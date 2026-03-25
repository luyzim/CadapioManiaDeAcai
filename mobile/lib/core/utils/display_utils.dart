class DisplayUtils {
  static String formatCurrency(int cents) {
    final String value = (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $value';
  }

  static String formatDateTime(DateTime? value) {
    if (value == null) {
      return '--';
    }

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }

  static String formatOrderStatus(String rawStatus) {
    switch (rawStatus) {
      case 'Em_preparo':
        return 'Em preparo';
      default:
        return rawStatus;
    }
  }
}
