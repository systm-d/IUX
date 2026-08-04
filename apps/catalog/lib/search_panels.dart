import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';

/// Search, in the four states a search is ever in.
///
/// Waiting, answered, answered with nothing, and failed. The one that gets
/// shipped broken is the third: a screen that shows an empty list and says
/// nothing, so the user cannot tell whether the search ran.
class SearchPanels extends StatefulWidget {
  /// Creates the search harness.
  const SearchPanels({super.key, required this.longLabels});

  /// Whether samples use labels of translated length.
  final bool longLabels;

  @override
  State<SearchPanels> createState() => _SearchPanelsState();
}

/// What the demonstration search reports next.
enum _Answer {
  /// The search is still running.
  searching,

  /// The corpus is filtered by whatever is in the box.
  filtered,

  /// The search failed, with a way to try again.
  failed,
}

const List<String> _corpus = <String>[
  'March invoice — Costa Ltd',
  'March invoice — Nordwind GmbH',
  'April invoice — Costa Ltd',
  'Credit note — Nordwind GmbH',
  'Receipt — Costa Ltd',
];

class _SearchPanelsState extends State<SearchPanels> {
  final TextEditingController _query = TextEditingController();
  _Answer _answer = _Answer.filtered;
  int _retries = 0;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<String> get _matches {
    final String needle = _query.text.trim().toLowerCase();
    if (needle.isEmpty) return _corpus;
    return _corpus
        .where((String row) => row.toLowerCase().contains(needle))
        .toList();
  }

  IuxLoadState<List<String>> get _state => switch (_answer) {
        _Answer.searching => const IuxLoadState<List<String>>.loading(),
        _Answer.filtered => IuxLoadState<List<String>>.ready(_matches),
        _Answer.failed => const IuxLoadState<List<String>>.failed(
            message: 'The invoice service did not answer.',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return Column(
      children: <Widget>[
        CatalogPanel(
          title: 'The query box',
          description: 'The clear control appears only when there is something '
              'to clear, and it is named — an unnamed × in a box is announced '
              'as "button" and the only way to find out what it does is to '
              'lose your query to it. Type something, then look for it.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IuxSearchField(
                label: widget.longLabels
                    ? 'Rechnungen und Gutschriften durchsuchen'
                    : 'Search invoices',
                hint: 'Results update as you type',
                placeholder: 'Costa',
                clearLabel: 'Clear the search',
                controller: _query,
                onChanged: (String _) => setState(() {}),
              ),
              const CatalogNote(
                'Clearing returns focus to the box rather than dropping it. '
                'That is the one focus move this pattern makes, and it is '
                'right: the user asked to start again, and starting again '
                'means typing.',
              ),
              const CatalogNote(
                'A search still cannot be run from the keyboard\'s action key '
                'here, and the reason has moved. IuxTextField was missing both '
                'onSubmitted and a search content type — two thirds of '
                'IUX-TEXTFIELD-GAPS-001 — and it has gained both: the Inputs '
                'section reads the content type off the enum, and a field '
                'declared as search offers a "search" key that fires '
                'onSubmitted with the text. This pattern has not been rewired '
                'to use either. Measured on the box above: it builds an '
                'IuxTextField with content "text", passes no onSubmitted, and '
                'its action key is "done". So the query reaches the caller '
                'only through onChanged, and the box is announced as an '
                'ordinary text field rather than a search one — a gap in a '
                'pattern now, where it used to be a gap in the component the '
                'pattern is built on.',
                finding: true,
              ),
            ],
          ),
        ),
        CatalogPanel(
          title: 'What the search answered',
          description: 'Four branches, and every one of them says something. '
              'The one to check hardest is "nothing matched": it is an answer, '
              'not a blank screen, and the sentence is announced as well as '
              'shown. Type "zzz" with the answer set to filtered to reach it.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CatalogChoice<_Answer>(
                label: 'Answer',
                value: _answer,
                values: _Answer.values,
                naming: (_Answer value) => value.name,
                onChanged: (_Answer value) => setState(() => _answer = value),
              ),
              SizedBox(height: geometry.spacingXs),
              // Bounded on purpose, though it no longer has to be. The ready
              // branch used to wrap the caller's list in an Expanded, so
              // placing the pattern in a scroll view — this catalog is one —
              // threw on Flutter's unbounded-constraints assertion at the
              // first non-empty result. It does not any more: probed inside a
              // SingleChildScrollView it lays out with no exception and adds
              // no second scrollable. The box stays because a fixed height is
              // what makes the reachability question below visible.
              SizedBox(
                height: 320,
                child: IuxSearchResults<String>(
                  results: _state,
                  searchingLabel: 'Searching invoices',
                  failureCategoryLabel: 'Error',
                  emptyGuidance:
                      'Try an organisation name, or part of a month.',
                  summary: (BuildContext context, List<String> rows) => rows
                          .isEmpty
                      ? 'Nothing matches "${_query.text}"'
                      : '${rows.length} results for '
                          '"${_query.text.isEmpty ? 'everything' : _query.text}"',
                  recovery: IuxRetryRoute(
                    label: 'Try again',
                    onRetry: () => setState(() {
                      _retries++;
                      _answer = _Answer.filtered;
                    }),
                  ),
                  emptyCause: IuxNoMatches(
                    reset: IuxEmptyStateAction(
                      label: 'Clear the search',
                      action: const IuxActionDescriptor(
                        semantics:
                            IuxActionSemantics(label: 'Clear the search'),
                      ),
                      onActivate: () => setState(_query.clear),
                    ),
                  ),
                  builder: (BuildContext context, List<String> rows) =>
                      ListView(
                    children: <Widget>[
                      for (final String row in rows)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: geometry.spacingXxs,
                          ),
                          child: Text(
                            row,
                            style: type.body
                                .copyWith(color: colors.content.primary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: geometry.spacingXs),
              CatalogRows(<(String, String)>[
                ('Retries', '$_retries'),
                ('Rows in the corpus', '${_corpus.length}'),
                ('Rows matching', '${_matches.length}'),
              ]),
              const CatalogNote(
                'The summary is a function of the results rather than a '
                'sentence beside them, so it cannot go stale. A count and a '
                'state passed separately eventually disagree, and the stale '
                'one is what a screen-reader user hears.',
              ),
              const CatalogNote(
                'This box no longer overflows at 300%, and the rule that '
                'stopped it introducing a second scrollbar is intact. Measured '
                'in a 320-tall box at 300%: no exception, exactly one '
                'scrollable, and the reset control off screen until the user '
                'scrolls to it. The discriminator is the constraint rather '
                'than a parameter — given a bounded height the block scrolls '
                'itself, because something that will not scroll it has just '
                'told it the size of a box; given an unbounded one it adds '
                'nothing, because it is already inside a scroll view. So a '
                'region inside a list that already scrolls still cannot '
                'introduce a second one.',
              ),
              const CatalogNote(
                'Activating the reset loses keyboard focus, because the '
                'control the user just pressed is unmounted when the results '
                'come back. Clearing through the box above does not, because '
                'that control moves focus deliberately. Inherited from '
                'IuxButton and documented under loading-and-retry.',
                finding: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
