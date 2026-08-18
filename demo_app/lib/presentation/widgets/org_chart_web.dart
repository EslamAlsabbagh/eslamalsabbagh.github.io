import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_bloc.dart';
import 'package:hrms_demo/presentation/employees/widgets/edit_employee_content.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:hrms_demo/presentation/widgets/org_chart_n1_edit_dialog.dart';
import 'package:hrms_demo/presentation/widgets/sidebar_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:indexed/indexed.dart';

class OrgChartWeb extends StatefulWidget {
  const OrgChartWeb({super.key});

  @override
  State<OrgChartWeb> createState() => _OrgChartWebState();
}

class _OrgChartWebState extends State<OrgChartWeb> {
  late final html.IFrameElement _iframe;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;
  late final String _viewType;
  static int _instanceCounter = 0;

  late final UsersRepo _usersRepo;
  StreamSubscription<html.MessageEvent>? _messageSub;

  /// Last hierarchy rendered to the iframe (`{id, pid, name, post}` maps).
  /// Kept so the N+1 edit dialog can resolve manager names and reject cycles.
  List<Map<String, dynamic>> _currentNodes = [];

  @override
  void initState() {
    super.initState();

    _usersRepo = context.read<UsersRepo>();

    // Listen for messages the iframe posts back (e.g. "edit this node's N+1").
    _messageSub = html.window.onMessage.listen(_onIframeMessage);

    // Create a view type that is unique per instance AND across hot restarts.
    // The timestamp matters: on web hot restart the static counter resets to 0
    // while a stale (deactivated) instance's window listener can survive, so a
    // counter-only id would collide and let the ghost handle our message and
    // throw a deactivated-ancestor error. The timestamp can never collide.
    _viewType = 'orgchart-frame-${DateTime.now().microsecondsSinceEpoch}-${_instanceCounter++}';

    _iframe =
        html.IFrameElement()
          ..src = './assets/assets/orgchart/index.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';

    // ✅ When the iframe finishes loading, send the Supabase data
    _iframe.onLoad.listen((event) {
      if (!_hasLoadedOnce) {
        _hasLoadedOnce = true;
        // Add slight delay to ensure iframe is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            loadOrgChart();
          }
        });
      }
    });

    // Register the iframe with Flutter Web using unique view type
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => _iframe);

    // Collapse sidebar when org chart page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final sidebarCubit = context.read<SidebarCubit>();
        sidebarCubit.collapse();
      }
    });
  }

  Future<void> loadOrgChart() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Production issued a direct `users` query here. The demo reads the same
      // rows through the repository the widget already holds, so the chart is
      // built from the seeded organisation with no network call.
      final users = await _usersRepo.getUsers();

      if (!mounted) return;

      final data = users
          .where((u) => u.userState != 'suspended')
          .map(
            (user) => {
              'id': user.id,
              'pid': user.n1, // parent ID for OrgChart
              'name': user.englishName,
              'post': user.englishTitle,
            },
          )
          .toList();

      // 🔍 Detect and fix loops in the hierarchy (run in isolate to prevent UI blocking)
      final validData = await compute(_removeLoopsIsolate, data);

      if (!mounted) return;

      // Remember the rendered hierarchy for the N+1 edit dialog (name lookup + cycle guard).
      _currentNodes = validData;

      final jsonData = jsonEncode(validData);

      // ✅ Send data to iframe's JS via postMessage.
      // `instanceId` lets the iframe echo our unique id back on editN1, so a
      // stale/inactive OrgChartWeb instance (whose global window listener also
      // fires) can ignore messages that aren't its own — see _onIframeMessage.
      final message = {'type': 'render', 'data': jsonData, 'instanceId': _viewType};

      _iframe.contentWindow?.postMessage(message, '*');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load org chart: ${e.toString()}';
      });
    }
  }

  /// Handles messages posted back from the iframe. Only acts on the JSON
  /// `{type:'editN1', ...}` payload; everything else (Flutter engine traffic,
  /// other frames) is ignored.
  void _onIframeMessage(html.MessageEvent event) {
    final raw = event.data;
    if (raw is! String) return;
    Map<String, dynamic>? decoded;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) decoded = parsed;
    } catch (_) {
      return; // not our message
    }
    if (decoded == null) return;
    final type = decoded['type'];
    if (type != 'editN1' && type != 'editNode' && type != 'editEmployee') return;
    // The window listener is global, so this fires for EVERY mounted OrgChartWeb
    // instance. Only the instance that owns the iframe which sent the message may
    // proceed; others bail here (a plain string compare, before any context
    // lookup) so a stale/inactive instance can't throw a deactivated-ancestor error.
    if (decoded['instanceId'] != _viewType) return;
    if (type == 'editN1') {
      _handleEditN1(decoded);
    } else if (type == 'editEmployee') {
      _handleEditEmployee(decoded);
    } else {
      _handleEditNode(decoded);
    }
  }

  /// True when the current user may edit the org chart (reassign managers or
  /// rename/re-title nodes). Restricted to HR / Top Management, matching the
  /// gate historically applied to the N+1 edit flow.
  bool _canEditOrgChart() {
    final me = context.read<UserBloc>().state.user;
    return me?.groups?.any((g) {
          final t = g.toLowerCase();
          return t == 'hr' || t == 'top management';
        }) ??
        false;
  }

  /// Opens the N+1 edit dialog for the clicked node, gated to HR / Top Management.
  Future<void> _handleEditN1(Map<String, dynamic> data) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final me = context.read<UserBloc>().state.user;
    if (!_canEditOrgChart()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noPermissionToChangeManager)));
      return;
    }

    final rawId = data['id'];
    final employeeId = rawId is int ? rawId : int.tryParse('$rawId');
    if (employeeId == null) return;
    final name = data['name']?.toString() ?? '';
    final rawN1 = data['currentN1'];
    final currentN1 = rawN1 is int ? rawN1 : int.tryParse('${rawN1 ?? ''}');

    // The chart is an iframe (a separate DOM browsing context) that keeps
    // `pointer-events: auto`, so without this it would swallow every click meant
    // for the dialog painted on top of it. Make it inert while the modal is open
    // and always restore it (finally) — this also gives correct modal semantics.
    _iframe.style.pointerEvents = 'none';
    bool? saved;
    try {
      saved = await showDialog<bool>(
        context: context,
        builder:
            (_) => OrgChartN1EditDialog(
              employeeId: employeeId,
              employeeName: name,
              currentN1: currentN1,
              nodes: _currentNodes,
              usersRepo: _usersRepo,
              actorCode: me?.id,
            ),
      );
    } finally {
      _iframe.style.pointerEvents = 'auto';
    }

    if (saved == true && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.managerUpdatedSuccessfully)));
      loadOrgChart(); // re-fetch + re-render so the node moves under its new manager
    }
  }

  /// Opens the full employee editor (the same page reached from the employees
  /// list) as a near-fullscreen dialog over the chart, gated to HR / Top
  /// Management like the other org-chart edits. The chart only holds a bare id,
  /// so we fetch the full [UserModel] the page needs before showing it.
  Future<void> _handleEditEmployee(Map<String, dynamic> data) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    if (!_canEditOrgChart()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noPermissionToEditEmployeeDetails)));
      return;
    }

    final rawId = data['id'];
    final employeeId = rawId is int ? rawId : int.tryParse('$rawId');
    if (employeeId == null) return;

    // Capture the bloc BEFORE the async gap + showDialog so we never read
    // `context` across an await, and can hand it to BlocProvider.value.
    final employeesBloc = context.read<EmployeesBloc>();

    UserModel employee;
    try {
      employee = await _usersRepo.getEmployeeById(employeeId);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.failedToUpdateEmployeeDetails)));
      return;
    }
    if (!mounted) return;

    final size = MediaQuery.of(context).size;

    // The chart is an iframe (a separate DOM browsing context) that keeps
    // `pointer-events: auto`; make it inert while the modal is open and always
    // restore it (finally) so clicks reach the dialog painted on top.
    _iframe.style.pointerEvents = 'none';
    try {
      await showDialog<void>(
        context: context,
        // Force an explicit close so the page's unsaved-changes guard runs.
        barrierDismissible: false,
        builder:
            (_) => BlocProvider.value(
              value: employeesBloc,
              child: Dialog(
                // Near-fullscreen so the page's window-based width math still fits.
                insetPadding: const EdgeInsets.all(24),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: EditEmployeePage(employee: employee, asDialog: true),
                ),
              ),
            ),
      );
    } finally {
      _iframe.style.pointerEvents = 'auto';
    }

    if (mounted) {
      loadOrgChart(); // a save may have changed the employee's name/title/N+1
    }
  }

  /// Persists an inline name/position edit made in the iframe side panel.
  /// Unlike N+1 (which opens a Flutter dialog), the editing UI lives entirely
  /// in the web panel; here we only validate, gate, and write the two English
  /// columns, then re-render so the node reflects the saved values.
  Future<void> _handleEditNode(Map<String, dynamic> data) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final me = context.read<UserBloc>().state.user;
    if (!_canEditOrgChart()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noPermissionToEditEmployeeDetails)));
      return;
    }

    final rawId = data['id'];
    final employeeId = rawId is int ? rawId : int.tryParse('$rawId');
    if (employeeId == null) return;

    final name = data['name']?.toString().trim() ?? '';
    final position = data['post']?.toString().trim() ?? '';
    // Reject blank values so the panel can't wipe a node's name/title.
    if (name.isEmpty || position.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.failedToUpdateEmployeeDetails)));
      return;
    }

    try {
      await _usersRepo.updateEmployeeNameTitle(
        employeeId,
        englishName: name,
        englishTitle: position,
        actorCode: me?.id,
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.employeeDetailsUpdatedSuccessfully)));
      loadOrgChart(); // re-fetch + re-render so the node shows the saved values
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.failedToUpdateEmployeeDetails)));
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  /// Top-level function for use with compute() isolate
  /// Detects and removes loops in the organizational hierarchy
  static List<Map<String, dynamic>> _removeLoopsIsolate(List<Map<String, dynamic>> users) {
    final userMap = <int, Map<String, dynamic>>{};

    // Build a map for quick lookup
    for (final user in users) {
      final id = user['id'] as int?;
      if (id != null) {
        userMap[id] = user;
      }
    }

    // Find nodes that are part of a cycle
    final inCycle = <int>{};

    for (final user in users) {
      final userId = user['id'] as int?;
      if (userId == null) continue;

      final visited = <int>{};
      final path = <int>[];
      int? currentId = userId;

      // Traverse up the hierarchy
      while (currentId != null) {
        if (visited.contains(currentId)) {
          // Found a cycle - mark all nodes in the cycle
          final cycleStart = path.indexOf(currentId);
          if (cycleStart >= 0) {
            final cycleNodes = path.sublist(cycleStart);
            inCycle.addAll(cycleNodes);
          }
          break;
        }

        visited.add(currentId);
        path.add(currentId);

        final currentUser = userMap[currentId];
        if (currentUser == null) break;

        currentId = currentUser['pid'] as int?;
      }
    }

    // Break cycles by removing parent of one node in each cycle
    // We'll pick the node with the highest ID to make it deterministic
    final result =
        users.map((user) {
          final userId = user['id'] as int?;
          final parentId = user['pid'] as int?;

          // If this user is in a cycle AND their parent is also in the cycle, break it
          if (userId != null && parentId != null && inCycle.contains(userId) && inCycle.contains(parentId)) {
            return {...user, 'pid': null};
          }
          return user;
        }).toList();

    return result;
  }

  @override
  Widget build(BuildContext context) {
    // While the sidebar is expanded (overlapping the chart), disable the iframe's
    // pointer capture so Flutter's own sidebar MouseRegion sees enter/exit and the
    // sidebar behaves exactly as on every other page. The chart is briefly inert
    // during that hover, and becomes interactive again the moment it collapses.
    return BlocListener<SidebarCubit, bool>(
      listener: (context, expanded) {
        _iframe.style.pointerEvents = expanded ? 'none' : 'auto';
      },
      child: Scaffold(
        body: MainLayout(
          title: AppLocalizations.of(context)!.orgChart,
          child: Indexer(
            children: [
              Indexed(index: 0, child: HtmlElementView(viewType: _viewType)),
              if (_isLoading)
                Indexed(
                  index: 1,
                  child: Container(
                    color: Colors.white.withOpacity(0.9),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading organization chart...', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_errorMessage != null)
                Indexed(
                  index: 2,
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(_errorMessage!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: loadOrgChart, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
