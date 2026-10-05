import '../data/card_repository.dart';
import '../models/card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'game_command.dart';
import 'game_event.dart';
import 'game_random.dart';
import 'scoring.dart';

part 'game_engine_abilities.dart';
part 'game_engine_leaders.dart';
part 'game_engine_snapshot.dart';
part 'game_engine_zones.dart';

/// The authoritative, platform-independent Gwent rules engine.
///
/// The engine is synchronous: every public action resolves a complete turn and
/// returns the events that were produced. Presentation code (the controller)
/// drives the AI and consumes [takeEvents] to animate the result.
///
/// Card placement, ability resolution and leader abilities live in the
/// [_AbilityResolver] companion part file to keep both files cohesive.
class GameEngine {
  GameEngine({
    required DeckDefinition humanDeck,
    required DeckDefinition opponentDeck,
    required Difficulty difficulty,
    GameRandom? random,
    this.opponentName = 'Opponent',
  }) : _random = random ?? GameRandom() {
    final human = PlayerState(
      index: 0,
      name: 'You',
      faction: humanDeck.faction,
      leader: humanDeck.leader,
      isHuman: true,
      difficulty: difficulty,
      deckDefinition: humanDeck,
    );
    final opponent = PlayerState(
      index: 1,
      name: opponentName,
      faction: opponentDeck.faction,
      leader: opponentDeck.leader,
      isHuman: false,
      difficulty: difficulty,
      deckDefinition: opponentDeck,
    );
    state = GameState(
      players: [human, opponent],
      roundNumber: 0,
      currentPlayer: 0,
      firstPlayer: 0,
    );
    _buildDeck(human);
    _buildDeck(opponent);
    _abilities = _AbilityResolver(this);
  }

  /// Rebuilds an engine around a restored [GameState].
  GameEngine._restore(this._random, this.opponentName, GameState restored) {
    state = restored;
    _abilities = _AbilityResolver(this);
  }

  /// Restores a paused match previously produced by [toJson].
  ///
  /// Throws [FormatException] when the snapshot is unusable; callers should
  /// discard it in that case.
  factory GameEngine.fromJson(Map<String, dynamic> json, {GameRandom? random}) {
    final decoded = decodeMatch(json);
    final engine = GameEngine._restore(
      random ?? GameRandom(json['randomSeed'] as int?),
      json['opponentName'] as String? ?? 'Opponent',
      decoded.state,
    );
    engine._uid = decoded.maxUid + 1;
    engine.humanRedraws = json['humanRedraws'] as int? ?? 0;
    return engine;
  }

  /// Serializes the current match so it can be paused and resumed later.
  Map<String, dynamic> toJson() => encodeMatch(
    state,
    opponentName: opponentName,
    humanRedraws: humanRedraws,
    randomSeed: _random.seed,
  );

  final GameRandom _random;
  final String opponentName;

  late final GameState state;
  late final _AbilityResolver _abilities;

  final List<GameEvent> _events = [];
  int _uid = 0;

  int humanRedraws = 0;
  static const int maxRedraws = 2;
  static const int openingHandSize = 10;

  List<GameEvent> takeEvents() {
    final out = List<GameEvent>.unmodifiable(_events);
    _events.clear();
    return out;
  }

  GameRandom get random => _random;
  PlayerState get human => state.players[0];
  PlayerState get opponent => state.players[1];

  bool get isHumanTurn =>
      state.phase == GamePhase.playing && state.currentPlayer == human.index;

  bool get isOpponentTurn =>
      state.phase == GamePhase.playing && state.currentPlayer == opponent.index;

  int nextUid() => _uid++;

  void _emit(GameEvent event) => _events.add(event);

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  void _buildDeck(PlayerState player) {
    player.deckDefinition.cardCounts.forEach((id, count) {
      final definition = CardRepository.byId(id);
      for (var i = 0; i < count; i++) {
        player.deck.add(
          CardInstance(
            uid: nextUid(),
            definition: definition,
            owner: player.index,
          ),
        );
      }
    });
    _random.shuffle(player.deck);
  }

