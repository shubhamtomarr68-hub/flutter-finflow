import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/models.dart';
import 'finance_cubit.dart';

Future<void> showAddEntrySheet(BuildContext context, {LedgerEntry? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => AddEntrySheet(existing: existing),
  );
}

class AddEntrySheet extends StatefulWidget {
  const AddEntrySheet({super.key, this.existing});

  final LedgerEntry? existing;

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final TextEditingController _amount = TextEditingController(
    text: widget.existing == null ? '' : widget.existing!.amount.toString(),
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  late MoneyDirection _direction =
      widget.existing?.direction ?? MoneyDirection.expense;
  late String _category = widget.existing?.category ?? expenseCategories.first;
  late DateTime _date = widget.existing?.occurredOn ?? DateTime.now();
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  List<String> get _categories => _direction == MoneyDirection.expense
      ? expenseCategories
      : incomeCategories;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Add transaction' : 'Edit transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<MoneyDirection>(
              segments: const [
                ButtonSegment(
                  value: MoneyDirection.expense,
                  label: Text('Expense'),
                ),
                ButtonSegment(
                  value: MoneyDirection.income,
                  label: Text('Income'),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (selection) {
                setState(() {
                  _direction = selection.first;
                  if (!_categories.contains(_category)) {
                    _category = _categories.first;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('entry-title'),
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('entry-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('$_direction-$_category'),
              initialValue: _categories.contains(_category)
                  ? _category
                  : _categories.first,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in _categories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
              child: Text('Date ${_date.day}/${_date.month}/${_date.year}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('entry-save'),
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final cubit = context.read<FinanceCubit>();
    final error = await cubit.saveEntry(
      id: widget.existing?.id,
      title: _title.text,
      amountText: _amount.text,
      direction: _direction,
      category: _category,
      occurredOn: DateTime(_date.year, _date.month, _date.day),
      note: _note.text,
    );
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }
}
