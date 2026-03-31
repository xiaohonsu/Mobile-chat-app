import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'level2/services/local_cache_service.dart';
import 'level_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Level 2 offline cache
  await LocalCacheService.init();

  // Firebase initialization (uncomment when using real Firebase):
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App — Flutter Seminar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LevelSelectorScreen(),
    );
  }
}
