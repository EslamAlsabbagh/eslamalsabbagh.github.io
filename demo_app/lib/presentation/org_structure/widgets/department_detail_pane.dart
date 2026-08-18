import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/data/models/org_structure/org_structure_models.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_bloc.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_event.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_state.dart';
import 'package:hrms_demo/presentation/org_structure/org_labels.dart';
import 'package:hrms_demo/presentation/org_structure/org_selectors.dart';
import 'package:hrms_demo/presentation/org_structure/widgets/org_common.dart';
import 'package:hrms_demo/presentation/org_structure/widgets/position_chart_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Right pane, lower section: everything about the selected department — its
/// breadcrumb, which locations it exists at (toggle chips = links), and one
/// position chart per link.
class DepartmentDetailPane extends StatelessWidget {
  final OrgStructureState state;
  const DepartmentDetailPane({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = OrgStrings.of(context);
    final id = state.selectedDeptId;

    if (id == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: OrgGap.xl * 2),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree_outlined, size: 40, color: AppColors.inkMuted.withValues(alpha: 0.5)),
              const SizedBox(height: OrgGap.m),
              Text(s.selectDeptPrompt, style: const TextStyle(fontSize: 14, color: AppColors.inkMuted)),
            ],
          ),
        ),
      );
    }

    Department? dept;
    for (final d in state.departments) {
      if (d.id == id) {
        dept = d;
        break;
      }
    }
    if (dept == null) return const SizedBox.shrink();

    final chain = OrgSelectors.ancestryChain(state.departments, id);
    final links = OrgSelectors.linksForDept(state.links, id).where((l) => l.isActive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading + code
        Row(
          children: [
            Flexible(
              child: Text(
                state.lang.label(dept.name, dept.nameAr),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.inkPrimary),
              ),
            ),
            if (dept.code != null) ...[const SizedBox(width: OrgGap.s), OrgTag(dept.code!)],
          ],
        ),
        const SizedBox(height: OrgGap.xs),
        // Breadcrumb
        Text(
          chain.length <= 1 ? s.topLevelDepartment : chain.map((d) => state.lang.label(d.name, d.nameAr)).join('  ›  '),
          style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
        ),
        const SizedBox(height: OrgGap.l),

        // Present-at chips
        Text(
          s.presentAt,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.inkSecondary),
        ),
        const SizedBox(height: OrgGap.s),
        Wrap(
          spacing: OrgGap.s,
          runSpacing: OrgGap.s,
          children: [for (final loc in state.locations) _LocationChip(state: state, deptId: id, location: loc)],
        ),
        const SizedBox(height: OrgGap.l),

        // Position charts (one per active link)
        for (final link in links)
          Builder(
            builder: (context) {
              Location? loc;
              for (final l in state.locations) {
                if (l.id == link.locationId) {
                  loc = l;
                  break;
                }
              }
              if (loc == null) return const SizedBox.shrink();
              return PositionChartCard(state: state, link: link, location: loc);
            },
          ),
      ],
    );
  }
}

/// A toggle chip per location: filled when a link exists between the selected
/// department and that location, outlined otherwise. Tapping connects/disconnects.
class _LocationChip extends StatelessWidget {
  final OrgStructureState state;
  final int deptId;
  final Location location;
  const _LocationChip({required this.state, required this.deptId, required this.location});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrgStructureBloc>();
    final link = OrgSelectors.linkFor(state.links, deptId, location.id);
    final on = link != null;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (on) {
          bloc.add(OrgLocationDisconnected(link.id));
        } else {
          bloc.add(OrgLocationConnected(deptId, location.id));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: OrgGap.m, vertical: OrgGap.s),
        decoration: BoxDecoration(
          color: on ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? AppColors.primary : AppColors.baseline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              on ? Icons.push_pin : Icons.push_pin_outlined,
              size: 13,
              color: on ? Colors.white : AppColors.inkMuted,
            ),
            const SizedBox(width: OrgGap.xs),
            Text(
              state.lang.label(location.name, location.nameAr),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                color: on ? Colors.white : AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
