import '../core/domain/task_status.dart';
import 'gen/app_localizations.dart';

extension TaskStatusL10n on TaskStatus {
  String label(AppLocalizations l10n) => switch (this) {
        TaskStatus.todo => l10n.statusTodo,
        TaskStatus.doing => l10n.statusDoing,
        TaskStatus.waiting => l10n.statusWaiting,
        TaskStatus.done => l10n.statusDone,
        TaskStatus.cancelled => l10n.statusCancelled,
      };
}
