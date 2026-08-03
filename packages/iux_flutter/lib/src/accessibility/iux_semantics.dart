import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'iux_accessibility.dart';

/// Builds consistent `Semantics` configurations.
///
/// Components call these rather than composing `Semantics` by hand. Hand-built
/// semantics drift: one component sets `button: true` and forgets `enabled`,
/// another labels an icon and forgets to exclude the icon's own semantics, and
/// the reading order stops being predictable across the library.
abstract final class IuxSemantics {
  /// Wraps [child] as an activatable control.
  ///
  /// Leave [selected] null unless the control genuinely toggles: passing false
  /// advertises a selected *state* to assistive technology, so a plain button
  /// gets announced as "not selected", which invites the user to look for a
  /// selection that does not exist.
  ///
  /// [busyHint] is appended when the action is running. Supply it already
  /// localised, or leave it null: the framework will not invent one.
  static Widget action({
    required Widget child,
    required String label,
    String? hint,
    bool enabled = true,
    bool? selected,
    String? busyHint,
  }) =>
      Semantics(
        container: true,
        button: true,
        enabled: enabled,
        selected: selected,
        label: label,
        // A running action is announced through the hint, because a screen
        // reader gives no standard indication for it and silence is
        // indistinguishable from a control that simply did nothing.
        //
        // The wording is the caller's. An earlier version composed the
        // English literal 'In progress' here, which every non-English
        // application would have shipped untranslated — the framework holds
        // roles, never user-facing text.
        hint: busyHint == null || busyHint.isEmpty
            ? hint
            : _joinHint(hint, busyHint),
        excludeSemantics: true,
        child: child,
      );

  /// Wraps [child] as a section heading, so a screen reader can jump to it.
  static Widget header({required Widget child, required String label}) =>
      Semantics(
        container: true,
        header: true,
        label: label,
        excludeSemantics: true,
        child: child,
      );

  /// Wraps [child] as an image with a description.
  ///
  /// Pass an empty [label] for decoration, which hides it from screen readers
  /// instead of making them read a filename.
  static Widget image({required Widget child, required String label}) =>
      label.isEmpty
          ? ExcludeSemantics(child: child)
          : Semantics(
              container: true,
              image: true,
              label: label,
              excludeSemantics: true,
              child: child,
            );

  /// Wraps [child] as a region announced when its content changes.
  ///
  /// Use for a status that appears in place — a validation message, a result
  /// count. Do not use for content the user is reading, which would interrupt
  /// them repeatedly.
  static Widget liveRegion({required Widget child, String? label}) => Semantics(
        container: true,
        liveRegion: true,
        label: label,
        child: child,
      );

  /// Groups [children] so they are read as one unit.
  ///
  /// Without this, a row of label and value is announced as two unrelated
  /// fragments, and the relationship between them is lost.
  static Widget group({required Widget child, String? label}) => Semantics(
        container: true,
        label: label,
        child: child,
      );

  /// Hides [child] from assistive technology.
  ///
  /// Only for content that is genuinely redundant — an icon beside a label
  /// that already says the same thing. Hiding anything else removes it from
  /// the interface for part of the users.
  static Widget decorative({required Widget child}) =>
      ExcludeSemantics(child: child);

  /// Marks [child] as unavailable, so the state is announced and not only
  /// rendered.
  static Widget disabled({required Widget child, required String label}) =>
      Semantics(
        container: true,
        enabled: false,
        label: label,
        excludeSemantics: true,
        child: child,
      );

  static String? _joinHint(String? hint, String addition) =>
      hint == null || hint.isEmpty ? addition : '$hint. $addition';
}

/// Speaks a message that has no visual anchor.
///
/// **Prefer [IuxSemantics.liveRegion] to this, on Android especially.**
///
/// Android has deprecated `announceForAccessibility` because it forces
/// TalkBack to clear its speech queue and speak the given text, cutting off
/// whatever the user was listening to. An announcement is therefore an
/// interruption in the literal sense, and IUX treats it as a last resort
/// rather than the normal way to tell a screen-reader user something.
///
/// Use this only when a change has no on-screen representation at all — a
/// background save completing, a list refreshing in place with no visible
/// status. When the message does appear on screen, mark that region live and
/// let the platform announce it: the user then hears it once, in context, and
/// can re-read it.
///
/// Every method reports whether the announcement was actually delivered.
/// Announcements are unsupported on some platforms, so a false return is
/// normal — which is exactly why essential information must never depend on
/// one.
abstract final class IuxAnnouncement {
  /// Announces [message] after whatever is currently being read.
  ///
  /// Returns false when the platform does not support announcements.
  static Future<bool> polite(BuildContext context, String message) =>
      _announce(context, message, Assertiveness.polite);

  /// Announces [message] immediately, interrupting whatever is being spoken.
  ///
  /// Reserve this for something the user must know now — a failure that lost
  /// their input, a session about to expire. On Android this cuts off TalkBack
  /// mid-sentence, so interrupting for anything less trains users to turn
  /// announcements off.
  static Future<bool> assertive(BuildContext context, String message) =>
      _announce(context, message, Assertiveness.assertive);

  /// Whether announcements reach the user at [context].
  ///
  /// Use it to choose a strategy, never to decide whether to show something:
  /// a visible message is required either way.
  static bool isSupported(BuildContext context) =>
      MediaQuery.supportsAnnounceOf(context);

  static Future<bool> _announce(
    BuildContext context,
    String message,
    Assertiveness assertiveness,
  ) async {
    if (message.isEmpty) return false;
    if (!MediaQuery.supportsAnnounceOf(context)) return false;
    await SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
      assertiveness: assertiveness,
    );
    return true;
  }
}

/// Helpers for text that must stay readable when the user enlarges it.
abstract final class IuxReadableText {
  /// The line limit to apply, given the text scaling in force.
  ///
  /// Returns null — meaning unlimited — once text is enlarged enough that a
  /// fixed limit would clip it. Truncating enlarged text defeats the reason
  /// the user enlarged it.
  static int? maxLines(BuildContext context, int preferred) =>
      IuxAccessibility.of(context).prefersStackedLayout ? null : preferred;

  /// Whether a label-and-value row should stack vertically here.
  static bool shouldStack(BuildContext context) =>
      IuxAccessibility.of(context).prefersStackedLayout;

  /// The overflow behaviour to apply.
  ///
  /// Never [TextOverflow.ellipsis] for enlarged text: an ellipsis hides the
  /// content the user asked to see more of.
  static TextOverflow overflow(BuildContext context) =>
      IuxAccessibility.of(context).prefersStackedLayout
          ? TextOverflow.visible
          : TextOverflow.ellipsis;
}
