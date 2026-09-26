import 'dart:convert';

/// 🍏 Apple 首席資安工藝：零信任應用程式強固防衛盾 (Zero-Trust Security & Obfuscation Core)
class SecurityUtil {
  // 🌟 死穴 4 拆彈 1：徹底消滅靜態明文字串！
  // 以 0x6A 遮罩動態重組，在二進位機器碼中完全抓不到 tide_command_center 特徵碼
  static List<int> _getKeyBytes() {
    const masked = [
      0x1E, 0x03, 0x0E, 0x0F, 0x35, 0x09, 0x05, 0x07,
      0x07, 0x0B, 0x04, 0x0E, 0x35, 0x09, 0x0F, 0x04,
      0x1E, 0x0F, 0x18, 0x35, 0x19, 0x0B, 0x0C, 0x0F,
      0x35, 0x58, 0x5A, 0x58, 0x5E
    ];
    const xorMask = 0x6A;
    return masked.map((b) => b ^ xorMask).toList();
  }

  /// 🌟 核心：位元組級動態 XOR 解碼，杜絕明文殘留
  static String decryptBytes(List<int> bytes) {
    try {
      final keyBytes = _getKeyBytes();
      final result = <int>[];
      for (var i = 0; i < bytes.length; i++) {
        result.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      return utf8.decode(result);
    } catch (_) {
      return "";
    }
  }

  static String decrypt(String base64Input) {
    try {
      final bytes = base64.decode(base64Input);
      return decryptBytes(bytes);
    } catch (_) {
      return "";
    }
  }

  /// 🌟 死穴 4 拆彈 2：傳輸層零信任白名單邊界檢查 (防中間人重導向劫持)
  static bool isAuthorizedHost(Uri uri) {
    const authorizedDomains = [
      'opendata.cwa.gov.tw',
      'cwa.gov.tw',
      'beigou0427.github.io',
      'github.io',
      'googleapis.com',
      'firebaseio.com',
      'apple.com'
    ];
    final host = uri.host.toLowerCase();
    return authorizedDomains.any((domain) => host == domain || host.endsWith('.$domain'));
  }

  /// 🌟 死穴 4 拆彈 3：本地資產防篡改校驗簽章 (防止 Root 手機竄改代幣或 VIP 狀態)
  static String generateTamperProofSignature(String key, String value) {
    try {
      final secret = _getKeyBytes();
      final payload = utf8.encode("$key:$value");
      int hash = 0x811c9dc5; // 32-bit FNV-1a 偏移基底
      for (var b in payload) {
        hash ^= b;
        hash = (hash * 0x01000193) & 0xFFFFFFFF;
      }
      for (var s in secret) {
        hash ^= s;
        hash = (hash * 0x01000193) & 0xFFFFFFFF;
      }
      return hash.toRadixString(16).padLeft(8, '0');
    } catch (_) {
      return "";
    }
  }

  static bool verifyTamperProofSignature(String key, String value, String signature) {
    final expected = generateTamperProofSignature(key, value);
    return expected.isNotEmpty && expected.toLowerCase() == signature.toLowerCase();
  }
}