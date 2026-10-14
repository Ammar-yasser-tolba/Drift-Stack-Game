/// All "today" logic in the game uses the UTC date (Section 13).
class UtcDate {
  UtcDate._();

  /// Overridable clock (useful for tests).
  static DateTime Function() clock = () => DateTime.now().toUtc();

  static const List<String> _months = <String>[
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  static String keyOf(DateTime d) {
    final DateTime u = d.toUtc();
    return '${u.year.toString().padLeft(4, '0')}'
        '${u.month.toString().padLeft(2, '0')}'
        '${u.day.toString().padLeft(2, '0')}';
  }

  /// yyyymmdd of today (UTC).
  static String get todayKey => keyOf(clock());

  /// yyyymmdd of yesterday (UTC).
  static String get yesterdayKey {
    final DateTime n = clock().toUtc();
    return keyOf(DateTime.utc(n.year, n.month, n.day).subtract(const Duration(days: 1)));
  }

  /// Daily seed = the UTC date as a number, e.g. 20261028.
  static int get todaySeed => int.parse(todayKey);

  /// `28 OCT`
  static String shortLabel([String? key]) {
    final String k = key ?? todayKey;
    final int month = int.parse(k.substring(4, 6));
    final int day = int.parse(k.substring(6, 8));
    return '$day ${_months[month - 1]}';
  }

  /// `28 OCT 2026`
  static String fullLabel([String? key]) {
    final String k = key ?? todayKey;
    return '${shortLabel(k)} ${k.substring(0, 4)}';
  }
}
