import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🌟 John Carmack 單趟線性光柵化水文磚陣列 (Single-Pass Linear Grid)
/// 徹底消滅 GridView(shrinkWrap: true) 引起的雙重佈局 (Double Layout Pass) 掉幀
class MetricGrid extends StatelessWidget {
  final Observation current;

  const MetricGrid({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final List<Widget> bricks = [];

    void addIfValid(
      String label, 
      double? val, 
      String unit, 
      IconData icon, 
      Color accent, 
      {bool isHighPrecision = false}
    ) {
      if (val != null && !val.isNaN && !val.isInfinite) {
        bricks.add(_MetricBrickItem(
          label: label,
          val: val,
          unit: unit,
          icon: icon,
          accent: accent,
          isLight: isLight,
          isHighPrecision: isHighPrecision,
        ));
      }
    }

    // 依水文重要性嚴格排列
    addIfValid("波浪高度", current.waveHeight, "m", Icons.waves_rounded, AppColors.pelagicCyan);
    addIfValid("波能通量", current.waveEnergyFlux, "kW/m", Icons.bolt_rounded, AppColors.bioGold, isHighPrecision: true);
    addIfValid("海水溫度", current.seaTemperature, "℃", Icons.thermostat_rounded, const Color(0xFFFF9500));
    addIfValid("觀測風速", current.windSpeed, "m/s", Icons.air_rounded, const Color(0xFF30D158));
    addIfValid("海流流速", current.currentSpeed, "m/s", Icons.explore_rounded, AppColors.pelagicCyan);
    addIfValid("風向角度", current.windDirection, "°", Icons.navigation_rounded, AppColors.bioGold);
    addIfValid("大氣氣壓", current.airPressure, "hPa", Icons.speed_rounded, const Color(0xFFBF5AF2));
    addIfValid("即時氣溫", current.airTemperature, "℃", Icons.wb_sunny_rounded, AppColors.bioGold);

    if (bricks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLight ? Colors.grey.shade200 : AppColors.glassBorder, 
            width: isLight ? 1.0 : 0.5,
          ),
        ),
        child: Center(
          child: Text(
            "該測站目前僅提供基礎潮位數據",
            style: TextStyle(
              color: isLight ? Colors.grey : AppColors.textTertiary, 
              fontSize: 13, 
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // 🌟 John Carmack 線性 O(N) 雙列成對折疊：彻底消滅 GridView 雙重排版耗時
    final List<Widget> rows = [];
    for (int i = 0; i < bricks.length; i += 2) {
      final left = bricks[i];
      final right = (i + 1 < bricks.length) ? bricks[i + 1] : const Spacer();
      
      rows.add(Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ));

      if (i + 2 < bricks.length) {
        rows.add(const SizedBox(height: 10));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

/// 獨立元件化磚塊，避免上層 rebuild 導致整個列表反覆重繪
class _MetricBrickItem extends StatelessWidget {
  final String label;
  final double val;
  final String unit;
  final IconData icon;
  final Color accent;
  final bool isLight;
  final bool isHighPrecision;

  const _MetricBrickItem({
    required this.label,
    required this.val,
    required this.unit,
    required this.icon,
    required this.accent,
    required this.isLight,
    this.isHighPrecision = false,
  });

  @override
  Widget build(BuildContext context) {
    final String valStr = isHighPrecision
        ? val.toStringAsFixed(2)
        : (val == val.roundToDouble() && unit == "°" 
            ? val.toInt().toString() 
            : val.toStringAsFixed(1));

    final Color brickBg = isLight ? Colors.white : Colors.white.withValues(alpha: 0.04);
    final Color borderColor = isLight ? Colors.grey.shade200 : AppColors.glassBorder;
    final Color valColor = isLight ? AppColors.classicText : AppColors.textPrimary;
    final Color labelColor = isLight ? Colors.grey.shade600 : AppColors.textSecondary;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: brickBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isLight ? 0.8 : 0.5,
        ),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.5),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      valStr,
                      style: GoogleFonts.rubik(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: valColor,
                        letterSpacing: -0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: unit.length > 2 ? 9.5 : 11,
                        fontWeight: FontWeight.w600,
                        color: isLight ? Colors.grey.shade500 : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}