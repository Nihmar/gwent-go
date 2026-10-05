import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/core/rules/game_engine.dart';
import 'package:gwent_go/core/rules/game_event.dart';
import 'package:gwent_go/core/rules/game_random.dart';
import 'package:gwent_go/core/rules/scoring.dart';

import 'support/engine_harness.dart';

void main() {
  group('Engine flow', () {
    test('startMatch deals ten cards and enters the mulligan phase', () {
      final decks = CardRepository.defaultDecks();
      final engine = GameEngine(
        firstDeck: decks[0],
        secondDeck: decks[1],
        difficulty: Difficulty.normal,
        random: GameRandom(11),
      );

      engine.startMatch();

      expect(engine.state.phase, GamePhase.mulligan);
      expect(engine.state.players[0].hand, hasLength(10));
      expect(engine.state.players[1].hand, hasLength(10));
    });

    test('finishMulligan starts round one with the first player acting', () {
      final engine = harness();
      engine.finishMulligan(0);
      engine.finishMulligan(1);
      expect(engine.state.roundNumber, 1);
      expect(engine.state.currentPlayer, engine.state.firstPlayer);
    });

    test('passing both players ends the round and records a result', () {
      final engine = harness();
      engine.finishMulligan(0);
      engine.finishMulligan(1);
      while (engine.state.roundNumber == 1 &&
          engine.state.phase == GamePhase.playing) {
        engine.pass(engine.state.currentPlayer);
      }
      expect(engine.state.roundHistory, hasLength(1));
    });

    test('winning two rounds ends the match', () {
      final engine = harness();
      engine.finishMulligan(0);
      engine.finishMulligan(1);
      // Force a human win in round one.
      engine.state
          .rowState(0, CardRow.close)
          .cards
          .add(makeCard('geralt', owner: 0));
      engine.pass(engine.state.currentPlayer);
      engine.pass(engine.state.currentPlayer);
      expect(engine.state.players[1].roundsLost, 1);
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
      engine.finishMulligan(0);
      engine.finishMulligan(1);
      engine.pass(engine.state.currentPlayer);
      engine.pass(engine.state.currentPlayer);
      expect(engine.state.roundHistory.single.winner, 0);
      expect(engine.state.players[1].roundsLost, 1);
    });
  });

  group('Card abilities', () {
    test('Spy is placed on the opponent side and draws two cards', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['stennis']);
      setDeck(engine, 0, ['geralt', 'ciri', 'triss']);
      final spy = engine.state.players[0].hand.first;
      expect(engine.playCard(0, spy), isTrue);
      expect(
        engine.state.rowState(1, CardRow.close).cards.map((c) => c.id),
        contains('stennis'),
      );
      expect(engine.state.players[0].hand.length, 2);
    });

    test('Medic revives a unit from the graveyard', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['yennefer']);
      engine.state.players[0].graveyard.add(makeCard('gryffin', owner: 0));
      final medic = engine.state.players[0].hand.first;
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
      final card = engine.state.players[0].hand.first;
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
      final scorch = engine.state.players[0].hand.first;
      expect(engine.playCard(0, scorch), isTrue);
      final opponentClose = engine.state
          .rowState(1, CardRow.close)
          .cards
          .map((c) => c.id);
      expect(opponentClose, isNot(contains('fiend')));
      expect(opponentClose, contains('gryffin'));
      expect(engine.state.players[0].graveyard.map((c) => c.id), contains('scorch'));
    });

    test('Villentretenmerth scorches the strongest enemy close units', () {
      final engine = harness();
      setTurn(engine, 0);
      engine.state.rowState(1, CardRow.close).cards.addAll([
        makeCard('gryffin', owner: 1),
        makeCard('gryffin', owner: 1),
      ]);
      setHand(engine, 0, ['villen']);
      final card = engine.state.players[0].hand.first;
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
      final card = engine.state.players[0].hand.first;
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
      final decoy = engine.state.players[0].hand.first;
      expect(engine.playCard(0, decoy, target: target), isTrue);
      expect(engine.state.players[0].hand.map((c) => c.id), contains('gryffin'));
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
      final frost = engine.state.players[0].hand.first;
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
      final scorch = engine.state.players[0].hand.first;
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
      engine.playCard(0, engine.state.players[0].hand.first);
      setTurn(engine, 0);
      setHand(engine, 0, ['frost']);
      engine.playCard(0, engine.state.players[0].hand.first);
      expect(engine.state.players[0].graveyard.map((c) => c.id), contains('frost'));
      expect(engine.state.weatherCards.length, 1);
    });

    test('weather de-duplicates by effect, not by card name', () {
      final engine = harness();
      // A real frost card is already active.
      setTurn(engine, 0);
      setHand(engine, 0, ['frost']);
      engine.playCard(0, engine.state.players[0].hand.first);

      // A differently named card with the same effect must be discarded.
      final renamed = CardInstance(
        uid: 1 << 21,
        definition: const CardDefinition(
          id: 'test_deep_freeze',
          name: 'Deep Freeze',
          faction: CardFaction.weather,
          row: CardRow.weather,
          baseStrength: 0,
          artFilename: 'weather_frost',
          abilities: [Ability.frost],
        ),
        owner: 0,
      );
      setTurn(engine, 0);
      engine.state.players[0].hand
        ..clear()
        ..add(renamed);

      expect(engine.playCard(0, renamed), isTrue);
      expect(
        engine.state.weatherCards.map((c) => c.id),
        isNot(contains('test_deep_freeze')),
      );
      expect(
        engine.state.players[0].graveyard.map((c) => c.id),
        contains('test_deep_freeze'),
      );
    });
  });

  group('Draw events', () {
    test('Spy reports the number of cards actually drawn', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['stennis']);
      setDeck(engine, 0, ['geralt']);
      engine.takeEvents();
      final spy = engine.state.players[0].hand.first;

      expect(engine.playCard(0, spy), isTrue);
      final draws = engine.takeEvents().whereType<CardsDrawn>().toList();
      expect(draws, hasLength(1));
      expect(draws.single.count, 1);
    });

    test('Spy does not report a draw with an empty deck', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['stennis']);
      setDeck(engine, 0, []);
      engine.takeEvents();
      final spy = engine.state.players[0].hand.first;

      expect(engine.playCard(0, spy), isTrue);
      expect(engine.takeEvents().whereType<CardsDrawn>(), isEmpty);
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
      expect(engine.state.players[0].leaderUsed, isTrue);
    });

    test('Crach an Craite shuffles both graveyards into the decks', () {
      final engine = harness(humanLeader: 'crach_an_craite');
      setTurn(engine, 0);
      engine.state.players[0].graveyard.add(makeCard('gryffin', owner: 0));
      expect(engine.activateLeader(0), isTrue);
      expect(engine.state.players[0].graveyard, isEmpty);
      expect(engine.state.players[0].deck.map((c) => c.id), contains('gryffin'));
    });

    test('Pureblood Elf plays Biting Frost from the deck', () {
      final engine = harness(
        humanFaction: CardFaction.scoiatael,
        humanLeader: 'francesca_bronze',
      );
      setTurn(engine, 0);
      setDeck(engine, 0, ['frost', 'geralt']);
      expect(engine.activateLeader(0), isTrue);
      expect(engine.state.activeWeather, contains(Ability.frost));
      expect(engine.state.weatherCards.single.id, 'frost');
      expect(engine.state.rowState(0, CardRow.close).weather, isTrue);
      expect(engine.state.players[0].leaderUsed, isTrue);
    });
  });

  group('Invader of the North', () {
    test('Medic revives a random unit, ignoring the requested target', () {
      final engine = harness(
        humanFaction: CardFaction.nilfgaard,
        humanLeader: 'emhyr_invader_of_the_north',
        random: _AlwaysFirstRandom(),
      );
      expect(engine.state.randomRespawn, isTrue);
      setTurn(engine, 0);
      setHand(engine, 0, ['banner_nurse']);
      setDeck(engine, 0, ['geralt']);
      final graveyard = engine.state.players[0].graveyard
        ..clear()
        ..add(makeCard('gryffin', owner: 0))
        ..add(makeCard('nekker', owner: 0));
      final requested = graveyard[1];
      final medic = engine.state.players[0].hand.single;

      expect(engine.playCard(0, medic, target: requested), isTrue);

      // The random pick (index 0) wins over the requested Nekker.
      expect(
        engine.state.rowState(0, CardRow.close).cards.map((c) => c.id),
        contains('gryffin'),
      );
      expect(
        engine.state.players[0].graveyard.map((c) => c.id),
        contains('nekker'),
      );
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
      engine.state.players[0].hand
        ..clear()
        ..addAll([discardA, discardB]);
      engine.state.players[0].deck
        ..clear()
        ..addAll([pick, makeCard('fiend', owner: 0)]);

      expect(
        engine.activateLeader(0, discard: [discardA, discardB], deckPick: pick),
        isTrue,
      );
      expect(
        engine.state.players[0].graveyard.map((c) => c.id),
        containsAll(['nekker', 'nekker_1']),
      );
      expect(engine.state.players[0].hand.map((c) => c.id), contains('gryffin'));
      expect(engine.state.players[0].deck.map((c) => c.id), isNot(contains('gryffin')));
    });

    test('Emhyr the Relentless draws the chosen opponent card', () {
      final engine = harness(
        humanFaction: CardFaction.nilfgaard,
        humanLeader: 'emhyr_gold',
      );
      setTurn(engine, 0);
      final target = makeCard('gryffin', owner: 1);
      engine.state.players[1].graveyard
        ..clear()
        ..addAll([target, makeCard('fiend', owner: 1)]);

      expect(engine.activateLeader(0, target: target), isTrue);
      expect(engine.state.players[0].hand.map((c) => c.id), contains('gryffin'));
      expect(
        engine.state.players[1].graveyard.map((c) => c.id),
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
      engine.state.players[0].graveyard
        ..clear()
        ..add(target);

      expect(engine.activateLeader(0, target: target), isTrue);
      expect(engine.state.players[0].hand.map((c) => c.id), contains('fiend'));
      expect(engine.state.players[0].graveyard, isEmpty);
    });
  });

  group('White Flame leader', () {
    test('cancels passive leader effects for both players', () {
      final engine = harness(
        humanFaction: CardFaction.skellige,
        humanLeader: 'king_bran',
        opponentFaction: CardFaction.nilfgaard,
        opponentLeader: 'emhyr_bronze',
      );
      expect(engine.state.players[0].leaderUsed, isTrue);
      expect(engine.state.players[1].leaderUsed, isTrue);
      // King Bran's weather protection must not apply while White Flame is in
      // play, matching the reference's disableLeader behaviour.
      expect(engine.state.rowState(0, CardRow.close).halfWeather, isFalse);
    });

    test('cancels double spy power from the Treacherous leader', () {
      final engine = harness(
        humanFaction: CardFaction.nilfgaard,
        humanLeader: 'emhyr_bronze',
        opponentFaction: CardFaction.monsters,
        opponentLeader: 'eredin_the_treacherous',
      );
      expect(engine.state.doubleSpyPower, isFalse);
    });

    test('passive leader effects still apply without White Flame', () {
      final engine = harness(
        humanFaction: CardFaction.skellige,
        humanLeader: 'king_bran',
      );
      expect(engine.state.rowState(0, CardRow.close).halfWeather, isTrue);
    });
  });

  group('Skellige faction', () {
    test('round three revives two random units, not the strongest', () {
      final engine = GameEngine(
        firstDeck: testDeck(
          faction: CardFaction.skellige,
          leaderId: 'crach_an_craite',
        ),
        secondDeck: testDeck(
          faction: CardFaction.monsters,
          leaderId: 'eredin_silver',
        ),
        difficulty: Difficulty.normal,
        // A no-op shuffle keeps the graveyard order, so the two cards that
        // come back are the first inserted and provably not the strongest.
        random: _NoShuffleRandom(),
      );
      engine.startMatch();
      engine.finishMulligan(0);
      engine.finishMulligan(1);

      engine.state.players[0].graveyard
        ..clear()
        ..addAll([
          makeCard('nekker', owner: 0),
          makeCard('gargoyle', owner: 0),
          makeCard('fiend', owner: 0),
        ]);

      // End rounds one and two so round three starts and the faction ability
      // runs.
      for (var i = 0; i < 4; i++) {
        engine.pass(engine.state.currentPlayer);
      }

      expect(engine.state.roundNumber, 3);
      final revived = [
        for (final row in engine.state.rowsFor(0)) ...row.cards.map((c) => c.id),
      ];
      expect(revived, containsAll(['nekker', 'gargoyle']));
      expect(engine.state.players[0].graveyard.map((c) => c.id), contains('fiend'));
    });
  });
}

/// [GameRandom] that never reorders a list, so seeded behaviour is predictable.
class _NoShuffleRandom extends GameRandom {
  _NoShuffleRandom() : super(1);

  @override
  void shuffle<T>(List<T> items) {}
}

/// [GameRandom] whose every draw is index 0, so random picks are predictable.
class _AlwaysFirstRandom extends GameRandom {
  _AlwaysFirstRandom() : super(1);

  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => 0;
}
