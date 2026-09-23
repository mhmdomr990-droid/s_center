import 'package:intl/intl.dart';

final NumberFormat _amountFormat = NumberFormat('#,##0.00', 'en_US');

String formatAmount(dynamic value) {
  if (value == null) return '0.00';
  final text = value.toString();
  final number = double.tryParse(text);
  if (number == null) return text;
  return _amountFormat.format(number);
}

String formatArabicDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('d MMMM yyyy - HH:mm', 'ar').format(date);
}
