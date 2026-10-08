import 'package:intl/intl.dart';

import '../data/models/shop_settings.dart';

enum ShopState { open, closed, paused }

/// Whether the shop takes orders right now, and when it next opens.
class ShopStatus {
  const ShopStatus({
    required this.state,
    this.nextOpening,
    this.closesAt,
    this.message,
  });

  final ShopState state;

  /// Manila wall-clock time of the next opening, when closed.
  final DateTime? nextOpening;

  /// Manila wall-clock time the current window ends, when open.
  final DateTime? closesAt;

  /// Admin's pause message, when paused.
  final String? message;

  bool get canOrder => state == ShopState.open;
}

abstract final class ShopHours {
  static const _minutesPerDay = 24 * 60;

  /// Works out the shop status at [manilaNow] (see `Clock.nowInManila`).
  static ShopStatus statusAt(ShopSettings settings, DateTime manilaNow) {
    if (settings.isPaused) {
      return ShopStatus(
        state: ShopState.paused,
        message: settings.pauseMessage,
      );
    }
    final today = _midnight(manilaNow);
    // Look at yesterday too, for windows that run past midnight.
    for (var offset = -1; offset <= 0; offset++) {
      final day = today.add(Duration(days: offset));
      for (final window in _windowsOn(settings, day.weekday)) {
        final opens = day.add(Duration(minutes: window.openMinute));
        final closes = day.add(Duration(minutes: window.closeMinute));
        if (!manilaNow.isBefore(opens) && manilaNow.isBefore(closes)) {
          return ShopStatus(state: ShopState.open, closesAt: closes);
        }
      }
    }
    return ShopStatus(
      state: ShopState.closed,
      nextOpening: nextOpening(settings, manilaNow),
    );
  }

  /// The next opening time after [manilaNow] within a week, or null if the
  /// shop has no opening hours at all.
  static DateTime? nextOpening(ShopSettings settings, DateTime manilaNow) {
    final today = _midnight(manilaNow);
    for (var offset = 0; offset <= 7; offset++) {
      final day = today.add(Duration(days: offset));
      final windows = _windowsOn(settings, day.weekday).toList()
        ..sort((a, b) => a.openMinute.compareTo(b.openMinute));
      for (final window in windows) {
        final opens = day.add(Duration(minutes: window.openMinute));
        if (opens.isAfter(manilaNow)) return opens;
      }
    }
    return null;
  }

  /// "Opens today at 10:00 AM", "Opens tomorrow at 10:00 AM",
  /// "Opens Mon at 10:00 AM".
  static String describeOpening(DateTime opening, DateTime manilaNow) {
    final dayDiff = _midnight(opening).difference(_midnight(manilaNow)).inDays;
    final time = formatTime(opening);
    return switch (dayDiff) {
      0 => 'Opens today at $time',
      1 => 'Opens tomorrow at $time',
      _ => 'Opens ${DateFormat.E().format(opening)} at $time',
    };
  }

  static String formatTime(DateTime time) => DateFormat('h:mm a').format(time);

  /// "10:00 AM – 9:00 PM" for one window.
  static String formatWindow(OpeningHours window) {
    final base = DateTime.utc(2024, 1, 1);
    final open = base.add(Duration(minutes: window.openMinute));
    final close = base.add(
      Duration(minutes: window.closeMinute % _minutesPerDay),
    );
    return '${formatTime(open)} – ${formatTime(close)}';
  }

  static Iterable<OpeningHours> _windowsOn(
    ShopSettings settings,
    int weekday,
  ) => settings.openingHours.where(
    (w) => w.weekday == weekday && w.closeMinute > w.openMinute,
  );

  static DateTime _midnight(DateTime t) => DateTime.utc(t.year, t.month, t.day);
}
