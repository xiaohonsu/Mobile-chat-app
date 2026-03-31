// Firebase Options cho Emulator local
// Project ID "demo-chat-seminar" chỉ là tên local — không cần tồn tại trên cloud.
// Emulator chặn mọi request, không gửi gì lên internet.
// API keys ở đây là dummy — emulator không kiểm tra.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-chat-seminar',
    authDomain: 'demo-chat-seminar.firebaseapp.com',
    storageBucket: 'demo-chat-seminar.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-chat-seminar',
    storageBucket: 'demo-chat-seminar.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-chat-seminar',
    storageBucket: 'demo-chat-seminar.appspot.com',
    iosBundleId: 'com.seminar.chatApp',
  );
}
