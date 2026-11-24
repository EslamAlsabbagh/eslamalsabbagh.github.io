// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نظام التذاكر';

  @override
  String get switchLanguage => 'EN';

  @override
  String get switchLanguageHint => 'Switch to English';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get backToHome => 'الرجوع للرئيسية';

  @override
  String get loginSubtitle => 'سجّل دخولك لبدء الوردية';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get signIn => 'دخول';

  @override
  String get forgotPasswordHint =>
      'نسيت كلمة المرور؟ كلّم المشرف لإعادة تعيينها.';

  @override
  String get loginErrorMissingFields => 'اكتب اسم المستخدم وكلمة المرور.';

  @override
  String get loginErrorInvalidCredentials =>
      'اسم المستخدم أو كلمة المرور غير صحيحة.';

  @override
  String get loginErrorAccountInactive => 'هذا الحساب غير مفعّل. كلّم المشرف.';

  @override
  String get loginErrorServerUnreachable =>
      'تعذّر الاتصال بالسيرفر. تأكد من الشبكة وحاول مرة أخرى.';

  @override
  String get loginErrorSessionEnded => 'انتهت جلستك. سجّل دخولك مرة أخرى.';

  @override
  String get loginErrorUnexpected => 'حدث خطأ غير متوقع. حاول مرة أخرى.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get shiftAreaTitle => 'شاشة الكاشير';

  @override
  String get adminAreaTitle => 'لوحة الإدارة';

  @override
  String shiftNumberLabel(int number) {
    return 'وردية رقم $number';
  }

  @override
  String get roleCashier => 'كاشير';

  @override
  String get roleSupervisor => 'مشرف';

  @override
  String get roleAdmin => 'مدير النظام';

  @override
  String staffWithRole(String name, String role) {
    return '$name · $role';
  }

  @override
  String get errorServerUnreachable =>
      'تعذّر الاتصال بالسيرفر. تأكد من الشبكة وحاول مرة أخرى.';

  @override
  String get errorUnexpected => 'حدث خطأ غير متوقع. حاول مرة أخرى.';

  @override
  String get retry => 'حاول مرة أخرى';

  @override
  String get openShiftTitle => 'فتح الوردية';

  @override
  String lastShiftClosedToday(String time) {
    return 'آخر وردية على الجهاز ده اتقفلت النهارده الساعة $time.';
  }

  @override
  String lastShiftClosedYesterday(String time) {
    return 'آخر وردية على الجهاز ده اتقفلت أمس الساعة $time.';
  }

  @override
  String lastShiftClosedOn(String date, String time) {
    return 'آخر وردية على الجهاز ده اتقفلت يوم $date الساعة $time.';
  }

  @override
  String get openingFloatTitle => 'عهدة بداية الوردية';

  @override
  String get openingFloatHint =>
      'عدّ الفكة اللي في الدرج واكتب المبلغ. هيتقارن بالمبلغ اللي هتعدّه وقت قفل الوردية.';

  @override
  String get openingFloatLabel => 'المبلغ (ج.م)';

  @override
  String printerLabel(String address) {
    return 'الطابعة · $address';
  }

  @override
  String get printerLabelNone => 'الطابعة';

  @override
  String get printerNotSet => 'مفيش طابعة متسجلة للشباك ده. كلّم الأدمن.';

  @override
  String get printerChecking => 'بنفحص الطابعة…';

  @override
  String get printerReachable => 'متصلة · اعمل طباعة تجريبية قبل البدء';

  @override
  String get printerUnreachable => 'الطابعة مش بترد. اتأكد إنها شغالة ومتوصلة.';

  @override
  String get printerPrinting => 'بنطبع ورقة تجريبية…';

  @override
  String get printerPrinted => 'اتطبعت ورقة تجريبية — الطابعة شغالة';

  @override
  String get printerPrintFailed =>
      'الطباعة التجريبية فشلت. اتأكد من الطابعة وحاول تاني.';

  @override
  String get testPrint => 'طباعة تجريبية';

  @override
  String get checkPrinterAgain => 'افحص تاني';

  @override
  String get openShiftButton => 'فتح الوردية وبدء البيع';

  @override
  String get openShiftNoCounter =>
      'الجهاز ده مش متسجل على شباك. كلّم الأدمن يضبط إعدادات التطبيق.';

  @override
  String get openShiftCounterUnavailable =>
      'الشباك ده مش موجود أو موقوف. كلّم الأدمن.';

  @override
  String get openShiftCounterNoHomeGate => 'الشباك ده ملوش بوابة. كلّم الأدمن.';

  @override
  String openShiftElsewhere(String counter) {
    return 'عندك وردية مفتوحة على $counter. اقفلها من هناك الأول.';
  }

  @override
  String get openShiftErrorCounterBusy =>
      'فيه وردية تانية مفتوحة على الشباك ده. لازم تتقفل الأول.';

  @override
  String get openShiftErrorInvalidCash => 'اكتب مبلغ العهدة.';

  @override
  String moneyAmount(String amount) {
    return '$amount ج.م';
  }

  @override
  String get sellTitle => 'بيع التذاكر';

  @override
  String sellSubtitle(String counter, int number, String time) {
    return '$counter · وردية #$number · بدأت $time';
  }

  @override
  String get sellHeading => 'اختار نوع التذكرة والعدد';

  @override
  String get findTicket => 'بحث عن تذكرة';

  @override
  String get lastOrder => 'آخر طلب';

  @override
  String get closeShift => 'قفل الوردية';

  @override
  String get printerBadgeReady => 'الطابعة جاهزة';

  @override
  String get printerBadgeChecking => 'بنفحص الطابعة…';

  @override
  String get printerBadgeUnreachable => 'الطابعة مش بترد';

  @override
  String get printerBadgeNotSet => 'مفيش طابعة';

  @override
  String get printerBadgeHint => 'اضغط لفحص الطابعة تاني';

  @override
  String get ticketRuleSingleEntry => 'دخول مرة واحدة';

  @override
  String ticketRuleEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'دخول حتى $count مرة',
      few: 'دخول حتى $count مرات',
      two: 'دخول حتى مرتين',
    );
    return '$_temp0';
  }

  @override
  String get ticketRuleValidToday => 'صالحة اليوم';

  @override
  String ticketRuleValidHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'صالحة $hours ساعة',
      few: 'صالحة $hours ساعات',
      two: 'صالحة ساعتين',
      one: 'صالحة ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get increaseQuantity => 'زيادة';

  @override
  String get decreaseQuantity => 'تقليل';

  @override
  String get noTicketTypes => 'مفيش أنواع تذاكر متاحة للبيع. كلّم الأدمن.';

  @override
  String get footerShiftOrders => 'طلبات الوردية:';

  @override
  String get footerTicketsSold => 'التذاكر المباعة:';

  @override
  String get footerLastOrder => 'آخر طلب:';

  @override
  String get currentOrder => 'الطلب الحالي';

  @override
  String get clearOrder => 'مسح الطلب';

  @override
  String get orderEmpty => 'اختار أنواع التذاكر من القائمة';

  @override
  String orderLineQuantity(int quantity, String price) {
    return '$quantity × $price';
  }

  @override
  String get paymentMethodLabel => 'طريقة الدفع';

  @override
  String get paymentCash => 'نقدي';

  @override
  String get paymentCard => 'كارت';

  @override
  String get paymentWallet => 'محفظة';

  @override
  String orderTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الإجمالي · $count تذكرة',
      few: 'الإجمالي · $count تذاكر',
    );
    return '$_temp0';
  }

  @override
  String get printAndCharge => 'طباعة التذاكر والتحصيل';

  @override
  String get sellShortcutsHint => 'F12 للطباعة والتحصيل · Esc لمسح الطلب';

  @override
  String get ticketHeading => 'تذكرة دخول';

  @override
  String ticketValidOnDay(String date, String time) {
    return 'صالحة يوم $date حتى $time';
  }

  @override
  String ticketValidUntil(String date, String time) {
    return 'صالحة حتى $date $time';
  }

  @override
  String ticketHomeGate(String gate) {
    return 'ادخل من: $gate';
  }

  @override
  String get ticketOrderLabel => 'طلب';

  @override
  String ticketOrderValue(String number, String index, String count) {
    return '#$number · $index من $count';
  }

  @override
  String get ticketCounterLabel => 'شباك';

  @override
  String get ticketTimeLabel => 'الوقت';

  @override
  String get ticketFooter => 'امسح الكود على البوابة · احتفظ بالتذكرة';

  @override
  String get testPageTitle => 'طباعة تجريبية';

  @override
  String get testPageNotATicket => 'عينة — مش تذكرة';

  @override
  String testPagePaper(String width) {
    return 'ورق $width مم';
  }

  @override
  String get testPageSample => 'أبجد هوز حطي كلمن · 0123456789';

  @override
  String get testPageSampleType => 'عينة';

  @override
  String shiftSubtitle(String counter, int number) {
    return '$counter · وردية #$number';
  }

  @override
  String get sellFailureCounterNoHomeGate =>
      'الشباك ده مالوش بوابة. كلّم الأدمن.';

  @override
  String get sellFailureTypeUnavailable =>
      'نوع تذكرة في الطلب اتوقف بيعه. القائمة اتحدّثت، راجع الطلب.';

  @override
  String get sellFailureAfterClosing =>
      'عدّى ميعاد القفل: تذاكر النهارده بس مش بتتباع دلوقتي.';

  @override
  String get sellFailureCodesExhausted =>
      'مفيش أكواد تذاكر فاضية. كلّم الأدمن.';

  @override
  String orderCancelledNotice(int number) {
    return 'الطلب #$number اتلغى. خد التذاكر المطبوعة من العميل.';
  }

  @override
  String paymentTitle(String method) {
    return 'التحصيل · $method';
  }

  @override
  String get printStatusPrinting => 'بنطبع التذاكر…';

  @override
  String printStatusPrinted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اتطبعت $count تذكرة',
      few: 'اتطبعت $count تذاكر',
    );
    return '$_temp0';
  }

  @override
  String printStatusFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكرة ما اتطبعتش',
      few: '$count تذاكر ما اتطبعتش',
    );
    return '$_temp0';
  }

  @override
  String printStatusCount(int done, int count) {
    return '$done من $count';
  }

  @override
  String get printStatusHint =>
      'سلّم التذاكر بعد ما تستلم الفلوس. التذاكر مش هتفتح البوابة غير بعد تأكيد التحصيل.';

  @override
  String get printStatusFailedHint =>
      'اتأكد من الطابعة (الورق والكهربا) واضغط إعادة المحاولة.';

  @override
  String orderSummary(int number) {
    return 'ملخص الطلب #$number';
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
      other: 'المطلوب · $count تذكرة',
      few: 'المطلوب · $count تذاكر',
    );
    return '$_temp0';
  }

  @override
  String get amountReceivedLabel =>
      'المبلغ المستلم (ج.م) · اكتبه أو استخدم الأرقام';

  @override
  String get exactAmount => 'المبلغ بالظبط';

  @override
  String get tipTitle => 'إكرامية من العميل (اختياري)';

  @override
  String get tipNone => 'بدون';

  @override
  String get tipTypedHint => 'مبلغ';

  @override
  String get tipTypedLabel => 'مبلغ الإكرامية بالجنيه';

  @override
  String get tipTheChange => 'العميل ساب الباقي كله إكرامية';

  @override
  String get changeLabel => 'الباقي للعميل';

  @override
  String changeAfterTip(String tip) {
    return 'الباقي للعميل بعد إكرامية $tip';
  }

  @override
  String get amountShort => 'المبلغ ناقص';

  @override
  String get keypadClear => 'مسح';

  @override
  String get keypadBackspace => 'حذف رقم';

  @override
  String cardPaymentNote(String amount) {
    return 'حصّل $amount على ماكينة الكارت، وبعدين أكّد التحصيل.';
  }

  @override
  String walletPaymentNote(String amount) {
    return 'استلم $amount على المحفظة، وبعدين أكّد التحصيل.';
  }

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get cancelOrderHint => 'العميل ما دفعش · التذاكر المطبوعة بتتلغي';

  @override
  String get confirmPayment => 'تأكيد التحصيل';

  @override
  String get paymentShortcutsHint => 'Enter أو F12 لتأكيد التحصيل';

  @override
  String cancelDialogTitle(int number) {
    return 'إلغاء الطلب #$number؟';
  }

  @override
  String get cancelDialogBody =>
      'التذاكر المطبوعة هتتلغي ومش هتفتح البوابة. خدها من العميل.';

  @override
  String get cancelReasonNotPaid => 'العميل ما دفعش';

  @override
  String get cancelReasonOther => 'سبب تاني';

  @override
  String get cancelReasonTextLabel => 'اكتب السبب';

  @override
  String get cancelReasonTextRequired => 'لازم تكتب السبب';

  @override
  String get cancelDialogKeep => 'رجوع';

  @override
  String get paymentFailureOrderCancelled =>
      'الطلب ده اتلغى تلقائي لأنه فضل من غير تحصيل، والتذاكر اتلغت. خدها من العميل وبيع تاني.';

  @override
  String get paymentFailureOrderNotFound =>
      'الطلب ده مش موجود في ورديتك. ارجع للبيع وبيع تاني.';

  @override
  String get paymentFailureTipNotAllowed =>
      'الإكرامية مش مسموحة للدفع ده. شيل الإكرامية وحاول تاني.';

  @override
  String get paymentFailureAmount => 'المبلغ المستلم أقل من المطلوب.';

  @override
  String get paymentFailureAlreadyPaid => 'الطلب ده اتحصّل خلاص.';

  @override
  String get backToSell => 'رجوع للبيع';

  @override
  String get paymentServerUnreachable =>
      'تعذّر الاتصال بالسيرفر، فلم يُؤكَّد الدفع. حاول مرة أخرى، أو ارجع للبيع وبِع بدون اتصال: استرجع التذاكر المطبوعة، فهي لا تفتح البوابة.';

  @override
  String reviewTitle(int number) {
    return 'مراجعة طلب #$number';
  }

  @override
  String reviewSubtitle(String counter, int number, String time) {
    return '$counter · وردية #$number · $time';
  }

  @override
  String get reviewPaidTitle => 'تم التحصيل · التذاكر شغالة';

  @override
  String reviewPaidSubtitle(int count, String total, String method) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكرة اتطبعت · $total · $method',
      few: '$count تذاكر اتطبعت · $total · $method',
    );
    return '$_temp0';
  }

  @override
  String get reviewPrintingTitle => 'تم التحصيل · بنطبع التذاكر…';

  @override
  String get reviewFailedSubtitle =>
      'التحصيل اتأكد. اتأكد من الطابعة واضغط إعادة المحاولة.';

  @override
  String get reviewTickets => 'التذاكر';

  @override
  String get ticketPrinted => 'اتطبعت';

  @override
  String get ticketPrintFailed => 'فشلت الطباعة';

  @override
  String get ticketPrinting => 'بتتطبع…';

  @override
  String get ticketWaiting => 'مستنية الطباعة';

  @override
  String get reviewReprintNote =>
      'إعادة الطباعة بتتسجل باسمك والسبب، وبتظهر للإدارة في سجل الإجراءات.';

  @override
  String get reprint => 'إعادة طباعة';

  @override
  String get newOrder => 'طلب جديد';

  @override
  String get reviewShortcutsHint => 'Enter لطلب جديد';

  @override
  String get back => 'رجوع';

  @override
  String get close => 'إغلاق';

  @override
  String todayAt(String time) {
    return 'اليوم $time';
  }

  @override
  String get lookupTitle => 'البحث عن تذكرة';

  @override
  String get lookupCodeLabel => 'امسح التذكرة بالقارئ أو اكتب الكود';

  @override
  String get lookupSearch => 'بحث';

  @override
  String get lookupOrder => 'الطلب';

  @override
  String get lookupSold => 'اتباعت';

  @override
  String get lookupCashier => 'الكاشير';

  @override
  String get lookupValidUntil => 'صالحة لحد';

  @override
  String get lookupEntriesLeft => 'مرات الدخول المتبقية';

  @override
  String lookupEntriesValue(int left, int allowed) {
    return '$left من $allowed';
  }

  @override
  String get lookupPrintCount => 'مرات الطباعة';

  @override
  String get lookupHomeGate => 'بوابة الدخول';

  @override
  String get lookupScansTitle => 'سجل المسح على البوابات';

  @override
  String get lookupNoScans => 'التذكرة دي لسه ما اتمسحتش على أي بوابة.';

  @override
  String lookupNoteReactivate(String until, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'لو العميل عمل مسح ومعدّاش، تقدر ترجّع التذكرة صالحة لحد $until (فاضل $minutes دقيقة).',
      few:
          'لو العميل عمل مسح ومعدّاش، تقدر ترجّع التذكرة صالحة لحد $until (فاضل $minutes دقايق).',
      two:
          'لو العميل عمل مسح ومعدّاش، تقدر ترجّع التذكرة صالحة لحد $until (فاضل دقيقتين).',
      one:
          'لو العميل عمل مسح ومعدّاش، تقدر ترجّع التذكرة صالحة لحد $until (فاضل دقيقة).',
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
    return 'اتلغت $time بواسطة $actor · $counter · السبب: $reason.';
  }

  @override
  String lookupNoteVoidedAuto(String time) {
    return 'اتلغت $time تلقائي، لأن الطلب فضل من غير تحصيل.';
  }

  @override
  String get lookupNoteVoidedPlain => 'التذكرة دي ملغاة وما بتفتحش البوابة.';

  @override
  String get lookupNotePending =>
      'الطلب لسه ما اتحصّلش. التذكرة مش هتفتح البوابة غير بعد تأكيد التحصيل.';

  @override
  String lookupNoteExpired(String until) {
    return 'صلاحية التذكرة خلصت $until. ما ينفعش تتطبع تاني أو ترجع صالحة.';
  }

  @override
  String get statusActiveUnused => 'سليمة · لسه ما دخلتش';

  @override
  String get statusActive => 'سليمة';

  @override
  String get statusUsed => 'مستخدمة';

  @override
  String get statusVoided => 'ملغاة';

  @override
  String get statusPending => 'مش مدفوعة';

  @override
  String get statusExpired => 'منتهية';

  @override
  String get scanAccepted => 'اتقبلت';

  @override
  String scanRejected(String reason) {
    return 'مرفوضة · $reason';
  }

  @override
  String get scanReasonNotPaid => 'مش مدفوعة';

  @override
  String get scanReasonVoided => 'ملغاة';

  @override
  String get scanReasonUsedUp => 'مستخدمة قبل كده';

  @override
  String get scanReasonNotYetValid => 'لسه مش صالحة';

  @override
  String get scanReasonExpired => 'منتهية';

  @override
  String get scanReasonGateDisabled => 'البوابة مقفولة';

  @override
  String get scanReasonNotFound => 'كود مش معروف';

  @override
  String get actionDialogTitle => 'إجراء على التذكرة';

  @override
  String actionDialogTicket(String type) {
    return 'تذكرة $type';
  }

  @override
  String actionDialogOrder(int number) {
    return 'طلب #$number';
  }

  @override
  String get actionLabel => 'الإجراء';

  @override
  String get actionReactivate => 'إعادة تفعيل';

  @override
  String get actionReprint => 'إعادة طباعة';

  @override
  String get actionVoidRefund => 'إلغاء واسترداد';

  @override
  String get actionHelpReactivate =>
      'التذكرة ترجع صالحة لدخول واحد. استخدمها لو العميل عمل مسح ومعدّاش.';

  @override
  String get actionHelpReprint =>
      'هتتطبع نسخة جديدة بنفس الكود. النسخة القديمة والجديدة نفس التذكرة، فدخول واحد بس.';

  @override
  String get actionHelpVoidRefund =>
      'التذكرة هتتلغي وهتترفض على البوابة، والمبلغ يتخصم من الوردية.';

  @override
  String actionBlocked(String action, String reason) {
    return '$action: $reason';
  }

  @override
  String actionLimitReactivate(int max, int window) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'مسموحة $max مرة للتذكرة، وخلال $window دقايق من آخر مسح عليها.',
      few: 'مسموحة $max مرات للتذكرة، وخلال $window دقايق من آخر مسح عليها.',
      two: 'مسموحة مرتين للتذكرة، وخلال $window دقايق من آخر مسح عليها.',
      one: 'مسموحة مرة واحدة للتذكرة، وخلال $window دقايق من آخر مسح عليها.',
    );
    return '$_temp0';
  }

  @override
  String get actionLimitReprint =>
      'عدد مرات الطباعة بيظهر على التذكرة وفي السجل.';

  @override
  String get actionLimitRefundBoth =>
      'متاح بس لتذكرة ما اتمسحتش على أي بوابة، وفي نفس الوردية اللي اتباعت فيها.';

  @override
  String get actionLimitRefundBeforeScan =>
      'متاح بس لتذكرة ما اتمسحتش على أي بوابة.';

  @override
  String get actionLimitRefundSameShift =>
      'متاح بس في نفس الوردية اللي اتباعت فيها.';

  @override
  String get actionLimitRefundAny => 'متاح لأي تذكرة مدفوعة.';

  @override
  String get refundInCash => 'رجّع للعميل نقدي';

  @override
  String get refundToCard => 'رجّع للعميل على الكارت';

  @override
  String get refundToWallet => 'رجّع للعميل على المحفظة';

  @override
  String get actionReasonLabel => 'السبب (إجباري)';

  @override
  String get actionReasonNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get actionReasonTextRequiredLabel => 'اكتب السبب (إجباري)';

  @override
  String get actionReasonTextRequired => 'لازم تكتب السبب';

  @override
  String get reasonScannedNotPassed => 'عمل مسح ومعدّاش';

  @override
  String get reasonGateDidNotOpen => 'البوابة ما فتحتش';

  @override
  String get reasonPrintFailed => 'الطباعة باظت';

  @override
  String get reasonTicketLost => 'العميل ضيّع التذكرة';

  @override
  String get reasonCustomerChangedMind => 'العميل غيّر رأيه';

  @override
  String get reasonWrongTicketType => 'نوع تذكرة غلط';

  @override
  String get reasonOther => 'سبب آخر';

  @override
  String get reasonUnpaidTimeout => 'الطلب ما اتحصّلش في الوقت';

  @override
  String get actionConfirmReactivate => 'إعادة التفعيل';

  @override
  String get actionConfirmReprint => 'إعادة الطباعة';

  @override
  String actionConfirmVoidRefund(String amount) {
    return 'إلغاء واسترداد $amount';
  }

  @override
  String get actionFootnote =>
      'الإجراء بيتسجل باسمك والشباك والسبب والوقت، وبيظهر للإدارة في سجل الإجراءات.';

  @override
  String get actionCopyPrinting => 'إعادة الطباعة اتسجلت · النسخة بتتطبع…';

  @override
  String get actionCopyFailed =>
      'إعادة الطباعة اتسجلت بس النسخة ما اتطبعتش. اتأكد من الطابعة واضغط إعادة المحاولة.';

  @override
  String get actionCloseCopy => 'إغلاق من غير طباعة';

  @override
  String get outcomeReprinted => 'النسخة اتطبعت، وإعادة الطباعة اتسجلت.';

  @override
  String get outcomeReprintNotPrinted =>
      'إعادة الطباعة اتسجلت بس النسخة ما اتطبعتش.';

  @override
  String get outcomeReactivated => 'التذكرة رجعت صالحة لدخول واحد.';

  @override
  String outcomeRefunded(String how, String amount) {
    return 'التذكرة اتلغت. $how: $amount';
  }

  @override
  String get ticketFailureNotFound => 'مفيش تذكرة بالكود ده.';

  @override
  String get ticketFailureNoOpenShift => 'لازم وردية مفتوحة عشان تعمل إجراء.';

  @override
  String get ticketFailureVoided => 'التذكرة ملغاة.';

  @override
  String get ticketFailureUsed => 'التذكرة مستخدمة. رجّعها صالحة الأول.';

  @override
  String get ticketFailureExpired => 'صلاحية التذكرة خلصت.';

  @override
  String get ticketFailureNotScanned => 'التذكرة ما دخلتش من أي بوابة.';

  @override
  String get ticketFailureAlreadyReactivated => 'آخر مسح عليها اترجع خلاص.';

  @override
  String get ticketFailureReactivationLimit =>
      'التذكرة رجعت صالحة أقصى عدد مرات مسموح.';

  @override
  String get ticketFailureReactivationWindow =>
      'الوقت المسموح بعد آخر مسح خلص.';

  @override
  String get ticketFailureNotPaid =>
      'الطلب لسه ما اتحصّلش. ألغِ الطلب بدل كده.';

  @override
  String get ticketFailureAlreadyScanned => 'التذكرة اتمسحت ودخلت قبل كده.';

  @override
  String get ticketFailureNotSameShift => 'التذكرة اتباعت في وردية تانية.';

  @override
  String get ticketCopyLabel => 'الطباعة';

  @override
  String ticketCopyValue(int count) {
    return 'نسخة $count';
  }

  @override
  String get ticketRefunded => 'اتلغت واترجع مبلغها';

  @override
  String get ticketLeftUnprinted => 'ما اتطبعتش · اتسجلت';

  @override
  String unprintedDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكرة ما اتطبعتش',
      few: '$count تذاكر ما اتطبعتش',
      two: 'تذكرتين ما اتطبعوش',
      one: 'تذكرة واحدة ما اتطبعتش',
    );
    return '$_temp0';
  }

  @override
  String get unprintedDialogBody =>
      'لو غادرت الطلب، مفيش حاجة تقدر تطبعها تاني: الكود مش على ورق. اتأكد من الطابعة واضغط إعادة المحاولة، أو اختار السبب وغادر الطلب.';

  @override
  String get unprintedDialogReason => 'سبب مغادرة الطلب';

  @override
  String get leaveReasonPrintedAfterAll => 'اتطبعت فعلاً والعميل استلمها';

  @override
  String get leaveReasonCustomerLeft => 'العميل مشي من غيرها';

  @override
  String get unprintedDialogLogged =>
      'ده بيتسجل باسمك والسبب، وبيظهر للإدارة للمراجعة.';

  @override
  String get unprintedLeave => 'مغادرة الطلب';

  @override
  String get reviewPaidShortTitle => 'تم التحصيل';

  @override
  String reviewPartlyRefundedSubtitle(int active, int refunded) {
    String _temp0 = intl.Intl.pluralLogic(
      active,
      locale: localeName,
      other: '$active تذكرة شغالة · $refunded اتلغت واترجع مبلغها',
      few: '$active تذاكر شغالة · $refunded اتلغت واترجع مبلغها',
      two: 'تذكرتين شغالين · $refunded اتلغت واترجع مبلغها',
      one: 'تذكرة واحدة شغالة · $refunded اتلغت واترجع مبلغها',
    );
    return '$_temp0';
  }

  @override
  String reviewAllRefundedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'التذاكر كلها اتلغت',
      two: 'التذكرتين اتلغوا',
      one: 'التذكرة اتلغت',
    );
    return '$_temp0';
  }

  @override
  String reviewAllRefundedSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكرة اتلغت واترجع مبلغها',
      few: '$count تذاكر اتلغت واترجع مبلغها',
      two: 'اترجع مبلغهم للعميل',
      one: 'اترجع مبلغها للعميل',
    );
    return '$_temp0';
  }

  @override
  String reviewLeftSubtitle(int printed, int left) {
    return '$printed اتطبعت · $left ما اتطبعتش (اتسجلت)';
  }

  @override
  String retryAllFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حاول تاني للـ$count تذكرة',
      few: 'حاول تاني للـ$count تذاكر',
      two: 'حاول تاني للتذكرتين',
      one: 'حاول تاني للتذكرة',
    );
    return '$_temp0';
  }

  @override
  String closeShiftTitle(int number) {
    return 'قفل الوردية #$number';
  }

  @override
  String closeShiftSubtitle(
    String counter,
    String from,
    String to,
    String cashier,
  ) {
    return '$counter · من $from لحد $to · $cashier';
  }

  @override
  String get countHeading => 'عدّ كل الفلوس اللي في الدرج';

  @override
  String get countHint =>
      'اكتب عدد الورق من كل فئة، شامل العهدة والإكراميات. تقدر تكتب العدد مباشرة أو تستخدم + و −.';

  @override
  String denominationLabel(String amount) {
    return '$amount ج';
  }

  @override
  String denominationCountLabel(String amount) {
    return 'عدد ورق فئة $amount جنيه';
  }

  @override
  String get countedTotal => 'إجمالي المعدود';

  @override
  String get tipsHeading => 'الإكراميات';

  @override
  String get tipsHint =>
      'اللي سجّلتها مع العملاء خلال الوردية. لو نسيت تسجّل إكرامية، ضيفها هنا قبل القفل.';

  @override
  String get tipsNone => 'مفيش إكراميات متسجلة في الوردية دي.';

  @override
  String tipWithOrder(int number) {
    return 'مع طلب #$number';
  }

  @override
  String get tipAddedAtClose => 'اتضافت وقت القفل';

  @override
  String get addTipHeading => 'إضافة إكرامية منسية';

  @override
  String get addTipTypedLabel => 'أو اكتب المبلغ (ج.م)';

  @override
  String get addTipTypedHint => 'مثلًا 35';

  @override
  String addTipButton(String amount) {
    return 'إضافة $amount';
  }

  @override
  String get addTipButtonEmpty => 'اختار مبلغ الإكرامية';

  @override
  String get addTipNote => 'الإكرامية بعد ما تتضاف مش بتتشال.';

  @override
  String tipsTotal(int count) {
    return 'إجمالي الإكراميات · $count';
  }

  @override
  String get tipsDisabledNote => 'الإكراميات مقفولة في الإعدادات.';

  @override
  String get tipFailureInvalid => 'مبلغ الإكرامية لازم يكون أكبر من صفر.';

  @override
  String get closeShiftButton => 'قفل الوردية وطباعة الملخص';

  @override
  String get closeShiftNote => 'بعد القفل مفيش تعديل على العدّ أو الإكراميات.';

  @override
  String closeAwaitingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فيه $count طلب لسه مستنيين الدفع',
      few: 'فيه $count طلبات لسه مستنية الدفع',
      two: 'فيه طلبين لسه مستنيين الدفع',
      one: 'فيه طلب لسه مستني الدفع',
    );
    return '$_temp0';
  }

  @override
  String closeAwaitingBody(int minutes) {
    return 'أكّد الدفع أو الغي الطلب قبل القفل. لو مش ظاهر قدامك (مثلًا التطبيق اتقفل وانت على شاشة الدفع)، النظام هيلغيه لوحده بعد $minutes دقيقة من البيع، وبعدها تقدر تقفل.';
  }

  @override
  String get closeCheckAgain => 'شوف تاني';

  @override
  String get closeFailureInvalidCount =>
      'العدّ فيه رقم غلط. راجع الأعداد وحاول تاني.';

  @override
  String get closeFailureNoOpenShift =>
      'الوردية دي اتقفلت خلاص. الملخص مش هيتطبع من هنا؛ المشرف يقدر يشوفها في صفحة الورديات.';

  @override
  String closeConfirmTitle(int number) {
    return 'قفل الوردية #$number؟';
  }

  @override
  String closeConfirmBody(String amount) {
    return 'النقدية المعدودة: $amount. بعد القفل مفيش تعديل على العدّ أو الإكراميات.';
  }

  @override
  String get closeConfirmZero =>
      'إنت ما عدّتش أي فلوس. اتأكد إن الدرج فاضي فعلًا.';

  @override
  String get closeConfirmButton => 'اقفل الوردية';

  @override
  String closedTitle(int number) {
    return 'الوردية #$number اتقفلت';
  }

  @override
  String get receiptPrinting => 'بنطبع الملخص…';

  @override
  String get receiptPrinted =>
      'الملخص اتطبع. وقّع عليه وسلّمه مع الدرج للمشرف.';

  @override
  String get receiptPrintFailed =>
      'الملخص ما اتطبعش. اتأكد من الطابعة (الورق، الكهربا) ودوس حاول تاني.';

  @override
  String get receiptNoPrinter =>
      'مفيش طابعة متسجلة للشباك ده، فالملخص ما اتطبعش. المشرف يقدر يشوف الوردية في صفحة الورديات.';

  @override
  String get receiptOnlyHere =>
      'الملخص بيتطبع من هنا بس: بعد الخروج مش هتقدر تطبعه تاني.';

  @override
  String get closedDone => 'تمام، خروج';

  @override
  String get closedLeaveTitle => 'تخرج من غير الملخص المطبوع؟';

  @override
  String get closedLeaveBody =>
      'مش هتقدر تطبعه بعد كده. المشرف يقدر يشوف الوردية في صفحة الورديات.';

  @override
  String get closedLeave => 'خروج';

  @override
  String get receiptTitle => 'إقرار قفل الوردية';

  @override
  String get receiptShift => 'الوردية';

  @override
  String receiptShiftValue(int number, String counter) {
    return '#$number · $counter';
  }

  @override
  String get receiptCashier => 'الكاشير';

  @override
  String get receiptFrom => 'من';

  @override
  String get receiptTo => 'لحد';

  @override
  String get receiptTicketsSold => 'التذاكر المباعة';

  @override
  String receiptTicketsTotal(int orders) {
    return 'الإجمالي · $orders طلب';
  }

  @override
  String get receiptStatement => 'إقرار الكاشير';

  @override
  String get receiptCounted => 'النقدية المعدودة';

  @override
  String receiptTips(int count) {
    return 'منها إكراميات ($count)';
  }

  @override
  String get receiptTipsAtClose => 'إكراميات اتضافت وقت القفل';

  @override
  String get receiptReprints => 'إعادة طباعة';

  @override
  String get receiptReactivations => 'إعادة تفعيل';

  @override
  String get receiptRefunds => 'إلغاء واسترداد';

  @override
  String get receiptCancelledOrders => 'طلبات اتلغت';

  @override
  String get receiptLeftUnprinted => 'تذاكر ما اتطبعتش';

  @override
  String get receiptFooter => 'المطابقة مع المتوقع بيعملها المشرف في النظام';

  @override
  String get receiptCashierSignature => 'توقيع الكاشير';

  @override
  String get receiptSupervisorSignature => 'توقيع المشرف';

  @override
  String get serverBadgeOnline => 'متصل بالسيرفر';

  @override
  String get serverBadgeOffline => 'مفيش اتصال بالسيرفر';

  @override
  String get serverBadgeChecking => 'بنفحص الاتصال…';

  @override
  String get offlineBannerTitle =>
      'شغالين أوفلاين: البيع بس، الدفع الأول وبعدين الطباعة';

  @override
  String get offlineBannerBody =>
      'الطلبات بتتحفظ على الجهاز ده وبتترفع لوحدها أول ما السيرفر يرجع.';

  @override
  String offlineFreeCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فاضل $count كود أوفلاين',
      few: 'فاضل $count أكواد أوفلاين',
      two: 'فاضل كودين أوفلاين',
      one: 'فاضل كود أوفلاين واحد',
      zero: 'مفيش أكواد أوفلاين',
    );
    return '$_temp0';
  }

  @override
  String offlineQueuePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب مستنيين يترفعوا',
      few: '$count طلبات مستنية تترفع',
      two: 'طلبين مستنيين يترفعوا',
      one: 'طلب مستني يترفع',
    );
    return '$_temp0';
  }

  @override
  String get offlineQueueUploading => 'بنرفع طلبات الأوفلاين…';

  @override
  String offlineQueueRefused(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب السيرفر رفضهم',
      few: '$count طلبات السيرفر رفضها',
      two: 'طلبين السيرفر رفضهم',
      one: 'طلب السيرفر رفضه',
    );
    return '$_temp0';
  }

  @override
  String get offlinePoolUnavailable =>
      'مفيش أكواد أوفلاين للشباك ده (ليه بوابة؟). كلّم الأدمن: من غيرها مش هتقدر تبيع لو الاتصال وقع.';

  @override
  String get offlineRefusedTitle => 'طلبات السيرفر رفضها';

  @override
  String get offlineRefusedBody =>
      'دي اتباعت أو اتسجلت أوفلاين والسيرفر رفض رفعها. كلّم المشرف: الوردية مش هتتقفل غير لما تتحل.';

  @override
  String offlineRefusedRow(int number, String time, String reason) {
    return '#$number أوفلاين · $time · $reason';
  }

  @override
  String get offlineRefusalCodeNotInPool => 'الكود مش من أكواد الشباك';

  @override
  String get offlineRefusalSoldAt =>
      'وقت البيع مش مظبوط مع الوردية (ساعة الجهاز مظبوطة؟)';

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
      other: '$count إجراء متسجل مستنيين يترفعوا',
      few: '$count إجراءات متسجلة مستنية تترفع',
      two: 'إجراءين متسجلين مستنيين يترفعوا',
      one: 'إجراء متسجل مستني يترفع',
    );
    return '$_temp0';
  }

  @override
  String closeQueueActionsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فيه $count إجراء متسجل لسه ما اترفعوش',
      few: 'فيه $count إجراءات متسجلة لسه ما اترفعتش',
      two: 'فيه إجراءين متسجلين لسه ما اترفعوش',
      one: 'فيه إجراء متسجل لسه ما اترفعش',
    );
    return '$_temp0';
  }

  @override
  String get offlineRefusalTypeUnavailable => 'نوع تذكرة مش معروف';

  @override
  String offlineRefusalOther(String key) {
    return 'خطأ: $key';
  }

  @override
  String get needsServer => 'محتاج السيرفر';

  @override
  String get sellConnectionLost =>
      'الاتصال بالسيرفر وقع. اضغط طباعة التذاكر والتحصيل تاني عشان تبيع أوفلاين.';

  @override
  String get sellFailureOfflineDisabled =>
      'البيع أوفلاين مقفول من الإعدادات. استنى السيرفر يرجع.';

  @override
  String get sellFailureOfflinePoolEmpty =>
      'أكواد الأوفلاين مش كفاية للطلب ده. بيع تذاكر أقل، أو استنى السيرفر يرجع.';

  @override
  String get sellFailureOfflineZone =>
      'توقيت الجهاز ده مش توقيت المكان، فتذاكر اليوم ما تتباعش أوفلاين. كلّم الأدمن يظبط توقيت الجهاز.';

  @override
  String orderSummaryOffline(int number) {
    return 'ملخص الطلب #$number (أوفلاين)';
  }

  @override
  String get offlinePrintTitle => 'التذاكر هتتطبع بعد تأكيد التحصيل';

  @override
  String get offlinePrintHint =>
      'إحنا أوفلاين: استلم الفلوس الأول. بعد التأكيد التذاكر بتتطبع مدفوعة وشغالة.';

  @override
  String get offlineBackHint => 'لسه مفيش حاجة اتسجلت';

  @override
  String reviewTitleOffline(int number) {
    return 'مراجعة طلب #$number (أوفلاين)';
  }

  @override
  String get reviewOfflineNote =>
      'الطلب ده اتباع أوفلاين وهيترفع للسيرفر لوحده أول ما الاتصال يرجع. إعادة الطباعة بتتسجل وتترفع بعده، والإلغاء والاسترجاع محتاجين السيرفر.';

  @override
  String get unprintedDialogOffline =>
      'هيتسجل على الجهاز ده بالسبب ويتعلّم للمشرف، ويترفع لما السيرفر يرجع.';

  @override
  String ticketOrderValueOffline(String number, String index, String count) {
    return '#$number أوفلاين · $index من $count';
  }

  @override
  String closeQueueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فيه $count طلب أوفلاين لسه ما اترفعوش',
      few: 'فيه $count طلبات أوفلاين لسه ما اترفعتش',
      two: 'فيه طلبين أوفلاين لسه ما اترفعوش',
      one: 'فيه طلب أوفلاين لسه ما اترفعش',
    );
    return '$_temp0';
  }

  @override
  String get closeQueueBody =>
      'الوردية تتقفل بعد ما يترفعوا. بيترفعوا لوحدهم طول ما السيرفر بيرد.';

  @override
  String get closeQueueRefusedBody =>
      'السيرفر رفض بعضهم: كلّم المشرف. الوردية مش هتتقفل غير لما يتحلوا.';

  @override
  String get uploadNow => 'ارفع دلوقتي';

  @override
  String get adminMenuTitle => 'الإدارة';

  @override
  String get navDashboard => 'لوحة المتابعة';

  @override
  String get navShifts => 'الورديات';

  @override
  String get navReports => 'التقارير';

  @override
  String get navTicketTypes => 'أنواع التذاكر والأسعار';

  @override
  String get navActionsLog => 'سجل الإجراءات';

  @override
  String get navGates => 'البوابات';

  @override
  String get navUsers => 'المستخدمين';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String dashboardDateLive(String date) {
    return '$date · بتتحدث لحظيًا';
  }

  @override
  String dashboardDatePolling(String date, int seconds) {
    return '$date · بتتحدث كل $seconds ثانية';
  }

  @override
  String get dashboardLive => 'مباشر';

  @override
  String get dashboardNotLive => 'مش لحظي';

  @override
  String get dashboardEntriesToday => 'الدخول النهارده';

  @override
  String dashboardSince(String time) {
    return 'من $time';
  }

  @override
  String get dashboardNoEntriesYet => 'لسه محدش دخل';

  @override
  String get dashboardSalesToday => 'مبيعات النهارده';

  @override
  String dashboardOpenCounters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شباك شغال',
      few: '$count شبابيك شغالة',
      two: 'شباكين شغالين',
      one: 'شباك واحد شغال',
      zero: 'مفيش شبابيك شغالة',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTicketsSold => 'تذاكر مباعة';

  @override
  String dashboardNotEntered(int count) {
    return '$count لسه ما دخلتش';
  }

  @override
  String get dashboardRejected => 'مرفوض على البوابات';

  @override
  String get dashboardNoRejections => 'مفيش رفض النهارده';

  @override
  String dashboardReasonCount(int count, String reason) {
    return '$count $reason';
  }

  @override
  String get gateOnline => 'شغالة';

  @override
  String get gateOffline => 'مش متصلة';

  @override
  String get gateNeverSeen => 'ما اتصلتش';

  @override
  String get gateDisabled => 'متوقفة';

  @override
  String get gateEntriesToday => 'دخول اليوم';

  @override
  String get gateRejected => 'مرفوض';

  @override
  String gateLastScanSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'آخر مسح من $count ثانية',
      few: 'آخر مسح من $count ثواني',
      two: 'آخر مسح من ثانيتين',
      one: 'آخر مسح من ثانية',
    );
    return '$_temp0';
  }

  @override
  String gateLastScanMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'آخر مسح من $count دقيقة',
      few: 'آخر مسح من $count دقايق',
      two: 'آخر مسح من دقيقتين',
      one: 'آخر مسح من دقيقة',
    );
    return '$_temp0';
  }

  @override
  String gateLastScanAt(String time) {
    return 'آخر مسح $time';
  }

  @override
  String get gateNoScans => 'مفيش مسح لسه';

  @override
  String gateOfflineSince(String time) {
    return 'مفيش اتصال من $time · راجع الكهربا والشبكة';
  }

  @override
  String get gateNeverSeenNote =>
      'خدمة البوابة ما اتصلتش بالسيرفر · راجع إنها شغالة';

  @override
  String get gateDisabledNote => 'متوقفة من صفحة البوابات';

  @override
  String get dashboardNoGates => 'مفيش بوابات دخول متسجلة';

  @override
  String get dashboardHourlyTitle => 'الدخول بالساعة';

  @override
  String get dashboardHourlyLabel => 'عدد الداخلين في كل ساعة النهارده';

  @override
  String get dashboardHourlyEmpty => 'لسه مفيش دخول النهارده';

  @override
  String get dashboardFeedTitle => 'آخر عمليات المسح';

  @override
  String get dashboardFeedEmpty => 'لسه مفيش مسح';

  @override
  String get feedAccepted => 'اتقبلت';

  @override
  String get feedPoolCode => 'كود أوفلاين';

  @override
  String dashboardStale(String time) {
    return 'مش قادر يوصل للسيرفر. آخر تحديث $time.';
  }

  @override
  String get dashboardUnreachable => 'مش قادر يوصل للسيرفر.';

  @override
  String get dashboardUnexpected =>
      'اللوحة ما اتحمّلتش. حاول تاني، ولو المشكلة فضلت كلّم الدعم.';

  @override
  String get dashboardNotAllowed => 'اللوحة دي للمشرفين والمديرين بس.';

  @override
  String get shiftsTitle => 'الورديات ومطابقة النقدية';

  @override
  String get shiftsSubtitle =>
      'الكاشير بيعدّ من غير ما يعرف المتوقع. المطابقة والاعتماد هنا بس.';

  @override
  String get shiftsPeriodToday => 'النهارده';

  @override
  String get shiftsPeriodYesterday => 'أمس';

  @override
  String get shiftsPeriodWeek => 'آخر 7 أيام';

  @override
  String shiftsPeriodPending(int count) {
    return 'محتاجة مطابقة ($count)';
  }

  @override
  String get shiftsRefresh => 'تحديث';

  @override
  String get shiftsColShift => 'الوردية';

  @override
  String get shiftsColCashier => 'الكاشير · الشباك';

  @override
  String get shiftsColExpected => 'المتوقع';

  @override
  String get shiftsColCounted => 'المعدود';

  @override
  String get shiftsColDifference => 'الفرق';

  @override
  String get shiftsColStatus => 'الحالة';

  @override
  String get shiftsEmpty => 'مفيش ورديات في الفترة دي.';

  @override
  String get shiftsEmptyPending => 'مفيش ورديات مستنية اعتماد.';

  @override
  String get shiftsPickOne => 'اختار وردية من الجدول.';

  @override
  String shiftTitle(int number) {
    return 'وردية #$number';
  }

  @override
  String shiftUntilOpen(String from) {
    return '$from → مفتوحة';
  }

  @override
  String get shiftStatusOpen => 'مفتوحة';

  @override
  String get shiftStatusNeedsApproval => 'محتاجة مطابقة';

  @override
  String get shiftStatusApproved => 'معتمدة';

  @override
  String get shiftOpeningFloat => 'عهدة البداية';

  @override
  String get shiftCashSales => 'مبيعات نقدية';

  @override
  String shiftTips(int count) {
    return 'إكراميات مسجّلة · $count';
  }

  @override
  String get shiftCashRefunds => 'مرتجعات نقدية';

  @override
  String get shiftExpected => 'المتوقع في الدرج';

  @override
  String get shiftCounted => 'اللي الكاشير عدّه';

  @override
  String get shiftBalanced => 'مطابق';

  @override
  String get shiftShortage => 'عجز';

  @override
  String get shiftSurplus => 'زيادة';

  @override
  String shiftNonCash(String card, String wallet) {
    return 'غير نقدي (للمعلومية): كارت $card · محفظة $wallet';
  }

  @override
  String shiftPaidOrders(int count) {
    return 'الطلبات المدفوعة (كل طرق الدفع): $count';
  }

  @override
  String shiftActions(int count) {
    return 'إجراءات الوردية في السجل: $count';
  }

  @override
  String shiftActionsFlagged(int count, int flagged) {
    return 'إجراءات الوردية في السجل: $count ($flagged عليها علامة مراجعة)';
  }

  @override
  String get shiftOpenNote =>
      'الوردية لسه مفتوحة. المطابقة بتظهر بعد ما الكاشير يقفلها ويعدّ.';

  @override
  String shiftApprovedBy(String name, String time) {
    return 'اعتمدها $name · $time';
  }

  @override
  String shiftApprovalComment(String comment) {
    return 'التعليق: $comment';
  }

  @override
  String get shiftNoteOptional => 'ملاحظة (اختياري)';

  @override
  String get shiftNoteRequired => 'تعليق على الفرق (إجباري)';

  @override
  String get shiftApprove => 'اعتماد الوردية';

  @override
  String get shiftOwnShift =>
      'دي ورديتك، فمينفعش تعتمدها. لازم مشرف أو مدير تاني.';

  @override
  String shiftApprovedDone(int number) {
    return 'الوردية #$number اتعتمدت.';
  }

  @override
  String shiftOfflineOrders(int count) {
    return 'طلبات أوفلاين اترفعت: $count';
  }

  @override
  String shiftUnsyncedEntries(int count) {
    return 'أكواد أوفلاين دخلت قبل ما بيعها يترفع: $count';
  }

  @override
  String shiftRefusedOrders(int count) {
    return 'طلبات أوفلاين السيرفر رفضها: $count. فلوسها في الدرج بس مش في الأرقام، فبتبان في الفرق.';
  }

  @override
  String get refusalsTitle => 'اترفض وهو بيترفع';

  @override
  String get refusalKindOrder => 'طلب أوفلاين';

  @override
  String get refusalKindAction => 'إجراء أوفلاين';

  @override
  String refusalReportedAt(String time) {
    return 'وصل $time';
  }

  @override
  String refusalOrderSummary(String time, String method, String tickets) {
    return 'اتباع $time · $method · $tickets';
  }

  @override
  String refusalTicketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكرة',
      few: '$count تذاكر',
      two: 'تذكرتين',
      one: 'تذكرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get refusalUnknownType => 'نوع مش معروف';

  @override
  String refusalTip(String amount) {
    return 'إكرامية $amount';
  }

  @override
  String get refusalLeftUnprinted => 'تذكرة ما اتطبعتش';

  @override
  String get refusalOpen =>
      'مفتوح: الكاشير مش هيقدر يقفل الوردية غير لما يتمسح.';

  @override
  String get refusalAccepted => 'اترفع بعد كده.';

  @override
  String refusalCleared(String name, String time, String comment) {
    return 'مسحه $name · $time: $comment';
  }

  @override
  String get refusalClear => 'مسح';

  @override
  String get refusalOwnShift => 'دي ورديتك، فمينفعش تمسح الرفض.';

  @override
  String get refusalClearTitle => 'مسح الرفض';

  @override
  String get refusalClearBody =>
      'اكتب اللي عملته. اللي اتبعت مش هيترفع، وفلوس الطلب المرفوض هتفضل باينة في فرق الوردية.';

  @override
  String get refusalCommentLabel => 'التعليق (إجباري)';

  @override
  String get orphansTitle => 'دخول من غير وردية';

  @override
  String get orphansHint =>
      'أكواد أوفلاين دخلت وشباكها مكانش عليه وردية مفتوحة. مش محسوبة على أي وردية، ومفيش بيع هييجي ليها.';

  @override
  String get shiftsNotAllowed => 'الصفحة دي للمشرفين والمديرين بس.';

  @override
  String get shiftsUnexpected =>
      'الورديات ما اتحملتش. جرّب تاني، ولو فضلت كده كلّم الدعم.';

  @override
  String get shiftDetailFailed => 'تفاصيل الوردية ما اتحملتش.';

  @override
  String get shiftFailureCommentRequired => 'التعليق إجباري.';

  @override
  String get shiftFailureOwnShift => 'مينفعش تعتمد أو تمسح حاجة في ورديتك.';

  @override
  String get shiftFailureAlreadyApproved => 'الوردية دي اتعتمدت قبل كده.';

  @override
  String get shiftFailureNotClosed => 'الوردية لسه مفتوحة.';

  @override
  String get shiftFailureRefusalClosed => 'الرفض ده اتقفل قبل كده.';

  @override
  String get shiftFailureNotFound => 'مش لاقي الوردية دي.';

  @override
  String get actionsSubtitle =>
      'إعادة الطباعة وإعادة التفعيل والإلغاء اللي عملها الكاشيرية من غير موافقة';

  @override
  String get actionsExport => 'تصدير CSV';

  @override
  String get actionsRefresh => 'تحديث';

  @override
  String get actionsTileReview => 'محتاجة مراجعة';

  @override
  String get actionsShow => 'عرض';

  @override
  String actionsPeriodReview(int count) {
    return 'محتاجة مراجعة ($count)';
  }

  @override
  String actionsShiftChip(int number, String cashier, String counter) {
    return 'وردية #$number · $cashier · $counter';
  }

  @override
  String get actionsShiftClear => 'كل الورديات';

  @override
  String get actionsTypeAll => 'الكل';

  @override
  String get actionsTypeOffline => 'أوفلاين';

  @override
  String get actionsAllCashiers => 'كل الكاشيرية';

  @override
  String get actionsAllCounters => 'كل الشبابيك';

  @override
  String get actionsColTime => 'الوقت';

  @override
  String get actionsColWho => 'الكاشير · الشباك';

  @override
  String get actionsColAction => 'الإجراء';

  @override
  String get actionsColTicket => 'التذكرة';

  @override
  String get actionsColReason => 'السبب';

  @override
  String get actionsColReview => 'المراجعة';

  @override
  String get actionCancelOrder => 'إلغاء طلب';

  @override
  String get actionLeftUnprinted => 'ما اتطبعتش';

  @override
  String get actionOfflineAdjusted => 'وقت أوفلاين اتعدّل';

  @override
  String get actionTestOpen => 'فتح تجريبي';

  @override
  String get actionSettingsChange => 'تغيير إعدادات';

  @override
  String get actionsSystem => 'النظام';

  @override
  String actionsCopy(int number) {
    return 'الطبعة $number';
  }

  @override
  String actionsUndoneGate(String gate) {
    return 'المسح اللي اتلغى كان على $gate';
  }

  @override
  String actionsOtherReason(String text) {
    return 'سبب آخر: \"$text\"';
  }

  @override
  String actionsReasonNote(String text) {
    return 'ملاحظة: $text';
  }

  @override
  String actionsOfflineTimes(String claimed, String stored) {
    return 'وقت الجهاز $claimed ← اتسجل $stored';
  }

  @override
  String get adjustClockOutOfRange => 'ساعة الجهاز برّه وقت الوردية';

  @override
  String get adjustAfterClosing => 'بعد وقت القفل';

  @override
  String get adjustCodeExpired => 'الكود كان انتهى';

  @override
  String get flagOtherReason => 'سبب آخر';

  @override
  String flagTooManyActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إجراء للكاشير في الوردية',
      few: '$count إجراءات للكاشير في الوردية',
      two: 'إجراءين للكاشير في الوردية',
      one: 'إجراء واحد للكاشير في الوردية',
    );
    return '$_temp0';
  }

  @override
  String flagTooManyPrints(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'اتطبعت أكتر من $max مرة',
      few: 'اتطبعت أكتر من $max مرات',
      two: 'اتطبعت أكتر من مرتين',
      one: 'اتطبعت أكتر من مرة',
    );
    return '$_temp0';
  }

  @override
  String get flagReactivatedOtherGate => 'اتمسحت بعدها على بوابة تانية';

  @override
  String get flagUnprintedTicket => 'التذكرة ما اتطبعتش';

  @override
  String get flagOfflineTimeAdjusted => 'وقت البيع اتعدّل';

  @override
  String get flagOfflineReprint => 'إعادة طباعة أوفلاين';

  @override
  String get actionsReviewButton => 'تمت المراجعة';

  @override
  String actionsReviewedBy(String name) {
    return 'اتراجعت · $name';
  }

  @override
  String get actionsOwnAction => 'إجراءك، حد تاني يراجعه';

  @override
  String get actionsRulesTitle => 'إمتى الإجراء بيتعلّم للمراجعة';

  @override
  String get ruleOtherReason => 'السبب \"سبب آخر\"';

  @override
  String ruleTooManyActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أكتر من $count إجراء لنفس الكاشير في وردية واحدة',
      few: 'أكتر من $count إجراءات لنفس الكاشير في وردية واحدة',
      two: 'أكتر من إجراءين لنفس الكاشير في وردية واحدة',
      one: 'أكتر من إجراء واحد لنفس الكاشير في وردية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get ruleReactivatedOtherGate =>
      'إعادة تفعيل والتذكرة بعدها اتمسحت على بوابة تانية';

  @override
  String ruleTooManyPrints(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'تذكرة اتطبعت أكتر من $max مرة',
      few: 'تذكرة اتطبعت أكتر من $max مرات',
      two: 'تذكرة اتطبعت أكتر من مرتين',
      one: 'تذكرة اتطبعت أكتر من مرة',
    );
    return '$_temp0';
  }

  @override
  String get ruleUnprinted => 'دايماً: تذكرة الكاشير ساب طلبها من غير ما تتطبع';

  @override
  String get ruleOffline =>
      'دايماً: بيع أوفلاين وقته اتعدّل، أو إعادة طباعة أوفلاين';

  @override
  String get actionsRulesFootnote =>
      'القواعد دي إعدادات تقدر تغيّرها من صفحة الإعدادات.';

  @override
  String get actionsEmpty => 'مفيش إجراءات في الفترة دي.';

  @override
  String get actionsEmptyReview => 'مفيش حاجة محتاجة مراجعة.';

  @override
  String actionsTruncated(int shown, int total) {
    return 'معروض أحدث $shown من $total. ضيّق البحث بالكاشير أو الشباك، أو صدّر CSV للكل.';
  }

  @override
  String get actionsNotAllowed => 'الصفحة دي للمشرفين والإدارة بس.';

  @override
  String get actionsUnexpected => 'حصل خطأ في تحميل السجل.';

  @override
  String get actionsFailureOwnAction => 'ما تقدرش تراجع إجراء عملته بنفسك.';

  @override
  String get actionsFailureAlreadyReviewed => 'الإجراء ده اتراجع قبل كده.';

  @override
  String get actionsFailureNotFlagged => 'الإجراء ده مش عليه علامة مراجعة.';

  @override
  String get actionsFailureNotFound => 'مش لاقي الإجراء ده.';

  @override
  String actionsExported(String path) {
    return 'اتحفظ الملف: $path';
  }

  @override
  String get actionsOpenFolder => 'افتح المجلد';

  @override
  String get actionsExportNoFolder =>
      'مش لاقي مجلد التنزيلات (Downloads) على الجهاز ده.';

  @override
  String get actionsExportFailed => 'الملف ما اتحفظش.';

  @override
  String get csvTime => 'الوقت';

  @override
  String get csvCashier => 'الكاشير';

  @override
  String get csvCounter => 'الشباك';

  @override
  String get csvShift => 'الوردية';

  @override
  String get csvAction => 'الإجراء';

  @override
  String get csvOrder => 'الطلب';

  @override
  String get csvType => 'نوع التذكرة';

  @override
  String get csvCode => 'آخر 3 أرقام من الكود';

  @override
  String get csvCopy => 'الطبعة';

  @override
  String get csvAmount => 'المبلغ (ج.م)';

  @override
  String get csvMethod => 'طريقة الدفع';

  @override
  String get csvReason => 'السبب';

  @override
  String get csvReasonText => 'نص السبب';

  @override
  String get csvDetails => 'تفاصيل';

  @override
  String get csvFlags => 'علامات المراجعة';

  @override
  String get csvReviewedBy => 'راجعه';

  @override
  String get csvReviewedAt => 'وقت المراجعة';

  @override
  String get reportsTitle => 'تقرير المبيعات';

  @override
  String get reportsSubtitle =>
      'الصافي = المبيعات − المرتجعات + الإكراميات. المرتجع والإكرامية بيتحسبوا في يومهم، والإكرامية مالهاش نوع تذكرة.';

  @override
  String get reportsPeriod => 'الفترة';

  @override
  String get reportsGroupBy => 'تجميع حسب';

  @override
  String get reportsPeriodMonth => 'الشهر ده';

  @override
  String get reportsPeriodLastMonth => 'الشهر اللي فات';

  @override
  String get reportsPeriodRange => 'فترة تانية…';

  @override
  String get reportsRangeHelp => 'اختار أول وآخر يوم';

  @override
  String get reportsGroupType => 'نوع التذكرة';

  @override
  String get reportsGroupCashier => 'الكاشير';

  @override
  String get reportsGroupMethod => 'طريقة الدفع';

  @override
  String get reportsGroupDay => 'اليوم';

  @override
  String get reportsTileSales => 'إجمالي المبيعات';

  @override
  String get reportsTileRefunds => 'المرتجعات';

  @override
  String get reportsTileNet => 'الصافي';

  @override
  String get reportsTileTickets => 'التذاكر';

  @override
  String get reportsColTickets => 'إجمالي التذاكر';

  @override
  String get reportsColCounterGate => 'الشباك والبوابة';

  @override
  String get reportsGroupGate => 'البوابة';

  @override
  String get reportsColCounters => 'الشبابيك';

  @override
  String get reportsNoGate => 'من غير بوابة';

  @override
  String get reportsColSales => 'المبيعات (ج.م)';

  @override
  String get reportsColRefunds => 'المرتجعات (ج.م)';

  @override
  String get reportsColNet => 'الصافي (ج.م)';

  @override
  String get reportsColShare => 'النسبة من المبيعات';

  @override
  String get reportsTotal => 'الإجمالي';

  @override
  String reportsRefundCount(int count) {
    return '$count تذكرة';
  }

  @override
  String get reportsEmpty => 'مفيش مبيعات ولا مرتجعات في الفترة دي.';

  @override
  String get reportsLoading =>
      'بيتحسب التقرير… الفترات الطويلة بتاخد شوية وقت.';

  @override
  String get reportsNotAllowed => 'التقارير للمشرفين والأدمن بس.';

  @override
  String get reportsInvalidRange =>
      'الفترة دي مش صحيحة. اختار أول يوم قبل آخر يوم.';

  @override
  String get reportsBusy =>
      'فيه تقرير تاني شغال دلوقتي. استنى لحظة وجرّب تاني.';

  @override
  String get reportsUnexpected => 'حصل خطأ غير متوقع في التقرير.';

  @override
  String get reportsCsvSales => 'المبيعات (ج.م)';

  @override
  String get reportsCsvRefundCount => 'تذاكر مرتجعة';

  @override
  String get reportsCsvRefunds => 'المرتجعات (ج.م)';

  @override
  String get reportsCsvNet => 'الصافي (ج.م)';

  @override
  String get reportsCsvShare => 'النسبة من المبيعات (%)';

  @override
  String get reportsRangeFrom => 'من';

  @override
  String get reportsRangeTo => 'إلى';

  @override
  String reportsRangeDays(int count) {
    return '$count يوم';
  }

  @override
  String get reportsRangeApply => 'اعرض التقرير';

  @override
  String get reportsTooSlow =>
      'التقرير خد وقت أطول من اللازم ووقف. اختار فترة أقصر.';

  @override
  String get reportsTileTips => 'الإكراميات';

  @override
  String get reportsColTips => 'الإكراميات (ج.م)';

  @override
  String get reportsCsvTips => 'الإكراميات (ج.م)';

  @override
  String get typesNew => 'نوع جديد';

  @override
  String get typesColType => 'النوع';

  @override
  String get typesColPrice => 'السعر';

  @override
  String get typesColEntries => 'مرات الدخول';

  @override
  String get typesColValidity => 'الصلاحية';

  @override
  String get typesColStatus => 'الحالة';

  @override
  String get typesColOrder => 'الترتيب';

  @override
  String typesEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرة',
      few: '$count مرات',
      two: 'مرتين',
      one: 'مرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get typesValiditySameDay => 'يوم البيع';

  @override
  String typesValidityHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة من البيع',
      few: '$hours ساعات من البيع',
      two: 'ساعتين من البيع',
      one: 'ساعة من البيع',
    );
    return '$_temp0';
  }

  @override
  String get typesStatusActive => 'متاح';

  @override
  String get typesStatusInactive => 'متوقف';

  @override
  String get typesMoveUp => 'لفوق';

  @override
  String get typesMoveDown => 'لتحت';

  @override
  String typesEditTitle(String name) {
    return 'تعديل: $name';
  }

  @override
  String get typesNameAr => 'الاسم بالعربي';

  @override
  String get typesNameEn => 'الاسم بالإنجليزي';

  @override
  String get typesPrice => 'السعر (ج.م)';

  @override
  String get typesEntriesLabel => 'مرات الدخول';

  @override
  String get typesValidityLabel => 'الصلاحية';

  @override
  String get typesValidityOptionSameDay => 'يوم البيع لحد قفل المكان';

  @override
  String get typesValidityOptionHours => 'عدد ساعات من وقت البيع';

  @override
  String get typesHoursLabel => 'عدد الساعات';

  @override
  String get typesActiveLabel => 'متاح للبيع';

  @override
  String get typesActiveNote => 'لو اتقفل، بيختفي من شاشة الكاشير';

  @override
  String get typesPriceNote =>
      'تغيير السعر بيسري على المبيعات الجديدة بس. التذاكر اللي اتباعت بتفضل بسعرها.';

  @override
  String get typesLogNote => 'كل تغيير بيتسجل في سجل الإجراءات.';

  @override
  String get typesSave => 'حفظ التغييرات';

  @override
  String get typesAdd => 'إضافة النوع';

  @override
  String get typesSaved => 'اتحفظ.';

  @override
  String get typesLoading => 'بيحمّل أنواع التذاكر…';

  @override
  String get typesEmpty => 'مفيش أنواع تذاكر لسه. أضف أول نوع.';

  @override
  String get typesInvalidName => 'اكتب الاسم بالعربي والإنجليزي.';

  @override
  String get typesInvalidPrice => 'اكتب سعر صحيح، مثلاً 100 أو 12.50.';

  @override
  String get typesInvalidEntries => 'مرات الدخول لازم تكون 1 أو أكتر.';

  @override
  String get typesInvalidHours => 'عدد الساعات لازم يكون 1 أو أكتر.';

  @override
  String get typesNameTaken => 'فيه نوع تاني بالاسم ده.';

  @override
  String get typesNotFound => 'النوع ده مبقاش موجود. القائمة اتحدّثت.';

  @override
  String get typesNotAllowed => 'أنواع التذاكر والأسعار للأدمن بس.';

  @override
  String get typesUnexpected => 'حصل خطأ غير متوقع في أنواع التذاكر.';

  @override
  String get actionsTypeSettings => 'الإعدادات';

  @override
  String changeNewType(String name) {
    return 'نوع جديد: $name';
  }

  @override
  String changeTypeName(String name) {
    return 'نوع التذكرة $name';
  }

  @override
  String changeField(String field, String from, String to) {
    return '$field: من $from لـ $to';
  }

  @override
  String get sellFailureTypeNotNow =>
      'الفئة دي مش متاحة دلوقتي. القائمة اتحدّثت، راجع الطلب.';

  @override
  String get sellPeakChip => 'وقت الذروة';

  @override
  String get sellNothingOnSale => 'مفيش فئة متاحة للبيع دلوقتي. كلّم المشرف.';

  @override
  String get sellPeriodChanged =>
      'وقت البيع اتغيّر، والفئة اللي مبقتش متاحة اتشالت من الطلب.';

  @override
  String get typesSalePeriodLabel => 'يتباع إمتى';

  @override
  String get typesSaleAlways => 'دايماً';

  @override
  String get typesSaleOffPeak => 'في الأوقات العادية بس';

  @override
  String get typesSalePeak => 'في الذروة بس';

  @override
  String get typesColSale => 'يتباع';

  @override
  String get typesNoPeakType =>
      'مفيش نوع متاح للبيع في وقت الذروة: الكاشير مش هيلاقي حاجة يبيعها.';

  @override
  String get typesNoOffPeakType =>
      'مفيش نوع متاح للبيع في الأوقات العادية: الكاشير مش هيلاقي حاجة يبيعها.';

  @override
  String get typesInvalidWeekdays => 'اختار أيام صحيحة.';

  @override
  String get peakTitle => 'وقت الذروة';

  @override
  String peakNowOn(String reason) {
    return 'الذروة دلوقتي: آه · $reason';
  }

  @override
  String peakNowOff(String reason) {
    return 'الذروة دلوقتي: لأ · $reason';
  }

  @override
  String get peakSourceManualOn => 'اتشغّلت يدوي النهارده';

  @override
  String get peakSourceManualOff => 'اتقفلت يدوي النهارده';

  @override
  String get peakSourceWeekend => 'يوم ذروة';

  @override
  String get peakSourceHours => 'ساعات الذروة';

  @override
  String get peakSourceNone => 'وقت عادي';

  @override
  String get peakModeAuto => 'تلقائي';

  @override
  String get peakModeOn => 'ذروة النهارده';

  @override
  String get peakModeOff => 'عادي النهارده';

  @override
  String get peakModeHelp =>
      'المفتاح بيرجع تلقائي لوحده بكرة. الشبابيك المتصلة بتشوف التغيير خلال ثواني.';

  @override
  String get peakWeekdaysLabel => 'أيام ذروة طول اليوم';

  @override
  String get peakHoursLabel => 'ساعات الذروة في باقي الأيام';

  @override
  String get peakFrom => 'من';

  @override
  String get peakTo => 'لحد';

  @override
  String get peakInvalidHours =>
      'البداية لازم تيجي قبل النهاية في نفس يوم المكان.';

  @override
  String get peakSave => 'حفظ أوقات الذروة';

  @override
  String get peakSaved => 'اتحفظت أوقات الذروة.';

  @override
  String get peakSwitched => 'اتغيّر وقت الذروة.';

  @override
  String get peakNoDays => 'ولا يوم';

  @override
  String get changePeakTimes => 'أوقات الذروة';

  @override
  String changePeakOverride(String day) {
    return 'مفتاح الذروة ليوم $day';
  }

  @override
  String get changePeakMode => 'الوضع';

  @override
  String get peakNoHours => 'مفيش ساعات ذروة في باقي الأيام.';

  @override
  String get peakPickHour => 'الساعة';

  @override
  String get peakPickMinute => 'الدقايق';

  @override
  String get gatesSubtitle => 'كل بوابة متوصلة بباب على وحدة تحكم';

  @override
  String get gatesNew => 'بوابة جديدة';

  @override
  String get gatesLoading => 'بيحمّل البوابات…';

  @override
  String get gatesControllersTitle => 'وحدات التحكم وخدمة البوابات';

  @override
  String gatesServicesLine(int online, int total) {
    return 'خدمة البوابات شغالة على $online من $total بوابة دخول';
  }

  @override
  String get gatesAddController => 'إضافة وحدة';

  @override
  String get gatesNoControllers => 'مفيش وحدات تحكم متسجلة';

  @override
  String controllerDoors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count باب',
      few: '$count أبواب',
      two: 'بابين',
      one: 'باب واحد',
    );
    return '$_temp0';
  }

  @override
  String get controllerOnline => 'متصلة';

  @override
  String controllerOfflineSince(String time) {
    return 'مش متصلة من $time';
  }

  @override
  String get controllerNeverSeen => 'ما اتصلتش';

  @override
  String get controllerNoEntryGate => 'مفيش بوابة دخول';

  @override
  String get controllerNoIp => 'من غير IP';

  @override
  String get gatesColGate => 'البوابة';

  @override
  String get gatesColDirection => 'الاتجاه';

  @override
  String get gatesColWiring => 'التوصيل';

  @override
  String get gatesColToday => 'النهارده';

  @override
  String get gatesColStatus => 'الحالة';

  @override
  String get gatesEmpty => 'مفيش بوابات لسه';

  @override
  String get gateDirectionEntry => 'دخول';

  @override
  String get gateDirectionExit => 'خروج';

  @override
  String gatesWiring(String controller, int door) {
    return '$controller · باب $door';
  }

  @override
  String get gatesNotWired => 'مش متوصلة';

  @override
  String gatesToday(int entries, int rejected) {
    return '$entries دخول · $rejected مرفوض';
  }

  @override
  String get gateStatusExit => 'خروج حر';

  @override
  String get gateExitNote => 'خروج حر بدون مسح';

  @override
  String gatesEditTitle(String name) {
    return 'إعدادات $name';
  }

  @override
  String get gatesName => 'الاسم';

  @override
  String get gatesDirectionLabel => 'الاتجاه';

  @override
  String get gatesController => 'وحدة التحكم';

  @override
  String get gatesDoor => 'رقم الباب';

  @override
  String get gatesOpenSeconds => 'مدة الفتح (ثانية)';

  @override
  String get gatesReader => 'القارئ';

  @override
  String get gatesEnabledLabel => 'البوابة شغالة';

  @override
  String get gatesEnabledNote => 'لو اتقفلت، كل المسح عليها بيترفض';

  @override
  String get gatesTestOpen => 'فتح تجريبي';

  @override
  String get gatesAdd => 'إضافة البوابة';

  @override
  String get gatesSave => 'حفظ';

  @override
  String gatesHomeGateNote(String counters) {
    return 'دي بوابة $counters: لو السيرفر وقع تذاكرهم بتفتح البوابة دي بس، فلازم تفضل بوابة دخول.';
  }

  @override
  String get gatesExitStopsService => 'خدمة البوابة بتقف لو البوابة بقت خروج.';

  @override
  String get gatesTestOpenExit =>
      'مفيش خدمة بوابات على بوابة خروج، فمفيش فتح تجريبي.';

  @override
  String get gatesTestOpenNotWired => 'البوابة مش متوصلة بوحدة تحكم.';

  @override
  String get gatesTestSending => 'بيبعت أمر الفتح…';

  @override
  String gatesTestWaiting(int seconds) {
    return 'اتبعت أمر فتح لمدة $seconds ثانية · مستني خدمة البوابة…';
  }

  @override
  String gatesTestOpened(int seconds) {
    return 'البوابة اتفتحت لمدة $seconds ثانية · اتسجل في سجل الإجراءات باسمك.';
  }

  @override
  String gatesTestFailed(String detail) {
    return 'خدمة البوابة ما قدرتش تفتحها: $detail';
  }

  @override
  String get gatesTestNoAnswer =>
      'خدمة البوابة ما ردتش · راجع إنها شغالة. الطلب اتسجل في سجل الإجراءات.';

  @override
  String get gatesNotAllowed => 'البوابات للأدمن بس.';

  @override
  String get gatesInvalidName => 'اكتب اسم.';

  @override
  String get gatesNameTaken => 'الاسم ده موجود.';

  @override
  String get gatesInvalidOpenSeconds => 'من 1 لـ 10 ثواني.';

  @override
  String get gatesInvalidWiring => 'اختار وحدة التحكم ورقم الباب مع بعض.';

  @override
  String get gatesControllerNotFound => 'وحدة التحكم دي مبقتش موجودة.';

  @override
  String get gatesDoorNotOnController => 'الباب ده مش موجود على وحدة التحكم.';

  @override
  String get gatesDoorTaken => 'الباب ده متوصل ببوابة تانية.';

  @override
  String get gatesHomeGateMustBeEntry => 'دي بوابة شباك، فلازم تفضل دخول.';

  @override
  String get gatesInvalidIp => 'اكتب IP جهاز واحد، زي 10.20.0.51.';

  @override
  String get gatesInvalidPort => 'البورت من 1 لـ 65535.';

  @override
  String get gatesInvalidDoorCount => 'عدد الأبواب من 1 لـ 4.';

  @override
  String get gatesDoorsInUse => 'في بوابة متوصلة بباب أكبر من العدد ده.';

  @override
  String get gatesNotFound => 'اتغيرت من شاشة تانية. القائمة اتحدّثت.';

  @override
  String get gatesTestOpenPending => 'في فتح تجريبي مستني على البوابة دي.';

  @override
  String get gatesUnexpected => 'حصل خطأ غير متوقع في البوابات.';

  @override
  String get controllerNew => 'وحدة تحكم جديدة';

  @override
  String controllerEditTitle(String name) {
    return 'تعديل $name';
  }

  @override
  String get controllerModel => 'الموديل';

  @override
  String get controllerIp => 'IP';

  @override
  String get controllerPort => 'البورت';

  @override
  String get controllerDoorsLabel => 'عدد الأبواب';

  @override
  String get testOpenResultWaiting => 'مستني رد';

  @override
  String get testOpenResultOpened => 'اتفتحت';

  @override
  String get testOpenResultFailed => 'ما اتفتحتش';

  @override
  String get testOpenResultNoAnswer => 'مفيش رد من خدمة البوابة';

  @override
  String changeNewGate(String name) {
    return 'بوابة جديدة: $name';
  }

  @override
  String changeGateName(String name) {
    return 'البوابة $name';
  }

  @override
  String changeNewController(String name) {
    return 'وحدة تحكم جديدة: $name';
  }

  @override
  String changeControllerName(String name) {
    return 'وحدة التحكم $name';
  }

  @override
  String gatesSecondsShort(int seconds) {
    return '$seconds ث';
  }

  @override
  String gatesOpenFor(int seconds) {
    return 'فتح $seconds ث';
  }

  @override
  String get gatesStateOn => 'شغالة';

  @override
  String get usersSubtitle =>
      'مين بيدخل على السيستم وبيعمل إيه. محدش بيتمسح، بيتوقف بس.';

  @override
  String get usersNew => 'مستخدم جديد';

  @override
  String get usersLoading => 'بيحمّل المستخدمين…';

  @override
  String get usersEmpty => 'مفيش مستخدمين.';

  @override
  String get usersColName => 'الاسم';

  @override
  String get usersColRole => 'الدور';

  @override
  String get usersColLastSignIn => 'آخر دخول';

  @override
  String get usersColStatus => 'الحالة';

  @override
  String get usersStatusActive => 'مفعّل';

  @override
  String get usersStatusInactive => 'موقوف';

  @override
  String get usersNeverSignedIn => 'لسه مدخلش';

  @override
  String usersEditTitle(String name) {
    return 'تعديل: $name';
  }

  @override
  String get usersName => 'الاسم';

  @override
  String get usersUsername => 'اسم الدخول';

  @override
  String get usersUsernameHint => 'حروف إنجليزي صغيرة وأرقام و . _ -';

  @override
  String get usersRole => 'الدور';

  @override
  String get usersPermissionsTitle => 'يقدر يعمل';

  @override
  String get usersPermSell => 'البيع والتحصيل وقفل ورديته';

  @override
  String get usersPermActions => 'إعادة طباعة وإعادة تفعيل وإلغاء (بتتسجل)';

  @override
  String get usersPermShifts => 'مطابقة الورديات واعتمادها';

  @override
  String get usersPermLog => 'مراجعة سجل الإجراءات والتقارير';

  @override
  String get usersPermCatalog => 'الأسعار وأنواع التذاكر والبوابات';

  @override
  String get usersPermUsers => 'المستخدمين والإعدادات';

  @override
  String get usersActiveLabel => 'الحساب مفعّل';

  @override
  String get usersActiveNote => 'الإيقاف مش بيمسح المستخدم ولا تاريخه';

  @override
  String get usersPassword => 'كلمة المرور';

  @override
  String get usersPasswordConfirm => 'تأكيد كلمة المرور';

  @override
  String usersPasswordHint(int min) {
    return '$min حروف على الأقل';
  }

  @override
  String get usersPasswordMismatch => 'كلمتين المرور مش زي بعض.';

  @override
  String get usersShowPassword => 'إظهار كلمة المرور';

  @override
  String get usersHidePassword => 'إخفاء كلمة المرور';

  @override
  String get usersResetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String usersResetTitle(String name) {
    return 'كلمة مرور جديدة لـ $name';
  }

  @override
  String get usersResetNote =>
      'قول له على الكلمة الجديدة. هيخرج من أي جهاز داخل عليه ويدخل بيها من جديد.';

  @override
  String get usersResetConfirm => 'تعيين';

  @override
  String get usersResetDone => 'اتغيرت كلمة المرور. هيدخل بيها من جديد.';

  @override
  String get usersSave => 'حفظ';

  @override
  String get usersAdd => 'إضافة المستخدم';

  @override
  String get usersAdded => 'اتضاف. يدخل باسم الدخول وكلمة المرور.';

  @override
  String get usersSelfNote => 'ده حسابك: دورك وتفعيله بيغيرهم مدير تاني.';

  @override
  String get usersOpenShiftNote =>
      'عنده وردية مفتوحة. لازم تتقفل قبل إيقاف الحساب.';

  @override
  String get usersRoleSessionsNote =>
      'تغيير الدور أو الإيقاف بيخرّجه من الأجهزة، ويدخل تاني.';

  @override
  String get usersNotAllowed => 'المستخدمين للأدمن بس.';

  @override
  String get usersNameRequired => 'اكتب الاسم.';

  @override
  String get usersInvalidUsername =>
      'اسم الدخول من 3 لـ 32: حروف إنجليزي صغيرة وأرقام و . _ -';

  @override
  String get usersUsernameTaken => 'اسم الدخول ده متاخد.';

  @override
  String usersPasswordTooShort(int min) {
    return 'كلمة المرور $min حروف على الأقل.';
  }

  @override
  String get usersPasswordTooLong => 'كلمة المرور طويلة قوي.';

  @override
  String get usersCannotChangeOwn =>
      'مينفعش تغيّر دورك أو توقف حسابك. مدير تاني يعملها.';

  @override
  String get usersHasOpenShift => 'عنده وردية مفتوحة. اقفلها الأول.';

  @override
  String get usersNotFound => 'اتغير من شاشة تانية. القائمة اتحدّثت.';

  @override
  String get usersUnexpected => 'حصل خطأ غير متوقع في المستخدمين.';

  @override
  String changeNewUser(String name) {
    return 'مستخدم جديد: $name';
  }

  @override
  String changeUserName(String name) {
    return 'المستخدم $name';
  }

  @override
  String get changePasswordReset => 'كلمة المرور اتعيّنت من جديد';

  @override
  String get settingsLoading => 'بيحمّل الإعدادات…';

  @override
  String get settingsLogNote => 'كل تغيير بيتسجل باسمك في سجل الإجراءات';

  @override
  String get settingsNotAllowed => 'الإعدادات للأدمن بس.';

  @override
  String get settingsUnexpected => 'حصل خطأ غير متوقع في الإعدادات.';

  @override
  String get settingsInvalidValue => 'القيمة دي مش مقبولة.';

  @override
  String get settingsRequired => 'اكتب قيمة.';

  @override
  String settingsOutOfRange(int min, int max) {
    return 'رقم من $min لـ $max.';
  }

  @override
  String get settingsInvalidList =>
      'اكتب مبالغ مفصولة بفاصلة، مثلاً 5, 10, 20.';

  @override
  String settingsTooManyAmounts(int count) {
    return '$count مبلغ بالكتير.';
  }

  @override
  String get settingsAmountTooBig => 'كل مبلغ لحد 100,000 ج.م.';

  @override
  String get settingsDuplicateAmount => 'فيه فئة مكررة.';

  @override
  String get settingsNeedOneDenomination => 'اكتب فئة واحدة على الأقل.';

  @override
  String get settingsVenueSection => 'المكان';

  @override
  String get settingsVenueName => 'اسم المكان (بيتطبع على التذكرة)';

  @override
  String get settingsClosingTime => 'ميعاد قفل المكان';

  @override
  String get settingsClosingNote =>
      'تذاكر يوم البيع بتنتهي في الميعاد ده. التذاكر اللي اتباعت بتفضل بميعادها.';

  @override
  String peakHoursPastMidnight(String closing) {
    return 'ممكن الساعات تعدّي نص الليل، لحد ميعاد قفل المكان الساعة $closing.';
  }

  @override
  String get peakHoursAfterClosing =>
      'ساعات الذروة لازم تخلص لحد ميعاد قفل المكان: بعده مفيش بيع لتذاكر اليوم.';

  @override
  String peakModeHelpDay(String day, String start) {
    return 'المفتاح ليوم $day، وبيرجع تلقائي لما اليوم اللي بعده يبدأ الساعة $start. بعد ميعاد القفل بيتطبّق على اليوم اللي جاي. الشبابيك المتصلة بتشوف التغيير خلال ثواني.';
  }

  @override
  String get settingsClosingCutsPeak =>
      'ساعات الذروة هتبقى بعد ميعاد القفل ده. غيّرها الأول من صفحة أنواع التذاكر.';

  @override
  String get settingsStartCrossesPeak =>
      'ساعات الذروة هتعدّي بداية اليوم دي. غيّرها الأول من صفحة أنواع التذاكر.';

  @override
  String get settingsDayStart => 'بداية يوم المكان';

  @override
  String get settingsDayStartNote =>
      '\"النهارده\" في البيع والتقارير بيبدأ الساعة دي. لو المكان بيقفل بعد نص الليل خلّيها بعد ميعاد القفل.';

  @override
  String settingsClosingNextDay(String time) {
    return 'بيقفل الساعة $time بعد نص الليل: تذاكر يوم البيع بتنتهي $time الصبح اللي بعده.';
  }

  @override
  String get settingsClosedNowTitle => 'البيع هيقف دلوقتي';

  @override
  String settingsClosedNowBody(String closing, String start) {
    return 'بالمواعيد دي يوم النهارده قفل الساعة $closing. الشبابيك مش هتبيع تذاكر يوم البيع لحد ما اليوم الجديد يبدأ الساعة $start.';
  }

  @override
  String get settingsClosedNowSave => 'احفظ برضه';

  @override
  String get settingsDefaultLanguage => 'لغة الواجهة الافتراضية';

  @override
  String get settingsLanguageAr => 'عربي';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsTimezone => 'المنطقة الزمنية';

  @override
  String get settingsTimezoneNote =>
      'ثابتة: تغييرها بيحرّك \"النهارده\" في كل التقارير والصلاحيات.';

  @override
  String get settingsTicketsSection => 'التذاكر';

  @override
  String get settingsGateCodeLength => 'طول كود البوابة (أرقام)';

  @override
  String get settingsUnpaidTimeout => 'إلغاء الطلب غير المحصّل بعد (دقيقة)';

  @override
  String get settingsWiegandNote =>
      'قارئ Wiegand 26 بيقرا لحد 16,777,215، يعني 7 أرقام كحد أقصى. لو القارئ اتغير لـ Wiegand 34 تقدر تزوّد الطول. الطول الجديد للتذاكر الجديدة بس.';

  @override
  String get settingsValidityNote =>
      'صلاحية التذكرة (يوم البيع أو عدد ساعات) بتتحدد لكل نوع.';

  @override
  String get settingsActionsSection => 'إجراءات الكاشير والمراجعة';

  @override
  String get settingsReactivationWindow =>
      'مهلة إعادة التفعيل بعد المسح (دقيقة)';

  @override
  String get settingsReactivationMax => 'أقصى إعادة تفعيل للتذكرة';

  @override
  String get settingsFlagActions => 'مراجعة لو الإجراءات في الوردية أكتر من';

  @override
  String get settingsFlagPrints => 'مراجعة لو التذكرة اتطبعت أكتر من';

  @override
  String get settingsRefundBeforeScan => 'الإلغاء قبل المسح بس';

  @override
  String get settingsRefundBeforeScanHelp => 'التذكرة اللي دخلت مينفعش تتلغي';

  @override
  String get settingsRefundSameShift => 'الإلغاء في نفس الوردية بس';

  @override
  String get settingsRefundSameShiftHelp =>
      'التذكرة بتتلغي في الوردية اللي اتباعت فيها بس';

  @override
  String get settingsFlagOther => 'مراجعة أي إجراء سببه \"سبب آخر\"';

  @override
  String get settingsFlagOtherHelp => 'بيظهر في سجل الإجراءات كـ محتاج مراجعة';

  @override
  String get settingsTipsSection => 'الإكراميات والمبالغ السريعة';

  @override
  String get settingsTipsEnabled => 'تسجيل الإكراميات مع التحصيل';

  @override
  String get settingsTipsEnabledHelp =>
      'مع الكاش بس، وبتدخل في المتوقع عند مطابقة الوردية';

  @override
  String get settingsTipQuick => 'أزرار الإكرامية السريعة (ج.م)';

  @override
  String get settingsFloatQuick => 'أزرار عهدة البداية السريعة (ج.م)';

  @override
  String get settingsTipQuickNote =>
      'لحد 6: بتظهر في صفين في شاشة الدفع وشاشة قفل الوردية.';

  @override
  String get settingsFloatQuickNote =>
      'لحد 4: بتظهر في سطر واحد في شاشة فتح الوردية.';

  @override
  String get settingsReceivedQuick => 'أزرار المبلغ المستلم السريعة (ج.م)';

  @override
  String get settingsReceivedQuickNote =>
      'لحد 8. شاشة الدفع بتعرض أول 3 أكبر من إجمالي الطلب.';

  @override
  String get settingsDenominations => 'فئات العدّ عند قفل الوردية (ج.م)';

  @override
  String get settingsDenominationsNote =>
      'لحد 12، بنفس الترتيب ده في شاشة القفل.';

  @override
  String get settingsNoAmounts => 'ولا مبلغ';

  @override
  String get settingsOn => 'شغال';

  @override
  String get settingsOff => 'مقفول';

  @override
  String get settingsPeakSection => 'أوقات الذروة';

  @override
  String settingsPeakDays(String days) {
    return '$days: ذروة طول اليوم';
  }

  @override
  String get settingsPeakNoDays => 'مفيش أيام ذروة طول اليوم.';

  @override
  String settingsPeakHours(String from, String to) {
    return 'باقي الأيام: من $from لحد $to';
  }

  @override
  String get settingsPeakNote =>
      'بتتعدل من صفحة أنواع التذاكر، وزرار ذروة النهارده في لوحة المتابعة.';

  @override
  String get settingsOfflineSection => 'الأوفلاين والشبكة';

  @override
  String get settingsPoolSize => 'أكواد الأوفلاين لكل شباك';

  @override
  String get settingsHealthCheck => 'الشباك يبقى أوفلاين بعد (ثانية)';

  @override
  String get settingsOfflineNote =>
      '0 أكواد بيقفل البيع أوفلاين. الأكواد المحجوزة مش بتتلغي لو قللت العدد.';

  @override
  String get settingsGateOffline => 'البوابة تبان واقفة بعد (ثانية)';

  @override
  String get settingsTestOpenTimeout => 'مهلة الفتح التجريبي (ثانية)';

  @override
  String get settingsGateTimingNote =>
      'خدمة البوابة بتبعت نبضة كل 30 ثانية وبتسأل عن الفتح التجريبي كل 2 ثانية (الافتراضي). خلي الوقف أكبر من النبضة (90 = 3 نبضات فايتة)، والمهلة أكبر من 2.';

  @override
  String get settingsCountersSection => 'الشبابيك والطابعات';

  @override
  String get settingsCountersEmpty => 'مفيش شبابيك لسه. أضف أول شباك.';

  @override
  String get settingsCountersNote =>
      'الطباعة التجريبية من شاشة فتح الوردية على كل شباك.';

  @override
  String get settingsBackupSection => 'النسخ الاحتياطي';

  @override
  String get settingsBackupNotYet =>
      'النسخ الاحتياطي لسه متجهزش. بييجي مع تركيب السيرفر في المكان.';

  @override
  String get settingsUndo => 'تراجع';

  @override
  String get settingsSave => 'حفظ الإعدادات';

  @override
  String get settingsUnsaved => 'فيه تغييرات لسه متحفظتش.';

  @override
  String settingsLastChange(String name, String time) {
    return 'آخر تغيير: $name · $time';
  }

  @override
  String get settingsNoChangeYet => 'الإعدادات زي ما اتركّبت.';

  @override
  String get counterNew => 'شباك جديد';

  @override
  String get counterAdd => 'إضافة الشباك';

  @override
  String get counterPrinterIp => 'IP الطابعة';

  @override
  String get counterPrinterPort => 'بورت الطابعة';

  @override
  String get counterPaperWidth => 'عرض الورق';

  @override
  String counterPaperMm(int mm) {
    return '$mm مم';
  }

  @override
  String get counterHomeGate => 'بوابة الدخول (وقت انقطاع الشبكة)';

  @override
  String counterHomeGateIs(String gate) {
    return 'بوابة $gate';
  }

  @override
  String get counterHomeGateNote =>
      'وقت انقطاع السيرفر أو السويتش، تذاكر الشباك بتفتح البوابة دي بس، وبتتطبع عليها.';

  @override
  String get counterNoHomeGate => 'من غير بوابة';

  @override
  String counterGateDisabled(String name) {
    return '$name (متوقفة)';
  }

  @override
  String get counterActive => 'الشباك شغال';

  @override
  String get counterActiveNote => 'لو اتوقف، مينفعش تتفتح عليه وردية.';

  @override
  String get counterOpenShiftNote =>
      'عليه وردية مفتوحة دلوقتي، فمينفعش يتوقف لحد ما تتقفل.';

  @override
  String get counterGateChangeNote =>
      'التذاكر الجديدة هتتطبع بالبوابة الجديدة. أكواد الأوفلاين المحجوزة بتفضل على القديمة لحد ما تنتهي.';

  @override
  String get counterNewIdNote =>
      'بعد الإضافة، انسخ رقم الشباك (زرار النسخ في القائمة). ده الرقم اللي بيتحط في إعدادات تشغيل البرنامج على جهاز الشباك (COUNTER_ID)، عشان البرنامج يعرف هو على أنهي شباك.';

  @override
  String get counterAddedCopyId =>
      'اتضاف. انسخ رقمه لإعدادات البرنامج على جهاز الشباك.';

  @override
  String get counterCopyId => 'نسخ رقم الشباك';

  @override
  String get counterIdCopied =>
      'اتنسخ. ده رقم الشباك اللي بيتحط في إعدادات البرنامج على جهازه (COUNTER_ID).';

  @override
  String get counterOn => 'شغال';

  @override
  String get counterOff => 'متوقف';

  @override
  String get counterOpenShift => 'وردية مفتوحة';

  @override
  String get counterNoPrinter => 'مفيش طابعة';

  @override
  String get counterInvalidName => 'اكتب اسم الشباك.';

  @override
  String get counterNameTaken => 'فيه شباك تاني بالاسم ده.';

  @override
  String get counterInvalidPaper => 'عرض الورق 58 أو 80 مم.';

  @override
  String get counterHomeGateRequired => 'الشباك الشغال محتاج بوابة دخول.';

  @override
  String get counterHomeGateNotEntry => 'لازم تكون بوابة دخول.';

  @override
  String get counterGateNotFound =>
      'البوابة دي مبقتش موجودة. افتح الصفحة تاني.';

  @override
  String get counterHasOpenShift => 'عليه وردية مفتوحة. اقفلها الأول.';

  @override
  String get counterNotFound => 'الشباك اتغير من شاشة تانية. القائمة اتحدّثت.';

  @override
  String get changeSettings => 'الإعدادات';

  @override
  String changeNewCounter(String name) {
    return 'شباك جديد: $name';
  }

  @override
  String changeCounterName(String name) {
    return 'الشباك $name';
  }
}
