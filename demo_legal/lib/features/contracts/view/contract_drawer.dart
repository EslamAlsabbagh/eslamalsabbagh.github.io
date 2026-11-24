import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/contract_item_kind.dart';
import '../../../core/domain/contract_kind.dart';
import '../../../core/domain/contract_status.dart';
import '../../../core/format/app_formats.dart';
import '../../../core/format/arabic_count.dart';
import '../../../core/format/text_direction.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/contract_text.dart';
import '../../../core/validation/task_text.dart';
import '../../../l10n/contract_l10n.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../tasks/bloc/tasks_bloc.dart';
import '../../tasks/bloc/new_task_bloc.dart' show NewTaskPreset;
import '../../tasks/data/live_changes.dart';
import '../../tasks/view/new_task_modal.dart';
import '../../tasks/view/task_drawer.dart';
import '../../tasks/view/widgets/confirm_dialog.dart';
import '../../tasks/view/widgets/drawer_frame.dart';
import '../../tasks/view/widgets/form_error_line.dart';
import '../bloc/contract_details_bloc.dart';
import '../bloc/contract_form_bloc.dart';
import '../bloc/contracts_bloc.dart';
import '../data/contract_details.dart';
import '../data/contract_record.dart';
import '../data/contract_save_failure.dart';
import '../data/contracts_repository.dart';
import 'annex_form_modal.dart';
import 'contract_form_modal.dart';
import 'widgets/contract_checklist.dart';
import 'widgets/contract_followups.dart';
import 'widgets/contract_history.dart';
import 'widgets/contract_sections.dart';
import 'widgets/contract_status_pill.dart';
import 'widgets/optional_date_box.dart';
import 'widgets/suggest_field.dart';
import '../../tasks/view/widgets/stored_text.dart';

/// «+ عقد جديد» in the header on «العقود»: the contract form, then the
/// drawer of what it saved.
Future<void> openNewContract(BuildContext context, {required DateTime Function() clock}) async {
  final shown = await openContractForm(context, clock: clock);
  if (shown != null && context.mounted) await showContractDrawer(context, shown, clock: clock);
}

/// Opens the contract drawer (DESIGN_SPEC §4 "Contract drawer") for the main
/// contract [contractId] of [fileId] (for the top bar while it loads).
///
/// The dialog route sits above the shell, so the shell's [TasksBloc] and
/// [ContractsBloc] are handed in: the first names the file and brand, the
/// second reloads the list after a change.
Future<void> showContractDrawer(
  BuildContext context,
  String contractId, {
  required DateTime Function() clock,
}) {
  final tasksBloc = context.read<TasksBloc>();
  final contractsBloc = context.read<ContractsBloc>();
  final repository = context.read<ContractsRepository>();
  final liveChanges = context.read<LiveChanges>();
  return showSideDrawer<void>(
    context,
    builder: (context) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: tasksBloc),
        BlocProvider.value(value: contractsBloc),
        BlocProvider(
          create: (_) => ContractDetailsBloc(
            contractId: contractId,
            repository: repository,
            liveChanges: liveChanges.changes,
          )..add(const ContractDetailsLoadRequested()),
        ),
      ],
      child: ContractDrawer(clock: clock),
    ),
  );
}

/// The drawer panel. Needs a [ContractDetailsBloc], and the shell's
/// [TasksBloc] and [ContractsBloc].
class ContractDrawer extends StatelessWidget {
  const ContractDrawer({super.key, required this.clock});

  /// "Now" for the history times and the termination date's default.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = context.select((ContractDetailsBloc bloc) => bloc.state.details);
    final files = context.select((TasksBloc bloc) => bloc.state.files);
    final topics = context.select((TasksBloc bloc) => bloc.state.topics);
    final fileName = files.where((f) => f.id == details?.fileId).firstOrNull?.name ?? '';
    final topicId = details?.topicId;
    final brand = topicId == null ? l10n.contractNoBrand : topics.where((t) => t.id == topicId).firstOrNull?.name ?? '';

    return MultiBlocListener(
      listeners: [
        // Each change shows in the list, its chips and badges.
        BlocListener<ContractDetailsBloc, ContractDetailsState>(
          listenWhen: (previous, current) => previous.revision != current.revision,
          listener: (context, _) => context.read<ContractsBloc>().add(const ContractsRefreshRequested()),
        ),
        BlocListener<ContractDetailsBloc, ContractDetailsState>(
          listenWhen: (previous, current) => !previous.deleted && current.deleted,
          listener: (context, _) => Navigator.of(context).pop(),
        ),
        // Midnight moves «تنتهي بعد …» and the list status.
        BlocListener<TasksBloc, TasksState>(
          listenWhen: (previous, current) => previous.dayRevision != current.dayRevision,
          listener: (context, _) => context.read<ContractDetailsBloc>().add(const ContractDetailsRefreshRequested()),
        ),
      ],
      child: DrawerFrame(
        panelKey: const Key('contract-drawer'),
        title: details == null ? '' : '$fileName / $brand',
        child: _Body(clock: clock, brand: brand),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.clock, required this.brand});

