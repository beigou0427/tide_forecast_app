import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint("🔔 [FCM] 推播授權狀態: ${settings.authorizationStatus}");
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 🌟 iOS 守衛：非實機或 APNS 尚未配發時安全處理，防止直接拋出未捕捉例外
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _fcm.getAPNSToken();
        if (apnsToken != null) {
          final String? token = await _fcm.getToken();
          debugPrint("📱 [FCM Device Token]: $token");
          await _fcm.subscribeToTopic('weekend_briefing');
          await _fcm.subscribeToTopic('severe_weather_alert');
        } else {
          debugPrint("ℹ️ [FCM] iOS 模擬器或 APNS 尚未就緒，主題訂閱將於實機啟動時自動掛載");
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

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("🚀 [FCM 點擊開啟] 用戶透過點擊推播進入 App: ${message.data}");
      });

    } catch (e) {
      debugPrint("⚠️ [FCM] 守衛捕獲例外: $e");
    }
  }
}
