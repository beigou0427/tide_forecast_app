import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tide_provider.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/widgets/custom_card.dart';

class StationGuidePage extends ConsumerStatefulWidget {
  const StationGuidePage({super.key});

  @override
  ConsumerState<StationGuidePage> createState() => _StationGuidePageState();
}

class _StationGuidePageState extends ConsumerState<StationGuidePage> {
  String _selectedRegion = "全部";
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("全台 85 測站水文指引", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF0077B6),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEducationalCard(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildRegionFilter(),
                ],
              ),
            ),
          ),
          stationsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, _) => SliverFillRemaining(child: Center(child: Text("測站加載失敗: $err"))),
            data: (allStations) {
              final filtered = allStations.where((s) {
                final matchRegion = _selectedRegion == "全部" || s.region == _selectedRegion;
                final matchQuery = _searchQuery.isEmpty ||
                    s.name.contains(_searchQuery) ||
                    s.id.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchRegion && matchQuery;
              }).toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("未找到符合條件的測站", style: TextStyle(color: Colors.grey))),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStationItem(filtered[index]),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF0077B6).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0077B6), size: 18),
              ),
              const SizedBox(width: 8),
              const Text("老船長水文作戰速查指南", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          _buildKnowledgeRow("🌊 湧浪週期 > 8 秒", "外海有深層長湧浪，岸邊易突發瘋狗浪，礁石務必穿救生衣。"),
          const SizedBox(height: 6),
          _buildKnowledgeRow("🌡️ 水溫變動 > 1.5℃", "冷暖水塊交匯走水快，黑毛、鱸魚活性提高但咬口變敏感。"),
          const SizedBox(height: 6),
          _buildKnowledgeRow("⏱️ 滿乾潮前後 2 分分水", "潮差帶動藻類與小魚漂移，為一日中作釣最佳「黃金咬度期」。"),
        ],
      ),
    );
  }

  Widget _buildKnowledgeRow(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF023E8A))),
        const SizedBox(width: 6),
        Expanded(child: Text(desc, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, height: 1.3))),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: "搜尋站點名稱或代號 (如: 富貴角 / C6AH2)...",
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildRegionFilter() {
    final regions = ["全部", ...AppConstants.regions];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: regions.map((r) {
          final isSelected = _selectedRegion == r;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(r),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedRegion = r),
              selectedColor: const Color(0xFF0077B6).withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF0077B6) : Colors.blueGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? const Color(0xFF0077B6) : Colors.grey.shade200),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStationItem(StationModel station) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        child: ListTile(
          onTap: () {
            ref.read(currentStationIdProvider.notifier).state = station.id;
            ref.read(selectedDateProvider.notifier).state = DateTime.now();
            Navigator.pop(context);
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: station.isBuoy ? Colors.indigo.shade50 : const Color(0xFF0077B6).withValues(alpha: 0.1),
            child: Icon(station.isBuoy ? Icons.sensors : Icons.water_drop, color: station.isBuoy ? Colors.indigo : const Color(0xFF0077B6), size: 18),
          ),
          // 🌟 徹底修復 RenderFlex 50px 溢出：使用 Expanded 約束長站名
          title: Row(
            children: [
              Expanded(
                child: Text(
                  station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: station.isBuoy ? Colors.indigo.shade50 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  station.stationType,
                  style: TextStyle(fontSize: 10, color: station.isBuoy ? Colors.indigo : Colors.teal, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: Text("${station.agency} (${station.id}) • ${station.region}海域", style: const TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
        ),
      ),
    );
  }
}
