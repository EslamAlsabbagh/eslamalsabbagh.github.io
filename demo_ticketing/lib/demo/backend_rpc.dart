part of 'backend.dart';

/// The database functions, re-stated over the in-memory tables. Each returns
/// the JSON its Postgres namesake returns and raises the same error keys.
extension _Rpc on DemoBackend {
  Object? _dispatch(String fn, Map<String, dynamic> p) => switch (fn) {
        // Selling
        'my_shift_counts' => _myShiftCounts(),
        'sell_tickets' => _sellTickets(p['p_items'] as List),
        'confirm_payment' => _confirmPayment(p),
        'cancel_order' => _cancelOrder(p),
        'leave_unprinted_tickets' => _leaveUnprinted(p),
        // Shift
        'last_shift_closed_at' => _lastClosedAt(p['p_counter_id'] as String),
        'open_shift' => _openShift(p['p_counter_id'] as String, p['p_opening_cash_piastres'] as int),
        'my_shift_tips' => _myShiftTips(),
        'add_tip' => _addTip(p['p_amount_piastres'] as int),
        'close_shift' => _closeShift(p['p_counts'] as List),
        'set_my_language' => _me().language = p['p_language'] as String,
        // Tickets
        'lookup_ticket' => _lookup(p['p_code'] as String),
        'reprint_ticket' => _reprint(p),
        'reactivate_ticket' => _reactivate(p),
        'void_refund_ticket' => _voidRefund(p),
        // Admin
        'dashboard_today' => _dashboard(),
        'shifts_overview' => _shiftsOverview(p['p_period'] as String),
        'shift_reconciliation' => [
            for (final s in shifts)
              if (s.id == p['p_shift_id']) _shiftRow(s),
          ],
        'shift_offline_refusals' => <dynamic>[],
        'approve_shift' => _approveShift(p['p_shift_id'] as String, p['p_comment'] as String?),
        'resolve_offline_refusal' => throw const PostgrestException(message: 'refusal_not_found'),
        'actions_log' => _actionsLog(p),
        'mark_action_reviewed' => _markReviewed(p['p_action_id'] as String),
        'sales_report' => _salesReport(p),
        'save_ticket_type' => _saveTicketType(p),
        'move_ticket_type' => _moveTicketType(p['p_id'] as String, p['p_direction'] as String),
        'peak_state' => _peakState(),
        'save_peak_times' => _savePeakTimes(p),
        'set_peak_override' => _setPeakOverride(p['p_mode'] as String),
        'gates_overview' => _gatesOverview(),
        'save_gate' => _saveGate(p),
        'save_controller' => _saveController(p),
        'test_open_gate' => _testOpen(p['p_gate_id'] as String),
        'test_open_status' => _testOpenStatus(p['p_command_id'] as String),
        'users_overview' => _usersOverview(),
        'save_staff' => _saveStaff(p),
        'reset_staff_password' => _resetPassword(p['p_staff_id'] as String, p['p_password'] as String),
        'settings_overview' => _settingsOverview(),
        'save_settings' => _saveSettings(p['p_changes'] as Map),
        'save_counter' => _saveCounter(p),
        // Offline
        'reserve_offline_codes' => _reserveCodes(),
        'sync_offline_orders' => _syncOrders(p['p_shift_id'] as String, p['p_orders'] as List),
        'sync_offline_actions' => _syncActions(p['p_shift_id'] as String, p['p_actions'] as List),
        _ => throw PostgrestException(message: 'unknown function $fn', code: 'PGRST202'),
      };

  // ── Selling (ADR-0007) ──────────────────────────────────────────────────────

  Map<String, dynamic> _myShiftCounts() {
    final shift = _requireMyShift();
    final mine = orders.where((o) => o.shiftId == shift.id).toList();
    final paid = mine.where((o) => o.status == 'paid').toList();
    return {
      'orders_count': paid.length,
      'tickets_count': tickets.where((t) => paid.any((o) => o.id == t.orderId)).length,
      'awaiting_payment_count': mine.where((o) => o.status == 'awaiting_payment').length,
      'last_order_number': mine.isEmpty ? null : mine.map((o) => o.number).reduce(max),
    };
  }

  DateTime _validUntil(_Type type, DateTime at) => type.validityKind == 'hours_from_sale'
      ? at.add(Duration(hours: type.validityHours ?? 4))
      : venueDay.closingFor(at);

  /// Whether [type] is on sale at [at] (peak times, ADR-0033).
  bool _onSale(_Type type, DateTime at) {
    final isPeak = peak.isPeakAt(at, day: venueDay);
    return switch (type.salePeriod) { 'peak' => isPeak, 'off_peak' => !isPeak, _ => true };
  }

  Map<String, dynamic> _sellTickets(List items) {
    final shift = _requireMyShift();
    final counter = _counter(shift.counterId)!;
    if (counter.entryGateId == null) throw const PostgrestException(message: 'counter_no_home_gate');
    final now = _now;
    if (!now.isBefore(venueDay.closingFor(now))) throw const PostgrestException(message: 'after_closing_time');
    final lines = <(_Type, int)>[];
    for (final item in items.cast<Map<String, dynamic>>()) {
      final type = _type(item['ticket_type_id'] as String);
      if (type == null || !type.active) throw const PostgrestException(message: 'ticket_type_unavailable');
      if (!_onSale(type, now)) throw const PostgrestException(message: 'ticket_type_not_now');
      lines.add((type, item['quantity'] as int));
    }
    final total = lines.fold(0, (sum, l) => sum + l.$1.price * l.$2);
    final order = _Order(_id('o'), ++_orderNumber, shift.id, total, now);
    orders.add(order);
    for (final (type, quantity) in lines) {
      for (var i = 0; i < quantity; i++) {
        tickets.add(_Ticket(_id('t'), order.id, type.id, type.price, counter.entryGateId, _newGateCode(), now,
            _validUntil(type, now), type.entries));
      }
    }
    return _soldOrder(order);
  }

  Map<String, dynamic> _soldOrder(_Order order) => {
        'order_id': order.id,
        'order_number': order.number,
        'total_piastres': order.total,
        'created_at': DemoBackend._iso(order.createdAt),
        'tickets': [
          for (final t in tickets.where((t) => t.orderId == order.id))
            {
              'id': t.id,
              'gate_code': t.gateCode,
              'ticket_type_id': t.typeId,
              'name_ar': _type(t.typeId)!.nameAr,
              'name_en': _type(t.typeId)!.nameEn,
              'price_piastres': t.price,
              'entries_left': t.entriesLeft,
              'valid_from': DemoBackend._iso(t.validFrom),
              'valid_until': DemoBackend._iso(t.validUntil),
              'home_gate_name': _gate(t.homeGateId)?.name ?? '',
            },
        ],
      };

  _Order _myOrder(String id) {
    final order = _order(id);
    if (order == null || _shift(order.shiftId)?.cashierId != _userId) {
      throw const PostgrestException(message: 'order_not_found');
    }
    return order;
  }

  Map<String, dynamic> _confirmPayment(Map<String, dynamic> p) {
    final order = _myOrder(p['p_order_id'] as String);
    if (order.status == 'paid') throw const PostgrestException(message: 'order_already_paid');
    if (order.status == 'cancelled') throw const PostgrestException(message: 'order_cancelled');
    final method = p['p_payment_method'] as String;
    final tip = (p['p_tip_piastres'] as int?) ?? 0;
    if (tip < 0) throw const PostgrestException(message: 'invalid_tip');
    if (tip > 0 && method != 'cash') throw const PostgrestException(message: 'tip_requires_cash');
    if (tip > 0 && !_flag('tips_enabled')) throw const PostgrestException(message: 'tips_disabled');
    var received = p['p_amount_received_piastres'] as int?;
    if (method == 'cash') {
      if (received == null || received < order.total + tip) {
        throw const PostgrestException(message: 'invalid_amount_received');
      }
    } else {
      received = order.total;
    }
    order
      ..status = 'paid'
      ..method = method
      ..amountReceived = received
      ..paidAt = _now;
    for (final t in tickets.where((t) => t.orderId == order.id)) {
      t.status = 'active';
    }
    if (tip > 0) tips.add(_Tip(_id('tip'), order.shiftId, order.id, tip, 'with_order', _now));
    return {
      'payment_method': method,
      'total_piastres': order.total,
      'tip_piastres': tip,
      'amount_received_piastres': received,
      'change_piastres': received - order.total - tip,
    };
  }

