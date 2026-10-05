import 'package:flutter/material.dart';

import '../../core/data/faction_catalog.dart';
import '../../core/models/card.dart';
import '../../core/models/player.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';

/// Easy / Normal / Hard selector used on the home screen and deck editor.
class DifficultySelector extends StatelessWidget {
  const DifficultySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Difficulty value;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<Difficulty>(
        segments: [
          for (final difficulty in Difficulty.values)
            ButtonSegment(
              value: difficulty,
              label: Text(strings.difficultyName(difficulty)),
            ),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

/// Horizontal faction picker with the reference faction shields.
class FactionSelector extends StatelessWidget {
  const FactionSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CardFaction value;
  final ValueChanged<CardFaction> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final faction in playableFactions) ...[
          Expanded(
            child: _FactionTile(
              faction: faction,
              selected: faction == value,
              onTap: () => onChanged(faction),
            ),
          ),
          if (faction != playableFactions.last) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _FactionTile extends StatelessWidget {
  const _FactionTile({
    required this.faction,
    required this.selected,
    required this.onTap,
  });

  final CardFaction faction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = factionInfo(faction);
    final name = context.strings.factionName(faction);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? GwentColors.gold.withValues(alpha: 0.6)
                : GwentColors.outlineVariant.withValues(alpha: 0.55),
          ),
          color: selected
              ? GwentColors.gold.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.02),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 30,
              child: Image.asset(info.shieldAsset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 5),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w500,
                color: selected
                    ? GwentColors.goldBright
                    : GwentColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
