import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/rules/game_command.dart';
import 'package:gwent_go/core/session/client_session.dart';
import 'package:gwent_go/core/session/command_codec.dart';
import 'package:gwent_go/core/session/host_session.dart';
import 'package:gwent_go/core/session/match_transport.dart';
import 'package:gwent_go/core/session/session_event.dart';

/// Lets the in-memory transport deliver its queued messages.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  final decks = CardRepository.defaultDecks();

  late MatchTransport hostSide;
  late MatchTransport guestSide;
  late HostSession host;
  late ClientSession guest;

  setUp(() {
    final pair = loopbackTransportPair();
    hostSide = pair.$1;
    guestSide = pair.$2;
    host = HostSession(
      transport: hostSide,
      hostSeat: 0,
      hostDeck: decks[0],
      opponentName: 'Guest',
      randomSeed: 5,
    );
    guest = ClientSession(transport: guestSide, deck: decks[1], name: 'Guest');
  });

  tearDown(() async {
    await host.close();
    await guest.close();
  });

  Future<void> join() async {
    guest.connect();
    await settle();
  }

  test('a guest joins and receives a redacted view', () async {
    await join();

    expect(guest.seat, 1);
    expect(host.guestSeat, 1);
    expect(host.isReady, isTrue);

    final view = guest.view!;
    final players = (view['players'] as List).cast<Map<String, Object?>>();
    // The host's hand is hidden, its size is not.
    expect(players[0]['hand'], isNull);
    expect(players[0]['handCount'], greaterThan(0));
    // The guest sees its own hand.
    expect(players[1]['hand'], isA<List<Object?>>());
    expect(players[1]['hand'], isNotEmpty);
  });

  test('both seats can play a match to the end through the session', () async {
    await join();
    final engine = host.engine!;

    host.submit(const FinishMulliganCommand(0));
    guest.submit(const FinishMulliganCommand(1));
    await settle();
    expect(engine.state.phase, GamePhase.playing);

    final playedThisRound = <int>{};
    var guard = 0;
    while (!engine.state.isOver && guard++ < 60) {
      final state = engine.state;
      if (state.phase != GamePhase.playing) break;
      final current = state.currentPlayer;
      if (current == 0) {
        final hand = state.players[0].hand;
        if (!playedThisRound.contains(state.roundNumber) && hand.isNotEmpty) {
          playedThisRound.add(state.roundNumber);
          final card = hand.first;
          final result = host.submit(
            PlayCardCommand(
              player: 0,
              cardUid: card.uid,
              targetRow: card.row == CardRow.agile ? CardRow.close : null,
            ),
          );
          if (result is CommandRejected) host.submit(const PassCommand(0));
        } else {
          host.submit(const PassCommand(0));
        }
      } else {
        guest.submit(const PassCommand(1));
      }
      await settle();
    }

    expect(guard, lessThan(60), reason: 'the match did not finish');
    expect(engine.state.isOver, isTrue);
    expect(engine.state.matchWinner, 0);
    expect(guest.view!['phase'], GamePhase.gameOver.name);
    expect(guest.view!['matchWinner'], 0);
  });

  test('the host refuses commands for the wrong seat', () async {
    await join();
    final rejections = <SessionEvent>[];
    guest.events.listen(rejections.add);

    // Bypass ClientSession's guard to act as a misbehaving peer.
    guestSide.send({
      'type': SessionMessage.command,
      'seq': 1,
      'command': CommandCodec.encode(const PassCommand(0)),
    });
    await settle();

    final rejected = rejections.whereType<SessionCommandRejected>().single;
    expect(rejected.reason, CommandRejection.notYourTurn);
  });

  test('a repeated sequence number is ignored', () async {
    await join();
    final engine = host.engine!;
    host.submit(const FinishMulliganCommand(0));
    guest.submit(const FinishMulliganCommand(1));
    await settle();

    final message = {
      'type': SessionMessage.command,
      'seq': 1,
      'command': CommandCodec.encode(const FinishMulliganCommand(1)),
    };
    guestSide.send(message);
    await settle();
    guestSide.send(message);
    await settle();

    // The second delivery must not change anything.
    expect(engine.state.roundNumber, 1);
    expect(engine.state.players[1].mulliganDone, isTrue);
  });

  test('a peer with mismatched versions is rejected', () async {
    final pair = loopbackTransportPair();
    final host = HostSession(
      transport: pair.$1,
      hostSeat: 0,
      hostDeck: decks[0],
    );
    final events = <SessionEvent>[];
    host.events.listen(events.add);

    pair.$2.send({
      'type': SessionMessage.hello,
      'protocol': 999,
      'catalog': 'stale',
    });
    await settle();

    expect(
      events.whereType<SessionFailed>().single.code,
      SessionFailure.versions,
    );
    expect(host.isReady, isFalse);
    await host.close();
  });
}
