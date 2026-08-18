import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:equatable/equatable.dart';

base class BaseState extends Equatable {
  const BaseState({this.status = Status.initial, this.failure});

  final Status status;
  final Failure? failure;

  @override
  List<Object?> get props => [status, failure];
}
