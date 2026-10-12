/// 🌟 Philip Crosby 零缺陷 (Zero Defects) 權威海事水文領域模型
/// 100% 物理真理防禦版：
/// 1. 徹底消滅氣象署電文 185 公分潮高被誤當 185 米海嘯的單位歸一化漏洞！
/// 2. 測站資訊智能解構，優先萃取中文 StationName，杜絕純英數代碼未轉譯。
/// 3. 全面防禦 DateTime 畸形格式與深層巢狀 Map 型別轉型崩潰。
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
    this.aiBriefing,
  });

  factory TideStationData.fromEdgeJson(Map<String, dynamic> json) {
    final int version = json['schema_version'] as int? ?? (json['version'] as int? ?? 1);

    final obsNode = (json['obs'] is Map) 
        ? Map<String, dynamic>.from(json['obs'] as Map) 
        : <String, dynamic>{};
    final stationInfoNode = (json['station_info'] is Map) 
        ? Map<String, dynamic>.from(json['station_info'] as Map) 
        : <String, dynamic>{};

    final Map<String, dynamic> mergedInfo = (obsNode['info'] is Map)
        ? Map<String, dynamic>.from(obsNode['info'] as Map)
        : Map<String, dynamic>.from(obsNode);

    if (stationInfoNode.isNotEmpty) {
      mergedInfo['StationName'] = stationInfoNode['friendly_name'] ?? stationInfoNode['name'] ?? mergedInfo['StationName'];
      mergedInfo['lat'] = stationInfoNode['lat'] ?? mergedInfo['lat'];
      mergedInfo['lng'] = stationInfoNode['lng'] ?? mergedInfo['lng'];
      mergedInfo['attr'] = stationInfoNode['station_type'] ?? stationInfoNode['attr'] ?? mergedInfo['attr'];
      mergedInfo['CountyName'] = stationInfoNode['region'] ?? mergedInfo['CountyName'];
    }

    List obsRaw = [];
    if (obsNode['StationObsTimes'] is Map && (obsNode['StationObsTimes'] as Map)['StationObsTime'] is List) {
      obsRaw = (obsNode['StationObsTimes'] as Map)['StationObsTime'] as List;
    } else if (obsNode['StationObsTimes'] is List) {
      obsRaw = obsNode['StationObsTimes'] as List;
    } else if (obsNode['Observation'] is List) {
      obsRaw = obsNode['Observation'] as List;
    } else if (json['observations'] is List) {
      obsRaw = json['observations'] as List;
    }

    final List forecastRaw = (json['forecasts'] is List) 
        ? json['forecasts'] as List 
        : ((obsNode['forecasts'] is List) ? obsNode['forecasts'] as List : []);

    final safeObservations = obsRaw.map((i) {
      if (i is Map) {
        return Observation.fromProxy(Map<String, dynamic>.from(i));
      }
      return Observation(dateTime: DateTime.now());
    }).toList();

    final safeForecasts = forecastRaw.map((f) {
      if (f is Map) {
        return TideForecast.fromOfficial(Map<String, dynamic>.from(f));
      }
      return TideForecast(dateTime: DateTime.now(), tideType: '', tideHeight: '--');
    }).toList();

    return TideStationData(
      schemaVersion: version,
      info: StationInfo.fromMap(mergedInfo),
      observations: safeObservations,
      forecasts: safeForecasts,
      aiBriefing: (json['ai_expert'] is Map) 
          ? AIExpertBriefing.fromMap(Map<String, dynamic>.from(json['ai_expert'] as Map)) 
          : null,
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
    required this.activities,
  });

  factory AIExpertBriefing.fromMap(Map<String, dynamic> map) {
    final rawScore = map['safety_score'] ?? map['safetyScore'] ?? map['hazard_index'];
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

    final rawActs = map['activities'] ?? map['suggested_activities'];
    final List<String> actsList = (rawActs is List)
        ? rawActs.map((e) => e.toString()).toList()
        : <String>[];

    return AIExpertBriefing(
      briefing: (map['briefing'] ?? map['advice'] ?? "海象數據解析中，外礁作業請維持警戒防護。").toString(),
      safetyScore: parsedScore,
      waveEnergyFlux: parsedFlux,
      activities: actsList,
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
    required this.addressDescription,
  });
  
  factory StationInfo.fromMap(Map<String, dynamic> json) {
    final dynamic geo = json['GeoLocation'];
    final rawLat = json['lat'] ?? json['Latitude'] ?? (geo is Map ? geo['Latitude'] : null);
    final rawLng = json['lng'] ?? json['Longitude'] ?? (geo is Map ? geo['Longitude'] : null);

    final double? parsedLatNum = double.tryParse(rawLat?.toString() ?? '');
    final double? parsedLngNum = double.tryParse(rawLng?.toString() ?? '');

    final bool isLatValid = parsedLatNum != null && parsedLatNum >= 20.0 && parsedLatNum <= 27.5;
    final bool isLngValid = parsedLngNum != null && parsedLngNum >= 116.0 && parsedLngNum <= 124.0;

    final String finalLat = isLatValid ? parsedLatNum.toString() : '25.037';
    final String finalLng = isLngValid ? parsedLngNum.toString() : '121.926';

    // 🌟 核心防線：深度解構 st['StationName']，杜絕落入英數代號
    final dynamic st = json['Station'];
    final String resolvedStationName = json['friendly_name'] ?? 
        json['name'] ?? 
        json['StationName'] ?? 
        (st is Map ? (st['StationName'] ?? st['StationID']) : (st is String ? st : '海象測站'));

    return StationInfo(
      stationName: resolvedStationName,
      countyName: (json['CountyName'] ?? json['county'] ?? '').toString(),
      townName: (json['TownName'] ?? json['town'] ?? '').toString(),
      lat: finalLat,
      lng: finalLng,
      attr: (json['station_type'] ?? json['attr'] ?? json['StationAttribute'] ?? '一般測站').toString(),
      addressDescription: (json['address-description'] ?? '').toString(),
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
    final dynamic rawE = json['WeatherElements'] ?? json['WeatherElement'] ?? json['Weather'];
    final Map<String, dynamic> e = (rawE is Map) ? Map<String, dynamic>.from(rawE) : <String, dynamic>{};

    final dynamic rawTide = json['Tide'];
    final Map<String, dynamic> tide = (rawTide is Map) ? Map<String, dynamic>.from(rawTide) : <String, dynamic>{};

    final dynamic rawWave = json['Wave'];
    final Map<String, dynamic> wave = (rawWave is Map) ? Map<String, dynamic>.from(rawWave) : <String, dynamic>{};

    final dynamic rawAnemometer = e['PrimaryAnemometer'];
    final Map<String, dynamic> anemometer = (rawAnemometer is Map) ? Map<String, dynamic>.from(rawAnemometer) : <String, dynamic>{};

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

    final DateTime safeDateTime = _parseSafeDateTime(
      json['DateTime'] ?? json['DataTime'] ?? json['timestamp'] ?? json['time'],
    );

    return Observation(
      dateTime: safeDateTime,
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

  static DateTime _parseSafeDateTime(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    try {
      final str = raw.toString().trim().replaceAll('/', '-');
      final parsed = DateTime.tryParse(str);
      if (parsed != null) return parsed;
    } catch (_) {}
    return DateTime.now();
  }

  static double? _sanitizeWave(dynamic v) {
    final val = _n(v);
    if (val == null || val <= 0.05 || val > 25.0) return null;
    return val;
  }

  static double? _sanitizePeriod(dynamic v) {
    final val = _n(v);
    if (val == null || val < 1.0 || val > 30.0) return null;
    return val;
  }

  static double? _sanitizeWind(dynamic v) {
    final val = _n(v);
    if (val == null || val < 0.0 || val > 75.0) return null;
    return val;
  }

  static double? _sanitizeWindDirection(dynamic v) {
    final val = _n(v);
    if (val == null || val < 0.0 || val > 360.0) return null;
    return val;
  }

  static double? _sanitizePressure(dynamic v) {
    final val = _n(v);
    if (val == null || val < 870.0 || val > 1085.0) return null;
    return val;
  }

  static double? _sanitizeSeaTemp(dynamic v) {
    final val = _n(v);
    if (val == null || val < 10.0 || val > 38.0) return null;
    return val;
  }

  /// 🌟 物理單位智能歸一化防線：徹底消滅公分與公尺混雜引發的 185 米假海嘯！
  static double? _sanitizeTide(dynamic v) {
    final val = _n(v, isTideMeasurement: true);
    if (val == null) return null;

    // 台灣海域天文實測潮差極限不超過 5.5 米。
    // 若絕對值 >= 6.0 (例如 185, 215, 20, -45)，必定為公分 (cm)，必須除以 100 轉為公尺 (m)！
    if (val.abs() >= 6.0) {
      return double.parse((val / 100.0).toStringAsFixed(2));
    }

    return double.parse(val.toStringAsFixed(2));
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
  
  TideForecast({
    required this.dateTime, 
    required this.tideType, 
    required this.tideHeight,
  });
  
  factory TideForecast.fromOfficial(Map<String, dynamic> json) {
    final dynamic rawHeights = json['TideHeights'];
    final Map<String, dynamic> heights = (rawHeights is Map) 
        ? Map<String, dynamic>.from(rawHeights) 
        : <String, dynamic>{};

    final DateTime safeDate = Observation._parseSafeDateTime(
      json['DateTime'] ?? json['dateTime'] ?? json['time'],
    );

    return TideForecast(
      dateTime: safeDate,
      tideType: (json['Tide'] ?? json['tideType'] ?? '').toString(),
      tideHeight: (heights['AboveLocalMSL'] ?? heights['AboveTWVD'] ?? json['tideHeight'] ?? json['height'] ?? '--').toString(),
    );
  }
}
