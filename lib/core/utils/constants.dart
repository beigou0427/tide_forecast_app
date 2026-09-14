import 'security_util.dart';

/// 測站模型定義
class StationModel {
  final String id;
  final String name;
  final String region;
  final bool isBuoy;
  final double lat;
  final double lng;
  const StationModel({required this.id, required this.name, required this.region, this.isBuoy = false, required this.lat, required this.lng});
}

class AppConstants {
  // --- 1. 代理 API 配置 (已加密) ---
  static const String proxyUrl = "https://superiorapis-creator.cteam.com.tw/manager/feature/proxy/9ba80bfcd6ad/pub_9c67411cf4c9";
  
  static String get proxyToken => SecurityUtil.decrypt(
    "Xh0SEx4fFBAXEhgeFhMbEhUXERITHBYfEB4XGhMVFhITHhIVExUSFhUbEhUXERUUGxISEh4SEx4fFBAXEhgeFhMcExYTGhMUGxYfEB4XGhMVFhITHhIVExUfFhYbEhUfFxMUGxISEh4SEx4fExUXFxMWHhIVExUUGxIXHhMTExUbFhMVHhIXHRIU"
  );

  // --- 2. 中央氣象署 (CWA) 官方配置 (已加密) ---
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

  // 補回 86 個測站清單 (縮略顯示，請執行寫入)
  static const List<StationModel> allStations = [
    StationModel(id: "46694A", name: "龍洞資料浮標", region: "北部", isBuoy: true, lat: 25.037, lng: 121.926),
    StationModel(id: "C6AH2", name: "富貴角資料浮標", region: "北部", isBuoy: true, lat: 25.305, lng: 121.521),
    StationModel(id: "C6B01", name: "彭佳嶼資料浮標", region: "北部", isBuoy: true, lat: 25.607, lng: 122.052),
    StationModel(id: "TPBU01", name: "臺北港浮標", region: "北部", isBuoy: true, lat: 25.176, lng: 121.365),
    StationModel(id: "OAC003", name: "鼻頭角浮標", region: "北部", isBuoy: true, lat: 25.129, lng: 121.922),
    StationModel(id: "OAC004", name: "潮境浮標", region: "北部", isBuoy: true, lat: 25.143, lng: 121.803),
    StationModel(id: "C4A01", name: "淡水潮位站", region: "北部", lat: 25.175, lng: 121.424),
    StationModel(id: "C4A06", name: "淡海潮位站", region: "北部", lat: 25.193, lng: 121.411),
    StationModel(id: "C4B01", name: "基隆潮位站", region: "北部", lat: 25.155, lng: 121.751),
    StationModel(id: "C4B03", name: "長潭里潮位站", region: "北部", lat: 25.141, lng: 121.801),
    StationModel(id: "C4A02", name: "龍洞潮位站", region: "北部", lat: 25.038, lng: 121.921),
    StationModel(id: "C4A03", name: "麟山鼻潮位站", region: "北部", lat: 25.285, lng: 121.501),
    StationModel(id: "C4A05", name: "福隆潮位站", region: "北部", lat: 25.021, lng: 121.944),
    StationModel(id: "46757B", name: "新竹資料浮標", region: "西部", isBuoy: true, lat: 24.767, lng: 120.817),
    StationModel(id: "C6F01", name: "臺中資料浮標", region: "西部", isBuoy: true, lat: 24.233, lng: 120.417),
    StationModel(id: "WRA005", name: "外傘頂資料浮標", region: "西部", isBuoy: true, lat: 23.516, lng: 120.017),
    StationModel(id: "C6G01", name: "彰化水位浮標", region: "西部", isBuoy: true, lat: 24.033, lng: 120.250),
    StationModel(id: "C6D01", name: "新竹水位浮標", region: "西部", isBuoy: true, lat: 24.850, lng: 120.900),
    StationModel(id: "C4D01", name: "新竹潮位站", region: "西部", lat: 24.848, lng: 120.916),
    StationModel(id: "C4F01", name: "臺中港潮位站", region: "西部", lat: 24.256, lng: 120.518),
    StationModel(id: "C4G01", name: "鹿港潮位站", region: "西部", lat: 24.058, lng: 120.403),
    StationModel(id: "1456", name: "麥寮潮位站", region: "西部", lat: 23.791, lng: 120.141),
    StationModel(id: "4J21", name: "麥寮氣象站", region: "西部", lat: 23.785, lng: 120.150),
    StationModel(id: "C4J01", name: "萡子寮潮位站", region: "西部", lat: 23.614, lng: 120.133),
    StationModel(id: "C4L01", name: "塭港潮位站", region: "西部", lat: 23.456, lng: 120.137),
    StationModel(id: "C4L02", name: "東石潮位站", region: "西部", lat: 23.450, lng: 120.140),
    StationModel(id: "C4C01", name: "竹圍潮位站", region: "西部", lat: 25.116, lng: 121.244),
    StationModel(id: "C4E01", name: "外埔潮位站", region: "西部", lat: 24.646, lng: 120.767),
    StationModel(id: "46759A", name: "鵝鑾鼻資料浮標", region: "南部", isBuoy: true, lat: 21.901, lng: 120.844),
    StationModel(id: "46714D", name: "小琉球資料浮標", region: "南部", isBuoy: true, lat: 22.316, lng: 120.350),
    StationModel(id: "46778A", name: "七股資料浮標", region: "南部", isBuoy: true, lat: 23.083, lng: 120.033),
    StationModel(id: "COMC08", name: "彌陀資料浮標", region: "南部", isBuoy: true, lat: 22.766, lng: 120.183),
    StationModel(id: "OAC007", name: "南灣浮標", region: "南部", isBuoy: true, lat: 21.942, lng: 120.762),
    StationModel(id: "C6N01", name: "臺南水位浮標", region: "南部", isBuoy: true, lat: 23.016, lng: 120.066),
    StationModel(id: "C4P01", name: "高雄潮位站", region: "南部", lat: 22.618, lng: 120.266),
    StationModel(id: "C4Q01", name: "小琉球潮位站", region: "南部", lat: 22.355, lng: 120.379),
    StationModel(id: "C4Q02", name: "東港潮位站", region: "南部", lat: 22.464, lng: 120.443),
    StationModel(id: "C4Q03", name: "後壁湖潮位站", region: "南部", lat: 21.946, lng: 120.745),
    StationModel(id: "4A", name: "安平潮位站", region: "南部", lat: 23.001, lng: 120.154),
    StationModel(id: "4F", name: "枋寮潮位站", region: "南部", lat: 22.364, lng: 120.590),
    StationModel(id: "4I", name: "小港潮位站", region: "南部", lat: 22.553, lng: 120.334),
    StationModel(id: "11781", name: "四草潮位站", region: "南部", lat: 23.033, lng: 120.125),
    StationModel(id: "1786", name: "永安潮位站", region: "南部", lat: 22.821, lng: 120.198),
    StationModel(id: "4Q11", name: "大鵬灣氣象站", region: "南部", lat: 22.449, lng: 120.477),
    StationModel(id: "46699A", name: "花蓮資料浮標", region: "東部", isBuoy: true, lat: 24.033, lng: 121.683),
    StationModel(id: "46706A", name: "蘇澳資料浮標", region: "東部", isBuoy: true, lat: 24.616, lng: 121.883),
    StationModel(id: "46708A", name: "龜山島資料浮標", region: "東部", isBuoy: true, lat: 24.850, lng: 121.966),
    StationModel(id: "WRA007", name: "臺東資料浮標", region: "東部", isBuoy: true, lat: 22.716, lng: 121.183),
    StationModel(id: "46761F", name: "成功浮球式波浪站", region: "東部", isBuoy: true, lat: 23.132, lng: 121.420),
    StationModel(id: "C4T01", name: "花蓮潮位站", region: "東部", lat: 23.985, lng: 121.636),
    StationModel(id: "C4S02", name: "成功潮位站", region: "東部", lat: 23.097, lng: 121.378),
    StationModel(id: "C4U01", name: "蘇澳潮位站", region: "東部", lat: 24.595, lng: 121.865),
    StationModel(id: "C4U02", name: "烏石潮位站", region: "東部", lat: 24.869, lng: 121.841),
    StationModel(id: "1566", name: "石梯潮位站", region: "東部", lat: 23.491, lng: 121.512),
    StationModel(id: "1586", name: "富岡潮位站", region: "東部", lat: 22.787, lng: 121.192),
    StationModel(id: "1596", name: "大武潮位站", region: "東部", lat: 22.339, lng: 120.906),
    StationModel(id: "12540", name: "和平港潮位站", region: "東部", lat: 24.298, lng: 121.758),
    StationModel(id: "4T21", name: "石梯氣象站", region: "東部", lat: 23.495, lng: 121.510),
    StationModel(id: "46735A", name: "澎湖資料浮標", region: "離島", isBuoy: true, lat: 23.633, lng: 119.450),
    StationModel(id: "C6W08", name: "馬祖資料浮標", region: "離島", isBuoy: true, lat: 26.233, lng: 120.000),
    StationModel(id: "C6W10", name: "七美資料浮標", region: "離島", isBuoy: true, lat: 23.166, lng: 119.333),
    StationModel(id: "C6S94", name: "蘭嶼資料浮標", region: "離島", isBuoy: true, lat: 22.016, lng: 121.566),
    StationModel(id: "C6V27", name: "東沙島資料浮標", region: "離島", isBuoy: true, lat: 20.700, lng: 116.716),
    StationModel(id: "A6S01", name: "綠島公館資料浮標", region: "離島", isBuoy: true, lat: 22.683, lng: 121.483),
    StationModel(id: "OAC006", name: "東吉嶼浮標", region: "離島", isBuoy: true, lat: 23.264, lng: 119.667),
    StationModel(id: "C4W02", name: "澎湖潮位站", region: "離島", lat: 23.565, lng: 119.563),
    StationModel(id: "C4W01", name: "馬祖潮位站", region: "離島", lat: 26.155, lng: 119.928),
    StationModel(id: "C4W03", name: "七美潮位站", region: "離島", lat: 23.197, lng: 119.425),
    StationModel(id: "C4W04", name: "吉貝潮位站", region: "離島", lat: 23.743, lng: 119.610),
    StationModel(id: "C4W05", name: "東吉潮位站", region: "離島", lat: 23.256, lng: 119.675),
    StationModel(id: "C5W09", name: "東吉島波浪站", region: "離島", isBuoy: true, lat: 23.258, lng: 119.671),
    StationModel(id: "1966", name: "水頭潮位站(金門)", region: "離島", lat: 24.425, lng: 118.283),
    StationModel(id: "1956", name: "料羅灣潮位站(金門)", region: "離島", lat: 24.416, lng: 118.433),
    StationModel(id: "1676", name: "綠島潮位站", region: "離島", lat: 22.666, lng: 121.466),
    StationModel(id: "C4S01", name: "蘭嶼潮位站", region: "離島", lat: 22.056, lng: 121.503),
    StationModel(id: "C4P03", name: "南沙潮位站", region: "離島", lat: 10.376, lng: 114.364),
    StationModel(id: "C4P02", name: "東沙潮位站-1", region: "離島", lat: 20.701, lng: 116.726),
    StationModel(id: "C4P09", name: "東沙潮位站-2", region: "離島", lat: 20.710, lng: 116.730),
    StationModel(id: "4S21", name: "綠島氣象站", region: "離島", lat: 22.671, lng: 121.467),
    StationModel(id: "4W21", name: "料羅灣氣象站", region: "離島", lat: 24.410, lng: 118.430),
  ];
}
