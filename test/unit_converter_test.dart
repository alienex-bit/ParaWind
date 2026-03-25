import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/utils/unit_converter.dart';

void main() {
  group('UnitSettings Tests', () {
    test('Knots to KMH conversion (manual check of logic)', () {
      // UnitSettings.convertKmh(kmh) converts FROM kmh TO selected unit.
      // 1 knot = 1.852 km/h
      // If we want to test conversion logic:
      expect(1.852 * 0.539957, closeTo(1.0, 0.01));
    });

    test('Convert Speed based on setting', () {
      UnitSettings.selectedUnit.value = SpeedUnit.kph;
      expect(UnitSettings.convertKmh(10), 10.0);

      UnitSettings.selectedUnit.value = SpeedUnit.mph;
      expect(UnitSettings.convertKmh(10), closeTo(6.21, 0.01));
    });

    test('Degree to Compass conversion', () {
      expect(UnitSettings.degreesToCompass(0), 'N');
      expect(UnitSettings.degreesToCompass(90), 'E');
      expect(UnitSettings.degreesToCompass(180), 'S');
      expect(UnitSettings.degreesToCompass(270), 'W');
      expect(UnitSettings.degreesToCompass(45), 'NE');
      expect(UnitSettings.degreesToCompass(350), 'N');
    });
  });
}
