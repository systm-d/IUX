import 'package:flutter/widgets.dart';

import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../components/button/iux_button.dart';
import '../../components/feedback/iux_inline_feedback.dart';
import '../../components/media/iux_icon.dart';
import '../../components/media/iux_media_model.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import 'iux_permission_moment.dart';

/// Why a rationale with no heading is refused.
const String _kEmptyTitle =
    'A permission rationale must open by naming what is being asked for, in '
    'the user\'s own terms. Without a title the block starts mid-argument, and '
    'a screen-reader user hears the justification for a request they have not '
    'been told about. Pass the localised sentence: "Scan receipts with your '
    'camera?", "Find shops near you?" — the thing the user gets, not the '
    'permission constant.';

/// Why a rationale with no reason is not a rationale.
const String _kEmptyReason =
    'The reason is the entire pattern. A block that asks for a permission and '
    'declines to say why is the system prompt with extra steps: the user is '
    'asked the same unanswerable question, having spent one more screen '
    'getting there. Say what the application does with it and what the user '
    'gets back — "Photographs of receipts are read on this device and never '
    'uploaded" — and say it before the controls, because after them it is an '
    'excuse rather than a reason.';

/// Why an empty guidance string is refused rather than ignored.
const String _kEmptyGuidance =
    'An empty guidance is the same as no guidance, and says so less clearly. '
    'Omit the parameter, or pass the localised sentence saying what happens '
    'without the permission and who can change it.';

/// Why a moment with no forward control may not also be silent about the way
/// forward.
const String _kDeadEnd =
    'This moment offers the user no way to obtain the permission and no '
    'sentence saying where one is, which leaves a screen that explains why an '
    'application wants something, refuses to say how the user could give it, '
    'and offers one control that declines. That is a dead end, and it is the '
    'failure this pattern shares with an empty state. Two ways out, and either '
    'is enough: give the moment its action — ask, ask again, open settings — '
    'or write the guidance saying what the user can do instead and who holds '
    'the switch ("Your work profile manages camera access. Your IT '
    'administrator can turn it on."). Unlike an empty state there is no exempt '
    'moment here: in every one of them the user is short of a feature they '
    'came for.';

