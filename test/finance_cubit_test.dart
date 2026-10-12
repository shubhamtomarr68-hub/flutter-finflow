import 'dart:io';

import 'package:finflow/data/file_stores.dart';
import 'package:finflow/data/memory_stores.dart';
import 'package:finflow/data/sample_ledger.dart';
import 'package:finflow/domain/models.dart';
import 'package:finflow/presentation/finance_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 12);

  FinanceCubit cubitFor(MemoryFinanceRepository repository) {
    final cubit = FinanceCubit(repository: repository, clock: () => now);
    addTearDown(cubit.close);
    return cubit;
  }

  test('load failure keeps the ledger off screen', () async {
    final cubit = cubitFor(
      MemoryFinanceRepository(LedgerSnapshot.empty, failLoad: true),
    );
    await cubit.load();
    expect(cubit.state.status, LoadStatus.failure);
    expect(cubit.state.errorMessage, 'Could not load your ledger.');
  });

  test('save, filter, budget, and delete update storage', () async {
    final repository = MemoryFinanceRepository(sampleLedger(now));
    final cubit = cubitFor(repository);
    await cubit.load();

    expect(
      await cubit.saveEntry(
        title: ' ',
        amountText: '10',
        direction: MoneyDirection.expense,
        category: 'Food',
        occurredOn: now,
        note: '',
      ),
      'Enter a title.',
    );

    expect(
      await cubit.saveEntry(
        title: 'Coffee',
        amountText: '120',
        direction: MoneyDirection.expense,
        category: 'Food',
        occurredOn: now,
        note: 'Latte',
      ),
      isNull,
    );
    expect(
      repository.snapshot.entries.any((entry) => entry.title == 'Coffee'),
      isTrue,
    );

    cubit.setQuery('latte');
    final visible = LedgerQuery.apply(
      entries: cubit.state.entries,
      query: cubit.state.query,
      category: cubit.state.categoryFilter,
    );
    expect(visible.single.title, 'Coffee');

    expect(await cubit.setBudget('Food', '9000'), isNull);
    expect(
      cubit.state.budgets
          .firstWhere((budget) => budget.category == 'Food')
          .monthlyLimit,
      9000,
    );

    final id = cubit.state.entries
        .firstWhere((entry) => entry.title == 'Coffee')
        .id;
    expect(await cubit.deleteEntry(id), isNull);
    expect(repository.snapshot.entries.any((entry) => entry.id == id), isFalse);
  });

  test('failed save does not drop the current ledger', () async {
    final repository = MemoryFinanceRepository(sampleLedger(now));
    final cubit = cubitFor(repository);
    await cubit.load();
    final before = cubit.state.entries.length;
    repository.failSave = true;
    expect(
      await cubit.saveEntry(
        title: 'Coffee',
        amountText: '120',
        direction: MoneyDirection.expense,
        category: 'Food',
        occurredOn: now,
        note: '',
      ),
      'Could not save changes.',
    );
    expect(cubit.state.entries, hasLength(before));
    expect(cubit.state.status, LoadStatus.ready);
  });

  test('file repository round-trips and rejects a corrupt file', () async {
    final directory = await Directory.systemTemp.createTemp('finflow');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/ledger.json');
    final repository = FileFinanceRepository(file: file, clock: () => now);

    final created = await repository.load();
    expect(created.entries, isNotEmpty);
    expect(file.existsSync(), isTrue);

    await repository.save(LedgerSnapshot.empty);
    expect((await repository.load()).entries, isEmpty);

    await file.writeAsString('{"version": 2}');
    expect(repository.load(), throwsA(isA<FormatException>()));
  });
}
