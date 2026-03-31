# Demo Script — Chat App (3 Levels)

> Tổng thời gian demo: ~10 phút | Mỗi level: ~3 phút

---

## Lệnh khởi động (chạy trong terminal tại thư mục `source_code/chat_app`)

### Bước 1 — Mở Android Emulator
```bash
flutter emulators --launch Pixel_7_API35
```
> Chờ emulator boot xong (~30 giây) rồi mới chạy bước 2

### Bước 2 — Chạy app trên Emulator (thiết bị 1)
> Mở terminal mới, cd vào `source_code/chat_app` rồi chạy:
```bash
flutter run -d emulator-5554
```

### Bước 3 — Chạy app trên Chrome (thiết bị 2)
> Mở terminal mới, cd vào `source_code/chat_app` rồi chạy:
```bash
flutter run -d chrome --web-port 9191
```
> Nếu báo port bị chiếm, đổi thành `--web-port 9292` hoặc bất kỳ số nào khác

---

## Chuẩn bị trước khi demo

1. Đảm bảo có internet (dùng Firebase Cloud thật)
2. Chạy đủ cả 2 thiết bị theo lệnh ở trên
3. **Đăng ký 2 tài khoản** trên 2 thiết bị trước khi demo (chỉ cần làm 1 lần)

---

## Level 1 — Simple Chat
### Firebase Auth + Firestore + StreamBuilder

**Tính năng:**
- Đăng ký / Đăng nhập bằng Email + Password
- Chat real-time giữa 2 thiết bị
- Online/Offline indicator (chấm xanh/xám)
- Atomic batch write khi gửi tin nhắn

**Flow demo:**
1. Level Selector → **Level 1**
2. Đăng nhập tài khoản
3. Nhấn **+** (FAB) → chọn user → vào chat room
4. Gõ tin nhắn → gửi → **thiết bị 2 thấy ngay, không cần refresh**
5. Đăng xuất → chấm xanh biến mất → đăng nhập lại → chấm xanh trở lại

**Điểm nhấn:**
- Mở Firebase Console → Firestore → thấy data ghi vào real-time
- Chỉ vào `.snapshots()` trong code — đây là "magic" của real-time

**Code show:**
```dart
// Real-time stream — không cần polling
Stream<List<Message>> getMessages(String chatRoomId) {
  return _db
      .collection('chats/$chatRoomId/messages')
      .orderBy('timestamp')
      .snapshots()  // ← Firestore tự push khi có data mới
      .map((snap) => snap.docs.map(_msgFromDoc).toList());
}

// StreamBuilder tự rebuild UI
StreamBuilder<List<Message>>(
  stream: ChatService().getMessages(chatRoom.id),
  builder: (context, snapshot) { ... },
)
```

---

## Level 2 — Intermediate
### BLoC + Typing Indicator (Firestore-synced) + Online Status + Search + Push Notifications

**Tính năng:**
- **BLoC pattern**: tách UI ↔ Business Logic hoàn toàn
- **Cache-first**: load từ Hive cache ngay lập tức → sau đó mới fetch server
- **Typing indicator (Firestore-synced)**: cross-device real-time, không phải local simulation
- **Search conversations**: tìm kiếm theo tên user
- **Push Notifications** (`flutter_local_notifications`): banner hệ thống khi nhận tin nhắn mới

**Flow demo — Typing Indicator:**
1. Level Selector → **Level 2** → đăng nhập
2. Thiết bị 1 và thiết bị 2 cùng mở Level 2
3. Vào một chat room (thiết bị 1)
4. **Thiết bị 2 bắt đầu gõ tin nhắn** → thiết bị 1 thấy **"[Tên] is typing..."** ngay lập tức
5. Thiết bị 2 dừng gõ / gửi tin → indicator biến mất

