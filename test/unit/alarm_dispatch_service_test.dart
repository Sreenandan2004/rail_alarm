import 'package:flutter_test/flutter_test.dart';
import 'package:rail_alarm/services/alarm_dispatch_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlarmDispatchService Tests', () {
    test('dispatchSystemAlarm handles call gracefully without throwing', () async {
      // In unit test environment, native Android intent launch will safely catch or skip
      final result = await AlarmDispatchService.dispatchSystemAlarm(
        locationName: 'Palakkad Junction (PGT)',
        scheduledTime: DateTime.now().add(const Duration(minutes: 1)),
        skipUi: true,
      );

      // Should return a bool without throwing unhandled exceptions
      expect(result, isA<bool>());
    });

    test('testSystemAlarm handles test dispatch call gracefully', () async {
      final result = await AlarmDispatchService.testSystemAlarm(
        locationName: 'Coimbatore Junction',
      );
      expect(result, isA<bool>());
    });
  });
}
