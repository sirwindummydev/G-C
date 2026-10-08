import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_card.dart';
import '../../core/widgets/async_value_view.dart';
import '../../domain/menu_catalog.dart';
import '../../core/theme/app_theme.dart';
import '../shell/customer_shell.dart';
import '../menu/menu_providers.dart';
import 'menu_photos_section.dart';
import 'promo_codes_section.dart';

/// Admin home. Order management and menu editing arrive in Phase 3; for now
/// it confirms the admin view and shows what is loaded from the data layer.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(menuCatalogProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: Gap.screen,
        title: const Wordmark(text: 'G&C', suffix: 'Admin'),
      ),
      body: AsyncValueView<MenuCatalog>(
        value: catalog,
        onRetry: () => retryMenu(ref),
        data: (catalog) {
          final soldOut = catalog.items.where((i) => !i.isOrderable).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Menu at a glance', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _Stat(label: 'Categories', value: catalog.categories.length),
              _Stat(label: 'Items', value: catalog.items.length),
              _Stat(label: 'Combos', value: catalog.combos.length),
              _Stat(label: 'Sold out items', value: soldOut),
              const SizedBox(height: 24),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.l),
                  child: Text(
                    'Incoming orders and full menu editing arrive in Phase 3.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: Gap.section),
              const PromoCodesSection(),
              const SizedBox(height: Gap.section),
              MenuPhotosSection(catalog: catalog),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text('$value', style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
