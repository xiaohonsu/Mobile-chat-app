import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Tracks which chat room is currently open so we skip showing
/// notifications for messages in the active chat.
class ActiveChatTracker {
  static String? activeChatRoomId;
}

/// Level 2 — Notification Service
///
/// DEMO: Uses flutter_local_notifications to show system notifications
/// when a new message arrives in a chat room that is NOT currently open.
///
/// PRODUCTION: Replace with Firebase Cloud Messaging (FCM):
/// ```dart
/// import 'package:firebase_messaging/firebase_messaging.dart';
///
/// FirebaseMessaging.onMessage.listen((RemoteMessage message) {
///   // Foreground notification
///   showLocalNotification(message.notification);
/// });
///
/// // Background/terminated: handled by FCM automatically
/// FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
/// ```
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb) return; // Web uses browser notifications (not supported here)

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Request permission on Android 13+ (API 33+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String chatRoomId,
  }) async {
    if (!_initialized || kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    final shortMsg = message.length > 60
        ? '${message.substring(0, 60)}...'
        : message;

    await _plugin.show(
      chatRoomId.hashCode.abs(),
      senderName,
      shortMsg,
      const NotificationDetails(android: androidDetails),
    );
  }
}
