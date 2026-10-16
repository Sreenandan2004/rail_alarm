import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rail_alarm/models/alarm_info.dart';
import 'package:rail_alarm/models/tracking_state.dart';
import 'package:rail_alarm/services/adaptive_location_service.dart';
import 'package:rail_alarm/utils/geo_utils.dart';

void main() {
  group('GeoUtils Tests', () {
    test('same coordinates return 0 distance', () {
      final dist = GeoUtils.haversineDistanceKm(28.6430, 77.2197, 28.6430, 77.2197);
      expect(dist, 0.0);
    });

    test('calculates accurate distance between NDLS and NZM stations (~6.8 km)', () {
      // New Delhi Railway Station (NDLS): 28.6430, 77.2197
      // Hazrat Nizamuddin Station (NZM): 28.5888, 77.2534
      final dist = GeoUtils.haversineDistanceKm(28.6430, 77.2197, 28.5888, 77.2534);
      expect(dist, greaterThan(6.5));
      expect(dist, lessThan(7.2));
    });

    test('estimateEta returns correct duration when moving', () {
      final eta = GeoUtils.estimateEta(distanceKm: 60, speedKmh: 60);
      expect(eta, isNotNull);
      expect(eta!.inMinutes, 60);
    });

    test('estimateEta returns null when stationary or speed <= 1 km/h', () {
      final eta = GeoUtils.estimateEta(distanceKm: 20, speedKmh: 0.5);
      expect(eta, isNull);
    });

    test('formatEta formats properly for different durations', () {
      expect(GeoUtils.formatEta(const Duration(minutes: 45)), '45m');
      expect(GeoUtils.formatEta(const Duration(hours: 1, minutes: 25)), '1h 25m');
      expect(GeoUtils.formatEta(const Duration(hours: 2)), '2h');
      expect(GeoUtils.formatEta(const Duration(seconds: 30)), '< 1 min');
    });
  });

  group('AdaptiveLocationService Tier & Safe Sleep Tests', () {
    test('evaluateTier classifies distances correctly based on lead distance', () {
      const leadDist = 10.0;

      expect(
        AdaptiveLocationService.evaluateTier(distanceKm: 80.0, leadDistanceKm: leadDist),
        DistanceTier.far,
      );
      expect(
        AdaptiveLocationService.evaluateTier(distanceKm: 35.0, leadDistanceKm: leadDist),
        DistanceTier.approaching,
      );
      expect(
        AdaptiveLocationService.evaluateTier(distanceKm: 13.0, leadDistanceKm: leadDist),
        DistanceTier.near,
      );
      expect(
        AdaptiveLocationService.evaluateTier(distanceKm: 9.5, leadDistanceKm: leadDist),
        DistanceTier.alarmRange,
      );
      expect(
        AdaptiveLocationService.evaluateTier(distanceKm: 10.0, leadDistanceKm: leadDist),
        DistanceTier.alarmRange,
      );
    });

    test('evaluateTier respects custom lead distance (e.g. 2.0 km for bus/car)', () {
      const customLead = 2.0;

      expect(
        AdaptiveLocationService.evaluateTier(distanceKm: 3.5, leadDistanceKm: customLead),
        DistanceTier.near,
      );
      expect(
        AdaptiveLocationService.evaluateTier(distanceKm: 1.8, leadDistanceKm: customLead),
        DistanceTier.alarmRange,
      );
    });

    test('calculateSafeSleep returns minimum interval when inside alarm range', () {
      final sleep = AdaptiveLocationService.calculateSafeSleep(
        distanceKm: 8.0,
        leadDistanceKm: 10.0,
      );
      expect(sleep.inSeconds, 10);
    });

    test('calculateSafeSleep clamps within expected tier limits for far distance', () {
      final sleep = AdaptiveLocationService.calculateSafeSleep(
        distanceKm: 100.0,
        leadDistanceKm: 10.0,
        measuredSpeedKmh: 90.0,
      );
      // In Zone 1 (Far), sleep interval is bounded between 5m (300s) and 15m (900s)
      expect(sleep.inSeconds, greaterThanOrEqualTo(300));
      expect(sleep.inSeconds, lessThanOrEqualTo(900));
    });

    test('stationary back-off gives higher sleep duration when speed < 3 km/h', () {
      final sleepStationary = AdaptiveLocationService.calculateSafeSleep(
        distanceKm: 40.0,
        leadDistanceKm: 10.0,
        measuredSpeedKmh: 0.0, // stopped at train signal / traffic
      );
      // In Zone 2 approaching (15-50km), max tier sleep is 300s (5 min)
      expect(sleepStationary.inSeconds, 300);
    });

    test('evaluate returns valid decision and accuracy for real position', () {
      final currentPos = Position(
        latitude: 28.6430,
        longitude: 77.2197,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 215.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 25.0, // 25 m/s = 90 km/h
        speedAccuracy: 1.0,
      );

      // Target ~6.8 km away
      final alarm = AlarmInfo(
        id: 'test_1',
        location: 'Hazrat Nizamuddin',
        latitude: 28.5888,
        longitude: 77.2534,
        leadDistanceKm: 10.0,
      );

      final decision = AdaptiveLocationService.evaluate(
        currentPosition: currentPos,
        alarm: alarm,
      );

      expect(decision.distanceKm, lessThan(10.0));
      expect(decision.tier, DistanceTier.alarmRange);
      expect(decision.shouldTrigger, isTrue);
      expect(decision.currentSpeedKmh, 90.0);
    });
  });
}
