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
/// to. Switching identity here re-drives `AuthGate` exactly as a sign-in would.
///
/// The roles are laid out as inline buttons rather than a dropdown on purpose.
/// This widget is mounted from `MaterialApp.builder`, where the `child` *is*
/// the Navigator — so the bar is the Navigator's sibling and has no `Navigator`
/// or `Overlay` above it. A `DropdownButton` there silently does nothing when
/// tapped, because it has no route to push its menu into. Inline buttons need
/// neither, and they make the available roles visible without a click.
class DemoChrome extends StatelessWidget {
  const DemoChrome({super.key, required this.child});

  final Widget child;

  static const double _barHeight = 40;

  static const _roles = <_Role>[
    _Role('Employee', DemoSeed.employeeCode),
    _Role('Manager', DemoSeed.managerCode),
    _Role('HR', DemoSeed.hrCode),
    _Role('Finance', DemoSeed.financeCode),
    _Role('Top mgmt', DemoSeed.topManagementCode),
  ];

  void _switchTo(BuildContext context, int code) {
    context.read<DemoSession>().switchTo(code);
    // AuthGate only auto-loads a profile from its `initial` state, so drive the
    // reload explicitly rather than relying on the gate's first-run path.
    context.read<UserBloc>().add(LoadUserProfile(code.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // `context.watch` would not help here: DemoSession is supplied through a
    // plain RepositoryProvider, which never notifies. The bar re-renders off
    // the session's own change stream instead — the same signal AuthGate uses.
    final session = context.read<DemoSession>();
    final wide = mq.size.width >= 900;

    // Overlaid rather than stacked in a Column: the builder's child is the
    // Navigator, and wrapping it in an Expanded left some routes without the
    // bounded constraints they expect. A Stack leaves the app's own layout
    // untouched, and the extra inset is fed back through MediaQuery so nothing
    // hides behind the bar.
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(bottom: mq.padding.bottom + _barHeight),
        viewPadding: mq.viewPadding.copyWith(
          bottom: mq.viewPadding.bottom + _barHeight,
        ),
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
                  child: StreamBuilder<void>(
                    stream: session.changes,
                    builder: (context, _) {
                      final current = session.currentCode;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const _Chip(),
                            const SizedBox(width: 10),
                            if (wide) ...[
                              const Text(
                                'All employees, requests and balances are fictional.',
                                style: TextStyle(
                                  color: Color(0xFF99A2B2),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 18),
                            ],
                            if (current != null) ...[
                              const Text(
                                'View as',
                                style: TextStyle(
                                  color: Color(0xFF99A2B2),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              for (final r in _roles) ...[
                                _RoleButton(
                                  label: r.label,
                                  selected: r.code == current,
                                  onTap: () => _switchTo(context, r.code),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ],
                            const SizedBox(width: 10),
                            TextButton.icon(
                              onPressed: () {
                                DemoStore.instance.reset();
                                _switchTo(context, DemoSeed.defaultUserCode);
                              },
                              icon: const Icon(
                                Icons.refresh,
                                size: 15,
                                color: Color(0xFF58A6FF),
                              ),
                              label: const Text(
                                'Reset data',
                                style: TextStyle(
                                  color: Color(0xFF58A6FF),
                                  fontSize: 12,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF58A6FF) : Colors.transparent,
          border: Border.all(
            color: selected ? const Color(0xFF58A6FF) : const Color(0xFF39404E),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF0F1116) : const Color(0xFFD5DAE3),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
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
  const _Role(this.label, this.code);
  final String label;
  final int code;
}
