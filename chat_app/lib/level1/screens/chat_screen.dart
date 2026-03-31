import 'package:flutter/material.dart';
import '../../core/models/chat_room.dart';
import '../../core/models/message.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/message_bubble.dart';
import '../../core/widgets/message_input.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final UserModel currentUser;

  const ChatScreen({
    super.key,
    required this.chatRoom,
    required this.currentUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                widget.chatRoom.avatarInitials(widget.currentUser.uid),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatRoom.displayName(widget.currentUser.uid),
                  style: const TextStyle(fontSize: 15),
                ),
                // Real-time online status từ Firestore
                StreamBuilder<bool>(
                  stream: ChatService().watchUserOnline(
                    widget.chatRoom.memberIds.firstWhere(
                        (id) => id != widget.currentUser.uid,
                        orElse: () => widget.currentUser.uid),
                  ),
                  builder: (_, snap) {
                    final isOnline = snap.data ?? false;
                    return Text(
                      isOnline ? 'online' : 'offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOnline ? Colors.greenAccent : Colors.white54,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showConceptDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Concept banner
          Container(
            width: double.infinity,
            color: AppTheme.level1Color.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 13, color: AppTheme.level1Color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'StreamBuilder + .snapshots() → real-time, no polling',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),

          // 🔑 KEY: StreamBuilder lắng nghe Firestore stream
          // Khi thiết bị khác gửi message → Firestore push → widget rebuild
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: ChatService().getMessages(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];

                // Auto scroll khi có message mới
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom());

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hello! 👋',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return MessageBubble(
                      message: msg,
                      isMe: msg.senderId == widget.currentUser.uid,
                    );
                  },
                );
              },
            ),
          ),

          MessageInput(
            onSend: (text) => ChatService().sendMessage(
              chatRoomId: widget.chatRoom.id,
              content: text,
              senderId: widget.currentUser.uid,
              senderName: widget.currentUser.displayName,
            ),
          ),
        ],
      ),
    );
  }

  void _showConceptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Level 1 — Key Concepts'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CodeNote(
                title: '1. StreamBuilder (real-time UI)',
                code: 'StreamBuilder<List<Message>>(\n'
                    '  stream: chatService.getMessages(id),\n'
                    '  // auto-rebuilds on new message\n'
                    ')',
              ),
              SizedBox(height: 12),
              _CodeNote(
                title: '2. Firestore .snapshots()',
                code: 'collection("chats/\$id/messages")\n'
                    '  .orderBy("timestamp")\n'
                    '  .snapshots() // WebSocket under hood',
              ),
              SizedBox(height: 12),
              _CodeNote(
                title: '3. Batch Write (atomic)',
                code: 'final batch = firestore.batch();\n'
                    'batch.set(messageRef, msgData);\n'
                    'batch.update(chatRef, lastMsg);\n'
                    'await batch.commit(); // all-or-nothing',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _CodeNote extends StatelessWidget {
  final String title;
  final String code;
  const _CodeNote({required this.title, required this.code});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(code,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
        ),
      ],
    );
  }
}
