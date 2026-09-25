import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;
  static const String _keyHasPrompted = 'has_prompted_review';
  static const String _keyLastPromptTime = 'last_prompt_review_epoch';

  /// 🌟 Google CMO 高潮觸發原則 (Peak-End Rule)：
  /// 只有在用戶處於正向情緒頂峰（成就感 / 獲得獎勵）時，才發起 Apple 原生好評邀請
  static Future<void> triggerOnDopamineMoment({required String triggerReason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. 若已經評價過，終身不再打擾用戶
      final bool hasReviewed = prefs.getBool(_keyHasPrompted) ?? false;
      if (hasReviewed) return;

      // 2. 冷却防打擾防線：至少間隔 14 天才能再次觸發
      final int lastEpoch = prefs.getInt(_keyLastPromptTime) ?? 0;
      final int nowEpoch = DateTime.now().millisecondsSinceEpoch;
      if (nowEpoch - lastEpoch < const Duration(days: 14).inMilliseconds) {
        return;
      }

      if (await _inAppReview.isAvailable()) {
        debugPrint("🌟 [ASO 評分飛輪] 偵測到用戶多巴胺頂峰 ($triggerReason)，發起原生 5 星好評邀請！");
        await _inAppReview.requestReview();
        await prefs.setBool(_keyHasPrompted, true);
        await prefs.setInt(_keyLastPromptTime, nowEpoch);
      }
    } catch (e) {
      debugPrint("⚠️ 評分引擎調用防禦: $e");
    }
  }

  /// 🎣 觸發情境 1：用戶剛記錄了一筆 4 或 5 顆星的漁獲戰利品（成就感頂峰）
  static Future<void> onCatchLogSaved(int rating) async {
    if (rating >= 4) {
      await triggerOnDopamineMoment(triggerReason: "釣獲大物好評 (評分: $rating星)");
    }
  }

  /// 🪙 觸發情境 2：用戶剛回報實況並獲得了「老船長幣」獎勵（獲得感頂峰）
  static Future<void> onUgcRewarded() async {
    await triggerOnDopamineMoment(triggerReason: "獲得老船長幣獎勵");
  }

  /// 兼容舊方法 (平滑降級，避免其他調用處編譯錯誤)
  static Future<void> checkAndTriggerReview() async {}
}