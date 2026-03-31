enum MessageType { text, image, video, file }

enum MessageStatus { sending, sent, delivered, seen }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  // --- Firebase pattern (commented for demo) ---
  // factory Message.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return Message(
  //     id: doc.id,
  //     senderId: data['senderId'],
  //     senderName: data['senderName'],
  //     content: data['content'],
  //     type: MessageType.values.byName(data['type'] ?? 'text'),
  //     timestamp: (data['timestamp'] as Timestamp).toDate(),
  //     status: MessageStatus.values.byName(data['status'] ?? 'sent'),
  //   );
  // }
  //
  // Map<String, dynamic> toFirestore() => {
  //   'senderId': senderId,
  //   'senderName': senderName,
  //   'content': content,
  //   'type': type.name,
  //   'timestamp': FieldValue.serverTimestamp(),
  //   'status': status.name,
  // };

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      content: map['content'] as String,
      type: MessageType.values.byName(map['type'] as String? ?? 'text'),
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: MessageStatus.values.byName(map['status'] as String? ?? 'sent'),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
      };

  Message copyWith({MessageStatus? status}) {
    return Message(
      id: id,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: type,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }
}
