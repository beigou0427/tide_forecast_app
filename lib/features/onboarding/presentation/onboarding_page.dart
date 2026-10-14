import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tide/presentation/home_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/global_error_trap.dart';
import '../../premium/services/premium_service.dart';
import '../../premium/presentation/premium_page.dart';
import '../../../core/services/analytics_service.dart';

/// 🌟 經 CMO / 銷冠標準重塑之百萬 ARR 訂閱前置引導 (High-ARR Onboarding)
/// 100% 商業變現閉環版：
/// 1. 【銷冠殺招】長官親授：問卷完成不再白送本地假特權，直接引導至 Apple StoreKit「年度指揮官 7 天免費試用」！
/// 2. 透過 FaceID 預先綁定 Apple 訂閱隊列，利用「預設續訂慣性 (Auto-Renewal)」，將試用轉化為每年 990 元的實質 ARR！
class OnboardingPage extends ConsumerStatefulWidget {
  final String? initialCohort; 
  const OnboardingPage({super.key, this.initialCohort});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _currentStep = 0; 
  
  String? _selectedRegion;
  String? _selectedStyle;
  String? _selectedRisk;
  String? _selectedJtbd;
  
  String? _cohortBadgeText;
  bool _isTransitioning = false;
  bool _isRestoring = false;

