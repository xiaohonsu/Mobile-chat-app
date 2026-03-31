import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/chat_room.dart';
import '../../core/theme/app_theme.dart';
import '../../level1/services/auth_service.dart';
import '../../level1/services/chat_service.dart';
import '../../level1/screens/login_screen.dart';
import '../services/websocket_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Connect WebSocket when entering Level 2
    final user = AuthService().currentUser;
    if (user != null) {
      WebSocketService().connect(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;

    if (currentUser == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level 2 — Intermediate',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('BLoC + WebSocket + FCM + Offline Cache',
                style: TextStyle(fontSize: 10)),
          ],
        ),
        actions: [
          // WebSocket connection indicator
          StreamBuilder<WSEvent>(
            stream: WebSocketService().events,
            builder: (context, _) {
              final connected = WebSocketService().isConnected;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Icon(
                      connected ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: connected
                          ? AppTheme.primaryLight
                          : Colors.red[300],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connected ? 'WS' : 'Off',
                      style: TextStyle(
                        fontSize: 11,
                        color: connected
                            ? AppTheme.primaryLight
                            : Colors.red[300],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              WebSocketService().disconnect();
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
          // Level 2 features banner
          Container(
            width: double.infinity,
            color: AppTheme.level2Color.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppTheme.level2Color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BLoC manages state. WebSocket handles typing & presence. '
                    'Hive caches messages offline.',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<ChatRoom>>(
              stream: ChatService().getChatRooms(currentUser.uid),
              builder: (context, snapshot) {
                final rooms = snapshot.data ?? [];
                if (rooms.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: room.isGroup
                            ? AppTheme.secondary
                            : AppTheme.level2Color,
                        child: Text(
                          room.avatarInitials(currentUser.uid),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(room.displayName(currentUser.uid),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: room.lastMessage != null
                          ? Text(
                              room.lastMessage!.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                          builder: (_) => Level2ChatScreen(
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
