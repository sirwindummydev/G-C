import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/data/models/selections.dart';
import 'package:gnc_app/data/seed/seed_menu.dart';
import 'package:gnc_app/domain/item_pricing.dart';

import '../helpers.dart';

void main() {
  final catalog = seedCatalog();
  final octopus = catalog.itemById('takoyaki-octopus')!;
  final soda = catalog.itemById(SeedMenu.fruitSoda)!;

  ItemSelection sodaWith({String? flavour, String? size}) => ItemSelection(
    itemId: soda.id,
    choiceIdsByGroup: {
      SeedMenu.sodaFlavourGroup: [?flavour],
      SeedMenu.sodaSizeGroup: [?size],
    },
  );

  group('takoyaki', () {
    test('has a fixed price of ₱75 for 4 pcs', () {
      expect(octopus.basePrice, 7500);
      expect(octopus.servingLabel, '4 pcs');
      expect(
        ItemPricing.unitPrice(octopus, ItemSelection(itemId: octopus.id)),
        7500,
      );
      expect(ItemPricing.fromPrice(octopus), 7500);
      expect(ItemPricing.hasVariablePrice(octopus), isFalse);
    });

    test('is valid with no options', () {
      expect(
        ItemPricing.validate(octopus, ItemSelection(itemId: octopus.id)),
        isEmpty,
      );
    });

    test('cannot be ordered when sold out', () {
      final soldOut = octopus.copyWith(isAvailable: false);
      expect(soldOut.isOrderable, isFalse);
      expect(ItemPricing.validate(soldOut, ItemSelection(itemId: octopus.id)), [
        'Octopus is sold out.',
      ]);
    });
  });

  group('fruit soda', () {
    test('seed has 11 flavours and 3 sizes', () {
      expect(soda.groupById(SeedMenu.sodaFlavourGroup)!.choices, hasLength(11));
      expect(soda.groupById(SeedMenu.sodaSizeGroup)!.choices, hasLength(3));
    });

    test('is priced by size', () {
      expect(
        ItemPricing.unitPrice(soda, sodaWith(flavour: 'mango', size: '12oz')),
        3500,
      );
      expect(
        ItemPricing.unitPrice(soda, sodaWith(flavour: 'mango', size: '16oz')),
        5000,
      );
      expect(
        ItemPricing.unitPrice(soda, sodaWith(flavour: 'mango', size: '20oz')),
        5500,
      );
    });

    test('starts from the cheapest size', () {
      expect(ItemPricing.fromPrice(soda), 3500);
      expect(ItemPricing.hasVariablePrice(soda), isTrue);
    });

    test('requires a flavour and a size', () {
      expect(ItemPricing.validate(soda, sodaWith()), [
        'Choose a flavour.',
        'Choose a size.',
      ]);
      expect(ItemPricing.validate(soda, sodaWith(flavour: 'kiwi')), [
        'Choose a size.',
      ]);
      expect(
        ItemPricing.validate(soda, sodaWith(flavour: 'kiwi', size: '16oz')),
        isEmpty,
      );
    });

    test('rejects more than one choice in a single-choice group', () {
      final selection = ItemSelection(
        itemId: soda.id,
        choiceIdsByGroup: {
          SeedMenu.sodaFlavourGroup: ['kiwi', 'mango'],
          SeedMenu.sodaSizeGroup: ['16oz'],
        },
      );
      expect(ItemPricing.validate(soda, selection), [
        'Choose at most 1 for Flavour.',
      ]);
    });

    test('rejects a sold-out flavour', () {
      final item = seedCatalog(
        seed: seedWith(
          editItem: editSodaChoice(
            SeedMenu.sodaFlavourGroup,
            'mango',
            (c) => c.copyWith(isAvailable: false),
          ),
        ),
      ).itemById(soda.id)!;
      expect(
        ItemPricing.validate(item, sodaWith(flavour: 'mango', size: '16oz')),
        ['Mango is sold out.'],
      );
      expect(item.isOrderable, isTrue);
    });

    test('adds a premium flavour price adjustment', () {
      final item = seedCatalog(
        seed: seedWith(
          editItem: editSodaChoice(
            SeedMenu.sodaFlavourGroup,
            'tiger-s-blood',
            (c) => c.copyWith(priceDelta: 1000),
          ),
        ),
      ).itemById(soda.id)!;
      expect(
        ItemPricing.unitPrice(
          item,
          sodaWith(flavour: 'tiger-s-blood', size: '12oz'),
        ),
        4500,
      );
      expect(ItemPricing.fromPrice(item), 3500);
    });

    test('is not orderable when every flavour is sold out', () {
      final flavours = soda.groupById(SeedMenu.sodaFlavourGroup)!;
      final item = soda.copyWith(
        optionGroups: [
          flavours.copyWith(
            choices: [
              for (final c in flavours.choices) c.copyWith(isAvailable: false),
            ],
          ),
          soda.groupById(SeedMenu.sodaSizeGroup)!,
        ],
      );
      expect(item.isOrderable, isFalse);
    });

    test('20oz carries the admin "Best value" badge', () {
      final size = soda.groupById(SeedMenu.sodaSizeGroup)!;
      expect(size.choiceById('20oz')!.badge, 'Best value');
      expect(size.choiceById('16oz')!.badge, isNull);
    });

    test('labels sizes with full price and flavours only when extra', () {
      final size = soda.groupById(SeedMenu.sodaSizeGroup)!;
      final flavour = soda.groupById(SeedMenu.sodaFlavourGroup)!;
      expect(
        ItemPricing.choiceLabelPrice(soda, size, size.choiceById('16oz')!),
        5000,
      );
      expect(
        ItemPricing.choiceLabelPrice(
          soda,
          flavour,
          flavour.choiceById('kiwi')!,
        ),
        isNull,
      );
    });

    test('describes the chosen options in menu order', () {
      expect(
        ItemPricing.describe(soda, sodaWith(flavour: 'kiwi', size: '20oz')),
        'Kiwi, 20oz',
      );
    });
  });

  group('ItemSelection', () {
    test('toggle respects maxSelect', () {
      var selection = const ItemSelection(itemId: 'x');
      selection = selection.toggle('g', 'a', maxSelect: 2);
      selection = selection.toggle('g', 'b', maxSelect: 2);
      selection = selection.toggle('g', 'c', maxSelect: 2);
      expect(selection.choicesFor('g'), ['a', 'b']);
      selection = selection.toggle('g', 'a', maxSelect: 2);
      expect(selection.choicesFor('g'), ['b']);
    });

    test('equality ignores choice order', () {
      const a = ItemSelection(
        itemId: 'x',
        choiceIdsByGroup: {
          'g': ['a', 'b'],
        },
      );
      const b = ItemSelection(
        itemId: 'x',
        choiceIdsByGroup: {
          'g': ['b', 'a'],
        },
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
