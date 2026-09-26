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
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

// 🌟 升級為 ConsumerWidget，實現全域主題動態切換
class MyApp extends ConsumerWidget {
  final bool hasCompletedOnboarding;
  const MyApp({super.key, required this.hasCompletedOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🌟 即時監聽 VIP 介面切換狀態機
    final isClassic = ref.watch(isClassicThemeProvider);

    // 狀態列自適應深淺
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isClassic ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isClassic ? AppColors.classicBg : AppColors.abyssBlack,
        systemNavigationBarIconBrightness: isClassic ? Brightness.dark : Brightness.light,
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
      // 🌟 雙軌主題綁定
      theme: AppTheme.classicLightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isClassic ? ThemeMode.light : ThemeMode.dark,
      home: hasCompletedOnboarding ? const HomePage() : const OnboardingPage(),
    );
  }
}