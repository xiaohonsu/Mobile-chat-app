# Chat App — Simple to Advanced
### Flutter & Dart | Advanced Mobile Application Development Seminar

Ứng dụng chat demo 3 cấp độ, từ đơn giản đến nâng cao, sử dụng **Firebase Cloud** thật (không cần emulator).

---

## Yêu cầu

- Flutter SDK ≥ 3.11
- Android Studio / VS Code
- Internet connection

---

## Setup & Chạy

### 1. Clone project

```bash
git clone https://github.com/xiaohonsu/Mobile-chat-app.git
cd source_code/chat_app
flutter pub get
```

### 2. Firebase đã được cấu hình sẵn

Project đã kết nối với Firebase project `chat-app-a4569`. Các file config đã có sẵn:
- `android/app/google-services.json` — Android config
- `lib/firebase_options.dart` — Dart config (Android + Web)

**Không cần làm gì thêm**, chỉ cần chạy app.

### 3. Chạy app

**Bước 1 — Mở Android Emulator:**
```bash
flutter emulators --launch Pixel_7_API35
```

**Bước 2 — Chạy app trên Emulator (terminal 1):**
```bash
flutter run -d emulator-5554
```

**Bước 3 — Chạy app trên Chrome (terminal 2):**
```bash
flutter run -d chrome --web-port 9191
```

> Nếu port bị chiếm, đổi sang port khác: `--web-port 9292`

---

## Cấu trúc Project

```
chat_app/
├── lib/
│   ├── main.dart                          # Entry point — khởi tạo Firebase + Notifications
│   ├── firebase_options.dart              # Firebase config (Android + Web)
│   ├── level_selector_screen.dart         # Màn hình chọn Level 1/2/3
│   │
│   ├── core/                              # Shared — dùng cho cả 3 levels
│   │   ├── models/
│   │   │   ├── user_model.dart            # Model: uid, displayName, email, isOnline
│   │   │   ├── message.dart               # Model: content, timestamp, status, reactions
│   │   │   └── chat_room.dart             # Model: memberIds, isGroup, groupName, lastMessage
│   │   ├── theme/app_theme.dart           # Màu sắc, theme toàn app
│   │   └── widgets/
│   │       ├── message_bubble.dart        # Widget hiển thị 1 tin nhắn
│   │       └── message_input.dart         # TextField + nút gửi
│   │
│   ├── level1/                            # Level 1 — Simple Chat
│   │   ├── services/
│   │   │   ├── auth_service.dart          # Firebase Auth (login, register, logout)
│   │   │   └── chat_service.dart          # Firestore CRUD + real-time streams + encrypted chat methods
│   │   └── screens/
│   │       ├── login_screen.dart          # Màn hình đăng nhập (có level param)
│   │       ├── register_screen.dart       # Màn hình đăng ký (có level param)
│   │       ├── chat_list_screen.dart      # Danh sách cuộc trò chuyện
│   │       ├── new_chat_screen.dart       # Tạo chat mới (hỗ trợ cả plaintext & encrypted)
│   │       └── chat_screen.dart          # Màn hình nhắn tin
│   │
│   ├── level2/                            # Level 2 — Intermediate
│   │   ├── blocs/
│   │   │   └── chat_bloc.dart             # BLoC: Events → States → UI
│   │   ├── services/
│   │   │   ├── websocket_service.dart     # WebSocket simulation (typing indicator)
│   │   │   ├── local_cache_service.dart   # Hive — offline cache
│   │   │   └── notification_service.dart  # flutter_local_notifications + ActiveChatTracker
│   │   └── screens/
│   │       ├── chat_list_screen.dart      # Chat list + Search + Online indicator + Notification listener
│   │       └── chat_screen.dart           # Chat + BLoC + Typing indicator (Firestore-synced)
│   │
│   └── level3/                            # Level 3 — Advanced
│       ├── services/
│       │   └── encryption_service.dart    # RSA E2EE simulation
│       └── screens/
│           ├── chat_list_screen.dart      # Chat list (encrypted_chats collection)
│           ├── new_group_screen.dart      # Tạo group chat có mã hóa
│           └── chat_screen.dart           # Chat + E2EE + Reactions + Group support
│
├── android/
│   ├── app/
│   │   ├── google-services.json           # Firebase Android config
│   │   ├── build.gradle.kts               # coreLibraryDesugaring (cho flutter_local_notifications)
│   │   └── src/main/
│   │       ├── AndroidManifest.xml        # POST_NOTIFICATIONS permission
│   │       └── res/xml/
│   │           └── network_security_config.xml
│
└── web/                                   # Auto-generated khi enable web
```

