import 'package:finflow/app.dart';
import 'package:finflow/core/format/money_format.dart';
import 'package:finflow/data/memory_stores.dart';
import 'package:finflow/data/sample_ledger.dart';
import 'package:finflow/domain/models.dart';
import 'package:finflow/domain/money_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(
    WidgetTester tester,
    MemoryFinanceRepository repository,
  ) {
    return tester.pumpWidget(
      FinFlowApp(
        financeRepository: repository,
        preferenceStore: MemoryPreferenceStore(),
        clock: DateTime.now,
      ),
    );
  }

  testWidgets('shows the sample balance and a transaction', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final now = DateTime.now();
    final snapshot = sampleLedger(now);
    await pumpApp(tester, MemoryFinanceRepository(snapshot));
    await tester.pumpAndSettle();

    final balance = MoneySummary.of(snapshot.entries).balance;
    expect(find.text(formatInr(balance)), findsOneWidget);
    expect(find.textContaining('No bank or broker'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Salary'), findsWidgets);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title.'), findsOneWidget);
  });

  testWidgets('failed load offers retry', (tester) async {
    final repository = MemoryFinanceRepository(
      LedgerSnapshot.empty,
      failLoad: true,
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load your ledger.'), findsWidgets);
    repository.failLoad = false;
    repository.snapshot = sampleLedger(DateTime(2026, 10, 12));
    await tester.tap(find.byKey(const Key('retry-load')).first);
    await tester.pumpAndSettle();
    expect(find.text('All-time balance'), findsOneWidget);
  });

  testWidgets('theme toggle switches to dark', (tester) async {
    await pumpApp(
      tester,
      MemoryFinanceRepository(sampleLedger(DateTime(2026, 10, 12))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch theme'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
