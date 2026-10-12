import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

import 'data/file_stores.dart';
import 'domain/repositories.dart';

/// Composition root for the running app.
///
/// Widgets do not call GetIt. Tests build [FinFlowApp] with fakes and skip this.
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationDocumentsDirectory();
  getIt.registerSingleton<FinanceRepository>(
    FileFinanceRepository(
      file: File('${directory.path}/finflow_ledger.json'),
      clock: DateTime.now,
    ),
  );
  getIt.registerSingleton<PreferenceStore>(
    FilePreferenceStore(
      file: File('${directory.path}/finflow_preferences.json'),
    ),
  );
}