  final DateTime Function() clock;
  final String brand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final state = context.watch<ContractDetailsBloc>().state;
    final details = state.details;

    if (state.load == ContractDetailsLoad.failure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(l10n.contractLoadError, style: AppTextStyles.body.copyWith(color: tokens.ink)),
          OutlinedButton(
            key: const Key('contract-drawer-retry'),
            onPressed: () => context.read<ContractDetailsBloc>().add(const ContractDetailsLoadRequested()),
            style: quietOutlineButtonStyle(context),
            child: Text(l10n.retry),
          ),
        ],
      );
    }
    if (details == null || state.load == ContractDetailsLoad.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final failure = state.failure;
    final record = state.record;
    final ready = !state.busy && record != null;
    // Rows stay on a terminated contract; adding and renewing don't.
    final open = ready && details.status == ContractStatus.active;
    final annexes = sortedAnnexes(state.children);
    final storage = sortedStorage(state.children);
    final showAnnexes = annexes.isNotEmpty || open;
    final showStorage = details.kind == ContractKind.lease && (storage.isNotEmpty || open);
    final contractIds = {details.id, for (final child in state.children) child.id};
    final tasks = context.select((TasksBloc bloc) => bloc.state.tasks);
    final followUps = followUpsOf(tasks, contractIds);
    // A brandless contract can't hold follow-ups (`tasks_contract_topic`).
    final canFollowUp = open && details.topicId != null;
    final bloc = context.read<ContractDetailsBloc>();
    // Not tied to busy: the checklist's add row stays open while its own
    // write is in flight, and waits on [ContractChecklistSection.busy].
    final itemsEditable = record != null && details.status == ContractStatus.active;
    final targets = checklistTargets(l10n, details.id, annexes: annexes, storage: storage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.drawerGap,
      children: [
        _Head(details: details, brand: brand, onEdit: ready ? () => _edit(context) : null),
        _Details(details: details),
        if (showAnnexes)
          ContractAnnexesSection(
            annexes: annexes,
            onOpen: ready ? (annex) => _annex(context, annex: annex) : null,
            onAdd: open ? () => _annex(context) : null,
          ),
        if (showStorage)
          ContractStorageSection(
            storage: storage,
            onOpen: ready ? (s) => _storage(context, record: s) : null,
            onRenew: open
                ? (s) => _storage(context, preset: StoragePreset(fileId: details.fileId, leaseId: details.id, renewing: s))
                : null,
            onAdd: open ? () => _storage(context, preset: StoragePreset(fileId: details.fileId, leaseId: details.id)) : null,
          ),
        if (ContractChecklistSection.shows(items: state.items, editable: itemsEditable))
          ContractChecklistSection(
            items: state.items,
            targets: targets,
            partyId: details.partyId,
            busy: state.busy,
            failure: state.itemFailure,
            fetchLabels: (query) async => [
              for (final row in await bloc.suggestItemLabels(query)) SuggestOption(value: row.value, label: row.value),
            ],
            onToggle: open ? (item, resolved) => bloc.add(ContractItemToggled(item.id, resolved: resolved)) : null,
            onDelete: open ? (item) => bloc.add(ContractItemDeleted(item.id)) : null,
            onAdd: itemsEditable ? (input) => bloc.add(ContractItemAdded(input)) : null,
          ),
        if (followUps.isNotEmpty || canFollowUp)
          ContractFollowUpsSection(
            tasks: followUps,
            onOpen: (task) => showTaskDrawer(context, task, clock: clock, fromContractId: details.id),
            onAdd: canFollowUp ? () => _followUp(context) : null,
          ),
        ContractHistory(
          entries: state.activity,
          contractId: details.id,
          now: clock(),
          annexNumbers: {for (final annex in annexes) annex.id: ?annex.annexNo},
          targetLabels: {for (final t in targets.skip(1)) t.id: t.label},
        ),
        _Actions(state: state, clock: clock),
        if (failure != null) FormErrorLine(_message(l10n, failure), key: const Key('contract-drawer-error')),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<ContractDetailsBloc>();
    final saved = await openContractForm(context, clock: clock, record: bloc.state.record);
    if (saved != null && !bloc.isClosed) bloc.add(const ContractDetailsRefreshRequested());
  }

  /// The annex form: [annex] to edit, or a new annex.
  Future<void> _annex(BuildContext context, {ContractRecord? annex}) async {
    final bloc = context.read<ContractDetailsBloc>();
    final state = bloc.state;
    final changed = await openAnnexForm(
      context,
      clock: clock,
      parent: state.details!,
      parentRecord: state.record!,
      annexes: sortedAnnexes(state.children),
      annex: annex,
    );
    if (changed != null && !bloc.isClosed) bloc.add(const ContractDetailsRefreshRequested());
  }

  /// The contract form on a storage contract under this lease: [record] to
  /// edit, or a new one from [preset] (added or renewed).
  Future<void> _storage(BuildContext context, {ContractRecord? record, StoragePreset? preset}) async {
    final bloc = context.read<ContractDetailsBloc>();
    final changed = await openContractForm(context, clock: clock, record: record, preset: preset);
    if (changed != null && !bloc.isClosed) bloc.add(const ContractDetailsRefreshRequested());
  }

  /// «+ إضافة متابعة»: the new-task modal with the file, brand and contract
  /// fixed, its title filled while the client still owes a signature or
  /// stamp.
  Future<void> _followUp(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<ContractDetailsBloc>();
    final contractsBloc = context.read<ContractsBloc>();
    final state = bloc.state;
    final details = state.details!;
    final clientOwes = state.items.any(
      (i) => i.kind == ContractItemKind.missing && !i.isResolved && i.side == ContractItemSide.client,
    );
    final id = await openNewTaskModal(
      context,
      clock: clock,
      preset: NewTaskPreset(
        fileId: details.fileId,
        topicId: details.topicId!,
        contractId: details.id,
        contractLabel: contractName(l10n, kind: details.kind, subject: details.subject),
        title: clientOwes ? l10n.followUpDefaultTitle : '',
      ),
    );
    if (id == null) return;
    if (!bloc.isClosed) bloc.add(const ContractDetailsRefreshRequested());
    if (!contractsBloc.isClosed) contractsBloc.add(const ContractsRefreshRequested());
  }

  static String _message(AppLocalizations l10n, ContractSaveFailure failure) => switch (failure) {
        ContractSaveFailure.notAllowed => l10n.contractActionNotAllowed,
        ContractSaveFailure.notEmpty => l10n.contractDeleteNotEmpty,
        ContractSaveFailure.network => l10n.loginErrorNetwork,
        _ => l10n.saveErrorUnknown,
      };
}

/// The status pill, the brand (Readex 22/600) with «تعديل» at the row's
/// `end`, and the subject under it (15 `textMuted`).
class _Head extends StatelessWidget {
  const _Head({required this.details, required this.brand, required this.onEdit});

  final ContractDetails details;
  final String brand;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        ContractStatusPill(details.listStatus),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  brand,
                  textDirection: textDirectionOf(brand),
                  textAlign: TextAlign.start,
                  style: AppTextStyles.drawerTitle.copyWith(
                    color: details.topicId == null ? tokens.textMuted : tokens.ink,
                  ),
                ),
              ),
            ),
            TextButton.icon(
              key: const Key('contract-edit'),
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: tokens.ink,
                textStyle: AppTextStyles.button,
                minimumSize: const Size(0, AppSpacing.touchTarget),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l10n.editTask),
            ),
          ],
        ),
        if (details.subject.isNotEmpty)
          StoredText(details.subject, style: AppTextStyles.body.copyWith(color: tokens.textMuted)),
      ],
    );
  }
}

