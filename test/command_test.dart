import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/core/rules/game_command.dart';
import 'package:gwent_go/core/rules/game_engine.dart';
import 'package:gwent_go/core/rules/game_random.dart';

import 'support/engine_harness.dart';

/// An engine still in the mulligan phase, with the full default decks.
GameEngine mulliganEngine() {
  final decks = CardRepository.defaultDecks();
  final engine = GameEngine(
    humanDeck: decks[0],
    opponentDeck: decks[1],
    difficulty: Difficulty.normal,
    random: GameRandom(11),
  );
  engine.startMatch();
  return engine;
}

CommandRejection rejectionOf(CommandResult result) {
  expect(result, isA<CommandRejected>());
  return (result as CommandRejected).reason;
}

void main() {
  group('PlayCardCommand', () {
    test('an accepted command places the card', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['gryffin']);
      final card = engine.human.hand.first;

      final result = engine.apply(
        PlayCardCommand(player: 0, cardUid: card.uid),
      );

      expect(result, isA<CommandAccepted>());
      expect(
        engine.state.rowState(0, CardRow.close).cards.map((c) => c.id),
        contains('gryffin'),
      );
      expect(engine.state.currentPlayer, 1);
    });

    test('a command from the other seat is rejected', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 1, ['gryffin']);
      final card = engine.opponent.hand.first;

      expect(
        rejectionOf(
          engine.apply(PlayCardCommand(player: 1, cardUid: card.uid)),
        ),
        CommandRejection.notYourTurn,
      );
    });

    test('a card outside the hand is rejected', () {
      final engine = harness();
      setTurn(engine, 0);
      engine.human.hand.clear();
      final card = makeCard('gryffin', owner: 0);
      engine.human.deck.add(card);

      expect(
        rejectionOf(
          engine.apply(PlayCardCommand(player: 0, cardUid: card.uid)),
        ),
        CommandRejection.cardNotInHand,
      );
    });

    test('an unknown card id is rejected', () {
      final engine = harness();
      setTurn(engine, 0);

      expect(
        rejectionOf(
          engine.apply(const PlayCardCommand(player: 0, cardUid: 999999)),
        ),
        CommandRejection.unknownCard,
      );
    });

    test('a row-special slot that is taken is rejected', () {
      final engine = harness();
      setTurn(engine, 0);
      engine.state.rowState(0, CardRow.close).special = makeCard(
        'horn',
        owner: 0,
      );
      setHand(engine, 0, ['horn']);
      final card = engine.human.hand.first;

      expect(
        rejectionOf(
          engine.apply(
            PlayCardCommand(
              player: 0,
              cardUid: card.uid,
              targetRow: CardRow.close,
            ),
          ),
        ),
        CommandRejection.rowOccupied,
      );
    });

    test('a decoy without a target is rejected', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['decoy']);
      final card = engine.human.hand.first;

      expect(
        rejectionOf(
          engine.apply(PlayCardCommand(player: 0, cardUid: card.uid)),
        ),
        CommandRejection.noTarget,
      );
    });

    test('a command during the mulligan is rejected', () {
      final engine = mulliganEngine();
      final card = engine.human.hand.first;

      expect(
        rejectionOf(
          engine.apply(PlayCardCommand(player: 0, cardUid: card.uid)),
        ),
        CommandRejection.wrongPhase,
      );
    });
  });

  group('PassCommand', () {
    test('passing twice is rejected', () {
      final engine = harness();
      setTurn(engine, 0);

      expect(engine.apply(const PassCommand(0)), isA<CommandAccepted>());
      expect(
        rejectionOf(engine.apply(const PassCommand(0))),
        CommandRejection.playerPassed,
      );
    });
  });

  group('ActivateLeaderCommand', () {
    test('a used leader is rejected', () {
      final engine = harness();
      setTurn(engine, 0);

      expect(
        engine.apply(const ActivateLeaderCommand(player: 0)),
        isA<CommandAccepted>(),
      );
      setTurn(engine, 0);
      expect(
        rejectionOf(engine.apply(const ActivateLeaderCommand(player: 0))),
        CommandRejection.leaderUnavailable,
      );
    });

    test('a passive leader cannot be activated', () {
      final engine = harness(humanLeader: 'king_bran');
      setTurn(engine, 0);

      expect(
        rejectionOf(engine.apply(const ActivateLeaderCommand(player: 0))),
        CommandRejection.leaderUnavailable,
      );
    });
  });

  group('RedrawCommand', () {
    test('redraws are limited to two', () {
      final engine = mulliganEngine();

      for (var i = 0; i < GameEngine.maxRedraws; i++) {
        final card = engine.human.hand.first;
        expect(
          engine.apply(RedrawCommand(player: 0, cardUid: card.uid)),
          isA<CommandAccepted>(),
        );
      }
      final card = engine.human.hand.first;
      expect(
        rejectionOf(engine.apply(RedrawCommand(player: 0, cardUid: card.uid))),
        CommandRejection.noRedrawsLeft,
      );
    });

    test('another seat cannot redraw yet', () {
      final engine = mulliganEngine();
      final card = engine.opponent.hand.first;

      expect(
        rejectionOf(engine.apply(RedrawCommand(player: 1, cardUid: card.uid))),
        CommandRejection.notYourTurn,
      );
    });
  });

  group('FinishMulliganCommand', () {
    test('another seat cannot finish the mulligan yet', () {
      final engine = mulliganEngine();

      expect(
        rejectionOf(engine.apply(const FinishMulliganCommand(1))),
        CommandRejection.notYourTurn,
      );
    });

    test('the local seat starts the first round', () {
      final engine = mulliganEngine();

      expect(
        engine.apply(const FinishMulliganCommand(0)),
        isA<CommandAccepted>(),
      );
      expect(engine.state.phase, GamePhase.playing);
      expect(engine.state.roundNumber, 1);
    });
  });

  group('cardByUid', () {
    test('finds cards in hand, rows and the graveyard', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['gryffin']);
      final inHand = engine.human.hand.first;
      final onRow = makeCard('fiend', owner: 0);
      engine.state.rowState(0, CardRow.close).cards.add(onRow);
      final inGrave = makeCard('ciri', owner: 1);
      engine.opponent.graveyard.add(inGrave);

      expect(engine.cardByUid(inHand.uid), same(inHand));
      expect(engine.cardByUid(onRow.uid), same(onRow));
      expect(engine.cardByUid(inGrave.uid), same(inGrave));
      expect(engine.cardByUid(999999), isNull);
    });
  });
}
