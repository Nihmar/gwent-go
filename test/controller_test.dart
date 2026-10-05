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

GameController buildLeaderController(String leaderId, CardFaction faction) {
  final opponent = CardRepository.defaultDecks()[1];
  final deck = DeckDefinition(
    id: 'test_leader',
    name: 'Test leader',
    faction: faction,
    leader: CardRepository.byId(leaderId),
    cardCounts: const {'gryffin': 12, 'nekker': 2},
  );
  return GameController(
    humanDeck: deck,
    opponentDeck: opponent,
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

    test('Destroyer of Worlds asks for two discards then a draw', () {
      final controller = buildLeaderController(
        'eredin_gold',
        CardFaction.monsters,
      );
      controller.start();
      controller.confirmMulligan();
      controller.state.currentPlayer = 0;

      controller.activateLeader();
      final discardChoice = controller.pendingChoice as TargetChoice;
      expect(discardChoice.kind, TargetKind.hand);
      expect(discardChoice.requiredCount, 2);

      final discards = controller.human.hand.take(2).toList();
      controller.chooseTargets(discards);
      final drawChoice = controller.pendingChoice as TargetChoice;
      expect(drawChoice.kind, TargetKind.deck);

      final pick = controller.human.deck.first;
      controller.chooseTargets([pick]);

      expect(controller.human.leaderUsed, isTrue);
      expect(
        controller.human.graveyard.map((c) => c.id),
        containsAll(discards.map((c) => c.id)),
      );
      expect(controller.human.hand.map((c) => c.id), contains(pick.id));
      controller.dispose();
    });

    test('Destroyer of Worlds accepts a single card when the hand is short', () {
      final controller = buildLeaderController(
        'eredin_gold',
        CardFaction.monsters,
      );
      controller.start();
      controller.confirmMulligan();
      controller.state.currentPlayer = 0;

      controller.human.hand
        ..clear()
        ..add(makeCard('gryffin', owner: 0));

      controller.activateLeader();
      final discardChoice = controller.pendingChoice as TargetChoice;
      expect(discardChoice.kind, TargetKind.hand);
      expect(discardChoice.requiredCount, 1);

      final discard = controller.human.hand.first;
      controller.chooseTargets([discard]);
      final drawChoice = controller.pendingChoice as TargetChoice;
      expect(drawChoice.kind, TargetKind.deck);

      controller.chooseTargets([controller.human.deck.first]);
      expect(controller.human.leaderUsed, isTrue);
      expect(controller.human.graveyard.map((c) => c.id), contains('gryffin'));
      controller.dispose();
    });

    test('Destroyer of Worlds skips the discard with an empty hand', () {
      final controller = buildLeaderController(
        'eredin_gold',
        CardFaction.monsters,
      );
      controller.start();
      controller.confirmMulligan();
      controller.state.currentPlayer = 0;

      controller.human.hand.clear();
      controller.activateLeader();

      final choice = controller.pendingChoice as TargetChoice;
      expect(choice.kind, TargetKind.deck);
      controller.dispose();
    });

    test('ability effects register a flash for affected cards', () {
      final controller = buildController();
      controller.start();
      controller.engine!.finishMulligan(0);
      controller.state.currentPlayer = 0;

      final strong = makeCard('fiend', owner: controller.opponent.index);
      final weak = makeCard('gryffin', owner: controller.opponent.index);
      controller.state
          .rowState(controller.opponent.index, CardRow.close)
          .cards
          .addAll([strong, weak]);
      controller.human.hand
        ..clear()
        ..add(makeCard('scorch', owner: 0));
      controller.selectCard(controller.human.hand.first);
      controller.playSelected();

      expect(controller.flashCounter(strong.uid), greaterThan(0));
      expect(controller.flashColorFor(strong.uid), isNotNull);
      expect(controller.flashCounter(weak.uid), 0);
      controller.dispose();
    });

    test('Emhyr the Relentless asks for an opponent graveyard card', () {
      final controller = buildLeaderController(
        'emhyr_gold',
        CardFaction.nilfgaard,
      );
      controller.start();
      controller.confirmMulligan();
      controller.state.currentPlayer = 0;

      final target = makeCard('gryffin', owner: controller.opponent.index);
      controller.opponent.graveyard
        ..clear()
        ..add(target);

      controller.activateLeader();
      final choice = controller.pendingChoice as TargetChoice;
      expect(choice.kind, TargetKind.graveyard);
      controller.chooseTargets([target]);

      expect(controller.human.leaderUsed, isTrue);
      expect(controller.human.hand.map((c) => c.id), contains('gryffin'));
      controller.dispose();
    });
  });
}
