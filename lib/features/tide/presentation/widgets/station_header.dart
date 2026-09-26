import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';

/// 🍏 Apple 首席設計工藝：航海地標地理抬頭 (Navigational Landmark Telemetry)
class StationHeader extends StatelessWidget {
  final StationInfo info;
  final double? distanceKm;

  const StationHeader({super.key, required this.info, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final String locationText = info.townName.isNotEmpty 
        ? "${info.countyName} · ${info.townName}" 
        : (info.countyName.isNotEmpty ? info.countyName : "台灣海域");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 地理定位與距離微型膠囊
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: AppColors.pelagicCyan),
                const SizedBox(width: 4),
                Text(
                  locationText, 
                  style: const TextStyle(
                    color: AppColors.textSecondary, 
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            if (distanceKm != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.pelagicCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.pelagicCyan.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  "距離 ${distanceKm!.toStringAsFixed(1)} km",
                  style: const TextStyle(
                    fontSize: 10.5, 
                    color: AppColors.pelagicCyan, 
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // 2. 28pt 磅礴特粗地名
        Text(
          info.stationName, 
          style: GoogleFonts.notoSansTc(
            fontSize: 28, 
            fontWeight: FontWeight.w900, 
            color: AppColors.textPrimary,
            letterSpacing: -0.8,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // 3. 水文屬性光學微膠囊
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.pelagicCyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                info.attr.isNotEmpty ? info.attr : "海象站", 
                style: const TextStyle(
                  color: AppColors.textSecondary, 
                  fontWeight: FontWeight.w700, 
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}