import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ugc_report_model.dart';
import '../../providers/ugc_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../../shared/widgets/custom_card.dart';

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
    // 🌟 若無真人回報，自動由 AI 巡航哨兵依實況波高風速補位，絕不留白
    final stationReports = ref.read(ugcReportProvider.notifier).getReportsForStation(
      stationId,
      waveHeight: waveHeight,
      windSpeed: windSpeed,
    );

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar_rounded, color: Colors.deepOrange, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text("Waze 現場海況雷達", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(width: 6),
                          Text("實時情報", style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text("釣友一線回報 • AI 哨兵同步巡邏", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_alert_rounded, size: 14),
                label: const Text("回報實況", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _showQuickReportSheet(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...stationReports.take(3).map((report) => _buildReportTile(context, ref, report)),
        ],
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, WidgetRef ref, UgcReportItem report) {
    final diffMins = DateTime.now().difference(report.timestamp).inMinutes;
    final String timeStr = diffMins < 60 ? "$diffMins 分鐘前" : "${(diffMins / 60).floor()} 小時前";
    final bool isAiSentinel = report.userTag.contains("AI");

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAiSentinel ? const Color(0xFF0077B6).withValues(alpha: 0.03) : Colors.orange.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAiSentinel ? const Color(0xFF0077B6).withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.3),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF021B33)),
                    ),
                    if (!isAiSentinel) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(4)),
                        child: const Text("實地", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "$timeStr • 由 ${report.userTag} 通報",
                  style: TextStyle(fontSize: 10, color: isAiSentinel ? const Color(0xFF0077B6) : Colors.deepOrange.shade700),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => ref.read(ugcReportProvider.notifier).upvote(report.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isAiSentinel ? const Color(0xFF0077B6) : Colors.deepOrange).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.thumb_up_alt_rounded, size: 12, color: isAiSentinel ? const Color(0xFF0077B6) : Colors.deepOrange),
                  const SizedBox(width: 4),
                  Text(
                    "${report.upvotes}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isAiSentinel ? const Color(0xFF0077B6) : Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickReportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),

              // 🌟 利益激勵誘餌：回報即送 Pro 會員體驗
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "🎁 實況互助獎勵：通報 1 次現場海況，免費啟動 Pro 旗艦特權！",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text(
                "📢 一鍵回報 [$stationName] 現場實況",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF021B33)),
              ),
              const SizedBox(height: 4),
              Text("免打字單指通報，您的實況將即刻同步至全台釣友雷達", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UgcConditionType.values.map((type) {
                  final dummyItem = UgcReportItem(id: '', stationId: '', timestamp: DateTime.now(), type: type);
                  return InkWell(
                    onTap: () async {
                      ref.read(ugcReportProvider.notifier).reportCondition(stationId, type);
                      // 激勵回饋：通報後直接贈送 Pro 體驗
                      await ref.read(premiumProvider.notifier).setPremiumStatus(true, SubscriptionType.weekly);
                      if (ctx.mounted) Navigator.pop(ctx);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("🎉 感謝通報【${dummyItem.label}】！已為您啟動 Pro 旗艦特權以示感謝！"),
                            backgroundColor: Colors.deepOrange,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF021B33).withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        dummyItem.label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF021B33)),
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
