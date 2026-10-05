import 'package:flutter/material.dart';

import '../../../core/models/card.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../card_detail_dialog.dart';
import '../gwent_card.dart';

/// Bottom sheet shown on long-press: artwork, full ability text and the copy
/// actions, so the effect is readable without leaving the collection.
Future<void> showCardPickerSheet(
  BuildContext context, {
  required CardDefinition card,
  required int copies,
  required int maxCopies,
  required VoidCallback onAdd,
  required VoidCallback onRemove,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: GwentColors.surfaceHigh,
    builder: (_) => _CardPickerSheet(
      card: card,
      copies: copies,
      maxCopies: maxCopies,
      onAdd: onAdd,
      onRemove: onRemove,
    ),
  );
}

class _CardPickerSheet extends StatefulWidget {
  const _CardPickerSheet({
    required this.card,
    required this.copies,
    required this.maxCopies,
    required this.onAdd,
    required this.onRemove,
  });

  final CardDefinition card;
  final int copies;
  final int maxCopies;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  State<_CardPickerSheet> createState() => _CardPickerSheetState();
}

class _CardPickerSheetState extends State<_CardPickerSheet> {
  late int _copies = widget.copies;

  void _add() {
    if (_copies >= widget.maxCopies) return;
    setState(() => _copies++);
    widget.onAdd();
  }

  void _remove() {
    if (_copies <= 0) return;
    setState(() => _copies--);
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final tags = strings.abilityTags(widget.card);
    final atLimit = _copies >= widget.maxCopies;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GwentCard(definition: widget.card, width: 96),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.card.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cardTypeLine(strings, widget.card),
                        style: const TextStyle(
                          color: GwentColors.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final tag in tags)
                              Chip(
                                label: Text(tag),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: strings.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GwentColors.surfaceLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: GwentColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.abilityLabel.toUpperCase(), style: _labelStyle),
                  const SizedBox(height: 6),
                  Text(
                    strings.cardDescription(widget.card),
                    style: const TextStyle(
                      color: GwentColors.onSurface,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              strings.inDeckCount(_copies, widget.maxCopies),
              style: const TextStyle(
                color: GwentColors.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
            if (atLimit) ...[
              const SizedBox(height: 2),
              Text(
                strings.atCopyLimit,
                style: const TextStyle(
                  color: GwentColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copies > 0 ? _remove : null,
                    icon: const Icon(Icons.remove, size: 18),
                    label: Text(strings.removeCopy),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: atLimit ? null : _add,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(strings.addCopy),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const TextStyle _labelStyle = TextStyle(
  color: GwentColors.onSurfaceVariant,
  fontSize: 10,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.2,
);
