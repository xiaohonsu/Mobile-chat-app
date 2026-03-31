import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/chat_room.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/message_bubble.dart';
import '../../core/widgets/message_input.dart';
import '../../level1/services/chat_service.dart';
import '../blocs/chat_bloc.dart';
import '../services/websocket_service.dart';

class Level2ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final UserModel currentUser;

  const Level2ChatScreen({
    super.key,
    required this.chatRoom,
    required this.currentUser,
  });

  @override
  State<Level2ChatScreen> createState() => _Level2ChatScreenState();
}

class _Level2ChatScreenState extends State<Level2ChatScreen> {
  late final ChatBloc _bloc;
  final _scrollController = ScrollController();
  bool _otherIsTyping = false;
  StreamSubscription? _typingSub;

  @override
  void initState() {
    super.initState();
    _bloc = ChatBloc(widget.chatRoom.id)
      ..add(LoadMessages(widget.chatRoom.id));

    // Listen to typing events from WebSocket
    _typingSub = WebSocketService().typingStream.listen((typingMap) {
      final otherTyping = typingMap.entries
          .where((e) => e.key != widget.currentUser.uid)
          .any((e) => e.value);
      if (mounted && otherTyping != _otherIsTyping) {
        setState(() => _otherIsTyping = otherTyping);
        // Auto-clear typing indicator after 3s
        if (otherTyping) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _otherIsTyping = false);
          });
        }
      }
    });

    // Simulate the other user typing after 2s for demo
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        WebSocketService().simulateTyping(
          widget.chatRoom.memberIds
              .firstWhere((id) => id != widget.currentUser.uid),
          widget.chatRoom.id,
          true,
        );
      }
    });
  }

  @override
  void dispose() {
    _bloc.close();
    _typingSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
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
                  // Real-time online/offline + typing indicator
                  Builder(builder: (context) {
                    final otherUid = widget.chatRoom.memberIds
                        .firstWhere((id) => id != widget.currentUser.uid,
                            orElse: () => '');
                    if (_otherIsTyping) {
                      return Text(
                        'typing...',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryLight,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    return StreamBuilder<bool>(
                      stream: otherUid.isNotEmpty
                          ? ChatService().watchUserOnline(otherUid)
                          : const Stream.empty(),
                      builder: (context, snap) {
                        final online = snap.data ?? false;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: online ? Colors.greenAccent : Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              online ? 'online' : 'offline',
                              style: TextStyle(
                                fontSize: 11,
                                color: online ? Colors.white70 : Colors.grey[400],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showBlocDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Concept banner
            _buildBanner(),

            // Messages — powered by BLoC instead of setState
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is ChatLoaded) {
                    Future.microtask(_scrollToBottom);
                  }
                },
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ChatCached) {
                    // Cached data — shown instantly while fetching
                    return _buildMessageList(state.messages,
                        banner: 'Loaded from local cache');
                  }

                  if (state is ChatLoaded) {
                    return _buildMessageList(state.messages,
                        offlineBanner: state.isOffline
                            ? 'Offline — showing cached messages'
                            : null);
                  }

                  if (state is ChatError) {
                    return Center(child: Text(state.message));
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Typing indicator
            if (_otherIsTyping)
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    const _TypingDots(),
                    const SizedBox(width: 8),
                    Text(
                      widget.chatRoom
                          .displayName(widget.currentUser.uid)
                          .split(' ')
                          .first,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(' is typing...',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),

            // Input — dispatches BLoC events instead of calling service directly
            MessageInput(
              onSend: (text) =>
                  _bloc.add(SendMessage(widget.chatRoom.id, text)),
              onTypingStart: () =>
                  _bloc.add(TypingStarted(widget.chatRoom.id)),
              onTypingStop: () =>
                  _bloc.add(TypingStopped(widget.chatRoom.id)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      color: AppTheme.level2Color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 13, color: AppTheme.level2Color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'BLoC: Widget dispatches Events → Bloc emits States → UI rebuilds',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    List<dynamic> messages, {
    String? banner,
    String? offlineBanner,
  }) {
    return Column(
      children: [
        if (banner != null)
          Container(
            width: double.infinity,
            color: Colors.amber[50],
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(banner,
                style: const TextStyle(fontSize: 11, color: Colors.amber)),
          ),
        if (offlineBanner != null)
          Container(
            width: double.infinity,
            color: Colors.orange[50],
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, size: 12, color: Colors.orange),
                const SizedBox(width: 6),
                Text(offlineBanner,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.orange)),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
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
          ),
        ),
      ],
    );
  }

  void _showBlocDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Level 2 — Key Concepts'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoItem(
                icon: Icons.account_tree,
                title: 'BLoC Pattern',
                body: 'Event → BLoC → State → UI\n'
                    'ChatBloc handles: LoadMessages,\n'
                    'SendMessage, TypingStarted',
              ),
              SizedBox(height: 12),
              _InfoItem(
                icon: Icons.swap_horiz,
                title: 'WebSocket',
                body: 'Persistent TCP connection.\n'
                    'Server pushes events instantly:\n'
                    'typing, seen, presence',
              ),
              SizedBox(height: 12),
              _InfoItem(
                icon: Icons.storage,
                title: 'Hive Cache (Offline)',
                body: 'Cache-first strategy:\n'
                    '1. Show cache immediately\n'
                    '2. Fetch from server\n'
                    '3. Update UI with fresh data',
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

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.level2Color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              Text(body, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