  /// Draws opening hands, applies start-of-game abilities and enters mulligan.
  void startMatch() {
    _abilities.draw(human, openingHandSize);
    _abilities.draw(opponent, openingHandSize);
    final leadersDisabled = _applyGameStart();
    _randomizeFirstPlayer();
    // White Flame disables every leader, including the passive ones, matching
    // the reference implementation's disableLeader branch.
    if (!leadersDisabled) _applyLeaderStartAbilities();
    _mulliganOpponent();
    state.phase = GamePhase.mulligan;
    Scoring.refresh(state);
    _emit(const MatchStarted());
  }

  void _randomizeFirstPlayer() {
    final humanScoiatael = human.faction == CardFaction.scoiatael;
    final opponentScoiatael = opponent.faction == CardFaction.scoiatael;
    if (humanScoiatael && !opponentScoiatael) {
      // The human Scoia'tael player chooses; the UI defaults to going first.
      state.firstPlayer = human.index;
    } else if (opponentScoiatael && !humanScoiatael) {
      state.firstPlayer = _random.chance(0.5) ? opponent.index : human.index;
    } else {
      state.firstPlayer = _random.chance(0.5) ? human.index : opponent.index;
    }
  }

  /// Applies start-of-game leader rules. Returns true when a White Flame leader
  /// disabled both leaders, so no other leader effect may run.
  bool _applyGameStart() {
    if (human.leader.hasAbility('emhyr_whiteflame') ||
        opponent.leader.hasAbility('emhyr_whiteflame')) {
      human.leaderUsed = true;
      opponent.leaderUsed = true;
      return true;
    }
    return false;
  }

  /// Passive / start-of-game leader abilities.
  void _applyLeaderStartAbilities() {
    for (final player in state.players) {
      final leader = player.leader;
      if (leader.hasAbility('francesca_daisy')) {
        final drawn = _abilities.draw(player, 1);
        if (drawn > 0) {
          _emit(CardsDrawn(player: player.index, count: drawn));
        }
      }
      if (leader.hasAbility('eredin_treacherous')) {
        state.doubleSpyPower = true;
      }
      if (leader.hasAbility('emhyr_invader')) {
        state.randomRespawn = true;
      }
      if (leader.hasAbility('king_bran')) {
        for (final row in state.rowsFor(player.index)) {
          row.halfWeather = true;
        }
      }
    }
  }

  void _mulliganOpponent() {
    _opponentRedraw();
    _opponentRedraw();
  }

  void _opponentRedraw() {
    if (opponent.deck.isEmpty) return;
    final order = _abilities.discardOrder(opponent);
    if (order.isEmpty) return;
    final card = order.first;
    if (card.baseStrength >= 15) return;
    _swapWithDeck(opponent, card);
  }

  void _swapWithDeck(PlayerState player, CardInstance card) {
    if (!player.hand.remove(card)) return;
    player.hand.add(player.deck.removeAt(0));
    player.deck.add(card);
    _random.shuffle(player.deck);
  }

  // ---------------------------------------------------------------------------
  // Round and turn flow
  // ---------------------------------------------------------------------------

  void _startRound() {
    state.roundNumber++;
    for (final row in state.rows) {
      for (final card in row.cards) {
        card.noRemove = false;
      }
    }
    state.currentPlayer = state.roundNumber.isEven
        ? state.firstPlayer
        : state.opponentOf(state.firstPlayer);
    _applyRoundStart();
    for (final player in state.players) {
      if (!player.canPlay()) player.passed = true;
    }
    if (human.passed && opponent.passed) {
      _endRound();
      return;
    }
    if (state.players[state.currentPlayer].passed) {
      state.currentPlayer = state.opponentOf(state.currentPlayer);
    }
    _startTurn();
  }

  void _applyRoundStart() {
    for (final player in state.players) {
      _applyFactionRoundStart(player);
    }
  }

