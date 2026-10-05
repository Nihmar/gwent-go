import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_catalog.dart';
import 'package:gwent_go/core/data/match_versions.dart';
import 'package:gwent_go/core/models/card.dart';

void main() {
  const base = CardDefinition(
    id: 'test',
    name: 'Test',
    faction: CardFaction.realms,
    row: CardRow.close,
    baseStrength: 5,
    artFilename: 'test',
    abilities: ['spy'],
    maxCopies: 2,
  );

  group('MatchVersions', () {
    test('pins the shipped catalog', () {
      // Golden value: changing any card data must be a deliberate decision
      // that also bumps the version peers compare.
      expect(MatchVersions.catalogHash, '642eeeff');
      expect(MatchVersions.protocolVersion, greaterThan(0));
      expect(MatchVersions.rulesVersion, greaterThan(0));
    });

    test('is independent of card and ability order', () {
      const reordered = CardDefinition(
        id: 'test',
        name: 'Test',
        faction: CardFaction.realms,
        row: CardRow.close,
        baseStrength: 5,
        artFilename: 'test',
        abilities: ['hero', 'spy', 'medic'],
        maxCopies: 2,
      );
      const sameAbilities = CardDefinition(
        id: 'test',
        name: 'Test',
        faction: CardFaction.realms,
        row: CardRow.close,
        baseStrength: 5,
        artFilename: 'test',
        abilities: ['medic', 'hero', 'spy'],
        maxCopies: 2,
      );

      expect(
        MatchVersions.hashCards([reordered, base]),
        MatchVersions.hashCards([base, sameAbilities]),
      );
    });

    test('changes when any rule-relevant field changes', () {
      final variants = [
        CardDefinition(
          id: 'other',
          name: base.name,
          faction: base.faction,
          row: base.row,
          baseStrength: base.baseStrength,
          artFilename: base.artFilename,
          abilities: base.abilities,
          maxCopies: base.maxCopies,
        ),
        CardDefinition(
          id: base.id,
          name: base.name,
          faction: CardFaction.monsters,
          row: base.row,
          baseStrength: base.baseStrength,
          artFilename: base.artFilename,
          abilities: base.abilities,
          maxCopies: base.maxCopies,
        ),
        CardDefinition(
          id: base.id,
          name: base.name,
          faction: base.faction,
          row: CardRow.ranged,
          baseStrength: base.baseStrength,
          artFilename: base.artFilename,
          abilities: base.abilities,
          maxCopies: base.maxCopies,
        ),
        CardDefinition(
          id: base.id,
          name: base.name,
          faction: base.faction,
          row: base.row,
          baseStrength: 6,
          artFilename: base.artFilename,
          abilities: base.abilities,
          maxCopies: base.maxCopies,
        ),
        CardDefinition(
          id: base.id,
          name: base.name,
          faction: base.faction,
          row: base.row,
          baseStrength: base.baseStrength,
          artFilename: base.artFilename,
          abilities: base.abilities,
          maxCopies: 3,
        ),
        CardDefinition(
          id: base.id,
          name: base.name,
          faction: base.faction,
          row: base.row,
          baseStrength: base.baseStrength,
          artFilename: base.artFilename,
          abilities: ['spy', 'medic'],
          maxCopies: base.maxCopies,
        ),
      ];

      final reference = MatchVersions.hashCards([base]);
      for (final variant in variants) {
        expect(
          MatchVersions.hashCards([variant]),
          isNot(reference),
          reason: variant.toString(),
        );
      }
    });

    test('hashes the whole shipped catalog', () {
      expect(
        MatchVersions.hashCards(allCards),
        MatchVersions.catalogHash,
      );
    });
  });
}
