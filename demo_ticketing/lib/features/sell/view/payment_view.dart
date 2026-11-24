import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/connectivity/server_status_cubit.dart';
import '../../../core/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../home/view/app_header.dart';
import '../../home/view/message_box.dart';
import '../../offline/view/offline_banner.dart';
import '../../shift/bloc/shift_cubit.dart';
import '../bloc/checkout_cubit.dart';
import '../bloc/sell_cubit.dart';
import '../data/sell_draft.dart';
import '../data/sell_repository.dart';
import '../data/sold_order.dart';
import 'sell_messages.dart';

/// Payment screen (`Payment.dc.html`): the order is created and its tickets
/// print, inactive, while the cashier collects (ADR-0007). Confirm activates
/// them; cancel voids them.
///
/// Differs from the design:
/// - the method can still be switched here (in the order panel), in case the
///   customer changes their mind after the tickets printed. Card and wallet
///   have no amount, keypad or tip (tips are cash only, ADR-0016);
/// - so that a 1366 × 768 screen needs no scrolling: cancel and confirm sit
///   in a bar fixed at the bottom, and the change is under the keypad;
/// - no back arrow, Admin or sign out: the order must be confirmed or
///   cancelled first;
/// - the tickets print while this screen shows: the status box shows the
///   progress, failures and a retry;
/// - the quick amounts are "exact" plus the `received_quick_amounts_piastres`
///   setting's amounts above the total, not a fixed 500 / 1,000 / 200;
/// - the cancel button asks first, with a reason;
/// - offline (2.8, ADR-0015; no design): charge first. The status box says
///   the tickets print after the confirm, and cancel is Back, since nothing
///   is stored before the confirm;
/// - the server out of reach on confirm (ADR-0039): once the health check
///   agrees, "Back to sell" leaves the order unconfirmed; the sell screen
///   starts from 0, as after a cancel, and the next order sells offline.
class PaymentView extends StatelessWidget {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final checkout = context.read<CheckoutCubit>();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f12): checkout.confirm,
        const SingleActivator(LogicalKeyboardKey.enter): checkout.confirm,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): checkout.confirm,
      },
      // A scope, not a plain Focus: on Windows a mouse click outside a text
      // field unfocuses it to the nearest scope. Here that is this one, under
      // the shortcuts, so Enter / F12 / Esc keep working.
      child: FocusScope(
        autofocus: true,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PaymentHeader(),
              const OfflineBanner(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const padding = EdgeInsets.symmetric(horizontal: 24, vertical: 20);
                    // The design's flex-wrap: side by side while both fit.
                    final wide = constraints.maxWidth - padding.horizontal >= 360 + 20 + 560;
                    return SingleChildScrollView(
                      padding: padding,
                      child: wide
                          ? const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: _SummaryPanel()),
                                SizedBox(width: 20),
                                Expanded(flex: 3, child: _CollectPanel()),
                              ],
                            )
                          : const Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [_SummaryPanel(), SizedBox(height: 20), _CollectPanel()],
                            ),
                    );
                  },
                ),
              ),
              const _ActionBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final method = context.select((CheckoutCubit cubit) => cubit.state.method);
    final shift = context.watch<ShiftCubit>().state;
    return AppHeader(
      title: l10n.paymentTitle(paymentMethodName(l10n, method)),
      subtitle: switch (shift) {
        ShiftOpen(:final shift) => l10n.shiftSubtitle(shift.counterName, shift.number),
        _ => '',
      },
      canLeave: false,
    );
  }
}

/// The design's white panel.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: child,
    );
  }
}

