import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../gwent_card.dart';
import 'game_panels.dart';

/// Bottom preview/action sheet shown on narrow layouts when a card is selected.
///
/// The desktop layout has a permanent preview panel; phones need the same
/// controls, otherwise a selected card could never be played.
class CardPreviewSheet extends StatelessWidget {
  const CardPreviewSheet({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: GwentColors.surfaceHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: GwentColors.gold.withValues(alpha: 0.3)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: SingleChildScrollView(
              child: GamePreviewPanel(controller: controller, embedded: true),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen opening redraw chooser.
class MulliganOverlay extends StatelessWidget {
  const MulliganOverlay({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.88),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                strings.mulliganTitle(
                  controller.redrawsLeft + controller.redrawPicks.length,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${strings.cardsInHand}: ${controller.human.hand.length}',
                style: const TextStyle(color: GwentColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final card in controller.human.hand)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GwentCard(
                            definition: card.definition,
                            strength: card.baseStrength,
                            width: 96,
                            selected: controller.redrawPicks.contains(card),
                            onTap: () => controller.toggleRedraw(card),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton.icon(
                  onPressed: controller.confirmMulligan,
                  icon: const Icon(Icons.check),
                  label: Text(strings.mulliganConfirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet that collects a row or target choice for the selected card.
class ChoiceOverlay extends StatelessWidget {
  const ChoiceOverlay({
    super.key,
    required this.controller,
    required this.choice,
  });

  final GameController controller;
  final PendingChoice choice;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GwentColors.surfaceHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: GwentColors.gold.withValues(alpha: 0.3)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(switch (choice) {
                    RowChoice() => strings.selectRowHint,
                    TargetChoice() => strings.selectTargetHint,
                  }, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: controller.clearSelection,
                    child: Text(strings.cancel),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              switch (choice) {
                RowChoice(:final rows) => Wrap(
                  spacing: 8,
                  children: [
                    for (final row in rows)
                      FilledButton.tonal(
                        onPressed: () => controller.playSelected(row: row),
                        child: Text(strings.rowName(row)),
                      ),
                  ],
                ),
                TargetChoice(:final targets) => SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: targets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final target = targets[index];
                      return GwentCard(
                        definition: target.definition,
                        strength: target.baseStrength,
                        width: 78,
                        onTap: () => controller.playSelected(target: target),
                      );
                    },
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
