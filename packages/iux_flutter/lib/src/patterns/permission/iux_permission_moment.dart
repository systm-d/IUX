import 'package:flutter/foundation.dart';

import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../components/feedback/iux_inline_feedback.dart';

/// Where a permission conversation stands, and therefore what may honestly be
/// offered.
///
/// **A rationale shown before the system asks and a rationale shown after the
/// user has refused are not the same screen**, and treating them as one is how
/// applications end up nagging. The first is a request to be allowed to ask.
/// The second is a reply to an answer the user already gave. The third — the
/// system will not ask again — is a screen where the application has no way to
/// obtain anything at all, and must say so.
///
/// | Moment | The user has | The application may |
/// | --- | --- | --- |
/// | [IuxBeforeAsking] | not been asked | ask, once they agree to be asked |
/// | [IuxAfterRefusal] | said no | explain, and ask at most once more |
/// | [IuxSystemWillNotAsk] | said no, and the system has closed the door | send them to the setting, and nothing else |
///
/// Sealed for the reason `IuxRecoveryRoute` is: the choice between the three is
/// a claim about the conversation that only the caller can make, so it is made
/// by *naming a type* rather than by setting a flag that reads the same
/// whichever value it holds. A reviewer sees `IuxSystemWillNotAsk` in a diff.
/// Nobody sees `stage: 2`.
///
/// The claims are not merely documented, they are the shapes of the
/// constructors:
///
/// - [IuxBeforeAsking] **requires** a way to ask. A rationale that cannot lead
///   to the question is a wall of text with no door.
/// - [IuxAfterRefusal] makes the second ask **optional**, because declining to
///   ask again is a legitimate answer and must be as cheap to write as asking.
/// - [IuxSystemWillNotAsk] has **no ask parameter at all**. A control that
///   claimed to grant a permission the application can no longer request is a
///   lie, and it is unrepresentable rather than asserted.
///
/// ## Every moment can be declined
///
/// [decline] is required on all three, and it is the most load-bearing
/// requirement in this file. Two things follow from it.
///
/// The user always has a way out. A request that cannot be refused is not a
/// request, and a screen that explains why an application wants something and
/// offers only one control is a wall.
///
/// And the parent always receives the refusal. That callback is the *only*
/// signal an application gets that this user said no to being asked — the
/// system prompt reports its own answer, but nothing reports that the user
/// walked away from the rationale before it. A pattern with no such signal can
/// only nag, because the caller has nothing to record.
///
/// ## What is not here
///
/// **A granted permission.** There is nothing to explain and nothing to ask, so
/// there is no member for it and no rationale to render.
///
/// **A partial grant** — "selected photos only", "while using the app". The
/// application may still ask the system for more, so that is
/// [IuxBeforeAsking]; what changed is the caller's wording, which was always
/// the caller's.
///
/// **A status.** Nothing here reads one. See `IuxPermissionRationale` for the
/// boundary between this pattern and the platform.
@immutable
sealed class IuxPermissionMoment {
  /// Creates a moment.
  const IuxPermissionMoment();

  /// What the user can do to obtain the permission, or null when nothing in
  /// this application can obtain it for them.
  ///
  /// Nullable on the base and non-nullable on [IuxBeforeAsking], which always
  /// has one, so a caller reading that moment never checks for an absence that
  /// cannot happen.
  ///
  /// Null is a real answer in the other two: an application that has decided
  /// not to ask twice, and a device where an administrator settled the question
  /// and the settings screen will not help either. In both cases the sentence
  /// carries the way forward instead of a button — see the dead-end rule in
  /// `IuxPermissionRationale`.
  IuxInlineFeedbackAction? get action;

  /// How the user says no, or not now.
  ///
  /// Required in every moment. See the class documentation.
  ///
  /// Name what happens rather than the mechanism: "Not now", "Continue without
  /// photos", "Skip". "Cancel" makes the user work out which of two things is
  /// being cancelled, and here one of them is a feature they asked for.
  IuxInlineFeedbackAction get decline;

