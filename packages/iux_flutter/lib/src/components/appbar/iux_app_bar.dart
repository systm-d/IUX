import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_button_theme.dart';
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
///   body: Column(
///     children: <Widget>[
///       IuxAppBar(
///         title: l10n.orders,
///         leading: IuxAppBarLeading.back(
///           label: l10n.backToHome,
///           onActivate: controller.goBack,
///         ),
///         actions: <IuxIconButton>[
///           IuxIconButton(
///             icon: Icons.search,
///             action: IuxActionDescriptor(
///               semantics: IuxActionSemantics(label: l10n.search),
///             ),
///             onActivate: controller.search,
///           ),
///         ],
///       ),
///       Expanded(
///         // The bar already consumed the top inset. Anything else double-pads.
///         child: IuxPage(
///           insets: IuxPageInsets.bottomOnly,
///           child: content,
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: geometry.spacingXs,
              vertical: geometry.spacingXxs,
            ),
            child: ConstrainedBox(
              // A floor, never a ceiling. The bar is at least as tall as a
              // control it can hold, so bars on screens with and without a back
              // affordance line up; above that it follows its content.
              constraints:
                  BoxConstraints(minHeight: geometry.minimumTouchTarget),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    _layout(
                  context: context,
                  available: constraints.maxWidth,
                  geometry: geometry,
                  accessibility: accessibility,
                  titleStyle: titleStyle,
                  upButton: upButton,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _layout({
    required BuildContext context,
    required double available,
    required IuxGeometryTheme geometry,
    required IuxAccessibility accessibility,
    required TextStyle titleStyle,
    required Widget? upButton,
  }) {
    final Widget titleWidget = IuxSemantics.header(
      label: title,
      child: Text(
        title,
        style: titleStyle,
        // No line limit and no ellipsis, here or anywhere else in this file.
        // Truncation gets worse exactly when a user has enlarged their text,
        // which is when they can least afford to lose the words.
        softWrap: true,
      ),
    );

    final bool stacked = _titleNeedsItsOwnLine(
      context: context,
      available: available,
      geometry: geometry,
      accessibility: accessibility,
      titleStyle: titleStyle,
    );

    if (!stacked) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (upButton != null) upButton,
          // With a control before it the title needs separating from it; with
          // none it needs aligning with the page content below.
          if (upButton != null)
            const IuxGap.horizontal(IuxSpacingStep.sm)
          else
            const IuxGap.horizontal(IuxSpacingStep.xs),
          // Takes what the controls left. Never shrinks them to nothing and
          // never overflows, because the row's only flexible child is the one
          // that wraps.
          Expanded(child: titleWidget),
          if (actions.isNotEmpty) ...<Widget>[
            const IuxGap.horizontal(IuxSpacingStep.sm),
            IuxTargetSpacing(axis: Axis.horizontal, children: actions),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (upButton != null || actions.isNotEmpty) ...<Widget>[
          // One strip rather than one control pushed to each edge. It is an
          // IuxTargetSpacing, so the controls keep the minimum separation
          // between adjacent targets and move to a second line rather than
          // overflow when the glyphs grow past the width.
          IuxTargetSpacing(
            axis: Axis.horizontal,
            children: <Widget>[
              if (upButton != null) upButton,
              ...actions,
            ],
          ),
          const IuxGap(IuxSpacingStep.xs),
        ],
        Padding(
          // Lines the title up with the glyphs above it, which carry the same
          // inset inside their own targets.
          padding: EdgeInsets.symmetric(horizontal: geometry.spacingXs),
          child: titleWidget,
        ),
      ],
    );
  }

  /// Whether the title has to leave the controls' row to stay readable.
  ///
  /// Measured, not assumed. The alternative — branching on the text scale
  /// alone, the way `IuxReadableText.shouldStack` does — would move a two-word
  /// title onto its own line on a wide screen where it fitted perfectly well,
  /// and would leave a long one squeezed into forty pixels on a narrow screen
  /// at ordinary text size. Both are cases this component actually meets.
  bool _titleNeedsItsOwnLine({
    required BuildContext context,
    required double available,
    required IuxGeometryTheme geometry,
    required IuxAccessibility accessibility,
    required TextStyle titleStyle,
  }) {
    // An unbounded width has nothing to be short of.
    if (!available.isFinite) return false;
    if (leading == null && actions.isEmpty) return false;

    // Every control here is an icon button, and the icon variant resolves the
    // same geometry whichever action it carries — so one resolution answers for
    // all of them. Asking the resolver rather than restating its numbers is
    // what stops this drifting the next time the button changes.
    final IuxButtonTokens tokens = IuxButtonResolver.resolve(
      context,
      leading?.action ?? actions.first.action,
      variant: IuxButtonVariant.icon,
      hasLabel: false,
    );
    final double control = math.max(
      tokens.minimumSize,
      accessibility.scaleText(tokens.iconSize) + tokens.padding.horizontal,
    );
    final double betweenTargets =
        math.max(geometry.spacingXs, kIuxMinimumTargetSpacing);

    double strip =
        leading == null ? geometry.spacingXs : control + geometry.spacingSm;
    if (actions.isNotEmpty) {
      strip += geometry.spacingSm +
          actions.length * control +
          (actions.length - 1) * betweenTargets;
    }

    final double room = available - strip;

    final TextPainter painter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: Directionality.of(context),
      textScaler: accessibility.textScaler,
    )..layout();
    final double oneLine = painter.width;
    painter.dispose();

    // Enough for the whole title on one line, or failing that enough to wrap
    // into lines that are still words rather than syllables.
    final double readable = accessibility.scaleText(
          titleStyle.fontSize ?? _assumedTitleSize,
        ) *
        _averageCharacterWidthRatio *
        _minimumTitleCharacters;

    return room < math.min(oneLine, readable);
  }
}
