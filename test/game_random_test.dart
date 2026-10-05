import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/rules/game_random.dart';

void main() {
  group('GameRandom', () {
    test('a fixed seed produces a stable sequence', () {
      // Golden values: this generator must not drift between Dart versions or
      // platforms, or seeded replays would break.
      final random = GameRandom(42);

      expect(
        [for (var i = 0; i < 6; i++) random.nextInt(100)],
        [62, 24, 91, 45, 74, 7],
      );
      expect(
        [for (var i = 0; i < 3; i++) random.nextDouble()],
        [closeTo(0.411039, 1e-6), closeTo(0.153165, 1e-6), closeTo(0.505695, 1e-6)],
      );
    });

    test('the same seed replays the same draws', () {
      final a = GameRandom(99);
      final b = GameRandom(99);

      expect(
        [for (var i = 0; i < 20; i++) a.nextInt(1000)],
        [for (var i = 0; i < 20; i++) b.nextInt(1000)],
      );
    });

    test('different seeds diverge', () {
      final a = GameRandom(1);
      final b = GameRandom(2);

      expect(
        [for (var i = 0; i < 10; i++) a.nextInt(1000)],
        isNot([for (var i = 0; i < 10; i++) b.nextInt(1000)]),
      );
    });

    test('the generator without a seed still records one', () {
      final random = GameRandom();

      expect(random.seed, isNot(0));
      expect(GameRandom(random.seed).nextInt(1 << 20),
          GameRandom(random.seed).nextInt(1 << 20));
    });

    test('nextInt stays in range', () {
      final random = GameRandom(3);

      for (var i = 0; i < 500; i++) {
        final value = random.nextInt(7);
        expect(value, inInclusiveRange(0, 6));
      }
      expect(() => random.nextInt(0), throwsArgumentError);
    });

    test('nextDouble stays in [0, 1)', () {
      final random = GameRandom(4);

      for (var i = 0; i < 500; i++) {
        final value = random.nextDouble();
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(1));
      }
    });

    test('shuffle is a deterministic permutation', () {
      final list = [for (var i = 0; i < 8; i++) i];
      GameRandom(7).shuffle(list);

      expect(list, [3, 5, 6, 4, 7, 1, 2, 0]);
      expect(list..sort(), [0, 1, 2, 3, 4, 5, 6, 7]);
    });
  });
}
