import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Sticky bottom bar on detail and cart screens: optional quantity row,
/// what is still missing, "You save" text, and a full-width button.
class OrderBar extends StatelessWidget {
  const OrderBar({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.hint,
    this.savingsText,
    this.leading,
  });

  final String buttonText;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Explains why the button is disabled, e.g. "Choose a flavour."
  final String? hint;
  final String? savingsText;

  /// Usually a [QuantityStepper], shown in a row above the button.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Gap.screen,
            Gap.m,
            Gap.screen,
            Gap.m,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leading != null || savingsText != null || hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.m),
                  child: Row(
                    children: [
                      ?leading,
                      const SizedBox(width: Gap.m),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: savingsText != null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Icon(
                                      Icons.savings_outlined,
                                      size: 18,
                                      color: AppColors.accentDark,
                                    ),
                                    const SizedBox(width: Gap.xs),
                                    Flexible(
                                      child: Text(
                                        savingsText!,
                                        textAlign: TextAlign.end,
                                        style: textTheme.labelLarge?.copyWith(
                                          color: AppColors.accentDark,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  hint ?? '',
                                  textAlign: TextAlign.end,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              FilledButton(
                onPressed: onPressed,
                child: Text(
                  buttonText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// − 1 + control for quantities: outlined orange "−", the number, and a
/// filled orange "+" with a dark icon.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.compact = false,
    this.itemName,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// Small version for cart rows and recommended cards.
  final bool compact;

  /// Used in screen reader labels, e.g. "Decrease Octopus".
  final String? itemName;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 40.0;
    final what = itemName == null ? 'quantity' : itemName!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          tooltip: 'Decrease $what',
          size: size,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Semantics(
          label: 'Quantity $value',
          excludeSemantics: true,
          liveRegion: true,
          child: SizedBox(
            width: compact ? 22 : 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppText.itemName(size: compact ? 14 : 17),
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          tooltip: 'Increase $what',
          size: size,
          filled: true,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final double size;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final Color background;
    final Color foreground;
    BorderSide side = BorderSide.none;
    if (!enabled) {
      background = filled ? AppColors.disabled : Colors.transparent;
      foreground = AppColors.borderStrong;
      if (!filled) side = const BorderSide(color: AppColors.border, width: 1.5);
    } else if (filled) {
      background = AppColors.primary;
      foreground = AppColors.text;
    } else {
      background = Colors.transparent;
      foreground = AppColors.priceOrange;
      side = const BorderSide(color: AppColors.primary, width: 1.5);
    }
    // A tap area a little larger than the circle.
    final target = size < 34 ? 34.0 : size;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: target / 2 + 2,
        child: SizedBox.square(
          dimension: target,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: ShapeDecoration(
                color: background,
                shape: CircleBorder(side: side),
              ),
              child: Icon(icon, size: size * 0.55, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
