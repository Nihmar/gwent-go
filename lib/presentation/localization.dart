import 'package:flutter/widgets.dart';

import '../core/data/faction_catalog.dart';
import '../core/models/card.dart';
import '../core/models/player.dart';
import '../l10n/generated/app_localizations.dart';

/// Localized names for domain enums and card abilities.
///
/// Game-domain identifiers stay language independent; this extension is the
/// only place where they are turned into user-facing text.
extension GwentLocalizations on AppLocalizations {
  String rowName(CardRow row) => switch (row) {
    CardRow.close => rowClose,
    CardRow.ranged => rowRanged,
    CardRow.siege => rowSiege,
    CardRow.agile => rowAgile,
    CardRow.weather => rowWeather,
    CardRow.special => cardTypeSpecial,
    CardRow.leader => cardTypeLeader,
  };

  String factionName(CardFaction faction) {
    final info = factionCatalog[faction];
    if (info == null) return faction.name;
    return _lookup(info.nameKey);
  }

  String factionAbilityDescription(CardFaction faction) {
    final info = factionCatalog[faction];
    if (info == null) return '';
    return _lookup(info.abilityKey);
  }

  String difficultyName(Difficulty difficulty) {
    if (difficulty == Difficulty.easy) return easy;
    if (difficulty == Difficulty.hard) return hard;
    return normal;
  }

  String difficultyDescription(Difficulty difficulty) {
    if (difficulty == Difficulty.easy) return difficultyEasyDescription;
    if (difficulty == Difficulty.hard) return difficultyHardDescription;
    return difficultyNormalDescription;
  }

  /// Human readable description of a card ability.
  String abilityDescription(String ability) => switch (ability) {
    Ability.hero => abilityHero,
    Ability.decoy => abilityDecoy,
    Ability.horn => abilityHorn,
    Ability.mardroeme => abilityMardroeme,
    Ability.berserker => abilityBerserker,
    Ability.scorch => abilityScorch,
    Ability.scorchClose => abilityScorchClose,
    Ability.scorchRanged => abilityScorchRanged,
    Ability.scorchSiege => abilityScorchSiege,
    Ability.agile => abilityAgile,
    Ability.muster => abilityMuster,
    Ability.spy => abilitySpy,
    Ability.medic => abilityMedic,
    Ability.morale => abilityMorale,
    Ability.bond => abilityBond,
    Ability.avenger || Ability.avengerKambi => abilityAvenger,
    Ability.frost => abilityFrost,
    Ability.fog => abilityFog,
    Ability.rain => abilityRain,
    Ability.storm => abilityStorm,
    Ability.clear => abilityClear,
    'foltest_king' => leaderFoltestKing,
    'foltest_lord' => leaderFoltestLord,
    'foltest_siegemaster' => leaderFoltestSiegemaster,
    'foltest_steelforged' => leaderFoltestSteelforged,
    'foltest_son' => leaderFoltestSon,
    'emhyr_imperial' => leaderEmhyrImperial,
    'emhyr_emperor' => leaderEmhyrEmperor,
    'emhyr_whiteflame' => leaderEmhyrWhiteflame,
    'emhyr_relentless' => leaderEmhyrRelentless,
    'emhyr_invader' => leaderEmhyrInvader,
    'eredin_commander' => leaderEredinCommander,
    'eredin_bringer_of_death' => leaderEredinBringer,
    'eredin_destroyer' => leaderEredinDestroyer,
    'eredin_king' => leaderEredinKing,
    'eredin_treacherous' => leaderEredinTreacherous,
    'francesca_queen' => leaderFrancescaQueen,
    'francesca_beautiful' => leaderFrancescaBeautiful,
    'francesca_daisy' => leaderFrancescaDaisy,
    'francesca_pureblood' => leaderFrancescaPureblood,
    'francesca_hope' => leaderFrancescaHope,
    'crach_an_craite' => leaderCrachAnCraite,
    'king_bran' => leaderKingBran,
    _ => '',
  };

  /// Full description of a card: type line followed by its abilities.
  String cardDescription(CardDefinition card) {
    if (card.isLeader) {
      return card.abilities.isEmpty
          ? ''
          : abilityDescription(card.abilities.first);
    }
    if (card.isWeather) {
      return card.abilities
          .map(abilityDescription)
          .where((s) => s.isNotEmpty)
          .join(' ');
    }
    final parts = <String>[];
    if (card.isHero) parts.add(abilityHero);
    for (final ability in card.abilities) {
      if (ability == Ability.hero) continue;
      final text = abilityDescription(ability);
      if (text.isNotEmpty) parts.add(text);
    }
    if (card.row == CardRow.agile && !card.abilities.contains(Ability.agile)) {
      parts.add(abilityAgile);
    }
    return parts.join(' ');
  }

  String _lookup(String key) => switch (key) {
    'factionRealms' => factionRealms,
    'factionNilfgaard' => factionNilfgaard,
    'factionMonsters' => factionMonsters,
    'factionScoiatael' => factionScoiatael,
    'factionSkellige' => factionSkellige,
    'factionAbilityRealms' => factionAbilityRealms,
    'factionAbilityNilfgaard' => factionAbilityNilfgaard,
    'factionAbilityMonsters' => factionAbilityMonsters,
    'factionAbilityScoiatael' => factionAbilityScoiatael,
    'factionAbilitySkellige' => factionAbilitySkellige,
    _ => key,
  };
}

/// Convenience accessor for [AppLocalizations] from a build context.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this);
}
