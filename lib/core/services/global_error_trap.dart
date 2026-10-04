import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ErrorSeverity { info, warning, error, critical }

class StructuredErrorRecord {
  final String message;
  final String contextTag;
  final DateTime timestamp;
  final ErrorSeverity severity;
  final String? stackTraceString;

  const StructuredErrorRecord({
    required this.message,
    required this.contextTag,
    required this.timestamp,
    this.severity = ErrorSeverity.error,
    this.stackTraceString,
  });

  Map<String, dynamic> toMap() => {
    'message': message,
    'contextTag': contextTag,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity.name,
    'stackTrace': stackTraceString,
  };

  factory StructuredErrorRecord.fromMap(Map<String, dynamic> map) => StructuredErrorRecord(
    message: map['message']?.toString() ?? '',
    contextTag: map['contextTag']?.toString() ?? 'General',
    timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
    severity: ErrorSeverity.values.firstWhere(
      (e) => e.name == map['severity'],
      orElse: () => ErrorSeverity.error,
    ),
    stackTraceString: map['stackTrace']?.toString(),
  );

  String toJson() => jsonEncode(toMap());
  factory StructuredErrorRecord.fromJson(String source) => StructuredErrorRecord.fromMap(jsonDecode(source));
}

/// 🌟 消除非同步落盤競態條件之全域航太黑盒子記錄器
class GlobalErrorTrap {
  static final List<String> caughtErrors = [];
  
  static const int _maxTelemetryCapacity = 60;
  static final List<StructuredErrorRecord> _records = [];
  static const String _blackBoxDiskKey = "spacex_blackbox_telemetry_v1";

  // 🌟 磁碟寫入 Future 錨點 (消除讀寫競態條件)
  static Future<void>? _pendingFlush;

  static List<StructuredErrorRecord> get records => List.unmodifiable(_records);

  static void record(
    String error, {
    String contextTag = "General", 
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    if (!caughtErrors.contains(error)) {
      caughtErrors.add(error);
    }

    final recordItem = StructuredErrorRecord(
      message: error,
      contextTag: contextTag,
      timestamp: DateTime.now(),
      severity: severity,
    );

    _appendRecord(recordItem);
    
    if (kDebugMode) {
      debugPrint("🛡️ [航太遙測:$contextTag][${severity.name.toUpperCase()}] $error");
    }
  }

  static void recordException(
    dynamic error, {
    StackTrace? stackTrace,
    String contextTag = "Uncaught",
    ErrorSeverity severity = ErrorSeverity.critical,
    bool failFastInDebug = false,
  }) {
    final errorMsg = error.toString();
    if (!caughtErrors.contains(errorMsg)) {
      caughtErrors.add(errorMsg);
    }

    final recordItem = StructuredErrorRecord(
      message: errorMsg,
      contextTag: contextTag,
      timestamp: DateTime.now(),
      severity: severity,
      stackTraceString: stackTrace?.toString(),
    );

    _appendRecord(recordItem);

    if (kDebugMode && failFastInDebug) {
      assert(() {
        debugPrint("💥 [Fail-Fast 觸發] $contextTag: $error\n$stackTrace");
        return true;
      }());
    }
  }

  static void _appendRecord(StructuredErrorRecord record) {
    if (_records.length >= _maxTelemetryCapacity) {
      _records.removeAt(0);
    }
    _records.add(record);

    if (record.severity == ErrorSeverity.critical) {
      _triggerAsyncFlush();
    }
  }

  static Future<void> _triggerAsyncFlush() {
    final future = () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final list = _records.map((r) => r.toJson()).toList();
        await prefs.setStringList(_blackBoxDiskKey, list);
      } catch (_) {}
    }();
    _pendingFlush = future;
    return future;
  }

  /// 🌟 事故自癒：開機還原前次黑盒子飛行記錄 (具備寫入等待鎖，消滅 Race Condition)
  static Future<List<StructuredErrorRecord>> recoverPriorFlightRecords() async {
    // 若當前有正在寫入中的磁碟任務，強制等待落盤完成
    if (_pendingFlush != null) {
      await _pendingFlush;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      var list = prefs.getStringList(_blackBoxDiskKey);
      
      // 保底自癒：若磁碟尚未寫入但記憶體有緊急記錄，立即補償落盤
      if ((list == null || list.isEmpty) && _records.isNotEmpty) {
        await _triggerAsyncFlush();
        list = prefs.getStringList(_blackBoxDiskKey);
      }

      return (list ?? []).map((e) => StructuredErrorRecord.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static String exportTelemetrySnapshot() {
    final data = {
      'system': 'TidePro Marine Telemetry Engine',
      'exported_at': DateTime.now().toIso8601String(),
      'total_anomalies': _records.length,
      'records': _records.map((r) => r.toMap()).toList(),
    };
    return jsonEncode(data);
  }

  static void clear() {
    caughtErrors.clear();
    _records.clear();
    _pendingFlush = null;
    SharedPreferences.getInstance().then((prefs) => prefs.remove(_blackBoxDiskKey)).catchError((_) => false);
  }

  static bool get hasErrors => caughtErrors.isNotEmpty || _records.any((r) => r.severity == ErrorSeverity.critical);
  static int get totalRecords => _records.length;
}