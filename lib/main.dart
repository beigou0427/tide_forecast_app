import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'firebase_options.dart';
import 'features/tide/presentation/home_page.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'core/services/analytics_service.dart';
import 'core/services/global_error_trap.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌟 VVIP 核心：允許全向螢幕轉動 (支援 iPad / 駕駛台橫置)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 🌟 啟用螢幕常亮 (Wakelock)，保障航海儀表板永不熄火黑屏
  WakelockPlus.enable();

  // 第 1 層：Flutter Widget 樹同步渲染例外攔截
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    GlobalErrorTrap.recordException(
      details.exception,
      stackTrace: details.stack,
      contextTag: "FlutterUI",
      severity: ErrorSeverity.error,
    );
  };

  // 第 2 層：Flutter 3+ 非同步/背景佇列未捕獲例外天網
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    GlobalErrorTrap.recordException(
      error,
      stackTrace: stack,
      contextTag: "AsyncPlatformRoot",
      severity: ErrorSeverity.critical,
    );
    return true; 
  };

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await AnalyticsService.init();
  } catch (e, stack) {
    debugPrint("Firebase 初始化異常 (離線或測試環境): $e");
    GlobalErrorTrap.recordException(
      e,
      stackTrace: stack,
      contextTag: "FirebaseBootstrap",
      severity: ErrorSeverity.warning,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final bool hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

  runApp(
    ProviderScope(
      child: MyApp(hasCompletedOnboarding: hasCompletedOnboarding),
    ),
  );
}

/// 🌟 支援 3 模切換 (深淵黑金 / 經典白藍 / E-Ink烈日) 之全域根 Widget
class MyApp extends ConsumerWidget {
  final bool hasCompletedOnboarding;
  const MyApp({super.key, required this.hasCompletedOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    ThemeData activeTheme;
    ThemeMode activeThemeMode;
    Brightness statusIconBrightness;
    Color navBarColor;

    switch (themeMode) {
      case AppThemeMode.eInkHighContrast:
        activeTheme = AppTheme.eInkTheme;
        activeThemeMode = ThemeMode.light;
        statusIconBrightness = Brightness.dark;
        navBarColor = AppColors.eInkWhite;
        break;
      case AppThemeMode.classicLight:
        activeTheme = AppTheme.classicLightTheme;
        activeThemeMode = ThemeMode.light;
        statusIconBrightness = Brightness.dark;
        navBarColor = AppColors.classicBg;
        break;
      case AppThemeMode.darkAbyss:
        activeTheme = AppTheme.darkTheme;
        activeThemeMode = ThemeMode.dark;
        statusIconBrightness = Brightness.light;
        navBarColor = AppColors.abyssBlack;
        break;
    }

    // 狀態列自適應深淺與 OLED 零發光純黑
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: statusIconBrightness,
        systemNavigationBarColor: navBarColor,
        systemNavigationBarIconBrightness: statusIconBrightness,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '潮汐表 Pro',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'TW'), Locale('en', 'US')],
      
      theme: activeTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: activeThemeMode,
      
      home: hasCompletedOnboarding ? const HomePage() : const OnboardingPage(),
    );
  }
}