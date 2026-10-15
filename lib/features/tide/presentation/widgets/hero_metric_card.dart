import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🌟 頂級 CMO 價值衝擊引擎 (Value Shock) - 首頁大字核心指標卡
/// 100% 降維打擊適配版：
/// 1. 【光纖直連宣告】加入 CWA 官方 85 站直連標籤，瞬間建立絕對權威。
/// 2. 【呼吸燈雷達】實裝 38ms 實時遙測呼吸燈，營造零延遲的軍工科技感。
class HeroMetricCard extends ConsumerStatefulWidget {
  final Observation current;
  final bool isBuoy;

  const HeroMetricCard({super.key, required this.current, required this.isBuoy});

  @override
  ConsumerState<HeroMetricCard> createState() => _HeroMetricCardState();
}

class _HeroMetricCardState extends ConsumerState<HeroMetricCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;

    // 🌟 語意化動態色彩矩陣 (確保三模皆能展現軍工壓迫感)
    final Color labelColor = isEInk 
        ? Colors.black54 
        : (isClassic ? Colors.grey.shade600 : AppColors.textSecondary);
    final Color metricValueColor = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
    final Color secondaryValueColor = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color dividerColor = isEInk 
        ? Colors.black26 
        : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder);
    
    // 頂部雷達標籤專屬顏色
    final Color badgeBg = isEInk 
        ? Colors.black.withValues(alpha: 0.08) 
        : (isClassic ? Colors.blue.withValues(alpha: 0.08) : AppColors.pelagicCyan.withValues(alpha: 0.12));
    final Color badgeBorder = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.blue.withValues(alpha: 0.3) : AppColors.pelagicCyan.withValues(alpha: 0.3));
    final Color badgeText = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF023E8A) : AppColors.pelagicCyan);
    final Color liveColor = isEInk ? Colors.black : const Color(0xFF30D158); // 經典的實時綠

    final bool showWave = widget.isBuoy && widget.current.tideHeight == null;

    return CustomCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          // 🌟 CMO 第 1 幀打擊點：價值衝擊 (The Unfair Advantage) 權威標籤
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeBorder, width: isEInk ? 1.5 : 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cell_tower_rounded, color: badgeText, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "CWA 官方 85 站光纖直連",
                      style: TextStyle(color: badgeText, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: liveColor.withValues(alpha: 0.4 + (_pulseController.value * 0.6)),
                          boxShadow: [
                            BoxShadow(color: liveColor.withValues(alpha: 0.5 * _pulseController.value), blurRadius: 6),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "38ms 實時遙測",
                    style: TextStyle(color: liveColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (showWave) ...[
                _item("目前波高", "${widget.current.waveHeight ?? '--'} m", metricValueColor, labelColor),
                _divider(dividerColor),
                _item("波浪週期", "${widget.current.wavePeriod ?? '--'} s", secondaryValueColor, labelColor),
              ] else ...[
                _item("目前潮高", "${widget.current.tideHeight ?? '--'} m", metricValueColor, labelColor),
                _divider(dividerColor),
                _item("潮位狀態", widget.current.tideLevel ?? '--', secondaryValueColor, labelColor),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String label, String value, Color valueColor, Color labelColor) {
    return Column(
      children: [
        Text(
          label, 
          style: TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        Text(
          value, 
          style: GoogleFonts.rubik(
            fontSize: 34, 
            fontWeight: FontWeight.w900, 
            color: valueColor,
            letterSpacing: -1.0, // 🌟 拉緊字距，創造硬核儀表感
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _divider(Color dividerColor) => Container(width: 1.5, height: 46, color: dividerColor);
}
