import 'package:flutter/material.dart';

import '../../../../core/domain/unit_kind.dart';
import '../../../../core/format/arabic_count.dart';
import '../../../../core/format/arabic_normalize.dart';
import '../../../../core/format/unit_codes.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validation/contract_text.dart';
import '../../../../core/validation/task_text.dart';
import '../../../../l10n/contract_l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../tasks/view/widgets/confirm_dialog.dart';
import '../../../tasks/view/widgets/labeled_field.dart';
import '../../../tasks/view/widgets/select_box.dart';
import '../../bloc/contract_lookups.dart';
import '../../data/contract_refs.dart';
import '../../data/contract_save_failure.dart';
import 'suggest_field.dart';

/// The error line of a failed «+ إضافة» on a tenant or unit.
String _addFailure(AppLocalizations l10n, ContractSaveFailure failure, {required String duplicate}) =>
    switch (failure) {
      ContractSaveFailure.duplicateParty || ContractSaveFailure.duplicateUnit => duplicate,
      ContractSaveFailure.notAllowed => l10n.suggestAddNotAllowed,
      ContractSaveFailure.network => l10n.loginErrorNetwork,
      _ => l10n.suggestAddFailed,
    };

/// «المستأجر»: one party, picked from `suggest_parties` or added with
/// «+ إضافة», which asks «يوجد مستأجر مشابه» first when a close name exists
/// (DESIGN_SPEC §4 "Suggest field"). The contract form and the annex form
/// («المستأجر (تنازل)») share it.
class PartyField extends StatefulWidget {
  const PartyField({
    super.key,
    required this.keyPrefix,
    required this.label,
    required this.lookups,
    required this.party,
    required this.onChanged,
    this.enabled = true,
  });

  final String keyPrefix;
  final String label;
  final ContractLookups lookups;
  final PartyRef? party;

  /// Null makes the pick fixed.
  final ValueChanged<PartyRef?>? onChanged;
  final bool enabled;

  @override
  State<PartyField> createState() => _PartyFieldState();
}

class _PartyFieldState extends State<PartyField> {
  String? _error;

  Future<List<SuggestOption<PartyRef>>> _parties(String query) async {
    final l10n = AppLocalizations.of(context);
    final key = normalizeAr(query);
    final rows = await widget.lookups.suggestParties(query);
    return [
      for (final row in rows)
        SuggestOption(
          value: row.party,
          label: row.party.name,
          hint: row.contractCount == 0
              ? null
              : arabicCount(
                  row.contractCount,
                  one: l10n.contractCountOne,
                  two: l10n.contractCountTwo,
                  few: l10n.contractCountFew,
                  many: l10n.contractCountMany,
                ),
          score: row.score,
          exact: normalizeAr(row.party.name) == key,
        ),
    ];
  }

  Future<List<PartyRef>?> _add(SuggestAddRequest<PartyRef> request) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    final similar = similarOptions(request.shown);
    if (similar.isNotEmpty) {
      final choice = await showSimilarDialog(context, title: l10n.similarPartyTitle, matches: similar);
      switch (choice) {
        case null:
          return null;
        case UseExisting(:final value):
          return [value];
        case AddAnyway():
      }
    }
    try {
      return [await widget.lookups.createParty(request.text)];
    } on ContractSaveException catch (error) {
      if (mounted) setState(() => _error = _addFailure(l10n, error.failure, duplicate: l10n.partyDuplicate));
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = widget.onChanged;
    return LabeledField(
      label: widget.label,
      semantics: FieldLabelSemantics.hidden,
      child: SuggestField<PartyRef>(
        keyPrefix: widget.keyPrefix,
        label: widget.label,
        fetch: _parties,
        picks: [?widget.party],
        pickLabel: (party) => party.name,
        onPicksChanged: onChanged == null ? null : (picks) => onChanged(picks.firstOrNull),
        onAdd: _add,
        maxLength: ContractText.partyMax,
        errorText: _error,
        enabled: widget.enabled,
      ),
    );
  }
}

/// «الوحدات»: several units of the lookups' file, picked from
/// `suggest_units` or added with «+ إضافة», one code or several joined with
/// `+` / `&`. Codes the file already has are picked; for new ones the
/// inline row asks their kind (and a single storage unit's key number)
/// first. A single new code close to an existing one asks «توجد وحدة
/// مشابهة». Give it a key that changes with the file, so a file change
/// starts it afresh.
class UnitsField extends StatefulWidget {
  const UnitsField({
    super.key,
    required this.keyPrefix,
    required this.label,
    required this.lookups,
    required this.units,
    required this.onChanged,
    required this.canAdd,
    this.storageFirst = false,
    this.enabled = true,
  });

  final String keyPrefix;
  final String label;
  final ContractLookups lookups;
  final List<UnitRef> units;
  final ValueChanged<List<UnitRef>>? onChanged;

  /// «+ إضافة» shows (a file is chosen).
  final bool canAdd;

  /// A new unit's kind starts at «مخزن» (a storage contract).
  final bool storageFirst;
  final bool enabled;

  @override
  State<UnitsField> createState() => _UnitsFieldState();
}

class _UnitsFieldState extends State<UnitsField> {
  String? _error;

  Future<List<SuggestOption<UnitRef>>> _units(String query) async {
    final l10n = AppLocalizations.of(context);
    final key = unitCodeKey(query);
    final rows = await widget.lookups.suggestUnits(query);
    return [
      for (final row in rows)
        SuggestOption(
          value: row.unit,
          label: row.unit.code,
          hint: [
            row.currentBrand ?? l10n.unitVacant,
            if (row.keyNumber case final key?) l10n.unitKeyHint(key),
          ].join(' · '),
          score: row.score,
          exact: unitCodeKey(row.unit.code) == key,
        ),
    ];
  }

