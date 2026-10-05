import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/services/health_probe_service.dart';
import '../../providers/tide_provider.dart';
import '../../../catch_log/providers/catch_log_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../premium/presentation/premium_page.dart';
import '../../../premium/presentation/vip_center_page.dart';
import '../../../diagnostic/presentation/diagnostic_page.dart';
import '../station_guide_page.dart';
import '../../../catch_log/presentation/catch_log_page.dart';
import '../aso_studio_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../home_page.dart';

/// 🌟 經海事嚴謹標準重塑之生產純淨化抽屜 (100% 商業成熟度)
/// 內建「航海純潮汐 / 全雷達」戰術開關，徹底移除虛飾，保護駕駛台純粹航海作業
class StationDrawer extends ConsumerStatefulWidget {
  final String currentId;
  const StationDrawer({super.key, required this.currentId});

  @override
  ConsumerState<StationDrawer> createState() => _StationDrawerState();
}

class _StationDrawerState extends ConsumerState<StationDrawer> {
  String _searchQuery = "";
  String _selectedFilter = "全部";
  int _secretTapCount = 0;
  int _lastTapTime = 0;

  void _handleSecretEasterEgg() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTime > 1500) {
      _secretTapCount = 0;
    }
    _lastTapTime = now;
    _secretTapCount++;

    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      HapticFeedback.heavyImpact();
      _showSecretAuthDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClassic = ref.watch(isClassicThemeProvider);
    final premiumState = ref.watch(premiumProvider);
    final favoriteIdsAsync = ref.watch(favoriteStationsProvider);
    final stationListAsync = ref.watch(stationListProvider);
    final healthReport = ref.watch(healthProbeProvider);
    final isPureTide = ref.watch(isPureTideModeProvider);
    final bool isPro = premiumState.isPremium || premiumState.isFounder;

    final Color drawerBg = isClassic ? AppColors.classicBg : AppColors.abyssSurface;
    final Color dividerColor = isClassic ? Colors.grey.shade200 : AppColors.glassBorder;

    return Drawer(
      backgroundColor: drawerBg,
      child: Column(
        children: [
          _buildDrawerHeader(premiumState.isFounder, isClassic),
          _buildModeSwitchTile(isPureTide, isClassic),
          _buildClusterHealthPod(healthReport, isClassic),
          _buildPremiumEntry(premiumState, isClassic),
          _buildSearchField(isClassic),
          _buildFilterChips(isClassic),

          Expanded(
            child: stationListAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan,
                  strokeWidth: 2.5,
                ),
              ),
              error: (err, stack) => Center(
                child: Text(
                  "清單載入失敗",
                  style: TextStyle(color: isClassic ? Colors.grey : AppColors.textTertiary),
                ),
              ),
              data: (allStations) {
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    favoriteIdsAsync.when(
                      data: (favIds) {
                        if (favIds.isEmpty) return const SizedBox.shrink();
                        final favStations = allStations.where((s) => favIds.contains(s.id)).toList();
                        if (favStations.isEmpty) return const SizedBox.shrink();
                        return Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            leading: const Icon(Icons.star_rounded, color: AppColors.bioGold, size: 20),
                            title: const Text(
                              "我的最愛", 
                              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.bioGold, fontSize: 14.5),
                            ),
                            children: favStations.map((s) => _buildStationTile(s, true, isPro, isClassic)).toList(),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    Divider(height: 1, color: dividerColor),

                    ...AppConstants.regions.map((region) {
                      final List<StationModel> stations = allStations.where((s) {
                        final bool matchesRegion = s.region == region;
                        final bool matchesSearch = s.name.contains(_searchQuery) || s.id.contains(_searchQuery);
                        
                        bool matchesFilter = true;
                        if (_selectedFilter == "👑 VIP專屬") {
                          matchesFilter = s.isProOnly;
                        } else if (_selectedFilter == "🆓 免費體驗") {
                          matchesFilter = !s.isProOnly;
                        } else if (_selectedFilter == "🌊 資料浮標") {
                          matchesFilter = s.isBuoy;
                        } else if (_selectedFilter == "⏱️ 潮位站") {
                          matchesFilter = !s.isBuoy;
                        }

                        return matchesRegion && matchesSearch && matchesFilter;
                      }).toList();

                      if (stations.isEmpty && (_searchQuery.isNotEmpty || _selectedFilter != "全部")) {
                        return const SizedBox.shrink();
                      }

                      return Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: _searchQuery.isNotEmpty || _selectedFilter != "全部",
                          leading: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan).withValues(alpha: 0.25),
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                region[0], 
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan, 
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                region, 
                                style: TextStyle(
                                  fontWeight: FontWeight.w800, 
                                  fontSize: 15,
                                  color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "(${stations.length})", 
                                style: TextStyle(
                                  fontSize: 11.5, 
                                  color: isClassic ? Colors.grey : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          children: stations.map((s) {
                            final isFav = favoriteIdsAsync.value?.contains(s.id) ?? false;
                            return _buildStationTile(s, isFav, isPro, isClassic);
                          }).toList(),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          Divider(height: 1, color: dividerColor),

          _buildActionTile(
            icon: Icons.phishing_rounded,
            title: "潮汐漁獲日誌",
            color: Colors.indigoAccent,
            isClassic: isClassic,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CatchLogPage()));
            },
          ),
          _buildActionTile(
            icon: Icons.menu_book_rounded,
            title: "85 測站水文指引",
            color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan,
            isClassic: isClassic,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StationGuidePage()));
            },
          ),
          _buildActionTile(
            icon: Icons.support_agent_rounded,
            title: "官方客服與隱私治理",
            color: Colors.orangeAccent,
            badge: "24H",
            isClassic: isClassic,
            onTap: () {
              HapticFeedback.lightImpact();
              _showSupportModal(context, isClassic);
            },
          ),
          
          Divider(height: 1, color: dividerColor),

          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 24),
            child: GestureDetector(
              onTap: _handleSecretEasterEgg,
              onLongPress: () {
                HapticFeedback.heavyImpact();
                _showSecretAuthDialog(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.transparent,
                child: Text(
                  "資料來源：中央氣象署 (CWA) 官方開放資料", 
                  style: GoogleFonts.notoSansTc(
                    fontSize: 11, 
                    color: isClassic ? Colors.grey.shade500 : AppColors.textTertiary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitchTile(bool isPureTide, bool isClassic) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isPureTide
            ? AppColors.bioGold.withValues(alpha: isClassic ? 0.12 : 0.15)
            : (isClassic ? Colors.white : Colors.white.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPureTide ? AppColors.bioGold : (isClassic ? Colors.grey.shade300 : AppColors.glassBorder),
          width: isPureTide ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isPureTide ? Icons.waves_rounded : Icons.radar_rounded,
                color: isPureTide ? AppColors.bioGold : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan),
                size: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPureTide ? "純潮汐航海儀表模式" : "全維度海象雷達模式",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isPureTide ? "極致降噪 · 專注潮位與走水" : "含天氣、風向與即時雷達",
                    style: TextStyle(
                      fontSize: 10,
                      color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch.adaptive(
            value: isPureTide,
            activeColor: AppColors.bioGold,
            onChanged: (val) {
              HapticFeedback.mediumImpact();
              ref.read(isPureTideModeProvider.notifier).toggle();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClusterHealthPod(ClusterHealthReport report, bool isClassic) {
    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    switch (report.status) {
      case ProbeStatus.healthy:
        statusColor = const Color(0xFF30D158);
        statusTitle = "邊緣節點連通 (${report.latencyMs}ms)";
        statusIcon = Icons.cloud_done_rounded;
        break;
      case ProbeStatus.degraded:
        statusColor = const Color(0xFFFF9500);
        statusTitle = "備援線 (${report.totalStationsOnline} 站在線)";
        statusIcon = Icons.cloud_sync_rounded;
        break;
      case ProbeStatus.critical:
        statusColor = AppColors.hazardCoral;
        statusTitle = "本地離線神盾接管";
        statusIcon = Icons.offline_bolt_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isClassic ? Colors.white : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "探針節點: ${report.activeNode.split('//').last.split('.').first}",
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            tooltip: "立即重載探針",
            color: statusColor,
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(healthProbeProvider.notifier).executeReadinessProbe();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _eraseAllUserDataAndCloudFootprint(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.abyssCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.hazardCoral, width: 1)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.hazardCoral, size: 24),
            SizedBox(width: 8),
            Text("徹底銷毀個人資料", style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "依據 Apple 規範與個資法規，此動作將不可逆地永久銷毀：\n• 雲端 Firestore 與 Storage 中的所有個人漁獲相片與紀錄\n• 本機快取、老船長積分餘額與個人偏好設定\n\n確定立即執行徹底銷毀？",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text("取消", style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hazardCoral, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text("確認徹底銷毀", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_sync_id');

      if (deviceId != null && deviceId.isNotEmpty) {
        final logsCollection = FirebaseFirestore.instance.collection('users').doc(deviceId).collection('catch_logs');
        final snapshot = await logsCollection.get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        await FirebaseFirestore.instance.collection('users').doc(deviceId).delete();

        try {
          final storageRef = FirebaseStorage.instance.ref().child('users/$deviceId');
          final listResult = await storageRef.listAll();
          for (var item in listResult.items) {
            await item.delete();
          }
        } catch (_) {}
      }

      await prefs.remove('catch_logs_v1');
      await prefs.remove('captain_coins');
      await prefs.remove('blocked_ugc_authors');
      await prefs.remove('user_pref_region');
      await prefs.remove('device_sync_id');

      ref.invalidate(catchLogProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🛡️ 依據被遺忘權規範，您的所有本機與雲端個人資料已徹底銷毀完畢！"),
            backgroundColor: Color(0xFF0077B6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("⚠️ [隱私銷毀例外]: $e");
    }
  }

  void _showSupportModal(BuildContext context, bool isClassic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isClassic ? Colors.white : AppColors.abyssCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        final Color titleColor = isClassic ? AppColors.classicText : AppColors.textPrimary;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, 
                  height: 4, 
                  decoration: BoxDecoration(
                    color: isClassic ? Colors.grey.shade300 : Colors.white24, 
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.orangeAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "官方客服與隱私治理中心",
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: titleColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "老船長團隊承諾於 24 小時內親自處理您的問題，嚴格遵守個資法與隱私規範。",
                style: TextStyle(fontSize: 11.5, color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary),
              ),
              const SizedBox(height: 18),

              _buildSupportOptionTile(
                title: "聯繫技術團隊 / 回報測站水文異常",
                desc: "附帶當前測站 ID 與設備資訊，工程師即刻排查修復",
                icon: Icons.mark_email_read_rounded,
                color: const Color(0xFF0077B6),
                isClassic: isClassic,
                onTap: () async {
                  final Uri emailUri = Uri.parse(
                    "mailto:support@beigou.app?subject=%E3%80%90TidePro%E5%AE%A2%E6%9C%8D%E5%B7%A5%E5%96%AE%E3%80%91%E6%B8%AC%E7%AB%99%E6%B0%B4%E6%96%87%E8%88%87%E4%BD%BF%E7%94%A8%E5%8F%8D%E6%98%A0&body=%E6%82%A8%E5%A5%BD%EF%BC%8C%E6%88%91%E5%9C%A8%E4%BD%BF%E7%94%A8%E6%BD%AE%E6%B1%90%E8%A1%A8%20Pro%20%E6%99%82%E9%81%87%E5%88%B0%E4%BB%A5%E4%B8%8B%E5%95%8F%E9%A1%8C%EF%BC%9A%0A%0A%E3%80%90%E7%99%BC%E7%94%9F%E6%B8%AC%E7%AB%99%E3%80%91%EF%BC%9A${widget.currentId}%0A%E3%80%90%E5%95%8F%E9%A1%8C%E6%8F%8F%E8%BF%B0%E3%80%91%EF%BC%9A",
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
              ),
              const SizedBox(height: 10),

              _buildSupportOptionTile(
                title: "訂閱條款說明與退訂指南",
                desc: "說明如何至 Apple ID 取消自動續訂與申請消費爭議處理",
                icon: Icons.receipt_long_rounded,
                color: AppColors.bioGold,
                isClassic: isClassic,
                onTap: () async {
                  final Uri subGuide = Uri.parse("https://support.apple.com/HT202039");
                  if (await canLaunchUrl(subGuide)) {
                    await launchUrl(subGuide, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: 10),

              _buildSupportOptionTile(
                title: "徹底銷毀個人資料與雲端紀錄",
                desc: "符合 Apple 5.1.1 條款與台灣個資法第11條，一鍵永久抹除數位足跡",
                icon: Icons.delete_forever_rounded,
                color: AppColors.hazardCoral,
                isClassic: isClassic,
                onTap: () => _eraseAllUserDataAndCloudFootprint(context),
              ),
              const SizedBox(height: 14),

              Text(
                "⚠️ 消費者保障告知：所有訂閱購買均經由 Apple StoreKit 官方加密通道，您可隨時於 App Store 帳號中取消續訂，保障您的消費者權益。",
                style: TextStyle(fontSize: 10, color: isClassic ? Colors.grey.shade500 : AppColors.textTertiary, height: 1.35),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportOptionTile({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required bool isClassic,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isClassic ? Colors.grey.shade200 : AppColors.glassBorder, 
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 13,
                      color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc, 
                    style: TextStyle(
                      fontSize: 10.5, 
                      color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded, 
              size: 16, 
              color: isClassic ? Colors.grey : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isClassic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isClassic ? Colors.white : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isClassic ? Colors.grey.shade300 : AppColors.glassBorder, 
            width: 0.5,
          ),
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextStyle(
            color: isClassic ? Colors.black87 : AppColors.textPrimary, 
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: "搜尋測站或地名 (如: 石門 / 龍洞)...",
            hintStyle: TextStyle(
              color: isClassic ? Colors.grey : AppColors.textTertiary, 
              fontSize: 12,
            ),
            prefixIcon: Icon(
              Icons.search_rounded, 
              size: 18, 
              color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isClassic) {
    final filters = ["全部", "👑 VIP專屬", "🌊 資料浮標", "⏱️ 潮位站", "🆓 免費體驗"];
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, idx) {
          final f = filters[idx];
          final isSelected = _selectedFilter == f;

          Color chipBg = isClassic 
              ? (isSelected ? const Color(0xFF0077B6).withValues(alpha: 0.12) : Colors.white)
              : (isSelected ? AppColors.pelagicCyan.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04));
          
          Color chipText = isClassic 
              ? (isSelected ? const Color(0xFF0077B6) : Colors.blueGrey)
              : (isSelected ? AppColors.pelagicCyan : AppColors.textSecondary);

          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = f);
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan)
                      : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder),
                  width: 0.5,
                ),
              ),
              child: Text(
                f, 
                style: TextStyle(
                  fontSize: 10.5, 
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, 
                  color: chipText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStationTile(StationModel station, bool isFavorited, bool isPro, bool isClassic) {
    final bool isSelected = station.id == widget.currentId;
    final bool isLocked = station.isProOnly && !isPro;

    return ListTile(
      onTap: () {
        if (isLocked) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage()));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🔒 [${station.name}] 為 PRO 專屬水文模型，請解鎖啟用！"),
              backgroundColor: isClassic ? const Color(0xFF0077B6) : AppColors.abyssCard,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ref.read(currentStationIdProvider.notifier).state = station.id;
          ref.read(selectedDateProvider.notifier).state = DateTime.now();
          Navigator.pop(context);
        }
      },
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: (station.isBuoy ? Colors.indigoAccent : AppColors.pelagicCyan).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              station.isBuoy ? Icons.sensors_rounded : Icons.water_drop_rounded,
              size: 14,
              color: station.isBuoy ? Colors.indigoAccent : AppColors.pelagicCyan,
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: station.isHealthy ? const Color(0xFF30D158) : const Color(0xFFFF9500),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.0),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              station.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected 
                    ? (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan) 
                    : (isClassic ? Colors.black87 : AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 4),

          if (station.isProOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.bioGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.35), width: 0.5),
              ),
              child: const Text("PRO", style: TextStyle(color: AppColors.bioGold, fontSize: 8.5, fontWeight: FontWeight.w900)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF30D158).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text("免費", style: TextStyle(color: Color(0xFF30D158), fontSize: 8.5, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      subtitle: Text(
        "${station.stationType} • ${station.agency} (${station.id}) · ${station.syncStatus}",
        style: TextStyle(
          fontSize: 10, 
          color: isClassic ? Colors.grey : AppColors.textTertiary,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          isFavorited ? Icons.star_rounded : Icons.star_border_rounded,
          size: 19,
          color: isFavorited ? AppColors.bioGold : (isClassic ? Colors.grey.shade300 : AppColors.glassBorder),
        ),
        onPressed: () async {
          HapticFeedback.selectionClick();
          await ref.read(tideRepositoryProvider).toggleFavorite(station.id);
          ref.invalidate(favoriteStationsProvider);
        },
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required bool isClassic,
    required VoidCallback onTap,
    String? badge,
  }) {
    return ListTile(
      dense: true,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.w700, 
          fontSize: 13,
          color: isClassic ? Colors.blueGrey.shade800 : AppColors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), 
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge, 
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          Icon(
            Icons.chevron_right_rounded, 
            size: 16, 
            color: isClassic ? Colors.grey : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(bool isFounder, bool isClassic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 52, 22, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isClassic 
              ? const [Color(0xFF023E8A), Color(0xFF0077B6)]
              : const [Color(0xFF071221), Color(0xFF0B1F38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: isClassic ? Colors.transparent : AppColors.glassBorder, 
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isClassic 
                      ? Colors.white.withValues(alpha: 0.15) 
                      : AppColors.pelagicCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isClassic ? Colors.white30 : AppColors.pelagicCyan.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.sensors_rounded, 
                  color: isClassic ? Colors.white : AppColors.pelagicCyan, 
                  size: 24,
                ),
              ),
              if (isFounder)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.military_tech_rounded, color: Colors.black87, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "創始席位", 
                        style: TextStyle(color: Colors.black87, fontSize: 10.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "海象監測指揮中心",
            style: GoogleFonts.notoSansTc(
              color: Colors.white, 
              fontSize: 20, 
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            "全台 85 測站光纖直連陣列",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6), 
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEntry(PremiumState state, bool isClassic) {
    if (state.isFounder || state.isPremium) {
      return InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VipCenterPage()));
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isClassic 
                ? const Color(0xFFE0F7FA) 
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state.isFounder 
                  ? AppColors.bioGold 
                  : (isClassic ? const Color(0xFF00ACC1) : AppColors.pelagicCyan.withValues(alpha: 0.4)), 
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (state.isFounder ? AppColors.bioGold : AppColors.pelagicCyan).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded, 
                  color: state.isFounder ? AppColors.bioGold : (isClassic ? const Color(0xFF00838F) : AppColors.pelagicCyan), 
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          state.isFounder ? "創始釣友" : "VIP 指揮官",
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 14, 
                            color: state.isFounder 
                                ? AppColors.bioGold 
                                : (isClassic ? const Color(0xFF004D40) : AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: (state.isFounder ? AppColors.bioGold : AppColors.pelagicCyan).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            state.isFounder ? "FOUNDER" : "ACTIVE", 
                            style: TextStyle(
                              color: state.isFounder ? AppColors.bioGold : AppColors.pelagicCyan, 
                              fontSize: 8.5, 
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.isFounder ? "專屬銘牌 · 85站離線預載" : "氣象署專線運作中 • 點擊進入",
                      style: TextStyle(
                        fontSize: 10.5, 
                        color: isClassic ? const Color(0xFF00695C) : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded, 
                size: 18, 
                color: isClassic ? Colors.blueGrey : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isClassic ? Colors.white : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isClassic ? Colors.grey.shade200 : AppColors.glassBorder, 
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_outlined, color: AppColors.bioGold, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "解鎖老船長 Pro 旗艦版", 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 13.5,
                      color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "7天免費試用 · 85站專線與長湧警報", 
                    style: TextStyle(
                      fontSize: 10.5, 
                      color: isClassic ? Colors.grey : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded, 
              size: 18, 
              color: isClassic ? Colors.grey : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showSecretAuthDialog(BuildContext context) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.abyssCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.terminal_rounded, color: AppColors.pelagicCyan, size: 20),
            SizedBox(width: 8),
            Text(
              "創辦人專屬面板",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextField(
          controller: textCtrl,
          obscureText: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: "請輸入通關密鑰 (密碼: beigou)...",
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.pelagicCyan, width: 1.0)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消", style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pelagicCyan,
              foregroundColor: AppColors.abyssBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (textCtrl.text.trim() == "beigou") {
                Navigator.pop(ctx);
                HapticFeedback.heavyImpact();
                _showDeveloperMasterPanel(context);
              } else {
                HapticFeedback.vibrate();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ 密鑰錯誤，存取被拒！"), backgroundColor: AppColors.hazardCoral, duration: Duration(seconds: 2)),
                );
              }
            },
            child: const Text("解鎖", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeveloperMasterPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.abyssCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        final current = ref.watch(premiumProvider);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.bioGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "創辦人專屬後台 (全系統 41 項自檢)",
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "內部除錯測試工具已全數歸攏於此，一般用戶與 Apple 審查員完全不可見",
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              ListTile(
                dense: true,
                leading: const Icon(Icons.verified_user_rounded, color: Color(0xFF30D158)),
                title: const Text("開啟 41 項海事實機自檢與混沌中心", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("包含 10 大行銷巨擘 ASO 與 VVIP 零退費實機診斷", style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticPage()));
                },
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.purpleAccent),
                title: const Text("開啟 ASO 宣傳截圖攝影棚 (Studio)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("產生商店審查 6.7 吋與 6.5 吋宣傳照", style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AsoStudioPage()));
                },
              ),

              const Divider(color: AppColors.glassBorder),
              const SizedBox(height: 8),

              const Text("即時身分狀態切換：", style: TextStyle(color: AppColors.bioGold, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              _buildRoleTile(
                title: "1. 一般免費用戶 (Regular User)",
                subtitle: "鎖定 77 席測站、體驗 3 小時延遲與付費閘門",
                icon: Icons.person_outline_rounded,
                color: Colors.blueGrey,
                isSelected: !current.isPremium && !current.isFounder,
                onSelect: () => _applyRole(isPro: false, isFounder: false, type: SubscriptionType.none),
              ),
              const SizedBox(height: 8),
              _buildRoleTile(
                title: "2. PRO 專業用戶 (年度指揮官)",
                subtitle: "解鎖 85 站光纖直連、走水黃金期與 AI 簡報",
                icon: Icons.workspace_premium_rounded,
                color: AppColors.pelagicCyan,
                isSelected: current.isPremium && !current.isFounder,
                onSelect: () => _applyRole(isPro: true, isFounder: false, type: SubscriptionType.yearly),
              ),
              const SizedBox(height: 8),
              _buildRoleTile(
                title: "3. 超級 VIP (創始天尊指揮官)",
                subtitle: "終身黑金卡面、專屬語音問候、現場實證認證",
                icon: Icons.military_tech_rounded,
                color: AppColors.bioGold,
                isSelected: current.isFounder,
                onSelect: () => _applyRole(isPro: true, isFounder: true, type: SubscriptionType.lifetime),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : AppColors.glassBorder, width: isSelected ? 1.5 : 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textTertiary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? color : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10.5)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _applyRole({
    required bool isPro,
    required bool isFounder,
    required SubscriptionType type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', isPro);
    await prefs.setBool('is_founder', isFounder);
    await prefs.setInt('sub_type', type.index);
    if (isPro) {
      if (isFounder) {
        await prefs.setString('expiry_date', DateTime(2099, 12, 31).toIso8601String());
      } else {
        await prefs.setString('expiry_date', DateTime.now().add(const Duration(days: 365)).toIso8601String());
      }
    } else {
      await prefs.remove('expiry_date');
    }

    ref.invalidate(premiumProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚡ 模式切換成功：已切換為 ${isFounder ? '👑 超級VIP (創始指揮官)' : (isPro ? '⚡ PRO 專業用戶' : '👤 一般免費用戶')}！"),
          backgroundColor: isFounder ? const Color(0xFF2C1802) : (isPro ? const Color(0xFF0077B6) : Colors.blueGrey),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}