/// 🌟 Philip Crosby (克勞斯比) 零缺陷 (Zero Defects) 權威海事水文領域模型
/// 嚴格遵循「第一次就做對」原則，在輸入邊界徹底消滅任何物理不可行髒數據穿透
class TideStationData {
  final int schemaVersion;
  final StationInfo info;
  final List<Observation> observations;
  final List<TideForecast> forecasts;
  final AIExpertBriefing? aiBriefing;

  TideStationData({
    this.schemaVersion = 2,
    required this.info, 
    required this.observations, 
    this.forecasts = const [], 
    this.aiBriefing
  });

  factory TideStationData.fromEdgeJson(Map<String, dynamic> json) {
    final int version = json['schema_version'] as int? ?? (json['version'] as int? ?? 1);

    final obsNode = (json['obs'] is Map) ? json['obs'] as Map<String, dynamic> : {};
    final stationInfoNode = (json['station_info'] is Map) ? json['station_info'] as Map<String, dynamic> : {};

    final Map<String, dynamic> mergedInfo = Map<String, dynamic>.from(obsNode['info'] ?? obsNode);
    if (stationInfoNode.isNotEmpty) {
      mergedInfo['StationName'] = stationInfoNode['friendly_name'] ?? stationInfoNode['name'] ?? mergedInfo['StationName'];
      mergedInfo['lat'] = stationInfoNode['lat'] ?? mergedInfo['lat'];
      mergedInfo['lng'] = stationInfoNode['lng'] ?? mergedInfo['lng'];
      mergedInfo['attr'] = stationInfoNode['station_type'] ?? stationInfoNode['attr'] ?? mergedInfo['attr'];
      mergedInfo['CountyName'] = stationInfoNode['region'] ?? mergedInfo['CountyName'];
    }

    List obsRaw = [];
    if (obsNode['StationObsTimes'] is Map) {
      obsRaw = obsNode['StationObsTimes']['StationObsTime'] as List? ?? [];
    } else if (obsNode['StationObsTimes'] is List) {
      obsRaw = obsNode['StationObsTimes'];
    } else if (obsNode['Observation'] is List) {
      obsRaw = obsNode['Observation'];
    } else if (json['observations'] is List) {
      obsRaw = json['observations'] as List;
    }

    final List forecastRaw = json['forecasts'] as List? ?? obsNode['forecasts'] as List? ?? [];

    return TideStationData(
      schemaVersion: version,
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
  final double? waveEnergyFlux;
  final List<String> activities;

  AIExpertBriefing({
    required this.briefing, 
    required this.safetyScore, 
    this.waveEnergyFlux,
    required this.activities
  });

  factory AIExpertBriefing.fromMap(Map<String, dynamic> map) {
    final rawScore = map['safety_score'] ?? map['safetyScore'] ?? map['hazard_index'];
    // 🌟 克勞斯比零缺陷安全預設：解析失敗時預設 30 分戒備，嚴禁給出盲目樂觀的高分
    int parsedScore = 30;
    if (rawScore is num) {
      parsedScore = rawScore.toInt().clamp(0, 100);
    } else if (rawScore != null) {
      parsedScore = (int.tryParse(rawScore.toString()) ?? 30).clamp(0, 100);
    }

    final rawFlux = map['wave_energy_flux'] ?? map['waveEnergyFlux'] ?? map['energy_flux'];
    double? parsedFlux;
    if (rawFlux is num) {
      parsedFlux = rawFlux.toDouble();
    } else if (rawFlux != null) {
      parsedFlux = double.tryParse(rawFlux.toString());
    }

    return AIExpertBriefing(
      briefing: (map['briefing'] ?? map['advice'] ?? "海象數據解析中，外礁作業請維持警戒防護。").toString(),
      safetyScore: parsedScore,
      waveEnergyFlux: parsedFlux,
      activities: List<String>.from(map['activities'] ?? map['suggested_activities'] ?? []),
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

    final double? parsedLatNum = double.tryParse(rawLat?.toString() ?? '');
    final double? parsedLngNum = double.tryParse(rawLng?.toString() ?? '');

    // 台灣海域地理包圍盒邊界約束 (含東沙與各離島 20.0°~27.5°N, 116.0°~124.0°E)
    final bool isLatValid = parsedLatNum != null && parsedLatNum >= 20.0 && parsedLatNum <= 27.5;
    final bool isLngValid = parsedLngNum != null && parsedLngNum >= 116.0 && parsedLngNum <= 124.0;

    final String finalLat = isLatValid ? parsedLatNum.toString() : '25.037';
    final String finalLng = isLngValid ? parsedLngNum.toString() : '121.926';

    return StationInfo(
      stationName: json['friendly_name'] ?? json['name'] ?? json['StationName'] ?? json['Station']?['StationID'] ?? '海象測站',
      countyName: json['CountyName'] ?? json['county'] ?? '',
      townName: json['TownName'] ?? json['town'] ?? '',
      lat: finalLat,
      lng: finalLng,
      attr: json['station_type'] ?? json['attr'] ?? json['StationAttribute'] ?? '一般測站',
      addressDescription: json['address-description'] ?? '',
    );
  }
}

class Observation {
  final DateTime dateTime;
  final double? tideHeight, waveHeight, windSpeed, wavePeriod, waveEnergyFlux, seaTemperature, currentSpeed, windDirection, airTemperature, airPressure;
  final String? tideLevel;

  Observation({
    required this.dateTime, 
    this.tideHeight, 
    this.tideLevel, 
    this.waveHeight, 
    this.windSpeed,
    this.wavePeriod, 
    this.waveEnergyFlux, 
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

    final parsedWaveH = _sanitizeWave(json['wave_height'] ?? e['WaveHeight'] ?? wave['WaveHeight']);
    final parsedWaveP = _sanitizePeriod(json['wave_period'] ?? e['WavePeriod'] ?? wave['WavePeriod']);
    final parsedTideH = _sanitizeTide(json['tide_height'] ?? e['TideHeight'] ?? tide['TideHeight']);
    final parsedWindS = _sanitizeWind(json['wind_speed'] ?? e['WindSpeed'] ?? json['WindSpeed'] ?? anemometer['WindSpeed']);
    final parsedWindDir = _sanitizeWindDirection(json['wind_direction'] ?? e['WindDirection'] ?? json['WindDirection'] ?? anemometer['WindDirection']);
    final parsedPressure = _sanitizePressure(json['air_pressure'] ?? e['AirPressure'] ?? e['StationPressure']);
    final parsedSeaTemp = _sanitizeSeaTemp(json['sea_temp'] ?? e['SeaTemperature'] ?? json['SeaTemperature']);

    double? flux = _n(json['wave_energy_flux'] ?? json['energy_flux'] ?? wave['WaveEnergyFlux'] ?? e['WaveEnergyFlux']);
    if (flux == null && parsedWaveH != null && parsedWaveP != null) {
      flux = double.parse((0.49 * (parsedWaveH * parsedWaveH) * parsedWaveP).toStringAsFixed(2));
    }

    return Observation(
      dateTime: DateTime.parse(json['DateTime'] ?? json['DataTime'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
      tideHeight: parsedTideH,
      tideLevel: (json['tide_level'] ?? e['TideLevel'] ?? tide['TideLevel'])?.toString(),
      waveHeight: parsedWaveH,
      windSpeed: parsedWindS,
      wavePeriod: parsedWaveP,
      waveEnergyFlux: flux,
      seaTemperature: parsedSeaTemp,
      currentSpeed: _n(json['current_speed'] ?? e['CurrentSpeed'] ?? json['CurrentSpeed']),
      windDirection: parsedWindDir,
      airTemperature: _n(json['air_temp'] ?? e['AirTemperature'] ?? e['Temperature']),
      airPressure: parsedPressure,
    );
  }

  // 🌟 克勞斯比零缺陷物理規格化清洗器：

  // 浪高：開闊海面無 0.0m（感測器卡死）；浪高大於 25m 為噪訊
  static double? _sanitizeWave(dynamic v) {
    final val = _n(v);
    if (val == null || val <= 0.05 || val > 25.0) return null;
    return val;
  }

  // 週期：小於 1.0s 為電磁噪訊；大於 30s 為非真實波浪
  static double? _sanitizePeriod(dynamic v) {
    final val = _n(v);
    if (val == null || val < 1.0 || val > 30.0) return null;
    return val;
  }

  // 風速：負風速為噪訊；大於 75m/s（17級以上颶風超限）為異常感測
  static double? _sanitizeWind(dynamic v) {
    final val = _n(v);
    if (val == null || val < 0.0 || val > 75.0) return null;
    return val;
  }

  // 風向：嚴格限制於 [0.0, 360.0]，消滅 720° 等髒資料
  static double? _sanitizeWindDirection(dynamic v) {
    final val = _n(v);
    if (val == null || val < 0.0 || val > 360.0) return null;
    return val;
  }

  // 氣壓：地球海平面極限氣壓範圍 [870.0, 1085.0] hPa，消滅 500hPa 穿透
  static double? _sanitizePressure(dynamic v) {
    final val = _n(v);
    if (val == null || val < 870.0 || val > 1085.0) return null;
    return val;
  }

  // 海水表溫：台灣周遭海水合理表溫 [10.0, 38.0] ℃
  static double? _sanitizeSeaTemp(dynamic v) {
    final val = _n(v);
    if (val == null || val < 10.0 || val > 38.0) return null;
    return val;
  }

  // 潮位：大潮乾潮底負水深合法 (-3.0m ~ +6.0m)，其餘過濾
  static double? _sanitizeTide(dynamic v) {
    return _n(v, isTideMeasurement: true);
  }

  static double? _n(dynamic v, {bool isTideMeasurement = false}) {
    if (v == null) return null;
    String s = v.toString().trim();
    if (s.isEmpty || 
        s == "None" || 
        s == "nan" || 
        s == "null" || 
        s == "Infinity" ||
        s == "-Infinity") {
      return null;
    }
    
    // 氣象署標準故障與離線代碼
    if (s == "-99" || s == "-99.0" || s == "-999" || s == "-999.0" || s == "-9999") {
      return null;
    }

    final cleaned = s.replaceAll(RegExp(r'[^0-9.-]'), '');
    if (cleaned.isEmpty || cleaned == '-' || cleaned == '.') return null;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;

    if (!isTideMeasurement && parsed <= -90.0) return null;
    if (isTideMeasurement && (parsed == -99.0 || parsed == -999.0 || parsed < -300.0 || parsed > 600.0)) {
      return null;
    }

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
      dateTime: DateTime.parse(json['DateTime'] ?? json['dateTime'] ?? json['time'] ?? DateTime.now().toIso8601String()),
      tideType: json['Tide']?.toString() ?? json['tideType']?.toString() ?? '',
      tideHeight: (heights['AboveLocalMSL'] ?? heights['AboveTWVD'] ?? json['tideHeight'] ?? json['height'] ?? '--').toString(),
    );
  }
}

class PrivateSpotModel {
  final String id;
  final String name;
  final String stationId;
  final double lat;
  final double lng;
  final String targetSpecies;
  final String tackleNotes;
  final DateTime createdAt;

  const PrivateSpotModel({
    required this.id,
    required this.name,
    required this.stationId,
    required this.lat,
    required this.lng,
    this.targetSpecies = "",
    this.tackleNotes = "",
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'stationId': stationId,
    'lat': lat,
    'lng': lng,
    'targetSpecies': targetSpecies,
    'tackleNotes': tackleNotes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PrivateSpotModel.fromMap(Map<String, dynamic> map) => PrivateSpotModel(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '私房標點',
    stationId: map['stationId']?.toString() ?? '',
    lat: (map['lat'] as num?)?.toDouble() ?? 25.037,
    lng: (map['lng'] as num?)?.toDouble() ?? 121.926,
    targetSpecies: map['targetSpecies']?.toString() ?? '',
    tackleNotes: map['tackleNotes']?.toString() ?? '',
    createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}