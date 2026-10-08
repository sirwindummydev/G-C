import 'dart:async';

import '../../models/category.dart';
import '../../models/combo.dart';
import '../../models/menu_item.dart';
import '../../models/shop_settings.dart';
import '../../models/promo_code.dart';
import '../menu_repository.dart';
import '../promo_repository.dart';
import '../../seed/seed_menu.dart';

/// In-memory [MenuRepository] filled with the seed menu. No internet needed.
///
/// It imitates a network: every call waits [latency], and when
/// [simulateOffline] is on, calls fail with a [RepositoryException] so the
/// loading, error and retry states can be tested. Changes are kept until the
/// app restarts.
class LocalMenuRepository implements MenuRepository, PromoRepository {
  LocalMenuRepository({
    this.latency = const Duration(milliseconds: 500),
    SeedMenu? seed,
  }) {
    final data = seed ?? SeedMenu.standard();
    for (final c in data.categories) {
      _categories[c.id] = c;
    }
    for (final i in data.items) {
      _items[i.id] = i;
    }
    for (final c in data.combos) {
      _combos[c.id] = c;
    }
    _settings = data.settings;
    for (final p in data.promos) {
      _promos[p.code] = p;
    }
  }

  final Duration latency;
  bool simulateOffline = false;

  final _categories = <String, Category>{};
  final _items = <String, MenuItem>{};
  final _combos = <String, Combo>{};
  late ShopSettings _settings;
  final _promos = <String, PromoCode>{};

  final _categoryChanges = StreamController<void>.broadcast();
  final _itemChanges = StreamController<void>.broadcast();
  final _comboChanges = StreamController<void>.broadcast();
  final _settingsChanges = StreamController<void>.broadcast();
  final _promoChanges = StreamController<void>.broadcast();

  @override
  Stream<List<Category>> watchCategories() =>
      _watch(() => _categories.values.toList(), _categoryChanges.stream);

  @override
  Stream<List<MenuItem>> watchItems() =>
      _watch(() => _items.values.toList(), _itemChanges.stream);

  @override
  Stream<List<Combo>> watchCombos() =>
      _watch(() => _combos.values.toList(), _comboChanges.stream);

  @override
  Stream<ShopSettings> watchShopSettings() =>
      _watch(() => _settings, _settingsChanges.stream);

  @override
  Stream<List<PromoCode>> watchPromoCodes() =>
      _watch(() => _promos.values.toList(), _promoChanges.stream);

  @override
  Future<void> savePromoCode(PromoCode promo) => _write(() {
    _promos[promo.code] = promo;
    _promoChanges.add(null);
  });

  @override
  Future<void> saveCategory(Category category) => _write(() {
    _categories[category.id] = category;
    _categoryChanges.add(null);
  });

  @override
  Future<void> deleteCategory(String categoryId) => _write(() {
    _categories.remove(categoryId);
    _categoryChanges.add(null);
  });

  @override
  Future<void> saveItem(MenuItem item) => _write(() {
    _items[item.id] = item;
    _itemChanges.add(null);
  });

  @override
  Future<void> deleteItem(String itemId) => _write(() {
    _items.remove(itemId);
    _itemChanges.add(null);
  });

  @override
  Future<void> saveCombo(Combo combo) => _write(() {
    _combos[combo.id] = combo;
    _comboChanges.add(null);
  });

  @override
  Future<void> deleteCombo(String comboId) => _write(() {
    _combos.remove(comboId);
    _comboChanges.add(null);
  });

  @override
  Future<void> saveShopSettings(ShopSettings settings) => _write(() {
    _settings = settings;
    _settingsChanges.add(null);
  });

  Future<void> dispose() async {
    await Future.wait([
      _categoryChanges.close(),
      _itemChanges.close(),
      _comboChanges.close(),
      _settingsChanges.close(),
      _promoChanges.close(),
    ]);
  }

  Future<void> _simulateNetwork() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (simulateOffline) {
      throw const RepositoryException(
        "Can't reach G&C right now. Check your connection and try again.",
      );
    }
  }

  Future<void> _write(void Function() apply) async {
    await _simulateNetwork();
    apply();
  }

  Stream<T> _watch<T>(T Function() read, Stream<void> changes) {
    StreamSubscription<void>? sub;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () async {
        sub = changes.listen((_) => controller.add(read()));
        try {
          await _simulateNetwork();
          if (!controller.isClosed) controller.add(read());
        } catch (error, stack) {
          if (!controller.isClosed) controller.addError(error, stack);
        }
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }
}
