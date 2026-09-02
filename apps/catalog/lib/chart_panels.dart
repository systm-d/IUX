import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';

/// Twelve monthly readings with a hole where March should be.
const List<IuxChartPoint> _thisYear = <IuxChartPoint>[
  IuxChartPoint(position: 0, value: 4.1),
  IuxChartPoint(position: 1, value: 5.6),
  IuxChartPoint(position: 2, value: null),
  IuxChartPoint(position: 3, value: 12.4),
  IuxChartPoint(position: 4, value: 16.8),
  IuxChartPoint(position: 5, value: 21.2),
  IuxChartPoint(position: 6, value: 24.9),
  IuxChartPoint(position: 7, value: 24.1),
  IuxChartPoint(position: 8, value: 19.3),
  IuxChartPoint(position: 9, value: 14.2),
  IuxChartPoint(position: 10, value: 8.7),
  IuxChartPoint(position: 11, value: 5.2),
];

const List<IuxChartPoint> _lastYear = <IuxChartPoint>[
  IuxChartPoint(position: 0, value: 3.2),
  IuxChartPoint(position: 1, value: 4.9),
  IuxChartPoint(position: 2, value: 8.1),
  IuxChartPoint(position: 3, value: 11.0),
  IuxChartPoint(position: 4, value: 15.4),
  IuxChartPoint(position: 5, value: 19.1),
  IuxChartPoint(position: 6, value: 21.8),
  IuxChartPoint(position: 7, value: 21.4),
  IuxChartPoint(position: 8, value: 17.9),
  IuxChartPoint(position: 9, value: 13.1),
  IuxChartPoint(position: 10, value: 7.8),
  IuxChartPoint(position: 11, value: 4.4),
];

const IuxChartBand _normal = IuxChartBand(
  label: 'Normal 1991-2020',
  lower: <IuxChartPoint>[
    IuxChartPoint(position: 0, value: 2.0),
    IuxChartPoint(position: 3, value: 9.0),
    IuxChartPoint(position: 6, value: 19.0),
    IuxChartPoint(position: 9, value: 11.0),
    IuxChartPoint(position: 11, value: 3.0),
  ],
  upper: <IuxChartPoint>[
    IuxChartPoint(position: 0, value: 5.5),
    IuxChartPoint(position: 3, value: 13.0),
    IuxChartPoint(position: 6, value: 23.5),
    IuxChartPoint(position: 9, value: 15.0),
    IuxChartPoint(position: 11, value: 6.5),
  ],
);

const IuxChartAxis _months = IuxChartAxis(
  min: 0,
  max: 11,
  ticks: <IuxAxisTick>[
    IuxAxisTick(value: 0, label: 'Jan'),
    IuxAxisTick(value: 3, label: 'Apr'),
    IuxAxisTick(value: 6, label: 'Jul'),
    IuxAxisTick(value: 9, label: 'Oct'),
  ],
);

const IuxChartAxis _degrees = IuxChartAxis(
  min: 0,
  max: 30,
  ticks: <IuxAxisTick>[
    IuxAxisTick(value: 0, label: '0 °C'),
    IuxAxisTick(value: 15, label: '15 °C'),
    IuxAxisTick(value: 30, label: '30 °C'),
  ],
);

/// Charts, and the four conditions they usually stop working under.
///
/// A chart is the component most often shipped having only ever been looked at
/// once, at 100%, in light mode, in English, by somebody who could see it.

