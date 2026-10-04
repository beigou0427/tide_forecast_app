import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/solunar_util.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🌟 Rich Hickey (Clojure 作者) 時態解構投影值實體 (Temporal Projection Value Object)
/// 數值完全不可變、純函數衍生、無隱含時鐘副作用
@immutable
class AstroHindcastProjection {
  final String dateStr;
  final String tideCategory;
  final String lunarDateStr;
  final int fishActivityScore;
  final String advice;

  const AstroHindcastProjection({
    required this.dateStr,
    required this.tideCategory,
    required this.lunarDateStr,
    required this.fishActivityScore,
    required this.advice,
  });

  /// 純函數衍生器：相同輸入恆得相同投影 (Deterministic & Idempotent)
  factory AstroHindcastProjection.fromTemporalDate(DateTime targetDate) {
    final solunar = SolunarUtil.calculate(targetDate);
    final formattedDate = DateFormat('yyyy/MM/dd').format(targetDate);

    return AstroHindcastProjection(
      dateStr: formattedDate,
      tideCategory: solunar.tideCategory,
      lunarDateStr: solunar.lunarDateStr,
      fishActivityScore: solunar.fishActivityScore,
      advice: solunar.biteWindowAdvice,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AstroHindcastProjection &&
          runtimeType == other.runtimeType &&
          dateStr == other.dateStr &&
          tideCategory == other.tideCategory &&
          lunarDateStr == other.lunarDateStr &&
          fishActivityScore == other.fishActivityScore &&
          advice == other.advice;

  @override
  int get hashCode => Object.hash(
        dateStr,
        tideCategory,
        lunarDateStr,
        fishActivityScore,
        advice,
      );
}

/// 🌟 純粹無副作用時態天文回溯展示卡
class AstroHindcastCard extends StatelessWidget {
  final DateTime selectedDate;
  final String stationName;
  final bool isClassic;

  const AstroHindcastCard({
    super.key,
    required this.selectedDate,
    required this.stationName,
    required this.isClassic,
  });

  @override
  Widget build(BuildContext context) {
    // 依據不可變時態輸入生成投影
    final projection = AstroHindcastProjection.fromTemporalDate(selectedDate);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bioGold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.bioGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${projection.dateStr} · 天文水文調和推算",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "此日期早於本地快取建立時間，已啟用天文物理補位",
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isClassic ? Colors.grey.shade200 : AppColors.glassBorder, 
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• 當日天體引力屬性：【${projection.tideCategory} (${projection.lunarDateStr})】",
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w700, 
                    color: isClassic ? const Color(0xFF023E8A) : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "• 魚群活躍指數推演：【${projection.fishActivityScore}%】",
                  style: const TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w700, 
                    color: AppColors.bioGold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "• 老船長出海戰術指引：${projection.advice}",
                  style: TextStyle(
                    fontSize: 11.5, 
                    color: isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "💡 提示：氣象署官方感測器原始電文僅暫存 48 小時。本系統現已啟動後端 30 天時間序列金庫，今後所有測站之浪高、風速與水溫將隨時間自動沉積，提供您完整的實測回溯。",
            style: TextStyle(
              fontSize: 10.5, 
              color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary, 
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}