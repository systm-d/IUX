import 'package:flutter/foundation.dart';

import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';

/// Why an unlabelled way out is refused.
const String _kEmptyLabel =
    'The way out of an empty state must be labelled, and labelled with its '
    'outcome. On a screen holding nothing else, this control is the only thing '
    'the user can act on: unlabelled it is a rectangle in the middle of an '
    'empty page. Name what it produces — "Add a project", "Clear the filters" '
    '— already localised.';

/// Why a way out that asks to be confirmed is refused.
const String _kConfirmingAction =
    'This action declares a confirmation policy, and an empty state presents '
    'none: it holds no dialog, no armed state and nowhere to put a second '
    'question. The policy would therefore be dropped in silence, and the call '
    'site would read as though the user were being asked while the action ran '
    'on the first tap — which is the worst direction for that mistake to go. '
    'Nothing reached from an empty state should need confirming anyway: '
    'creating the first item, widening a filter and asking for access are all '
    'additive. If the control genuinely destroys something, it does not belong '
    'here — put an IuxDestructiveAction on the screen, which owns the question '
    'and the answer.';

/// Why IuxActionRole.retry is refused here.
const String _kRetryRole =
    'IuxActionRole.retry describes a failure that did not happen. A collection '
    'that came back with nothing in it answered the question; a collection '
    'that never came back is an error, and the two need opposite things — an '
    'empty state explains an answer, an error explains a breakdown. Offering '
    '"Try again" over an answer sends the user to repeat a request that will '
    'return the same nothing, and teaches them that the interface does not '
    'know the difference either. Report the failure with the error-recovery '
    'pattern instead, and keep this for the case where the request succeeded.';

/// Why a greyed way out with no explanation is refused.
const String _kUnexplainedUnavailability =
    'This action is unavailable and does not say why. Everywhere else in IUX '
    'that is bad; here it is the whole screen. The user is looking at a page '
    'with nothing on it and one greyed control, with no way to tell whether '
    'they did something wrong, whether the feature does not apply to them, or '
    'whether the application is broken — and a disabled control leaves the '
    'focus order on Android, so a screen-reader user cannot even reach it to '
    'wonder. Set IuxActionSemantics.unavailabilityReason, or keep the action '
    'enabled and let the refusal explain itself.';

/// Why an empty busy hint is refused rather than ignored.
const String _kEmptyBusyHint =
    'An empty busyHint is the same as no busyHint, and says so less clearly. '
    'Omit the parameter, or pass the localised sentence a screen reader should '
    'hear while the action runs.';

/// The way out of an empty state: what it is called, what it is, and what it
/// runs.
///
/// ```dart
/// IuxEmptyStateAction(
///   label: l10n.addYourFirstProject,          // on screen
///   action: IuxActionDescriptor.primary(
///     semantics: IuxActionSemantics(label: l10n.addYourFirstProject),
///   ),
///   onActivate: controller.createProject,
/// )
/// ```
///
/// What an `IuxButton` takes, in one object, because an empty state never
/// renders more than one of them and the situation decides which. It is
/// **not** a second action model: [action] is the same [IuxActionDescriptor]
/// every other IUX control takes, so an availability that follows the network,
/// an operation driven by an `IuxAsyncActionController` and a fuller announced
/// name all work here exactly as they do on a button.
///
/// Three combinations are refused, each because it would otherwise be dropped
/// in silence rather than merely being unusual:
///
/// - **a confirmation policy**, which nothing here would present. See
///   [_kConfirmingAction].
/// - **[IuxActionRole.retry]**, which describes a failure that did not happen.
///   See [_kRetryRole].
/// - **an unavailable action with no reason**, which on a screen holding
///   nothing else is the entire interface. See [_kUnexplainedUnavailability].
///
/// This type does not say *which* situation the action belongs to. That is
/// [IuxEmptyStateCause]'s job, and it is why the two are separate: the same
/// shape of control means "create the first one" in one situation and "widen
/// what you asked for" in another, and only the cause can keep those apart.
@immutable
final class IuxEmptyStateAction {
  /// Creates the way out of an empty state.
  ///
  /// The constructor is not `const`, and the reason is worth stating because
  /// the first version of this file tried to be. Two of the assertions below
  /// read a field of [action], and Dart cannot evaluate a field access on a
  /// constant object inside a `const` constructor's assertion — the compiler
  /// rejects it outright. The alternative was to defer both checks to the
  /// widget's build, as `IuxDestructiveActionController` defers its own; that
  /// is the right answer when the object being checked genuinely has to be a
  /// constant, and this one does not. [onActivate] is a closure or a tear-off,
  /// neither of which is a constant expression, so no call site could ever have
  /// written `const IuxEmptyStateAction(...)` anyway. Nothing is lost, and the
  /// mistake is caught at the line that made it rather than one frame later.
  IuxEmptyStateAction({
    required this.label,
    required this.action,
    required this.onActivate,
    this.busyHint,
  })  : assert(label.length > 0, _kEmptyLabel),
        assert(action.confirmation is IuxNoConfirmation, _kConfirmingAction),
        assert(action.role != IuxActionRole.retry, _kRetryRole),
        assert(
          action.availability != IuxActionAvailability.disabled ||
              action.semantics.unavailabilityReason != null,
          _kUnexplainedUnavailability,
        ),
        assert(busyHint == null || busyHint.length > 0, _kEmptyBusyHint);

