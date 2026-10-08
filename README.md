# G&C — Mobile Ordering App

Flutter app for **G&C**, a takoyaki and fruit soda business in the Philippines.
Customers browse the menu, customise items and combos, and order for pickup.
Admins manage the menu and orders.

- **Targets:** Android (APK) and Chrome (Flutter web preview). iOS is not set up yet.
- **Currency:** Philippine Peso (₱). All money is stored as integer centavos.
- **Timezone:** Asia/Manila (UTC+8) for opening hours, whatever the device timezone.

## Status

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | Setup, theme, models, repository interface, seed data | ✅ Done |
| 2 | Menu browsing, item options, combo selection | ✅ Done |
| 3 | Cart, checkout, simulated order tracking, admin on local data | ⏳ Next |
| 4 | Firebase setup, auth, real orders, security rules | — |
| 5 | Live tracking, Android push notifications | — |
| 6 | Admin order management on Firebase | — |
| 7 | Admin menu/pricing on Firebase, hours, pause, daily summary | — |
| 8 | Polish, accessibility, full tests, release APK | — |

Until Phase 4, everything runs on **local sample data**. You don't need Firebase or an
internet connection.

## Requirements

- Flutter (stable) with Dart 3. Check with `flutter --version`.
- **Chrome** for the web preview.
- **Android:** Android Studio with the Android SDK, plus a phone with USB debugging or an
  emulator. Check with `flutter doctor`.

## Run it

```bash
cd G-C
flutter pub get
```

### In Chrome

```bash
flutter run -d chrome
```

In a wide window, the app appears as a phone-sized frame in the middle of the page.
While it runs, press `r` to hot reload or `R` to restart.

### On an Android phone or emulator

1. Phone: turn on **Developer options → USB debugging**, plug it in, and accept the prompt.
   Emulator: start one from Android Studio (**Device Manager**), or run
   `flutter emulators --launch <id>`.
2. Run `flutter devices` and note the device id.
3. Run:

```bash
flutter run -d <device-id>
```

### Build a test APK

```bash
flutter build apk --debug
```

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. Copy it to a phone
and open it to install. You may need to allow "Install unknown apps". Phase 8 covers
signed release APKs.

## Developer options (Phases 1–3)

Open **Profile → Developer options**, or long-press the logo, to:

- switch between the **Customer** and **Admin** views, and
- **simulate no connection**, to check the loading, error and "Try again" screens.

To hide the panel, build with `--dart-define=GNC_DEV_TOOLS=false`. From Phase 4, roles
come from the signed-in account and Firestore security rules.

## Look and feel

The app is clean and white, with plenty of space and orange used only as an accent.
Every colour, radius, shadow and text style lives in
[`lib/core/theme/app_theme.dart`](lib/core/theme/app_theme.dart): `AppColors`,
`AppRadii`, `AppText`, `Gap` and `AppTheme`.

- **Colours:** set by hand. Nothing is generated (no `ColorScheme.fromSeed`) and
  surface tint is off.
  - Screens are white `#FFFFFF`. The peach gradient (`#FFF1E3` → `#FFF8F1`) is used
    only in the home header.
  - Orange `#FE9F43` marks selected states, the active nav item and small buttons.
    Prices and the greeting use `#E07B22`. Text and icons on orange are always dark
    `#2B2118`.
  - Text is `#2B2118`, descriptions `#8A7F76`, unselected chips `#F3F0ED`. Blue is kept
    for "Best value". Red is used only for real errors.
- **Cards:** white, 20px corners, one soft shadow (black at 6%, blur 20, y 6), no
  borders. Photos inside cards are inset by 12px with 14px corners.
- **Fonts** (bundled, never downloaded): DM Serif Display for the greeting and section
  titles; Poppins for everything else. Poppins has no ₱ sign, so Nunito provides
  that one character.
- **Spacing:** 20px screen padding, 24px between sections.
- **Shared components** (`lib/core/widgets/`): menu card, promo banner, chip, pill
  button, outlined "+" button, quantity stepper, summary card, section header, top
  bar, peach-header sheet layout, and the floating bottom nav.
- **Navigation:** a floating white pill bar with Home, Cart, Orders and Profile. It
  reports its height as bottom padding, so every tab pads its scrolling content and
  nothing hides behind it.
- **Pictures:** real photos where we have them, drawn illustrations otherwise (see
  *Menu photos* below). The illustrations are made with Flutter shapes in
  `lib/core/widgets/illustrations.dart`.
