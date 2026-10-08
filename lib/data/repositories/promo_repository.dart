import '../models/promo_code.dart';

/// Source of promo codes. The local sample-data repository (now) and a
/// Firebase repository (Phase 4+) implement this; switch in
/// `promoRepositoryProvider` (lib/data/repositories/providers.dart).
///
/// From Phase 4, discounts are recalculated on the backend from these
/// codes; the app's value is only for display.
abstract interface class PromoRepository {
  Stream<List<PromoCode>> watchPromoCodes();

  /// Creates or replaces the code with the same [PromoCode.code].
  Future<void> savePromoCode(PromoCode promo);
}
