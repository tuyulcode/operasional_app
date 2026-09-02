import 'package:flutter/material.dart';

/// Drop-in replacement for `GestureDetector(onTap: ..., child: ...)` that
/// adds a visible press feedback (ripple) — GestureDetector alone gives
/// zero visual response when tapped, which makes buttons/cards feel dead.
///
/// Pass [borderRadius] matching the child's own decoration so the ripple
/// stays clipped to the same rounded shape instead of spilling into a
/// square. Use [circular: true] for round avatars/icon buttons instead.
class Tappable extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final bool circular;
  final Color? splashColor;
  final Color? highlightColor;

  const Tappable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.circular = false,
    this.splashColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: circular ? const CircleBorder() : null,
      borderRadius: circular ? null : (borderRadius ?? BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: circular ? const CircleBorder() : null,
        borderRadius: circular ? null : borderRadius,
        splashColor: splashColor,
        highlightColor: highlightColor,
        child: child,
      ),
    );
  }
}