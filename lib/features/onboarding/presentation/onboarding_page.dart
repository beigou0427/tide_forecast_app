import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../premium/presentation/premium_page.dart';
import '../../../core/theme/app_theme.dart';

/// 🍏 Apple 首席設計工藝：深海啟航問卷與動態模型合成儀 (Deep Ocean Onboarding Odyssey)
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0; // 0, 1, 2: 問卷; 3: 模型合成中
  
  String? _selectedRegion;
  String? _selectedStyle;
  String? _selectedRisk;

  double _progress = 0.0;
  String _loadingText = "正在連接中央氣象署 85 測站光纖直連陣列...";
  Timer? _loadingTimer;

  final List<Map<String, dynamic>> _questions = [
    {
      "title": "您最常出沒的作業海域？",
      "subtitle": "老船長將優先預載該海域之高精度水文拓撲模型",
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
      "title": "您的主要作釣活動方式？",
      "subtitle": "系統將自適應計算最適合您下竿的海流與湧浪窗口",
      "key": "style",
      "options": [
        {"icon": "🐟", "label": "浮游磯釣 / 沉底遠投"},
        {"icon": "🎯", "label": "岸拋路亞 / 微鐵岸拋"},
        {"icon": "🦀", "label": "前打 / 落入 / 港口搞搞"},
        {"icon": "🚤", "label": "近海船釣 / 觀光海釣"},
        {"icon": "🤿", "label": "自由潛水 / 沿岸趕海採集"},
      ]
    },
    {
      "title": "出海時最在意的海象風險？",
      "subtitle": "老船長 AI 預警引擎將為此風險提高安全加權係數",
      "key": "risk",
      "options": [
        {"icon": "⚠️", "label": "瘋狗浪 / 突發深海長湧浪"},
        {"icon": "🌪️", "label": "陣風過強 (吹落或走水過快)"},
        {"icon": "⏳", "label": "滿乾潮水位急驟變化被困礁石"},
        {"icon": "🌡️", "label": "水溫驟降 (魚不開口白跑一趟)"},
      ]
    }
  ];

  void _onOptionSelected(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentStep == 0) _selectedRegion = value;
      if (_currentStep == 1) _selectedStyle = value;
      if (_currentStep == 2) _selectedRisk = value;
    });

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _startSynthesisLoading();
    }
  }

  void _startSynthesisLoading() async {
    setState(() {
      _currentStep = 3;
      _progress = 0.05;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pref_region', _selectedRegion ?? '');
    await prefs.setString('user_pref_style', _selectedStyle ?? '');
    await prefs.setString('user_pref_risk', _selectedRisk ?? '');
    await prefs.setBool('has_completed_onboarding', true);

    const totalDurationMs = 2100;
    const intervalMs = 50;
    int elapsed = 0;

    _loadingTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      elapsed += intervalMs;
      final ratio = (elapsed / totalDurationMs).clamp(0.0, 1.0);

      setState(() {
        _progress = ratio;
        if (ratio > 0.7) {
          _loadingText = "正在封裝專屬潮汐推論模型...";
        } else if (ratio > 0.35) {
          _loadingText = "正在初始化 Gemini 老船長推論模型...";
        }
      });

      if (elapsed >= totalDurationMs) {
        timer.cancel();
        HapticFeedback.mediumImpact();
        _goToPaywall();
      }
    });
  }

  void _goToPaywall() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const PremiumPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abyssBlack,
      body: SafeArea(
        child: _currentStep < 3 ? _buildQuestionStep() : _buildLoadingStep(),
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
          // 頂部膠囊進度光條
          Row(
            children: List.generate(3, (idx) {
              final isPassed = idx <= _currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3.5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isPassed ? AppColors.pelagicCyan : Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isPassed 
                        ? [BoxShadow(color: AppColors.pelagicCyan.withValues(alpha: 0.5), blurRadius: 6)] 
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 36),
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
              fontSize: 26, 
              fontWeight: FontWeight.w900, 
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            q["subtitle"],
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 32),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.glassBorder, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Text(opt["icon"]!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            opt["label"]!,
                            style: const TextStyle(
                              color: AppColors.textPrimary, 
                              fontSize: 14.5, 
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary, size: 14),
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

  Widget _buildLoadingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 3.5,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pelagicCyan),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.pelagicCyan.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.anchor_rounded, color: AppColors.bioGold, size: 48),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Text(
              "${(_progress * 100).toInt()} %",
              style: GoogleFonts.rubik(
                color: AppColors.textPrimary, 
                fontSize: 32, 
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _loadingText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "依據您的個人水文習慣自適應調整中",
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}