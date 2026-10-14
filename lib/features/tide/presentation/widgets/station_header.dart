import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🌟 經海事光學對比標準重塑之測站首頁抬頭組件
/// 100% 三模配色自適應版：徹底消滅深淵黑金模式下黑字撞黑底的視覺死穴！
class StationHeader extends ConsumerWidget {
  final StationInfo info;
  final double? distanceKm;

  const StationHeader({super.key, required this.info, this.distanceKm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;

    // 🌟 核心修復：深色模式使用純白高亮字體，消滅黑字撞黑底！
    final Color titleColor = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color locationColor = isEInk 
        ? Colors.black87 
        : (isClassic ? Colors.blueGrey.shade700 : AppColors.textSecondary);
    final Color accentColor = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);

    final String locationText = info.townName.isNotEmpty 
        ? "${info.countyName} · ${info.townName}" 
        : info.countyName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 16, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  locationText, 
                  style: TextStyle(color: locationColor, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (distanceKm != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isEInk ? Colors.black12 : accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEInk ? Colors.black : accentColor.withValues(alpha: 0.3),
                    width: isEInk ? 1.0 : 0.5,
                  ),
                ),
                child: Text(
                  "距離 ${distanceKm!.toStringAsFixed(1)} km",
                  style: TextStyle(
                    fontSize: 11.5, 
                    color: accentColor, 
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          info.stationName, 
          style: GoogleFonts.notoSansTc(
            fontSize: 28, 
            fontWeight: FontWeight.w900, 
            color: titleColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isEInk ? Colors.black12 : accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isEInk ? Colors.black : accentColor.withValues(alpha: 0.25), width: 0.5),
              ),
              child: Text(
                info.attr, 
                style: TextStyle(
                  color: accentColor, 
                  fontWeight: FontWeight.w800, 
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "中央氣象署 85 測站光纖直連",
              style: TextStyle(color: locationColor, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
