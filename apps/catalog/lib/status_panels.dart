import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';
import 'catalog_testable.dart';

/// Pictures, glyphs and the small containers that report a state.
///
/// Everything here is either announced or deliberately silent, and the
/// difference is invisible on screen. A decorative glyph that announces itself
/// adds a stop to every swipe through the screen; a meaningful one that does
/// not is information the user never receives. Both look identical.
class StatusPanels extends StatelessWidget {
  /// Creates the media and status harness.
  const StatusPanels({super.key, required this.longLabels});

  /// Whether samples use labels of translated length.
  final bool longLabels;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          const _IconPanel(),
          const _AvatarPanel(),
          _ImagePanel(longLabels: longLabels),
          _StatusPanel(longLabels: longLabels),
          _ValuePanel(longLabels: longLabels),
          _ChipPanel(longLabels: longLabels),
          const _BadgePanel(),
        ],
      );
}

/// A 48×48 checkerboard, embedded so the harness needs no network.
///
/// Not a photograph: what the picture *is* has no bearing on anything checked
/// here, and a decorative bitmap that looked like content would invite exactly
/// the confusion the description parameter exists to prevent.
final Uint8List _checkerboard = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAIAAADYYG7QAAAASklEQVR42u3WsQ0AMAgDMM7u'
  'iT2LCzJWHWJmJDyFzA1zwrzeHyAgoDrQr8NpHwgIqA8kqYGAgPQhrwMISB+S1EBAQPqQ1wEE'
  'VA1ajN7g8SGTS30AAAAASUVORK5CYII=',
);

/// A picture that never arrives, so the reserved frame can be looked at.
class _PendingImage extends ImageProvider<_PendingImage> {
  const _PendingImage();

  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_PendingImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(Completer<ImageInfo>().future);

  @override
  bool operator ==(Object other) => other is _PendingImage;

  @override
  int get hashCode => (_PendingImage).hashCode;
}

/// A picture that fails, which is the state a slow connection produces.
class _FailingImage extends ImageProvider<_FailingImage> {
  const _FailingImage();

  @override
  Future<_FailingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FailingImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _FailingImage key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(
          StateError('the picture service did not answer'),
        ),
      );

  @override
  bool operator ==(Object other) => other is _FailingImage;

  @override
  int get hashCode => (_FailingImage).hashCode;
}

class _IconPanel extends StatelessWidget {
  const _IconPanel();

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return CatalogPanel(
      title: 'Glyphs, meaningful and decorative',
      description: 'Two sizes, two emphases, and one required decision: does '
          'this glyph carry information the user would otherwise not have? '
          'There is no default, because a default would be wrong half the '
          'time and silently.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: geometry.spacingSm,
            runSpacing: geometry.spacingSm,
            children: <Widget>[
              for (final IuxIconSize size in IuxIconSize.values)
                for (final IuxIconEmphasis emphasis in IuxIconEmphasis.values)
                  CatalogSample(
                    caption: '${size.name} · ${emphasis.name}',
                    child: CatalogMeasured(
                      checksTarget: false,
                      child: IuxIcon(
                        icon: Icons.lock_outline,
                        size: size,
                        emphasis: emphasis,
                        description:
                            const IuxImageDescription.meaningful('Private'),
                      ),
                    ),
                  ),
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('a decorative glyph beside its own label'),
          Row(
            children: <Widget>[
              const IuxIcon(
                icon: Icons.delete_outline,
                description: IuxImageDescription.decorative(),
              ),
              SizedBox(width: geometry.spacingXs),
              Text(
                'Delete',
                style: type.body.copyWith(color: colors.content.primary),
              ),
            ],
          ),
          const CatalogNote(
            'The word is already there, so the glyph is declared decorative '
            'and disappears from the semantics tree entirely. Declared '
            'meaningful instead, a screen reader would read "delete, delete" — '
            'which is how a screen full of icons becomes a screen full of '
            'stutters.',
          ),
          const CatalogNote(
            'A glyph is content, so it grows with the text scale and is not '
            'capped. At 300% these are large, and that is the same trade a '
            'label makes: a glyph that stayed small while the words grew would '
            'be the one element on the screen the user cannot enlarge.',
          ),
          const CatalogNote(
            'Nothing can tell whether "Private" describes the padlock '
            'usefully. Every assertion in this family is satisfied by the word '
            '"Image", which helps nobody. Content review is a human '
            'obligation and this is the family where it matters most.',
          ),
        ],
      ),
    );
  }
}

