import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// Apple 首席設計工藝：海況安全環境感知微光膠囊 (Ambient Safety Telemetry)
class SafetyAlert extends StatelessWidget {
  final Observation current;

  const SafetyAlert({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final double waveH = current.waveHeight ?? 0.0;
    final double waveP = current.wavePeriod ?? 0.0;
    final double windS = current.windSpeed ?? 0.0;
    final bool isOffline = current.waveHeight == null && current.windSpeed == null;

    // 核心生命安全防線：長週期長湧瘋狗浪與惡劣海況判定
    final bool isRogueWaveRisk = waveP >= 10.0 && waveH >= 0.7;
    final bool isExtremeSea = waveH >= 2.5 || windS >= 11.0;
    final bool isHighDanger = isRogueWaveRisk || isExtremeSea;
    final bool isCaution = waveH > 1.3 || windS > 7.0;

    Color accentColor;
    Color surfaceColor;
    IconData alertIcon;
    String alertTitle;
    String alertDesc;

    if (isHighDanger) {
      accentColor = AppColors.hazardCoral;
      surfaceColor = const Color(0xFF240608);
      alertIcon = Icons.dangerous_rounded;
      if (isRogueWaveRisk) {
        alertTitle = "🚨 致命長湧瘋狗浪預警 (外海長週期 ${waveP.toStringAsFixed(1)}s)";
        alertDesc = "外海偵測到深層長週期能量湧浪！近岸極易突發無預警蓋礁洗岸瘋狗浪，嚴禁外礁與消波塊作釣！";
      } else {
        alertTitle = "🚨 極端風浪巨浪警戒 (浪高 ${waveH.toStringAsFixed(1)}m)";
        alertDesc = "實測浪高或陣風已達危險警戒上限，走水猛烈且浪拍防波堤，請即刻撤離無防護作業區！";
      }
    } else if (isOffline) {
      accentColor = AppColors.bioGold;
      surfaceColor = const Color(0xFF261D05);
      alertIcon = Icons.sensors_off_rounded;
      alertTitle = "⚠️ 即時感測器維護中 · 現場水文不明";
      alertDesc = "當前測站感測器無即時回傳數據，現場風浪未明，請勿盲目冒險登礁，務必先於安全港區觀察。";
    } else if (isCaution) {
      accentColor = const Color(0xFFFF9500);
      surfaceColor = const Color(0xFF241403);
      alertIcon = Icons.warning_amber_rounded;
      alertTitle = "海況稍強 · 注意防護";
      alertDesc = "風力或浪高稍有推升，潮位變換走水急促，作釣請務必全程穿著合格救生衣與防滑釘鞋。";
    } else {
      accentColor = const Color(0xFF30D158);
      surfaceColor = const Color(0xFF041C0F);
      alertIcon = Icons.check_circle_outline_rounded;
      alertTitle = "海況平穩 · 條件優良";
      alertDesc = "波高週期平緩且風力適中，全島多數近岸作業條件優良，請維持基本防護。";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Icon(
              alertIcon,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertTitle,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alertDesc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
