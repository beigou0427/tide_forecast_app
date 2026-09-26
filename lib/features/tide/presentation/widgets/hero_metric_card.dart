import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/tide_model.dart';

/// 🍏 Apple 首席設計工藝：核心水文指標看板 (Hero Oceanic Telemetry)
class HeroMetricCard extends StatelessWidget {
  final Observation current;
  final bool isBuoy;

  const HeroMetricCard({super.key, required this.current, required this.isBuoy});

  @override
  Widget build(BuildContext context) {
    final bool showWave = isBuoy && current.tideHeight == null;

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (showWave) ...[
            _buildMetric(
              label: "實測波高",
              number: current.waveHeight != null ? current.waveHeight!.toStringAsFixed(2) : "--",
              unit: "m",
              glowColor: AppColors.pelagicCyan,
            ),
            _buildDivider(),
            _buildMetric(
              label: "波浪週期",
              number: current.wavePeriod != null ? current.wavePeriod!.toStringAsFixed(1) : "--",
              unit: "s",
              glowColor: AppColors.bioGold,
            ),
          ] else ...[
            _buildMetric(
              label: "即時潮高",
              number: current.tideHeight != null ? current.tideHeight!.toStringAsFixed(2) : "--",
              unit: "m",
              glowColor: AppColors.pelagicCyan,
            ),
            _buildDivider(),
            _buildStatusItem(
              label: "水文狀態",
              status: current.tideLevel ?? "--",
              glowColor: AppColors.bioGold,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String number,
    required String unit,
    required Color glowColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // 🌟 48pt 磅礴特粗數字 + 瑞士鐘錶級等寬特性 (Tabular Figures)
              Text(
                number,
                style: GoogleFonts.rubik(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: glowColor,
                  letterSpacing: -1.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required String label,
    required String status,
    required Color glowColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: glowColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: glowColor.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: glowColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 0.5,
      height: 52,
      color: AppColors.glassBorder,
    );
  }
}