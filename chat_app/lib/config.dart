/// Cấu hình kết nối Firebase Emulator
///
/// ⚠️  THAY ĐỔI emulatorHost THÀNH IP WIFI CỦA LAPTOP TRƯỚC KHI DEMO
///
/// Cách tìm IP:
///   Windows: ipconfig  →  IPv4 Address (ví dụ: 192.168.1.5)
///   macOS:   ifconfig  →  inet (ví dụ: 192.168.1.5)
///
/// Cả laptop và điện thoại phải kết nối cùng một mạng WiFi.

const String emulatorHost = '10.0.2.2'; // Android emulator default
// const String emulatorHost = 'localhost'; // iOS simulator
// const String emulatorHost = '192.168.1.5'; // WiFi LAN — thay bằng IP thật

const int firestorePort = 8080;
const int authPort = 9099;
const int emulatorUiPort = 4000;
