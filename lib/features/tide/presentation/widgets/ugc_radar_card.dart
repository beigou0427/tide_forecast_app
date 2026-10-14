import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/ugc_report_model.dart';
import '../../providers/ugc_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../core/theme/app_theme.dart';

/// 🌟 經海事與增長駭客重塑之 UGC 雷達卡 (UGC Radar Card)
/// 100% 商業金流與資料潔淨防禦版：
/// 1. 實裝 30 分鐘冷卻時間 (Cooldown)，徹底杜絕假情報洗版與資料毒化！
/// 2. 封殺無限白嫖漏洞：首交通報送 7 天 PRO，後續自動降級為發放「老船長代幣」。
/// 3. 【銷冠優化】VVIP 綠色通道：年度/終身指揮官豁免 30 分鐘冷卻，享有無限開火權！
class UgcRadarCard extends ConsumerStatefulWidget {
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
  ConsumerState<UgcRadarCard> createState() => _UgcRadarCardState();
}

class _UgcRadarCardState extends ConsumerState<UgcRadarCard> {
  bool _hasClaimedPro = false;

  @override
  void initState() {
    super.initState();
    _loadRewardStatus();
  }

  Future<void> _loadRewardStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _hasClaimedPro = prefs.getBool('has_claimed_ugc_pro_reward') ?? false;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ugcReportProvider);
    // 🌟 若無真人回報，自動由 AI 巡航哨兵依實況波高風速補位，絕不留白
    final stationReports = ref.read(ugcReportProvider.notifier).getReportsForStation(
      widget.stationId,
      waveHeight: widget.waveHeight,
      windSpeed: widget.windSpeed,
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
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(ugcReportProvider.notifier).upvote(report.id);
            },
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
    HapticFeedback.mediumImpact();
    
    final premium = ref.read(premiumProvider);
    final bool isVvip = premium.isFounder || premium.type == SubscriptionType.yearly || premium.type == SubscriptionType.lifetime;

    // 🌟 PM 核心：根據用戶「身分階級」動態變化文案，賦予最高尊榮感！
    final String bannerText;
    final Color bannerColor;
    final IconData bannerIcon;
    final Color bannerTextColor;

    if (isVvip) {
      bannerText = "⚓ 航海家特權：無冷卻時間，實況直通全台雷達！";
      bannerColor = AppColors.bioGold;
      bannerIcon = Icons.military_tech_rounded;
      bannerTextColor = const Color(0xFF3D2605);
    } else if (_hasClaimedPro) {
      bannerText = "🪙 實況互助獎勵：通報即賺 5 枚老船長代幣！";
      bannerColor = Colors.teal;
      bannerIcon = Icons.monetization_on_rounded;
      bannerTextColor = const Color(0xFF004D40);
    } else {
      bannerText = "🎁 實況互助獎勵：首交通報，免費啟動 7 天 Pro 旗艦特權！";
      bannerColor = Colors.amber;
      bannerIcon = Icons.workspace_premium_rounded;
      bannerTextColor = const Color(0xFF5D4037);
    }

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

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bannerColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: bannerColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(bannerIcon, color: bannerColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bannerText,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: bannerTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text(
                "📢 一鍵回報 [${widget.stationName}] 現場實況",
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
                      HapticFeedback.lightImpact();
                      
                      final prefs = await SharedPreferences.getInstance();
                      final lastTime = prefs.getInt('last_ugc_report_time') ?? 0;
                      final nowMs = DateTime.now().millisecondsSinceEpoch;

                      // 🚨 銷冠防護網：VVIP 擁有特權，直接 bypass 30 分鐘冷卻時間！
                      if (!isVvip && (nowMs - lastTime < 1800000)) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("⏳ 雷達冷卻中：為維持情報品質，請等待 30 分鐘後再發布新實況！"),
                              backgroundColor: Colors.blueGrey,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return;
                      }

                      await prefs.setInt('last_ugc_report_time', nowMs);
                      
                      // 🌟 使用正規方法呼叫，杜絕 Riverpod .state 越權編譯報錯！
                      ref.read(ugcReportProvider.notifier).reportCondition(widget.stationId, type);

                      // VVIP 專屬回饋
                      if (isVvip) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("👑 指揮官，已發布您的特權戰報！"),
                              backgroundColor: AppColors.bioGold,
                              duration: Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return;
                      }

                      // 一般用戶獎勵發放邏輯
                      if (!_hasClaimedPro) {
                        await prefs.setBool('has_claimed_ugc_pro_reward', true);
                        await ref.read(premiumProvider.notifier).setPremiumStatus(true, SubscriptionType.weekly);
                        if (mounted) setState(() => _hasClaimedPro = true);
                        
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("🎉 感謝通報！首交獎勵：已為您啟動 7 天 Pro 旗艦特權！"),
                              backgroundColor: Colors.deepOrange,
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        await ref.read(premiumProvider.notifier).addCoins(5);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("🪙 感謝通報！已發放 5 枚老船長代幣！"),
                              backgroundColor: Colors.teal,
                              duration: Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
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
