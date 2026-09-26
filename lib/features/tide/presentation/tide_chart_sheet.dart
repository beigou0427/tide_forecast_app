import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/tide_model.dart';
import '../../../../core/theme/app_theme.dart';

/// 🍏 Apple 首席設計工藝：航海調和擬合潮汐走勢圖 (Harmonic Oceanic Tide Surface)
class TideChartSheet extends StatelessWidget {
  final List<Observation> observations;
  final List<TideForecast>? futureForecasts; // 🌟 支援未來 30 天預報點
  final DateTime? targetDate;                 // 🌟 目標日期

  const TideChartSheet({
    super.key,
    required this.observations,
    this.futureForecasts,
    this.targetDate,
  });

  @override
  Widget build(BuildContext context) {
    // 🌟 炸彈 2 拆彈核心：若無實測資料 (未來模式)，自動啟動航海餘弦調和擬合引擎
    final bool isFutureMode = observations.isEmpty && 
                             futureForecasts != null && 
                             futureForecasts!.isNotEmpty;

    final List<Observation> effectiveObs = isFutureMode
        ? _synthesizeFutureCurve(futureForecasts!, targetDate ?? DateTime.now())
        : observations;

    if (effectiveObs.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("目前無圖表觀測或預報數據", style: TextStyle(color: AppColors.textTertiary))),
      );
    }

    final String chartDate = DateFormat('yyyy/MM/dd').format(effectiveObs.first.dateTime);
    final bool useWaveHeight = !isFutureMode && 
                               effectiveObs.any((o) => o.tideHeight == null) &&
                               effectiveObs.any((o) => o.waveHeight != null);

    // 峰值與黃金咬度計算
    int peakIndex = -1;
    double maxVal = double.negativeInfinity;
    for (int i = 0; i < effectiveObs.length; i++) {
      final val = useWaveHeight 
          ? (effectiveObs[i].waveHeight ?? double.negativeInfinity) 
          : (effectiveObs[i].tideHeight ?? double.negativeInfinity);
      if (val > maxVal) { 
        maxVal = val; 
        peakIndex = i; 
      }
    }

    double? goldenStartX;
    double? goldenEndX;

    if (peakIndex != -1 && maxVal != double.negativeInfinity && effectiveObs.length >= 2) {
      final peakTime = effectiveObs[peakIndex].dateTime;
      final startTime = peakTime.subtract(const Duration(hours: 2));
      final endTime = peakTime.add(const Duration(hours: 1));

      int? startIdx;
      int? endIdx;

      for (int i = 0; i < effectiveObs.length; i++) {
        final t = effectiveObs[i].dateTime;
        if (t.isAfter(startTime) || t.isAtSameMomentAs(startTime)) {
          startIdx ??= i;
        }
        if (t.isBefore(endTime) || t.isAtSameMomentAs(endTime)) {
          endIdx = i;
        }
      }

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
                  Container(
                    width: 12, 
                    height: 3, 
                    color: isFutureMode ? AppColors.bioGold : (useWaveHeight ? Colors.indigoAccent : AppColors.pelagicCyan),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFutureMode 
                        ? "30 天未來潮位推算 (m)" 
                        : (useWaveHeight ? "實測波高趨勢 (m)" : "實測潮位趨勢 (m)"),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  if (goldenStartX != null && goldenEndX != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.bioGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text("🔥 黃金咬度標示中", style: TextStyle(fontSize: 10, color: AppColors.bioGold, fontWeight: FontWeight.bold)),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(4)),
                    child: Text(chartDate, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
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
              rangeAnnotations: RangeAnnotations(
                verticalRangeAnnotations: [
                  if (goldenStartX != null && goldenEndX != null && goldenStartX < goldenEndX)
                    VerticalRangeAnnotation(
                      x1: goldenStartX,
                      x2: goldenEndX,
                      color: AppColors.bioGold.withValues(alpha: 0.15),
                    ),
                ],
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  if (peakIndex >= 0 && peakIndex < effectiveObs.length && maxVal != double.negativeInfinity)
                    VerticalLine(
                      x: peakIndex.toDouble(),
                      color: AppColors.bioGold,
                      strokeWidth: 1.5,
                      dashArray: [5, 5],
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(bottom: 5, left: 5),
                        labelResolver: (_) => isFutureMode ? "預測滿潮" : "實測滿水",
                        style: const TextStyle(color: AppColors.bioGold, fontWeight: FontWeight.bold, fontSize: 10),
                      )
                    )
                ]
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.glassBorder,
                  strokeWidth: 0.5,
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
                      if (index >= 0 && index < effectiveObs.length) {
                        final String timeStr = DateFormat('HH:mm').format(effectiveObs[index].dateTime);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(timeStr, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
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
                        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                      );
                    },
                    reservedSize: 35,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: effectiveObs.asMap().entries.map((e) {
                    final double yValue = useWaveHeight 
                        ? (e.value.waveHeight ?? 0.0) 
                        : (e.value.tideHeight ?? 0.0);
                    return FlSpot(e.key.toDouble(), yValue);
                  }).toList(),
                  isCurved: true, 
                  curveSmoothness: 0.35, 
                  color: isFutureMode ? AppColors.bioGold : AppColors.pelagicCyan,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false), 
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isFutureMode ? AppColors.bioGold : AppColors.pelagicCyan).withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: AppColors.abyssCard,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final obs = effectiveObs[barSpot.x.toInt()];
                      final String fullTime = DateFormat('MM/dd HH:mm').format(obs.dateTime);
                      return LineTooltipItem(
                        "$fullTime\n",
                        const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: "${barSpot.y.toStringAsFixed(2)} m",
                            style: TextStyle(
                              color: isFutureMode ? AppColors.bioGold : AppColors.pelagicCyan, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 14,
                            ),
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

  // 🌟 航海經典餘弦調和潮位擬合演算法 (Cosine Harmonic Tidal Synthesis)
  List<Observation> _synthesizeFutureCurve(List<TideForecast> forecasts, DateTime targetDay) {
    if (forecasts.isEmpty) return [];

    final sorted = List<TideForecast>.from(forecasts)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final List<Observation> curve = [];
    final DateTime dayStart = DateTime(targetDay.year, targetDay.month, targetDay.day);

    for (int hour = 0; hour < 24; hour++) {
      final currentT = dayStart.add(Duration(hours: hour));

      TideForecast? prev;
      TideForecast? next;

      for (int i = 0; i < sorted.length - 1; i++) {
        if ((sorted[i].dateTime.isBefore(currentT) || sorted[i].dateTime.isAtSameMomentAs(currentT)) &&
            sorted[i + 1].dateTime.isAfter(currentT)) {
          prev = sorted[i];
          next = sorted[i + 1];
          break;
        }
      }

      double heightInMeters;

      if (prev != null && next != null) {
        final totalMs = next.dateTime.difference(prev.dateTime).inMilliseconds;
        final elapsedMs = currentT.difference(prev.dateTime).inMilliseconds;
        final double ratio = totalMs > 0 ? (elapsedMs / totalMs).clamp(0.0, 1.0) : 0.0;

        final double h1 = (double.tryParse(prev.tideHeight) ?? 100.0) / 100.0;
        final double h2 = (double.tryParse(next.tideHeight) ?? 100.0) / 100.0;

        // 餘弦平滑諧波擬合公式
        heightInMeters = (h1 + h2) / 2.0 + ((h1 - h2) / 2.0) * math.cos(math.pi * ratio);
      } else if (sorted.isNotEmpty) {
        final closest = sorted.reduce((a, b) => 
          (a.dateTime.difference(currentT).abs() < b.dateTime.difference(currentT).abs()) ? a : b
        );
        heightInMeters = (double.tryParse(closest.tideHeight) ?? 100.0) / 100.0;
      } else {
        heightInMeters = 1.0;
      }

      curve.add(Observation(
        dateTime: currentT,
        tideHeight: double.parse(heightInMeters.toStringAsFixed(2)),
        tideLevel: "預測潮位",
      ));
    }
    return curve;
  }
}