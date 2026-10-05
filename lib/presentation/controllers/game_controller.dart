import 'package:flutter/material.dart';

import 'turn_driver.dart';

import '../../core/ai/ai.dart';
import '../../core/ai/ai_players.dart';
import '../../core/models/card.dart';
import '../../core/models/game_state.dart';
import '../../core/models/player.dart';
import '../../core/rules/game_engine.dart';
import '../../core/rules/game_event.dart';
import '../../core/rules/game_random.dart';
import '../theme/gwent_colors.dart';

/// A choice the UI must collect before a card can be played.
sealed class PendingChoice {
  const PendingChoice();
}

class RowChoice extends PendingChoice {
  const RowChoice(this.rows);
  final List<CardRow> rows;
}

enum TargetKind { battlefield, graveyard, hand, deck }

class TargetChoice extends PendingChoice {
  const TargetChoice(this.targets, this.kind, {this.requiredCount = 1});
  final List<CardInstance> targets;
  final TargetKind kind;

  /// How many cards the player must pick before confirming.
  final int requiredCount;
}

/// Bridges the rules engine to the widget tree.
///
/// Owns the local player's interaction state (selected card, pending target)
/// and drives the AI opponent with small delays so its moves are readable.
///
/// In [hotseat] mode two humans share the device: the local seat follows the
/// turn and the UI asks them to pass the device before the next hand is shown.
class GameController extends ChangeNotifier {
  GameController({
    required DeckDefinition humanDeck,
    required DeckDefinition opponentDeck,
    required Difficulty difficulty,
    String opponentName = 'Opponent',
    int localSeat = 0,
    bool hotseat = false,
    int? seed,
  }) : this._(
         GameEngine(
           firstDeck: humanDeck,
           secondDeck: opponentDeck,
           difficulty: difficulty,
           random: seed == null ? null : GameRandom(seed),
         ),
         localSeat: localSeat,
         opponentName: opponentName,
         hotseat: hotseat,
       );

  /// Resumes a match from a snapshot produced by [snapshot] using the given
  /// snapshot (which already carries the player names).
  factory GameController.resume(
    Map<String, dynamic> snapshot, {
    int localSeat = 0,
    bool hotseat = false,
  }) {
    final controller = GameController._(
      GameEngine.fromJson(snapshot),
      localSeat: localSeat,
      hotseat: hotseat,
    );
    controller._runAiMulligan();
    controller._driver.onStateChanged();
    return controller;
  }

  GameController._(
    this.engine, {
    required int localSeat,
    required this.hotseat,
    String? opponentName,
  }) : _localSeat = localSeat,
       difficulty = engine.state.players[localSeat].difficulty {
    _ai = createAi(difficulty);
    // The engine is seat agnostic; the presentation marks which seats humans
    // control. In hotseat play both of them are.
    if (hotseat) {
      for (final player in engine.state.players) {
        player.isHuman = true;
      }
    } else {
      engine.state.players[localSeat].isHuman = true;
      if (opponentName != null) {
        engine.state.players[engine.state.opponentOf(localSeat)].name =
            opponentName;
      }
    }
    _driver = hotseat
        ? const IdleTurnDriver()
        : LocalAiDriver(
            engine: engine,
            seat: engine.state.opponentOf(localSeat),
            ai: _ai,
            onApplied: () {
              _drainEvents();
              if (!_disposed) notifyListeners();
            },
            onThinkingChanged: (value) {
              isAiThinking = value;
              if (!_disposed) notifyListeners();
            },
          );
  }

  final GameEngine engine;

  /// True when two humans share this device.
  final bool hotseat;

  int _localSeat;

  /// Seat the device is currently showing.
  int get localSeat => _localSeat;

  int? _pendingSeat;

  /// Seat waiting for the device, when [hotseat] is on and the turn moved to
  /// the other player. The UI must hide the board until it is confirmed.
  int? get pendingSeat => _pendingSeat;

  final Difficulty difficulty;
  late final AiPlayer _ai;
  late final TurnDriver _driver;

  final List<CardInstance> redrawPicks = [];

  CardInstance? selectedCard;
  PendingChoice? pendingChoice;
  bool isAiThinking = false;
  bool _disposed = false;
  List<CardInstance> _destroyerDiscard = const [];

  final Map<int, int> _flashCounters = {};
  final Map<int, Color> _flashColors = {};

  /// Per-card effect counter; increments every time an ability affects the card.
  int flashCounter(int uid) => _flashCounters[uid] ?? 0;

