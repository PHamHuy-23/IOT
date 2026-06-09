import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // ĐÃ SỬA: Xóa bỏ chữ 'settings:' -> truyền thẳng InitializationSettings làm tham số đầu tiên
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  
  Future<void> showHealthAlert({
    required int id,
    required String title,
    required String body,
    bool critical = false,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'health_alerts',
      'Cảnh báo sức khỏe',
      channelDescription: 'Nhịp tim, SpO2 và té ngã',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    try {
      // ĐÃ SỬA: Truyền trực tiếp id, title, body làm tham số vị trí
      await _plugin.show(
        id,                                    // Tham số số 1: id (không có id:)
        title,                                 // Tham số số 2: title (không có title:)
        body,                                  // Tham số số 3: body (không có body:)
        const NotificationDetails(             // Tham số số 4: cấu hình chi tiết
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
    } catch (e) {
      debugPrint('[LocalNotificationService] $e');
    }
  }
}