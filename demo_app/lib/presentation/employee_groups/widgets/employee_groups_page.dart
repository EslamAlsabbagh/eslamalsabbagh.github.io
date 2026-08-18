import 'package:hrms_demo/core/utils/display_name_utils.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_groups/bloc/employee_groups_bloc.dart';
import 'package:hrms_demo/presentation/employee_groups/bloc/employee_groups_event.dart';
import 'package:hrms_demo/presentation/employee_groups/bloc/employee_groups_state.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/data/models/user_model.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────

class EmployeeGroupsPage extends StatelessWidget {
  const EmployeeGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = EmployeeGroupsBloc(repo: context.read<UsersRepo>());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          bloc.add(LoadGroupsData(locale: Localizations.localeOf(context).languageCode));
        });
        return bloc;
      },
      child: const _EmployeeGroupsView(),
    );
  }
}

// ─── View ─────────────────────────────────────────────────────────────────────

class _EmployeeGroupsView extends StatelessWidget {
  const _EmployeeGroupsView();

  /// Translates the prefix-coded message strings from the BLoC into
  /// human-readable localized strings, reusing the same convention as
  /// edit_employee_content.dart's _getLocalizedMessage.
  String _decodeMessage(BuildContext context, String messageKey) {
    final l10n = AppLocalizations.of(context)!;
    if (messageKey.startsWith('ADDED_TO_GROUP:')) {
      return l10n.successfullyAddedUserToGroup(messageKey.split(':')[1]);
    } else if (messageKey.startsWith('REMOVED_FROM_GROUP:')) {
      return l10n.successfullyRemovedUserFromGroup(messageKey.split(':')[1]);
    } else if (messageKey.startsWith('USER_ALREADY_IN_GROUP:')) {
      return l10n.userAlreadyInGroup(messageKey.split(':')[1]);
    } else if (messageKey.startsWith('USER_NOT_IN_GROUP:')) {
      return l10n.userNotInGroup(messageKey.split(':')[1]);
    } else if (messageKey.startsWith('FAILED_ADD_TO_GROUP:')) {
      return l10n.failedToAddUserToGroup(messageKey.split(':')[1]);
    } else if (messageKey.startsWith('FAILED_REMOVE_FROM_GROUP:')) {
      return l10n.failedToRemoveUserFromGroup(messageKey.split(':')[1]);
    }
    return messageKey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MainLayout(
      title: l10n.employeeGroups,
      child: BlocConsumer<EmployeeGroupsBloc, EmployeeGroupsState>(
        listenWhen:
            (previous, current) =>
                (current.successMessage != null && current.successMessage != previous.successMessage) ||
                (current.errorMessage != null && current.errorMessage != previous.errorMessage),
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_decodeMessage(context, state.successMessage!))));
          }
          if (state.status == EmployeeGroupsStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_decodeMessage(context, state.errorMessage!))));
          }
        },
        builder: (context, state) {
          if (state.status == EmployeeGroupsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == EmployeeGroupsStatus.error && state.allEmployees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? l10n.errorOccurred,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      context.read<EmployeeGroupsBloc>().add(
                        LoadGroupsData(locale: Localizations.localeOf(context).languageCode),
                      );
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          return _TwoPanelLayout(state: state);
        },
      ),
    );
  }
}

// ─── Two-panel layout ─────────────────────────────────────────────────────────

class _TwoPanelLayout extends StatelessWidget {
  final EmployeeGroupsState state;
  const _TwoPanelLayout({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel — group list
          SizedBox(width: 200, child: _GroupsListPanel(state: state)),
          const VerticalDivider(width: 1, thickness: 1),
          // Right panel — members of selected group
          SizedBox(width: 600, child: _GroupMembersPanel(state: state)),
        ],
      ),
    );
  }
}

// ─── Left panel: group list ───────────────────────────────────────────────────

class _GroupsListPanel extends StatelessWidget {
  final EmployeeGroupsState state;
  const _GroupsListPanel({required this.state});

