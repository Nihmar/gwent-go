import 'package:flutter/material.dart';

import '../../core/models/card.dart';
import '../../core/models/game_state.dart';
import '../../core/rules/scoring.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';
import 'card_assets.dart';
import 'gwent_card.dart';

/// One battlefield row: marker, overlapping unit cards and an optional special.
class RowStrip extends StatelessWidget {
  const RowStrip({
    super.key,
    required this.state,
    required this.owner,
    required this.row,
    required this.cardWidth,
    this.leading = false,
    this.highlighted = false,
    this.selectable = false,
    this.onTap,
    this.onCardTap,
  });

  final GameState state;
  final int owner;
  final CardRow row;
  final double cardWidth;
  final bool leading;
  final bool highlighted;
  final bool selectable;
  final VoidCallback? onTap;
  final void Function(CardInstance card)? onCardTap;

  @override
  Widget build(BuildContext context) {
    final rowState = state.rowState(owner, row);
    final total = Scoring.rowTotal(state, rowState);
    final height = cardWidth * 6.35 / 4.45 + 8;

    return GestureDetector(
      onTap: selectable ? onTap : null,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: rowState.weather
                ? [
                    GwentColors.tertiary.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.2),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.16),
                  ],
          ),
          border: Border.all(
            color: highlighted
                ? GwentColors.goldBright
                : rowState.weather
                ? GwentColors.tertiary.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.05),
            width: highlighted ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (CardAssets.rowIcon(row) case final icon?)
                    Image.asset(icon, width: 18, height: 18),
                  const SizedBox(height: 2),
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: leading
                          ? GwentColors.goldBright
                          : GwentColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _CardStack(
                cards: rowState.cards,
                cardWidth: cardWidth,
                onCardTap: onCardTap,
              ),
            ),
            if (rowState.special case final special?) ...[
              const SizedBox(width: 4),
              GwentCard(
                definition: special.definition,
                width: cardWidth * 0.72,
                showName: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardStack extends StatelessWidget {
  const _CardStack({required this.cards, required this.cardWidth, this.onCardTap});

  final List<CardInstance> cards;
  final double cardWidth;
  final void Function(CardInstance card)? onCardTap;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final height = cardWidth * 6.35 / 4.45;
    return LayoutBuilder(
      builder: (context, constraints) {
        final step = cardWidth * 0.84;
        final needed = step * (cards.length - 1) + cardWidth;
        final scale = needed > constraints.maxWidth
            ? (constraints.maxWidth / needed).clamp(0.6, 1.0)
            : 1.0;
        final effective = cardWidth * scale;
        final effectiveStep = effective * 0.84;
        return ClipRect(
          child: SizedBox(
            height: height,
            width: constraints.maxWidth,
            child: Stack(
              children: [
                for (var i = 0; i < cards.length; i++)
                  Positioned(
                    left: i * effectiveStep,
                    top: 0,
                    child: GwentCard(
                      definition: cards[i].definition,
                      strength: cards[i].currentStrength,
                      width: effective,
                      showName: false,
                      onTap: onCardTap == null
                          ? null
                          : () => onCardTap!(cards[i]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The weather zone showing every active weather card.
class WeatherBand extends StatelessWidget {
  const WeatherBand({super.key, required this.state, this.cardWidth = 30});

  final GameState state;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: GwentColors.surfaceLowest.withValues(alpha: 0.7),
        border: Border.all(color: GwentColors.tertiary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(
              strings.weather.toUpperCase(),
              style: const TextStyle(
                color: GwentColors.tertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
              ),
            ),
          ),
          for (final card in state.weatherCards) ...[
            GwentCard(
              definition: card.definition,
              width: cardWidth,
              showName: false,
            ),
            const SizedBox(width: 6),
          ],
          const Spacer(),
          Flexible(
            child: Text(
              state.activeWeather.isEmpty
                  ? strings.clearWeatherNotPlayed
                  : strings.closeRowAtOne,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: GwentColors.tertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deck or graveyard pile with a badge count.
class Pile extends StatelessWidget {
  const Pile({
    super.key,
    required this.count,
    required this.backAsset,
    this.width = 38,
    this.graveyard = false,
    this.icon,
  });

  final int count;
  final String backAsset;
  final double width;
  final bool graveyard;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final height = width * 6.35 / 4.45;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width * 0.09),
              child: Opacity(
                opacity: graveyard ? 0.6 : 1,
                child: Image.asset(backAsset, fit: BoxFit.cover),
              ),
            ),
          ),
          if (icon != null)
            Positioned.fill(
              child: Center(
                child: Icon(icon, size: width * 0.42, color: Colors.white70),
              ),
            ),
          Positioned(right: -6, bottom: -6, child: _CountBadge(count: count)),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xD10A0805),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: GwentColors.parchment,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Round win gems for one player.
class RoundGems extends StatelessWidget {
  const RoundGems({super.key, required this.roundsWon, this.size = 15});

  final int roundsWon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 2; i++) ...[
          Image.asset(
            i < roundsWon ? CardAssets.gemOn() : CardAssets.gemOff(),
            width: size,
            height: size,
          ),
          if (i == 0) const SizedBox(width: 3),
        ],
      ],
    );
  }
}

/// Pulsing "your turn" / "opponent turn" chip.
class TurnChip extends StatelessWidget {
  const TurnChip({super.key, required this.label, this.active = true});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active
            ? GwentColors.gold.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? GwentColors.gold.withValues(alpha: 0.45)
              : GwentColors.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? GwentColors.goldBright : GwentColors.outline,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: active
                  ? GwentColors.goldBright
                  : GwentColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin decorative divider between battlefield halves.
class MidRule extends StatelessWidget {
  const MidRule({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: GwentColors.gold.withValues(alpha: 0.25)),
        ),
        Transform.rotate(
          angle: 0.785,
          child: Container(width: 7, height: 7, color: GwentColors.gold),
        ),
        Expanded(
          child: Divider(color: GwentColors.gold.withValues(alpha: 0.25)),
        ),
      ],
    );
  }
}