/// Print status, the order's lines, the payment method and the amount due.
class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final checkout = context.read<CheckoutCubit>();
    final order = context.select((CheckoutCubit cubit) => cubit.state.order);
    final method = context.select((CheckoutCubit cubit) => cubit.state.method);
    final submitting = context.select((CheckoutCubit cubit) => cubit.state.submitting);
    if (order == null) return const SizedBox.shrink();
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (order.offline) const _OfflinePrintNote() else const PrintStatusBox(),
          const SizedBox(height: 14),
          Text(
            order.offline ? l10n.orderSummaryOffline(order.number) : l10n.orderSummary(order.number),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          for (final line in order.lines) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.inset,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.soldLine(line.ticket.name(l10n.localeName), line.quantity),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    formatMoney(l10n, line.subtotalPiastres),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.paymentMethodLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (index, value) in PaymentMethod.values.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: _ChoiceButton(
                    label: paymentMethodName(l10n, value),
                    selected: method == value,
                    onPressed: submitting ? null : () => checkout.pickMethod(value),
                    height: 48,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l10n.amountDue(order.tickets.length),
                    style: TextStyle(fontSize: 16, color: tokens.textSecondary),
                  ),
                ),
                Text(
                  formatMoney(l10n, order.totalPiastres),
                  key: const ValueKey('amount-due'),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Offline (ADR-0015) nothing is printed before the confirm: charge first.
class _OfflinePrintNote extends StatelessWidget {
  const _OfflinePrintNote();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Container(
      key: const ValueKey('offline-print-note'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off, size: 20, color: tokens.warningText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.offlinePrintTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.warningText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l10n.offlinePrintHint, style: TextStyle(fontSize: 14, color: tokens.warningText)),
        ],
      ),
    );
  }
}

/// The tickets' print progress, with a retry for those that failed.
class PrintStatusBox extends StatelessWidget {
  const PrintStatusBox({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<CheckoutCubit>().state;
    final count = state.prints.length;
    final failed = state.failedCount;
    final (title, hint, background, border, foreground) = state.printing
        ? (l10n.printStatusPrinting, l10n.printStatusHint, tokens.inset, tokens.border, tokens.text)
        : failed > 0
        ? (
            l10n.printStatusFailed(failed),
            l10n.printStatusFailedHint,
            tokens.warningBg,
            tokens.warningBorder,
            tokens.warningText,
          )
        : (
            l10n.printStatusPrinted(count),
            l10n.printStatusHint,
            tokens.successBg,
            // The design's #A7D9B8 isn't a token: the dot colour, faded.
            tokens.successDot.withValues(alpha: 0.35),
            tokens.successText,
          );
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (state.printing)
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
                  )
                else
                  Icon(failed > 0 ? Icons.error_outline : Icons.check, size: 20, color: foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: foreground),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: ShapeDecoration(color: tokens.surface, shape: const StadiumBorder()),
                  child: Text(
                    l10n.printStatusCount(state.printedCount, count),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: foreground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(hint, style: TextStyle(fontSize: 14, color: foreground)),
            if (failed > 0 && !state.printing) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton(
                  onPressed: context.read<CheckoutCubit>().retryFailed,
                  child: Text(l10n.retry),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Amount received, tip and change; or the card or wallet note.
class _CollectPanel extends StatelessWidget {
  const _CollectPanel();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CheckoutCubit>().state;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.method == PaymentMethod.cash)
            const _CashSection()
          else
            _NonCashNote(method: state.method, totalPiastres: state.totalPiastres),
        ],
      ),
    );
  }
}

