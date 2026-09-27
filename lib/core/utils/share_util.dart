import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtil {
  static Future<void> captureAndShare(
    GlobalKey boundaryKey, {
    required String stationName,
  }) async {
    try {
      // 1. 等待繪製幀完成，杜絕 debugNeedsPaint 斷言死機
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

      // 4. 計算 iPad 彈出視窗錨點，防範 iPadOS 原生 UIPopoverPresentationController 閃退
      Rect? shareOrigin;
      if (boundary.hasSize) {
        final originOffset = boundary.localToGlobal(Offset.zero);
        shareOrigin = originOffset & boundary.size;
      }

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: "🌊 潮汐表 PRO 老船長實時情報｜$stationName 站點數據",
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      debugPrint("🚨 [ShareUtil] 戰報生成與分享失敗: $e");
    }
  }
}
