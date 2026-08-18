import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showFiltersSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: MT.bgPage,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => BlocProvider.value(value: context.read<ScheduleBloc>(), child: const FiltersSheet()),
  );
}

class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late String? _department;
  late String? _location;
  late TeamScope _teamScope;

  @override
  void initState() {
    super.initState();
    final f = context.read<ScheduleBloc>().state.filters;
    _department = f.department;
    _location = f.location;
    _teamScope = f.teamScope;
  }

  bool get _hasActiveFilters => _department != null || _location != null || _teamScope != TeamScope.direct;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      buildWhen: (prev, curr) => prev.allTeam != curr.allTeam,
      builder: (context, state) {
        // Collect unique departments and locations from the full team
        final departments =
            state.allTeam
                .map((u) => u.englishDepartment ?? u.department ?? '')
                .where((d) => d.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        final locations =
            state.allTeam.map((u) => u.location ?? '').where((l) => l.isNotEmpty).toSet().toList()..sort();

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder:
              (ctx, scrollCtrl) => Column(
                children: [
                  _header(l10n),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      children: [
                        _sectionLabel(l10n.mobileDepartment),
                        _chipGroup(
                          items: departments,
                          selected: _department,
                          onTap: (v) => setState(() => _department = _department == v ? null : v),
                        ),
                        const SizedBox(height: 16),
                        if (locations.isNotEmpty) ...[
                          _sectionLabel(l10n.mobileLocation),
                          _chipGroup(
                            items: locations,
                            selected: _location,
                            onTap: (v) => setState(() => _location = _location == v ? null : v),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _sectionLabel(l10n.mobileTeamScope),
                        _scopeSelector(l10n),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  _footer(context, l10n),
                ],
              ),
        );
      },
    );
  }

  Widget _header(AppLocalizations l10n) => Column(
    children: [
      const SizedBox(height: 10),
      Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(color: MT.hair, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: Row(
          children: [
            Text(
              l10n.mobileFiltersTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MT.text),
            ),
            const Spacer(),
            if (_hasActiveFilters)
              GestureDetector(
                onTap:
                    () => setState(() {
                      _department = null;
                      _location = null;
                      _teamScope = TeamScope.direct;
                    }),
                child: Text(
                  l10n.mobileFiltersReset,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MT.brand),
                ),
              ),
          ],
        ),
      ),
      Divider(height: 1, color: MT.hair2),
    ],
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MT.text3, letterSpacing: 0.5),
    ),
  );

  Widget _chipGroup({required List<String> items, required String? selected, required ValueChanged<String> onTap}) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            items.map((item) {
              final active = selected == item;
              return GestureDetector(
                onTap: () => onTap(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? MT.brandBg : MT.bgCard,
                    borderRadius: MT.br24,
                    border: Border.all(color: active ? MT.brand : MT.hair),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? MT.brand : MT.text2),
                  ),
                ),
              );
            }).toList(),
      );

  Widget _scopeSelector(AppLocalizations l10n) {
    final opts = [
      (scope: TeamScope.all, label: l10n.mobileTeamScopeAll),
      (scope: TeamScope.direct, label: l10n.mobileTeamScopeDirect),
      (scope: TeamScope.indirect, label: l10n.mobileTeamScopeIndirect),
    ];
    return Row(
      children:
          opts.map((opt) {
            final active = _teamScope == opt.scope;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _teamScope = opt.scope),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? MT.brandBg : MT.bgCard,
                    borderRadius: MT.br12,
                    border: Border.all(color: active ? MT.brand : MT.hair),
                  ),
                  child: Text(
                    opt.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? MT.brand : MT.text2),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _footer(BuildContext ctx, AppLocalizations l10n) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: MT.hair),
                shape: RoundedRectangleBorder(borderRadius: MT.br12),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel, style: const TextStyle(color: MT.text2, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: MT.brand,
                shape: RoundedRectangleBorder(borderRadius: MT.br12),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                ctx.read<ScheduleBloc>().add(
                  ChangeFilters(ScheduleFilters(department: _department, location: _location, teamScope: _teamScope)),
                );
                Navigator.of(ctx).pop();
              },
              child: Text(
                l10n.mobileFiltersApply,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
