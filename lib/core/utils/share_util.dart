import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 🌟 Rob Pike (Unix 哲學) 資源自律與檔案描述符安全釋放之分享引擎
/// 具備 GPU 原生紋理即時銷毀 (image.dispose())、沙盒暫存圖自動回收與並發互斥鎖
class ShareUtil {
  // 並發分享互斥鎖，杜絕重複連擊產生多重檔案
  static bool _isSharing = false;

  static Future<void> captureAndShare(
    GlobalKey boundaryKey, {
    required String stationName,
    String? stationId,
  }) async {
    if (_isSharing) return;
    _isSharing = true;

    try {
      // 1. 等待當前畫面繪製完畢，徹底消滅 debugNeedsPaint 斷言例外
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
      ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        // 🌟 Rob Pike 原生資源管理：立即顯式釋放底層 C++ / Skia 紋理，杜絕記憶體洩漏
        image.dispose();
      }

      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 3. 安全寫入暫存沙盒並執行 Unix 暫存檔案自動回收
      final tempDir = await getTemporaryDirectory();
      await _cleanupStaleTempReports(tempDir); // 清理過往暫存垃圾

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/tide_report_$timestamp.png');
      await file.writeAsBytes(pngBytes, flush: true);

      // 4. 計算 iPad 彈出視窗錨點，防範 iPadOS 原生 UIPopover 閃退
      Rect? shareOrigin;
      if (boundary.hasSize) {
        final originOffset = boundary.localToGlobal(Offset.zero);
        shareOrigin = originOffset & boundary.size;
      }

      // 提取乾淨站名與深度連結
      final cleanName = stationName.replaceAll(RegExp(r'[\(（].*?[\)）]'), '').trim();
      final match = RegExp(r'[\(（]([A-Za-z0-9]+)[\)）]').firstMatch(stationName);
      final sid = stationId ?? (match != null ? match.group(1) : "C6AH2");
      final webViewerUrl = "https://beigou0427.github.io/tide_forecast_app/?sid=$sid";

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
    } finally {
      _isSharing = false;
    }
  }

  /// 🌟 Unix 風格暫存垃圾回收器：保留最新 3 份檔案，刪除所有陳舊戰報圖片
  static Future<void> _cleanupStaleTempReports(Directory tempDir) async {
    try {
      final List<FileSystemEntity> entities = tempDir.listSync();
      final reportFiles = entities.whereType<File>().where(
        (f) => f.path.contains('tide_report_') && f.path.endsWith('.png')
      ).toList();

      if (reportFiles.length > 3) {
        // 依照最後修改時間排序，保留最新 3 份，其餘刪除釋放磁碟空間
        reportFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        for (int i = 3; i < reportFiles.length; i++) {
          try {
            await reportFiles[i].delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}