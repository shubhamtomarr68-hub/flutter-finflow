const monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String monthLabel(int year, int month) => '${monthNames[month - 1]} $year';

/// Indian grouping: 85000 becomes ₹85,000.
String formatInr(double value) {
  final negative = value < 0;
  final digits = value.abs().round().toString();
  final chars = digits.split('').reversed.toList();
  final grouped = <String>[];
  for (var index = 0; index < chars.length; index++) {
    if (index == 3 || (index > 3 && (index - 3).isEven)) {
      grouped.add(',');
    }
    grouped.add(chars[index]);
  }
  final amount = grouped.reversed.join();
  return '${negative ? '-' : ''}₹$amount';
}

String formatPercent(double ratio) {
  final percent = (ratio * 100).round();
  return '$percent%';
}
