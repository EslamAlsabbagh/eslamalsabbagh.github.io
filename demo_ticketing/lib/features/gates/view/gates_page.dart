import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/clock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/gates_cubit.dart';
import '../data/gate_models.dart';
import '../data/gates_repository.dart';
import 'controller_dialog.dart';
import 'gates_messages.dart';

/// Gates & controllers (task 4.6, `Gates.dc.html`): the controllers with their
/// status, every gate with its wiring and today's scans, an edit panel, and a
/// test open that reaches the gate's service (ADR-0035). Admins only. Each
/// save and each test open is logged in the actions log.
class GatesPage extends StatelessWidget {
  const GatesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => GatesCubit(context.read<GatesRepository>())..start(),
    child: const _GatesView(),
  );
}

class _GatesView extends StatelessWidget {
  const _GatesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<GatesCubit>().state;
    final cubit = context.read<GatesCubit>();
    final overview = state.overview;

    final Widget body;
    if (overview == null) {
      final failure = state.loadFailure;
      body = failure == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.gatesLoading, style: TextStyle(color: tokens.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Text(
                    gatesFailureMessage(l10n, failure),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (failure != GatesFailureKind.notAllowed)
                    FilledButton(onPressed: cubit.refresh, child: Text(l10n.retry)),
                ],
              ),
            );
    } else {
      // Rebuilt for another gate, so its fields start from it.
      final panel = _EditPanel(
        key: ValueKey(state.creating ? 'gates-panel-new' : 'gates-panel-${state.selectedId}'),
        gate: state.selected,
        controllers: overview.controllers,
      );
      final left = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ControllersCard(overview: overview),
          const SizedBox(height: 18),
          _Table(overview: overview, state: state),
        ],
      );
      body = LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [left, const SizedBox(height: 18), panel],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  key: const ValueKey('gates-table-scroll'),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: left,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: panel,
                ),
              ),
            ],
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.navGates,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l10n.gatesSubtitle,
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.actionsRefresh,
                    onPressed: state.loading ? null : cubit.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: AppSizes.touchTarget,
                    child: FilledButton.icon(
                      key: const ValueKey('gates-new'),
                      onPressed: overview == null || state.creating ? null : cubit.startNew,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        l10n.gatesNew,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// A status chip with its dot, as on the dashboard's gate cards.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg, required this.dot});

  final String label;
  final Color bg;
  final Color fg;
  final Color dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ),
      ],
    ),
  );
}

class _ControllersCard extends StatelessWidget {
  const _ControllersCard({required this.overview});

  final GatesOverview overview;

  /// The design's `repeat(auto-fit, minmax(260px, 1fr))`.
  static const _minTile = 260.0;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final now = context.read<Clock>().now();
    final cubit = context.read<GatesCubit>();

    // Entry gates switched on, and how many of their services beat.
    final watched = [
      for (final g in overview.gates)
        if (g.direction == GateDirection.entry && g.enabled) g,
    ];
    final running = watched.where((g) => g.status == GateStatus.online).length;

    Future<void> edit(AdminController? controller) =>
        showControllerDialog(context, cubit: cubit, controller: controller);

