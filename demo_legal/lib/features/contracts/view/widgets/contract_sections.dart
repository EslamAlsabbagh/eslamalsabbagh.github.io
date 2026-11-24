import 'package:flutter/material.dart';

import '../../../../core/domain/contract_kind.dart';
import '../../../../core/domain/task_status.dart';
import '../../../../core/format/app_formats.dart';
import '../../../../core/format/arabic_count.dart';
import '../../../../core/format/text_direction.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../tasks/view/widgets/confirm_dialog.dart';
import '../../../tasks/view/widgets/stored_text.dart';
import '../../data/contract_record.dart';
import 'contract_row.dart';

/// A drawer section's title row: the title with its count (13/600
/// `textMuted`) and a quiet «+ إضافة …» at the `end` (DESIGN_SPEC §4
/// "Contract drawer" → Sections). [onAdd] null hides the action (a
/// terminated contract).
class DrawerSectionHeader extends StatelessWidget {
  const DrawerSectionHeader({super.key, required this.title, this.addLabel, this.addKey, this.onAdd});

  final String title;
  final String? addLabel;
  final Key? addKey;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final addLabel = this.addLabel;
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.fieldLabel.copyWith(color: tokens.textMuted)),
          ),
        ),
        if (addLabel != null && onAdd != null)
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

/// A row in a drawer section: the list row's box, one button.
class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.row),
      side: BorderSide(color: tokens.border),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      child: Material(
        color: tokens.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 14 + 1, vertical: 12 + 1),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Parts of a line joined by « · », each its own text so a code or an
/// English name reads in its own direction.
class _Parts extends StatelessWidget {
  const _Parts(this.parts, {required this.style});

  final List<Widget> parts;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, part) in parts.indexed) ...[
          if (i > 0) Text('·', style: style),
          part,
        ],
      ],
    );
  }
}

/// The annexes under a contract, oldest first: by date (undated last), then
/// number.
List<ContractRecord> sortedAnnexes(List<ContractRecord> children) => [
      for (final c in children)
        if (c.kind == ContractKind.annex) c,
    ]..sort((a, b) {
        final byDate = switch ((a.signedOn, b.signedOn)) {
          (final x?, final y?) => x.compareTo(y),
          (null, null) => 0,
          (null, _) => 1,
          (_, null) => -1,
        };
        return byDate != 0 ? byDate : (a.annexNo ?? 0).compareTo(b.annexNo ?? 0);
      });

/// «الملاحق (n)»: a row per annex, «ملحق ٢ · subject · date» over what it
/// changes («النهاية ← …»), with its own «n نواقص» badge. A row opens the
/// annex form; «+ إضافة ملحق» a new one ([onAdd] null hides it).
class ContractAnnexesSection extends StatelessWidget {
  const ContractAnnexesSection({super.key, required this.annexes, required this.onOpen, required this.onAdd});

  /// In order ([sortedAnnexes]).
  final List<ContractRecord> annexes;
  final ValueChanged<ContractRecord>? onOpen;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onOpen = this.onOpen;
    return Column(
      key: const Key('contract-annexes'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        DrawerSectionHeader(
          title: l10n.contractAnnexesTitle(AppFormats.number(annexes.length)),
          addLabel: l10n.contractAddAnnex,
          addKey: const Key('contract-add-annex'),
          onAdd: onAdd,
        ),
        for (final annex in annexes)
          _AnnexRow(
            key: ValueKey('annex-${annex.id}'),
            annex: annex,
            onTap: onOpen == null ? null : () => onOpen(annex),
          ),
      ],
    );
  }
}

class _AnnexRow extends StatelessWidget {
  const _AnnexRow({super.key, required this.annex, required this.onTap});

  final ContractRecord annex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final a = annex;
    final title = AppTextStyles.body.copyWith(color: tokens.ink, fontWeight: FontWeight.w600);
    final meta = AppTextStyles.meta.copyWith(color: tokens.textMuted);
    String area(double value) => l10n.contractArea(AppFormats.number(value));

    final changes = <Widget>[
      if (a.endsOn case final ends?) Text(l10n.annexChangeEnds(AppFormats.fullDate(ends)), style: meta),
      if (a.areaInner case final inner?) Text(l10n.annexChangeAreaInner(area(inner)), style: meta),
      if (a.areaOuter case final outer?) Text(l10n.annexChangeAreaOuter(area(outer)), style: meta),
      if (a.party case final party?)
        Wrap(spacing: 4, children: [
          Text(l10n.annexChangeParty, style: meta),
          Text(party.name, textDirection: textDirectionOf(party.name), style: meta),
        ]),
      if (a.units.isNotEmpty)
        Wrap(spacing: 4, children: [
          Text(l10n.annexChangeUnits, style: meta),
          for (final unit in a.units) Text(unit.code, textDirection: TextDirection.ltr, style: meta),
        ]),
    ];
    final number = a.annexNo;
    final badge = a.openItemCount > 0
        ? ContractBadge(
            key: const Key('annex-missing-badge'),
            text: arabicCount(
              a.openItemCount,
              one: l10n.missingCountOne,
              two: l10n.missingCountTwo,
              few: l10n.missingCountFew,
              many: l10n.missingCountMany,
            ),
            colors: tokens.status(TaskStatus.waiting),
          )
        : null;

