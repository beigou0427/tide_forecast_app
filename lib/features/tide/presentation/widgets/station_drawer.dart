import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/constants.dart';
import '../../providers/tide_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../premium/presentation/premium_page.dart';
import '../../../diagnostic/presentation/diagnostic_page.dart';

class StationDrawer extends ConsumerStatefulWidget {
  final String currentId;
  const StationDrawer({super.key, required this.currentId});

  @override
  ConsumerState<StationDrawer> createState() => _StationDrawerState();
}

class _StationDrawerState extends ConsumerState<StationDrawer> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final premiumState = ref.watch(premiumProvider);
    final favoriteIdsAsync = ref.watch(favoriteStationsProvider);
    final stationListAsync = ref.watch(stationListProvider);

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildDrawerHeader(premiumState.isFounder),
          // 🌟 創始天使判定：老用戶展示黃金勳章，新用戶展示促購入口
          _buildPremiumEntry(premiumState),
          _buildSearchField(),

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
                            children: favStations.map((s) => _buildStationTile(s, true)).toList(),
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
                        return matchesRegion && matchesSearch;
                      }).toList();

                      if (stations.isEmpty && _searchQuery.isNotEmpty) return const SizedBox.shrink();

                      return Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: _searchQuery.isNotEmpty,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF0077B6).withValues(alpha: 0.1),
                            child: Text(region[0], style: const TextStyle(fontSize: 12, color: Color(0xFF0077B6), fontWeight: FontWeight.bold)),
                          ),
                          title: Text(region, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          children: stations.map((s) {
                            final isFav = favoriteIdsAsync.value?.contains(s.id) ?? false;
                            return _buildStationTile(s, isFav);
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
    // 🌟 核心分流：若是 14 位創始老用戶，渲染尊榮黃金勳章卡
    if (state.isFounder) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFB300), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF8F00),
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
                      const Text(
                        "創始釣友",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF4E342E)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6F00),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text("FOUNDER", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "永久享有全平台終身旗艦特權",
                    style: TextStyle(fontSize: 11, color: Color(0xFF6D4C41), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 一般用戶：展示促購與方案管理入口
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: state.isPremium ? Colors.amber.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: state.isPremium ? Colors.amber.shade300 : Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(state.isPremium ? Icons.stars_rounded : Icons.workspace_premium_outlined, color: Colors.amber.shade800),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isPremium ? "您已是 Pro 會員" : "升級老船長 Pro 旗艦版",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    state.isPremium ? "享受 0 延遲海象直連與 AI 漁獲窗口" : "週費 / 年費主力 / 終身買斷方案",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
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
          hintText: "搜尋測站...",
          prefixIcon: const Icon(Icons.search, size: 18),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildStationTile(StationModel station, bool isFavorited) {
    final bool isSelected = station.id == widget.currentId;
    return ListTile(
      onTap: () {
        ref.read(currentStationIdProvider.notifier).state = station.id;
        ref.read(selectedDateProvider.notifier).state = DateTime.now();
        Navigator.pop(context);
      },
      dense: true,
      leading: Icon(station.isBuoy ? Icons.sensors : Icons.water_drop, size: 16, color: isSelected ? const Color(0xFF0077B6) : Colors.blueGrey.shade200),
      title: Text(station.name, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF0077B6) : Colors.black87)),
      trailing: IconButton(
        icon: Icon(isFavorited ? Icons.star : Icons.star_border, size: 18, color: isFavorited ? Colors.amber : Colors.grey.shade300),
        onPressed: () async {
          await ref.read(tideRepositoryProvider).toggleFavorite(station.id);
          ref.invalidate(favoriteStationsProvider);
        },
      ),
    );
  }
}


