import '../models/card.dart';
import '../models/game_state.dart';
import '../models/player.dart';

/// Pure strength computation for cards, rows and players.
///
/// The formulas mirror the classic Gwent rules: weather clamps units to 1,
/// Tight Bond multiplies by the number of same-named bonded cards, Morale adds
/// +1 per other Morale card and Commander's Horn doubles the row.
abstract final class Scoring {
  /// Number of Commander's Horn effects present in [row].
  static int hornCount(RowState row) {
    var count = row.cards.where((c) => c.hasAbility(Ability.horn)).length;
    if (row.special?.hasAbility(Ability.horn) ?? false) count++;
    return count;
  }

  /// Number of Morale cards in [row].
  static int moraleCount(RowState row) =>
      row.cards.where((c) => c.hasAbility(Ability.morale)).length;

  /// Number of Tight Bond cards sharing [card]'s name in [row].
  static int bondCount(RowState row, CardInstance card) => row.cards
      .where((c) => c.hasAbility(Ability.bond) && c.name == card.name)
      .length;

  /// Strength of [card] as placed in [row].
  ///
  /// Heroes are immune to every modifier and Decoy is always worth zero.
  static int cardStrength(GameState state, RowState row, CardInstance card) {
    if (card.hasAbility(Ability.decoy)) return 0;
    var total = card.baseStrength;
    if (card.isHero) return total;

    if (row.weather && card.isUnit) {
      if (row.halfWeather) {
        total = total <= 1 ? total : (total + 1) ~/ 2;
      } else {
        total = total < 1 ? total : 1;
      }
    }

    if (state.doubleSpyPower && card.hasAbility(Ability.spy)) {
      total *= 2;
    }

    final bond = bondCount(row, card);
    if (bond > 1) total *= bond;

    final morale = moraleCount(row) - (card.hasAbility(Ability.morale) ? 1 : 0);
    if (morale > 0) total += morale;

    final horn = hornCount(row) - (card.hasAbility(Ability.horn) ? 1 : 0);
    if (horn > 0) total *= 2;

    return total;
  }

  static int rowTotal(GameState state, RowState row) {
    var total = 0;
    for (final card in row.cards) {
      total += cardStrength(state, row, card);
    }
    return total;
  }

  static int playerTotal(GameState state, int owner) {
    var total = 0;
    for (final row in state.rowsFor(owner)) {
      total += rowTotal(state, row);
    }
    return total;
  }

  /// Returns the strongest non-hero units in [row], all of them on a tie.
  static List<CardInstance> strongestUnits(GameState state, RowState row) {
    final units = row.cards.where((c) => c.isUnit).toList();
    if (units.isEmpty) return const [];
    var best = -1;
    final result = <CardInstance>[];
    for (final unit in units) {
      final value = cardStrength(state, row, unit);
      if (value > best) {
        best = value;
        result
          ..clear()
          ..add(unit);
      } else if (value == best) {
        result.add(unit);
      }
    }
    return result;
  }

  /// Recomputes weather flags and the displayed strength of every card.
  ///
  /// Mutates only presentation-visible values ([CardInstance.currentStrength]
  /// and [RowState.weather]); the scoring formulas themselves are pure.
  static void refresh(GameState state) {
    for (final row in state.rows) {
      row.weather = state.activeWeather.any((type) {
        final rows = Ability.weatherRows[type];
        return rows != null && rows.contains(row.row);
      });
    }
    for (final player in state.players) {
      for (final row in state.rowsFor(player.index)) {
        for (final card in row.cards) {
          card.currentStrength = cardStrength(state, row, card);
        }
      }
    }
  }

  /// All battlefield units (both sides) that are not heroes.
  static List<CardInstance> allBattlefieldUnits(GameState state) => [
    for (final row in state.rows) ...row.cards.where((c) => c.isUnit),
  ];
}