    return _SectionRow(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                _Parts([
                  Text(l10n.annexRowTitle(number == null ? '' : AppFormats.number(number)), style: title),
                  if (a.subject.isNotEmpty) StoredText(a.subject, style: AppTextStyles.body.copyWith(color: tokens.ink)),
                  if (a.signedOn case final signed?) Text(AppFormats.fullDate(signed), style: meta),
                ], style: meta),
                if (changes.isNotEmpty) _Parts(changes, style: meta),
              ],
            ),
          ),
          ?badge,
        ],
      ),
    );
  }
}

/// The storage contracts under a lease, newest first (by start date, then
/// signing date; undated last).
List<ContractRecord> sortedStorage(List<ContractRecord> children) {
  DateTime? from(ContractRecord c) => c.startsOn ?? c.signedOn;
  return [
    for (final c in children)
      if (c.kind == ContractKind.storage) c,
  ]..sort((a, b) => switch ((from(a), from(b))) {
        (final x?, final y?) => y.compareTo(x),
        (null, null) => 0,
        (null, _) => 1,
        (_, null) => -1,
      });
}

/// The ids of the storage contracts that get «تجديد للموسم التالي»: the
/// newest for each set of units ([storage] in [sortedStorage]'s order).
Set<String> renewableStorage(List<ContractRecord> storage) {
  final seen = <String>{};
  return {
    for (final c in storage)
      if (seen.add((c.units.map((u) => u.id).toList()..sort()).join(','))) c.id,
  };
}

/// «المخازن (n)» on a lease: a row per storage contract, «STOR-ST03 · مفتاح
/// ٣٠٤ · start – end · ٥٧ م²». A row opens the contract form on it; the
/// newest per unit has «تجديد للموسم التالي»; «+ إضافة عقد مخزن» starts a
/// new one. [onAdd] and [onRenew] null hide those (a terminated lease).
class ContractStorageSection extends StatelessWidget {
  const ContractStorageSection({
    super.key,
    required this.storage,
    required this.onOpen,
    required this.onRenew,
    required this.onAdd,
  });

  /// In order ([sortedStorage]).
  final List<ContractRecord> storage;
  final ValueChanged<ContractRecord>? onOpen;
  final ValueChanged<ContractRecord>? onRenew;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final renewable = renewableStorage(storage);
    final onOpen = this.onOpen;
    final onRenew = this.onRenew;
    return Column(
      key: const Key('contract-storage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        DrawerSectionHeader(
          title: l10n.contractStorageTitle(AppFormats.number(storage.length)),
          addLabel: l10n.contractAddStorage,
          addKey: const Key('contract-add-storage'),
          onAdd: onAdd,
        ),
        for (final s in storage)
          _StorageRow(
            key: ValueKey('storage-${s.id}'),
            storage: s,
            onTap: onOpen == null ? null : () => onOpen(s),
            onRenew: onRenew == null || !renewable.contains(s.id) ? null : () => onRenew(s),
          ),
      ],
    );
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow({super.key, required this.storage, required this.onTap, required this.onRenew});

  final ContractRecord storage;
  final VoidCallback? onTap;
  final VoidCallback? onRenew;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final s = storage;
    final title = AppTextStyles.body.copyWith(color: tokens.ink, fontWeight: FontWeight.w600);
    final meta = AppTextStyles.meta.copyWith(color: tokens.textMuted);
    final from = s.startsOn ?? s.signedOn;
    final to = s.endsOn;
    final area = s.areaInner ?? s.areaOuter;
    final keys = {for (final unit in s.units) ?unit.keyNumber};
    final renew = onRenew;

    // «تجديد للموسم التالي» sits under the lines, so a phone row keeps its
    // width for the codes and dates.
    return _SectionRow(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          _Parts([
            for (final unit in s.units) Text(unit.code, textDirection: TextDirection.ltr, style: title),
            for (final key in keys) Text(l10n.unitKeyHint(key), style: meta),
          ], style: meta),
          _Parts([
            if (from != null || to != null)
              Text(
                [
                  if (from != null) AppFormats.fullDate(from),
                  if (to != null) AppFormats.fullDate(to),
                ].join(' – '),
                style: meta,
              )
            else if (s.dateNote.isNotEmpty)
              StoredText(s.dateNote, style: meta),
            if (area != null) Text(l10n.contractArea(AppFormats.number(area)), style: meta),
          ], style: meta),
          if (renew != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 4),
              child: OutlinedButton(
                key: Key('storage-renew-${s.id}'),
                onPressed: renew,
                style: quietOutlineButtonStyle(context),
                child: Text(l10n.storageRenew),
              ),
            ),
        ],
      ),
    );
  }
}
