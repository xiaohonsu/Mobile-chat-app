import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/models/message.dart';

/// Level 2 — Local Cache Service (Hive)
///
/// Implements "Cache-First" strategy:
/// 1. Return cached data immediately → smooth UX, no loading spinner
/// 2. Fetch from server in background
/// 3. Update cache + UI with fresh data
/// 4. If offline: keep showing cached data

class LocalCacheService {
  static const String _boxPrefix = 'messages_';
  static bool _initialized = false;

  /// Must call once at app start.
  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _initialized = true;
  }

  static Future<Box> _getBox(String chatRoomId) async {
    final boxName = '$_boxPrefix$chatRoomId';
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return await Hive.openBox(boxName);
  }

  /// Cache a list of messages for a chat room.
  static Future<void> cacheMessages(
      String chatRoomId, List<Message> messages) async {
    final box = await _getBox(chatRoomId);
    await box.clear();
    for (final msg in messages) {
      await box.put(msg.id, jsonEncode(msg.toMap()));
    }
  }

  /// Append a single message to cache.
  static Future<void> appendMessage(
      String chatRoomId, Message message) async {
    final box = await _getBox(chatRoomId);
    await box.put(message.id, jsonEncode(message.toMap()));
  }

  /// Get all cached messages, sorted by timestamp.
  static Future<List<Message>> getCachedMessages(String chatRoomId) async {
    try {
      final box = await _getBox(chatRoomId);
      return box.values
          .map((v) => Message.fromMap(
              jsonDecode(v as String) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (_) {
      return [];
    }
  }

  /// Check if there are any cached messages.
  static Future<bool> hasCachedMessages(String chatRoomId) async {
    final box = await _getBox(chatRoomId);
    return box.isNotEmpty;
  }

  /// Clear cache for a room.
  static Future<void> clearRoom(String chatRoomId) async {
    final box = await _getBox(chatRoomId);
    await box.clear();
  }
}