  Map<String, dynamic> _cancelOrder(Map<String, dynamic> p) {
    final order = _myOrder(p['p_order_id'] as String);
    if (order.status == 'paid') throw const PostgrestException(message: 'order_already_paid');
    if (order.status == 'cancelled') throw const PostgrestException(message: 'order_cancelled');
    order
      ..status = 'cancelled'
      ..cancelledAt = _now;
    for (final t in tickets.where((t) => t.orderId == order.id)) {
      t.status = 'voided';
    }
    _log('cancel_order', orderId: order.id, reason: p['p_reason'] as String?, reasonText: p['p_reason_text'] as String?);
    return {};
  }

  Map<String, dynamic> _leaveUnprinted(Map<String, dynamic> p) {
    final order = _myOrder(p['p_order_id'] as String);
    for (final id in (p['p_ticket_ids'] as List).cast<String>()) {
      _log('left_unprinted',
          orderId: order.id,
          ticketId: id,
          reason: p['p_reason'] as String?,
          reasonText: p['p_reason_text'] as String?,
          extraFlags: ['unprinted_ticket']);
    }
    return {};
  }

  /// Writes a ticket_actions row with its automatic review flags (ADR-0009).
  _Action _log(
    String action, {
    String? ticketId,
    String? orderId,
    String? gateId,
    String? reason,
    String? reasonText,
    int? amount,
    Map<String, dynamic>? details,
    List<String> extraFlags = const [],
    DateTime? at,
    String? actorId,
    String? shiftId,
  }) {
    final actor = actorId ?? _userId;
    final shift = shiftId ?? _myOpenShift()?.id;
    final entry = _Action(_id('a'), actor, shift, action, at ?? _now,
        ticketId: ticketId,
        orderId: orderId ?? _ticket(ticketId)?.orderId,
        gateId: gateId,
        reasonCode: reason,
        reasonText: reasonText,
        amount: amount,
        details: details);
    final flags = [...extraFlags];
    if (reason == 'other' && _flag('flag_other_reason')) flags.add('other_reason');
    if (shift != null && action != 'settings_change' && action != 'test_open') {
      final count = actions.where((a) => a.shiftId == shift && a.actorId == actor).length + 1;
      if (count > _num('flag_actions_per_shift')) flags.add('too_many_actions');
    }
    if (action == 'reprint' && (_ticket(ticketId)?.printCount ?? 0) > _num('flag_prints_per_ticket')) {
      flags.add('too_many_prints');
    }
    entry.flags = flags;
    actions.add(entry);
    return entry;
  }

  // ── Shift (ADR-0008) ────────────────────────────────────────────────────────

  String? _lastClosedAt(String counterId) {
    final closed = shifts.where((s) => s.counterId == counterId && s.closedAt != null).toList()
      ..sort((a, b) => b.closedAt!.compareTo(a.closedAt!));
    return closed.isEmpty ? null : DemoBackend._iso(closed.first.closedAt!);
  }

  Map<String, dynamic> _openShift(String counterId, int openingCash) {
    final me = _me();
    if (_myOpenShift() != null) throw const PostgrestException(message: 'shift_already_open');
    final counter = _counter(counterId);
    if (counter == null || !counter.active) throw const PostgrestException(message: 'counter_unavailable');
    if (counter.entryGateId == null) throw const PostgrestException(message: 'counter_no_home_gate');
    if (shifts.any((s) => s.counterId == counterId && s.status == 'open')) {
      throw const PostgrestException(message: 'counter_busy');
    }
    if (openingCash < 0) throw const PostgrestException(message: 'invalid_opening_cash');
    final shift = _Shift(_id('s'), ++_shiftNumber, me.id, counterId, _now, openingCash);
    shifts.add(shift);
    return {
      'shift_id': shift.id,
      'shift_number': shift.number,
      'counter_id': counter.id,
      'counter_name': counter.name,
      'opened_at': DemoBackend._iso(shift.openedAt),
    };
  }

  Map<String, dynamic> _tipJson(_Tip t) => {
        'tip_id': t.id,
        'order_number': _order(t.orderId)?.number,
        'amount_piastres': t.amount,
        'created_at': DemoBackend._iso(t.createdAt),
      };

  List<dynamic> _myShiftTips() {
    final shift = _requireMyShift();
    return [for (final t in tips.where((t) => t.shiftId == shift.id)) _tipJson(t)];
  }

  Map<String, dynamic> _addTip(int amount) {
    final shift = _requireMyShift();
    if (!_flag('tips_enabled')) throw const PostgrestException(message: 'tips_disabled');
    if (amount <= 0) throw const PostgrestException(message: 'invalid_tip');
    final tip = _Tip(_id('tip'), shift.id, null, amount, 'added_at_close', _now);
    tips.add(tip);
    return _tipJson(tip);
  }

  Map<String, dynamic> _closeShift(List counts) {
    final shift = _requireMyShift();
    if (orders.any((o) => o.shiftId == shift.id && o.status == 'awaiting_payment')) {
      throw const PostgrestException(message: 'orders_awaiting_payment');
    }
    var counted = 0;
    for (final c in counts.cast<Map<String, dynamic>>()) {
      final n = c['count'] as int;
      if (n < 0) throw const PostgrestException(message: 'invalid_cash_count');
      counted += (c['denomination_piastres'] as int) * n;
    }
    shift
      ..status = 'closed'
      ..closedAt = _now
      ..countedCash = counted;
    return _receipt(shift);
  }

  Map<String, dynamic> _receipt(_Shift shift) {
    final paid = orders.where((o) => o.shiftId == shift.id && o.status == 'paid').toList();
    final sold = tickets.where((t) => paid.any((o) => o.id == t.orderId)).toList();
    final byType = <String, int>{};
    for (final t in sold) {
      byType[t.typeId] = (byType[t.typeId] ?? 0) + 1;
    }
    final shiftTips = tips.where((t) => t.shiftId == shift.id).toList();
    int count(String action) => actions.where((a) => a.shiftId == shift.id && a.action == action).length;
    return {
      'shift_number': shift.number,
      'counter_name': _counter(shift.counterId)!.name,
      'cashier_name': _staff(shift.cashierId)!.fullName,
      'opened_at': DemoBackend._iso(shift.openedAt),
      'closed_at': DemoBackend._iso(shift.closedAt!),
      'tickets_by_type': [
        for (final e in byType.entries)
          {'name_ar': _type(e.key)!.nameAr, 'name_en': _type(e.key)!.nameEn, 'count': e.value},
      ],
      'tickets_total': sold.length,
      'orders_count': paid.length,
      'counted_cash_piastres': shift.countedCash,
      'tips': {
        'count': shiftTips.length,
        'total_piastres': shiftTips.fold(0, (s, t) => s + t.amount),
        'added_at_close_count': shiftTips.where((t) => t.source == 'added_at_close').length,
      },
      'actions': {
        for (final a in ['reprint', 'reactivate', 'void_refund', 'cancel_order', 'left_unprinted']) a: count(a),
      },
    };
  }

  // ── Tickets (ADR-0009) ──────────────────────────────────────────────────────

  _Ticket _ticketByCode(String code) {
    final n = int.tryParse(code.trim());
    final found = tickets.where((t) => t.gateCode == n).toList()
      ..sort((a, b) => b.validFrom.compareTo(a.validFrom));
    if (found.isEmpty) throw const PostgrestException(message: 'ticket_not_found');
    return found.first;
  }

  String _status(_Ticket t) =>
      (t.status == 'active' || t.status == 'used') && t.validUntil.isBefore(_now) ? 'expired' : t.status;

  List<_Scan> _acceptedScans(_Ticket t) =>
      scans.where((s) => s.ticketId == t.id && s.result == 'accepted').toList()
        ..sort((a, b) => a.scannedAt.compareTo(b.scannedAt));

  /// Why [action] is refused for [t] right now, or null; and until when it
  /// is allowed.
  (String?, DateTime?) _blocked(String action, _Ticket t) {
    final shift = _myOpenShift();
    if (shift == null) return ('no_open_shift', null);
    final status = _status(t);
    if (status == 'voided') return ('ticket_voided', null);
    if (status == 'expired') return ('ticket_expired', null);
    final type = _type(t.typeId)!;
    switch (action) {
      case 'reprint':
        if (status == 'pending') return ('ticket_not_paid', null);
        return (null, null);
      case 'reactivate':
        if (status == 'pending') return ('ticket_not_paid', null);
        final scanned = _acceptedScans(t);
        if (scanned.isEmpty || t.entriesLeft >= type.entries) return ('not_scanned', null);
        final maxReactivations = _num('reactivation_max');
        if (t.reactivationCount >= maxReactivations) {
          return (maxReactivations <= 1 ? 'already_reactivated' : 'reactivation_limit_reached', null);
        }
        final until = scanned.last.scannedAt.add(Duration(minutes: _num('reactivation_window_min')));
        if (_now.isAfter(until)) return ('reactivation_window_passed', null);
        return (null, until);
      case 'void_refund':
        if (status == 'pending') return ('ticket_not_paid', null);
        if (_flag('refund_before_scan_only') && _acceptedScans(t).isNotEmpty) return ('ticket_already_scanned', null);
        if (_flag('refund_same_shift_only') && _order(t.orderId)!.shiftId != shift.id) return ('not_same_shift', null);
        return (null, null);
    }
    return ('unexpected', null);
  }

