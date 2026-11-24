// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Legal Department System';

  @override
  String get statusTodo => 'Not started';

  @override
  String get statusDoing => 'In progress';

  @override
  String get statusWaiting => 'Waiting for reply';

  @override
  String get statusDone => 'Done';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginForgotHelp =>
      'Forgot your password? Contact the system administrator.';

  @override
  String get loginErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get loginErrorRateLimited =>
      'Too many attempts. Try again in a moment.';

  @override
  String get loginErrorNetwork =>
      'Can\'t reach the server. Check the network and try again.';

  @override
  String get loginErrorUnknown => 'Something went wrong. Try again.';

  @override
  String get authAccountDisabled =>
      'This account is disabled. Contact the system administrator.';

  @override
  String get signOut => 'Sign out';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get counterUrgent => 'Urgent';

  @override
  String get counterOverdue => 'Overdue';

  @override
  String get counterOpen => 'Open';

  @override
  String get allFiles => 'All files';

  @override
  String get fileFilterLabel => 'Filter by file';

  @override
  String get sectionUrgentTitle => 'Urgent — due today';

  @override
  String get sectionUrgentCaption =>
      'Overdue first, then due today or marked urgent';

  @override
  String get sectionUpcomingTitle => 'Upcoming';

  @override
  String get sectionUpcomingCaption => 'Sorted by nearest due date';

  @override
  String get sectionClosedTitle => 'Completed';

  @override
  String get emptyUrgent => 'No urgent tasks today';

  @override
  String get emptyUpcoming => 'No upcoming tasks';

  @override
  String showClosed(String count) {
    return 'Show completed ($count)';
  }

  @override
  String hideClosed(String count) {
    return 'Hide completed ($count)';
  }

  @override
  String get flagOverdue => 'Overdue';

  @override
  String get flagUrgent => 'Urgent';

  @override
  String get dueToday => 'Today';

  @override
  String get dueTomorrow => 'Tomorrow';

  @override
  String dueOverdueSince(String days) {
    return 'Overdue by $days';
  }

  @override
  String dueIn(String days) {
    return 'In $days';
  }

  @override
  String get dayOne => '1 day';

  @override
  String get dayTwo => '2 days';

  @override
  String daysFew(String count) {
    return '$count days';
  }

  @override
  String daysMany(String count) {
    return '$count days';
  }

  @override
  String updatesCount(String count) {
    return 'Updates: $count';
  }

  @override
  String get formerEmployee => 'Former employee';

  @override
  String get tasksLoadError => 'Couldn\'t load the tasks.';

  @override
  String get retry => 'Try again';

  @override
  String get drawerClose => 'Close';

  @override
  String get drawerStatusLabel => 'Status';

  @override
  String get drawerAssigneeLabel => 'Assignee';

  @override
  String get drawerDueLabel => 'Due date';

  @override
  String get drawerContractLabel => 'Contract';

  @override
  String get drawerPickDue => 'Pick the due date';

  @override
  String get drawerManualUrgent => 'Mark as urgent';

  @override
  String get urgentNoteDone => 'The task is done.';

  @override
  String get urgentNoteCancelled => 'The task is cancelled.';

  @override
  String get urgentNoteOverdue =>
      'Urgent automatically: the due date has passed.';

  @override
  String get urgentNoteToday => 'Urgent automatically: it is due today.';

  @override
  String get urgentNoteManual =>
      'Marked urgent by hand; it shows at the top of the list.';

  @override
  String get urgentNoteLater => 'Becomes urgent automatically on its due date.';

  @override
  String get drawerDescriptionLabel => 'Description';

  @override
  String get drawerUpdatesLabel => 'Updates — where we are';

  @override
  String get drawerNoUpdates => 'No updates yet';

  @override
  String get updateFieldLabel => 'Add an update';

  @override
  String get updateHint => 'Write where the task has got to…';

  @override
  String get updateAdd => 'Add update';

  @override
  String get updateErrorNotAllowed => 'You can\'t post an update on this task.';

  @override
  String get updateErrorUnknown => 'Couldn\'t add the update. Try again.';

  @override
  String get drawerLoadError => 'Couldn\'t load the task.';

  @override
  String get saveErrorNotAllowed => 'You can\'t edit this task.';

  @override
  String get saveErrorAssignee => 'The task can\'t be assigned to this person.';

  @override
  String get saveErrorUnknown => 'Couldn\'t save the change. Try again.';

  @override
  String get cancelTask => 'Cancel task';

  @override
  String get cancelTaskTitle => 'Cancel the task?';

  @override
  String get cancelTaskBody =>
      'The task moves to the closed list as cancelled. It can be reopened later.';

  @override
  String get cancelTaskBack => 'Back';

  @override
  String get editTask => 'Edit';

  @override
  String get editTitleLabel => 'Task title';

  @override
  String get editSave => 'Save';

  @override
  String get editCancel => 'Cancel';

  @override
  String get discardEditTitle => 'Discard your changes?';

  @override
  String get discardEditBody =>
      'The changes to the title and description won\'t be saved.';

  @override
  String get discardEditBack => 'Keep editing';

  @override
  String get discardEditConfirm => 'Discard';

  @override
  String get discardUpdateTitle => 'Discard the update?';

  @override
  String get discardUpdateBody => 'The update you wrote won\'t be saved.';

  @override
  String get discardUpdateBack => 'Keep writing';

  @override
  String get discardAllTitle => 'Discard what you wrote?';

  @override
  String get discardAllBody =>
      'The changes to the title and description, and the update you wrote, won\'t be saved.';

  @override
  String get timeNow => 'Just now';

  @override
  String timeAgo(String time) {
    return '$time ago';
  }

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String get minuteOne => '1 minute';

  @override
  String get minuteTwo => '2 minutes';

  @override
  String minutesFew(String count) {
    return '$count minutes';
  }

  @override
  String minutesMany(String count) {
    return '$count minutes';
  }

  @override
  String get hourOne => '1 hour';

  @override
  String get hourTwo => '2 hours';

  @override
  String hoursFew(String count) {
    return '$count hours';
  }

  @override
  String hoursMany(String count) {
    return '$count hours';
  }

  @override
  String get searchHint => 'Search tasks…';

  @override
  String get searchLabel => 'Search tasks';

  @override
  String get searchClear => 'Clear search';

  @override
  String searchResultOne(String term) {
    return '1 result for \"$term\"';
  }

  @override
  String searchResultTwo(String term) {
    return '2 results for \"$term\"';
  }

  @override
  String searchResultsFew(String count, String term) {
    return '$count results for \"$term\"';
  }

  @override
  String searchResultsMany(String count, String term) {
    return '$count results for \"$term\"';
  }

  @override
  String searchNoResults(String term) {
    return 'No tasks match \"$term\"';
  }

  @override
  String get searchError => 'Couldn\'t search. Try again.';

  @override
  String get viewTabsLabel => 'View';

  @override
  String get tabTasks => 'Tasks & priority';

  @override
  String get tabTopics => 'Topics';

  @override
  String get tabPeople => 'People';

  @override
  String get topicBrandLabel => 'Brand contract';

  @override
  String get topicCountZero => 'No topics';

  @override
  String get topicCountOne => '1 topic';

  @override
  String get topicCountTwo => '2 topics';

  @override
  String topicCountFew(String count) {
    return '$count topics';
  }

  @override
  String topicCountMany(String count) {
    return '$count topics';
  }

  @override
  String get openTaskCountZero => 'No open tasks';

  @override
  String get openTaskCountOne => '1 open task';

  @override
  String get openTaskCountTwo => '2 open tasks';

  @override
  String openTaskCountFew(String count) {
    return '$count open tasks';
  }

  @override
  String openTaskCountMany(String count) {
    return '$count open tasks';
  }

  @override
  String urgentCountLabel(String count) {
    return '$count urgent';
  }

  @override
  String topicProgress(String done, String total) {
    return 'Done: $done of $total';
  }

  @override
  String get topicNoTasks => 'No tasks yet';

  @override
  String get topicNoOpenTasks => 'No open tasks';

  @override
  String get fileNoTopics => 'This file has no topics';

  @override
  String get peopleEmptyFile => 'Nobody works on this file';

  @override
  String get peopleEmpty => 'No people yet';

  @override
  String get newFileButton => 'New file';

  @override
  String get editName => 'Edit';

  @override
  String editFileSemantics(String name) {
    return 'Rename file $name';
  }

  @override
  String get editTopicTooltip => 'Rename topic';

  @override
  String editTopicSemantics(String name) {
    return 'Rename topic $name';
  }

  @override
  String get newTopicCard => 'New topic';

  @override
  String newTopicSemantics(String file) {
    return 'Add a topic to $file';
  }

  @override
  String get nameModalNewFile => 'New file';

  @override
  String get nameModalRenameFile => 'Rename file';

  @override
  String get nameModalNewTopic => 'New topic';

  @override
  String get nameModalRenameTopic => 'Rename topic';

  @override
  String nameModalFileLine(String file) {
    return 'File: $file';
  }

  @override
  String get fileNameLabel => 'File name';

  @override
  String get topicNameLabel => 'Topic (brand) name';

  @override
  String get fileNameHint => 'e.g. City Centre';

  @override
  String get topicNameHint => 'e.g. Lemona Café';

  @override
  String get nameErrorDuplicateFile => 'A file with this name already exists.';

  @override
  String get nameErrorDuplicateTopic =>
      'This file already has a topic with this name.';

  @override
  String get nameErrorNotAllowed =>
      'You don\'t have permission to change files and topics.';

  @override
  String get nameErrorUnknown => 'Couldn\'t save. Try again.';

  @override
  String get deleteFile => 'Delete file';

  @override
  String get deleteTopic => 'Delete topic';

  @override
  String deleteFileSemantics(String name) {
    return 'Delete file $name';
  }

  @override
  String deleteTopicSemantics(String name) {
    return 'Delete topic $name';
  }

  @override
  String deleteFileTitle(String name) {
    return 'Delete the file $name?';
  }

  @override
  String deleteTopicTitle(String name) {
    return 'Delete the topic $name?';
  }

  @override
  String get deleteNameBody => 'It is deleted for good. This can\'t be undone.';

  @override
  String get deleteNameConfirm => 'Delete';

  @override
  String get nameErrorFileNotEmpty =>
      'Topics were added to this file, so it can no longer be deleted.';

  @override
  String get nameErrorTopicNotEmpty =>
      'Tasks were added to this topic, so it can no longer be deleted.';

  @override
  String get headerUsers => 'Users';

  @override
  String get usersTitle => 'Users';

  @override
  String get usersBack => 'Back';

  @override
  String get usersNew => 'New user';

  @override
  String get usersLoadFailed => 'Couldn\'t load the users.';

  @override
  String get roleLawyer => 'Lawyer';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get userInactive => 'Deactivated';

  @override
  String get userFileCountZero => 'No files';

  @override
  String get userFileCountOne => '1 file';

  @override
  String get userFileCountTwo => '2 files';

  @override
  String userFileCountFew(String count) {
    return '$count files';
  }

  @override
  String userFileCountMany(String count) {
    return '$count files';
  }

  @override
  String get userModalNew => 'New user';

  @override
  String get userModalEdit => 'Edit user';

  @override
  String get userNameLabel => 'Name';

  @override
  String get userNameHint => 'e.g. Nour Hassan';

  @override
  String get userPasswordHint => 'At least 8 characters';

  @override
  String get userRoleLabel => 'Role';

  @override
  String get userFilesLabel => 'Files';

  @override
  String get userFilesAll => 'Managers and administrators see every file.';

  @override
  String get userFilesNone => 'There are no files yet.';

  @override
  String get userSelfNote =>
      'You can\'t change your own role or deactivate your own account.';

  @override
  String get userAccountLabel => 'Account';

  @override
  String get userSetPassword => 'Set a new password';

  @override
  String get userPasswordSet => 'The new password is set.';

  @override
  String get userDeactivate => 'Deactivate account';

  @override
  String get userReactivate => 'Reactivate account';

  @override
  String get userIsInactive =>
      'This account is deactivated and can\'t sign in.';

  @override
  String userDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get userDeactivateBody =>
      'This user won\'t be able to sign in until the account is reactivated. Tasks and updates stay as they are.';

  @override
  String get userDiscardBody => 'Your changes to this user won\'t be saved.';

  @override
  String get passwordModalTitle => 'New password';

  @override
  String passwordModalUserLine(String name) {
    return 'User: $name';
  }

  @override
  String get passwordModalLabel => 'New password';

  @override
  String get userErrorNotAllowed =>
      'You don\'t have permission to manage users.';

  @override
  String get userErrorOpenTasks =>
      'This user has open tasks. Reassign them first.';

  @override
  String get userErrorOpenTasksInFile =>
      'This user has open tasks in a file you unticked. Reassign them first.';

  @override
  String get userErrorOpenTasksOutsideFiles =>
      'This user has open tasks in files that aren\'t ticked. Tick them or reassign the tasks first.';

  @override
  String get userErrorEmailTaken =>
      'An account with this email already exists.';

  @override
  String get userErrorWeakPassword =>
      'The password is too short. Use at least 8 characters.';

  @override
  String get newTask => 'New task';

  @override
  String get newTaskTitleHint => 'e.g. Review the contract addendum';

  @override
  String get newTaskFileLabel => 'File';

  @override
  String get newTaskTopicLabel => 'Topic (brand)';

  @override
  String get newTaskAssigneeHint => 'Choose a person';

  @override
  String get newTaskUrgent => 'Urgent (due today)';

  @override
  String get newTaskUrgentHelp =>
      'A task becomes urgent automatically on its due date.';

  @override
  String get newTaskSave => 'Save task';

  @override
  String get newTaskDiscardBody => 'This task won\'t be saved.';

  @override
  String get newTaskErrorNotAllowed =>
      'You don\'t have permission to create a task in this file.';

  @override
  String get newTaskErrorUnknown => 'Couldn\'t save the task. Try again.';

  @override
  String showActivity(String count) {
    return 'Show change history ($count)';
  }

  @override
  String hideActivity(String count) {
    return 'Hide change history ($count)';
  }

  @override
  String get activitySystem => 'System';

  @override
  String get activityCreated => 'created the task';

  @override
  String activityStatus(String from, String to) {
    return 'changed the status from $from to $to';
  }

  @override
  String activityAssignee(String from, String to) {
    return 'changed the assignee from $from to $to';
  }

  @override
  String activityDueDate(String from, String to) {
    return 'changed the due date from $from to $to';
  }

  @override
  String get activityUrgentOn => 'marked it urgent';

  @override
  String get activityUrgentOff => 'unmarked it as urgent';

  @override
  String get activityTitle => 'changed the title';

  @override
  String activityOldTitle(String title) {
    return 'Old title: $title';
  }

  @override
  String activityNewTitle(String title) {
    return 'New title: $title';
  }

  @override
  String get activityDescription => 'edited the description';

  @override
  String activityTopic(String to) {
    return 'moved the task to topic $to';
  }

  @override
  String get activityOtherTopic => 'another';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notificationsBellUnread(String count) {
    return 'Notifications: $count';
  }

  @override
  String get notificationsUnreadOne => 'one unread notification';

  @override
  String get notificationsUnreadTwo => 'two unread notifications';

  @override
  String notificationsUnreadFew(String count) {
    return '$count unread notifications';
  }

  @override
  String notificationsUnreadMany(String count) {
    return '$count unread notifications';
  }

  @override
  String notificationsBadgeMore(String count) {
    return '$count+';
  }

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get notificationsLoadError => 'Could not load notifications.';

  @override
  String get notificationAssigned => 'assigned you a task';

  @override
  String get notificationUpdatePosted => 'posted an update';

  @override
  String get notificationChanged => 'changed the task';

  @override
  String get notificationTaskGone => 'This task is no longer available';

  @override
  String get notificationUnread => 'unread';

  @override
  String get tabContracts => 'Contracts';

  @override
  String get contractsSearchHint => 'Search contracts…';

  @override
  String get contractsSearchLabel => 'Search contracts';

  @override
  String get contractFilterKindLabel => 'Type';

  @override
  String get contractFilterStatusLabel => 'Status';

  @override
  String get contractFilterSeasonLabel => 'Season';

  @override
  String get contractKindAll => 'All types';

  @override
  String get contractKindUnits => 'Units';

  @override
  String get contractKindStorage => 'Storage';

  @override
  String get contractKindServicesOther => 'Services and other';

  @override
  String get contractStatusAll => 'All statuses';

  @override
  String get contractStatusInForce => 'In force';

  @override
  String get contractStatusEnding => 'Ending within 90 days';

  @override
  String get contractStatusExpired => 'Expired';

  @override
  String get contractMissingOnly => 'Has missing items';

  @override
  String get contractSeasonAll => 'All seasons';

  @override
  String get contractListActive => 'In force';

  @override
  String get contractListEnding => 'Ending soon';

  @override
  String get contractListExpired => 'Expired';

  @override
  String get contractListTerminated => 'Terminated';

  @override
  String get contractNoBrand => 'No brand';

  @override
  String contractEndsOn(String date) {
    return 'Until $date';
  }

  @override
  String contractMoreUnits(String count) {
    return '+ $count';
  }

  @override
  String get annexCountOne => '1 annex';

  @override
  String get annexCountTwo => '2 annexes';

  @override
  String annexCountFew(String count) {
    return '$count annexes';
  }

  @override
  String annexCountMany(String count) {
    return '$count annexes';
  }

  @override
  String get storageCountOne => '1 storage';

  @override
  String get storageCountTwo => '2 storage';

  @override
  String storageCountFew(String count) {
    return '$count storage';
  }

  @override
  String storageCountMany(String count) {
    return '$count storage';
  }

  @override
  String get followUpCountOne => '1 follow-up';

  @override
  String get followUpCountTwo => '2 follow-ups';

  @override
  String followUpCountFew(String count) {
    return '$count follow-ups';
  }

  @override
  String followUpCountMany(String count) {
    return '$count follow-ups';
  }

  @override
  String get missingCountOne => '1 missing';

  @override
  String get missingCountTwo => '2 missing';

  @override
  String missingCountFew(String count) {
    return '$count missing';
  }

  @override
  String missingCountMany(String count) {
    return '$count missing';
  }

  @override
  String get contractCountOne => '1 contract';

  @override
  String get contractCountTwo => '2 contracts';

  @override
  String contractCountFew(String count) {
    return '$count contracts';
  }

  @override
  String contractCountMany(String count) {
    return '$count contracts';
  }

  @override
  String contractsEndingLabel(String count) {
    return '$count ending within 90 days';
  }

  @override
  String contractsMissingLabel(String count) {
    return '$count with missing items';
  }

  @override
  String showTerminated(String count) {
    return 'Show terminated ($count)';
  }

  @override
  String hideTerminated(String count) {
    return 'Hide terminated ($count)';
  }

  @override
  String get contractsEmptyFile => 'No contracts in this file';

  @override
  String get contractsEmpty => 'No contracts yet';

  @override
  String get contractsNoFilterMatches => 'No contracts match these choices';

  @override
  String get contractsClearFilters => 'Clear choices';

  @override
  String contractsNoSearchMatches(String term) {
    return 'No contracts match \"$term\"';
  }

  @override
  String get contractsLoadError => 'Couldn\'t load the contracts.';

  @override
  String suggestAdd(String text) {
    return '+ Add \"$text\"';
  }

  @override
  String suggestAddUnits(String count, String codes) {
    return '+ Add $count: $codes';
  }

  @override
  String get suggestPickOrAdd => 'Pick from the list or add a new one';

  @override
  String get suggestCountOne => '1 suggestion';

  @override
  String get suggestCountTwo => '2 suggestions';

  @override
  String suggestCountFew(String count) {
    return '$count suggestions';
  }

  @override
  String suggestCountMany(String count) {
    return '$count suggestions';
  }

  @override
  String suggestRemove(String value) {
    return 'Remove $value';
  }

  @override
  String get suggestAddFailed => 'Couldn\'t add it. Try again.';

  @override
  String get suggestAddNotAllowed => 'You can\'t add to this file.';

  @override
  String get similarPartyTitle => 'A similar tenant exists';

  @override
  String get similarUnitTitle => 'A similar unit exists';

  @override
  String get similarUse => 'Use this';

  @override
  String get similarAddAnyway => 'Add new anyway';

  @override
  String get partyDuplicate => 'A tenant with this name exists.';

  @override
  String get unitDuplicate => 'A unit with this code exists in this file.';

  @override
  String get unitCountOne => '1 unit';

  @override
  String get unitCountTwo => '2 units';

  @override
  String unitCountFew(String count) {
    return '$count units';
  }

  @override
  String unitCountMany(String count) {
    return '$count units';
  }

  @override
  String get unitVacant => 'Vacant';

  @override
  String unitKeyHint(String number) {
    return 'Key $number';
  }

  @override
  String get unitKindShop => 'Shop';

  @override
  String get unitKindKiosk => 'Kiosk';

  @override
  String get unitKindStorage => 'Storage';

  @override
  String get unitKindSpace => 'Space';

  @override
  String get unitKindSite => 'Site';

  @override
  String get unitNewLabel => 'New unit';

  @override
  String get unitKindLabel => 'Unit kind';

  @override
  String get unitKeyNumberLabel => 'Key number';

  @override
  String get unitAdd => 'Add';

  @override
  String get contractNew => 'New contract';

  @override
  String get contractEditTitle => 'Edit contract';

  @override
  String get contractKindLabel => 'Contract kind';

  @override
  String get contractFormKindLease => 'Unit / space lease';

  @override
  String get contractFormKindStorage => 'Storage';

  @override
  String get contractFormKindService => 'Services';

  @override
  String get contractFormKindOther => 'Other';

  @override
  String get contractSubjectLease => 'Unit lease contract';

  @override
  String get contractSubjectStorage => 'Storage lease contract';

  @override
  String get contractFieldBrand => 'Brand';

  @override
  String get contractFieldParty => 'Tenant';

  @override
  String get contractFieldUnits => 'Units';

  @override
  String get contractFieldSubject => 'Subject';

  @override
  String get contractFieldActivity => 'Activity';

  @override
  String get contractFieldSigned => 'Contract date';

  @override
  String get contractFieldStarts => 'Start date';

  @override
  String get contractFieldEnds => 'End date';

  @override
  String get contractFieldAreaInner => 'Inner area';

  @override
  String get contractFieldAreaOuter => 'Outer area';

  @override
  String get contractFieldArea => 'Area';

  @override
  String get contractFieldNotes => 'Notes';

  @override
  String get contractFieldLinked => 'Linked to';

  @override
  String get contractFieldDuration => 'Duration';

  @override
  String get contractFieldTerminated => 'Termination date';

  @override
  String get contractFieldReason => 'Reason';

  @override
  String get contractLinkedHint => 'Optional';

  @override
  String get contractStartsHint => 'Same as the contract date';

  @override
  String get contractPickDate => 'Pick a date';

  @override
  String contractClearDate(String field) {
    return 'Clear $field';
  }

  @override
  String get contractNoEndDate => 'No set end date';

  @override
  String get contractUseEndDate => 'Enter an end date';

  @override
  String get contractAreaAsText => 'The area isn\'t one number';

  @override
  String get contractAreaAsNumber => 'Enter the area as a number';

  @override
  String get contractDateNoteHint => 'e.g. end of the 2028 summer season';

  @override
  String get contractAreaNoteHint => 'e.g. year one 165 / year two 331';

  @override
  String get contractAreaUnit => 'm²';

  @override
  String get contractAreaInvalid => 'Type a number, such as 35,3';

  @override
  String get contractDatesOrder => 'The end date is before the start date.';

  @override
  String get contractSave => 'Save contract';

  @override
  String get contractDiscardBody => 'This contract won\'t be saved.';

  @override
  String get contractDiscardEditBody =>
      'Your changes to the contract won\'t be saved.';

  @override
  String get contractSaveNotAllowed =>
      'You can\'t save a contract in this file.';

  @override
  String get contractSaveRejected =>
      'The server refused these values. Check the brand, units and dates.';

  @override
  String get contractSaveUnknown => 'Couldn\'t save the contract. Try again.';

  @override
  String get contractLoadError => 'Couldn\'t load the contract.';

  @override
  String contractByAnnex(String number) {
    return '(by annex $number)';
  }

  @override
  String get contractValueNone => '—';

  @override
  String contractArea(String area) {
    return '$area m²';
  }

  @override
  String get contractEndsToday => 'Ends today';

  @override
  String contractEndsIn(String time) {
    return 'Ends in $time';
  }

  @override
  String contractEndedAgo(String time) {
    return 'Ended $time ago';
  }

  @override
  String get relDaysOne => '1 day';

  @override
  String get relDaysTwo => '2 days';

  @override
  String relDaysFew(String count) {
    return '$count days';
  }

  @override
  String relDaysMany(String count) {
    return '$count days';
  }

  @override
  String get relMonthsOne => '1 month';

  @override
  String get relMonthsTwo => '2 months';

  @override
  String relMonthsFew(String count) {
    return '$count months';
  }

  @override
  String relMonthsMany(String count) {
    return '$count months';
  }

  @override
  String get relYearsOne => '1 year';

  @override
  String get relYearsTwo => '2 years';

  @override
  String relYearsFew(String count) {
    return '$count years';
  }

  @override
  String relYearsMany(String count) {
    return '$count years';
  }

  @override
  String get durYearsOne => '1 year';

  @override
  String get durYearsTwo => '2 years';

  @override
  String durYearsFew(String count) {
    return '$count years';
  }

  @override
  String durYearsMany(String count) {
    return '$count years';
  }

  @override
  String get durMonthsOne => '1 month';

  @override
  String get durMonthsTwo => '2 months';

  @override
  String durMonthsFew(String count) {
    return '$count months';
  }

  @override
  String durMonthsMany(String count) {
    return '$count months';
  }

  @override
  String durJoin(String years, String months) {
    return '$years and $months';
  }

  @override
  String get contractDelete => 'Delete contract';

  @override
  String get contractDeleteTitle => 'Delete the contract?';

  @override
  String get contractDeleteBody => 'The contract is deleted for good.';

  @override
  String get contractTerminate => 'Terminate contract';

  @override
  String get contractTerminateBody =>
      'The contract moves to terminated. A manager can reactivate it later.';

  @override
  String get contractReasonHint => 'e.g. ended by agreement';

  @override
  String get contractPickTerminated => 'Pick the termination date';

  @override
  String get contractReopen => 'Reactivate';

  @override
  String get contractActionNotAllowed => 'You can\'t change this contract.';

  @override
  String get contractDeleteNotEmpty =>
      'The contract can\'t be deleted: something was added to it since it opened.';

  @override
  String get contractNoDate => 'no date';

  @override
  String get contractNoArea => 'no area';

  @override
  String get contractNoParty => 'no tenant';

  @override
  String get contractOtherParty => 'another tenant';

  @override
  String get contractHistCreated => 'created the contract';

  @override
  String contractHistAddedAnnex(String number) {
    return 'added annex $number';
  }

  @override
  String get contractHistAddedStorage => 'added a storage contract';

  @override
  String contractHistDeletedAnnex(String number) {
    return 'deleted annex $number';
  }

  @override
  String get contractHistDeletedStorage => 'deleted a storage contract';

  @override
  String get contractHistActivated => 'activated the contract';

  @override
  String contractHistTerminated(String reason) {
    return 'terminated the contract: $reason';
  }

  @override
  String get contractHistReopened => 'reactivated the contract';

  @override
  String contractHistParty(String from, String to) {
    return 'changed the tenant from $from to $to';
  }

  @override
  String contractHistBrand(String from, String to) {
    return 'changed the brand from $from to $to';
  }

  @override
  String contractHistSigned(String from, String to) {
    return 'changed the contract date from $from to $to';
  }

  @override
  String contractHistStarts(String from, String to) {
    return 'changed the start date from $from to $to';
  }

  @override
  String contractHistEnds(String from, String to) {
    return 'changed the end date from $from to $to';
  }

  @override
  String get contractHistDateNote => 'edited the date note';

  @override
  String contractHistAreaInner(String from, String to) {
    return 'changed the inner area from $from to $to';
  }

  @override
  String contractHistAreaOuter(String from, String to) {
    return 'changed the outer area from $from to $to';
  }

  @override
  String get contractHistAreaNote => 'edited the area note';

  @override
  String get contractHistSubject => 'edited the subject';

  @override
  String get contractHistActivity => 'edited the activity';

  @override
  String get contractHistNotes => 'edited the notes';

  @override
  String contractHistUnitAdded(String code) {
    return 'added unit $code';
  }

  @override
  String contractHistUnitRemoved(String code) {
    return 'removed unit $code';
  }

  @override
  String contractHistItemAdded(String label) {
    return 'added a missing item: $label';
  }

  @override
  String contractHistItemResolved(String label) {
    return 'resolved: $label';
  }

  @override
  String contractHistItemReopened(String label) {
    return 'reopened: $label';
  }

  @override
  String contractHistItemDeleted(String label) {
    return 'deleted a missing item: $label';
  }

  @override
  String contractHistItemOn(String line, String target) {
    return '$line on $target';
  }

  @override
  String get contractHistItemOnStorage => 'the storage contract';

  @override
  String contractAnnexesTitle(String count) {
    return 'Annexes ($count)';
  }

  @override
  String get contractAddAnnex => '+ Add annex';

  @override
  String contractStorageTitle(String count) {
    return 'Storage ($count)';
  }

  @override
  String get contractAddStorage => '+ Add storage contract';

  @override
  String get storageRenew => 'Renew for next season';

  @override
  String annexRowTitle(String number) {
    return 'Annex $number';
  }

  @override
  String annexChangeEnds(String date) {
    return 'End → $date';
  }

  @override
  String annexChangeAreaInner(String area) {
    return 'Inner area → $area';
  }

  @override
  String annexChangeAreaOuter(String area) {
    return 'Outer area → $area';
  }

  @override
  String get annexChangeParty => 'Tenant →';

  @override
  String get annexChangeUnits => 'Units →';

  @override
  String get annexNewTitle => 'New annex';

  @override
  String get annexEditTitle => 'Edit annex';

  @override
  String get annexFieldNo => 'Annex number';

  @override
  String get annexFieldSubject => 'Annex subject';

  @override
  String get annexFieldSigned => 'Annex date';

  @override
  String get annexChangesLabel => 'What does the annex change?';

  @override
  String get annexToggleParty => 'Tenant (transfer)';

  @override
  String get annexSave => 'Save annex';

  @override
  String get annexNoInvalid => 'Enter a number above zero.';

  @override
  String get annexDuplicateNo =>
      'This contract already has an annex with this number.';

  @override
  String get annexSaveRejected =>
      'The server refused these values. Check the units and dates.';

  @override
  String get annexSaveUnknown => 'Couldn\'t save the annex. Try again.';

  @override
  String get annexDiscardBody => 'This annex won\'t be saved.';

  @override
  String get annexDiscardEditBody =>
      'Your changes to the annex won\'t be saved.';

  @override
  String get annexDelete => 'Delete annex';

  @override
  String get annexDeleteTitle => 'Delete the annex?';

  @override
  String get annexDeleteBody =>
      'This annex is deleted for good and can\'t be restored.';

  @override
  String get annexDeleteNotEmpty =>
      'Can\'t delete the annex: something was added to it since it opened.';

  @override
  String get storageDelete => 'Delete storage contract';

  @override
  String get storageDeleteTitle => 'Delete the storage contract?';

  @override
  String get storageDeleteBody =>
      'This storage contract is deleted for good and can\'t be restored.';

  @override
  String get storageDeleteNotEmpty =>
      'Can\'t delete the storage contract: something was added to it since it opened.';

  @override
  String contractHistOnAnnex(String number, String line) {
    return 'annex $number: $line';
  }

  @override
  String contractHistOnStorage(String line) {
    return 'storage contract: $line';
  }

  @override
  String contractHistAddedAnnexSubject(String number, String subject) {
    return 'added annex $number: $subject';
  }

  @override
  String contractHistAnnexNo(String from, String to) {
    return 'changed the annex number from $from to $to';
  }

  @override
  String get contractHistAnnexSubject => 'edited the annex subject';

  @override
  String contractChecklistTitle(String count) {
    return 'Missing items and documents ($count)';
  }

  @override
  String get checklistDocumentsTitle => 'Documents required from the tenant';

  @override
  String get checklistDocumentsNote => 'For all of this tenant\'s contracts';

  @override
  String get checklistMissingTitle => 'Missing signatures and stamps';

  @override
  String get checklistAddDocument => '+ Add document';

  @override
  String get checklistAddMissing => '+ Add missing item';

  @override
  String get checklistNoDocuments => 'No documents required';

  @override
  String get checklistNoMissing => 'Nothing missing';

  @override
  String checklistShowResolved(String count) {
    return 'Show resolved ($count)';
  }

  @override
  String checklistHideResolved(String count) {
    return 'Hide resolved ($count)';
  }

  @override
  String get checklistSignature => 'Signature';

  @override
  String get checklistStamp => 'Stamp';

  @override
  String get checklistOurSide => 'Our side';

  @override
  String checklistOn(String target) {
    return 'On $target';
  }

  @override
  String get checklistOnLabel => 'On';

  @override
  String get checklistOnContract => 'The contract';

  @override
  String checklistOnStorage(String codes) {
    return 'Storage $codes';
  }

  @override
  String checklistOnStorageSeason(String codes, String year) {
    return 'Storage $codes · $year';
  }

  @override
  String get checklistLabelField => 'Item';

  @override
  String get checklistDocumentHint => 'e.g. recent commercial register';

  @override
  String get checklistMissingHint => 'e.g. handover report';

  @override
  String get checklistDetailField => 'Detail';

  @override
  String get checklistDetailHint => 'Detail (optional)';

  @override
  String get checklistNeedsOne => 'Choose the signature or the stamp.';

  @override
  String get checklistAdd => 'Add';

  @override
  String get checklistDelete => 'Delete item';

  @override
  String get checklistDeleteTitle => 'Delete the item?';

  @override
  String get checklistDeleteBody =>
      'This item is removed from the list for good. For an item that was done, tick it instead.';

  @override
  String get checklistDeleteConfirm => 'Delete';

  @override
  String contractFollowUpsTitle(String count) {
    return 'Follow-ups ($count)';
  }

  @override
  String get contractAddFollowUp => '+ Add follow-up';

  @override
  String get followUpDefaultTitle =>
      'Contact the client to sign and stamp the missing items';

  @override
  String get newTaskContractLabel => 'Contract';

  @override
  String get activityContractLinked => 'linked the task to a contract';

  @override
  String get activityContractUnlinked => 'unlinked the task from its contract';

  @override
  String get contractExport => 'Export';

  @override
  String get contractExportXlsx => 'Download Excel file';

  @override
  String get contractExportPrint => 'Print';

  @override
  String get contractExportError => 'Couldn\'t export the contracts.';

  @override
  String contractExportFileName(String file, String date) {
    return 'Contracts $file $date';
  }

  @override
  String get registerHeaderNumber => 'No.';

  @override
  String get registerHeaderTenant => 'Tenant';

  @override
  String get registerHeaderBrand => 'Brand';

  @override
  String get registerHeaderUnits => 'Unit / kiosk';

  @override
  String get registerHeaderActivity => 'Activity';

  @override
  String get registerHeaderSubject => 'Contract or annex subject';

  @override
  String get registerHeaderSignedOn => 'Contract or annex date';

  @override
  String get registerHeaderEndsOn => 'End date';

  @override
  String get registerHeaderDuration => 'Lease duration';

  @override
  String get registerHeaderAreaInner => 'Inner area\n(m²)';

  @override
  String get registerHeaderAreaOuter => 'Outer area\n(m²)';

  @override
  String get registerHeaderDocuments => '(Required documents)';

  @override
  String get registerHeaderMissing => 'Missing (signature and stamp)';

  @override
  String get registerHeaderNotes => 'Notes';

  @override
  String get registerHeaderFollowUps => 'Action required';

  @override
  String registerBandTitle(String file, String season) {
    return 'All active contracts at $file, season $season';
  }

  @override
  String registerBandTitleUndated(String file) {
    return 'Undated active contracts at $file';
  }

  @override
  String registerTerminatedBandTitle(String file, String season) {
    return 'Terminated contracts at $file, season $season';
  }

  @override
  String registerTerminatedBandTitleUndated(String file) {
    return 'Undated terminated contracts at $file';
  }

  @override
  String registerTerminatedSheet(String file) {
    return '$file - terminated';
  }

  @override
  String registerAnnexSubject(String number, String subject) {
    return 'Annex $number: $subject';
  }

  @override
  String registerAnnexOnly(String number) {
    return 'Annex $number';
  }

  @override
  String get registerAnnexUnnumbered => 'Annex';

  @override
  String registerUnitKey(String code, String key) {
    return '$code (key $key)';
  }

  @override
  String get registerNeedsBoth => 'signature and stamp';

  @override
  String registerTerminatedOn(String date) {
    return 'Terminated on $date';
  }

  @override
  String get registerTerminated => 'Terminated';

  @override
  String get registerLegendTitle => 'Colors:';

  @override
  String get registerLegendExpired => 'Expired';

  @override
  String get registerLegendEnding => 'Ends within 90 days';

  @override
  String get registerLegendAnnex => 'Annex';

  @override
  String get registerLegendStorage => 'Storage contract';
}