- **Flavour swatch colours** are matched from the flavour name in
  `lib/features/menu/flavour_palette.dart`, with a fallback palette for new flavours.

## Menu photos

Photos are data, not code:

- `MenuItem.image` and `Combo.image` are optional. Each holds an asset path or an
  `https://` URL. Firebase Storage uploads (Phase 7) will be URLs, so no screen has to
  change.
- `Category.defaultImage` applies to items in that category that have no photo of
  their own. In the seed data, Takoyaki's default is
  `assets/images/optimized/takoyaki.jpg`.
- `MenuCatalog.imageForItem` and `imageForCombo` decide what to show:
  1. the item's or combo's own photo;
  2. otherwise the category default;
  3. for a combo, the shared photo of everything it can contain, so takoyaki-only
     combos get the takoyaki photo and mixed combos (takoyaki + drink) keep their
     illustration;
  4. otherwise the illustration. This is also the fallback if a photo fails to
     load.
- **Admin:** *Menu photos* on the admin screen lets you set or reset each item's and
  combo's photo, choosing from the bundled photos.

Display rules (`MenuImage`): `BoxFit.cover`, centred, never stretched. Photos are
decoded at display size, fade in over a cream placeholder (200ms), and use Hero
animations from menu cards to detail screens.

**Adding a photo:** put the original JPEG in `assets/images/`, then run
`python tool/images/optimize_photos.py`. This writes an app-sized copy (longest side
800px, quality 80, colour profile kept) to `assets/images/optimized/`, and only that
copy is bundled with the app. The new photo then appears in the admin picker
automatically.

## Cart

The cart is held in memory for now; saving it and checkout come in Phase 3. Prices are
always recalculated from the current menu.

- **Lines:** each line has an inset photo, the chosen options ("Lemon · 20oz"), an
  orange price and a compact stepper. Swipe left or tap ✕ to remove, with **Undo**.
- **Combo suggestion** (`lib/domain/cart_suggestions.dart`): finds the combo that
  saves the most and that the cart's items can fill, following each combo's own rules
  (Merienda only accepts 16oz/20oz sodas). **Switch** turns those items into the
  combo, keeping the chosen flavours, with **Undo**.
- **Upsell:** if a menu category is missing from the cart (e.g. takoyaki but no drink),
  the cart suggests that category's first item ("Add a Fruit Soda?").
- **Recommended:** small cards with a stepper. Items with options, like Fruit Soda,
  open their builder instead.
- **Summary:** Subtotal at regular prices, Combo savings, Promo discount, then Total.
  There is no tax line because prices are final.
- **Checkout button:** disabled while the shop is closed or paused, e.g.
  "Closed · opens 10:00 AM".

### Promo codes

- **Data:** `PromoCode` (`lib/data/models/promo_code.dart`). Each code is a
  percentage (1–100) or a fixed amount in centavos, with an optional minimum order,
  an optional expiry (Manila time) and an active switch. Codes are stored upper-case
  and matched without regard to case or spaces.
- **Rules:** `PromoRules` (`lib/domain/promo_rules.dart`) checks a code and returns
  the discount in centavos, or a friendly reason it was rejected: unknown, switched
  off, expired, empty cart, or below the minimum ("₱25 to go"). Percentages round
  down. A discount never exceeds the order, and it applies after combo savings.
- **Admin:** the *Promo codes* section creates and edits codes (with form
  validation) and switches them on or off.
- **Sample codes:** `WELCOME10` (10% off, ₱100 minimum), `MERIENDA20` (₱20 off, ₱150
  minimum) and `GRANDOPENING` (switched off).
- From Phase 4, the backend recalculates discounts; the app's figure is only for
  display.

## Tests

```bash
flutter test
flutter analyze
```

- **Unit tests** (`test/core`, `test/domain`, `test/data`): money formatting, item
  prices and options, combo rules, "you save" calculations, opening hours, and the
  local repository.
- **Promo and combo rules:** `test/domain/promo_rules_test.dart` and
  `test/domain/cart_suggestions_test.dart`.
- **Widget tests** (`test/widgets`): the menu screen (chips, scroll-to-section,
  quick add, closed notice, offline retry), the drink builder, combo detail and the
  cart. They run on a 360 × 800 phone so small-screen layout problems fail the tests.

## The menu is data, not code

