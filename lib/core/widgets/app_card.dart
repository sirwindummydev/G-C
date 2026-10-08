import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// White rounded card with a soft neutral shadow and ripple feedback.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.radius = AppTheme.radius,
    this.color = AppColors.card,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border ?? BorderSide.none,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

enum PillTone {
  /// Blue, for savings and "Best value".
  accent,

  /// Grey, for "Sold out".
  muted,

  /// Orange.
  brand,
}

/// Small rounded label such as "Sold out", "Save ₱10" or "Best value".
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    this.tone = PillTone.brand,
    this.icon,
    this.elevated = false,
  });

  /// Soft shadow that keeps labels readable on busy photos.
  static const softShadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Adds [softShadow]; use when the pill sits on a photo.
  final bool elevated;

  final String text;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      PillTone.accent => (AppColors.accentDark, Colors.white),
      PillTone.muted => (AppColors.disabled, AppColors.textMuted),
      PillTone.brand => (AppColors.primary, AppColors.text),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        boxShadow: elevated ? softShadow : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: fg, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Round "+" button with a scale-press effect.
class RoundAddButton extends StatefulWidget {
  const RoundAddButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 40,
    this.outlined = false,
  });

  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;

  /// Orange outline and icon on white, instead of a solid orange circle.
  final bool outlined;

  @override
  State<RoundAddButton> createState() => _RoundAddButtonState();
}

class _RoundAddButtonState extends State<RoundAddButton> {
  bool _pressed = false;
  bool _done = false;

  Future<void> _handleTap() async {
    widget.onPressed?.call();
    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _done = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.semanticLabel,
        excludeFromSemantics: true,
        child: Listener(
          onPointerDown: enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onPointerCancel: (_) => setState(() => _pressed = false),
          onPointerUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.88 : (_done ? 1.12 : 1),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: Material(
              // Confirmation: solid orange with a dark check (dark icons on
              // orange fills, everywhere).
              color: !enabled
                  ? AppColors.disabled
                  : _done
                  ? AppColors.primary
                  : (widget.outlined ? AppColors.card : AppColors.primary),
              shape: CircleBorder(
                side: widget.outlined && enabled && !_done
                    ? const BorderSide(color: AppColors.primary, width: 1.5)
                    : BorderSide.none,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? _handleTap : null,
                child: SizedBox.square(
                  dimension: widget.size,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      _done ? Icons.check_rounded : Icons.add_rounded,
                      key: ValueKey(_done),
                      color: widget.outlined && !_done && enabled
                          ? AppColors.priceOrange
                          : AppColors.text,
                      size: widget.size * 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
