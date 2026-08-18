import 'package:equatable/equatable.dart';
import 'package:hrms_demo/data/models/user_model.dart';

abstract class EmployeeGroupsEvent extends Equatable {
  const EmployeeGroupsEvent();

  @override
  List<Object?> get props => [];
}

class LoadGroupsData extends EmployeeGroupsEvent {
  final String? locale;

  const LoadGroupsData({this.locale});

  @override
  List<Object?> get props => [locale];
}

class SelectGroup extends EmployeeGroupsEvent {
  final String group;

  const SelectGroup(this.group);

  @override
  List<Object?> get props => [group];
}

class AddMemberToGroup extends EmployeeGroupsEvent {
  final UserModel employee;
  final String group;

  const AddMemberToGroup({required this.employee, required this.group});

  @override
  List<Object?> get props => [employee, group];
}

class RemoveMemberFromGroup extends EmployeeGroupsEvent {
  final int employeeId;
  final String group;

  const RemoveMemberFromGroup({required this.employeeId, required this.group});

  @override
  List<Object?> get props => [employeeId, group];
}