  void _applyFactionRoundStart(PlayerState player) {
    if (player.faction == CardFaction.realms &&
        state.roundNumber > 1 &&
        state.roundHistory.isNotEmpty &&
        state.roundHistory.last.winner == player.index) {
      final drawn = _abilities.draw(player, 1);
      if (drawn > 0) {
        _emit(CardsDrawn(player: player.index, count: drawn));
      }
    }
    if (player.faction == CardFaction.skellige && state.roundNumber == 3) {
      // The reference returns two random units from the graveyard.
      final candidates = player.graveyard.where((c) => c.isUnit).toList();
      if (candidates.isNotEmpty) {
        _random.shuffle(candidates);
        for (final card in candidates.take(2)) {
          player.graveyard.remove(card);
          _abilities.insertSorted(
            _abilities.rowForCard(card, player.index),
            card,
          );
        }
        _emit(
          AbilityTriggered(player: player.index, ability: 'skellige_revive'),
        );
      }
    }
  }

  void _startTurn() {
    final opponentIndex = state.opponentOf(state.currentPlayer);
    if (!state.players[opponentIndex].passed) {
      state.currentPlayer = opponentIndex;
    }
    Scoring.refresh(state);
    _emit(TurnChanged(state.currentPlayer));
  }

  void _endTurn() {
    final player = state.players[state.currentPlayer];
    if (!player.passed && !player.canPlay()) {
      player.passed = true;
      _emit(PlayerPassed(player.index));
    }
    if (human.passed && opponent.passed) {
      _endRound();
      return;
    }
    _startTurn();
  }

  void _endRound() {
    final humanTotal = Scoring.playerTotal(state, human.index);
    final opponentTotal = Scoring.playerTotal(state, opponent.index);
    var diff = humanTotal - opponentTotal;
    if (diff == 0) {
      final humanNilf = human.faction == CardFaction.nilfgaard;
      final opponentNilf = opponent.faction == CardFaction.nilfgaard;
      if (humanNilf != opponentNilf) diff = humanNilf ? 1 : -1;
    }
    final int? winner = diff > 0
        ? human.index
        : (diff < 0 ? opponent.index : null);
    state.roundHistory.add(
      RoundResult(
        round: state.roundNumber,
        scores: [humanTotal, opponentTotal],
        winner: winner,
      ),
    );
    _applyFactionRoundEnd();
    _clearBoard();
    for (final player in state.players) {
      if (winner != null && player.index != winner && !player.isOutOfGems) {
        player.roundsLost++;
      }
      player.passed = false;
      player.isWinning = false;
    }
    _emit(
      RoundEnded(
        round: state.roundNumber,
        winner: winner,
        scores: [humanTotal, opponentTotal],
      ),
    );
    if (human.isOutOfGems || opponent.isOutOfGems) {
      _endGame();
    } else {
      _startRound();
    }
  }

  void _applyFactionRoundEnd() {
    for (final player in state.players) {
      if (player.faction != CardFaction.monsters) continue;
      final units = <CardInstance>[];
      for (final row in state.rowsFor(player.index)) {
        units.addAll(row.cards.where((c) => c.isUnit));
      }
      if (units.isEmpty) continue;
      units[_random.nextInt(units.length)].noRemove = true;
      _emit(AbilityTriggered(player: player.index, ability: 'monsters_keep'));
    }
  }

  void _clearBoard() {
    for (final row in state.rows) {
      for (final card in List.of(row.cards)) {
        if (card.noRemove) continue;
        row.cards.remove(card);
        state.players[card.owner].graveyard.add(card);
      }
      final special = row.special;
      if (special != null) {
        row.special = null;
        if (!special.temporary) {
          state.players[special.owner].graveyard.add(special);
        }
      }
      row.weather = false;
    }
    _abilities.clearWeatherCards();
    _emit(const WeatherChanged({}));
  }

