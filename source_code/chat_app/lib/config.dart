import 'package:flutter/foundation.dart';

/// Tự động chọn emulator host theo platform:
///   Android emulator → 10.0.2.2  (alias của localhost trên host machine)
///   Web / Desktop    → localhost
///   Thiết bị thật trên WiFi → IP của laptop (thay thủ công bên dưới)
String get emulatorHost {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
  // Thiết bị thật qua WiFi — thay bằng IP laptop:
  // return '192.168.1.5';
}

const int firestorePort = 8080;
const int authPort = 9099;
const int emulatorUiPort = 4000;
