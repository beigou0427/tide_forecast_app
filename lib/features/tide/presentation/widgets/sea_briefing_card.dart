import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🍏 Apple 首席設計工藝：AI 海象極光晨報 (Aurora Intelligence Surface)
class SeaBriefingCard extends ConsumerWidget {
  final TideStationData station;
  final double? distance;

  const SeaBriefingCard({super.key, required this.station, this.distance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = station.aiBriefing;
    final isSpeaking = ref.watch(ttsProvider);
    final score = ai?.safetyScore ?? 80;
    final aura = _getOceanicAura(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        // 🌟 極光深淵動態漸層：深海光學折射
        gradient: LinearGradient(
          colors: aura.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        // 🌟 0.5pt 霓光邊界
        border: Border.all(
          color: aura.accentColor.withValues(alpha: 0.35),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: aura.accentColor.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 測站地名與靈動膠囊語音鍵
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
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded, size: 11, color: AppColors.pelagicCyan),
                          const SizedBox(width: 4),
                          Text(
                            "距您約 ${distance!.toStringAsFixed(1)} km",
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 🌟 Apple 觸覺靈動膠囊語音播報鍵
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact(); // 🍏 注入 Taptic Engine 實體輕觸感
                  ref.read(ttsProvider.notifier).toggleBriefing(station);
                },
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSpeaking 
                        ? AppColors.bioGold 
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSpeaking 
                          ? AppColors.bioGold 
                          : Colors.white.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                    boxShadow: isSpeaking
                        ? [
                            BoxShadow(
                              color: AppColors.bioGold.withValues(alpha: 0.45),
                              blurRadius: 12,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                        color: isSpeaking ? Colors.black87 : AppColors.textPrimary,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSpeaking ? "播報中" : "語音晨報",
                        style: TextStyle(
                          color: isSpeaking ? Colors.black87 : AppColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: AppColors.glassBorder, height: 0.5),
          ),

          // 2. 老船長 AI 專家深度簡報
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: aura.accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.anchor_rounded, color: aura.accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "老船長 AI 專家評估",
                          style: TextStyle(
                            color: aura.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
                          ),
                          child: Text(
                            "安全係數 $score 分",
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 9.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ai?.briefing ?? "正在連線取得即時 AI 專家分析...",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (ai != null && ai.activities.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ai.activities.map((act) => _buildActivityTag(act)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  _OceanicAura _getOceanicAura(int score) {
    if (score < 50) {
      return _OceanicAura(
        gradientColors: const [Color(0xFF33080A), Color(0xFF1E0406), Color(0xFF0A0203)],
        accentColor: AppColors.hazardCoral,
      );
    }
    if (score < 75) {
      return _OceanicAura(
        gradientColors: const [Color(0xFF331D05), Color(0xFF1C0F02), Color(0xFF0A0601)],
        accentColor: const Color(0xFFFF9500),
      );
    }
    return _OceanicAura(
      gradientColors: const [Color(0xFF002B47), Color(0xFF00192B), Color(0xFF030D17)],
      accentColor: AppColors.pelagicCyan,
    );
  }
}

class _OceanicAura {
  final List<Color> gradientColors;
  final Color accentColor;
  _OceanicAura({required this.gradientColors, required this.accentColor});
}