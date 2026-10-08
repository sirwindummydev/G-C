import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/data/models/promo_code.dart';
import 'package:gnc_app/domain/promo_rules.dart';

void main() {
  final now = DateTime.utc(2026, 10, 7, 14);
  const tenPercent = PromoCode(
    code: 'WELCOME10',
    type: PromoType.percent,
    value: 10,
    minOrder: 10000,
  );
  const twentyOff = PromoCode(
    code: 'MERIENDA20',
    type: PromoType.fixed,
    value: 2000,
  );
  final codes = [
    tenPercent,
    twentyOff,
    const PromoCode(
      code: 'OFF',
      type: PromoType.percent,
      value: 50,
      isActive: false,
    ),
    PromoCode(
      code: 'OLD',
      type: PromoType.fixed,
      value: 500,
      expiresAt: DateTime.utc(2026, 10, 1),
    ),
  ];

  PromoCheck check(String input, int total) => PromoRules.check(
    input: input,
    codes: codes,
    orderTotal: total,
    manilaNow: now,
  );

  group('discounts (centavos)', () {
    test('percent rounds down to the centavo', () {
      expect(PromoRules.discountFor(tenPercent, 20500), 2050);
      expect(PromoRules.discountFor(tenPercent, 12345), 1234);
    });

    test('fixed amount never exceeds the order', () {
      expect(PromoRules.discountFor(twentyOff, 20500), 2000);
      expect(PromoRules.discountFor(twentyOff, 1500), 1500);
    });

    test('nothing off an empty order', () {
      expect(PromoRules.discountFor(tenPercent, 0), 0);
    });

    test('percent is capped at 100%', () {
      const silly = PromoCode(code: 'X', type: PromoType.percent, value: 150);
      expect(PromoRules.discountFor(silly, 1000), 1000);
    });
  });

  group('validation', () {
    test('accepts a valid code, ignoring case and spaces', () {
      final result = check('  welcome 10 ', 20500);
      expect(result, isA<PromoAccepted>());
      expect((result as PromoAccepted).discount, 2050);
      expect(result.promo.code, 'WELCOME10');
    });

    PromoProblem problemOf(PromoCheck c) => (c as PromoRejected).problem;

    test('rejects empty input', () {
      expect(problemOf(check('   ', 20500)), PromoProblem.empty);
    });

    test('rejects unknown codes', () {
      final result = check('NOPE', 20500);
      expect(problemOf(result), PromoProblem.notFound);
      expect((result as PromoRejected).message, contains("couldn't find"));
    });

    test('rejects deactivated codes', () {
      expect(problemOf(check('off', 20500)), PromoProblem.inactive);
    });

    test('rejects expired codes with the date', () {
      final result = check('OLD', 20500);
      expect(problemOf(result), PromoProblem.expired);
      expect((result as PromoRejected).message, contains('1 Oct 2026'));
    });

    test('expiry is exclusive: valid until the moment it ends', () {
      final ends = PromoCode(
        code: 'END',
        type: PromoType.fixed,
        value: 100,
        expiresAt: now,
      );
      final before = PromoRules.check(
        input: 'END',
        codes: [ends],
        orderTotal: 1000,
        manilaNow: now.subtract(const Duration(minutes: 1)),
      );
      expect(before, isA<PromoAccepted>());
      final at = PromoRules.check(
        input: 'END',
        codes: [ends],
        orderTotal: 1000,
        manilaNow: now,
      );
      expect(at, isA<PromoRejected>());
    });

    test('rejects orders below the minimum and says how much more', () {
      final result = check('WELCOME10', 7500);
      expect(problemOf(result), PromoProblem.belowMinimum);
      expect(
        (result as PromoRejected).message,
        'Spend ₱100 or more to use this code (₱25 to go).',
      );
      expect(check('WELCOME10', 10000), isA<PromoAccepted>());
    });

    test('rejects an empty cart', () {
      expect(problemOf(check('MERIENDA20', 0)), PromoProblem.emptyCart);
    });
  });

  test('describe for admin lists', () {
    expect(PromoRules.describe(tenPercent), '10% off · min ₱100');
    expect(PromoRules.describe(twentyOff), '₱20 off');
  });

  test('codes survive a map round trip (for Firestore)', () {
    final code = PromoCode(
      code: 'TEST',
      type: PromoType.fixed,
      value: 1500,
      description: 'Test',
      minOrder: 5000,
      expiresAt: DateTime.utc(2026, 12, 31, 23, 59),
      isActive: false,
    );
    final copy = PromoCode.fromMap('test', code.toMap());
    expect(copy.code, 'TEST');
    expect(copy.toMap(), code.toMap());
  });
}
