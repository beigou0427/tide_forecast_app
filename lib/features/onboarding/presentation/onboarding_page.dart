import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../premium/presentation/premium_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0; // 0, 1, 2: 問卷; 3: 假加載
  
  String? _selectedRegion;
  String? _selectedStyle;
  String? _selectedRisk;

  // 假進度條進度與輪播文字
  double _progress = 0.0;
  String _loadingText = "正在連接中央氣象署 86 測站感測陣列...";
  Timer? _loadingTimer;

  final List<Map<String, dynamic>> _questions = [
    {
      "title": "您最常出沒的作業海域？",
      "subtitle": "老船長將優先為您預載該海域之潮汐水文模型",
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
      "title": "您的主要作釣方式？",
      "subtitle": "系統將自適應計算最適合您作釣的海流與湧浪窗口",
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
      "subtitle": "老船長 AI 預警引擎將為此風險提高安全加權等級",
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
    setState(() {
      if (_currentStep == 0) _selectedRegion = value;
      if (_currentStep == 1) _selectedStyle = value;
      if (_currentStep == 2) _selectedRisk = value;
    });

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _startFakeLoading();
    }
  }

  void _startFakeLoading() async {
    setState(() {
      _currentStep = 3;
      _progress = 0.05;
    });

    // 儲存問卷偏好以利日後 AI 推理加權
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pref_region', _selectedRegion ?? '');
    await prefs.setString('user_pref_style', _selectedStyle ?? '');
    await prefs.setString('user_pref_risk', _selectedRisk ?? '');
    await prefs.setBool('has_completed_onboarding', true);

    const totalDurationMs = 2000;
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
        _goToPaywall();
      }
    });
  }

  void _goToPaywall() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const PremiumPage(),
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
      backgroundColor: const Color(0xFF021B33),
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
          // 頂部步數指示
          Row(
            children: List.generate(3, (idx) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: idx <= _currentStep ? const Color(0xFF00B4D8) : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Text(
            "STEP 0${_currentStep + 1} / 03",
            style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            q["title"],
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            q["subtitle"],
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final opt = options[idx];
                return InkWell(
                  onTap: () => _onOptionSelected(opt["label"]!),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Text(opt["icon"]!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            opt["label"]!,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.4), size: 20),
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
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B4D8)),
                  ),
                ),
                const Icon(Icons.anchor_rounded, color: Colors.amberAccent, size: 52),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              "${(_progress * 100).toInt()} %",
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Text(
              _loadingText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              "依據您的釣法習慣自適應調整中",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

