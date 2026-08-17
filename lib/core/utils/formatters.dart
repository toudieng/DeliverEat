import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _cfa = NumberFormat.decimalPattern('fr_FR');

  static String currency(int amount) => '${_cfa.format(amount)} CFA';

  static String time(DateTime? dt) {
    if (dt == null) return '--:--';
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String dateTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} • ${time(dt)}';
  }
}
