import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/core/theme/app_theme.dart';
import 'package:gnc_app/core/widgets/illustrations.dart';
import 'package:gnc_app/core/widgets/menu_image.dart';
import 'package:gnc_app/data/models/menu_visual.dart';
import 'package:gnc_app/data/seed/seed_menu.dart';
import 'package:gnc_app/features/admin/admin_home_screen.dart';
import 'package:gnc_app/features/menu/item_detail_screen.dart';
import 'package:gnc_app/features/menu/menu_providers.dart';
import 'package:gnc_app/features/menu/menu_screen.dart';
import 'package:gnc_app/features/menu/widgets/menu_cards.dart';

import '../helpers.dart';

MenuImage imageIn(WidgetTester tester, Finder card) => tester.widget<MenuImage>(
  find
      .descendant(
        of: card,
        matching: find.byType(MenuImage, skipOffstage: false),
        skipOffstage: false,
      )
      .first,
);

void main() {
  testWidgets('menu shows the takoyaki photo; drinks keep the cup', (
    tester,
  ) async {
    await pumpWithMenu(tester, const MenuScreen());

    final octopus = imageIn(
      tester,
      find.byKey(const ValueKey('popular-takoyaki-octopus')),
    );
    expect(octopus.image, SeedMenu.takoyakiPhoto);
    expect(octopus.heroTag, itemHeroTag('takoyaki-octopus', 'popular'));

    final duoPromo = imageIn(
      tester,
      find.byKey(const ValueKey('banner-takoyaki-duo')),
    );
    expect(duoPromo.image, SeedMenu.takoyakiPhoto);

    // Drinks keep the cup illustration.
    await tester.tap(find.byKey(const ValueKey('chip-drinks')));
    await tester.pumpAndSettle();
    final soda = imageIn(
      tester,
      find.byKey(const ValueKey('item-${SeedMenu.fruitSoda}')),
    );
    expect(soda.image, isNull);
  });

  testWidgets('detail hero matches the card and is ~40% of the screen', (
    tester,
  ) async {
    await pumpWithMenu(
      tester,
      ItemDetailScreen(
        itemId: 'takoyaki-octopus',
        heroTag: itemHeroTag('takoyaki-octopus', 'grid'),
      ),
    );
    final hero = tester.widget<MenuImage>(find.byType(MenuImage).first);
    expect(hero.image, SeedMenu.takoyakiPhoto);
    expect(hero.heroTag, itemHeroTag('takoyaki-octopus', 'grid'));
    final height = tester.getSize(find.byType(MenuImage).first).height;
    expect(height, closeTo(800 * 0.4, 1));
  });

  testWidgets('a photo that fails to load falls back to the illustration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Center(
          child: MenuImage(
            visual: MenuVisual(iconKey: 'takoyaki'),
            image: 'assets/images/optimized/missing.jpg',
            size: 120,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FoodIllustration), findsOneWidget);
  });

  testWidgets('admin can set a photo, and the menu updates', (tester) async {
    await pumpWithMenu(tester, const AdminHomeScreen());

    final row = find.byKey(const ValueKey('photo-row-${SeedMenu.fruitSoda}'));
    await revealInList(tester, row);
    expect(
      find.descendant(of: row, matching: find.text('Illustration')),
      findsOneWidget,
    );

    await tapVisible(tester, row);
    await tester.pumpAndSettle();
    expect(find.text('Photo for Fruit Soda'), findsOneWidget);
    await tester.tap(find.text('takoyaki.jpg').last);
    await tester.pumpAndSettle();

    expect(find.text('Photo updated for Fruit Soda.'), findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('Own photo · takoyaki.jpg')),
      findsOneWidget,
    );
    // Saved through the repository, so every screen sees it.
    final items = ProviderScope.containerOf(
      tester.element(find.byType(AdminHomeScreen)),
    ).read(menuItemsProvider).requireValue;
    expect(
      items.firstWhere((i) => i.id == SeedMenu.fruitSoda).image,
      SeedMenu.takoyakiPhoto,
    );
    await settleTimers(tester);
  });
}
