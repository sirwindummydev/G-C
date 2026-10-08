import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/core/theme/app_theme.dart';
import 'package:gnc_app/core/widgets/capsule_chip.dart';
import 'package:gnc_app/core/widgets/menu_image.dart';
import 'package:gnc_app/data/seed/seed_menu.dart';
import 'package:gnc_app/features/cart/cart_providers.dart';
import 'package:gnc_app/features/menu/combo_detail_screen.dart';
import 'package:gnc_app/features/menu/flavour_palette.dart';
import 'package:gnc_app/features/menu/item_detail_screen.dart';

import '../helpers.dart';

FilledButton addButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

ProviderContainer containerOf(WidgetTester tester, Type screen) =>
    ProviderScope.containerOf(tester.element(find.byType(screen)));

Finder flavour(String id) =>
    find.byKey(ValueKey('choice-${SeedMenu.sodaFlavourGroup}-$id'));
Finder size(String id) =>
    find.byKey(ValueKey('choice-${SeedMenu.sodaSizeGroup}-$id'));
Finder takoyakiPick(String flavour, {String slot = 'takoyaki'}) =>
    find.byKey(ValueKey('pick-$slot-takoyaki-$flavour'));

CapsuleChip chipAt(WidgetTester tester, Finder finder) =>
    tester.widget<CapsuleChip>(finder);

HeaderTag tagWithText(WidgetTester tester, String text) =>
    tester.widget<HeaderTag>(
      find.byWidgetPredicate((w) => w is HeaderTag && w.text == text),
    );

Color? cupColour(WidgetTester tester) => tester
    .widget<MenuImage>(find.byType(MenuImage, skipOffstage: false).first)
    .drinkColor;

