import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    
    final premium = ref.watch(premiumProvider);
    final bool isVvip = premium.isFounder || premium.type == SubscriptionType.yearly;

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
            // 1. 頂部抬頭與時間 (彈性防溢出)
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

            if (isVvip) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
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
                    Icon(Icons.shield_rounded, size: 11, color: premium.isFounder ? Colors.amber : const Color(0xFF00E5FF)),
                    const SizedBox(width: 4),
                    Text(
                      premium.isFounder ? "👑 創始天尊指揮官 • 專屬戰報" : "🔱 年度首席領航員 • 專屬戰報",
                      style: TextStyle(
                        fontSize: 9.5, 
                        fontWeight: FontWeight.w900, 
                        color: premium.isFounder ? Colors.amberAccent : const Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 2. 測站地名與安全分數膠囊
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
                        "${station.info.attr} • 官方即時直連",
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

            // 3. AI 專家評估
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
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ai?.briefing ?? "海象平穩，適合近岸作業與作釣。",
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
                  _buildMetricItem("潮高", "${obs.tideHeight != null ? obs.tideHeight!.toStringAsFixed(1) : '--'} m"),
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
                        "App Store 搜尋：「潮汐表」", 
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
                    color: isVvip ? Colors.amberAccent : Colors.tealAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isVvip ? "COMMANDER VERIFIED" : "官方即時數據",
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
