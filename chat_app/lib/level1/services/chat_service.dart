import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/models/chat_room.dart';
import '../../core/models/message.dart';
import '../../core/models/user_model.dart';

/// Level 1 — Chat Service
///
/// DEMO MODE: In-memory StreamController simulates Firestore real-time.
/// PRODUCTION: Replace with Firebase Firestore implementation.
///
/// Firebase implementation:
/// ```dart
/// // Get chat rooms for current user
/// Stream<List<ChatRoom>> getChatRooms(String uid) {
///   return FirebaseFirestore.instance
///       .collection('chats')
///       .where('memberIds', arrayContains: uid)
///       .orderBy('lastMessageTime', descending: true)
///       .snapshots()
///       .map((snap) => snap.docs.map(ChatRoom.fromFirestore).toList());
/// }
///
/// // Get messages — REAL-TIME via .snapshots()
/// Stream<List<Message>> getMessages(String chatRoomId) {
///   return FirebaseFirestore.instance
///       .collection('chats/$chatRoomId/messages')
///       .orderBy('timestamp', descending: false)
///       .snapshots()
///       .map((snap) => snap.docs.map(Message.fromFirestore).toList());
/// }
///
/// // Send message — Batch write for atomicity
/// Future<void> sendMessage(String chatRoomId, String content, String senderId) async {
///   final batch = FirebaseFirestore.instance.batch();
///   final msgRef = FirebaseFirestore.instance
///       .collection('chats/$chatRoomId/messages').doc();
///   batch.set(msgRef, {
///     'senderId': senderId,
///     'content': content,
///     'timestamp': FieldValue.serverTimestamp(),  // server time
///     'status': 'sent',
///   });
///   batch.update(
///     FirebaseFirestore.instance.collection('chats').doc(chatRoomId),
///     {'lastMessage': content, 'lastMessageTime': FieldValue.serverTimestamp()},
///   );
///   await batch.commit(); // ATOMIC — both succeed or both fail
/// }
/// ```

class ChatService {
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;
  ChatService._() {
    _initMockData();
  }

  static const _uuid = Uuid();

  // In-memory "database"
  final _rooms = <String, ChatRoom>{};
  final _messages = <String, List<Message>>{};
  final _roomControllers = <String, StreamController<List<Message>>>{};
  final _roomListController =
      StreamController<List<ChatRoom>>.broadcast();

  void _initMockData() {
    // Seed mock chat rooms
    final rooms = [
      ChatRoom(
        id: 'room_1',
        memberIds: const ['uid_alice', 'uid_bob'],
        memberNames: const ['Alice Nguyen', 'Bob Tran'],
        lastMessage: Message(
          id: 'm0',
          senderId: 'uid_bob',
          senderName: 'Bob Tran',
          content: 'Hey Alice! How are you?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          status: MessageStatus.seen,
        ),
        unreadCount: 1,
      ),
      ChatRoom(
        id: 'room_2',
        memberIds: const ['uid_alice', 'uid_carol'],
        memberNames: const ['Alice Nguyen', 'Carol Le'],
        lastMessage: Message(
          id: 'm1',
          senderId: 'uid_alice',
          senderName: 'Alice Nguyen',
          content: 'The Flutter seminar is tomorrow!',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          status: MessageStatus.delivered,
        ),
      ),
      ChatRoom(
        id: 'room_3',
        memberIds: const ['uid_bob', 'uid_carol', 'uid_alice'],
        memberNames: const ['Bob Tran', 'Carol Le', 'Alice Nguyen'],
        isGroup: true,
        groupName: 'Flutter Team',
        lastMessage: Message(
          id: 'm2',
          senderId: 'uid_carol',
          senderName: 'Carol Le',
          content: "Don't forget to push the code!",
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          status: MessageStatus.delivered,
        ),
        unreadCount: 2,
      ),
    ];

    for (final room in rooms) {
      _rooms[room.id] = room;
      _messages[room.id] = [];
    }

    // Seed initial messages for room_1
    _messages['room_1'] = [
      Message(
        id: _uuid.v4(),
        senderId: 'uid_bob',
        senderName: 'Bob Tran',
        content: 'Hey Alice! How are you?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        status: MessageStatus.seen,
      ),
      Message(
        id: _uuid.v4(),
        senderId: 'uid_alice',
        senderName: 'Alice Nguyen',
        content: "I'm great! Ready for the seminar?",
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        status: MessageStatus.seen,
      ),
      Message(
        id: _uuid.v4(),
        senderId: 'uid_bob',
        senderName: 'Bob Tran',
        content: 'Yes! I finished the Level 1 demo.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: MessageStatus.delivered,
      ),
    ];
  }

