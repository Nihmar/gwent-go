import '../data/card_repository.dart';
import '../models/card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../rules/game_engine.dart';
import '../rules/scoring.dart';
import 'ai.dart';

/// A scored AI option.
class AiCandidate {
  const AiCandidate(this.weight, this.action);

  final double weight;
  final AiAction action;
}

/// Heuristic evaluation of the position, shared by every difficulty.
///
/// The evaluator temporarily mutates the board to measure the exact effect of
/// a card (mirroring the reference AI), always restoring state afterwards.
class AiEvaluator {
  AiEvaluator(this.engine, this.playerIndex);

  final GameEngine engine;
  final int playerIndex;

  GameState get state => engine.state;
  PlayerState get player => state.players[playerIndex];
  PlayerState get opponent => state.players[state.opponentOf(playerIndex)];

  int get playerTotal => Scoring.playerTotal(state, player.index);
  int get opponentTotal => Scoring.playerTotal(state, opponent.index);
  int get scoreDifference => opponentTotal - playerTotal;

  List<AiCandidate> candidates() {
    final result = <AiCandidate>[];
    for (final card in player.hand) {
      final option = evaluateCard(card);
      if (option.$1.isFinite && option.$1 >= 0) {
        result.add(AiCandidate(option.$1, option.$2));
      }
    }
    final leader = leaderCandidate();
    if (leader != null) result.add(leader);
    result.add(AiCandidate(passWeight(), const AiPass()));
    return result;
  }

  // ---------------------------------------------------------------------------
  // Cards
  // ---------------------------------------------------------------------------

  (double, AiPlayCard) evaluateCard(CardInstance card) {
    if (card.isSpecial && card.hasAbility(Ability.scorch)) {
      return (_globalScorchValue(), AiPlayCard(card));
    }
    if (card.hasAbility(Ability.decoy)) {
      return (_decoyValue(), AiPlayCard(card, target: _bestDecoyTarget()));
    }
    if (card.isWeather) {
      return (_weatherValue(card), AiPlayCard(card));
    }
    if (card.usesRowSpecialSlot) {
      if (card.hasAbility(Ability.mardroeme)) {
        final row = _bestMardroemeRow();
        return (_mardroemeValue(row), AiPlayCard(card, targetRow: row?.row));
      }
      final row = _bestHornRow();
      return (_hornValueOf(row), AiPlayCard(card, targetRow: row?.row));
    }

    final placement = _bestUnitPlacement(card);
    var weight = placement.$1;
    if (card.hasAbility(Ability.spy)) {
      weight += 15;
    }
    if (card.hasAbility(Ability.muster)) weight *= 3;
    if (card.hasAbility(Ability.medic)) weight += _medicValue();
    if (card.hasAbility(Ability.scorchClose)) {
      weight += _rowScorchValue(CardRow.close);
    } else if (card.hasAbility(Ability.scorchRanged)) {
      weight += _rowScorchValue(CardRow.ranged);
    } else if (card.hasAbility(Ability.scorchSiege)) {
      weight += _rowScorchValue(CardRow.siege);
    }
    if (card.hasAbility(Ability.berserker)) weight += _berserkerValue();
    if (card.hasAbility(Ability.avenger)) weight += 10;
    if (card.hasAbility(Ability.avengerKambi)) weight += 10;
    return (weight, AiPlayCard(card, targetRow: placement.$2));
  }

  /// Returns the projected value of playing [card] as a unit and the row it
  /// should be placed on (non-null only for Agile cards).
  (double, CardRow?) _bestUnitPlacement(CardInstance card) {
    if (card.hasAbility(Ability.spy)) {
      final row = state.rowState(
        state.opponentOf(playerIndex),
        _combatRow(card),
      );
      return (_strengthIn(row, card), null);
    }
    if (card.row == CardRow.agile) {
      var best = -1.0;
      CardRow? bestRow;
      for (final row in [CardRow.close, CardRow.ranged]) {
        final value = _addDelta(state.rowState(playerIndex, row), card);
        if (value > best) {
          best = value;
          bestRow = row;
        }
      }
      return (best, bestRow);
    }
    final row = state.rowState(playerIndex, _combatRow(card));
    return (_addDelta(row, card), null);
  }

  CardRow _combatRow(CardInstance card) =>
      card.row.isCombat ? card.row : CardRow.close;

  double _strengthIn(RowState row, CardInstance card) =>
      Scoring.cardStrength(state, row, card).toDouble();