  Map<String, dynamic> _lookup(String code) {
    _me();
    final t = _ticketByCode(code);
    final order = _order(t.orderId)!;
    final shift = _shift(order.shiftId)!;
    final type = _type(t.typeId)!;
    Map<String, dynamic> allowance(String action) {
      final (blockedBy, until) = _blocked(action, t);
      return {'allowed': blockedBy == null, 'blocked_by': blockedBy, 'until': until == null ? null : DemoBackend._iso(until)};
    }

    return {
      'ticket_id': t.id,
      'gate_code': t.gateCode,
      'status': _status(t),
      'name_ar': type.nameAr,
      'name_en': type.nameEn,
      'price_piastres': t.price,
      'entries_allowed': type.entries,
      'entries_left': t.entriesLeft,
      'valid_from': DemoBackend._iso(t.validFrom),
      'valid_until': DemoBackend._iso(t.validUntil),
      'print_count': t.printCount,
      'reactivation_count': t.reactivationCount,
      'created_at': DemoBackend._iso(order.createdAt),
      'home_gate_name': _gate(t.homeGateId)?.name,
      'order_number': order.number,
      'payment_method': order.method,
      'sold_by_name': _staff(shift.cashierId)!.fullName,
      'counter_name': _counter(shift.counterId)!.name,
      'scans': [
        for (final s in scans.where((s) => s.ticketId == t.id).toList().reversed)
          {
            'gate_name': _gate(s.gateId)!.name,
            'result': s.result,
            'reason': s.reason,
            'scanned_at': DemoBackend._iso(s.scannedAt),
          },
      ],
      'actions': [
        for (final a in actions.where((a) => a.ticketId == t.id).toList().reversed)
          {
            'action': a.action,
            'actor_name': _staff(a.actorId)?.fullName,
            'counter_name': _counter(_shift(a.shiftId)?.counterId)?.name,
            'reason_code': a.reasonCode,
            'reason_text': a.reasonText,
            'created_at': DemoBackend._iso(a.createdAt),
          },
      ],
      'actions_allowed': {for (final a in ['reprint', 'reactivate', 'void_refund']) a: allowance(a)},
    };
  }

  _Ticket _actOn(Map<String, dynamic> p, String action) {
    final t = _ticket(p['p_ticket_id'] as String);
    if (t == null) throw const PostgrestException(message: 'ticket_not_found');
    final reason = p['p_reason'] as String?;
    if (reason == null || reason.isEmpty) throw const PostgrestException(message: 'invalid_reason');
    final text = (p['p_reason_text'] as String?)?.trim() ?? '';
    if (reason == 'other' && text.isEmpty) throw const PostgrestException(message: 'reason_text_required');
    final (blockedBy, _) = _blocked(action, t);
    if (blockedBy != null) throw PostgrestException(message: blockedBy);
    return t;
  }

  Map<String, dynamic> _reprint(Map<String, dynamic> p) {
    final t = _actOn(p, 'reprint');
    t.printCount++;
    _log('reprint',
        ticketId: t.id,
        reason: p['p_reason'] as String?,
        reasonText: p['p_reason_text'] as String?,
        details: {'copy_number': t.printCount});
    final order = _order(t.orderId)!;
    final shift = _shift(order.shiftId)!;
    final siblings = tickets.where((x) => x.orderId == order.id).toList();
    final type = _type(t.typeId)!;
    return {
      'gate_code': t.gateCode,
      'name_ar': type.nameAr,
      'name_en': type.nameEn,
      'price_piastres': t.price,
      'entries_left': t.entriesLeft,
      'valid_from': DemoBackend._iso(t.validFrom),
      'valid_until': DemoBackend._iso(t.validUntil),
      'print_count': t.printCount,
      'order_number': order.number,
      'home_gate_name': _gate(t.homeGateId)?.name ?? '',
      'sold_at': DemoBackend._iso(order.createdAt),
      'counter_name': _counter(shift.counterId)!.name,
      'sold_by_name': _staff(shift.cashierId)!.fullName,
      'ticket_index': siblings.indexOf(t) + 1,
      'ticket_count': siblings.length,
    };
  }

  Map<String, dynamic> _reactivate(Map<String, dynamic> p) {
    final t = _actOn(p, 'reactivate');
    final last = _acceptedScans(t).last;
    t
      ..entriesLeft += 1
      ..status = 'active'
      ..reactivationCount += 1;
    _log('reactivate',
        ticketId: t.id,
        reason: p['p_reason'] as String?,
        reasonText: p['p_reason_text'] as String?,
        gateId: last.gateId,
        details: {'undone_gate_id': last.gateId});
    return {};
  }

  Map<String, dynamic> _voidRefund(Map<String, dynamic> p) {
    final t = _actOn(p, 'void_refund');
    final order = _order(t.orderId)!;
    t.status = 'voided';
    _log('void_refund',
        ticketId: t.id, reason: p['p_reason'] as String?, reasonText: p['p_reason_text'] as String?, amount: t.price);
    return {'amount_piastres': t.price, 'payment_method': order.method};
  }

  // ── Admin: live dashboard (ADR-0030) ────────────────────────────────────────

  DateTime get _dayStart => venueDay.startOf(today);

  String _gateStatus(_Gate g) {
    if (!g.enabled) return 'disabled';
    final seen = g.lastSeenAt;
    if (seen == null) return 'never_seen';
    return _now.difference(seen).inSeconds > _num('gate_offline_after_seconds') ? 'offline' : 'online';
  }

  /// Gate services beat every few seconds; the demo's live ones beat on read.
  void _heartbeat() {
    for (final g in gates) {
      if (g.enabled && g.lastSeenAt != null && _now.difference(g.lastSeenAt!).inMinutes < 5) g.lastSeenAt = _now;
    }
  }

  Map<String, dynamic> _dashboard() {
    _requireRole({'supervisor', 'admin'});
    _heartbeat();
    final start = _dayStart;
    final todays = scans.where((s) => !s.scannedAt.isBefore(start)).toList();
    final accepted = todays.where((s) => s.result == 'accepted').toList();
    final rejected = todays.where((s) => s.result == 'rejected').toList();
    final paidToday = orders.where((o) => o.status == 'paid' && !o.paidAt!.isBefore(start)).toList();
    final soldToday = tickets.where((t) => paidToday.any((o) => o.id == t.orderId)).toList();
    final refunds = actions
        .where((a) => a.action == 'void_refund' && !a.createdAt.isBefore(start))
        .fold(0, (s, a) => s + (a.amount ?? 0));
    final byReason = <String, int>{};
    for (final s in rejected) {
      byReason[s.reason ?? 'not_found'] = (byReason[s.reason ?? 'not_found'] ?? 0) + 1;
    }
    final hours = <Map<String, dynamic>>[];
    for (var h = start; !h.isAfter(_now); h = h.add(const Duration(hours: 1))) {
      final end = h.add(const Duration(hours: 1));
      hours.add({
        'hour': h.hour,
        'entries': accepted.where((s) => !s.scannedAt.isBefore(h) && s.scannedAt.isBefore(end)).length,
      });
    }
    final feed = [...todays]..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return {
      'now': DemoBackend._iso(_now),
      'day': DemoBackend._ymd(today),
      'day_starts_at': settings['venue_day_starts_at'],
      'current_hour': _now.hour,
      'entries': accepted.length,
      'first_entry_at': accepted.isEmpty
          ? null
          : DemoBackend._iso(accepted.map((s) => s.scannedAt).reduce((a, b) => a.isBefore(b) ? a : b)),
      'sales_piastres': paidToday.fold(0, (s, o) => s + o.total) - refunds,
      'open_counters': shifts.where((s) => s.status == 'open').length,
      'tickets_sold': soldToday.length,
      'tickets_not_entered': soldToday.where((t) => t.status == 'active' && _acceptedScans(t).isEmpty).length,
      'rejected': rejected.length,
      'rejected_by_reason': byReason,
      'gates': [
        for (final g in gates.where((g) => g.direction == 'entry'))
          {
            'id': g.id,
            'name': g.name,
            'status': _gateStatus(g),
            'last_seen_at': g.lastSeenAt == null ? null : DemoBackend._iso(g.lastSeenAt!),
            'last_scan_at': _lastScanAt(g.id),
            'entries': accepted.where((s) => s.gateId == g.id).length,
            'rejected': rejected.where((s) => s.gateId == g.id).length,
          },
      ],
      'hours': hours,
      'feed': [
        for (final s in feed.take(30))
          {
            'scan_id': s.id,
            'scanned_at': DemoBackend._iso(s.scannedAt),
            'gate_name': _gate(s.gateId)!.name,
            'result': s.result,
            'reason': s.reason,
            'type_name_ar': _type(_ticket(s.ticketId)?.typeId)?.nameAr,
            'type_name_en': _type(_ticket(s.ticketId)?.typeId)?.nameEn,
            'pool_code': s.poolCode,
          },
      ],
    };
  }

