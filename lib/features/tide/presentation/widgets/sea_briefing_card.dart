import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/share_util.dart';
import '../../data/tide_model.dart';

enum OperationalTier { halt, advisory, operational }

/// 🌟 經海事流體力學與 TQM 單一真相來源重塑之決策推論矩陣
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

  Color getDecisionColor() {
    switch (tier) {
      case OperationalTier.halt:
        return AppColors.hazardCoral;
      case OperationalTier.advisory:
        return const Color(0xFFFF9500);
      case OperationalTier.operational:
        return const Color(0xFF10B981);
    }
  }

  factory MaritimeDecision.evaluate({
    required int safetyScore,
    required double waveHeight,
    required double wavePeriod,
    required double windSpeed,
    double waveEnergyFlux = 0.0,
    double? airPressure,
  }) {
    // 1. 致命長湧瘋狗浪 (波能通量臨界值或深層長週期)
    final bool isDeepSwellRogue = (wavePeriod >= 10.0 && waveHeight >= 0.7) || waveEnergyFlux >= 3.5;
    
    // 2. 氣壓驟降鋒面暴潮共振 (低壓 + 長湧相長干涉)
    final bool isBarometricSwellCombo = airPressure != null && airPressure < 1005.0 && wavePeriod >= 8.5;

    // 3. 巨浪強風作業死線
    final bool isExtremeSea = waveHeight >= 2.2 || windSpeed >= 11.0;

    final bool isHalt = safetyScore < 40 || 
                        isExtremeSea || 
                        isDeepSwellRogue || 
                        isBarometricSwellCombo;

    final bool isAdvisory = !isHalt && 
                           (safetyScore < 70 || waveHeight > 1.2 || windSpeed > 7.0 || (airPressure != null && airPressure < 1010.0));

    if (isHalt) {
      String haltTitle = "極端危險 · 嚴禁外礁登礁";
      String haltAdvice = "外海偵測到致命長週期長湧或巨浪！具極端蓋礁瘋狗浪風險，嚴禁無防護水上作業！";
      
      // 🌟 核心修復：airPressure 已自動晉升為非空，直接使用 . 呼叫
      if (isBarometricSwellCombo) {
        haltTitle = "低壓暴潮警示 · 嚴禁登礁";
        haltAdvice = "大氣氣壓降至 ${airPressure.toStringAsFixed(1)}hPa 疊加外海長湧，近岸洗岸巨浪動能劇烈，請即刻撤離！";
      } else if (isDeepSwellRogue) {
        haltTitle = "長湧瘋狗浪警戒 · 嚴禁登礁";
        haltAdvice = "外海深層長湧波能達 ${waveEnergyFlux.toStringAsFixed(1)} kW/m！即便岸際風平浪靜亦具突發蓋礁危險，禁止登礁！";
      }

      return MaritimeDecision(
        tier: OperationalTier.halt,
        badgeText: "HALT 警戒",
        title: haltTitle,
        actionAdvice: haltAdvice,
        icon: Icons.dangerous_rounded,
      );
    } else if (isAdvisory) {
      return const MaritimeDecision(
        tier: OperationalTier.advisory,
        badgeText: "ADVISORY 戒備",
        title: "水文戒備 · 需穿著合格裝備",
        actionAdvice: "潮位變換急促或風浪稍強，建議避開迎風迎浪面，僅限具備背風條件之安全標點。",
        icon: Icons.warning_amber_rounded,
      );
    } else {
      return const MaritimeDecision(
        tier: OperationalTier.operational,
        badgeText: "OPERATIONAL 許可",
        title: "常態水文許可 · 仍須安全戒備",
        actionAdvice: "實測波高與風力處於常態作業水準。自然水域變幻莫測，請全程著合格救生衣與釘鞋。",
        icon: Icons.check_circle_rounded,
      );
    }
  }
}

/// 🌟 經海事流體力學與客觀感測器陣列重塑之海象簡報卡
class SeaBriefingCard extends ConsumerStatefulWidget {
  final TideStationData station;
  final double? distance;

  const SeaBriefingCard({super.key, required this.station, this.distance});

  @override
  ConsumerState<SeaBriefingCard> createState() => _SeaBriefingCardState();
}

class _SeaBriefingCardState extends ConsumerState<SeaBriefingCard> {
  final GlobalKey _cardBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;

    final ai = widget.station.aiBriefing;
    final obs = widget.station.observations.isNotEmpty ? widget.station.observations.last : null;
    final isSpeaking = ref.watch(ttsProvider);

