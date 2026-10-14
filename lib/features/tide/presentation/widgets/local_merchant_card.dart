import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_card.dart';

/// 🌟 經海事航安與真實水文標準重塑之港區補給雷達與海難救護中心
/// 100% 真實可用版：
/// 1. 拒絕虛假特約，改以地圖 API 即時動態搜尋周邊真實活餌釣具行。
/// 2. 整合海委會海巡署 118 官方 24 小時海上緊急救難直通專線。
/// 3. 深度適配深淵黑金、經典白藍、E-Ink 烈日抗反光三模光學標準。
class LocalMerchantCard extends ConsumerWidget {
  final String stationName;
  final String region;

  const LocalMerchantCard({
    super.key,
    required this.stationName,
    required this.region,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;

    final Color titleColor = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color badgeColor = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
    final Color subtitleColor = isEInk 
        ? Colors.black54 
        : (isClassic ? Colors.grey.shade600 : AppColors.textTertiary);
    final Color emergencyColor = isEInk ? Colors.black : AppColors.hazardCoral;

    final Color innerBg = isEInk 
        ? Colors.white 
        : (isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.04));
    final Color innerBorder = isEInk 
        ? Colors.black 
        : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder);

    // 乾淨的測站名稱作為地圖搜尋關鍵字
    final String cleanStation = stationName.replaceAll(RegExp(r'[\(（].*?[\)）]'), '').trim();

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 頂部標題列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isEInk ? Colors.black.withValues(alpha: 0.08) : badgeColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.radar_rounded, color: badgeColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "港區補給雷達與海事支援",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                  color: titleColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isEInk ? Colors.black12 : badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "實時定位",
                                  style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "[$cleanStation] 周邊釣具活餌搜尋 · 海難緊急專線",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. 地圖動態搜尋入口卡片
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: innerBorder, 
                width: isEInk ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "📍 尋找 [$cleanStation] 周邊釣具行",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: titleColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isEInk ? Colors.black12 : badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "即時地圖",
                        style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "出海作釣缺南極蝦磚、活白蝦或鉛線？一鍵開啟地圖即時搜尋附近營業中的釣具餌料行與導航路線。",
                  style: TextStyle(fontSize: 11.5, color: subtitleColor, height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEInk ? Colors.black : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan),
                      foregroundColor: isEInk ? Colors.white : (isClassic ? Colors.white : AppColors.abyssBlack),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.near_me_rounded, size: 16),
                    label: const Text(
                      "在地圖上搜尋周邊釣具與餌料行", 
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _launchMapSearch(context, "$cleanStation 釣具 餌料");
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. 官方海事緊急救難聯絡網 (海巡 118)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEInk ? Colors.white : emergencyColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isEInk ? Colors.black : emergencyColor.withValues(alpha: 0.35),
                width: isEInk ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEInk ? Colors.black12 : emergencyColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.emergency_rounded, color: emergencyColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "海巡署 118 海上緊急報案專線",
                            style: TextStyle(
                              fontWeight: FontWeight.w900, 
                              fontSize: 12.5, 
                              color: isEInk ? Colors.black : (isClassic ? Colors.red.shade900 : Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "突發湧浪困礁、落水意外或海難事故，請立即撥打",
                        style: TextStyle(fontSize: 10.5, color: isEInk ? Colors.black54 : (isClassic ? Colors.red.shade700 : Colors.white70)),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: emergencyColor, width: 1.0),
                    foregroundColor: emergencyColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showEmergencyCallDialog(context, isClassic, isEInk),
                  child: const Text("撥打 118", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyCallDialog(BuildContext context, bool isClassic, bool isEInk) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isEInk ? Colors.white : (isClassic ? Colors.white : AppColors.abyssCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.hazardCoral, size: 24),
            SizedBox(width: 8),
            Text("海巡署緊急救援通報", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: const Text(
          "即將撥打海洋委員會海巡署【118】免付費緊急救援服務專線。\n\n如遇人員落海、礁石受困或緊急海難，請保持冷靜向值班人員報出當前測站地名與地標方位。",
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.hazardCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final Uri url = Uri.parse("tel:118");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: const Text("確認撥打 118", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMapSearch(BuildContext context, String query) async {
    final Uri googleMapUrl = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
    try {
      if (await canLaunchUrl(googleMapUrl)) {
        await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
      } else {
        final Uri appleMapUrl = Uri.https('maps.apple.com', '/', {'q': query});
        if (await canLaunchUrl(appleMapUrl)) {
          await launchUrl(appleMapUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("地圖開啟異常: $e"), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}
