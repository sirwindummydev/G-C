import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/data/models/category.dart';
import 'package:gnc_app/data/models/menu_item.dart';
import 'package:gnc_app/data/models/shop_settings.dart';
import 'package:gnc_app/data/repositories/local/local_menu_repository.dart';
import 'package:gnc_app/data/repositories/menu_repository.dart';
import 'package:gnc_app/data/seed/seed_menu.dart';

void main() {
  late LocalMenuRepository repository;

  setUp(() => repository = LocalMenuRepository(latency: Duration.zero));
  tearDown(() => repository.dispose());

  test('serves the full seed menu', () async {
    final categories = await repository.watchCategories().first;
    final items = await repository.watchItems().first;
    final combos = await repository.watchCombos().first;

    expect(
      categories.map((c) => c.name),
      containsAll(['Takoyaki', 'Combos', 'Drinks']),
    );
    expect(
      items.where((i) => i.categoryId == SeedMenu.takoyakiCategory),
      hasLength(6),
    );
    expect(items.where((i) => i.id == SeedMenu.fruitSoda), hasLength(1));
    expect(combos.map((c) => c.price), containsAll([14000, 27000, 11500]));
  });

  test('pushes changes to watchers', () async {
    final stream = repository.watchItems();
    final expectation = expectLater(
      stream.map(
        (items) =>
            items.firstWhere((i) => i.id == 'takoyaki-octopus').isAvailable,
      ),
      emitsInOrder([true, false]),
    );
    await Future<void>.delayed(Duration.zero);
    final items = await repository.watchItems().first;
    final octopus = items.firstWhere((i) => i.id == 'takoyaki-octopus');
    await repository.saveItem(octopus.copyWith(isAvailable: false));
    await expectation;
  });

  test('adds and deletes entries', () async {
    await repository.saveCategory(
      const Category(id: 'desserts', name: 'Desserts'),
    );
    expect(
      (await repository.watchCategories().first).map((c) => c.id),
      contains('desserts'),
    );
    await repository.deleteCategory('desserts');
    expect(
      (await repository.watchCategories().first).map((c) => c.id),
      isNot(contains('desserts')),
    );
  });

  test('saves shop settings', () async {
    final settings = await repository.watchShopSettings().first;
    await repository.saveShopSettings(settings.copyWith(isPaused: true));
    expect((await repository.watchShopSettings().first).isPaused, isTrue);
  });

  test('fails with a friendly error when offline', () async {
    repository.simulateOffline = true;
    await expectLater(
      repository.watchItems().first,
      throwsA(isA<RepositoryException>()),
    );
    await expectLater(
      repository.saveShopSettings(const ShopSettings(shopName: 'x')),
      throwsA(isA<RepositoryException>()),
    );
  });

  test('items survive a map round trip (for Firestore)', () async {
    final items = await repository.watchItems().first;
    for (final item in items) {
      final copy = MenuItem.fromMap(item.id, item.toMap());
      expect(copy.toMap(), item.toMap());
    }
  });

  test('reading tolerates missing and mistyped fields', () {
    final item = MenuItem.fromMap('x', {
      'name': 'Mystery',
      'basePrice': '12',
      'optionGroups': 'nope',
    });
    expect(item.name, 'Mystery');
    expect(item.basePrice, 0);
    expect(item.optionGroups, isEmpty);
    expect(item.isAvailable, isTrue);
  });
}
