import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/core/widgets/brand_logo.dart';
import 'package:gnc_app/data/models/selections.dart';
import 'package:gnc_app/data/seed/seed_menu.dart';
import 'package:gnc_app/features/cart/cart_providers.dart';
import 'package:gnc_app/features/cart/cart_screen.dart';

import '../helpers.dart';

const octopus = ItemSelection(itemId: 'takoyaki-octopus');

ItemSelection sodaOf(String flavour, String size) => ItemSelection(
  itemId: SeedMenu.fruitSoda,
  choiceIdsByGroup: {
    SeedMenu.sodaFlavourGroup: [flavour],
    SeedMenu.sodaSizeGroup: [size],
  },
);

Future<ProviderContainer> pumpCart(
  WidgetTester tester, {
  DateTime? now,
  void Function(CartNotifier cart)? fill,
}) async {
  await pumpWithMenu(tester, const CartScreen(), manilaNow: now);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(CartScreen)),
  );
  if (fill != null) {
    fill(container.read(cartProvider.notifier));
    await tester.pumpAndSettle();
  }
  return container;
}

/// Text inside the cart's line cards (not the recommended row).
Finder inLine(String text) => find.descendant(
  of: find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey &&
        '${(w.key! as ValueKey).value}'.startsWith('cart-line-'),
  ),
  matching: find.text(text),
);

FilledButton checkoutButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.descendant(
    of: find.byKey(const ValueKey('checkout')),
    matching: find.byType(FilledButton),
  ),
);

