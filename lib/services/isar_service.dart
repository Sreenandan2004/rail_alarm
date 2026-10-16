import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/alarm_entity.dart';
import '../models/alarm_info.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  Isar? _isar;

  Future<Isar> get isar async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }
    _isar = await openDb();
    return _isar!;
  }

  Future<Isar> openDb() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.contains('rail_alarm_db')) {
      return Isar.getInstance('rail_alarm_db')!;
    }
    return await Isar.open(
      [AlarmEntitySchema],
      directory: dir.path,
      name: 'rail_alarm_db',
      inspector: false,
    );
  }

  /// Direct injection for testing
  void setDatabaseForTesting(Isar isarInstance) {
    _isar = isarInstance;
  }

  /// Save or update an alarm
  Future<void> saveAlarm(AlarmInfo alarm) async {
    final db = await isar;
    final entity = alarm.toEntity();
    await db.writeTxn(() async {
      await db.alarmEntitys.putByAlarmId(entity);
    });
  }

  /// Delete alarm by alarmId string
  Future<void> deleteAlarm(String alarmId) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.alarmEntitys.deleteByAlarmId(alarmId);
    });
  }

  /// Toggle active state of an alarm
  Future<void> toggleAlarmActive(String alarmId, bool isActive) async {
    final db = await isar;
    await db.writeTxn(() async {
      final existing = await db.alarmEntitys.getByAlarmId(alarmId);
      if (existing != null) {
        existing.isActive = isActive;
        await db.alarmEntitys.putByAlarmId(existing);
      }
    });
  }

  /// Get all alarms
  Future<List<AlarmInfo>> getAllAlarms() async {
    final db = await isar;
    final entities = await db.alarmEntitys.where().sortByCreatedAtDesc().findAll();
    return entities.map((e) => AlarmInfo.fromEntity(e)).toList();
  }

  /// Watch all alarms reactively
  Stream<List<AlarmInfo>> watchAlarms() async* {
    final db = await isar;
    yield* db.alarmEntitys
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .map((entities) => entities.map((e) => AlarmInfo.fromEntity(e)).toList());
  }

  /// Close the DB
  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }
}