  /// [action] as the action model already understands it, or null when there is
  /// no action.
  ///
  /// **Derived rather than accepted, and that is the point of the whole file.**
  /// If this took an [IuxActionDescriptor], a call site could write
  /// `role: IuxActionRole.retry` on a permission control — which is the exact
  /// lie `docs/patterns/error-recovery.md` already forbids from the other side
  /// ("not allowed (403) — nothing the user repeats changes their
  /// permissions"). Asking again is not repeating a request that failed for a
  /// transient reason; it is putting a question to a person for the second
  /// time, and announcing it as "try again" tells the user the application
  /// thinks their answer was a malfunction.
  ///
  /// The fixed values, and why none of them is the caller's:
  ///
  /// | Field | Value | Why |
  /// | --- | --- | --- |
  /// | `role` | [IuxActionRole.navigate] | it moves the user to a surface this application does not own |
  /// | `intent`/`importance` | primary, high | it is the forward control of the block |
  /// | `confirmation` | none | nothing here presents a second question |
  /// | `operation` | idle | see below |
  ///
  /// [IuxActionRole.navigate] is the honest role for both an ask and a
  /// settings link, and it is one claim rather than two: **neither control
  /// grants anything.** One hands the user to the operating system's question,
  /// the other to the operating system's settings. An application that
  /// advertised either as "Allow" would be promising an outcome it cannot
  /// produce, and the user who pressed it and was then asked again by the
  /// system — or, worse, was not asked at all — learns that this interface does
  /// not know what its own buttons do.
  ///
  /// There is no operation and no busy state. What the control opens is a
  /// system surface that takes over the screen, and the somewhere-else owns its
  /// own progress — the same reasoning `IuxAlternativeRoute` gives. A spinner
  /// underneath a system dialog is a spinner nobody sees.
  IuxActionDescriptor? get actionDescriptor {
    final IuxInlineFeedbackAction? offer = action;
    if (offer == null) return null;
    return IuxActionDescriptor(
      semantics: IuxActionSemantics(label: offer.effectiveSemanticLabel),
      intent: IuxActionIntent.primary,
      importance: IuxActionImportance.high,
      role: IuxActionRole.navigate,
    );
  }

  /// [decline] as the action model already understands it.
  ///
  /// [IuxActionRole.dismiss] rather than [IuxActionRole.cancel], and the
  /// difference is the one the action model already draws: cancelling abandons
  /// an in-progress task and discards what was in it, while declining a
  /// permission discards nothing at all. Announcing this as a cancellation
  /// would tell a screen-reader user they are about to lose something, at the
  /// exact moment the interface is trying to establish that saying no is free.
  ///
  /// Secondary rather than primary, because the user arrived here by reaching
  /// for the feature and the forward control is the continuation of what they
  /// were doing. Emphasis, not availability: it is a full `IuxButton` with the
  /// same target floor and the same place in the focus order, never a bare word
  /// under a filled rectangle. That asymmetry — a real button against a grey
  /// link — is the manipulation this pattern exists to make unnecessary, and it
  /// is unrepresentable here because there is no parameter with which to draw
  /// the refusal as anything else.
  IuxActionDescriptor get declineDescriptor => IuxActionDescriptor(
        semantics: IuxActionSemantics(label: decline.effectiveSemanticLabel),
        intent: IuxActionIntent.secondary,
        role: IuxActionRole.dismiss,
      );
}

