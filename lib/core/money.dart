import 'package:intl/intl.dart';

/// All money in the app is stored as integer **centavos** (₱1 = 100 centavos).
/// Never use doubles for money. These helpers only format for display.
abstract final class Money {
  static final NumberFormat _pesoGrouping = NumberFormat('#,##0', 'en');

  /// Formats centavos as Philippine Peso.
  ///
  /// Whole pesos drop the decimals (`7500` → `₱75`); anything else shows two
  /// decimals (`275` → `₱2.75`). Negative values get a leading minus sign.
  static String format(int centavos) {
    final negative = centavos < 0;
    final abs = centavos.abs();
    final pesos = abs ~/ 100;
    final rest = abs % 100;
    final buffer = StringBuffer(negative ? '-₱' : '₱')
      ..write(_pesoGrouping.format(pesos));
    if (rest != 0) {
      buffer
        ..write('.')
        ..write(rest.toString().padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// Formats a price difference with an explicit sign, e.g. `+₱5`.
  static String formatDelta(int centavos) =>
      centavos >= 0 ? '+${format(centavos)}' : format(centavos);

  /// Price per unit (e.g. per oz), rounded to the nearest centavo.
  static int perUnit(int centavos, num measure) {
    if (measure <= 0) {
      throw ArgumentError.value(measure, 'measure', 'must be positive');
    }
    return (centavos / measure).round();
  }

  /// Converts a peso amount typed by a person (e.g. "75" or "2.75") to
  /// centavos. Returns null when the text is not a valid, non-negative amount
  /// with at most two decimals.
  static int? tryParsePesos(String input) {
    final text = input.trim().replaceAll(',', '').replaceAll('₱', '');
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(text);
    if (match == null) return null;
    final pesos = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return pesos * 100 + int.parse(fraction);
  }
}
