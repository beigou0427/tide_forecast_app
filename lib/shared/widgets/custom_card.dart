import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 🍏 Apple 首席設計工藝：液態玻璃懸浮卡片 (Liquid Glass Crystal Surface)
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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        // 🌟 藍寶石鏡面雙層微折射漸層：上淺下深，展現玻璃厚度感
        gradient: const LinearGradient(
          colors: [
            Color(0xFF101C2E), // 頂部微光折射層
            Color(0xFF09111C), // 底部深邃沉積層
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        // 🌟 0.5pt 水晶切面高精度導角邊界 (符合 HIG 物理反光原則)
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: 0.5,
        ),
        boxShadow: [
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