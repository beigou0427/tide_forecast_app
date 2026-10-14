import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/tide_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../premium/presentation/premium_page.dart';
import '../../../premium/presentation/vip_center_page.dart';
import '../../../diagnostic/presentation/diagnostic_page.dart';
import '../../../onboarding/presentation/onboarding_page.dart';
import '../station_guide_page.dart';
import '../../../catch_log/presentation/catch_log_page.dart';
import '../../../catch_log/providers/catch_log_provider.dart';
import 'developer_master_panel.dart';

/// 🌟 經海事光學對比與極限防呆重塑之全域導航側邊欄
/// 100% 免疫鍵盤溢出崩潰與 Apple 審查合規版：
/// 1. 將所有靜態組件編入單一 ListView，消滅 RenderFlex Overflow！
/// 2. 【合規防線】補齊 Apple Guideline 5.1.1(v) 隱私與資料刪除機制。
/// 3. 【創投級 Demo】導入 7 連擊隱藏入口 (Konami Code)，直通創辦人專屬面板！
class StationDrawer extends ConsumerStatefulWidget {
  final String currentId;
  const StationDrawer({super.key, required this.currentId});

  @override
  ConsumerState<StationDrawer> createState() => _StationDrawerState();
}

class _StationDrawerState extends ConsumerState<StationDrawer> {
  String _searchQuery = "";
  String _selectedFilter = "全部";
  int _secretTapCount = 0; // 🌟 創辦人專屬：7 連擊計數器

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;

