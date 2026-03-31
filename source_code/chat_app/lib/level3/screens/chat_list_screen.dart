import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/chat_room.dart';
import '../../core/theme/app_theme.dart';
import '../../level1/screens/login_screen.dart';
import '../../level1/screens/new_chat_screen.dart';
import '../../level1/services/auth_service.dart';
import '../../level1/services/chat_service.dart';
import 'chat_screen.dart';
import 'new_group_screen.dart';

class Level3ChatListScreen extends StatelessWidget {
  const Level3ChatListScreen({super.key});

  void _showNewOptions(BuildContext context, currentUser) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.level3Color.withOpacity(0.15),
                child: const Icon(Icons.lock, color: AppTheme.level3Color),
              ),
              title: const Text('New Encrypted Chat',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('1-on-1 encrypted conversation'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => NewChatScreen(
                      currentUser: currentUser, useEncrypted: true),
                ));
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.withOpacity(0.15),
                child: const Icon(Icons.group, color: Colors.purple),
              ),
              title: const Text('New Group Chat',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Encrypted group with multiple members'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => NewGroupScreen(currentUser: currentUser),
                ));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return const LoginScreen(level: 3);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level 3 — Advanced',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('E2EE + Message Reactions + Security',
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
                  MaterialPageRoute(builder: (_) => const LoginScreen(level: 3)));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.level3Color,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showNewOptions(context, currentUser),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppTheme.level3Color.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.lock, size: 14, color: AppTheme.level3Color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'E2EE active · Long press messages to react · Reactions sync in real-time',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatRoom>>(
              stream: ChatService().getEncryptedChatRooms(currentUser.uid),
              builder: (context, snapshot) {
                final rooms = snapshot.data ?? [];
                if (rooms.isEmpty &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('No conversations yet',
                            style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 8),
                        const Text('Tap + to start a chat',
                            style: TextStyle(fontSize: 12)),
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
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.level3Color.withOpacity(0.8),
                        child: Text(
                          room.avatarInitials(currentUser.uid),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(room.displayName(currentUser.uid),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          const Icon(Icons.lock,
                              size: 12, color: Colors.green),
                        ],
                      ),
                      subtitle: room.lastMessage != null
                          ? Text(
                              room.lastMessage!.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            )
                          : null,
                      trailing: room.lastMessage != null
                          ? Text(
                              DateFormat('HH:mm')
                                  .format(room.lastMessage!.timestamp),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
                            )
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdvancedChatScreen(
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
