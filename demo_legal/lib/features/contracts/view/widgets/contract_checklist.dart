import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/domain/contract_item_kind.dart';
import '../../../../core/format/app_formats.dart';
import '../../../../core/format/text_direction.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validation/contract_text.dart';
import '../../../../core/validation/task_text.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../tasks/view/widgets/confirm_dialog.dart';
import '../../../tasks/view/widgets/expand_toggle.dart';
import '../../../tasks/view/widgets/form_error_line.dart';
import '../../../tasks/view/widgets/select_box.dart';
import '../../data/contract_item.dart';
import '../../data/contract_record.dart';
import '../../data/contract_save_failure.dart';
import 'contract_sections.dart';
import 'quiet_chip.dart';
import 'suggest_field.dart';

/// Where a missing item can go: the contract, one of its annexes or one of
/// its storage contracts, with how «على» names it.
typedef ChecklistTarget = ({String id, String label});

/// «على»'s choices: «العقد», then the annexes («ملحق ٢») and the storage
/// contracts («مخزن STOR-ST03 · ٢٠٢٦», the season telling renewals apart), in
/// their sections' order.
List<ChecklistTarget> checklistTargets(
  AppLocalizations l10n,
  String contractId, {
  required List<ContractRecord> annexes,
  required List<ContractRecord> storage,
}) =>
    [
      (id: contractId, label: l10n.checklistOnContract),
      for (final annex in annexes)
        (id: annex.id, label: l10n.annexRowTitle(annex.annexNo == null ? '' : AppFormats.number(annex.annexNo!))),
      for (final s in storage)
        (
          id: s.id,
          label: switch ((s.units.map((u) => u.code).join(' + '), s.signedOn)) {
            (final codes, final signed?) => l10n.checklistOnStorageSeason(codes, AppFormats.year(signed.year)),
            (final codes, null) => l10n.checklistOnStorage(codes),
          },
        ),
    ];

