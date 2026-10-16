import 'package:geolocator/geolocator.dart';

/// Distance tiers for adaptive power-saving location tracking.
enum DistanceTier {
  /// Zone 1: > 50 km away. Low power, coarse network/cell polling.
  far,

  /// Zone 2: 15 km to 50 km away. Balanced accuracy, medium interval.
  approaching,

  /// Zone 3: Lead distance to 15 km away. Fine GPS polling, high accuracy.
  near,

  /// Zone 4: Inside trigger threshold (<= lead distance). Real-time GPS & alarm trigger.
  alarmRange,
}

/// Snapshot decision returned by the Adaptive Location Engine.
class AdaptiveTrackingDecision {
  /// Evaluated distance tier
  final DistanceTier tier;

  /// Dynamic sleep duration before next scheduled location query
  final Duration sleepInterval;

  /// Optimal hardware accuracy to request on the next query
  final LocationAccuracy locationAccuracy;

  /// Current distance to the destination in kilometers
  final double distanceKm;

  /// Current measured velocity in km/h
  final double currentSpeedKmh;

  /// Estimated time of arrival (null if stationary)
  final Duration? eta;

  /// Whether the vehicle has entered the alarm trigger boundary
  final bool shouldTrigger;

  const AdaptiveTrackingDecision({
    required this.tier,
    required this.sleepInterval,
    required this.locationAccuracy,
    required this.distanceKm,
    required this.currentSpeedKmh,
    this.eta,
    required this.shouldTrigger,
  });

  @override
  String toString() {
    return 'AdaptiveTrackingDecision(tier: $tier, dist: ${distanceKm.toStringAsFixed(1)}km, '
        'sleep: ${sleepInterval.inSeconds}s, speed: ${currentSpeedKmh.toStringAsFixed(1)}km/h, '
        'trigger: $shouldTrigger)';
  }
}
