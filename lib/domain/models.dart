import 'package:equatable/equatable.dart';

enum MoneyDirection { income, expense }

/// Fixed category lists keep filters and the entry form in sync.
const expenseCategories = <String>[
  'Food',
  'Rent',
  'Transport',
  'Shopping',
  'Health',
  'Other',
];

const incomeCategories = <String>['Salary', 'Freelance', 'Other'];

class LedgerEntry extends Equatable {
  const LedgerEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.direction,
    required this.category,
    required this.occurredOn,
    this.note = '',
  });

  final String id;
  final String title;

  /// Always stored as a positive number. [direction] decides the sign.
  final double amount;
  final MoneyDirection direction;
  final String category;
  final DateTime occurredOn;
  final String note;

  LedgerEntry copyWith({
    String? title,
    double? amount,
    MoneyDirection? direction,
    String? category,
    DateTime? occurredOn,
    String? note,
  }) {
    return LedgerEntry(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      category: category ?? this.category,
      occurredOn: occurredOn ?? this.occurredOn,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'direction': direction.name,
    'category': category,
    'occurredOn': _formatDate(occurredOn),
    'note': note,
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: _requireString(json, 'id'),
      title: _requireString(json, 'title'),
      amount: _requireDouble(json, 'amount'),
      direction: MoneyDirection.values.byName(
        _requireString(json, 'direction'),
      ),
      category: _requireString(json, 'category'),
      occurredOn: _parseDate(_requireString(json, 'occurredOn')),
      note: json['note'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    direction,
    category,
    occurredOn,
    note,
  ];
}

class CategoryBudget extends Equatable {
  const CategoryBudget({required this.category, required this.monthlyLimit});

  final String category;
  final double monthlyLimit;

  CategoryBudget copyWith({double? monthlyLimit}) {
    return CategoryBudget(
      category: category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'monthlyLimit': monthlyLimit,
  };

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    return CategoryBudget(
      category: _requireString(json, 'category'),
      monthlyLimit: _requireDouble(json, 'monthlyLimit'),
    );
  }

  @override
  List<Object?> get props => [category, monthlyLimit];
}

class Holding extends Equatable {
  const Holding({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.averageCost,
    required this.lastPrice,
  });

  final String symbol;
  final String name;
  final double quantity;
  final double averageCost;

  /// Sample price stored with the ledger. This is not a live market quote.
  final double lastPrice;

  double get marketValue => quantity * lastPrice;
  double get costBasis => quantity * averageCost;
  double get unrealizedGain => marketValue - costBasis;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'quantity': quantity,
    'averageCost': averageCost,
    'lastPrice': lastPrice,
  };

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      symbol: _requireString(json, 'symbol'),
      name: _requireString(json, 'name'),
      quantity: _requireDouble(json, 'quantity'),
      averageCost: _requireDouble(json, 'averageCost'),
      lastPrice: _requireDouble(json, 'lastPrice'),
    );
  }

  @override
  List<Object?> get props => [symbol, name, quantity, averageCost, lastPrice];
}

class LedgerSnapshot extends Equatable {
  const LedgerSnapshot({
    required this.entries,
    required this.budgets,
    required this.holdings,
  });

  static const empty = LedgerSnapshot(entries: [], budgets: [], holdings: []);

  final List<LedgerEntry> entries;
  final List<CategoryBudget> budgets;
  final List<Holding> holdings;

  LedgerSnapshot copyWith({
    List<LedgerEntry>? entries,
    List<CategoryBudget>? budgets,
    List<Holding>? holdings,
  }) {
    return LedgerSnapshot(
      entries: entries ?? this.entries,
      budgets: budgets ?? this.budgets,
      holdings: holdings ?? this.holdings,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'budgets': budgets.map((budget) => budget.toJson()).toList(),
    'holdings': holdings.map((holding) => holding.toJson()).toList(),
  };

  factory LedgerSnapshot.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != 1) {
      throw FormatException('Unsupported ledger version: $version');
    }
    return LedgerSnapshot(
      entries: _mapList(json, 'entries', LedgerEntry.fromJson),
      budgets: _mapList(json, 'budgets', CategoryBudget.fromJson),
      holdings: _mapList(json, 'holdings', Holding.fromJson),
    );
  }

  @override
  List<Object?> get props => [entries, budgets, holdings];
}

class LedgerQuery {
  static List<LedgerEntry> apply({
    required List<LedgerEntry> entries,
    required String query,
    required String? category,
  }) {
    final needle = query.trim().toLowerCase();
    final result = entries.where((entry) {
      if (category != null && entry.category != category) {
        return false;
      }
      if (needle.isEmpty) {
        return true;
      }
      return entry.title.toLowerCase().contains(needle) ||
          entry.category.toLowerCase().contains(needle) ||
          entry.note.toLowerCase().contains(needle);
    }).toList();
    result.sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
    return result;
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime _parseDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw FormatException('Invalid date: $value');
  }
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing $key');
  }
  return value;
}

double _requireDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('Missing $key');
  }
  return value.toDouble();
}

List<T> _mapList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic> json) decode,
) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Missing $key');
  }
  return value.map((item) {
    if (item is! Map<String, dynamic>) {
      throw FormatException('Invalid $key item');
    }
    return decode(item);
  }).toList();
}
