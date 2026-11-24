import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/gates_cubit.dart';
import '../data/gate_models.dart';
import '../data/gates_repository.dart';
import 'gates_messages.dart';

/// Adds a controller ([controller] null) or changes one (not in the design:
/// it has no way to set up a controller). Each save is logged.
Future<void> showControllerDialog(
  BuildContext context, {
  required GatesCubit cubit,
  AdminController? controller,
}) => showDialog<void>(
  context: context,
  builder: (context) => _ControllerDialog(cubit: cubit, controller: controller),
);

class _ControllerDialog extends StatefulWidget {
  const _ControllerDialog({required this.cubit, required this.controller});

  final GatesCubit cubit;
  final AdminController? controller;

  @override
  State<_ControllerDialog> createState() => _ControllerDialogState();
}

class _ControllerDialogState extends State<_ControllerDialog> {
  late final _name = TextEditingController(text: widget.controller?.name ?? '');
  late final _model = TextEditingController(text: widget.controller?.model ?? '');
  late final _ip = TextEditingController(text: widget.controller?.ip ?? '');
  // 4370: the usual ZKTeco port (NOT CONFIRMED for our model, HARDWARE.md).
  late final _port = TextEditingController(text: '${widget.controller?.port ?? 4370}');
  late final _doors = TextEditingController(text: '${widget.controller?.doorCount ?? ''}');

  GatesFailureKind? _failure;
  bool _saving = false;

  List<TextEditingController> get _all => [_name, _model, _ip, _port, _doors];

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
  int? get _doorsValue => int.tryParse(_doors.text.trim());

  ControllerDraft? get _draft {
    final port = _portValue;
    final doors = _doorsValue;
    if (_name.text.trim().isEmpty) return null;
    if (port == null || port < 1 || port > 65535) return null;
    if (doors == null || doors < 1 || doors > 4) return null;
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return ControllerDraft(
      name: _name.text.trim(),
      model: text(_model),
      ip: text(_ip),
      port: port,
      doorCount: doors,
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final failure = await widget.cubit.saveController(widget.controller?.id, draft);
    if (!mounted) return;
    if (failure == null) {
      navigator.pop();
      messenger?.showSnackBar(SnackBar(content: Text(l10n.typesSaved)));
    } else {
      setState(() {
        _saving = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final controller = widget.controller;
    final draft = _draft;
    final changed = draft != null && (controller == null || !draft.sameAs(controller.draft));
    final failureText = _failure == null ? null : gatesFailureMessage(l10n, _failure!);

    String? on(Set<GatesFailureKind> kinds) => kinds.contains(_failure) ? failureText : null;
    final nameError = on({GatesFailureKind.nameTaken, GatesFailureKind.invalidName});
    final ipError = on({GatesFailureKind.invalidIp});
    final portError =
        _port.text.trim().isNotEmpty && !((_portValue ?? 0) >= 1 && (_portValue ?? 0) <= 65535)
        ? l10n.gatesInvalidPort
        : on({GatesFailureKind.invalidPort});
    final doorsError =
        _doors.text.trim().isNotEmpty && !((_doorsValue ?? 0) >= 1 && (_doorsValue ?? 0) <= 4)
        ? l10n.gatesInvalidDoorCount
        : on({GatesFailureKind.invalidDoorCount, GatesFailureKind.doorsInUse});
    final banner =
        failureText != null &&
            nameError == null &&
            ipError == null &&
            on({GatesFailureKind.invalidPort}) == null &&
            on({GatesFailureKind.invalidDoorCount, GatesFailureKind.doorsInUse}) == null
        ? failureText
        : null;

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

    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );

    final digits = [FilteringTextInputFormatter.digitsOnly];

    return AlertDialog(
      key: const ValueKey('controller-dialog'),
      title: Text(
        controller == null ? l10n.controllerNew : l10n.controllerEditTitle(controller.name),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              pair(
                field(
                  l10n.gatesName,
                  TextField(
                    key: const ValueKey('controller-name'),
                    controller: _name,
                    inputFormatters: [LengthLimitingTextInputFormatter(40)],
                    decoration: decoration(error: nameError),
                  ),
                ),
                field(
                  l10n.controllerModel,
                  TextField(
                    key: const ValueKey('controller-model'),
                    controller: _model,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [LengthLimitingTextInputFormatter(40)],
                    decoration: decoration(hint: 'C3-400'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              field(
                l10n.controllerIp,
                TextField(
                  key: const ValueKey('controller-ip'),
                  controller: _ip,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F.:]')),
                    LengthLimitingTextInputFormatter(45),
                  ],
                  decoration: decoration(error: ipError, hint: '10.20.0.51'),
                ),
              ),
              const SizedBox(height: 12),
              pair(
                field(
                  l10n.controllerPort,
                  TextField(
                    key: const ValueKey('controller-port'),
                    controller: _port,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.number,
                    inputFormatters: [...digits, LengthLimitingTextInputFormatter(5)],
                    decoration: decoration(error: portError),
                  ),
                ),
                field(
                  l10n.controllerDoorsLabel,
                  TextField(
                    key: const ValueKey('controller-doors'),
                    controller: _doors,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.number,
                    inputFormatters: [...digits, LengthLimitingTextInputFormatter(1)],
                    decoration: decoration(error: doorsError, hint: '1–4'),
                  ),
                ),
              ),
              if (banner != null) ...[
                const SizedBox(height: 14),
                Container(
                  key: const ValueKey('controller-failure'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tokens.dangerBg,
                    borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                  ),
                  child: Text(banner, style: TextStyle(fontSize: 14, color: tokens.dangerText)),
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
          key: const ValueKey('controller-save'),
          onPressed: changed && !_saving ? _save : null,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.gatesSave),
        ),
      ],
    );
  }
}
