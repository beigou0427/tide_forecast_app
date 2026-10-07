import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/tide_provider.dart';
import '../data/tide_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/share_util.dart';
import '../../../core/theme/app_theme.dart';
import '../../premium/services/premium_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/global_error_trap.dart';
import '../../catch_log/presentation/catch_log_page.dart';
import 'station_guide_page.dart';

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
import 'widgets/bite_radar_section.dart';
import 'widgets/astro_hindcast_card.dart';
import 'widgets/classic_pure_tide_table.dart';
import '../../../shared/widgets/custom_card.dart';

final isPureTideModeProvider = StateNotifierProvider<PureTideModeNotifier, bool>((ref) {
  return PureTideModeNotifier();
});

class PureTideModeNotifier extends StateNotifier<bool> {
  static const String _prefKey = 'is_pure_tide_mode_v2';

  PureTideModeNotifier() : super(false) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_prefKey) ?? false;
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, state);
    } catch (_) {}
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _pushInitTimer;

  @override
  void initState() {
    super.initState();
    _pushInitTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      try {
        await NotificationService.init();
        await FcmService.init();
      } catch (e, stack) {
        GlobalErrorTrap.recordException(e, stackTrace: stack, contextTag: "PushNotificationInit", severity: ErrorSeverity.warning);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkMaritimeSafetyConsent();
      }
    });
  }

  @override
  void dispose() {
    _pushInitTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkMaritimeSafetyConsent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final bool hasAgreed = prefs.getBool('has_agreed_maritime_safety_v2') ?? false;
    
    if (!hasAgreed && mounted) {
      _showMandatorySafetyDisclaimer(context, prefs);
    }
  }

  void _showMandatorySafetyDisclaimer(BuildContext context, SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.abyssCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.anchor_rounded, color: AppColors.bioGold, size: 24),
            SizedBox(width: 10),
            Text(
              "老船長出海安全須知",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bioGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.3), width: 0.5),
                ),
                child: const Text(
                  "⚓ 歡迎登艦！出海作釣、潛水與航海活動具備自然不可抗力，請共同維護航行安全。",
                  style: TextStyle(fontSize: 12, color: AppColors.bioGold, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "1. 【海事水文參考用途】\n本系統即時浪高、風速、潮位走勢錨定中央氣象署官方遙測，供休閒作釣與行程規劃參考，嚴禁作為唯一避難或吃水航行依據。",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 10),
              const Text(
                "2. 【長湧與瘋狗浪自主防衛】\n台灣沿岸海象多變，外海長湧極易誘發近岸洗岸浪。登礁作業請務必穿著合格救生衣與防滑釘鞋，隨時注意身後退路。",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 10),
              const Text(
                "3. 【人身安全自主負責】\n進入本系統即代表您理解並承諾自負各項水上作業之人身安全責任，老船長團隊竭誠為您的航安提供最即時的情報支援。",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pelagicCyan,
                foregroundColor: AppColors.abyssBlack,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () async {
                HapticFeedback.heavyImpact();
                await prefs.setBool('has_agreed_maritime_safety_v2', true);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("同意並進入海象指揮中心", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClassic = ref.watch(isClassicThemeProvider);
    final isPureTide = ref.watch(isPureTideModeProvider);
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
    final bool isProUser = premiumState.isPremium || premiumState.isFounder;

    final Color classicModeColor = isToday 
        ? const Color(0xFF0077B6) 
        : (isFuture ? const Color(0xFF3F51B5) : const Color(0xFFE65100));

    final String pageTitle = isPureTide 
        ? "純潮汐航海儀表" 
        : (isToday ? "今日即時海象" : (isFuture ? "未來 30 天潮位預報" : "歷史水文實測"));

    return Scaffold(
      backgroundColor: isClassic ? AppColors.classicBg : AppColors.abyssBlack,
      drawer: StationDrawer(currentId: currentId),
      body: RefreshIndicator(
        color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan,
        backgroundColor: isClassic ? Colors.white : AppColors.abyssCard,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          try {
            return await ref.refresh(tideViewDataProvider.future);
          } catch (e) {
            debugPrint("重新載入異常降級: $e");
          }
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              backgroundColor: isClassic 
                  ? classicModeColor 
                  : AppColors.abyssBlack.withValues(alpha: 0.88),
              elevation: isClassic ? 1 : 0,
              leadingWidth: 78,
              leading: Builder(builder: (context) => _buildRegionButton(context, isClassic)),
              centerTitle: true,
              title: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isPureTide
                            ? AppColors.bioGold
                            : (isToday 
                                ? (isClassic ? Colors.white : AppColors.pelagicCyan) 
                                : (isFuture ? Colors.indigoAccent : AppColors.hazardCoral)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pageTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: isClassic ? 0 : -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(isPureTideModeProvider.notifier).toggle();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPureTide 
                            ? AppColors.bioGold 
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isPureTide ? AppColors.bioGold : Colors.white24,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPureTide ? Icons.waves_rounded : Icons.radar_rounded,
                            size: 14,
                            color: isPureTide ? Colors.black87 : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPureTide ? "純潮汐" : "全海象",
                            style: TextStyle(
                              color: isPureTide ? Colors.black87 : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _buildCompactAction(
                  icon: isClassic ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  color: isClassic ? Colors.white : AppColors.bioGold,
                  tooltip: isClassic ? "深淵黑金夜戰" : "烈日高對比",
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(isClassicThemeProvider.notifier).setClassicTheme(!isClassic);
                  },
                ),
                _buildCompactAction(
                  icon: Icons.share_rounded,
                  color: Colors.white,
                  tooltip: "戰報分享",
                  onPressed: tideViewAsync.value == null
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _showShareModal(context, tideViewAsync.value!.stationData);
                        },
                ),
                _buildCompactAction(
                  icon: isFavorited ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFavorited ? AppColors.bioGold : Colors.white,
                  tooltip: isFavorited ? "取消收藏" : "加入最愛",
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    await ref.read(tideRepositoryProvider).toggleFavorite(currentId);
                    ref.invalidate(favoriteStationsProvider);
                  },
                ),
                _buildCompactAction(
                  icon: Icons.calendar_month_rounded,
                  color: premiumState.isPremium ? AppColors.bioGold : Colors.white,
                  tooltip: "選擇日期",
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _openCalendar(context, ref);
                  },
                ),
                const SizedBox(width: 6),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DateRibbon(
                      selectedDate: selectedDate, 
                      themeColor: isClassic ? classicModeColor : AppColors.pelagicCyan,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            tideViewAsync.when(
              loading: () => SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan, 
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: _buildOfflineArmorUI(ref, currentStation.name, isClassic),
              ),
              data: (viewData) {
                final station = viewData.stationData;
                final isBuoy = allStations.any((s) => s.id == currentId && s.isBuoy);

                final dayForecasts = station.forecasts.where((f) =>
                    DateFormat('yyyyMMdd').format(f.dateTime) == selectedKey).toList();

                final dayObservations = isToday
                    ? station.observations
                    : station.observations.where((o) => DateFormat('yyyyMMdd').format(o.dateTime) == selectedKey).toList();

                final bool isPastWithoutSensor = !isToday && !isFuture && dayObservations.isEmpty;

                final Observation? activeObservation = dayObservations.isNotEmpty
                    ? dayObservations.last
                    : (station.observations.isNotEmpty ? station.observations.last : null);

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. 海事簡報卡 (全海象模式且今日時顯示)
                      if (isToday && !isPureTide) ...[
                        SeaBriefingCard(station: station, distance: viewData.distanceKm),
                        const SizedBox(height: 20),
                      ],

                      // 2. 測站地標抬頭
                      StationHeader(info: station.info, distanceKm: isToday ? viewData.distanceKm : null),
                      const SizedBox(height: 16),
                      
                      // 🌟 3. 核心亮點：當開啟「純潮汐儀表」模式時，立即置頂呈現 VVIP 經典純潮汐對照表！
                      if (isPureTide) ...[
                        ClassicPureTideTable(
                          station: station,
                          selectedDate: selectedDate,
                          isClassic: isClassic,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 4. Waze 現場雷達 (全海象模式顯示)
                      if (isToday && !isPureTide) ...[
                        UgcRadarCard(
                          stationId: currentId,
                          stationName: station.info.stationName,
                          waveHeight: activeObservation?.waveHeight,
                          windSpeed: activeObservation?.windSpeed,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 5. 天文月相卡 (全海象模式顯示)
                      if (!isPureTide) ...[
                        SolunarCard(selectedDate: selectedDate),
                        const SizedBox(height: 20),
                      ],

                      // 6. 魚種活性雷達 (全海象模式顯示)
                      if (!isPureTide) ...[
                        BiteRadarSection(
                          station: station,
                          selectedDate: selectedDate,
                          isClassic: isClassic,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 7. 未來預報模式
                      if (isFuture) ...[
                        if (!isPureTide) ...[
                          _sectionTitle("🌟 ${DateFormat('MM/dd').format(selectedDate)} 滿乾潮時程與潮差走水", accentColor: Colors.indigoAccent, isClassic: isClassic),
                          const SizedBox(height: 12),
                          _buildForecastList(context, dayForecasts.isNotEmpty ? dayForecasts : station.forecasts.take(4).toList()),
                          const SizedBox(height: 22),
                        ],
                        
                        _sectionTitle("🌊 預測潮位走勢 (錨定官方極值)", accentColor: isClassic ? const Color(0xFF0077B6) : AppColors.bioGold, isClassic: isClassic),
                        const SizedBox(height: 12),
                        CustomCard(
                          child: TideChartSheet(
                            observations: const [],
                            futureForecasts: station.forecasts,
                            targetDate: selectedDate,
                          ),
                        ),
                      ] else if (isPastWithoutSensor) ...[
                        _sectionTitle("🌌 歷史天文調和回溯模式", accentColor: AppColors.bioGold, isClassic: isClassic),
                        const SizedBox(height: 12),
                        AstroHindcastCard(
                          selectedDate: selectedDate,
                          stationName: station.info.stationName,
                          isClassic: isClassic,
                        ),
                      ] else if (activeObservation != null) ...[
                        // 實測水文數據
                        HeroMetricCard(current: activeObservation, isBuoy: isBuoy),
                        const SizedBox(height: 14),

                        SafetyAlert(current: activeObservation),
                        const SizedBox(height: 14),

                        WindCompassCard(current: activeObservation),

                        // 全海象模式下呈現標準條列時程；純潮汐模式已由頂部經典對照表接管
                        if (!isPureTide && (dayForecasts.isNotEmpty || station.forecasts.isNotEmpty)) ...[
                          const SizedBox(height: 22),
                          _sectionTitle(isToday ? "今日滿乾潮時程與走水黃金期" : "當日滿乾潮時程與走水黃金期", accentColor: isClassic ? const Color(0xFF0077B6) : AppColors.bioGold, isClassic: isClassic),
                          const SizedBox(height: 12),
                          _buildForecastList(context, dayForecasts.isNotEmpty ? dayForecasts : station.forecasts.take(4).toList()),
                        ],

                        const SizedBox(height: 22),
                        _sectionTitle(isToday ? "24h 走勢監控" : "歷史實測走勢圖", accentColor: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan, isClassic: isClassic),
                        const SizedBox(height: 12),
                        CustomCard(
                          child: TideChartSheet(
                            observations: dayObservations,
                            targetDate: selectedDate,
                          ),
                        ),

                        if (!isPureTide) ...[
                          const SizedBox(height: 22),
                          _sectionTitle(isToday ? "詳細觀測參數" : "歷史時空記錄參數", isClassic: isClassic),
                          const SizedBox(height: 12),
                          MetricGrid(current: activeObservation),
                        ],
                      ],

                      // 釣具店資訊 (僅在全海象且非 PRO 用戶時呈現)
                      if (!isPureTide && !isProUser) ...[
                        const SizedBox(height: 24),
                        LocalMerchantCard(
                          stationName: station.info.stationName,
                          region: currentStation.region,
                        ),
                      ],

                      const SizedBox(height: 24),
                      _buildFooter(station.info.addressDescription, isClassic),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: (isPureTide && isToday)
          ? null
          : (isToday
              ? FloatingActionButton.extended(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CatchLogPage()));
                  },
                  backgroundColor: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan,
                  foregroundColor: isClassic ? Colors.white : AppColors.abyssBlack,
                  elevation: 4,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text("中魚紀錄 · 疊加水文", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(selectedDateProvider.notifier).state = DateTime.now();
                  },
                  backgroundColor: isClassic ? classicModeColor : AppColors.pelagicCyan,
                  foregroundColor: isClassic ? Colors.white : AppColors.abyssBlack,
                  elevation: 4,
                  icon: const Icon(Icons.today_rounded, size: 18),
                  label: const Text("返回今日", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                )),
    );
  }

  Widget _buildOfflineArmorUI(WidgetRef ref, String stationName, bool isClassic) {
    final Color titleColor = isClassic ? AppColors.classicText : AppColors.textPrimary;
    final Color shieldColor = isClassic ? const Color(0xFF0077B6) : AppColors.bioGold;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: shieldColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: shieldColor.withValues(alpha: 0.35), width: 1.0),
              ),
              child: Icon(Icons.offline_bolt_rounded, size: 48, color: shieldColor),
            ),
            const SizedBox(height: 20),
            Text(
              "外海離線水文預報", 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 18, 
                color: titleColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "[$stationName] 目前通訊網路未連通\n已啟用天文調和模型，滿乾潮時程依然精準有效", 
              textAlign: TextAlign.center, 
              style: TextStyle(
                color: isClassic ? Colors.grey.shade600 : AppColors.textSecondary, 
                fontSize: 12.5, 
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isClassic ? Colors.grey.shade300 : AppColors.glassBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text("水文百科", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StationGuidePage()));
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan, 
                    foregroundColor: isClassic ? Colors.white : AppColors.abyssBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text("重新整理", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                  onPressed: () => ref.refresh(tideViewDataProvider), 
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, color: color, size: 19),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
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
                    final navigator = Navigator.of(ctx);
                    await Future.delayed(const Duration(milliseconds: 120));
                    await ShareUtil.captureAndShare(reportKey, stationName: station.info.stationName);
                    if (ctx.mounted) navigator.pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegionButton(BuildContext context, bool isClassic) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, top: 12, bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Scaffold.of(context).openDrawer();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isClassic ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isClassic ? Colors.white.withValues(alpha: 0.35) : AppColors.glassBorder, 
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.near_me_rounded, color: isClassic ? Colors.white : AppColors.pelagicCyan, size: 12),
              const SizedBox(width: 3),
              Text(
                isClassic ? "地區" : "測站", 
                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {Color? accentColor, required bool isClassic}) {
    if (isClassic) {
      return Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: accentColor ?? const Color(0xFF023E8A),
        ),
      );
    }
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

  Widget _buildForecastList(BuildContext context, List<TideForecast> forecasts) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (forecasts.isEmpty) {
      return CustomCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "該日期暫無潮位轉向紀錄", 
              style: TextStyle(color: isLight ? Colors.grey : AppColors.textTertiary),
            ),
          ),
        ),
      );
    }

    final sorted = List<TideForecast>.from(forecasts)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: List.generate(sorted.length, (index) {
          final f = sorted[index];
          final bool isHigh = f.tideType.contains("滿");
          final double? currentHeight = double.tryParse(f.tideHeight);

          String diffBadge = "";
          Color diffColor = Colors.transparent;
          if (index > 0 && currentHeight != null) {
            final double? prevHeight = double.tryParse(sorted[index - 1].tideHeight);
            if (prevHeight != null) {
              final double diff = (currentHeight - prevHeight).abs();
              final String flowSpeed = diff >= 160.0 ? "大急流" : (diff >= 90.0 ? "中走水" : "微緩流");
              diffBadge = isHigh 
                  ? "▲ 漲潮 +${diff.toStringAsFixed(0)}cm ($flowSpeed)" 
                  : "▼ 退潮 -${diff.toStringAsFixed(0)}cm ($flowSpeed)";
              diffColor = diff >= 160.0 
                  ? AppColors.bioGold 
                  : (isLight ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
            }
          }

          String slackOrBiteWindow = "";
          if (isHigh) {
            final biteStart = f.dateTime.add(const Duration(hours: 1, minutes: 15));
            final biteEnd = f.dateTime.add(const Duration(hours: 2, minutes: 45));
            final startStr = DateFormat('HH:mm').format(biteStart);
            final endStr = DateFormat('HH:mm').format(biteEnd);
            slackOrBiteWindow = "🔥 滿退2分走水期：$startStr ~ $endStr (魚群大開口)";
          } else {
            if (currentHeight != null && currentHeight <= 30.0) {
              slackOrBiteWindow = "🚨 乾潮底極淺水位：防範暗礁擱淺危險！";
            } else {
              final drySlackStart = f.dateTime.subtract(const Duration(minutes: 30));
              final drySlackEnd = f.dateTime.add(const Duration(minutes: 30));
              final sStr = DateFormat('HH:mm').format(drySlackStart);
              final eStr = DateFormat('HH:mm').format(drySlackEnd);
              slackOrBiteWindow = "⏳ 乾潮底停潮緩流：$sStr ~ $eStr (宜攻深坎流溝)";
            }
          }

          final bool isDangerShallow = !isHigh && currentHeight != null && currentHeight <= 30.0;

          return Column(
            children: [
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isHigh 
                        ? (isLight ? Colors.red.shade50 : AppColors.hazardCoral.withValues(alpha: 0.15))
                        : (isLight ? Colors.blue.shade50 : AppColors.pelagicCyan.withValues(alpha: 0.15))),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHigh ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
                    color: isHigh 
                        ? (isLight ? Colors.redAccent : AppColors.hazardCoral) 
                        : (isLight ? Colors.blueAccent : AppColors.pelagicCyan), 
                    size: 16,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(f.dateTime), 
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        color: isLight ? Colors.black87 : AppColors.textPrimary, 
                        fontSize: 15,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isHigh 
                            ? (isLight ? Colors.redAccent.withValues(alpha: 0.1) : AppColors.hazardCoral.withValues(alpha: 0.15))
                            : (isLight ? Colors.blueAccent.withValues(alpha: 0.1) : AppColors.pelagicCyan.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        f.tideType,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: isHigh 
                              ? (isLight ? Colors.redAccent : AppColors.hazardCoral) 
                              : (isLight ? Colors.blueAccent : AppColors.pelagicCyan),
                        ),
                      ),
                    ),
                    if (diffBadge.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        diffBadge,
                        style: TextStyle(fontSize: 10.5, color: diffColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    slackOrBiteWindow,
                    style: TextStyle(
                      fontSize: 11, 
                      color: isDangerShallow 
                          ? AppColors.hazardCoral 
                          : (isHigh ? AppColors.bioGold : (isLight ? Colors.blueGrey : AppColors.textTertiary)), 
                      fontWeight: isHigh || isDangerShallow ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
                trailing: Text(
                  "${f.tideHeight} cm", 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 17, 
                    color: isDangerShallow ? AppColors.hazardCoral : (isLight ? Colors.blueGrey.shade800 : AppColors.textPrimary),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (index < sorted.length - 1)
                Divider(
                  height: 1, 
                  color: isLight ? Colors.grey.shade200 : AppColors.glassBorder,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFooter(String desc, bool isClassic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "測站數據拓撲", 
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w700, 
            color: isClassic ? const Color(0xFF023E8A) : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc.isEmpty ? "中央氣象署 (CWA) 官方數據 · 雙軌邊緣運算拓撲。" : desc, 
          style: TextStyle(
            color: isClassic ? Colors.grey : AppColors.textTertiary, 
            fontSize: 11, 
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.gavel_rounded, size: 14, color: AppColors.textTertiary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "⚠️ 法律免責聲明：本 App 所有水文預報、AI 建議與安全分數僅供休閒與參考用途，非屬官方航海指定設備。出海作釣請穿著合格救生衣與防滑釘鞋，個人人身安全請完全自負。",
                  style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _openCalendar(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 30));
    final lastDate = now.add(const Duration(days: 30));
    
    DateTime initial = ref.read(selectedDateProvider);
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: "選擇回測或預報日期",
    );
    if (picked != null && mounted) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }
}