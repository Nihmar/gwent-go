import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/rules/game_projection.dart';
import 'package:gwent_go/core/rules/scoring.dart';

import 'support/engine_harness.dart';

void main() {
  group('decodeProjection', () {
    /// A state with cards in every public zone, a weather effect and a special.
    GameState populatedEngine() {
      final engine = harness();
      setTurn(engine, 0);
      setHand(engine, 0, ['gryffin', 'fiend']);
      setHand(engine, 1, ['leshen', 'ciri']);
      setDeck(engine, 0, ['geralt']);
      setDeck(engine, 1, ['gargoyle']);
      engine.state
          .rowState(1, CardRow.close)
          .cards
          .add(makeCard('nekker', owner: 1));
      engine.state.rowState(0, CardRow.close).special = makeCard(
        'horn',
        owner: 0,
      );
      engine.state.players[0].graveyard.add(makeCard('cow', owner: 0));
      engine.state.weatherCards.add(makeCard('frost', owner: 0));
      engine.state.activeWeather.add(Ability.frost);
      Scoring.refresh(engine.state);
      return engine.state;
    }

    test('renders the public zones of the viewer seat', () {
      final source = populatedEngine();
      final view = decodeProjection(encodeProjection(source, viewer: 0));

      // Own hand is complete.
      expect(
        view.players[0].hand.map((c) => c.id),
        containsAll(['gryffin', 'fiend']),
      );
      expect(view.players[0].handSize, 2);
      // Both decks are hidden, only their size survives.
      expect(view.players[0].deck, isEmpty);
      expect(view.players[0].deckSize, 1);
      expect(view.players[1].deckSize, 1);
      // Battlefield, row special, graveyard and weather are public.
      expect(
        view.rowState(1, CardRow.close).cards.map((c) => c.id),
        contains('nekker'),
      );
      expect(view.rowState(0, CardRow.close).special?.id, 'horn');
      expect(view.players[0].graveyard.map((c) => c.id), contains('cow'));
      expect(view.weatherCards.map((c) => c.id), contains('frost'));
      expect(view.activeWeather, contains(Ability.frost));
    });

    test('hides the other hand but keeps its size', () {
      final source = populatedEngine();
      final view = decodeProjection(encodeProjection(source, viewer: 0));

      expect(view.players[1].hand, isEmpty);
      expect(view.players[1].handSize, 2);
      expect(view.players[1].hiddenHandCount, 2);
      // The viewer keeps its own real hand.
      expect(view.players[0].hiddenHandCount, isNull);
    });

    test('recomputes strengths and totals from the visible board', () {
      final source = populatedEngine();
      final view = decodeProjection(encodeProjection(source, viewer: 0));

      for (final player in source.players) {
        expect(
          Scoring.playerTotal(view, player.index),
          Scoring.playerTotal(source, player.index),
          reason: 'seat ${player.index}',
        );
      }
      // The weather clamp is derived locally too: the 2-strength unit drops to 1.
      final nekker = view.rowState(1, CardRow.close).cards.single;
      expect(nekker.definition.id, 'nekker');
      expect(nekker.currentStrength, 1);
    });

    test('carries the flow state', () {
      final source = populatedEngine();
      final view = decodeProjection(encodeProjection(source, viewer: 1));

      expect(view.roundNumber, source.roundNumber);
      expect(view.currentPlayer, source.currentPlayer);
      expect(view.firstPlayer, source.firstPlayer);
      expect(view.phase, source.phase);
      expect(view.players[0].name, source.players[0].name);
      expect(view.players[1].leader.id, source.players[1].leader.id);
    });

    test('rejects an unknown card', () {
      final payload = encodeProjection(populatedEngine(), viewer: 0);
      final cards = (payload['cards'] as List).cast<Map<String, Object?>>();
      cards.first['id'] = 'not_a_card';

      expect(() => decodeProjection(payload), throwsFormatException);
    });
  });
}
