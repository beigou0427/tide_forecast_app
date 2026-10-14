import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/solunar_util.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🌟 經海事光學對比重塑之月相農曆與咬度指數儀表 (Solunar Card)
/// 100% 三模光學適配版：消滅深色模式下進度條亮白軌道與低對比建議框！
class SolunarCard extends ConsumerWidget {
  final DateTime selectedDate;
  const SolunarCard({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;

    final solunar = SolunarUtil.calculate(selectedDate);
    final bool isSpringTide = solunar.tideCategory == "大潮";

    // 🌟 核心修復：語意化動態色彩矩陣，消滅刺眼白色進度軌道
    final Color textPrimary = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color textSecondary = isEInk 
        ? Colors.black54 
        : (isClassic ? Colors.grey.shade600 : AppColors.textSecondary);
    final Color accentColor = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
    final Color springTideColor = isEInk ? Colors.black : AppColors.hazardCoral;
    final Color progressTrackColor = isEInk 
        ? Colors.black12 
        : (isClassic ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.08));
    final Color adviceBoxBg = isEInk 
        ? Colors.white 
        : (isClassic ? const Color(0xFF0077B6).withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.04));
    final Color adviceBorderColor = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(solunar.moonPhaseEmoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            solunar.moonPhaseName,
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: textPrimary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(${solunar.lunarDateStr})",
                            style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text("日月引力與海流活躍指數", style: TextStyle(fontSize: 10.5, color: textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isEInk ? Colors.black.withValues(alpha: 0.08) : (isSpringTide
                      ? springTideColor.withValues(alpha: 0.12)
                      : accentColor.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEInk ? Colors.black : (isSpringTide
                        ? springTideColor.withValues(alpha: 0.4)
                        : accentColor.withValues(alpha: 0.3)),
                    width: isEInk ? 1.5 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSpringTide ? Icons.local_fire_department_rounded : Icons.water_rounded,
                      color: isSpringTide ? springTideColor : accentColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      solunar.tideCategory,
                      style: TextStyle(
                        color: isSpringTide ? springTideColor : accentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text("咬度指數", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: solunar.fishActivityScore / 100.0,
                    backgroundColor: progressTrackColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isEInk ? Colors.black : (solunar.fishActivityScore >= 85 ? AppColors.bioGold : accentColor),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${solunar.fishActivityScore}%",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: isEInk ? Colors.black : (solunar.fishActivityScore >= 85 ? AppColors.bioGold : accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: adviceBoxBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: adviceBorderColor, width: isEInk ? 1.5 : 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 15, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    solunar.biteWindowAdvice,
                    style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.4, fontWeight: FontWeight.w500),
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
