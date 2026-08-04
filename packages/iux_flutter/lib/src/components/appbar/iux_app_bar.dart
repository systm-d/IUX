import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import '../button/iux_button.dart';

/// The largest number of actions an app bar accepts.
///
/// Three, and it is enforced rather than advised. An app bar is the narrowest
/// strip in an application, every action in it is an unlabelled glyph, and each
/// one takes width away from the only thing on screen that says where the user
/// is. A fourth action is the point at which the bar stops being a place to
/// look and becomes a place to search.
///
/// A screen with more actions than this needs a menu, a bottom bar or a
/// contextual surface — none of which are this component's job.
const int kIuxAppBarMaximumActions = 3;

/// Assumed title size when a theme supplies a title style without one.
///
/// Only used to work out how much room the title needs before it is laid out.
/// An IUX theme always sets a size; this keeps a hand-built theme from
/// crashing the layout decision.
const double _assumedTitleSize = 16;

/// The shortest title fragment worth leaving on a shared line.
///
/// Below roughly a dozen characters a wrapping title turns into a column of
/// syllables, which is harder to read than the same words on their own line.
/// A hypothesis, not a measurement.
const int _minimumTitleCharacters = 12;

/// Roughly half the font size per character, for a proportional Latin face.
///
/// The same crude conversion `IuxContentWidthResolver` uses, and crude for the
/// same reason: an exact measurement would need the actual font, and being
/// generous is safer than clipping. It will be wrong for CJK and for monospace.
const double _averageCharacterWidthRatio = 0.5;

/// The way up and out of a screen: back, or close.
///
/// A dedicated type rather than a `Widget` slot, because the up affordance is
/// the control most often shipped without a name — a bare chevron that a screen
/// reader announces as "button" and nothing else. Here the name is a required
/// constructor argument, so an unnamed one cannot be written.
///
/// It reports intent and nothing more. [onActivate] is called; what happens
/// next is the parent's decision. A component that navigated would be deciding
/// where the user goes, which it cannot know — see
/// `docs/components/component-standard.md` §1.
@immutable
final class IuxAppBarLeading {
  /// Returns to wherever the user came from.
  ///
  /// [label] is the accessible name, already localised — "Back", "Retour",
  /// "Back to orders". Prefer naming the destination when the screen has one:
  /// "Back" tells a screen-reader user that they will leave and refuses to say
  /// where they will land.
  const IuxAppBarLeading.back({
    required this.label,
    required this.onActivate,
    this.hint,
  })  : assert(
          label.length > 0,
          'The way back must be named. A bare chevron with no accessible name '
          'is announced as "button" and nothing else, which is the single most '
          'common app bar failure. Pass the localised name of the action.',
        ),
        icon = Icons.arrow_back,
        _role = IuxActionRole.navigate;

  /// Closes the screen without discarding anything.
  ///
  /// Separate from [IuxAppBarLeading.back] because the two do different things
  /// and look different. Closing a detail sheet loses nothing; going back from
  /// step three of a form does. Announcing and drawing them identically is how
  /// users lose work.
  ///
  /// This is not `cancel`. A control that discards what the user typed needs a
  /// confirmation, which is a pattern's job and not an app bar's.
  const IuxAppBarLeading.close({
    required this.label,
    required this.onActivate,
    this.hint,
  })  : assert(
          label.length > 0,
          'The way out must be named. An unnamed close control is announced as '
          '"button", so a screen-reader user is offered an exit without being '
          'told it is one.',
        ),
        icon = Icons.close,
        _role = IuxActionRole.dismiss;

  /// The accessible name, already localised.
  ///
  /// The framework composes no user-facing text, so there is no default: an
  /// invented English "Back" is what every non-English application would have
  /// shipped untranslated.
  final String label;

  /// What activating this does, when [label] alone is ambiguous.
  final String? hint;

  /// Called once per accepted activation.
  ///
  /// Reports intent. The parent navigates.
  final VoidCallback onActivate;

