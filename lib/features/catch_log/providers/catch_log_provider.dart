import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catch_log_model.dart';

final catchLogProvider = StateNotifierProvider<CatchLogNotifier, List<CatchLogItem>>((ref) {
  return CatchLogNotifier();
});

class CatchLogNotifier extends StateNotifier<List<CatchLogItem>> {
  static const String _storageKey = "catch_logs_v1";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String _deviceId = "unknown_device";

  CatchLogNotifier() : super([]) {
    _initSync();
  }

  Future<void> _initSync() async {
    final prefs = await SharedPreferences.getInstance();
    
    _deviceId = prefs.getString('device_sync_id') ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = "device_${DateTime.now().millisecondsSinceEpoch}";
      await prefs.setString('device_sync_id', _deviceId);
    }

    _loadLocal(prefs);
    _syncWithCloud();
  }

  void _loadLocal(SharedPreferences prefs) {
    try {
      final List<String> rawList = prefs.getStringList(_storageKey) ?? [];
      state = rawList.map((e) => CatchLogItem.fromJson(e)).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (_) {
      state = [];
    }
  }

  Future<void> _syncWithCloud() async {
    try {
      final snapshot = await _firestore.collection('users').doc(_deviceId).collection('catch_logs').get();
      final cloudLogs = snapshot.docs.map((doc) => CatchLogItem.fromMap(doc.data())).toList();

      final cloudIds = cloudLogs.map((e) => e.id).toSet();
      for (final localItem in state) {
        if (!cloudIds.contains(localItem.id)) {
          await _firestore.collection('users').doc(_deviceId).collection('catch_logs').doc(localItem.id).set(localItem.toMap());
        }
        
        // 🌟 死穴 2 修復：序列化執行上傳，杜絕多個非同步任務同時踩踏 state
        if (localItem.imagePath != null && localItem.imageUrl == null) {
          await _uploadImageAndSync(localItem);
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_storageKey, updatedLocal.map((e) => e.toJson()).toList());
        debugPrint("☁️ [Firestore] 雲端漁獲日誌同步完成，成功還原遺失資料！");
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore] 雲端同步暫時無法連線: $e");
    }
  }

  Future<void> addLog(CatchLogItem item) async {
    final updated = [item, ...state];
    state = updated;
    
    final prefs = await SharedPreferences.getInstance();
    final rawList = updated.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, rawList);

    try {
      await _firestore.collection('users').doc(_deviceId).collection('catch_logs').doc(item.id).set(item.toMap());
      if (item.imagePath != null && item.imageUrl == null) {
        _uploadImageAndSync(item);
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore] 日誌上傳失敗: $e");
    }
  }

  // 🌟 核心防禦：具備「防詐屍安全檢查」的照片上傳器
  Future<void> _uploadImageAndSync(CatchLogItem item) async {
    try {
      final file = File(item.imagePath!);
      if (!await file.exists()) return;

      final storageRef = _storage.ref().child('users/$_deviceId/catch_logs/${item.id}.jpg');
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 🚨 核心防詐屍防線：檢查這段上傳期間，使用者是否已經把這筆日誌刪除了！
      final bool isStillAlive = state.any((e) => e.id == item.id);
      if (!isStillAlive) {
        debugPrint("🛡️ [防詐屍攔截] 用戶已在照片上傳期間刪除此日誌，中止寫入並清理孤兒檔案！");
        try {
          await storageRef.delete();
        } catch (_) {}
        return;
      }

      // 原子化替換狀態，確保不覆蓋其他併發更新
      final updatedItem = CatchLogItem(
        id: item.id,
        dateTime: item.dateTime,
        stationName: item.stationName,
        species: item.species,
        tideHeight: item.tideHeight,
        waveHeight: item.waveHeight,
        seaTemperature: item.seaTemperature,
        notes: item.notes,
        rating: item.rating,
        imagePath: item.imagePath,
        imageUrl: downloadUrl,
      );

      state = [
        for (final existing in state)
          if (existing.id == item.id) updatedItem else existing
      ];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, state.map((e) => e.toJson()).toList());

      // 再次確認雲端紀錄存在才執行 update
      await _firestore.collection('users').doc(_deviceId).collection('catch_logs').doc(item.id).update({'imageUrl': downloadUrl});
      debugPrint("☁️ [Storage] 照片上傳成功！網址已安全寫入資料庫。");
    } catch (e) {
      debugPrint("⚠️ [Storage] 照片上傳失敗或紀錄已不存在: $e");
    }
  }

  Future<void> deleteLog(String id) async {
    final itemToDelete = state.firstWhere(
      (e) => e.id == id, 
      orElse: () => CatchLogItem(id: '', dateTime: DateTime.now(), stationName: '', species: '')
    );
        
    // 立即從狀態與本地快取中抹除
    state = state.where((e) => e.id != id).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.map((e) => e.toJson()).toList());

    try {
      await _firestore.collection('users').doc(_deviceId).collection('catch_logs').doc(id).delete();
      
      // 不論當前是否有 imageUrl，一併嘗試清除對應的 storage 檔案，防範殘留
      await _storage.ref().child('users/$_deviceId/catch_logs/$id.jpg').delete();
    } catch (e) {
      debugPrint("⚠️ [Firestore/Storage] 雲端刪除失敗或檔案本就不存在: $e");
    }
  }
}