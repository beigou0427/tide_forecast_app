import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/tide_model.dart';

class SeaBriefingCard extends StatelessWidget {
  final TideStationData station;
  final double? distance;

  const SeaBriefingCard({super.key, required this.station, this.distance});

  @override
  Widget build(BuildContext context) {
    // 取得 AI 推理數據，若無則顯示預設
    final ai = station.aiBriefing;
    final current = station.observations.isNotEmpty ? station.observations.last : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getThemeColors(ai?.safetyScore ?? 80),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getThemeColors(ai?.safetyScore ?? 80).first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 頂部狀態列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📍 ${station.info.stationName}",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (distance != null)
                    Text(
                      "距離您約 ${distance!.toStringAsFixed(1)} km",
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                    ),
                ],
              ),
              // 安全分數圓環
              _buildSafetyBadge(ai?.safetyScore ?? 0),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Colors.white24, height: 1),
          ),

          // 2. 🌟 老船長 AI 簡報文字
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.anchor_rounded, color: Colors.amberAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "老船長 AI 專家簡報",
                      style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ai?.briefing ?? "正在連結衛星獲取 AI 專家分析...",
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. 推薦活動標籤
          if (ai != null && ai.activities.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ai.activities.map((act) => _buildActivityTag(act)).toList(),
            ),
        ],
      ),
    );
  }

  // 根據安全分數切換顏色 (危險時變紅)
  List<Color> _getThemeColors(int score) {
    if (score < 50) return [const Color(0xFFD00000), const Color(0xFF9D0208)]; // 警告紅
    if (score < 75) return [const Color(0xFFF3722C), const Color(0xFFF9433D)]; // 注意橘
    return [const Color(0xFF0077B6), const Color(0xFF023E8A)]; // 安全藍
  }

  Widget _buildSafetyBadge(int score) {
    return Column(
      children: [
        Text(
          "$score",
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          "安全指數",
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActivityTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
