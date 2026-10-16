import 'alarm_entity.dart';

class AlarmInfo {
  final String id;
  final String location;
  final double latitude;
  final double longitude;
  final bool isActive;
  final double leadDistanceKm;

  AlarmInfo({
    required this.id,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
    this.leadDistanceKm = 10.0,
  });

  AlarmEntity toEntity() {
    final serializedLocation = leadDistanceKm != 10.0
        ? "$location###${leadDistanceKm.toStringAsFixed(1)}"
        : location;

    return AlarmEntity()
      ..alarmId = id
      ..location = serializedLocation
      ..latitude = latitude
      ..longitude = longitude
      ..isActive = isActive
      ..createdAt = DateTime.now();
  }

  factory AlarmInfo.fromEntity(AlarmEntity entity) {
    String loc = entity.location;
    double lead = 10.0;
    if (loc.contains('###')) {
      final parts = loc.split('###');
      loc = parts[0];
      lead = double.tryParse(parts[1]) ?? 10.0;
    }

    return AlarmInfo(
      id: entity.alarmId,
      location: loc,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isActive: entity.isActive,
      leadDistanceKm: lead,
    );
  }

  AlarmInfo copyWith({
    String? id,
    String? location,
    double? latitude,
    double? longitude,
    bool? isActive,
    double? leadDistanceKm,
  }) {
    return AlarmInfo(
      id: id ?? this.id,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      leadDistanceKm: leadDistanceKm ?? this.leadDistanceKm,
    );
  }
}
