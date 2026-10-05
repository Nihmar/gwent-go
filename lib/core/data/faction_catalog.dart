import '../models/card.dart';

/// Presentation metadata for a playable faction.
///
/// Text is referenced through localization keys, never hard-coded.
class FactionInfo {
  const FactionInfo({
    required this.faction,
    required this.nameKey,
    required this.abilityKey,
  });

  final CardFaction faction;
  final String nameKey;
  final String abilityKey;

  String get shieldAsset => 'assets/icons/deck_shield_${faction.name}.png';
  String get heroAsset => 'assets/factions/faction_${faction.name}.jpg';
  String get deckBackAsset => 'assets/icons/deck_back_${faction.name}.jpg';
}

/// Factions that can be selected on the home screen and in the deck editor.
const List<CardFaction> playableFactions = [
  CardFaction.realms,
  CardFaction.nilfgaard,
  CardFaction.monsters,
  CardFaction.scoiatael,
  CardFaction.skellige,
];

const Map<CardFaction, FactionInfo> factionCatalog = {
  CardFaction.realms: FactionInfo(
    faction: CardFaction.realms,
    nameKey: 'factionRealms',
    abilityKey: 'factionAbilityRealms',
  ),
  CardFaction.nilfgaard: FactionInfo(
    faction: CardFaction.nilfgaard,
    nameKey: 'factionNilfgaard',
    abilityKey: 'factionAbilityNilfgaard',
  ),
  CardFaction.monsters: FactionInfo(
    faction: CardFaction.monsters,
    nameKey: 'factionMonsters',
    abilityKey: 'factionAbilityMonsters',
  ),
  CardFaction.scoiatael: FactionInfo(
    faction: CardFaction.scoiatael,
    nameKey: 'factionScoiatael',
    abilityKey: 'factionAbilityScoiatael',
  ),
  CardFaction.skellige: FactionInfo(
    faction: CardFaction.skellige,
    nameKey: 'factionSkellige',
    abilityKey: 'factionAbilitySkellige',
  ),
};

FactionInfo factionInfo(CardFaction faction) => factionCatalog[faction]!;
