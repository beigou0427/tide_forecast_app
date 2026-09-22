import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/custom_card.dart';

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
    // 依據海域自動匹配在地特約釣具行與船班情報
    final merchant = _getMerchantInfo(region, stationName);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFFB8860B), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("周邊特約補給站 & 船班", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("在地釣具 • 活餌現貨 • 船班預約", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade300, width: 0.8),
                ),
                child: const Text("特約認證", style: TextStyle(color: Color(0xFF795548), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF021B33).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      merchant["name"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF021B33)),
                    ),
                    Text(
                      merchant["distance"]!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0077B6), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 13, color: Colors.teal),
                    const SizedBox(width: 4),
                    Text(merchant["liveBait"]!, style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.directions_boat_filled_outlined, size: 13, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(merchant["boatStatus"]!, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700)),
                  ],
                ),
                const SizedBox(height: 12),

                // 撥打電話與導航動作按鈕
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF0077B6)),
                        label: const Text("撥打訂餌/查船班", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0077B6))),
                        onPressed: () => _launchCaller(merchant["phone"]!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6).withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.navigation_outlined, size: 18, color: Color(0xFF0077B6)),
                      onPressed: () => _launchMap(merchant["name"]!),
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
