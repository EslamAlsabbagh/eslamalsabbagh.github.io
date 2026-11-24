import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/contract_kind.dart';
import '../../../core/format/text_direction.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/contract_text.dart';
import '../../../core/validation/task_text.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tasks/bloc/tasks_bloc.dart';
import '../../tasks/view/widgets/confirm_dialog.dart';
import '../../tasks/view/widgets/form_error_line.dart';
import '../../tasks/view/widgets/form_modal.dart';
import '../../tasks/view/widgets/labeled_field.dart';
import '../bloc/annex_form_bloc.dart';
import '../bloc/contracts_bloc.dart';
import '../data/contract_details.dart';
import '../data/contract_record.dart';
import '../data/contract_refs.dart';
import '../data/contract_save_failure.dart';
import '../data/contracts_repository.dart';
import 'widgets/optional_date_box.dart';
import 'widgets/quiet_chip.dart';
import 'widgets/record_fields.dart';
import 'widgets/suggest_field.dart';

/// Opens the annex form under [parent] (DESIGN_SPEC §4 "Annex form"): a new
/// annex, or [annex] to edit. [parentRecord] and [annexes] (the rows the
/// drawer loaded) give the effective units and the next number. Returns the
/// saved or deleted annex's id, or null when nothing changed; the contracts
/// list is asked to reload after a change.
Future<String?> openAnnexForm(
  BuildContext context, {
  required DateTime Function() clock,
  required ContractDetails parent,
  required ContractRecord parentRecord,
  required List<ContractRecord> annexes,
  ContractRecord? annex,
}) async {
  final contractsBloc = context.read<ContractsBloc>();
  final today = context.read<TasksBloc>().state.cairoToday(clock());
  final l10n = AppLocalizations.of(context);
  final id = await showDialog<String>(
    context: context,
    barrierColor: context.tokens.scrim,
    barrierLabel: l10n.drawerClose,
    builder: (_) => BlocProvider(
      create: (_) => AnnexFormBloc(
        parent: parent,
        parentRecord: parentRecord,
        annexes: annexes,
        annex: annex,
        repository: context.read<ContractsRepository>(),
      ),
      child: AnnexFormModal(today: today),
    ),
  );
  if (id != null && !contractsBloc.isClosed) contractsBloc.add(const ContractsRefreshRequested());
  return id;
}

/// «ملحق جديد» / «تعديل ملحق»: the number, subject, date and notes, then
/// «ما الذي يغيّره الملحق؟» with a toggle per value it may change, each
/// opening its field. «حفظ الملحق» / «إلغاء», and «حذف الملحق» at the `end`
/// for an annex with nothing hanging on it. Leaving with changes asks
/// first, as in the contract form.
class AnnexFormModal extends StatefulWidget {
  const AnnexFormModal({super.key, required this.today});

  /// The Cairo date, where the date pickers open when a date is empty.
  final DateTime today;

  @override
  State<AnnexFormModal> createState() => _AnnexFormModalState();
}

class _AnnexFormModalState extends State<AnnexFormModal> {
  late final AnnexFormBloc _bloc = context.read<AnnexFormBloc>();
  late final _number = TextEditingController(text: _bloc.state.draft.number);
  late final _subject = TextEditingController(text: _bloc.state.draft.subject);
  late final _notes = TextEditingController(text: _bloc.state.draft.notes);
  late final _areaInner = TextEditingController(text: _bloc.state.draft.areaInner);
  late final _areaOuter = TextEditingController(text: _bloc.state.draft.areaOuter);

