import '../../../core/domain/unit_kind.dart';
import '../../../core/format/arabic_normalize.dart';
import '../data/contract_refs.dart';
import '../data/contract_save_failure.dart';
import '../data/contracts_repository.dart';

/// What a form's tenant, units and wording fields ask through their bloc:
/// the suggestions, and the records «+ إضافة» makes. Shared by the contract
/// form and the annex form, so both fields behave the same.
mixin ContractLookups {
  ContractsRepository get lookupRepository;

  /// The file the units belong to; null until one is chosen.
  String? get lookupFileId;

  /// The unit kinds the units field suggests; null for all.
  List<UnitKind>? get lookupUnitKinds;

  Future<List<PartySuggestion>> suggestParties(String query) => lookupRepository.suggestParties(query);

  /// The file's units, of [lookupUnitKinds].
  Future<List<UnitSuggestion>> suggestUnits(String query) {
    final fileId = lookupFileId;
    if (fileId == null) return Future.value(const []);
    return lookupRepository.suggestUnits(fileId, query, kinds: lookupUnitKinds);
  }

  Future<List<ValueSuggestion>> suggestValues(SuggestValueField field, String query) =>
      lookupRepository.suggestValues(field, query);

  /// Throws [ContractSaveException].
  Future<PartyRef> createParty(String name) => lookupRepository.createParty(name);

  /// The units [codes] name in the file: existing ones (same code key) as
  /// they are, and [missing] codes, which [createUnits] makes.
  Future<({List<UnitRef> found, List<String> missing})> findUnits(List<String> codes) async {
    final fileId = lookupFileId;
    if (fileId == null) return (found: const <UnitRef>[], missing: codes);
    final found = <UnitRef>[];
    final missing = <String>[];
    for (final code in codes) {
      final key = unitCodeKey(code);
      final rows = await lookupRepository.suggestUnits(fileId, code);
      final match = rows.where((row) => unitCodeKey(row.unit.code) == key).firstOrNull;
      if (match == null) {
        missing.add(code);
      } else {
        found.add(match.unit);
      }
    }
    return (found: found, missing: missing);
  }

  /// New units [codes] in the file, of [kind]; [keyNumber] goes on a single
  /// storage unit. Throws [ContractSaveException] on the first that fails,
  /// after keeping those made before it in [made].
  Future<List<UnitRef>> createUnits(List<String> codes, UnitKind kind, {String? keyNumber, List<UnitRef>? made}) async {
    final fileId = lookupFileId!;
    final units = made ?? <UnitRef>[];
    for (final code in codes) {
      units.add(await lookupRepository.createUnit(fileId: fileId, code: code, kind: kind, keyNumber: keyNumber));
    }
    return units;
  }
}
