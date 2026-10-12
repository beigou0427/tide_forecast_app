import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import 'global_error_trap.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
}

class FcmService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _isLocalNotificationsInitialized = false;

  static GlobalKey<NavigatorState>? _navKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) => _navKey = key;

  static Future<void> init() async {
    try {
      await _initLocalNotifications();
      final NotificationSettings settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (!kIsWeb && Platform.isIOS) {
          _secureIosSubscription();
        } else {
          _subscribeToTopics();
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null && _isLocalNotificationsInitialized) {
            _localNotifications.show(
              message.hashCode, notification.title, notification.body,
              const NotificationDetails(
                android: AndroidNotificationDetails('fcm_urgent_channel', '老船長海事緊急預警', importance: Importance.max, priority: Priority.high, icon: '@mipmap/ic_launcher'),
                iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true, interruptionLevel: InterruptionLevel.timeSensitive),
              ),
              payload: message.data['deep_link'] ?? message.data['route'],
            );
          }
        });

        // 🌟 修復三：背景喚醒監聽
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleMessagePayload(message);
        });

        // 🌟 修復三：被徹底滑掉關閉的冷啟動 (Terminated) 狀態攔截黑洞！
        final initialMsg = await _fcm.getInitialMessage();
        if (initialMsg != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleMessagePayload(initialMsg);
          });
        }
      }
    } catch (e, stack) {
      GlobalErrorTrap.recordException(e, stackTrace: stack, contextTag: "FCM_Init", severity: ErrorSeverity.warning);
    }
  }

  static void _handleMessagePayload(RemoteMessage message) {
    final payload = message.data['deep_link'] ?? message.data['route'];
    debugPrint("🚀 [FCM 點擊] 觸發路由: $payload");
    if (payload != null && _navKey?.currentState != null) {
      _navKey!.currentState!.pushNamed(payload);
    }
  }

  static Future<void> _initLocalNotifications() async {
    if (_isLocalNotificationsInitialized) return;
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload != null && _navKey?.currentState != null) {
            _navKey!.currentState!.pushNamed(details.payload!);
          }
        },
      );
      _isLocalNotificationsInitialized = true;
    } catch (_) {}
  }

  static Future<void> _secureIosSubscription() async {
    int retryCount = 0;
    while (retryCount < 8) {
      final apnsToken = await _fcm.getAPNSToken();
      if (apnsToken != null) {
        await _subscribeToTopics();
        return;
      }
      retryCount++;
      await Future.delayed(Duration(milliseconds: 500 * retryCount));
    }
    _fcm.onTokenRefresh.listen((_) async {
      if (await _fcm.getAPNSToken() != null) await _subscribeToTopics();
    });
  }

  static Future<void> _subscribeToTopics() async {
    try {
      await _fcm.subscribeToTopic('weekend_briefing');
      await _fcm.subscribeToTopic('severe_weather_alert');
    } catch (_) {}
  }
}