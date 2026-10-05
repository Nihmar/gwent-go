import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/card.dart';
import '../../core/models/game_state.dart';
import '../../core/models/player.dart';
import '../../core/rules/game_command.dart';
import '../../core/rules/game_engine.dart';
import '../../core/rules/game_event.dart';
import '../../core/rules/game_projection.dart';
import '../../core/session/client_session.dart';
import '../../core/session/session_event.dart';

/// What the game controller needs from whoever owns the match.
///
/// Two implementations exist: [EngineBackend] for a match this client owns
/// (single player or hotseat) and [SessionBackend] for a guest that renders the
/// host's projections and forwards commands.
abstract interface class MatchBackend {
  /// State the widgets render.
  GameState get state;

  /// True when this side owns the authoritative engine.
  bool get isAuthoritative;

  /// False while the other side is unreachable. Always true locally.
  bool get opponentOnline;

  /// Notified when the state changed outside a local action (remote views).
  set onChanged(VoidCallback? listener);

  /// Deals the opening hands and enters the mulligan phase.
  void startMatch();

  /// Applies or forwards [command].
  CommandResult apply(GameCommand command);

  /// Events produced by the last action; empty for a remote guest.
  List<GameEvent> takeEvents();

  /// Snapshot for pause/resume, when this side can produce one.
  Map<String, dynamic>? snapshot();

  /// Discard order for a seat's mulligan; empty when this side cannot compute
  /// it (the guest leaves the first player's redraws to its own UI).
  List<CardInstance> mulliganDiscards(PlayerState player);

  /// Whether [card] may be played by [player] right now.
  bool canPlayCard(int player, CardInstance card);

  bool redraw(int player, CardInstance card);

  bool finishMulligan(int player);

  bool playCard(
    int player,
    CardInstance card, {
    CardRow? targetRow,
    CardInstance? target,
  });

  void pass(int player);

  bool activateLeader(
    int player, {
    CardRow? targetRow,
    CardInstance? target,
    List<CardInstance>? discard,
    CardInstance? deckPick,
  });

  void dispose();
}

/// Backend backed by the local rules engine.
class EngineBackend implements MatchBackend {
  EngineBackend(this.engine, {Stream<SessionEvent>? peerEvents}) {
    _peerEvents = peerEvents?.listen(_onPeerEvent);
  }

  final GameEngine engine;

  StreamSubscription<SessionEvent>? _peerEvents;
  VoidCallback? _onPeerChanged;
  bool _opponentOnline = true;

  /// The host is authoritative but still needs to know when its guest goes
  /// away, so the board can say so instead of looking frozen.
  void _onPeerEvent(SessionEvent event) {
    final online = switch (event) {
      SessionPeerLost() => false,
      SessionViewUpdated() => true,
      _ => _opponentOnline,
    };
    if (online == _opponentOnline) return;
    _opponentOnline = online;
    _onPeerChanged?.call();
  }

  @override
  GameState get state => engine.state;

  @override
  bool get isAuthoritative => true;

  @override
  bool get opponentOnline => _opponentOnline;

  @override
  set onChanged(VoidCallback? listener) => _onPeerChanged = listener;

  @override
  void startMatch() => engine.startMatch();

  @override
  CommandResult apply(GameCommand command) => engine.apply(command);

  @override
  List<GameEvent> takeEvents() => engine.takeEvents();

  @override
  Map<String, dynamic>? snapshot() => engine.toJson();

  @override
  List<CardInstance> mulliganDiscards(PlayerState player) =>
      engine.mulliganDiscards(player);

  @override
  bool canPlayCard(int player, CardInstance card) =>
      engine.canPlayCard(player, card);

  @override
  bool redraw(int player, CardInstance card) => engine.redraw(player, card);

  @override
  bool finishMulligan(int player) => engine.finishMulligan(player);

  @override
  bool playCard(
    int player,
    CardInstance card, {
    CardRow? targetRow,
    CardInstance? target,
  }) => engine.playCard(
    player,
    card,
    targetRow: targetRow,
    target: target,
  );

