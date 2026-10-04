import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/ugc_report_model.dart';
import '../../providers/ugc_provider.dart';
import '../../providers/tide_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../core/services/review_service.dart';
import '../../../../core/theme/app_theme.dart';

/// 🌟 具備「颱風/巨浪海事物理熔斷」之 Waze 現場雷達卡
/// 極端危險海況下強制封殺「魚群大咬」與「比預報平穩」，杜絕誘惑出海引發人命傷亡
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
  final Set<String> _blockedAuthors = {};

  @override
  void initState() {
    super.initState();
    _loadBlockedAuthors();
  }

  Future<void> _loadBlockedAuthors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('blocked_ugc_authors') ?? [];
      if (mounted) {
        setState(() {
          _blockedAuthors.addAll(list);
        });
      }
    } catch (_) {}
  }

  Future<void> _blockAuthor(String authorTag) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _blockedAuthors.add(authorTag);
    });
    await prefs.setStringList('blocked_ugc_authors', _blockedAuthors.toList());
  }

  Future<void> _submitReportTicket(UgcReportItem report, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('ugc_moderation_queue').add({
        'report_id': report.id,
        'station_id': report.stationId,
        'condition_label': report.label,
        'author_tag': report.userTag,
        'reported_timestamp': report.timestamp.toIso8601String(),
        'reason': reason,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'PENDING_REVIEW',
      });
      debugPrint("🛡️ [UGC 信任審查] 檢舉工單已安全遞交至審核隊列 (ID: ${report.id})");
    } catch (e) {
      debugPrint("⚠️ [UGC 信任審查] 檢舉寫入異常: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ugcReportProvider);
    final allStationReports = ref.read(ugcReportProvider.notifier).getReportsForStation(
      widget.stationId,
      waveHeight: widget.waveHeight,
      windSpeed: widget.windSpeed,
    );

    final visibleReports = allStationReports
        .where((r) => !_blockedAuthors.contains(r.userTag))
        .toList();

    return CustomCard(
      padding: const EdgeInsets.all(20),
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
                            "現場防偽認證",
                            style: TextStyle(fontSize: 10, color: AppColors.pelagicCyan, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text("GPS 實證釣友 · 海事安全物理守衛", style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary)),
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

          ...visibleReports.take(3).map((report) => _buildReportTile(context, ref, report)),
        ],
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, WidgetRef ref, UgcReportItem report) {
    final diffMins = DateTime.now().difference(report.timestamp).inMinutes;
    final String timeStr = diffMins < 60 ? "$diffMins 分鐘前" : "${(diffMins / 60).floor()} 小時前";
    final bool isAiSentinel = report.userTag.contains("AI");
    final bool isVerifiedOnSite = report.userTag.contains("現場實證") || report.userTag.contains("現場認證");
    final bool isVvip = report.userTag.contains("領航員") || report.userTag.contains("指揮官");

    final Color accentColor = isVvip 
        ? AppColors.bioGold 
        : (isVerifiedOnSite ? const Color(0xFF30D158) : (isAiSentinel ? AppColors.pelagicCyan : const Color(0xFFFF9500)));

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
                          isVerifiedOnSite ? "📍 現場實證" : (isVvip ? "👑 VVIP" : "遠端通報"), 
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
                  onSelected: (value) async {
                    HapticFeedback.selectionClick();
                    if (value == 'report') {
                      await _submitReportTicket(report, "用戶於前端標記不實海象或不當內容");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("🛡️ 檢舉工單已立案，審核團隊將於 24 小時內完成處理。"), 
                            backgroundColor: AppColors.abyssCard,
                          ),
                        );
                      }
                    } else if (value == 'block') {
                      await _blockAuthor(report.userTag);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("🚫 已封鎖【${report.userTag}】，已為您即時隱藏其所有通報內容。"), 
                            backgroundColor: AppColors.abyssCard,
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'report', 
                      child: Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 16, color: AppColors.hazardCoral),
                          SizedBox(width: 8),
                          Text('檢舉不當/虛假情報', style: TextStyle(fontSize: 12.5, color: AppColors.hazardCoral, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'block', 
                      child: Row(
                        children: [
                          Icon(Icons.block_rounded, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('封鎖此通報者', style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuickReportSheet(BuildContext context, WidgetRef ref) {
    final userPos = ref.read(userLocationProvider).value;
    final tideView = ref.read(tideViewDataProvider).value;
    bool isOnSite = false;

    if (userPos != null && tideView != null) {
      final sLat = double.tryParse(tideView.stationData.info.lat);
      final sLng = double.tryParse(tideView.stationData.info.lng);
      if (sLat != null && sLng != null) {
        final double dist = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, sLat, sLng) / 1000.0;
        if (dist <= 15.0) {
          isOnSite = true;
        }
      }
    }

    // 🌟 海事物理熔斷防線：實測大浪 >= 2.5m 或 強風 >= 11m/s 時，判定為極端危險/颱風天
    final double currentWave = widget.waveHeight ?? 0.0;
    final double currentWind = widget.windSpeed ?? 0.0;
    final bool isExtremeDanger = currentWave >= 2.5 || currentWind >= 11.0;

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

              // 🌟 颱風巨浪物理熔斷警戒橫幅
              if (isExtremeDanger) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.hazardCoral.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.hazardCoral.withValues(alpha: 0.5), width: 1.0),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.dangerous_rounded, color: AppColors.hazardCoral, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "🚨 颱風/巨浪安全熔斷生效中！現場海象極度兇險，系統已強制鎖定所有「誘惑出海」之樂觀選項！",
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.hazardCoral, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOnSite ? const Color(0xFF30D158).withValues(alpha: 0.12) : AppColors.bioGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isOnSite ? const Color(0xFF30D158).withValues(alpha: 0.3) : AppColors.bioGold.withValues(alpha: 0.3), 
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOnSite ? Icons.verified_rounded : Icons.cell_tower_rounded, 
                        color: isOnSite ? const Color(0xFF30D158) : AppColors.bioGold, 
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isOnSite
                              ? "📍 GPS 判定您在測站現場（15km內）！本次回報將加冠「現場實證」標章並發放 5 枚代幣！"
                              : "📡 您目前距測站較遠，將以「遠端通報」標記發布，共同維護海況真實性。",
                          style: TextStyle(
                            fontSize: 11.5, 
                            fontWeight: FontWeight.w700, 
                            color: isOnSite ? const Color(0xFF30D158) : AppColors.bioGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                "一鍵通報 [${widget.stationName}] 現場水況",
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
                  
                  // 🌟 海事安全物理熔斷邏輯：颱風巨浪時，嚴禁通報「大咬」或「平穩」！
                  final bool isForbiddenInTyphoon = isExtremeDanger && 
                      (type == UgcConditionType.fishBiting || type == UgcConditionType.waveCalm);

                  return InkWell(
                    onTap: () async {
                      if (isForbiddenInTyphoon) {
                        HapticFeedback.vibrate();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("🚨 警告：當前浪高/風速已達危險警戒上限！嚴禁發布誤導性出海通報！生命安全第一！"),
                            backgroundColor: AppColors.hazardCoral,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }

                      HapticFeedback.mediumImpact();
                      
                      ref.read(ugcReportProvider.notifier).reportCondition(widget.stationId, type);
                      
                      final prefs = await SharedPreferences.getInstance();
                      final lastRewardEpoch = prefs.getInt('last_coin_reward_epoch') ?? 0;
                      final nowEpoch = DateTime.now().millisecondsSinceEpoch;
                      final bool canClaimReward = (nowEpoch - lastRewardEpoch) > const Duration(hours: 24).inMilliseconds;

                      if (canClaimReward && isOnSite && !isExtremeDanger) {
                        await prefs.setInt('last_coin_reward_epoch', nowEpoch);
                        await ref.read(premiumProvider.notifier).addCoins(5);
                      }

                      if (ctx.mounted) Navigator.pop(ctx);

                      if (context.mounted) {
                        final currentCoins = ref.read(premiumProvider).coinBalance;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isOnSite && canClaimReward
                                ? "🎉 感謝現場實證通報【${dummyItem.label}】！已獲贈 5 枚老船長幣 (餘額: $currentCoins 幣)"
                                : "🙏 感謝通報【${dummyItem.label}】！感謝您為全台釣友貢獻情報！"
                            ),
                            backgroundColor: isOnSite ? const Color(0xFF0077B6) : AppColors.abyssCard,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        if (isOnSite && canClaimReward) {
                          ReviewService.onUgcRewarded();
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isForbiddenInTyphoon 
                            ? Colors.white.withValues(alpha: 0.02) 
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isForbiddenInTyphoon ? Colors.white10 : AppColors.glassBorder, 
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isForbiddenInTyphoon) ...[
                            const Icon(Icons.lock_rounded, size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            dummyItem.label,
                            style: TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.w700, 
                              color: isForbiddenInTyphoon ? AppColors.textTertiary : AppColors.textPrimary,
                              decoration: isForbiddenInTyphoon ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                "⚠️ 社群信任公約：依據海事防衛規範，嚴禁發布虛假危險海況、違規廣告或不當言論。違規通報經審核確認將立即刪除並永久封鎖通報權限。",
                style: TextStyle(fontSize: 10, color: AppColors.textTertiary, height: 1.35),
              ),
            ],
          ),
        );
      },
    );
  }
}
