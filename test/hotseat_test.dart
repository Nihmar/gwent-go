import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/core/rules/game_engine.dart';
import 'package:gwent_go/presentation/controllers/game_controller.dart';
import 'package:gwent_go/presentation/screens/game_screen.dart';
import 'package:gwent_go/presentation/widgets/game/game_overlays.dart';
import 'package:gwent_go/presentation/widgets/gwent_card.dart';

void main() {
  final decks = CardRepository.defaultDecks();

  GameController hotseatController() => GameController(
    humanDeck: decks[0],
    opponentDeck: decks[1],
    difficulty: Difficulty.normal,
    hotseat: true,
    seed: 3,
  );

  group('Hotseat controller', () {
    test('both seats are human and no AI is created', () {
      final controller = hotseatController();
      controller.start();

      expect(controller.human.isHuman, isTrue);
      expect(controller.opponent.isHuman, isTrue);
      controller.dispose();
    });

    test('the device changes hands for the second mulligan', () {
      final controller = hotseatController();
      controller.start();

      // Seat 0 builds its hand first.
      expect(controller.localSeat, 0);
      expect(controller.isMulligan, isTrue);
      expect(controller.pendingSeat, isNull);

      controller.confirmMulligan();

      // The other seat still has to confirm, so the board stays hidden.
      expect(controller.state.phase, GamePhase.mulligan);
      expect(controller.pendingSeat, 1);
      expect(controller.localSeat, 0);

      controller.confirmSeatSwitch();
      expect(controller.localSeat, 1);
      expect(controller.opponent.hand.length, GameEngine.openingHandSize);

      controller.confirmMulligan();
      expect(controller.state.phase, GamePhase.playing);

      // Whoever starts, the device must be showing that seat.
      while (controller.pendingSeat != null) {
        controller.confirmSeatSwitch();
      }
      expect(controller.localSeat, controller.state.currentPlayer);
      controller.dispose();
    });

    test('passing hands the device to the other seat', () {
      final controller = hotseatController();
      controller.start();
      controller.confirmMulligan();
      controller.confirmSeatSwitch();
      controller.confirmMulligan();
      while (controller.pendingSeat != null) {
        controller.confirmSeatSwitch();
      }

      controller.pass();

      expect(controller.state.currentPlayer, isNot(controller.localSeat));
      expect(controller.pendingSeat, controller.state.currentPlayer);
      controller.confirmSeatSwitch();
      expect(controller.localSeat, controller.state.currentPlayer);
      controller.dispose();
    });
  });

  group('Hotseat screen', () {
    testWidgets('the hand-over hides the board and the next hand', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        GwentApp(
          home: GameScreen(
            humanDeck: decks[0],
            opponentDeck: decks[1],
            difficulty: Difficulty.normal,
            hotseat: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Seat 0 redraws first.
      expect(find.byType(MulliganOverlay), findsOneWidget);
      await tester.tap(find.text('Keep hand'));
      await tester.pumpAndSettle();

      // Nothing but the hand-over is on screen.
      expect(find.byType(PassDeviceOverlay), findsOneWidget);
      expect(find.byType(MulliganOverlay), findsNothing);
      expect(find.byType(GwentCard), findsNothing);

      await tester.tap(find.text("I'm ready"));
      await tester.pumpAndSettle();

      expect(find.byType(PassDeviceOverlay), findsNothing);
      expect(find.byType(MulliganOverlay), findsOneWidget);
      expect(find.byType(GwentCard), findsWidgets);
    });
  });
}
