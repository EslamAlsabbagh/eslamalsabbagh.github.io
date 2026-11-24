import 'package:equatable/equatable.dart';

import '../../../core/domain/contract_kind.dart';
import 'task_list_item.dart';

/// The contract a follow-up task belongs to, as the task drawer names it.
typedef TaskContract = ({ContractKind kind, String subject});

/// One task as the drawer shows it: the [TaskListItem] fields plus the ones
/// only the drawer needs.
class TaskDetails extends Equatable {
  const TaskDetails({required this.item, required this.description, required this.isManualUrgent, this.contract});

  /// Builds from a `task_list` row selected with [TaskDetails.select].
  factory TaskDetails.fromRow(Map<String, dynamic> row) => TaskDetails(
        item: TaskListItem.fromRow(row),
        description: row['description'] as String? ?? '',
        isManualUrgent: row['is_urgent'] as bool,
        contract: switch (row['contract']) {
          {'kind': final String kind, 'subject': final String? subject} =>
            (kind: ContractKind.fromDb(kind), subject: subject ?? ''),
          _ => null,
        },
      );

  /// The list's columns, plus the follow-up's contract through
  /// `tasks.contract_id` (null when RLS hides it).
  static const String select = '${TaskListItem.select}, description, is_urgent, contract:contracts(kind, subject)';

  final TaskListItem item;
  final String description;

  /// The stored «تعليم كعاجلة يدويًا» flag (`tasks.is_urgent`). Whether the
  /// task is urgent right now is [TaskListItem.isUrgentNow].
  final bool isManualUrgent;

  /// A follow-up's contract ([TaskListItem.contractId]); null for any other
  /// task, or one whose contract the viewer can't read.
  final TaskContract? contract;

  @override
  List<Object?> get props => [item, description, isManualUrgent, contract];
}
