# Demo Script — Chat App (3 Levels)

> Tổng thời gian demo: ~10 phút | Mỗi level: ~3 phút

---

## Chuẩn bị trước khi demo

1. Đảm bảo có internet (dùng Firebase Cloud thật)
2. Chạy app trên Android Emulator (thiết bị 1):
   ```
   flutter run -d emulator-5554
   ```
3. Chạy app trên Chrome (thiết bị 2):
   ```
   flutter run -d chrome --web-port 8082
   ```
4. **Đăng ký 2 tài khoản** trên 2 thiết bị trước khi demo

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
### BLoC + WebSocket Typing + Online Status + Search

**Tính năng:**
- **BLoC pattern**: tách UI ↔ Business Logic hoàn toàn
- **Cache-first**: load từ Hive cache ngay lập tức → sau đó mới fetch server
- **Typing indicator**: WebSocket persistent connection
- **Search conversations**: tìm kiếm theo tên hoặc nội dung tin nhắn

**Flow demo:**
1. Level Selector → **Level 2** (cần đăng nhập qua Level 1 trước)
2. Thấy chat list với **chấm xanh** (online) / **chấm xám** (offline) bên cạnh avatar
3. Nhấn vào search bar → gõ tên user → danh sách tự filter
4. Xóa search → vào một chat room
5. Sau 2 giây thấy **"Bob Tran is typing..."** hiện ra
6. Gõ tin nhắn → gửi → tin nhắn hiện ngay (cache-first)

**Điểm nhấn:**
- Chỉ ra chấm xanh/xám thay đổi khi user kia đăng xuất
- Search bar lọc ngay khi gõ — không cần nhấn Search
- Typing indicator: WebSocket không phải HTTP request → không tốn bandwidth

**Code show:**
```dart
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
      emit(ChatLoaded(messages));  // update UI với data mới nhất
    },
  );
});

// Online indicator
StreamBuilder<bool>(
  stream: ChatService().watchUserOnline(otherUid),
  builder: (context, snap) {
    final online = snap.data ?? false;
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: online ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  },
)
```

---

## Level 3 — Advanced
### E2EE + Message Reactions + Security

**Tính năng:**
- **End-to-End Encryption (RSA)**: server chỉ thấy ciphertext
- **Message Reactions**: long press → chọn emoji → hiện dưới tin nhắn
- **Toggle Raw/Decrypt**: xem bản mã hóa và bản giải mã
- **Firestore Security Rules**: kiểm soát quyền truy cập server-side
- **Secure Storage**: private key lưu trên thiết bị, không lên server

**Flow demo:**
1. Level Selector → **Level 3**
2. Thấy chat với Bob Tran — có badge **E2EE enabled** trên AppBar
3. Thấy Public Key hiển thị (lưu trên Firestore), Private Key chỉ trên thiết bị
4. **Toggle "Decrypt" → "Raw"**: tin nhắn đổi thành chuỗi `SGVsbG8s...` (base64 encrypted)
5. Toggle lại **"Raw" → "Decrypt"**: thấy nội dung bình thường
6. Gõ tin nhắn → gửi → sau 2s Bob reply + **react 👍 vào tin nhắn vừa gửi**
7. **Long press** bất kỳ tin nhắn → bottom sheet emoji picker → chọn reaction
8. Reaction hiện dưới bubble, nhấn lại để bỏ
9. Nhấn **ℹ️** → đọc giải thích E2EE + Reactions + Security

**Điểm nhấn:**
- Toggle Raw/Decrypt: trực quan nhất để giải thích E2EE
- Reactions: tính năng thực tế, real-time sync qua Firestore `.snapshots()`
- Nhấn mạnh: **server chỉ lưu bản encrypted** — admin cũng không đọc được

**Code show:**
```dart
// Encrypt trước khi gửi
void sendMessage(String text) {
  final peerPublicKey = encryption.getPublicKey(peerId);
  final encrypted = encryption.encrypt(text, peerPublicKey); // RSA

  // Server chỉ nhận bản encrypted
  Firestore.save(encrypted);
}

// Reactions lưu trong Firestore
// chats/{chatId}/messages/{msgId}
// reactions: { "uid_alice": "👍", "uid_bob": "❤️" }

// Real-time sync reactions
.collection('chats/$chatId/messages')
.snapshots()
.map((snap) => snap.docs.map((d) {
  final reactions = d.data()['reactions'] as Map? ?? {};
  ...
}).toList())
```

---

## Thứ tự demo lý tưởng

```
[Slide: Tại sao real-time?]
  → Level 1 demo (4 phút) — 2 thiết bị chat nhau

[Slide: Vấn đề với direct stream — scalability]
  → Level 2 demo (3 phút) — typing, online, search, cache

[Slide: Security là gì trong chat?]
  → Level 3 demo (3 phút) — E2EE toggle, reactions

→ Q&A
```

---

## Xử lý sự cố khi demo

| Tình huống | Xử lý |
|---|---|
| Chrome port bị chiếm | Đổi sang `--web-port 8083` |
| App crash khi khởi động | Kiểm tra internet, Firebase Console còn hoạt động |
| Đăng nhập bị lỗi | Kiểm tra Email/Password đúng, tài khoản đã tạo chưa |
| Chat list trống | Nhấn **+** để tạo chat room mới với user kia |
| Online indicator không cập nhật | Đăng xuất/đăng nhập lại để trigger update |
