import 'package:flutter/material.dart';
import '../../core/models/message.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/message_bubble.dart';
import '../../core/widgets/message_input.dart';
import '../../level1/services/auth_service.dart';
import '../services/encryption_service.dart';
import '../services/webrtc_service.dart';
import 'video_call_screen.dart';

class AdvancedChatScreen extends StatefulWidget {
  const AdvancedChatScreen({super.key});

  @override
  State<AdvancedChatScreen> createState() => _AdvancedChatScreenState();
}

class _AdvancedChatScreenState extends State<AdvancedChatScreen> {
  final _messages = <Message>[];
  final _scrollController = ScrollController();
  final _encryption = EncryptionService();
  late final String _currentUserId;
  late final String _currentUserName;
  late final String _peerId;
  bool _showEncryptedView = false;
  bool _keysGenerated = false;

  @override
  void initState() {
    super.initState();

    final user = AuthService().currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _currentUserName = user.displayName;
      _peerId = 'uid_bob';
    } else {
      _currentUserId = 'demo_user';
      _currentUserName = 'Demo User';
      _peerId = 'uid_bob';
    }

    // Generate keys for demo
    _encryption.generateKeyPair(_currentUserId);
    _encryption.generateKeyPair(_peerId);
    _keysGenerated = true;

    // Seed some encrypted messages
    _messages.addAll([
      Message(
        id: '1',
        senderId: _peerId,
        senderName: 'Bob Tran',
        content: 'Hey! This message is end-to-end encrypted 🔒',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: MessageStatus.seen,
      ),
      Message(
        id: '2',
        senderId: _currentUserId,
        senderName: _currentUserName,
        content: 'Great! Even the server cannot read this.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        status: MessageStatus.seen,
      ),
      Message(
        id: '3',
        senderId: _peerId,
        senderName: 'Bob Tran',
        content: 'RSA public key is on Firestore. Private key stays on device.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        status: MessageStatus.delivered,
      ),
    ]);
  }

  void _sendMessage(String text) {
    // Encrypt with recipient's public key
    final peerPublicKey = _encryption.getPublicKey(_peerId);
    final encrypted = _encryption.encrypt(text, peerPublicKey);

    setState(() {
      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: _currentUserName,
        // Store encrypted content — server only sees this
        content: _showEncryptedView ? encrypted : text,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      ));
    });

    Future.microtask(() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate reply
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _messages.add(Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: _peerId,
          senderName: 'Bob Tran',
          content: 'Got your encrypted message! 🔐',
          timestamp: DateTime.now(),
          status: MessageStatus.delivered,
        ));
      });
    });
  }

  void _startVideoCall() {
    WebRTCService().startCall(
      callerId: _currentUserId,
      callerName: _currentUserName,
      calleeId: _peerId,
      isVideo: true,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          callerName: 'Bob Tran',
          isVideo: true,
        ),
      ),
    );
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
              backgroundColor: AppTheme.level3Color.withOpacity(0.7),
              child: const Text('B', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bob Tran', style: TextStyle(fontSize: 15)),
                Row(
                  children: [
                    const Icon(Icons.lock, size: 10, color: Colors.greenAccent),
                    const SizedBox(width: 3),
                    const Text('E2EE enabled',
                        style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Voice Call (WebRTC)',
            onPressed: () {
              WebRTCService().startCall(
                callerId: _currentUserId,
                callerName: _currentUserName,
                calleeId: _peerId,
                isVideo: false,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VideoCallScreen(
                    callerName: 'Bob Tran',
                    isVideo: false,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            tooltip: 'Video Call (WebRTC)',
            onPressed: _startVideoCall,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Level 3 banner
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
                // Toggle to show encrypted view
                GestureDetector(
                  onTap: () =>
                      setState(() => _showEncryptedView = !_showEncryptedView),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _showEncryptedView
                          ? AppTheme.level3Color
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.level3Color),
                    ),
                    child: Text(
                      _showEncryptedView ? 'Raw' : 'Decrypt',
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
                  Row(
                    children: const [
                      Icon(Icons.vpn_key, size: 13, color: Colors.amber),
                      SizedBox(width: 6),
                      Text('Your Public Key (stored in Firestore):',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _encryption.getPublicKey(_currentUserId),
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.lock, size: 13, color: Colors.red),
                      SizedBox(width: 6),
                      Text('Private Key: stored in Secure Storage (device only)',
                          style: TextStyle(
                              fontSize: 11, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return MessageBubble(
                  message: msg,
                  isMe: msg.senderId == _currentUserId,
                  showEncrypted: true,
                );
              },
            ),
          ),

          // Security features row
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SecurityBadge(
                  icon: Icons.lock,
                  label: 'E2EE',
                  color: Colors.green,
                ),
                _SecurityBadge(
                  icon: Icons.verified_user,
                  label: 'JWT Auth',
                  color: Colors.blue,
                ),
                _SecurityBadge(
                  icon: Icons.shield,
                  label: 'Firestore Rules',
                  color: Colors.orange,
                ),
                _SecurityBadge(
                  icon: Icons.storage,
                  label: 'Secure Storage',
                  color: AppTheme.level3Color,
                ),
              ],
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
                  'Private key → Secure Storage (local)',
                  'Messages encrypted before sending',
                  'Only recipient can decrypt',
                ],
              ),
              SizedBox(height: 16),
              _InfoSection(
                icon: Icons.video_call,
                color: Colors.blue,
                title: 'WebRTC Voice/Video Call',
                items: [
                  'createOffer() → Firestore signaling',
                  'ICE Candidates exchange',
                  'Peer-to-peer media stream',
                  'STUN/TURN server for NAT traversal',
                  'Package: flutter_webrtc',
                ],
              ),
              SizedBox(height: 16),
              _InfoSection(
                icon: Icons.security,
                color: Colors.orange,
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

class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SecurityBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

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
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: color)),
                Expanded(
                  child: Text(item, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
