import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/sample_ledger.dart';
import '../domain/entry_validator.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

enum LoadStatus { loading, ready, failure }

class FinanceState extends Equatable {
  const FinanceState({
    required this.status,
    required this.entries,
    required this.budgets,
    required this.holdings,
    required this.query,
    required this.categoryFilter,
    required this.visibleYear,
    required this.visibleMonth,
    required this.errorMessage,
  });

  factory FinanceState.initial(DateTime now) {
    return FinanceState(
      status: LoadStatus.loading,
      entries: const [],
      budgets: const [],
      holdings: const [],
      query: '',
      categoryFilter: null,
      visibleYear: now.year,
      visibleMonth: now.month,
      errorMessage: null,
    );
  }

  final LoadStatus status;
  final List<LedgerEntry> entries;
  final List<CategoryBudget> budgets;
  final List<Holding> holdings;
  final String query;
  final String? categoryFilter;
  final int visibleYear;
  final int visibleMonth;
  final String? errorMessage;

  DateTime get visibleMonthDate => DateTime(visibleYear, visibleMonth, 1);

  FinanceState copyWith({
    LoadStatus? status,
    List<LedgerEntry>? entries,
    List<CategoryBudget>? budgets,
    List<Holding>? holdings,
    String? query,
    String? categoryFilter,
    bool clearCategory = false,
    int? visibleYear,
    int? visibleMonth,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FinanceState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      budgets: budgets ?? this.budgets,
      holdings: holdings ?? this.holdings,
      query: query ?? this.query,
      categoryFilter: clearCategory
          ? null
          : (categoryFilter ?? this.categoryFilter),
      visibleYear: visibleYear ?? this.visibleYear,
      visibleMonth: visibleMonth ?? this.visibleMonth,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    budgets,
    holdings,
    query,
    categoryFilter,
    visibleYear,
    visibleMonth,
    errorMessage,
  ];
}

class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit({required this.repository, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(FinanceState.initial((clock ?? DateTime.now)()));

  final FinanceRepository repository;
  final DateTime Function() _clock;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    try {
      final snapshot = await repository.load();
      emit(
        state.copyWith(
          status: LoadStatus.ready,
          entries: List.unmodifiable(snapshot.entries),
          budgets: List.unmodifiable(snapshot.budgets),
          holdings: List.unmodifiable(snapshot.holdings),
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: LoadStatus.failure,
          errorMessage: 'Could not load your ledger.',
        ),
      );
    }
  }

  void setQuery(String query) => emit(state.copyWith(query: query));

  void setCategory(String? category) {
    emit(
      state.copyWith(clearCategory: category == null, categoryFilter: category),
    );
  }

  void shiftMonth(int delta) {
    final next = DateTime(state.visibleYear, state.visibleMonth + delta, 1);
    emit(state.copyWith(visibleYear: next.year, visibleMonth: next.month));
  }

  Future<String?> saveEntry({
    String? id,
    required String title,
    required String amountText,
    required MoneyDirection direction,
    required String category,
    required DateTime occurredOn,
    required String note,
  }) async {
    final error = EntryValidator.validate(
      title: title,
      amountText: amountText,
      category: category,
    );
    if (error != null) {
      return error;
    }
    final amount = double.parse(amountText.trim());
    final draft = LedgerEntry(
      id: id ?? _nextId(state.entries),
      title: title.trim(),
      amount: amount,
      direction: direction,
      category: category,
      occurredOn: occurredOn,
      note: note.trim(),
    );
    final entries = [...state.entries];
    if (id == null) {
      entries.add(draft);
    } else {
      final index = entries.indexWhere((entry) => entry.id == id);
      if (index == -1) {
        return 'That transaction is no longer on this device.';
      }
      entries[index] = draft;
    }
    return _persist(entries: entries);
  }

  Future<String?> deleteEntry(String id) {
    final entries = state.entries.where((entry) => entry.id != id).toList();
    return _persist(entries: entries);
  }

  Future<String?> setBudget(String category, String limitText) async {
    final error = EntryValidator.validateBudget(limitText);
    if (error != null) {
      return error;
    }
    final limit = double.parse(limitText.trim());
    final budgets = [...state.budgets];
    final index = budgets.indexWhere((budget) => budget.category == category);
    if (index == -1) {
      budgets.add(CategoryBudget(category: category, monthlyLimit: limit));
    } else {
      budgets[index] = budgets[index].copyWith(monthlyLimit: limit);
    }
    return _persist(budgets: budgets);
  }

  Future<String?> restoreSample() async {
    final sample = sampleLedger(_clock());
    final error = await _persist(
      entries: sample.entries,
      budgets: sample.budgets,
      holdings: sample.holdings,
    );
    if (error != null) {
      return 'Could not restore sample data.';
    }
    emit(state.copyWith(query: '', clearCategory: true));
    return null;
  }

  Future<String?> _persist({
    List<LedgerEntry>? entries,
    List<CategoryBudget>? budgets,
    List<Holding>? holdings,
  }) async {
    final snapshot = LedgerSnapshot(
      entries: entries ?? state.entries,
      budgets: budgets ?? state.budgets,
      holdings: holdings ?? state.holdings,
    );
    try {
      await repository.save(snapshot);
    } catch (_) {
      return 'Could not save changes.';
    }
    emit(
      state.copyWith(
        status: LoadStatus.ready,
        entries: List.unmodifiable(snapshot.entries),
        budgets: List.unmodifiable(snapshot.budgets),
        holdings: List.unmodifiable(snapshot.holdings),
        clearError: true,
      ),
    );
    return null;
  }

  String _nextId(List<LedgerEntry> entries) {
    var max = 0;
    for (final entry in entries) {
      final match = RegExp(r'^txn-(\d+)$').firstMatch(entry.id);
      if (match == null) {
        continue;
      }
      final value = int.parse(match.group(1)!);
      if (value > max) {
        max = value;
      }
    }
    return 'txn-${max + 1}';
  }
}
