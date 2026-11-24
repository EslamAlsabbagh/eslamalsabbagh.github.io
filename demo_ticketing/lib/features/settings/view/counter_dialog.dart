import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/settings_cubit.dart';
import '../data/settings_models.dart';
import '../data/settings_repository.dart';
import 'settings_messages.dart';

/// Adds a counter ([counter] null) or changes one: name, printer, paper and
/// home gate. The design's counters card has no edit form; this one follows
/// the Gates page's controller dialog. Each save is logged.
Future<void> showCounterDialog(
  BuildContext context, {
  required SettingsCubit cubit,
  required List<EntryGateOption> entryGates,
  AdminCounter? counter,
}) => showDialog<void>(
  context: context,
  builder: (context) => _CounterDialog(cubit: cubit, entryGates: entryGates, counter: counter),
);

class _CounterDialog extends StatefulWidget {
  const _CounterDialog({required this.cubit, required this.entryGates, required this.counter});

  final SettingsCubit cubit;
  final List<EntryGateOption> entryGates;
  final AdminCounter? counter;

  @override
  State<_CounterDialog> createState() => _CounterDialogState();
}

class _CounterDialogState extends State<_CounterDialog> {
  late final _name = TextEditingController(text: widget.counter?.name ?? '');
  late final _ip = TextEditingController(text: widget.counter?.printerIp ?? '');
  // 9100: the raw printing port (HARDWARE.md §4).
  late final _port = TextEditingController(text: '${widget.counter?.printerPort ?? 9100}');
  late int _paper = widget.counter?.paperWidthMm ?? 80;
  late String? _gateId = widget.counter?.entryGateId;
  late bool _active = widget.counter?.active ?? true;

  SettingsFailureKind? _failure;
  bool _saving = false;

