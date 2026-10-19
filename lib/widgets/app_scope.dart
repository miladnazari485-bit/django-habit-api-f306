import 'package:flutter/widgets.dart';

import '../state/app_state.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    final state = scope?.notifier;
    if (state == null) {
      throw StateError('AppScope was not found in the widget tree.');
    }
    return state;
  }
}
