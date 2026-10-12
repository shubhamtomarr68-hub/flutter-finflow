import 'package:flutter/material.dart';

import '../core/format/money_format.dart';
import '../domain/models.dart';
import 'overview_page.dart';

class InvestmentsPage extends StatelessWidget {
  const InvestmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LedgerGate(
      builder: (context, state) {
        final value = state.holdings.fold<double>(
          0,
          (sum, holding) => sum + holding.marketValue,
        );
        final cost = state.holdings.fold<double>(
          0,
          (sum, holding) => sum + holding.costBasis,
        );
        final gain = value - cost;
        final scheme = Theme.of(context).colorScheme;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Sample prices stored with the ledger. Quotes are not live.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio value',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatInr(value),
                      key: const Key('portfolio-value'),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unrealized ${gain >= 0 ? '+' : ''}${formatInr(gain)} on cost ${formatInr(cost)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (state.holdings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text('No holdings in the sample portfolio.'),
              ),
            for (final holding in state.holdings) ...[
              _HoldingTile(holding: holding),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _HoldingTile extends StatelessWidget {
  const _HoldingTile({required this.holding});

  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gain = holding.unrealizedGain;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text('${holding.symbol} · ${holding.name}'),
        subtitle: Text(
          '${holding.quantity.toStringAsFixed(0)} units · avg ${formatInr(holding.averageCost)} · last ${formatInr(holding.lastPrice)}',
        ),
        trailing: Text(
          '${gain >= 0 ? '+' : ''}${formatInr(gain)}',
          style: TextStyle(
            color: gain >= 0 ? scheme.primary : scheme.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
