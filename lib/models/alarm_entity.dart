import 'package:isar/isar.dart';

part 'alarm_entity.g.dart';

@collection
class AlarmEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String alarmId;

  late String location;
  late double latitude;
  late double longitude;
  late bool isActive;
  late DateTime createdAt;
}
