import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bite_prediction_engine.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/tide_model.dart';
import '../../../premium/services/premium_service.dart';
import '../../../premium/presentation/premium_page.dart';

/// 🌟 經海事與水產生物學標準重塑之魚種索餌活性雷達
/// 融合 Sean Ellis「AHA Moment 價值先行」與 von Cramon「受眾精準引流」架構
class BiteRadarSection extends ConsumerStatefulWidget {
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
  ConsumerState<BiteRadarSection> createState() => _BiteRadarSectionState();
}

class _BiteRadarSectionState extends ConsumerState<BiteRadarSection> {
  // 🌟 John Carmack 記憶化計算快取：當觀測資料與日期未變時，0 重複計算開銷
  BitePredictionResult? _cachedBiteResult;
  DateTime? _lastTargetDate;
  int _lastObsCount = 0;
  DateTime? _lastObsTime;

  @override
  void initState() {
    super.initState();
    _recomputeProjectionIfNeeded();
  }

  @override
  void didUpdateWidget(covariant BiteRadarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeProjectionIfNeeded();
  }

  void _recomputeProjectionIfNeeded() {
    final obs = widget.station.observations;
    final DateTime? currentLatestTime = obs.isNotEmpty ? obs.last.dateTime : null;

    if (_cachedBiteResult != null &&
        _lastTargetDate == widget.selectedDate &&
        _lastObsCount == obs.length &&
        _lastObsTime == currentLatestTime) {
      return;
    }

    _lastTargetDate = widget.selectedDate;
    _lastObsCount = obs.length;
    _lastObsTime = currentLatestTime;

    _cachedBiteResult = BitePredictionEngine.predict(
      stationData: widget.station, 
      targetDate: widget.selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(premiumProvider.select((s) => s.isPremium || s.isFounder));
    final bite = _cachedBiteResult ?? BitePredictionEngine.predict(
      stationData: widget.station, 
      targetDate: widget.selectedDate,
    );
    final Color titleColor = widget.isClassic ? const Color(0xFF023E8A) : AppColors.textPrimary;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頂部活性總評
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "指標魚種活性與索餌推演",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "海溫躍層 ΔT · 氣壓走勢 ΔP · 潮目起流指標",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.bioGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.4), width: 0.5),
                ),
                child: Text(
                  "${bite.overallBiteScore} 分 · ${bite.biteLevel}",
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.bioGold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 起流黃金窗口提示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.04),
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
                      color: widget.isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sean Ellis: 價值先行，免費用戶看見第 1 種魚（證明物理演算法真實性）
          if (isPro) ...[
            ...bite.speciesIndices.map((s) => _buildSpeciesRow(s, widget.isClassic)),
          ] else ...[
            if (bite.speciesIndices.isNotEmpty)
              _buildSpeciesRow(bite.speciesIndices.first, widget.isClassic),
            const SizedBox(height: 6),
            // 其餘 3 種魚以半透微光引流卡呈現 (附帶受眾痛點對比)
            _buildLockedSpeciesTeaser(context, widget.isClassic, bite.speciesIndices.skip(1).toList()),
          ],
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

  Widget _buildLockedSpeciesTeaser(BuildContext context, bool isClassic, List<SpeciesBiteIndex> lockedSpecies) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bioGold.withValues(alpha: isClassic ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.bioGold.withValues(alpha: 0.35), 
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頂部引流抬頭
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.bioGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "解鎖老船長 PRO · 掌握三大專項水文指標：",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: isClassic ? const Color(0xFFB45309) : AppColors.bioGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 半透預覽專項受眾痛點條列 (von Cramon CPP 策略)
          _buildLockedTeaserItem("🦑 軟絲 · 透抽 (岸拋木蝦/夜釣)", "近岸澄澈微流窗口 · 小潮平水抱餌時段分析", isClassic),
          _buildLockedTeaserItem("🎯 紅甘 · 煙仔虎 (岸拋鐵板/船釣)", "天文大潮活水急流 · 氣壓降壓靠岸掠食衝擊線", isClassic),
          _buildLockedTeaserItem("🦀 黑鯛 · 石斑 (前打/港區沉底)", "推浪拍岸捲底誘餌分析 · 底層障礙物開口時程", isClassic),

          const SizedBox(height: 12),

          // 零退費防禦標示 (降低心理摩擦)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isClassic ? 0.6 : 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, size: 12, color: Color(0xFF30D158)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "年度方案享 7 天免費試用，隨時可於 Apple ID 輕鬆取消，支援家人共享",
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // CTA 轉換按鈕
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bioGold,
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.bolt_rounded, size: 16),
              label: const Text(
                "開啟 7 天免費試用 · 解鎖全指標魚種",
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage()));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedTeaserItem(String title, String desc, bool isClassic) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.bioGold),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary,
                  height: 1.35,
                ),
                children: [
                  TextSpan(text: "$title：", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}