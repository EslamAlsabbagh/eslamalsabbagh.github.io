import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/contract_kind.dart';
import '../../../core/format/arabic_normalize.dart';
import '../../../core/format/text_direction.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/contract_text.dart';
import '../../../core/validation/name_text.dart';
import '../../../core/validation/task_text.dart';
import '../../../l10n/contract_l10n.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tasks/bloc/tasks_bloc.dart';
import '../../tasks/data/name_save_failure.dart';
import '../../tasks/data/task_topic.dart';
import '../../tasks/data/tasks_repository.dart';
import '../../tasks/view/widgets/confirm_dialog.dart';
import '../../tasks/view/widgets/field_box.dart';
import '../../tasks/view/widgets/form_error_line.dart';
import '../../tasks/view/widgets/form_modal.dart';
import '../../tasks/view/widgets/labeled_field.dart';
import '../../tasks/view/widgets/select_box.dart';
import '../bloc/contract_form_bloc.dart';
import '../bloc/contracts_bloc.dart';
import '../data/contract_record.dart';
import '../data/contract_refs.dart';
import '../data/contract_save_failure.dart';
import '../data/contracts_repository.dart';
import 'widgets/optional_date_box.dart';
import 'widgets/quiet_chip.dart';
import 'widgets/record_fields.dart';
import 'widgets/suggest_field.dart';

/// Opens the contract form: a new contract, [record] to edit, or a storage
/// contract under a lease ([preset], from the lease's drawer). Built from
/// the shell's loaded files, topics and contracts. Returns the id of the
/// main contract to show (the saved one, or the lease a storage contract
/// hangs under, also after «حذف عقد المخزن»), or null when nothing changed;
/// the contracts list is asked to reload after a change.
Future<String?> openContractForm(
  BuildContext context, {
  required DateTime Function() clock,
  ContractRecord? record,
  StoragePreset? preset,
}) async {
  final tasksBloc = context.read<TasksBloc>();
  final contractsBloc = context.read<ContractsBloc>();
  final tasks = tasksBloc.state;
  final l10n = AppLocalizations.of(context);
  final savedId = await showDialog<String>(
    context: context,
    barrierColor: context.tokens.scrim,
    barrierLabel: l10n.drawerClose,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: tasksBloc),
        BlocProvider(
          create: (_) => ContractFormBloc(
            files: tasks.files,
            topics: tasks.topics,
            contracts: contractsBloc.state.contracts,
            initialFileId: tasks.selectedFileId,
            defaultSubjects: {for (final kind in ContractKind.values) kind: kind.defaultSubject(l10n)},
            repository: context.read<ContractsRepository>(),
            tasksRepository: context.read<TasksRepository>(),
            record: record,
            preset: preset,
          ),
        ),
      ],
      child: ContractFormModal(today: tasks.cairoToday(clock())),
    ),
  );
  if (savedId != null && !contractsBloc.isClosed) contractsBloc.add(const ContractsRefreshRequested());
  return savedId;
}

/// «عقد جديد» / «تعديل العقد» (DESIGN_SPEC §4 "Contract form"): the kind
/// chips, then the fields in two columns when the modal is at least 454
/// inside, then «حفظ العقد» / «إلغاء». Leaving with changes asks first;
/// nothing closes it while saving. Closes with the saved contract's id.
class ContractFormModal extends StatefulWidget {
  const ContractFormModal({super.key, required this.today});

  /// The Cairo date, where the date pickers open when a date is empty.
  final DateTime today;

  static const double width = 640;

  /// As the new-task modal's two columns.
  static const double twoColumnWidth = 220 * 2 + 14;

  @override
  State<ContractFormModal> createState() => _ContractFormModalState();
}

class _ContractFormModalState extends State<ContractFormModal> {
  late final ContractFormBloc _bloc = context.read<ContractFormBloc>();
  late final _subject = TextEditingController(text: _bloc.state.draft.subject);
  late final _activity = TextEditingController(text: _bloc.state.draft.activity);
  late final _dateNote = TextEditingController(text: _bloc.state.draft.dateNote);
  late final _areaInner = TextEditingController(text: _bloc.state.draft.areaInner);
  late final _areaOuter = TextEditingController(text: _bloc.state.draft.areaOuter);
  late final _areaNote = TextEditingController(text: _bloc.state.draft.areaNote);
  late final _notes = TextEditingController(text: _bloc.state.draft.notes);

