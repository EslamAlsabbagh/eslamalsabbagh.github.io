import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/ticket_types_cubit.dart';
import '../data/admin_ticket_type.dart';
import '../data/ticket_types_repository.dart';
import 'peak_card.dart';
import 'ticket_types_messages.dart';

/// Ticket types & prices (task 4.5, `TicketTypes.dc.html`): every type with
/// its price, entries, validity and status, the order on the sell screen
/// (↑/↓), and an edit panel. Admins only. Each save is logged in the actions
/// log (`save_ticket_type`).
class TicketTypesPage extends StatelessWidget {
  const TicketTypesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => TicketTypesCubit(context.read<TicketTypesRepository>())..start(),
    child: const _TicketTypesView(),
  );
}

class _TicketTypesView extends StatelessWidget {
  const _TicketTypesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<TicketTypesCubit>().state;
    final cubit = context.read<TicketTypesCubit>();
    final types = state.types;

    final Widget body;
    if (types == null) {
      final failure = state.loadFailure;
      body = failure == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.typesLoading, style: TextStyle(color: tokens.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Text(
                    typesFailureMessage(l10n, failure),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (failure != TicketTypesFailureKind.notAllowed)
                    FilledButton(onPressed: cubit.refresh, child: Text(l10n.retry)),
                ],
              ),
            );
    } else {
      // The panel is rebuilt for another type, so its fields start from it.
      final panel = _EditPanel(
        key: ValueKey(state.creating ? 'types-panel-new' : 'types-panel-${state.selectedId}'),
        type: state.selected,
      );
      final table = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PeakCard(editSchedule: true),
          const SizedBox(height: 20),
          for (final warning in _periodWarnings(l10n, types)) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.warningBg,
                border: Border.all(color: tokens.warningBorder),
                borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              ),
              child: Text(warning, style: TextStyle(fontSize: 14, color: tokens.warningText)),
            ),
            const SizedBox(height: 12),
          ],
          _Table(types: types, state: state),
        ],
      );
      body = LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [table, const SizedBox(height: 20), panel],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  key: const ValueKey('types-table-scroll'),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: table,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: panel,
                ),
              ),
            ],
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Text(
                l10n.navTicketTypes,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.actionsRefresh,
                    onPressed: state.loading ? null : cubit.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: AppSizes.touchTarget,
                    child: FilledButton.icon(
                      key: const ValueKey('types-new'),
                      onPressed: types == null || state.creating ? null : cubit.startNew,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        l10n.typesNew,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Peak or normal time with no type on sale (ADR-0033): the cashier would
/// have nothing to sell then.
List<String> _periodWarnings(AppLocalizations l10n, List<AdminTicketType> types) {
  final onSale = [
    for (final t in types)
      if (t.active) t.salePeriod,
  ];
  if (onSale.isEmpty) return const [];
  return [
    if (!onSale.any((p) => p.onSale(peak: true))) l10n.typesNoPeakType,
    if (!onSale.any((p) => p.onSale(peak: false))) l10n.typesNoOffPeakType,
  ];
}

class _Table extends StatelessWidget {
  const _Table({required this.types, required this.state});

  final List<AdminTicketType> types;
  final TicketTypesState state;

  static const _flex = [3, 2, 2, 2, 2, 2];
  static const _orderWidth = 100.0;

  static Widget cells(List<Widget> children, Widget order) => Row(
    children: [
      for (var i = 0; i < children.length; i++)
        Expanded(
          flex: _flex[i],
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: children[i]),
        ),
      SizedBox(width: _orderWidth, child: order),
    ],
  );

  Future<void> _move(BuildContext context, String id, MoveDirection direction) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failure = await context.read<TicketTypesCubit>().move(id, direction);
    if (failure != null) {
      messenger?.showSnackBar(SnackBar(content: Text(typesFailureMessage(l10n, failure))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final header = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: tokens.textSecondary,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: cells([
                Text(l10n.typesColType, style: header),
                Text(l10n.typesColPrice, style: header),
                Text(l10n.typesColEntries, style: header),
                Text(l10n.typesColValidity, style: header),
                Text(l10n.typesColSale, style: header),
                Text(l10n.typesColStatus, style: header),
              ], Text(l10n.typesColOrder, style: header, textAlign: TextAlign.center)),
            ),
            if (types.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.typesEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ),
            for (var i = 0; i < types.length; i++)
              _row(context, types[i], first: i == 0, last: i == types.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    AdminTicketType type, {
    required bool first,
    required bool last,
  }) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<TicketTypesCubit>();
    final selected = !state.creating && state.selectedId == type.id;
    final busy = state.moving != null;
    final (chipBg, chipFg) = type.active
        ? (tokens.successBg, tokens.successText)
        : (tokens.bg, tokens.textMuted);

    return DecoratedBox(
      key: ValueKey('type-row-${type.id}'),
      decoration: BoxDecoration(
        color: selected ? tokens.primaryTint : null,
        border: Border(top: BorderSide(color: tokens.rowDivider)),
      ),
      child: InkWell(
        onTap: () => cubit.select(type.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: cells(
              [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.nameAr,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    Text(type.nameEn, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
                  ],
                ),
                Text(
                  formatMoney(l10n, type.pricePiastres),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(entriesText(l10n, type.entriesAllowed), style: const TextStyle(fontSize: 15)),
                Text(
                  validityText(l10n, type.validity, type.validityHours),
                  style: const TextStyle(fontSize: 15),
                ),
                Text(salePeriodText(l10n, type.salePeriod), style: const TextStyle(fontSize: 15)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      activeText(l10n, type.active),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: chipFg),
                    ),
                  ),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: ValueKey('type-up-${type.id}'),
                    tooltip: l10n.typesMoveUp,
                    onPressed: first || busy
                        ? null
                        : () => _move(context, type.id, MoveDirection.up),
                    icon: const Icon(Icons.arrow_upward, size: 20),
                  ),
                  IconButton(
                    key: ValueKey('type-down-${type.id}'),
                    tooltip: l10n.typesMoveDown,
                    onPressed: last || busy
                        ? null
                        : () => _move(context, type.id, MoveDirection.down),
                    icon: const Icon(Icons.arrow_downward, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The edit panel. Its fields start from [type], or empty for a new one; the
/// page gives it a new key per type, so switching rows drops unsaved edits
/// (as the design).
class _EditPanel extends StatefulWidget {
  const _EditPanel({super.key, required this.type});

  /// Null for a new type.
  final AdminTicketType? type;

  @override
  State<_EditPanel> createState() => _EditPanelState();
}

class _EditPanelState extends State<_EditPanel> {
  late final _nameAr = TextEditingController(text: widget.type?.nameAr ?? '');
  late final _nameEn = TextEditingController(text: widget.type?.nameEn ?? '');
  late final _price = TextEditingController(
    text: widget.type == null ? '' : piastresText(widget.type!.pricePiastres),
  );
  late final _entries = TextEditingController(text: '${widget.type?.entriesAllowed ?? 1}');
  late final _hours = TextEditingController(text: '${widget.type?.validityHours ?? ''}');
  late TicketValidity _validity = widget.type?.validity ?? TicketValidity.sameDay;
  late bool _active = widget.type?.active ?? true;
  late SalePeriod _salePeriod = widget.type?.salePeriod ?? SalePeriod.always;

  /// The server's last refusal, shown on its field or in the banner.
  TicketTypesFailureKind? _failure;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameAr, _nameEn, _price, _entries, _hours]) {
      c.addListener(_changed);
    }
  }

  @override
  void dispose() {
    for (final c in [_nameAr, _nameEn, _price, _entries, _hours]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() => _failure = null);

  int? get _pricePiastres => parsePiastres(_price.text);
  int? get _entriesValue => int.tryParse(_entries.text.trim());
  int? get _hoursValue => int.tryParse(_hours.text.trim());

  bool get _hoursKind => _validity == TicketValidity.hoursFromSale;

  /// The panel's values, or null while one is missing or wrong.
  TicketTypeDraft? get _draft {
    final price = _pricePiastres;
    final entries = _entriesValue;
    final hours = _hoursValue;
    if (_nameAr.text.trim().isEmpty || _nameEn.text.trim().isEmpty) return null;
    if (price == null || entries == null || entries < 1) return null;
    if (_hoursKind && (hours == null || hours < 1)) return null;
    return TicketTypeDraft(
      nameAr: _nameAr.text.trim(),
      nameEn: _nameEn.text.trim(),
      pricePiastres: price,
      entriesAllowed: entries,
      validity: _validity,
      validityHours: _hoursKind ? hours : null,
      active: _active,
      salePeriod: _salePeriod,
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failure = await context.read<TicketTypesCubit>().save(draft);
    if (!mounted) return;
    if (failure == null) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.typesSaved)));
    } else {
      setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final languageCode = Localizations.localeOf(context).languageCode;
    final saving = context.select((TicketTypesCubit c) => c.state.saving);
    final type = widget.type;
    final draft = _draft;
    final changed = draft != null && (type == null || !draft.sameAs(type.draft));

    // Format errors only on something typed; an empty field just keeps Save off.
    final priceError = _price.text.trim().isNotEmpty && _pricePiastres == null
        ? l10n.typesInvalidPrice
        : null;
    final entriesError = _entries.text.trim().isNotEmpty && (_entriesValue ?? 0) < 1
        ? l10n.typesInvalidEntries
        : null;
    final hoursError = _hours.text.trim().isNotEmpty && (_hoursValue ?? 0) < 1
        ? l10n.typesInvalidHours
        : null;

    final fieldFailure = switch (_failure) {
      TicketTypesFailureKind.nameArTaken ||
      TicketTypesFailureKind.nameEnTaken ||
      TicketTypesFailureKind.invalidPrice ||
      TicketTypesFailureKind.invalidEntries ||
      TicketTypesFailureKind.invalidValidityHours => true,
      _ => false,
    };
    final failureText = _failure == null ? null : typesFailureMessage(l10n, _failure!);

    InputDecoration decoration({String? error}) => InputDecoration(
      isDense: true,
      errorText: error,
      errorMaxLines: 2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: BorderSide(color: tokens.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: BorderSide(color: tokens.inputBorder),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

    Widget field(String label, Widget input) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        input,
      ],
    );

    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );

    final digits = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              type == null ? l10n.typesNew : l10n.typesEditTitle(type.name(languageCode)),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            pair(
              field(
                l10n.typesNameAr,
                TextField(
                  key: const ValueKey('types-name-ar'),
                  controller: _nameAr,
                  textDirection: TextDirection.rtl,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  decoration: decoration(
                    error: _failure == TicketTypesFailureKind.nameArTaken ? failureText : null,
                  ),
                ),
              ),
              field(
                l10n.typesNameEn,
                TextField(
                  key: const ValueKey('types-name-en'),
                  controller: _nameEn,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  decoration: decoration(
                    error: _failure == TicketTypesFailureKind.nameEnTaken ? failureText : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            pair(
              field(
                l10n.typesPrice,
                TextField(
                  key: const ValueKey('types-price'),
                  controller: _price,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    // Up to 9,999,999.99 EGP.
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: decoration(
                    error:
                        priceError ??
                        (_failure == TicketTypesFailureKind.invalidPrice ? failureText : null),
                  ),
                ),
              ),
              field(
                l10n.typesEntriesLabel,
                TextField(
                  key: const ValueKey('types-entries'),
                  controller: _entries,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: decoration(
                    error:
                        entriesError ??
                        (_failure == TicketTypesFailureKind.invalidEntries ? failureText : null),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            field(
              l10n.typesValidityLabel,
              DropdownButtonFormField<TicketValidity>(
                key: const ValueKey('types-validity'),
                initialValue: _validity,
                isExpanded: true,
                decoration: decoration(),
                items: [
                  DropdownMenuItem(
                    value: TicketValidity.sameDay,
                    child: Text(l10n.typesValidityOptionSameDay),
                  ),
                  DropdownMenuItem(
                    value: TicketValidity.hoursFromSale,
                    child: Text(l10n.typesValidityOptionHours),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _validity = value;
                      _failure = null;
                    });
                  }
                },
              ),
            ),
            if (_hoursKind) ...[
              const SizedBox(height: 12),
              field(
                l10n.typesHoursLabel,
                TextField(
                  key: const ValueKey('types-hours'),
                  controller: _hours,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: decoration(
                    error:
                        hoursError ??
                        (_failure == TicketTypesFailureKind.invalidValidityHours
                            ? failureText
                            : null),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            field(
              l10n.typesSalePeriodLabel,
              DropdownButtonFormField<SalePeriod>(
                key: const ValueKey('types-sale-period'),
                initialValue: _salePeriod,
                isExpanded: true,
                decoration: decoration(),
                items: [
                  for (final period in SalePeriod.values)
                    DropdownMenuItem(value: period, child: Text(salePeriodText(l10n, period))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _salePeriod = value;
                      _failure = null;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.inset,
                borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.typesActiveLabel,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          l10n.typesActiveNote,
                          style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const ValueKey('types-active'),
                    value: _active,
                    onChanged: (value) => setState(() {
                      _active = value;
                      _failure = null;
                    }),
                  ),
                ],
              ),
            ),
            if (type != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: tokens.warningBg,
                  borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                ),
                child: Text(
                  l10n.typesPriceNote,
                  style: TextStyle(fontSize: 14, color: tokens.warningText),
                ),
              ),
            ],
            if (failureText != null && !fieldFailure) ...[
              const SizedBox(height: 14),
              Container(
                key: const ValueKey('types-failure'),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: tokens.dangerBg,
                  borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                ),
                child: Text(failureText, style: TextStyle(fontSize: 14, color: tokens.dangerText)),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const ValueKey('types-save'),
                onPressed: changed && !saving ? _save : null,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        type == null ? l10n.typesAdd : l10n.typesSave,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.typesLogNote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
