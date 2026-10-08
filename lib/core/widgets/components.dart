import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// Icon button in a light circle (back, menu, close).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: 20, color: AppColors.text),
          ),
        ),
      ),
    );
  }
}

/// Top bar: optional back button in a light circle, centred serif title,
/// optional trailing action. Transparent, so it sits on the peach header.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.onBack,
    this.trailing,
    this.backTooltip = 'Back',
  });

  final String? title;

  /// Null hides the back button. Defaults to popping when [onBack] is not
  /// given but the route can pop (see [AppTopBar.auto]).
  final VoidCallback? onBack;
  final Widget? trailing;
  final String backTooltip;

  /// A top bar whose back button pops the current route when possible.
  static AppTopBar auto(
    BuildContext context, {
    String? title,
    Widget? trailing,
  }) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return AppTopBar(
      title: title,
      trailing: trailing,
      onBack: canPop ? () => Navigator.of(context).maybePop() : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: preferredSize.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.screen),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: onBack == null
                    ? null
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: CircleIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: backTooltip,
                          onPressed: onBack,
                        ),
                      ),
              ),
              Expanded(
                child: title == null
                    ? const SizedBox.shrink()
                    : Semantics(
                        header: true,
                        child: Text(
                          title!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: serif(fontSize: 22),
                        ),
                      ),
              ),
              SizedBox(
                width: 48,
                child: Align(alignment: Alignment.centerRight, child: trailing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Peach header behind a white content sheet with large rounded top
/// corners (cart, orders, profile).
class PeachSheetLayout extends StatelessWidget {
  const PeachSheetLayout({
    super.key,
    required this.topBar,
    required this.child,
    this.bottom,
  });

  final PreferredSizeWidget topBar;
  final Widget child;

  /// Pinned under the content, inside the sheet (e.g. checkout button).
  final Widget? bottom;

  static const double sheetRadius = 32;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.35],
          colors: [AppColors.peachTop, AppColors.peachBottom],
        ),
      ),
      child: Column(
        children: [
          topBar,
          const SizedBox(height: Gap.s),
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(sheetRadius),
                ),
              ),
              child: Column(
                children: [
                  Expanded(child: child),
                  ?bottom,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Serif section title, optionally with a trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding});

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(Gap.screen, Gap.section, Gap.screen, Gap.m),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppText.sectionTitle()),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Large full-width orange pill button with dark text and a soft orange
/// shadow. Disabled: grey, no shadow.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: enabled ? AppColors.orangeShadow : null,
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(minimumSize: Size.fromHeight(height)),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// One line of a [SummaryCard].
class SummaryRow {
  const SummaryRow(this.label, this.value, {this.emphasis = false});

  final String label;
  final String value;

  /// Shows the value in the accent orange (e.g. savings).
  final bool emphasis;
}

/// White card listing amounts, a dashed divider, then a bold total.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.rows,
    required this.totalLabel,
    required this.totalValue,
    this.footer,
  });

  final List<SummaryRow> rows;
  final String totalLabel;
  final String totalValue;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium;
    return AppCard(
      padding: const EdgeInsets.all(Gap.screen),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.m),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: body?.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  Text(
                    row.value,
                    style: body?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: row.emphasis
                          ? AppColors.priceOrange
                          : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: Gap.xs, bottom: Gap.l),
            child: DashedDivider(),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  totalLabel,
                  style: poppins(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                totalValue,
                style: poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: Gap.m), footer!],
        ],
      ),
    );
  }
}

/// Horizontal dashed line in the divider colour.
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key, this.dash = 6, this.gap = 4});

  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter(dash, gap)),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.dash, this.gap);

  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, 0.5),
        Offset((x + dash).clamp(0, size.width), 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.dash != dash || old.gap != gap;
}
