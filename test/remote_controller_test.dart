import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/rules/game_command.dart';
import 'package:gwent_go/core/rules/scoring.dart';
import 'package:gwent_go/core/session/client_session.dart';
import 'package:gwent_go/core/session/host_session.dart';
import 'package:gwent_go/core/session/match_transport.dart';
import 'package:gwent_go/presentation/controllers/game_controller.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  final decks = CardRepository.defaultDecks();

  late HostSession host;
  late ClientSession guest;
  late GameController remote;

  setUp(() async {
    final pair = loopbackTransportPair();
    host = HostSession(
      transport: pair.$1,
      hostSeat: 0,
      hostDeck: decks[0],
      opponentName: 'Guest',
      randomSeed: 5,
    );
    guest = ClientSession(transport: pair.$2, deck: decks[1]);
    guest.connect();
    await settle();
    remote = GameController.remote(session: guest, localSeat: 1);
  });

  tearDown(() async {
    remote.dispose();
    await host.close();
    await guest.close();
  });

  test('renders the host state without seeing its hidden cards', () async {
    host.submit(const FinishMulliganCommand(0));
    guest.submit(const FinishMulliganCommand(1));
    await settle();

    final hostState = host.engine!.state;
    expect(remote.state.phase, hostState.phase);
    expect(remote.state.roundNumber, hostState.roundNumber);
    expect(remote.localSeat, 1);
    expect(remote.human.isHuman, isTrue);

    // Public totals match; the host's hand is hidden but sized.
    for (final player in hostState.players) {
      expect(
        Scoring.playerTotal(remote.state, player.index),
        Scoring.playerTotal(hostState, player.index),
      );
    }
    expect(remote.state.players[0].hand, isEmpty);
    expect(remote.state.players[0].handSize, hostState.players[0].hand.length);
    expect(remote.state.players[1].handSize, hostState.players[1].hand.length);
    expect(remote.opponent.hiddenHandCount, isNotNull);
  });

  test('forwards its commands to the host and reflects the answer', () async {
    host.submit(const FinishMulliganCommand(0));
    guest.submit(const FinishMulliganCommand(1));
    await settle();

    // Let the turn reach the guest.
    var guard = 0;
    while (host.engine!.state.currentPlayer != 1 &&
        !host.engine!.state.isOver &&
        guard++ < 10) {
      host.submit(PassCommand(host.engine!.state.currentPlayer));
      await settle();
    }

    expect(remote.isLocalTurn, isTrue);
    final card = remote.human.hand.first;
    expect(remote.canPlayCard(card), isTrue);

    remote.pass();
    await settle();

    expect(host.engine!.state.players[1].passed, isTrue);
    expect(remote.state.players[1].passed, isTrue);
  });

  test('a remote controller has no engine and cannot be snapshotted', () {
    expect(remote.engine, isNull);
    expect(remote.snapshot(), isNull);
  });
}
