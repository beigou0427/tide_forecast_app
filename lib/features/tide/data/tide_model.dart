import 'dart:convert';

class TideStationData {
  final StationInfo info;
  final List<Observation> observations;
  final List<TideForecast> forecasts; // 🌟 補回預報清單
  final AIExpertBriefing? aiBriefing;

  TideStationData({
    required this.info, 
    required this.observations, 
    this.forecasts = const [], 
    this.aiBriefing
  });

  factory TideStationData.fromEdgeJson(Map<String, dynamic> json) {
    final obsRaw = json['obs']?['StationObsTimes'] as List? ?? json['obs']?['Observation'] as List? ?? [];
    return TideStationData(
      info: StationInfo.fromMap(json['obs']?['info'] ?? json['obs'] ?? {}),
      observations: obsRaw.map((i) => Observation.fromProxy(i)).toList(),
      forecasts: [], // 預報數據目前由後端整合處理
      aiBriefing: json['ai_expert'] != null ? AIExpertBriefing.fromMap(json['ai_expert']) : null,
    );
  }
}

class AIExpertBriefing {
  final String briefing;
  final int safetyScore;
  final List<String> activities;
  AIExpertBriefing({required this.briefing, required this.safetyScore, required this.activities});
  factory AIExpertBriefing.fromMap(Map<String, dynamic> map) {
    return AIExpertBriefing(
      briefing: map['briefing'] ?? "海象平穩，注意安全。",
      safetyScore: map['safety_score'] ?? 80,
      activities: List<String>.from(map['activities'] ?? []),
    );
  }
}

class StationInfo {
  final String stationName, countyName, townName, lat, lng, attr, addressDescription;
  StationInfo({required this.stationName, required this.countyName, required this.townName, required this.lat, required this.lng, required this.attr, required this.addressDescription});
  factory StationInfo.fromMap(Map<String, dynamic> json) {
    final String parsedLat = (json['lat'] ?? json['GeoLocation']?['Latitude'] ?? '0').toString();
    final String parsedLng = (json['lng'] ?? json['GeoLocation']?['Longitude'] ?? '0').toString();
    return StationInfo(
      stationName: json['StationName'] ?? json['Station']?['StationID'] ?? '未知測站',
      countyName: json['CountyName'] ?? '',
      townName: json['TownName'] ?? '',
      lat: parsedLat, lng: parsedLng,
      attr: json['attr'] ?? json['StationAttribute'] ?? '一般站',
      addressDescription: json['address-description'] ?? '',
    );
  }
}

class Observation {
  final DateTime dateTime;
  final double? tideHeight, waveHeight, windSpeed;
  final String? tideLevel;
  
  // 🌟 補回 UI 依賴的所有進階觀測欄位
  final double? wavePeriod;
  final double? seaTemperature;
  final double? currentSpeed;
  final double? windDirection;
  final double? airTemperature;
  final double? airPressure;

  Observation({
    required this.dateTime, 
    this.tideHeight, 
    this.tideLevel, 
    this.waveHeight, 
    this.windSpeed,
    this.wavePeriod,
    this.seaTemperature,
    this.currentSpeed,
    this.windDirection,
    this.airTemperature,
    this.airPressure,
  });

  factory Observation.fromProxy(Map<String, dynamic> json) {
    final e = json['WeatherElements'] ?? json['WeatherElement'] ?? json['Weather'] ?? {};
    final tide = json['Tide'] ?? {};
    final wave = json['Wave'] ?? {};

    return Observation(
      dateTime: DateTime.parse(json['DateTime'] ?? json['DataTime'] ?? DateTime.now().toIso8601String()),
      tideHeight: _n(e['TideHeight'] ?? tide['TideHeight']),
      tideLevel: (e['TideLevel'] ?? tide['TideLevel'])?.toString(),
      waveHeight: _n(e['WaveHeight'] ?? wave['WaveHeight']),
      windSpeed: _n(e['WindSpeed'] ?? json['WindSpeed']),
      // 解析補回欄位
      wavePeriod: _n(e['WavePeriod'] ?? wave['WavePeriod']),
      seaTemperature: _n(e['SeaTemperature'] ?? json['SeaTemperature']),
      currentSpeed: _n(e['CurrentSpeed'] ?? json['CurrentSpeed']),
      windDirection: _n(e['WindDirection'] ?? json['WindDirection']),
      airTemperature: _n(e['AirTemperature'] ?? e['Temperature']),
      airPressure: _n(e['AirPressure'] ?? e['StationPressure']),
    );
  }

  static double? _n(dynamic v) {
    if (v == null) return null;
    String s = v.toString().trim();
    if (s == "None" || s == "-99" || s == "" || s == "nan" || s == "null") return null;
    return double.tryParse(s.replaceAll(RegExp(r'[^0-9.-]'), ''));
  }
}

class TideForecast {
  final DateTime dateTime;
  final String tideType, tideHeight;
  TideForecast({required this.dateTime, required this.tideType, required this.tideHeight});
  factory TideForecast.fromOfficial(Map<String, dynamic> json) {
    final heights = json['TideHeights'] ?? {};
    return TideForecast(
      dateTime: DateTime.parse(json['DateTime']),
      tideType: json['Tide']?.toString() ?? '',
      tideHeight: (heights['AboveLocalMSL'] ?? heights['AboveTWVD'] ?? '--').toString(),
    );
  }
}
