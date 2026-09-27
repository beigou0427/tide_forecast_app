import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/tide_model.dart';

/// Tony Fadell 人因工程重塑：外礁手套友善與 1 公尺遠距巨幕儀表
class HeroMetricCard extends StatelessWidget {
  final Observation current;
  final bool isBuoy;

  const HeroMetricCard({super.key, required this.current, required this.isBuoy});

  @override
  Widget build(BuildContext context) {
    final bool showWave = isBuoy && current.tideHeight == null;
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    final String mainVal = showWave
        ? (current.waveHeight != null ? current.waveHeight!.toStringAsFixed(2) : "--")
        : (current.tideHeight != null ? current.tideHeight!.toStringAsFixed(2) : "--");
    final String mainLabel = showWave ? "實測波高" : "即時潮高";
    final String subVal = showWave
        ? (current.wavePeriod != null ? "${current.wavePeriod!.toStringAsFixed(1)} s" : "--")
        : (current.tideLevel ?? "--");
    final String subLabel = showWave ? "波浪週期" : "水文狀態";

    return InkWell(
      onTap: () {
        HapticFeedback.heavyImpact();
        _showGlanceableHUD(context, mainLabel, mainVal, subLabel, subVal, isLight);
      },
      borderRadius: BorderRadius.circular(22),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  context: context,
                  label: mainLabel,
                  number: mainVal,
                  unit: "m",
                  isLight: isLight,
                ),
                _buildDivider(isLight),
                if (showWave)
                  _buildMetric(
                    context: context,
                    label: subLabel,
                    number: current.wavePeriod != null ? current.wavePeriod!.toStringAsFixed(1) : "--",
                    unit: "s",
                    isLight: isLight,
                  )
                else
                  _buildStatusItem(
                    context: context,
                    label: subLabel,
                    status: current.tideLevel ?? "--",
                    isLight: isLight,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Tony Fadell 人因暗示：提醒釣客可全螢幕放大
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fullscreen_rounded, 
                  size: 14, 
                  color: isLight ? Colors.grey.shade500 : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  "輕觸放大 · 外礁一公尺遠距看板模式",
                  style: TextStyle(
                    fontSize: 10,
                    color: isLight ? Colors.grey.shade600 : AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 外礁巨幕 HUD (濕手戴手套專用，1公尺外清晰可見)
  void _showGlanceableHUD(
    BuildContext context, 
    String mainLabel, 
    String mainVal, 
    String subLabel, 
    String subVal, 
    bool isLight,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "HUD",
      pageBuilder: (ctx, anim1, anim2) {
        final Color hudBg = isLight ? Colors.white : AppColors.abyssBlack;
        final Color hudText = isLight ? AppColors.classicText : AppColors.textPrimary;
        final Color accentColor = isLight ? AppColors.marineBlue : AppColors.pelagicCyan;

        return Scaffold(
          backgroundColor: hudBg,
          body: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // 任何手掌拍擊立即關閉
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 0.5),
                          ),
                          child: Text(
                            "外礁遠距抬頭 HUD",
                            style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          "點擊螢幕任何處退出",
                          style: TextStyle(color: isLight ? Colors.grey : AppColors.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),

                    // 96pt 巨大數值
                    Column(
                      children: [
                        Text(
                          mainLabel,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isLight ? Colors.grey.shade700 : AppColors.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              mainVal,
                              style: GoogleFonts.rubik(
                                fontSize: 96,
                                fontWeight: FontWeight.w900,
                                color: hudText,
                                letterSpacing: -3.0,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "m",
                              style: GoogleFonts.rubik(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.0),
                          ),
                          child: Text(
                            "$subLabel：$subVal",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Text(
                      "🌊 潮汐表 PRO · 海事級高對比儀表",
                      style: TextStyle(color: isLight ? Colors.grey.shade400 : AppColors.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
