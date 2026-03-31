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

class LoadMoreMessages extends ChatEvent {
  final String chatRoomId;
  LoadMoreMessages(this.chatRoomId);

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
  final bool hasMore; // whether older messages exist to load
  ChatLoaded(this.messages, {this.isOffline = false, this.hasMore = false});

  @override
  List<Object?> get props => [messages, isOffline, hasMore];
}

class ChatLoadingMore extends ChatLoaded {
  ChatLoadingMore(super.messages, {super.hasMore});
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
  // Tracks prepended older messages (pagination)
  final List<Message> _olderMessages = [];

  static const _uuid = Uuid();

  ChatBloc(this.chatRoomId) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
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

    // Step 3: Mark incoming messages as seen
    final user = AuthService().currentUser;
    if (user != null) {
      ChatService().markMessagesAsSeen(chatRoomId, user.uid);
    }
  }

  Future<void> _onLoadMoreMessages(
      LoadMoreMessages event, Emitter<ChatState> emit) async {
    final current = state is ChatLoaded ? (state as ChatLoaded) : null;
    if (current == null || current is ChatLoadingMore) return;

    emit(ChatLoadingMore(current.messages, hasMore: current.hasMore));

    // Find the oldest message doc in Firestore for cursor-based pagination
    final allMessages = [..._olderMessages, ...current.messages];
    if (allMessages.isEmpty) return;

    // We use the oldest message ID as the cursor
    final oldestId = allMessages.first.id;
    try {
      // Fetch the DocumentSnapshot for the oldest loaded message
      final olderMsgs = await _loadOlderThan(oldestId);
      if (olderMsgs.isEmpty) {
        emit(ChatLoaded(current.messages, hasMore: false));
        return;
      }
      _olderMessages.insertAll(0, olderMsgs);
      final combined = [..._olderMessages, ...current.messages];
      emit(ChatLoaded(combined,
          hasMore: olderMsgs.length >= 30)); // assume more if full page
    } catch (_) {
      emit(ChatLoaded(current.messages, hasMore: current.hasMore));
    }
  }

  Future<List<Message>> _loadOlderThan(String messageId) async {
    // Get a DocumentSnapshot of the oldest visible message, then paginate before it
    final db = ChatService();
    // We fetch the reference doc by querying messages with this ID
    // Using orderBy timestamp descending + startAfter approach via ChatService
    // For simplicity, we query the raw Firestore doc via ChatService helper
    return db.getOlderMessagesById(chatRoomId, messageId, limit: 30);
  }

  Future<void> _onNewMessages(
      _NewMessageReceived event, Emitter<ChatState> emit) async {
    await LocalCacheService.cacheMessages(chatRoomId, event.messages);
    // Merge with older prepended messages
    final combined = _olderMessages.isEmpty
        ? event.messages
        : [..._olderMessages, ...event.messages];
    emit(ChatLoaded(combined, hasMore: _olderMessages.isNotEmpty));

    // Mark new incoming messages as seen
    final user = AuthService().currentUser;
    if (user != null) {
      final hasUnseen = event.messages.any((m) =>
          m.senderId != user.uid &&
          (m.status == MessageStatus.sent ||
              m.status == MessageStatus.delivered));
      if (hasUnseen) {
        ChatService().markMessagesAsSeen(chatRoomId, user.uid);
      }
    }
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
    ChatService().setTyping(chatRoomId, user.uid, false);
  }

  void _onTypingStarted(TypingStarted event, Emitter<ChatState> emit) {
    // Send typing event via WebSocket (real server)
    WebSocketService().sendTypingStart(event.chatRoomId);
    // Also write to Firestore so other device can see it
    final user = AuthService().currentUser;
    if (user != null) {
      ChatService().setTyping(event.chatRoomId, user.uid, true);
    }
  }

  void _onTypingStopped(TypingStopped event, Emitter<ChatState> emit) {
    WebSocketService().sendTypingStop(event.chatRoomId);
    final user = AuthService().currentUser;
    if (user != null) {
      ChatService().setTyping(event.chatRoomId, user.uid, false);
    }
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    return super.close();
  }
}
