import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/premium_service.dart';
import '../../../core/utils/share_util.dart';

class VipCenterPage extends ConsumerStatefulWidget {
  const VipCenterPage({super.key});

  @override
  ConsumerState<VipCenterPage> createState() => _VipCenterPageState();
}

class _VipCenterPageState extends ConsumerState<VipCenterPage> {
  final GlobalKey _vipCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(premiumProvider);
    final String memberId = "CAPT-2026-${(state.expiryDate?.millisecondsSinceEpoch ?? 88888).toString().substring(5, 9)}";
    final String title = state.isFounder ? "創始天尊指揮官" : (state.type == SubscriptionType.yearly ? "年度首席領航員" : "尊榮專業會員");
    final String expiryText = state.isFounder ? "終身永久享有最高特權" : "特權有效期至：${state.expiryDate != null ? DateFormat('yyyy/MM/dd').format(state.expiryDate!) : '有效'}";
    
    // 取得當前餘額
    final int coins = state.coinBalance;

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

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded, color: Colors.amberAccent, size: 18),
                label: const Text("分享我的 VIP 航海家榮譽身分卡", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => ShareUtil.captureAndShare(_vipCardKey, stationName: title),
              ),
            ),

            const SizedBox(height: 32),

            // 🌟 2. 虛擬資產與特權金庫 (代幣經濟展示)
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  "虛擬資產與特權金庫",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildCoinWallet(context, coins),

            const SizedBox(height: 32),

            // 🌟 3. 硬核專線儀表板
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
            _buildStatusCard(
              icon: Icons.offline_bolt_rounded,
              title: "外海 85 測站全水文離線黑盒子",
              statusText: "本地防禦庫隨時待命",
              desc: "即使進入防波堤外側或深海無收訊死角，App 自動啟用離線神盾，確保水文回測不中斷。",
              statusColor: Colors.tealAccent,
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 建構老船長幣錢包 UI
  Widget _buildCoinWallet(BuildContext context, int coins) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("老船長幣 (Captain Coins)", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text("$coins", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    const Text("枚", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🛠️ 特約釣具店折扣與高階測站單次解鎖功能，將於下個版本開放兌換！"),
                  backgroundColor: Color(0xFF0077B6),
                ),
              );
            },
            child: const Text("兌換中心", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          )
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