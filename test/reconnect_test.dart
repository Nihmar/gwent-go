import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/presentation/controllers/game_controller.dart';
import 'package:gwent_go/presentation/screens/game_screen.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/rules/game_command.dart';
import 'package:gwent_go/core/session/client_session.dart';
import 'package:gwent_go/core/session/host_session.dart';
import 'package:gwent_go/core/session/match_transport.dart';
import 'package:gwent_go/core/session/session_event.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  final decks = CardRepository.defaultDecks();

  test('the host survives a disconnect and catches the guest up', () async {
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

    host.submit(const FinishMulliganCommand(0));
    guest.submit(const FinishMulliganCommand(1));
    await settle();
    expect(host.engine!.state.phase, GamePhase.playing);

    final hostEvents = <SessionEvent>[];
    host.events.listen(hostEvents.add);

    // The guest drops: the match must not end.
    await guest.close();
    await settle();
    expect(hostEvents.whereType<SessionPeerLost>(), isNotEmpty);
    expect(host.engine!.state.phase, GamePhase.playing);

    // A new link carries the returning guest.
    final fresh = loopbackTransportPair();
    await host.rebind(fresh.$1);
    final returning = ClientSession(transport: fresh.$2, deck: decks[1]);
    final views = <Map<String, Object?>>[];
    returning.events.listen((event) {
      if (event is SessionViewUpdated) views.add(event.view);
    });
    returning.connect();
    for (var i = 0; i < 40 && views.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(returning.seat, 1);
    expect(views, isNotEmpty, reason: 'the host resyncs on hello');
    expect(views.last['phase'], GamePhase.playing.name);

    await returning.close();
    await host.close();
  });

  testWidgets('the board waits for a returning guest, then gives up', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    // The sessions talk over real streams, so they are built inside the real
    // async zone rather than the widget tester's fake clock.
    late HostSession host;
    late ClientSession guest;
    await tester.runAsync(() async {
      final pair = loopbackTransportPair();
      host = HostSession(
        transport: pair.$1,
        hostSeat: 0,
        hostDeck: decks[0],
        randomSeed: 5,
      );
      guest = ClientSession(transport: pair.$2, deck: decks[1]);
      guest.connect();
      for (var i = 0; i < 100 && host.engine == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      host.submit(const FinishMulliganCommand(0));
      guest.submit(const FinishMulliganCommand(1));
      for (var i = 0;
          i < 100 && host.engine!.state.phase != GamePhase.playing;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(host.engine!.state.phase, GamePhase.playing);
    });

    var reconnects = 0;
    await tester.pumpWidget(
      GwentApp(
        home: GameScreen(
          controller: GameController.host(host),
          disconnectGrace: const Duration(milliseconds: 50),
          onReconnect: () async {
            reconnects++;
            return false;
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Opponent disconnected'), findsNothing);

    // The guest drops mid-match: the host says so instead of freezing.
    await tester.runAsync(() => guest.close());
    await tester.pump();
    await tester.pump();
    expect(find.text('Opponent disconnected'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);

    // A failed attempt leaves the match open with a hint.
    await tester.tap(find.text('Reconnect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(reconnects, 1);
    expect(find.textContaining('Could not reach the host'), findsOneWidget);

    // Nobody came back in time: the match is abandoned.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Opponent lost'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => host.close());
  }, timeout: const Timeout(Duration(seconds: 30)));
}
