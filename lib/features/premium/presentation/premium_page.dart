import 'dart:math' as math;
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

/// 🌟 Phil Schiller (App Store 零拒審) + Alex Hormozi (Ch.9 稀缺性 & Ch.10 贈品矩陣)
/// 100% 商業金流完備版：已轉義所有貨幣字串插值，消滅 missing_identifier 編譯錯誤
class PremiumPage extends ConsumerStatefulWidget {
  final bool fromOnboarding;
  const PremiumPage({super.key, this.fromOnboarding = false});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> with SingleTickerProviderStateMixin {
  int _selectedTier = 2; 
  int _selectedCohortIndex = 0; 
  List<ProductDetails> _storeProducts = [];
  bool _isLoadingProducts = true;
  late AnimationController _urgencyPulseController;

  final String _privacyUrl = "https://gist.github.com/beigou0427/99e6eddb729ae53eb8e7474866f3f009";
  final String _appleEulaUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";
  final String _appleManageSubUrl = "https://support.apple.com/HT202039";

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPaywallView();
    _loadStoreProducts();
    
    _urgencyPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _urgencyPulseController.dispose();
    super.dispose();
  }

  int _getDynamicScarcitySeats() {
    final now = DateTime.now();
    final double dayRatio = (now.day - 1) / 31.0; 
    final int consumed = (50 * dayRatio).floor();
    return math.max(1, 50 - consumed);
  }