class _AvatarPanel extends StatelessWidget {
  const _AvatarPanel();

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return CatalogPanel(
      title: 'Avatars announce a person, never their initials',
      description: '"MC" spoken aloud is a spelling, not a person. The '
          'separation is structural: there is no arrangement of parameters '
          'that gets the initials announced.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: geometry.spacingSm,
            runSpacing: geometry.spacingSm,
            children: <Widget>[
              for (final IuxAvatarSize size
                  in IuxAvatarSize.values) ...<Widget>[
                CatalogSample(
                  caption: '${size.name} · initials',
                  child: CatalogMeasured(
                    checksTarget: false,
                    child: IuxAvatar(
                      name: 'Maria Costa',
                      initials: 'MC',
                      size: size,
                    ),
                  ),
                ),
                CatalogSample(
                  caption: '${size.name} · picture',
                  child: IuxAvatar(
                    name: 'Maria Costa',
                    image: MemoryImage(_checkerboard),
                    size: size,
                  ),
                ),
                CatalogSample(
                  caption: '${size.name} · neither',
                  child: IuxAvatar(name: 'Maria Costa', size: size),
                ),
              ],
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('decorative, beside the name it stands for'),
          Row(
            children: <Widget>[
              const IuxAvatar.decorative(initials: 'MC'),
              SizedBox(width: geometry.spacingXs),
              Text(
                'Maria Costa',
                style: type.body.copyWith(color: colors.content.primary),
              ),
            ],
          ),
          const CatalogNote(
            'The row already carries the name, so announcing the circle as '
            'well would say it twice. The decorative constructor takes no '
            'name at all, which is the only way to make "announced twice" '
            'unrepresentable rather than merely discouraged.',
          ),
          const CatalogNote(
            'No status dot, no badge and no overlapping stack. A status beside '
            'an avatar is IuxStatusIndicator and a count is IuxBadge, both in '
            'reading order rather than floating over the circle, where they '
            'would be a clipping and text-scaling problem with no announcement '
            'order at all.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('an avatar for a thing, not a person'),
          Wrap(
            spacing: geometry.spacingSm,
            runSpacing: geometry.spacingSm,
            children: <Widget>[
              for (final (IuxAvatarTone tone, IconData glyph, String what) entry
                  in const <(IuxAvatarTone, IconData, String)>[
                (IuxAvatarTone.one, Icons.ac_unit, 'Winter'),
                (IuxAvatarTone.two, Icons.eco_outlined, 'Spring'),
                (IuxAvatarTone.three, Icons.park_outlined, 'Autumn'),
                (IuxAvatarTone.four, Icons.wb_sunny_outlined, 'Summer'),
              ])
                CatalogSample(
                  caption: '${entry.$3} · ${entry.$1.name}',
                  child: CatalogMeasured(
                    checksTarget: false,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IuxAvatar.decorative(icon: entry.$2, tone: entry.$1),
                        SizedBox(width: geometry.spacingXs),
                        Text(entry.$3),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('both sizes, both constructors, toned'),
          Wrap(
            spacing: geometry.spacingSm,
            children: <Widget>[
              for (final IuxAvatarSize size in IuxAvatarSize.values)
                CatalogSample(
                  caption: size.name,
                  child: IuxAvatar(
                    name: 'Winter 2026',
                    icon: Icons.ac_unit,
                    tone: IuxAvatarTone.one,
                    size: size,
                  ),
                ),
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogNote(
            "IuxAvatarTone's members carry no meaning of their own — see "
            'ADR-0014. Which tone means which season is this catalogue\'s '
            'choice, not a mapping IUX ships.',
          ),
          const CatalogNote(
            'Anti-pattern: four circles that differ only in tone. Turn the '
            'contrast down, or imagine them under a colour-vision deficiency, '
            'and the row says nothing — which is why the glyph changes with '
            'the tone above, and why IuxAvatar.icon exists in the same change '
            'as IuxAvatar.tone rather than as a follow-up.',
            finding: true,
          ),
        ],
      ),
    );
  }
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    final String description = longLabels
        ? 'Ein gescannter Zahlungsbeleg der Nordwind GmbH über 1.240 Euro, '
            'abgestempelt am dreißigsten März'
        : 'A scanned receipt for €1,240';

    return CatalogPanel(
      title: 'Pictures, including the ones that never arrive',
      description: 'The frame is reserved from the aspect ratio before '
          'anything decodes, so nothing below it moves when the picture lands '
          '— which on a slow connection happens exactly while the user is '
          'reaching for something. The three states below are arrived, '
          'pending and failed.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CatalogSubheading('arrived'),
          CatalogMeasured(
            checksTarget: false,
            child: IuxImage(
              image: MemoryImage(_checkerboard),
              description: IuxImageDescription.meaningful(description),
              aspectRatio: 16 / 9,
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('pending — the frame is already reserved'),
          CatalogMeasured(
            checksTarget: false,
            child: IuxImage(
              image: const _PendingImage(),
              description: IuxImageDescription.meaningful(description),
              aspectRatio: 16 / 9,
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('failed — the description arrives as text'),
          IuxImage(
            image: const _FailingImage(),
            description: IuxImageDescription.meaningful(description),
            aspectRatio: 16 / 9,
          ),
          const CatalogNote(
            'A screen-reader user is never told the picture failed. They '
            'receive the description, delivered as text instead of as an '
            'image, which is the honest outcome — the information survived. '
            'There is no "unavailable" wording because IUX composes no '
            'user-facing text.',
          ),
          const CatalogNote(
            'Set the text scale to 300% with long labels on and look at the '
            'failed frame. Its description can be taller than the frame it '
            'replaced, and inside a fixed-height box it overflows visibly '
            'rather than clipping. That is deliberate: a visible overflow in '
            'debug is a bug report, a silent clip is the information '
            'disappearing for the users least able to notice.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('decorative, and therefore absent'),
          IuxImage(
            image: MemoryImage(_checkerboard),
            description: const IuxImageDescription.decorative(),
            aspectRatio: 3,
            fit: IuxImageFit.contain,
          ),
          const CatalogNote(
            'Declared decorative, so it is hidden from a screen reader '
            'outright. An empty description string is not this — that state is '
            'refused, because an image announced with no name tells the user '
            'something is there and refuses to say what.',
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    String word(String short, String long) => longLabels ? long : short;

    final List<IuxStatus> statuses = <IuxStatus>[
      IuxStatus.neutral(word('Draft', 'Entwurf, noch nicht freigegeben')),
      IuxStatus.success(word('Paid', 'Vollständig bezahlt und verbucht')),
      IuxStatus.warning(word('Due soon', 'Zahlungsfrist läuft in drei Tagen')),
      IuxStatus.error(word('Overdue', 'Zahlungsfrist überschritten')),
    ];

    return CatalogPanel(
      title: 'Status',
      description: 'Four tones, each one a glyph and a word as well as a '
          'colour. There is no dot-only form and no parameter that asks for '
          'one: a coloured dot is the failure this component exists to '
          'prevent, and a user who cannot distinguish the hues learns nothing '
          'from it at all.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: geometry.spacingXs,
            runSpacing: geometry.spacingXs,
            children: <Widget>[
              for (final IuxStatus status in statuses)
                IuxStatusIndicator(status: status),
            ],
          ),
          SizedBox(height: geometry.spacingXs),
          const CatalogSubheading('the same four, marked as a live region'),
          IuxSemantics.liveRegion(
            child: IuxStatusIndicator(status: statuses.last),
          ),
          const CatalogNote(
            'The indicator is not a live region on its own. Thirty rows each '
            'announcing themselves on every refresh is a list nobody can use '
            'with TalkBack, and only the caller knows which status is worth '
            'an interruption — so the wrapping is at the call site, as above.',
          ),
          const CatalogNote(
            'Four tones and no more. An application needing a fifth is '
            'describing its domain rather than a UX category, and the domain '
            'belongs in the label.',
          ),
        ],
      ),
    );
  }
}

/// The pill that reports a reading against a reference.
class _ValuePanel extends StatelessWidget {
  const _ValuePanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    String sentence(String short, String long) => longLabels ? long : short;

    // The pilot's own four readings, which is the point of the sample: two of
    // them are above their reference and two below, and the hues cross the
    // axis rather than following it. Warmer and drier are both "more than the
    // normal" in one case and "less than" in the other, and they take two
    // different accents; wetter and colder sit on opposite sides and take one.
    final List<(String, IuxValue)> readings = <(String, IuxValue)>[
      (
        'above, accent one',
        IuxValue.above(
          '+2,1 °C',
          meaning: 'warmer',
          label: sentence(
            '2.1 degrees above normal',
            '2.1 degrees above the 1991 to 2020 normal, the widest gap in the '
                'record',
          ),
          accent: IuxValueAccent.one,
        )
      ),
      (
        'above, accent two',
        IuxValue.above(
          '+51 mm',
          meaning: 'wetter',
          label: sentence(
            '51 millimetres above normal',
            '51 millimetres more rain than the 1991 to 2020 normal',
          ),
          accent: IuxValueAccent.two,
        )
      ),
      (
        'below, accent two',
        IuxValue.below(
          '-1,8 °C',
          meaning: 'colder',
          label: sentence(
            '1.8 degrees below normal',
            '1.8 degrees below the 1991 to 2020 normal',
          ),
          accent: IuxValueAccent.two,
        )
      ),
      (
        'below, accent three',
        IuxValue.below(
          '-47 mm',
          meaning: 'drier',
          label: sentence(
            '47 millimetres below normal',
            '47 millimetres less rain than the 1991 to 2020 normal',
          ),
          accent: IuxValueAccent.three,
        )
      ),
      (
        'at, no accent',
        IuxValue.at(
          '0,0 °C',
          meaning: 'as usual',
          label: sentence(
            'at the normal',
            'within a tenth of a degree of the 1991 to 2020 normal',
          ),
        )
      ),
    ];

    return CatalogPanel(
      title: 'A reading, compared',
      description: 'The sister of the status indicator, and the difference is '
          'the axis: a status is news — it worked, it failed — and a reading '
          'is a number held against a reference. Three directions, because a '
          'quantity is above its reference, level with it, or below it, and '
          'there is no fourth side. The colour is not one of the three: the '
          'first two samples are both above their reference and are drawn in '
          'two hues, and the second and third are on opposite sides and drawn '
          'in one. The word under each capsule is what says which is which, '
          'and it cannot be left out. Turn the text to 300% and watch the '
          'narrow sample wrap rather than clip.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: geometry.spacingSm,
            runSpacing: geometry.spacingSm,
            children: <Widget>[
              for (final (String caption, IuxValue value) in readings)
                CatalogSample(
                  caption: caption,
                  child: CatalogMeasured(
                    checksTarget: false,
                    child: IuxValueIndicator(value: value),
                  ),
                ),
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('in a row, where it is normally read'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Expanded(child: Text('Été 2026')),
              SizedBox(width: geometry.spacingSm),
              IuxValueIndicator(value: readings.first.$2),
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('narrow, which is where it has to wrap'),
          const CatalogSample(
            caption: '120 px',
            width: 120,
            child: CatalogMeasured(
              checksTarget: false,
              child: IuxValueIndicator(
                value: IuxValue.above(
                  '+2,1 °C against the normal',
                  meaning: 'warmer than the thirty year normal',
                  label: 'well above the normal',
                  accent: IuxValueAccent.one,
                ),
              ),
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading(
              'the reading the caller wrote without a sign'),
          Wrap(
            spacing: geometry.spacingSm,
            children: const <Widget>[
              IuxValueIndicator(
                value: IuxValue.above(
                  '2,1 °C',
                  meaning: 'warmer',
                  label: '2.1 degrees warmer',
                  accent: IuxValueAccent.one,
                ),
              ),
              IuxValueIndicator(
                value: IuxValue.below(
                  '2,1 °C',
                  meaning: 'colder',
                  label: '2.1 degrees cooler',
                  accent: IuxValueAccent.two,
                ),
              ),
            ],
          ),
          const CatalogNote(
            'Two readings the caller formatted without a sign. Nothing here '
            'can refuse that, and it is why the word is required rather than '
            'recommended: take the colour away — a monochrome screen, a '
            'colour vision deficiency, the two light profiles where the warm '
            'and the amber accent measure 2.2 and 1.1 apart in Oklab x100 '
            'under deuteranopia — and the word is the whole difference. '
            'There is no longer an arrow: it said which side and never which '
            'sense, and it was never in the semantic tree.',
          ),
          const CatalogNote(
            'No focus, no press, no disabled, no loading, no error and no '
            'movement. A value pill has one state and reports no gesture; if '
            'the user can act on a reading, the button goes beside it.',
          ),
          const CatalogNote(
            'Three directions and no fourth, and four accents that mean '
            'nothing on their own. A reading that is above its reference is '
            'not a warning and one below it is not an error — that judgement '
            'is a status, with the words that make it arguable. See ADR-0013 '
            'and ADR-0015.',
          ),
        ],
      ),
    );
  }
}

class _ChipPanel extends StatefulWidget {
  const _ChipPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_ChipPanel> createState() => _ChipPanelState();
}

class _ChipPanelState extends State<_ChipPanel> {
  final Set<String> _selected = <String>{'Overdue'};
  String _interval = '15';

  static const List<String> _filters = <String>['Draft', 'Paid', 'Overdue'];

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    String label(String value) => widget.longLabels
        ? '$value — Zahlungsbestätigungen und Gutschriften'
        : value;

    return CatalogPanel(
      title: 'Chips',
      description: 'A tag states a fact; a filter chip is a control. They look '
          'similar and behave nothing alike, which is why the two are separate '
          'widgets. The measurement under the tag is the point of this panel: '
          'it is deliberately under the target floor, and the harness flags it '
          'as a failure because the harness cannot tell "not a target" from '
          '"a target that is too small".',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CatalogSubheading('a tag, which is not a control'),
          CatalogMeasured(child: IuxTagChip(label: label('Recurring'))),
          const CatalogNote(
            'Under the floor by design — a tag responds to nothing, so there '
            'is no target to make large. A tag placed in a row beside a filter '
            'chip will look inconsistent, and the two should not be mixed. '
            'IuxChipGroup does not enforce that, because a List<Widget> '
            'cannot.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('filters, which are'),
          CatalogTestable(
            what: 'Turns a filter on and off — the row underneath says which '
                'are in force. The last two, "Archived" and "Disputed", take '
                'no callback and will not respond: that is how a chip becomes '
                'unavailable, not a fault.',
            child: IuxChipGroup(
              label: 'Filter invoices by state',
              chips: <Widget>[
                for (final String filter in _filters)
                  IuxFilterChip(
                    label: label(filter),
                    selected: _selected.contains(filter),
                    onSelectionChanged: (bool selected) => setState(() {
                      if (selected) {
                        _selected.add(filter);
                      } else {
                        _selected.remove(filter);
                      }
                    }),
                  ),
                IuxFilterChip(
                  label: label('Archived'),
                  selected: false,
                  onSelectionChanged: null,
                ),
                IuxFilterChip(
                  label: label('Disputed'),
                  selected: true,
                  onSelectionChanged: null,
                ),
              ],
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            (
              'Filters in force',
              _selected.isEmpty ? 'none' : _selected.join(', ')
            ),
          ]),
          const CatalogNote(
            'The last two take no callback, which is how a chip becomes '
            'unavailable. Compare "Disputed" — disabled *and* selected — with '
            'a selected one above it: it keeps the checkmark and the announced '
            'state and loses the heavier outline, because IuxChipState is one '
            'state rather than two independent dimensions. Two of the three '
            'non-colour signals survive, which is why it is a limit rather '
            'than a defect.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('the same chips without the reserved slot'),
          CatalogTestable(
            what: 'A short scale. Toggle one and watch the row not move — '
                'there is no glyph left to appear, and the heavier outline is '
                'drawn inside the padding rather than added to it.',
            child: IuxChipGroup(
              label: 'Refresh interval',
              mark: IuxChipMark.outline,
              chips: <Widget>[
                for (final String minutes in <String>['5', '15', '30', '60'])
                  IuxFilterChip(
                    label: minutes,
                    selected: _interval == minutes,
                    onSelectionChanged: (bool _) =>
                        setState(() => _interval = minutes),
                  ),
              ],
            ),
          ),
          const CatalogNote(
            'These four take two lines with the reserved slot and one without '
            'it: 120 pixels against 56, on a 360-wide screen. Seven of them go '
            'from three lines to two. What costs the width is the slot, not '
            'the text — 22 of a one-character chip\'s 78 pixels — so '
            'shortening a label buys almost nothing, which is the part nobody '
            'guesses while trying to compact a row.',
          ),
          const CatalogNote(
            'The price is a signal. Selection is left to the fill, the outline '
            'weight and the announcement. Weight is not colour, so SC 1.4.1 '
            'still holds — but it is quieter than a glyph appearing, and '
            'quieter for exactly the users the glyph was put there for. Turn '
            'the display monochrome and compare this row with the one above.',
          ),
          const CatalogNote(
            'The group wraps rather than scrolling sideways. A horizontally '
            'scrolling chip row hides options off screen with no affordance; '
            'wrapping costs vertical space instead, and at 300% with long '
            'labels it costs a great deal of it. Look at how much.',
          ),
          const CatalogNote(
            'No removable chip and no leading glyph. The "×" inside a chip is '
            'a second control inside the first: nested targets, an ambiguous '
            'tap near the boundary, and two focus stops that look like one.',
          ),
        ],
      ),
    );
  }
}

class _BadgePanel extends StatelessWidget {
  const _BadgePanel();

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return CatalogPanel(
      title: 'Badges',
      description: 'A count and a marker. The label is the announcement and '
          'the digits are not: "3" spoken alone tells a screen-reader user '
          'that there are three of something. Raise the text scale and check '
          'that a three-digit count still fits inside its own container.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: geometry.spacingSm,
            runSpacing: geometry.spacingSm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final String count in <String>['3', '12', '99+'])
                CatalogSample(
                  caption: count,
                  child: CatalogMeasured(
                    checksTarget: false,
                    child: IuxBadge.count(
                      count: count,
                      label: '$count unread invoices',
                    ),
                  ),
                ),
              const CatalogSample(
                caption: 'marker',
                child: IuxBadge.marker(label: 'Unread invoices'),
              ),
            ],
          ),
          SizedBox(height: geometry.spacingXs),
          Row(
            children: <Widget>[
              Text(
                'Invoices',
                style: type.body.copyWith(color: colors.content.primary),
              ),
              SizedBox(width: geometry.spacingXs),
              const IuxBadge.count(count: '3', label: '3 unread invoices'),
            ],
          ),
          const CatalogNote(
            'A badge sits in reading order beside the thing it counts, never '
            'floating over it. There is no overlay form: a badge positioned on '
            'top of an icon clips at a large text scale, and its announcement '
            'has no defined place in the reading order.',
          ),
        ],
      ),
    );
  }
}