    return Container(
      key: const ValueKey('gates-controllers'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The title and the services line wrap; the button keeps its place.
          Row(
            children: [
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      l10n.gatesControllersTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      l10n.gatesServicesLine(running, watched.length),
                      key: const ValueKey('gates-services-line'),
                      style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                key: const ValueKey('gates-add-controller'),
                onPressed: () => edit(null),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.gatesAddController),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (overview.controllers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.gatesNoControllers,
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.textSecondary),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = ((constraints.maxWidth + _gap) / (_minTile + _gap)).floor().clamp(
                  1,
                  overview.controllers.length,
                );
                final width = (constraints.maxWidth - _gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: _gap,
                  runSpacing: _gap,
                  children: [
                    for (final c in overview.controllers)
                      SizedBox(
                        width: width,
                        child: _ControllerTile(controller: c, now: now, onTap: () => edit(c)),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ControllerTile extends StatelessWidget {
  const _ControllerTile({required this.controller, required this.now, required this.onTap});

  final AdminController controller;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final (bg, fg, dot) = switch (controller.status) {
      ControllerStatus.online => (tokens.successBg, tokens.successText, tokens.successDot),
      ControllerStatus.offline ||
      ControllerStatus.neverSeen => (tokens.dangerBg, tokens.dangerText, tokens.dangerAction),
      ControllerStatus.noEntryGate => (tokens.bg, tokens.textMuted, tokens.inputBorder),
    };
    final address = [
      controller.ip ?? l10n.controllerNoIp,
      l10n.controllerDoors(controller.doorCount),
    ].join(' · ');

    return Material(
      color: tokens.inset,
      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      child: InkWell(
        key: ValueKey('controller-${controller.id}'),
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.label,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      // An IP reads left to right in both languages.
                      Text(
                        address,
                        textDirection: controller.ip == null ? null : TextDirection.ltr,
                        style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: _Pill(
                    label: controllerStatusText(l10n, controller, now),
                    bg: bg,
                    fg: fg,
                    dot: dot,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.overview, required this.state});

  final GatesOverview overview;
  final GatesState state;

  static const _flex = [3, 2, 3, 3, 2];

  static Widget cells(List<Widget> children) => Row(
    children: [
      for (var i = 0; i < children.length; i++)
        Expanded(
          flex: _flex[i],
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: children[i]),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final header = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: tokens.textSecondary,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: cells([
                Text(l10n.gatesColGate, style: header),
                Text(l10n.gatesColDirection, style: header),
                Text(l10n.gatesColWiring, style: header),
                Text(l10n.gatesColToday, style: header),
                Text(l10n.gatesColStatus, style: header),
              ]),
            ),
            if (overview.gates.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.gatesEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ),
            for (final gate in overview.gates) _row(context, gate),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AdminGate gate) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final now = context.read<Clock>().now();
    final selected = !state.creating && state.selectedId == gate.id;
    final (bg, fg, dot) = switch (gate.status) {
      GateStatus.online => (tokens.successBg, tokens.successText, tokens.successDot),
      GateStatus.offline ||
      GateStatus.neverSeen => (tokens.dangerBg, tokens.dangerText, tokens.dangerAction),
      GateStatus.disabled => (tokens.bg, tokens.textMuted, tokens.inputBorder),
      GateStatus.exit => (tokens.inset, tokens.textSecondary, tokens.inputBorder),
    };
    final down = gate.status == GateStatus.offline || gate.status == GateStatus.neverSeen;

    return DecoratedBox(
      key: ValueKey('gate-row-${gate.id}'),
      decoration: BoxDecoration(
        color: selected ? tokens.primaryTint : null,
        border: Border(top: BorderSide(color: tokens.rowDivider)),
      ),
      child: InkWell(
        onTap: () => context.read<GatesCubit>().select(gate.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: cells([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gate.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    gateNote(l10n, gate, overview.now, now),
                    style: TextStyle(
                      fontSize: 12,
                      color: down ? tokens.dangerText : tokens.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(directionText(l10n, gate.direction), style: const TextStyle(fontSize: 14)),
              Text(
                wiringText(l10n, gate.controllerName, gate.doorNumber),
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                gate.direction == GateDirection.exit
                    ? '—'
                    : l10n.gatesToday(gate.entries, gate.rejected),
                style: const TextStyle(fontSize: 14),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _Pill(label: gateStatusText(l10n, gate.status), bg: bg, fg: fg, dot: dot),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The edit panel. Its fields start from [gate], or empty for a new one; the
/// page gives it a new key per gate, so switching rows drops unsaved edits
/// (as the design).
class _EditPanel extends StatefulWidget {
  const _EditPanel({super.key, required this.gate, required this.controllers});

  /// Null for a new gate.
  final AdminGate? gate;
  final List<AdminController> controllers;

  @override
  State<_EditPanel> createState() => _EditPanelState();
}

class _EditPanelState extends State<_EditPanel> {
  late final _name = TextEditingController(text: widget.gate?.name ?? '');
  late final _door = TextEditingController(text: '${widget.gate?.doorNumber ?? ''}');
  late final _open = TextEditingController(text: '${widget.gate?.openSeconds ?? 2}');
  late final _reader = TextEditingController(text: widget.gate?.reader ?? '');
  late GateDirection _direction = widget.gate?.direction ?? GateDirection.entry;
  late String? _controllerId = widget.gate?.controllerId;
  late bool _enabled = widget.gate?.enabled ?? true;

  /// The server's last refusal, shown on its field or in the banner.
  GatesFailureKind? _failure;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _door, _open, _reader]) {
      c.addListener(_changed);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _door, _open, _reader]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() => _failure = null);

  int? get _doorValue => int.tryParse(_door.text.trim());
  int? get _openValue => int.tryParse(_open.text.trim());

  /// The panel's values, or null while one is missing or wrong.
  GateDraft? get _draft {
    final open = _openValue;
    final door = _doorValue;
    if (_name.text.trim().isEmpty) return null;
    if (open == null || open < 1 || open > 10) return null;
    if (_controllerId != null && (door == null || door < 1)) return null;
    return GateDraft(
      name: _name.text.trim(),
      direction: _direction,
      controllerId: _controllerId,
      doorNumber: _controllerId == null ? null : door,
      openSeconds: open,
      reader: _reader.text.trim().isEmpty ? null : _reader.text.trim(),
      enabled: _enabled,
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failure = await context.read<GatesCubit>().saveGate(draft);
    if (!mounted) return;
    if (failure == null) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.typesSaved)));
    } else {
      setState(() => _failure = failure);
    }
  }

  Future<void> _testOpen(AdminGate gate) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failure = await context.read<GatesCubit>().testOpen(gate.id);
    if (failure != null) {
      messenger?.showSnackBar(SnackBar(content: Text(gatesFailureMessage(l10n, failure))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final saving = context.select((GatesCubit c) => c.state.saving);
    final progress = context.select((GatesCubit c) => c.state.testOpen);
    final gate = widget.gate;
    final draft = _draft;
    final changed = draft != null && (gate == null || !draft.sameAs(gate.draft));

    // Format errors only on something typed; an empty field just keeps Save off.
    final openError =
        _open.text.trim().isNotEmpty && !((_openValue ?? 0) >= 1 && (_openValue ?? 0) <= 10)
        ? l10n.gatesInvalidOpenSeconds
        : null;
    final failureText = _failure == null ? null : gatesFailureMessage(l10n, _failure!);
    final nameFailure = switch (_failure) {
      GatesFailureKind.nameTaken || GatesFailureKind.invalidName => true,
      _ => false,
    };
    final doorFailure = switch (_failure) {
      GatesFailureKind.doorTaken ||
      GatesFailureKind.doorNotOnController ||
      GatesFailureKind.invalidWiring => true,
      _ => false,
    };
    final openFailure = _failure == GatesFailureKind.invalidOpenSeconds;

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

    Widget note(String text, Color bg, Color fg, {Key? key}) => Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, color: fg)),
    );

    // Test open uses the saved gate, so it waits for nothing in the panel.
    final mine = gate != null && progress != null && progress.gateId == gate.id ? progress : null;
    final testBusy = progress?.busy ?? false;
    final String? testOffReason = switch (gate) {
      null => null,
      final g when g.direction == GateDirection.exit => l10n.gatesTestOpenExit,
      final g when !g.wired => l10n.gatesTestOpenNotWired,
      _ => null,
    };
    final (testBg, testFg) = switch (mine?.phase) {
      TestOpenPhase.opened => (tokens.successBg, tokens.successText),
      TestOpenPhase.failed || TestOpenPhase.noAnswer => (tokens.dangerBg, tokens.dangerText),
      _ => (tokens.primaryTint, tokens.onPrimaryTint),
    };

    final controllerIds = {for (final c in widget.controllers) c.id};

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              gate == null ? l10n.gatesNew : l10n.gatesEditTitle(gate.name),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            field(
              l10n.gatesName,
              TextField(
                key: const ValueKey('gates-name'),
                controller: _name,
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
                decoration: decoration(error: nameFailure ? failureText : null),
              ),
            ),
            const SizedBox(height: 12),
            field(
              l10n.gatesDirectionLabel,
              SegmentedButton<GateDirection>(
                key: const ValueKey('gates-direction'),
                showSelectedIcon: false,
                segments: [
                  for (final d in GateDirection.values)
                    ButtonSegment(value: d, label: Text(directionText(l10n, d))),
                ],
                selected: {_direction},
                onSelectionChanged: (value) => setState(() {
                  _direction = value.first;
                  _failure = null;
                }),
              ),
            ),
            const SizedBox(height: 12),
            pair(
              field(
                l10n.gatesController,
                DropdownButtonFormField<String?>(
                  key: const ValueKey('gates-controller'),
                  initialValue: controllerIds.contains(_controllerId) ? _controllerId : null,
                  isExpanded: true,
                  decoration: decoration(),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(l10n.gatesNotWired)),
                    for (final c in widget.controllers)
                      DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.label, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _controllerId = value;
                    if (value == null) _door.clear();
                    _failure = null;
                  }),
                ),
              ),
              field(
                l10n.gatesDoor,
                TextField(
                  key: const ValueKey('gates-door'),
                  controller: _door,
                  enabled: _controllerId != null,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  decoration: decoration(error: doorFailure ? failureText : null),
                ),
              ),
            ),
            const SizedBox(height: 12),
            pair(
              field(
                l10n.gatesOpenSeconds,
                TextField(
                  key: const ValueKey('gates-open-seconds'),
                  controller: _open,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: decoration(error: openError ?? (openFailure ? failureText : null)),
                ),
              ),
              field(
                l10n.gatesReader,
                TextField(
                  key: const ValueKey('gates-reader'),
                  controller: _reader,
                  inputFormatters: [LengthLimitingTextInputFormatter(60)],
                  decoration: decoration(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          l10n.gatesEnabledLabel,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          l10n.gatesEnabledNote,
                          style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const ValueKey('gates-enabled'),
                    value: _enabled,
                    onChanged: (value) => setState(() {
                      _enabled = value;
                      _failure = null;
                    }),
                  ),
                ],
              ),
            ),
            if (gate != null && gate.homeOf.isNotEmpty) ...[
              const SizedBox(height: 14),
              note(
                l10n.gatesHomeGateNote(gate.homeOf.join('، ')),
                tokens.warningBg,
                tokens.warningText,
                key: const ValueKey('gates-home-note'),
              ),
            ],
            if (gate != null &&
                gate.direction == GateDirection.entry &&
                gate.status == GateStatus.online &&
                _direction == GateDirection.exit) ...[
              const SizedBox(height: 14),
              note(
                l10n.gatesExitStopsService,
                tokens.warningBg,
                tokens.warningText,
                key: const ValueKey('gates-exit-note'),
              ),
            ],
            if (failureText != null && !nameFailure && !doorFailure && !openFailure) ...[
              const SizedBox(height: 14),
              note(
                failureText,
                tokens.dangerBg,
                tokens.dangerText,
                key: const ValueKey('gates-failure'),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (gate != null) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        key: const ValueKey('gates-test-open'),
                        onPressed: testOffReason == null && !testBusy
                            ? () => _testOpen(gate)
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: tokens.inputBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                          ),
                        ),
                        child: Text(
                          l10n.gatesTestOpen,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      key: const ValueKey('gates-save'),
                      onPressed: changed && !saving ? _save : null,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                        ),
                      ),
                      child: saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              gate == null ? l10n.gatesAdd : l10n.gatesSave,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            if (testOffReason != null) ...[
              const SizedBox(height: 8),
              Text(
                testOffReason,
                key: const ValueKey('gates-test-off'),
                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
              ),
            ],
            if (mine != null) ...[
              const SizedBox(height: 12),
              note(
                testOpenText(l10n, mine)!,
                testBg,
                testFg,
                key: const ValueKey('gates-test-result'),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.typesLogNote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
