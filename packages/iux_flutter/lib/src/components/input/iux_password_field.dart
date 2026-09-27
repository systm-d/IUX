import 'package:flutter/material.dart';

import '../../inputs/iux_input_descriptor.dart';
import '../../inputs/iux_input_model.dart';
import '../../inputs/iux_input_theme.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../selection/iux_selection_controls.dart';
import '../selection/iux_selection_model.dart';
import 'iux_text_field.dart';

/// Why a reveal control with no name is refused.
const String _kEmptyRevealLabel =
    'The control that reveals the value must be named. It is the only way a '
    'user can check what they typed, and it is drawn as a labelled switch, so '
    'the name is what they read as well as what they hear. Pass the localised '
    'name of the thing being shown: "Show password", "Show token".';

/// What a secret is for, which decides what the platform may do with it.
///
/// Required on [IuxPasswordField], because the three are indistinguishable on
/// screen and different to a password manager — and guessing wrong is harmful
/// in both directions. A sign-in field that does not say so is a field the
/// user types a forty-character password into by hand. A token field that
/// says it is a password gets offered to be *saved* as the account's
/// password, which a user who accepts has now overwritten.
enum IuxSecretPurpose {
  /// The user's existing password, entered to sign in.
  ///
  /// Autofill may offer the password it has saved for this application.
  current,

  /// A password being chosen: signing up, or changing one.
  ///
  /// Autofill may offer to generate one and will offer to save what is typed.
  created,

  /// A token, key or code the user brings from elsewhere and pastes.
  ///
  /// A personal access token, an API key, a recovery code. Not a password:
  /// autofill neither offers a saved password nor offers to save this as one.
  /// It is still concealed, because it is still a credential on a screen.
  token,
}

/// A value that must not be shown by default, and the control that shows it.
///
/// ```dart
/// IuxPasswordField(
///   input: IuxInputDescriptor(
///     semantics: IuxInputSemantics(label: l10n.personalAccessToken),
///     requirement: IuxInputRequirement.required,
///     helpText: l10n.tokenHelp,
///     validation: state.tokenValidation,
///   ),
///   purpose: IuxSecretPurpose.token,
///   revealLabel: l10n.showToken,
///   controller: _token,
///   onChanged: controller.tokenChanged,
/// )
/// ```
///
/// **Use it** for anything that would be a problem on a screen someone else
/// can see: a password, a token, an API key, a recovery code.
///
/// **It is a component rather than a flag on `IuxTextField`**, and the reason
/// was written down before it was built. `IuxTextContent` explains that there
/// is no `password` value because "an obscured field owes the user a way to
/// reveal what they typed — otherwise a motor or dyslexic user cannot check a
/// long password before submitting it — and that reveal control is a second
/// interactive element with its own name, state and announcement." The first
/// application migrated onto IUX needed exactly this, for a GitHub token, and
/// its report reached the same conclusion on its own (systm-d/IUX#67).
///
/// ## The reveal control is a labelled switch, not an eye
///
/// **An eye icon was the obvious choice and it was refused**, for two reasons
/// this project had already written down elsewhere.
///
/// An icon on its own is a guess — `IuxNavigationDestination` refuses an
/// icon-only form in those words. The eye is a worse guess than most, because
/// the convention is split: some applications draw the open eye to mean "it is
/// hidden, tap to show", others to mean "it is shown". A user moving between
/// them learns nothing reliable from the glyph, and the one who most needs to
/// check what they typed is the one least likely to experiment.
///
/// And a control inside the box is refused by `IuxTextField` itself
/// (IUX-TEXTFIELD-GAPS-001): a target that meets the floor leaves too little of
/// a small-screen field for the text.
///
/// So the control is an `IuxSwitch` under the field, reading [revealLabel] —
/// the arrangement large sign-in forms already use. It carries its state in
/// the thumb's position and a tick, announces itself as "Show password,
/// switch, off", and is a real selection control: target floor, focus ring and
/// press feedback are the switch's, already measured, not reimplemented. It is
/// a switch and not a checkbox by `IuxSwitch`'s own rule: revealing takes
/// effect the moment it moves and is undone the same way, and there is no Save
/// button it is waiting for.
///
/// ## Behaviour
///
/// **Concealed on arrival, always.** There is no parameter that starts it
/// revealed. Whether to show a credential is the user's decision in the moment,
/// made knowing who is looking at their screen; an application deciding it in
/// advance has decided for a room it cannot see.
///
/// **The reveal state is this widget's, not the parent's.** Everything about
/// the *value* belongs to the parent, as it does for `IuxTextField`. Whether it
/// is currently drawn as bullets is not a fact about the value, any more than
/// whether the field has focus is.
///
/// **Revealing does not move focus.** Clearing a search returns focus to the
/// box, because the user is about to type again. Revealing is inspection: the
/// user wants to read, and a screen-reader user reaches the value by moving to
/// the field, which now speaks it.
///
/// **The keyboard does not change when the value is revealed.** It is the
/// visible-password keyboard throughout, so showing the value does not re-lay
/// the keyboard out under a user's fingers mid-word. Suggestions, correction,
/// capitalisation and the keyboard's own learning are off in both states:
/// each of them would put the secret somewhere other than this box.
///
/// **The switch follows the field's availability.** A disabled field has a
/// disabled switch, since there is nothing the user may do with its value. A
/// read-only field keeps an enabled one: a generated token shown once for the
/// user to copy is exactly a value someone needs to reveal and may not edit.
///
/// Everything else — the visible label, the help text, the validation message
/// and when it is announced, the focus ring, the variants — is
/// `IuxTextField`'s, unchanged.
class IuxPasswordField extends StatefulWidget {
  /// Creates a concealed field and the switch that reveals it.
  const IuxPasswordField({
    super.key,
    required this.input,
    required this.controller,
    required this.onChanged,
    required this.purpose,
    required this.revealLabel,
    this.placeholder,
    this.variant,
    this.autofocus = false,
    this.focusNode,
    this.onSubmitted,
  }) : assert(revealLabel.length > 0, _kEmptyRevealLabel);

