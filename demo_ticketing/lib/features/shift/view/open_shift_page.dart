import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/clock.dart';
import '../../../core/config/app_config.dart';
import '../../../core/printer/print_service.dart';
import '../../../core/printer/printer_status.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../home/view/app_header.dart';
import '../../home/view/message_box.dart';
import '../bloc/open_shift_cubit.dart';
import '../bloc/shift_cubit.dart';
import '../data/shift_repository.dart';

/// Open shift (`OpenShift.dc.html`): the opening float, the printer check and
/// test print, then `open_shift`. The router moves on to selling once
/// [ShiftCubit] has a shift at this counter.
///
/// Differs from the design:
/// - the float field starts empty, so the cashier counts rather than
///   accepting a default, and isn't thousand-grouped while typing;
/// - the language switch is in the header, as on Login;
/// - the printer card shows the address only (the Xprinter model isn't
///   confirmed);
/// - messages the design doesn't have: no counter in this PC's config,
///   counter unknown or inactive, counter without a home gate (1.10a), and an
///   open shift at another counter.
class OpenShiftPage extends StatelessWidget {
  const OpenShiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OpenShiftCubit(
        repository: context.read<ShiftRepository>(),
        printer: context.read<PrintService>(),
        shift: context.read<ShiftCubit>(),
        counterId: context.read<AppConfig>().counterId,
        cashierName: switch (context.read<AuthCubit>().state) {
          AuthSignedIn(:final staff) => staff.fullName,
          _ => '',
        },
        clock: context.read<Clock>(),
      )..load(),
      child: const _OpenShiftView(),
    );
  }
}

class _OpenShiftView extends StatefulWidget {
  const _OpenShiftView();

  @override
  State<_OpenShiftView> createState() => _OpenShiftViewState();
}

class _OpenShiftViewState extends State<_OpenShiftView> {
  final _float = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuilds the open button as the field fills or empties.
    _float.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  /// Whole pounds typed, in piastres; null when the field is empty.
  int? get _floatPiastres {
    final pounds = int.tryParse(_float.text);
    return pounds == null ? null : pounds * 100;
  }

  void _submit() => context.read<OpenShiftCubit>().submit(_floatPiastres);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        // The header spans the window, as in the design.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<OpenShiftCubit, OpenShiftState>(
            buildWhen: (previous, current) =>
                previous.counter != current.counter || previous.today != current.today,
            builder: (context, state) {
              final locale = Localizations.localeOf(context).toLanguageTag();
              final date = DateFormat.yMMMMEEEEd(locale).format(state.today);
              final counterName = state.counter?.name;
              return AppHeader(
                title: AppLocalizations.of(context).openShiftTitle,
                subtitle: counterName == null ? date : '$counterName · $date',
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: BlocBuilder<ShiftCubit, ShiftState>(builder: _body),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, ShiftState shift) {
    final l10n = AppLocalizations.of(context);
    switch (shift) {
      // Loading, or about to move on to selling.
      case ShiftUnknown() || ShiftOpen(atThisCounter: true):
        return const _Spinner();
      case ShiftLoadFailed(:final kind):
        return MessageBox.danger(
          message: _failureText(l10n, kind),
          onRetry: () => context.read<ShiftCubit>().load(),
        );
      case ShiftOpen(:final shift):
        return MessageBox.warning(message: l10n.openShiftElsewhere(shift.counterName));
      case ShiftNone():
        return BlocBuilder<OpenShiftCubit, OpenShiftState>(builder: _form);
    }
  }

  Widget _form(BuildContext context, OpenShiftState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<OpenShiftCubit>();
    if (state.loading) return const _Spinner();
    if (state.loadFailure case final kind?) {
      return MessageBox.danger(message: _failureText(l10n, kind), onRetry: cubit.load);
    }
    if (state.block case final block?) {
      return MessageBox.warning(
        message: switch (block) {
          OpenShiftBlock.noCounterConfigured => l10n.openShiftNoCounter,
          OpenShiftBlock.counterUnavailable => l10n.openShiftCounterUnavailable,
          OpenShiftBlock.counterNoHomeGate => l10n.openShiftCounterNoHomeGate,
        },
        // An admin can fix the counter while the cashier waits; the config
        // needs a new build.
        onRetry: block == OpenShiftBlock.noCounterConfigured ? null : cubit.load,
      );
    }

    final failure = state.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.lastClosedAt case final closedAt?) ...[
          _LastClosedBanner(closedAt: closedAt, today: state.today),
          const SizedBox(height: 20),
        ],
        _FloatCard(
          controller: _float,
          quickAmountsPiastres: state.quickAmountsPiastres,
          enabled: !state.submitting,
          onSubmitted: _submit,
        ),
        const SizedBox(height: 20),
        _PrinterCard(state: state),
        const SizedBox(height: 20),
        SizedBox(
          height: 64,
          child: FilledButton(
            onPressed: state.canOpen && _floatPiastres != null ? _submit : null,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            child: state.submitting
                ? const SizedBox.square(
                    dimension: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(l10n.openShiftButton),
          ),
        ),
        if (failure != null) ...[
          const SizedBox(height: 20),
          _RevealOnShow(child: MessageBox.danger(message: _failureText(l10n, failure))),
        ],
      ],
    );
  }

  static String _failureText(AppLocalizations l10n, ShiftFailureKind kind) => switch (kind) {
        ShiftFailureKind.invalidOpeningCash => l10n.openShiftErrorInvalidCash,
        ShiftFailureKind.counterBusy => l10n.openShiftErrorCounterBusy,
        ShiftFailureKind.counterUnavailable => l10n.openShiftCounterUnavailable,
        ShiftFailureKind.counterNoHomeGate => l10n.openShiftCounterNoHomeGate,
        ShiftFailureKind.serverUnreachable => l10n.errorServerUnreachable,
        // The rest belong to close shift and can't come from open_shift.
        _ => l10n.errorUnexpected,
      };
}

