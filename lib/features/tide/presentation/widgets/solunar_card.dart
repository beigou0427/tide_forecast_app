import 'package:flutter/material.dart';
import '../../../../core/utils/solunar_util.dart';
import '../../../../shared/widgets/custom_card.dart';

class SolunarCard extends StatelessWidget {
  final DateTime selectedDate;
  const SolunarCard({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final solunar = SolunarUtil.calculate(selectedDate);
    final bool isSpringTide = solunar.tideCategory == "大潮";

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(solunar.moonPhaseEmoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            solunar.moonPhaseName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(${solunar.lunarDateStr})",
                            style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text("日月引力與海流活躍指數", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSpringTide
                      ? Colors.redAccent.withValues(alpha: 0.1)
                      : const Color(0xFF0077B6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSpringTide
                        ? Colors.redAccent.withValues(alpha: 0.3)
                        : const Color(0xFF0077B6).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSpringTide ? Icons.local_fire_department_rounded : Icons.water_rounded,
                      color: isSpringTide ? Colors.redAccent : const Color(0xFF0077B6),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      solunar.tideCategory,
                      style: TextStyle(
                        color: isSpringTide ? Colors.redAccent : const Color(0xFF0077B6),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text("咬度指數", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: solunar.fishActivityScore / 100.0,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      solunar.fishActivityScore >= 85 ? Colors.orangeAccent : const Color(0xFF0077B6),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${solunar.fishActivityScore}%",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: solunar.fishActivityScore >= 85 ? Colors.orange.shade800 : const Color(0xFF0077B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0077B6).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_outlined, size: 15, color: Color(0xFF0077B6)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    solunar.biteWindowAdvice,
                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
