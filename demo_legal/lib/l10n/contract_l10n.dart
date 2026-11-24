import '../core/domain/contract_kind.dart';
import '../core/domain/contract_list_status.dart';
import '../core/domain/unit_kind.dart';
import '../core/format/arabic_count.dart';
import '../features/contracts/bloc/contract_filters.dart';
import '../features/contracts/export/register_document.dart';
import '../features/contracts/export/register_labels.dart';
import 'gen/app_localizations.dart';

extension ContractListStatusL10n on ContractListStatus {
  /// The list's status pill (DESIGN_SPEC §4 View 4 "List status pills").
  String label(AppLocalizations l10n) => switch (this) {
        ContractListStatus.active => l10n.contractListActive,
        ContractListStatus.ending => l10n.contractListEnding,
        ContractListStatus.expired => l10n.contractListExpired,
        ContractListStatus.terminated => l10n.contractListTerminated,
      };
}

extension ContractKindFilterL10n on ContractKindFilter {
  String label(AppLocalizations l10n) => switch (this) {
        ContractKindFilter.all => l10n.contractKindAll,
        ContractKindFilter.units => l10n.contractKindUnits,
        ContractKindFilter.storage => l10n.contractKindStorage,
        ContractKindFilter.servicesOther => l10n.contractKindServicesOther,
      };
}

extension ContractStatusFilterL10n on ContractStatusFilter {
  String label(AppLocalizations l10n) => switch (this) {
        ContractStatusFilter.all => l10n.contractStatusAll,
        ContractStatusFilter.inForce => l10n.contractStatusInForce,
        ContractStatusFilter.ending => l10n.contractStatusEnding,
        ContractStatusFilter.expired => l10n.contractStatusExpired,
      };
}

extension UnitKindL10n on UnitKind {
  String label(AppLocalizations l10n) => switch (this) {
        UnitKind.shop => l10n.unitKindShop,
        UnitKind.kiosk => l10n.unitKindKiosk,
        UnitKind.storage => l10n.unitKindStorage,
        UnitKind.space => l10n.unitKindSpace,
        UnitKind.site => l10n.unitKindSite,
      };
}

extension ContractKindFormL10n on ContractKind {
  /// The contract form's kind chips (DESIGN_SPEC §4 "Contract form"). An
  /// annex has its own form (Phase 7 step 5).
  String formLabel(AppLocalizations l10n) => switch (this) {
        ContractKind.lease => l10n.contractFormKindLease,
        ContractKind.storage => l10n.contractFormKindStorage,
        ContractKind.service => l10n.contractFormKindService,
        ContractKind.other || ContractKind.annex => l10n.contractFormKindOther,
      };

  /// The subject a new contract of this kind starts with; empty for
  /// services and others.
  String defaultSubject(AppLocalizations l10n) => switch (this) {
        ContractKind.lease => l10n.contractSubjectLease,
        ContractKind.storage => l10n.contractSubjectStorage,
        _ => '',
      };
}

/// A contract as a follow-up names it, in the new-task modal's fixed
/// «العقد» line and the task drawer's: its subject, or else its kind.
String contractName(AppLocalizations l10n, {required ContractKind kind, required String subject}) =>
    subject.isNotEmpty ? subject : kind.formLabel(l10n);

/// A duration in months: «٥ سنوات», «٤ أشهر», «سنتان و٣ أشهر». [format]
/// writes the counts (locale digits unless given).
String contractDuration(AppLocalizations l10n, int months, {String Function(int count)? format}) {
  final years = months ~/ 12;
  final rest = months % 12;
  String count(int n, String one, String two, String Function(String) few, String Function(String) many) =>
      format == null
          ? arabicCount(n, one: one, two: two, few: few, many: many)
          : arabicCount(n, one: one, two: two, few: few, many: many, format: format);
  String y() => count(years, l10n.durYearsOne, l10n.durYearsTwo, l10n.durYearsFew, l10n.durYearsMany);
  String m() => count(rest, l10n.durMonthsOne, l10n.durMonthsTwo, l10n.durMonthsFew, l10n.durMonthsMany);
  if (months <= 0) return l10n.contractValueNone;
  if (years == 0) return m();
  if (rest == 0) return y();
  return l10n.durJoin(y(), m());
}

/// The exported register's words (DESIGN_SPEC §4 View 4 "Export and
/// print"), with Western digits as in the firm's workbook.
RegisterLabels registerLabels(AppLocalizations l10n) => RegisterLabels(
      headers: [
        l10n.registerHeaderNumber,
        l10n.registerHeaderTenant,
        l10n.registerHeaderBrand,
        l10n.registerHeaderUnits,
        l10n.registerHeaderActivity,
        l10n.registerHeaderSubject,
        l10n.registerHeaderSignedOn,
        l10n.registerHeaderEndsOn,
        l10n.registerHeaderDuration,
        l10n.registerHeaderAreaInner,
        l10n.registerHeaderAreaOuter,
        l10n.registerHeaderDocuments,
        l10n.registerHeaderMissing,
        l10n.registerHeaderNotes,
        l10n.registerHeaderFollowUps,
      ],
      legend: RegisterLegend(
        title: l10n.registerLegendTitle,
        expired: l10n.registerLegendExpired,
        ending: l10n.registerLegendEnding,
        annex: l10n.registerLegendAnnex,
        storage: l10n.registerLegendStorage,
      ),
      bandTitle: (file, season) =>
          season == null ? l10n.registerBandTitleUndated(file) : l10n.registerBandTitle(file, '$season'),
      terminatedBandTitle: (file, season) => season == null
          ? l10n.registerTerminatedBandTitleUndated(file)
          : l10n.registerTerminatedBandTitle(file, '$season'),
      terminatedSheetName: l10n.registerTerminatedSheet,
      subject: (kind, subject) => contractName(l10n, kind: kind, subject: subject),
      annexSubject: (number, subject) => switch ((number, subject.isEmpty)) {
            (null, true) => l10n.registerAnnexUnnumbered,
            (null, false) => subject,
            (final n?, true) => l10n.registerAnnexOnly('$n'),
            (final n?, false) => l10n.registerAnnexSubject('$n', subject),
          },
      unitWithKey: l10n.registerUnitKey,
      duration: (months) => contractDuration(l10n, months, format: (n) => '$n'),
      needs: ({required signature, required stamp}) => signature && stamp
          ? l10n.registerNeedsBoth
          : (signature ? l10n.checklistSignature : l10n.checklistStamp),
      ourSide: l10n.checklistOurSide,
      terminatedNote: (date, reason) {
        final start = date == null ? l10n.registerTerminated : l10n.registerTerminatedOn(date);
        return reason.isEmpty ? start : '$start: $reason';
      },
    );