  /// Colour of the last ability that affected the card, or null.
  Color? flashColorFor(int uid) => _flashColors[uid];

  /// True while the player is choosing cards for a leader ability.
  bool get isChoosingForLeader => pendingChoice != null && selectedCard == null;

  GameState get state => engine.state;
  PlayerState get human => state.players[_localSeat];
  PlayerState get opponent => state.players[state.opponentOf(_localSeat)];
  bool get isMulligan =>
      state.phase == GamePhase.mulligan && !human.mulliganDone;
  bool get isGameOver => state.phase == GamePhase.gameOver;

  /// True while this seat may act.
  bool get isLocalTurn =>
      state.phase == GamePhase.playing && state.currentPlayer == localSeat;

  /// True while any other seat is acting.
  bool get isRemoteTurn =>
      state.phase == GamePhase.playing && state.currentPlayer != localSeat;

  int get redrawsLeft => GameEngine.maxRedraws - human.redraws;

  /// Accepts the pending device hand-over and switches the visible seat.
  void confirmSeatSwitch() {
    final seat = _pendingSeat;
    if (seat == null) return;
    _localSeat = seat;
    _pendingSeat = null;
    selectedCard = null;
    pendingChoice = null;
    notifyListeners();
  }

  /// Hands the device over to [seat] when hotseat play moved the turn.
  void _syncHotseat() {
    if (!hotseat) return;
    if (state.phase == GamePhase.mulligan) {
      final next = state.players.where((p) => !p.mulliganDone);
      if (next.length == 1 && next.single.index != _localSeat) {
        _pendingSeat = next.single.index;
      }
      return;
    }
    if (state.phase != GamePhase.playing) return;
    final current = state.currentPlayer;
    if (current == _localSeat || state.players[current].passed) return;
    _pendingSeat = current;
  }

  /// Starts the match and enters the mulligan phase.
  void start() {
    engine.startMatch();
    _runAiMulligan();
    _drainEvents();
    notifyListeners();
  }

  /// Redraws the opening hand of every seat this client does not control.
  void _runAiMulligan() {
    if (hotseat) return;
    if (state.phase != GamePhase.mulligan) return;
    for (final player in state.players) {
      if (player.isHuman || player.mulliganDone) continue;
      for (var i = 0; i < GameEngine.maxRedraws; i++) {
        final order = engine.mulliganDiscards(player);
        if (order.isEmpty) break;
        final card = order.first;
        if (card.baseStrength >= 15) break;
        if (!engine.redraw(player.index, card)) break;
      }
      engine.finishMulligan(player.index);
    }
  }

  /// Serializes the current match so it can be resumed later.
  Map<String, dynamic> snapshot() => engine.toJson();

  // ---------------------------------------------------------------------------
  // Mulligan
  // ---------------------------------------------------------------------------

  void toggleRedraw(CardInstance card) {
    if (!isMulligan) return;
    if (!redrawPicks.remove(card)) {
      if (redrawPicks.length >= redrawsLeft) return;
      redrawPicks.add(card);
    }
    notifyListeners();
  }

  void confirmMulligan() {
    if (!isMulligan) return;
    for (final card in redrawPicks) {
      engine.redraw(human.index, card);
    }
    redrawPicks.clear();
    engine.finishMulligan(human.index);
    _drainEvents();
    _syncHotseat();
    notifyListeners();
    _driver.onStateChanged();
  }

  // ---------------------------------------------------------------------------
  // Human actions
  // ---------------------------------------------------------------------------

  void selectCard(CardInstance? card) {
    selectedCard = card;
    pendingChoice = null;
    notifyListeners();
  }

  void clearSelection() {
    selectedCard = null;
    pendingChoice = null;
    _destroyerDiscard = const [];
    notifyListeners();
  }

  /// Plays the selected card, asking for a row or target when required.
  void playSelected({CardRow? row, CardInstance? target}) {
    final card = selectedCard;
    if (card == null) return;
    if (!engine.canPlayCard(human.index, card)) return;

    if (_needsRow(card) && row == null) {
      pendingChoice = RowChoice(_rowOptions(card));
      notifyListeners();
      return;
    }
    if (card.hasAbility(Ability.decoy) && target == null) {
      final targets = _ownBattlefieldUnits();
      pendingChoice = TargetChoice(targets, TargetKind.battlefield);
      notifyListeners();
      return;
    }
    if (card.hasAbility(Ability.medic) && target == null) {
      final graveyard = human.graveyard.where((c) => c.isUnit).toList();
      if (graveyard.isNotEmpty) {
        pendingChoice = TargetChoice(graveyard, TargetKind.graveyard);
        notifyListeners();
        return;
      }
    }

    final played = engine.playCard(
      human.index,
      card,
      targetRow: row,
      target: target,
    );
    if (!played) return;
    _afterHumanAction();
  }

