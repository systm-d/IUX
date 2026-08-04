import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';

/// Telling the user something, in the two shapes that stay on screen.
///
/// The transient strip is the channel that forgets; these are the ones that do
/// not. Everything here is a live region, which means the interesting failure
/// is not visual at all — it is a message that changes on every frame and
/// therefore speaks on every frame, or one whose category is carried by a
/// colour and a glyph and never by a word.
class FeedbackPanels extends StatelessWidget {
  /// Creates the feedback harness.
  const FeedbackPanels({super.key, required this.longLabels});

  /// Whether samples use text of translated length.
  final bool longLabels;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          _InlineFeedbackPanel(longLabels: longLabels),
          _EveryCategoryPanel(longLabels: longLabels),
          const _ProgressPanel(),
          const _FeedbackRefusalPanel(),
        ],
      );
}

/// The message the feedback harness shows, short and translated.
String _message({required bool long}) => long
    ? 'Die Zahlung wurde von der Bank abgelehnt. Prüfen Sie die hinterlegte '
        'Karte oder wählen Sie ein anderes Zahlungsmittel aus.'
    : 'The card was declined.';

class _InlineFeedbackPanel extends StatefulWidget {
  const _InlineFeedbackPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_InlineFeedbackPanel> createState() => _InlineFeedbackPanelState();
}

class _InlineFeedbackPanelState extends State<_InlineFeedbackPanel> {
  IuxFeedbackCategory _category = IuxFeedbackCategory.error;
  bool _withTitle = true;
  bool _withAction = true;
  bool _withDismissal = false;
  int _acted = 0;
  int _dismissed = 0;

  /// Whether the current combination is one the component accepts.
  ///
  /// An error that can be dismissed and offers nothing to do about it is
  /// refused: closing it is then the only available response to a failure, and
  /// the user is left with a problem and no route out of it. Shown as a
  /// disabled combination rather than built, because building it would stop
  /// the application.
  bool get _legal => !(_category == IuxFeedbackCategory.error &&
      _withDismissal &&
      !_withAction);

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final bool long = widget.longLabels;

    final IuxNamedAction? action = _withAction
        ? IuxNamedAction(
            label: 'Use another card',
            onActivate: () => setState(() => _acted++),
          )
        : null;

    final IuxInlineFeedbackDismissal? dismissal = _withDismissal
        ? IuxInlineFeedbackDismissal(
            label: 'Dismiss',
            onDismissed: () => setState(() => _dismissed++),
          )
        : null;

    final String? title =
        _withTitle ? (long ? 'Zahlung abgelehnt' : 'Payment declined') : null;

