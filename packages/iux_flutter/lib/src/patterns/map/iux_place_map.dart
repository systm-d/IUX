import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../components/button/iux_button.dart';
import '../../components/list/iux_list_group.dart';
import '../../components/list/iux_list_item.dart';
import '../../layout/iux_section.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import 'iux_place_map_model.dart';

/// What share of the height it is given the map region may take.
///
/// Two fifths. Chosen so that on the smallest screen this library targets —
/// 320x640 — the map keeps 256 logical pixels, enough to read a street layout,
/// while the list keeps the majority. The number is a hypothesis, not a
/// measured optimum; what is measured is that no text scale from 100% to 300%
/// overflows or puts a row out of reach at either share.
const double _kMapHeightShare = 0.4;

/// The height below which a map region is not worth drawing.
///
/// A 90-pixel strip of tiles shows a road and no context, and it costs the
/// list the room to show a row. Below this the map is dropped and the list
/// takes the whole height — see the note on which half survives in
/// [IuxPlaceMap].
const double _kMinimumMapHeight = 120;

/// The height above which more map stops buying anything.
///
/// On a tablet or a desktop window two fifths of the height is a great deal of
/// map, and the extra pixels are better spent on rows the user can read at a
/// glance.
const double _kMaximumMapHeight = 360;

/// Why a map of nowhere is refused.
const String _kNoPlaces =
    'A place map must have at least one place. An empty list is not a map with '
    'nothing on it — it is one of four different situations, each with a '
    'different way out, and this pattern can express none of them: a round '
    'nobody has scheduled yet is IuxNothingCreatedYet, a filter that excluded '
    'every visit is IuxNoMatches and needs a reset, a round this user may not '
    'see is IuxAccessRestricted, and a round whose visits are all done is '
    'IuxNothingLeftToDo. Render IuxEmptyState with the situation that applies '
    'and reach for this pattern once there is something to show. If the round '
    'has not answered yet, that is IuxLoadState and IuxLoadingRetry, one level '
    'up.';

/// Why an unnamed list is refused.
const String _kEmptyListLabel =
    'The list must be named, already localised. The name is published as a '
    'heading, which is how a screen-reader user jumps to the list instead of '
    'swiping through everything above it — and it is what tells them what the '
    'rows are: "Visits on this round", "Collection points". Without it the '
    'list is a heap of rows that appears after a region they were told '
    'nothing about.';

/// Why an empty hint is refused rather than ignored.
const String _kEmptyHint =
    'An empty hint is the same as no hint, and says so less clearly. Omit the '
    'parameter, or pass the localised outcome of activating a row — "centres '
    'the map on this visit", "opens the visit".';

/// Why a hint for a tap that does not exist is refused.
const String _kHintWithoutTap =
    'This describes what activating a row does, and the rows do not activate: '
    'onPlaceSelected is null, so the list is a reading list and no row is a '
    'control. A hint on a row that is not a control is announced to a user who '
    'is then given nothing to activate. Supply onPlaceSelected, or drop the '
    'hint.';

/// Why two places sharing an identifier are refused.
const String _kDuplicateIds =
    'Two places share an id. The selection points at a place by id, so a '
    'duplicate makes "which row is the current one" a question with two '
    'answers, resolved silently in favour of whichever was built first.';

/// Why a selection naming no place is refused.
const String _kUnknownSelection =
    'The selection names a place that is not in the list. The pattern would '
    'announce that a place is now the current one and highlight nothing, '
    'leaving a screen-reader user hunting the list for a row that is not '
    'there. This usually means the selection outlived a filter that removed '
    'its place: clear the selection at the same moment.';

/// Whether every place carries a distinct [IuxPlace.id].
bool _debugDistinctIds(List<IuxPlace> places) {
  final Set<String> seen = <String>{};
  for (final IuxPlace place in places) {
    if (!seen.add(place.id)) return false;
  }
  return true;
}

/// Whether [selection], when there is one, names a place that exists.
bool _debugSelectionExists(List<IuxPlace> places, IuxMapSelection? selection) {
  if (selection == null) return true;
  for (final IuxPlace place in places) {
    if (place.id == selection.placeId) return true;
  }
  return false;
}

