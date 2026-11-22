/// Building blocks shared by every game: seeded randomness, difficulty,
/// results, rules text, the base controller, theming and common widgets.
///
/// Each game library (`sudoku.dart`, …) re-exports this, so you rarely need
/// to import it directly.
library;

export 'src/core/cell_position.dart';
export 'src/core/puzzle_controller.dart';
export 'src/core/puzzle_difficulty.dart';
export 'src/core/puzzle_result.dart';
export 'src/core/puzzle_rules.dart';
export 'src/core/seeded_random.dart';
export 'src/theme/puzzle_theme.dart';
export 'src/widgets/puzzle_clock_text.dart';
export 'src/widgets/puzzle_rules_bar.dart';
export 'src/widgets/puzzle_rules_button.dart';
export 'src/widgets/puzzle_rules_sheet.dart';
export 'src/widgets/puzzle_status_bar.dart';
