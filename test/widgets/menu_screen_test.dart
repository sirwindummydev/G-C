import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/core/widgets/brand_logo.dart';
import 'package:gnc_app/features/cart/cart_providers.dart';
import 'package:gnc_app/features/menu/menu_screen.dart';

import '../helpers.dart';

CategoryChip chip(WidgetTester tester, String key) =>
    tester.widget<CategoryChip>(find.byKey(ValueKey('chip-$key')));

Finder byKey(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('header: logo, greeting, tagline, status and search', (
    tester,
  ) async {
    await pumpWithMenu(tester, const MenuScreen());

    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.text('Good Afternoon'), findsOneWidget); // 2 PM Manila
    expect(
      find.text('Fresh takoyaki and fruit sodas, made to order.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Open now · until 9:00 PM'), findsOneWidget);
    expect(find.text('Search takoyaki, drinks…'), findsOneWidget);
  });

  testWidgets('greeting follows Manila time', (tester) async {
    await pumpWithMenu(
      tester,
      const MenuScreen(),
      manilaNow: DateTime.utc(2026, 10, 7, 9),
    );
    expect(find.text('Good Morning'), findsOneWidget);
  });

  testWidgets('closed shop: evening greeting and amber status pill', (
    tester,
  ) async {
    await pumpWithMenu(tester, const MenuScreen(), manilaNow: closedTime);
    expect(find.text('Good Evening'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Closed · Opens tomorrow 10:00 AM'),
      findsOneWidget,
    );
  });

  test('greetingFor covers the day', () {
    DateTime at(int hour) => DateTime.utc(2026, 10, 7, hour);
    expect(greetingFor(at(5)), 'Good Morning');
    expect(greetingFor(at(11)), 'Good Morning');
    expect(greetingFor(at(12)), 'Good Afternoon');
    expect(greetingFor(at(17)), 'Good Afternoon');
    expect(greetingFor(at(18)), 'Good Evening');
    expect(greetingFor(at(2)), 'Good Evening');
  });

  testWidgets('category chips filter the menu', (tester) async {
    await pumpWithMenu(tester, const MenuScreen());

    for (final key in ['all', 'takoyaki', 'combos', 'drinks']) {
      expect(byKey('chip-$key'), findsOneWidget);
    }
    expect(chip(tester, 'all').selected, isTrue);
    expect(find.text('Combo deals'), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);

    await tester.tap(byKey('chip-drinks'));
    await tester.pumpAndSettle();
    expect(chip(tester, 'drinks').selected, isTrue);
    expect(chip(tester, 'all').selected, isFalse);
    expect(find.text('Combo deals'), findsNothing);
    expect(byKey('section-drinks'), findsOneWidget);
    expect(byKey('section-takoyaki'), findsNothing);
    expect(byKey('item-fruit-soda'), findsOneWidget);
    expect(find.text('11 flavours'), findsOneWidget);

    await tester.tap(byKey('chip-all'));
    await tester.pumpAndSettle();
    expect(find.text('Combo deals'), findsOneWidget);
  });

  testWidgets('combo banner: frosted savings badge, dots, auto-advance', (
    tester,
  ) async {
    await pumpWithMenu(tester, const MenuScreen());

    final duo = byKey('banner-takoyaki-duo');
    expect(duo, findsOneWidget);
    expect(
      find.descendant(of: duo, matching: find.text('Save ₱10')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Promotion 1 of 3'), findsOneWidget);

    // Advances on its own after 5 seconds.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Promotion 2 of 3'), findsOneWidget);
    expect(byKey('banner-barkada-box'), findsOneWidget);

    // Swipeable.
    await tester.fling(byKey('banner-barkada-box'), const Offset(-300, 0), 800);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Promotion 3 of 3'), findsOneWidget);
  });

  testWidgets('combos section shows price and savings on each card', (
    tester,
  ) async {
    await pumpWithMenu(tester, const MenuScreen());
    await tester.tap(byKey('chip-combos'));
    await tester.pumpAndSettle();

    Finder inCard(String id, String text) =>
        find.descendant(of: byKey('combo-$id'), matching: find.text(text));
    expect(inCard('takoyaki-duo', '₱140'), findsOneWidget);
    expect(inCard('takoyaki-duo', 'Save ₱10'), findsOneWidget);
    expect(inCard('barkada-box', '₱270'), findsOneWidget);
    expect(inCard('barkada-box', 'Save ₱30'), findsOneWidget);
    await revealInList(tester, byKey('combo-merienda-combo'));
    expect(inCard('merienda-combo', '₱115'), findsOneWidget);
  });

  testWidgets('Popular "+" adds one serving with confirmation', (tester) async {
    await pumpWithMenu(tester, const MenuScreen());
    final card = byKey('popular-takoyaki-octopus');
    expect(card, findsOneWidget);

    await tapVisible(
      tester,
      find.descendant(
        of: card,
        matching: find.byTooltip('Add one Octopus to cart'),
      ),
    );
    expect(find.text('Added Octopus (4 pcs) to your cart'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MenuScreen)),
    );
    expect(container.read(cartProvider).single.quantity, 1);
    await settleTimers(tester);
  });

  testWidgets('search matches names and flavours', (tester) async {
    await pumpWithMenu(tester, const MenuScreen());

    await tester.enterText(byKey('menu-search'), 'mango');
    await tester.pumpAndSettle();
    expect(find.text('Combo deals'), findsNothing);
    expect(byKey('item-fruit-soda'), findsOneWidget);
    expect(byKey('item-takoyaki-octopus'), findsNothing);

    await tester.enterText(byKey('menu-search'), 'CHEESE');
    await tester.pumpAndSettle();
    expect(byKey('item-takoyaki-cheese'), findsOneWidget);
    expect(byKey('item-takoyaki-ham-cheese'), findsOneWidget);
    expect(byKey('item-fruit-soda'), findsNothing);

    await tester.enterText(byKey('menu-search'), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matches for “zzz”'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Combo deals'), findsOneWidget);
  });

  testWidgets('filter sheet hides sold-out items', (tester) async {
    await pumpWithMenu(
      tester,
      const MenuScreen(),
      seed: seedWith(editItem: soldOutItem('takoyaki-squid')),
    );
    await tester.tap(byKey('chip-takoyaki'));
    await tester.pumpAndSettle();
    await revealInList(tester, byKey('item-takoyaki-squid'));
    expect(
      find.descendant(
        of: byKey('item-takoyaki-squid'),
        matching: find.text('Sold out'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Add one Squid to cart'), findsNothing);

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide sold-out items'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show results'));
    await tester.pumpAndSettle();

    expect(byKey('item-takoyaki-squid'), findsNothing);
    await tester.scrollUntilVisible(
      find.byTooltip('Filters (on)'),
      -200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.byTooltip('Filters (on)'), findsOneWidget);
  });

  testWidgets('long-pressing the logo opens developer options', (tester) async {
    await pumpWithMenu(tester, const MenuScreen());
    await tester.longPress(find.byType(BrandLogo));
    await tester.pumpAndSettle();
    expect(find.text('Developer options'), findsOneWidget);
  });

  testWidgets('shows an error with retry when offline, then recovers', (
    tester,
  ) async {
    final repository = await pumpWithMenu(tester, const SizedBox());
    repository.simulateOffline = true;

    final context = tester.element(find.byType(SizedBox));
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const MenuScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining("Can't reach G&C"), findsOneWidget);

    repository.simulateOffline = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsNothing);
    expect(find.text('Popular'), findsOneWidget);
  });
}
