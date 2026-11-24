import '../../../core/domain/contract_item_kind.dart';
import '../../../core/domain/contract_kind.dart';
import '../../../core/domain/contract_list_status.dart';
import '../bloc/contract_groups.dart';
import '../data/contract_item.dart';
import '../data/contract_register_data.dart';
import 'register_document.dart';
import 'register_labels.dart';

/// Lays out the register for the list's sections ([groups], as shown: the
/// file chip, the search and the filters applied), like the firm's workbook
/// (DESIGN_SPEC §4 View 4 "Export and print", ADR-0013 amendment
/// 2026-11-16):
/// - a sheet per file with its current contracts, then «{file} - الملغاة»
///   with its terminated ones, when it has any
/// - a band per signing year, newest first, undated last, «م» restarting
/// - per main contract, its row as signed, then its annexes by date, then
///   each storage contract followed by its own annexes
/// - only open checklist items and open follow-ups ([data] holds no others)
///
/// A contract missing from [data] (deleted meanwhile) is left out.
RegisterDocument buildRegister({
  required List<FileContracts> groups,
  required ContractRegisterData data,
  required RegisterLabels labels,
}) {
  final index = _Index(data);
  final names = <String>{};
  final sheets = <RegisterSheet>[];
  for (final group in groups) {
    final file = group.file.name;
    final current = _bands(group.current.map((c) => c.id), index, labels, terminated: false, file: file);
    if (current.isNotEmpty) sheets.add(RegisterSheet(name: _sheetName(file, names), bands: current));
    final terminated = _bands(group.terminated.map((c) => c.id), index, labels, terminated: true, file: file);
    if (terminated.isNotEmpty) {
      final name = _sheetName(file, names, build: labels.terminatedSheetName);
      sheets.add(RegisterSheet(name: name, bands: terminated));
    }
  }
  return RegisterDocument(headers: labels.headers, legend: labels.legend, sheets: sheets);
}

/// The open items and follow-ups, by what they belong to, and the rows
/// under each contract.
class _Index {
  _Index(this.data) {
    for (final contract in data.contracts.values) {
      if (contract.parentId case final parent?) children.putIfAbsent(parent, () => []).add(contract);
    }
    for (final item in data.items) {
      switch (item.kind) {
        case ContractItemKind.missing:
          missing.putIfAbsent(item.contractId!, () => []).add(item);
        case ContractItemKind.document:
          documents.putIfAbsent(item.partyId!, () => []).add(item);
      }
    }
    for (final task in data.followUps) {
      followUps.putIfAbsent(task.contractId, () => []).add(task.title);
    }
  }

  final ContractRegisterData data;
  final children = <String, List<RegisterContract>>{};
  final missing = <String, List<ContractItem>>{};
  final documents = <String, List<ContractItem>>{};
  final followUps = <String, List<String>>{};

  List<RegisterContract> under(String id, ContractKind kind) =>
      (children[id] ?? const <RegisterContract>[]).where((c) => c.kind == kind).toList()..sort(_byDate);
}

List<RegisterBand> _bands(
  Iterable<String> ids,
  _Index index,
  RegisterLabels labels, {
  required bool terminated,
  required String file,
}) {
  final bySeason = <int?, List<RegisterContract>>{};
  for (final id in ids) {
    final main = index.data.mains[id];
    final contract = index.data.contracts[id];
    if (main == null || contract == null) continue;
    bySeason.putIfAbsent(main.season, () => []).add(contract);
  }
  final seasons = bySeason.keys.toList()
    ..sort((a, b) {
      if (a == null) return b == null ? 0 : 1;
      if (b == null) return -1;
      return b.compareTo(a);
    });
  return [
    for (final season in seasons)
      RegisterBand(
        title: terminated ? labels.terminatedBandTitle(file, season) : labels.bandTitle(file, season),
        groups: [
          for (final (i, contract) in (bySeason[season]!..sort(_byDate)).indexed)
            _group(i + 1, contract, index.data.mains[contract.id]!, index, labels, terminated: terminated),
        ],
      ),
  ];
}

