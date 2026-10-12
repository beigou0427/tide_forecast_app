import 'package:shared_preferences/shared_preferences.dart';
import '../../catch_log/data/catch_log_model.dart';

/// 🌟 漁獲日誌自檢套件 (100% 演算法 Benchmark 噪訊隔離版)
/// 1. 徹底消滅將 OS SharedPreferences 冷啟動耗時混入 CRUD 測速導致假性失敗的漏洞！
/// 2. 碼表僅精確量測「3 筆日誌 JSON 序列化 -> 寫入 -> 時間軸倒序 -> 刪除 1 筆」之真實演算法延遲。
/// 3. 完美驗證特殊符號、Emoji、Null 欄位無損雙向還原。
class CatchLogSuiteResult {
  final bool isSerializationLossless;
  final bool isCrudPersistencePassed;
  final bool isChronologicalSortAccurate;
  final bool isLatencyHealthy;
  final int latencyMicroseconds;
  final String sampleRecord;
  final String message;

  const CatchLogSuiteResult({
    required this.isSerializationLossless,
    required this.isCrudPersistencePassed,
    required this.isChronologicalSortAccurate,
    required this.isLatencyHealthy,
    required this.latencyMicroseconds,
    required this.sampleRecord,
    required this.message,
  });

  bool get isAllPassed =>
      isSerializationLossless &&
      isCrudPersistencePassed &&
      isChronologicalSortAccurate &&
      isLatencyHealthy;
}

class CatchLogDiagnosticSuite {
  static const String _testStorageKey = "catch_logs_test_suite_v1";

  static Future<CatchLogSuiteResult> run() async {
    // 1. 特殊符號、Emoji 與 Null 混合雙向序列化回溯測試
    bool serializationOk = true;
    final originalItem = CatchLogItem(
      id: "diag_special_888",
      dateTime: DateTime(2026, 9, 23, 14, 30),
      stationName: "新北石門 富貴角資料浮標 (C6AH2)",
      species: "🐟 黑毛 48.5cm 🌊",
      tideHeight: 1.82,
      waveHeight: null, // 測試無浮標浪高時的 null 容錯
      seaTemperature: 24.8,
      notes: "滿潮退2分咬中層，吃青磺蝦，拉力極強！",
      rating: 5,
    );

    final rawJson = originalItem.toJson();
    final restoredItem = CatchLogItem.fromJson(rawJson);

    if (restoredItem.id != originalItem.id ||
        restoredItem.species != originalItem.species ||
        restoredItem.tideHeight != originalItem.tideHeight ||
        restoredItem.waveHeight != null ||
        restoredItem.notes != originalItem.notes ||
        restoredItem.rating != originalItem.rating) {
      serializationOk = false;
    }

    // 🌟 核心防線：先完成 SharedPreferences 實例載入，避免 OS XML 讀取耗數十毫秒污染演算法測速！
    final prefs = await SharedPreferences.getInstance();
    
    // 2. 本地實體持久化儲存 CRUD 與微秒延遲實測 (僅量測純粹演算法與 I/O)
    final sw = Stopwatch()..start();

    // 寫入測試
    final item1 = CatchLogItem(id: "item_1", dateTime: DateTime(2026, 9, 20), stationName: "龍洞", species: "黑毛", rating: 4);
    final item2 = CatchLogItem(id: "item_2", dateTime: DateTime(2026, 9, 22), stationName: "富貴角", species: "白毛", rating: 5);
    final item3 = CatchLogItem(id: "item_3", dateTime: DateTime(2026, 9, 21), stationName: "新竹", species: "石斑", rating: 3);

    final testList = [item1, item2, item3];
    await prefs.setStringList(_testStorageKey, testList.map((e) => e.toJson()).toList());

    // 讀取與時間倒序校驗
    final readBackRaw = prefs.getStringList(_testStorageKey) ?? [];
    List<CatchLogItem> readBackList = readBackRaw.map((e) => CatchLogItem.fromJson(e)).toList();
    readBackList.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    bool sortOk = true;
    if (readBackList.length != 3 ||
        readBackList[0].id != "item_2" || // 9/22 最晚排第一
        readBackList[1].id != "item_3" || // 9/21 第二
        readBackList[2].id != "item_1") {  // 9/20 第三
      sortOk = false;
    }

    // 刪除特定 ID 實測
    readBackList.removeWhere((e) => e.id == "item_3");
    await prefs.setStringList(_testStorageKey, readBackList.map((e) => e.toJson()).toList());
    final afterDeleteRaw = prefs.getStringList(_testStorageKey) ?? [];
    final bool crudOk = afterDeleteRaw.length == 2 && !afterDeleteRaw.any((e) => e.contains("item_3"));

    // 清理測試鍵值
    await prefs.remove(_testStorageKey);
    sw.stop();

    final int latencyUs = sw.elapsedMicroseconds;
    // 🌟 實裝田口穩健門檻：低於 250ms (250,000 μs) 均判定為極速通過，消化 UFS/NVMe 寫入波動
    final bool latencyOk = latencyUs < 250000;

    String msg;
    if (!serializationOk) {
      msg = "JSON 序列化還原失真 (Emoji 或 Null 欄位損壞)";
    } else if (!crudOk) {
      msg = "持久化存儲 CRUD 讀寫刪除失敗";
    } else if (!sortOk) {
      msg = "時間軸倒序排列演算法異常";
    } else if (!latencyOk) {
      msg = "磁碟存取延遲超標 (${(latencyUs / 1000).toStringAsFixed(1)}ms)";
    } else {
      msg = "Emoji與Null序列化無損，CRUD寫讀刪精準，時間軸倒序完好 (${(latencyUs / 1000).toStringAsFixed(1)}ms)";
    }

    return CatchLogSuiteResult(
      isSerializationLossless: serializationOk,
      isCrudPersistencePassed: crudOk,
      isChronologicalSortAccurate: sortOk,
      isLatencyHealthy: latencyOk,
      latencyMicroseconds: latencyUs,
      sampleRecord: "${restoredItem.species} • ${restoredItem.stationName} (${restoredItem.tideHeight}m)",
      message: msg,
    );
  }
}
