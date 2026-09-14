import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart'; // 🌟 引入用於開啟網頁
import '../services/premium_service.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/widgets/custom_card.dart';

// 🌟 核心 Provider：從商店獲取真實產品清單與價格
final storeProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final iapManager = ref.read(iapManagerProvider);
  return await iapManager.fetchProducts();
});

class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  // 🌟 輔助方法：開啟 Gist 連結
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("無法開啟網址: $urlString");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 監聽本地付費狀態
    final premiumState = ref.watch(premiumProvider);
    // 監聽商店產品資訊 (動態價格)
    final productsAsync = ref.watch(storeProductsProvider);

    // 您的法律條款連結
    const String legalUrl = "https://gist.github.com/beigou0427/99e6eddb729ae53eb8e7474866f3f009";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "專業版會員計畫",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. 頂部品牌橫幅 ---
            _buildPremiumHeader(premiumState.isPremium),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. 方案選擇區 ---
                  if (!premiumState.isPremium) ...[
                    const Text(
                      "選擇您的計畫",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 12),
                    
                    productsAsync.when(
                      data: (List<ProductDetails> products) {
                        if (products.isEmpty) {
                          return _buildNoStoreDataUI();
                        }
                        
                        try {
                          final yearlyProduct = products.firstWhere(
                            (p) => p.id == AppConstants.iapProYearly
                          );
                          final monthlyProduct = products.firstWhere(
                            (p) => p.id == AppConstants.iapProMonthly
                          );

                          return Column(
                            children: [
                              _buildIAPPlanCard(
                                context, ref,
                                product: yearlyProduct,
                                title: "年度指揮官計畫",
                                desc: "解鎖 60 天數據，現省 24%",
                                isBestValue: true,
                              ),
                              const SizedBox(height: 16),
                              _buildIAPPlanCard(
                                context, ref,
                                product: monthlyProduct,
                                title: "月度專業計畫",
                                desc: "彈性訂閱，隨時可取消",
                                isBestValue: false,
                              ),
                            ],
                          );
                        } catch (e) {
                          return const Center(child: Text("商店產品配置不完整"));
                        }
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Center(child: Text("無法連線至 App Store: $err")),
                    ),
                  ] else ...[
                    _buildSubscriptionStatusCard(context, ref, premiumState),
                  ],

                  const SizedBox(height: 32),
                  
                  // --- 3. 特權清單 ---
                  const Text(
                    "Pro 會員專屬特權",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(Icons.history_rounded, "30 天深度歷史回測", "觀測過去一個月內每一小時的風浪數據"),
                  _buildFeatureItem(Icons.calendar_view_month_rounded, "1 個月遠期潮汐預報", "提前規劃未來一個月的行程"),
                  _buildFeatureItem(Icons.block_flipped, "純淨無廣告體驗", "移除所有干擾資訊，專注於海象分析"),
                  _buildFeatureItem(Icons.cloud_download_rounded, "優先數據加載", "使用專屬伺服器線路，數據更新更及時"),

                  const SizedBox(height: 40),
                  
                  // --- 4. 🌟 法律宣告與恢復購買 (Apple 審核必備) ---
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "訂閱將透過您的商店帳號扣款並自動續費",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 🌟 連結到您的 Gist
                            _buildFooterLink("服務條款", () => _launchURL(legalUrl)),
                            const Text(" | ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            _buildFooterLink("隱私政策", () => _launchURL(legalUrl)),
                            const Text(" | ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            // 🌟 恢復購買功能
                            _buildFooterLink("恢復購買", () {
                              ref.read(iapManagerProvider).restorePurchases();
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIAPPlanCard(
    BuildContext context, 
    WidgetRef ref, {
    required ProductDetails product,
    required String title,
    required String desc,
    required bool isBestValue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBestValue ? Colors.amber : Colors.grey.shade200, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          if (isBestValue)
            Positioned(
              top: 0, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                child: const Text("最划算", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.price, 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0077B6)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(iapManagerProvider).buySubscription(product);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        elevation: 0,
                      ),
                      child: const Text("選擇", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(bool isPro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF023E8A), Color(0xFF0077B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(isPro ? Icons.stars_rounded : Icons.workspace_premium_rounded, size: 80, color: Colors.amber),
          const SizedBox(height: 20),
          Text(
            isPro ? "您已解鎖專業權限" : "升級專業版計畫",
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "掌握全台 86 個測站，解鎖完整 60 天數據",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF0077B6).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF0077B6), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStatusCard(BuildContext context, WidgetRef ref, PremiumState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          Text(
            "會員方案：${state.type == SubscriptionType.monthly ? '月費訂閱' : '年度訂閱'}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text("服務已解鎖，享受完整海象大數據", style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => ref.read(premiumProvider.notifier).cancelSubscription(),
            child: const Text("管理訂閱設定", style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoStoreDataUI() {
    return const CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text("目前無法連線至商店", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("請檢查網路或實機進行沙盒測試", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF0077B6), decoration: TextDecoration.underline),
      ),
    );
  }
}