  /// The visible text, already localised.
  ///
  /// Name the outcome rather than the mechanism: "Add a project", not "New";
  /// "Show all invoices", not "Reset". The user is looking at a screen with
  /// nothing on it, so this label is the only description of what happens next
  /// they are going to get.
  ///
  /// Kept separate from [IuxActionSemantics.label] for the reason
  /// `IuxButton` keeps them separate: the announced name may be fuller than
  /// the visible one — "Add" on screen, "Add your first project" in a screen
  /// reader.
  final String label;

  /// What the action is, and whether it may currently run.
  ///
  /// The existing action model rather than a parallel one. Availability and
  /// operation are the two dimensions that earn their place here: a create
  /// action is legitimately unavailable while the application is offline, and
  /// legitimately in progress while the first item is being created — and both
  /// states are announced by the button without this pattern knowing anything
  /// about them.
  final IuxActionDescriptor action;

  /// Called once per accepted activation.
  ///
  /// The empty state never changes as a result. Whether the collection is
  /// still empty afterwards is something only the parent can know, and a
  /// pattern that hid itself on activation would hide a state that is still
  /// true.
  final VoidCallback onActivate;

  /// Announced after the name while the action is running, already localised.
  ///
  /// Leave it null and a screen reader hears nothing when the control is
  /// pressed, and silence is indistinguishable from a control that did
  /// nothing — which is the impression a screen holding one control can least
  /// afford to give. Supply it whenever [action] carries an operation the
  /// parent drives, because that is the only case in which the running state
  /// exists at all.
  final String? busyHint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxEmptyStateAction &&
          other.label == label &&
          other.action == action &&
          other.onActivate == onActivate &&
          other.busyHint == busyHint;

  @override
  int get hashCode => Object.hash(label, action, onActivate, busyHint);

  @override
  String toString() => 'IuxEmptyStateAction($label)';
}