RegisterGroup _group(
  int number,
  RegisterContract main,
  RegisterMain list,
  _Index index,
  RegisterLabels labels, {
  required bool terminated,
}) {
  final annexes = index.under(main.id, ContractKind.annex);
  final storages = index.under(main.id, ContractKind.storage);

  // Each term (the main contract, and each storage contract) has its own
  // status from `contract_end_status`. Its tint goes where its effective end
  // date is: its own row, or the annex that set it. The terminated sheet has
  // none.
  RegisterTone tone(RegisterContract c) => terminated
      ? RegisterTone.none
      : switch (index.data.ends[c.id]?.listStatus) {
          ContractListStatus.expired => RegisterTone.expired,
          ContractListStatus.ending => RegisterTone.ending,
          _ => RegisterTone.none,
        };
  RegisterContract? toneAnnex(RegisterContract c, List<RegisterContract> annexes) {
    final number = index.data.ends[c.id]?.endsOnAnnexNo;
    return number == null ? null : annexes.where((a) => a.annexNo == number).firstOrNull;
  }

  RegisterTone ownTone(RegisterContract c, List<RegisterContract> annexes) =>
      toneAnnex(c, annexes) == null ? tone(c) : RegisterTone.none;
  RegisterTone? annexTone(RegisterContract annex, RegisterContract parent, List<RegisterContract> annexes) =>
      identical(annex, toneAnnex(parent, annexes)) ? tone(parent) : null;

  final seenParties = <String>{};
  RegisterRow row(RegisterContract c, RegisterRowKind kind, {String? tenant, String? brand, RegisterTone? ends}) {
    final docs = c.partyId != null && seenParties.add(c.partyId!) ? index.documents[c.partyId!] : null;
    String? notes = c.notes.isEmpty ? null : c.notes;
    if (terminated && kind == RegisterRowKind.main) {
      final note = labels.terminatedNote(
        list.terminatedOn == null ? null : registerDateText(list.terminatedOn!),
        list.terminationReason,
      );
      notes = notes == null ? note : '$note\n$notes';
    }
    final duration = kind == RegisterRowKind.annex ? null : _months(c.startsOn ?? c.signedOn, c.endsOn);
    final noAreas = c.areaInner == null && c.areaOuter == null;

    final cells = List<RegisterValue?>.filled(RegisterColumn.values.length, null);
    void put(RegisterColumn column, RegisterValue? value) => cells[column.index] = value;
    put(RegisterColumn.number, kind == RegisterRowKind.main ? RegisterNumber(number) : null);
    put(RegisterColumn.tenant, _text(tenant));
    put(RegisterColumn.brand, _text(brand));
    put(
      RegisterColumn.units,
      _text([
        for (final u in [...c.units]..sort((a, b) => a.code.compareTo(b.code)))
          u.keyNumber == null ? u.code : labels.unitWithKey(u.code, u.keyNumber!),
      ].join(' + ')),
    );
    put(RegisterColumn.activity, _text(c.activity));
    put(
      RegisterColumn.subject,
      _text(kind == RegisterRowKind.annex
          ? labels.annexSubject(c.annexNo, c.subject)
          : labels.subject(c.kind, c.subject)),
    );
    put(
      RegisterColumn.signedOn,
      c.signedOn != null
          ? RegisterDate(c.signedOn!)
          : (c.endsOn != null ? _text(c.dateNote) : null),
    );
    put(RegisterColumn.endsOn, c.endsOn != null ? RegisterDate(c.endsOn!) : _text(c.dateNote));
    put(RegisterColumn.duration, duration == null ? null : _text(labels.duration(duration)));
    put(
      RegisterColumn.areaInner,
      c.areaInner != null ? RegisterNumber(c.areaInner!) : (noAreas ? _text(c.areaNote) : null),
    );
    put(RegisterColumn.areaOuter, c.areaOuter != null ? RegisterNumber(c.areaOuter!) : null);
    put(RegisterColumn.documents, _lines(docs, (item) => _join(item.label, item.detail)));
    put(
      RegisterColumn.missing,
      _lines(index.missing[c.id], (item) {
        final needs = labels.needs(signature: item.needsSignature, stamp: item.needsStamp);
        final text = _join('${item.label} ($needs)', item.detail);
        return item.side == ContractItemSide.us ? _join(text, labels.ourSide) : text;
      }),
    );
    put(RegisterColumn.notes, _text(notes));
    put(RegisterColumn.followUps, _lines(index.followUps[c.id], (title) => title));
    return RegisterRow(kind: kind, cells: cells, endsTone: ends ?? RegisterTone.none);
  }

  // A row under the main one shows a tenant or brand only when it is its
  // own: an annex's transfer, or a storage contract's other tenant or brand.
  String? ownTenant(RegisterContract c) =>
      c.kind == ContractKind.annex ? c.partyName : (c.partyName != main.partyName ? c.partyName : null);
  String? ownBrand(RegisterContract c) =>
      c.kind == ContractKind.storage && c.brand != null && c.brand != main.brand ? c.brand : null;

  // Each row under the main one, with its end date's tint.
  final under = <(RegisterContract, RegisterRowKind, RegisterTone?)>[
    for (final annex in annexes) (annex, RegisterRowKind.annex, annexTone(annex, main, annexes)),
    for (final storage in storages) ...() {
      final own = index.under(storage.id, ContractKind.annex);
      return [
        (storage, RegisterRowKind.storage, ownTone(storage, own)),
        for (final annex in own) (annex, RegisterRowKind.annex, annexTone(annex, storage, own)),
      ];
    }(),
  ];
  final rows = [
    row(main, RegisterRowKind.main, tenant: main.partyName, brand: main.brand, ends: ownTone(main, annexes)),
    for (final (c, kind, ends) in under) row(c, kind, tenant: ownTenant(c), brand: ownBrand(c), ends: ends),
  ];
  return RegisterGroup(
    rows: rows,
    mergeTenant: under.every((u) => _blank(ownTenant(u.$1))),
    mergeBrand: under.every((u) => _blank(ownBrand(u.$1))),
  );
}

