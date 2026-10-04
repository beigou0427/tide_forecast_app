import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tide/presentation/home_page.dart';
import '../../../core/theme/app_theme.dart';

/// 🌟 經海事嚴謹標準重塑之極速前置引導 (Zero Friction Onboarding)
/// 徹底拔除一切虛假偽加載等待，問卷完成即刻 0 延遲直達海象指揮中心
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0; // 0, 1, 2: 偏好配置
  
  String? _selectedRegion;
  String? _selectedStyle;
  String? _selectedRisk;

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

  Future<void> _onOptionSelected(String value) async {
    HapticFeedback.selectionClick();
    if (_currentStep == 0) _selectedRegion = value;
    if (_currentStep == 1) _selectedStyle = value;
    if (_currentStep == 2) _selectedRisk = value;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // 🌟 徹底拔除偽進度條：完成後 0 延遲立即直達駕駛台
      await _completeAndEnterCockpit();
    }
  }

  Future<void> _completeAndEnterCockpit() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pref_region', _selectedRegion ?? '');
    await prefs.setString('user_pref_style', _selectedStyle ?? '');
    await prefs.setString('user_pref_risk', _selectedRisk ?? '');
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
                  "先看海況 ➔", 
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
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
              fontSize: 24, 
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
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final opt = options[idx];
                return InkWell(
                  onTap: () => _onOptionSelected(opt["label"]!),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.glassBorder, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Text(opt["icon"]!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            opt["label"]!,
                            style: const TextStyle(
                              color: AppColors.textPrimary, 
                              fontSize: 14, 
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary, size: 13),
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