The UI does not hard-code anything about the menu. Categories, items, flavours,
sizes, prices, combos, badges such as "Best value", and sold-out flags all come from
the repository.
[`lib/data/seed/seed_menu.dart`](lib/data/seed/seed_menu.dart) is only the
starting data. In Phase 3 the admin screens can edit it, and in Phase 4 it is uploaded
to Firestore.

### How items are modelled

- **Item** (`MenuItem`): has a `basePrice` plus **option groups**. Each takoyaki flavour
  is its own item, priced at ₱75 for 4 pcs.
- **Option group** (`OptionGroup`): sets `minSelect`/`maxSelect` and holds **choices**.
  Each choice (`OptionChoice`) has:
  - `priceDelta`, which may be ₱0 (for example, a future premium flavour),
  - `isAvailable`, the sold-out switch,
  - an optional `badge` such as "Best value",
  - an optional `measure`/`measureUnit` such as `20` `oz`, which shows the price per oz.
- **Fruit Soda:** one item with `basePrice` ₱0 and two required groups. The Flavour
  group has 11 flavours at +₱0. The Size group has 12oz for ₱35, 16oz for ₱50 and 20oz
  for ₱55 (badge "Best value"). The Size group uses `showAbsolutePrice`, so the size
  buttons show the full price instead of "+₱50".

### How combos work (generic)

A **combo** has a fixed `price` and a list of **slots**. Each slot has:

- `picks`: how many choices the customer makes. The Duo has 2, the Barkada Box has 4.
- `eligibleCategoryIds`: every item in these categories can be picked. A new takoyaki
  flavour appears in combos automatically.
- `choices`: specific items, each with an optional `upcharge` and **option rules**. An
  option rule limits an item's options inside the combo and sets upgrade charges. For
  example, the Merienda soda allows only 16oz or 20oz, with 20oz at +₱5.
- `allowDuplicates`: whether the same item can be picked twice.

Prices are worked out automatically:

- **Combo total** = combo price + upcharges for the chosen items and options.
- **You save** = what the same picks cost bought separately − combo total. It is shown
  only when it is more than ₱0.
- On menu cards, **Save ₱X** is the smallest saving any valid selection gets.
- Sold-out items and choices cannot be picked. If a slot has nothing left, the whole
  combo shows as sold out.

The rules live in [`lib/domain/combo_pricing.dart`](lib/domain/combo_pricing.dart) and
[`lib/domain/item_pricing.dart`](lib/domain/item_pricing.dart). They are pure Dart and
fully unit-tested.

## Architecture

```
lib/
  main.dart                 App entry: locale setup, ProviderScope
  app.dart                  MaterialApp, theme, phone frame, customer/admin switch
  core/
    money.dart              Centavo formatting/parsing (₱75, ₱2.75/oz)
    clock.dart              Manila time (UTC+8), replaceable in tests
    app_config.dart         Dev-tools flag, role switch
    theme/app_theme.dart    The single theme file (warm orange/red)
    widgets/                MenuImage, loading/error/retry views, PhoneFrame
  data/
    models/                 Category, MenuItem, OptionGroup, Combo, ShopSettings, selections
    repositories/
      menu_repository.dart  The interface (local now, Firebase in Phase 4)
      providers.dart        ← the one line that picks the repository
      local/                In-memory implementation with simulated latency/offline
    seed/seed_menu.dart     Starting menu and opening hours
  domain/                   Pure business rules: prices, combos, opening hours
  features/
    menu/                   Menu, item detail, combo detail screens + providers
    admin/                  Admin home (full tools in Phase 3+)
    dev/                    Developer panel
test/                       Unit and widget tests
```

- **Layers:** UI (`features/`) → state (Riverpod providers) → repository interface
  (`data/repositories/`) → data source. Business rules in `domain/` don't depend on
  Flutter.
- **State:** Riverpod. The menu streams from the repository through `StreamProvider`s
  and is combined into one `MenuCatalog`, so the UI updates live when the admin edits
  something.
- **Switching data source:** change one line in
  [`lib/data/repositories/providers.dart`](lib/data/repositories/providers.dart).
- **Errors:** repositories throw `RepositoryException` with a message that is safe to
  show to customers. Screens use `AsyncValueView`, which shows a loading spinner, a
  friendly error with **Try again**, or the data.
- **Images:** offline placeholder tiles (an icon plus a colour from the data). An
  item can also point to a bundled asset with `visual.assetPath`.

## Firebase configuration

_Coming in Phase 4._ It will cover a step-by-step setup of the Firebase project for
Android and web, Authentication (email/password and Google), Firestore, security rules,
seeding the menu, and Cloud Messaging.
