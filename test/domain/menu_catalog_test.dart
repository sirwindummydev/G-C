import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/data/models/combo.dart';
import 'package:gnc_app/data/models/menu_item.dart';
import 'package:gnc_app/data/seed/seed_menu.dart';

import '../helpers.dart';

void main() {
  final catalog = seedCatalog();

  group('photos', () {
    test('takoyaki items use the category default photo', () {
      for (final item in catalog.itemsIn(SeedMenu.takoyakiCategory)) {
        expect(item.image, isNull);
        expect(catalog.imageForItem(item), SeedMenu.takoyakiPhoto);
      }
    });

    test('drinks keep the illustration', () {
      final soda = catalog.itemById(SeedMenu.fruitSoda)!;
      expect(catalog.imageForItem(soda), isNull);
    });

    test("an item's own photo wins over the default", () {
      final octopus = catalog
          .itemById('takoyaki-octopus')!
          .copyWith(image: () => 'https://example.com/octopus.jpg');
      expect(catalog.imageForItem(octopus), 'https://example.com/octopus.jpg');
    });

    test('combos use the photo of what they contain, in slot order', () {
      for (final id in ['takoyaki-duo', 'barkada-box', 'merienda-combo']) {
        expect(
          catalog.imageForCombo(catalog.comboById(id)!),
          SeedMenu.takoyakiPhoto,
          reason: id,
        );
      }
    });

    test('a combo of drinks only keeps the illustration', () {
      final drinksOnly = catalog
          .comboById('merienda-combo')!
          .copyWith(
            slots: [catalog.comboById('merienda-combo')!.sortedSlots.last],
          );
      expect(catalog.imageForCombo(drinksOnly), isNull);
    });

    test("a combo's own photo wins", () {
      final merienda = catalog
          .comboById('merienda-combo')!
          .copyWith(image: () => 'https://example.com/merienda.jpg');
      expect(
        catalog.imageForCombo(merienda),
        'https://example.com/merienda.jpg',
      );
    });

    test('image fields survive a map round trip (for Firestore)', () {
      final item = catalog
          .itemById('takoyaki-cheese')!
          .copyWith(image: () => 'assets/images/optimized/cheese.jpg');
      expect(
        MenuItem.fromMap(item.id, item.toMap()).image,
        'assets/images/optimized/cheese.jpg',
      );
      final combo = catalog
          .comboById('takoyaki-duo')!
          .copyWith(image: () => 'https://example.com/duo.jpg');
      expect(
        Combo.fromMap(combo.id, combo.toMap()).image,
        'https://example.com/duo.jpg',
      );
      final category = catalog.categoryById(SeedMenu.takoyakiCategory)!;
      expect(category.toMap()['defaultImage'], SeedMenu.takoyakiPhoto);
    });
  });
}
