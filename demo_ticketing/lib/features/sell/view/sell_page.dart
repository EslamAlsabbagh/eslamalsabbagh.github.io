import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../app/router.dart';
import '../../../core/clock.dart';
import '../../../core/config/app_config.dart';
import '../../../core/connectivity/server_status_cubit.dart';
import '../../../core/money.dart';
import '../../../core/printer/print_service.dart';
import '../../../core/printer/printer_status.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../home/view/app_header.dart';
import '../../home/view/dashed_border.dart';
import '../../home/view/message_box.dart';
import '../../offline/bloc/offline_sync_cubit.dart';
import '../../offline/data/offline_store.dart';
import '../../offline/view/offline_banner.dart';
import '../../shift/bloc/shift_cubit.dart';
import '../../shift/data/shift_repository.dart';
import '../../tickets/bloc/ticket_action_cubit.dart';
import '../bloc/checkout_cubit.dart';
import '../bloc/sell_cubit.dart';
import '../data/sell_draft.dart';
import '../data/sell_repository.dart';
import '../data/ticket_type.dart';
import 'payment_view.dart';
import 'review_view.dart';
import 'sell_messages.dart';

/// Sell screen (`Main.dc.html`, `SellEnglish.dc.html`): ticket type cards,
/// the current order and its payment method, and the shift's counts. No
/// money totals for the shift (ADR-0008).
///
/// "Print tickets and charge" sells the order, print first (ADR-0007): the
/// payment and review screens ([PaymentView], [ReviewView]) take this page's
/// place until the order is paid or cancelled, so they stay behind the
/// router's open-shift rule.
///
/// Differs from the design:
/// - no tag chip on the cards ("Best seller", "Kids"): ticket types have no
///   such field;
/// - the header shows the server's state (2.8, no design), and offline a
///   banner under it with the queue; the printer badge also shows not set /
///   checking / not answering, and a tap checks again;
/// - offline, Find ticket and Close shift are disabled, and sign out and
///   Admin hidden: they need the server (ADR-0015);
/// - the header has sign out and, for supervisors and admins, Admin, as on
///   the open shift screen;
/// - Find ticket and Close shift open their screens over this one, so the
///   order in progress stays. Last order
///   reopens the review of the last order paid since the app started: the
///   cashier can't read orders (ADR-0014), so after a restart it's disabled;
/// - − is disabled at 0.
class SellPage extends StatelessWidget {
  const SellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SellCubit(
            repository: context.read<SellRepository>(),
            shiftRepository: context.read<ShiftRepository>(),
            printer: context.read<PrintService>(),
            shift: context.read<ShiftCubit>(),
            counterId: context.read<AppConfig>().counterId,
            store: context.read<OfflineStore>(),
            status: context.read<ServerStatusCubit>(),
            clock: context.read<Clock>(),
          )..load(),
        ),
        BlocProvider(
          create: (context) => CheckoutCubit(
            repository: context.read<SellRepository>(),
            printer: context.read<PrintService>(),
            store: context.read<OfflineStore>(),
            clock: context.read<Clock>(),
          ),
        ),
      ],
      child: const _CheckoutFlow(),
    );
  }
}

