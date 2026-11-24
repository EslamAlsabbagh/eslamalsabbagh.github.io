import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name: window title and the login screen heading.
  ///
  /// In ar, this message translates to:
  /// **'نظام التذاكر'**
  String get appTitle;

  /// Language switch button: short code of the OTHER language.
  ///
  /// In ar, this message translates to:
  /// **'EN'**
  String get switchLanguage;

  /// Screen-reader name and tooltip of the language switch, in the OTHER language.
  ///
  /// In ar, this message translates to:
  /// **'Switch to English'**
  String get switchLanguageHint;

  /// Shown for an unknown route.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة غير موجودة'**
  String get pageNotFound;

  /// Button on the not-found page.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع للرئيسية'**
  String get backToHome;

  /// Login screen line under the app name.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لبدء الوردية'**
  String get loginSubtitle;

  /// Login screen username field label.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get usernameLabel;

  /// Login screen password field label.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// Login screen main button.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get signIn;

  /// Login screen footnote: passwords are reset by a supervisor, not by email.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟ كلّم المشرف لإعادة تعيينها.'**
  String get forgotPasswordHint;

  /// Login error: a field is empty.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم المستخدم وكلمة المرور.'**
  String get loginErrorMissingFields;

  /// Login error: wrong username or password (never says which).
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم أو كلمة المرور غير صحيحة.'**
  String get loginErrorInvalidCredentials;

  /// Login error: the login has no active staff account.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب غير مفعّل. كلّم المشرف.'**
  String get loginErrorAccountInactive;

  /// Login error: the on-site server can't be reached.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالسيرفر. تأكد من الشبكة وحاول مرة أخرى.'**
  String get loginErrorServerUnreachable;

  /// Login screen at startup: the server no longer accepts the saved session.
  ///
  /// In ar, this message translates to:
  /// **'انتهت جلستك. سجّل دخولك مرة أخرى.'**
  String get loginErrorSessionEnded;

  /// Login error: anything else.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. حاول مرة أخرى.'**
  String get loginErrorUnexpected;

  /// Sign-out button.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// Cashier flow (open shift, sell): the link to it from the admin placeholder.
  ///
  /// In ar, this message translates to:
  /// **'شاشة الكاشير'**
  String get shiftAreaTitle;

  /// Admin area: placeholder heading and the link to it from the cashier flow.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get adminAreaTitle;

  /// Admin placeholder: the signed-in user's open shift number.
  ///
  /// In ar, this message translates to:
  /// **'وردية رقم {number}'**
  String shiftNumberLabel(int number);

  /// Staff role name.
  ///
  /// In ar, this message translates to:
  /// **'كاشير'**
  String get roleCashier;

  /// Staff role name.
  ///
  /// In ar, this message translates to:
  /// **'مشرف'**
  String get roleSupervisor;

  /// Staff role name.
  ///
  /// In ar, this message translates to:
  /// **'مدير النظام'**
  String get roleAdmin;

  /// Header: who is logged in and their role.
  ///
  /// In ar, this message translates to:
  /// **'{name} · {role}'**
  String staffWithRole(String name, String role);

  /// Any screen: the on-site server can't be reached.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالسيرفر. تأكد من الشبكة وحاول مرة أخرى.'**
  String get errorServerUnreachable;

  /// Any screen: anything else went wrong.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. حاول مرة أخرى.'**
  String get errorUnexpected;

  /// Button that repeats a failed load.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get retry;

  /// Open shift screen: header title.
  ///
  /// In ar, this message translates to:
  /// **'فتح الوردية'**
  String get openShiftTitle;

  /// Open shift banner: this counter's last shift closed earlier today.
  ///
  /// In ar, this message translates to:
  /// **'آخر وردية على الجهاز ده اتقفلت النهارده الساعة {time}.'**
  String lastShiftClosedToday(String time);

  /// Open shift banner: this counter's last shift closed yesterday.
  ///
  /// In ar, this message translates to:
  /// **'آخر وردية على الجهاز ده اتقفلت أمس الساعة {time}.'**
  String lastShiftClosedYesterday(String time);

  /// Open shift banner: this counter's last shift closed before yesterday.
  ///
  /// In ar, this message translates to:
  /// **'آخر وردية على الجهاز ده اتقفلت يوم {date} الساعة {time}.'**
  String lastShiftClosedOn(String date, String time);

  /// Open shift: opening float card heading.
  ///
  /// In ar, this message translates to:
  /// **'عهدة بداية الوردية'**
  String get openingFloatTitle;

  /// Open shift: line under the opening float heading.
  ///
  /// In ar, this message translates to:
  /// **'عدّ الفكة اللي في الدرج واكتب المبلغ. هيتقارن بالمبلغ اللي هتعدّه وقت قفل الوردية.'**
  String get openingFloatHint;

  /// Open shift: opening float field label (whole pounds).
  ///
  /// In ar, this message translates to:
  /// **'المبلغ (ج.م)'**
  String get openingFloatLabel;

  /// Open shift: printer card title with its LAN address.
  ///
  /// In ar, this message translates to:
  /// **'الطابعة · {address}'**
  String printerLabel(String address);

  /// Open shift: printer card title when no printer is set.
  ///
  /// In ar, this message translates to:
  /// **'الطابعة'**
  String get printerLabelNone;

  /// Printer card: the counter has no printer address.
  ///
  /// In ar, this message translates to:
  /// **'مفيش طابعة متسجلة للشباك ده. كلّم الأدمن.'**
  String get printerNotSet;

  /// Printer card: connection check running.
  ///
  /// In ar, this message translates to:
  /// **'بنفحص الطابعة…'**
  String get printerChecking;

  /// Printer card: printer answers.
  ///
  /// In ar, this message translates to:
  /// **'متصلة · اعمل طباعة تجريبية قبل البدء'**
  String get printerReachable;

  /// Printer card: printer doesn't answer.
  ///
  /// In ar, this message translates to:
  /// **'الطابعة مش بترد. اتأكد إنها شغالة ومتوصلة.'**
  String get printerUnreachable;

  /// Printer card: test page being sent.
  ///
  /// In ar, this message translates to:
  /// **'بنطبع ورقة تجريبية…'**
  String get printerPrinting;

  /// Printer card: test page sent.
  ///
  /// In ar, this message translates to:
  /// **'اتطبعت ورقة تجريبية — الطابعة شغالة'**
  String get printerPrinted;

  /// Printer card: test page couldn't be sent.
  ///
  /// In ar, this message translates to:
  /// **'الطباعة التجريبية فشلت. اتأكد من الطابعة وحاول تاني.'**
  String get printerPrintFailed;

  /// Printer card: test print button.
  ///
  /// In ar, this message translates to:
  /// **'طباعة تجريبية'**
  String get testPrint;

  /// Printer card: repeat the connection check.
  ///
  /// In ar, this message translates to:
  /// **'افحص تاني'**
  String get checkPrinterAgain;

  /// Open shift: main button.
  ///
  /// In ar, this message translates to:
  /// **'فتح الوردية وبدء البيع'**
  String get openShiftButton;

  /// Open shift: the app config has no COUNTER_ID.
  ///
  /// In ar, this message translates to:
  /// **'الجهاز ده مش متسجل على شباك. كلّم الأدمن يضبط إعدادات التطبيق.'**
  String get openShiftNoCounter;

  /// Open shift: counter_unavailable (unknown or inactive counter).
  ///
  /// In ar, this message translates to:
  /// **'الشباك ده مش موجود أو موقوف. كلّم الأدمن.'**
  String get openShiftCounterUnavailable;

  /// Open shift: counter_no_home_gate (ADR-0015, task 1.10a).
  ///
  /// In ar, this message translates to:
  /// **'الشباك ده ملوش بوابة. كلّم الأدمن.'**
  String get openShiftCounterNoHomeGate;

  /// Open shift: the user's open shift is at another counter.
  ///
  /// In ar, this message translates to:
  /// **'عندك وردية مفتوحة على {counter}. اقفلها من هناك الأول.'**
  String openShiftElsewhere(String counter);

  /// Open shift: counter_busy (another cashier's shift is open here).
  ///
  /// In ar, this message translates to:
  /// **'فيه وردية تانية مفتوحة على الشباك ده. لازم تتقفل الأول.'**
  String get openShiftErrorCounterBusy;

  /// Open shift: no opening float typed.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبلغ العهدة.'**
  String get openShiftErrorInvalidCash;

  /// An amount in Egyptian pounds; amount is already formatted with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ج.م'**
  String moneyAmount(String amount);

  /// Sell screen: header title.
  ///
  /// In ar, this message translates to:
  /// **'بيع التذاكر'**
  String get sellTitle;

  /// Sell screen header: counter, open shift number, when it opened.
  ///
  /// In ar, this message translates to:
  /// **'{counter} · وردية #{number} · بدأت {time}'**
  String sellSubtitle(String counter, int number, String time);

  /// Sell screen: heading above the ticket type cards.
  ///
  /// In ar, this message translates to:
  /// **'اختار نوع التذكرة والعدد'**
  String get sellHeading;

  /// Sell screen: opens ticket lookup (task 2.6).
  ///
  /// In ar, this message translates to:
  /// **'بحث عن تذكرة'**
  String get findTicket;

  /// Sell screen: opens the last order's review (task 2.5).
  ///
  /// In ar, this message translates to:
  /// **'آخر طلب'**
  String get lastOrder;

  /// Sell screen: opens close shift (task 2.7).
  ///
  /// In ar, this message translates to:
  /// **'قفل الوردية'**
  String get closeShift;

  /// Sell header badge: the printer answers.
  ///
  /// In ar, this message translates to:
  /// **'الطابعة جاهزة'**
  String get printerBadgeReady;

  /// Sell header badge: printer check running.
  ///
  /// In ar, this message translates to:
  /// **'بنفحص الطابعة…'**
  String get printerBadgeChecking;

  /// Sell header badge: the printer doesn't answer.
  ///
  /// In ar, this message translates to:
  /// **'الطابعة مش بترد'**
  String get printerBadgeUnreachable;

  /// Sell header badge: the counter has no printer address.
  ///
  /// In ar, this message translates to:
  /// **'مفيش طابعة'**
  String get printerBadgeNotSet;

  /// Sell header badge tooltip: tapping repeats the check.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لفحص الطابعة تاني'**
  String get printerBadgeHint;

  /// Ticket type card: one entry per ticket.
  ///
  /// In ar, this message translates to:
  /// **'دخول مرة واحدة'**
  String get ticketRuleSingleEntry;

  /// Ticket type card: a multi-entry ticket (count is at least 2).
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =2{دخول حتى مرتين} few{دخول حتى {count} مرات} other{دخول حتى {count} مرة}}'**
  String ticketRuleEntries(int count);

  /// Ticket type card: valid until today's closing time (same_day).
  ///
  /// In ar, this message translates to:
  /// **'صالحة اليوم'**
  String get ticketRuleValidToday;

  /// Ticket type card: valid N hours from sale (hours_from_sale).
  ///
  /// In ar, this message translates to:
  /// **'{hours, plural, =1{صالحة ساعة واحدة} =2{صالحة ساعتين} few{صالحة {hours} ساعات} other{صالحة {hours} ساعة}}'**
  String ticketRuleValidHours(int hours);

  /// Ticket type card: + button, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'زيادة'**
  String get increaseQuantity;

  /// Ticket type card: − button, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'تقليل'**
  String get decreaseQuantity;

  /// Sell screen: no active ticket types.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أنواع تذاكر متاحة للبيع. كلّم الأدمن.'**
  String get noTicketTypes;

  /// Sell footer: paid orders in this shift (count only, no money).
  ///
  /// In ar, this message translates to:
  /// **'طلبات الوردية:'**
  String get footerShiftOrders;

  /// Sell footer: tickets sold in this shift (count only, no money).
  ///
  /// In ar, this message translates to:
  /// **'التذاكر المباعة:'**
  String get footerTicketsSold;

  /// Sell footer: the shift's newest order number.
  ///
  /// In ar, this message translates to:
  /// **'آخر طلب:'**
  String get footerLastOrder;

  /// Sell screen: order panel heading.
  ///
  /// In ar, this message translates to:
  /// **'الطلب الحالي'**
  String get currentOrder;

  /// Sell screen: empties the current order.
  ///
  /// In ar, this message translates to:
  /// **'مسح الطلب'**
  String get clearOrder;

  /// Sell screen: the current order has no tickets yet.
  ///
  /// In ar, this message translates to:
  /// **'اختار أنواع التذاكر من القائمة'**
  String get orderEmpty;

  /// Order line: quantity times the unit price.
  ///
  /// In ar, this message translates to:
  /// **'{quantity} × {price}'**
  String orderLineQuantity(int quantity, String price);

  /// Sell screen: payment method buttons label.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get paymentMethodLabel;

  /// Payment method: cash.
  ///
  /// In ar, this message translates to:
  /// **'نقدي'**
  String get paymentCash;

  /// Payment method: card.
  ///
  /// In ar, this message translates to:
  /// **'كارت'**
  String get paymentCard;

  /// Payment method: mobile wallet.
  ///
  /// In ar, this message translates to:
  /// **'محفظة'**
  String get paymentWallet;

  /// Sell screen: label before the current order's total.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{الإجمالي · {count} تذاكر} other{الإجمالي · {count} تذكرة}}'**
  String orderTotal(int count);

  /// Sell screen main button: prints the tickets, then the payment screen (ADR-0007).
  ///
  /// In ar, this message translates to:
  /// **'طباعة التذاكر والتحصيل'**
  String get printAndCharge;

  /// Sell screen: keyboard shortcuts under the main button.
  ///
  /// In ar, this message translates to:
  /// **'F12 للطباعة والتحصيل · Esc لمسح الطلب'**
  String get sellShortcutsHint;

  /// Printed ticket: under the venue name.
  ///
  /// In ar, this message translates to:
  /// **'تذكرة دخول'**
  String get ticketHeading;

  /// Printed ticket: valid from sale until a time on the same day (date dd/MM/yyyy, time HH:mm).
  ///
  /// In ar, this message translates to:
  /// **'صالحة يوم {date} حتى {time}'**
  String ticketValidOnDay(String date, String time);

  /// Printed ticket: valid until a time on a later day.
  ///
  /// In ar, this message translates to:
  /// **'صالحة حتى {date} {time}'**
  String ticketValidUntil(String date, String time);

  /// Printed ticket: the ticket's home gate, the one that still opens while the server is down (ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'ادخل من: {gate}'**
  String ticketHomeGate(String gate);

  /// Printed ticket: order row label.
  ///
  /// In ar, this message translates to:
  /// **'طلب'**
  String get ticketOrderLabel;

  /// Printed ticket: order number and this ticket's place in the order.
  ///
  /// In ar, this message translates to:
  /// **'#{number} · {index} من {count}'**
  String ticketOrderValue(String number, String index, String count);

  /// Printed ticket: counter and cashier row label.
  ///
  /// In ar, this message translates to:
  /// **'شباك'**
  String get ticketCounterLabel;

  /// Printed ticket: sale time row label.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get ticketTimeLabel;

  /// Printed ticket: last line.
  ///
  /// In ar, this message translates to:
  /// **'امسح الكود على البوابة · احتفظ بالتذكرة'**
  String get ticketFooter;

  /// Printed test page: title.
  ///
  /// In ar, this message translates to:
  /// **'طباعة تجريبية'**
  String get testPageTitle;

  /// Printed test page: above the sample ticket, which no gate accepts.
  ///
  /// In ar, this message translates to:
  /// **'عينة — مش تذكرة'**
  String get testPageNotATicket;

  /// Printed test page: the counter's paper width.
  ///
  /// In ar, this message translates to:
  /// **'ورق {width} مم'**
  String testPagePaper(String width);

  /// Printed test page: a line to check the letters and digits print right.
  ///
  /// In ar, this message translates to:
  /// **'أبجد هوز حطي كلمن · 0123456789'**
  String get testPageSample;

  /// Printed test page: the sample ticket's type name.
  ///
  /// In ar, this message translates to:
  /// **'عينة'**
  String get testPageSampleType;

  /// Payment header: counter and shift.
  ///
  /// In ar, this message translates to:
  /// **'{counter} · وردية #{number}'**
  String shiftSubtitle(String counter, int number);

  /// Sell: sell_tickets refused, the counter has no home gate.
  ///
  /// In ar, this message translates to:
  /// **'الشباك ده مالوش بوابة. كلّم الأدمن.'**
  String get sellFailureCounterNoHomeGate;

  /// Sell: an admin switched off a type in the order.
  ///
  /// In ar, this message translates to:
  /// **'نوع تذكرة في الطلب اتوقف بيعه. القائمة اتحدّثت، راجع الطلب.'**
  String get sellFailureTypeUnavailable;

  /// Sell: same-day tickets after closing time.
  ///
  /// In ar, this message translates to:
  /// **'عدّى ميعاد القفل: تذاكر النهارده بس مش بتتباع دلوقتي.'**
  String get sellFailureAfterClosing;

  /// Sell: gate_code_space_exhausted.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أكواد تذاكر فاضية. كلّم الأدمن.'**
  String get sellFailureCodesExhausted;

  /// Sell: after cancelling an order.
  ///
  /// In ar, this message translates to:
  /// **'الطلب #{number} اتلغى. خد التذاكر المطبوعة من العميل.'**
  String orderCancelledNotice(int number);

  /// Payment header title with the method.
  ///
  /// In ar, this message translates to:
  /// **'التحصيل · {method}'**
  String paymentTitle(String method);

  /// Payment: tickets still printing.
  ///
  /// In ar, this message translates to:
  /// **'بنطبع التذاكر…'**
  String get printStatusPrinting;

  /// Payment: every ticket printed.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{اتطبعت {count} تذاكر} other{اتطبعت {count} تذكرة}}'**
  String printStatusPrinted(int count);

  /// Payment and review: some tickets failed to print.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{{count} تذاكر ما اتطبعتش} other{{count} تذكرة ما اتطبعتش}}'**
  String printStatusFailed(int count);

  /// Payment: printed tickets out of the order's.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {count}'**
  String printStatusCount(int done, int count);

  /// Payment: under the print status.
  ///
  /// In ar, this message translates to:
  /// **'سلّم التذاكر بعد ما تستلم الفلوس. التذاكر مش هتفتح البوابة غير بعد تأكيد التحصيل.'**
  String get printStatusHint;

  /// Payment: under a failed print status.
  ///
  /// In ar, this message translates to:
  /// **'اتأكد من الطابعة (الورق والكهربا) واضغط إعادة المحاولة.'**
  String get printStatusFailedHint;

  /// Payment: order summary heading.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الطلب #{number}'**
  String orderSummary(int number);

  /// Payment: one ticket type of the order.
  ///
  /// In ar, this message translates to:
  /// **'{name} × {quantity}'**
  String soldLine(String name, int quantity);

  /// Payment: label of the order's total.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{المطلوب · {count} تذاكر} other{المطلوب · {count} تذكرة}}'**
  String amountDue(int count);

  /// Payment: amount received field label.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المستلم (ج.م) · اكتبه أو استخدم الأرقام'**
  String get amountReceivedLabel;

  /// Payment: quick amount equal to the total.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ بالظبط'**
  String get exactAmount;

  /// Payment: tip box heading.
  ///
  /// In ar, this message translates to:
  /// **'إكرامية من العميل (اختياري)'**
  String get tipTitle;

  /// Payment: no tip.
  ///
  /// In ar, this message translates to:
  /// **'بدون'**
  String get tipNone;

  /// Payment: typed tip placeholder.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ'**
  String get tipTypedHint;

  /// Payment: typed tip field, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ الإكرامية بالجنيه'**
  String get tipTypedLabel;

  /// Payment: tip = amount received − total.
  ///
  /// In ar, this message translates to:
  /// **'العميل ساب الباقي كله إكرامية'**
  String get tipTheChange;

  /// Payment and review: change label.
  ///
  /// In ar, this message translates to:
  /// **'الباقي للعميل'**
  String get changeLabel;

  /// Payment: change label with a tip.
  ///
  /// In ar, this message translates to:
  /// **'الباقي للعميل بعد إكرامية {tip}'**
  String changeAfterTip(String tip);

  /// Payment: the cash received is less than total + tip.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ ناقص'**
  String get amountShort;

  /// Payment keypad: clear, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get keypadClear;

  /// Payment keypad: backspace, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'حذف رقم'**
  String get keypadBackspace;

  /// Payment: card payment instructions.
  ///
  /// In ar, this message translates to:
  /// **'حصّل {amount} على ماكينة الكارت، وبعدين أكّد التحصيل.'**
  String cardPaymentNote(String amount);

  /// Payment: wallet payment instructions.
  ///
  /// In ar, this message translates to:
  /// **'استلم {amount} على المحفظة، وبعدين أكّد التحصيل.'**
  String walletPaymentNote(String amount);

  /// Payment: cancel button title.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get cancelOrder;

  /// Payment: cancel button subtitle.
  ///
  /// In ar, this message translates to:
  /// **'العميل ما دفعش · التذاكر المطبوعة بتتلغي'**
  String get cancelOrderHint;

  /// Payment: confirm button.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التحصيل'**
  String get confirmPayment;

  /// Payment: keyboard hint.
  ///
  /// In ar, this message translates to:
  /// **'Enter أو F12 لتأكيد التحصيل'**
  String get paymentShortcutsHint;

  /// Cancel dialog title.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب #{number}؟'**
  String cancelDialogTitle(int number);

  /// Cancel dialog text.
  ///
  /// In ar, this message translates to:
  /// **'التذاكر المطبوعة هتتلغي ومش هتفتح البوابة. خدها من العميل.'**
  String get cancelDialogBody;

  /// Cancel reason.
  ///
  /// In ar, this message translates to:
  /// **'العميل ما دفعش'**
  String get cancelReasonNotPaid;

  /// Cancel reason: needs typed text.
  ///
  /// In ar, this message translates to:
  /// **'سبب تاني'**
  String get cancelReasonOther;

  /// Cancel dialog: other reason text field.
  ///
  /// In ar, this message translates to:
  /// **'اكتب السبب'**
  String get cancelReasonTextLabel;

  /// Cancel dialog: other reason left blank.
  ///
  /// In ar, this message translates to:
  /// **'لازم تكتب السبب'**
  String get cancelReasonTextRequired;

  /// Cancel dialog: keep the order.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get cancelDialogKeep;

  /// Payment: the unpaid-order job cancelled it first.
  ///
  /// In ar, this message translates to:
  /// **'الطلب ده اتلغى تلقائي لأنه فضل من غير تحصيل، والتذاكر اتلغت. خدها من العميل وبيع تاني.'**
  String get paymentFailureOrderCancelled;

  /// Payment: order_not_found.
  ///
  /// In ar, this message translates to:
  /// **'الطلب ده مش موجود في ورديتك. ارجع للبيع وبيع تاني.'**
  String get paymentFailureOrderNotFound;

  /// Payment: tips switched off, or not cash.
  ///
  /// In ar, this message translates to:
  /// **'الإكرامية مش مسموحة للدفع ده. شيل الإكرامية وحاول تاني.'**
  String get paymentFailureTipNotAllowed;

  /// Payment: invalid_amount_received.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المستلم أقل من المطلوب.'**
  String get paymentFailureAmount;

  /// Payment: cancel refused, the order is paid.
  ///
  /// In ar, this message translates to:
  /// **'الطلب ده اتحصّل خلاص.'**
  String get paymentFailureAlreadyPaid;

  /// Payment: leave an order the server cancelled, or one the server can't confirm (ADR-0039).
  ///
  /// In ar, this message translates to:
  /// **'رجوع للبيع'**
  String get backToSell;

  /// Payment: confirm got no answer and the counter is offline. Back to selling leaves the order unconfirmed; the server's job cancels it (ADR-0039).
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالسيرفر، فلم يُؤكَّد الدفع. حاول مرة أخرى، أو ارجع للبيع وبِع بدون اتصال: استرجع التذاكر المطبوعة، فهي لا تفتح البوابة.'**
  String get paymentServerUnreachable;

  /// Review header title.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة طلب #{number}'**
  String reviewTitle(int number);

  /// Review header subtitle: counter, shift, sale time.
  ///
  /// In ar, this message translates to:
  /// **'{counter} · وردية #{number} · {time}'**
  String reviewSubtitle(String counter, int number, String time);

  /// Review banner: all printed.
  ///
  /// In ar, this message translates to:
  /// **'تم التحصيل · التذاكر شغالة'**
  String get reviewPaidTitle;

  /// Review banner: count, this order's total and method.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{{count} تذاكر اتطبعت · {total} · {method}} other{{count} تذكرة اتطبعت · {total} · {method}}}'**
  String reviewPaidSubtitle(int count, String total, String method);

  /// Review banner: some tickets still printing.
  ///
  /// In ar, this message translates to:
  /// **'تم التحصيل · بنطبع التذاكر…'**
  String get reviewPrintingTitle;

  /// Review banner: some tickets failed to print.
  ///
  /// In ar, this message translates to:
  /// **'التحصيل اتأكد. اتأكد من الطابعة واضغط إعادة المحاولة.'**
  String get reviewFailedSubtitle;

  /// Review: tickets list heading.
  ///
  /// In ar, this message translates to:
  /// **'التذاكر'**
  String get reviewTickets;

  /// Review: ticket status chip.
  ///
  /// In ar, this message translates to:
  /// **'اتطبعت'**
  String get ticketPrinted;

  /// Review: ticket status chip.
  ///
  /// In ar, this message translates to:
  /// **'فشلت الطباعة'**
  String get ticketPrintFailed;

  /// Review: ticket status chip.
  ///
  /// In ar, this message translates to:
  /// **'بتتطبع…'**
  String get ticketPrinting;

  /// Review: ticket status chip.
  ///
  /// In ar, this message translates to:
  /// **'مستنية الطباعة'**
  String get ticketWaiting;

  /// Review: under the tickets list.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الطباعة بتتسجل باسمك والسبب، وبتظهر للإدارة في سجل الإجراءات.'**
  String get reviewReprintNote;

  /// Review: reprint button (task 2.6).
  ///
  /// In ar, this message translates to:
  /// **'إعادة طباعة'**
  String get reprint;

  /// Review: back to selling.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد'**
  String get newOrder;

  /// Review: keyboard hint.
  ///
  /// In ar, this message translates to:
  /// **'Enter لطلب جديد'**
  String get reviewShortcutsHint;

  /// Header: back arrow label.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// Dialog close button label.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// A time today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {time}'**
  String todayAt(String time);

  /// Lookup header title (task 2.6).
  ///
  /// In ar, this message translates to:
  /// **'البحث عن تذكرة'**
  String get lookupTitle;

  /// Lookup: code field label.
  ///
  /// In ar, this message translates to:
  /// **'امسح التذكرة بالقارئ أو اكتب الكود'**
  String get lookupCodeLabel;

  /// Lookup: search button.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get lookupSearch;

  /// Lookup: detail label.
  ///
  /// In ar, this message translates to:
  /// **'الطلب'**
  String get lookupOrder;

  /// Lookup: detail label (time · counter).
  ///
  /// In ar, this message translates to:
  /// **'اتباعت'**
  String get lookupSold;

  /// Lookup: detail label.
  ///
  /// In ar, this message translates to:
  /// **'الكاشير'**
  String get lookupCashier;

  /// Lookup: detail label.
  ///
  /// In ar, this message translates to:
  /// **'صالحة لحد'**
  String get lookupValidUntil;

  /// Lookup: detail label.
  ///
  /// In ar, this message translates to:
  /// **'مرات الدخول المتبقية'**
  String get lookupEntriesLeft;

  /// Lookup: entries left of allowed.
  ///
  /// In ar, this message translates to:
  /// **'{left} من {allowed}'**
  String lookupEntriesValue(int left, int allowed);

  /// Lookup: detail label.
  ///
  /// In ar, this message translates to:
  /// **'مرات الطباعة'**
  String get lookupPrintCount;

  /// Lookup: the ticket's home gate (ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'بوابة الدخول'**
  String get lookupHomeGate;

  /// Lookup: scan history heading.
  ///
  /// In ar, this message translates to:
  /// **'سجل المسح على البوابات'**
  String get lookupScansTitle;

  /// Lookup: no scans.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة دي لسه ما اتمسحتش على أي بوابة.'**
  String get lookupNoScans;

  /// Lookup note: the reactivation window is open.
  ///
  /// In ar, this message translates to:
  /// **'{minutes, plural, =1{لو العميل عمل مسح ومعدّاش، تقدر ترجّع التذكرة صالحة لحد {until} (فاضل دقيقة).} =2{لو العميل عمل مسح ومعدّاش، تقدر ترجّع التذكرة صالحة لحد {until} (فاضل دقيقتين).} few{لو العميل عمل مسح ومعدّاش، تقدر ترجّع التذكرة صالحة لحد {until} (فاضل {minutes} دقايق).} other{لو العميل عمل مسح ومعدّاش، تقدر ترجّع التذكرة صالحة لحد {until} (فاضل {minutes} دقيقة).}}'**
  String lookupNoteReactivate(String until, int minutes);

  /// Lookup note: who voided it.
  ///
  /// In ar, this message translates to:
  /// **'اتلغت {time} بواسطة {actor} · {counter} · السبب: {reason}.'**
  String lookupNoteVoided(
    String time,
    String actor,
    String counter,
    String reason,
  );

  /// Lookup note: cancelled by the unpaid-order job.
  ///
  /// In ar, this message translates to:
  /// **'اتلغت {time} تلقائي، لأن الطلب فضل من غير تحصيل.'**
  String lookupNoteVoidedAuto(String time);

  /// Lookup note: voided, no action found.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة دي ملغاة وما بتفتحش البوابة.'**
  String get lookupNoteVoidedPlain;

  /// Lookup note: pending ticket.
  ///
  /// In ar, this message translates to:
  /// **'الطلب لسه ما اتحصّلش. التذكرة مش هتفتح البوابة غير بعد تأكيد التحصيل.'**
  String get lookupNotePending;

  /// Lookup note: expired ticket (ADR-0020).
  ///
  /// In ar, this message translates to:
  /// **'صلاحية التذكرة خلصت {until}. ما ينفعش تتطبع تاني أو ترجع صالحة.'**
  String lookupNoteExpired(String until);

  /// Lookup status pill.
  ///
  /// In ar, this message translates to:
  /// **'سليمة · لسه ما دخلتش'**
  String get statusActiveUnused;

  /// Lookup status pill: active, some entries used.
  ///
  /// In ar, this message translates to:
  /// **'سليمة'**
  String get statusActive;

  /// Lookup status pill.
  ///
  /// In ar, this message translates to:
  /// **'مستخدمة'**
  String get statusUsed;

  /// Lookup status pill.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get statusVoided;

  /// Lookup status pill: pending.
  ///
  /// In ar, this message translates to:
  /// **'مش مدفوعة'**
  String get statusPending;

  /// Lookup status pill.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get statusExpired;

  /// Lookup: accepted scan.
  ///
  /// In ar, this message translates to:
  /// **'اتقبلت'**
  String get scanAccepted;

  /// Lookup: rejected scan.
  ///
  /// In ar, this message translates to:
  /// **'مرفوضة · {reason}'**
  String scanRejected(String reason);

  /// Scan reject reason.
  ///
  /// In ar, this message translates to:
  /// **'مش مدفوعة'**
  String get scanReasonNotPaid;

  /// Scan reject reason.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get scanReasonVoided;

  /// Scan reject reason.
  ///
  /// In ar, this message translates to:
  /// **'مستخدمة قبل كده'**
  String get scanReasonUsedUp;

  /// Scan reject reason.
  ///
  /// In ar, this message translates to:
  /// **'لسه مش صالحة'**
  String get scanReasonNotYetValid;

  /// Scan reject reason.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get scanReasonExpired;

  /// Scan reject reason.
  ///
  /// In ar, this message translates to:
  /// **'البوابة مقفولة'**
  String get scanReasonGateDisabled;

  /// Scan reject reason.
  ///
  /// In ar, this message translates to:
  /// **'كود مش معروف'**
  String get scanReasonNotFound;

  /// Action dialog title.
  ///
  /// In ar, this message translates to:
  /// **'إجراء على التذكرة'**
  String get actionDialogTitle;

  /// Action dialog subtitle: the ticket type.
  ///
  /// In ar, this message translates to:
  /// **'تذكرة {type}'**
  String actionDialogTicket(String type);

  /// Action dialog subtitle: the order.
  ///
  /// In ar, this message translates to:
  /// **'طلب #{number}'**
  String actionDialogOrder(int number);

  /// Action dialog: action picker label.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء'**
  String get actionLabel;

  /// Ticket action name.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تفعيل'**
  String get actionReactivate;

  /// Ticket action name.
  ///
  /// In ar, this message translates to:
  /// **'إعادة طباعة'**
  String get actionReprint;

  /// Ticket action name.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء واسترداد'**
  String get actionVoidRefund;

  /// Action dialog help.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة ترجع صالحة لدخول واحد. استخدمها لو العميل عمل مسح ومعدّاش.'**
  String get actionHelpReactivate;

  /// Action dialog help.
  ///
  /// In ar, this message translates to:
  /// **'هتتطبع نسخة جديدة بنفس الكود. النسخة القديمة والجديدة نفس التذكرة، فدخول واحد بس.'**
  String get actionHelpReprint;

  /// Action dialog help.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة هتتلغي وهتترفض على البوابة، والمبلغ يتخصم من الوردية.'**
  String get actionHelpVoidRefund;

  /// Action dialog: why an action is blocked.
  ///
  /// In ar, this message translates to:
  /// **'{action}: {reason}'**
  String actionBlocked(String action, String reason);

  /// Action dialog limit: settings.reactivation_max and reactivation_window_min.
  ///
  /// In ar, this message translates to:
  /// **'{max, plural, =1{مسموحة مرة واحدة للتذكرة، وخلال {window} دقايق من آخر مسح عليها.} =2{مسموحة مرتين للتذكرة، وخلال {window} دقايق من آخر مسح عليها.} few{مسموحة {max} مرات للتذكرة، وخلال {window} دقايق من آخر مسح عليها.} other{مسموحة {max} مرة للتذكرة، وخلال {window} دقايق من آخر مسح عليها.}}'**
  String actionLimitReactivate(int max, int window);

  /// Action dialog limit.
  ///
  /// In ar, this message translates to:
  /// **'عدد مرات الطباعة بيظهر على التذكرة وفي السجل.'**
  String get actionLimitReprint;

  /// Action dialog limit: both refund settings on.
  ///
  /// In ar, this message translates to:
  /// **'متاح بس لتذكرة ما اتمسحتش على أي بوابة، وفي نفس الوردية اللي اتباعت فيها.'**
  String get actionLimitRefundBoth;

  /// Action dialog limit: refund_before_scan_only.
  ///
  /// In ar, this message translates to:
  /// **'متاح بس لتذكرة ما اتمسحتش على أي بوابة.'**
  String get actionLimitRefundBeforeScan;

  /// Action dialog limit: refund_same_shift_only.
  ///
  /// In ar, this message translates to:
  /// **'متاح بس في نفس الوردية اللي اتباعت فيها.'**
  String get actionLimitRefundSameShift;

  /// Action dialog limit: both refund settings off.
  ///
  /// In ar, this message translates to:
  /// **'متاح لأي تذكرة مدفوعة.'**
  String get actionLimitRefundAny;

  /// Refund: cash-paid ticket.
  ///
  /// In ar, this message translates to:
  /// **'رجّع للعميل نقدي'**
  String get refundInCash;

  /// Refund: card-paid ticket.
  ///
  /// In ar, this message translates to:
  /// **'رجّع للعميل على الكارت'**
  String get refundToCard;

  /// Refund: wallet-paid ticket.
  ///
  /// In ar, this message translates to:
  /// **'رجّع للعميل على المحفظة'**
  String get refundToWallet;

  /// Action dialog: reasons label.
  ///
  /// In ar, this message translates to:
  /// **'السبب (إجباري)'**
  String get actionReasonLabel;

  /// Action dialog: note field.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get actionReasonNoteLabel;

  /// Action dialog: note field for "other".
  ///
  /// In ar, this message translates to:
  /// **'اكتب السبب (إجباري)'**
  String get actionReasonTextRequiredLabel;

  /// Action dialog: "other" without text.
  ///
  /// In ar, this message translates to:
  /// **'لازم تكتب السبب'**
  String get actionReasonTextRequired;

  /// Reactivate reason.
  ///
  /// In ar, this message translates to:
  /// **'عمل مسح ومعدّاش'**
  String get reasonScannedNotPassed;

  /// Reactivate reason.
  ///
  /// In ar, this message translates to:
  /// **'البوابة ما فتحتش'**
  String get reasonGateDidNotOpen;

  /// Reprint reason.
  ///
  /// In ar, this message translates to:
  /// **'الطباعة باظت'**
  String get reasonPrintFailed;

  /// Reprint reason.
  ///
  /// In ar, this message translates to:
  /// **'العميل ضيّع التذكرة'**
  String get reasonTicketLost;

  /// Refund reason.
  ///
  /// In ar, this message translates to:
  /// **'العميل غيّر رأيه'**
  String get reasonCustomerChangedMind;

  /// Refund reason.
  ///
  /// In ar, this message translates to:
  /// **'نوع تذكرة غلط'**
  String get reasonWrongTicketType;

  /// Any action: other reason.
  ///
  /// In ar, this message translates to:
  /// **'سبب آخر'**
  String get reasonOther;

  /// Logged reason of the automatic cancel.
  ///
  /// In ar, this message translates to:
  /// **'الطلب ما اتحصّلش في الوقت'**
  String get reasonUnpaidTimeout;

  /// Action dialog confirm.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التفعيل'**
  String get actionConfirmReactivate;

  /// Action dialog confirm.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الطباعة'**
  String get actionConfirmReprint;

  /// Action dialog confirm: the ticket price.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء واسترداد {amount}'**
  String actionConfirmVoidRefund(String amount);

  /// Action dialog: last line.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء بيتسجل باسمك والشباك والسبب والوقت، وبيظهر للإدارة في سجل الإجراءات.'**
  String get actionFootnote;

  /// Action dialog: reprint copy printing.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الطباعة اتسجلت · النسخة بتتطبع…'**
  String get actionCopyPrinting;

  /// Action dialog: reprint copy failed.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الطباعة اتسجلت بس النسخة ما اتطبعتش. اتأكد من الطابعة واضغط إعادة المحاولة.'**
  String get actionCopyFailed;

  /// Action dialog: give up the failed copy.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق من غير طباعة'**
  String get actionCloseCopy;

  /// Notice after a reprint.
  ///
  /// In ar, this message translates to:
  /// **'النسخة اتطبعت، وإعادة الطباعة اتسجلت.'**
  String get outcomeReprinted;

  /// Notice after a reprint whose copy failed.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الطباعة اتسجلت بس النسخة ما اتطبعتش.'**
  String get outcomeReprintNotPrinted;

  /// Notice after a reactivation.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة رجعت صالحة لدخول واحد.'**
  String get outcomeReactivated;

  /// Notice after a refund: how and how much.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة اتلغت. {how}: {amount}'**
  String outcomeRefunded(String how, String amount);

  /// ticket_not_found.
  ///
  /// In ar, this message translates to:
  /// **'مفيش تذكرة بالكود ده.'**
  String get ticketFailureNotFound;

  /// no_open_shift.
  ///
  /// In ar, this message translates to:
  /// **'لازم وردية مفتوحة عشان تعمل إجراء.'**
  String get ticketFailureNoOpenShift;

  /// ticket_voided.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة ملغاة.'**
  String get ticketFailureVoided;

  /// ticket_used.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة مستخدمة. رجّعها صالحة الأول.'**
  String get ticketFailureUsed;

  /// ticket_expired.
  ///
  /// In ar, this message translates to:
  /// **'صلاحية التذكرة خلصت.'**
  String get ticketFailureExpired;

  /// not_scanned.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة ما دخلتش من أي بوابة.'**
  String get ticketFailureNotScanned;

  /// already_reactivated.
  ///
  /// In ar, this message translates to:
  /// **'آخر مسح عليها اترجع خلاص.'**
  String get ticketFailureAlreadyReactivated;

  /// reactivation_limit_reached.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة رجعت صالحة أقصى عدد مرات مسموح.'**
  String get ticketFailureReactivationLimit;

  /// reactivation_window_passed.
  ///
  /// In ar, this message translates to:
  /// **'الوقت المسموح بعد آخر مسح خلص.'**
  String get ticketFailureReactivationWindow;

  /// ticket_not_paid.
  ///
  /// In ar, this message translates to:
  /// **'الطلب لسه ما اتحصّلش. ألغِ الطلب بدل كده.'**
  String get ticketFailureNotPaid;

  /// ticket_already_scanned.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة اتمسحت ودخلت قبل كده.'**
  String get ticketFailureAlreadyScanned;

  /// not_same_shift.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة اتباعت في وردية تانية.'**
  String get ticketFailureNotSameShift;

  /// Printed ticket: copy row label (a reprint).
  ///
  /// In ar, this message translates to:
  /// **'الطباعة'**
  String get ticketCopyLabel;

  /// Printed ticket: which print this is.
  ///
  /// In ar, this message translates to:
  /// **'نسخة {count}'**
  String ticketCopyValue(int count);

  /// Review: ticket void-refunded from the review.
  ///
  /// In ar, this message translates to:
  /// **'اتلغت واترجع مبلغها'**
  String get ticketRefunded;

  /// Review: ticket left unprinted (ADR-0024).
  ///
  /// In ar, this message translates to:
  /// **'ما اتطبعتش · اتسجلت'**
  String get ticketLeftUnprinted;

  /// Review: New order with failed prints.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{تذكرة واحدة ما اتطبعتش} =2{تذكرتين ما اتطبعوش} few{{count} تذاكر ما اتطبعتش} other{{count} تذكرة ما اتطبعتش}}'**
  String unprintedDialogTitle(int count);

  /// Review: unprinted dialog body.
  ///
  /// In ar, this message translates to:
  /// **'لو غادرت الطلب، مفيش حاجة تقدر تطبعها تاني: الكود مش على ورق. اتأكد من الطابعة واضغط إعادة المحاولة، أو اختار السبب وغادر الطلب.'**
  String get unprintedDialogBody;

  /// Review: unprinted dialog reasons label.
  ///
  /// In ar, this message translates to:
  /// **'سبب مغادرة الطلب'**
  String get unprintedDialogReason;

  /// Leave reason printed_after_all.
  ///
  /// In ar, this message translates to:
  /// **'اتطبعت فعلاً والعميل استلمها'**
  String get leaveReasonPrintedAfterAll;

  /// Leave reason customer_left.
  ///
  /// In ar, this message translates to:
  /// **'العميل مشي من غيرها'**
  String get leaveReasonCustomerLeft;

  /// Review: unprinted dialog footnote.
  ///
  /// In ar, this message translates to:
  /// **'ده بيتسجل باسمك والسبب، وبيظهر للإدارة للمراجعة.'**
  String get unprintedDialogLogged;

  /// Review: leave with unprinted tickets.
  ///
  /// In ar, this message translates to:
  /// **'مغادرة الطلب'**
  String get unprintedLeave;

  /// Review banner: paid, but not every ticket is active and printed.
  ///
  /// In ar, this message translates to:
  /// **'تم التحصيل'**
  String get reviewPaidShortTitle;

  /// Review banner: some tickets refunded from the review.
  ///
  /// In ar, this message translates to:
  /// **'{active, plural, =1{تذكرة واحدة شغالة · {refunded} اتلغت واترجع مبلغها} =2{تذكرتين شغالين · {refunded} اتلغت واترجع مبلغها} few{{active} تذاكر شغالة · {refunded} اتلغت واترجع مبلغها} other{{active} تذكرة شغالة · {refunded} اتلغت واترجع مبلغها}}'**
  String reviewPartlyRefundedSubtitle(int active, int refunded);

  /// Review banner: every ticket refunded from the review.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{التذكرة اتلغت} =2{التذكرتين اتلغوا} other{التذاكر كلها اتلغت}}'**
  String reviewAllRefundedTitle(int count);

  /// Review banner: every ticket refunded.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{اترجع مبلغها للعميل} =2{اترجع مبلغهم للعميل} few{{count} تذاكر اتلغت واترجع مبلغها} other{{count} تذكرة اتلغت واترجع مبلغها}}'**
  String reviewAllRefundedSubtitle(int count);

  /// Review banner: some tickets left unprinted (ADR-0024).
  ///
  /// In ar, this message translates to:
  /// **'{printed} اتطبعت · {left} ما اتطبعتش (اتسجلت)'**
  String reviewLeftSubtitle(int printed, int left);

  /// Review bottom bar: print every failed ticket again (ADR-0023).
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{حاول تاني للتذكرة} =2{حاول تاني للتذكرتين} few{حاول تاني للـ{count} تذاكر} other{حاول تاني للـ{count} تذكرة}}'**
  String retryAllFailed(int count);

  /// Close shift header title (task 2.7).
  ///
  /// In ar, this message translates to:
  /// **'قفل الوردية #{number}'**
  String closeShiftTitle(int number);

  /// Close shift header subtitle: counter, opening time, now, cashier.
  ///
  /// In ar, this message translates to:
  /// **'{counter} · من {from} لحد {to} · {cashier}'**
  String closeShiftSubtitle(
    String counter,
    String from,
    String to,
    String cashier,
  );

  /// Close shift: blind count heading (ADR-0008).
  ///
  /// In ar, this message translates to:
  /// **'عدّ كل الفلوس اللي في الدرج'**
  String get countHeading;

  /// Close shift: blind count hint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب عدد الورق من كل فئة، شامل العهدة والإكراميات. تقدر تكتب العدد مباشرة أو تستخدم + و −.'**
  String get countHint;

  /// Close shift: a denomination's label, e.g. 200 ج.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ج'**
  String denominationLabel(String amount);

  /// Close shift: the count field's accessibility label.
  ///
  /// In ar, this message translates to:
  /// **'عدد ورق فئة {amount} جنيه'**
  String denominationCountLabel(String amount);

  /// Close shift: the counted total.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المعدود'**
  String get countedTotal;

  /// Close shift: tips section heading.
  ///
  /// In ar, this message translates to:
  /// **'الإكراميات'**
  String get tipsHeading;

  /// Close shift: tips section hint.
  ///
  /// In ar, this message translates to:
  /// **'اللي سجّلتها مع العملاء خلال الوردية. لو نسيت تسجّل إكرامية، ضيفها هنا قبل القفل.'**
  String get tipsHint;

  /// Close shift: no tips yet.
  ///
  /// In ar, this message translates to:
  /// **'مفيش إكراميات متسجلة في الوردية دي.'**
  String get tipsNone;

  /// Close shift: a tip recorded with an order.
  ///
  /// In ar, this message translates to:
  /// **'مع طلب #{number}'**
  String tipWithOrder(int number);

  /// Close shift: a tip added without an order.
  ///
  /// In ar, this message translates to:
  /// **'اتضافت وقت القفل'**
  String get tipAddedAtClose;

  /// Close shift: add tip box heading.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إكرامية منسية'**
  String get addTipHeading;

  /// Close shift: typed tip label.
  ///
  /// In ar, this message translates to:
  /// **'أو اكتب المبلغ (ج.م)'**
  String get addTipTypedLabel;

  /// Close shift: typed tip placeholder.
  ///
  /// In ar, this message translates to:
  /// **'مثلًا 35'**
  String get addTipTypedHint;

  /// Close shift: add the picked tip.
  ///
  /// In ar, this message translates to:
  /// **'إضافة {amount}'**
  String addTipButton(String amount);

  /// Close shift: add tip button with no amount picked.
  ///
  /// In ar, this message translates to:
  /// **'اختار مبلغ الإكرامية'**
  String get addTipButtonEmpty;

  /// Close shift: under the add tip button.
  ///
  /// In ar, this message translates to:
  /// **'الإكرامية بعد ما تتضاف مش بتتشال.'**
  String get addTipNote;

  /// Close shift: tips total with their count.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الإكراميات · {count}'**
  String tipsTotal(int count);

  /// Close shift: tips_enabled is off.
  ///
  /// In ar, this message translates to:
  /// **'الإكراميات مقفولة في الإعدادات.'**
  String get tipsDisabledNote;

  /// Close shift: add_tip refused invalid_tip.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ الإكرامية لازم يكون أكبر من صفر.'**
  String get tipFailureInvalid;

  /// Close shift: the main button.
  ///
  /// In ar, this message translates to:
  /// **'قفل الوردية وطباعة الملخص'**
  String get closeShiftButton;

  /// Close shift: under the main button.
  ///
  /// In ar, this message translates to:
  /// **'بعد القفل مفيش تعديل على العدّ أو الإكراميات.'**
  String get closeShiftNote;

  /// Close shift: orders awaiting payment block the close (ADR-0016).
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{فيه طلب لسه مستني الدفع} =2{فيه طلبين لسه مستنيين الدفع} few{فيه {count} طلبات لسه مستنية الدفع} other{فيه {count} طلب لسه مستنيين الدفع}}'**
  String closeAwaitingTitle(int count);

  /// Close shift: what to do about an order awaiting payment.
  ///
  /// In ar, this message translates to:
  /// **'أكّد الدفع أو الغي الطلب قبل القفل. لو مش ظاهر قدامك (مثلًا التطبيق اتقفل وانت على شاشة الدفع)، النظام هيلغيه لوحده بعد {minutes} دقيقة من البيع، وبعدها تقدر تقفل.'**
  String closeAwaitingBody(int minutes);

  /// Close shift: read the awaiting-payment count again.
  ///
  /// In ar, this message translates to:
  /// **'شوف تاني'**
  String get closeCheckAgain;

  /// Close shift: close_shift refused invalid_cash_count.
  ///
  /// In ar, this message translates to:
  /// **'العدّ فيه رقم غلط. راجع الأعداد وحاول تاني.'**
  String get closeFailureInvalidCount;

  /// Close shift: the shift was closed meanwhile (or the close's answer was lost).
  ///
  /// In ar, this message translates to:
  /// **'الوردية دي اتقفلت خلاص. الملخص مش هيتطبع من هنا؛ المشرف يقدر يشوفها في صفحة الورديات.'**
  String get closeFailureNoOpenShift;

  /// Close shift: confirm dialog title.
  ///
  /// In ar, this message translates to:
  /// **'قفل الوردية #{number}؟'**
  String closeConfirmTitle(int number);

  /// Close shift: confirm dialog body.
  ///
  /// In ar, this message translates to:
  /// **'النقدية المعدودة: {amount}. بعد القفل مفيش تعديل على العدّ أو الإكراميات.'**
  String closeConfirmBody(String amount);

  /// Close shift: confirm dialog, nothing counted.
  ///
  /// In ar, this message translates to:
  /// **'إنت ما عدّتش أي فلوس. اتأكد إن الدرج فاضي فعلًا.'**
  String get closeConfirmZero;

  /// Close shift: confirm dialog's close button.
  ///
  /// In ar, this message translates to:
  /// **'اقفل الوردية'**
  String get closeConfirmButton;

  /// After close: title.
  ///
  /// In ar, this message translates to:
  /// **'الوردية #{number} اتقفلت'**
  String closedTitle(int number);

  /// After close: receipt printing.
  ///
  /// In ar, this message translates to:
  /// **'بنطبع الملخص…'**
  String get receiptPrinting;

  /// After close: receipt printed.
  ///
  /// In ar, this message translates to:
  /// **'الملخص اتطبع. وقّع عليه وسلّمه مع الدرج للمشرف.'**
  String get receiptPrinted;

  /// After close: receipt print failed.
  ///
  /// In ar, this message translates to:
  /// **'الملخص ما اتطبعش. اتأكد من الطابعة (الورق، الكهربا) ودوس حاول تاني.'**
  String get receiptPrintFailed;

  /// After close: no printer set.
  ///
  /// In ar, this message translates to:
  /// **'مفيش طابعة متسجلة للشباك ده، فالملخص ما اتطبعش. المشرف يقدر يشوف الوردية في صفحة الورديات.'**
  String get receiptNoPrinter;

  /// After close: why to print before leaving.
  ///
  /// In ar, this message translates to:
  /// **'الملخص بيتطبع من هنا بس: بعد الخروج مش هتقدر تطبعه تاني.'**
  String get receiptOnlyHere;

  /// After close: sign out.
  ///
  /// In ar, this message translates to:
  /// **'تمام، خروج'**
  String get closedDone;

  /// After close: leaving with the receipt not printed.
  ///
  /// In ar, this message translates to:
  /// **'تخرج من غير الملخص المطبوع؟'**
  String get closedLeaveTitle;

  /// After close: leaving with the receipt not printed.
  ///
  /// In ar, this message translates to:
  /// **'مش هتقدر تطبعه بعد كده. المشرف يقدر يشوف الوردية في صفحة الورديات.'**
  String get closedLeaveBody;

  /// After close: leave without the receipt.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get closedLeave;

  /// Printed receipt: title.
  ///
  /// In ar, this message translates to:
  /// **'إقرار قفل الوردية'**
  String get receiptTitle;

  /// Printed receipt: shift row label.
  ///
  /// In ar, this message translates to:
  /// **'الوردية'**
  String get receiptShift;

  /// Printed receipt: shift number and counter.
  ///
  /// In ar, this message translates to:
  /// **'#{number} · {counter}'**
  String receiptShiftValue(int number, String counter);

  /// Printed receipt: cashier row label.
  ///
  /// In ar, this message translates to:
  /// **'الكاشير'**
  String get receiptCashier;

  /// Printed receipt: opened at.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get receiptFrom;

  /// Printed receipt: closed at.
  ///
  /// In ar, this message translates to:
  /// **'لحد'**
  String get receiptTo;

  /// Printed receipt: tickets heading.
  ///
  /// In ar, this message translates to:
  /// **'التذاكر المباعة'**
  String get receiptTicketsSold;

  /// Printed receipt: tickets total with the paid orders count.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي · {orders} طلب'**
  String receiptTicketsTotal(int orders);

  /// Printed receipt: statement heading.
  ///
  /// In ar, this message translates to:
  /// **'إقرار الكاشير'**
  String get receiptStatement;

  /// Printed receipt: counted cash.
  ///
  /// In ar, this message translates to:
  /// **'النقدية المعدودة'**
  String get receiptCounted;

  /// Printed receipt: tips total with their count.
  ///
  /// In ar, this message translates to:
  /// **'منها إكراميات ({count})'**
  String receiptTips(int count);

  /// Printed receipt: tips added at close.
  ///
  /// In ar, this message translates to:
  /// **'إكراميات اتضافت وقت القفل'**
  String get receiptTipsAtClose;

  /// Printed receipt: action count.
  ///
  /// In ar, this message translates to:
  /// **'إعادة طباعة'**
  String get receiptReprints;

  /// Printed receipt: action count.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تفعيل'**
  String get receiptReactivations;

  /// Printed receipt: action count.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء واسترداد'**
  String get receiptRefunds;

  /// Printed receipt: cancelled orders count.
  ///
  /// In ar, this message translates to:
  /// **'طلبات اتلغت'**
  String get receiptCancelledOrders;

  /// Printed receipt: left_unprinted count (ADR-0024).
  ///
  /// In ar, this message translates to:
  /// **'تذاكر ما اتطبعتش'**
  String get receiptLeftUnprinted;

  /// Printed receipt: footer (ADR-0008).
  ///
  /// In ar, this message translates to:
  /// **'المطابقة مع المتوقع بيعملها المشرف في النظام'**
  String get receiptFooter;

  /// Printed receipt: signature line.
  ///
  /// In ar, this message translates to:
  /// **'توقيع الكاشير'**
  String get receiptCashierSignature;

  /// Printed receipt: signature line.
  ///
  /// In ar, this message translates to:
  /// **'توقيع المشرف'**
  String get receiptSupervisorSignature;

  /// Header badge: the health check reaches the server (ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'متصل بالسيرفر'**
  String get serverBadgeOnline;

  /// Header badge: the server doesn't answer; selling goes on offline (ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال بالسيرفر'**
  String get serverBadgeOffline;

  /// Header badge: before the first health check.
  ///
  /// In ar, this message translates to:
  /// **'بنفحص الاتصال…'**
  String get serverBadgeChecking;

  /// Sell flow banner while offline (ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'شغالين أوفلاين: البيع بس، الدفع الأول وبعدين الطباعة'**
  String get offlineBannerTitle;

  /// Sell flow banner while offline: what happens to the orders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات بتتحفظ على الجهاز ده وبتترفع لوحدها أول ما السيرفر يرجع.'**
  String get offlineBannerBody;

  /// Offline banner: pool codes left to sell with.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش أكواد أوفلاين} =1{فاضل كود أوفلاين واحد} =2{فاضل كودين أوفلاين} few{فاضل {count} أكواد أوفلاين} other{فاضل {count} كود أوفلاين}}'**
  String offlineFreeCodes(int count);

  /// Banner: offline orders not uploaded yet.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{طلب مستني يترفع} =2{طلبين مستنيين يترفعوا} few{{count} طلبات مستنية تترفع} other{{count} طلب مستنيين يترفعوا}}'**
  String offlineQueuePending(int count);

  /// Banner: an upload is running.
  ///
  /// In ar, this message translates to:
  /// **'بنرفع طلبات الأوفلاين…'**
  String get offlineQueueUploading;

  /// Banner: offline orders the server refused; a tap lists them.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{طلب السيرفر رفضه} =2{طلبين السيرفر رفضهم} few{{count} طلبات السيرفر رفضها} other{{count} طلب السيرفر رفضهم}}'**
  String offlineQueueRefused(int count);

  /// Banner: the pool top-up failed (e.g. no home gate).
  ///
  /// In ar, this message translates to:
  /// **'مفيش أكواد أوفلاين للشباك ده (ليه بوابة؟). كلّم الأدمن: من غيرها مش هتقدر تبيع لو الاتصال وقع.'**
  String get offlinePoolUnavailable;

  /// Refused orders dialog title.
  ///
  /// In ar, this message translates to:
  /// **'طلبات السيرفر رفضها'**
  String get offlineRefusedTitle;

  /// Refused orders dialog: what to do.
  ///
  /// In ar, this message translates to:
  /// **'دي اتباعت أو اتسجلت أوفلاين والسيرفر رفض رفعها. كلّم المشرف: الوردية مش هتتقفل غير لما تتحل.'**
  String get offlineRefusedBody;

  /// Refused orders dialog: one order.
  ///
  /// In ar, this message translates to:
  /// **'#{number} أوفلاين · {time} · {reason}'**
  String offlineRefusedRow(int number, String time, String reason);

  /// Refusal reason code_not_in_pool.
  ///
  /// In ar, this message translates to:
  /// **'الكود مش من أكواد الشباك'**
  String get offlineRefusalCodeNotInPool;

  /// Refusal reason invalid_sold_at.
  ///
  /// In ar, this message translates to:
  /// **'وقت البيع مش مظبوط مع الوردية (ساعة الجهاز مظبوطة؟)'**
  String get offlineRefusalSoldAt;

  /// Refused orders dialog: one logged action.
  ///
  /// In ar, this message translates to:
  /// **'{action} · {code} · {time} · {reason}'**
  String offlineRefusedActionRow(
    String action,
    String code,
    String time,
    String reason,
  );

  /// Banner: reprints and unprinted tickets logged offline, not uploaded yet (ADR-0026).
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{إجراء متسجل مستني يترفع} =2{إجراءين متسجلين مستنيين يترفعوا} few{{count} إجراءات متسجلة مستنية تترفع} other{{count} إجراء متسجل مستنيين يترفعوا}}'**
  String offlineQueueActions(int count);

  /// Close shift: logged actions not uploaded block the close (ADR-0026).
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{فيه إجراء متسجل لسه ما اترفعش} =2{فيه إجراءين متسجلين لسه ما اترفعوش} few{فيه {count} إجراءات متسجلة لسه ما اترفعتش} other{فيه {count} إجراء متسجل لسه ما اترفعوش}}'**
  String closeQueueActionsTitle(int count);

  /// Refusal reason ticket_type_unavailable.
  ///
  /// In ar, this message translates to:
  /// **'نوع تذكرة مش معروف'**
  String get offlineRefusalTypeUnavailable;

  /// Refusal reason without its own text: the server's key.
  ///
  /// In ar, this message translates to:
  /// **'خطأ: {key}'**
  String offlineRefusalOther(String key);

  /// Tooltip on a button disabled while offline.
  ///
  /// In ar, this message translates to:
  /// **'محتاج السيرفر'**
  String get needsServer;

  /// Sell screen: sell_tickets didn't reach the server.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال بالسيرفر وقع. اضغط طباعة التذاكر والتحصيل تاني عشان تبيع أوفلاين.'**
  String get sellConnectionLost;

  /// Sell screen: offline_pool_size is 0.
  ///
  /// In ar, this message translates to:
  /// **'البيع أوفلاين مقفول من الإعدادات. استنى السيرفر يرجع.'**
  String get sellFailureOfflineDisabled;

  /// Sell screen: fewer pool codes than tickets.
  ///
  /// In ar, this message translates to:
  /// **'أكواد الأوفلاين مش كفاية للطلب ده. بيع تذاكر أقل، أو استنى السيرفر يرجع.'**
  String get sellFailureOfflinePoolEmpty;

  /// Sell screen: the PC's time zone doesn't match the pool's closing time.
  ///
  /// In ar, this message translates to:
  /// **'توقيت الجهاز ده مش توقيت المكان، فتذاكر اليوم ما تتباعش أوفلاين. كلّم الأدمن يظبط توقيت الجهاز.'**
  String get sellFailureOfflineZone;

  /// Payment: heading of an offline order.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الطلب #{number} (أوفلاين)'**
  String orderSummaryOffline(int number);

  /// Payment, offline: replaces the print status (charge first, ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'التذاكر هتتطبع بعد تأكيد التحصيل'**
  String get offlinePrintTitle;

  /// Payment, offline: under the title.
  ///
  /// In ar, this message translates to:
  /// **'إحنا أوفلاين: استلم الفلوس الأول. بعد التأكيد التذاكر بتتطبع مدفوعة وشغالة.'**
  String get offlinePrintHint;

  /// Payment, offline: under the Back button that replaces cancel.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش حاجة اتسجلت'**
  String get offlineBackHint;

  /// Review header of an offline order.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة طلب #{number} (أوفلاين)'**
  String reviewTitleOffline(int number);

  /// Review, offline order: under the tickets.
  ///
  /// In ar, this message translates to:
  /// **'الطلب ده اتباع أوفلاين وهيترفع للسيرفر لوحده أول ما الاتصال يرجع. إعادة الطباعة بتتسجل وتترفع بعده، والإلغاء والاسترجاع محتاجين السيرفر.'**
  String get reviewOfflineNote;

  /// Review, offline order: why Leave anyway is disabled.
  ///
  /// In ar, this message translates to:
  /// **'هيتسجل على الجهاز ده بالسبب ويتعلّم للمشرف، ويترفع لما السيرفر يرجع.'**
  String get unprintedDialogOffline;

  /// Printed ticket: an offline order's local number and this ticket's place.
  ///
  /// In ar, this message translates to:
  /// **'#{number} أوفلاين · {index} من {count}'**
  String ticketOrderValueOffline(String number, String index, String count);

  /// Close shift: offline orders not uploaded block the close (ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{فيه طلب أوفلاين لسه ما اترفعش} =2{فيه طلبين أوفلاين لسه ما اترفعوش} few{فيه {count} طلبات أوفلاين لسه ما اترفعتش} other{فيه {count} طلب أوفلاين لسه ما اترفعوش}}'**
  String closeQueueTitle(int count);

  /// Close shift: the queue uploads by itself.
  ///
  /// In ar, this message translates to:
  /// **'الوردية تتقفل بعد ما يترفعوا. بيترفعوا لوحدهم طول ما السيرفر بيرد.'**
  String get closeQueueBody;

  /// Close shift: some queued orders were refused.
  ///
  /// In ar, this message translates to:
  /// **'السيرفر رفض بعضهم: كلّم المشرف. الوردية مش هتتقفل غير لما يتحلوا.'**
  String get closeQueueRefusedBody;

  /// Close shift: runs the upload now.
  ///
  /// In ar, this message translates to:
  /// **'ارفع دلوقتي'**
  String get uploadNow;

  /// Admin side menu: the title next to the logo.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get adminMenuTitle;

  /// Admin menu item and dashboard title.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المتابعة'**
  String get navDashboard;

  /// Admin menu item.
  ///
  /// In ar, this message translates to:
  /// **'الورديات'**
  String get navShifts;

  /// Admin menu item.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get navReports;

  /// Admin menu item (admins only).
  ///
  /// In ar, this message translates to:
  /// **'أنواع التذاكر والأسعار'**
  String get navTicketTypes;

  /// Admin menu item.
  ///
  /// In ar, this message translates to:
  /// **'سجل الإجراءات'**
  String get navActionsLog;

  /// Admin menu item (admins only); also the dashboard's gates heading.
  ///
  /// In ar, this message translates to:
  /// **'البوابات'**
  String get navGates;

  /// Admin menu item (admins only).
  ///
  /// In ar, this message translates to:
  /// **'المستخدمين'**
  String get navUsers;

  /// Admin menu item (admins only).
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get navSettings;

  /// Dashboard subtitle while the live channel is joined.
  ///
  /// In ar, this message translates to:
  /// **'{date} · بتتحدث لحظيًا'**
  String dashboardDateLive(String date);

  /// Dashboard subtitle while the live channel is down.
  ///
  /// In ar, this message translates to:
  /// **'{date} · بتتحدث كل {seconds} ثانية'**
  String dashboardDatePolling(String date, int seconds);

  /// Dashboard chip: new scans show within seconds.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get dashboardLive;

  /// Dashboard chip: the live channel is down; the page still refreshes on a timer.
  ///
  /// In ar, this message translates to:
  /// **'مش لحظي'**
  String get dashboardNotLive;

  /// Dashboard KPI: accepted scans today.
  ///
  /// In ar, this message translates to:
  /// **'الدخول النهارده'**
  String get dashboardEntriesToday;

  /// Dashboard KPI note: time of the first entry today.
  ///
  /// In ar, this message translates to:
  /// **'من {time}'**
  String dashboardSince(String time);

  /// Dashboard KPI note: no entry today.
  ///
  /// In ar, this message translates to:
  /// **'لسه محدش دخل'**
  String get dashboardNoEntriesYet;

  /// Dashboard KPI: paid today minus refunded today.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات النهارده'**
  String get dashboardSalesToday;

  /// Dashboard KPI note: open shifts.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش شبابيك شغالة} =1{شباك واحد شغال} =2{شباكين شغالين} few{{count} شبابيك شغالة} other{{count} شباك شغال}}'**
  String dashboardOpenCounters(int count);

  /// Dashboard KPI: tickets of orders paid today.
  ///
  /// In ar, this message translates to:
  /// **'تذاكر مباعة'**
  String get dashboardTicketsSold;

  /// Dashboard KPI note: sold today, never scanned in.
  ///
  /// In ar, this message translates to:
  /// **'{count} لسه ما دخلتش'**
  String dashboardNotEntered(int count);

  /// Dashboard KPI: rejected scans today.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض على البوابات'**
  String get dashboardRejected;

  /// Dashboard KPI note: no rejected scan today.
  ///
  /// In ar, this message translates to:
  /// **'مفيش رفض النهارده'**
  String get dashboardNoRejections;

  /// Dashboard KPI note: one rejection reason with its count.
  ///
  /// In ar, this message translates to:
  /// **'{count} {reason}'**
  String dashboardReasonCount(int count, String reason);

  /// Gate card chip: heartbeat is recent.
  ///
  /// In ar, this message translates to:
  /// **'شغالة'**
  String get gateOnline;

  /// Gate card chip: no heartbeat for gate_offline_after_seconds.
  ///
  /// In ar, this message translates to:
  /// **'مش متصلة'**
  String get gateOffline;

  /// Gate card chip: the gate service never beat for this gate.
  ///
  /// In ar, this message translates to:
  /// **'ما اتصلتش'**
  String get gateNeverSeen;

  /// Gate card chip: gate switched off by an admin.
  ///
  /// In ar, this message translates to:
  /// **'متوقفة'**
  String get gateDisabled;

  /// Gate card row.
  ///
  /// In ar, this message translates to:
  /// **'دخول اليوم'**
  String get gateEntriesToday;

  /// Gate card row.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get gateRejected;

  /// Gate card: age of the last scan, under a minute.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{آخر مسح من ثانية} =2{آخر مسح من ثانيتين} few{آخر مسح من {count} ثواني} other{آخر مسح من {count} ثانية}}'**
  String gateLastScanSeconds(int count);

  /// Gate card: age of the last scan, under an hour.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{آخر مسح من دقيقة} =2{آخر مسح من دقيقتين} few{آخر مسح من {count} دقايق} other{آخر مسح من {count} دقيقة}}'**
  String gateLastScanMinutes(int count);

  /// Gate card: the last scan's time, an hour ago or more.
  ///
  /// In ar, this message translates to:
  /// **'آخر مسح {time}'**
  String gateLastScanAt(String time);

  /// Gate card: the gate never had a scan.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مسح لسه'**
  String get gateNoScans;

  /// Gate card: an offline gate's last heartbeat.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال من {time} · راجع الكهربا والشبكة'**
  String gateOfflineSince(String time);

  /// Gate card: a gate with no heartbeat ever.
  ///
  /// In ar, this message translates to:
  /// **'خدمة البوابة ما اتصلتش بالسيرفر · راجع إنها شغالة'**
  String get gateNeverSeenNote;

  /// Gate card: a disabled gate.
  ///
  /// In ar, this message translates to:
  /// **'متوقفة من صفحة البوابات'**
  String get gateDisabledNote;

  /// Dashboard: no entry gate exists.
  ///
  /// In ar, this message translates to:
  /// **'مفيش بوابات دخول متسجلة'**
  String get dashboardNoGates;

  /// Dashboard section heading.
  ///
  /// In ar, this message translates to:
  /// **'الدخول بالساعة'**
  String get dashboardHourlyTitle;

  /// Dashboard chart: screen reader label.
  ///
  /// In ar, this message translates to:
  /// **'عدد الداخلين في كل ساعة النهارده'**
  String get dashboardHourlyLabel;

  /// Dashboard chart: nothing to draw.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش دخول النهارده'**
  String get dashboardHourlyEmpty;

  /// Dashboard section heading.
  ///
  /// In ar, this message translates to:
  /// **'آخر عمليات المسح'**
  String get dashboardFeedTitle;

  /// Dashboard feed: no scan at all.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش مسح'**
  String get dashboardFeedEmpty;

  /// Dashboard feed chip: accepted scan.
  ///
  /// In ar, this message translates to:
  /// **'اتقبلت'**
  String get feedAccepted;

  /// Dashboard feed: a pool code whose sale hasn't uploaded yet.
  ///
  /// In ar, this message translates to:
  /// **'كود أوفلاين'**
  String get feedPoolCode;

  /// Dashboard banner: the last refresh failed; older figures stay on screen.
  ///
  /// In ar, this message translates to:
  /// **'مش قادر يوصل للسيرفر. آخر تحديث {time}.'**
  String dashboardStale(String time);

  /// Dashboard: the first load failed.
  ///
  /// In ar, this message translates to:
  /// **'مش قادر يوصل للسيرفر.'**
  String get dashboardUnreachable;

  /// Dashboard: an unexpected server answer.
  ///
  /// In ar, this message translates to:
  /// **'اللوحة ما اتحمّلتش. حاول تاني، ولو المشكلة فضلت كلّم الدعم.'**
  String get dashboardUnexpected;

  /// Dashboard: the server refused the role.
  ///
  /// In ar, this message translates to:
  /// **'اللوحة دي للمشرفين والمديرين بس.'**
  String get dashboardNotAllowed;

  /// Shifts page title.
  ///
  /// In ar, this message translates to:
  /// **'الورديات ومطابقة النقدية'**
  String get shiftsTitle;

  /// Shifts page subtitle (blind count, ADR-0008).
  ///
  /// In ar, this message translates to:
  /// **'الكاشير بيعدّ من غير ما يعرف المتوقع. المطابقة والاعتماد هنا بس.'**
  String get shiftsSubtitle;

  /// Shifts period chip.
  ///
  /// In ar, this message translates to:
  /// **'النهارده'**
  String get shiftsPeriodToday;

  /// Shifts period chip.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get shiftsPeriodYesterday;

  /// Shifts period chip.
  ///
  /// In ar, this message translates to:
  /// **'آخر 7 أيام'**
  String get shiftsPeriodWeek;

  /// Shifts chip: every closed shift not approved yet, any date.
  ///
  /// In ar, this message translates to:
  /// **'محتاجة مطابقة ({count})'**
  String shiftsPeriodPending(int count);

  /// Shifts page: read everything again.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get shiftsRefresh;

  /// Shifts table column.
  ///
  /// In ar, this message translates to:
  /// **'الوردية'**
  String get shiftsColShift;

  /// Shifts table column.
  ///
  /// In ar, this message translates to:
  /// **'الكاشير · الشباك'**
  String get shiftsColCashier;

  /// Shifts table column.
  ///
  /// In ar, this message translates to:
  /// **'المتوقع'**
  String get shiftsColExpected;

  /// Shifts table column.
  ///
  /// In ar, this message translates to:
  /// **'المعدود'**
  String get shiftsColCounted;

  /// Shifts table column.
  ///
  /// In ar, this message translates to:
  /// **'الفرق'**
  String get shiftsColDifference;

  /// Shifts table column.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get shiftsColStatus;

  /// Shifts table: none.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ورديات في الفترة دي.'**
  String get shiftsEmpty;

  /// Shifts table: none to approve.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ورديات مستنية اعتماد.'**
  String get shiftsEmptyPending;

  /// Shifts detail: nothing selected.
  ///
  /// In ar, this message translates to:
  /// **'اختار وردية من الجدول.'**
  String get shiftsPickOne;

  /// Shifts detail heading.
  ///
  /// In ar, this message translates to:
  /// **'وردية #{number}'**
  String shiftTitle(int number);

  /// A shift's times while it is open.
  ///
  /// In ar, this message translates to:
  /// **'{from} → مفتوحة'**
  String shiftUntilOpen(String from);

  /// Shift status chip.
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة'**
  String get shiftStatusOpen;

  /// Shift status chip: closed, not approved.
  ///
  /// In ar, this message translates to:
  /// **'محتاجة مطابقة'**
  String get shiftStatusNeedsApproval;

  /// Shift status chip.
  ///
  /// In ar, this message translates to:
  /// **'معتمدة'**
  String get shiftStatusApproved;

  /// Shifts detail line.
  ///
  /// In ar, this message translates to:
  /// **'عهدة البداية'**
  String get shiftOpeningFloat;

  /// Shifts detail line.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات نقدية'**
  String get shiftCashSales;

  /// Shifts detail line.
  ///
  /// In ar, this message translates to:
  /// **'إكراميات مسجّلة · {count}'**
  String shiftTips(int count);

  /// Shifts detail line.
  ///
  /// In ar, this message translates to:
  /// **'مرتجعات نقدية'**
  String get shiftCashRefunds;

  /// Shifts detail line.
  ///
  /// In ar, this message translates to:
  /// **'المتوقع في الدرج'**
  String get shiftExpected;

  /// Shifts detail line.
  ///
  /// In ar, this message translates to:
  /// **'اللي الكاشير عدّه'**
  String get shiftCounted;

  /// Shifts difference box: 0.
  ///
  /// In ar, this message translates to:
  /// **'مطابق'**
  String get shiftBalanced;

  /// Shifts difference box: counted less than expected.
  ///
  /// In ar, this message translates to:
  /// **'عجز'**
  String get shiftShortage;

  /// Shifts difference box: counted more than expected.
  ///
  /// In ar, this message translates to:
  /// **'زيادة'**
  String get shiftSurplus;

  /// Shifts detail: card and wallet totals.
  ///
  /// In ar, this message translates to:
  /// **'غير نقدي (للمعلومية): كارت {card} · محفظة {wallet}'**
  String shiftNonCash(String card, String wallet);

  /// Shifts detail: paid orders of every method.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات المدفوعة (كل طرق الدفع): {count}'**
  String shiftPaidOrders(int count);

  /// Shifts detail: the shift's ticket actions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات الوردية في السجل: {count}'**
  String shiftActions(int count);

  /// Shifts detail: the shift's ticket actions, some flagged.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات الوردية في السجل: {count} ({flagged} عليها علامة مراجعة)'**
  String shiftActionsFlagged(int count, int flagged);

  /// Shifts detail: an open shift.
  ///
  /// In ar, this message translates to:
  /// **'الوردية لسه مفتوحة. المطابقة بتظهر بعد ما الكاشير يقفلها ويعدّ.'**
  String get shiftOpenNote;

  /// Shifts detail: who approved it.
  ///
  /// In ar, this message translates to:
  /// **'اعتمدها {name} · {time}'**
  String shiftApprovedBy(String name, String time);

  /// Shifts detail: the approval comment.
  ///
  /// In ar, this message translates to:
  /// **'التعليق: {comment}'**
  String shiftApprovalComment(String comment);

  /// Approval comment label, no difference.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get shiftNoteOptional;

  /// Approval comment label when there is a difference.
  ///
  /// In ar, this message translates to:
  /// **'تعليق على الفرق (إجباري)'**
  String get shiftNoteRequired;

  /// Approve button.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد الوردية'**
  String get shiftApprove;

  /// Shifts detail: nobody approves their own shift (ADR-0017).
  ///
  /// In ar, this message translates to:
  /// **'دي ورديتك، فمينفعش تعتمدها. لازم مشرف أو مدير تاني.'**
  String get shiftOwnShift;

  /// Snack bar after an approval.
  ///
  /// In ar, this message translates to:
  /// **'الوردية #{number} اتعتمدت.'**
  String shiftApprovedDone(int number);

  /// Shifts detail: the shift's offline orders.
  ///
  /// In ar, this message translates to:
  /// **'طلبات أوفلاين اترفعت: {count}'**
  String shiftOfflineOrders(int count);

  /// Shifts detail: pool entries without a sale yet (ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'أكواد أوفلاين دخلت قبل ما بيعها يترفع: {count}'**
  String shiftUnsyncedEntries(int count);

  /// Shifts detail: refused offline orders (ADR-0026).
  ///
  /// In ar, this message translates to:
  /// **'طلبات أوفلاين السيرفر رفضها: {count}. فلوسها في الدرج بس مش في الأرقام، فبتبان في الفرق.'**
  String shiftRefusedOrders(int count);

  /// Shifts detail: refused offline orders and actions.
  ///
  /// In ar, this message translates to:
  /// **'اترفض وهو بيترفع'**
  String get refusalsTitle;

  /// Refusal kind.
  ///
  /// In ar, this message translates to:
  /// **'طلب أوفلاين'**
  String get refusalKindOrder;

  /// Refusal kind.
  ///
  /// In ar, this message translates to:
  /// **'إجراء أوفلاين'**
  String get refusalKindAction;

  /// When the refusal reached the server.
  ///
  /// In ar, this message translates to:
  /// **'وصل {time}'**
  String refusalReportedAt(String time);

  /// What a refused order sent.
  ///
  /// In ar, this message translates to:
  /// **'اتباع {time} · {method} · {tickets}'**
  String refusalOrderSummary(String time, String method, String tickets);

  /// A refused order's ticket count.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{تذكرة واحدة} =2{تذكرتين} few{{count} تذاكر} other{{count} تذكرة}}'**
  String refusalTicketCount(int count);

  /// A refused order's ticket type the server doesn't know.
  ///
  /// In ar, this message translates to:
  /// **'نوع مش معروف'**
  String get refusalUnknownType;

  /// A refused order's tip.
  ///
  /// In ar, this message translates to:
  /// **'إكرامية {amount}'**
  String refusalTip(String amount);

  /// A refused offline action: left unprinted.
  ///
  /// In ar, this message translates to:
  /// **'تذكرة ما اتطبعتش'**
  String get refusalLeftUnprinted;

  /// An open refusal.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح: الكاشير مش هيقدر يقفل الوردية غير لما يتمسح.'**
  String get refusalOpen;

  /// A refusal a later upload accepted.
  ///
  /// In ar, this message translates to:
  /// **'اترفع بعد كده.'**
  String get refusalAccepted;

  /// A refusal a supervisor cleared.
  ///
  /// In ar, this message translates to:
  /// **'مسحه {name} · {time}: {comment}'**
  String refusalCleared(String name, String time, String comment);

  /// Clear a refusal button.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get refusalClear;

  /// Nobody clears their own shift's refusal.
  ///
  /// In ar, this message translates to:
  /// **'دي ورديتك، فمينفعش تمسح الرفض.'**
  String get refusalOwnShift;

  /// Clear dialog title.
  ///
  /// In ar, this message translates to:
  /// **'مسح الرفض'**
  String get refusalClearTitle;

  /// Clear dialog body.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اللي عملته. اللي اتبعت مش هيترفع، وفلوس الطلب المرفوض هتفضل باينة في فرق الوردية.'**
  String get refusalClearBody;

  /// Clear dialog comment field.
  ///
  /// In ar, this message translates to:
  /// **'التعليق (إجباري)'**
  String get refusalCommentLabel;

  /// Shifts page: pool entries no shift counts.
  ///
  /// In ar, this message translates to:
  /// **'دخول من غير وردية'**
  String get orphansTitle;

  /// Shifts page: what an orphan entry is.
  ///
  /// In ar, this message translates to:
  /// **'أكواد أوفلاين دخلت وشباكها مكانش عليه وردية مفتوحة. مش محسوبة على أي وردية، ومفيش بيع هييجي ليها.'**
  String get orphansHint;

  /// Shifts: the server refused the role.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة دي للمشرفين والمديرين بس.'**
  String get shiftsNotAllowed;

  /// Shifts: unexpected failure.
  ///
  /// In ar, this message translates to:
  /// **'الورديات ما اتحملتش. جرّب تاني، ولو فضلت كده كلّم الدعم.'**
  String get shiftsUnexpected;

  /// Shifts detail: load failed.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الوردية ما اتحملتش.'**
  String get shiftDetailFailed;

  /// Approve/clear: no comment.
  ///
  /// In ar, this message translates to:
  /// **'التعليق إجباري.'**
  String get shiftFailureCommentRequired;

  /// Approve/clear: own shift.
  ///
  /// In ar, this message translates to:
  /// **'مينفعش تعتمد أو تمسح حاجة في ورديتك.'**
  String get shiftFailureOwnShift;

  /// Approve: already approved.
  ///
  /// In ar, this message translates to:
  /// **'الوردية دي اتعتمدت قبل كده.'**
  String get shiftFailureAlreadyApproved;

  /// Approve: still open.
  ///
  /// In ar, this message translates to:
  /// **'الوردية لسه مفتوحة.'**
  String get shiftFailureNotClosed;

  /// Clear: already closed.
  ///
  /// In ar, this message translates to:
  /// **'الرفض ده اتقفل قبل كده.'**
  String get shiftFailureRefusalClosed;

  /// Approve/clear: not found.
  ///
  /// In ar, this message translates to:
  /// **'مش لاقي الوردية دي.'**
  String get shiftFailureNotFound;

  /// Actions log subtitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الطباعة وإعادة التفعيل والإلغاء اللي عملها الكاشيرية من غير موافقة'**
  String get actionsSubtitle;

  /// Actions log: export button.
  ///
  /// In ar, this message translates to:
  /// **'تصدير CSV'**
  String get actionsExport;

  /// Actions log: refresh button tooltip.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get actionsRefresh;

  /// Actions log tile: open reviews.
  ///
  /// In ar, this message translates to:
  /// **'محتاجة مراجعة'**
  String get actionsTileReview;

  /// Actions log filter bar label.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get actionsShow;

  /// Actions log chip: every flagged, unreviewed action, any date.
  ///
  /// In ar, this message translates to:
  /// **'محتاجة مراجعة ({count})'**
  String actionsPeriodReview(int count);

  /// Actions log: the shift the log is narrowed to (from the Shifts page).
  ///
  /// In ar, this message translates to:
  /// **'وردية #{number} · {cashier} · {counter}'**
  String actionsShiftChip(int number, String cashier, String counter);

  /// Actions log: leave the one shift's log.
  ///
  /// In ar, this message translates to:
  /// **'كل الورديات'**
  String get actionsShiftClear;

  /// Actions log type chip.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get actionsTypeAll;

  /// Actions log type chip: offline sale times adjusted.
  ///
  /// In ar, this message translates to:
  /// **'أوفلاين'**
  String get actionsTypeOffline;

  /// Actions log cashier filter.
  ///
  /// In ar, this message translates to:
  /// **'كل الكاشيرية'**
  String get actionsAllCashiers;

  /// Actions log counter filter.
  ///
  /// In ar, this message translates to:
  /// **'كل الشبابيك'**
  String get actionsAllCounters;

  /// Actions log column.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get actionsColTime;

  /// Actions log column.
  ///
  /// In ar, this message translates to:
  /// **'الكاشير · الشباك'**
  String get actionsColWho;

  /// Actions log column.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء'**
  String get actionsColAction;

  /// Actions log column.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة'**
  String get actionsColTicket;

  /// Actions log column.
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get actionsColReason;

  /// Actions log column.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة'**
  String get actionsColReview;

  /// Logged action: an unpaid order cancelled.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء طلب'**
  String get actionCancelOrder;

  /// Logged action: the cashier left a paid order with a ticket that never printed.
  ///
  /// In ar, this message translates to:
  /// **'ما اتطبعتش'**
  String get actionLeftUnprinted;

  /// Logged action: an offline sale's time was corrected at upload.
  ///
  /// In ar, this message translates to:
  /// **'وقت أوفلاين اتعدّل'**
  String get actionOfflineAdjusted;

  /// Logged action: a gate test open.
  ///
  /// In ar, this message translates to:
  /// **'فتح تجريبي'**
  String get actionTestOpen;

  /// Logged action: a settings change.
  ///
  /// In ar, this message translates to:
  /// **'تغيير إعدادات'**
  String get actionSettingsChange;

  /// Actions log: the automatic cancel has no cashier.
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get actionsSystem;

  /// Actions log: a reprint's copy number.
  ///
  /// In ar, this message translates to:
  /// **'الطبعة {number}'**
  String actionsCopy(int number);

  /// Actions log: a reactivation's undone scan.
  ///
  /// In ar, this message translates to:
  /// **'المسح اللي اتلغى كان على {gate}'**
  String actionsUndoneGate(String gate);

  /// Actions log: an 'other' reason with its typed text.
  ///
  /// In ar, this message translates to:
  /// **'سبب آخر: \"{text}\"'**
  String actionsOtherReason(String text);

  /// Actions log: the note typed with a reason.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة: {text}'**
  String actionsReasonNote(String text);

  /// Actions log: an offline sale's claimed and stored times.
  ///
  /// In ar, this message translates to:
  /// **'وقت الجهاز {claimed} ← اتسجل {stored}'**
  String actionsOfflineTimes(String claimed, String stored);

  /// Why an offline sale's time was adjusted.
  ///
  /// In ar, this message translates to:
  /// **'ساعة الجهاز برّه وقت الوردية'**
  String get adjustClockOutOfRange;

  /// Why an offline sale's time was adjusted.
  ///
  /// In ar, this message translates to:
  /// **'بعد وقت القفل'**
  String get adjustAfterClosing;

  /// Why an offline sale's time was adjusted.
  ///
  /// In ar, this message translates to:
  /// **'الكود كان انتهى'**
  String get adjustCodeExpired;

  /// Review flag.
  ///
  /// In ar, this message translates to:
  /// **'سبب آخر'**
  String get flagOtherReason;

  /// Review flag: too many actions by one cashier in a shift.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{إجراء واحد للكاشير في الوردية} =2{إجراءين للكاشير في الوردية} few{{count} إجراءات للكاشير في الوردية} other{{count} إجراء للكاشير في الوردية}}'**
  String flagTooManyActions(int count);

  /// Review flag: a ticket printed too many times.
  ///
  /// In ar, this message translates to:
  /// **'{max, plural, =1{اتطبعت أكتر من مرة} =2{اتطبعت أكتر من مرتين} few{اتطبعت أكتر من {max} مرات} other{اتطبعت أكتر من {max} مرة}}'**
  String flagTooManyPrints(int max);

  /// Review flag: a reactivated ticket entered at a different gate.
  ///
  /// In ar, this message translates to:
  /// **'اتمسحت بعدها على بوابة تانية'**
  String get flagReactivatedOtherGate;

  /// Review flag: a ticket left unprinted (always flagged).
  ///
  /// In ar, this message translates to:
  /// **'التذكرة ما اتطبعتش'**
  String get flagUnprintedTicket;

  /// Review flag: an offline sale's time was corrected.
  ///
  /// In ar, this message translates to:
  /// **'وقت البيع اتعدّل'**
  String get flagOfflineTimeAdjusted;

  /// Review flag: a reprint made offline (always flagged).
  ///
  /// In ar, this message translates to:
  /// **'إعادة طباعة أوفلاين'**
  String get flagOfflineReprint;

  /// Actions log: mark a flagged action reviewed.
  ///
  /// In ar, this message translates to:
  /// **'تمت المراجعة'**
  String get actionsReviewButton;

  /// Actions log: who reviewed it.
  ///
  /// In ar, this message translates to:
  /// **'اتراجعت · {name}'**
  String actionsReviewedBy(String name);

  /// Actions log: nobody reviews their own action (ADR-0018).
  ///
  /// In ar, this message translates to:
  /// **'إجراءك، حد تاني يراجعه'**
  String get actionsOwnAction;

  /// Actions log: flag rules box title.
  ///
  /// In ar, this message translates to:
  /// **'إمتى الإجراء بيتعلّم للمراجعة'**
  String get actionsRulesTitle;

  /// Flag rule.
  ///
  /// In ar, this message translates to:
  /// **'السبب \"سبب آخر\"'**
  String get ruleOtherReason;

  /// Flag rule.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{أكتر من إجراء واحد لنفس الكاشير في وردية واحدة} =2{أكتر من إجراءين لنفس الكاشير في وردية واحدة} few{أكتر من {count} إجراءات لنفس الكاشير في وردية واحدة} other{أكتر من {count} إجراء لنفس الكاشير في وردية واحدة}}'**
  String ruleTooManyActions(int count);

  /// Flag rule.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تفعيل والتذكرة بعدها اتمسحت على بوابة تانية'**
  String get ruleReactivatedOtherGate;

  /// Flag rule.
  ///
  /// In ar, this message translates to:
  /// **'{max, plural, =1{تذكرة اتطبعت أكتر من مرة} =2{تذكرة اتطبعت أكتر من مرتين} few{تذكرة اتطبعت أكتر من {max} مرات} other{تذكرة اتطبعت أكتر من {max} مرة}}'**
  String ruleTooManyPrints(int max);

  /// Flag rule.
  ///
  /// In ar, this message translates to:
  /// **'دايماً: تذكرة الكاشير ساب طلبها من غير ما تتطبع'**
  String get ruleUnprinted;

  /// Flag rule.
  ///
  /// In ar, this message translates to:
  /// **'دايماً: بيع أوفلاين وقته اتعدّل، أو إعادة طباعة أوفلاين'**
  String get ruleOffline;

  /// Actions log: flag rules footnote.
  ///
  /// In ar, this message translates to:
  /// **'القواعد دي إعدادات تقدر تغيّرها من صفحة الإعدادات.'**
  String get actionsRulesFootnote;

  /// Actions log: empty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش إجراءات في الفترة دي.'**
  String get actionsEmpty;

  /// Actions log: no open review.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة محتاجة مراجعة.'**
  String get actionsEmptyReview;

  /// Actions log: the list was cut at the page limit.
  ///
  /// In ar, this message translates to:
  /// **'معروض أحدث {shown} من {total}. ضيّق البحث بالكاشير أو الشباك، أو صدّر CSV للكل.'**
  String actionsTruncated(int shown, int total);

  /// Actions log: not allowed.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة دي للمشرفين والإدارة بس.'**
  String get actionsNotAllowed;

  /// Actions log: unexpected failure.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ في تحميل السجل.'**
  String get actionsUnexpected;

  /// Review refused: own action.
  ///
  /// In ar, this message translates to:
  /// **'ما تقدرش تراجع إجراء عملته بنفسك.'**
  String get actionsFailureOwnAction;

  /// Review refused: already reviewed.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء ده اتراجع قبل كده.'**
  String get actionsFailureAlreadyReviewed;

  /// Review refused: not flagged.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء ده مش عليه علامة مراجعة.'**
  String get actionsFailureNotFlagged;

  /// Review or shift not found.
  ///
  /// In ar, this message translates to:
  /// **'مش لاقي الإجراء ده.'**
  String get actionsFailureNotFound;

  /// CSV export: the saved file.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظ الملف: {path}'**
  String actionsExported(String path);

  /// CSV export: show the file in Explorer.
  ///
  /// In ar, this message translates to:
  /// **'افتح المجلد'**
  String get actionsOpenFolder;

  /// CSV export: no folder.
  ///
  /// In ar, this message translates to:
  /// **'مش لاقي مجلد التنزيلات (Downloads) على الجهاز ده.'**
  String get actionsExportNoFolder;

  /// CSV export: write failed.
  ///
  /// In ar, this message translates to:
  /// **'الملف ما اتحفظش.'**
  String get actionsExportFailed;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get csvTime;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'الكاشير'**
  String get csvCashier;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'الشباك'**
  String get csvCounter;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'الوردية'**
  String get csvShift;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء'**
  String get csvAction;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'الطلب'**
  String get csvOrder;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'نوع التذكرة'**
  String get csvType;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'آخر 3 أرقام من الكود'**
  String get csvCode;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'الطبعة'**
  String get csvCopy;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ (ج.م)'**
  String get csvAmount;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get csvMethod;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get csvReason;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'نص السبب'**
  String get csvReasonText;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل'**
  String get csvDetails;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'علامات المراجعة'**
  String get csvFlags;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'راجعه'**
  String get csvReviewedBy;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'وقت المراجعة'**
  String get csvReviewedAt;

  /// The Reports page's title.
  ///
  /// In ar, this message translates to:
  /// **'تقرير المبيعات'**
  String get reportsTitle;

  /// Under the title: what the figures are (ADR-0032).
  ///
  /// In ar, this message translates to:
  /// **'الصافي = المبيعات − المرتجعات + الإكراميات. المرتجع والإكرامية بيتحسبوا في يومهم، والإكرامية مالهاش نوع تذكرة.'**
  String get reportsSubtitle;

  /// Filter bar label.
  ///
  /// In ar, this message translates to:
  /// **'الفترة'**
  String get reportsPeriod;

  /// Filter bar label.
  ///
  /// In ar, this message translates to:
  /// **'تجميع حسب'**
  String get reportsGroupBy;

  /// Period chip: the 1st of this month to today.
  ///
  /// In ar, this message translates to:
  /// **'الشهر ده'**
  String get reportsPeriodMonth;

  /// Period chip: the whole previous calendar month.
  ///
  /// In ar, this message translates to:
  /// **'الشهر اللي فات'**
  String get reportsPeriodLastMonth;

  /// Period chip that opens the date range picker.
  ///
  /// In ar, this message translates to:
  /// **'فترة تانية…'**
  String get reportsPeriodRange;

  /// Date range picker title.
  ///
  /// In ar, this message translates to:
  /// **'اختار أول وآخر يوم'**
  String get reportsRangeHelp;

  /// Group-by choice and column.
  ///
  /// In ar, this message translates to:
  /// **'نوع التذكرة'**
  String get reportsGroupType;

  /// Group-by choice and column.
  ///
  /// In ar, this message translates to:
  /// **'الكاشير'**
  String get reportsGroupCashier;

  /// Group-by choice and column.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get reportsGroupMethod;

  /// Group-by choice and column.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get reportsGroupDay;

  /// Tile: gross sales.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات'**
  String get reportsTileSales;

  /// Tile.
  ///
  /// In ar, this message translates to:
  /// **'المرتجعات'**
  String get reportsTileRefunds;

  /// Tile: sales minus refunds.
  ///
  /// In ar, this message translates to:
  /// **'الصافي'**
  String get reportsTileNet;

  /// Tile: tickets sold.
  ///
  /// In ar, this message translates to:
  /// **'التذاكر'**
  String get reportsTileTickets;

  /// Table and CSV column.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي التذاكر'**
  String get reportsColTickets;

  /// By cashier: table and CSV column, the counters sold at, each with the home gate printed on its tickets.
  ///
  /// In ar, this message translates to:
  /// **'الشباك والبوابة'**
  String get reportsColCounterGate;

  /// Reports: group by the gate printed on the tickets (4.4b); also the table's first column.
  ///
  /// In ar, this message translates to:
  /// **'البوابة'**
  String get reportsGroupGate;

  /// By gate: table and CSV column, the counters that sold tickets for the gate.
  ///
  /// In ar, this message translates to:
  /// **'الشبابيك'**
  String get reportsColCounters;

  /// By gate: the row of tickets with no gate printed (sold before counters had a home gate).
  ///
  /// In ar, this message translates to:
  /// **'من غير بوابة'**
  String get reportsNoGate;

  /// Table column.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات (ج.م)'**
  String get reportsColSales;

  /// Table column.
  ///
  /// In ar, this message translates to:
  /// **'المرتجعات (ج.م)'**
  String get reportsColRefunds;

  /// Table column.
  ///
  /// In ar, this message translates to:
  /// **'الصافي (ج.م)'**
  String get reportsColNet;

  /// Table column.
  ///
  /// In ar, this message translates to:
  /// **'النسبة من المبيعات'**
  String get reportsColShare;

  /// The table's and the CSV's totals row.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get reportsTotal;

  /// Under a refund amount: how many tickets.
  ///
  /// In ar, this message translates to:
  /// **'{count} تذكرة'**
  String reportsRefundCount(int count);

  /// The table with no rows.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مبيعات ولا مرتجعات في الفترة دي.'**
  String get reportsEmpty;

  /// While a report loads.
  ///
  /// In ar, this message translates to:
  /// **'بيتحسب التقرير… الفترات الطويلة بتاخد شوية وقت.'**
  String get reportsLoading;

  /// The server refused the caller.
  ///
  /// In ar, this message translates to:
  /// **'التقارير للمشرفين والأدمن بس.'**
  String get reportsNotAllowed;

  /// invalid_range.
  ///
  /// In ar, this message translates to:
  /// **'الفترة دي مش صحيحة. اختار أول يوم قبل آخر يوم.'**
  String get reportsInvalidRange;

  /// report_busy: one report at a time, so the gates come first.
  ///
  /// In ar, this message translates to:
  /// **'فيه تقرير تاني شغال دلوقتي. استنى لحظة وجرّب تاني.'**
  String get reportsBusy;

  /// Any other failure.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ غير متوقع في التقرير.'**
  String get reportsUnexpected;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات (ج.م)'**
  String get reportsCsvSales;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'تذاكر مرتجعة'**
  String get reportsCsvRefundCount;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'المرتجعات (ج.م)'**
  String get reportsCsvRefunds;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'الصافي (ج.م)'**
  String get reportsCsvNet;

  /// CSV column.
  ///
  /// In ar, this message translates to:
  /// **'النسبة من المبيعات (%)'**
  String get reportsCsvShare;

  /// Range dialog: the first day's calendar.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get reportsRangeFrom;

  /// Range dialog: the last day's calendar.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get reportsRangeTo;

  /// Range dialog: how many days are picked.
  ///
  /// In ar, this message translates to:
  /// **'{count} يوم'**
  String reportsRangeDays(int count);

  /// Range dialog: apply the dates.
  ///
  /// In ar, this message translates to:
  /// **'اعرض التقرير'**
  String get reportsRangeApply;

  /// 57014: the report reached its 120 s limit.
  ///
  /// In ar, this message translates to:
  /// **'التقرير خد وقت أطول من اللازم ووقف. اختار فترة أقصر.'**
  String get reportsTooSlow;

  /// Tile.
  ///
  /// In ar, this message translates to:
  /// **'الإكراميات'**
  String get reportsTileTips;

  /// Table column. A ticket type's row shows —.
  ///
  /// In ar, this message translates to:
  /// **'الإكراميات (ج.م)'**
  String get reportsColTips;

  /// CSV column. Empty on a ticket type's row.
  ///
  /// In ar, this message translates to:
  /// **'الإكراميات (ج.م)'**
  String get reportsCsvTips;

  /// Ticket types page: header button, and the panel title for a new type.
  ///
  /// In ar, this message translates to:
  /// **'نوع جديد'**
  String get typesNew;

  /// Ticket types table header.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get typesColType;

  /// Ticket types table header.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get typesColPrice;

  /// Ticket types table header.
  ///
  /// In ar, this message translates to:
  /// **'مرات الدخول'**
  String get typesColEntries;

  /// Ticket types table header.
  ///
  /// In ar, this message translates to:
  /// **'الصلاحية'**
  String get typesColValidity;

  /// Ticket types table header.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get typesColStatus;

  /// Ticket types table header: the up/down arrows (sell screen order).
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get typesColOrder;

  /// Entries allowed per ticket.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{مرة واحدة} =2{مرتين} few{{count} مرات} other{{count} مرة}}'**
  String typesEntries(int count);

  /// Validity: the day of sale until closing time.
  ///
  /// In ar, this message translates to:
  /// **'يوم البيع'**
  String get typesValiditySameDay;

  /// Validity: hours from the time of sale.
  ///
  /// In ar, this message translates to:
  /// **'{hours, plural, =1{ساعة من البيع} =2{ساعتين من البيع} few{{hours} ساعات من البيع} other{{hours} ساعة من البيع}}'**
  String typesValidityHours(int hours);

  /// Ticket type status chip; also a value in the actions log.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get typesStatusActive;

  /// Ticket type status chip; also a value in the actions log.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get typesStatusInactive;

  /// Tooltip: move the type up on the sell screen.
  ///
  /// In ar, this message translates to:
  /// **'لفوق'**
  String get typesMoveUp;

  /// Tooltip: move the type down on the sell screen.
  ///
  /// In ar, this message translates to:
  /// **'لتحت'**
  String get typesMoveDown;

  /// Edit panel title.
  ///
  /// In ar, this message translates to:
  /// **'تعديل: {name}'**
  String typesEditTitle(String name);

  /// Field label; also a changed field in the actions log.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالعربي'**
  String get typesNameAr;

  /// Field label; also a changed field in the actions log.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالإنجليزي'**
  String get typesNameEn;

  /// Field label.
  ///
  /// In ar, this message translates to:
  /// **'السعر (ج.م)'**
  String get typesPrice;

  /// Field label; also a changed field in the actions log.
  ///
  /// In ar, this message translates to:
  /// **'مرات الدخول'**
  String get typesEntriesLabel;

  /// Field label; also a changed field in the actions log.
  ///
  /// In ar, this message translates to:
  /// **'الصلاحية'**
  String get typesValidityLabel;

  /// Validity dropdown option.
  ///
  /// In ar, this message translates to:
  /// **'يوم البيع لحد قفل المكان'**
  String get typesValidityOptionSameDay;

  /// Validity dropdown option.
  ///
  /// In ar, this message translates to:
  /// **'عدد ساعات من وقت البيع'**
  String get typesValidityOptionHours;

  /// Field label, only for hours from sale.
  ///
  /// In ar, this message translates to:
  /// **'عدد الساعات'**
  String get typesHoursLabel;

  /// Switch label; also a changed field in the actions log.
  ///
  /// In ar, this message translates to:
  /// **'متاح للبيع'**
  String get typesActiveLabel;

  /// Under the on-sale switch.
  ///
  /// In ar, this message translates to:
  /// **'لو اتقفل، بيختفي من شاشة الكاشير'**
  String get typesActiveNote;

  /// Warning box in the edit panel.
  ///
  /// In ar, this message translates to:
  /// **'تغيير السعر بيسري على المبيعات الجديدة بس. التذاكر اللي اتباعت بتفضل بسعرها.'**
  String get typesPriceNote;

  /// Small note under the save button.
  ///
  /// In ar, this message translates to:
  /// **'كل تغيير بيتسجل في سجل الإجراءات.'**
  String get typesLogNote;

  /// Edit panel button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get typesSave;

  /// Edit panel button for a new type.
  ///
  /// In ar, this message translates to:
  /// **'إضافة النوع'**
  String get typesAdd;

  /// Snack bar after a save.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظ.'**
  String get typesSaved;

  /// First load.
  ///
  /// In ar, this message translates to:
  /// **'بيحمّل أنواع التذاكر…'**
  String get typesLoading;

  /// Empty list.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أنواع تذاكر لسه. أضف أول نوع.'**
  String get typesEmpty;

  /// Server refused: a blank name.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الاسم بالعربي والإنجليزي.'**
  String get typesInvalidName;

  /// Price field error.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سعر صحيح، مثلاً 100 أو 12.50.'**
  String get typesInvalidPrice;

  /// Entries field error.
  ///
  /// In ar, this message translates to:
  /// **'مرات الدخول لازم تكون 1 أو أكتر.'**
  String get typesInvalidEntries;

  /// Hours field error.
  ///
  /// In ar, this message translates to:
  /// **'عدد الساعات لازم يكون 1 أو أكتر.'**
  String get typesInvalidHours;

  /// Name field error (case and spaces ignored).
  ///
  /// In ar, this message translates to:
  /// **'فيه نوع تاني بالاسم ده.'**
  String get typesNameTaken;

  /// Save of a type that is gone.
  ///
  /// In ar, this message translates to:
  /// **'النوع ده مبقاش موجود. القائمة اتحدّثت.'**
  String get typesNotFound;

  /// Not an admin.
  ///
  /// In ar, this message translates to:
  /// **'أنواع التذاكر والأسعار للأدمن بس.'**
  String get typesNotAllowed;

  /// Any other failure.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ غير متوقع في أنواع التذاكر.'**
  String get typesUnexpected;

  /// Actions log type chip: settings and ticket type changes.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get actionsTypeSettings;

  /// Actions log: a ticket type was added.
  ///
  /// In ar, this message translates to:
  /// **'نوع جديد: {name}'**
  String changeNewType(String name);

  /// Actions log: the type a change is about.
  ///
  /// In ar, this message translates to:
  /// **'نوع التذكرة {name}'**
  String changeTypeName(String name);

  /// Actions log: one changed value. Words, not an arrow, in Arabic (RTL).
  ///
  /// In ar, this message translates to:
  /// **'{field}: من {from} لـ {to}'**
  String changeField(String field, String from, String to);

  /// Sell: ticket_type_not_now (peak times, ADR-0033).
  ///
  /// In ar, this message translates to:
  /// **'الفئة دي مش متاحة دلوقتي. القائمة اتحدّثت، راجع الطلب.'**
  String get sellFailureTypeNotNow;

  /// Sell header chip while it is peak.
  ///
  /// In ar, this message translates to:
  /// **'وقت الذروة'**
  String get sellPeakChip;

  /// Sell screen with no type on sale at this time.
  ///
  /// In ar, this message translates to:
  /// **'مفيش فئة متاحة للبيع دلوقتي. كلّم المشرف.'**
  String get sellNothingOnSale;

  /// Snack bar when peak starts or ends with that type in the order.
  ///
  /// In ar, this message translates to:
  /// **'وقت البيع اتغيّر، والفئة اللي مبقتش متاحة اتشالت من الطلب.'**
  String get sellPeriodChanged;

  /// Ticket type field; also a changed field in the actions log.
  ///
  /// In ar, this message translates to:
  /// **'يتباع إمتى'**
  String get typesSalePeriodLabel;

  /// Sale period.
  ///
  /// In ar, this message translates to:
  /// **'دايماً'**
  String get typesSaleAlways;

  /// Sale period.
  ///
  /// In ar, this message translates to:
  /// **'في الأوقات العادية بس'**
  String get typesSaleOffPeak;

  /// Sale period.
  ///
  /// In ar, this message translates to:
  /// **'في الذروة بس'**
  String get typesSalePeak;

  /// Ticket types table header: the sale period.
  ///
  /// In ar, this message translates to:
  /// **'يتباع'**
  String get typesColSale;

  /// Warning on the Ticket types page.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نوع متاح للبيع في وقت الذروة: الكاشير مش هيلاقي حاجة يبيعها.'**
  String get typesNoPeakType;

  /// Warning on the Ticket types page.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نوع متاح للبيع في الأوقات العادية: الكاشير مش هيلاقي حاجة يبيعها.'**
  String get typesNoOffPeakType;

  /// save_peak_times refused the days.
  ///
  /// In ar, this message translates to:
  /// **'اختار أيام صحيحة.'**
  String get typesInvalidWeekdays;

  /// Peak card title (dashboard and Ticket types page).
  ///
  /// In ar, this message translates to:
  /// **'وقت الذروة'**
  String get peakTitle;

  /// Peak card: current state.
  ///
  /// In ar, this message translates to:
  /// **'الذروة دلوقتي: آه · {reason}'**
  String peakNowOn(String reason);

  /// Peak card: current state.
  ///
  /// In ar, this message translates to:
  /// **'الذروة دلوقتي: لأ · {reason}'**
  String peakNowOff(String reason);

  /// Why it is peak.
  ///
  /// In ar, this message translates to:
  /// **'اتشغّلت يدوي النهارده'**
  String get peakSourceManualOn;

  /// Why it isn't peak.
  ///
  /// In ar, this message translates to:
  /// **'اتقفلت يدوي النهارده'**
  String get peakSourceManualOff;

  /// Why it is peak: a weekend day.
  ///
  /// In ar, this message translates to:
  /// **'يوم ذروة'**
  String get peakSourceWeekend;

  /// Why it is peak: the daily range.
  ///
  /// In ar, this message translates to:
  /// **'ساعات الذروة'**
  String get peakSourceHours;

  /// Why it isn't peak.
  ///
  /// In ar, this message translates to:
  /// **'وقت عادي'**
  String get peakSourceNone;

  /// Peak switch: follow the schedule.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get peakModeAuto;

  /// Peak switch: peak all of today.
  ///
  /// In ar, this message translates to:
  /// **'ذروة النهارده'**
  String get peakModeOn;

  /// Peak switch: no peak today.
  ///
  /// In ar, this message translates to:
  /// **'عادي النهارده'**
  String get peakModeOff;

  /// Under the peak switch.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح بيرجع تلقائي لوحده بكرة. الشبابيك المتصلة بتشوف التغيير خلال ثواني.'**
  String get peakModeHelp;

  /// Peak schedule: the weekend days.
  ///
  /// In ar, this message translates to:
  /// **'أيام ذروة طول اليوم'**
  String get peakWeekdaysLabel;

  /// Peak schedule: the daily range.
  ///
  /// In ar, this message translates to:
  /// **'ساعات الذروة في باقي الأيام'**
  String get peakHoursLabel;

  /// Peak range start; also a changed field in the actions log.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get peakFrom;

  /// Peak range end; also a changed field in the actions log.
  ///
  /// In ar, this message translates to:
  /// **'لحد'**
  String get peakTo;

  /// The daily range is incomplete or reversed.
  ///
  /// In ar, this message translates to:
  /// **'البداية لازم تيجي قبل النهاية في نفس يوم المكان.'**
  String get peakInvalidHours;

  /// Peak schedule button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ أوقات الذروة'**
  String get peakSave;

  /// Snack bar.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظت أوقات الذروة.'**
  String get peakSaved;

  /// Snack bar after the switch.
  ///
  /// In ar, this message translates to:
  /// **'اتغيّر وقت الذروة.'**
  String get peakSwitched;

  /// Actions log: no peak weekday.
  ///
  /// In ar, this message translates to:
  /// **'ولا يوم'**
  String get peakNoDays;

  /// Actions log: the peak schedule changed.
  ///
  /// In ar, this message translates to:
  /// **'أوقات الذروة'**
  String get changePeakTimes;

  /// Actions log: the manual switch.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح الذروة ليوم {day}'**
  String changePeakOverride(String day);

  /// Actions log: the switch's changed field.
  ///
  /// In ar, this message translates to:
  /// **'الوضع'**
  String get changePeakMode;

  /// Peak schedule with the daily hours switched off.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ساعات ذروة في باقي الأيام.'**
  String get peakNoHours;

  /// Peak time dialog: the hour buttons.
  ///
  /// In ar, this message translates to:
  /// **'الساعة'**
  String get peakPickHour;

  /// Peak time dialog: the minute buttons.
  ///
  /// In ar, this message translates to:
  /// **'الدقايق'**
  String get peakPickMinute;

  /// Gates page subtitle (4.6).
  ///
  /// In ar, this message translates to:
  /// **'كل بوابة متوصلة بباب على وحدة تحكم'**
  String get gatesSubtitle;

  /// Gates page: add a gate.
  ///
  /// In ar, this message translates to:
  /// **'بوابة جديدة'**
  String get gatesNew;

  /// Gates page: first read.
  ///
  /// In ar, this message translates to:
  /// **'بيحمّل البوابات…'**
  String get gatesLoading;

  /// Gates page: controllers card title.
  ///
  /// In ar, this message translates to:
  /// **'وحدات التحكم وخدمة البوابات'**
  String get gatesControllersTitle;

  /// Gates page: entry gates switched on whose service beats recently.
  ///
  /// In ar, this message translates to:
  /// **'خدمة البوابات شغالة على {online} من {total} بوابة دخول'**
  String gatesServicesLine(int online, int total);

  /// Gates page: opens the controller dialog.
  ///
  /// In ar, this message translates to:
  /// **'إضافة وحدة'**
  String get gatesAddController;

  /// Gates page: no controller rows.
  ///
  /// In ar, this message translates to:
  /// **'مفيش وحدات تحكم متسجلة'**
  String get gatesNoControllers;

  /// Controller card: its number of doors.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{باب واحد} =2{بابين} few{{count} أبواب} other{{count} باب}}'**
  String controllerDoors(int count);

  /// Controller chip: an entry gate on it beat recently.
  ///
  /// In ar, this message translates to:
  /// **'متصلة'**
  String get controllerOnline;

  /// Controller chip: its gates' newest heartbeat is old.
  ///
  /// In ar, this message translates to:
  /// **'مش متصلة من {time}'**
  String controllerOfflineSince(String time);

  /// Controller chip: no gate on it ever beat.
  ///
  /// In ar, this message translates to:
  /// **'ما اتصلتش'**
  String get controllerNeverSeen;

  /// Controller chip: none of its doors is an entry gate, so nothing reports on it.
  ///
  /// In ar, this message translates to:
  /// **'مفيش بوابة دخول'**
  String get controllerNoEntryGate;

  /// Controller card: no address saved yet.
  ///
  /// In ar, this message translates to:
  /// **'من غير IP'**
  String get controllerNoIp;

  /// Gates table header.
  ///
  /// In ar, this message translates to:
  /// **'البوابة'**
  String get gatesColGate;

  /// Gates table header.
  ///
  /// In ar, this message translates to:
  /// **'الاتجاه'**
  String get gatesColDirection;

  /// Gates table header.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل'**
  String get gatesColWiring;

  /// Gates table header.
  ///
  /// In ar, this message translates to:
  /// **'النهارده'**
  String get gatesColToday;

  /// Gates table header.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get gatesColStatus;

  /// Gates table: no rows.
  ///
  /// In ar, this message translates to:
  /// **'مفيش بوابات لسه'**
  String get gatesEmpty;

  /// Gate direction.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get gateDirectionEntry;

  /// Gate direction.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get gateDirectionExit;

  /// Gates table: the controller and door a gate is wired to.
  ///
  /// In ar, this message translates to:
  /// **'{controller} · باب {door}'**
  String gatesWiring(String controller, int door);

  /// Gates table / dropdown: no controller.
  ///
  /// In ar, this message translates to:
  /// **'مش متوصلة'**
  String get gatesNotWired;

  /// Gates table: today's scans.
  ///
  /// In ar, this message translates to:
  /// **'{entries} دخول · {rejected} مرفوض'**
  String gatesToday(int entries, int rejected);

  /// Gate chip: an exit gate, which has no gate service.
  ///
  /// In ar, this message translates to:
  /// **'خروج حر'**
  String get gateStatusExit;

  /// Gates table: under an exit gate's name.
  ///
  /// In ar, this message translates to:
  /// **'خروج حر بدون مسح'**
  String get gateExitNote;

  /// Gate panel title.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات {name}'**
  String gatesEditTitle(String name);

  /// Gate / controller field.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get gatesName;

  /// Gate panel field.
  ///
  /// In ar, this message translates to:
  /// **'الاتجاه'**
  String get gatesDirectionLabel;

  /// Gate panel field.
  ///
  /// In ar, this message translates to:
  /// **'وحدة التحكم'**
  String get gatesController;

  /// Gate panel field.
  ///
  /// In ar, this message translates to:
  /// **'رقم الباب'**
  String get gatesDoor;

  /// Gate panel field.
  ///
  /// In ar, this message translates to:
  /// **'مدة الفتح (ثانية)'**
  String get gatesOpenSeconds;

  /// Gate panel field (free text).
  ///
  /// In ar, this message translates to:
  /// **'القارئ'**
  String get gatesReader;

  /// Gate panel switch.
  ///
  /// In ar, this message translates to:
  /// **'البوابة شغالة'**
  String get gatesEnabledLabel;

  /// Gate panel switch note.
  ///
  /// In ar, this message translates to:
  /// **'لو اتقفلت، كل المسح عليها بيترفض'**
  String get gatesEnabledNote;

  /// Gate panel button.
  ///
  /// In ar, this message translates to:
  /// **'فتح تجريبي'**
  String get gatesTestOpen;

  /// Gate panel: save a new gate.
  ///
  /// In ar, this message translates to:
  /// **'إضافة البوابة'**
  String get gatesAdd;

  /// Gate panel / controller dialog: save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get gatesSave;

  /// Gate panel: the counters whose home gate it is (ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'دي بوابة {counters}: لو السيرفر وقع تذاكرهم بتفتح البوابة دي بس، فلازم تفضل بوابة دخول.'**
  String gatesHomeGateNote(String counters);

  /// Gate panel: a running entry gate is being changed to exit.
  ///
  /// In ar, this message translates to:
  /// **'خدمة البوابة بتقف لو البوابة بقت خروج.'**
  String get gatesExitStopsService;

  /// Gate panel: why test open is off.
  ///
  /// In ar, this message translates to:
  /// **'مفيش خدمة بوابات على بوابة خروج، فمفيش فتح تجريبي.'**
  String get gatesTestOpenExit;

  /// Gate panel: why test open is off.
  ///
  /// In ar, this message translates to:
  /// **'البوابة مش متوصلة بوحدة تحكم.'**
  String get gatesTestOpenNotWired;

  /// Test open: before the server answers.
  ///
  /// In ar, this message translates to:
  /// **'بيبعت أمر الفتح…'**
  String get gatesTestSending;

  /// Test open: queued, the gate service hasn't answered yet.
  ///
  /// In ar, this message translates to:
  /// **'اتبعت أمر فتح لمدة {seconds} ثانية · مستني خدمة البوابة…'**
  String gatesTestWaiting(int seconds);

  /// Test open: done.
  ///
  /// In ar, this message translates to:
  /// **'البوابة اتفتحت لمدة {seconds} ثانية · اتسجل في سجل الإجراءات باسمك.'**
  String gatesTestOpened(int seconds);

  /// Test open: the adapter refused.
  ///
  /// In ar, this message translates to:
  /// **'خدمة البوابة ما قدرتش تفتحها: {detail}'**
  String gatesTestFailed(String detail);

  /// Test open: never taken, or no answer.
  ///
  /// In ar, this message translates to:
  /// **'خدمة البوابة ما ردتش · راجع إنها شغالة. الطلب اتسجل في سجل الإجراءات.'**
  String get gatesTestNoAnswer;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'البوابات للأدمن بس.'**
  String get gatesNotAllowed;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم.'**
  String get gatesInvalidName;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'الاسم ده موجود.'**
  String get gatesNameTaken;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'من 1 لـ 10 ثواني.'**
  String get gatesInvalidOpenSeconds;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'اختار وحدة التحكم ورقم الباب مع بعض.'**
  String get gatesInvalidWiring;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'وحدة التحكم دي مبقتش موجودة.'**
  String get gatesControllerNotFound;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'الباب ده مش موجود على وحدة التحكم.'**
  String get gatesDoorNotOnController;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'الباب ده متوصل ببوابة تانية.'**
  String get gatesDoorTaken;

  /// Gates page error (ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'دي بوابة شباك، فلازم تفضل دخول.'**
  String get gatesHomeGateMustBeEntry;

  /// Controller dialog error.
  ///
  /// In ar, this message translates to:
  /// **'اكتب IP جهاز واحد، زي 10.20.0.51.'**
  String get gatesInvalidIp;

  /// Controller dialog error.
  ///
  /// In ar, this message translates to:
  /// **'البورت من 1 لـ 65535.'**
  String get gatesInvalidPort;

  /// Controller dialog error.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأبواب من 1 لـ 4.'**
  String get gatesInvalidDoorCount;

  /// Controller dialog error.
  ///
  /// In ar, this message translates to:
  /// **'في بوابة متوصلة بباب أكبر من العدد ده.'**
  String get gatesDoorsInUse;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'اتغيرت من شاشة تانية. القائمة اتحدّثت.'**
  String get gatesNotFound;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'في فتح تجريبي مستني على البوابة دي.'**
  String get gatesTestOpenPending;

  /// Gates page error.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ غير متوقع في البوابات.'**
  String get gatesUnexpected;

  /// Controller dialog title.
  ///
  /// In ar, this message translates to:
  /// **'وحدة تحكم جديدة'**
  String get controllerNew;

  /// Controller dialog title.
  ///
  /// In ar, this message translates to:
  /// **'تعديل {name}'**
  String controllerEditTitle(String name);

  /// Controller field.
  ///
  /// In ar, this message translates to:
  /// **'الموديل'**
  String get controllerModel;

  /// Controller field.
  ///
  /// In ar, this message translates to:
  /// **'IP'**
  String get controllerIp;

  /// Controller field.
  ///
  /// In ar, this message translates to:
  /// **'البورت'**
  String get controllerPort;

  /// Controller field.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأبواب'**
  String get controllerDoorsLabel;

  /// Actions log: a test open's result.
  ///
  /// In ar, this message translates to:
  /// **'مستني رد'**
  String get testOpenResultWaiting;

  /// Actions log: a test open's result.
  ///
  /// In ar, this message translates to:
  /// **'اتفتحت'**
  String get testOpenResultOpened;

  /// Actions log: a test open's result.
  ///
  /// In ar, this message translates to:
  /// **'ما اتفتحتش'**
  String get testOpenResultFailed;

  /// Actions log: a test open's result.
  ///
  /// In ar, this message translates to:
  /// **'مفيش رد من خدمة البوابة'**
  String get testOpenResultNoAnswer;

  /// Actions log: a gate added.
  ///
  /// In ar, this message translates to:
  /// **'بوابة جديدة: {name}'**
  String changeNewGate(String name);

  /// Actions log: a gate changed.
  ///
  /// In ar, this message translates to:
  /// **'البوابة {name}'**
  String changeGateName(String name);

  /// Actions log: a controller added.
  ///
  /// In ar, this message translates to:
  /// **'وحدة تحكم جديدة: {name}'**
  String changeNewController(String name);

  /// Actions log: a controller changed.
  ///
  /// In ar, this message translates to:
  /// **'وحدة التحكم {name}'**
  String changeControllerName(String name);

  /// Actions log: open seconds.
  ///
  /// In ar, this message translates to:
  /// **'{seconds} ث'**
  String gatesSecondsShort(int seconds);

  /// Actions log: a new gate's open seconds.
  ///
  /// In ar, this message translates to:
  /// **'فتح {seconds} ث'**
  String gatesOpenFor(int seconds);

  /// Actions log: a gate switched on.
  ///
  /// In ar, this message translates to:
  /// **'شغالة'**
  String get gatesStateOn;

  /// Users page subtitle.
  ///
  /// In ar, this message translates to:
  /// **'مين بيدخل على السيستم وبيعمل إيه. محدش بيتمسح، بيتوقف بس.'**
  String get usersSubtitle;

  /// Users page button and new-user panel title.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم جديد'**
  String get usersNew;

  /// First load.
  ///
  /// In ar, this message translates to:
  /// **'بيحمّل المستخدمين…'**
  String get usersLoading;

  /// Empty table.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مستخدمين.'**
  String get usersEmpty;

  /// Users table column.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get usersColName;

  /// Users table column.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get usersColRole;

  /// Users table column.
  ///
  /// In ar, this message translates to:
  /// **'آخر دخول'**
  String get usersColLastSignIn;

  /// Users table column.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get usersColStatus;

  /// User status chip.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get usersStatusActive;

  /// User status chip.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get usersStatusInactive;

  /// Last sign-in cell: no sign-in yet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مدخلش'**
  String get usersNeverSignedIn;

  /// User panel title.
  ///
  /// In ar, this message translates to:
  /// **'تعديل: {name}'**
  String usersEditTitle(String name);

  /// User panel field.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get usersName;

  /// User panel field.
  ///
  /// In ar, this message translates to:
  /// **'اسم الدخول'**
  String get usersUsername;

  /// Under the username field.
  ///
  /// In ar, this message translates to:
  /// **'حروف إنجليزي صغيرة وأرقام و . _ -'**
  String get usersUsernameHint;

  /// User panel field.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get usersRole;

  /// Permissions summary title.
  ///
  /// In ar, this message translates to:
  /// **'يقدر يعمل'**
  String get usersPermissionsTitle;

  /// Permissions summary row (cashier and up).
  ///
  /// In ar, this message translates to:
  /// **'البيع والتحصيل وقفل ورديته'**
  String get usersPermSell;

  /// Permissions summary row (cashier and up).
  ///
  /// In ar, this message translates to:
  /// **'إعادة طباعة وإعادة تفعيل وإلغاء (بتتسجل)'**
  String get usersPermActions;

  /// Permissions summary row (supervisor and up).
  ///
  /// In ar, this message translates to:
  /// **'مطابقة الورديات واعتمادها'**
  String get usersPermShifts;

  /// Permissions summary row (supervisor and up).
  ///
  /// In ar, this message translates to:
  /// **'مراجعة سجل الإجراءات والتقارير'**
  String get usersPermLog;

  /// Permissions summary row (admin).
  ///
  /// In ar, this message translates to:
  /// **'الأسعار وأنواع التذاكر والبوابات'**
  String get usersPermCatalog;

  /// Permissions summary row (admin).
  ///
  /// In ar, this message translates to:
  /// **'المستخدمين والإعدادات'**
  String get usersPermUsers;

  /// User panel switch.
  ///
  /// In ar, this message translates to:
  /// **'الحساب مفعّل'**
  String get usersActiveLabel;

  /// Under the active switch.
  ///
  /// In ar, this message translates to:
  /// **'الإيقاف مش بيمسح المستخدم ولا تاريخه'**
  String get usersActiveNote;

  /// New user / reset field.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get usersPassword;

  /// New user / reset field.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get usersPasswordConfirm;

  /// Under the password field.
  ///
  /// In ar, this message translates to:
  /// **'{min} حروف على الأقل'**
  String usersPasswordHint(int min);

  /// Password confirm error.
  ///
  /// In ar, this message translates to:
  /// **'كلمتين المرور مش زي بعض.'**
  String get usersPasswordMismatch;

  /// Password field toggle tooltip.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get usersShowPassword;

  /// Password field toggle tooltip.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get usersHidePassword;

  /// User panel button.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get usersResetPassword;

  /// Reset dialog title.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور جديدة لـ {name}'**
  String usersResetTitle(String name);

  /// Reset dialog note.
  ///
  /// In ar, this message translates to:
  /// **'قول له على الكلمة الجديدة. هيخرج من أي جهاز داخل عليه ويدخل بيها من جديد.'**
  String get usersResetNote;

  /// Reset dialog button.
  ///
  /// In ar, this message translates to:
  /// **'تعيين'**
  String get usersResetConfirm;

  /// Snack bar after a reset.
  ///
  /// In ar, this message translates to:
  /// **'اتغيرت كلمة المرور. هيدخل بيها من جديد.'**
  String get usersResetDone;

  /// User panel button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get usersSave;

  /// New-user panel button.
  ///
  /// In ar, this message translates to:
  /// **'إضافة المستخدم'**
  String get usersAdd;

  /// Snack bar after adding a user.
  ///
  /// In ar, this message translates to:
  /// **'اتضاف. يدخل باسم الدخول وكلمة المرور.'**
  String get usersAdded;

  /// User panel note on one's own account.
  ///
  /// In ar, this message translates to:
  /// **'ده حسابك: دورك وتفعيله بيغيرهم مدير تاني.'**
  String get usersSelfNote;

  /// User panel note.
  ///
  /// In ar, this message translates to:
  /// **'عنده وردية مفتوحة. لازم تتقفل قبل إيقاف الحساب.'**
  String get usersOpenShiftNote;

  /// User panel note when the role or active changed.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الدور أو الإيقاف بيخرّجه من الأجهزة، ويدخل تاني.'**
  String get usersRoleSessionsNote;

  /// Users page error.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمين للأدمن بس.'**
  String get usersNotAllowed;

  /// Users page error.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الاسم.'**
  String get usersNameRequired;

  /// Users page error.
  ///
  /// In ar, this message translates to:
  /// **'اسم الدخول من 3 لـ 32: حروف إنجليزي صغيرة وأرقام و . _ -'**
  String get usersInvalidUsername;

  /// Users page error.
  ///
  /// In ar, this message translates to:
  /// **'اسم الدخول ده متاخد.'**
  String get usersUsernameTaken;

  /// Users page error.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور {min} حروف على الأقل.'**
  String usersPasswordTooShort(int min);

  /// Users page error.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور طويلة قوي.'**
  String get usersPasswordTooLong;

  /// Users page error.
  ///
  /// In ar, this message translates to:
  /// **'مينفعش تغيّر دورك أو توقف حسابك. مدير تاني يعملها.'**
  String get usersCannotChangeOwn;

  /// Users page error.
  ///
  /// In ar, this message translates to:
  /// **'عنده وردية مفتوحة. اقفلها الأول.'**
  String get usersHasOpenShift;

  /// Users page error.
  ///
  /// In ar, this message translates to:
  /// **'اتغير من شاشة تانية. القائمة اتحدّثت.'**
  String get usersNotFound;

  /// Users page error.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ غير متوقع في المستخدمين.'**
  String get usersUnexpected;

  /// Actions log: a user added.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم جديد: {name}'**
  String changeNewUser(String name);

  /// Actions log: a user changed.
  ///
  /// In ar, this message translates to:
  /// **'المستخدم {name}'**
  String changeUserName(String name);

  /// Actions log: a user's password reset (never the password).
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور اتعيّنت من جديد'**
  String get changePasswordReset;

  /// Settings page: loading.
  ///
  /// In ar, this message translates to:
  /// **'بيحمّل الإعدادات…'**
  String get settingsLoading;

  /// Settings page: header line (design).
  ///
  /// In ar, this message translates to:
  /// **'كل تغيير بيتسجل باسمك في سجل الإجراءات'**
  String get settingsLogNote;

  /// Settings page error.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات للأدمن بس.'**
  String get settingsNotAllowed;

  /// Settings page error.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ غير متوقع في الإعدادات.'**
  String get settingsUnexpected;

  /// Settings page: the server refused a value.
  ///
  /// In ar, this message translates to:
  /// **'القيمة دي مش مقبولة.'**
  String get settingsInvalidValue;

  /// Settings page: an empty field.
  ///
  /// In ar, this message translates to:
  /// **'اكتب قيمة.'**
  String get settingsRequired;

  /// Settings page: a number out of its range.
  ///
  /// In ar, this message translates to:
  /// **'رقم من {min} لـ {max}.'**
  String settingsOutOfRange(int min, int max);

  /// Settings page: an amount list that can't be read.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبالغ مفصولة بفاصلة، مثلاً 5, 10, 20.'**
  String get settingsInvalidList;

  /// Settings page: too many amounts.
  ///
  /// In ar, this message translates to:
  /// **'{count} مبلغ بالكتير.'**
  String settingsTooManyAmounts(int count);

  /// Settings page: an amount too big.
  ///
  /// In ar, this message translates to:
  /// **'كل مبلغ لحد 100,000 ج.م.'**
  String get settingsAmountTooBig;

  /// Settings page: a repeated denomination.
  ///
  /// In ar, this message translates to:
  /// **'فيه فئة مكررة.'**
  String get settingsDuplicateAmount;

  /// Settings page: no denominations.
  ///
  /// In ar, this message translates to:
  /// **'اكتب فئة واحدة على الأقل.'**
  String get settingsNeedOneDenomination;

  /// Settings page: section title.
  ///
  /// In ar, this message translates to:
  /// **'المكان'**
  String get settingsVenueSection;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'اسم المكان (بيتطبع على التذكرة)'**
  String get settingsVenueName;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد قفل المكان'**
  String get settingsClosingTime;

  /// Settings page: under the closing time.
  ///
  /// In ar, this message translates to:
  /// **'تذاكر يوم البيع بتنتهي في الميعاد ده. التذاكر اللي اتباعت بتفضل بميعادها.'**
  String get settingsClosingNote;

  /// Ticket types page: under the peak From/To, the range may run past midnight until the closing time (ADR-0038).
  ///
  /// In ar, this message translates to:
  /// **'ممكن الساعات تعدّي نص الليل، لحد ميعاد قفل المكان الساعة {closing}.'**
  String peakHoursPastMidnight(String closing);

  /// Ticket types page: the peak range ends after the closing time (ADR-0038).
  ///
  /// In ar, this message translates to:
  /// **'ساعات الذروة لازم تخلص لحد ميعاد قفل المكان: بعده مفيش بيع لتذاكر اليوم.'**
  String get peakHoursAfterClosing;

  /// Under the peak switch: the venue day it acts on (the coming one after closing) and when it lapses (ADR-0038).
  ///
  /// In ar, this message translates to:
  /// **'المفتاح ليوم {day}، وبيرجع تلقائي لما اليوم اللي بعده يبدأ الساعة {start}. بعد ميعاد القفل بيتطبّق على اليوم اللي جاي. الشبابيك المتصلة بتشوف التغيير خلال ثواني.'**
  String peakModeHelpDay(String day, String start);

  /// Settings page: under the closing time when the daily peak hours would end after it.
  ///
  /// In ar, this message translates to:
  /// **'ساعات الذروة هتبقى بعد ميعاد القفل ده. غيّرها الأول من صفحة أنواع التذاكر.'**
  String get settingsClosingCutsPeak;

  /// Settings page: under the venue day start when the daily peak hours would cross it.
  ///
  /// In ar, this message translates to:
  /// **'ساعات الذروة هتعدّي بداية اليوم دي. غيّرها الأول من صفحة أنواع التذاكر.'**
  String get settingsStartCrossesPeak;

  /// Settings page: field, venue_day_starts_at (ADR-0038).
  ///
  /// In ar, this message translates to:
  /// **'بداية يوم المكان'**
  String get settingsDayStart;

  /// Settings page: under the venue day start.
  ///
  /// In ar, this message translates to:
  /// **'\"النهارده\" في البيع والتقارير بيبدأ الساعة دي. لو المكان بيقفل بعد نص الليل خلّيها بعد ميعاد القفل.'**
  String get settingsDayStartNote;

  /// Settings page: under the closing time when it is at or before the day start, so on the next date.
  ///
  /// In ar, this message translates to:
  /// **'بيقفل الساعة {time} بعد نص الليل: تذاكر يوم البيع بتنتهي {time} الصبح اللي بعده.'**
  String settingsClosingNextDay(String time);

  /// Settings page: confirm before saving times whose closing for today has already passed.
  ///
  /// In ar, this message translates to:
  /// **'البيع هيقف دلوقتي'**
  String get settingsClosedNowTitle;

  /// Settings page: the confirm's text.
  ///
  /// In ar, this message translates to:
  /// **'بالمواعيد دي يوم النهارده قفل الساعة {closing}. الشبابيك مش هتبيع تذاكر يوم البيع لحد ما اليوم الجديد يبدأ الساعة {start}.'**
  String settingsClosedNowBody(String closing, String start);

  /// Settings page: save in spite of the warning.
  ///
  /// In ar, this message translates to:
  /// **'احفظ برضه'**
  String get settingsClosedNowSave;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'لغة الواجهة الافتراضية'**
  String get settingsDefaultLanguage;

  /// Settings page: a language.
  ///
  /// In ar, this message translates to:
  /// **'عربي'**
  String get settingsLanguageAr;

  /// Settings page: a language.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// Settings page: read-only row.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية'**
  String get settingsTimezone;

  /// Settings page: why the time zone can't be changed here.
  ///
  /// In ar, this message translates to:
  /// **'ثابتة: تغييرها بيحرّك \"النهارده\" في كل التقارير والصلاحيات.'**
  String get settingsTimezoneNote;

  /// Settings page: section title.
  ///
  /// In ar, this message translates to:
  /// **'التذاكر'**
  String get settingsTicketsSection;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'طول كود البوابة (أرقام)'**
  String get settingsGateCodeLength;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب غير المحصّل بعد (دقيقة)'**
  String get settingsUnpaidTimeout;

  /// Settings page: under the gate code length (design).
  ///
  /// In ar, this message translates to:
  /// **'قارئ Wiegand 26 بيقرا لحد 16,777,215، يعني 7 أرقام كحد أقصى. لو القارئ اتغير لـ Wiegand 34 تقدر تزوّد الطول. الطول الجديد للتذاكر الجديدة بس.'**
  String get settingsWiegandNote;

  /// Settings page: replaces the design's same-day switch.
  ///
  /// In ar, this message translates to:
  /// **'صلاحية التذكرة (يوم البيع أو عدد ساعات) بتتحدد لكل نوع.'**
  String get settingsValidityNote;

  /// Settings page: section title.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات الكاشير والمراجعة'**
  String get settingsActionsSection;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'مهلة إعادة التفعيل بعد المسح (دقيقة)'**
  String get settingsReactivationWindow;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'أقصى إعادة تفعيل للتذكرة'**
  String get settingsReactivationMax;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة لو الإجراءات في الوردية أكتر من'**
  String get settingsFlagActions;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة لو التذكرة اتطبعت أكتر من'**
  String get settingsFlagPrints;

  /// Settings page: switch.
  ///
  /// In ar, this message translates to:
  /// **'الإلغاء قبل المسح بس'**
  String get settingsRefundBeforeScan;

  /// Settings page: switch help.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة اللي دخلت مينفعش تتلغي'**
  String get settingsRefundBeforeScanHelp;

  /// Settings page: switch.
  ///
  /// In ar, this message translates to:
  /// **'الإلغاء في نفس الوردية بس'**
  String get settingsRefundSameShift;

  /// Settings page: switch help.
  ///
  /// In ar, this message translates to:
  /// **'التذكرة بتتلغي في الوردية اللي اتباعت فيها بس'**
  String get settingsRefundSameShiftHelp;

  /// Settings page: switch.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة أي إجراء سببه \"سبب آخر\"'**
  String get settingsFlagOther;

  /// Settings page: switch help.
  ///
  /// In ar, this message translates to:
  /// **'بيظهر في سجل الإجراءات كـ محتاج مراجعة'**
  String get settingsFlagOtherHelp;

  /// Settings page: section title.
  ///
  /// In ar, this message translates to:
  /// **'الإكراميات والمبالغ السريعة'**
  String get settingsTipsSection;

  /// Settings page: switch.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الإكراميات مع التحصيل'**
  String get settingsTipsEnabled;

  /// Settings page: switch help.
  ///
  /// In ar, this message translates to:
  /// **'مع الكاش بس، وبتدخل في المتوقع عند مطابقة الوردية'**
  String get settingsTipsEnabledHelp;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'أزرار الإكرامية السريعة (ج.م)'**
  String get settingsTipQuick;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'أزرار عهدة البداية السريعة (ج.م)'**
  String get settingsFloatQuick;

  /// Settings page: hint under the tip quick amounts.
  ///
  /// In ar, this message translates to:
  /// **'لحد 6: بتظهر في صفين في شاشة الدفع وشاشة قفل الوردية.'**
  String get settingsTipQuickNote;

  /// Settings page: hint under the opening float quick amounts.
  ///
  /// In ar, this message translates to:
  /// **'لحد 4: بتظهر في سطر واحد في شاشة فتح الوردية.'**
  String get settingsFloatQuickNote;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'أزرار المبلغ المستلم السريعة (ج.م)'**
  String get settingsReceivedQuick;

  /// Settings page: hint.
  ///
  /// In ar, this message translates to:
  /// **'لحد 8. شاشة الدفع بتعرض أول 3 أكبر من إجمالي الطلب.'**
  String get settingsReceivedQuickNote;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'فئات العدّ عند قفل الوردية (ج.م)'**
  String get settingsDenominations;

  /// Settings page: hint.
  ///
  /// In ar, this message translates to:
  /// **'لحد 12، بنفس الترتيب ده في شاشة القفل.'**
  String get settingsDenominationsNote;

  /// Actions log: an empty amount list.
  ///
  /// In ar, this message translates to:
  /// **'ولا مبلغ'**
  String get settingsNoAmounts;

  /// Actions log: a switch on.
  ///
  /// In ar, this message translates to:
  /// **'شغال'**
  String get settingsOn;

  /// Actions log: a switch off.
  ///
  /// In ar, this message translates to:
  /// **'مقفول'**
  String get settingsOff;

  /// Settings page: section title.
  ///
  /// In ar, this message translates to:
  /// **'أوقات الذروة'**
  String get settingsPeakSection;

  /// Settings page: the peak weekdays.
  ///
  /// In ar, this message translates to:
  /// **'{days}: ذروة طول اليوم'**
  String settingsPeakDays(String days);

  /// Settings page: no peak weekdays.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أيام ذروة طول اليوم.'**
  String get settingsPeakNoDays;

  /// Settings page: the daily peak hours.
  ///
  /// In ar, this message translates to:
  /// **'باقي الأيام: من {from} لحد {to}'**
  String settingsPeakHours(String from, String to);

  /// Settings page: where the peak times are edited.
  ///
  /// In ar, this message translates to:
  /// **'بتتعدل من صفحة أنواع التذاكر، وزرار ذروة النهارده في لوحة المتابعة.'**
  String get settingsPeakNote;

  /// Settings page: section title.
  ///
  /// In ar, this message translates to:
  /// **'الأوفلاين والشبكة'**
  String get settingsOfflineSection;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'أكواد الأوفلاين لكل شباك'**
  String get settingsPoolSize;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'الشباك يبقى أوفلاين بعد (ثانية)'**
  String get settingsHealthCheck;

  /// Settings page: hint.
  ///
  /// In ar, this message translates to:
  /// **'0 أكواد بيقفل البيع أوفلاين. الأكواد المحجوزة مش بتتلغي لو قللت العدد.'**
  String get settingsOfflineNote;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'البوابة تبان واقفة بعد (ثانية)'**
  String get settingsGateOffline;

  /// Settings page: field.
  ///
  /// In ar, this message translates to:
  /// **'مهلة الفتح التجريبي (ثانية)'**
  String get settingsTestOpenTimeout;

  /// Settings page: hint.
  ///
  /// In ar, this message translates to:
  /// **'خدمة البوابة بتبعت نبضة كل 30 ثانية وبتسأل عن الفتح التجريبي كل 2 ثانية (الافتراضي). خلي الوقف أكبر من النبضة (90 = 3 نبضات فايتة)، والمهلة أكبر من 2.'**
  String get settingsGateTimingNote;

  /// Settings page: section title.
  ///
  /// In ar, this message translates to:
  /// **'الشبابيك والطابعات'**
  String get settingsCountersSection;

  /// Settings page: no counters.
  ///
  /// In ar, this message translates to:
  /// **'مفيش شبابيك لسه. أضف أول شباك.'**
  String get settingsCountersEmpty;

  /// Settings page: why there is no test print here.
  ///
  /// In ar, this message translates to:
  /// **'الطباعة التجريبية من شاشة فتح الوردية على كل شباك.'**
  String get settingsCountersNote;

  /// Settings page: section title.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get settingsBackupSection;

  /// Settings page: backup placeholder until 6.2.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي لسه متجهزش. بييجي مع تركيب السيرفر في المكان.'**
  String get settingsBackupNotYet;

  /// Settings page: button (design).
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get settingsUndo;

  /// Settings page: button (design).
  ///
  /// In ar, this message translates to:
  /// **'حفظ الإعدادات'**
  String get settingsSave;

  /// Settings page: bottom bar.
  ///
  /// In ar, this message translates to:
  /// **'فيه تغييرات لسه متحفظتش.'**
  String get settingsUnsaved;

  /// Settings page: bottom bar.
  ///
  /// In ar, this message translates to:
  /// **'آخر تغيير: {name} · {time}'**
  String settingsLastChange(String name, String time);

  /// Settings page: bottom bar before any change.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات زي ما اتركّبت.'**
  String get settingsNoChangeYet;

  /// Counter dialog: title and the add button.
  ///
  /// In ar, this message translates to:
  /// **'شباك جديد'**
  String get counterNew;

  /// Counter dialog: save a new counter.
  ///
  /// In ar, this message translates to:
  /// **'إضافة الشباك'**
  String get counterAdd;

  /// Counter dialog: field.
  ///
  /// In ar, this message translates to:
  /// **'IP الطابعة'**
  String get counterPrinterIp;

  /// Counter dialog: field.
  ///
  /// In ar, this message translates to:
  /// **'بورت الطابعة'**
  String get counterPrinterPort;

  /// Counter dialog: field.
  ///
  /// In ar, this message translates to:
  /// **'عرض الورق'**
  String get counterPaperWidth;

  /// Counter: paper width.
  ///
  /// In ar, this message translates to:
  /// **'{mm} مم'**
  String counterPaperMm(int mm);

  /// Counter dialog: field (ADR-0015).
  ///
  /// In ar, this message translates to:
  /// **'بوابة الدخول (وقت انقطاع الشبكة)'**
  String get counterHomeGate;

  /// Counter row: its home gate.
  ///
  /// In ar, this message translates to:
  /// **'بوابة {gate}'**
  String counterHomeGateIs(String gate);

  /// Counter dialog: what the home gate is.
  ///
  /// In ar, this message translates to:
  /// **'وقت انقطاع السيرفر أو السويتش، تذاكر الشباك بتفتح البوابة دي بس، وبتتطبع عليها.'**
  String get counterHomeGateNote;

  /// Counter: no home gate.
  ///
  /// In ar, this message translates to:
  /// **'من غير بوابة'**
  String get counterNoHomeGate;

  /// Counter dialog: a disabled entry gate.
  ///
  /// In ar, this message translates to:
  /// **'{name} (متوقفة)'**
  String counterGateDisabled(String name);

  /// Counter dialog: switch.
  ///
  /// In ar, this message translates to:
  /// **'الشباك شغال'**
  String get counterActive;

  /// Counter dialog: switch help.
  ///
  /// In ar, this message translates to:
  /// **'لو اتوقف، مينفعش تتفتح عليه وردية.'**
  String get counterActiveNote;

  /// Counter dialog: switch help with an open shift.
  ///
  /// In ar, this message translates to:
  /// **'عليه وردية مفتوحة دلوقتي، فمينفعش يتوقف لحد ما تتقفل.'**
  String get counterOpenShiftNote;

  /// Counter dialog: changing the home gate.
  ///
  /// In ar, this message translates to:
  /// **'التذاكر الجديدة هتتطبع بالبوابة الجديدة. أكواد الأوفلاين المحجوزة بتفضل على القديمة لحد ما تنتهي.'**
  String get counterGateChangeNote;

  /// Counter dialog: a new counter's id.
  ///
  /// In ar, this message translates to:
  /// **'بعد الإضافة، انسخ رقم الشباك (زرار النسخ في القائمة). ده الرقم اللي بيتحط في إعدادات تشغيل البرنامج على جهاز الشباك (COUNTER_ID)، عشان البرنامج يعرف هو على أنهي شباك.'**
  String get counterNewIdNote;

  /// Counter dialog: after adding.
  ///
  /// In ar, this message translates to:
  /// **'اتضاف. انسخ رقمه لإعدادات البرنامج على جهاز الشباك.'**
  String get counterAddedCopyId;

  /// Counter row: copy button tooltip.
  ///
  /// In ar, this message translates to:
  /// **'نسخ رقم الشباك'**
  String get counterCopyId;

  /// Counter row: after copying the id.
  ///
  /// In ar, this message translates to:
  /// **'اتنسخ. ده رقم الشباك اللي بيتحط في إعدادات البرنامج على جهازه (COUNTER_ID).'**
  String get counterIdCopied;

  /// Counter row: status.
  ///
  /// In ar, this message translates to:
  /// **'شغال'**
  String get counterOn;

  /// Counter row: status.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get counterOff;

  /// Counter row: status.
  ///
  /// In ar, this message translates to:
  /// **'وردية مفتوحة'**
  String get counterOpenShift;

  /// Counter row: no printer IP.
  ///
  /// In ar, this message translates to:
  /// **'مفيش طابعة'**
  String get counterNoPrinter;

  /// Counter dialog error.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم الشباك.'**
  String get counterInvalidName;

  /// Counter dialog error.
  ///
  /// In ar, this message translates to:
  /// **'فيه شباك تاني بالاسم ده.'**
  String get counterNameTaken;

  /// Counter dialog error.
  ///
  /// In ar, this message translates to:
  /// **'عرض الورق 58 أو 80 مم.'**
  String get counterInvalidPaper;

  /// Counter dialog error.
  ///
  /// In ar, this message translates to:
  /// **'الشباك الشغال محتاج بوابة دخول.'**
  String get counterHomeGateRequired;

  /// Counter dialog error.
  ///
  /// In ar, this message translates to:
  /// **'لازم تكون بوابة دخول.'**
  String get counterHomeGateNotEntry;

  /// Counter dialog error.
  ///
  /// In ar, this message translates to:
  /// **'البوابة دي مبقتش موجودة. افتح الصفحة تاني.'**
  String get counterGateNotFound;

  /// Counter dialog error.
  ///
  /// In ar, this message translates to:
  /// **'عليه وردية مفتوحة. اقفلها الأول.'**
  String get counterHasOpenShift;

  /// Counter dialog error.
  ///
  /// In ar, this message translates to:
  /// **'الشباك اتغير من شاشة تانية. القائمة اتحدّثت.'**
  String get counterNotFound;

  /// Actions log: settings changed.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get changeSettings;

  /// Actions log: a counter added.
  ///
  /// In ar, this message translates to:
  /// **'شباك جديد: {name}'**
  String changeNewCounter(String name);

  /// Actions log: a counter changed.
  ///
  /// In ar, this message translates to:
  /// **'الشباك {name}'**
  String changeCounterName(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