  void _endGame() {
    state.phase = GamePhase.gameOver;
    if (human.isOutOfGems && opponent.isOutOfGems) {
      state.matchWinner = null;
    } else if (human.isOutOfGems) {
      state.matchWinner = opponent.index;
    } else {
      state.matchWinner = human.index;
    }
    _emit(MatchEnded(state.matchWinner));
  }

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  /// Applies a serialized [command].
  ///
  /// Returns [CommandAccepted] or [CommandRejected] with a language-independent
  /// reason. Every state mutation goes through here, so a network or replay
  /// layer can drive the engine with plain data.
  CommandResult apply(GameCommand command) => switch (command) {
    PlayCardCommand() => _applyPlayCard(command),
    ActivateLeaderCommand() => _applyActivateLeader(command),
    PassCommand() => _applyPass(command),
    RedrawCommand() => _applyRedraw(command),
    FinishMulliganCommand() => _applyFinishMulligan(command),
  };

  /// Finds a card anywhere on the table by its instance id.
  CardInstance? cardByUid(int uid) {
    for (final player in state.players) {
      for (final zone in [player.hand, player.deck, player.graveyard]) {
        for (final card in zone) {
          if (card.uid == uid) return card;
        }
      }
    }
    for (final row in state.rows) {
      for (final card in row.cards) {
        if (card.uid == uid) return card;
      }
      final special = row.special;
      if (special != null && special.uid == uid) return special;
    }
    for (final card in state.weatherCards) {
      if (card.uid == uid) return card;
    }
    return null;
  }

  CommandResult _applyPlayCard(PlayCardCommand command) {
    if (state.phase != GamePhase.playing) {
      return const CommandRejected(CommandRejection.wrongPhase);
    }
    if (state.currentPlayer != command.player) {
      return const CommandRejected(CommandRejection.notYourTurn);
    }
    final player = state.players[command.player];
    if (player.passed) {
      return const CommandRejected(CommandRejection.playerPassed);
    }
    final card = cardByUid(command.cardUid);
    if (card == null) {
      return const CommandRejected(CommandRejection.unknownCard);
    }
    if (!player.hand.contains(card)) {
      return const CommandRejected(CommandRejection.cardNotInHand);
    }
    final targetUid = command.targetUid;
    final target = targetUid == null ? null : cardByUid(targetUid);
    if (targetUid != null && target == null) {
      return const CommandRejected(CommandRejection.unknownCard);
    }

    if (card.hasAbility(Ability.decoy)) {
      if (_abilities.decoyTargets(player).isEmpty) {
        return const CommandRejected(CommandRejection.noTarget);
      }
      return _abilities.playDecoy(player, card, target)
          ? const CommandAccepted()
          : const CommandRejected(CommandRejection.noTarget);
    }
    if (card.isSpecial && card.hasAbility(Ability.scorch)) {
      _abilities.resolveGlobalScorch(player);
      _abilities.toGrave(card);
      _emit(CardPlayed(player: command.player, card: card, row: null));
      _endTurn();
      return const CommandAccepted();
    }
    if (card.usesRowSpecialSlot &&
        state
            .rowState(command.player, command.targetRow ?? CardRow.close)
            .hasSpecial) {
      return const CommandRejected(CommandRejection.rowOccupied);
    }

    final row = _abilities.placeCard(player, card, targetRow: command.targetRow);
    _emit(CardPlayed(player: command.player, card: card, row: row?.row));
    _abilities.resolvePlaced(player, card, row, target: target);
    Scoring.refresh(state);
    _endTurn();
    return const CommandAccepted();
  }

  CommandResult _applyActivateLeader(ActivateLeaderCommand command) {
    if (state.phase != GamePhase.playing) {
      return const CommandRejected(CommandRejection.wrongPhase);
    }
    if (state.currentPlayer != command.player) {
      return const CommandRejected(CommandRejection.notYourTurn);
    }
    final player = state.players[command.player];
    if (!player.leaderAvailable) {
      return const CommandRejected(CommandRejection.leaderUnavailable);
    }
    final ability = player.leader.abilities.first;
    if (!Ability.isActiveLeaderAbility(ability)) {
      return const CommandRejected(CommandRejection.leaderUnavailable);
    }
    final targetUid = command.targetUid;
    final deckPickUid = command.deckPickUid;
    _abilities.resolveLeader(
      player,
      ability,
      targetRow: command.targetRow,
      target: targetUid == null ? null : cardByUid(targetUid),
      discard: [for (final uid in command.discardUids) ?cardByUid(uid)],
      deckPick: deckPickUid == null ? null : cardByUid(deckPickUid),
    );
    player.leaderUsed = true;
    _emit(LeaderActivated(player: command.player, ability: ability));
    Scoring.refresh(state);
    _endTurn();
    return const CommandAccepted();
  }

