import 'vip_center_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/premium_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/utils/constants.dart';
import '../../tide/presentation/home_page.dart';

class PremiumPage extends ConsumerStatefulWidget {
  final bool fromOnboarding;
  const PremiumPage({super.key, this.fromOnboarding = false});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  int _selectedTier = 1;
  List<ProductDetails> _storeProducts = [];

  final String _legalUrl = "https://gist.github.com/beigou0427/99e6eddb729ae53eb8e7474866f3f009";
  final String _appleEulaUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPaywallView();
    _loadStoreProducts();
  }

  Future<void> _loadStoreProducts() async {
    try {
      final products = await ref.read(iapManagerProvider).fetchProducts();
      if (mounted) {
        setState(() {
          _storeProducts = products;
        });
      }
    } catch (_) {
      
    }
  }

  void _closePaywall() {
    if (widget.fromOnboarding || !Navigator.canPop(context)) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handlePurchase() async {
    String targetProductId;
    SubscriptionType fallbackType;

    switch (_selectedTier) {
      case 0:
        targetProductId = AppConstants.iapProWeekly;
        fallbackType = SubscriptionType.weekly;
        break;
      case 2:
        targetProductId = AppConstants.iapProLifetime;
        fallbackType = SubscriptionType.lifetime;
        break;
      case 1:
      default:
        targetProductId = AppConstants.iapProYearly;
        fallbackType = SubscriptionType.yearly;
        break;
    }

    AnalyticsService.logInitiateCheckout(targetProductId);

    // 🌟 1. 優先嘗試發起 Apple 原生 StoreKit 支付
    ProductDetails? matchedProduct;
    for (final p in _storeProducts) {
      if (p.id == targetProductId) {
        matchedProduct = p;
        break;
      }
    }

    if (matchedProduct != null) {
      await ref.read(iapManagerProvider).buySubscription(matchedProduct);
    } else {
      // 🌟 2. 本地開發與沙盒模擬容錯
      debugPrint("⚠️ 尚未抓取到 StoreKit 商品，執行沙盒保底模擬流程 ($targetProductId)");
      await ref.read(premiumProvider.notifier).setPremiumStatus(true, fallbackType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 成功啟動 Pro 會員權限（沙盒/展示模式）"),
            backgroundColor: Colors.teal,
            duration: Duration(seconds: 2),
          ),
        );
        _closePaywall();
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("無法開啟: $urlString");
    }
  }

  @override
  Widget build(BuildContext context) {
    final premiumState = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF021B33),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("PRO MEMBER", style: TextStyle(color: Color(0xFF00B4D8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: _closePaywall,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
                        border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.anchor_rounded, color: Color(0xFF00B4D8), size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "解鎖老船長 AI 專業旗艦版",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "掌握全台 85 測站實時湧浪、30 天潮汐深度回測與 AI 漁獲窗口",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),

                    if (premiumState.isPremium) ...[
                      _buildUnlockedCard(premiumState),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildTierCard(
                        index: 0,
                        title: "週費方案 (短期嚐鮮)",
                        price: "NT\$ 99",
                        unit: " / 週",
                        subDesc: "換算年費需 NT\$ 5,148",
                        badge: null,
                      ),
                      const SizedBox(height: 12),
                      _buildTierCard(
                        index: 1,
                        title: "年度指揮官計畫",
                        price: "NT\$ 790",
                        unit: " / 年",
                        subDesc: "每月僅約 NT\$ 66，現省 84%",
                        badge: "🔥 85% 首選",
                        isHighlight: true,
                      ),
                      const SizedBox(height: 12),
                      _buildTierCard(
                        index: 2,
                        title: "終身買斷席次",
                        price: "NT\$ 1,990",
                        unit: " / 永久",
                        subDesc: "一次付費，終身享受全功能升級",
                        badge: "⚡ 限量席位",
                        isGold: true,
                      ),
                      const SizedBox(height: 24),
                    ],

                    _buildFeatureRow(Icons.bolt, "VIP 氣象署即時直連專線 (0 延遲刷新)"),
                    _buildFeatureRow(Icons.auto_awesome, "Gemini Flash-Lite 老船長綜合海象推理"),
                    _buildFeatureRow(Icons.history_toggle_off, "30 天完整風浪水溫回測與未來遠期預報"),
                    _buildFeatureRow(Icons.notifications_active_outlined, "滿乾潮前 30 分鐘主動突發湧浪安全警示"),
                    const SizedBox(height: 24),

                    // 🌟 Apple Guideline 3.1.2 審查條款合規聲明
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "【訂閱須知】付款將在確認購買時由您的 Apple ID 帳戶收取。訂閱會自動續訂，除非在當前計費週期結束前至少 24 小時關閉自動續訂。帳戶將在當前週期結束前 24 小時內收取續訂費用。購買後您可隨時至 App Store 帳號設定管理或取消訂閱。",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => _launchURL(_appleEulaUrl),
                          child: Text("標準使用條款 (EULA)", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, decoration: TextDecoration.underline)),
                        ),
                        Text("  •  ", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                        InkWell(
                          onTap: () => _launchURL(_legalUrl),
                          child: Text("隱私權政策", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, decoration: TextDecoration.underline)),
                        ),
                        Text("  •  ", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                        InkWell(
                          onTap: () async {
                            await ref.read(iapManagerProvider).restorePurchases();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已向 App Store 送出恢復購買請求")));
                            }
                          },
                          child: Text("恢復購買", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF021B33),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handlePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedTier == 2 ? Colors.amberAccent : const Color(0xFF00B4D8),
                        foregroundColor: _selectedTier == 2 ? Colors.black87 : Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _selectedTier == 2 ? "搶購終身創始席次 (NT\$ 1,990)" : (_selectedTier == 1 ? "立即啟動年度計畫 (現省 84%)" : "開啟週度體驗 (NT\$ 99)"),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _closePaywall,
                    child: Text("先以免費版體驗 (功能受限)", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required int index,
    required String title,
    required String price,
    required String unit,
    required String subDesc,
    String? badge,
    bool isHighlight = false,
    bool isGold = false,
  }) {
    final bool isSelected = _selectedTier == index;
    Color borderColor = Colors.white.withValues(alpha: 0.12);
    if (isSelected) {
      borderColor = isGold ? Colors.amberAccent : (isHighlight ? const Color(0xFF00B4D8) : Colors.white);
    }

    return InkWell(
      onTap: () => setState(() => _selectedTier = index),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? (isGold ? Colors.amber.withValues(alpha: 0.12) : const Color(0xFF00B4D8).withValues(alpha: 0.1)) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected ? 2.2 : 1.0),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? (isGold ? Colors.amberAccent : const Color(0xFF00B4D8)) : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isGold ? Colors.amber : const Color(0xFF00B4D8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subDesc, style: TextStyle(color: isSelected ? (isGold ? Colors.amberAccent : const Color(0xFF00B4D8)) : Colors.white38, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(price, style: TextStyle(color: isGold ? Colors.amberAccent : Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(unit, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedCard(PremiumState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: state.isFounder ? [const Color(0xFFB8860B), const Color(0xFFFFD700)] : [const Color(0xFF0077B6), const Color(0xFF023E8A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(state.isFounder ? Icons.workspace_premium : Icons.verified_user, color: Colors.black87, size: 40),
          const SizedBox(height: 8),
          Text(
            state.isFounder ? "👑 尊貴的創始釣友" : "專業版已成功啟動",
            style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
                    Text(
            state.isFounder ? "感謝您早期支持！已為您永久鎖定全平台終身最高權限" : "方案有效期至：${state.expiryDate?.toString().substring(0, 10) ?? '有效'}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.shield_rounded, color: Colors.amber, size: 18),
            label: const Text("進入 VIP 航海指揮中心", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VipCenterPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B4D8), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}