/// Why there is nothing here — and therefore what the way out can be.
///
/// **"Empty" is not one state, and this is the type that refuses to pretend it
/// is.** Four situations put nothing on a screen, and they have four different
/// exits:
///
/// | Situation | The user's position | The way out |
/// | --- | --- | --- |
/// | [IuxNothingCreatedYet] | nothing has ever been here | make the first one |
/// | [IuxNoMatches] | it is here, and you excluded it | widen what you asked for |
/// | [IuxAccessRestricted] | it is here, and you may not see it | obtain access |
/// | [IuxNothingLeftToDo] | it was here and you dealt with it | none is owed |
///
/// A single `EmptyState(title, message)` makes those indistinguishable, and
/// the mistake that follows is always the same one: an exit that belongs to a
/// different situation. "Add your first invoice" under a filter that hid
/// forty of them. "Clear the filters" on a collection that has never held
/// anything. "Retry" on either. Each is a control that cannot work, offered to
/// a user who has no other information to go on.
///
/// So the situation carries its own exit and there is no way to pair them
/// wrongly: [IuxNoMatches] takes a `reset` and nothing else,
/// [IuxNothingLeftToDo] takes nothing at all. The wrong combination is not
/// validated at runtime — it does not compile.
///
/// Sealed for the same reason [IuxConfirmationPolicy] is: a fifth situation
/// must be a deliberate, reviewable change rather than a value someone adds to
/// an enum, and every subclass answers [requiresWayForward] for itself instead
/// of leaving a `switch` somewhere to be forgotten.
///
/// ## Search and filter are one situation, not two
///
/// A search that matched nothing and a filter that matched nothing put the
/// user in the same place: the content exists, and the criteria they set
/// excluded it. The exit is the same too — widen or drop the criteria — and
/// the only thing that genuinely differs is the wording, which is the caller's
/// in every IUX API. Two types here would have identical shapes, identical
/// behaviour, and would make the caller choose between them for no consequence.
///
/// ## What is not here
///
/// **A failure.** A collection that is empty because the request never came
/// back is not empty, it failed, and the two need opposite things: an empty
/// state explains an answer, an error explains a breakdown and offers a retry.
/// That is IUX-029, and [IuxEmptyStateAction] refuses
/// [IuxActionRole.retry] to keep the line visible.
///
/// **A wait.** A collection that has not answered yet is loading, and showing
/// "Nothing here" while the answer is in flight is a statement the interface
/// cannot support. That is IUX-030.
@immutable
sealed class IuxEmptyStateCause {
  /// Creates a cause.
  const IuxEmptyStateCause();

  /// The exit this situation offers, or null when it offers none.
  ///
  /// Nullable on the base and non-nullable on the subclasses that always have
  /// one, so a caller reading a concrete situation never has to check for an
  /// absence that cannot happen.
  IuxEmptyStateAction? get action;

  /// Whether the user is still owed a way forward.
  ///
  /// True for every situation where the user came for something and did not
  /// get it. False only for [IuxNothingLeftToDo], where they got exactly what
  /// they came for and there is nothing to offer.
  ///
  /// `IuxEmptyState` uses it to refuse a dead end: a situation that owes a way
  /// forward and supplies neither an action nor guidance is a screen that
  /// tells the user they are stuck and declines to say what would help.
  bool get requiresWayForward;
}

/// Nothing has ever been in this collection.
///
/// A first run, a project with no members, a folder nobody has put anything
/// in. The distinguishing fact is that the user is not missing anything —
/// there is nothing to miss — so the screen's job is to say what this place is
/// for and, when the user is the one who can fill it, to start them off.
///
/// ```dart
/// IuxNothingCreatedYet(
///   create: IuxEmptyStateAction(
///     label: l10n.addYourFirstProject,
///     action: IuxActionDescriptor.primary(
///       semantics: IuxActionSemantics(label: l10n.addYourFirstProject),
///     ),
///     onActivate: controller.createProject,
///   ),
/// )
/// ```
///
/// [create] is optional, and null is a real answer rather than an oversight:
/// plenty of collections are filled by somebody else. An employee's payslips
/// appear when payroll files them; a patient's results appear when the lab
/// returns them. Offering "Add one" there would be a control that cannot work.
///
/// When there is no action, `IuxEmptyState` requires the guidance instead —
/// *what* will make something appear here, and *who* makes it happen. That
/// sentence is the way out; it is simply made of words rather than of a
/// button.
@immutable
final class IuxNothingCreatedYet extends IuxEmptyStateCause {
  /// Creates the situation where the collection has never held anything.
  const IuxNothingCreatedYet({IuxEmptyStateAction? create}) : action = create;

