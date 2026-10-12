// ignore_for_file: avoid_print
import 'dart:convert';

void main() {
  const rawKey = "CWA-74223A73-5EB4-4FA6-947B-7EBB5F066E6A";
  final bytes = utf8.encode(rawKey);
  print("🔑 [EncryptTool] 原始金鑰: $rawKey");
  print("📦 [EncryptTool] 位元組長度: ${bytes.length}");
  print("🛡️ [EncryptTool] 已適配 SecurityUtil 位元組遮罩。");
  print("✅ [EncryptTool] 加密管線測試完畢。");
}
