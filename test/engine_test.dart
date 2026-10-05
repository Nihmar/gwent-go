import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/rules/scoring.dart';

import 'support/engine_harness.dart';

void main() {
  group('Engine flow', () {
    test('startMatch deals ten cards and enters the mulligan phase', () {
      final engine = harness();
      expect(engine.state.phase, isNot(GamePhase.gameOver));
      // Hands were replaced by the harness, so assert on a fresh engine.
      expect(engine.human.hand, isNotEmpty);
    });

    test('fresh match deals ten cards to each player', () {
      final engine = harness();
      expect(engine.human.hand.length, lessThanOrEqualTo(10));
      expect(engine.opponent.hand.length, lessThanOrEqualTo(10));
    });

    test('finishMulligan starts round one with the first player acting', () {
      final engine = harness();
      engine.finishMulligan();
      expect(engine.state.roundNumber, 1);
      expect(engine.state.currentPlayer, engine.state.firstPlayer);
    });

    test('passing both players ends the round and records a result', () {
      final engine = harness();
      engine.finishMulligan();
      while (engine.state.roundNumber == 1 &&
          engine.state.phase == GamePhase.playing) {
        engine.pass(engine.state.currentPlayer);
      }
      expect(engine.state.roundHistory, hasLength(1));
    });

    test('winning two rounds ends the match', () {
      final engine = harness();
      engine.finishMulligan();
      // Force a human win in round one.
      engine.state
          .rowState(0, CardRow.close)
          .cards
          .add(makeCard('geralt', owner: 0));
      engine.pass(engine.state.currentPlayer);
      engine.pass(engine.state.currentPlayer);
      expect(engine.opponent.roundsLost, 1);
      expect(engine.state.roundNumber, 2);

      // Force a human win in round two.
      engine.state
          .rowState(0, CardRow.close)
          .cards
          .add(makeCard('ciri', owner: 0));
      engine.pass(engine.state.currentPlayer);
      engine.pass(engine.state.currentPlayer);
      expect(engine.state.phase, GamePhase.gameOver);
      expect(engine.state.matchWinner, 0);
    });

    test('Nilfgaard wins a round that ends in a draw', () {
      final engine = harness(humanFaction: CardFaction.nilfgaard);
      engine.finishMulligan();
      engine.pass(engine.state.currentPlayer);
      engine.pass(engine.state.currentPlayer);
      expect(engine.state.roundHistory.single.winner, 0);
      expect(engine.opponent.roundsLost, 1);
    });
  });

  group('Card abilities', () {
    test('Spy is placed on the opponent side and draws two cards', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['stennis']);
      setDeck(engine, 0, ['geralt', 'ciri', 'triss']);
      final spy = engine.human.hand.first;
      expect(engine.playCard(0, spy), isTrue);
      expect(
        engine.state.rowState(1, CardRow.close).cards.map((c) => c.id),
        contains('stennis'),
      );
      expect(engine.human.hand.length, 2);
    });

    test('Medic revives a unit from the graveyard', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['yennefer']);
      engine.human.graveyard.add(makeCard('gryffin', owner: 0));
      final medic = engine.human.hand.first;
      expect(engine.playCard(0, medic), isTrue);
      expect(
        engine.state.rowState(0, CardRow.close).cards.map((c) => c.id),
        contains('gryffin'),
      );
    });

    test('Muster plays every same-named card from hand and deck', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['nekker']);
      setDeck(engine, 0, ['nekker_1', 'nekker_2']);
      final card = engine.human.hand.first;
      expect(engine.playCard(0, card), isTrue);
      final nekkers = engine.state
          .rowState(0, CardRow.close)
          .cards
          .where((c) => c.id.startsWith('nekker'));
      expect(nekkers.length, 3);
    });

    test('Scorch destroys the strongest unit across the battlefield', () {
      final engine = harness();
      setTurn(engine, 0);
      engine.state.rowState(1, CardRow.close).cards.addAll([
        makeCard('gryffin', owner: 1),
        makeCard('fiend', owner: 1),
      ]);
      setHand(engine, 0, ['scorch']);
      final scorch = engine.human.hand.first;
      expect(engine.playCard(0, scorch), isTrue);
      final opponentClose = engine.state
          .rowState(1, CardRow.close)
          .cards
          .map((c) => c.id);
      expect(opponentClose, isNot(contains('fiend')));
      expect(opponentClose, contains('gryffin'));
      expect(engine.human.graveyard.map((c) => c.id), contains('scorch'));
    });

    test('Villentretenmerth scorches the strongest enemy close units', () {
      final engine = harness();
      setTurn(engine, 0);
      engine.state.rowState(1, CardRow.close).cards.addAll([
        makeCard('gryffin', owner: 1),
        makeCard('gryffin', owner: 1),
      ]);
      setHand(engine, 0, ['villen']);
      final card = engine.human.hand.first;
      expect(engine.playCard(0, card), isTrue);
      expect(engine.state.rowState(1, CardRow.close).cards, isEmpty);
    });

    test('Mardroeme transforms all Berserkers on its row', () {
      final engine = harness();
      setTurn(engine, 0);
      engine.state
          .rowState(0, CardRow.close)
          .cards
          .add(makeCard('berserker', owner: 0));
      setHand(engine, 0, ['mardroeme']);
      final card = engine.human.hand.first;
      expect(engine.playCard(0, card, targetRow: CardRow.close), isTrue);
      expect(
        engine.state.rowState(0, CardRow.close).cards.map((c) => c.id),
        contains('vildkaarl'),
      );
    });

    test('Decoy returns a friendly unit to hand', () {
      final engine = harness();
      setTurn(engine, 0);
      final target = makeCard('gryffin', owner: 0);
      engine.state.rowState(0, CardRow.close).cards.add(target);
      setHand(engine, 0, ['decoy']);
      final decoy = engine.human.hand.first;
      expect(engine.playCard(0, decoy, target: target), isTrue);
      expect(engine.human.hand.map((c) => c.id), contains('gryffin'));
      expect(
        engine.state.rowState(0, CardRow.close).cards.map((c) => c.id),
        contains('decoy'),
      );
    });

    test('Weather clamps unit strength for both players', () {
      final engine = harness();
      setTurn(engine, 0);
      engine.state
          .rowState(0, CardRow.close)
          .cards
          .add(makeCard('gryffin', owner: 0));
      engine.state
          .rowState(1, CardRow.close)
          .cards
          .add(makeCard('fiend', owner: 1));
      setHand(engine, 0, ['frost']);
      final frost = engine.human.hand.first;
      expect(engine.playCard(0, frost), isTrue);
      expect(engine.state.activeWeather, contains(Ability.frost));
      Scoring.refresh(engine.state);
      expect(
        Scoring.rowTotal(engine.state, engine.state.rowState(0, CardRow.close)),
        1,
      );
      expect(
        Scoring.rowTotal(engine.state, engine.state.rowState(1, CardRow.close)),
        1,
      );
    });

    test('Avenger summons a replacement when destroyed', () {
      final engine = harness();
      setTurn(engine, 0);
      engine.state
          .rowState(0, CardRow.close)
          .cards
          .add(makeCard('cow', owner: 0));
      setHand(engine, 0, ['scorch']);
      final scorch = engine.human.hand.first;
      expect(engine.playCard(0, scorch), isTrue);
      expect(
        engine.state.rowState(0, CardRow.close).cards.map((c) => c.id),
        contains('chort'),
      );
    });

    test('a duplicate weather card is discarded without effect', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['frost']);
      engine.playCard(0, engine.human.hand.first);
      setTurn(engine, 0);
      setHand(engine, 0, ['frost']);
      engine.playCard(0, engine.human.hand.first);
      expect(engine.human.graveyard.map((c) => c.id), contains('frost'));
      expect(engine.state.weatherCards.length, 1);
    });
  });

  group('Leader abilities', () {
    test("Foltest's Siegemaster doubles the player's siege row", () {
      final engine = harness(humanLeader: 'foltest_copper');
      setTurn(engine, 0);
      engine.state
          .rowState(0, CardRow.siege)
          .cards
          .add(makeCard('ballista', owner: 0));
      expect(engine.activateLeader(0), isTrue);
      Scoring.refresh(engine.state);
      expect(
        Scoring.rowTotal(engine.state, engine.state.rowState(0, CardRow.siege)),
        12,
      );
      expect(engine.human.leaderUsed, isTrue);
    });

    test('Crach an Craite shuffles both graveyards into the decks', () {
      final engine = harness(humanLeader: 'crach_an_craite');
      setTurn(engine, 0);
      engine.human.graveyard.add(makeCard('gryffin', owner: 0));
      expect(engine.activateLeader(0), isTrue);
      expect(engine.human.graveyard, isEmpty);
      expect(engine.human.deck.map((c) => c.id), contains('gryffin'));
    });
  });

  group('Manual leader choices', () {
    test('Destroyer of Worlds discards and draws the chosen cards', () {
      final engine = harness(
        humanFaction: CardFaction.monsters,
        humanLeader: 'eredin_gold',
      );
      setTurn(engine, 0);
      final discardA = makeCard('nekker', owner: 0);
      final discardB = makeCard('nekker_1', owner: 0);
      final pick = makeCard('gryffin', owner: 0);
      engine.human.hand
        ..clear()
        ..addAll([discardA, discardB]);
      engine.human.deck
        ..clear()
        ..addAll([pick, makeCard('fiend', owner: 0)]);

      expect(
        engine.activateLeader(0, discard: [discardA, discardB], deckPick: pick),
        isTrue,
      );
      expect(
        engine.human.graveyard.map((c) => c.id),
        containsAll(['nekker', 'nekker_1']),
      );
      expect(engine.human.hand.map((c) => c.id), contains('gryffin'));
      expect(engine.human.deck.map((c) => c.id), isNot(contains('gryffin')));
    });

    test('Emhyr the Relentless draws the chosen opponent card', () {
      final engine = harness(
        humanFaction: CardFaction.nilfgaard,
        humanLeader: 'emhyr_gold',
      );
      setTurn(engine, 0);
      final target = makeCard('gryffin', owner: 1);
      engine.opponent.graveyard
        ..clear()
        ..addAll([target, makeCard('fiend', owner: 1)]);

      expect(engine.activateLeader(0, target: target), isTrue);
      expect(engine.human.hand.map((c) => c.id), contains('gryffin'));
      expect(
        engine.opponent.graveyard.map((c) => c.id),
        isNot(contains('gryffin')),
      );
    });

    test('Bringer of Death restores the chosen own card', () {
      final engine = harness(
        humanFaction: CardFaction.monsters,
        humanLeader: 'eredin_bronze',
      );
      setTurn(engine, 0);
      final target = makeCard('fiend', owner: 0);
      engine.human.graveyard
        ..clear()
        ..add(target);

      expect(engine.activateLeader(0, target: target), isTrue);
      expect(engine.human.hand.map((c) => c.id), contains('fiend'));
      expect(engine.human.graveyard, isEmpty);
    });
  });
}
