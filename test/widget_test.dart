import 'package:flutter_test/flutter_test.dart';
import 'package:rail_alarm/main.dart';

void main() {
  testWidgets('RailAlarmApp loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RailAlarmApp());
    expect(find.text('RailAlarm'), findsWidgets);
  });
}
