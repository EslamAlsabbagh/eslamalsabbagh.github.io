import '../../../l10n/gen/app_localizations.dart';
import '../data/sell_draft.dart';
import '../data/sell_repository.dart';

/// The one message for each way a sell flow call can fail.
String sellFailureMessage(AppLocalizations l10n, SellFailureKind kind) => switch (kind) {
      SellFailureKind.counterNoHomeGate => l10n.sellFailureCounterNoHomeGate,
      SellFailureKind.ticketTypeUnavailable => l10n.sellFailureTypeUnavailable,
      SellFailureKind.ticketTypeNotNow => l10n.sellFailureTypeNotNow,
      SellFailureKind.afterClosingTime => l10n.sellFailureAfterClosing,
      SellFailureKind.gateCodeSpaceExhausted => l10n.sellFailureCodesExhausted,
      SellFailureKind.orderCancelled => l10n.paymentFailureOrderCancelled,
      SellFailureKind.orderNotFound => l10n.paymentFailureOrderNotFound,
      SellFailureKind.orderAlreadyPaid => l10n.paymentFailureAlreadyPaid,
      SellFailureKind.tipNotAllowed => l10n.paymentFailureTipNotAllowed,
      SellFailureKind.invalidAmountReceived => l10n.paymentFailureAmount,
      SellFailureKind.serverUnreachable => l10n.errorServerUnreachable,
      SellFailureKind.offlineDisabled => l10n.sellFailureOfflineDisabled,
      SellFailureKind.offlinePoolEmpty => l10n.sellFailureOfflinePoolEmpty,
      SellFailureKind.offlineZoneMismatch => l10n.sellFailureOfflineZone,
      // The router leaves selling once the shift is reloaded.
      SellFailureKind.noOpenShift || SellFailureKind.unexpected => l10n.errorUnexpected,
    };

/// Why the server refused an offline upload. A bad time isn't a reason any
/// more (ADR-0026), except a time that can't be read.
String offlineRefusalMessage(AppLocalizations l10n, String key) => switch (key) {
      'code_not_in_pool' => l10n.offlineRefusalCodeNotInPool,
      'invalid_sold_at' => l10n.offlineRefusalSoldAt,
      'ticket_type_unavailable' => l10n.offlineRefusalTypeUnavailable,
      _ => l10n.offlineRefusalOther(key),
    };

String paymentMethodName(AppLocalizations l10n, PaymentMethod method) => switch (method) {
      PaymentMethod.cash => l10n.paymentCash,
      PaymentMethod.card => l10n.paymentCard,
      PaymentMethod.wallet => l10n.paymentWallet,
    };
