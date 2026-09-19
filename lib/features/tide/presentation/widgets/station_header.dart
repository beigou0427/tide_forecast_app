import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/tide_model.dart';

class StationHeader extends StatelessWidget {
  final StationInfo info;
  final double? distanceKm;

  const StationHeader({super.key, required this.info, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    // 組合地點顯示文字，如果鄉鎮名稱為空則只顯示縣市
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
                const Icon(Icons.location_on, size: 16, color: Color(0xFF0077B6)),
                const SizedBox(width: 4),
                Text(
                  locationText, 
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 14)
                ),
              ],
            ),
            if (distanceKm != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0077B6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "距離 ${distanceKm!.toStringAsFixed(1)} km",
                  style: const TextStyle(
                    fontSize: 12, 
                    color: Color(0xFF0077B6), 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          info.stationName, 
          style: GoogleFonts.notoSansTc(
            fontSize: 30, 
            fontWeight: FontWeight.bold, 
            color: Colors.black87
          )
        ),
        Text(
          info.attr, 
          style: const TextStyle(
            color: Color(0xFF00B4D8), 
            fontWeight: FontWeight.w600, 
            fontSize: 14
          )
        ),
      ],
    );
  }
}
