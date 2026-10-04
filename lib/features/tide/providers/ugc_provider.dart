import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/ugc_report_model.dart';
import '../../premium/services/premium_service.dart';

final ugcReportProvider = StateNotifierProvider<UgcReportNotifier, List<UgcReportItem>>((ref) {
  return UgcReportNotifier(ref);
});

/// 🌟 經海事最高誠信原則重塑之真實海況情報引擎
/// 100% 杜絕前端偽造「假釣友 / 假 AI 哨兵」情報，無通報即誠實呈現空清單，捍衛出海人命安全
class UgcReportNotifier extends StateNotifier<List<UgcReportItem>> {
  static const String _storageKey = "ugc_reports_v1";
  static const String _tombstonesKey = "ugc_tombstones_v1";
  final Ref ref;
  
  SharedPreferences? _prefs;
  String _deviceId = "device_client";
  final Set<String> _knownTombstones = {};

  Future<void>? _initFuture;

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  UgcReportNotifier(this.ref) : super([]) {
    _initFuture = _initAndLoad();
  }

  Future<void> _ensureInitialized() async {
    if (_initFuture != null) {
      await _initFuture;
    }
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _initAndLoad() async {
    _prefs = await SharedPreferences.getInstance();
    _deviceId = _prefs?.getString('device_sync_id') ?? 'dev_${DateTime.now().millisecondsSinceEpoch}';
    
    final tombList = _prefs?.getStringList(_tombstonesKey) ?? [];
    _knownTombstones.addAll(tombList);

    await _loadReports();
  }

  Future<void> _loadReports() async {
    final now = DateTime.now();

    final rawList = _prefs?.getStringList(_storageKey) ?? [];
    List<UgcReportItem> localReports = rawList
        .map((e) => UgcReportItem.fromJson(e))
        .where((item) {
          final diff = now.difference(item.timestamp);
          return !item.isTombstoned && 
                 !_knownTombstones.contains(item.id) &&
                 diff.inMinutes >= -2 && 
                 diff.inMinutes <= 360;
        })
        .toList();

    final Map<String, UgcReportItem> currentMemoryMap = {for (var r in state) r.id: r};
    for (var local in localReports) {
      if (!currentMemoryMap.containsKey(local.id)) {
        currentMemoryMap[local.id] = local;
      }
    }

    state = currentMemoryMap.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final firestore = _firestore;
    if (firestore == null) {
      return;
    }

    try {
      final sixHoursAgo = now.subtract(const Duration(hours: 6));
      final maxAllowedTime = now.add(const Duration(minutes: 2));

      final snapshot = await firestore
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

        final mergedList = _mergeCausalReports(state, cloudReports);
        state = mergedList;
        _saveToDisk(mergedList);
      }
    } catch (e) {
      debugPrint("⚠️ [DDIA 引擎] 雲端同步暫時受阻，維持本機真實情報: $e");
    }
  }

  List<UgcReportItem> _mergeCausalReports(List<UgcReportItem> localList, List<UgcReportItem> remoteList) {
    final Map<String, UgcReportItem> mergeMap = {};

    for (var item in localList) {
      mergeMap[item.id] = item;
    }

    for (var remote in remoteList) {
      if (_knownTombstones.contains(remote.id) || remote.isTombstoned) {
        _knownTombstones.add(remote.id);
        mergeMap.remove(remote.id);
        continue;
      }

      if (!mergeMap.containsKey(remote.id)) {
        mergeMap[remote.id] = remote;
      } else {
        final local = mergeMap[remote.id]!;
        final Set<String> mergedVoters = Set<String>.from(local.voterDeviceIds)..addAll(remote.voterDeviceIds);
        final int maxCounter = math.max(local.logicalCounter, remote.logicalCounter);
        final int maxUpvotes = math.max(mergedVoters.length, math.max(local.upvotes, remote.upvotes));

        mergeMap[remote.id] = UgcReportItem(
          id: remote.id,
          stationId: remote.stationId,
          timestamp: local.timestamp.isAfter(remote.timestamp) ? local.timestamp : remote.timestamp,
          type: remote.type,
          userTag: remote.userTag,
          upvotes: maxUpvotes,
          logicalCounter: maxCounter + 1,
          voterDeviceIds: mergedVoters,
          isTombstoned: false,
        );
      }
    }

    final result = mergeMap.values.where((e) => !e.isTombstoned && !_knownTombstones.contains(e.id)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return result;
  }

  /// 🌟 絕對真實水文：只回傳現場真實釣友回報，絕無虛假 AI 偽造通報
  List<UgcReportItem> getReportsForStation(String stationId, {double? waveHeight, double? windSpeed}) {
    return state.where((r) => r.stationId == stationId).toList();
  }

  Future<void> reportCondition(String stationId, UgcConditionType type) async {
    await _ensureInitialized();

    final premium = ref.read(premiumProvider);
    
    String customTag = "現場釣友";

    if (premium.isFounder) {
      customTag = "👑 創始天尊指揮官";
    } else if (premium.type == SubscriptionType.yearly) {
      customTag = "🔱 年度首席領航員";
    } else if (premium.isPremium) {
      customTag = "⭐ VIP 專業航海家";
    }

    final firestore = _firestore;
    final String distributedId = firestore?.collection('public_ugc_reports').doc().id 
        ?? "ugc_${DateTime.now().millisecondsSinceEpoch}";

    // 真實回報：每筆實名真實通報起步票數皆為 1，不灌虛假讚數
    final newItem = UgcReportItem(
      id: distributedId,
      stationId: stationId,
      timestamp: DateTime.now(),
      type: type,
      userTag: customTag,
      upvotes: 1,
      logicalCounter: 1,
      voterDeviceIds: {_deviceId},
      isTombstoned: false,
    );

    final updated = [newItem, ...state.where((r) => r.id != distributedId)];
    state = updated;
    await _saveToDisk(updated);

    if (firestore != null) {
      try {
        await firestore.collection('public_ugc_reports').doc(distributedId).set(newItem.toMap());
      } catch (_) {}
    }
  }

  Future<void> upvote(String reportId) async {
    await _ensureInitialized();

    final updated = state.map((item) {
      if (item.id == reportId) {
        if (item.voterDeviceIds.contains(_deviceId)) {
          return item;
        }
        return item.copyWithVote(voterDeviceId: _deviceId);
      }
      return item;
    }).toList();

    state = updated;
    await _saveToDisk(updated);

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('public_ugc_reports').doc(reportId).set({
          'upvotes': FieldValue.increment(1),
          'voterDeviceIds': FieldValue.arrayUnion([_deviceId]),
          'logicalCounter': FieldValue.increment(1),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> deleteReport(String reportId) async {
    await _ensureInitialized();

    _knownTombstones.add(reportId);
    if (_prefs != null) {
      await _prefs!.setStringList(_tombstonesKey, _knownTombstones.toList());
    }

    state = state.where((r) => r.id != reportId).toList();
    await _saveToDisk(state);

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('public_ugc_reports').doc(reportId).delete();
      } catch (_) {}
    }
  }

  Future<void> _saveToDisk(List<UgcReportItem> list) async {
    await _ensureInitialized();
    if (_prefs == null) return;
    try {
      final raw = list.map((e) => e.toJson()).toList();
      await _prefs!.setStringList(_storageKey, raw);
    } catch (_) {}
  }
}