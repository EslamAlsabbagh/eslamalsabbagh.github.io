// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نظام الإدارة القانونية';

  @override
  String get statusTodo => 'لم تبدأ';

  @override
  String get statusDoing => 'جارية';

  @override
  String get statusWaiting => 'بانتظار رد';

  @override
  String get statusDone => 'مكتملة';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginEmailLabel => 'البريد الإلكتروني';

  @override
  String get loginPasswordLabel => 'كلمة المرور';

  @override
  String get loginErrorInvalidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا.';

  @override
  String get loginSubmit => 'دخول';

  @override
  String get loginShowPassword => 'إظهار كلمة المرور';

  @override
  String get loginHidePassword => 'إخفاء كلمة المرور';

  @override
  String get loginForgotHelp => 'نسيت كلمة المرور؟ تواصل مع مسؤول النظام.';

  @override
  String get loginErrorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get loginErrorRateLimited => 'محاولات كثيرة. حاول مرة أخرى بعد قليل.';

  @override
  String get loginErrorNetwork =>
      'تعذّر الاتصال بالخادم. تحقق من الشبكة وحاول مرة أخرى.';

  @override
  String get loginErrorUnknown => 'حدث خطأ غير متوقع. حاول مرة أخرى.';

  @override
  String get authAccountDisabled => 'هذا الحساب معطّل. تواصل مع مسؤول النظام.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get statusCancelled => 'ملغاة';

  @override
  String get counterUrgent => 'عاجلة';

  @override
  String get counterOverdue => 'متأخرة';

  @override
  String get counterOpen => 'مفتوحة';

  @override
  String get allFiles => 'كل الملفات';

  @override
  String get fileFilterLabel => 'تصفية حسب الملف';

  @override
  String get sectionUrgentTitle => 'عاجلة — تُنجز اليوم';

  @override
  String get sectionUrgentCaption =>
      'المتأخرة أولًا، ثم ما موعده اليوم أو عُلّم عاجلًا';

  @override
  String get sectionUpcomingTitle => 'القادمة';

  @override
  String get sectionUpcomingCaption => 'مرتبة حسب أقرب موعد تسليم';

  @override
  String get sectionClosedTitle => 'المكتملة';

  @override
  String get emptyUrgent => 'لا توجد مهام عاجلة اليوم';

  @override
  String get emptyUpcoming => 'لا توجد مهام قادمة';

  @override
  String showClosed(String count) {
    return 'عرض المكتملة ($count)';
  }

  @override
  String hideClosed(String count) {
    return 'إخفاء المكتملة ($count)';
  }

  @override
  String get flagOverdue => 'متأخرة';

  @override
  String get flagUrgent => 'عاجلة';

  @override
  String get dueToday => 'اليوم';

  @override
  String get dueTomorrow => 'غدًا';

  @override
  String dueOverdueSince(String days) {
    return 'متأخرة منذ $days';
  }

  @override
  String dueIn(String days) {
    return 'بعد $days';
  }

  @override
  String get dayOne => 'يوم';

  @override
  String get dayTwo => 'يومين';

  @override
  String daysFew(String count) {
    return '$count أيام';
  }

  @override
  String daysMany(String count) {
    return '$count يومًا';
  }

  @override
  String updatesCount(String count) {
    return 'عدد التحديثات: $count';
  }

  @override
  String get formerEmployee => 'موظف سابق';

  @override
  String get tasksLoadError => 'تعذّر تحميل المهام.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get drawerClose => 'إغلاق';

  @override
  String get drawerStatusLabel => 'الحالة';

  @override
  String get drawerAssigneeLabel => 'الموظف المسؤول';

  @override
  String get drawerDueLabel => 'موعد التسليم';

  @override
  String get drawerContractLabel => 'العقد';

  @override
  String get drawerPickDue => 'اختيار موعد التسليم';

  @override
  String get drawerManualUrgent => 'تعليم كعاجلة يدويًا';

  @override
  String get urgentNoteDone => 'المهمة مكتملة.';

  @override
  String get urgentNoteCancelled => 'المهمة ملغاة.';

  @override
  String get urgentNoteOverdue => 'عاجلة تلقائيًا لأن موعد التسليم فات.';

  @override
  String get urgentNoteToday => 'عاجلة تلقائيًا لأن موعد التسليم اليوم.';

  @override
  String get urgentNoteManual => 'عُلّمت عاجلة يدويًا وتظهر في أعلى القائمة.';

  @override
  String get urgentNoteLater => 'ستصبح عاجلة تلقائيًا يوم موعد التسليم.';

  @override
  String get drawerDescriptionLabel => 'الوصف';

  @override
  String get drawerUpdatesLabel => 'التحديثات — إلى أين وصلنا';

  @override
  String get drawerNoUpdates => 'لا توجد تحديثات بعد';

  @override
  String get updateFieldLabel => 'أضف تحديثًا';

  @override
  String get updateHint => 'اكتب آخر ما وصلت إليه في المهمة…';

  @override
  String get updateAdd => 'إضافة تحديث';

  @override
  String get updateErrorNotAllowed =>
      'لا تملك صلاحية إضافة تحديث على هذه المهمة.';

  @override
  String get updateErrorUnknown => 'تعذّر إضافة التحديث. حاول مرة أخرى.';

  @override
  String get drawerLoadError => 'تعذّر تحميل المهمة.';

  @override
  String get saveErrorNotAllowed => 'لا تملك صلاحية تعديل هذه المهمة.';

  @override
  String get saveErrorAssignee => 'لا يمكن إسناد المهمة لهذا الموظف.';

  @override
  String get saveErrorUnknown => 'تعذّر حفظ التغيير. حاول مرة أخرى.';

  @override
  String get cancelTask => 'إلغاء المهمة';

  @override
  String get cancelTaskTitle => 'إلغاء المهمة؟';

  @override
  String get cancelTaskBody =>
      'تنتقل المهمة إلى المكتملة بحالة ملغاة، ويمكن إعادة فتحها لاحقًا.';

  @override
  String get cancelTaskBack => 'رجوع';

  @override
  String get editTask => 'تعديل';

  @override
  String get editTitleLabel => 'عنوان المهمة';

  @override
  String get editSave => 'حفظ';

  @override
  String get editCancel => 'إلغاء';

  @override
  String get discardEditTitle => 'تجاهل التعديلات؟';

  @override
  String get discardEditBody => 'لن تُحفظ التعديلات على العنوان والوصف.';

  @override
  String get discardEditBack => 'متابعة التعديل';

  @override
  String get discardEditConfirm => 'تجاهل';

  @override
  String get discardUpdateTitle => 'تجاهل التحديث؟';

  @override
  String get discardUpdateBody => 'لن يُحفظ التحديث الذي كتبته.';

  @override
  String get discardUpdateBack => 'متابعة الكتابة';

  @override
  String get discardAllTitle => 'تجاهل ما كتبته؟';

  @override
  String get discardAllBody =>
      'لن تُحفظ التعديلات على العنوان والوصف ولا التحديث الذي كتبته.';

  @override
  String get timeNow => 'الآن';

  @override
  String timeAgo(String time) {
    return 'منذ $time';
  }

  @override
  String get timeYesterday => 'أمس';

  @override
  String get minuteOne => 'دقيقة';

  @override
  String get minuteTwo => 'دقيقتين';

  @override
  String minutesFew(String count) {
    return '$count دقائق';
  }

  @override
  String minutesMany(String count) {
    return '$count دقيقة';
  }

  @override
  String get hourOne => 'ساعة';

  @override
  String get hourTwo => 'ساعتين';

  @override
  String hoursFew(String count) {
    return '$count ساعات';
  }

  @override
  String hoursMany(String count) {
    return '$count ساعة';
  }

  @override
  String get searchHint => 'ابحث في المهام…';

  @override
  String get searchLabel => 'البحث في المهام';

  @override
  String get searchClear => 'مسح البحث';

  @override
  String searchResultOne(String term) {
    return 'نتيجة واحدة لـ \"$term\"';
  }

  @override
  String searchResultTwo(String term) {
    return 'نتيجتان لـ \"$term\"';
  }

  @override
  String searchResultsFew(String count, String term) {
    return '$count نتائج لـ \"$term\"';
  }

  @override
  String searchResultsMany(String count, String term) {
    return '$count نتيجة لـ \"$term\"';
  }

  @override
  String searchNoResults(String term) {
    return 'لا توجد مهام تطابق \"$term\"';
  }

  @override
  String get searchError => 'تعذّر البحث. حاول مرة أخرى.';

  @override
  String get viewTabsLabel => 'طريقة العرض';

  @override
  String get tabTasks => 'المهام والأولوية';

  @override
  String get tabTopics => 'المواضيع';

  @override
  String get tabPeople => 'الموظفون';

  @override
  String get topicBrandLabel => 'عقد براند';

  @override
  String get topicCountZero => 'لا مواضيع';

  @override
  String get topicCountOne => 'موضوع واحد';

  @override
  String get topicCountTwo => 'موضوعان';

  @override
  String topicCountFew(String count) {
    return '$count مواضيع';
  }

  @override
  String topicCountMany(String count) {
    return '$count موضوعًا';
  }

  @override
  String get openTaskCountZero => 'لا مهام مفتوحة';

  @override
  String get openTaskCountOne => 'مهمة مفتوحة واحدة';

  @override
  String get openTaskCountTwo => 'مهمتان مفتوحتان';

  @override
  String openTaskCountFew(String count) {
    return '$count مهام مفتوحة';
  }

  @override
  String openTaskCountMany(String count) {
    return '$count مهمة مفتوحة';
  }

  @override
  String urgentCountLabel(String count) {
    return '$count عاجلة';
  }

  @override
  String topicProgress(String done, String total) {
    return 'مكتملة: $done من $total';
  }

  @override
  String get topicNoTasks => 'لا مهام بعد';

  @override
  String get topicNoOpenTasks => 'لا توجد مهام مفتوحة';

  @override
  String get fileNoTopics => 'لا توجد مواضيع في هذا الملف';

  @override
  String get peopleEmptyFile => 'لا يوجد موظفون في هذا الملف';

  @override
  String get peopleEmpty => 'لا يوجد موظفون بعد';

  @override
  String get newFileButton => 'ملف جديد';

  @override
  String get editName => 'تعديل';

  @override
  String editFileSemantics(String name) {
    return 'تعديل اسم الملف $name';
  }

  @override
  String get editTopicTooltip => 'تعديل اسم الموضوع';

  @override
  String editTopicSemantics(String name) {
    return 'تعديل اسم الموضوع $name';
  }

  @override
  String get newTopicCard => 'موضوع جديد';

  @override
  String newTopicSemantics(String file) {
    return 'إضافة موضوع إلى $file';
  }

  @override
  String get nameModalNewFile => 'ملف جديد';

  @override
  String get nameModalRenameFile => 'تعديل اسم الملف';

  @override
  String get nameModalNewTopic => 'موضوع جديد';

  @override
  String get nameModalRenameTopic => 'تعديل اسم الموضوع';

  @override
  String nameModalFileLine(String file) {
    return 'الملف: $file';
  }

  @override
  String get fileNameLabel => 'اسم الملف';

  @override
  String get topicNameLabel => 'اسم الموضوع (البراند)';

  @override
  String get fileNameHint => 'مثال: سيتي سنتر';

  @override
  String get topicNameHint => 'مثال: كافيه ليمونة';

  @override
  String get nameErrorDuplicateFile => 'يوجد ملف بهذا الاسم.';

  @override
  String get nameErrorDuplicateTopic => 'يوجد موضوع بهذا الاسم في هذا الملف.';

  @override
  String get nameErrorNotAllowed => 'لا تملك صلاحية تعديل الملفات والمواضيع.';

  @override
  String get nameErrorUnknown => 'تعذّر الحفظ. حاول مرة أخرى.';

  @override
  String get deleteFile => 'حذف الملف';

  @override
  String get deleteTopic => 'حذف الموضوع';

  @override
  String deleteFileSemantics(String name) {
    return 'حذف الملف $name';
  }

  @override
  String deleteTopicSemantics(String name) {
    return 'حذف الموضوع $name';
  }

  @override
  String deleteFileTitle(String name) {
    return 'حذف الملف $name؟';
  }

  @override
  String deleteTopicTitle(String name) {
    return 'حذف الموضوع $name؟';
  }

  @override
  String get deleteNameBody => 'يُحذف نهائيًا، ولا يمكن التراجع عن ذلك.';

  @override
  String get deleteNameConfirm => 'حذف';

  @override
  String get nameErrorFileNotEmpty =>
      'أُضيفت مواضيع إلى هذا الملف، فلم يعد حذفه ممكنًا.';

  @override
  String get nameErrorTopicNotEmpty =>
      'أُضيفت مهام إلى هذا الموضوع، فلم يعد حذفه ممكنًا.';

  @override
  String get headerUsers => 'المستخدمون';

  @override
  String get usersTitle => 'المستخدمون';

  @override
  String get usersBack => 'رجوع';

  @override
  String get usersNew => 'مستخدم جديد';

  @override
  String get usersLoadFailed => 'تعذّر تحميل المستخدمين.';

  @override
  String get roleLawyer => 'محامٍ';

  @override
  String get roleManager => 'مدير';

  @override
  String get roleAdmin => 'مسؤول النظام';

  @override
  String get userInactive => 'معطّل';

  @override
  String get userFileCountZero => 'لا ملفات';

  @override
  String get userFileCountOne => 'ملف واحد';

  @override
  String get userFileCountTwo => 'ملفان';

  @override
  String userFileCountFew(String count) {
    return '$count ملفات';
  }

  @override
  String userFileCountMany(String count) {
    return '$count ملفًا';
  }

  @override
  String get userModalNew => 'مستخدم جديد';

  @override
  String get userModalEdit => 'تعديل المستخدم';

  @override
  String get userNameLabel => 'الاسم';

  @override
  String get userNameHint => 'مثال: نور حسن';

  @override
  String get userPasswordHint => '٨ أحرف على الأقل';

  @override
  String get userRoleLabel => 'الدور';

  @override
  String get userFilesLabel => 'الملفات';

  @override
  String get userFilesAll => 'المدير ومسؤول النظام يريان كل الملفات.';

  @override
  String get userFilesNone => 'لا توجد ملفات بعد.';

  @override
  String get userSelfNote => 'لا يمكنك تغيير دورك أو تعطيل حسابك.';

  @override
  String get userAccountLabel => 'الحساب';

  @override
  String get userSetPassword => 'تعيين كلمة مرور جديدة';

  @override
  String get userPasswordSet => 'تم تعيين كلمة المرور الجديدة.';

  @override
  String get userDeactivate => 'تعطيل الحساب';

  @override
  String get userReactivate => 'إعادة تفعيل الحساب';

  @override
  String get userIsInactive => 'هذا الحساب معطّل ولا يمكنه تسجيل الدخول.';

  @override
  String userDeactivateTitle(String name) {
    return 'تعطيل حساب $name؟';
  }

  @override
  String get userDeactivateBody =>
      'لن يتمكن هذا المستخدم من تسجيل الدخول حتى يُعاد تفعيل الحساب. تبقى المهام والتحديثات كما هي.';

  @override
  String get userDiscardBody => 'لن تُحفظ التعديلات على هذا المستخدم.';

  @override
  String get passwordModalTitle => 'كلمة مرور جديدة';

  @override
  String passwordModalUserLine(String name) {
    return 'المستخدم: $name';
  }

  @override
  String get passwordModalLabel => 'كلمة المرور الجديدة';

  @override
  String get userErrorNotAllowed => 'لا تملك صلاحية إدارة المستخدمين.';

  @override
  String get userErrorOpenTasks =>
      'لهذا المستخدم مهام مفتوحة. أعد إسنادها أولًا.';

  @override
  String get userErrorOpenTasksInFile =>
      'لهذا المستخدم مهام مفتوحة في ملف أُلغي تحديده. أعد إسنادها أولًا.';

  @override
  String get userErrorOpenTasksOutsideFiles =>
      'لهذا المستخدم مهام مفتوحة في ملفات غير محددة. حدّدها أو أعد إسناد المهام أولًا.';

  @override
  String get userErrorEmailTaken => 'يوجد حساب بهذا البريد الإلكتروني.';

  @override
  String get userErrorWeakPassword =>
      'كلمة المرور قصيرة. استخدم ٨ أحرف على الأقل.';

  @override
  String get newTask => 'مهمة جديدة';

  @override
  String get newTaskTitleHint => 'مثال: مراجعة ملحق العقد';

  @override
  String get newTaskFileLabel => 'الملف';

  @override
  String get newTaskTopicLabel => 'الموضوع (البراند)';

  @override
  String get newTaskAssigneeHint => 'اختر الموظف';

  @override
  String get newTaskUrgent => 'عاجلة (تُنجز اليوم)';

  @override
  String get newTaskUrgentHelp =>
      'تصبح المهمة عاجلة تلقائيًا عندما يحين موعد تسليمها.';

  @override
  String get newTaskSave => 'حفظ المهمة';

  @override
  String get newTaskDiscardBody => 'لن تُحفظ هذه المهمة.';

  @override
  String get newTaskErrorNotAllowed =>
      'لا تملك صلاحية إنشاء مهمة في هذا الملف.';

  @override
  String get newTaskErrorUnknown => 'تعذّر حفظ المهمة. حاول مرة أخرى.';

  @override
  String showActivity(String count) {
    return 'عرض سجل التغييرات ($count)';
  }

  @override
  String hideActivity(String count) {
    return 'إخفاء سجل التغييرات ($count)';
  }

  @override
  String get activitySystem => 'النظام';

  @override
  String get activityCreated => 'أنشأ المهمة';

  @override
  String activityStatus(String from, String to) {
    return 'غيّر الحالة من $from إلى $to';
  }

  @override
  String activityAssignee(String from, String to) {
    return 'غيّر المسؤول من $from إلى $to';
  }

  @override
  String activityDueDate(String from, String to) {
    return 'غيّر موعد التسليم من $from إلى $to';
  }

  @override
  String get activityUrgentOn => 'علّمها عاجلة';

  @override
  String get activityUrgentOff => 'ألغى تعليمها عاجلة';

  @override
  String get activityTitle => 'غيّر العنوان';

  @override
  String activityOldTitle(String title) {
    return 'العنوان السابق: $title';
  }

  @override
  String activityNewTitle(String title) {
    return 'العنوان الجديد: $title';
  }

  @override
  String get activityDescription => 'عدّل الوصف';

  @override
  String activityTopic(String to) {
    return 'نقل المهمة إلى موضوع $to';
  }

  @override
  String get activityOtherTopic => 'آخر';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String notificationsBellUnread(String count) {
    return 'الإشعارات: $count';
  }

  @override
  String get notificationsUnreadOne => 'إشعار واحد غير مقروء';

  @override
  String get notificationsUnreadTwo => 'إشعاران غير مقروءين';

  @override
  String notificationsUnreadFew(String count) {
    return '$count إشعارات غير مقروءة';
  }

  @override
  String notificationsUnreadMany(String count) {
    return '$count إشعارًا غير مقروء';
  }

  @override
  String notificationsBadgeMore(String count) {
    return '$count+';
  }

  @override
  String get notificationsMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات';

  @override
  String get notificationsLoadError => 'تعذّر تحميل الإشعارات.';

  @override
  String get notificationAssigned => 'أسند إليك مهمة';

  @override
  String get notificationUpdatePosted => 'أضاف تحديثًا';

  @override
  String get notificationChanged => 'عدّل المهمة';

  @override
  String get notificationTaskGone => 'لم تعد هذه المهمة متاحة';

  @override
  String get notificationUnread => 'غير مقروء';

  @override
  String get tabContracts => 'العقود';

  @override
  String get contractsSearchHint => 'ابحث في العقود…';

  @override
  String get contractsSearchLabel => 'البحث في العقود';

  @override
  String get contractFilterKindLabel => 'النوع';

  @override
  String get contractFilterStatusLabel => 'الحالة';

  @override
  String get contractFilterSeasonLabel => 'الموسم';

  @override
  String get contractKindAll => 'كل الأنواع';

  @override
  String get contractKindUnits => 'وحدات';

  @override
  String get contractKindStorage => 'مخازن';

  @override
  String get contractKindServicesOther => 'خدمات وأخرى';

  @override
  String get contractStatusAll => 'كل الحالات';

  @override
  String get contractStatusInForce => 'سارية';

  @override
  String get contractStatusEnding => 'تنتهي خلال ٩٠ يومًا';

  @override
  String get contractStatusExpired => 'منتهية';

  @override
  String get contractMissingOnly => 'بها نواقص';

  @override
  String get contractSeasonAll => 'كل المواسم';

  @override
  String get contractListActive => 'سارية';

  @override
  String get contractListEnding => 'تنتهي قريبًا';

  @override
  String get contractListExpired => 'منتهية';

  @override
  String get contractListTerminated => 'ملغاة';

  @override
  String get contractNoBrand => 'بدون براند';

  @override
  String contractEndsOn(String date) {
    return 'حتى $date';
  }

  @override
  String contractMoreUnits(String count) {
    return '+ $count';
  }

  @override
  String get annexCountOne => 'ملحق';

  @override
  String get annexCountTwo => 'ملحقان';

  @override
  String annexCountFew(String count) {
    return '$count ملاحق';
  }

  @override
  String annexCountMany(String count) {
    return '$count ملحقًا';
  }

  @override
  String get storageCountOne => 'مخزن';

  @override
  String get storageCountTwo => 'مخزنان';

  @override
  String storageCountFew(String count) {
    return '$count مخازن';
  }

  @override
  String storageCountMany(String count) {
    return '$count مخزنًا';
  }

  @override
  String get followUpCountOne => 'متابعة';

  @override
  String get followUpCountTwo => 'متابعتان';

  @override
  String followUpCountFew(String count) {
    return '$count متابعات';
  }

  @override
  String followUpCountMany(String count) {
    return '$count متابعة';
  }

  @override
  String get missingCountOne => 'نقص';

  @override
  String get missingCountTwo => 'نقصان';

  @override
  String missingCountFew(String count) {
    return '$count نواقص';
  }

  @override
  String missingCountMany(String count) {
    return '$count نقصًا';
  }

  @override
  String get contractCountOne => 'عقد واحد';

  @override
  String get contractCountTwo => 'عقدان';

  @override
  String contractCountFew(String count) {
    return '$count عقود';
  }

  @override
  String contractCountMany(String count) {
    return '$count عقدًا';
  }

  @override
  String contractsEndingLabel(String count) {
    return '$count تنتهي خلال ٩٠ يومًا';
  }

  @override
  String contractsMissingLabel(String count) {
    return '$count بها نواقص';
  }

  @override
  String showTerminated(String count) {
    return 'عرض الملغاة ($count)';
  }

  @override
  String hideTerminated(String count) {
    return 'إخفاء الملغاة ($count)';
  }

  @override
  String get contractsEmptyFile => 'لا توجد عقود في هذا الملف';

  @override
  String get contractsEmpty => 'لا توجد عقود بعد';

  @override
  String get contractsNoFilterMatches => 'لا توجد عقود تطابق هذه الاختيارات';

  @override
  String get contractsClearFilters => 'مسح الاختيارات';

  @override
  String contractsNoSearchMatches(String term) {
    return 'لا توجد عقود تطابق \"$term\"';
  }

  @override
  String get contractsLoadError => 'تعذّر تحميل العقود.';

  @override
  String suggestAdd(String text) {
    return '+ إضافة \"$text\"';
  }

  @override
  String suggestAddUnits(String count, String codes) {
    return '+ إضافة $count: $codes';
  }

  @override
  String get suggestPickOrAdd => 'اختر من القائمة أو أضف جديدًا';

  @override
  String get suggestCountOne => 'اقتراح واحد';

  @override
  String get suggestCountTwo => 'اقتراحان';

  @override
  String suggestCountFew(String count) {
    return '$count اقتراحات';
  }

  @override
  String suggestCountMany(String count) {
    return '$count اقتراحًا';
  }

  @override
  String suggestRemove(String value) {
    return 'إزالة $value';
  }

  @override
  String get suggestAddFailed => 'تعذّرت الإضافة. حاول مرة أخرى.';

  @override
  String get suggestAddNotAllowed => 'لا تملك صلاحية الإضافة في هذا الملف.';

  @override
  String get similarPartyTitle => 'يوجد مستأجر مشابه';

  @override
  String get similarUnitTitle => 'توجد وحدة مشابهة';

  @override
  String get similarUse => 'استخدام هذا';

  @override
  String get similarAddAnyway => 'إضافة جديد على أي حال';

  @override
  String get partyDuplicate => 'يوجد مستأجر بهذا الاسم.';

  @override
  String get unitDuplicate => 'توجد وحدة بهذا الرقم في هذا الملف.';

  @override
  String get unitCountOne => 'وحدة واحدة';

  @override
  String get unitCountTwo => 'وحدتان';

  @override
  String unitCountFew(String count) {
    return '$count وحدات';
  }

  @override
  String unitCountMany(String count) {
    return '$count وحدة';
  }

  @override
  String get unitVacant => 'شاغرة';

  @override
  String unitKeyHint(String number) {
    return 'مفتاح $number';
  }

  @override
  String get unitKindShop => 'محل';

  @override
  String get unitKindKiosk => 'كشك';

  @override
  String get unitKindStorage => 'مخزن';

  @override
  String get unitKindSpace => 'مساحة';

  @override
  String get unitKindSite => 'موقع';

  @override
  String get unitNewLabel => 'وحدة جديدة';

  @override
  String get unitKindLabel => 'نوع الوحدة';

  @override
  String get unitKeyNumberLabel => 'رقم المفتاح';

  @override
  String get unitAdd => 'إضافة';

  @override
  String get contractNew => 'عقد جديد';

  @override
  String get contractEditTitle => 'تعديل العقد';

  @override
  String get contractKindLabel => 'نوع العقد';

  @override
  String get contractFormKindLease => 'إيجار وحدة / مساحة';

  @override
  String get contractFormKindStorage => 'مخزن';

  @override
  String get contractFormKindService => 'خدمات';

  @override
  String get contractFormKindOther => 'أخرى';

  @override
  String get contractSubjectLease => 'عقد ايجار وحدة';

  @override
  String get contractSubjectStorage => 'عقد ايجار مخزن';

  @override
  String get contractFieldBrand => 'البراند';

  @override
  String get contractFieldParty => 'المستأجر';

  @override
  String get contractFieldUnits => 'الوحدات';

  @override
  String get contractFieldSubject => 'موضوع العقد';

  @override
  String get contractFieldActivity => 'النشاط';

  @override
  String get contractFieldSigned => 'تاريخ العقد';

  @override
  String get contractFieldStarts => 'تاريخ البداية';

  @override
  String get contractFieldEnds => 'تاريخ النهاية';

  @override
  String get contractFieldAreaInner => 'المساحة الداخلية';

  @override
  String get contractFieldAreaOuter => 'المساحة الخارجية';

  @override
  String get contractFieldArea => 'المساحة';

  @override
  String get contractFieldNotes => 'ملاحظات';

  @override
  String get contractFieldLinked => 'مرتبط بعقد';

  @override
  String get contractFieldDuration => 'المدة';

  @override
  String get contractFieldTerminated => 'تاريخ الإنهاء';

  @override
  String get contractFieldReason => 'سبب الإنهاء';

  @override
  String get contractLinkedHint => 'اختياري';

  @override
  String get contractStartsHint => 'مثل تاريخ العقد';

  @override
  String get contractPickDate => 'اختر التاريخ';

  @override
  String contractClearDate(String field) {
    return 'مسح $field';
  }

  @override
  String get contractNoEndDate => 'لا يوجد تاريخ نهاية محدد';

  @override
  String get contractUseEndDate => 'إدخال تاريخ النهاية';

  @override
  String get contractAreaAsText => 'المساحة لا تُكتب كرقم';

  @override
  String get contractAreaAsNumber => 'إدخال المساحة كرقم';

  @override
  String get contractDateNoteHint => 'مثل: نهاية موسم صيف 2028';

  @override
  String get contractAreaNoteHint => 'مثل: السنة الأولى 165 / الثانية 331';

  @override
  String get contractAreaUnit => 'م²';

  @override
  String get contractAreaInvalid => 'اكتب رقمًا، مثل 35,3';

  @override
  String get contractDatesOrder => 'تاريخ النهاية قبل تاريخ البداية.';

  @override
  String get contractSave => 'حفظ العقد';

  @override
  String get contractDiscardBody => 'لن يُحفظ هذا العقد.';

  @override
  String get contractDiscardEditBody => 'لن تُحفظ التعديلات على العقد.';

  @override
  String get contractSaveNotAllowed => 'لا تملك صلاحية حفظ عقد في هذا الملف.';

  @override
  String get contractSaveRejected =>
      'رفض الخادم هذه القيم. تحقق من البراند والوحدات والتواريخ.';

  @override
  String get contractSaveUnknown => 'تعذّر حفظ العقد. حاول مرة أخرى.';

  @override
  String get contractLoadError => 'تعذّر تحميل العقد.';

  @override
  String contractByAnnex(String number) {
    return '(بموجب ملحق $number)';
  }

  @override
  String get contractValueNone => '—';

  @override
  String contractArea(String area) {
    return '$area م²';
  }

  @override
  String get contractEndsToday => 'تنتهي اليوم';

  @override
  String contractEndsIn(String time) {
    return 'تنتهي بعد $time';
  }

  @override
  String contractEndedAgo(String time) {
    return 'انتهت منذ $time';
  }

  @override
  String get relDaysOne => 'يوم واحد';

  @override
  String get relDaysTwo => 'يومين';

  @override
  String relDaysFew(String count) {
    return '$count أيام';
  }

  @override
  String relDaysMany(String count) {
    return '$count يومًا';
  }

  @override
  String get relMonthsOne => 'شهر واحد';

  @override
  String get relMonthsTwo => 'شهرين';

  @override
  String relMonthsFew(String count) {
    return '$count أشهر';
  }

  @override
  String relMonthsMany(String count) {
    return '$count شهرًا';
  }

  @override
  String get relYearsOne => 'سنة واحدة';

  @override
  String get relYearsTwo => 'سنتين';

  @override
  String relYearsFew(String count) {
    return '$count سنوات';
  }

  @override
  String relYearsMany(String count) {
    return '$count سنة';
  }

  @override
  String get durYearsOne => 'سنة واحدة';

  @override
  String get durYearsTwo => 'سنتان';

  @override
  String durYearsFew(String count) {
    return '$count سنوات';
  }

  @override
  String durYearsMany(String count) {
    return '$count سنة';
  }

  @override
  String get durMonthsOne => 'شهر واحد';

  @override
  String get durMonthsTwo => 'شهران';

  @override
  String durMonthsFew(String count) {
    return '$count أشهر';
  }

  @override
  String durMonthsMany(String count) {
    return '$count شهرًا';
  }

  @override
  String durJoin(String years, String months) {
    return '$years و$months';
  }

  @override
  String get contractDelete => 'حذف العقد';

  @override
  String get contractDeleteTitle => 'حذف العقد؟';

  @override
  String get contractDeleteBody =>
      'يُحذف هذا العقد نهائيًا، ولا يمكن استرجاعه.';

  @override
  String get contractTerminate => 'إنهاء العقد';

  @override
  String get contractTerminateBody =>
      'ينتقل العقد إلى «الملغاة». يستطيع المدير إعادة تفعيله لاحقًا.';

  @override
  String get contractReasonHint => 'مثل: فسخ رضائي';

  @override
  String get contractPickTerminated => 'اختيار تاريخ الإنهاء';

  @override
  String get contractReopen => 'إعادة تفعيل';

  @override
  String get contractActionNotAllowed => 'لا تملك صلاحية تعديل هذا العقد.';

  @override
  String get contractDeleteNotEmpty =>
      'لا يمكن حذف العقد: أُضيف إليه شيء منذ فتحه.';

  @override
  String get contractNoDate => 'بدون تاريخ';

  @override
  String get contractNoArea => 'بدون مساحة';

  @override
  String get contractNoParty => 'بدون مستأجر';

  @override
  String get contractOtherParty => 'مستأجر آخر';

  @override
  String get contractHistCreated => 'أنشأ العقد';

  @override
  String contractHistAddedAnnex(String number) {
    return 'أضاف ملحق $number';
  }

  @override
  String get contractHistAddedStorage => 'أضاف عقد مخزن';

  @override
  String contractHistDeletedAnnex(String number) {
    return 'حذف ملحق $number';
  }

  @override
  String get contractHistDeletedStorage => 'حذف عقد مخزن';

  @override
  String get contractHistActivated => 'فعّل العقد';

  @override
  String contractHistTerminated(String reason) {
    return 'أنهى العقد: $reason';
  }

  @override
  String get contractHistReopened => 'أعاد تفعيل العقد';

  @override
  String contractHistParty(String from, String to) {
    return 'غيّر المستأجر من $from إلى $to';
  }

  @override
  String contractHistBrand(String from, String to) {
    return 'غيّر البراند من $from إلى $to';
  }

  @override
  String contractHistSigned(String from, String to) {
    return 'غيّر تاريخ العقد من $from إلى $to';
  }

  @override
  String contractHistStarts(String from, String to) {
    return 'غيّر تاريخ البداية من $from إلى $to';
  }

  @override
  String contractHistEnds(String from, String to) {
    return 'غيّر تاريخ النهاية من $from إلى $to';
  }

  @override
  String get contractHistDateNote => 'عدّل ملاحظة التاريخ';

  @override
  String contractHistAreaInner(String from, String to) {
    return 'غيّر المساحة الداخلية من $from إلى $to';
  }

  @override
  String contractHistAreaOuter(String from, String to) {
    return 'غيّر المساحة الخارجية من $from إلى $to';
  }

  @override
  String get contractHistAreaNote => 'عدّل ملاحظة المساحة';

  @override
  String get contractHistSubject => 'عدّل موضوع العقد';

  @override
  String get contractHistActivity => 'عدّل النشاط';

  @override
  String get contractHistNotes => 'عدّل الملاحظات';

  @override
  String contractHistUnitAdded(String code) {
    return 'أضاف الوحدة $code';
  }

  @override
  String contractHistUnitRemoved(String code) {
    return 'أزال الوحدة $code';
  }

  @override
  String contractHistItemAdded(String label) {
    return 'أضاف نقصًا: $label';
  }

  @override
  String contractHistItemResolved(String label) {
    return 'استوفى: $label';
  }

  @override
  String contractHistItemReopened(String label) {
    return 'أعاد فتح: $label';
  }

  @override
  String contractHistItemDeleted(String label) {
    return 'حذف نقصًا: $label';
  }

  @override
  String contractHistItemOn(String line, String target) {
    return '$line على $target';
  }

  @override
  String get contractHistItemOnStorage => 'عقد المخزن';

  @override
  String contractAnnexesTitle(String count) {
    return 'الملاحق ($count)';
  }

  @override
  String get contractAddAnnex => '+ إضافة ملحق';

  @override
  String contractStorageTitle(String count) {
    return 'المخازن ($count)';
  }

  @override
  String get contractAddStorage => '+ إضافة عقد مخزن';

  @override
  String get storageRenew => 'تجديد للموسم التالي';

  @override
  String annexRowTitle(String number) {
    return 'ملحق $number';
  }

  @override
  String annexChangeEnds(String date) {
    return 'النهاية ← $date';
  }

  @override
  String annexChangeAreaInner(String area) {
    return 'المساحة الداخلية ← $area';
  }

  @override
  String annexChangeAreaOuter(String area) {
    return 'المساحة الخارجية ← $area';
  }

  @override
  String get annexChangeParty => 'المستأجر ←';

  @override
  String get annexChangeUnits => 'الوحدات ←';

  @override
  String get annexNewTitle => 'ملحق جديد';

  @override
  String get annexEditTitle => 'تعديل ملحق';

  @override
  String get annexFieldNo => 'رقم الملحق';

  @override
  String get annexFieldSubject => 'موضوع الملحق';

  @override
  String get annexFieldSigned => 'تاريخ الملحق';

  @override
  String get annexChangesLabel => 'ما الذي يغيّره الملحق؟';

  @override
  String get annexToggleParty => 'المستأجر (تنازل)';

  @override
  String get annexSave => 'حفظ الملحق';

  @override
  String get annexNoInvalid => 'اكتب رقمًا أكبر من صفر.';

  @override
  String get annexDuplicateNo => 'يوجد ملحق بهذا الرقم.';

  @override
  String get annexSaveRejected =>
      'رفض الخادم هذه القيم. تحقق من الوحدات والتواريخ.';

  @override
  String get annexSaveUnknown => 'تعذّر حفظ الملحق. حاول مرة أخرى.';

  @override
  String get annexDiscardBody => 'لن يُحفظ هذا الملحق.';

  @override
  String get annexDiscardEditBody => 'لن تُحفظ التعديلات على الملحق.';

  @override
  String get annexDelete => 'حذف الملحق';

  @override
  String get annexDeleteTitle => 'حذف الملحق؟';

  @override
  String get annexDeleteBody => 'يُحذف هذا الملحق نهائيًا، ولا يمكن استرجاعه.';

  @override
  String get annexDeleteNotEmpty =>
      'لا يمكن حذف الملحق: أُضيف إليه شيء منذ فتحه.';

  @override
  String get storageDelete => 'حذف عقد المخزن';

  @override
  String get storageDeleteTitle => 'حذف عقد المخزن؟';

  @override
  String get storageDeleteBody =>
      'يُحذف عقد المخزن هذا نهائيًا، ولا يمكن استرجاعه.';

  @override
  String get storageDeleteNotEmpty =>
      'لا يمكن حذف عقد المخزن: أُضيف إليه شيء منذ فتحه.';

  @override
  String contractHistOnAnnex(String number, String line) {
    return 'ملحق $number: $line';
  }

  @override
  String contractHistOnStorage(String line) {
    return 'عقد المخزن: $line';
  }

  @override
  String contractHistAddedAnnexSubject(String number, String subject) {
    return 'أضاف ملحق $number: $subject';
  }

  @override
  String contractHistAnnexNo(String from, String to) {
    return 'غيّر رقم الملحق من $from إلى $to';
  }

  @override
  String get contractHistAnnexSubject => 'عدّل موضوع الملحق';

  @override
  String contractChecklistTitle(String count) {
    return 'النواقص والمستندات ($count)';
  }

  @override
  String get checklistDocumentsTitle => 'مستندات مطلوبة من المستأجر';

  @override
  String get checklistDocumentsNote => 'تخص كل عقود هذا المستأجر';

  @override
  String get checklistMissingTitle => 'نواقص التوقيع والختم';

  @override
  String get checklistAddDocument => '+ إضافة مستند';

  @override
  String get checklistAddMissing => '+ إضافة نقص';

  @override
  String get checklistNoDocuments => 'لا توجد مستندات مطلوبة';

  @override
  String get checklistNoMissing => 'لا توجد نواقص';

  @override
  String checklistShowResolved(String count) {
    return 'عرض المستوفاة ($count)';
  }

  @override
  String checklistHideResolved(String count) {
    return 'إخفاء المستوفاة ($count)';
  }

  @override
  String get checklistSignature => 'توقيع';

  @override
  String get checklistStamp => 'ختم';

  @override
  String get checklistOurSide => 'من جانبنا';

  @override
  String checklistOn(String target) {
    return 'على $target';
  }

  @override
  String get checklistOnLabel => 'على';

  @override
  String get checklistOnContract => 'العقد';

  @override
  String checklistOnStorage(String codes) {
    return 'مخزن $codes';
  }

  @override
  String checklistOnStorageSeason(String codes, String year) {
    return 'مخزن $codes · $year';
  }

  @override
  String get checklistLabelField => 'البند';

  @override
  String get checklistDocumentHint => 'مثل: سجل تجاري حديث';

  @override
  String get checklistMissingHint => 'مثل: محضر الاستلام';

  @override
  String get checklistDetailField => 'التفاصيل';

  @override
  String get checklistDetailHint => 'تفاصيل (اختياري)';

  @override
  String get checklistNeedsOne => 'اختر التوقيع أو الختم.';

  @override
  String get checklistAdd => 'إضافة';

  @override
  String get checklistDelete => 'حذف البند';

  @override
  String get checklistDeleteTitle => 'حذف البند؟';

  @override
  String get checklistDeleteBody =>
      'يُحذف هذا البند من القائمة نهائيًا. للبند المستوفى، علّمه بدلًا من حذفه.';

  @override
  String get checklistDeleteConfirm => 'حذف';

  @override
  String contractFollowUpsTitle(String count) {
    return 'المتابعات ($count)';
  }

  @override
  String get contractAddFollowUp => '+ إضافة متابعة';

  @override
  String get followUpDefaultTitle => 'التواصل مع العميل لتوقيع وختم النواقص';

  @override
  String get newTaskContractLabel => 'العقد';

  @override
  String get activityContractLinked => 'ربط المهمة بعقد';

  @override
  String get activityContractUnlinked => 'ألغى ربط المهمة بالعقد';

  @override
  String get contractExport => 'تصدير';

  @override
  String get contractExportXlsx => 'تنزيل ملف Excel';

  @override
  String get contractExportPrint => 'طباعة';

  @override
  String get contractExportError => 'تعذّر تصدير العقود.';

  @override
  String contractExportFileName(String file, String date) {
    return 'عقود $file $date';
  }

  @override
  String get registerHeaderNumber => 'م';

  @override
  String get registerHeaderTenant => 'اسم المستأجر';

  @override
  String get registerHeaderBrand => 'الاسم التجاري';

  @override
  String get registerHeaderUnits => 'رقم الوحدة/ الكشك';

  @override
  String get registerHeaderActivity => 'النشاط';

  @override
  String get registerHeaderSubject => 'موضوع العقد او الملحق';

  @override
  String get registerHeaderSignedOn => 'تاريخ العقد او الملحق';

  @override
  String get registerHeaderEndsOn => 'تاريخ انتهاء العقد';

  @override
  String get registerHeaderDuration => 'مدة الإيجار في العقد';

  @override
  String get registerHeaderAreaInner => 'مساحه داخليه\n(متر مربع)';

  @override
  String get registerHeaderAreaOuter => 'مساحه خارجيه\n(متر مربع)';

  @override
  String get registerHeaderDocuments => '(المستندات المطلوبة)';

  @override
  String get registerHeaderMissing => 'النواقص (توقيع وختم)';

  @override
  String get registerHeaderNotes => 'الملاحظات';

  @override
  String get registerHeaderFollowUps => 'الاجراء المطلوب';

  @override
  String registerBandTitle(String file, String season) {
    return 'بيان بجميع العقود السارية بمشروع $file لموسم $season';
  }

  @override
  String registerBandTitleUndated(String file) {
    return 'بيان بالعقود السارية غير المؤرخة بمشروع $file';
  }

  @override
  String registerTerminatedBandTitle(String file, String season) {
    return 'بيان بالعقود الملغاة بمشروع $file لموسم $season';
  }

  @override
  String registerTerminatedBandTitleUndated(String file) {
    return 'بيان بالعقود الملغاة غير المؤرخة بمشروع $file';
  }

  @override
  String registerTerminatedSheet(String file) {
    return '$file - الملغاة';
  }

  @override
  String registerAnnexSubject(String number, String subject) {
    return 'ملحق $number: $subject';
  }

  @override
  String registerAnnexOnly(String number) {
    return 'ملحق $number';
  }

  @override
  String get registerAnnexUnnumbered => 'ملحق';

  @override
  String registerUnitKey(String code, String key) {
    return '$code (مفتاح $key)';
  }

  @override
  String get registerNeedsBoth => 'توقيع وختم';

  @override
  String registerTerminatedOn(String date) {
    return 'أُلغي في $date';
  }

  @override
  String get registerTerminated => 'ملغى';

  @override
  String get registerLegendTitle => 'الألوان:';

  @override
  String get registerLegendExpired => 'منتهية';

  @override
  String get registerLegendEnding => 'تنتهي خلال 90 يومًا';

  @override
  String get registerLegendAnnex => 'ملحق';

  @override
  String get registerLegendStorage => 'عقد مخزن';
}
