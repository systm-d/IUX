import 'package:flutter/widgets.dart';

import '../../accessibility/iux_focus.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../components/button/iux_button.dart';
import '../../layout/iux_spacing_primitives.dart';
import 'iux_form_model.dart';
import 'iux_form_section.dart';
import 'iux_validation_summary.dart';

/// Produces the sentence that opens an error summary, given how many fields are
/// rejected.
///
/// A function rather than a string, and for one reason: the number in the
/// sentence and the number of entries below it must be the same number. A
/// caller passing a fixed string has to count the failures itself, in parallel
/// with the form, and the two counts drift the first time a rule changes —
/// leaving "2 fields need your attention" above a list of three.
///
/// The count is offered, not imposed. Returning a constant — GOV.UK's "There is
/// a problem" is the best-known example — is a perfectly good answer, and a
/// better one in a language where the plural forms would make the sentence
/// awkward.
typedef IuxErrorCountDescription = String Function(int invalidFieldCount);

/// The strings an error summary needs, which IUX cannot supply.
///
/// Grouped into one object so a form cannot be given half of them, and so
/// passing null for the whole object is the single, visible way of saying "this
/// form has no summary".
@immutable
final class IuxValidationSummaryLabels {
  /// Creates the text an error summary is built from.
  const IuxValidationSummaryLabels({
    required this.categoryLabel,
    required this.describeCount,
    this.navigationHint,
  })  : assert(
          categoryLabel.length > 0,
          'categoryLabel is the only thing that tells a screen-reader user the '
          'summary is an error rather than a note. Pass the localised word.',
        ),
        assert(
          navigationHint == null || navigationHint.length > 0,
          'Pass null rather than an empty hint.',
        );

  /// The localised word for the category — "Error", "Erreur".
  final String categoryLabel;

  /// The opening sentence, given the number of rejected fields.
  final IuxErrorCountDescription describeCount;

  /// What a screen reader says after each entry, already localised.
  ///
  /// Something like "Go to this field". Optional; see
  /// [IuxValidationSummary.navigationHint].
  final String? navigationHint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxValidationSummaryLabels &&
          other.categoryLabel == categoryLabel &&
          other.describeCount == describeCount &&
          other.navigationHint == navigationHint;

  @override
  int get hashCode => Object.hash(categoryLabel, describeCount, navigationHint);
}

/// The action that commits a form.
///
/// ```dart
/// IuxFormSubmit(
///   label: l10n.createAccount,
///   action: const IuxActionDescriptor.primary(
///     semantics: IuxActionSemantics(label: 'Create account'),
///   ),
///   onSubmit: controller.createAccount,
/// )
/// ```
///
/// **Leave it enabled while the form is incomplete.** This is the single most
/// common mistake a form makes, and it is worth stating as a rule: a submit
/// button that greys itself out until every field is valid gives the user a
/// control that does nothing, tells them nothing about what is missing, and —
/// because a disabled control leaves the focus order on Android — is not even
/// reachable by a screen-reader user who wants to find out. They are left
/// pressing a button that is not there. An enabled button that refuses and
/// explains is strictly better: the refusal is the moment the user learns what
/// is wrong.
///
/// Disable it only for a reason that is not about the fields — a plan that does
/// not allow this, a session that has expired — and then say so. The
/// constructor enforces that: a disabled submit must carry
/// [IuxActionSemantics.unavailabilityReason], because the alternative is the
/// greyed control with no explanation that this rule exists to prevent.
@immutable
final class IuxFormSubmit {
  /// Creates the submit action of a form.
  ///
  /// The constructor is not `const`, deliberately: the assertion below reads a
  /// field of [action], and Dart cannot evaluate a field access on a constant
  /// object inside a `const` constructor's assertion. Failing at construction
  /// is worth more here than the constness of an object that already holds a
  /// closure.
  IuxFormSubmit({
    required this.label,
    required this.action,
    required this.onSubmit,
    this.busyHint,
    this.onBlocked,
  })  : assert(
          label.length > 0,
          'A submit control must show something. An empty label leaves a '
          'container a sighted user can see and cannot identify.',
        ),
        assert(
          action.availability != IuxActionAvailability.disabled ||
              action.semantics.unavailabilityReason != null,
          'A disabled submit must say why it is disabled. A greyed control '
          'with no explanation leaves the user unable to tell whether they '
          'did something wrong, whether the feature does not apply to them, '
          'or whether the application is broken — and it has left the focus '
          'order, so a screen-reader user cannot even find it to wonder. Set '
          'IuxActionSemantics.unavailabilityReason, or keep the action '
          'enabled and let the refusal explain itself.',
        ),
        assert(
          busyHint == null || busyHint.length > 0,
          'Pass null rather than an empty busy hint.',
        );