  /// The glyph, chosen by the constructor.
  ///
  /// Not a parameter. The two glyphs mean two different things, and letting a
  /// call site pass a third is how an application ends up with three ways to
  /// leave a screen and no convention for any of them.
  ///
  /// [Icons.arrow_back] mirrors itself under a right-to-left directionality,
  /// so the arrow points the way out in both reading directions.
  final IconData icon;

  /// What the affordance does in the flow, fixed by the constructor.
  final IuxActionRole _role;

  /// The action this affordance performs.
  ///
  /// Always available: an up affordance that cannot be used is an exit the user
  /// can see and not take, and a screen with no way out should not draw one.
  /// It carries [IuxActionIntent.tertiary] because leaving a screen is never
  /// the action the screen is about.
  IuxActionDescriptor get action => IuxActionDescriptor(
        semantics: IuxActionSemantics(label: label, hint: hint),
        intent: IuxActionIntent.tertiary,
        importance: IuxActionImportance.low,
        role: _role,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAppBarLeading &&
          other.label == label &&
          other.hint == hint &&
          other.onActivate == onActivate &&
          other.icon == icon &&
          other._role == _role;

  @override
  int get hashCode => Object.hash(label, hint, onActivate, icon, _role);
}

/// The top of a screen: its name, the way out, and up to three actions.
///
/// ```dart
/// Scaffold(
///   body: IuxScreen(
///     appBar: IuxAppBar(
///       title: l10n.orders,
///       leading: IuxAppBarLeading.back(
///         label: l10n.backToHome,
///         onActivate: controller.goBack,
///       ),
///       actions: <IuxIconButton>[
///         IuxIconButton(
///           icon: Icons.search,
///           action: IuxActionDescriptor(
///             semantics: IuxActionSemantics(label: l10n.search),
///           ),
///           onActivate: controller.search,
///         ),
///       ],
///     ),
///     page: IuxPage(child: content),
///   ),
/// )
/// ```
///
/// **Put it in an [IuxScreen]** rather than beside an `IuxPage` in a hand-built
/// `Column`. The two are siblings there, so neither can see the other: the top
/// inset gets spent twice and no one owns the total height. `IuxScreen` owns
/// both, and is two parameters wide precisely so there is no reason not to
/// (`IUX-APPBAR-PAGE-001`).
///
/// **Use it** at the top of a screen that has a name worth showing and, usually,
/// a way back out of it.
///
/// **Do not use it** as a toolbar for a section of a page — that is
/// `IuxSectionHeader` — nor as a place to park controls that did not fit
/// elsewhere, nor for a selection mode, a search field or a set of tabs. None
/// of those are here, and all of them are the usual route to an app bar that
/// does four jobs badly.
///
/// ## The title is never truncated
///
/// This is the component's one non-negotiable rule, and everything else in the
/// layout gives way to it. The title is the only thing on screen that says
/// where the user is; an ellipsis in it replaces that answer with a guess.
///
/// So the bar has **no fixed height**. When the title cannot be read beside the
/// controls, the controls keep their row and the title takes the one below,
/// full width, wrapping over as many lines as it needs. The bar grows. Nothing
/// is clipped and nothing is abbreviated.
///
/// The decision is measured rather than assumed: the title stays on the shared
/// row while it either fits there on one line, or still gets enough width to
/// wrap into readable ones. That is why a short title keeps its row at 200%
/// text while a long one gives it up on the same screen.
///
/// ## It is not a `PreferredSizeWidget`, and it does not wrap `AppBar`
///
/// `Scaffold.appBar` is a fixed-height slot: `preferredSize` is read before
/// layout, with no access to the text scale, the available width or the number
/// of lines the title will take, and the slot then caps the bar at exactly that
/// height. A height fixed in advance and a title that must not be truncated
/// cannot both hold. IUX gives up the slot.
///
/// It therefore composes with `Scaffold` the same way `IuxPage` does — by
/// sitting in the body rather than absorbing the frame. What that costs, and
/// what to do instead, is in `docs/components/app-bar.md`.
///
/// ## It measures itself, and it can be asked how tall it wants to be
///
/// The arrangement above is decided by a render object rather than by a
/// `LayoutBuilder`, and that is not an implementation detail. A `LayoutBuilder`
/// can never answer an intrinsic query — it has to build to know anything —
/// so while one was in here **no tree containing an IUX app bar could take part
/// in `IntrinsicHeight`, `IntrinsicWidth` or an intrinsic `Table`**, and the
/// fill-viewport-or-scroll arrangement every application eventually writes threw
/// *LayoutBuilder does not support returning intrinsic dimensions*. That cost
/// the pilot application its pinned title at every text scale
/// (`IUX-APPBAR-PAGE-001`). The bar now reports the height its title needs at a
/// given width, so those arrangements work.
///
/// ## Given a box too short for it, it scrolls rather than overflow
///
/// The bar has no fixed height, so a caller can always hand it less room than
/// its title needs — at 300% text on a short window, the room left over by a
/// navigation bar is routinely less than half of what an enlarged title takes.
/// A `Column` in that position overflows and paints outside itself.
///
/// This does what `IuxBottomNavigation` does at the other end of the screen:
/// the strip scrolls its own content. Nothing is clipped, nothing is
/// abbreviated, the surface and the boundary line still span the box they were
/// given, and the whole title stays reachable — by scrolling, and immediately
/// for a screen reader, which is not stopped by a viewport edge. **Where the bar
/// fits, this scrolls nothing and measures exactly as it did before.**
///
/// Who decides how short that box is, is [IuxScreen]'s job.
class IuxAppBar extends StatelessWidget {
  /// Creates the top of a screen.
  const IuxAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const <IuxIconButton>[],
  }) : assert(
          title.length > 0,
          'A screen has a name. An empty title leaves a bar that occupies the '
          'top of the screen and answers nothing, and leaves a screen-reader '
          'user with no heading to jump to.',
        );

  /// The name of the screen, already localised.
  ///
  /// Exposed as a heading, so a screen-reader user can jump straight to it and
  /// learn where they are instead of listening to the controls first.
  ///
  /// Wraps and is never truncated. Write it as the name of the place, not as a
  /// sentence: a title long enough to need three lines will get them, and will
  /// have pushed the content that far down to do it.
  final String title;

  /// The way up and out of the screen, or null when there is none.
  ///
  /// Null is an answer, not an oversight: a root screen has nowhere to go back
  /// to, and drawing an arrow that returns to nothing is worse than drawing
  /// none.
  final IuxAppBarLeading? leading;

  /// Actions belonging to the screen as a whole.
  ///
  /// Typed as [IuxIconButton] rather than `Widget` on purpose. That widget
  /// takes its accessible name from [IuxActionDescriptor.semantics], which the
  /// action model already requires to be non-empty, so an unnamed app bar
  /// action is unrepresentable. A `Widget` list would reopen exactly that hole,
  /// and an app bar full of unnamed glyphs is the failure this component exists
  /// to prevent.
  ///
  /// They are actions on the *screen*, not on its content. An action that
  /// belongs to one item in a list belongs beside that item, where a
  /// screen-reader user meets it in context.
  final List<IuxIconButton> actions;

  @override
  Widget build(BuildContext context) {
    // Checked here rather than in the constructor because a list's length is
    // not something a `const` invocation can evaluate, and a widget that
    // cannot be `const` costs every call site a rebuild. It still fails on the
    // first build, in debug, before anything is painted.
    assert(
      actions.length <= kIuxAppBarMaximumActions,
      'An app bar takes at most $kIuxAppBarMaximumActions actions, and this '
      'one was given ${actions.length}. Each action is an unlabelled glyph '
      'taking width from the title, and past three the bar stops being a place '
      'to look and becomes a place to search. Move the rest into a menu or '
      'onto the page.',
    );

    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxAccessibility accessibility = IuxAccessibility.of(context);

    final TextStyle titleStyle =
        typography.title.copyWith(color: colors.content.primary);

    final IuxAppBarLeading? up = leading;
    final Widget? upButton = up == null
        ? null
        : IuxIconButton(
            icon: up.icon,
            action: up.action,
            onActivate: up.onActivate,
          );

    return IuxSemantics.contentContainer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          // The same surface as the page below it: an app bar is part of the
          // screen, not a card floating above it.
          color: colors.surface.base,
          // Which makes this line the only visual boundary between the two, so
          // it takes the role that carries a contrast guarantee rather than the
          // decorative one. No shadow: elevation resolves to zero under a
          // reduced visual stimulation preference, and a boundary that a
          // preference can delete is not a boundary.
          border: Border(
            bottom: BorderSide(
              color: colors.border.standard,
              width: geometry.borderWidth,
            ),
          ),
        ),
        // Inside the decoration, so the surface paints behind the status bar
        // while the content clears it. Bottom is left alone: the bar is at the
        // top of the screen and something else owns the other end.
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            // The degradation, and it is the one `IuxBottomNavigation` already
            // documents for the other end of the screen: given a box shorter
            // than the title needs, the strip scrolls rather than clipping the
            // name of the screen or painting outside its own box. It is inside
            // the decoration and outside the padding, so the surface and the
            // boundary line still span whatever box the bar was given.
            //
            // Where the bar fits — which is everywhere the caller left it room
            // — this scrolls nothing and measures exactly as the bare
            // arrangement would.
            physics: const ClampingScrollPhysics(),
            // Never the screen's primary scrollable. That belongs to the page,
            // and two vertical views claiming it is how a `ScrollController`
            // ends up attached to two positions at once.
            primary: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: geometry.spacingXs,
                vertical: geometry.spacingXxs,
              ),
              child: ConstrainedBox(
                // A floor, never a ceiling. The bar is at least as tall as a
                // control it can hold, so bars on screens with and without a
                // back affordance line up; above that it follows its content.
                constraints:
                    BoxConstraints(minHeight: geometry.minimumTouchTarget),
                child: _IuxAppBarArrangement(
                  metrics: _IuxAppBarMetrics(
                    beforeTitle: geometry.spacingSm,
                    edgeInset: geometry.spacingXs,
                    beforeActions: geometry.spacingSm,
                    betweenControls:
                        math.max(geometry.spacingXs, kIuxMinimumTargetSpacing),
                    belowControls: geometry.spacing(IuxSpacingStep.xs),
                    // Enough width to wrap into lines that are still words
                    // rather than syllables. Resolved here, where the text
                    // scale in force is readable, because the render object
                    // below is deliberately given numbers rather than a
                    // `BuildContext`.
                    readableTitle: accessibility.scaleText(
                          titleStyle.fontSize ?? _assumedTitleSize,
                        ) *
                        _averageCharacterWidthRatio *
                        _minimumTitleCharacters,
                  ),
                  leading: upButton,
                  actions: actions.isEmpty
                      ? null
                      // One strip rather than one control pushed to each edge.
                      // It is an IuxTargetSpacing, so the controls keep the
                      // minimum separation between adjacent targets and move to
                      // a second line rather than overflow when the glyphs grow
                      // past the width.
                      : IuxTargetSpacing(
                          axis: Axis.horizontal,
                          children: actions,
                        ),
                  title: IuxSemantics.header(
                    label: title,
                    child: Text(
                      title,
                      style: titleStyle,
                      // No line limit and no ellipsis, here or anywhere else in
                      // this file. Truncation gets worse exactly when a user has
                      // enlarged their text, which is when they can least afford
                      // to lose the words.
                      softWrap: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three places a child of the bar can occupy.
enum _IuxAppBarSlot {
  /// The way up and out, when there is one.
  leading,

  /// The screen's actions, as one strip, when there are any.
  actions,

  /// The name of the screen. Always present.
  title,
}

/// The resolved numbers the arrangement needs, and nothing else.
///
/// A render object has no `BuildContext`, which is the point rather than an
/// inconvenience: everything the layout depends on is resolved once, in
/// `build`, from the same theme and runtime every other IUX component reads.
/// The layout below cannot reach around them because it has nothing to reach
/// with.
@immutable
class _IuxAppBarMetrics {
  const _IuxAppBarMetrics({
    required this.beforeTitle,
    required this.edgeInset,
    required this.beforeActions,
    required this.betweenControls,
    required this.belowControls,
    required this.readableTitle,
  });

  /// Between the way out and a title sharing its row.
  final double beforeTitle;

  /// Before a title with no control in front of it, and around a stacked one.
  ///
  /// It lines the title up with the glyphs above it, which carry the same inset
  /// inside their own targets.
  final double edgeInset;

  /// Between a title sharing the row and the actions after it.
  final double beforeActions;

  /// Between the way out and the actions when both are on the stacked strip.
  final double betweenControls;

  /// Between the stacked control strip and the title below it.
  final double belowControls;

  /// The narrowest width in which a wrapped title is still words.
  final double readableTitle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _IuxAppBarMetrics &&
          other.beforeTitle == beforeTitle &&
          other.edgeInset == edgeInset &&
          other.beforeActions == beforeActions &&
          other.betweenControls == betweenControls &&
          other.belowControls == belowControls &&
          other.readableTitle == readableTitle;

  @override
  int get hashCode => Object.hash(beforeTitle, edgeInset, beforeActions,
      betweenControls, belowControls, readableTitle);
}

/// The bar's two arrangements, chosen by measurement at layout time.
///
/// A render object rather than a `LayoutBuilder`, and the difference is not
/// stylistic: a `LayoutBuilder` has to build before it knows anything, so it
/// can never answer *how tall would you be at this width* — which is what
/// `IntrinsicHeight`, `IntrinsicWidth`, an intrinsic `Table` column and
/// `SliverFillRemaining(hasScrollBody: false)` all ask. While the decision
/// lived in one, every tree containing an IUX app bar was excluded from all of
/// them (`IUX-APPBAR-PAGE-001`).
class _IuxAppBarArrangement
    extends SlottedMultiChildRenderObjectWidget<_IuxAppBarSlot, RenderBox> {
  const _IuxAppBarArrangement({
    required this.metrics,
    required this.leading,
    required this.actions,
    required this.title,
  });

  final _IuxAppBarMetrics metrics;
  final Widget? leading;
  final Widget? actions;
  final Widget title;

  @override
  Iterable<_IuxAppBarSlot> get slots => _IuxAppBarSlot.values;

  @override
  Widget? childForSlot(_IuxAppBarSlot slot) => switch (slot) {
        _IuxAppBarSlot.leading => leading,
        _IuxAppBarSlot.actions => actions,
        _IuxAppBarSlot.title => title,
      };

  @override
  _RenderIuxAppBarArrangement createRenderObject(BuildContext context) =>
      _RenderIuxAppBarArrangement(
        metrics: metrics,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderIuxAppBarArrangement renderObject,
  ) {
    renderObject
      ..metrics = metrics
      ..textDirection = Directionality.of(context);
  }
}

/// Lays the way out, the actions and the title into one row or two.
///
/// The decision is the one the component's document describes, unchanged: the
/// title keeps the shared row while it either fits there on one line or still
/// gets enough width to wrap into readable ones. What changed is where the
/// numbers come from. The control strip used to be *estimated* from the button
/// resolver — one icon button's geometry, multiplied by the number of controls.
/// Here the controls are laid out and measured, so the estimate and the thing
/// it estimated cannot disagree.
class _RenderIuxAppBarArrangement extends RenderBox
    with SlottedContainerRenderObjectMixin<_IuxAppBarSlot, RenderBox> {
  _RenderIuxAppBarArrangement({
    required _IuxAppBarMetrics metrics,
    required TextDirection textDirection,
  })  : _metrics = metrics,
        _textDirection = textDirection;

  _IuxAppBarMetrics get metrics => _metrics;
  _IuxAppBarMetrics _metrics;
  set metrics(_IuxAppBarMetrics value) {
    if (_metrics == value) return;
    _metrics = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox? get _leading => childForSlot(_IuxAppBarSlot.leading);
  RenderBox? get _actions => childForSlot(_IuxAppBarSlot.actions);
  RenderBox? get _title => childForSlot(_IuxAppBarSlot.title);

  /// Painted, hit tested and visited in this order.
  ///
  /// Which is not the reading order and does not need to be: the semantics
  /// compiler sorts siblings by where they ended up, so the announced order
  /// follows the arrangement — the way out, the heading, then the actions on a
  /// shared row; the way out, the actions, then the heading when stacked.
  @override
  Iterable<RenderBox> get children {
    final RenderBox? leading = _leading;
    final RenderBox? actions = _actions;
    final RenderBox? title = _title;
    return <RenderBox>[
      if (leading != null) leading,
      if (actions != null) actions,
      if (title != null) title,
    ];
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  /// The width the controls take out of the row, gaps included.
  double _controlExtent(double leadingWidth, double? actionsWidth) {
    double extent = _leading == null
        ? metrics.edgeInset
        : leadingWidth + metrics.beforeTitle;
    if (actionsWidth != null) extent += metrics.beforeActions + actionsWidth;
    return extent;
  }

  /// Whether the title has to leave the controls' row to stay readable.
  ///
  /// Measured, not assumed. The alternative — branching on the text scale
  /// alone, the way `IuxReadableText.shouldStack` does — would move a two-word
  /// title onto its own line on a wide screen where it fitted perfectly well,
  /// and would leave a long one squeezed into forty pixels on a narrow screen
  /// at ordinary text size. Both are cases this component actually meets.
  bool _stacked({
    required double available,
    required double controls,
    required double titleOneLine,
  }) {
    // Nothing takes width from the title, so it has no row to lose.
    if (_leading == null && _actions == null) return false;
    return available - controls < math.min(titleOneLine, metrics.readableTitle);
  }

  /// Mirrors an offset measured from the leading edge under a right-to-left
  /// directionality, so the way out sits where the user leaves from.
  Offset _place(double start, double top, double width, double available) =>
      Offset(
        textDirection == TextDirection.ltr ? start : available - start - width,
        top,
      );

  /// The whole layout, shared by [performLayout] and [computeDryLayout].
  ///
  /// `positionChild` is null for the dry pass, which is what keeps the two from
  /// drifting: one description of the arrangement, measured twice.
  Size _arrange(
    BoxConstraints constraints,
    ChildLayouter layoutChild, {
    void Function(RenderBox child, Offset offset)? positionChild,
  }) {
    final RenderBox? leading = _leading;
    final RenderBox? actions = _actions;
    final RenderBox title = _title!;

    final BoxConstraints room = BoxConstraints(
      maxWidth:
          constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity,
    );
    final Size leadingSize =
        leading == null ? Size.zero : layoutChild(leading, room);
    final Size actionsSize =
        actions == null ? Size.zero : layoutChild(actions, room);

    final double controls = _controlExtent(
      leadingSize.width,
      actions == null ? null : actionsSize.width,
    );
    final double titleOneLine = title.getMaxIntrinsicWidth(double.infinity);
    // An unbounded width has nothing to be short of, so the bar takes the width
    // its content asks for and keeps the shared row.
    final double available = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : controls + titleOneLine;

    if (!_stacked(
      available: available,
      controls: controls,
      titleOneLine: titleOneLine,
    )) {
      // Takes what the controls left, and never less than nothing: the title is
      // the only flexible thing in the row, so it is the only thing that wraps.
      final double titleWidth = math.max(0, available - controls);
      final Size titleSize =
          layoutChild(title, BoxConstraints.tightFor(width: titleWidth));
      final double height = math.max(
        math.max(leadingSize.height, actionsSize.height),
        titleSize.height,
      );
      if (positionChild != null) {
        if (leading != null) {
          positionChild(
            leading,
            _place(0, (height - leadingSize.height) / 2, leadingSize.width,
                available),
          );
        }
        positionChild(
          title,
          _place(
            // With a control before it the title needs separating from it; with
            // none it needs aligning with the page content below.
            leading == null
                ? metrics.edgeInset
                : leadingSize.width + metrics.beforeTitle,
            (height - titleSize.height) / 2,
            titleWidth,
            available,
          ),
        );
        if (actions != null) {
          positionChild(
            actions,
            _place(
                available - actionsSize.width,
                (height - actionsSize.height) / 2,
                actionsSize.width,
                available),
          );
        }
      }
      return Size(available, height);
    }

    // Stacked: the controls keep their row, the title takes the one below it,
    // full width, wrapping over as many lines as it needs.
    final double stripStart =
        leading == null ? 0 : leadingSize.width + metrics.betweenControls;
    final Size stripSize = actions == null
        ? Size.zero
        // Re-measured against what the way out left, so a strip of enlarged
        // glyphs wraps inside itself rather than past the edge of the bar.
        : layoutChild(
            actions,
            BoxConstraints(maxWidth: math.max(0, available - stripStart)),
          );
    final double controlsHeight =
        math.max(leadingSize.height, stripSize.height);
    final Size titleSize = layoutChild(
      title,
      BoxConstraints(maxWidth: math.max(0, available - metrics.edgeInset * 2)),
    );
    final double titleTop =
        controlsHeight + (controlsHeight > 0 ? metrics.belowControls : 0);

    if (positionChild != null) {
      if (leading != null) {
        positionChild(
          leading,
          _place(0, (controlsHeight - leadingSize.height) / 2,
              leadingSize.width, available),
        );
      }
      if (actions != null) {
        positionChild(
          actions,
          _place(stripStart, (controlsHeight - stripSize.height) / 2,
              stripSize.width, available),
        );
      }
      positionChild(
        title,
        _place(metrics.edgeInset, titleTop, titleSize.width, available),
      );
    }
    return Size(available, titleTop + titleSize.height);
  }

  /// The same arrangement, measured through the intrinsic protocol.
  ///
  /// Separate from [_arrange] because nothing may be laid out during an
  /// intrinsic pass. The two agree by construction: the same decision, the same
  /// gaps, the same widths handed to the same children.
  double _intrinsicHeight(double width) {
    final RenderBox? leading = _leading;
    final RenderBox? actions = _actions;
    final RenderBox title = _title!;

    final double leadingWidth =
        leading == null ? 0 : leading.getMaxIntrinsicWidth(double.infinity);
    final double leadingHeight =
        leading == null ? 0 : leading.getMaxIntrinsicHeight(leadingWidth);
    final double actionsWidth =
        actions == null ? 0 : actions.getMaxIntrinsicWidth(double.infinity);

    final double controls =
        _controlExtent(leadingWidth, actions == null ? null : actionsWidth);
    final double titleOneLine = title.getMaxIntrinsicWidth(double.infinity);
    final double available = width.isFinite ? width : controls + titleOneLine;

    if (!_stacked(
      available: available,
      controls: controls,
      titleOneLine: titleOneLine,
    )) {
      final double actionsHeight =
          actions == null ? 0 : actions.getMaxIntrinsicHeight(actionsWidth);
      return math.max(
        math.max(leadingHeight, actionsHeight),
        title.getMaxIntrinsicHeight(math.max(0, available - controls)),
      );
    }

    final double stripStart =
        leading == null ? 0 : leadingWidth + metrics.betweenControls;
    final double stripHeight = actions == null
        ? 0
        : actions.getMaxIntrinsicHeight(math.max(0, available - stripStart));
    final double controlsHeight = math.max(leadingHeight, stripHeight);
    return controlsHeight +
        (controlsHeight > 0 ? metrics.belowControls : 0) +
        title.getMaxIntrinsicHeight(
          math.max(0, available - metrics.edgeInset * 2),
        );
  }

  /// The width the bar asks for when nothing constrains it: the controls, and
  /// the whole title on one line.
  double _intrinsicWidth(double titleWidth) {
    final RenderBox? leading = _leading;
    final RenderBox? actions = _actions;
    return _controlExtent(
          leading == null ? 0 : leading.getMaxIntrinsicWidth(double.infinity),
          actions?.getMaxIntrinsicWidth(double.infinity),
        ) +
        titleWidth;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _intrinsicWidth(_title!.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _intrinsicWidth(_title!.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
        _arrange(constraints, ChildLayoutHelper.dryLayoutChild),
      );

  @override
  void performLayout() {
    size = constraints.constrain(
      _arrange(
        constraints,
        ChildLayoutHelper.layoutChild,
        positionChild: (RenderBox child, Offset offset) =>
            (child.parentData! as BoxParentData).offset = offset,
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final RenderBox child in children) {
      context.paintChild(
        child,
        (child.parentData! as BoxParentData).offset + offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final RenderBox child in children) {
      final BoxParentData parentData = child.parentData! as BoxParentData;
      final bool hit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