/// The details grid: label (13 `textMuted`) over value (15), two columns,
/// one on a phone. Values are effective ones; a value an annex set ends
/// with «(بموجب ملحق n)».
class _Details extends StatelessWidget {
  const _Details({required this.details});

  final ContractDetails details;

  static const double _twoColumnWidth = 200 * 2 + 14;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final d = details;
    final value = AppTextStyles.body.copyWith(color: tokens.ink);
    final none = AppTextStyles.body.copyWith(color: tokens.textMuted);

    Widget text(String? shown, {int? annexNo, bool ltr = false}) {
      final empty = shown == null || shown.trim().isEmpty;
      return Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (empty)
            Text(l10n.contractValueNone, style: none)
          else
            Text(shown, textDirection: ltr ? TextDirection.ltr : textDirectionOf(shown), style: value),
          if (annexNo != null) _ByAnnex(annexNo),
        ],
      );
    }

    String? date(DateTime? value) => value == null ? null : AppFormats.fullDate(value);
    String? area(double? value) => value == null ? null : l10n.contractArea(AppFormats.number(value));

    final ends = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        if (d.endsOn != null || d.dateNote.isEmpty) text(date(d.endsOn), annexNo: d.endsOnAnnexNo),
        if (d.endsOn == null && d.dateNote.isNotEmpty)
          StoredText(d.dateNote, style: value)
        else if (d.daysUntilEnd case final days?)
          Text(
            _endLabel(l10n, days),
            key: const Key('contract-end-label'),
            style: AppTextStyles.meta.copyWith(color: days < 0 ? tokens.overdue : tokens.textMuted),
          ),
      ],
    );

    final noAreas = d.areaInner == null && d.areaOuter == null;
    final cells = <(String, Widget)>[
      (l10n.contractFieldParty, text(d.partyName, annexNo: d.partyAnnexNo)),
      (
        l10n.contractFieldUnits,
        d.unitCodes.isEmpty
            ? text(null)
            : Wrap(
                spacing: 10,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final code in d.unitCodes) Text(code, textDirection: TextDirection.ltr, style: value),
                  if (d.unitsAnnexNo case final n?) _ByAnnex(n),
                ],
              ),
      ),
      (l10n.contractFieldActivity, text(d.activity)),
      (l10n.contractFieldSigned, text(date(d.signedOn))),
      if (d.startsOn != null && d.startsOn != d.signedOn) (l10n.contractFieldStarts, text(date(d.startsOn))),
      (l10n.contractFieldEnds, ends),
      (l10n.contractFieldDuration, text(d.durationMonths == null ? null : contractDuration(l10n, d.durationMonths!))),
      if (noAreas && d.areaNote.isNotEmpty)
        (l10n.contractFieldArea, StoredText(d.areaNote, style: value))
      else ...[
        (l10n.contractFieldAreaInner, text(area(d.areaInner), annexNo: d.areaInnerAnnexNo)),
        (l10n.contractFieldAreaOuter, text(area(d.areaOuter), annexNo: d.areaOuterAnnexNo)),
      ],
      if (d.status == ContractStatus.terminated) ...[
        (l10n.contractFieldTerminated, text(date(d.terminatedOn))),
        (l10n.contractFieldReason, text(d.terminationReason)),
      ],
    ];

    Widget cell((String, Widget) item) => MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(item.$1, style: AppTextStyles.meta.copyWith(color: tokens.textMuted)),
              item.$2,
            ],
          ),
        );

    final notes = d.notes.isEmpty
        ? null
        : cell((l10n.contractFieldNotes, StoredText(d.notes, style: value.copyWith(height: 1.8))));

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _twoColumnWidth;
        return Column(
          key: Key(wide ? 'contract-details-2' : 'contract-details-1'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            if (wide)
              for (var i = 0; i < cells.length; i += 2)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 14,
                  children: [
                    Expanded(child: cell(cells[i])),
                    Expanded(child: i + 1 < cells.length ? cell(cells[i + 1]) : const SizedBox.shrink()),
                  ],
                )
            else
              for (final item in cells) cell(item),
            ?notes,
          ],
        );
      },
    );
  }
}

