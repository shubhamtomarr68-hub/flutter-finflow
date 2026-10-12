import 'package:finflow/domain/entry_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects empty, zero, and non-numeric amounts', () {
    expect(
      EntryValidator.validate(title: ' ', amountText: '10', category: 'Food'),
      'Enter a title.',
    );
    expect(
      EntryValidator.validate(
        title: 'Coffee',
        amountText: '0',
        category: 'Food',
      ),
      'Amount must be greater than zero.',
    );
    expect(
      EntryValidator.validate(
        title: 'Coffee',
        amountText: 'abc',
        category: 'Food',
      ),
      'Enter a valid amount.',
    );
    expect(
      EntryValidator.validate(
        title: 'Coffee',
        amountText: '120',
        category: 'Food',
      ),
      isNull,
    );
  });

  test('rejects a non-positive budget', () {
    expect(
      EntryValidator.validateBudget('-5'),
      'Limit must be greater than zero.',
    );
    expect(EntryValidator.validateBudget('8000'), isNull);
  });
}
