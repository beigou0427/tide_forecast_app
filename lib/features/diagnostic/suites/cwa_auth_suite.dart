import 'package:http/http.dart' as http;
import '../../../../core/utils/constants.dart';

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
    
    // 1. 真實解密
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

    // 2. 嚴格比對 CWA 官方 UUID 格式 (8-4-4-4-12 16進制大寫)
    final regex = RegExp(r'^CWA-[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$');
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

    // 3. 真實向氣象署官方 API 發起 1 筆輕量化握手驗證
    int statusCode = 0;
    bool serverOk = false;
    try {
      final probeUrl = "https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization=$key&limit=1";
      final res = await http.get(Uri.parse(probeUrl)).timeout(const Duration(seconds: 6));
      statusCode = res.statusCode;
      sw.stop();

      if (statusCode == 200) {
        serverOk = true;
      }
    } catch (e) {
      sw.stop();
      return CwaAuthSuiteResult(
        isDecrypted: true,
        isRegexValid: true,
        isServerAuthorized: false,
        httpStatusCode: statusCode,
        latencyMs: sw.elapsedMilliseconds,
        maskedKey: masked,
        message: "連線氣象署官方伺服器逾時 ($e)",
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