  String? _lastScanAt(String gateId) {
    final mine = scans.where((s) => s.gateId == gateId).toList();
    if (mine.isEmpty) return null;
    return DemoBackend._iso(mine.map((s) => s.scannedAt).reduce((a, b) => a.isAfter(b) ? a : b));
  }

  // ── Admin: shifts and reconciliation (ADR-0008, ADR-0017) ───────────────────

  Map<String, dynamic> _shiftRow(_Shift s) {
    final mine = orders.where((o) => o.shiftId == s.id && o.status == 'paid').toList();
    int sales(String method) => mine.where((o) => o.method == method).fold(0, (sum, o) => sum + o.total);
    final shiftTips = tips.where((t) => t.shiftId == s.id).toList();
    final tipsTotal = shiftTips.fold(0, (sum, t) => sum + t.amount);
    final cashRefunds = actions
        .where((a) => a.shiftId == s.id && a.action == 'void_refund' && _order(a.orderId)?.method == 'cash')
        .fold(0, (sum, a) => sum + (a.amount ?? 0));
    final expected = s.openingCash + sales('cash') + tipsTotal - cashRefunds;
    final shiftActions = actions.where((a) => a.shiftId == s.id).toList();
    return {
      'shift_id': s.id,
      'shift_number': s.number,
      'status': s.status,
      'cashier_id': s.cashierId,
      'cashier_name': _staff(s.cashierId)!.fullName,
      'counter_name': _counter(s.counterId)!.name,
      'opened_at': DemoBackend._iso(s.openedAt),
      'closed_at': s.closedAt == null ? null : DemoBackend._iso(s.closedAt!),
      'opening_cash_piastres': s.openingCash,
      'cash_sales_piastres': sales('cash'),
      'card_sales_piastres': sales('card'),
      'wallet_sales_piastres': sales('wallet'),
      'paid_orders': mine.length,
      'offline_orders': mine.where((o) => o.clientId != null).length,
      'unsynced_entries': 0,
      'refused_offline_orders': 0,
      'tips_piastres': tipsTotal,
      'tip_count': shiftTips.length,
      'cash_refunds_piastres': cashRefunds,
      'expected_cash_piastres': expected,
      'counted_cash_piastres': s.countedCash,
      'difference_piastres': s.countedCash == null ? null : s.countedCash! - expected,
      'action_count': shiftActions.length,
      'flagged_action_count': shiftActions.where((a) => a.flags.isNotEmpty).length,
      'approved_by_name': _staff(s.approvedBy)?.fullName,
      'approved_at': s.approvedAt == null ? null : DemoBackend._iso(s.approvedAt!),
      'approval_comment': s.approvalComment,
    };
  }

  (DateTime, DateTime) _periodRange(String period) {
    final start = _dayStart;
    return switch (period) {
      'yesterday' => (start.subtract(const Duration(days: 1)), start),
      'week' => (start.subtract(const Duration(days: 6)), _now.add(const Duration(days: 1))),
      _ => (start, _now.add(const Duration(days: 1))),
    };
  }

  Map<String, dynamic> _shiftsOverview(String period) {
    _requireRole({'supervisor', 'admin'});
    final (from, to) = _periodRange(period);
    final list = shifts.where((s) {
      if (period == 'pending') return s.status == 'closed';
      final inRange = !s.openedAt.isBefore(from) && s.openedAt.isBefore(to);
      return inRange || (period == 'today' && s.status != 'approved');
    }).toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return {
      'now': DemoBackend._iso(_now),
      'day': DemoBackend._ymd(today),
      'period': period,
      'pending_count': shifts.where((s) => s.status == 'closed').length,
      'shifts': [for (final s in list) _shiftRow(s)],
      'orphan_entries': <dynamic>[],
    };
  }

  Object? _approveShift(String id, String? comment) {
    _requireRole({'supervisor', 'admin'});
    final s = _shift(id);
    if (s == null) throw const PostgrestException(message: 'shift_not_found');
    if (s.cashierId == _userId) throw const PostgrestException(message: 'cannot_approve_own_shift');
    if (s.status == 'approved') throw const PostgrestException(message: 'shift_already_approved');
    if (s.status != 'closed') throw const PostgrestException(message: 'shift_not_closed');
    final difference = _shiftRow(s)['difference_piastres'] as int?;
    if ((difference ?? 0) != 0 && (comment == null || comment.trim().isEmpty)) {
      throw const PostgrestException(message: 'comment_required');
    }
    s
      ..status = 'approved'
      ..approvedBy = _userId
      ..approvedAt = _now
      ..approvalComment = comment;
    return null;
  }

  // ── Admin: actions log (ADR-0031) ───────────────────────────────────────────

  Map<String, dynamic> _actionRow(_Action a) {
    final ticket = _ticket(a.ticketId);
    final order = _order(a.orderId);
    final shift = _shift(a.shiftId);
    return {
      'id': a.id,
      'created_at': DemoBackend._iso(a.createdAt),
      'action': a.action,
      'actor_id': a.actorId,
      'actor_name': _staff(a.actorId)?.fullName,
      'shift_id': a.shiftId,
      'shift_number': shift?.number,
      'counter_name': _counter(shift?.counterId)?.name,
      'order_number': order?.number,
      'type_name_ar': _type(ticket?.typeId)?.nameAr,
      'type_name_en': _type(ticket?.typeId)?.nameEn,
      // A live code is enough to forge a QR: only its last 3 digits leave.
      'code_tail': ticket == null ? null : '${ticket.gateCode}'.substring('${ticket.gateCode}'.length - 3),
      'copy_number': a.details?['copy_number'],
      'amount_piastres': a.amount,
      'payment_method': a.action == 'void_refund' ? order?.method : null,
      'reason_code': a.reasonCode,
      'reason_text': a.reasonText,
      'actor_shift_actions':
          a.shiftId == null ? null : actions.where((x) => x.shiftId == a.shiftId && x.actorId == a.actorId).length,
      'undone_gate_name': _gate(a.details?['undone_gate_id'] as String?)?.name,
      'gate_name': a.action == 'test_open' ? _gate(a.gateId)?.name : null,
      'test_open_result': a.details?['test_open_result'],
      'change': a.details?['change'],
      'flags': a.flags,
      'reviewed_by': a.reviewedBy,
      'reviewed_by_name': _staff(a.reviewedBy)?.fullName,
      'reviewed_at': a.reviewedAt == null ? null : DemoBackend._iso(a.reviewedAt!),
    };
  }

