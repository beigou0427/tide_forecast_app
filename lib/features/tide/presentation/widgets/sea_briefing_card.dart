import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

enum OperationalTier { halt, advisory, operational }

class MaritimeDecision {
  final OperationalTier tier;
  final String badgeText;
  final String title;
  final String actionAdvice;
  final IconData icon;

  const MaritimeDecision({
    required this.tier,
    required this.badgeText,
    required this.title,
    required this.actionAdvice,
    required this.icon,
  });

  Color getDecisionColor(bool isLight) {
    switch (tier) {
      case OperationalTier.halt:
        return AppColors.hazardCoral;
      case OperationalTier.advisory:
        return const Color(0xFFFF9500);
      case OperationalTier.operational:
        return isLight ? AppColors.marineBlue : AppColors.pelagicCyan;
    }
  }

  factory MaritimeDecision.evaluate({
    required int safetyScore,
    required double waveHeight,
    required double wavePeriod,
    required double windSpeed,
  }) {
    final bool isHalt = safetyScore < 40 || 
                        waveHeight >= 2.2 || 
                        (wavePeriod >= 10.0 && waveHeight >= 0.7);

    final bool isAdvisory = !isHalt && 
                           (safetyScore < 70 || waveHeight > 1.2 || windSpeed > 7.0);

    if (isHalt) {
      return const MaritimeDecision(
        tier: OperationalTier.halt,
        badgeText: "HALT",
        title: "極端危險 · 嚴禁外礁登礁",
        actionAdvice: "外海偵測到致命長週期長湧或巨浪！具極端蓋礁瘋狗浪風險，嚴禁無防護水上作業！",
        icon: Icons.dangerous_rounded,
      );
    } else if (isAdvisory) {
      return const MaritimeDecision(
        tier: OperationalTier.advisory,
        badgeText: "ADVISORY",
        title: "水文戒備 · 需穿著合格裝備",
        actionAdvice: "潮位變換急促或風浪稍強，建議避開迎風迎浪面，僅限具備背風條件之安全標點。",
        icon: Icons.warning_amber_rounded,
      );
    } else {
      return const MaritimeDecision(
        tier: OperationalTier.operational,
        badgeText: "OPERATIONAL",
        title: "常態水文許可 · 仍須安全戒備",
        actionAdvice: "實測波高與風力處於常態作業水準。自然水域變幻莫測，請全程著合格救生衣與釘鞋。",
        icon: Icons.shield_rounded,
      );
    }
  }
}

/// 🌟 經海事嚴謹標準重塑之老船長水文決策簡報卡
/// 徹底拔除一切保險業配雜質，專注呈現 gemini-flash-lite-latest 即時海況推論與航行建議
class SeaBriefingCard extends ConsumerStatefulWidget {
  final TideStationData station;
  final double? distance;

  const SeaBriefingCard({super.key, required this.station, this.distance});

  @override
  ConsumerState<SeaBriefingCard> createState() => _SeaBriefingCardState();
}

class _SeaBriefingCardState extends ConsumerState<SeaBriefingCard> {
  // 🌟 手勢防抖閥門（防止甲板晃動下連點擊穿語音佇列）
  int _lastClickEpoch = 0;

  void _handleSpeechToggle() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastClickEpoch < 600) {
      return;
    }
    _lastClickEpoch = now;
    HapticFeedback.lightImpact();
    ref.read(ttsProvider.notifier).toggleBriefing(widget.station);
  }

  @override
  Widget build(BuildContext context) {
    final ai = widget.station.aiBriefing;
    final isSpeaking = ref.watch(ttsProvider);
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    final obs = widget.station.observations.isNotEmpty ? widget.station.observations.last : null;
    final double waveH = obs?.waveHeight ?? 0.0;
    final double waveP = obs?.wavePeriod ?? 0.0;
    final double windS = obs?.windSpeed ?? 0.0;
    final int score = ai?.safetyScore ?? 80;

    final decision = MaritimeDecision.evaluate(
      safetyScore: score,
      waveHeight: waveH,
      wavePeriod: waveP,
      windSpeed: windS,
    );
    final Color decisionColor = decision.getDecisionColor(isLight);

    final String cleanStationName = widget.station.info.stationName.replaceAll(RegExp(r'[\(（].*?[\)）]'), '').trim();

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
                    if (widget.distance != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        "距您約 ${widget.distance!.toStringAsFixed(1)} km · 實測水文即時監控",
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

              InkWell(
                onTap: _handleSpeechToggle,
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
                  child: Icon(decision.icon, color: decisionColor, size: 20),
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
                              decision.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: decisionColor,
                                fontSize: 14.5,
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
                              decision.badgeText,
                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        decision.actionAdvice,
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

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.anchor_rounded, color: AppColors.bioGold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ai?.briefing ?? "正在透過氣象署感測陣列與 gemini-flash-lite-latest 進行即時水文推論...",
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