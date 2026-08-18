import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/shift_swap_request_model.dart';
import 'package:hrms_demo/data/models/shift_template_model.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';

sealed class ScheduleEvent {
  const ScheduleEvent();
}

final class LoadSchedule extends ScheduleEvent {
  final int managerId;
  final DateTime weekStart;
  const LoadSchedule({required this.managerId, required this.weekStart});
}

final class ChangeWeek extends ScheduleEvent {
  final DateTime weekStart;
  const ChangeWeek(this.weekStart);
}

final class ChangeMonth extends ScheduleEvent {
  final DateTime month;
  const ChangeMonth(this.month);
}

final class ChangeView extends ScheduleEvent {
  final ScheduleView view;
  final int? dayIndex;
  const ChangeView(this.view, {this.dayIndex});
}

final class ChangeFilters extends ScheduleEvent {
  final ScheduleFilters filters;
  const ChangeFilters(this.filters);
}

final class ChangeViewMode extends ScheduleEvent {
  final ScheduleViewMode mode;
  const ChangeViewMode(this.mode);
}

final class SaveShift extends ScheduleEvent {
  final List<String> keys;
  final ScheduleModel payload;
  final ShiftTemplateModel? template;
  const SaveShift({required this.keys, required this.payload, this.template});
}

final class DeleteShift extends ScheduleEvent {
  final List<String> keys;
  const DeleteShift(this.keys);
}

final class PublishWeek extends ScheduleEvent {
  const PublishWeek();
}

final class CopyLastWeek extends ScheduleEvent {
  const CopyLastWeek();
}

final class ApproveSwap extends ScheduleEvent {
  final int id;
  const ApproveSwap(this.id);
}

final class DeclineSwap extends ScheduleEvent {
  final int id;
  const DeclineSwap(this.id);
}

final class DeleteTemplate extends ScheduleEvent {
  final int templateId;
  const DeleteTemplate(this.templateId);
}

final class SubmitSwapRequest extends ScheduleEvent {
  final ShiftSwapRequestModel request;
  const SubmitSwapRequest(this.request);
}

final class AcceptSwapAsTarget extends ScheduleEvent {
  final int id;
  const AcceptSwapAsTarget(this.id);
}

final class DeclineSwapAsTarget extends ScheduleEvent {
  final int id;
  const DeclineSwapAsTarget(this.id);
}

final class CancelSwapRequest extends ScheduleEvent {
  final int id;
  const CancelSwapRequest(this.id);
}

/// Assign one shift template to multiple employees across multiple days.
/// [dayIndices] are 0-based offsets from [ScheduleState.weekStart].
/// [employeeIds] are the team member IDs to assign to.
final class BulkAssignShifts extends ScheduleEvent {
  final double customStart;
  final double customEnd;
  final List<int> dayIndices;
  final List<int> employeeIds;
  final ShiftTemplateModel? template;
  final String? note;

  const BulkAssignShifts({
    required this.customStart,
    required this.customEnd,
    required this.dayIndices,
    required this.employeeIds,
    this.template,
    this.note,
  });
}