  /// The visible text of the control, already localised.
  ///
  /// Name the outcome — "Create account", "Send the request" — rather than the
  /// mechanism. "Submit" tells the user that something will happen and refuses
  /// to say what.
  final String label;

  /// What the action is, whether it may run, and where it is in its lifecycle.
  ///
  /// The parent owns [IuxActionDescriptor.operation]. A form that set it itself
  /// would be deciding that a submission had succeeded, which only the caller
  /// can know.
  final IuxActionDescriptor action;

  /// Called when the user asks to submit and nothing is currently rejected.
  ///
  /// Every field has been asked for a check by the time this runs, but the
  /// answers may not have arrived: a check the parent runs asynchronously is
  /// still in flight, and this form does not wait for it. Whether the values
  /// are acceptable is the parent's decision, taken here.
  final VoidCallback onSubmit;

  /// Called instead of [onSubmit] when the form refuses the attempt.
  ///
  /// The refusal is already visible and already announced — the summary appears
  /// and takes focus. This exists so the parent can add what only the parent
  /// may add: a feedback event, a log line, a metric. It must not be used to
  /// show a second message about the same refusal.
  final VoidCallback? onBlocked;

  /// Announced after the label while the submission is running.
  ///
  /// Already localised. Leave it null and a screen reader hears nothing extra,
  /// and silence is indistinguishable from a control that did nothing — so
  /// supply it for anything that takes a network round trip.
  final String? busyHint;
}

/// A form: fields grouped into sections, a summary of what is refusing them,
/// and one action that commits the lot.
///
/// ```dart
/// IuxForm(
///   sections: <IuxFormSection>[
///     IuxFormSection(title: l10n.yourDetails, fields: <IuxFormField>[…]),
///   ],
///   summary: IuxValidationSummaryLabels(
///     categoryLabel: l10n.error,
///     describeCount: l10n.fieldsNeedAttention,
///   ),
///   submit: IuxFormSubmit(
///     label: l10n.createAccount,
///     action: state.submitAction,
///     onSubmit: controller.createAccount,
///   ),
/// )
/// ```
///
/// **Use it** wherever the user answers several questions and then commits
/// them: a sign-up, an address, a settings page with a Save button.
///
/// **Do not use it** for a single field with a single action — a search box is
/// a field and a button, and wrapping it in a form buys nothing but a summary
/// that will never have two entries. Do not use it for settings that apply
/// immediately either: a switch that takes effect on contact has nothing to
/// submit, and a Save button beside it is a lie about which of the two did the
/// work. And do not use it for a multi-step flow: a wizard has its own
/// questions about progress, going back and losing work, which this pattern
/// does not answer.
///
/// **The parent owns everything.** The values live in the parent's controllers,
/// the decision about whether a value is acceptable lives in the parent, and
/// whether the submission succeeded lives in the parent. This widget decides
/// exactly three things, none of which the parent could decide for itself: when
/// a check is worth asking for, what the summary lists, and where focus goes
/// when a submission is refused.
///
/// ## What happens when a submission is refused
///
/// The user presses the submit control. If a field is already rejected, nothing
/// is sent. Otherwise every field is asked for a check and [IuxFormSubmit
/// .onSubmit] runs; if the parent then rejects a field, the form is in the same
/// state as if it had known.
///
/// In both cases three things happen, and they are the answer to "refused, why,
/// and where":
///
/// - the summary appears at the top of the form, saying how many fields are
///   refusing it — that it was refused;
/// - each entry names a field and repeats its message — why;
/// - each entry is a control that focuses and scrolls to that field — where.
///
/// And focus moves to the summary. Not to the first rejected field: the summary
/// says how many problems there are and the first field says only itself, so a
/// user sent straight into field one of five learns about the other four one
/// submission at a time. It is also the same destination every time, which the
/// first-field rule is not — that one lands somewhere different depending on
/// which questions were answered badly. Where no summary is configured, focus
/// falls back to the first rejected field, because being moved somewhere useful
/// beats being left where the failure is invisible.
///
/// ## Accessibility
///
/// Everything above is what a screen-reader user gets, and it is the same thing
/// a sighted user gets. Focus arriving at the summary is what announces the
/// refusal; the entries are controls, so moving by control walks the list of
/// problems; each field keeps its own message under itself, announced by the
/// field, so the information is never only in the summary.
///
/// The form animates nothing. The summary appearing is not a change the user
/// needs help following — focus has just been moved onto it — and an animation
/// there would delay the announcement to save nothing.
///
/// ## Known limitations
///
/// The submit control is rendered inline, at the end. A form whose action lives
/// in a fixed bottom bar has to place that control itself and call the same
/// handler; there is no slot for it here, because the two layouts have
/// different scrolling and keyboard-avoidance problems and one parameter cannot
/// answer both.
///
/// If the parent rejects a field long after the submission was sent, focus
/// moves to the summary at that moment — which is right if the user was
/// waiting, and an interruption if they had gone back to reading the form.
class IuxForm extends StatefulWidget {
  /// Creates a form.
  const IuxForm({
    super.key,
    required this.sections,
    required this.submit,
    this.summary,
    this.timing = IuxValidationTiming.onBlur,
  }) : assert(
          sections.length > 0,
          'A form with no sections is a submit button. Render the button on '
          'its own instead, so nothing promises the user a form that is not '
          'there.',
        );

