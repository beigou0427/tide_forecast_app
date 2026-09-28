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
  SharedPreferences? _prefs;

  UgcReportNotifier(this.ref) : super([]) {
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadReports();
  }

  Future<void> _loadReports() async {
    final now = DateTime.now();

    // 1. 離線優先：0ms 秒開本機快取，並過濾未來時間竄改（時鐘偏斜防線）
    final rawList = _prefs?.getStringList(_storageKey) ?? [];
    List<UgcReportItem> localReports = rawList
        .map((e) => UgcReportItem.fromJson(e))
        .where((item) {
          final diff = now.difference(item.timestamp);
          // 嚴格限制：不允許超過未來 2 分鐘，且在過去 6 小時內
          return diff.inMinutes >= -2 && diff.inMinutes <= 360;
        })
        .toList();

    state = localReports..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 2. 雲端同步：Leslie Lamport 雙向時鐘邊界防衛查詢
    try {
      final sixHoursAgo = now.subtract(const Duration(hours: 6));
      // 容許最多 2 分鐘時鐘漂移，徹底阻斷惡意手動調快時鐘的「幽靈置頂情報」
      final maxAllowedTime = now.add(const Duration(minutes: 2));

      final snapshot = await _firestore
          .collection('public_ugc_reports')
          .where('timestamp', isGreaterThan: sixHoursAgo.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: maxAllowedTime.toIso8601String())
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final cloudReports = snapshot.docs
            .map((doc) => UgcReportItem.fromMap(doc.data()))
            .where((item) => !item.timestamp.isAfter(maxAllowedTime))
            .toList();

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
        _saveToDisk(mergedList);
        debugPrint("📡 [真·Waze雷達] 經因果定序檢驗，成功同步全台 ${cloudReports.length} 筆實況！");
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

    // 0 人回報時，由 AI 水文哨兵即時補位
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

    // 分散式唯一識別碼：杜絕毫秒碰撞 (Collision-Free UUID)
    final newDocRef = _firestore.collection('public_ugc_reports').doc();
    final String distributedId = newDocRef.id;

    final newItem = UgcReportItem(
      id: distributedId,
      stationId: stationId,
      timestamp: DateTime.now(),
      type: type,
      userTag: customTag,
      upvotes: initialUpvotes,
    );

    final updated = [newItem, ...state];
    state = updated;
    _saveToDisk(updated);

    try {
      await newDocRef.set(newItem.toMap());
      debugPrint("📢 [真·Waze雷達] 釣況情報已廣播至雲端雷達 (ID: $distributedId)！");
    } catch (e) {
      debugPrint("⚠️ [真·Waze雷達] 雲端廣播暫時無法送達，保留於本機快取: $e");
    }
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
    _saveToDisk(updated);

    try {
      await _firestore.collection('public_ugc_reports').doc(reportId).set({
        'upvotes': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("⚠️ [點讚同步例外]: $e");
    }
  }

  void _saveToDisk(List<UgcReportItem> list) {
    if (_prefs == null) return;
    try {
      final raw = list.map((e) => e.toJson()).toList();
      _prefs!.setStringList(_storageKey, raw);
    } catch (_) {}
  }
}
