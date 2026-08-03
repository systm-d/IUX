import 'package:flutter/widgets.dart';

import '../../accessibility/iux_accessibility.dart';
import 'iux_transient_message.dart';

/// How long a transient message stays, and when it must not leave at all.
///
/// **Why this is not `IuxMotionPolicy`.** The motion policy answers "may I
/// animate this, and for how long". This answers "how long must a sentence
/// remain legible to somebody who was looking somewhere else". They are not the
/// same question, and tying reading time to an animation curve would mean a
/// user who asked for less motion also got less time to read — the opposite of
/// an accommodation. Every animation in this component still goes through
/// `IuxMotionPolicy`; only the dwell does not.
///
/// ## WCAG 2.2 SC 2.2.1, and how it is honoured
///
/// The criterion requires that a time limit set by the content can be turned
/// off, adjusted, or extended. A fixed four-second dismissal offers none of
/// the three, which is why no number in this class is fixed and why the class
/// is mostly about the cases where there is no timer at all.
///
/// Four mechanisms, in the order they matter:
///
/// 1. **Nothing that matters is under a timer.** `IuxTransientTone` has no
///    `error` and no `warning`, so a failure cannot be placed in this channel
///    in the first place. This is the mechanism the other three rest on: a
///    time limit on content nobody needs is not a time limit on a task.
/// 2. **An action removes the timer entirely.** [resolve] returns null the
///    moment [IuxTransientMessage.action] is set. If there is something to do,
///    there is no deadline for doing it.
/// 3. **An expected screen reader removes the timer entirely.** A live region
///    is queued behind whatever the platform is already speaking, so a clock
///    started when the message is painted measures nothing for that user; and
///    a screen-reader user reaches content by navigating to it, which cannot be
///    done to content that has already gone.
/// 4. **The user stops and restarts the clock by touching or focusing the
///    message**, and removes it early with the dismiss control. Those are the
///    "pause" and "hide" mechanisms of SC 2.2.2, implemented in
///    `IuxTransientLayer`.
///
/// What is *not* offered is a user-facing "extend by ten times" control: IUX
/// has no settings surface and will not invent one. An application that has
/// one can raise the floor through `IuxTransientLayer.minimumDwell`, which only
/// ever lengthens.
abstract final class IuxTransientTiming {
  /// The shortest a message ever stays, however short its text.
  ///
  /// A short message is not a message that can be read quickly: the cost is
  /// noticing that something appeared at the edge of a screen the user was not
  /// looking at, moving their eyes there, and only then reading two words.
  /// Material's own defaults are shorter than this in both of their lengths;
  /// IUX is deliberately slower, because the cost of a message staying two
  /// seconds too long is irritation and the cost of it leaving two seconds too
  /// early is that it was never read.
  static const Duration minimum = Duration(seconds: 4);

  /// The reading rate used to derive a dwell, in characters per second.
  ///
  /// Roughly 120 words per minute for Latin text, about half the average adult
  /// silent reading rate. That is not a mistake: the average is measured on
  /// someone reading deliberately, and this component's reader is doing
  /// something else at the time.
  static const double charactersPerSecond = 10;

  /// How long [text] is given to be read, never less than [minimum].
  ///
  /// Pure, so the rule can be tested without a widget tree.
  ///
  /// There is no ceiling. A ceiling is a truncation of somebody's reading time,
  /// and the honest response to a message whose derived dwell looks absurd is
  /// that the message is too long to be transient at all.
  static Duration readingTime(String text) {
    // Runes rather than code units, so an emoji or an accented character is
    // one character and not two.
    final double seconds = text.runes.length / charactersPerSecond;
    final Duration read = Duration(
      microseconds: (seconds * Duration.microsecondsPerSecond).round(),
    );
    return read < minimum ? minimum : read;
  }

  /// How long [message] stays at [context], or null when it must not expire.
  ///
  /// Null is not an error and not a default: it is the answer for every
  /// message carrying an action, and for every message shown while a screen
  /// reader is expected. The parent removes those when the state they describe
  /// changes, or the user dismisses them.
  ///
  /// [minimumDwell] raises the floor and never lowers it, exactly as
  /// `IuxTapTarget.minimumSize` raises the target floor. There is no parameter
  /// anywhere in this component that can shorten a dwell, because the only
  /// reason to want one is to fit more messages into the same second.
  static Duration? resolve(
    BuildContext context,
    IuxTransientMessage message, {
    Duration? minimumDwell,
  }) {
    if (message.action != null) return null;

    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    if (accessibility.screenReaderExpected) return null;

    final Duration derived = readingTime(message.text);
    if (minimumDwell == null || minimumDwell <= derived) return derived;
    return minimumDwell;
  }
}
