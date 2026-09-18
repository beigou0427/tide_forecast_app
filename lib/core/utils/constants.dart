import 'security_util.dart';

class StationModel {
  final String id;
  final String name;
  final String region;
  final bool isBuoy;
  final double lat;
  final double lng;

  const StationModel({
    required this.id, required this.name, required this.region, 
    this.isBuoy = false, required this.lat, required this.lng
  });

  // 🌟 新增：讓測站可以從 JSON 動態生成
  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '未知測站',
      region: json['region'] ?? '未知',
      isBuoy: json['isBuoy'] ?? false,
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }
}

class AppConstants {
  static const String proxyUrl = "https://superiorapis-creator.cteam.com.tw/manager/feature/proxy/9ba80bfcd6ad/pub_9c67411cf4c9";
  static String get proxyToken => SecurityUtil.decrypt(
    "Xh0SEx4fFBAXEhgeFhMbEhUXERITHBYfEB4XGhMVFhITHhIVExUSFhUbEhUXERUUGxISEh4SEx4fFBAXEhgeFhMcExYTGhMUGxYfEB4XGhMVFhITHhIVExUfFhYbEhUfFxMUGxISEh4SEx4fExUXFxMWHhIVExUUGxIXHhMTExUbFhMVHhIXHRIU"
  );

  static const String officialBaseUrl = "https://opendata.cwa.gov.tw/api/v1/rest/datastore";
  static String get officialApiKey => SecurityUtil.decrypt(
    "FxcNGQYIDh0UGRsAFxUZBhodGAAUHBoYGRkZFxUeGRkVGxsYGRkZFxcbGQYZGw=="
  );
  
  static const String dsObservation = "O-B0075-002";
  static const String dsForecast = "F-A0021-001";

  static const String iapProMonthly = "com.beigou.tide_app.pro_monthly";
  static const String iapProYearly = "com.beigou.tide_app.pro_yearly";
  static const Set<String> iapProductIds = {iapProMonthly, iapProYearly};
  static const List<String> regions = ["北部", "西部", "南部", "東部", "離島"];

  // 🌟 核心：雲端測站配置檔的存放網址
  static const String remoteStationsUrl = "https://beigou0427.github.io/tide_forecast_app/stations_config.json";

  // 🌟 保底：只留兩個最基礎的測站，當作沒網路時的預設值
  static const List<StationModel> fallbackStations = [
    StationModel(id: "46694A", name: "龍洞資料浮標", region: "北部", isBuoy: true, lat: 25.037, lng: 121.926),
    StationModel(id: "C4A01", name: "淡水潮位站", region: "北部", lat: 25.175, lng: 121.424),
  ];
}
