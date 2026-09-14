import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 🌟 必須引入，處理繁體中文環境
import 'features/tide/presentation/home_page.dart';

void main() {
  // 確保 Flutter 引擎在啟動前已完成初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // 🌟 必須包裹 ProviderScope，否則所有 ref.watch 都不會運作
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '潮汐海象預報',

      // 🌟 核心修正 1：處理繁體中文語系 (讓日曆、對話框顯示中文)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'), // 繁體中文
        Locale('en', 'US'), // 英文備援
      ],

      // 🌟 核心修正 2：解決字體出現問號的問題
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0077B6), // 專業海洋藍色調
        
        // 當預設字體找不到中文字符時，強制回退到系統自帶的繁體中文字體
        fontFamilyFallback: const [
          'PingFang TC',       // iOS 繁體中文
          'Noto Sans TC',      // Android 繁體中文
          'Microsoft JhengHei', // Windows 繁體中文
          'sans-serif',
        ],
        
        // 優化 AppBar 文字樣式
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      // 設定首頁
      home: const HomePage(),
    );
  }
}