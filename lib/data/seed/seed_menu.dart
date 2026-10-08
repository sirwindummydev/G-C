import '../models/category.dart';
import '../models/combo.dart';
import '../models/menu_item.dart';
import '../models/menu_visual.dart';
import '../models/option_group.dart';
import '../models/promo_code.dart';
import '../models/shop_settings.dart';

/// The starting menu for G&C. This is only *seed* data: the app reads the
/// menu from the repository, and everything here is editable by admin.
/// In Phase 4 this same data is uploaded to Firestore.
class SeedMenu {
  const SeedMenu({
    required this.categories,
    required this.items,
    required this.combos,
    required this.settings,
    this.promos = const [],
  });

  final List<Category> categories;
  final List<MenuItem> items;
  final List<Combo> combos;
  final ShopSettings settings;

  /// Starting promo codes (editable in the admin screen).
  final List<PromoCode> promos;

  // Ids used to link seed records together.
  static const takoyakiCategory = 'takoyaki';
  static const combosCategory = 'combos';
  static const drinksCategory = 'drinks';
  static const fruitSoda = 'fruit-soda';
  static const sodaFlavourGroup = 'flavour';
  static const sodaSizeGroup = 'size';
  static const size12 = '12oz';
  static const size16 = '16oz';
  static const size20 = '20oz';

  /// The real takoyaki photo (optimised copy; see tool/images/).
  static const takoyakiPhoto = 'assets/images/optimized/takoyaki.jpg';

  factory SeedMenu.standard() => SeedMenu(
    categories: _categories,
    items: [..._takoyaki(), _fruitSoda()],
    combos: _combos,
    settings: _settings,
    promos: _promos,
  );

  static const _categories = [
    Category(
      id: takoyakiCategory,
      name: 'Takoyaki',
      description: 'Crispy outside, gooey inside. 4 pieces per serving.',
      sortOrder: 0,
      visual: MenuVisual(iconKey: 'takoyaki', colorHex: '#E4572E'),
      // Every takoyaki item (and takoyaki-only combo) uses this photo unless
      // it has its own `image`.
      defaultImage: takoyakiPhoto,
    ),
    Category(
      id: combosCategory,
      name: 'Combos',
      description: 'Bundles that save you more.',
      sortOrder: 1,
      visual: MenuVisual(iconKey: 'combo', colorHex: '#F29E4C'),
    ),
    Category(
      id: drinksCategory,
      name: 'Drinks',
      description: 'Ice-cold fruit sodas.',
      sortOrder: 2,
      visual: MenuVisual(iconKey: 'drink', colorHex: '#2A9D8F'),
    ),
  ];

  static List<MenuItem> _takoyaki() {
    const flavours = [
      ('octopus', 'Octopus', 'The classic: tender octopus bits.', '#C0392B'),
      ('cheese', 'Cheese', 'Loaded with melty cheese.', '#F4A300'),
      (
        'ham-cheese',
        'Ham & Cheese',
        'Savoury ham with melty cheese.',
        '#E67E22',
      ),
      ('squid', 'Squid', 'Chewy squid in every ball.', '#8E5A9B'),
      ('crabstix', 'Crabstix', 'Sweet crab sticks inside.', '#E25563'),
      ('assorted', 'Assorted', "Can't decide? A mix of flavours.", '#6D4C41'),
    ];
    return [
      for (final (index, (id, name, description, color)) in flavours.indexed)
        MenuItem(
          id: 'takoyaki-$id',
          categoryId: takoyakiCategory,
          name: name,
          description: description,
          basePrice: 7500,
          servingLabel: '4 pcs',
          sortOrder: index,
          visual: MenuVisual(iconKey: 'takoyaki', colorHex: color),
        ),
    ];
  }

