import 'dart:convert';

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
  final String? imageUrl;  // 🌟 雲端 Firebase Storage 相片網址

  CatchLogItem({
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
      'imageUrl': imageUrl, // 🌟 寫入雲端網址快取
    };
  }

  factory CatchLogItem.fromMap(Map<String, dynamic> map) {
    return CatchLogItem(
      id: map['id'] ?? '',
      dateTime: DateTime.parse(map['dateTime'] ?? DateTime.now().toIso8601String()),
      stationName: map['stationName'] ?? '',
      species: map['species'] ?? '',
      tideHeight: map['tideHeight']?.toDouble(),
      waveHeight: map['waveHeight']?.toDouble(),
      seaTemperature: map['seaTemperature']?.toDouble(),
      notes: map['notes'] ?? '',
      rating: map['rating']?.toInt() ?? 5,
      imagePath: map['imagePath'],
      imageUrl: map['imageUrl'], // 🌟 讀取雲端網址快取
    );
  }

  String toJson() => jsonEncode(toMap());
  factory CatchLogItem.fromJson(String source) => CatchLogItem.fromMap(jsonDecode(source));
}