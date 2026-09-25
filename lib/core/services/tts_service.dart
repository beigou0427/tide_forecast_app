import 'dart:io' show Platform;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/tide/data/tide_model.dart';
import '../utils/solunar_util.dart';

final ttsProvider = StateNotifierProvider<TtsNotifier, bool>((ref) {
  return TtsNotifier();
});

class TtsNotifier extends StateNotifier<bool> {
  final FlutterTts _tts = FlutterTts();

  TtsNotifier() : super(false) {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("zh-TW");
      await _tts.setSpeechRate(0.5); // 沉穩適中的語速
      await _tts.setVolume(1.0);
      await _tts.setPitch(0.95);    // 略帶成熟的老船長沉穩音色

      // 🌟 VIP 痛點修復 2/3：實作 Audio Focus Ducking 技術
      // 確保 TTS 播放時，自動壓低 (Duck) 背景音樂 (如 Spotify, Apple Music)，播完後平滑恢復
      if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.duckOthers, // 核心：壓低其他 App 音量
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
          ],
        );
      }
      // 啟動等待播放完成機制，讓 Android 與 iOS 都能精準掌握釋放 Audio Focus 的時機
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

    final StringBuffer sb = StringBuffer();
    sb.write("老船長海象晨報。");
    sb.write("觀測站點：$name。");

    if (ai != null) {
      sb.write("今日安全指針：${ai.safetyScore}分。");
      sb.write("綜合海況評估：${ai.briefing}。");
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

    sb.write("出海作釣請務必穿著合格釘鞋與救生衣，老船長祝您滿載而歸！");
    return sb.toString();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}