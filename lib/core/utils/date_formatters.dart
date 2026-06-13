import 'package:intl/intl.dart';

class DateFormatters {
  const DateFormatters._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  static final _dayFormat = DateFormat('EEEE, dd MMM yyyy');

  static String formatDate(DateTime date) => _dateFormat.format(date.toLocal());
  static String formatTime(DateTime date) => _timeFormat.format(date.toLocal());
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date.toLocal());
  static String formatDay(DateTime date) => _dayFormat.format(date.toLocal());

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes}m';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year && localA.month == localB.month && localA.day == localB.day;
  }

  static DateTime startOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime endOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day, 23, 59, 59);
  }
}