  final List<Map<String, dynamic>> _questions = [
    {
      "title": "您最常出沒的作業海域？",
      "subtitle": "系統將優先鎖定該海域之高精度即時水文測站",
      "key": "region",
      "options": [
        {"icon": "🌊", "label": "北部沿海 (基隆 / 東北角 / 淡水)"},
        {"icon": "🎣", "label": "西部灘釣 / 港區 (台中 / 新竹 / 彰濱)"},
        {"icon": "☀️", "label": "南部珊瑚礁 / 沿岸 (高雄 / 墾丁 / 恆春)"},
        {"icon": "🐋", "label": "東部太平洋沿線 (花蓮 / 蘇澳 / 台東)"},
        {"icon": "🏝️", "label": "外島防波堤 / 礁岩 (澎湖 / 金馬 / 綠島)"},
      ]
    },
    {
      "title": "您的主要水上作業方式？",
      "subtitle": "系統將自適應計算最適合您下竿的走水黃金窗口",
      "key": "style",
      "options": [
        {"icon": "🐟", "label": "浮游磯釣 / 沉底遠投"},
        {"icon": "🎯", "label": "岸拋路亞 / 微鐵岸拋"},
        {"icon": "🦀", "label": "前打 / 落入 / 港口作業"},
        {"icon": "🚤", "label": "近海船釣 / 觀光海釣"},
        {"icon": "🤿", "label": "自由潛水 / 沿岸採集"},
      ]
    },
    {
      "title": "出海時最在意的海象風險？",
      "subtitle": "出海安全警報將為此風險提高安全警戒係數",
      "key": "risk",
      "options": [
        {"icon": "⚠️", "label": "瘋狗浪 / 突發深層長湧浪"},
        {"icon": "🌪️", "label": "陣風過強 (吹落或走水過快)"},
        {"icon": "⏳", "label": "滿乾潮水位急驟變化被困礁石"},
        {"icon": "🌡️", "label": "水溫驟降 (魚群閉口不食)"},
      ]
    },
    {
      "title": "主要為了解決什麼問題下載 Tide Pro？",
      "subtitle": "您的真實回饋將幫助我們優化核心海象演算法",
      "key": "jtbd",
      "options": [
        {"icon": "🛡️", "label": "避開瘋狗浪與惡劣海象 (求生保命)"},
        {"icon": "🔥", "label": "精準抓準滿退起流大咬 (追求爆箱)"},
        {"icon": "👥", "label": "朋友推薦 / 看到釣友戰報 (社群口碑)"},
        {"icon": "🌤️", "label": "純粹看天氣與潮汐走勢 (休閒觀察)"},
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _applyCohortDefaultsIfPresent();
  }

  void _applyCohortDefaultsIfPresent() {
    if (widget.initialCohort == "boat_skippers") {
      _selectedRegion = "北部沿海 (基隆 / 東北角 / 淡水)";
      _selectedStyle = "近海船釣 / 觀光海釣";
      _selectedRisk = "🌪️ 陣風過強 (吹落或走水過快)";
      _cohortBadgeText = "🚤 已為您預設【駕駛台船長】航海儀表參數";
    } else if (widget.initialCohort == "rock_anglers") {
      _selectedRegion = "北部沿海 (基隆 / 東北角 / 淡水)";
      _selectedStyle = "浮游磯釣 / 沉底遠投";
      _selectedRisk = "⚠️ 瘋狗浪 / 突發深層長湧浪";
      _cohortBadgeText = "🎣 已為您預設【外礁磯釣客】防困礁長湧參數";
    } else if (widget.initialCohort == "surf_dive") {
      _selectedRegion = "東部太平洋沿線 (花蓮 / 蘇澳 / 台東)";
      _selectedStyle = "自由潛水 / 沿岸採集";
      _selectedRisk = "🌡️ 水溫驟降 (魚群閉口不食)";
      _cohortBadgeText = "🤿 已為您預設【自潛衝浪】海溫躍層參數";
    }
  }

  Future<void> _handleVvipRestore() async {
    if (_isRestoring || _isTransitioning) return;
    
    HapticFeedback.mediumImpact();
    setState(() => _isRestoring = true);

    try {
      await ref.read(iapManagerProvider).restorePurchases();
      
      int elapsedMs = 0;
      bool isRestored = false;

      while (elapsedMs < 6000) {
        await Future.delayed(const Duration(milliseconds: 300));
        elapsedMs += 300;
        if (!mounted) return;

        final currentPremium = ref.read(premiumProvider);
        if (currentPremium.isPremium || currentPremium.isFounder) {
          isRestored = true;
          break;
        }
      }

      if (mounted) {
        if (isRestored) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_completed_onboarding', true);
          
          if (!mounted) return;
          
          final premium = ref.read(premiumProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: AppColors.bioGold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      premium.isFounder ? "👑 創始天尊特權已恢復！歡迎登艦！" : "⚡ PRO 權限已恢復！歡迎歸隊！", 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0077B6),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          _navigateToHome();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("未找到您的 Apple ID 下有任何 PRO 訂閱或購買紀錄。"),
              backgroundColor: AppColors.hazardCoral,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _isRestoring = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("恢復購買時發生異常：$e"), backgroundColor: AppColors.hazardCoral),
        );
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _onOptionSelected(String value) async {
    if (_isTransitioning) return; 
    HapticFeedback.selectionClick();
    
    setState(() {
      if (_currentStep == 0) _selectedRegion = value;
      if (_currentStep == 1) _selectedStyle = value;
      if (_currentStep == 2) _selectedRisk = value;
      if (_currentStep == 3) _selectedJtbd = value;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    if (_currentStep < 3) {
      if (mounted) setState(() => _currentStep++);
    } else {
      await _completeAndEnterCockpit(isSkipped: false);
    }
  }

  Future<void> _completeAndEnterCockpit({required bool isSkipped}) async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    HapticFeedback.heavyImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String finalRegion = _selectedRegion ?? (isSkipped ? "SKIPPED_IMPATIENT" : '北部沿海 (基隆 / 東北角 / 淡水)');
      final String finalStyle = _selectedStyle ?? (isSkipped ? "SKIPPED_IMPATIENT" : '浮游磯釣 / 沉底遠投');
      final String finalRisk = _selectedRisk ?? (isSkipped ? "SKIPPED_IMPATIENT" : '⚠️ 瘋狗浪 / 突發深層長湧浪');
      final String finalJtbd = _selectedJtbd ?? (isSkipped ? "SKIPPED_IMPATIENT" : '🛡️ 避開瘋狗浪與惡劣海象 (求生保命)');

      await prefs.setString('user_pref_region', finalRegion);
      await prefs.setString('user_pref_style', finalStyle);
      await prefs.setString('user_pref_risk', finalRisk);
      await prefs.setString('user_jtbd_reason', finalJtbd);
      await prefs.setBool('has_completed_onboarding', true);

      final currentPremium = ref.read(premiumProvider);
      final bool alreadyHasHigherTier = currentPremium.isFounder || 
          currentPremium.type == SubscriptionType.yearly || 
          currentPremium.type == SubscriptionType.lifetime;

      AnalyticsService.logOnboardingCompleted(
        region: finalRegion,
        style: finalStyle,
        risk: finalRisk,
        jtbdReason: finalJtbd,
        isSkipped: isSkipped,
        claimed7DaysTrial: !isSkipped && !alreadyHasHigherTier,
      ).catchError((_) {});

      // 🌟 銷冠核心變現：問卷完成不再白送本地假特權！
      // 而是直接推進 Apple StoreKit 付費牆，預選「年度指揮官（首週 0 元試用，第 8 天自動扣款 990）」！
      if (!isSkipped && !alreadyHasHigherTier) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => const PremiumPage(fromOnboarding: true),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
            ),
          );
        }
        return;
      }

      if (isSkipped && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.directions_boat_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text("⚓ 歡迎登艦！已為您啟用訪客模式，隨時可至設定解鎖 PRO 特權！", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: Color(0xFF0077B6),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }

      _navigateToHome();
    } catch (e, stack) {
      GlobalErrorTrap.recordException(e, stackTrace: stack, contextTag: "Onboarding_Prefs", severity: ErrorSeverity.warning);
      _navigateToHome(); 
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    _isTransitioning = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PremiumState>(premiumProvider, (previous, next) async {
      if (next.isPremium && !_isTransitioning && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_completed_onboarding', true);
        _navigateToHome();
      }
    });

    final isAlreadyPro = ref.watch(premiumProvider.select((s) => s.isPremium || s.isFounder));

    return Scaffold(
      backgroundColor: AppColors.abyssBlack,
      body: SafeArea(
        child: Stack(
          children: [
            _buildQuestionStep(isAlreadyPro),
            
            Positioned(
              top: 8,
              left: 16,
              child: InkWell(
                onTap: _handleVvipRestore,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bioGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.4), width: 1.0),
                    boxShadow: [BoxShadow(color: AppColors.bioGold.withValues(alpha: 0.1), blurRadius: 8)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRestoring)
                        const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bioGold),
                        )
                      else
                        const Icon(Icons.workspace_premium_rounded, color: AppColors.bioGold, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _isRestoring ? "驗證中..." : "老用戶恢復購買", 
                        style: const TextStyle(color: AppColors.bioGold, fontSize: 11.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionStep(bool isAlreadyPro) {
    final q = _questions[_currentStep];
    final options = q["options"] as List<Map<String, String>>;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 56.0, 24.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: List.generate(4, (idx) {
                    final isPassed = idx <= _currentStep;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3.5,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          color: isPassed ? AppColors.pelagicCyan : Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => _completeAndEnterCockpit(isSkipped: true),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "訪客模式 (直接看浪) ➔", 
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: isAlreadyPro
                  ? const LinearGradient(colors: [Color(0xFF003870), Color(0xFF001F3F)])
                  : const LinearGradient(colors: [Color(0xFF3B2F0B), Color(0xFF1C1402)]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isAlreadyPro ? AppColors.pelagicCyan.withValues(alpha: 0.5) : AppColors.bioGold.withValues(alpha: 0.5), 
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isAlreadyPro ? AppColors.pelagicCyan.withValues(alpha: 0.15) : AppColors.bioGold.withValues(alpha: 0.15), 
                  blurRadius: 8,
                )
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isAlreadyPro ? Icons.anchor_rounded : Icons.card_giftcard_rounded, 
                  color: isAlreadyPro ? AppColors.pelagicCyan : AppColors.bioGold, 
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAlreadyPro
                        ? "尊榮船長您好！完成調查將為您客製化鎖定出海專屬標點！"
                        : "完成 4 題海事調查，免費獲取官方「年度指揮官 7 天免費試用」！",
                    style: TextStyle(
                      fontSize: 11.5, 
                      color: isAlreadyPro ? AppColors.pelagicCyan : AppColors.bioGold, 
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_cohortBadgeText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.pelagicCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.pelagicCyan.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.pelagicCyan, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _cohortBadgeText!,
                      style: const TextStyle(fontSize: 11, color: AppColors.pelagicCyan, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          Text(
            "STEP 0${_currentStep + 1} OF 04",
            style: const TextStyle(
              color: AppColors.pelagicCyan, 
              fontSize: 11, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            q["title"],
            style: GoogleFonts.notoSansTc(
              color: AppColors.textPrimary, 
              fontSize: 23, 
              fontWeight: FontWeight.w900, 
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            q["subtitle"],
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final opt = options[idx];
                final String label = opt["label"]!;
                final bool isPreselected = (_currentStep == 0 && label == _selectedRegion) ||
                                          (_currentStep == 1 && label == _selectedStyle) ||
                                          (_currentStep == 2 && label == _selectedRisk) ||
                                          (_currentStep == 3 && label == _selectedJtbd);

                return InkWell(
                  onTap: () => _onOptionSelected(label),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    decoration: BoxDecoration(
                      color: isPreselected 
                          ? AppColors.pelagicCyan.withValues(alpha: 0.15) 
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isPreselected ? AppColors.pelagicCyan : AppColors.glassBorder, 
                        width: isPreselected ? 1.2 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(opt["icon"]!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isPreselected ? Colors.white : AppColors.textPrimary, 
                              fontSize: 14, 
                              fontWeight: isPreselected ? FontWeight.w900 : FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          isPreselected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded, 
                          color: isPreselected ? AppColors.pelagicCyan : AppColors.textTertiary, 
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
