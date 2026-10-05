import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/core/rules/game_command.dart';
import 'package:gwent_go/core/session/client_session.dart';
import 'package:gwent_go/core/session/host_session.dart';
import 'package:gwent_go/core/session/match_transport.dart';
import 'package:gwent_go/presentation/controllers/game_controller.dart';
import 'package:gwent_go/presentation/screens/game_screen.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  final decks = CardRepository.defaultDecks();

  group('session controllers', () {
    test('the host controller uses the session engine and drives no AI', () async {
      final pair = loopbackTransportPair();
      final host = HostSession(
        transport: pair.$1,
        hostSeat: 0,
        hostDeck: decks[0],
        randomSeed: 5,
      );
      final guest = ClientSession(transport: pair.$2, deck: decks[1]);
      guest.connect();
      await settle();

      final controller = GameController.host(host);
      expect(controller.engine, isNotNull);
      expect(controller.localSeat, 0);
      expect(controller.human.isHuman, isTrue);
      expect(controller.isAiThinking, isFalse);

      // Let the guest finish its hand so the round can start, then pass from
      // the host: the guest seat must stay untouched (no AI plays it).
      controller.confirmMulligan();
      guest.submit(const FinishMulliganCommand(1));
      await settle();
      expect(controller.state.phase.name, 'playing');

      final handsBefore = controller.opponent.hand.length;
      if (controller.isLocalTurn) controller.pass();
      await settle();
      expect(controller.opponent.hand.length, handsBefore);

      controller.dispose();
      await host.close();
      await guest.close();
    });

    test('building a host controller before the match starts throws', () {
      final pair = loopbackTransportPair();
      final host = HostSession(
        transport: pair.$1,
        hostSeat: 0,
        hostDeck: decks[0],
      );
      expect(() => GameController.host(host), throwsStateError);
      host.close();
    });
  });

  testWidgets('GameScreen renders an injected controller', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    final controller = GameController(
      humanDeck: decks[0],
      opponentDeck: decks[1],
      difficulty: Difficulty.normal,
      seed: 3,
    );
    controller.start();

    await tester.pumpWidget(GwentApp(home: GameScreen(controller: controller)));
    await tester.pumpAndSettle();

    // The injected controller is already in the mulligan, so the overlay shows
    // without the screen calling start() again.
    expect(find.text('Keep hand'), findsOneWidget);

    // The screen owns an injected controller and disposes it when unmounted.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
