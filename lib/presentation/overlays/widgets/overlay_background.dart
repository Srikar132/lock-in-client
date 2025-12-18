import 'package:flutter/material.dart';

class OverlayBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final Color? backgroundColor;

  const OverlayBackground({
    super.key,
    required this.child,
    this.gradient,
    this. backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(
          colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
          begin: Alignment. topCenter,
          end: Alignment. bottomCenter,
        ),
        color: backgroundColor,
      ),
      child: child,
    );
  }
}