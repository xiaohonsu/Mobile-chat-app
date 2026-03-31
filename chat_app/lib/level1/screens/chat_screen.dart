import 'package:flutter/material.dart';
import '../../core/models/chat_room.dart';
import '../../core/models/message.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/message_bubble.dart';
import '../../core/widgets/message_input.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatelessWidget {
  final ChatRoom chatRoom;
  final UserModel currentUser;

  const ChatScreen({
    super.key,
    required this.chatRoom,
    required this.currentUser,
  });

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
                chatRoom.avatarInitials(currentUser.uid),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatRoom.displayName(currentUser.uid),
                  style: const TextStyle(fontSize: 15),
                ),
                const Text('online',
                    style:
                        TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Key concept',
            onPressed: () => _showConceptDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Concept banner
          _ConceptBanner(
            text: 'StreamBuilder + .snapshots() → real-time, no polling',
            color: AppTheme.level1Color,
          ),

          // 🔑 KEY CONCEPT: StreamBuilder listens to Firestore stream
          // Every time a new message is added to Firestore,
          // this widget automatically rebuilds — zero manual refresh needed.
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: ChatService().getMessages(chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet.\nSay hello! 👋',
                        textAlign: TextAlign.center),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return MessageBubble(
                      message: msg,
                      isMe: msg.senderId == currentUser.uid,
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          MessageInput(
            onSend: (text) => ChatService().sendMessage(
              chatRoomId: chatRoom.id,
              content: text,
              senderId: currentUser.uid,
              senderName: currentUser.displayName,
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
                title: 'StreamBuilder (real-time UI)',
                code: 'StreamBuilder<List<Message>>(\n'
                    '  stream: chatService.getMessages(id),\n'
                    '  builder: (context, snapshot) {\n'
                    '    // rebuilds automatically\n'
                    '    // when new message arrives\n'
                    '  },\n'
                    ')',
              ),
              SizedBox(height: 12),
              _CodeNote(
                title: 'Batch Write (atomicity)',
                code: 'final batch = firestore.batch();\n'
                    'batch.set(messageRef, msgData);\n'
                    'batch.update(chatRef, lastMsg);\n'
                    'await batch.commit(); // atomic',
              ),
              SizedBox(height: 12),
              _CodeNote(
                title: 'Server Timestamp',
                code: "'timestamp': FieldValue\n"
                    '    .serverTimestamp()',
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

class _ConceptBanner extends StatelessWidget {
  final String text;
  final Color color;

  const _ConceptBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 11, color: Colors.grey[700])),
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
          child: Text(
            code,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
      ],
    );
  }
}
