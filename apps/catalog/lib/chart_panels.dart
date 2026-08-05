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
  Widget build(BuildContext context) => const CatalogPanel(
        title: 'Sparkline, beside the number it is about',
        description: 'No axis, no grid, no labels: nobody can take a value off '
            'it, and it is not meant to be read from. Two of them are scaled '
            'independently, which is why they must never be compared — the '
            'flat one below has the same height as the steep one.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CatalogSubheading('Rising'),
            IuxSparkline(
              points: _thisYear,
              semanticsSummary: 'Rising from January to July, then falling.',
            ),
            CatalogSubheading('Almost flat, at its own scale'),
            IuxSparkline(
              points: <IuxChartPoint>[
                IuxChartPoint(position: 0, value: 12.0),
                IuxChartPoint(position: 1, value: 12.1),
                IuxChartPoint(position: 2, value: 12.0),
                IuxChartPoint(position: 3, value: 12.2),
              ],
              semanticsSummary: 'Unchanged, within a tenth of a degree.',
            ),
          ],
        ),
      );
}
