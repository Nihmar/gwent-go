import 'package:flutter/material.dart';

import '../../../core/models/card.dart';
import '../../controllers/game_controller.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../gwent_card.dart';

/// Selected-card preview with the play action.
class GamePreviewPanel extends StatelessWidget {
  const GamePreviewPanel({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  final GameController controller;

  /// Drops the surrounding surface so the panel can be embedded in a sheet.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final card = controller.selectedCard;
    final content = card == null
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              strings.cardPreview.toUpperCase(),
              style: const TextStyle(
                color: GwentColors.onSurfaceVariant,
                fontSize: 12,
                letterSpacing: 1.6,
              ),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GwentCard(definition: card.definition, width: 76),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _typeLine(context, card.definition),
                          style: const TextStyle(
                            color: GwentColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                strings.cardDescription(card.definition),
                style: const TextStyle(
                  color: GwentColors.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: controller.engine.isHumanTurn
                        ? () => controller.playSelected()
                        : null,
                    icon: const Icon(Icons.double_arrow_rounded, size: 18),
                    label: Text(strings.playCard),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: controller.clearSelection,
                    child: Text(strings.cancel),
                  ),
                ],
              ),
            ],
          );
    if (embedded) {
      return Padding(padding: const EdgeInsets.all(16), child: content);
    }
    return _SurfacePanel(child: content);
  }

  String _typeLine(BuildContext context, CardDefinition card) {
    final strings = context.strings;
    if (card.isLeader) return strings.cardTypeLeader;
    if (card.isWeather) return strings.cardTypeWeather;
    if (card.isSpecial) return strings.cardTypeSpecial;
    final row = card.row == CardRow.agile ? CardRow.close : card.row;
    final hero = card.isHero ? ' · ${strings.tagHero}' : '';
    return '${strings.rowName(row)}$hero';
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GwentColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }
}