void main() {
  group('drink builder', () {
    testWidgets('requires options and updates the price live', (tester) async {
      await pumpWithMenu(
        tester,
        const ItemDetailScreen(itemId: SeedMenu.fruitSoda),
      );

      expect(find.text('Choose a flavour.'), findsOneWidget);
      expect(find.text('Add to cart'), findsOneWidget);
      expect(addButton(tester).onPressed, isNull);
      expect(
        find.byWidgetPredicate((w) => w is HeaderTag && w.text == 'Required'),
        findsWidgets,
      );

      await tapVisible(tester, flavour('mango'));
      expect(chipAt(tester, flavour('mango')).selected, isTrue);
      expect(tagWithText(tester, 'Mango').tone, TagTone.done);
      expect(find.text('Choose a size.'), findsOneWidget);

      // Sizes read "16oz · ₱50"; 20oz carries the admin "Best value" badge.
      await revealInList(tester, size('20oz'));
      expect(chipAt(tester, size('16oz')).detail, '₱50');
      expect(chipAt(tester, size('20oz')).badge, 'Best value');
      expect(find.text('Best value'), findsOneWidget);
      expect(find.textContaining('20oz ₱2.75'), findsOneWidget);

      await tapVisible(tester, size('20oz'));
      expect(find.text('Add to cart · ₱55'), findsOneWidget);
      expect(addButton(tester).onPressed, isNotNull);

      await tapVisible(tester, find.byTooltip('Increase quantity'));
      expect(find.text('Add to cart · ₱110'), findsOneWidget);

      // Radio behaviour: choosing another size replaces the first.
      await tapVisible(tester, size('12oz'));
      expect(chipAt(tester, size('20oz')).selected, isFalse);
      expect(find.text('Add to cart · ₱70'), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      final line = containerOf(
        tester,
        ItemDetailScreen,
      ).read(cartProvider).single;
      expect(line.quantity, 2);
      expect(line.item!.choicesFor(SeedMenu.sodaFlavourGroup), ['mango']);
      await settleTimers(tester);
    });

    testWidgets('cup starts neutral and takes the flavour colour', (
      tester,
    ) async {
      await pumpWithMenu(
        tester,
        const ItemDetailScreen(itemId: SeedMenu.fruitSoda),
      );
      expect(cupColour(tester), AppColors.neutralDrink);

      await tapVisible(tester, flavour('kiwi'));
      await tester.pumpAndSettle();
      expect(cupColour(tester), FlavourPalette.forName('Kiwi'));
    });

    testWidgets('chips have screen reader labels', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpWithMenu(
        tester,
        const ItemDetailScreen(itemId: SeedMenu.fruitSoda),
        seed: seedWith(
          editItem: editSodaChoice(
            SeedMenu.sodaFlavourGroup,
            'kiwi',
            (c) => c.copyWith(isAvailable: false),
          ),
        ),
      );
      await tapVisible(tester, flavour('lemon'));
      expect(find.bySemanticsLabel('Lemon, flavour, selected'), findsOneWidget);
      expect(find.bySemanticsLabel('Kiwi, sold out'), findsOneWidget);
      expect(
        find.bySemanticsLabel('20oz, size, ₱55, Best value'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('sold-out flavours are not tappable', (tester) async {
      await pumpWithMenu(
        tester,
        const ItemDetailScreen(itemId: SeedMenu.fruitSoda),
        seed: seedWith(
          editItem: editSodaChoice(
            SeedMenu.sodaFlavourGroup,
            'kiwi',
            (c) => c.copyWith(isAvailable: false),
          ),
        ),
      );
      await revealInList(tester, flavour('kiwi'));
      final kiwi = chipAt(tester, flavour('kiwi'));
      expect(kiwi.soldOut, isTrue);
      expect(kiwi.onTap, isNull);
      expect(find.text('Sold out'), findsOneWidget);
    });

    testWidgets('chips wrap inside a 360px screen', (tester) async {
      await pumpWithMenu(
        tester,
        const ItemDetailScreen(itemId: SeedMenu.fruitSoda),
      );
      await tapVisible(tester, flavour("tiger-s-blood"));
      for (final element
          in find.byType(CapsuleChip, skipOffstage: false).evaluate()) {
        final box = element.renderObject! as RenderBox;
        final right = box.localToGlobal(Offset(box.size.width, 0)).dx;
        expect(right, lessThanOrEqualTo(360 - Gap.screen + 0.5));
      }
    });
  });

  testWidgets('takoyaki detail can be added straight away', (tester) async {
    await pumpWithMenu(
      tester,
      const ItemDetailScreen(itemId: 'takoyaki-octopus'),
    );
    expect(find.text('Add to cart · ₱75'), findsOneWidget);
    expect(addButton(tester).onPressed, isNotNull);
  });

  group('combo detail', () {
    testWidgets('Duo: pick 2 flavours, see savings', (tester) async {
      await pumpWithMenu(
        tester,
        const ComboDetailScreen(comboId: 'takoyaki-duo'),
      );

      expect(find.text('0 of 2 selected'), findsOneWidget);
      expect(addButton(tester).onPressed, isNull);

      await tapVisible(tester, takoyakiPick('octopus'));
      await tapVisible(tester, takoyakiPick('cheese'));

      expect(find.text('2 of 2 selected'), findsOneWidget);
      expect(find.text('You save ₱10'), findsOneWidget);
      expect(find.text('Add to cart · ₱140'), findsOneWidget);
      expect(addButton(tester).onPressed, isNotNull);

      // Full: unselected chips are disabled until one is removed.
      expect(chipAt(tester, takoyakiPick('squid')).onTap, isNull);
      await tapVisible(tester, find.byTooltip('Remove one Cheese'));
      expect(find.text('1 of 2 selected'), findsOneWidget);
      expect(chipAt(tester, takoyakiPick('squid')).onTap, isNotNull);
    });

    testWidgets('Duo: the same flavour can be picked twice', (tester) async {
      await pumpWithMenu(
        tester,
        const ComboDetailScreen(comboId: 'takoyaki-duo'),
      );
      await tapVisible(tester, takoyakiPick('octopus'));
      await tapVisible(tester, takoyakiPick('octopus'));
      expect(find.text('2 of 2 selected'), findsOneWidget);
      expect(chipAt(tester, takoyakiPick('octopus')).count, 2);
      expect(find.textContaining('×2'), findsOneWidget);
      expect(find.text('Add to cart · ₱140'), findsOneWidget);
    });

    testWidgets('Merienda: soda pre-selected, 20oz upgrade costs +₱5', (
      tester,
    ) async {
      await pumpWithMenu(
        tester,
        const ComboDetailScreen(comboId: 'merienda-combo'),
      );

      await tapVisible(tester, takoyakiPick('octopus'));
      expect(tagWithText(tester, 'Octopus').tone, TagTone.done);
      await tapVisible(tester, flavour('lemon'));
      await revealInList(tester, size('20oz'));

      // Only 16oz and 20oz are offered.
      expect(size('12oz'), findsNothing);
      expect(chipAt(tester, size('16oz')).detail, 'Included');
      expect(chipAt(tester, size('20oz')).detail, '+₱5');

      await tapVisible(tester, size('16oz'));
      expect(find.text('Add to cart · ₱115'), findsOneWidget);
      await tapVisible(tester, size('20oz'));
      expect(find.text('Add to cart · ₱120'), findsOneWidget);
      expect(find.text('You save ₱10'), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(
        containerOf(tester, ComboDetailScreen).read(cartProvider).single.combo,
        isNotNull,
      );
      await settleTimers(tester);
    });

    testWidgets('sold-out flavour cannot be added to a combo', (tester) async {
      await pumpWithMenu(
        tester,
        const ComboDetailScreen(comboId: 'takoyaki-duo'),
        seed: seedWith(editItem: soldOutItem('takoyaki-crabstix')),
      );
      await revealInList(tester, takoyakiPick('crabstix'));
      final crabstix = chipAt(tester, takoyakiPick('crabstix'));
      expect(crabstix.soldOut, isTrue);
      expect(crabstix.onTap, isNull);
      expect(find.text('Sold out'), findsOneWidget);
    });
  });
}
