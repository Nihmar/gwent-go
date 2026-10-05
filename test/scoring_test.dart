import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/core/rules/scoring.dart';

import 'support/engine_harness.dart';

GameState blankState({
  CardFaction human = CardFaction.realms,
  CardFaction opponent = CardFaction.monsters,
}) => GameState(
  players: [
    PlayerState(
      index: 0,
      name: 'You',
      faction: human,
      leader: CardRepository.byId('foltest_gold'),
      isHuman: true,
      difficulty: Difficulty.normal,
      deckDefinition: testDeck(faction: human, leaderId: 'foltest_gold'),
    ),
    PlayerState(
      index: 1,
      name: 'Opponent',
      faction: opponent,
      leader: CardRepository.byId('eredin_silver'),
      isHuman: false,
      difficulty: Difficulty.normal,
      deckDefinition: testDeck(faction: opponent, leaderId: 'eredin_silver'),
    ),
  ],
  roundNumber: 1,
  currentPlayer: 0,
  firstPlayer: 0,
);

void main() {
  group('Scoring', () {
    test('sums base strength of plain units', () {
      final state = blankState();
      final row = state.rowState(0, CardRow.close);
      row.cards.addAll([makeCard('gryffin'), makeCard('gryffin')]);
      expect(Scoring.rowTotal(state, row), 10);
    });

    test('Tight Bond multiplies by the number of same-named bonded cards', () {
      final state = blankState();
      final row = state.rowState(0, CardRow.close);
      row.cards.addAll([
        makeCard('blue_stripes'),
        makeCard('blue_stripes'),
        makeCard('blue_stripes'),
      ]);
      // 4 strength, bond x3 each.
      expect(Scoring.rowTotal(state, row), 36);
    });

    test('Morale adds +1 per other Morale card', () {
      final state = blankState();
      final row = state.rowState(0, CardRow.siege);
      row.cards.addAll([makeCard('kaedwen_siege'), makeCard('ballista')]);
      // Ballista 6 + 1 morale, Kaedweni 1.
      expect(Scoring.rowTotal(state, row), 8);
    });

    test("Commander's Horn doubles the row except the horn unit itself", () {
      final state = blankState();
      final row = state.rowState(0, CardRow.close);
      row.cards.addAll([makeCard('dandelion'), makeCard('gryffin')]);
      // Griffin 5 x2, Dandelion 2 (no self doubling).
      expect(Scoring.rowTotal(state, row), 12);
    });

    test('a special Commander\'s Horn doubles every unit in the row', () {
      final state = blankState();
      final row = state.rowState(0, CardRow.close);
      row.cards.add(makeCard('gryffin'));
      row.special = makeCard('horn');
      expect(Scoring.rowTotal(state, row), 10);
    });

    test('Biting Frost clamps non-hero close units to 1', () {
      final state = blankState();
      state.activeWeather.add(Ability.frost);
      final row = state.rowState(0, CardRow.close);
      row.cards.addAll([makeCard('gryffin'), makeCard('geralt')]);
      Scoring.refresh(state);
      // Griffin 5 -> 1, Geralt hero stays 15.
      expect(Scoring.rowTotal(state, row), 16);
    });

    test('King Bran keeps half strength in weather', () {
      final state = blankState();
      state.activeWeather.add(Ability.frost);
      final row = state.rowState(0, CardRow.close);
      row.halfWeather = true;
      row.cards.add(makeCard('gryffin'));
      Scoring.refresh(state);
      expect(Scoring.rowTotal(state, row), 3);
    });

    test('Decoy is always worth zero', () {
      final state = blankState();
      final row = state.rowState(0, CardRow.close);
      row.cards.add(makeCard('decoy'));
      expect(Scoring.rowTotal(state, row), 0);
    });

    test('Decoy is worth zero by ability, not by card name', () {
      final state = blankState();
      final row = state.rowState(0, CardRow.close);
      row.cards.add(
        CardInstance(
          uid: 1,
          definition: const CardDefinition(
            id: 'test_decoy',
            name: 'Impostor',
            faction: CardFaction.special,
            row: CardRow.special,
            baseStrength: 7,
            artFilename: 'decoy',
            abilities: [Ability.decoy],
          ),
          owner: 0,
        ),
      );
      expect(Scoring.rowTotal(state, row), 0);
    });

    test("Eredin the Treacherous doubles spy strength", () {
      final state = blankState();
      state.doubleSpyPower = true;
      final row = state.rowState(1, CardRow.close);
      row.cards.add(makeCard('stennis', owner: 1));
      // Prince Stennis is a 5 strength spy.
      expect(Scoring.rowTotal(state, row), 10);
    });

    test('player total aggregates all rows', () {
      final state = blankState();
      state.rowState(0, CardRow.close).cards.add(makeCard('gryffin'));
      state.rowState(0, CardRow.ranged).cards.add(makeCard('gryffin'));
      expect(Scoring.playerTotal(state, 0), 10);
      expect(Scoring.playerTotal(state, 1), 0);
    });
  });
}
