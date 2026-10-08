import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/data/models/selections.dart';
import 'package:gnc_app/features/cart/cart_providers.dart';
import 'package:gnc_app/features/menu/menu_screen.dart';
import 'package:gnc_app/features/shell/customer_shell.dart';

import '../helpers.dart';

void main() {
  testWidgets('floating nav switches between the four tabs', (tester) async {
    await pumpWithMenu(tester, const CustomerShell());

    for (final label in ['Home', 'Cart', 'Orders', 'Profile']) {
      expect(find.byTooltip(label), findsOneWidget);
    }
    expect(find.text('Popular'), findsOneWidget);

    await tester.tap(find.byTooltip('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);

    await tester.tap(find.byTooltip('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('No orders yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, guest'), findsOneWidget);
    expect(find.text('Opening hours'), findsOneWidget);
    expect(find.text('Developer options'), findsOneWidget);

    // Empty states lead back to the menu.
    await tester.tap(find.byTooltip('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse menu'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CustomerShell)),
    );
    expect(container.read(shellTabProvider), ShellTab.home);
  });

  testWidgets('cart tab shows the item count badge', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpWithMenu(tester, const CustomerShell());
    ProviderScope.containerOf(tester.element(find.byType(CustomerShell)))
        .read(cartProvider.notifier)
        .addItem(const ItemSelection(itemId: 'takoyaki-octopus'), quantity: 3);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Cart, 3 items'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the header cart icon opens the Cart tab', (tester) async {
    await pumpWithMenu(tester, const CustomerShell());
    await tester.tap(find.byTooltip('Cart, empty'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('menu content never hides behind the navigation bar', (
    tester,
  ) async {
    await pumpWithMenu(tester, const CustomerShell());

    await tester.drag(
      find.descendant(
        of: find.byType(MenuScreen),
        matching: find.byType(CustomScrollView),
      ),
      const Offset(0, -20000),
    );
    await tester.pumpAndSettle();

    final navTop = tester
        .getTopLeft(
          find.descendant(
            of: find.byType(FloatingNavBar),
            matching: find.byType(Row),
          ),
        )
        .dy;
    final lastCard = find.byKey(const ValueKey('item-fruit-soda'));
    expect(tester.getBottomLeft(lastCard).dy, lessThanOrEqualTo(navTop - 16));
  });
}
