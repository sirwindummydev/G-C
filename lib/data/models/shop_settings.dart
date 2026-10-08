import 'map_reader.dart';

/// Opening window for one weekday, in minutes after midnight Manila time.
/// `closeMinute` may be past 1440 to run past midnight (e.g. 1500 = 1:00 AM).
class OpeningHours {
  const OpeningHours({
    required this.weekday,
    required this.openMinute,
    required this.closeMinute,
  });

  /// [DateTime.monday] (1) to [DateTime.sunday] (7).
  final int weekday;
  final int openMinute;
  final int closeMinute;

  factory OpeningHours.fromMap(Map<String, dynamic> map) => OpeningHours(
    weekday: map.integer('weekday', DateTime.monday),
    openMinute: map.integer('openMinute'),
    closeMinute: map.integer('closeMinute'),
  );

  Map<String, dynamic> toMap() => {
    'weekday': weekday,
    'openMinute': openMinute,
    'closeMinute': closeMinute,
  };
}

/// Shop-wide settings, editable by admin.
class ShopSettings {
  const ShopSettings({
    required this.shopName,
    this.tagline = '',
    this.openingHours = const [],
    this.isPaused = false,
    this.pauseMessage,
  });

  final String shopName;
  final String tagline;

  /// Days without an entry are closed days.
  final List<OpeningHours> openingHours;

  /// Manual "pause ordering" switch for busy times.
  final bool isPaused;
  final String? pauseMessage;

  factory ShopSettings.fromMap(Map<String, dynamic> map) => ShopSettings(
    shopName: map.str('shopName', 'G&C'),
    tagline: map.str('tagline'),
    openingHours: map.maps('openingHours').map(OpeningHours.fromMap).toList(),
    isPaused: map.boolean('isPaused'),
    pauseMessage: map.strOrNull('pauseMessage'),
  );

  Map<String, dynamic> toMap() => {
    'shopName': shopName,
    'tagline': tagline,
    'openingHours': openingHours.map((h) => h.toMap()).toList(),
    'isPaused': isPaused,
    if (pauseMessage != null) 'pauseMessage': pauseMessage,
  };

  ShopSettings copyWith({
    String? shopName,
    String? tagline,
    List<OpeningHours>? openingHours,
    bool? isPaused,
    String? Function()? pauseMessage,
  }) => ShopSettings(
    shopName: shopName ?? this.shopName,
    tagline: tagline ?? this.tagline,
    openingHours: openingHours ?? this.openingHours,
    isPaused: isPaused ?? this.isPaused,
    pauseMessage: pauseMessage != null ? pauseMessage() : this.pauseMessage,
  );
}
