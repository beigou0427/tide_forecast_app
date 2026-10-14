import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../main.dart' show appNavigatorKey;
import '../providers/tide_provider.dart';
import '../data/tide_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/bite_prediction_engine.dart';
import '../../../core/utils/solunar_util.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/global_error_trap.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/review_service.dart';
import '../../onboarding/presentation/founder_welcome_dialog.dart';
import '../../premium/services/premium_service.dart';
import '../../premium/presentation/premium_page.dart';
import '../../catch_log/presentation/catch_log_page.dart';

import 'tide_chart_sheet.dart';
import 'widgets/station_drawer.dart';
import 'widgets/station_header.dart';
import 'widgets/hero_metric_card.dart';
import 'widgets/metric_grid.dart';
import 'widgets/safety_alert.dart';
import 'widgets/sea_briefing_card.dart';
import 'widgets/date_ribbon.dart';
import 'widgets/wind_compass_card.dart';
import 'widgets/classic_pure_tide_table.dart';
import 'widgets/local_merchant_card.dart';
import 'widgets/solunar_card.dart';
import 'widgets/ugc_radar_card.dart';
import '../../../shared/widgets/custom_card.dart';

final isPureTideModeProvider = StateNotifierProvider<PureTideModeNotifier, bool>((ref) {
  return PureTideModeNotifier();
});

class PureTideModeNotifier extends StateNotifier<bool> {
  static const String _prefKey = 'is_pure_tide_mode_v2';
  static const String _legacyMigratedKey = 'has_migrated_pure_tide_default';

  PureTideModeNotifier() : super(false) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasMigrated = prefs.getBool(_legacyMigratedKey) ?? false;
      final isFounder = prefs.getBool('is_founder') ?? false;

