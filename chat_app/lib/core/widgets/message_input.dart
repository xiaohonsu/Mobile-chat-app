import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MessageInput extends StatefulWidget {
  final void Function(String text) onSend;
  final void Function()? onTypingStart;
  final void Function()? onTypingStop;

  const MessageInput({
    super.key,
    required this.onSend,
    this.onTypingStart,
    this.onTypingStop,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
    widget.onTypingStop?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onChanged: (value) {
                  final hasText = value.trim().isNotEmpty;
                  if (hasText != _hasText) {
                    setState(() => _hasText = hasText);
                    if (hasText) {
                      widget.onTypingStart?.call();
                    } else {
                      widget.onTypingStop?.call();
                    }
                  }
                },
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSend,
            child: CircleAvatar(
              backgroundColor: _hasText ? AppTheme.primaryLight : Colors.grey,
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
