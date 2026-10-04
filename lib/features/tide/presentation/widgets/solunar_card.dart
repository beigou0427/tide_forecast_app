import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/solunar_util.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🍏 Apple 首席設計工藝：天體月相與潮汐動能雙儀表 (零溢出安全版)
/// 結合 AI 咬度與國際海事權威「潮汐係數 (Tidal Coefficient)」
class SolunarCard extends StatelessWidget {
  final DateTime selectedDate;
  const SolunarCard({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final solunar = SolunarUtil.calculate(selectedDate);
    final bool isSpringTide = solunar.tideCategory == "大潮";
    final Color tideAccent = isSpringTide ? AppColors.bioGold : AppColors.pelagicCyan;
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 月相立體微光與大中小潮膠囊 (雙重 Expanded 彈性約束，杜絕字體放大溢出)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // 天體玻璃光暈球
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLight ? Colors.blueGrey.shade50 : Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: isLight ? Colors.grey.shade300 : AppColors.glassBorder, 
                          width: 0.5,
                        ),
                        boxShadow: isLight ? [] : [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.08),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          solunar.moonPhaseEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  solunar.moonPhaseName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: isLight ? AppColors.classicText : AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "(${solunar.lunarDateStr})",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLight ? Colors.grey.shade600 : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "日月天體引力 · 海流走水動能",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5, 
                              color: isLight ? Colors.grey : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 大中小潮高對比光學膠囊
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tideAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tideAccent.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                  boxShadow: isLight ? [] : [
                    BoxShadow(
                      color: tideAccent.withValues(alpha: 0.15),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSpringTide ? Icons.local_fire_department_rounded : Icons.water_rounded,
                      color: tideAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      solunar.tideCategory,
                      style: TextStyle(
                        color: tideAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 🌟 2. 雙重指標儀表：國際潮汐係數 + AI 咬度指數
          Row(
            children: [
              _buildProgressMetric(
                label: "國際潮汐係數",
                value: solunar.tidalCoefficient,
                maxValue: 120, // 潮汐係數極限值為 120
                isHigh: solunar.tidalCoefficient >= 90,
                isLight: isLight,
              ),
              const SizedBox(width: 16),
              _buildProgressMetric(
                label: "AI 咬度指數",
                value: solunar.fishActivityScore,
                maxValue: 100, // 咬度極限值為 100
                isHigh: solunar.fishActivityScore >= 85,
                isLight: isLight,
                isPercentage: true,
              ),
            ],
          ),
          
          const SizedBox(height: 14),

          // 3. 滿水返退戰術指引氣泡
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isLight ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLight ? Colors.grey.shade200 : AppColors.glassBorder, 
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.wb_twilight_rounded, 
                  size: 16, 
                  color: isLight ? const Color(0xFF0077B6) : AppColors.bioGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    solunar.biteWindowAdvice,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isLight ? Colors.blueGrey.shade800 : AppColors.textSecondary,
                      height: 1.45,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric({
    required String label,
    required int value,
    required int maxValue,
    required bool isHigh,
    required bool isLight,
    bool isPercentage = false,
  }) {
    final Color progressColor = isHigh 
        ? AppColors.bioGold 
        : (isLight ? AppColors.marineBlue : AppColors.pelagicCyan);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isLight ? Colors.grey.shade600 : AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 6,
                    color: isLight ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.08),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (value / maxValue).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: isHigh
                                ? (isLight ? const [Color(0xFFD97706), AppColors.bioGold] : const [AppColors.pelagicCyan, AppColors.bioGold])
                                : (isLight ? const [Color(0xFF023E8A), AppColors.marineBlue] : const [AppColors.marineBlue, AppColors.pelagicCyan]),
                          ),
                          boxShadow: isLight ? [] : [
                            BoxShadow(
                              color: progressColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isPercentage ? "$value%" : "$value",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: progressColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
