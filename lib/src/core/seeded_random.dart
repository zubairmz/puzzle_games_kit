import 'dart:math' as math;

const int _mask32 = 0xFFFFFFFF;

/// A small, deterministic pseudo-random number generator (xorshift32).
///
/// Unlike `dart:math`'s `Random`, the sequence produced for a given seed is
/// part of this package's contract: the same seed yields the same numbers on
/// every platform (including the web) and across package versions. That is
/// what lets a seed identify a puzzle, so a puzzle can be regenerated,
/// shared, or replayed later from its seed alone.
///
/// Only 32-bit shifts and XORs are used, which behave identically on the Dart
/// VM and when compiled to JavaScript.
class SeededRandom {
  /// Creates a generator for [seed]. Any integer is accepted.
  SeededRandom(int seed) : _state = _initialState(seed) {
    // Warm up so that similar seeds diverge quickly.
    for (var i = 0; i < 8; i++) {
      _next();
    }
  }

  int _state;

  /// A seed that differs on every call, for when no seed is supplied.
  static int randomSeed() => math.Random().nextInt(0x7FFFFFFF);

  /// A stable seed for a calendar [date] (time of day is ignored).
  ///
  /// Pass [salt] to derive a different seed for the same day, for example a
  /// user id to give every user their own daily puzzle, or a game name to
  /// keep the seeds of different games apart.
  static int dailySeed(DateTime date, {String salt = ''}) {
    final day = date.year * 10000 + date.month * 100 + date.day;
    return salt.isEmpty ? day : combine(day, hashString(salt));
  }

  /// Mixes two values into one seed.
  static int combine(int a, int b) {
    final x = (_fold(a) ^ ((_fold(b) << 7) & _mask32)) & _mask32;
    return (x ^ (_fold(b) >> 3)) & _mask32;
  }

  /// A stable 32-bit hash of [value] (djb2-xor), identical on all platforms.
  static int hashString(String value) {
    var hash = 5381;
    for (final unit in value.codeUnits) {
      hash = ((((hash << 5) & _mask32) + hash) & _mask32) ^ unit;
    }
    return hash & _mask32;
  }

  static int _fold(int value) {
    // Fold anything wider than 32 bits (and negatives) into 32 bits without
    // relying on shifts wider than 32, which differ on the web.
    final low = value & _mask32;
    final high = (value ~/ 0x100000000) & _mask32;
    return (low ^ high) & _mask32;
  }

  static int _initialState(int seed) {
    final state = (_fold(seed) ^ 0x9E3779B9) & _mask32;
    return state == 0 ? 0x6D2B79F5 : state;
  }

  int _next() {
    var x = _state;
    x ^= (x << 13) & _mask32;
    x ^= x >> 17;
    x ^= (x << 5) & _mask32;
    _state = x & _mask32;
    return _state;
  }

  /// A non-negative integer less than [max]. [max] must be positive.
  int nextInt(int max) {
    RangeError.checkValueInInterval(max, 1, _mask32, 'max');
    return _next() % max;
  }

  /// A double in the range `[0, 1)`.
  double nextDouble() => _next() / 4294967296.0;

  /// A random boolean.
  bool nextBool() => (_next() & 1) == 1;

  /// A random element of [items], which must not be empty.
  T pick<T>(List<T> items) => items[nextInt(items.length)];

  /// Shuffles [items] in place (Fisher–Yates) and returns it.
  List<T> shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
    return items;
  }
}
