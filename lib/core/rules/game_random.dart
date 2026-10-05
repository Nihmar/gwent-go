import 'dart:math';

/// Deterministic-friendly random source for the rules engine.
///
/// Passing a seed makes a whole match reproducible, which the tests rely on.
class GameRandom {
  GameRandom([int? seed]) : _random = seed == null ? Random() : Random(seed);

  final Random _random;

  int nextInt(int max) => _random.nextInt(max);

  T pick<T>(List<T> items) => items[_random.nextInt(items.length)];

  bool chance(double probability) => _random.nextDouble() < probability;

  void shuffle<T>(List<T> items) => items.shuffle(_random);
}
