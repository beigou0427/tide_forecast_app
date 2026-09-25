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
      await _tts.setLanguage("zh-TW");
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

      _tts.setStartHandler(() => state = true);
      _tts.setCompletionHandler(() => state = false);
      _tts.setCancelHandler(() => state = false);
      _tts.setErrorHandler((_) => state = false);
    } catch (_) {
      state = false;
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
    state = false;
  }

  String _composeSpeechScript(TideStationData station) {
    final name = station.info.stationName;
    final ai = station.aiBriefing;
    final obs = station.observations.isNotEmpty ? station.observations.last : null;
    final solunar = SolunarUtil.calculate(DateTime.now());
    
    // 🌟 讀取用戶的尊榮 VIP 狀態
    final premiumState = ref.read(premiumProvider);

    final StringBuffer sb = StringBuffer();
    
    // 🌟 情緒價值彩蛋：根據階級給予不同的專屬語音問候
    if (premiumState.isFounder) {
      sb.write("創始指揮官您好，歡迎登艦！");
    } else if (premiumState.type == SubscriptionType.yearly) {
      sb.write("年度領航員，老船長為您待命！");
    } else if (premiumState.isPremium) {
      sb.write("尊榮航海家，早安。");
    } else {
      sb.write("老船長海象晨報。");
    }
    
    sb.write("今日為您鎖定觀測站點：$name。");

    if (ai != null) {
      sb.write("當前安全指針：${ai.safetyScore}分。");
      sb.write("老船長綜合海況評估：${ai.briefing}。");
    }

    sb.write("水文狀態：${solunar.tideCategory}，魚群活躍指數百分之${solunar.fishActivityScore}。");

    if (obs != null) {
      if (obs.waveHeight != null) sb.write("實測浪高：${obs.waveHeight}米。");
      if (obs.windSpeed != null) sb.write("陣風風速：每秒${obs.windSpeed}米。");
      if (obs.seaTemperature != null) sb.write("海水表溫：${obs.seaTemperature}度。");
    }

    final now = DateTime.now();
    for (final f in station.forecasts) {
      if (f.tideType.contains("滿") && f.dateTime.isAfter(now)) {
        final timeStr = DateFormat('HH點mm分').format(f.dateTime);
        sb.write("提醒您，下一次滿潮水位將在$timeStr到來。");
        break;
      }
    }

    // 結語同樣加入尊榮感
    if (premiumState.isPremium) {
      sb.write("出海作釣請穿著合格裝備，祝長官滿載而歸！");
    } else {
      sb.write("出海作釣請注意安全，祝您滿載而歸！");
    }
    
    return sb.toString();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}