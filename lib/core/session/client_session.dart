import 'dart:async';

import '../data/deck_codec.dart';
import '../data/match_versions.dart';
import '../models/player.dart';
import '../rules/game_command.dart';
import 'command_codec.dart';
import 'match_transport.dart';
import 'session_event.dart';

/// Guest side of a match.
///
/// The client never simulates: it sends commands for its own seat and renders
/// the projections the host sends back.
class ClientSession {
  ClientSession({
    required MatchTransport transport,
    required this.deck,
    this.name = 'Guest',
  }) : _transport = transport {
    _listen(transport);
  }

  /// Current link to the host. Replaced by [reconnect].
  MatchTransport get transport => _transport;
  final DeckDefinition deck;
  final String name;

  late MatchTransport _transport;
  StreamSubscription<Map<String, Object?>>? _subscription;
  bool _handshaken = false;
  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast();

  int? _seat;
  int _seq = 0;
  Map<String, Object?>? _view;

  Stream<SessionEvent> get events => _events.stream;

  /// Seat assigned by the host, once the handshake completed.
  int? get seat => _seat;

  /// Latest projection received, or null before the match starts.
  Map<String, Object?>? get view => _view;

  bool get isReady => _seat != null;

  /// Attaches a new link after a disconnect and handshakes again.
  ///
  /// The host answers with a fresh projection, so the guest can resume without
  /// replaying anything.
  Future<void> reconnect(MatchTransport next) async {
    await _subscription?.cancel();
    await _transport.close();
    _transport = next;
    _listen(next);
    connect();
  }

  void _listen(MatchTransport link) {
    _subscription = link.incoming.listen(
      _onMessage,
      onDone: () => _fail(SessionFailure.closed),
      onError: (_) => _fail(SessionFailure.closed),
    );
  }

  /// Starts the handshake; the host answers with a seat or a rejection.
  void connect() {
    _transport.send({
      'type': SessionMessage.hello,
      'protocol': MatchVersions.protocolVersion,
      'catalog': MatchVersions.catalogHash,
      'rules': MatchVersions.rulesVersion,
      'name': name,
    });
  }

  /// Submits a command for this client's seat.
  void submit(GameCommand command) {
    assert(
      _seat == null || command.player == _seat,
      'the client only submits commands for its own seat',
    );
    _seq++;
    _transport.send({
      'type': SessionMessage.command,
      'seq': _seq,
      'command': CommandCodec.encode(command),
    });
  }

  Future<void> close() async {
    if (_events.isClosed) return;
    _transport.send(const {'type': SessionMessage.bye});
    await _transport.close();
    await _subscription?.cancel();
    await _events.close();
  }

  // ---------------------------------------------------------------------------
  // Host messages
  // ---------------------------------------------------------------------------

  void _onMessage(Map<String, Object?> message) {
    switch (message['type']) {
      case SessionMessage.welcome:
        _handleWelcome(message);
      case SessionMessage.start:
        _events.add(const SessionStarted());
      case SessionMessage.view:
        final view = message['view'];
        if (view is Map) {
          _view = view.cast<String, Object?>();
          _events.add(SessionViewUpdated(_view!));
        }
      case SessionMessage.rejected:
        final reason = CommandCodec.rejectionFromName(
          message['reason'] as String?,
        );
        if (reason != null) _events.add(SessionCommandRejected(reason));
      case SessionMessage.reject:
        _fail(message['reason'] as String? ?? SessionFailure.protocol);
      case SessionMessage.bye:
        _fail(SessionFailure.closed);
      default:
        _fail(SessionFailure.protocol);
    }
  }

  void _handleWelcome(Map<String, Object?> message) {
    final seat = message['seat'];
    if (seat is! int) return _fail(SessionFailure.protocol);
    _seat = seat;
    _events.add(SessionReady(seat));
    // Only the first handshake submits the deck; a reconnection reuses the one
    // the host already has.
    if (!_handshaken) {
      _handshaken = true;
      _transport.send({'type': SessionMessage.deck, 'deck': deckToJson(deck)});
    }
  }

  void _fail(String code) {
    if (_events.isClosed) return;
    _events.add(SessionFailed(code));
    _events.close();
  }
}
