import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(space5),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: borderRadius ?? BorderRadius.circular(radiusLg),
            border: border ?? Border.all(color: AppColors.borderHairline),
          ),
          child: child,
        ),
      ),
    );
  }
}
