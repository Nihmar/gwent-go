import 'package:flutter/material.dart';

/// Plays a short scale/fade entrance when a card is added to a row.
///
/// It runs once per widget instance; the parent stack keys each card by uid, so
/// rebuilds and neighbours moving do not replay the animation.
class EntranceCard extends StatefulWidget {
  const EntranceCard({super.key, required this.child});

  final Widget child;

  @override
  State<EntranceCard> createState() => _EntranceCardState();
}

class _EntranceCardState extends State<EntranceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..forward();

  late final Animation<double> _scale = Tween<double>(
    begin: 0.85,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

/// A number that fades/scales when its value changes (row and player scores).
class AnimatedScore extends StatelessWidget {
  const AnimatedScore({super.key, required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 220),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: animation, child: child),
    ),
    child: Text('$value', key: ValueKey<int>(value), style: style),
  );
}

/// One-shot coloured glow used to show that an ability affected a card.
///
/// The animation is driven purely by [flashKey]: whenever it increments the
/// glow replays. There is no timer to clear, so widget tests still settle.
class AbilityFlash extends StatefulWidget {
  const AbilityFlash({
    super.key,
    required this.flashKey,
    required this.color,
    required this.radius,
    required this.child,
  });

  final int flashKey;
  final Color color;
  final double radius;
  final Widget child;

  @override
  State<AbilityFlash> createState() => _AbilityFlashState();
}

class _AbilityFlashState extends State<AbilityFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _glow = Tween<double>(
    begin: 1,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    if (widget.flashKey > 0) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(AbilityFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashKey != oldWidget.flashKey && widget.flashKey > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _glow,
              builder: (context, _) {
                final value = _glow.value;
                if (value <= 0.01) return const SizedBox.shrink();
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    border: Border.all(
                      color: widget.color.withValues(alpha: value),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.7 * value),
                        blurRadius: 18 * value,
                        spreadRadius: 2 * value,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