/// Spans on a shared axis, and the overlap resolution that keeps them honest.
class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel();

  static const IuxSpanKind _work = IuxSpanKind(
    label: 'Declared work',
    texture: IuxSpanTexture.solid,
  );
  static const IuxSpanKind _onCall = IuxSpanKind(
    label: 'On call',
    texture: IuxSpanTexture.hatched,
  );
  static const IuxSpanKind _rest = IuxSpanKind(
    label: 'Statutory rest',
    texture: IuxSpanTexture.dotted,
  );

  // Deliberately overlapping: Tuesday is on call across a shift that is also
  // worked, which is the case a hand-built chart draws wrongly.
  static const List<IuxTimelineRow> _week = <IuxTimelineRow>[
    IuxTimelineRow(
      label: 'Mon',
      spans: <IuxSpan>[
        IuxSpan(kind: _work, start: 9, end: 17),
        IuxSpan(kind: _rest, start: 17, end: 24),
      ],
    ),
    IuxTimelineRow(
      label: 'Tue',
      spans: <IuxSpan>[
        IuxSpan(kind: _onCall, start: 6, end: 20),
        IuxSpan(kind: _work, start: 9, end: 17),
        IuxSpan(kind: _rest, start: 20, end: 24),
      ],
    ),
    IuxTimelineRow(
      label: 'Wed',
      spans: <IuxSpan>[
        IuxSpan(kind: _work, start: 8, end: 13),
        IuxSpan(kind: _rest, start: 14, end: 24),
      ],
    ),
  ];

  static String _hours(double v) =>
      '${v.toInt().toString().padLeft(2, '0')}:00';

  static String _describe(IuxTimelineRow row, List<IuxResolvedSpan> bands) {
    final StringBuffer buffer = StringBuffer(row.label);
    for (final IuxResolvedSpan band in bands) {
      buffer.write(
        ', ${band.kind.label} ${_hours(band.start)} to ${_hours(band.end)}',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) => CatalogPanel(
        title: 'When, and for how long',
        description: 'The other charts answer "how much". Reported as #51 by '
            'an integrator who had already built it: a list saying "rest '
            'short by one hour" is arithmetic; a band visibly thinner than '
            'the one above it is the same fact without the arithmetic.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IuxTimelineChart(
              title: 'Rest periods this week',
              precedence: const <IuxSpanKind>[_work, _onCall, _rest],
              rows: _week,
              axisStart: 0,
              axisEnd: 24,
              formatPosition: _hours,
              describeRow: _describe,
            ),
            const IuxGap.standard(),
            const CatalogNote(
              'Tuesday was handed three overlapping stretches — on call from '
              '06:00 to 20:00, worked from 09:00 to 17:00, rest after. What is '
              'drawn is four disjoint bands, because resolveSpans swept the '
              'axis against the precedence order. A hand-built chart draws the '
              'overlap and is silently wrong.',
            ),
            const CatalogNote(
              'describeRow receives the resolved bands, never the input. The '
              'sentence a screen reader hears cannot describe a different '
              'arrangement from the one on screen — the framework does the '
              'arithmetic, the caller writes the sentence.',
            ),
            const CatalogNote(
              'Four kinds, two palette colours. Rather than add colours whose '
              'distinguishability nobody has measured under dichromacy, the '
              'kinds differ by fill: solid, hatched, dotted, open. That is the '
              'octagon argument applied to an area.',
            ),
          ],
        ),
      );
}

/// Every panel here puts one of those assumptions under pressure.
class ChartPanels extends StatelessWidget {
  /// Creates the chart harness.
  const ChartPanels({super.key, required this.longLabels});

  /// Whether samples use labels of translated length.
  final bool longLabels;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          _LineChartPanel(longLabels: longLabels),
          const _MonochromePanel(),
          const _GapPanel(),
          _BarChartPanel(longLabels: longLabels),
          const _SparklinePanel(),
          const _TimelinePanel(),
        ],
      );
}

