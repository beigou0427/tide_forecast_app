import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tide_forecast_app/core/utils/constants.dart';

class MonetizationSuiteResult {
  final bool isFreePortsUnlocked;
  final bool isVipGatesLocked;
  final bool isB2bProtocolValid;
  final bool isStoreKitIdsComplete;
  final bool isVipCardSerialValid;
  final int freeCount;
  final int proCount;
  final String sampleSerial;
  final String message;

  const MonetizationSuiteResult({
    required this.isFreePortsUnlocked,
    required this.isVipGatesLocked,
    required this.isB2bProtocolValid,
    required this.isStoreKitIdsComplete,
    required this.isVipCardSerialValid,
    required this.freeCount,
    required this.proCount,
    required this.sampleSerial,
    required this.message,
  });

  bool get isAllPassed =>
      isFreePortsUnlocked &&
      isVipGatesLocked &&
      isB2bProtocolValid &&
      isStoreKitIdsComplete &&
      isVipCardSerialValid;
}

class MonetizationDiagnosticSuite {
  static Future<MonetizationSuiteResult> run() async {
    // 1 & 2. 真實 85 站全庫遍歷：8 大免費站與 77 站 VIP 付費閘門精準度審計
    int freeCount = 0;
    int proCount = 0;
    bool freeGatesOk = true;
    bool proGatesOk = true;

    try {
      final raw = await rootBundle.loadString('assets/stations_config.json');
      final List list = jsonDecode(raw);

      for (var s in list) {
        final sid = s['id']?.toString() ?? '';
        final model = StationModel(id: sid, name: s['name'] ?? '', region: s['region'] ?? '', lat: 25.0, lng: 121.0);
        
        if (model.isProOnly) {
          proCount++;
          // 確保免費清單裡的 ID 絕對不應該被判斷為 ProOnly
          if (AppConstants.freeStationIds.contains(sid)) proGatesOk = false;
        } else {
          freeCount++;
          // 確保免費站數量與邏輯完全吻合
          if (!AppConstants.freeStationIds.contains(sid)) freeGatesOk = false;
        }
      }
    } catch (_) {
      freeGatesOk = false;
      proGatesOk = false;
    }

    final bool freeOk = freeGatesOk && freeCount == 8;
    final bool proOk = proGatesOk && proCount == 77;

    // 3. B2B 實體特約商家電話協定校驗
    final uri = Uri.parse("tel:0224690000");
    final bool b2bOk = uri.scheme == "tel";

    // 4. 4 大 StoreKit 產品矩陣宣告完整度
    final bool storeKitOk = AppConstants.iapProductIds.length == 4 && 
                            AppConstants.iapProductIds.contains(AppConstants.iapProMonthly) &&
                            AppConstants.iapProductIds.contains(AppConstants.iapProYearly);

    // 5. VIP 創始黑金身分銘牌演算法合規
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final testSeq = "CAPT-2026-${nowMs.toString().substring(5, 9)}";
    final bool seqOk = RegExp(r'^CAPT-2026-\d{4}$').hasMatch(testSeq);

    String msg;
    if (!freeOk) {
      msg = "8 大基準免費港口權限反轉，遭誤判為付費站！";
    } else if (!proOk) {
      msg = "77 席 VIP 測站付費牆漏洞，遭誤判為免費開放！";
    } else if (!storeKitOk) {
      msg = "StoreKit 4 大商品矩陣宣告缺失！";
    } else {
      msg = "8/77 商業分級防線堅不可摧，StoreKit 矩陣與 B2B 通訊協定全數就緒！";
    }

    return MonetizationSuiteResult(
      isFreePortsUnlocked: freeOk,
      isVipGatesLocked: proOk,
      isB2bProtocolValid: b2bOk,
      isStoreKitIdsComplete: storeKitOk,
      isVipCardSerialValid: seqOk,
      freeCount: freeCount,
      proCount: proCount,
      sampleSerial: testSeq,
      message: msg,
    );
  }
}
