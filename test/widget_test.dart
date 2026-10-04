import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide_forecast_app/main.dart';
import 'package:tide_forecast_app/features/tide/providers/tide_provider.dart';
import 'package:tide_forecast_app/core/network/tide_api_service.dart';
import 'package:tide_forecast_app/features/tide/data/tide_model.dart';

/// 🌟 對齊 Adrian Cockcroft 超時預算簽章之 Mock API 服務
class MockTideApiService extends TideApiService {
  @override
  Future<TideStationData> fetchData(
    String stationId, {
    bool isPremium = false,
    Duration totalBudget = const Duration(milliseconds: 3500),
  }) async {
    return TideStationData(
      schemaVersion: 2,
      info: StationInfo(
        stationName: "富貴角測試站",
        countyName: "新北",
        townName: "石門",
        lat: "25.30",
        lng: "121.53",
        attr: "資料浮標",
        addressDescription: "",
      ),
      observations: [
        Observation(
          dateTime: DateTime.now(),
          waveHeight: 0.8,
          windSpeed: 4.0,
          seaTemperature: 24.5,
          tideHeight: 1.5,
          tideLevel: "平穩",
        ),
      ],
      forecasts: [],
      aiBriefing: AIExpertBriefing(
        briefing: "測試水文平穩",
        safetyScore: 85,
        activities: ["測試作業"],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
      'has_agreed_maritime_safety_v2': true,
      'has_init_station': true,
      'last_station_id': 'C6AH2',
    });
  });

  testWidgets('App 全域煙霧測試：啟動渲染、時鐘推進排空與銷毀零懸掛驗證', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tideApiServiceProvider.overrideWithValue(MockTideApiService()),
        ],
        child: const MyApp(hasCompletedOnboarding: true),
      ),
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
  });
}