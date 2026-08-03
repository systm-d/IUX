import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import 'iux_progress_tokens.dart';

/// How much of the track the indeterminate segment covers.
///
/// Wide enough to read as an object moving, narrow enough that where it is
/// stays unambiguous. A segment much thinner than this reads as a dot and
/// invites the user to look for a value it does not have.
const double _indeterminateSegment = 0.3;

/// Progress through an operation whose extent is known.
///
/// ```dart
/// IuxProgressIndicator(
///   label: l10n.uploadingPhotos,
///   value: uploaded / total,
///   valueLabel: l10n.percentComplete(percent),
/// )
/// ```
///
/// **Use it** whenever the caller can say how far along the work is, even
/// roughly. A determinate indicator answers "how much longer"; an
/// indeterminate one answers nothing, and a user who cannot estimate the wait
/// cannot decide whether to keep waiting.
///
/// **Do not use it** when the extent is genuinely unknown — reach for
/// [IuxLoadingIndicator] and accept that it says less. Do not use it to report
/// a result: reaching 1.0 means the caller supplied 1.0 and nothing more. This
/// widget never decides that an operation finished, succeeded or failed, and
/// it will keep rendering a full bar until the parent replaces it with
/// whatever comes next.
///
/// Reaching the end is not the same as being removed. A bar sitting at 100%
/// with no successor on screen is a parent that forgot to re-render, and it is
/// worth watching for.
///
/// ## Motion
///
/// The fill travels between two values under [IuxMotionRole.progress], which
/// survives a reduced-motion preference: removing it would hide that work is
/// happening, and that is worse than the movement. Under
/// [IuxMotionPreference.none] the travel is removed and the fill snaps — but
/// the bar and the value stay, because a bar at 45% is a static statement
/// whether or not the last change was animated.
class IuxProgressIndicator extends StatefulWidget {
  /// Creates a determinate progress indicator.
  const IuxProgressIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.valueLabel,
  })  : assert(
          label.length > 0,
          'A progress indicator without a description tells the user that '
          'something is happening and refuses to say what. Pass the localised '
          'name of the operation.',
        ),
        assert(
          value >= 0 && value <= 1,
          'value is a fraction of the work, from 0 to 1. Divide at the call '
          'site: a component that accepted arbitrary bounds would have to '
          'guess which of two numbers was the total.',
        ),
        assert(
          valueLabel.length > 0,
          'valueLabel is what a screen reader announces and what a sighted '
          'user reads instead of estimating a bar length. It cannot be empty.',
        );

  /// What is happening, already localised.
  ///
  /// Describe the work, not the widget: "Uploading photos", not "Loading".
  /// This is the line a screen-reader user hears when they land on the
  /// indicator, and the one they hear again when you change it.
  final String label;

  /// How far along the work is, from 0 to 1.
  ///
  /// Out-of-range values assert in debug and are clamped in release, because
  /// a bar painted past its own track is a rendering bug on top of a data bug.
  final double value;

  /// [value] in words, already localised — "45%", "3 of 7", "12 MB of 40 MB".
  ///
  /// Required rather than optional, and never composed by IUX. A bar with no
  /// number leaves the user estimating a length, which people do badly, and it
  /// is the only thing a screen reader can announce as the work advances.
  /// Composing it here would be guessing at a locale: "45%", "45 %" and "٤٥٪"
  /// are three different strings and only the caller knows which one applies.
  ///
  /// Write it so it stands alone. It is announced on its own when progress
  /// crosses a milestone, so "45% uploaded" is kinder than "45%" when the
  /// screen holds more than one operation.
  final String valueLabel;

  /// The value actually painted.
  ///
  /// The assertion in the constructor is the real guard; this only keeps a
  /// release build from painting outside its own track when a caller ships a
  /// division by zero.
  double get _fraction => value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0;

  @override
  State<IuxProgressIndicator> createState() => _IuxProgressIndicatorState();
}

class _IuxProgressIndicatorState extends State<IuxProgressIndicator> {
  /// The value in force the last time the user was told about it.
  late double _announcedValue;

  /// The words that went with it.
  late String _announcedLabel;