  @override
  void dispose() {
    for (final controller in [_number, _subject, _notes, _areaInner, _areaOuter]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _text(AnnexTextField field, String text) => _bloc.add(AnnexFormTextChanged(field, text));

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.discardEditTitle,
      body: _bloc.isEditing ? l10n.annexDiscardEditBody : l10n.annexDiscardBody,
      backLabel: l10n.discardEditBack,
      confirmLabel: l10n.discardEditConfirm,
      keyPrefix: 'annex-discard',
    );
    if (discard && mounted) navigator.pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.annexDeleteTitle,
      body: l10n.annexDeleteBody,
      backLabel: l10n.cancelTaskBack,
      confirmLabel: l10n.annexDelete,
      keyPrefix: 'annex-delete',
    );
    if (confirmed && !_bloc.isClosed) _bloc.add(const AnnexFormDeleteConfirmed());
  }

  Future<List<SuggestOption<String>>> _subjects(String query) async => [
        for (final row in await _bloc.suggestValues(SuggestValueField.annexSubject, query))
          SuggestOption(value: row.value, label: row.value),
      ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final textStyle = AppTextStyles.body.copyWith(color: tokens.ink);

    return BlocConsumer<AnnexFormBloc, AnnexFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (current.status == AnnexFormStatus.saved || current.status == AnnexFormStatus.deleted),
      listener: (context, state) => Navigator.of(context).pop(state.savedId),
      builder: (context, state) {
        final busy = state.busy;
        final draft = state.draft;
        final changes = draft.changes;
        final failure = state.failure;
        final deleteFailure = state.deleteFailure;

        TextField textField(
          String key,
          TextEditingController controller,
          AnnexTextField field,
          int max, {
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
              decoration: InputDecoration(errorText: error, suffixText: suffix),
              inputFormatters: [
                if (!multiline) FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' '),
                CodePointLimitFormatter(max),
              ],
            );

        Widget date(String key, String label, DateTime? value, ValueChanged<DateTime?> onChanged) => LabeledField(
              label: label,
              semantics: FieldLabelSemantics.hidden,
              child: OptionalDateBox(
                keyName: key,
                label: label,
                date: value,
                initialDate: value ?? widget.today,
                onPicked: busy ? null : onChanged,
                onCleared: () => onChanged(null),
              ),
            );

        final number = LabeledField(
          label: l10n.annexFieldNo,
          child: textField(
            'annex-number',
            _number,
            AnnexTextField.number,
            4,
            keyboard: TextInputType.number,
            error: _number.text.trim().isEmpty || _bloc.numberValid ? null : l10n.annexNoInvalid,
          ),
        );
        final subject = LabeledField(
          label: l10n.annexFieldSubject,
          semantics: FieldLabelSemantics.hidden,
          child: SuggestField<String>(
            keyPrefix: 'annex-subject',
            label: l10n.annexFieldSubject,
            mode: SuggestMode.freeText,
            fetch: _subjects,
            controller: _subject,
            onTextChanged: (text) => _text(AnnexTextField.subject, text),
            maxLength: ContractText.subjectMax,
            enabled: !busy,
          ),
        );
        final signed = date('annex-signed', l10n.annexFieldSigned, draft.signedOn,
            (picked) => _bloc.add(AnnexFormSignedChanged(picked)));

        Widget area(String key, String label, TextEditingController controller, AnnexTextField field) =>
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

        final changeFields = <Widget>[
          if (changes.contains(AnnexChange.ends))
            date('annex-ends', l10n.contractFieldEnds, draft.endsOn, (picked) => _bloc.add(AnnexFormEndsChanged(picked))),
          if (changes.contains(AnnexChange.area)) ...[
            area('annex-area-inner', l10n.contractFieldAreaInner, _areaInner, AnnexTextField.areaInner),
            area('annex-area-outer', l10n.contractFieldAreaOuter, _areaOuter, AnnexTextField.areaOuter),
          ],
          if (changes.contains(AnnexChange.party))
            PartyField(
              keyPrefix: 'annex-party',
              label: l10n.annexToggleParty,
              lookups: _bloc,
              party: draft.party,
              onChanged: busy ? null : (party) => _bloc.add(AnnexFormPartyPicked(party)),
              enabled: !busy,
            ),
          if (changes.contains(AnnexChange.units))
            UnitsField(
              keyPrefix: 'annex-units',
              label: l10n.contractFieldUnits,
              lookups: _bloc,
              units: draft.units,
              onChanged: busy ? null : (units) => _bloc.add(AnnexFormUnitsChanged(units)),
              canAdd: true,
              storageFirst: _bloc.parent.kind == ContractKind.storage,
              enabled: !busy,
            ),
        ];

        return PopScope<Object?>(
          canPop: !busy && !_bloc.isDirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy) _confirmDiscard();
          },
          child: FormModal(
            title: _bloc.isEditing ? l10n.annexEditTitle : l10n.annexNewTitle,
            maxWidth: 640,
            actions: [
              FilledButton(
                key: const Key('annex-save'),
                onPressed: _bloc.canSave ? () => _bloc.add(const AnnexFormSubmitted()) : null,
                child: state.status == AnnexFormStatus.saving
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: tokens.surface),
                      )
                    : Text(l10n.annexSave),
              ),
              OutlinedButton(
                key: const Key('annex-cancel'),
                onPressed: busy ? null : () => Navigator.of(context).maybePop(),
                style: quietOutlineButtonStyle(context),
                child: Text(l10n.editCancel),
              ),
            ],
            endAction: _bloc.canDelete
                ? OutlinedButton(
                    key: const Key('annex-delete'),
                    onPressed: busy ? null : _delete,
                    style: quietOutlineButtonStyle(context),
                    child: Text(l10n.annexDelete),
                  )
                : null,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 220 * 2 + 14;
                  final top = [number, signed];
                  return Column(
                    key: Key(wide ? 'annex-grid-2' : 'annex-grid-1'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: wide ? 14 : AppSpacing.formGap,
                    children: [
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 14,
                          children: [for (final cell in top) Expanded(child: cell)],
                        )
                      else
                        ...top,
                      subject,
                    ],
                  );
                },
              ),
              LabeledField(
                label: l10n.contractFieldNotes,
                child: textField('annex-notes', _notes, AnnexTextField.notes, ContractText.notesMax, multiline: true),
              ),
              Semantics(
                container: true,
                label: l10n.annexChangesLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    ExcludeSemantics(
                      child: Text(l10n.annexChangesLabel, style: AppTextStyles.fieldLabel.copyWith(color: tokens.ink)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (change, label) in [
                          (AnnexChange.ends, l10n.contractFieldEnds),
                          (AnnexChange.area, l10n.contractFieldArea),
                          (AnnexChange.party, l10n.annexToggleParty),
                          (AnnexChange.units, l10n.contractFieldUnits),
                        ])
                          QuietChip(
                            key: Key('annex-change-${change.name}'),
                            label: label,
                            selected: changes.contains(change),
                            onTap: busy ? null : () => _bloc.add(AnnexFormChangeToggled(change)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              ...changeFields,
              if (failure != null) FormErrorLine(_message(l10n, failure), key: const Key('annex-error')),
              if (deleteFailure != null)
                FormErrorLine(
                  deleteFailure == ContractSaveFailure.notEmpty ? l10n.annexDeleteNotEmpty : _message(l10n, deleteFailure),
                  key: const Key('annex-delete-error'),
                ),
            ],
          ),
        );
      },
    );
  }

  static String _message(AppLocalizations l10n, ContractSaveFailure failure) => switch (failure) {
        ContractSaveFailure.duplicateAnnexNo => l10n.annexDuplicateNo,
        ContractSaveFailure.notAllowed => l10n.contractActionNotAllowed,
        ContractSaveFailure.rejected => l10n.annexSaveRejected,
        ContractSaveFailure.network => l10n.loginErrorNetwork,
        _ => l10n.annexSaveUnknown,
      };
}
