import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 🌟 Rob Pike (Unix / Go 哲學) 簡樸強固漁獲日誌實體 (Robust Immutable Data Model)
/// 具備畸形輸入自癒 (Fail-Safe Deserialization)、防崩潰時間解析與不可變性
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

  /// 🌟 寬進嚴出型別自癒解析器 (徹底消滅 String/Num 型別衝突與時間格式崩潰)
  factory CatchLogItem.fromMap(Map<String, dynamic> map) {
    double? parseSafeDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) {
        final parsed = double.tryParse(val.trim());
        if (parsed != null && !parsed.isNaN && !parsed.isInfinite) return parsed;
      }
      return null;
    }

    final rawDate = map['dateTime']?.toString();
    final DateTime safeDate = (rawDate != null ? DateTime.tryParse(rawDate) : null) ?? DateTime.now();

    final int rawRating = map['rating'] is num 
        ? (map['rating'] as num).toInt() 
        : (int.tryParse(map['rating']?.toString() ?? '5') ?? 5);

    return CatchLogItem(
      id: map['id']?.toString() ?? '',
      dateTime: safeDate,
      stationName: map['stationName']?.toString() ?? '',
      species: map['species']?.toString() ?? '未知魚種',
      tideHeight: parseSafeDouble(map['tideHeight']),
      waveHeight: parseSafeDouble(map['waveHeight']),
      seaTemperature: parseSafeDouble(map['seaTemperature']),
      notes: map['notes']?.toString() ?? '',
      rating: rawRating.clamp(1, 5),
      imagePath: map['imagePath']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
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