  /// How the user makes the first one, or null when they are not the one who
  /// fills this.
  @override
  final IuxEmptyStateAction? action;

  @override
  bool get requiresWayForward => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxNothingCreatedYet && other.action == action;

  @override
  int get hashCode => Object.hash(IuxNothingCreatedYet, action);

  @override
  String toString() => 'IuxNothingCreatedYet($action)';
}

/// The content is there, and the criteria the user set exclude all of it.
///
/// A search that returned nothing, a filter that hid everything, a date range
/// with nothing in it. The one situation where the emptiness is the user's own
/// doing, which is what makes it recoverable — and what makes an exit
/// mandatory here and optional everywhere else.
///
/// ```dart
/// IuxNoMatches(
///   reset: IuxEmptyStateAction(
///     label: l10n.showAllInvoices,
///     action: IuxActionDescriptor(
///       semantics: IuxActionSemantics(label: l10n.showAllInvoices),
///     ),
///     onActivate: controller.clearFilters,
///   ),
/// )
/// ```
///
/// **[reset] is required, and that is the strongest claim this file makes.**
/// The criteria were set through the interface, so the interface can always
/// unset them: unlike a create action, there is no case where this callback
/// cannot be written. And the failure it prevents is the one users get stuck
/// in most often — a filter applied three screens ago, collapsed behind a
/// control that is now scrolled off, leaving a permanently empty list and no
/// visible cause. A reset beside the emptiness costs one line and ends that
/// class of bug.
///
/// It does not have to *clear everything*. "Search all folders", "Include
/// archived", "Show the last year instead" are all resets: what matters is
/// that activating it returns content, so the user learns that the criteria
/// were the reason.
///
/// Do not point it at the control the user would have to find anyway. A reset
/// labelled "Open filters" hands them back the same search they are already
/// lost in.
@immutable
final class IuxNoMatches extends IuxEmptyStateCause {
  /// Creates the situation where the criteria exclude everything.
  const IuxNoMatches({required IuxEmptyStateAction reset}) : action = reset;

  /// How the user widens what they asked for. Never null.
  @override
  final IuxEmptyStateAction action;

  @override
  bool get requiresWayForward => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IuxNoMatches && other.action == action;

  @override
  int get hashCode => Object.hash(IuxNoMatches, action);

  @override
  String toString() => 'IuxNoMatches($action)';
}

/// The content is there, and this user may not see it.
///
/// A permission that was declined, an account that has not been verified, a
/// workspace an administrator has not added them to. The screen is empty for a
/// reason that has nothing to do with the data, and saying "No photos yet" here
/// is a lie the user cannot detect: they will go looking for the photos they
/// know they have.
///
/// ```dart
/// IuxAccessRestricted(
///   request: IuxEmptyStateAction(
///     label: l10n.choosePhotos,
///     action: IuxActionDescriptor.primary(
///       semantics: IuxActionSemantics(label: l10n.choosePhotosToShare),
///     ),
///     onActivate: controller.requestPhotoAccess,
///   ),
/// )
/// ```
///
/// [request] is optional because self-service is not always available: when
/// only an administrator can grant the access, the honest screen names who to
/// ask rather than offering a button that opens nothing. The guidance carries
/// that, and `IuxEmptyState` requires it when there is no action.
///
/// **This presents the consequence, not the request.** It does not ask the
/// operating system for anything, does not know whether a permission was
/// declined once or permanently, and holds no rationale copy — [onActivate] is
/// the parent's, and what it opens is the parent's decision. Explaining *why*
/// an application needs a permission before asking for it is a flow of its own
/// (IUX-031) and a different moment in the user's day: this one is what the
/// screen shows afterwards.
@immutable
final class IuxAccessRestricted extends IuxEmptyStateCause {
  /// Creates the situation where access, not content, is missing.
  const IuxAccessRestricted({IuxEmptyStateAction? request}) : action = request;

  /// How the user obtains access, or null when they cannot do it themselves.
  @override
  final IuxEmptyStateAction? action;

