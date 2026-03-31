# Chat App — Simple to Advanced
### Flutter & Dart | Advanced Mobile Application Development Seminar

Ứng dụng chat demo 3 cấp độ, từ đơn giản đến nâng cao, sử dụng **Firebase Cloud** thật + **WebSocket server** thật.

---

## Yêu cầu

- Flutter SDK ≥ 3.11
- Node.js ≥ 18 (cho WebSocket server)
- Android Studio / VS Code
- Internet connection

---

## Setup & Chạy

### 1. Clone project

```bash
git clone https://github.com/xiaohonsu/Mobile-chat-app.git
```

### 2. Cài dependencies

```bash
# Flutter app
cd source_code/chat_app
flutter pub get

# WebSocket server
cd ../websocket_server
npm install
```

### 3. Firebase đã cấu hình sẵn

Project đã kết nối với Firebase project `chat-app-a4569`. Các file config đã có sẵn:
- `android/app/google-services.json` — Android config
- `lib/firebase_options.dart` — Dart config (Android + Web)

**Không cần làm gì thêm**, chỉ cần chạy app.

### 4. Chạy app

**Bước 1 — Khởi động WebSocket server (terminal 1):**
```bash
cd source_code/websocket_server
node server.js
# → WebSocket server listening on ws://localhost:8080
```

**Bước 2 — Mở Android Emulator:**
```bash
flutter emulators --launch Pixel_7_API35
```

**Bước 3 — Chạy app trên Emulator (terminal 2):**
```bash
cd source_code/chat_app
flutter run -d emulator-5554
```

**Bước 4 — Chạy app trên Chrome (terminal 3):**
```bash
flutter run -d chrome
```

> **Production:** Deploy WebSocket server lên Railway/Render, rồi chạy:
> ```bash
> flutter run --dart-define=WEBSOCKET_URL=wss://your-app.railway.app
> ```

---

## Cấu trúc Project

```
source_code/
├── websocket_server/          # Node.js WebSocket server
│   ├── server.js              # Server chính — xử lý typing, seen, presence
│   ├── package.json           # Dependencies: ws
│   └── .env.example           # PORT config
│
└── chat_app/
    ├── lib/
    │   ├── main.dart                          # Entry point — Firebase + FCM background handler
    │   ├── firebase_options.dart              # Firebase config (Android + Web)
    │   ├── level_selector_screen.dart         # Màn hình chọn Level 1/2/3
    │   │
    │   ├── core/                              # Shared — dùng cho cả 3 levels
    │   │   ├── models/
    │   │   │   ├── user_model.dart            # uid, displayName, email, isOnline
    │   │   │   ├── message.dart               # content, timestamp, status (sending/sent/delivered/seen), reactions
    │   │   │   └── chat_room.dart             # memberIds, isGroup, groupName, lastMessage
    │   │   ├── theme/app_theme.dart           # Màu sắc, theme toàn app
    │   │   └── widgets/
    │   │       ├── message_bubble.dart        # Widget hiển thị tin nhắn + status ticks
    │   │       └── message_input.dart         # TextField + nút gửi
    │   │
    │   ├── level1/                            # Level 1 — Simple Chat
    │   │   ├── services/
    │   │   │   ├── auth_service.dart          # Firebase Auth (login, register, logout, presence)
    │   │   │   └── chat_service.dart          # Firestore CRUD + real-time streams + pagination + seen
    │   │   └── screens/
    │   │       ├── login_screen.dart
    │   │       ├── register_screen.dart
    │   │       ├── chat_list_screen.dart
    │   │       ├── new_chat_screen.dart
    │   │       └── chat_screen.dart
    │   │
    │   ├── level2/                            # Level 2 — Intermediate
    │   │   ├── blocs/
    │   │   │   └── chat_bloc.dart             # BLoC: LoadMessages, SendMessage, LoadMoreMessages, Typing
    │   │   ├── services/
    │   │   │   ├── websocket_service.dart     # Real WebSocket (web_socket_channel) + auto-reconnect
    │   │   │   ├── local_cache_service.dart   # Hive — offline cache (cache-first strategy)
    │   │   │   └── notification_service.dart  # flutter_local_notifications + FCM + ActiveChatTracker
    │   │   └── screens/
    │   │       ├── chat_list_screen.dart      # Chat list + Search + Online indicator + Notification listener
    │   │       └── chat_screen.dart           # Chat + BLoC + Typing + Pagination + Seen status
    │   │
    │   └── level3/                            # Level 3 — Advanced
    │       ├── services/
    │       │   ├── encryption_service.dart    # E2EE simulation + flutter_secure_storage
    │       │   └── webrtc_service.dart        # WebRTC video call simulation
    │       └── screens/
    │           ├── chat_list_screen.dart      # Chat list (encrypted_chats collection)
    │           ├── new_group_screen.dart      # Tạo group chat có mã hóa
    │           ├── chat_screen.dart           # Chat + E2EE + Reactions + Group support
    │           └── video_call_screen.dart     # Video call UI (WebRTC simulation)
    │
    └── android/
        └── app/
            ├── google-services.json
            └── src/main/AndroidManifest.xml   # POST_NOTIFICATIONS permission
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
  ├── lastMessage: string
  ├── lastMessageTime: timestamp
  ├── typing: { uid: bool }               # Level 2 — real-time typing indicator
  └── messages/{messageId}
        ├── senderId: string
        ├── senderName: string
        ├── content: string               # PLAINTEXT
        ├── type: "text"
        ├── timestamp: timestamp
        ├── status: "sending"|"sent"|"delivered"|"seen"
        └── reactions: { uid: emoji }

# Level 3 — tin nhắn ĐÃ MÃ HÓA
encrypted_chats/{chatId}
  ├── memberIds: [uid1, uid2, ...]        # Hỗ trợ group chat
  ├── isGroup: bool
  ├── groupName: string?
  ├── lastMessage: string                 # CIPHERTEXT (🔒base64...)
  └── messages/{messageId}
        ├── content: string               # CIPHERTEXT (🔒base64.signature)
        ├── status: string
        └── reactions: { uid: emoji }
```

