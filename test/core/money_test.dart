import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/core/money.dart';

void main() {
  group('Money.format', () {
    test('drops decimals for whole pesos', () {
      expect(Money.format(7500), '₱75');
      expect(Money.format(0), '₱0');
    });

    test('shows two decimals otherwise', () {
      expect(Money.format(275), '₱2.75');
      expect(Money.format(5), '₱0.05');
      expect(Money.format(3050), '₱30.50');
    });

    test('groups thousands', () {
      expect(Money.format(125000), '₱1,250');
      expect(Money.format(123456789), '₱1,234,567.89');
    });

    test('handles negatives and deltas', () {
      expect(Money.format(-500), '-₱5');
      expect(Money.formatDelta(500), '+₱5');
      expect(Money.formatDelta(-500), '-₱5');
    });
  });

  group('Money.perUnit', () {
    test('20oz soda at ₱55 is ₱2.75/oz', () {
      expect(Money.perUnit(5500, 20), 275);
    });

    test('rounds to the nearest centavo', () {
      expect(Money.perUnit(5000, 16), 313); // 312.5 → 313
      expect(Money.perUnit(3500, 12), 292); // 291.67 → 292
    });

    test('rejects non-positive measures', () {
      expect(() => Money.perUnit(100, 0), throwsArgumentError);
    });
  });

  group('Money.tryParsePesos', () {
    test('parses valid amounts', () {
      expect(Money.tryParsePesos('75'), 7500);
      expect(Money.tryParsePesos('2.75'), 275);
      expect(Money.tryParsePesos('2.5'), 250);
      expect(Money.tryParsePesos(' ₱1,250 '), 125000);
    });

    test('rejects invalid amounts', () {
      expect(Money.tryParsePesos(''), isNull);
      expect(Money.tryParsePesos('-5'), isNull);
      expect(Money.tryParsePesos('1.234'), isNull);
      expect(Money.tryParsePesos('abc'), isNull);
    });
  });
}
