import 'package:flutter/material.dart';

import '../../../core/data/card_repository.dart';
import '../../../core/models/player.dart';
import '../../../core/rules/deck_validator.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';

/// Persistent deck summary and actions for the phone layout.
///
/// Keeps the deck rules visible while the player edits: card/unit/special
/// counts, total strength, every validation issue and the start action, so a
/// disabled **Start game** always explains itself.
class DeckSummaryBar extends StatelessWidget {
  const DeckSummaryBar({
    super.key,
    required this.deck,
    required this.validation,
    required this.onSave,
    required this.onStart,
  });

  final DeckDefinition deck;
  final DeckValidationResult validation;
  final VoidCallback onSave;

  /// Null when the deck is not playable.
  final VoidCallback? onStart;

  static const cardsKey = Key('deck-stat-cards');
  static const unitsKey = Key('deck-stat-units');
  static const specialKey = Key('deck-stat-special');
  static const strengthKey = Key('deck-stat-strength');

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final units = CardRepository.deckUnitCount(deck);
    final specials = CardRepository.deckSpecialCount(deck);
    final total = deck.totalCards;
    final strength = CardRepository.deckStrength(deck);
    final issues = [...validation.issues]
      ..sort((a, b) => a.index.compareTo(b.index));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        border: Border(
          top: BorderSide(
            color: GwentColors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (total / DeckValidator.maxTotal).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: GwentColors.outlineVariant,
                  color: GwentColors.gold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: strings.cards,
                      value: '$total / ${DeckValidator.maxTotal}',
                      valueKey: cardsKey,
                      warn: total > DeckValidator.maxTotal,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: strings.filterUnits,
                      value: '$units / ${DeckValidator.minUnits}',
                      valueKey: unitsKey,
                      warn: units < DeckValidator.minUnits,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: strings.filterSpecial,
                      value: '$specials / ${DeckValidator.maxSpecial}',
                      valueKey: specialKey,
                      warn: specials > DeckValidator.maxSpecial,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: strings.strength,
                      value: '$strength',
                      valueKey: strengthKey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (issues.isEmpty)
                _ValidRow(text: strings.deckValid)
              else
                _IssuesRow(
                  messages: [
                    for (final issue in issues)
                      strings.deckIssueMessage(issue),
                  ],
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: onSave,
                      child: Text(strings.saveDeck),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onStart,
                      child: Text(strings.startGame),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueKey,
    this.warn = false,
  });

  final String label;
  final String value;
  final Key valueKey;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GwentColors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          key: valueKey,
          maxLines: 1,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: warn ? GwentColors.error : null,
          ),
        ),
      ],
    );
  }
}

class _ValidRow extends StatelessWidget {
  const _ValidRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      color: GwentColors.gold,
      icon: Icons.check_circle_outline,
      lines: [text],
    );
  }
}

class _IssuesRow extends StatelessWidget {
  const _IssuesRow({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      color: GwentColors.error,
      icon: Icons.error_outline,
      lines: messages,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.lines,
  });

  final Color color;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lines[i],
                      style: TextStyle(color: color, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
