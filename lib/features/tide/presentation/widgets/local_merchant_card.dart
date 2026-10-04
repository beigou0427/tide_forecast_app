import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🌟 經海事嚴謹標準重塑之港口補給與在地聯絡資訊卡
/// 具備濕手防誤觸二次確認閥門，剔除浮誇廣告，專注港區安全與即時水文諮詢
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
    final isLight = Theme.of(context).brightness == Brightness.light;

    final Color titleColor = isLight ? AppColors.classicText : AppColors.textPrimary;
    final Color badgeColor = isLight ? const Color(0xFF0077B6) : AppColors.pelagicCyan;

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 頂部推薦標題列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.anchor_rounded, color: badgeColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "港區補給與海事聯絡點",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "在地活餌常備 · 港況諮詢 · 海事支援",
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
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 11, color: badgeColor),
                    const SizedBox(width: 3),
                    Text(
                      "在地資訊",
                      style: TextStyle(color: badgeColor, fontSize: 9.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. 商戶真實資訊卡
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isLight ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight ? Colors.grey.shade200 : AppColors.glassBorder, 
                width: 0.5,
              ),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        merchant["distance"]!,
                        style: TextStyle(fontSize: 10.5, color: badgeColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 13, color: isLight ? Colors.blueGrey : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        merchant["commonBait"]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: isLight ? Colors.blueGrey.shade800 : AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.directions_boat_filled_rounded, size: 13, color: isLight ? Colors.blueGrey : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        merchant["boatAdvisory"]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: isLight ? Colors.blueGrey.shade800 : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. 通訊與導航按鈕 (🌟 注入濕手二次確認防誤觸閥門)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          backgroundColor: isLight ? Colors.white : Colors.white.withValues(alpha: 0.05),
                          side: BorderSide(color: isLight ? Colors.grey.shade300 : AppColors.glassBorder, width: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(Icons.phone_in_talk_rounded, size: 14, color: badgeColor),
                        label: Text(
                          "電洽確認活餌與港況",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: badgeColor),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showCallConfirmDialog(context, merchant["name"]!, merchant["phone"]!);
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
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Icon(Icons.navigation_rounded, size: 16, color: badgeColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4. 海事安全宣導告示
          Text(
            "⚠️ 海事安全提醒：各港口活餌與出港管制受當日即時海象限制。登礁出海作業前，請依規定穿戴救生衣與防滑釘鞋，並向港區海巡安檢所落實報關。",
            style: TextStyle(
              fontSize: 10, 
              color: isLight ? Colors.grey.shade600 : AppColors.textTertiary, 
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getMerchantInfo(String reg, String name) {
    if (reg.contains("北")) {
      return {
        "name": "東北角海釣補給驛站 (碧砂/龍洞端)",
        "distance": "距測站約 2.5 km",
        "commonBait": "常備餌料：活白蝦、青磺蝦、生鮮南極蝦磚",
        "boatAdvisory": "船班諮詢：近海夜釣與渡礁船班需提前確認海況",
        "phone": "0224690000",
      };
    } else if (reg.contains("西")) {
      return {
        "name": "台中港區專業海釣餌料行",
        "distance": "距港區約 1.8 km",
        "commonBait": "常備餌料：跳蟲、紅蟲、活沙蝦、紅蟳",
        "boatAdvisory": "釣點交流：提供港區最新水色與風浪情報諮詢",
        "phone": "0426560000",
      };
    } else if (reg.contains("南")) {
      return {
        "name": "興達港/蚵仔寮船釣聯絡處",
        "distance": "距港口約 1.2 km",
        "commonBait": "常備餌料：現撈小卷、活巴朗、大活蝦",
        "boatAdvisory": "船班諮詢：近海鐵板船班開航需以當日風浪為準",
        "phone": "076980000",
      };
    } else if (reg.contains("東")) {
      return {
        "name": "花蓮港/成功磯釣補給基地",
        "distance": "距下竿點約 3.0 km",
        "commonBait": "常備餌料：冷凍白毛誘餌磚、特選南極蝦",
        "boatAdvisory": "外礁渡礁：東海岸長湧時嚴禁渡礁，請先電洽",
        "phone": "038320000",
      };
    } else {
      return {
        "name": "澎湖外海海釣快艇聯絡處",
        "distance": "距碼頭約 800 m",
        "commonBait": "常備餌料：活丁香、特級海蟲、小卷",
        "boatAdvisory": "船班預約：七美/望安海釣快艇行程需事先預定",
        "phone": "069270000",
      };
    }
  }

  /// 🌟 駕駛台濕手防誤觸撥號確認閥門
  void _showCallConfirmDialog(BuildContext context, String merchantName, String tel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.abyssCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: AppColors.pelagicCyan, size: 20),
            SizedBox(width: 8),
            Text(
              "通話確認", 
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "是否立即致電【$merchantName】？\n電話：$tel",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消", style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pelagicCyan,
              foregroundColor: AppColors.abyssBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final Uri url = Uri.parse("tel:$tel");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: const Text("確認撥號", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMap(String query) async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}