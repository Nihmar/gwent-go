import '../models/card.dart';
import 'card_catalog.dart';

/// Versions two peers must agree on before sharing a match.
///
/// A mismatch means the two builds would disagree about the rules or the card
/// data, so it has to be rejected during the lobby handshake rather than
/// discovered mid-match.
abstract final class MatchVersions {
  /// Version of the command and session message schema.
  static const int protocolVersion = 1;

  /// Version of the rules themselves, for balance changes that keep the card
  /// catalog stable.
  static const int rulesVersion = 1;

  /// Content hash of the shipped catalog.
  static final String catalogHash = hashCards(allCards);

  /// Stable hash over a card set.
  ///
  /// Covers everything the rules read: id, faction, row, base strength, copy
  /// limit and the ability ids. Order independent, so it does not change when
  /// the catalog is merely reordered.
  static String hashCards(Iterable<CardDefinition> cards) {
    final entries = cards.map(_describe).toList()..sort();
    return _fnv1a(entries.join('\n'));
  }

  static String _describe(CardDefinition card) {
    final abilities = [...card.abilities]..sort();
    return '${card.id}|${card.faction.name}|${card.row.name}|'
        '${card.baseStrength}|${card.maxCopies}|${abilities.join(',')}';
  }

  /// 32-bit FNV-1a, hexadecimal. Small and stable across platforms.
  static String _fnv1a(String input) {
    var hash = 0x811C9DC5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
