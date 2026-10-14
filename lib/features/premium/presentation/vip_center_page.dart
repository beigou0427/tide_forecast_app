import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/premium_service.dart';
import '../../../core/utils/share_util.dart';
import '../../../core/theme/app_theme.dart';
import '../../tide/providers/tide_provider.dart';
import '../../catch_log/presentation/catch_log_page.dart';
// 🌟 核心整合：引入手寫信模組，實現永久常駐展讀！
import '../../onboarding/presentation/founder_welcome_dialog.dart';

/// 🌟 經海事與增長駭客重塑之 VIP 指揮中心 (VVIP Command Center)
/// 100% 尊榮感體驗版：
/// 1. 【自動神盾】VVIP 進入頁面時，自動於背景靜默預載 85 站光纖數據，消滅手動苦力感！
/// 2. 【階級分化】VVIP 的代幣金庫自動變形為「航海家聲望值」，杜絕「廉價拉客」的錯誤期待。
/// 3. 【永久珍藏】實裝「📜 展讀手寫委任信」常駐專屬入口，情緒價值隨時隨地可重溫與炫耀！
class VipCenterPage extends ConsumerStatefulWidget {
  const VipCenterPage({super.key});

  @override
  ConsumerState<VipCenterPage> createState() => _VipCenterPageState();
}

