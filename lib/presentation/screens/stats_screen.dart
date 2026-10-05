import 'package:flutter/material.dart';

import '../controllers/settings_controller.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';
import '../widgets/board_background.dart';

/// Match statistics accumulated across sessions.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(strings.stats)),
      body: BoardBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: settings,
            builder: (context, _) {
              final stats = settings.stats;
              if (stats.matches == 0) {
                return Center(
                  child: Text(
                    strings.noMatchesYet,
                    style: const TextStyle(color: GwentColors.onSurfaceVariant),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _StatTile(label: strings.matches, value: '${stats.matches}'),
                  _StatTile(label: strings.won, value: '${stats.wins}'),
                  _StatTile(label: strings.losses, value: '${stats.losses}'),
                  _StatTile(label: strings.draws, value: '${stats.draws}'),
                  _StatTile(
                    label: strings.winRate,
                    value: '${(stats.winRate * 100).round()}%',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GwentColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: GwentColors.onSurfaceVariant,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: GwentColors.goldBright,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
