import 'package:flutter/material.dart';

import '../../../core/models/card.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../gwent_card.dart';

/// Opens a carousel of the faction leader cards and returns the chosen one,
/// or `null` when the dialog is dismissed.
Future<CardDefinition?> showLeaderPicker(
  BuildContext context, {
  required CardFaction faction,
  required List<CardDefinition> leaders,
  required CardDefinition current,
}) {
  return showDialog<CardDefinition>(
    context: context,
    builder: (_) => LeaderPickerDialog(
      faction: faction,
      leaders: leaders,
      current: current,
    ),
  );
}

/// Swipeable leader browser: card artwork, name and localized ability effect.
class LeaderPickerDialog extends StatefulWidget {
  const LeaderPickerDialog({
    super.key,
    required this.faction,
    required this.leaders,
    required this.current,
  });

  final CardFaction faction;
  final List<CardDefinition> leaders;
  final CardDefinition current;

  @override
  State<LeaderPickerDialog> createState() => _LeaderPickerDialogState();
}

class _LeaderPickerDialogState extends State<LeaderPickerDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.leaders.indexWhere((leader) => leader.id == widget.current.id);
    if (_index < 0) _index = 0;
    _controller = PageController(initialPage: _index, viewportFraction: 0.72);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.leaders.length) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final leader = widget.leaders[_index];
    final compact = MediaQuery.sizeOf(context).width < 420;
    final cardWidth = compact ? 148.0 : 184.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.changeLeader,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    strings.factionName(widget.faction),
                    style: const TextStyle(
                      color: GwentColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: cardWidth * 6.35 / 4.45 + 12,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.leaders.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) => _LeaderPage(
                    controller: _controller,
                    initialPage: _index,
                    index: index,
                    leader: widget.leaders[index],
                    width: cardWidth,
                    onTap: () => _goTo(index),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: strings.previousLeader,
                    onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  for (var i = 0; i < widget.leaders.length; i++)
                    _Dot(active: i == _index),
                  IconButton(
                    tooltip: strings.nextLeader,
                    onPressed: _index < widget.leaders.length - 1
                        ? () => _goTo(_index + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                leader.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              _AbilityPanel(text: strings.cardDescription(leader)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(leader),
                    child: Text(strings.confirm),
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

/// One carousel page: the leader artwork, scaled down when off-centre.
class _LeaderPage extends StatelessWidget {
  const _LeaderPage({
    required this.controller,
    required this.initialPage,
    required this.index,
    required this.leader,
    required this.width,
    required this.onTap,
  });

  final PageController controller;
  final int initialPage;
  final int index;
  final CardDefinition leader;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final position =
            controller.hasClients && controller.position.haveDimensions
            ? controller.page ?? initialPage.toDouble()
            : initialPage.toDouble();
        final delta = (position - index).clamp(-1.0, 1.0);
        return Opacity(
          opacity: (1 - delta.abs() * 0.5).clamp(0.0, 1.0),
          child: Transform.scale(scale: 1 - delta.abs() * 0.12, child: child),
        );
      },
      child: Center(
        child: Semantics(
          label: leader.name,
          button: true,
          child: GestureDetector(
            onTap: onTap,
            child: GwentCard(
              definition: leader,
              width: width,
              showName: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 18 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? GwentColors.goldBright : GwentColors.outline,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

/// Bordered panel with the localized leader ability text.
class _AbilityPanel extends StatelessWidget {
  const _AbilityPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
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
          Text(
            strings.leaderAbility.toUpperCase(),
            style: const TextStyle(
              color: GwentColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: GwentColors.onSurface,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
