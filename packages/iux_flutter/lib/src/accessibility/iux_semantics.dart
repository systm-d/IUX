// SemanticsInputType is declared in `dart:ui` and is not re-exported by
// `package:flutter/semantics.dart`, so this is the only way to name it. It is
// what tells a screen reader that a box holds an email address rather than
// prose, which changes how the platform speaks the value back.
import 'dart:ui' show SemanticsInputType;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'iux_accessibility.dart';

/// Which selection control a node is, which decides how its state is spoken.
///
/// Android reads the three differently: "checked" for a box, "on" for a
/// switch, and one option of a set for a radio. Announcing a switch as a
/// checkbox tells the user a Save button is coming that does not exist, and
/// announcing a radio as a checkbox tells them they may choose several.
///
/// This is the *role* half of "name, role, value". A component decides which
/// control it is; this is how that decision reaches the platform.
enum IuxSelectionRole {
  /// An independent yes/no, announced as checked or unchecked.
  ///
  /// The only role that may carry [IuxSelectionValue.partial].
  checkbox,

  /// A setting that applies the moment it moves, announced as on or off.
  toggle,

  /// One option of a set of which exactly one applies.
  ///
  /// Announced as belonging to a mutually exclusive group, so the platform can
  /// say "1 of 3" rather than leaving the user to count.
  radio,
}

/// What a selection control is currently set to, as it is announced.
///
/// The *value* half of "name, role, value", and the accessibility runtime's
/// own vocabulary rather than any component's. The runtime sits below the
/// components and must not know that a checkbox widget exists, so a component
/// translates whatever it holds into this on the way in.
enum IuxSelectionValue {
  /// Not chosen. The resting state.
  unselected,

  /// Chosen.
  selected,

