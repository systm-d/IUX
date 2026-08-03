import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../layout/iux_surface.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';

/// A block of related content, presented as one object on its own surface.
///
/// ```dart
/// IuxCard(
///   child: Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: <Widget>[Text(order.reference), Text(order.status)],
///   ),
///   actions: <Widget>[IuxButton(label: l10n.track, ...)],
/// )
/// ```
///
/// **Use it** when several pieces of content belong together and the boundary
/// around them has to be visible — an order summary, a search result, one item
/// in a feed.
///
/// **Do not use it to give a screen its structure.** A card draws a boundary;
/// it does not name what is inside. A screen-reader user gets a container and
/// no heading, so a page built only from cards offers nothing to navigate by.
/// `IuxSection` names a group and publishes that name as a heading landmark;
/// put cards inside a section, not sections inside cards. The full comparison
/// is in `docs/components/card.md`.
///
/// **Do not use it around a single control.** A card wrapped around one button
/// is a button with a box drawn round it, and the box costs a screen-reader
/// user an extra container to step through for no information.
///
/// ## Tappable, or containing actions. Never both
///
/// [IuxCard.tappable] makes the whole card one control. The default
/// constructor takes [actions] and is never itself activatable. There is no
/// third form, because the combination of the two is the most common
/// accessibility failure this component has:
///
/// - A screen reader announces the card as a button and then announces the
///   buttons inside it. The user hears controls nested in a control and cannot
///   tell which one they are on.
/// - A sighted user has no way to see where "open the card" stops and "press
///   the button" starts, so the outcome of a tap depends on a boundary they
///   cannot perceive.
/// - Keyboard traversal stops on the card and again on each control inside it,
///   with nothing to say that activating the outer one does something else.
///
/// The two constructors make the sanctioned combination unrepresentable:
/// [IuxCard.tappable] has no [actions] parameter. A control smuggled into
/// [child] instead is caught in debug builds by a subtree check that throws
/// with the offending widget named — see [IuxCard.tappable] for what that
/// check can and cannot see.
///
/// ## Grouping does not rest on elevation
///
/// A card is always bordered and never elevated, and neither is configurable.
/// A shadow is not a grouping signal: the theme resolves elevation to zero
/// under a reduced visual stimulation preference, and a shadow is close to
/// invisible in dark conditions and gone entirely in greyscale. Whatever is
/// left has to be enough on its own, so what is left is surface contrast and
/// an outline — both measurable, and neither of them something a user turns
/// off by accident.
///
/// There is no colour, radius, elevation or padding parameter, and there will
/// not be one, for the same reason a button has none: an API that accepts a
/// colour has already lost the contrast guarantee, because the theme can no
/// longer be held responsible for something a call site overrode.
///
/// ## Reading order
///
/// [child] then [actions], laid out in tree order. Nothing here reorders
/// visually without reordering semantically, so what a sighted user reads
/// top to bottom is what a screen reader announces first to last.
class IuxCard extends StatelessWidget {
  /// Creates a card that presents content and, optionally, its own controls.
  ///
  /// This card is not activatable. When the whole block should respond to a
  /// tap, use [IuxCard.tappable] and move the controls out of it.
  const IuxCard({
    super.key,
    required this.child,
    this.actions,
  })  : semanticLabel = null,
        hint = null,
        onActivate = null,
        autofocus = false,
        focusNode = null;

  /// Creates a card that is itself one control.
  ///
  /// ```dart
  /// IuxCard.tappable(
  ///   semanticLabel: l10n.orderNumber(order.reference),
  ///   hint: l10n.opensTheOrder,
  ///   onActivate: () => open(order),
  ///   child: OrderSummary(order),
  /// )
  /// ```
  ///
  /// The card is announced as a single button whose name is [semanticLabel],
  /// followed by the text the card shows. Descendant semantics are merged in
  /// rather than dropped: a card is one stop for a screen-reader user, and
  /// that one utterance has to carry what a sighted user takes in at a glance.
  ///
  /// [semanticLabel] is required and may not be empty. A container with a tap
  /// handler and no name is announced as "button" and nothing else, which
  /// tells the user that something will happen and refuses to say what.
  ///
  /// **The card must not contain a control.** A debug-only check walks the
  /// content after the first frame and throws when it finds one. It recognises
  /// a `GestureDetector` carrying a tap handler and a `Semantics` node
  /// claiming a button, link, text field, slider or tap action, which between
  /// them cover every IUX control and every Material one. It does not see
  /// custom hit testing, and it is compiled out of release builds: it is a
  /// fast way to find the mistake, not a proof that the mistake is absent.
  const IuxCard.tappable({
    super.key,
    required this.child,
    required String this.semanticLabel,
    required VoidCallback this.onActivate,
    this.hint,
    this.autofocus = false,
    this.focusNode,
  })  : actions = null,
        assert(
          semanticLabel.length > 0,
          'A tappable card needs an accessible name. Without one it is '
          'announced as "button" with nothing after it, and a user who cannot '
          'see the card has no way to know what activating it does. Name the '
          'card by what it is — the button role already says it can be '
          'activated.',
        );