/// «النواقص والمستندات (n)» (DESIGN_SPEC §4 "Contract drawer" → Sections 3):
/// the tenant's documents and the missing signatures and stamps, each group
/// with its open items, a quiet «+ إضافة …» that opens a one-line inline
/// row under it, and its resolved items behind «عرض المستوفاة (n)».
///
/// Ticking an item resolves it at once, and unticking a resolved one opens it
/// again ([onToggle]). An open item's × deletes it after «حذف البند؟». With
/// [onAdd] null (a terminated contract) the rows are read-only, and an empty
/// group or section is hidden.
class ContractChecklistSection extends StatefulWidget {
  const ContractChecklistSection({
    super.key,
    required this.items,
    required this.targets,
    required this.partyId,
    required this.busy,
    required this.failure,
    required this.fetchLabels,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  final List<ContractItem> items;

  /// «على»'s choices, the main contract first. An item on any other row
  /// reads «على ملحق ٢» with its label.
  final List<ChecklistTarget> targets;

  /// The effective tenant, whose documents these are; null hides the
  /// documents group.
  final String? partyId;

  /// A write is in flight: the add row's button waits.
  final bool busy;

  /// Why the last checklist write failed.
  final ContractSaveFailure? failure;

  /// The label field's suggestions (`suggest_values('item_label')`).
  final Future<List<SuggestOption<String>>> Function(String query) fetchLabels;
  final void Function(ContractItem item, bool resolved)? onToggle;
  final ValueChanged<ContractItem>? onDelete;
  final ValueChanged<ContractItemInput>? onAdd;

  /// Whether the section shows at all: something to list, or something to add.
  static bool shows({required List<ContractItem> items, required bool editable}) => items.isNotEmpty || editable;

  @override
  State<ContractChecklistSection> createState() => _ContractChecklistSectionState();
}

class _ContractChecklistSectionState extends State<ContractChecklistSection> {
  /// The group whose inline row is open.
  ContractItemKind? _adding;
  final Set<ContractItemKind> _showResolved = {};

  final _label = TextEditingController();
  final _detail = TextEditingController();
  bool _signature = true;
  bool _stamp = true;
  bool _ourSide = false;
  String? _targetId;

  /// «إضافة» was pressed and its write hasn't come back.
  bool _submitted = false;

  @override
  void didUpdateWidget(ContractChecklistSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Terminated meanwhile: nothing more to add.
    if (widget.onAdd == null) _adding = null;
    if (!_submitted || widget.busy) return;
    if (widget.failure != null) {
      _submitted = false;
    } else if (widget.items != oldWidget.items) {
      // Saved: the row closes, and the group's «+ إضافة …» opens the next
      // one (chosen 2026-11-15; it stayed open before). A refusal keeps it
      // open with what was typed.
      _submitted = false;
      _adding = null;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _detail.dispose();
    super.dispose();
  }

  void _open(ContractItemKind kind) => setState(() {
        _adding = kind;
        _label.clear();
        _detail.clear();
        _signature = true;
        _stamp = true;
        _ourSide = false;
        _targetId = widget.targets.firstOrNull?.id;
        _submitted = false;
      });

  void _close() => setState(() {
        _adding = null;
        _submitted = false;
      });

  bool get _needsOne => _adding == ContractItemKind.missing && !_signature && !_stamp;

  bool get _canAdd =>
      !widget.busy &&
      !_submitted &&
      ContractText.isFilled(_label.text, ContractText.itemLabelMax) &&
      ContractText.fits(_detail.text, ContractText.itemDetailMax) &&
      !_needsOne;

  void _submit() {
    final onAdd = widget.onAdd;
    final kind = _adding;
    if (onAdd == null || kind == null || !_canAdd) return;
    final label = _label.text.trim();
    final detail = _detail.text.trim();
    final input = switch (kind) {
      ContractItemKind.document => ContractItemInput.document(partyId: widget.partyId!, label: label, detail: detail),
      ContractItemKind.missing => ContractItemInput.missing(
          contractId: _targetId ?? widget.targets.first.id,
          label: label,
          detail: detail,
          needsSignature: _signature,
          needsStamp: _stamp,
          side: _ourSide ? ContractItemSide.us : ContractItemSide.client,
        ),
    };
    setState(() => _submitted = true);
    onAdd(input);
  }

  Future<void> _delete(ContractItem item) async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.checklistDeleteTitle,
      body: l10n.checklistDeleteBody,
      backLabel: l10n.cancelTaskBack,
      confirmLabel: l10n.checklistDeleteConfirm,
      keyPrefix: 'item-delete',
    );
    if (confirmed && mounted) onDelete(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editable = widget.onAdd != null;
    final open = widget.items.where((i) => !i.isResolved).length;
    final failure = widget.failure;
    final groups = [
      if (widget.partyId != null || widget.items.any((i) => i.kind == ContractItemKind.document))
        _group(context, ContractItemKind.document, editable: editable && widget.partyId != null),
      _group(context, ContractItemKind.missing, editable: editable && widget.targets.isNotEmpty),
    ].nonNulls;
    return Column(
      key: const Key('contract-checklist'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        DrawerSectionHeader(title: l10n.contractChecklistTitle(AppFormats.number(open))),
        ...groups,
        if (failure != null) FormErrorLine(_message(l10n, failure), key: const Key('checklist-error')),
      ],
    );
  }

  /// One group, or null when it has nothing to show.
  Widget? _group(BuildContext context, ContractItemKind kind, {required bool editable}) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final mine = [
      for (final item in widget.items)
        if (item.kind == kind) item,
    ];
    if (mine.isEmpty && !editable) return null;
    final openItems = mine.where((i) => !i.isResolved).toList();
    final resolved = mine.where((i) => i.isResolved).toList();
    final showResolved = _showResolved.contains(kind);
    final isDocument = kind == ContractItemKind.document;
    final keyName = isDocument ? 'documents' : 'missing';

    return Column(
      key: Key('checklist-$keyName'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        _GroupHeader(
          title: isDocument ? l10n.checklistDocumentsTitle : l10n.checklistMissingTitle,
          note: isDocument ? l10n.checklistDocumentsNote : null,
          addLabel: isDocument ? l10n.checklistAddDocument : l10n.checklistAddMissing,
          addKey: Key(isDocument ? 'checklist-add-document' : 'checklist-add-missing'),
          onAdd: editable && _adding != kind ? () => _open(kind) : null,
        ),
        for (final item in openItems) _row(item),
        if (_adding == kind && editable) _addRow(context, kind),
        if (resolved.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ExpandToggle(
              buttonKey: Key('checklist-resolved-$keyName'),
              expanded: showResolved,
              label: showResolved
                  ? l10n.checklistHideResolved(AppFormats.number(resolved.length))
                  : l10n.checklistShowResolved(AppFormats.number(resolved.length)),
              onPressed: () => setState(() => showResolved ? _showResolved.remove(kind) : _showResolved.add(kind)),
            ),
          ),
        if (showResolved)
          for (final item in resolved) _row(item),
        if (mine.isEmpty && _adding != kind)
          Text(
            isDocument ? l10n.checklistNoDocuments : l10n.checklistNoMissing,
            style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
          ),
      ],
    );
  }

  Widget _row(ContractItem item) {
    final onToggle = widget.onToggle;
    final mainId = widget.targets.firstOrNull?.id;
    final on = item.contractId == null || item.contractId == mainId
        ? null
        : widget.targets.where((t) => t.id == item.contractId).firstOrNull?.label;
    return _ItemRow(
      key: ValueKey('item-${item.id}'),
      item: item,
      on: on,
      onToggle: onToggle == null ? null : (resolved) => onToggle(item, resolved),
      onDelete: widget.onDelete == null || item.isResolved ? null : () => _delete(item),
    );
  }

  Widget _addRow(BuildContext context, ContractItemKind kind) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final busy = widget.busy || _submitted;
    final textStyle = AppTextStyles.body.copyWith(color: tokens.ink);

    final label = SuggestField<String>(
      keyPrefix: 'item-label',
      label: l10n.checklistLabelField,
      mode: SuggestMode.freeText,
      fetch: widget.fetchLabels,
      controller: _label,
      onTextChanged: (_) => setState(() {}),
      maxLength: ContractText.itemLabelMax,
      hintText: kind == ContractItemKind.document ? l10n.checklistDocumentHint : l10n.checklistMissingHint,
      enabled: !busy,
    );
    final detail = Semantics(
      label: l10n.checklistDetailField,
      child: TextField(
        key: const Key('item-detail'),
        controller: _detail,
        readOnly: busy,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        textDirection: textDirectionOf(_detail.text),
        maxLines: 1,
        style: textStyle,
        decoration: InputDecoration(hintText: l10n.checklistDetailHint),
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' '),
          const CodePointLimitFormatter(ContractText.itemDetailMax),
        ],
      ),
    );
    final targets = widget.targets;
    final missingParts = <Widget>[
      QuietChip(
        key: const Key('item-signature'),
        label: l10n.checklistSignature,
        selected: _signature,
        onTap: busy ? null : () => setState(() => _signature = !_signature),
      ),
      QuietChip(
        key: const Key('item-stamp'),
        label: l10n.checklistStamp,
        selected: _stamp,
        onTap: busy ? null : () => setState(() => _stamp = !_stamp),
      ),
      QuietChip(
        key: const Key('item-our-side'),
        label: l10n.checklistOurSide,
        selected: _ourSide,
        onTap: busy ? null : () => setState(() => _ourSide = !_ourSide),
      ),
      if (targets.length > 1)
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            ExcludeSemantics(child: Text(l10n.checklistOnLabel, style: textStyle)),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140, maxWidth: 240),
              child: Semantics(
                label: l10n.checklistOnLabel,
                child: SelectBox(
                  selectKey: const Key('item-target'),
                  value: _targetId ?? targets.first.id,
                  items: {for (final t in targets) t.id: t.label},
                  onChanged: busy ? null : (id) => setState(() => _targetId = id),
                ),
              ),
            ),
          ],
        ),
    ];

    return Container(
      key: const Key('checklist-add-row'),
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppRadii.row),
        border: Border.all(color: tokens.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 420;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [Expanded(child: label), Expanded(child: detail)],
                )
              else ...[
                label,
                detail,
              ],
              if (kind == ContractItemKind.missing)
                Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: missingParts),
              if (_needsOne) FormErrorLine(l10n.checklistNeedsOne, key: const Key('item-needs-one')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    key: const Key('item-add'),
                    onPressed: _canAdd ? _submit : null,
                    child: busy
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: tokens.surface),
                          )
                        : Text(l10n.checklistAdd),
                  ),
                  OutlinedButton(
                    key: const Key('item-cancel'),
                    onPressed: busy ? null : _close,
                    style: quietOutlineButtonStyle(context),
                    child: Text(l10n.editCancel),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _message(AppLocalizations l10n, ContractSaveFailure failure) => switch (failure) {
        ContractSaveFailure.notAllowed => l10n.contractActionNotAllowed,
        ContractSaveFailure.network => l10n.loginErrorNetwork,
        _ => l10n.saveErrorUnknown,
      };
}

