import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/local_menu_repository.dart';
import 'menu_repository.dart';
import 'promo_repository.dart';

/// The one place that decides where menu data comes from.
///
/// Phases 1–3 use local sample data. In Phase 4 this line becomes
/// `FirebaseMenuRepository(...)`; nothing else in the app changes.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final repository = LocalMenuRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

/// Promo codes. Locally the sample repository serves them too; in Phase 4
/// this becomes `FirebasePromoRepository(...)`.
final promoRepositoryProvider = Provider<PromoRepository>(
  (ref) => ref.watch(menuRepositoryProvider) as PromoRepository,
);