  /// The content, in reading order.
  final Widget child;

  /// Controls belonging to the card as a whole.
  ///
  /// Laid out after [child], with at least the minimum separation between
  /// adjacent targets: two buttons sharing an edge produce mis-taps even when
  /// both are large enough, because a finger landing near the seam has no
  /// margin for error.
  ///
  /// Absent on [IuxCard.tappable], and that absence is the API-level half of
  /// the rule — a card is either a control or it contains controls.
  final List<Widget>? actions;

  /// The accessible name of a tappable card. Null on a plain card.
  final String? semanticLabel;

  /// What activating the card does, when [semanticLabel] leaves it ambiguous.
  ///
  /// Read after the name and the role, so write it as an outcome — "opens the
  /// order" — and not as an instruction to double-tap, which the screen reader
  /// already supplies.
  final String? hint;

  /// Called once per accepted activation. Null on a plain card.
  final VoidCallback? onActivate;

  /// Whether a tappable card takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node, for a tappable card.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    // Checked here rather than in the constructor: a list length is not a
    // constant expression, and refusing `const IuxCard(...)` to gain an
    // assertion would be a poor trade.
    assert(
      actions == null || actions!.isNotEmpty,
      'An empty actions list reserves space for controls that do not exist. '
      'Pass null when the card has none, so the card does not grow a gap the '
      'user has to scroll past.',
    );

    final VoidCallback? activate = onActivate;
    if (activate == null) {
      // One object whose parts stay separately reachable, and the mirror image
      // of the tappable card: this one is not a control, so its contents must
      // not collapse into one. A control inside it keeps the node the user
      // lands on, which `IuxSemantics.group` — whose whole purpose is to
      // collapse — cannot express.
      return IuxSemantics.contentContainer(
        child: _IuxCardSurface(child: _content),
      );
    }

    return _IuxTappableCard(
      semanticLabel: semanticLabel!,
      hint: hint,
      onActivate: activate,
      autofocus: autofocus,
      focusNode: focusNode,
      child: _content,
    );
  }

  /// The content column, in the order it is read.
  Widget get _content {
    final List<Widget>? controls = actions;
    if (controls == null || controls.isEmpty) return child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        child,
        const IuxGap.tight(),
        IuxTargetSpacing(axis: Axis.horizontal, children: controls),
      ],
    );
  }
}

/// The surface a card is drawn on.
///
/// Extracted so the plain and tappable forms cannot drift apart: a card whose
/// border appeared only when it was not tappable would make "is this one
/// object" depend on whether it happens to be a link.
///
/// It resolves nothing itself. [IuxSurface] owns colour, border, shape and
/// elevation; this only fixes the choices a card is not allowed to make.
class _IuxCardSurface extends StatelessWidget {
  const _IuxCardSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => IuxSurface(
        role: IuxSurfaceRole.raised,
        bordered: true,
        // Never elevated, at any profile. See IuxCard for why a shadow is not
        // allowed to be the grouping signal.
        padding: IuxInsets.surface(context),
        child: child,
      );
}

/// A card that is itself one control.
///
/// Private because the choice between the two forms belongs to [IuxCard].
/// Exposing this separately would let a caller assemble a third form that is
/// tappable *and* carries actions, which is what the split exists to prevent.
class _IuxTappableCard extends StatefulWidget {
  const _IuxTappableCard({
    required this.semanticLabel,
    required this.hint,
    required this.onActivate,
    required this.autofocus,
    required this.focusNode,
    required this.child,
  });

  final String semanticLabel;
  final String? hint;
  final VoidCallback onActivate;
  final bool autofocus;
  final FocusNode? focusNode;
  final Widget child;

  @override
  State<_IuxTappableCard> createState() => _IuxTappableCardState();
}

