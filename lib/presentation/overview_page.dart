import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/format/money_format.dart';
import '../domain/money_summary.dart';
import 'finance_cubit.dart';
import 'widgets/spending_chart.dart';
import 'widgets/state_views.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LedgerGate(
      builder: (context, state) {
        final month = state.visibleMonthDate;
        final monthSummary = MoneySummary.forMonth(state.entries, month);
        final allTime = MoneySummary.of(state.entries);
        final spending = MoneySummary.spendingByCategory(state.entries, month);
        final scheme = Theme.of(context).colorScheme;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Sample ledger stored on this device. No bank or broker is connected.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All-time balance',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatInr(allTime.balance),
                    key: const Key('all-time-balance'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Income ${formatInr(allTime.income)} · Expenses ${formatInr(allTime.expenses)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const MonthSwitcher(),
            const SizedBox(height: 12),
            _StatWrap(
              children: [
                _StatTile(
                  label: 'Income',
                  value: formatInr(monthSummary.income),
                  color: scheme.primary,
                ),
                _StatTile(
                  label: 'Expenses',
                  value: formatInr(monthSummary.expenses),
                  color: scheme.error,
                ),
                _StatTile(
                  label: 'Left this month',
                  value: formatInr(monthSummary.balance),
                  detail: monthSummary.savingsRatio == null
                      ? 'No income yet'
                      : '${formatPercent(monthSummary.savingsRatio!)} of income left',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending by category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SpendingChart(totals: spending),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceCubit>().state;
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: () => context.read<FinanceCubit>().shiftMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            monthLabel(state.visibleYear, state.visibleMonth),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: () => context.read<FinanceCubit>().shiftMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class LedgerGate extends StatelessWidget {
  const LedgerGate({super.key, required this.builder});

  final Widget Function(BuildContext context, FinanceState state) builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceCubit, FinanceState>(
      builder: (context, state) {
        switch (state.status) {
          case LoadStatus.loading:
            return const LoadingView();
          case LoadStatus.failure:
            return ErrorView(
              message: state.errorMessage ?? 'Could not load your ledger.',
              onRetry: () => context.read<FinanceCubit>().load(),
            );
          case LoadStatus.ready:
            return builder(context, state);
        }
      },
    );
  }
}

class _StatWrap extends StatelessWidget {
  const _StatWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(child: children[index]),
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.detail,
    this.color,
  });

  final String label;
  final String value;
  final String? detail;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Semantics(
        label: '$label $value',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(detail!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
