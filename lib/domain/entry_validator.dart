class EntryValidator {
  static const maxAmount = 100000000.0;

  static String? validate({
    required String title,
    required String amountText,
    required String category,
  }) {
    if (title.trim().isEmpty) {
      return 'Enter a title.';
    }
    if (title.trim().length > 80) {
      return 'Title is too long.';
    }
    final amount = double.tryParse(amountText.trim());
    if (amount == null) {
      return 'Enter a valid amount.';
    }
    if (amount <= 0) {
      return 'Amount must be greater than zero.';
    }
    if (amount > maxAmount) {
      return 'Amount is too large.';
    }
    if (category.trim().isEmpty) {
      return 'Choose a category.';
    }
    return null;
  }

  static String? validateBudget(String limitText) {
    final limit = double.tryParse(limitText.trim());
    if (limit == null) {
      return 'Enter a valid limit.';
    }
    if (limit <= 0) {
      return 'Limit must be greater than zero.';
    }
    if (limit > maxAmount) {
      return 'Limit is too large.';
    }
    return null;
  }
}
