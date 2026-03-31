# Chat App — Simple to Advanced
### Flutter & Dart | Advanced Mobile Application Development Seminar

---

## Demo nhanh

```bash
cd chat_app
flutter pub get
flutter run
```

Chọn level từ màn hình chính để xem demo từng cấp độ.

---

## Cấu trúc project

```
chat_app/lib/
├── main.dart                        # Entry point
├── level_selector_screen.dart       # Màn hình chọn level
│
├── core/                            # Shared — dùng cho cả 3 levels
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── message.dart
│   │   └── chat_room.dart
│   ├── theme/app_theme.dart
│   └── widgets/
│       ├── message_bubble.dart
│       └── message_input.dart
│
├── level1/                          # Simple — Firebase pattern
│   ├── services/
│   │   ├── auth_service.dart        # Firebase Auth (mock)
│   │   └── chat_service.dart        # Firestore + StreamBuilder (mock)
│   └── screens/
│       ├── login_screen.dart
│       ├── chat_list_screen.dart
│       └── chat_screen.dart
│
├── level2/                          # Intermediate — BLoC + WebSocket
│   ├── blocs/chat_bloc.dart         # Events / States / BLoC
│   ├── services/
│   │   ├── websocket_service.dart   # WebSocket (mock)
│   │   └── local_cache_service.dart # Hive offline cache
│   └── screens/
│       ├── chat_list_screen.dart
│       └── chat_screen.dart
│
└── level3/                          # Advanced — E2EE + WebRTC
    ├── services/
    │   ├── encryption_service.dart  # RSA E2EE (mock)
    │   └── webrtc_service.dart      # WebRTC call (mock)
    └── screens/
        ├── chat_screen.dart
        └── video_call_screen.dart
```

---

## 3 cấp độ

### Level 1 — Simple
- **Firebase Auth** — Email/Password login
- **Cloud Firestore** — Real-time database
- **StreamBuilder** — UI tự động cập nhật khi có tin mới
- **Batch write** — Atomic operations
- Demo accounts: `user1@demo.com / 123456` (Alice), `user2@demo.com / 123456` (Bob)

### Level 2 — Intermediate
- **BLoC pattern** — Tách UI khỏi business logic
- **WebSocket** — Real-time events (typing indicator, presence)
- **Firebase Cloud Messaging (FCM)** — Push notification
- **Hive** — Offline cache với cache-first strategy

### Level 3 — Advanced
- **End-to-End Encryption (E2EE)** — RSA asymmetric encryption
- **WebRTC** — Voice/Video call peer-to-peer
- **Security** — JWT, Firestore Rules, Secure Storage

---

## Chuyển sang Firebase thật

Mỗi service file đều có comment `PRODUCTION:` với code Firebase thật sẵn sàng copy-paste.

```bash
# 1. Thêm Firebase packages
flutter pub add firebase_core cloud_firestore firebase_auth firebase_messaging

# 2. Kết nối Firebase project
flutterfire configure

# 3. Uncomment Firebase code trong:
#    - lib/level1/services/auth_service.dart
#    - lib/level1/services/chat_service.dart
#    - lib/main.dart (Firebase.initializeApp)
```

---

## Packages sử dụng

| Package | Level | Mục đích |
|---------|-------|---------|
| flutter_bloc | 2, 3 | State management |
| equatable | 2, 3 | Value equality cho BLoC |
| hive_flutter | 2 | Offline local cache |
| uuid | 1, 2, 3 | Generate unique IDs |
| intl | 1, 2, 3 | Date/time formatting |

**Production thêm:**
- `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_messaging`
- `web_socket_channel` — WebSocket thật
- `flutter_webrtc` — Voice/Video call
- `encrypt` + `pointycastle` — RSA encryption thật
- `flutter_secure_storage` — Lưu private key an toàn

---

*Seminar — Advanced Mobile Application Development*
