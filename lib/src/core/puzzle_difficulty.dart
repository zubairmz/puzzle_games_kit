/// How hard a generated puzzle should be.
///
/// Each game maps these to its own parameters (grid size, number of clues);
/// every generator also accepts explicit values to override the defaults.
enum PuzzleDifficulty {
  /// Gentle: small grids or many clues.
  easy,

  /// The default.
  medium,

  /// Larger grids or few clues.
  hard,
}
