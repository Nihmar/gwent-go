import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/rules/game_projection.dart';

import 'support/engine_harness.dart';

void main() {
  group('encodeProjection', () {
    test('hides the other hands and every deck order', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['gryffin']);
      setHand(engine, 1, ['leshen']);
      setDeck(engine, 0, ['geralt']);
      setDeck(engine, 1, ['ciri']);

      final payload = jsonEncode(encodeProjection(engine.state, viewer: 0));

      expect(payload, contains('gryffin'), reason: 'own hand');
      expect(payload, isNot(contains('leshen')), reason: 'opponent hand');
      expect(payload, isNot(contains('geralt')), reason: 'own deck order');
      expect(payload, isNot(contains('ciri')), reason: 'opponent deck order');
    });

    test('reports hidden zone sizes instead', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['gryffin', 'fiend']);
      setHand(engine, 1, ['leshen']);
      setDeck(engine, 0, ['geralt']);

      final decoded = encodeProjection(engine.state, viewer: 0);
      final players = (decoded['players'] as List).cast<Map<String, dynamic>>();

      expect(players[0]['hand'], hasLength(2));
      expect(players[0]['handCount'], 2);
      expect(players[0]['deckCount'], 1);
      expect(players[1]['hand'], isNull);
      expect(players[1]['handCount'], 1);
      expect(players[1]['deckCount'], 0);
    });

    test('keeps every public zone', () {
      final engine = harness();
      setTurn(engine, 0);
      engine.state
          .rowState(0, CardRow.close)
          .cards
          .add(makeCard('fiend', owner: 0));
      engine.state.players[0].graveyard.add(makeCard('cow', owner: 0));
      engine.state.rowState(0, CardRow.close).special = makeCard(
        'horn',
        owner: 0,
      );
      engine.state.weatherCards.add(makeCard('frost', owner: 0));
      engine.state.activeWeather.add(Ability.frost);

      final payload = jsonEncode(encodeProjection(engine.state, viewer: 0));

      expect(payload, contains('fiend'));
      expect(payload, contains('cow'));
      expect(payload, contains('horn'));
      expect(payload, contains('frost'));
    });

    test('is deterministic', () {
      final engine = harness();

      final first = jsonEncode(encodeProjection(engine.state, viewer: 0));
      final second = jsonEncode(encodeProjection(engine.state, viewer: 0));

      expect(first, second);
    });

    test('mirrors the hidden zones for the other seat', () {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['gryffin']);
      setHand(engine, 1, ['leshen']);

      final forZero = jsonEncode(encodeProjection(engine.state, viewer: 0));
      final forOne = jsonEncode(encodeProjection(engine.state, viewer: 1));

      expect(forZero, contains('gryffin'));
      expect(forZero, isNot(contains('leshen')));
      expect(forOne, contains('leshen'));
      expect(forOne, isNot(contains('gryffin')));
    });
  });
}