/// Explains why an application wants a permission, and offers only the moves
/// that are honest at this point in the conversation.
///
/// ```dart
/// IuxPermissionRationale(
///   moment: IuxBeforeAsking(
///     ask: IuxInlineFeedbackAction(
///       label: l10n.chooseCameraAccess,
///       onActivate: controller.requestCameraPermission,
///     ),
///     decline: IuxInlineFeedbackAction(
///       label: l10n.notNow,
///       onActivate: controller.dismissRationale,
///     ),
///   ),
///   title: l10n.scanReceiptsWithYourCamera,
///   reason: l10n.photographsAreReadOnThisDeviceAndNeverUploaded,
/// )
/// ```
///
/// **Use it** where a feature the user has reached for needs a permission they
/// have not granted, and the reason is not obvious from what they just pressed.
/// A camera button that opens the camera explains itself; a background-location
/// permission behind "Remind me when I am near a shop" does not, and asking
/// cold there spends the user's best chance on a question they have no reason
/// to answer yes to.
///
/// ## What it is not
///
/// **It is not the system prompt, and it never becomes one.** The operating
/// system owns the question that actually grants anything. This block owns the
/// screen before it, between it and a refusal, and after the system has stopped
/// asking. See "The platform boundary" below, which is the most important
/// section of this document.
///
/// **It is not an empty state.** `IuxEmptyState` with `IuxAccessRestricted`
/// reports a *consequence*: a region that holds nothing because this user may
/// not see what is in it. This is a *request*: a question being put to the
/// user, with an answer expected. The two meet at exactly one point — the empty
/// state's `request` action is a natural place for a parent to raise this
/// block — and neither renders the other.
///
/// | | `IuxEmptyState` + `IuxAccessRestricted` | [IuxPermissionRationale] |
/// | --- | --- | --- |
/// | the user is | looking at a region with nothing in it | being asked something |
/// | the block is | an account of why | an argument, and a choice |
/// | it offers | one exit | a forward control, always beside a refusal |
/// | the moment | afterwards | before, or between |
///
/// **It is not an error.** A refusal is a decision the user made, and reporting
/// it with `IuxErrorRecovery` would put the word "Error", an error tint and an
/// error glyph around a choice they were entitled to make. Where a *running
/// operation* broke because a permission was missing — an upload that reached
/// the storage layer and stopped — that genuinely is a failure, and it is
/// `IuxErrorRecovery` with an `IuxAlternativeRoute`, because nothing the user
/// repeats changes their permissions.
///
/// **It is not a dialog.** Do not place it inside an `IuxDialog`: a dialog is
/// already a question and already composes its own title, message and choices,
/// so the two would produce a block with two headings and four controls. Put it
/// where the feature is — inline in the region the permission unlocks, or in a
/// sheet the parent opens — and let the user see what they are being asked
/// about.
///
/// ## The moment decides what may be offered
///
/// [moment] is the whole design rather than a label. A rationale shown before
/// the system asks is a request to be allowed to ask; one shown after a refusal
/// is a reply to an answer already given; one shown after the system has closed
/// the door is neither, because nothing this application does can reopen it.
/// Conflating them is how applications end up nagging, so the three are
/// separate types and the wrong offer is not validated at runtime — it does not
/// compile. [IuxSystemWillNotAsk] has no parameter with which to offer an ask.
/// See [IuxPermissionMoment].
///
/// What the type system cannot check is whether the *words* fit the moment, and
/// one assertion covers the case that matters: a moment offering no forward
/// control must be accompanied by [guidance]. See [_kDeadEnd].
///
/// ## The platform boundary
///
/// **This pattern calls no permission API, reads no permission status, and
/// imports nothing platform-specific.** Not as an omission to be filled in
/// later — as the design. Three reasons, in order of how badly each would fail:
///
/// 1. **A framework that asked would be asking on the user's behalf.** The
///    system prompt is answerable a fixed number of times, and spending one of
///    those on a request a widget made during a build is not a mistake an
///    application can recover from: on Android the second refusal closes the
///    door for the lifetime of the installation.
/// 2. **A framework that checked would be wrong somewhere.** Permission models
///    differ by platform, by API level and by permission — foreground and
///    background location, partial photo access, notification permission that
///    did not exist before Android 13. A single abstraction over that either
///    lies about one platform or grows into the plugin it was trying to avoid.
/// 3. **It would put a dependency in the way of every user of the library.** A
///    package that pulled in a permission plugin would drag its manifest
///    entries, its platform channels and its release cadence into applications
///    that never touch a permission.
///
/// So the application makes the call, and hands this pattern the answer as a
/// [IuxPermissionMoment]. A typical mapping, which is the *caller's* to write
/// and is given here only so nobody has to invent it:
///
/// | Platform answer | Moment |
/// | --- | --- |
/// | not asked yet; or granted in part and more can be asked for | [IuxBeforeAsking] |
/// | denied, and the platform says a rationale should be shown | [IuxAfterRefusal] |
/// | denied and the prompt no longer appears; restricted by policy | [IuxSystemWillNotAsk] |
/// | granted | render the feature — there is no rationale to show |
///
/// ## What it puts on screen
///
/// An optional decorative glyph, the title, the reason, the guidance, and then
/// the controls — the refusal first, the forward control after it.
///
/// **The refusal comes first**, which is `IuxDialog`'s ordering and is chosen
/// twice over here. It is the first control reached by keyboard, by D-pad and
/// by a screen-reader swipe, so the way out is never something the user has to
/// travel past a request to find; and the control that opens a system prompt is
/// never the one sitting under the next Enter press.
///
/// Both controls are `IuxButton`s. There is no parameter that would draw the
/// refusal as a bare word beside a filled rectangle, because that asymmetry —
/// not the wording, and not the order — is what makes a permission screen feel
/// like a trap.
///
/// The text is aligned to the start rather than centred, which is where this
/// diverges from `IuxEmptyState`. A rationale is a paragraph the user has to
/// read and weigh, and centred running text gives both edges a ragged start
/// for the eye to find on every line. An empty state's one-line title does not
/// pay that cost; two or three sentences of argument do.
///
/// It draws no surface and no tint. A tint would have to come from a feedback
/// category, and none of them is true here: nothing has failed, nothing has
/// succeeded, and labelling a request "Information" adds a category word the
/// user must hear before the sentence that matters.
///
/// It animates nothing, so there is nothing for a reduced-motion preference to
/// remove. It emits no feedback: a component emits feedback only when the
/// parent supplies the event.
///
/// ## Reaching both controls
///
/// **The refusal is first, so the refusal is the one that survives a short
/// viewport.** That ordering is right for a keyboard and right for a screen
/// reader, and it has one consequence nobody chose: when the block is taller
/// than the fold, the fold falls *between* the two controls before it falls
/// above both. Measured on 320×640 at 150% text, with a glyph, a reason and a
/// guidance — the refusal took its tap and the ask did not. **The user could
/// refuse and could not accept**, which is the asymmetry this pattern refused to
/// build deliberately, arriving through layout instead.
///
/// So the block scrolls itself **when, and only when, it is given a bounded
/// height**. That is the entire rule, and it is read off the constraints rather
/// than asked for in a parameter, because the constraints already answer the
/// question the parameter would have asked:
///
/// - Every vertical scroll view in Flutter hands its children an unbounded
///   height — that is what makes it a scroll view. A block placed in a sheet or
///   a list that already scrolls therefore sees an unbounded height, adds
///   nothing, and the rule that it must not introduce a second scroll view holds
///   structurally instead of by convention. There is no flag to forget.
/// - A block given a bounded height has been told the size of the box it may
///   occupy by something that is not going to scroll it. That is the case where
///   the difference is a choice the user can make or only half of one.
///
/// Nothing moves when the content fits. A `SingleChildScrollView` sizes itself
/// to its child up to the height it was given, so a block that fits keeps its
/// position and its size, and its scroll view accepts no drag because there is
/// nothing to scroll.
///
/// What this cannot do is make a 900-pixel block fit in 640 pixels. Reaching the
/// lower control still means scrolling to it — WCAG SC 1.4.10 asks for one
/// direction of scrolling, not for none — and what changed is that both answers
/// are reachable, which is the only state in which the question is honest.
///
/// ## Accessibility
///
/// **The request is announced, unconditionally.** The title, the reason and the
/// guidance form one live region, so the platform speaks the whole argument
/// once, in place, and the user can go back over it. `IuxEmptyState` takes an
/// arrival dimension and stays silent when a screen opened that way; this does
/// not, and the asymmetry is the same one `IuxErrorRecovery` argues: a region
/// that is empty may always have been, but **a request is an event by
/// definition**. A question nobody heard is not a question. The cost of being
/// wrong is one duplicated sentence for a user who then swipes into the block;
/// the cost the other way is a request that reaches only the users who can see
/// it (WCAG SC 4.1.3).
///
/// `IuxSemantics.liveRegion` is used rather than an announcement API, because
/// an announcement on Android clears TalkBack's speech queue and cuts off
/// whatever the user was listening to.
///
/// **Focus is not moved, and there is no hook to move it.** This reaches
/// `IuxEmptyState`'s and `IuxErrorRecovery`'s conclusion rather than
/// `IuxValidationSummary`'s, and the difference is what the framework knows.
/// `IuxForm` moves focus to its summary because it built that summary in
/// response to a submission it watched the user make, so it knows they are
/// standing still waiting for an answer. Nothing here knows that: this block is
/// rendered by a parent, and the parent may be rendering it because the user
/// tapped a feature, because a settings row expanded, or because a screen
/// opened with it already on it. Moving focus in the last two cases interrupts
/// a user to announce something they did not ask about.
///
/// The specific hazard is worse than interruption, and it is worse here than
/// anywhere else in the library. Focus landing on a control arms it under the
/// next Enter or the next screen-reader double-tap — and the control this block
/// offers opens the operating system's permission prompt. A retry fired by
/// accident costs a request; a permission prompt fired by accident costs the
/// user an answer they cannot get back, because a refusal they never meant to
/// give can close the prompt permanently. The live region says everything focus
/// would have said and arms nothing.
///
/// **The argument is one stop, the controls are two more.** Title, reason and
/// guidance merge into a single node, so a screen-reader user hears the whole
/// case as one utterance rather than landing on three fragments. Each control
/// keeps its own node, because each is somewhere the user has to be able to
/// land — `IuxSemantics.contentContainer` is what preserves that.
///
/// **Nothing is carried by colour** (SC 1.4.1). The moment reaches the user
/// through the wording and through which controls exist, never through a tint;
/// there is no tint. The glyph is excluded from the semantic tree outright
/// (SC 1.1.1) and cannot be the only carrier of anything, because [title] and
/// [reason] are both required and neither may be empty.
///
/// Target size, focus indication, keyboard and D-pad activation and text
/// scaling on the controls are `IuxButton`'s, which is why this pattern
/// delegates to it rather than drawing controls of its own.
///
/// ## Known limitations
///
/// **A live region is a request, not a guarantee.** Whether the platform speaks
/// it, and when, is the platform's decision; a widget test can assert the node
/// carries the flag and no more, so TalkBack remains a manual check. Nothing
/// essential depends on it — the same words are on screen either way.
///
/// **Nothing here can stop an application nagging.** The pattern starts no
/// loop — it renders nothing on its own, calls no platform API, counts nothing
/// and waits for nothing — but a parent that rebuilds this block on every entry
/// to a screen will ask every time, and no widget can prevent that. IUX holds
/// the shape of the conversation; its cadence belongs to the application, which
/// is why [IuxPermissionMoment.decline] is required: it is the signal a caller
/// records in order to stop.
///
/// **The block scrolls only where it was given a bounded height.** See
/// "Reaching both controls". One case is left standing: a caller who places it
/// in an unbounded, non-scrolling context — a `Column` inside a fixed-height
/// box — still owns that overflow, because a scroll view cannot be built in an
/// unbounded height at all. Flutter reports it as a flex overflow, which is the
/// same report every other widget in that column gets.
///
/// **Intrinsic dimensions are not available** through the layout builder that
/// reads the constraints, so a caller wrapping the block in an `IntrinsicHeight`
/// will be told so by Flutter rather than given a wrong number.
///
/// **One permission, one block.** A feature needing three of them is three
/// conversations, and stacking three of these is a screen that asks for
/// everything at once — which is the pattern users learn to refuse wholesale.
/// Ask for each where it is used.
///
/// **The assertions are debug-only.** A release build with a dead end will
/// render one. The rules are teaching tools, not runtime guards.
class IuxPermissionRationale extends StatelessWidget {
  /// Creates a permission rationale.
  ///
  /// The constructor stays `const`, so the dead-end check in [_debugWayForward]
  /// runs at build time rather than here. It reads a getter on [moment], and a
  /// getter call is not a constant expression — a `const` constructor whose
  /// assertion touched one would not compile. This is the same division
  /// `IuxEmptyState` and `IuxDestructiveActionController` make.
  const IuxPermissionRationale({
    super.key,
    required this.moment,
    required this.title,
    required this.reason,
    this.guidance,
    this.illustration,
  })  : assert(title.length > 0, _kEmptyTitle),
        assert(reason.length > 0, _kEmptyReason),
        assert(guidance == null || guidance.length > 0, _kEmptyGuidance);