  Map<String, dynamic> _actionsLog(Map<String, dynamic> p) {
    _requireRole({'supervisor', 'admin'});
    final period = p['p_period'] as String;
    final shiftId = p['p_shift_id'] as String?;
    final actorId = p['p_actor_id'] as String?;
    final counterId = p['p_counter_id'] as String?;
    final (from, to) = _periodRange(period);
    final rows = actions.where((a) {
      final inPeriod = switch (period) {
        'review' => a.flags.isNotEmpty && a.reviewedAt == null,
        'shift' => a.shiftId == shiftId,
        _ => !a.createdAt.isBefore(from) && a.createdAt.isBefore(to),
      };
      return inPeriod &&
          (actorId == null || a.actorId == actorId) &&
          (counterId == null || _shift(a.shiftId)?.counterId == counterId);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final limit = p['p_limit'] as int?;
    final counts = <String, int>{};
    for (final a in rows) {
      counts[a.action] = (counts[a.action] ?? 0) + 1;
    }
    final refunds = rows.where((a) => a.action == 'void_refund').toList();
    final shift = _shift(shiftId);
    return {
      'now': DemoBackend._iso(_now),
      'day': DemoBackend._ymd(today),
      'period': period,
      'total': rows.length,
      'review_count': actions.where((a) => a.flags.isNotEmpty && a.reviewedAt == null).length,
      'counts': counts,
      'refund_count': refunds.length,
      'refund_piastres': refunds.fold(0, (s, a) => s + (a.amount ?? 0)),
      'rules': {
        'flag_other_reason': _flag('flag_other_reason'),
        'flag_actions_per_shift': _num('flag_actions_per_shift'),
        'flag_prints_per_ticket': _num('flag_prints_per_ticket'),
      },
      'staff': [
        for (final s in staff) {'id': s.id, 'full_name': s.fullName},
      ],
      'counters': [
        for (final c in counters) {'id': c.id, 'name': c.name},
      ],
      'rows': [for (final a in limit == null ? rows : rows.take(limit)) _actionRow(a)],
      'shift': shift == null
          ? null
          : {
              'id': shift.id,
              'number': shift.number,
              'cashier_name': _staff(shift.cashierId)!.fullName,
              'counter_name': _counter(shift.counterId)!.name,
            },
    };
  }

  Object? _markReviewed(String id) {
    _requireRole({'supervisor', 'admin'});
    final a = actions.where((x) => x.id == id).firstOrNull;
    if (a == null) throw const PostgrestException(message: 'action_not_found');
    if (a.actorId == _userId) throw const PostgrestException(message: 'cannot_review_own_action');
    if (a.flags.isEmpty) throw const PostgrestException(message: 'action_not_flagged');
    if (a.reviewedAt != null) throw const PostgrestException(message: 'action_already_reviewed');
    a
      ..reviewedBy = _userId
      ..reviewedAt = _now;
    return null;
  }

  // ── Admin: sales report (ADR-0032) ──────────────────────────────────────────

  Map<String, dynamic> _salesReport(Map<String, dynamic> p) {
    _requireRole({'supervisor', 'admin'});
    final period = p['p_period'] as String;
    final day = today;
    DateTime d(int y, int m, int dd) => DateTime(y, m, dd);
    final (DateTime first, DateTime last) = switch (period) {
      'yesterday' => (day.subtract(const Duration(days: 1)), day.subtract(const Duration(days: 1))),
      'week' => (day.subtract(const Duration(days: 6)), day),
      'month' => (d(day.year, day.month, 1), day),
      'last_month' => (d(day.year, day.month - 1, 1), d(day.year, day.month, 0)),
      'range' => (DateTime.parse(p['p_from'] as String), DateTime.parse(p['p_to'] as String)),
      _ => (day, day),
    };
    if (last.isBefore(first)) throw const PostgrestException(message: 'invalid_range');
    final from = venueDay.startOf(first);
    final to = venueDay.startOf(last.add(const Duration(days: 1)));
    bool inRange(DateTime t) => !t.isBefore(from) && t.isBefore(to);

    final paid = orders.where((o) => o.status == 'paid' && inRange(o.paidAt!)).toList();
    final sold = tickets.where((t) => paid.any((o) => o.id == t.orderId)).toList();
    final refunds = actions.where((a) => a.action == 'void_refund' && inRange(a.createdAt)).toList();
    final periodTips = tips.where((t) => inRange(t.createdAt)).toList();

    Map<String, dynamic> figures(Iterable<_Ticket> ts, Iterable<_Action> rs, {Iterable<_Tip>? tipRows}) {
      final sales = ts.fold(0, (s, t) => s + t.price);
      final refund = rs.fold(0, (s, a) => s + (a.amount ?? 0));
      final tipTotal = tipRows?.fold(0, (s, t) => s + t.amount);
      return {
        'tickets': ts.length,
        'sales_piastres': sales,
        'refund_count': rs.length,
        'refund_piastres': refund,
        'tips_piastres': tipTotal,
        'net_piastres': sales - refund + (tipTotal ?? 0),
      };
    }

    _Order orderOf(_Ticket t) => _order(t.orderId)!;
    _Shift shiftOf(_Ticket t) => _shift(orderOf(t).shiftId)!;
    List<Map<String, dynamic>> typeCounts(Iterable<_Ticket> ts) {
      final m = <String, int>{};
      for (final t in ts) {
        m[t.typeId] = (m[t.typeId] ?? 0) + 1;
      }
      return [for (final e in m.entries) {'id': e.key, 'tickets': e.value}];
    }

    return {
      'now': DemoBackend._iso(_now),
      'day': DemoBackend._ymd(day),
      'period': period,
      'from': DemoBackend._ymd(first),
      'to': DemoBackend._ymd(last),
      'totals': figures(sold, refunds, tipRows: periodTips),
      'by_type': [
        for (final type in types)
          if (sold.any((t) => t.typeId == type.id) || type.active)
            {
              ...figures(sold.where((t) => t.typeId == type.id),
                  refunds.where((a) => _ticket(a.ticketId)?.typeId == type.id)),
              'id': type.id,
              'name_ar': type.nameAr,
              'name_en': type.nameEn,
              'sort_order': type.sortOrder,
            },
      ],
      'by_cashier': [
        for (final s in staff)
          if (sold.any((t) => shiftOf(t).cashierId == s.id))
            {
              ...figures(sold.where((t) => shiftOf(t).cashierId == s.id),
                  refunds.where((a) => _shift(a.shiftId)?.cashierId == s.id),
                  tipRows: periodTips.where((t) => _shift(t.shiftId)?.cashierId == s.id)),
              'id': s.id,
              'name': s.fullName,
              'types': typeCounts(sold.where((t) => shiftOf(t).cashierId == s.id)),
              'counters': [
                for (final c in {for (final t in sold.where((t) => shiftOf(t).cashierId == s.id)) shiftOf(t).counterId})
                  {'name': _counter(c)!.name, 'gate': _gate(_counter(c)!.entryGateId)?.name},
              ],
            },
      ],
      'by_gate': [
        for (final g in gates)
          if (sold.any((t) => t.homeGateId == g.id))
            {
              ...figures(sold.where((t) => t.homeGateId == g.id),
                  refunds.where((a) => _ticket(a.ticketId)?.homeGateId == g.id)),
              'id': g.id,
              'name': g.name,
              'types': typeCounts(sold.where((t) => t.homeGateId == g.id)),
              'counters': [
                for (final c in counters.where((c) => c.entryGateId == g.id)) {'name': c.name, 'gate': null},
              ],
            },
      ],
      'by_method': [
        for (final m in ['cash', 'card', 'wallet'])
          if (paid.any((o) => o.method == m))
            {
              ...figures(sold.where((t) => orderOf(t).method == m),
                  refunds.where((a) => _order(a.orderId)?.method == m)),
              'method': m,
            },
      ],
      'by_day': [
        for (var dd = first; !dd.isAfter(last); dd = DateTime(dd.year, dd.month, dd.day + 1))
          {
            ...figures(
              sold.where((t) => venueDay.dayOf(orderOf(t).paidAt!) == dd),
              refunds.where((a) => venueDay.dayOf(a.createdAt) == dd),
            ),
            'date': DemoBackend._ymd(dd),
          },
      ],
    };
  }

  // ── Admin: ticket types and peak times (ADR-0033, ADR-0034) ─────────────────

  Map<String, dynamic> _saveTicketType(Map<String, dynamic> p) {
    _requireRole({'admin'});
    final id = p['p_id'] as String?;
    final nameAr = (p['p_name_ar'] as String).trim();
    final nameEn = (p['p_name_en'] as String).trim();
    if (nameAr.isEmpty || nameEn.isEmpty) throw const PostgrestException(message: 'invalid_name');
    final price = p['p_price_piastres'] as int;
    if (price < 0) throw const PostgrestException(message: 'invalid_price');
    final entries = p['p_entries_allowed'] as int;
    if (entries < 1) throw const PostgrestException(message: 'invalid_entries');
    if (types.any((t) => t.id != id && t.nameAr == nameAr)) throw const PostgrestException(message: 'name_ar_taken');
    if (types.any((t) => t.id != id && t.nameEn.toLowerCase() == nameEn.toLowerCase())) {
      throw const PostgrestException(message: 'name_en_taken');
    }
    final kind = p['p_validity_kind'] as String;
    final hours = p['p_validity_hours'] as int?;
    if (kind == 'hours_from_sale' && (hours == null || hours < 1)) {
      throw const PostgrestException(message: 'invalid_validity_hours');
    }
    _Type type;
    final changes = <String, dynamic>{};
    void set<T>(String key, T old, T value, void Function(T) apply) {
      if (old != value) changes[key] = {'old': old, 'new': value};
      apply(value);
    }

    if (id == null) {
      type = _Type(_id('tt'), nameAr, nameEn, price, (types.map((t) => t.sortOrder).fold(0, max)) + 1);
      types.add(type);
    } else {
      type = _type(id) ?? (throw const PostgrestException(message: 'not_found'));
    }
    set('name_ar', type.nameAr, nameAr, (v) => type.nameAr = v);
    set('name_en', type.nameEn, nameEn, (v) => type.nameEn = v);
    set('price_piastres', type.price, price, (v) => type.price = v);
    set('entries_allowed', type.entries, entries, (v) => type.entries = v);
    set('validity_kind', type.validityKind, kind, (v) => type.validityKind = v);
    set('validity_hours', type.validityHours, kind == 'hours_from_sale' ? hours : null, (v) => type.validityHours = v);
    set('active', type.active, p['p_active'] as bool, (v) => type.active = v);
    set('sale_period', type.salePeriod, p['p_sale_period'] as String, (v) => type.salePeriod = v);
    _logSettings({
      'subject': 'ticket_type',
      'name_ar': type.nameAr,
      'name_en': type.nameEn,
      'created': id == null,
      'changes': changes,
    });
    return type.row();
  }

  void _logSettings(Map<String, dynamic> change) =>
      _log('settings_change', details: {'change': change}, shiftId: null);

  Object? _moveTicketType(String id, String direction) {
    _requireRole({'admin'});
    final sorted = [...types]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final i = sorted.indexWhere((t) => t.id == id);
    if (i < 0) throw const PostgrestException(message: 'not_found');
    final j = direction == 'up' ? i - 1 : i + 1;
    if (j < 0 || j >= sorted.length) return null;
    final a = sorted[i], b = sorted[j];
    final tmp = a.sortOrder;
    a.sortOrder = b.sortOrder;
    b.sortOrder = tmp;
    return null;
  }

  Map<String, dynamic> _peakState() {
    final source = peak.sourceAt(_now, day: venueDay);
    final manualToday = settings['peak_override_day'] == DemoBackend._ymd(today) ? settings['peak_override'] as bool? : null;
    return {
      'peak': source.peak,
      'source': source.key,
      'weekdays': settings['peak_weekdays'],
      'from': settings['peak_from'],
      'to': settings['peak_to'],
      'day_starts_at': settings['venue_day_starts_at'],
      'closing_time': settings['closing_time'],
      'switch_day': DemoBackend._ymd(today),
      'override': switch (manualToday) { true => 'on', false => 'off', null => 'auto' },
    };
  }

  Map<String, dynamic> _savePeakTimes(Map<String, dynamic> p) {
    _requireRole({'admin'});
    final weekdays = (p['p_weekdays'] as List).cast<int>();
    if (weekdays.any((d) => d < 1 || d > 7)) throw const PostgrestException(message: 'invalid_weekdays');
    final from = PeakSchedule.parseTime(p['p_from']);
    final to = PeakSchedule.parseTime(p['p_to']);
    if ((from == null) != (to == null)) throw const PostgrestException(message: 'invalid_hours');
    if (from != null && to != null && !venueDay.hoursFit(from, to)) {
      throw const PostgrestException(message: 'peak_hours_after_closing');
    }
    settings
      ..['peak_weekdays'] = weekdays
      ..['peak_from'] = p['p_from']
      ..['peak_to'] = p['p_to'];
    _logSettings({'subject': 'peak_times', 'changes': <String, dynamic>{}});
    return _peakState();
  }

  Map<String, dynamic> _setPeakOverride(String mode) {
    _requireRole({'supervisor', 'admin'});
    settings
      ..['peak_override'] = switch (mode) { 'on' => true, 'off' => false, _ => null }
      ..['peak_override_day'] = mode == 'auto' ? null : DemoBackend._ymd(today);
    _logSettings({'subject': 'peak_override', 'day': DemoBackend._ymd(today), 'changes': {'mode': {'old': null, 'new': mode}}});
    return _peakState();
  }

  // ── Admin: gates and controllers (ADR-0035) ─────────────────────────────────

  Map<String, dynamic> _gatesOverview() {
    _requireRole({'admin'});
    _heartbeat();
    final today = scans.where((s) => !s.scannedAt.isBefore(_dayStart)).toList();
    return {
      'now': DemoBackend._iso(_now),
      'offline_after_seconds': _num('gate_offline_after_seconds'),
      'test_open_timeout_seconds': _num('test_open_timeout_seconds'),
      'controllers': [
        for (final c in controllers)
          () {
            final mine = gates.where((g) => g.controllerId == c.id).toList();
            final seen = [for (final g in mine) ?g.lastSeenAt]..sort();
            final entry = mine.where((g) => g.direction == 'entry' && g.enabled).toList();
            return {
              'id': c.id,
              'name': c.name,
              'model': c.model,
              'ip': c.ip,
              'port': c.port,
              'door_count': c.doorCount,
              'gate_count': mine.length,
              'last_seen_at': seen.isEmpty ? null : DemoBackend._iso(seen.last),
              'status': entry.isEmpty
                  ? 'no_entry_gate'
                  : entry.any((g) => _gateStatus(g) == 'online')
                      ? 'online'
                      : seen.isEmpty
                          ? 'never_seen'
                          : 'offline',
            };
          }(),
      ],
      'gates': [
        for (final g in gates)
          {
            'id': g.id,
            'name': g.name,
            'direction': g.direction,
            'controller_id': g.controllerId,
            'controller_name': controllers.where((c) => c.id == g.controllerId).firstOrNull?.name,
            'door_number': g.doorNumber,
            'open_seconds': g.openSeconds,
            'reader': g.reader,
            'enabled': g.enabled,
            'status': g.direction == 'exit' ? 'exit' : _gateStatus(g),
            'last_seen_at': g.lastSeenAt == null ? null : DemoBackend._iso(g.lastSeenAt!),
            'last_scan_at': _lastScanAt(g.id),
            'entries': today.where((s) => s.gateId == g.id && s.result == 'accepted').length,
            'rejected': today.where((s) => s.gateId == g.id && s.result == 'rejected').length,
            'home_of': [for (final c in counters.where((c) => c.entryGateId == g.id)) c.name],
          },
      ],
    };
  }

  Map<String, dynamic> _saveGate(Map<String, dynamic> p) {
    _requireRole({'admin'});
    final id = p['p_id'] as String?;
    final name = (p['p_name'] as String).trim();
    if (name.isEmpty) throw const PostgrestException(message: 'invalid_name');
    if (gates.any((g) => g.id != id && g.name.toLowerCase() == name.toLowerCase())) {
      throw const PostgrestException(message: 'name_taken');
    }
    final seconds = p['p_open_seconds'] as int;
    if (seconds < 1 || seconds > 30) throw const PostgrestException(message: 'invalid_open_seconds');
    final controllerId = p['p_controller_id'] as String?;
    final door = p['p_door_number'] as int?;
    if ((controllerId == null) != (door == null)) throw const PostgrestException(message: 'invalid_wiring');
    if (controllerId != null) {
      final c = controllers.where((c) => c.id == controllerId).firstOrNull;
      if (c == null) throw const PostgrestException(message: 'controller_not_found');
      if (door! < 1 || door > c.doorCount) throw const PostgrestException(message: 'door_not_on_controller');
      if (gates.any((g) => g.id != id && g.controllerId == controllerId && g.doorNumber == door)) {
        throw const PostgrestException(message: 'door_taken');
      }
    }
    final direction = p['p_direction'] as String;
    if (direction == 'exit' && id != null && counters.any((c) => c.entryGateId == id)) {
      throw const PostgrestException(message: 'home_gate_must_be_entry');
    }
    final g = id == null ? (_Gate(_id('g'), name)..lastSeenAt = null) : _gate(id) ?? (throw const PostgrestException(message: 'not_found'));
    if (id == null) gates.add(g);
    g
      ..name = name
      ..direction = direction
      ..controllerId = controllerId
      ..doorNumber = door
      ..openSeconds = seconds
      ..reader = p['p_reader'] as String?
      ..enabled = p['p_enabled'] as bool;
    _logSettings({'subject': 'gate', 'name': g.name, 'created': id == null, 'changes': <String, dynamic>{}});
    return {'id': g.id};
  }

  Map<String, dynamic> _saveController(Map<String, dynamic> p) {
    _requireRole({'admin'});
    final id = p['p_id'] as String?;
    final name = (p['p_name'] as String).trim();
    if (name.isEmpty) throw const PostgrestException(message: 'invalid_name');
    if (controllers.any((c) => c.id != id && c.name.toLowerCase() == name.toLowerCase())) {
      throw const PostgrestException(message: 'name_taken');
    }
    final ip = p['p_ip'] as String?;
    if (ip != null && !RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(ip)) throw const PostgrestException(message: 'invalid_ip');
    final port = p['p_port'] as int;
    if (port < 1 || port > 65535) throw const PostgrestException(message: 'invalid_port');
    final doors = p['p_door_count'] as int;
    if (doors < 1 || doors > 4) throw const PostgrestException(message: 'invalid_door_count');
    if (id != null && gates.any((g) => g.controllerId == id && (g.doorNumber ?? 0) > doors)) {
      throw const PostgrestException(message: 'doors_in_use');
    }
    final c = id == null
        ? _Controller(_id('ctl'), name, null, null)
        : controllers.where((c) => c.id == id).firstOrNull ?? (throw const PostgrestException(message: 'not_found'));
    if (id == null) controllers.add(c);
    c
      ..name = name
      ..model = p['p_model'] as String?
      ..ip = ip
      ..port = port
      ..doorCount = doors;
    _logSettings({'subject': 'controller', 'name': c.name, 'created': id == null, 'changes': <String, dynamic>{}});
    return {'id': c.id};
  }

  Map<String, dynamic> _testOpen(String gateId) {
    _requireRole({'admin'});
    final g = _gate(gateId) ?? (throw const PostgrestException(message: 'gate_not_found'));
    if (g.direction != 'entry') throw const PostgrestException(message: 'not_entry_gate');
    if (g.controllerId == null) throw const PostgrestException(message: 'gate_not_wired');
    final cmd = _Command(_id('cmd'), gateId, _now);
    commands.add(cmd);
    return {'command_id': cmd.id, 'open_seconds': g.openSeconds, 'timeout_seconds': _num('test_open_timeout_seconds')};
  }

  Map<String, dynamic> _testOpenStatus(String commandId) {
    final cmd = commands.where((c) => c.id == commandId).firstOrNull;
    if (cmd == null) throw const PostgrestException(message: 'command_not_found');
    final age = _now.difference(cmd.createdAt);
    if (age < const Duration(seconds: 2)) return {'result': 'waiting', 'detail': null};
    final g = _gate(cmd.gateId)!;
    final opened = _gateStatus(g) == 'online';
    if (!actions.any((a) => a.details?['command_id'] == cmd.id)) {
      _log('test_open',
          gateId: g.id, shiftId: null, details: {'command_id': cmd.id, 'test_open_result': opened ? 'opened' : 'no_answer'});
    }
    return {'result': opened ? 'opened' : 'no_answer', 'detail': null};
  }

  // ── Admin: users (ADR-0036) ─────────────────────────────────────────────────

  Map<String, dynamic> _usersOverview() {
    _requireRole({'admin'});
    return {
      'now': DemoBackend._iso(_now),
      'staff': [
        for (final s in staff)
          () {
            final mine = shifts.where((x) => x.cashierId == s.id).toList()
              ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
            return {
              'id': s.id,
              'full_name': s.fullName,
              'username': s.username,
              'role': s.role,
              'active': s.active,
              'last_sign_in_at': s.lastSignInAt == null ? null : DemoBackend._iso(s.lastSignInAt!),
              'last_counter_name': mine.isEmpty ? null : _counter(mine.first.counterId)!.name,
              'last_shift_opened_at': mine.isEmpty ? null : DemoBackend._iso(mine.first.openedAt),
              'has_open_shift': mine.any((x) => x.status == 'open'),
            };
          }(),
      ],
    };
  }

  Map<String, dynamic> _saveStaff(Map<String, dynamic> p) {
    _requireRole({'admin'});
    final id = p['p_id'] as String?;
    final name = (p['p_full_name'] as String).trim();
    if (name.isEmpty) throw const PostgrestException(message: 'name_required');
    final username = (p['p_username'] as String).trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9._-]{3,32}$').hasMatch(username)) throw const PostgrestException(message: 'invalid_username');
    if (staff.any((s) => s.id != id && s.username == username)) throw const PostgrestException(message: 'username_taken');
    final role = p['p_role'] as String;
    final active = p['p_active'] as bool;
    if (id == null) {
      final password = p['p_password'] as String? ?? '';
      if (password.length < 8) throw const PostgrestException(message: 'password_too_short');
      if (password.length > 72) throw const PostgrestException(message: 'password_too_long');
      final s = DemoStaff(_id('st'), name, username, role, active: active)..password = password;
      staff.add(s);
      return {'id': s.id};
    }
    final s = _staff(id) ?? (throw const PostgrestException(message: 'not_found'));
    if (id == _userId && (role != s.role || !active)) {
      throw const PostgrestException(message: 'cannot_change_own_account');
    }
    if (!active && shifts.any((x) => x.cashierId == id && x.status == 'open')) {
      throw const PostgrestException(message: 'staff_has_open_shift');
    }
    s
      ..fullName = name
      ..username = username
      ..role = role
      ..active = active;
    return {'id': s.id};
  }

  Object? _resetPassword(String id, String password) {
    _requireRole({'admin'});
    if (password.length < 8) throw const PostgrestException(message: 'password_too_short');
    (_staff(id) ?? (throw const PostgrestException(message: 'not_found'))).password = password;
    return null;
  }

  // ── Admin: settings and counters (ADR-0037) ─────────────────────────────────

  Map<String, dynamic> _settingsOverview() {
    _requireRole({'admin'});
    return {
      'settings': {
        ...settings,
        'timezone': 'Africa/Cairo',
        'updated_at': DemoBackend._iso(_now.subtract(const Duration(days: 3))),
        'updated_by_name': staff.where((s) => s.role == 'admin').firstOrNull?.fullName,
      },
      'peak': {'weekdays': settings['peak_weekdays'], 'from': settings['peak_from'], 'to': settings['peak_to']},
      'counters': [
        for (final c in counters)
          {
            'id': c.id,
            'name': c.name,
            'printer_ip': c.printerIp,
            'printer_port': c.printerPort,
            'paper_width_mm': c.paperWidthMm,
            'entry_gate_id': c.entryGateId,
            'entry_gate_name': _gate(c.entryGateId)?.name,
            'active': c.active,
            'has_open_shift': shifts.any((s) => s.counterId == c.id && s.status == 'open'),
          },
      ],
      'entry_gates': [
        for (final g in gates.where((g) => g.direction == 'entry')) {'id': g.id, 'name': g.name, 'enabled': g.enabled},
      ],
    };
  }

  Map<String, dynamic> _saveSettings(Map changes) {
    _requireRole({'admin'});
    final logged = <String, dynamic>{};
    for (final MapEntry(:key, :value) in changes.entries) {
      if (!settings.containsKey(key)) throw const PostgrestException(message: 'unknown_setting');
      logged[key as String] = {'old': settings[key], 'new': value};
      settings[key] = value;
    }
    _logSettings({'subject': 'settings', 'changes': logged});
    return _settingsOverview();
  }

  Map<String, dynamic> _saveCounter(Map<String, dynamic> p) {
    _requireRole({'admin'});
    final id = p['p_id'] as String?;
    final name = (p['p_name'] as String).trim();
    if (name.isEmpty) throw const PostgrestException(message: 'invalid_name');
    if (counters.any((c) => c.id != id && c.name.toLowerCase() == name.toLowerCase())) {
      throw const PostgrestException(message: 'name_taken');
    }
    final ip = p['p_printer_ip'] as String?;
    if (ip != null && ip.isNotEmpty && !RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(ip)) {
      throw const PostgrestException(message: 'invalid_ip');
    }
    final active = p['p_active'] as bool;
    final gateId = p['p_entry_gate_id'] as String?;
    if (active && gateId == null) throw const PostgrestException(message: 'home_gate_required');
    if (gateId != null && _gate(gateId) == null) throw const PostgrestException(message: 'gate_not_found');
    if (gateId != null && _gate(gateId)!.direction != 'entry') throw const PostgrestException(message: 'home_gate_not_entry');
    final c = id == null ? _Counter(_id('c'), name, ip, gateId) : _counter(id) ?? (throw const PostgrestException(message: 'not_found'));
    if (id != null && !active && shifts.any((s) => s.counterId == id && s.status == 'open')) {
      throw const PostgrestException(message: 'counter_has_open_shift');
    }
    if (id == null) counters.add(c);
    c
      ..name = name
      ..printerIp = ip
      ..printerPort = p['p_printer_port'] as int
      ..paperWidthMm = p['p_paper_width_mm'] as int
      ..entryGateId = gateId
      ..active = active;
    _logSettings({'subject': 'counter', 'name': c.name, 'created': id == null, 'changes': <String, dynamic>{}});
    return {'id': c.id};
  }

  // ── Offline selling (ADR-0015, ADR-0026) ────────────────────────────────────

  Map<String, dynamic> _reserveCodes() {
    final shift = _requireMyShift();
    final counter = _counter(shift.counterId)!;
    final gateId = counter.entryGateId ?? (throw const PostgrestException(message: 'counter_no_home_gate'));
    final expires = venueDay.closingFor(_now);
    pool.removeWhere((c) => c.status == 'reserved' && !c.expiresAt.isAfter(_now));
    final mine = pool.where((c) => c.counterId == counter.id && c.status == 'reserved').toList();
    for (var i = mine.length; i < _num('offline_pool_size'); i++) {
      final code = _PoolCode(_newGateCode(), counter.id, gateId, expires);
      pool.add(code);
      mine.add(code);
    }
    return {
      'counter_id': counter.id,
      'home_gate_id': gateId,
      'home_gate_name': _gate(gateId)!.name,
      'pool_size': _num('offline_pool_size'),
      'codes': [
        for (final c in mine) {'gate_code': c.gateCode, 'expires_at': DemoBackend._iso(c.expiresAt)},
      ],
    };
  }

  Map<String, dynamic> _syncOrders(String shiftId, List incoming) {
    final shift = _shift(shiftId);
    if (shift == null || shift.cashierId != _userId) throw const PostgrestException(message: 'no_open_shift');
    final results = <Map<String, dynamic>>[];
    for (final raw in incoming.cast<Map<String, dynamic>>()) {
      final clientId = raw['client_id'] as String;
      final existing = orders.where((o) => o.clientId == clientId).firstOrNull;
      if (existing != null) {
        results.add({'client_id': clientId, 'result': 'already_synced', 'order_id': existing.id, 'order_number': existing.number});
        continue;
      }
      final soldAt = DateTime.parse(raw['sold_at'] as String).toLocal();
      final lines = (raw['tickets'] as List).cast<Map<String, dynamic>>();
      final lineTypes = [for (final l in lines) _type(l['ticket_type_id'] as String)!];
      final total = lineTypes.fold(0, (s, t) => s + t.price);
      final order = _Order(_id('o'), ++_orderNumber, shift.id, total, soldAt)
        ..status = 'paid'
        ..method = raw['payment_method'] as String
        ..amountReceived = raw['amount_received_piastres'] as int? ?? total
        ..paidAt = soldAt
        ..clientId = clientId;
      orders.add(order);
      for (final (i, l) in lines.indexed) {
        final code = l['gate_code'] as int;
        final reserved = pool.where((c) => c.gateCode == code).firstOrNull;
        reserved?.status = 'sold';
        final type = lineTypes[i];
        // A pool code scanned before its sale arrived counts as that entry.
        final entered = scans.where((s) => s.poolGateCode == code).toList();
        final t = _Ticket(_id('t'), order.id, type.id, type.price, reserved?.homeGateId ?? _counter(shift.counterId)!.entryGateId,
            code, soldAt, _validUntil(type, soldAt), type.entries - entered.length)
          ..status = type.entries - entered.length > 0 ? 'active' : 'used';
        tickets.add(t);
      }
      final tip = raw['tip_piastres'] as int? ?? 0;
      if (tip > 0) tips.add(_Tip(_id('tip'), shift.id, order.id, tip, 'with_order', soldAt));
      results.add({'client_id': clientId, 'result': 'synced', 'order_id': order.id, 'order_number': order.number});
    }
    return {'results': results};
  }

  Map<String, dynamic> _syncActions(String shiftId, List incoming) {
    final results = <Map<String, dynamic>>[];
    for (final raw in incoming.cast<Map<String, dynamic>>()) {
      final clientId = raw['client_id'] as String;
      final order = orders.where((o) => o.clientId == raw['order_id'] || o.id == raw['order_id']).firstOrNull;
      final ticket = tickets.where((t) => t.orderId == order?.id && t.gateCode == raw['gate_code']).firstOrNull;
      final action = raw['action'] as String;
      if (action == 'reprint') ticket?.printCount++;
      _log(action,
          ticketId: ticket?.id,
          orderId: order?.id,
          reason: raw['reason'] as String?,
          reasonText: raw['reason_text'] as String?,
          at: DateTime.parse(raw['at'] as String).toLocal(),
          shiftId: shiftId,
          extraFlags: [action == 'reprint' ? 'offline_reprint' : 'unprinted_ticket']);
      results.add({'client_id': clientId, 'result': 'synced'});
    }
    return {'results': results};
  }
}

/// What the demo bar's gate scanner shows after a scan.
class ScanOutcome {
  const ScanOutcome({required this.accepted, required this.message, this.typeName});

