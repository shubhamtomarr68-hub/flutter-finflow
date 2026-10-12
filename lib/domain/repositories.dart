import 'package:flutter/material.dart';

import 'models.dart';

abstract class FinanceRepository {
  Future<LedgerSnapshot> load();

  Future<void> save(LedgerSnapshot snapshot);
}

abstract class PreferenceStore {
  Future<ThemeMode> readTheme();

  Future<void> writeTheme(ThemeMode mode);
}