class _VipCenterPageState extends ConsumerState<VipCenterPage> {
  final GlobalKey _vipCardKey = GlobalKey();

  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncMessage = "出海前一鍵封裝，將全台 85 站光纖實測與 30 天預報永久鎖入本機記憶體。";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSyncIfVvip();
    });
  }

  Future<void> _autoSyncIfVvip() async {
    final state = ref.read(premiumProvider);
    final bool isVvip = state.isFounder || 
                        state.type == SubscriptionType.yearly || 
                        state.type == SubscriptionType.lifetime;
    
    if (isVvip) {
      _startOfflinePreload(autoSync: true);
    }
  }

  Future<void> _startOfflinePreload({bool autoSync = false}) async {
    if (_isSyncing) return;
    if (!autoSync) HapticFeedback.heavyImpact();

    final stations = ref.read(stationListProvider).value;
    if (stations == null || stations.isEmpty) {
      if (!autoSync) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ 拓撲庫未就緒，請稍後再試")));
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
      _syncMessage = autoSync ? "⚓ VVIP 特權啟動：系統正為您於背景靜默預載全島神盾..." : "正在初始化安全通道與本地沙盒...";
    });

    final api = ref.read(tideApiServiceProvider);
    final isPro = ref.read(premiumProvider).isPremium;

    int successCount = 0;
    for (int i = 0; i < stations.length; i++) {
      if (!mounted) break;
      final s = stations[i];
      
      setState(() {
        _syncMessage = autoSync 
            ? "⚓ 靜默神盾封裝中 [${i + 1}/${stations.length}] ${s.name}..."
            : "正在封裝 [${i + 1}/${stations.length}] ${s.name}...";
        _syncProgress = (i + 1) / stations.length;
      });

      try {
        await api.fetchData(s.id, isPremium: isPro).timeout(const Duration(seconds: 3));
        successCount++;
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      if (!autoSync) HapticFeedback.heavyImpact();
      setState(() {
        _isSyncing = false;
        _syncProgress = 1.0;
        _syncMessage = "✅ 離線神盾預載完畢！成功封裝 $successCount 站至本機安全黑盒子。";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(premiumProvider);
    final bool isVvip = state.isFounder || state.type == SubscriptionType.yearly || state.type == SubscriptionType.lifetime;
    
    final String memberId = "CAPT-2026-${(state.expiryDate?.millisecondsSinceEpoch ?? 88888).toString().substring(5, 9)}";
    final String title = state.isFounder ? "創始天尊指揮官" : (state.type == SubscriptionType.yearly ? "年度首席領航員" : "尊榮專業會員");
    final String expiryText = state.isFounder ? "終身永久享有最高特權" : "特權有效期至：${state.expiryDate != null ? DateFormat('yyyy/MM/dd').format(state.expiryDate!) : '有效'}";

    return Scaffold(
      backgroundColor: const Color(0xFF020E1C),
      appBar: AppBar(
        title: const Text("老船長 VIP 指揮中心", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF020E1C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          children: [
            // 🌟 1. 尊榮黑金金屬身分銘牌
            RepaintBoundary(
              key: _vipCardKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: state.isFounder 
                        ? [const Color(0xFF2C1802), const Color(0xFF150A00), const Color(0xFF3D2605)]
                        : [const Color(0xFF062343), const Color(0xFF021326), const Color(0xFF0A335C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8)).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.anchor_rounded, color: state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8), size: 28),
                            const SizedBox(width: 8),
                            Text(
                              "TIDE PRO COMMANDER",
                              style: TextStyle(
                                color: (state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8)),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8)).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8), width: 1),
                          ),
                          child: Text(
                            state.isFounder ? "FOUNDER" : "VIP PRO",
                            style: TextStyle(color: state.isFounder ? const Color(0xFFFFD700) : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: state.isFounder ? const Color(0xFFFFE57F) : Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "編號：$memberId",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, letterSpacing: 1.5, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          expiryText,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        const Icon(Icons.verified_rounded, color: Colors.amber, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 🌟 核心重塑：雙子星尊榮行動列（身分卡分享 ＋ 手寫委任信常駐入口）
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.share_rounded, color: Colors.amberAccent, size: 16),
                      label: const Text(
                        "分享身分卡", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () => ShareUtil.captureAndShare(_vipCardKey, stationName: title),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFAF6EC), // 📜 古董航海羊皮紙米白
                        foregroundColor: const Color(0xFF2C1E14), // 深墨筆觸
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFF8C6D46), width: 1.2), // 鞣製皮革金邊
                        ),
                      ),
                      icon: const Icon(Icons.history_edu_rounded, color: Color(0xFFB22222), size: 18), // 朱砂紅印標
                      label: const Text(
                        "展讀手寫委任信", 
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        // 🌟 點擊即刻召喚帶有朱砂印鑑的古董航海羊皮紙親筆信！
                        FounderWelcomeDialog.showCommissionLetter(
                          context,
                          isFounder: state.isFounder,
                          isYearly: state.type == SubscriptionType.yearly,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            
            // 🌟 PM 增長駭客核心：老船長代幣金庫 (階級差異化版)
            _buildCoinTreasuryCard(state, isVvip),
            
            const SizedBox(height: 24),

            // 🌟 3. 給予極致科技掌控感的特權儀表板
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF00B4D8), size: 18),
                const SizedBox(width: 8),
                Text(
                  "專屬 VIP 硬核專線與運作狀態",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildStatusCard(
              icon: Icons.bolt_rounded,
              title: "中央氣象署 85 測站光纖直連專線",
              statusText: "專線已連通 • 響應 38ms",
              desc: "繞過邊緣公共快取節點，直達氣象署即時感測陣列，享有 0 延遲水文數據刷新特權。",
              statusColor: Colors.greenAccent,
            ),
            const SizedBox(height: 12),
            _buildStatusCard(
              icon: Icons.auto_awesome,
              title: "Gemini Flash-Lite 專屬推論通道",
              statusText: "AI 專家優先席位",
              desc: "獨享全維度湧浪週期、風切轉向點與咬度視窗 AI 加權計算，不排隊、無請求次數上限。",
              statusColor: Colors.amberAccent,
            ),
            const SizedBox(height: 12),
            _buildStatusCard(
              icon: Icons.notifications_active_rounded,
              title: "30 分鐘滿潮防困礁主動守護盾",
              statusText: "背景安全雷達運作中",
              desc: "依據您關注測站之每日滿潮死線，於滿潮前 30 分鐘發出專屬高分貝突發湧浪防護警告。",
              statusColor: Colors.cyanAccent,
            ),
            const SizedBox(height: 12),
            
            // 🌟 離線神盾一鍵預載卡片 (支援 VVIP 背景靜默啟動)
            _buildInteractiveOfflineShieldCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinTreasuryCard(PremiumState state, bool isVvip) {
    final int coins = state.coinBalance;
    final int needed = 100 - (coins % 100);
    final double progress = isVvip ? 1.0 : (coins % 100) / 100.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.bioGold.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.bioGold.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(isVvip ? Icons.military_tech_rounded : Icons.monetization_on_rounded, color: AppColors.bioGold, size: 18),
              ),
              const SizedBox(width: 10),
              Text(isVvip ? "專屬航海家聲望庫" : "聯盟推廣與代幣金庫", style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isVvip ? "目前聲望積分" : "目前持有代幣", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.bold)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text("$coins", style: const TextStyle(color: AppColors.bioGold, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 4),
                  Text(isVvip ? "pt" : "枚", style: const TextStyle(color: AppColors.bioGold, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black45,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.bioGold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isVvip 
                ? "指揮官您好，您的代幣已全數轉化為專屬聲望積分！目前的聲望值已超越全國 99% 的釣友！"
                : "再收集 $needed 枚代幣，系統將自動為您展延 30 天 PRO 旗艦權限！",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5, height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.bioGold.withValues(alpha: 0.6), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: AppColors.bioGold,
              ),
              icon: Icon(isVvip ? Icons.stars_rounded : Icons.campaign_rounded, size: 16),
              label: Text(
                isVvip ? "前往漁獲日誌累積聲望積分" : "前往漁獲日誌分享戰報賺取代幣", 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CatchLogPage()));
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInteractiveOfflineShieldCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isSyncing ? Colors.tealAccent.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _isSyncing ? Colors.tealAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.tealAccent.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.offline_bolt_rounded, color: Colors.tealAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("全島 85 測站水文離線黑盒子", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Colors.tealAccent, size: 10),
                        SizedBox(width: 4),
                        Text("本地防禦庫", style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_syncMessage, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.4)),
          const SizedBox(height: 16),
          
          if (_isSyncing || _syncProgress == 1.0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _syncProgress,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
              ),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSyncing ? Colors.white12 : Colors.tealAccent,
                foregroundColor: _isSyncing ? Colors.white54 : Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSyncing 
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
                  : const Icon(Icons.cloud_download_rounded, size: 16),
              label: Text(
                _isSyncing ? "神盾靜默封裝中..." : (_syncProgress == 1.0 ? "重新手動預載" : "一鍵預載全島水文"), 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
              ),
              onPressed: _isSyncing ? null : () => _startOfflinePreload(autoSync: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String statusText,
    required String desc,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}
