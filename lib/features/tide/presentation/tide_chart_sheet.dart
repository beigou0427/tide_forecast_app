import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/tide_model.dart';

class TideChartSheet extends StatelessWidget {
  final List<Observation> observations;

  const TideChartSheet({
    super.key,
    required this.observations,
  });

  @override
  Widget build(BuildContext context) {
    if (observations.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("目前無圖表觀測數據", style: TextStyle(color: Colors.grey))),
      );
    }

    // 取得該批數據的日期 (取第一筆觀測資料的日期)
    final String chartDate = DateFormat('yyyy/MM/dd').format(observations.first.dateTime);

    // 判斷數據源：優先使用潮位高度，若無則使用波浪高度
    final bool useWaveHeight = observations.any((o) => o.tideHeight == null) &&
                               observations.any((o) => o.waveHeight != null);

    return Column(
      children: [
        // --- 圖表標題與日期 ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 3, color: const Color(0xFF0077B6)),
                  const SizedBox(width: 6),
                  Text(
                    useWaveHeight ? "波高趨勢 (m)" : "潮位趨勢 (m)",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                ],
              ),
              // 🌟 新增：顯示圖表日期
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  chartDate,
                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        
        // --- 核心圖表區 ---
        Container(
          height: 220,
          padding: const EdgeInsets.only(right: 20, top: 10),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                
                // 下方 X 軸：顯示時間
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 4, 
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index >= 0 && index < observations.length) {
                        final String timeStr = DateFormat('HH:mm').format(observations[index].dateTime);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                
                // 左側 Y 軸：顯示高度
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        "${value.toStringAsFixed(1)}m",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    },
                    reservedSize: 35,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              
              lineBarsData: [
                LineChartBarData(
                  spots: observations.asMap().entries.map((e) {
                    final double yValue = useWaveHeight 
                        ? (e.value.waveHeight ?? 0.0) 
                        : (e.value.tideHeight ?? 0.0);
                    return FlSpot(e.key.toDouble(), yValue);
                  }).toList(),
                  isCurved: true, 
                  curveSmoothness: 0.35, 
                  color: const Color(0xFF0077B6),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false), 
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0077B6).withValues(alpha: 0.3),
                        const Color(0xFF0077B6).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              
              // 🌟 修改：點擊圖表時顯示詳細日期與時間
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: const Color(0xFF023E8A).withValues(alpha: 0.9),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final obs = observations[barSpot.x.toInt()];
                      // Tooltip 顯示範例：03/12 20:00
                      final String fullTime = DateFormat('MM/dd HH:mm').format(obs.dateTime);
                      return LineTooltipItem(
                        "$fullTime\n",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: "${barSpot.y.toStringAsFixed(2)} m",
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
