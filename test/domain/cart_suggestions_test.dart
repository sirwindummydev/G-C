import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/data/models/selections.dart';
import 'package:gnc_app/data/seed/seed_menu.dart';
import 'package:gnc_app/domain/cart_line.dart';
import 'package:gnc_app/domain/cart_suggestions.dart';

import '../helpers.dart';

CartLine tako(String id, String flavour, [int qty = 1]) => CartLine.item(
  id: id,
  item: ItemSelection(itemId: 'takoyaki-$flavour'),
  quantity: qty,
);

CartLine soda(String id, String flavour, String size, [int qty = 1]) =>
    CartLine.item(
      id: id,
      item: ItemSelection(
        itemId: SeedMenu.fruitSoda,
        choiceIdsByGroup: {
          SeedMenu.sodaFlavourGroup: [flavour],
          SeedMenu.sodaSizeGroup: [size],
        },
      ),
      quantity: qty,
    );

void main() {
  late CartSuggestions suggestions;
  setUp(() => suggestions = CartSuggestions(seedCatalog()));

  group('combo detection', () {
    test('takoyaki + 16oz soda → Merienda, saves ₱10, keeps flavours', () {
      final s = suggestions.bestCombo([
        tako('a', 'cheese'),
        soda('b', 'lemon', SeedMenu.size16),
      ])!;
      expect(s.combo.id, 'merienda-combo');
      expect(s.separatePrice, 12500);
      expect(s.comboPrice, 11500);
      expect(s.savings, 1000);
      expect(s.consumed, {'a': 1, 'b': 1});
      final drink = s.selection.picksFor('drink', 1).single!;
      expect(drink.choicesFor(SeedMenu.sodaFlavourGroup), ['lemon']);
      expect(drink.choicesFor(SeedMenu.sodaSizeGroup), [SeedMenu.size16]);
      expect(
        s.selection.picksFor('takoyaki', 1).single!.itemId,
        'takoyaki-cheese',
      );
    });

    test('20oz soda still qualifies (with the +₱5 upgrade)', () {
      final s = suggestions.bestCombo([
        tako('a', 'octopus'),
        soda('b', 'kiwi', SeedMenu.size20),
      ])!;
      expect(s.comboPrice, 12000);
      expect(s.savings, 1000);
    });

    test('12oz soda is not allowed in Merienda', () {
      expect(
        suggestions.bestCombo([
          tako('a', 'octopus'),
          soda('b', 'kiwi', SeedMenu.size12),
        ]),
        isNull,
      );
    });

    test('two servings → Duo; quantity on one line counts', () {
      final s = suggestions.bestCombo([tako('a', 'squid', 2)])!;
      expect(s.combo.id, 'takoyaki-duo');
      expect(s.consumed, {'a': 2});
      expect(s.savings, 1000);
    });

    test('four servings → Barkada beats Duo (saves ₱30)', () {
      final s = suggestions.bestCombo([
        tako('a', 'octopus', 2),
        tako('b', 'cheese'),
        tako('c', 'crabstix'),
      ])!;
      expect(s.combo.id, 'barkada-box');
      expect(s.savings, 3000);
      expect(s.consumed, {'a': 2, 'b': 1, 'c': 1});
    });

    test('a single serving matches nothing', () {
      expect(suggestions.bestCombo([tako('a', 'octopus')]), isNull);
    });

    test('combos already in the cart are left alone', () {
      final combo = CartLine.combo(
        id: 'x',
        combo: const ComboSelection(comboId: 'takoyaki-duo'),
      );
      expect(suggestions.bestCombo([combo, tako('a', 'octopus')]), isNull);
    });

    test('sold-out items in the cart do not form a combo', () {
      final catalog = seedCatalog(
        seed: seedWith(editItem: soldOutItem('takoyaki-squid')),
      );
      expect(
        CartSuggestions(catalog).bestCombo([tako('a', 'squid', 2)]),
        isNull,
      );
    });

    test('no suggestion when the combo would cost more', () {
      final base = seedCatalog();
      final pricey = SeedMenu(
        categories: base.categories,
        items: base.items,
        combos: [
          for (final c in base.combos)
            c.id == 'takoyaki-duo' ? c.copyWith(price: 20000) : c,
        ],
        settings: SeedMenu.standard().settings,
      );
      expect(
        CartSuggestions(seedCatalog(seed: pricey))
            .bestCombo([tako('a', 'octopus', 2)])
            ?.combo
            .id,
        isNot('takoyaki-duo'),
      );
    });
  });

  group('missing-category upsell', () {
    test('takoyaki but no drink → suggests the Fruit Soda', () {
      final pick = suggestions.missingCategoryPick([tako('a', 'octopus')])!;
      expect(pick.item.id, SeedMenu.fruitSoda);
      expect(pick.category.id, SeedMenu.drinksCategory);
    });

    test('a combo with a drink counts as having a drink', () {
      final merienda = CartLine.combo(
        id: 'm',
        combo: ComboSelection(
          comboId: 'merienda-combo',
          picksBySlot: {
            'takoyaki': [const ItemSelection(itemId: 'takoyaki-octopus')],
            'drink': [soda('x', 'lemon', SeedMenu.size16).item],
          },
        ),
      );
      expect(suggestions.missingCategoryPick([merienda]), isNull);
    });

    test('drinks only → suggests takoyaki', () {
      final pick = suggestions.missingCategoryPick([
        soda('b', 'lemon', SeedMenu.size16),
      ])!;
      expect(pick.category.id, SeedMenu.takoyakiCategory);
    });

    test('empty cart → nothing', () {
      expect(suggestions.missingCategoryPick([]), isNull);
    });
  });
}
