import 'message.dart';

class ChatRoom {
  final String id;
  final List<String> memberIds;
  final List<String> memberNames;
  final Message? lastMessage;
  final bool isGroup;
  final String? groupName;
  final int unreadCount;

  const ChatRoom({
    required this.id,
    required this.memberIds,
    required this.memberNames,
    this.lastMessage,
    this.isGroup = false,
    this.groupName,
    this.unreadCount = 0,
  });

  // --- Firebase pattern (commented for demo) ---
  // factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return ChatRoom(
  //     id: doc.id,
  //     memberIds: List<String>.from(data['memberIds']),
  //     memberNames: List<String>.from(data['memberNames']),
  //     isGroup: data['isGroup'] ?? false,
  //     groupName: data['groupName'],
  //     unreadCount: data['unreadCount'] ?? 0,
  //   );
  // }

  String displayName(String currentUserId) {
    if (isGroup) return groupName ?? 'Group Chat';
    final otherIndex = memberIds.indexWhere((id) => id != currentUserId);
    return otherIndex >= 0 ? memberNames[otherIndex] : memberNames.first;
  }

  String avatarInitials(String currentUserId) {
    final name = displayName(currentUserId);
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  ChatRoom copyWith({Message? lastMessage, int? unreadCount}) {
    return ChatRoom(
      id: id,
      memberIds: memberIds,
      memberNames: memberNames,
      lastMessage: lastMessage ?? this.lastMessage,
      isGroup: isGroup,
      groupName: groupName,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