  String _addLabel(AppLocalizations l10n, String text) {
    final codes = splitUnitCodes(text);
    if (codes.length < 2) return l10n.suggestAdd(text);
    final count = arabicCount(
      codes.length,
      one: l10n.unitCountOne,
      two: l10n.unitCountTwo,
      few: l10n.unitCountFew,
      many: l10n.unitCountMany,
    );
    return l10n.suggestAddUnits(count, codes.join(' · '));
  }

  Future<List<UnitRef>?> _add(SuggestAddRequest<UnitRef> request) async {
    final l10n = AppLocalizations.of(context);
    final lookups = widget.lookups;
    setState(() => _error = null);
    final codes = splitUnitCodes(request.text);
    if (codes.isEmpty) return null;
    if (codes.length == 1) {
      final similar = similarOptions(request.shown);
      if (similar.isNotEmpty) {
        final choice = await showSimilarDialog(context, title: l10n.similarUnitTitle, matches: similar);
        switch (choice) {
          case null:
            return null;
          case UseExisting(:final value):
            return [value];
          case AddAnyway():
        }
      }
    }
    final made = <UnitRef>[];
    try {
      final (:found, :missing) = await lookups.findUnits(codes);
      if (missing.isEmpty) return found;
      final details = await request.showPanel<({UnitKind kind, String? keyNumber})>(
        (done) => NewUnitPanel(
          codes: missing,
          initialKind: widget.storageFirst ? UnitKind.storage : UnitKind.shop,
          onDone: done,
        ),
      );
      if (details == null) return null;
      await lookups.createUnits(missing, details.kind, keyNumber: details.keyNumber, made: made);
      return [...found, ...made];
    } on ContractSaveException catch (error) {
      if (mounted) setState(() => _error = _addFailure(l10n, error.failure, duplicate: l10n.unitDuplicate));
      return made.isEmpty ? null : made;
    } catch (_) {
      if (mounted) setState(() => _error = l10n.suggestAddFailed);
      return made.isEmpty ? null : made;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LabeledField(
      label: widget.label,
      semantics: FieldLabelSemantics.hidden,
      child: SuggestField<UnitRef>(
        keyPrefix: widget.keyPrefix,
        label: widget.label,
        mode: SuggestMode.multi,
        fetch: _units,
        picks: widget.units,
        pickLabel: (unit) => unit.code,
        onPicksChanged: widget.onChanged,
        onAdd: widget.canAdd ? _add : null,
        addLabel: (text) => _addLabel(l10n, text),
        // Joined codes are longer than one unit's.
        maxLength: ContractText.unitCodeMax * 4,
        errorText: _error,
        enabled: widget.enabled,
      ),
    );
  }
}

/// The inline row under the units field for codes the file doesn't have:
/// «وحدة جديدة», the codes, «النوع», «رقم المفتاح» for a single storage
/// unit, then «إضافة» / «إلغاء» (DESIGN_SPEC §4 "Suggest field").
class NewUnitPanel extends StatefulWidget {
  const NewUnitPanel({super.key, required this.codes, required this.initialKind, required this.onDone});

  final List<String> codes;
  final UnitKind initialKind;
  final void Function(({UnitKind kind, String? keyNumber})? result) onDone;

  @override
  State<NewUnitPanel> createState() => _NewUnitPanelState();
}

class _NewUnitPanelState extends State<NewUnitPanel> {
  late UnitKind _kind = widget.initialKind;
  final _keyNumber = TextEditingController();

  @override
  void dispose() {
    _keyNumber.dispose();
    super.dispose();
  }

  bool get _asksKey => _kind == UnitKind.storage && widget.codes.length == 1;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final keyNumber = _keyNumber.text.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.subtleFill,
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.unitNewLabel, style: AppTextStyles.fieldLabel.copyWith(color: tokens.textMuted)),
            for (final code in widget.codes)
              Text(code, textDirection: TextDirection.ltr, style: AppTextStyles.body.copyWith(color: tokens.ink)),
            SizedBox(
              width: 150,
              child: Semantics(
                label: l10n.unitKindLabel,
                child: SelectBox(
                  selectKey: const Key('new-unit-kind'),
                  value: _kind.name,
                  items: {for (final kind in UnitKind.values) kind.name: kind.label(l10n)},
                  onChanged: (name) => setState(() => _kind = UnitKind.fromDb(name)),
                ),
              ),
            ),
            if (_asksKey)
              SizedBox(
                width: 140,
                child: TextField(
                  key: const Key('new-unit-key'),
                  controller: _keyNumber,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.body.copyWith(color: tokens.ink),
                  decoration: InputDecoration(hintText: l10n.unitKeyNumberLabel),
                  inputFormatters: const [CodePointLimitFormatter(ContractText.keyNumberMax)],
                ),
              ),
            FilledButton(
              key: const Key('new-unit-add'),
              onPressed: () => widget.onDone((kind: _kind, keyNumber: _asksKey && keyNumber.isNotEmpty ? keyNumber : null)),
              child: Text(l10n.unitAdd),
            ),
            OutlinedButton(
              key: const Key('new-unit-cancel'),
              onPressed: () => widget.onDone(null),
              style: quietOutlineButtonStyle(context),
              child: Text(l10n.editCancel),
            ),
          ],
        ),
      ),
    );
  }
}
