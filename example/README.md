# puzzle_games example

A demo app for the `puzzle_games` package: pick a game and difficulty, try
daily puzzles and dark mode, show or hide the rules, and see the result when
you finish.

```bash
flutter run
```

## Structure

```
lib/
├── main.dart                       Entry point
├── app/
│   ├── app.dart                    MaterialApp, owns the settings
│   └── app_theme.dart              Light and dark themes, PuzzleTheme tweaks
├── core/
│   └── settings/
│       ├── app_settings.dart       ChangeNotifier with the app's settings
│       └── app_settings_scope.dart InheritedNotifier that provides them
└── features/
    ├── home/
    │   ├── home_page.dart          Difficulty, settings and the game list
    │   ├── data/game_catalog.dart  Every game the app offers
    │   ├── models/game_entry.dart  One game on the home page
    │   └── widgets/                Difficulty selector, settings card, tile
    ├── play/
    │   ├── play_page.dart          Shared game screen: controller lifecycle,
    │   │                           result dialog, play again
    │   └── widgets/result_dialog.dart
    ├── sudoku/sudoku_screen.dart
    ├── star_battle/star_battle_screen.dart
    └── shikaku/shikaku_screen.dart
```

## State management

No extra package. The game controllers from `puzzle_games` are
`ChangeNotifier`s, and the app settings use the same approach: an
`AppSettings` `ChangeNotifier` provided through an `InheritedNotifier`.
In your own app you can hold the controllers in whatever you already use
(Provider, Riverpod, Bloc, GetX…).

## Adding a game

Add a screen under `features/` that returns a `PlayPage` with the game's
controller and widget, then add one `GameEntry` to `GameCatalog.all`.

## Tests

```bash
flutter test
```
