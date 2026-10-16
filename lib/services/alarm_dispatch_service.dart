import 'package:flutter/foundation.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

/// Service responsible for dispatching wake-up alarms to the device's native clock app.
class AlarmDispatchService {
  /// Schedules a native system alarm on the user's default clock app.
  /// Sets the alarm for [scheduledTime] (defaults to 1 minute from now).
  static Future<bool> dispatchSystemAlarm({
    required String locationName,
    DateTime? scheduledTime,
    bool skipUi = true,
  }) async {
    final targetTime = scheduledTime ?? DateTime.now().add(const Duration(minutes: 1));

    if (kIsWeb) {
      debugPrint('[AlarmDispatchService] Web platform: System alarm intent skipped for $locationName.');
      return false;
    }

    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        arguments: <String, dynamic>{
          'android.intent.extra.alarm.MESSAGE': 'Arriving at $locationName! (RailAlarm)',
          'android.intent.extra.alarm.HOUR': targetTime.hour,
          'android.intent.extra.alarm.MINUTES': targetTime.minute,
          'android.intent.extra.alarm.SKIP_UI': skipUi,
          'android.intent.extra.alarm.VIBRATE': true,
        },
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );

      await intent.launch();
      return true;
    } catch (e) {
      debugPrint('[AlarmDispatchService] Failed to launch system alarm intent: $e');
      return false;
    }
  }

  /// Triggers a test alarm scheduled for 1 minute from now.
  static Future<bool> testSystemAlarm({String? locationName}) async {
    return dispatchSystemAlarm(
      locationName: locationName ?? 'Test Station',
      skipUi: false,
    );
  }
}
