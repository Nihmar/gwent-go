import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/ai/ai.dart';
import '../../core/models/game_state.dart';
import '../../core/rules/game_engine.dart';

/// Drives the seats the local player does not control.
///
/// The view controller calls [onStateChanged] after every change; the driver
/// schedules whatever those seats need: an AI move, nothing at all for hotseat,
/// or a network round trip once a session driver lands.
abstract interface class TurnDriver {
  /// Called after every state change (a local action, a mulligan, a resume).
  void onStateChanged();

  /// Cancels pending work and releases resources.
  void dispose();
}

/// Drives nothing: every seat is local, as in hotseat play.
class IdleTurnDriver implements TurnDriver {
  const IdleTurnDriver();

  @override
  void onStateChanged() {}

  @override
  void dispose() {}
}

/// Plays one AI-controlled seat with a short delay so its moves are readable.
class LocalAiDriver implements TurnDriver {
  LocalAiDriver({
    required this.engine,
    required this.seat,
    required this.ai,
    required this.onApplied,
    required this.onThinkingChanged,
    this.delay = const Duration(milliseconds: 650),
  });

  final GameEngine engine;

  /// Seat this driver plays.
  final int seat;
  final AiPlayer ai;

  /// Called after a move was applied so the controller can drain events and
  /// notify its listeners.
  final VoidCallback onApplied;

  /// Reports whether this driver is currently waiting to act.
  final ValueChanged<bool> onThinkingChanged;

  final Duration delay;

  Timer? _timer;
  bool _disposed = false;
  bool _thinking = false;

  /// True while waiting for the delayed move. Exposed for tests.
  bool get isThinking => _thinking;

  @override
  void onStateChanged() {
    if (_disposed) return;
    final state = engine.state;
    if (state.phase != GamePhase.playing) return;
    if (state.currentPlayer != seat) return;
    _timer?.cancel();
    _setThinking(true);
    _timer = Timer(delay, _act);
  }

  void _act() {
    if (_disposed) return;
    final state = engine.state;
    if (state.phase == GamePhase.playing && state.currentPlayer == seat) {
      _apply(ai.decide(engine, state.players[seat]));
    }
    _setThinking(false);
    onApplied();
    // The turn may still belong to this seat (for example when the opponent has
    // passed), so ask for another move.
    onStateChanged();
  }

  void _apply(AiAction action) {
    final applied = switch (action) {
      AiPlayCard(:final card, :final targetRow, :final target) => engine
          .playCard(seat, card, targetRow: targetRow, target: target),
      AiActivateLeader(:final targetRow, :final target) => engine
          .activateLeader(seat, targetRow: targetRow, target: target),
      AiPass() => _pass(),
    };
    // A rejected action would otherwise stall the match, so fall back to
    // passing.
    if (!applied) engine.pass(seat);
  }

  bool _pass() {
    engine.pass(seat);
    return true;
  }

  void _setThinking(bool value) {
    if (_thinking == value) return;
    _thinking = value;
    onThinkingChanged(value);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
