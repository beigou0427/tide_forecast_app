import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../features/tide/data/tide_model.dart';
import 'solunar_util.dart';

class SpeciesBiteIndex {
  final String speciesName;
  final int biteProbability; // 15 ~ 95%
  final String statusBadge;   // "活性極佳" | "穩定索餌" | "謹慎就餌" | "閉口停滯"
  final String triggerReason; // "海溫微升 +0.8℃ · 浪腳白沫適中"
  final String tacticalTip;    // "建議使用 1.5 號阿波掛生鮮蝦攻湧浪邊緣"

  const SpeciesBiteIndex({
    required this.speciesName,
    required this.biteProbability,
    required this.statusBadge,
    required this.triggerReason,
    required this.tacticalTip,
  });
}

class BitePredictionResult {
  final int overallBiteScore;       // 20 ~ 95
  final String biteLevel;           // "走水活化期" | "穩定索餌期" | "水流平緩期"
  final String primaryWindow;       // 具體鐘點時間，如 "預估 次日00:45 ~ 02:15"
  final String oceanTriggerSummary; // 水文綜合推算摘要
  final List<SpeciesBiteIndex> speciesIndices;

  const BitePredictionResult({
    required this.overallBiteScore,
    required this.biteLevel,
    required this.primaryWindow,
    required this.oceanTriggerSummary,
    required this.speciesIndices,
  });
}