/// A failed call, cancel and confirm: always in view at the bottom, so the
/// cashier never scrolls to confirm.
class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final checkout = context.read<CheckoutCubit>();
    final state = context.watch<CheckoutCubit>().state;
    final failure = state.failure;
    // The order is gone on the server: only going back makes sense.
    final orderGone =
        failure == SellFailureKind.orderCancelled || failure == SellFailureKind.orderNotFound;
    // Offline nothing is stored before the confirm: Back instead of cancel.
    final offline = state.order?.offline ?? false;
    // The server didn't answer and the health check agrees it's gone: the
    // order can't be confirmed or cancelled, so the cashier may leave it and
    // sell again offline. The job cancels it later; its pending tickets never
    // open a gate (ADR-0039). Confirm stays, for when the server comes back.
    final serverGone = context.select((ServerStatusCubit cubit) => cubit.isOffline);
    final canLeave = failure == SellFailureKind.serverUnreachable && !offline && serverGone;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null) ...[
            MessageBox.danger(
              message: canLeave
                  ? l10n.paymentServerUnreachable
                  : sellFailureMessage(l10n, failure),
              onRetry: orderGone || canLeave ? checkout.abandon : null,
              actionLabel: orderGone || canLeave ? l10n.backToSell : null,
            ),
            const SizedBox(height: 10),
          ],
          // Both buttons as tall as the taller one.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 240,
                  // Two lines: at least the design's 64 px, taller if the font
                  // needs it.
                  child: OutlinedButton(
                    key: const ValueKey('payment-cancel'),
                    onPressed: state.submitting || orderGone
                        ? null
                        : offline
                        ? checkout.abandon
                        : () => _cancel(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 64),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      foregroundColor: offline ? tokens.text : tokens.dangerAction,
                      side: BorderSide(
                        color: offline ? tokens.inputBorder : tokens.dangerAction.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          offline ? l10n.back : l10n.cancelOrder,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          offline ? l10n.offlineBackHint : l10n.cancelOrderHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.canConfirm && !orderGone ? checkout.confirm : null,
                    icon: state.submitting
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.check, size: 22),
                    label: Text(l10n.confirmPayment),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.paymentShortcutsHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }

  static Future<void> _cancel(BuildContext context) async {
    final checkout = context.read<CheckoutCubit>();
    final number = checkout.state.order?.number;
    if (number == null) return;
    final choice = await showDialog<(CancelReason, String?)>(
      context: context,
      builder: (context) => _CancelDialog(orderNumber: number),
    );
    if (choice == null) return;
    await checkout.cancel(choice.$1, reasonText: choice.$2);
  }
}

/// Card or wallet: the exact total, nothing to type.
class _NonCashNote extends StatelessWidget {
  const _NonCashNote({required this.method, required this.totalPiastres});

  final PaymentMethod method;
  final int totalPiastres;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final amount = formatMoney(l10n, totalPiastres);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: tokens.primaryTint, borderRadius: BorderRadius.circular(12)),
      child: Text(
        method == PaymentMethod.card
            ? l10n.cardPaymentNote(amount)
            : l10n.walletPaymentNote(amount),
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: tokens.onPrimaryTint),
      ),
    );
  }
}

/// Amount received (typed or keypad), quick amounts, tip and change. The
/// fields hold text; the cubit gets the amounts.
class _CashSection extends StatefulWidget {
  const _CashSection();

  @override
  State<_CashSection> createState() => _CashSectionState();
}

class _CashSectionState extends State<_CashSection> {
  final _received = TextEditingController();
  final _tip = TextEditingController();

  /// Up to 999,999 EGP, with up to two decimals for piastres.
  static final _amount = RegExp(r'^\d{0,6}(\.\d{0,2})?$');
  static final _amountFormat = TextInputFormatter.withFunction(
    (previous, next) => _amount.hasMatch(next.text) ? next : previous,
  );

  @override
  void initState() {
    super.initState();
    final state = context.read<CheckoutCubit>().state;
    final received = state.receivedPiastres;
    if (received != null) _received.text = piastresText(received);
    if (state.tipKind == TipKind.typed) _tip.text = piastresText(state.tipAmountPiastres);
    _received.addListener(
      () => context.read<CheckoutCubit>().setReceived(parsePiastres(_received.text)),
    );
  }

  @override
  void dispose() {
    _received.dispose();
    _tip.dispose();
    super.dispose();
  }

