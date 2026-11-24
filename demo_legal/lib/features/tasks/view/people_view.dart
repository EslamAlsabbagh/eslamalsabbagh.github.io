import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../bloc/tasks_bloc.dart';
import '../data/task_list_item.dart';
import 'task_drawer.dart';
import 'widgets/card_grid.dart';
import 'widgets/empty_section.dart';
import 'widgets/person_card.dart';

/// View 3, «الموظفون»: a grid of person cards with their open tasks, scoped
/// by the file chip. A row opens the task drawer.
class PeopleView extends StatelessWidget {
  const PeopleView({super.key, this.clock = DateTime.now});

  /// "Now" for the drawer's update times; injectable for tests.
  final DateTime Function() clock;

  /// The canvas's `minmax(min(340px, 100%), 1fr)` with a 14px gap.
  static const double _minCardWidth = 340;
  static const double _gap = 14;

  @override
  Widget build(BuildContext context) {
    final groups = context.select((TasksBloc bloc) => bloc.state.personGroups);
    final fileSelected = context.select((TasksBloc bloc) => bloc.state.selectedFileId != null);
    void open(TaskListItem task) => showTaskDrawer(context, task, clock: clock);

    if (groups.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return EmptySection(fileSelected ? l10n.peopleEmptyFile : l10n.peopleEmpty);
    }
    // Cards keep their own heights, top-aligned, as in the canvas.
    return CardGrid(
      minCardWidth: _minCardWidth,
      gap: _gap,
      stretch: false,
      children: [
        for (final summary in groups)
          PersonCard(key: Key('person-${summary.id}'), summary: summary, onOpen: open),
      ],
    );
  }
}
