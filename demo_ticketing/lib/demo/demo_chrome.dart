import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/printer/ticket_view.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/bloc/auth_cubit.dart';
import 'backend.dart';
import 'printer_tray.dart';

enum _Panel { none, printer, scanner }

/// The demo's own bar along the bottom, and the two things a browser can't
/// have: the counter's thermal printer and a turnstile's QR reader.
///
/// - **View as** signs in as the cashier, the supervisor or the admin, through
///   the app's own sign-in, so the role redirects run as they do live.
/// - **Server outage** makes every server call fail. The counter notices
///   within seconds, switches to offline selling (charge first, then print,
///   from its reserved code pool) and uploads the queue when it's back.
/// - **Printer** shows what was printed; **Jam** makes printing fail so the
///   retry and "leave unprinted" paths can be seen.
/// - **Gate scanner** holds a code to an entry gate: `validate_ticket` online,
///   the gate's own controller during an outage.
///
/// Mounted from the router's `builder`, above the Navigator, so it brings its
/// own [Overlay] for the panels' text field.
class DemoChrome extends StatefulWidget {
  const DemoChrome({super.key, required this.child});

  final Widget child;

  @override
  State<DemoChrome> createState() => _DemoChromeState();
}

class _DemoChromeState extends State<DemoChrome> {
  _Panel _panel = _Panel.none;
  final _backend = DemoBackend.instance;

  static const _muted = Color(0xFF99A2B2);
  static const _accent = Color(0xFF58A6FF);
  static const _warn = Color(0xFFF2B84B);

  void _toggle(_Panel panel) => setState(() {
        _panel = _panel == panel ? _Panel.none : panel;
        if (_panel == _Panel.printer) PrinterTray.instance.markSeen();
      });