/// The sell, payment or review screen, by where the order is; and what the
/// sell screen does when the order moves on.
class _CheckoutFlow extends StatelessWidget {
  const _CheckoutFlow();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Peak started or ended with a type in the order that isn't on sale
        // any more: it was taken out (ADR-0033).
        BlocListener<SellCubit, SellState>(
          listenWhen: (previous, current) => current.periodNotices > previous.periodNotices,
          listener: (context, state) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).sellPeriodChanged)),
          ),
        ),
        BlocListener<CheckoutCubit, CheckoutState>(
          listenWhen: (previous, current) =>
              current.failure != null && previous.failure != current.failure,
          listener: (context, state) {
            switch (state.failure) {
              case SellFailureKind.ticketTypeUnavailable || SellFailureKind.ticketTypeNotNow:
                context.read<SellCubit>().reloadTypes();
              case SellFailureKind.noOpenShift:
                // Closed meanwhile: reloading it lets the router leave selling.
                context.read<ShiftCubit>().load();
              case SellFailureKind.serverUnreachable:
                // Check now, so the next press sells offline (ADR-0015).
                context.read<ServerStatusCubit>().reportUnreachable();
              default:
                break;
            }
          },
        ),
        // An offline sale was stored: the banner's queue and codes change.
        BlocListener<CheckoutCubit, CheckoutState>(
          listenWhen: (previous, current) =>
              current.stage == CheckoutStage.confirmed &&
              previous.stage == CheckoutStage.payment &&
              (current.order?.offline ?? false),
          listener: (context, state) => context.read<OfflineSyncCubit>().refresh(),
        ),
        // The server confirmed a shift started from its copy (ADR-0026): the
        // copy of the catalog may be from earlier.
        BlocListener<ShiftCubit, ShiftState>(
          listenWhen: (previous, current) =>
              previous is ShiftOpen &&
              previous.fromCopy &&
              current is ShiftOpen &&
              !current.fromCopy,
          listener: (context, state) => context.read<SellCubit>().refreshFromServer(),
        ),
        // Offline orders uploaded: the server's counts have them now.
        BlocListener<OfflineSyncCubit, OfflineSyncState>(
          listenWhen: (previous, current) =>
              current.queue.unsyncedOrders < previous.queue.unsyncedOrders,
          listener: (context, state) => context.read<SellCubit>().refreshCounts(),
        ),
        // A method switched on the payment screen is the sell screen's too,
        // so the next order, after a confirm or a cancel, starts with it.
        BlocListener<CheckoutCubit, CheckoutState>(
          listenWhen: (previous, current) =>
              current.stage == CheckoutStage.payment && previous.method != current.method,
          listener: (context, state) => context.read<SellCubit>().pickMethod(state.method),
        ),
        // Paid or cancelled (by the cashier or the unpaid-order job): the
        // next order starts from 0, so a cancelled order's quantities can't
        // be sold again by mistake; the method stays. The counts change, and
        // the types are read again, so an admin's new price or order shows
        // before the next sale (4.5; nothing while offline).
        // Back from an offline payment screen stored nothing: the order stays.
        // An online order left with the server out of reach starts from 0
        // too (ADR-0039), as its printed tickets go back to the counter.
        BlocListener<CheckoutCubit, CheckoutState>(
          listenWhen: (previous, current) =>
              previous.stage == CheckoutStage.payment &&
              current.stage != CheckoutStage.payment &&
              !((previous.order?.offline ?? false) && current.stage == CheckoutStage.idle),
          listener: (context, state) {
            final sell = context.read<SellCubit>();
            sell.clear();
            sell.refreshCounts();
            sell.reloadTypes();
          },
        ),
      ],
      child: BlocBuilder<CheckoutCubit, CheckoutState>(
        buildWhen: (previous, current) => previous.stage != current.stage,
        builder: (context, state) => switch (state.stage) {
          CheckoutStage.payment => const PaymentView(),
          CheckoutStage.confirmed => const ReviewView(),
          CheckoutStage.idle || CheckoutStage.selling => const _SellView(),
        },
      ),
    );
  }
}

class _SellView extends StatelessWidget {
  const _SellView();

  /// Sells the draft. Online, [CheckoutCubit] creates the order and the
  /// payment screen takes over while its tickets print (ADR-0007). Offline,
  /// the payment screen comes first and the tickets print after the confirm
  /// (ADR-0015).
  static void _charge(BuildContext context) {
    final sell = context.read<SellCubit>().state;
    final draft = sell.draft;
    final settings = sell.settings;
    final shift = context.read<ShiftCubit>().state;
    final auth = context.read<AuthCubit>().state;
    if (draft == null || settings == null || shift is! ShiftOpen || auth is! AuthSignedIn) return;
    final setup = CheckoutSetup(
      venueName: settings.venueName,
      tipsEnabled: settings.tipsEnabled,
      counterName: sell.counter?.name ?? shift.shift.counterName,
      cashierName: auth.staff.fullName,
      printer: sell.printerTarget,
    );
    final checkout = context.read<CheckoutCubit>();
    // A shift still running from its copy (ADR-0026): the server hasn't answered
    // since the start, even if the first check hasn't said so yet.
    final online = !context.read<ServerStatusCubit>().isOffline && !shift.fromCopy;
    if (online) return unawaited(checkout.start(draft, setup));
    checkout.startOffline(
      draft,
      setup,
      OfflineSaleSetup(
        shiftId: shift.shift.id,
        counterId: shift.shift.counterId,
        venueDay: settings.venueDay,
        poolSize: settings.offlinePoolSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SellCubit>();
    final checkout = context.read<CheckoutCubit>();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f12): () {
          if (!cubit.state.isEmpty) _charge(context);
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          cubit.clear();
          checkout.dismiss();
        },
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
              const _SellHeader(),
              const OfflineBanner(),
              Expanded(child: BlocBuilder<SellCubit, SellState>(builder: _body)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SellState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SellCubit>();
    const padding = EdgeInsets.symmetric(horizontal: 24, vertical: 20);

    Widget message(Widget box) => SingleChildScrollView(
          padding: padding,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: box),
          ),
        );

    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Align(alignment: Alignment.topCenter, child: CircularProgressIndicator()),
      );
    }
    if (state.loadFailure case final kind?) {
      return message(MessageBox.danger(
        message: kind == SellFailureKind.serverUnreachable
            ? l10n.errorServerUnreachable
            : l10n.errorUnexpected,
        onRetry: cubit.load,
      ));
    }
    if (state.types.isEmpty) {
      return message(MessageBox.warning(message: l10n.noTicketTypes, onRetry: cubit.load));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // The design's flex-wrap: side by side while both fit, else stacked.
        final wide = constraints.maxWidth - padding.horizontal >=
            _sectionMinWidth + _panelGap + _panelWidth;
        if (!wide) {
          return SingleChildScrollView(
            padding: padding,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_TypesSection(), SizedBox(height: _panelGap), _OrderPanel(fill: false)],
            ),
          );
        }
        // The order panel stays in view; the cards scroll on their own.
        return const Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: SingleChildScrollView(child: _TypesSection())),
              SizedBox(width: _panelGap),
              SizedBox(width: _panelWidth, child: _OrderPanel(fill: true)),
            ],
          ),
        );
      },
    );
  }
}

