import 'package:flutter/widgets.dart';

import '../../accessibility/iux_semantics.dart';
import '../../components/button/iux_button.dart';
import '../../components/media/iux_icon.dart';
import '../../components/media/iux_media_model.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import 'iux_empty_state_model.dart';

/// Why an empty state with no words is refused.
const String _kEmptyTitle =
    'An empty state must say something. Without a title the user is looking at '
    'a blank region and, at best, a glyph — and a glyph is hidden from '
    'assistive technology here, so a screen-reader user is looking at nothing '
    'at all. Pass the localised sentence that says what is missing: "No '
    'invoices match these filters", "You have not added a project yet".';

/// Why an empty guidance string is refused rather than ignored.
const String _kEmptyGuidance =
    'An empty guidance is the same as no guidance, and says so less clearly. '
    'Omit the parameter, or pass the localised sentence that tells the user '
    'what would put something here.';

/// Why a situation that owes a way forward may not offer nothing.
const String _kDeadEnd =
    'This situation owes the user a way forward and offers neither an action '
    'nor guidance, which leaves a screen that says "there is nothing here" and '
    'declines to say what would help. That is a dead end, and it is the single '
    'most common failure of an empty state. Two ways out, and either is '
    'enough: give the cause its action — create, reset, request — or write the '
    'guidance saying what makes something appear and who makes it happen '
    '("Your payslips appear here once payroll files them"). Only '
    'IuxNothingLeftToDo is exempt, because the user is not short of anything.';

