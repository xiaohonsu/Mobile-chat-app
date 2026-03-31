import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/message.dart';
import '../../level1/services/auth_service.dart';
import '../../level1/services/chat_service.dart';
import '../services/local_cache_service.dart';
import '../services/websocket_service.dart';

// ─────────────────────────── EVENTS ────────────────────────────

/// Events represent things that HAPPEN (user actions, external triggers).
abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String chatRoomId;
  LoadMessages(this.chatRoomId);

  @override
  List<Object?> get props => [chatRoomId];
}

class SendMessage extends ChatEvent {
  final String chatRoomId;
  final String content;
  SendMessage(this.chatRoomId, this.content);

  @override
  List<Object?> get props => [chatRoomId, content];
}

class _NewMessageReceived extends ChatEvent {
  final List<Message> messages;
  _NewMessageReceived(this.messages);

  @override
  List<Object?> get props => [messages];
}

class TypingStarted extends ChatEvent {
  final String chatRoomId;
  TypingStarted(this.chatRoomId);
}

class TypingStopped extends ChatEvent {
  final String chatRoomId;
  TypingStopped(this.chatRoomId);
}

// ─────────────────────────── STATES ────────────────────────────

/// States represent how the UI should look.
abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

/// Cached data is available — shown instantly while fetching from server.
class ChatCached extends ChatState {
  final List<Message> messages;
  ChatCached(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool isOffline;
  ChatLoaded(this.messages, {this.isOffline = false});

  @override
  List<Object?> get props => [messages, isOffline];
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─────────────────────────── BLOC ────────────────────────────

/// ChatBloc handles all chat business logic.
/// UI only dispatches Events and renders States — zero logic in widgets.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final String chatRoomId;
  StreamSubscription? _messagesSub;

  static const _uuid = Uuid();

  ChatBloc(this.chatRoomId) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<_NewMessageReceived>(_onNewMessages);
    on<TypingStarted>(_onTypingStarted);
    on<TypingStopped>(_onTypingStopped);
  }

  Future<void> _onLoadMessages(
      LoadMessages event, Emitter<ChatState> emit) async {
    emit(ChatLoading());

    // ── Cache-First Strategy ──────────────────────────────────────
    // Step 1: Show cached data immediately (no loading delay)
    final cached = await LocalCacheService.getCachedMessages(chatRoomId);
    if (cached.isNotEmpty) {
      emit(ChatCached(cached)); // instant feedback
    }

    // Step 2: Subscribe to live stream (Firebase: .snapshots())
    await _messagesSub?.cancel();
    _messagesSub = ChatService()
        .getMessages(chatRoomId)
        .listen((messages) => add(_NewMessageReceived(messages)));
  }

  Future<void> _onNewMessages(
      _NewMessageReceived event, Emitter<ChatState> emit) async {
    await LocalCacheService.cacheMessages(chatRoomId, event.messages);
    emit(ChatLoaded(event.messages));
  }

  Future<void> _onSendMessage(
      SendMessage event, Emitter<ChatState> emit) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    // Optimistic update — add message to UI immediately
    final current = state is ChatLoaded
        ? (state as ChatLoaded).messages
        : state is ChatCached
            ? (state as ChatCached).messages
            : <Message>[];

    final optimistic = Message(
      id: _uuid.v4(),
      senderId: user.uid,
      senderName: user.displayName,
      content: event.content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    emit(ChatLoaded([...current, optimistic]));

    // Send via service (Firebase: batch.commit())
    await ChatService().sendMessage(
      chatRoomId: chatRoomId,
      content: event.content,
      senderId: user.uid,
      senderName: user.displayName,
    );

    // Notify via WebSocket (typing stopped)
    WebSocketService().sendTypingStop(chatRoomId);
  }

  void _onTypingStarted(TypingStarted event, Emitter<ChatState> emit) {
    // Send typing event via WebSocket
    // In production: WebSocketChannel.sink.add(jsonEncode({type: 'typing_start'}))
    WebSocketService().sendTypingStart(event.chatRoomId);
  }

  void _onTypingStopped(TypingStopped event, Emitter<ChatState> emit) {
    WebSocketService().sendTypingStop(event.chatRoomId);
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    return super.close();
  }
}