---

## Level 1 — Simple Chat

**Công nghệ:** Firebase Auth + Cloud Firestore + StreamBuilder

**Tính năng:**
- Đăng ký / Đăng nhập bằng Email + Password
- Chat real-time giữa 2 thiết bị qua Firestore `.snapshots()`
- Online / Offline indicator
- Atomic batch write khi gửi tin nhắn (message + lastMessage cùng 1 transaction)

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

**Công nghệ:** BLoC + Real WebSocket + Hive offline cache + Search + Push Notifications + Pagination + Seen status

**Tính năng:**
- **BLoC pattern**: UI chỉ dispatch Event → BLoC xử lý logic → emit State → UI rebuild. Zero logic trong widget.
- **Cache-first**: load Hive cache ngay lập tức (0ms delay) → fetch server background → cập nhật UI
- **Real WebSocket** (`web_socket_channel`): kết nối tới Node.js server tại `websocket_server/`
  - Emulator: `ws://10.0.2.2:8080` | Chrome: `ws://localhost:8080` | Production: `--dart-define=WEBSOCKET_URL=wss://...`
  - Auto-reconnect sau 3 giây nếu mất kết nối
  - Events: `typing_start`, `typing_stop`, `seen`, `user_online`, `user_offline`
- **Typing indicator**: WebSocket gửi `typing_start`/`typing_stop` → server broadcast tới room members + đồng thời ghi Firestore để sync đa nền tảng
- **Seen/Delivered status**: khi mở chat room → batch update tất cả tin nhắn chưa đọc thành `seen` → MessageBubble hiện ✓ (sent) / ✓✓ grey (delivered) / ✓✓ blue (seen)
- **Message Pagination**: 50 tin nhắn mới nhất được load ban đầu. Nút "Load earlier messages" ở đầu danh sách dùng cursor-based pagination (`startAfterDocument`)
- **Online/Offline real-time**: StreamBuilder theo dõi `isOnline` từ Firestore
- **Search**: lọc cuộc trò chuyện theo tên user theo thời gian thực
- **Push Notifications** (`flutter_local_notifications` + FCM):
  - Nhận tin mới → hiện notification banner hệ thống
  - Không hiện nếu đang mở đúng chat đó (`ActiveChatTracker`)
  - FCM token lưu Firestore (sẵn sàng cho Cloud Functions background notifications)

**Flow BLoC:**
```
User gõ phím
  → widget.add(TypingStarted(roomId))
  → ChatBloc._onTypingStarted()
      → WebSocketService().sendTypingStart(roomId)   // TCP frame → server
      → ChatService().setTyping(roomId, uid, true)   // Firestore (cross-platform)
  → Server broadcasts { type: 'typing_start' } tới room members
  → Thiết bị kia: WebSocketService._handleMessage() → typingStream.add({userId: true})
  → UI: StreamBuilder trên typing indicator rebuild → hiện "typing..."
```

**Code quan trọng:**
```dart
// websocket_service.dart — real connection với auto-reconnect
void _connect() {
  _channel = WebSocketChannel.connect(Uri.parse('$_serverUrl?userId=$_userId'));
  _channelSub = _channel!.stream.listen(
    _handleMessage,
    onError: (_) => _scheduleReconnect(),
    onDone: _scheduleReconnect,
  );
}

// chat_bloc.dart — cache-first strategy
Future<void> _onLoadMessages(LoadMessages event, Emitter emit) async {
  emit(ChatLoading());
  final cached = await LocalCacheService.getCachedMessages(chatRoomId);
  if (cached.isNotEmpty) emit(ChatCached(cached));     // instant từ cache
  _messagesSub = ChatService().getMessages(chatRoomId) // subscribe server
      .listen((msgs) => add(_NewMessageReceived(msgs)));
  ChatService().markMessagesAsSeen(chatRoomId, uid);   // batch update seen
}

// chat_service.dart — pagination
Stream<List<Message>> getMessages(String chatRoomId, {int limit = 50}) {
  return _db.collection('chats/$chatRoomId/messages')
      .orderBy('timestamp')
      .limitToLast(limit)   // 50 tin nhắn mới nhất
      .snapshots()
      .map((snap) => snap.docs.map(_msgFromDoc).toList());
}
```

