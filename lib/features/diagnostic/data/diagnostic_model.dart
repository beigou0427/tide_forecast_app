// 🌟 透過 Re-export 將全域黑盒子無縫橋接，100% 撲滅 undefined_identifier 審計錯誤
export 'package:tide_forecast_app/core/services/global_error_trap.dart';

/// 🌟 Joseph M. Juran 品質工程：純淨自檢結果資料模型
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

  factory DiagnosticResultItem.fromMap(Map<String, dynamic> map) => DiagnosticResultItem(
    category: map["category"]?.toString() ?? "General",
    title: map["title"]?.toString() ?? "未命名項目",
    passed: map["passed"] == true,
    detail: map["detail"]?.toString() ?? "",
    metric: map["metric"]?.toString() ?? "--",
  );
}