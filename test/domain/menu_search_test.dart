import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/data/seed/seed_menu.dart';
import 'package:gnc_app/domain/menu_search.dart';

import '../helpers.dart';

void main() {
  final catalog = seedCatalog();
  final soda = catalog.itemById(SeedMenu.fruitSoda)!;
  final octopus = catalog.itemById('takoyaki-octopus')!;

  test('empty query matches everything', () {
    expect(MenuSearch.matchesItem(octopus, '  '), isTrue);
    expect(
      MenuSearch.matchesCombo(catalog.comboById('takoyaki-duo')!, ''),
      isTrue,
    );
  });

  test('matches item names, ignoring case and spaces', () {
    expect(MenuSearch.matchesItem(octopus, ' OCTO '), isTrue);
    expect(MenuSearch.matchesItem(octopus, 'squid'), isFalse);
  });

  test('matches option names, so a flavour finds its drink', () {
    expect(MenuSearch.matchesItem(soda, 'mango'), isTrue);
    expect(MenuSearch.matchesItem(soda, "tiger's"), isTrue);
    expect(MenuSearch.matchesItem(soda, '20oz'), isTrue);
    expect(MenuSearch.matchesItem(octopus, 'mango'), isFalse);
  });

  test('matches combo names', () {
    final barkada = catalog.comboById('barkada-box')!;
    expect(MenuSearch.matchesCombo(barkada, 'barkada'), isTrue);
    expect(MenuSearch.matchesCombo(barkada, 'merienda'), isFalse);
  });
}