---

## Firebase Structure (Firestore)

```
users/{uid}
  ├── displayName: string
  ├── email: string
  ├── isOnline: bool
  ├── lastSeen: timestamp
  └── createdAt: timestamp

# Level 1 & 2 — tin nhắn PLAINTEXT
chats/{chatId}                             # chatId = "uid1_uid2" (sorted)
  ├── memberIds: [uid1, uid2]
  ├── memberNames: [name1, name2]
  ├── isGroup: bool
  ├── groupName: string?
  ├── lastMessage: string
  ├── lastMessageTime: timestamp
  ├── typing: { uid: bool }               # Level 2 — real-time typing indicator
  └── messages/{messageId}
        ├── senderId: string
        ├── senderName: string
        ├── content: string               # PLAINTEXT
        ├── type: "text"
        ├── timestamp: timestamp
        ├── status: "sent" | "delivered" | "seen"
        └── reactions: { uid: emoji }

# Level 3 — tin nhắn ĐÃ MÃ HÓA
encrypted_chats/{chatId}
  ├── memberIds: [uid1, uid2, ...]        # Hỗ trợ group (nhiều thành viên)
  ├── memberNames: [name1, name2, ...]
  ├── isGroup: bool
  ├── groupName: string?
  ├── lastMessage: string                 # CIPHERTEXT (🔒base64...)
  ├── lastMessageTime: timestamp
  └── messages/{messageId}
        ├── senderId: string
        ├── senderName: string
        ├── content: string               # CIPHERTEXT (🔒base64.signature)
        ├── timestamp: timestamp
        ├── status: string
        └── reactions: { uid: emoji }
```

---

## Level 1 — Simple Chat

**Công nghệ:** Firebase Auth + Cloud Firestore + StreamBuilder

**Tính năng:**
- Đăng ký / Đăng nhập bằng Email + Password — **mỗi level có màn hình login riêng**
- Danh sách cuộc trò chuyện, real-time cập nhật
- Chat real-time giữa 2 thiết bị
- Online / Offline indicator (chấm xanh/xám)
- Atomic batch write khi gửi tin nhắn

**Flow:**
```
Level Selector → Login (Level 1) → Chat List → New Chat (chọn user) → Chat Screen
                                                                      ↓
                                                            Gõ tin nhắn → Send
                                                            batch.commit():
                                                              1. Thêm message vào subcollection
                                                              2. Cập nhật lastMessage ở chat room
                                                            StreamBuilder nhận snapshot → UI tự cập nhật
```

**Code quan trọng:**
```dart
// Real-time stream — không cần polling
Stream<List<Message>> getMessages(String chatRoomId) {
  return _db
      .collection('chats/$chatRoomId/messages')
      .orderBy('timestamp')
      .snapshots()  // Firestore tự push khi có data mới
      .map((snap) => snap.docs.map(_msgFromDoc).toList());
}

// Atomic batch write
final batch = _db.batch();
batch.set(messageRef, { 'content': content, ... });       // thêm message
batch.update(chatRef, { 'lastMessage': content, ... });   // update preview
await batch.commit();  // cả 2 thành công hoặc thất bại cùng nhau
```

---

## Level 2 — Intermediate

**Công nghệ:** BLoC + WebSocket + Hive offline cache + Search + Online status + **Push Notifications**

