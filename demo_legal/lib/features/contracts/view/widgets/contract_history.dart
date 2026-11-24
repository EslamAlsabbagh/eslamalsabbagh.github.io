import 'package:flutter/material.dart';

import '../../../../core/format/app_formats.dart';
import '../../../../core/format/relative_time.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../tasks/view/widgets/expand_toggle.dart';
import '../../data/contract_activity_entry.dart';

/// One line of a contract's history: who, what, when.
class ContractHistoryLine {
  const ContractHistoryLine({required this.key, required this.entry, required this.text});

  /// Unique within the history (an entry may give several lines).
  final String key;
  final ContractActivityEntry entry;
  final String text;
}

/// The lines [entries] read as, newest first (DESIGN_SPEC §4 "Contract
/// drawer" → «سجل التغييرات»). The verb is masculine for everyone, as in the
/// task history.
///
/// - A grouped row gives one line per value that changed: «غيّر تاريخ
///   النهاية من … إلى …», then «عدّل ملاحظة التاريخ».
/// - The units a contract was created with are part of «أنشأ العقد»: the
///   `units_changed` rows written in the same transaction (same time, same
///   row) are left out.
/// - A row about an annex or storage contract under [contractId] reads
///   «أضاف ملحق ٢: مد فترة السماح», «أضاف عقد مخزن», «حذف ملحق ٢»; any
///   other change is worded as for the contract, after the row's name:
///   «ملحق ٢: غيّر تاريخ النهاية من … إلى …», «عقد المخزن: …» (chosen
///   2026-11-15).
/// - An annex's number is [annexNumbers]' (the rows loaded with the drawer,
///   so a renumbered annex reads its current number), or else its creation's.
/// - Checklist rows read «أضاف نقصًا: …», «استوفى: …». One about an item on
///   an annex or storage contract adds where, as the checklist's rows do:
///   «أضاف نقصًا: ختم الملحق على ملحق ٢» (chosen 2026-11-15). The place is
///   [targetLabels]' (the checklist's «على» labels, by id), or else, for a
///   row no longer loaded, «ملحق ٢» / «عقد المخزن».
List<ContractHistoryLine> contractHistoryLines(
  AppLocalizations l10n,
  List<ContractActivityEntry> entries, {
  required String contractId,
  Map<String, int> annexNumbers = const {},
  Map<String, String> targetLabels = const {},
}) {
  // What each row under the contract is, from its creation (or deletion).
  final children = <String, Map<String, dynamic>>{};
  final createdAt = <String, DateTime>{};
  for (final entry in entries) {
    if (entry.action == ContractActivityAction.created) {
      createdAt[entry.targetId] = entry.createdAt;
      if (entry.targetId != contractId) children[entry.targetId] = entry.newMap;
    } else if (entry.action == ContractActivityAction.deleted) {
      children.putIfAbsent(entry.targetId, () => entry.oldMap);
    }
  }

  /// The child row's annex number as shown, or null for a storage contract.
  String? annexNumber(String targetId) {
    final row = children[targetId] ?? const {};
    final number = annexNumbers[targetId] ?? row['annex_no'];
    if (row['kind'] != 'annex' && number == null) return null;
    return number == null ? '' : AppFormats.number(number as num);
  }

  String child(String targetId, {required String Function(String n) annex, required String storage}) =>
      switch (annexNumber(targetId)) {
        final String n => annex(n),
        null => storage,
      };

  /// A checklist row's [line], with where its item is unless that is the
  /// contract itself.
  String onItem(Map<String, dynamic> row, String line) {
    final on = row['contract_id'];
    if (on is! String || on == contractId) return line;
    final target = targetLabels[on] ??
        child(on, annex: l10n.annexRowTitle, storage: l10n.contractHistItemOnStorage);
    return l10n.contractHistItemOn(line, target);
  }

  String date(Object? value) => value is String ? AppFormats.fullDate(DateTime.parse(value)) : l10n.contractNoDate;
  String area(Object? value) => value is num ? l10n.contractArea(AppFormats.number(value)) : l10n.contractNoArea;

  final lines = <ContractHistoryLine>[];
  for (final entry in entries) {
    final texts = <String>[];
    final old = entry.oldMap;
    final now = entry.newMap;
    bool changed(String key) => old[key] != now[key];
    final onChild = entry.targetId != contractId;
    // A change to an annex or storage row is worded as for the contract,
    // then named; its creation, deletion and checklist rows are not.
    var named = onChild;

    switch (entry.action) {
      case ContractActivityAction.itemAdded:
        named = false;
        texts.add(onItem(now, l10n.contractHistItemAdded('${now['label'] ?? ''}')));
      case ContractActivityAction.itemResolved:
        named = false;
        texts.add(onItem(now, l10n.contractHistItemResolved('${now['label'] ?? ''}')));
      case ContractActivityAction.itemReopened:
        named = false;
        texts.add(onItem(now, l10n.contractHistItemReopened('${now['label'] ?? ''}')));
      case ContractActivityAction.itemDeleted:
        named = false;
        final row = now.isNotEmpty ? now : old;
        texts.add(onItem(row, l10n.contractHistItemDeleted('${row['label'] ?? ''}')));
      case ContractActivityAction.created when onChild:
        named = false;
        final subject = '${now['subject'] ?? ''}'.trim();
        texts.add(child(
          entry.targetId,
          annex: (n) => subject.isEmpty ? l10n.contractHistAddedAnnex(n) : l10n.contractHistAddedAnnexSubject(n, subject),
          storage: l10n.contractHistAddedStorage,
        ));
      case ContractActivityAction.deleted:
        named = false;
        texts.add(child(entry.targetId, annex: l10n.contractHistDeletedAnnex, storage: l10n.contractHistDeletedStorage));
      case ContractActivityAction.unitsChanged when createdAt[entry.targetId] == entry.createdAt:
        break;
      case ContractActivityAction.created:
        texts.add(l10n.contractHistCreated);
      case ContractActivityAction.statusChanged:
        final reason = '${now['termination_reason'] ?? ''}'.trim();
        texts.add(switch ((old['status'], now['status'])) {
          (_, 'terminated') => reason.isEmpty ? l10n.contractTerminate : l10n.contractHistTerminated(reason),
          ('terminated', 'active') => l10n.contractHistReopened,
          // From a draft, before drafts were dropped (2026-11-15).
          _ => l10n.contractHistActivated,
        });
      case ContractActivityAction.partyChanged:
        String name(Object? id, String? named) => id == null ? l10n.contractNoParty : named ?? l10n.contractOtherParty;
        texts.add(l10n.contractHistParty(name(entry.oldValue, entry.oldName), name(entry.newValue, entry.newName)));
      case ContractActivityAction.topicChanged:
        String name(Object? id, String? named) => id == null ? l10n.contractNoBrand : named ?? l10n.contractValueNone;
        texts.add(l10n.contractHistBrand(name(entry.oldValue, entry.oldName), name(entry.newValue, entry.newName)));
      case ContractActivityAction.datesChanged:
        if (changed('signed_on')) texts.add(l10n.contractHistSigned(date(old['signed_on']), date(now['signed_on'])));
        if (changed('starts_on')) texts.add(l10n.contractHistStarts(date(old['starts_on']), date(now['starts_on'])));
        if (changed('ends_on')) texts.add(l10n.contractHistEnds(date(old['ends_on']), date(now['ends_on'])));
        if (changed('date_note')) texts.add(l10n.contractHistDateNote);
      case ContractActivityAction.areasChanged:
        if (changed('area_inner')) {
          texts.add(l10n.contractHistAreaInner(area(old['area_inner']), area(now['area_inner'])));
        }
        if (changed('area_outer')) {
          texts.add(l10n.contractHistAreaOuter(area(old['area_outer']), area(now['area_outer'])));
        }
        if (changed('area_note')) texts.add(l10n.contractHistAreaNote);
      case ContractActivityAction.detailsChanged:
        if (changed('annex_no')) {
          String number(Object? value) => value is num ? AppFormats.number(value) : l10n.contractValueNone;
          texts.add(l10n.contractHistAnnexNo(number(old['annex_no']), number(now['annex_no'])));
        }
        if (changed('subject')) {
          texts.add(onChild && annexNumber(entry.targetId) != null ? l10n.contractHistAnnexSubject : l10n.contractHistSubject);
        }
        if (changed('activity')) texts.add(l10n.contractHistActivity);
        if (changed('notes')) texts.add(l10n.contractHistNotes);
      case ContractActivityAction.unitsChanged:
        if (now['code'] case final String code) texts.add(l10n.contractHistUnitAdded(code));
        if (old['code'] case final String code) texts.add(l10n.contractHistUnitRemoved(code));
    }
    for (final (index, text) in texts.indexed) {
      final shown = named
          ? child(entry.targetId, annex: (n) => l10n.contractHistOnAnnex(n, text), storage: l10n.contractHistOnStorage(text))
          : text;
      lines.add(ContractHistoryLine(key: '${entry.id}-$index', entry: entry, text: shown));
    }
  }
  return lines;
}

