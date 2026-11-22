import 'package:flutter/material.dart';

import '../core/settings/app_settings.dart';
import '../core/settings/app_settings_scope.dart';
import '../features/home/home_page.dart';
import 'app_theme.dart';

/// The root of the example app.
///
/// Owns the [AppSettings] and makes them available to every screen through
/// [AppSettingsScope].
class PuzzleGamesExampleApp extends StatefulWidget {
  /// Creates the example app.
  const PuzzleGamesExampleApp({super.key, this.settings});

  /// Settings to start with; mainly for tests.
  final AppSettings? settings;

  @override
  State<PuzzleGamesExampleApp> createState() => _PuzzleGamesExampleAppState();
}

class _PuzzleGamesExampleAppState extends State<PuzzleGamesExampleApp> {
  late final AppSettings _settings = widget.settings ?? AppSettings();

  @override
  void dispose() {
    if (widget.settings == null) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      notifier: _settings,
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => MaterialApp(
          title: 'Puzzle games',
          debugShowCheckedModeBanner: false,
          themeMode: _settings.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const HomePage(),
        ),
      ),
    );
  }
}
