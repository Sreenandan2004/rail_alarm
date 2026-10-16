import 'package:flutter_test/flutter_test.dart';
import 'package:rail_alarm/models/station.dart';
import 'package:rail_alarm/services/station_service.dart';

void main() {
  group('StationService Offline Search Tests', () {
    final service = StationService();

    final testStations = [
      const Station(code: 'NDLS', name: 'New Delhi', latitude: 28.6424, longitude: 77.2205),
      const Station(code: 'DLI', name: 'Old Delhi Junction', latitude: 28.6608, longitude: 77.2289),
      const Station(code: 'HWH', name: 'Howrah Junction', latitude: 22.5839, longitude: 88.3426),
      const Station(code: 'SBC', name: 'KSR Bengaluru City', latitude: 12.9784, longitude: 77.5694),
      const Station(code: 'MAS', name: 'Chennai Central', latitude: 13.0827, longitude: 80.2755),
      const Station(code: 'CSMT', name: 'Chhatrapati Shivaji Maharaj Terminus', latitude: 18.9402, longitude: 72.8358),
    ];

    setUp(() {
      service.setStationsForTesting(testStations);
    });

    test('exact station code search returns matching station first', () {
      final results = service.search('NDLS');
      expect(results, isNotEmpty);
      expect(results.first.code, 'NDLS');
      expect(results.first.name, 'New Delhi');
    });

    test('search is case-insensitive for station codes and names', () {
      final codeResults = service.search('hwh');
      expect(codeResults, isNotEmpty);
      expect(codeResults.first.code, 'HWH');

      final nameResults = service.search('bengaluru');
      expect(nameResults, isNotEmpty);
      expect(nameResults.first.code, 'SBC');
    });

    test('prefix code search matches starting codes', () {
      final results = service.search('CSM');
      expect(results, isNotEmpty);
      expect(results.first.code, 'CSMT');
    });

    test('substring name search matches partial city names', () {
      final results = service.search('Delhi');
      expect(results.length, greaterThanOrEqualTo(2));
      final codes = results.map((s) => s.code).toList();
      expect(codes, contains('NDLS'));
      expect(codes, contains('DLI'));
    });

    test('empty or whitespace query returns empty list', () {
      expect(service.search(''), isEmpty);
      expect(service.search('   '), isEmpty);
    });

    test('station displayName formats properly', () {
      const station = Station(code: 'SBC', name: 'KSR Bengaluru', latitude: 12.0, longitude: 77.0);
      expect(station.displayName, 'KSR Bengaluru (SBC)');
    });
  });
}