const _sectionMinWidth = 560.0;
const _panelWidth = 360.0;
const _panelGap = 20.0;

/// Title, counter · shift · start time, and the printer badge.
class _SellHeader extends StatelessWidget {
  const _SellHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shift = context.watch<ShiftCubit>().state;
    final printer = context.select((SellCubit cubit) => cubit.state.printer);
    final subtitle = switch (shift) {
      ShiftOpen(:final shift) => l10n.sellSubtitle(
          shift.counterName,
          shift.number,
          DateFormat.Hm(locale).format(shift.openedAt),
        ),
      _ => '',
    };
    return AppHeader(
      title: l10n.sellTitle,
      subtitle: subtitle,
      badges: [_PrinterBadge(status: printer)],
    );
  }
}

class _PrinterBadge extends StatelessWidget {
  const _PrinterBadge({required this.status});

  final PrinterStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final (text, background, foreground, dot) = switch (status) {
      PrinterStatus.reachable =>
        (l10n.printerBadgeReady, tokens.successBg, tokens.successText, tokens.successDot),
      PrinterStatus.notSet =>
        (l10n.printerBadgeNotSet, tokens.warningBg, tokens.warningText, tokens.warningText),
      PrinterStatus.unreachable =>
        (l10n.printerBadgeUnreachable, tokens.warningBg, tokens.warningText, tokens.warningText),
      _ => (l10n.printerBadgeChecking, tokens.inset, tokens.textSecondary, tokens.textSecondary),
    };
    final canCheck = status != PrinterStatus.checking;