/// A geographic map and the same places as a list, which is the part IUX
/// guarantees.
///
/// ```dart
/// IuxPlaceMap(
///   places: <IuxPlace>[
///     for (final Visit visit in round)
///       IuxPlace(
///         id: visit.reference,
///         ordinal: l10n.stopNumber(visit.position),
///         name: visit.site,
///         detail: l10n.addressLine(visit.address),
///         distance: l10n.distance(visit.metres),
///       ),
///   ],
///   map: GoogleMap(initialCameraPosition: camera, markers: markers),
///   zoom: IuxZoomControls(
///     zoomInLabel: l10n.zoomIn,
///     zoomOutLabel: l10n.zoomOut,
///     onZoomIn: controller.zoomIn,
///     onZoomOut: controller.zoomOut,
///   ),
///   listLabel: l10n.visitsOnThisRound,
///   selection: selected,
///   placeActionHint: l10n.centresTheMapOnThisVisit,
///   onPlaceSelected: controller.select,
/// )
/// ```
///
/// **Use it** wherever an application shows a set of real-world places on a
/// map: a field-service round, delivery stops, branches, collection points,
/// sites on a schedule.
///
/// **Do not use it for a map that is not about places** — a heat map, a
/// coverage area, a route drawn without stops. The equivalent this pattern
/// guarantees is a list of named places, and a map whose information is not a
/// set of places has no such equivalent. It needs one, but not this one.
///
/// **Do not use it for a picture of a map.** A static image of a location, in
/// an article or a confirmation screen, is `IuxImage` with a description.
///
/// **Do not use it while the round is still loading, and do not use it when
/// the round is empty.** Both are refused: see "There is no empty branch here"
/// below.
///
/// ## IUX does not render the map, and that is the constraint that shapes
/// everything
///
/// This package touches no platform. It declares no plugin, opens no method
/// channel, and `test/patterns/iux_place_map_test.dart` proves it by parsing
/// this file: every import is `package:flutter/…` or relative, and no line of
/// code outside a comment mentions a platform channel, `dart:io`, or a map
/// SDK. So [map] is yours — a `GoogleMap`, an OSM widget, anything — and
/// everything around it is this pattern's.
///
/// The consequence worth saying out loud: **the visual half of this pattern
/// cannot be verified in this repository at all.** No widget test and no
/// emulator here draws a real tile. Every claim below about the list, the
/// controls, the semantics tree and the layout is measured; every claim about
/// what the map *shows* is the caller's to verify on a device.
///
/// ## The list is not a caption, and it cannot be turned off
///
/// A map is the hardest case in WCAG 2.2 SC 1.1.1 (Non-text Content):
/// information that exists only as spatial arrangement. The usual answer —
/// a `semanticLabel` on the map — is a described image, and a described image
/// is the wrong answer here. "A map showing five visits around Salford" tells
/// a screen-reader user that there are five visits and nothing they can act
/// on: not where the visits are, not which is next, not which is nearest, not
/// the address of any of them.
///
/// The honest answer is that **the same information exists as a list**: every
/// place named, with what makes it findable and orderable — its ordinal, its
/// address, how far away it is. A screen-reader user does not read a map. They
/// read what is on it, in an order that serves them.
///
/// So the list is not a parameter. [places] is required, this widget renders
/// the rows itself, and there is **no parameter that hides them** — no
/// `showList`, no `accessibleMode`, no builder that could return something
/// else. A map without its list equivalent is not something a call site can
/// express, in the same way that `IuxDestructiveFlow` cannot be given a
/// deletion without an `IuxWayBack`. That is the central decision of this
/// pattern, and the alternatives it was taken against are argued in
/// `docs/patterns/place-map.md`.
///
/// **It is what licenses hiding the map.** Because the list is guaranteed, the
/// map subtree is removed from the semantics tree outright, through
/// `IuxSemantics.decorative`. A platform map view contributes a pile of
/// unlabelled nodes a user swipes through and learns nothing from; the same
/// information is one heading away as text. Neither half of that trade is
/// defensible on its own — hiding a map with no text equivalent would be
/// deleting the content, and keeping the noise would be leaving it in.
///
/// ## The list is a peer, not a fallback
///
/// It is on screen, always, beside the map — not behind a disclosure and not
/// behind a mode. Three arrangements were considered and two rejected:
///
/// - **A switch ("accessible view").** The user has to know it exists, and
///   until they find it the default state of the screen is a map with no text
///   equivalent, which is the state SC 1.1.1 forbids. It also takes the list
///   away from everyone else, and scanning a round as text is faster than
///   reading it off a map for a driver at a junction as much as for anyone
///   using a screen reader.
/// - **A draggable sheet**, the convention every consumer map application
///   uses. Dragging a sheet open is a path-based gesture, so SC 2.5.1 then
///   requires a single-pointer alternative for the sheet as well as for the
///   pinch — a criterion bought rather than met. Collapsed, it shows one row,
///   which is a disclosure wearing a different shape.
/// - **Both on screen**, which is what this does. The cost is real and
///   measured: on 320x640 the map takes 256 pixels and the list keeps the
///   rest, so at 200% text about two rows are visible at a time and the rest
///   are a scroll away. Two rows of eight is a worse overview than a sheet
///   dragged to full height would give. It is a worse overview that is always
///   there.
///
/// ## The map yields, the list never does
///
/// The map region takes two fifths of the height this widget is given, capped
/// at 360 logical pixels. If that leaves it under 120 the map is not drawn at
/// all and the list takes everything.
///
/// The asymmetry is the point: **the list is the equivalent of the map, and
/// the map is not the equivalent of the list.** When only one of the two can
/// be shown, it is the one everybody can read. A 90-pixel band of tiles is not
/// a map anyone can navigate by, so nothing is lost that was working.
///
/// Given an unbounded height — inside a `ListView`, a `SingleChildScrollView`,
/// an `IuxPage` — there is no share to take a fraction of, so the map is given
/// its minimum and the caller's scroll view carries the rest. That is the same
/// discriminator `IuxEmptyState` uses and it is not a heuristic: every
/// vertical scroll view in Flutter hands its children an unbounded height,
/// which is what makes it a scroll view. What it costs is a gesture conflict
/// the caller has to know about — see "Known limitations".
///
/// ## Pinch is never the only way to zoom
///
/// [zoom] is required and sealed. `IuxZoomControls` says the map zooms and
/// supplies the route that is not a gesture; `IuxZoomFixed` says the map does
/// not zoom, so there is nothing to replace. There is no third answer and no
/// default, because both are claims about a widget IUX cannot inspect and a
/// default would make one of them on the caller's behalf. See [IuxMapZoom] for
/// the criteria (SC 2.1.1 Keyboard, SC 2.5.1 Pointer Gestures).
///
/// **The controls are under the map, never over it.** That is a contrast
/// decision, not a taste one. A control floating over map tiles has no
/// determinate contrast ratio at all — the background is a photograph the
/// theme has never measured, and it changes as the user pans. IUX has one
/// honest place to put a control it is asked to guarantee 3:1 for (SC 1.4.11),
/// and that is the page surface, where `IuxButton`'s measurements hold. The
/// cost is a strip of vertical space; the alternative is a guarantee the
/// library would be making up.
///
/// ## There is no empty branch here, and no loading branch
///
/// An empty list is refused at construction. "No places" is not one situation
/// but four, with four different exits, and `IuxEmptyStateCause` already
/// distinguishes them: a round nobody has scheduled (`IuxNothingCreatedYet`),
/// a filter that excluded every visit (`IuxNoMatches`, which requires a
/// reset), a round this user may not see (`IuxAccessRestricted`), a round
/// whose visits are all done (`IuxNothingLeftToDo`). A fifth cause is not
/// needed and an `empty` branch here would flatten the four into one word —
/// which is the argument `IuxLoadState` already makes for having no `empty`
/// state of its own.
///
/// A round that has not answered yet is `IuxLoadState`, and the region that
/// renders the wait and the failure is `IuxLoadingRetry`, one level up:
///
/// ```dart
/// IuxLoadingRetry<List<Visit>>(
///   state: controller.state,
///   loadingLabel: l10n.loadingTodaysRound,
///   failureCategoryLabel: l10n.error,
///   recovery: IuxRetryRoute(label: l10n.tryAgain, onRetry: controller.load),
///   builder: (BuildContext context, List<Visit> round) => round.isEmpty
///       ? IuxEmptyState(cause: ..., title: l10n.nothingScheduledToday)
///       : IuxPlaceMap(places: ..., map: ..., zoom: ..., listLabel: ...),
/// )
/// ```
///
/// No state machine is invented here and none is needed. **The one wait this
/// pattern genuinely cannot see is the map's own tiles**: they load over the
/// network, inside a widget IUX does not own and cannot observe without
/// touching the platform. If they never arrive the caller's map shows a blank
/// square and nothing in IUX knows. The list is unaffected, which is the
/// strongest reason for it to be there.
///
/// ## Selection
///
/// [selection] names the place that is currently the one, and carries the
/// caller's own sentence for it. That sentence is announced through a live
/// region when it changes and is the accessible name of the matching row while
/// it holds. [onPlaceSelected] reports the place a user activated in the list;
/// what that does to the camera is the caller's.
///
/// **No row is tinted to show it is selected.** A fill would be the canonical
/// SC 1.4.1 failure — a state carried by colour alone — and this pattern has
/// no second signal to pair with it that would not be a word IUX composed.
/// The words carry it instead: the status line above the list is visible as
/// well as announced.
///
/// **Focus never moves.** Not when the selection changes, not when the list
/// rebuilds, not when a row is activated. Selecting a place in the list is a
/// user action and the user is already standing on the row they used; moving
/// them anywhere would be answering a question they did not ask. Selecting one
/// on the map is an action a screen-reader or keyboard user cannot perform at
/// all, so a focus move for it would land somebody somewhere in response to an
/// event they could not have caused. This is the eighth IUX pattern to decide
/// focus and the line is still IUX-033's — *did the user ask for this?* — so
/// there is no `IuxFocus.request` in this file, and a test asserts the
/// primary focus is unchanged across a selection change.
///
/// ## Known limitations
///
/// **A row does not announce that it is the selected one unless the list is
/// interactive.** The selected row's accessible name comes from
/// [IuxMapSelection.announcement], and a non-interactive row has nowhere to
/// put a name — `IuxListItem`'s plain form takes no `semanticLabel`, by
/// design. With [onPlaceSelected] null the status line is the only carrier.
///
/// **The rows are built eagerly.** This is `IuxListGroup`, so a list of two
/// hundred places builds two hundred rows. A round is a day's work — five to
/// forty stops — and forty is measured. A set of places large enough to need
/// recycling is not a round, and wants a `ListView.separated` the caller owns.
///
/// **Inside a scroll view, the map competes for the drag.** A platform map
/// view consumes vertical drags to pan, so a drag that starts on the map may
/// not scroll the page. Giving this widget a bounded height instead — the
/// usual arrangement, a screen body rather than a card in a feed — avoids it
/// entirely, because the list then scrolls inside its own region and the page
/// does not scroll at all.
///
/// **Nothing here can check that the markers match the rows.** IUX guarantees
/// that every place has a name and a non-colour ordinal, that both are on
/// screen and both are announced. Whether the marker for stop 3 is drawn where
/// stop 3 is, carries "3", meets 3:1 against the tiles behind it (SC 1.4.11)
/// and is large enough to hit is entirely the caller's — it is drawn by the
/// caller's map. The division is tabulated in `docs/patterns/place-map.md`.
///
/// **A live region is a request, not a guarantee.** Whether the platform
/// speaks the selection, and when, is the platform's decision; a widget test
/// can assert the node carries the flag and no more. Nothing essential depends
/// on it — the same words are on screen either way.
class IuxPlaceMap extends StatelessWidget {
  /// Creates a map region and the list that stands in for it.
  ///
  /// Not `const`, and deliberately. Two of the checks below walk [places],
  /// which Dart cannot evaluate inside a `const` constructor's assertion at
  /// all, and the alternative is deferring them to the first build — one frame
  /// later, at a stack that names this file rather than the call site that got
  /// it wrong. Nothing is lost: [map] is a live map widget and
  /// [onPlaceSelected] is a closure, so no call site could have written
  /// `const IuxPlaceMap(...)` anyway. This is the same division
  /// `IuxEmptyStateAction` makes, for the same reason.
  IuxPlaceMap({
    super.key,
    required this.places,
    required this.map,
    required this.zoom,
    required this.listLabel,
    this.selection,
    this.onPlaceSelected,
    this.placeActionHint,
  })  : assert(places.isNotEmpty, _kNoPlaces),
        assert(listLabel.length > 0, _kEmptyListLabel),
        assert(
          placeActionHint == null || placeActionHint.length > 0,
          _kEmptyHint,
        ),
        assert(
          placeActionHint == null || onPlaceSelected != null,
          _kHintWithoutTap,
        ),
        assert(_debugDistinctIds(places), _kDuplicateIds),
        assert(_debugSelectionExists(places, selection), _kUnknownSelection);

