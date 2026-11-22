import 'package:flutter/material.dart';
import 'package:puzzle_games/puzzle_games.dart';

void main() => runApp(const PuzzleGamesExample());

/// Demo app showing every game with difficulty, sizes, theming and results.
class PuzzleGamesExample extends StatefulWidget {
  /// Creates the demo app.
  const PuzzleGamesExample({super.key});

  @override
  State<PuzzleGamesExample> createState() => _PuzzleGamesExampleState();
}

class _PuzzleGamesExampleState extends State<PuzzleGamesExample> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    const seed = Colors.indigo;
    return MaterialApp(
      title: 'puzzle_games',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: HomePage(
        mode: _mode,
        onToggleMode: () => setState(() {
          _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        }),
      ),
    );
  }
}

/// Lists the games and lets you pick a difficulty.
class HomePage extends StatefulWidget {
  /// Creates the home page.
  const HomePage({super.key, required this.mode, required this.onToggleMode});

  /// The current theme mode.
  final ThemeMode mode;

  /// Switches between light and dark.
  final VoidCallback onToggleMode;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PuzzleDifficulty _difficulty = PuzzleDifficulty.medium;
  bool _daily = false;

  /// With "daily" on, everyone gets the same puzzle today. Add a user id as
  /// the salt to give each user their own daily puzzle instead.
  int? _seedFor(String game) =>
      _daily ? SeededRandom.dailySeed(DateTime.now(), salt: game) : null;

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle games'),
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            icon: Icon(widget.mode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: widget.onToggleMode,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Difficulty', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<PuzzleDifficulty>(
            segments: [
              for (final d in PuzzleDifficulty.values)
                ButtonSegment(value: d, label: Text(_label(d.name))),
            ],
            selected: {_difficulty},
            onSelectionChanged: (s) => setState(() => _difficulty = s.first),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Daily puzzle'),
            subtitle: const Text('Same puzzle for everyone today'),
            value: _daily,
            onChanged: (v) => setState(() => _daily = v),
          ),
          const SizedBox(height: 8),
          _GameTile(
            icon: Icons.grid_on_rounded,
            title: 'Mini Sudoku',
            subtitle: '6×6 — every row, column and box holds 1–6',
            onTap: () => _open(SudokuPage(
              size: SudokuSize.six,
              difficulty: _difficulty,
              seed: _seedFor('sudoku6'),
            )),
          ),
          _GameTile(
            icon: Icons.grid_4x4_rounded,
            title: 'Classic Sudoku',
            subtitle: '9×9 — the original',
            onTap: () => _open(SudokuPage(
              size: SudokuSize.nine,
              difficulty: _difficulty,
              seed: _seedFor('sudoku9'),
            )),
          ),
        ],
      ),
    );
  }
}

String _label(String name) => name[0].toUpperCase() + name.substring(1);

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Shows a finished game's result — in a real app, save it for stats and
/// leaderboards instead.
Future<void> showResultDialog(
  BuildContext context,
  PuzzleResult result, {
  required VoidCallback onPlayAgain,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(result.solved
          ? Icons.emoji_events_outlined
          : Icons.sentiment_dissatisfied_outlined),
      title: Text(result.solved ? 'Solved!' : 'Game over'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ResultRow('Time', formatPuzzleDuration(result.elapsed)),
          _ResultRow('Mistakes', '${result.mistakes}'),
          _ResultRow('Hints', '${result.hintsUsed}'),
          _ResultRow('Moves', '${result.moves}'),
          if (result.seed != null) _ResultRow('Seed', '${result.seed}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          child: const Text('Home'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPlayAgain();
          },
          child: const Text('Play again'),
        ),
      ],
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A Sudoku screen: generates a puzzle and wires up the result.
class SudokuPage extends StatefulWidget {
  /// Creates a Sudoku page.
  const SudokuPage({
    super.key,
    required this.size,
    required this.difficulty,
    this.seed,
  });

  /// Grid size.
  final SudokuSize size;

  /// Puzzle difficulty.
  final PuzzleDifficulty difficulty;

  /// Fixed seed (daily puzzle), or `null` for a random puzzle.
  final int? seed;

  @override
  State<SudokuPage> createState() => _SudokuPageState();
}

class _SudokuPageState extends State<SudokuPage> {
  late SudokuController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _newController(widget.seed);
  }

  SudokuController _newController(int? seed) => SudokuController(
        puzzle: const SudokuGenerator().generate(
          size: widget.size,
          difficulty: widget.difficulty,
          seed: seed,
        ),
        maxMistakes: 3,
        onFinished: (result) => showResultDialog(
          context,
          result,
          onPlayAgain: () => setState(() {
            _controller.dispose();
            _controller = _newController(null);
          }),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sudoku ${widget.size.length}×${widget.size.length}'),
        actions: [
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _controller.restart,
          ),
        ],
      ),
      body: SafeArea(child: SudokuGame(controller: _controller)),
    );
  }
}
