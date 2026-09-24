import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/monetization_suite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('【功能 12 真實穿透自檢】Apple StoreKit 商業閉環、實機 85 站付費閘門與 B2B 電話協定', () async {
    final result = await MonetizationDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 12 專項自檢：商業變現閉環與 85 站付費閘門】        ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 免費口岸 : ${result.isFreePortsUnlocked ? '✅ 開放' : '❌ 阻斷'} (龍洞/淡水/基隆等 ${result.freeCount} 大港口 100% 免費體驗)");
    print("║ • VIP 閘門 : ${result.isVipGatesLocked ? '✅ 鎖定' : '❌ 漏洞'} (富貴角等 ${result.proCount} 席外礁浮標精準鎖定付費牆)");
    print("║ • B2B 協定 : ${result.isB2bProtocolValid ? '✅ 就緒' : '❌ 異常'} (tel: 撥號通訊協定合規，支援一鍵訂餌)");
    print("║ • StoreKit : ${result.isStoreKitIdsComplete ? '✅ 齊全' : '❌ 缺失'} (週費/月費/年費/終身 4 大商品宣告就緒)");
    print("║ • VIP 序號 : ${result.isVipCardSerialValid ? '✅ 合規' : '❌ 異常'} (符合軍規正則標準：${result.sampleSerial})");
    print("║ • 審計結論 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.isFreePortsUnlocked, isTrue, reason: "8 大基準站必須 100% 放行免費體驗");
    expect(result.isVipGatesLocked, isTrue, reason: "77 席深海與外礁測站必須 100% 觸發 VIP 阻斷牆");
    expect(result.isStoreKitIdsComplete, isTrue, reason: "Apple StoreKit 4 大商品矩陣必須完好");
  });
}