/// Signing date, oldest first, undated last; then as entered.
int _byDate(RegisterContract a, RegisterContract b) {
  final x = a.signedOn, y = b.signedOn;
  final dates = x == null ? (y == null ? 0 : 1) : (y == null ? -1 : x.compareTo(y));
  if (dates != 0) return dates;
  final numbers = (a.annexNo ?? 0).compareTo(b.annexNo ?? 0);
  if (numbers != 0) return numbers;
  final created = a.createdAt.compareTo(b.createdAt);
  return created != 0 ? created : a.id.compareTo(b.id);
}

/// Whole months from [start] to the day after [end], as `contract_list`'s
/// `duration_months` counts them (`age(ends_on + 1, starts_on)`); null when
/// either date is missing or there is no whole month.
int? _months(DateTime? start, DateTime? end) {
  if (start == null || end == null) return null;
  final after = DateTime.utc(end.year, end.month, end.day + 1);
  var months = (after.year - start.year) * 12 + after.month - start.month;
  if (after.day < start.day) months -= 1;
  return months > 0 ? months : null;
}

RegisterText? _text(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : RegisterText(text);
}

RegisterText? _lines<T>(List<T>? items, String Function(T) line) =>
    items == null || items.isEmpty ? null : _text(items.map(line).join('\n'));

String _join(String text, String detail) => detail.isEmpty ? text : '$text — $detail';

bool _blank(String? value) => value == null || value.trim().isEmpty;

/// A valid, unique sheet name: Excel allows 31 characters and none of
/// `[]:*?/\`, and no apostrophe at either end. The file's name is cut, so
/// what [build] adds around it («- الملغاة») stays whole.
String _sheetName(String file, Set<String> taken, {String Function(String file)? build}) {
  String clean(String s) => s.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  String fit(String extra) {
    var cut = clean(file);
    String compose() {
      final name = clean(build == null ? cut : build(cut)).replaceAll(RegExp(r"^'+|'+$"), '');
      return '$name$extra';
    }

    while (compose().length > 31 && cut.isNotEmpty) {
      cut = cut.substring(0, cut.length - 1).trim();
    }
    final name = compose();
    return name.trim().isEmpty ? 'Sheet$extra' : name;
  }

  var name = fit('');
  for (var n = 2; taken.contains(name); n++) {
    name = fit(' ($n)');
  }
  taken.add(name);
  return name;
}
