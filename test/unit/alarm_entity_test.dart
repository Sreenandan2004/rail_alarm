import 'package:flutter_test/flutter_test.dart';
import 'package:rail_alarm/models/alarm_entity.dart';
import 'package:rail_alarm/models/alarm_info.dart';

void main() {
  group('AlarmInfo & AlarmEntity mapping tests', () {
    test('converts AlarmInfo to AlarmEntity with correct fields', () {
      final info = AlarmInfo(
        id: 'NDLS_12345',
        location: 'New Delhi (NDLS)',
        latitude: 28.6424,
        longitude: 77.2205,
        isActive: true,
      );

      final entity = info.toEntity();
      expect(entity.alarmId, 'NDLS_12345');
      expect(entity.location, 'New Delhi (NDLS)');
      expect(entity.latitude, 28.6424);
      expect(entity.longitude, 77.2205);
      expect(entity.isActive, isTrue);
      expect(entity.createdAt, isNotNull);
    });

    test('reconstructs AlarmInfo from AlarmEntity faithfully', () {
      final entity = AlarmEntity()
        ..alarmId = 'HWH_999'
        ..location = 'Howrah Junction (HWH)'
        ..latitude = 22.5839
        ..longitude = 88.3426
        ..isActive = false
        ..createdAt = DateTime(2026, 1, 1);

      final info = AlarmInfo.fromEntity(entity);
      expect(info.id, 'HWH_999');
      expect(info.location, 'Howrah Junction (HWH)');
      expect(info.latitude, 22.5839);
      expect(info.longitude, 88.3426);
      expect(info.isActive, isFalse);
      expect(info.leadDistanceKm, 10.0);
    });

    test('faithfully preserves custom lead distance (e.g. 2.0 km for bus/car, 5.0 km for road)', () {
      final busAlarm = AlarmInfo(
        id: 'BUS_STOP_1',
        location: 'Kozhikode Bus Terminal',
        latitude: 11.2588,
        longitude: 75.7804,
        isActive: true,
        leadDistanceKm: 2.0,
      );

      final entity = busAlarm.toEntity();
      final restored = AlarmInfo.fromEntity(entity);

      expect(restored.location, 'Kozhikode Bus Terminal');
      expect(restored.leadDistanceKm, 2.0);
    });
  });
}
