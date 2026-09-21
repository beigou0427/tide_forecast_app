import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/ugc_report_model.dart';
import '../../../core/utils/solunar_util.dart';

final ugcReportProvider = StateNotifierProvider<UgcReportNotifier, List<UgcReportItem>>((ref) {
  return UgcReportNotifier();
});

class UgcReportNotifier extends StateNotifier<List<UgcReportItem>> {
  static const String _storageKey = "ugc_reports_v1";

  UgcReportNotifier() : super([]) {
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      
      final now = DateTime.now();
      List<UgcReportItem> loaded = rawList
          .map((e) => UgcReportItem.fromJson(e))
          .where((item) => now.difference(item.timestamp).inHours < 6)
          .toList();

      state = loaded..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      state = [];
    }
  }

  /// 🌟 核心破局：若該測站無真人回報，自動以 AI 水文哨兵推演動態情報，確保絕不留白！
  List<UgcReportItem> getReportsForStation(String stationId, {double? waveHeight, double? windSpeed}) {
    final realReports = state.where((r) => r.stationId == stationId).toList();
    if (realReports.isNotEmpty) {
      return realReports;
    }

    // 當前無真人通報時，由 AI 哨兵依實時感測數據動態生成推演情報
    final now = DateTime.now();
    final solunar = SolunarUtil.calculate(now);
    final double wave = waveHeight ?? 0.8;
    final double wind = windSpeed ?? 4.0;

    final List<UgcReportItem> sentinelReports = [];

    if (wave >= 2.0 || wind >= 10.0) {
      sentinelReports.add(UgcReportItem(
        id: "ai_sentinel_wave_$stationId",
        stationId: stationId,
        timestamp: now.subtract(const Duration(minutes: 18)),
        type: UgcConditionType.waveLarger,
        userTag: "🤖 AI 水文巡航哨兵",
        upvotes: 12,
      ));
    } else {
      sentinelReports.add(UgcReportItem(
        id: "ai_sentinel_calm_$stationId",
        stationId: stationId,
        timestamp: now.subtract(const Duration(minutes: 22)),
        type: UgcConditionType.waveCalm,
        userTag: "🤖 AI 水文巡航哨兵",
        upvotes: 9,
      ));
    }

    if (solunar.fishActivityScore >= 80) {
      sentinelReports.add(UgcReportItem(
        id: "ai_sentinel_bite_$stationId",
        stationId: stationId,
        timestamp: now.subtract(const Duration(minutes: 45)),
        type: UgcConditionType.fishBiting,
        userTag: "🤖 老船長 AI 咬度推論",
        upvotes: 16,
      ));
    }

    return sentinelReports;
  }

  Future<void> reportCondition(String stationId, UgcConditionType type) async {
    final newItem = UgcReportItem(
      id: "ugc_${DateTime.now().millisecondsSinceEpoch}",
      stationId: stationId,
      timestamp: DateTime.now(),
      type: type,
      userTag: "🔥 現場認證釣友",
      upvotes: 1,
    );

    final updated = [newItem, ...state];
    state = updated;
    await _save(updated);
  }

  Future<void> upvote(String reportId) async {
    final updated = state.map((item) {
      if (item.id == reportId) {
        return UgcReportItem(
          id: item.id,
          stationId: item.stationId,
          timestamp: item.timestamp,
          type: item.type,
          userTag: item.userTag,
          upvotes: item.upvotes + 1,
        );
      }
      return item;
    }).toList();

    state = updated;
    await _save(updated);
  }

  Future<void> _save(List<UgcReportItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = list.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, raw);
  }
}


