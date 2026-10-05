import 'package:flutter/material.dart';

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
/// Owns the human's interaction state (selected card, pending target) and
/// drives the AI opponent with small delays so its moves are readable.
class GameController extends ChangeNotifier {
  GameController({
    required DeckDefinition humanDeck,
    required DeckDefinition opponentDeck,
    required Difficulty difficulty,
    String opponentName = 'Opponent',
    int? seed,
  }) : this._(
         GameEngine(
           humanDeck: humanDeck,
           opponentDeck: opponentDeck,
           difficulty: difficulty,
           random: seed == null ? null : GameRandom(seed),
           opponentName: opponentName,
         ),
       );

  /// Resumes a match from a snapshot produced by [snapshot].
  factory GameController.resume(Map<String, dynamic> snapshot) {
    final controller = GameController._(GameEngine.fromJson(snapshot));
    controller._maybeRunAi();
    return controller;
  }

  GameController._(this.engine) : difficulty = engine.human.difficulty {
    _ai = createAi(difficulty);
  }

  final GameEngine engine;
  final Difficulty difficulty;
  late final AiPlayer _ai;

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
  PlayerState get human => engine.human;
  PlayerState get opponent => engine.opponent;
  bool get isMulligan => state.phase == GamePhase.mulligan;
  bool get isGameOver => state.phase == GamePhase.gameOver;
  int get redrawsLeft => GameEngine.maxRedraws - engine.humanRedraws;

  /// Starts the match and enters the mulligan phase.
  void start() {
    engine.startMatch();
    _drainEvents();
    notifyListeners();
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
    engine.finishMulligan();
    _drainEvents();
    notifyListeners();
    _maybeRunAi();
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
    if (!engine.isHumanTurn) return;
    engine.pass(human.index);
    _afterHumanAction();
  }

  void activateLeader() {
    if (!engine.isHumanTurn || !human.leaderAvailable) return;
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
    notifyListeners();
    _maybeRunAi();
  }

  // ---------------------------------------------------------------------------
  // AI
  // ---------------------------------------------------------------------------

  void _maybeRunAi() {
    if (_disposed) return;
    if (isGameOver) return;
    if (state.phase != GamePhase.playing) return;
    if (!engine.isOpponentTurn) return;
    isAiThinking = true;
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (_disposed || isGameOver) return;
      if (!engine.isOpponentTurn) {
        isAiThinking = false;
        notifyListeners();
        return;
      }
      final action = _ai.decide(engine, opponent);
      _applyAi(action);
      isAiThinking = false;
      _drainEvents();
      notifyListeners();
      _maybeRunAi();
    });
  }

  void _applyAi(AiAction action) {
    final applied = switch (action) {
      AiPlayCard(:final card, :final targetRow, :final target) =>
        engine.playCard(
          opponent.index,
          card,
          targetRow: targetRow,
          target: target,
        ),
      AiActivateLeader(:final targetRow, :final target) =>
        engine.activateLeader(
          opponent.index,
          targetRow: targetRow,
          target: target,
        ),
      AiPass() => _passAi(),
    };
    if (!applied) engine.pass(opponent.index);
  }

  bool _passAi() {
    engine.pass(opponent.index);
    return true;
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
    super.dispose();
  }
}
