import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 🍏 Apple 首席設計工藝：自適應雙主題懸浮卡片 (Adaptive Liquid Glass / Classic Card)
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        // 🌟 經典模式：純白溫潤底色；深淵模式：藍寶石雙層光學折射漸層
        color: isLight ? Colors.white : null,
        gradient: isLight
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF101C2E), // 頂部微光折射層
                  Color(0xFF09111C), // 底部深邃沉積層
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(isLight ? 20 : 22),
        // 🌟 經典模式：細緻微灰外框；深淵模式：0.5pt 水晶切面導角
        border: isLight
            ? Border.all(color: Colors.grey.shade200, width: 1.0)
            : Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: 0.5,
              ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}