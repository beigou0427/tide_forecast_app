import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// Apple 首席設計工藝 × Jensen Huang 物理資產：全盤水文細節磚塊陣列 (含波能通量)
class MetricGrid extends StatelessWidget {
  final Observation current;

  const MetricGrid({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final List<Widget> metrics = [];

    void addIfValid(String label, double? val, String unit, IconData icon, Color accent, {bool isHighPrecision = false}) {
      if (val != null) {
        metrics.add(_buildMetricBrick(label, val, unit, icon, accent, isLight, isHighPrecision: isHighPrecision));
      }
    }

    // 依序排列水文指標：波浪高度與專利波能通量並列為前哨核心
    addIfValid("波浪高度", current.waveHeight, "m", Icons.waves_rounded, AppColors.pelagicCyan);
    addIfValid("波能通量", current.waveEnergyFlux, "kW/m", Icons.bolt_rounded, AppColors.bioGold, isHighPrecision: true);
    addIfValid("海水溫度", current.seaTemperature, "℃", Icons.thermostat_rounded, const Color(0xFFFF9500));
    addIfValid("觀測風速", current.windSpeed, "m/s", Icons.air_rounded, const Color(0xFF30D158));
    addIfValid("海流流速", current.currentSpeed, "m/s", Icons.explore_rounded, AppColors.pelagicCyan);
    addIfValid("風向角度", current.windDirection, "°", Icons.navigation_rounded, AppColors.bioGold);
    addIfValid("大氣氣壓", current.airPressure, "hPa", Icons.speed_rounded, const Color(0xFFBF5AF2));
    addIfValid("即時氣溫", current.airTemperature, "℃", Icons.wb_sunny_rounded, AppColors.bioGold);

    if (metrics.isEmpty) {
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

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.85,
      children: metrics,
    );
  }

  Widget _buildMetricBrick(
    String label, 
    double val, 
    String unit, 
    IconData icon, 
    Color accent, 
    bool isLight, 
    {bool isHighPrecision = false}
  ) {
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
