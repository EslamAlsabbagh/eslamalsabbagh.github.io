import 'package:equatable/equatable.dart';

import '../../../core/domain/contract_kind.dart';
import '../../../core/domain/contract_list_status.dart';
import '../data/contract_list_item.dart';

/// «النوع» on the «العقود» filter row.
enum ContractKindFilter {
  all,

  /// «وحدات»: leases.
  units,

  /// «مخازن»: storage contracts, and leases with storage contracts linked
  /// to them (those never get their own row; chosen 2026-11-12).
  storage,

  /// «خدمات وأخرى».
  servicesOther;

  bool matches(ContractListItem contract) => switch (this) {
        all => true,
        units => contract.kind == ContractKind.lease,
        storage => contract.kind == ContractKind.storage || contract.storageCount > 0,
        servicesOther => contract.kind == ContractKind.service || contract.kind == ContractKind.other,
      };
}

/// «الحالة» on the «العقود» filter row. Any choice but [all] leaves out the
/// terminated contracts, so their «الملغاة» toggle goes too.
enum ContractStatusFilter {
  all,

  /// «سارية»: everything in force, those ending within 90 days included
  /// (chosen 2026-11-12).
  inForce,

  /// «تنتهي خلال ٩٠ يومًا».
  ending,

  /// «منتهية».
  expired;

  bool matches(ContractListItem contract) => switch (this) {
        all => true,
        inForce => contract.listStatus == ContractListStatus.active || contract.listStatus == ContractListStatus.ending,
        ending => contract.listStatus == ContractListStatus.ending,
        expired => contract.listStatus == ContractListStatus.expired,
      };
}

/// The filter row's choices (DESIGN_SPEC §4 "View 4 — العقود"). Each group is
/// one choice; the default is everything.
final class ContractFilters extends Equatable {
  const ContractFilters({
    this.kind = ContractKindFilter.all,
    this.status = ContractStatusFilter.all,
    this.missingOnly = false,
    this.season,
  });

  final ContractKindFilter kind;
  final ContractStatusFilter status;

  /// «بها نواقص»: only contracts with open checklist items.
  final bool missingOnly;

  /// A signing year, or null for «كل المواسم».
  final int? season;

  bool get isActive => this != const ContractFilters();

  bool matches(ContractListItem contract) =>
      kind.matches(contract) &&
      status.matches(contract) &&
      (!missingOnly || contract.openItemCount > 0) &&
      (season == null || contract.season == season);

  ContractFilters copyWith({
    ContractKindFilter? kind,
    ContractStatusFilter? status,
    bool? missingOnly,
    int? Function()? season,
  }) =>
      ContractFilters(
        kind: kind ?? this.kind,
        status: status ?? this.status,
        missingOnly: missingOnly ?? this.missingOnly,
        season: season != null ? season() : this.season,
      );

  @override
  List<Object?> get props => [kind, status, missingOnly, season];
}
