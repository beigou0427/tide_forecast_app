import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tide_model.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🌟 頂級 CMO 階級傲慢引擎 (The Status Flex) - 360° 風浪作戰羅盤
/// 100% E-Ink 航海家專屬適配版：
/// 1. 【階級銘牌】加入 "COMMAND DECK" 標籤，篩選並討好高淨值船長受眾。
/// 2. 【硬核軍工】捨棄漸層，改用極致對比的黑白實線，強調「這是一個強光下保命的儀器」。
class WindCompassCard extends ConsumerWidget {
  final Observation current;

  const WindCompassCard({super.key, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;

    final double windDir = current.windDirection ?? 0.0;
    final double windSpeed = current.windSpeed ?? 0.0;
    final String windDirName = _getWindDirectionName(windDir);
    final String beaufortInfo = _getBeaufortScale(windSpeed);
    final String tacticTip = _getTacticAdvice(windSpeed, windDir);

    // 🌟 語意化動態色彩矩陣 (為 E-Ink 賦予極致的軍工感)
    final Color titleColor = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color subtitleColor = isEInk 
        ? Colors.black87 
        : (isClassic ? Colors.grey.shade600 : AppColors.textSecondary);
    final Color windSpeedColor = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color compassDialBg = isEInk 
        ? Colors.white 
        : (isClassic ? const Color(0xFF0077B6).withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.04));
    final Color compassDialBorder = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.grey.shade300 : AppColors.glassBorder);
    final Color compassDirectionColor = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary);
    final Color tacticsBoxBg = isEInk 
        ? Colors.black.withValues(alpha: 0.05) 
        : (isClassic ? Colors.blueGrey.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.04));
    final Color tacticsBoxBorder = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder);
    final Color tacticTextColor = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.blueGrey.shade900 : AppColors.textPrimary);
    final Color beaufortBadgeBg = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.teal.withValues(alpha: 0.12) : Colors.teal.withValues(alpha: 0.18));
    final Color beaufortBadgeText = isEInk 
        ? Colors.white 
        : (isClassic ? Colors.teal.shade800 : Colors.tealAccent);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 CMO 階級打擊點：專屬 COMMAND DECK 銘牌
          if (isEInk) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_boat_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 6),
                  Text(
                    "COMMAND DECK • 駕駛台專用",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isEInk ? Colors.black : (isClassic ? const Color(0xFF0077B6).withValues(alpha: 0.12) : AppColors.pelagicCyan.withValues(alpha: 0.12)),
                        shape: isEInk ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius: isEInk ? BorderRadius.circular(6) : null,
                      ),
                      child: Icon(
                        Icons.explore_rounded, 
                        color: isEInk ? Colors.white : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan), 
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("360° 風浪作戰羅盤", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: titleColor, letterSpacing: -0.2)),
                          const SizedBox(height: 2),
                          Text(
                            isEInk ? "烈日抗反光引擎運作中" : "實時方位角與蒲福風力等級", 
                            style: TextStyle(fontSize: 10.5, color: isEInk ? Colors.black : subtitleColor, fontWeight: isEInk ? FontWeight.bold : FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isEInk ? Colors.white : (isClassic ? const Color(0xFF0077B6).withValues(alpha: 0.12) : AppColors.pelagicCyan.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEInk ? Colors.black : (isClassic ? const Color(0xFF0077B6).withValues(alpha: 0.3) : AppColors.pelagicCyan.withValues(alpha: 0.3)),
                    width: isEInk ? 2.0 : 0.5,
                  ),
                ),
                child: Text(
                  "${windDir.toStringAsFixed(0)}° $windDirName",
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w900, 
                    color: isEInk ? Colors.black : (isClassic ? const Color(0xFF023E8A) : AppColors.pelagicCyan),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              // 1. 360° 立體航海指北羅盤 (E-Ink 高對比防護)
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: compassDialBorder, width: isEInk ? 2.5 : 1.0),
                        color: compassDialBg,
                      ),
                    ),
                    if (isEInk) ...[
                      // 內部準星輔助線 (軍工感)
                      Container(width: 1, height: 116, color: Colors.black12),
                      Container(width: 116, height: 1, color: Colors.black12),
                    ],
                    Positioned(top: 4, child: Text("N", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isEInk ? Colors.black : Colors.redAccent))),
                    Positioned(bottom: 4, child: Text("S", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: compassDirectionColor))),
                    Positioned(left: 6, child: Text("W", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: compassDirectionColor))),
                    Positioned(right: 6, child: Text("E", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: compassDirectionColor))),
                    
                    // 旋轉風向指針
                    Transform.rotate(
                      angle: (windDir * math.pi / 180),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.navigation_rounded, 
                            size: 38, 
                            color: windSpeed >= 8.0 
                                ? AppColors.hazardCoral 
                                : (isEInk ? Colors.black : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan)),
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                    Container(
                      width: 10, 
                      height: 10, 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        color: isEInk ? Colors.white : AppColors.bioGold,
                        border: isEInk ? Border.all(color: Colors.black, width: 2.5) : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              // 2. 風級與戰術評估
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "${windSpeed.toStringAsFixed(1)}",
                          style: TextStyle(
                            fontSize: 26, 
                            fontWeight: FontWeight.w900, 
                            color: windSpeedColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text("m/s", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subtitleColor)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: beaufortBadgeBg,
                            borderRadius: BorderRadius.circular(6),
                            border: isEInk ? null : Border.all(color: beaufortBadgeText.withValues(alpha: 0.3), width: 0.5),
                          ),
                          child: Text(
                            beaufortInfo,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: beaufortBadgeText, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tacticsBoxBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tacticsBoxBorder, width: isEInk ? 2.0 : 0.5),
                      ),
                      child: Text(
                        tacticTip,
                        style: TextStyle(
                          fontSize: 11.5, 
                          color: tacticTextColor, 
                          height: 1.45, 
                          fontWeight: isEInk ? FontWeight.w800 : FontWeight.w500,
                        ),
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

  static String _getWindDirectionName(double deg) {
    const directions = [
      "北風", "北北東", "東北風", "東北東",
      "東風", "東南東", "東南風", "南南東",
      "南風", "南南西", "西南風", "西南西",
      "西風", "西北西", "西北風", "北北西"
    ];
    final int idx = ((deg + 11.25) % 360 / 22.5).floor();
    return directions[idx % 16];
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
