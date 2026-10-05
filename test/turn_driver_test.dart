import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/ai/ai_players.dart';
import 'package:gwent_go/presentation/controllers/turn_driver.dart';

import 'support/engine_harness.dart';

void main() {
  group('IdleTurnDriver', () {
    test('never acts', () {
      const driver = IdleTurnDriver();
      driver.onStateChanged();
      driver.dispose();
    });
  });

  group('LocalAiDriver', () {
    test('does nothing while it is the other seat turn', () async {
      final engine = harness();
      setTurn(engine, 0);
      var applied = 0;
      final driver = LocalAiDriver(
        engine: engine,
        seat: 1,
        ai: EasyAi(),
        delay: const Duration(milliseconds: 5),
        onApplied: () => applied++,
        onThinkingChanged: (_) {},
      );

      driver.onStateChanged();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(applied, 0);
      driver.dispose();
    });

    test('plays the seat after the delay and clears thinking', () async {
      final engine = harness();
      setTurn(engine, 1);
      var applied = 0;
      final thinking = <bool>[];
      final driver = LocalAiDriver(
        engine: engine,
        seat: 1,
        ai: EasyAi(),
        delay: const Duration(milliseconds: 5),
        onApplied: () => applied++,
        onThinkingChanged: thinking.add,
      );

      driver.onStateChanged();
      expect(thinking, [true]);

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(applied, greaterThan(0));
      expect(thinking.last, isFalse);
      // Easy always plays its strongest card, so a card left the hand.
      expect(engine.state.players[1].hand.length, lessThan(5));
      driver.dispose();
    });

    test('a pending move is cancelled by dispose', () async {
      final engine = harness();
      setTurn(engine, 1);
      var applied = 0;
      final driver = LocalAiDriver(
        engine: engine,
        seat: 1,
        ai: EasyAi(),
        delay: const Duration(milliseconds: 10),
        onApplied: () => applied++,
        onThinkingChanged: (_) {},
      );

      driver.onStateChanged();
      driver.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(applied, 0);
    });
  });
}
