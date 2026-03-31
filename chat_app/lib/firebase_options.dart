// ⚠️  FILE NÀY CẦN ĐƯỢC TẠO TỰ ĐỘNG BỞI FLUTTERFIRE CLI
// ⚠️  KHÔNG COMMIT FILE NÀY LÊN GITHUB SAU KHI CÓ API KEYS THẬT
//
// Để tạo file này, chạy lệnh sau trong terminal:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Chọn Firebase project của bạn và FlutterFire sẽ tự động tạo
// file này với đúng API keys cho iOS và Android.
//
// ─────────────────────────────────────────────────────────────
// PLACEHOLDER — sẽ bị ghi đè bởi flutterfire configure

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
        throw UnsupportedError(
            'DefaultFirebaseOptions không hỗ trợ platform này.\n'
            'Chạy: flutterfire configure');
    }
  }

  // ─── Thay thế bằng giá trị thật từ Firebase Console ───────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.seminar.chatApp',
  );
}
