import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'features/tide/presentation/home_page.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'core/services/analytics_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化 Firebase 核心與營運埋點監控
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AnalyticsService.init();
  } catch (e) {
    debugPrint("Firebase 初始化失敗: $e");
  }

  // 2. 初始化本地推播引擎 (每週五 18:00 本地定時與滿潮防困礁主動警報)
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint("本地推播服務初始化失敗: $e");
  }

  // 3. 🌟 初始化 FCM 雲端推播引擎 (跨裝置即時出海週報與後台喚醒)
  try {
    await FcmService.init();
  } catch (e) {
    debugPrint("FCM 雲端推播初始化失敗: $e");
  }

  // 4. 啟動閘門：檢查是否已完成阻斷式 Onboarding 問卷
  final prefs = await SharedPreferences.getInstance();
  final bool hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

  runApp(
    ProviderScope(
      child: MyApp(hasCompletedOnboarding: hasCompletedOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasCompletedOnboarding;
  const MyApp({super.key, required this.hasCompletedOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tide Pro 潮汐海象',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'TW'), Locale('en', 'US')],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0077B6),
        fontFamilyFallback: const ['PingFang TC', 'Noto Sans TC', 'Microsoft JhengHei', 'sans-serif'],
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: hasCompletedOnboarding ? const HomePage() : const OnboardingPage(),
    );
  }
}
