import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🍏 Apple 首席設計工藝：港口前哨站與特約船班 (零溢出安全版)
class LocalMerchantCard extends StatelessWidget {
  final String stationName;
  final String region;

  const LocalMerchantCard({
    super.key,
    required this.stationName,
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    final merchant = _getMerchantInfo(region, stationName);

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 頂部特約證書標題列 (注入雙層彈性約束，徹底杜絕小螢幕溢出)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.bioGold.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.bioGold, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "周邊特約補給站 & 船班",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "在地釣具 · 活餌現貨 · 渡礁預約",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.bioGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.35), width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 11, color: AppColors.bioGold),
                    SizedBox(width: 3),
                    Text(
                      "特約認證",
                      style: TextStyle(color: AppColors.bioGold, fontSize: 9.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. 黑曜石玻璃商家資訊卡
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        merchant["name"]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.pelagicCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        merchant["distance"]!,
                        style: const TextStyle(fontSize: 10.5, color: AppColors.pelagicCyan, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF30D158)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        merchant["liveBait"]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF30D158), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.directions_boat_filled_rounded, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        merchant["boatStatus"]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. 觸覺原生通訊按鍵
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 14, color: AppColors.pelagicCyan),
                        label: const Text(
                          "撥打訂餌 / 查船班",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.pelagicCyan),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _launchCaller(merchant["phone"]!);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _launchMap(merchant["name"]!);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.pelagicCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.pelagicCyan.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: const Icon(Icons.navigation_rounded, size: 16, color: AppColors.pelagicCyan),
                      ),
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

  Map<String, String> _getMerchantInfo(String reg, String name) {
    if (reg.contains("北")) {
      return {
        "name": "東北角海釣補給驛站 (碧砂/龍洞店)",
        "distance": "距釣點約 2.5 km",
        "liveBait": "現貨供應：活白蝦、青磺蝦、特級南極蝦",
        "boatStatus": "週末近海夜釣船班：尚餘 3 席空位",
        "phone": "0224690000",
      };
    } else if (reg.contains("西")) {
      return {
        "name": "台中港區專業海釣餌料行",
        "distance": "距港區約 1.8 km",
        "liveBait": "現貨供應：跳蟲、紅蟲、活沙蝦、紅蟳",
        "boatStatus": "外海沉底遠投交流聚集點",
        "phone": "0426560000",
      };
    } else if (reg.contains("南")) {
      return {
        "name": "興達港/蚵仔寮船釣聯絡處",
        "distance": "距港口約 1.2 km",
        "liveBait": "現貨供應：現撈小卷、活巴朗、大活蝦",
        "boatStatus": "明日清晨鐵板船班：尚餘 2 席空位",
        "phone": "076980000",
      };
    } else if (reg.contains("東")) {
      return {
        "name": "花蓮港/成功磯釣補給基地",
        "distance": "距下竿點約 3.0 km",
        "liveBait": "現貨供應：冷凍白毛誘餌磚、生鮮南極蝦",
        "boatStatus": "外礁渡礁船接送服務登記中",
        "phone": "038320000",
      };
    } else {
      return {
        "name": "澎湖外海海釣快艇俱樂部",
        "distance": "距碼頭約 800 m",
        "liveBait": "現貨供應：活丁香、特級海蟲、小卷",
        "boatStatus": "七美/望安海釣快艇預約專線",
        "phone": "069270000",
      };
    }
  }

  Future<void> _launchCaller(String tel) async {
    final Uri url = Uri.parse("tel:$tel");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _launchMap(String query) async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}