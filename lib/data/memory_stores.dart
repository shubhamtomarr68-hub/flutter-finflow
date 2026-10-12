import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/repositories.dart';

class MemoryFinanceRepository implements FinanceRepository {
  MemoryFinanceRepository(
    this.snapshot, {
    this.failLoad = false,
    this.failSave = false,
  });

  LedgerSnapshot snapshot;
  bool failLoad;
  bool failSave;

  @override
  Future<LedgerSnapshot> load() async {
    if (failLoad) {
      throw StateError('storage unavailable');
    }
    return snapshot;
  }

  @override
  Future<void> save(LedgerSnapshot next) async {
    if (failSave) {
      throw StateError('storage unavailable');
    }
    snapshot = next;
  }
}

class MemoryPreferenceStore implements PreferenceStore {
  MemoryPreferenceStore({this.mode = ThemeMode.system});

  ThemeMode mode;

  @override
  Future<ThemeMode> readTheme() async => mode;

  @override
  Future<void> writeTheme(ThemeMode next) async {
    mode = next;
  }
}
