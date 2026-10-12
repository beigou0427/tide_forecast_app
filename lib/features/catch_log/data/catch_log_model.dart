import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 🌟 Rob Pike (Unix / Go 哲學) 簡樸強固漁獲日誌實體 (Robust Immutable Data Model)
/// 100% 多型態自癒防禦版：
/// 1. 徹底消滅 Firestore Timestamp / 毫秒整數反序列化失敗導致歷史日期被洗牌為「今天」之死穴！
/// 2. 實裝 "null" 與空字串物理消毒，杜絕幽靈圖片路徑引發檔案拋錯。
/// 3. 潮高公尺智能歸一化，防止歷史公分數據 (185) 顯示為 185 米荒謬標籤。
@immutable
class CatchLogItem {
  final String id;
  final DateTime dateTime;
  final String stationName;
  final String species;
  final double? tideHeight;
  final double? waveHeight;
  final double? seaTemperature;
  final String notes;
  final int rating;
  final String? imagePath; // 本地沙盒相片路徑 (離線優先)
  final String? imageUrl;  // 雲端 Firebase Storage 相片網址

  const CatchLogItem({
    required this.id,
    required this.dateTime,
    required this.stationName,
    required this.species,
    this.tideHeight,
    this.waveHeight,
    this.seaTemperature,
    this.notes = "",
    this.rating = 5,
    this.imagePath,
    this.imageUrl,
  });

  CatchLogItem copyWith({
    String? id,
    DateTime? dateTime,
    String? stationName,
    String? species,
    double? tideHeight,
    double? waveHeight,
    double? seaTemperature,
    String? notes,
    int? rating,
    String? imagePath,
    String? imageUrl,
  }) {
    return CatchLogItem(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      stationName: stationName ?? this.stationName,
      species: species ?? this.species,
      tideHeight: tideHeight ?? this.tideHeight,
      waveHeight: waveHeight ?? this.waveHeight,
      seaTemperature: seaTemperature ?? this.seaTemperature,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'stationName': stationName,
      'species': species,
      'tideHeight': tideHeight,
      'waveHeight': waveHeight,
      'seaTemperature': seaTemperature,
      'notes': notes,
      'rating': rating,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
    };
  }

  /// 🌟 寬進嚴出型別自癒解析器：相容 Firestore Timestamp、整數毫秒、ISO 字串
  factory CatchLogItem.fromMap(Map<String, dynamic> map) {
    double? parseSafeDouble(dynamic val, {bool isTide = false}) {
      if (val == null) return null;
      double? parsed;
      if (val is num) {
        parsed = val.toDouble();
      } else if (val is String) {
        final clean = val.trim();
        parsed = double.tryParse(clean);
      }
      if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;

      // 潮高數值物理歸一化 (公分轉公尺)
      if (isTide && parsed.abs() >= 6.0) {
        return double.parse((parsed / 100.0).toStringAsFixed(2));
      }
      return double.parse(parsed.toStringAsFixed(2));
    }

    DateTime parseSafeDateTime(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is DateTime) return raw;

      // 🌟 核心防線：動態反射相容 Firestore Timestamp
      if (raw.runtimeType.toString() == 'Timestamp') {
        try {
          return (raw as dynamic).toDate() as DateTime;
        } catch (_) {}
      }

      // 相容整數或浮點毫秒數
      if (raw is num) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
        } catch (_) {}
      }

      if (raw is String) {
        final clean = raw.trim();
        final parsed = DateTime.tryParse(clean);
        if (parsed != null) return parsed;

        // 若為純數字字串 (毫秒時間戳)
        final intParsed = int.tryParse(clean);
        if (intParsed != null && intParsed > 100000000000) {
          try {
            return DateTime.fromMillisecondsSinceEpoch(intParsed);
          } catch (_) {}
        }
      }

      return DateTime.now();
    }

    String? sanitizePath(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty || str == 'null' || str == 'None') return null;
      return str;
    }

    final int rawRating = map['rating'] is num 
        ? (map['rating'] as num).toInt() 
        : (int.tryParse(map['rating']?.toString() ?? '5') ?? 5);

    return CatchLogItem(
      id: map['id']?.toString() ?? '',
      dateTime: parseSafeDateTime(map['dateTime']),
      stationName: map['stationName']?.toString() ?? '',
      species: map['species']?.toString() ?? '未知魚種',
      tideHeight: parseSafeDouble(map['tideHeight'], isTide: true),
      waveHeight: parseSafeDouble(map['waveHeight']),
      seaTemperature: parseSafeDouble(map['seaTemperature']),
      notes: map['notes']?.toString() ?? '',
      rating: rawRating.clamp(1, 5),
      imagePath: sanitizePath(map['imagePath']),
      imageUrl: sanitizePath(map['imageUrl']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CatchLogItem.fromJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return CatchLogItem.fromMap(decoded);
      }
      if (decoded is Map) {
        return CatchLogItem.fromMap(Map<String, dynamic>.from(decoded));
      }
      return CatchLogItem(
        id: 'corrupted',
        dateTime: DateTime.now(),
        stationName: '',
        species: '損壞資料',
      );
    } catch (_) {
      return CatchLogItem(
        id: 'corrupted',
        dateTime: DateTime.now(),
        stationName: '',
        species: '損壞資料',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatchLogItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dateTime == other.dateTime &&
          stationName == other.stationName &&
          species == other.species &&
          tideHeight == other.tideHeight &&
          waveHeight == other.waveHeight &&
          seaTemperature == other.seaTemperature &&
          notes == other.notes &&
          rating == other.rating &&
          imagePath == other.imagePath &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => Object.hash(
        id,
        dateTime,
        stationName,
        species,
        tideHeight,
        waveHeight,
        seaTemperature,
        notes,
        rating,
        imagePath,
        imageUrl,
      );
}
