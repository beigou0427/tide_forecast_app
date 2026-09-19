import 'package:flutter/material.dart';
import '../../data/tide_model.dart';

class SafetyAlert extends StatelessWidget {
  final Observation current;

  const SafetyAlert({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    // 安全評估邏輯：波高 > 1.5m 或 風速 > 8m/s 視為不佳
    bool isDanger = (current.waveHeight ?? 0) > 1.5 || (current.windSpeed ?? 0) > 8.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDanger ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDanger ? Colors.red.shade100 : Colors.green.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: isDanger ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isDanger 
                  ? "海況警告：風浪較大，不建議從事岸邊活動。" 
                  : "海況良好：目前環境適合戶外活動，請注意安全。",
              style: TextStyle(
                color: isDanger ? Colors.red.shade900 : Colors.green.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