/// «(بموجب ملحق ٢)» after a value an annex set.
class _ByAnnex extends StatelessWidget {
  const _ByAnnex(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).contractByAnnex(AppFormats.number(number)),
      style: AppTextStyles.meta.copyWith(color: context.tokens.textMuted),
    );
  }
}

/// «تنتهي بعد ٣ أشهر» / «انتهت منذ ١٢ يومًا» / «تنتهي اليوم»: days under 60,
/// then months (30 days) under two years, then years.
String _endLabel(AppLocalizations l10n, int days) {
  if (days == 0) return l10n.contractEndsToday;
  final n = days.abs();
  final String time;
  if (n < 60) {
    time = arabicCount(n, one: l10n.relDaysOne, two: l10n.relDaysTwo, few: l10n.relDaysFew, many: l10n.relDaysMany);
  } else if (n < 730) {
    time = arabicCount(n ~/ 30,
        one: l10n.relMonthsOne, two: l10n.relMonthsTwo, few: l10n.relMonthsFew, many: l10n.relMonthsMany);
  } else {
    time = arabicCount(n ~/ 365,
        one: l10n.relYearsOne, two: l10n.relYearsTwo, few: l10n.relYearsFew, many: l10n.relYearsMany);
  }
  return days > 0 ? l10n.contractEndsIn(time) : l10n.contractEndedAgo(time);
}