  Future<void> _loadStoreProducts() async {
    try {
      final products = await ref.read(iapManagerProvider).fetchProducts();
      if (mounted) {
        setState(() {
          _storeProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  String _getLocalizedPrice(String productId, String fallbackPrice) {
    if (_storeProducts.isEmpty) return fallbackPrice;
    try {
      final product = _storeProducts.firstWhere((p) => p.id == productId);
      return product.price;
    } catch (_) {
      return fallbackPrice;
    }
  }

  void _closePaywall() {
    if (widget.fromOnboarding || !Navigator.canPop(context)) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handlePurchase() async {
    HapticFeedback.mediumImpact();

    String targetProductId;
    switch (_selectedTier) {
      case 0: targetProductId = AppConstants.iapProWeekly; break;
      case 1: targetProductId = AppConstants.iapProMonthly; break;
      case 3: targetProductId = AppConstants.iapProLifetime; break;
      case 2:
      default: targetProductId = AppConstants.iapProYearly; break;
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
      _loadStoreProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("正在透過 Apple 加密通道獲取最新商品定價，請稍候重試..."),
            backgroundColor: Color(0xFF0077B6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final premiumState = ref.watch(premiumProvider);
    final int seatsLeft = _getDynamicScarcitySeats();

    ref.listen<PremiumState>(premiumProvider, (previous, next) {
      if (next.isPremium && (previous == null || !previous.isPremium)) {
        HapticFeedback.heavyImpact();
      }
    });

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
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLoadingProducts ? Icons.sync_rounded : Icons.apple_rounded, 
                          color: const Color(0xFF00B4D8), 
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isLoadingProducts ? "定價同步中..." : "Apple StoreKit 安全支付", 
                          style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                      ],
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
                    if (!premiumState.isPremium)
                      _buildDynamicUrgencyBanner(),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
                        border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFF00B4D8), size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      premiumState.isPremium ? "您已是老船長尊榮會員" : "解鎖老船長 AI 專業旗艦版",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "85 測站光纖直連 0 延遲 · 38ms 極速響應 · 全島離線神盾",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 14),

                    _buildCohortSelector(),
                    const SizedBox(height: 14),

                    if (premiumState.isPremium) ...[
                      _buildUnlockedCard(premiumState),
                      const SizedBox(height: 20),
                    ] else ...[
                      _buildTierCard(
                        index: 0,
                        title: "週費體驗版",
                        price: _getLocalizedPrice(AppConstants.iapProWeekly, AppConstants.priceWeekly),
                        unit: " / 週",
                        subDesc: "單次週末出海衝刺體驗",
                        badge: null,
                      ),
                      const SizedBox(height: 8),

                      _buildTierCard(
                        index: 1,
                        title: "月度專業版",
                        price: _getLocalizedPrice(AppConstants.iapProMonthly, AppConstants.priceMonthly),
                        unit: " / 月",
                        subDesc: "當季黑毛 / 軟絲釣汛首選",
                        badge: "熱門首選",
                      ),
                      const SizedBox(height: 8),

                      _buildTierCard(
                        index: 2,
                        title: "年度指揮官計畫",
                        price: _getLocalizedPrice(AppConstants.iapProYearly, AppConstants.priceYearly),
                        unit: " / 年",
                        subDesc: "主力推薦 · 支援 Apple 家人共享",
                        badge: "🔥 7天免費試用 · 支援家人共享",
                        isHighlight: true,
                      ),
                      const SizedBox(height: 8),

                      _buildTierCard(
                        index: 3,
                        title: "終身創始席次",
                        price: _getLocalizedPrice(AppConstants.iapProLifetime, AppConstants.priceLifetime),
                        unit: " / 永久",
                        subDesc: "本月額度僅剩 $seatsLeft 席 · 終身免除後續所有訂閱費",
                        badge: "⚡ 創始天尊 · 限量買斷",
                        isGold: true,
                        warningHighlight: seatsLeft <= 5,
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (!premiumState.isPremium && (_selectedTier == 2 || _selectedTier == 3)) ...[
                      _buildValueStackingCard(),
                      _buildBonusMatrixCard(),
                      const SizedBox(height: 18),
                    ],

                    ..._buildCohortFeaturesList(),
                    const SizedBox(height: 18),

                    if (!premiumState.isPremium)
                      _buildRiskReversalGuarantee(),
                    const SizedBox(height: 14),

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
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 14, color: Colors.white70),
                              SizedBox(width: 6),
                              Text(
                                "【App Store 訂閱及免費試用條款說明】", 
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "• 「年度指揮官計畫」提供 7 天免費試用。試用期結束後，系統將自動從您的 Apple ID 帳戶收取訂閱費用，除非您在計費週期結束至少 24 小時前取消。\n"
                            "• 各方案費用將依據您當地 App Store 的幣值顯示，購買後由 Apple ID 帳戶安全扣款。\n"
                            "• 訂閱將自動續訂，帳戶將在當前計費週期結束前 24 小時內收取續訂費用。您可在購買後隨時前往「App Store 帳號設定 > 訂閱項目」輕鬆管理或取消續訂。\n"
                            "• 「終身創始席次」為一次性非消耗型買斷商品，無需自動續訂。",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        InkWell(
                          onTap: () => _launchURL(_appleEulaUrl),
                          child: Text("使用條款 (EULA)", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, decoration: TextDecoration.underline)),
                        ),
                        Text("•", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                        InkWell(
                          onTap: () => _launchURL(_privacyUrl),
                          child: Text("隱私權政策", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, decoration: TextDecoration.underline)),
                        ),
                        Text("•", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                        InkWell(
                          onTap: () => _launchURL(_appleManageSubUrl),
                          child: Text("退訂與訂閱管理", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, decoration: TextDecoration.underline)),
                        ),
                        Text("•", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
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
                          child: Text("恢復購買", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, decoration: TextDecoration.underline)),
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
                    height: 50,
                    child: ElevatedButton(
                      onPressed: premiumState.isPremium
                          ? () {
                              HapticFeedback.heavyImpact();
                              Navigator.pushReplacement(
                                context, 
                                MaterialPageRoute(builder: (_) => const VipCenterPage())
                              );
                            }
                          : (_isLoadingProducts ? null : _handlePurchase),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: premiumState.isPremium 
                            ? AppColors.bioGold
                            : (_selectedTier == 3 
                                ? Colors.amberAccent 
                                : (_selectedTier == 2 ? const Color(0xFF00B4D8) : Colors.white12)),
                        foregroundColor: premiumState.isPremium
                            ? Colors.black87
                            : (_selectedTier == 3 ? Colors.black87 : Colors.white),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          premiumState.isPremium
                              ? "👑 進入 VIP 航海指揮中心"
                              : (_selectedTier == 2 
                                  ? "開啟 7 天免費試用 (滿期 ${_getLocalizedPrice(AppConstants.iapProYearly, AppConstants.priceYearly)}/年)"
                                  : (_selectedTier == 3 
                                      ? "取得終身創始席次 (${_getLocalizedPrice(AppConstants.iapProLifetime, AppConstants.priceLifetime)})" 
                                      : (_selectedTier == 1 
                                          ? "立即訂閱月度版 (${_getLocalizedPrice(AppConstants.iapProMonthly, AppConstants.priceMonthly)}/月)" 
                                          : "開啟週度體驗 (${_getLocalizedPrice(AppConstants.iapProWeekly, AppConstants.priceWeekly)}/週)"))),
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  if (!premiumState.isPremium) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _closePaywall,
                      child: Text(
                        "先以免費版體驗 (功能受限)", 
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11.5),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicUrgencyBanner() {
    final now = DateTime.now();
    int daysToSaturday = DateTime.saturday - now.weekday;
    if (daysToSaturday < 0) daysToSaturday += 7; 

    String urgencyText;
    Color highlightColor = AppColors.hazardCoral;
    IconData urgencyIcon = Icons.access_time_filled_rounded;

    if (daysToSaturday == 0 || daysToSaturday == 6) { 
      urgencyText = "週末海象高峰進行中！出海前務必啟動雷達與長湧預警！";
      urgencyIcon = Icons.warning_rounded;
    } else if (daysToSaturday == 1) { 
      urgencyText = "戰備倒數：距離週末出海黃金窗口僅剩最後 24 小時！";
    } else { 
      urgencyText = "行動倒數：距離本週末出海黃金窗口僅剩 $daysToSaturday 天！";
      highlightColor = const Color(0xFFFF9500); 
    }

    return AnimatedBuilder(
      animation: _urgencyPulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: highlightColor.withValues(alpha: 0.15 + (_urgencyPulseController.value * 0.1)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: highlightColor.withValues(alpha: 0.5), width: 1.0),
            boxShadow: [
              BoxShadow(color: highlightColor.withValues(alpha: 0.15 * _urgencyPulseController.value), blurRadius: 8, spreadRadius: 2)
            ],
          ),
          child: Row(
            children: [
              Icon(urgencyIcon, color: highlightColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  urgencyText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 2)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskReversalGuarantee() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_rounded, size: 18, color: Color(0xFF34D399)),
              SizedBox(width: 8),
              Text(
                "老船長 100% 實海驗證無風險承諾", 
                style: TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "我們不玩文字遊戲。本週末，請直接帶著 Tide Pro 旗艦版上礁石或上船實戰。\n\n"
            "如果您覺得 85 站光纖直連沒有比免費天氣 App 更精準，或者 AI 瘋狗浪預警沒有讓您感到極致的安全感...\n\n"
            "您只需在 7 天內進入 Apple ID 一鍵取消訂閱。不需打電話、不需跟任何人解釋，您不會損失任何一毛錢。\n\n"
            "所有的風險，由我們來承擔。",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusMatrixCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bioGold.withValues(alpha: 0.15), const Color(0xFF2C1802)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.6), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: AppColors.bioGold, size: 18),
              SizedBox(width: 8),
              Text(
                "🎁 訂閱加碼：今日立享 3 大尊榮贈品", 
                style: TextStyle(color: AppColors.bioGold, fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBonusRow("Apple 家人共享", "一人訂閱，5 位同行親友免費享有 PRO 權限", "價值 NT\$ 4,950/年"),
          _buildBonusRow("VVIP 優先客服通道", "工單免排隊，3 秒直通創辦人手機推送", "價值 NT\$ 3,600/年"),
          _buildBonusRow("85 站水文百科指南", "內建台灣沿海特有魚種索餌習性與潮目對照表", "價值 NT\$ 1,200"),
        ],
      ),
    );
  }

  Widget _buildBonusRow(String title, String desc, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(Icons.add_circle_rounded, color: AppColors.bioGold, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                    Text(value, style: const TextStyle(color: AppColors.bioGold, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueStackingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF062343).withValues(alpha: 0.8), const Color(0xFF021B33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_rounded, color: Color(0xFF00B4D8), size: 18),
              SizedBox(width: 8),
              Text(
                "專屬旗艦軍火庫價值清單", 
                style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildValueRow("中央氣象署 85 站光纖直連", "NT\$ 1,200/年"),
          _buildValueRow("AI 長湧瘋狗浪預警引擎", "NT\$ 1,800/年"),
          _buildValueRow("離線神盾全島水文預載", "NT\$ 600/年"),
          _buildValueRow("E-Ink 烈日抗反光航海模式", "NT\$ 800/年"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("核心模塊真實價值", style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text("NT\$ 4,400 /年", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, decoration: TextDecoration.lineThrough)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(String item, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF30D158), size: 14),
              const SizedBox(width: 8),
              Text(item, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Text(value, style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _buildCohortSelector() {
    final cohorts = ["🎣 外礁磯釣客", "🚤 駕駛台船長", "🤿 自潛與衝浪"];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(cohorts.length, (idx) {
          final isSelected = _selectedCohortIndex == idx;
          return Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCohortIndex = idx);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00B4D8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    cohorts[idx],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildCohortFeaturesList() {
    if (_selectedCohortIndex == 0) {
      return [
        _buildFeatureRow(Icons.waves_rounded, "外海 10 秒以上深層長湧 (瘋狗浪) 動能通量即時預警"),
        _buildFeatureRow(Icons.notifications_active_outlined, "滿潮前 30 分鐘主動發布撤礁防困警報，守護人身安全"),
        _buildFeatureRow(Icons.phishing_rounded, "黑毛、白毛、黑鯛活性指數與滿退 2 分水大咬黃金期換算"),
        _buildFeatureRow(Icons.download_for_offline_rounded, "85 測站一鍵離線神盾預載，外礁斷網照常秒級導航"),
      ];
    } else if (_selectedCohortIndex == 1) {
      return [
        _buildFeatureRow(Icons.bolt_rounded, "中央氣象署 85 測站光纖直連專線，38ms 官方遙測 0 延遲"),
        _buildFeatureRow(Icons.speed_rounded, "全台 23 座浮標與 62 潮位站智慧雙向路由，乾潮底吃水暗礁預警"),
        _buildFeatureRow(Icons.wb_sunny_rounded, "全新「純潮汐航海儀表模式」，高對比防反光，螢幕常亮永不熄火"),
        _buildFeatureRow(Icons.groups_rounded, "完整支援 Apple 家人共享，船長訂閱全員享有 PRO 特權"),
      ];
    } else {
      return [
        _buildFeatureRow(Icons.thermostat_rounded, "海水表溫與海溫躍層 ΔT 即時監控，掌握澄澈微流窗口"),
        _buildFeatureRow(Icons.water_rounded, "即時波高消長、浪向角度與蒲福風級階梯連續走勢"),
        _buildFeatureRow(Icons.history_toggle_off_rounded, "30 天時間序列金庫與歷史天文調和模型精確回測"),
        _buildFeatureRow(Icons.cloud_upload_rounded, "無限張數雲端高畫質相簿，永久備份每次下海冒險標本"),
      ];
    }
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
    bool warningHighlight = false,
  }) {
    final bool isSelected = _selectedTier == index;
    Color borderColor = Colors.white.withValues(alpha: 0.12);
    if (isSelected) {
      borderColor = isGold ? Colors.amberAccent : (isHighlight ? const Color(0xFF00B4D8) : Colors.white);
    }
    if (warningHighlight && isGold) {
      borderColor = AppColors.hazardCoral;
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTier = index);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isGold ? Colors.amber.withValues(alpha: 0.12) : const Color(0xFF00B4D8).withValues(alpha: 0.1)) 
              : Colors.white.withValues(alpha: 0.05),
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
                  Text(
                    subDesc, 
                    style: TextStyle(
                      color: warningHighlight ? AppColors.hazardCoral : (isSelected ? (isGold ? Colors.amberAccent : const Color(0xFF00B4D8)) : Colors.white38), 
                      fontSize: 10.5, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
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
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VipCenterPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00B4D8), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
