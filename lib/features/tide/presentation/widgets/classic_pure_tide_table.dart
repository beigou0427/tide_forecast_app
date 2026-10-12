import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/solunar_util.dart';
import '../../data/tide_model.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🌟 100% 依據 V1 原始碼 DNA 還原之老船長經典純潮汐對照表
/// 100% 時態保真與物理單位修復版：
/// 1. 徹底消滅歷史無資料日時，偷抓未來預報來充數的「時空幻覺」重大詐欺漏洞！
/// 2. 實裝智能單位格式化器 (_formatHeight)，消滅 LINE 戰報出現 1.85cm 的尷尬瑕疵。
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

  /// 🌟 智慧物理單位格式化器 (防呆)
  String _formatHeight(String h) {
    final v = double.tryParse(h);
    if (v == null) return "$h cm";
    // 若含有小數點或小於 10，代表底層已歸一化為公尺 (m)
    if (v.abs() < 10.0 || h.contains('.')) return "${v.toStringAsFixed(2)} m";
    // 否則維持公分 (cm)
    return "${v.toStringAsFixed(0)} cm";
  }

  @override
  Widget build(BuildContext context) {
    final solunar = SolunarUtil.calculate(selectedDate);
    final selectedKey = DateFormat('yyyyMMdd').format(selectedDate);
    
    // 依選定日期過濾預報節點
    final dayForecasts = station.forecasts.where((f) =>
        DateFormat('yyyyMMdd').format(f.dateTime) == selectedKey).toList();
    
    // 🚨 核心防禦：絕不拿未來的預報 (take(4)) 來填補歷史的空白！維持 SSOT 單一真相！
    final sortedForecasts = List<TideForecast>.from(dayForecasts)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final Color textColor = isClassic ? AppColors.classicText : AppColors.textPrimary;
    final Color subTextColor = isClassic ? Colors.blueGrey.shade700 : AppColors.textSecondary;
    final Color goldColor = isClassic ? const Color(0xFFD97706) : AppColors.bioGold;

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 頂部經典標題列與一鍵分享至 LINE 快捷鍵
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.anchor_rounded, color: goldColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "老船長經典潮汐表",
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
                        "V1 經典排印",
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: goldColor),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: "複製純文字至 LINE 群組",
                  color: subTextColor,
                  onPressed: () => _copyTideTableToClipboard(context, solunar, sortedForecasts),
                ),
              ],
            ),
          ),
          
          // 2. 簡練天體水象綱要
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Text(
              "${solunar.lunarDateStr} • ${solunar.moonPhaseName} • ${solunar.tideCategory} (係數 ${solunar.tidalCoefficient})",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: goldColor),
            ),
          ),

          Divider(height: 1, color: isClassic ? Colors.grey.shade200 : AppColors.glassBorder),

          // 3. 原汁原味 V1 原始碼 DNA 實體排版
          if (sortedForecasts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "該日無潮汐預報資料或已歸檔\n請參考上方天文物理調和模型走勢",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subTextColor, fontSize: 12.5, height: 1.5),
                ),
              ),
            )
          else
            ...sortedForecasts.map((f) {
              final bool isHigh = f.tideType.contains("滿");
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                leading: Icon(
                  isHigh ? Icons.arrow_upward : Icons.arrow_downward, 
                  color: isHigh ? Colors.redAccent : Colors.blueAccent, 
                  size: 20,
                ),
                title: Text(
                  "${DateFormat('HH:mm').format(f.dateTime)} - ${f.tideType}",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: textColor,
                  ),
                ),
                trailing: Text(
                  _formatHeight(f.tideHeight),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                    color: isClassic ? Colors.blueGrey.shade800 : AppColors.pelagicCyan,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _copyTideTableToClipboard(BuildContext context, SolunarData solunar, List<TideForecast> list) {
    HapticFeedback.lightImpact();
    final stationName = station.info.stationName;
    final dateStr = DateFormat('yyyy/MM/dd').format(selectedDate);

    final StringBuffer sb = StringBuffer();
    sb.writeln("🌊【老船長經典潮汐表】$stationName");
    sb.writeln("📅 日期：$dateStr (${solunar.lunarDateStr}) | ${solunar.tideCategory}");
    sb.writeln("-----------------------------");
    if (list.isEmpty) {
      sb.writeln("⚠️ 該日預報已歸檔，以實測為主");
    } else {
      for (final f in list) {
        final t = DateFormat('HH:mm').format(f.dateTime);
        sb.writeln("$t - ${f.tideType.padRight(4)} ${_formatHeight(f.tideHeight)}");
      }
    }
    sb.writeln("-----------------------------");
    sb.writeln("📲 潮汐表 Pro 85 測站光纖直連：https://beigou0427.github.io/tide_forecast_app/");

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ 已複製純文字潮汐表，可直接貼至 LINE 群組！"),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}