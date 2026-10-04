import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🌟 Alex Karp (Palantir CEO) 國防級多維海事遙測本體論安全雷達
/// 融合流體力學波能通量、大氣反向水銀柱暴潮效應 (IBE) 與長湧干涉預警 (零 Warning 純淨版)
class SafetyAlert extends StatelessWidget {
  final Observation current;

  const SafetyAlert({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    
    final double waveH = current.waveHeight ?? 0.0;
    final double waveP = current.wavePeriod ?? 0.0;
    final double windS = current.windSpeed ?? 0.0;
    final double? pressure = current.airPressure;
    final double flux = current.waveEnergyFlux ?? (waveH > 0 && waveP > 0 ? (0.49 * waveH * waveH * waveP) : 0.0);
    final bool isOffline = current.waveHeight == null && current.windSpeed == null;

    // 🌟 Palantir 國防遙測 1：大氣反向水銀柱效應 (Inverted Barometer Effect, IBE)
    // 基準海平面氣壓 1013.25 hPa，每下降 1 hPa，海平面吸升抬高 0.01 公尺 (1 公分)
    double barometricSurgeMeters = 0.0;
    if (pressure != null && pressure < 1013.25 && pressure > 850.0) {
      barometricSurgeMeters = (1013.25 - pressure) * 0.01;
    }

    // 🌟 Palantir 國防遙測 2：三維瘋狗浪能量相長干涉矩陣
    final bool isDeepSwellRogue = (waveP >= 10.0 && waveH >= 0.7) || flux >= 3.5;
    final bool isBarometricSwellCombo = pressure != null && pressure < 1005.0 && waveP >= 8.5;
    final bool isExtremeSea = waveH >= 2.5 || windS >= 11.0;
    final bool isCaution = waveH > 1.3 || windS > 7.0 || barometricSurgeMeters > 0.15;

    Color accentColor;
    Color surfaceColor;
    IconData alertIcon;
    String badgeTag;
    String alertTitle;
    String alertDesc;

    if (isDeepSwellRogue || isBarometricSwellCombo || isExtremeSea) {
      accentColor = AppColors.hazardCoral;
      surfaceColor = isLight ? const Color(0xFFFFF1F2) : const Color(0xFF240608);
      alertIcon = Icons.dangerous_rounded;

      if (isBarometricSwellCombo && pressure != null) {
        badgeTag = "CRITICAL SURGE";
        alertTitle = "🚨 鋒面低壓暴潮疊加 · 氣壓吸升抬升 +${(barometricSurgeMeters * 100).toStringAsFixed(0)}cm";
        // 🌟 移除多餘的 ! 斷言，消滅 unnecessary_non_null_assertion Warning
        alertDesc = "當前大氣氣壓低至 ${pressure.toStringAsFixed(1)} hPa，疊加外海長湧能量相長干涉！防波堤與外礁極易突發無預警洗岸巨浪，嚴禁登礁！";
      } else if (isDeepSwellRogue) {
        badgeTag = "ROGUE WAVE HAZARD";
        alertTitle = "🚨 致命長湧瘋狗浪預警 · 波能通量 ${flux.toStringAsFixed(1)} kW/m";
        alertDesc = "外海偵測到週期 ${waveP.toStringAsFixed(0)} 秒之深層重力長湧！動能達臨界值，近岸消波塊極易突發洗岸瘋狗浪，嚴禁外礁作業！";
      } else {
        badgeTag = "EXTREME SEA STATE";
        alertTitle = "🚨 極端強風巨浪警戒 · 實測浪高 ${waveH.toStringAsFixed(1)}m";
        alertDesc = "實測浪高或陣風已達危險警戒上限，走水狂暴且浪拍防波堤，請即刻撤離無防護作業水域！";
      }
    } else if (isOffline) {
      accentColor = AppColors.bioGold;
      surfaceColor = isLight ? Colors.amber.shade50 : const Color(0xFF261D05);
      alertIcon = Icons.shield_rounded;
      badgeTag = "OFFLINE DEFENSE";
      alertTitle = "🛡️ 外海離線黑盒子自癒守護 · 本地水文接管";
      alertDesc = "當前測站感測器處於離線週期。本地 30 天水文時間序列金庫與天文調和模型已接管防衛，外礁作業請維持最高警戒。";
    } else if (isCaution) {
      accentColor = const Color(0xFFFF9500);
      surfaceColor = isLight ? const Color(0xFFFFFBEB) : const Color(0xFF241403);
      alertIcon = Icons.warning_amber_rounded;
      badgeTag = "ADVISORY";
      alertTitle = "水文戒備 · 請落實防護";
      alertDesc = "風力或浪高稍有推升，潮位變換走水急促，作釣請務必全程穿著合格救生衣與防滑釘鞋，建議尋找背風標點。";
    } else {
      accentColor = isLight ? AppColors.marineBlue : AppColors.pelagicCyan;
      surfaceColor = isLight ? const Color(0xFFF0F9FF) : const Color(0xFF041C0F);
      alertIcon = Icons.verified_user_rounded;
      badgeTag = "OPERATIONAL";
      alertTitle = "海象平穩 · 條件優良";
      alertDesc = "波高週期平緩且風力適中，全島多數近岸作業條件優良，請維持基本防護。";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: isLight ? 0.95 : 0.88),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                            alertTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isLight && accentColor != AppColors.hazardCoral ? const Color(0xFF023E8A) : accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 0.5),
                          ),
                          child: Text(
                            badgeTag,
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: accentColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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

          if (!isOffline && (flux > 0 || pressure != null)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (flux > 0)
                  _buildTelemetryChip(
                    "動能通量", 
                    "${flux.toStringAsFixed(1)} kW/m", 
                    flux >= 3.5 ? AppColors.hazardCoral : AppColors.bioGold,
                    isLight,
                  ),
                if (pressure != null)
                  _buildTelemetryChip(
                    "大氣氣壓", 
                    "${pressure.toStringAsFixed(1)} hPa", 
                    pressure < 1005.0 ? AppColors.hazardCoral : (isLight ? AppColors.marineBlue : AppColors.pelagicCyan),
                    isLight,
                  ),
                if (barometricSurgeMeters > 0.05)
                  _buildTelemetryChip(
                    "低壓水銀吸升", 
                    "+${(barometricSurgeMeters * 100).toStringAsFixed(1)} cm", 
                    AppColors.hazardCoral,
                    isLight,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryChip(String label, String value, Color color, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isLight ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}