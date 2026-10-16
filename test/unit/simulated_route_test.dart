import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rail_alarm/models/alarm_info.dart';
import 'package:rail_alarm/models/tracking_state.dart';
import 'package:rail_alarm/services/adaptive_location_service.dart';
import 'package:rail_alarm/utils/geo_utils.dart';

void main() {
  group('Simulated Journey Route Integration Test', () {
    // Destination: Palakkad Junction (PGT)
    final destination = AlarmInfo(
      id: 'PGT_ALARM',
      location: 'Palakkad Junction (PGT)',
      latitude: 10.7867,
      longitude: 76.6548,
      isActive: true,
      leadDistanceKm: 10.0,
    );

    test('Full journey lifecycle from Far (>100km) to Alarm Trigger (<10km)', () {
      // 1. Waypoint 1: Ernakulam (ERS) - ~105 km away
      final ersPosition = Position(
        latitude: 9.9676,
        longitude: 76.2944,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 10.0,
        altitudeAccuracy: 10.0,
        heading: 30.0,
        headingAccuracy: 10.0,
        speed: 25.0, // 90 km/h
        speedAccuracy: 1.0,
      );

      final ersDist = GeoUtils.haversineDistanceKm(
        ersPosition.latitude,
        ersPosition.longitude,
        destination.latitude,
        destination.longitude,
      );
      expect(ersDist > 50.0, isTrue);

      final ersDecision = AdaptiveLocationService.evaluate(
        currentPosition: ersPosition,
        alarm: destination,
      );

      expect(ersDecision.tier, DistanceTier.far);
      expect(ersDecision.locationAccuracy, LocationAccuracy.low);
      expect(ersDecision.shouldTrigger, isFalse);
      expect(ersDecision.sleepInterval.inMinutes >= 10, isTrue);

      // 2. Waypoint 2: Shoranur Junction (SRR) - ~41.8 km away (Approaching tier)
      final srrPosition = Position(
        latitude: 10.7584,
        longitude: 76.2731,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 10.0,
        altitudeAccuracy: 10.0,
        heading: 85.0,
        headingAccuracy: 10.0,
        speed: 22.2, // 80 km/h
        speedAccuracy: 1.0,
      );

      final srrDist = GeoUtils.haversineDistanceKm(
        srrPosition.latitude,
        srrPosition.longitude,
        destination.latitude,
        destination.longitude,
      );
      expect(srrDist > 15.0 && srrDist <= 50.0, isTrue);

      final srrDecision = AdaptiveLocationService.evaluate(
        currentPosition: srrPosition,
        alarm: destination,
      );

      expect(srrDecision.tier, DistanceTier.approaching);
      expect(srrDecision.locationAccuracy, LocationAccuracy.medium);
      expect(srrDecision.shouldTrigger, isFalse);
      expect(srrDecision.sleepInterval.inMinutes <= 5, isTrue);

      // 3. Waypoint 3: Parli (~12.5 km away)
      final parliPosition = Position(
        latitude: 10.7780,
        longitude: 76.5400,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 10.0,
        heading: 85.0,
        headingAccuracy: 5.0,
        speed: 19.4, // 70 km/h
        speedAccuracy: 1.0,
      );

      final parliDist = GeoUtils.haversineDistanceKm(
        parliPosition.latitude,
        parliPosition.longitude,
        destination.latitude,
        destination.longitude,
      );
      expect(parliDist > 10.0 && parliDist <= 15.0, isTrue);

      final parliDecision = AdaptiveLocationService.evaluate(
        currentPosition: parliPosition,
        alarm: destination,
      );

      expect(parliDecision.tier, DistanceTier.near);
      expect(parliDecision.locationAccuracy, LocationAccuracy.high);
      expect(parliDecision.shouldTrigger, isFalse);
      expect(parliDecision.sleepInterval.inSeconds <= 90, isTrue);

      // 4. Waypoint 4: Within 10km lead distance (~6 km from PGT)
      final arrivalPosition = Position(
        latitude: 10.7840,
        longitude: 76.6000,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 10.0,
        heading: 90.0,
        headingAccuracy: 5.0,
        speed: 15.0, // 54 km/h
        speedAccuracy: 1.0,
      );

      final arrivalDist = GeoUtils.haversineDistanceKm(
        arrivalPosition.latitude,
        arrivalPosition.longitude,
        destination.latitude,
        destination.longitude,
      );
      expect(arrivalDist <= destination.leadDistanceKm, isTrue);

      final arrivalDecision = AdaptiveLocationService.evaluate(
        currentPosition: arrivalPosition,
        alarm: destination,
      );

      expect(arrivalDecision.tier, DistanceTier.alarmRange);
      expect(arrivalDecision.shouldTrigger, isTrue);
      expect(arrivalDecision.sleepInterval, const Duration(seconds: 10));
    });
  });
}
