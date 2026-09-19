import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint("點擊推播進入 App: ${details.payload}");
        },
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();

      debugPrint("✅ [Notification] 推播引擎初始化成功！");

      await scheduleWeekendBriefing();
    } catch (e) {
      debugPrint("⚠️ [Notification] 推播初始化失敗: $e");
    }
  }

  /// 1. 每週五 18:00 週末出海決策情報定時通知
  static Future<void> scheduleWeekendBriefing() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'weekend_briefing_channel',
        '週末海象決策快報',
        channelDescription: '每週五傍晚發布週末出海與作釣黃金窗口預測',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      tz.TZDateTime scheduledDate = _nextInstanceOfFriday18();

      await _notificationsPlugin.zonedSchedule(
        id: 1001,
        title: '🚢 老船長週末海象情報已出爐！',
        body: '全台測站最新風浪、水溫與咬度模型已更新，立即規劃週末出海窗口。',
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint("⏰ [Notification] 週末決策推播已排程至: $scheduledDate");
    } catch (e) {
      debugPrint("⚠️ [Notification] 決策推播排程失敗: $e");
    }
  }

  /// 2. 滿潮前 30 分鐘主動湧浪與防困礁警報
  static Future<void> scheduleTideSurgeAlert({
    required DateTime highTideTime,
    required String stationName,
  }) async {
    try {
      final alertTime = highTideTime.subtract(const Duration(minutes: 30));
      if (alertTime.isBefore(DateTime.now())) return;

      final tzAlertTime = tz.TZDateTime.from(alertTime, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'tide_safety_channel',
        '突發湧浪與潮位安全預警',
        channelDescription: '滿潮前 30 分鐘提示撤離礁石與注意海浪',
        importance: Importance.max,
        priority: Priority.max,
      );

      await _notificationsPlugin.zonedSchedule(
        id: 2001,
        title: '⚠️ 潮位安全預警：滿潮水位即將逼近！',
        body: '[$stationName] 將於 30 分鐘後達到今日滿潮水位，請密切注意身後退路並提早撤離外礁！',
        scheduledDate: tzAlertTime,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint("🚨 [Notification] 滿潮預警推播已設定: $tzAlertTime");
    } catch (e) {
      debugPrint("⚠️ [Notification] 滿潮預警設定失敗: $e");
    }
  }

  static tz.TZDateTime _nextInstanceOfFriday18() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18);
    while (scheduledDate.weekday != DateTime.friday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
