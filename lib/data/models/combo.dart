import 'map_reader.dart';
import 'menu_visual.dart';

/// A fixed-price bundle made of [slots].
///
/// Example: "Merienda Combo" = slot "Takoyaki" (1 pick from the Takoyaki
/// category) + slot "Fruit Soda" (1 pick, sizes limited to 16oz/20oz, with
/// +₱5 for 20oz).
class Combo {
  const Combo({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.slots,
    this.description = '',
    this.servingLabel,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.visual = const MenuVisual(iconKey: 'combo'),
    this.image,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;

  /// Fixed combo price in centavos, before any upgrade charges.
  final int price;
  final String? servingLabel;
  final bool isAvailable;
  final int sortOrder;
  final MenuVisual visual;

  /// Photo for this entry: an asset path (e.g.
  /// `assets/images/optimized/takoyaki.jpg`) or an `https://` URL. Null
  /// uses the category's default photo, or else the illustration.
  final String? image;
  final List<ComboSlot> slots;

  List<ComboSlot> get sortedSlots =>
      [...slots]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  factory Combo.fromMap(String id, Map<String, dynamic> map) => Combo(
    id: id,
    categoryId: map.str('categoryId'),
    name: map.str('name'),
    description: map.str('description'),
    price: map.integer('price'),
    servingLabel: map.strOrNull('servingLabel'),
    isAvailable: map.boolean('isAvailable', true),
    sortOrder: map.integer('sortOrder'),
    visual: MenuVisual.fromMap(map.mapOrNull('visual')),
    image: map.strOrNull('image'),
    slots: map.maps('slots').map(ComboSlot.fromMap).toList(),
  );

  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'name': name,
    'description': description,
    'price': price,
    if (servingLabel != null) 'servingLabel': servingLabel,
    'isAvailable': isAvailable,
    'sortOrder': sortOrder,
    'visual': visual.toMap(),
    if (image != null) 'image': image,
    'slots': slots.map((s) => s.toMap()).toList(),
  };

  Combo copyWith({
    String? categoryId,
    String? name,
    String? description,
    int? price,
    String? Function()? servingLabel,
    bool? isAvailable,
    int? sortOrder,
    MenuVisual? visual,
    String? Function()? image,
    List<ComboSlot>? slots,
  }) => Combo(
    id: id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    servingLabel: servingLabel != null ? servingLabel() : this.servingLabel,
    isAvailable: isAvailable ?? this.isAvailable,
    sortOrder: sortOrder ?? this.sortOrder,
    visual: visual ?? this.visual,
    image: image != null ? image() : this.image,
    slots: slots ?? this.slots,
  );
}

/// One part of a combo. The customer makes [picks] choices for it, each one
/// being a menu item (and that item's options, if it has any).
///
/// Eligible items are every item in [eligibleCategoryIds] plus every item in
/// [choices]. An explicit entry in [choices] wins over the category default,
/// so it can add an upgrade charge or restrict options for one item.
class ComboSlot {
  const ComboSlot({
    required this.id,
    required this.name,
    this.description = '',
    this.picks = 1,
    this.allowDuplicates = true,
    this.eligibleCategoryIds = const [],
    this.choices = const [],
    this.sortOrder = 0,
  });

  final String id;

  /// e.g. "Takoyaki flavours".
  final String name;

  /// e.g. "4 pcs per flavour".
  final String description;

  /// How many picks the customer makes in this slot, e.g. 2 for a Duo.
  final int picks;

  /// When false, the same item cannot be picked twice in this slot.
  final bool allowDuplicates;
  final List<String> eligibleCategoryIds;
  final List<ComboSlotChoice> choices;
  final int sortOrder;

  ComboSlotChoice? explicitChoiceFor(String itemId) {
    for (final choice in choices) {
      if (choice.itemId == itemId) return choice;
    }
    return null;
  }

  factory ComboSlot.fromMap(Map<String, dynamic> map) => ComboSlot(
    id: map.str('id'),
    name: map.str('name'),
    description: map.str('description'),
    picks: map.integer('picks', 1),
    allowDuplicates: map.boolean('allowDuplicates', true),
    eligibleCategoryIds: map.strings('eligibleCategoryIds'),
    choices: map.maps('choices').map(ComboSlotChoice.fromMap).toList(),
    sortOrder: map.integer('sortOrder'),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'picks': picks,
    'allowDuplicates': allowDuplicates,
    'eligibleCategoryIds': eligibleCategoryIds,
    'choices': choices.map((c) => c.toMap()).toList(),
    'sortOrder': sortOrder,
  };

  ComboSlot copyWith({
    String? name,
    String? description,
    int? picks,
    bool? allowDuplicates,
    List<String>? eligibleCategoryIds,
    List<ComboSlotChoice>? choices,
    int? sortOrder,
  }) => ComboSlot(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    picks: picks ?? this.picks,
    allowDuplicates: allowDuplicates ?? this.allowDuplicates,
    eligibleCategoryIds: eligibleCategoryIds ?? this.eligibleCategoryIds,
    choices: choices ?? this.choices,
    sortOrder: sortOrder ?? this.sortOrder,
  );
}

/// An item that can fill a [ComboSlot], with its combo-specific rules.
class ComboSlotChoice {
  const ComboSlotChoice({
    required this.itemId,
    this.upcharge = 0,
    this.optionRules = const [],
  });

  final String itemId;

  /// Extra charge in centavos for picking this item in the combo.
  final int upcharge;

  /// Restrictions and upgrade charges for the item's option groups.
  /// Groups without a rule allow all choices and charge each choice's normal
  /// price delta (so premium flavours still cost extra inside combos).
  final List<ComboOptionRule> optionRules;

  ComboOptionRule? ruleFor(String groupId) {
    for (final rule in optionRules) {
      if (rule.groupId == groupId) return rule;
    }
    return null;
  }

  factory ComboSlotChoice.fromMap(Map<String, dynamic> map) => ComboSlotChoice(
    itemId: map.str('itemId'),
    upcharge: map.integer('upcharge'),
    optionRules: map.maps('optionRules').map(ComboOptionRule.fromMap).toList(),
  );

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'upcharge': upcharge,
    'optionRules': optionRules.map((r) => r.toMap()).toList(),
  };
}

/// Combo rule for one option group of an item, e.g. Fruit Soda "Size" in the
/// Merienda Combo: only 16oz and 20oz allowed, 20oz costs +₱5.
///
/// When a rule exists, choices cost exactly [upcharges] (default ₱0), not
/// their normal price delta.
class ComboOptionRule {
  const ComboOptionRule({
    required this.groupId,
    this.allowedChoiceIds,
    this.upcharges = const {},
  });

  final String groupId;

  /// Null means every choice of the group is allowed.
  final List<String>? allowedChoiceIds;

  /// Upgrade charge per choice id, in centavos.
  final Map<String, int> upcharges;

  bool allows(String choiceId) =>
      allowedChoiceIds == null || allowedChoiceIds!.contains(choiceId);

  int upchargeFor(String choiceId) => upcharges[choiceId] ?? 0;

  factory ComboOptionRule.fromMap(Map<String, dynamic> map) => ComboOptionRule(
    groupId: map.str('groupId'),
    allowedChoiceIds: map['allowedChoiceIds'] is List
        ? map.strings('allowedChoiceIds')
        : null,
    upcharges: map.intMap('upcharges'),
  );

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    if (allowedChoiceIds != null) 'allowedChoiceIds': allowedChoiceIds,
    'upcharges': upcharges,
  };
}
