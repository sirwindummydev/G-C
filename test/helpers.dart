import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/core/clock.dart';
import 'package:gnc_app/core/theme/app_theme.dart';
import 'package:gnc_app/data/models/menu_item.dart';
import 'package:gnc_app/data/models/option_group.dart';
import 'package:gnc_app/data/repositories/local/local_menu_repository.dart';
import 'package:gnc_app/data/repositories/providers.dart';
import 'package:gnc_app/data/seed/seed_menu.dart';
import 'package:gnc_app/domain/menu_catalog.dart';

/// Wednesday 2 PM in Manila: the seed shop is open.
final openTime = DateTime.utc(2026, 10, 7, 14);

/// Wednesday 11 PM in Manila: the seed shop is closed.
final closedTime = DateTime.utc(2026, 10, 7, 23);

MenuCatalog seedCatalog({SeedMenu? seed}) {
  final data = seed ?? SeedMenu.standard();
  return MenuCatalog(
    categories: data.categories,
    items: data.items,
    combos: data.combos,
  );
}

/// The seed menu with some items or choices replaced.
SeedMenu seedWith({MenuItem Function(MenuItem item)? editItem}) {
  final base = SeedMenu.standard();
  return SeedMenu(
    categories: base.categories,
    items: editItem == null ? base.items : base.items.map(editItem).toList(),
    combos: base.combos,
    settings: base.settings,
  );
}

/// [seed] with one more item edit applied.
SeedMenu seedWithFrom(
  SeedMenu seed,
  MenuItem Function(MenuItem item) editItem,
) => SeedMenu(
  categories: seed.categories,
  items: seed.items.map(editItem).toList(),
  combos: seed.combos,
  settings: seed.settings,
);

/// Marks a takoyaki flavour sold out, e.g. `soldOutItem('takoyaki-cheese')`.
MenuItem Function(MenuItem) soldOutItem(String id) =>
    (item) => item.id == id ? item.copyWith(isAvailable: false) : item;

/// Edits one choice of the Fruit Soda.
MenuItem Function(MenuItem) editSodaChoice(
  String groupId,
  String choiceId,
  OptionChoice Function(OptionChoice) edit,
) => (item) {
  if (item.id != SeedMenu.fruitSoda) return item;
  return item.copyWith(
    optionGroups: [
      for (final group in item.optionGroups)
        group.id != groupId
            ? group
            : group.copyWith(
                choices: [
                  for (final c in group.choices) c.id == choiceId ? edit(c) : c,
                ],
              ),
    ],
  );
};

/// Pumps [child] inside the app theme with a fast local repository.
Future<LocalMenuRepository> pumpWithMenu(
  WidgetTester tester,
  Widget child, {
  SeedMenu? seed,
  DateTime? manilaNow,
}) async {
  // A small Android phone: 360 × 800 logical pixels.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repository = LocalMenuRepository(latency: Duration.zero, seed: seed);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        menuRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(FixedClock(manilaNow ?? openTime)),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

/// Scrolls [finder] into view, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await revealInList(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Scrolls the main vertical list until [finder] is built and on screen.
Future<void> revealInList(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// The [IconButton] with the given tooltip.
IconButton iconButton(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(
      find.byWidgetPredicate((w) => w is IconButton && w.tooltip == tooltip),
    );

/// Lets short UI timers (button feedback, snackbars) finish.
Future<void> settleTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}
