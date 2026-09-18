import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/diagnostic_provider.dart';
import '../../../shared/widgets/custom_card.dart';

class DiagnosticPage extends ConsumerWidget {
  const DiagnosticPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagAsync = ref.watch(diagnosticProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("系統自檢中心", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(diagnosticProvider),
            tooltip: '重新檢測',
          ),
        ],
      ),
      body: diagAsync.when(
        loading: () => _buildLoadingUI(),
        error: (err, stack) => Center(child: Text("檢測器異常: $err")),
        data: (results) {
          int errorCount = results.values.where((v) => v.contains('❌')).length;
          
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildStatusHeader(errorCount),
              const SizedBox(height: 24),
              ...results.entries.map((e) => _buildResultTile(e.key, e.value)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.teal),
          const SizedBox(height: 16),
          Text("正在檢測所有微服務節點...", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(int errorCount) {
    bool isHealthy = errorCount == 0;
    return CustomCard(
      child: Column(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.warning_rounded,
            color: isHealthy ? Colors.green : Colors.redAccent,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            isHealthy ? "系統運作正常" : "發現 $errorCount 項異常",
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              color: isHealthy ? Colors.green.shade700 : Colors.redAccent.shade700,
            ),
          ),
          const SizedBox(height: 8),
          const Text("此儀表板用於確認 CWA 官方 API、GitHub Edge 邊緣節點及手機權限的連線健康度。", 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildResultTile(String title, String status) {
    bool isError = status.contains('❌');
    bool isWarning = status.contains('⚠️');
    
    Color bgColor = Colors.green.shade50;
    Color iconColor = Colors.green;
    IconData icon = Icons.check_circle_outline;

    if (isError) {
      bgColor = Colors.red.shade50;
      iconColor = Colors.red;
      icon = Icons.cancel_outlined;
    } else if (isWarning) {
      bgColor = Colors.orange.shade50;
      iconColor = Colors.orange;
      icon = Icons.error_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(status, style: TextStyle(color: isError ? Colors.red : (isWarning ? Colors.orange.shade800 : Colors.blueGrey))),
        ),
      ),
    );
  }
}
