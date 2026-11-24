part of 'contracts_bloc.dart';

sealed class ContractsEvent extends Equatable {
  const ContractsEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) the list. Added when the tab first opens and on retry.
final class ContractsLoadRequested extends ContractsEvent {
  const ContractsLoadRequested();
}

/// Reload quietly after a change heard from Realtime or at midnight: the list
/// stays on screen, and a failure keeps it (it is only logged).
final class ContractsRefreshRequested extends ContractsEvent {
  const ContractsRefreshRequested();
}

/// The search field changed. The bloc waits for a short pause in typing,
/// then searches once there are at least [ContractsState.minSearchLength]
/// letters.
final class ContractsSearchChanged extends ContractsEvent {
  const ContractsSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// A filter changed (one group at a time, or «مسح الاختيارات»).
final class ContractsFiltersChanged extends ContractsEvent {
  const ContractsFiltersChanged(this.filters);

  final ContractFilters filters;

  @override
  List<Object?> get props => [filters];
}

/// «عرض / إخفاء الملغاة» in [fileId]'s section.
final class ContractsTerminatedToggled extends ContractsEvent {
  const ContractsTerminatedToggled(this.fileId);

  final String fileId;

  @override
  List<Object?> get props => [fileId];
}
