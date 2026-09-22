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
import 'core/services/global_error_trap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌟 真實全域崩潰與渲染異常看門狗
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    GlobalErrorTrap.record("${details.exception}");
  };

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await AnalyticsService.init();
  } catch (e) {
    debugPrint("Firebase 初始化失敗: $e");
  }

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint("本地推播服務初始化失敗: $e");
  }

  try {
    await FcmService.init();
  } catch (e) {
    debugPrint("FCM 雲端推播初始化失敗: $e");
  }

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
