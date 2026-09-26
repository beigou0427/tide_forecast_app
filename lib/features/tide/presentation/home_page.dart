import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/tide_provider.dart';
import '../data/tide_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/share_util.dart';
import '../../../core/theme/app_theme.dart';
import '../../premium/services/premium_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/fcm_service.dart';

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
import 'widgets/wind_compass_card.dart';
import 'widgets/ugc_radar_card.dart';
import 'widgets/local_merchant_card.dart';
import '../../../shared/widgets/custom_card.dart';

/// 🍏 Apple 首席設計工藝：深海無邊界主座艙 (Abyssal Master Canvas)
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

  @override
  void initState() {
    super.initState();
    // 延遲 3 秒請求推播權限，先讓用戶看見 App 價值 (Apple HIG 規範)
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        await NotificationService.init();
        await FcmService.init();
      } catch (e) {
        debugPrint("推播服務延遲初始化失敗: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
    final currentStation = allStations.firstWhere((s) => s.id == currentId, orElse: () => allStations.first);

    final bool isFavorited = favoritesAsync.value?.contains(currentId) ?? false;
    final now = DateTime.now();
    final String selectedKey = DateFormat('yyyyMMdd').format(selectedDate);
    final String todayKey = DateFormat('yyyyMMdd').format(now);
    final bool isToday = selectedKey == todayKey;
    final bool isFuture = selectedDate.isAfter(now) && !isToday;

    return Scaffold(
      // 🌟 深淵極致純黑畫布
      backgroundColor: AppColors.abyssBlack,
      drawer: StationDrawer(currentId: currentId),
      body: RefreshIndicator(
        color: AppColors.pelagicCyan,
        backgroundColor: AppColors.abyssCard,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          return await ref.refresh(tideViewDataProvider.future);
        },
        child: CustomScrollView(
          // iOS 彈簧回彈物理
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              backgroundColor: AppColors.abyssBlack.withValues(alpha: 0.88),
              elevation: 0,
              leadingWidth: 92,
              leading: Builder(builder: (context) => _buildRegionButton(context)),
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.pelagicCyan : (isFuture ? Colors.indigoAccent : AppColors.hazardCoral),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isToday ? "海象指揮中心" : (isFuture ? "未來預報模式" : "歷史觀測回測"),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 16.5,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary, size: 20),
                  tooltip: "產出海象戰報分享",
                  onPressed: tideViewAsync.value == null
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _showShareModal(context, tideViewAsync.value!.stationData);
                        },
                ),
                IconButton(
                  icon: Icon(
                    isFavorited ? Icons.star_rounded : Icons.star_border_rounded, 
                    color: isFavorited ? AppColors.bioGold : AppColors.textSecondary,
                    size: 22,
                  ),
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    await ref.read(tideRepositoryProvider).toggleFavorite(currentId);
                    ref.invalidate(favoriteStationsProvider);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.calendar_month_rounded, 
                    color: premiumState.isPremium ? AppColors.bioGold : AppColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _openCalendar(context, ref);
                  },
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DateRibbon(selectedDate: selectedDate, themeColor: AppColors.pelagicCyan),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            tideViewAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.pelagicCyan, strokeWidth: 2.5)),
              ),
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

                final Observation? activeObservation = dayObservations.isNotEmpty
                    ? dayObservations.last
                    : (station.observations.isNotEmpty ? station.observations.last : null);

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (isToday) ...[
                        SeaBriefingCard(station: station, distance: viewData.distanceKm),
                        const SizedBox(height: 20),
                      ],
                      StationHeader(info: station.info, distanceKm: isToday ? viewData.distanceKm : null),
                      const SizedBox(height: 16),
                      
                      if (isToday) ...[
                        UgcRadarCard(
                          stationId: currentId,
                          stationName: station.info.stationName,
                          waveHeight: activeObservation?.waveHeight,
                          windSpeed: activeObservation?.windSpeed,
                        ),
                        const SizedBox(height: 16),
                      ],

                      SolunarCard(selectedDate: selectedDate),
                      const SizedBox(height: 20),

                      if (isFuture) ...[
                        _sectionTitle("🌟 ${DateFormat('MM/dd').format(selectedDate)} 專家級潮汐預報", accentColor: Colors.indigoAccent),
                        const SizedBox(height: 12),
                        _buildForecastList(dayForecasts.isNotEmpty ? dayForecasts : station.forecasts.take(4).toList()),
                        const SizedBox(height: 18),
                        _infoCard("預報模式說明", "您正在查看未來預報。滿乾潮水位與走水轉向點已透過氣象署物理模型推算。"),
                      ] else if (activeObservation != null) ...[
                        HeroMetricCard(current: activeObservation, isBuoy: isBuoy),
                        const SizedBox(height: 14),
                        SafetyAlert(current: activeObservation),
                        const SizedBox(height: 14),
                        
                        WindCompassCard(current: activeObservation),

                        if (dayForecasts.isNotEmpty || station.forecasts.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          _sectionTitle(isToday ? "今日滿乾潮時程" : "當日滿乾潮時程", accentColor: AppColors.bioGold),
                          const SizedBox(height: 12),
                          _buildForecastList(dayForecasts.isNotEmpty ? dayForecasts : station.forecasts.take(4).toList()),
                        ],
                        const SizedBox(height: 22),
                        _sectionTitle(isToday ? "24h 走勢監控" : "歷史走勢圖", accentColor: AppColors.pelagicCyan),
                        const SizedBox(height: 12),
                        CustomCard(child: TideChartSheet(observations: dayObservations)),
                        const SizedBox(height: 22),
                        _sectionTitle(isToday ? "詳細觀測參數" : "歷史時空記錄參數"),
                        const SizedBox(height: 12),
                        MetricGrid(current: activeObservation),
                      ],
                      const SizedBox(height: 24),

                      LocalMerchantCard(
                        stationName: station.info.stationName,
                        region: currentStation.region,
                      ),
                      const SizedBox(height: 24),

                      _buildFooter(station.info.addressDescription),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: !isToday
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(selectedDateProvider.notifier).state = DateTime.now();
              },
              backgroundColor: AppColors.pelagicCyan,
              foregroundColor: AppColors.abyssBlack,
              elevation: 4,
              icon: const Icon(Icons.today_rounded, size: 18),
              label: const Text("返回今日", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            )
          : null,
    );
  }

  void _showShareModal(BuildContext context, TideStationData station) {
    final GlobalKey reportKey = GlobalKey();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.abyssBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
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
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pelagicCyan,
                    foregroundColor: AppColors.abyssBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text("生成戰報並分享至 LINE / 社群", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
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
      padding: const EdgeInsets.only(left: 12.0, top: 12, bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Scaffold.of(context).openDrawer();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.near_me_rounded, color: AppColors.pelagicCyan, size: 13),
              SizedBox(width: 4),
              Text("測站", style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {Color? accentColor}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: accentColor ?? AppColors.pelagicCyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastList(List<TideForecast> forecasts) {
    if (forecasts.isEmpty) {
      return const CustomCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("該日期暫無潮位轉向紀錄", style: TextStyle(color: AppColors.textTertiary)),
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
            leading: Icon(
              isHigh ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
              color: isHigh ? AppColors.hazardCoral : AppColors.pelagicCyan, 
              size: 18,
            ),
            title: Text(
              "${DateFormat('HH:mm').format(f.dateTime)} · ${f.tideType}", 
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 14),
            ),
            trailing: Text(
              "${f.tideHeight} cm", 
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textSecondary),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _infoCard(String title, String content) {
    return CustomCard(
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.pelagicCyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35)),
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
        const Text("測站數據拓撲", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          desc.isEmpty ? "中央氣象署 (CWA) 官方數據 · 雙軌邊緣運算拓撲。" : desc, 
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, height: 1.4),
        ),
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
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.hazardCoral),
          const SizedBox(height: 16),
          const Text("海象數據暫時中斷", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text("請檢查網路連線或稍後重新載入", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pelagicCyan, 
              foregroundColor: AppColors.abyssBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => ref.refresh(tideViewDataProvider), 
            child: const Text("重新整理", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataUI(WidgetRef ref, DateTime date, String name) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.event_busy_rounded, size: 56, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        Text("$name 歷史水文存檔", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(
          "氣象署實測數據僅即時保留近 48 小時\n${DateFormat('yyyy/MM/dd').format(date)} 暫無實測存檔", 
          textAlign: TextAlign.center, 
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pelagicCyan, 
            foregroundColor: AppColors.abyssBlack,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => ref.read(selectedDateProvider.notifier).state = DateTime.now(),
          child: const Text("返回今日觀測", style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}