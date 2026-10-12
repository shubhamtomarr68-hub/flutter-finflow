import 'package:flutter/material.dart';

import 'app.dart';
import 'domain/repositories.dart';
import 'injection.dart';

Future<void> main() async {
  await configureDependencies();
  runApp(
    FinFlowApp(
      financeRepository: getIt<FinanceRepository>(),
      preferenceStore: getIt<PreferenceStore>(),
    ),
  );
}
