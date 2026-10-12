import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/repositories.dart';
import 'sample_ledger.dart';

/// JSON file on disk. Chosen over a database because the ledger is small and
/// the same class can be tested with a temp file, without a platform plugin.
class FileFinanceRepository implements FinanceRepository {
  FileFinanceRepository({required this.file, required this.clock});

  final File file;
  final DateTime Function() clock;

  @override
  Future<LedgerSnapshot> load() async {
    if (!await file.exists()) {
      final sample = sampleLedger(clock());
      await save(sample);
      return sample;
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Ledger file is not a JSON object');
    }
    return LedgerSnapshot.fromJson(decoded);
  }

  @override
  Future<void> save(LedgerSnapshot snapshot) async {
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(snapshot.toJson()));
  }
}

class FilePreferenceStore implements PreferenceStore {
  FilePreferenceStore({required this.file});

  final File file;

  @override
  Future<ThemeMode> readTheme() async {
    if (!await file.exists()) {
      return ThemeMode.system;
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Preference file is not a JSON object');
    }
    final name = decoded['theme'];
    if (name is! String) {
      throw const FormatException('Missing theme');
    }
    return ThemeMode.values.byName(name);
  }

  @override
  Future<void> writeTheme(ThemeMode mode) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'theme': mode.name}));
  }
}