    return CatalogPanel(
      title: 'A message that stays',
      description: 'An alert sits beside the thing it is about; a banner runs '
          'edge to edge above the content it concerns. They take exactly the '
          'same parameters and differ only in that, which is the argument for '
          'them being two widgets rather than a flag — the choice is about '
          'where the message belongs, and a flag would invite it being made by '
          'whichever looked better.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<IuxFeedbackCategory>(
            label: 'Category',
            value: _category,
            values: IuxFeedbackCategory.values,
            naming: (IuxFeedbackCategory value) => value.name,
            onChanged: (IuxFeedbackCategory value) =>
                setState(() => _category = value),
          ),
          CatalogChoice<bool>(
            label: 'Title',
            value: _withTitle,
            values: const <bool>[true, false],
            naming: (bool value) => value ? 'present' : 'absent',
            onChanged: (bool value) => setState(() => _withTitle = value),
          ),
          CatalogChoice<bool>(
            label: 'Action',
            value: _withAction,
            values: const <bool>[true, false],
            naming: (bool value) => value ? 'present' : 'absent',
            onChanged: (bool value) => setState(() => _withAction = value),
          ),
          CatalogChoice<bool>(
            label: 'Dismissal',
            value: _withDismissal,
            values: const <bool>[false, true],
            naming: (bool value) => value ? 'present' : 'absent',
            onChanged: (bool value) => setState(() => _withDismissal = value),
          ),
          SizedBox(height: geometry.spacingXs),
          if (!_legal)
            const CatalogNote(
              'This combination is refused: an error that can be dismissed and '
              'offers nothing to do about it. It is not drawn, because the '
              'assertion would stop the harness — turn the action back on, or '
              'the dismissal off. That the harness has to check this by hand '
              'is itself the point about debug-only assertions.',
              finding: true,
            )
          else ...<Widget>[
            const CatalogSubheading('an alert, beside what it is about'),
            IuxAlert(
              category: _category,
              categoryLabel: _category.name,
              title: title,
              message: _message(long: long),
              action: action,
              dismissal: dismissal,
            ),
            SizedBox(height: geometry.spacingSm),
            const CatalogSubheading('a banner, above the content it concerns'),
            IuxBanner(
              category: _category,
              categoryLabel: _category.name,
              title: title,
              message: _message(long: long),
              action: action,
              dismissal: dismissal,
            ),
          ],
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Action taken', '$_acted'),
            ('Dismissed', '$_dismissed'),
          ]),
          const CatalogNote(
            'The category word is required and it is the caller\'s. A red '
            'block with a triangle in it says "error" to somebody who can see '
            'both; the word is what says it to everybody else, and it has to '
            'be a parameter because IUX composes no user-facing text and does '
            'not know what language this is.',
          ),
          const CatalogNote(
            'The dismiss control comes before the action in reading order, '
            'because it sits in the trailing top corner and both TalkBack and '
            'the focus traversal sort geometrically. Forcing a different '
            'keyboard order would give a user of both a switch and a screen '
            'reader two different sequences for one message. The message is '
            'heard before either, in every case.',
          ),
          const CatalogNote(
            'One action, and it cannot be busy. There is no loading state on '
            'it and no second action: an action with a lifecycle belongs in a '
            'button below the message, and two actions inside a message is a '
            'decision that belongs in a dialog.',
          ),
          const CatalogNote(
            'Nothing is throttled. Changing the message every frame makes the '
            'live region speak every frame — progress solved that with '
            'milestones because progress changes continuously, and a parent '
            'that changes an inline message continuously has a different '
            'problem than this component can solve.',
          ),
        ],
      ),
    );
  }
}

