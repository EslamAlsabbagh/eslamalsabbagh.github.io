import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs every bloc transition and error to the debug console. Dev builds only.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    log('${bloc.runtimeType}: $transition', name: 'bloc');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    // Cubits have no transitions; log their changes too.
    if (bloc is! Bloc) log('${bloc.runtimeType}: $change', name: 'bloc');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('${bloc.runtimeType} error', name: 'bloc', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
