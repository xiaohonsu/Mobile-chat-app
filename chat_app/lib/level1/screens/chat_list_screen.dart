import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/chat_room.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'new_chat_screen.dart';

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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryLight,
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewChatScreen(currentUser: currentUser),
          ),
        ),
      ),
      body: Column(
        children: [
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
                    'StreamBuilder + Firestore .snapshots() — '
                    'real-time, no polling.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            // 🔑 KEY: StreamBuilder lắng nghe Firestore stream
            // Mỗi khi có tin nhắn mới → Firestore push → ListView rebuild
            child: StreamBuilder<List<ChatRoom>>(
              stream: ChatService().getChatRooms(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                final rooms = snapshot.data ?? [];
                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No conversations yet.',
                            style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NewChatScreen(currentUser: currentUser),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Start a chat'),
                        ),
                      ],
                    ),
                  );
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
        backgroundColor:
            room.isGroup ? AppTheme.secondary : AppTheme.primary,
        child: Text(initials,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      title: Text(name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: lastMsg != null
          ? Text(
              lastMsg.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            )
          : null,
      trailing: lastMsg != null
          ? Text(
              _formatTime(lastMsg.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            )
          : null,
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