**Tính năng:**
- **BLoC pattern**: UI không gọi Firestore trực tiếp, mọi thứ qua Event → BLoC → State
- **Cache-first**: load từ Hive cache ngay lập tức (0ms) → fetch server background
- **Typing indicator (Firestore-synced)**: khi gõ phím → ghi `typing: {uid: true}` lên Firestore → thiết bị kia đọc `.snapshots()` → hiện "typing..." real-time giữa 2 thiết bị
- **Online/Offline real-time**: StreamBuilder theo dõi `isOnline` từ Firestore — cả chat list lẫn trong màn hình chat
- **Search**: tìm kiếm cuộc trò chuyện theo tên user
- **Push Notifications** (`flutter_local_notifications`):
  - Khi nhận tin nhắn mới từ người khác → hiện notification banner hệ thống
  - Không hiện notification nếu đang mở đúng chat room đó (`ActiveChatTracker`)
  - Lần đầu dùng sẽ hỏi quyền thông báo (Android 13+)
  - **Production thay bằng**: Firebase Cloud Messaging (FCM) để nhận notification khi app bị tắt

**Notification — Cách hoạt động:**
```
Thiết bị B gửi tin nhắn
  → Firestore cập nhật lastMessage trong chat room
  → Thiết bị A: StreamSubscription trong ChatListScreen nhận snapshot
  → So sánh lastMessage.timestamp với timestamp cũ
  → Nếu mới hơn + sender != mình + không đang mở chat đó
  → NotificationService.showMessageNotification() → banner hệ thống
```

**Flow:**
```
Login → Chat List (search bar + chấm online/offline)
  → Vào chat room → ActiveChatTracker.activeChatRoomId = roomId
  → Gõ phím → BLoC gọi setTyping(true) → ghi lên Firestore
  → Dừng gõ / gửi → setTyping(false)
  → Thiết bị kia thấy "typing..." real-time qua .snapshots()
  → Thoát chat → activeChatRoomId = null
  → Nhận tin nhắn mới → hiện notification banner
```

**Code quan trọng:**
```dart
// notification_service.dart — flutter_local_notifications
Future<void> showMessageNotification({
  required String senderName,
  required String message,
  required String chatRoomId,
}) async {
  if (!_initialized || kIsWeb) return;
  const androidDetails = AndroidNotificationDetails(
    'chat_messages', 'Chat Messages',
    importance: Importance.high, priority: Priority.high,
  );
  await _plugin.show(chatRoomId.hashCode.abs(), senderName, message,
      const NotificationDetails(android: androidDetails));
}

// Typing indicator — sync qua Firestore (hoạt động giữa 2 thiết bị thật)
Future<void> setTyping(String chatRoomId, String uid, bool isTyping) async {
  await _db.collection('chats').doc(chatRoomId).set(
    {'typing': {uid: isTyping}},
    SetOptions(merge: true),
  );
}

Stream<bool> watchOtherTyping(String chatRoomId, String currentUserId) {
  return _db.collection('chats').doc(chatRoomId).snapshots().map((doc) {
    final typing = doc.data()?['typing'] as Map? ?? {};
    return typing.entries
        .where((e) => e.key != currentUserId)
        .any((e) => e.value == true);
  });
}
```

---

## Level 3 — Advanced

**Công nghệ:** E2EE (RSA simulation) + Message Reactions + Group Chat + Encrypted Firestore collection

**Tính năng:**
- **E2EE simulation**: tin nhắn được mã hóa (base64 + signature) **trước khi lưu lên Firestore** — server chỉ thấy ciphertext
- **Separate encrypted collection**: `encrypted_chats/` riêng biệt với `chats/` — nhìn trong Firebase Console thấy rõ sự khác nhau
- **Toggle "Raw (DB)" / "Decrypted"**: xem đúng nội dung đang lưu trong database vs nội dung sau khi giải mã
- **Message Reactions**: long press → emoji picker → lưu lên Firestore → sync real-time
- **Group Chat**: tạo group với nhiều thành viên, tất cả tin nhắn đều được mã hóa
- **Secure Storage concept**: private key chỉ lưu trên thiết bị, không bao giờ lên server