class _LineChartPanel extends StatelessWidget {
  const _LineChartPanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) => CatalogPanel(
        title: 'Line chart with a reference band',
        description: 'The signature case: one year laid over the envelope it '
            'is read against. Watch the legend at 300% — it wraps, and the '
            'swatch stays beside the name it belongs to. Watch the value axis '
            'too: the labels move with the gridlines, they are not spaced '
            'evenly.',
        child: IuxLineChart(
          series: <IuxChartSeries>[
            IuxChartSeries(
              label: longLabels
                  ? 'Average monthly temperature, this year'
                  : 'This year',
              stroke: IuxSeriesStroke.solid,
              points: _thisYear,
            ),
            IuxChartSeries(
              label: longLabels
                  ? 'Average monthly temperature, last year'
                  : 'Last year',
              stroke: IuxSeriesStroke.dashed,
              emphasis: IuxSeriesEmphasis.secondary,
              points: _lastYear,
            ),
          ],
          band: _normal,
          horizontalAxis: _months,
          verticalAxis: _degrees,
          semanticsSummary: 'Warmer than the 1991 to 2020 normal every month '
              'from May onwards, and above the top of the band in July.',
          stops: const <IuxChartStop>[
            IuxChartStop(start: 0, end: 2, label: 'Winter, within the normal'),
            IuxChartStop(
              start: 3,
              end: 5,
              label: 'Spring, at the top of the normal',
            ),
            IuxChartStop(start: 6, end: 8, label: 'Summer, above the normal'),
            IuxChartStop(start: 9, end: 11, label: 'Autumn, within the normal'),
          ],
        ),
      );
}

class _MonochromePanel extends StatelessWidget {
  const _MonochromePanel();

  @override
  Widget build(BuildContext context) => const CatalogPanel(
        title: 'Three series, told apart without colour',
        description: 'All three at the same emphasis, so colour distinguishes '
            'nothing and only the stroke pattern is left. This is the check '
            'from docs/accessibility/color-and-non-color-signals.md, made '
            'routine. A fourth series is refused: there is no fourth pattern.',
        child: IuxLineChart(
          series: <IuxChartSeries>[
            IuxChartSeries(
              label: 'Solid',
              stroke: IuxSeriesStroke.solid,
              points: _thisYear,
            ),
            IuxChartSeries(
              label: 'Dashed',
              stroke: IuxSeriesStroke.dashed,
              points: _lastYear,
            ),
            IuxChartSeries(
              label: 'Dotted',
              stroke: IuxSeriesStroke.dotted,
              points: <IuxChartPoint>[
                IuxChartPoint(position: 0, value: 1),
                IuxChartPoint(position: 6, value: 28),
                IuxChartPoint(position: 11, value: 2),
              ],
            ),
          ],
          horizontalAxis: _months,
          verticalAxis: _degrees,
          semanticsSummary: 'Three series with the same weight, separated by '
              'their stroke pattern alone.',
        ),
      );
}

class _GapPanel extends StatelessWidget {
  const _GapPanel();

  @override
  Widget build(BuildContext context) => const CatalogPanel(
        title: 'A missing reading is a hole',
        description: 'March is null in this series, and the line stops rather '
            'than crossing it. The alternative — joining the two neighbours — '
            'draws a month of steady weather nobody observed, and nothing on '
            'screen would say it was invented.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CatalogSubheading('One reading missing'),
            IuxLineChart(
              series: <IuxChartSeries>[
                IuxChartSeries(
                  label: 'This year',
                  stroke: IuxSeriesStroke.solid,
                  points: _thisYear,
                ),
              ],
              horizontalAxis: _months,
              verticalAxis: _degrees,
              semanticsSummary: 'March was not measured.',
            ),
            CatalogSubheading('One reading present, and alone'),
            IuxSparkline(
              points: <IuxChartPoint>[
                IuxChartPoint(position: 0, value: null),
                IuxChartPoint(position: 1, value: 12),
                IuxChartPoint(position: 2, value: null),
              ],
              semanticsSummary: 'One reading, in February.',
            ),
          ],
        ),
      );
}

