import '../../core/models/card.dart';

/// Maps card definitions to the bundled asset paths.
///
/// Artwork and icon sprites come from the reference game art; they are copied
/// into `assets/` so the app never depends on the ignored reference checkout.
abstract final class CardAssets {
  static String art(CardDefinition card) =>
      'assets/cards/${card.artFilename}.jpg';

  static String? rowIcon(CardRow row) {
    if (!row.isUnitRow) return null;
    return 'assets/icons/card_row_${row.name}.png';
  }

  /// Sprite used for the circular strength badge.
  static String powerBadge(CardDefinition card) {
    if (card.isHero) return 'assets/icons/power_hero.png';
    if (card.isWeather || card.isSpecial) {
      final ability = card.abilities.isEmpty ? '' : card.abilities.first;
      return 'assets/icons/power_${_powerSuffix(ability)}.png';
    }
    return 'assets/icons/power_normal.png';
  }

  static String _powerSuffix(String ability) => switch (ability) {
    Ability.frost => 'frost',
    Ability.fog => 'fog',
    Ability.rain => 'rain',
    Ability.storm => 'storm',
    Ability.clear => 'clear',
    Ability.decoy => 'decoy',
    Ability.scorch => 'scorch',
    Ability.horn => 'horn',
    Ability.mardroeme => 'mardroeme',
    _ => 'normal',
  };

  /// Small ability badge shown over the artwork, or null when there is none.
  static String? abilityIcon(CardDefinition card) {
    if (card.isLeader || card.isWeather || card.isSpecial) return null;
    String? ability;
    for (final candidate in card.abilities.reversed) {
      if (candidate == Ability.hero) continue;
      ability = candidate;
      break;
    }
    if (ability == null) {
      return card.row == CardRow.agile
          ? 'assets/icons/card_ability_agile.png'
          : null;
    }
    return 'assets/icons/card_ability_${_abilitySuffix(ability)}.png';
  }

  static String _abilitySuffix(String ability) => switch (ability) {
    Ability.scorchClose ||
    Ability.scorchRanged ||
    Ability.scorchSiege => 'scorch',
    Ability.avengerKambi => 'avenger',
    _ => ability,
  };

  static String gemOn() => 'assets/icons/icon_gem_on.png';
  static String gemOff() => 'assets/icons/icon_gem_off.png';
}
