import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tts_service.dart';
import '../../data/tide_model.dart';

class SeaBriefingCard extends ConsumerWidget {
  final TideStationData station;
  final double? distance;

  const SeaBriefingCard({super.key, required this.station, this.distance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = station.aiBriefing;
    final isSpeaking = ref.watch(ttsProvider);

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
            color: _getThemeColors(ai?.safetyScore ?? 80).first.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 頂部站點標題與語音晨報按鈕
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
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                    ),
                ],
              ),

              // 🔊 老船長語音開關
              InkWell(
                onTap: () => ref.read(ttsProvider.notifier).toggleBriefing(station),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSpeaking ? Colors.amberAccent : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSpeaking ? Colors.amber : Colors.white.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                    boxShadow: isSpeaking
                        ? [BoxShadow(color: Colors.amberAccent.withValues(alpha: 0.4), blurRadius: 8)]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeaking ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        color: isSpeaking ? Colors.black87 : Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSpeaking ? "播報中" : "語音晨報",
                        style: TextStyle(
                          color: isSpeaking ? Colors.black87 : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14.0),
            child: Divider(color: Colors.white24, height: 1),
          ),

          // 2. AI 核心簡報
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.anchor_rounded, color: Colors.amberAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "老船長 AI 專家簡報",
                          style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text("安全係數 ${ai?.safetyScore ?? 80}分", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ai?.briefing ?? "正在連線取得即時 AI 專家分析...",
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. 建議活動標籤
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

  List<Color> _getThemeColors(int score) {
    if (score < 50) return [const Color(0xFFD00000), const Color(0xFF9D0208)];
    if (score < 75) return [const Color(0xFFF3722C), const Color(0xFFF9433D)];
    return [const Color(0xFF0077B6), const Color(0xFF023E8A)];
  }

  Widget _buildActivityTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