  void _setReceived(String text) => _received.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );

  void _press(String key) {
    final text = _received.text;
    switch (key) {
      case 'C':
        _setReceived('');
      case '⌫':
        _setReceived(text.isEmpty ? '' : text.substring(0, text.length - 1));
      default:
        final next = text == '0' ? key : '$text$key';
        if (_amount.hasMatch(next)) _setReceived(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<CheckoutCubit>().state;
    final settings = context.select((SellCubit cubit) => cubit.state.settings);
    final quick = [
      for (final amount in settings?.receivedQuickAmountsPiastres ?? const <int>[])
        if (amount > state.totalPiastres) amount,
    ].take(3);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: tokens.primary, width: 2),
    );

    final amountColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.amountReceivedLabel,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textSecondary),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('amount-received'),
          controller: _received,
          autofocus: true,
          enabled: !state.submitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_amountFormat],
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            constraints: const BoxConstraints(minHeight: 72),
            contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 14),
            border: fieldBorder,
            enabledBorder: fieldBorder,
            focusedBorder: fieldBorder,
          ),
        ),
        const SizedBox(height: 16),
        _ButtonGrid(
          columns: 2,
          children: [
            _QuickButton(
              label: l10n.exactAmount,
              onPressed: () => _setReceived(piastresText(state.totalPiastres)),
            ),
            for (final amount in quick)
              _QuickButton(
                key: ValueKey('received-$amount'),
                label: formatMoney(l10n, amount),
                onPressed: () => _setReceived(piastresText(amount)),
              ),
          ],
        ),
        if (state.tipsEnabled) ...[
          const SizedBox(height: 16),
          _TipBox(controller: _tip, quickAmounts: settings?.tipQuickAmountsPiastres ?? const []),
        ],
      ],
    );

    // The change under the keypad, not under the tip as the design: the two
    // columns come out about as tall, so it fits a 768 px screen.
    final keypad = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          // Digits read left to right in both languages, as the design.
          textDirection: TextDirection.ltr,
          child: _ButtonGrid(
            columns: 3,
            gap: 10,
            children: [
              for (final key in ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'])
                _KeypadButton(
                  label: key,
                  semanticsLabel: switch (key) {
                    'C' => l10n.keypadClear,
                    '⌫' => l10n.keypadBackspace,
                    _ => key,
                  },
                  onPressed: state.submitting ? null : () => _press(key),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ChangeBox(state: state),
      ],
    );

    return BlocListener<CheckoutCubit, CheckoutState>(
      // A method switch or a quick tip drops the typed one.
      listenWhen: (previous, current) => current.tipKind != TipKind.typed,
      listener: (context, state) {
        if (_tip.text.isNotEmpty) _tip.clear();
      },
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 260 * 2 + 20
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: amountColumn),
                  const SizedBox(width: 20),
                  Expanded(child: keypad),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [amountColumn, const SizedBox(height: 20), keypad],
              ),
      ),
    );
  }
}

/// None, the quick tips, a typed one, and "left the change".
class _TipBox extends StatelessWidget {
  const _TipBox({required this.controller, required this.quickAmounts});

  final TextEditingController controller;
  final List<int> quickAmounts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final checkout = context.read<CheckoutCubit>();
    final state = context.watch<CheckoutCubit>().state;
    final enabled = !state.submitting;
    bool quickOn(int amount) => amount == 0
        ? state.tipKind == TipKind.none
        : state.tipKind == TipKind.quick && state.tipAmountPiastres == amount;
    final typedOn = state.tipKind == TipKind.typed;

