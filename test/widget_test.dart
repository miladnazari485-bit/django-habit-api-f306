import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opening the app pins today and lists each habit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(HabitTrackerApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Wake Up Early'), findsOneWidget);
    expect(find.text('Drink Water'), findsOneWidget);
    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Daily Habits'), findsOneWidget);
    expect(find.text('Postpone (1)'), findsOneWidget);

    await tester.drag(
      find.byWidgetPredicate(
        (widget) => widget is ListView && widget.scrollDirection == Axis.vertical,
      ),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('1,698 / 10,000 steps'), findsOneWidget);
  });

  testWidgets('reopens on the calendar month the user left', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final first = AppState();
    await first.load();
    first.rememberTab(2);
    first.rememberCalendarMonth(DateTime(2026, 2, 1));
    await first.settled;

    final restored = AppState();
    await restored.load();
    await tester.pumpWidget(HabitTrackerApp(state: restored));
    await tester.pumpAndSettle();

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('February 2026'), findsOneWidget);
  });
}
