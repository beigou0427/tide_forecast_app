import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_error_trap.dart';

/// 🌟 商業變現與 ASO 五星增長引擎 (Apple 3/365 滑動視窗演算法版)
/// 1. 徹底消滅舊版 boolean 標記造成的「終身只問一次」流量浪費漏洞！
/// 2. 實裝 Apple 官方規範：365 天內最多彈出 3 次，且每次間隔至少 60 天的冷卻期 (Cooldown)。
class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// 一般深度使用觸發 (備用引擎)
  static Future<void> checkAndTriggerReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int deepUsageCount = prefs.getInt('deep_usage_count') ?? 0;
      deepUsageCount++;
      await prefs.setInt('deep_usage_count', deepUsageCount);

      if (deepUsageCount % 10 == 0) { // 每深度使用 10 次嘗試觸發
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

  /// 🌟 Apple ASO 嚴格規範防呆 (Sliding Window Throttle Shield)
  static Future<void> _requestReviewWithThrottling({required String eventTag}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 取得歷史彈窗時間戳記
      List<String> rawHistory = prefs.getStringList('aso_review_history_v3') ?? [];
      final now = DateTime.now();
      
      // 🌟 1. 滑動視窗：自動過濾並拋棄 365 天以前的舊紀錄
      final validHistory = rawHistory
          .map((e) => DateTime.tryParse(e))
          .where((d) => d != null && now.difference(d).inDays <= 365)
          .map((d) => d!.toIso8601String())
          .toList();

      // 🌟 2. 觸發次數極限限制：365天內不得超過 3 次 (Apple 官方死線)
      if (validHistory.length >= 3) {
        debugPrint("🛡️ [ASO 護城河] 過去 365 天已彈出 3 次達 Apple 上限，阻斷騷擾。");
        return;
      }

      // 🌟 3. 冷卻期防護：兩次彈窗之間至少間隔 60 天，極大化使用者耐心
      if (validHistory.isNotEmpty) {
        final lastPrompt = DateTime.parse(validHistory.last);
        if (now.difference(lastPrompt).inDays < 60) {
          debugPrint("🛡️ [ASO 護城河] 距離上次彈出未滿 60 天冷卻期，阻斷騷擾。");
          return;
        }
      }

      // 確保 API 在當前系統環境 (iOS/Android) 支援
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        
        // 標記本次成功請求，寫入滑動視窗
        validHistory.add(now.toIso8601String());
        await prefs.setStringList('aso_review_history_v3', validHistory);
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
