import 'package:flutter/widgets.dart';

/// Why a step with no name is refused.
const String _kEmptyTitle =
    'An onboarding step must be named. The name is where focus lands when the '
    'step changes, so it is the whole of what a screen-reader user hears when '
    'one screen of an interruption becomes the next. Unnamed, the flow moves '
    'and says nothing. Name what the user gets — "Track what you spend" — not '
    'the position, which IuxStepPositionDescription already says.';

/// Why a step with nothing to say is refused.
const String _kEmptyBody =
    'An onboarding step must say something. A title over an illustration is a '
    'screen the user is asked to sit through in exchange for one noun, and it '
    'is the reason onboarding has the reputation it has. Write the sentence '
    'that would make someone glad they stayed, or drop the step: a flow of '
    'three screens that each earn their place beats six that do not.';

/// One screen of an onboarding flow: what it is called, what it says, and
/// anything it shows beyond those two sentences.
///
/// ```dart
/// IuxOnboardingStep(
///   title: l10n.trackWhatYouSpend,
///   body: l10n.everyReceiptIsReadOnThisDeviceAndNeverUploaded,
///   content: const SpendingIllustration(),
/// )
/// ```
///
/// **A step is content, not questions.** A sequence that collects answers and
/// ends in one submission is `IuxGuidedForm`, which owns validation, an error
/// summary that reaches across steps, and a route back to a rejected field.
/// None of that exists here, because none of it applies to a screen that asks
/// for nothing. Choosing this pattern for a form would leave the user with a
/// flow that cannot tell them what is wrong.
///
/// [title] and [body] are both required and neither may be empty. They are the
/// step: together with the position they form the single utterance a
/// screen-reader user hears on arrival, and a step missing either is a screen
/// that moved the user and then declined to say where to.
///
/// ## What goes in [content], and what must not
///
/// [content] is the slot for everything that is not those two sentences — an
/// illustration, a choice the application wants to offer, a sample of the thing
/// being described. It keeps its own semantic nodes and its own place in the
/// focus order, so it may contain controls.
///
/// Two things must not go in it, and neither can be enforced by a type:
///
/// | Never in [content] | Why |
/// | --- | --- |
/// | the way out of the flow | `IuxOnboardingFlow` already draws it, on every step, as a full control beside the others. A second exit inside the content is a second thing to find, and a flow with two of them has one the user will miss. This is the third row of the table in `IuxDisclosureState`: the exit is the one control that must never need discovering. |
/// | a permission request the user did not invite | `IuxBeforeAsking` already refuses this in its own words — "a rationale on first launch, before the user has touched the feature, is still an interruption". Onboarding is where that rule is most often broken, and it is not suspended here. |
///
/// The second row deserves the detail, because onboarding is the surface on
/// which permission requests are traditionally buried.
///
/// If an application puts an `IuxPermissionRationale` here anyway, IUX-031's
/// guarantees travel with it: the rationale requires a reason, and it requires
/// `IuxPermissionMoment.decline`, drawn as a full `IuxButton` beside the ask
/// with no parameter that could make it a grey link. So the asymmetry stays
/// unrepresentable even in the place it is most tempting. What is *not*
/// repaired by that is the arithmetic: the step then shows two forward controls
/// and two refusals — the rationale's pair inside, the flow's pair beneath —
/// and the user has to work out which of the four leaves what. That is the
/// concrete reason to ask at the feature instead, and it is a defect of
/// composition that no assertion here can see.
///
/// **The flow's skip is not a permission decline.** Leaving an onboarding flow
/// says nothing about a question that was put inside one of its screens, and an
/// application that records it as an answer has recorded something the user did
/// not say.
@immutable
final class IuxOnboardingStep {
  /// Creates one screen of an onboarding flow.
  const IuxOnboardingStep({
    required this.title,
    required this.body,
    this.content,
  })  : assert(title.length > 0, _kEmptyTitle),
        assert(body.length > 0, _kEmptyBody);

  /// What this step is about, already localised.
  ///
  /// Name what the user gets, not the position: "Track what you spend", never
  /// "Step 2". Where the user is comes from `IuxStepPositionDescription`, which
  /// is announced immediately before this, so a title carrying the number says
  /// the number twice.
  ///
  /// It is announced as part of one utterance with [body], so keep it to a
  /// phrase. A title that is already a sentence leaves the body with nothing to
  /// add.
  final String title;

  /// What the step actually tells the user, already localised.
  ///
  /// **The sentence that has to earn the screen.** An onboarding step costs the
  /// user a page they did not ask for, and this is the only thing that pays for
  /// it. Say what the feature does for them and what it costs — "Photographs of
  /// receipts are read on this device and never uploaded" — rather than what
  /// the application is proud of.
  ///
  /// Required, and separate from [title] for the reason `IuxDialog` keeps its
  /// two apart: a title states a topic, and a topic is not information.
  ///
  /// Keep it to a sentence or two. It is spoken on arrival as part of the same
  /// node as the title, which is what makes a step change one announcement
  /// rather than three fragments — and the cost of that arrangement is that a
  /// long body is a long announcement, heard again every time the user walks
  /// back. See the limitations in `IuxOnboardingFlow`.
  final String body;

  /// Anything the step shows beyond [title] and [body], or null.
  ///
  /// A widget rather than an [IconData] slot, which is where this differs from
  /// `IuxPermissionRationale.illustration` and does so deliberately. A
  /// permission rationale's glyph is decoration beside an argument; an
  /// onboarding step's picture is frequently the point of the step, is usually
  /// an image rather than a glyph, and sometimes is not a picture at all. A
  /// slot that only accepted glyphs would be a parameter nobody used, and the
  /// caller would compose their own subtree beside it — which is the same
  /// widget with none of the layout.
  ///
  /// The consequence is stated rather than hidden: **a widget arrives carrying
  /// its own colours**, and the contrast guarantee the theme makes for
  /// everything above it stops at this boundary. Build what goes in here out of
  /// `IuxImage`, `IuxIcon` and the semantic roles, and it holds; build it out of
  /// literals and it does not, and nothing in IUX will notice.
  ///
  /// Its semantics are kept and are not merged into the heading. It may contain
  /// controls, and they take their place in the focus order immediately after
  /// the heading and before the flow's own controls. A decorative picture should
  /// say so — `IuxImage` with `IuxImageDescription.decorative()` — so it does
  /// not become a stop that announces a filename.
  ///
  /// Null is the ordinary case for a step that is two sentences, and it renders
  /// nothing at all rather than an empty box with a gap above it.
  final Widget? content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxOnboardingStep &&
          other.title == title &&
          other.body == body &&
          other.content == content;

  @override
  int get hashCode => Object.hash(title, body, content);

  @override
  String toString() => 'IuxOnboardingStep($title)';
}
