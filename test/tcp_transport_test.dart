
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/rules/game_command.dart';
import 'package:gwent_go/core/session/client_session.dart';
import 'package:gwent_go/core/session/host_session.dart';
import 'package:gwent_go/platform/tcp_match_transport.dart';

Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('TcpMatchTransport', () {
    test('carries messages both ways over loopback', () async {
      final server = await TcpMatchTransport.listen(port: 0);
      final connecting = TcpMatchTransport.connect(
        '127.0.0.1',
        port: server.port,
      );
      final host = await TcpMatchTransport.accept(server);
      final guest = await connecting;

      final fromGuest = host.incoming.first;
      final fromHost = guest.incoming.first;

      guest.send(const {'type': 'ping', 'value': 1});
      host.send(const {'type': 'pong', 'value': 2});

      expect(await fromGuest, {'type': 'ping', 'value': 1});
      expect(await fromHost, {'type': 'pong', 'value': 2});

      await guest.close();
      await host.close();
    });

    test('runs a session handshake over a real socket', () async {
      final server = await TcpMatchTransport.listen(port: 0);
      final connecting = TcpMatchTransport.connect(
        '127.0.0.1',
        port: server.port,
      );
      final hostSide = await TcpMatchTransport.accept(server);
      final guestSide = await connecting;

      final decks = CardRepository.defaultDecks();
      final host = HostSession(
        transport: hostSide,
        hostSeat: 0,
        hostDeck: decks[0],
        randomSeed: 5,
      );
      final guest = ClientSession(transport: guestSide, deck: decks[1]);

      guest.connect();
      await settle();

      expect(host.isReady, isTrue);
      expect(guest.seat, 1);
      expect(guest.view, isNotNull);

      // A command travels to the host and comes back as a new view.
      host.submit(const FinishMulliganCommand(0));
      guest.submit(const FinishMulliganCommand(1));
      await settle();

      expect(host.engine!.state.phase.name, 'playing');
      expect(guest.view!['phase'], 'playing');

      await guest.close();
      await host.close();
    });

    test('a closed peer completes the incoming stream', () async {
      final server = await TcpMatchTransport.listen(port: 0);
      final connecting = TcpMatchTransport.connect(
        '127.0.0.1',
        port: server.port,
      );
      final host = await TcpMatchTransport.accept(server);
      final guest = await connecting;

      final done = host.incoming.drain<void>();
      await guest.close();
      await done.timeout(const Duration(seconds: 2));

      await host.close();
    });
  });
}
