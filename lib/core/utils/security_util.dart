import 'dart:convert';

/// 專業級字串混淆工具
/// 透過 XOR 運算與 Base64 編碼，防止 API Key 在二進位檔案中以明文顯示
class SecurityUtil {
  // 混淆金鑰 (自定義，建議不要太短)
  static const String _internalKey = "tide_command_center_safe_2024";

  /// 混淆/還原字串
  /// 原理：A XOR B = C, 則 C XOR B = A
  static String toggle(String input) {
    List<int> inputBytes = utf8.encode(input);
    List<int> keyBytes = utf8.encode(_internalKey);
    List<int> result = [];

    for (int i = 0; i < inputBytes.length; i++) {
      result.add(inputBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return utf8.decode(result);
  }

  /// 輔助方法：將混淆後的 Base64 字串還原為明文
  static String decrypt(String base64Input) {
    try {
      String obfuscated = utf8.decode(base64.decode(base64Input));
      return toggle(obfuscated);
    } catch (e) {
      return "";
    }
  }

  /// 輔助方法：用於產生混淆字串 (僅在開發階段手動呼叫)
  static String encrypt(String plainText) {
    String obfuscated = toggle(plainText);
    return base64.encode(utf8.encode(obfuscated));
  }
}