  static MenuItem _fruitSoda() {
    const flavours = [
      'Lemon',
      'Blueberry',
      'Strawberry',
      'Mango',
      'Watermelon',
      'Melon',
      'Grapes',
      'Kiwi',
      'Green Apple',
      "Tiger's Blood",
      'Pineapple',
    ];
    return MenuItem(
      id: fruitSoda,
      categoryId: drinksCategory,
      name: 'Fruit Soda',
      description: 'Sparkling soda with your choice of fruit flavour.',
      // Drinks are priced by size, so the price lives on the size options.
      basePrice: 0,
      visual: const MenuVisual(iconKey: 'drink', colorHex: '#2A9D8F'),
      optionGroups: [
        OptionGroup(
          id: sodaFlavourGroup,
          name: 'Flavour',
          sortOrder: 0,
          choices: [
            for (final (index, name) in flavours.indexed)
              OptionChoice(id: _slug(name), name: name, sortOrder: index),
          ],
        ),
        const OptionGroup(
          id: sodaSizeGroup,
          name: 'Size',
          sortOrder: 1,
          showAbsolutePrice: true,
          choices: [
            OptionChoice(
              id: size12,
              name: '12oz',
              priceDelta: 3500,
              measure: 12,
              measureUnit: 'oz',
              sortOrder: 0,
            ),
            OptionChoice(
              id: size16,
              name: '16oz',
              priceDelta: 5000,
              measure: 16,
              measureUnit: 'oz',
              sortOrder: 1,
            ),
            OptionChoice(
              id: size20,
              name: '20oz',
              priceDelta: 5500,
              measure: 20,
              measureUnit: 'oz',
              badge: 'Best value',
              sortOrder: 2,
            ),
          ],
        ),
      ],
    );
  }

  static const _combos = [
    Combo(
      id: 'takoyaki-duo',
      categoryId: combosCategory,
      name: 'Takoyaki Duo',
      description: '8 pcs: pick 2 flavours, 4 pcs each.',
      servingLabel: '8 pcs',
      price: 14000,
      sortOrder: 0,
      visual: MenuVisual(iconKey: 'duo', colorHex: '#F29E4C'),
      slots: [
        ComboSlot(
          id: 'takoyaki',
          name: 'Takoyaki flavours',
          description: '4 pcs per flavour',
          picks: 2,
          eligibleCategoryIds: [takoyakiCategory],
        ),
      ],
    ),
    Combo(
      id: 'barkada-box',
      categoryId: combosCategory,
      name: 'Barkada Box',
      description: '16 pcs for sharing: up to 4 flavours, 4 pcs each.',
      servingLabel: '16 pcs',
      price: 27000,
      sortOrder: 1,
      visual: MenuVisual(iconKey: 'group', colorHex: '#D1495B'),
      slots: [
        ComboSlot(
          id: 'takoyaki',
          name: 'Takoyaki flavours',
          description: '4 pcs per pick. Pick the same flavour more than once if you like.',
          picks: 4,
          eligibleCategoryIds: [takoyakiCategory],
        ),
      ],
    ),
    Combo(
      id: 'merienda-combo',
      categoryId: combosCategory,
      name: 'Merienda Combo',
      description: '4 pcs takoyaki + 16oz Fruit Soda. Upgrade to 20oz for +₱5.',
      servingLabel: '4 pcs + drink',
      price: 11500,
      sortOrder: 2,
      visual: MenuVisual(iconKey: 'combo', colorHex: '#EDAE49'),
      slots: [
        ComboSlot(
          id: 'takoyaki',
          name: 'Takoyaki',
          description: '4 pcs',
          picks: 1,
          eligibleCategoryIds: [takoyakiCategory],
          sortOrder: 0,
        ),
        ComboSlot(
          id: 'drink',
          name: 'Drink',
          description: '16oz Fruit Soda, or upgrade to 20oz',
          picks: 1,
          sortOrder: 1,
          choices: [
            ComboSlotChoice(
              itemId: fruitSoda,
              optionRules: [
                ComboOptionRule(
                  groupId: sodaSizeGroup,
                  allowedChoiceIds: [size16, size20],
                  upcharges: {size20: 500},
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  /// Sample promo codes. Admin can edit or switch them off.
  static const _promos = [
    PromoCode(
      code: 'WELCOME10',
      type: PromoType.percent,
      value: 10,
      description: 'Welcome treat',
      minOrder: 10000,
    ),
    PromoCode(
      code: 'MERIENDA20',
      type: PromoType.fixed,
      value: 2000,
      description: 'Merienda time',
      minOrder: 15000,
    ),
    PromoCode(
      code: 'GRANDOPENING',
      type: PromoType.percent,
      value: 20,
      description: 'Grand opening',
      isActive: false,
    ),
  ];

  /// Placeholder hours: every day 10:00 AM – 9:00 PM Manila time.
  static final _settings = ShopSettings(
    shopName: 'G&C',
    tagline: 'Fresh takoyaki and fruit sodas, made to order.',
    openingHours: [
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        OpeningHours(weekday: day, openMinute: 10 * 60, closeMinute: 21 * 60),
    ],
  );

  static String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
