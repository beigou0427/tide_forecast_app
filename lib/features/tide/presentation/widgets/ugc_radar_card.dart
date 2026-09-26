import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/ugc_report_model.dart';
import '../../providers/ugc_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../core/services/review_service.dart';
import '../../../../core/theme/app_theme.dart';

/// 🍏 Apple 首席設計工藝：深海聲吶實況雷達 (Oceanic Sonar Radar Telemetry)
class UgcRadarCard extends ConsumerWidget {
  final String stationId;
  final String stationName;
  final double? waveHeight;
  final double? windSpeed;

  const UgcRadarCard({
    super.key,
    required this.stationId,
    required this.stationName,
    this.waveHeight,
    this.windSpeed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(ugcReportProvider);
    final stationReports = ref.read(ugcReportProvider.notifier).getReportsForStation(
      stationId,
      waveHeight: waveHeight,
      windSpeed: windSpeed,
    );

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 頂部雷達標題與靈動回報按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.pelagicCyan.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar_rounded, color: AppColors.pelagicCyan, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Waze 現場海況雷達",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            "即時遙測",
                            style: TextStyle(fontSize: 10, color: AppColors.pelagicCyan, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text("釣友一線回報 · AI 哨兵同步巡邏", style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pelagicCyan,
                  foregroundColor: AppColors.abyssBlack,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_alert_rounded, size: 14),
                label: const Text("回報實況", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showQuickReportSheet(context, ref);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. 實況情報卡片流
          ...stationReports.take(3).map((report) => _buildReportTile(context, ref, report)),
        ],
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, WidgetRef ref, UgcReportItem report) {
    final diffMins = DateTime.now().difference(report.timestamp).inMinutes;
    final String timeStr = diffMins < 60 ? "$diffMins 分鐘前" : "${(diffMins / 60).floor()} 小時前";
    final bool isAiSentinel = report.userTag.contains("AI");
    final bool isVvip = report.userTag.contains("領航員") || report.userTag.contains("指揮官");

    // 🌟 階級感知光譜
    final Color accentColor = isVvip 
        ? AppColors.bioGold 
        : (isAiSentinel ? AppColors.pelagicCyan : const Color(0xFFFF9500));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 12, right: 6, top: 9, bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      report.label,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    if (!isAiSentinel) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Text(
                          isVvip ? "VVIP" : "實地", 
                          style: TextStyle(color: accentColor, fontSize: 8.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "$timeStr · 由 ${report.userTag} 通報",
                  style: TextStyle(fontSize: 10.5, color: accentColor.withValues(alpha: 0.85), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(ugcReportProvider.notifier).upvote(report.id);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.thumb_up_alt_rounded, size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        "${report.upvotes}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isAiSentinel)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 17, color: AppColors.textTertiary),
                  padding: EdgeInsets.zero,
                  color: AppColors.abyssCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.glassBorder, width: 0.5)),
                  onSelected: (value) {
                    HapticFeedback.selectionClick();
                    if (value == 'report') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已收到您的檢舉，審核團隊將於 24 小時內處理。"), backgroundColor: AppColors.abyssCard));
                    } else if (value == 'block') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已封鎖此用戶，將不再顯示其發佈的實況。"), backgroundColor: AppColors.abyssCard));
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: 'report', child: Text('檢舉不當內容', style: TextStyle(fontSize: 13, color: AppColors.hazardCoral, fontWeight: FontWeight.bold))),
                    const PopupMenuItem<String>(value: 'block', child: Text('封鎖此用戶', style: TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuickReportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.abyssCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bioGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.3), width: 0.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.monetization_on_rounded, color: AppColors.bioGold, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "🪙 實況互助獎勵：每日首次通報現場海況，即可獲得 5 枚「老船長幣」！",
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.bioGold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "一鍵通報 [$stationName] 現場水況",
                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.3),
              ),
              const SizedBox(height: 4),
              const Text("免打字單指通報，情報將即刻同步至全台釣友雷達", style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UgcConditionType.values.map((type) {
                  final dummyItem = UgcReportItem(id: '', stationId: '', timestamp: DateTime.now(), type: type);
                  return InkWell(
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      ref.read(ugcReportProvider.notifier).reportCondition(stationId, type);
                      
                      final prefs = await SharedPreferences.getInstance();
                      final lastRewardEpoch = prefs.getInt('last_coin_reward_epoch') ?? 0;
                      final nowEpoch = DateTime.now().millisecondsSinceEpoch;
                      final bool canClaimReward = (nowEpoch - lastRewardEpoch) > const Duration(hours: 24).inMilliseconds;

                      if (canClaimReward) {
                        await prefs.setInt('last_coin_reward_epoch', nowEpoch);
                        await ref.read(premiumProvider.notifier).addCoins(5);
                      }

                      if (ctx.mounted) Navigator.pop(ctx);

                      if (context.mounted) {
                        final currentCoins = ref.read(premiumProvider).coinBalance;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              canClaimReward 
                                ? "🎉 感謝通報【${dummyItem.label}】！已獲得 5 枚老船長幣 (餘額: $currentCoins 幣)"
                                : "🙏 感謝通報【${dummyItem.label}】！(今日已領取過代幣獎勵)"
                            ),
                            backgroundColor: canClaimReward ? AppColors.abyssSurface : AppColors.abyssCard,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        if (canClaimReward) {
                          ReviewService.onUgcRewarded();
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.glassBorder, width: 0.5),
                      ),
                      child: Text(
                        dummyItem.label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}