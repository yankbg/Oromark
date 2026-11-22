// lib/core/widgets/staggered_fade_in.dart
//
// Wraps a list item so it fades/slides into place a little after the one
// before it, instead of every row appearing at once. Pure implicit
// animation (AnimatedOpacity/AnimatedSlide) — no AnimationController to
// manage, so it's safe to drop around any list item without adding
// lifecycle risk. Give it the item's own stable key (not an index-based
// one), same as you would any other list-item widget.

import 'package:flutter/material.dart';

class StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;

  // How much extra delay each subsequent item gets, capped at
  // [maxStaggeredIndex] so a long list doesn't take seconds to finish
  // revealing — items past the cap all start together at the capped delay.
  final Duration step;
  final Duration duration;
  final int maxStaggeredIndex;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 200),
    this.maxStaggeredIndex = 10,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final cappedIndex = widget.index.clamp(0, widget.maxStaggeredIndex);
    final delay = widget.step * cappedIndex;
    if (delay == Duration.zero) {
      _visible = true;
    } else {
      Future.delayed(delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: widget.duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
