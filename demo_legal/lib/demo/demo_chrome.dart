import 'package:flutter/material.dart';

import 'demo_seed.dart';
import 'demo_store.dart';

/// The demo's own bar along the bottom: a disclosure, the role switcher, the
/// language toggle and a reset.
///
/// The role switcher is what makes the demo worth opening. The product's
/// rules differ by role (a lawyer sees only their own files and edits only
/// their own tasks; a manager assigns work; an admin manages accounts), and a
/// task created as the manager rings the lawyer's bell after a switch.
///
/// Mounted from `MaterialApp.builder`, so it is the Navigator's sibling and has
/// no Overlay above it: everything here is an inline button, never a menu.
class DemoChrome extends StatelessWidget {
  const DemoChrome({super.key, required this.child});

  final Widget child;

  static const double _barHeight = 40;
  static const _muted = Color(0xFF99A2B2);
  static const _accent = Color(0xFF58A6FF);

  @override
  Widget build(BuildContext context) {
    final store = DemoStore.instance;
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    // A Column, not an overlay: the app keeps its full layout above the bar
    // and nothing it draws can end up underneath it.
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: child),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              color: const Color(0xFF12141A),
              child: SizedBox(
                height: _barHeight,
                child: StreamBuilder<Object?>(
                  stream: store.authChanges,
                  builder: (context, _) {
                    final current = store.currentUser;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const _Chip(),
                          const SizedBox(width: 10),
                          if (wide) ...[
                            const Text(
                              'Fictional firm, people and contracts. Nothing leaves your browser.',
                              style: TextStyle(color: _muted, fontSize: 12),
                            ),
                            const SizedBox(width: 18),
                          ],
                          const Text('View as', style: TextStyle(color: _muted, fontSize: 12)),
                          const SizedBox(width: 8),
                          for (final (label, id) in DemoSeed.roleAccounts) ...[
                            _PillButton(
                              label: '$label · ${store.profile(id)?.displayName.split(' ').first ?? ''}',
                              selected: current?.id == id,
                              onTap: () => store.signInAs(id),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (current == null) ...[
                            const SizedBox(width: 6),
                            const Text(
                              'or sign in with any account · password ${DemoStore.password}',
                              style: TextStyle(color: _muted, fontSize: 12),
                            ),
                          ],
                          const SizedBox(width: 14),
                          ValueListenableBuilder<Locale>(
                            valueListenable: store.locale,
                            builder: (context, locale, _) => Row(
                              children: [
                                _PillButton(
                                  label: 'EN',
                                  selected: locale.languageCode == 'en',
                                  onTap: () => store.setLocale(const Locale('en')),
                                ),
                                const SizedBox(width: 4),
                                _PillButton(
                                  label: 'عربي',
                                  selected: locale.languageCode == 'ar',
                                  onTap: () => store.setLocale(const Locale('ar')),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton.icon(
                            onPressed: store.reset,
                            icon: const Icon(Icons.refresh, size: 15, color: _accent),
                            label: const Text('Reset data', style: TextStyle(color: _accent, fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
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
        ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.selected, required this.onTap});

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
          border: Border.all(color: selected ? const Color(0xFF58A6FF) : const Color(0xFF39404E)),
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
        decoration: BoxDecoration(color: const Color(0xFF58A6FF), borderRadius: BorderRadius.circular(999)),
        child: const Text(
          'DEMO',
          style: TextStyle(color: Color(0xFF0F1116), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .5),
        ),
      );
}
