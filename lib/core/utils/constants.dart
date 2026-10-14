import 'security_util.dart';

class StationModel {
  final String id;
  final String name;
  final String region;
  final bool isBuoy;
  final double lat;
  final double lng;
  final String stationType;
  final String agency;

  const StationModel({
    required this.id,
    required this.name,
    required this.region,
    this.isBuoy = false,
    required this.lat,
    required this.lng,
    this.stationType = "海象站",
    this.agency = "中央氣象署",
  });

  // 8 大基準口岸站免費，其餘 77 席深海/外礁站標註為 PRO 專屬
  bool get isProOnly => !AppConstants.freeStationIds.contains(id);

  factory StationModel.fromJson(Map<String, dynamic> json) {
    final bool buoy = json['isBuoy'] ?? false;
    return StationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '未知測站',
      region: json['region'] ?? '未知',
      isBuoy: buoy,
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      stationType: json['stationType'] ?? (buoy ? "資料浮標" : "潮位站"),
      agency: json['agency'] ?? "中央氣象署",
    );
  }
}

class AppConstants {
  static const String officialBaseUrl = "https://opendata.cwa.gov.tw/api/v1/rest/datastore";
  
  // 🌟 長官專屬神鑰：CWA-0B848F9A-6643-41CE-9631-05EAB31DF1DE (40-byte 完美遮罩加密版)
  static String get officialApiKey => SecurityUtil.decryptBytes(const [
    0x37, 0x3E, 0x25, 0x48, 0x6F, 0x21, 0x57, 0x59, 0x55, 0x27, 0x57, 0x25,
    0x72, 0x55, 0x53, 0x5A, 0x47, 0x48, 0x46, 0x6E, 0x30, 0x24, 0x4B, 0x5C,
    0x69, 0x01, 0x01, 0x1F, 0x04, 0x41, 0x2C, 0x25, 0x27, 0x6C, 0x52, 0x2B,
    0x2B, 0x5C, 0x25, 0x2B
  ]);

  static const String dsObservation = "O-B0075-002";
  static const String dsForecast = "F-A0021-001";
  
  static const String iapProWeekly = "com.beigou.tide_app.pro_weekly";
  static const String iapProMonthly = "com.beigou.tide_app.pro_monthly";
  static const String iapProYearly = "com.beigou.tide_app.pro_yearly";
  static const String iapProLifetime = "com.beigou.tide_app.pro_lifetime";

  // 🌟 StoreKit 官方定價備援常數 (使用 Raw String r"..." 徹底消滅貨幣符號插值報錯)
  static const String priceWeekly = r"NT$ 60";
  static const String priceMonthly = r"NT$ 120";
  static const String priceYearly = r"NT$ 990";
  static const String priceLifetime = r"NT$ 2,990";

  // 🌟 免費用戶雲端漁獲日誌照片上限 (COGS 伺服器成本防禦線)
  static const int maxFreeCloudCatchLogs = 5;
  
  static const Set<String> iapProductIds = {
    iapProWeekly,
    iapProMonthly,
    iapProYearly,
    iapProLifetime,
  };

  // 8 大免費體驗基準測站 (大港口岸)
  static const Set<String> freeStationIds = {
    "46694A", // 龍洞資料浮標
    "C4A01",  // 淡水潮位站
    "C4B01",  // 基隆潮位站
    "C4D01",  // 新竹潮位站
    "C4F01",  // 臺中港潮位站
    "C4P01",  // 高雄潮位站
    "C4T01",  // 花蓮潮位站
    "C4W02",  // 澎湖潮位站
  };

  static const List<String> regions = ["北部", "西部", "南部", "東部", "離島"];
  static const String remoteStationsUrl = "https://beigou0427.github.io/tide_forecast_app/stations_config.json";

  static const List<StationModel> fallbackStations = [
    StationModel(id: "46694A", name: "新北貢寮 龍洞資料浮標 (46694A)", region: "北部", isBuoy: true, lat: 25.037, lng: 121.926, stationType: "資料浮標"),
    StationModel(id: "C4A01", name: "新北淡水 淡水潮位站 (C4A01)", region: "北部", lat: 25.175, lng: 121.424, stationType: "潮位站"),
  ];
}
