class TideStationData {
  final StationInfo info;
  final List<Observation> observations;
  final List<TideForecast> forecasts;
  final AIExpertBriefing? aiBriefing;

  TideStationData({
    required this.info, 
    required this.observations, 
    this.forecasts = const [], 
    this.aiBriefing
  });

  factory TideStationData.fromEdgeJson(Map<String, dynamic> json) {
    final obsNode = (json['obs'] is Map) ? json['obs'] as Map<String, dynamic> : {};
    final stationInfoNode = (json['station_info'] is Map) ? json['station_info'] as Map<String, dynamic> : {};

    final Map<String, dynamic> mergedInfo = Map<String, dynamic>.from(obsNode['info'] ?? obsNode);
    if (stationInfoNode.isNotEmpty) {
      mergedInfo['StationName'] = stationInfoNode['friendly_name'] ?? mergedInfo['StationName'];
      mergedInfo['lat'] = stationInfoNode['lat'] ?? mergedInfo['lat'];
      mergedInfo['lng'] = stationInfoNode['lng'] ?? mergedInfo['lng'];
      mergedInfo['attr'] = stationInfoNode['station_type'] ?? mergedInfo['attr'];
      mergedInfo['CountyName'] = stationInfoNode['region'] ?? mergedInfo['CountyName'];
    }

    List obsRaw = [];
    if (obsNode['StationObsTimes'] is Map) {
      obsRaw = obsNode['StationObsTimes']['StationObsTime'] as List? ?? [];
    } else if (obsNode['StationObsTimes'] is List) {
      obsRaw = obsNode['StationObsTimes'];
    } else if (obsNode['Observation'] is List) {
      obsRaw = obsNode['Observation'];
    }

    final List forecastRaw = json['forecasts'] as List? ?? obsNode['forecasts'] as List? ?? [];

    return TideStationData(
      info: StationInfo.fromMap(mergedInfo),
      observations: obsRaw.map((i) => Observation.fromProxy(i as Map<String, dynamic>)).toList(),
      forecasts: forecastRaw.map((f) => TideForecast.fromOfficial(f as Map<String, dynamic>)).toList(), 
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
    final rawScore = map['safety_score'];
    int parsedScore = 80;
    if (rawScore is num) {
      parsedScore = rawScore.toInt().clamp(0, 100);
    } else if (rawScore != null) {
      parsedScore = (int.tryParse(rawScore.toString()) ?? 80).clamp(0, 100);
    }

    return AIExpertBriefing(
      briefing: map['briefing']?.toString() ?? "海象平穩，注意防曬與補水。",
      safetyScore: parsedScore,
      activities: List<String>.from(map['activities'] ?? []),
    );
  }
}

class StationInfo {
  final String stationName, countyName, townName, lat, lng, attr, addressDescription;
  
  StationInfo({
    required this.stationName, 
    required this.countyName, 
    required this.townName, 
    required this.lat, 
    required this.lng, 
    required this.attr, 
    required this.addressDescription
  });
  
  factory StationInfo.fromMap(Map<String, dynamic> json) {
    final rawLat = json['lat'] ?? json['Latitude'] ?? json['GeoLocation']?['Latitude'];
    final rawLng = json['lng'] ?? json['Longitude'] ?? json['GeoLocation']?['Longitude'];

    // 核心地理防線：防止 0.0 幾內亞灣 Null Island 造成萬里漂移
    final double? parsedLatNum = double.tryParse(rawLat?.toString() ?? '');
    final double? parsedLngNum = double.tryParse(rawLng?.toString() ?? '');

    final bool isLatValid = parsedLatNum != null && parsedLatNum >= 20.0 && parsedLatNum <= 27.5;
    final bool isLngValid = parsedLngNum != null && parsedLngNum >= 116.0 && parsedLngNum <= 124.0;

    final String finalLat = isLatValid ? parsedLatNum.toString() : '25.037';
    final String finalLng = isLngValid ? parsedLngNum.toString() : '121.926';

    return StationInfo(
      stationName: json['friendly_name'] ?? json['StationName'] ?? json['Station']?['StationID'] ?? '未知測站',
      countyName: json['CountyName'] ?? '',
      townName: json['TownName'] ?? '',
      lat: finalLat,
      lng: finalLng,
      attr: json['station_type'] ?? json['attr'] ?? json['StationAttribute'] ?? '一般測站',
      addressDescription: json['address-description'] ?? '',
    );
  }
}

class Observation {
  final DateTime dateTime;
  final double? tideHeight, waveHeight, windSpeed, wavePeriod, seaTemperature, currentSpeed, windDirection, airTemperature, airPressure;
  final String? tideLevel;

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
    final anemometer = e['PrimaryAnemometer'] ?? {};

    return Observation(
      dateTime: DateTime.parse(json['DateTime'] ?? json['DataTime'] ?? DateTime.now().toIso8601String()),
      tideHeight: _n(e['TideHeight'] ?? tide['TideHeight']),
      tideLevel: (e['TideLevel'] ?? tide['TideLevel'])?.toString(),
      waveHeight: _n(e['WaveHeight'] ?? wave['WaveHeight']),
      windSpeed: _n(e['WindSpeed'] ?? json['WindSpeed'] ?? anemometer['WindSpeed']),
      wavePeriod: _n(e['WavePeriod'] ?? wave['WavePeriod']),
      seaTemperature: _n(e['SeaTemperature'] ?? json['SeaTemperature']),
      currentSpeed: _n(e['CurrentSpeed'] ?? json['CurrentSpeed']),
      windDirection: _n(e['WindDirection'] ?? json['WindDirection'] ?? anemometer['WindDirection']),
      airTemperature: _n(e['AirTemperature'] ?? e['Temperature']),
      airPressure: _n(e['AirPressure'] ?? e['StationPressure']),
    );
  }

  static double? _n(dynamic v) {
    if (v == null) return null;
    String s = v.toString().trim();
    if (s.isEmpty || 
        s == "None" || 
        s == "nan" || 
        s == "null" || 
        s == "Infinity" ||
        s.startsWith("-99") ||
        s.startsWith("-999")) {
      return null;
    }
    
    final cleaned = s.replaceAll(RegExp(r'[^0-9.-]'), '');
    if (cleaned.isEmpty || cleaned == '-' || cleaned == '.') return null;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed <= -90.0) return null;
    return parsed;
  }
}

class TideForecast {
  final DateTime dateTime;
  final String tideType, tideHeight;
  TideForecast({required this.dateTime, required this.tideType, required this.tideHeight});
  
  factory TideForecast.fromOfficial(Map<String, dynamic> json) {
    final heights = json['TideHeights'] ?? {};
    return TideForecast(
      dateTime: DateTime.parse(json['DateTime'] ?? json['dateTime'] ?? DateTime.now().toIso8601String()),
      tideType: json['Tide']?.toString() ?? json['tideType']?.toString() ?? '',
      tideHeight: (heights['AboveLocalMSL'] ?? heights['AboveTWVD'] ?? json['tideHeight'] ?? '--').toString(),
    );
  }
}
