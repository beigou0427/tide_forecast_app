enum ErrorSeverity { info, warning, error, critical }

class ErrorRecord {
  final String message;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String contextTag;

  ErrorRecord({
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.contextTag,
  });
}

/// 🌟 遵循 NASA JPL Rule #3 打造之絕對安全環形緩衝錯誤陷阱 (OOM 防禦版)
class GlobalErrorTrap {
  // 🚨 核心防線：絕對上限 50 筆，採用 FIFO 環形替換，徹底消滅無限制增長導致的 OOM 閃退！
  static const int maxRetainedErrors = 50; 
  
  static final List<String> caughtErrors = [];
  static final List<ErrorRecord> records = [];

  static bool get hasErrors => caughtErrors.isNotEmpty || records.isNotEmpty;
  static bool get hasCriticalErrors => records.any((e) => e.severity == ErrorSeverity.critical);

  static void record(String error) {
    if (!caughtErrors.contains(error)) {
      if (caughtErrors.length >= maxRetainedErrors) {
        caughtErrors.removeAt(0); // FIFO 釋放最舊的記憶體
      }
      caughtErrors.add(error);
    }
  }

  static void recordException(
    Object e, {
    StackTrace? stackTrace,
    String contextTag = "Unknown",
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final String errorStr = e.toString();
    
    // 同步記錄至簡單字串陣列 (相容舊版檢測)
    record("[$contextTag] $errorStr");

    // 寫入結構化日誌陣列 (具備時間軸與嚴重度)
    if (records.length >= maxRetainedErrors) {
      records.removeAt(0);
    }
    
    records.add(ErrorRecord(
      message: errorStr,
      severity: severity,
      timestamp: DateTime.now(),
      contextTag: contextTag,
    ));
  }

  static void clear() {
    caughtErrors.clear();
    records.clear();
  }
}