/// Every word this application shows a user, in one place.
///
/// IUX composes no user-facing text — deliberately, and the reason is sound:
/// a framework that invented an English "Back" would ship it untranslated in
/// every application that did not think to override it. The consequence is
/// that this file exists, that it is the largest file in the application by
/// count of declarations, and that adding one control to a screen means adding
/// between one and six entries here.
///
/// It is written as a plain class of constants rather than as an ARB bundle
/// because the pilot has one locale. A real application would generate this
/// from `.arb` files, which changes where the strings live and not how many of
/// them there are.
///
/// The count is the finding. See the mission report.
library;

/// The words this application shows.
abstract final class Strings {
  // ---------------------------------------------------------------- shell

  /// The application's name.
  static const String appName = 'Rounds';

  /// Names the set of destinations for a screen reader entering it.
  static const String navigationLabel = 'Main sections';

  /// The first destination.
  static const String navJobs = 'Visits';

  /// The second destination.
  static const String navNew = 'New visit';

  /// The third destination.
  static const String navSettings = 'Settings';

  /// Announces how many visits are outstanding, on the navigation badge.
  static String outstandingBadge(int count) =>
      '$count visit${count == 1 ? '' : 's'} still to do';

  // ----------------------------------------------------------------- list

  /// The title of the list screen.
  static const String jobsTitle = 'Visits';

  /// Names the operation a screen reader hears while the list loads.
  static const String jobsLoading = 'Loading your visits';

  /// The word that says the block below is a failure, not a note.
  static const String errorCategory = 'Error';

  /// What the user is told when the list could not be fetched.
  static const String jobsLoadFailed =
      'Your visits could not be loaded. The round is stored on this device, so '
      'nothing has been lost.';

  /// The verb on the control that asks again.
  static const String retry = 'Try again';

  /// What a screen reader hears while the retry runs.
  static const String retryBusy = 'Loading your visits again';

  /// The title of the screen with no visits on it at all.
  static const String jobsEmptyTitle = 'No visits on this round yet';

  /// What would put something on the empty screen.
  static const String jobsEmptyGuidance =
      'Visits you add appear here in the order you plan to make them.';

  /// The way out of the empty screen.
  static const String jobsEmptyAction = 'Add the first visit';

  /// The title of the screen when a filter matched nothing.
  static const String jobsNoMatchesTitle = 'No visits match this search';

  /// How to search differently.
  static const String jobsNoMatchesGuidance =
      'Search matches the reference and the address. Try a shorter word.';

  /// The way out of a filtered-to-nothing list.
  static const String jobsNoMatchesAction = 'Clear the search';

  /// Names the search box.
  static const String searchLabel = 'Search visits';

  /// Names the control that empties the search box.
  static const String searchClear = 'Clear the search';

  /// The grey text inside the empty search box.
  static const String searchPlaceholder = 'Reference or address';

  /// Says how many visits are showing, for both audiences.
  static String jobsCount(int shown, int total) => shown == total
      ? '$total visit${total == 1 ? '' : 's'}'
      : '$shown of $total visits';

  /// Names the row for a screen reader, which needs the state as well.
  static String jobRowLabel(String reference, String site, String state) =>
      '$reference, $site, $state';

  /// Tells a screen-reader user what activating the row does.
  static const String jobRowHint = 'Opens the visit';

  /// The status of a visit that has not happened.
  static const String stateScheduled = 'Scheduled';

  /// The status of a visit that has.
  static const String stateDone = 'Completed';

  /// The name of the lower of the two priorities.
  static const String priorityRoutine = 'Routine';

  /// The name of the higher of the two.
  static const String priorityUrgent = 'Urgent';

  // --------------------------------------------------------------- detail

  /// Names the control that leaves the detail screen.
  static const String detailBack = 'Back to the visit list';

  /// The heading over the visit's own details.
  static const String detailSection = 'Details';

  /// Labels the address line.
  static const String detailSite = 'Address';

  /// Labels the priority line.
  static const String detailPriority = 'Priority';

  /// Labels the notes block.
  static const String detailNotes = 'Notes';

  /// Stands in for notes nobody wrote.
  static const String detailNoNotes = 'No notes were left for this visit.';

  /// The control that records the visit as made.
  static const String detailComplete = 'Mark this visit completed';

  /// What a screen reader hears while that is being recorded.
  static const String detailCompleteBusy = 'Recording the visit';

  /// What is announced once it is recorded.
  static const String detailCompleted = 'Visit recorded as completed';

  /// The control that removes the visit.
  static const String detailDelete = 'Remove this visit';

  /// What the removal notice says.
  static String detailDeletedNotice(String reference) =>
      'Visit $reference removed from the round';

  /// The control that puts it back.
  static const String detailUndo = 'Put it back';

  /// Names the control that clears the removal notice.
  static const String detailDismissNotice = 'Dismiss the removed-visit notice';

  /// The heading of the detail screen, when the visit is gone.
  static const String detailGoneTitle = 'This visit is no longer on the round';

  /// What to do about it.
  static const String detailGoneGuidance =
      'It was removed. Return to the list to see what is left.';

  // ----------------------------------------------------------------- form

  /// The title of the creation screen.
  static const String formTitle = 'New visit';

  /// The heading over the identifying fields.
  static const String formSectionIdentity = 'Where and what';

  /// Says which of required and optional is marked, since IUX marks neither.
  static const String formSectionIdentityNote =
      'Every field on this screen is needed unless it says otherwise.';

