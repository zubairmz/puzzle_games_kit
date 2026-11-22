import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_games/puzzle_games.dart';
import 'package:puzzle_games_example/app/app.dart';
import 'package:puzzle_games_example/core/settings/app_settings.dart';
import 'package:puzzle_games_example/features/home/data/game_catalog.dart';

void main() {
  late AppSettings settings;

  setUp(() => settings = AppSettings(themeMode: ThemeMode.light));
  tearDown(() => settings.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PuzzleGamesExampleApp(settings: settings));
  }

  testWidgets('home lists every game', (tester) async {
    await pumpApp(tester);
    for (final game in GameCatalog.all) {
      await tester.scrollUntilVisible(find.text(game.title), 100);
      expect(find.text(game.title), findsOneWidget);
    }
  });

  testWidgets('every game opens on a small phone', (tester) async {
    await pumpApp(tester);
    for (final game in GameCatalog.all) {
      await tester.scrollUntilVisible(find.text(game.title), 100);
      await tester.tap(find.text(game.title));
      await tester.pumpAndSettle();
      expect(find.text('How to play'), findsOneWidget, reason: game.title);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a game shows its rules and opens the sheet', (tester) async {
    await pumpApp(tester);
    await tester.scrollUntilVisible(find.text('Star Battle'), 100);
    await tester.tap(find.text('Star Battle'));
    await tester.pumpAndSettle();

    expect(find.text(starBattleRules().summary), findsOneWidget);
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleRulesSheet), findsOneWidget);
  });

  testWidgets('settings hide the rules and move help to the app bar',
      (tester) async {
    settings
      ..showRulesSummary = false
      ..showRulesButton = false;
    await pumpApp(tester);
    await tester.scrollUntilVisible(find.text('Shikaku'), 100);
    await tester.tap(find.text('Shikaku'));
    await tester.pumpAndSettle();

    expect(find.text(shikakuRules().summary), findsNothing);
    expect(find.text('How to play'), findsNothing);
    await tester.tap(find.byTooltip('How to play'));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleRulesSheet), findsOneWidget);
  });
}
