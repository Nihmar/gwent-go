import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/presentation/controllers/game_controller.dart';

import 'support/engine_harness.dart';

GameController buildController() {
  final decks = CardRepository.defaultDecks();
  return GameController(
    humanDeck: decks[0],
    opponentDeck: decks[1],
    difficulty: Difficulty.normal,
    seed: 3,
  );
}

void main() {
  group('GameController', () {
    test('starts in the mulligan phase with a full hand', () {
      final controller = buildController();
      controller.start();
      expect(controller.isMulligan, isTrue);
      expect(controller.human.hand.length, 10);
      controller.dispose();
    });

    test('confirming the mulligan starts the first round', () {
      final controller = buildController();
      controller.start();
      controller.confirmMulligan();
      expect(controller.state.phase, GamePhase.playing);
      expect(controller.state.roundNumber, 1);
      controller.dispose();
    });

    test('an agile card asks for a row before it is played', () {
      final controller = buildController();
      controller.start();
      controller.confirmMulligan();
      controller.state.currentPlayer = 0;

      controller.human.hand
        ..clear()
        ..add(makeCard('celaeno_harpy', owner: 0));
      final card = controller.human.hand.first;
      controller.selectCard(card);
      controller.playSelected();
      expect(controller.pendingChoice, isA<RowChoice>());
      expect(controller.human.hand, contains(card));

      controller.playSelected(row: CardRow.close);
      expect(
        controller.state.rowState(0, CardRow.close).cards.map((c) => c.id),
        contains('celaeno_harpy'),
      );
      controller.dispose();
    });

    test('decoy asks for a target before it is played', () {
      final controller = buildController();
      controller.start();
      controller.confirmMulligan();
      controller.state.currentPlayer = 0;

      final target = makeCard('gryffin', owner: 0);
      controller.state.rowState(0, CardRow.close).cards.add(target);
      controller.human.hand
        ..clear()
        ..add(makeCard('decoy', owner: 0));
      controller.selectCard(controller.human.hand.first);
      controller.playSelected();
      expect(controller.pendingChoice, isA<TargetChoice>());
      controller.dispose();
    });
  });
}
