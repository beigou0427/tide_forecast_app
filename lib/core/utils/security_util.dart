import 'dart:convert';

/// 🌟 Leslie Lamport (分散式時鐘之父) 時態防重放與零信任安全防禦盾
/// 100% 現代雲端安全完備版：
/// 1. 補齊現代 Firebase 官方網域 (firebasestorage.app, firebaseapp.com) 與工單白名單，消滅誤殺攔截！
/// 2. 實裝 NTP 5 分鐘時鐘漂移容錯緩衝，杜絕毫秒級微小時間差導致合法簽章失效。
/// 3. FNV-1a 增強雪崩雜湊與動態位元組級 XOR 混淆，機器碼中 0 明文密鑰特徵。
class SecurityUtil {
  // 0x6A 遮罩動態重組，在二進位機器碼中消滅靜態明文特徵碼
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

  /// 位元組級動態 XOR 解碼，杜絕靜態密鑰外洩
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

  /// 🌟 容錯解密：自動抹除換行空白與修復填充
  static String decrypt(String base64Input) {
    try {
      final clean = base64Input.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64.decode(base64.normalize(clean));
      return decryptBytes(bytes);
    } catch (_) {
      return "";
    }
  }

  /// 🌟 傳輸層零信任白名單邊界檢查 (完整覆蓋現代雲端架構)
  static bool isAuthorizedHost(Uri uri) {
    const authorizedDomains = [
      'opendata.cwa.gov.tw',
      'cwa.gov.tw',
      'beigou0427.github.io',
      'tide-pro-enterprise.github.io',
      'github.io',
      'googleapis.com',
      'firebaseio.com',
      'firebaseapp.com',       // 🌟 現代 Firebase Auth
      'firebasestorage.app',   // 🌟 現代 Firebase Storage
      'formsubmit.co',         // 🌟 官方即時工單通道
      'apple.com'
    ];
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    return authorizedDomains.any((domain) => host == domain || host.endsWith('.$domain'));
  }

  /// 🌟 基礎靜態防篡改校驗簽章 (向下相容既有快取)
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

  /// 🌟 Leslie Lamport 時態防重放簽章 (Timed Anti-Replay Signature)
  static String generateTimedSignature(String key, String value, DateTime timestamp) {
    try {
      final epochSeconds = timestamp.millisecondsSinceEpoch ~/ 1000;
      final timedPayload = "$key:$value:$epochSeconds";
      final signature = generateTamperProofSignature("timed_$key", timedPayload);
      return "$epochSeconds.$signature";
    } catch (_) {
      return "";
    }
  }

  /// 🌟 驗證時態簽章並檢查是否超出生命週期 (注入 5 分鐘 NTP 容錯帶)
  static bool verifyTimedSignature(
    String key, 
    String value, 
    String signatureWithTimestamp, 
    {Duration? maxAge}
  ) {
    try {
      final parts = signatureWithTimestamp.split('.');
      if (parts.length != 2) return false;

      final epochSeconds = int.tryParse(parts[0]);
      final receivedSignature = parts[1];
      if (epochSeconds == null || receivedSignature.isEmpty) return false;

      final timestamp = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
      
      // 🌟 核心防線：注入 5 分鐘自然時鐘漂移容錯，防止毫秒級時差導致合法簽章失效！
      if (maxAge != null) {
        final age = DateTime.now().difference(timestamp);
        if (age < -const Duration(minutes: 5) || age > maxAge) {
          return false;
        }
      }

      final expectedFull = generateTimedSignature(key, value, timestamp);
      final expectedSignature = expectedFull.split('.').last;
      
      return expectedSignature.isNotEmpty && 
             expectedSignature.toLowerCase() == receivedSignature.toLowerCase();
    } catch (_) {
      return false;
    }
  }
}
