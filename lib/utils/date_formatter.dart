class DateFormatter {
  static const List<String> _bulan = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  static const List<String> _hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  static String format(DateTime? date) {
    if (date == null) return '-';
    return '${date.day} ${_bulan[date.month]} ${date.year}';
  }

  static String formatShort(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String formatWithDay(DateTime? date) {
    if (date == null) return '-';
    final hari = _hari[date.weekday - 1];
    return '$hari, ${date.day} ${_bulan[date.month]} ${date.year}';
  }

  static String monthYear(DateTime date) {
    return '${_bulan[date.month]} ${date.year}';
  }

  static String dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
