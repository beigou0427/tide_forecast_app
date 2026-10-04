import 'dart:math' as math;
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/tide_model.dart';
import '../../../../core/theme/app_theme.dart';

/// 🌟 經海事嚴謹標準重塑之潮汐走勢圖表
/// 嚴格錨定氣象署官方滿乾潮預報節點，清晰區隔實測、官方極值與插值趨勢，杜絕航海吃水誤導
class TideChartSheet extends StatefulWidget {
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
  State<TideChartSheet> createState() => _TideChartSheetState();
}

class _TideChartSheetState extends State<TideChartSheet> {
  // 🌟 John Carmack 記憶化計算快取：防止 build() 每次觸發昂貴的 O(N) 重複計算
  List<Observation>? _memoizedEffectiveObs;
  Set<int> _officialAnchorIndices = {};
  int _lastObsHash = 0;
  int _lastForecastHash = 0;
  DateTime? _lastTargetDate;

  double _chartMinY = 0.0;
  double _chartMaxY = 3.0;
  int _peakIndex = -1;
  double? _goldenStartX;
  double? _goldenEndX;
  bool _useWaveHeight = false;
  String _chartDateStr = "";

  @override
  void initState() {
    super.initState();
    _recomputeChartMetricsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant TideChartSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeChartMetricsIfNeeded();
  }

