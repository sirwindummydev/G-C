import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/money.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/components.dart';
import '../../data/models/category.dart';
import '../../data/models/combo.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/selections.dart';
import '../../domain/combo_pricing.dart';
import '../../domain/item_pricing.dart';
import '../../domain/menu_catalog.dart';
import '../../domain/menu_search.dart';
import '../cart/cart_providers.dart';
import '../cart/widgets/cart_widgets.dart';
import '../shell/customer_shell.dart';
import 'combo_detail_screen.dart';
import 'item_detail_screen.dart';
import 'menu_providers.dart';
import 'widgets/menu_cards.dart';
import 'widgets/shop_status_banner.dart';

/// "Good Morning" / "Good Afternoon" / "Good Evening" for a Manila time.
String greetingFor(DateTime manilaNow) {
  final hour = manilaNow.hour;
  if (hour >= 5 && hour < 12) return 'Good Morning';
  if (hour >= 12 && hour < 18) return 'Good Afternoon';
  return 'Good Evening';
}

/// Customer home: peach header (greeting, status, search), category chips,
/// combo banners, Popular, then the menu in 2-column grids.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(menuCatalogProvider);
    return Scaffold(
      body: AsyncValueView<MenuCatalog>(
        value: catalog,
        loadingLabel: 'Loading menu',
        onRetry: () => retryMenu(ref),
        data: (catalog) => _HomeBody(catalog: catalog),
      ),
    );
  }
}

enum MenuSort { menuOrder, priceLowToHigh }

/// Presentation-only filters from the search bar's filter button.
class MenuFilters {
  const MenuFilters({this.hideSoldOut = false, this.sort = MenuSort.menuOrder});

  final bool hideSoldOut;
  final MenuSort sort;

  bool get isActive => hideSoldOut || sort != MenuSort.menuOrder;
}

/// An item or a combo in a menu list.
class _Entry {
  _Entry.item(MenuItem this.item) : combo = null;
  _Entry.combo(Combo this.combo) : item = null;

  final MenuItem? item;
  final Combo? combo;
}

class _HomeBody extends ConsumerStatefulWidget {
  const _HomeBody({required this.catalog});

  final MenuCatalog catalog;

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  static const _popularLimit = 8;
  static const _popularWidth = 150.0;

  final _search = TextEditingController();
  String _query = '';

  /// Null means "All".
  String? _categoryId;
  MenuFilters _filters = const MenuFilters();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _browsing => _query.trim().isEmpty && _categoryId == null;

  void _clearAll() {
    _search.clear();
    setState(() {
      _query = '';
      _categoryId = null;
      _filters = const MenuFilters();
    });
  }

