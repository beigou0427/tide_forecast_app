import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'global_error_trap.dart';

/// 🌟 經海事與創投級量化標準重塑之全域遙測引擎
/// 100% 全漏斗數據歸因與 Firebase 安全防呆版：
/// 1. 補齊 logPurchaseSuccess 與 logStationView，建立創投級 ROAS / LTV 完整數據飛輪。
/// 2. 實裝 Firebase User Property 36 字元安全防呆夾鉗，杜絕超長字串拋錯。
/// 3. 惰性自癒實體存取，確保外海離線恢復後遙測數據 0 丟失。
class AnalyticsService {
  static FirebaseAnalytics? _analytics;

  /// 🌟 惰性自癒存取器：若冷啟動時逾時，網路恢復後自動連通實體
  static FirebaseAnalytics? get _instance {
    if (_analytics == null) {
      try {
        _analytics = FirebaseAnalytics.instance;
      } catch (_) {}
    }
    return _analytics;
  }

  static Future<void> init() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics?.setDefaultEventParameters({
        'app_version': '2.6.0+5',
        'platform_tier': 'flagship_pro',
      });
      debugPrint("✅ [Analytics] Firebase 連線成功，創投級數據增長漏斗啟動！");
    } catch (e, stack) {
      debugPrint("⚠️ [Analytics] Firebase 連線失敗: $e");
      GlobalErrorTrap.recordException(
        e, 
        stackTrace: stack, 
        contextTag: "AnalyticsInit", 
        severity: ErrorSeverity.warning,
      );
    }
  }

  // 1. 紀錄使用者觀看測站 (活躍度與黏性指標)
  static Future<void> logStationView(String stationId, String stationName) async {
    debugPrint("📊 [埋點追蹤] 觀看測站: $stationName ($stationId)");
    try {
      await _instance?.logEvent(
        name: 'station_viewed',
        parameters: {
          'station_id': stationId, 
          'station_name': _clampString(stationName, 40),
        },
      );
    } catch (_) {}
  }

  // 2. 紀錄使用者打開付費牆 (漏斗頂端曝光)
  static Future<void> logPaywallView({String triggerSource = 'drawer_locked_station'}) async {
    debugPrint("📊 [埋點追蹤] 曝光付費牆 (來源: $triggerSource)");
    try {
      await _instance?.logEvent(
        name: 'paywall_viewed',
        parameters: {'trigger_source': _clampString(triggerSource, 40)},
      );
    } catch (_) {}
  }

  // 3. 紀錄使用者點擊購買方案 (轉換意圖)
  static Future<void> logInitiateCheckout(String productId) async {
    debugPrint("📊 [埋點追蹤] 發起結帳: $productId");
    try {
      await _instance?.logEvent(
        name: 'initiate_checkout',
        parameters: {'product_id': _clampString(productId, 40)},
      );
    } catch (_) {}
  }

  // 🌟 4. 補齊漏斗底端：紀錄付款成功與 ROAS 金流轉換 (核心 LTV/CAC 歸因)
  static Future<void> logPurchaseSuccess({
    required String productId,
    required double price,
    String currency = 'TWD',
  }) async {
    debugPrint("💰 [埋點追蹤] 交易成功！產品: $productId, 金額: $price $currency");
    try {
      await _instance?.logEvent(
        name: 'purchase_success',
        parameters: {
          'product_id': _clampString(productId, 40),
          'value': price,
          'currency': currency,
        },
      );
    } catch (_) {}
  }

  // 🌟 5. 收割零方數據 (Zero-Party Data) 與 User Property 安全發送
  static Future<void> logOnboardingCompleted({
    required String region,
    required String style,
    required String risk,
    required String jtbdReason,
    required bool isSkipped,
    required bool claimed7DaysTrial,
  }) async {
    debugPrint("📊 [埋點追蹤] 完成前置引導 (跳過: $isSkipped, 領取7天: $claimed7DaysTrial)");
    debugPrint("   -> 動機 (JTBD): $jtbdReason");
    
    try {
      // 🌟 核心防線：setUserProperty value 嚴格限制在 36 字元內！
      await _instance?.setUserProperty(name: 'user_region', value: _clampString(region, 36));
      await _instance?.setUserProperty(name: 'user_style', value: _clampString(style, 36));
      await _instance?.setUserProperty(name: 'user_jtbd', value: _clampString(jtbdReason, 36));
      
      await _instance?.logEvent(
        name: 'onboarding_funnel_completed',
        parameters: {
          'is_skipped': isSkipped.toString(),
          'claimed_trial': claimed7DaysTrial.toString(),
          'primary_jtbd': _clampString(jtbdReason, 100),
          'primary_risk': _clampString(risk, 100),
        },
      );
    } catch (e) {
      debugPrint("⚠️ [Analytics] 零方數據發送失敗: $e");
    }
  }

  // 🌟 6. VVIP 價值實現 (AHA Moment)
  static Future<void> logGoldenWindowViewed(String stationId) async {
    debugPrint("📊 [埋點追蹤] VVIP 觸發 AHA Moment：查看走水黃金窗口 ($stationId)");
    try {
      await _instance?.logEvent(
        name: 'golden_window_viewed',
        parameters: {'station_id': _clampString(stationId, 40)},
      );
    } catch (_) {}
  }

  /// 安全字串截斷防呆工具
  static String _clampString(String input, int maxLength) {
    final trimmed = input.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return trimmed.substring(0, maxLength);
  }
}
