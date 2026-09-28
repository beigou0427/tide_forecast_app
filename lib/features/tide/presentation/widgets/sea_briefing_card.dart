import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// Don Norman 認知防錯與海事工程重塑：客觀水文作業許可階梯 (Operational Limits)
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

    final obs = station.observations.isNotEmpty ? station.observations.last : null;
    final double waveH = obs?.waveHeight ?? 0.0;
    final double waveP = obs?.wavePeriod ?? 0.0;
    final double windS = obs?.windSpeed ?? 0.0;

    // 海事航空級客觀作業限制判定（杜絕綠色 GO 誘發認知懈怠）
    final bool isHalt = score < 40 || waveH >= 2.2 || (waveP >= 10.0 && waveH >= 0.7);
    final bool isAdvisory = !isHalt && (score < 70 || waveH > 1.2 || windS > 7.0);

    Color decisionColor;
    String decisionBadge;
    String decisionTitle;
    String decisionAction;
    IconData decisionIcon;

    if (isHalt) {
      decisionColor = AppColors.hazardCoral;
      decisionBadge = "HALT";
      decisionTitle = "極端危險 · 嚴禁外礁登礁";
      decisionAction = "外海偵測到致命長週期長湧或巨浪！具極端蓋礁瘋狗浪風險，嚴禁無防護水上作業！";
      decisionIcon = Icons.dangerous_rounded;
    } else if (isAdvisory) {
      decisionColor = const Color(0xFFFF9500);
      decisionBadge = "ADVISORY";
      decisionTitle = "水文戒備 · 需穿著合格裝備";
      decisionAction = "潮位變換急促或風浪稍強，建議避開迎風迎浪面，僅限具備避風條件之安全標點。";
      decisionIcon = Icons.warning_amber_rounded;
    } else {
      // 航空級專業冷靜藍（取代絕對綠色，保持警惕心智模型）
      decisionColor = isLight ? AppColors.marineBlue : AppColors.pelagicCyan;
      decisionBadge = "OPERATIONAL";
      decisionTitle = "常態水文許可 · 仍須安全戒備";
      decisionAction = "實測波高與風力處於常態作業水準。自然水域變幻莫測，請全程著合格救生衣與釘鞋。";
      decisionIcon = Icons.shield_rounded;
    }

    final String cleanStationName = station.info.stationName.replaceAll(RegExp(r'\(.*?\)'), '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.abyssCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? Colors.grey.shade200 : AppColors.glassBorder,
          width: isLight ? 1.0 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: decisionColor.withValues(alpha: isLight ? 0.08 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 測站地名與語音按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanStationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLight ? AppColors.classicText : AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        "距您約 ${distance!.toStringAsFixed(1)} km · 實測水文即時監控",
                        style: TextStyle(
                          color: isLight ? Colors.grey.shade600 : AppColors.textTertiary, 
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 語音晨報按鈕
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(ttsProvider.notifier).toggleBriefing(station);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: isSpeaking 
                        ? decisionColor 
                        : (isLight ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSpeaking ? Colors.transparent : (isLight ? Colors.grey.shade300 : AppColors.glassBorder),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                        color: isSpeaking ? Colors.white : (isLight ? const Color(0xFF0077B6) : AppColors.pelagicCyan),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSpeaking ? "播報中" : "語音晨報",
                        style: TextStyle(
                          color: isSpeaking ? Colors.white : (isLight ? const Color(0xFF0077B6) : AppColors.textPrimary),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. 🌟 Don Norman 海事級客觀作業許可看板（杜絕虛假安全感）
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: decisionColor.withValues(alpha: isLight ? 0.08 : 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: decisionColor.withValues(alpha: isLight ? 0.3 : 0.4),
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: decisionColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(decisionIcon, color: decisionColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              decisionTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: decisionColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: decisionColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              decisionBadge,
                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        decisionAction,
                        style: TextStyle(
                          color: isLight ? Colors.blueGrey.shade800 : AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. 老船長 AI 專家深度筆記
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.anchor_rounded, color: AppColors.bioGold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ai?.briefing ?? "正在透過氣象署即時感測陣列與 AI 推論出海建議...",
                  style: TextStyle(
                    color: isLight ? Colors.blueGrey.shade900 : AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (ai != null && ai.activities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ai.activities.map((act) => _buildActivityTag(act, isLight)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTag(String label, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: isLight ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLight ? Colors.grey.shade300 : AppColors.glassBorder, 
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isLight ? Colors.blueGrey.shade700 : AppColors.textSecondary, 
          fontSize: 10.5, 
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
