import 'package:http/http.dart' as http;
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/security_util.dart';

class CwaAuthSuiteResult {
  final bool isDecrypted;
  final bool isRegexValid;
  final bool isServerAuthorized;
  final int httpStatusCode;
  final int latencyMs;
  final String maskedKey;
  final String message;

  const CwaAuthSuiteResult({
    required this.isDecrypted,
    required this.isRegexValid,
    required this.isServerAuthorized,
    required this.httpStatusCode,
    required this.latencyMs,
    required this.maskedKey,
    required this.message,
  });

  bool get isAllPassed => isDecrypted && isRegexValid && isServerAuthorized;
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
        httpStatusCode: 0,
        latencyMs: sw.elapsedMilliseconds,
        maskedKey: masked,
        message: "未授權之官方請求網域",
      );
    }

    try {
      final res = await http.get(probeUri).timeout(const Duration(seconds: 5));
      statusCode = res.statusCode;
      sw.stop();

      if (statusCode == 200) {
        serverOk = true;
      }
    } catch (e) {
      sw.stop();
      // 外海弱網或超時處理：格式合規但連線超時
      return CwaAuthSuiteResult(
        isDecrypted: true,
        isRegexValid: true,
        isServerAuthorized: false,
        httpStatusCode: statusCode,
        latencyMs: sw.elapsedMilliseconds,
        maskedKey: masked,
        message: "官方伺服器連線逾時 ($e)，但本機金鑰結構校驗合格",
      );
    }

    return CwaAuthSuiteResult(
      isDecrypted: true,
      isRegexValid: regexOk,
      isServerAuthorized: serverOk,
      httpStatusCode: statusCode,
      latencyMs: sw.elapsedMilliseconds,
      maskedKey: masked,
      message: serverOk 
          ? "金鑰通過官方伺服器即時鑑權驗證 (HTTP 200 OK)" 
          : "官方伺服器拒絕此金鑰 (HTTP $statusCode 授權無效)",
    );
  }
}