    return Tooltip(
      message: l10n.printerBadgeHint,
      child: Semantics(
        liveRegion: true,
        button: canCheck,
        child: InkWell(
          onTap: canCheck ? context.read<SellCubit>().checkPrinter : null,
          customBorder: const StadiumBorder(),
          // A 44 px target around the design's small pill.
          child: SizedBox(
            height: AppSizes.touchTarget,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Heading and tool buttons, the type cards, and the shift's counts.
class _TypesSection extends StatelessWidget {
  const _TypesSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final types = context.select((SellCubit cubit) => cubit.state.visibleTypes);
    final peak = context.select((SellCubit cubit) => cubit.state.peak);
    final hasLast = context.select((CheckoutCubit cubit) => cubit.state.last != null);
    final selling = context.select((CheckoutCubit cubit) => cubit.state.submitting);
    // Offline only selling works (ADR-0015): lookups and closing need the
    // server.
    final offline = context.select((ServerStatusCubit cubit) => cubit.isOffline);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.sellHeading,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                if (peak) const _PeakChip(),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ToolButton(
                  icon: Icons.search,
                  label: l10n.findTicket,
                  tooltip: offline ? l10n.needsServer : null,
                  onPressed: offline ? null : () => _findTicket(context),
                ),
                _ToolButton(
                  icon: Icons.print_outlined,
                  label: l10n.lastOrder,
                  onPressed: hasLast ? context.read<CheckoutCubit>().showLast : null,
                ),
                _ToolButton(
                  icon: Icons.lock_outline,
                  label: l10n.closeShift,
                  tooltip: offline ? l10n.needsServer : null,
                  // Not while a sale is being created: its order would be
                  // awaiting payment.
                  onPressed: selling || offline ? null : () => _closeShift(context),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (types.isEmpty)
          MessageBox.warning(message: l10n.sellNothingOnSale)
        else
          _TypeGrid(types: types),
        const SizedBox(height: 16),
        const _CountsFooter(),
      ],
    );
  }
}

/// "وقت الذروة": only the peak types are on sale (ADR-0033).
class _PeakChip extends StatelessWidget {
  const _PeakChip();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      key: const ValueKey('sell-peak-chip'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.warningBg,
        border: Border.all(color: tokens.warningBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppLocalizations.of(context).sellPeakChip,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.warningText),
      ),
    );
  }
}

/// The lookup, with what a reprint's copy needs from this screen.
void _findTicket(BuildContext context) {
  final sell = context.read<SellCubit>().state;
  context.push(
    AppRoutes.ticket,
    extra: TicketPrintSetup(venueName: sell.settings?.venueName ?? '', printer: sell.printerTarget),
  );
}

/// Close shift, over this screen, with this counter's printer for the
/// receipt.
void _closeShift(BuildContext context) =>
    context.push(AppRoutes.closeShift, extra: context.read<SellCubit>().state.printerTarget);

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, this.onPressed, this.tooltip});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Why it is disabled, e.g. "needs the server".
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tooltip = this.tooltip;
    final button = _button(context);
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _button(BuildContext context) {
    final tokens = context.tokens;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: tokens.surface,
        side: BorderSide(color: tokens.border),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// The design's `repeat(auto-fill, minmax(240px, 1fr))`: as many columns as
/// fit at 240 px, cards in a row as tall as the tallest.
class _TypeGrid extends StatelessWidget {
  const _TypeGrid({required this.types});

  final List<TicketType> types;

  static const _minCardWidth = 240.0;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(1, ((constraints.maxWidth + _gap) / (_minCardWidth + _gap)).floor());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var start = 0; start < types.length; start += columns) ...[
              if (start > 0) const SizedBox(height: _gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: _gap),
                      Expanded(
                        child: start + column < types.length
                            ? _TypeCard(type: types[start + column])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type});

  final TicketType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<SellCubit>();
    final quantity = context.select((SellCubit cubit) => cubit.state.quantityOf(type));
    final entries = type.entriesAllowed == 1
        ? l10n.ticketRuleSingleEntry
        : l10n.ticketRuleEntries(type.entriesAllowed);
    final validity = switch (type.validity) {
      TicketValidity.sameDay => l10n.ticketRuleValidToday,
      TicketValidity.hoursFromSale => l10n.ticketRuleValidHours(type.validityHours ?? 0),
    };

    return Container(
      key: ValueKey('type-card-${type.id}'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: quantity > 0 ? tokens.primary : tokens.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            type.name(l10n.localeName),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('$entries · $validity', style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
          const SizedBox(height: 14),
          Text(
            formatMoney(l10n, type.pricePiastres),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          // Keeps the steppers of a row's cards level.
          const Spacer(),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.border))),
            // + is on the right in both languages, as in both designs.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StepButton(
                    key: ValueKey('decrease-${type.id}'),
                    label: l10n.decreaseQuantity,
                    increase: false,
                    onPressed: quantity > 0 ? () => cubit.decrement(type) : null,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48),
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                  ),
                  _StepButton(
                    key: ValueKey('increase-${type.id}'),
                    label: l10n.increaseQuantity,
                    increase: true,
                    onPressed: () => cubit.increment(type),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The cards' 56 px + / − buttons.
class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.label,
    required this.increase,
    required this.onPressed,
  });

  final String label;
  final bool increase;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    const size = Size.square(56);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const textStyle = TextStyle(fontSize: 28, fontWeight: FontWeight.w600);
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: increase
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                minimumSize: size,
                maximumSize: size,
                padding: EdgeInsets.zero,
                shape: shape,
                textStyle: textStyle,
              ),
              child: const Text('+'),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: size,
                maximumSize: size,
                padding: EdgeInsets.zero,
                shape: shape,
                foregroundColor: tokens.text,
                side: BorderSide(color: tokens.inputBorder),
                textStyle: textStyle,
              ),
              child: const Text('−'),
            ),
    );
  }
}

