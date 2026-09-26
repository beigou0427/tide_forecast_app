import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/tide_model.dart';
import 'widgets/hero_metric_card.dart';
import 'widgets/solunar_card.dart';
import 'tide_chart_sheet.dart'; // 🌟 修復路徑：平級引用同目錄下的 tide_chart_sheet.dart
import 'widgets/wind_compass_card.dart';
import '../../../shared/widgets/custom_card.dart';

class AsoStudioPage extends StatefulWidget {
  const AsoStudioPage({super.key});

  @override
  State<AsoStudioPage> createState() => _AsoStudioPageState();
}

class _AsoStudioPageState extends State<AsoStudioPage> {
  int _currentSlide = 0;
  bool _cleanMode = false;

  final List<Map<String, String>> _slideMeta = [
    {
      "tag": "全台首創 · AI 水文決策",
      "title": "85 測站 0 延遲光纖直連\n老船長 AI 即時出海晨報",
      "subtitle": "官方即時浪高 · 蒲福風速 · 水溫週期全監測",
    },
    {
      "tag": "獨家技術 · 爆咬時段可視化",
      "title": "30 天潮位時空預測\n一眼看透黃金出海咬度期",
      "subtitle": "滿水波峰自動標定 · 日月引力大中小潮推算",
    },
    {
      "tag": "釣友互助 · 現場海象情報",
      "title": "海釣版 Waze 實況雷達\n現場風浪即時通報與 AI 哨兵",
      "subtitle": "釣友第一手水況 · 突發大湧預警 · 防困礁守護",
    },
    {
      "tag": "戰利品專屬藏寶庫",
      "title": "潮汐漁獲相片日誌\n自動疊加當下即時水文",
      "subtitle": "拍攝魚獲自動綁定浪高與潮位 · 離線雲端雙向同步",
    },
    {
      "tag": "尊榮旗艦 · 掌舵特權",
      "title": "VIP 專屬黑金指揮中心\n代幣經濟與光纖直連通道",
      "subtitle": "專屬身分銘牌 · LINE 戰報鋼印 · 離線黑盒子防禦",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final meta = _slideMeta[_currentSlide];

    return Scaffold(
      backgroundColor: const Color(0xFF021B33),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (!_cleanMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B4D8).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00B4D8), width: 1),
                          ),
                          child: Text(
                            "ASO 宣傳截圖攝影棚 [${_currentSlide + 1}/5]",
                            style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_rounded, color: Colors.amberAccent),
                          tooltip: "進入純淨截圖模式",
                          onPressed: () => setState(() => _cleanMode = true),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meta["tag"]!,
                          style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        meta["title"]!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansTc(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meta["subtitle"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: _buildSlideContent(_currentSlide),
                  ),
                ),
              ],
            ),

            if (!_cleanMode)
              Positioned(
                bottom: 20, left: 20, right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF062343).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(5, (idx) {
                          final isCur = _currentSlide == idx;
                          return InkWell(
                            onTap: () => setState(() => _currentSlide = idx),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCur ? const Color(0xFF00B4D8) : Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "0${idx + 1}",
                                style: TextStyle(
                                  color: isCur ? Colors.white : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.fullscreen_rounded, size: 18),
                        label: const Text("截圖", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        onPressed: () {
                          setState(() => _cleanMode = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("📸 已進入純淨截圖模式！點擊螢幕任何地方可退出。"),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF0077B6),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            if (_cleanMode)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _cleanMode = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideContent(int slideIdx) {
    final now = DateTime.now();

    final perfectObs = Observation(
      dateTime: now,
      waveHeight: 0.8,
      windSpeed: 3.5,
      wavePeriod: 6.8,
      seaTemperature: 24.8,
      tideHeight: 1.82,
      tideLevel: "滿潮退2分",
      windDirection: 67.5,
      airTemperature: 26.5,
      airPressure: 1013.2,
    );

    switch (slideIdx) {
      case 0:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0077B6), Color(0xFF023E8A)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("📍 新北石門 富貴角資料浮標 (C6AH2)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Icon(Icons.volume_up_rounded, color: Colors.amberAccent, size: 22),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.anchor_rounded, color: Colors.amberAccent, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "老船長 AI 專家簡報：今日海況平穩，長湧浪週期平順。滿潮返退 2 分水流暢通，黑毛、石斑索餌意願極高，全島近岸作業條件優良！",
                          style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            HeroMetricCard(current: perfectObs, isBuoy: true),
            const SizedBox(height: 14),
            WindCompassCard(current: perfectObs),
          ],
        );

      case 1:
        final mockChartData = List.generate(24, (i) {
          final t = now.subtract(Duration(hours: 23 - i));
          final double h = 1.2 + 0.8 * (i == 14 ? 1.0 : (i % 6 - 3).abs() * 0.2);
          return Observation(dateTime: t, tideHeight: double.parse(h.toStringAsFixed(2)));
        });

        return Column(
          children: [
            SolunarCard(selectedDate: now),
            const SizedBox(height: 14),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("🌊 24h 潮位走勢與黃金波峰", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text("滿水前後2小時標定", style: TextStyle(color: Color(0xFFD84315), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TideChartSheet(observations: mockChartData),
                ],
              ),
            ),
          ],
        );

      case 2:
        return Column(
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.radar_rounded, color: Colors.deepOrange, size: 24),
                          SizedBox(width: 8),
                          Text("Waze 現場海況雷達", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(8)),
                        child: const Text("即時通報", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAsoReportItem("🐟 現場魚群大咬中！", "12 分鐘前", "🔱 年度首席領航員", 18, Colors.deepOrange),
                  _buildAsoReportItem("⛵ 現場風浪比預報更平穩", "35 分鐘前", "👑 創始天尊指揮官", 14, const Color(0xFF0077B6)),
                  _buildAsoReportItem("🌊 外礁開始走活水", "1 小時前", "🤖 AI 水文巡航哨兵", 9, Colors.teal),
                ],
              ),
            ),
          ],
        );

      case 3:
        return Column(
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Color(0xFF0077B6)),
                          SizedBox(width: 4),
                          Text("新北石門 富貴角 (C6AH2)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0077B6))),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.cloud_done_outlined, size: 12, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(DateFormat('yyyy/MM/dd HH:mm').format(now), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.phishing_rounded, size: 64, color: Colors.white24),
                        Positioned(
                          bottom: 12, left: 16,
                          child: Text("🐟 白毛 48.5cm / 2.3kg", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: Text("滿潮返退2分水大咬，青磺蝦中層截擊！", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                      Row(children: [Icon(Icons.star_rounded, color: Colors.amber, size: 16), Icon(Icons.star_rounded, color: Colors.amber, size: 16), Icon(Icons.star_rounded, color: Colors.amber, size: 16), Icon(Icons.star_rounded, color: Colors.amber, size: 16), Icon(Icons.star_rounded, color: Colors.amber, size: 16)]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _badge("潮位 1.82 m", Colors.blue),
                      _badge("浪高 0.8 m", Colors.indigo),
                      _badge("水溫 24.8 ℃", Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

      case 4:
      default:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C1802), Color(0xFF150A00), Color(0xFF3D2605)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
                boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.25), blurRadius: 20)],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.anchor_rounded, color: Color(0xFFFFD700), size: 28),
                          SizedBox(width: 8),
                          Text("TIDE PRO COMMANDER", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
                        ],
                      ),
                      Text("FOUNDER", style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text("創始天尊指揮官", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFFFE57F), letterSpacing: 1.2)),
                  SizedBox(height: 4),
                  Text("編號：CAPT-2026-8888", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5, fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 32),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("老船長幣 (Captain Coins)", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text("120 枚", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAsoReportItem(String title, String time, String tag, int upvotes, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF021B33))),
              const SizedBox(height: 2),
              Text("$time • 由 $tag 通報", style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.thumb_up_alt_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Text("$upvotes", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}