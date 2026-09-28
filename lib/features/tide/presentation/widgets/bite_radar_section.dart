import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bite_prediction_engine.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/tide_model.dart';

/// Martin Fowler 重構解耦：獨立之 10x 標竿魚種水溫驟變爆咬預警元件
class BiteRadarSection extends StatelessWidget {
  final TideStationData station;
  final DateTime selectedDate;
  final bool isClassic;

  const BiteRadarSection({
    super.key,
    required this.station,
    required this.selectedDate,
    required this.isClassic,
  });

  @override
  Widget build(BuildContext context) {
    final bite = BitePredictionEngine.predict(stationData: station, targetDate: selectedDate);
    final Color titleColor = isClassic ? const Color(0xFF023E8A) : AppColors.textPrimary;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.bioGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phishing_rounded, color: AppColors.bioGold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "10x 標竿魚種爆咬預警雷達",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "水溫變化率 ΔT · 氣壓趨勢 ΔP 專利推演",
                        style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.bioGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.4), width: 0.5),
                ),
                child: Text(
                  "${bite.overallBiteScore} 分 · ${bite.biteLevel.substring(0, 2)}",
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.bioGold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 13, color: AppColors.bioGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    bite.primaryWindow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...bite.speciesIndices.map((s) => _buildSpeciesRow(s, isClassic)),
        ],
      ),
    );
  }

  Widget _buildSpeciesRow(SpeciesBiteIndex species, bool isClassic) {
    final bool isHot = species.biteProbability >= 80;
    final Color badgeColor = isHot ? AppColors.bioGold : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isClassic ? Colors.white : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClassic ? Colors.grey.shade200 : AppColors.glassBorder, 
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                species.speciesName,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    species.triggerReason,
                    style: TextStyle(
                      fontSize: 10,
                      color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${species.biteProbability}% ${species.statusBadge}",
                      style: TextStyle(color: badgeColor, fontSize: 9.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            species.tacticalTip,
            style: TextStyle(
              fontSize: 10.5,
              color: isClassic ? Colors.blueGrey.shade700 : AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
