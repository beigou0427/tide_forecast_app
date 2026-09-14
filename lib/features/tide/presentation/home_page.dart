import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// 核心配置與 Provider
import '../providers/tide_provider.dart';
import '../data/tide_model.dart';
import '../../../core/utils/constants.dart';
import '../../premium/services/premium_service.dart';
import '../../premium/presentation/premium_page.dart';

// 專業組件
import 'tide_chart_sheet.dart';
import 'widgets/station_drawer.dart';
import 'widgets/station_header.dart';
import 'widgets/hero_metric_card.dart';
import 'widgets/metric_grid.dart';
import 'widgets/safety_alert.dart';
import 'widgets/sea_briefing_card.dart';
import '../../../shared/widgets/custom_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 自動定位邏輯
    ref.listen<String?>(nearestStationIdProvider, (previous, next) {
      if (next != null && previous == null) {
        ref.read(currentStationIdProvider.notifier).state = next;
      }
    });

    final tideViewAsync = ref.watch(tideViewDataProvider);
    final currentId = ref.watch(currentStationIdProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final premiumState = ref.watch(premiumProvider);
    
    // 獲取最愛狀態
    final favoritesAsync = ref.watch(favoriteStationsProvider);
    final bool isFavorited = favoritesAsync.value?.contains(currentId) ?? false;

    // 時態與主題視覺邏輯
    final now = DateTime.now();
    final String selectedKey = DateFormat('yyyyMMdd').format(selectedDate);
    final String todayKey = DateFormat('yyyyMMdd').format(now);
    final bool isToday = selectedKey == todayKey;
    final bool isFuture = selectedDate.isAfter(now) && !isToday;

    final Color modeColor = isToday 
        ? const Color(0xFF0077B6) 
        : (isFuture ? const Color(0xFF3F51B5) : const Color(0xFFE65100));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: StationDrawer(currentId: currentId),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 185,
            backgroundColor: modeColor,
            elevation: 0,
            leadingWidth: 100,
            leading: Builder(builder: (context) => _buildRegionButton(context)),
            centerTitle: true,
            title: Text(
              isToday ? "海象指揮中心" : (isFuture ? "未來預報模式" : "歷史觀測回測"),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            actions: [
              // 1. 收藏按鈕 (星星)
              IconButton(
                icon: Icon(
                  isFavorited ? Icons.star : Icons.star_border,
                  color: isFavorited ? Colors.amberAccent : Colors.white,
                ),
                onPressed: () async {
                  await ref.read(tideRepositoryProvider).toggleFavorite(currentId);
                  ref.refresh(favoriteStationsProvider);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFavorited ? "已從最愛移除" : "已加入我的最愛"),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              // 2. 日曆按鈕
              IconButton(
                icon: Icon(Icons.calendar_month, 
                  color: premiumState.isPremium ? Colors.amberAccent : Colors.white),
                onPressed: () => _openCalendar(context, ref),
              )
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 🌟 這裡呼叫 DateRibbon
                  DateRibbon(selectedDate: selectedDate, themeColor: modeColor),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),

          tideViewAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF0077B6)))),
            error: (err, _) => SliverFillRemaining(child: _buildErrorUI(err.toString(), ref)),
            data: (viewData) {
              final station = viewData.stationData;
              final isBuoy = AppConstants.allStations.any((s) => s.id == currentId && s.isBuoy);

              if (station.observations.isEmpty && !isFuture) {
                return SliverFillRemaining(child: _buildNoDataUI(ref, selectedDate, station.info.stationName));
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (!isFuture) ...[
                      SeaBriefingCard(station: station, distance: viewData.distanceKm),
                      const SizedBox(height: 24),
                    ],
                    StationHeader(info: station.info, distanceKm: isToday ? viewData.distanceKm : null),
                    const SizedBox(height: 20),
                    if (isFuture) ...[
                      _sectionTitle("🌟 專家級潮汐預報 (30日)", modeColor),
                      const SizedBox(height: 12),
                      _buildForecastList(station.forecasts, modeColor),
                      const SizedBox(height: 20),
                      _infoCard("預報模式說明", "您正在查看未來預報。實時波高與風速感測數據將於該日期當天產生觀測紀錄。"),
                    ] else ...[
                      HeroMetricCard(current: station.observations.last, isBuoy: isBuoy),
                      const SizedBox(height: 16),
                      SafetyAlert(current: station.observations.last),
                      if (isToday && station.forecasts.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionTitle("⏱️ 今日滿乾潮預測", modeColor),
                        const SizedBox(height: 12),
                        _buildForecastList(station.forecasts, modeColor),
                      ],
                      const SizedBox(height: 24),
                      _sectionTitle(selectedDate.isBefore(now) ? "🗓️ 歷史走勢圖" : "🌊 24h 走勢監控", modeColor),
                      const SizedBox(height: 12),
                      CustomCard(child: TideChartSheet(observations: station.observations)),
                      const SizedBox(height: 24),
                      _sectionTitle("📋 詳細觀測參數", modeColor),
                      const SizedBox(height: 12),
                      MetricGrid(current: station.observations.last),
                    ],
                    const SizedBox(height: 24),
                    _buildFooter(station.info.addressDescription),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: !isToday ? FloatingActionButton.extended(
        onPressed: () => ref.read(selectedDateProvider.notifier).state = DateTime.now(),
        backgroundColor: modeColor,
        icon: const Icon(Icons.today, color: Colors.white),
        label: const Text("返回今日", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildRegionButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 10, bottom: 10),
      child: InkWell(
        onTap: () => Scaffold.of(context).openDrawer(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text("地區", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) => Text(title, 
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color.withOpacity(0.9)));

  Widget _buildForecastList(List<TideForecast> forecasts, Color themeColor) {
    return CustomCard(
      child: Column(
        children: forecasts.map((f) {
          bool isHigh = f.tideType.contains("滿");
          return ListTile(
            dense: true,
            leading: Icon(
              isHigh ? Icons.arrow_upward : Icons.arrow_downward, 
              color: isHigh ? Colors.redAccent : Colors.blueAccent, 
              size: 20
            ),
            title: Text("${DateFormat('HH:mm').format(f.dateTime)} - ${f.tideType}", 
              style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text("${f.tideHeight} cm", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
          );
        }).toList(),
      ),
    );
  }

  Widget _infoCard(String title, String content) {
    return CustomCard(
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(content, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]))
        ],
      ),
    );
  }

  Widget _buildFooter(String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("站點資訊", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        Text(desc.isEmpty ? "中央氣象署官方 30 天數據備份節點。數據每小時更新一次。" : desc, 
             style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _openCalendar(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(selectedDateProvider),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 30)),
      helpText: "選擇回測或預報日期",
    );
    if (picked != null) ref.read(selectedDateProvider.notifier).state = picked;
  }

  Widget _buildErrorUI(String error, WidgetRef ref) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.red),
      const SizedBox(height: 16),
      const Text("資料加載失敗", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
        child: Text("請檢查網路連線或稍後再試", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      ),
      TextButton(onPressed: () => ref.refresh(tideViewDataProvider), child: const Text("重試")),
    ]));
  }

  Widget _buildNoDataUI(WidgetRef ref, DateTime date, String name) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 100),
      const Icon(Icons.event_busy, size: 80, color: Colors.grey),
      const SizedBox(height: 16),
      Text("$name 無觀測紀錄", 
           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      const SizedBox(height: 8),
      Text("${DateFormat('yyyy/MM/dd').format(date)} 暫無數據存檔", style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => ref.read(selectedDateProvider.notifier).state = DateTime.now(), 
        child: const Text("返回今日觀測")
      ),
    ]);
  }
}

