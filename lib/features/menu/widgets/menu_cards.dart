import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/menu_image.dart';
import '../../../data/models/combo.dart';
import '../../../data/models/menu_item.dart';
import '../../../data/models/menu_visual.dart';
import '../../../domain/combo_pricing.dart';
import '../../../domain/item_pricing.dart';

/// Hero tag linking an item's picture to its detail screen. Items can show
/// in more than one place on the home screen (Popular and the grid), so the
/// tag includes where it was tapped.
Object itemHeroTag(String itemId, String origin) =>
    'item-image-$origin-$itemId';

/// Hero tag for a combo picture (banner or grid).
Object comboHeroTag(String comboId, String origin) =>
    'combo-image-$origin-$comboId';

String itemPriceText(MenuItem item) => ItemPricing.hasVariablePrice(item)
    ? 'from ${Money.format(ItemPricing.fromPrice(item))}'
    : Money.format(ItemPricing.fromPrice(item));

/// "11 flavours", from the item's main choice group (data-driven).
String? choiceCountText(MenuItem item) {
  for (final group in item.sortedOptionGroups) {
    if (group.isRequired && !group.choices.any((c) => c.hasMeasure)) {
      final n = group.choices.length;
      final noun = group.name.toLowerCase();
      return '$n ${n == 1 ? noun : '${noun}s'}';
    }
  }
  return null;
}

/// Height a [MenuTileCard] needs at a given width, allowing for the
/// reader's text size: 12px padding, square photo, name, subtitle, and the
/// price/"+" row.
double menuTileExtent(BuildContext context, double width) {
  final scaler = MediaQuery.textScalerOf(context);
  return width + 10 + scaler.scale(21) + scaler.scale(19) + 6 + 36 + 12;
}

/// The one menu card: photo inset with 12px padding and its own rounded
/// corners, name, a short subtitle, the price in orange and an outlined
/// "+" button. Used for Popular (fixed width) and the menu grids.
class MenuTileCard extends StatelessWidget {
  const MenuTileCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.priceText,
    required this.visual,
    required this.onTap,
    required this.addLabel,
    this.image,
    this.heroTag,
    this.badge,
    this.soldOut = false,
    this.onAdd,
    this.semanticLabel,
  });

  /// Card for a menu item. Items without options are added in one tap;
  /// for items with options, "+" opens the builder.
  factory MenuTileCard.item({
    Key? key,
    required MenuItem item,
    required String? image,
    required String heroOrigin,
    required VoidCallback onTap,
    required VoidCallback? onQuickAdd,
  }) {
    final soldOut = !item.isOrderable;
    final price = itemPriceText(item);
    final subtitle = item.hasOptions
        ? (choiceCountText(item) ?? item.description)
        : item.description;
    return MenuTileCard(
      key: key,
      name: item.name,
      subtitle: subtitle,
      priceText: price,
      visual: item.visual,
      image: image,
      heroTag: itemHeroTag(item.id, heroOrigin),
      badge: item.servingLabel,
      soldOut: soldOut,
      onTap: onTap,
      onAdd: soldOut ? null : (item.hasOptions ? onTap : onQuickAdd),
      addLabel: item.hasOptions
          ? 'Choose options for ${item.name}'
          : 'Add one ${item.name} to cart',
      semanticLabel: [
        item.name,
        price,
        ?item.servingLabel,
        if (soldOut) 'Sold out',
        subtitle,
      ].join(', '),
    );
  }

  /// Card for a combo; "+" opens the combo so the customer can pick.
  factory MenuTileCard.combo({
    Key? key,
    required Combo combo,
    required ComboPricing pricing,
    required String? image,
    required String heroOrigin,
    required VoidCallback onTap,
  }) {
    final orderable = pricing.isOrderable(combo);
    final saved = pricing.guaranteedSavings(combo);
    final price = Money.format(pricing.fromPrice(combo));
    final save = saved == null ? null : 'Save ${Money.format(saved)}';
    return MenuTileCard(
      key: key,
      name: combo.name,
      subtitle: combo.servingLabel ?? combo.description,
      priceText: price,
      visual: combo.visual,
      image: image,
      heroTag: comboHeroTag(combo.id, heroOrigin),
      badge: orderable ? save : null,
      soldOut: !orderable,
      onTap: onTap,
      onAdd: orderable ? onTap : null,
      addLabel: 'Choose ${combo.name}',
      semanticLabel: [
        combo.name,
        price,
        ?combo.servingLabel,
        if (!orderable) 'Sold out' else ?save,
      ].join(', '),
    );
  }

  final String name;
  final String subtitle;
  final String priceText;
  final MenuVisual visual;
  final String? image;
  final Object? heroTag;

  /// Frosted label on the photo, e.g. "4 pcs" or "Save ₱10".
  final String? badge;
  final bool soldOut;
  final VoidCallback onTap;

  /// Null hides the "+" button.
  final VoidCallback? onAdd;
  final String addLabel;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final card = AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MenuImage(
                  visual: visual,
                  image: image,
                  borderRadius: AppRadii.image,
                  dimmed: soldOut,
                  heroTag: heroTag,
                ),
                if (soldOut || badge != null)
                  Positioned(
                    left: Gap.s,
                    top: Gap.s,
                    child: FrostedPill(text: soldOut ? 'Sold out' : badge!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _NameAndSubtitle(name: name, subtitle: subtitle),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  priceText,
                  style: soldOut
                      ? AppText.price().copyWith(color: AppColors.textMuted)
                      : AppText.price(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Room for the "+" button, which sits outside the card's
              // own tap area (see the Stack below).
              if (onAdd != null) const SizedBox(width: 36, height: 36),
            ],
          ),
        ],
      ),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            button: true,
            label: semanticLabel ?? name,
            excludeSemantics: true,
            child: card,
          ),
        ),
        if (onAdd != null)
          Positioned(
            right: 12,
            bottom: 12,
            child: RoundAddButton(
              semanticLabel: addLabel,
              onPressed: onAdd,
              size: 36,
              outlined: true,
            ),
          ),
      ],
    );
  }
}

