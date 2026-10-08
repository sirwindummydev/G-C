import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/components.dart';
import '../../domain/shop_hours.dart';
import '../dev/dev_panel.dart';
import '../menu/menu_providers.dart';

/// Profile tab. Sign-in (email and Google) arrives in Phase 4; for now it
/// shows the shop's details and, during development, developer options.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(shopSettingsProvider).value;
    final theme = Theme.of(context);
    final hours = [...?settings?.openingHours]
      ..sort((a, b) => a.weekday.compareTo(b.weekday));

    return Scaffold(
      backgroundColor: AppColors.peachTop,
      body: PeachSheetLayout(
        topBar: const AppTopBar(title: 'Profile'),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Gap.screen,
            Gap.section,
            Gap.screen,
            MediaQuery.paddingOf(context).bottom + Gap.section,
          ),
          children: [
            AppCard(
              padding: const EdgeInsets.all(Gap.screen),
              child: Row(
                children: [
                  const BrandLogo(height: 56),
                  const SizedBox(width: Gap.l),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, guest', style: AppText.sectionTitle()),
                        const SizedBox(height: Gap.xs),
                        Text(
                          'Signing in arrives soon, so you can save your '
                          'details and see past orders.',
                          style: AppText.description(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(
              'Opening hours',
              padding: EdgeInsets.only(top: Gap.section, bottom: Gap.m),
            ),
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.screen,
                vertical: Gap.m,
              ),
              child: hours.isEmpty
                  ? Text(
                      'Hours coming soon.',
                      style: theme.textTheme.bodyMedium,
                    )
                  : Column(
                      children: [
                        for (final window in hours)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    DateFormat.EEEE().format(
                                      DateTime.utc(2024, 1, window.weekday),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  ShopHours.formatWindow(window),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: Gap.m),
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: Gap.s),
                Expanded(
                  child: Text(
                    'Pickup only · pay at pickup',
                    style: AppText.description(),
                  ),
                ),
              ],
            ),
            if (AppConfig.devToolsEnabled) ...[
              const SizedBox(height: Gap.section),
              AppCard(
                onTap: () => showDevPanel(context),
                child: const ListTile(
                  leading: Icon(Icons.developer_mode_rounded),
                  title: Text('Developer options'),
                  subtitle: Text('Switch to admin view, test offline mode'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
