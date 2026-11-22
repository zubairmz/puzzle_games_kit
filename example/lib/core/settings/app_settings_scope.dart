import 'package:flutter/widgets.dart';

import 'app_settings.dart';

/// Makes [AppSettings] available below it and rebuilds dependents when they
/// change.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  /// Provides [notifier] to [child].
  const AppSettingsScope({
    super.key,
    required AppSettings super.notifier,
    required super.child,
  });

  /// The nearest settings; rebuilds [context] when they change.
  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'No AppSettingsScope found in context.');
    return scope!.notifier!;
  }
}
