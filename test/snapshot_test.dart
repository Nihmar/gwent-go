import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/rules/game_engine.dart';
import 'package:gwent_go/core/rules/scoring.dart';

import 'support/engine_harness.dart';

List<String> ids(Iterable<CardInstance> cards) =>
    cards.map((c) => c.id).toList();

void expectSameBoard(GameEngine a, GameEngine b) {
  expect(b.state.roundNumber, a.state.roundNumber);
  expect(b.state.currentPlayer, a.state.currentPlayer);
  expect(b.state.firstPlayer, a.state.firstPlayer);
  expect(b.state.phase, a.state.phase);
  expect(b.state.matchWinner, a.state.matchWinner);

  for (var i = 0; i < a.state.players.length; i++) {
    final pa = a.state.players[i];
    final pb = b.state.players[i];
    expect(ids(pb.hand), ids(pa.hand), reason: 'hand $i');
    expect(ids(pb.deck), ids(pa.deck), reason: 'deck $i');
    expect(ids(pb.graveyard), ids(pa.graveyard), reason: 'graveyard $i');
    expect(pb.roundsLost, pa.roundsLost);
    expect(pb.passed, pa.passed);
    expect(pb.leaderUsed, pa.leaderUsed);
    expect(Scoring.playerTotal(b.state, i), Scoring.playerTotal(a.state, i));
  }

  for (final row in CardRow.values.where((r) => r.isCombat)) {
    for (var owner = 0; owner < 2; owner++) {
      final ra = a.state.rowState(owner, row);
      final rb = b.state.rowState(owner, row);
      expect(ids(rb.cards), ids(ra.cards), reason: '$owner/$row');
      expect(rb.special?.id, ra.special?.id);
      expect(rb.weather, ra.weather);
      expect(rb.halfWeather, ra.halfWeather);
    }
  }
  expect(ids(b.state.weatherCards), ids(a.state.weatherCards));
  expect(b.state.activeWeather, a.state.activeWeather);
}

void main() {
  group('Match snapshot', () {
    test('round-trips an in-progress match through JSON', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['stennis', 'geralt', 'gryffin']);
      setDeck(engine, 0, ['ciri', 'triss', 'villen']);
      engine.playCard(
        0,
        engine.state.players[0].hand.firstWhere((c) => c.id == 'stennis'),
      );

      setTurn(engine, 0);
      engine.state
          .rowState(0, CardRow.close)
          .cards
          .add(makeCard('gryffin', owner: 0));
      final frost = makeCard('frost', owner: 0);
      engine.state.players[0].hand.add(frost);
      engine.playCard(0, frost);

      final encoded = jsonEncode(engine.toJson());
      final restored = GameEngine.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expectSameBoard(engine, restored);
    });

    test('keeps instance flags such as noRemove and temporary', () {
      final engine = harness();
      final survivor = makeCard('gryffin', owner: 0);
      survivor.noRemove = true;
      engine.state.rowState(0, CardRow.close).cards.add(survivor);
      final horn = makeCard('horn', owner: 0)..temporary = true;
      engine.state.rowState(0, CardRow.siege).special = horn;

      final restored = GameEngine.fromJson(engine.toJson());
      expect(
        restored.state.rowState(0, CardRow.close).cards.single.noRemove,
        isTrue,
      );
      expect(
        restored.state.rowState(0, CardRow.siege).special?.temporary,
        isTrue,
      );
    });

    test('a restored match can continue playing', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['gryffin', 'fiend']);
      final restored = GameEngine.fromJson(engine.toJson());
      setTurn(restored, 0);
      final card = restored.state.players[0].hand.first;
      expect(restored.playCard(0, card), isTrue);
      expect(
        restored.state.rowState(0, CardRow.close).cards.map((c) => c.id),
        contains(card.id),
      );
    });
  });
}
