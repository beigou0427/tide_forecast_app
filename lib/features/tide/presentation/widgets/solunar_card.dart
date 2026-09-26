import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/solunar_util.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🍏 Apple 首席設計工藝：天體月相與生物咬度儀 (零溢出安全版)
class SolunarCard extends StatelessWidget {
  final DateTime selectedDate;
  const SolunarCard({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final solunar = SolunarUtil.calculate(selectedDate);
    final bool isSpringTide = solunar.tideCategory == "大潮";
    final Color tideAccent = isSpringTide ? AppColors.bioGold : AppColors.pelagicCyan;

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 月相立體微光與大中小潮膠囊 (🌟 雙重 Expanded 彈性約束，杜絕字體放大溢出)
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
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(color: AppColors.glassBorder, width: 0.5),
                        boxShadow: [
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "(${solunar.lunarDateStr})",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            "日月天體引力 · 海流走水活躍指數",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
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
                  boxShadow: [
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

          // 2. 生物熒光咬度進度條
          Row(
            children: [
              const Text(
                "咬度指數",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 7,
                    color: Colors.white.withValues(alpha: 0.08),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (solunar.fishActivityScore / 100.0).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: solunar.fishActivityScore >= 85
                                ? const [AppColors.pelagicCyan, AppColors.bioGold]
                                : const [AppColors.marineBlue, AppColors.pelagicCyan],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (solunar.fishActivityScore >= 85 ? AppColors.bioGold : AppColors.pelagicCyan).withValues(alpha: 0.4),
                              blurRadius: 6,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${solunar.fishActivityScore}%",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: solunar.fishActivityScore >= 85 ? AppColors.bioGold : AppColors.pelagicCyan,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. 滿水返退戰術指引氣泡
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wb_twilight_rounded, size: 16, color: AppColors.bioGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    solunar.biteWindowAdvice,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
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
}