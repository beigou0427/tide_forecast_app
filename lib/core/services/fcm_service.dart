import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🌟 Top-Level 原生入口點：確保 App 被滑掉關閉時，仍可在後台接收雲端推播
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🚨 [FCM 後台靜默喚醒] 接收到推播: ${message.notification?.title ?? message.data['title']}");
}

class FcmService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      // 1. 請求 iOS 與 Android 13+ 推播授權
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint("🔔 [FCM] 推播授權狀態: ${settings.authorizationStatus}");

      // 2. 註冊後台訊息入口點
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. 自動訂閱核心推播主題頻道 (出海週報 & 突發惡劣海象)
      await _fcm.subscribeToTopic('weekend_briefing');
      await _fcm.subscribeToTopic('severe_weather_alert');
      debugPrint("✅ [FCM] 已自動訂閱 weekend_briefing 與 severe_weather_alert 主題頻道！");

      // 4. 印出設備專屬 Token (供測試手動推播使用)
      final String? token = await _fcm.getToken();
      debugPrint("📱 [FCM Device Token]: $token");

      // 5. 前景監聽：當 App 正在使用中收到推播時，透過本地通道彈出橫幅
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("📩 [FCM 前景訊息] ${message.notification?.title}: ${message.notification?.body}");
        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            message.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'fcm_urgent_channel',
                '老船長雲端緊急快訊',
                channelDescription: '由雲端推播之緊急海象與週末出海決策情報',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
            ),
          );
        }
      });

      // 6. 點擊推播進入 App 路由處理
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("🚀 [FCM 點擊開啟] 用戶透過點擊推播進入 App: ${message.data}");
      });

    } catch (e) {
      debugPrint("⚠️ [FCM] 初始化失敗: $e");
    }
  }
}
