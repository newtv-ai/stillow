import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/stillow_theme.dart';

class StillowBackdrop extends StatelessWidget {
  const StillowBackdrop({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 18, 24, 28),
    this.showGlow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [StillowColors.backgroundSoft, StillowColors.background],
        ),
      ),
      child: Stack(
        children: [
          if (showGlow)
            const Positioned(top: -150, right: -130, child: _BackgroundGlow()),
          SafeArea(
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 330,
        height: 330,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0x223F6A5C), Color(0x003F6A5C)],
          ),
        ),
      ),
    );
  }
}

class SoftChoiceCard extends StatelessWidget {
  const SoftChoiceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final radius = dense ? 20.0 : 24.0;
    final iconExtent = dense ? 40.0 : 48.0;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected
            ? StillowColors.surfaceRaised
            : StillowColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: dense
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                : const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected ? StillowColors.sage : StillowColors.outline,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: iconExtent,
                  height: iconExtent,
                  decoration: BoxDecoration(
                    color: StillowColors.backgroundSoft,
                    borderRadius: BorderRadius.circular(dense ? 14 : 17),
                  ),
                  child: Icon(
                    icon,
                    size: dense ? 22 : 24,
                    color: StillowColors.sage,
                  ),
                ),
                SizedBox(width: dense ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: dense
                            ? Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                height: 1.25,
                              )
                            : Theme.of(context).textTheme.titleLarge,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: dense ? 6 : 8),
                Icon(
                  selected ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  size: dense ? 19 : 20,
                  color: selected
                      ? StillowColors.moon
                      : StillowColors.linenMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StillowWordmark extends StatelessWidget {
  const StillowWordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -math.pi / 12,
          child: Icon(
            Icons.bedtime_outlined,
            size: compact ? 19 : 22,
            color: StillowColors.moon,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'Stillow',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: compact ? 18 : 21,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class AmbientOrb extends StatefulWidget {
  const AmbientOrb({
    super.key,
    required this.active,
    this.size = 190,
    this.icon,
  });

  final bool active;
  final double size;
  final IconData? icon;

  @override
  State<AmbientOrb> createState() => _AmbientOrbState();
}

class _AmbientOrbState extends State<AmbientOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _breath = Tween<double>(
      begin: 0.97,
      end: 1.035,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AmbientOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.animateBack(0, duration: const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _breath,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0x806E887A), Color(0x403F5A51), Color(0x003F5A51)],
            stops: [0, 0.58, 1],
          ),
          border: Border.all(color: StillowColors.sage.withValues(alpha: 0.3)),
        ),
        child: widget.icon == null
            ? null
            : Icon(
                widget.icon,
                color: StillowColors.linen.withValues(alpha: 0.88),
                size: widget.size * 0.2,
              ),
      ),
    );
  }
}

class QuietIconButton extends StatelessWidget {
  const QuietIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: StillowColors.linenMuted,
      style: IconButton.styleFrom(
        backgroundColor: StillowColors.surface.withValues(alpha: 0.7),
      ),
    );
  }
}