/// A region that holds nothing, saying why and what would change that.
///
/// ```dart
/// IuxEmptyState(
///   cause: IuxNoMatches(
///     reset: IuxEmptyStateAction(
///       label: l10n.showAllInvoices,
///       action: const IuxActionDescriptor(
///         semantics: IuxActionSemantics(label: 'Show all invoices'),
///       ),
///       onActivate: controller.clearFilters,
///     ),
///   ),
///   title: l10n.noInvoicesMatchTheseFilters,
///   guidance: l10n.tryAWiderDateRange,
///   arrival: IuxEmptyStateArrival.afterAChange,
/// )
/// ```
///
/// **Use it** wherever a list, a grid, a search result or a whole screen has
/// nothing in it and the user is entitled to know why. It is the answer to the
/// `empty` row of the component standard's state table, which every collection
/// eventually needs and most applications answer with a centred grey sentence
/// that says "No data".
///
/// **Do not use it while a load is running.** "Nothing here" is a statement the
/// interface cannot support until the answer has arrived, and a screen that
/// makes it early is wrong for as long as the request is in flight. Show
/// progress, and reach for this once `IuxLoadState` is ready with an empty
/// value.
///
/// **Do not use it for a failure.** A collection that is empty because the
/// request never came back is not empty, it failed. The two need opposite
/// things — an empty state explains an answer, an error explains a breakdown
/// and offers a retry — and [IuxEmptyStateAction] refuses
/// `IuxActionRole.retry` so that the line cannot be blurred here by accident.
///
/// **Do not use it for a placeholder while content is being written.** A region
/// that will hold something as soon as somebody finishes building the feature
/// is not empty for a reason the user can act on, and this pattern would tell
/// them it is.
///
/// ## The situation decides the way out
///
/// [cause] is not a decorative label. It is the whole design of this pattern:
/// four situations put nothing on a screen and they have four different exits,
/// so the exit travels *inside* the situation and there is no way to pair them
/// wrongly. [IuxNoMatches] takes a reset and requires one; [IuxNothingLeftToDo]
/// takes nothing at all. "Add your first invoice" under a filter that hid forty
/// of them is not validated at runtime here — it does not compile. See
/// [IuxEmptyStateCause].
///
/// What the type system cannot check is whether the *words* match the
/// situation, and one assertion covers the case that matters: a situation that
/// owes the user a way forward must offer either an action or [guidance]. A
/// screen that says "there is nothing here" and stops is a dead end, and it is
/// the failure this pattern exists to prevent.
///
/// ## What it puts on screen
///
/// An optional decorative glyph, the title, the guidance, and the situation's
/// action if it has one — in that order, centred, with nothing else. It draws
/// no surface and no border: an empty region is already surrounded by the space
/// its content would have occupied, and a card around it would suggest there is
/// an object here when the point is that there is not.
///
/// It animates nothing. The block appearing is not a change the user needs help
/// following, and an animation would delay the announcement below to save
/// nothing.
///
/// ## Reaching the way out
///
/// A way out the user cannot reach is not a way out. The control is last, under
/// the sentences that explain it, so it is the first thing to leave a short
/// viewport: on 320×640 at 200% text this block was measured with its reset at
/// y 712–776, **zero** hit-testable controls and **zero** activations, on a page
/// that had nothing else on it and no scroll view anywhere.
///
/// So the block scrolls itself **when, and only when, it is given a bounded
/// height**. That is the entire rule, and it is read off the constraints rather
/// than asked for in a parameter, because the constraints already answer the
/// question the parameter would have asked:
///
/// - Every vertical scroll view in Flutter hands its children an unbounded
///   height — that is what makes it a scroll view. A block embedded in a list
///   that already scrolls therefore sees an unbounded height, adds nothing, and
///   IUX-028's rule that it must not introduce a second scroll view holds
///   structurally instead of by convention. There is no flag to forget.
/// - A block given a bounded height has been told the size of the box it may
///   occupy by something that is not going to scroll it. That is the case where
///   the difference is a reachable control or a dead screen.
///
/// Nothing moves when the content fits. A `SingleChildScrollView` sizes itself
/// to its child up to the height it was given, so a block that fits keeps its
/// position and its size, and its scroll view accepts no drag because there is
/// nothing to scroll — the gesture goes to whatever is above it, exactly as it
/// did before.
///
/// What this cannot do is make a 900-pixel block fit in 640 pixels. Reaching the
/// control still means scrolling to it — WCAG SC 1.4.10 asks for one direction
/// of scrolling, not for none — and what changed is that scrolling to it is now
/// possible.
///
/// ## Accessibility
///
/// **The silence problem.** When a list empties under a filter, the rows go and
/// the explanation appears, and a screen-reader user is told none of it — they
/// are left holding a screen they have no reason to re-read. So the message
/// becomes a live region when [arrival] says the content emptied while the user
/// was looking at it, which is the default. The platform then reads it once, in
/// place, and the user can go back over it. See [IuxEmptyStateArrival] for why
/// the pattern cannot work this out for itself and why the default is the safer
/// of the two.
///
/// **Focus is not moved.** This is the opposite choice from
/// `IuxValidationSummary`, which takes focus when a submission is refused, and
/// the difference is where the user is standing. A refused submission happens
/// after the user pressed a button and is waiting for an answer; a list emptying
/// under a filter happens while their hands are in the search field, and moving
/// focus out of it would interrupt typing to announce the consequence of what
/// they are still typing. The live region says it without taking anything away.
///
/// **The title and the guidance are one stop.** They are merged into a single
/// semantic node, so a screen-reader user hears the whole explanation as one
/// utterance rather than landing on two fragments. The action stays a node of
/// its own, because it is a control and has to remain somewhere the user can
/// land.
///
/// **The glyph carries nothing.** [illustration] is excluded from the semantic
/// tree outright (WCAG SC 1.1.1), and it cannot be the only carrier of the
/// message because [title] is required and must not be empty. An empty state
/// whose meaning lived in its picture would be blank for part of its users.
///
/// Text scaling, target size, focus and disabled semantics on the action are
/// `IuxButton`'s, which is why this pattern delegates to it rather than drawing
/// a control of its own.
///
/// ## Known limitations
///
/// A live region is a request, not a guarantee. Whether the platform speaks it,
/// and when, is the platform's decision: a widget test can assert that the node
/// carries the flag and no more, so TalkBack remains a manual check. Nothing
/// essential depends on the announcement — the same words are on screen either
/// way.
///
/// The block is centred within whatever width it is given.
///
/// It scrolls only where it was given a bounded height, so one case is left
/// standing: a caller who places it in an unbounded, non-scrolling context — a
/// `Column` inside a fixed-height box — still owns that overflow, because a
/// scroll view cannot be built in an unbounded height at all. Flutter reports it
/// as a flex overflow, which is the same report every other widget in that
/// column gets.
///
/// Intrinsic dimensions are not available through the layout builder that reads
/// the constraints, so a caller wrapping the block in an `IntrinsicHeight` will
/// be told so by Flutter rather than given a wrong number.
class IuxEmptyState extends StatelessWidget {
  /// Creates an empty state.
  ///
  /// The constructor stays `const`, so the dead-end check in [_debugWayForward]
  /// runs at build time rather than here. It reads a getter on [cause], and a
  /// getter call is not a constant expression — a `const` constructor whose
  /// assertion touched one would not compile at all. This is the same division
  /// `IuxDestructiveActionController` makes, for the same reason: the check is
  /// worth more than the line it is checked on.
  const IuxEmptyState({
    super.key,
    required this.cause,
    required this.title,
    this.guidance,
    this.arrival = IuxEmptyStateArrival.afterAChange,
    this.illustration,
  })  : assert(title.length > 0, _kEmptyTitle),
        assert(guidance == null || guidance.length > 0, _kEmptyGuidance);

