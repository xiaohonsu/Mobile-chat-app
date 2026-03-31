import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/chat_room.dart';
import '../../core/theme/app_theme.dart';
import '../../level1/services/auth_service.dart';
import '../../level1/services/chat_service.dart';
import '../../level1/screens/login_screen.dart';
import '../services/notification_service.dart';
import '../services/websocket_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  StreamSubscription? _notifSub;
  final Map<String, int> _lastMsgTime = {};
  bool _notifFirstLoad = true;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null) {
      WebSocketService().connect(user.uid);
      _setupNotificationListener(user.uid);
    }
  }

  void _setupNotificationListener(String uid) {
    _notifSub = ChatService().getChatRooms(uid).listen((rooms) {
      if (_notifFirstLoad) {
        // First snapshot — just record current timestamps, don't notify
        for (final room in rooms) {
          if (room.lastMessage != null) {
            _lastMsgTime[room.id] =
                room.lastMessage!.timestamp.millisecondsSinceEpoch;
          }
        }
        _notifFirstLoad = false;
        return;
      }

      for (final room in rooms) {
        if (room.lastMessage == null) continue;
        final msg = room.lastMessage!;

        // Skip own messages
        if (msg.senderId == uid) continue;
        // Skip if user is currently in this chat
        if (ActiveChatTracker.activeChatRoomId == room.id) continue;

        final prevTime = _lastMsgTime[room.id] ?? 0;
        final newTime = msg.timestamp.millisecondsSinceEpoch;

        if (newTime > prevTime) {
          _lastMsgTime[room.id] = newTime;
          NotificationService().showMessageNotification(
            senderName: msg.senderName,
            message: msg.content,
            chatRoomId: room.id,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return const LoginScreen(level: 2);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level 2 — Intermediate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('BLoC + WebSocket + Offline Cache + Search',
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
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Icon(
                      connected ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: connected ? AppTheme.primaryLight : Colors.red[300],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connected ? 'WS' : 'Off',
                      style: TextStyle(
                        fontSize: 11,
                        color: connected ? AppTheme.primaryLight : Colors.red[300],
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
                  MaterialPageRoute(builder: (_) => const LoginScreen(level: 2)));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Level 2 info banner
          Container(
            width: double.infinity,
            color: AppTheme.level2Color.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppTheme.level2Color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BLoC manages state · WebSocket typing · Hive offline cache · Search',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),

          // ─── Search bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),

          // ─── Chat list ───────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<ChatRoom>>(
              stream: ChatService().getChatRooms(currentUser.uid),
              builder: (context, snapshot) {
                var rooms = snapshot.data ?? [];

                // Filter by search query
                if (_query.isNotEmpty) {
                  rooms = rooms.where((room) {
                    final name = room.displayName(currentUser.uid).toLowerCase();
                    return name.contains(_query);
                  }).toList();
                }

                if (rooms.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          _query.isNotEmpty ? 'No results for "$_query"' : 'No conversations yet',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final otherUid = room.memberIds
                        .firstWhere((id) => id != currentUser.uid, orElse: () => '');

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.level2Color,
                            child: Text(
                              room.avatarInitials(currentUser.uid),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          // ─── Online indicator ─────────────────
                          if (otherUid.isNotEmpty)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: StreamBuilder<bool>(
                                stream: ChatService().watchUserOnline(otherUid),
                                builder: (context, snap) {
                                  final online = snap.data ?? false;
                                  return Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: online ? Colors.green : Colors.grey,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        room.displayName(currentUser.uid),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: room.lastMessage != null
                          ? Text(
                              room.lastMessage!.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            )
                          : null,
                      trailing: room.lastMessage != null
                          ? Text(
                              DateFormat('HH:mm').format(room.lastMessage!.timestamp),
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
