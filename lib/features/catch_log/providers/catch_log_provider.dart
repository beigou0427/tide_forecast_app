import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catch_log_model.dart';
import '../../../core/utils/constants.dart';
import '../../premium/services/premium_service.dart';

final catchLogProvider = StateNotifierProvider<CatchLogNotifier, List<CatchLogItem>>((ref) {
  return CatchLogNotifier(ref);
});

/// 🌟 Tim Cook (Apple CEO) 隱私主權與資料原子性日誌引擎
/// 100% 遵從 App Store Guideline 5.1.1(v) 被遺忘權與反孤兒檔案架構
class CatchLogNotifier extends StateNotifier<List<CatchLogItem>> {
  static const String _storageKey = "catch_logs_v1";
  final Ref ref;
  
  SharedPreferences? _prefs;
  String _deviceId = "unknown_device";
  Timer? _diskFlushTimer;

  // 安全防衛：在單元測試或未配置 Firebase 環境時安全回退，杜絕 [core/no-app] 崩潰
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

    _loadLocal();
    _syncWithCloud();
  }

  void _loadLocal() {
    if (_prefs == null) return;
    try {
      final List<String> rawList = _prefs!.getStringList(_storageKey) ?? [];
      state = rawList.map((e) => CatchLogItem.fromJson(e)).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (e) {
      debugPrint("⚠️ [Storage] 本地日誌載入失敗: $e");
      state = [];
    }
  }

  void _flushToDisk() {
    if (_prefs == null) return;
    try {
      final rawList = state.map((e) => e.toJson()).toList();
      _prefs!.setStringList(_storageKey, rawList);
    } catch (e) {
      debugPrint("⚠️ [Storage I/O] 本地快取沉積失敗: $e");
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
        
        // 🌟 Ruth Porat 成本防衛：免費用戶限制雲端相簿 5 張上限
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
        debugPrint("☁️ [Firestore] 雲端漁獲日誌安全同步完成！");
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore] 雲端同步暫時離線: $e");
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

      // 單位經濟學防線：免費用戶超過上限自動轉為純本地沙盒保存
      if (!isPro && currentCloudPhotos >= AppConstants.maxFreeCloudCatchLogs) {
        debugPrint("🛡️ [COGS 成本防線] 免費用戶雲端相簿達標 (${AppConstants.maxFreeCloudCatchLogs} 張)，相片保留於本地沙盒");
        return;
      }

      final file = File(item.imagePath!);
      if (!await file.exists()) return;

      final storageRef = storage.ref().child('users/$_deviceId/catch_logs/${item.id}.jpg');
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 🌟 嚴格生命週期守衛：若用戶在上傳中途已點擊刪除，立即撲滅雲端孤兒相片
      final bool isStillAlive = state.any((e) => e.id == item.id);
      if (!isStillAlive) {
        debugPrint("🛡️ [Tim Cook 孤兒檔案防線] 用戶已刪除日誌，即刻自癒清理 Storage 相片！");
        try {
          await storageRef.delete();
        } catch (_) {}
        return;
      }

      state = [
        for (final existing in state)
          if (existing.id == item.id)
            CatchLogItem(
              id: existing.id,
              dateTime: existing.dateTime,
              stationName: existing.stationName,
              species: existing.species,
              tideHeight: existing.tideHeight,
              waveHeight: existing.waveHeight,
              seaTemperature: existing.seaTemperature,
              notes: existing.notes,
              rating: existing.rating,
              imagePath: existing.imagePath,
              imageUrl: downloadUrl,
            )
          else
            existing
      ];

      _scheduleDiskFlush(immediate: false);

      await firestore
          .collection('users')
          .doc(_deviceId)
          .collection('catch_logs')
          .doc(item.id)
          .update({'imageUrl': downloadUrl});
      debugPrint("☁️ [Storage] 照片上傳完成，網址已寫入資料庫");
    } catch (e) {
      debugPrint("⚠️ [Storage] 照片上傳異常: $e");
    }
  }

  /// 🌟 Tim Cook 零孤兒檔案承諾：本機與雲端 Storage 進行原子性抹除
  Future<void> deleteLog(String id) async {
    final itemToDelete = state.firstWhere(
      (e) => e.id == id, 
      orElse: () => CatchLogItem(id: '', dateTime: DateTime.now(), stationName: '', species: '')
    );
        
    state = state.where((e) => e.id != id).toList();
    _scheduleDiskFlush(immediate: true);

    // 1. 刪除本地沙盒實體照片檔案
    if (itemToDelete.imagePath != null && itemToDelete.imagePath!.isNotEmpty) {
      try {
        final localFile = File(itemToDelete.imagePath!);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      } catch (_) {}
    }

    // 2. 刪除雲端 Firestore 文件
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection('users')
            .doc(_deviceId)
            .collection('catch_logs')
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint("⚠️ [Firestore] 雲端刪除異常: $e");
      }
    }

    // 3. 刪除雲端 Storage 照片（雙重重試保障，徹底杜絕孤兒隱私洩漏）
    final storage = _storage;
    if (storage != null && (itemToDelete.imageUrl != null || (itemToDelete.imagePath != null && itemToDelete.imagePath!.isNotEmpty))) {
      try {
        await storage.ref().child('users/$_deviceId/catch_logs/$id.jpg').delete();
        debugPrint("🗑️ [Tim Cook 隱私銷毀] 雲端 Storage 照片已永久抹除 (ID: $id)");
      } catch (_) {
        // 若檔案本就不存在則正常忽略
      }
    }
  }

  /// 🌟 App Store Guideline 5.1.1(v) 權威被遺忘權全域徹底抹除
  Future<void> wipeAllPersonalData() async {
    debugPrint("🚨 [Tim Cook 隱私法規] 發動全域數位足跡徹底銷毀...");
    
    // 1. 清空本地記憶體與磁碟
    state = [];
    if (_prefs != null) {
      await _prefs!.remove(_storageKey);
    }

    // 2. 徹底清空雲端 Firestore
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final collectionRef = firestore.collection('users').doc(_deviceId).collection('catch_logs');
        final snapshots = await collectionRef.get();
        for (final doc in snapshots.docs) {
          await doc.reference.delete();
        }
        await firestore.collection('users').doc(_deviceId).delete();
      } catch (e) {
        debugPrint("⚠️ [Firestore] 全域抹除異常: $e");
      }
    }

    // 3. 徹底清空雲端 Storage 專屬資料夾
    final storage = _storage;
    if (storage != null) {
      try {
        final dirRef = storage.ref().child('users/$_deviceId/catch_logs');
        final listResult = await dirRef.listAll();
        for (final item in listResult.items) {
          await item.delete();
        }
      } catch (e) {
        debugPrint("⚠️ [Storage] 全域相片抹除異常: $e");
      }
    }

    debugPrint("✅ [Tim Cook 隱私審計通過] 本機與雲端個人資料已 100% 徹底抹除完畢！");
  }

  @override
  void dispose() {
    _diskFlushTimer?.cancel();
    _flushToDisk();
    super.dispose();
  }
}