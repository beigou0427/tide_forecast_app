import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'global_error_trap.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;
  
  static GlobalKey<NavigatorState>? _navKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) => _navKey = key;

  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Taipei'));

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true,
      );
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload != null && _navKey?.currentState != null) {
            _navKey!.currentState!.pushNamed(details.payload!);
          }
        },
      );

      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();

      // 🌟 修復三：Terminated (冷啟動) 狀態本地推播接管
      final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _navKey?.currentState?.pushNamed(payload);
          });
        }
      }

      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e, stack) {
      _initCompleter!.complete();
      _initCompleter = null;
      GlobalErrorTrap.recordException(e, stackTrace: stack, contextTag: "NotificationInit", severity: ErrorSeverity.warning);
    }
  }

  static Future<void> init() async {
    await ensureInitialized();
    await scheduleWeekendBriefing();
  }

  static Future<void> scheduleWeekendBriefing() async {
    await ensureInitialized();
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'weekend_briefing_channel', '週末海象決策快報',
        importance: Importance.high, priority: Priority.high,
      );
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      final tz.TZDateTime scheduledDate = _nextInstanceOfFriday18();

      await _notificationsPlugin.zonedSchedule(
        1001, '🚢 老船長週末海象情報已出爐！', '全台測站最新風浪、水溫與咬度模型已更新，立即規劃週末出海窗口。',
        scheduledDate, platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'tidepro://events/spring_tide_window', 
      );
    } catch (_) {}
  }

  static Future<void> scheduleTideSurgeAlert({required DateTime highTideTime, required String stationName}) async {
    await ensureInitialized();
    try {
      final alertTime = highTideTime.subtract(const Duration(minutes: 30));
      if (alertTime.isBefore(DateTime.now())) return;
      final tzAlertTime = tz.TZDateTime.from(alertTime, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'tide_safety_channel', '突發湧浪與潮位安全預警',
        importance: Importance.max, priority: Priority.max,
      );
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true, interruptionLevel: InterruptionLevel.timeSensitive),
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          2001, '⚠️ 潮位安全預警：滿潮水位即將逼近！', '[$stationName] 將於 30 分鐘後達到今日滿潮水位，請密切注意身後退路並提早撤離外礁！',
          tzAlertTime, platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'tidepro://alerts/surge',
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          2001, '⚠️ 潮位安全預警：滿潮水位即將逼近！', '[$stationName] 將於 30 分鐘後達到今日滿潮水位，請密切注意身後退路並提早撤離外礁！',
          tzAlertTime, platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'tidepro://alerts/surge',
        );
      }
    } catch (_) {}
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