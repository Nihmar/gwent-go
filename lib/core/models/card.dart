/// Card-domain definitions shared by the rules engine, the AI and the UI.
///
/// Nothing in this file depends on Flutter: the game engine must stay
/// platform independent so it can be reused for future multiplayer support.
library;

/// The six combat rows plus the two non-combat positions.
enum CardRow {
  close,
  ranged,
  siege,
  agile,
  weather,
  special,
  leader;

  /// Rows that hold regular unit cards once placed on the battlefield.
  bool get isCombat => this == close || this == ranged || this == siege;

  /// `agile` cards may be placed on either [close] or [ranged].
  bool get isUnitRow => isCombat || this == agile;

  /// Rows a card can be placed on, before any ability constraints.
  static const List<CardRow> combatRows = [close, ranged, siege];
}

/// The origin group of a card, used for deck building legality.
enum CardFaction {
  realms,
  nilfgaard,
  monsters,
  scoiatael,
  skellige,
  neutral,
  special,
  weather;

  bool get isPlayableFaction => this != special && this != weather;
}

/// Ability identifiers. These values are language-independent: user-facing
/// text is looked up in the localization layer using these keys.
abstract final class Ability {
  static const hero = 'hero';
  static const decoy = 'decoy';
  static const horn = 'horn';
  static const mardroeme = 'mardroeme';
  static const berserker = 'berserker';
  static const scorch = 'scorch';
  static const scorchClose = 'scorch_c';
  static const scorchRanged = 'scorch_r';
  static const scorchSiege = 'scorch_s';
  static const agile = 'agile';
  static const muster = 'muster';
  static const spy = 'spy';
  static const medic = 'medic';
  static const morale = 'morale';
  static const bond = 'bond';
  static const avenger = 'avenger';
  static const avengerKambi = 'avenger_kambi';

  static const frost = 'frost';
  static const fog = 'fog';
  static const rain = 'rain';
  static const clear = 'clear';

  /// Weather abilities mapped to the combat rows they affect.
  static const Map<String, List<CardRow>> weatherRows = {
    frost: [CardRow.close],
    fog: [CardRow.ranged],
    rain: [CardRow.siege],
  };

  static bool isWeather(String id) => weatherRows.containsKey(id);

  /// Leader abilities that can be activated during the player's turn.
  static const Set<String> activeLeaderAbilities = {
    'foltest_king',
    'foltest_lord',
    'foltest_siegemaster',
    'foltest_steelforged',
    'foltest_son',
    'emhyr_imperial',
    'emhyr_emperor',
    'emhyr_relentless',
    'eredin_commander',
    'eredin_bringer_of_death',
    'eredin_destroyer',
    'eredin_king',
    'francesca_queen',
    'francesca_beautiful',
    'francesca_pureblood',
    'francesca_hope',
    'crach_an_craite',
  };

  /// Leader abilities that run automatically (at the start of the game or of a
  /// round) and are never activated by the player.
  static const Set<String> passiveLeaderAbilities = {
    'emhyr_whiteflame',
    'emhyr_invader',
    'eredin_treacherous',
    'francesca_daisy',
    'king_bran',
  };

  static bool isActiveLeaderAbility(String id) =>
      activeLeaderAbilities.contains(id);
}

/// Immutable definition of a single card, as printed on the card.
class CardDefinition {
  const CardDefinition({
    required this.id,
    required this.name,
    required this.faction,
    required this.row,
    required this.baseStrength,
    required this.artFilename,
    this.abilities = const [],
    this.maxCopies = 1,
  });

  /// Stable, language-independent identifier (unique across the catalog).
  final String id;

  /// Proper noun shown on the card; not localized.
  final String name;

  final CardFaction faction;
  final CardRow row;
  final int baseStrength;

  /// Artwork file name without extension, e.g. `realms_blue_stripes`.
  final String artFilename;

  /// Language-independent ability identifiers (see [Ability]).
  final List<String> abilities;

  /// Maximum number of copies allowed in an owned collection.
  final int maxCopies;

  bool get isHero => abilities.contains(Ability.hero);

  bool get isLeader => row == CardRow.leader;

  bool get isWeather => faction == CardFaction.weather;

  bool get isSpecial => faction == CardFaction.special;

  /// A combat unit that is not a hero.
  bool get isUnit =>
      !isHero && (row.isUnitRow) && !isWeather && !isSpecial && !isLeader;

  /// True when the card is placed in a row's special (horn / mardroeme) slot.
  ///
  /// Only Special-faction cards use that slot: units such as Dandelion or
  /// Ermion that merely carry the horn / mardroeme ability occupy a normal
  /// card position.
  bool get usesRowSpecialSlot =>
      isSpecial && (hasAbility(Ability.horn) || hasAbility(Ability.mardroeme));

  bool hasAbility(String ability) => abilities.contains(ability);

  @override
  String toString() => 'CardDefinition($id, $name)';
}

/// A concrete card owned by a player during a match.
///
/// Instances are cheap wrappers around an immutable [CardDefinition]; mutable
/// per-match state lives here so definitions can be shared safely.
class CardInstance {
  CardInstance({
    required this.uid,
    required this.definition,
    required this.owner,
  }) : baseStrength = definition.baseStrength,
       currentStrength = definition.baseStrength;

  final int uid;
  final CardDefinition definition;

  /// Index of the owning player (0 or 1).
  int owner;

  final int baseStrength;
  int currentStrength;

  /// Set by the Monsters faction ability so a unit survives a round.
  bool noRemove = false;

  /// Set when the card is removed from the battlefield and triggers an ability.
  bool removedTriggered = false;

  /// Cards created by an ability (a leader's temporary Horn) are discarded
  /// instead of going to the graveyard.
  bool temporary = false;

  String get id => definition.id;
  String get name => definition.name;
  CardFaction get faction => definition.faction;
  CardRow get row => definition.row;
  bool get isHero => definition.isHero;
  bool get isUnit => definition.isUnit;
  bool get isWeather => definition.isWeather;
  bool get isSpecial => definition.isSpecial;
  bool get usesRowSpecialSlot => definition.usesRowSpecialSlot;
  List<String> get abilities => definition.abilities;

  bool hasAbility(String ability) => definition.hasAbility(ability);

  void resetStrength() => currentStrength = baseStrength;

  @override
  String toString() => 'CardInstance($uid, $name)';
}
