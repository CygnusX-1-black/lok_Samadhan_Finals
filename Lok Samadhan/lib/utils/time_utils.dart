import 'package:intl/intl.dart';

/// Standard Timezone-aware Date & Time formatting utility for Lok Samadhan.
/// Displays all complaint registration timestamps, audit trail steps,
/// and progress updates in Asia/Kolkata (IST, UTC+05:30).
class TimeUtils {
  /// Standard IANA timezone identifier for Indian Standard Time (IST)
  static const String kolkataTimeZone = 'Asia/Kolkata';

  /// Formats any [DateTime] or ISO-8601 string to a consistent Kolkata (IST)
  /// display string.
  ///
  /// Example:
  /// Input:  `2026-10-10T06:22:01.067+00:00`
  /// Output: `10 Oct 2026, 11:52 AM`
  static String formatKolkataTime(dynamic timestamp) {
    if (timestamp == null) return 'Time unavailable';

    DateTime? date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is String) {
      final trimmed = timestamp.trim();
      if (trimmed.isEmpty) return 'Time unavailable';
      date = DateTime.tryParse(trimmed);
    }

    if (date == null) return 'Invalid date';

    // Normalize to UTC first to prevent double-conversion regardless of device local timezone
    final utc = date.toUtc();
    // Indian Standard Time (Asia/Kolkata) is permanently UTC+05:30 (no DST)
    final kolkataTime = utc.add(const Duration(hours: 5, minutes: 30));

    return DateFormat('d MMM yyyy, h:mm a').format(kolkataTime);
  }
}
