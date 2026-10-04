import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/ugc_radar_suite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UGC 雷達診斷套件測試 (海事零造假誠信與防白嫖)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef testRef;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, child) {
            testRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    final result = await UgcRadarDiagnosticSuite.run(testRef);

    expect(result.is6TagsStructureValid, isTrue);
    expect(result.isZeroFabricationHonestyPassed, isTrue);
    expect(result.isRealReportUnitValid, isTrue);
    expect(result.isCoinAntiExploitDefended, isTrue);
    expect(result.is6HourExpiryFilterValid, isTrue);
    expect(result.isAllPassed, isTrue);
  });
}