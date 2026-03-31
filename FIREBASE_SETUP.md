# Firebase Setup Guide
## Hướng dẫn kết nối Firebase để demo 2 thiết bị real-time

---

## Bước 1 — Tạo Firebase Project

1. Vào [console.firebase.google.com](https://console.firebase.google.com)
2. Nhấn **Add project** → đặt tên (ví dụ: `flutter-chat-seminar`)
3. Tắt Google Analytics (không cần cho demo) → **Create project**

---

## Bước 2 — Bật Authentication

1. Sidebar → **Build → Authentication** → **Get started**
2. Tab **Sign-in method** → chọn **Email/Password** → Enable → **Save**

---

## Bước 3 — Tạo Firestore Database

1. Sidebar → **Build → Firestore Database** → **Create database**
2. Chọn **Start in test mode** (cho phép đọc ghi thoải mái, đủ cho demo)
3. Chọn region gần nhất: `asia-southeast1` (Singapore) → **Enable**

> Sau khi demo xong, vào **Rules** và paste nội dung từ `firestore.rules`
> để bảo vệ database.

---

## Bước 4 — Kết nối Flutter app

```bash
# Cài FlutterFire CLI (chạy 1 lần duy nhất)
dart pub global activate flutterfire_cli

# Vào thư mục project
cd source_code/chat_app

# Kết nối với Firebase project
flutterfire configure
```

Khi chạy lệnh này:
- Chọn Firebase project vừa tạo
- Chọn platform: `android` và `ios`
- FlutterFire sẽ tự động:
  - Tạo file `lib/firebase_options.dart` với API keys thật
  - Tạo `google-services.json` cho Android
  - Cập nhật `GoogleService-Info.plist` cho iOS

---

## Bước 5 — Chạy app

```bash
flutter run
```

---

## Demo 2 thiết bị real-time

### Cách 1: 2 máy tính
```bash
# Máy 1
flutter run -d <device_id_1>

# Máy 2 (cùng project, cùng Firebase)
flutter run -d <device_id_2>
```

### Cách 2: 1 máy + 1 điện thoại thật
```bash
# Kết nối điện thoại qua USB, bật Developer Mode
flutter devices          # xem danh sách thiết bị
flutter run -d <phone_id>
```

### Cách 3: 2 simulator/emulator trên cùng máy
```bash
# Terminal 1
flutter run -d emulator-5554

# Terminal 2
flutter run -d emulator-5556
```

---

## Luồng demo (30 giây)

```
Thiết bị A: Đăng ký tài khoản "Alice"
Thiết bị B: Đăng ký tài khoản "Bob"
Thiết bị A: Nhấn (+) → chọn Bob → gửi "Xin chào!"
            ↓  Firestore push ngay lập tức
Thiết bị B: Tin nhắn hiện lên NGAY — không cần refresh
```

---

## Cấu trúc Firestore sau khi demo

```
users/
  uid_alice → { displayName: "Alice", isOnline: true, ... }
  uid_bob   → { displayName: "Bob",   isOnline: true, ... }

chats/
  uid_alice_uid_bob/
    memberIds: ["uid_alice", "uid_bob"]
    lastMessage: "Xin chào!"
    messages/
      msg_001 → { senderId: "uid_alice", content: "Xin chào!", ... }
      msg_002 → { senderId: "uid_bob",   content: "Hello!", ... }
```

---

## Troubleshooting

| Lỗi | Giải pháp |
|-----|-----------|
| `firebase_options.dart` không có keys thật | Chạy `flutterfire configure` |
| `PERMISSION_DENIED` | Kiểm tra Firestore Rules đang ở test mode |
| App crash khi khởi động | Kiểm tra `google-services.json` đã được đặt đúng chỗ |
| Không thấy thiết bị khác | Cả 2 phải dùng cùng Firebase project |

---

## File cần giữ bí mật (không commit lên GitHub public)

```
lib/firebase_options.dart   ← chứa API keys thật
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

Thêm vào `.gitignore` nếu repo public:
```
# Firebase
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

> Repo này là private nên có thể commit bình thường.