    final Color drawerBg = isEInk 
        ? Colors.white 
        : (isClassic ? AppColors.classicBg : AppColors.abyssSurface);
    final Color cardBg = isEInk 
        ? Colors.white 
        : (isClassic ? Colors.white : AppColors.abyssCard);
    final Color cardBorder = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder);
    final Color textPrimary = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color textSecondary = isEInk 
        ? Colors.black54 
        : (isClassic ? Colors.grey.shade600 : AppColors.textSecondary);
    final Color searchBg = isEInk 
        ? Colors.white 
        : (isClassic ? Colors.white : Colors.white.withValues(alpha: 0.06));
    final Color dividerColor = isEInk 
        ? Colors.black26 
        : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder);
    final Color goldColor = isEInk ? Colors.black : AppColors.bioGold;

    final premiumState = ref.watch(premiumProvider);
    final favoriteIdsAsync = ref.watch(favoriteStationsProvider);
    final stationListAsync = ref.watch(stationListProvider);
    final bool isPro = premiumState.isPremium || premiumState.isFounder;

    return Drawer(
      backgroundColor: drawerBg,
      child: Column(
        children: [
          // 頂部 Header：內嵌 7 連擊幽靈入口
          _buildDrawerHeader(premiumState.isFounder, isClassic, isEInk),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPremiumEntry(premiumState, cardBg, cardBorder, textPrimary, textSecondary, isClassic, isEInk),

                if (!isPro)
                  _buildDrawerSurveyTrialBanner(context, isEInk),

                _buildSearchField(searchBg, cardBorder, textPrimary, textSecondary, isClassic, isEInk),
                _buildFilterChips(cardBg, cardBorder, textPrimary, textSecondary, isClassic, isEInk),

                // 測站清單區塊
                stationListAsync.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator(color: isEInk ? Colors.black : AppColors.pelagicCyan)),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: Text("清單載入失敗", style: TextStyle(color: textSecondary))),
                  ),
                  data: (allStations) {
                    return Column(
                      children: [
                        favoriteIdsAsync.when(
                          data: (favIds) {
                            if (favIds.isEmpty) return const SizedBox.shrink();
                            final favStations = allStations.where((s) => favIds.contains(s.id)).toList();
                            if (favStations.isEmpty) return const SizedBox.shrink();
                            return Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                key: Key('fav_${_searchQuery}_$_selectedFilter'),
                                initiallyExpanded: true,
                                iconColor: goldColor,
                                collapsedIconColor: goldColor,
                                leading: Icon(Icons.stars, color: goldColor, size: 20),
                                title: Text("我的最愛", style: TextStyle(fontWeight: FontWeight.bold, color: goldColor)),
                                children: favStations.map((s) => _buildStationTile(s, true, isPro, textPrimary, textSecondary, isClassic, isEInk)).toList(),
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
                              key: Key('region_${region}_${_searchQuery}_$_selectedFilter'),
                              initiallyExpanded: _searchQuery.isNotEmpty || _selectedFilter != "全部",
                              iconColor: textPrimary,
                              collapsedIconColor: textSecondary,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: isEInk ? Colors.black12 : const Color(0xFF0077B6).withValues(alpha: 0.15),
                                child: Text(region[0], style: TextStyle(fontSize: 12, color: isEInk ? Colors.black : const Color(0xFF0077B6), fontWeight: FontWeight.bold)),
                              ),
                              title: Row(
                                children: [
                                  Text(region, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
                                  const SizedBox(width: 8),
                                  Text("(${stations.length})", style: TextStyle(fontSize: 12, color: textSecondary)),
                                ],
                              ),
                              children: stations.map((s) => _buildStationTile(s, favoriteIdsAsync.value?.contains(s.id) ?? false, isPro, textPrimary, textSecondary, isClassic, isEInk)).toList(),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),

                Divider(height: 1, color: dividerColor),
                
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.emergency_rounded, color: AppColors.hazardCoral),
                  title: Row(
                    children: [
                      Text("海事安全與救難專線", style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.hazardCoral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("海巡 118", style: TextStyle(color: AppColors.hazardCoral, fontSize: 8.5, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right, size: 16, color: textSecondary),
                  onTap: () {
                    Navigator.pop(context);
                    _showMaritimeSupportDialog(context, cardBg, textPrimary, textSecondary, cardBorder, isClassic, isEInk);
                  },
                ),

                ListTile(
                  dense: true,
                  leading: const Icon(Icons.phishing_rounded, color: Colors.indigoAccent),
                  title: Text("潮汐漁獲日誌", style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                  trailing: Icon(Icons.chevron_right, size: 16, color: textSecondary),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CatchLogPage()));
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF00B4D8)),
                  title: Text("85 測站水文指引", style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                  trailing: Icon(Icons.chevron_right, size: 16, color: textSecondary),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StationGuidePage()));
                  },
                ),
                
                // 🌟 Apple 審查合規防線：隱私權與資料管理
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blueGrey),
                  title: Text("隱私權與資料管理", style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                  trailing: Icon(Icons.chevron_right, size: 16, color: textSecondary),
                  onTap: () {
                    Navigator.pop(context);
                    _showPrivacyManagementDialog(context, ref, cardBg, textPrimary, textSecondary, cardBorder, isClassic, isEInk);
                  },
                ),

                Divider(height: 1, color: dividerColor),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 40, left: 16),
                  child: Text("資料來源：中央氣象署 (CWA)", style: GoogleFonts.notoSansTc(fontSize: 10, color: textSecondary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 核心引擎：7 連擊創辦人專屬面板觸發器 (Konami Code)
  Widget _buildDrawerHeader(bool isFounder, bool isClassic, bool isEInk) {
    return GestureDetector(
      onTap: () {
        _secretTapCount++;
        if (_secretTapCount >= 7) {
          _secretTapCount = 0;
          HapticFeedback.heavyImpact();
          Navigator.pop(context); // 關閉側邊欄
          DeveloperMasterPanel.showAuthDialog(context, ref); // 召喚隱藏控制台
        } else if (_secretTapCount >= 3) {
          HapticFeedback.selectionClick(); // 輕微回饋，暗示還有機關
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
        decoration: BoxDecoration(
          color: isEInk ? Colors.black : null,
          gradient: isEInk ? null : const LinearGradient(
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
      ),
    );
  }

  void _showPrivacyManagementDialog(
    BuildContext context, 
    WidgetRef ref,
    Color cardBg, 
    Color textPrimary, 
    Color textSecondary, 
    Color cardBorder, 
    bool isClassic, 
    bool isEInk,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: cardBorder, width: isEInk ? 1.5 : 0.8),
        ),
        title: Row(
          children: [
            const Icon(Icons.privacy_tip_rounded, color: Colors.blueGrey, size: 24),
            const SizedBox(width: 8),
            Text("隱私與資料管理", style: TextStyle(color: textPrimary, fontSize: 16.5, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tide Pro 尊重您的數位隱私權。您可以隨時查閱我們的隱私權政策，或行使您的資料刪除權 (被遺忘權)。",
              style: TextStyle(color: textSecondary, fontSize: 12.5, height: 1.45),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isEInk ? Colors.black : const Color(0xFF0077B6), width: 1.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: isEInk ? Colors.black : const Color(0xFF0077B6),
                ),
                icon: const Icon(Icons.policy_rounded, size: 16),
                label: const Text("檢視隱私權政策", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final Uri url = Uri.parse("https://gist.github.com/beigou0427/99e6eddb729ae53eb8e7474866f3f009");
                  if (await canLaunchUrl(url)) await launchUrl(url);
                },
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hazardCoral.withValues(alpha: 0.1),
                  foregroundColor: AppColors.hazardCoral,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.hazardCoral, width: 1.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_forever_rounded, size: 16),
                label: const Text("永久刪除雲端資料與帳號", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(ctx);
                  _showWipeConfirmDialog(context, ref, cardBg, textPrimary, textSecondary, cardBorder, isClassic, isEInk);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("關閉", style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showWipeConfirmDialog(
    BuildContext context, 
    WidgetRef ref,
    Color cardBg, 
    Color textPrimary, 
    Color textSecondary, 
    Color cardBorder, 
    bool isClassic, 
    bool isEInk,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.hazardCoral, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.hazardCoral, size: 24),
            SizedBox(width: 8),
            Text("嚴重警告：資料將永久銷毀", style: TextStyle(color: AppColors.hazardCoral, fontSize: 16.5, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          "此操作將呼叫系統底層指令，徹底抹除您在本機與 Firebase 雲端金庫上的所有漁獲紀錄、照片與設定。此動作不可逆，確定要執行嗎？",
          style: TextStyle(color: textPrimary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("保留資料", style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.hazardCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("⚠️ 正在執行全域資料抹除指令..."), backgroundColor: AppColors.hazardCoral, duration: Duration(seconds: 2)),
              );

              await ref.read(catchLogProvider.notifier).wipeAllPersonalData();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ 本機與雲端所有個人資料已徹底抹除完畢。"), backgroundColor: Colors.blueGrey, behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text("確認永久刪除", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSurveyTrialBanner(BuildContext context, bool isEInk) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.heavyImpact();
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingPage(initialCohort: 'survey_trial')));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isEInk ? null : const LinearGradient(colors: [Color(0xFF0F3B2A), Color(0xFF051C12)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            color: isEInk ? Colors.black.withValues(alpha: 0.05) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isEInk ? Colors.black : const Color(0xFF10B981), width: isEInk ? 1.5 : 1.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text("填 4 題問卷，免綁卡直接領 7 天 PRO 試用！", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF34D399)))),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isEInk ? Colors.black : const Color(0xFF34D399)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumEntry(
    PremiumState state, Color cardBg, Color cardBorder, Color textPrimary, Color textSecondary, bool isClassic, bool isEInk,
  ) {
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
            color: isEInk ? Colors.white : null,
            gradient: isEInk ? null : LinearGradient(
              colors: state.isFounder ? [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)] : [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: state.isFounder ? const Color(0xFFFFB300) : const Color(0xFF00ACC1), width: 1.8),
            boxShadow: [BoxShadow(color: (state.isFounder ? Colors.amber : Colors.cyan).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: state.isFounder ? const Color(0xFFFF8F00) : const Color(0xFF0097A7), shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(state.isFounder ? "創始釣友" : "VIP 指揮官", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: state.isFounder ? const Color(0xFF4E342E) : const Color(0xFF004D40))),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: state.isFounder ? const Color(0xFFFF6F00) : const Color(0xFF00838F), borderRadius: BorderRadius.circular(6)),
                          child: Text(state.isFounder ? "FOUNDER" : "ACTIVE", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(state.isFounder ? "點擊檢視專屬身分卡與特權" : "氣象署專線運作中 • 點擊進入中心", style: TextStyle(fontSize: 11, color: state.isFounder ? const Color(0xFF6D4C41) : const Color(0xFF00695C), fontWeight: FontWeight.w500)),
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
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder, width: isEInk ? 1.5 : 1.0)),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: AppColors.bioGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("升級老船長 Pro 旗艦版", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text("週費 / 年費主力 / 終身買斷方案", style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(Color searchBg, Color cardBorder, Color textPrimary, Color textSecondary, bool isClassic, bool isEInk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: textPrimary, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: "搜尋測站或地名 (如: 石門 / 龍洞)...",
          hintStyle: TextStyle(color: textSecondary, fontSize: 12),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: textSecondary),
          filled: true,
          fillColor: searchBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder, width: isEInk ? 1.5 : 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder, width: isEInk ? 1.5 : 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isEInk ? Colors.black : const Color(0xFF0077B6), width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildFilterChips(Color cardBg, Color cardBorder, Color textPrimary, Color textSecondary, bool isClassic, bool isEInk) {
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
            label: Text(f, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : textPrimary)),
            selected: isSelected,
            selectedColor: isEInk ? Colors.black : const Color(0xFF0077B6),
            backgroundColor: cardBg,
            side: BorderSide(color: isSelected ? (isEInk ? Colors.black : const Color(0xFF0077B6)) : cardBorder, width: isEInk ? 1.5 : 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (_) => setState(() => _selectedFilter = f),
          );
        },
      ),
    );
  }

  Widget _buildStationTile(StationModel station, bool isFavorited, bool isPro, Color textPrimary, Color textSecondary, bool isClassic, bool isEInk) {
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
        backgroundColor: station.isBuoy ? Colors.indigo.withValues(alpha: 0.15) : const Color(0xFF0077B6).withValues(alpha: 0.15),
        child: Icon(station.isBuoy ? Icons.sensors_rounded : Icons.water_drop_rounded, size: 13, color: station.isBuoy ? Colors.indigoAccent : const Color(0xFF0077B6)),
      ),
      title: Row(
        children: [
          Expanded(child: Text(station.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? (isEInk ? Colors.black : const Color(0xFF0077B6)) : textPrimary))),
          const SizedBox(width: 4),
          if (station.isProOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: isEInk ? Colors.black : AppColors.bioGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: isEInk ? Colors.black : AppColors.bioGold.withValues(alpha: 0.4), width: 0.8)),
              child: Text("👑 PRO", style: TextStyle(color: isEInk ? Colors.white : AppColors.bioGold, fontSize: 9, fontWeight: FontWeight.w900)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
              child: const Text("免費", style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      subtitle: Text("${station.stationType} • ${station.agency} (${station.id})", style: TextStyle(fontSize: 10, color: textSecondary)),
      trailing: IconButton(
        icon: Icon(isFavorited ? Icons.star_rounded : Icons.star_border_rounded, size: 18, color: isFavorited ? AppColors.bioGold : textSecondary.withValues(alpha: 0.4)),
        onPressed: () async {
          await ref.read(tideRepositoryProvider).toggleFavorite(station.id);
          ref.invalidate(favoriteStationsProvider);
        },
      ),
    );
  }

  void _showMaritimeSupportDialog(BuildContext context, Color cardBg, Color textPrimary, Color textSecondary, Color cardBorder, bool isClassic, bool isEInk) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: cardBorder, width: isEInk ? 1.5 : 0.8)),
        title: Row(
          children: [
            const Icon(Icons.emergency_rounded, color: AppColors.hazardCoral, size: 22),
            const SizedBox(width: 8),
            Text("海事安全與緊急支援聯絡網", style: TextStyle(color: textPrimary, fontSize: 16.5, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.hazardCoral.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hazardCoral.withValues(alpha: 0.4))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("海巡署 118 海上報案", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: AppColors.hazardCoral)),
                      SizedBox(height: 2),
                      Text("遇險困礁、人員落海免費直撥", style: TextStyle(fontSize: 10.5, color: AppColors.hazardCoral)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.hazardCoral, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => _callNumber("118"),
                    child: const Text("撥打 118", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0077B6).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF0077B6).withValues(alpha: 0.3))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("中央氣象署 166 語音", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: textPrimary)),
                      const SizedBox(height: 2),
                      Text("海象、風浪與天氣電話預報", style: TextStyle(fontSize: 10.5, color: textSecondary)),
                    ],
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0077B6), side: const BorderSide(color: Color(0xFF0077B6)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => _callNumber("166"),
                    child: const Text("撥打 166", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text("📍 尋找周邊釣具與餌料行：請回到首頁「港區補給雷達」，將為您根據當前測站即時搜尋周邊真實營業中的店家與地圖導航。", style: TextStyle(color: textSecondary, fontSize: 11, height: 1.4)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("關閉", style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)))],
      ),
    );
  }

  Future<void> _callNumber(String num) async {
    final Uri url = Uri.parse("tel:$num");
    try {
      if (await canLaunchUrl(url)) await launchUrl(url);
    } catch (_) {}
  }
}