  /// The places, in the order the list reads them.
  ///
  /// Required and never empty. **This is the parameter that makes the map's
  /// text equivalent structural** rather than advisory: the rows are rendered
  /// from it and there is no way to ask for the map without them.
  ///
  /// The order is the order the user hears. Put it in whatever order the round
  /// is actually done in, and say so in [IuxPlace.ordinal] — a list ordered by
  /// something the user cannot see is a list they cannot navigate by.
  final List<IuxPlace> places;

  /// The map itself, which IUX neither builds nor understands.
  ///
  /// A `GoogleMap`, or any other widget: this package declares no map
  /// dependency and cannot, so whatever renders tiles arrives from here. It is
  /// given a bounded height and removed from the semantics tree — see the
  /// class documentation.
  final Widget map;

  /// Whether the map zooms, and if it does, how somebody zooms it without a
  /// pinch.
  ///
  /// Required and sealed: see [IuxMapZoom]. There is no default because both
  /// answers are claims about [map], and IUX cannot inspect it to find out
  /// which is true.
  final IuxMapZoom zoom;

  /// What the list is called, already localised.
  ///
  /// Published as a heading, which is how a screen-reader user reaches the
  /// list without swiping through everything above it, and what tells them
  /// what the rows are — "Visits on this round", "Collection points".
  ///
  /// Required, and never empty: see [_kEmptyListLabel].
  final String listLabel;

