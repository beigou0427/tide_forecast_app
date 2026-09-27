import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🍏 Don Norman × Dieter Rams 哲學重塑：大氣海洋智慧晨報 (Atmospheric Oceanic Surface)
class SeaBriefingCard extends ConsumerWidget {
  final TideStationData station;
  final double? distance;

  const SeaBriefingCard({super.key, required this.station, this.distance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = station.aiBriefing;
    final isSpeaking = ref.watch(ttsProvider);
    final score = ai?.safetyScore ?? 80;
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final aura = _getAtmosphericAura(score, isLight);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        // 🌟 Don Norman 大氣海霧微光圈：告別混濁發焦的厚重漸層
        gradient: LinearGradient(
          colors: aura.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: aura.borderColor,
          width: 0.5,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: aura.accentColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
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
                      style: TextStyle(
                        color: isLight ? AppColors.classicText : AppColors.textPrimary,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.near_me_rounded, 
                            size: 11, 
                            color: isLight ? AppColors.marineBlue : AppColors.pelagicCyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "距您約 ${distance!.toStringAsFixed(1)} km",
                            style: TextStyle(
                              color: isLight ? Colors.grey.shade600 : AppColors.textSecondary, 
                              fontSize: 11, 
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 🌟 靈動語音播報膠囊 (帶有 Taptic 輕觸反饋)
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(ttsProvider.notifier).toggleBriefing(station);
                },
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSpeaking 
                        ? (isLight ? AppColors.marineBlue : AppColors.bioGold) 
                        : (isLight ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSpeaking 
                          ? Colors.transparent 
                          : (isLight ? AppColors.marineBlue.withValues(alpha: 0.25) : AppColors.glassBorder),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                        color: isSpeaking 
                            ? (isLight ? Colors.white : AppColors.abyssBlack) 
                            : (isLight ? AppColors.marineBlue : AppColors.textPrimary),
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSpeaking ? "播報中" : "語音晨報",
                        style: TextStyle(
                          color: isSpeaking 
                              ? (isLight ? Colors.white : AppColors.abyssBlack) 
                              : (isLight ? AppColors.marineBlue : AppColors.textPrimary),
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

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Divider(
              color: isLight ? Colors.grey.shade200 : AppColors.glassBorder, 
              height: 0.5,
            ),
          ),

          // 2. 老船長 AI 專家深度簡報
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: aura.accentColor.withValues(alpha: isLight ? 0.1 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.anchor_rounded, color: aura.accentColor, size: 18),
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
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isLight ? Colors.grey.shade300 : AppColors.glassBorder, 
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            "安全係數 $score 分",
                            style: TextStyle(
                              color: isLight ? AppColors.classicText : AppColors.textPrimary, 
                              fontSize: 9.5, 
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ai?.briefing ?? "正在連線取得即時 AI 專家分析...",
                      style: TextStyle(
                        color: isLight ? const Color(0xFF334155) : AppColors.textSecondary,
                        fontSize: 14,
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ai.activities.map((act) => _buildActivityTag(act, isLight)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTag(String label, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? Colors.grey.shade300 : AppColors.glassBorder, 
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isLight ? const Color(0xFF475569) : AppColors.textSecondary, 
          fontSize: 11, 
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _AtmosphericAura _getAtmosphericAura(int score, bool isLight) {
    if (isLight) {
      if (score < 50) {
        return _AtmosphericAura(
          gradientColors: const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
          borderColor: const Color(0xFFFECDD3),
          accentColor: AppColors.hazardCoral,
        );
      }
      return _AtmosphericAura(
        gradientColors: const [Color(0xFFF0F7FD), Color(0xFFE2EFF9)],
        borderColor: const Color(0xFFBAE6FD),
        accentColor: AppColors.marineBlue,
      );
    }

    // 🌟 深淵模式：冷冽大氣薄霧
    if (score < 50) {
      return _AtmosphericAura(
        gradientColors: const [Color(0xFF260D14), Color(0xFF14060A)],
        borderColor: AppColors.hazardCoral.withValues(alpha: 0.3),
        accentColor: AppColors.hazardCoral,
      );
    }
    return _AtmosphericAura(
      gradientColors: const [Color(0xFF0E1A2B), Color(0xFF09121E)],
      borderColor: AppColors.glassBorder,
      accentColor: AppColors.pelagicCyan,
    );
  }
}

class _AtmosphericAura {
  final List<Color> gradientColors;
  final Color borderColor;
  final Color accentColor;
  _AtmosphericAura({required this.gradientColors, required this.borderColor, required this.accentColor});
}