  final bool accepted;
  final String message;
  final String? typeName;
}

/// The gate side: what `validate_ticket` decides when a QR is held to a
/// reader, and what a gate's own controller decides when the server is down.
extension GateScanner on DemoBackend {
  List<(String id, String name)> get entryGates =>
      [for (final g in gates.where((g) => g.direction == 'entry' && g.enabled)) (g.id, g.name)];

  /// Recently sold codes, newest first, for the scanner's quick picks.
  List<(String code, String label)> recentCodes() {
    final live = tickets.where((t) => t.status != 'voided').toList()
      ..sort((a, b) => b.validFrom.compareTo(a.validFrom));
    return [
      for (final t in live.take(8))
        ('${t.gateCode}', '${_type(t.typeId)!.nameEn} · ${t.status == 'pending' ? 'unpaid' : t.status}'),
    ];
  }

  ScanOutcome scan(String code, String gateId) {
    final gate = _gate(gateId)!;
    final n = int.tryParse(code.trim());
    final now = _now;
    ScanOutcome record(String? ticketId, String? reason, {int? poolGateCode}) {
      final accepted = reason == null;
      scans.add(_Scan(_id('scan'), ticketId, gateId, accepted ? 'accepted' : 'rejected', reason, now,
          poolCode: poolGateCode != null, poolGateCode: poolGateCode));
      gate.lastSeenAt = now;
      _scanEvents.add(null);
      _changed();
      final type = _type(_ticket(ticketId)?.typeId);
      return ScanOutcome(
        accepted: accepted,
        message: accepted
            ? 'OPEN · ${gate.name}'
            : 'DENIED · ${switch (reason) {
                'not_paid' => 'not paid yet',
                'voided' => 'voided',
                'used_up' => 'already used',
                'expired' => 'expired',
                'not_yet_valid' => 'not valid yet',
                'gate_disabled' => 'gate disabled',
                'not_home_gate' => 'outage: only its home gate opens',
                _ => 'unknown code',
              }}',
        typeName: type?.nameEn,
      );
    }

