import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/constants.dart';
import '../../providers/tide_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../premium/presentation/premium_page.dart';

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
    final bool isPremium = premiumState.isPremium;

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildDrawerHeader(),
          _buildPremiumEntry(isPremium, premiumState.type),
          _buildSearchField(),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 🌟 1. 我的最愛分組 (僅在有收藏時顯示)
                favoriteIdsAsync.when(
                  data: (favIds) {
                    if (favIds.isEmpty) return const SizedBox.shrink();
                    final favStations = AppConstants.allStations
                        .where((s) => favIds.contains(s.id))
                        .toList();
                    
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

                // 2. 地區分類列表
                ...AppConstants.regions.map((region) {
                  final List<StationModel> stations = AppConstants.allStations.where((s) {
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
                        backgroundColor: const Color(0xFF0077B6).withOpacity(0.1),
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
            ),
          ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text("資料來源：中央氣象署 (CWA)", style: GoogleFonts.notoSansTc(fontSize: 10, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF023E8A), Color(0xFF0077B6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.analytics_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text("海象監測指揮中心", style: GoogleFonts.notoSansTc(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPremiumEntry(bool isPremium, SubscriptionType type) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPremium ? Colors.amber.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isPremium ? Colors.amber.shade300 : Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(isPremium ? Icons.stars_rounded : Icons.workspace_premium_outlined, color: Colors.amber.shade800),
            const SizedBox(width: 12),
            const Expanded(child: Text("Pro 專業版功能管理", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
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
          ref.refresh(favoriteStationsProvider); // 🌟 關鍵：通知 UI 刷新最愛清單
        },
      ),
    );
  }
}
