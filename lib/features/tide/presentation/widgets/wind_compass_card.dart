import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/tide_model.dart';
import '../../../../shared/widgets/custom_card.dart';

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

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0077B6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.explore_rounded, color: Color(0xFF0077B6), size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("360° 風浪作戰羅盤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("實時方位角與蒲福風力等級", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${windDir.toStringAsFixed(0)}° $windDirName",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF023E8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // 1. 360° 立體航海指北羅盤
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外刻度圈
                    Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2), width: 1.5),
                        color: const Color(0xFF021B33).withValues(alpha: 0.03),
                      ),
                    ),
                    const Positioned(top: 4, child: Text("N", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent))),
                    const Positioned(bottom: 4, child: Text("S", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                    const Positioned(left: 6, child: Text("W", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                    const Positioned(right: 6, child: Text("E", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                    
                    // 旋轉風向指針
                    Transform.rotate(
                      angle: (windDir * math.pi / 180),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.navigation_rounded, size: 36, color: windSpeed >= 8.0 ? Colors.redAccent : const Color(0xFF0077B6)),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber)),
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
                          "${windSpeed.toStringAsFixed(1)} m/s",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF021B33)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            beaufortInfo,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tacticTip,
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey, height: 1.35),
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
