import 'package:flutter/material.dart';

import '../../../core/data/card_repository.dart';
import '../../../core/data/faction_catalog.dart';
import '../../../core/models/card.dart';
import '../../../core/models/collection.dart';
import '../../../core/models/player.dart';
import '../../../core/rules/deck_validator.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../gwent_card.dart';

const TextStyle deckPaneTitleStyle = TextStyle(
  color: GwentColors.onSurfaceVariant,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.4,
);

/// Search, filters and the collectible grid.
class DeckCollectionPane extends StatelessWidget {
  const DeckCollectionPane({
    super.key,
    required this.cards,
    required this.collection,
    required this.counts,
    required this.search,
    required this.filter,
    required this.onlyOwned,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onOnlyOwnedChanged,
    required this.onAdd,
  });

  final List<CardDefinition> cards;
  final Collection collection;
  final Map<String, int> counts;
  final String search;
  final CardRow? filter;
  final bool onlyOwned;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CardRow?> onFilterChanged;
  final ValueChanged<bool> onOnlyOwnedChanged;
  final ValueChanged<CardDefinition> onAdd;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: strings.searchCollection,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: GwentColors.surfaceHigh,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _filterChip(strings.filterAll, null),
            _filterChip(strings.filterUnits, CardRow.close),
            _filterChip(strings.filterSpecial, CardRow.special),
            _filterChip(strings.filterWeather, CardRow.weather),
            FilterChip(
              label: Text(strings.filterOwned),
              selected: onlyOwned,
              onSelected: onOnlyOwnedChanged,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 108,
              childAspectRatio: 4.45 / 6.35,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final owned = counts[card.id] ?? 0;
              final cap = card.maxCopies < collection.ownedCount(card)
                  ? card.maxCopies
                  : collection.ownedCount(card);
              final canAdd = owned < cap;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  GwentCard(
                    definition: card,
                    width: 96,
                    onTap: canAdd ? () => onAdd(card) : null,
                  ),
                  if (owned > 0)
                    Positioned(
                      left: -4,
                      top: -4,
                      child: DeckBadge(text: '$owned/$cap'),
                    ),
                  if (canAdd)
                    const Positioned(
                      right: -4,
                      top: -4,
                      child: Icon(
                        Icons.add_circle,
                        color: GwentColors.goldBright,
                        size: 18,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, CardRow? row) => ChoiceChip(
    label: Text(label),
    selected: filter == row,
    onSelected: (_) => onFilterChanged(row),
  );
}

/// The deck itself, grouped by row.
class DeckListPane extends StatelessWidget {
  const DeckListPane({
    super.key,
    required this.counts,
    required this.onRemove,
    required this.onChangeLeader,
    required this.showChangeLeader,
  });

  final Map<String, int> counts;
  final ValueChanged<CardDefinition> onRemove;
  final VoidCallback onChangeLeader;
  final bool showChangeLeader;

  int get _total => counts.values.fold(0, (a, b) => a + b);

  List<CardDefinition> _cardsForRow(CardRow row) {
    final result = <CardDefinition>[];
    counts.forEach((id, count) {
      final card = CardRepository.byId(id);
      if (card.row != row && !(row == CardRow.special && card.isWeather)) {
        return;
      }
      for (var i = 0; i < count; i++) {
        result.add(card);
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    var strength = 0;
    counts.forEach((id, count) {
      strength += CardRepository.byId(id).baseStrength * count;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(strings.deck.toUpperCase(), style: deckPaneTitleStyle),
            const SizedBox(width: 10),
            Chip(label: Text('$_total / 40')),
            const SizedBox(width: 6),
            Chip(label: Text('$strength ${strings.strength}')),
            const Spacer(),
            if (showChangeLeader)
              TextButton(
                onPressed: onChangeLeader,
                child: Text(strings.changeLeader),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            children: [
              for (final row in CardRow.values)
                if (_cardsForRow(row).isNotEmpty)
                  _DeckGroup(
                    row: row,
                    cards: _cardsForRow(row),
                    onRemove: onRemove,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeckGroup extends StatelessWidget {
  const _DeckGroup({
    required this.row,
    required this.cards,
    required this.onRemove,
  });

  final CardRow row;
  final List<CardDefinition> cards;
  final ValueChanged<CardDefinition> onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GwentColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                strings.rowName(row),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('${cards.length}'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 2,
            runSpacing: 6,
            children: [
              for (final card in cards)
                GwentCard(
                  definition: card,
                  width: 52,
                  showName: false,
                  onTap: () => onRemove(card),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stats, leader and faction ability for the edited deck.
class DeckSidePane extends StatelessWidget {
  const DeckSidePane({
    super.key,
    required this.deck,
    required this.leader,
    required this.validation,
    required this.onChangeLeader,
  });

  final DeckDefinition deck;
  final CardDefinition leader;
  final DeckValidationResult validation;
  final VoidCallback onChangeLeader;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final units = CardRepository.deckUnitCount(deck);
    final specials = CardRepository.deckSpecialCount(deck);
    final valid = validation.isValid;
    return ListView(
      children: [
        _surface(
          title: strings.deckStats,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statLine(strings.totalCards, '${deck.totalCards}'),
              _statLine(strings.unitCards, '$units / 22'),
              _statLine(strings.specialCards, '$specials / 10'),
              _statLine(
                strings.heroCards,
                '${CardRepository.deckHeroCount(deck)}',
              ),
              _statLine(
                strings.totalStrength,
                '${CardRepository.deckStrength(deck)}',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: valid
                      ? GwentColors.gold.withValues(alpha: 0.12)
                      : GwentColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: valid
                        ? GwentColors.gold.withValues(alpha: 0.4)
                        : GwentColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  valid ? strings.deckValid : strings.deckInvalid,
                  style: TextStyle(
                    color: valid ? GwentColors.goldBright : GwentColors.error,
                    fontSize: 12.5,
                  ),
                ),
              ),
              for (final issue in validation.issues)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '• ${strings.deckIssueMessage(issue)}',
                    style: const TextStyle(
                      color: GwentColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _surface(
          title: strings.leader,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GwentCard(definition: leader, width: 60),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.cardDescription(leader),
                      style: const TextStyle(
                        color: GwentColors.onSurfaceVariant,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    TextButton(
                      onPressed: onChangeLeader,
                      child: Text(strings.changeLeader),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _surface(
          title: strings.factionAbility,
          child: Text(
            strings.factionAbilityDescription(deck.faction),
            style: const TextStyle(
              color: GwentColors.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _surface({required String title, required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: GwentColors.surfaceLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: GwentColors.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: deckPaneTitleStyle),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  Widget _statLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GwentColors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

/// Small gold badge over a collection card.
class DeckBadge extends StatelessWidget {
  const DeckBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: GwentColors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: GwentColors.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Faction shield + title used by the deck editor header.
class DeckHeaderInfo extends StatelessWidget {
  const DeckHeaderInfo({
    super.key,
    required this.faction,
    required this.title,
    required this.subtitle,
  });

  final CardFaction faction;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(factionInfo(faction).shieldAsset, width: 22, height: 25),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GwentColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
