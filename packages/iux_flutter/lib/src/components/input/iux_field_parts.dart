/// The parts every IUX field wears, shared so that two fields cannot wear them
/// differently.
///
/// Package-internal: nothing here is exported. These are not components in
/// their own right — they express no intent, take no descriptor, and mean
/// nothing outside a field. They live in their own file only because Dart
/// privacy is per-file, and a box drawn twice is a box that will eventually be
/// drawn two ways.
///
/// The reason to share rather than copy is the one `IuxInputDescriptor` gives
/// for existing at all: a text field and a select must not disagree about what
/// "read-only and invalid" looks like. A caller who learns one field learns
/// them all, and that only holds while the chrome is one piece of code.
library;

import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import '../../inputs/iux_input_theme.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../themes/extensions/iux_geometry_theme.dart';

/// The outlined box a field's contents sit in.
///
/// Moved here from `iux_text_field.dart` when the select needed the same box.
/// The behaviour is unchanged, and the text field's existing tests are what
/// says so.
class IuxFieldContainer extends StatelessWidget {
  /// Draws the box described by [tokens] around [child].
  const IuxFieldContainer({
    super.key,
    required this.tokens,
    required this.geometry,
    required this.child,
  });

  /// The resolved appearance of the field in its current state.
  final IuxInputTokens tokens;

  /// The ambient geometry, for the border width an invalid field grows to.
  final IuxGeometryTheme geometry;

  /// What the box contains.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Declared as a state change, so a reduced-motion preference shortens it
    // and no motion removes it — without the colour change itself ever being
    // lost.
    final IuxResolvedMotion motion = IuxMotionPolicy.resolve(
      context,
      role: IuxMotionRole.stateChange,
      scale: IuxMotionScale.short,
    );

    // An invalid field draws a thicker outline. Left uncompensated, that
    // thickening would grow the box by two pixels and push the help text and
    // the error down the screen — so the padding gives back exactly what the
    // border takes, and the field stays where the user left it.
    final double reserved = geometry.strongBorderWidth - tokens.borderWidth;

    return AnimatedContainer(
      duration: motion.duration,
      curve: motion.curve,
      constraints: BoxConstraints(minHeight: tokens.minimumSize),
      padding: tokens.padding + EdgeInsets.all(reserved),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(resolveFieldRadius(tokens)),
        border: Border.all(color: tokens.border, width: tokens.borderWidth),
      ),
      child: child,
    );
  }
}

/// The corner radius of a field box.
///
/// `IuxShape.full` arrives as infinity, because the theme cannot know how tall
/// the field will be. Half the minimum target is the answer for a single-line
/// field and an under-estimate for a multi-line one, which rounds its corners
/// less than asked rather than clipping its own text.
double resolveFieldRadius(IuxInputTokens tokens) =>
    tokens.radius.isFinite ? tokens.radius : tokens.minimumSize / 2;

/// A validation message, announced when it is news and merely present when it
/// is not.
///
/// A live region rather than an announcement: Android deprecated
/// `announceForAccessibility` because it clears TalkBack's speech queue, so an
/// announcement cuts off whatever the user was listening to. A live region is
/// spoken in place, once, and the user can go back and re-read it.
///
/// The text is always on screen. An error that only a screen reader hears is an
/// error a sighted user with a cognitive impairment never finds.
///
/// [announce] is what makes "when it appears" true. A message the field was
/// already showing when it arrived on screen keeps its node and its words and
/// loses only the flag, so nothing is unreachable — it is simply not shouted
/// over whatever moved the user here.
class IuxFieldValidationMessage extends StatelessWidget {
  /// Shows [message], announcing it when [announce] is set.
  const IuxFieldValidationMessage({
    super.key,
    required this.message,
    required this.style,
    required this.announce,
  });

  /// The already-localised message.
  final String message;

  /// How the message is drawn.
  final TextStyle style;

  /// Whether this message is a change the user did not see arrive.
  final bool announce;

  @override
  Widget build(BuildContext context) {
    // The visual repeats the label verbatim, so it is excluded to keep the
    // message from being read twice — the same shape the progress indicator
    // uses.
    final Widget text = IuxSemantics.decorative(
      child: Text(message, style: style),
    );
    // The same container either way, so turning the flag on later changes one
    // property of one node rather than replacing it — which is what keeps a
    // message that becomes news from being announced twice.
    return announce
        ? IuxSemantics.liveRegion(label: message, child: text)
        : IuxSemantics.group(label: message, child: text);
  }
}
