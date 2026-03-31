import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/chat_room.dart';
import '../../core/models/message.dart';

/// Level 1 — Chat Service
/// Firestore database structure:
///
/// users/{uid}
///   displayName, email, isOnline, lastSeen
///
/// chats/{chatId}
///   memberIds: [uid1, uid2]
///   memberNames: [name1, name2]
///   lastMessage: string
///   lastMessageTime: timestamp
///   isGroup: bool
///   groupName: string?
///   unreadCount: int (per member — simplified)
///
/// chats/{chatId}/messages/{msgId}
///   senderId, senderName, content, type, timestamp, status

class ChatService {
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;
  ChatService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ─── Chat Rooms ─────────────────────────────────────────────

  /// Stream danh sách chat rooms của user hiện tại.
  /// Real-time: Firestore tự push khi có thay đổi.
  Stream<List<ChatRoom>> getChatRooms(String uid) {
    return _db
        .collection('chats')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snap) {
          final rooms = snap.docs.map(_roomFromDoc).toList();
          rooms.sort((a, b) {
            final ta = a.lastMessage?.timestamp ?? DateTime(2000);
            final tb = b.lastMessage?.timestamp ?? DateTime(2000);
            return tb.compareTo(ta);
          });
          return rooms;
        });
  }

  ChatRoom _roomFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Message? lastMsg;
    if (data['lastMessage'] != null) {
      lastMsg = Message(
        id: 'last',
        senderId: data['lastSenderId'] ?? '',
        senderName: data['lastSenderName'] ?? '',
        content: data['lastMessage'] as String,
        timestamp: (data['lastMessageTime'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        status: MessageStatus.delivered,
      );
    }
    return ChatRoom(
      id: doc.id,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberNames: List<String>.from(data['memberNames'] ?? []),
      lastMessage: lastMsg,
      isGroup: data['isGroup'] as bool? ?? false,
      groupName: data['groupName'] as String?,
    );
  }

  /// Tạo hoặc lấy chat room 1-1 giữa 2 users.
  /// Dùng chatId = sorted uid1_uid2 để tránh tạo duplicate.
  Future<String> getOrCreateChatRoom({
    required String uid1,
    required String name1,
    required String uid2,
    required String name2,
  }) async {
    final ids = [uid1, uid2]..sort();
    final chatId = '${ids[0]}_${ids[1]}';
    final ref = _db.collection('chats').doc(chatId);

    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'memberIds': [uid1, uid2],
        'memberNames': [name1, name2],
        'isGroup': false,
        'lastMessage': null,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  // ─── Messages ────────────────────────────────────────────────

  /// Stream messages real-time.
  /// .snapshots() = Firestore maintains WebSocket connection,
  /// pushes updates automatically — no polling needed.
  Stream<List<Message>> getMessages(String chatRoomId) {
    return _db
        .collection('chats/$chatRoomId/messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(_msgFromDoc).toList());
  }

  Message _msgFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      content: data['content'] as String,
      type: MessageType.values.byName(data['type'] as String? ?? 'text'),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.byName(data['status'] as String? ?? 'sent'),
      reactions: Map<String, String>.from(data['reactions'] as Map? ?? {}),
    );
  }

  /// Gửi tin nhắn — Batch write đảm bảo atomicity.
  /// Cả 2 thao tác (thêm message + cập nhật lastMessage) thành công hoặc
  /// thất bại cùng nhau — không bao giờ bị inconsistent state.
  Future<void> sendMessage({
    required String chatRoomId,
    required String content,
    required String senderId,
    required String senderName,
    MessageType type = MessageType.text,
  }) async {
    final batch = _db.batch();

    // 1. Thêm message vào subcollection
    final messageRef =
        _db.collection('chats/$chatRoomId/messages').doc();
    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'timestamp': FieldValue.serverTimestamp(), // server time, không dùng device time
      'status': MessageStatus.sent.name,
    });

    // 2. Cập nhật lastMessage ở chat room (atomic)
    final chatRef = _db.collection('chats').doc(chatRoomId);
    batch.update(chatRef, {
      'lastMessage': content,
      'lastSenderId': senderId,
      'lastSenderName': senderName,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Cập nhật status tin nhắn (seen/delivered)
  Future<void> updateMessageStatus(
      String chatRoomId, String messageId, MessageStatus status) async {
    await _db
        .collection('chats/$chatRoomId/messages')
        .doc(messageId)
        .update({'status': status.name});
  }

  /// Stream typing status của các user khác trong chat room.
  /// Dùng để show "X is typing..." indicator ở Level 2.
  Stream<bool> watchOtherTyping(String chatRoomId, String currentUserId) {
    return _db.collection('chats').doc(chatRoomId).snapshots().map((doc) {
      final typing = doc.data()?['typing'] as Map? ?? {};
      return typing.entries
          .where((e) => e.key != currentUserId)
          .any((e) => e.value == true);
    });
  }

  /// Cập nhật trạng thái typing của user vào Firestore.
  /// Cho phép thiết bị khác nhận typing indicator qua .snapshots().
  Future<void> setTyping(
      String chatRoomId, String uid, bool isTyping) async {
    await _db.collection('chats').doc(chatRoomId).set(
      {'typing': {uid: isTyping}},
      SetOptions(merge: true),
    );
  }

  /// Cập nhật online presence trong Firestore
  /// Được dùng thay WebSocket presence ở Level 1
  Stream<bool> watchUserOnline(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] as bool? ?? false);
  }

  /// Toggle reaction trên một message.
  /// Nếu user đã react emoji đó → bỏ. Nếu chưa → thêm.
  Future<void> toggleReaction({
    required String chatRoomId,
    required String messageId,
    required String uid,
    required String emoji,
  }) async {
    final ref = _db.collection('chats/$chatRoomId/messages').doc(messageId);
    final doc = await ref.get();
    final reactions = Map<String, String>.from(
        (doc.data() as Map<String, dynamic>?)?['reactions'] as Map? ?? {});

    if (reactions[uid] == emoji) {
      reactions.remove(uid); // toggle off
    } else {
      reactions[uid] = emoji; // add or change
    }
    await ref.update({'reactions': reactions});
  }

  // ─── Encrypted Chat Rooms (Level 3) ────────────────────────────

  static const _encPrefix = 'encrypted_chats';

  Stream<List<ChatRoom>> getEncryptedChatRooms(String uid) {
    return _db
        .collection(_encPrefix)
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snap) {
          final rooms = snap.docs.map(_roomFromDoc).toList();
          rooms.sort((a, b) {
            final ta = a.lastMessage?.timestamp ?? DateTime(2000);
            final tb = b.lastMessage?.timestamp ?? DateTime(2000);
            return tb.compareTo(ta);
          });
          return rooms;
        });
  }

  Future<String> createEncryptedGroupChat({
    required String groupName,
    required List<String> memberIds,
    required List<String> memberNames,
  }) async {
    final ref = _db.collection(_encPrefix).doc(); // auto-generated ID
    await ref.set({
      'memberIds': memberIds,
      'memberNames': memberNames,
      'isGroup': true,
      'groupName': groupName,
      'lastMessage': null,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> getOrCreateEncryptedChatRoom({
    required String uid1,
    required String name1,
    required String uid2,
    required String name2,
  }) async {
    final ids = [uid1, uid2]..sort();
    final chatId = '${ids[0]}_${ids[1]}';
    final ref = _db.collection(_encPrefix).doc(chatId);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'memberIds': [uid1, uid2],
        'memberNames': [name1, name2],
        'isGroup': false,
        'lastMessage': null,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  Stream<List<Message>> getEncryptedMessages(String chatRoomId) {
    return _db
        .collection('$_encPrefix/$chatRoomId/messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(_msgFromDoc).toList());
  }

  Future<void> sendEncryptedMessage({
    required String chatRoomId,
    required String encryptedContent,
    required String senderId,
    required String senderName,
  }) async {
    final batch = _db.batch();

    final messageRef =
        _db.collection('$_encPrefix/$chatRoomId/messages').doc();
    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'content': encryptedContent,
      'type': MessageType.text.name,
      'timestamp': FieldValue.serverTimestamp(),
      'status': MessageStatus.sent.name,
    });

    final chatRef = _db.collection(_encPrefix).doc(chatRoomId);
    batch.update(chatRef, {
      'lastMessage': encryptedContent,
      'lastSenderId': senderId,
      'lastSenderName': senderName,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> toggleEncryptedReaction({
    required String chatRoomId,
    required String messageId,
    required String uid,
    required String emoji,
  }) async {
    final ref =
        _db.collection('$_encPrefix/$chatRoomId/messages').doc(messageId);
    final doc = await ref.get();
    final reactions = Map<String, String>.from(
        (doc.data() as Map<String, dynamic>?)?['reactions'] as Map? ?? {});
    if (reactions[uid] == emoji) {
      reactions.remove(uid);
    } else {
      reactions[uid] = emoji;
    }
    await ref.update({'reactions': reactions});
  }

  /// Lấy danh sách users để tạo chat mới
  Future<List<Map<String, dynamic>>> getAvailableUsers() async {
    final currentUid = _auth.currentUser?.uid ?? '';
    final snap = await _db.collection('users').get();
    return snap.docs
        .where((doc) => doc.id != currentUid)
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .toList();
  }
}
