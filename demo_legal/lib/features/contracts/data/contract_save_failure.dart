/// Why a contract, party or unit wasn't saved, or a contract wasn't deleted, in
/// terms the form and drawer can show.
enum ContractSaveFailure {
  /// RLS refused (0 rows, or a policy check), or a lawyer reopening a
  /// terminated contract (`contracts_reopen_guard`).
  notAllowed,

  /// `parties_name_normalized_key`: a party with the same normalized name.
  duplicateParty,

  /// `units_file_id_code_key_key`: a unit with the same code key in the file.
  duplicateUnit,

  /// `contracts_annex_no_key`: the contract already has an annex with this
  /// number.
  duplicateAnnexNo,

  /// A delete the foreign keys refused: something was added under the contract
  /// since the drawer read it.
  notEmpty,

  /// A shape, file or brand rule (`23514`): a unit or brand of another file,
  /// a lease without a brand, follow-ups under the brand being changed.
  rejected,

  /// No response from the server.
  network,
  unknown;

  /// Maps an error from a contract, party or unit write. PostgREST gives the
  /// SQLSTATE but not the constraint, so a duplicate is told apart by the
  /// constraint name in its message. Anything that isn't a PostgREST error
  /// came from the HTTP layer, as in `TaskSaveFailure.fromError`.
  static ContractSaveFailure fromError(Object error) => switch (error) {
        ContractSaveException(:final failure) => failure,
        _ => network,
      };
}

/// Thrown by the `ContractsRepository` writes.
class ContractSaveException implements Exception {
  const ContractSaveException(this.failure);

  final ContractSaveFailure failure;

  @override
  String toString() => 'ContractSaveException($failure)';
}
