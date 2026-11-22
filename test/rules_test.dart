import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_games/puzzle_games.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PuzzleRules', () {
    test('copyWith replaces only the given fields', () {
      final rules = starBattleRules();
      final edited = rules.copyWith(summary: 'Short.', buttonLabel: 'Rules');
      expect(edited.summary, 'Short.');
      expect(edited.buttonLabel, 'Rules');
      expect(edited.title, rules.title);
      expect(edited.sections, rules.sections);
      expect(edited.closeLabel, rules.closeLabel);
    });

    test('equality compares every field', () {
      expect(shikakuRules(), shikakuRules());
      expect(shikakuRules() == shikakuRules().copyWith(title: 'X'), isFalse);
    });

    test('every game has a summary and full rules', () {
      for (final rules in [
        sudokuRules(),
        starBattleRules(),
        shikakuRules(),
      ]) {
        expect(rules.summary, isNotEmpty);
        expect(rules.sections, isNotEmpty);
        expect(rules.buttonLabel, 'How to play');
      }
    });

    test('keyboard help is optional', () {
      bool hasKeyboard(PuzzleRules r) =>
          r.sections.any((s) => s.title == 'Keyboard');
      expect(hasKeyboard(shikakuRules(keyboardHelp: true)), isTrue);
      expect(hasKeyboard(shikakuRules(keyboardHelp: false)), isFalse);
      // Tests run as Android by default: a touch platform.
      expect(hasKeyboard(starBattleRules()), isFalse);
    });

    test('Sudoku rules follow the box shape', () {
      expect(sudokuRules(boxRows: 2, boxCols: 3).summary, contains('1 to 6'));
      expect(sudokuRules().summary, contains('1 to 9'));
    });
  });

  group('PuzzleRulesBar', () {
    testWidgets('shows the summary and opens the rules sheet', (tester) async {
      final rules = shikakuRules();
      await tester.pumpWidget(_app(PuzzleRulesBar(rules: rules)));
      expect(find.text(rules.summary), findsOneWidget);

      await tester.tap(find.text('How to play'));
      await tester.pumpAndSettle();
      expect(find.text(rules.title), findsOneWidget);
      for (final section in rules.sections) {
        final title = find.descendant(
          of: find.byType(PuzzleRulesSheet),
          matching: find.text(section.title),
        );
        await tester.scrollUntilVisible(title, 100,
            scrollable: find.byType(Scrollable).last);
        expect(title, findsOneWidget);
      }

      await tester.tap(find.text(rules.closeLabel));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleRulesSheet), findsNothing);
    });

    testWidgets('each part can be hidden', (tester) async {
      final rules = starBattleRules();
      await tester
          .pumpWidget(_app(PuzzleRulesBar(rules: rules, showButton: false)));
      expect(find.text(rules.summary), findsOneWidget);
      expect(find.byType(PuzzleRulesButton), findsNothing);

      await tester
          .pumpWidget(_app(PuzzleRulesBar(rules: rules, showSummary: false)));
      expect(find.text(rules.summary), findsNothing);
      expect(find.byType(PuzzleRulesButton), findsOneWidget);
    });

    testWidgets('a custom sheet builder replaces the sheet', (tester) async {
      await tester.pumpWidget(_app(PuzzleRulesBar(
        rules: sudokuRules(),
        sheetBuilder: (context, rules) => Text('Custom ${rules.title}'),
      )));
      await tester.tap(find.byType(PuzzleRulesButton));
      await tester.pumpAndSettle();
      expect(find.text('Custom Sudoku'), findsOneWidget);
    });
  });

  group('PuzzleRulesButton', () {
    testWidgets('icon only shows the label as a tooltip', (tester) async {
      await tester.pumpWidget(_app(PuzzleRulesButton(
        rules: starBattleRules().copyWith(buttonLabel: 'Rules'),
        iconOnly: true,
      )));
      expect(find.text('Rules'), findsNothing);
      expect(find.byTooltip('Rules'), findsOneWidget);
    });

    testWidgets('onPressed replaces the sheet', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(_app(PuzzleRulesButton(
        rules: starBattleRules(),
        onPressed: () => pressed++,
      )));
      await tester.tap(find.byType(PuzzleRulesButton));
      await tester.pumpAndSettle();
      expect(pressed, 1);
      expect(find.byType(PuzzleRulesSheet), findsNothing);
    });
  });

  group('Game widgets', () {
    testWidgets('show the default rules and accept custom text',
        (tester) async {
      final sudoku = SudokuController(
        puzzle: const SudokuGenerator().generate(size: SudokuSize.six, seed: 1),
      );
      addTearDown(sudoku.dispose);
      await tester.pumpWidget(_app(SudokuGame(controller: sudoku)));
      expect(find.text(sudokuRules(boxRows: 2, boxCols: 3).summary),
          findsOneWidget);
      expect(find.text('How to play'), findsOneWidget);

      await tester.pumpWidget(_app(SudokuGame(
        controller: sudoku,
        rules: sudokuRules(boxRows: 2, boxCols: 3)
            .copyWith(summary: 'Fill the grid.', buttonLabel: 'Rules'),
      )));
      expect(find.text('Fill the grid.'), findsOneWidget);
      expect(find.text('Rules'), findsOneWidget);
    });

    testWidgets('hide the rules when asked', (tester) async {
      final controller = StarBattleController(
        puzzle: const StarBattleGenerator().generate(size: 5, seed: 1),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(StarBattleGame(
        controller: controller,
        showRulesSummary: false,
        showRulesButton: false,
      )));
      expect(find.text(starBattleRules().summary), findsNothing);
      expect(find.byType(PuzzleRulesButton), findsNothing);
    });

    testWidgets('Shikaku opens its rules sheet', (tester) async {
      final controller = ShikakuController(
        puzzle: const ShikakuGenerator().generate(rows: 5, seed: 31),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(ShikakuGame(controller: controller)));
      await tester.tap(find.text('How to play'));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleRulesSheet), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
    });
  });
}
