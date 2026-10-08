import 'map_reader.dart';

enum PromoType {
  /// [PromoCode.value] is a whole percentage, 1–100.
  percent,

  /// [PromoCode.value] is an amount in centavos.
  fixed,
}

/// A promo code customers can apply in the cart. Created and edited by
/// admin; the [code] is stored upper-case and is the document id.
class PromoCode {
  const PromoCode({
    required this.code,
    required this.type,
    required this.value,
    this.description = '',
    this.minOrder,
    this.expiresAt,
    this.isActive = true,
  });

  final String code;
  final PromoType type;

  /// Percentage (1–100) for [PromoType.percent]; centavos for
  /// [PromoType.fixed].
  final int value;

  /// Short admin note shown to customers on success, e.g. "Welcome treat".
  final String description;

  /// Minimum order in centavos (after combo savings), or null for none.
  final int? minOrder;

  /// Manila wall-clock time the code stops working (see `Clock`), or null
  /// for no expiry.
  final DateTime? expiresAt;

  /// Admin's on/off switch.
  final bool isActive;

  /// Codes are matched case-insensitively and without spaces.
  static String normalise(String input) =>
      input.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  factory PromoCode.fromMap(String code, Map<String, dynamic> map) => PromoCode(
    code: normalise(code),
    type: map.str('type') == 'fixed' ? PromoType.fixed : PromoType.percent,
    value: map.integer('value'),
    description: map.str('description'),
    minOrder: map['minOrder'] is num ? map.integer('minOrder') : null,
    expiresAt: DateTime.tryParse(map.str('expiresAt'))?.toUtc(),
    isActive: map.boolean('isActive', true),
  );

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'value': value,
    'description': description,
    if (minOrder != null) 'minOrder': minOrder,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    'isActive': isActive,
  };

  PromoCode copyWith({
    PromoType? type,
    int? value,
    String? description,
    int? Function()? minOrder,
    DateTime? Function()? expiresAt,
    bool? isActive,
  }) => PromoCode(
    code: code,
    type: type ?? this.type,
    value: value ?? this.value,
    description: description ?? this.description,
    minOrder: minOrder != null ? minOrder() : this.minOrder,
    expiresAt: expiresAt != null ? expiresAt() : this.expiresAt,
    isActive: isActive ?? this.isActive,
  );
}
