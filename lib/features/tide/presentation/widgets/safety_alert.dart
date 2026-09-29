import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// Scott Belsky 邊界韌性重塑：海況安全環境感知微光膠囊 (含外海離線自癒黑盒子守護)
class SafetyAlert extends StatelessWidget {
  final Observation current;

  const SafetyAlert({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final double waveH = current.waveHeight ?? 0.0;
    final double waveP = current.wavePeriod ?? 0.0;
    final double windS = current.windSpeed ?? 0.0;
    final double flux = current.waveEnergyFlux ?? (waveH > 0 && waveP > 0 ? (0.49 * waveH * waveH * waveP) : 0.0);
    final bool isOffline = current.waveHeight == null && current.windSpeed == null;

    // 海事流體動能防線：波能通量 >= 3.5 kW/m 或 長週期長湧 (p>=10s & h>=0.7m)
    final bool isRogueWaveRisk = (waveP >= 10.0 && waveH >= 0.7) || flux >= 3.5;
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
      surfaceColor = isLight ? const Color(0xFFFFF1F2) : const Color(0xFF240608);
      alertIcon = Icons.dangerous_rounded;
      if (isRogueWaveRisk) {
        alertTitle = "🚨 致命長湧瘋狗浪預警 · 動能高達 ${flux.toStringAsFixed(1)} kW/m";
        alertDesc = "外海偵測到深層長週期能量湧浪！近岸極易突發無預警蓋礁洗岸瘋狗浪，嚴禁外礁與消波塊作釣！";
      } else {
        alertTitle = "🚨 極端風浪巨浪警戒 · 浪高 ${waveH.toStringAsFixed(1)}m";
        alertDesc = "實測浪高或陣風已達危險警戒上限，走水猛烈且浪拍防波堤，請即刻撤離無防護作業區！";
      }
    } else if (isOffline) {
      // 🌟 Scott Belsky 外海離線黑盒子自癒守護 (杜絕故障挫折感)
      accentColor = AppColors.bioGold;
      surfaceColor = isLight ? Colors.amber.shade50 : const Color(0xFF261D05);
      alertIcon = Icons.shield_rounded;
      alertTitle = "🛡️ 外海離線黑盒子守護 · 本地水文防衛接管";
      alertDesc = "當前測站感測器處於離線週期。本地 30 天水文時間序列金庫與天文調和模型已接管防衛，外礁作業請維持最高警戒。";
    } else if (isCaution) {
      accentColor = const Color(0xFFFF9500);
      surfaceColor = isLight ? const Color(0xFFFFFBEB) : const Color(0xFF241403);
      alertIcon = Icons.warning_amber_rounded;
      alertTitle = "海況稍強 · 注意防護";
      alertDesc = "風力或浪高稍有推升，潮位變換走水急促，作釣請務必全程穿著合格救生衣與防滑釘鞋。";
    } else {
      accentColor = isLight ? AppColors.marineBlue : AppColors.pelagicCyan;
      surfaceColor = isLight ? const Color(0xFFF0F9FF) : const Color(0xFF041C0F);
      alertIcon = Icons.verified_user_rounded;
      alertTitle = "海象平穩 · 條件優良";
      alertDesc = "波高週期平緩且風力適中，全島多數近岸作業條件優良，請維持基本防護。";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: isLight ? 0.95 : 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: isLight ? 0.35 : 0.4),
          width: isLight ? 0.8 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isLight ? 0.08 : 0.12),
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
                    color: isLight && !isHighDanger ? const Color(0xFF023E8A) : accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alertDesc,
                  style: TextStyle(
                    color: isLight ? Colors.blueGrey.shade800 : AppColors.textSecondary,
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
