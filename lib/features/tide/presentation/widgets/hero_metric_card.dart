import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/tide_model.dart';

/// 🍏 Dieter Rams × John Maeda 哲學重塑：冷靜海洋遙測主儀表 (Calm Oceanic Telemetry)
/// 徹底消滅左右互搏的雜亂雙色，回歸瑞士名錶般的純粹等寬排版與極致克制
class HeroMetricCard extends StatelessWidget {
  final Observation current;
  final bool isBuoy;

  const HeroMetricCard({super.key, required this.current, required this.isBuoy});

  @override
  Widget build(BuildContext context) {
    final bool showWave = isBuoy && current.tideHeight == null;
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (showWave) ...[
            _buildMetric(
              context: context,
              label: "實測波高",
              number: current.waveHeight != null ? current.waveHeight!.toStringAsFixed(2) : "--",
              unit: "m",
              isLight: isLight,
            ),
            _buildDivider(isLight),
            _buildMetric(
              context: context,
              label: "波浪週期",
              number: current.wavePeriod != null ? current.wavePeriod!.toStringAsFixed(1) : "--",
              unit: "s",
              isLight: isLight,
            ),
          ] else ...[
            _buildMetric(
              context: context,
              label: "即時潮高",
              number: current.tideHeight != null ? current.tideHeight!.toStringAsFixed(2) : "--",
              unit: "m",
              isLight: isLight,
            ),
            _buildDivider(isLight),
            _buildStatusItem(
              context: context,
              label: "水文狀態",
              status: current.tideLevel ?? "--",
              isLight: isLight,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric({
    required BuildContext context,
    required String label,
    required String number,
    required String unit,
    required bool isLight,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isLight ? Colors.grey.shade600 : AppColors.textTertiary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // 🌟 瑞士名錶級純粹排印：告別刺眼雙色，回歸純淨冰白或沉穩深海黑
                Text(
                  number,
                  style: GoogleFonts.rubik(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: isLight ? AppColors.classicText : AppColors.textPrimary,
                    letterSpacing: -1.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isLight ? Colors.grey.shade500 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required BuildContext context,
    required String label,
    required String status,
    required bool isLight,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isLight ? Colors.grey.shade600 : AppColors.textTertiary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                // 🌟 Dieter Rams 減法：極簡微光膠囊，消滅刺眼俗氣色塊
                color: isLight 
                    ? AppColors.marineBlue.withValues(alpha: 0.08) 
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLight 
                      ? AppColors.marineBlue.withValues(alpha: 0.2) 
                      : AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.marineBlue : AppColors.pelagicCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isLight ? AppColors.marineBlue : AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isLight) {
    return Container(
      width: 0.5,
      height: 48,
      color: isLight ? Colors.grey.shade200 : AppColors.glassBorder,
    );
  }
}