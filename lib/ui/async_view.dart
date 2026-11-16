import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/failure.dart';
import 'error_view.dart';
import 'loading_view.dart';

Widget nwbAsyncView<T>(
  AsyncValue<T> state, {
  required Widget Function(T value) data,
  required VoidCallback onRetry,
  Widget Function(Object error)? error,
  Widget loading = const LoadingView(),
}) {
  if (state.hasValue) return data(state.requireValue);
  if (state.error case final Object failure) {
    return error?.call(failure) ?? ErrorView(error: failure, onRetry: onRetry);
  }
  return loading;
}

/// Liegt ein Verbindungsfehler vor, **obwohl** schon Inhalte dastehen? Genau
/// dann gehört das Offline-Band darüber (Ü-05) — bei einem Serverfehler ohne
/// Inhalt übernimmt stattdessen die Fehlerfläche.
///
/// Stand bisher als dieselbe Bedingung in fünf Bildschirmen; hier ist sie
/// einmal formuliert.
bool isOfflineWithContent(AsyncValue<Object?> state) =>
    state.hasValue && state.hasError && state.error is ConnectionFailure;
