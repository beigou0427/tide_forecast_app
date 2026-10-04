import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌟 經海事航海安全規範重塑之 ASO 原生評價引擎
/// 具備駕駛台絕對靜音防線，嚴禁在航海純潮汐儀表或緊急作業期間彈出評分打擾
class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;
  static const String _keyHasPrompted = 'has_prompted_review';
  static const String _keyLastPromptTime = 'last_prompt_review_epoch';

  /// 🌟 核心評分邀請入口 (具備海事安全靜默閥門)
  static Future<void> triggerOnDopamineMoment({required String triggerReason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. 🌟 海事最高安全防線：純潮汐航海儀表模式下 100% 絕對靜音，嚴禁彈窗遮擋水文數據
      final bool isPureTide = prefs.getBool('is_pure_tide_mode_v2') ?? false;
      if (isPureTide) {
        debugPrint("🛡️ [海事安全靜音] 純潮汐航海儀表模式運行中，嚴禁彈出評分視窗干擾航海！");
        return;
      }

      // 2. 若先前已評價過，終身不再彈窗打擾 (尊重用戶體驗)
      final bool hasReviewed = prefs.getBool(_keyHasPrompted) ?? false;
      if (hasReviewed) {
        debugPrint("ℹ️ [ASO 評分飛輪] 用戶先前已完成評分流程，跳過請求");
        return;
      }

      // 3. 剛性冷卻防打擾防線：至少間隔 30 天以上才能再次觸發
      final int lastEpoch = prefs.getInt(_keyLastPromptTime) ?? 0;
      final int nowEpoch = DateTime.now().millisecondsSinceEpoch;
      if (nowEpoch - lastEpoch < const Duration(days: 30).inMilliseconds) {
        debugPrint("⏳ [ASO 評分飛輪] 尚處於 30 天冷卻防打擾保護期，跳過邀請");
        return;
      }

      // 4. 設備硬體與 StoreKit 服務可用性探測
      bool isAvailable = false;
      try {
        isAvailable = await _inAppReview.isAvailable();
      } catch (err) {
        debugPrint("⚠️ [ASO 評分飛輪] 設備未就緒: $err");
        return;
      }

      if (isAvailable) {
        debugPrint("🌟 [ASO 評分飛輪] 捕捉到用戶登錄大物喜悅頂峰 ($triggerReason)，發起 Apple 原生評價邀請");
        await _inAppReview.requestReview();
        await prefs.setBool(_keyHasPrompted, true);
        await prefs.setInt(_keyLastPromptTime, nowEpoch);
      }
    } catch (e) {
      debugPrint("⚠️ [ASO 評分飛輪] 防衛捕獲異常: $e");
    }
  }

  /// 🎣 唯一觸發情境：用戶主動登錄了 5 顆星的漁獲戰利品（安全放鬆時刻）
  static Future<void> onCatchLogSaved(int rating) async {
    if (rating >= 5) {
      await triggerOnDopamineMoment(triggerReason: "釣獲五星大物戰利品");
    }
  }

  /// 廢除代幣與切換測站之干擾型彈窗，回歸駕駛台專注
  static Future<void> onUgcRewarded() async {}
  static Future<void> checkAndTriggerReview() async {}
}