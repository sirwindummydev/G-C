/// Small helpers for reading loosely-typed maps (seed data now, Firestore
/// documents later) without crashing on missing or mistyped fields.
extension MapReader on Map<String, dynamic> {
  String str(String key, [String fallback = '']) {
    final value = this[key];
    return value is String ? value : fallback;
  }

  String? strOrNull(String key) {
    final value = this[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  int integer(String key, [int fallback = 0]) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }

  double? decimalOrNull(String key) {
    final value = this[key];
    return value is num ? value.toDouble() : null;
  }

  bool boolean(String key, [bool fallback = false]) {
    final value = this[key];
    return value is bool ? value : fallback;
  }

  List<String> strings(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  Map<String, dynamic>? mapOrNull(String key) {
    final value = this[key];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  List<Map<String, dynamic>> maps(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList(growable: false);
  }

  Map<String, int> intMap(String key) {
    final value = this[key];
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (entry.key is String && entry.value is num)
          entry.key as String: (entry.value as num).round(),
    };
  }
}