  /// Standing for a set of which some, but not all, members are chosen.
  ///
  /// Legal only on [IuxSelectionRole.checkbox]. A switch has two physical
  /// positions and a radio is one option among several, so neither has
  /// anywhere to put this — and a state the user can perceive but cannot
  /// predict the effect of is worse than no state at all.
  partial,
}

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
  ///
  /// Pass [onTap] whenever the wrapped subtree is activatable. It is what a
  /// screen reader's double-tap invokes; a gesture detector inside the child
  /// cannot supply it, because this helper excludes the child's semantics in
  /// order to control the announced name.
  static Widget action({
    required Widget child,
    required String label,
    String? hint,
    bool enabled = true,
    bool? selected,
    String? busyHint,
    VoidCallback? onTap,
  }) =>
      Semantics(
        container: true,
        button: true,
        enabled: enabled,
        selected: selected,
        label: label,
        // Carried here because [excludeSemantics] removes the child's own tap
        // action along with its label. Without it the node announces a button
        // and offers nothing to activate, so a screen-reader double-tap does
        // nothing at all — the control is visible, named, and unusable.
        onTap: enabled ? onTap : null,
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

  /// Wraps [child] as one control whose content is part of its announcement.
  ///
  /// [action] excludes the subtree, which is right for a button whose visible
  /// content only repeats the name it was given. It is wrong for a block whose
  /// content *is* the information — a card standing for an order — where
  /// dropping the subtree deletes the reference, the status and the amount
  /// from the interface of every screen-reader user, silently, while the
  /// control goes on looking correct.
  ///
  /// So this keeps the content and merges it into one stop: the user hears the
  /// name, then the role, then everything a sighted user takes in at a glance,
  /// and lands on one control rather than on each of its lines.
  ///
  /// One stop means one thing to activate, so nothing inside may be a control
  /// of its own. Merged in, a nested button loses the node the user would have
  /// landed on: it is announced and cannot be reached. A block that contains
  /// controls is [contentContainer], not this.
  ///
  /// [onTap] is required and is what a screen reader's double-tap invokes.
  /// A merged subtree usually carries its own tap action, but "usually" is how
  /// a control ends up announced and inert.
  static Widget contentAction({
    required Widget child,
    required String label,
    required VoidCallback onTap,
    String? hint,
    bool enabled = true,
  }) {
    assert(
      label.length > 0,
      'A control must be named. Without a name this is announced as "button" '
      'followed by its content, which tells the user that something will '
      'happen and refuses to say what.',
    );
    return MergeSemantics(
      child: Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: label,
        hint: hint,
        onTap: enabled ? onTap : null,
        child: child,
      ),
    );
  }

  /// Wraps [child] as a selection control, announced by [role] and [value].
  ///
  /// One helper for all three roles, on purpose. A checkbox, a switch and a
  /// radio must not be able to drift apart on what a disabled one announces or
  /// on whether its state is spoken at all; what genuinely differs is which
  /// property carries the state, and that is decided here rather than at three
  /// call sites that will eventually disagree.
  ///
  /// The subtree is excluded. A selection control's label, its help text and
  /// its tap target all repeat what this node already says, and left in they
  /// would be announced again as unlabelled fragments. That exclusion is also
  /// why [onTap] exists: with the subtree gone, it is the only tap action
  /// left, and without it the control is announced correctly and refuses to
  /// respond to a screen reader's double-tap.
  ///
  /// [onTap] is nullable, and null is an answer rather than an oversight here.
  /// A control that cannot be edited has nothing to activate, and neither has
  /// the already-chosen option of a radio group, which cannot be unchosen.
  /// Offering an action that changes nothing is worse than offering none.
  ///
  /// [readOnly] is not the opposite of [enabled]: a read-only control keeps
  /// its place in the focus order and still announces its value, a disabled
  /// one leaves the order entirely.
  static Widget selection({
    required Widget child,
    required IuxSelectionRole role,
    required IuxSelectionValue value,
    required String label,
    String? hint,
    bool enabled = true,
    bool readOnly = false,
    bool isRequired = false,
    VoidCallback? onTap,
  }) {
    assert(
      label.length > 0,
      'A selection control must be named. An unnamed one is announced as '
      '"checkbox" and nothing else, so the user is asked a question they '
      'cannot hear.',
    );
    assert(
      value != IuxSelectionValue.partial || role == IuxSelectionRole.checkbox,
      'Only a checkbox can be partly chosen. A switch has two physical '
      'positions and a radio is one option among several, so announcing a '
      'mixed state on either describes a control that cannot exist.',
    );

    final bool selected = value == IuxSelectionValue.selected;
    return Semantics(
      container: true,
      enabled: enabled,
      // Only ever set, never cleared: `readOnly: false` would announce a state
      // this control does not have.
      readOnly: readOnly ? true : null,
      label: label,
      hint: hint,
      isRequired: isRequired ? true : null,
      // A checkbox and a radio are "checked"; a switch is "toggled".
      checked: role == IuxSelectionRole.toggle ? null : selected,
      mixed: role == IuxSelectionRole.checkbox
          ? value == IuxSelectionValue.partial
          : null,
      toggled: role == IuxSelectionRole.toggle ? selected : null,
      inMutuallyExclusiveGroup: role == IuxSelectionRole.radio ? true : null,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: child,
    );
  }

  /// Wraps [child] as a set of options of which exactly one applies.
  ///
  /// The container half of [IuxSelectionRole.radio]. Each option announces
  /// that it belongs to a mutually exclusive set; this says where that set
  /// starts and stops, which is what lets the platform count "1 of 3" instead
  /// of leaving the user to, and what gives the options a question to be heard
  /// as answers to.
  ///
  /// The options keep their own nodes. They are separate controls, and each
  /// one has to stay somewhere the user can land.
  static Widget radioGroup({required Widget child, required String label}) {
    assert(
      label.length > 0,
      'A mutually exclusive set must be named. Unnamed, it is a list of words '
      'with no question attached, and a screen reader reads it that way.',
    );
    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      label: label,
      child: child,
    );
  }

  /// Wraps [child] as an editable value, keeping the actions that edit it.
  ///
  /// [child] is the editing widget itself, and its semantics are merged into
  /// this node rather than excluded. That is the whole reason this helper
  /// exists separately from [action]: excluding the subtree would take the
  /// set-text, set-selection and move-cursor actions away with it, leaving a
  /// field that a screen reader can find, can announce, and cannot type into.
  ///
  /// Merging is also what attaches the name. Left as two nodes, the name and
  /// the box are separate stops, and the one the user lands on to type is the
  /// one with no name — the field still works, it is simply announced as "edit
  /// box".
  ///
  /// [readOnly] is not the opposite of [enabled]. A read-only field stays in
  /// the focus order and still announces its value; a disabled one leaves the
  /// order entirely, and a value nobody can reach is a value they do not have.
  /// Set at most one of them.
  ///
  /// [isRequired] and [validation] are announced as properties, which the
  /// platform speaks in the user's own language. An asterisk or the word
  /// "required" composed into [label] would be the framework's language rather
  /// than theirs.
  ///
  /// [inputType] says what kind of value the box holds, so the platform can
  /// read an address back character by character instead of as a word.
  static Widget field({
    required Widget child,
    required String label,
    String? hint,
    bool enabled = true,
    bool readOnly = false,
    bool isRequired = false,
    SemanticsValidationResult validation = SemanticsValidationResult.none,
    SemanticsInputType inputType = SemanticsInputType.text,
  }) {
    assert(
      label.length > 0,
      'A field must be named. An unnamed box is announced as "edit box" and '
      'nothing else, so a screen-reader user is asked for a value without '
      'being told which one.',
    );
    return MergeSemantics(
      child: Semantics(
        textField: true,
        label: label,
        hint: hint,
        enabled: enabled,
        // Only ever set, never cleared. Passing false here would announce a
        // state the field does not have, and would overwrite a read-only flag
        // the editing widget below had set for itself.
        readOnly: readOnly ? true : null,
        isRequired: isRequired ? true : null,
        validationResult: validation,
        inputType: inputType,
        child: child,
      ),
    );
  }

  /// Wraps [child] as a layer that has taken over the screen, named by [label].
  ///
  /// A dialog, a sheet, anything the user cannot see past until they deal with
  /// it. Assistive technology is told that the context changed and what it
  /// changed to. Without that, a screen-reader user hears focus move and is
  /// left to work out for themselves what they are now inside.
  ///
  /// The subtree keeps its own nodes, and that is not optional: the layer's
  /// controls have to stay individually reachable, so this helper never
  /// excludes them and never merges them into the route. [label] is announced
  /// on arrival; it does not replace the content.
  ///
  /// This describes the layer. It does not blank the page behind it and does
  /// not trap keyboard focus, because only the caller knows what "behind" is.
  /// A layer that announces itself while the page underneath stays swipeable
  /// is still broken — see `docs/accessibility/semantics.md`.
  static Widget route({required Widget child, required String label}) {
    assert(
      label.length > 0,
      'A route must be named. Scoping a route without naming it announces '
      'that something took over the screen and refuses to say what, which '
      'leaves a screen-reader user interrupted with nothing to act on.',
    );
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      // The layer's own controls keep their nodes. Without this, a control
      // that does not declare itself a semantic container has its name
      // absorbed into the route node, and the layer becomes one long sentence
      // with nothing inside it the user can land on.
      explicitChildNodes: true,
      label: label,
      child: child,
    );
  }

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

  /// Wraps [child] as one object whose parts stay individually reachable.
  ///
  /// A card, a bordered block of rows: something a sighted user reads as one
  /// object and a screen-reader user has to be able to move around inside.
  ///
  /// What separates it from [group] is what becomes of the children. [group]
  /// collapses a label and its value into one utterance, which is what makes
  /// the pair mean anything. This does the opposite, and deliberately: every
  /// child keeps its own node. Without that, a control that does not declare
  /// itself a semantic container has its name and its role absorbed into this
  /// one, and the block is announced as a single button called "Order 3141,
  /// Track" — which is both wrong and unreachable, because the control it came
  /// from no longer exists as somewhere the user can land.
  ///
  /// It announces no role, because it is not a control. When the whole block
  /// is activatable, that is [contentAction].
  static Widget contentContainer({required Widget child}) => Semantics(
        container: true,
        explicitChildNodes: true,
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
