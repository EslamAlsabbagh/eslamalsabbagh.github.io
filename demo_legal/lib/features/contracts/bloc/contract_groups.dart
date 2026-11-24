import 'package:equatable/equatable.dart';

import '../../../core/domain/contract_list_status.dart';
import '../../tasks/data/task_file.dart';
import '../data/contract_list_item.dart';

/// One file's section in «العقود»: its contracts in list order, and the
/// terminated ones for the collapsed «الملغاة» toggle.
final class FileContracts extends Equatable {
  const FileContracts({required this.file, required this.current, required this.terminated});

  final TaskFile file;

  /// Expired, then ending, then active by end date (soonest first, undated
  /// last).
  final List<ContractListItem> current;

  /// Most recently terminated first.
  final List<ContractListItem> terminated;

  /// The summary «n عقود · n تنتهي خلال ٩٠ يومًا · n بها نواقص» counts the
  /// shown contracts outside the toggle.
  int get endingCount => current.where((c) => c.listStatus == ContractListStatus.ending).length;
  int get missingCount => current.where((c) => c.openItemCount > 0).length;

  @override
  List<Object?> get props => [file, current, terminated];
}

/// A section per file in [files] (chip order) that has any of [contracts].
List<FileContracts> buildContractGroups({
  required List<TaskFile> files,
  required List<ContractListItem> contracts,
}) {
  final byFile = <String, List<ContractListItem>>{};
  for (final contract in contracts) {
    byFile.putIfAbsent(contract.fileId, () => []).add(contract);
  }
  return [
    for (final file in files)
      if (byFile[file.id] case final rows?)
        FileContracts(
          file: file,
          current: rows.where((c) => !c.isTerminated).toList()..sort(_listOrder),
          terminated: rows.where((c) => c.isTerminated).toList()..sort(_terminatedOrder),
        ),
  ];
}

int _listOrder(ContractListItem a, ContractListItem b) {
  final group = a.sortGroup.compareTo(b.sortGroup);
  if (group != 0) return group;
  final ends = _compareDates(a.endsOn, b.endsOn);
  if (ends != 0) return ends;
  final created = a.createdAt.compareTo(b.createdAt);
  return created != 0 ? created : a.id.compareTo(b.id);
}

int _terminatedOrder(ContractListItem a, ContractListItem b) {
  final ended = _compareDates(b.terminatedOn, a.terminatedOn, nullsLast: false);
  if (ended != 0) return ended;
  final created = b.createdAt.compareTo(a.createdAt);
  return created != 0 ? created : a.id.compareTo(b.id);
}

/// Earliest first, with a missing date after every date (or before them,
/// when [nullsLast] is false, which the reversed newest-first order needs).
int _compareDates(DateTime? a, DateTime? b, {bool nullsLast = true}) {
  if (a == null && b == null) return 0;
  if (a == null) return nullsLast ? 1 : -1;
  if (b == null) return nullsLast ? -1 : 1;
  return a.compareTo(b);
}
