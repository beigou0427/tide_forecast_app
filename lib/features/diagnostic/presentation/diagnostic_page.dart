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
        title: const Text("全系統模組自檢中心", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF0077B6),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(diagnosticProvider),
            tooltip: '重新執行全系統自檢',
          ),
        ],
      ),
      body: diagAsync.when(
        loading: () => _buildLoadingUI(),
        error: (err, _) => Center(child: Text("自檢執行失敗: $err")),
        data: (results) {
          int errorCount = results.values.where((v) => v.contains('❌')).length;
          int warnCount = results.values.where((v) => v.contains('⚠️')).length;
          int passCount = results.length - errorCount - warnCount;
          int healthPercentage = ((passCount / results.length) * 100).round();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _buildCommandGauge(results.length, passCount, errorCount, warnCount, healthPercentage),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.checklist_rounded, size: 18, color: Color(0xFF0077B6)),
                  const SizedBox(width: 8),
                  Text(
                    "12 大功能模組實時檢測明細",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey.shade800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...results.entries.map((e) => _buildModuleTile(e.key, e.value)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.replay_rounded, color: Colors.white),
                  label: const Text("重新執行全系統自檢", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () => ref.invalidate(diagnosticProvider),
                ),
              ),
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
          const CircularProgressIndicator(color: Color(0xFF0077B6)),
          const SizedBox(height: 20),
          const Text("正在穿透檢測全系統 12 大功能模組...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
          const SizedBox(height: 6),
          Text("包括氣象署專線測速、30天預報拓撲、離線快取與各硬體感測器", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCommandGauge(int total, int pass, int errors, int warns, int percentage) {
    final bool isAllGood = errors == 0;

    return CustomCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("系統綜合健康指數", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "$percentage%",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isAllGood ? const Color(0xFF0077B6) : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isAllGood ? Colors.green : Colors.redAccent).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAllGood ? "OPERATIONAL" : "DEGRADED",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isAllGood ? Colors.green.shade700 : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                isAllGood ? Icons.verified_user_rounded : Icons.warning_rounded,
                size: 48,
                color: isAllGood ? const Color(0xFF0077B6) : Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(isAllGood ? const Color(0xFF0077B6) : Colors.redAccent),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBadge("全綠通行", "$pass 模組", Colors.green),
              _buildStatBadge("潛在警示", "$warns 模組", Colors.orange),
              _buildStatBadge("異常阻斷", "$errors 模組", Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildModuleTile(String title, String status) {
    final bool isError = status.contains('❌');
    final bool isWarn = status.contains('⚠️');

    Color iconBg = Colors.green.shade50;
    Color iconColor = Colors.green.shade700;
    IconData icon = Icons.check_circle_rounded;

    if (isError) {
      iconBg = Colors.red.shade50;
      iconColor = Colors.redAccent;
      icon = Icons.cancel_rounded;
    } else if (isWarn) {
      iconBg = Colors.orange.shade50;
      iconColor = Colors.orange.shade800;
      icon = Icons.info_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF021B33))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isError ? Colors.redAccent : (isWarn ? Colors.orange.shade800 : Colors.blueGrey.shade700),
            ),
          ),
        ),
      ),
    );
  }
}
