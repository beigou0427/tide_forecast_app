import 'dart:math' as math;
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/tide_model.dart';
import '../../../../core/theme/app_theme.dart';

/// Mike Matas 哲學重塑：活體流體潮汐光學圖表 (Living Oceanic Tidal Surface)
class TideChartSheet extends StatelessWidget {
  final List<Observation> observations;
  final List<TideForecast>? futureForecasts;
  final DateTime? targetDate;

  const TideChartSheet({
    super.key,
    required this.observations,
    this.futureForecasts,
    this.targetDate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final bool isFutureMode = observations.isEmpty && 
                             futureForecasts != null && 
                             futureForecasts!.isNotEmpty;

    final List<Observation> effectiveObs = isFutureMode
        ? _synthesizeFutureCurve(futureForecasts!, targetDate ?? DateTime.now())
        : observations;

    if (effectiveObs.length < 2) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "目前無足夠圖表觀測或預報數據", 
            style: TextStyle(color: isLight ? Colors.grey.shade500 : AppColors.textTertiary),
          ),
        ),
      );
    }

    final String chartDate = DateFormat('yyyy/MM/dd').format(effectiveObs.first.dateTime);
    final bool useWaveHeight = !isFutureMode && 
                               effectiveObs.any((o) => o.tideHeight == null) &&
                               effectiveObs.any((o) => o.waveHeight != null);

    // 峰值與極值安全邊界計算
    int peakIndex = -1;
    double maxVal = double.negativeInfinity;
    double minVal = double.infinity;

    for (int i = 0; i < effectiveObs.length; i++) {
      final double? rawVal = useWaveHeight ? effectiveObs[i].waveHeight : effectiveObs[i].tideHeight;
      if (rawVal != null && !rawVal.isNaN && !rawVal.isInfinite) {
        if (rawVal > maxVal) { 
          maxVal = rawVal; 
          peakIndex = i; 
        }
        if (rawVal < minVal) {
          minVal = rawVal;
        }
      }
    }

    // 若數值全為空或無效，提供預設安全邊界
    if (maxVal == double.negativeInfinity || minVal == double.infinity) {
      maxVal = 2.0;
      minVal = 0.0;
    } else if (maxVal == minVal) {
      maxVal += 0.5;
      minVal = math.max(0.0, minVal - 0.5);
    }

    final double chartMinY = math.max(-2.0, minVal - 0.3);
    final double chartMaxY = maxVal + 0.3;

    double? goldenStartX;
    double? goldenEndX;

    if (peakIndex != -1 && effectiveObs.length >= 2) {
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

    final Color waveLineColor = isFutureMode 
        ? AppColors.bioGold 
        : (isLight ? AppColors.marineBlue : AppColors.pelagicCyan);

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
                    width: 10, 
                    height: 3, 
                    decoration: BoxDecoration(
                      color: waveLineColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFutureMode 
                        ? "30 天未來潮位推算 (m)" 
                        : (useWaveHeight ? "實測波高走勢 (m)" : "實測潮位走勢 (m)"),
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w700, 
                      color: isLight ? Colors.grey.shade700 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (goldenStartX != null && goldenEndX != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bioGold.withValues(alpha: isLight ? 0.12 : 0.15), 
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.bioGold.withValues(alpha: isLight ? 0.25 : 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: const Text(
                        "🔥 爆咬黃金期", 
                        style: TextStyle(fontSize: 9.5, color: AppColors.bioGold, fontWeight: FontWeight.w800),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.06), 
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      chartDate, 
                      style: TextStyle(
                        fontSize: 10.5, 
                        color: isLight ? Colors.grey.shade600 : AppColors.textTertiary, 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        
        Container(
          height: 220,
          padding: const EdgeInsets.only(right: 18, top: 12),
          child: LineChart(
            LineChartData(
              minY: chartMinY,
              maxY: chartMaxY,
              rangeAnnotations: RangeAnnotations(
                verticalRangeAnnotations: [
                  if (goldenStartX != null && goldenEndX != null && goldenStartX < goldenEndX)
                    VerticalRangeAnnotation(
                      x1: goldenStartX,
                      x2: goldenEndX,
                      color: AppColors.bioGold.withValues(alpha: isLight ? 0.08 : 0.12),
                    ),
                ],
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  if (peakIndex >= 0 && peakIndex < effectiveObs.length && maxVal != double.negativeInfinity)
                    VerticalLine(
                      x: peakIndex.toDouble(),
                      color: AppColors.bioGold.withValues(alpha: 0.8),
                      strokeWidth: 1.0,
                      dashArray: [4, 4],
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(bottom: 6, left: 6),
                        labelResolver: (_) => isFutureMode ? "預報滿水" : "實測滿潮",
                        style: const TextStyle(color: AppColors.bioGold, fontWeight: FontWeight.w800, fontSize: 9.5),
                      )
                    )
                ]
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isLight ? Colors.grey.shade200 : AppColors.glassBorder,
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
                    reservedSize: 28,
                    interval: 4, 
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index >= 0 && index < effectiveObs.length) {
                        final String timeStr = DateFormat('HH:mm').format(effectiveObs[index].dateTime);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6,
                          child: Text(
                            timeStr, 
                            style: TextStyle(
                              fontSize: 10, 
                              color: isLight ? Colors.grey.shade500 : AppColors.textTertiary,
                            ),
                          ),
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
                        style: TextStyle(
                          fontSize: 10, 
                          color: isLight ? Colors.grey.shade500 : AppColors.textTertiary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      );
                    },
                    reservedSize: 34,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: effectiveObs.asMap().entries.map((e) {
                    double yValue = useWaveHeight 
                        ? (e.value.waveHeight ?? 0.0) 
                        : (e.value.tideHeight ?? 0.0);
                    if (yValue.isNaN || yValue.isInfinite) yValue = 0.0;
                    return FlSpot(e.key.toDouble(), yValue);
                  }).toList(),
                  isCurved: true, 
                  curveSmoothness: 0.38, 
                  color: waveLineColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false), 
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        waveLineColor.withValues(alpha: isLight ? 0.12 : 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: isLight ? Colors.white : AppColors.abyssCard,
                  tooltipRoundedRadius: 12,
                  tooltipBorder: BorderSide(
                    color: isLight ? Colors.grey.shade200 : AppColors.glassBorder,
                    width: 0.5,
                  ),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final obs = effectiveObs[barSpot.x.toInt()];
                      final String fullTime = DateFormat('MM/dd HH:mm').format(obs.dateTime);
                      return LineTooltipItem(
                        "$fullTime\n",
                        TextStyle(
                          color: isLight ? Colors.grey.shade600 : AppColors.textSecondary, 
                          fontWeight: FontWeight.w600, 
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: "${barSpot.y.toStringAsFixed(2)} m",
                            style: TextStyle(
                              color: waveLineColor, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 14,
                              fontFeatures: const [FontFeature.tabularFigures()],
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

  static double _parseTideMeters(String valStr) {
    final v = double.tryParse(valStr);
    if (v == null) return 1.0;
    // 智慧單位自適應：絕對值大於 25 判定為公分換算公尺，否則保留公尺
    if (v.abs() > 25.0) return v / 100.0;
    return v;
  }

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

        final double h1 = _parseTideMeters(prev.tideHeight);
        final double h2 = _parseTideMeters(next.tideHeight);

        heightInMeters = (h1 + h2) / 2.0 + ((h1 - h2) / 2.0) * math.cos(math.pi * ratio);
      } else if (sorted.isNotEmpty) {
        final closest = sorted.reduce((a, b) => 
          (a.dateTime.difference(currentT).abs() < b.dateTime.difference(currentT).abs()) ? a : b
        );
        heightInMeters = _parseTideMeters(closest.tideHeight);
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
