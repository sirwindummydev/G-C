import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The shop runs on Asia/Manila time (UTC+8, no daylight saving), regardless
/// of the timezone of the phone or browser.
abstract interface class Clock {
  /// Current time expressed as Manila wall-clock time.
  ///
  /// The returned [DateTime] is UTC-flagged but its fields (hour, weekday...)
  /// are Manila local values. Use it for display and opening-hours checks.
  DateTime nowInManila();
}

class SystemClock implements Clock {
  const SystemClock();

  static const manilaOffset = Duration(hours: 8);

  @override
  DateTime nowInManila() => DateTime.now().toUtc().add(manilaOffset);
}

/// A clock frozen at a given Manila time, for tests.
class FixedClock implements Clock {
  FixedClock(this.manilaTime);

  DateTime manilaTime;

  @override
  DateTime nowInManila() => manilaTime;
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());
