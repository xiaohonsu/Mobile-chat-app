import 'dart:async';
import '../../core/models/message.dart';

/// Level 2 — WebSocket Service
///
/// DEMO MODE: Simulates WebSocket events using local StreamControllers.
/// PRODUCTION: Replace with real WebSocket implementation below.
///
/// ```dart
/// import 'package:web_socket_channel/web_socket_channel.dart';
///
/// class WebSocketService {
///   WebSocketChannel? _channel;
///
///   void connect(String userId) {
///     _channel = WebSocketChannel.connect(
///       Uri.parse('wss://your-server.com/ws?userId=$userId'),
///     );
///     _channel!.stream.listen(
///       (data) => _handleIncoming(jsonDecode(data)),
///       onError: (_) => _reconnect(),
///       onDone:  () => _reconnect(),   // auto reconnect on disconnect
///     );
///   }
///
///   void sendEvent(Map<String, dynamic> event) =>
///       _channel?.sink.add(jsonEncode(event));
///
///   void disconnect() => _channel?.sink.close();
/// }
/// ```

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

  final _eventController = StreamController<WSEvent>.broadcast();
  final _typingController = StreamController<Map<String, bool>>.broadcast();

  bool _connected = false;
  String? _userId;

  bool get isConnected => _connected;

  /// Connect to WebSocket server.
  /// In production: WebSocketChannel.connect(Uri.parse('wss://...'))
  void connect(String userId) {
    _userId = userId;
    _connected = true;
    _emit(WSEvent(WSEventType.userOnline, {'userId': userId}));
  }

  /// Disconnect and update presence.
  void disconnect() {
    if (_userId != null) {
      _emit(WSEvent(WSEventType.userOffline, {'userId': _userId}));
    }
    _connected = false;
    _userId = null;
  }

  /// Listen to all WebSocket events.
  Stream<WSEvent> get events => _eventController.stream;

  /// Stream of typing states — key: userId, value: isTyping.
  Stream<Map<String, bool>> get typingStream => _typingController.stream;

  /// Send typing_start event.
  /// In production: _channel.sink.add(jsonEncode({type: 'typing_start', ...}))
  void sendTypingStart(String chatRoomId) {
    _emit(WSEvent(WSEventType.typing, {
      'chatRoomId': chatRoomId,
      'userId': _userId,
      'isTyping': true,
    }));
    _typingController.add({_userId ?? '': true});
  }

  /// Send typing_stop event.
  void sendTypingStop(String chatRoomId) {
    _emit(WSEvent(WSEventType.typing, {
      'chatRoomId': chatRoomId,
      'userId': _userId,
      'isTyping': false,
    }));
    _typingController.add({_userId ?? '': false});
  }

  /// Simulate receiving a message from server push.
  /// In production: server pushes this automatically via WebSocket.
  void simulateIncomingMessage(Message message) {
    _emit(WSEvent(WSEventType.message, {
      'message': message.toMap(),
    }));
  }

  /// Simulate typing from another user.
  void simulateTyping(String userId, String chatRoomId, bool isTyping) {
    _typingController.add({userId: isTyping});
  }

  void _emit(WSEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void dispose() {
    _eventController.close();
    _typingController.close();
  }
}
