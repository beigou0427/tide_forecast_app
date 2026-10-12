export '../../../core/services/global_error_trap.dart';

/// 🌟 診斷中心單項檢驗結果實體
class DiagnosticResultItem {
  final String category;
  final String title;
  final bool passed;
  final String detail;
  final String metric;

  const DiagnosticResultItem({
    required this.category,
    required this.title,
    required this.passed,
    required this.detail,
    required this.metric,
  });

  Map<String, dynamic> toMap() => {
    "category": category,
    "title": title,
    "passed": passed,
    "detail": detail,
    "metric": metric,
  };
}
