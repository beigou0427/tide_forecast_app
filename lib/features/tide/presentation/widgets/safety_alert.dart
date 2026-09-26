import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🍏 Apple 首席設計工藝：海況安全環境感知微光膠囊 (Ambient Safety Telemetry)
class SafetyAlert extends StatelessWidget {
  final Observation current;

  const SafetyAlert({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final double waveH = current.waveHeight ?? 0.0;
    final double windS = current.windSpeed ?? 0.0;
    final bool isDanger = waveH > 1.5 || windS > 8.0;

    // 🌟 Apple 原生系統警戒色譜
    final Color accentColor = isDanger ? AppColors.hazardCoral : const Color(0xFF30D158);
    final Color surfaceColor = isDanger 
        ? const Color(0xFF240608) 
        : const Color(0xFF041C0F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        // 🌟 0.5pt 警戒微光切面
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 警戒光環圖示
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Icon(
              isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDanger ? "海況警戒 · 風浪偏大" : "海況平穩 · 條件優良",
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDanger
                      ? "浪高超標或風力急劇推升，嚴防外礁瘋狗浪，無防護作業請提早撤離。"
                      : "波高週期平緩且風力適中，全島多數近岸作業條件優良，請維持基本防護。",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
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