  /// The groups of questions, in the order they are asked.
  final List<IuxFormSection> sections;

  /// The action that commits the form.
  final IuxFormSubmit submit;

  /// The text an error summary needs, or null for a form without one.
  ///
  /// Null is defensible for a form of one or two fields, where each message is
  /// already beside the field it concerns and a summary would only add a stop
  /// between the user and their answer. It is not defensible for a long form:
  /// without a summary, a refusal is a screen that looks unchanged and a field
  /// somewhere below the fold that has turned red.
  final IuxValidationSummaryLabels? summary;

  /// When the form asks the parent to check a field.
  ///
  /// See [IuxValidationTiming]. The default checks an edited field when the
  /// user leaves it, which is the answer that neither interrupts a user
  /// mid-word nor saves every failure up for the end.
  final IuxValidationTiming timing;

  @override
  State<IuxForm> createState() => _IuxFormState();
}

class _IuxFormState extends State<IuxForm> {
  /// The node focus moves to when a submission is refused.
  final FocusNode _summaryNode = FocusNode(debugLabel: 'IuxForm summary');

  /// The blur listeners currently attached, by the node they are attached to.
  final Map<FocusNode, VoidCallback> _listeners = <FocusNode, VoidCallback>{};

  /// Whether each watched node had focus last time we looked.
  ///
  /// A `FocusNode` listener fires for changes other than focus — attaching a
  /// child, a descendant gaining focus — so "did it just lose focus" has to be
  /// worked out rather than assumed.
  final Map<FocusNode, bool> _hadFocus = <FocusNode, bool>{};

  /// How many times the user has asked to submit.
  int _attempt = 0;

  /// The attempt for which focus has already been moved to a failure.
  ///
  /// Compared against [_attempt] rather than being a flag, so a second refused
  /// submission moves focus again and a rebuild for any other reason does not.
  int _focusedAttempt = 0;

  @override
  void initState() {
    super.initState();
    _syncListeners();
  }

  @override
  void didUpdateWidget(IuxForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncListeners();
    // The parent has rebuilt, possibly with the rejections that answer a
    // submission already sent. If that submission is still waiting for its
    // failure to be shown, this is it.
    if (_attempt != _focusedAttempt) _moveFocusToFailure();
  }

