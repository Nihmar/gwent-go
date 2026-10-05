import 'package:flutter/material.dart';

import '../../../core/data/card_repository.dart';
import '../../../core/data/faction_catalog.dart';
import '../../../core/models/card.dart';
import '../../../core/models/player.dart';
import '../../../core/persistence/profile_repository.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../selectors.dart';

/// Gold-accented tonal action button used on the phone home layout.
class TonalActionButton extends StatelessWidget {
  const TonalActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.height = 48,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

/// Large cinematic banner showing the selected faction artwork.
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.faction,
    required this.eyebrow,
    this.height = 300,
    this.compact = false,
    this.onContinue,
  });

  final CardFaction faction;
  final String eyebrow;
  final double height;
  final bool compact;

  /// When set, a "Continue match" action is shown in the banner.
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              factionInfo(faction).heroAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.4),
              errorBuilder: (context, error, stack) =>
                  const ColoredBox(color: GwentColors.surfaceLow),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: compact
                      ? Alignment.bottomCenter
                      : Alignment.centerLeft,
                  end: compact ? Alignment.topCenter : Alignment.centerRight,
                  colors: const [
                    Color(0xEB0A0704),
                    Color(0x8A0A0704),
                    Color(0x1A0A0704),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 18 : 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      color: GwentColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.appTitle,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: compact ? 40 : 62,
                      height: 1,
                      letterSpacing: compact ? 4 : 6,
                      color: GwentColors.goldBright,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 360 : 520),
                    child: Text(
                      strings.appAbout,
                      style: const TextStyle(
                        color: GwentColors.onSurface,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (!compact && onContinue != null) ...[
                    const SizedBox(height: 14),
                    FilledButton.tonalIcon(
                      onPressed: onContinue,
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(strings.continueMatch),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase section label.
class HomeSectionLabel extends StatelessWidget {
  const HomeSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: GwentColors.onSurfaceVariant,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
    ),
  );
}

/// Compact feature chip.
class HomeChip extends StatelessWidget {
  const HomeChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(text),
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

/// Bordered surface used by the desktop panels.
class HomeSurface extends StatelessWidget {
  const HomeSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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

const TextStyle homeSurfaceTitle = TextStyle(
  color: GwentColors.onSurfaceVariant,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.6,
);

/// Difficulty + faction picker with the start action (desktop layout).
class NewMatchPanel extends StatelessWidget {
  const NewMatchPanel({
    super.key,
    required this.difficulty,
    required this.faction,
    required this.deck,
    required this.onDifficulty,
    required this.onFaction,
    required this.onStart,
    required this.onStartLocal,
  });

  final Difficulty difficulty;
  final CardFaction faction;
  final DeckDefinition deck;
  final ValueChanged<Difficulty> onDifficulty;
  final ValueChanged<CardFaction> onFaction;
  final VoidCallback onStart;

  /// Starts a match where two humans share the device.
  final VoidCallback onStartLocal;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return HomeSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.newMatch, style: homeSurfaceTitle),
          const SizedBox(height: 16),
          _fieldLabel(strings.opponentDifficulty),
          const SizedBox(height: 8),
          DifficultySelector(value: difficulty, onChanged: onDifficulty),
          const SizedBox(height: 6),
          Text(
            strings.difficultyDescription(difficulty),
            style: const TextStyle(
              color: GwentColors.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),
          _fieldLabel(strings.faction),
          const SizedBox(height: 8),
          FactionSelector(value: faction, onChanged: onFaction),
          const Spacer(),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.double_arrow_rounded),
                label: Text(strings.startMatch),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onStartLocal,
                child: Text(strings.localMatch),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${strings.factionName(faction)} · ${deck.leader.name}',
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Recent decks list and current deck stats (desktop layout).
class DecksPanel extends StatelessWidget {
  const DecksPanel({
    super.key,
    required this.deck,
    required this.onManage,
    required this.onSelect,
    required this.stats,
  });

  final DeckDefinition deck;
  final VoidCallback onManage;
  final ValueChanged<DeckDefinition> onSelect;
  final MatchStats stats;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final decks = CardRepository.defaultDecks();
    return HomeSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(strings.recentDecks, style: homeSurfaceTitle),
              const Spacer(),
              TextButton(onPressed: onManage, child: Text(strings.manageDecks)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: decks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = decks[index];
                return _DeckTile(
                  deck: item,
                  selected: item.id == deck.id,
                  onTap: () => onSelect(item),
                );
              },
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              _Stat(label: strings.matches, value: '${stats.matches}'),
              _Stat(label: strings.won, value: '${stats.wins}'),
              _Stat(
                label: strings.winRate,
                value: '${(stats.winRate * 100).round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({
    required this.deck,
    required this.selected,
    required this.onTap,
  });

  final DeckDefinition deck;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = factionInfo(deck.faction);
    final strings = context.strings;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? GwentColors.gold.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: selected
                ? GwentColors.gold.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                info.deckBackAsset,
                width: 36,
                height: 51,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${strings.factionName(deck.faction)} · '
                    '${deck.totalCards} ${strings.cards} · '
                    '${CardRepository.deckStrength(deck)} ${strings.strength}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GwentColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: GwentColors.goldBright),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: GwentColors.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: GwentColors.goldBright,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _fieldLabel(String text) => Text(
  text.toUpperCase(),
  style: const TextStyle(
    color: GwentColors.onSurfaceVariant,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  ),
);