/// The shift's counts, never money (ADR-0008). "—" when they couldn't be read.
class _CountsFooter extends StatelessWidget {
  const _CountsFooter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final counts = context.select((SellCubit cubit) => cubit.state.counts);
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    String count(int? value) => value == null ? '—' : numbers.format(value);
    final lastOrder = counts?.lastOrderNumber;

    Widget item(String label, String value) => Text.rich(
          TextSpan(
            text: '$label ',
            children: [
              TextSpan(
                text: value,
                style: TextStyle(color: tokens.text, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          style: TextStyle(fontSize: 14, color: tokens.textSecondary),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        children: [
          item(l10n.footerShiftOrders, count(counts?.ordersCount)),
          item(l10n.footerTicketsSold, count(counts?.ticketsCount)),
          item(l10n.footerLastOrder, lastOrder == null ? '—' : '#$lastOrder'),
        ],
      ),
    );
  }
}

/// The current order: lines, payment method, total and the main button.
class _OrderPanel extends StatelessWidget {
  const _OrderPanel({required this.fill});

  /// Side by side, the panel fills the height; stacked, it is as tall as its
  /// content.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<SellCubit>();
    final checkout = context.read<CheckoutCubit>();
    final state = context.watch<SellCubit>().state;
    final selling = context.select((CheckoutCubit cubit) => cubit.state.submitting);
    final failure = context.select((CheckoutCubit cubit) => cubit.state.failure);
    final cancelledNumber = context.select((CheckoutCubit cubit) => cubit.state.cancelledNumber);
    final lines = state.lines;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 160),
      child: lines.isEmpty
          ? const _EmptyOrder()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, line) in lines.indexed) ...[
                  if (index > 0) const SizedBox(height: 10),
                  _OrderLineRow(line: line),
                ],
              ],
            ),
    );

    final panel = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.currentOrder,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: state.isEmpty
                    ? null
                    : () {
                        cubit.clear();
                        checkout.dismiss();
                      },
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.touchTarget),
                  foregroundColor: tokens.dangerAction,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: Text(l10n.clearOrder),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (fill) Expanded(child: content) else content,
          const SizedBox(height: 16),
          Text(
            l10n.paymentMethodLabel,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (index, method) in PaymentMethod.values.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: _MethodButton(
                    method: method,
                    selected: state.method == method,
                    onPressed: () => cubit.pickMethod(method),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.border))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l10n.orderTotal(state.ticketCount),
                    style: TextStyle(fontSize: 16, color: tokens.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatMoney(l10n, state.totalPiastres),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (failure != null) ...[
            const SizedBox(height: 16),
            MessageBox.danger(
              // The sale didn't reach the server: once the check confirms
              // it, the same button sells offline.
              message: failure == SellFailureKind.serverUnreachable
                  ? l10n.sellConnectionLost
                  : sellFailureMessage(l10n, failure),
            ),
          ] else if (cancelledNumber != null) ...[
            const SizedBox(height: 16),
            MessageBox.warning(message: l10n.orderCancelledNotice(cancelledNumber)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            child: FilledButton.icon(
              onPressed: state.isEmpty || selling ? null : () => _SellView._charge(context),
              icon: selling
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.print_outlined, size: 22),
              label: Text(l10n.printAndCharge),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.sellShortcutsHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: tokens.textSecondary),
          ),
        ],
      ),
    );

    if (!fill) return panel;
    // Fills the height, with the lines taking what is left; scrolls as a
    // whole when the window is too short for it.
    return CustomScrollView(
      slivers: [SliverFillRemaining(hasScrollBody: false, child: panel)],
    );
  }
}

class _OrderLineRow extends StatelessWidget {
  const _OrderLineRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: tokens.inset, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.type.name(l10n.localeName),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n.orderLineQuantity(line.quantity, formatMoney(l10n, line.type.pricePiastres)),
                  style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMoney(l10n, line.subtotalPiastres),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrder extends StatelessWidget {
  const _EmptyOrder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return CustomPaint(
      painter: DashedBorderPainter(color: tokens.border),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.confirmation_number_outlined, size: 32, color: tokens.textSecondary),
              const SizedBox(height: 8),
              Text(
                l10n.orderEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: tokens.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({required this.method, required this.selected, required this.onPressed});

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final label = paymentMethodName(l10n, method);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: selected ? tokens.primary : tokens.surface,
          foregroundColor: selected ? tokens.surface : tokens.text,
          side: BorderSide(color: selected ? tokens.primary : tokens.border, width: 2),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
