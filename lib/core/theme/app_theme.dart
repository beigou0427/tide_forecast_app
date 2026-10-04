import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { darkAbyss, classicLight, eInkHighContrast }

class AppColors {
  // 1. 深淵黑金旗艦主題 (Jony Ive)
  static const Color abyssBlack = Color(0xFF02060D);
  static const Color abyssSurface = Color(0xFF070F1A);
  static const Color abyssCard = Color(0xFF0C1624);
  
  static const Color pelagicCyan = Color(0xFF38BDF8); 
  static const Color marineBlue = Color(0xFF0284C7);
  
  static const Color bioGold = Color(0xFFEAB308);
  static const Color hazardCoral = Color(0xFFF43F5E);
  
  static const Color glassBorder = Color(0x18FFFFFF);
  
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  // 2. 經典復古白藍專用
  static const Color classicBg = Color(0xFFF8FAFC);
  static const Color classicCard = Colors.white;
  static const Color classicText = Color(0xFF0F172A);

  // 🌟 3. VVIP 專屬：E-Ink 烈日高對比黑白 (極致無陰影抗反光)
  static const Color eInkWhite = Color(0xFFFFFFFF);
  static const Color eInkBlack = Color(0xFF000000);
  static const Color eInkGrey = Color(0xFF333333);
}

/// 🌟 支援三模切換的主題狀態機
final themeModeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const String _prefKey = 'app_theme_mode_v2';

  ThemeNotifier() : super(AppThemeMode.darkAbyss) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final int index = prefs.getInt(_prefKey) ?? 0;
    if (index >= 0 && index < AppThemeMode.values.length) {
      state = AppThemeMode.values[index];
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, mode.index);
  }

  // 循環切換主題 (深淵 -> 經典 -> E-Ink)
  Future<void> cycleTheme() async {
    final nextIndex = (state.index + 1) % AppThemeMode.values.length;
    await setTheme(AppThemeMode.values[nextIndex]);
  }
}

/// 🌟 橋接模式 (Bridge Pattern)：
/// 為了不破壞既有舊頁面 (如 catch_log_page 等) 對 isClassicThemeProvider 的依賴，
/// 建立向下相容的布林值橋接器，狀態與新的 3 模引擎雙向綁定！
final isClassicThemeProvider = StateNotifierProvider<ThemeNotifierBridge, bool>((ref) {
  return ThemeNotifierBridge(ref);
});

class ThemeNotifierBridge extends StateNotifier<bool> {
  final Ref ref;
  ThemeNotifierBridge(this.ref) : super(false) {
    // 初始化同步
    final mode = ref.read(themeModeProvider);
    state = mode != AppThemeMode.darkAbyss;
  }

  void setClassicTheme(bool isClassic) {
    state = isClassic;
    // 雙向驅動新狀態機
    ref.read(themeModeProvider.notifier).setTheme(
      isClassic ? AppThemeMode.classicLight : AppThemeMode.darkAbyss
    );
  }
}

class AppTheme {
  // 1. 深淵黑金旗艦主題
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
      dividerTheme: const DividerThemeData(color: AppColors.glassBorder, thickness: 0.5, space: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3),
      ),
      textTheme: GoogleFonts.notoSansTcTextTheme(
        ThemeData.dark().textTheme.copyWith(
          bodyMedium: const TextStyle(color: AppColors.textPrimary, fontFeatures: [FontFeature.tabularFigures()]),
          bodyLarge: const TextStyle(color: AppColors.textPrimary, fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }

  // 2. 經典白藍老船長主題
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
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 0.8, space: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.marineBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
      ),
      textTheme: GoogleFonts.notoSansTcTextTheme(
        ThemeData.light().textTheme.copyWith(
          bodyMedium: const TextStyle(color: AppColors.classicText, fontFeatures: [FontFeature.tabularFigures()]),
          bodyLarge: const TextStyle(color: AppColors.classicText, fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }

  // 🌟 3. VVIP 專屬：E-Ink 烈日高對比黑白主題 (絕對 0 陰影，邊界銳利化)
  static ThemeData get eInkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.eInkWhite,
      colorScheme: const ColorScheme.light(
        surface: AppColors.eInkWhite,
        primary: AppColors.eInkBlack,
        secondary: AppColors.eInkBlack,
        error: AppColors.eInkBlack,
      ),
      cardTheme: CardThemeData(
        elevation: 0, // 絕對 0 陰影，杜絕陽光折射干擾
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0), // 方正銳利邊角
          side: const BorderSide(color: AppColors.eInkBlack, width: 2.0), // 特粗黑色外框
        ),
        color: AppColors.eInkWhite,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.eInkBlack, thickness: 2.0, space: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.eInkWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.eInkBlack, size: 28),
        shape: Border(bottom: BorderSide(color: AppColors.eInkBlack, width: 3.0)),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.eInkBlack, letterSpacing: 0),
      ),
      textTheme: GoogleFonts.notoSansTcTextTheme(
        ThemeData.light().textTheme.copyWith(
          bodyMedium: const TextStyle(color: AppColors.eInkBlack, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]),
          bodyLarge: const TextStyle(color: AppColors.eInkBlack, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }
}
