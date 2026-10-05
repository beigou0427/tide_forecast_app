import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tide/presentation/home_page.dart';
import '../../../core/theme/app_theme.dart';

/// 🌟 經海事嚴謹標準重塑之極速前置引導 (Zero Friction Onboarding)
/// 融合 Johannes von Cramon CPP 專屬受眾深度接軌與 Sean Ellis「0 延遲直達駕駛台」架構
class OnboardingPage extends StatefulWidget {
  final String? initialCohort; // 'rock_anglers' | 'boat_skippers' | 'surf_dive'
  const OnboardingPage({super.key, this.initialCohort});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0; // 0, 1, 2: 偏好配置
  
  String? _selectedRegion;
  String? _selectedStyle;
  String? _selectedRisk;
  String? _cohortBadgeText;

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
    }
  ];

  @override
  void initState() {
    super.initState();
    _applyCohortDefaultsIfPresent();
  }

  // 🌟 Johannes von Cramon: 依據 CPP 深度連結自動預載專屬受眾參數
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

  Future<void> _onOptionSelected(String value) async {
    HapticFeedback.selectionClick();
    if (_currentStep == 0) _selectedRegion = value;
    if (_currentStep == 1) _selectedStyle = value;
    if (_currentStep == 2) _selectedRisk = value;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      await _completeAndEnterCockpit();
    }
  }

  Future<void> _completeAndEnterCockpit() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pref_region', _selectedRegion ?? '北部沿海 (基隆 / 東北角 / 淡水)');
    await prefs.setString('user_pref_style', _selectedStyle ?? '浮游磯釣 / 沉底遠投');
    await prefs.setString('user_pref_risk', _selectedRisk ?? '⚠️ 瘋狗浪 / 突發深層長湧浪');
    await prefs.setBool('has_completed_onboarding', true);
    await prefs.setBool('has_agreed_maritime_safety_v2', true);
    _navigateToHome();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abyssBlack,
      body: SafeArea(
        child: _buildQuestionStep(),
      ),
    );
  }

  Widget _buildQuestionStep() {
    final q = _questions[_currentStep];
    final options = q["options"] as List<Map<String, String>>;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頂部進度條與快速跳過按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: List.generate(3, (idx) {
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
                onPressed: _completeAndEnterCockpit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "直達駕駛台 ➔", 
                  style: TextStyle(color: AppColors.pelagicCyan, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // CPP 受眾預設標記橫幅
          if (_cohortBadgeText != null) ...[
            const SizedBox(height: 16),
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

          const SizedBox(height: 24),
          Text(
            "STEP 0${_currentStep + 1} OF 03",
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
                                          (_currentStep == 2 && label == _selectedRisk);

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