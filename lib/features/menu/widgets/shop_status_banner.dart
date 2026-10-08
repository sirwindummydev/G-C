import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/clock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/shop_hours.dart';
import '../menu_providers.dart';

/// Short "when do we open" text: "today 10:00 AM", "tomorrow 10:00 AM",
/// "Mon 10:00 AM".
String openingWhen(DateTime opening, DateTime manilaNow) {
  DateTime day(DateTime t) => DateTime.utc(t.year, t.month, t.day);
  final diff = day(opening).difference(day(manilaNow)).inDays;
  final time = ShopHours.formatTime(opening);
  return switch (diff) {
    0 => 'today $time',
    1 => 'tomorrow $time',
    _ => '${DateFormat.E().format(opening)} $time',
  };
}

/// Small shop-status pill for the home header.
///
/// Open: a green dot, "Open now · until 9:00 PM".
/// Closed or paused: amber, with a clock or pause icon. These are
/// information, not errors, so they never use error colours.
class ShopStatusPill extends ConsumerWidget {
  const ShopStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(shopStatusProvider).value;
    if (status == null) return const SizedBox(height: 28);
    final now =
        ref.watch(manilaNowProvider).value ??
        ref.watch(clockProvider).nowInManila();

    final open = status.state == ShopState.open;
    final String text;
    if (open) {
      text = status.closesAt == null
          ? 'Open now'
          : 'Open now · until ${ShopHours.formatTime(status.closesAt!)}';
    } else if (status.state == ShopState.paused) {
      text = 'Ordering paused · ${status.message ?? 'back soon'}';
    } else {
      text = status.nextOpening == null
          ? 'Closed · check back soon'
          : 'Closed · Opens ${openingWhen(status.nextOpening!, now)}';
    }

    final Widget leading = open
        ? Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.open,
              shape: BoxShape.circle,
            ),
          )
        : Icon(
            status.state == ShopState.paused
                ? Icons.pause_circle_outline_rounded
                : Icons.schedule_rounded,
            size: 14,
            color: AppColors.primaryDark,
          );

    return Semantics(
      container: true,
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 5),
        decoration: BoxDecoration(
          color: open ? Colors.white.withValues(alpha: 0.75) : AppColors.notice,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