  void _openItem(MenuItem item, String origin) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ItemDetailScreen(
        itemId: item.id,
        heroTag: itemHeroTag(item.id, origin),
      ),
    ),
  );

  void _openCombo(Combo combo, Object heroTag) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ComboDetailScreen(comboId: combo.id, heroTag: heroTag),
    ),
  );

  void _quickAdd(MenuItem item) {
    ref.read(cartProvider.notifier).addItem(ItemSelection(itemId: item.id));
    final serving = item.servingLabel == null ? '' : ' (${item.servingLabel})';
    showAddedToCart(context, 'Added ${item.name}$serving to your cart');
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<MenuFilters>(
      context: context,
      builder: (_) => _FilterSheet(initial: _filters),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  int _priceOf(_Entry e, ComboPricing pricing) => e.item != null
      ? ItemPricing.fromPrice(e.item!)
      : pricing.fromPrice(e.combo!);

  bool _orderable(_Entry e, ComboPricing pricing) =>
      e.item?.isOrderable ?? pricing.isOrderable(e.combo!);

  /// Entries for one category after search, filters and sorting.
  List<_Entry> _entriesFor(Category category, ComboPricing pricing) {
    final catalog = widget.catalog;
    final entries = <_Entry>[
      for (final combo in catalog.combosIn(category.id))
        if (MenuSearch.matchesCombo(combo, _query)) _Entry.combo(combo),
      for (final item in catalog.itemsIn(category.id))
        if (MenuSearch.matchesItem(item, _query)) _Entry.item(item),
    ];
    if (_filters.hideSoldOut) {
      entries.removeWhere((e) => !_orderable(e, pricing));
    }
    if (_filters.sort == MenuSort.priceLowToHigh) {
      final order = {for (final (i, e) in entries.indexed) e: i};
      entries.sort((a, b) {
        final byPrice = _priceOf(a, pricing).compareTo(_priceOf(b, pricing));
        return byPrice != 0 ? byPrice : order[a]!.compareTo(order[b]!);
      });
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    final pricing = ComboPricing(catalog);
    final categories = catalog.visibleCategories
        .where((c) => !catalog.isEmpty(c.id))
        .toList();
    final visibleIds = {for (final c in categories) c.id};

    final sections = [
      for (final c in categories)
        if (_categoryId == null || c.id == _categoryId)
          (category: c, entries: _entriesFor(c, pricing)),
    ].where((s) => s.entries.isNotEmpty).toList();

    final slides = [
      for (final combo in catalog.combos)
        if (visibleIds.contains(combo.categoryId))
          PromoSlide(
            combo: combo,
            image: catalog.imageForCombo(combo),
            badge: switch (pricing.guaranteedSavings(combo)) {
              final saved? => 'Save ${Money.format(saved)}',
              null => null,
            },
            priceText: Money.format(pricing.fromPrice(combo)),
            soldOut: !pricing.isOrderable(combo),
          ),
    ]..sort((a, b) => (a.soldOut ? 1 : 0).compareTo(b.soldOut ? 1 : 0));

    // No sales data yet, so "Popular" is the orderable menu in menu order.
    // Real best-sellers can replace this once orders exist (Phase 7).
    final popular = [
      for (final c in categories)
        for (final item in catalog.itemsIn(c.id))
          if (item.isOrderable) item,
    ].take(_popularLimit).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HomeHeader(
            controller: _search,
            filtersActive: _filters.isActive,
            onQueryChanged: (q) => setState(() => _query = q),
            onClear: () {
              _search.clear();
              setState(() => _query = '');
            },
            onFilters: _openFilters,
          ),
        ),
        SliverToBoxAdapter(
          child: _CategoryChips(
            categories: categories,
            selectedId: _categoryId,
            onSelected: (id) => setState(() => _categoryId = id),
          ),
        ),
        if (_browsing && slides.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Combo deals')),
          SliverToBoxAdapter(
            child: PromoBannerCarousel(slides: slides, onOpen: _openCombo),
          ),
        ],
        if (_browsing && popular.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Popular')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: menuTileExtent(context, _popularWidth) + Gap.l,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  Gap.screen,
                  0,
                  Gap.screen,
                  Gap.l,
                ),
                clipBehavior: Clip.none,
                itemCount: popular.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (_, i) => SizedBox(
                  width: _popularWidth,
                  child: MenuTileCard.item(
                    key: ValueKey('popular-${popular[i].id}'),
                    item: popular[i],
                    image: catalog.imageForItem(popular[i]),
                    heroOrigin: 'popular',
                    onTap: () => _openItem(popular[i], 'popular'),
                    onQuickAdd: () => _quickAdd(popular[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
        for (final section in sections) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              section.category.name,
              key: ValueKey('section-${section.category.id}'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.screen),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                const columns = 2;
                const spacing = 14.0;
                final tileWidth =
                    (constraints.crossAxisExtent - spacing * (columns - 1)) /
                    columns;
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    mainAxisExtent: menuTileExtent(context, tileWidth),
                  ),
                  itemCount: section.entries.length,
                  itemBuilder: (_, i) {
                    final entry = section.entries[i];
                    if (entry.combo case final combo?) {
                      return MenuTileCard.combo(
                        key: ValueKey('combo-${combo.id}'),
                        combo: combo,
                        pricing: pricing,
                        image: catalog.imageForCombo(combo),
                        heroOrigin: 'grid',
                        onTap: () =>
                            _openCombo(combo, comboHeroTag(combo.id, 'grid')),
                      );
                    }
                    final item = entry.item!;
                    return MenuTileCard.item(
                      key: ValueKey('item-${item.id}'),
                      item: item,
                      image: catalog.imageForItem(item),
                      heroOrigin: 'grid',
                      onTap: () => _openItem(item, 'grid'),
                      onQuickAdd: () => _quickAdd(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
        if (sections.isEmpty)
          SliverToBoxAdapter(
            child: _NoResults(query: _query.trim(), onClear: _clearAll),
          ),
        // Room for the floating navigation bar (reported as bottom padding).
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.paddingOf(context).bottom + Gap.section,
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({
    required this.controller,
    required this.filtersActive,
    required this.onQueryChanged,
    required this.onClear,
    required this.onFilters,
  });

  final TextEditingController controller;
  final bool filtersActive;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(shopSettingsProvider).value;
    final now =
        ref.watch(manilaNowProvider).value ??
        ref.watch(clockProvider).nowInManila();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.peachTop, AppColors.peachBottom],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.header),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Gap.screen,
        MediaQuery.paddingOf(context).top + Gap.m,
        Gap.screen,
        Gap.screen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Wordmark(text: settings?.shopName ?? 'G&C', height: 40),
              const Spacer(),
              const CartIconButton(),
            ],
          ),
          const SizedBox(height: Gap.l),
          Semantics(
            header: true,
            child: Text(greetingFor(now), style: AppText.greeting()),
          ),
          if (settings != null && settings.tagline.isNotEmpty) ...[
            const SizedBox(height: Gap.xs),
            Text(settings.tagline, style: AppText.description(size: 14)),
          ],
          const SizedBox(height: Gap.m),
          const ShopStatusPill(),
          const SizedBox(height: Gap.l),
          _SearchBar(
            controller: controller,
            filtersActive: filtersActive,
            onChanged: onQueryChanged,
            onClear: onClear,
            onFilters: onFilters,
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.filtersActive,
    required this.onChanged,
    required this.onClear,
    required this.onFilters,
  });

  final TextEditingController controller;
  final bool filtersActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: Gap.l, right: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textMuted),
          const SizedBox(width: Gap.s),
          Expanded(
            child: TextField(
              key: const ValueKey('menu-search'),
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: poppins(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration.collapsed(
                hintText: 'Search takoyaki, drinks…',
                hintStyle: poppins(fontSize: 14, color: AppColors.textMuted),
              ).copyWith(filled: false),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
          ),
          Tooltip(
            message: filtersActive ? 'Filters (on)' : 'Filters',
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onFilters,
                child: SizedBox.square(
                  dimension: 40,
                  child: Badge(
                    isLabelVisible: filtersActive,
                    smallSize: 8,
                    backgroundColor: AppColors.text,
                    offset: const Offset(-8, 8),
                    child: const Center(
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <(String?, String)>[
      (null, 'All'),
      for (final c in categories) (c.id, c.name),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: Gap.screen),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.screen),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: Gap.s),
          itemBuilder: (_, i) {
            final (id, label) = chips[i];
            return CategoryChip(
              key: ValueKey('chip-${id ?? 'all'}'),
              label: label,
              selected: id == selectedId,
              onTap: () => onSelected(id),
            );
          },
        ),
      ),
    );
  }
}

/// Pill-shaped category chip: solid orange (dark text) when selected,
/// light grey without a border otherwise. The change is animated.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.chip,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Text(
                  label,
                  style: poppins(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Gap.screen,
        Gap.xxl,
        Gap.screen,
        Gap.l,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.borderStrong,
          ),
          const SizedBox(height: Gap.m),
          Text(
            query.isEmpty ? 'Nothing to show' : 'No matches for “$query”',
            style: AppText.sectionTitle(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gap.xs),
          Text(
            'Try another name or flavour, or clear the filters.',
            style: AppText.description(size: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gap.m),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear search and filters'),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final MenuFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _hideSoldOut = widget.initial.hideSoldOut;
  late MenuSort _sort = widget.initial.sort;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Gap.screen,
          0,
          Gap.screen,
          Gap.screen,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filters', style: AppText.sectionTitle()),
            const SizedBox(height: Gap.s),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hide sold-out items'),
              value: _hideSoldOut,
              onChanged: (v) => setState(() => _hideSoldOut = v),
            ),
            const SizedBox(height: Gap.s),
            Text('Sort by', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Gap.s),
            SegmentedButton<MenuSort>(
              segments: const [
                ButtonSegment(
                  value: MenuSort.menuOrder,
                  label: Text('Menu order'),
                ),
                ButtonSegment(
                  value: MenuSort.priceLowToHigh,
                  label: Text('Price: low to high'),
                ),
              ],
              selected: {_sort},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _sort = s.first),
            ),
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context)
                      .pop(MenuFilters(hideSoldOut: _hideSoldOut, sort: _sort)),
              child: const Text('Show results'),
            ),
          ],
        ),
      ),
    );
  }
}