> **Giải thích cơ chế:** Không dùng WebSocket thật — dùng Firestore `typing: {uid: true}` field. Khi gõ phím, ghi lên Firestore; thiết bị kia lắng nghe `.snapshots()` và hiện indicator. Concept giống WebSocket nhưng sync qua cloud.

**Flow demo — Push Notifications:**
1. Thiết bị 1 (Android Emulator): đang ở **màn hình chat list** (không trong chat room)
2. Thiết bị 2 (Chrome/Web): vào chat → gõ và gửi tin nhắn
3. **Thiết bị 1 nhận notification banner hệ thống** với tên người gửi + nội dung tin nhắn
4. Nhấn vào notification → (hoặc nhấn vào chat trong list) → vào chat room
5. **Demo không notification khi đang trong chat:** thiết bị 1 mở đúng chat room đó → thiết bị 2 gửi tin → **không có banner** (đã đọc rồi)

> **Công nghệ:** `flutter_local_notifications` v17.2.4 — hiện system notification banner trực tiếp từ app, không cần server push. Notification được kích hoạt khi Firestore stream nhận `lastMessage` mới từ người khác. `ActiveChatTracker` theo dõi chat room đang mở để tránh hiện notification thừa.
>
> **Production thay bằng:** Firebase Cloud Messaging (FCM) — nhận notification kể cả khi app bị tắt hoàn toàn.

**Flow demo — Search & Online Status:**
1. Quay ra chat list → thấy **chấm xanh** (online) / **chấm xám** (offline)
2. Nhấn vào search bar → gõ tên user → danh sách tự filter theo tên
3. Xóa search → list trở về đầy đủ

**Code show:**
```dart
// Typing indicator — ghi lên Firestore, thiết bị kia đọc qua .snapshots()
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

// Push Notification — flutter_local_notifications
Future<void> showMessageNotification({
  required String senderName,
  required String message,
  required String chatRoomId,
}) async {
  if (!_initialized || kIsWeb) return;  // không hỗ trợ web
  const androidDetails = AndroidNotificationDetails(
    'chat_messages', 'Chat Messages',
    importance: Importance.high, priority: Priority.high,
  );
  await _plugin.show(chatRoomId.hashCode.abs(), senderName, message,
      const NotificationDetails(android: androidDetails));
}

// BLoC — Cache First
on<LoadMessages>((event, emit) async {
  emit(ChatLoading());
  // 1. Emit cached data NGAY LẬP TỨC (0ms loading)
  final cached = await LocalCacheService.getCachedMessages(event.chatRoomId);
  if (cached.isNotEmpty) emit(ChatCached(cached));
  // 2. Fetch từ server trong background
  _messagesSub = ChatService().getMessages(event.chatRoomId).listen(
    (messages) {
      LocalCacheService.cacheMessages(event.chatRoomId, messages);
      emit(ChatLoaded(messages));
    },
  );
});
```

---

## Level 3 — Advanced
### E2EE + Message Reactions + Group Chat

**Tính năng:**
- **End-to-End Encryption (RSA simulation)**: server chỉ thấy ciphertext `🔒base64.sig`
- **Separate `encrypted_chats/` collection**: hoàn toàn tách biệt với `chats/` của Level 1&2
- **Toggle "Raw (DB)" / "Decrypted"**: xem đúng nội dung lưu trong database vs sau giải mã
- **Message Reactions**: long press → emoji picker → sync real-time
- **Group Chat**: tạo group nhiều thành viên, toàn bộ tin nhắn được mã hóa

**Flow demo — E2EE (1-on-1):**
1. Level Selector → **Level 3** → đăng nhập
2. Nhấn **+** → **New Encrypted Chat** → chọn user → vào chat room
3. Gõ tin nhắn → gửi
4. Nhấn **"Decrypted"** để toggle → đổi thành **"Raw (DB)"**
5. Thấy tin nhắn đổi thành `🔒SGVsbG8s...abc123` — đây là bản lưu trong Firestore
6. Toggle lại → thấy nội dung bình thường
7. Mở **Firebase Console → encrypted_chats → messages** → xác nhận content là ciphertext

