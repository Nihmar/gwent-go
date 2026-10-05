import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/player.dart';
import '../../core/session/client_session.dart';
import '../../core/session/host_session.dart';
import '../../core/session/match_transport.dart';
import '../../core/session/session_event.dart';
import '../../platform/lan_discovery.dart';
import '../../platform/tcp_match_transport.dart';

/// What this device is doing in the lobby.
enum LobbyRole { idle, hosting, joining }

/// Lifecycle of a lobby, surfaced by the UI.
enum LobbyStatus {
  /// Nothing started yet.
  idle,

  /// Hosting, announcing and waiting for a guest.
  waitingForGuest,

  /// Searching the LAN for hosts.
  browsing,

  /// Dialling a host.
  connecting,

  /// A transport is connected and the session is running.
  ready,

  /// Something failed; see [LobbyController.failure].
  failed,
}

/// Coordinates discovery, the TCP transport and the sessions for a LAN match.
///
/// The UI only starts [hostMatch] or [joinMatch] and reacts to [status]. All the
/// network details stay here, so the same coordinator can drive a different
/// [MatchTransport] later (for example Wi-Fi Direct).
class LobbyController extends ChangeNotifier {
  LobbyController({
    this.name = 'Host',
    this.matchPort = TcpMatchTransport.defaultPort,
    this.discoveryPort = LanAnnouncer.defaultPort,
    this.discoveryTarget = '255.255.255.255',
    this.connectTimeout = const Duration(seconds: 10),
  });

  final String name;
  final int matchPort;
  final int discoveryPort;

  /// Where announcements are sent; tests point it at loopback.
  final String discoveryTarget;

  final Duration connectTimeout;

  LobbyRole _role = LobbyRole.idle;
  LobbyStatus _status = LobbyStatus.idle;
  List<DiscoveredHost> _hosts = const [];
  String? _failure;

  LanAnnouncer? _announcer;
  LanBrowser? _browser;
  StreamSubscription<DiscoveredHost>? _browserSubscription;
  MatchTransport? _transport;
  HostSession? _hostSession;
  ClientSession? _clientSession;
  bool _disposed = false;

  LobbyRole get role => _role;
  LobbyStatus get status => _status;
  List<DiscoveredHost> get hosts => _hosts;
  String? get failure => _failure;
  HostSession? get hostSession => _hostSession;
  ClientSession? get clientSession => _clientSession;

  /// True once a session can drive a game screen.
  bool get isReady => _status == LobbyStatus.ready;

  // ---------------------------------------------------------------------------
  // Hosting
  // ---------------------------------------------------------------------------

  /// Binds [matchPort], announces the match and waits for a guest.
  ///
  /// Completes when the guest's session is up, or fails after
  /// [connectTimeout].
  Future<void> hostMatch(DeckDefinition deck) async {
    await cancel();
    _role = LobbyRole.hosting;
    _setStatus(LobbyStatus.waitingForGuest);
    try {
      final server = await TcpMatchTransport.listen(port: matchPort);
      _announcer = LanAnnouncer(
        name: name,
        matchPort: matchPort,
        port: discoveryPort,
        target: discoveryTarget,
      );
      await _announcer!.start();

      _transport = await TcpMatchTransport.accept(server).timeout(
        connectTimeout,
        onTimeout: () => throw TimeoutException('no guest joined'),
      );
      await _announcer?.stop();
      _announcer = null;

      final session = HostSession(
        transport: _transport!,
        hostSeat: 0,
        hostDeck: deck,
        opponentName: 'Guest',
      );
      final ready = session.events.firstWhere(
        (event) => event is SessionStarted,
      );
      _hostSession = session;
      await ready.timeout(connectTimeout);
      if (_disposed) return;
      _setStatus(LobbyStatus.ready);
    } on Object catch (error) {
      _fail(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Joining
  // ---------------------------------------------------------------------------

  /// Watches the LAN for hosts until [cancel] or [joinMatch].
  Future<void> browse() async {
    await cancel();
    _role = LobbyRole.joining;
    _setStatus(LobbyStatus.browsing);
    try {
      final browser = LanBrowser(port: discoveryPort);
      await browser.start();
      _browser = browser;
      _browserSubscription = browser.hosts.listen((host) {
        _hosts = [..._hosts.where((seen) => seen.id != host.id), host];
        _notify();
      });
    } on Object catch (error) {
      _fail(error);
    }
  }

  /// Connects to [host] and completes the handshake.
  Future<void> joinMatch(DiscoveredHost host, DeckDefinition deck) async {
    _role = LobbyRole.joining;
    _setStatus(LobbyStatus.connecting);
    try {
      await _browserSubscription?.cancel();
      _browserSubscription = null;
      await _browser?.close();
      _browser = null;

      _transport = await TcpMatchTransport.connect(
        host.address,
        port: host.matchPort,
      ).timeout(connectTimeout);
      final session = ClientSession(transport: _transport!, deck: deck);
      _clientSession = session;
      final ready = session.events.firstWhere((event) => event is SessionReady);
      session.connect();
      await ready.timeout(connectTimeout);
      if (_disposed) return;
      _setStatus(LobbyStatus.ready);
    } on Object catch (error) {
      _fail(error);
    }
  }

  /// Connects to a manually entered address, for networks without discovery.
  Future<void> joinAddress(String address, DeckDefinition deck) => joinMatch(
    DiscoveredHost(
      id: 'manual',
      name: address,
      address: address,
      matchPort: matchPort,
    ),
    deck,
  );

  // ---------------------------------------------------------------------------
  // Teardown
  // ---------------------------------------------------------------------------

  /// Stops announcing, browsing and any session.
  Future<void> cancel() async {
    _role = LobbyRole.idle;
    _hosts = const [];
    _failure = null;
    await _announcer?.stop();
    _announcer = null;
    await _browserSubscription?.cancel();
    _browserSubscription = null;
    await _browser?.close();
    _browser = null;
    await _hostSession?.close();
    _hostSession = null;
    await _clientSession?.close();
    _clientSession = null;
    await _transport?.close();
    _transport = null;
    _setStatus(LobbyStatus.idle);
  }

  void _fail(Object error) {
    _failure = error is TimeoutException
        ? 'timeout'
        : error.toString();
    _setStatus(LobbyStatus.failed);
  }

  void _setStatus(LobbyStatus status) {
    _status = status;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_closeQuietly());
    super.dispose();
  }

  Future<void> _closeQuietly() async {
    await _announcer?.stop();
    await _browserSubscription?.cancel();
    await _browser?.close();
    await _transport?.close();
    await _hostSession?.close();
    await _clientSession?.close();
  }
}
