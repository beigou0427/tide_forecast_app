import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'features/tide/presentation/home_page.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'core/services/analytics_service.dart';
import 'core/services/global_error_trap.dart';
import 'core/theme/app_theme.dart'; // 🌟 引入 Apple 首席深淵霓光設計系統

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🍏 Apple 頂級沉浸感：狀態列完全透明，無縫融入深淵黑底
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.abyssBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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
      title: '潮汐表 Pro',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'TW'), Locale('en', 'US')],
      // 🍏 Apple 首席設計系統：全域鎖定深淵 OLED 極致純黑主題
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: hasCompletedOnboarding ? const HomePage() : const OnboardingPage(),
    );
  }
}