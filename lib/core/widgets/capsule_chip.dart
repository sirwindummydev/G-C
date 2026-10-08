import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// The one option chip used for every choice in the app: flavours, sizes,
/// and combo picks.
///
/// A 40px pill inside a 48px tap target. Unselected: white with a light
/// border and an optional colour dot. Selected: cream with an orange border,
/// and the dot becomes a check icon so selection never relies on colour.
/// Sold out: grey, "Sold out" label, not tappable.
class CapsuleChip extends StatelessWidget {
  const CapsuleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.semanticLabel,
    this.dotColor,
    this.detail,
    this.badge,
    this.soldOut = false,
    this.count = 0,
    this.onRemove,
    this.removeTooltip,
    this.radioStyle = true,
  });

  final String label;
  final bool selected;

  /// Null makes the chip not tappable. Unselected chips without a tap
  /// action are shown faded (e.g. when a multi-select group is full).
  final VoidCallback? onTap;

  /// Full screen reader text, e.g. "Lemon, flavour, selected".
  final String semanticLabel;

  /// The flavour colour dot (hidden when selected or sold out).
  final Color? dotColor;

  /// Secondary text after the label, e.g. "₱50" → "16oz · ₱50".
  final String? detail;

  /// Small blue tag inside the chip, e.g. "Best value".
  final String? badge;
  final bool soldOut;

  /// Shows "×n" when the same item is picked more than once (combos).
  final int count;

  /// Shows a small "−" inside the chip to remove one pick (combos).
  final VoidCallback? onRemove;
  final String? removeTooltip;

  /// Radio-button semantics for single-choice groups.
  final bool radioStyle;

  static const _duration = Duration(milliseconds: 150);
  static const _border = Color(0xFFE8DDD3);
  static const _soldOutBg = Color(0xFFF3EEE9);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final faded = !selected && !soldOut && onTap == null;
    final background = soldOut
        ? _soldOutBg
        : selected
        ? AppColors.illustrationBg
        : AppColors.card;
    final border = selected
        ? const BorderSide(color: AppColors.primary, width: 1.5)
        : const BorderSide(color: _border);
    final textColor = soldOut ? AppColors.textMuted : AppColors.text;

    Widget? leading;
    if (selected) {
      leading = const Icon(
        Icons.check_rounded,
        key: ValueKey('check'),
        size: 16,
        color: AppColors.primaryDark,
      );
    } else if (dotColor != null && !soldOut) {
      leading = Container(
        key: const ValueKey('dot'),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
      );
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: _duration,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: leading == null
              ? const SizedBox.shrink(key: ValueKey('none'))
              : Padding(
                  key: leading.key,
                  padding: const EdgeInsets.only(right: Gap.s),
                  child: leading,
                ),
        ),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.2,
          ),
        ),
        if (detail != null && !soldOut)
          Text(
            ' · $detail',
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
        if (count > 1)
          Text(
            '  ×$count',
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              height: 1.2,
            ),
          ),
        if (badge != null && !soldOut) ...[
          const SizedBox(width: Gap.s),
          Pill(text: badge!, tone: PillTone.accent),
        ],
        if (soldOut) ...[
          const SizedBox(width: Gap.s),
          Text(
            'Sold out',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );

    final capsule = AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOut,
      height: 40,
      decoration: ShapeDecoration(
        color: background,
        shape: StadiumBorder(side: border),
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: onRemove == null ? 14 : 6,
                ),
                child: SizedBox(
                  height: 40,
                  child: Center(child: ExcludeSemantics(child: content)),
                ),
              ),
            ),
            if (onRemove != null)
              Tooltip(
                message: removeTooltip ?? 'Remove one $label',
                child: InkWell(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 36,
                    height: 40,
                    child: Center(
                      child: Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 20,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: onTap != null,
      inMutuallyExclusiveGroup: radioStyle,
      label: semanticLabel,
      child: AnimatedOpacity(
        duration: _duration,
        opacity: faded ? 0.45 : 1,
        child: SizedBox(
          height: 48,
          child: Center(widthFactor: 1, child: capsule),
        ),
      ),
    );
  }
}

enum TagTone { required, done, neutral }

/// Small tag in a section header: "Required", "✓ Lemon", "2 of 4 selected".
class HeaderTag extends StatelessWidget {
  const HeaderTag({super.key, required this.text, required this.tone});

  final String text;
  final TagTone tone;

  static const _doneBg = Color(0xFFE5F4EB);
  static const _doneFg = Color(0xFF1E7A45);

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      TagTone.required => (AppColors.notice, AppColors.text),
      TagTone.done => (_doneBg, _doneFg),
      TagTone.neutral => (AppColors.disabled, AppColors.textMuted),
    };
    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tone == TagTone.done) ...[
              Icon(Icons.check_rounded, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
