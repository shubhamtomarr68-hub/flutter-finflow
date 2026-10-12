import '../domain/models.dart';

/// Builds a deterministic ledger around [now] so the current month has data.
///
/// Amounts and prices are sample figures. No bank, broker, or market feed is used.
LedgerSnapshot sampleLedger(DateTime now) {
  final current = DateTime(now.year, now.month, 1);
  final previous = DateTime(now.year, now.month - 1, 1);
  final older = DateTime(now.year, now.month - 2, 1);

  return LedgerSnapshot(
    entries: [
      _income('txn-1', 'Salary', 85000, 'Salary', current, 1),
      _expense('txn-2', 'Rent', 22000, 'Rent', current, 2),
      _expense('txn-3', 'Groceries', 6400, 'Food', current, 4),
      _expense('txn-4', 'Metro card', 2100, 'Transport', current, 6),
      _expense('txn-5', 'Dinner', 1800, 'Food', current, 11),
      _income('txn-6', 'Freelance invoice', 12000, 'Freelance', current, 15),
      _expense('txn-7', 'Pharmacy', 900, 'Health', current, 18),
      _expense('txn-8', 'Weekend groceries', 920, 'Food', current, 20),
      _income('txn-9', 'Salary', 85000, 'Salary', previous, 1),
      _expense('txn-10', 'Rent', 22000, 'Rent', previous, 2),
      _expense('txn-11', 'Groceries', 7200, 'Food', previous, 8),
      _expense('txn-12', 'New headphones', 4500, 'Shopping', previous, 14),
      _expense('txn-13', 'Clinic visit', 1800, 'Health', previous, 21),
      _income('txn-14', 'Salary', 82000, 'Salary', older, 1),
      _expense('txn-15', 'Rent', 22000, 'Rent', older, 2),
      _expense('txn-16', 'Cab rides', 2600, 'Transport', older, 9),
      _expense('txn-17', 'Books', 1500, 'Shopping', older, 16),
    ],
    budgets: const [
      CategoryBudget(category: 'Food', monthlyLimit: 8000),
      CategoryBudget(category: 'Rent', monthlyLimit: 22000),
      CategoryBudget(category: 'Transport', monthlyLimit: 3000),
      CategoryBudget(category: 'Shopping', monthlyLimit: 4000),
      CategoryBudget(category: 'Health', monthlyLimit: 2500),
    ],
    holdings: const [
      Holding(
        symbol: 'NIFTYBEES',
        name: 'Nifty 50 ETF sample',
        quantity: 12,
        averageCost: 240,
        lastPrice: 268,
      ),
      Holding(
        symbol: 'GOLDBEES',
        name: 'Gold ETF sample',
        quantity: 8,
        averageCost: 62,
        lastPrice: 71,
      ),
      Holding(
        symbol: 'HDFCBANK',
        name: 'Sample bank stock',
        quantity: 6,
        averageCost: 1540,
        lastPrice: 1490,
      ),
      Holding(
        symbol: 'LIQUID',
        name: 'Sample liquid fund',
        quantity: 40,
        averageCost: 1000,
        lastPrice: 1042,
      ),
    ],
  );
}

LedgerEntry _income(
  String id,
  String title,
  double amount,
  String category,
  DateTime month,
  int day,
) {
  return LedgerEntry(
    id: id,
    title: title,
    amount: amount,
    direction: MoneyDirection.income,
    category: category,
    occurredOn: DateTime(month.year, month.month, day),
  );
}

LedgerEntry _expense(
  String id,
  String title,
  double amount,
  String category,
  DateTime month,
  int day,
) {
  return LedgerEntry(
    id: id,
    title: title,
    amount: amount,
    direction: MoneyDirection.expense,
    category: category,
    occurredOn: DateTime(month.year, month.month, day),
  );
}