---

## Level 3 — Advanced

**Công nghệ:** E2EE (RSA simulation) + flutter_secure_storage + Message Reactions + Group Chat + WebRTC simulation

**Tính năng:**
- **E2EE simulation**: tin nhắn mã hóa (base64 + signature) trước khi lưu Firestore — server chỉ thấy ciphertext
- **flutter_secure_storage**: private key lưu vào Keychain (iOS) / EncryptedSharedPreferences (Android) — tự động load lại sau restart app, tự generate nếu là lần đầu
- **Separate encrypted collection**: `encrypted_chats/` riêng — Firebase Console thấy rõ sự khác biệt
- **Toggle Raw/Decrypted**: xem ciphertext trong DB vs plaintext sau khi decrypt
- **Message Reactions**: long press → emoji picker → lưu Firestore → sync real-time
- **Group Chat**: nhiều thành viên, tất cả tin nhắn đều mã hóa
- **WebRTC video call**: simulation UI (concept demo)

**Code quan trọng:**
```dart
// encryption_service.dart — secure key storage
Future<KeyPair> getOrCreateKeyPair(String userId) async {
  // 1. Check in-memory cache
  if (_cache.containsKey(userId)) return _cache[userId]!;
  // 2. Load from Keychain/EncryptedSharedPreferences
  final stored = await _storage.read(key: 'keypair_$userId');
  if (stored != null) return KeyPair.fromJson(jsonDecode(stored));
  // 3. First launch — generate & persist securely
  return generateAndSaveKeyPair(userId);
}

// Encrypt trước khi lưu Firestore
String encrypt(String plaintext, String publicKey) {
  final encoded = base64.encode(utf8.encode(plaintext));
  return '🔒$encoded.${_generateSig(publicKey)}'; // ciphertext lưu lên DB
}
```

---

## WebSocket Server

**File:** `source_code/websocket_server/server.js`

**Events (client → server):**
| Event | Data | Mô tả |
|---|---|---|
| `join_room` | `chatRoomId` | Đăng ký nhận events của room này |
| `leave_room` | `chatRoomId` | Rời room |
| `typing_start` | `chatRoomId` | Đang gõ phím |
| `typing_stop` | `chatRoomId` | Ngừng gõ |
| `seen` | `chatRoomId, messageId` | Đã đọc tin nhắn |

**Events (server → client):**
| Event | Data | Mô tả |
|---|---|---|
| `typing_start` | `chatRoomId, userId` | Broadcast tới room members |
| `typing_stop` | `chatRoomId, userId` | Broadcast tới room members |
| `seen` | `chatRoomId, messageId, userId` | Broadcast tới room members |
| `user_online` | `userId` | Broadcast tới tất cả |
| `user_offline` | `userId` | Broadcast tới tất cả |

**Deploy lên production (Railway):**
```bash
# 1. Push code lên GitHub
# 2. Tạo project trên railway.app, connect GitHub repo
# 3. Set root directory = source_code/websocket_server
# 4. Railway tự detect Node.js, chạy "npm start"
# 5. Copy URL (wss://your-app.railway.app) vào flutter run --dart-define
```

---

## Packages

| Package | Mục đích | Level |
|---|---|---|
| `firebase_core` | Khởi tạo Firebase | All |
| `firebase_auth` | Authentication | All |
| `cloud_firestore` | Real-time database | All |
| `firebase_messaging` | FCM push notifications (background) | Level 2 |
| `flutter_bloc` | BLoC state management | Level 2 |
| `equatable` | So sánh BLoC states | Level 2 |
| `hive_flutter` | Offline cache | Level 2 |
| `flutter_local_notifications` | System notification banners | Level 2 |
| `web_socket_channel` | Real WebSocket connection | Level 2 |
| `flutter_secure_storage` | Lưu private key (Keychain/Keystore) | Level 3 |
| `uuid` | Generate unique IDs | All |
| `intl` | Format ngày giờ | All |

---

## Lưu ý

- **Firestore Security Rules**: đang để `allow read, write: if true` (test mode). Đổi rules trước production.
- **Notification trên web**: `flutter_local_notifications` không hỗ trợ web — chỉ hoạt động Android/iOS.
- **Typing indicator**: WebSocket gửi event tới server + Firestore làm fallback để đảm bảo cross-platform sync.
- **E2EE**: là simulation (base64) để demo concept. Production cần `pointycastle` với RSA 2048-bit thật.
- **Online status**: cập nhật khi login/logout. Production nên dùng Firebase Realtime Database presence system để handle app crash.
- **WebSocket auto-reconnect**: tự reconnect sau 3 giây, re-join room sau khi reconnect thành công.

---

*Advanced Mobile Application Development Seminar — Flutter & Dart*