  Future<void> _signInAs(String username) async {
    final auth = context.read<AuthCubit>();
    final current = auth.state;
    if (current is AuthSignedIn && current.staff.username == username) return;
    if (_backend.outage.value) _backend.outage.value = false;
    await auth.signOut();
    await auth.signIn(username, DemoBackend.password);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Stack(
                  children: [
                    Positioned.fill(child: widget.child),
                    if (_panel != _Panel.none)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        top: 8,
                        width: 380,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: _panel == _Panel.printer
                              ? _PrinterPanel(onClose: () => _toggle(_Panel.printer))
                              : _ScannerPanel(onClose: () => _toggle(_Panel.scanner)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: const Color(0xFF12141A),
            child: SizedBox(
              height: 44,
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, auth) {
                  final username = auth is AuthSignedIn ? auth.staff.username : null;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const _Chip(),
                        const SizedBox(width: 10),
                        if (wide) ...[
                          const Text('Fictional venue. Nothing leaves your browser.',
                              style: TextStyle(color: _muted, fontSize: 12)),
                          const SizedBox(width: 16),
                        ],
                        const Text('View as', style: TextStyle(color: _muted, fontSize: 12)),
                        const SizedBox(width: 8),
                        for (final (label, user) in demoAccounts) ...[
                          _Pill(label: label, selected: username == user, onTap: () => _signInAs(user)),
                          const SizedBox(width: 6),
                        ],
                        const _Divider(),
                        ValueListenableBuilder<bool>(
                          valueListenable: _backend.outage,
                          builder: (context, down, _) => _Pill(
                            label: down ? 'Server outage: ON' : 'Server outage',
                            icon: Icons.cloud_off,
                            selected: down,
                            selectedColor: _warn,
                            onTap: () => _backend.outage.value = !down,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ValueListenableBuilder<bool>(
                          valueListenable: _backend.printerJammed,
                          builder: (context, jammed, _) => _Pill(
                            label: jammed ? 'Printer jammed' : 'Jam printer',
                            icon: Icons.print_disabled,
                            selected: jammed,
                            selectedColor: _warn,
                            onTap: () => _backend.printerJammed.value = !jammed,
                          ),
                        ),
                        const _Divider(),
                        ListenableBuilder(
                          listenable: PrinterTray.instance,
                          builder: (context, _) => _Pill(
                            label: PrinterTray.instance.unseen == 0
                                ? 'Printer tray'
                                : 'Printer tray (${PrinterTray.instance.unseen})',
                            icon: Icons.receipt_long,
                            selected: _panel == _Panel.printer,
                            onTap: () => _toggle(_Panel.printer),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _Pill(
                          label: 'Gate scanner',
                          icon: Icons.qr_code_scanner,
                          selected: _panel == _Panel.scanner,
                          onTap: () => _toggle(_Panel.scanner),
                        ),
                        const SizedBox(width: 10),
                        TextButton.icon(
                          onPressed: () async {
                            final auth = context.read<AuthCubit>();
                            await auth.signOut();
                            _backend.reset();
                            PrinterTray.instance.clear();
                          },
                          icon: const Icon(Icons.refresh, size: 15, color: _accent),
                          label: const Text('Reset', style: TextStyle(color: _accent, fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        if (username == null) ...[
                          const SizedBox(width: 8),
                          const Text('Sign in: mona / rania / tarek · password ${DemoBackend.password}',
                              style: TextStyle(color: _muted, fontSize: 12)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Panels ────────────────────────────────────────────────────────────────────

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({required this.title, required this.subtitle, required this.onClose, required this.child});

  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 12,
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(color: Color(0xFF99A2B2), fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Color(0xFF99A2B2), size: 20)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2B3038)),
            Expanded(child: child),
          ],
        ),
      );
}

class _PrinterPanel extends StatelessWidget {
  const _PrinterPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => _PanelFrame(
        title: 'Printer tray',
        subtitle: 'What the 80 mm thermal printer printed, newest first.',
        onClose: onClose,
        child: ListenableBuilder(
          listenable: PrinterTray.instance,
          builder: (context, _) {
            final pages = PrinterTray.instance.pages;
            if (pages.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nothing printed yet. Open a shift (it prints a test page) or sell a ticket.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF99A2B2)),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, i) => Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  // As production lays a page out for the printer: 80 mm
                  // wide, as tall as it needs (core/printer/widget_image.dart).
                  child: SizedBox(
                    width: TicketView.width,
                    child: DefaultTextStyle(
                      style: const TextStyle(fontFamily: AppSizes.fontFamily, color: Colors.black, fontSize: 14),
                      child: pages[i].$1,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _ScannerPanel extends StatefulWidget {
  const _ScannerPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_ScannerPanel> createState() => _ScannerPanelState();
}

class _ScannerPanelState extends State<_ScannerPanel> {
  final _backend = DemoBackend.instance;
  final _code = TextEditingController();
  String? _gateId;
  ScanOutcome? _last;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _scan() {
    final gate = _gateId ?? _backend.entryGates.first.$1;
    if (_code.text.trim().isEmpty) return;
    setState(() => _last = _backend.scan(_code.text, gate));
  }

  @override
  Widget build(BuildContext context) {
    final gates = _backend.entryGates;
    final gateId = _gateId ?? gates.first.$1;
    return _PanelFrame(
      title: 'Gate scanner',
      subtitle: 'Hold a ticket\'s QR to an entry gate.',
      onClose: widget.onClose,
      child: ValueListenableBuilder<int>(
        valueListenable: _backend.revision,
        builder: (context, _, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Gate', style: TextStyle(color: Color(0xFF99A2B2), fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (id, name) in gates)
                  _Pill(label: name, selected: id == gateId, onTap: () => setState(() => _gateId = id)),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _code,
              onSubmitted: (_) => _scan(),
              style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'Gate code (6 digits)',
                hintStyle: const TextStyle(color: Color(0xFF6F7887), letterSpacing: 0, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF12141A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  onPressed: _scan,
                  icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF58A6FF)),
                  tooltip: 'Scan',
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_last case final last?)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: last.accepted ? const Color(0xFF123524) : const Color(0xFF3A1616),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(last.accepted ? Icons.check_circle : Icons.block,
                        color: last.accepted ? const Color(0xFF3FD29B) : const Color(0xFFFF7B72)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        [last.message, ?last.typeName].join('\n'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text('Recent tickets', style: TextStyle(color: Color(0xFF99A2B2), fontSize: 12)),
            const SizedBox(height: 6),
            for (final (code, label) in _backend.recentCodes())
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(code, style: const TextStyle(color: Colors.white, letterSpacing: 1.5)),
                subtitle: Text(label, style: const TextStyle(color: Color(0xFF99A2B2))),
                trailing: const Icon(Icons.north_west, size: 16, color: Color(0xFF58A6FF)),
                onTap: () => setState(() => _code.text = code),
              ),
            const SizedBox(height: 8),
            const Text(
              'Online, the gate asks the server (validate_ticket). During an outage each gate\'s controller '
              'knows only the tickets and pool codes of its own counters, so a ticket opens only its home gate.',
              style: TextStyle(color: Color(0xFF6F7887), fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bits ──────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap, this.icon, this.selectedColor});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final on = selectedColor ?? const Color(0xFF58A6FF);
    final fg = selected ? const Color(0xFF0F1116) : const Color(0xFFD5DAE3);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? on : Colors.transparent,
          border: Border.all(color: selected ? on : const Color(0xFF39404E)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 5)],
            Text(label,
                style: TextStyle(color: fg, fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 10), color: const Color(0xFF2B3038));
}

class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFF58A6FF), borderRadius: BorderRadius.circular(999)),
        child: const Text('DEMO',
            style: TextStyle(color: Color(0xFF0F1116), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .5)),
      );
}
