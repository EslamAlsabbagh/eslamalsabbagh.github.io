import 'package:hrms_demo/core/utils/display_name_utils.dart';
import 'package:hrms_demo/core/utils/leave_error_localizer.dart';
import 'package:hrms_demo/data/repos/leave_request/bulk_leave_result.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Reports the outcome of a best-effort normal-cycle bulk submission: how many
/// requests were created, and which employees the server rejected and why.
///
/// The failures are passed in rather than read from the bloc so the dialog keeps
/// rendering correctly after the caller clears the message state.
///
/// Built on the plain [Dialog], not [AlertDialog], for the same reason
/// `_ShiftPickerDialog` is: AlertDialog wraps its body in an `IntrinsicWidth`,
/// which probes the child for its intrinsic width and blows up on the lazy
/// [ListView] below ("viewport does not support returning intrinsic
/// dimensions") — the layout aborts and only the modal barrier paints.
class BulkLeaveResultDialog extends StatelessWidget {
  final int createdCount;
  final int totalCount;
  final List<BulkLeaveFailure> failures;

  const BulkLeaveResultDialog({
    super.key,
    required this.createdCount,
    required this.totalCount,
    required this.failures,
  });

  static Future<void> show(
    BuildContext context, {
    required int createdCount,
    required int totalCount,
    required List<BulkLeaveFailure> failures,
  }) {
    return showDialog<void>(
      context: context,
      builder:
          (_) => BulkLeaveResultDialog(createdCount: createdCount, totalCount: totalCount, failures: failures),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Nothing created at all is a hard failure; a partial run is a warning.
    final accent = createdCount == 0 ? Colors.red : Colors.orange.shade800;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.bulkLeavesPartialTitle,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.bulkLeavesPartialSummary(createdCount, totalCount),
                style: TextStyle(fontWeight: FontWeight.w600, color: accent),
              ),
            ),
            const SizedBox(height: 12),
            // Flexible + shrinkWrap: the list takes only what it needs, and
            // scrolls within the dialog once the batch is large.
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: failures.length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final failure = failures[index];
                  final name = DisplayNameUtils.getDisplayName(
                    context,
                    failure.employee.englishName,
                    failure.employee.arabicName,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        localizeLeaveError(l10n, failure.rawError),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  );
                },
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
