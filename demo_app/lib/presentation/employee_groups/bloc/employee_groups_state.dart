import 'package:equatable/equatable.dart';
import 'package:hrms_demo/data/models/user_model.dart';

/// The ordered list of groups managed by this page.
/// Update this constant to add or remove manageable groups.
const kManagedGroups = ['hr', 'legal', 'top management', 'finance', 'it', 'dashboard'];

enum EmployeeGroupsStatus { initial, loading, loaded, updating, error }

class EmployeeGroupsState extends Equatable {
  final EmployeeGroupsStatus status;
  final List<UserModel> allEmployees;

  /// Map from group name to list of members in that group.
  /// Derived client-side from [allEmployees] on each load.
  final Map<String, List<UserModel>> groupsData;

  /// The group whose members are currently shown in the right panel.
  final String selectedGroup;

  final String? errorMessage;
  final String? successMessage;

  const EmployeeGroupsState({
    this.status = EmployeeGroupsStatus.initial,
    this.allEmployees = const [],
    this.groupsData = const {},
    this.selectedGroup = 'hr',
    this.errorMessage,
    this.successMessage,
  });

  EmployeeGroupsState copyWith({
    EmployeeGroupsStatus? status,
    List<UserModel>? allEmployees,
    Map<String, List<UserModel>>? groupsData,
    String? selectedGroup,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return EmployeeGroupsState(
      status: status ?? this.status,
      allEmployees: allEmployees ?? this.allEmployees,
      groupsData: groupsData ?? this.groupsData,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [status, allEmployees, groupsData, selectedGroup, errorMessage, successMessage];
}
