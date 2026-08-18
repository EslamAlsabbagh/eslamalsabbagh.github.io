import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/my_requests_summary_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/my_requests_summary_state.dart';
import 'package:hrms_demo/presentation/user_requests/widgets/user_requests_page.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/user_overtime_requests_page.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/widgets/user_businesstrip_requests_page.dart';
import 'package:hrms_demo/presentation/user_missingpunch-requests/widgets/user_missingpunch_requests_page.dart';
import 'package:hrms_demo/presentation/user_advance_on_salary_requests/widgets/user_advance_on_salary_requests_page.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/widgets/user_disciplinary_action_requests_page.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/bloc/user_disciplinary_action_requests_event.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/widgets/user_hr_letter_requests_page.dart';
import 'package:hrms_demo/presentation/employee_schedule/employee_schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyInProcessRequestsWidget extends StatefulWidget {
  final bool embedded;

  const MyInProcessRequestsWidget({super.key, this.embedded = false});

  @override
  State<MyInProcessRequestsWidget> createState() => _MyInProcessRequestsWidgetState();
}

class _MyInProcessRequestsWidgetState extends State<MyInProcessRequestsWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isAtBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 5;
    if (_showScrollIndicator == isAtBottom) setState(() => _showScrollIndicator = !isAtBottom);
  }

  void _updateScrollIndicator() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final canScroll = _scrollController.position.maxScrollExtent > 0;
      final isAtBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 5;
      final shouldShow = canScroll && !isAtBottom;
      if (_showScrollIndicator != shouldShow) setState(() => _showScrollIndicator = shouldShow);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyRequestsSummaryBloc, MyRequestsSummaryState>(
      builder: (context, state) {
        if (state.status == Status.failure) {
          if (widget.embedded) return const SizedBox.shrink();
          return Container(
            height: 100,
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 32),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.requestsLoadFailed,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!state.summary.hasInProcessRequests) return const SizedBox.shrink();

        _updateScrollIndicator();

        final scrollableItems = _buildScrollableItems(context, state.summary);

        if (widget.embedded) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [scrollableItems, if (state.summary.activeInProcessTypesCount > 4) _buildScrollIndicator()],
            ),
          );
        }

        return Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.cyan[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.myInProcessRequests,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                scrollableItems,
                if (state.summary.activeInProcessTypesCount > 4) _buildScrollIndicator(),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.cyan[700]!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${AppLocalizations.of(context)!.total}: ${state.summary.totalInProcess}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan[700]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollableItems(BuildContext context, MyRequestsSummary summary) {
    final l = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 350),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: EdgeInsets.all(context.screenWidth > 600 ? 16 : 8),
            child: Column(
              children: [
                if (summary.inProcessLeaveRequests > 0)
                  _buildSummaryItem(
                    context,
                    icon: Icons.back_hand_outlined,
                    label: l.leaveRequests,
                    count: summary.inProcessLeaveRequests,
                    color: Colors.blue,
                    onTap: () => _navigate(context, 'leave'),
                  ),
                if (summary.inProcessBusinessTripRequests > 0)
                  _buildSummaryItem(
                    context,
                    icon: Icons.mode_of_travel_outlined,
                    label: l.businessTripRequests,
                    count: summary.inProcessBusinessTripRequests,
                    color: Colors.green,
                    onTap: () => _navigate(context, 'businessTrip'),
                  ),
                if (summary.inProcessMissingPunchRequests > 0)
                  _buildSummaryItem(
                    context,
                    icon: Icons.fingerprint,
                    label: l.missingPunchRequests,
                    count: summary.inProcessMissingPunchRequests,
                    color: Colors.purple,
                    onTap: () => _navigate(context, 'missingPunch'),
                  ),
                if (summary.inProcessAdvanceOnSalaryRequests > 0)
                  _buildSummaryItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: l.advanceOnSalaryRequests,
                    count: summary.inProcessAdvanceOnSalaryRequests,
                    color: Colors.teal,
                    onTap: () => _navigate(context, 'advanceOnSalary'),
                  ),
                if (summary.inProcessDisciplinaryActionRequests > 0)
                  _buildSummaryItem(
                    context,
                    icon: Icons.gavel_outlined,
                    label: l.disciplinaryActionRequests,
                    count: summary.inProcessDisciplinaryActionRequests,
                    color: Colors.red,
                    onTap: () => _navigate(context, 'disciplinaryAction'),
                  ),
                if (summary.inProcessHrLetterRequests > 0)
                  _buildSummaryItem(
                    context,
                    icon: Icons.article_outlined,
                    label: l.hrLetterRequests,
                    count: summary.inProcessHrLetterRequests,
                    color: Colors.indigo,
                    onTap: () => _navigate(context, 'hrLetter'),
                  ),
                if (summary.inProcessSwapRequests > 0)
                  _buildSummaryItem(
                    context,
                    icon: Icons.swap_horiz,
                    label: AppLocalizations.of(context)!.shiftSwapRequests,
                    count: summary.inProcessSwapRequests,
                    color: Colors.blue,
                    onTap: () => _navigate(context, 'swapRequests'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollIndicator() {
    if (!_showScrollIndicator) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: _showScrollIndicator ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 20),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String requestType) {
    if (requestType == 'swapRequests') {
      NavigationHelper.pushWithSidebarSync(
        context,
        routeName: '/schedule',
        page: const EmployeeSchedulePage(highlight: ScheduleHighlight.selfSwapRows),
      );
      return;
    }

    final Widget page;
    final String routeName;

    switch (requestType) {
      case 'leave':
        page = const UserRequestsPage();
        routeName = '/leave/my';
      case 'overtime':
        page = const UserOvertimeRequestsPage();
        routeName = '/overtime/my';
      case 'businessTrip':
        page = const UserBusinesstripRequestsPage();
        routeName = '/businesstrip/my';
      case 'missingPunch':
        page = const UserMissingpunchRequestsPage();
        routeName = '/missingpunch/my';
      case 'advanceOnSalary':
        page = const UserAdvanceOnSalaryRequestsPage();
        routeName = '/advance/my';
      case 'disciplinaryAction':
        page = const UserDisciplinaryActionRequestsPage(sourceType: RequestSourceType.myRequests);
        routeName = '/disciplinary/my';
      case 'hrLetter':
        page = const UserHrLetterRequestsPage();
        routeName = '/hr-letter/my';
      default:
        return;
    }

    NavigationHelper.pushWithSidebarSync(context, routeName: routeName, page: page);
  }
}
