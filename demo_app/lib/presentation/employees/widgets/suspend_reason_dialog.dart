import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The three suspension reasons. Stored raw in `users."Suspension Reason"`;
/// only resignation/termination require a last working date.
class SuspensionReasons {
  static const String resignation = 'resignation';
  static const String termination = 'termination';
  static const String other = 'other';

  /// Reasons that require the user to pick a last working date.
  static bool requiresLastWorkingDate(String? reason) => reason == resignation || reason == termination;
}

/// Result returned by [SuspendReasonDialog] when the admin confirms.
/// `lastWorkingDate` is null for the 'other' reason.
class SuspendReasonResult {
  final String reason;
  final DateTime? lastWorkingDate;

  const SuspendReasonResult({required this.reason, this.lastWorkingDate});
}

/// Dialog shown at the start of the suspend flow. Asks for the suspension
/// reason; for resignation/termination it additionally requires a last
/// working date before the suspension can be confirmed. Returns a
/// [SuspendReasonResult] on confirm, or null on cancel/dismiss.
class SuspendReasonDialog extends StatefulWidget {
  const SuspendReasonDialog({super.key});

  @override
  State<SuspendReasonDialog> createState() => _SuspendReasonDialogState();
}

class _SuspendReasonDialogState extends State<SuspendReasonDialog> {
  String? _reason;
  DateTime? _lastWorkingDate;

  final DateFormat _dateFormat = DateFormat('d-MMM-yyyy');

  bool get _needsDate => SuspensionReasons.requiresLastWorkingDate(_reason);

  bool get _canConfirm => _reason != null && (!_needsDate || _lastWorkingDate != null);

  String _reasonLabel(AppLocalizations l10n, String reason) {
    switch (reason) {
      case SuspensionReasons.resignation:
        return l10n.reasonResignation;
      case SuspensionReasons.termination:
        return l10n.reasonTermination;
      default:
        return l10n.reasonOther;
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: _lastWorkingDate ?? DateTime.now(),
      // Any date allowed — supports future-dated notice periods.
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _lastWorkingDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.pause_circle_outline, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.suspendEmployee, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _reason,
              decoration: InputDecoration(
                labelText: l10n.suspensionReason,
                hintText: l10n.selectSuspensionReason,
                prefixIcon: const Icon(Icons.info_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items:
                  const [
                    SuspensionReasons.resignation,
                    SuspensionReasons.termination,
                    SuspensionReasons.other,
                  ].map((v) => DropdownMenuItem<String>(value: v, child: Text(_reasonLabel(l10n, v)))).toList(),
              onChanged: (value) {
                setState(() {
                  _reason = value;
                  // Drop any picked date if the reason no longer needs one.
                  if (!_needsDate) _lastWorkingDate = null;
                });
              },
            ),
            if (_needsDate) ...[
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: _lastWorkingDate != null ? _dateFormat.format(_lastWorkingDate!) : '',
                ),
                decoration: InputDecoration(
                  labelText: l10n.lastWorkingDate,
                  hintText: l10n.selectLastWorkingDate,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onTap: _pickDate,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
          onPressed:
              _canConfirm
                  ? () => Navigator.of(
                    context,
                  ).pop(SuspendReasonResult(reason: _reason!, lastWorkingDate: _lastWorkingDate))
                  : null,
          child: Text(l10n.confirmAndSuspend),
        ),
      ],
    );
  }
}
