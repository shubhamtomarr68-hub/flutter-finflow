import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/finflow_theme.dart';
import 'domain/repositories.dart';
import 'presentation/finance_cubit.dart';
import 'presentation/shell_page.dart';
import 'presentation/theme_cubit.dart';

class FinFlowApp extends StatelessWidget {
  const FinFlowApp({
    super.key,
    required this.financeRepository,
    required this.preferenceStore,
    this.clock,
  });

  final FinanceRepository financeRepository;
  final PreferenceStore preferenceStore;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(preferenceStore)..load()),
        BlocProvider(
          create: (_) =>
              FinanceCubit(repository: financeRepository, clock: clock)..load(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return MaterialApp(
            title: 'FinFlow',
            debugShowCheckedModeBanner: false,
            theme: buildFinFlowTheme(Brightness.light),
            darkTheme: buildFinFlowTheme(Brightness.dark),
            themeMode: mode,
            home: const ShellPage(),
          );
        },
      ),
    );
  }
}
