import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/solunar_util.dart';
import '../../data/tide_model.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🌟 VVIP 專屬：老船長經典紙本純潮汐對照表 (Classic Nautical Tide Almanac)
/// 徹底屏蔽所有現代裝飾雜訊，回歸傳統船舶航海日誌與漁業氣象純潮汐矩陣排印
class ClassicPureTideTable extends StatelessWidget {
  final TideStationData station;
  final DateTime selectedDate;
  final bool isClassic;

  const ClassicPureTideTable({
    super.key,
    required this.station,
    required this.selectedDate,
    required this.isClassic,
  });

  @override
  Widget build(BuildContext context) {
    final solunar = SolunarUtil.calculate(selectedDate);
    final selectedKey = DateFormat('yyyyMMdd').format(selectedDate);
    
    // 依選定日期過濾預報節點
    final dayForecasts = station.forecasts.where((f) =>
        DateFormat('yyyyMMdd').format(f.dateTime) == selectedKey).toList();
    
    final sortedForecasts = List<TideForecast>.from(
      dayForecasts.isNotEmpty ? dayForecasts : station.forecasts.take(4).toList()
    )..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final Color cardBg = isClassic ? Colors.white : AppColors.abyssCard;
    final Color textColor = isClassic ? AppColors.classicText : AppColors.textPrimary;
    final Color subTextColor = isClassic ? Colors.blueGrey.shade700 : AppColors.textSecondary;
    final Color borderColor = isClassic ? Colors.grey.shade300 : AppColors.glassBorder;
    final Color goldColor = isClassic ? const Color(0xFFD97706) : AppColors.bioGold;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 傳統船舶航海日誌抬頭
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.menu_book_rounded, color: goldColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "老船長經典純潮汐對照表",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: goldColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: goldColor.withValues(alpha: 0.35), width: 0.5),
                            ),
                            child: Text(
                              "VVIP 專屬",
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: goldColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "氣象署官方 85 站光纖極值錨定 · 零雜訊航海紙本排印",
                        style: TextStyle(fontSize: 10.5, color: subTextColor),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: "複製純文字潮汐表至剪貼簿",
                color: subTextColor,
                onPressed: () => _copyTideTableToClipboard(context, solunar, sortedForecasts),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. 天文月相與天體引力狀態條 (傳統農曆水文綱要)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isClassic ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(solunar.moonPhaseEmoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      "${solunar.lunarDateStr} · ${solunar.moonPhaseName}",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textColor),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${solunar.tideCategory} (係數 ${solunar.tidalCoefficient})",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: goldColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. 核心紙本表格 (The Classic Nautical Matrix)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2), // 時程
                  1: FlexColumnWidth(1.1), // 狀態
                  2: FlexColumnWidth(1.2), // 潮位 (cm)
                  3: FlexColumnWidth(1.6), // 潮差變動
                  4: FlexColumnWidth(1.8), // 走水等級
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // 表頭 (Header)
                  TableRow(
                    decoration: BoxDecoration(
                      color: isClassic ? const Color(0xFF0077B6).withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.06),
                    ),
                    children: [
                      _buildHeaderCell("時間", isClassic),
                      _buildHeaderCell("狀態", isClassic),
                      _buildHeaderCell("潮高", isClassic),
                      _buildHeaderCell("潮差變動", isClassic),
                      _buildHeaderCell("起流走水窗口", isClassic),
                    ],
                  ),

                  // 數據行 (Data Rows)
                  ...List.generate(sortedForecasts.length, (idx) {
                    final f = sortedForecasts[idx];
                    final bool isHigh = f.tideType.contains("滿");
                    final double? currH = double.tryParse(f.tideHeight);
                    final String timeStr = DateFormat('HH:mm').format(f.dateTime);

                    // 計算與前一刻之潮差變動
                    String diffStr = "--";
                    String speedStr = "平水微流";
                    Color speedColor = isClassic ? Colors.blueGrey : AppColors.textTertiary;

                    if (idx > 0 && currH != null) {
                      final prevH = double.tryParse(sortedForecasts[idx - 1].tideHeight);
                      if (prevH != null) {
                        final diff = (currH - prevH).round();
                        diffStr = isHigh ? "▲ +${diff.abs()}cm" : "▼ -${diff.abs()}cm";
                        if (diff.abs() >= 160) {
                          speedStr = "大急流 (開大水)";
                          speedColor = goldColor;
                        } else if (diff.abs() >= 90) {
                          speedStr = "中走水 (活水)";
                          speedColor = isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan;
                        } else {
                          speedStr = "緩流 (平水)";
                        }
                      }
                    }

                    // 走水窗口推算
                    String windowTip = isHigh ? "滿退二分" : "乾潮底起流";
                    if (isHigh) {
                      final biteStart = f.dateTime.add(const Duration(hours: 1, minutes: 15));
                      windowTip = "滿退2分 (${DateFormat('HH:mm').format(biteStart)})";
                    }

                    final Color rowBg = idx % 2 == 0 
                        ? (isClassic ? Colors.white : Colors.transparent) 
                        : (isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.02));

                    return TableRow(
                      decoration: BoxDecoration(color: rowBg),
                      children: [
                        _buildDataCell(timeStr, isClassic, isBold: true),
                        _buildStatusCell(f.tideType, isHigh, isClassic),
                        _buildDataCell("${f.tideHeight}cm", isClassic, isBold: true),
                        _buildDataCell(diffStr, isClassic, customColor: isHigh ? AppColors.hazardCoral : AppColors.pelagicCyan),
                        _buildWindowCell(windowTip, speedStr, speedColor, isClassic),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. 老船長戰術備忘錄
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 14, color: goldColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "老船長作戰叮嚀：${solunar.biteWindowAdvice}",
                  style: TextStyle(
                    fontSize: 11,
                    color: subTextColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, bool isClassic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isClassic ? const Color(0xFF023E8A) : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, bool isClassic, {bool isBold = false, Color? customColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          color: customColor ?? (isClassic ? AppColors.classicText : AppColors.textPrimary),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildStatusCell(String tideType, bool isHigh, bool isClassic) {
    final Color badgeColor = isHigh ? AppColors.hazardCoral : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tideType,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: badgeColor),
          ),
        ),
      ),
    );
  }

  Widget _buildWindowCell(String windowTip, String speedStr, Color speedColor, bool isClassic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            windowTip,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: isClassic ? Colors.black87 : AppColors.textPrimary),
          ),
          Text(
            speedStr,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9.5, color: speedColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _copyTideTableToClipboard(BuildContext context, SolunarData solunar, List<TideForecast> list) {
    HapticFeedback.lightImpact();
    final stationName = station.info.stationName;
    final dateStr = DateFormat('yyyy/MM/dd').format(selectedDate);

    final StringBuffer sb = StringBuffer();
    sb.writeln("🌊【老船長經典純潮汐對照表】$stationName");
    sb.writeln("📅 日期：$dateStr (${solunar.lunarDateStr}) | 天體水象：${solunar.tideCategory}");
    sb.writeln("---------------------------------------------");
    sb.writeln("時間      狀態    潮高    走水推算");
    for (final f in list) {
      final t = DateFormat('HH:mm').format(f.dateTime);
      sb.writeln("$t     ${f.tideType.padRight(4)}  ${f.tideHeight}cm");
    }
    sb.writeln("---------------------------------------------");
    sb.writeln("💡 戰術指引：${solunar.biteWindowAdvice}");
    sb.writeln("📲 潮汐表 Pro 85 測站光纖直連：https://beigou0427.github.io/tide_forecast_app/");

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ 已將純文字潮汐對照表複製至剪貼簿，可直接貼至 LINE 群組！"),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}