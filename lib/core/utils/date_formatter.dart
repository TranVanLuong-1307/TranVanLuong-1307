import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('HH:mm dd/MM/yyyy');

  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);

  static String formatDateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24 && dateTime.day == now.day) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 2) {
      return 'Hôm qua ${_timeFormat.format(dateTime)}';
    } else {
      return _dateTimeFormat.format(dateTime);
    }
  }
}