  @override
  void initState() {
    super.initState();
    // Eagerly, not through a lazy initialiser. A `late` field is resolved at
    // its first read, and the first read of _announcedValue is inside
    // didUpdateWidget — by which point `widget` is already the new one, so the
    // baseline would record the value it is supposed to be compared against
    // and the first milestone would never be announced.
    _announcedValue = widget._fraction;
    _announcedLabel = widget.valueLabel;
  }

  @override
  void didUpdateWidget(IuxProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (IuxProgressAnnouncementPolicy.shouldAnnounce(
      announced: _announcedValue,
      current: widget._fraction,
      phaseChanged: widget.label != oldWidget.label,
    )) {
      // No setState: the announced text is read during the build this update
      // already scheduled, and calling setState from didUpdateWidget would
      // schedule a second one for nothing.
      _announcedValue = widget._fraction;
      _announcedLabel = widget.valueLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final IuxProgressTokens tokens = IuxProgressResolver.resolve(context);

    final Widget visual = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProgressHeading(
          label: widget.label,
          valueLabel: widget.valueLabel,
          tokens: tokens,
        ),
        const IuxGap.tight(),
        _ProgressTrack(
          tokens: tokens,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: widget._fraction),
            duration: tokens.motion.duration,
            curve: tokens.motion.curve,
            builder: (BuildContext context, double fraction, Widget? child) =>
                FractionallySizedBox(
              // Directional, so the bar fills from the side the user reads
              // from. A left-anchored bar in an Arabic interface reports
              // progress running backwards.
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction.clamp(0.0, 1.0).toDouble(),
              heightFactor: 1,
              child: child,
            ),
            child: ColoredBox(color: tokens.fill),
          ),
        ),
      ],
    );

    // Two nodes, on purpose. The outer one is the standing name, read whenever
    // the user lands on the indicator. The inner one is the only thing that
    // changes, and it changes at milestones rather than at every frame, so a
    // screen reader is told that work is advancing without being made
    // unusable for the duration of the upload.
    //
    // The visual is excluded because it repeats both of those strings
    // verbatim; leaving it in would have the value announced twice.
    return IuxSemantics.group(
      label: widget.label,
      child: IuxSemantics.liveRegion(
        label: _announcedLabel,
        child: IuxSemantics.decorative(child: visual),
      ),
    );
  }
}

/// An operation whose extent is unknown.
///
/// ```dart
/// IuxLoadingIndicator(label: l10n.searchingNearbyStores)
/// ```
///
/// **Use it** only when nothing can be counted — a request whose response size
/// is unknown, a search with no total. Prefer [IuxProgressIndicator] whenever
/// the caller can supply a fraction, however rough: an indeterminate indicator
/// tells the user that they are waiting and refuses to say for how long, which
/// is the state people abandon.
///
/// **Do not use it** to fill the gap for an operation that finishes in under a
/// couple of hundred milliseconds. A spinner that appears and vanishes reads
/// as a glitch, and the flicker costs more attention than the wait did.
/// Do not use it to report an outcome either: this widget never decides that
/// loading finished. The parent stops rendering it.
///
/// ## What happens when motion is off
///
/// This is the component where [IuxMotionRole.progress] earns its
/// [IuxResolvedMotion.requiresStaticAlternative] flag. An indeterminate bar is
/// nothing but movement — freeze it and it becomes a segment parked at a
/// position that means nothing, which reads as a hung operation rather than a
/// running one. So under [IuxMotionPreference.none] the bar is not frozen, it
/// is removed, and [label] carries the whole message as a status line.
///
/// That is why [label] is required and why it is always visible, in both
/// modes: a static alternative that only exists under one preference is a
/// static alternative nobody has ever seen fail.
class IuxLoadingIndicator extends StatefulWidget {
  /// Creates an indeterminate loading indicator.
  const IuxLoadingIndicator({
    super.key,
    required this.label,
  }) : assert(
          label.length > 0,
          'An unlabelled spinner is the most common accessibility failure in '
          'this category: the user knows something is happening and cannot '
          'tell what, nor whether it is stuck. Pass the localised name of the '
          'operation.',
        );

  /// What is being waited on, already localised.
  ///
  /// Always visible, never decorative. It is the status line that replaces the
  /// bar entirely when the user has asked for no motion, and the text a screen
  /// reader announces when you change it.
  final String label;

