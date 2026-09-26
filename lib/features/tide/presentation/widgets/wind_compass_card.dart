import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🍏 Apple 首席設計工藝：360° 航海作戰羅盤 (零溢出安全版)
class WindCompassCard extends StatelessWidget {
  final Observation current;

  const WindCompassCard({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final double windDir = current.windDirection ?? 0.0;
    final double windSpeed = current.windSpeed ?? 0.0;
    final String windDirName = _getWindDirectionName(windDir);
    final String beaufortInfo = _getBeaufortScale(windSpeed);
    final String tacticTip = _getTacticAdvice(windSpeed, windDir);
    final Color windColor = _getWindSpeedColor(windSpeed);

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 頂部儀表標題與方位角膠囊 (🌟 注入 Expanded 彈性保護)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.pelagicCyan.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.explore_rounded, color: AppColors.pelagicCyan, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "360° 航海作戰羅盤",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "即時方位角與蒲福風級階梯",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pelagicCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.pelagicCyan.withValues(alpha: 0.3), width: 0.5),
                ),
                child: Text(
                  "${windDir.toStringAsFixed(0)}° $windDirName",
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pelagicCyan,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. 羅盤本體與風級戰術排印
          Row(
            children: [
              // 瑞士精密航海羅盤錶盤
              SizedBox(
                width: 124,
                height: 124,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.glassBorder, width: 0.5),
                        gradient: const RadialGradient(
                          colors: [Color(0xFF0F1B2B), Color(0xFF060B12)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
                      ),
                    ),
                    const Positioned(
                      top: 6,
                      child: Text("N", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.hazardCoral)),
                    ),
                    const Positioned(
                      bottom: 6,
                      child: Text("S", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                    ),
                    const Positioned(
                      left: 7,
                      child: Text("W", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                    ),
                    const Positioned(
                      right: 7,
                      child: Text("E", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                    ),
                    
                    Transform.rotate(
                      angle: (windDir * math.pi / 180),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.navigation_rounded, 
                            size: 36, 
                            color: windColor,
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bioGold,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.bioGold.withValues(alpha: 0.5),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              // 🌟 3. 風速數值區：採用 Wrap 自適應彈性佈局，徹底終結小螢幕強風溢出！
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              windSpeed.toStringAsFixed(1),
                              style: GoogleFonts.rubik(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -1,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              "m/s",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: windColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: windColor.withValues(alpha: 0.3), width: 0.5),
                          ),
                          child: Text(
                            beaufortInfo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: windColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder, width: 0.5),
                      ),
                      child: Text(
                        tacticTip,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _getWindSpeedColor(double speed) {
    if (speed >= 10.8) return AppColors.hazardCoral;
    if (speed >= 6.0) return const Color(0xFFFF9500);
    return AppColors.pelagicCyan;
  }

  static String _getWindDirectionName(double deg) {
    const directions = [
      "北風", "北北東", "東北風", "東北東",
      "東風", "東南東", "東南風", "南南東",
      "南風", "南南西", "西南風", "西南西",
      "西風", "西北西", "西北風", "北北西"
    ];
    final double normalized = (deg % 360 + 360) % 360;
    final int idx = ((normalized + 11.25) / 22.5).floor() % 16;
    return directions[idx];
  }

  static String _getBeaufortScale(double speed) {
    if (speed < 0.3) return "0 級無風";
    if (speed < 1.6) return "1 級軟風";
    if (speed < 3.4) return "2 級輕風";
    if (speed < 5.5) return "3 級微風";
    if (speed < 8.0) return "4 級和風";
    if (speed < 10.8) return "5 級清勁風";
    if (speed < 13.9) return "6 級強風";
    if (speed < 17.2) return "7 級疾風";
    return "8 級以上大風";
  }

  static String _getTacticAdvice(double speed, double dir) {
    if (speed >= 10.8) {
      return "⚠️ 陣風強烈，釣竿受風面積大易走線，防波堤外側請嚴防強側風吹落！";
    } else if (speed >= 6.0) {
      return "🚩 具備推浪水流，建議尋找背風側岬角或深場作釣，換用較重配鉛維持泳層。";
    } else {
      return "🌊 風力柔和，微風帶起水面波紋有利降減魚群戒心，輕量路亞與阿波操控感最佳。";
    }
  }
}