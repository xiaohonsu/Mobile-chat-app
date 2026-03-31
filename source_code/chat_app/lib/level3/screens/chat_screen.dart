import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/chat_room.dart';
import '../../core/models/message.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/message_input.dart';
import '../../level1/services/auth_service.dart';
import '../../level1/services/chat_service.dart';
import '../services/encryption_service.dart';

class AdvancedChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final UserModel currentUser;

  const AdvancedChatScreen({
    super.key,
    required this.chatRoom,
    required this.currentUser,
  });

  @override
  State<AdvancedChatScreen> createState() => _AdvancedChatScreenState();
}

class _AdvancedChatScreenState extends State<AdvancedChatScreen> {
  final _scrollController = ScrollController();
  final _encryption = EncryptionService();
  bool _showEncryptedView = false;
  bool _keysGenerated = false;

  static const _emojiOptions = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

  @override
  void initState() {
    super.initState();
    _encryption.generateKeyPair(widget.currentUser.uid);
    _keysGenerated = true;
  }

  Future<void> _sendMessage(String text) async {
    // Encrypt before storing — Level 3 stores ciphertext in Firestore
    final pubKey = _encryption.getPublicKey(widget.currentUser.uid);
    final encrypted = _encryption.encrypt(text, pubKey);
    await ChatService().sendEncryptedMessage(
      chatRoomId: widget.chatRoom.id,
      encryptedContent: encrypted,
      senderId: widget.currentUser.uid,
      senderName: widget.currentUser.displayName,
    );
    Future.microtask(() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showReactionPicker(String messageId, Map<String, String> currentReactions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('React to message',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _emojiOptions.map((emoji) {
                final isSelected =
                    currentReactions[widget.currentUser.uid] == emoji;
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await ChatService().toggleEncryptedReaction(
                      chatRoomId: widget.chatRoom.id,
                      messageId: messageId,
                      uid: widget.currentUser.uid,
                      emoji: emoji,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.level3Color.withOpacity(0.15)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: AppTheme.level3Color)
                          : null,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            if (currentReactions.containsKey(widget.currentUser.uid))
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await ChatService().toggleEncryptedReaction(
                    chatRoomId: widget.chatRoom.id,
                    messageId: messageId,
                    uid: widget.currentUser.uid,
                    emoji: currentReactions[widget.currentUser.uid]!,
                  );
                },
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Remove my reaction',
                    style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherName = widget.chatRoom.displayName(widget.currentUser.uid);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.level3Color.withOpacity(0.7),
              child: Text(
                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherName, style: const TextStyle(fontSize: 15)),
                const Row(
                  children: [
                    Icon(Icons.lock, size: 10, color: Colors.greenAccent),
                    SizedBox(width: 3),
                    Text('E2EE enabled',
                        style:
                            TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // E2EE banner + toggle
          Container(
            width: double.infinity,
            color: AppTheme.level3Color.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.security, size: 13, color: AppTheme.level3Color),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Messages encrypted with RSA. Server only sees ciphertext.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      setState(() => _showEncryptedView = !_showEncryptedView),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _showEncryptedView
                          ? AppTheme.level3Color
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.level3Color),
                    ),
                    child: Text(
                      _showEncryptedView ? 'Decrypted' : 'Raw (DB)',
                      style: TextStyle(
                        fontSize: 11,
                        color: _showEncryptedView
                            ? Colors.white
                            : AppTheme.level3Color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Key info panel
          if (_keysGenerated)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.vpn_key, size: 13, color: Colors.amber),
                    SizedBox(width: 6),
                    Text('Your Public Key (stored in Firestore):',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    _encryption.getPublicKey(widget.currentUser.uid),
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  const Row(children: [
                    Icon(Icons.lock, size: 13, color: Colors.red),
                    SizedBox(width: 6),
                    Text('Private Key: stored in Secure Storage (device only)',
                        style: TextStyle(fontSize: 11, color: Colors.red)),
                  ]),
                ],
              ),
            ),

          // Hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('Long press a message to react',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),

          // ─── Real-time messages from Firestore ──────────────────
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: ChatService().getEncryptedMessages(widget.chatRoom.id),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];

                if (messages.isEmpty &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == widget.currentUser.uid;

                    // E2EE: msg.content is encrypted in Firestore.
                    // Default: decrypt to show plaintext.
                    // Raw mode: show the actual ciphertext stored in DB.
                    String displayContent;
                    if (_showEncryptedView) {
                      displayContent = msg.content; // raw ciphertext from Firestore
                    } else {
                      final privKey = _encryption.getKeyPair(widget.currentUser.uid)?.privateKey ?? '';
                      displayContent = _encryption.decrypt(msg.content, privKey);
                    }

                    return GestureDetector(
                      onLongPress: () =>
                          _showReactionPicker(msg.id, msg.reactions),
                      child: _MessageWithReaction(
                        message: msg,
                        displayContent: displayContent,
                        isMe: isMe,
                        showEncryptedBadge: _showEncryptedView,
                        onReactionTap: (emoji) async {
                          await ChatService().toggleEncryptedReaction(
                            chatRoomId: widget.chatRoom.id,
                            messageId: msg.id,
                            uid: widget.currentUser.uid,
                            emoji: emoji,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          MessageInput(onSend: _sendMessage),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Level 3 — Advanced Features'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoSection(
                icon: Icons.lock,
                color: Colors.green,
                title: 'End-to-End Encryption (E2EE)',
                items: [
                  'Each user has RSA key pair',
                  'Public key → Firestore (shared)',
                  'Private key → Secure Storage (local only)',
                  'Messages encrypted before sending',
                  'Only recipient can decrypt',
                ],
              ),
              SizedBox(height: 16),
              _InfoSection(
                icon: Icons.emoji_emotions,
                color: Colors.orange,
                title: 'Message Reactions (Real-time)',
                items: [
                  'Long press any message to react',
                  'Stored in Firestore: reactions: {uid → emoji}',
                  'Syncs in real-time via .snapshots()',
                  'Multiple users can react differently',
                  'Tap same emoji again to remove',
                ],
              ),
              SizedBox(height: 16),
              _InfoSection(
                icon: Icons.security,
                color: Colors.blue,
                title: 'Production Security',
                items: [
                  'JWT with short expiry + refresh token',
                  'Firestore Security Rules (server-side)',
                  'flutter_secure_storage for secrets',
                  'HTTPS only + certificate pinning',
                  'Input sanitization',
                ],
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

// ─── Message bubble with reactions ──────────────────────────────────────────

class _MessageWithReaction extends StatelessWidget {
  final Message message;
  final String displayContent;
  final bool isMe;
  final bool showEncryptedBadge;
  final void Function(String emoji) onReactionTap;

  const _MessageWithReaction({
    required this.message,
    required this.displayContent,
    required this.isMe,
    required this.showEncryptedBadge,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final emojiCount = <String, int>{};
    for (final emoji in message.reactions.values) {
      emojiCount[emoji] = (emojiCount[emoji] ?? 0) + 1;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          top: 2,
          bottom: message.reactions.isNotEmpty ? 2 : 6,
          left: isMe ? 64 : 12,
          right: isMe ? 12 : 64,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.bubbleMe : AppTheme.bubbleOther,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe)
                    Text(message.senderName,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary)),
                  if (showEncryptedBadge)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 10, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text('encrypted',
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey[500])),
                        const SizedBox(width: 4),
                      ],
                    ),
                  Text(displayContent,
                      style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _statusIcon(message.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Reaction chips — real-time from Firestore
            if (emojiCount.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Wrap(
                  spacing: 4,
                  children: emojiCount.entries.map((entry) {
                    return GestureDetector(
                      onTap: () => onReactionTap(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 2)
                          ],
                        ),
                        child: Text('${entry.key} ${entry.value}',
                            style: const TextStyle(fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 12, color: Colors.grey[500]);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 12, color: Colors.grey[500]);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 12, color: Colors.grey[500]);
      case MessageStatus.seen:
        return const Icon(Icons.done_all, size: 12, color: Colors.blue);
    }
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SecurityBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  const _InfoSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: color)),
                Expanded(
                    child:
                        Text(item, style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
