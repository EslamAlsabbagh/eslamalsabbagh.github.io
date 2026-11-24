import 'package:flutter/painting.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../data/task_list_item.dart';

/// The due label's color in task rows: overdue red, «اليوم» urgent orange,
/// otherwise soft text (the canvas's `dueColor`).
Color dueColorFor(AppTokens tokens, TaskListItem task) {
  if (task.isOverdue) return tokens.overdue;
  if (task.isOpen && task.daysUntilDue == 0) return tokens.urgentText;
  return tokens.textSoft;
}
