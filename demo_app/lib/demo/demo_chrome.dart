import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/demo/demo_seed.dart';
import 'package:hrms_demo/demo/demo_session.dart';
import 'package:hrms_demo/demo/demo_store.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';

/// The demo's own chrome: a persistent disclosure bar, a role switcher and a
/// reset control, overlaid on every screen.
///
/// The role switcher is the point of the whole demo. The product's most
/// interesting behaviour is its multi-level approval chain, and you cannot see
/// a chain from one seat — the same request has to be viewable as the employee
/// who raised it, the manager it is waiting on, and the HR user it escalates
/// to. Switching identity here re-drives `AuthGate` exactly as a real sign-in
/// would.
class DemoChrome extends StatelessWidget {
  const DemoChrome({super.key, required this.child});

  final Widget child;

  static const double _barHeight = 38;

  static const _roles = <_Role>[
    _Role('Employee', DemoSeed.employeeCode, 'Operations Coordinator'),
    _Role('Manager', DemoSeed.managerCode, 'Operations Manager'),
    _Role('HR', DemoSeed.hrCode, 'HR Manager'),
    _Role('Finance', DemoSeed.financeCode, 'Finance Manager'),
    _Role('Top management', DemoSeed.topManagementCode, 'Managing Director'),
  ];

  void _switchTo(BuildContext context, int code) {
    context.read<DemoSession>().switchTo(code);
    // AuthGate only auto-loads a profile from its `initial` state, so drive the
    // reload explicitly rather than relying on the gate's first-run path.
    context.read<UserBloc>().add(LoadUserProfile(code.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DemoSession>();
    final current = session.currentCode;

    final mq = MediaQuery.of(context);

    // Overlaid rather than stacked in a Column: the builder's child is the
    // Navigator, and wrapping it in an Expanded inside a Column left some
    // routes without the bounded constraints they expect ("RenderBox was not
    // laid out"). A Stack leaves the app's own layout untouched, and the extra
    // bottom inset is fed back through MediaQuery so nothing hides behind the
    // bar.
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(bottom: mq.padding.bottom + _barHeight),
        viewPadding: mq.viewPadding.copyWith(bottom: mq.viewPadding.bottom + _barHeight),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Material(
                color: const Color(0xFF12141A),
                child: SizedBox(
                  height: _barHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _Chip(),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            'All employees, requests and balances are fictional.',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Color(0xFF99A2B2), fontSize: 12),
                          ),
                        ),
                        if (current != null) ...[
                          const SizedBox(width: 16),
                          const Text('View as',
                              style: TextStyle(color: Color(0xFF99A2B2), fontSize: 12)),
                          const SizedBox(width: 6),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _roles.any((r) => r.code == current) ? current : null,
                              hint: const Text('Custom',
                                  style: TextStyle(color: Colors.white, fontSize: 12)),
                              dropdownColor: const Color(0xFF1B1F27),
                              isDense: true,
                              iconEnabledColor: const Color(0xFF58A6FF),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              items: [
                                for (final r in _roles)
                                  DropdownMenuItem<int>(
                                    value: r.code,
                                    child: Text('${r.label} · ${r.title}'),
                                  ),
                              ],
                              onChanged: (code) {
                                if (code != null) _switchTo(context, code);
                              },
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            DemoStore.instance.reset();
                            _switchTo(context, DemoSeed.defaultUserCode);
                          },
                          icon: const Icon(Icons.refresh, size: 15, color: Color(0xFF58A6FF)),
                          label: const Text('Reset data',
                              style: TextStyle(color: Color(0xFF58A6FF), fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF58A6FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'DEMO',
          style: TextStyle(
            color: Color(0xFF0F1116),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
          ),
        ),
      );
}

class _Role {
  const _Role(this.label, this.code, this.title);
  final String label;
  final int code;
  final String title;
}
