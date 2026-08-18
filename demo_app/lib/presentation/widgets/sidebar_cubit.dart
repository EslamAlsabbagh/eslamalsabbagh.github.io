import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarCubit extends Cubit<bool> {
  SidebarCubit() : super(false); // collapsed by default

  void expand() {
    if (!state) emit(true);
  }

  void collapse() {
    if (state) emit(false);
  }

  void toggle() => emit(!state);
  void reset() => emit(false); // Reset to collapsed state
}
