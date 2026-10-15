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
import 'features/catch_log/presentation/catch_log_page.dart';
import 'features/premium/presentation/vip_center_page.dart';
import 'features/onboarding/presentation/founder_welcome_dialog.dart';

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

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final isPureTide = ref.read(isPureTideModeProvider);
    
    if (state == AppLifecycleState.resumed) {
      if (isPureTide) WakelockPlus.enable().catchError((_) {});
    } else {
      WakelockPlus.disable().catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isPureTide = ref.watch(isPureTideModeProvider);

    if (isPureTide && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
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
            
            if (uri.path.contains('home') || uri.host == 'home') {
              return PageRouteBuilder(
                opaque: false,
                pageBuilder: (ctx, _, __) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(isPureTideModeProvider.notifier).setMode(false);
                    if (uri.queryParameters.containsKey('sid')) {
                      ref.read(currentStationIdProvider.notifier).state = uri.queryParameters['sid']!;
                    }
                    Navigator.pop(ctx);
                  });
                  return const SizedBox.shrink();
                },
              );
            }

            if (uri.path.contains('pure_tide') || uri.host == 'pure_tide') {
              return PageRouteBuilder(
                opaque: false,
                pageBuilder: (ctx, _, __) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(isPureTideModeProvider.notifier).setMode(true);
                    if (uri.queryParameters.containsKey('sid')) {
                      ref.read(currentStationIdProvider.notifier).state = uri.queryParameters['sid']!;
                    }
                    Navigator.pop(ctx);
                  });
                  return const SizedBox.shrink();
                },
              );
            }

            if (uri.path.contains('catch_log') || uri.host == 'catch_log') {
              return MaterialPageRoute(builder: (_) => const CatchLogPage());
            }

            if (uri.path.contains('vip_center') || uri.host == 'vip_center') {
              return MaterialPageRoute(builder: (_) => const VipCenterPage());
            }

            if (uri.path.contains('letter') || uri.host == 'letter') {
              return PageRouteBuilder(
                opaque: false,
                pageBuilder: (ctx, _, __) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final rootCtx = appNavigatorKey.currentContext ?? ctx;
                    FounderWelcomeDialog.showCommissionLetter(rootCtx, isFounder: true);
                    Navigator.pop(ctx);
                  });
                  return const SizedBox.shrink();
                },
              );
            }

            if (uri.queryParameters.containsKey('sid')) {
              final sid = uri.queryParameters['sid']!;
              return PageRouteBuilder(
                opaque: false,
                pageBuilder: (ctx, _, __) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(currentStationIdProvider.notifier).state = sid;
                    ref.read(selectedDateProvider.notifier).state = DateTime.now();
                    Navigator.pop(ctx); 
                  });
                  return const SizedBox.shrink();
                }
              );
            }

            if (uri.path == '/onboarding' || uri.host == 'onboarding') {
              return MaterialPageRoute(builder: (_) => OnboardingPage(initialCohort: uri.queryParameters['cohort']));
            }

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
                    Navigator.pop(ctx); 
                  });
                  return const SizedBox.shrink();
                }
              );
            }

            // 🌟 核心打擊點：第 3 幀【恐懼喚醒 (The Fear Factor)】UI 真實注入！
            if (uri.path.contains('surge') || uri.host == 'alerts') {
              return PageRouteBuilder(
                opaque: false,
                barrierColor: AppColors.hazardCoral.withValues(alpha: 0.95), // 加深血紅壓迫感
                barrierDismissible: false,
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (ctx, animation, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    HapticFeedback.heavyImpact();
                    ref.read(isPureTideModeProvider.notifier).setMode(false);
                  });

                  return AlertDialog(
                    backgroundColor: const Color(0xFF1A0505), // 極致深紅底色
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24), 
                      side: const BorderSide(color: AppColors.hazardCoral, width: 2.5),
                    ),
                    title: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.dangerous_rounded, color: AppColors.hazardCoral, size: 32),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "瘋狗浪預警 · 比死神快30分鐘", 
                                style: TextStyle(color: AppColors.hazardCoral, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "HALT 警戒: 嚴禁水上作業",
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
                        )
                      ],
                    ),
                    content: const Text(
                      "外海深層長湧動能已被 AI 哨兵提前捕捉！\n\n滿潮蓋礁危機即將爆發，這不是演習，為了您與家人的安全，請即刻收竿撤離至安全高地！", 
                      style: TextStyle(color: Colors.white, fontSize: 14.5, height: 1.6, fontWeight: FontWeight.w600),
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.hazardCoral, 
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 8,
                            shadowColor: AppColors.hazardCoral.withValues(alpha: 0.6),
                          ),
                          icon: const Icon(Icons.directions_run_rounded, size: 20),
                          label: const Text("立即撤離保命 (Acknowledge)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                    ],
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
