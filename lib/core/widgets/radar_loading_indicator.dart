// lib/core/widgets/radar_loading_indicator.dart
//
// A small, self-contained version of the student home screen's scanning-
// hero motif (pulsing orb + expanding wave rings) — this app's branded
// stand-in for a bare CircularProgressIndicator wherever a whole screen or
// section is loading data. Manages its own animation lifecycle so it can
// drop into any screen without that screen owning a controller.
//
// Not a replacement for small inline spinners (e.g. inside a button or an
// avatar while it loads) — those stay as plain CircularProgressIndicators;
// this is sized for "this screen/section is loading" moments only.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RadarLoadingIndicator extends StatefulWidget {
  final double size;
  final IconData icon;

  const RadarLoadingIndicator({
    super.key,
    this.size = 48,
    this.icon = Icons.sensors_rounded,
  });

  @override
  State<RadarLoadingIndicator> createState() => _RadarLoadingIndicatorState();
}

class _RadarLoadingIndicatorState extends State<RadarLoadingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _wave1;
  late final AnimationController _wave2;

  @override
  void initState() {
    super.initState();
    _wave1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _wave2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // Second ring starts half a cycle behind the first so they don't pulse
    // in lockstep.
    _wave2.value = 0.5;
    _wave2.repeat();
  }

  @override
  void dispose() {
    _wave1.dispose();
    _wave2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringMaxSize = widget.size * 2.2;
    return SizedBox(
      width: ringMaxSize,
      height: ringMaxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _wave1,
            builder: (_, __) =>
                _Ring(progress: _wave1.value, baseSize: widget.size),
          ),
          AnimatedBuilder(
            animation: _wave2,
            builder: (_, __) =>
                _Ring(progress: _wave2.value, baseSize: widget.size),
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.28),
                  blurRadius: widget.size * 0.3,
                  spreadRadius: widget.size * 0.06,
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: widget.size * 0.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double progress; // 0..1
  final double baseSize;
  const _Ring({required this.progress, required this.baseSize});

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + progress * 1.2; // grows from 1x to 2.2x
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity * 0.6,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: baseSize,
          height: baseSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
