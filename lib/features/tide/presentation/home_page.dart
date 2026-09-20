import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/tide_provider.dart';
import '../data/tide_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/share_util.dart';
import '../../premium/services/premium_service.dart';

import 'tide_chart_sheet.dart';
import 'widgets/station_drawer.dart';
import 'widgets/station_header.dart';
import 'widgets/hero_metric_card.dart';
import 'widgets/metric_grid.dart';
import 'widgets/safety_alert.dart';
import 'widgets/sea_briefing_card.dart';
import 'widgets/date_ribbon.dart';
import 'widgets/shareable_report_card.dart';
import 'widgets/solunar_card.dart';
import '../../../shared/widgets/custom_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(nearestStationIdProvider, (previous, next) {
      if (next != null && previous == null) {
        ref.read(currentStationIdProvider.notifier).state = next;
      }
    });

    final tideViewAsync = ref.watch(tideViewDataProvider);
    final currentId = ref.watch(currentStationIdProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final premiumState = ref.watch(premiumProvider);
    final favoritesAsync = ref.watch(favoriteStationsProvider);
    
    final allStations = ref.watch(stationListProvider).value ?? AppConstants.fallbackStations;
    
    final bool isFavorited = favoritesAsync.value?.contains(currentId) ?? false;
    final now = DateTime.now();
    final String selectedKey = DateFormat('yyyyMMdd').format(selectedDate);
    final String todayKey = DateFormat('yyyyMMdd').format(now);
    final bool isToday = selectedKey == todayKey;
    final bool isFuture = selectedDate.isAfter(now) && !isToday;

    final Color modeColor = isToday ? const Color(0xFF0077B6) : (isFuture ? const Color(0xFF3F51B5) : const Color(0xFFE65100));

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
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                tooltip: "產出海象戰報分享",
                onPressed: tideViewAsync.value == null
                    ? null
                    : () => _showShareModal(context, tideViewAsync.value!.stationData),
              ),
              IconButton(
                icon: Icon(isFavorited ? Icons.star : Icons.star_border, color: isFavorited ? Colors.amberAccent : Colors.white),
                onPressed: () async {
                  await ref.read(tideRepositoryProvider).toggleFavorite(currentId);
                  ref.invalidate(favoriteStationsProvider);
                },
              ),
              IconButton(
                icon: Icon(Icons.calendar_month, color: premiumState.isPremium ? Colors.amberAccent : Colors.white),
                onPressed: () => _openCalendar(context, ref),
              )
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
              final isBuoy = allStations.any((s) => s.id == currentId && s.isBuoy);

              final dayForecasts = station.forecasts.where((f) =>
                  DateFormat('yyyyMMdd').format(f.dateTime) == selectedKey).toList();

              final dayObservations = isToday
                  ? station.observations
                  : station.observations.where((o) => DateFormat('yyyyMMdd').format(o.dateTime) == selectedKey).toList();

              if (!isFuture && dayObservations.isEmpty) {
                return SliverFillRemaining(child: _buildNoDataUI(ref, selectedDate, station.info.stationName));
              }

              final Observation activeObservation = dayObservations.last;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (isToday) ...[
                      SeaBriefingCard(station: station, distance: viewData.distanceKm),
                      const SizedBox(height: 24),
                    ],
                    StationHeader(info: station.info, distanceKm: isToday ? viewData.distanceKm : null),
                    const SizedBox(height: 16),
                    
                    // 🌟 核心升級：月相・大潮小潮與咬度指針卡片
                    SolunarCard(selectedDate: selectedDate),
                    const SizedBox(height: 20),

                    if (isFuture) ...[
                      _sectionTitle("🌟 ${DateFormat('MM/dd').format(selectedDate)} 專家級潮汐預報", modeColor),
                      const SizedBox(height: 12),
                      _buildForecastList(dayForecasts.isNotEmpty ? dayForecasts : station.forecasts.take(4).toList(), modeColor),
                      const SizedBox(height: 20),
                      _infoCard("預報模式說明", "您正在查看未來預報。滿乾潮水位與走水轉向點已透過氣象署模型完成推算。"),
                    ] else ...[
                      HeroMetricCard(current: activeObservation, isBuoy: isBuoy),
                      const SizedBox(height: 16),
                      SafetyAlert(current: activeObservation),
                      if (dayForecasts.isNotEmpty || station.forecasts.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionTitle(isToday ? "⏱️ 今日滿乾潮預測" : "⏱️ 當日滿乾潮預測", modeColor),
                        const SizedBox(height: 12),
                        _buildForecastList(dayForecasts.isNotEmpty ? dayForecasts : station.forecasts.take(4).toList(), modeColor),
                      ],
                      const SizedBox(height: 24),
                      _sectionTitle(isToday ? "🌊 24h 走勢監控" : "🗓️ ${DateFormat('MM/dd').format(selectedDate)} 歷史走勢圖", modeColor),
                      const SizedBox(height: 12),
                      CustomCard(child: TideChartSheet(observations: dayObservations)),
                      const SizedBox(height: 24),
                      _sectionTitle("📋 ${isToday ? '詳細觀測參數' : '歷史時空記錄參數'}", modeColor),
                      const SizedBox(height: 12),
                      MetricGrid(current: activeObservation),
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
      floatingActionButton: !isToday
          ? FloatingActionButton.extended(
              onPressed: () => ref.read(selectedDateProvider.notifier).state = DateTime.now(),
              backgroundColor: modeColor,
              icon: const Icon(Icons.today, color: Colors.white),
              label: const Text("返回今日", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  void _showShareModal(BuildContext context, TideStationData station) {
    final GlobalKey reportKey = GlobalKey();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF021B33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                child: ShareableReportCard(
                  boundaryKey: reportKey,
                  station: station,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4D8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.send_rounded, color: Colors.black87),
                  label: const Text("生成戰報並分享至 LINE / 社群", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () async {
                    await ShareUtil.captureAndShare(reportKey, stationName: station.info.stationName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
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
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
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

  Widget _sectionTitle(String title, Color color) => Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.9)));

  Widget _buildForecastList(List<TideForecast> forecasts, Color themeColor) {
    if (forecasts.isEmpty) {
      return const CustomCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("該日期暫無潮位轉向紀錄", style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }
    return CustomCard(
      child: Column(
        children: forecasts.map((f) {
          bool isHigh = f.tideType.contains("滿");
          return ListTile(
            dense: true,
            leading: Icon(isHigh ? Icons.arrow_upward : Icons.arrow_downward, color: isHigh ? Colors.redAccent : Colors.blueAccent, size: 20),
            title: Text("${DateFormat('HH:mm').format(f.dateTime)} - ${f.tideType}", style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text("${f.tideHeight} cm", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(content, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
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
        Text(desc.isEmpty ? "中央氣象署官方數據。動態配置架構版。" : desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text("資料加載失敗", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text("請檢查網路連線或稍後再試", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
          TextButton(onPressed: () => ref.refresh(tideViewDataProvider), child: const Text("重試")),
        ],
      ),
    );
  }

  Widget _buildNoDataUI(WidgetRef ref, DateTime date, String name) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.event_busy, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        Text("$name 歷史觀測存檔", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Text("氣象署實測資料僅即時保留近 48 小時`n${DateFormat('yyyy/MM/dd').format(date)} 暫無實測存檔", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.4)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => ref.read(selectedDateProvider.notifier).state = DateTime.now(),
          child: const Text("返回今日觀測"),
        ),
      ],
    );
  }
}
