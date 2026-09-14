import 'dart:convert';

void main() {
  // 1. 在這裡輸入你想加密的字串
  String cwaKey = "你的_CWA_KEY_貼在這裡";
  String proxyToken = "你的_PROXY_TOKEN_貼在這裡";

  String internalKey = "tide_command_center_safe_2024";

  String encrypt(String plainText) {
    List<int> inputBytes = utf8.encode(plainText);
    List<int> keyBytes = utf8.encode(internalKey);
    List<int> result = [];
    for (int i = 0; i < inputBytes.length; i++) {
      result.add(inputBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    return base64.encode(utf8.encode(utf8.decode(result)));
  }

  print("\n--- 您的專屬密文 ---");
  print("CWA Key 密文: ${encrypt(cwaKey)}");
  print("Proxy Token 密文: ${encrypt(proxyToken)}");
  print("------------------\n");
}
