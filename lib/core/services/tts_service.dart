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

      // 嚴格生命週期守衛，防止銷毀後更新狀態
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
    // 濾除括號英數代碼，呈現自然口語播音
    final cleanName = station.info.stationName.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    final ai = station.aiBriefing;
    final obs = station.observations.isNotEmpty ? station.observations.last : null;
    final solunar = SolunarUtil.calculate(DateTime.now());
    
    final premiumState = ref.read(premiumProvider);
    final StringBuffer sb = StringBuffer();
    
    // 1. 階級尊榮問候
    if (premiumState.isFounder) {
      sb.write("創始指揮官您好，歡迎登艦！");
    } else if (premiumState.type == SubscriptionType.yearly) {
      sb.write("年度首席領航員，老船長為您待命！");
    } else if (premiumState.isPremium) {
      sb.write("尊榮航海家，早安。");
    } else {
      sb.write("老船長海象晨報。");
    }
    
    sb.write("今日為您鎖定觀測站點：$cleanName。");

    // 2. 致命長湧瘋狗浪語音防線
    final double waveH = obs?.waveHeight ?? 0.0;
    final double waveP = obs?.wavePeriod ?? 0.0;
    if (waveP >= 10.0 && waveH >= 0.7) {
      sb.write("緊急注意！外海偵測到週期${waveP.toStringAsFixed(0)}秒之深層長湧浪，極易引發外礁蓋礁瘋狗浪，嚴禁前往外礁作釣！");
    }

    // 3. AI 專家水文簡報
    if (ai != null) {
      sb.write("當前安全指針：${ai.safetyScore}分。");
      sb.write("老船長綜合海況評估：${ai.briefing}。");
    }

    // 4. 天體日月引力狀態
    sb.write("今日水文狀態：${solunar.tideCategory}，魚群活躍指數百分之${solunar.fishActivityScore}。");

    // 5. 實測觀測數據
    if (obs != null) {
      if (obs.waveHeight != null) sb.write("實測浪高：${obs.waveHeight}米。");
      if (obs.windSpeed != null) sb.write("陣風風速：每秒${obs.windSpeed}米。");
      if (obs.seaTemperature != null) sb.write("海水表溫：${obs.seaTemperature}度。");
    } else {
      sb.write("提醒您，當前測站實體感測器維護中，無即時風浪數據。");
    }

    // 6. 滿潮時程提醒
    final now = DateTime.now();
    for (final f in station.forecasts) {
      if (f.tideType.contains("滿") && f.dateTime.isAfter(now)) {
        final timeStr = DateFormat('HH點mm分').format(f.dateTime);
        sb.write("提醒您，下一次滿潮水位將在$timeStr到來。");
        break;
      }
    }

    if (premiumState.isPremium) {
      sb.write("出海作釣請穿著合格裝備，祝長官滿載而歸！");
    } else {
      sb.write("出海作釣請穿戴防滑釘鞋與救生衣，老船長祝您滿載而歸！");
    }
    
    return sb.toString();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