  void pass() {
    if (!isLocalTurn) return;
    engine.pass(human.index);
    _afterHumanAction();
  }

  void activateLeader() {
    if (!isLocalTurn || !human.leaderAvailable) return;
    switch (human.leader.abilities.first) {
      case 'eredin_destroyer':
        final required = human.hand.length < 2 ? human.hand.length : 2;
        if (required == 0) {
          // Nothing to discard: go straight to the draw.
          _startDestroyerDraw();
          return;
        }
        pendingChoice = TargetChoice(
          List.of(human.hand),
          TargetKind.hand,
          requiredCount: required,
        );
        notifyListeners();
        return;
      case 'emhyr_relentless':
        final targets = opponent.graveyard.where((c) => c.isUnit).toList();
        if (targets.isEmpty) break;
        pendingChoice = TargetChoice(targets, TargetKind.graveyard);
        notifyListeners();
        return;
      case 'eredin_bringer_of_death':
        final targets = human.graveyard.where((c) => c.isUnit).toList();
        if (targets.isEmpty) break;
        pendingChoice = TargetChoice(targets, TargetKind.graveyard);
        notifyListeners();
        return;
      default:
        break;
    }
    engine.activateLeader(human.index);
    _afterHumanAction();
  }

  /// Resolves a [TargetChoice] collected by the UI.
  ///
  /// For card-driven choices (Decoy, Medic) the selection is forwarded to
  /// [playSelected]; for leader abilities it completes the activation.
  void chooseTargets(List<CardInstance> targets) {
    if (targets.isEmpty) return;
    if (selectedCard != null) {
      playSelected(target: targets.first);
      return;
    }
    final choice = pendingChoice;
    if (choice is! TargetChoice) return;
    switch (choice.kind) {
      case TargetKind.hand:
        _destroyerDiscard = targets.take(choice.requiredCount).toList();
        _startDestroyerDraw();
        return;
      case TargetKind.deck:
        engine.activateLeader(
          human.index,
          discard: _destroyerDiscard,
          deckPick: targets.first,
        );
        _afterHumanAction();
        return;
      case TargetKind.graveyard:
      case TargetKind.battlefield:
        engine.activateLeader(human.index, target: targets.first);
        _afterHumanAction();
        return;
    }
  }

  void _finishDestroyer() {
    engine.activateLeader(human.index, discard: _destroyerDiscard);
    _afterHumanAction();
  }

  /// Asks the player which card to draw after the Destroyer of Worlds discard,
  /// or resolves immediately when the deck is empty.
  void _startDestroyerDraw() {
    final deck = List.of(human.deck);
    if (deck.isEmpty) {
      _finishDestroyer();
      return;
    }
    pendingChoice = TargetChoice(deck, TargetKind.deck);
    notifyListeners();
  }

  void _afterHumanAction() {
    selectedCard = null;
    pendingChoice = null;
    _destroyerDiscard = const [];
    _drainEvents();
    _syncHotseat();
    notifyListeners();
    _driver.onStateChanged();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _needsRow(CardInstance card) =>
      card.row == CardRow.agile || card.usesRowSpecialSlot;

  List<CardRow> _rowOptions(CardInstance card) {
    if (card.usesRowSpecialSlot) {
      return CardRow.combatRows
          .where((row) => !state.rowState(human.index, row).hasSpecial)
          .toList();
    }
    return const [CardRow.close, CardRow.ranged];
  }

  List<CardInstance> _ownBattlefieldUnits() {
    final units = <CardInstance>[];
    for (final row in state.rowsFor(human.index)) {
      units.addAll(row.cards.where((c) => c.isUnit));
    }
    return units;
  }

  void _drainEvents() {
    for (final event in engine.takeEvents()) {
      if (event is AbilityTriggered && event.cards.isNotEmpty) {
        final color = GwentColors.abilityEffect(event.ability);
        for (final card in event.cards) {
          _flashCounters[card.uid] = (_flashCounters[card.uid] ?? 0) + 1;
          _flashColors[card.uid] = color;
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _driver.dispose();
    super.dispose();
  }
}
