import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'level1/screens/login_screen.dart';
import 'level2/screens/chat_list_screen.dart' as l2;
import 'level3/screens/chat_screen.dart' as l3;

class LevelSelectorScreen extends StatelessWidget {
  const LevelSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        title: const Text('Chat App Demo'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Demo Level',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Each level adds more features on top of the previous.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _LevelCard(
                level: 1,
                title: 'Simple Chat',
                subtitle: 'Firebase Auth + Firestore + StreamBuilder',
                color: AppTheme.level1Color,
                features: const [
                  'Email / Password login',
                  'Real-time messages via Stream',
                  'Atomic batch writes',
                  'Online/Offline status',
                ],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _LevelCard(
                level: 2,
                title: 'Intermediate',
                subtitle: 'BLoC + WebSocket + FCM + Offline Cache',
                color: AppTheme.level2Color,
                features: const [
                  'BLoC state management',
                  'WebSocket real-time events',
                  'Typing indicator',
                  'Offline cache (Hive)',
                ],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const l2.ChatListScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _LevelCard(
                level: 3,
                title: 'Advanced',
                subtitle: 'E2EE + WebRTC + Security',
                color: AppTheme.level3Color,
                features: const [
                  'End-to-End Encryption',
                  'Voice / Video call (WebRTC)',
                  'Firestore Security Rules',
                  'JWT + Secure Storage',
                ],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const l3.AdvancedChatScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final String title;
  final String subtitle;
  final Color color;
  final List<String> features;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
            // Features
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: features
                    .map(
                      (f) => Chip(
                        label: Text(f,
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor: color.withOpacity(0.08),
                        side: BorderSide(color: color.withOpacity(0.2)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
