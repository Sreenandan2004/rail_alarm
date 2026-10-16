import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rail_alarm/models/alarm_info.dart';
import 'package:rail_alarm/models/tracking_state.dart';
import 'package:rail_alarm/services/battery_optimization_service.dart';
import 'package:rail_alarm/widgets/trip_status_hud.dart';

void main() {
  group('BatteryOptimizationService Tests', () {
    test('Default package name matches RailAlarm application ID', () {
      expect(BatteryOptimizationService.defaultPackageName, 'com.sreenandan.rail_alarm');
    });

    test('OEM tips contain guidance for all major Android manufacturers', () {
      final tips = BatteryOptimizationService.oemTips;
      expect(tips.isNotEmpty, isTrue);

      final oemNames = tips.map((t) => t['oem']!).join(' ');
      expect(oemNames.contains('Xiaomi'), isTrue);
      expect(oemNames.contains('Samsung'), isTrue);
      expect(oemNames.contains('OnePlus'), isTrue);
      expect(oemNames.contains('Vivo'), isTrue);
      expect(oemNames.contains('Pixel'), isTrue);

      for (final tip in tips) {
        expect(tip['step'], isNotNull);
        expect(tip['step']!.isNotEmpty, isTrue);
      }
    });

    test('Intent launchers execute safely without crashing in unit test environment', () async {
      final res1 = await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
      expect(res1, isA<bool>());

      final res2 = await BatteryOptimizationService.openBatteryOptimizationSettings();
      expect(res2, isA<bool>());

      final res3 = await BatteryOptimizationService.openAppSettings();
      expect(res3, isA<bool>());
    });
  });

  group('TripStatusHud Widget Tests', () {
    testWidgets('Renders idle pill when no active alarm is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TripStatusHud(
              activeAlarm: null,
              decision: null,
            ),
          ),
        ),
      );

      expect(find.textContaining('No active trip'), findsOneWidget);
    });

    testWidgets('Renders live telemetry and safe sleep badge when alarm and decision are active', (tester) async {
      final alarm = AlarmInfo(
        id: 'test_123',
        location: 'Palakkad Junction (PGT)',
        latitude: 10.7867,
        longitude: 76.6548,
        isActive: true,
        leadDistanceKm: 10.0,
      );

      final decision = AdaptiveTrackingDecision(
        tier: DistanceTier.approaching,
        sleepInterval: const Duration(minutes: 5),
        locationAccuracy: LocationAccuracy.medium,
        distanceKm: 34.5,
        currentSpeedKmh: 75.0,
        eta: const Duration(minutes: 28),
        shouldTrigger: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripStatusHud(
              activeAlarm: alarm,
              decision: decision,
            ),
          ),
        ),
      );

      expect(find.text('LIVE TRIP MONITOR'), findsOneWidget);
      expect(find.text('APPROACHING'), findsOneWidget);
      expect(find.text('Palakkad Junction (PGT)'), findsOneWidget);
      expect(find.text('34.5 km'), findsOneWidget);
      expect(find.text('75 km/h'), findsOneWidget);
      expect(find.text('28m'), findsOneWidget);
      expect(find.textContaining('Next GPS check in 5.0 min'), findsOneWidget);
      expect(find.text('Alarm @ <10km'), findsOneWidget);
    });
  });
}
