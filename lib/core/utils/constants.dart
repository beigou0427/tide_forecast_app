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
  
  static String get officialApiKey => SecurityUtil.decryptBytes(const [0x37, 0x3e, 0x25, 0x48, 0x68, 0x21, 0x5b, 0x59, 0x29, 0x50, 0x5f, 0x53, 0x72, 0x50, 0x57, 0x5b, 0x41, 0x48, 0x46, 0x1b, 0x44, 0x50, 0x4b, 0x5c, 0x66, 0x05, 0x04, 0x1f, 0x76, 0x47, 0x28, 0x5d, 0x56, 0x1d, 0x5a, 0x5c, 0x5a, 0x29, 0x54, 0x5f]);

  static const String dsObservation = "O-B0075-002";
  static const String dsForecast = "F-A0021-001";
  
  // 🌟 App Store Connect 商品 ID 對齊
  // (請在蘋果後台為 Monthly 與 Yearly 加上「推介優惠：7 天免費試用」)
  static const String iapProWeekly = "com.beigou.tide_app.pro_weekly";     // 內部福利發送專用
  static const String iapProMonthly = "com.beigou.tide_app.pro_monthly";   // 月度航海員 (含7天試用)
  static const String iapProYearly = "com.beigou.tide_app.pro_yearly";     // 年度指揮官 (含7天試用)
  static const String iapProLifetime = "com.beigou.tide_app.pro_lifetime"; // 終身創始席次 (買斷無試用)
  
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