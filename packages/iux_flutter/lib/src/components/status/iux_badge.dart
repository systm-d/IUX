import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import 'iux_status_tokens.dart';

/// A count or a marker attached to something else.
///
/// ```dart
/// IuxBadge.count(count: l10n.formatCount(3), label: l10n.unreadMessages(3))
///
/// IuxBadge.marker(label: l10n.unreadMessages)
/// ```
///
/// **Use it** to say how many of something are waiting, or merely that some
/// are. It is the marker beside a mailbox, a filter or a tab.
///
/// **Do not use it** to report a state — an order that failed is
/// `IuxStatusIndicator`, which has room to say so. Do not use it as a control:
/// a badge is never tappable, and the thing it decorates owns both the gesture
/// and the touch target. Do not use it to draw attention to something that is
/// not countable; a badge with nothing behind it trains users to ignore badges.
///
/// **Accessibility.** A badge announces its subject, never its number alone.
/// "3" is meaningless to anyone who has not already worked out what it refers
/// to, and a screen-reader user landing on it hears a digit with no noun. So
/// [label] is required, and it may not repeat the count — the assertion fires on
/// `IuxBadge.count(count: '3', label: '3')`, which is the exact shape of the
/// mistake.
///
/// A badge that shows no number is not a colour-alone failure: what carries the
/// meaning is that the marker is *there*, and presence and absence survive a
/// monochrome screen. What would fail is two markers of different colours
/// meaning different things, which is why a badge has one tone and no others.
///
/// **Placement.** Put it beside what it counts, in reading order — a row of
/// label then badge. IUX offers no overlay: a badge floating over the corner of
/// an icon covers the glyph, clips as soon as the user enlarges their text, and
/// leaves the badge and its subject in two unrelated places in the reading
/// order.
class IuxBadge extends StatelessWidget {
  /// A badge showing how many.
  ///
  /// `count` is what the eye reads and [label] is what the ear hears, and they
  /// are separate parameters because they are different strings: `3` against
  /// `3 unread messages`.
  const IuxBadge.count({
    super.key,
    required String count,
    required this.label,
  })  : assert(
          count.length > 0,
          'A counted badge must show a number. Pass IuxBadge.marker when there '
          'is nothing to count and only presence to report.',
        ),
        assert(
          label.length > 0,
          'A badge must announce what it counts. Without a label a screen '
          'reader reads a bare digit, which tells the user how many of nothing '
          'they have.',
        ),
        assert(
          label != count,
          'The label repeats the number instead of naming its subject. "3" is '
          'meaningless; "3 unread messages" is information. Pass the localised '
          'sentence, not the numeral a second time.',
        ),
        _count = count;

  /// A badge showing only that there is something.
  ///
  /// For the case where the number is unknown, irrelevant, or too large to be
  /// worth reading — "you have unread messages" rather than "you have 47".
  const IuxBadge.marker({super.key, required this.label})
      : assert(
          label.length > 0,
          'A marker is a shape with no text in it, so the label is the only '
          'thing that says what it means. Without one it is decoration that '
          'implies something needs attention and refuses to say what.',
        ),
        _count = null;

  /// What this counts, already localised, and never empty.
  ///
  /// The whole announcement, not the noun on its own: IUX will not join a
  /// number to a word, because `3 unread messages`, `3 messages non lus` and
  /// `٣ رسائل غير مقروءة` differ in more than vocabulary and only the caller
  /// knows which applies.
  final String label;

  /// The visible numeral, already localised and formatted, or null.
  ///
  /// A string rather than an int, for the same reason `IuxProgressIndicator`
  /// takes its value in words: `3`, `٣` and `99+` are three different strings,
  /// and a component that formatted the number itself would ship Western
  /// numerals into every locale and invent its own overflow marker.
  final String? _count;

  @override
  Widget build(BuildContext context) {
    final IuxBadgeTokens tokens = IuxBadgeResolver.resolve(context);
    final String? count = _count;

    final Widget visual = count == null
        ? SizedBox.square(
            dimension: tokens.markerSize,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: tokens.background,
                shape: const CircleBorder(),
              ),
            ),
          )
        : DecoratedBox(
            decoration: ShapeDecoration(
              color: tokens.background,
              shape: const StadiumBorder(),
            ),
            child: ConstrainedBox(
              // A width floor rather than a fixed size: a single digit stays
              // round, and `99+` grows instead of being clipped. Nothing here
              // is a touch target — a badge is not interactive, and the control
              // it sits beside is what has to meet the floor.
              constraints: BoxConstraints(minWidth: tokens.minimumExtent),
              child: Padding(
                padding: tokens.padding,
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    count,
                    style: tokens.textStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );

    // The numeral is excluded and the label read in its place, so a screen
    // reader hears "3 unread messages" once rather than "3" followed by
    // "3 unread messages".
    return IuxSemantics.group(
      label: label,
      child: IuxSemantics.decorative(child: visual),
    );
  }
}
