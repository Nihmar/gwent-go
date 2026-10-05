import 'package:flutter/material.dart';

import '../../../core/models/card.dart';
import '../../controllers/game_controller.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../gwent_card.dart';
import 'game_preview_panel.dart';

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
                // redrawsLeft is the number of swaps still allowed for this
                // mulligan; pending picks are only a selection, so they must
                // not inflate the count shown to the player.
                strings.mulliganTitle(controller.redrawsLeft),
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

/// Bottom sheet that collects a row or target choice.
///
/// Serves two callers: card plays (Decoy, Medic) and leader abilities that ask
/// the player to pick cards (Eredin's Destroyer of Worlds, Emhyr's Relentless,
/// Eredin's Bringer of Death). When more than one card must be chosen the sheet
/// turns into a multi-select with a confirm action.
class ChoiceOverlay extends StatefulWidget {
  const ChoiceOverlay({
    super.key,
    required this.controller,
    required this.choice,
  });

  final GameController controller;
  final PendingChoice choice;

  @override
  State<ChoiceOverlay> createState() => _ChoiceOverlayState();
}

class _ChoiceOverlayState extends State<ChoiceOverlay> {
  final List<CardInstance> _selected = [];

  @override
  void didUpdateWidget(ChoiceOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.choice, widget.choice)) _selected.clear();
  }

  String _title(BuildContext context) {
    final strings = context.strings;
    return switch (widget.choice) {
      RowChoice() => strings.selectRowHint,
      TargetChoice(:final kind, :final requiredCount) => switch (kind) {
        TargetKind.hand => strings.selectDiscardHint(requiredCount),
        TargetKind.deck => strings.selectDrawHint,
        TargetKind.graveyard ||
        TargetKind.battlefield => strings.selectTargetHint,
      },
    };
  }

  void _toggle(CardInstance target, int requiredCount) {
    if (requiredCount == 1) {
      _resolve([target]);
      return;
    }
    setState(() {
      if (_selected.remove(target)) return;
      if (_selected.length >= requiredCount) _selected.removeAt(0);
      _selected.add(target);
    });
  }

  void _resolve(List<CardInstance> chosen) {
    if (widget.controller.selectedCard != null) {
      widget.controller.playSelected(target: chosen.first);
    } else {
      widget.controller.chooseTargets(List.of(chosen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final choice = widget.choice;
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
                  Text(
                    _title(context),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.controller.clearSelection,
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
                        onPressed: () =>
                            widget.controller.playSelected(row: row),
                        child: Text(strings.rowName(row)),
                      ),
                  ],
                ),
                TargetChoice(:final targets, :final requiredCount) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
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
                            selected: _selected.contains(target),
                            onTap: () => _toggle(target, requiredCount),
                          );
                        },
                      ),
                    ),
                    if (requiredCount > 1) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _selected.length == requiredCount
                              ? () => _resolve(_selected)
                              : null,
                          child: Text(
                            '${strings.confirmSelection} '
                            '(${_selected.length}/$requiredCount)',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen hand-over used by hotseat play.
///
/// Nothing of the next player's hand is rendered until they confirm, so the
/// board and the new hand are only revealed once the device has changed hands.
class PassDeviceOverlay extends StatelessWidget {
  const PassDeviceOverlay({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final seat = controller.pendingSeat;
    final name = seat == null
        ? ''
        : strings.playerSeat(seat + 1);
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.97),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pan_tool_alt_outlined,
                    size: 44,
                    color: GwentColors.goldBright,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    strings.passDeviceTitle(name),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.passDeviceHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GwentColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: controller.confirmSeatSwitch,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(strings.passDeviceReady),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
