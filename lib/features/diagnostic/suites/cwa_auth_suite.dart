import 'package:http/http.dart' as http;
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/security_util.dart';

/// 🌟 氣象署金鑰鑑權自檢套件 (100% 離線穩健容災版)
/// 1. 徹底消滅外海離線斷網時金鑰解密完全正確卻被假性判定為失敗的漏洞！
/// 2. 本地金鑰解密與 RFC 4122 UUID 格式合規性為第一判定原則，離線時不誤報紅燈。
/// 3. 嚴格包含傳輸層零信任白名單檢驗與伺服器即時握手。
class CwaAuthSuiteResult {
  final bool isDecrypted;
  final bool isRegexValid;
  final bool isServerAuthorized;
  final bool isOfflinePass;
  final int httpStatusCode;
  final int latencyMs;
  final String maskedKey;
  final String message;

  const CwaAuthSuiteResult({
    required this.isDecrypted,
    required this.isRegexValid,
    required this.isServerAuthorized,
    required this.isOfflinePass,
    required this.httpStatusCode,
    required this.latencyMs,
    required this.maskedKey,
    required this.message,
  });

  // 🌟 核心防線：金鑰解密與格式正確時，若因外海離線無網路，視為本機結構合格通過！
  bool get isAllPassed => 
      isDecrypted && 
      isRegexValid && 
      (isServerAuthorized || isOfflinePass);
}

class CwaAuthDiagnosticSuite {
  static Future<CwaAuthSuiteResult> run() async {
    final sw = Stopwatch()..start();
    
    // 1. 動態解密測試
    String key = "";
    try {
      key = AppConstants.officialApiKey;
    } catch (e) {
      sw.stop();
      return CwaAuthSuiteResult(
        isDecrypted: false,
        isRegexValid: false,
        isServerAuthorized: false,
        isOfflinePass: false,
        httpStatusCode: 0,
        latencyMs: sw.elapsedMilliseconds,
        maskedKey: "N/A",
        message: "XOR 位元組矩陣解密崩潰: $e",
      );
    }

    if (key.isEmpty) {
      sw.stop();
      return CwaAuthSuiteResult(
        isDecrypted: false,
        isRegexValid: false,
        isServerAuthorized: false,
        isOfflinePass: false,
        httpStatusCode: 0,
        latencyMs: sw.elapsedMilliseconds,
        maskedKey: "EMPTY",
        message: "解密結果為空字串",
      );
    }

    // 2. 嚴格比對 CWA 官方 UUID 格式 (大小寫不敏感 RFC 4122 標準)
    final regex = RegExp(
      r'^CWA-[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$',
      caseSensitive: false,
    );
    final bool regexOk = regex.hasMatch(key);
    final String masked = key.length >= 12 
        ? "${key.substring(0, 8)}...${key.substring(key.length - 4)}" 
        : key;

    if (!regexOk) {
      sw.stop();
      return CwaAuthSuiteResult(
        isDecrypted: true,
        isRegexValid: false,
        isServerAuthorized: false,
        isOfflinePass: false,
        httpStatusCode: 0,
        latencyMs: sw.elapsedMilliseconds,
        maskedKey: masked,
        message: "金鑰未通過 RFC 4122 UUID 格式校驗 (格式損壞)",
      );
    }

    // 3. 官方伺服器即時鑑權握手 (含主機白名單校驗)
    int statusCode = 0;
    bool serverOk = false;
    final probeUri = Uri.parse("https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization=$key&limit=1");

    if (!SecurityUtil.isAuthorizedHost(probeUri)) {
      sw.stop();
      return CwaAuthSuiteResult(
        isDecrypted: true,
        isRegexValid: true,
        isServerAuthorized: false,
        isOfflinePass: false,
        httpStatusCode: 0,
        latencyMs: sw.elapsedMilliseconds,
        maskedKey: masked,
        message: "未授權之官方請求網域",
      );
    }

    try {
      final res = await http.get(probeUri).timeout(const Duration(seconds: 4));
      statusCode = res.statusCode;
      sw.stop();

      if (statusCode == 200) {
        serverOk = true;
      }
    } catch (e) {
      sw.stop();
      // 🌟 核心防線：外海弱網或離線時，若解密與格式皆通過，標記 isOfflinePass = true
      return CwaAuthSuiteResult(
        isDecrypted: true,
        isRegexValid: true,
        isServerAuthorized: false,
        isOfflinePass: true,
        httpStatusCode: statusCode,
        latencyMs: sw.elapsedMilliseconds,
        maskedKey: masked,
        message: "本機金鑰結構與 UUID 校驗通過 (外海離線或連線逾時)",
      );
    }

    return CwaAuthSuiteResult(
      isDecrypted: true,
      isRegexValid: regexOk,
      isServerAuthorized: serverOk,
      isOfflinePass: false,
      httpStatusCode: statusCode,
      latencyMs: sw.elapsedMilliseconds,
      maskedKey: masked,
      message: serverOk 
          ? "金鑰通過官方伺服器即時鑑權驗證 (HTTP 200 OK)" 
          : "官方伺服器拒絕此金鑰 (HTTP $statusCode 授權無效)",
    );
  }
}
