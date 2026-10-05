import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/diagnostic_model.dart';
import '../services/diagnostic_runner.dart';
import '../../../core/services/global_error_trap.dart';

class DiagnosticState {
  final bool isRunning;
  final double progress;
  final String statusText;
  final List<DiagnosticResultItem> results;
  final String selectedCategory;

  const DiagnosticState({
    this.isRunning = false,
    this.progress = 0.0,
    this.statusText = "點擊下方按鈕，執行全系統 41 項海事穿透性與增長實機自檢",
    this.results = const [],
    this.selectedCategory = "全部",
  });

  DiagnosticState copyWith({
    bool? isRunning,
    double? progress,
    String? statusText,
    List<DiagnosticResultItem>? results,
    String? selectedCategory,
  }) {
    return DiagnosticState(
      isRunning: isRunning ?? this.isRunning,
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
      results: results ?? this.results,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

final diagnosticStateProvider = StateNotifierProvider<DiagnosticNotifier, DiagnosticState>((ref) {
  return DiagnosticNotifier();
});

/// 🌟 經海事嚴謹標準重塑之 41 項全系統自檢控制狀態機 (具備例外自癒防禦)
class DiagnosticNotifier extends StateNotifier<DiagnosticState> {
  DiagnosticNotifier() : super(const DiagnosticState());

  void setCategory(String cat) {
    state = state.copyWith(selectedCategory: cat);
  }

  Future<void> executeDiagnostics(WidgetRef ref) async {
    state = state.copyWith(
      isRunning: true,
      progress: 0.0,
      results: [],
      statusText: "正在發動 41 項專家級海事穿透性與行銷增長自檢套件...",
    );

    List<DiagnosticResultItem> results = [];

    try {
      results = await DiagnosticRunner.runAll(
        ref: ref,
        onProgress: (prog, status) {
          if (mounted) {
            state = state.copyWith(progress: prog, statusText: status);
          }
        },
      );

      final int totalCount = results.length;
      final int passCount = results.where((r) => r.passed).length;

      if (mounted) {
        state = state.copyWith(
          isRunning: false,
          progress: 1.0,
          results: results,
          statusText: "全系統 $totalCount 項海事穿透性自檢完成（通過 $passCount / $totalCount）",
        );
      }

      _printTerminalReport(results);
    } catch (e, stack) {
      // 🌟 核心防線：杜絕診斷中途崩潰導致 UI 永久卡死轉圈
      GlobalErrorTrap.recordException(
        e,
        stackTrace: stack,
        contextTag: "DiagnosticNotifier",
        severity: ErrorSeverity.error,
      );

      if (mounted) {
        state = state.copyWith(
          isRunning: false,
          progress: 1.0,
          statusText: "⚠️ 自檢流程遭遇非預期例外，已由黑盒子攔截安全降級！",
        );
      }
    }
  }

  void _printTerminalReport(List<DiagnosticResultItem> results) {
    final int totalCount = results.length;
    final int passCount = results.where((r) => r.passed).length;
    final int errorCount = results.where((r) => !r.passed).length;

    debugPrint("\n============================================================");
    debugPrint("      ⚓ Tide Pro 全系統 $totalCount 項海事實機穿透性自檢終端報告      ");
    debugPrint("============================================================");
    for (final r in results) {
      final String mark = r.passed ? '✅' : '❌';
      final String title = r.title.padRight(32);
      final String metric = r.metric.padLeft(14);
      debugPrint("║ $title : $mark $metric ║ ${r.detail}");
    }
    debugPrint("============================================================");
    debugPrint("║ 檢驗結論: 通過 $passCount / $totalCount ║ 失敗 $errorCount ║ 壞死指標: 0 ║ 狀態: ${errorCount == 0 ? '100% HEALTHY' : 'WARNINGS FOUND'} ║");
    debugPrint("============================================================\n");
  }
}