  CommandResult _applyPass(PassCommand command) {
    if (state.phase != GamePhase.playing) {
      return const CommandRejected(CommandRejection.wrongPhase);
    }
    final player = state.players[command.player];
    if (player.passed) {
      return const CommandRejected(CommandRejection.playerPassed);
    }
    player.passed = true;
    _emit(PlayerPassed(command.player));
    if (state.currentPlayer == command.player) {
      _endTurn();
    }
    return const CommandAccepted();
  }

  CommandResult _applyRedraw(RedrawCommand command) {
    if (state.phase != GamePhase.mulligan) {
      return const CommandRejected(CommandRejection.wrongPhase);
    }
    // Only the local seat redraws until the per-seat mulligan lands (#37).
    if (command.player != human.index) {
      return const CommandRejected(CommandRejection.notYourTurn);
    }
    if (humanRedraws >= maxRedraws) {
      return const CommandRejected(CommandRejection.noRedrawsLeft);
    }
    final card = cardByUid(command.cardUid);
    if (card == null) {
      return const CommandRejected(CommandRejection.unknownCard);
    }
    if (human.deck.isEmpty || !human.hand.contains(card)) {
      return const CommandRejected(CommandRejection.cardNotInHand);
    }
    humanRedraws++;
    _swapWithDeck(human, card);
    return const CommandAccepted();
  }

  CommandResult _applyFinishMulligan(FinishMulliganCommand command) {
    if (state.phase != GamePhase.mulligan) {
      return const CommandRejected(CommandRejection.wrongPhase);
    }
    if (command.player != human.index) {
      return const CommandRejected(CommandRejection.notYourTurn);
    }
    state.phase = GamePhase.playing;
    _startRound();
    return const CommandAccepted();
  }

  // ---------------------------------------------------------------------------
  // Convenience wrappers used by the single-player UI
  // ---------------------------------------------------------------------------

  /// Whether [card] can currently be played by [playerIndex].
  ///
  /// Used by the UI to dim unplayable cards; the real validation happens in
  /// [_applyPlayCard].
  bool canPlayCard(int playerIndex, CardInstance card) {
    if (state.phase != GamePhase.playing) return false;
    if (state.currentPlayer != playerIndex) return false;
    final player = state.players[playerIndex];
    if (player.passed || !player.hand.contains(card)) return false;
    if (card.hasAbility(Ability.decoy)) {
      return _abilities.decoyTargets(player).isNotEmpty;
    }
    return true;
  }

  bool playCard(
    int playerIndex,
    CardInstance card, {
    CardRow? targetRow,
    CardInstance? target,
  }) => apply(
    PlayCardCommand(
      player: playerIndex,
      cardUid: card.uid,
      targetRow: targetRow,
      targetUid: target?.uid,
    ),
  ).accepted;

  void pass(int playerIndex) => apply(PassCommand(playerIndex));

  bool activateLeader(
    int playerIndex, {
    CardRow? targetRow,
    CardInstance? target,
    List<CardInstance>? discard,
    CardInstance? deckPick,
  }) => apply(
    ActivateLeaderCommand(
      player: playerIndex,
      targetRow: targetRow,
      targetUid: target?.uid,
      discardUids: [for (final card in discard ?? const []) card.uid],
      deckPickUid: deckPick?.uid,
    ),
  ).accepted;

  bool redraw(int playerIndex, CardInstance card) =>
      apply(RedrawCommand(player: playerIndex, cardUid: card.uid)).accepted;

  void finishMulligan() => apply(FinishMulliganCommand(human.index));
}
