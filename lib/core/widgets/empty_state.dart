import 'package:flutter/material.dart';

import '../../data/models/menu_visual.dart';
import '../theme/app_theme.dart';
import 'brand_logo.dart';
import 'menu_image.dart';

/// Friendly empty screen: illustration, title, message and one action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.visual = const MenuVisual(iconKey: 'takoyaki', colorHex: '#7AB648'),
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final MenuVisual visual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuImage(visual: visual, size: 160, borderRadius: 80),
            const SizedBox(height: Gap.xl),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gap.s),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
              child: Text(actionLabel),
            ),
            const SizedBox(height: Gap.xxl),
            // Small, quiet brand sign-off.
            const BrandLogo(height: 48, opacity: 0.55, semanticLabel: null),
          ],
        ),
      ),
    );
  }
}
