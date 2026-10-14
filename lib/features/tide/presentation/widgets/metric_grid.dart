import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🌟 經海事光學對比重塑之 6 大水文參數矩陣
/// 100% 三模配色自適應版：徹底消滅深色模式下白底白字的視覺災難！
class MetricGrid extends ConsumerWidget {
  final Observation current;

  const MetricGrid({super.key, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;

    // 🌟 核心修復：語意化動態色彩矩陣，消滅寫死白色卡片與隱形文字
    final Color tileBg = isEInk 
        ? Colors.white 
        : (isClassic ? Colors.white : AppColors.abyssCard);
    final Color tileBorder = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder);
    final Color labelColor = isEInk 
        ? Colors.black54 
        : (isClassic ? Colors.grey.shade600 : AppColors.textSecondary);
    final Color valueColor = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);

    final List<Widget> metrics = [];

    void addIfValid(String label, double? val, String unit, IconData icon, Color iconColor) {
      if (val != null) {
        metrics.add(_buildMetricTile(
          label, 
          "$val$unit", 
          icon, 
          isEInk ? Colors.black : iconColor,
          tileBg,
          tileBorder,
          labelColor,
          valueColor,
          isEInk,
        ));
      }
    }

    addIfValid("波浪高度", current.waveHeight, " m", Icons.waves_rounded, Colors.indigoAccent);
    addIfValid("海水溫度", current.seaTemperature, " ℃", Icons.thermostat_rounded, const Color(0xFFFF9500));
    addIfValid("觀測風速", current.windSpeed, " m/s", Icons.air_rounded, const Color(0xFF10B981));
    addIfValid("海流流速", current.currentSpeed, " m/s", Icons.explore_rounded, Colors.tealAccent);
    addIfValid("風向角度", current.windDirection, "°", Icons.navigation_rounded, Colors.brown);
    addIfValid("大氣壓力", current.airPressure, " hPa", Icons.speed_rounded, Colors.purpleAccent);
    addIfValid("即時氣溫", current.airTemperature, " ℃", Icons.wb_sunny_rounded, AppColors.bioGold);

    if (metrics.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            "該測站目前僅提供基礎潮位資訊", 
            style: TextStyle(color: labelColor, fontSize: 13),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: metrics,
    );
  }

  Widget _buildMetricTile(
    String label, 
    String value, 
    IconData icon, 
    Color iconColor,
    Color tileBg,
    Color tileBorder,
    Color labelColor,
    Color valueColor,
    bool isEInk,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tileBorder, width: isEInk ? 1.5 : 0.5),
        boxShadow: (isEInk || tileBg != Colors.white) ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEInk ? Colors.black12 : iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: labelColor, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value, 
                    style: GoogleFonts.rubik(
                      fontSize: 16.5, 
                      fontWeight: FontWeight.w900, 
                      color: valueColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
