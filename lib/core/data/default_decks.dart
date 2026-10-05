// GENERATED FILE — do not edit by hand.
//
// Default decks derived from the reference implementation's premade decks.
// Regenerate with tool/generate_default_decks.js.

import '../models/card.dart';

/// A deck described without resolving card definitions; [CardRepository]
/// turns blueprints into [DeckDefinition] instances.
class DeckBlueprint {
  const DeckBlueprint({
    required this.id,
    required this.name,
    required this.faction,
    required this.leaderId,
    required this.cardCounts,
  });

  final String id;
  final String name;
  final CardFaction faction;
  final String leaderId;
  final Map<String, int> cardCounts;
}

/// One ready-made deck per playable faction.
const List<DeckBlueprint> defaultDeckBlueprints = [
  DeckBlueprint(
    id: 'realms_starter',
    name: "Foltest Siege",
    faction: CardFaction.realms,
    leaderId: 'foltest_copper',
    cardCounts: {
      'horn': 1, 'decoy': 3, 'frost': 1, 'ciri': 1, 'geralt': 1, 'esterad': 1, 'natalis': 1, 'philippa': 1, 'vernon': 1, 'catapult_1': 2, 'triss': 1, 'villen': 1, 'yennefer': 1, 'ballista': 1, 'olgierd': 1, 'siege_tower': 1, 'trebuchet': 1, 'trebuchet_1': 1, 'crinfrid': 3, 'banner_nurse': 1, 'stennis': 1, 'blue_stripes': 3, 'gaunter_odimm_darkness': 3, 'dijkstra': 1, 'dandelion': 1, 'gaunter_odimm': 1, 'thaler': 1, 'mysterious_elf': 1,
    },
  ), // 37 cards, 195 strength

  DeckBlueprint(
    id: 'nilfgaard_starter',
    name: "Emhyr Control",
    faction: CardFaction.nilfgaard,
    leaderId: 'emhyr_gold',
    cardCounts: {
      'horn': 1, 'decoy': 3, 'scorch': 1, 'frost': 1, 'clear': 1, 'fog': 1, 'rain': 1, 'ciri': 1, 'geralt': 1, 'black_archer': 1, 'black_archer_1': 1, 'heavy_zerri': 1, 'menno': 1, 'moorvran': 1, 'stefan': 1, 'shilard': 1, 'villen': 1, 'yennefer': 1, 'olgierd': 1, 'young_emissary': 1, 'young_emissary_1': 1, 'gaunter_odimm_darkness': 3, 'vattier': 1, 'imperal_brigade': 4, 'dandelion': 1, 'gaunter_odimm': 1, 'archer_support': 1, 'archer_support_1': 1, 'mysterious_elf': 1, 'siege_support': 1,
    },
  ), // 37 cards, 160 strength

  DeckBlueprint(
    id: 'monsters_starter',
    name: "Eredin Muster",
    faction: CardFaction.monsters,
    leaderId: 'eredin_silver',
    cardCounts: {
      'horn': 1, 'decoy': 3, 'scorch': 1, 'clear': 1, 'fog': 1, 'rain': 1, 'ciri': 1, 'geralt': 1, 'imlerith': 1, 'kayran': 1, 'toad': 1, 'villen': 1, 'yennefer': 1, 'arachas_behemoth': 1, 'witch_velen': 1, 'witch_velen_1': 1, 'witch_velen_2': 1, 'olgierd': 1, 'katakan': 1, 'arachas': 1, 'arachas_1': 1, 'arachas_2': 1, 'poroniec': 1, 'gaunter_odimm_darkness': 3, 'bruxa': 1, 'ekkima': 1, 'fleder': 1, 'garkain': 1, 'dandelion': 1, 'gaunter_odimm': 1, 'nekker': 1, 'nekker_1': 1, 'nekker_2': 1, 'mysterious_elf': 1,
    },
  ), // 38 cards, 158 strength

  DeckBlueprint(
    id: 'scoiatael_starter',
    name: "Francesca Hope",
    faction: CardFaction.scoiatael,
    leaderId: 'francesca_copper',
    cardCounts: {
      'horn': 1, 'decoy': 3, 'scorch': 1, 'frost': 1, 'clear': 1, 'fog': 1, 'rain': 1, 'ciri': 1, 'geralt': 1, 'isengrim': 1, 'milva': 1, 'schirru': 1, 'villen': 1, 'yennefer': 1, 'dol_infantry': 1, 'olgierd': 1, 'havekar_support': 1, 'havekar_support_1': 1, 'havekar_support_2': 1, 'gaunter_odimm_darkness': 3, 'ciaran': 1, 'dwarf': 1, 'dwarf_1': 1, 'dwarf_2': 1, 'dandelion': 1, 'gaunter_odimm': 1, 'havekar_nurse': 1, 'havekar_nurse_1': 1, 'mysterious_elf': 1,
    },
  ), // 33 cards, 127 strength

  DeckBlueprint(
    id: 'skellige_starter',
    name: "Crach An Craite",
    faction: CardFaction.skellige,
    leaderId: 'crach_an_craite',
    cardCounts: {
      'horn': 1, 'mardroeme': 1, 'scorch': 1, 'frost': 1, 'storm': 1, 'rain': 1, 'ciri': 1, 'geralt': 1, 'olaf': 1, 'cerys': 1, 'ermion': 1, 'villen': 1, 'yennefer': 1, 'craite_warrior': 3, 'dimun_pirate': 1, 'olgierd': 1, 'shield_maiden': 1, 'shield_maiden_1': 1, 'shield_maiden_2': 1, 'light_longship': 3, 'birna': 1, 'dandelion': 1, 'young_berserker': 3, 'kambi': 1, 'mysterious_elf': 1,
    },
  ), // 31 cards, 138 strength
];
