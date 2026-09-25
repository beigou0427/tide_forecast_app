import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/ugc_report_model.dart';
import '../../../core/utils/solunar_util.dart';
import '../../premium/services/premium_service.dart';

final ugcReportProvider = StateNotifierProvider<UgcReportNotifier, List<UgcReportItem>>((ref) {
  return UgcReportNotifier(ref);
});

class UgcReportNotifier extends StateNotifier<List<UgcReportItem>> {
  static const String _storageKey = "ugc_reports_v1";
  final Ref ref;

  UgcReportNotifier(this.ref) : super([]) {
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      
      final now = DateTime.now();
      List<UgcReportItem> loaded = rawList
          .map((e) => UgcReportItem.fromJson(e))
          .where((item) {
            final diff = now.difference(item.timestamp);
            // 🚨 死穴 4 修復：雙向時間圍欄 (Two-Way Temporal Fence)
            // 1. 下界：diff.inMinutes >= -5，只允許最多 5 分鐘時鐘漂移，徹底消滅未來 2099 永生穿透！
            // 2. 上界：diff.inMinutes <= 360，嚴格 6 小時整自動過期清除！
            return diff.inMinutes >= -5 && diff.inMinutes <= 360;
          })
          .toList();

      state = loaded..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      state = [];
    }
  }

  List<UgcReportItem> getReportsForStation(String stationId, {double? waveHeight, double? windSpeed}) {
    final realReports = state.where((r) => r.stationId == stationId).toList();
    if (realReports.isNotEmpty) {
      return realReports;
    }

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

  // 尊榮 VVIP 階級頭銜與自帶權威讚
  Future<void> reportCondition(String stationId, UgcConditionType type) async {
    final premium = ref.read(premiumProvider);
    
    String customTag = "🔥 現場認證釣友";
    int initialUpvotes = 1;

    if (premium.isFounder) {
      customTag = "👑 創始天尊指揮官";
      initialUpvotes = 8;
    } else if (premium.type == SubscriptionType.yearly) {
      customTag = "🔱 年度首席領航員";
      initialUpvotes = 5;
    } else if (premium.isPremium) {
      customTag = "⭐ VIP 專業航海家";
      initialUpvotes = 3;
    }

    final newItem = UgcReportItem(
      id: "ugc_${DateTime.now().millisecondsSinceEpoch}",
      stationId: stationId,
      timestamp: DateTime.now(),
      type: type,
      userTag: customTag,
      upvotes: initialUpvotes,
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