  String _groupDisplayName(BuildContext context, String group) {
    final l10n = AppLocalizations.of(context)!;
    switch (group) {
      case 'hr':
        return l10n.groupHr;
      case 'legal':
        return l10n.groupLegal;
      case 'top management':
        return l10n.groupTopManagement;
      case 'finance':
        return l10n.groupFinance;
      case 'it':
        return l10n.groupIt;
      case 'dashboard':
        return l10n.groupDashboard;
      default:
        return group;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: ListView.builder(
        itemCount: kManagedGroups.length,
        itemBuilder: (context, index) {
          final group = kManagedGroups[index];
          final isSelected = state.selectedGroup == group;
          final members = state.groupsData[group] ?? [];

          return Material(
            color: Colors.transparent,
            child: ListTile(
              selected: isSelected,
              selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
              leading: Icon(Icons.group, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600]),
              title: Text(
                _groupDisplayName(context, group),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${members.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
              onTap: () {
                context.read<EmployeeGroupsBloc>().add(SelectGroup(group));
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Right panel: group members ───────────────────────────────────────────────

class _GroupMembersPanel extends StatelessWidget {
  final EmployeeGroupsState state;
  const _GroupMembersPanel({required this.state});

  String _groupDisplayName(BuildContext context, String group) {
    final l10n = AppLocalizations.of(context)!;
    switch (group) {
      case 'hr':
        return l10n.groupHr;
      case 'legal':
        return l10n.groupLegal;
      case 'top management':
        return l10n.groupTopManagement;
      case 'finance':
        return l10n.groupFinance;
      case 'it':
        return l10n.groupIt;
      case 'dashboard':
        return l10n.groupDashboard;
      default:
        return group;
    }
  }

  void _showAddMemberDialog(BuildContext context, String group, List<UserModel> currentMembers) {
    showDialog<void>(
      context: context,
      builder:
          (_) => BlocProvider.value(
            value: context.read<EmployeeGroupsBloc>(),
            child: _AddMemberDialog(targetGroup: group, currentMembers: currentMembers),
          ),
    );
  }

  void _showRemoveConfirmDialog(BuildContext context, UserModel member, String group) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = DisplayNameUtils.getDisplayName(context, member.englishName, member.arabicName);
    final groupName = _groupDisplayName(context, group);

    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.confirmRemoveMemberTitle),
            content: Text(l10n.confirmRemoveMemberMessage(displayName, groupName)),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.cancel)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<EmployeeGroupsBloc>().add(RemoveMemberFromGroup(employeeId: member.id!, group: group));
                },
                child: Text(l10n.confirmRemoveMemberTitle, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final group = state.selectedGroup;
    final members = state.groupsData[group] ?? [];
    final locale = Localizations.localeOf(context).languageCode;
    final isUpdating = state.status == EmployeeGroupsStatus.updating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Colors.grey[50],
          child: Row(
            children: [
              Icon(Icons.group, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Text(
                _groupDisplayName(context, group),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text('(${members.length})', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const Spacer(),
              if (isUpdating)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: isUpdating ? null : () => _showAddMemberDialog(context, group, members),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: Text(l10n.addMember),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Member list
        Expanded(
          child:
              members.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(l10n.noMembersInGroup, style: TextStyle(fontSize: 15, color: Colors.grey[500])),
                      ],
                    ),
                  )
                  : ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final displayName = DisplayNameUtils.getDisplayName(
                        context,
                        member.englishName,
                        member.arabicName,
                      );
                      final title =
                          locale == 'ar'
                              ? (member.title ?? member.englishTitle ?? '')
                              : (member.englishTitle ?? member.title ?? '');

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          displayName.isEmpty ? l10n.unknown : displayName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: title.isNotEmpty ? Text(title, style: const TextStyle(fontSize: 12)) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.person_remove_outlined),
                          color: Colors.red[400],
                          tooltip: l10n.confirmRemoveMemberTitle,
                          onPressed: isUpdating ? null : () => _showRemoveConfirmDialog(context, member, group),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

// ─── Add member dialog ────────────────────────────────────────────────────────

class _AddMemberDialog extends StatefulWidget {
  final String targetGroup;
  final List<UserModel> currentMembers;

  const _AddMemberDialog({required this.targetGroup, required this.currentMembers});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<EmployeeGroupsBloc, EmployeeGroupsState>(
      builder: (context, state) {
        // All employees not already in this group
        final currentMemberIds = widget.currentMembers.map((e) => e.id).toSet();
        final candidates = state.allEmployees.where((e) => !currentMemberIds.contains(e.id)).toList();

        // Apply search filter then sort: code matches ascending, name matches by term position
        int compareEmployees(UserModel a, UserModel b) {
          final term = _searchTerm.toLowerCase();
          final isNumeric = int.tryParse(_searchTerm) != null;
          final shortCodeA = a.id != null ? (a.id! - 10000000).toString() : '';
          final shortCodeB = b.id != null ? (b.id! - 10000000).toString() : '';
          final engNameA = a.englishName?.toLowerCase() ?? '';
          final arNameA = a.arabicName?.toLowerCase() ?? '';
          final engNameB = b.englishName?.toLowerCase() ?? '';
          final arNameB = b.arabicName?.toLowerCase() ?? '';

          final isCodeA = isNumeric && shortCodeA.startsWith(_searchTerm);
          final isCodeB = isNumeric && shortCodeB.startsWith(_searchTerm);

          // Code matches before name matches
          if (isCodeA && !isCodeB) return -1;
          if (!isCodeA && isCodeB) return 1;

          if (isCodeA && isCodeB) {
            return (a.id ?? 0).compareTo(b.id ?? 0); // ascending code
          }

          // Both name matches: sort by earliest position of term in name
          int bestPos(String eng, String ar) {
            final pe = eng.indexOf(term);
            final pa = ar.indexOf(term);
            if (pe == -1) return pa == -1 ? 999 : pa;
            if (pa == -1) return pe;
            return pe < pa ? pe : pa;
          }

          final posA = bestPos(engNameA, arNameA);
          final posB = bestPos(engNameB, arNameB);
          if (posA != posB) return posA.compareTo(posB);
          // Alphabetical tiebreak
          final nameA = engNameA.isNotEmpty ? engNameA : arNameA;
          final nameB = engNameB.isNotEmpty ? engNameB : arNameB;
          return nameA.compareTo(nameB);
        }

        final filtered =
            _searchTerm.isEmpty
                ? candidates
                : (candidates.where((e) {
                    final term = _searchTerm.toLowerCase();
                    final engName = e.englishName?.toLowerCase() ?? '';
                    final arName = e.arabicName?.toLowerCase() ?? '';
                    final shortCode = e.id != null ? (e.id! - 10000000).toString() : '';
                    final isNumeric = int.tryParse(_searchTerm) != null;
                    return engName.contains(term) ||
                        arName.contains(term) ||
                        (isNumeric && shortCode.startsWith(_searchTerm));
                  }).toList()
                  ..sort(compareEmployees));

        return AlertDialog(
          title: Row(children: [const Icon(Icons.person_add), const SizedBox(width: 8), Text(l10n.addMember)]),
          content: SizedBox(
            width: 420,
            height: 460,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchEmployeesToAdd,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchTerm.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchTerm = '');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchTerm = v),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child:
                      filtered.isEmpty
                          ? Center(child: Text(l10n.noEmployeesYet, style: TextStyle(color: Colors.grey[500])))
                          : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final employee = filtered[index];
                              final displayName = DisplayNameUtils.getDisplayName(
                                context,
                                employee.englishName,
                                employee.arabicName,
                              );
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  displayName.isEmpty ? l10n.unknown : displayName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  '${l10n.code}: ${employee.id ?? 'N/A'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                onTap: () {
                                  context.read<EmployeeGroupsBloc>().add(
                                    AddMemberToGroup(employee: employee, group: widget.targetGroup),
                                  );
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel))],
        );
      },
    );
  }
}
