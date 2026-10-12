import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/format/money_format.dart';
import '../domain/entry_validator.dart';
import '../domain/models.dart';
import '../domain/money_summary.dart';
import 'finance_cubit.dart';
import 'overview_page.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LedgerGate(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const MonthSwitcher(),
            const SizedBox(height: 8),
            Text(
              'Limits apply to expenses in the selected month.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (state.budgets.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text('No budgets yet.'),
              ),
            for (final budget in state.budgets) ...[
              _BudgetCard(budget: budget, state: state),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.state});

  final CategoryBudget budget;
  final FinanceState state;

  @override
  Widget build(BuildContext context) {
    final spent = MoneySummary.spentInCategory(
      state.entries,
      state.visibleMonthDate,
      budget.category,
    );
    final ratio = budget.monthlyLimit == 0
        ? 0.0
        : (spent / budget.monthlyLimit).clamp(0.0, 1.0);
    final over = spent > budget.monthlyLimit;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    budget.category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit ${budget.category} budget',
                  onPressed: () => _editLimit(context, budget),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            Text(
              '${formatInr(spent)} of ${formatInr(budget.monthlyLimit)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Semantics(
              label:
                  '${budget.category} budget ${(ratio * 100).round()} percent used',
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: over ? scheme.error : scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            if (over) ...[
              const SizedBox(height: 8),
              Text(
                '${formatInr(spent - budget.monthlyLimit)} over the limit',
                style: TextStyle(color: scheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editLimit(BuildContext context, CategoryBudget budget) async {
    final cubit = context.read<FinanceCubit>();
    final controller = TextEditingController(
      text: budget.monthlyLimit.round().toString(),
    );
    final error = await showDialog<String>(
      context: context,
      builder: (context) {
        var message = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${budget.category} limit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monthly limit',
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(message),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final local = EntryValidator.validateBudget(
                      controller.text,
                    );
                    if (local != null) {
                      setState(() => message = local);
                      return;
                    }
                    final saveError = await cubit.setBudget(
                      budget.category,
                      controller.text,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    if (saveError != null) {
                      setState(() => message = saveError);
                      return;
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
