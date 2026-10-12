import 'package:finflow/core/format/money_format.dart';
import 'package:finflow/domain/models.dart';
import 'package:finflow/domain/money_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final month = DateTime(2026, 10, 1);
  final entries = [
    LedgerEntry(
      id: 'txn-1',
      title: 'Salary',
      amount: 1000,
      direction: MoneyDirection.income,
      category: 'Salary',
      occurredOn: month,
    ),
    LedgerEntry(
      id: 'txn-2',
      title: 'Groceries',
      amount: 200,
      direction: MoneyDirection.expense,
      category: 'Food',
      occurredOn: month,
    ),
    LedgerEntry(
      id: 'txn-3',
      title: 'Old rent',
      amount: 500,
      direction: MoneyDirection.expense,
      category: 'Rent',
      occurredOn: DateTime(2026, 9, 2),
    ),
  ];

  test('month summary ignores other months and avoids NaN', () {
    final summary = MoneySummary.forMonth(entries, month);
    expect(summary.income, 1000);
    expect(summary.expenses, 200);
    expect(summary.balance, 800);
    expect(summary.savingsRatio, 0.8);

    final empty = MoneySummary.forMonth(const [], month);
    expect(empty.savingsRatio, isNull);
  });

  test('spending map only includes expenses in that month', () {
    expect(MoneySummary.spendingByCategory(entries, month), {'Food': 200});
  });

  test('formats rupees with Indian grouping', () {
    expect(formatInr(85000), '₹85,000');
    expect(formatInr(1200), '₹1,200');
    expect(formatInr(-40), '-₹40');
  });

  test('query matches title, note, and category', () {
    final withNote = [entries.first.copyWith(note: 'October payroll')];
    expect(
      LedgerQuery.apply(entries: withNote, query: 'payroll', category: null),
      hasLength(1),
    );
    expect(
      LedgerQuery.apply(
        entries: entries,
        query: '',
        category: 'Food',
      ).single.title,
      'Groceries',
    );
  });
}
