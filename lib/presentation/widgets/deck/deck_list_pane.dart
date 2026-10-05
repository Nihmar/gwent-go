import 'package:flutter/material.dart';

import '../../../core/data/card_repository.dart';
import '../../../core/models/card.dart';
import '../../../core/models/collection.dart';
import '../../../core/rules/deck_validator.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../card_assets.dart';
import '../gwent_card.dart';
import 'deck_editor_parts.dart';

/// The deck contents grouped by battlefield row.
///
/// Each card is a list row with an explicit `- n +` stepper, so a copy is
/// never removed by an accidental tap. The narrow layout also shows the leader
/// tile at the top; the wide layout has it in the side pane instead.
class DeckListPane extends StatelessWidget {
  const DeckListPane({
    super.key,
    required this.counts,
    required this.collection,
    required this.leader,
    required this.onAdd,
    required this.onRemove,
    required this.onChangeLeader,
    this.showLeaderSlot = true,
    this.showHeader = false,
  });

  final Map<String, int> counts;
  final Collection collection;
  final CardDefinition leader;
  final ValueChanged<CardDefinition> onAdd;
  final ValueChanged<CardDefinition> onRemove;
  final VoidCallback onChangeLeader;

  /// Renders the leader tile above the rows (phone layout).
  final bool showLeaderSlot;

  /// Renders the "DECK / total / strength" header (wide layout).
  final bool showHeader;

  int get _total => counts.values.fold(0, (a, b) => a + b);

  int get _strength {
    var total = 0;
    counts.forEach((id, count) {
      total += CardRepository.byId(id).baseStrength * count;
    });
    return total;
  }

  List<MapEntry<String, int>> _entriesForRow(CardRow row) {
    final entries = counts.entries
        .where((entry) => CardRepository.byId(entry.key).row == row)
        .toList();
    entries.sort((a, b) {
      final cardA = CardRepository.byId(a.key);
      final cardB = CardRepository.byId(b.key);
      if (cardA.baseStrength != cardB.baseStrength) {
        return cardB.baseStrength.compareTo(cardA.baseStrength);
      }
      return cardA.name.compareTo(cardB.name);
    });
    return entries;
  }

  int _copiesCap(CardDefinition card) =>
      card.maxCopies < collection.ownedCount(card)
      ? card.maxCopies
      : collection.ownedCount(card);

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final groups = [
      for (final row in CardRow.values)
        if (_entriesForRow(row).isNotEmpty) row,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLeaderSlot) ...[
          DeckLeaderTile(leader: leader, onChangeLeader: onChangeLeader),
          const SizedBox(height: 10),
        ],
        if (showHeader) ...[
          Row(
            children: [
              Text(strings.deck.toUpperCase(), style: deckPaneTitleStyle),
              const SizedBox(width: 10),
              Chip(label: Text('$_total / ${DeckValidator.maxTotal}')),
              const SizedBox(width: 6),
              Chip(label: Text('$_strength ${strings.strength}')),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(
                    strings.deckInvalid,
                    style: const TextStyle(
                      color: GwentColors.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final row in groups)
                      _DeckGroup(
                        row: row,
                        entries: _entriesForRow(row),
                        capOf: _copiesCap,
                        onAdd: onAdd,
                        onRemove: onRemove,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Leader card, effect and the action that opens the leader picker.
class DeckLeaderTile extends StatelessWidget {
  const DeckLeaderTile({
    super.key,
    required this.leader,
    required this.onChangeLeader,
  });

  final CardDefinition leader;
  final VoidCallback onChangeLeader;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GwentColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          GwentCard(definition: leader, width: 56, showName: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.leader.toUpperCase(), style: deckPaneTitleStyle),
                const SizedBox(height: 2),
                Text(
                  leader.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.cardDescription(leader),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onChangeLeader,
            child: Text(strings.changeLeader),
          ),
        ],
      ),
    );
  }
}

class _DeckGroup extends StatelessWidget {
  const _DeckGroup({
    required this.row,
    required this.entries,
    required this.capOf,
    required this.onAdd,
    required this.onRemove,
  });

  final CardRow row;
  final List<MapEntry<String, int>> entries;
  final int Function(CardDefinition card) capOf;
  final ValueChanged<CardDefinition> onAdd;
  final ValueChanged<CardDefinition> onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final rowIcon = CardAssets.rowIcon(row);
    final cards = entries
        .map((entry) => CardRepository.byId(entry.key))
        .toList();
    final total = entries.fold(0, (a, entry) => a + entry.value);
    final strength = entries.fold(
      0,
      (a, entry) => a + CardRepository.byId(entry.key).baseStrength * entry.value,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GwentColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.white.withValues(alpha: 0.04),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (rowIcon != null) ...[
                  Image.asset(rowIcon, width: 18, height: 18),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    strings.rowName(row),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '$total · $strength ${strings.strength}',
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _DeckRowItem(
            card: cards.first,
            count: entries.first.value,
            cap: capOf(cards.first),
            onAdd: onAdd,
            onRemove: onRemove,
          ),
          for (var i = 1; i < entries.length; i++)
            _DeckRowItem(
              card: cards[i],
              count: entries[i].value,
              cap: capOf(cards[i]),
              onAdd: onAdd,
              onRemove: onRemove,
            ),
        ],
      ),
    );
  }
}

class _DeckRowItem extends StatelessWidget {
  const _DeckRowItem({
    required this.card,
    required this.count,
    required this.cap,
    required this.onAdd,
    required this.onRemove,
  });

  final CardDefinition card;
  final int count;
  final int cap;
  final ValueChanged<CardDefinition> onAdd;
  final ValueChanged<CardDefinition> onRemove;

  String _subtitle(BuildContext context) {
    final strings = context.strings;
    if (card.isSpecial || card.isWeather) {
      return strings.rowName(card.row);
    }
    final tags = strings.abilityTags(card);
    return [
      ...tags,
      '${card.baseStrength} ${strings.strength}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: GwentColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          GwentCard(definition: card, width: 42, showName: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _subtitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QuantityStepper(
            count: count,
            canAdd: count < cap,
            onAdd: () => onAdd(card),
            onRemove: () => onRemove(card),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.count,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  final int count;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final style = IconButton.styleFrom(
      minimumSize: const Size(36, 36),
      padding: EdgeInsets.zero,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: strings.removeCopy,
          onPressed: onRemove,
          style: style,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove, size: 18),
        ),
        SizedBox(
          width: 22,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton(
          tooltip: strings.addCopy,
          onPressed: canAdd ? onAdd : null,
          style: style,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}
