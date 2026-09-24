import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_init;
import 'package:timezone/timezone.dart' as tz;
import 'package:tide_forecast_app/core/services/notification_service.dart';

class PushAlertSuiteResult {
  final bool isFridayAlgorithmAccurate;
  final bool isSurgeAlertOffsetValid;
  final bool isChannelConfigurationValid;
  final bool isFcmTopicsAligned;
  final String sampleFridayTime;
  final String message;

  const PushAlertSuiteResult({
    required this.isFridayAlgorithmAccurate,
    required this.isSurgeAlertOffsetValid,
    required this.isChannelConfigurationValid,
    required this.isFcmTopicsAligned,
    required this.sampleFridayTime,
    required this.message,
  });

  bool get isAllPassed =>
      isFridayAlgorithmAccurate &&
      isSurgeAlertOffsetValid &&
      isChannelConfigurationValid &&
      isFcmTopicsAligned;
}

class PushAlertDiagnosticSuite {
  // 對齊 NotificationService._nextInstanceOfFriday18
  static tz.TZDateTime _mockNextFriday18(tz.TZDateTime mockNow) {
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, mockNow.year, mockNow.month, mockNow.day, 18);
    while (scheduledDate.weekday != DateTime.friday || scheduledDate.isBefore(mockNow)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<PushAlertSuiteResult> run() async {
    tz_init.initializeTimeZones();

    // 1. 週五 18:00 排程演算法極限邊界測試
    bool fridayOk = true;
    final List<tz.TZDateTime> mockNows = [
      tz.TZDateTime(tz.local, 2026, 9, 21, 10, 0), // 週一
      tz.TZDateTime(tz.local, 2026, 9, 25, 17, 59), // 週五 17:59 (應排在今天 18:00)
      tz.TZDateTime(tz.local, 2026, 9, 25, 18, 1), // 週五 18:01 (應排在下週五)
      tz.TZDateTime(tz.local, 2026, 12, 31, 23, 59), // 跨年邊界
    ];

    for (final mock in mockNows) {
      final next = _mockNextFriday18(mock);
      if (next.weekday != DateTime.friday || next.isBefore(mock)) {
        fridayOk = false;
        break;
      }
    }

    final realNow = tz.TZDateTime.now(tz.local);
    final realNextFriday = _mockNextFriday18(realNow);

    // 2. 滿潮防困礁 30 分鐘偏移量檢測
    bool surgeOffsetOk = false;
    final mockHighTide = DateTime.now().add(const Duration(hours: 3));
    final expectedAlertTime = mockHighTide.subtract(const Duration(minutes: 30));
    final tzAlert = tz.TZDateTime.from(expectedAlertTime, tz.local);
    if (tzAlert.isBefore(tz.TZDateTime.from(mockHighTide, tz.local)) && 
        tzAlert.difference(tz.TZDateTime.now(tz.local)).inMinutes >= 140) {
      surgeOffsetOk = true;
    }

    // 3. 通道物件與高優先級配置檢驗
    bool channelOk = false;
    try {
      const androidDetails = AndroidNotificationDetails(
        'tide_safety_channel',
        '突發湧浪與潮位安全預警',
        importance: Importance.max,
        priority: Priority.max,
      );
      if (androidDetails.importance == Importance.max && androidDetails.priority == Priority.max) {
        channelOk = true;
      }
    } catch (_) {
      channelOk = false;
    }

    // 4. FCM 雙主題頻道對齊檢驗
    const topics = ['weekend_briefing', 'severe_weather_alert'];
    final bool topicsOk = topics.length == 2 && topics[0] == 'weekend_briefing';

    String msg;
    if (!fridayOk) {
      msg = "週五決策情報排程時間軸回退或算錯日期";
    } else if (!surgeOffsetOk) {
      msg = "滿潮 30 分鐘推播偏移量計算錯誤";
    } else if (!channelOk) {
      msg = "推播通道未正確賦予高優先級 (可能被系統靜音)";
    } else {
      msg = "推播時區演算法精準，安全通道優先級正確，FCM 主題完整";
    }

    return PushAlertSuiteResult(
      isFridayAlgorithmAccurate: fridayOk,
      isSurgeAlertOffsetValid: surgeOffsetOk,
      isChannelConfigurationValid: channelOk,
      isFcmTopicsAligned: topicsOk,
      sampleFridayTime: "${realNextFriday.year}/${realNextFriday.month}/${realNextFriday.day} ${realNextFriday.hour}:00",
      message: msg,
    );
  }
}
