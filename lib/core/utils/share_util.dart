import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/global_error_trap.dart';

/// 🌟 Rob Pike (Unix 哲學) 資源自律與檔案描述符安全釋放之分享引擎
/// 100% Release 模式零缺陷防禦版：
/// 1. 徹底消滅 debugNeedsPaint 在 Release 模式下拋出 Null check operator 導致分享癱瘓的致命死穴！
/// 2. 實裝 iPadOS 安全中心點錨定 (Safe Center Popover)，消滅全螢幕邊界引發的系統崩潰。
/// 3. 非同步沙盒暫存垃圾自動回收與 GPU 原生紋理即時顯式銷毀 (image.dispose())。
class ShareUtil {
  static bool _isSharing = false;

  static Future<void> captureAndShare(
    GlobalKey boundaryKey, {
    required String stationName,
    String? stationId,
  }) async {
    if (_isSharing) return;
    _isSharing = true;

    try {
      if (WidgetsBinding.instance.hasScheduledFrame) {
        await WidgetsBinding.instance.endOfFrame;
      }

      RenderRepaintBoundary? boundary;

      // 🌟 核心防線：重試檢驗以 assert 包裝 debugNeedsPaint，Release 模式以 hasSize 安全放行！
      for (int retry = 0; retry < 5; retry++) {
        final context = boundaryKey.currentContext;
        if (context == null || !context.mounted) {
          _isSharing = false;
          return;
        }
        
        final renderObj = context.findRenderObject();
        if (renderObj is RenderRepaintBoundary) {
          bool isPainting = false;
          // 唯有在 Debug 模式下才檢查 debugNeedsPaint，Release 模式下斷言自動拔除，絕不拋錯！
          assert(() {
            isPainting = renderObj.debugNeedsPaint;
            return true;
          }());

          if (!isPainting && renderObj.hasSize && !renderObj.size.isEmpty) {
            boundary = renderObj;
            break;
          }
        }
        await Future.delayed(const Duration(milliseconds: 40));
      }

      if (boundary == null) {
        debugPrint("⚠️ [ShareUtil] 無法獲取已完成繪製之 RenderRepaintBoundary，安全終止");
        _isSharing = false;
        return;
      }

      // 轉換為高解析度點陣圖 (3.0 pixel ratio 確保 Retina 螢幕清晰度)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData;
      
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        // Rob Pike 資源管理鐵律：立即顯式釋放底層 GPU 紋理，杜絕連續分享導致 OOM 閃退！
        image.dispose();
      }

      if (byteData == null) {
        _isSharing = false;
        return;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 非同步寫入暫存沙盒並自動回收陳舊垃圾
      final tempDir = await getTemporaryDirectory();
      _cleanupStaleTempReportsAsync(tempDir); // 非同步後台回收，不卡死主線程

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/tide_report_$timestamp.png');
      await file.writeAsBytes(pngBytes, flush: true);

      // 🌟 核心防線：iPadOS 安全中心點錨定（避免大矩形邊界造成 UIPopover 崩潰）
      Rect? shareOrigin;
      if (boundary.hasSize && !boundary.size.isEmpty) {
        final originOffset = boundary.localToGlobal(Offset.zero);
        shareOrigin = Rect.fromCenter(
          center: originOffset + Offset(boundary.size.width / 2, boundary.size.height / 2),
          width: 20,
          height: 20,
        );
      }

      // 提取乾淨站名與深度連結
      String cleanName = stationName.replaceAll(RegExp(r'[\(（].*?[\)）]'), '').trim();
      if (cleanName.isEmpty) cleanName = stationName;

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
    } catch (e, stack) {
      debugPrint("🚨 [ShareUtil] 戰報生成與分享失敗: $e");
      GlobalErrorTrap.recordException(
        e, 
        stackTrace: stack, 
        contextTag: "ViralShare", 
        severity: ErrorSeverity.warning, // 🌟 降為 warning，使用者取消分享不污染系統錯誤
      );
    } finally {
      _isSharing = false;
    }
  }

  /// 🌟 非同步垃圾回收器：不阻塞 UI 主線程，背景清理舊圖片
  static void _cleanupStaleTempReportsAsync(Directory tempDir) {
    tempDir.list().toList().then((entities) {
      final reportFiles = entities.whereType<File>().where(
        (f) => f.path.contains('tide_report_') && f.path.endsWith('.png')
      ).toList();

      if (reportFiles.length > 3) {
        reportFiles.sort((a, b) {
          try {
            return b.lastModifiedSync().compareTo(a.lastModifiedSync());
          } catch (_) {
            return 0;
          }
        });
        for (int i = 3; i < reportFiles.length; i++) {
          try {
            reportFiles[i].delete();
          } catch (_) {}
        }
      }
    }).catchError((_) {});
  }
}
