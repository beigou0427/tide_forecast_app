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
    
    // 🌟 1. 產生或讀取裝置綁定 ID
    _deviceId = prefs.getString('device_sync_id') ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = "device_${DateTime.now().millisecondsSinceEpoch}";
      await prefs.setString('device_sync_id', _deviceId);
    }

    // 🌟 2. 優先載入本地離線快取 (Offline First)
    _loadLocal(prefs);

    // 🌟 3. 背景啟動 Firestore 雙向雲端同步
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
        
        // 🌟 補償機制：如果本地有照片但沒有雲端網址，觸發背景上傳
        if (localItem.imagePath != null && localItem.imageUrl == null) {
          _uploadImageAndSync(localItem);
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
    // 1. 寫入本地狀態 (Optimistic UI)
    final updated = [item, ...state];
    state = updated;
    
    final prefs = await SharedPreferences.getInstance();
    final rawList = updated.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, rawList);

    // 2. 寫入雲端 Firestore 與觸發照片上傳
    try {
      await _firestore.collection('users').doc(_deviceId).collection('catch_logs').doc(item.id).set(item.toMap());
      if (item.imagePath != null && item.imageUrl == null) {
        _uploadImageAndSync(item);
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore] 日誌上傳失敗: $e");
    }
  }

  // 🌟 核心功能：背景上傳實體照片至 Firebase Storage 並回填網址
  Future<void> _uploadImageAndSync(CatchLogItem item) async {
    try {
      final file = File(item.imagePath!);
      if (!await file.exists()) return;

      final ref = _storage.ref().child('users/$_deviceId/catch_logs/${item.id}.jpg');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 更新資料模型
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
        imageUrl: downloadUrl, // 🌟 注入剛取得的雲端網址
      );

      // 更新記憶體狀態與硬碟快取
      final updatedList = state.map((e) => e.id == item.id ? updatedItem : e).toList();
      state = updatedList;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, updatedList.map((e) => e.toJson()).toList());

      // 更新雲端 Firestore
      await _firestore.collection('users').doc(_deviceId).collection('catch_logs').doc(item.id).update({'imageUrl': downloadUrl});
      debugPrint("☁️ [Storage] 照片上傳成功！網址已無縫寫入資料庫。");
    } catch (e) {
      debugPrint("⚠️ [Storage] 照片上傳失敗: $e");
    }
  }

  Future<void> deleteLog(String id) async {
    // 找出要刪除的物件，以便後續清理雲端照片
    final itemToDelete = state.firstWhere(
      (e) => e.id == id, 
      orElse: () => CatchLogItem(id: '', dateTime: DateTime.now(), stationName: '', species: '')
    );
        
    final updated = state.where((e) => e.id != id).toList();
    state = updated;

    final prefs = await SharedPreferences.getInstance();
    final rawList = updated.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, rawList);

    try {
      // 刪除 Firestore 紀錄
      await _firestore.collection('users').doc(_deviceId).collection('catch_logs').doc(id).delete();
      
      // 🌟 若存在雲端照片，一併實體刪除，絕不浪費成本
      if (itemToDelete.imageUrl != null || itemToDelete.imagePath != null) {
        await _storage.ref().child('users/$_deviceId/catch_logs/$id.jpg').delete();
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore/Storage] 雲端刪除失敗: $e");
    }
  }
}