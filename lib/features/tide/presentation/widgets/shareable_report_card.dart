import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/tide_model.dart';
import '../../../premium/services/premium_service.dart';

/// Jonah Berger 瘋傳行銷重塑：自帶「社交貨幣」與海事榮譽認證之作戰戰報卡
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
    
    final premium = ref.watch(premiumProvider);
    final bool isVvip = premium.isFounder || premium.type == SubscriptionType.yearly;

    // 提取物理指標以計算社交貨幣認證標記 (Jonah Berger Social Currency Engine)
    final double waveH = obs?.waveHeight ?? 0.0;
    final double waveP = obs?.wavePeriod ?? 0.0;
    final double flux = obs?.waveEnergyFlux ?? 0.0;

    String certificationTag;
    Color certificationColor;
    IconData certificationIcon;

    if (waveP >= 10.0 && waveH >= 0.7) {
      certificationTag = "🚨 外礁瘋狗浪特級防區 · 極限海象挑戰";
      certificationColor = const Color(0xFFF43F5E);
      certificationIcon = Icons.dangerous_rounded;
    } else if (flux >= 3.0 || waveH >= 2.0) {
      certificationTag = "⚡ 高波能衝擊防區 (${flux > 0 ? '$flux kW/m' : '${waveH}m 巨浪'})";
      certificationColor = const Color(0xFFFF9500);
      certificationIcon = Icons.bolt_rounded;
    } else {
      certificationTag = "🔱 老船長光纖直連 · 官方即時水文認證";
      certificationColor = const Color(0xFF00E5FF);
      certificationIcon = Icons.verified_rounded;
    }

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isVvip 
              ? const LinearGradient(
                  colors: [Color(0xFF031E3A), Color(0xFF021326), Color(0xFF141908)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF0B1B2B), Color(0xFF030D17)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: premium.isFounder
                ? const Color(0xFFFFD700)
                : (premium.type == SubscriptionType.yearly 
                    ? const Color(0xFF00E5FF) 
                    : const Color(0xFF00B4D8).withValues(alpha: 0.45)),
            width: isVvip ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (premium.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8)).withValues(alpha: 0.2),
              blurRadius: 18,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 頂部抬頭與時間
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
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
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isVvip ? "潮汐表 PRO 旗艦作戰情報" : "潮汐表 PRO 老船長情報",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isVvip ? Colors.amberAccent : Colors.white, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 11.5, 
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  nowStr,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9.5),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🌟 Jonah Berger 社交貨幣核心：海象榮譽認證鋼印 (Social Currency Seal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
              decoration: BoxDecoration(
                color: certificationColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: certificationColor.withValues(alpha: 0.45),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(certificationIcon, size: 12, color: certificationColor),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      certificationTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5, 
                        fontWeight: FontWeight.w900, 
                        color: certificationColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. 測站地名與安全指針膠囊
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.info.stationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${station.info.attr} • 官方直連鑑測",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (ai?.safetyScore ?? 80) >= 70 ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (ai?.safetyScore ?? 80) >= 70 ? Colors.greenAccent : Colors.redAccent,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${ai?.safetyScore ?? 80}",
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                      Text("安全指針", style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 8.5)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 3. AI 專家海況簡評
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.anchor_rounded, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ai?.briefing ?? "海況平穩，走水順暢，全島多數近岸標點作業適宜。",
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. 水文 4 大指標 (均分佈局)
            if (obs != null)
              Row(
                children: [
                  _buildMetricItem("浪高", "${obs.waveHeight != null ? obs.waveHeight!.toStringAsFixed(1) : '--'} m"),
                  _buildMetricItem("風速", "${obs.windSpeed != null ? obs.windSpeed!.toStringAsFixed(1) : '--'} m/s"),
                  _buildMetricItem("波能通量", "${obs.waveEnergyFlux != null ? obs.waveEnergyFlux!.toStringAsFixed(1) : '--'} kW"),
                  _buildMetricItem("水溫", "${obs.seaTemperature != null ? obs.seaTemperature!.toStringAsFixed(1) : '--'} ℃"),
                ],
              ),

            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 10),

            // 5. 底部品牌與認證印章
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "出海作釣、潛水必備決策工具", 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white60, fontSize: 9.5),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "App Store 搜尋：「潮汐表 Pro」", 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isVvip ? Colors.amberAccent : const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isVvip ? "COMMANDER VERIFIED" : "官方直連鑑測",
                    style: const TextStyle(color: Colors.black87, fontSize: 8.5, fontWeight: FontWeight.w900),
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
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value, 
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
