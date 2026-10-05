import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/ai/ai.dart';
import 'package:gwent_go/core/ai/ai_players.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/core/rules/game_engine.dart';
import 'package:gwent_go/core/rules/game_random.dart';

import 'support/engine_harness.dart';

/// Runs a full AI vs AI match, returning the number of turns used.
int playMatch(Difficulty difficulty, {int seed = 1, int maxTurns = 2000}) {
  final decks = CardRepository.defaultDecks();
  final engine = GameEngine(
    humanDeck: decks[0],
    opponentDeck: decks[1],
    difficulty: difficulty,
    random: GameRandom(seed),
  );
  engine.startMatch();
  engine.takeEvents();
  engine.finishMulligan();
  engine.takeEvents();

  final ai = createAi(difficulty);
  var turns = 0;
  while (!engine.state.isOver && turns < maxTurns) {
    final player = engine.state.players[engine.state.currentPlayer];
    final action = ai.decide(engine, player);
    final applied = _apply(engine, player.index, action);
    if (!applied) engine.pass(player.index);
    engine.takeEvents();
    turns++;
  }
  expect(engine.state.phase, GamePhase.gameOver, reason: 'match did not finish');
  return turns;
}

bool _apply(GameEngine engine, int index, AiAction action) {
  return switch (action) {
    AiPlayCard(:final card, :final targetRow, :final target) => engine.playCard(
      index,
      card,
      targetRow: targetRow,
      target: target,
    ),
    AiActivateLeader(:final targetRow, :final target) => engine.activateLeader(
      index,
      targetRow: targetRow,
      target: target,
    ),
    AiPass() => () {
      engine.pass(index);
      return true;
    }(),
  };
}

void main() {
  group('AI difficulties', () {
    for (final difficulty in Difficulty.values) {
      test('${difficulty.name} AI finishes a self-play match', () {
        final turns = playMatch(difficulty);
        expect(turns, greaterThan(5));
      });
    }

    test('Easy plays its strongest card and ignores the leader', () {
      final engine = harness();
      setTurn(engine, 1);
      engine.opponent.hand
        ..clear()
        ..addAll([makeCard('gryffin', owner: 1), makeCard('fiend', owner: 1)]);
      final action = EasyAi().decide(engine, engine.opponent);
      expect(action, isA<AiPlayCard>());
      expect((action as AiPlayCard).card.id, 'fiend');
    });

    test('Hard passes when ahead and the opponent has already passed', () {
      final engine = harness();
      setTurn(engine, 1);
      engine.state.rowState(1, CardRow.close).cards.add(
        makeCard('geralt', owner: 1),
      );
      engine.state.players[0].passed = true;
      final action = HardAi().decide(engine, engine.opponent);
      expect(action, isA<AiPass>());
    });

    test('Normal returns a legal action on the opening turn', () {
      final engine = harness();
      setTurn(engine, 1);
      final action = NormalAi().decide(engine, engine.opponent);
      expect(action, isA<AiAction>());
    });
  });
}