  /// Where the conversation stands, and therefore what may be offered.
  ///
  /// See [IuxPermissionMoment]. Choosing the member is the one decision this
  /// pattern asks the caller to make deliberately, because it is the one that
  /// depends on a platform answer no framework may read on the caller's behalf.
  final IuxPermissionMoment moment;

  /// What is being asked for, in the user's terms and already localised.
  ///
  /// Name the thing the user gets, not the permission: "Scan receipts with your
  /// camera?" rather than "Camera permission". The user is not short of a
  /// permission; they are short of a feature, and the permission is the
  /// application's problem described in the application's vocabulary.
  ///
  /// Required. It is the first thing a screen reader announces, and with
  /// [illustration] hidden from the semantic tree it is where the block starts
  /// for everybody.
  final String title;

  /// Why the application wants it, already localised.
  ///
  /// **The sentence this pattern exists to carry.** Two things earn their place
  /// here and both are the caller's to judge: what the application does with
  /// the permission, and what the user gets in exchange. "So we can improve
  /// your experience" is neither, and a user who has been told that has been
  /// told they are not owed a reason.
  ///
  /// Say what is true and say what is bounded. "Photographs are read on this
  /// device and never uploaded" is a claim the user can weigh; "we take your
  /// privacy seriously" is not a claim at all.
  ///
  /// Required, and separate from [title] for the reason `IuxDialog` keeps its
  /// own two apart: a title states a topic, and a user cannot agree to a topic.
  final String reason;

