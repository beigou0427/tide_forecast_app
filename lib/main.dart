import 'dart:async';
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

  // 1. 旋轉螢幕人因工程 (全向支援)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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

  // 🌟 非阻塞背景初始化 Firebase (加 3 秒超時保護，絕不卡死 main 執行緒)
  unawaited(
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 3))
        .then((_) => AnalyticsService.init())
        .catchError((e, stack) {
      debugPrint("Firebase 初始化異常 (離線或測試環境): $e");
      GlobalErrorTrap.recordException(
        e,
        stackTrace: stack,
        contextTag: "FirebaseBootstrap",
        severity: ErrorSeverity.warning,
      );
    })
  );

  final prefs = await SharedPreferences.getInstance();
  final bool hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
  final String? pendingCohort = prefs.getString('pending_deeplink_cohort');

  // 🌟 50ms 內極速呼叫 runApp，讓 Flutter 視圖與 Dart VM Service 瞬間連通！
  runApp(
    ProviderScope(
      child: MyApp(
        hasCompletedOnboarding: hasCompletedOnboarding,
        initialCohort: pendingCohort,
      ),
    ),
  );
}

/// 🌟 支援 3 模切換、首幀安全防熄火與 CPP 深度連結之全域根 Widget
class MyApp extends ConsumerStatefulWidget {
  final bool hasCompletedOnboarding;
  final String? initialCohort;

  const MyApp({
    super.key, 
    required this.hasCompletedOnboarding,
    this.initialCohort,
  });

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // 🌟 在 Activity 視窗掛載完成的首幀回調中啟用螢幕常亮，徹底消滅死鎖！
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        WakelockPlus.enable();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
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
      
      home: widget.hasCompletedOnboarding 
          ? const HomePage() 
          : OnboardingPage(initialCohort: widget.initialCohort),

      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri != null) {
          if (uri.path == '/onboarding' || uri.host == 'onboarding') {
            final cohort = uri.queryParameters['cohort'];
            return MaterialPageRoute(
              builder: (_) => OnboardingPage(initialCohort: cohort),
            );
          }

          if (uri.path.contains('spring_tide_window') || uri.host == 'events') {
            return MaterialPageRoute(
              builder: (_) => const HomePage(),
            );
          }
        }

        return MaterialPageRoute(
          builder: (_) => widget.hasCompletedOnboarding 
              ? const HomePage() 
              : OnboardingPage(initialCohort: widget.initialCohort),
        );
      },
    );
  }
}