class _IuxTappableCardState extends State<_IuxTappableCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final BorderRadius radius = BorderRadius.circular(geometry.radiusMedium);

    // Read from the runtime rather than measured here, so a card and a button
    // cannot end up disagreeing about how large a target has to be.
    final double minimum = IuxAccessibility.of(context).minimumTouchTarget;

    // The press tint fades in so the change is perceptible rather than
    // abrupt. Declared as a state change: a reduced-motion preference shortens
    // the fade and no motion removes it — the tint itself still appears,
    // because the information is the tint and not the fade.
    final IuxResolvedMotion motion = IuxMotionPolicy.resolve(
      context,
      role: IuxMotionRole.stateChange,
      scale: IuxMotionScale.short,
    );

    final Widget visual = Stack(
      children: <Widget>[
        ConstrainedBox(
          // Inside the stack rather than around it. A minimum applied outside
          // would make the stack tall enough while leaving the painted card —
          // and its border — the original size, so the visible object and the
          // region that responds would stop being the same shape.
          constraints: BoxConstraints(minHeight: minimum, minWidth: minimum),
          child: _IuxCardSurface(
            child: _IuxTappableCardContentGuard(child: widget.child),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _pressed ? 1 : 0,
              duration: motion.duration,
              curve: motion.curve,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.state.pressed,
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    // Not IuxSemantics.action, which excludes descendant semantics: that is
    // right for a button whose only content is its own label, and it would
    // delete the price, the status and the date from the interface of every
    // screen-reader user here. contentAction is the form that keeps them —
    // one stop, named, announced as activatable, reading out everything a
    // sighted user sees.
    return IuxSemantics.contentAction(
      label: widget.semanticLabel,
      hint: widget.hint,
      // Carried on the node itself as well as on the gesture detector below
      // it. The merged subtree does supply a tap action today, but a control
      // whose activation depends on a descendant staying put is one refactor
      // away from being announced and inert.
      onTap: widget.onActivate,
      child: IuxFocusable(
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        borderRadius: radius,
        onActivate: widget.onActivate,
        child: GestureDetector(
          // Opaque so the whole card responds, including its padding, and not
          // only the text painted inside it.
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails _) => _setPressed(true),
          onTapUp: (TapUpDetails _) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onActivate,
          child: visual,
        ),
      ),
    );
  }
}

/// Fails loudly, in debug builds, when a tappable card contains a control.
///
/// Placed inside the card's own gesture and semantics layers so the walk
/// starts at the caller's content: the card's own tap handler is an ancestor
/// of this widget and is never mistaken for a violation.
class _IuxTappableCardContentGuard extends StatefulWidget {
  const _IuxTappableCardContentGuard({required this.child});

  final Widget child;

  @override
  State<_IuxTappableCardContentGuard> createState() =>
      _IuxTappableCardContentGuardState();
}

class _IuxTappableCardContentGuardState
    extends State<_IuxTappableCardContentGuard> {
  /// Whether this card has already reported a nested control.
  ///
  /// Without it, a card rebuilt every frame reports the same mistake every
  /// frame and the error the developer needs scrolls out of the log.
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant _IuxTappableCardContentGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-checked on update: a control that appears in only one state of the
    // parent would otherwise never be seen.
    _scheduleCheck();
  }

  void _scheduleCheck() {
    assert(() {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (!mounted || _reported) return;
        final String? offender = _firstInteractiveDescendant(context);
        if (offender == null) return;
        _reported = true;
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'A tappable IuxCard contains an interactive element ($offender).',
          ),
          ErrorDescription(
            'A card that is itself a control and also contains controls has '
            'two answers to "what does tapping do", and nothing on screen '
            'tells the user which one they are about to get. A screen reader '
            'announces the card as a button and then announces the buttons '
            'inside it, so the ambiguity is heard as well as felt.',
          ),
          ErrorHint(
            'Either keep the whole card tappable and move the control outside '
            'it, or use the default IuxCard constructor and pass the control '
            'in `actions`, where it stays its own target with its own name.',
          ),
        ]);
      });
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Names the first control found below [context], or returns null.
///
/// Reports the nearest enclosing IUX widget rather than the raw
/// `GestureDetector` it matched on, because "IuxButton" tells a developer
/// where to look and "GestureDetector" does not.
String? _firstInteractiveDescendant(BuildContext context) {
  String? found;
  String? nearestNamed;

  void visit(Element element) {
    if (found != null) return;
    final Widget widget = element.widget;
    final String type = widget.runtimeType.toString();
    final String? enclosing = nearestNamed;
    if (type.startsWith('Iux')) nearestNamed = type;

    if (_isInteractive(widget)) {
      found = nearestNamed ?? type;
      return;
    }

    element.visitChildren(visit);
    nearestNamed = enclosing;
  }

  context.visitChildElements(visit);
  return found;
}

/// Whether [widget] responds to activation.
///
/// Long press and double tap are deliberately not counted. A tooltip attaches
/// a long-press handler to content that is not a control, and reporting that
/// would train developers to ignore this check — which costs more than missing
/// the rare card whose only nested control is long-press-only.
bool _isInteractive(Widget widget) {
  if (widget is GestureDetector) return widget.onTap != null;
  if (widget is Semantics) {
    final SemanticsProperties properties = widget.properties;
    return properties.button == true ||
        properties.link == true ||
        properties.textField == true ||
        properties.slider == true ||
        properties.onTap != null;
  }
  return false;
}