  /// What the field is, what may be done to it, and what is known about its
  /// value. As for `IuxTextField`.
  final IuxInputDescriptor input;

  /// The live value, owned and disposed by the parent.
  final TextEditingController controller;

  /// Called on every user edit, with the new value.
  final ValueChanged<String> onChanged;

  /// What the secret is for, which decides what autofill may do with it.
  final IuxSecretPurpose purpose;

  /// The visible and announced name of the switch that reveals the value,
  /// already localised: "Show password", "Show token".
  ///
  /// It names what is shown, and it does not change with the state. The state
  /// is announced as on or off; a name that flipped between "Show" and "Hide"
  /// would have to be read again each time to know what the control does now.
  final String revealLabel;

  /// A short example of the expected shape, shown only while the field is
  /// empty. As for `IuxTextField`.
  final String? placeholder;

  /// The visual variant, or null for the theme's default. As for
  /// `IuxTextField`.
  final IuxInputVariant? variant;

  /// Whether the field takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node for the field.
  final FocusNode? focusNode;

  /// Called when the user presses the keyboard's action key.
  final ValueChanged<String>? onSubmitted;

  @override
  State<IuxPasswordField> createState() => _IuxPasswordFieldState();
}

class _IuxPasswordFieldState extends State<IuxPasswordField> {
  bool _revealed = false;

  List<String>? get _autofillHints => switch (widget.purpose) {
        IuxSecretPurpose.current => const <String>[AutofillHints.password],
        IuxSecretPurpose.created => const <String>[AutofillHints.newPassword],
        IuxSecretPurpose.token => null,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IuxTextField.secret(
          input: widget.input,
          controller: widget.controller,
          onChanged: widget.onChanged,
          secret: IuxSecretEntry(
            concealed: !_revealed,
            autofillHints: _autofillHints,
          ),
          placeholder: widget.placeholder,
          variant: widget.variant,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          onSubmitted: widget.onSubmitted,
        ),
        // Tightly related: the switch belongs to this field and to no other,
        // and the gap is the one the spacing scale gives for exactly that.
        const IuxGap.tight(),
        IuxSwitch(
          label: widget.revealLabel,
          input: IuxInputDescriptor(
            semantics: IuxInputSemantics(label: widget.revealLabel),
            availability:
                widget.input.availability == IuxInputAvailability.disabled
                    ? IuxInputAvailability.disabled
                    : IuxInputAvailability.enabled,
          ),
          value: IuxSelectionState.fromSelected(_revealed),
          onChanged: (bool revealed) => setState(() => _revealed = revealed),
        ),
      ],
    );
  }
}
