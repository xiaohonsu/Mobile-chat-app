import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../../core/models/chat_room.dart';

/// Màn hình tạo chat mới — chọn user để bắt đầu cuộc trò chuyện
class NewChatScreen extends StatefulWidget {
  final UserModel currentUser;
  const NewChatScreen({super.key, required this.currentUser});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await ChatService().getAvailableUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _loading = false;
      });
    }
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    final chatId = await ChatService().getOrCreateChatRoom(
      uid1: widget.currentUser.uid,
      name1: widget.currentUser.displayName,
      uid2: user['uid'] as String,
      name2: user['displayName'] as String,
    );

    if (!mounted) return;

    final room = ChatRoom(
      id: chatId,
      memberIds: [widget.currentUser.uid, user['uid'] as String],
      memberNames: [
        widget.currentUser.displayName,
        user['displayName'] as String,
      ],
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatRoom: room,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No other users found.\nAsk teammates to register!', textAlign: TextAlign.center))
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final name = user['displayName'] as String? ?? 'User';
                    final email = user['email'] as String? ?? '';
                    final isOnline = user['isOnline'] as bool? ?? false;
                    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            child: Text(initials,
                                style: const TextStyle(color: Colors.white)),
                          ),
                          if (isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(email,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                      trailing: Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      onTap: () => _startChat(user),
                    );
                  },
                ),
    );
  }
}
