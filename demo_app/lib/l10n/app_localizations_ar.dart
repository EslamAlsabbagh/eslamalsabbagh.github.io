// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get action => 'الإجراء';

  @override
  String get approve => 'تأكيد';

  @override
  String get approver => 'المراجع';

  @override
  String get cancel => 'إلغاء';

  @override
  String get editManagerTitle => 'تعديل المدير';

  @override
  String get currentManager => 'المدير الحالي';

  @override
  String get newManager => 'المدير الجديد (N+1)';

  @override
  String get pleaseSelectManager => 'يرجى اختيار مدير';

  @override
  String get circularReportingLine => 'سيؤدي ذلك إلى إنشاء تسلسل إداري دائري';

  @override
  String get failedToUpdateManager => 'فشل تحديث المدير';

  @override
  String get noPermissionToChangeManager => 'ليس لديك صلاحية لتغيير المديرين';

  @override
  String get managerUpdatedSuccessfully => 'تم تحديث المدير بنجاح';

  @override
  String get employeeDetailsUpdatedSuccessfully =>
      'تم تحديث بيانات الموظف بنجاح';

  @override
  String get failedToUpdateEmployeeDetails => 'فشل تحديث بيانات الموظف';

  @override
  String get noPermissionToEditEmployeeDetails =>
      'ليس لديك صلاحية لتعديل بيانات الموظف';

  @override
  String get code => 'الكود';

  @override
  String get close => 'إغلاق';

  @override
  String get confirmPassword => 'أعد كتابة كلمة السر الجديدة';

  @override
  String get dateFrom => 'من تاريخ';

  @override
  String get dateTo => 'إلى تاريخ';

  @override
  String get day => 'يوم';

  @override
  String get days => 'أيام';

  @override
  String get decline => 'رفض';

  @override
  String get putOnHold => 'تعليق مؤقت';

  @override
  String get declineReason => 'سبب الرفض';

  @override
  String get department => 'القسم';

  @override
  String get hours => 'عدد الساعات';

  @override
  String get hoursLabel => 'ساعات';

  @override
  String get hourLabel => 'ساعة';

  @override
  String get numberOfHours => 'عدد الساعات';

  @override
  String get am => 'صباحاً';

  @override
  String get pm => 'مساءً';

  @override
  String get morning => 'صباحاً';

  @override
  String get evening => 'مساءً';

  @override
  String get id => 'الكود';

  @override
  String get leaveBalance => 'رصيد الإجازات';

  @override
  String get availableNow => 'المتاح حتى تاريخه';

  @override
  String get annualAllowanceRemaining => 'المتبقي من رصيدك السنوي';

  @override
  String get carryForward => 'رصيد مرحّل';

  @override
  String get expiresApr1 => 'ينتهي في 31 مارس';

  @override
  String get catchingUp => 'في طور التعويض';

  @override
  String maxPerMonth(Object days) {
    return 'بحد أقصى $days في الشهر';
  }

  @override
  String get negativeBalanceHint =>
      'رصيدك حاليًا بالسالب — سيتحقق النظام مما إذا كان يغطي التواريخ المختارة عند إرسال طلب جديد';

  @override
  String get useCompensationFirst => 'يجب استخدام رصيد التعويض أولاً';

  @override
  String get annualCapReached => 'تم الوصول للحد الأقصى للرصيد السنوي';

  @override
  String get leaveType => 'نوع الإجازة';

  @override
  String get location => 'الموقع';

  @override
  String get enterLocation => 'أدخل الموقع';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get lRSubmittedSuccessfully => 'تم إرسال طلب الإجازة بنجاح';

  @override
  String get errUserNotFound => 'تعذّر العثور على سجل الموظف الخاص بك.';

  @override
  String get errLeaveOutsideYear =>
      'يجب أن تقع تواريخ الإجازة ضمن السنة الحالية.';

  @override
  String get errAnnualCapExceeded =>
      'لقد استنفدت رصيد إجازتك السنوية لهذا العام.';

  @override
  String get errInsufficientProjectedBalance =>
      'رصيدك لا يغطي هذه التواريخ، حتى مع الأرصدة الشهرية القادمة.';

  @override
  String get errDatesRequired => 'يرجى اختيار تاريخ البداية والنهاية.';

  @override
  String get errLeaveRequestFailed =>
      'تعذّر إرسال طلب الإجازة. يرجى المحاولة مرة أخرى.';

  @override
  String get oRSubmittedSuccessfully => 'تم إرسال طلب الأوفرتايم بنجاح';

  @override
  String get myRequests => 'طلباتي';

  @override
  String get name => 'الإسم';

  @override
  String get newPassword => 'كلمة السر الجديدة';

  @override
  String get noLeaveRequestsFound => 'لا يوجد طلبات إجازة';

  @override
  String get noOvertimeRequestsFound => 'لا يوجد طلبات أوفرتايم';

  @override
  String get noSickAvail => 'لا يوجد مرفق طبي';

  @override
  String get numberOfDays => 'عدد الأيام';

  @override
  String get oldPassword => 'كلمة السر الحالية';

  @override
  String get overtime => 'أوفرتايم';

  @override
  String get overTimeBalance => 'رصيد الأوفرتايم';

  @override
  String get password => 'كلمة السر';

  @override
  String get passwordsDoNotMatch => 'كلمتا السر غير منطبقتين';

  @override
  String get passwordUpdatedSuccessfully => 'تم تغيير كلمة السر بنجاح';

  @override
  String get plsNewPassword => 'من فضلك أدخل كلمة السر الجديدة';

  @override
  String get plsOldPassword => 'من فضلك أدخل كلمة السر الحالية';

  @override
  String get resetPassword => 'إعادة تعيين كلمة السر';

  @override
  String get resetPasswordConfirmTitle => 'إعادة تعيين كلمة السر';

  @override
  String get resetPasswordConfirmMessage =>
      'هل أنت متأكد من إعادة تعيين كلمة سر هذا الموظف إلى \"123456\"؟';

  @override
  String get resetPasswordSuccess =>
      'تم إعادة تعيين كلمة السر بنجاح إلى \"123456\"';

  @override
  String get resetPasswordFailed => 'فشل في إعادة تعيين كلمة السر';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get home => 'الرئيسية';

  @override
  String get quickAccess => 'الوصول السريع';

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get reason => 'السبب';

  @override
  String get requestID => 'كود الطلب';

  @override
  String get requestLeave => 'طلب إجازة';

  @override
  String get requestOvertime => 'طلب أوفرتايم';

  @override
  String get sickNote => 'مرفق';

  @override
  String get sickNotes => 'المرفقات';

  @override
  String get status => 'الحالة';

  @override
  String get submit => 'تأكيد';

  @override
  String get submitting => 'جاري الإرسال';

  @override
  String get teamRequests => 'طلبات الفريق';

  @override
  String get forgotPasswordHint =>
      'هل نسيت كلمة السر؟ تواصل مع الموارد البشرية لإعادة تعيين كلمة السر';

  @override
  String get test => 'تجربة';

  @override
  String get timeFrom => 'وقت البدء';

  @override
  String get timeTo => 'وقت الإنتهاء';

  @override
  String get title => 'المنصب';

  @override
  String get updatePassword => 'تغيير كلمة السر';

  @override
  String get upSicknote => 'تحميل مرفق طبي';

  @override
  String get youWillOff => 'سوف تكون في إجازة لمدة : ';

  @override
  String get newRequest => 'طلب جديد';

  @override
  String get date => 'التاريخ';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get approved => 'موافق عليه';

  @override
  String get declined => 'مرفوض';

  @override
  String get onHold => 'معلق';

  @override
  String get underInvestigation => 'قيد التحقيق';

  @override
  String get viewRequests => 'عرض الطلبات';

  @override
  String get actionable => 'بحاجة لإجراء';

  @override
  String get processed => 'سابقة';

  @override
  String get processedDisciplinary => 'الإجراءات الإدارية المُعالجة';

  @override
  String get processedInvestigations => 'التحقيقات المُعالجة';

  @override
  String get annual => 'سنوية';

  @override
  String get sick => 'مرضية';

  @override
  String get unpaid => 'غير مدفوعة';

  @override
  String get emergency => 'طارئة';

  @override
  String get compensation => 'تعويضية';

  @override
  String get compensationNotEnoughBalance => 'تعويضية (رصيد غير كافي)';

  @override
  String get annualNotEnoughBalance => 'سنوية (رصيد غير كافي)';

  @override
  String get annualHasOvertime => 'سنوية (لديك رصيد أوفرتايم)';

  @override
  String get numOfHours => 'عدد الساعات';

  @override
  String get emergencyMaxOneDay => 'لا يمكن أن تتجاوز إجازة الطوارئ يوم واحد.';

  @override
  String get emergencyNotEnoughBalance =>
      'ليس لديك رصيد كافٍ من إجازة الطوارئ.';

  @override
  String get emergencyRequiresAnnual =>
      'يجب أن يكون لديك رصيد إجازة سنوية لتقديم طلب إجازة طوارئ.';

  @override
  String get requestMissingPunching => 'طلب إثبات بصمة';

  @override
  String get requestMissingPunchingSubmittedSuccessfully =>
      'تم إرسال طلب إثبات البصمة بنجاح';

  @override
  String get time => 'الوقت';

  @override
  String get missingPunching => 'إثبات البصمة';

  @override
  String get noMissingPunchingRequestsFound => 'لا يوجد طلبات إثبات بصمة';

  @override
  String get missingPunchingRequests => 'طلبات إثبات البصمة';

  @override
  String get missingPunchingRequestDetails => 'تفاصيل طلب إثبات البصمة';

  @override
  String get requestBusinesstrip => 'طلب مأموية عمل';

  @override
  String get businessTrip => 'مأمورية عمل';

  @override
  String get noBusinessTripRequestsFound => 'لا يوجد طلبات مأمورية عمل';

  @override
  String get other => 'أخرى';

  @override
  String get businessTripSubmittedSuccessfully =>
      'تم إرسال طلب مأمورية العمل بنجاح';

  @override
  String get riverside => 'ريفرسايد';

  @override
  String get riversidePark => 'ريفرسايد بارك';

  @override
  String get northSquare => 'نورث سكوير';

  @override
  String get transportationFeesEligible => 'هذا الموقع يستحق بدل انتقالات.';

  @override
  String get requestTransportationFees => 'طلب بدل انتقالات';

  @override
  String get transportationFeeAmount => 'قيمة بدل الانتقالات';

  @override
  String get transportationFeeAmountRequired => 'من فضلك أدخل قيمة صحيحة.';

  @override
  String get editTransportationFeeAmount => 'تعديل قيمة بدل الانتقالات';

  @override
  String get egp => 'جنيه';

  @override
  String get sameDayMissingPunchWarning => 'يوجد طلب إثبات بصمة في نفس اليوم.';

  @override
  String get sameDayBusinessTripWarning => 'يوجد طلب مأمورية في نفس اليوم.';

  @override
  String get holidays => 'إجازات رسمية';

  @override
  String get compensatedHours => 'الساعات تعويضية';

  @override
  String get reasonDetails => 'وصف السبب';

  @override
  String get missingPunchBalance => 'رصيد إثبات البصمة';

  @override
  String get employeeBalances => 'أرصدة الموظف';

  @override
  String get annualLeave => 'إجازة سنوية';

  @override
  String get dayAbbr => 'ي';

  @override
  String get hourAbbr => 'س';

  @override
  String get filterByMonth => 'تصفية حسب الشهر';

  @override
  String get chooseMonth => 'اختر الشهر';

  @override
  String get employees => 'الموظفين';

  @override
  String get requestsReport => 'تقرير الطلبات';

  @override
  String get employeeRequestsReport => 'تقرير طلبات الموظف';

  @override
  String get overallSummary => 'الملخص العام';

  @override
  String get totalRequests => 'إجمالي الطلبات';

  @override
  String get pendingRequests => 'الطلبات المعلقة';

  @override
  String get myInProcessRequests => 'طلبات قيد المعالجة';

  @override
  String get myRecentlyProcessedRequests => 'طلبات تمت معالجتها مؤخراً';

  @override
  String get total => 'الإجمالي';

  @override
  String get leaveRequests => 'طلبات الإجازة';

  @override
  String get overtimeRequests => 'طلبات الأوفرتايم';

  @override
  String get businessTripRequests => 'طلبات مأمورية العمل';

  @override
  String get missingPunchRequests => 'طلبات إثبات البصمة';

  @override
  String get noRequestsMessage => 'لم يقدم هذا الموظف أي طلبات بعد.';

  @override
  String andMoreRequests(int count) {
    return '$count طلب آخر';
  }

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get unknown => 'غير معروف';

  @override
  String get detailsNotAvailable => 'التفاصيل غير متاحة';

  @override
  String get leaveRequest => 'طلب إجازة';

  @override
  String get overtimeRequest => 'طلب أوفرتايم';

  @override
  String get businessTripRequest => 'طلب مأمورية عمل';

  @override
  String get missingPunchRequest => 'طلب إثبات بصمة';

  @override
  String get request => 'طلب';

  @override
  String get searchByName => 'البحث بالاسم أو الكود';

  @override
  String get searchByNameOrCode => 'ابحث بالاسم أو الرمز...';

  @override
  String get addEmployee => 'إضافة موظف';

  @override
  String get saveChanges => 'حفظ';

  @override
  String get employeesList => 'قائمة الموظفين';

  @override
  String get editEmployee => 'تعديل بيانات الموظف';

  @override
  String get edit => 'تعديل';

  @override
  String get editPeriod => 'تعديل فترة السداد';

  @override
  String get updatedPeriod => 'فترة السداد الجديدة';

  @override
  String get originalPeriod => 'فترة السداد القديمة';

  @override
  String get unscheduledPayment => 'دفع غير مجدول';

  @override
  String get noEmployeesFoundMatching => 'لا يوجد موظفين يطابقون';

  @override
  String get noEmployeesYet => 'لا يوجد موظفين حتى الآن';

  @override
  String get saveEmployee => 'حفظ الموظف';

  @override
  String get employeeAddedSuccessfully => 'تم إضافة الموظف بنجاح';

  @override
  String get employeeUpdatedSuccessfully => 'تم تحديث بيانات الموظف بنجاح';

  @override
  String get suspendEmployee => 'إيقاف الموظف';

  @override
  String get unsuspendEmployee => 'إلغاء إيقاف الموظف';

  @override
  String get workingDays => 'أيام العمل';

  @override
  String get leavesEligibility => 'رصيد الإجازات';

  @override
  String get shiftHours => 'ساعات العمل';

  @override
  String get inType => 'الدخول';

  @override
  String get outType => 'الخروج';

  @override
  String get filterRequests => 'تصفية الطلبات';

  @override
  String get filterByRequestType => 'تصفية حسب نوع الطلب';

  @override
  String get allTypes => 'جميع الأنواع';

  @override
  String get leaveRequestsFilter => 'طلبات الإجازة';

  @override
  String get overtimeRequestsFilter => 'طلبات الأوفرتايم';

  @override
  String get businessTripRequestsFilter => 'طلبات مأمورية العمل';

  @override
  String get missingPunchRequestsFilter => 'طلبات إثبات البصمة';

  @override
  String get clearFilters => 'مسح التصفية';

  @override
  String get exportToCSV => 'تصدير إلى CSV';

  @override
  String get exportToXlsx => 'تصدير إلى Xlsx';

  @override
  String get exportByRequestType => 'حسب نوع الطلب';

  @override
  String get exportByEmployee => 'حسب الموظف';

  @override
  String downloadingFiles(int count) {
    return 'جاري تنزيل $count ملف...';
  }

  @override
  String get csvExport => 'تصدير CSV';

  @override
  String get csvContentGenerated => 'تم إنشاء محتوى CSV بنجاح!';

  @override
  String get csvMobileInstructions =>
      'في المنصات المحمولة، يمكنك نسخ هذا المحتوى وحفظه كملف CSV.';

  @override
  String showingRequests(int filteredCount, int totalCount) {
    return 'عرض $filteredCount من $totalCount طلب';
  }

  @override
  String get select => 'تحديد';

  @override
  String get selectMonth => 'اختر الشهر';

  @override
  String get type => 'النوع';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get arabicName => 'الاسم بالعربية';

  @override
  String get nationalId => 'الرقم القومي';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get address => 'العنوان';

  @override
  String get contactInfoUpdated => 'تم تحديث بيانات التواصل بنجاح';

  @override
  String get contactInfoUpdateFailed => 'فشل تحديث بيانات التواصل';

  @override
  String get arabicNickname => 'اللقب بالعربية';

  @override
  String get englishNickname => 'اللقب بالإنجليزية';

  @override
  String get email => 'الإيميل';

  @override
  String get jobTitleInArabic => 'المسمى الوظيفي بالعربية';

  @override
  String get jobTitleInEnglish => 'المسمى الوظيفي بالإنجليزية';

  @override
  String get employeeCode => 'كود الموظف';

  @override
  String get loginCode => 'كود الدخول';

  @override
  String get directManager => 'المدير المباشر';

  @override
  String get managersManager => 'مدير المدير';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get loadingEmployeeRequests => 'جاري تحميل الطلبات...';

  @override
  String get addingEmployees => 'جاري الإضافة...';

  @override
  String get employeeId => 'كود الموظف';

  @override
  String get pleaseEnterEmployeeName => 'يرجى إدخال اسم الموظف';

  @override
  String get pleaseEnterArabicName => 'يرجى إدخال الاسم بالعربية';

  @override
  String get pleaseEnterJobTitle => 'يرجى إدخال المسمى الوظيفي';

  @override
  String get pleaseEnterEmployeeCode => 'يرجى إدخال كود الموظف';

  @override
  String get pleaseEnterLoginCode => 'يرجى إدخال كود الدخول';

  @override
  String get pleaseEnterHireDate => 'يرجى إدخال تاريخ التعيين';

  @override
  String get pleaseEnterN1Manager => 'يرجى إدخال كود المدير المباشر';

  @override
  String get pleaseEnterN2Manager => 'يرجى إدخال كود مدير المدير';

  @override
  String get pleaseEnterValidEmail => 'يرجى إدخال عنوان بريد إلكتروني صحيح';

  @override
  String get operationFailed => 'فشلت العملية';

  @override
  String get noEmployeeFound => 'لم يتم العثور على موظف بهذا كود';

  @override
  String get unsavedChanges => 'تغييرات غير محفوظة';

  @override
  String get unsavedChangesMessage =>
      'لديك تغييرات غير محفوظة. هل أنت متأكد من أنك تريد المغادرة؟';

  @override
  String get stay => 'البقاء';

  @override
  String get leave => 'إجازة';

  @override
  String get departmentInArabic => 'القسم بالعربية';

  @override
  String get departmentInEnglish => 'القسم بالإنجليزية';

  @override
  String get pleaseSelectDepartment => 'يرجى اختيار قسم';

  @override
  String get pleaseSelectLocation => 'يرجى اختيار موقع';

  @override
  String get pleaseSelectCostCenter => 'يرجى اختيار مركز التكلفة';

  @override
  String get costCenter => 'مركز التكلفة';

  @override
  String get topManagement => 'الإدارة العليا';

  @override
  String get financialDepartment => 'الإدارة المالية';

  @override
  String get receptionDepartment => 'إدارة الاستقبال';

  @override
  String get administrativeAffairs => 'إدارة الشئون الإدارية';

  @override
  String get eventsDepartment => 'إدارة الفعاليات';

  @override
  String get marketingDepartment => 'إدارة التسويق';

  @override
  String get leasingDepartment => 'إدارة التأجير';

  @override
  String get licenseDepartment => 'إدارة التراخيص';

  @override
  String get maintenanceDepartment => 'إدارة الصيانة';

  @override
  String get projectsDepartment => 'إدارة المشروعات';

  @override
  String get legalDepartment => 'إدارة الشئون القانونية';

  @override
  String get operationsDepartment => 'إدارة العمليات';

  @override
  String get safetyDepartment => 'إدارة السلامة والصحة المهنية';

  @override
  String get prDepartment => 'إدارة العلاقات العامة';

  @override
  String get purchasingDepartment => 'إدارة المشتريات';

  @override
  String get cashierDepartment => 'إدارة الكاشير';

  @override
  String get humanResourcesDepartment => 'إدارة الموارد البشرية';

  @override
  String get itDepartment => 'إدارة تكنولوجيا المعلومات';

  @override
  String get warehousesDepartment => 'إدارة المخازن';

  @override
  String get collectionDepartment => 'قسم التحصيل';

  @override
  String get pleaseEnterValidNumber => 'يرجى إدخال رقم صحيح';

  @override
  String get pleaseEnterValidEmployeeCode => 'يرجى إدخال كود موظف صحيح';

  @override
  String get pleaseEnterValidN1ManagerCode => 'يرجى إدخال كود مدير مباشر صحيح';

  @override
  String get pleaseEnterValidN2ManagerCode => 'يرجى إدخال كود مدير المدير صحيح';

  @override
  String get pleaseSelectShiftHours => 'يرجى تحديد ساعات العمل';

  @override
  String get pleaseSelectWorkingDays => 'يرجى تحديد أيام العمل';

  @override
  String get pleaseSelectLeavesEligibility => 'يرجى تحديد رصيد الإجازات';

  @override
  String get n1DirectManagerCode => 'كود المدير المباشر (N+1)';

  @override
  String get n2ManagersManagerCode => 'كود مدير المدير (N+2)';

  @override
  String get licensingDepartment => 'قسم التراخيص';

  @override
  String get internalSecurity => 'الامن الداخلى';

  @override
  String get filterByDateRange => 'تصفية حسب التاريخ';

  @override
  String get dateFilterEffective => 'تاريخ التنفيذ';

  @override
  String get dateFilterCreated => 'تاريخ الإنشاء';

  @override
  String get filterByRequestStatus => 'تصفية حسب حالة الطلب';

  @override
  String get filterByUser => 'تصفية حسب الموظف';

  @override
  String get allStatuses => 'جميع الحالات';

  @override
  String get pendingStatus => 'قيد الانتظار';

  @override
  String get approvedStatus => 'موافق عليه';

  @override
  String get declinedStatus => 'مرفوض';

  @override
  String get waitingStatus => 'في الانتظار';

  @override
  String get submittedStatus => 'تم الإرسال';

  @override
  String get acceptedStatus => 'مقبول';

  @override
  String get rejectedStatus => 'مرفوض';

  @override
  String get cancelledStatus => 'ملغي';

  @override
  String get completedStatus => 'مكتمل';

  @override
  String get requestType => 'نوع الطلب';

  @override
  String get overtimeType => 'نوع الأوفرتايم';

  @override
  String get missingpunchType => 'نوع إثبات البصمة';

  @override
  String get clear => 'مسح الكل';

  @override
  String get selectDepartments => 'اختر الأقسام';

  @override
  String get departmentsSelected => 'أقسام مختارة';

  @override
  String get addEmployees => 'إضافة الموظفين';

  @override
  String get filteredBy => 'تم تصفيتها حسب';

  @override
  String get employee => 'موظف';

  @override
  String get employeewithAl => 'الموظف';

  @override
  String get employeesWithoutAl => 'موظفين';

  @override
  String get investigation => 'تحقيق';

  @override
  String get investigations => 'تحقيقات';

  @override
  String get investigationDetails => 'تفاصيل التحقيق';

  @override
  String get employeeCount => 'عدد الموظفين';

  @override
  String get numOfDays => 'عدد الأيام';

  @override
  String get advanceOnSalary => 'سلفة';

  @override
  String get advanceOnSalaryRequests => 'طلبات السلفة';

  @override
  String get advanceOnSalaryRequest => 'طلب سلفة';

  @override
  String get advanceOnSalarySubmittedSuccessfully =>
      'تم إرسال طلب السلفة بنجاح';

  @override
  String get advanceOnSalaryRequestTitle => 'طلب سلفة على الراتب';

  @override
  String browseAllManagedEmployees(int count) {
    return 'استعراض جميع الموظفين المدارين ($count)';
  }

  @override
  String get directEmployees => 'الموظفون المباشرون';

  @override
  String get indirectEmployees => 'غير المباشرين L1';

  @override
  String get allSubordinates => 'غير المباشرين L2+';

  @override
  String browseAllIndirectEmployees(int count) {
    return 'استعراض جميع الموظفين غير المباشرين في المستوى الأول ($count)';
  }

  @override
  String browseAllSubordinates(int count) {
    return 'استعراض جميع الموظفين غير المباشرين في المستوى الثاني فأكثر ($count)';
  }

  @override
  String get mandatoryPasswordChange => 'تغيير كلمة المرور الإجباري';

  @override
  String get weakPasswordMessage =>
      'كلمة المرور الحالية ضعيفة ويجب تغييرها لأسباب أمنية. لا يمكنك الوصول إلى النظام حتى تقوم بتحديث كلمة المرور.';

  @override
  String get weakPasswordError =>
      'كلمة المرور لا يمكن أن تكون 123456. يرجى اختيار كلمة مرور أقوى.';

  @override
  String get passwordTooShort => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل.';

  @override
  String get passwordRequirements =>
      'متطلبات كلمة المرور:\n• يجب أن تكون 8 أحرف على الأقل\n• يجب أن تحتوي على حرف كبير واحد على الأقل (A-Z)\n• يجب أن تحتوي على حرف صغير واحد على الأقل (a-z)\n• يجب أن تحتوي على رقم واحد على الأقل (0-9)\n• يجب أن تحتوي على رمز خاص واحد على الأقل (!@#\$%^&*)\n• لا يمكن أن تكون 123456\n• مختلفة عن كلمة المرور الحالية';

  @override
  String get passwordTooShortNew => 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';

  @override
  String get passwordMissingUppercase =>
      'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل';

  @override
  String get passwordMissingLowercase =>
      'يجب أن تحتوي كلمة المرور على حرف صغير واحد على الأقل';

  @override
  String get passwordMissingDigit =>
      'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';

  @override
  String get passwordMissingSpecialChar =>
      'يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل (!@#\$%^&*)';

  @override
  String get passwordComplexityError => 'كلمة المرور لا تلبي متطلبات التعقيد';

  @override
  String get unableToVerifyCurrentDate =>
      'غير قادر على التحقق من التاريخ الحالي';

  @override
  String get checkInternetConnectionAndRetry =>
      'يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى';

  @override
  String get hireDate => 'تاريخ التعيين';

  @override
  String get notAvailable => 'غير متوفر';

  @override
  String get amountInLetters => 'المبلغ بالحروف';

  @override
  String get willBeCalculated => 'سيتم الحساب';

  @override
  String get paymentEndDate => 'تاريخ انتهاء السداد';

  @override
  String get monthlyPayment => 'السداد الشهري';

  @override
  String get newMonthlyPayment => 'السداد الشهري الجديد';

  @override
  String get searchByNameOrCodeHint => 'البحث بالاسم أو الكود';

  @override
  String get amountRequestedEgp => 'المبلغ المطلوب (جنيه مصري) *';

  @override
  String get enterAmountBetween => 'أدخل مبلغ بين 500 و 20,000 جنيه مصري';

  @override
  String get periodInMonths => 'الفترة بالشهور *';

  @override
  String get enterPeriodBetween => 'أدخل فترة بين 1 و 12 شهر';

  @override
  String get paymentStartDate => 'تاريخ بداية السداد';

  @override
  String get mustBeOnFirstDay =>
      'يجب أن يكون في اليوم الأول، شهر أو شهرين من الآن';

  @override
  String get requestsCantBeSubmitted => 'لا يمكن تقديم الطلبات في هذا الوقت';

  @override
  String get submissionWindowMessage =>
      'نافذة التقديم مفتوحة فقط من 15 إلى 25 من كل شهر';

  @override
  String get notEligibleForAdvance => 'غير مؤهل للحصول على سلفة على الراتب';

  @override
  String get tenureLessThanSixMonths => 'نظراً لأن مدة الخدمة أقل من ستة أشهر';

  @override
  String get currentAdvanceOnSalaryRequest =>
      'نظراً لأن الموظف لديه سلفة حالياً';

  @override
  String get newEmployeePeriodRestriction =>
      'للموظفين الذين لديهم فترة خدمة أقل من سنة واحدة، يتم تعيين المدة تلقائياً إلى شهر واحد فقط';

  @override
  String get newEmployeePaymentStartRestriction =>
      'للموظفين الذين لديهم فترة خدمة أقل من سنة واحدة، يتم تعيين تاريخ بداية السداد تلقائياً للشهر التالي';

  @override
  String advanceEligibilityDateRestriction(String eligibilityDate) {
    return 'سيكون هذا الموظف مؤهلاً للحصول على سلفة على الراتب ابتداءً من $eligibilityDate';
  }

  @override
  String get pendingRequestExists => 'يوجد طلب معلق';

  @override
  String get pendingRequestMessage =>
      'هذا الموظف لديه بالفعل طلب سلفة على الراتب معلق. يرجى انتظار معالجة الطلب الحالي قبل تقديم طلب جديد.';

  @override
  String get checkingPendingRequests => 'جاري التحقق من الطلبات المعلقة...';

  @override
  String get cancelled => 'ملغى';

  @override
  String get cancelRequest => 'إلغاء الطلب';

  @override
  String get confirmCancelRequest => 'تأكيد إلغاء الطلب';

  @override
  String get cancelRequestMessage =>
      'هل أنت متأكد من أنك تريد إلغاء هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get requestCancelledSuccessfully => 'تم إلغاء الطلب بنجاح';

  @override
  String get cancelling => 'جاري الإلغاء...';

  @override
  String get errorCancellingRequest => 'خطأ في إلغاء الطلب';

  @override
  String get requestCancellation => 'طلب إلغاء';

  @override
  String get leaveCancellationRequests => 'طلبات إلغاء الإجازة';

  @override
  String get leaveCancellationRequest => 'طلب إلغاء إجازة';

  @override
  String get cancellationRequestMessage =>
      'سيتم إنشاء طلب إلغاء يتطلب موافقة من مديرك والموارد البشرية. يرجى تقديم سبب:';

  @override
  String get cancellationRequestSubmittedSuccessfully =>
      'تم إرسال طلب الإلغاء بنجاح';

  @override
  String get errorSubmittingCancellationRequest => 'خطأ في إرسال طلب الإلغاء';

  @override
  String get remove => 'إزالة';

  @override
  String get confirmRemoveRequest => 'تأكيد إزالة الطلب';

  @override
  String get removeRequestMessage =>
      'هل أنت متأكد من أنك تريد إزالة هذا الطلب من القائمة؟';

  @override
  String get requestRemovedSuccessfully => 'تم إزالة الطلب بنجاح';

  @override
  String get removing => 'جاري الإزالة...';

  @override
  String get errorRemovingRequest => 'خطأ في إزالة الطلب';

  @override
  String get selectPaymentStartDate => 'اختر تاريخ بداية السداد';

  @override
  String get pleaseFillAllRequiredFields => 'يرجى ملء جميع الحقول المطلوبة';

  @override
  String get myAdvanceOnSalaryRequests => 'طلبات السلفة الخاصة بي';

  @override
  String get teamAdvanceOnSalaryRequests => 'طلبات سلفة الفريق';

  @override
  String get searchByNameCodeOrAmount => 'البحث بالاسم أو الكود أو المبلغ';

  @override
  String get allStatus => 'جميع الحالات';

  @override
  String get allMonths => 'جميع الأشهر';

  @override
  String get groupHr => 'الموارد البشرية';

  @override
  String get groupFinance => 'المالية';

  @override
  String get groupLegal => 'الشئون القانونية';

  @override
  String get groupTopManagement => 'الإدارة العليا';

  @override
  String get groupIt => 'IT';

  @override
  String get groupDashboard => 'لوحة المعلومات';

  @override
  String get perPage => 'لكل صفحة';

  @override
  String get sortBy => 'ترتيب حسب:';

  @override
  String get dateCreated => 'تاريخ الإنشاء';

  @override
  String get period => 'الفترة';

  @override
  String get ascending => 'تصاعدي';

  @override
  String get descending => 'تنازلي';

  @override
  String get refresh => 'تحديث';

  @override
  String get refreshing => 'جاري التحديث...';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noRequestsFound => 'لا توجد طلبات';

  @override
  String get noNewUpdates => 'لا توجد تحديثات جديدة';

  @override
  String get tryAdjustingSearchFilters => 'حاول ضبط البحث أو المرشحات';

  @override
  String showingRequestsOfTotal(int showing, int total) {
    return 'عرض $showing من $total طلب';
  }

  @override
  String get requestor => 'مقدم الطلب';

  @override
  String get borrower => 'المقترض';

  @override
  String get amountRequested => 'المبلغ المطلوب';

  @override
  String get createdAt => 'تاريخ الإنشاء';

  @override
  String get currentApprover => 'المراجع الحالي';

  @override
  String get n2Manager => 'مدير المدير';

  @override
  String get hrDepartment => 'الموارد البشرية';

  @override
  String get financeDepartment => 'المالية';

  @override
  String get paymentStartDateLabel => 'تاريخ بداية السداد';

  @override
  String get paymentEndDateLabel => 'تاريخ انتهاء السداد';

  @override
  String get monthlyPaymentLabel => 'السداد الشهري';

  @override
  String get month => 'الشهر';

  @override
  String get months => 'أشهر';

  @override
  String get declining => 'جاري الرفض...';

  @override
  String get approving => 'جاري الموافقة...';

  @override
  String pageOfPages(int current, int total) {
    return 'صفحة $current من $total';
  }

  @override
  String get previousPage => 'الصفحة السابقة';

  @override
  String get nextPage => 'الصفحة التالية';

  @override
  String get requestApprovedSuccessfully => 'تم الموافقة على الطلب بنجاح';

  @override
  String failedToApproveRequest(String error) {
    return 'فشل في الموافقة على الطلب: $error';
  }

  @override
  String get requestDeclinedSuccessfully => 'تم رفض الطلب بنجاح';

  @override
  String get requestPutOnHoldSuccessfully => 'تم تعليق الطلب مؤقتاً بنجاح';

  @override
  String failedToDeclineRequest(String error) {
    return 'فشل في رفض الطلب: $error';
  }

  @override
  String failedToPutOnHoldRequest(String error) {
    return 'فشل في تعليق الطلب مؤقتاً: $error';
  }

  @override
  String errorLoadingRequests(String error) {
    return 'خطأ في تحميل الطلبات: $error';
  }

  @override
  String get approvalConfirmation => 'تأكيد الموافقة';

  @override
  String get requestDetails => 'تفاصيل الطلب';

  @override
  String get requestId => 'رقم الطلب';

  @override
  String get declineRequest => 'رفض الطلب';

  @override
  String get provideDeclinereason => 'يرجى تقديم سبب لرفض هذا الطلب:';

  @override
  String get enterDeclineReason => 'أدخل سبب الرفض...';

  @override
  String get pleaseEnterDeclineReason => 'يرجى إدخال سبب الرفض';

  @override
  String get confirmApproval => 'تأكيد الموافقة';

  @override
  String get confirming => 'جاري التأكيد...';

  @override
  String get unknownError => 'خطأ غير معروف';

  @override
  String get amount => 'المبلغ';

  @override
  String get previewPdf => 'معاينة PDF';

  @override
  String get printPdf => 'طباعة PDF';

  @override
  String get printing => 'جارٍ الطباعة...';

  @override
  String get downloading => 'جارٍ التحميل...';

  @override
  String get generatePdf => 'إنشاء PDF';

  @override
  String get pdfActions => 'إجراءات PDF';

  @override
  String get pdfNotAvailable => 'PDF غير متوفر حتى الآن';

  @override
  String get pdfGeneratedWhenApproved =>
      'سيتم إنشاء PDF عند الموافقة النهائية من قبل المالية';

  @override
  String get downloadPdf => 'تحميل PDF';

  @override
  String pdfDownloadedSuccessfully(String filePath) {
    return 'تم تحميل PDF بنجاح إلى $filePath';
  }

  @override
  String failedToDownloadPdf(String error) {
    return 'فشل في تحميل PDF: $error';
  }

  @override
  String get unsettled => 'غير مسددة';

  @override
  String get settled => 'مسددة';

  @override
  String get settle => 'تسوية';

  @override
  String get settling => 'جاري التسوية...';

  @override
  String get manuallySettled => 'تمت التسوية يدوياً';

  @override
  String get settledBy => 'تم التسوية بواسطة';

  @override
  String get settlementDate => 'تاريخ التسوية';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get confirmSettlement => 'تأكيد التسوية';

  @override
  String get confirmSettlementMessage =>
      'هل أنت متأكد من أنك تريد تسوية طلب السلفة على الراتب هذا؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get settlementWarning =>
      'سيؤدي هذا إلى وضع علامة على الطلب كمسدد يدوياً وتحديث تاريخ أهلية المقترض إلى اليوم.';

  @override
  String get confirmSettle => 'تأكيد التسوية';

  @override
  String get confirmSubmitRequest => 'تأكيد إرسال الطلب';

  @override
  String get areYouSureToSubmitRequest =>
      'هل أنت متأكد من أنك تريد إرسال طلب السلفة على الراتب هذا؟';

  @override
  String get areYouSureToSubmitDisciplinaryRequest =>
      'هل أنت متأكد من أنك تريد إرسال طلب الإجراء الإداري هذا؟';

  @override
  String get requestSettledSuccessfully => 'تم تسوية الطلب بنجاح';

  @override
  String failedToSettleRequest(String error) {
    return 'فشل في تسوية الطلب: $error';
  }

  @override
  String get confirmPasswordDoesNotMatch =>
      'كلمة المرور الجديدة وتأكيد كلمة المرور غير متطابقتين';

  @override
  String get oldPasswordIncorrect => 'كلمة المرور القديمة غير صحيحة';

  @override
  String get updatePasswordFailed => 'فشل في تحديث كلمة المرور';

  @override
  String get loginFailed => 'فشل في تسجيل الدخول';

  @override
  String get invalidCredentials =>
      'رقم الموظف أو كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.';

  @override
  String get emailNotConfirmed =>
      'البريد الإلكتروني غير مؤكد. يرجى فحص بريدك الإلكتروني.';

  @override
  String get tooManyRequests =>
      'محاولات دخول كثيرة جداً. يرجى المحاولة لاحقاً.';

  @override
  String get signupFailed => 'فشل في إنشاء الحساب';

  @override
  String get weakPassword =>
      'كلمة المرور لا يمكن أن تكون 123456. يرجى اختيار كلمة مرور أقوى.';

  @override
  String get samePassword =>
      'كلمة المرور الجديدة يجب أن تكون مختلفة عن كلمة المرور القديمة';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get accountSuspended => 'حسابك موقوف.';

  @override
  String get employeeCodeOnlyNumbers => 'رقم الموظف يجب أن يحتوي على أرقام فقط';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String reasonMinLength(Object min) {
    return 'يجب أن يكون السبب $min حرفاً على الأقل';
  }

  @override
  String get advanceOnSalaryRequestsFilter => 'طلبات السلفة';

  @override
  String get groupManagement => 'إدارة المجموعات';

  @override
  String get addToGroup => 'إضافة إلى مجموعة';

  @override
  String get addGroup => 'إضافة مجموعة';

  @override
  String get groups => 'المجموعات';

  @override
  String userAlreadyInGroup(String group) {
    return 'المستخدم موجود بالفعل في مجموعة $group';
  }

  @override
  String successfullyAddedUserToGroup(String group) {
    return 'تم إضافة المستخدم بنجاح إلى مجموعة $group';
  }

  @override
  String failedToAddUserToGroup(String error) {
    return 'فشل في إضافة المستخدم إلى المجموعة: $error';
  }

  @override
  String get removeFromGroup => 'إزالة من المجموعة';

  @override
  String successfullyRemovedUserFromGroup(String group) {
    return 'تم إزالة المستخدم بنجاح من مجموعة $group';
  }

  @override
  String failedToRemoveUserFromGroup(String error) {
    return 'فشل في إزالة المستخدم من المجموعة: $error';
  }

  @override
  String userNotInGroup(String group) {
    return 'المستخدم ليس في مجموعة $group';
  }

  @override
  String get currentGroups => 'المجموعات الحالية';

  @override
  String get none => 'لا يوجد';

  @override
  String get back => 'رجوع';

  @override
  String get selectEmployee => 'حدد الموظف';

  @override
  String get selectedEmployee => 'الموظف المحدد';

  @override
  String get clearSelection => 'مسح التحديد';

  @override
  String get jobTitle => 'المسمى الوظيفي';

  @override
  String get disciplinaryAction => 'إجراء إداري';

  @override
  String get disciplinaryActionRequest => 'طلب إجراء إداري';

  @override
  String get disciplinaryActionRequests => 'طلبات الإجراءات الإدارية';

  @override
  String get myDisciplinaryActionRequests => 'طلباتي للإجراءات الإدارية';

  @override
  String get teamDisciplinaryActionRequests =>
      'طلبات الإجراءات الإدارية للفريق';

  @override
  String get processedDisciplinaryActionRequests =>
      'طلبات الإجراءات الإدارية المُعالجة';

  @override
  String get disciplinaryActionType => 'نوع الإجراء الإداري';

  @override
  String get actionType => 'نوع الإجراء';

  @override
  String get selectActionType => 'اختر نوع الإجراء';

  @override
  String get verbalRemark => 'ملاحظة شفهية';

  @override
  String get writtenRemark => 'تنبيه خطي';

  @override
  String get writtenWarning => 'إنذار خطي';

  @override
  String get selectEmployees => 'اختر الموظفين';

  @override
  String get selectedEmployees => 'الموظفون المختارون';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get removeEmployee => 'إزالة الموظف';

  @override
  String get browseAllEmployees => 'تصفح جميع الموظفين';

  @override
  String get pleaseSelectAtLeastOneEmployee =>
      'يرجى اختيار موظف واحد على الأقل';

  @override
  String get incidentDescription => 'وصف الحادثة';

  @override
  String get describeIncident => 'يرجى وصف الحادثة بالتفصيل';

  @override
  String get violationDate => 'تاريخ المخالفة';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get writtenWarningOptions => 'خيارات الإنذار الخطي';

  @override
  String get deductDays => 'أيام الخصم';

  @override
  String get quarterDay => 'ربع يوم';

  @override
  String get halfDay => 'نصف يوم';

  @override
  String get selectDeductDays => 'اختر أيام الخصم';

  @override
  String get additionalInformation => 'معلومات إضافية';

  @override
  String get witnessStatements => 'شهادات الشهود';

  @override
  String get recommendedAction => 'الإجراء الموصى به';

  @override
  String get optional => '(اختياري)';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get requestSubmittedSuccessfully => 'تم إرسال الطلب بنجاح';

  @override
  String get searchEmployee => 'البحث عن موظف';

  @override
  String get orSelectFromList => 'أو اختر من القائمة';

  @override
  String get terminationWarning => 'تحذير فصل';

  @override
  String get searchRequests => 'البحث في الطلبات...';

  @override
  String get sortAscending => 'ترتيب تصاعدي';

  @override
  String get sortDescending => 'ترتيب تنازلي';

  @override
  String get enterReason => 'أدخل السبب...';

  @override
  String get pleaseEnterReason => 'يرجى إدخال السبب';

  @override
  String get pleaseEnterApprovalReason => 'يرجى إدخال سبب الموافقة';

  @override
  String get pleaseEnterHoldReason => 'يرجى إدخال سبب التعليق';

  @override
  String get pleaseEnterInvestigationReason => 'يرجى إدخال سبب التحقيق';

  @override
  String get approvalReason => 'سبب الموافقة';

  @override
  String get holdReason => 'سبب التعليق';

  @override
  String get investigationReason => 'سبب التحقيق';

  @override
  String get sendToHrInvestigation => 'إرسال للموارد البشرية للتحقيق';

  @override
  String get sendingToHrInvestigation =>
      'جاري الإرسال للموارد البشرية للتحقيق...';

  @override
  String get sentToHrInvestigationSuccessfully =>
      'تم إرسال الطلب للموارد البشرية للتحقيق بنجاح';

  @override
  String failedToSendToHrInvestigation(String error) {
    return 'فشل في إرسال الطلب للموارد البشرية للتحقيق: $error';
  }

  @override
  String get editWrittenWarning => 'تعديل الإنذار الخطي';

  @override
  String get editDeductDays => 'تعديل أيام الخصم';

  @override
  String get editSuspensionDays => 'تعديل أيام الإيقاف';

  @override
  String get writtenWarningUpdatedSuccessfully =>
      'تم تحديث خيارات الإنذار الخطي بنجاح';

  @override
  String failedToUpdateWrittenWarning(String error) {
    return 'فشل في تحديث الإنذار الخطي: $error';
  }

  @override
  String get errorPrefix => 'خطأ';

  @override
  String employeeTerminationWarningMessage(int warningCount) {
    return 'هذا الموظف لديه $warningCount إنذارات خطية في آخر 6 أشهر.';
  }

  @override
  String get deductDaysHint => '1-5';

  @override
  String get suspensionDaysHint => '1-7';

  @override
  String get suspensionDays => 'أيام الإيقاف';

  @override
  String get pleaseSelectEmployee => 'يرجى اختيار موظف';

  @override
  String get pleaseSelectActionType => 'يرجى اختيار نوع الإجراء الإداري';

  @override
  String get pleaseProvideIncidentDetails => 'يرجى تقديم تفاصيل الحادث';

  @override
  String get incidentDescriptionTooShort =>
      'وصف الحادث يجب أن يكون على الأقل 10 كلمات';

  @override
  String get pleaseSelectViolationDate => 'يرجى اختيار تاريخ المخالفة';

  @override
  String get violationDateFuture =>
      'تاريخ المخالفة لا يمكن أن يكون في المستقبل';

  @override
  String get violationDateTooOld =>
      'تاريخ المخالفة لا يمكن أن يكون أكثر من 30 يوماً مضت';

  @override
  String get deductDaysRange => 'أيام الخصم يجب أن تكون بين 1 و 5';

  @override
  String get suspensionDaysRange => 'أيام الإيقاف يجب أن تكون بين 1 و 7';

  @override
  String get save => 'حفظ';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get enterDaysBetween1And5 => 'أدخل عدد أيام بين 1 و 5';

  @override
  String get enterSuspensionDaysBetween1And7 =>
      'أدخل عدد أيام الإيقاف بين 1 و 7';

  @override
  String get employeeConfirmationRequired => 'مطلوب تأكيد من الموظف';

  @override
  String get financeHasEditedPaymentPeriod =>
      'قامت المالية بتعديل فترة السداد لطلب السلفة الخاص بك. يرجى المراجعة والتأكيد أو إلغاء الطلب.';

  @override
  String get confirmFinanceEdit => 'تأكيد التعديلات';

  @override
  String get cancelFinanceEdit => 'إلغاء الطلب';

  @override
  String get confirmingChanges => 'جاري تأكيد التعديلات...';

  @override
  String get cancellingRequest => 'جاري إلغاء الطلب...';

  @override
  String get changesConfirmedSuccessfully => 'تم تأكيد التعديلات بنجاح';

  @override
  String failedToConfirmChanges(String error) {
    return 'فشل في تأكيد التعديلات: $error';
  }

  @override
  String failedToCancelRequest(String error) {
    return 'فشل في إلغاء الطلب: $error';
  }

  @override
  String get financeAcknowledgmentRequired => 'مطلوب إقرار من المالية';

  @override
  String get employeeHasRespondedToFinanceEdit =>
      'لقد رد الموظف على تعديل المالية. يرجى الإقرار بقراره.';

  @override
  String get acknowledgeEmployeeDecision => 'إقرار القرار';

  @override
  String get acknowledgingDecision => 'جاري إقرار القرار...';

  @override
  String get decisionAcknowledgedSuccessfully => 'تم إقرار القرار بنجاح';

  @override
  String failedToAcknowledgeDecision(String error) {
    return 'فشل في إقرار القرار: $error';
  }

  @override
  String get employeeConfirmed => 'وافق الموظف';

  @override
  String get employeeCancelled => 'ألغى الموظف';

  @override
  String get pendingEmployeeConfirmation => 'في انتظار تأكيد الموظف';

  @override
  String get pendingFinanceAcknowledgment => 'في انتظار إقرار المالية';

  @override
  String get employeeConfirmationRequests => 'طلبات السلفة الخاصة بي';

  @override
  String get orgChart => 'الهيكل التنظيمي';

  @override
  String get businessTripCancellationRequest => 'طلب إلغاء مأمورية العمل';

  @override
  String get businessTripCancellationRequests => 'طلبات إلغاء مأمورية العمل';

  @override
  String get firstLineManager => 'المدير المباشر';

  @override
  String get secondLineManager => 'المدير غير المباشر';

  @override
  String get approvedByN1 => 'تمت الموافقة من قبل المدير المباشر';

  @override
  String get approvedByN2 => 'تمت الموافقة من قبل مدير المدير';

  @override
  String get approvedByHR => 'تمت الموافقة من قبل الموارد البشرية';

  @override
  String get approvedByFinance => 'تمت الموافقة من قبل المالية';

  @override
  String get approvedBy => 'تمت الموافقة من قبل';

  @override
  String get acknowledgedBy => 'تم الاستلام من قبل';

  @override
  String get completedBy => 'تم الإنجاز من قبل';

  @override
  String get declinedBy => 'تم الرفض من قبل';

  @override
  String get declinedByN1 => 'تم الرفض من قبل المدير المباشر';

  @override
  String get declinedByN2 => 'تم الرفض من قبل مدير المدير';

  @override
  String get declinedByHR => 'تم الرفض من قبل الموارد البشرية';

  @override
  String get declinedByFinance => 'تم الرفض من قبل المالية';

  @override
  String get on => 'في';

  @override
  String get autoFillNicknameFromFullName =>
      'ملء اللقب تلقائياً من الاسم الكامل';

  @override
  String get unavailableLeaveRequest => 'غير متاح: طلب إجازة';

  @override
  String get unavailableBusinessTrip => 'غير متاح: مأمورية عمل';

  @override
  String get unavailableMissingPunch => 'غير متاح: طلب إثبات بصمة';

  @override
  String get hoursRequiredDueToMissingPunch =>
      'اختيار الساعات مطلوب لأن هناك طلب إثبات بصمة في هذا اليوم';

  @override
  String get leaveTypeAnnual => 'سنوية';

  @override
  String get leaveTypeEmergency => 'طارئة';

  @override
  String get leaveTypeSick => 'مرضية';

  @override
  String get leaveTypeCompensation => 'تعويضية';

  @override
  String get leaveTypeUnpaid => 'بدون أجر';

  @override
  String get moreActions => 'المزيد من الإجراءات';

  @override
  String get puttingOnHold => 'جاري التعليق...';

  @override
  String get investigating => 'جاري الإرسال للتحقيق...';

  @override
  String get confirm => 'تأكيد';

  @override
  String get acknowledgeWithRemark => 'الإقرار مع ملاحظة';

  @override
  String get confirmAcknowledgment => 'تأكيد الإقرار';

  @override
  String get pleaseProvideYourRemarkOnThisAction =>
      'يرجى تقديم ملاحظتك على هذا الإجراء:';

  @override
  String get areYouSureYouWantToAcknowledgeThisRequest =>
      'هل أنت متأكد من رغبتك في الإقرار بطلب الإجراء الإداري هذا؟';

  @override
  String get yourRemark => 'ملاحظتك';

  @override
  String get enterYourRemark => 'أدخل ملاحظتك هنا...';

  @override
  String get pleaseProvideARemark => 'يرجى تقديم ملاحظة';

  @override
  String get acknowledgmentWillMoveRequestToApprovalWorkflow =>
      'بالإقرار، سيتم نقل هذا الطلب إلى سير عمل الموافقة.';

  @override
  String get acknowledge => 'إقرار';

  @override
  String get employeeAcknowledged => 'أقر الموظف';

  @override
  String get autoEscalated => 'تمت التصعيد تلقائيًا (لا يوجد رد من الموظف)';

  @override
  String get escalationDate => 'تاريخ التصعيد التلقائي';

  @override
  String get acknowledgmentDate => 'تاريخ الإقرار';

  @override
  String get acknowledgmentType => 'نوع الإقرار';

  @override
  String get confirmed => 'مؤكد';

  @override
  String get acknowledgedWithRemark => 'أقر مع ملاحظة';

  @override
  String get employeeRemark => 'ملاحظة الموظف';

  @override
  String get acknowledging => 'جاري الإقرار...';

  @override
  String get requestAcknowledgedSuccessfully => 'تم الإقرار بالطلب بنجاح';

  @override
  String get confirmAcknowledgmentMessage =>
      'هل أنت متأكد من أنك تريد الإقرار بطلب الإجراء الإداري هذا دون تقديم ملاحظة؟';

  @override
  String get requiresYourAcknowledgment => 'إجراء إدراي يتطلب إقرارك';

  @override
  String get escalateToLegal => 'إحالة إلى الشئون القانونية';

  @override
  String get legalInvestigation => 'تحقيق الشئون القانونية';

  @override
  String get legalEscalationReason => 'سبب الإحالة للشئون القانونية';

  @override
  String get provideEscalationReason =>
      'يرجى تقديم سبب الإحالة للشئون القانونية';

  @override
  String get uploadInvestigationPDF => 'رفع تقرير التحقيق PDF';

  @override
  String get acknowledgeLegalRequest => 'إقرار الطلب';

  @override
  String get acknowledgeLegalRequestMessage =>
      'بالإقرار بهذا الطلب، تؤكد أنك استلمته وستبدأ التحقيق القانوني. سيتم إيقاف إشعارات التذكير.';

  @override
  String get legalAcknowledgedSuccessfully => 'تم إقرار الطلب بنجاح';

  @override
  String get investigationPdfRequired => 'تقرير التحقيق PDF مطلوب';

  @override
  String get hrFinalDecision => 'القرار النهائي للموارد البشرية';

  @override
  String get terminateEmployee => 'إنهاء خدمة الموظف';

  @override
  String get enterSuspensionDays => 'أدخل عدد أيام الإيقاف';

  @override
  String get closedAtHR => 'أغلق';

  @override
  String get escalatedToLegalSuccessfully =>
      'تم إحالة الطلب إلى الشئون القانونية بنجاح';

  @override
  String get investigationUploadedSuccessfully => 'تم رفع التحقيق بنجاح';

  @override
  String get hrFinalDecisionSubmittedSuccessfully =>
      'تم تقديم القرار النهائي بنجاح';

  @override
  String get pendingLegalInvestigation => 'في انتظار تحقيق الشئون القانونية';

  @override
  String get legal => 'الشئون القانونية';

  @override
  String get legalApprover => 'محقق الشئون القانونية';

  @override
  String get investigationReport => 'تقرير التحقيق';

  @override
  String get viewInvestigationReport => 'عرض تقرير التحقيق';

  @override
  String get suspendedFor => 'موقوف لمدة';

  @override
  String get terminationRecommended => 'موصى بإنهاء الخدمة';

  @override
  String get suspensionPeriod => 'فترة الإيقاف';

  @override
  String get suspensionStartDate => 'تاريخ بدء الإيقاف';

  @override
  String get suspensionEndDate => 'تاريخ انتهاء الإيقاف';

  @override
  String get escalatingToLegal => 'جاري الإحالة إلى الشئون القانونية...';

  @override
  String get uploading => 'جاري الرفع...';

  @override
  String get approveFinal => 'الموافقة النهائية';

  @override
  String get declineFinal => 'الرفض النهائي';

  @override
  String get pleaseSelectPdfFile => 'يرجى اختيار ملف PDF للرفع';

  @override
  String get investigationPdfUploadedSuccessfully =>
      'تم رفع تقرير التحقيق PDF بنجاح';

  @override
  String get suspensionDaysRequired => 'يرجى إدخال أيام الإيقاف';

  @override
  String get suspensionDaysMustBePositive =>
      'يجب أن تكون أيام الإيقاف أكبر من 0';

  @override
  String get confirmTermination =>
      'هل أنت متأكد من إنهاء خدمة هذا الموظف؟ هذا الإجراء لا رجعة فيه.';

  @override
  String get submittingFinalDecision => 'جاري تقديم القرار النهائي...';

  @override
  String get legalInvestigationComplete => 'اكتمل تحقيق الشئون القانونية';

  @override
  String get makeHRFinalDecision => 'اتخاذ القرار النهائي للموارد البشرية';

  @override
  String get n2SendingForInvestigationReason =>
      '(N+2) قد أرسل الطلب للموارد البشرية للتحقيق للسبب التالي';

  @override
  String get attachDocuments => 'إرفاق المستندات';

  @override
  String get uploadDocuments => 'رفع المستندات';

  @override
  String get removeDocument => 'إزالة';

  @override
  String get supportedFormats => 'الصيغ المدعومة: PDF، JPG، PNG، DOC، DOCX';

  @override
  String get maxFilesReached => 'الحد الأقصى 5 ملفات';

  @override
  String get fileTooLarge => 'حجم الملف يتجاوز الحد المسموح 10 ميجابايت';

  @override
  String documentsAttached(int count) {
    return '$count مستند(ات) مرفقة';
  }

  @override
  String get attachments => 'المرفقات';

  @override
  String get viewAttachment => 'عرض';

  @override
  String get loadingAttachments => 'جاري تحميل المرفقات...';

  @override
  String get noAttachments => 'لا توجد مرفقات';

  @override
  String get openAttachmentFailed => 'فشل في فتح المرفق';

  @override
  String get violationCategory => 'فئة المخالفة';

  @override
  String get selectViolationCategory => 'اختر فئة المخالفة';

  @override
  String get violation => 'المخالفة';

  @override
  String get selectViolation => 'اختر المخالفة';

  @override
  String get violationDescription => 'وصف المخالفة';

  @override
  String get describeViolation => 'صف المخالفة بالتفصيل';

  @override
  String get selectCategoryFirst => 'يرجى اختيار الفئة أولاً';

  @override
  String get categoryAttendance => 'الحضور';

  @override
  String get categoryConduct => 'السلوك';

  @override
  String get categoryPerformance => 'الأداء';

  @override
  String get categorySafety => 'السلامة';

  @override
  String get categoryPolicy => 'السياسات';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get pleaseSelectViolationCategory => 'يرجى اختيار فئة المخالفة';

  @override
  String get pleaseSelectViolation => 'يرجى اختيار المخالفة';

  @override
  String get pleaseDescribeViolation => 'يرجى وصف المخالفة';

  @override
  String get violationDescriptionTooShort =>
      'يجب أن يكون وصف المخالفة 10 أحرف على الأقل';

  @override
  String get settlementReview => 'مراجعة التسوية';

  @override
  String get settlementReviewRequests => 'إشعارات التسوية';

  @override
  String get sendNotification => 'إرسال الإشعار';

  @override
  String get sendAllNotifications => 'إرسال الكل';

  @override
  String get noSettlementReviewRequests => 'لا توجد إشعارات تسوية معلقة';

  @override
  String get settlementNotificationSent => 'تم إرسال إشعار التسوية بنجاح';

  @override
  String get allNotificationsSent => 'تم إرسال جميع الإشعارات بنجاح';

  @override
  String get skipNotification => 'تخطي';

  @override
  String get notificationSkipped => 'تم تخطي الإشعار';

  @override
  String get reviewPdf => 'مراجعة PDF';

  @override
  String get confirmSendAll => 'تأكيد إرسال الكل';

  @override
  String confirmSendAllNotifications(Object count) {
    return 'إرسال $count إشعار تسوية؟';
  }

  @override
  String get send => 'إرسال';

  @override
  String get readyForReview => 'جاهز للمراجعة';

  @override
  String get closed => 'مغلق';

  @override
  String get recordDecision => 'تسجيل القرار';

  @override
  String get hrDecision => 'قرار الموارد البشرية';

  @override
  String get legalReview => 'المراجعة القانونية';

  @override
  String get topManagementDecision => 'قرار الإدارة العليا';

  @override
  String get decisionHistory => 'سجل القرارات';

  @override
  String get linkedActions => 'الإجراءات الإدارية المرتبطة';

  @override
  String get takeAction => 'اتخاذ إجراء إداري';

  @override
  String get noAction => 'لا إجراء';

  @override
  String get suspend => 'إيقاف';

  @override
  String get terminate => 'إنهاء الخدمة';

  @override
  String get confirmDecision => 'تأكيد القرار';

  @override
  String get convertToDisciplinary => 'تحويل إلى إجراء إداري';

  @override
  String get decisionSummary => 'ملخص القرار';

  @override
  String get decidedBy => 'تم القرار بواسطة';

  @override
  String get decidedAt => 'تاريخ القرار';

  @override
  String get reviewedBy => 'تمت المراجعة بواسطة';

  @override
  String get employeeDecisions => 'قرارات الموظفين';

  @override
  String get legalOpinion => 'الرأي القانوني';

  @override
  String get createActions => 'إنشاء إجراءات إدارية';

  @override
  String get bulkCreation => 'إنشاء جماعي';

  @override
  String get createdFromInvestigation => 'تم الإنشاء من تحقيق';

  @override
  String get convertedFromDisciplinary => 'تم التحويل من إجراء إداري';

  @override
  String get viewInvestigation => 'عرض التحقيق';

  @override
  String get loadingEmployeeDetails => 'جارٍ تحميل بيانات الموظفين...';

  @override
  String get unknownEmployee => 'غير معروف';

  @override
  String get finalDecision => 'القرار النهائي';

  @override
  String get uploadDecisionPdf => 'رفع ملف PDF للقرار';

  @override
  String get legalPdfRequired => 'ملف PDF القانوني مطلوب لإتمام المراجعة';

  @override
  String get fromInvestigation => 'من تحقيق';

  @override
  String get convertToInvestigation => 'تحويل إلى تحقيق';

  @override
  String get hrFinalDecisionAfterLegal =>
      'قرار الموارد البشرية النهائي (بعد المراجعة القانونية)';

  @override
  String get invalidApproverType => 'نوع المراجع غير صالح';

  @override
  String get basicInformation => 'المعلومات الأساسية';

  @override
  String get hrDecisions => 'قرارات الموارد البشرية';

  @override
  String get topManagementDecisions => 'قرارات الإدارة العليا';

  @override
  String get linkedDisciplinaryActions => 'الإجراءات الإدارية المرتبطة';

  @override
  String get employeeName => 'اسم الموظف';

  @override
  String get uploaded => 'تم الرفع';

  @override
  String escalatedFromDisciplinaryAction(Object id) {
    return 'تم التصعيد من الإجراء الإداري رقم $id';
  }

  @override
  String get createDisciplinaryActions => 'إنشاء إجراءات إدارية';

  @override
  String get backToDetails => 'رجوع للتفاصيل';

  @override
  String get continueButton => 'استمرار';

  @override
  String submitAll(Object count) {
    return 'إرسال الكل ($count إجراء)';
  }

  @override
  String get acknowledgeInvestigation => 'تأكيد استلام التحقيق';

  @override
  String get uploadLegalPdf => 'رفع ملف PDF القانوني';

  @override
  String get cleared => 'تمت تبرئته';

  @override
  String get verbalWarning => 'إنذار شفوي';

  @override
  String get suspension => 'إيقاف';

  @override
  String get termination => 'إنهاء الخدمة';

  @override
  String get disciplinaryActionRequired => 'يتطلب إجراء إداري';

  @override
  String get pleaseSelectDecisionForAll => 'يرجى اتخاذ قرار لجميع الموظفين';

  @override
  String get escalateToLegalDepartment => 'تصعيد إلى القسم القانوني';

  @override
  String get escalationReason => 'سبب التصعيد';

  @override
  String get provideReasonForEscalation => 'قدم سبب التصعيد للقانونية...';

  @override
  String get pleaseProvideEscalationReason => 'يرجى تقديم سبب التصعيد';

  @override
  String investigationEscalatedToLegal(Object id) {
    return 'تم تصعيد التحقيق رقم $id إلى القسم القانوني';
  }

  @override
  String get acknowledgeInvestigationMessage =>
      'سيؤدي هذا إلى إيقاف تذكيرات البريد الإلكتروني لهذا التحقيق. سيظل التحقيق مسنداً للقانونية حتى تقوم برفع ملف PDF الخاص بالتحقيق.';

  @override
  String get acknowledgeInvestigationNote =>
      'ملاحظة: يجب عليك رفع ملف PDF الخاص بالتحقيق لإعادة هذه القضية إلى الموارد البشرية.';

  @override
  String investigationAcknowledged(Object id) {
    return 'تم تأكيد استلام التحقيق رقم $id. تم إيقاف تذكيرات البريد الإلكتروني.';
  }

  @override
  String get uploadLegalPdfTitle => 'رفع ملف PDF القانوني';

  @override
  String uploadPdfConfirmation(Object id) {
    return 'رفع هذا الملف للتحقيق رقم $id؟';
  }

  @override
  String get afterUploadingReturnToHr =>
      'بعد الرفع، سيتم إعادة هذا التحقيق إلى الموارد البشرية.';

  @override
  String pdfUploadedReturnedToHr(Object id) {
    return 'تم رفع الملف. تم إعادة التحقيق رقم $id إلى الموارد البشرية.';
  }

  @override
  String get errorCouldNotReadFile => 'خطأ: لا يمكن قراءة الملف';

  @override
  String escalatedOn(Object date) {
    return 'تم التصعيد بتاريخ: $date';
  }

  @override
  String get acknowledgedByLegal => 'تم التأكيد من القانونية';

  @override
  String get pendingAcknowledgment => 'في انتظار التأكيد';

  @override
  String get viewInvestigationReportPdf => 'عرض تقرير التحقيق (PDF)';

  @override
  String get viewLegalInvestigationReportPdf =>
      'عرض تقرير التحقيق القانوني (PDF)';

  @override
  String get pdfOpeningNotImplemented => 'سيتم تنفيذ وظيفة فتح PDF قريباً';

  @override
  String daNumber(Object id) {
    return 'إجراء إداري رقم $id';
  }

  @override
  String get decision => 'القرار';

  @override
  String get autoEscalateWarning =>
      'سيتم تصعيد قرارات الإيقاف أو إنهاء الخدمة تلقائياً إلى الإدارة العليا للمراجعة';

  @override
  String investigationNumber(Object id) {
    return 'التحقيق رقم $id';
  }

  @override
  String get legalReviewCompleted => 'تمت المراجعة القانونية';

  @override
  String get legalReviewCompletedMessage =>
      'راجعت القانونية هذا التحقيق. يمكنك الآن اتخاذ القرارات النهائية.';

  @override
  String get viewLegalPdf => 'عرض ملف PDF القانوني';

  @override
  String get bulkCreationInstruction =>
      'اختر نوع الإجراء الإداري لكل موظف. سيتم نسخ تفاصيل المخالفة من التحقيق.';

  @override
  String get employeeActionTypes => 'أنواع الإجراءات للموظفين';

  @override
  String get attachmentsOptional => 'المرفقات (اختياري)';

  @override
  String get attachmentsWillBeAddedToAll =>
      'سيتم إضافة هذه المرفقات إلى جميع الإجراءات الإدارية المنشأة';

  @override
  String creatingActionsFromInvestigation(
    Object actions,
    Object count,
    Object id,
  ) {
    return 'إنشاء $count $actions من التحقيق رقم $id';
  }

  @override
  String get actions => 'إجراءات';

  @override
  String get enterLegalOpinion => 'أدخل رأيك القانوني وتوصياتك...';

  @override
  String get legalOpinionRequired => 'الرأي القانوني مطلوب';

  @override
  String get legalDocument => 'المستند القانوني';

  @override
  String get required => 'مطلوب';

  @override
  String get legalPdfMandatory => '* ملف PDF القانوني إلزامي لإتمام المراجعة';

  @override
  String get reviewHrDecisions =>
      'راجع القرارات التي اتخذتها الموارد البشرية لكل موظف';

  @override
  String get afterSubmittingReturnedToHr =>
      'بعد مراجعة الشئون القانونية، سيتم إعادة هذا التحقيق إلى الموارد البشرية للقرارات النهائية';

  @override
  String get submitLegalReview => 'إرسال المراجعة القانونية';

  @override
  String get hrDecisionsReadOnly => 'قرارات الموارد البشرية';

  @override
  String get legalReviewSubmittedSuccess => 'تم إرسال المراجعة القانونية بنجاح';

  @override
  String get errorSubmittingReview => 'خطأ في إرسال المراجعة القانونية';

  @override
  String get reviewSuspendTerminateDecisions =>
      'راجع الموظفين الذين لديهم قرارات إيقاف أو إنهاء خدمة';

  @override
  String employeesRequireReview(Object count) {
    return '$count موظف يحتاج للمراجعة';
  }

  @override
  String get noEmployeesRequireTmReview =>
      'لا يوجد موظفين يحتاجون لمراجعة الإدارة العليا';

  @override
  String get tmDecision => 'قرار الإدارة العليا';

  @override
  String get convertToDisciplinaryAction => 'تحويل لإجراء إداري';

  @override
  String get originalHrDecision => 'قرار الموارد البشرية الأصلي';

  @override
  String get tmDecisionOptional => 'قرار الإدارة العليا (PDF اختياري)';

  @override
  String get uploadTmPdf => 'رفع ملف PDF لقرار الإدارة';

  @override
  String get uploadPdfOptional => 'رفع ملف PDF (اختياري)';

  @override
  String get selectPdf => 'اختر ملف PDF';

  @override
  String get noFileSelected => 'لم يتم اختيار ملف';

  @override
  String get submitTmDecision => 'إرسال قرار الإدارة العليا';

  @override
  String get tmDecisionSubmittedSuccess => 'تم إرسال قرار الإدارة العليا بنجاح';

  @override
  String get hrDecisionWillBeExecuted =>
      'سيتم تنفيذ قرار الموارد البشرية كما هو مقترح';

  @override
  String get reasonMinimum25 => 'يجب أن يكون السبب 25 حرفاً على الأقل';

  @override
  String get upload => 'رفع';

  @override
  String get uploadDecisionPdfOptional => 'رفع ملف PDF القرار (اختياري)';

  @override
  String get choosePdfFiles => 'اختر ملفات PDF';

  @override
  String get filesSelected => 'ملف محدد';

  @override
  String get addAttachments => 'إضافة مرفقات';

  @override
  String get chooseLegalPdfRequired => 'اختر ملف PDF القانوني';

  @override
  String get legalReviewRecordedSuccess =>
      'تم تسجيل المراجعة القانونية بنجاح. تمت إعادة القضية إلى الموارد البشرية.';

  @override
  String get submitFinalDecision => 'إرسال القرار النهائي';

  @override
  String get legalHasReviewedInvestigation =>
      'راجعت القانونية هذا التحقيق وقدمت الوثائق';

  @override
  String get converted => 'محول';

  @override
  String get finalDecisionWarning =>
      'هذا هو القرار النهائي. سيتم إغلاق التحقيق بعد الإرسال.';

  @override
  String duplicateFileSkipped(Object fileName) {
    return 'تم تخطي $fileName (مكرر)';
  }

  @override
  String get daConvertedToInvestigation =>
      'تم تحويل طلب الإجراء الإداري إلى تحقيق';

  @override
  String get convertedToInvestigation => 'تم التحويل إلى تحقيق';

  @override
  String get convertToInvestigationDescription =>
      'سيتم تحويل الإجراء الإداري إلى طلب تحقيق رسمي.';

  @override
  String get whatHappensNext => 'ماذا سيحدث بعد ذلك:';

  @override
  String get investigationRequestWillBeCreated => 'سيتم إنشاء طلب تحقيق';

  @override
  String get originalDaWillBeLinked => 'سيتم ربط الإجراء الإداري الأصلي';

  @override
  String get investigationFollowsFormalProcess =>
      'يتبع التحقيق عملية مراجعة رسمية';

  @override
  String get hrLegalTopManagement =>
      'الموارد البشرية ← القانونية (إذا لزم الأمر) ← الإدارة العليا';

  @override
  String get convertToInvestigationConfirmation =>
      'هل أنت متأكد من أنك تريد تحويل هذا إلى تحقيق؟';

  @override
  String get uploadInvestigationPdfOptional => 'رفع ملف تحقيق (اختياري)';

  @override
  String get fileSelected => 'تم اختيار الملف';

  @override
  String get choosePdfFile => 'اختر ملف PDF';

  @override
  String get pdfFilesOnlyMax10mb => 'ملفات PDF فقط، حد أقصى 10 ميجابايت';

  @override
  String get invalidFilePdfUnder10mb =>
      'ملف غير صحيح. يرجى رفع ملف PDF صالح أقل من 10 ميجابايت.';

  @override
  String errorSelectingFile(String error) {
    return 'خطأ في اختيار الملف: $error';
  }

  @override
  String get viewButton => 'عرض';

  @override
  String failedToLoadInvestigation(String error) {
    return 'فشل تحميل التحقيق: $error';
  }

  @override
  String get legalEscalation => 'تصعيد إلى الشؤون القانونية';

  @override
  String get completionDate => 'تاريخ اكتمال التحقيق';

  @override
  String get changeLog => 'سجل التغييرات';

  @override
  String get hrInvestigationPdf => 'ملف تحقيق الموارد البشرية';

  @override
  String get investigationPdfDocument => 'ملف التحقيق المرفق';

  @override
  String uploadedDate(String date) {
    return 'تاريخ الرفع: $date';
  }

  @override
  String get legalInvestigationPdf => 'ملف التحقيق القانوني';

  @override
  String get legalInvestigationPdfDocument => 'ملف التحقيق القانوني المرفق';

  @override
  String get finalApproval => 'موافقة نهائية';

  @override
  String get finalDecline => 'رفض نهائي';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get terminationRecommendedDate => 'تاريخ التوصية بإنهاء الخدمة';

  @override
  String get bulkEmployeeUpload => 'تحميل مجموعة موظفين';

  @override
  String get instructions => 'التعليمات';

  @override
  String get downloadTemplateInstruction => 'قم بتنزيل قالب CSV أو Excel';

  @override
  String get fillEmployeeDataInstruction => 'أدخل بيانات الموظفين';

  @override
  String get uploadFileInstruction => 'ارفع الملف المكتمل';

  @override
  String get reviewAndFixErrorsInstruction => 'راجع وأصلح أي أخطاء في التحقق';

  @override
  String get submitToAddEmployeesInstruction => 'اضغط إرسال لإضافة الموظفين';

  @override
  String get downloadCsvTemplate => 'تنزيل قالب CSV';

  @override
  String get downloadExcelTemplate => 'تنزيل قالب Excel';

  @override
  String get uploadFile => 'رفع ملف';

  @override
  String get parsingFile => 'جارٍ تحليل الملف...';

  @override
  String get validatingData => 'جارٍ التحقق من البيانات...';

  @override
  String get totalEmployees => 'إجمالي الموظفين';

  @override
  String get valid => 'صالح';

  @override
  String get withErrors => 'بأخطاء';

  @override
  String get invalid => 'غير صالح';

  @override
  String get reviewData => 'مراجعة البيانات';

  @override
  String get revalidate => 'إعادة التحقق';

  @override
  String get clickOnRedCellsToFix => 'اضغط على الخلايا الحمراء لإصلاح الأخطاء';

  @override
  String get n1Code => 'كود المدير المباشر';

  @override
  String uploadingProgress(int current, int total) {
    return 'جارٍ الرفع: $current/$total موظف';
  }

  @override
  String submitEmployees(int count) {
    return 'إرسال ($count موظف)';
  }

  @override
  String get fixErrorsToSubmit => 'أصلح جميع الأخطاء للتمكين من الإرسال';

  @override
  String get uploadComplete => 'اكتمل الرفع';

  @override
  String get partialUploadComplete => 'اكتمل الرفع جزئياً';

  @override
  String get succeeded => 'نجح';

  @override
  String get failed => 'فشل';

  @override
  String get failedEmployeesList => 'قائمة الموظفين الذين لم يتم إضافتهم:';

  @override
  String get retryFailed => 'إعادة محاولة للموظفين الذين لم يتم إضافتهم';

  @override
  String get confirmUpload => 'تأكيد الرفع';

  @override
  String confirmUploadMessage(int count) {
    return 'هل أنت متأكد من إضافة $count موظف؟';
  }

  @override
  String templateSavedTo(String path) {
    return 'تم حفظ القالب في: $path';
  }

  @override
  String employeesAddedSuccessfully(int count) {
    return 'تم إضافة $count موظف بنجاح';
  }

  @override
  String get employeeGroups => 'مجموعات الموظفين';

  @override
  String get manageGroups => 'إدارة المجموعات';

  @override
  String get addMember => 'إضافة عضو';

  @override
  String get noMembersInGroup => 'لا يوجد أعضاء في هذه المجموعة بعد.';

  @override
  String get searchEmployeesToAdd => 'ابحث عن موظفين للإضافة...';

  @override
  String get confirmRemoveMemberTitle => 'إزالة عضو';

  @override
  String confirmRemoveMemberMessage(String name, String group) {
    return 'هل أنت متأكد من إزالة $name من مجموعة $group؟';
  }

  @override
  String get reassignDirectReports => 'إعادة تعيين التقارير المباشرة';

  @override
  String suspendingEmployee(String name) {
    return 'إيقاف: $name';
  }

  @override
  String get directReportsAssignmentWarning =>
      'يجب تعيين مدير N+1 جديد لجميع التقارير المباشرة قبل الإيقاف.';

  @override
  String employeesAssignedProgress(int assigned, int total) {
    return '$assigned من $total موظف تم تعيينهم';
  }

  @override
  String get assignN1ToEmployee => 'تعيين N+1 لموظف واحد محدد';

  @override
  String assignN1ToEmployees(int count) {
    return 'تعيين N+1 لـ $count موظفين محددين';
  }

  @override
  String get bulkAssignN1SelectFirst =>
      'تعيين N+1 بالجملة — اختر الصفوف أدناه أولاً';

  @override
  String get selectRowsFirstToSearch => 'اختر الصفوف أولاً لتفعيل البحث';

  @override
  String directReportsCount(int count) {
    return 'التقارير المباشرة ($count)';
  }

  @override
  String get newN1 => 'N+1 جديد';

  @override
  String get notAssigned => 'غير معيّن';

  @override
  String get processing => 'جارٍ المعالجة...';

  @override
  String get confirmAndSuspend => 'تأكيد وإيقاف';

  @override
  String couldNotLoadDirectReports(String error) {
    return 'تعذر تحميل التقارير المباشرة: $error';
  }

  @override
  String get suspensionReason => 'سبب الإيقاف';

  @override
  String get selectSuspensionReason => 'اختر السبب';

  @override
  String get reasonResignation => 'استقالة';

  @override
  String get reasonTermination => 'إنهاء خدمة';

  @override
  String get reasonOther => 'أخرى';

  @override
  String get lastWorkingDate => 'آخر يوم عمل';

  @override
  String get selectLastWorkingDate => 'اختر آخر يوم عمل';

  @override
  String get completed => 'مكتمل';

  @override
  String get acknowledged => 'تم الاستلام';

  @override
  String get hrLetter => 'خطاب HR';

  @override
  String get hrLetterRequest => 'طلب خطاب HR';

  @override
  String get hrLetterRequests => 'طلبات خطابات HR';

  @override
  String get myHrLetterRequests => 'طلبات خطابات HR الخاصة بي';

  @override
  String get teamHrLetterRequests => 'طلبات خطابات HR';

  @override
  String get hrLetterSubmittedSuccessfully => 'تم تقديم طلب خطاب HR بنجاح';

  @override
  String get letterPurpose => 'الغرض من الخطاب';

  @override
  String get letterPurposeBank => 'بنك';

  @override
  String get letterPurposeEmbassy => 'سفارة';

  @override
  String get letterPurposeOther => 'أخرى';

  @override
  String get travelFromDate => 'تاريخ السفر من';

  @override
  String get travelToDate => 'تاريخ السفر إلى';

  @override
  String get hrLetterDetails => 'التفاصيل';

  @override
  String get hrLetterDetailsHint => 'أدخل أي تفاصيل إضافية...';

  @override
  String get hrLetterDetailsRequired =>
      'التفاصيل مطلوبة عند اختيار غرض \'أخرى\'';

  @override
  String get hrLetterNationalIdRequired => 'الرقم القومي مطلوب';

  @override
  String get hrLetterPurposeRequired => 'يرجى اختيار غرض الخطاب';

  @override
  String get hrLetterTravelFromRequired => 'تاريخ بداية السفر مطلوب';

  @override
  String get hrLetterTravelToRequired => 'تاريخ نهاية السفر مطلوب';

  @override
  String get hrLetterTravelToAfterFrom =>
      'يجب أن يكون تاريخ نهاية السفر بعد تاريخ بدايته';

  @override
  String get notEligibleForHrLetter => 'غير مؤهل لطلب خطاب HR';

  @override
  String get tenureLessThanThreeMonths =>
      'أنت غير مؤهل لأن مدة خدمتك أقل من 3 أشهر';

  @override
  String get acknowledgeHrLetterRequest => 'تأكيد الاستلام';

  @override
  String get confirmAcknowledgeHrLetter => 'تأكيد الاستلام';

  @override
  String get confirmAcknowledgeHrLetterMessage =>
      'هل أنت متأكد من رغبتك في استلام طلب الخطاب الرسمي؟';

  @override
  String get completeRequest => 'إكمال الطلب';

  @override
  String get confirmCompleteHrLetter => 'تأكيد الإكمال';

  @override
  String get confirmCompleteHrLetterMessage =>
      'هل أنت متأكد من رغبتك في تحديد هذا الخطاب الرسمي كمكتمل وجاهز للاستلام؟';

  @override
  String get completing => 'جاري الإكمال...';

  @override
  String get requestCompletedSuccessfully => 'تم إكمال الطلب بنجاح';

  @override
  String get hrLetterReadyForCollection => 'خطاب HR جاهز للاستلام';

  @override
  String get searchByNameOrNationalId =>
      'البحث بالاسم أو الكود أو الرقم القومي';

  @override
  String get noHrLetterRequestsFound => 'لم يتم العثور على طلبات خطابات HR';

  @override
  String failedToCompleteRequest(String error) {
    return 'فشل في إكمال الطلب: $error';
  }

  @override
  String failedToAcknowledgeHrLetterRequest(String error) {
    return 'فشل في تأكيد الاستلام: $error';
  }

  @override
  String failedToCancelHrLetterRequest(String error) {
    return 'فشل في إلغاء الطلب: $error';
  }

  @override
  String failedToDeclineHrLetterRequest(String error) {
    return 'فشل في رفض الطلب: $error';
  }

  @override
  String get lastActionAt => 'آخر تحديث';

  @override
  String get acknowledgedAt => 'تاريخ الاطلاع';

  @override
  String get completedAt => 'تاريخ الاكتمال';

  @override
  String get declinedAt => 'تاريخ الرفض';

  @override
  String get cancelledAt => 'تاريخ الإلغاء';

  @override
  String get hrHandler => 'موظف الموارد البشرية';

  @override
  String get n2ApprovalDate => 'تاريخ موافقة المدير الثاني';

  @override
  String get n2ApprovalReason => 'سبب قرار المدير الثاني';

  @override
  String get hrApprovalDate => 'تاريخ موافقة الموارد البشرية';

  @override
  String get hrApprovalReason => 'سبب قرار الموارد البشرية';

  @override
  String get legalEscalationDate => 'تاريخ إحالة الشؤون القانونية';

  @override
  String get legalCompletionDate => 'تاريخ انتهاء القضية القانونية';

  @override
  String get employeeAcknowledgmentDate => 'تاريخ اطلاع الموظف';

  @override
  String get employeeAcknowledgmentRemark => 'ملاحظة اطلاع الموظف';

  @override
  String get employeeAcknowledgmentType => 'نوع اطلاع الموظف';

  @override
  String get linkedInvestigation => 'التحقيق المرتبط';

  @override
  String get linkedDisciplinaryAction => 'الإجراء الإداري المرتبط';

  @override
  String get requestorDepartment => 'قسم مقدم الطلب';

  @override
  String get requestorTitle => 'مسمى مقدم الطلب';

  @override
  String get scheduleOnShift => 'في الدوام';

  @override
  String get scheduleLateNoPunch => 'متأخر / لم يسجل';

  @override
  String get scheduleOff => 'خارج الدوام';

  @override
  String get scheduleLoading => 'جارٍ تحميل الجدول...';

  @override
  String get scheduleUnableToLoad => 'تعذّر تحميل الجدول';

  @override
  String get scheduleCheckConnection => 'تحقق من اتصالك وأعد المحاولة';

  @override
  String get scheduleRetry => 'إعادة المحاولة';

  @override
  String get schedulePageTitle => 'جدول الموظفين';

  @override
  String get scheduleStatusPublished => 'منشور';

  @override
  String get scheduleStatusDraft => 'مسودة';

  @override
  String get scheduleTabWeekly => 'أسبوعي';

  @override
  String get scheduleTabDaily => 'يومي';

  @override
  String get scheduleTabMonthly => 'شهري';

  @override
  String get scheduleTabOnShiftNow => 'في الدوام الآن';

  @override
  String get scheduleTabMySchedule => 'جدولي';

  @override
  String get scheduleTabSwaps => 'التبادلات';

  @override
  String get mobileBulkAssignTitle => 'تعيين ورديات';

  @override
  String get mobileBulkStep1Shift => '١ · الوردية';

  @override
  String get mobileBulkStep2Days => '٢ · الأيام';

  @override
  String get mobileBulkStep3Employees => '٣ · الموظفون';

  @override
  String get mobileBulkWholeWeek => 'الأسبوع كله';

  @override
  String get mobileBulkClear => 'مسح';

  @override
  String get mobileBulkAll => 'الكل';

  @override
  String mobileBulkAssignN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ورديات',
      one: 'وردية',
    );
    return 'تعيين $count $_temp0';
  }

  @override
  String get mobileBulkSearchHint => 'ابحث بالاسم أو القسم…';

  @override
  String get mobileBulkFillDay => 'تعبئة هذا اليوم';

  @override
  String get mobileBulkAssignDay => 'تعيين هذا اليوم…';

  @override
  String get mobileBulkAssignShifts => 'تعيين ورديات…';

  @override
  String get mobileBulkOneShift => 'وردية واحدة';

  @override
  String mobileWeekHoursScheduled(int hours) {
    return '$hours ساعة مجدولة';
  }

  @override
  String get mobileThisWeek => 'هذا الأسبوع';

  @override
  String get mobileUpcoming14Days => 'القادم · 14 يوماً';

  @override
  String get mobileSwapActivity => 'نشاط التبادل';

  @override
  String get mobileSeeAll => 'عرض الكل';

  @override
  String get mobileDayOff => 'يوم إجازة';

  @override
  String get mobileOnLeave => 'في إجازة';

  @override
  String get mobileApprovedTimeOff => 'إجازة معتمدة';

  @override
  String get mobileNoShiftScheduled => 'لا توجد وردية مجدولة';

  @override
  String get mobileOnShiftNow => 'في الدوام';

  @override
  String get mobileLateNoPunch => 'متأخر / لم يسجل';

  @override
  String get mobileOffShift => 'خارج الدوام';

  @override
  String get mobileMoreTab => 'المزيد';

  @override
  String get mobilePublishWeek => 'نشر الأسبوع';

  @override
  String get mobileCopyLastWeek => 'نسخ الأسبوع الماضي';

  @override
  String get mobileFilters => 'التصفية';

  @override
  String get mobileAllTeams => 'جميع الفرق';

  @override
  String get mobileFiltersTitle => 'التصفية';

  @override
  String get mobileDepartment => 'القسم';

  @override
  String get mobileLocation => 'الموقع';

  @override
  String get mobileTeamScope => 'نطاق الفريق';

  @override
  String get mobileTeamScopeAll => 'الجميع';

  @override
  String get mobileTeamScopeDirect => 'المباشرون';

  @override
  String get mobileTeamScopeIndirect => 'غير المباشرون';

  @override
  String get mobileFiltersReset => 'إعادة ضبط';

  @override
  String get mobileFiltersApply => 'تطبيق';

  @override
  String get mobileShiftRequests => 'طلبات التبادل';

  @override
  String get mobilePendingAction => 'بانتظار الإجراء';

  @override
  String get mobileSentByMe => 'أرسلتها أنا';

  @override
  String get mobileSwapHistory => 'السجل';

  @override
  String get mobileOpenRequests => 'الطلبات المفتوحة';

  @override
  String get mobilePastRequests => 'الطلبات السابقة';

  @override
  String mobileConflictWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعارضات',
      one: 'تعارض',
    );
    return 'سيتم إنشاء $count $_temp0';
  }

  @override
  String get mobileStatPeople => 'الموظفون المجدولون';

  @override
  String get mobileStatShifts => 'الورديات هذا الأسبوع';

  @override
  String get mobileStatConflicts => 'التعارضات';

  @override
  String get mobileStatUnpublished => 'غير منشورة';

  @override
  String get mobileStatAllClear => 'لا توجد تعارضات';

  @override
  String get mobileStatAllPublished => 'جميعها منشورة';

  @override
  String mobileStatOfTotal(int total) {
    return 'من $total في العرض';
  }

  @override
  String mobileStatHoursTotal(int hours) {
    return '$hours ساعة إجمالاً';
  }

  @override
  String get mobileShiftDetailWorking => 'يعملون في هذه الوردية';

  @override
  String get mobileRequestSwap => 'طلب تبادل وردية';

  @override
  String get mobileCurrentlyOnShift => 'في الدوام الآن';

  @override
  String get mobileLateTitle => 'متأخر / لم يسجل';

  @override
  String get mobileOffTitle => 'خارج الدوام';

  @override
  String get scheduleCopyDialogTitle => 'نسخ جدول الأسبوع الماضي؟';

  @override
  String get scheduleCopyFrom => 'من';

  @override
  String get scheduleCopyTo => 'إلى';

  @override
  String get scheduleCopyShiftsToCopy => 'الورديات المراد نسخها';

  @override
  String get scheduleCopyTeamSize => 'حجم الفريق';

  @override
  String get scheduleCopyEmployeesToCopy => 'عدد الموظفين المراد نسخهم';

  @override
  String scheduleCopyEmployees(int count) {
    return '$count موظف';
  }

  @override
  String get scheduleCopyNote =>
      'سيتم الاحتفاظ بالورديات الموجودة لهذا الأسبوع. سيتم تعبئة الأيام الفارغة فقط.';

  @override
  String get scheduleCopyButton => 'نسخ الجدول';

  @override
  String get schedulePublishDialogTitle => 'نشر جدول هذا الأسبوع؟';

  @override
  String get schedulePublishTotalShifts => 'الورديات';

  @override
  String get schedulePublishToBePublished => 'سيتم نشرها';

  @override
  String get schedulePublishEmployeesNotified => 'الموظفون المُخطَرون';

  @override
  String get schedulePublishWeekLabel => 'الأسبوع';

  @override
  String get schedulePublishNote => 'سيتلقى الموظفون إشعاراً عند نشر الجدول.';

  @override
  String get schedulePublishButton => 'نشر';

  @override
  String get scheduleToolbarToday => 'اليوم';

  @override
  String scheduleToolbarWeek(int number) {
    return 'أسبوع $number';
  }

  @override
  String get scheduleAllDepartments => 'جميع الأقسام';

  @override
  String get scheduleAllLocations => 'جميع المواقع';

  @override
  String get scheduleDirectPlusIndirect => 'المباشرون وغير المباشرين';

  @override
  String get scheduleDirectReportsOnly => 'المباشرون فقط';

  @override
  String get scheduleIndirectOnly => 'غير المباشرين فقط';

  @override
  String get scheduleCopyLastWeek => 'نسخ الأسبوع الماضي';

  @override
  String get scheduleCopyLastWeekNoShifts => 'لا توجد ورديات في الأسبوع الماضي';

  @override
  String get scheduleCopyNoRoom => 'لا توجد أيام فارغة للنسخ إليها هذا الأسبوع';

  @override
  String get schedulePublishing => 'جارٍ النشر…';

  @override
  String get schedulePublishingPleaseWait => 'جارٍ النشر، يرجى الانتظار';

  @override
  String get schedulePublishWeek => 'نشر الأسبوع';

  @override
  String get schedulePanelSwapRequests => 'طلبات تبديل الوردية';

  @override
  String get scheduleNoPendingSwaps => 'لا توجد طلبات تبديل معلّقة';

  @override
  String get schedulePanelConflicts => 'التعارضات';

  @override
  String get scheduleNoConflicts => 'لا توجد تعارضات';

  @override
  String get schedulePanelTimeOff => 'الإجازات';

  @override
  String get scheduleNoApprovedLeaves => 'لا توجد إجازات معتمدة هذا الأسبوع';

  @override
  String get scheduleSidePanelCollapse => 'طي اللوحة';

  @override
  String get scheduleSidePanelExpand => 'توسيع اللوحة';

  @override
  String get scheduleShiftNewShift => 'وردية جديدة';

  @override
  String get scheduleShiftEditShift => 'تعديل الوردية';

  @override
  String get scheduleShiftBulkAssign => 'تعيين جماعي';

  @override
  String scheduleShiftAssignCells(int count) {
    return 'تعيين وردية لـ $count خلايا';
  }

  @override
  String get scheduleConflictDetected => 'تم اكتشاف تعارض';

  @override
  String get scheduleQuickTypes => 'أنواع سريعة';

  @override
  String get scheduleOffTypeDayOff => 'راحة';

  @override
  String get scheduleOffTypePlannedLeave => 'إجازة مخططة';

  @override
  String get scheduleOffTypeUnplannedLeave => 'إجازة غير مخططة';

  @override
  String get scheduleOffTypeHoliday => 'عطلة';

  @override
  String get scheduleSummary => 'ملخص';

  @override
  String get scheduleSummaryShifts => 'ورديات';

  @override
  String get scheduleSummaryConflicts => 'تعارضات';

  @override
  String scheduleSummaryLeaveOnShift(String type) {
    return '$type (مع وردية)';
  }

  @override
  String scheduleEmptyCellsRemaining(int count) {
    return 'لا يزال $count خلية غير مملوءة';
  }

  @override
  String get scheduleQuickTemplates => 'قوالب سريعة';

  @override
  String get scheduleNoTemplatesYet =>
      'لا توجد قوالب بعد — أدخل الأوقات أدناه لإنشاء واحد';

  @override
  String get scheduleStartTime => 'وقت البداية';

  @override
  String get scheduleEndTime => 'وقت النهاية';

  @override
  String get scheduleHours => 'ساعات';

  @override
  String get scheduleSaveAsTemplate => 'حفظ كقالب';

  @override
  String get scheduleTemplateName => 'اسم القالب';

  @override
  String get scheduleTemplateNameHint => 'مثال: وردية صباحية';

  @override
  String get scheduleTemplateNameRequired => 'اسم القالب مطلوب';

  @override
  String get scheduleNoteOptional => 'ملاحظة (اختياري)';

  @override
  String get scheduleNotifyEmployees => 'إشعار الموظفين عند نشر الجدول';

  @override
  String get scheduleRemoveShift => 'حذف الوردية';

  @override
  String get scheduleSaveAsDraft => 'حفظ كمسودة';

  @override
  String get scheduleTapCellFirst =>
      'اضغط على خلية في الجدول أولاً لتحديد الموظف واليوم.';

  @override
  String get scheduleConflictApprovedLeave =>
      'الموظف في إجازة معتمدة ذلك اليوم';

  @override
  String get scheduleConflictExceedsMaxHours => 'تتجاوز الوردية 16 ساعة';

  @override
  String get scheduleConflictInsufficientRestAfter =>
      'أقل من 8 ساعات راحة بعد الوردية السابقة';

  @override
  String get scheduleConflictInsufficientRestBefore =>
      'أقل من 8 ساعات راحة قبل الوردية التالية';

  @override
  String get scheduleRequestSwapTitle => 'طلب تبديل وردية';

  @override
  String get scheduleSwapWith => 'التبديل مع';

  @override
  String get scheduleSearchColleague => 'البحث عن زميل…';

  @override
  String get scheduleSameShift => 'نفس الوردية';

  @override
  String get scheduleDayOff => 'يوم إجازة';

  @override
  String get schedulePleaseSelectColleague => 'الرجاء اختيار زميل';

  @override
  String get scheduleReasonOptional => 'السبب (اختياري)';

  @override
  String get scheduleWhySwapHint => 'لماذا تحتاج إلى تبديل هذه الوردية؟';

  @override
  String get scheduleSendRequest => 'إرسال الطلب';

  @override
  String get scheduleNoUpcomingShifts => 'لا توجد ورديات منشورة قادمة للتبديل.';

  @override
  String get scheduleSelectShift => 'اختر وردية للتبديل';

  @override
  String get scheduleNoData => 'لا توجد بيانات جدول متاحة.';

  @override
  String get scheduleUpcomingShifts => 'الورديات القادمة · 14 يوماً';

  @override
  String get scheduleNotAssigned => 'غير مُعيَّن';

  @override
  String get scheduleRequestSwap => 'طلب تبديل';

  @override
  String get scheduleTeamView => 'الفريق';

  @override
  String get scheduleColleaguesView => 'الزملاء';

  @override
  String get scheduleNotAvailableInColleaguesMode => 'غير متاح في وضع الزملاء';

  @override
  String get scheduleSelectOtherShiftsToSwap => 'اختر ورديات أخرى للتبديل معها';

  @override
  String get scheduleSwapSameShift => 'نفس الوردية — لا يوجد ما يُبدَّل';

  @override
  String get scheduleSwapAlreadyPending =>
      'لديك طلب تبديل مفتوح لهذا اليوم بالفعل';

  @override
  String get scheduleSwapPastDay =>
      'لا يمكن طلب التبديل إلا للورديات المستقبلية';

  @override
  String get scheduleSwapOnLeave => 'لا يمكن تبديل وردية في يوم إجازة';

  @override
  String get scheduleSwapColleagueOnLeave =>
      'الزميل في إجازة — لا يمكن تبديل هذه الوردية';

  @override
  String get scheduleSwapWantsToSwap => 'يريد تبديل الوردية معك';

  @override
  String get scheduleSwapAwaitingManagerApproval =>
      'التبديل بانتظار موافقة المدير';

  @override
  String get scheduleSwapCompleted => 'تم التبديل';

  @override
  String get scheduleSwapDeclined => 'تم رفض طلب التبديل';

  @override
  String get scheduleSwapCancelledByRequester => 'تم إلغاء الطلب من قِبل مقدمه';

  @override
  String get scheduleSwapAwaitingColleague => 'بانتظار رد الزميل';

  @override
  String get scheduleSwapAwaitingManager => 'بانتظار موافقة المدير';

  @override
  String get scheduleSwapRequestDeclined => 'تم رفض الطلب';

  @override
  String get scheduleSwapYouCancelled => 'لقد ألغيت هذا الطلب';

  @override
  String get scheduleStatusApproved => 'معتمد';

  @override
  String get scheduleStatusCancelled => 'ملغي';

  @override
  String get scheduleStatusDeclined => 'مرفوض';

  @override
  String get scheduleAwaitingColleagueBadge => 'بانتظار الزميل';

  @override
  String get scheduleAwaitingManagerBadge => 'بانتظار المدير';

  @override
  String scheduleGridCellSelected(int count) {
    return '$count خلية محددة';
  }

  @override
  String scheduleGridCellsSelected(int count) {
    return '$count خلايا محددة';
  }

  @override
  String get scheduleAssignShift => 'تعيين وردية';

  @override
  String get scheduleCoverage => 'التغطية';

  @override
  String get scheduleScrollTooltip => 'التمرير (Shift + عجلة الماوس)';

  @override
  String scheduleEmployeeColumn(int count) {
    return 'الموظف · $count';
  }

  @override
  String get scheduleKpiPeopleScheduled => 'موظفون مجدولون';

  @override
  String scheduleKpiOfInView(int total) {
    return 'من $total في العرض';
  }

  @override
  String get scheduleKpiShiftsThisWeek => 'ورديات هذا الأسبوع';

  @override
  String scheduleKpiTotalHours(int hours) {
    return '$hours ساعة إجمالاً';
  }

  @override
  String get scheduleKpiConflicts => 'تعارضات';

  @override
  String get scheduleKpiAllClear => 'لا تعارضات';

  @override
  String get scheduleKpiNeedReview => 'تحتاج مراجعة';

  @override
  String get scheduleKpiUnpublishedDrafts => 'مسودات غير منشورة';

  @override
  String get scheduleKpiAllPublished => 'جميعها منشورة';

  @override
  String get scheduleKpiPendingPublish => 'بانتظار النشر';

  @override
  String get scheduleKpiOnApprovedLeave => 'في إجازة معتمدة';

  @override
  String get scheduleKpiThisWeek => 'هذا الأسبوع';

  @override
  String get scheduleLegendMorning => 'صباحي';

  @override
  String get scheduleLegendAfternoon => 'بعد الظهر';

  @override
  String get scheduleLegendOvernight => 'ليلي ممتد';

  @override
  String get scheduleLegendNight => 'ليلي';

  @override
  String get scheduleLegendLeave => 'إجازة';

  @override
  String get scheduleLegendDraft => 'مسودة';

  @override
  String get scheduleLegendConflict => 'تعارض';

  @override
  String get schedulePinnedSelfBadge => 'أنت';

  @override
  String get schedulePinnedManagerBadge => 'المدير';

  @override
  String get scheduleProposedBadge => 'مقترح';

  @override
  String get scheduleReservedByManager => 'محجوز من قبل مديرك';

  @override
  String get scheduleDraftHint => 'مسودة — مديرك هو من ينشرها';

  @override
  String scheduleLegendPublished(int count) {
    return '$count منشور';
  }

  @override
  String get daySat => 'سبت';

  @override
  String get daySun => 'أحد';

  @override
  String get dayMon => 'اثنين';

  @override
  String get dayTue => 'ثلاثاء';

  @override
  String get dayWed => 'أربعاء';

  @override
  String get dayThu => 'خميس';

  @override
  String get dayFri => 'جمعة';

  @override
  String get monthJan => 'يناير';

  @override
  String get monthFeb => 'فبراير';

  @override
  String get monthMar => 'مارس';

  @override
  String get monthApr => 'أبريل';

  @override
  String get monthMay => 'مايو';

  @override
  String get monthJun => 'يونيو';

  @override
  String get monthJul => 'يوليو';

  @override
  String get monthAug => 'أغسطس';

  @override
  String get monthSep => 'سبتمبر';

  @override
  String get monthOct => 'أكتوبر';

  @override
  String get monthNov => 'نوفمبر';

  @override
  String get monthDec => 'ديسمبر';

  @override
  String get scheduleOpenSlot => 'دوام شاغر';

  @override
  String get scheduleAnErrorOccurred => 'حدث خطأ';

  @override
  String scheduleCarryOverEnds(String time) {
    return '↵ ينتهي $time';
  }

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get requestsLoadFailed => 'خطأ في تحميل الطلبات';

  @override
  String get errorLoadingPendingRequests => 'خطأ في تحميل الطلبات المعلّقة';

  @override
  String get teamShiftSwapRequests => 'طلبات الفريق لتبديل الوردية';

  @override
  String get colleaguesSwapRequests => 'طلبات تبديل زملائي';

  @override
  String get shiftSwapRequests => 'طلبات تبديل الدوام';

  @override
  String get schedule => 'جدول الدوام';

  @override
  String get shiftMorning => 'صباحي';

  @override
  String get shiftEvening => 'مسائي';

  @override
  String get shiftAfternoon => 'بعد الظهر';

  @override
  String get shiftOvernight => 'ليلي ممتد';

  @override
  String get shiftNight => 'ليلي';

  @override
  String get shiftFullDay => 'يوم كامل';

  @override
  String get hrTools => 'أدوات الموارد البشرية';

  @override
  String get bulkLeaves => 'إجازات جماعية';

  @override
  String get bulkOvertimeIncrement => 'زيادة أوقات عمل إضافي جماعية';

  @override
  String get selectEmployeesFirst => 'يرجى اختيار موظف واحد على الأقل';

  @override
  String get bulkLeavesSubmittedSuccessfully => 'تمت إضافة الإجازات بنجاح';

  @override
  String get bulkOvertimeSubmittedSuccessfully =>
      'تم تحديث رصيد الوقت الإضافي بنجاح';

  @override
  String get daysToAdd => 'أيام للإضافة';

  @override
  String get daysToAddHint => 'مثال: 1.5';

  @override
  String get invalidDaysToAdd => 'أدخل رقمًا صحيحًا أكبر من الصفر';

  @override
  String get bulkLeaveNote =>
      'ستُعتمد الإجازات تلقائيًا لجميع الموظفين المحددين';

  @override
  String get approvalMode => 'طريقة الاعتماد';

  @override
  String get autoApproveMode => 'اعتماد تلقائي';

  @override
  String get normalApprovalCycleMode => 'الدورة المعتادة';

  @override
  String get bulkLeaveApprovalCycleNote =>
      'سيتم إرسال الطلبات إلى المدير المباشر (N+1) لكل موظف للاعتماد';

  @override
  String get bulkSickNoteSingleEmployeeOnly =>
      'يمكن إرفاق تقرير طبي فقط عند اختيار موظف واحد';

  @override
  String get bulkLeaveNoteUploadFailed =>
      'تم إنشاء الإجازة، لكن تعذر رفع التقرير الطبي';

  @override
  String get bulkLeavesPartialTitle => 'لم يتم إنشاء بعض الطلبات';

  @override
  String bulkLeavesPartialSummary(int created, int total) {
    return 'تم إنشاء $created من $total طلبات';
  }

  @override
  String get tutTopBarTitle => 'شريط العنوان';

  @override
  String get tutTopBarBody =>
      'يعرض اسم الصفحة الحالية، واسم المستخدم المسجّل دخوله، وزر تسجيل الخروج على اليسار.';

  @override
  String get tutSidebarTitle => 'شريط التنقّل الجانبي';

  @override
  String get tutSidebarBody =>
      'اختصارات لجميع أقسام النظام: الرئيسية، الإجازات، البصمة، السلف، الخطابات وغيرها.';

  @override
  String get tutPendingTitle => 'الطلبات المعلّقة';

  @override
  String get tutPendingBody =>
      'الطلبات التي تنتظر اتخاذ إجراء منك، مقسّمة حسب النوع: إجازات، مأموريات، بصمة، سلف، إجراءات إدارية.';

  @override
  String get tutProcessingTitle => 'طلبات قيد المعالجة';

  @override
  String get tutProcessingBody =>
      'الطلبات التي أرسلتها ولا تزال قيد المراجعة من قبل الإدارة أو الموارد البشرية.';

  @override
  String get tutRecentTitle => 'طلبات تمت معالجتها مؤخراً';

  @override
  String get tutRecentBody =>
      'سجلّ بأحدث الطلبات التي تمت معالجتها، للرجوع إليها بسهولة.';

  @override
  String get tutQuickActionsTitle => 'الإجراءات السريعة';

  @override
  String get tutQuickActionsBody =>
      'من هنا تبدأ أي طلب جديد بضغطة واحدة: مأمورية عمل، إجازة، سلفة، إثبات بصمة، خطاب HR، أو إجراء إداري.';

  @override
  String get tutLeaveButtonTitle => 'لنقدّم طلب إجازة';

  @override
  String get tutLeaveButtonBody =>
      'هذا زر «طلب إجازة». اضغط عليه لفتح نموذج تقديم الإجازة.';

  @override
  String get tutLeaveBalancesTitle => 'أرصدتك';

  @override
  String get tutLeaveBalancesBody =>
      'نظرة سريعة على أرصدة إجازاتك. «المتاح الآن» هو ما يمكنك استخدامه اليوم (وقد يصبح سالبًا إذا كان لديك عجز). أيام الترحيل هي رصيد العام السابق وتنتهي في 31 مارس، ويُعرض رصيد الأوفرتايم/التعويضي بشكل منفصل ويُستخدم قبل الإجازة السنوية.';

  @override
  String get tutLeaveFromDateTitle => 'تاريخ البداية';

  @override
  String get tutLeaveFromDateBody =>
      'اختر أول يوم لإجازتك. في التقويم، الأيام المشطوبة باللون الأحمر غير متاحة لوجود طلب إجازة أو مأمورية أو بصمة ناقصة عليها. اضغط على اليوم الأحمر لمعرفة السبب.';

  @override
  String get tutLeaveToDateTitle => 'تاريخ النهاية';

  @override
  String get tutLeaveToDateBody =>
      'اختر آخر يوم لإجازتك. لا يمكن أن تمتد الفترة عبر يوم غير متاح (أحمر)، لذا تتغيّر الأيام القابلة للاختيار تلقائيًا بناءً على تاريخ البداية.';

  @override
  String get tutLeaveHoursTitle => 'ساعات جزئية';

  @override
  String get tutLeaveHoursBody =>
      'يظهر فقط لطلب ليوم واحد. اختر عدد الساعات التي تحتاجها بدلًا من يوم كامل — اتركه فارغًا لأخذ اليوم كاملًا. اختيار الساعات يحدّد أنواع الإجازات المتاحة.';

  @override
  String get tutLeaveDayCountTitle => 'أيام الغياب';

  @override
  String get tutLeaveDayCountBody =>
      'عدّاد مباشر لمدة غيابك حسب التواريخ المختارة. يعرض الساعات بدل الأيام عند طلب ساعات جزئية.';

  @override
  String get tutLeaveTypeTitle => 'نوع الإجازة';

  @override
  String get tutLeaveTypeBody =>
      'اختر النوع المناسب لحالتك. الخيار الباهت يعني أنّ شرطه غير محقّق لتواريخك أو ساعاتك أو رصيدك الحالي.\n\n• سنوية — إجازة مخطّطة. تتطلّب رصيدًا متاحًا أو مرحّلًا، وتخضع لحدّك السنوي وإن كان لديك رصيد أوفرتايم فاستخدم التعويضية أولًا.\n\n• طارئة — للحالات المفاجئة في نفس اليوم. محدودة بيوم واحد وتتطلّب رصيدًا سنويًا/مرحّلًا متاحًا.\n\n• تعويضية — تُخصم من رصيد الأوفرتايم. متاحة فقط عندما يغطّي ذلك الرصيد الأيام المطلوبة.\n\n• مرضية — للمرض. تتطلّب رفع تقرير طبي.\n\n• بدون أجر — إجازة دون راتب. متاحة فقط عندما يكون رصيدك المدفوع ضئيلًا أو منعدمًا.';

  @override
  String get tutLeaveSubmitTitle => 'الإرسال';

  @override
  String get tutLeaveSubmitBody =>
      'يرسل طلبك للاعتماد. يبقى الزر رماديًا ومعطّلًا حتى تكتمل جميع الحقول بشكل صحيح ثم يتحوّل إلى الأزرق. وتظهر أي مشكلة مانعة (مثل طلب طارئ أطول من المسموح) أعلى هذا الزر مباشرة.';

  @override
  String get tutHelpTooltip => 'جولة إرشادية';

  @override
  String get tutNext => 'التالي';

  @override
  String get tutSkip => 'تخطّي الجولة';

  @override
  String get tutWatchHow => 'شاهد الطريقة';

  @override
  String get tutHelpCenterTitle => 'مساعدة الجدول';

  @override
  String get tutStartTour => 'بدء الجولة الإرشادية';

  @override
  String get tutBrowseClips => 'مقاطع توضيحية';

  @override
  String get tutClipComingSoon => 'هذا المقطع قيد الإعداد.';

  @override
  String get tutSchViewModeTitle => 'عرض الفريق أو الزملاء';

  @override
  String get tutSchViewModeBody =>
      'بدّل بين عرض الفريق — جدول كل من يتبعك إدارياً — وعرض الزملاء، حيث تُعدّ مسودّة ورديّاتك الخاصة إلى جانب زملائك.';

  @override
  String get tutSchTabsTitle => 'طرق عرض الجدول';

  @override
  String get tutSchTabsBody =>
      'اطّلع على الأسبوع نفسه بأربع طرق: الشبكة الأسبوعية، الخط الزمني اليومي، التقويم الشهري، وجدولي لورديّاتك الخاصة.';

  @override
  String get tutSchFiltersTitle => 'التنقّل والتصفية';

  @override
  String get tutSchFiltersBody =>
      'استخدم زر اليوم والأسهم للتنقّل بين الأسابيع، ثم صفِّ الفريق حسب القسم أو الموقع أو نطاق التبعية (مباشر، غير مباشر، أو كلاهما).';

  @override
  String get tutSchCopyTitle => 'نسخ الأسبوع الماضي';

  @override
  String get tutSchCopyBody =>
      'أعد استخدام خطة الأسبوع الماضي بخطوة واحدة — تُنسخ الورديّات إلى الأيام الفارغة في الأسبوع الحالي مع تجاوز الأيام الممتلئة.';

  @override
  String get tutSchPublishTitle => 'نشر الأسبوع';

  @override
  String get tutSchPublishBody =>
      'حوّل مسوّداتك إلى الجدول الرسمي. عند اكتمال كل الخلايا يتحوّل الزر إلى الأزرق، والنشر يُخطر الموظفين المعنيين. يبقى الزر معطّلاً ما دامت هناك خلايا فارغة.';

  @override
  String get tutSchKpiTitle => 'لمحة عن الأسبوع';

  @override
  String get tutSchKpiBody =>
      'إجماليات مباشرة للفريق الظاهر: عدد المجدولين، ورديّات الأسبوع، التعارضات، المسودّات غير المنشورة، وعدد من هم في إجازة معتمدة.';

  @override
  String get tutSchLegendTitle => 'دليل الألوان';

  @override
  String get tutSchLegendBody =>
      'معاني ألوان الخلايا — ورديّات الصباح والظهيرة والليل والمبيت، إضافةً إلى الإجازة ويوم الراحة، وعلامات المسودّات والتعارضات.';

  @override
  String get tutSchAssignTitle => 'إسناد وردية';

  @override
  String get tutSchAssignBody =>
      'انقر أي خلية فارغة لفتح محرّر الورديّة وتحديد الأوقات، أو انقر وردية موجودة لتعديلها. تُحدَّد التعارضات (فترات الراحة، تداخل الإجازات) تلقائياً.';

  @override
  String get tutSchMultiSelectTitle => 'تحديد عدة خلايا';

  @override
  String get tutSchMultiSelectBody =>
      'تحتاج الوردية نفسها لعدة أشخاص أو أيام؟ اسحب عبر الشبكة — أو اضغط مطوّلاً ثم انقر — لتحديد عدة خلايا، ثم أسندها دفعةً واحدة من الشريط الذي يظهر.';

  @override
  String get tutSchTemplateTitle => 'قوالب قابلة لإعادة الاستخدام';

  @override
  String get tutSchTemplateBody =>
      'في محرّر الورديّة، فعّل خيار «حفظ كقالب» وأعطه اسماً لتخزين وردية تستخدمها كثيراً. في المرة القادمة تظهر كبطاقة يمكنك تطبيقها بنقرة واحدة.';

  @override
  String get tutSchSwapTitle => 'التبديلات والتعارضات والإجازات';

  @override
  String get tutSchSwapBody =>
      'تجمع اللوحة الجانبية طلبات التبديل للموافقة أو الرفض، وتعارضات الجدولة لحلّها، وإجازات فريقك المعتمدة — كلّها في مكان واحد.';

  @override
  String get tutTeamTour => 'جولة عرض الفريق';

  @override
  String get tutColleaguesTour => 'جولة عرض الزملاء';

  @override
  String get tutSchWeekNavTitle => 'التنقّل بين الأسابيع';

  @override
  String get tutSchWeekNavBody =>
      'استخدم زر اليوم والأسهم للتنقّل بين الأسابيع. تعرض تسمية الأسبوع الأسبوع الذي تشاهده حالياً.';

  @override
  String get tutSchSelfActionsTitle => 'إجراءات مسودّتك';

  @override
  String get tutSchSelfActionsBody =>
      'في عرض الزملاء تُعدّ صفّك الخاص. يملأ «نسخ الأسبوع الماضي» أيامك الفارغة من الأسبوع الماضي، ويذكّرك التنبيه الكهرماني بأن مديرك ينشر جدولك النهائي.';

  @override
  String get tutSchSelfDraftTitle => 'إعداد ورديّاتك الخاصة';

  @override
  String get tutSchSelfDraftBody =>
      'انقر يوماً فارغاً في صفّك لاقتراح وردية، أو انقر مسودّتك لتعديلها. الأيام التي حجزها مديرك تظهر بقفل ولا يمكن تعديلها. تبقى مسوّداتك معلّقة حتى ينشرها مديرك.';

  @override
  String get tutSchRequestSwapTitle => 'طلب تبديل';

  @override
  String get tutSchRequestSwapBody =>
      'انقر وردية زميل لطلب تبديل معه. يمكنك التبديل فقط للورديّات المستقبلية، وليس عندما يكون أحدكما في إجازة أو لديه طلب مفتوح لذلك اليوم.';

  @override
  String get tutSchPinnedRowTitle => 'صف مقارنة المدير';

  @override
  String get tutSchPinnedRowBody =>
      'يعرض هذا الصف المثبّت جدول مديرك للمرجعية (للقراءة فقط، بعلامة «المدير») حتى توائم ورديّاتك مع ورديّاته.';

  @override
  String get tutSchMobileWeekNavTitle => 'اختر أسبوعاً';

  @override
  String get tutSchMobileWeekNavBody =>
      'انقر الأسهم للتنقّل بين الأسابيع؛ تعرض التسمية في المنتصف الأسبوع الذي تشاهده.';

  @override
  String get tutSchMobileStatsTitle => 'لمحة عن الأسبوع';

  @override
  String get tutSchMobileStatsBody =>
      'إجماليات سريعة للأسبوع: يظهر عدد المجدولين والورديّات دائماً؛ وفي عرض الفريق ترى أيضاً التعارضات والمسودّات غير المنشورة.';

  @override
  String get tutSchMobileDayPickerTitle => 'اختر يوماً';

  @override
  String get tutSchMobileDayPickerBody =>
      'انقر يوماً لتركيز القائمة أدناه على ورديّات ذلك اليوم. اسحب الشريط جانبياً للوصول إلى الأسبوع كاملاً.';

  @override
  String get tutSchMobileBulkTitle => 'إسناد جماعي للورديّات';

  @override
  String get tutSchMobileBulkBody =>
      'انقر «إسناد ورديّات…» لفتح الورقة الجماعية ومنح الوردية نفسها لعدة أشخاص عبر عدة أيام دفعةً واحدة — ترشدك عبر الوردية (قالب أو أوقات مخصّصة)، ثم الأيام، ثم من تنطبق عليهم. ورابط «املأ هذا اليوم» أعلى القائمة يفعل الشيء نفسه لليوم المعروض فقط.';

  @override
  String get tutSchMobileTabsTitle => 'طرق عرض الجدول';

  @override
  String get tutSchMobileTabsBody =>
      'اسحب شريط التبويبات للتنقّل بين العروض: الأسبوعي (القائمة اليومية أدناه)، والشهري لنظرة عامة على الشهر، و«على وردية الآن» لمن يعمل حالياً، و«جدولي» لورديّاتك، و«التبديلات» — تعرض شارته عدد الطلبات التي تنتظرك. ويحصل المديرون أيضاً على تبويب «المزيد» للنشر والنسخ.';

  @override
  String get tutSchMobileFiltersTitle => 'تصفية الفريق';

  @override
  String get tutSchMobileFiltersBody =>
      'انقر هذه البطاقة لفتح ورقة التصفية، ثم ضيّق القائمة حسب القسم أو الموقع أو نطاق التبعية. لا يتغيّر شيء حتى تنقر «تطبيق»، و«إعادة تعيين» تمسح كل شيء. وتعرض البطاقة نفسها ما هو مُطبَّق حالياً.';

  @override
  String get tutSchMobileSelfBarTitle => 'إجراءات ورديّاتك';

  @override
  String get tutSchMobileSelfBarBody =>
      '«نسخ الأسبوع الماضي» يملأ أيامك الفارغة من الأسبوع الماضي، و«إسناد ورديّات…» يفتح ورقة مقصورة على صفّك لتعدّ مسودّة عدة أيام دفعةً واحدة. تبقى مسوّداتك معلّقة حتى ينشرها مديرك.';

  @override
  String get tutSchMobileSwapsTitle => 'الموافقة على طلبات التبديل';

  @override
  String get tutSchMobileSwapsBody =>
      'تصل طلبات التبديل من فريقك هنا ضمن «بانتظار إجراء». تعرض كل بطاقة الورديتين جنباً إلى جنب لتقارنهما، ثم توافق أو ترفض. وتخبرك شارة التبويب بعدد الطلبات المنتظرة.';

  @override
  String get tutSchMobileSwapsPeerTitle => 'تبديلاتك';

  @override
  String get tutSchMobileSwapsPeerBody =>
      'كل ما يخصّ تبديلاتك في تبويب واحد: الطلبات التي أرسلها إليك الزملاء (اقبلها أو ارفضها)، وتلك التي أرسلتها (ويمكنك إلغاؤها)، وسجلّ تبديلاتك السابق. ولبدء تبديل جديد، انقر وردية زميل في العرض الأسبوعي أو استخدم «تبديل مع» في «جدولي».';

  @override
  String get tutSchMobileMoreTitle => 'النشر والنسخ';

  @override
  String get tutSchMobileMoreBody =>
      'إجراءات المدير موجودة هنا. «نشر الأسبوع» يحوّل مسوّداتك إلى الجدول الرسمي ويُخطر جميع المعنيين — ويبقى معطّلاً حتى تُملأ كل الخلايا. و«نسخ الأسبوع الماضي» يعيد استخدام خطة الأسبوع الماضي للأيام الفارغة.';

  @override
  String get tutSchKpiColleaguesBody =>
      'إجماليات الأسبوع المعروض: عدد الأشخاص المجدولين وإجمالي عدد الورديّات.';

  @override
  String get tutSchLegendColleaguesBody =>
      'معاني الألوان — ورديّات الصباح والظهيرة والليل والمبيت، إضافةً إلى الإجازة ويوم الراحة.';

  @override
  String get tutTopicsTeam => 'إدارة فريقك';

  @override
  String get tutTopicsColleagues => 'جدولك الخاص';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get statsOverview => 'نظرة عامة';

  @override
  String get statsApprovalFunnel => 'مسار الاعتماد';

  @override
  String get statsLeaveAttendance => 'الإجازات والحضور';

  @override
  String get statsFinancial => 'المالية';

  @override
  String get statsDisciplinary => 'الإجراءات التأديبية';

  @override
  String get statsWorkforce => 'القوى العاملة';

  @override
  String get statsTotalRequests => 'إجمالي الطلبات';

  @override
  String get statsPendingApproval => 'بانتظار الاعتماد';

  @override
  String get statsAvgApprovalTime => 'متوسط زمن الاعتماد';

  @override
  String get statsApprovalRate => 'نسبة الاعتماد';

  @override
  String get statsVolumeByType => 'حجم الطلبات حسب النوع';

  @override
  String get statsStatusDistribution => 'توزيع الحالات';

  @override
  String get statsRequestsByDepartment => 'الطلبات حسب الإدارة';

  @override
  String get statsAvgTimePerStage => 'متوسط الزمن لكل مرحلة';

  @override
  String get statsPendingByApprover => 'المعلّقة حسب المعتمد والنوع';

  @override
  String get statsOldestPending => 'أقدم الطلبات المعلّقة';

  @override
  String get statsLeaveTypeMix => 'توزيع أنواع الإجازات';

  @override
  String get statsLeaveSeasonality => 'أيام الإجازات (الموسمية)';

  @override
  String get statsLeaveBalanceByDept => 'رصيد الإجازات حسب الإدارة';

  @override
  String get statsAdvancesDisbursed => 'السلف المصروفة';

  @override
  String get statsTotalAdvances => 'إجمالي السلف';

  @override
  String get statsSettlementRate => 'نسبة التسوية';

  @override
  String get statsAvgAdvance => 'متوسط السلفة';

  @override
  String get statsApprovedAmount => 'المبلغ المعتمد';

  @override
  String get statsViolationCategories => 'فئات المخالفات';

  @override
  String get statsActionTypes => 'أنواع الإجراءات';

  @override
  String get statsOutcomes => 'النتائج';

  @override
  String get statsEscalatedToLegal => 'محوّلة للقانونية';

  @override
  String get statsSuspensions => 'الإيقافات';

  @override
  String get statsTerminations => 'إنهاء الخدمة';

  @override
  String get statsTotalCases => 'إجمالي الحالات';

  @override
  String get statsHeadcountByDepartment => 'التعداد حسب الإدارة';

  @override
  String get statsHeadcountByLocation => 'التعداد حسب الموقع';

  @override
  String get statsTenureDistribution => 'توزيع مدة الخدمة';

  @override
  String get statsAllDepartments => 'كل الإدارات';

  @override
  String get statsAllLocations => 'كل المواقع';

  @override
  String get statsAllTypes => 'كل الأنواع';

  @override
  String get statsThisMonth => 'هذا الشهر';

  @override
  String get statsLast3Months => 'آخر 3 أشهر';

  @override
  String get statsThisYear => 'هذه السنة';

  @override
  String get statsLast12Months => 'آخر 12 شهرًا';

  @override
  String get statsNoData => 'لا توجد بيانات لهذه الفترة';

  @override
  String get statsNothingPending => 'لا توجد طلبات معلّقة';

  @override
  String get statsRetry => 'إعادة المحاولة';

  @override
  String get statsApproverN1 => 'N+1';

  @override
  String get statsApproverN2 => 'N+2';

  @override
  String get statsApproverHr => 'الموارد البشرية';

  @override
  String get statsApproverFinance => 'المالية';

  @override
  String get statsApproverLegal => 'الشئون القانونية';

  @override
  String get statsApproverEmployee => 'الموظف';

  @override
  String get statsApproverNone => '—';

  @override
  String get statsStageSubmitted => 'مُقدَّم';

  @override
  String get statsStageFinalized => 'مكتمل';

  @override
  String get statsTenureUnder1 => 'أقل من سنة';

  @override
  String get statsTenure1to2 => '1-2 سنة';

  @override
  String get statsTenure2to4 => '2-4 سنوات';

  @override
  String get statsTenure4plus => '4+ سنوات';

  @override
  String get statsUnknown => 'غير معروف';

  @override
  String get statsPendingAt => 'لدى';

  @override
  String get statsAge => 'المدة';

  @override
  String get statsLeaveCancellation => 'إلغاء إجازة';

  @override
  String get statsBusinesstripCancellation => 'إلغاء مأمورية';

  @override
  String get statsTakenVsBalanceByDept =>
      'الإجازات المستهلكة مقابل الرصيد المتاح حسب الإدارة (متوسط أيام/موظف)';

  @override
  String get statsTakenThisYear => 'المستهلك هذا العام';

  @override
  String get statsAvailableBalance => 'الرصيد المتاح';

  @override
  String get statsHeadcount => 'التعداد';

  @override
  String get statsAccessDenied => 'ليس لديك صلاحية الوصول إلى الإحصائيات.';
}
