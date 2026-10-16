import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../models/alarm_info.dart';
import '../models/tracking_state.dart';
import '../utils/geo_utils.dart';

/// Engine responsible for battery-efficient, adaptive distance-tiered location tracking.
class AdaptiveLocationService {
  /// Assumed maximum vehicle speed for safe sleep calculation (120 km/h)
  static const double defaultMaxAssumedSpeedKmh = 120.0;

  /// Absolute safety ceiling for speed calculations
  static const double maxAllowedSpeedCeilingKmh = 160.0;

  /// Absolute minimum sleep interval
  static const int minIntervalSeconds = 10;

  /// Maximum sleep interval when far away (15 minutes)
  static const int maxFarIntervalSeconds = 900;

  /// Evaluates distance tier based on current distance and lead distance.
  static DistanceTier evaluateTier({
    required double distanceKm,
    required double leadDistanceKm,
  }) {
    if (distanceKm <= leadDistanceKm) {
      return DistanceTier.alarmRange;
    } else if (distanceKm <= 15.0) {
      return DistanceTier.near;
    } else if (distanceKm <= 50.0) {
      return DistanceTier.approaching;
    } else {
      return DistanceTier.far;
    }
  }

  /// Calculates the safe sleep interval before the next location check:
  /// Δt = (Distance - LeadDistance) / MaxSpeed
  ///
  /// Guarantees that even at peak velocity, the vehicle cannot overshoot
  /// the alarm boundary before the next wake-up.
  static Duration calculateSafeSleep({
    required double distanceKm,
    required double leadDistanceKm,
    double? measuredSpeedKmh,
  }) {
    final remainingKm = distanceKm - leadDistanceKm;
    if (remainingKm <= 0) {
      return const Duration(seconds: minIntervalSeconds);
    }

    // Determine effective speed to use for safe sleep calculation
    double effectiveSpeedKmh = defaultMaxAssumedSpeedKmh;
    if (measuredSpeedKmh != null && measuredSpeedKmh > 5.0) {
      // 20% safety buffer over measured speed, bounded between 80 km/h and ceiling
      effectiveSpeedKmh = math.min(
        math.max(measuredSpeedKmh * 1.2, 80.0),
        maxAllowedSpeedCeilingKmh,
      );
    }

    // Raw safe sleep calculation: remaining distance / effective speed
    final rawSeconds = (remainingKm / effectiveSpeedKmh * 3600).round();

    final tier = evaluateTier(distanceKm: distanceKm, leadDistanceKm: leadDistanceKm);
    int minTierSeconds;
    int maxTierSeconds;

    switch (tier) {
      case DistanceTier.far:
        minTierSeconds = 300; // at least 5 mins
        maxTierSeconds = maxFarIntervalSeconds; // 15 mins
        break;
      case DistanceTier.approaching:
        minTierSeconds = 120; // at least 2 mins
        maxTierSeconds = 300; // 5 mins
        break;
      case DistanceTier.near:
        minTierSeconds = 30; // 30s
        maxTierSeconds = 90; // 90s
        break;
      case DistanceTier.alarmRange:
        minTierSeconds = minIntervalSeconds;
        maxTierSeconds = 15;
        break;
    }

    // Stationary back-off: If vehicle is stopped (< 3 km/h), safely use max tier sleep
    if (measuredSpeedKmh != null && measuredSpeedKmh < 3.0 && tier != DistanceTier.alarmRange) {
      return Duration(seconds: maxTierSeconds);
    }

    final clampedSeconds = rawSeconds.clamp(minTierSeconds, maxTierSeconds);
    return Duration(seconds: clampedSeconds);
  }

  /// Evaluates full tracking decision for a given GPS position and alarm.
  static AdaptiveTrackingDecision evaluate({
    required Position currentPosition,
    required AlarmInfo alarm,
  }) {
    final distanceKm = GeoUtils.haversineDistanceKm(
      currentPosition.latitude,
      currentPosition.longitude,
      alarm.latitude,
      alarm.longitude,
    );

    // Speed in m/s converted to km/h (Geolocator provides speed in m/s)
    final speedKmh = math.max(0.0, currentPosition.speed * 3.6);

    final tier = evaluateTier(
      distanceKm: distanceKm,
      leadDistanceKm: alarm.leadDistanceKm,
    );

    final sleepInterval = calculateSafeSleep(
      distanceKm: distanceKm,
      leadDistanceKm: alarm.leadDistanceKm,
      measuredSpeedKmh: speedKmh,
    );

    LocationAccuracy accuracy;
    switch (tier) {
      case DistanceTier.far:
        accuracy = LocationAccuracy.low;
        break;
      case DistanceTier.approaching:
        accuracy = LocationAccuracy.medium;
        break;
      case DistanceTier.near:
        accuracy = LocationAccuracy.high;
        break;
      case DistanceTier.alarmRange:
        accuracy = LocationAccuracy.best;
        break;
    }

    final eta = GeoUtils.estimateEta(
      distanceKm: distanceKm,
      speedKmh: speedKmh,
    );

    return AdaptiveTrackingDecision(
      tier: tier,
      sleepInterval: sleepInterval,
      locationAccuracy: accuracy,
      distanceKm: distanceKm,
      currentSpeedKmh: speedKmh,
      eta: eta,
      shouldTrigger: distanceKm <= alarm.leadDistanceKm,
    );
  }

  /// Finds the closest active alarm to the user's current position.
  static AlarmInfo? findClosestActiveAlarm({
    required Position currentPosition,
    required List<AlarmInfo> alarms,
  }) {
    final activeAlarms = alarms.where((a) => a.isActive).toList();
    if (activeAlarms.isEmpty) return null;

    AlarmInfo? closest;
    double minDistance = double.infinity;

    for (final alarm in activeAlarms) {
      final dist = GeoUtils.haversineDistanceKm(
        currentPosition.latitude,
        currentPosition.longitude,
        alarm.latitude,
        alarm.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closest = alarm;
      }
    }

    return closest;
  }
}
