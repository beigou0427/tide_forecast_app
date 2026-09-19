import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/tide_model.dart';

class ShareableReportCard extends StatelessWidget {
  final GlobalKey boundaryKey;
  final TideStationData station;

  const ShareableReportCard({
    super.key,
    required this.boundaryKey,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    final ai = station.aiBriefing;
    final obs = station.observations.isNotEmpty ? station.observations.last : null;
    final nowStr = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF021B33),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.4), width: 1.5),
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
                        color: const Color(0xFF00B4D8).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.anchor_rounded, color: Color(0xFF00B4D8), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "TIDE PRO 老船長海象情報",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                    ),
                  ],
                ),
                Text(
                  nowStr,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.info.stationName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      station.info.attr,
                      style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 12),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("出海作釣、潛水必備決策工具", style: TextStyle(color: Colors.white60, fontSize: 10)),
                    Text("App Store 搜尋: Tide Pro", style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text("官方即時數據", style: TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold)),
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

