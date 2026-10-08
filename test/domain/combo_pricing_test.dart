import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/data/models/combo.dart';
import 'package:gnc_app/data/models/selections.dart';
import 'package:gnc_app/data/seed/seed_menu.dart';
import 'package:gnc_app/domain/combo_pricing.dart';
import 'package:gnc_app/domain/menu_catalog.dart';

import '../helpers.dart';

ItemSelection tako(String flavour) =>
    ItemSelection(itemId: 'takoyaki-$flavour');

ItemSelection soda(String flavour, String size) => ItemSelection(
  itemId: SeedMenu.fruitSoda,
  choiceIdsByGroup: {
    SeedMenu.sodaFlavourGroup: [flavour],
    SeedMenu.sodaSizeGroup: [size],
  },
);

ComboSelection picks(
  String comboId,
  Map<String, List<ItemSelection?>> bySlot,
) => ComboSelection(comboId: comboId, picksBySlot: bySlot);

void main() {
  late MenuCatalog catalog;
  late ComboPricing pricing;
  late Combo duo;
  late Combo barkada;
  late Combo merienda;

  void useCatalog(MenuCatalog next) {
    catalog = next;
    pricing = ComboPricing(catalog);
    duo = catalog.comboById('takoyaki-duo')!;
    barkada = catalog.comboById('barkada-box')!;
    merienda = catalog.comboById('merienda-combo')!;
  }

  setUp(() => useCatalog(seedCatalog()));

  group('Takoyaki Duo', () {
    test('costs ₱140 and saves ₱10 vs two servings', () {
      final selection = picks(duo.id, {
        'takoyaki': [tako('octopus'), tako('cheese')],
      });
      expect(pricing.validate(duo, selection), isEmpty);
      expect(pricing.total(duo, selection), 14000);
      expect(pricing.separatePrice(duo, selection), 15000);
      expect(pricing.savings(duo, selection), 1000);
    });

    test('allows the same flavour twice', () {
      final selection = picks(duo.id, {
        'takoyaki': [tako('squid'), tako('squid')],
      });
      expect(pricing.validate(duo, selection), isEmpty);
    });

    test('needs both picks before it is complete', () {
      final selection = picks(duo.id, {
        'takoyaki': [tako('octopus'), null],
      });
      expect(pricing.validate(duo, selection), [
        'Choose 1 more for Takoyaki flavours.',
      ]);
      expect(pricing.savings(duo, selection), isNull);
    });

    test('offers every takoyaki flavour, including newly added ones', () {
      final slot = duo.slots.single;
      expect(pricing.optionsFor(slot).map((o) => o.item.id), [
        'takoyaki-octopus',
        'takoyaki-cheese',
        'takoyaki-ham-cheese',
        'takoyaki-squid',
        'takoyaki-crabstix',
        'takoyaki-assorted',
      ]);
    });
  });

  group('Barkada Box', () {
    test('costs ₱270 and saves ₱30 for 4 picks', () {
      final selection = picks(barkada.id, {
        'takoyaki': [
          tako('octopus'),
          tako('cheese'),
          tako('squid'),
          tako('crabstix'),
        ],
      });
      expect(pricing.validate(barkada, selection), isEmpty);
      expect(pricing.total(barkada, selection), 27000);
      expect(pricing.savings(barkada, selection), 3000);
      expect(pricing.guaranteedSavings(barkada), 3000);
    });

    test('accepts fewer distinct flavours (up to 4)', () {
      final selection = picks(barkada.id, {
        'takoyaki': [
          tako('octopus'),
          tako('octopus'),
          tako('cheese'),
          tako('cheese'),
        ],
      });
      expect(pricing.validate(barkada, selection), isEmpty);
    });
  });

  group('Merienda Combo', () {
    test('16oz: ₱115, saves ₱10', () {
      final selection = picks(merienda.id, {
        'takoyaki': [tako('ham-cheese')],
        'drink': [soda('mango', SeedMenu.size16)],
      });
      expect(pricing.validate(merienda, selection), isEmpty);
      expect(pricing.total(merienda, selection), 11500);
      expect(pricing.separatePrice(merienda, selection), 12500);
      expect(pricing.savings(merienda, selection), 1000);
    });

    test('20oz upgrade adds ₱5 and still saves ₱10', () {
      final selection = picks(merienda.id, {
        'takoyaki': [tako('octopus')],
        'drink': [soda('kiwi', SeedMenu.size20)],
      });
      expect(pricing.total(merienda, selection), 12000);
      expect(pricing.separatePrice(merienda, selection), 13000);
      expect(pricing.savings(merienda, selection), 1000);
    });

    test('12oz is not allowed in the combo', () {
      final selection = picks(merienda.id, {
        'takoyaki': [tako('octopus')],
        'drink': [soda('kiwi', SeedMenu.size12)],
      });
      expect(pricing.validate(merienda, selection), [
        'A size choice is no longer offered.',
      ]);
    });

    test('drink needs a flavour and a size', () {
      final selection = picks(merienda.id, {
        'takoyaki': [tako('octopus')],
        'drink': [const ItemSelection(itemId: SeedMenu.fruitSoda)],
      });
      expect(pricing.validate(merienda, selection), [
        'Choose a flavour.',
        'Choose a size.',
      ]);
    });

    test('menu card numbers: from ₱115, save ₱10', () {
      expect(pricing.fromPrice(merienda), 11500);
      expect(pricing.guaranteedSavings(merienda), 1000);
    });

    test('only offers 16oz and 20oz sizes', () {
      final option = pricing.optionFor(merienda.slots[1], SeedMenu.fruitSoda)!;
      final sizes = option.item.groupById(SeedMenu.sodaSizeGroup)!;
      expect(option.allowedChoices(sizes).map((c) => c.id), [
        SeedMenu.size16,
        SeedMenu.size20,
      ]);
    });
  });

  group('sold out inside combos', () {
    test('a sold-out flavour cannot be picked', () {
      useCatalog(
        seedCatalog(seed: seedWith(editItem: soldOutItem('takoyaki-cheese'))),
      );
      final slot = duo.slots.single;
      final cheese = pricing.optionFor(slot, 'takoyaki-cheese')!;
      expect(cheese.isPickable, isFalse);

      final selection = picks(duo.id, {
        'takoyaki': [tako('cheese'), tako('octopus')],
      });
      expect(pricing.validate(duo, selection), ['Cheese is sold out.']);
      expect(pricing.isOrderable(duo), isTrue);
    });

    test('a sold-out soda flavour cannot be picked', () {
      useCatalog(
        seedCatalog(
          seed: seedWith(
            editItem: editSodaChoice(
              SeedMenu.sodaFlavourGroup,
              'mango',
              (c) => c.copyWith(isAvailable: false),
            ),
          ),
        ),
      );
      final selection = picks(merienda.id, {
        'takoyaki': [tako('octopus')],
        'drink': [soda('mango', SeedMenu.size16)],
      });
      expect(pricing.validate(merienda, selection), ['Mango is sold out.']);
    });

    test('a combo is sold out when a slot has nothing left', () {
      var seed = SeedMenu.standard();
      for (final item in seed.items.where(
        (i) => i.categoryId == SeedMenu.takoyakiCategory,
      )) {
        seed = seedWithFrom(seed, soldOutItem(item.id));
      }
      useCatalog(seedCatalog(seed: seed));
      expect(pricing.isOrderable(duo), isFalse);
      expect(pricing.guaranteedSavings(duo), isNull);
      expect(pricing.validate(duo, picks(duo.id, {})), [
        'Takoyaki Duo is not available right now.',
      ]);
    });

    test('a combo marked unavailable by admin is not orderable', () {
      final hidden = duo.copyWith(isAvailable: false);
      expect(pricing.isOrderable(hidden), isFalse);
    });
  });

  group('generic combo rules', () {
    test('no duplicates when the slot forbids them', () {
      final strict = duo.copyWith(
        slots: [duo.slots.single.copyWith(allowDuplicates: false)],
      );
      final selection = picks(strict.id, {
        'takoyaki': [tako('octopus'), tako('octopus')],
      });
      expect(pricing.validate(strict, selection), [
        'Pick different items for Takoyaki flavours.',
      ]);
    });

    test('item upcharge is added to the combo price', () {
      final withUpcharge = duo.copyWith(
        slots: [
          duo.slots.single.copyWith(
            choices: [
              const ComboSlotChoice(itemId: 'takoyaki-squid', upcharge: 1000),
            ],
          ),
        ],
      );
      final selection = picks(withUpcharge.id, {
        'takoyaki': [tako('squid'), tako('octopus')],
      });
      expect(pricing.total(withUpcharge, selection), 15000);
      expect(pricing.savings(withUpcharge, selection), isNull); // 150 vs 150
    });

    test('premium soda flavour costs extra inside a combo too', () {
      useCatalog(
        seedCatalog(
          seed: seedWith(
            editItem: editSodaChoice(
              SeedMenu.sodaFlavourGroup,
              'tiger-s-blood',
              (c) => c.copyWith(priceDelta: 1000),
            ),
          ),
        ),
      );
      final selection = picks(merienda.id, {
        'takoyaki': [tako('octopus')],
        'drink': [soda('tiger-s-blood', SeedMenu.size16)],
      });
      expect(pricing.total(merienda, selection), 12500);
      expect(pricing.separatePrice(merienda, selection), 13500);
      expect(pricing.savings(merienda, selection), 1000);
    });

    test('items outside the slot are rejected', () {
      final selection = picks(duo.id, {
        'takoyaki': [
          const ItemSelection(itemId: SeedMenu.fruitSoda),
          tako('octopus'),
        ],
      });
      expect(
        pricing.validate(duo, selection),
        contains('That item is not part of this combo.'),
      );
    });

    test('no saving is shown when the combo costs more than separately', () {
      final pricey = duo.copyWith(price: 20000);
      final selection = picks(pricey.id, {
        'takoyaki': [tako('octopus'), tako('cheese')],
      });
      expect(pricing.savings(pricey, selection), isNull);
      expect(pricing.guaranteedSavings(pricey), isNull);
    });
  });

  test('combos survive a map round trip (for Firestore)', () {
    final copy = Combo.fromMap(merienda.id, merienda.toMap());
    expect(copy.toMap(), merienda.toMap());
    final rule = copy.slots[1].choices.single.ruleFor(SeedMenu.sodaSizeGroup)!;
    expect(rule.allowedChoiceIds, [SeedMenu.size16, SeedMenu.size20]);
    expect(rule.upchargeFor(SeedMenu.size20), 500);
  });
}