  @override
  void pass(int player) => engine.pass(player);

  @override
  bool activateLeader(
    int player, {
    CardRow? targetRow,
    CardInstance? target,
    List<CardInstance>? discard,
    CardInstance? deckPick,
  }) => engine.activateLeader(
    player,
    targetRow: targetRow,
    target: target,
    discard: discard,
    deckPick: deckPick,
  );

  @override
  void dispose() {
    _peerEvents?.cancel();
    _peerEvents = null;
  }
}

/// Backend backed by a session client: the peer owns the rules.
class SessionBackend implements MatchBackend {
  SessionBackend(this.session, {required this.localSeat}) {
    _subscription = session.events.listen((event) {
      switch (event) {
        // A view is the proof the peer is back: the host resyncs a returning
        // guest with a fresh projection.
        case SessionViewUpdated():
          _state = null;
          if (!_opponentOnline) _opponentOnline = true;
          onChanged?.call();
        // The guest sees a lost host as a failed session: the link is gone
        // and only a reconnect can bring it back.
        case SessionPeerLost() || SessionFailed():
          if (_opponentOnline) {
            _opponentOnline = false;
            onChanged?.call();
          }
        default:
          break;
      }
    });
  }

  final ClientSession session;
  final int localSeat;

  late final StreamSubscription<SessionEvent> _subscription;
  VoidCallback? onChanged;
  GameState? _state;

  @override
  GameState get state => _state ??= _decode();

  GameState _decode() {
    final view = session.view;
    if (view == null) {
      throw StateError('the session has not received a view yet');
    }
    final decoded = decodeProjection(view);
    // The host sends the same payload to every seat; the local one marks
    // itself so the UI knows which side is "you".
    decoded.players[localSeat].isHuman = true;
    return decoded;
  }

  @override
  bool get isAuthoritative => false;

  @override
  bool get opponentOnline => _opponentOnline;
  bool _opponentOnline = true;

  /// The match already started on the host.
  @override
  void startMatch() {}

  @override
  CommandResult apply(GameCommand command) {
    // Optimistic: the host validates and answers with a view or a rejection.
    session.submit(command);
    return const CommandAccepted();
  }

  @override
  List<GameEvent> takeEvents() => const [];

  @override
  Map<String, dynamic>? snapshot() => null;

  @override
  List<CardInstance> mulliganDiscards(PlayerState player) => const [];

  @override
  bool redraw(int player, CardInstance card) =>
      apply(RedrawCommand(player: player, cardUid: card.uid)).accepted;

  @override
  bool finishMulligan(int player) =>
      apply(FinishMulliganCommand(player)).accepted;

  @override
  bool playCard(
    int player,
    CardInstance card, {
    CardRow? targetRow,
    CardInstance? target,
  }) => apply(
    PlayCardCommand(
      player: player,
      cardUid: card.uid,
      targetRow: targetRow,
      targetUid: target?.uid,
    ),
  ).accepted;

  @override
  void pass(int player) => apply(PassCommand(player));

  @override
  bool activateLeader(
    int player, {
    CardRow? targetRow,
    CardInstance? target,
    List<CardInstance>? discard,
    CardInstance? deckPick,
  }) => apply(
    ActivateLeaderCommand(
      player: player,
      targetRow: targetRow,
      targetUid: target?.uid,
      discardUids: [for (final card in discard ?? const []) card.uid],
      deckPickUid: deckPick?.uid,
    ),
  ).accepted;

  @override
  bool canPlayCard(int player, CardInstance card) {
    final current = state;
    if (current.phase != GamePhase.playing) return false;
    if (current.currentPlayer != player) return false;
    final owner = current.players[player];
    if (owner.passed) return false;
    return owner.hand.any((candidate) => candidate.uid == card.uid);
  }

  @override
  void dispose() {
    _subscription.cancel();
  }
}
