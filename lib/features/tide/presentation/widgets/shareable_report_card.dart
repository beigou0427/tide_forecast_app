import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/tide_model.dart';
import '../../../premium/services/premium_service.dart';

class ShareableReportCard extends ConsumerWidget {
  final GlobalKey boundaryKey;
  final TideStationData station;

  const ShareableReportCard({
    super.key,
    required this.boundaryKey,
    required this.station,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = station.aiBriefing;
    final obs = station.observations.isNotEmpty ? station.observations.last : null;
    final nowStr = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());
    
    // 🌟 讀取 VVIP 會員身分
    final premium = ref.watch(premiumProvider);
    final bool isVvip = premium.isFounder || premium.type == SubscriptionType.yearly;

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isVvip 
              ? const LinearGradient(
                  colors: [Color(0xFF031E3A), Color(0xFF021326), Color(0xFF141908)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isVvip ? null : const Color(0xFF021B33),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: premium.isFounder
                ? const Color(0xFFFFD700)
                : (premium.type == SubscriptionType.yearly 
                    ? const Color(0xFF00E5FF) 
                    : const Color(0xFF00B4D8).withValues(alpha: 0.4)),
            width: isVvip ? 2.0 : 1.5,
          ),
          boxShadow: isVvip
              ? [
                  BoxShadow(
                    color: (premium.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00E5FF)).withValues(alpha: 0.2),
                    blurRadius: 16,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isVvip ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFF00B4D8).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isVvip ? Icons.workspace_premium_rounded : Icons.anchor_rounded, 
                        color: isVvip ? Colors.amberAccent : const Color(0xFF00B4D8), 
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isVvip ? "潮汐表 PRO 旗艦作戰情報" : "潮汐表 PRO 老船長海象情報", // 🌟 抬頭對齊潮汐表品牌
                      style: TextStyle(
                        color: isVvip ? Colors.amberAccent : Colors.white, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 12, 
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  nowStr,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                ),
              ],
            ),

            if (isVvip) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: premium.isFounder 
                      ? Colors.amber.withValues(alpha: 0.15) 
                      : const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: premium.isFounder ? Colors.amber : const Color(0xFF00E5FF),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 12, color: premium.isFounder ? Colors.amber : const Color(0xFF00E5FF)),
                    const SizedBox(width: 4),
                    Text(
                      premium.isFounder ? "👑 創始天尊指揮官 • 專屬鑑測戰報" : "🔱 年度首席領航員 • 專屬特權戰報",
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w900, 
                        color: premium.isFounder ? Colors.amberAccent : const Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.info.stationName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${station.info.attr} • 官方即時直連",
                      style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 11),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (ai?.safetyScore ?? 80) >= 70 ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (ai?.safetyScore ?? 80) >= 70 ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${ai?.safetyScore ?? 80}",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text("安全指針", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ai?.briefing ?? "海象平穩，適合近岸作業與作釣。",
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (obs != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem("浪高", "${obs.waveHeight ?? '--'} m"),
                  _buildMetricItem("風速", "${obs.windSpeed ?? '--'} m/s"),
                  _buildMetricItem("潮高", "${obs.tideHeight ?? '--'} m"),
                  _buildMetricItem("水溫", "${obs.seaTemperature ?? '--'} ℃"),
                ],
              ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("出海作釣、潛水必備決策工具", style: TextStyle(color: Colors.white60, fontSize: 10)),
                    // 🌟 核心對齊：精準引流至 App Store 既有「潮汐表」大詞
                    Text("App Store 搜尋：「潮汐表」", style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVvip ? Colors.amberAccent : Colors.tealAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isVvip ? "COMMANDER VERIFIED" : "官方即時數據",
                    style: const TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}