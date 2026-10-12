import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/format/money_format.dart';
import '../domain/models.dart';
import 'add_entry_sheet.dart';
import 'finance_cubit.dart';
import 'overview_page.dart';
import 'widgets/state_views.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LedgerGate(
      builder: (context, state) {
        final entries = LedgerQuery.apply(
          entries: state.entries,
          query: state.query,
          category: state.categoryFilter,
        );
        final categories = {
          ...state.entries.map((entry) => entry.category),
        }.toList();

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _SearchField(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: state.categoryFilter == null,
                      onSelected: (_) =>
                          context.read<FinanceCubit>().setCategory(null),
                    ),
                  ),
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category),
                        selected: state.categoryFilter == category,
                        onSelected: (_) =>
                            context.read<FinanceCubit>().setCategory(category),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const EmptyView(
                      message: 'No transactions match this search.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _EntryTile(entry: entry);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FinanceCubit, FinanceState>(
      listenWhen: (previous, next) =>
          previous.query != next.query && next.query.isEmpty,
      listener: (context, state) => _controller.clear(),
      child: TextField(
        key: const Key('activity-search'),
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Search title, note, or category',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: context.read<FinanceCubit>().setQuery,
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final income = entry.direction == MoneyDirection.income;
    final amount = '${income ? '+' : '-'}${formatInr(entry.amount)}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(entry.title),
      subtitle: Text(
        [
          entry.category,
          '${entry.occurredOn.day} ${monthNames[entry.occurredOn.month - 1]}',
          if (entry.note.isNotEmpty) entry.note,
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: income ? scheme.primary : scheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            tooltip: 'Edit ${entry.title}',
            onPressed: () => showAddEntrySheet(context, existing: entry),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete ${entry.title}',
            onPressed: () => _confirmDelete(context, entry),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, LedgerEntry entry) async {
    final cubit = context.read<FinanceCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: Text('“${entry.title}” will be removed from this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    final error = await cubit.deleteEntry(entry.id);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
