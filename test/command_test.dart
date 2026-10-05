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
    firstDeck: decks[0],
    secondDeck: decks[1],
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
      final card = engine.state.players[0].hand.first;

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
      final card = engine.state.players[1].hand.first;

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
      engine.state.players[0].hand.clear();
      final card = makeCard('gryffin', owner: 0);
      engine.state.players[0].deck.add(card);

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
      final card = engine.state.players[0].hand.first;

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
      final card = engine.state.players[0].hand.first;

      expect(
        rejectionOf(
          engine.apply(PlayCardCommand(player: 0, cardUid: card.uid)),
        ),
        CommandRejection.noTarget,
      );
    });

    test('a command during the mulligan is rejected', () {
      final engine = mulliganEngine();
      final card = engine.state.players[0].hand.first;

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
    test('each seat is limited to two redraws', () {
      final engine = mulliganEngine();

      for (final seat in [0, 1]) {
        for (var i = 0; i < GameEngine.maxRedraws; i++) {
          final card = engine.state.players[seat].hand.first;
          expect(
            engine.apply(RedrawCommand(player: seat, cardUid: card.uid)),
            isA<CommandAccepted>(),
          );
        }
        final card = engine.state.players[seat].hand.first;
        expect(
          rejectionOf(
            engine.apply(RedrawCommand(player: seat, cardUid: card.uid)),
          ),
          CommandRejection.noRedrawsLeft,
        );
      }
    });

    test('a seat that confirmed its hand cannot redraw', () {
      final engine = mulliganEngine();
      engine.apply(const FinishMulliganCommand(0));
      final card = engine.state.players[0].hand.first;

      expect(
        rejectionOf(engine.apply(RedrawCommand(player: 0, cardUid: card.uid))),
        CommandRejection.alreadyDone,
      );
    });
  });

  group('FinishMulliganCommand', () {
    test('the round starts once every seat has finished', () {
      final engine = mulliganEngine();

      expect(
        engine.apply(const FinishMulliganCommand(1)),
        isA<CommandAccepted>(),
      );
      expect(engine.state.phase, GamePhase.mulligan);

      expect(
        engine.apply(const FinishMulliganCommand(0)),
        isA<CommandAccepted>(),
      );
      expect(engine.state.phase, GamePhase.playing);
      expect(engine.state.roundNumber, 1);
    });

    test('finishing twice is rejected', () {
      final engine = mulliganEngine();
      engine.apply(const FinishMulliganCommand(0));

      expect(
        rejectionOf(engine.apply(const FinishMulliganCommand(0))),
        CommandRejection.alreadyDone,
      );
    });
  });

  group('ChooseFirstPlayerCommand', () {
    GameEngine scoiaEngine() {
      final decks = CardRepository.defaultDecks();
      final scoia = decks.firstWhere(
        (deck) => deck.faction == CardFaction.scoiatael,
      );
      final realms = decks.firstWhere(
        (deck) => deck.faction == CardFaction.realms,
      );
      final engine = GameEngine(
        firstDeck: scoia,
        secondDeck: realms,
        difficulty: Difficulty.normal,
        random: GameRandom(5),
      );
      engine.startMatch();
      return engine;
    }

    test('only the lone Scoia\'tael seat may choose', () {
      final engine = scoiaEngine();
      expect(engine.firstPlayerChoice, 0);

      expect(
        rejectionOf(
          engine.apply(
            const ChooseFirstPlayerCommand(player: 1, firstPlayer: 1),
          ),
        ),
        CommandRejection.choiceNotAllowed,
      );

      expect(
        engine.apply(const ChooseFirstPlayerCommand(player: 0, firstPlayer: 1)),
        isA<CommandAccepted>(),
      );
      expect(engine.state.firstPlayer, 1);
      expect(engine.firstPlayerChoice, isNull);

      // The decision is not offered again.
      expect(
        rejectionOf(
          engine.apply(
            const ChooseFirstPlayerCommand(player: 0, firstPlayer: 0),
          ),
        ),
        CommandRejection.choiceNotAllowed,
      );
    });

    test('a seat outside the match is rejected', () {
      final engine = scoiaEngine();

      expect(
        rejectionOf(
          engine.apply(
            const ChooseFirstPlayerCommand(player: 0, firstPlayer: 9),
          ),
        ),
        CommandRejection.invalidChoice,
      );
    });
  });

  group('cardByUid', () {
    test('finds cards in hand, rows and the graveyard', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['gryffin']);
      final inHand = engine.state.players[0].hand.first;
      final onRow = makeCard('fiend', owner: 0);
      engine.state.rowState(0, CardRow.close).cards.add(onRow);
      final inGrave = makeCard('ciri', owner: 1);
      engine.state.players[1].graveyard.add(inGrave);

      expect(engine.cardByUid(inHand.uid), same(inHand));
      expect(engine.cardByUid(onRow.uid), same(onRow));
      expect(engine.cardByUid(inGrave.uid), same(inGrave));
      expect(engine.cardByUid(999999), isNull);
    });
  });
}
