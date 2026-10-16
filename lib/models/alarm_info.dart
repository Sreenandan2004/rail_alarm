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
}