class _LastClosedBanner extends StatelessWidget {
  const _LastClosedBanner({required this.closedAt, required this.today});

  final DateTime closedAt;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.Hm(locale).format(closedAt);
    final days = DateUtils.dateOnly(today).difference(DateUtils.dateOnly(closedAt)).inDays;
    final message = switch (days) {
      0 => l10n.lastShiftClosedToday(time),
      1 => l10n.lastShiftClosedYesterday(time),
      _ => l10n.lastShiftClosedOn(DateFormat.MMMMd(locale).format(closedAt), time),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.primaryTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: tokens.onPrimaryTint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 14, color: tokens.onPrimaryTint)),
          ),
        ],
      ),
    );
  }
}

class _FloatCard extends StatelessWidget {
  const _FloatCard({
    required this.controller,
    required this.quickAmountsPiastres,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final List<int> quickAmountsPiastres;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final numbers = NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag());
    // The field takes whole pounds, so a quick amount with piastres can't be
    // offered.
    final quickPounds = [
      for (final piastres in quickAmountsPiastres)
        if (piastres % 100 == 0) piastres ~/ 100,
    ];
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: tokens.primary, width: 2),
    );

    return _Section(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.openingFloatTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Text(l10n.openingFloatHint, style: TextStyle(fontSize: 15, color: tokens.textSecondary)),
          const SizedBox(height: 18),
          Text(
            l10n.openingFloatLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: enabled,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              // Up to 9,999,999 EGP.
              LengthLimitingTextInputFormatter(7),
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmitted(),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              constraints: const BoxConstraints(minHeight: 64),
              contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 12),
              border: fieldBorder,
              enabledBorder: fieldBorder,
              focusedBorder: fieldBorder,
            ),
          ),
          if (quickPounds.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pounds in quickPounds)
                  OutlinedButton(
                    onPressed: enabled ? () => controller.text = '$pounds' : null,
                    style: _quietButton(tokens),
                    child: Text(numbers.format(pounds)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PrinterCard extends StatelessWidget {
  const _PrinterCard({required this.state});

  final OpenShiftState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<OpenShiftCubit>();
    final host = state.counter?.printerHost;
    final status = state.printer;

    final (text, background, foreground) = switch (status) {
      PrinterStatus.notSet => (l10n.printerNotSet, tokens.warningBg, tokens.warningText),
      PrinterStatus.checking => (l10n.printerChecking, tokens.bg, tokens.textSecondary),
      PrinterStatus.reachable => (l10n.printerReachable, tokens.bg, tokens.textSecondary),
      PrinterStatus.unreachable => (l10n.printerUnreachable, tokens.warningBg, tokens.warningText),
      PrinterStatus.printing => (l10n.printerPrinting, tokens.bg, tokens.textSecondary),
      PrinterStatus.printed => (l10n.printerPrinted, tokens.successBg, tokens.successDot),
      PrinterStatus.printFailed => (l10n.printerPrintFailed, tokens.dangerBg, tokens.dangerText),
    };
    final busy = status == PrinterStatus.checking || status == PrinterStatus.printing;

    return _Section(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.print_outlined, size: 22, color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  host == null ? l10n.printerLabelNone : l10n.printerLabel(host),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(text, style: TextStyle(fontSize: 14, color: foreground)),
                ),
              ],
            ),
          ),
          if (host != null) ...[
            const SizedBox(width: 12),
            if (status == PrinterStatus.unreachable) ...[
              OutlinedButton(
                onPressed: cubit.checkPrinter,
                style: _quietButton(tokens),
                child: Text(l10n.checkPrinterAgain),
              ),
              const SizedBox(width: 8),
            ],
            OutlinedButton(
              onPressed: busy ? null : cubit.testPrint,
              style: _quietButton(tokens),
              child: Text(l10n.testPrint),
            ),
          ],
        ],
      ),
    );
  }
}

/// The design's secondary buttons: input-colored border, 15px semibold.
ButtonStyle _quietButton(AppTokens tokens) => OutlinedButton.styleFrom(
      side: BorderSide(color: tokens.inputBorder),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );

/// A white card section, as in the design.
class _Section extends StatelessWidget {
  const _Section({required this.padding, required this.child});

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: child,
    );
  }
}

/// Scrolls its child into view when it appears: on a 1366×768 counter screen
/// an error under the open button is otherwise below the fold.
class _RevealOnShow extends StatefulWidget {
  const _RevealOnShow({required this.child});

  final Widget child;

  @override
  State<_RevealOnShow> createState() => _RevealOnShowState();
}

class _RevealOnShowState extends State<_RevealOnShow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 200));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
}
