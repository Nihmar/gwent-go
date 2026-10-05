import '../data/card_repository.dart';
import '../models/card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'game_event.dart';
import 'game_random.dart';
import 'scoring.dart';

part 'game_engine_abilities.dart';

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
      state.phase == GamePhase.playing &&
      state.currentPlayer == opponent.index;

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
          CardInstance(uid: nextUid(), definition: definition, owner: player.index),
        );
      }
    });
    _random.shuffle(player.deck);
  }

  /// Draws opening hands, applies start-of-game abilities and enters mulligan.
  void startMatch() {
    _abilities.draw(human, openingHandSize);
    _abilities.draw(opponent, openingHandSize);
    _applyGameStart();
    _randomizeFirstPlayer();
    _applyLeaderStartAbilities();
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

  void _applyGameStart() {
    if (human.leader.hasAbility('emhyr_whiteflame') ||
        opponent.leader.hasAbility('emhyr_whiteflame')) {
      human.leaderUsed = true;
      opponent.leaderUsed = true;
    }
  }

  /// Passive / start-of-game leader abilities.
  void _applyLeaderStartAbilities() {
    for (final player in state.players) {
      final leader = player.leader;
      if (leader.hasAbility('francesca_daisy')) {
        _abilities.draw(player, 1);
        _emit(CardsDrawn(player: player.index, count: 1));
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

  /// Human mulligan: swaps a single card. Returns false when none remain.
  bool redraw(int playerIndex, CardInstance card) {
    if (state.phase != GamePhase.mulligan) return false;
    if (playerIndex != human.index) return false;
    if (humanRedraws >= maxRedraws) return false;
    if (human.deck.isEmpty || !human.hand.contains(card)) return false;
    humanRedraws++;
    _swapWithDeck(human, card);
    return true;
  }

  void finishMulligan() {
    if (state.phase != GamePhase.mulligan) return;
    state.phase = GamePhase.playing;
    _startRound();
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
      if (_abilities.draw(player, 1)) {
        _emit(CardsDrawn(player: player.index, count: 1));
      }
    }
    if (player.faction == CardFaction.skellige && state.roundNumber == 3) {
      final revived = player.graveyard.where((c) => c.isUnit).toList()
        ..sort((a, b) => b.baseStrength.compareTo(a.baseStrength));
      for (final card in revived.take(2)) {
        player.graveyard.remove(card);
        _abilities.insertSorted(
          _abilities.rowForCard(card, player.index),
          card,
        );
      }
      if (revived.isNotEmpty) {
        _emit(AbilityTriggered(player: player.index, ability: 'skellige_revive'));
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
        state.players[special.owner].graveyard.add(special);
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
  // Public actions
  // ---------------------------------------------------------------------------

  /// Whether [card] can currently be played by [playerIndex].
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
  }) {
    if (!canPlayCard(playerIndex, card)) return false;
    final player = state.players[playerIndex];

    if (card.hasAbility(Ability.decoy)) {
      return _abilities.playDecoy(player, card, target);
    }
    if (card.isSpecial && card.hasAbility(Ability.scorch)) {
      _abilities.resolveGlobalScorch(player);
      _abilities.toGrave(card);
      _emit(CardPlayed(player: playerIndex, card: card, row: null));
      _endTurn();
      return true;
    }

    if (card.usesRowSpecialSlot &&
        state.rowState(playerIndex, targetRow ?? CardRow.close).hasSpecial) {
      return false;
    }

    final row = _abilities.placeCard(player, card, targetRow: targetRow);
    _emit(CardPlayed(player: playerIndex, card: card, row: row?.row));
    _abilities.resolvePlaced(player, card, row, target: target);
    Scoring.refresh(state);
    _endTurn();
    return true;
  }

  void pass(int playerIndex) {
    if (state.phase != GamePhase.playing) return;
    final player = state.players[playerIndex];
    if (player.passed) return;
    player.passed = true;
    _emit(PlayerPassed(playerIndex));
    if (state.currentPlayer == playerIndex) {
      _endTurn();
    }
  }

  bool activateLeader(
    int playerIndex, {
    CardRow? targetRow,
    CardInstance? target,
  }) {
    if (state.phase != GamePhase.playing) return false;
    if (state.currentPlayer != playerIndex) return false;
    final player = state.players[playerIndex];
    if (!player.leaderAvailable) return false;
    final ability = player.leader.abilities.first;
    if (!Ability.isActiveLeaderAbility(ability)) return false;
    _abilities.resolveLeader(
      player,
      ability,
      targetRow: targetRow,
      target: target,
    );
    player.leaderUsed = true;
    _emit(LeaderActivated(player: playerIndex, ability: ability));
    Scoring.refresh(state);
    _endTurn();
    return true;
  }
}
