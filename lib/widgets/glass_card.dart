import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// A frosted glass card with background blur effect.
///
/// Wraps content in a translucent container with [BackdropFilter]
/// for the iOS liquid glass look. Adapts opacity and blur per
/// brightness (light = more transparent, dark = more frosted).
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? elevation;
  final Color? backgroundColor;
  final Border? border;
  final Clip clipBehavior;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.elevation,
    this.backgroundColor,
    this.border,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Frosted background: semi-transparent with tint from surface
    final glassBg = backgroundColor ??
        (isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.55)
            : theme.colorScheme.surface.withValues(alpha: 0.72));

    // Subtle border highlight
    final glassBorder = border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.60),
          width: 0.5,
        );

    final borderRadiusGeometry = BorderRadius.circular(borderRadius);

    // Inner shadow for depth
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: glassBg,
        borderRadius: borderRadiusGeometry,
        border: glassBorder,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.20)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: elevation ?? 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: clipBehavior,
      child: ClipRRect(
        borderRadius: borderRadiusGeometry,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: onTap != null
                ? InkWell(
                    onTap: onTap,
                    borderRadius: borderRadiusGeometry,
                    splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                    highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
                    child: Padding(
                      padding: padding ?? const EdgeInsets.all(16),
                      child: child,
                    ),
                  )
                : Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
          ),
        ),
      ),
    );

    return card;
  }
}

/// A section header label used above glass card groups.
class GlassSectionLabel extends StatelessWidget {
  final String label;
  const GlassSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
