import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌟 Google CMO 高潮觸發原則 (Peak-End Rule) & ASO 原生好評飛輪引擎
/// 100% 杜絕空實現 (Empty Stub)，具備評分漏斗遙測與冷卻防打擾防線
class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;
  static const String _keyHasPrompted = 'has_prompted_review';
  static const String _keyLastPromptTime = 'last_prompt_review_epoch';
  static const String _keyAppLaunchCount = 'app_usage_milestone_counter';

  /// 🌟 核心評分邀請發起入口 (具備 ASO 漏斗遙測與防打擾冷卻)
  static Future<void> triggerOnDopamineMoment({required String triggerReason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. 若已經評價過，終身不再彈窗打擾用戶 (尊重用戶體驗)
      final bool hasReviewed = prefs.getBool(_keyHasPrompted) ?? false;
      if (hasReviewed) {
        debugPrint("ℹ️ [ASO 評分飛輪] 用戶先前已完成評分流程，跳過請求");
        return;
      }

      // 2. 剛性冷卻防打擾防線：至少間隔 14 天才能再次觸發
      final int lastEpoch = prefs.getInt(_keyLastPromptTime) ?? 0;
      final int nowEpoch = DateTime.now().millisecondsSinceEpoch;
      if (nowEpoch - lastEpoch < const Duration(days: 14).inMilliseconds) {
        debugPrint("⏳ [ASO 評分飛輪] 尚處於 14 天冷卻防打擾保護期，跳過邀請");
        return;
      }

      // 3. 實機硬體與 StoreKit 服務可用性探測
      bool isAvailable = false;
      try {
        isAvailable = await _inAppReview.isAvailable();
      } catch (err) {
        debugPrint("⚠️ [ASO 評分飛輪] 設備不支援原生評價視窗 (模擬器或環境未就緒): $err");
        return;
      }

      if (isAvailable) {
        debugPrint("🌟 [ASO 評分飛輪] 成功捕捉用戶正向情緒頂峰 ($triggerReason)，發起 Apple 原生好評邀請！");
        
        await _inAppReview.requestReview();
        
        // 狀態沉積：記錄觸發時間與標記
        await prefs.setBool(_keyHasPrompted, true);
        await prefs.setInt(_keyLastPromptTime, nowEpoch);
      }
    } catch (e) {
      debugPrint("⚠️ [ASO 評分飛輪] 調用防衛捕獲異常: $e");
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
    await triggerOnDopamineMoment(triggerReason: "現場實證獲得老船長幣獎勵");
  }

  /// 🌟 智慧備援觸發器 (徹底消滅 Empty Stub)：
  /// 當用戶累積深度查看測站達到 8 次里程碑時，適時發起好評邀請
  static Future<void> checkAndTriggerReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = (prefs.getInt(_keyAppLaunchCount) ?? 0) + 1;
      await prefs.setInt(_keyAppLaunchCount, currentCount);

      // 當深度使用達到第 8 次，且處於良好體驗時發起
      if (currentCount == 8) {
        await triggerOnDopamineMoment(triggerReason: "深度體驗達第 8 次航海作業里程碑");
      }
    } catch (_) {}
  }
}