    final double realWaveH = obs?.waveHeight ?? 0.0;
    final double realWaveP = obs?.wavePeriod ?? 0.0;
    final double realWindS = obs?.windSpeed ?? 0.0;
    final double flux = obs?.waveEnergyFlux ?? (realWaveH > 0 && realWaveP > 0 ? (0.49 * realWaveH * realWaveH * realWaveP) : 0.0);
    final String tideStatus = obs?.tideLevel ?? "平穩";

    final decision = MaritimeDecision.evaluate(
      safetyScore: ai?.safetyScore ?? 80,
      waveHeight: realWaveH,
      wavePeriod: realWaveP,
      windSpeed: realWindS,
      waveEnergyFlux: flux,
      airPressure: obs?.airPressure,
    );
    
    final String stationDisplayName = widget.station.info.stationName.replaceAll(RegExp(r'[\(（].*?[\)）]'), '').trim();

    final bool hasWaveSensor = obs?.waveHeight != null;
    final bool hasTideSensor = obs?.tideHeight != null;

    final String rightMetricLabel;
    final String rightMetricValue;
    final IconData rightMetricIcon;

    if (hasWaveSensor) {
      rightMetricLabel = "即時波高";
      rightMetricValue = "${obs!.waveHeight!.toStringAsFixed(1)} m";
      rightMetricIcon = Icons.surfing_rounded;
    } else if (hasTideSensor) {
      rightMetricLabel = "即時潮位";
      rightMetricValue = "${obs!.tideHeight!.toStringAsFixed(2)} m";
      rightMetricIcon = Icons.water_drop_rounded;
    } else {
      rightMetricLabel = "實測水文";
      rightMetricValue = "--";
      rightMetricIcon = Icons.sensors_off_rounded;
    }

    final BoxDecoration cardDecoration;
    final Color textColor;
    final Color subTextColor;
    final Color dividerColor;

    if (isEInk) {
      cardDecoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 2.0),
      );
      textColor = Colors.black;
      subTextColor = Colors.black87;
      dividerColor = Colors.black26;
    } else {
      cardDecoration = BoxDecoration(
        gradient: LinearGradient(
          colors: decision.tier == OperationalTier.halt
              ? const [Color(0xFF6B1115), Color(0xFF38070A)]
              : const [Color(0xFF0052A3), Color(0xFF003870)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (decision.tier == OperationalTier.halt ? const Color(0xFF6B1115) : const Color(0xFF003870)).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );
      textColor = Colors.white;
      subTextColor = Colors.white.withValues(alpha: 0.75);
      dividerColor = Colors.white.withValues(alpha: 0.2);
    }

    return RepaintBoundary(
      key: _cardBoundaryKey,
      child: Container(
        width: double.infinity,
        decoration: cardDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text("📍", style: TextStyle(fontSize: 14, color: textColor)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.distance != null 
                              ? "距離最近的觀測站 (${widget.distance!.toStringAsFixed(1)}km)"
                              : "距離最近的觀測站",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ShareUtil.captureAndShare(
                          _cardBoundaryKey,
                          stationName: widget.station.info.stationName,
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isEInk ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.ios_share_rounded,
                          color: isEInk ? Colors.black : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(ttsProvider.notifier).toggleBriefing(widget.station);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isEInk ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSpeaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                          color: isEInk ? Colors.black : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stationDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEInk 
                        ? Colors.black 
                        : decision.getDecisionColor().withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEInk ? Colors.black : decision.getDecisionColor(),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        decision.icon, 
                        size: 13, 
                        color: isEInk ? Colors.white : decision.getDecisionColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        decision.badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Divider(
              height: 1, 
              thickness: 0.8, 
              color: dividerColor,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.waves_rounded, color: subTextColor, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        "目前潮況",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tideStatus,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 42,
                  width: 0.8,
                  color: dividerColor,
                ),

                Expanded(
                  child: Column(
                    children: [
                      Icon(rightMetricIcon, color: subTextColor, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        rightMetricLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rightMetricValue,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isEInk 
                    ? Colors.black.withValues(alpha: 0.05) 
                    : Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEInk ? Colors.black12 : Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    decision.tier == OperationalTier.halt ? Icons.warning_rounded : Icons.anchor_rounded, 
                    color: decision.tier == OperationalTier.halt ? AppColors.hazardCoral : const Color(0xFFFBBF24),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "老船長快報",
                              style: TextStyle(
                                color: decision.tier == OperationalTier.halt ? AppColors.hazardCoral : const Color(0xFFFBBF24),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (decision.tier == OperationalTier.halt) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.hazardCoral.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  decision.title,
                                  style: const TextStyle(color: AppColors.hazardCoral, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          decision.tier == OperationalTier.halt 
                              ? decision.actionAdvice 
                              : (ai?.briefing ?? decision.actionAdvice),
                          style: TextStyle(
                            color: isEInk ? Colors.black87 : Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
