import 'package:flutter_test/flutter_test.dart';
import 'package:gnc_app/data/models/shop_settings.dart';
import 'package:gnc_app/domain/shop_hours.dart';

void main() {
  // Every day 10:00–21:00 Manila time.
  final daily = ShopSettings(
    shopName: 'G&C',
    openingHours: [
      for (var d = DateTime.monday; d <= DateTime.sunday; d++)
        OpeningHours(weekday: d, openMinute: 600, closeMinute: 1260),
    ],
  );

  // 2026-10-07 is a Wednesday.
  DateTime at(int day, int hour, [int minute = 0]) =>
      DateTime.utc(2026, 10, day, hour, minute);

  test('open during opening hours', () {
    final status = ShopHours.statusAt(daily, at(7, 14));
    expect(status.state, ShopState.open);
    expect(status.canOrder, isTrue);
    expect(status.closesAt, at(7, 21));
  });

  test('opening minute is open, closing minute is closed', () {
    expect(ShopHours.statusAt(daily, at(7, 10)).state, ShopState.open);
    expect(ShopHours.statusAt(daily, at(7, 21)).state, ShopState.closed);
  });

  test('before opening: opens today', () {
    final now = at(7, 8);
    final status = ShopHours.statusAt(daily, now);
    expect(status.state, ShopState.closed);
    expect(status.nextOpening, at(7, 10));
    expect(
      ShopHours.describeOpening(status.nextOpening!, now),
      'Opens today at 10:00 AM',
    );
  });

  test('after closing: opens tomorrow', () {
    final now = at(7, 22);
    final status = ShopHours.statusAt(daily, now);
    expect(status.nextOpening, at(8, 10));
    expect(
      ShopHours.describeOpening(status.nextOpening!, now),
      'Opens tomorrow at 10:00 AM',
    );
  });

  test('skips closed days', () {
    final weekdaysOnly = daily.copyWith(
      openingHours: daily.openingHours
          .where((h) => h.weekday <= DateTime.friday)
          .toList(),
    );
    final fridayNight = at(9, 22);
    final next = ShopHours.nextOpening(weekdaysOnly, fridayNight);
    expect(next, at(12, 10)); // Monday
    expect(
      ShopHours.describeOpening(next!, fridayNight),
      'Opens Mon at 10:00 AM',
    );
  });

  test('pause overrides opening hours', () {
    final paused = daily.copyWith(
      isPaused: true,
      pauseMessage: () => 'Back in 30 mins',
    );
    final status = ShopHours.statusAt(paused, at(7, 14));
    expect(status.state, ShopState.paused);
    expect(status.canOrder, isFalse);
    expect(status.message, 'Back in 30 mins');
  });

  test('windows past midnight stay open into the next day', () {
    final lateNight = ShopSettings(
      shopName: 'G&C',
      openingHours: const [
        OpeningHours(
          weekday: DateTime.wednesday,
          openMinute: 18 * 60,
          closeMinute: 26 * 60,
        ),
      ],
    );
    expect(ShopHours.statusAt(lateNight, at(8, 1)).state, ShopState.open);
    expect(ShopHours.statusAt(lateNight, at(8, 2, 30)).state, ShopState.closed);
  });

  test('no opening hours means closed with no next opening', () {
    const none = ShopSettings(shopName: 'G&C');
    final status = ShopHours.statusAt(none, at(7, 12));
    expect(status.state, ShopState.closed);
    expect(status.nextOpening, isNull);
  });

  test('formats a window', () {
    expect(
      ShopHours.formatWindow(
        const OpeningHours(weekday: 1, openMinute: 600, closeMinute: 1260),
      ),
      '10:00 AM – 9:00 PM',
    );
  });
}
