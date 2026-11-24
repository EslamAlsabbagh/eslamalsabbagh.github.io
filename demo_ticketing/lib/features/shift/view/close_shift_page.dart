import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/clock.dart';
import '../../../core/money.dart';
import '../../../core/printer/print_service.dart';
import '../../../core/printer/printer_status.dart';
import '../../../core/printer/printer_target.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../home/view/app_header.dart';
import '../../home/view/dashed_border.dart';
import '../../home/view/message_box.dart';
import '../../offline/bloc/offline_sync_cubit.dart';
import '../../offline/view/offline_banner.dart';
import '../../sell/data/sell_repository.dart';
import '../bloc/close_shift_cubit.dart';
import '../bloc/shift_cubit.dart';
import '../data/close_shift.dart';
import '../data/shift_repository.dart';

/// Close shift (`CloseShift.dc.html`): the blind count by denomination, the
/// shift's tips and a forgotten one, then `close_shift` and the printed
/// receipt (`ShiftReceipt.dc.html`). No expected cash anywhere (ADR-0008).
///
/// Pushed over selling (`/sell/close`), so Back or Esc returns with the
/// order in progress kept. Once closed, the screen shows the receipt's print
/// and "Done", which signs out: the receipt can't be printed again later.
///
/// Differs from the design:
/// - the denominations come from `settings` (default 200 to 1 EGP), and the
///   counts start at 0;
/// - no tip amount is picked at first, and the box says a tip can't be
///   removed; it's hidden when tips are off;
/// - the close button sits in a bar fixed at the bottom, as on payment, so
///   it stays in view at 1366 × 768;
/// - an order still awaiting payment shows a warning and disables closing;
///   so do offline orders not uploaded yet (2.8, ADR-0015), with "Upload
///   now";
/// - closing asks first, and the screen then shows the receipt's print
///   status, Retry, and Done (sign out).
class CloseShiftPage extends StatelessWidget {
  const CloseShiftPage({super.key, required this.printer});

  /// This counter's printer, from the sell screen; null when none is set.
  final PrinterTarget? printer;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final sync = context.read<OfflineSyncCubit>();
        // Upload what's queued now rather than at the next health check.
        unawaited(sync.sync());
        return CloseShiftCubit(
          repository: context.read<ShiftRepository>(),
          sellRepository: context.read<SellRepository>(),
          printer: context.read<PrintService>(),
          shift: context.read<ShiftCubit>(),
          target: printer,
          clock: context.read<Clock>(),
        )
          ..setQueue(sync.state.queue)
          ..load();
      },
      // The queue empties while the screen shows: closing waits for it.
      child: BlocListener<OfflineSyncCubit, OfflineSyncState>(
        listenWhen: (previous, current) => previous.queue != current.queue,
        listener: (context, state) => context.read<CloseShiftCubit>().setQueue(state.queue),
        child: const _CloseView(),
      ),
    );
  }
}

