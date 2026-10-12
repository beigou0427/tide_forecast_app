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
import 'features/tide/providers/tide_provider.dart';
import 'core/services/analytics_service.dart';
import 'core/services/global_error_trap.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // 🌟 克勞斯比 (Philip Crosby) 零缺陷：精確使用 WidgetsFlutterBinding 建立引擎單例
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 旋轉螢幕人因工程 (全向支援)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 🌟 第 1 層：Flutter Widget 樹同步渲染例外攔截
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    GlobalErrorTrap.recordException(
      details.exception,
      stackTrace: details.stack,
      contextTag: "FlutterUI",
      severity: ErrorSeverity.error,
    );
  };

  // 🌟 第 2 層：Flutter 3+ 非同步/背景佇列未捕獲例外天網
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
    Brightness iosStatusBarBrightness;
    Color navBarColor;

    switch (themeMode) {
      case AppThemeMode.eInkHighContrast:
        activeTheme = AppTheme.eInkTheme;
        activeThemeMode = ThemeMode.light;
        statusIconBrightness = Brightness.dark;
        iosStatusBarBrightness = Brightness.light;
        navBarColor = AppColors.eInkWhite;
        break;
      case AppThemeMode.classicLight:
        activeTheme = AppTheme.classicLightTheme;
        activeThemeMode = ThemeMode.light;
        statusIconBrightness = Brightness.dark;
        iosStatusBarBrightness = Brightness.light;
        navBarColor = AppColors.classicBg;
        break;
      case AppThemeMode.darkAbyss:
        activeTheme = AppTheme.darkTheme;
        activeThemeMode = ThemeMode.dark;
        statusIconBrightness = Brightness.light;
        iosStatusBarBrightness = Brightness.dark;
        navBarColor = AppColors.abyssBlack;
        break;
    }

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: iosStatusBarBrightness,
      statusBarIconBrightness: statusIconBrightness,
      systemNavigationBarColor: navBarColor,
      systemNavigationBarIconBrightness: statusIconBrightness,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MaterialApp(
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
          // 🚨 核心防呆：請求根路由 '/' 或空路徑強制返回 null，home: 為單一真相來源
          if (settings.name == null || settings.name == '/') {
            return null;
          }

          final uri = Uri.tryParse(settings.name!);
          if (uri != null) {
            
            // 🌟 Johannes von Cramon CPP 受眾精準分流路由
            if (uri.path == '/onboarding' || uri.host == 'onboarding') {
              final cohort = uri.queryParameters['cohort'];
              return MaterialPageRoute(
                builder: (_) => OnboardingPage(initialCohort: cohort),
              );
            }

            // 🌟 Moritz Daan 週末大潮 IAE 活動深度縫合路由
            if (uri.path.contains('spring_tide_window') || uri.host == 'events') {
              return MaterialPageRoute(
                builder: (ctx) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!ctx.mounted) return;
                    final now = DateTime.now();

                    // 🚨 核心時態防線：若當前剛好是週末 (週六/週日)，大潮活動就是「這個週末」！
                    // 絕不荒謬向後跳躍 6 天至下週五！
                    DateTime targetWeekend;
                    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
                      targetWeekend = now;
                    } else {
                      int daysToFriday = (5 - now.weekday + 7) % 7;
                      if (daysToFriday == 0 && now.hour >= 18) daysToFriday = 7;
                      targetWeekend = now.add(Duration(days: daysToFriday));
                    }

                    ref.read(selectedDateProvider.notifier).state = targetWeekend;
                    
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text("🌕 已為您鎖定週末大潮走水黃金窗口！", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        backgroundColor: AppColors.bioGold,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  });
                  return const HomePage();
                },
              );
            }
          }

          return null;
        },
      ),
    );
  }
}
