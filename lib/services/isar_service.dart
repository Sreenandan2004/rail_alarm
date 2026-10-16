import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/alarm_entity.dart';
import '../models/alarm_info.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  Isar? _isar;
  final List<AlarmInfo> _webAlarms = [];
  final StreamController<List<AlarmInfo>> _webStreamController =
      StreamController<List<AlarmInfo>>.broadcast();

  Future<Isar?> get isar async {
    if (kIsWeb) return null;
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }
    _isar = await openDb();
    return _isar;
  }

  Future<Isar> openDb() async {
    if (kIsWeb) {
      throw UnsupportedError('Isar direct open not used on web');
    }
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
    if (kIsWeb) {
      final index = _webAlarms.indexWhere((a) => a.id == alarm.id);
      if (index >= 0) {
        _webAlarms[index] = alarm;
      } else {
        _webAlarms.insert(0, alarm);
      }
      _webStreamController.add(List.unmodifiable(_webAlarms));
      return;
    }
    final db = (await isar)!;
    final entity = alarm.toEntity();
    await db.writeTxn(() async {
      await db.alarmEntitys.putByAlarmId(entity);
    });
  }

  /// Delete alarm by alarmId string
  Future<void> deleteAlarm(String alarmId) async {
    if (kIsWeb) {
      _webAlarms.removeWhere((a) => a.id == alarmId);
      _webStreamController.add(List.unmodifiable(_webAlarms));
      return;
    }
    final db = (await isar)!;
    await db.writeTxn(() async {
      await db.alarmEntitys.deleteByAlarmId(alarmId);
    });
  }

  /// Toggle active state of an alarm
  Future<void> toggleAlarmActive(String alarmId, bool isActive) async {
    if (kIsWeb) {
      final index = _webAlarms.indexWhere((a) => a.id == alarmId);
      if (index >= 0) {
        _webAlarms[index] = _webAlarms[index].copyWith(isActive: isActive);
        _webStreamController.add(List.unmodifiable(_webAlarms));
      }
      return;
    }
    final db = (await isar)!;
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
    if (kIsWeb) {
      return List.unmodifiable(_webAlarms);
    }
    final db = (await isar)!;
    final entities = await db.alarmEntitys.where().sortByCreatedAtDesc().findAll();
    return entities.map((e) => AlarmInfo.fromEntity(e)).toList();
  }

  /// Watch all alarms reactively
  Stream<List<AlarmInfo>> watchAlarms() async* {
    if (kIsWeb) {
      yield List.unmodifiable(_webAlarms);
      yield* _webStreamController.stream;
      return;
    }
    final db = (await isar)!;
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
