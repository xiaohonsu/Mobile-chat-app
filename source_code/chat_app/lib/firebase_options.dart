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

  // Web config — từ Firebase Console > Project Settings > Web app
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC8T48wnho3VqiXTVYPPh8fZsVSgQ14s9E',
    appId: '1:960488613843:web:7b6c0195cff67621ad3126',
    messagingSenderId: '960488613843',
    projectId: 'chat-app-a4569',
    authDomain: 'chat-app-a4569.firebaseapp.com',
    storageBucket: 'chat-app-a4569.firebasestorage.app',
  );

  // Android config — từ google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyASh483TJVXtS0na_-h3O42Au2wikYto9k',
    appId: '1:960488613843:android:724792b74cd6489ead3126',
    messagingSenderId: '960488613843',
    projectId: 'chat-app-a4569',
    storageBucket: 'chat-app-a4569.firebasestorage.app',
  );

  // iOS — không dùng, để placeholder
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder',
    appId: '1:960488613843:ios:000000000000000000000000',
    messagingSenderId: '960488613843',
    projectId: 'chat-app-a4569',
    storageBucket: 'chat-app-a4569.firebasestorage.app',
    iosBundleId: 'com.seminar.chatApp',
  );
}
