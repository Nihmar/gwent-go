import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/session/client_session.dart';
import 'package:gwent_go/presentation/controllers/game_controller.dart';
import 'package:gwent_go/presentation/controllers/lobby_controller.dart';
import 'package:gwent_go/platform/tcp_match_transport.dart';

/// A port that was free a moment ago.
Future<int> freeTcpPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<int> freeUdpPort() async {
  final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  socket.close();
  return port;
}

Future<void> until(bool Function() condition, {int tries = 100}) async {
  for (var i = 0; i < tries; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('condition not met in time');
}

void main() {
  final decks = CardRepository.defaultDecks();

  test('hosting advertises and becomes ready when a guest connects', () async {
    final port = await freeTcpPort();
    final lobby = LobbyController(
      name: 'Host',
      matchPort: port,
      discoveryPort: await freeUdpPort(),
      connectTimeout: const Duration(seconds: 5),
    );
    final hosting = lobby.hostMatch(decks[0]);
    await until(() => lobby.status == LobbyStatus.waitingForGuest);
    expect(lobby.isReady, isFalse);

    final guestSide = await TcpMatchTransport.connect('127.0.0.1', port: port);
    final guest = ClientSession(transport: guestSide, deck: decks[1]);
    guest.connect();
    await hosting;

    expect(lobby.status, LobbyStatus.ready);
    expect(lobby.hostSession, isNotNull);

    await lobby.cancel();
    expect(lobby.status, LobbyStatus.idle);
    await guest.close();
    lobby.dispose();
  });

  test('a guest browses, joins and gets its seat', () async {
    final port = await freeTcpPort();
    final discovery = await freeUdpPort();
    final hostLobby = LobbyController(
      name: 'Host',
      matchPort: port,
      discoveryPort: discovery,
      discoveryTarget: '127.0.0.1',
    );
    final guestLobby = LobbyController(
      name: 'Guest',
      matchPort: port,
      discoveryPort: discovery,
      discoveryTarget: '127.0.0.1',
    );

    final hosting = hostLobby.hostMatch(decks[0]);
    await guestLobby.browse();
    await until(() => guestLobby.hosts.isNotEmpty);
    expect(guestLobby.hosts.first.name, 'Host');
    await guestLobby.joinMatch(guestLobby.hosts.first, decks[1]);
    await hosting;

    expect(guestLobby.status, LobbyStatus.ready);
    expect(guestLobby.clientSession!.seat, 1);
    // The lobby must not report ready before the host's first projection, or
    // the game controller would be built without a state to render.
    expect(guestLobby.clientSession!.view, isNotNull);
    expect(hostLobby.status, LobbyStatus.ready);

    // The controller the lobby hands to the board must be buildable as-is.
    final controller = GameController.remote(
      session: guestLobby.clientSession!,
      localSeat: 1,
    );
    expect(controller.state.players, hasLength(2));
    controller.dispose();

    await guestLobby.cancel();
    await hostLobby.cancel();
    guestLobby.dispose();
    hostLobby.dispose();
  });

  test('hosting times out without a guest', () async {
    final lobby = LobbyController(
      name: 'Host',
      matchPort: await freeTcpPort(),
      discoveryPort: await freeUdpPort(),
      connectTimeout: const Duration(milliseconds: 60),
    );
    await lobby.hostMatch(decks[0]);

    expect(lobby.status, LobbyStatus.failed);
    expect(lobby.failure, 'timeout');

    await lobby.cancel();
    lobby.dispose();
  });
}