  /// Row total change of adding [card] to [row], restoring the row afterwards.
  double _addDelta(RowState row, CardInstance card) {
    final before = Scoring.rowTotal(state, row);
    row.cards.add(card);
    try {
      return (Scoring.rowTotal(state, row) - before).toDouble();
    } finally {
      row.cards.remove(card);
    }
  }

  // ---------------------------------------------------------------------------
  // Specific abilities
  // ---------------------------------------------------------------------------

  double _decoyValue() {
    final target = _bestDecoyTarget();
    if (target == null) return 0;
    return target.currentStrength + 5;
  }

  CardInstance? _bestDecoyTarget() {
    CardInstance? best;
    for (final row in state.rows) {
      for (final card in row.cards) {
        if (!card.isUnit || card.owner != player.index) continue;
        if (best == null || card.currentStrength > best.currentStrength) {
          best = card;
        }
      }
    }
    return best;
  }

  double _medicValue() {
    final units = player.graveyard.where((c) => c.isUnit).toList();
    if (units.isEmpty) return 0;
    return units
        .map((c) => c.baseStrength.toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  double _berserkerValue() {
    final hasMardroeme =
        player.hand.any((c) => c.hasAbility(Ability.mardroeme)) ||
        state
            .rowsFor(player.index)
            .any((r) => r.special?.hasAbility(Ability.mardroeme) ?? false);
    return hasMardroeme ? 14 : 2;
  }

  double _weatherValue(CardInstance card) {
    final previous = Set<String>.of(state.activeWeather);
    if (card.hasAbility(Ability.clear)) {
      final beforeOpponent = opponentTotal;
      final beforePlayer = playerTotal;
      state.activeWeather.clear();
      Scoring.refresh(state);
      final gain =
          (beforeOpponent - opponentTotal) - (beforePlayer - playerTotal);
      _restoreWeather(previous);
      if (state.activeWeather.isEmpty && gain == 0) return 1;
      return gain.toDouble();
    }
    final beforeOpponent = opponentTotal;
    final beforePlayer = playerTotal;
    var changed = false;
    for (final ability in card.abilities.where(Ability.isWeather)) {
      if (state.activeWeather.add(ability)) changed = true;
    }
    if (!changed) return 1;
    Scoring.refresh(state);
    final gain =
        (beforeOpponent - opponentTotal) - (beforePlayer - playerTotal);
    _restoreWeather(previous);
    return gain.toDouble();
  }

  void _restoreWeather(Set<String> previous) {
    state.activeWeather
      ..clear()
      ..addAll(previous);
    Scoring.refresh(state);
  }

  double _rowScorchValue(CardRow row) {
    final target = state.rowState(state.opponentOf(playerIndex), row);
    if (Scoring.rowTotal(state, target) < 10) return 0;
    final units = Scoring.strongestUnits(state, target);
    return units
        .map((c) => c.currentStrength.toDouble())
        .fold(0.0, (a, b) => a + b);
  }

  double _globalScorchValue() {
    double strongest(int owner) {
      var best = 0;
      for (final row in state.rowsFor(owner)) {
        for (final unit in Scoring.strongestUnits(state, row)) {
          final value = Scoring.cardStrength(state, row, unit);
          if (value > best) best = value;
        }
      }
      return best.toDouble();
    }

    double totalAt(int owner, double power) {
      var total = 0.0;
      for (final row in state.rowsFor(owner)) {
        for (final unit in Scoring.strongestUnits(state, row)) {
          if (Scoring.cardStrength(state, row, unit) == power) {
            total += power;
          }
        }
      }
      return total;
    }

    final powerPlayer = strongest(player.index);
    final powerOpponent = strongest(opponent.index);
    if (powerPlayer > powerOpponent) {
      return 0;
    }
    if (powerPlayer < powerOpponent) {
      return totalAt(opponent.index, powerOpponent);
    }
    return (totalAt(opponent.index, powerOpponent) -
            totalAt(player.index, powerPlayer))
        .clamp(0, double.infinity)
        .toDouble();
  }

  double _mardroemeValue(RowState? row) {
    if (row == null) return 1;
    final berserkers = row.cards
        .where((c) => c.hasAbility(Ability.berserker))
        .length;
    if (berserkers == 0) return 1;
    return (berserkers * berserkers * 8).toDouble();
  }

  RowState? _bestMardroemeRow() {
    RowState? best;
    var bestValue = 0.0;
    for (final row in state.rowsFor(player.index)) {
      if (row.hasSpecial) continue;
      final value = _mardroemeValue(row);
      if (value > bestValue) {
        bestValue = value;
        best = row;
      }
    }
    return best;
  }

  double _hornValueOf(RowState? row) {
    if (row == null || row.hasSpecial) return 0;
    final before = Scoring.rowTotal(state, row);
    row.special = CardInstance(
      uid: -1,
      definition: CardRepository.byId('horn'),
      owner: playerIndex,
    );
    try {
      return (Scoring.rowTotal(state, row) - before).toDouble();
    } finally {
      row.special = null;
    }
  }

  RowState? _bestHornRow() {
    RowState? best;
    var bestValue = 0.0;
    for (final row in state.rowsFor(player.index)) {
      final value = _hornValueOf(row);
      if (value > bestValue) {
        bestValue = value;
        best = row;
      }
    }
    return best;
  }

  // ---------------------------------------------------------------------------
  // Passing and leaders
  // ---------------------------------------------------------------------------

  double passWeight() {
    if (player.roundsWon == 1) return 0;
    final difference = scoreDifference;
    if (difference > 30) return 100;
    if (difference < -30 && opponent.hand.length - player.hand.length > 2) {
      return 100;
    }
    return difference.abs().toDouble();
  }

  AiCandidate? leaderCandidate() {
    if (!player.leaderAvailable) return null;
    final ability = player.leader.abilities.first;
    if (!Ability.isActiveLeaderAbility(ability)) return null;
    return _leaderCandidate(ability);
  }

  AiCandidate? _leaderCandidate(String ability) {
    switch (ability) {
      case 'foltest_siegemaster':
      case 'eredin_commander':
      case 'francesca_beautiful':
        final row = ability == 'foltest_siegemaster'
            ? CardRow.siege
            : ability == 'eredin_commander'
            ? CardRow.close
            : CardRow.ranged;
        final value = _hornValueOf(state.rowState(player.index, row));
        return AiCandidate(value, AiActivateLeader(targetRow: row));
      case 'foltest_steelforged':
        return AiCandidate(
          _rowScorchValue(CardRow.siege),
          const AiActivateLeader(),
        );
      case 'foltest_son':
        return AiCandidate(
          _rowScorchValue(CardRow.ranged),
          const AiActivateLeader(),
        );
      case 'francesca_queen':
        return AiCandidate(
          _rowScorchValue(CardRow.close),
          const AiActivateLeader(),
        );
      case 'foltest_king':
        return AiCandidate(
          _weatherValue(_weatherById(Ability.fog)),
          const AiActivateLeader(),
        );
      case 'emhyr_imperial':
        return AiCandidate(
          _weatherValue(_weatherById(Ability.rain)),
          const AiActivateLeader(),
        );
      case 'francesca_pureblood':
        return AiCandidate(
          _weatherValue(_weatherById(Ability.frost)),
          const AiActivateLeader(),
        );
      case 'eredin_king':
        final best = _bestWeatherInDeck();
        return AiCandidate(best, const AiActivateLeader());
      case 'eredin_bringer_of_death':
        return AiCandidate(_medicValue(), const AiActivateLeader());
      case 'emhyr_relentless':
        final units = opponent.graveyard.where((c) => c.isUnit);
        final value = units.isEmpty
            ? 0.0
            : units
                  .map((c) => c.baseStrength.toDouble())
                  .reduce((a, b) => a > b ? a : b);
        return AiCandidate(value, const AiActivateLeader());
      case 'eredin_destroyer':
        return AiCandidate(20, const AiActivateLeader());
      case 'crach_an_craite':
        return AiCandidate(
          (player.graveyard.where((c) => c.isUnit).length * 4).toDouble(),
          const AiActivateLeader(),
        );
      default:
        return AiCandidate(
          10.0 + (state.roundNumber - 1) * 15,
          const AiActivateLeader(),
        );
    }
  }

  double _bestWeatherInDeck() {
    var best = 0.0;
    for (final card in player.deck.where((c) => c.isWeather)) {
      final value = _weatherValue(card);
      if (value > best) best = value;
    }
    return best;
  }

  CardInstance _weatherById(String ability) {
    final id = switch (ability) {
      Ability.fog => 'fog',
      Ability.rain => 'rain',
      _ => 'frost',
    };
    return CardInstance(
      uid: -1,
      definition: CardRepository.byId(id),
      owner: playerIndex,
    );
  }
}
