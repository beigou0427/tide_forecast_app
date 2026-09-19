import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;

  static Future<void> init() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      debugPrint("✅ [Analytics] Firebase 連線成功，雲端監控啟動！");
    } catch (e) {
      debugPrint("⚠️ [Analytics] Firebase 連線失敗: $e");
    }
  }

  // 1. 紀錄使用者看了哪個測站
  static Future<void> logStationView(String stationId, String stationName) async {
    debugPrint("📊 [埋點追蹤] 觀看測站: $stationName ($stationId)");
    await _analytics?.logEvent(
      name: 'station_viewed',
      parameters: {'station_id': stationId, 'station_name': stationName},
    );
  }

  // 2. 紀錄使用者打開付費牆 (曝光度)
  static Future<void> logPaywallView() async {
    debugPrint("📊 [埋點追蹤] 曝光付費牆: paywall_viewed");
    await _analytics?.logEvent(name: 'paywall_viewed');
  }

  // 3. 紀錄使用者點擊了哪個購買方案 (轉換率)
  static Future<void> logInitiateCheckout(String productId) async {
    debugPrint("📊 [埋點追蹤] 點擊購買按鈕: initiate_checkout ($productId)");
    await _analytics?.logEvent(
      name: 'initiate_checkout',
      parameters: {'product_id': productId},
    );
  }
}

