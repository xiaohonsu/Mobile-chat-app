# Chat App — Simple to Advanced
### Flutter & Dart | Advanced Mobile Application Development Seminar

Ứng dụng chat demo 3 cấp độ, từ đơn giản đến nâng cao, sử dụng **Firebase Cloud** thật (không cần emulator).

---

## Yêu cầu

- Flutter SDK ≥ 3.11
- Android Studio / VS Code
- Google account (để truy cập Firebase Console)
- Internet connection

---

## Setup & Chạy

### 1. Clone project

```bash
git clone <repo-url>
cd source_code/chat_app
flutter pub get
```

### 2. Firebase đã được cấu hình sẵn

Project đã kết nối với Firebase project `chat-app-a4569`. Các file config đã có sẵn:
- `android/app/google-services.json` — Android config
- `lib/firebase_options.dart` — Dart config (Android + Web)

**Không cần làm gì thêm**, chỉ cần chạy app.

### 3. Chạy app

**Android Emulator (thiết bị 1):**
```bash
flutter run -d emulator-5554
```

**Chrome Web (thiết bị 2 — để demo real-time):**
```bash
flutter run -d chrome --web-port 9091
```

> Nếu port bị chiếm, đổi sang port khác: `--web-port 9092`

---

## Cấu trúc Project

```
chat_app/
├── lib/
│   ├── main.dart                          # Entry point — khởi tạo Firebase
│   ├── firebase_options.dart              # Firebase config (Android + Web)
│   ├── level_selector_screen.dart         # Màn hình chọn Level 1/2/3
│   │
│   ├── core/                              # Shared — dùng cho cả 3 levels
│   │   ├── models/
│   │   │   ├── user_model.dart            # Model: uid, displayName, email, isOnline
│   │   │   ├── message.dart               # Model: content, timestamp, status, reactions
│   │   │   └── chat_room.dart             # Model: memberIds, lastMessage
│   │   ├── theme/app_theme.dart           # Màu sắc, theme toàn app
│   │   └── widgets/
│   │       ├── message_bubble.dart        # Widget hiển thị 1 tin nhắn
│   │       └── message_input.dart         # TextField + nút gửi
│   │
│   ├── level1/                            # Level 1 — Simple Chat
│   │   ├── services/
│   │   │   ├── auth_service.dart          # Firebase Auth (login, register, logout)
│   │   │   └── chat_service.dart          # Firestore CRUD + real-time streams
│   │   └── screens/
│   │       ├── login_screen.dart          # Màn hình đăng nhập
│   │       ├── register_screen.dart       # Màn hình đăng ký
│   │       ├── chat_list_screen.dart      # Danh sách cuộc trò chuyện
│   │       ├── new_chat_screen.dart       # Tạo chat mới — chọn user
│   │       └── chat_screen.dart          # Màn hình nhắn tin
│   │
│   ├── level2/                            # Level 2 — Intermediate
│   │   ├── blocs/
│   │   │   └── chat_bloc.dart             # BLoC: Events → States → UI
│   │   ├── services/
│   │   │   ├── websocket_service.dart     # WebSocket simulation (typing indicator)
│   │   │   └── local_cache_service.dart   # Hive — offline cache
│   │   └── screens/
│   │       ├── chat_list_screen.dart      # Chat list + Search + Online indicator
│   │       └── chat_screen.dart           # Chat + BLoC + Typing indicator
│   │
│   └── level3/                            # Level 3 — Advanced
│       ├── services/
│       │   └── encryption_service.dart    # RSA E2EE simulation
│       └── screens/
│           ├── chat_list_screen.dart      # Chat list (Level 3 entry)
│           └── chat_screen.dart           # Chat + E2EE toggle + Reactions thật
│
├── android/
│   ├── app/
│   │   ├── google-services.json           # Firebase Android config
│   │   └── src/main/
│   │       ├── AndroidManifest.xml        # networkSecurityConfig cho HTTP
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

chats/{chatId}                             # chatId = "uid1_uid2" (sorted)
  ├── memberIds: [uid1, uid2]
  ├── memberNames: [name1, name2]
  ├── lastMessage: string
  ├── lastMessageTime: timestamp
  └── messages/{messageId}
        ├── senderId: string
        ├── senderName: string
        ├── content: string
        ├── type: "text"
        ├── timestamp: timestamp
        ├── status: "sent" | "delivered" | "seen"
        └── reactions: { uid: emoji }     # Level 3 — real-time reactions
```