  /// Why there is nothing here, and therefore what the way out is.
  ///
  /// See [IuxEmptyStateCause]. Choosing the member is the one decision this
  /// pattern asks the caller to make deliberately, because it is the one no
  /// framework can make for them.
  final IuxEmptyStateCause cause;

  /// What is missing, already localised.
  ///
  /// One sentence, naming the thing rather than the state: "No invoices match
  /// these filters" rather than "No results". The user knows the region is
  /// empty — they are looking at it — so a title that only restates that spends
  /// their attention and returns nothing.
  ///
  /// It is the first thing a screen reader announces and it is required for
  /// that reason: with [illustration] hidden from the semantic tree, this is
  /// the whole of what a screen-reader user receives before the action.
  final String title;

  /// What would put something here, already localised.
  ///
  /// The second sentence, and the one that does the work when there is no
  /// control to offer: *what* makes something appear, and *who* makes it happen.
  /// "Your payslips appear here once payroll files them" is a way out made of
  /// words, and for a collection somebody else fills it is the only honest one.
  ///
  /// Optional, except where it is the only way forward left — see [_kDeadEnd].
  final String? guidance;

  /// How this empty state got in front of the user, which decides whether it is
  /// announced.
  ///
  /// See [IuxEmptyStateArrival]. Defaults to
  /// [IuxEmptyStateArrival.afterAChange], the safer of the two: used there by
  /// mistake, a screen that opened empty is announced once more than it needed
  /// to be, and used the other way by mistake a list that emptied says nothing
  /// at all.
  final IuxEmptyStateArrival arrival;

  /// A glyph shown above the title, carrying nothing.
  ///
  /// An [IconData] rather than a widget, for the reason every other IUX glyph
  /// slot is: a widget could arrive carrying its own colour, and the contrast
  /// guarantee would leave with it. It is drawn from the theme at secondary
  /// emphasis, because an illustration that outshouts the sentence beside it
  /// has the emphasis backwards — the sentence is the message.
  ///
  /// It is hidden from assistive technology outright rather than described. A
  /// description of decoration is noise a screen-reader user steps through on
  /// every visit, and anything the picture would need to say is already in
  /// [title].
  final IconData? illustration;

  @override
  Widget build(BuildContext context) {
    assert(_debugWayForward());

    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxEmptyStateAction? exit = cause.action;
    final String? guidance = this.guidance;
    final IconData? illustration = this.illustration;

    // Merged into one node, so the explanation is one utterance rather than two
    // fragments the user lands on separately. The live region rides on the same
    // node: a container above it would be announced with no label of its own,
    // which is a change reported and not described.
    Widget message = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: type.title.copyWith(color: colors.content.primary),
          textAlign: TextAlign.center,
          // No line limit and no ellipsis, at any text size. Half a sentence
          // about why a screen is empty is an explanation the user cannot act
          // on, and truncation gets worse exactly when someone has enlarged
          // their text because they were struggling to read.
          softWrap: true,
        ),
        if (guidance != null) ...<Widget>[
          const IuxGap.tight(),
          Text(
            guidance,
            style: type.body.copyWith(color: colors.content.secondary),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ],
      ],
    );

    if (arrival == IuxEmptyStateArrival.afterAChange) {
      message = IuxSemantics.liveRegion(child: message);
    }
    message = MergeSemantics(child: message);

    final Widget block = IuxSemantics.contentContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (illustration != null) ...<Widget>[
            IuxIcon(
              icon: illustration,
              description: const IuxImageDescription.decorative(),
              // Secondary, and never the sole carrier of anything: the glyph
              // qualifies the sentence below it and says nothing the sentence
              // does not.
              emphasis: IuxIconEmphasis.secondary,
            ),
            const IuxGap.standard(),
          ],
          message,
          if (exit != null) ...<Widget>[
            const IuxGap.between(),
            IuxButton(
              label: exit.label,
              action: exit.action,
              busyHint: exit.busyHint,
              onActivate: exit.onActivate,
            ),
          ],
        ],
      ),
    );

    // See "Reaching the way out". The constraints decide, not a parameter: a
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

  /// Checks that the user is left somewhere to go, in debug only.
  ///
  /// Returns true so it can be used inside an `assert`; it never returns false,
  /// because the failure is worth its own sentence.
  bool _debugWayForward() {
    assert(
      !cause.requiresWayForward || cause.action != null || guidance != null,
      _kDeadEnd,
    );
    return true;
  }
}
