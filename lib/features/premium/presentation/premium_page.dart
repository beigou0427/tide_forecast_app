import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/premium_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../tide/presentation/home_page.dart';
import 'vip_center_page.dart';

/// 🌟 Phil Schiller (App Store 審查合規) 零拒審標準付費牆 (Guideline 3.1.2 Compliant)
/// 全面聚焦於專業海事遙測、全島 85 站光纖專線、長湧動能防衛與 Apple 家人共享
class PremiumPage extends ConsumerStatefulWidget {
  final bool fromOnboarding;
  const PremiumPage({super.key, this.fromOnboarding = false});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  int _selectedTier = 2; // 預設推薦年度指揮官方案 (支援家人共享)
  List<ProductDetails> _storeProducts = [];

  final String _privacyUrl = "https://gist.github.com/beigou0427/99e6eddb729ae53eb8e7474866f3f009";
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
    } catch (_) {}
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
    HapticFeedback.mediumImpact();

    String targetProductId;
    switch (_selectedTier) {
      case 0:
        targetProductId = AppConstants.iapProWeekly;
        break;
      case 1:
        targetProductId = AppConstants.iapProMonthly;
        break;
      case 3:
        targetProductId = AppConstants.iapProLifetime;
        break;
      case 2:
      default:
        targetProductId = AppConstants.iapProYearly;
        break;
    }

    AnalyticsService.logInitiateCheckout(targetProductId);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("正在連接 App Store 官方加密通道，請稍候重試..."),
            backgroundColor: Color(0xFF0077B6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("無法開啟連結: $urlString");
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
            // 頂部導航列
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
                    child: const Text(
                      "TIDE PRO", 
                      style: TextStyle(color: Color(0xFF00B4D8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: _closePaywall,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                      "掌握全台 85 測站光纖直連、全站離線神盾預載與外礁長湧防困礁警報",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 18),

                    // 家人共享專案卡 (合規標示)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bioGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.4), width: 1.0),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.bioGold.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.groups_rounded, color: AppColors.bioGold, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "支援 Apple「家人共享」機制", 
                                  style: TextStyle(color: AppColors.bioGold, fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "「年度指揮官計畫」完整相容家人共享，一人訂閱，同行作釣家庭成員自動享有 PRO 旗艦特權！", 
                                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (premiumState.isPremium) ...[
                      _buildUnlockedCard(premiumState),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildTierCard(
                        index: 0,
                        title: "週費體驗版",
                        price: AppConstants.priceWeekly,
                        unit: " / 週",
                        subDesc: "單次週末出海衝刺體驗",
                        badge: "單週靈活",
                      ),
                      const SizedBox(height: 10),

                      _buildTierCard(
                        index: 1,
                        title: "月度專業版",
                        price: AppConstants.priceMonthly,
                        unit: " / 月",
                        subDesc: "當季黑毛/軟絲釣汛首選",
                        badge: "熱門首選",
                      ),
                      const SizedBox(height: 10),

                      _buildTierCard(
                        index: 2,
                        title: "年度指揮官計畫",
                        price: AppConstants.priceYearly,
                        unit: " / 年",
                        subDesc: "主力推薦 · 支援 Apple 家人共享 · 每月僅約 NT\$ 82",
                        badge: "🔥 7天免費試用 · 支援家人共享",
                        isHighlight: true,
                      ),
                      const SizedBox(height: 10),

                      _buildTierCard(
                        index: 3,
                        title: "終身創始席次",
                        price: AppConstants.priceLifetime,
                        unit: " / 永久",
                        subDesc: "限量 100 席 · 終身享有後續所有 AI 算力與更新",
                        badge: "⚡ 創始天尊",
                        isGold: true,
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildFeatureRow(Icons.groups_rounded, "支援 Apple 家人共享 · 同行家庭成員全員享有 PRO 特權"),
                    _buildFeatureRow(Icons.bolt_rounded, "85 測站光纖直連專線 (中央氣象署官方遙測 0 延遲)"),
                    _buildFeatureRow(Icons.download_for_offline_rounded, "全台 85 測站一鍵離線神盾預載包 (外海斷網無縫切換)"),
                    _buildFeatureRow(Icons.notifications_active_outlined, "滿潮前 30 分鐘主動突發長湧瘋狗浪防困礁警報"),
                    _buildFeatureRow(Icons.phishing_rounded, "四大標竿魚種海溫躍層 ΔT 與氣壓走水推演"),
                    _buildFeatureRow(Icons.history_toggle_off_rounded, "30 天時間序列金庫與歷史天文調和回測"),
                    _buildFeatureRow(Icons.cloud_upload_rounded, "無限張數雲端高畫質漁獲相簿永久備份"),
                    const SizedBox(height: 20),

                    // 🌟 Phil Schiller Guideline 3.1.2 權威透明訂閱告示盒
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "【App Store 訂閱及免費試用條款說明】", 
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "• 「年度指揮官計畫」提供 7 天免費試用期。試用期結束後，系統將自動從您的 Apple ID 帳戶收取每年 NT\$ 990 的費用，除非您在計費週期結束至少 24 小時前取消。\n"
                            "• 「月度專業版」費用為每月 NT\$ 120，「週費體驗版」費用為每週 NT\$ 60，購買後由 Apple ID 帳戶扣款。\n"
                            "• 訂閱將自動續訂，帳戶將在當前計費週期結束前 24 小時內收取續訂費用。您可在購買後隨時前往「App Store 帳號設定 > 訂閱項目」管理或取消續訂。\n"
                            "• 「終身創始席次」為一次性買斷商品，無需自動續訂。",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 法規連結列：EULA / 隱私權政策 / 恢復購買
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => _launchURL(_appleEulaUrl),
                          child: Text(
                            "使用條款 (EULA)", 
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, decoration: TextDecoration.underline),
                          ),
                        ),
                        Text("   •   ", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                        InkWell(
                          onTap: () => _launchURL(_privacyUrl),
                          child: Text(
                            "隱私權政策", 
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, decoration: TextDecoration.underline),
                          ),
                        ),
                        Text("   •   ", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                        InkWell(
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            final messenger = ScaffoldMessenger.of(context);
                            await ref.read(iapManagerProvider).restorePurchases();
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text("已向 App Store 送出恢復購買請求，若有訂閱紀錄將自動為您啟動！"),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Text(
                            "恢復購買", 
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 底部購買觸控列
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
                        backgroundColor: _selectedTier == 3 
                            ? Colors.amberAccent 
                            : (_selectedTier == 2 ? const Color(0xFF00B4D8) : Colors.white12),
                        foregroundColor: _selectedTier == 3 
                            ? Colors.black87 
                            : Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _selectedTier == 2 
                              ? "開啟 7 天免費試用 (滿期 ${AppConstants.priceYearly}/年 · 支援家人共享)"
                              : (_selectedTier == 3 
                                  ? "取得終身創始席次 (${AppConstants.priceLifetime})" 
                                  : (_selectedTier == 1 
                                      ? "立即訂閱月度版 (${AppConstants.priceMonthly} / 月)" 
                                      : "開啟週度體驗 (${AppConstants.priceWeekly} / 週)")),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _closePaywall,
                    child: Text(
                      "先以免費版體驗 (功能受限)", 
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                    ),
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
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTier = index);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (isGold ? Colors.amber.withValues(alpha: 0.12) : const Color(0xFF00B4D8).withValues(alpha: 0.1)) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? (isGold ? Colors.amberAccent : const Color(0xFF00B4D8)) : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isGold ? Colors.amber : const Color(0xFF00B4D8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w900)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subDesc, style: TextStyle(color: isSelected ? (isGold ? Colors.amberAccent : const Color(0xFF00B4D8)) : Colors.white38, fontSize: 10.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(price, style: TextStyle(color: isGold ? Colors.amberAccent : Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                Text(unit, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
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
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B4D8), size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}