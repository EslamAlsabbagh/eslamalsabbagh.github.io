part of 'contract_form_bloc.dart';

sealed class ContractFormEvent extends Equatable {
  const ContractFormEvent();

  @override
  List<Object?> get props => [];
}

/// A kind chip; creating only (the kind is written once).
final class ContractFormKindChanged extends ContractFormEvent {
  const ContractFormKindChanged(this.kind);

  final ContractKind kind;

  @override
  List<Object?> get props => [kind];
}

/// «الملف»; creating only. The brand, units and linked lease belong to a
/// file, so they are cleared.
final class ContractFormFileChanged extends ContractFormEvent {
  const ContractFormFileChanged(this.fileId);

  final String fileId;

  @override
  List<Object?> get props => [fileId];
}

final class ContractFormTopicPicked extends ContractFormEvent {
  const ContractFormTopicPicked(this.topic);

  final TaskTopic? topic;

  @override
  List<Object?> get props => [topic];
}

/// A brand made from the field («+ إضافة»): joins the list and is picked.
final class ContractFormTopicAdded extends ContractFormEvent {
  const ContractFormTopicAdded(this.topic);

  final TaskTopic topic;

  @override
  List<Object?> get props => [topic];
}

final class ContractFormPartyPicked extends ContractFormEvent {
  const ContractFormPartyPicked(this.party);

  final PartyRef? party;

  @override
  List<Object?> get props => [party];
}

final class ContractFormUnitsChanged extends ContractFormEvent {
  const ContractFormUnitsChanged(this.units);

  final List<UnitRef> units;

  @override
  List<Object?> get props => [units];
}

/// «مرتبط بعقد»: a lease fills in the brand and the tenant.
final class ContractFormLeasePicked extends ContractFormEvent {
  const ContractFormLeasePicked(this.lease);

  final LeaseRef? lease;

  @override
  List<Object?> get props => [lease];
}

/// The form's text fields.
enum ContractTextField { subject, activity, dateNote, areaInner, areaOuter, areaNote, notes }

final class ContractFormTextChanged extends ContractFormEvent {
  const ContractFormTextChanged(this.field, this.text);

  final ContractTextField field;
  final String text;

  @override
  List<Object?> get props => [field, text];
}

enum ContractDateField { signed, starts, ends }

final class ContractFormDateChanged extends ContractFormEvent {
  const ContractFormDateChanged(this.field, this.date);

  final ContractDateField field;
  final DateTime? date;

  @override
  List<Object?> get props => [field, date];
}

/// «لا يوجد تاريخ نهاية محدد» and back.
final class ContractFormEndAsTextToggled extends ContractFormEvent {
  const ContractFormEndAsTextToggled();
}

/// «المساحة لا تُكتب كرقم» and back.
final class ContractFormAreaAsTextToggled extends ContractFormEvent {
  const ContractFormAreaAsTextToggled();
}

final class ContractFormSubmitted extends ContractFormEvent {
  const ContractFormSubmitted();
}