  /// The error of the brand's «+ إضافة», under the field (the tenant and
  /// units fields keep their own).
  String? _brandError;

  /// «حذف عقد المخزن» is in flight, or failed with this.
  bool _deleting = false;
  ContractSaveFailure? _deleteFailure;

  @override
  void dispose() {
    for (final controller in [_subject, _activity, _dateNote, _areaInner, _areaOuter, _areaNote, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _text(ContractTextField field, String text) => _bloc.add(ContractFormTextChanged(field, text));

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.discardEditTitle,
      body: _bloc.isEditing ? l10n.contractDiscardEditBody : l10n.contractDiscardBody,
      backLabel: l10n.discardEditBack,
      confirmLabel: l10n.discardEditConfirm,
      keyPrefix: 'contract-discard',
    );
    if (discard && mounted) navigator.pop();
  }

  /// «حذف عقد المخزن»: a storage contract under a lease made by mistake,
  /// while nothing hangs on it. Closes with the lease's id.
  Future<void> _deleteStorage() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final record = _bloc.record!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.storageDeleteTitle,
      body: l10n.storageDeleteBody,
      backLabel: l10n.cancelTaskBack,
      confirmLabel: l10n.storageDelete,
      keyPrefix: 'storage-delete',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _deleting = true;
      _deleteFailure = null;
    });
    try {
      await _bloc.deleteRecord();
      if (mounted) navigator.pop(record.parentId);
    } on ContractSaveException catch (error) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _deleteFailure = error.failure;
        });
      }
    }
  }

  // Suggest fields --------------------------------------------------------------------------------------------

  Future<List<SuggestOption<TaskTopic>>> _brands(String query) async {
    final key = normalizeAr(query);
    return [
      for (final topic in _bloc.matchTopics(query))
        SuggestOption(value: topic, label: topic.name, exact: normalizeAr(topic.name) == key),
    ];
  }

  /// «+ إضافة» on the brand: a new topic in the file, as «+ موضوع جديد».
  Future<List<TaskTopic>?> _addBrand(SuggestAddRequest<TaskTopic> request) async {
    final l10n = AppLocalizations.of(context);
    final tasksBloc = context.read<TasksBloc>();
    setState(() => _brandError = null);
    try {
      final topic = await _bloc.createTopic(request.text);
      _bloc.add(ContractFormTopicAdded(topic));
      tasksBloc.add(const TasksRefreshRequested());
      return [topic];
    } on NameSaveException catch (error) {
      if (mounted) {
        setState(() => _brandError = switch (error.failure) {
              NameSaveFailure.duplicate => l10n.nameErrorDuplicateTopic,
              NameSaveFailure.notAllowed => l10n.suggestAddNotAllowed,
              NameSaveFailure.network => l10n.loginErrorNetwork,
              _ => l10n.suggestAddFailed,
            });
      }
      return null;
    }
  }

  Future<List<SuggestOption<LeaseRef>>> _leases(String query) async {
    final l10n = AppLocalizations.of(context);
    return [
      for (final lease in _bloc.matchLeases(query))
        SuggestOption(value: lease, label: lease.brand ?? l10n.contractNoBrand, hint: lease.party?.name),
    ];
  }

  Future<List<SuggestOption<String>>> Function(String) _values(SuggestValueField field) => (query) async => [
        for (final row in await _bloc.suggestValues(field, query)) SuggestOption(value: row.value, label: row.value),
      ];

  // Build ----------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final textStyle = AppTextStyles.body.copyWith(color: tokens.ink);

    return BlocConsumer<ContractFormBloc, ContractFormState>(
      listenWhen: (previous, current) =>
          current.status == ContractFormStatus.saved || current.draft.subject != _subject.text,
      listener: (context, state) {
        // A kind change sets the default subject in the bloc.
        if (state.draft.subject != _subject.text) _subject.text = state.draft.subject;
        if (state.status != ContractFormStatus.saved) return;
        // A storage contract under a lease has no row of its own: the
        // lease's drawer shows it.
        Navigator.of(context).pop(
          state.draft.kind == ContractKind.storage ? state.draft.lease?.id ?? state.savedId : state.savedId,
        );
      },
      builder: (context, state) {
        final busy = state.busy || _deleting;
        final draft = state.draft;
        final editing = _bloc.isEditing;
        final failure = state.failure;
        final muted = AppTextStyles.body.copyWith(color: tokens.textMuted);

        Widget link(String key, String label, VoidCallback onTap) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: Key(key),
                onPressed: busy ? null : onTap,
                style: TextButton.styleFrom(
                  foregroundColor: tokens.textMuted,
                  textStyle: AppTextStyles.meta,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                ),
                child: Text(label),
              ),
            );

        TextField textField(
          String key,
          TextEditingController controller,
          ContractTextField field,
          int max, {
          String? hint,
          String? error,
          String? suffix,
          bool multiline = false,
          TextInputType? keyboard,
        }) =>
            TextField(
              key: Key(key),
              controller: controller,
              readOnly: busy,
              onChanged: (text) => _text(field, text),
              textDirection: textDirectionOf(controller.text),
              keyboardType: keyboard ?? (multiline ? TextInputType.multiline : null),
              minLines: multiline ? 3 : 1,
              maxLines: multiline ? null : 1,
              style: textStyle,
              decoration: InputDecoration(hintText: hint, errorText: error, suffixText: suffix),
              inputFormatters: [
                if (!multiline) FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' '),
                CodePointLimitFormatter(max),
              ],
            );

        final file = LabeledField(
          label: l10n.newTaskFileLabel,
          child: _bloc.files.isEmpty
              ? FieldBox(child: Text(l10n.userFilesNone, key: const Key('contract-no-files'), style: muted))
              : SelectBox(
                  selectKey: const Key('contract-file'),
                  value: draft.fileId,
                  items: {for (final f in _bloc.files) f.id: f.name},
                  onChanged: busy || editing || _bloc.preset != null
                      ? null
                      : (id) => _bloc.add(ContractFormFileChanged(id)),
                ),
        );
        final fileKey = draft.fileId ?? '';
        final linked = LabeledField(
          label: l10n.contractFieldLinked,
          semantics: FieldLabelSemantics.hidden,
          child: SuggestField<LeaseRef>(
            key: ValueKey('contract-lease-$fileKey'),
            keyPrefix: 'contract-lease',
            label: l10n.contractFieldLinked,
            hintText: l10n.contractLinkedHint,
            fetch: _leases,
            picks: [?draft.lease],
            pickLabel: (lease) => lease.brand ?? l10n.contractNoBrand,
            onPicksChanged: busy || _bloc.leaseLocked
                ? null
                : (picks) => _bloc.add(ContractFormLeasePicked(picks.firstOrNull)),
            enabled: !busy,
          ),
        );
        final brand = LabeledField(
          label: l10n.contractFieldBrand,
          semantics: FieldLabelSemantics.hidden,
          child: SuggestField<TaskTopic>(
            key: ValueKey('contract-brand-$fileKey'),
            keyPrefix: 'contract-brand',
            label: l10n.contractFieldBrand,
            fetch: _brands,
            picks: [?draft.topic],
            pickLabel: (topic) => topic.name,
            onPicksChanged: busy ? null : (picks) => _bloc.add(ContractFormTopicPicked(picks.firstOrNull)),
            onAdd: draft.fileId == null ? null : _addBrand,
            maxLength: NameText.max,
            errorText: _brandError,
            enabled: !busy,
          ),
        );
        final party = PartyField(
          keyPrefix: 'contract-party',
          label: l10n.contractFieldParty,
          lookups: _bloc,
          party: draft.party,
          onChanged: busy ? null : (party) => _bloc.add(ContractFormPartyPicked(party)),
          enabled: !busy,
        );
        final units = UnitsField(
          key: ValueKey('contract-units-$fileKey-${draft.kind.name}'),
          keyPrefix: 'contract-units',
          label: l10n.contractFieldUnits,
          lookups: _bloc,
          units: draft.units,
          onChanged: busy ? null : (picks) => _bloc.add(ContractFormUnitsChanged(picks)),
          canAdd: draft.fileId != null,
          storageFirst: draft.kind == ContractKind.storage,
          enabled: !busy,
        );
        SuggestField<String> wording(String key, String label, TextEditingController controller,
                SuggestValueField field, ContractTextField textField) =>
            SuggestField<String>(
              keyPrefix: key,
              label: label,
              mode: SuggestMode.freeText,
              fetch: _values(field),
              controller: controller,
              onTextChanged: (text) => _text(textField, text),
              maxLength: ContractText.subjectMax,
              enabled: !busy,
            );
        final subject = LabeledField(
          label: l10n.contractFieldSubject,
          semantics: FieldLabelSemantics.hidden,
          child: wording('contract-subject', l10n.contractFieldSubject, _subject, SuggestValueField.subject,
              ContractTextField.subject),
        );
        final activity = LabeledField(
          label: l10n.contractFieldActivity,
          semantics: FieldLabelSemantics.hidden,
          child: wording('contract-activity', l10n.contractFieldActivity, _activity, SuggestValueField.activity,
              ContractTextField.activity),
        );

        Widget date(String key, String label, DateTime? value, ContractDateField field, {String? placeholder}) =>
            LabeledField(
              label: label,
              semantics: FieldLabelSemantics.hidden,
              child: OptionalDateBox(
                keyName: key,
                label: label,
                date: value,
                initialDate: value ?? draft.signedOn ?? widget.today,
                placeholder: placeholder,
                onPicked: busy ? null : (picked) => _bloc.add(ContractFormDateChanged(field, picked)),
                onCleared: () => _bloc.add(ContractFormDateChanged(field, null)),
              ),
            );
        final signed = date('contract-signed', l10n.contractFieldSigned, draft.signedOn, ContractDateField.signed);
        final starts = date('contract-starts', l10n.contractFieldStarts, draft.startsOn, ContractDateField.starts,
            placeholder: l10n.contractStartsHint);
        final ends = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            if (draft.endAsText)
              LabeledField(
                label: l10n.contractFieldEnds,
                child: textField('contract-date-note', _dateNote, ContractTextField.dateNote, ContractText.noteMax,
                    hint: l10n.contractDateNoteHint),
              )
            else
              date('contract-ends', l10n.contractFieldEnds, draft.endsOn, ContractDateField.ends),
            link('contract-end-toggle', draft.endAsText ? l10n.contractUseEndDate : l10n.contractNoEndDate,
                () => _bloc.add(const ContractFormEndAsTextToggled())),
          ],
        );

        Widget area(String key, String label, TextEditingController controller, ContractTextField field) =>
            LabeledField(
              label: label,
              child: textField(
                key,
                controller,
                field,
                12,
                suffix: l10n.contractAreaUnit,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                error: _bloc.areaValid(controller.text) ? null : l10n.contractAreaInvalid,
              ),
            );
        final areaToggle = link('contract-area-toggle',
            draft.areaAsText ? l10n.contractAreaAsNumber : l10n.contractAreaAsText,
            () => _bloc.add(const ContractFormAreaAsTextToggled()));

        final notes = LabeledField(
          label: l10n.contractFieldNotes,
          child: textField('contract-notes', _notes, ContractTextField.notes, ContractText.notesMax, multiline: true),
        );

        final record = _bloc.record;
        final canDeleteStorage = record != null &&
            record.kind == ContractKind.storage &&
            record.parentId != null &&
            record.canDelete;
        final deleteFailure = _deleteFailure;

        final cells = <Widget>[
          file,
          if (draft.kind == ContractKind.storage) linked,
          brand,
          party,
          units,
          subject,
          activity,
          signed,
          starts,
          ends,
        ];

        return PopScope<Object?>(
          canPop: !busy && !_bloc.isDirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy) _confirmDiscard();
          },
          child: FormModal(
            title: editing ? l10n.contractEditTitle : l10n.contractNew,
            maxWidth: ContractFormModal.width,
            actions: [
              FilledButton(
                key: const Key('contract-save'),
                onPressed: _bloc.canSave && !_deleting ? () => _bloc.add(const ContractFormSubmitted()) : null,
                child: state.status == ContractFormStatus.editing
                    ? Text(l10n.contractSave)
                    : SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: tokens.surface),
                      ),
              ),
              OutlinedButton(
                key: const Key('contract-cancel'),
                onPressed: busy ? null : () => Navigator.of(context).maybePop(),
                style: quietOutlineButtonStyle(context),
                child: Text(l10n.editCancel),
              ),
            ],
            endAction: canDeleteStorage
                ? OutlinedButton(
                    key: const Key('storage-delete'),
                    onPressed: busy ? null : _deleteStorage,
                    style: quietOutlineButtonStyle(context),
                    child: Text(l10n.storageDelete),
                  )
                : null,
            children: [
              Semantics(
                label: l10n.contractKindLabel,
                container: true,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final kind in const [
                      ContractKind.lease,
                      ContractKind.storage,
                      ContractKind.service,
                      ContractKind.other,
                    ])
                      QuietChip(
                        key: Key('contract-form-kind-${kind.name}'),
                        label: kind.formLabel(l10n),
                        selected: draft.kind == kind,
                        onTap: busy || _bloc.kindLocked ? null : () => _bloc.add(ContractFormKindChanged(kind)),
                      ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= ContractFormModal.twoColumnWidth;
                  final areas = draft.areaAsText
                      ? <Widget>[
                          LabeledField(
                            label: l10n.contractFieldArea,
                            child: textField('contract-area-note', _areaNote, ContractTextField.areaNote,
                                ContractText.noteMax, hint: l10n.contractAreaNoteHint),
                          ),
                        ]
                      : [
                          area('contract-area-inner', l10n.contractFieldAreaInner, _areaInner,
                              ContractTextField.areaInner),
                          area('contract-area-outer', l10n.contractFieldAreaOuter, _areaOuter,
                              ContractTextField.areaOuter),
                        ];
                  return Column(
                    key: Key(wide ? 'contract-grid-2' : 'contract-grid-1'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: wide ? 14 : AppSpacing.formGap,
                    children: [
                      ..._grid(cells, wide: wide),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 4,
                        children: [
                          if (wide && areas.length == 2)
                            ..._grid(areas, wide: true)
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: AppSpacing.formGap,
                              children: areas,
                            ),
                          areaToggle,
                        ],
                      ),
                    ],
                  );
                },
              ),
              notes,
              if (!_bloc.datesOrdered) FormErrorLine(l10n.contractDatesOrder, key: const Key('contract-dates-error')),
              if (failure != null) FormErrorLine(_message(l10n, failure), key: const Key('contract-error')),
              if (deleteFailure != null)
                FormErrorLine(
                  deleteFailure == ContractSaveFailure.notEmpty
                      ? l10n.storageDeleteNotEmpty
                      : _message(l10n, deleteFailure),
                  key: const Key('storage-delete-error'),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Pairs of cells side by side on a wide modal; one column otherwise.
  static List<Widget> _grid(List<Widget> cells, {required bool wide}) {
    if (!wide) return cells;
    return [
      for (var i = 0; i < cells.length; i += 2)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Expanded(child: cells[i]),
            Expanded(child: i + 1 < cells.length ? cells[i + 1] : const SizedBox.shrink()),
          ],
        ),
    ];
  }

  static String _message(AppLocalizations l10n, ContractSaveFailure failure) => switch (failure) {
        ContractSaveFailure.notAllowed => l10n.contractSaveNotAllowed,
        ContractSaveFailure.rejected => l10n.contractSaveRejected,
        ContractSaveFailure.network => l10n.loginErrorNetwork,
        _ => l10n.contractSaveUnknown,
      };
}

