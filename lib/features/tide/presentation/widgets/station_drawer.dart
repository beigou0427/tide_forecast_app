import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/constants.dart';
import '../../providers/tide_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../premium/presentation/premium_page.dart';
import '../../../premium/presentation/vip_center_page.dart';
import '../../../diagnostic/presentation/diagnostic_page.dart';
import '../station_guide_page.dart';
import '../../../catch_log/presentation/catch_log_page.dart';
import '../aso_studio_page.dart'; // 🌟 引入 ASO 截圖工坊

class StationDrawer extends ConsumerStatefulWidget {
  final String currentId;
  const StationDrawer({super.key, required this.currentId});

  @override
  ConsumerState<StationDrawer> createState() => _StationDrawerState();
}

class _StationDrawerState extends ConsumerState<StationDrawer> {
  String _searchQuery = "";
  String _selectedFilter = "全部";

  @override
  Widget build(BuildContext context) {
    final premiumState = ref.watch(premiumProvider);
    final favoriteIdsAsync = ref.watch(favoriteStationsProvider);
    final stationListAsync = ref.watch(stationListProvider);
    final bool isPro = premiumState.isPremium || premiumState.isFounder;

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildDrawerHeader(premiumState.isFounder),
          _buildPremiumEntry(premiumState),
          _buildSearchField(),
          _buildFilterChips(),

          Expanded(
            child: stationListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(child: Text("清單載入失敗")),
              data: (allStations) {
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // 我的最愛分組
                    favoriteIdsAsync.when(
                      data: (favIds) {
                        if (favIds.isEmpty) return const SizedBox.shrink();
                        final favStations = allStations.where((s) => favIds.contains(s.id)).toList();
                        if (favStations.isEmpty) return const SizedBox.shrink();
                        return Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            leading: const Icon(Icons.stars, color: Colors.amber, size: 20),
                            title: const Text("我的最愛", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                            children: favStations.map((s) => _buildStationTile(s, true, isPro)).toList(),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const Divider(height: 1),

                    // 地區分類列表
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
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF0077B6).withValues(alpha: 0.1),
                            child: Text(region[0], style: const TextStyle(fontSize: 12, color: Color(0xFF0077B6), fontWeight: FontWeight.bold)),
                          ),
                          title: Row(
                            children: [
                              Text(region, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 8),
                              Text("(${stations.length})", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          children: stations.map((s) {
                            final isFav = favoriteIdsAsync.value?.contains(s.id) ?? false;
                            return _buildStationTile(s, isFav, isPro);
                          }).toList(),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.phishing_rounded, color: Colors.indigo),
            title: const Text("潮汐漁獲日誌", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CatchLogPage()));
            },
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF0077B6)),
            title: const Text("85 測站水文指引", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StationGuidePage()));
            },
          ),
          // 🌟 ASO 宣傳截圖專用攝影棚入口
          ListTile(
            dense: true,
            leading: const Icon(Icons.camera_alt_outlined, color: Colors.purple),
            title: const Text("ASO 截圖工坊", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
              child: const Text("拍照用", style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AsoStudioPage()));
            },
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.health_and_safety_outlined, color: Colors.teal),
            title: const Text("系統自檢中心", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticPage()));
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Text("資料來源：中央氣象署 (CWA)", style: GoogleFonts.notoSansTc(fontSize: 10, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(bool isFounder) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF023E8A), Color(0xFF0077B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.white, size: 36),
              if (isFounder)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.black87, size: 14),
                      SizedBox(width: 4),
                      Text("創始席位", style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "海象監測指揮中心",
            style: GoogleFonts.notoSansTc(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEntry(PremiumState state) {
    if (state.isFounder || state.isPremium) {
      return InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VipCenterPage()));
        },
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: state.isFounder 
                  ? [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)]
                  : [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: state.isFounder ? const Color(0xFFFFB300) : const Color(0xFF00ACC1), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: (state.isFounder ? Colors.amber : Colors.cyan).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: state.isFounder ? const Color(0xFFFF8F00) : const Color(0xFF0097A7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          state.isFounder ? "創始釣友" : "VIP 指揮官",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: state.isFounder ? const Color(0xFF4E342E) : const Color(0xFF004D40)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: state.isFounder ? const Color(0xFFFF6F00) : const Color(0xFF00838F),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(state.isFounder ? "FOUNDER" : "ACTIVE", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      state.isFounder ? "點擊檢視專屬身分卡與特權" : "氣象署專線運作中 • 點擊進入中心",
                      style: TextStyle(fontSize: 11, color: state.isFounder ? const Color(0xFF6D4C41) : const Color(0xFF00695C), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.blueGrey),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium_outlined, color: Colors.amber),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("升級老船長 Pro 旗艦版", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("週費 / 年費主力 / 終身買斷方案", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "搜尋測站或地名 (如: 石門 / 龍洞)...",
          prefixIcon: const Icon(Icons.search, size: 18),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["全部", "👑 VIP專屬", "🌊 資料浮標", "⏱️ 潮位站", "🆓 免費體驗"];
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, idx) {
          final f = filters[idx];
          final isSelected = _selectedFilter == f;
          return ChoiceChip(
            label: Text(f, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF0077B6) : Colors.blueGrey)),
            selected: isSelected,
            selectedColor: const Color(0xFF0077B6).withValues(alpha: 0.15),
            backgroundColor: Colors.white,
            side: BorderSide(color: isSelected ? const Color(0xFF0077B6) : Colors.grey.shade200),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (_) => setState(() => _selectedFilter = f),
          );
        },
      ),
    );
  }

  Widget _buildStationTile(StationModel station, bool isFavorited, bool isPro) {
    final bool isSelected = station.id == widget.currentId;
    final bool isLocked = station.isProOnly && !isPro;

    return ListTile(
      onTap: () {
        if (isLocked) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage()));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🔒 [${station.name}] 為老船長 PRO 專屬外礁/浮標水文模型，請解鎖啟用！"),
              backgroundColor: const Color(0xFF0077B6),
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
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: station.isBuoy ? Colors.indigo.shade50 : const Color(0xFF0077B6).withValues(alpha: 0.1),
        child: Icon(
          station.isBuoy ? Icons.sensors : Icons.water_drop,
          size: 13,
          color: station.isBuoy ? Colors.indigo : const Color(0xFF0077B6),
        ),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF0077B6) : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 4),

          if (station.isProOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.shade400, width: 0.8),
              ),
              child: const Text("👑 PRO", style: TextStyle(color: Color(0xFF795548), fontSize: 9, fontWeight: FontWeight.w900)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text("免費", style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      subtitle: Text(
        "${station.stationType} • ${station.agency} (${station.id})",
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      trailing: IconButton(
        icon: Icon(
          isFavorited ? Icons.star : Icons.star_border,
          size: 18,
          color: isFavorited ? Colors.amber : Colors.grey.shade300,
        ),
        onPressed: () async {
          await ref.read(tideRepositoryProvider).toggleFavorite(station.id);
          ref.invalidate(favoriteStationsProvider);
        },
      ),
    );
  }
}