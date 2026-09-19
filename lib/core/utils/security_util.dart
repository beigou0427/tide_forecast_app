import 'dart:convert';

/// 專業級位元組混淆工具
class SecurityUtil {
  static const String _internalKey = "tide_command_center_safe_2024";

  /// 🌟 核心：直接針對位元組進行 XOR 還原，完全杜絕 UTF-8 解碼失敗問題
  static String decryptBytes(List<int> bytes) {
    try {
      final keyBytes = utf8.encode(_internalKey);
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
}

