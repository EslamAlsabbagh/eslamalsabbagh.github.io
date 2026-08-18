import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/data/repos/org_structure/org_structure_repo.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_bloc.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_event.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_state.dart';
import 'package:hrms_demo/presentation/org_structure/org_labels.dart';
import 'package:hrms_demo/presentation/org_structure/widgets/department_detail_pane.dart';
import 'package:hrms_demo/presentation/org_structure/widgets/department_tree_pane.dart';
import 'package:hrms_demo/presentation/org_structure/widgets/locations_manager.dart';
import 'package:hrms_demo/presentation/org_structure/widgets/org_common.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Entry point for the Org Structure Builder. Provides the Bloc (Supabase-backed
/// repo), kicks off the initial load, and lays out the header + two-pane body
/// inside the app's MainLayout.
class OrgStructurePage extends StatelessWidget {
  const OrgStructurePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrgStructureBloc(context.read<OrgStructureRepo>())..add(const OrgLoaded()),
      child: const _OrgStructureView(),
    );
  }
}

class _OrgStructureView extends StatelessWidget {
  const _OrgStructureView();

  @override
  Widget build(BuildContext context) {
    final s = OrgStrings.of(context);
    return MainLayout(
      title: s.title,
      child: BlocBuilder<OrgStructureBloc, OrgStructureState>(
        builder: (context, state) {
          if (state.status == Status.loading && state.departments.isEmpty && state.locations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(OrgGap.l, OrgGap.l, OrgGap.l, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(state: state),
                const SizedBox(height: OrgGap.m),
                if (state.warning != null)
                  OrgWarningBanner(
                    message: s.warning(state.warning!),
                    onDismiss: () => context.read<OrgStructureBloc>().add(const OrgWarningCleared()),
                  ),
                const Divider(height: 1, color: AppColors.gridline),
                Expanded(child: _Body(state: state)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final OrgStructureState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = OrgStrings.of(context);
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        runSpacing: OrgGap.m,
        children: [
          // Brand + stat pills grouped, with a wide gap between the title and the count chips
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(OrgGap.s),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.account_tree, color: Colors.white, size: 20),
              ),
              const SizedBox(width: OrgGap.m),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.inkPrimary),
                  ),
                  Text(s.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                ],
              ),
              const SizedBox(width: OrgGap.xl),
              // Stat pills
              _StatPill(label: s.statLocations, count: state.locations.length, color: AppColors.cat2Aqua),
              _StatPill(label: s.statDepartments, count: state.departments.length, color: AppColors.cat1Blue),
              _StatPill(label: s.statLinks, count: state.links.length, color: AppColors.cat5Violet),
              _StatPill(label: s.statPositions, count: state.positions.length, color: AppColors.cat8Orange),
            ],
          ),
          // Language segmented control (pushed to the end by Wrap spaceBetween)
          SegmentedButton<OrgLang>(
            segments: const [
              ButtonSegment(value: OrgLang.en, label: Text('EN')),
              ButtonSegment(value: OrgLang.ar, label: Text('عربي')),
              ButtonSegment(value: OrgLang.bilingual, label: Text('EN / ع')),
            ],
            selected: {state.lang},
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
            ),
            onSelectionChanged: (set) => context.read<OrgStructureBloc>().add(OrgLangChanged(set.first)),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatPill({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: OrgGap.s),
      padding: const EdgeInsets.symmetric(horizontal: OrgGap.m, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: OrgGap.xs),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkSecondary)),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final OrgStructureState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: department tree (fixed width, own scroll)
        SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: OrgGap.m, horizontal: OrgGap.l),
            child: DepartmentTreePane(state: state),
          ),
        ),
        const VerticalDivider(width: 1, color: AppColors.gridline),
        // Right: locations + selected-department detail (own scroll)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(OrgGap.xl, OrgGap.m, OrgGap.s, OrgGap.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocationsManager(state: state),
                const SizedBox(height: OrgGap.xl),
                const Divider(height: 1, color: AppColors.gridline),
                const SizedBox(height: OrgGap.xl),
                DepartmentDetailPane(state: state),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
