import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/data/models/promo_code.dart';
import 'package:gnc_app/features/admin/admin_home_screen.dart';
import 'package:gnc_app/features/cart/cart_providers.dart';

import '../helpers.dart';

List<PromoCode> codesIn(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(AdminHomeScreen)))
        .read(promoCodesProvider)
        .requireValue;

void main() {
  testWidgets('admin sees codes with their rules and status', (tester) async {
    await pumpWithMenu(tester, const AdminHomeScreen());
    await revealInList(
      tester,
      find.byKey(const ValueKey('promo-row-WELCOME10')),
    );
    expect(find.text('10% off · min ₱100'), findsOneWidget);
    expect(find.text('₱20 off · min ₱150'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget); // GRANDOPENING
  });

  testWidgets('create a code: validation, then save', (tester) async {
    await pumpWithMenu(tester, const AdminHomeScreen());
    await tapVisible(tester, find.byKey(const ValueKey('promo-new')));
    await tester.pumpAndSettle();

    // Empty form → errors.
    await tapVisible(tester, find.byKey(const ValueKey('promo-save')));
    await tester.pumpAndSettle();
    expect(
      find.text('Use 3–20 letters or numbers, no spaces.'),
      findsOneWidget,
    );
    expect(find.text('Enter a whole number, 1–100.'), findsOneWidget);

    // Duplicate code → error.
    await tester.enterText(
      find.byKey(const ValueKey('promo-code-field')),
      'welcome10',
    );
    await tester.enterText(
      find.byKey(const ValueKey('promo-value-field')),
      '15',
    );
    await tapVisible(tester, find.byKey(const ValueKey('promo-save')));
    await tester.pumpAndSettle();
    expect(find.text('That code already exists.'), findsOneWidget);

    // Fixed ₱ amount.
    await tester.enterText(
      find.byKey(const ValueKey('promo-code-field')),
      'takoyaki15',
    );
    await tapVisible(tester, find.text('Fixed ₱'));
    await tester.enterText(
      find.byKey(const ValueKey('promo-value-field')),
      '12.50',
    );
    await tapVisible(tester, find.byKey(const ValueKey('promo-save')));
    await tester.pumpAndSettle();

    expect(find.text('Saved TAKOYAKI15.'), findsOneWidget);
    final saved = codesIn(tester).singleWhere((c) => c.code == 'TAKOYAKI15');
    expect(saved.type, PromoType.fixed);
    expect(saved.value, 1250);
    expect(saved.minOrder, isNull);
    expect(saved.isActive, isTrue);
    await settleTimers(tester);
  });

  testWidgets('switch a code off from the list', (tester) async {
    await pumpWithMenu(tester, const AdminHomeScreen());
    final row = find.byKey(const ValueKey('promo-row-MERIENDA20'));
    await revealInList(tester, row);
    await tapVisible(
      tester,
      find.descendant(of: row, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(
      codesIn(tester).singleWhere((c) => c.code == 'MERIENDA20').isActive,
      isFalse,
    );
  });
}
