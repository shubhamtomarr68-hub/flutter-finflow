import 'models.dart';

class MoneySummary {
  const MoneySummary({required this.income, required this.expenses});

  final double income;
  final double expenses;

  double get balance => income - expenses;

  /// Zero when there is no income, so the UI never shows NaN.
  double? get savingsRatio => income == 0 ? null : balance / income;

  static MoneySummary of(Iterable<LedgerEntry> entries) {
    var income = 0.0;
    var expenses = 0.0;
    for (final entry in entries) {
      if (entry.direction == MoneyDirection.income) {
        income += entry.amount;
      } else {
        expenses += entry.amount;
      }
    }
    return MoneySummary(income: income, expenses: expenses);
  }

  static MoneySummary forMonth(Iterable<LedgerEntry> entries, DateTime month) {
    return of(entries.where((entry) => _sameMonth(entry.occurredOn, month)));
  }

  static Map<String, double> spendingByCategory(
    Iterable<LedgerEntry> entries,
    DateTime month,
  ) {
    final totals = <String, double>{};
    for (final entry in entries) {
      if (entry.direction != MoneyDirection.expense) {
        continue;
      }
      if (!_sameMonth(entry.occurredOn, month)) {
        continue;
      }
      totals[entry.category] = (totals[entry.category] ?? 0) + entry.amount;
    }
    return totals;
  }

  static double spentInCategory(
    Iterable<LedgerEntry> entries,
    DateTime month,
    String category,
  ) {
    return spendingByCategory(entries, month)[category] ?? 0;
  }
}

bool _sameMonth(DateTime date, DateTime month) {
  return date.year == month.year && date.month == month.month;
}