class _CloseView extends StatelessWidget {
  const _CloseView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CloseShiftCubit>().state;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (context.read<CloseShiftCubit>().state.stage == CloseStage.counting) context.pop();
        },
      },
      // A scope, not a plain Focus: a mouse click outside a field unfocuses it
      // to this scope, under the shortcuts, so Esc keeps working.
      child: FocusScope(
        autofocus: true,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CloseHeader(state: state),
              if (state.stage == CloseStage.closed)
                const Expanded(child: _ClosedView())
              else ...[
                Expanded(child: _countingBody(context, state)),
                if (!state.loading && state.loadFailure == null) _ActionBar(state: state),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _countingBody(BuildContext context, CloseShiftState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<CloseShiftCubit>();
    const padding = EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Align(alignment: Alignment.topCenter, child: CircularProgressIndicator()),
      );
    }
    if (state.loadFailure case final kind?) {
      return SingleChildScrollView(
        padding: padding,
        child: MessageBox.danger(message: _failureText(l10n, kind), onRetry: cubit.load),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // The design's flex-wrap: side by side while both fit.
        final wide =
            constraints.maxWidth - padding.horizontal >= _countMinWidth + _gap + _tipsWidth;
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.blockedByAwaiting) ...[
                MessageBox.warning(
                  message: '${l10n.closeAwaitingTitle(state.awaitingPayment!)}. '
                      '${l10n.closeAwaitingBody(state.settings?.unpaidOrderTimeoutMin ?? 0)}',
                  onRetry: state.checkingAwaiting ? null : cubit.checkAwaiting,
                  actionLabel: l10n.closeCheckAgain,
                ),
                const SizedBox(height: _gap),
              ],
              if (state.blockedByQueue) ...[
                const _QueueWarning(),
                const SizedBox(height: _gap),
              ],
              if (wide)
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _CountSection()),
                    SizedBox(width: _gap),
                    SizedBox(width: _tipsWidth, child: _TipsPanel()),
                  ],
                )
              else
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CountSection(),
                    SizedBox(height: _gap),
                    _TipsPanel(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Offline orders not uploaded yet block the close (ADR-0015). They upload
/// by themselves; "Upload now" doesn't wait for the next check. Refused ones
/// need a supervisor: the action then lists them.
class _QueueWarning extends StatelessWidget {
  const _QueueWarning();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sync = context.watch<OfflineSyncCubit>();
    final queue = sync.state.queue;
    final refusedOnly = !queue.hasPending && queue.hasRefused;
    final title = queue.unsyncedOrders > 0
        ? l10n.closeQueueTitle(queue.unsyncedOrders)
        : l10n.closeQueueActionsTitle(queue.pendingActions + queue.refusedActions.length);
    return MessageBox.warning(
      key: const ValueKey('close-queue-warning'),
      message: '$title. ${queue.hasRefused ? l10n.closeQueueRefusedBody : l10n.closeQueueBody}',
      onRetry: refusedOnly
          ? () => showRefusedOrders(context, queue)
          : sync.state.uploading
          ? null
          : sync.sync,
      actionLabel: refusedOnly ? l10n.offlineRefusedTitle : l10n.uploadNow,
    );
  }
}

const _countMinWidth = 560.0;
const _tipsWidth = 380.0;
const _gap = 20.0;

String _failureText(AppLocalizations l10n, ShiftFailureKind kind) => switch (kind) {
      ShiftFailureKind.noOpenShift => l10n.closeFailureNoOpenShift,
      ShiftFailureKind.offlineRefusalsOpen => l10n.closeQueueRefusedBody,
      ShiftFailureKind.invalidCashCount => l10n.closeFailureInvalidCount,
      ShiftFailureKind.invalidTip => l10n.tipFailureInvalid,
      ShiftFailureKind.tipsDisabled => l10n.tipsDisabledNote,
      ShiftFailureKind.serverUnreachable => l10n.errorServerUnreachable,
      _ => l10n.errorUnexpected,
    };

/// "Close shift #24", "شباك 1 · from 09:00 to 17:04 · cashier". Back, sign
/// out and Admin only while counting: once closed, the receipt prints from
/// here or nowhere.
class _CloseHeader extends StatelessWidget {
  const _CloseHeader({required this.state});

  final CloseShiftState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shift = context.watch<ShiftCubit>().state;
    final auth = context.watch<AuthCubit>().state;
    final time = DateFormat.Hm(locale);
    final counting = state.stage == CloseStage.counting;
    final receipt = state.receipt;

    final (number, subtitle) = switch (shift) {
      ShiftOpen(:final shift) => (
          receipt?.shiftNumber ?? shift.number,
          l10n.closeShiftSubtitle(
            receipt?.counterName ?? shift.counterName,
            time.format(receipt?.openedAt ?? shift.openedAt),
            time.format(receipt?.closedAt ?? state.now),
            switch (auth) {
              AuthSignedIn(:final staff) => staff.fullName,
              _ => '',
            },
          ),
        ),
      _ => (receipt?.shiftNumber ?? 0, ''),
    };

