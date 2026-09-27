import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/premium_service.dart';
import '../../../core/utils/share_util.dart';
import '../../../core/theme/app_theme.dart';

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
    final isClassic = ref.watch(isClassicThemeProvider);

    final currentYear = DateTime.now().year;
    final String memberId = "CAPT-$currentYear-${(state.expiryDate?.millisecondsSinceEpoch ?? 88888).toString().substring(5, 9)}";
    final String title = state.isFounder ? "創始天尊指揮官" : (state.type == SubscriptionType.yearly ? "年度首席領航員" : "尊榮專業會員");
    final String expiryText = state.isFounder ? "終身永久享有最高特權" : "特權有效期至：${state.expiryDate != null ? DateFormat('yyyy/MM/dd').format(state.expiryDate!) : '有效'}";
    
    final int coins = state.coinBalance;

    final Color pageBg = isClassic ? AppColors.classicBg : const Color(0xFF020E1C);
    final Color appBarBg = isClassic ? const Color(0xFF0077B6) : const Color(0xFF020E1C);
    final Color sectionTitleColor = isClassic ? const Color(0xFF023E8A) : Colors.white.withValues(alpha: 0.9);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text("老船長 VIP 指揮中心", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: appBarBg,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: isClassic ? 1 : 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
        child: Column(
          children: [
            // 1. 尊榮金屬身分銘牌（專利黑金/深藍拉絲光澤）
            RepaintBoundary(
              key: _vipCardKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: state.isFounder 
                        ? const [Color(0xFF2C1802), Color(0xFF150A00), Color(0xFF3D2605)]
                        : const [Color(0xFF062343), Color(0xFF021326), Color(0xFF0A335C)],
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
                  backgroundColor: isClassic ? Colors.white : Colors.transparent,
                  side: BorderSide(color: isClassic ? Colors.grey.shade300 : Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded, color: AppColors.bioGold, size: 18),
                label: Text(
                  "分享我的 VIP 航海家榮譽身分卡", 
                  style: TextStyle(
                    color: isClassic ? AppColors.classicText : Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                  ),
                ),
                onPressed: () => ShareUtil.captureAndShare(_vipCardKey, stationName: title),
              ),
            ),

            const SizedBox(height: 24),

            // 2. 全天候戰術環境風格切換
            _buildThemeSwitchCard(context, ref, isClassic),

            const SizedBox(height: 24),

            // 3. 虛擬資產與特權金庫
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: AppColors.bioGold, size: 18),
                const SizedBox(width: 8),
                Text(
                  "虛擬資產與特權金庫",
                  style: TextStyle(color: sectionTitleColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildCoinWallet(context, ref, coins, state, isClassic),

            const SizedBox(height: 28),

            // 4. 硬核專線儀表板
            Row(
              children: [
                Icon(Icons.shield_rounded, color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  "專屬 VIP 硬核專線與運作狀態",
                  style: TextStyle(color: sectionTitleColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildStatusCard(
              icon: Icons.bolt_rounded,
              title: "中央氣象署 85 測站光纖直連專線",
              statusText: "專線已連通 • 響應 38ms",
              desc: "繞過邊緣公共快取節點，直達氣象署即時感測陣列，享有 0 延遲水文數據刷新特權。",
              statusColor: const Color(0xFF30D158),
              isClassic: isClassic,
            ),
            const SizedBox(height: 12),
            _buildStatusCard(
              icon: Icons.auto_awesome,
              title: "Gemini Flash-Lite 專屬推論通道",
              statusText: "AI 專家優先席位",
              desc: "獨享全維度湧浪週期、風切轉向點與咬度視窗 AI 加權計算，不排隊、無請求次數上限。",
              statusColor: AppColors.bioGold,
              isClassic: isClassic,
            ),
            const SizedBox(height: 12),
            _buildStatusCard(
              icon: Icons.notifications_active_rounded,
              title: "30 分鐘滿潮防困礁主動守護盾",
              statusText: "背景安全雷達運作中",
              desc: "依據您關注測站之每日滿潮死線，於滿潮前 30 分鐘發出專屬高分貝突發湧浪防護警告。",
              statusColor: Colors.cyanAccent,
              isClassic: isClassic,
            ),
            const SizedBox(height: 12),
            _buildStatusCard(
              icon: Icons.offline_bolt_rounded,
              title: "外海 85 測站全水文離線黑盒子",
              statusText: "本地防禦庫隨時待命",
              desc: "即使進入防波堤外側或深海無收訊死角，App 自動啟用離線神盾，確保水文回測不中斷。",
              statusColor: Colors.tealAccent,
              isClassic: isClassic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitchCard(BuildContext context, WidgetRef ref, bool isClassic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isClassic ? Colors.white : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isClassic ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.08), width: isClassic ? 1.0 : 0.5),
        boxShadow: isClassic ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isClassic ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
              color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "全天候戰術環境風格",
                      style: TextStyle(
                        color: isClassic ? AppColors.classicText : Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan).withValues(alpha: 0.3), 
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        "主畫面已支援一鍵秒切", 
                        style: TextStyle(
                          color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan, 
                          fontSize: 8.5, 
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isClassic ? "目前：經典白藍老船長版 (烈日外礁高對比)" : "目前：深淵黑金旗艦版 (OLED極致純黑)",
                  style: TextStyle(
                    color: isClassic ? Colors.grey.shade600 : Colors.white.withValues(alpha: 0.5), 
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isClassic,
            activeColor: const Color(0xFF0077B6),
            onChanged: (val) {
              HapticFeedback.mediumImpact();
              ref.read(isClassicThemeProvider.notifier).setClassicTheme(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoinWallet(BuildContext context, WidgetRef ref, int coins, PremiumState state, bool isClassic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isClassic ? Colors.amber.shade50 : Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: isClassic ? 0.5 : 0.3)),
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
                const Text("老船長幣 (Captain Coins)", style: TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "$coins", 
                      style: TextStyle(
                        color: isClassic ? Colors.black87 : Colors.white, 
                        fontSize: 28, 
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text("枚", style: TextStyle(color: isClassic ? Colors.black54 : Colors.white70, fontSize: 12)),
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
              HapticFeedback.lightImpact();
              _showCoinRedemptionSheet(context, ref, coins, state, isClassic);
            },
            child: const Text("兌換中心", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          )
        ],
      ),
    );
  }

  void _showCoinRedemptionSheet(
    BuildContext context, 
    WidgetRef ref, 
    int coins, 
    PremiumState state,
    bool isClassic,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isClassic ? Colors.white : AppColors.abyssCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, 
                  height: 4, 
                  decoration: BoxDecoration(
                    color: isClassic ? Colors.grey.shade300 : Colors.white24, 
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "老船長幣 · 特權兌換中心",
                    style: TextStyle(
                      fontSize: 17, 
                      fontWeight: FontWeight.w900, 
                      color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 0.5),
                    ),
                    child: Text(
                      "持有：$coins 枚",
                      style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "每日現場回報實況可獲 5 枚代幣，可直接兌換 PRO 旗艦特權天數！",
                style: TextStyle(fontSize: 11.5, color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary),
              ),
              const SizedBox(height: 20),

              _buildRedemptionOption(
                ctx: ctx,
                ref: ref,
                title: "1 日出海作戰通行證",
                desc: "解鎖 85 站光纖直連、全水文 24 小時無限制使用",
                coinCost: 15,
                passDays: 1,
                currentCoins: coins,
                state: state,
                isClassic: isClassic,
              ),
              const SizedBox(height: 10),
              _buildRedemptionOption(
                ctx: ctx,
                ref: ref,
                title: "3 日週末衝刺通行證",
                desc: "超值推薦！覆蓋週五至週日完整大潮咬度窗口",
                coinCost: 35,
                passDays: 3,
                currentCoins: coins,
                state: state,
                isClassic: isClassic,
                isHighlight: true,
              ),
              const SizedBox(height: 10),
              _buildRedemptionOption(
                ctx: ctx,
                ref: ref,
                title: "7 日黃金釣汛通行證",
                desc: "整週 PRO 特權免費用！深度活躍釣友首選",
                coinCost: 70,
                passDays: 7,
                currentCoins: coins,
                state: state,
                isClassic: isClassic,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRedemptionOption({
    required BuildContext ctx,
    required WidgetRef ref,
    required String title,
    required String desc,
    required int coinCost,
    required int passDays,
    required int currentCoins,
    required PremiumState state,
    required bool isClassic,
    bool isHighlight = false,
  }) {
    final bool canAfford = currentCoins >= coinCost;
    final Color borderColor = isHighlight ? AppColors.bioGold : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlight 
            ? AppColors.bioGold.withValues(alpha: isClassic ? 0.08 : 0.1) 
            : (isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isHighlight ? 1.5 : 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title, 
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 13.5, 
                        color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.amber, 
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "$coinCost 幣", 
                        style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc, 
                  style: TextStyle(fontSize: 10.5, color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? AppColors.bioGold : (isClassic ? Colors.grey.shade300 : Colors.white12),
              foregroundColor: canAfford ? Colors.black87 : Colors.white38,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (state.isFounder) {
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("👑 您已具備創始天尊指揮官終身權限，無須消耗代幣！"), backgroundColor: Color(0xFFB45309)),
                );
                return;
              }

              if (!canAfford) {
                HapticFeedback.vibrate();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("⚠️ 老船長幣不足！還需 ${coinCost - currentCoins} 枚幣，每日現場回報實況即可獲得 5 枚！"),
                    backgroundColor: AppColors.hazardCoral,
                  ),
                );
                return;
              }

              HapticFeedback.heavyImpact();
              // 預先捕獲 messenger 避免跨非同步 Gap 警告
              final messenger = ScaffoldMessenger.of(context);
              final bool success = await ref.read(premiumProvider.notifier).redeemCoinsForProPass(coinCost, passDays);
              
              if (ctx.mounted) Navigator.pop(ctx);

              if (success && mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text("🎉 成功兌換【$title】！PRO 特權已延長 $passDays 天！"),
                    backgroundColor: const Color(0xFF0077B6),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(canAfford ? "兌換" : "缺幣", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
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
    required bool isClassic,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClassic ? Colors.white : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isClassic ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.08), width: isClassic ? 1.0 : 0.5),
        boxShadow: isClassic ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)] : null,
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
                    Text(
                      title, 
                      style: TextStyle(
                        color: isClassic ? AppColors.classicText : Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                      ),
                    ),
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
          Text(
            desc, 
            style: TextStyle(
              color: isClassic ? Colors.grey.shade600 : Colors.white.withValues(alpha: 0.5), 
              fontSize: 12, 
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
