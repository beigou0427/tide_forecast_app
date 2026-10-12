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

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    GlobalErrorTrap.recordException(details.exception, stackTrace: details.stack, contextTag: "FlutterUI", severity: ErrorSeverity.error);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    GlobalErrorTrap.recordException(error, stackTrace: stack, contextTag: "AsyncPlatformRoot", severity: ErrorSeverity.critical);
    return true; 
  };

  unawaited(
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 3))
        .then((_) => AnalyticsService.init())
        .catchError((e, stack) => GlobalErrorTrap.recordException(e, stackTrace: stack, contextTag: "FirebaseBootstrap", severity: ErrorSeverity.warning))
  );

  final prefs = await SharedPreferences.getInstance();
  final bool hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
  final String? pendingCohort = prefs.getString('pending_deeplink_cohort');

  runApp(
    ProviderScope(
      child: MyApp(hasCompletedOnboarding: hasCompletedOnboarding, initialCohort: pendingCohort),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final bool hasCompletedOnboarding;
  final String? initialCohort;
  const MyApp({super.key, required this.hasCompletedOnboarding, this.initialCohort});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isPureTide = ref.watch(isPureTideModeProvider);

    if (isPureTide) {
      WakelockPlus.enable().catchError((_) {});
    } else {
      WakelockPlus.disable().catchError((_) {});
    }

    ThemeData activeTheme = AppTheme.darkTheme;
    ThemeMode activeThemeMode = ThemeMode.dark;
    Brightness statusIconBrightness = Brightness.light;
    Brightness iosStatusBarBrightness = Brightness.dark;
    Color navBarColor = AppColors.abyssBlack;

    if (themeMode == AppThemeMode.eInkHighContrast) {
      activeTheme = AppTheme.eInkTheme;
      activeThemeMode = ThemeMode.light;
      statusIconBrightness = Brightness.dark;
      iosStatusBarBrightness = Brightness.light;
      navBarColor = AppColors.eInkWhite;
    } else if (themeMode == AppThemeMode.classicLight) {
      activeTheme = AppTheme.classicLightTheme;
      activeThemeMode = ThemeMode.light;
      statusIconBrightness = Brightness.dark;
      iosStatusBarBrightness = Brightness.light;
      navBarColor = AppColors.classicBg;
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
        navigatorKey: appNavigatorKey, 
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
        home: widget.hasCompletedOnboarding ? const HomePage() : OnboardingPage(initialCohort: widget.initialCohort),

        onGenerateRoute: (settings) {
          if (settings.name == null || settings.name == '/') return null;
          final uri = Uri.tryParse(settings.name!);
          if (uri != null) {
            
            if (uri.path == '/onboarding' || uri.host == 'onboarding') {
              return MaterialPageRoute(builder: (_) => OnboardingPage(initialCohort: uri.queryParameters['cohort']));
            }

            // 🌟 修復一：大潮黃金視窗（隱形路由覆蓋技術，處理完立刻銷毀，不堆疊 HomePage）
            if (uri.path.contains('spring_tide_window') || uri.host == 'events') {
              return PageRouteBuilder(
                opaque: false,
                pageBuilder: (ctx, _, __) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final now = DateTime.now();
                    DateTime targetWeekend = now;
                    if (now.weekday != DateTime.saturday && now.weekday != DateTime.sunday) {
                      int daysToFriday = (5 - now.weekday + 7) % 7;
                      if (daysToFriday == 0 && now.hour >= 18) daysToFriday = 7;
                      targetWeekend = now.add(Duration(days: daysToFriday));
                    }
                    ref.read(selectedDateProvider.notifier).state = targetWeekend;
                    ScaffoldMessenger.of(appNavigatorKey.currentContext ?? ctx).showSnackBar(
                      const SnackBar(
                        content: Text("🌕 已為您鎖定週末大潮走水黃金窗口！", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        backgroundColor: AppColors.bioGold,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 4),
                      ),
                    );
                    Navigator.pop(ctx); 
                  });
                  return const SizedBox.shrink();
                }
              );
            }

            // 🌟 修復二：生命安全熔斷警報（合法呼叫 setMode，彈出對話框路由）
            if (uri.path.contains('surge') || uri.host == 'alerts') {
              return PageRouteBuilder(
                opaque: false,
                barrierColor: AppColors.hazardCoral.withValues(alpha: 0.9),
                barrierDismissible: false,
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (ctx, animation, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    HapticFeedback.heavyImpact();
                    Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());
                    // 調用合法封裝的方法，消滅編譯錯誤！
                    ref.read(isPureTideModeProvider.notifier).setMode(false);
                  });

                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                      child: AlertDialog(
                        backgroundColor: AppColors.abyssBlack,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white, width: 2)),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_rounded, color: AppColors.hazardCoral, size: 28),
                            SizedBox(width: 10),
                            Text("緊急撤礁警告", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        content: const Text(
                          "滿潮水位即將於 30 分鐘內逼近！\n請立即停止作釣，檢查身後退路，並迅速撤離至高處或安全海域！",
                          style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.bold),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hazardCoral, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("我已了解並開始撤離", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ),
                  );
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