class _EveryCategoryPanel extends StatelessWidget {
  const _EveryCategoryPanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'Four categories, one above the other',
      description: 'The comparison the previous panel cannot make, because it '
          'shows one at a time. Two that read the same are a category doing no '
          'work. Turn on high contrast, then look again without reading the '
          'words: what should still separate them is the glyph, and the glyph '
          'alone has to carry it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final IuxFeedbackCategory category
              in IuxFeedbackCategory.values) ...<Widget>[
            IuxAlert(
              category: category,
              categoryLabel: category.name,
              message: longLabels
                  ? 'Eine Meldung der Kategorie ${category.name}, in der '
                      'Länge, die eine Übersetzung tatsächlich erzeugt.'
                  : 'A message in the ${category.name} category.',
            ),
            SizedBox(height: geometry.spacingXs),
          ],
          const CatalogNote(
            'Every message carries a glyph, including the informational one, '
            'which costs about 32 logical pixels of width on a narrow screen. '
            'There is no icon-free variant: removing it would leave colour and '
            'wording, and the wording is the caller\'s — so the one signal the '
            'component can guarantee would be the one it had dropped.',
          ),
          const CatalogNote(
            'The banner does not pin itself; it renders where it is placed. '
            'Keeping one visible while the content below scrolls is a layout '
            'decision, and a component that installed itself at the top of a '
            'screen would be doing navigation.',
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatefulWidget {
  const _ProgressPanel();

  @override
  State<_ProgressPanel> createState() => _ProgressPanelState();
}

class _ProgressPanelState extends State<_ProgressPanel> {
  double _value = 0.45;
  bool _honest = true;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxMotionTheme motion = IuxMotionTheme.of(context);

    return CatalogPanel(
      title: 'How far along, and the edges of it',
      description: 'A determinate bar keeps its bar when motion is reduced, '
          'because 45% is already a static statement. An indeterminate one '
          'removes its bar entirely and falls back to its label, because a '
          'frozen segment is parked at a position that means nothing and reads '
          'as a hung operation. Set motion to "none" in the conditions and '
          'compare the two.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<double>(
            label: 'Value',
            value: _value,
            values: const <double>[0, 0.45, 1],
            naming: (double value) => '${(value * 100).round()}%',
            onChanged: (double value) => setState(() => _value = value),
          ),
          CatalogChoice<bool>(
            label: 'Value label',
            value: _honest,
            values: const <bool>[true, false],
            naming: (bool value) => value ? 'agrees with the bar' : 'lies',
            onChanged: (bool value) => setState(() => _honest = value),
          ),
          SizedBox(height: geometry.spacingXs),
          IuxProgressIndicator(
            label: 'Uploading invoices',
            value: _value,
            valueLabel: _honest ? '${(_value * 100).round()}%' : '90%',
          ),
          SizedBox(height: geometry.spacingSm),
          const IuxLoadingIndicator(label: 'Checking availability'),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            (
              'Non-essential motion allowed',
              motion.allowsNonEssentialMotion ? 'yes' : 'no'
            ),
            ('Value in force', _value.toStringAsFixed(2)),
          ]),
          const CatalogNote(
            'Set the value label to "lies" and look at the bar against the '
            'number. The label is a free string and nothing compares it with '
            'the value, so a bar at 45% can announce "90%" — and the '
            'announcement is what a screen-reader user receives, so the two '
            'audiences are told different things. The parameter exists because '
            'IUX cannot compose a percentage: "%", "٪" and "45 %" are all '
            'locale decisions. That is a good reason for the parameter and not '
            'a reason for it to be unchecked.',
            finding: true,
          ),
          const CatalogNote(
            'Zero and one are both legal and both look like a mistake — an '
            'empty track reads as "nothing is happening" and a full one as '
            '"finished, why is this still here". Neither is the component\'s '
            'to fix: a bar at 100% that should have been dismissed is the '
            'parent still rendering it.',
          ),
          const CatalogNote(
            'Announcements are throttled to ten-point milestones, so a bar '
            'moving continuously does not speak continuously. Ten points is a '
            'judgement rather than a measured optimum, and it has not been '
            'validated with screen-reader users — which is worth knowing '
            'before anyone quotes it as a rule.',
          ),
          const CatalogNote(
            'TalkBack presents the determinate indicator as two stops, the '
            'description and then the value. That is one swipe more than a '
            'single node, and it is the cost of being able to announce the '
            'value on its own rather than composing a sentence IUX has no '
            'right to compose.',
          ),
          const CatalogNote(
            'Linear only. There is no circular variant, because a circle has '
            'no room for a label beside it and is the shape most often shipped '
            'without one. There is also no elapsed time, no "this is taking '
            'longer than usual" and no cancel: all three need to know about '
            'the operation, which a progress bar may not.',
          ),
        ],
      ),
    );
  }
}

class _FeedbackRefusalPanel extends StatelessWidget {
  const _FeedbackRefusalPanel();

  @override
  Widget build(BuildContext context) => const CatalogPanel(
        title: 'What feedback refuses',
        description: 'Assertions, so a release build has none of them.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CatalogRows(<(String, String)>[
              ('a dismissible error with no action', 'closing is not fixing'),
              ('an empty message', 'a coloured block saying nothing'),
              ('an empty category label', 'colour left to do the work'),
              ('an empty title', 'a line reserved and unused'),
              ('a progress value outside 0 to 1', 'a bar off its own track'),
              ('an empty progress label', 'a bar for nothing in particular'),
              ('an empty value label', 'the number that carries the meaning'),
            ]),
            CatalogNote(
              'The first is the interesting one and it is the only refusal '
              'here that is about meaning rather than about empty strings. '
              'Information, success and warning may all be dismissed with '
              'nothing offered; an error may not, because dismissing it would '
              'then be the entire available response to a failure.',
            ),
            CatalogNote(
              'The progress indicator clamps rather than throwing in release: '
              'a value outside the range becomes 0 or 1, and a non-finite one '
              'becomes 0. So the assertion catches a developer and the clamp '
              'catches the user — which is the right pair, and it is rarer in '
              'this library than it should be.',
            ),
          ],
        ),
      );
}
