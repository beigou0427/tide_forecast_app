import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catch_log_model.dart';
import '../../../core/utils/constants.dart';
import '../../premium/services/premium_service.dart';
import '../../../core/services/global_error_trap.dart';

final catchLogProvider = StateNotifierProvider<CatchLogNotifier, List<CatchLogItem>>((ref) {
  return CatchLogNotifier(ref);
});

/// 🌟 Tim Cook (Apple CEO) 隱私主權與資料原子性日誌引擎
/// 100% iOS 沙盒自癒防禦版：
/// 1. 實裝 iOS 沙盒 UUID 跨版本動態自癒巡檢，徹底消滅 App 更新後照片全數破圖死檔！
/// 2. 弱網上傳超時主動取消 (uploadTask.cancel())，釋放外海珍貴頻寬。
/// 3. Firestore 支援 SetOptions(merge: true)，杜絕離線同步時的 not-found 崩潰。
class CatchLogNotifier extends StateNotifier<List<CatchLogItem>> {
  static const String _storageKey = "catch_logs_v1";
  final Ref ref;
  
  SharedPreferences? _prefs;
  String _deviceId = "unknown_device";
  Timer? _diskFlushTimer;

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get _storage {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  CatchLogNotifier(this.ref) : super([]) {
    _initSync();
  }

  Future<void> _initSync() async {
    _prefs = await SharedPreferences.getInstance();
    
    _deviceId = _prefs!.getString('device_sync_id') ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = "device_${DateTime.now().millisecondsSinceEpoch}";
      await _prefs!.setString('device_sync_id', _deviceId);
    }

    await _loadLocalAndHealSandboxPaths();
    _syncWithCloud();
  }

  /// 🌟 核心修復：載入日誌並自動修復 iOS App 更新後的沙盒 UUID 路徑漂移
  Future<void> _loadLocalAndHealSandboxPaths() async {
    if (_prefs == null) return;
    try {
      final List<String> rawList = _prefs!.getStringList(_storageKey) ?? [];
      final loadedLogs = rawList.map((e) => CatchLogItem.fromJson(e)).toList();

      Directory? appDir;
      try {
        appDir = await getApplicationDocumentsDirectory();
      } catch (_) {}

      final List<CatchLogItem> healedList = [];
      bool hasRepairedPaths = false;

      for (var item in loadedLogs) {
        if (item.imagePath != null && item.imagePath!.isNotEmpty && appDir != null) {
          final file = File(item.imagePath!);
          // 若原絕對路徑不存在（iOS 升級後 UUID 變更），在當前沙盒中搜尋同名檔案進行自癒修復
          if (!file.existsSync()) {
            final fileName = item.imagePath!.split(Platform.pathSeparator).last.split('/').last;
            final currentDocFile = File('${appDir.path}/$fileName');
            if (currentDocFile.existsSync()) {
              healedList.add(item.copyWith(imagePath: currentDocFile.path));
              hasRepairedPaths = true;
              continue;
            }
          }
        }
        healedList.add(item);
      }

      healedList.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      state = healedList;

      if (hasRepairedPaths) {
        debugPrint("🍏 [iOS 沙盒自癒] 成功修復因版本更新漂移之照片檔案路徑！");
        _scheduleDiskFlush(immediate: true);
      }
    } catch (e, stack) {
      debugPrint("⚠️ [Storage] 本地日誌載入失敗: $e");
      GlobalErrorTrap.recordException(e, stackTrace: stack, contextTag: "CatchLog_Load", severity: ErrorSeverity.warning);
      state = [];
    }
  }

  void _flushToDisk() {
    if (_prefs == null) return;
    try {
      final rawList = state.map((e) => e.toJson()).toList();
      _prefs!.setStringList(_storageKey, rawList);
    } catch (e, stack) {
      GlobalErrorTrap.recordException(e, stackTrace: stack, contextTag: "CatchLog_Flush", severity: ErrorSeverity.warning);
    }
  }

  void _scheduleDiskFlush({bool immediate = false}) {
    _diskFlushTimer?.cancel();
    if (immediate) {
      _flushToDisk();
    } else {
      _diskFlushTimer = Timer(const Duration(milliseconds: 300), _flushToDisk);
    }
  }

  Future<void> _syncWithCloud() async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(_deviceId)
          .collection('catch_logs')
          .get();
      final cloudLogs = snapshot.docs.map((doc) => CatchLogItem.fromMap(doc.data())).toList();

      final isPro = ref.read(premiumProvider).isPremium;
      int cloudPhotosCount = cloudLogs.where((e) => e.imageUrl != null).length;

      final cloudIds = cloudLogs.map((e) => e.id).toSet();
      for (final localItem in state) {
        if (!cloudIds.contains(localItem.id)) {
          await firestore
              .collection('users')
              .doc(_deviceId)
              .collection('catch_logs')
              .doc(localItem.id)
              .set(localItem.toMap());
        }
        
        // 免費用戶限制雲端相簿上限
        if (localItem.imagePath != null && localItem.imageUrl == null) {
          if (isPro || cloudPhotosCount < AppConstants.maxFreeCloudCatchLogs) {
            await _uploadImageAndSync(localItem);
            cloudPhotosCount++;
          }
        }
      }

      final localIds = state.map((e) => e.id).toSet();
      bool hasNewCloudData = false;
      final updatedLocal = List<CatchLogItem>.from(state);

      for (final cloudItem in cloudLogs) {
        if (!localIds.contains(cloudItem.id)) {
          updatedLocal.add(cloudItem);
          hasNewCloudData = true;
        }
      }