void main() {
  testWidgets('empty cart: serif title, friendly empty state', (tester) async {
    await pumpCart(tester);
    expect(find.text('My Cart'), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Browse menu'), findsOneWidget);
    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.byKey(const ValueKey('checkout')), findsNothing);
  });

  testWidgets('lines show options, orange price and a live total', (
    tester,
  ) async {
    await pumpCart(
      tester,
      fill: (cart) => cart
        ..addItem(octopus, quantity: 2)
        ..addItem(sodaOf('lemon', SeedMenu.size12)),
    );

    expect(inLine('Octopus'), findsOneWidget);
    expect(inLine('Lemon · 12oz'), findsOneWidget);
    expect(inLine('₱150'), findsOneWidget);
    expect(find.text('Proceed to Checkout · ₱185'), findsOneWidget);
    expect(checkoutButton(tester).onPressed, isNotNull);

    await tester.tap(find.byTooltip('Increase Octopus').first);
    await tester.pumpAndSettle();
    expect(find.text('Proceed to Checkout · ₱260'), findsOneWidget);
  });

  testWidgets('remove with undo', (tester) async {
    final container = await pumpCart(
      tester,
      fill: (cart) => cart
        ..addItem(octopus)
        ..addItem(sodaOf('lemon', SeedMenu.size12)),
    );
    await tester.tap(find.byTooltip('Remove Octopus'));
    await tester.pumpAndSettle();
    expect(inLine('Octopus'), findsNothing);
    expect(find.text('Removed Octopus'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(inLine('Octopus'), findsOneWidget);
    // Back in its original position.
    expect(container.read(cartProvider).first.item, octopus);
  });

  testWidgets('swipe left to remove', (tester) async {
    await pumpCart(tester, fill: (cart) => cart.addItem(octopus));
    await tester.drag(inLine('Octopus'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Removed Octopus'), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('suggests a cheaper combo and switches, keeping flavours', (
    tester,
  ) async {
    final container = await pumpCart(
      tester,
      fill: (cart) => cart
        ..addItem(octopus)
        ..addItem(sodaOf('lemon', SeedMenu.size16)),
    );
    expect(find.text('Make it a Merienda Combo and save ₱10'), findsOneWidget);
    expect(find.text('Proceed to Checkout · ₱125'), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('switch-to-combo')));
    await tester.pumpAndSettle();

    final lines = container.read(cartProvider);
    expect(lines, hasLength(1));
    final drink = lines.single.combo!.picksFor('drink', 1).single!;
    expect(drink.choicesFor(SeedMenu.sodaFlavourGroup), ['lemon']);
    expect(inLine('Merienda Combo'), findsOneWidget);
    expect(find.text('Proceed to Checkout · ₱115'), findsOneWidget);
    // Summary shows the regular price and the combo saving.
    await revealInList(tester, find.text('Combo savings'));
    expect(find.text('−₱10'), findsOneWidget);

    // Undo puts the original items back.
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(container.read(cartProvider), hasLength(2));
  });

  testWidgets('takoyaki without a drink → suggests a Fruit Soda', (
    tester,
  ) async {
    await pumpCart(tester, fill: (cart) => cart.addItem(octopus));
    expect(find.text('Add a Fruit Soda?'), findsOneWidget);
    expect(find.text('Ice-cold fruit sodas.'), findsOneWidget);
    await revealInList(tester, find.text('Recommended'));
    expect(
      find.byKey(const ValueKey('recommended-fruit-soda')),
      findsOneWidget,
    );
  });

  testWidgets('recommended stepper adds to the cart', (tester) async {
    final container = await pumpCart(
      tester,
      fill: (cart) => cart.addItem(sodaOf('lemon', SeedMenu.size12)),
    );
    final card = find.byKey(const ValueKey('recommended-takoyaki-octopus'));
    await revealInList(tester, card);
    await tester.tap(
      find.descendant(of: card, matching: find.byTooltip('Increase Octopus')),
    );
    await tester.pumpAndSettle();
    expect(
      container
          .read(cartProvider)
          .where((l) => l.item == octopus)
          .single
          .quantity,
      1,
    );
  });

  group('promo codes', () {
    Future<void> enterCode(WidgetTester tester, String code) async {
      await tapVisible(tester, find.byKey(const ValueKey('promo-open')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('promo-field')), code);
      await tapVisible(tester, find.byKey(const ValueKey('promo-apply')));
      await tester.pumpAndSettle();
    }

    testWidgets('valid code: success message and discount in the summary', (
      tester,
    ) async {
      await pumpCart(
        tester,
        fill: (cart) => cart
          ..addItem(octopus, quantity: 2)
          ..addItem(sodaOf('lemon', SeedMenu.size12)),
      );
      await enterCode(tester, 'welcome10');

      expect(find.text('WELCOME10 applied'), findsOneWidget);
      expect(find.text('You save ₱18.50'), findsOneWidget);
      await revealInList(tester, find.text('Promo (WELCOME10)'));
      expect(find.text('Promo (WELCOME10)'), findsOneWidget);
      expect(find.text('Proceed to Checkout · ₱166.50'), findsOneWidget);
    });

    testWidgets('unknown code: clear error', (tester) async {
      await pumpCart(
        tester,
        fill: (cart) => cart.addItem(octopus, quantity: 2),
      );
      await enterCode(tester, 'NOPE');
      expect(find.textContaining("couldn't find that code"), findsOneWidget);
      expect(find.text('Proceed to Checkout · ₱150'), findsOneWidget);
    });

    testWidgets('inactive code is rejected', (tester) async {
      await pumpCart(
        tester,
        fill: (cart) => cart.addItem(octopus, quantity: 2),
      );
      await enterCode(tester, 'GRANDOPENING');
      expect(find.text('This code is no longer active.'), findsOneWidget);
    });

    testWidgets('below the minimum says how much more to spend', (
      tester,
    ) async {
      await pumpCart(tester, fill: (cart) => cart.addItem(octopus));
      await enterCode(tester, 'WELCOME10');
      expect(
        find.text('Spend ₱100 or more to use this code (₱25 to go).'),
        findsOneWidget,
      );
    });
  });

  testWidgets('checkout is disabled while the shop is closed', (tester) async {
    await pumpCart(
      tester,
      now: closedTime,
      fill: (cart) => cart.addItem(octopus),
    );
    expect(find.text('Closed · opens 10:00 AM'), findsOneWidget);
    expect(checkoutButton(tester).onPressed, isNull);
  });

  test('same item and options merge into one line', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final lemon = sodaOf('lemon', SeedMenu.size20);
    container.read(cartProvider.notifier)
      ..addItem(lemon)
      ..addItem(lemon, quantity: 2)
      ..addItem(octopus);
    final lines = container.read(cartProvider);
    expect(lines, hasLength(2));
    expect(lines.first.quantity, 3);

    container.read(cartProvider.notifier).setQuantity(lines.first.id, 0);
    expect(container.read(cartProvider), hasLength(1));
  });
}
