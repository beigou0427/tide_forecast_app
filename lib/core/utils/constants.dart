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
  static const String officialBaseUrl = "https://opendata.cwa.gov.tw/api/v1/rest/datastore";
  
  // 🌟 十六進位混淆矩陣：完全隱藏 CWA-7B44D117-3255-4D71-9974-B3A93B937D51
  static String get officialApiKey => SecurityUtil.decryptBytes(const [
    0x37, 0x3e, 0x25, 0x48, 0x48, 0x21, 0x5b, 0x59, 0x49, 0x50, 0x5f, 0x53,
    0x52, 0x50, 0x57, 0x5b, 0x41, 0x48, 0x5e, 0x1b, 0x5c, 0x50, 0x4b, 0x5c,
    0x46, 0x05, 0x04, 0x1f, 0x76, 0x43, 0x28, 0x5d, 0x56, 0x1d, 0x4a, 0x5c,
    0x52, 0x49, 0x54, 0x5f
  ]);

  static const String dsObservation = "O-B0075-002";
  static const String dsForecast = "F-A0021-001";
  static const String iapProMonthly = "com.beigou.tide_app.pro_monthly";
  static const String iapProYearly = "com.beigou.tide_app.pro_yearly";
  static const Set<String> iapProductIds = {iapProMonthly, iapProYearly};
  static const List<String> regions = ["北部", "西部", "南部", "東部", "離島"];
  static const String remoteStationsUrl = "https://beigou0427.github.io/tide_forecast_app/stations_config.json";

  static const List<StationModel> fallbackStations = [
    StationModel(id: "46694A", name: "龍洞資料浮標", region: "北部", isBuoy: true, lat: 25.037, lng: 121.926),
    StationModel(id: "C4A01", name: "淡水潮位站", region: "北部", lat: 25.175, lng: 121.424),
  ];
}

