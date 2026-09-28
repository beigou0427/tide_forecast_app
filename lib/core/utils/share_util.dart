import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Elena Verna 產品主導成長（PLG）：自帶深層連結的病毒裂變分享引擎
class ShareUtil {
  static Future<void> captureAndShare(
    GlobalKey boundaryKey, {
    required String stationName,
    String? stationId,
  }) async {
    try {
      // 1. 等待幀繪製完成，杜絕 debugNeedsPaint 斷言死機
      if (WidgetsBinding.instance.hasScheduledFrame) {
        await WidgetsBinding.instance.endOfFrame;
      }

      RenderRepaintBoundary? boundary;
      for (int retry = 0; retry < 5; retry++) {
        final context = boundaryKey.currentContext;
        if (context == null || !context.mounted) return;
        
        final renderObj = context.findRenderObject();
        if (renderObj is RenderRepaintBoundary && !renderObj.debugNeedsPaint) {
          boundary = renderObj;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 40));
      }

      if (boundary == null) {
        debugPrint("⚠️ [ShareUtil] 無法獲取已完成繪製之 RenderRepaintBoundary");
        return;
      }

      // 2. 轉換為高解析度點陣圖
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 3. 安全寫入暫存沙盒並強制落盤
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/tide_report_$timestamp.png');
      await file.writeAsBytes(pngBytes, flush: true);

      // 4. 計算 iPad 彈出視窗錨點，防範 iPadOS 原生 UIPopover 閃退
      Rect? shareOrigin;
      if (boundary.hasSize) {
        final originOffset = boundary.localToGlobal(Offset.zero);
        shareOrigin = originOffset & boundary.size;
      }

      // 🌟 Elena Verna PLG 核心武器：自動提取測站代碼並組裝帶參 Web 深度連結
      final cleanName = stationName.replaceAll(RegExp(r'\(.*?\)'), '').trim();
      final match = RegExp(r'\(([A-Za-z0-9]+)\)').firstMatch(stationName);
      final sid = stationId ?? (match != null ? match.group(1) : "C6AH2");
      final webViewerUrl = "https://beigou0427.github.io/tide_forecast_app/?sid=$sid";

      // 高轉化率社群傳播文案（圖片 + 連結 + 商店搜尋錨點）
      final String viralShareText = """🌊【老船長海象實時情報】$cleanName
⚡ 中央氣象署 85 測站光纖直連 · 0 延遲湧浪與風速水象

📲 點擊即刻在手機瀏覽器查看 85 站光纖實況雷達：
👉 $webViewerUrl

🎣 釣友出海決策必備神器，請在 App Store 搜尋：「潮汐表」或「潮汐表 Pro」""";

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: viralShareText,
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      debugPrint("🚨 [ShareUtil] 戰報生成與分享失敗: $e");
    }
  }
}
