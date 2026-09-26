import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🍏 Apple 首席設計系統代碼：深淵霓光色系 (The Abyssal Palette)
class AppColors {
  // 純黑與深淵玻璃底層
  static const Color abyssBlack = Color(0xFF03070D); // OLED 極致純黑畫布
  static const Color abyssSurface = Color(0xFF08101A); // 液態玻璃深層基底
  static const Color abyssCard = Color(0xFF0D1726); // 卡片主體懸浮層 (深藍黑)
  
  // 核心靈魂光譜
  static const Color pelagicCyan = Color(0xFF00E5FF); // 第一主角光：遠洋霓光青
  static const Color marineBlue = Color(0xFF0077B6); // 經典老船長藍
  static const Color bioGold = Color(0xFFFFD700); // 第二主角光：生物熒光金
  static const Color hazardCoral = Color(0xFFFF453A); // 警示赤潮珊瑚紅
  
  // 材質與玻璃折射
  static const Color glassBorder = Color(0x26FFFFFF); // 0.5pt 水晶折射邊界 (15% 霧白)
  static const Color glassShimmer = Color(0x0DFFFFFF); // 表面微光 (5% 白)
  
  // 字體層級系統
  static const Color textPrimary = Color(0xFFF5F5F7); // 標題主文字 (96% 白)
  static const Color textSecondary = Color(0x99EBEBF5); // 輔助說明文字 (60% 白)
  static const Color textTertiary = Color(0x4DEBEBF5); // 刻度與次要標籤 (30% 白)

  // 🌟 VIP 專屬經典白藍色系
  static const Color classicBg = Color(0xFFF8FBFF);
  static const Color classicCard = Colors.white;
  static const Color classicText = Color(0xFF1E293B);
}

// 🌟 VIP 介面切換狀態機 (持久化記憶到手機硬碟)
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
  // 🌟 旗艦：深淵 OLED 極致純黑主題 (預設)
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.4,
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

  // 🌟 復古：經典白藍老船長原版主題 (VIP 特權切換)
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: AppColors.classicCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.marineBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.4,
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