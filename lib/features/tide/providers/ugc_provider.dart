import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref ref;

  UgcReportNotifier(this.ref) : super([]) {
    _loadReports();
  }

  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // 1. 離線優先：先載入本地快取，確保在無訊號外礁秒開 (0ms)
    final rawList = prefs.getStringList(_storageKey) ?? [];
    List<UgcReportItem> localReports = rawList
        .map((e) => UgcReportItem.fromJson(e))
        .where((item) {
          final diff = now.difference(item.timestamp);
          return diff.inMinutes >= -5 && diff.inMinutes <= 360;
        })
        .toList();

    state = localReports..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 2. 🌟 終極破局：真正連網！從 Firestore 全國公共雷達拉取全台釣友最新情報！
    try {
      final sixHoursAgo = now.subtract(const Duration(hours: 6));
      final snapshot = await _firestore
          .collection('public_ugc_reports')
          .where('timestamp', isGreaterThan: sixHoursAgo.toIso8601String())
          .limit(100)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final cloudReports = snapshot.docs
            .map((doc) => UgcReportItem.fromMap(doc.data()))
            .toList();

        // 雙向合併去重 (以雲端最新讚數與情報為準)
        final Map<String, UgcReportItem> mergedMap = {};
        for (var item in localReports) {
          mergedMap[item.id] = item;
        }
        for (var item in cloudReports) {
          mergedMap[item.id] = item;
        }

        final mergedList = mergedMap.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        state = mergedList;

        // 同步寫入本機快取
        await prefs.setStringList(_storageKey, mergedList.map((e) => e.toJson()).toList());
        debugPrint("📡 [真·Waze雷達] 成功同步全台 ${cloudReports.length} 筆釣友即時情報！");
      }
    } catch (e) {
      debugPrint("⚠️ [UGC雷達] 雲端同步暫時離線，平滑維持本機情報: $e");
    }
  }

  List<UgcReportItem> getReportsForStation(String stationId, {double? waveHeight, double? windSpeed}) {
    final realReports = state.where((r) => r.stationId == stationId).toList();
    if (realReports.isNotEmpty) {
      return realReports;
    }

    // 0 人回報時，由 AI 哨兵即時推演補位
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

  // 🌟 全網廣播實況情報
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

    // 1. Optimistic UI 更新本機
    final updated = [newItem, ...state];
    state = updated;
    await _save(updated);

    // 2. 🌟 真正連網！將情報即時廣播至全台公共集合！
    try {
      await _firestore.collection('public_ugc_reports').doc(newItem.id).set(newItem.toMap());
      debugPrint("📢 [真·Waze雷達] 釣況情報已成功廣播至全台灣！");
    } catch (e) {
      debugPrint("⚠️ [真·Waze雷達] 廣播失敗，已暫存於本機: $e");
    }
  }

  // 🌟 雲端點讚原子遞增
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

    // 🌟 全網同步累加讚數
    try {
      await _firestore.collection('public_ugc_reports').doc(reportId).update({
        'upvotes': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  Future<void> _save(List<UgcReportItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = list.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, raw);
  }
}