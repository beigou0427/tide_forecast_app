import 'dart:convert';

enum UgcConditionType {
  waveLarger,       // 風浪比預報大
  waveCalm,         // 比預報更平穩
  rogueWaveAlert,   // 突發瘋狗浪/長湧
  currentFast,      // 走水急促/起大流
  fishBiting,       // 目標魚大咬中
  waterTurbid,      // 水質混濁
}

class UgcReportItem {
  final String id;
  final String stationId;
  final DateTime timestamp;
  final UgcConditionType type;
  final String userTag;
  final int upvotes;

  UgcReportItem({
    required this.id,
    required this.stationId,
    required this.timestamp,
    required this.type,
    this.userTag = "資深釣友",
    this.upvotes = 1,
  });

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stationId': stationId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'userTag': userTag,
      'upvotes': upvotes,
    };
  }

  factory UgcReportItem.fromMap(Map<String, dynamic> map) {
    return UgcReportItem(
      id: map['id'] ?? '',
      stationId: map['stationId'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      type: UgcConditionType.values[map['type'] ?? 0],
      userTag: map['userTag'] ?? "資深釣友",
      upvotes: map['upvotes'] ?? 1,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory UgcReportItem.fromJson(String source) => UgcReportItem.fromMap(jsonDecode(source));
}
