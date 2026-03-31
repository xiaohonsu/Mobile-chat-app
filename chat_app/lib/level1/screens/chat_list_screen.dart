import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/chat_room.dart';
import '../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level 1 — Simple Chat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Firebase Firestore + StreamBuilder',
                style: TextStyle(fontSize: 10)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Level indicator banner
          Container(
            width: double.infinity,
            color: AppTheme.level1Color.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppTheme.level1Color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'StreamBuilder listens to Firestore .snapshots() — '
                    'messages update in real-time without polling.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            // 🔑 KEY CONCEPT: StreamBuilder + Firestore .snapshots()
            // In production: ChatService().getChatRooms() returns
            // FirebaseFirestore.collection('chats').snapshots()
            child: StreamBuilder<List<ChatRoom>>(
              stream: ChatService().getChatRooms(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rooms = snapshot.data ?? [];
                if (rooms.isEmpty) {
                  return const Center(child: Text('No conversations yet'));
                }
                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return _RoomTile(
                      room: room,
                      currentUserId: currentUser.uid,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatRoom: room,
                            currentUser: currentUser,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final ChatRoom room;
  final String currentUserId;
  final VoidCallback onTap;

  const _RoomTile({
    required this.room,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = room.displayName(currentUserId);
    final initials = room.avatarInitials(currentUserId);
    final lastMsg = room.lastMessage;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: room.isGroup
            ? AppTheme.secondary
            : AppTheme.primary,
        child: Text(initials,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: lastMsg != null
          ? Text(
              lastMsg.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: room.unreadCount > 0
                    ? Colors.black87
                    : Colors.grey[600],
                fontWeight: room.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastMsg != null)
            Text(
              _formatTime(lastMsg.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: room.unreadCount > 0
                    ? AppTheme.primaryLight
                    : Colors.grey[500],
              ),
            ),
          const SizedBox(height: 4),
          if (room.unreadCount > 0)
            CircleAvatar(
              radius: 10,
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                '${room.unreadCount}',
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return DateFormat('HH:mm').format(time);
    }
    return DateFormat('dd/MM').format(time);
  }
}