/// «سجل التغييرات» at the end of the contract drawer: the task drawer's
/// toggle and rows, closed by default, hidden while nothing is readable.
class ContractHistory extends StatefulWidget {
  const ContractHistory({
    super.key,
    required this.entries,
    required this.contractId,
    required this.now,
    this.annexNumbers = const {},
    this.targetLabels = const {},
  });

  final List<ContractActivityEntry> entries;
  final String contractId;
  final DateTime now;

  /// The loaded annexes' current numbers, by id ([contractHistoryLines]).
  final Map<String, int> annexNumbers;

  /// The checklist's «على» labels of the rows under the contract, by id.
  final Map<String, String> targetLabels;

  @override
  State<ContractHistory> createState() => _ContractHistoryState();
}

class _ContractHistoryState extends State<ContractHistory> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lines = contractHistoryLines(l10n, widget.entries,
        contractId: widget.contractId, annexNumbers: widget.annexNumbers, targetLabels: widget.targetLabels);
    if (lines.isEmpty) return const SizedBox.shrink();
    final count = AppFormats.number(lines.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ExpandToggle(
            buttonKey: const Key('contract-activity-toggle'),
            expanded: _expanded,
            label: _expanded ? l10n.hideActivity(count) : l10n.showActivity(count),
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
        ),
        if (_expanded)
          for (final line in lines) _HistoryRow(line: line, now: widget.now),
      ],
    );
  }
}

/// The task history's row: a dot, the actor (600) and the change, the time
/// under it, a separator. Read as one line.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.line, required this.now});

  final ContractHistoryLine line;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final entry = line.entry;
    final actor = entry.actorId == null ? l10n.activitySystem : entry.actorName ?? l10n.formerEmployee;
    final style = AppTextStyles.meta.copyWith(height: 1.6, color: tokens.ink);
    return Semantics(
      container: true,
      child: Row(
        key: ValueKey('contract-activity-${line.key}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(color: tokens.borderStrong, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 6),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.dividerSubtle))),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 10 + 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: actor, style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: ' ${line.text}'),
                      ]),
                      style: style,
                    ),
                    Text(
                      RelativeTime.format(l10n, entry.createdAt, now: now),
                      style: AppTextStyles.badge.copyWith(fontWeight: FontWeight.w400, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