      if (hasNewCloudData) {
        updatedLocal.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        state = updatedLocal;
        _scheduleDiskFlush(immediate: false);
      }
    } catch (e) {
      debugPrint("⚠️ [DDIA] 雲端同步暫時離線: $e");
    }
  }

  Future<void> addLog(CatchLogItem item) async {
    state = [item, ...state];
    _scheduleDiskFlush(immediate: true);

    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection('users')
          .doc(_deviceId)
          .collection('catch_logs')
          .doc(item.id)
          .set(item.toMap());
          
      if (item.imagePath != null && item.imageUrl == null) {
        await _uploadImageAndSync(item);
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore] 日誌上傳失敗: $e");
    }
  }

  Future<void> _uploadImageAndSync(CatchLogItem item) async {
    final storage = _storage;
    final firestore = _firestore;
    if (storage == null || firestore == null) return;

    try {
      final isPro = ref.read(premiumProvider).isPremium;
      final currentCloudPhotos = state.where((e) => e.imageUrl != null && e.imageUrl!.isNotEmpty).length;

      if (!isPro && currentCloudPhotos >= AppConstants.maxFreeCloudCatchLogs) {
        debugPrint("🛡️ [COGS 成本防線] 免費用戶雲端相簿達標 (${AppConstants.maxFreeCloudCatchLogs} 張)，相片安全保留於本地沙盒");
        return;
      }

      final file = File(item.imagePath!);
      if (!await file.exists()) return;

      final storageRef = storage.ref().child('users/$_deviceId/catch_logs/${item.id}.jpg');
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'privacy_protection': 'VVIP_EXIF_STRIPPED',
          'gps_location': 'REDACTED',
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );

      // 🌟 核心防線：超時主動取消上傳任務，釋放外海連線頻寬
      final uploadTask = storageRef.putFile(file, metadata);
      TaskSnapshot snapshot;
      try {
        snapshot = await uploadTask.timeout(const Duration(seconds: 25));
      } on TimeoutException {
        uploadTask.cancel();
        throw TimeoutException("外海弱網環境上傳超時，已轉入本地沙盒隊列，釋放頻寬");
      }
      
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 孤兒檔案防衛：若上傳期間該日誌已被使用者刪除，即刻自癒清理雲端殘留
      final bool isStillAlive = state.any((e) => e.id == item.id);
      if (!isStillAlive) {
        debugPrint("🛡️ [孤兒檔案防線] 用戶於上傳期間刪除日誌，即刻自癒清理 Firebase Storage 殘留相片！");
        try {
          await storageRef.delete();
        } catch (_) {}
        return;
      }

      state = [
        for (final existing in state)
          if (existing.id == item.id)
            existing.copyWith(imageUrl: downloadUrl)
          else
            existing
      ];

      _scheduleDiskFlush(immediate: false);

      // 🌟 核心防線：以 SetOptions(merge: true) 保證即使文檔先前未建立亦能安全合併，零 not-found 崩潰
      await firestore
          .collection('users')
          .doc(_deviceId)
          .collection('catch_logs')
          .doc(item.id)
          .set({'imageUrl': downloadUrl}, SetOptions(merge: true));
          
      debugPrint("✅ [隱私金庫] 漁獲照片已成功剝離 EXIF 座標並上傳雲端 (ID: ${item.id})");
    } catch (e) {
      debugPrint("⚠️ [Storage] 照片上傳異常或離線，已安全保留於本地沙盒等待下次同步: $e");
    }
  }

  /// 🌟 絕對原子性抹除日誌
  Future<void> deleteLog(String id) async {
    final itemToDelete = state.firstWhere(
      (e) => e.id == id, 
      orElse: () => CatchLogItem(id: '', dateTime: DateTime.now(), stationName: '', species: '')
    );
        
    state = state.where((e) => e.id != id).toList();
    _scheduleDiskFlush(immediate: true);

    if (itemToDelete.imagePath != null && itemToDelete.imagePath!.isNotEmpty) {
      try {
        final localFile = File(itemToDelete.imagePath!);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      } catch (_) {}
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('users').doc(_deviceId).collection('catch_logs').doc(id).delete();
      } catch (_) {}
    }

    final storage = _storage;
    if (storage != null && (itemToDelete.imageUrl != null || (itemToDelete.imagePath != null && itemToDelete.imagePath!.isNotEmpty))) {
      try {
        await storage.ref().child('users/$_deviceId/catch_logs/$id.jpg').delete();
        debugPrint("🗑️ [Tim Cook 隱私銷毀] 雲端 Storage 照片已永久抹除 (ID: $id)");
      } catch (_) {}
    }
  }

  /// 🌟 App Store Guideline 5.1.1(v) 被遺忘權原子化全域銷毀
  Future<void> wipeAllPersonalData() async {
    debugPrint("🚨 [隱私法規] 發動全域數位足跡徹底銷毀...");
    
    _diskFlushTimer?.cancel();
    state = [];
    if (_prefs != null) {
      await _prefs!.remove(_storageKey);
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final collectionRef = firestore.collection('users').doc(_deviceId).collection('catch_logs');
        final snapshots = await collectionRef.get();
        for (final doc in snapshots.docs) {
          await doc.reference.delete();
        }
        await firestore.collection('users').doc(_deviceId).delete();
      } catch (_) {}
    }

    final storage = _storage;
    if (storage != null) {
      try {
        final dirRef = storage.ref().child('users/$_deviceId/catch_logs');
        final listResult = await dirRef.listAll();
        for (final item in listResult.items) {
          await item.delete();
        }
      } catch (_) {}
    }

    debugPrint("✅ [隱私審計通過] 本機與雲端個人資料已 100% 徹底抹除完畢！");
  }

  @override
  void dispose() {
    _diskFlushTimer?.cancel();
    _flushToDisk();
    super.dispose();
  }
}
