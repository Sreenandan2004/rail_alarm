import 'alarm_entity.dart';

class AlarmInfo {
  final String id;
  final String location;
  final double latitude;
  final double longitude;
  final bool isActive;

  AlarmInfo({
    required this.id,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
  });

  AlarmEntity toEntity() {
    return AlarmEntity()
      ..alarmId = id
      ..location = location
      ..latitude = latitude
      ..longitude = longitude
      ..isActive = isActive
      ..createdAt = DateTime.now();
  }

  factory AlarmInfo.fromEntity(AlarmEntity entity) {
    return AlarmInfo(
      id: entity.alarmId,
      location: entity.location,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isActive: entity.isActive,
    );
  }

  AlarmInfo copyWith({
    String? id,
    String? location,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) {
    return AlarmInfo(
      id: id ?? this.id,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
    );
  }
}
