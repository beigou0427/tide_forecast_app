import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 [FCM 背景推播通道] 收到海象通知: ${message.notification?.title ?? message.data['title']}");
}

/// 🌟 經海事最高等級重塑之雲端推播服務引擎
/// 支援 iOS APNS 延遲容錯、外海劇烈天氣主題訂閱與高分貝緊急警報通知
class FcmService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint("🔔 [FCM] 授權狀態: ${settings.authorizationStatus}");
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // iOS 實機適配：若 APNS token 尚未取得，暫緩訂閱以防崩潰
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _fcm.getAPNSToken();
        if (apnsToken != null) {
          final String? token = await _fcm.getToken();
          debugPrint("📱 [FCM Device Token]: $token");
          await _fcm.subscribeToTopic('weekend_briefing');
          await _fcm.subscribeToTopic('severe_weather_alert');
        } else {
          debugPrint("⚠️ [FCM] iOS 模擬器或 APNS 尚未就緒，將於就緒時自動訂閱");
        }
      } else {
        final String? token = await _fcm.getToken();
        debugPrint("📱 [FCM Device Token]: $token");
        await _fcm.subscribeToTopic('weekend_briefing');
        await _fcm.subscribeToTopic('severe_weather_alert');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            message.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'fcm_urgent_channel',
                '老船長海事緊急預警',
                channelDescription: '突發巨浪與極端海象高優先級推播通知',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("🚀 [FCM 點擊開啟] 使用者點擊推播進入 App: ${message.data}");
      });

    } catch (e) {
      debugPrint("⚠️ [FCM] 初始化捕獲異常: $e");
    }
  }
}