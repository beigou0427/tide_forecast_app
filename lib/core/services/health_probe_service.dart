import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/security_util.dart';

enum ProbeStatus { healthy, degraded, critical }

class ClusterHealthReport {
  final ProbeStatus status;
  final String activeNode;
  final int totalStationsOnline;
  final DateTime lastChecked;
  final int latencyMs;
  final String message;

  const ClusterHealthReport({
    required this.status,
    required this.activeNode,
    required this.totalStationsOnline,
    required this.lastChecked,
    required this.latencyMs,
    required this.message,
  });

  factory ClusterHealthReport.initial() => ClusterHealthReport(
    status: ProbeStatus.healthy,
    activeNode: "https://beigou0427.github.io/tide_forecast_app",
    totalStationsOnline: 85,
    lastChecked: DateTime.now(),
    latencyMs: 0,
    message: "健康探針初始化就緒",
  );
}

final healthProbeProvider = StateNotifierProvider<HealthProbeNotifier, ClusterHealthReport>((ref) {
  return HealthProbeNotifier();
});

/// 🌟 Kelsey Hightower (Kubernetes 傳奇) 宣告式叢集健康探針 (Liveness & Readiness Probes)
/// 背景主動探測邊緣端點，實現無中斷切流 (Zero-Downtime Failover)
class HealthProbeNotifier extends StateNotifier<ClusterHealthReport> {
  static const List<String> _clusterNodes = [
    "https://beigou0427.github.io/tide_forecast_app",
    "https://tide-pro-enterprise.github.io/tide_forecast_app",
  ];

  Timer? _periodicProbeTimer;

  HealthProbeNotifier() : super(ClusterHealthReport.initial()) {
    // 延遲啟動首次探針，避開冷啟動尖峰
    Future.delayed(const Duration(seconds: 4), () {
      executeReadinessProbe();
    });

    // 每 15 分鐘背景低耗能巡航探測一次
    _periodicProbeTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      executeReadinessProbe();
    });
  }

  /// 🌟 執行 Readiness 探針：探測遠端 Canary Heartbeat (health_status.json)
  Future<void> executeReadinessProbe() async {
    for (final node in _clusterNodes) {
      final sw = Stopwatch()..start();
      try {
        final probeUri = Uri.parse("$node/health_status.json?t=${DateTime.now().millisecondsSinceEpoch}");
        if (!SecurityUtil.isAuthorizedHost(probeUri)) continue;

        final response = await http.get(probeUri).timeout(const Duration(milliseconds: 2500));
        sw.stop();

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final int stationCount = data['total_stations'] as int? ?? 85;
          final String systemStatus = data['status']?.toString() ?? 'OPERATIONAL';

          final isDegraded = systemStatus != 'OPERATIONAL' || stationCount < 85;

          state = ClusterHealthReport(
            status: isDegraded ? ProbeStatus.degraded : ProbeStatus.healthy,
            activeNode: node,
            totalStationsOnline: stationCount,
            lastChecked: DateTime.now(),
            latencyMs: sw.elapsedMilliseconds,
            message: isDegraded ? "邊緣快照降級 ($stationCount/85 站)" : "叢集探針連通正常 (${sw.elapsedMilliseconds}ms)",
          );

          debugPrint("🛰️ [Kelsey Hightower 探針] 節點 $node 狀態: ${state.status.name.toUpperCase()} (延遲: ${sw.elapsedMilliseconds}ms)");
          return; // 命中健康節點，探針終止
        }
      } catch (e) {
        sw.stop();
        debugPrint("⚠️ [Kelsey Hightower 探針] 節點 $node 連線超時或異常 ($e)，探測備援節點...");
      }
    }

    // 若全部遠端節點均不可達，轉入本地 Liveness 存活模式
    _fallbackToLocalLiveness();
  }

  /// 🌟 Liveness 探針本地降級：驗證本地沙盒存活狀態
  Future<void> _fallbackToLocalLiveness() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStations = prefs.getStringList('favorite_stations_v1') ?? [];

    state = ClusterHealthReport(
      status: ProbeStatus.degraded,
      activeNode: "LOCAL_SANDBOX_DEFENSE",
      totalStationsOnline: cachedStations.length,
      lastChecked: DateTime.now(),
      latencyMs: 0,
      message: "外海離線或遠端叢集維護中，本地天文物理神盾接管運行",
    );
    debugPrint("🛡️ [Kelsey Hightower 探針] 啟動本地沙盒 Liveness 保底模式");
  }

  @override
  void dispose() {
    _periodicProbeTimer?.cancel();
    super.dispose();
  }
}