/// The system has not asked yet, and it still can.
///
/// ```dart
/// IuxBeforeAsking(
///   ask: IuxInlineFeedbackAction(
///     label: l10n.chooseCameraAccess,
///     onActivate: controller.requestCameraPermission,
///   ),
///   decline: IuxInlineFeedbackAction(
///     label: l10n.notNow,
///     onActivate: controller.dismissRationale,
///   ),
/// )
/// ```
///
/// **This is a request to be allowed to ask.** The system prompt is a question
/// the user gets a fixed number of chances to answer, and it arrives with no
/// context: "Allow this app to use the camera?" says nothing about receipts.
/// The rationale is where the application spends its own screen explaining why,
/// so that the system's question is one the user can answer rather than guess
/// at.
///
/// Reach for it when the reason is not obvious from what the user just pressed.
/// A camera button that opens the camera needs no essay; a background-location
/// permission behind a "Remind me when I am near a shop" toggle needs one, and
/// asking cold there spends the user's single best chance on a question they
/// have no reason to say yes to.
///
/// **Do not use it to soften an ask the user did not invite.** A rationale on
/// first launch, before the user has touched the feature, is still an
/// interruption — it is simply a politely worded one, and the user who has not
/// yet seen what the application does has nothing to weigh the request against.
///
/// [ask] is required. Without it this is a page explaining why the application
/// wants something, ending in a control that declines and nothing else — which
/// leaves the user unable to agree even when they want to.
@immutable
final class IuxBeforeAsking extends IuxPermissionMoment {
  /// Creates the moment before the system has asked.
  const IuxBeforeAsking({
    required IuxInlineFeedbackAction ask,
    required this.decline,
  }) : action = ask;

  /// How the user agrees to be asked. Never null.
  ///
  /// Its callback is where the application makes its platform call. Nothing in
  /// IUX makes that call, and nothing in IUX knows whether it was made.
  ///
  /// Label it as what it is. "Continue", "Choose camera access" and "Next" are
  /// honest; "Allow" is not, because this control allows nothing — the system's
  /// question does, and it has not been asked yet.
  @override
  final IuxInlineFeedbackAction action;

  /// How the user declines to be asked.
  @override
  final IuxInlineFeedbackAction decline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxBeforeAsking &&
          other.action == action &&
          other.decline == decline;

  @override
  int get hashCode => Object.hash(IuxBeforeAsking, action, decline);

  @override
  String toString() => 'IuxBeforeAsking(${action.label})';
}

/// The user has refused, and the system can still be asked to ask again.
///
/// ```dart
/// IuxAfterRefusal(
///   askAgain: IuxInlineFeedbackAction(
///     label: l10n.chooseCameraAccess,
///     onActivate: controller.requestCameraPermission,
///   ),
///   decline: IuxInlineFeedbackAction(
///     label: l10n.continueWithoutTheCamera,
///     onActivate: controller.dismissRationale,
///   ),
/// )
/// ```
///
/// On Android this is the moment the platform itself marks: the permission is
/// denied and `shouldShowRequestPermissionRationale` is true. The mapping is
/// the caller's to make — see `IuxPermissionRationale` on why nothing here
/// reads a status.
///
/// ## Asking twice: the position this pattern takes
///
/// **It is permitted, and it is permitted exactly once, and only where the user
/// came back.** Forbidding a second ask outright would be dishonest: the
/// platform provides the signal above precisely so that an application can
/// explain itself and put the question again, and a pattern that refused would
/// push every application that needs it back into building its own — where
/// nothing constrains it at all.
///
/// What is *not* permitted is the loop, and the loop is prevented structurally
/// rather than by advice:
///
/// - **Nothing here decides it should be on screen.** This is a value the
///   parent renders. There is no controller that opens anything, no route
///   pushed, no overlay inserted; the same rule every IUX pattern follows, and
///   the one that matters most in this one.
/// - **Nothing here calls the platform.** There is no path from a build to a
///   system prompt. Every prompt an application shows is one a user activated
///   with their own finger.
/// - **Nothing here counts, waits or repeats.** No attempt budget, no timer, no
///   backoff, no "ask again in three days". A rationale left on screen for an
///   hour asks for nothing.
/// - **The refusal is always reported.** [decline] is required, so the parent
///   is handed the signal it needs in order to stop.
///
/// What the framework cannot prevent is stated in
/// `docs/patterns/permission-rationale.md` rather than hidden: a parent that
/// rebuilds this on every entry to a screen will nag, and no widget can stop
/// it. IUX holds the shape of the conversation; its cadence belongs to the
/// application.
///
/// [askAgain] is optional, and null is a real answer rather than an oversight.
/// An application that has decided one refusal is enough still owes the user an
/// explanation of why the feature is inert, and it should not have to leave the
/// pattern — or invent a disabled button — in order to give one. When it is
/// null the guidance carries the way forward instead; see the dead-end rule in
/// `IuxPermissionRationale`.
@immutable
final class IuxAfterRefusal extends IuxPermissionMoment {
  /// Creates the moment after a refusal the system will let you revisit.
  const IuxAfterRefusal({
    IuxInlineFeedbackAction? askAgain,
    required this.decline,
  }) : action = askAgain;