  /// Which place is currently the one, or null when none is.
  ///
  /// See [IuxMapSelection]. Nothing here changes it; the parent owns it, and a
  /// pattern that marked a place selected before the application accepted it
  /// would be showing a state that is not true yet.
  final IuxMapSelection? selection;

  /// Called with the place a user activated in the list.
  ///
  /// Null means the list is a reading list: the rows present places and none
  /// of them is a control, which is right for an overview the user is not
  /// meant to act on. Non-null makes every row a single named control.
  ///
  /// What activation does — centre the camera, open the visit, both — is the
  /// caller's. This pattern reports the request and renders what it is given
  /// next.
  final ValueChanged<IuxPlace>? onPlaceSelected;

  /// What activating a row does, already localised.
  ///
  /// Read after the row's name and role, so write it as an outcome — "centres
  /// the map on this visit" — not as an instruction to double-tap, which the
  /// screen reader already supplies. One hint for every row, because every row
  /// does the same thing.
  ///
  /// Refused without [onPlaceSelected]: see [_kHintWithoutTap].
  final String? placeActionHint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool bounded = constraints.hasBoundedHeight;
          final double? mapHeight = bounded
              ? _mapHeightWithin(constraints.maxHeight)
              : _kMinimumMapHeight;
          final IuxMapSelection? current = selection;
          final Widget list = _IuxPlaceList(
            places: places,
            listLabel: listLabel,
            selection: current,
            onPlaceSelected: onPlaceSelected,
            placeActionHint: placeActionHint,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: <Widget>[
              if (mapHeight != null) ...<Widget>[
                SizedBox(
                  height: mapHeight,
                  // Hidden from assistive technology, and licensed to be by
                  // the list below. See the class documentation.
                  child: IuxSemantics.decorative(child: map),
                ),
                if (zoom case final IuxZoomControls controls) ...<Widget>[
                  const IuxGap.tight(),
                  _IuxZoomControlBar(controls: controls),
                ],
                const IuxGap.standard(),
              ],
              if (current != null) ...<Widget>[
                _IuxSelectedPlaceStatus(announcement: current.announcement),
                const IuxGap.tight(),
              ],
              // Bounded: the list scrolls inside the space left over, so the
              // map stays put and every row is reachable. Unbounded: the
              // caller's scroll view already does it, and a second one here
              // would be the nested-scrolling defect IUX-028 records.
              if (bounded)
                Expanded(child: SingleChildScrollView(child: list))
              else
                list,
            ],
          );
        },
      );

  /// The height the map region takes, or null when it is not drawn.
  ///
  /// See "The map yields, the list never does" in the class documentation.
  static double? _mapHeightWithin(double available) {
    final double share = available * _kMapHeightShare;
    final double height =
        share < _kMaximumMapHeight ? share : _kMaximumMapHeight;
    return height < _kMinimumMapHeight ? null : height;
  }
}

