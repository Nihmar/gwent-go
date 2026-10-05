import 'package:flutter/material.dart';

import '../../../core/data/card_repository.dart';
import '../../../core/models/card.dart';
import '../../../core/models/collection.dart';
import '../../../core/models/player.dart';
import '../../../core/rules/deck_validator.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../gwent_card.dart';
import 'card_picker_sheet.dart';

const TextStyle deckPaneTitleStyle = TextStyle(
  color: GwentColors.onSurfaceVariant,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.4,
);

/// Card width used by the collection grid.
const double deckCollectionCardWidth = 104;

/// Category filters for the collection pane.
///
/// A single [CardRow] cannot express "all units" or "heroes", so the filter is
/// its own type independent of the row model.
enum CollectionFilter { all, units, special, weather, heroes }

/// Search, filters and the collectible grid.
///
/// Tapping a tile adds a copy, long-pressing opens the ability sheet so the
/// effect text is readable without leaving the collection.
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
    required this.onRemove,
  });

  final List<CardDefinition> cards;
  final Collection collection;
  final Map<String, int> counts;
  final String search;
  final CollectionFilter filter;
  final bool onlyOwned;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CollectionFilter> onFilterChanged;
  final ValueChanged<bool> onOnlyOwnedChanged;
  final ValueChanged<CardDefinition> onAdd;
  final ValueChanged<CardDefinition> onRemove;

  int _cap(CardDefinition card) => card.maxCopies < collection.ownedCount(card)
      ? card.maxCopies
      : collection.ownedCount(card);

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
            _filterChip(strings.filterAll, CollectionFilter.all),
            _filterChip(strings.filterUnits, CollectionFilter.units),
            _filterChip(strings.filterSpecial, CollectionFilter.special),
            _filterChip(strings.filterWeather, CollectionFilter.weather),
            _filterChip(strings.filterHeroes, CollectionFilter.heroes),
            FilterChip(
              label: Text(strings.filterOwned),
              selected: onlyOwned,
              onSelected: onOnlyOwnedChanged,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          strings.deckEditorHint,
          style: const TextStyle(
            color: GwentColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: cards.isEmpty
              ? Center(
                  child: Text(
                    strings.noCardsFound,
                    style: const TextStyle(
                      color: GwentColors.onSurfaceVariant,
                    ),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 124,
                    mainAxisExtent:
                        deckCollectionCardWidth * 6.35 / 4.45 + 24,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return _CollectionTile(
                      card: card,
                      owned: counts[card.id] ?? 0,
                      cap: _cap(card),
                      onAdd: () => onAdd(card),
                      onRemove: () => onRemove(card),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, CollectionFilter value) => ChoiceChip(
    label: Text(label),
    selected: filter == value,
    onSelected: (_) => onFilterChanged(value),
  );
}

/// One collection card with its copy state and ability label.
class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.card,
    required this.owned,
    required this.cap,
    required this.onAdd,
    required this.onRemove,
  });

  final CardDefinition card;
  final int owned;
  final int cap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final canAdd = owned < cap;
    final tags = strings.abilityTags(card);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GwentCard(
              definition: card,
              width: deckCollectionCardWidth,
              dim: !canAdd,
              onTap: canAdd ? onAdd : null,
              onLongPress: () => showCardPickerSheet(
                context,
                card: card,
                copies: owned,
                maxCopies: cap,
                onAdd: onAdd,
                onRemove: onRemove,
              ),
            ),
            // A single status marker in the top-right corner so the card's own
            // power badge in the top-left stays readable.
            Positioned(
              right: -4,
              top: -4,
              child: owned == 0
                  ? const Icon(
                      Icons.add_circle,
                      color: GwentColors.goldBright,
                      size: 20,
                    )
                  : DeckBadge(text: '$owned/$cap', done: !canAdd),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 15,
          child: Text(
            tags.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GwentColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Stats, leader and faction ability for the edited deck (wide layout).
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
  const DeckBadge({super.key, required this.text, this.done = false});

  final String text;

  /// Adds a check mark, used when no more copies may be added.
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: done ? 4 : 6,
        right: 6,
        top: 2,
        bottom: 2,
      ),
      decoration: BoxDecoration(
        color: GwentColors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            const Icon(Icons.check, size: 12, color: GwentColors.onPrimary),
            const SizedBox(width: 1),
          ],
          Text(
            text,
            style: const TextStyle(
              color: GwentColors.onPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