    return AppHeader(
      title: l10n.closeShiftTitle(number),
      subtitle: subtitle,
      canLeave: counting,
      onBack: counting ? () => context.pop() : null,
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

/// The blind count: one row per denomination, and the counted total.
class _CountSection extends StatelessWidget {
  const _CountSection();

  static const _rowGap = 10.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final denominations =
        context.select((CloseShiftCubit cubit) => cubit.state.settings?.denominationsPiastres) ??
            const [];
    final counted = context.select((CloseShiftCubit cubit) => cubit.state.countedPiastres);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.countHeading,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(l10n.countHint, style: TextStyle(fontSize: 14, color: tokens.textSecondary)),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // Two columns, as the design, while a row still fits.
              final columns = constraints.maxWidth >= 640 ? 2 : 1;
              final width = (constraints.maxWidth - _rowGap * (columns - 1)) / columns;
              return Wrap(
                spacing: _rowGap,
                runSpacing: _rowGap,
                children: [
                  for (final denomination in denominations)
                    SizedBox(
                      width: width,
                      child: _DenominationRow(denomination: denomination),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: tokens.primaryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l10n.countedTotal,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: tokens.onPrimaryTint,
                    ),
                  ),
                ),
                Text(
                  formatMoney(l10n, counted),
                  key: const ValueKey('counted-total'),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: tokens.onPrimaryTint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "200 ج", − / count / +, and the subtotal. The count can be typed.
class _DenominationRow extends StatefulWidget {
  const _DenominationRow({required this.denomination});

  final int denomination;

  @override
  State<_DenominationRow> createState() => _DenominationRowState();
}

class _DenominationRowState extends State<_DenominationRow> {
  final _controller = TextEditingController(text: '0');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Selected on focus, so typing replaces the count instead of adding
    // digits to it.
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// + and − change the count in the cubit; the field follows. An empty
  /// field is 0 and stays empty while the cashier types.
  void _sync(int count) {
    if ((int.tryParse(_controller.text) ?? 0) == count) return;
    _controller.value = TextEditingValue(
      text: '$count',
      selection: TextSelection.collapsed(offset: '$count'.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<CloseShiftCubit>();
    final d = widget.denomination;
    final count = context.select((CloseShiftCubit cubit) => cubit.state.countOf(d));
    final enabled = context.select(
      (CloseShiftCubit cubit) => cubit.state.stage == CloseStage.counting,
    );
    _sync(count);
    // "200", or "0.50" for a coin with piastres.
    final amount = piastresText(d);
    const buttonSize = Size.square(AppSizes.touchTarget);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    const buttonText = TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: tokens.inputBorder),
    );

    return Container(
      key: ValueKey('denomination-$d'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: tokens.inset, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Text(
              l10n.denominationLabel(amount),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            // + on the right in both languages, as the design (RTL) and the
            // sell screen's steppers.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    label: l10n.decreaseQuantity,
                    button: true,
                    excludeSemantics: true,
                    child: OutlinedButton(
                      key: ValueKey('decrease-$d'),
                      onPressed: enabled && count > 0 ? () => cubit.decrement(d) : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: buttonSize,
                        maximumSize: buttonSize,
                        padding: EdgeInsets.zero,
                        shape: shape,
                        foregroundColor: tokens.text,
                        backgroundColor: tokens.surface,
                        side: BorderSide(color: tokens.inputBorder),
                        textStyle: buttonText,
                      ),
                      child: const Text('−'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: Semantics(
                      label: l10n.denominationCountLabel(amount),
                      child: TextField(
                        key: ValueKey('count-$d'),
                        controller: _controller,
                        focusNode: _focus,
                        enabled: enabled,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter('${CloseShiftCubit.maxCount}'.length),
                        ],
                        onChanged: (text) => cubit.setCount(d, int.tryParse(text) ?? 0),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: tokens.surface,
                          constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          border: fieldBorder,
                          enabledBorder: fieldBorder,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: l10n.increaseQuantity,
                    button: true,
                    excludeSemantics: true,
                    child: FilledButton(
                      key: ValueKey('increase-$d'),
                      onPressed: enabled ? () => cubit.increment(d) : null,
                      style: FilledButton.styleFrom(
                        minimumSize: buttonSize,
                        maximumSize: buttonSize,
                        padding: EdgeInsets.zero,
                        shape: shape,
                        textStyle: buttonText,
                      ),
                      child: const Text('+'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Text(
              formatMoney(l10n, d * count),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 15, color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The shift's tips, a forgotten one, and their total.
class _TipsPanel extends StatelessWidget {
  const _TipsPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<CloseShiftCubit>().state;
    final tips = state.tips;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.tipsHeading, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(l10n.tipsHint, style: TextStyle(fontSize: 14, color: tokens.textSecondary)),
          const SizedBox(height: 14),
          if (tips.isEmpty)
            Text(l10n.tipsNone, style: TextStyle(fontSize: 14, color: tokens.textSecondary))
          else
            for (final (index, tip) in tips.indexed) ...[
              if (index > 0) const SizedBox(height: 8),
              _TipRow(tip: tip),
            ],
          const SizedBox(height: 14),
          if (state.tipsEnabled)
            const _AddTipBox()
          else
            Text(
              l10n.tipsDisabledNote,
              style: TextStyle(fontSize: 14, color: tokens.textSecondary),
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l10n.tipsTotal(tips.length),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  formatMoney(l10n, state.tipsTotalPiastres),
                  key: const ValueKey('tips-total'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.tip});

  final ShiftTip tip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final orderNumber = tip.orderNumber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: tokens.inset, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderNumber == null ? l10n.tipAddedAtClose : l10n.tipWithOrder(orderNumber),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat.Hm(locale).format(tip.createdAt),
                  style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatMoney(l10n, tip.amountPiastres),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// "Add a forgotten tip": a quick amount or a typed one, then `add_tip`.
class _AddTipBox extends StatefulWidget {
  const _AddTipBox();

  @override
  State<_AddTipBox> createState() => _AddTipBoxState();
}

class _AddTipBoxState extends State<_AddTipBox> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<CloseShiftCubit>();
    final state = context.watch<CloseShiftCubit>().state;
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    final amount = state.tipPiastres;
    final quick = state.settings?.tipQuickAmountsPiastres ?? const [];
    final enabled = state.stage == CloseStage.counting && !state.addingTip;
    final tipFailure = state.tipFailure;
    final typedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: state.tipTyped ? tokens.primary : tokens.inputBorder, width: 2),
    );

    return BlocListener<CloseShiftCubit, CloseShiftState>(
      // A quick pick or an added tip empties the typed amount.
      listenWhen: (previous, current) => previous.tipTyped && !current.tipTyped,
      listener: (context, state) => _typed.clear(),
      child: CustomPaint(
        painter: DashedBorderPainter(color: tokens.inputBorder, strokeWidth: 1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.addTipHeading,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final width = (constraints.maxWidth - gap * 2) / 3;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final piastres in quick)
                        SizedBox(
                          width: width,
                          child: _QuickTipButton(
                            label: piastres % 100 == 0
                                ? numbers.format(piastres ~/ 100)
                                : piastresText(piastres),
                            selected: !state.tipTyped && amount == piastres,
                            onPressed: enabled ? () => cubit.pickTip(piastres) : null,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.addTipTypedLabel,
                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
              ),
              const SizedBox(height: 4),
              TextField(
                key: const ValueKey('tip-typed'),
                controller: _typed,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  LengthLimitingTextInputFormatter(8),
                ],
                onChanged: cubit.typeTip,
                onSubmitted: (_) => cubit.addTip(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.addTipTypedHint,
                  constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: typedBorder,
                  enabledBorder: typedBorder,
                  focusedBorder: typedBorder,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  key: const ValueKey('add-tip'),
                  onPressed: state.canAddTip ? cubit.addTip : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.text,
                    foregroundColor: tokens.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: state.addingTip
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          amount == null || amount <= 0
                              ? l10n.addTipButtonEmpty
                              : l10n.addTipButton(formatMoney(l10n, amount)),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.addTipNote,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
              ),
              if (tipFailure != null && tipFailure != ShiftFailureKind.tipsDisabled) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _failureText(l10n, tipFailure),
                    style: TextStyle(fontSize: 13, color: tokens.dangerText),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTipButton extends StatelessWidget {
  const _QuickTipButton({required this.label, required this.selected, required this.onPressed});

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          backgroundColor: selected ? tokens.primaryTint : tokens.surface,
          foregroundColor: selected ? tokens.onPrimaryTint : tokens.text,
          side: BorderSide(color: selected ? tokens.primary : tokens.inputBorder, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

/// A failed close and the close button: always in view at the bottom.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state});

  final CloseShiftState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final failure = state.closeFailure;
    final closing = state.stage == CloseStage.closing;

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
            // Closed meanwhile, or the close's answer was lost: nothing is
            // left to do here but leave.
            failure == ShiftFailureKind.noOpenShift
                ? MessageBox.warning(
                    message: _failureText(l10n, failure),
                    onRetry: () => context.read<AuthCubit>().signOut(),
                    actionLabel: l10n.closedDone,
                  )
                : MessageBox.danger(message: _failureText(l10n, failure)),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: 60,
            child: FilledButton.icon(
              key: const ValueKey('close-shift'),
              onPressed: state.canClose ? () => _confirm(context) : null,
              icon: closing
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.lock_outline, size: 22),
              label: Text(l10n.closeShiftButton),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.closeShiftNote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Closing can't be undone: say what was counted, and warn on nothing.
  static Future<void> _confirm(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<CloseShiftCubit>();
    final shift = context.read<ShiftCubit>().state;
    final counted = cubit.state.countedPiastres;
    final tokens = context.tokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.closeConfirmTitle(shift is ShiftOpen ? shift.shift.number : 0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.closeConfirmBody(formatMoney(l10n, counted))),
            if (counted == 0) ...[
              const SizedBox(height: 12),
              Text(
                l10n.closeConfirmZero,
                style: TextStyle(color: tokens.warningText, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelDialogKeep),
          ),
          FilledButton(
            key: const ValueKey('confirm-close'),
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.closeConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.closeShift();
  }
}

/// After `close_shift`: the receipt's print, Retry, and Done (sign out).
class _ClosedView extends StatelessWidget {
  const _ClosedView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<CloseShiftCubit>();
    final state = context.watch<CloseShiftCubit>().state;
    final print = state.receiptPrint;
    final printing = print == PrinterStatus.printing;

    final status = switch (print) {
      PrinterStatus.printed => _StatusLine(
          icon: Icons.check_circle_outline,
          text: l10n.receiptPrinted,
          background: tokens.successBg,
          foreground: tokens.successText,
        ),
      PrinterStatus.printFailed => MessageBox.danger(
          message: l10n.receiptPrintFailed,
          onRetry: cubit.printReceipt,
        ),
      PrinterStatus.notSet => MessageBox.warning(message: l10n.receiptNoPrinter),
      _ => _StatusLine(
          icon: Icons.print_outlined,
          text: l10n.receiptPrinting,
          background: tokens.inset,
          foreground: tokens.textSecondary,
          busy: true,
        ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_outline, size: 40, color: tokens.successDot),
                const SizedBox(height: 12),
                Text(
                  l10n.closedTitle(state.receipt?.shiftNumber ?? 0),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                status,
                if (print == PrinterStatus.printFailed || printing) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.receiptOnlyHere,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 60,
                  child: FilledButton(
                    key: const ValueKey('closed-done'),
                    onPressed: printing ? null : () => _done(context),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    child: Text(l10n.closedDone),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Signs out. A receipt that failed to print can't be printed later, so
  /// that asks first.
  static Future<void> _done(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthCubit>();
    if (context.read<CloseShiftCubit>().state.receiptPrint == PrinterStatus.printFailed) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.closedLeaveTitle),
          content: Text(l10n.closedLeaveBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelDialogKeep),
            ),
            FilledButton(
              key: const ValueKey('closed-leave'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.closedLeave),
            ),
          ],
        ),
      );
      if (!(leave ?? false)) return;
    }
    await auth.signOut();
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
    this.busy = false,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            if (busy)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(icon, size: 22, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: 15, color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}