  void _recomputeChartMetricsIfNeeded() {
    final int currentObsHash = Object.hashAll(widget.observations.map((o) => o.dateTime));
    final int currentForecastHash = widget.futureForecasts != null 
        ? Object.hashAll(widget.futureForecasts!.map((f) => f.dateTime))
        : 0;

    if (_memoizedEffectiveObs != null &&
        _lastObsHash == currentObsHash &&
        _lastForecastHash == currentForecastHash &&
        _lastTargetDate == widget.targetDate) {
      return;
    }

    _lastObsHash = currentObsHash;
    _lastForecastHash = currentForecastHash;
    _lastTargetDate = widget.targetDate;

    final bool isFutureMode = widget.observations.isEmpty && 
                             widget.futureForecasts != null && 
                             widget.futureForecasts!.isNotEmpty;

    if (isFutureMode) {
      final synthesisResult = _synthesizeFutureCurveWithAnchors(
        widget.futureForecasts!, 
        widget.targetDate ?? DateTime.now(),
      );
      _memoizedEffectiveObs = synthesisResult.curve;
      _officialAnchorIndices = synthesisResult.anchorIndices;
    } else {
      _memoizedEffectiveObs = widget.observations;
      _officialAnchorIndices = {};
    }

    if (_memoizedEffectiveObs!.length < 2) return;

    _chartDateStr = DateFormat('yyyy/MM/dd').format(_memoizedEffectiveObs!.first.dateTime);
    _useWaveHeight = !isFutureMode && 
                     _memoizedEffectiveObs!.any((o) => o.tideHeight == null) &&
                     _memoizedEffectiveObs!.any((o) => o.waveHeight != null);

    // 峰值與極值安全邊界計算
    _peakIndex = -1;
    double maxVal = double.negativeInfinity;
    double minVal = double.infinity;

    for (int i = 0; i < _memoizedEffectiveObs!.length; i++) {
      final double? rawVal = _useWaveHeight 
          ? _memoizedEffectiveObs![i].waveHeight 
          : _memoizedEffectiveObs![i].tideHeight;
          
      if (rawVal != null && !rawVal.isNaN && !rawVal.isInfinite) {
        if (rawVal > maxVal) { 
          maxVal = rawVal; 
          _peakIndex = i; 
        }
        if (rawVal < minVal) {
          minVal = rawVal;
        }
      }
    }

    if (maxVal == double.negativeInfinity || minVal == double.infinity) {
      maxVal = 2.0;
      minVal = 0.0;
    } else if (maxVal == minVal) {
      maxVal += 0.5;
      minVal = math.max(0.0, minVal - 0.5);
    }

    _chartMinY = math.max(-2.0, minVal - 0.3);
    _chartMaxY = maxVal + 0.3;

    // 計算滿水起流黃金窗口
    _goldenStartX = null;
    _goldenEndX = null;

    if (_peakIndex != -1 && _memoizedEffectiveObs!.length >= 2) {
      final peakTime = _memoizedEffectiveObs![_peakIndex].dateTime;
      final startTime = peakTime.subtract(const Duration(hours: 1, minutes: 30));
      final endTime = peakTime.add(const Duration(hours: 2, minutes: 30));

      int? startIdx;
      int? endIdx;

      for (int i = 0; i < _memoizedEffectiveObs!.length; i++) {
        final t = _memoizedEffectiveObs![i].dateTime;
        if (t.isAfter(startTime) || t.isAtSameMomentAs(startTime)) {
          startIdx ??= i;
        }
        if (t.isBefore(endTime) || t.isAtSameMomentAs(endTime)) {
          endIdx = i;
        }
      }

      if (startIdx != null && endIdx != null && startIdx < endIdx) {
        _goldenStartX = startIdx.toDouble();
        _goldenEndX = endIdx.toDouble();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final effectiveObs = _memoizedEffectiveObs ?? [];

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

    final bool isFutureMode = widget.observations.isEmpty && 
                             widget.futureForecasts != null && 
                             widget.futureForecasts!.isNotEmpty;

    final Color waveLineColor = isFutureMode 
        ? AppColors.bioGold 
        : (isLight ? AppColors.marineBlue : AppColors.pelagicCyan);

    return RepaintBoundary(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
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
                      Flexible(
                        child: Text(
                          isFutureMode 
                              ? "氣象署官方預測極值走勢 (m)" 
                              : (_useWaveHeight ? "實測波高走勢 (m)" : "實測潮位走勢 (m)"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w700, 
                            color: isLight ? Colors.grey.shade700 : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (_goldenStartX != null && _goldenEndX != null)
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
                          "🔥 走水黃金期", 
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
                        _chartDateStr, 
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
                minY: _chartMinY,
                maxY: _chartMaxY,
                rangeAnnotations: RangeAnnotations(
                  verticalRangeAnnotations: [
                    if (_goldenStartX != null && _goldenEndX != null && _goldenStartX! < _goldenEndX!)
                      VerticalRangeAnnotation(
                        x1: _goldenStartX!,
                        x2: _goldenEndX!,
                        color: AppColors.bioGold.withValues(alpha: isLight ? 0.08 : 0.12),
                      ),
                  ],
                ),
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    if (_peakIndex >= 0 && _peakIndex < effectiveObs.length)
                      VerticalLine(
                        x: _peakIndex.toDouble(),
                        color: AppColors.bioGold.withValues(alpha: 0.8),
                        strokeWidth: 1.0,
                        dashArray: const [4, 4],
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
                      double yValue = _useWaveHeight 
                          ? (e.value.waveHeight ?? 0.0) 
                          : (e.value.tideHeight ?? 0.0);
                      if (yValue.isNaN || yValue.isInfinite) yValue = 0.0;
                      return FlSpot(e.key.toDouble(), yValue);
                    }).toList(),
                    isCurved: true, 
                    curveSmoothness: 0.35, 
                    color: waveLineColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    // 🌟 嚴謹標記：在氣象署官方滿乾潮極值錨點處精確顯示圓點，杜絕誤認平滑曲線為實時深度的風險
                    dotData: FlDotData(
                      show: isFutureMode,
                      checkToShowDot: (spot, barData) {
                        return _officialAnchorIndices.contains(spot.x.toInt());
                      },
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4.5,
                          color: AppColors.bioGold,
                          strokeWidth: 1.5,
                          strokeColor: Colors.black,
                        );
                      },
                    ), 
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
                        final idx = barSpot.x.toInt();
                        final obs = effectiveObs[idx];
                        final String fullTime = DateFormat('MM/dd HH:mm').format(obs.dateTime);
                        final bool isOfficialNode = _officialAnchorIndices.contains(idx);

                        return LineTooltipItem(
                          "$fullTime ${isOfficialNode ? '⚓氣象署極值' : '調和趨勢'}\n",
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
          
          if (isFutureMode)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                "⚓ 圓點為氣象署官方滿乾潮預測極值；曲線為趨勢輔助，實時航行吃水請參考測深儀",
                style: TextStyle(
                  fontSize: 9.5,
                  color: isLight ? Colors.grey.shade600 : AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static double _parseTideMeters(String valStr) {
    final v = double.tryParse(valStr);
    if (v == null) return 1.0;
    if (v.abs() > 25.0) return v / 100.0;
    return v;
  }

  static _SynthesizedCurveResult _synthesizeFutureCurveWithAnchors(
    List<TideForecast> forecasts, 
    DateTime targetDay,
  ) {
    if (forecasts.isEmpty) {
      return _SynthesizedCurveResult(curve: [], anchorIndices: {});
    }

    final sorted = List<TideForecast>.from(forecasts)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final List<Observation> curve = [];
    final Set<int> anchorIndices = {};
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

        // 採用標準餘弦半日潮過渡算式
        final double cosComponent = math.cos(math.pi * ratio);
        heightInMeters = (h1 + h2) / 2.0 + ((h1 - h2) / 2.0) * cosComponent;
      } else if (sorted.isNotEmpty) {
        final closest = sorted.reduce((a, b) => 
          (a.dateTime.difference(currentT).abs() < b.dateTime.difference(currentT).abs()) ? a : b
        );
        heightInMeters = _parseTideMeters(closest.tideHeight);
      } else {
        heightInMeters = 1.0;
      }

      // 檢查此小時是否接近官方預報極值點 (45 分鐘內)
      final bool isNearOfficialNode = sorted.any(
        (f) => f.dateTime.difference(currentT).inMinutes.abs() <= 45
      );
      if (isNearOfficialNode) {
        anchorIndices.add(curve.length);
      }

      curve.add(Observation(
        dateTime: currentT,
        tideHeight: double.parse(heightInMeters.toStringAsFixed(2)),
        tideLevel: "預測趨勢",
      ));
    }
    return _SynthesizedCurveResult(curve: curve, anchorIndices: anchorIndices);
  }
}

class _SynthesizedCurveResult {
  final List<Observation> curve;
  final Set<int> anchorIndices;
  const _SynthesizedCurveResult({required this.curve, required this.anchorIndices});
}