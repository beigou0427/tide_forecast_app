import 'dart:convert';

enum UgcConditionType {
  waveLarger,       // 風浪比預報大
  waveCalm,         // 比預報更平穩
  rogueWaveAlert,   // 突發瘋狗浪/長湧
  currentFast,      // 走水急促/起大流
  fishBiting,       // 目標魚大咬中
  waterTurbid,      // 水質混濁
}

/// 🌟 Martin Kleppmann (DDIA 作者) 分散式因果一致性海況情報實體 (CRDT-Aligned Entity)
/// 具備混合邏輯時鐘 (HLC)、點讚防衝突集合 (OR-Set) 與防死灰復燃墓碑 (Tombstone)
class UgcReportItem {
  final String id;
  final String stationId;
  final DateTime timestamp;
  final UgcConditionType type;
  final String userTag;
  final int upvotes;
  
  // 🌟 Martin Kleppmann 分散式防線：
  final int logicalCounter;          // 單調遞增因果計數器 (Lamport / HLC Counter)
  final Set<String> voterDeviceIds;  // 點讚設備集合 (OR-Set 語意，防分散式重複灌水)
  final bool isTombstoned;          // 刪除墓碑標記 (徹底杜絕弱網延遲封包造成殭屍復活)

  UgcReportItem({
    required this.id,
    required this.stationId,
    required this.timestamp,
    required this.type,
    this.userTag = "資深釣友",
    this.upvotes = 1,
    this.logicalCounter = 0,
    Set<String>? voterDeviceIds,
    this.isTombstoned = false,
  }) : voterDeviceIds = voterDeviceIds ?? {};

  String get label {
    switch (type) {
      case UgcConditionType.waveLarger: return "🌊 風浪比預報大";
      case UgcConditionType.waveCalm: return "⛵ 現場比預報平穩";
      case UgcConditionType.rogueWaveAlert: return "⚠️ 突發大湧/瘋狗浪";
      case UgcConditionType.currentFast: return "⚡ 走水急促起大流";
      case UgcConditionType.fishBiting: return "🐟 現場魚群大咬中";
      case UgcConditionType.waterTurbid: return "🌫️ 水質混濁翻底";
    }
  }

  /// 🌟 產生包含因果時間戳的下一版本實體 (狀態不可變轉移)
  UgcReportItem copyWithVote({required String voterDeviceId}) {
    final newVoters = Set<String>.from(voterDeviceIds)..add(voterDeviceId);
    return UgcReportItem(
      id: id,
      stationId: stationId,
      timestamp: timestamp,
      type: type,
      userTag: userTag,
      upvotes: newVoters.length > upvotes ? newVoters.length : upvotes + 1,
      logicalCounter: logicalCounter + 1,
      voterDeviceIds: newVoters,
      isTombstoned: isTombstoned,
    );
  }

  /// 產生墓碑化刪除實體
  UgcReportItem toTombstone() {
    return UgcReportItem(
      id: id,
      stationId: stationId,
      timestamp: DateTime.now(),
      type: type,
      userTag: userTag,
      upvotes: 0,
      logicalCounter: logicalCounter + 1,
      voterDeviceIds: {},
      isTombstoned: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stationId': stationId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'userTag': userTag,
      'upvotes': upvotes,
      'logicalCounter': logicalCounter,
      'voterDeviceIds': voterDeviceIds.toList(),
      'isTombstoned': isTombstoned,
    };
  }

  factory UgcReportItem.fromMap(Map<String, dynamic> map) {
    final rawVoters = map['voterDeviceIds'];
    final Set<String> parsedVoters = rawVoters is List 
        ? rawVoters.map((e) => e.toString()).toSet() 
        : {};

    final int rawUpvotes = (map['upvotes'] as num?)?.toInt() ?? 1;
    final int effectiveUpvotes = parsedVoters.isNotEmpty 
        ? (parsedVoters.length > rawUpvotes ? parsedVoters.length : rawUpvotes)
        : rawUpvotes;

    return UgcReportItem(
      id: map['id']?.toString() ?? '',
      stationId: map['stationId']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      type: UgcConditionType.values[((map['type'] as num?)?.toInt() ?? 0).clamp(0, UgcConditionType.values.length - 1)],
      userTag: map['userTag']?.toString() ?? "資深釣友",
      upvotes: effectiveUpvotes,
      logicalCounter: (map['logicalCounter'] as num?)?.toInt() ?? 0,
      voterDeviceIds: parsedVoters,
      isTombstoned: map['isTombstoned'] == true,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory UgcReportItem.fromJson(String source) => UgcReportItem.fromMap(jsonDecode(source));
}