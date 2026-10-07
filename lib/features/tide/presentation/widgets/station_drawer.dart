import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/services/health_probe_service.dart';
import '../../providers/tide_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../premium/presentation/premium_page.dart';
import '../../../premium/presentation/vip_center_page.dart';
import '../station_guide_page.dart';
import '../../../catch_log/presentation/catch_log_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../home_page.dart';
import 'support_privacy_modal.dart';
import 'developer_master_panel.dart';

/// 🌟 經海事嚴謹標準重構之純淨導航抽屜 (解耦後的單一職責純淨架構)
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
      DeveloperMasterPanel.showAuthDialog(context, ref);
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
                    // 我的最愛群組
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

                    // 各海域分區
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

          // 功能捷徑選單
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
              SupportPrivacyModal.showSupportModal(
                context, 
                currentStationId: widget.currentId, 
                isClassic: isClassic, 
                ref: ref,
              );
            },
          ),
          
          Divider(height: 1, color: dividerColor),

          // 底部來源與創辦人彩蛋
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 24),
            child: GestureDetector(
              onTap: _handleSecretEasterEgg,
              onLongPress: () {
                HapticFeedback.heavyImpact();
                DeveloperMasterPanel.showAuthDialog(context, ref);
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
}