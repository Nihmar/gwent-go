/// Deterministic 32-bit pseudo random generator (xorshift128).
///
/// `dart:math`'s seeded `Random` is not guaranteed to produce the same sequence
/// across Dart versions or platforms, which would make replays and any future
/// lockstep verification unreliable. This generator is small, documented and
/// stable on every target; [seed] is what match snapshots store, so a resumed
/// or replayed match keeps drawing the same cards.
class GameRandom {
  GameRandom([int? seed]) : seed = seed ?? _clockSeed() {
    _state = _seedState(this.seed);
  }

  /// Seed that produced this generator. Always present so a snapshot can
  /// restore the exact sequence.
  final int seed;

  /// Four 32-bit words: [x, y, z, w] xorshift state.
  late final List<int> _state;

  static const int _mask32 = 0xFFFFFFFF;
  static const int _space = 0x100000000;

  /// Clock-based seed used when the caller does not provide one.
  static int _clockSeed() => DateTime.now().microsecondsSinceEpoch & _mask32;

  /// SplitMix32, used to spread a single seed over the four state words.
  static List<int> _seedState(int seed) {
    var x = seed & _mask32;
    int next() {
      x = (x + 0x9E3779B9) & _mask32;
      var z = x;
      z = (z ^ (z >> 16)) & _mask32;
      z = (z * 0x21F0AAAD) & _mask32;
      z = (z ^ (z >> 15)) & _mask32;
      z = (z * 0x735A2D97) & _mask32;
      z = (z ^ (z >> 15)) & _mask32;
      return z;
    }

    final state = [next(), next(), next(), next()];
    // xorshift128 must not start from all zeroes.
    if (state.every((word) => word == 0)) state[0] = 1;
    return state;
  }

  int _next32() {
    var t = (_state[3] ^ (_state[3] << 11)) & _mask32;
    _state[3] = _state[2];
    _state[2] = _state[1];
    _state[1] = _state[0];
    _state[0] = (_state[0] ^ (_state[0] >> 19) ^ t ^ (t >> 8)) & _mask32;
    return _state[0];
  }

  /// Uniform value in `[0, max)`.
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be positive');
    }
    // Rejection sampling avoids the modulo bias of a truncated 32-bit word.
    final limit = _space - (_space % max);
    while (true) {
      final value = _next32();
      if (value < limit) return value % max;
    }
  }

  /// Uniform value in `[0, 1)`.
  double nextDouble() => _next32() / _space;

  T pick<T>(List<T> items) => items[nextInt(items.length)];

  bool chance(double probability) => nextDouble() < probability;

  /// In-place Fisher–Yates shuffle.
  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final swap = items[i];
      items[i] = items[j];
      items[j] = swap;
    }
  }
}
