part of 'contracts_bloc.dart';

enum ContractsStatus { initial, loading, success, failure }

/// The search's request state. [idle] means there is no search.
enum ContractsSearchStatus { idle, loading, success, failure }

/// Every visible main contract plus the tab's search, filters and open
/// toggles. The file chip is the shell's (`TasksState.selectedFileId`), so
/// the derived lists take the selected file (and the files) as arguments.
final class ContractsState extends Equatable {
  const ContractsState({
    this.status = ContractsStatus.initial,
    this.contracts = const [],
    this.filters = const ContractFilters(),
    this.searchQuery = '',
    this.searchStatus = ContractsSearchStatus.idle,
    this.searchIds,
    this.searchedTerm = '',
    this.openTerminated = const {},
  });

  /// A search starts at this many letters, as on «اليوم».
  static const int minSearchLength = 2;

  final ContractsStatus status;
  final List<ContractListItem> contracts;
  final ContractFilters filters;

  /// What is in the search field, as typed.
  final String searchQuery;
  final ContractsSearchStatus searchStatus;

  /// The matches for [searchedTerm], or null when no search result is shown.
  /// The previous result stays while the next one loads, so rows don't flicker.
  final Set<String>? searchIds;

  /// The term [searchIds] belong to; the result line quotes it.
  final String searchedTerm;

  /// Files whose «الملغاة» toggle is open.
  final Set<String> openTerminated;

  /// The query the database is asked about.
  String get searchTerm => searchQuery.trim();

  /// Contracts in the selected file (all of them when none is selected).
  List<ContractListItem> fileScoped(String? fileId) =>
      fileId == null ? contracts : contracts.where((c) => c.fileId == fileId).toList();

  /// [fileScoped] narrowed to the search matches.
  List<ContractListItem> _searched(String? fileId) {
    final ids = searchIds;
    final scoped = fileScoped(fileId);
    return ids == null ? scoped : scoped.where((c) => ids.contains(c.id)).toList();
  }

  /// What the list shows: the file chip, the search and the filters.
  List<ContractListItem> visible(String? fileId) => _searched(fileId).where(filters.matches).toList();

  /// The sections, in chip order.
  List<FileContracts> groups(List<TaskFile> files, String? fileId) => buildContractGroups(
        files: fileId == null ? files : files.where((f) => f.id == fileId).toList(),
        contracts: visible(fileId),
      );

  /// Matches shown (those in the toggles too), or null when no search result
  /// is shown.
  int? searchResultCount(String? fileId) => searchIds == null ? null : visible(fileId).length;

  /// The search found nothing in the file, whatever the filters.
  bool searchFoundNothing(String? fileId) => searchIds != null && _searched(fileId).isEmpty;

  /// The «الموسم» choices: the signing years in the file, newest first, plus
  /// the chosen one, so the select always holds its value.
  List<int> seasons(String? fileId) {
    final years = <int>{
      for (final c in fileScoped(fileId)) ?c.season,
      ?filters.season,
    }.toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  ContractsState copyWith({
    ContractsStatus? status,
    List<ContractListItem>? contracts,
    ContractFilters? filters,
    String? searchQuery,
    ContractsSearchStatus? searchStatus,
    Set<String>? Function()? searchIds,
    String? searchedTerm,
    Set<String>? openTerminated,
  }) =>
      ContractsState(
        status: status ?? this.status,
        contracts: contracts ?? this.contracts,
        filters: filters ?? this.filters,
        searchQuery: searchQuery ?? this.searchQuery,
        searchStatus: searchStatus ?? this.searchStatus,
        searchIds: searchIds != null ? searchIds() : this.searchIds,
        searchedTerm: searchedTerm ?? this.searchedTerm,
        openTerminated: openTerminated ?? this.openTerminated,
      );

  @override
  List<Object?> get props => [
        status,
        contracts,
        filters,
        searchQuery,
        searchStatus,
        searchIds,
        searchedTerm,
        openTerminated,
      ];
}
