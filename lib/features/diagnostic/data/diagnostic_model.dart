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

class GlobalErrorTrap {
  static final List<String> caughtErrors = [];
  static void record(String error) {
    if (!caughtErrors.contains(error)) caughtErrors.add(error);
  }
}
