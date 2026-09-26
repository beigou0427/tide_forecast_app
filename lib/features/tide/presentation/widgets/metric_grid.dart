import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🍏 Apple 首席設計工藝：全盤水文細節磚塊陣列 (Hydrological Telemetry Bricks)
class MetricGrid extends StatelessWidget {
  final Observation current;

  const MetricGrid({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final List<Widget> metrics = [];

    void addIfValid(String label, double? val, String unit, IconData icon, Color accent) {
      if (val != null) {
        metrics.add(_buildMetricBrick(label, val, unit, icon, accent));
      }
    }

    // 依序排列水文指標，套用 Apple 嚴謹克制光譜
    addIfValid("波浪高度", current.waveHeight, "m", Icons.waves_rounded, AppColors.pelagicCyan);
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
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: const Center(
          child: Text(
            "該測站目前僅提供基礎潮位數據",
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w500),
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

  Widget _buildMetricBrick(String label, double val, String unit, IconData icon, Color accent) {
    final String valStr = val == val.roundToDouble() && unit == "°" 
        ? val.toInt().toString() 
        : val.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // 🌟 黑曜石液態玻璃微光磚
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // 微型光環圖示
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // 🌟 瑞士名錶級等寬數字排印
                    Text(
                      valStr,
                      style: GoogleFonts.rubik(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
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