    if (!gate.enabled) return record(null, 'gate_disabled');
    final ticket = n == null
        ? null
        : (tickets.where((t) => t.gateCode == n).toList()..sort((a, b) => b.validFrom.compareTo(a.validFrom)))
            .firstOrNull;
    final poolCode = pool.where((c) => c.gateCode == n).firstOrNull;

    // Server down: the gate's own controller holds only its counters' cards.
    if (outage.value) {
      final home = ticket?.homeGateId ?? poolCode?.homeGateId;
      if (home == null) return record(null, 'not_found');
      if (home != gateId) return record(ticket?.id, 'not_home_gate');
      if (ticket == null) {
        if (scans.any((s) => s.poolGateCode == n)) return record(null, 'used_up');
        return record(null, null, poolGateCode: n);
      }
    }

    if (ticket == null) {
      // An unused pool code is accepted once before its sale uploads.
      if (poolCode != null && !scans.any((s) => s.poolGateCode == n)) return record(null, null, poolGateCode: n);
      return record(null, 'not_found');
    }
    final status = _status(ticket);
    final reason = switch (status) {
      'pending' => 'not_paid',
      'voided' => 'voided',
      'expired' => 'expired',
      _ when ticket.validFrom.isAfter(now) => 'not_yet_valid',
      _ when ticket.entriesLeft <= 0 => 'used_up',
      _ => null,
    };
    if (reason != null) return record(ticket.id, reason);
    ticket.entriesLeft--;
    if (ticket.entriesLeft == 0) ticket.status = 'used';
    // A reactivated ticket that then enters through another gate is flagged.
    final reactivation = actions
        .where((a) => a.ticketId == ticket.id && a.action == 'reactivate')
        .fold<_Action?>(null, (last, a) => a);
    if (reactivation != null &&
        reactivation.details?['undone_gate_id'] != gateId &&
        !reactivation.flags.contains('reactivated_other_gate')) {
      reactivation.flags = [...reactivation.flags, 'reactivated_other_gate'];
    }
    return record(ticket.id, null);
  }
}