class _BarChartPanel extends StatelessWidget {
  const _BarChartPanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) => CatalogPanel(
        title: 'Bars, one per row',
        description: 'Horizontal on purpose. Turn the text up to 300% and the '
            'names wrap and the rows grow; the vertical arrangement this '
            'replaces would have collided its labels and then truncated them, '
            'for exactly the reader who asked for larger text.',
        child: IuxBarChart(
          bars: <IuxChartBar>[
            IuxChartBar(
              label: longLabels ? 'Villars-les-Dombes (Ain)' : 'January',
              value: 82,
              valueLabel: '82 mm',
            ),
            IuxChartBar(
              label: longLabels
                  ? 'Saint-Just-le-Martel (Haute-Vienne)'
                  : 'February',
              value: 61,
              valueLabel: '61 mm',
            ),
            IuxChartBar(
              label: longLabels ? 'Bourg-en-Bresse (Ain)' : 'March',
              value: 104,
              valueLabel: '104 mm',
              emphasis: IuxSeriesEmphasis.secondary,
            ),
            const IuxChartBar(
              label: 'Nothing at all',
              value: 0,
              valueLabel: '0 mm',
            ),
          ],
          semanticsSummary: 'Wettest in March, driest in February.',
        ),
      );
}

class _SparklinePanel extends StatelessWidget {
  const _SparklinePanel();

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    return CatalogPanel(
      title: 'Sparkline, beside the number it is about',
      description: 'No axis, no grid, no labels: nobody can take a value off '
          'it, and it is not meant to be read from. Two of them are scaled '
          'independently, which is why they must never be compared — the '
          'flat one below has the same height as the steep one.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const CatalogSubheading('Rising'),
          const IuxSparkline(
            points: _thisYear,
            semanticsSummary: 'Rising from January to July, then falling.',
          ),
          const CatalogSubheading('Almost flat, at its own scale'),
          const IuxSparkline(
            points: <IuxChartPoint>[
              IuxChartPoint(position: 0, value: 12.0),
              IuxChartPoint(position: 1, value: 12.1),
              IuxChartPoint(position: 2, value: 12.0),
              IuxChartPoint(position: 3, value: 12.2),
            ],
            semanticsSummary: 'Unchanged, within a tenth of a degree.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('tinted, and marking where the line stops'),
          Wrap(
            spacing: geometry.spacingSm,
            runSpacing: geometry.spacingSm,
            children: <Widget>[
              for (final IuxValueAccent accent in IuxValueAccent.values)
                CatalogSample(
                  caption: accent.name,
                  width: 120,
                  child: IuxSparkline(
                    points: const <IuxChartPoint>[
                      IuxChartPoint(position: 0, value: 0.2),
                      IuxChartPoint(position: 1, value: 1.1),
                      IuxChartPoint(position: 2, value: 2.1),
                    ],
                    semanticsSummary:
                        'Further from the normal each month of the season.',
                    accent: accent,
                    marksEnd: true,
                  ),
                ),
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogNote(
            'The same accents `IuxValueIndicator` uses for its capsule, '
            'reused rather than duplicated — ADR-0013 and ADR-0015. '
            '`IuxStatusTone` was deliberately not offered here: a sparkline '
            'of a deviation from a normal is a comparison, not news. Nor is '
            'the hue read off the side of the reference: a series of rainfall '
            'totals above their normal is wetter, and only the application '
            'knows that wetter is blue.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('a series whose tail has not been published'),
          const CatalogSample(
            caption: 'marker on the last reading',
            width: 120,
            child: IuxSparkline(
              points: <IuxChartPoint>[
                IuxChartPoint(position: 0, value: 0.2),
                IuxChartPoint(position: 1, value: 1.1),
                IuxChartPoint(position: 2, value: null),
              ],
              semanticsSummary: 'Two months measured; the third is not in yet.',
              marksEnd: true,
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogNote(
            'Anti-pattern: two sparklines side by side differing only in '
            'direction. Their summaries say the same thing, so the picture '
            'carries a meaning nothing else does — which is the failure the '
            'required summary exists to prevent.',
          ),
        ],
      ),
    );
  }
}
