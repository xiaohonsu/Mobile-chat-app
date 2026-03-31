import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'config.dart';
import 'core/theme/app_theme.dart';
import 'level2/services/local_cache_service.dart';
import 'level_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Kết nối Firebase Emulator (chạy local trên laptop)
  // Không cần internet, không cần credit card
  await FirebaseAuth.instance.useAuthEmulator(emulatorHost, authPort);
  FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, firestorePort);

  await LocalCacheService.init();

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