/// The bottom: «إنهاء العقد» on an active contract, with «حذف العقد» while
/// nothing hangs on it, and «إعادة تفعيل» on a terminated one for managers
/// and admins.
class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.clock});

  final ContractDetailsState state;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<ContractDetailsBloc>();
    final managesFiles = context.select((AuthBloc bloc) => bloc.state.profile?.role.managesFiles ?? false);
    final status = state.details!.status;
    final busy = state.busy;
    final outline = quietOutlineButtonStyle(context);

    final buttons = <Widget>[
      if (status == ContractStatus.active) ...[
        OutlinedButton(
          key: const Key('contract-terminate'),
          onPressed: busy ? null : () => _terminate(context, bloc),
          style: outline,
          child: Text(l10n.contractTerminate),
        ),
        if (state.record?.canDelete ?? false)
          OutlinedButton(
            key: const Key('contract-delete'),
            onPressed: busy ? null : () => _delete(context, bloc),
            style: outline,
            child: Text(l10n.contractDelete),
          ),
      ],
      if (status == ContractStatus.terminated && managesFiles)
        OutlinedButton(
          key: const Key('contract-reopen'),
          onPressed: busy ? null : () => bloc.add(const ContractDetailsReopened()),
          style: outline,
          child: Text(l10n.contractReopen),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 10, runSpacing: 10, children: buttons);
  }

  Future<void> _delete(BuildContext context, ContractDetailsBloc bloc) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.contractDeleteTitle,
      body: l10n.contractDeleteBody,
      backLabel: l10n.cancelTaskBack,
      confirmLabel: l10n.contractDelete,
      keyPrefix: 'contract-delete',
    );
    if (confirmed && !bloc.isClosed) bloc.add(const ContractDetailsDeleteConfirmed());
  }

  Future<void> _terminate(BuildContext context, ContractDetailsBloc bloc) async {
    final today = context.read<TasksBloc>().state.cairoToday(clock());
    final result = await showDialog<(DateTime, String)>(
      context: context,
      barrierColor: context.tokens.scrim,
      builder: (_) => _TerminateDialog(today: today),
    );
    if (result != null && !bloc.isClosed) {
      bloc.add(ContractDetailsTerminated(on: result.$1, reason: result.$2));
    }
  }
}

/// «إنهاء العقد»: the termination date (today by default) and a required
/// one-line reason, then «رجوع» / «إنهاء العقد».
class _TerminateDialog extends StatefulWidget {
  const _TerminateDialog({required this.today});

  final DateTime today;

  @override
  State<_TerminateDialog> createState() => _TerminateDialogState();
}

class _TerminateDialogState extends State<_TerminateDialog> {
  late DateTime _on = widget.today;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _canConfirm => ContractText.isFilled(_reason.text, ContractText.reasonMax);

  void _confirm() {
    if (_canConfirm) Navigator.of(context).pop((_on, _reason.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: tokens.surface,
      surfaceTintColor: tokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.modal)),
      titlePadding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 0),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 0),
      actionsPadding: const EdgeInsetsDirectional.all(20),
      title: Text(l10n.contractTerminate, style: AppTextStyles.sectionTitle.copyWith(color: tokens.ink)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Text(l10n.contractTerminateBody, style: AppTextStyles.body.copyWith(color: tokens.ink)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                ExcludeSemantics(
                  child: Text(l10n.contractFieldTerminated,
                      style: AppTextStyles.fieldLabel.copyWith(color: tokens.textMuted)),
                ),
                OptionalDateBox(
                  keyName: 'terminate-date',
                  label: l10n.contractPickTerminated,
                  date: _on,
                  initialDate: widget.today,
                  onPicked: (date) => setState(() => _on = date),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                ExcludeSemantics(
                  child: Text(l10n.contractFieldReason, style: AppTextStyles.fieldLabel.copyWith(color: tokens.textMuted)),
                ),
                Semantics(
                  label: l10n.contractFieldReason,
                  child: TextField(
                    key: const Key('terminate-reason'),
                    controller: _reason,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _confirm(),
                    textDirection: textDirectionOf(_reason.text),
                    maxLines: 1,
                    style: AppTextStyles.body.copyWith(color: tokens.ink),
                    decoration: InputDecoration(hintText: l10n.contractReasonHint),
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' '),
                      const CodePointLimitFormatter(ContractText.reasonMax),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          key: const Key('terminate-back'),
          onPressed: () => Navigator.of(context).pop(),
          style: quietOutlineButtonStyle(context),
          child: Text(l10n.cancelTaskBack),
        ),
        FilledButton(
          key: const Key('terminate-confirm'),
          onPressed: _canConfirm ? _confirm : null,
          child: Text(l10n.contractTerminate),
        ),
      ],
    );
  }
}
