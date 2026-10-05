import 'package:flutter_test/flutter_test.dart';
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
}
