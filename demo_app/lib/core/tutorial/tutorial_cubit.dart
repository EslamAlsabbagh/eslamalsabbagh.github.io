import 'package:flutter_bloc/flutter_bloc.dart';

class TutorialCubit extends Cubit<bool> {
  TutorialCubit() : super(false);

  void start() => emit(true);
  void finish() => emit(false);
}