  @override
  bool get requiresWayForward => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAccessRestricted && other.action == action;

  @override
  int get hashCode => Object.hash(IuxAccessRestricted, action);

  @override
  String toString() => 'IuxAccessRestricted($action)';
}

/// There was something here, the user dealt with it, and the emptiness is the
/// result they wanted.
///
/// An inbox with nothing unread, a queue with nothing left to review, a list of
/// overdue tasks with none overdue. The only situation in this file that is not
/// a gap, and the only one that carries no action — structurally, not by
/// omission.
///
/// ```dart
/// IuxEmptyState(
///   cause: const IuxNothingLeftToDo(),
///   title: l10n.everythingIsReviewed,
///   arrival: IuxEmptyStateArrival.afterAChange,
/// )
/// ```
///
/// **Why it takes no action.** Every other situation leaves the user short of
/// something, so the pattern insists on a way forward. Here they are not
/// short of anything, and a button would be the interface inventing work:
/// "Review something else" sends a user who has just finished back into a
/// queue they emptied on purpose. Making that unrepresentable is what stops
/// this becoming the escape hatch for "I could not think of an action" — which
/// would put the words "all done" under every genuinely broken screen in an
/// application.
///
/// **Do not use it for a collection that has never held anything.** "You are
/// all caught up" on a first run congratulates the user for work they have not
/// done and hides the fact that this is where their work would go. That is
/// [IuxNothingCreatedYet].
///
/// Pair it with [IuxEmptyStateArrival.afterAChange] whenever the last item
/// left under the user's hands: reaching zero is the whole event, and a screen
/// reader user who hears nothing does not know they finished.
@immutable
final class IuxNothingLeftToDo extends IuxEmptyStateCause {
  /// Creates the situation where the emptiness is the outcome.
  const IuxNothingLeftToDo();

  /// Always null. See the class documentation.
  @override
  IuxEmptyStateAction? get action => null;

  @override
  bool get requiresWayForward => false;

  @override
  bool operator ==(Object other) => other is IuxNothingLeftToDo;

  @override
  int get hashCode => (IuxNothingLeftToDo).hashCode;

  @override
  String toString() => 'IuxNothingLeftToDo()';
}

/// How this empty state got in front of the user, which decides whether it is
/// announced.
///
/// **The dimension a screen-reader user notices most, and the one frameworks
/// leave out.** A list that empties under a filter is silent: the rows are
/// gone, the explanation is on screen, and nothing tells the person who cannot
/// see it that anything happened. They are left holding a screen they have no
/// reason to re-read.
///
/// The pattern cannot work this out for itself. A widget being built for the
/// first time looks identical whether it arrived with the screen or replaced
/// forty rows a moment ago; only the parent knows which, and the parent owns
/// the state in IUX anyway.
///
/// Orthogonal to [IuxEmptyStateCause] on purpose. Any situation can arrive
/// either way — a collection is empty on first run *and* empty again after its
/// last item is deleted — so folding this into the cause would double the
/// number of situations and still get the pairing wrong.
enum IuxEmptyStateArrival {
  /// The content emptied while the user was looking at it.
  ///
  /// The default, and the safer of the two. The title and the guidance become a
  /// live region — the action does not, because it is a control the user lands
  /// on rather than a change to be read out — so the platform speaks the
  /// explanation once, in place, and the user can go back over it.
  ///
  /// The asymmetry is why it is the default: used here by mistake, a screen
  /// that opened empty is announced once more than it needed to be — noise.
  /// Used the other way by mistake, a list that emptied says nothing at all,
  /// and silence is indistinguishable from an application that has hung.
  afterAChange,

  /// The screen already had nothing in it when the user arrived.
  ///
  /// No live region. The empty state is simply the screen's content, and a
  /// screen reader reads it as the user explores; announcing it on top of that
  /// says the same sentence twice, once before the user has any context for it.
  ///
  /// Say this only when it is true. It is a claim about where the user came
  /// from, not a way of quietening a screen.
  withTheScreen,
}
