import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  String get timeLabel => DateFormat('h:mm a').format(this);
  String get shortDate => DateFormat('MMM d').format(this);
}
