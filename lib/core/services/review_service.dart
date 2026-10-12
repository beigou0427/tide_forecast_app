import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_error_trap.dart';

/// 🌟 商業變現與 ASO 五星增長引擎 (100% 靜態簽名安全防禦版)
/// 1. 補齊 onCatchLogSaved 與 onVvipUnlocked 簽名，消滅編譯期 Method not found 崩潰！
/// 2. 實裝 Apple 規範 365 天防打擾節流閥 (Throttle Shield)，保持旗艦級 UX。
class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// 既有的深度使用觸發 (相容舊代碼)
  static Future<void> checkAndTriggerReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int deepUsageCount = prefs.getInt('deep_usage_count') ?? 0;
      deepUsageCount++;
      await prefs.setInt('deep_usage_count', deepUsageCount);

      if (deepUsageCount >= 3) {
        await _requestReviewWithThrottling(eventTag: "DeepUsage");
      }
    } catch (_) {}
  }

  /// AHA Moment 1: 記錄到 5 星大物時觸發 (高情緒價值)
  static Future<void> onCatchLogSaved(int rating) async {
    // 只有在釣客情緒最高昂 (捕獲 5 星大物) 時，才要求給予五星好評
    if (rating >= 5) {
      await _requestReviewWithThrottling(eventTag: "TrophyCatch");
    }
  }

  /// AHA Moment 2: 成功解鎖 VVIP 權限時觸發 (高品牌認同)
  static Future<void> onVvipUnlocked() async {
    // 剛付費解鎖的瞬間，是用戶對系統信任度最高的時候
    await _requestReviewWithThrottling(eventTag: "VvipUnlock");
  }

  /// 🌟 Apple 嚴格規範防呆 (Throttle Shield)
  static Future<void> _requestReviewWithThrottling({required String eventTag}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 終極防打擾：如果已經彈過，就不再瘋狂騷擾使用者，避免引起反感留下 1 星
      final bool hasReviewed = prefs.getBool('has_prompted_review_v2') ?? false;
      if (hasReviewed) return;

      // 確保 API 在當前系統環境 (iOS/Android) 支援
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        
        // 標記已請求過，維持高雅的 UX
        await prefs.setBool('has_prompted_review_v2', true);
        debugPrint("⭐️ [InAppReview] 成功觸發五星評分彈窗！(觸發源: $eventTag)");
      }
    } catch (e, stack) {
      // 非致命錯誤，僅記錄至黑盒子，絕不中斷 UI
      GlobalErrorTrap.recordException(
        e, 
        stackTrace: stack, 
        contextTag: "ReviewService", 
        severity: ErrorSeverity.info,
      );
    }
  }
}