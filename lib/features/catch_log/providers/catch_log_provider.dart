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

class CatchLogNotifier extends StateNotifier<List<CatchLogItem>> {
  static const String _storageKey = "catch_logs_v1";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Ref ref;
  
  SharedPreferences? _prefs;
  String _deviceId = "unknown_device";
  Timer? _diskFlushTimer;

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
      _diskFlushTimer = Timer(const Duration(milliseconds: 400), _flushToDisk);
    }
  }

  Future<void> _syncWithCloud() async {
    try {
      final snapshot = await _firestore
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
          await _firestore
              .collection('users')
              .doc(_deviceId)
              .collection('catch_logs')
              .doc(localItem.id)
              .set(localItem.toMap());
        }
        
        // 🌟 Ruth Porat 單位經濟學防禦：免費用戶限制雲端相簿 5 張上限
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
        debugPrint("☁️ [Firestore] 雲端漁獲日誌同步完成！");
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore] 雲端同步暫時無法連線: $e");
    }
  }

  Future<void> addLog(CatchLogItem item) async {
    state = [item, ...state];
    _scheduleDiskFlush(immediate: true);

    try {
      await _firestore
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
    try {
      final isPro = ref.read(premiumProvider).isPremium;
      final currentCloudPhotos = state.where((e) => e.imageUrl != null && e.imageUrl!.isNotEmpty).length;

      // 🌟 Ruth Porat 成本邊界守衛：免費用戶超過 5 張停止上傳雲端，照片安全保留於本機沙盒
      if (!isPro && currentCloudPhotos >= AppConstants.maxFreeCloudCatchLogs) {
        debugPrint("🛡️ [Ruth Porat COGS防線] 免費用戶雲端相簿已達上限 (${AppConstants.maxFreeCloudCatchLogs} 張)，相片保留於本地沙盒，保護伺服器成本");
        return;
      }

      final file = File(item.imagePath!);
      if (!await file.exists()) return;

      final storageRef = _storage.ref().child('users/$_deviceId/catch_logs/${item.id}.jpg');
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final bool isStillAlive = state.any((e) => e.id == item.id);
      if (!isStillAlive) {
        debugPrint("🛡️ [防孤兒檔案] 用戶已在此期間刪除日誌，清理檔案");
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

      await _firestore
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

  Future<void> deleteLog(String id) async {
    final itemToDelete = state.firstWhere(
      (e) => e.id == id, 
      orElse: () => CatchLogItem(id: '', dateTime: DateTime.now(), stationName: '', species: '')
    );
        
    state = state.where((e) => e.id != id).toList();
    _scheduleDiskFlush(immediate: true);

    try {
      await _firestore
          .collection('users')
          .doc(_deviceId)
          .collection('catch_logs')
          .doc(id)
          .delete();
      
      if (itemToDelete.imageUrl != null || (itemToDelete.imagePath != null && itemToDelete.imagePath!.isNotEmpty)) {
        await _storage.ref().child('users/$_deviceId/catch_logs/$id.jpg').delete();
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore/Storage] 雲端刪除異常: $e");
    }
  }

  @override
  void dispose() {
    _diskFlushTimer?.cancel();
    _flushToDisk();
    super.dispose();
  }
}