**Flow:**
```
Level Selector → Login (Level 3) → Chat List (encrypted_chats collection)
  → FAB (+) → chọn "New Encrypted Chat" hoặc "New Group Chat"
  → New Group: nhập tên group → tick chọn thành viên → Create
  → Vào chat room → gõ tin nhắn → encrypt → lưu ciphertext lên Firestore
  → Toggle "Raw (DB)": thấy "🔒SGVsbG8s...abc123" — đúng như trong database
  → Toggle "Decrypted": app decrypt → thấy nội dung bình thường
  → Long press message → emoji picker → reaction lưu lên encrypted_chats
  → Thiết bị kia thấy reaction chip real-time
```

**Firebase Console demo:**
```
Firestore → chats/         → content: "Hello"          ← Level 1 & 2 (plaintext)
Firestore → encrypted_chats/ → content: "🔒SGVsbG8s..." ← Level 3 (encrypted)
```

**Code quan trọng:**
```dart
// Encrypt trước khi lưu
Future<void> _sendMessage(String text) async {
  final pubKey = _encryption.getPublicKey(widget.currentUser.uid);
  final encrypted = _encryption.encrypt(text, pubKey); // → "🔒base64.sig"
  await ChatService().sendEncryptedMessage(
    chatRoomId: widget.chatRoom.id,
    encryptedContent: encrypted, // ciphertext lưu lên Firestore
    ...
  );
}

// Hiển thị — decrypt khi đọc
String displayContent = _showRaw
    ? msg.content  // raw ciphertext từ Firestore
    : _encryption.decrypt(msg.content, privateKey); // plaintext cho user

// encryption_service.dart — RSA simulation
String encrypt(String plaintext, String publicKey) {
  final encoded = base64.encode(utf8.encode(plaintext));
  return '🔒$encoded.${_generateSig(publicKey)}'; // lưu dạng này lên Firestore
}

String decrypt(String ciphertext, String privateKey) {
  final parts = ciphertext.substring(2).split('.');
  return utf8.decode(base64.decode(parts[0])); // giải mã
}
```

---

## Packages

| Package | Mục đích | Level |
|---|---|---|
| `firebase_core` | Khởi tạo Firebase | All |
| `firebase_auth` | Authentication | All |
| `cloud_firestore` | Real-time database | All |
| `flutter_bloc` | BLoC state management | Level 2 |
| `equatable` | So sánh BLoC states | Level 2 |
| `hive_flutter` | Offline cache | Level 2 |
| `flutter_local_notifications` | System notifications | Level 2 |
| `uuid` | Generate unique IDs | Level 2 |
| `intl` | Format ngày giờ | All |

**Production cần thêm:**
- `web_socket_channel` — WebSocket thật thay simulation
- `encrypt` + `pointycastle` — RSA encryption thật
- `flutter_secure_storage` — Lưu private key an toàn
- `firebase_messaging` — FCM push notifications (background + terminated state)

---

## Lưu ý

- **Firestore Security Rules**: đang để `allow read, write: if true` (test mode). Đổi lại rules nghiêm ngặt trước production.
- **Notification trên web**: `flutter_local_notifications` không hỗ trợ web — notification chỉ hoạt động trên Android/iOS.
- **Typing indicator**: dùng Firestore `.snapshots()` để sync giữa 2 thiết bị thật — không phải WebSocket thật, nhưng concept tương tự.
- **E2EE**: là simulation (base64) để demo concept. Production cần `pointycastle` với RSA 2048-bit thật.
- **Online status**: cập nhật khi login/logout. Không handle trường hợp app crash (cần Firebase Realtime Database presence system cho production).
- **Bạn bè dùng chung Firebase**: chỉ cần clone repo, không cần tạo Firebase project mới — dùng chung `chat-app-a4569`.

---

*Advanced Mobile Application Development Seminar — Flutter & Dart*