// -----------------------------------------------------------------------------
// 🌟 這裡就是之前漏掉的 DateRibbon 類別定義
// -----------------------------------------------------------------------------
class DateRibbon extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final Color themeColor;
  const DateRibbon({super.key, required this.selectedDate, required this.themeColor});

  @override
  ConsumerState<DateRibbon> createState() => _DateRibbonState();
}

class _DateRibbonState extends ConsumerState<DateRibbon> {
  late ScrollController _scrollController;
  final double itemWidth = 66.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 啟動即橫移置中 (今日為第 30 格)
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    if (_scrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      final offset = (30 * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      _scrollController.animateTo(offset, 
          duration: const Duration(milliseconds: 800), 
          curve: Curves.easeOutBack);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime todayZero = DateTime(now.year, now.month, now.day);
    final String todayStr = DateFormat('yyyyMMdd').format(now);
    final String selectedStr = DateFormat('yyyyMMdd').format(widget.selectedDate);
    final isPremium = ref.watch(premiumProvider).isPremium;

    return SizedBox(
      height: 78,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: 61, 
        itemBuilder: (context, index) {
          final date = now.subtract(const Duration(days: 30)).add(Duration(days: index));
          final String currentStr = DateFormat('yyyyMMdd').format(date);
          final bool isToday = currentStr == todayStr;
          final bool isSelected = currentStr == selectedStr;

          // 昨日、今日、明日免費 (-1, 0, 1)
          final int dayDiff = date.difference(todayZero).inDays;
          final bool isFree = dayDiff >= -1 && dayDiff <= 1;
          final bool isLocked = !isFree && !isPremium;

          return GestureDetector(
            onTap: () {
              if (isLocked) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage()));
              } else {
                ref.read(selectedDateProvider.notifier).state = date;
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 58,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: isToday 
                    ? Border.all(color: isSelected ? Colors.amber : Colors.amberAccent, width: 2.5)
                    : null,
                boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('E').format(date),
                          style: TextStyle(
                            color: isSelected ? widget.themeColor : (isToday ? Colors.amberAccent : Colors.white70), 
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal
                          )),
                        Text(DateFormat('dd').format(date),
                          style: TextStyle(
                            color: isSelected ? widget.themeColor : Colors.white, 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          )),
                      ],
                    ),
                  ),
                  if (isToday)
                    Positioned(top: -11, left: 0, right: 0, child: Center(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber, 
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]
                      ),
                      child: const Text("今日", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                    ))),
                  if (isLocked)
                    Positioned(top: 4, right: 4, child: Icon(Icons.lock_outline, size: 10, color: Colors.white.withOpacity(0.7))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