/// The tile's name and subtitle in the same two lines of space: a name too
/// long for one line (e.g. "Merienda Combo") gets both lines and the
/// subtitle is dropped, so every card keeps the same height.
class _NameAndSubtitle extends StatelessWidget {
  const _NameAndSubtitle({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final nameStyle = AppText.itemName();
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: name, style: nameStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final wraps = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: nameStyle,
              maxLines: wraps ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!wraps)
              Text(
                subtitle,
                style: AppText.description(size: 12.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        );
      },
    );
  }
}

/// Semi-transparent white pill with a blurred backdrop, for labels on
/// photos ("4 pcs", "Save ₱30"). Dark text keeps it readable.
class FrostedPill extends StatelessWidget {
  const FrostedPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: Pill.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            color: Colors.white.withValues(alpha: 0.8),
            child: Text(
              text,
              style: poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One promo slide's content.
class PromoSlide {
  const PromoSlide({
    required this.combo,
    required this.image,
    required this.badge,
    required this.priceText,
    required this.soldOut,
  });

  final Combo combo;
  final String? image;
  final String? badge;
  final String priceText;
  final bool soldOut;
}

/// Full-width photo banners that advance every 5 seconds and can be
/// swiped, with an animated page indicator (active dot = orange pill).
class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({
    super.key,
    required this.slides,
    required this.onOpen,
    this.height = 180,
    this.interval = const Duration(seconds: 5),
  });

  final List<PromoSlide> slides;
  final void Function(Combo combo, Object heroTag) onOpen;
  final double height;
  final Duration interval;

  static const heroOrigin = 'banner';

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(PromoBannerCarousel old) {
    super.didUpdateWidget(old);
    if (_page >= widget.slides.length) _page = 0;
    if (old.slides.length != widget.slides.length) _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.slides.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % widget.slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollStartNotification>(
            // A swipe restarts the 5-second timer.
            onNotification: (n) {
              if (n.dragDetails != null) _restartTimer();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.screen),
                child: _BannerCard(
                  key: ValueKey('banner-${slides[i].combo.id}'),
                  slide: slides[i],
                  onTap: () => widget.onOpen(
                    slides[i].combo,
                    comboHeroTag(
                      slides[i].combo.id,
                      PromoBannerCarousel.heroOrigin,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: Gap.m),
          Semantics(
            label: 'Promotion ${_page + 1} of ${slides.length}',
            excludeSemantics: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.primary
                          : AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({super.key, required this.slide, required this.onTap});

  final PromoSlide slide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final combo = slide.combo;
    return Semantics(
      button: true,
      label: [
        combo.name,
        slide.priceText,
        if (slide.soldOut) 'Sold out' else ?slide.badge,
      ].join(', '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: AppColors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MenuImage(
                visual: combo.visual,
                image: slide.image,
                borderRadius: 0,
                dimmed: slide.soldOut,
                heroTag: comboHeroTag(combo.id, PromoBannerCarousel.heroOrigin),
              ),
              // Soft scrim so the white text stays readable on the photo.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.4, 1],
                    colors: [Color(0x00000000), Color(0x99000000)],
                  ),
                ),
              ),
              if (slide.soldOut || slide.badge != null)
                Positioned(
                  left: Gap.l,
                  top: Gap.l,
                  child: FrostedPill(
                    text: slide.soldOut ? 'Sold out' : slide.badge!,
                  ),
                ),
              Positioned(
                left: Gap.l,
                right: Gap.l,
                bottom: Gap.l,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            combo.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: serif(fontSize: 22, color: Colors.white),
                          ),
                          if (combo.servingLabel != null)
                            Text(
                              combo.servingLabel!,
                              style: poppins(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Gap.s),
                    Text(
                      slide.priceText,
                      style: poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