  /// The heading over the rest.
  static const String formSectionExtras = 'Anything else';

  /// Labels the reference field.
  static const String formReference = 'Job reference';

  /// Explains the shape of a reference.
  static const String formReferenceHelp = 'The code on the work order, such as '
      'WO-4471.';

  /// What the reference field says when it is empty.
  static const String formReferencePlaceholder = 'WO-0000';

  /// What is wrong when the reference is missing.
  static const String formReferenceMissing =
      'Enter the job reference from the work order.';

  /// What is wrong when the reference is already on the round.
  static const String formReferenceDuplicate =
      'This reference is already on the round. Open the existing visit '
      'instead of adding a second one.';

  /// Labels the address field.
  static const String formSite = 'Address';

  /// Explains what to put in it.
  static const String formSiteHelp = 'Enough for a driver to find it.';

  /// What is wrong when the address is missing.
  static const String formSiteMissing = 'Enter the address of the visit.';

  /// Labels the notes field.
  static const String formNotes = 'Notes (optional)';

  /// Explains what notes are for.
  static const String formNotesHelp =
      'Anything the person making the visit should read first.';

  /// Names the priority group.
  static const String formPriority = 'Priority';

  /// Explains what priority changes.
  static const String formPriorityHelp =
      'Urgent visits are listed above routine ones.';

  /// Labels the reminder switch.
  static const String formReminder = 'Remind me the evening before';

  /// Explains what the reminder needs.
  static const String formReminderHelp =
      'A reminder needs permission to send notifications.';

  /// The control that saves the visit.
  static const String formSubmit = 'Add the visit';

  /// The word that says the summary block is a failure.
  static const String formSummaryCategory = 'Error';

  /// Says how many fields need attention.
  static String formSummaryCount(int invalid) => invalid == 1
      ? 'One field needs your attention before this visit can be added.'
      : '$invalid fields need your attention before this visit can be added.';

  /// Tells a screen-reader user what a summary entry does.
  static const String formSummaryHint = 'Moves to the field';

  /// What is announced when a visit is added.
  static String formAdded(String reference) => 'Visit $reference added';

  /// Names the control that clears the added-visit notice.
  static const String formAddedDismiss = 'Dismiss the added-visit notice';

  // ------------------------------------------------------------- settings

  /// The title of the settings screen.
  static const String settingsTitle = 'Settings';

  /// The heading over the display settings.
  static const String settingsDisplay = 'Display';

  /// Labels the dark-theme switch.
  static const String settingsDark = 'Dark theme';

  /// Explains what it does.
  static const String settingsDarkHelp =
      'Applies immediately, to every screen.';

  /// Labels the contrast switch.
  static const String settingsContrast = 'Higher contrast';

  /// Explains what it does.
  static const String settingsContrastHelp =
      'Strengthens text and borders against their background.';

  /// Labels the motion switch.
  static const String settingsMotion = 'Reduce motion';

  /// Explains what it does.
  static const String settingsMotionHelp =
      'Removes the movement from transitions and progress.';

  /// The heading over the notification section.
  static const String settingsNotifications = 'Reminders';

  /// The title of the permission conversation.
  static const String permissionTitle = 'Let Rounds remind you about visits';

  /// Why the permission is being asked for.
  static const String permissionReason =
      'A notification the evening before is the only thing that tells you '
      'about a visit while the application is closed.';

  /// The control that agrees.
  static const String permissionAsk = 'Allow reminders';

  /// The control that refuses.
  static const String permissionDecline = 'Not now';

  /// The title once the user has refused.
  static const String permissionRefusedTitle = 'Reminders are turned off';

  /// The reason, restated for somebody who already said no once.
  static const String permissionRefusedReason =
      'Visits are still listed here. Nothing will tell you about them while '
      'the application is closed.';

  /// The control that asks again.
  static const String permissionAskAgain = 'Turn reminders on';

  /// The control that closes the conversation for good.
  static const String permissionKeepOff = 'Keep them off';

  /// What is shown once the permission is granted.
  static const String permissionGranted = 'Reminders are on';

  /// The word that says the granted block is a note.
  static const String noteCategory = 'Note';

  /// What the granted note says.
  static const String permissionGrantedDetail =
      'You will be reminded the evening before each visit.';

  /// The control that turns reminders off again.
  static const String permissionTurnOff = 'Turn reminders off';

  /// The summary on the closed disclosure.
  static const String settingsAboutSummary = 'About this round';

  /// What is inside it.
  static const String settingsAboutBody =
      'Rounds is a pilot application. Visits live on this device only and are '
      'lost when the application is closed. Nothing is sent anywhere.';

  /// The heading over the dangerous part.
  static const String settingsDanger = 'Clearing the round';

  /// The control that empties the round.
  static const String settingsClear = 'Clear the whole round';

  /// The title of the question it asks first.
  static const String settingsClearTitle = 'Clear every visit?';

  /// What clearing costs.
  static const String settingsClearConsequence =
      'Every visit, its address and its notes are removed from this device. '
      'Nothing here can bring them back.';

  /// The control that goes ahead.
  static const String settingsClearConfirm = 'Clear the round';

  /// The control that does not.
  static const String settingsClearKeep = 'Keep the visits';

  /// Says the round is already empty, on the disabled control.
  static const String settingsClearNothing = 'There are no visits to clear.';

  /// What is announced once the round is cleared.
  static const String settingsCleared = 'The round is empty';

  /// Names the control that clears that notice.
  static const String settingsClearedDismiss =
      'Dismiss the round-cleared notice';
}
