import '../models/card.dart';
import '../models/player.dart';
import 'card_repository.dart';

/// Serializes a [DeckDefinition] for storage or the wire.
Map<String, Object?> deckToJson(DeckDefinition deck) => {
  'id': deck.id,
  'name': deck.name,
  'faction': deck.faction.name,
  'leader': deck.leader.id,
  'cards': deck.cardCounts,
};

/// Reads a deck, dropping ids the catalog no longer knows.
///
/// Returns null when the payload is unusable (unknown faction or leader, or no
/// cards left after filtering).
DeckDefinition? deckFromJson(Map<String, Object?> json) {
  final factionName = json['faction'];
  final leaderId = json['leader'];
  if (factionName is! String || leaderId is! String) return null;
  final faction = _factionByName(factionName);
  final leader = CardRepository.maybeById(leaderId);
  if (faction == null || leader == null || !leader.isLeader) return null;

  final counts = <String, int>{};
  final rawCards = json['cards'];
  if (rawCards is Map) {
    rawCards.forEach((id, count) {
      if (id is! String || count is! int) return;
      if (CardRepository.maybeById(id) == null) return;
      counts[id] = count;
    });
  }
  if (counts.isEmpty) return null;
  return DeckDefinition(
    id: json['id'] as String? ?? 'custom_${faction.name}',
    name: json['name'] as String? ?? 'Custom deck',
    faction: faction,
    leader: leader,
    cardCounts: counts,
  );
}

CardFaction? _factionByName(String name) {
  for (final faction in CardFaction.values) {
    if (faction.name == name) return faction;
  }
  return null;
}
