import 'dart:async';

import '../data/deck_codec.dart';
import '../data/match_versions.dart';
import '../models/player.dart';
import '../rules/game_command.dart';
import '../rules/game_engine.dart';
import '../rules/game_projection.dart';
import '../rules/game_random.dart';
import 'command_codec.dart';
import 'match_transport.dart';
import 'session_event.dart';

/// Host side of a match: owns the authoritative engine, validates the guest's
/// commands and sends that guest a fresh projection after every change.
///
/// The host plays its own seat through [submit] and never receives its own
/// commands over the wire.
class HostSession {
  HostSession({
    required MatchTransport transport,
    required this.hostSeat,
    required this.hostDeck,
    this.opponentName = 'Guest',
    this.difficulty = Difficulty.normal,
    this.randomSeed,
  }) : _transport = transport {
    _listen(transport);
  }

  /// Current link to the guest. Replaced by [rebind] after a reconnection.
  MatchTransport get transport => _transport;
  final int hostSeat;
  final DeckDefinition hostDeck;
  final String opponentName;
  final Difficulty difficulty;
  /// Seed for the match generator; a random one is used when null.
  final int? randomSeed;

  late MatchTransport _transport;
  StreamSubscription<Map<String, Object?>>? _subscription;
  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast();

  GameEngine? _engine;
  int? _guestSeat;
  DeckDefinition? _guestDeck;
  int _lastSeq = -1;

  /// Events for the host's own UI (started, rejected, failed).
  Stream<SessionEvent> get events => _events.stream;

  /// The authoritative engine, once the guest's deck has arrived.
  GameEngine? get engine => _engine;

  /// Seat the guest controls, once the handshake completed.
  int? get guestSeat => _guestSeat;

  bool get isReady => _engine != null;

  /// Applies a command from the host's own seat and refreshes the guest view.
  CommandResult submit(GameCommand command) {
    final engine = _engine;
    if (engine == null) return const CommandRejected(CommandRejection.wrongPhase);
    final result = engine.apply(command);
    if (result.accepted) _publishView();
    return result;
  }

  /// Points the session at a new link, e.g. after the guest reconnected.
  ///
  /// The engine is untouched, so the returning guest can be caught up with a
  /// fresh projection.
  Future<void> rebind(MatchTransport next) async {
    await _subscription?.cancel();
    await _transport.close();
    _transport = next;
    _listen(next);
    if (_engine != null) _publishView();
  }

  Future<void> close() async {
    if (_events.isClosed) return;
    _transport.send(const {'type': SessionMessage.bye});
    await _transport.close();
    await _subscription?.cancel();
    await _events.close();
  }

  void _listen(MatchTransport link) {
    _subscription = link.incoming.listen(
      _onMessage,
      onDone: _onPeerLost,
      onError: (_) => _onPeerLost(),
    );
  }

  /// A guest leaving does not end the match: the engine lives on and a
  /// reconnecting guest can be caught up.
  void _onPeerLost() {
    if (_events.isClosed) return;
    _events.add(const SessionPeerLost());
  }

  // ---------------------------------------------------------------------------
  // Guest messages
  // ---------------------------------------------------------------------------

  void _onMessage(Map<String, Object?> message) {
    switch (message['type']) {
      case SessionMessage.hello:
        _handleHello(message);
      case SessionMessage.deck:
        _handleDeck(message);
      case SessionMessage.command:
        _handleCommand(message);
      case SessionMessage.bye:
        // A guest leaving is a disconnect, not the end of the match.
        _onPeerLost();
      default:
        _fail(SessionFailure.protocol);
    }
  }

  void _handleHello(Map<String, Object?> message) {
    final protocol = message['protocol'];
    final catalog = message['catalog'];
    if (protocol != MatchVersions.protocolVersion ||
        catalog != MatchVersions.catalogHash) {
      _send({
        'type': SessionMessage.reject,
        'reason': SessionFailure.versions,
      });
      _fail(SessionFailure.versions);
      return;
    }
    _guestSeat ??= _otherSeat(hostSeat);
    _send({
      'type': SessionMessage.welcome,
      'seat': _guestSeat,
      'protocol': MatchVersions.protocolVersion,
      'catalog': MatchVersions.catalogHash,
      'rules': MatchVersions.rulesVersion,
    });
    // A returning guest arrives after the match started: catch it up instead
    // of waiting for another deck.
    if (_engine != null) _publishView();
  }

  void _handleDeck(Map<String, Object?> message) {
    if (_engine != null || _guestDeck != null) return;
    final raw = message['deck'];
    if (raw is! Map) return _sendFailure(SessionFailure.deck);
    final deck = deckFromJson(raw.cast<String, Object?>());
    if (deck == null) return _sendFailure(SessionFailure.deck);
    _guestDeck = deck;
    _startMatch(deck);
  }

  void _handleCommand(Map<String, Object?> message) {
    final engine = _engine;
    final guest = _guestSeat;
    if (engine == null || guest == null) {
      return _reject(message, CommandRejection.wrongPhase);
    }
    final seq = message['seq'];
    if (seq is! int) return _fail(SessionFailure.protocol);
    // Retries are idempotent: a sequence already applied is simply ignored.
    if (seq <= _lastSeq) return;

    final raw = message['command'];
    final command = raw is Map
        ? CommandCodec.decode(raw.cast<String, Object?>())
        : null;
    if (command == null) return _fail(SessionFailure.protocol);
    if (command.player != guest) {
      return _reject(message, CommandRejection.notYourTurn);
    }
    final result = engine.apply(command);
    if (result is CommandRejected) {
      return _reject(message, result.reason);
    }
    _lastSeq = seq;
    _publishView();
  }

  // ---------------------------------------------------------------------------
  // Match lifecycle
  // ---------------------------------------------------------------------------

  void _startMatch(DeckDefinition guestDeck) {
    final firstDeck = hostSeat == 0 ? hostDeck : guestDeck;
    final secondDeck = hostSeat == 0 ? guestDeck : hostDeck;
    final engine = GameEngine(
      firstDeck: firstDeck,
      secondDeck: secondDeck,
      difficulty: difficulty,
      random: GameRandom(randomSeed),
    );
    engine.state.players[hostSeat].isHuman = true;
    engine.state.players[_otherSeat(hostSeat)].name = opponentName;
    engine.startMatch();
    _engine = engine;
    _send({'type': SessionMessage.start, 'seat': _guestSeat});
    _events.add(const SessionStarted());
    _publishView();
  }

  void _publishView() {
    final engine = _engine;
    final guest = _guestSeat;
    if (engine == null || guest == null) return;
    final view = encodeProjection(engine.state, viewer: guest);
    _send({'type': SessionMessage.view, 'view': view});
    _events.add(SessionViewUpdated(view));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _otherSeat(int seat) => seat == 0 ? 1 : 0;

  void _send(Map<String, Object?> message) => _transport.send(message);

  void _sendFailure(String code) {
    _send({'type': SessionMessage.reject, 'reason': code});
    _fail(code);
  }

  void _reject(Map<String, Object?> message, CommandRejection reason) {
    _send({
      'type': SessionMessage.rejected,
      'seq': message['seq'],
      'reason': reason.name,
    });
  }

  void _fail(String code) {
    if (_events.isClosed) return;
    _events.add(SessionFailed(code));
    _events.close();
  }
}
