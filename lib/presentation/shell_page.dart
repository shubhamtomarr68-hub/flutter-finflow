import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'activity_page.dart';
import 'add_entry_sheet.dart';
import 'budgets_page.dart';
import 'finance_cubit.dart';
import 'investments_page.dart';
import 'overview_page.dart';
import 'theme_cubit.dart';
import 'widgets/state_views.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  static const _titles = ['Overview', 'Activity', 'Budgets', 'Investments'];

  @override
  Widget build(BuildContext context) {
    final status = context.watch<FinanceCubit>().state.status;
    final ready = status == LoadStatus.ready;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Switch theme',
            onPressed: () => context.read<ThemeCubit>().toggle(),
            icon: const Icon(Icons.brightness_6),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'restore') {
                _confirmRestore();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'restore',
                child: Text('Restore sample data'),
              ),
            ],
          ),
        ],
      ),
      body: switch (status) {
        LoadStatus.loading => const LoadingView(),
        LoadStatus.failure => ErrorView(
          message:
              context.read<FinanceCubit>().state.errorMessage ??
              'Could not load your ledger.',
          onRetry: () => context.read<FinanceCubit>().load(),
        ),
        LoadStatus.ready => IndexedStack(
          index: _index,
          children: const [
            OverviewPage(),
            ActivityPage(),
            BudgetsPage(),
            InvestmentsPage(),
          ],
        ),
      },
      floatingActionButton: _index == 1 && ready
          ? FloatingActionButton.extended(
              onPressed: () => showAddEntrySheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Investments',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestore() async {
    final cubit = context.read<FinanceCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore sample data?'),
          content: const Text(
            'This replaces the ledger on this device with the original sample. It does not contact a bank.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    final error = await cubit.restoreSample();
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
