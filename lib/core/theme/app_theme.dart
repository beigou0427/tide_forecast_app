import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Jony Ive 哲學重塑：冰川深淵與極簡冷冽光學光譜 (The Master Abyssal Palette)
/// 遵循 90% 單色克制、10% 精準訊號原則
class AppColors {
  // 冰川深淵底層
  static const Color abyssBlack = Color(0xFF02060D);   // 極致深海純黑畫布 (OLED零發光)
  static const Color abyssSurface = Color(0xFF070F1A); // 次層透光基底
  static const Color abyssCard = Color(0xFF0C1624);    // 浮島主體層
  
  // 主角靈魂光：冰川天青 (純淨、通透、極簡冷冽藍)
  static const Color pelagicCyan = Color(0xFF38BDF8); 
  static const Color marineBlue = Color(0xFF0284C7);   // 航海沉穩藍
  
  // 輔助功能光 (僅用於例外與極限訊號)
  static const Color bioGold = Color(0xFFEAB308);      // 香檳琥珀金 (爆咬/VVIP)
  static const Color hazardCoral = Color(0xFFF43F5E);  // 警戒珊瑚紅 (長湧/危險)
  
  // 光學水晶與微光切面
  static const Color glassBorder = Color(0x18FFFFFF);  // 0.5pt 極致透光微切面 (10% 霧白)
  static const Color glassSurface = Color(0x06FFFFFF); // 微透流體層 (2.5% 白)
  
  // Apple 典範文字階層 (Typography Contrast Ratio > 7:1)
  static const Color textPrimary = Color(0xFFF8FAFC);   // 100% 冰白
  static const Color textSecondary = Color(0xFF94A3B8); // 60% 沉靜石板灰
  static const Color textTertiary = Color(0xFF64748B);  // 40% 弱化刻度灰

  // 經典復古白藍專用 (外礁烈日高對比)
  static const Color classicBg = Color(0xFFF8FAFC);
  static const Color classicCard = Colors.white;
  static const Color classicText = Color(0xFF0F172A);
}

final isClassicThemeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<bool> {
  static const String _prefKey = 'is_classic_theme_v1';

  ThemeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefKey) ?? false;
  }

  Future<void> setClassicTheme(bool isClassic) async {
    state = isClassic;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isClassic);
  }
}

class AppTheme {
  // 深淵黑金旗艦主題 (Jony Ive 純粹工藝)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.abyssBlack,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.abyssSurface,
        primary: AppColors.pelagicCyan,
        secondary: AppColors.bioGold,
        error: AppColors.hazardCoral,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        color: AppColors.abyssCard,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 0.5,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.abyssCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.abyssCard,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: GoogleFonts.notoSansTcTextTheme(
        ThemeData.dark().textTheme.copyWith(
          bodyMedium: const TextStyle(
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          bodyLarge: const TextStyle(
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          titleLarge: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  // 經典白藍老船長主題 (烈日外礁高對比)
  static ThemeData get classicLightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.classicBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.marineBlue,
        surface: AppColors.classicCard,
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200, width: 0.8),
        ),
        color: AppColors.classicCard,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 0.8,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.marineBlue,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.marineBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: GoogleFonts.notoSansTcTextTheme(
        ThemeData.light().textTheme.copyWith(
          bodyMedium: const TextStyle(
            color: AppColors.classicText,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          bodyLarge: const TextStyle(
            color: AppColors.classicText,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