  @override
  State<IuxLoadingIndicator> createState() => _IuxLoadingIndicatorState();
}

class _IuxLoadingIndicatorState extends State<IuxLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Motion depends on the theme and on the platform preference, both of
    // which arrive through inherited widgets — so this is where a preference
    // switching mid-session is picked up, not initState.
    _synchroniseWithMotionPolicy();
  }

  void _synchroniseWithMotionPolicy() {
    final IuxProgressTokens tokens = IuxProgressResolver.resolve(context);

    if (!tokens.isAnimated) {
      // Stopped, not reset. Resetting would notify the builder that is still
      // mounted from the previous frame, and rebuilding a widget in the middle
      // of a build is how a preference change turns into a crash. Nothing
      // reads the value in this mode anyway: the bar is gone, not frozen.
      _controller.stop();
      return;
    }
    if (_controller.duration != tokens.traversal || !_controller.isAnimating) {
      _controller
        ..duration = tokens.traversal
        // Back and forth rather than resetting. A reset is an instant jump the
        // full width of the track, which is both the sudden large movement
        // reduced-motion users report as uncomfortable and a visual restart
        // that suggests the operation itself began again.
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IuxProgressTokens tokens = IuxProgressResolver.resolve(context);

    final Widget status = _ProgressLabel(
      text: widget.label,
      style: tokens.labelStyle,
    );

    final Widget visual = tokens.requiresStaticAlternative
        ? status
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              status,
              const IuxGap.tight(),
              _ProgressTrack(
                tokens: tokens,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) =>
                      FractionallySizedBox(
                    alignment: AlignmentDirectional(
                      // -1 is flush against the reading start, 1 against the
                      // reading end. The curve comes from the motion theme,
                      // which flattens it to linear once the user has asked
                      // for less — an eased pendulum draws attention to the
                      // movement, which is the opposite of the intent.
                      tokens.motion.curve.transform(_controller.value) * 2 - 1,
                      0,
                    ),
                    widthFactor: _indeterminateSegment,
                    heightFactor: 1,
                    child: child,
                  ),
                  child: ColoredBox(color: tokens.fill),
                ),
              ),
            ],
          );

    // One node. Its label changes only when the caller changes the phase, so
    // this live region cannot spam: there is no number in it to churn.
    return IuxSemantics.liveRegion(
      label: widget.label,
      child: IuxSemantics.decorative(child: visual),
    );
  }
}

/// The bar itself: a track with something painted inside it.
class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.tokens, required this.child});

  final IuxProgressTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius),
        child: SizedBox(
          height: tokens.thickness,
          width: double.infinity,
          child: ColoredBox(color: tokens.track, child: child),
        ),
      );
}

/// The description line, which must survive being enlarged.
class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel({required this.text, required this.style});

  final String text;
  final TextStyle style;

  // No line limit and no ellipsis, at any text scale. "Uploading the
  // photographs you sele…" tells the user less than nothing, and a status
  // line is exactly the text someone reads when they are trying to work out
  // whether to keep waiting.
  @override
  Widget build(BuildContext context) => Text(text, style: style);
}

/// The description and the value, side by side until they no longer fit.
class _ProgressHeading extends StatelessWidget {
  const _ProgressHeading({
    required this.label,
    required this.valueLabel,
    required this.tokens,
  });

  final String label;
  final String valueLabel;
  final IuxProgressTokens tokens;

  @override
  Widget build(BuildContext context) {
    final Widget description = _ProgressLabel(
      text: label,
      style: tokens.labelStyle,
    );
    final Widget value = Text(
      valueLabel,
      style: tokens.valueStyle,
      softWrap: true,
    );

    // Above roughly 130% text scaling a description and a value stop fitting
    // on a phone width. Stacking keeps both readable; shrinking would produce
    // the clipped label users report as "the text size setting does nothing".
    if (IuxReadableText.shouldStack(context)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          description,
          const IuxGap(IuxSpacingStep.xxs),
          value,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(child: description),
        const IuxGap.horizontal(IuxSpacingStep.xs),
        value,
      ],
    );
  }
}
