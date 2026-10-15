import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // 🌟 核心修復：補齊時間格式化套件

import '../../../core/theme/app_theme.dart';
import '../data/tide_model.dart';
import '../../catch_log/data/catch_log_model.dart';
import 'widgets/hero_metric_card.dart';
import 'widgets/metric_grid.dart';
import 'widgets/wind_compass_card.dart';
import 'home_page.dart';

/// 🌟 頂級 CMO 內建 App Store 截圖渲染引擎 (ASO Screenshot Carousel)
/// 100% 零後製產出版：滑動即展示 7 大 ASO 完美排版，直接 Cmd+S 即可送審 Apple！
class AsoStudioPage extends ConsumerStatefulWidget {
  const AsoStudioPage({super.key});

  @override
  ConsumerState<AsoStudioPage> createState() => _AsoStudioPageState();
}

class _AsoStudioPageState extends ConsumerState<AsoStudioPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // 🌟 構造極致完美的展示用假資料 (Mock Data)
  final TideStationData _mockStation = TideStationData(
    info: StationInfo(stationName: "新北石門 富貴角資料浮標 (C6AH2)", countyName: "新北市", townName: "石門區", lat: "25.3", lng: "121.5", attr: "資料浮標", addressDescription: ""),
    observations: [
      Observation(dateTime: DateTime.now(), waveHeight: 2.8, wavePeriod: 11.5, windSpeed: 14.5, windDirection: 45.0, tideHeight: 1.85, tideLevel: "滿潮", seaTemperature: 24.5, airPressure: 1008.2)
    ],
    forecasts: [],
    aiBriefing: AIExpertBriefing(briefing: "M4 引擎推演：滿退 2 分起流，黑毛、紅甘索餌意願極高。", safetyScore: 88, activities: []),
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    
    // 自動根據場景切換全域主題，讓嵌入的真實 Widget 呈現對應光學模式
    if (index == 1 || index == 5) {
      ref.read(themeModeProvider.notifier).setTheme(AppThemeMode.classicLight);
    } else if (index == 3) {
      ref.read(themeModeProvider.notifier).setTheme(AppThemeMode.eInkHighContrast);
    } else {
      ref.read(themeModeProvider.notifier).setTheme(AppThemeMode.darkAbyss);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> asoPages = [
      _buildAsoPage(
        title: "拒絕盲目等流\n奪回看海特權",
        subtitle: "穿透氣象署內部光纖，85 測站 0 延遲實況雷達。",
        bgColors: const [Color(0xFF021B33), Color(0xFF003870)],
        child: Column(
          children: [
            HeroMetricCard(current: _mockStation.observations.last, isBuoy: true),
            const SizedBox(height: 16),
            MetricGrid(current: _mockStation.observations.last),
          ],
        ),
      ),
      _buildAsoPage(
        title: "滿退 2 分起流\n精算爆咬時機",
        subtitle: "M4 天體物理引擎推演，一眼看穿黃金索餌窗口。",
        bgColors: const [Color(0xFF0077B6), Color(0xFF023E8A)],
        child: BiteRadarSection(
          station: _mockStation,
          selectedDate: DateTime.now(),
          isClassic: true,
          isEInk: false,
        ),
      ),
      _buildAsoPage(
        title: "瘋狗浪預警\n比死神快 30 分鐘",
        subtitle: "外海深層長湧動能提前示警，守護您與家人的安全。",
        bgColors: const [Color(0xFF6B1115), Color(0xFF38070A)],
        child: _buildMockSurgeAlert(),
      ),
      _buildAsoPage(
        title: "駕駛台專屬\n烈日抗反光模式",
        subtitle: "無懼海上強光直射，螢幕常亮永不熄火的硬核指揮艙。",
        bgColors: const [Color(0xFF2C3E50), Color(0xFF000000)],
        child: WindCompassCard(current: _mockStation.observations.last),
      ),
      _buildAsoPage(
        title: "拔掉 SIM 卡\n照樣精準導航",
        subtitle: "出海前預載全島神盾，外礁無基地台訊號照常運行。",
        bgColors: const [Color(0xFF064E3B), Color(0xFF022C22)],
        child: _buildMockOfflineShield(),
      ),
      _buildAsoPage(
        title: "官方實測鋼印\n戰績無可反駁",
        subtitle: "拍下戰利品自動疊加水文數據，稱霸 LINE 釣魚群組。",
        bgColors: const [Color(0xFFD4AF37), Color(0xFF8B6508)],
        child: _buildMockCatchLog(),
      ),
      _buildAsoPage(
        title: "免綁卡問卷\n領取 7 天旗艦特權",
        subtitle: "週末海象高峰即將到來。完成問卷立即解鎖光纖直連。",
        bgColors: const [Color(0xFF1F2937), Color(0xFF111827)],
        child: _buildMockPaywall(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: asoPages.length,
            itemBuilder: (context, index) => asoPages[index],
          ),
          
          // 頂部導航列 (懸浮)
          Positioned(
            top: 50, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    Navigator.pop(context);
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Text(
                    "ASO Screen 0${_currentIndex + 1} / 07",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 通用 ASO 截圖單頁渲染器
  Widget _buildAsoPage({
    required String title,
    required String subtitle,
    required List<Color> bgColors,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 50), // 留白給懸浮 Appbar
            // 🌟 ASO 介紹語區塊 (文案)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansTc(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.25,
                      letterSpacing: -1.0,
                      shadows: [const Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // 🌟 模擬手機視窗 (App UI 容器)
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: ref.watch(themeModeProvider) == AppThemeMode.classicLight ? const Color(0xFFF8FAFC) : const Color(0xFF02060D),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 5)],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== 以下為各場景的專屬 Mock UI ======

  Widget _buildMockSurgeAlert() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0505),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.hazardCoral, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
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
          const SizedBox(height: 12),
          const Text(
            "HALT 警戒: 嚴禁水上作業",
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          const Text(
            "外海深層長湧動能已被 AI 哨兵提前捕捉！\n\n滿潮蓋礁危機即將爆發，這不是演習，為了您與家人的安全，請即刻收竿撤離至安全高地！", 
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.6, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hazardCoral, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.directions_run_rounded, size: 22),
              label: const Text("立即撤離保命", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockOfflineShield() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF051C12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.signal_wifi_off_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("全島 85 站離線神盾", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      SizedBox(height: 4),
                      Text("拔掉 SIM 卡照常運作", style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                child: const Text("ANTI-FRAGILE", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "✅ 離線神盾預載完畢！外礁無基地台訊號，導航照常秒級運行。", 
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(value: 1.0, minHeight: 8, backgroundColor: Colors.black45, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  Widget _buildMockCatchLog() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF0077B6)),
                  SizedBox(width: 4),
                  Text("富貴角資料浮標 (C6AH2)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0077B6))),
                ],
              ),
              Text(DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now()), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Icon(Icons.phishing_rounded, size: 64, color: Colors.grey)),
              ),
              Positioned(
                bottom: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.bioGold, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppColors.bioGold, size: 14),
                      SizedBox(width: 6),
                      Text("氣象署實測鋼印", style: TextStyle(color: AppColors.bioGold, fontSize: 11, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("巨無霸紅甘", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFF07C)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text("👑 傳奇大物 · 官方認證", style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06C755), 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.campaign_rounded, size: 18),
              label: const Text("一鍵發布戰報至 LINE 群組", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockPaywall() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F3B2A), Color(0xFF051C12)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.black87, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("免綁卡問卷 · 領取 7 天旗艦特權", style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 15)),
                    SizedBox(height: 6),
                    Text("週末海象高峰將至。完成問卷立即解鎖。", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00B4D8), width: 2.0),
          ),
          child: const Row(
            children: [
              Icon(Icons.radio_button_checked, color: Color(0xFF00B4D8), size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("年度指揮官計畫", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("最高性價比 · 支援 Apple 家人共享", style: TextStyle(color: Color(0xFF00B4D8), fontSize: 12)),
                  ],
                ),
              ),
              Text("NT\$ 990", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {},
            child: const Text("🚀 啟動 7 天免費試用 (不滿意隨時取消)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}
