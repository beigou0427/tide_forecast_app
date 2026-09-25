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

    final String chartDate = DateFormat('yyyy/MM/dd').format(observations.first.dateTime);
    final bool useWaveHeight = observations.any((o) => o.tideHeight == null) &&
                               observations.any((o) => o.waveHeight != null);

    // 🌟 死穴 3 修復：防崩潰安全峰值演算法
    int peakIndex = -1;
    double maxVal = double.negativeInfinity;
    for (int i = 0; i < observations.length; i++) {
      final val = useWaveHeight 
          ? (observations[i].waveHeight ?? double.negativeInfinity) 
          : (observations[i].tideHeight ?? double.negativeInfinity);
      if (val > maxVal) { 
        maxVal = val; 
        peakIndex = i; 
      }
    }

    // 🌟 嚴格座標守衛：預設為 null，只有在 100% 合法且 start < end 時才生成
    double? goldenStartX;
    double? goldenEndX;

    if (peakIndex != -1 && maxVal != double.negativeInfinity && observations.length >= 2) {
      final peakTime = observations[peakIndex].dateTime;
      final startTime = peakTime.subtract(const Duration(hours: 2));
      final endTime = peakTime.add(const Duration(hours: 1));

      int? startIdx;
      int? endIdx;

      for (int i = 0; i < observations.length; i++) {
        final t = observations[i].dateTime;
        if (t.isAfter(startTime) || t.isAtSameMomentAs(startTime)) {
          startIdx ??= i;
        }
        if (t.isBefore(endTime) || t.isAtSameMomentAs(endTime)) {
          endIdx = i;
        }
      }

      // 🚨 核心防線：強制確保 startIdx 必須嚴格小於 endIdx，杜絕 Rect left > right 逆轉崩潰！
      if (startIdx != null && endIdx != null && startIdx < endIdx) {
        goldenStartX = startIdx.toDouble();
        goldenEndX = endIdx.toDouble();
      }
    }

    return Column(
      children: [
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
              Row(
                children: [
                  if (goldenStartX != null && goldenEndX != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text("🔥 黃金咬度標示中", style: TextStyle(fontSize: 10, color: Color(0xFFD84315), fontWeight: FontWeight.bold)),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(chartDate, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                  ),
                ],
              )
            ],
          ),
        ),
        
        Container(
          height: 220,
          padding: const EdgeInsets.only(right: 20, top: 10),
          child: LineChart(
            LineChartData(
              // 🌟 100% 幾何安全守衛的黃金區間
              rangeAnnotations: RangeAnnotations(
                verticalRangeAnnotations: [
                  if (goldenStartX != null && goldenEndX != null && goldenStartX < goldenEndX)
                    VerticalRangeAnnotation(
                      x1: goldenStartX,
                      x2: goldenEndX,
                      color: Colors.amber.withValues(alpha: 0.15),
                    ),
                ],
              ),
              // 滿水波峰提示線
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  if (peakIndex >= 0 && peakIndex < observations.length && maxVal != double.negativeInfinity)
                    VerticalLine(
                      x: peakIndex.toDouble(),
                      color: Colors.amber.shade700,
                      strokeWidth: 1.5,
                      dashArray: [5, 5],
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(bottom: 5, left: 5),
                        labelResolver: (_) => "🔥 滿水點",
                        style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, fontSize: 10),
                      )
                    )
                ]
              ),
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
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: const Color(0xFF023E8A).withValues(alpha: 0.9),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final obs = observations[barSpot.x.toInt()];
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