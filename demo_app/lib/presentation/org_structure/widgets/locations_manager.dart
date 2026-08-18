import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/data/models/org_structure/org_structure_models.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_bloc.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_event.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_state.dart';
import 'package:hrms_demo/presentation/org_structure/org_labels.dart';
import 'package:hrms_demo/presentation/org_structure/widgets/org_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Right pane, top section: manage the flat list of physical locations. Cards
/// wrap; each edits inline; a new card enters edit mode immediately.
class LocationsManager extends StatelessWidget {
  final OrgStructureState state;
  const LocationsManager({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = OrgStrings.of(context);
    final bloc = context.read<OrgStructureBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.locations,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.inkPrimary),
            ),
            const SizedBox(width: OrgGap.m),
            TextButton.icon(
              onPressed: () => bloc.add(const OrgLocationAdded()),
              icon: const Icon(Icons.add, size: 16),
              label: Text(s.addLocation),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: OrgGap.m),
        Wrap(
          spacing: OrgGap.m,
          runSpacing: OrgGap.m,
          children: [for (final loc in state.locations) _LocationCard(state: state, location: loc)],
        ),
      ],
    );
  }
}

class _LocationCard extends StatefulWidget {
  final OrgStructureState state;
  final Location location;
  const _LocationCard({required this.state, required this.location});

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = OrgStrings.of(context);
    final bloc = context.read<OrgStructureBloc>();
    final loc = widget.location;
    final editing = widget.state.editing?.kind == EditKind.location && widget.state.editing?.id == loc.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedOpacity(
        opacity: loc.isActive ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 230,
          padding: const EdgeInsets.all(OrgGap.m),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gridline),
            boxShadow: [
              BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child:
              editing
                  ? InlineEditRow(
                    fields: [
                      OrgEditField(s.englishName, loc.name),
                      OrgEditField(s.arabicName, loc.nameAr ?? '', rtl: true),
                      OrgEditField(s.code, loc.code, uppercase: true),
                    ],
                    onSave: (v) => bloc.add(OrgLocationEdited(loc.id, v[0], v[1], v[2])),
                    onCancel: () => bloc.add(const OrgEditCancelled()),
                  )
                  : _display(context, s, bloc, loc),
        ),
      ),
    );
  }

  Widget _display(BuildContext context, OrgStrings s, OrgStructureBloc bloc, Location loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.push_pin, size: 15, color: AppColors.cat2Aqua),
            const SizedBox(width: OrgGap.s),
            Expanded(
              child: GestureDetector(
                onTap: () => bloc.add(OrgEditStarted(OrgEditTarget(EditKind.location, loc.id))),
                child: Text(
                  widget.state.lang.label(loc.name, loc.nameAr),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkPrimary),
                ),
              ),
            ),
            if (_hover) ...[
              IconButton(
                onPressed: () => bloc.add(OrgLocationActiveToggled(loc.id)),
                icon: Icon(loc.isActive ? Icons.power_settings_new : Icons.power_off, size: 15),
                color: AppColors.inkSecondary,
                tooltip: loc.isActive ? s.deactivate : s.activate,
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                onPressed: () => bloc.add(OrgLocationDeleted(loc.id)),
                icon: const Icon(Icons.delete_outline, size: 15),
                color: AppColors.statusDeclined,
                tooltip: s.delete,
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        const SizedBox(height: OrgGap.s),
        OrgTag(loc.code),
      ],
    );
  }
}
