import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/presentation/employee_groups/bloc/employee_groups_event.dart';
import 'package:hrms_demo/presentation/employee_groups/bloc/employee_groups_state.dart';

class EmployeeGroupsBloc extends Bloc<EmployeeGroupsEvent, EmployeeGroupsState> {
  final UsersRepo _repo;

  EmployeeGroupsBloc({required UsersRepo repo}) : _repo = repo, super(const EmployeeGroupsState()) {
    on<LoadGroupsData>(_onLoadGroupsData);
    on<SelectGroup>(_onSelectGroup);
    on<AddMemberToGroup>(_onAddMemberToGroup);
    on<RemoveMemberFromGroup>(_onRemoveMemberFromGroup);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Derives a groupsData map from a flat list of employees by checking each
  /// employee's groups field against each managed group string.
  Map<String, List<UserModel>> _deriveGroupsData(List<UserModel> employees) {
    final result = <String, List<UserModel>>{};
    for (final group in kManagedGroups) {
      result[group] = employees.where((e) => e.groups?.any((g) => g.toLowerCase() == group) ?? false).toList();
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onLoadGroupsData(LoadGroupsData event, Emitter<EmployeeGroupsState> emit) async {
    emit(state.copyWith(status: EmployeeGroupsStatus.loading, clearMessages: true));

    try {
      final employees = await _repo.getUsers(locale: event.locale);
      emit(
        state.copyWith(
          status: EmployeeGroupsStatus.loaded,
          allEmployees: employees,
          groupsData: _deriveGroupsData(employees),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EmployeeGroupsStatus.error,
          errorMessage: 'Failed to load groups data: ${error.toString()}',
        ),
      );
    }
  }

  void _onSelectGroup(SelectGroup event, Emitter<EmployeeGroupsState> emit) {
    emit(state.copyWith(selectedGroup: event.group, clearMessages: true));
  }

  Future<void> _onAddMemberToGroup(AddMemberToGroup event, Emitter<EmployeeGroupsState> emit) async {
    emit(state.copyWith(status: EmployeeGroupsStatus.updating, clearMessages: true));

    try {
      // Fetch fresh employee record to get authoritative groups list
      final employee = await _repo.getEmployeeById(event.employee.id!);

      final currentGroups = <String>[];
      if (employee.groups != null) {
        currentGroups.addAll(employee.groups!);
      }

      // Guard: already in group
      if (currentGroups.contains(event.group.toLowerCase())) {
        emit(state.copyWith(status: EmployeeGroupsStatus.loaded, errorMessage: 'USER_ALREADY_IN_GROUP:${event.group}'));
        return;
      }

      currentGroups.add(event.group.toLowerCase());
      final updatedEmployee = employee.copyWith(groups: currentGroups);
      await _repo.updateEmployee(updatedEmployee);

      // Update local state immediately without re-fetching
      final updatedList = state.allEmployees.map((e) => e.id == event.employee.id ? updatedEmployee : e).toList();

      emit(
        state.copyWith(
          status: EmployeeGroupsStatus.loaded,
          allEmployees: updatedList,
          groupsData: _deriveGroupsData(updatedList),
          successMessage: 'ADDED_TO_GROUP:${event.group}',
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: EmployeeGroupsStatus.error, errorMessage: 'FAILED_ADD_TO_GROUP:${error.toString()}'));
    }
  }

  Future<void> _onRemoveMemberFromGroup(RemoveMemberFromGroup event, Emitter<EmployeeGroupsState> emit) async {
    emit(state.copyWith(status: EmployeeGroupsStatus.updating, clearMessages: true));

    try {
      // Fetch fresh employee record
      final employee = await _repo.getEmployeeById(event.employeeId);

      final currentGroups = <String>[];
      if (employee.groups != null) {
        currentGroups.addAll(employee.groups!);
      }

      // Guard: not in group
      if (!currentGroups.contains(event.group.toLowerCase())) {
        emit(state.copyWith(status: EmployeeGroupsStatus.loaded, errorMessage: 'USER_NOT_IN_GROUP:${event.group}'));
        return;
      }

      currentGroups.remove(event.group.toLowerCase());
      final updatedEmployee = employee.copyWith(groups: currentGroups);
      await _repo.updateEmployee(updatedEmployee);

      // Update local state immediately without re-fetching
      final updatedList = state.allEmployees.map((e) => e.id == event.employeeId ? updatedEmployee : e).toList();

      emit(
        state.copyWith(
          status: EmployeeGroupsStatus.loaded,
          allEmployees: updatedList,
          groupsData: _deriveGroupsData(updatedList),
          successMessage: 'REMOVED_FROM_GROUP:${event.group}',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EmployeeGroupsStatus.error,
          errorMessage: 'FAILED_REMOVE_FROM_GROUP:${error.toString()}',
        ),
      );
    }
  }
}