      if (isFounder && !hasMigrated) {
        state = true;
        await prefs.setBool(_prefKey, true);
        await prefs.setBool(_legacyMigratedKey, true);
      } else {
        state = prefs.getBool(_prefKey) ?? false;
      }
    } catch (_) {}
  }

  Future<void> toggle() async {
    await setMode(!state);
  }

  Future<void> setMode(bool isPure) async {
    state = isPure;
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _checkMaritimeSafetyConsent();
      _checkLegacyVvipThemeMigration();
      FounderWelcomeDialog.checkAndShowIfNeeded(context);
      _checkAndPrimeNotifications();
    });
  }

  Future<void> _checkAndPrimeNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrimed = prefs.getBool('has_primed_notifications_v3') ?? false;

    if (!hasPrimed) {
      if (!mounted) return;
      final agreed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.abyssCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: AppColors.pelagicCyan, size: 24),
              SizedBox(width: 10),
              Text("老船長通訊請求", style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "為了在滿潮前 30 分鐘向您發布「撤礁保命警報」，以及每週五派送「週末大潮出海黃金窗口」，請允許 Tide Pro 傳送推播通知給您。\n\n我們承諾：絕不發送無用垃圾訊息。",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("暫時不要", style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pelagicCyan,
                foregroundColor: AppColors.abyssBlack,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("開啟安全警報", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );

      await prefs.setBool('has_primed_notifications_v3', true);
      
      if (agreed == true) {
        _initPushServices();
      }
    } else {
      _initPushServices();
    }
  }

  Future<void> _initPushServices() async {
    try {
      NotificationService.setNavigatorKey(appNavigatorKey);
      FcmService.setNavigatorKey(appNavigatorKey);
      await NotificationService.init();
      await FcmService.init();
    } catch (e, stack) {
      GlobalErrorTrap.recordException(
        e,
        stackTrace: stack,
        contextTag: "PushNotificationInit",
        severity: ErrorSeverity.warning,
      );
    }
  }

  Future<void> _checkLegacyVvipThemeMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasMigratedTheme = prefs.getBool('has_migrated_theme_v26') ?? false;
      
      if (!hasMigratedTheme) {
        final bool isPro = prefs.getBool('is_pro') ?? false;
        if (isPro) {
          ref.read(themeModeProvider.notifier).setTheme(AppThemeMode.classicLight);
        }
        await prefs.setBool('has_migrated_theme_v26', true);
      }
    } catch (_) {}
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
              style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3),
            ),
          ],
        ),
        content: const Text(
          "歡迎登艦！出海作釣與航海活動具備自然不可抗力。本系統即時數據錨定氣象署官方遙測，供休閒參考，出海請務必穿著合格救生衣與防滑釘鞋，注意人身安全。",
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45),
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
              child: const Text("同意並進入指揮中心", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPureTide = ref.watch(isPureTideModeProvider);
    final tideViewAsync = ref.watch(tideViewDataProvider);
    final currentId = ref.watch(currentStationIdProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final favoritesAsync = ref.watch(favoriteStationsProvider);
    
    final bool isPro = ref.watch(premiumProvider.select((s) => s.isPremium || s.isFounder));

    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassicTheme = themeMode == AppThemeMode.classicLight;
    final bool isDarkAbyss = themeMode == AppThemeMode.darkAbyss;
    final bool isClassicUI = themeMode != AppThemeMode.darkAbyss;

    final allStations = ref.watch(stationListProvider).value ?? AppConstants.fallbackStations;
    final currentStation = allStations.firstWhere((s) => s.id == currentId, orElse: () => allStations.first);

    final nearestId = ref.watch(nearestStationIdProvider);
    final nearestStation = nearestId != null 
        ? allStations.firstWhere((s) => s.id == nearestId, orElse: () => allStations.first)
        : null;

    final bool isFavorited = favoritesAsync.value?.contains(currentId) ?? false;
    final now = DateTime.now();
    final String selectedKey = DateFormat('yyyyMMdd').format(selectedDate);
    final String todayKey = DateFormat('yyyyMMdd').format(now);
    final bool isToday = selectedKey == todayKey;
    final bool isFuture = selectedDate.isAfter(now) && !isToday;
    final bool isPast = !isToday && !isFuture;

    final Color modeThemeColor = isToday 
        ? const Color(0xFF1E40AF)
        : (isFuture ? const Color(0xFF2563EB) : const Color(0xFFD84315));

    final Color pageBg = isEInk ? Colors.white : (isClassicTheme ? AppColors.classicBg : AppColors.abyssBlack);
    final Color appBarBg = isEInk ? Colors.white : (isClassicTheme ? modeThemeColor : AppColors.abyssBlack.withValues(alpha: 0.88));
    final Color topIconColor = isEInk ? Colors.black : Colors.white;
    final Color ribbonThemeColor = isEInk ? Colors.black : modeThemeColor;

    final String pageTitle = isPureTide 
        ? "純潮汐航海儀表" 
        : (isToday ? "今日即時海象" : (isFuture ? "未來預報模式" : "歷史觀測回測"));

    AppThemeMode nextMode;
    IconData themeIcon;
    if (isDarkAbyss) {
      nextMode = AppThemeMode.classicLight;
      themeIcon = Icons.nights_stay_rounded;
    } else if (isClassicTheme) {
      nextMode = AppThemeMode.eInkHighContrast;
      themeIcon = Icons.wb_sunny_rounded;
    } else {
      nextMode = AppThemeMode.darkAbyss;
      themeIcon = Icons.contrast_rounded;
    }

    // 🌟 盲點一：引擎點火！將遙測與評價引擎對接潮汐視圖的生命週期
    ref.listen<AsyncValue<TideViewData>>(tideViewDataProvider, (previous, next) {
      if (next.hasValue && next.value != null && !next.isRefreshing) {
        final stationName = next.value!.stationData.info.stationName;
        // 點火 1：全漏斗遙測，餵養 Firebase 演算法
        AnalyticsService.logStationView(currentId, stationName);
        // 點火 2：喚醒被遺忘的 ASO 五星增長引擎！
        ReviewService.checkAndTriggerReview();
      }
    });

    Widget? smartFab;
    if (!isToday) {
      smartFab = FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ref.read(selectedDateProvider.notifier).state = DateTime.now();
        },
        backgroundColor: isEInk ? Colors.black : modeThemeColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.calendar_today_rounded, size: 16),
        label: const Text("返回今日", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
      );
    } else if (nearestId != null && nearestId != currentId && nearestStation != null) {
      String shortName = nearestStation.name.replaceAll(RegExp(r'[\(（].*?[\)）]'), '').trim();
      if (shortName.length > 8) shortName = "${shortName.substring(0, 8)}...";
      
      smartFab = FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.heavyImpact();
          ref.read(currentStationIdProvider.notifier).state = nearestId;
        },
        backgroundColor: isEInk ? Colors.black : const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.my_location_rounded, size: 16),
        label: Text("切換就近測站 ($shortName)", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
      );
    } else {
      // 🌟 盲點二修復：把被藏在衣櫃裡的「印鈔機」搬到首頁黃金右下角！
      smartFab = FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CatchLogPage()));
        },
        backgroundColor: isEInk ? Colors.black : AppColors.bioGold,
        foregroundColor: isEInk ? Colors.white : AppColors.abyssBlack,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_a_photo_rounded, size: 16),
        label: const Text("現場登錄大物", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      drawer: StationDrawer(currentId: currentId),
      body: RefreshIndicator(
        color: ribbonThemeColor,
        backgroundColor: Colors.white,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          try {
            return await ref.refresh(tideViewDataProvider.future);
          } catch (_) {}
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              backgroundColor: appBarBg,
              elevation: isEInk ? 1 : 0,
              leadingWidth: 84,
              leading: Builder(builder: (context) => _buildRegionButton(context, topIconColor, isEInk)),
              centerTitle: true,
              title: Text(
                pageTitle,
                style: TextStyle(fontWeight: FontWeight.w900, color: topIconColor, fontSize: 18, letterSpacing: -0.3),
              ),
              actions: [
                _buildCompactAction(
                  icon: isPureTide ? Icons.waves_rounded : Icons.radar_rounded,
                  color: isPureTide ? (isEInk ? Colors.black : AppColors.bioGold) : topIconColor,
                  tooltip: isPureTide ? "切換全海象" : "切換純潮汐",
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(isPureTideModeProvider.notifier).toggle();
                  },
                ),
                _buildCompactAction(
                  icon: themeIcon,
                  color: topIconColor,
                  tooltip: "循環切換顯示模式",
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(themeModeProvider.notifier).setTheme(nextMode);
                  },
                ),
                _buildCompactAction(
                  icon: isFavorited ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFavorited ? (isEInk ? Colors.black : AppColors.bioGold) : topIconColor,
                  tooltip: isFavorited ? "已收藏" : "加入收藏",
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    await ref.read(tideRepositoryProvider).toggleFavorite(currentId);
                    ref.invalidate(favoriteStationsProvider);
                  },
                ),
                _buildCompactAction(
                  icon: Icons.calendar_month_rounded,
                  color: topIconColor,
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
                    DateRibbon(selectedDate: selectedDate, themeColor: ribbonThemeColor),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            tideViewAsync.when(
              loading: () => SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: ribbonThemeColor, strokeWidth: 2.5)),
              ),
              error: (err, _) => SliverFillRemaining(
                child: _buildOfflineArmorUI(ref, currentStation.name, isClassicUI, isEInk),
              ),
              data: (viewData) {
                final station = viewData.stationData;
                final isBuoy = allStations.any((s) => s.id == currentId && s.isBuoy);

                final dayForecasts = station.forecasts.where((f) =>
                    DateFormat('yyyyMMdd').format(f.dateTime) == selectedKey).toList();

                final dayObservations = isToday
                    ? station.observations
                    : station.observations.where((o) => DateFormat('yyyyMMdd').format(o.dateTime) == selectedKey).toList();

                List<Observation> chartObservations = List.from(dayObservations);
                if (isFuture && chartObservations.isEmpty && dayForecasts.isNotEmpty) {
                  chartObservations = dayForecasts.map((f) {
                    double h = double.tryParse(f.tideHeight.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
                    if (h.abs() >= 6.0) h = h / 100.0; 
                    return Observation(dateTime: f.dateTime, tideHeight: h);
                  }).toList();
                }

                final Observation? activeObservation = dayObservations.isNotEmpty
                    ? dayObservations.last
                    : null;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      
                      if (isPureTide) ...[
                        _buildPaywallBlurredWrapper(
                          isPro: isPro,
                          blurMessage: "升級 PRO 解鎖經典純潮汐對照表",
                          child: ClassicPureTideTable(station: station, selectedDate: selectedDate, isClassic: isClassicUI),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (isToday && !isPureTide) ...[
                        _buildPaywallBlurredWrapper(
                          isPro: isPro,
                          blurMessage: "解鎖 PRO 獲取 AI 長湧與走水安全預警",
                          child: SeaBriefingCard(station: station, distance: viewData.distanceKm),
                        ),
                        const SizedBox(height: 16),
                      ],

                      StationHeader(info: station.info, distanceKm: isToday ? viewData.distanceKm : null),
                      const SizedBox(height: 16),

                      if (isFuture) ...[
                        _buildSectionHeader("🌟 專家級潮汐預報 (30日)", isEInk ? Colors.black : const Color(0xFF1E40AF)),
                        const SizedBox(height: 10),

                        _buildPaywallBlurredWrapper(
                          isPro: isPro,
                          blurMessage: "解鎖 PRO 查看未來 30 天詳細滿乾潮時間",
                          child: _buildV1ForecastCard(dayForecasts.isNotEmpty ? dayForecasts : station.forecasts.take(4).toList(), isClassicUI, isEInk),
                        ),
                        const SizedBox(height: 14),

                        _buildFutureInfoCard(isClassicUI),
                        const SizedBox(height: 16),

                        _buildSectionHeader("🌊 預測潮位走勢", isEInk ? Colors.black : const Color(0xFF1E40AF)),
                        const SizedBox(height: 10),
                        
                        _buildPaywallBlurredWrapper(
                          isPro: isPro,
                          blurMessage: "解鎖 PRO 查看全天候極值走勢與起流窗口",
                          child: CustomCard(
                            child: TideChartSheet(observations: chartObservations),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] 
                      else if (isPast && activeObservation == null) ...[
                        AstroHindcastCard(
                          selectedDate: selectedDate,
                          stationName: station.info.stationName,
                          isClassic: isClassicUI,
                        ),
                        const SizedBox(height: 16),
                      ] 
                      else ...[
                        if (activeObservation != null) ...[
                          HeroMetricCard(current: activeObservation, isBuoy: isBuoy),
                          const SizedBox(height: 14),

                          SafetyAlert(current: activeObservation),
                          const SizedBox(height: 14),

                          CustomCard(
                            child: TideChartSheet(observations: chartObservations),
                          ),
                          const SizedBox(height: 20),

                          if (!isPureTide) ...[
                            _buildSectionHeader("📋 詳細觀測參數", isEInk ? Colors.black : modeThemeColor),
                            const SizedBox(height: 12),
                            MetricGrid(current: activeObservation),
                            const SizedBox(height: 16),

                            WindCompassCard(current: activeObservation),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ],

                      if (!isPureTide) ...[
                        SolunarCard(selectedDate: selectedDate),
                        const SizedBox(height: 16),
                      ],

                      if (!isPureTide) ...[
                        BiteRadarSection(
                          station: station,
                          selectedDate: selectedDate,
                          isClassic: isClassicUI,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (isToday && !isPureTide) ...[
                        UgcRadarCard(
                          stationId: currentId,
                          stationName: station.info.stationName,
                          waveHeight: activeObservation?.waveHeight,
                          windSpeed: activeObservation?.windSpeed,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (!isPureTide) ...[
                        _buildSectionHeader("🏪 港區補給與海事支援", isEInk ? Colors.black : modeThemeColor),
                        const SizedBox(height: 12),
                        LocalMerchantCard(
                          stationName: station.info.stationName,
                          region: currentStation.region,
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 16),
                      _buildV1Footer(isFuture, isClassicUI),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: smartFab,
    );
  }

  Widget _buildPaywallBlurredWrapper({
    required bool isPro,
    required String blurMessage,
    required Widget child,
  }) {
    if (isPro) return child;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Opacity(
              opacity: 0.6,
              child: IgnorePointer(child: child),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, color: AppColors.bioGold, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      blurMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bioGold,
                          foregroundColor: Colors.black87,
                          elevation: 8,
                          shadowColor: AppColors.bioGold.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage()));
                        },
                        child: const Text("立即解鎖", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildV1ForecastCard(List<TideForecast> forecasts, bool isClassicUI, bool isEInk) {
    return Container(
      decoration: BoxDecoration(
        color: isClassicUI ? Colors.white : AppColors.abyssCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isClassicUI ? (isEInk ? Colors.black : Colors.grey.shade100) : AppColors.glassBorder, width: isEInk ? 1.5 : 0.5),
        boxShadow: (isClassicUI && !isEInk) ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: forecasts.map((f) {
          final bool isHigh = f.tideType.contains("滿");
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isHigh ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: isEInk ? Colors.black : (isHigh ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)),
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "${DateFormat('HH:mm').format(f.dateTime)} - ${f.tideType}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isClassicUI ? const Color(0xFF0F172A) : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${f.tideHeight} cm",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isEInk ? Colors.black : (isClassicUI ? const Color(0xFF334155) : AppColors.pelagicCyan),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFutureInfoCard(bool isClassicUI) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClassicUI ? Colors.white : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isClassicUI ? Colors.grey.shade100 : AppColors.glassBorder, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.memory_rounded, color: isClassicUI ? const Color(0xFF3B82F6) : AppColors.pelagicCyan, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "M4 物理調和與天體推演引擎",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: isClassicUI ? const Color(0xFF0F172A) : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "未來時空預測模式已啟動。系統正以天體引力模型結合氣象署歷史參數進行高維度推算。實況波高與陣風數據將於該日由實體感測器回傳。",
                  style: TextStyle(
                    fontSize: 12,
                    color: isClassicUI ? Colors.grey.shade600 : AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildV1Footer(bool isFuture, bool isClassicUI) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SSOT 官方數據庫節點",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isClassicUI ? const Color(0xFF0F172A) : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isFuture
              ? "天體引力模型推算中 (非即時感測)"
              : "中央氣象署官方 30 天數據備份節點。光纖數據每小時更新以確保單一真相來源。",
          style: TextStyle(
            fontSize: 11.5,
            color: isClassicUI ? Colors.grey.shade500 : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: accentColor,
      ),
    );
  }

  Widget _buildRegionButton(BuildContext context, Color topIconColor, bool isEInk) {
    return Padding(
      padding: const EdgeInsets.only(left: 14.0, top: 12, bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Scaffold.of(context).openDrawer();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isEInk ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isEInk ? Colors.black26 : Colors.white30, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, color: topIconColor, size: 14),
              const SizedBox(width: 4),
              Text(
                "地區", 
                style: TextStyle(color: topIconColor, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
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
        icon: Icon(icon, color: color, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildOfflineArmorUI(WidgetRef ref, String stationName, bool isClassicUI, bool isEInk) {
    final Color textColor = isEInk ? Colors.black : (isClassicUI ? AppColors.classicText : AppColors.textPrimary);
    final Color iconColor = isEInk ? Colors.black : AppColors.bioGold;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.offline_bolt_rounded, size: 48, color: iconColor),
            const SizedBox(height: 16),
            Text(
              "[$stationName] 天文潮位接管中", 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEInk ? Colors.black : AppColors.bioGold,
                foregroundColor: isEInk ? Colors.white : AppColors.abyssBlack,
              ),
              onPressed: () => ref.refresh(tideViewDataProvider),
              child: const Text("重新整理", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCalendar(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(selectedDateProvider),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }
}

class AstroHindcastCard extends StatelessWidget {
  final DateTime selectedDate;
  final String stationName;
  final bool isClassic;

  const AstroHindcastCard({
    super.key,
    required this.selectedDate,
    required this.stationName,
    required this.isClassic,
  });

  @override
  Widget build(BuildContext context) {
    final solunar = SolunarUtil.calculate(selectedDate);
    final dateStr = DateFormat('yyyy/MM/dd').format(selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClassic ? Colors.white : AppColors.abyssCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isClassic ? Colors.grey.shade200 : AppColors.glassBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_toggle_off_rounded, color: AppColors.bioGold, size: 20),
              const SizedBox(width: 8),
              Text(
                "歷史天文潮位推演 [$stationName]",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "觀測日 $dateStr 歷史實測資料已歸檔，系統已為您啟動天文引力模型推演：當日適逢${solunar.tideCategory}（${solunar.lunarDateStr}），潮汐係數 ${solunar.tidalCoefficient}，魚群活躍指數 ${solunar.fishActivityScore}%。",
            style: TextStyle(
              fontSize: 12,
              color: isClassic ? Colors.grey.shade600 : AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class BiteRadarSection extends StatelessWidget {
  final TideStationData station;
  final DateTime selectedDate;
  final bool isClassic;

  const BiteRadarSection({
    super.key,
    required this.station,
    required this.selectedDate,
    required this.isClassic,
  });

  @override
  Widget build(BuildContext context) {
    final biteResult = BitePredictionEngine.predict(
      stationData: station,
      targetDate: selectedDate,
    );

    final Color primaryColor = isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan;
    final Color textColor = isClassic ? AppColors.classicText : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClassic ? Colors.white : AppColors.abyssCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isClassic ? Colors.grey.shade200 : AppColors.glassBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.radar_rounded, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "指標魚種索餌活性雷達",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  biteResult.biteLevel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "黃金起流窗口：${biteResult.primaryWindow}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.bioGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            biteResult.oceanTriggerSummary,
            style: TextStyle(
              fontSize: 11.5,
              color: isClassic ? Colors.grey.shade600 : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...biteResult.speciesIndices.map((sp) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sp.speciesName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "${sp.statusBadge} (${sp.biteProbability}%)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: sp.biteProbability >= 75 ? const Color(0xFF30D158) : primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
