import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🌟 經海事夜航暗適應規範重塑之安全警示條 (Safety Alert)
/// 100% 三模光學適配版：消滅深色夜間模式下寫死粉紅/淺綠的刺眼眩光！
class SafetyAlert extends ConsumerWidget {
  final Observation current;

  const SafetyAlert({super.key, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;

    // 浪高 > 1.5m 或 風速 > 8m/s 視為海象不佳
    final bool isDanger = (current.waveHeight ?? 0) > 1.5 || (current.windSpeed ?? 0) > 8.0;

    // 🌟 核心修復：語意化動態夜視色彩矩陣，消滅刺眼粉彩
    final Color alertBg;
    final Color alertBorder;
    final Color iconColor;
    final Color textColor;

    if (isEInk) {
      alertBg = Colors.white;
      alertBorder = Colors.black;
      iconColor = Colors.black;
      textColor = Colors.black;
    } else if (isClassic) {
      alertBg = isDanger ? Colors.red.shade50 : Colors.green.shade50;
      alertBorder = isDanger ? Colors.red.shade200 : Colors.green.shade200;
      iconColor = isDanger ? Colors.red.shade700 : Colors.green.shade700;
      textColor = isDanger ? Colors.red.shade900 : Colors.green.shade900;
    } else {
      // 深淵黑金 (暗夜外礁模式)：微光半透明背景，保護瞳孔暗適應
      alertBg = isDanger 
          ? AppColors.hazardCoral.withValues(alpha: 0.12)
          : const Color(0xFF10B981).withValues(alpha: 0.10);
      alertBorder = isDanger 
          ? AppColors.hazardCoral.withValues(alpha: 0.45)
          : const Color(0xFF10B981).withValues(alpha: 0.35);
      iconColor = isDanger ? AppColors.hazardCoral : const Color(0xFF34D399);
      textColor = isDanger ? const Color(0xFFFF8595) : const Color(0xFF6EE7B7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: alertBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alertBorder,
          width: isEInk ? 1.5 : 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isDanger 
                  ? "海況警告：現場浪高或陣風已達作業上限，不建議從事岸邊作釣！" 
                  : "海況平穩：目前環境適合作業，出海請穿著合格救生衣與釘鞋。",
              style: TextStyle(
                color: textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