  List<TextEditingController> get _all => [_name, _ip, _port];

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(_changed);
    }
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() => _failure = null);

  int? get _portValue => int.tryParse(_port.text.trim());

  CounterDraft? get _draft {
    final port = _portValue;
    if (_name.text.trim().isEmpty) return null;
    if (port == null || port < 1 || port > 65535) return null;
    // An active counter needs a home gate (ADR-0015), as save_counter says.
    if (_active && _gateId == null) return null;
    return CounterDraft(
      name: _name.text.trim(),
      printerIp: _ip.text.trim().isEmpty ? null : _ip.text.trim(),
      printerPort: port,
      paperWidthMm: _paper,
      entryGateId: _gateId,
      active: _active,
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final failure = await widget.cubit.saveCounter(widget.counter?.id, draft);
    if (!mounted) return;
    if (failure == null) {
      navigator.pop();
      messenger?.showSnackBar(
        SnackBar(content: Text(widget.counter == null ? l10n.counterAddedCopyId : l10n.typesSaved)),
      );
    } else {
      setState(() {
        _saving = false;
        _failure = failure.kind;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final counter = widget.counter;
    final draft = _draft;
    final changed = draft != null && (counter == null || !draft.sameAs(counter.draft));
    final failureText = _failure == null ? null : settingsFailureMessage(l10n, _failure!);

    String? on(Set<SettingsFailureKind> kinds) => kinds.contains(_failure) ? failureText : null;
    final nameError = on({SettingsFailureKind.nameTaken, SettingsFailureKind.invalidName});
    final ipError = on({SettingsFailureKind.invalidIp});
    final portError =
        _port.text.trim().isNotEmpty && !((_portValue ?? 0) >= 1 && (_portValue ?? 0) <= 65535)
        ? l10n.gatesInvalidPort
        : on({SettingsFailureKind.invalidPort});
    final gateError = on({
      SettingsFailureKind.homeGateRequired,
      SettingsFailureKind.homeGateNotEntry,
      SettingsFailureKind.gateNotFound,
    });
    final banner =
        failureText != null &&
            nameError == null &&
            ipError == null &&
            on({SettingsFailureKind.invalidPort}) == null &&
            gateError == null
        ? failureText
        : null;

    // Off with no home gate is allowed; on without one keeps Save off.
    final needsGate = _active && _gateId == null;
    final gateIds = {for (final g in widget.entryGates) g.id};
    final openShift = counter?.hasOpenShift ?? false;

    InputDecoration decoration({String? error, String? hint}) => InputDecoration(
      isDense: true,
      errorText: error,
      errorMaxLines: 2,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: BorderSide(color: tokens.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: BorderSide(color: tokens.inputBorder),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

    Widget field(String label, Widget input) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        input,
      ],
    );

    Widget note(String text, Color bg, Color fg, {Key? key}) => Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, color: fg)),
    );

    return AlertDialog(
      key: const ValueKey('counter-dialog'),
      title: Text(counter == null ? l10n.counterNew : l10n.typesEditTitle(counter.name)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field(
                l10n.gatesName,
                TextField(
                  key: const ValueKey('counter-name'),
                  controller: _name,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  decoration: decoration(error: nameError),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: field(
                      l10n.counterPrinterIp,
                      TextField(
                        key: const ValueKey('counter-ip'),
                        controller: _ip,
                        textDirection: TextDirection.ltr,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F.:]')),
                          LengthLimitingTextInputFormatter(45),
                        ],
                        decoration: decoration(error: ipError, hint: '10.20.0.21'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: field(
                      l10n.counterPrinterPort,
                      TextField(
                        key: const ValueKey('counter-port'),
                        controller: _port,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        decoration: decoration(error: portError),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              field(
                l10n.counterPaperWidth,
                SegmentedButton<int>(
                  key: const ValueKey('counter-paper'),
                  showSelectedIcon: false,
                  segments: [
                    for (final mm in const [80, 58])
                      ButtonSegment(value: mm, label: Text(l10n.counterPaperMm(mm))),
                  ],
                  selected: {_paper},
                  onSelectionChanged: (value) => setState(() {
                    _paper = value.first;
                    _failure = null;
                  }),
                ),
              ),
              const SizedBox(height: 12),
              field(
                l10n.counterHomeGate,
                DropdownButtonFormField<String?>(
                  key: const ValueKey('counter-gate'),
                  initialValue: gateIds.contains(_gateId) ? _gateId : null,
                  isExpanded: true,
                  decoration: decoration(
                    error: gateError ?? (needsGate ? l10n.counterHomeGateRequired : null),
                  ),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(l10n.counterNoHomeGate)),
                    for (final g in widget.entryGates)
                      DropdownMenuItem<String?>(
                        value: g.id,
                        child: Text(
                          g.enabled ? g.name : l10n.counterGateDisabled(g.name),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _gateId = value;
                    _failure = null;
                  }),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.counterHomeGateNote,
                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: tokens.inset,
                  borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.counterActive,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            openShift ? l10n.counterOpenShiftNote : l10n.counterActiveNote,
                            key: const ValueKey('counter-active-note'),
                            style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      key: const ValueKey('counter-active'),
                      value: _active,
                      // A cashier is selling there: the shift closes first.
                      onChanged: openShift && _active
                          ? null
                          : (value) => setState(() {
                              _active = value;
                              _failure = null;
                            }),
                    ),
                  ],
                ),
              ),
              if (counter != null &&
                  counter.entryGateId != null &&
                  _gateId != counter.entryGateId) ...[
                const SizedBox(height: 12),
                note(
                  l10n.counterGateChangeNote,
                  tokens.warningBg,
                  tokens.warningText,
                  key: const ValueKey('counter-gate-change-note'),
                ),
              ],
              if (counter == null) ...[
                const SizedBox(height: 12),
                note(l10n.counterNewIdNote, tokens.primaryTint, tokens.onPrimaryTint),
              ],
              if (banner != null) ...[
                const SizedBox(height: 12),
                note(
                  banner,
                  tokens.dangerBg,
                  tokens.dangerText,
                  key: const ValueKey('counter-failure'),
                ),
              ],
              const SizedBox(height: 10),
              Text(l10n.typesLogNote, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.back),
        ),
        FilledButton(
          key: const ValueKey('counter-save'),
          onPressed: changed && !_saving ? _save : null,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(counter == null ? l10n.counterAdd : l10n.gatesSave),
        ),
      ],
    );
  }
}
