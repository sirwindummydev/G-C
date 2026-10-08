import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/models/category.dart';
import '../../data/models/combo.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/shop_settings.dart';
import '../../data/repositories/providers.dart';
import '../../domain/combo_pricing.dart';
import '../../domain/menu_catalog.dart';
import '../../domain/shop_hours.dart';

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(menuRepositoryProvider).watchCategories(),
);

final menuItemsProvider = StreamProvider<List<MenuItem>>(
  (ref) => ref.watch(menuRepositoryProvider).watchItems(),
);

final combosProvider = StreamProvider<List<Combo>>(
  (ref) => ref.watch(menuRepositoryProvider).watchCombos(),
);

final shopSettingsProvider = StreamProvider<ShopSettings>(
  (ref) => ref.watch(menuRepositoryProvider).watchShopSettings(),
);

/// The whole menu as one value: loading until every part has arrived, an
/// error if any part failed.
final menuCatalogProvider = Provider<AsyncValue<MenuCatalog>>((ref) {
  final categories = ref.watch(categoriesProvider);
  final items = ref.watch(menuItemsProvider);
  final combos = ref.watch(combosProvider);

  for (final part in [categories, items, combos]) {
    if (part.hasError && !part.hasValue) {
      return AsyncError(part.error!, part.stackTrace ?? StackTrace.current);
    }
  }
  if (categories.hasValue && items.hasValue && combos.hasValue) {
    return AsyncData(
      MenuCatalog(
        categories: categories.requireValue,
        items: items.requireValue,
        combos: combos.requireValue,
      ),
    );
  }
  return const AsyncLoading();
});

final comboPricingProvider = Provider<ComboPricing?>((ref) {
  final catalog = ref.watch(menuCatalogProvider).value;
  return catalog == null ? null : ComboPricing(catalog);
});

/// Manila time, refreshed every 30 seconds so open/closed updates on its own.
final manilaNowProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  controller.add(clock.nowInManila());
  final timer = Timer.periodic(
    const Duration(seconds: 30),
    (_) => controller.add(clock.nowInManila()),
  );
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

final shopStatusProvider = Provider<AsyncValue<ShopStatus>>((ref) {
  final settings = ref.watch(shopSettingsProvider);
  final now =
      ref.watch(manilaNowProvider).value ??
      ref.watch(clockProvider).nowInManila();
  return settings.whenData((s) => ShopHours.statusAt(s, now));
});

/// Re-subscribes to all menu data, e.g. from a "Try again" button.
void retryMenu(WidgetRef ref) {
  ref.invalidate(categoriesProvider);
  ref.invalidate(menuItemsProvider);
  ref.invalidate(combosProvider);
  ref.invalidate(shopSettingsProvider);
}