  /// What happens without the permission, and who can change that — already
  /// localised.
  ///
  /// The second sentence, and the one that does the work when there is no
  /// forward control to offer: "You can still add receipts by hand", "Your
  /// work profile manages camera access; your IT administrator can turn it
  /// on". A way out made of words, and for a device somebody else administers
  /// it is the only honest one.
  ///
  /// Optional, except where it is the only way forward left — see [_kDeadEnd].
  final String? guidance;

  /// A glyph shown above the title, carrying nothing.
  ///
  /// An [IconData] rather than a widget, for the reason every other IUX glyph
  /// slot is: a widget could arrive carrying its own colour, and the contrast
  /// guarantee would leave with it. Drawn at secondary emphasis, because a
  /// picture that outshouts the argument beside it has the emphasis backwards.
  ///
  /// It is hidden from assistive technology outright rather than described
  /// (WCAG SC 1.1.1). A camera glyph above the words "Scan receipts with your
  /// camera?" adds nothing to the sentence, and a description of decoration is
  /// noise a screen-reader user steps through on every visit.
  final IconData? illustration;

  @override
  Widget build(BuildContext context) {
    assert(_debugWayForward());

    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final String? guidance = this.guidance;
    final IconData? illustration = this.illustration;

    // One node, one utterance, one live region. Merged so the whole argument
    // arrives as a single stop rather than as three fragments the user lands on
    // separately, and live because a request nobody heard is not a request.
    final Widget message = MergeSemantics(
      child: IuxSemantics.liveRegion(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: type.title.copyWith(color: colors.content.primary),
              // No line limit and no ellipsis, at any text size. Half a reason
              // is a reason the user cannot weigh, and truncation gets worse
              // exactly when someone has enlarged their text because they were
              // struggling to read.
              softWrap: true,
            ),
            const IuxGap.tight(),
            Text(
              reason,
              // The substance rather than a caption, so it takes the primary
              // content role: a justification set in the secondary colour
              // reads as small print, which is what an application with a weak
              // reason would want and this pattern refuses to provide.
              style: type.body.copyWith(color: colors.content.primary),
              softWrap: true,
            ),
            if (guidance != null) ...<Widget>[
              const IuxGap.tight(),
              Text(
                guidance,
                style: type.body.copyWith(color: colors.content.secondary),
                softWrap: true,
              ),
            ],
          ],
        ),
      ),
    );

    final Widget block = IuxSemantics.contentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (illustration != null) ...<Widget>[
            IuxIcon(
              icon: illustration,
              description: const IuxImageDescription.decorative(),
              emphasis: IuxIconEmphasis.secondary,
            ),
            const IuxGap.standard(),
          ],
          message,
          const IuxGap.between(),
          // Wraps to a second line rather than overflowing: at a large text
          // scale two controls stop fitting side by side, and stacking is the
          // only outcome in which both stay usable. It also keeps the target
          // spacing floor, so a refusal is never a thumb's width from an ask.
          IuxTargetSpacing(
            axis: Axis.horizontal,
            children: _controls(),
          ),
        ],
      ),
    );

    // See "Reaching both controls". The constraints decide, not a parameter: a
    // bounded height means nobody above is going to scroll this block, and an
    // unbounded height is what every vertical scroll view hands its children,
    // so a block that is already inside one adds nothing.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedHeight) return block;
        // Sizes itself to the block up to the height it was given, so a block
        // that fits keeps its size and takes no gesture.
        return SingleChildScrollView(child: block);
      },
    );
  }

  /// The refusal, then the forward control if the moment has one.
  ///
  /// The refusal is first in every moment, so it is first for a keyboard, a
  /// D-pad and a screen-reader swipe — and so the control that opens a system
  /// prompt is never the one an accidental activation reaches.
  List<Widget> _controls() {
    final IuxInlineFeedbackAction decline = moment.decline;
    final List<Widget> controls = <Widget>[
      IuxButton(
        label: decline.label,
        action: moment.declineDescriptor,
        onActivate: decline.onActivate,
      ),
    ];

    final IuxInlineFeedbackAction? offer = moment.action;
    final IuxActionDescriptor? offerAction = moment.actionDescriptor;
    if (offer != null && offerAction != null) {
      controls.add(
        IuxButton(
          label: offer.label,
          action: offerAction,
          // The descriptor is derived, so this callback is only ever reached
          // for an activation the action policy already accepted — and it can
          // never be reached for a control announced as a retry.
          onActivate: offer.onActivate,
        ),
      );
    }

    return controls;
  }

  /// Checks that the user is left somewhere to go, in debug only.
  ///
  /// Returns true so it can be used inside an `assert`; it never returns false,
  /// because the failure is worth its own sentence.
  bool _debugWayForward() {
    assert(moment.action != null || guidance != null, _kDeadEnd);
    return true;
  }
}
