import 'package:flutter/material.dart';

import '../../core/models/card.dart';
import '../theme/gwent_colors.dart';
import 'card_assets.dart';

/// A single Gwent card, composed entirely from widgets.
///
/// Artwork and icon sprites are the only raster assets; frames, banners and
/// states are drawn with Flutter primitives so the card scales on any screen.
class GwentCard extends StatelessWidget {
  const GwentCard({
    super.key,
    required this.definition,
    this.strength,
    this.width = 64,
    this.showName = true,
    this.selected = false,
    this.dim = false,
    this.highlighted = false,
    this.onTap,
  });

  final CardDefinition definition;
  final int? strength;
  final double width;
  final bool showName;
  final bool selected;
  final bool dim;
  final bool highlighted;
  final VoidCallback? onTap;

  double get _height => width * 6.35 / 4.45;

  @override
  Widget build(BuildContext context) {
    final radius = width * 0.095;
    final showStrength = definition.isUnit || definition.isHero;
    final shownStrength = strength ?? definition.baseStrength;

    Widget card = SizedBox(
      width: width,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _Frame(
              definition: definition,
              radius: radius,
              highlighted: highlighted,
            ),
          ),
          if (definition.isSpecial || definition.isWeather)
            Positioned.fill(
              child: Center(
                child: _PowerBadge(
                  definition: definition,
                  strength: null,
                  size: width * 0.54,
                ),
              ),
            )
          else
            Positioned(
              left: -width * 0.1,
              top: -width * 0.1,
              child: _PowerBadge(
                definition: definition,
                strength: showStrength ? shownStrength : null,
                size: width * 0.44,
              ),
            ),
          if (CardAssets.rowIcon(definition.row) case final rowIcon?)
            Positioned(
              right: width * 0.055,
              top: width * 0.055,
              child: _IconTag(size: width * 0.26, asset: rowIcon),
            ),
          if (CardAssets.abilityIcon(definition) case final abilityIcon?)
            Positioned(
              right: width * 0.05,
              bottom: width * 0.045,
              child: _IconTag(
                size: width * 0.22,
                asset: abilityIcon,
                opacity: 0.95,
              ),
            ),
          if (showName)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _NameBanner(name: definition.name, width: width),
            ),
        ],
      ),
    );

    if (dim) {
      card = Opacity(opacity: 0.7, child: card);
    }
    if (selected) {
      card = Transform.translate(offset: Offset(0, -width * 0.18), child: card);
    }
    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: card),
      );
    }
    return card;
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.definition,
    required this.radius,
    required this.highlighted,
  });

  final CardDefinition definition;
  final double radius;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final borderColor = definition.isHero
        ? GwentColors.goldBright.withValues(alpha: 0.78)
        : GwentColors.parchment.withValues(alpha: 0.3);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: const Color(0xFF0D0B08),
        boxShadow: [
          if (highlighted)
            BoxShadow(
              color: GwentColors.goldBright.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: highlighted ? GwentColors.goldBright : borderColor,
          width: highlighted ? 2 : (definition.isHero ? 1.6 : 1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            CardAssets.art(definition),
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.55),
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: Color(0xFF241F19)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0, 0.32, 0.56],
                colors: [Color(0xEB0A0704), Color(0x730A0704), Color(0x000A0704)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerBadge extends StatelessWidget {
  const _PowerBadge({
    required this.definition,
    required this.strength,
    required this.size,
  });

  final CardDefinition definition;
  final int? strength;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hero = definition.isHero;
    final scale = hero ? 1.0 : 1.955;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: scale,
            child: Image.asset(
              CardAssets.powerBadge(definition),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
          if (strength != null)
            Text(
              '$strength',
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
                height: 1,
                color: hero ? const Color(0xFFF7E8C2) : const Color(0xFF221806),
                shadows: const [
                  Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _IconTag extends StatelessWidget {
  const _IconTag({required this.size, required this.asset, this.opacity = 1});

  final double size;
  final String asset;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x990A0805),
        ),
        padding: EdgeInsets.all(size * 0.16),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _NameBanner extends StatelessWidget {
  const _NameBanner({required this.name, required this.width});

  final String name;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.09,
        vertical: width * 0.06,
      ),
      child: Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: width * 0.115,
          height: 1.15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFF1E6CD),
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}
