import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tide_provider.dart';
import '../../../core/utils/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_card.dart';

/// Apple 首席設計工藝：全台 85 測站水文百科指南 (雙軌自適應版)
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
    final isClassic = ref.watch(isClassicThemeProvider);
    final stationsAsync = ref.watch(stationListProvider);

    final Color bgColor = isClassic ? AppColors.classicBg : AppColors.abyssBlack;
    final Color appBarBg = isClassic ? const Color(0xFF0077B6) : AppColors.abyssBlack.withValues(alpha: 0.88);
    final Color accentColor = isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "85 測站水文百科指南", 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white, letterSpacing: -0.4),
        ),
        backgroundColor: appBarBg,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: isClassic ? 1 : 0,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEducationalCard(isClassic),
                  const SizedBox(height: 18),
                  _buildSearchBar(isClassic, accentColor),
                  const SizedBox(height: 14),
                  _buildRegionFilter(isClassic, accentColor),
                ],
              ),
            ),
          ),
          stationsAsync.when(
            loading: () => SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 2.5)),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text("測站載入異常: $err", style: const TextStyle(color: AppColors.hazardCoral, fontSize: 13)),
              ),
            ),
            data: (allStations) {
              final filtered = allStations.where((s) {
                final matchRegion = _selectedRegion == "全部" || s.region == _selectedRegion;
                final matchQuery = _searchQuery.isEmpty ||
                    s.name.contains(_searchQuery) ||
                    s.id.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchRegion && matchQuery;
              }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "未找到符合條件的水文測站", 
                      style: TextStyle(color: isClassic ? Colors.grey : AppColors.textTertiary, fontSize: 13),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStationItem(filtered[index], isClassic, accentColor),
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

  Widget _buildEducationalCard(bool isClassic) {
    final Color iconAccent = isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan;
    final Color titleColor = isClassic ? const Color(0xFF023E8A) : AppColors.textPrimary;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book_rounded, color: iconAccent, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                "老船長作戰速查指南", 
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: titleColor, letterSpacing: -0.2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildKnowledgeRow("🌊 湧浪週期 > 8 秒", "外海具深層長湧，岸邊極易突發瘋狗浪，礁石務必穿戴合格釘鞋救生衣。", isClassic),
          const SizedBox(height: 8),
          _buildKnowledgeRow("🌡️ 水溫變動 > 1.5℃", "冷暖水塊交匯走水急促，黑毛、鱸魚活性提高但索餌就餌轉為敏感。", isClassic),
          const SizedBox(height: 8),
          _buildKnowledgeRow("⏱️ 滿乾潮前後 2 分水", "潮差走水帶動浮游藻類與餌魚聚集，為全天作釣最佳「黃金爆咬窗口」。", isClassic),
        ],
      ),
    );
  }

  Widget _buildKnowledgeRow(String title, String desc, bool isClassic) {
    final Color titleColor = isClassic ? const Color(0xFFD97706) : AppColors.bioGold;
    final Color descColor = isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: titleColor)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            desc, 
            style: TextStyle(fontSize: 11.5, color: descColor, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isClassic, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: isClassic ? Colors.white : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClassic ? Colors.grey.shade300 : AppColors.glassBorder, 
          width: 0.5,
        ),
        boxShadow: isClassic ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)] : null,
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(color: isClassic ? Colors.black87 : AppColors.textPrimary, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: "搜尋測站地名或代號 (如: 富貴角 / C6AH2)...",
          hintStyle: TextStyle(color: isClassic ? Colors.grey : AppColors.textTertiary, fontSize: 12.5),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: accentColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRegionFilter(bool isClassic, Color accentColor) {
    final regions = ["全部", ...AppConstants.regions];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: regions.map((r) {
          final isSelected = _selectedRegion == r;

          Color chipBg;
          Color chipText;
          Border? chipBorder;

          if (isClassic) {
            chipBg = isSelected ? const Color(0xFF0077B6) : Colors.white;
            chipText = isSelected ? Colors.white : Colors.blueGrey.shade700;
            chipBorder = isSelected ? null : Border.all(color: Colors.grey.shade300, width: 0.5);
          } else {
            chipBg = isSelected ? AppColors.textPrimary : Colors.white.withValues(alpha: 0.06);
            chipText = isSelected ? AppColors.abyssBlack : AppColors.textSecondary;
            chipBorder = isSelected ? null : Border.all(color: AppColors.glassBorder, width: 0.5);
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedRegion = r);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(20),
                  border: chipBorder,
                  boxShadow: isSelected 
                      ? [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 8)] 
                      : null,
                ),
                child: Text(
                  r,
                  style: TextStyle(
                    color: chipText,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStationItem(StationModel station, bool isClassic, Color accentColor) {
    final Color itemBg = isClassic ? Colors.white : Colors.white.withValues(alpha: 0.04);
    final Color borderColor = isClassic ? Colors.grey.shade200 : AppColors.glassBorder;
    final Color titleColor = isClassic ? AppColors.classicText : AppColors.textPrimary;
    final Color subtitleColor = isClassic ? Colors.grey.shade600 : AppColors.textTertiary;
    final Color typeColor = station.isBuoy ? Colors.indigoAccent : accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isClassic ? 0.8 : 0.5),
        boxShadow: isClassic ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(currentStationIdProvider.notifier).state = station.id;
            ref.read(selectedDateProvider.notifier).state = DateTime.now();
            Navigator.pop(context);
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: typeColor.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Icon(
              station.isBuoy ? Icons.sensors_rounded : Icons.water_drop_rounded, 
              color: typeColor, 
              size: 16,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: titleColor),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isClassic ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor, width: 0.5),
                ),
                child: Text(
                  station.stationType,
                  style: TextStyle(
                    fontSize: 9.5, 
                    color: typeColor, 
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            "${station.agency} (${station.id}) · ${station.region}海域", 
            style: TextStyle(color: subtitleColor, fontSize: 10.5, height: 1.3),
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: subtitleColor),
        ),
      ),
    );
  }
}
