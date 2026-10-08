import 'map_reader.dart';

/// One choice inside an [OptionGroup], e.g. "Mango" or "20oz".
class OptionChoice {
  const OptionChoice({
    required this.id,
    required this.name,
    this.priceDelta = 0,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.badge,
    this.measure,
    this.measureUnit,
  });

  final String id;
  final String name;

  /// Added to the item's base price when chosen, in centavos. May be 0.
  final int priceDelta;

  /// False when sold out. Sold-out choices are shown but cannot be picked.
  final bool isAvailable;
  final int sortOrder;

  /// Optional admin-set highlight, e.g. "Best value".
  final String? badge;

  /// Optional size of this choice (e.g. 20 for 20oz), used to show price per
  /// unit. Both [measure] and [measureUnit] must be set for that to appear.
  final double? measure;
  final String? measureUnit;

  bool get hasMeasure => measure != null && measure! > 0 && measureUnit != null;

  factory OptionChoice.fromMap(Map<String, dynamic> map) => OptionChoice(
    id: map.str('id'),
    name: map.str('name'),
    priceDelta: map.integer('priceDelta'),
    isAvailable: map.boolean('isAvailable', true),
    sortOrder: map.integer('sortOrder'),
    badge: map.strOrNull('badge'),
    measure: map.decimalOrNull('measure'),
    measureUnit: map.strOrNull('measureUnit'),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'priceDelta': priceDelta,
    'isAvailable': isAvailable,
    'sortOrder': sortOrder,
    if (badge != null) 'badge': badge,
    if (measure != null) 'measure': measure,
    if (measureUnit != null) 'measureUnit': measureUnit,
  };

  OptionChoice copyWith({
    String? name,
    int? priceDelta,
    bool? isAvailable,
    int? sortOrder,
    String? Function()? badge,
    double? Function()? measure,
    String? Function()? measureUnit,
  }) => OptionChoice(
    id: id,
    name: name ?? this.name,
    priceDelta: priceDelta ?? this.priceDelta,
    isAvailable: isAvailable ?? this.isAvailable,
    sortOrder: sortOrder ?? this.sortOrder,
    badge: badge != null ? badge() : this.badge,
    measure: measure != null ? measure() : this.measure,
    measureUnit: measureUnit != null ? measureUnit() : this.measureUnit,
  );
}

/// A set of choices for an item, e.g. "Flavour" or "Size".
class OptionGroup {
  const OptionGroup({
    required this.id,
    required this.name,
    required this.choices,
    this.minSelect = 1,
    this.maxSelect = 1,
    this.showAbsolutePrice = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;

  /// Fewest choices the customer must pick. 0 makes the group optional.
  final int minSelect;

  /// Most choices the customer may pick.
  final int maxSelect;

  /// When true, each choice is labelled with the full item price
  /// (base + delta), e.g. sizes "12oz ₱35". When false, only non-zero
  /// deltas are shown, e.g. "+₱5".
  final bool showAbsolutePrice;
  final int sortOrder;
  final List<OptionChoice> choices;

  bool get isRequired => minSelect > 0;
  bool get isSingleChoice => maxSelect == 1;

  List<OptionChoice> get sortedChoices =>
      [...choices]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<OptionChoice> get availableChoices =>
      sortedChoices.where((c) => c.isAvailable).toList();

  OptionChoice? choiceById(String id) {
    for (final choice in choices) {
      if (choice.id == id) return choice;
    }
    return null;
  }

  factory OptionGroup.fromMap(Map<String, dynamic> map) => OptionGroup(
    id: map.str('id'),
    name: map.str('name'),
    minSelect: map.integer('minSelect', 1),
    maxSelect: map.integer('maxSelect', 1),
    showAbsolutePrice: map.boolean('showAbsolutePrice'),
    sortOrder: map.integer('sortOrder'),
    choices: map.maps('choices').map(OptionChoice.fromMap).toList(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'minSelect': minSelect,
    'maxSelect': maxSelect,
    'showAbsolutePrice': showAbsolutePrice,
    'sortOrder': sortOrder,
    'choices': choices.map((c) => c.toMap()).toList(),
  };

  OptionGroup copyWith({
    String? name,
    int? minSelect,
    int? maxSelect,
    bool? showAbsolutePrice,
    int? sortOrder,
    List<OptionChoice>? choices,
  }) => OptionGroup(
    id: id,
    name: name ?? this.name,
    minSelect: minSelect ?? this.minSelect,
    maxSelect: maxSelect ?? this.maxSelect,
    showAbsolutePrice: showAbsolutePrice ?? this.showAbsolutePrice,
    sortOrder: sortOrder ?? this.sortOrder,
    choices: choices ?? this.choices,
  );
}