/// The single-pointer, keyboard-reachable equivalent of a pinch.
///
/// Laid out with `IuxTargetSpacing`, which keeps the floor between the two
/// controls and wraps them onto a second line rather than clipping when the
/// text scale makes the row too wide.
class _IuxZoomControlBar extends StatelessWidget {
  const _IuxZoomControlBar({required this.controls});

  final IuxZoomControls controls;

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: IuxTargetSpacing(
          axis: Axis.horizontal,
          children: <Widget>[
            IuxIconButton(
              icon: Icons.add,
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(label: controls.zoomInLabel),
                role: IuxActionRole.navigate,
              ),
              onActivate: controls.onZoomIn,
            ),
            IuxIconButton(
              icon: Icons.remove,
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(label: controls.zoomOutLabel),
                role: IuxActionRole.navigate,
              ),
              onActivate: controls.onZoomOut,
            ),
          ],
        ),
      );
}

/// The words for a highlight that exists on the map as a colour.
///
/// Visible as well as announced: a sighted user needs to know which place the
/// map is showing them too, and a line of text is the one carrier that works
/// on a monochrome display, under an inverted palette and through a screen
/// reader at once.
class _IuxSelectedPlaceStatus extends StatelessWidget {
  const _IuxSelectedPlaceStatus({required this.announcement});