> **Điểm nhấn:** Chỉ vào Firebase Console — admin cũng chỉ thấy `🔒SGVsbG8s...`, không đọc được nội dung.

**Flow demo — Group Chat:**
1. Nhấn **+** → **New Group Chat**
2. Nhập tên group (ví dụ: "Demo Team")
3. Tick chọn 1-2 thành viên → nút **"Create Encrypted Group (N members)"** bật sáng
4. Nhấn Create → vào group chat room
5. AppBar hiện tên group + số thành viên
6. Gõ tin nhắn → gửi → tất cả thành viên nhận được (mã hóa)

**Flow demo — Message Reactions:**
1. Trong bất kỳ chat room Level 3 nào
2. **Long press** vào một tin nhắn → emoji picker hiện ra
3. Chọn emoji → reaction hiện ngay dưới bubble
4. Thiết bị kia thấy reaction real-time (qua Firestore `.snapshots()`)
5. Nhấn lại reaction → bỏ reaction (toggle)

**Firebase Console demo:**
```
Firestore → chats/          → content: "Hello"           ← Level 1 & 2 (plaintext)
Firestore → encrypted_chats/ → content: "🔒SGVsbG8s..."  ← Level 3 (encrypted)
```

**Code show:**
```dart
// Encrypt TRƯỚC KHI lưu lên Firestore
Future<void> _sendMessage(String text) async {
  final pubKey = _encryption.getPublicKey(widget.currentUser.uid);
  final encrypted = _encryption.encrypt(text, pubKey); // → "🔒base64.sig"
  await ChatService().sendEncryptedMessage(
    chatRoomId: widget.chatRoom.id,
    encryptedContent: encrypted,  // ← ciphertext lên server
    ...
  );
}

// Toggle Raw / Decrypted khi hiển thị
String displayContent = _showEncryptedView
    ? msg.content  // raw ciphertext từ Firestore — "🔒SGVsbG8s..."
    : _encryption.decrypt(msg.content, privateKey);  // plaintext cho user

// encryption_service.dart — RSA simulation (demo concept)
String encrypt(String plaintext, String publicKey) {
  final encoded = base64.encode(utf8.encode(plaintext));
  return '🔒$encoded.${_generateSig(publicKey)}';
}

String decrypt(String ciphertext, String privateKey) {
  final parts = ciphertext.substring(2).split('.');
  return utf8.decode(base64.decode(parts[0]));
}
```

---

## Thứ tự demo lý tưởng

```
[Slide: Tại sao real-time?]
  → Level 1 demo (3 phút) — 2 thiết bị chat nhau

[Slide: State management & UX nâng cao]
  → Level 2 demo (4 phút) — typing (cross-device), push notification, online, search, cache

[Slide: Security là gì trong chat?]
  → Level 3 demo (3 phút) — E2EE toggle (Firebase Console), group chat, reactions

→ Q&A
```

---

## Xử lý sự cố khi demo

| Tình huống | Xử lý |
|---|---|
| Chrome port bị chiếm | Đổi sang `--web-port 9292` hoặc số bất kỳ |
| App crash khi khởi động | Kiểm tra internet, Firebase Console còn hoạt động |
| Đăng nhập bị lỗi | Kiểm tra Email/Password đúng, tài khoản đã tạo chưa |
| Chat list trống | Nhấn **+** để tạo chat room mới với user kia |
| Online indicator không cập nhật | Đăng xuất/đăng nhập lại để trigger update |
| Notification không hiện | Chỉ hoạt động trên Android (Emulator), không hỗ trợ web |
| Notification hiện cả khi đang trong chat | Không xảy ra — `ActiveChatTracker` chặn notification khi đang mở đúng room đó |
| Group chat nút Create bị mờ | Cần nhập tên group VÀ chọn ít nhất 1 thành viên |