/// A group's title (14/600 ink), its note, and the quiet «+ إضافة …» at the
/// `end` ([onAdd] null hides it).
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.note, required this.addLabel, required this.addKey, required this.onAdd});

  final String title;
  final String? note;
  final String addLabel;
  final Key addKey;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final note = this.note;
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.ink),
                ),
              ),
              if (note != null) Text(note, style: AppTextStyles.meta.copyWith(color: tokens.textMuted)),
            ],
          ),
        ),
        if (onAdd != null)
          TextButton(
            key: addKey,
            onPressed: onAdd,
            style: TextButton.styleFrom(
              foregroundColor: tokens.ink,
              textStyle: AppTextStyles.fieldLabel,
              minimumSize: const Size(0, AppSpacing.touchTarget),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
            ),
            child: Text(addLabel),
          ),
      ],
    );
  }
}

/// An item: an `accent` checkbox with the label and detail, read and tapped
/// as one checkbox. A missing item adds «توقيع» / «ختم» pills, «من جانبنا»
/// for our side, and «على ملحق ٢» ([on]) when it isn't on the contract
/// itself. [onDelete] null hides the ×.
class _ItemRow extends StatelessWidget {
  const _ItemRow({super.key, required this.item, required this.on, required this.onToggle, required this.onDelete});

