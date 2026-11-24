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

  /// App name, shown in the header and the browser tab.
  ///
  /// In ar, this message translates to:
  /// **'نظام الإدارة القانونية'**
  String get appTitle;

  /// Task status: not started (enum todo).
  ///
  /// In ar, this message translates to:
  /// **'لم تبدأ'**
  String get statusTodo;

  /// Task status: in progress (enum doing).
  ///
  /// In ar, this message translates to:
  /// **'جارية'**
  String get statusDoing;

  /// Task status: waiting for a reply (enum waiting).
  ///
  /// In ar, this message translates to:
  /// **'بانتظار رد'**
  String get statusWaiting;

  /// Task status: completed (enum done).
  ///
  /// In ar, this message translates to:
  /// **'مكتملة'**
  String get statusDone;

  /// Login card heading.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// Login form: email field label.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get loginEmailLabel;

  /// Login form: password field label.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get loginPasswordLabel;

  /// Shown under the email field when its format is invalid (checked on submit, then while typing).
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدًا إلكترونيًا صحيحًا.'**
  String get loginErrorInvalidEmail;

  /// Login form: submit button.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginSubmit;

  /// Tooltip on the eye icon in the password field.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get loginShowPassword;

  /// Tooltip on the eye icon when the password is shown.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get loginHidePassword;

  /// Muted help line under the login button. There is no self-service reset.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟ تواصل مع مسؤول النظام.'**
  String get loginForgotHelp;

  /// Login error: wrong email or password.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة.'**
  String get loginErrorInvalidCredentials;

  /// Login error: rate limited by the server.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة. حاول مرة أخرى بعد قليل.'**
  String get loginErrorRateLimited;

  /// Login error: no response from the server.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالخادم. تحقق من الشبكة وحاول مرة أخرى.'**
  String get loginErrorNetwork;

  /// Login error: anything else.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. حاول مرة أخرى.'**
  String get loginErrorUnknown;

  /// Shown on the login screen after a deactivated user signs in.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب معطّل. تواصل مع مسؤول النظام.'**
  String get authAccountDisabled;

  /// Header button that signs the user out.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// Task status: cancelled (enum cancelled). Shown as a pill in the closed list.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get statusCancelled;

  /// Header counter label: open tasks that are urgent now (overdue included).
  ///
  /// In ar, this message translates to:
  /// **'عاجلة'**
  String get counterUrgent;

  /// Header counter label: open tasks past their due date.
  ///
  /// In ar, this message translates to:
  /// **'متأخرة'**
  String get counterOverdue;

  /// Header counter label: all open tasks.
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة'**
  String get counterOpen;

  /// First file filter chip: no file filter.
  ///
  /// In ar, this message translates to:
  /// **'كل الملفات'**
  String get allFiles;

  /// Accessibility label of the file filter chip row.
  ///
  /// In ar, this message translates to:
  /// **'تصفية حسب الملف'**
  String get fileFilterLabel;

  /// Tasks view: urgent section title.
  ///
  /// In ar, this message translates to:
  /// **'عاجلة — تُنجز اليوم'**
  String get sectionUrgentTitle;

  /// Tasks view: caption next to the urgent section title.
  ///
  /// In ar, this message translates to:
  /// **'المتأخرة أولًا، ثم ما موعده اليوم أو عُلّم عاجلًا'**
  String get sectionUrgentCaption;

  /// Tasks view: upcoming section title.
  ///
  /// In ar, this message translates to:
  /// **'القادمة'**
  String get sectionUpcomingTitle;

  /// Tasks view: caption next to the upcoming section title.
  ///
  /// In ar, this message translates to:
  /// **'مرتبة حسب أقرب موعد تسليم'**
  String get sectionUpcomingCaption;

  /// Tasks view: closed (done and cancelled) section title.
  ///
  /// In ar, this message translates to:
  /// **'المكتملة'**
  String get sectionClosedTitle;

  /// Tasks view: shown when the urgent section is empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مهام عاجلة اليوم'**
  String get emptyUrgent;

  /// Tasks view: shown when the upcoming section is empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مهام قادمة'**
  String get emptyUpcoming;

  /// Button that expands the closed section. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'عرض المكتملة ({count})'**
  String showClosed(String count);

  /// Button that collapses the closed section. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء المكتملة ({count})'**
  String hideClosed(String count);

  /// Flag on a task row that is past its due date.
  ///
  /// In ar, this message translates to:
  /// **'متأخرة'**
  String get flagOverdue;

  /// Flag on a task row that is urgent (due today or marked urgent).
  ///
  /// In ar, this message translates to:
  /// **'عاجلة'**
  String get flagUrgent;

  /// Due label: due today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get dueToday;

  /// Due label: due tomorrow.
  ///
  /// In ar, this message translates to:
  /// **'غدًا'**
  String get dueTomorrow;

  /// Due label for an overdue task. days is a day phrase (dayOne, dayTwo, daysFew or daysMany).
  ///
  /// In ar, this message translates to:
  /// **'متأخرة منذ {days}'**
  String dueOverdueSince(String days);

  /// Due label for a task due in 2 to 6 days. days is a day phrase.
  ///
  /// In ar, this message translates to:
  /// **'بعد {days}'**
  String dueIn(String days);

  /// Day phrase for 1 day.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get dayOne;

  /// Day phrase for 2 days.
  ///
  /// In ar, this message translates to:
  /// **'يومين'**
  String get dayTwo;

  /// Day phrase for 3 to 10 days. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} أيام'**
  String daysFew(String count);

  /// Day phrase for 11 days or more. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} يومًا'**
  String daysMany(String count);

  /// Accessibility label of the comment icon and count on a task row.
  ///
  /// In ar, this message translates to:
  /// **'عدد التحديثات: {count}'**
  String updatesCount(String count);

  /// Shown instead of the assignee's name when their profile can't be read.
  ///
  /// In ar, this message translates to:
  /// **'موظف سابق'**
  String get formerEmployee;

  /// Tasks view: the task list could not be loaded.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل المهام.'**
  String get tasksLoadError;

  /// Button that retries a failed load.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// Close button of the task drawer, and the drawer's scrim label.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get drawerClose;

  /// Task drawer: label above the status buttons.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get drawerStatusLabel;

  /// Task drawer: assignee field label.
  ///
  /// In ar, this message translates to:
  /// **'الموظف المسؤول'**
  String get drawerAssigneeLabel;

  /// Task drawer: due date field label.
  ///
  /// In ar, this message translates to:
  /// **'موعد التسليم'**
  String get drawerDueLabel;

  /// Task drawer: the label over a follow-up task's contract, a link to the contract drawer.
  ///
  /// In ar, this message translates to:
  /// **'العقد'**
  String get drawerContractLabel;

  /// Accessibility label of the due date field, which opens a date picker.
  ///
  /// In ar, this message translates to:
  /// **'اختيار موعد التسليم'**
  String get drawerPickDue;

  /// Task drawer: checkbox that flags the task urgent by hand.
  ///
  /// In ar, this message translates to:
  /// **'تعليم كعاجلة يدويًا'**
  String get drawerManualUrgent;

  /// Task drawer urgent box note: the task is done.
  ///
  /// In ar, this message translates to:
  /// **'المهمة مكتملة.'**
  String get urgentNoteDone;

  /// Task drawer urgent box note: the task is cancelled (not in the canvas).
  ///
  /// In ar, this message translates to:
  /// **'المهمة ملغاة.'**
  String get urgentNoteCancelled;

  /// Task drawer urgent box note: open and past its due date.
  ///
  /// In ar, this message translates to:
  /// **'عاجلة تلقائيًا لأن موعد التسليم فات.'**
  String get urgentNoteOverdue;

  /// Task drawer urgent box note: open and due today.
  ///
  /// In ar, this message translates to:
  /// **'عاجلة تلقائيًا لأن موعد التسليم اليوم.'**
  String get urgentNoteToday;

  /// Task drawer urgent box note: flagged urgent by hand.
  ///
  /// In ar, this message translates to:
  /// **'عُلّمت عاجلة يدويًا وتظهر في أعلى القائمة.'**
  String get urgentNoteManual;

  /// Task drawer urgent box note: not urgent yet.
  ///
  /// In ar, this message translates to:
  /// **'ستصبح عاجلة تلقائيًا يوم موعد التسليم.'**
  String get urgentNoteLater;

  /// Task drawer: description heading.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get drawerDescriptionLabel;

  /// Task drawer: updates heading.
  ///
  /// In ar, this message translates to:
  /// **'التحديثات — إلى أين وصلنا'**
  String get drawerUpdatesLabel;

  /// Task drawer: the task has no updates.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تحديثات بعد'**
  String get drawerNoUpdates;

  /// Task drawer: the update box's label for screen readers (hidden on screen, as in the canvas).
  ///
  /// In ar, this message translates to:
  /// **'أضف تحديثًا'**
  String get updateFieldLabel;

  /// Task drawer: the update box's placeholder.
  ///
  /// In ar, this message translates to:
  /// **'اكتب آخر ما وصلت إليه في المهمة…'**
  String get updateHint;

  /// Task drawer: posts the typed update.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تحديث'**
  String get updateAdd;

  /// Task drawer: the server refused the update (RLS).
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية إضافة تحديث على هذه المهمة.'**
  String get updateErrorNotAllowed;

  /// Task drawer: any other failure to post an update. The network case reuses loginErrorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إضافة التحديث. حاول مرة أخرى.'**
  String get updateErrorUnknown;

  /// Task drawer: the task's details could not be loaded.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل المهمة.'**
  String get drawerLoadError;

  /// Task drawer: the server refused the change (RLS).
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية تعديل هذه المهمة.'**
  String get saveErrorNotAllowed;

  /// Task drawer: the assignee is inactive or not a member of the task's file.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن إسناد المهمة لهذا الموظف.'**
  String get saveErrorAssignee;

  /// Task drawer: any other save failure. The network case reuses loginErrorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ التغيير. حاول مرة أخرى.'**
  String get saveErrorUnknown;

  /// Task drawer: button that cancels the task, and the confirm button of its dialog.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المهمة'**
  String get cancelTask;

  /// Cancel-task confirm dialog title.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المهمة؟'**
  String get cancelTaskTitle;

  /// Cancel-task confirm dialog body.
  ///
  /// In ar, this message translates to:
  /// **'تنتقل المهمة إلى المكتملة بحالة ملغاة، ويمكن إعادة فتحها لاحقًا.'**
  String get cancelTaskBody;

  /// Cancel-task confirm dialog: keep the task open.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get cancelTaskBack;

  /// Task drawer: button beside the title that turns the title and description into an edit form.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get editTask;

  /// Task drawer edit form: title field label (same as the new-task modal).
  ///
  /// In ar, this message translates to:
  /// **'عنوان المهمة'**
  String get editTitleLabel;

  /// Task drawer edit form: save the title and description.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get editSave;

  /// Task drawer edit form: drop the changes and show the text again.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get editCancel;

  /// Confirm dialog title when closing the drawer (or pressing Esc) with unsaved title or description changes.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل التعديلات؟'**
  String get discardEditTitle;

  /// Discard-changes confirm dialog body.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحفظ التعديلات على العنوان والوصف.'**
  String get discardEditBody;

  /// Discard-changes confirm dialog: go back to the form.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التعديل'**
  String get discardEditBack;

  /// Discard-changes confirm dialog: drop the changes.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get discardEditConfirm;

  /// Confirm dialog title when closing the drawer with an update typed but not added.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل التحديث؟'**
  String get discardUpdateTitle;

  /// Discard-update confirm dialog body. The confirm button reuses discardEditConfirm.
  ///
  /// In ar, this message translates to:
  /// **'لن يُحفظ التحديث الذي كتبته.'**
  String get discardUpdateBody;

  /// Discard-update confirm dialog (and the combined one): go back to the drawer.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الكتابة'**
  String get discardUpdateBack;

  /// Confirm dialog title when closing the drawer with both an unsaved title/description edit and an unsent update.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل ما كتبته؟'**
  String get discardAllTitle;

  /// The combined discard dialog body.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحفظ التعديلات على العنوان والوصف ولا التحديث الذي كتبته.'**
  String get discardAllBody;

  /// Relative time: less than a minute ago.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get timeNow;

  /// Relative time in the past. time is a minute, hour or day phrase.
  ///
  /// In ar, this message translates to:
  /// **'منذ {time}'**
  String timeAgo(String time);

  /// Relative time: the previous calendar day.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get timeYesterday;

  /// Minute phrase for 1 minute.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة'**
  String get minuteOne;

  /// Minute phrase for 2 minutes.
  ///
  /// In ar, this message translates to:
  /// **'دقيقتين'**
  String get minuteTwo;

  /// Minute phrase for 3 to 10 minutes. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} دقائق'**
  String minutesFew(String count);

  /// Minute phrase for 11 minutes or more. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} دقيقة'**
  String minutesMany(String count);

  /// Hour phrase for 1 hour.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get hourOne;

  /// Hour phrase for 2 hours.
  ///
  /// In ar, this message translates to:
  /// **'ساعتين'**
  String get hourTwo;

  /// Hour phrase for 3 to 10 hours. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} ساعات'**
  String hoursFew(String count);

  /// Hour phrase for 11 hours or more. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} ساعة'**
  String hoursMany(String count);

  /// Tasks view: placeholder of the search field.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في المهام…'**
  String get searchHint;

  /// Accessibility label of the search field.
  ///
  /// In ar, this message translates to:
  /// **'البحث في المهام'**
  String get searchLabel;

  /// Tooltip of the × button that clears the search.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get searchClear;

  /// Search result line for 1 match. term is what was searched.
  ///
  /// In ar, this message translates to:
  /// **'نتيجة واحدة لـ \"{term}\"'**
  String searchResultOne(String term);

  /// Search result line for 2 matches.
  ///
  /// In ar, this message translates to:
  /// **'نتيجتان لـ \"{term}\"'**
  String searchResultTwo(String term);

  /// Search result line for 3 to 10 matches. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} نتائج لـ \"{term}\"'**
  String searchResultsFew(String count, String term);

  /// Search result line for 11 matches or more. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} نتيجة لـ \"{term}\"'**
  String searchResultsMany(String count, String term);

  /// Tasks view: empty box when a search has no matches.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مهام تطابق \"{term}\"'**
  String searchNoResults(String term);

  /// Tasks view: the search request failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر البحث. حاول مرة أخرى.'**
  String get searchError;

  /// Accessibility label of the view tabs (segmented control).
  ///
  /// In ar, this message translates to:
  /// **'طريقة العرض'**
  String get viewTabsLabel;

  /// View tab: the tasks view (View 1).
  ///
  /// In ar, this message translates to:
  /// **'المهام والأولوية'**
  String get tabTasks;

  /// View tab: the topics view (View 2).
  ///
  /// In ar, this message translates to:
  /// **'المواضيع'**
  String get tabTopics;

  /// View tab: the people view (View 3).
  ///
  /// In ar, this message translates to:
  /// **'الموظفون'**
  String get tabPeople;

  /// Topics view: small label above a topic card's name.
  ///
  /// In ar, this message translates to:
  /// **'عقد براند'**
  String get topicBrandLabel;

  /// Topics view file summary: a file with no topics.
  ///
  /// In ar, this message translates to:
  /// **'لا مواضيع'**
  String get topicCountZero;

  /// Topics view file summary: one topic.
  ///
  /// In ar, this message translates to:
  /// **'موضوع واحد'**
  String get topicCountOne;

  /// Topics view file summary: two topics.
  ///
  /// In ar, this message translates to:
  /// **'موضوعان'**
  String get topicCountTwo;

  /// Topics view file summary: 3 to 10 topics. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} مواضيع'**
  String topicCountFew(String count);

  /// Topics view file summary: 11 or more topics. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} موضوعًا'**
  String topicCountMany(String count);

  /// Topics view file summary: no open tasks.
  ///
  /// In ar, this message translates to:
  /// **'لا مهام مفتوحة'**
  String get openTaskCountZero;

  /// Topics view file summary: one open task.
  ///
  /// In ar, this message translates to:
  /// **'مهمة مفتوحة واحدة'**
  String get openTaskCountOne;

  /// Topics view file summary: two open tasks.
  ///
  /// In ar, this message translates to:
  /// **'مهمتان مفتوحتان'**
  String get openTaskCountTwo;

  /// Topics view file summary: 3 to 10 open tasks. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} مهام مفتوحة'**
  String openTaskCountFew(String count);

  /// Topics view file summary: 11 or more open tasks. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} مهمة مفتوحة'**
  String openTaskCountMany(String count);

  /// Topics view: urgent count in a file summary and on a topic card's badge, written like the header counter. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} عاجلة'**
  String urgentCountLabel(String count);

  /// Topics view: under a topic's progress bar. Cancelled tasks are not counted. Both numbers are already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'مكتملة: {done} من {total}'**
  String topicProgress(String done, String total);

  /// Topics view: under the empty progress bar of a topic with no tasks.
  ///
  /// In ar, this message translates to:
  /// **'لا مهام بعد'**
  String get topicNoTasks;

  /// Topics and people views: a topic or person card with no open tasks.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مهام مفتوحة'**
  String get topicNoOpenTasks;

  /// Topics view: a file section with no topics.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواضيع في هذا الملف'**
  String get fileNoTopics;

  /// People view: a file chip is selected and nobody is a member of it or has open tasks in it.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد موظفون في هذا الملف'**
  String get peopleEmptyFile;

  /// People view: no file chip is selected and there is nobody to show.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد موظفون بعد'**
  String get peopleEmpty;

  /// Topics view (managers): the button that opens the new-file modal; shown with a + icon.
  ///
  /// In ar, this message translates to:
  /// **'ملف جديد'**
  String get newFileButton;

  /// Topics view (managers): the button beside a file's title that opens the rename modal.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get editName;

  /// Topics view: screen-reader label of a file's «تعديل» button.
  ///
  /// In ar, this message translates to:
  /// **'تعديل اسم الملف {name}'**
  String editFileSemantics(String name);

  /// Topics view: mouse tooltip of a topic card's pencil button.
  ///
  /// In ar, this message translates to:
  /// **'تعديل اسم الموضوع'**
  String get editTopicTooltip;

  /// Topics view: screen-reader label of a topic card's pencil button.
  ///
  /// In ar, this message translates to:
  /// **'تعديل اسم الموضوع {name}'**
  String editTopicSemantics(String name);

  /// Topics view: the dashed card at the end of a file's grid; also the last entry of the new-task modal's topic select.
  ///
  /// In ar, this message translates to:
  /// **'موضوع جديد'**
  String get newTopicCard;

  /// Screen-reader label of the dashed new-topic card and of the new-task modal's new-topic entry.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موضوع إلى {file}'**
  String newTopicSemantics(String file);

  /// Name modal title: creating a file.
  ///
  /// In ar, this message translates to:
  /// **'ملف جديد'**
  String get nameModalNewFile;

  /// Name modal title: renaming a file.
  ///
  /// In ar, this message translates to:
  /// **'تعديل اسم الملف'**
  String get nameModalRenameFile;

  /// Name modal title: creating a topic.
  ///
  /// In ar, this message translates to:
  /// **'موضوع جديد'**
  String get nameModalNewTopic;

  /// Name modal title: renaming a topic.
  ///
  /// In ar, this message translates to:
  /// **'تعديل اسم الموضوع'**
  String get nameModalRenameTopic;

  /// Name modal: the fixed line naming a topic's file.
  ///
  /// In ar, this message translates to:
  /// **'الملف: {file}'**
  String nameModalFileLine(String file);

  /// Name modal: the field label for a file.
  ///
  /// In ar, this message translates to:
  /// **'اسم الملف'**
  String get fileNameLabel;

  /// Name modal: the field label for a topic.
  ///
  /// In ar, this message translates to:
  /// **'اسم الموضوع (البراند)'**
  String get topicNameLabel;

  /// Name modal: placeholder for a file name (fake example).
  ///
  /// In ar, this message translates to:
  /// **'مثال: سيتي سنتر'**
  String get fileNameHint;

  /// Name modal: placeholder for a topic name (fake example).
  ///
  /// In ar, this message translates to:
  /// **'مثال: كافيه ليمونة'**
  String get topicNameHint;

  /// Name modal: the file name is taken (compared after Arabic normalization).
  ///
  /// In ar, this message translates to:
  /// **'يوجد ملف بهذا الاسم.'**
  String get nameErrorDuplicateFile;

  /// Name modal: the topic name is taken in its file.
  ///
  /// In ar, this message translates to:
  /// **'يوجد موضوع بهذا الاسم في هذا الملف.'**
  String get nameErrorDuplicateTopic;

  /// Name modal: the server refused the save. The network case reuses loginErrorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية تعديل الملفات والمواضيع.'**
  String get nameErrorNotAllowed;

  /// Name modal: any other save failure.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحفظ. حاول مرة أخرى.'**
  String get nameErrorUnknown;

  /// Rename-file modal: the delete button, shown only for a file with no topics.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملف'**
  String get deleteFile;

  /// Rename-topic modal: the delete button, shown only for a topic with no tasks.
  ///
  /// In ar, this message translates to:
  /// **'حذف الموضوع'**
  String get deleteTopic;

  /// Rename-file modal: screen-reader label of the delete button.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملف {name}'**
  String deleteFileSemantics(String name);

  /// Rename-topic modal: screen-reader label of the delete button.
  ///
  /// In ar, this message translates to:
  /// **'حذف الموضوع {name}'**
  String deleteTopicSemantics(String name);

  /// Delete-file confirm dialog: title.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملف {name}؟'**
  String deleteFileTitle(String name);

  /// Delete-topic confirm dialog: title.
  ///
  /// In ar, this message translates to:
  /// **'حذف الموضوع {name}؟'**
  String deleteTopicTitle(String name);

  /// Delete-file and delete-topic confirm dialogs: body.
  ///
  /// In ar, this message translates to:
  /// **'يُحذف نهائيًا، ولا يمكن التراجع عن ذلك.'**
  String get deleteNameBody;

  /// Delete-file and delete-topic confirm dialogs: the confirm button.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteNameConfirm;

  /// Rename-file modal: the delete was refused because someone added a topic after the modal opened.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت مواضيع إلى هذا الملف، فلم يعد حذفه ممكنًا.'**
  String get nameErrorFileNotEmpty;

  /// Rename-topic modal: the delete was refused because someone added a task after the modal opened.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت مهام إلى هذا الموضوع، فلم يعد حذفه ممكنًا.'**
  String get nameErrorTopicNotEmpty;

  /// Header: admins only; opens the users page.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get headerUsers;

  /// Users page: the heading.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get usersTitle;

  /// Users page: back to the tasks.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get usersBack;

  /// Users page: the button that opens the new-user modal (after a + icon).
  ///
  /// In ar, this message translates to:
  /// **'مستخدم جديد'**
  String get usersNew;

  /// Users page: the list failed to load. Followed by retry.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل المستخدمين.'**
  String get usersLoadFailed;

  /// Role label for the lawyer enum value.
  ///
  /// In ar, this message translates to:
  /// **'محامٍ'**
  String get roleLawyer;

  /// Role label for the manager enum value.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get roleManager;

  /// Role label for the admin enum value (as in the login help line).
  ///
  /// In ar, this message translates to:
  /// **'مسؤول النظام'**
  String get roleAdmin;

  /// Users page: pill on a deactivated account.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get userInactive;

  /// Users page: a lawyer who is a member of no file.
  ///
  /// In ar, this message translates to:
  /// **'لا ملفات'**
  String get userFileCountZero;

  /// Users page: a lawyer on one file.
  ///
  /// In ar, this message translates to:
  /// **'ملف واحد'**
  String get userFileCountOne;

  /// Users page: a lawyer on two files.
  ///
  /// In ar, this message translates to:
  /// **'ملفان'**
  String get userFileCountTwo;

  /// Users page: 3 to 10 files. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} ملفات'**
  String userFileCountFew(String count);

  /// Users page: 11 or more files. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} ملفًا'**
  String userFileCountMany(String count);

  /// User modal: title when creating.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم جديد'**
  String get userModalNew;

  /// User modal: title when editing.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المستخدم'**
  String get userModalEdit;

  /// User modal: the display name field label.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get userNameLabel;

  /// User modal: placeholder for the name (fake example).
  ///
  /// In ar, this message translates to:
  /// **'مثال: نور حسن'**
  String get userNameHint;

  /// User and password modals: placeholder for the password.
  ///
  /// In ar, this message translates to:
  /// **'٨ أحرف على الأقل'**
  String get userPasswordHint;

  /// User modal: the role choice label.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get userRoleLabel;

  /// User modal: the file membership checkboxes label (lawyers only).
  ///
  /// In ar, this message translates to:
  /// **'الملفات'**
  String get userFilesLabel;

  /// User modal: shown instead of the file checkboxes for a manager or admin.
  ///
  /// In ar, this message translates to:
  /// **'المدير ومسؤول النظام يريان كل الملفات.'**
  String get userFilesAll;

  /// User modal: there are no files to tick.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملفات بعد.'**
  String get userFilesNone;

  /// User modal: an admin editing their own account.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكنك تغيير دورك أو تعطيل حسابك.'**
  String get userSelfNote;

  /// User modal: heading of the password and deactivate buttons (edit only).
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get userAccountLabel;

  /// User modal: opens the password modal.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كلمة مرور جديدة'**
  String get userSetPassword;

  /// User modal: after the password modal saved.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين كلمة المرور الجديدة.'**
  String get userPasswordSet;

  /// User modal: the deactivate button, and the confirm button of its dialog.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل الحساب'**
  String get userDeactivate;

  /// User modal: the reactivate button.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تفعيل الحساب'**
  String get userReactivate;

  /// User modal: line in the account section of a deactivated account.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب معطّل ولا يمكنه تسجيل الدخول.'**
  String get userIsInactive;

  /// Deactivate confirm dialog: title.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل حساب {name}؟'**
  String userDeactivateTitle(String name);

  /// Deactivate confirm dialog: body.
  ///
  /// In ar, this message translates to:
  /// **'لن يتمكن هذا المستخدم من تسجيل الدخول حتى يُعاد تفعيل الحساب. تبقى المهام والتحديثات كما هي.'**
  String get userDeactivateBody;

  /// User modal: the discard dialog body (title and buttons reuse discardEdit*).
  ///
  /// In ar, this message translates to:
  /// **'لن تُحفظ التعديلات على هذا المستخدم.'**
  String get userDiscardBody;

  /// Password modal: title.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور جديدة'**
  String get passwordModalTitle;

  /// Password modal: the fixed line naming the account.
  ///
  /// In ar, this message translates to:
  /// **'المستخدم: {name}'**
  String passwordModalUserLine(String name);

  /// Password modal: the field label.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get passwordModalLabel;

  /// User and password modals: the server refused.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية إدارة المستخدمين.'**
  String get userErrorNotAllowed;

  /// User modal: deactivating someone with open tasks.
  ///
  /// In ar, this message translates to:
  /// **'لهذا المستخدم مهام مفتوحة. أعد إسنادها أولًا.'**
  String get userErrorOpenTasks;

  /// User modal: removing a lawyer from a file where they have open tasks.
  ///
  /// In ar, this message translates to:
  /// **'لهذا المستخدم مهام مفتوحة في ملف أُلغي تحديده. أعد إسنادها أولًا.'**
  String get userErrorOpenTasksInFile;

  /// User modal: making someone a lawyer while they have open tasks in files not ticked.
  ///
  /// In ar, this message translates to:
  /// **'لهذا المستخدم مهام مفتوحة في ملفات غير محددة. حدّدها أو أعد إسناد المهام أولًا.'**
  String get userErrorOpenTasksOutsideFiles;

  /// User modal: the email is taken.
  ///
  /// In ar, this message translates to:
  /// **'يوجد حساب بهذا البريد الإلكتروني.'**
  String get userErrorEmailTaken;

  /// User and password modals: the server refused the password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور قصيرة. استخدم ٨ أحرف على الأقل.'**
  String get userErrorWeakPassword;

  /// Header button and the new-task modal's title.
  ///
  /// In ar, this message translates to:
  /// **'مهمة جديدة'**
  String get newTask;

  /// New-task modal: the title placeholder.
  ///
  /// In ar, this message translates to:
  /// **'مثال: مراجعة ملحق العقد'**
  String get newTaskTitleHint;

  /// New-task modal: the file select's label.
  ///
  /// In ar, this message translates to:
  /// **'الملف'**
  String get newTaskFileLabel;

  /// New-task modal: the topic select's label.
  ///
  /// In ar, this message translates to:
  /// **'الموضوع (البراند)'**
  String get newTaskTopicLabel;

  /// New-task modal: the assignee select before anyone is picked.
  ///
  /// In ar, this message translates to:
  /// **'اختر الموظف'**
  String get newTaskAssigneeHint;

  /// New-task modal: the manual urgent checkbox.
  ///
  /// In ar, this message translates to:
  /// **'عاجلة (تُنجز اليوم)'**
  String get newTaskUrgent;

  /// New-task modal: the line under the urgent checkbox.
  ///
  /// In ar, this message translates to:
  /// **'تصبح المهمة عاجلة تلقائيًا عندما يحين موعد تسليمها.'**
  String get newTaskUrgentHelp;

  /// New-task modal: the save button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ المهمة'**
  String get newTaskSave;

  /// New-task modal: the body of the ask-before-discard dialog.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحفظ هذه المهمة.'**
  String get newTaskDiscardBody;

  /// New-task modal: the server refused the insert.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية إنشاء مهمة في هذا الملف.'**
  String get newTaskErrorNotAllowed;

  /// New-task modal: any other save error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ المهمة. حاول مرة أخرى.'**
  String get newTaskErrorUnknown;

  /// Task drawer: button that expands the change history. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'عرض سجل التغييرات ({count})'**
  String showActivity(String count);

  /// Task drawer: button that collapses the change history. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء سجل التغييرات ({count})'**
  String hideActivity(String count);

  /// Change history: the actor of a change made by no user (seeds, scheduled jobs, email intake).
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get activitySystem;

  /// Change history, after the actor's name: the task was created. The verb is masculine for everyone (chosen 2026-10-18).
  ///
  /// In ar, this message translates to:
  /// **'أنشأ المهمة'**
  String get activityCreated;

  /// Change history, after the actor's name: the status changed. from/to are status labels.
  ///
  /// In ar, this message translates to:
  /// **'غيّر الحالة من {from} إلى {to}'**
  String activityStatus(String from, String to);

  /// Change history, after the actor's name: the assignee changed. from/to are people's names.
  ///
  /// In ar, this message translates to:
  /// **'غيّر المسؤول من {from} إلى {to}'**
  String activityAssignee(String from, String to);

  /// Change history, after the actor's name: the due date changed. from/to are formatted dates.
  ///
  /// In ar, this message translates to:
  /// **'غيّر موعد التسليم من {from} إلى {to}'**
  String activityDueDate(String from, String to);

  /// Change history, after the actor's name: the task was marked urgent by hand.
  ///
  /// In ar, this message translates to:
  /// **'علّمها عاجلة'**
  String get activityUrgentOn;

  /// Change history, after the actor's name: the manual urgent mark was removed.
  ///
  /// In ar, this message translates to:
  /// **'ألغى تعليمها عاجلة'**
  String get activityUrgentOff;

  /// Change history, after the actor's name: the title changed. The old and new titles follow on their own lines.
  ///
  /// In ar, this message translates to:
  /// **'غيّر العنوان'**
  String get activityTitle;

  /// Change history, for screen readers: the struck-through old title.
  ///
  /// In ar, this message translates to:
  /// **'العنوان السابق: {title}'**
  String activityOldTitle(String title);

  /// Change history, for screen readers: the new title.
  ///
  /// In ar, this message translates to:
  /// **'العنوان الجديد: {title}'**
  String activityNewTitle(String title);

  /// Change history, after the actor's name: the description changed (the text itself isn't shown).
  ///
  /// In ar, this message translates to:
  /// **'عدّل الوصف'**
  String get activityDescription;

  /// Change history, after the actor's name: the task moved to another topic. to is the topic name.
  ///
  /// In ar, this message translates to:
  /// **'نقل المهمة إلى موضوع {to}'**
  String activityTopic(String to);

  /// Change history: stands in for a topic name the viewer can't see («نقل المهمة إلى موضوع آخر»).
  ///
  /// In ar, this message translates to:
  /// **'آخر'**
  String get activityOtherTopic;

  /// Header bell's tooltip and the notifications panel's heading.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// Header bell, for screen readers when something is unread. count is a phrase like «٣ إشعارات غير مقروءة».
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات: {count}'**
  String notificationsBellUnread(String count);

  /// Unread count phrase for 1 (Arabic plural rule, spec §1).
  ///
  /// In ar, this message translates to:
  /// **'إشعار واحد غير مقروء'**
  String get notificationsUnreadOne;

  /// Unread count phrase for 2.
  ///
  /// In ar, this message translates to:
  /// **'إشعاران غير مقروءين'**
  String get notificationsUnreadTwo;

  /// Unread count phrase for 3–10. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} إشعارات غير مقروءة'**
  String notificationsUnreadFew(String count);

  /// Unread count phrase for 11 and more. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} إشعارًا غير مقروء'**
  String notificationsUnreadMany(String count);

  /// Header bell's badge above 9 unread («٩+»). count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count}+'**
  String notificationsBadgeMore(String count);

  /// Notifications panel: marks every unread notification read.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get notificationsMarkAllRead;

  /// Notifications panel: nothing to show.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات'**
  String get notificationsEmpty;

  /// Notifications panel: the list could not be loaded.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الإشعارات.'**
  String get notificationsLoadError;

  /// Notification, after the actor's name: a task was created for the viewer or handed to them. The verb is masculine for everyone, like the change history.
  ///
  /// In ar, this message translates to:
  /// **'أسند إليك مهمة'**
  String get notificationAssigned;

  /// Notification, after the actor's name: an update was posted on the viewer's task.
  ///
  /// In ar, this message translates to:
  /// **'أضاف تحديثًا'**
  String get notificationUpdatePosted;

  /// Notification, after the actor's name: a change whose details can't be read.
  ///
  /// In ar, this message translates to:
  /// **'عدّل المهمة'**
  String get notificationChanged;

  /// Notification: stands in for the task's title when the viewer can no longer see the task.
  ///
  /// In ar, this message translates to:
  /// **'لم تعد هذه المهمة متاحة'**
  String get notificationTaskGone;

  /// Notification: for screen readers, on an unread row's dot.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروء'**
  String get notificationUnread;

  /// View tab: the contracts view (View 4).
  ///
  /// In ar, this message translates to:
  /// **'العقود'**
  String get tabContracts;

  /// Contracts view: placeholder of the search field.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في العقود…'**
  String get contractsSearchHint;

  /// Contracts view: accessibility label of the search field.
  ///
  /// In ar, this message translates to:
  /// **'البحث في العقود'**
  String get contractsSearchLabel;

  /// Contracts filter row: screen-reader name of the type group.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get contractFilterKindLabel;

  /// Contracts filter row: screen-reader name of the status group.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get contractFilterStatusLabel;

  /// Contracts filter row: screen-reader name of the season select.
  ///
  /// In ar, this message translates to:
  /// **'الموسم'**
  String get contractFilterSeasonLabel;

  /// Contracts filter: every type.
  ///
  /// In ar, this message translates to:
  /// **'كل الأنواع'**
  String get contractKindAll;

  /// Contracts filter: leases.
  ///
  /// In ar, this message translates to:
  /// **'وحدات'**
  String get contractKindUnits;

  /// Contracts filter: storage contracts, and leases with storage contracts.
  ///
  /// In ar, this message translates to:
  /// **'مخازن'**
  String get contractKindStorage;

  /// Contracts filter: service and other contracts.
  ///
  /// In ar, this message translates to:
  /// **'خدمات وأخرى'**
  String get contractKindServicesOther;

  /// Contracts filter: every status.
  ///
  /// In ar, this message translates to:
  /// **'كل الحالات'**
  String get contractStatusAll;

  /// Contracts filter: in force, those ending within 90 days included.
  ///
  /// In ar, this message translates to:
  /// **'سارية'**
  String get contractStatusInForce;

  /// Contracts filter: ending within 90 days.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي خلال ٩٠ يومًا'**
  String get contractStatusEnding;

  /// Contracts filter: the end date has passed.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get contractStatusExpired;

  /// Contracts filter: only contracts with open checklist items.
  ///
  /// In ar, this message translates to:
  /// **'بها نواقص'**
  String get contractMissingOnly;

  /// Contracts filter: every season (signing year).
  ///
  /// In ar, this message translates to:
  /// **'كل المواسم'**
  String get contractSeasonAll;

  /// Contract list status pill: in force.
  ///
  /// In ar, this message translates to:
  /// **'سارية'**
  String get contractListActive;

  /// Contract list status pill: ends within 90 days.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي قريبًا'**
  String get contractListEnding;

  /// Contract list status pill: the end date has passed.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get contractListExpired;

  /// Contract list status pill: terminated.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get contractListTerminated;

  /// Contract row: in place of the brand when there is none.
  ///
  /// In ar, this message translates to:
  /// **'بدون براند'**
  String get contractNoBrand;

  /// Contract row: the end date. date is already formatted.
  ///
  /// In ar, this message translates to:
  /// **'حتى {date}'**
  String contractEndsOn(String date);

  /// Contract row: the number of unit codes not shown after the first. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'+ {count}'**
  String contractMoreUnits(String count);

  /// Contract row badge: one annex.
  ///
  /// In ar, this message translates to:
  /// **'ملحق'**
  String get annexCountOne;

  /// Contract row badge: two annexes.
  ///
  /// In ar, this message translates to:
  /// **'ملحقان'**
  String get annexCountTwo;

  /// Contract row badge: 3 to 10 annexes. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} ملاحق'**
  String annexCountFew(String count);

  /// Contract row badge: 11 or more annexes. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} ملحقًا'**
  String annexCountMany(String count);

  /// Contract row badge: one storage contract.
  ///
  /// In ar, this message translates to:
  /// **'مخزن'**
  String get storageCountOne;

  /// Contract row badge: two storage contracts.
  ///
  /// In ar, this message translates to:
  /// **'مخزنان'**
  String get storageCountTwo;

  /// Contract row badge: 3 to 10 storage contracts. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} مخازن'**
  String storageCountFew(String count);

  /// Contract row badge: 11 or more storage contracts. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} مخزنًا'**
  String storageCountMany(String count);

  /// Contract row badge: one open follow-up task.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get followUpCountOne;

  /// Contract row badge: two open follow-up tasks.
  ///
  /// In ar, this message translates to:
  /// **'متابعتان'**
  String get followUpCountTwo;

  /// Contract row badge: 3 to 10 open follow-up tasks. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} متابعات'**
  String followUpCountFew(String count);

  /// Contract row badge: 11 or more open follow-up tasks. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} متابعة'**
  String followUpCountMany(String count);

  /// Contract row badge: one open checklist item.
  ///
  /// In ar, this message translates to:
  /// **'نقص'**
  String get missingCountOne;

  /// Contract row badge: two open checklist items.
  ///
  /// In ar, this message translates to:
  /// **'نقصان'**
  String get missingCountTwo;

  /// Contract row badge: 3 to 10 open checklist items. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} نواقص'**
  String missingCountFew(String count);

  /// Contract row badge: 11 or more open checklist items. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} نقصًا'**
  String missingCountMany(String count);

  /// Contracts file summary: one contract.
  ///
  /// In ar, this message translates to:
  /// **'عقد واحد'**
  String get contractCountOne;

  /// Contracts file summary: two contracts.
  ///
  /// In ar, this message translates to:
  /// **'عقدان'**
  String get contractCountTwo;

  /// Contracts file summary: 3 to 10 contracts. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} عقود'**
  String contractCountFew(String count);

  /// Contracts file summary: 11 or more contracts. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} عقدًا'**
  String contractCountMany(String count);

  /// Contracts file summary: contracts ending within 90 days. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} تنتهي خلال ٩٠ يومًا'**
  String contractsEndingLabel(String count);

  /// Contracts file summary: contracts with open checklist items. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} بها نواقص'**
  String contractsMissingLabel(String count);

  /// Contracts view: button that expands a file's terminated contracts. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'عرض الملغاة ({count})'**
  String showTerminated(String count);

  /// Contracts view: button that collapses a file's terminated contracts. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء الملغاة ({count})'**
  String hideTerminated(String count);

  /// Contracts view: the selected file has no contracts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عقود في هذا الملف'**
  String get contractsEmptyFile;

  /// Contracts view: no file has contracts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عقود بعد'**
  String get contractsEmpty;

  /// Contracts view: the filters leave nothing.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عقود تطابق هذه الاختيارات'**
  String get contractsNoFilterMatches;

  /// Contracts view: button that resets the filters.
  ///
  /// In ar, this message translates to:
  /// **'مسح الاختيارات'**
  String get contractsClearFilters;

  /// Contracts view: the search found nothing.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عقود تطابق \"{term}\"'**
  String contractsNoSearchMatches(String term);

  /// Contracts view: the list failed to load.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل العقود.'**
  String get contractsLoadError;

  /// Suggest field: the last row, which adds the typed text as a new record.
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة \"{text}\"'**
  String suggestAdd(String text);

  /// Units field: the add row for several joined unit codes. count is a phrase such as «٢ وحدات»; codes are joined with « · ».
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة {count}: {codes}'**
  String suggestAddUnits(String count, String codes);

  /// Suggest field: error when the field is left with typed text and no pick.
  ///
  /// In ar, this message translates to:
  /// **'اختر من القائمة أو أضف جديدًا'**
  String get suggestPickOrAdd;

  /// Suggest field: read by screen readers, one suggestion.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح واحد'**
  String get suggestCountOne;

  /// Suggest field: read by screen readers, two suggestions.
  ///
  /// In ar, this message translates to:
  /// **'اقتراحان'**
  String get suggestCountTwo;

  /// Suggest field: 3 to 10 suggestions. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} اقتراحات'**
  String suggestCountFew(String count);

  /// Suggest field: 11 or more suggestions. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} اقتراحًا'**
  String suggestCountMany(String count);

  /// Suggest field: the × on a pick, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'إزالة {value}'**
  String suggestRemove(String value);

  /// Suggest field: creating the typed record failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت الإضافة. حاول مرة أخرى.'**
  String get suggestAddFailed;

  /// Suggest field: the server refused creating the record.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية الإضافة في هذا الملف.'**
  String get suggestAddNotAllowed;

  /// Dialog title before adding a tenant close to an existing one.
  ///
  /// In ar, this message translates to:
  /// **'يوجد مستأجر مشابه'**
  String get similarPartyTitle;

  /// Dialog title before adding a unit close to an existing one.
  ///
  /// In ar, this message translates to:
  /// **'توجد وحدة مشابهة'**
  String get similarUnitTitle;

  /// Similar dialog: pick this existing record.
  ///
  /// In ar, this message translates to:
  /// **'استخدام هذا'**
  String get similarUse;

  /// Similar dialog: add the typed record anyway.
  ///
  /// In ar, this message translates to:
  /// **'إضافة جديد على أي حال'**
  String get similarAddAnyway;

  /// Tenant field: the server refused a duplicate name.
  ///
  /// In ar, this message translates to:
  /// **'يوجد مستأجر بهذا الاسم.'**
  String get partyDuplicate;

  /// Units field: the server refused a duplicate code in the file.
  ///
  /// In ar, this message translates to:
  /// **'توجد وحدة بهذا الرقم في هذا الملف.'**
  String get unitDuplicate;

  /// One unit.
  ///
  /// In ar, this message translates to:
  /// **'وحدة واحدة'**
  String get unitCountOne;

  /// Two units.
  ///
  /// In ar, this message translates to:
  /// **'وحدتان'**
  String get unitCountTwo;

  /// 3 to 10 units. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} وحدات'**
  String unitCountFew(String count);

  /// 11 or more units. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} وحدة'**
  String unitCountMany(String count);

  /// Unit suggestion hint: no contract in force.
  ///
  /// In ar, this message translates to:
  /// **'شاغرة'**
  String get unitVacant;

  /// Storage unit hint: its key number.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح {number}'**
  String unitKeyHint(String number);

  /// Unit kind.
  ///
  /// In ar, this message translates to:
  /// **'محل'**
  String get unitKindShop;

  /// Unit kind.
  ///
  /// In ar, this message translates to:
  /// **'كشك'**
  String get unitKindKiosk;

  /// Unit kind.
  ///
  /// In ar, this message translates to:
  /// **'مخزن'**
  String get unitKindStorage;

  /// Unit kind.
  ///
  /// In ar, this message translates to:
  /// **'مساحة'**
  String get unitKindSpace;

  /// Unit kind.
  ///
  /// In ar, this message translates to:
  /// **'موقع'**
  String get unitKindSite;

  /// Units field: the inline row that adds a new unit.
  ///
  /// In ar, this message translates to:
  /// **'وحدة جديدة'**
  String get unitNewLabel;

  /// Units field: the new unit kind select, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'نوع الوحدة'**
  String get unitKindLabel;

  /// Units field: a new storage unit key number.
  ///
  /// In ar, this message translates to:
  /// **'رقم المفتاح'**
  String get unitKeyNumberLabel;

  /// Units field: adds the new unit.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get unitAdd;

  /// Contracts view: the new-contract button, and the form title.
  ///
  /// In ar, this message translates to:
  /// **'عقد جديد'**
  String get contractNew;

  /// Contract form title when editing.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العقد'**
  String get contractEditTitle;

  /// Contract form: the kind chips, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'نوع العقد'**
  String get contractKindLabel;

  /// Contract form kind chip.
  ///
  /// In ar, this message translates to:
  /// **'إيجار وحدة / مساحة'**
  String get contractFormKindLease;

  /// Contract form kind chip.
  ///
  /// In ar, this message translates to:
  /// **'مخزن'**
  String get contractFormKindStorage;

  /// Contract form kind chip.
  ///
  /// In ar, this message translates to:
  /// **'خدمات'**
  String get contractFormKindService;

  /// Contract form kind chip.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get contractFormKindOther;

  /// Default subject of a lease. Saved as typed.
  ///
  /// In ar, this message translates to:
  /// **'عقد ايجار وحدة'**
  String get contractSubjectLease;

  /// Default subject of a storage contract.
  ///
  /// In ar, this message translates to:
  /// **'عقد ايجار مخزن'**
  String get contractSubjectStorage;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'البراند'**
  String get contractFieldBrand;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'المستأجر'**
  String get contractFieldParty;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'الوحدات'**
  String get contractFieldUnits;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'موضوع العقد'**
  String get contractFieldSubject;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'النشاط'**
  String get contractFieldActivity;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ العقد'**
  String get contractFieldSigned;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية'**
  String get contractFieldStarts;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ النهاية'**
  String get contractFieldEnds;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'المساحة الداخلية'**
  String get contractFieldAreaInner;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'المساحة الخارجية'**
  String get contractFieldAreaOuter;

  /// Contract drawer: the area text when it is not a number.
  ///
  /// In ar, this message translates to:
  /// **'المساحة'**
  String get contractFieldArea;

  /// Contract field label.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get contractFieldNotes;

  /// Storage contract form: the lease it hangs under.
  ///
  /// In ar, this message translates to:
  /// **'مرتبط بعقد'**
  String get contractFieldLinked;

  /// Contract drawer label.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get contractFieldDuration;

  /// Contract drawer and termination dialog label.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الإنهاء'**
  String get contractFieldTerminated;

  /// Contract drawer and termination dialog label.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإنهاء'**
  String get contractFieldReason;

  /// Storage contract form: hint of the linked-lease field.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get contractLinkedHint;

  /// Contract form: empty start date.
  ///
  /// In ar, this message translates to:
  /// **'مثل تاريخ العقد'**
  String get contractStartsHint;

  /// Contract form: an empty date box.
  ///
  /// In ar, this message translates to:
  /// **'اختر التاريخ'**
  String get contractPickDate;

  /// Contract form: the × on a date box. field is its label.
  ///
  /// In ar, this message translates to:
  /// **'مسح {field}'**
  String contractClearDate(String field);

  /// Contract form: turns the end date into text.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تاريخ نهاية محدد'**
  String get contractNoEndDate;

  /// Contract form: turns the end-date text back into a date.
  ///
  /// In ar, this message translates to:
  /// **'إدخال تاريخ النهاية'**
  String get contractUseEndDate;

  /// Contract form: turns the areas into text.
  ///
  /// In ar, this message translates to:
  /// **'المساحة لا تُكتب كرقم'**
  String get contractAreaAsText;

  /// Contract form: turns the area text back into numbers.
  ///
  /// In ar, this message translates to:
  /// **'إدخال المساحة كرقم'**
  String get contractAreaAsNumber;

  /// Contract form: the end-date text hint.
  ///
  /// In ar, this message translates to:
  /// **'مثل: نهاية موسم صيف 2028'**
  String get contractDateNoteHint;

  /// Contract form: the area text hint.
  ///
  /// In ar, this message translates to:
  /// **'مثل: السنة الأولى 165 / الثانية 331'**
  String get contractAreaNoteHint;

  /// Square metres, after an area.
  ///
  /// In ar, this message translates to:
  /// **'م²'**
  String get contractAreaUnit;

  /// Contract form: an area that is not a number.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقمًا، مثل 35,3'**
  String get contractAreaInvalid;

  /// Contract form: dates out of order.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ النهاية قبل تاريخ البداية.'**
  String get contractDatesOrder;

  /// Contract form: save button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العقد'**
  String get contractSave;

  /// Contract form: leaving a new contract with changes.
  ///
  /// In ar, this message translates to:
  /// **'لن يُحفظ هذا العقد.'**
  String get contractDiscardBody;

  /// Contract form: leaving an edit with changes.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحفظ التعديلات على العقد.'**
  String get contractDiscardEditBody;

  /// Contract form: the server refused the save.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية حفظ عقد في هذا الملف.'**
  String get contractSaveNotAllowed;

  /// Contract form: a database rule refused the save.
  ///
  /// In ar, this message translates to:
  /// **'رفض الخادم هذه القيم. تحقق من البراند والوحدات والتواريخ.'**
  String get contractSaveRejected;

  /// Contract form: any other failure.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ العقد. حاول مرة أخرى.'**
  String get contractSaveUnknown;

  /// Contract drawer: loading failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل العقد.'**
  String get contractLoadError;

  /// Contract drawer: after a value an annex set.
  ///
  /// In ar, this message translates to:
  /// **'(بموجب ملحق {number})'**
  String contractByAnnex(String number);

  /// Contract drawer: an empty value.
  ///
  /// In ar, this message translates to:
  /// **'—'**
  String get contractValueNone;

  /// An area in square metres. area is formatted.
  ///
  /// In ar, this message translates to:
  /// **'{area} م²'**
  String contractArea(String area);

  /// Contract drawer: under the end date.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي اليوم'**
  String get contractEndsToday;

  /// Contract drawer: under the end date. time is a phrase such as «٣ أشهر».
  ///
  /// In ar, this message translates to:
  /// **'تنتهي بعد {time}'**
  String contractEndsIn(String time);

  /// Contract drawer: under a past end date.
  ///
  /// In ar, this message translates to:
  /// **'انتهت منذ {time}'**
  String contractEndedAgo(String time);

  /// After بعد / منذ: one day.
  ///
  /// In ar, this message translates to:
  /// **'يوم واحد'**
  String get relDaysOne;

  /// After بعد / منذ: two days.
  ///
  /// In ar, this message translates to:
  /// **'يومين'**
  String get relDaysTwo;

  /// After بعد / منذ: 3 to 10 days. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} أيام'**
  String relDaysFew(String count);

  /// After بعد / منذ: 11 or more days. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} يومًا'**
  String relDaysMany(String count);

  /// After بعد / منذ: one month.
  ///
  /// In ar, this message translates to:
  /// **'شهر واحد'**
  String get relMonthsOne;

  /// After بعد / منذ: two months.
  ///
  /// In ar, this message translates to:
  /// **'شهرين'**
  String get relMonthsTwo;

  /// After بعد / منذ: 3 to 10 months. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} أشهر'**
  String relMonthsFew(String count);

  /// After بعد / منذ: 11 or more months. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} شهرًا'**
  String relMonthsMany(String count);

  /// After بعد / منذ: one year.
  ///
  /// In ar, this message translates to:
  /// **'سنة واحدة'**
  String get relYearsOne;

  /// After بعد / منذ: two years.
  ///
  /// In ar, this message translates to:
  /// **'سنتين'**
  String get relYearsTwo;

  /// After بعد / منذ: 3 to 10 years. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} سنوات'**
  String relYearsFew(String count);

  /// After بعد / منذ: 11 or more years. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} سنة'**
  String relYearsMany(String count);

  /// Contract duration: one year.
  ///
  /// In ar, this message translates to:
  /// **'سنة واحدة'**
  String get durYearsOne;

  /// Contract duration: two years.
  ///
  /// In ar, this message translates to:
  /// **'سنتان'**
  String get durYearsTwo;

  /// Contract duration: 3 to 10 years. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} سنوات'**
  String durYearsFew(String count);

  /// Contract duration: 11 or more years. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} سنة'**
  String durYearsMany(String count);

  /// Contract duration: one month.
  ///
  /// In ar, this message translates to:
  /// **'شهر واحد'**
  String get durMonthsOne;

  /// Contract duration: two months.
  ///
  /// In ar, this message translates to:
  /// **'شهران'**
  String get durMonthsTwo;

  /// Contract duration: 3 to 10 months. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} أشهر'**
  String durMonthsFew(String count);

  /// Contract duration: 11 or more months. count is already formatted with locale digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} شهرًا'**
  String durMonthsMany(String count);

  /// Contract duration: years and months, both phrases.
  ///
  /// In ar, this message translates to:
  /// **'{years} و{months}'**
  String durJoin(String years, String months);

  /// Contract drawer: deletes an active contract with nothing under it (one made by mistake).
  ///
  /// In ar, this message translates to:
  /// **'حذف العقد'**
  String get contractDelete;

  /// Contract drawer: delete confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'حذف العقد؟'**
  String get contractDeleteTitle;

  /// Contract drawer: delete confirmation body.
  ///
  /// In ar, this message translates to:
  /// **'يُحذف هذا العقد نهائيًا، ولا يمكن استرجاعه.'**
  String get contractDeleteBody;

  /// Contract drawer: terminates a contract; also its dialog title and button.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء العقد'**
  String get contractTerminate;

  /// Termination dialog body.
  ///
  /// In ar, this message translates to:
  /// **'ينتقل العقد إلى «الملغاة». يستطيع المدير إعادة تفعيله لاحقًا.'**
  String get contractTerminateBody;

  /// Termination dialog: the reason hint.
  ///
  /// In ar, this message translates to:
  /// **'مثل: فسخ رضائي'**
  String get contractReasonHint;

  /// Termination dialog: the date box, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'اختيار تاريخ الإنهاء'**
  String get contractPickTerminated;

  /// Contract drawer: managers reopen a terminated contract.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تفعيل'**
  String get contractReopen;

  /// Contract drawer: the server refused an action.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية تعديل هذا العقد.'**
  String get contractActionNotAllowed;

  /// Contract drawer: the delete was refused by the foreign keys.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن حذف العقد: أُضيف إليه شيء منذ فتحه.'**
  String get contractDeleteNotEmpty;

  /// Contract history: an empty date.
  ///
  /// In ar, this message translates to:
  /// **'بدون تاريخ'**
  String get contractNoDate;

  /// Contract history: an empty area.
  ///
  /// In ar, this message translates to:
  /// **'بدون مساحة'**
  String get contractNoArea;

  /// Contract history: an empty tenant.
  ///
  /// In ar, this message translates to:
  /// **'بدون مستأجر'**
  String get contractNoParty;

  /// Contract history: a tenant the viewer cannot see.
  ///
  /// In ar, this message translates to:
  /// **'مستأجر آخر'**
  String get contractOtherParty;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'أنشأ العقد'**
  String get contractHistCreated;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'أضاف ملحق {number}'**
  String contractHistAddedAnnex(String number);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'أضاف عقد مخزن'**
  String get contractHistAddedStorage;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'حذف ملحق {number}'**
  String contractHistDeletedAnnex(String number);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'حذف عقد مخزن'**
  String get contractHistDeletedStorage;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'فعّل العقد'**
  String get contractHistActivated;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'أنهى العقد: {reason}'**
  String contractHistTerminated(String reason);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'أعاد تفعيل العقد'**
  String get contractHistReopened;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'غيّر المستأجر من {from} إلى {to}'**
  String contractHistParty(String from, String to);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'غيّر البراند من {from} إلى {to}'**
  String contractHistBrand(String from, String to);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'غيّر تاريخ العقد من {from} إلى {to}'**
  String contractHistSigned(String from, String to);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'غيّر تاريخ البداية من {from} إلى {to}'**
  String contractHistStarts(String from, String to);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'غيّر تاريخ النهاية من {from} إلى {to}'**
  String contractHistEnds(String from, String to);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'عدّل ملاحظة التاريخ'**
  String get contractHistDateNote;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'غيّر المساحة الداخلية من {from} إلى {to}'**
  String contractHistAreaInner(String from, String to);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'غيّر المساحة الخارجية من {from} إلى {to}'**
  String contractHistAreaOuter(String from, String to);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'عدّل ملاحظة المساحة'**
  String get contractHistAreaNote;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'عدّل موضوع العقد'**
  String get contractHistSubject;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'عدّل النشاط'**
  String get contractHistActivity;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'عدّل الملاحظات'**
  String get contractHistNotes;

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'أضاف الوحدة {code}'**
  String contractHistUnitAdded(String code);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'أزال الوحدة {code}'**
  String contractHistUnitRemoved(String code);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'أضاف نقصًا: {label}'**
  String contractHistItemAdded(String label);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'استوفى: {label}'**
  String contractHistItemResolved(String label);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'أعاد فتح: {label}'**
  String contractHistItemReopened(String label);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'حذف نقصًا: {label}'**
  String contractHistItemDeleted(String label);

  /// Contract history: a checklist row about an item on an annex or storage contract. line is «أضاف نقصًا: …» and the like; target is «ملحق ٢» or «مخزن …», as in the checklist.
  ///
  /// In ar, this message translates to:
  /// **'{line} على {target}'**
  String contractHistItemOn(String line, String target);

  /// Contract history: the target of a checklist row on a storage contract that is no longer loaded.
  ///
  /// In ar, this message translates to:
  /// **'عقد المخزن'**
  String get contractHistItemOnStorage;

  /// Contract drawer: the annexes section title.
  ///
  /// In ar, this message translates to:
  /// **'الملاحق ({count})'**
  String contractAnnexesTitle(String count);

  /// Contract drawer: opens the annex form.
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة ملحق'**
  String get contractAddAnnex;

  /// Contract drawer: the storage contracts section title.
  ///
  /// In ar, this message translates to:
  /// **'المخازن ({count})'**
  String contractStorageTitle(String count);

  /// Contract drawer: opens the contract form as a storage contract under this lease.
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة عقد مخزن'**
  String get contractAddStorage;

  /// Contract drawer: a storage contract filled in one year on.
  ///
  /// In ar, this message translates to:
  /// **'تجديد للموسم التالي'**
  String get storageRenew;

  /// Contract drawer: an annex row starts with its number.
  ///
  /// In ar, this message translates to:
  /// **'ملحق {number}'**
  String annexRowTitle(String number);

  /// Contract drawer: what an annex changes.
  ///
  /// In ar, this message translates to:
  /// **'النهاية ← {date}'**
  String annexChangeEnds(String date);

  /// Contract drawer: what an annex changes.
  ///
  /// In ar, this message translates to:
  /// **'المساحة الداخلية ← {area}'**
  String annexChangeAreaInner(String area);

  /// Contract drawer: what an annex changes.
  ///
  /// In ar, this message translates to:
  /// **'المساحة الخارجية ← {area}'**
  String annexChangeAreaOuter(String area);

  /// Contract drawer: what an annex changes; the tenant name follows in its own text.
  ///
  /// In ar, this message translates to:
  /// **'المستأجر ←'**
  String get annexChangeParty;

  /// Contract drawer: what an annex changes; the unit codes follow in their own text.
  ///
  /// In ar, this message translates to:
  /// **'الوحدات ←'**
  String get annexChangeUnits;

  /// Annex form title.
  ///
  /// In ar, this message translates to:
  /// **'ملحق جديد'**
  String get annexNewTitle;

  /// Annex form title.
  ///
  /// In ar, this message translates to:
  /// **'تعديل ملحق'**
  String get annexEditTitle;

  /// Annex form field.
  ///
  /// In ar, this message translates to:
  /// **'رقم الملحق'**
  String get annexFieldNo;

  /// Annex form field.
  ///
  /// In ar, this message translates to:
  /// **'موضوع الملحق'**
  String get annexFieldSubject;

  /// Annex form field.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الملحق'**
  String get annexFieldSigned;

  /// Annex form: the toggles title.
  ///
  /// In ar, this message translates to:
  /// **'ما الذي يغيّره الملحق؟'**
  String get annexChangesLabel;

  /// Annex form toggle: the annex moves the contract to another tenant.
  ///
  /// In ar, this message translates to:
  /// **'المستأجر (تنازل)'**
  String get annexToggleParty;

  /// Annex form button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الملحق'**
  String get annexSave;

  /// Annex form: the number is empty or zero.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقمًا أكبر من صفر.'**
  String get annexNoInvalid;

  /// Annex form: the server refused a duplicate number.
  ///
  /// In ar, this message translates to:
  /// **'يوجد ملحق بهذا الرقم.'**
  String get annexDuplicateNo;

  /// Annex form error.
  ///
  /// In ar, this message translates to:
  /// **'رفض الخادم هذه القيم. تحقق من الوحدات والتواريخ.'**
  String get annexSaveRejected;

  /// Annex form error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الملحق. حاول مرة أخرى.'**
  String get annexSaveUnknown;

  /// Annex form: leaving a new annex with changes.
  ///
  /// In ar, this message translates to:
  /// **'لن يُحفظ هذا الملحق.'**
  String get annexDiscardBody;

  /// Annex form: leaving an edit with changes.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحفظ التعديلات على الملحق.'**
  String get annexDiscardEditBody;

  /// Annex form: an annex made by mistake, with nothing on it.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملحق'**
  String get annexDelete;

  /// Annex delete dialog.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملحق؟'**
  String get annexDeleteTitle;

  /// Annex delete dialog.
  ///
  /// In ar, this message translates to:
  /// **'يُحذف هذا الملحق نهائيًا، ولا يمكن استرجاعه.'**
  String get annexDeleteBody;

  /// Annex form: the foreign keys refused the delete.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن حذف الملحق: أُضيف إليه شيء منذ فتحه.'**
  String get annexDeleteNotEmpty;

  /// Contract form: a storage contract under a lease made by mistake.
  ///
  /// In ar, this message translates to:
  /// **'حذف عقد المخزن'**
  String get storageDelete;

  /// Storage delete dialog.
  ///
  /// In ar, this message translates to:
  /// **'حذف عقد المخزن؟'**
  String get storageDeleteTitle;

  /// Storage delete dialog.
  ///
  /// In ar, this message translates to:
  /// **'يُحذف عقد المخزن هذا نهائيًا، ولا يمكن استرجاعه.'**
  String get storageDeleteBody;

  /// Contract form: the foreign keys refused the delete.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن حذف عقد المخزن: أُضيف إليه شيء منذ فتحه.'**
  String get storageDeleteNotEmpty;

  /// Contract history: a change to an annex, with the change worded as for the contract.
  ///
  /// In ar, this message translates to:
  /// **'ملحق {number}: {line}'**
  String contractHistOnAnnex(String number, String line);

  /// Contract history: a change to a storage contract.
  ///
  /// In ar, this message translates to:
  /// **'عقد المخزن: {line}'**
  String contractHistOnStorage(String line);

  /// Contract history: an annex was added.
  ///
  /// In ar, this message translates to:
  /// **'أضاف ملحق {number}: {subject}'**
  String contractHistAddedAnnexSubject(String number, String subject);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'غيّر رقم الملحق من {from} إلى {to}'**
  String contractHistAnnexNo(String from, String to);

  /// Contract history.
  ///
  /// In ar, this message translates to:
  /// **'عدّل موضوع الملحق'**
  String get contractHistAnnexSubject;

  /// Contract drawer: the checklist section title; count is the open items.
  ///
  /// In ar, this message translates to:
  /// **'النواقص والمستندات ({count})'**
  String contractChecklistTitle(String count);

  /// Contract drawer checklist: the documents group.
  ///
  /// In ar, this message translates to:
  /// **'مستندات مطلوبة من المستأجر'**
  String get checklistDocumentsTitle;

  /// Contract drawer checklist: under the documents group title.
  ///
  /// In ar, this message translates to:
  /// **'تخص كل عقود هذا المستأجر'**
  String get checklistDocumentsNote;

  /// Contract drawer checklist: the missing signatures and stamps group.
  ///
  /// In ar, this message translates to:
  /// **'نواقص التوقيع والختم'**
  String get checklistMissingTitle;

  /// Contract drawer checklist: opens the inline row for a document.
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة مستند'**
  String get checklistAddDocument;

  /// Contract drawer checklist: opens the inline row for a missing signature or stamp.
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة نقص'**
  String get checklistAddMissing;

  /// Contract drawer checklist: the documents group is empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مستندات مطلوبة'**
  String get checklistNoDocuments;

  /// Contract drawer checklist: the missing items group is empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نواقص'**
  String get checklistNoMissing;

  /// Contract drawer checklist: shows a group's resolved items.
  ///
  /// In ar, this message translates to:
  /// **'عرض المستوفاة ({count})'**
  String checklistShowResolved(String count);

  /// Contract drawer checklist: hides a group's resolved items.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء المستوفاة ({count})'**
  String checklistHideResolved(String count);

  /// Contract drawer checklist: a missing signature (pill and toggle chip).
  ///
  /// In ar, this message translates to:
  /// **'توقيع'**
  String get checklistSignature;

  /// Contract drawer checklist: a missing stamp (pill and toggle chip).
  ///
  /// In ar, this message translates to:
  /// **'ختم'**
  String get checklistStamp;

  /// Contract drawer checklist: the signature or stamp is missing on our side (pill and toggle chip).
  ///
  /// In ar, this message translates to:
  /// **'من جانبنا'**
  String get checklistOurSide;

  /// Contract drawer checklist: under an item on an annex or storage contract. target is «ملحق ٢» or «مخزن …».
  ///
  /// In ar, this message translates to:
  /// **'على {target}'**
  String checklistOn(String target);

  /// Contract drawer checklist: the select of where a missing item goes.
  ///
  /// In ar, this message translates to:
  /// **'على'**
  String get checklistOnLabel;

  /// Contract drawer checklist: the «على» choice for the contract itself.
  ///
  /// In ar, this message translates to:
  /// **'العقد'**
  String get checklistOnContract;

  /// Contract drawer checklist: a storage contract as a place for a missing item. codes are its unit codes.
  ///
  /// In ar, this message translates to:
  /// **'مخزن {codes}'**
  String checklistOnStorage(String codes);

  /// Contract drawer checklist: a storage contract with its signing year, telling renewals apart.
  ///
  /// In ar, this message translates to:
  /// **'مخزن {codes} · {year}'**
  String checklistOnStorageSeason(String codes, String year);

  /// Contract drawer checklist: the label field, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'البند'**
  String get checklistLabelField;

  /// Contract drawer checklist: the label field's hint for a document.
  ///
  /// In ar, this message translates to:
  /// **'مثل: سجل تجاري حديث'**
  String get checklistDocumentHint;

  /// Contract drawer checklist: the label field's hint for a missing item.
  ///
  /// In ar, this message translates to:
  /// **'مثل: محضر الاستلام'**
  String get checklistMissingHint;

  /// Contract drawer checklist: the detail field, for screen readers.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get checklistDetailField;

  /// Contract drawer checklist: the detail field's hint.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل (اختياري)'**
  String get checklistDetailHint;

  /// Contract drawer checklist: a missing item needs at least one.
  ///
  /// In ar, this message translates to:
  /// **'اختر التوقيع أو الختم.'**
  String get checklistNeedsOne;

  /// Contract drawer checklist: saves the inline row.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get checklistAdd;

  /// Contract drawer checklist: the × on an open item (tooltip).
  ///
  /// In ar, this message translates to:
  /// **'حذف البند'**
  String get checklistDelete;

  /// Contract drawer checklist: the delete confirmation's title.
  ///
  /// In ar, this message translates to:
  /// **'حذف البند؟'**
  String get checklistDeleteTitle;

  /// Contract drawer checklist: the delete confirmation's body.
  ///
  /// In ar, this message translates to:
  /// **'يُحذف هذا البند من القائمة نهائيًا. للبند المستوفى، علّمه بدلًا من حذفه.'**
  String get checklistDeleteBody;

  /// Contract drawer checklist: confirms the delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get checklistDeleteConfirm;

  /// Contract drawer: the follow-up tasks section title; count is the open ones.
  ///
  /// In ar, this message translates to:
  /// **'المتابعات ({count})'**
  String contractFollowUpsTitle(String count);

  /// Contract drawer: opens the new-task modal for this contract.
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة متابعة'**
  String get contractAddFollowUp;

  /// New-task modal from a contract: the title it starts with while the client owes a signature or stamp.
  ///
  /// In ar, this message translates to:
  /// **'التواصل مع العميل لتوقيع وختم النواقص'**
  String get followUpDefaultTitle;

  /// New-task modal from a contract: the fixed contract line's label.
  ///
  /// In ar, this message translates to:
  /// **'العقد'**
  String get newTaskContractLabel;

  /// Change history, after the actor's name: the task was linked to a contract.
  ///
  /// In ar, this message translates to:
  /// **'ربط المهمة بعقد'**
  String get activityContractLinked;

  /// Change history, after the actor's name: the task's contract link was removed.
  ///
  /// In ar, this message translates to:
  /// **'ألغى ربط المهمة بالعقد'**
  String get activityContractUnlinked;

  /// The «العقود» filter row's menu button: export or print the contracts the list shows.
  ///
  /// In ar, this message translates to:
  /// **'تصدير'**
  String get contractExport;

  /// Export menu item: download the shown contracts as an Excel workbook.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل ملف Excel'**
  String get contractExportXlsx;

  /// Export menu item: print the shown contracts.
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get contractExportPrint;

  /// Snackbar when the export or print failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تصدير العقود.'**
  String get contractExportError;

  /// The downloaded workbook's name, without the extension. file is the file's name or «كل الملفات»; date is yyyy-mm-dd.
  ///
  /// In ar, this message translates to:
  /// **'عقود {file} {date}'**
  String contractExportFileName(String file, String date);

  /// Exported register, column A header: the row number.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get registerHeaderNumber;

  /// Exported register, column B header: the tenant.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستأجر'**
  String get registerHeaderTenant;

  /// Exported register, column C header: the brand.
  ///
  /// In ar, this message translates to:
  /// **'الاسم التجاري'**
  String get registerHeaderBrand;

  /// Exported register, column D header: the unit codes.
  ///
  /// In ar, this message translates to:
  /// **'رقم الوحدة/ الكشك'**
  String get registerHeaderUnits;

  /// Exported register, column E header: the activity.
  ///
  /// In ar, this message translates to:
  /// **'النشاط'**
  String get registerHeaderActivity;

  /// Exported register, column F header: the contract's or annex's subject.
  ///
  /// In ar, this message translates to:
  /// **'موضوع العقد او الملحق'**
  String get registerHeaderSubject;

  /// Exported register, column G header: the signing date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ العقد او الملحق'**
  String get registerHeaderSignedOn;

  /// Exported register, column H header: the end date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ انتهاء العقد'**
  String get registerHeaderEndsOn;

  /// Exported register, column I header: the duration.
  ///
  /// In ar, this message translates to:
  /// **'مدة الإيجار في العقد'**
  String get registerHeaderDuration;

  /// Exported register, column J header: the inner area. Worded as in the firm's workbook.
  ///
  /// In ar, this message translates to:
  /// **'مساحه داخليه\n(متر مربع)'**
  String get registerHeaderAreaInner;

  /// Exported register, column K header: the outer area. Worded as in the firm's workbook.
  ///
  /// In ar, this message translates to:
  /// **'مساحه خارجيه\n(متر مربع)'**
  String get registerHeaderAreaOuter;

  /// Exported register, column L header: the tenant's open required documents.
  ///
  /// In ar, this message translates to:
  /// **'(المستندات المطلوبة)'**
  String get registerHeaderDocuments;

  /// Exported register, column M header: open missing signatures and stamps.
  ///
  /// In ar, this message translates to:
  /// **'النواقص (توقيع وختم)'**
  String get registerHeaderMissing;

  /// Exported register, column N header: the notes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get registerHeaderNotes;

  /// Exported register, column O header: open follow-up tasks. Worded as in the firm's workbook.
  ///
  /// In ar, this message translates to:
  /// **'الاجراء المطلوب'**
  String get registerHeaderFollowUps;

  /// Exported register: a season band's title. season is a year in Western digits.
  ///
  /// In ar, this message translates to:
  /// **'بيان بجميع العقود السارية بمشروع {file} لموسم {season}'**
  String registerBandTitle(String file, String season);

  /// Exported register: the title of the band of contracts with no signing date.
  ///
  /// In ar, this message translates to:
  /// **'بيان بالعقود السارية غير المؤرخة بمشروع {file}'**
  String registerBandTitleUndated(String file);

  /// Exported register, terminated sheet: a season band's title. season is a year in Western digits.
  ///
  /// In ar, this message translates to:
  /// **'بيان بالعقود الملغاة بمشروع {file} لموسم {season}'**
  String registerTerminatedBandTitle(String file, String season);

  /// Exported register, terminated sheet: the undated band's title.
  ///
  /// In ar, this message translates to:
  /// **'بيان بالعقود الملغاة غير المؤرخة بمشروع {file}'**
  String registerTerminatedBandTitleUndated(String file);

  /// Exported register: the terminated contracts' sheet name. file may be cut to fit Excel's 31 characters.
  ///
  /// In ar, this message translates to:
  /// **'{file} - الملغاة'**
  String registerTerminatedSheet(String file);

  /// Exported register: an annex row's subject.
  ///
  /// In ar, this message translates to:
  /// **'ملحق {number}: {subject}'**
  String registerAnnexSubject(String number, String subject);

  /// Exported register: an annex row with no subject.
  ///
  /// In ar, this message translates to:
  /// **'ملحق {number}'**
  String registerAnnexOnly(String number);

  /// Exported register: an annex with no number and no subject.
  ///
  /// In ar, this message translates to:
  /// **'ملحق'**
  String get registerAnnexUnnumbered;

  /// Exported register: a storage unit with its key number.
  ///
  /// In ar, this message translates to:
  /// **'{code} (مفتاح {key})'**
  String registerUnitKey(String code, String key);

  /// Exported register: a missing item that needs both a signature and a stamp.
  ///
  /// In ar, this message translates to:
  /// **'توقيع وختم'**
  String get registerNeedsBoth;

  /// Exported register, terminated sheet: the note's start. date is dd/mm/yyyy.
  ///
  /// In ar, this message translates to:
  /// **'أُلغي في {date}'**
  String registerTerminatedOn(String date);

  /// Exported register, terminated sheet: the note's start when there is no termination date.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get registerTerminated;

  /// Exported register: the legend's title.
  ///
  /// In ar, this message translates to:
  /// **'الألوان:'**
  String get registerLegendTitle;

  /// Exported register legend: an expired end date (red).
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get registerLegendExpired;

  /// Exported register legend: an end date within 90 days (amber). Western digits, as in the register.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي خلال 90 يومًا'**
  String get registerLegendEnding;

  /// Exported register legend: an annex row's tint.
  ///
  /// In ar, this message translates to:
  /// **'ملحق'**
  String get registerLegendAnnex;

  /// Exported register legend: a storage contract row's tint.
  ///
  /// In ar, this message translates to:
  /// **'عقد مخزن'**
  String get registerLegendStorage;
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