  /// How the user asks to be asked again, or null when the application has
  /// decided not to ask twice.
  ///
  /// Not a retry, and it cannot be made into one: [actionDescriptor] fixes the
  /// role. Word it as a fresh offer — "Choose camera access" — rather than as a
  /// correction of the user's answer. "Try again" tells someone who deliberately
  /// said no that the interface read their decision as a mistake.
  @override
  final IuxInlineFeedbackAction? action;

  /// How the user declines again, and this time for good as far as this screen
  /// is concerned.
  @override
  final IuxInlineFeedbackAction decline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAfterRefusal &&
          other.action == action &&
          other.decline == decline;

  @override
  int get hashCode => Object.hash(IuxAfterRefusal, action, decline);

  @override
  String toString() => 'IuxAfterRefusal(${action?.label})';
}

/// The system will not put the question again, whatever this application does.
///
/// ```dart
/// IuxSystemWillNotAsk(
///   openSettings: IuxInlineFeedbackAction(
///     label: l10n.openSettings,
///     onActivate: controller.openAppSettings,
///   ),
///   decline: IuxInlineFeedbackAction(
///     label: l10n.continueWithoutTheCamera,
///     onActivate: controller.dismissRationale,
///   ),
/// )
/// ```
///
/// The end of the conversation: the user has spent the answers the platform
/// gives them, or a policy settled it before they ever saw a prompt. The
/// application cannot ask, cannot grant, and cannot get the prompt back.
///
/// **There is no ask parameter, structurally.** This is the one thing in the
/// pattern that is unrepresentable rather than merely discouraged, and it is
/// the failure worth making impossible: a control that offers to request a
/// permission the system will refuse to request produces nothing at all when
/// pressed — no prompt, no error, no change — which is indistinguishable from a
/// broken application, and it is the state a user reports as "the button does
/// nothing". An interface must not claim to grant what it cannot grant.
///
/// [openSettings] is what remains, and it is worth being precise about what it
/// does: **it grants nothing either.** It hands the user to the operating
/// system's own screen, where they may or may not find the switch, may or may
/// not change it, and may or may not come back. That is why its role is
/// [IuxActionRole.navigate] and why the wording should say where it goes rather
/// than what the user will find when they arrive.
///
/// It is optional, because self-service is not always on offer. On a managed
/// device, under a work profile, or where a guardian holds the setting, the
/// settings screen shows the user a control they cannot move — and sending them
/// there is worse than not offering, because they now believe they failed at
/// something. The honest screen names who can change it, in the guidance.
@immutable
final class IuxSystemWillNotAsk extends IuxPermissionMoment {
  /// Creates the moment where only the system settings remain, or not even
  /// those.
  const IuxSystemWillNotAsk({
    IuxInlineFeedbackAction? openSettings,
    required this.decline,
  }) : action = openSettings;

  /// How the user reaches the setting, or null when reaching it would not help
  /// them.
  ///
  /// Name the destination — "Open settings", "Open app permissions" — so the
  /// control says where it goes before it goes there. Do not name the outcome:
  /// "Turn on the camera" is a promise this control cannot keep, and the user
  /// who lands on a settings screen having been told the camera was about to be
  /// turned on has been misled by one word.
  @override
  final IuxInlineFeedbackAction? action;

  /// How the user carries on without the permission.
  ///
  /// Especially important here. This is the moment at which the answer is
  /// settled, so the honest label is usually about the feature rather than the
  /// permission: "Continue without photos", "Add receipts by hand".
  @override
  final IuxInlineFeedbackAction decline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxSystemWillNotAsk &&
          other.action == action &&
          other.decline == decline;

  @override
  int get hashCode => Object.hash(IuxSystemWillNotAsk, action, decline);

  @override
  String toString() => 'IuxSystemWillNotAsk(${action?.label})';
}