  final ContractItem item;
  final String? on;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final onToggle = this.onToggle;
    final on = this.on;
    final resolved = item.isResolved;
    final labelStyle = AppTextStyles.body.copyWith(color: resolved ? tokens.textMuted : tokens.ink);
    final meta = AppTextStyles.meta.copyWith(color: tokens.textMuted);
    final missing = item.kind == ContractItemKind.missing;

    final box = MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.flag),
        onTap: onToggle == null ? null : () => onToggle(!resolved),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 2),
                  child: SizedBox.square(
                    dimension: 20,
                    child: Checkbox(
                      key: Key('item-check-${item.id}'),
                      value: resolved,
                      onChanged: onToggle == null ? null : (value) => onToggle(value ?? false),
                      activeColor: tokens.accent,
                      checkColor: tokens.surface,
                      side: BorderSide(color: tokens.textMuted, width: 1.5),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(item.label, textDirection: textDirectionOf(item.label), style: labelStyle),
                          if (missing && item.needsSignature) _Pill(l10n.checklistSignature),
                          if (missing && item.needsStamp) _Pill(l10n.checklistStamp),
                          if (missing && item.side == ContractItemSide.us) _Pill(l10n.checklistOurSide),
                        ],
                      ),
                      if (item.detail.isNotEmpty)
                        Text(item.detail, textDirection: textDirectionOf(item.detail), style: meta),
                      if (on != null) Text(l10n.checklistOn(on), style: meta),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final onDelete = this.onDelete;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Expanded(child: box),
        if (onDelete != null)
          IconButton(
            key: Key('item-delete-${item.id}'),
            onPressed: onDelete,
            tooltip: l10n.checklistDelete,
            color: tokens.textMuted,
            iconSize: 18,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}

/// «توقيع» / «ختم» / «من جانبنا»: 12/600, radius 999, `mutedFill`, ink.
class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.mutedFill, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 1),
        child: Text(text, style: AppTextStyles.badge.copyWith(color: tokens.ink)),
      ),
    );
  }
}