  @override
  void dispose() {
    for (final MapEntry<FocusNode, VoidCallback> entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _listeners.clear();
    _summaryNode.dispose();
    super.dispose();
  }

  /// Every field of every section, in the order they are asked.
  List<IuxFormField> get _fields => <IuxFormField>[
        for (final IuxFormSection section in widget.sections) ...section.fields,
      ];

  /// The fields the parent has rejected, in the order they are asked.
  List<IuxFormField> get _invalidFields =>
      _fields.where((IuxFormField field) => field.isInvalid).toList();

  /// Attaches a blur listener to every field node, and drops the ones that
  /// left.
  ///
  /// The nodes belong to the parent, so this never disposes one — it only stops
  /// listening. A pattern that disposed a node it was handed would take a field
  /// down with it the next time the parent rebuilt.
  void _syncListeners() {
    final Set<FocusNode> current = <FocusNode>{
      for (final IuxFormField field in _fields) field.focusNode,
    };

    for (final FocusNode node in _listeners.keys.toList()) {
      if (current.contains(node)) continue;
      node.removeListener(_listeners.remove(node)!);
      _hadFocus.remove(node);
    }

    for (final FocusNode node in current) {
      if (_listeners.containsKey(node)) continue;
      void listener() => _handleFocusChange(node);
      _listeners[node] = listener;
      _hadFocus[node] = node.hasFocus;
      node.addListener(listener);
    }
  }

  /// Asks for a check when the user leaves a field they have edited.
  void _handleFocusChange(FocusNode node) {
    final bool had = _hadFocus[node] ?? false;
    final bool has = node.hasFocus;
    if (had == has) return;
    _hadFocus[node] = has;

    // Only the departure matters. Checking a field the user has just arrived in
    // would reject a value before they have had the chance to change it.
    if (has) return;
    if (widget.timing != IuxValidationTiming.onBlur) return;

    for (final IuxFormField field in _fields) {
      if (field.focusNode != node) continue;
      // A field the user only passed through has nothing to check. The error it
      // would produce is about a value they were never given the chance to get
      // wrong.
      if (!field.edited) return;
      field.onValidationRequested?.call(IuxValidationTrigger.blur);
      return;
    }
  }

  /// Handles an activation of the submit control.
  ///
  /// The control itself has already refused an unavailable or busy action —
  /// `IuxButton` evaluates `IuxActionPolicy` before calling this — so anything
  /// arriving here is a genuine request to commit.
  void _handleSubmit() {
    setState(() => _attempt++);

    // Already rejected, and the form knows it. Sending the parent a submission
    // it would have to refuse a second time helps nobody, and a form that asked
    // for a value it can see is wrong is a form the user cannot trust.
    if (_invalidFields.isNotEmpty) {
      widget.submit.onBlocked?.call();
      _moveFocusToFailure();
      return;
    }

    // Nothing is known to be wrong, which is not the same as everything being
    // right: a field may never have been checked at all. Ask for all of them,
    // then hand the decision to the parent.
    for (final IuxFormField field in _fields) {
      field.onValidationRequested?.call(IuxValidationTrigger.submit);
    }
    widget.submit.onSubmit();
  }

  /// Moves focus to the summary, or to the first rejected field when there is
  /// none.
  ///
  /// Scheduled for after the frame, because the summary this focuses does not
  /// exist until the build that follows the refusal.
  void _moveFocusToFailure() {
    final List<IuxFormField> invalid = _invalidFields;
    if (invalid.isEmpty) return;

    _focusedAttempt = _attempt;
    final bool hasSummary = widget.summary != null;
    final FocusNode target =
        hasSummary ? _summaryNode : invalid.first.focusNode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      IuxFocus.request(target);
    });
  }

  /// Focuses a field and brings it on screen.
  ///
  /// Both, because either alone leaves someone behind: focus without scrolling
  /// moves a screen-reader user to a field a sighted user still cannot see, and
  /// scrolling without focus does the reverse.
  void _navigateTo(FocusNode node) {
    IuxFocus.request(node);
    final BuildContext? fieldContext = node.context;
    if (fieldContext == null) return;
    // Instant rather than animated. The user asked to be taken somewhere, and
    // an animation between two points they did not choose is a journey they did
    // not ask to watch.
    Scrollable.ensureVisible(fieldContext);
  }

  /// The summary, or null when there is nothing to summarise.
  ///
  /// It appears only after a submission has been attempted. Before that, every
  /// message is already under the field it belongs to, where the user is
  /// looking; a summary at the top of the form would be the same information a
  /// second time, about a question they have not reached yet.
  Widget? _buildSummary() {
    final IuxValidationSummaryLabels? labels = widget.summary;
    if (labels == null) return null;
    if (_attempt == 0) return null;

    final List<IuxFormField> invalid = _invalidFields;
    if (invalid.isEmpty) return null;

    return IuxValidationSummary(
      categoryLabel: labels.categoryLabel,
      message: labels.describeCount(invalid.length),
      navigationHint: labels.navigationHint,
      focusNode: _summaryNode,
      entries: <IuxValidationSummaryEntry>[
        for (final IuxFormField field in invalid)
          IuxValidationSummaryEntry(
            label: field.input.semantics.label,
            // Non-null by construction: IuxInputValidation.invalid requires a
            // message, which is the point of that type.
            message: field.input.validation.message!,
            onActivate: () => _navigateTo(field.focusNode),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget? summary = _buildSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (summary != null) ...<Widget>[
          summary,
          const IuxGap.between(),
        ],
        for (int i = 0; i < widget.sections.length; i++) ...<Widget>[
          if (i > 0) const IuxGap.between(),
          widget.sections[i],
        ],
        const IuxGap.between(),
        // Aligned to the start rather than stretched. A button as wide as the
        // form reads as a banner, and its label drifts far from its own edges —
        // which is why IuxButton does not fill by default either.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IuxButton(
            label: widget.submit.label,
            action: widget.submit.action,
            busyHint: widget.submit.busyHint,
            onActivate: _handleSubmit,
          ),
        ),
      ],
    );
  }
}