  /// Stream danh sách chat rooms.
  /// Firebase: collection('chats').where('memberIds', arrayContains: uid).snapshots()
  Stream<List<ChatRoom>> getChatRooms(String uid) {
    Future.microtask(() => _emitRooms(uid));
    return _roomListController.stream
        .map((rooms) => rooms.where((r) => r.memberIds.contains(uid)).toList());
  }

  void _emitRooms(String uid) {
    _roomListController.add(_rooms.values.toList());
  }

  /// Stream messages real-time.
  /// Firebase: collection('chats/$id/messages').snapshots()
  Stream<List<Message>> getMessages(String chatRoomId) {
    _roomControllers[chatRoomId] ??=
        StreamController<List<Message>>.broadcast();
    // emit current messages immediately
    Future.microtask(() {
      _roomControllers[chatRoomId]
          ?.add(List.from(_messages[chatRoomId] ?? []));
    });
    return _roomControllers[chatRoomId]!.stream;
  }

  /// Gửi tin nhắn — Firebase: batch.commit() (atomic)
  Future<void> sendMessage({
    required String chatRoomId,
    required String content,
    required String senderId,
    required String senderName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100)); // simulate latency

    final message = Message(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    _messages[chatRoomId] ??= [];
    _messages[chatRoomId]!.add(message);

    // Firebase: batch.update(chatRef, {'lastMessage': content})
    final room = _rooms[chatRoomId];
    if (room != null) {
      _rooms[chatRoomId] = room.copyWith(lastMessage: message);
    }

    // Push to streams (Firebase: this happens automatically via .snapshots())
    _roomControllers[chatRoomId]
        ?.add(List.from(_messages[chatRoomId]!));
    _roomListController.add(_rooms.values.toList());

    // Simulate delivered status after 1s
    Future.delayed(const Duration(seconds: 1), () {
      final msgs = _messages[chatRoomId];
      if (msgs == null) return;
      final idx = msgs.indexWhere((m) => m.id == message.id);
      if (idx >= 0) {
        msgs[idx] = msgs[idx].copyWith(status: MessageStatus.delivered);
        _roomControllers[chatRoomId]?.add(List.from(msgs));
      }
    });

    // Simulate auto-reply for demo
    _scheduleAutoReply(chatRoomId, senderId);
  }

  void _scheduleAutoReply(String chatRoomId, String senderId) {
    final room = _rooms[chatRoomId];
    if (room == null) return;
    final otherMember =
        room.memberIds.firstWhere((id) => id != senderId, orElse: () => '');
    if (otherMember.isEmpty) return;
    final otherName =
        room.memberNames[room.memberIds.indexOf(otherMember)];

    final replies = [
      'Got it! 👍',
      'Sure, sounds good!',
      'That makes sense.',
      'Can you tell me more?',
      'Interesting! 🔥',
      'Okay, noted!',
    ];
    final reply = replies[DateTime.now().second % replies.length];

    Future.delayed(const Duration(seconds: 2), () {
      final autoMsg = Message(
        id: _uuid.v4(),
        senderId: otherMember,
        senderName: otherName,
        content: reply,
        timestamp: DateTime.now(),
        status: MessageStatus.delivered,
      );
      _messages[chatRoomId]?.add(autoMsg);
      _roomControllers[chatRoomId]
          ?.add(List.from(_messages[chatRoomId]!));
      _rooms[chatRoomId] =
          _rooms[chatRoomId]!.copyWith(lastMessage: autoMsg);
      _roomListController.add(_rooms.values.toList());
    });
  }

  List<UserModel> getAllUsers() {
    return [
      UserModel(
          uid: 'uid_alice',
          displayName: 'Alice Nguyen',
          email: 'user1@demo.com',
          isOnline: true,
          lastSeen: DateTime.now()),
      UserModel(
          uid: 'uid_bob',
          displayName: 'Bob Tran',
          email: 'user2@demo.com',
          isOnline: true,
          lastSeen: DateTime.now()),
      UserModel(
          uid: 'uid_carol',
          displayName: 'Carol Le',
          email: 'user3@demo.com',
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(hours: 1))),
    ];
  }
}