    return CustomPaint(
      painter: _DashedRectPainter(color: tokens.inputBorder),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.tipTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _ButtonGrid(
              columns: 4,
              children: [
                for (final amount in [0, ...quickAmounts])
                  _ChoiceButton(
                    label: amount == 0 ? l10n.tipNone : formatMoney(l10n, amount),
                    selected: quickOn(amount),
                    onPressed: enabled ? () => checkout.pickTip(amount) : null,
                    height: 44,
                    tinted: true,
                  ),
                Semantics(
                  label: l10n.tipTypedLabel,
                  child: TextField(
                    key: const ValueKey('tip-typed'),
                    controller: controller,
                    enabled: enabled,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [_CashSectionState._amountFormat],
                    onChanged: (text) => checkout.typeTip(parsePiastres(text)),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: l10n.tipTypedHint,
                      isDense: true,
                      constraints: const BoxConstraints(minHeight: 44),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: typedOn ? tokens.primary : tokens.inputBorder,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: AppSizes.touchTarget,
              child: FilledButton.tonal(
                onPressed: enabled ? checkout.tipTheChange : null,
                style: FilledButton.styleFrom(
                  backgroundColor: state.tipKind == TipKind.change ? tokens.primaryTint : tokens.bg,
                  foregroundColor: state.tipKind == TipKind.change
                      ? tokens.onPrimaryTint
                      : tokens.text,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: Text(l10n.tipTheChange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green change, or red "amount short" by how much.
class _ChangeBox extends StatelessWidget {
  const _ChangeBox({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final change = state.changePiastres ?? -(state.totalPiastres + state.tipPiastres);
    final short = change < 0;
    final tip = state.tipPiastres;
    final label = short
        ? l10n.amountShort
        : tip > 0
        ? l10n.changeAfterTip(formatMoney(l10n, tip))
        : l10n.changeLabel;
    final foreground = short ? tokens.dangerText : tokens.successText;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: short ? tokens.dangerBg : tokens.successBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: foreground),
            ),
            const SizedBox(height: 4),
            Text(
              formatMoney(l10n, change.abs()),
              key: const ValueKey('change'),
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

/// Equal columns, rows as tall as their buttons.
class _ButtonGrid extends StatelessWidget {
  const _ButtonGrid({required this.columns, required this.children, this.gap = 8});

  final int columns;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var start = 0; start < children.length; start += columns) ...[
          if (start > 0) SizedBox(height: gap),
          Row(
            children: [
              for (var column = 0; column < columns; column++) ...[
                if (column > 0) SizedBox(width: gap),
                Expanded(
                  child: start + column < children.length
                      ? children[start + column]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: tokens.text,
        side: BorderSide(color: tokens.inputBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// A button of a mutually exclusive set (method, tip).
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.height,
    this.tinted = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final double height;

  /// Selected as the light tint (tips) rather than solid primary (method).
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (background, foreground) = !selected
        ? (tokens.surface, tokens.text)
        : tinted
        ? (tokens.primaryTint, tokens.onPrimaryTint)
        : (tokens.primary, tokens.surface);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, height),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: selected ? tokens.primary : tokens.inputBorder, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Text(label, maxLines: 1),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.label, required this.semanticsLabel, required this.onPressed});

  final String label;
  final String semanticsLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      label: semanticsLabel,
      button: true,
      excludeSemantics: true,
      child: OutlinedButton(
        key: ValueKey('key-$label'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 72),
          backgroundColor: tokens.inset,
          foregroundColor: tokens.text,
          side: BorderSide(color: tokens.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

/// The tip box's 1 px dashed, rounded border.
class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    final border = Path()
      ..addRRect(
        RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), const Radius.circular(12)),
      );
    for (final metric in border.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 8) {
        canvas.drawPath(metric.extractPath(start, start + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) => oldDelegate.color != color;
}

/// Why the order is cancelled: "customer didn't pay", or another reason in
/// words. Pops `(reason, text)`, or null to keep the order.
class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.orderNumber});

  final int orderNumber;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  var _reason = CancelReason.customerDidNotPay;
  final _text = TextEditingController();
  var _textMissing = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _text.text.trim();
    if (_reason == CancelReason.other && text.isEmpty) {
      return setState(() => _textMissing = true);
    }
    Navigator.of(context).pop((_reason, _reason == CancelReason.other ? text : null));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return AlertDialog(
      title: Text(l10n.cancelDialogTitle(widget.orderNumber)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.cancelDialogBody, style: TextStyle(color: tokens.textSecondary)),
            const SizedBox(height: 12),
            RadioGroup<CancelReason>(
              groupValue: _reason,
              onChanged: (reason) => setState(() => _reason = reason ?? _reason),
              child: Column(
                children: [
                  RadioListTile(
                    value: CancelReason.customerDidNotPay,
                    title: Text(l10n.cancelReasonNotPaid),
                  ),
                  RadioListTile(value: CancelReason.other, title: Text(l10n.cancelReasonOther)),
                ],
              ),
            ),
            if (_reason == CancelReason.other)
              TextField(
                key: const ValueKey('cancel-reason-text'),
                controller: _text,
                autofocus: true,
                maxLength: 200,
                onChanged: (_) {
                  if (_textMissing) setState(() => _textMissing = false);
                },
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.cancelReasonTextLabel,
                  errorText: _textMissing ? l10n.cancelReasonTextRequired : null,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelDialogKeep),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: tokens.dangerAction),
          child: Text(l10n.cancelOrder),
        ),
      ],
    );
  }
}