---

## Level 1 — Simple Chat

**Công nghệ:** Firebase Auth + Cloud Firestore + StreamBuilder

**Tính năng:**
- Đăng ký / Đăng nhập bằng Email + Password
- Danh sách cuộc trò chuyện, real-time cập nhật
- Chat real-time giữa 2 thiết bị
- Online / Offline indicator (chấm xanh/xám)
- Atomic batch write khi gửi tin nhắn

**Flow:**
```
Register/Login → Chat List → New Chat (chọn user) → Chat Screen
                                                    ↓
                                          Gõ tin nhắn → Send
                                          Firestore batch.commit():
                                            1. Thêm message vào subcollection
                                            2. Cập nhật lastMessage ở chat room
                                          StreamBuilder nhận snapshot → UI tự cập nhật
```

**Code quan trọng:**
```dart
// auth_service.dart — Đăng ký
final cred = await _auth.createUserWithEmailAndPassword(email, password);
await _db.collection('users').doc(cred.user!.uid).set({
  'displayName': displayName,
  'isOnline': true,
  'lastSeen': FieldValue.serverTimestamp(),
});

// chat_service.dart — Real-time stream
Stream<List<Message>> getMessages(String chatRoomId) {
  return _db
      .collection('chats/$chatRoomId/messages')
      .orderBy('timestamp')
      .snapshots()  // Firestore tự push khi có data mới — không cần polling
      .map((snap) => snap.docs.map(_msgFromDoc).toList());
}

// chat_service.dart — Atomic batch write
final batch = _db.batch();
batch.set(messageRef, { 'content': content, ... });       // thêm message
batch.update(chatRef, { 'lastMessage': content, ... });   // update preview
await batch.commit();  // cả 2 thành công hoặc thất bại cùng nhau
```

---

## Level 2 — Intermediate

**Công nghệ:** BLoC + WebSocket + Hive offline cache + Search + Online status

**Tính năng:**
- **BLoC pattern**: UI không gọi Firestore trực tiếp, mọi thứ qua Event/State
- **Cache-first**: load từ Hive cache ngay lập tức (0ms) → fetch server background
- **Typing indicator**: WebSocket persistent connection, không dùng HTTP request
- **Online/Offline real-time**: StreamBuilder theo dõi `isOnline` từ Firestore — cả chat list lẫn trong màn hình chat
- **Search**: tìm kiếm theo tên user hoặc nội dung tin nhắn cuối

**Flow:**
```
Chat List (có search bar + chấm online/offline trên avatar)
  → Vào chat room
  → ChatBloc nhận LoadMessages event
  → Emit ChatLoading
  → Emit ChatCached (từ Hive, ngay lập tức)
  → Fetch Firestore → Emit ChatLoaded
  → WebSocket detect typing → hiện "typing..." trên AppBar
  → User đăng xuất → StreamBuilder cập nhật "offline" ngay lập tức
```

**Code quan trọng:**
```dart
// chat_bloc.dart — Cache first strategy
on<LoadMessages>((event, emit) async {
  emit(ChatLoading());

  // 1. Load cache ngay lập tức
  final cached = await LocalCacheService.getCachedMessages(event.chatRoomId);
  if (cached.isNotEmpty) emit(ChatCached(cached));

  // 2. Fetch server background, update khi có
  _messagesSub = ChatService().getMessages(event.chatRoomId).listen(
    (messages) {
      LocalCacheService.cacheMessages(event.chatRoomId, messages);
      emit(ChatLoaded(messages));
    },
  );
});

// chat_screen.dart — Online status real-time
StreamBuilder<bool>(
  stream: ChatService().watchUserOnline(otherUid),
  builder: (context, snap) {
    final online = snap.data ?? false;
    return Row(children: [
      Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: online ? Colors.greenAccent : Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
      Text(online ? 'online' : 'offline'),
    ]);
  },
)
```

