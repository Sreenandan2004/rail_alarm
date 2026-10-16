import 'dart:math' as math;

/// Core geographic calculations and travel estimations.
class GeoUtils {
  /// Mean radius of the Earth in kilometers
  static const double earthRadiusKm = 6371.0;

  /// Calculates the great-circle distance between two coordinates in kilometers
  /// using the Haversine formula.
  static double haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Converts degrees to radians.
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Estimates travel time (ETA) given remaining distance in km and current speed in km/h.
  /// Returns null if speed is negligible (stationary or < 1 km/h).
  static Duration? estimateEta({
    required double distanceKm,
    required double speedKmh,
  }) {
    if (speedKmh <= 1.0 || distanceKm <= 0) return null;
    final hours = distanceKm / speedKmh;
    return Duration(seconds: (hours * 3600).round());
  }

  /// Formats duration into a human-readable string (e.g. "45m", "1h 20m").
  static String formatEta(Duration duration) {
    final totalMinutes = duration.inMinutes;
    if (totalMinutes < 1) return "< 1 min";
    if (totalMinutes < 60) return "${totalMinutes}m";
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes > 0 ? "${hours}h ${minutes}m" : "${hours}h";
  }
}
