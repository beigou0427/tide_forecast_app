import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/tide_provider.dart';
import '../data/tide_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/share_util.dart';
import '../../../core/utils/solunar_util.dart';
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

/// Apple 首席設計工藝：雙軌自適應主座艙 (30天歷史回溯+調和補位版)
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        await NotificationService.init();
        await FcmService.init();
      } catch (e) {
        debugPrint("推播服務初始化異常: $e");
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMaritimeSafetyConsent());
  }

  Future<void> _checkMaritimeSafetyConsent() async {
    final prefs = await SharedPreferences.getInstance();
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
            Icon(Icons.shield_rounded, color: AppColors.hazardCoral, size: 24),
            SizedBox(width: 10),
            Text(
              "海事安全與法律免責聲明",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.5,
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
                  color: AppColors.hazardCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hazardCoral.withValues(alpha: 0.3), width: 0.5),
                ),
                child: const Text(
                  "⚠️ 敬告所有出海作釣、潛水與水上運動玩家：本聲明具備法律合意效力，進入前請務必詳閱。",
                  style: TextStyle(fontSize: 11.5, color: AppColors.hazardCoral, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "1. 【非航行與人身安全保證工具】\n本系統所有數據（包括即時浪高、風速、潮位走勢及老船長 AI 安全評估）均來自氣象署公開遙測與數值演算法推算，僅供休閒與參考用途。嚴禁作為船舶正式航行、避難、外礁無防護登礁作業或人身財產安全之唯一依據。",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 10),
              const Text(
                "2. 【海洋不可抗力與長湧風險】\n台灣近岸水文瞬息萬變，外海長週期湧浪（俗稱瘋狗浪）極具突發性與不可預測性。從事任何水上或沿岸活動，使用者應自備合格救生衣、防滑釘鞋及安全通訊設備，並隨時觀察現場浪況。",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 10),
              const Text(
                "3. 【完全自負風險與責任限制】\n使用者點擊同意進入本程式，即代表明確理解並承諾自負所有出海與作釣之人身安全責任。在法律允許之最大範圍內，本應用程式開發者及發行方不對任何因不可抗力、自然災害或依賴本數據所衍生之直接或間接人身傷亡與財產損失承擔任何法律賠償責任。",
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
              child: const Text("我已詳讀並承諾自負個人安全責任", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClassic = ref.watch(isClassicThemeProvider);
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

    final Color classicModeColor = isToday 
        ? const Color(0xFF0077B6) 
        : (isFuture ? const Color(0xFF3F51B5) : const Color(0xFFE65100));

    return Scaffold(
      backgroundColor: isClassic ? AppColors.classicBg : AppColors.abyssBlack,
      drawer: StationDrawer(currentId: currentId),
      body: RefreshIndicator(
        color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan,
        backgroundColor: isClassic ? Colors.white : AppColors.abyssCard,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          return await ref.refresh(tideViewDataProvider.future);
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
                        color: isToday 
                            ? (isClassic ? Colors.white : AppColors.pelagicCyan) 
                            : (isFuture ? Colors.indigoAccent : AppColors.hazardCoral),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isToday ? "海象指揮中心" : (isFuture ? "未來預報模式" : "歷史觀測回測"),
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
                _buildCompactAction(
                  icon: isClassic ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  color: isClassic ? Colors.white : AppColors.bioGold,
                  tooltip: isClassic ? "切換為深淵黑金夜戰模式" : "切換為烈日高對比白藍模式",
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(isClassicThemeProvider.notifier).setClassicTheme(!isClassic);
                  },
                ),
                _buildCompactAction(
                  icon: Icons.share_rounded,
                  color: Colors.white,
                  tooltip: "產出海象戰報分享",
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
              error: (err, _) => SliverFillRemaining(child: _buildErrorUI(err.toString(), ref, isClassic)),
              data: (viewData) {
                final station = viewData.stationData;
                final isBuoy = allStations.any((s) => s.id == currentId && s.isBuoy);

                final dayForecasts = station.forecasts.where((f) =>
                    DateFormat('yyyyMMdd').format(f.dateTime) == selectedKey).toList();

                final dayObservations = isToday
                    ? station.observations
                    : station.observations.where((o) => DateFormat('yyyyMMdd').format(o.dateTime) == selectedKey).toList();

                // 核心突破：即使沒有該日的感測器快取，也絕不再以 blank 畫面打發用戶，無縫啟用歷史天文回溯
                final bool isPastWithoutSensor = !isToday && !isFuture && dayObservations.isEmpty;

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

                      // 天文朔望月 phase 對所有日期 100% 精確有效
                      SolunarCard(selectedDate: selectedDate),
                      const SizedBox(height: 20),

                      if (isFuture) ...[
                        _sectionTitle("🌟 ${DateFormat('MM/dd').format(selectedDate)} 專家級潮汐預報", accentColor: Colors.indigoAccent, isClassic: isClassic),
                        const SizedBox(height: 12),
                        _buildForecastList(context, dayForecasts.isNotEmpty ? dayForecasts : station.forecasts.take(4).toList()),
                        const SizedBox(height: 22),
                        
                        _sectionTitle("🌊 預測潮位走勢 (餘弦調和擬合)", accentColor: isClassic ? const Color(0xFF0077B6) : AppColors.bioGold, isClassic: isClassic),
                        const SizedBox(height: 12),
                        CustomCard(
                          child: TideChartSheet(
                            observations: const [],
                            futureForecasts: station.forecasts,
                            targetDate: selectedDate,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _infoCard(context, "預報模式說明", "您正在查看未來預報。圖表已透過航海調和演算法將滿乾潮預測點擬合為平滑走勢曲線。"),
                      ] else if (isPastWithoutSensor) ...[
                        // 🌟 歷史天文調和回溯模式：消滅「48小時無資料即死機」
                        _sectionTitle("🌌 歷史天文調和回溯模式", accentColor: AppColors.bioGold, isClassic: isClassic),
                        const SizedBox(height: 12),
                        _buildAstroHindcastCard(context, selectedDate, station.info.stationName, isClassic),
                      ] else if (activeObservation != null) ...[
                        // 實時或 30 天時間序列金庫沉積的真實觀測
                        HeroMetricCard(current: activeObservation, isBuoy: isBuoy),
                        const SizedBox(height: 14),
                        SafetyAlert(current: activeObservation),
                        const SizedBox(height: 14),
                        
                        WindCompassCard(current: activeObservation),

                        if (dayForecasts.isNotEmpty || station.forecasts.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          _sectionTitle(isToday ? "今日滿乾潮時程" : "當日滿乾潮時程", accentColor: isClassic ? const Color(0xFF0077B6) : AppColors.bioGold, isClassic: isClassic),
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
                        const SizedBox(height: 22),
                        _sectionTitle(isToday ? "詳細觀測參數" : "歷史時空記錄參數", isClassic: isClassic),
                        const SizedBox(height: 12),
                        MetricGrid(current: activeObservation),
                      ],
                      const SizedBox(height: 24),

                      LocalMerchantCard(
                        stationName: station.info.stationName,
                        region: currentStation.region,
                      ),
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
      floatingActionButton: !isToday
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(selectedDateProvider.notifier).state = DateTime.now();
              },
              backgroundColor: isClassic ? classicModeColor : AppColors.pelagicCyan,
              foregroundColor: isClassic ? Colors.white : AppColors.abyssBlack,
              elevation: 4,
              icon: const Icon(Icons.today_rounded, size: 18),
              label: const Text("返回今日", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            )
          : null,
    );
  }

  // 🌟 歷史天文調和補位卡片（消滅 48 小時截斷遺憾）
  Widget _buildAstroHindcastCard(BuildContext context, DateTime date, String stationName, bool isClassic) {
    final solunar = SolunarUtil.calculate(date);
    final dateStr = DateFormat('yyyy/MM/dd').format(date);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bioGold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.bioGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$dateStr · 天文水文調和推算",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "此日期早於本地快取建立時間，已啟用天文物理補位",
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isClassic ? Colors.grey.shade200 : AppColors.glassBorder, 
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• 當日天體引力屬性：【${solunar.tideCategory} (${solunar.lunarDateStr})】",
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w700, 
                    color: isClassic ? const Color(0xFF023E8A) : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "• 魚群活躍指數推演：【${solunar.fishActivityScore}%】",
                  style: const TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w700, 
                    color: AppColors.bioGold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "• 老船長出海戰術指引：${solunar.biteWindowAdvice}",
                  style: TextStyle(
                    fontSize: 11.5, 
                    color: isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "💡 提示：氣象署官方感測器原始電文僅暫存 48 小時。本系統現已啟動後端 30 天時間序列金庫，今後所有測站之浪高、風速與水溫將隨時間自動沉積，提供您完整的實測回溯。",
            style: TextStyle(
              fontSize: 10.5, 
              color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary, 
              height: 1.4,
            ),
          ),
        ],
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
                    await Future.delayed(const Duration(milliseconds: 120));
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
    return CustomCard(
      child: Column(
        children: forecasts.map((f) {
          bool isHigh = f.tideType.contains("滿");
          return ListTile(
            dense: true,
            leading: Icon(
              isHigh ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
              color: isHigh 
                  ? (isLight ? Colors.redAccent : AppColors.hazardCoral) 
                  : (isLight ? Colors.blueAccent : AppColors.pelagicCyan), 
              size: 18,
            ),
            title: Text(
              "${DateFormat('HH:mm').format(f.dateTime)} · ${f.tideType}", 
              style: TextStyle(
                fontWeight: FontWeight.w700, 
                color: isLight ? Colors.black87 : AppColors.textPrimary, 
                fontSize: 14,
              ),
            ),
            trailing: Text(
              "${f.tideHeight} cm", 
              style: TextStyle(
                fontWeight: FontWeight.w800, 
                fontSize: 16, 
                color: isLight ? Colors.blueGrey : AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _infoCard(BuildContext context, String title, String content) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return CustomCard(
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: isLight ? const Color(0xFF0077B6) : AppColors.pelagicCyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: TextStyle(
                    fontWeight: FontWeight.w700, 
                    fontSize: 13.5, 
                    color: isLight ? const Color(0xFF023E8A) : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content, 
                  style: TextStyle(
                    color: isLight ? Colors.blueGrey : AppColors.textSecondary, 
                    fontSize: 11.5, 
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    if (picked != null) ref.read(selectedDateProvider.notifier).state = picked;
  }

  Widget _buildErrorUI(String error, WidgetRef ref, bool isClassic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: isClassic ? Colors.redAccent : AppColors.hazardCoral),
          const SizedBox(height: 16),
          Text(
            "海象數據暫時中斷", 
            style: TextStyle(
              fontWeight: FontWeight.w800, 
              fontSize: 17, 
              color: isClassic ? Colors.black87 : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "請檢查網路連線或稍後重新載入", 
              textAlign: TextAlign.center, 
              style: TextStyle(
                color: isClassic ? Colors.grey : AppColors.textSecondary, 
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan, 
              foregroundColor: isClassic ? Colors.white : AppColors.abyssBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => ref.refresh(tideViewDataProvider), 
            child: const Text("重新整理", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
