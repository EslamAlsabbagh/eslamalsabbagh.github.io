// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ticketing System';

  @override
  String get switchLanguage => 'AR';

  @override
  String get switchLanguageHint => 'التبديل إلى العربية';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get backToHome => 'Back to home';

  @override
  String get loginSubtitle => 'Sign in to start your shift';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get forgotPasswordHint =>
      'Forgot your password? Ask a supervisor to reset it.';

  @override
  String get loginErrorMissingFields => 'Enter your username and password.';

  @override
  String get loginErrorInvalidCredentials => 'Wrong username or password.';

  @override
  String get loginErrorAccountInactive =>
      'This account isn\'t active. Ask a supervisor.';

  @override
  String get loginErrorServerUnreachable =>
      'Can\'t reach the server. Check the network and try again.';

  @override
  String get loginErrorSessionEnded =>
      'Your session has ended. Please sign in again.';

  @override
  String get loginErrorUnexpected => 'Something went wrong. Try again.';

  @override
  String get signOut => 'Sign out';

  @override
  String get shiftAreaTitle => 'Cashier';

  @override
  String get adminAreaTitle => 'Admin';

  @override
  String shiftNumberLabel(int number) {
    return 'Shift #$number';
  }

  @override
  String get roleCashier => 'Cashier';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get roleAdmin => 'Admin';

  @override
  String staffWithRole(String name, String role) {
    return '$name · $role';
  }

  @override
  String get errorServerUnreachable =>
      'Can\'t reach the server. Check the network and try again.';

  @override
  String get errorUnexpected => 'Something went wrong. Try again.';

  @override
  String get retry => 'Try again';

  @override
  String get openShiftTitle => 'Open shift';

  @override
  String lastShiftClosedToday(String time) {
    return 'The last shift on this PC closed today at $time.';
  }

  @override
  String lastShiftClosedYesterday(String time) {
    return 'The last shift on this PC closed yesterday at $time.';
  }

  @override
  String lastShiftClosedOn(String date, String time) {
    return 'The last shift on this PC closed on $date at $time.';
  }

  @override
  String get openingFloatTitle => 'Opening float';

  @override
  String get openingFloatHint =>
      'Count the change in the drawer and type the amount. It\'s compared with what you count when you close the shift.';

  @override
  String get openingFloatLabel => 'Amount (EGP)';

  @override
  String printerLabel(String address) {
    return 'Printer · $address';
  }

  @override
  String get printerLabelNone => 'Printer';

  @override
  String get printerNotSet =>
      'No printer is set for this counter. Ask an admin.';

  @override
  String get printerChecking => 'Checking the printer…';

  @override
  String get printerReachable => 'Connected · do a test print before you start';

  @override
  String get printerUnreachable =>
      'The printer isn\'t answering. Check that it\'s on and connected.';

  @override
  String get printerPrinting => 'Printing a test page…';

  @override
  String get printerPrinted => 'Test page printed — the printer works';

  @override
  String get printerPrintFailed =>
      'The test print failed. Check the printer and try again.';

  @override
  String get testPrint => 'Test print';

  @override
  String get checkPrinterAgain => 'Check again';

  @override
  String get openShiftButton => 'Open shift and start selling';

  @override
  String get openShiftNoCounter =>
      'This PC isn\'t set up for a counter. Ask an admin to set up the app.';

  @override
  String get openShiftCounterUnavailable =>
      'This counter doesn\'t exist or is switched off. Ask an admin.';

  @override
  String get openShiftCounterNoHomeGate =>
      'This counter has no gate. Ask an admin.';

  @override
  String openShiftElsewhere(String counter) {
    return 'You have a shift open at $counter. Close it there first.';
  }

  @override
  String get openShiftErrorCounterBusy =>
      'Another shift is open at this counter. It has to be closed first.';

  @override
  String get openShiftErrorInvalidCash => 'Type the opening float.';

  @override
  String moneyAmount(String amount) {
    return 'EGP $amount';
  }

  @override
  String get sellTitle => 'Sell tickets';

  @override
  String sellSubtitle(String counter, int number, String time) {
    return '$counter · Shift #$number · started $time';
  }

  @override
  String get sellHeading => 'Choose ticket type and quantity';

  @override
  String get findTicket => 'Find ticket';

  @override
  String get lastOrder => 'Last order';

  @override
  String get closeShift => 'Close shift';

  @override
  String get printerBadgeReady => 'Printer ready';

  @override
  String get printerBadgeChecking => 'Checking the printer…';

  @override
  String get printerBadgeUnreachable => 'Printer not answering';

  @override
  String get printerBadgeNotSet => 'No printer';

  @override
  String get printerBadgeHint => 'Tap to check the printer again';

  @override
  String get ticketRuleSingleEntry => 'Single entry';

  @override
  String ticketRuleEntries(int count) {
    return 'Up to $count entries';
  }

  @override
  String get ticketRuleValidToday => 'valid today';

  @override
  String ticketRuleValidHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'valid $hours hours',
      one: 'valid 1 hour',
    );
    return '$_temp0';
  }

  @override
  String get increaseQuantity => 'Increase';

  @override
  String get decreaseQuantity => 'Decrease';

  @override
  String get noTicketTypes =>
      'There are no ticket types to sell. Ask an admin.';

  @override
  String get footerShiftOrders => 'Shift orders:';

  @override
  String get footerTicketsSold => 'Tickets sold:';

  @override
  String get footerLastOrder => 'Last order:';

  @override
  String get currentOrder => 'Current order';

  @override
  String get clearOrder => 'Clear order';

  @override
  String get orderEmpty => 'Choose ticket types from the list';

  @override
  String orderLineQuantity(int quantity, String price) {
    return '$quantity × $price';
  }

  @override
  String get paymentMethodLabel => 'Payment method';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCard => 'Card';

  @override
  String get paymentWallet => 'Wallet';

  @override
  String orderTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Total · $count tickets',
      one: 'Total · 1 ticket',
    );
    return '$_temp0';
  }

  @override
  String get printAndCharge => 'Print tickets and charge';

  @override
  String get sellShortcutsHint => 'F12 to print and charge · Esc to clear';

  @override
  String get ticketHeading => 'Entry ticket';

  @override
  String ticketValidOnDay(String date, String time) {
    return 'Valid on $date until $time';
  }

  @override
  String ticketValidUntil(String date, String time) {
    return 'Valid until $date $time';
  }

  @override
  String ticketHomeGate(String gate) {
    return 'Enter at: $gate';
  }

  @override
  String get ticketOrderLabel => 'Order';

  @override
  String ticketOrderValue(String number, String index, String count) {
    return '#$number · $index of $count';
  }

  @override
  String get ticketCounterLabel => 'Counter';

  @override
  String get ticketTimeLabel => 'Time';

  @override
  String get ticketFooter => 'Scan the code at the gate · Keep your ticket';

  @override
  String get testPageTitle => 'Test print';

  @override
  String get testPageNotATicket => 'Sample — not a ticket';

  @override
  String testPagePaper(String width) {
    return 'Paper $width mm';
  }

  @override
  String get testPageSample => 'ABCDEFG abcdefg · 0123456789';

  @override
  String get testPageSampleType => 'Sample';

  @override
  String shiftSubtitle(String counter, int number) {
    return '$counter · Shift #$number';
  }

  @override
  String get sellFailureCounterNoHomeGate =>
      'This counter has no gate. Ask an admin.';

  @override
  String get sellFailureTypeUnavailable =>
      'A ticket type in the order was switched off. The list is updated; check the order.';

  @override
  String get sellFailureAfterClosing =>
      'It is past closing time: same-day tickets can\'t be sold now.';

  @override
  String get sellFailureCodesExhausted =>
      'No free ticket codes left. Ask an admin.';

  @override
  String orderCancelledNotice(int number) {
    return 'Order #$number was cancelled. Take the printed tickets back from the customer.';
  }

  @override
  String paymentTitle(String method) {
    return 'Payment · $method';
  }

  @override
  String get printStatusPrinting => 'Printing the tickets…';

  @override
  String printStatusPrinted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets printed',
      one: '1 ticket printed',
    );
    return '$_temp0';
  }

  @override
  String printStatusFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets didn\'t print',
      one: '1 ticket didn\'t print',
    );
    return '$_temp0';
  }

  @override
  String printStatusCount(int done, int count) {
    return '$done of $count';
  }

  @override
  String get printStatusHint =>
      'Hand the tickets over once you have the money. They won\'t open the gate until payment is confirmed.';

  @override
  String get printStatusFailedHint =>
      'Check the printer (paper, power) and press Try again.';

  @override
  String orderSummary(int number) {
    return 'Order #$number summary';
  }

  @override
  String soldLine(String name, int quantity) {
    return '$name × $quantity';
  }

  @override
  String amountDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Due · $count tickets',
      one: 'Due · 1 ticket',
    );
    return '$_temp0';
  }

  @override
  String get amountReceivedLabel =>
      'Amount received (EGP) · type it or use the keypad';

  @override
  String get exactAmount => 'Exact amount';

  @override
  String get tipTitle => 'Tip from the customer (optional)';

  @override
  String get tipNone => 'None';

  @override
  String get tipTypedHint => 'Amount';

  @override
  String get tipTypedLabel => 'Tip amount in EGP';

  @override
  String get tipTheChange => 'Customer left all the change as a tip';

  @override
  String get changeLabel => 'Change for the customer';

  @override
  String changeAfterTip(String tip) {
    return 'Change after a $tip tip';
  }

  @override
  String get amountShort => 'Amount short';

  @override
  String get keypadClear => 'Clear';

  @override
  String get keypadBackspace => 'Delete a digit';

  @override
  String cardPaymentNote(String amount) {
    return 'Charge $amount on the card machine, then confirm.';
  }

  @override
  String walletPaymentNote(String amount) {
    return 'Receive $amount by wallet, then confirm.';
  }

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelOrderHint =>
      'Customer didn\'t pay · printed tickets are voided';

  @override
  String get confirmPayment => 'Confirm payment';

  @override
  String get paymentShortcutsHint => 'Enter or F12 to confirm payment';

  @override
  String cancelDialogTitle(int number) {
    return 'Cancel order #$number?';
  }

  @override
  String get cancelDialogBody =>
      'The printed tickets will be voided and won\'t open the gate. Take them back from the customer.';

  @override
  String get cancelReasonNotPaid => 'Customer didn\'t pay';

  @override
  String get cancelReasonOther => 'Other reason';

  @override
  String get cancelReasonTextLabel => 'Write the reason';

  @override
  String get cancelReasonTextRequired => 'The reason is required';

  @override
  String get cancelDialogKeep => 'Back';

  @override
  String get paymentFailureOrderCancelled =>
      'This order was cancelled automatically because it stayed unpaid, and its tickets are voided. Take them back and sell again.';

  @override
  String get paymentFailureOrderNotFound =>
      'This order isn\'t in your shift. Go back and sell again.';

  @override
  String get paymentFailureTipNotAllowed =>
      'A tip isn\'t allowed for this payment. Remove the tip and try again.';

  @override
  String get paymentFailureAmount =>
      'The amount received is less than the total.';

  @override
  String get paymentFailureAlreadyPaid => 'This order is already paid.';

  @override
  String get backToSell => 'Back to selling';

  @override
  String get paymentServerUnreachable =>
      'Can\'t reach the server, so the payment isn\'t confirmed. Try again, or go back and sell offline: take back the printed tickets, they won\'t open the gate.';

  @override
  String reviewTitle(int number) {
    return 'Order #$number review';
  }

  @override
  String reviewSubtitle(String counter, int number, String time) {
    return '$counter · Shift #$number · $time';
  }

  @override
  String get reviewPaidTitle => 'Paid · tickets active';

  @override
  String reviewPaidSubtitle(int count, String total, String method) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets printed · $total · $method',
      one: '1 ticket printed · $total · $method',
    );
    return '$_temp0';
  }

  @override
  String get reviewPrintingTitle => 'Paid · printing the tickets…';

  @override
  String get reviewFailedSubtitle =>
      'Payment is confirmed. Check the printer and press Try again.';

  @override
  String get reviewTickets => 'Tickets';

  @override
  String get ticketPrinted => 'Printed';

  @override
  String get ticketPrintFailed => 'Print failed';

  @override
  String get ticketPrinting => 'Printing…';

  @override
  String get ticketWaiting => 'Waiting to print';

  @override
  String get reviewReprintNote =>
      'A reprint is logged with your name and the reason, and shows in the actions log.';

  @override
  String get reprint => 'Reprint';

  @override
  String get newOrder => 'New order';

  @override
  String get reviewShortcutsHint => 'Enter for a new order';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String todayAt(String time) {
    return 'today $time';
  }

  @override
  String get lookupTitle => 'Find ticket';

  @override
  String get lookupCodeLabel =>
      'Scan the ticket with the reader or type the code';

  @override
  String get lookupSearch => 'Search';

  @override
  String get lookupOrder => 'Order';

  @override
  String get lookupSold => 'Sold';

  @override
  String get lookupCashier => 'Cashier';

  @override
  String get lookupValidUntil => 'Valid until';

  @override
  String get lookupEntriesLeft => 'Entries left';

  @override
  String lookupEntriesValue(int left, int allowed) {
    return '$left of $allowed';
  }

  @override
  String get lookupPrintCount => 'Times printed';

  @override
  String get lookupHomeGate => 'Entry gate';

  @override
  String get lookupScansTitle => 'Scans at the gates';

  @override
  String get lookupNoScans =>
      'This ticket hasn\'t been scanned at any gate yet.';

  @override
  String lookupNoteReactivate(String until, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'If the customer scanned but didn\'t pass, you can make the ticket valid again until $until ($minutes minutes left).',
      one:
          'If the customer scanned but didn\'t pass, you can make the ticket valid again until $until (1 minute left).',
    );
    return '$_temp0';
  }

  @override
  String lookupNoteVoided(
    String time,
    String actor,
    String counter,
    String reason,
  ) {
    return 'Voided $time by $actor · $counter · Reason: $reason.';
  }

  @override
  String lookupNoteVoidedAuto(String time) {
    return 'Voided $time automatically: the order stayed unpaid.';
  }

  @override
  String get lookupNoteVoidedPlain =>
      'This ticket is voided and doesn\'t open the gate.';

  @override
  String get lookupNotePending =>
      'The order isn\'t paid yet. The ticket won\'t open the gate until payment is confirmed.';

  @override
  String lookupNoteExpired(String until) {
    return 'The ticket\'s validity ended $until. It can\'t be reprinted or made valid again.';
  }

  @override
  String get statusActiveUnused => 'Valid · not used yet';

  @override
  String get statusActive => 'Valid';

  @override
  String get statusUsed => 'Used';

  @override
  String get statusVoided => 'Voided';

  @override
  String get statusPending => 'Not paid';

  @override
  String get statusExpired => 'Expired';

  @override
  String get scanAccepted => 'Accepted';

  @override
  String scanRejected(String reason) {
    return 'Rejected · $reason';
  }

  @override
  String get scanReasonNotPaid => 'not paid';

  @override
  String get scanReasonVoided => 'voided';

  @override
  String get scanReasonUsedUp => 'already used';

  @override
  String get scanReasonNotYetValid => 'not valid yet';

  @override
  String get scanReasonExpired => 'expired';

  @override
  String get scanReasonGateDisabled => 'gate disabled';

  @override
  String get scanReasonNotFound => 'unknown code';

  @override
  String get actionDialogTitle => 'Ticket action';

  @override
  String actionDialogTicket(String type) {
    return '$type ticket';
  }

  @override
  String actionDialogOrder(int number) {
    return 'Order #$number';
  }

  @override
  String get actionLabel => 'Action';

  @override
  String get actionReactivate => 'Reactivate';

  @override
  String get actionReprint => 'Reprint';

  @override
  String get actionVoidRefund => 'Void & refund';

  @override
  String get actionHelpReactivate =>
      'The ticket gets one entry back. Use it when the customer scanned but didn\'t pass.';

  @override
  String get actionHelpReprint =>
      'A new copy prints with the same code. The old and the new copy are the same ticket, so one entry only.';

  @override
  String get actionHelpVoidRefund =>
      'The ticket is voided and refused at the gate, and the amount comes off your shift.';

  @override
  String actionBlocked(String action, String reason) {
    return '$action: $reason';
  }

  @override
  String actionLimitReactivate(int max, int window) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other:
          'Allowed $max times per ticket, within $window minutes of its last scan.',
      one: 'Allowed once per ticket, within $window minutes of its last scan.',
    );
    return '$_temp0';
  }

  @override
  String get actionLimitReprint =>
      'The print count shows on the ticket and in the log.';

  @override
  String get actionLimitRefundBoth =>
      'Only for a ticket never scanned at a gate, in the shift that sold it.';

  @override
  String get actionLimitRefundBeforeScan =>
      'Only for a ticket never scanned at a gate.';

  @override
  String get actionLimitRefundSameShift => 'Only in the shift that sold it.';

  @override
  String get actionLimitRefundAny => 'For any paid ticket.';

  @override
  String get refundInCash => 'Hand back in cash';

  @override
  String get refundToCard => 'Refund to the card';

  @override
  String get refundToWallet => 'Refund to the wallet';

  @override
  String get actionReasonLabel => 'Reason (required)';

  @override
  String get actionReasonNoteLabel => 'Note (optional)';

  @override
  String get actionReasonTextRequiredLabel => 'Write the reason (required)';

  @override
  String get actionReasonTextRequired => 'The reason is required';

  @override
  String get reasonScannedNotPassed => 'Scanned but didn\'t pass';

  @override
  String get reasonGateDidNotOpen => 'The gate didn\'t open';

  @override
  String get reasonPrintFailed => 'The print was spoiled';

  @override
  String get reasonTicketLost => 'The customer lost the ticket';

  @override
  String get reasonCustomerChangedMind => 'The customer changed their mind';

  @override
  String get reasonWrongTicketType => 'Wrong ticket type';

  @override
  String get reasonOther => 'Other reason';

  @override
  String get reasonUnpaidTimeout => 'Not paid in time';

  @override
  String get actionConfirmReactivate => 'Reactivate';

  @override
  String get actionConfirmReprint => 'Reprint';

  @override
  String actionConfirmVoidRefund(String amount) {
    return 'Void & refund $amount';
  }

  @override
  String get actionFootnote =>
      'The action is logged with your name, the counter, the reason and the time, and shows in the actions log.';

  @override
  String get actionCopyPrinting => 'Reprint logged · printing the copy…';

  @override
  String get actionCopyFailed =>
      'The reprint is logged, but the copy didn\'t print. Check the printer and press Try again.';

  @override
  String get actionCloseCopy => 'Close without printing';

  @override
  String get outcomeReprinted => 'The copy printed, and the reprint is logged.';

  @override
  String get outcomeReprintNotPrinted =>
      'The reprint is logged, but the copy didn\'t print.';

  @override
  String get outcomeReactivated => 'The ticket is valid again for one entry.';

  @override
  String outcomeRefunded(String how, String amount) {
    return 'The ticket is voided. $how: $amount';
  }

  @override
  String get ticketFailureNotFound => 'No ticket has this code.';

  @override
  String get ticketFailureNoOpenShift => 'An action needs an open shift.';

  @override
  String get ticketFailureVoided => 'The ticket is voided.';

  @override
  String get ticketFailureUsed => 'The ticket is used up. Reactivate it first.';

  @override
  String get ticketFailureExpired => 'The ticket has expired.';

  @override
  String get ticketFailureNotScanned =>
      'The ticket hasn\'t entered at any gate.';

  @override
  String get ticketFailureAlreadyReactivated =>
      'Its last scan was already undone.';

  @override
  String get ticketFailureReactivationLimit =>
      'The ticket was reactivated the most times allowed.';

  @override
  String get ticketFailureReactivationWindow =>
      'The time allowed after the last scan has passed.';

  @override
  String get ticketFailureNotPaid =>
      'The order isn\'t paid yet. Cancel the order instead.';

  @override
  String get ticketFailureAlreadyScanned => 'The ticket has already entered.';

  @override
  String get ticketFailureNotSameShift =>
      'The ticket was sold in another shift.';

  @override
  String get ticketCopyLabel => 'Print';

  @override
  String ticketCopyValue(int count) {
    return 'Copy $count';
  }

  @override
  String get ticketRefunded => 'Refunded';

  @override
  String get ticketLeftUnprinted => 'Not printed · logged';

  @override
  String unprintedDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets didn\'t print',
      one: '1 ticket didn\'t print',
    );
    return '$_temp0';
  }

  @override
  String get unprintedDialogBody =>
      'Once you leave the order, nothing can print these again: the code isn\'t on paper. Check the printer and press Try again, or pick a reason and leave.';

  @override
  String get unprintedDialogReason => 'Why leave';

  @override
  String get leaveReasonPrintedAfterAll =>
      'It printed after all and the customer has it';

  @override
  String get leaveReasonCustomerLeft => 'The customer left without it';

  @override
  String get unprintedDialogLogged =>
      'This is logged with your name and the reason, for a supervisor to review.';

  @override
  String get unprintedLeave => 'Leave anyway';

  @override
  String get reviewPaidShortTitle => 'Paid';

  @override
  String reviewPartlyRefundedSubtitle(int active, int refunded) {
    String _temp0 = intl.Intl.pluralLogic(
      active,
      locale: localeName,
      other: '$active tickets active · $refunded voided and refunded',
      one: '1 ticket active · $refunded voided and refunded',
    );
    return '$_temp0';
  }

  @override
  String reviewAllRefundedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All tickets voided',
      two: 'Both tickets voided',
      one: 'The ticket was voided',
    );
    return '$_temp0';
  }

  @override
  String reviewAllRefundedSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets voided and refunded',
      one: 'Refunded to the customer',
    );
    return '$_temp0';
  }

  @override
  String reviewLeftSubtitle(int printed, int left) {
    return '$printed printed · $left not printed (logged)';
  }

  @override
  String retryAllFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Try again for all $count',
      two: 'Try again for both',
      one: 'Try again',
    );
    return '$_temp0';
  }

  @override
  String closeShiftTitle(int number) {
    return 'Close shift #$number';
  }

  @override
  String closeShiftSubtitle(
    String counter,
    String from,
    String to,
    String cashier,
  ) {
    return '$counter · $from to $to · $cashier';
  }

  @override
  String get countHeading => 'Count all the money in the drawer';

  @override
  String get countHint =>
      'Type how many of each note or coin, including the float and tips. Type the number or use + and −.';

  @override
  String denominationLabel(String amount) {
    return '$amount EGP';
  }

  @override
  String denominationCountLabel(String amount) {
    return 'Number of $amount EGP notes';
  }

  @override
  String get countedTotal => 'Total counted';

  @override
  String get tipsHeading => 'Tips';

  @override
  String get tipsHint =>
      'Recorded with orders during the shift. If you forgot to record a tip, add it here before closing.';

  @override
  String get tipsNone => 'No tips recorded in this shift.';

  @override
  String tipWithOrder(int number) {
    return 'With order #$number';
  }

  @override
  String get tipAddedAtClose => 'Added at close';

  @override
  String get addTipHeading => 'Add a forgotten tip';

  @override
  String get addTipTypedLabel => 'Or type the amount (EGP)';

  @override
  String get addTipTypedHint => 'e.g. 35';

  @override
  String addTipButton(String amount) {
    return 'Add $amount';
  }

  @override
  String get addTipButtonEmpty => 'Pick the tip amount';

  @override
  String get addTipNote => 'A tip can\'t be removed once it\'s added.';

  @override
  String tipsTotal(int count) {
    return 'Total tips · $count';
  }

  @override
  String get tipsDisabledNote => 'Tips are switched off in settings.';

  @override
  String get tipFailureInvalid => 'The tip must be more than zero.';

  @override
  String get closeShiftButton => 'Close shift and print the summary';

  @override
  String get closeShiftNote =>
      'After closing, the count and tips can\'t be changed.';

  @override
  String closeAwaitingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders are still awaiting payment',
      one: 'An order is still awaiting payment',
    );
    return '$_temp0';
  }

  @override
  String closeAwaitingBody(int minutes) {
    return 'Confirm or cancel it before closing. If you can\'t see it (for example the app closed on the payment screen), the system cancels it by itself $minutes minutes after the sale, and then you can close.';
  }

  @override
  String get closeCheckAgain => 'Check again';

  @override
  String get closeFailureInvalidCount =>
      'A count isn\'t valid. Check the numbers and try again.';

  @override
  String get closeFailureNoOpenShift =>
      'This shift is already closed. Its summary can\'t be printed from here; a supervisor sees it on the Shifts page.';

  @override
  String closeConfirmTitle(int number) {
    return 'Close shift #$number?';
  }

  @override
  String closeConfirmBody(String amount) {
    return 'Cash counted: $amount. After closing, the count and tips can\'t be changed.';
  }

  @override
  String get closeConfirmZero =>
      'You haven\'t counted any money. Make sure the drawer really is empty.';

  @override
  String get closeConfirmButton => 'Close the shift';

  @override
  String closedTitle(int number) {
    return 'Shift #$number is closed';
  }

  @override
  String get receiptPrinting => 'Printing the summary…';

  @override
  String get receiptPrinted =>
      'The summary is printed. Sign it and hand it to the supervisor with the drawer.';

  @override
  String get receiptPrintFailed =>
      'The summary didn\'t print. Check the printer (paper, power) and press Try again.';

  @override
  String get receiptNoPrinter =>
      'This counter has no printer, so the summary wasn\'t printed. A supervisor sees the shift on the Shifts page.';

  @override
  String get receiptOnlyHere =>
      'The summary prints from here only: once you leave, it can\'t be printed again.';

  @override
  String get closedDone => 'Done, sign out';

  @override
  String get closedLeaveTitle => 'Leave without the printed summary?';

  @override
  String get closedLeaveBody =>
      'It can\'t be printed later. A supervisor sees the shift on the Shifts page.';

  @override
  String get closedLeave => 'Leave anyway';

  @override
  String get receiptTitle => 'Shift close statement';

  @override
  String get receiptShift => 'Shift';

  @override
  String receiptShiftValue(int number, String counter) {
    return '#$number · $counter';
  }

  @override
  String get receiptCashier => 'Cashier';

  @override
  String get receiptFrom => 'From';

  @override
  String get receiptTo => 'To';

  @override
  String get receiptTicketsSold => 'Tickets sold';

  @override
  String receiptTicketsTotal(int orders) {
    String _temp0 = intl.Intl.pluralLogic(
      orders,
      locale: localeName,
      other: 'Total · $orders orders',
      one: 'Total · 1 order',
    );
    return '$_temp0';
  }

  @override
  String get receiptStatement => 'Cashier\'s statement';

  @override
  String get receiptCounted => 'Cash counted';

  @override
  String receiptTips(int count) {
    return 'Of which tips ($count)';
  }

  @override
  String get receiptTipsAtClose => 'Tips added at close';

  @override
  String get receiptReprints => 'Reprints';

  @override
  String get receiptReactivations => 'Reactivations';

  @override
  String get receiptRefunds => 'Voids and refunds';

  @override
  String get receiptCancelledOrders => 'Cancelled orders';

  @override
  String get receiptLeftUnprinted => 'Tickets left unprinted';

  @override
  String get receiptFooter =>
      'The supervisor reconciles it with the expected amount in the system';

  @override
  String get receiptCashierSignature => 'Cashier\'s signature';

  @override
  String get receiptSupervisorSignature => 'Supervisor\'s signature';

  @override
  String get serverBadgeOnline => 'Server connected';

  @override
  String get serverBadgeOffline => 'No server connection';

  @override
  String get serverBadgeChecking => 'Checking the server…';

  @override
  String get offlineBannerTitle =>
      'Working offline: selling only, charge first then print';

  @override
  String get offlineBannerBody =>
      'Orders are kept on this PC and upload by themselves when the server is back.';

  @override
  String offlineFreeCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offline codes left',
      one: '1 offline code left',
    );
    return '$_temp0';
  }

  @override
  String offlineQueuePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders waiting to upload',
      one: '1 order waiting to upload',
    );
    return '$_temp0';
  }

  @override
  String get offlineQueueUploading => 'Uploading offline orders…';

  @override
  String offlineQueueRefused(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders refused',
      one: '1 order refused',
    );
    return '$_temp0';
  }

  @override
  String get offlinePoolUnavailable =>
      'No offline codes for this counter (does it have a gate?). Ask an admin: without them you can\'t sell if the connection drops.';

  @override
  String get offlineRefusedTitle => 'Orders the server refused';

  @override
  String get offlineRefusedBody =>
      'These were sold or logged offline and the server refused their upload. Ask a supervisor: the shift can\'t close until they\'re cleared.';

  @override
  String offlineRefusedRow(int number, String time, String reason) {
    return '#$number offline · $time · $reason';
  }

  @override
  String get offlineRefusalCodeNotInPool =>
      'the code isn\'t from this counter\'s pool';

  @override
  String get offlineRefusalSoldAt =>
      'the sale time doesn\'t fit the shift (is the PC\'s clock right?)';

  @override
  String offlineRefusedActionRow(
    String action,
    String code,
    String time,
    String reason,
  ) {
    return '$action · $code · $time · $reason';
  }

  @override
  String offlineQueueActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logged actions waiting to upload',
      one: '1 logged action waiting to upload',
    );
    return '$_temp0';
  }

  @override
  String closeQueueActionsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logged actions haven\'t uploaded yet',
      one: '1 logged action hasn\'t uploaded yet',
    );
    return '$_temp0';
  }

  @override
  String get offlineRefusalTypeUnavailable => 'unknown ticket type';

  @override
  String offlineRefusalOther(String key) {
    return 'error: $key';
  }

  @override
  String get needsServer => 'Needs the server';

  @override
  String get sellConnectionLost =>
      'The connection to the server dropped. Press Print tickets and charge again to sell offline.';

  @override
  String get sellFailureOfflineDisabled =>
      'Offline selling is turned off in the settings. Wait for the server to come back.';

  @override
  String get sellFailureOfflinePoolEmpty =>
      'Not enough offline codes left for this order. Sell fewer tickets, or wait for the server to come back.';

  @override
  String get sellFailureOfflineZone =>
      'This PC\'s time zone isn\'t the venue\'s, so same-day tickets can\'t be sold offline. Ask an admin to fix the PC\'s time zone.';

  @override
  String orderSummaryOffline(int number) {
    return 'Offline order #$number summary';
  }

  @override
  String get offlinePrintTitle => 'Tickets print after you confirm';

  @override
  String get offlinePrintHint =>
      'We\'re offline: collect the money first. Once you confirm, the tickets print paid and active.';

  @override
  String get offlineBackHint => 'Nothing is recorded yet';

  @override
  String reviewTitleOffline(int number) {
    return 'Offline order #$number review';
  }

  @override
  String get reviewOfflineNote =>
      'Sold offline: the order uploads by itself when the server is back. A reprint is logged and uploads after it. Void & refund needs the server.';

  @override
  String get unprintedDialogOffline =>
      'Saved on this PC with your reason and flagged for a supervisor. It uploads when the server is back.';

  @override
  String ticketOrderValueOffline(String number, String index, String count) {
    return '#$number offline · $index of $count';
  }

  @override
  String closeQueueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offline orders haven\'t uploaded yet',
      one: '1 offline order hasn\'t uploaded yet',
    );
    return '$_temp0';
  }

  @override
  String get closeQueueBody =>
      'The shift can close once they upload. They upload by themselves while the server answers.';

  @override
  String get closeQueueRefusedBody =>
      'The server refused some of them: ask a supervisor. The shift can\'t close until they\'re cleared.';

  @override
  String get uploadNow => 'Upload now';

  @override
  String get adminMenuTitle => 'Admin';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navShifts => 'Shifts';

  @override
  String get navReports => 'Reports';

  @override
  String get navTicketTypes => 'Ticket types & prices';

  @override
  String get navActionsLog => 'Actions log';

  @override
  String get navGates => 'Gates';

  @override
  String get navUsers => 'Users';

  @override
  String get navSettings => 'Settings';

  @override
  String dashboardDateLive(String date) {
    return '$date · updating live';
  }

  @override
  String dashboardDatePolling(String date, int seconds) {
    return '$date · updating every $seconds s';
  }

  @override
  String get dashboardLive => 'Live';

  @override
  String get dashboardNotLive => 'Not live';

  @override
  String get dashboardEntriesToday => 'Entries today';

  @override
  String dashboardSince(String time) {
    return 'since $time';
  }

  @override
  String get dashboardNoEntriesYet => 'No one has entered yet';

  @override
  String get dashboardSalesToday => 'Sales today';

  @override
  String dashboardOpenCounters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count counters open',
      one: '1 counter open',
      zero: 'No counters open',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTicketsSold => 'Tickets sold';

  @override
  String dashboardNotEntered(int count) {
    return '$count not entered yet';
  }

  @override
  String get dashboardRejected => 'Rejected at the gates';

  @override
  String get dashboardNoRejections => 'None today';

  @override
  String dashboardReasonCount(int count, String reason) {
    return '$count $reason';
  }

  @override
  String get gateOnline => 'Online';

  @override
  String get gateOffline => 'Offline';

  @override
  String get gateNeverSeen => 'Never connected';

  @override
  String get gateDisabled => 'Disabled';

  @override
  String get gateEntriesToday => 'Entries today';

  @override
  String get gateRejected => 'Rejected';

  @override
  String gateLastScanSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last scan $count seconds ago',
      one: 'Last scan 1 second ago',
    );
    return '$_temp0';
  }

  @override
  String gateLastScanMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last scan $count minutes ago',
      one: 'Last scan 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String gateLastScanAt(String time) {
    return 'Last scan $time';
  }

  @override
  String get gateNoScans => 'No scans yet';

  @override
  String gateOfflineSince(String time) {
    return 'No connection since $time · check power and network';
  }

  @override
  String get gateNeverSeenNote =>
      'The gate service never connected · check it\'s running';

  @override
  String get gateDisabledNote => 'Switched off on the Gates page';

  @override
  String get dashboardNoGates => 'No entry gates set up';

  @override
  String get dashboardHourlyTitle => 'Entries by hour';

  @override
  String get dashboardHourlyLabel => 'Entries in each hour today';

  @override
  String get dashboardHourlyEmpty => 'No entries yet today';

  @override
  String get dashboardFeedTitle => 'Latest scans';

  @override
  String get dashboardFeedEmpty => 'No scans yet';

  @override
  String get feedAccepted => 'Accepted';

  @override
  String get feedPoolCode => 'offline code';

  @override
  String dashboardStale(String time) {
    return 'Can\'t reach the server. Last updated $time.';
  }

  @override
  String get dashboardUnreachable => 'Can\'t reach the server.';

  @override
  String get dashboardUnexpected =>
      'The dashboard didn\'t load. Try again, and if it keeps failing, call support.';

  @override
  String get dashboardNotAllowed =>
      'This dashboard is for supervisors and admins only.';

  @override
  String get shiftsTitle => 'Shifts & cash reconciliation';

  @override
  String get shiftsSubtitle =>
      'The cashier counts without seeing the expected amount. Reconciliation and approval happen here only.';

  @override
  String get shiftsPeriodToday => 'Today';

  @override
  String get shiftsPeriodYesterday => 'Yesterday';

  @override
  String get shiftsPeriodWeek => 'Last 7 days';

  @override
  String shiftsPeriodPending(int count) {
    return 'Needs approval ($count)';
  }

  @override
  String get shiftsRefresh => 'Refresh';

  @override
  String get shiftsColShift => 'Shift';

  @override
  String get shiftsColCashier => 'Cashier · counter';

  @override
  String get shiftsColExpected => 'Expected';

  @override
  String get shiftsColCounted => 'Counted';

  @override
  String get shiftsColDifference => 'Difference';

  @override
  String get shiftsColStatus => 'Status';

  @override
  String get shiftsEmpty => 'No shifts in this period.';

  @override
  String get shiftsEmptyPending => 'No shifts waiting for approval.';

  @override
  String get shiftsPickOne => 'Pick a shift from the table.';

  @override
  String shiftTitle(int number) {
    return 'Shift #$number';
  }

  @override
  String shiftUntilOpen(String from) {
    return '$from → open';
  }

  @override
  String get shiftStatusOpen => 'Open';

  @override
  String get shiftStatusNeedsApproval => 'To approve';

  @override
  String get shiftStatusApproved => 'Approved';

  @override
  String get shiftOpeningFloat => 'Opening float';

  @override
  String get shiftCashSales => 'Cash sales';

  @override
  String shiftTips(int count) {
    return 'Recorded tips · $count';
  }

  @override
  String get shiftCashRefunds => 'Cash refunds';

  @override
  String get shiftExpected => 'Expected in the drawer';

  @override
  String get shiftCounted => 'Counted by the cashier';

  @override
  String get shiftBalanced => 'Balanced';

  @override
  String get shiftShortage => 'Shortage';

  @override
  String get shiftSurplus => 'Surplus';

  @override
  String shiftNonCash(String card, String wallet) {
    return 'Non-cash (for information): card $card · wallet $wallet';
  }

  @override
  String shiftPaidOrders(int count) {
    return 'Paid orders (all methods): $count';
  }

  @override
  String shiftActions(int count) {
    return 'Shift actions in the log: $count';
  }

  @override
  String shiftActionsFlagged(int count, int flagged) {
    return 'Shift actions in the log: $count ($flagged flagged for review)';
  }

  @override
  String get shiftOpenNote =>
      'The shift is still open. Reconciliation shows once the cashier closes it and counts.';

  @override
  String shiftApprovedBy(String name, String time) {
    return 'Approved by $name · $time';
  }

  @override
  String shiftApprovalComment(String comment) {
    return 'Comment: $comment';
  }

  @override
  String get shiftNoteOptional => 'Note (optional)';

  @override
  String get shiftNoteRequired => 'Comment on the difference (required)';

  @override
  String get shiftApprove => 'Approve shift';

  @override
  String get shiftOwnShift =>
      'This is your own shift, so you can\'t approve it. Another supervisor or admin has to.';

  @override
  String shiftApprovedDone(int number) {
    return 'Shift #$number approved.';
  }

  @override
  String shiftOfflineOrders(int count) {
    return 'Offline orders uploaded: $count';
  }

  @override
  String shiftUnsyncedEntries(int count) {
    return 'Offline codes that entered before their sale uploaded: $count';
  }

  @override
  String shiftRefusedOrders(int count) {
    return 'Offline orders the server refused: $count. Their cash is in the drawer but not in the figures, so it shows in the difference.';
  }

  @override
  String get refusalsTitle => 'Refused at upload';

  @override
  String get refusalKindOrder => 'Offline order';

  @override
  String get refusalKindAction => 'Offline action';

  @override
  String refusalReportedAt(String time) {
    return 'Reported $time';
  }

  @override
  String refusalOrderSummary(String time, String method, String tickets) {
    return 'Sold $time · $method · $tickets';
  }

  @override
  String refusalTicketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets',
      one: '1 ticket',
    );
    return '$_temp0';
  }

  @override
  String get refusalUnknownType => 'unknown type';

  @override
  String refusalTip(String amount) {
    return 'tip $amount';
  }

  @override
  String get refusalLeftUnprinted => 'Ticket left unprinted';

  @override
  String get refusalOpen =>
      'Open: the cashier can\'t close the shift until it is cleared.';

  @override
  String get refusalAccepted => 'Uploaded later.';

  @override
  String refusalCleared(String name, String time, String comment) {
    return 'Cleared by $name · $time: $comment';
  }

  @override
  String get refusalClear => 'Clear';

  @override
  String get refusalOwnShift =>
      'This is your own shift, so you can\'t clear it.';

  @override
  String get refusalClearTitle => 'Clear the refusal';

  @override
  String get refusalClearBody =>
      'Write what you did. What was sent won\'t upload, and a refused order\'s cash stays in the shift\'s difference.';

  @override
  String get refusalCommentLabel => 'Comment (required)';

  @override
  String get orphansTitle => 'Entries with no shift';

  @override
  String get orphansHint =>
      'Offline codes that entered while their counter had no open shift. They count on no shift, and no sale will come for them.';

  @override
  String get shiftsNotAllowed =>
      'This page is for supervisors and admins only.';

  @override
  String get shiftsUnexpected =>
      'The shifts didn\'t load. Try again, and if it keeps failing, call support.';

  @override
  String get shiftDetailFailed => 'The shift\'s details didn\'t load.';

  @override
  String get shiftFailureCommentRequired => 'A comment is required.';

  @override
  String get shiftFailureOwnShift =>
      'You can\'t approve or clear anything on your own shift.';

  @override
  String get shiftFailureAlreadyApproved => 'This shift was already approved.';

  @override
  String get shiftFailureNotClosed => 'The shift is still open.';

  @override
  String get shiftFailureRefusalClosed => 'This refusal was already closed.';

  @override
  String get shiftFailureNotFound => 'This shift wasn\'t found.';

  @override
  String get actionsSubtitle =>
      'Reprints, reactivations and refunds cashiers did without approval';

  @override
  String get actionsExport => 'Export CSV';

  @override
  String get actionsRefresh => 'Refresh';

  @override
  String get actionsTileReview => 'Needs review';

  @override
  String get actionsShow => 'Show';

  @override
  String actionsPeriodReview(int count) {
    return 'Needs review ($count)';
  }

  @override
  String actionsShiftChip(int number, String cashier, String counter) {
    return 'Shift #$number · $cashier · $counter';
  }

  @override
  String get actionsShiftClear => 'All shifts';

  @override
  String get actionsTypeAll => 'All';

  @override
  String get actionsTypeOffline => 'Offline';

  @override
  String get actionsAllCashiers => 'All cashiers';

  @override
  String get actionsAllCounters => 'All counters';

  @override
  String get actionsColTime => 'Time';

  @override
  String get actionsColWho => 'Cashier · counter';

  @override
  String get actionsColAction => 'Action';

  @override
  String get actionsColTicket => 'Ticket';

  @override
  String get actionsColReason => 'Reason';

  @override
  String get actionsColReview => 'Review';

  @override
  String get actionCancelOrder => 'Order cancel';

  @override
  String get actionLeftUnprinted => 'Left unprinted';

  @override
  String get actionOfflineAdjusted => 'Offline time adjusted';

  @override
  String get actionTestOpen => 'Test open';

  @override
  String get actionSettingsChange => 'Settings change';

  @override
  String get actionsSystem => 'System';

  @override
  String actionsCopy(int number) {
    return 'copy $number';
  }

  @override
  String actionsUndoneGate(String gate) {
    return 'The undone scan was at $gate';
  }

  @override
  String actionsOtherReason(String text) {
    return 'Other reason: \"$text\"';
  }

  @override
  String actionsReasonNote(String text) {
    return 'Note: $text';
  }

  @override
  String actionsOfflineTimes(String claimed, String stored) {
    return 'PC time $claimed → stored $stored';
  }

  @override
  String get adjustClockOutOfRange => 'PC clock outside the shift';

  @override
  String get adjustAfterClosing => 'after closing time';

  @override
  String get adjustCodeExpired => 'the code had expired';

  @override
  String get flagOtherReason => 'Other reason';

  @override
  String flagTooManyActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions by the cashier this shift',
      one: '1 action by the cashier this shift',
    );
    return '$_temp0';
  }

  @override
  String flagTooManyPrints(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'printed more than $max times',
      two: 'printed more than twice',
      one: 'printed more than once',
    );
    return '$_temp0';
  }

  @override
  String get flagReactivatedOtherGate => 'scanned later at another gate';

  @override
  String get flagUnprintedTicket => 'never printed';

  @override
  String get flagOfflineTimeAdjusted => 'sale time adjusted';

  @override
  String get flagOfflineReprint => 'reprinted offline';

  @override
  String get actionsReviewButton => 'Mark reviewed';

  @override
  String actionsReviewedBy(String name) {
    return 'Reviewed · $name';
  }

  @override
  String get actionsOwnAction => 'Your own action: someone else reviews it';

  @override
  String get actionsRulesTitle => 'When an action is flagged for review';

  @override
  String get ruleOtherReason => 'The reason is \"Other reason\"';

  @override
  String ruleTooManyActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'More than $count actions by one cashier in a shift',
      one: 'More than 1 action by one cashier in a shift',
    );
    return '$_temp0';
  }

  @override
  String get ruleReactivatedOtherGate =>
      'A reactivated ticket later scanned at another gate';

  @override
  String ruleTooManyPrints(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'A ticket printed more than $max times',
      two: 'A ticket printed more than twice',
      one: 'A ticket printed more than once',
    );
    return '$_temp0';
  }

  @override
  String get ruleUnprinted => 'Always: a ticket left unprinted';

  @override
  String get ruleOffline =>
      'Always: an offline sale whose time was adjusted, or a reprint made offline';

  @override
  String get actionsRulesFootnote =>
      'These rules are settings you can change on the Settings page.';

  @override
  String get actionsEmpty => 'No actions in this period.';

  @override
  String get actionsEmptyReview => 'Nothing needs review.';

  @override
  String actionsTruncated(int shown, int total) {
    return 'Showing the newest $shown of $total. Narrow it by cashier or counter, or export CSV for all of them.';
  }

  @override
  String get actionsNotAllowed =>
      'This page is for supervisors and admins only.';

  @override
  String get actionsUnexpected => 'Something went wrong loading the log.';

  @override
  String get actionsFailureOwnAction => 'You can\'t review your own action.';

  @override
  String get actionsFailureAlreadyReviewed =>
      'This action was already reviewed.';

  @override
  String get actionsFailureNotFlagged => 'This action isn\'t flagged.';

  @override
  String get actionsFailureNotFound => 'This action wasn\'t found.';

  @override
  String actionsExported(String path) {
    return 'Saved: $path';
  }

  @override
  String get actionsOpenFolder => 'Open folder';

  @override
  String get actionsExportNoFolder =>
      'No Downloads folder was found on this PC.';

  @override
  String get actionsExportFailed => 'The file wasn\'t saved.';

  @override
  String get csvTime => 'Time';

  @override
  String get csvCashier => 'Cashier';

  @override
  String get csvCounter => 'Counter';

  @override
  String get csvShift => 'Shift';

  @override
  String get csvAction => 'Action';

  @override
  String get csvOrder => 'Order';

  @override
  String get csvType => 'Ticket type';

  @override
  String get csvCode => 'Code (last 3 digits)';

  @override
  String get csvCopy => 'Copy';

  @override
  String get csvAmount => 'Amount (EGP)';

  @override
  String get csvMethod => 'Payment method';

  @override
  String get csvReason => 'Reason';

  @override
  String get csvReasonText => 'Reason text';

  @override
  String get csvDetails => 'Details';

  @override
  String get csvFlags => 'Review flags';

  @override
  String get csvReviewedBy => 'Reviewed by';

  @override
  String get csvReviewedAt => 'Reviewed at';

  @override
  String get reportsTitle => 'Sales report';

  @override
  String get reportsSubtitle =>
      'Net = sales − refunds + tips. Refunds and tips count on their own day; a tip has no ticket type.';

  @override
  String get reportsPeriod => 'Period';

  @override
  String get reportsGroupBy => 'Group by';

  @override
  String get reportsPeriodMonth => 'This month';

  @override
  String get reportsPeriodLastMonth => 'Last month';

  @override
  String get reportsPeriodRange => 'Pick dates…';

  @override
  String get reportsRangeHelp => 'Pick the first and last day';

  @override
  String get reportsGroupType => 'Ticket type';

  @override
  String get reportsGroupCashier => 'Cashier';

  @override
  String get reportsGroupMethod => 'Payment method';

  @override
  String get reportsGroupDay => 'Day';

  @override
  String get reportsTileSales => 'Total sales';

  @override
  String get reportsTileRefunds => 'Refunds';

  @override
  String get reportsTileNet => 'Net';

  @override
  String get reportsTileTickets => 'Tickets';

  @override
  String get reportsColTickets => 'Total tickets';

  @override
  String get reportsColCounterGate => 'Counter · gate';

  @override
  String get reportsGroupGate => 'Gate';

  @override
  String get reportsColCounters => 'Counters';

  @override
  String get reportsNoGate => 'No gate';

  @override
  String get reportsColSales => 'Sales (EGP)';

  @override
  String get reportsColRefunds => 'Refunds (EGP)';

  @override
  String get reportsColNet => 'Net (EGP)';

  @override
  String get reportsColShare => 'Share of sales';

  @override
  String get reportsTotal => 'Total';

  @override
  String reportsRefundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets',
      one: '1 ticket',
    );
    return '$_temp0';
  }

  @override
  String get reportsEmpty => 'No sales or refunds in this period.';

  @override
  String get reportsLoading =>
      'Working out the report… long periods take a while.';

  @override
  String get reportsNotAllowed =>
      'Reports are for supervisors and admins only.';

  @override
  String get reportsInvalidRange =>
      'That date range isn\'t valid. Pick a first day before the last.';

  @override
  String get reportsBusy =>
      'Another report is running. Wait a moment and try again.';

  @override
  String get reportsUnexpected => 'Something went wrong with the report.';

  @override
  String get reportsCsvSales => 'Sales (EGP)';

  @override
  String get reportsCsvRefundCount => 'Refunded tickets';

  @override
  String get reportsCsvRefunds => 'Refunds (EGP)';

  @override
  String get reportsCsvNet => 'Net (EGP)';

  @override
  String get reportsCsvShare => 'Share of sales (%)';

  @override
  String get reportsRangeFrom => 'From';

  @override
  String get reportsRangeTo => 'To';

  @override
  String reportsRangeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get reportsRangeApply => 'Show report';

  @override
  String get reportsTooSlow =>
      'The report took too long and was stopped. Pick a shorter period.';

  @override
  String get reportsTileTips => 'Tips';

  @override
  String get reportsColTips => 'Tips (EGP)';

  @override
  String get reportsCsvTips => 'Tips (EGP)';

  @override
  String get typesNew => 'New type';

  @override
  String get typesColType => 'Type';

  @override
  String get typesColPrice => 'Price';

  @override
  String get typesColEntries => 'Entries';

  @override
  String get typesColValidity => 'Validity';

  @override
  String get typesColStatus => 'Status';

  @override
  String get typesColOrder => 'Order';

  @override
  String typesEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'Once',
    );
    return '$_temp0';
  }

  @override
  String get typesValiditySameDay => 'Day of sale';

  @override
  String typesValidityHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours from sale',
      one: '1 hour from sale',
    );
    return '$_temp0';
  }

  @override
  String get typesStatusActive => 'On sale';

  @override
  String get typesStatusInactive => 'Off sale';

  @override
  String get typesMoveUp => 'Move up';

  @override
  String get typesMoveDown => 'Move down';

  @override
  String typesEditTitle(String name) {
    return 'Edit: $name';
  }

  @override
  String get typesNameAr => 'Arabic name';

  @override
  String get typesNameEn => 'English name';

  @override
  String get typesPrice => 'Price (EGP)';

  @override
  String get typesEntriesLabel => 'Entries';

  @override
  String get typesValidityLabel => 'Validity';

  @override
  String get typesValidityOptionSameDay => 'Day of sale, until closing';

  @override
  String get typesValidityOptionHours => 'Hours from the time of sale';

  @override
  String get typesHoursLabel => 'Hours';

  @override
  String get typesActiveLabel => 'On sale';

  @override
  String get typesActiveNote =>
      'When off, it\'s hidden from the cashier\'s screen';

  @override
  String get typesPriceNote =>
      'A price change applies to new sales only. Tickets already sold keep their price.';

  @override
  String get typesLogNote => 'Every change is recorded in the actions log.';

  @override
  String get typesSave => 'Save changes';

  @override
  String get typesAdd => 'Add type';

  @override
  String get typesSaved => 'Saved.';

  @override
  String get typesLoading => 'Loading ticket types…';

  @override
  String get typesEmpty => 'No ticket types yet. Add the first one.';

  @override
  String get typesInvalidName => 'Type the Arabic and English names.';

  @override
  String get typesInvalidPrice => 'Type a valid price, e.g. 100 or 12.50.';

  @override
  String get typesInvalidEntries => 'Entries must be 1 or more.';

  @override
  String get typesInvalidHours => 'Hours must be 1 or more.';

  @override
  String get typesNameTaken => 'Another type has this name.';

  @override
  String get typesNotFound =>
      'This type no longer exists. The list was refreshed.';

  @override
  String get typesNotAllowed => 'Ticket types and prices are for admins only.';

  @override
  String get typesUnexpected =>
      'Something unexpected went wrong with the ticket types.';

  @override
  String get actionsTypeSettings => 'Settings';

  @override
  String changeNewType(String name) {
    return 'New type: $name';
  }

  @override
  String changeTypeName(String name) {
    return 'Ticket type $name';
  }

  @override
  String changeField(String field, String from, String to) {
    return '$field: $from → $to';
  }

  @override
  String get sellFailureTypeNotNow =>
      'That type isn\'t on sale right now. The list was refreshed; check the order.';

  @override
  String get sellPeakChip => 'Peak time';

  @override
  String get sellNothingOnSale =>
      'No ticket type is on sale right now. Ask a supervisor.';

  @override
  String get sellPeriodChanged =>
      'The sale period changed; a type no longer on sale was taken out of the order.';

  @override
  String get typesSalePeriodLabel => 'When it\'s sold';

  @override
  String get typesSaleAlways => 'Always';

  @override
  String get typesSaleOffPeak => 'Outside peak only';

  @override
  String get typesSalePeak => 'During peak only';

  @override
  String get typesColSale => 'Sold';

  @override
  String get typesNoPeakType =>
      'No type is on sale during peak: the cashier will have nothing to sell.';

  @override
  String get typesNoOffPeakType =>
      'No type is on sale outside peak: the cashier will have nothing to sell.';

  @override
  String get typesInvalidWeekdays => 'Pick valid days.';

  @override
  String get peakTitle => 'Peak time';

  @override
  String peakNowOn(String reason) {
    return 'Peak now: yes · $reason';
  }

  @override
  String peakNowOff(String reason) {
    return 'Peak now: no · $reason';
  }

  @override
  String get peakSourceManualOn => 'switched on for today';

  @override
  String get peakSourceManualOff => 'switched off for today';

  @override
  String get peakSourceWeekend => 'a peak day';

  @override
  String get peakSourceHours => 'peak hours';

  @override
  String get peakSourceNone => 'normal time';

  @override
  String get peakModeAuto => 'Automatic';

  @override
  String get peakModeOn => 'Peak today';

  @override
  String get peakModeOff => 'Normal today';

  @override
  String get peakModeHelp =>
      'The switch goes back to automatic by itself tomorrow. Connected counters see the change within seconds.';

  @override
  String get peakWeekdaysLabel => 'Peak all day on';

  @override
  String get peakHoursLabel => 'Peak hours on the other days';

  @override
  String get peakFrom => 'From';

  @override
  String get peakTo => 'To';

  @override
  String get peakInvalidHours =>
      'The start must come before the end within one venue day.';

  @override
  String get peakSave => 'Save peak times';

  @override
  String get peakSaved => 'Peak times saved.';

  @override
  String get peakSwitched => 'Peak changed.';

  @override
  String get peakNoDays => 'No day';

  @override
  String get changePeakTimes => 'Peak times';

  @override
  String changePeakOverride(String day) {
    return 'Peak switch for $day';
  }

  @override
  String get changePeakMode => 'Mode';

  @override
  String get peakNoHours => 'No peak hours on the other days.';

  @override
  String get peakPickHour => 'Hour';

  @override
  String get peakPickMinute => 'Minutes';

  @override
  String get gatesSubtitle =>
      'Each gate is wired to a door of an access controller';

  @override
  String get gatesNew => 'New gate';

  @override
  String get gatesLoading => 'Loading gates…';

  @override
  String get gatesControllersTitle => 'Controllers and gate services';

  @override
  String gatesServicesLine(int online, int total) {
    return 'Gate service running at $online of $total entry gates';
  }

  @override
  String get gatesAddController => 'Add controller';

  @override
  String get gatesNoControllers => 'No controllers yet';

  @override
  String controllerDoors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doors',
      one: '1 door',
    );
    return '$_temp0';
  }

  @override
  String get controllerOnline => 'Connected';

  @override
  String controllerOfflineSince(String time) {
    return 'Not connected since $time';
  }

  @override
  String get controllerNeverSeen => 'Never connected';

  @override
  String get controllerNoEntryGate => 'No entry gate';

  @override
  String get controllerNoIp => 'No IP';

  @override
  String get gatesColGate => 'Gate';

  @override
  String get gatesColDirection => 'Direction';

  @override
  String get gatesColWiring => 'Wiring';

  @override
  String get gatesColToday => 'Today';

  @override
  String get gatesColStatus => 'Status';

  @override
  String get gatesEmpty => 'No gates yet';

  @override
  String get gateDirectionEntry => 'Entry';

  @override
  String get gateDirectionExit => 'Exit';

  @override
  String gatesWiring(String controller, int door) {
    return '$controller · door $door';
  }

  @override
  String get gatesNotWired => 'Not wired';

  @override
  String gatesToday(int entries, int rejected) {
    return '$entries in · $rejected refused';
  }

  @override
  String get gateStatusExit => 'Free exit';

  @override
  String get gateExitNote => 'Free exit, no scanning';

  @override
  String gatesEditTitle(String name) {
    return '$name settings';
  }

  @override
  String get gatesName => 'Name';

  @override
  String get gatesDirectionLabel => 'Direction';

  @override
  String get gatesController => 'Controller';

  @override
  String get gatesDoor => 'Door number';

  @override
  String get gatesOpenSeconds => 'Open time (seconds)';

  @override
  String get gatesReader => 'Reader';

  @override
  String get gatesEnabledLabel => 'Gate enabled';

  @override
  String get gatesEnabledNote => 'When off, every scan at it is refused';

  @override
  String get gatesTestOpen => 'Test open';

  @override
  String get gatesAdd => 'Add gate';

  @override
  String get gatesSave => 'Save';

  @override
  String gatesHomeGateNote(String counters) {
    return 'Home gate of $counters: during an outage their tickets open only this gate, so it must stay an entry gate.';
  }

  @override
  String get gatesExitStopsService =>
      'Its gate service stops if the gate becomes an exit gate.';

  @override
  String get gatesTestOpenExit =>
      'No gate service runs at an exit gate, so it can\'t be test opened.';

  @override
  String get gatesTestOpenNotWired => 'The gate isn\'t wired to a controller.';

  @override
  String get gatesTestSending => 'Sending the open command…';

  @override
  String gatesTestWaiting(int seconds) {
    return 'Open command sent for $seconds s · waiting for the gate service…';
  }

  @override
  String gatesTestOpened(int seconds) {
    return 'The gate opened for $seconds s · recorded in the actions log under your name.';
  }

  @override
  String gatesTestFailed(String detail) {
    return 'The gate service couldn\'t open it: $detail';
  }

  @override
  String get gatesTestNoAnswer =>
      'The gate service didn\'t answer · check it\'s running. The request is in the actions log.';

  @override
  String get gatesNotAllowed => 'Gates are for admins only.';

  @override
  String get gatesInvalidName => 'Enter a name.';

  @override
  String get gatesNameTaken => 'That name is taken.';

  @override
  String get gatesInvalidOpenSeconds => '1 to 10 seconds.';

  @override
  String get gatesInvalidWiring => 'Pick the controller and the door together.';

  @override
  String get gatesControllerNotFound => 'That controller no longer exists.';

  @override
  String get gatesDoorNotOnController => 'The controller has no such door.';

  @override
  String get gatesDoorTaken => 'That door is wired to another gate.';

  @override
  String get gatesHomeGateMustBeEntry =>
      'It\'s a counter\'s home gate, so it must stay an entry gate.';

  @override
  String get gatesInvalidIp => 'Enter one device\'s IP, like 10.20.0.51.';

  @override
  String get gatesInvalidPort => 'Port 1 to 65535.';

  @override
  String get gatesInvalidDoorCount => '1 to 4 doors.';

  @override
  String get gatesDoorsInUse => 'A gate is wired to a door above that number.';

  @override
  String get gatesNotFound =>
      'It was changed elsewhere. The list was refreshed.';

  @override
  String get gatesTestOpenPending =>
      'A test open is already waiting for this gate.';

  @override
  String get gatesUnexpected =>
      'Something unexpected went wrong with the gates.';

  @override
  String get controllerNew => 'New controller';

  @override
  String controllerEditTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get controllerModel => 'Model';

  @override
  String get controllerIp => 'IP';

  @override
  String get controllerPort => 'Port';

  @override
  String get controllerDoorsLabel => 'Doors';

  @override
  String get testOpenResultWaiting => 'Waiting';

  @override
  String get testOpenResultOpened => 'Opened';

  @override
  String get testOpenResultFailed => 'Didn\'t open';

  @override
  String get testOpenResultNoAnswer => 'No answer from the gate service';

  @override
  String changeNewGate(String name) {
    return 'New gate: $name';
  }

  @override
  String changeGateName(String name) {
    return 'Gate $name';
  }

  @override
  String changeNewController(String name) {
    return 'New controller: $name';
  }

  @override
  String changeControllerName(String name) {
    return 'Controller $name';
  }

  @override
  String gatesSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String gatesOpenFor(int seconds) {
    return 'opens $seconds s';
  }

  @override
  String get gatesStateOn => 'Enabled';

  @override
  String get usersSubtitle =>
      'Who signs in and what they can do. Nobody is deleted, only deactivated.';

  @override
  String get usersNew => 'New user';

  @override
  String get usersLoading => 'Loading users…';

  @override
  String get usersEmpty => 'No users.';

  @override
  String get usersColName => 'Name';

  @override
  String get usersColRole => 'Role';

  @override
  String get usersColLastSignIn => 'Last sign-in';

  @override
  String get usersColStatus => 'Status';

  @override
  String get usersStatusActive => 'Active';

  @override
  String get usersStatusInactive => 'Deactivated';

  @override
  String get usersNeverSignedIn => 'Never';

  @override
  String usersEditTitle(String name) {
    return 'Edit: $name';
  }

  @override
  String get usersName => 'Name';

  @override
  String get usersUsername => 'Username';

  @override
  String get usersUsernameHint => 'Lowercase letters, digits and . _ -';

  @override
  String get usersRole => 'Role';

  @override
  String get usersPermissionsTitle => 'Can do';

  @override
  String get usersPermSell => 'Sell, take payment and close their shift';

  @override
  String get usersPermActions => 'Reprint, reactivate and void (logged)';

  @override
  String get usersPermShifts => 'Reconcile and approve shifts';

  @override
  String get usersPermLog => 'Review the actions log and reports';

  @override
  String get usersPermCatalog => 'Prices, ticket types and gates';

  @override
  String get usersPermUsers => 'Users and settings';

  @override
  String get usersActiveLabel => 'Account active';

  @override
  String get usersActiveNote => 'Deactivating keeps the user and their history';

  @override
  String get usersPassword => 'Password';

  @override
  String get usersPasswordConfirm => 'Confirm password';

  @override
  String usersPasswordHint(int min) {
    return 'At least $min characters';
  }

  @override
  String get usersPasswordMismatch => 'The passwords don\'t match.';

  @override
  String get usersShowPassword => 'Show password';

  @override
  String get usersHidePassword => 'Hide password';

  @override
  String get usersResetPassword => 'Reset password';

  @override
  String usersResetTitle(String name) {
    return 'New password for $name';
  }

  @override
  String get usersResetNote =>
      'Tell them the new password. They are signed out everywhere and sign in again with it.';

  @override
  String get usersResetConfirm => 'Set password';

  @override
  String get usersResetDone => 'Password changed. They sign in again with it.';

  @override
  String get usersSave => 'Save';

  @override
  String get usersAdd => 'Add user';

  @override
  String get usersAdded =>
      'Added. They sign in with the username and password.';

  @override
  String get usersSelfNote =>
      'This is your account: another admin changes its role and active.';

  @override
  String get usersOpenShiftNote =>
      'Has an open shift. It must close before the account can be deactivated.';

  @override
  String get usersRoleSessionsNote =>
      'A role change or deactivation signs them out; they sign in again.';

  @override
  String get usersNotAllowed => 'Users are for admins only.';

  @override
  String get usersNameRequired => 'Enter a name.';

  @override
  String get usersInvalidUsername =>
      'Username: 3 to 32 lowercase letters, digits and . _ -';

  @override
  String get usersUsernameTaken => 'That username is taken.';

  @override
  String usersPasswordTooShort(int min) {
    return 'The password needs at least $min characters.';
  }

  @override
  String get usersPasswordTooLong => 'That password is too long.';

  @override
  String get usersCannotChangeOwn =>
      'You can\'t change your own role or deactivate yourself. Another admin can.';

  @override
  String get usersHasOpenShift => 'They have an open shift. Close it first.';

  @override
  String get usersNotFound =>
      'It was changed elsewhere. The list was refreshed.';

  @override
  String get usersUnexpected =>
      'Something unexpected went wrong with the users.';

  @override
  String changeNewUser(String name) {
    return 'New user: $name';
  }

  @override
  String changeUserName(String name) {
    return 'User $name';
  }

  @override
  String get changePasswordReset => 'Password reset';

  @override
  String get settingsLoading => 'Loading the settings…';

  @override
  String get settingsLogNote =>
      'Every change is logged under your name in the actions log';

  @override
  String get settingsNotAllowed => 'Settings are for admins only.';

  @override
  String get settingsUnexpected =>
      'Something unexpected went wrong with the settings.';

  @override
  String get settingsInvalidValue => 'That value isn\'t accepted.';

  @override
  String get settingsRequired => 'Enter a value.';

  @override
  String settingsOutOfRange(int min, int max) {
    return 'A number from $min to $max.';
  }

  @override
  String get settingsInvalidList =>
      'Enter amounts separated by commas, like 5, 10, 20.';

  @override
  String settingsTooManyAmounts(int count) {
    return 'At most $count amounts.';
  }

  @override
  String get settingsAmountTooBig => 'Each amount up to EGP 100,000.';

  @override
  String get settingsDuplicateAmount => 'A denomination is listed twice.';

  @override
  String get settingsNeedOneDenomination => 'Enter at least one denomination.';

  @override
  String get settingsVenueSection => 'Venue';

  @override
  String get settingsVenueName => 'Venue name (printed on the ticket)';

  @override
  String get settingsClosingTime => 'Closing time';

  @override
  String get settingsClosingNote =>
      'Same-day tickets end at this time. Tickets already sold keep theirs.';

  @override
  String peakHoursPastMidnight(String closing) {
    return 'The hours can run past midnight, up to the closing time at $closing.';
  }

  @override
  String get peakHoursAfterClosing =>
      'Peak hours must end by the closing time: after it, no same-day tickets are sold.';

  @override
  String peakModeHelpDay(String day, String start) {
    return 'The switch is for the day of $day and goes back to automatic when the next day starts at $start. After closing time it applies to the coming day. Connected counters see the change within seconds.';
  }

  @override
  String get settingsClosingCutsPeak =>
      'The peak hours would end after this closing time. Change them first on the Ticket types page.';

  @override
  String get settingsStartCrossesPeak =>
      'The peak hours would cross this day start. Change them first on the Ticket types page.';

  @override
  String get settingsDayStart => 'Venue day starts at';

  @override
  String get settingsDayStartNote =>
      '\"Today\" for selling and every report starts at this time. If the venue closes after midnight, set it after the closing time.';

  @override
  String settingsClosingNextDay(String time) {
    return 'Closes at $time after midnight: same-day tickets end at $time the next morning.';
  }

  @override
  String get settingsClosedNowTitle => 'Selling stops now';

  @override
  String settingsClosedNowBody(String closing, String start) {
    return 'With these times today closed at $closing. Counters can\'t sell same-day tickets until the next day starts at $start.';
  }

  @override
  String get settingsClosedNowSave => 'Save anyway';

  @override
  String get settingsDefaultLanguage => 'Default language';

  @override
  String get settingsLanguageAr => 'Arabic';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsTimezone => 'Time zone';

  @override
  String get settingsTimezoneNote =>
      'Fixed: changing it would move \"today\" in every report and validity window.';

  @override
  String get settingsTicketsSection => 'Tickets';

  @override
  String get settingsGateCodeLength => 'Gate code length (digits)';

  @override
  String get settingsUnpaidTimeout => 'Cancel an unpaid order after (min)';

  @override
  String get settingsWiegandNote =>
      'A Wiegand 26 reader reads up to 16,777,215, so 7 digits at most. With a Wiegand 34 reader you can raise it. A new length applies to new tickets only.';

  @override
  String get settingsValidityNote =>
      'A ticket\'s validity (day of sale or a number of hours) is set per type.';

  @override
  String get settingsActionsSection => 'Cashier actions and review';

  @override
  String get settingsReactivationWindow =>
      'Reactivation window after a scan (min)';

  @override
  String get settingsReactivationMax => 'Most reactivations per ticket';

  @override
  String get settingsFlagActions =>
      'Review when a shift\'s actions are more than';

  @override
  String get settingsFlagPrints => 'Review when a ticket is printed more than';

  @override
  String get settingsRefundBeforeScan => 'Refund only before a scan';

  @override
  String get settingsRefundBeforeScanHelp =>
      'A ticket that entered can\'t be refunded';

  @override
  String get settingsRefundSameShift => 'Refund only in the same shift';

  @override
  String get settingsRefundSameShiftHelp =>
      'A ticket is refunded only in the shift that sold it';

  @override
  String get settingsFlagOther => 'Review any action with \"other reason\"';

  @override
  String get settingsFlagOtherHelp =>
      'It shows in the actions log as needing review';

  @override
  String get settingsTipsSection => 'Tips and quick amounts';

  @override
  String get settingsTipsEnabled => 'Record tips with payment';

  @override
  String get settingsTipsEnabledHelp =>
      'Cash only; they count in the shift\'s expected cash';

  @override
  String get settingsTipQuick => 'Tip quick amounts (EGP)';

  @override
  String get settingsFloatQuick => 'Opening float quick amounts (EGP)';

  @override
  String get settingsTipQuickNote =>
      'Up to 6: they fill two rows on the payment and close shift screens.';

  @override
  String get settingsFloatQuickNote =>
      'Up to 4: they fit one row on the open shift screen.';

  @override
  String get settingsReceivedQuick => 'Amount received quick amounts (EGP)';

  @override
  String get settingsReceivedQuickNote =>
      'Up to 8. The payment screen shows the first 3 above the order\'s total.';

  @override
  String get settingsDenominations =>
      'Denominations counted at shift close (EGP)';

  @override
  String get settingsDenominationsNote =>
      'Up to 12, shown in this order on the close screen.';

  @override
  String get settingsNoAmounts => 'none';

  @override
  String get settingsOn => 'on';

  @override
  String get settingsOff => 'off';

  @override
  String get settingsPeakSection => 'Peak times';

  @override
  String settingsPeakDays(String days) {
    return '$days: peak all day';
  }

  @override
  String get settingsPeakNoDays => 'No all-day peak days.';

  @override
  String settingsPeakHours(String from, String to) {
    return 'Other days: from $from to $to';
  }

  @override
  String get settingsPeakNote =>
      'Set on the Ticket types page; today\'s switch is on the dashboard.';

  @override
  String get settingsOfflineSection => 'Offline and network';

  @override
  String get settingsPoolSize => 'Offline codes per counter';

  @override
  String get settingsHealthCheck => 'A counter goes offline after (s)';

  @override
  String get settingsOfflineNote =>
      '0 codes turns offline selling off. Lowering it doesn\'t release codes already reserved.';

  @override
  String get settingsGateOffline => 'A gate shows offline after (s)';

  @override
  String get settingsTestOpenTimeout => 'Test open timeout (s)';

  @override
  String get settingsGateTimingNote =>
      'The gate service beats every 30 s and asks for test opens every 2 s (defaults). Keep the offline time above the beat (90 = three missed beats) and the timeout above 2.';

  @override
  String get settingsCountersSection => 'Counters and printers';

  @override
  String get settingsCountersEmpty => 'No counters yet. Add the first one.';

  @override
  String get settingsCountersNote =>
      'Test prints are made from each counter\'s open shift screen.';

  @override
  String get settingsBackupSection => 'Backup';

  @override
  String get settingsBackupNotYet =>
      'Backups aren\'t set up yet. They come with the server install at the venue.';

  @override
  String get settingsUndo => 'Undo';

  @override
  String get settingsSave => 'Save settings';

  @override
  String get settingsUnsaved => 'There are unsaved changes.';

  @override
  String settingsLastChange(String name, String time) {
    return 'Last change: $name · $time';
  }

  @override
  String get settingsNoChangeYet => 'The settings are as installed.';

  @override
  String get counterNew => 'New counter';

  @override
  String get counterAdd => 'Add counter';

  @override
  String get counterPrinterIp => 'Printer IP';

  @override
  String get counterPrinterPort => 'Printer port';

  @override
  String get counterPaperWidth => 'Paper width';

  @override
  String counterPaperMm(int mm) {
    return '$mm mm';
  }

  @override
  String get counterHomeGate => 'Home gate (during an outage)';

  @override
  String counterHomeGateIs(String gate) {
    return 'gate $gate';
  }

  @override
  String get counterHomeGateNote =>
      'While the server or switch is down, this counter\'s tickets open only this gate, which is printed on them.';

  @override
  String get counterNoHomeGate => 'no home gate';

  @override
  String counterGateDisabled(String name) {
    return '$name (disabled)';
  }

  @override
  String get counterActive => 'Counter in use';

  @override
  String get counterActiveNote => 'When off, no shift can be opened on it.';

  @override
  String get counterOpenShiftNote =>
      'A shift is open on it, so it can\'t be switched off until it closes.';

  @override
  String get counterGateChangeNote =>
      'New tickets print the new gate. Offline codes already reserved stay on the old one until they expire.';

  @override
  String get counterNewIdNote =>
      'After adding it, copy the counter\'s id (the copy button in the list). It goes into the app\'s setup on that counter\'s PC (COUNTER_ID), so the app knows which counter it is.';

  @override
  String get counterAddedCopyId =>
      'Added. Copy its id for the app\'s setup on the counter\'s PC.';

  @override
  String get counterCopyId => 'Copy counter id';

  @override
  String get counterIdCopied =>
      'Copied. This id goes into the app\'s setup on that counter\'s PC (COUNTER_ID).';

  @override
  String get counterOn => 'In use';

  @override
  String get counterOff => 'Off';

  @override
  String get counterOpenShift => 'Shift open';

  @override
  String get counterNoPrinter => 'No printer';

  @override
  String get counterInvalidName => 'Enter the counter\'s name.';

  @override
  String get counterNameTaken => 'Another counter has that name.';

  @override
  String get counterInvalidPaper => 'Paper is 58 or 80 mm.';

  @override
  String get counterHomeGateRequired => 'A counter in use needs a home gate.';

  @override
  String get counterHomeGateNotEntry => 'It must be an entry gate.';

  @override
  String get counterGateNotFound =>
      'That gate no longer exists. Reopen the page.';

  @override
  String get counterHasOpenShift => 'A shift is open on it. Close it first.';

  @override
  String get counterNotFound =>
      'The counter was changed elsewhere. The list was refreshed.';

  @override
  String get changeSettings => 'Settings';

  @override
  String changeNewCounter(String name) {
    return 'New counter: $name';
  }

  @override
  String changeCounterName(String name) {
    return 'Counter $name';
  }
}
