import 'dart:io' show Platform;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/tide/data/tide_model.dart';
import '../utils/solunar_util.dart';
import '../../features/premium/services/premium_service.dart';

final ttsProvider = StateNotifierProvider<TtsNotifier, bool>((ref) {
  return TtsNotifier(ref);
});

/// 🌟 經海事最高安全規格重塑之語音合成引擎
/// 具備致命長湧瘋狗浪語音第一順位插播、VVIP 尊榮播音與滿退 2 分水時程提醒
class TtsNotifier extends StateNotifier<bool> {
  final FlutterTts _tts = FlutterTts();
  final Ref ref;

  TtsNotifier(this.ref) : super(false) {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      final dynamic languages = await _tts.getLanguages;
      if (languages is List && languages.contains("zh-TW")) {
        await _tts.setLanguage("zh-TW");
      } else {
        await _tts.setLanguage("zh");
      }

      await _tts.setSpeechRate(0.5); 
      await _tts.setVolume(1.0);
      await _tts.setPitch(0.95);    

      if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.duckOthers, 
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
          ],
        );
      }
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        if (mounted) state = true;
      });
      _tts.setCompletionHandler(() {
        if (mounted) state = false;
      });
      _tts.setCancelHandler(() {
        if (mounted) state = false;
      });
      _tts.setErrorHandler((_) {
        if (mounted) state = false;
      });
    } catch (_) {
      if (mounted) state = false;
    }
  }

  Future<void> toggleBriefing(TideStationData station) async {
    if (state) {
      await stop();
      return;
    }

    final speechText = _composeSpeechScript(station);
    await _tts.speak(speechText);
  }

  Future<void> stop() async {
    await _tts.stop();
    if (mounted) state = false;
  }

  String _composeSpeechScript(TideStationData station) {
    final rawName = station.info.stationName;
    final cleanName = rawName.replaceAll(RegExp(r'[\(（].*?[\)）]'), '').trim();
    final displayName = cleanName.isNotEmpty ? cleanName : rawName;

    final ai = station.aiBriefing;
    final obs = station.observations.isNotEmpty ? station.observations.last : null;
    final solunar = SolunarUtil.calculate(DateTime.now());
    
    final premiumState = ref.read(premiumProvider);
    final StringBuffer sb = StringBuffer();
    
    // 1. 階級尊榮問候
    if (premiumState.isFounder) {
      sb.write("創始天尊指揮官您好，歡迎登艦！");
    } else if (premiumState.type == SubscriptionType.yearly) {
      sb.write("年度首席領航員，老船長為您待命！");
    } else if (premiumState.isPremium) {
      sb.write("尊榮航海家，早安。");
    } else {
      sb.write("老船長海象晨報。");
    }
    
    sb.write("今日鎖定觀測站點：$displayName。");

    // 2. 致命長湧瘋狗浪語音第一順位防線
    final double waveH = obs?.waveHeight ?? 0.0;
    final double waveP = obs?.wavePeriod ?? 0.0;
    final double flux = obs?.waveEnergyFlux ?? 0.0;

    if ((waveP >= 10.0 && waveH >= 0.7) || flux >= 3.5) {
      sb.write("緊急注意！外海偵測到週期${waveP.toStringAsFixed(0)}秒之深層長湧浪，動能通量高達${flux.toStringAsFixed(1)}千瓦，極易引發外礁蓋礁瘋狗浪，嚴禁前往無防護外礁！");
    }

    // 3. 實測水文數據
    if (obs != null) {
      if (obs.waveHeight != null) sb.write("實測浪高：${obs.waveHeight}米。");
      if (obs.windSpeed != null) sb.write("陣風風速：每秒${obs.windSpeed}米。");
      if (obs.seaTemperature != null) sb.write("海水表溫：${obs.seaTemperature}度。");
    } else {
      sb.write("提醒您，當前測站實體感測器維護中，已為您無縫接管天文調和推算。");
    }

    // 4. 天體引力與走水活躍度
    sb.write("今日天體水文狀態：${solunar.tideCategory}，魚群活躍指數百分之${solunar.fishActivityScore}。");

    // 5. AI 水文專家推論簡報
    if (ai != null) {
      sb.write("當前安全指針：${ai.safetyScore}分。");
      sb.write("綜合海況評估：${ai.briefing}。");
    }

    // 6. 滿潮時程與滿退 2 分水走水期
    final now = DateTime.now();
    for (final f in station.forecasts) {
      if (f.tideType.contains("滿") && f.dateTime.isAfter(now)) {
        final timeStr = DateFormat('HH點mm分').format(f.dateTime);
        final biteStart = f.dateTime.add(const Duration(hours: 1, minutes: 15));
        final biteStartStr = DateFormat('HH點mm分').format(biteStart);
        sb.write("提醒您，下一次滿潮水位將在$timeStr到來，滿退二分走水黃金期預估在$biteStartStr展開。");
        break;
      }
    }

    sb.write("出海作釣請務必穿著合格救生衣與防滑釘鞋，老船長祝您航行平安，滿載而歸！");
    return sb.toString();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}