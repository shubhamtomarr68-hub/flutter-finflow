import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/repositories.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._store) : super(ThemeMode.system);

  final PreferenceStore _store;

  Future<void> load() async {
    try {
      emit(await _store.readTheme());
    } catch (_) {
      emit(ThemeMode.system);
    }
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(next);
    try {
      await _store.writeTheme(next);
    } catch (_) {
      // The selection still applies for this session if the file cannot be written.
    }
  }
}
