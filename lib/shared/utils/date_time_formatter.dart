import 'package:intl/intl.dart';

class DateTimeFormatter {
  const DateTimeFormatter._();

  static final DateFormat _dayHeader = DateFormat('EEEE, MMM d');
  static final DateFormat _journalDate = DateFormat('MMM d, yyyy • h:mm a');

  static String dayHeader(DateTime date) => _dayHeader.format(date);

  static String journalDate(DateTime date) => _journalDate.format(date);

  static String hiveDayKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }
}
