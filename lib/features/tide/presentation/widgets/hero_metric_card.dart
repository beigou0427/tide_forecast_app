import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🌟 經海事光學對比重塑之首頁大字核心指標卡 (Hero Metric Card)
/// 100% 三模配色自適應版：徹底消滅深色模式下潮位狀態黑字撞黑底！
class HeroMetricCard extends ConsumerWidget {
  final Observation current;
  final bool isBuoy;

  const HeroMetricCard({super.key, required this.current, required this.isBuoy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;

    // 🌟 核心修復：語意化動態色彩矩陣，消滅黑字撞黑底
    final Color labelColor = isEInk 
        ? Colors.black54 
        : (isClassic ? Colors.grey.shade600 : AppColors.textSecondary);
    final Color tideHeightColor = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
    final Color tideStatusColor = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color waveColor = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.indigo : Colors.indigoAccent);
    final Color periodColor = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.cyan.shade700 : Colors.cyanAccent);
    final Color dividerColor = isEInk 
        ? Colors.black26 
        : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder);

    final bool showWave = isBuoy && current.tideHeight == null;

    return CustomCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (showWave) ...[
            _item("目前波高", "${current.waveHeight ?? '--'} m", waveColor, labelColor),
            _divider(dividerColor),
            _item("波浪週期", "${current.wavePeriod ?? '--'} s", periodColor, labelColor),
          ] else ...[
            _item("目前潮高", "${current.tideHeight ?? '--'} m", tideHeightColor, labelColor),
            _divider(dividerColor),
            // 🌟 核心修復：潮位狀態在深色模式下自動晉升為高亮純白！
            _item("潮位狀態", current.tideLevel ?? '--', tideStatusColor, labelColor),
          ],
        ],
      ),
    );
  }

  Widget _item(String label, String value, Color valueColor, Color labelColor) {
    return Column(
      children: [
        Text(
          label, 
          style: TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Text(
          value, 
          style: GoogleFonts.rubik(
            fontSize: 32, 
            fontWeight: FontWeight.w900, 
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _divider(Color dividerColor) => Container(width: 1, height: 42, color: dividerColor);
}
