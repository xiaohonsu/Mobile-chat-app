import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Level 2 — WebSocket Service
///
/// Connects to the Node.js WebSocket server in source_code/websocket_server/.
///
/// URL resolution (priority order):
///   1. WEBSOCKET_URL env var (production deployment)
///   2. Android emulator → ws://10.0.2.2:8080
///   3. Chrome / desktop  → ws://localhost:8080
///
/// Server events handled:
///   typing_start / typing_stop → typingStream
///   user_online / user_offline → events stream
///   seen                        → events stream

enum WSEventType { message, typing, userOnline, userOffline, seen }

class WSEvent {
  final WSEventType type;
  final Map<String, dynamic> data;
  const WSEvent(this.type, this.data);
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  WebSocketService._();

  // ── Public streams ──────────────────────────────────────────────
  Stream<WSEvent> get events => _eventController.stream;
  Stream<Map<String, bool>> get typingStream => _typingController.stream;
  bool get isConnected => _connected;

  // ── Internal state ──────────────────────────────────────────────
  final _eventController = StreamController<WSEvent>.broadcast();
  final _typingController = StreamController<Map<String, bool>>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  bool _connected = false;
  String? _userId;
  String? _currentChatRoomId;

  // Reconnect
  Timer? _reconnectTimer;
  static const _reconnectDelay = Duration(seconds: 3);
  bool _disposing = false;

  // ── URL ─────────────────────────────────────────────────────────
  static String get _serverUrl {
    // 1. Production env var (set in flutter run --dart-define=WEBSOCKET_URL=wss://...)
    const envUrl = String.fromEnvironment('WEBSOCKET_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // 2. Chrome / desktop
    if (kIsWeb) return 'ws://localhost:8080';

    // 3. Android emulator (10.0.2.2 = host machine's localhost)
    return 'ws://10.0.2.2:8080';
  }

  // ── Public API ──────────────────────────────────────────────────

  void connect(String userId) {
    _userId = userId;
    _disposing = false;
    _connect();
  }

  void disconnect() {
    _disposing = true;
    _reconnectTimer?.cancel();
    if (_userId != null) {
      _emit(WSEvent(WSEventType.userOffline, {'userId': _userId}));
    }
    _closeChannel();
    _connected = false;
    _userId = null;
    _currentChatRoomId = null;
  }

  void joinRoom(String chatRoomId) {
    _currentChatRoomId = chatRoomId;
    _send({'type': 'join_room', 'chatRoomId': chatRoomId});
  }

  void leaveRoom(String chatRoomId) {
    if (_currentChatRoomId == chatRoomId) _currentChatRoomId = null;
    _send({'type': 'leave_room', 'chatRoomId': chatRoomId});
  }

  void sendTypingStart(String chatRoomId) {
    _send({'type': 'typing_start', 'chatRoomId': chatRoomId});
  }

  void sendTypingStop(String chatRoomId) {
    _send({'type': 'typing_stop', 'chatRoomId': chatRoomId});
  }

  void sendSeen(String chatRoomId, String messageId) {
    _send({'type': 'seen', 'chatRoomId': chatRoomId, 'messageId': messageId});
  }

  // ── Internal ────────────────────────────────────────────────────

  void _connect() {
    if (_userId == null || _disposing) return;
    final url = '$_serverUrl?userId=$_userId';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channelSub = _channel!.stream.listen(
        _handleMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
      _connected = true;
      _emit(WSEvent(WSEventType.userOnline, {'userId': _userId}));
      // Re-join active room after reconnect
      if (_currentChatRoomId != null) {
        _send({'type': 'join_room', 'chatRoomId': _currentChatRoomId});
      }
    } catch (_) {
      _connected = false;
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    Map<String, dynamic> event;
    try {
      event = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = event['type'] as String? ?? '';
    switch (type) {
      case 'typing_start':
        final userId = event['userId'] as String? ?? '';
        _typingController.add({userId: true});
        _emit(WSEvent(WSEventType.typing, {...event, 'isTyping': true}));
        break;

      case 'typing_stop':
        final userId = event['userId'] as String? ?? '';
        _typingController.add({userId: false});
        _emit(WSEvent(WSEventType.typing, {...event, 'isTyping': false}));
        break;

      case 'user_online':
        _emit(WSEvent(WSEventType.userOnline, event));
        break;

      case 'user_offline':
        _emit(WSEvent(WSEventType.userOffline, event));
        break;

      case 'seen':
        _emit(WSEvent(WSEventType.seen, event));
        break;
    }
  }

  void _send(Map<String, dynamic> payload) {
    if (_channel == null || !_connected) return;
    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (_) {
      // channel closed; reconnect will fix it
    }
  }

  void _scheduleReconnect() {
    if (_disposing || _userId == null) return;
    _connected = false;
    _closeChannel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, _connect);
  }

  void _closeChannel() {
    _channelSub?.cancel();
    _channelSub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _emit(WSEvent event) {
    if (!_eventController.isClosed) _eventController.add(event);
  }

  void dispose() {
    _disposing = true;
    _reconnectTimer?.cancel();
    _closeChannel();
    _eventController.close();
    _typingController.close();
  }
}
