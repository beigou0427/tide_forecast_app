import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// 檢查並在用戶深入體驗核心價值（達標 3 次）時觸發原生五星評分
  static Future<void> checkAndTriggerReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final bool hasReviewed = prefs.getBool('has_prompted_review') ?? false;
      if (hasReviewed) return;

      int deepUsageCount = prefs.getInt('deep_usage_count') ?? 0;
      deepUsageCount++;
      await prefs.setInt('deep_usage_count', deepUsageCount);

      if (deepUsageCount >= 3) {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
          await prefs.setBool('has_prompted_review', true);
        }
      }
    } catch (_) {}
  }
}