/// 🌟 經海事與水產生物學標準重塑之指標魚種索餌活性推算引擎
/// 100% 時態隔離防偽版：
/// 1. 徹底消滅「未來預報日偷塞今日實測數據」的時空錯置詐欺漏洞！
/// 2. 無實測數據時 100% 誠實退回純天體引力與潮汐預測，保證學理嚴謹度。
/// 3. 實裝跨夜走水黃金期自適應標記 ("次日")，消滅夜航作釣的時間歧義。
class BitePredictionEngine {
  static BitePredictionResult predict({
    required TideStationData stationData,
    required DateTime targetDate,
  }) {
    final solunar = SolunarUtil.calculate(targetDate);
    final targetKey = DateFormat('yyyyMMdd').format(targetDate);

    final dayObs = stationData.observations.where((o) =>
        DateFormat('yyyyMMdd').format(o.dateTime) == targetKey).toList();
        
    // 🌟 核心防線：時態絕對隔離！如果當日無實測數據 (未來預報日或過期歷史日)，
    // 絕對禁止拿「今天的實測」去偷塞給未來！強制設為 null，交由純天文推演！
    final latest = dayObs.isNotEmpty ? dayObs.last : null;

    final double? realWaveH = latest?.waveHeight;
    final double? realWindS = latest?.windSpeed;
    final double? realSeaTemp = latest?.seaTemperature;
    final double? realPressure = latest?.airPressure;

    // 戴明真實時間梯度分析 (僅當日有實測時才計算)
    double deltaTemp = 0.0;
    double deltaPressure = 0.0;
    bool hasTempGradient = false;
    bool hasPressureGradient = false;

    if (latest != null && stationData.observations.length >= 2) {
      final latestTime = latest.dateTime;
      Observation? sixHoursPastObs;
      int minDiffMinutes = 999999;

      for (var o in stationData.observations) {
        final diff = latestTime.difference(o.dateTime).inMinutes;
        // 尋找落在 4 小時 (240分) 至 8 小時 (480分) 之間的真實基準點
        if (diff >= 240 && diff <= 480) {
          final targetDiff = (diff - 360).abs();
          if (targetDiff < minDiffMinutes) {
            minDiffMinutes = targetDiff;
            sixHoursPastObs = o;
          }
        }
      }

      if (sixHoursPastObs != null) {
        if (realSeaTemp != null && sixHoursPastObs.seaTemperature != null) {
          deltaTemp = realSeaTemp - sixHoursPastObs.seaTemperature!;
          hasTempGradient = true;
        }
        if (realPressure != null && sixHoursPastObs.airPressure != null) {
          deltaPressure = realPressure - sixHoursPastObs.airPressure!;
          hasPressureGradient = true;
        }
      }
    }

    final List<SpeciesBiteIndex> species = [];

    // =========================================================================
    // 1. 🎣 黑毛 / 白毛 (外礁磯釣指標)
    // =========================================================================
    int kuroScore = 60;
    final StringBuffer kuroTriggerSb = StringBuffer();

    if (realSeaTemp != null) {
      if (realSeaTemp >= 19.0 && realSeaTemp <= 24.0) {
        kuroScore += 12;
        kuroTriggerSb.write("涼水期(${realSeaTemp.toStringAsFixed(1)}℃)");
      } else if (realSeaTemp > 26.0) {
        kuroScore -= 15;
        kuroTriggerSb.write("水溫偏高(${realSeaTemp.toStringAsFixed(1)}℃)");
      } else {
        kuroTriggerSb.write("海溫常態");
      }
    } else {
      kuroTriggerSb.write("天文潮位推演");
    }

    if (hasTempGradient) {
      if (deltaTemp > 0.4) {
        kuroScore += 14;
        kuroTriggerSb.write(" · 海溫回升+${deltaTemp.toStringAsFixed(1)}℃");
      } else if (deltaTemp < -0.8) {
        kuroScore -= 20;
        kuroTriggerSb.write(" · 冷水底翻${deltaTemp.toStringAsFixed(1)}℃");
      }
    }

    if (realWaveH != null) {
      if (realWaveH >= 0.8 && realWaveH <= 1.8) {
        kuroScore += 10;
        kuroTriggerSb.write(" · 浪腳白沫溶氧充足");
      } else if (realWaveH < 0.4) {
        kuroScore -= 10;
        kuroTriggerSb.write(" · 平水如鏡戒心高");
      } else if (realWaveH > 2.2) {
        kuroScore -= 18;
        kuroTriggerSb.write(" · 巨浪洗礁無法站立");
      }
    }

    if (solunar.tideCategory == "大潮") kuroScore += 8;

    kuroScore = kuroScore.clamp(15, 95);
    species.add(SpeciesBiteIndex(
      speciesName: "黑毛 · 白毛",
      biteProbability: kuroScore,
      statusBadge: kuroScore >= 80 ? "活性極佳" : (kuroScore >= 68 ? "穩定索餌" : "就餌謹慎"),
      triggerReason: kuroTriggerSb.toString(),
      tacticalTip: "建議掛阿波 0~0.5 號配合生鮮南極蝦，攻消波塊外緣潮目流尾。",
    ));

    // =========================================================================
    // 2. 🦑 軟絲 / 透抽 (岸拋木蝦/船釣指標)
    // =========================================================================
    int squidScore = 55;
    final StringBuffer squidTriggerSb = StringBuffer();

    if (realWaveH != null && realWindS != null) {
      if (realWaveH < 0.9 && realWindS < 5.5) {
        squidScore += 22;
        squidTriggerSb.write("風平浪平(${realWaveH.toStringAsFixed(1)}m) · 水質透澈");
      } else if (realWaveH >= 1.5 || realWindS >= 8.5) {
        squidScore -= 26;
        squidTriggerSb.write("風大浪濁 · 抱餌意願低");
      } else {
        squidTriggerSb.write("風浪適中");
      }
    } else {
      squidTriggerSb.write(solunar.tideCategory == "小潮" ? "平水微流期" : "常態走水");
    }

    if (solunar.tideCategory == "中潮" || solunar.tideCategory == "小潮") {
      squidScore += 10;
    }

    squidScore = squidScore.clamp(15, 92);
    species.add(SpeciesBiteIndex(
      speciesName: "軟絲 · 透抽",
      biteProbability: squidScore,
      statusBadge: squidScore >= 78 ? "活性良好" : (squidScore >= 65 ? "平穩索餌" : "索餌謹慎"),
      triggerReason: squidTriggerSb.toString(),
      tacticalTip: "選用 3.0~3.5 號慢沉木蝦，夜間搭配夜光本體攻岬角緩流交界處。",
    ));

    // =========================================================================
    // 3. 🎯 紅甘 / 煙仔虎 (岸拋鐵板/船釣指標)
    // =========================================================================
    int pelagicScore = 50;
    final StringBuffer pelagicTriggerSb = StringBuffer();

    if (solunar.tideCategory == "大潮") {
      pelagicScore += 24;
      pelagicTriggerSb.write("大潮急流活水 · 誘集餌魚");
    } else {
      pelagicTriggerSb.write("水流平順");
    }

    if (hasPressureGradient && deltaPressure < -1.0 && deltaPressure > -4.0) {
      pelagicScore += 15;
      pelagicTriggerSb.write(" · 氣壓降壓促使靠岸掠食");
    }

    if (realWindS != null && realWindS >= 5.0 && realWindS <= 10.0) {
      pelagicScore += 8;
    }

    pelagicScore = pelagicScore.clamp(15, 95);
    species.add(SpeciesBiteIndex(
      speciesName: "紅甘 · 煙仔虎",
      biteProbability: pelagicScore,
      statusBadge: pelagicScore >= 80 ? "靠岸活躍" : (pelagicScore >= 66 ? "適度就餌" : "零星就餌"),
      triggerReason: pelagicTriggerSb.toString(),
      tacticalTip: "選用 40g~60g 快沉微鐵，於滿潮返退急流處全層快抽跳底搜尋。",
    ));

    // =========================================================================
    // 4. 🦀 黑鯛 / 石斑 (前打沉底指標)
    // =========================================================================
    int breamScore = 62;
    final StringBuffer breamTriggerSb = StringBuffer();

    if (realWaveH != null && realWaveH >= 0.7 && realWaveH <= 1.6) {
      breamScore += 14;
      breamTriggerSb.write("拍浪捲起底棲誘餌");
    } else {
      breamTriggerSb.write("底棲覓食水象適宜");
    }

    breamScore = breamScore.clamp(20, 90);
    species.add(SpeciesBiteIndex(
      speciesName: "黑鯛 · 石斑",
      biteProbability: breamScore,
      statusBadge: breamScore >= 78 ? "底層活躍" : "穩定就餌",
      triggerReason: breamTriggerSb.toString(),
      tacticalTip: "採用前打青磺蝦或活白蝦，貼近防波堤樁腳與深坎緩慢落入探尋。",
    ));

    final int avgSpeciesScore = (species.fold<int>(0, (sum, s) => sum + s.biteProbability) / species.length).round();
    final int overallScore = ((solunar.fishActivityScore * 0.45) + (avgSpeciesScore * 0.55)).round().clamp(20, 95);

    String level = "穩定索餌期";
    if (overallScore >= 80) {
      level = "走水活化期";
    } else if (overallScore <= 60) {
      level = "水流平緩期";
    }

    // 🌟 核心升級：跨夜歧義消除與具體「鐘點時間起流大咬窗口」
    String primaryWindow = "滿潮返退 2 分水至返退 5 分 (前後 2 小時走水窗口)";
    TideForecast? matchedHighTide;
    
    for (var f in stationData.forecasts) {
      if (f.tideType.contains("滿")) {
        final fKey = DateFormat('yyyyMMdd').format(f.dateTime);
        if (fKey == targetKey) {
          matchedHighTide = f;
          break;
        } else if (f.dateTime.isAfter(targetDate)) {
          matchedHighTide ??= f;
        }
      }
    }

    if (matchedHighTide != null) {
      final highTideTime = matchedHighTide.dateTime;
      final windowStart = highTideTime.add(const Duration(hours: 1, minutes: 15));
      final windowEnd = highTideTime.add(const Duration(hours: 2, minutes: 45));
      
      // 計算是否發生跨夜 (與目標查詢日進行日曆比較)
      final targetMidnight = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final startMidnight = DateTime(windowStart.year, windowStart.month, windowStart.day);
      final String startDayPrefix = startMidnight.isAfter(targetMidnight) ? "次日" : "";
      
      final String startStr = DateFormat('HH:mm').format(windowStart);
      final String endStr = DateFormat('HH:mm').format(windowEnd);
      final String highStr = DateFormat('HH:mm').format(highTideTime);

      primaryWindow = "預估 $startDayPrefix$startStr ~ $endStr (滿潮 $highStr 返退起流)";
    }

    String summary = "水文走勢穩定，走水節奏契合天體潮位，多數標點作業皆具良好潛力。";
    if (hasTempGradient && deltaTemp > 0.5) {
      summary = "海溫顯著微升 +${deltaTemp.toStringAsFixed(1)}℃，水溫躍層形成促使黑毛與近岸魚種積極就餌。";
    } else if (hasTempGradient && deltaTemp < -0.8) {
      summary = "海水底層冷水翻湧 (${deltaTemp.toStringAsFixed(1)}℃)，魚群索餌轉向敏感，建議精細釣組放緩節奏。";
    } else if (hasPressureGradient && deltaPressure < -1.5) {
      summary = "大氣氣壓持續下降 (${deltaPressure.toStringAsFixed(1)}hPa)，鋒面前緣效應可能刺激青物進入掠食高峰。";
    } else if (latest == null) {
      summary = "系統正以天體引力與潮汐模型為您預估基礎索餌活性，請隨時留意屆時之真實海況與風浪。";
    }

    return BitePredictionResult(
      overallBiteScore: overallScore,
      biteLevel: level,
      primaryWindow: primaryWindow,
      oceanTriggerSummary: summary,
      speciesIndices: species,
    );
  }
}