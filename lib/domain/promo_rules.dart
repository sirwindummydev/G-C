import 'package:intl/intl.dart';

import '../core/money.dart';
import '../data/models/promo_code.dart';

/// Result of checking a promo code against an order.
sealed class PromoCheck {
  const PromoCheck();
}

class PromoAccepted extends PromoCheck {
  const PromoAccepted(this.promo, this.discount);

  final PromoCode promo;

  /// Discount in centavos (never more than the order).
  final int discount;
}

enum PromoProblem {
  empty,
  notFound,
  inactive,
  expired,
  emptyCart,
  belowMinimum,
}

class PromoRejected extends PromoCheck {
  const PromoRejected(this.problem, this.message);

  final PromoProblem problem;

  /// Friendly text to show the customer.
  final String message;
}

/// Promo code rules. All money is centavos. Pure Dart, no Flutter.
abstract final class PromoRules {
  /// Discount [promo] gives on an order of [orderTotal] centavos.
  /// Percentages round down to the centavo; never more than the order.
  static int discountFor(PromoCode promo, int orderTotal) {
    if (orderTotal <= 0) return 0;
    final raw = switch (promo.type) {
      PromoType.percent => orderTotal * promo.value.clamp(0, 100) ~/ 100,
      PromoType.fixed => promo.value,
    };
    return raw.clamp(0, orderTotal);
  }

  /// Checks [input] against the admin's [codes] for an order of
  /// [orderTotal] centavos (after combo savings) at [manilaNow].
  static PromoCheck check({
    required String input,
    required List<PromoCode> codes,
    required int orderTotal,
    required DateTime manilaNow,
  }) {
    final code = PromoCode.normalise(input);
    if (code.isEmpty) {
      return const PromoRejected(PromoProblem.empty, 'Enter a promo code.');
    }
    PromoCode? promo;
    for (final c in codes) {
      if (c.code == code) promo = c;
    }
    if (promo == null) {
      return const PromoRejected(
        PromoProblem.notFound,
        "We couldn't find that code. Check the spelling and try again.",
      );
    }
    if (!promo.isActive) {
      return const PromoRejected(
        PromoProblem.inactive,
        'This code is no longer active.',
      );
    }
    final expiresAt = promo.expiresAt;
    if (expiresAt != null && !manilaNow.isBefore(expiresAt)) {
      return PromoRejected(
        PromoProblem.expired,
        'This code expired on ${DateFormat('d MMM yyyy').format(expiresAt)}.',
      );
    }
    if (orderTotal <= 0) {
      return const PromoRejected(
        PromoProblem.emptyCart,
        'Add something to your cart first.',
      );
    }
    final minimum = promo.minOrder;
    if (minimum != null && orderTotal < minimum) {
      return PromoRejected(
        PromoProblem.belowMinimum,
        'Spend ${Money.format(minimum)} or more to use this code '
        '(${Money.format(minimum - orderTotal)} to go).',
      );
    }
    return PromoAccepted(promo, discountFor(promo, orderTotal));
  }

  /// "10% off" / "₱20 off", plus the minimum, for admin lists.
  static String describe(PromoCode promo) {
    final amount = switch (promo.type) {
      PromoType.percent => '${promo.value}% off',
      PromoType.fixed => '${Money.format(promo.value)} off',
    };
    return promo.minOrder == null
        ? amount
        : '$amount · min ${Money.format(promo.minOrder!)}';
  }
}
