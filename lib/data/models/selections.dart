/// What a customer chose for one item: its id plus the chosen option ids per
/// option group. Immutable; every change returns a new selection.
class ItemSelection {
  const ItemSelection({required this.itemId, this.choiceIdsByGroup = const {}});

  final String itemId;
  final Map<String, List<String>> choiceIdsByGroup;

  List<String> choicesFor(String groupId) =>
      choiceIdsByGroup[groupId] ?? const [];

  bool isChosen(String groupId, String choiceId) =>
      choicesFor(groupId).contains(choiceId);

  /// Replaces whatever was chosen in a single-choice group.
  ItemSelection choose(String groupId, String choiceId) => ItemSelection(
    itemId: itemId,
    choiceIdsByGroup: {
      ...choiceIdsByGroup,
      groupId: [choiceId],
    },
  );

  /// Adds or removes a choice in a multi-choice group. Does not add beyond
  /// [maxSelect].
  ItemSelection toggle(
    String groupId,
    String choiceId, {
    required int maxSelect,
  }) {
    final current = choicesFor(groupId);
    final List<String> next;
    if (current.contains(choiceId)) {
      next = current.where((id) => id != choiceId).toList();
    } else if (current.length < maxSelect) {
      next = [...current, choiceId];
    } else {
      return this;
    }
    return ItemSelection(
      itemId: itemId,
      choiceIdsByGroup: {...choiceIdsByGroup, groupId: next},
    );
  }

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'choiceIdsByGroup': choiceIdsByGroup,
  };

  @override
  bool operator ==(Object other) =>
      other is ItemSelection &&
      other.itemId == itemId &&
      _sameChoices(other.choiceIdsByGroup, choiceIdsByGroup);

  @override
  int get hashCode => Object.hash(
    itemId,
    Object.hashAllUnordered(
      choiceIdsByGroup.entries
          .where((e) => e.value.isNotEmpty)
          .map((e) => Object.hash(e.key, Object.hashAllUnordered(e.value))),
    ),
  );

  static bool _sameChoices(
    Map<String, List<String>> a,
    Map<String, List<String>> b,
  ) {
    final keys = {...a.keys, ...b.keys};
    for (final key in keys) {
      final left = {...?a[key]};
      final right = {...?b[key]};
      if (left.length != right.length || !left.containsAll(right)) {
        return false;
      }
    }
    return true;
  }
}

/// What a customer chose for a combo: for each slot, one entry per pick.
/// A null entry is a pick not made yet.
class ComboSelection {
  const ComboSelection({required this.comboId, this.picksBySlot = const {}});

  final String comboId;
  final Map<String, List<ItemSelection?>> picksBySlot;

  /// Picks for a slot, padded with nulls to [count].
  List<ItemSelection?> picksFor(String slotId, int count) {
    final existing = picksBySlot[slotId] ?? const [];
    return List.generate(
      count,
      (i) => i < existing.length ? existing[i] : null,
    );
  }

  ComboSelection setPick(
    String slotId,
    int index,
    int count,
    ItemSelection? pick,
  ) {
    final picks = picksFor(slotId, count)..[index] = pick;
    return ComboSelection(
      comboId: comboId,
      picksBySlot: {...picksBySlot, slotId: picks},
    );
  }

  Iterable<ItemSelection> get filledPicks =>
      picksBySlot.values.expand((p) => p).whereType<ItemSelection>();
}