  final String announcement;

  @override
  Widget build(BuildContext context) {
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return IuxSemantics.liveRegion(
      label: announcement,
      // The label is on the region, so the text below it would otherwise be
      // announced a second time as a child node.
      child: ExcludeSemantics(
        child: Text(
          announcement,
          style: type.body.copyWith(color: colors.content.primary),
          // No line limit and no ellipsis. Half a sentence about which place
          // is selected is worse than none: the user cannot tell whether the
          // rest of it named the one they were looking for.
          softWrap: true,
        ),
      ),
    );
  }
}

/// The map's text equivalent: every place, named, ordered and findable.
class _IuxPlaceList extends StatelessWidget {
  const _IuxPlaceList({
    required this.places,
    required this.listLabel,
    required this.selection,
    required this.onPlaceSelected,
    required this.placeActionHint,
  });

  final List<IuxPlace> places;
  final String listLabel;
  final IuxMapSelection? selection;
  final ValueChanged<IuxPlace>? onPlaceSelected;
  final String? placeActionHint;

  @override
  Widget build(BuildContext context) => IuxSection(
        // Published as a heading, which is what makes the list something a
        // screen-reader user can jump to rather than arrive at.
        title: listLabel,
        children: <Widget>[
          IuxListGroup(
            children: <Widget>[
              for (final IuxPlace place in places) _row(place),
            ],
          ),
        ],
      );

  /// One place as one row.
  ///
  /// The ordinal leads, so a screen reader reads the position before the name
  /// and the two are one utterance rather than two fragments — `IuxListItem`
  /// merges its content for exactly this reason.
  Widget _row(IuxPlace place) {
    final ValueChanged<IuxPlace>? select = onPlaceSelected;
    final IuxMapSelection? current = selection;
    final Widget ordinal = _IuxPlaceOrdinal(ordinal: place.ordinal);

    if (select == null) {
      return IuxListItem(
        title: place.name,
        subtitle: place.detail,
        trailingText: place.distance,
        leading: ordinal,
      );
    }

    return IuxListItem.tappable(
      title: place.name,
      subtitle: place.detail,
      trailingText: place.distance,
      leading: ordinal,
      // Read before the row's own text, so the selected row names itself as
      // the current one in the caller's words. Null on every other row: a
      // second name where there is nothing extra to say would push the place's
      // own text one utterance further away.
      semanticLabel: current != null && current.placeId == place.id
          ? current.announcement
          : null,
      hint: placeActionHint,
      onActivate: () => select(place),
    );
  }
}

/// The non-colour token that ties a row to a marker.
///
/// Given a ceiling the width of a touch target — roughly the size of a marker
/// — so a long ordinal wraps inside its own box instead of taking the width
/// the place's name needs. That is the failure IUX-LISTITEM-TRAILING-001
/// recorded at the other end of the row: a non-flexible child of a `Row` takes
/// its full intrinsic width, and what grows all of them at once is the user's
/// text size.
class _IuxPlaceOrdinal extends StatelessWidget {
  const _IuxPlaceOrdinal({required this.ordinal});

  final String ordinal;

  @override
  Widget build(BuildContext context) {
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxAccessibility accessibility = IuxAccessibility.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: accessibility.minimumTouchTarget),
      child: Text(
        ordinal,
        style: type.label.copyWith(color: colors.content.primary),
        textAlign: TextAlign.center,
        softWrap: true,
      ),
    );
  }
}
