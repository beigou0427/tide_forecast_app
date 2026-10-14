import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/tide_model.dart';

/// 🌟 經海事光學對比重塑之潮位與波高趨勢圖表 (Tide Chart Sheet)
/// 100% 三模光學適配與動態網格版：
/// 1. 徹底消滅深色模式下深藍曲線隱沒在黑卡片的視覺盲區！
/// 2. 【PM優化】動態 X 軸刻度間距，完美相容高頻實測與低頻未來預報點陣列！
class TideChartSheet extends ConsumerWidget {
  final List<Observation> observations;

  const TideChartSheet({
    super.key,
    required this.observations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;
    final bool isDark = themeMode == AppThemeMode.darkAbyss;

    final Color lineColor = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
    final Color titleColor = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.blueGrey.shade800 : AppColors.textPrimary);
    final Color axisColor = isEInk 
        ? Colors.black54 
        : (isClassic ? Colors.grey.shade600 : AppColors.textSecondary);
    final Color gridColor = isEInk 
        ? Colors.black12 
        : (isClassic ? Colors.grey.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05));
    final Color dateChipBg = isEInk 
        ? Colors.black12 
        : (isClassic ? Colors.blueGrey.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.06));
    final Color dateChipText = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary);
    final Color tooltipBg = isEInk 
        ? Colors.white 
        : (isClassic ? const Color(0xFF023E8A) : AppColors.abyssSurface);

    if (observations.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "目前無圖表觀測數據", 
            style: TextStyle(color: axisColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final String chartDate = DateFormat('yyyy/MM/dd').format(observations.first.dateTime);

    final bool useWaveHeight = observations.any((o) => o.tideHeight == null) &&
                               observations.any((o) => o.waveHeight != null);

    // 🌟 PM 核心優化：動態 X 軸網格間距，消滅合成陣列的標籤遺失！
    final int dataLength = observations.length;
    final double dynamicInterval = dataLength <= 8 ? 1.0 : (dataLength / 6).roundToDouble();

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
                  Container(width: 12, height: 3.5, decoration: BoxDecoration(color: lineColor, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(
                    useWaveHeight ? "實測波高趨勢 (m)" : "即時潮位趨勢 (m)",
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: dateChipBg,
                  borderRadius: BorderRadius.circular(6),
                  border: isEInk ? Border.all(color: Colors.black, width: 1.0) : null,
                ),
                child: Text(
                  chartDate,
                  style: TextStyle(fontSize: 11, color: dateChipText, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        
        // --- 核心圖表區 ---
        Container(
          height: 220,
          padding: const EdgeInsets.only(right: 20, top: 12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: gridColor,
                  strokeWidth: isEInk ? 1.0 : 0.8,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                
                // 下方 X 軸時間
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: dynamicInterval, // 🌟 注入智慧動態間距
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index >= 0 && index < observations.length) {
                        final String timeStr = DateFormat('HH:mm').format(observations[index].dateTime);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(timeStr, style: TextStyle(fontSize: 10, color: axisColor, fontWeight: FontWeight.w500)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                
                // 左側 Y 軸高度
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        "${value.toStringAsFixed(1)}m",
                        style: TextStyle(fontSize: 10, color: axisColor, fontWeight: FontWeight.w500),
                      );
                    },
                    reservedSize: 36,
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
                  color: lineColor,
                  barWidth: isEInk ? 3.5 : 3.0,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: dataLength <= 8, // 🌟 若點數稀少（未來預報），自動顯示資料點提示圓點！
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3,
                      color: lineColor,
                      strokeWidth: 1.5,
                      strokeColor: tooltipBg,
                    ),
                  ), 
                  belowBarData: BarAreaData(
                    show: !isEInk, // 🌟 E-Ink 模式徹底關閉漸層，杜絕泥濘髒灰
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        lineColor.withValues(alpha: isDark ? 0.35 : 0.25),
                        lineColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: tooltipBg,
                  tooltipRoundedRadius: 10,
                  tooltipBorder: isEInk ? const BorderSide(color: Colors.black, width: 1.5) : const BorderSide(color: AppColors.glassBorder, width: 0.5),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final obs = observations[barSpot.x.toInt()];
                      final String fullTime = DateFormat('MM/dd HH:mm').format(obs.dateTime);
                      return LineTooltipItem(
                        "$fullTime\n",
                        TextStyle(color: isEInk ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        children: [
                          TextSpan(
                            text: "${barSpot.y.toStringAsFixed(2)} m",
                            style: TextStyle(
                              color: isEInk ? Colors.black : AppColors.pelagicCyan, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 14.5,
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
}