---

## Level 3 — Advanced

**Công nghệ:** E2EE (RSA simulation) + Message Reactions (Firestore thật) + Security

**Tính năng:**
- **E2EE simulation**: mỗi user có RSA key pair, tin nhắn được mã hóa trước khi gửi
- **Toggle Raw/Decrypt**: bật Raw để thấy ciphertext `SGVsbG8s...`, tắt để thấy plaintext
- **Message Reactions**: long press → emoji picker → lưu lên Firestore → sync real-time giữa 2 thiết bị
- **Real-time messages**: dùng Firestore thật, không mock
- **Security badges**: E2EE, Reactions, Firestore Rules, Secure Storage

**Flow:**
```
Level Selector → Level 3 → Login (nếu chưa) → Chat List
  → Vào chat room (messages từ Firestore thật)
  → Toggle "Decrypt/Raw" → thấy nội dung encrypted/decrypted
  → Long press message → emoji picker bottom sheet
  → Chọn emoji → toggleReaction() → update Firestore
  → Thiết bị kia thấy reaction chip hiện ra real-time
  → Nhấn reaction chip để toggle off
```

**Firestore data cho reactions:**
```
chats/{chatId}/messages/{msgId}
  reactions: {
    "uid_alice": "👍",
    "uid_bob": "❤️"
  }
```

**Code quan trọng:**
```dart
// chat_service.dart — Toggle reaction (thêm hoặc bỏ)
Future<void> toggleReaction({
  required String chatRoomId,
  required String messageId,
  required String uid,
  required String emoji,
}) async {
  final ref = _db.collection('chats/$chatRoomId/messages').doc(messageId);
  final doc = await ref.get();
  final reactions = Map<String, String>.from(doc.data()?['reactions'] ?? {});

  if (reactions[uid] == emoji) {
    reactions.remove(uid);  // toggle off — nhấn cùng emoji để bỏ
  } else {
    reactions[uid] = emoji; // thêm hoặc đổi reaction
  }
  await ref.update({'reactions': reactions});
  // .snapshots() trên thiết bị kia tự nhận update → UI cập nhật ngay
}

// encryption_service.dart — E2EE simulation
String encrypt(String plaintext, String publicKey) {
  // Production: RSA encrypt với pointycastle
  // Demo: base64 encode để minh họa concept
  return base64.encode(utf8.encode('$publicKey:$plaintext'));
}
```

---

## Packages

| Package | Mục đích |
|---|---|
| `firebase_core` | Khởi tạo Firebase |
| `firebase_auth` | Authentication |
| `cloud_firestore` | Real-time database |
| `flutter_bloc` | BLoC state management (Level 2) |
| `equatable` | So sánh BLoC states |
| `hive_flutter` | Offline cache (Level 2) |
| `uuid` | Generate unique message IDs |
| `intl` | Format ngày giờ |

**Production cần thêm:**
- `web_socket_channel` — WebSocket thật thay simulation
- `encrypt` + `pointycastle` — RSA encryption thật
- `flutter_secure_storage` — Lưu private key an toàn
- `firebase_messaging` — Push notifications (FCM)

---

## Lưu ý

- **Firestore Security Rules**: đang để `allow read, write: if true` (test mode). Đổi lại rules nghiêm ngặt trước khi production.
- **Web support**: đã enable. Chrome dùng `localhost` làm Firebase host, Android emulator dùng `10.0.2.2`.
- **Reactions**: lưu trực tiếp trong document message, không phải subcollection — đơn giản hơn nhưng có giới hạn document size.
- **Online status**: cập nhật khi login/logout. Không handle trường hợp app crash (cần Firebase Realtime Database presence system cho production).

---

*Advanced Mobile Application Development Seminar — Flutter & Dart*
