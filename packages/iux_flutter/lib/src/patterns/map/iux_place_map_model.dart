import 'package:flutter/foundation.dart';

/// Why a place with no identity is refused.
const String _kEmptyPlaceId =
    'A place needs an identifier so a selection can point at it. It is never '
    'shown and never spoken, so it is not a string to translate — use '
    'whatever your own model already calls this place: a work order number, a '
    'database key, a URL.';

/// Why a place with no ordinal is refused.
const String _kEmptyOrdinal =
    'A place must carry the short token that identifies it on the map. This '
    'is the one thing IUX can contribute to WCAG 2.2 SC 1.4.1 for a marker it '
    'does not draw: every place has a label — "1", "3", "A", "09:00" — that '
    'is not a colour, the list shows it beside the name, and you paint the '
    'same one on the marker. Two markers differing only in hue are two '
    'markers a user with a colour vision deficiency cannot tell apart, and no '
    'amount of list helps them point at the right one on screen.';

/// Why a place with no name is refused.
const String _kEmptyPlaceName =
    'A place must be named, already localised. The name is what a user reads '
    'in the list instead of looking at the map, so a place without one is a '
    'row saying a number and nothing else — which is the state a map already '
    'leaves a screen-reader user in. Name the site, the customer, the address '
    'the round is organised by.';

/// Why an empty supporting line is refused rather than ignored.
const String _kEmptyDetail =
    'An empty detail reserves a line and says nothing. Pass null, or pass the '
    'localised sentence that makes this place findable — the street, the '
    'floor, the gate code, the appointment window.';

/// Why an empty distance is refused rather than ignored.
const String _kEmptyDistance =
    'An empty distance reserves space for a figure that never arrives. Pass '
    'null, or pass the value already formatted and localised — "1.2 km", '
    '"0.7 mi". IUX holds no units, no rounding rule and no decimal separator, '
    'because all three differ by locale and none is a framework decision.';

/// Why an unlabelled zoom control is refused.
const String _kEmptyZoomLabel =
    'A zoom control must be named, already localised. It is an icon with no '
    'text of its own, so unnamed it is announced as "button" — and it is the '
    'control that exists specifically for the user who cannot perform the '
    'pinch gesture, which is very often the user reading the screen with a '
    'screen reader.';

/// Why a selection pointing at nothing is refused.
const String _kEmptySelectionId =
    'A selection must name the place it selects. An empty identifier matches '
    'no place, so the pattern would announce a change and highlight nothing.';

/// Why a selection with no wording is refused.
const String _kEmptySelectionAnnouncement =
    'A selection must say, in words, which place is now the current one. It '
    'is the only account a screen-reader user gets of a highlight that exists '
    'on the map as a change of colour and nothing else, so silence here means '
    'the selection did not happen as far as they can tell. Pass the localised '
    'sentence — "Stop 3 of 8, 18 Mill Lane, selected".';

/// One place on the map, and the row in the list that stands in for it.
///
/// ```dart
/// IuxPlace(
///   id: visit.reference,
///   ordinal: l10n.stopNumber(visit.position),   // '3'
///   name: visit.site,                           // 'Renshaw & Co, Depot 4'
///   detail: l10n.addressLine(visit.address),    // '18 Mill Lane, Salford'
///   distance: l10n.distance(visit.metres),      // '1.2 km'
/// )
/// ```
///
/// **Every field except [id] is text the user reads, and every one arrives
/// already formatted and localised.** IUX composes none of it: no ordinal
/// suffix, no unit, no separator, no "stop 3 of 8". Those differ by language
/// and by measurement system, and a framework that guessed would ship the
/// guess untranslated into every application built on it — the defect recorded
/// as IUX-A11Y-008, which is why
/// `test/accessibility/no_composed_strings_test.dart` exists.
///
/// ## Why there are no coordinates here
///
/// A latitude and a longitude would be the obvious fields and they are
/// deliberately absent. This package draws no map, so it has nothing to do
/// with a coordinate except hold it, and a field nothing reads is the dead API
/// `PROJECT_PROMPT.md` §19 forbids. The map handed to [IuxPlace]'s pattern is
/// built from your own model, where the coordinates already live; [id] is what
/// ties a marker back to a row.
///
/// ## What [ordinal] is for
///
/// It is the non-colour identity of the marker. The pattern guarantees that
/// every place has one, that it is not empty, that it is drawn beside the name
/// and that a screen reader reads it before the name. What IUX cannot do is
/// draw it on the marker, because it does not draw the marker.
///
/// It does not have to be a number. "A", "B", "C" work, and so does a time —
/// "09:00" — for a round organised by appointment rather than by sequence.
/// What it must be is short, distinct within the list, and the same string you
/// paint on the marker.
@immutable
final class IuxPlace {
  /// Creates one place.
  const IuxPlace({
    required this.id,
    required this.ordinal,
    required this.name,
    this.detail,
    this.distance,
  })  : assert(id.length > 0, _kEmptyPlaceId),
        assert(ordinal.length > 0, _kEmptyOrdinal),
        assert(name.length > 0, _kEmptyPlaceName),
        assert(detail == null || detail.length > 0, _kEmptyDetail),
        assert(distance == null || distance.length > 0, _kEmptyDistance);

  /// What this place is called in your own model. Never shown, never spoken.
  ///
  /// It has to be unique within one map; a duplicate is refused in debug
  /// builds, because a selection naming an identifier that appears twice
  /// highlights whichever row happened to be built first.
  final String id;

  /// The short token identifying this place on the map, already localised.
  ///
  /// See the note on ordinals in the class documentation. Required, and never
  /// empty.
  final String ordinal;

  /// What this place is called, already localised.
  ///
  /// The row's title, and the first thing after [ordinal] a screen reader
  /// reads. Name the place the way a user would say it out loud, which is
  /// usually the site or the customer rather than a reference they can already
  /// see elsewhere.
  final String name;

  /// What makes this place findable, already localised.
  ///
  /// The supporting line: an address, a floor, an entrance, a time window.
  /// Optional, because some rounds genuinely have nothing to add — but a place
  /// on a map with no address is a place the user cannot reach without the
  /// map, which is the situation this pattern exists to fix.
  final String? detail;

  /// How far away this place is, already formatted and localised.
  ///
  /// Laid out at the end of the row. Optional: a round driven in a fixed
  /// sequence does not need it, and a distance from a location the application
  /// is not permitted to read cannot be computed at all.
  final String? distance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxPlace &&
          other.id == id &&
          other.ordinal == ordinal &&
          other.name == name &&
          other.detail == detail &&
          other.distance == distance;

  @override
  int get hashCode => Object.hash(id, ordinal, name, detail, distance);

  @override
  String toString() => 'IuxPlace($id, $ordinal, $name)';
}

/// Whether the map zooms, and if it does, how somebody zooms it without a
/// pinch.
///
/// **A pinch is a multipoint gesture, and WCAG 2.2 SC 2.5.1 (Pointer Gestures,
/// level A) requires that anything operated by one can also be operated with a
/// single pointer.** SC 2.1.1 (Keyboard, level A) requires the same
/// functionality from a keyboard, and a keyboard cannot pinch at all. A map
/// whose only zoom is a pinch is therefore not usable by a switch user, by a
/// head pointer, by anyone using one hand while holding a ladder, or by anyone
/// on a keyboard.
///
/// So this type is required and it is sealed, for the reason `IuxWayBack` is:
/// there are exactly two honest answers, and neither of them is silence.
///
/// | Answer | What it claims |
/// | --- | --- |
/// | [IuxZoomControls] | the map zooms, and here is the route that is not a gesture |
/// | [IuxZoomFixed] | the map does not zoom, so there is no gesture to replace |
///
/// There is no third member and no default. A default would be one of these
/// two claims made on the caller's behalf about a widget IUX cannot inspect —
/// and the direction it would be wrong in is the expensive one: a map left
/// zoomable with no controls looks finished and is unusable, whereas a map
/// declared fixed that is in fact zoomable at least still has a list.
///
/// **What IUX cannot check.** Whether the map you pass in actually zoom on a
/// pinch is a property of that widget, not of this one. Declaring
/// [IuxZoomFixed] while leaving `zoomGesturesEnabled` on is a claim IUX has no
/// way to verify and no way to detect. It is recorded here as a limitation
/// rather than hidden: the type makes the decision explicit and reviewable,
/// which is all a package that touches no platform can do.
@immutable
sealed class IuxMapZoom {
  /// Creates a zoom answer.
  const IuxMapZoom();

  /// The map zooms, and these controls do it without a gesture. See
  /// [IuxZoomControls].
  const factory IuxMapZoom.controls({
    required String zoomInLabel,
    required String zoomOutLabel,
    required VoidCallback onZoomIn,
    required VoidCallback onZoomOut,
  }) = IuxZoomControls;

  /// The map does not zoom at all. See [IuxZoomFixed].
  const factory IuxMapZoom.fixed() = IuxZoomFixed;

  /// Whether the pattern draws a pair of controls for this answer.
  ///
  /// A property of the type rather than a parameter, so no call site can ask
  /// for a zoomable map with the controls turned off.
  bool get hasControls => this is IuxZoomControls;
}

/// The map zooms, and here is the single-pointer, keyboard-reachable way to do
/// it.
///
/// ```dart
/// IuxZoomControls(
///   zoomInLabel: l10n.zoomIn,
///   zoomOutLabel: l10n.zoomOut,
///   onZoomIn: controller.zoomIn,
///   onZoomOut: controller.zoomOut,
/// )
/// ```
///
/// Both callbacks are required and neither is nullable, so there is no state
/// in which one direction of the equivalent exists and the other does not — a
/// user who can zoom in and cannot zoom out is a user trapped at whatever
/// scale their last tap produced.
///
/// **What actually moves the camera is yours.** The controls report that the
/// user asked; the map controller does the work. IUX has no camera, no zoom
/// level and no maximum, which is also why neither control is ever disabled
/// here: the pattern cannot know that the map is already as close as it goes,
/// and a control greyed out for a reason it cannot state is the silent refusal
/// `IuxFormSubmit` refuses to ship. A tap at the limit reaches your controller
/// and does nothing, which is what the pinch does too.
@immutable
final class IuxZoomControls extends IuxMapZoom {
  /// Creates the pair of controls.
  const IuxZoomControls({
    required this.zoomInLabel,
    required this.zoomOutLabel,
    required this.onZoomIn,
    required this.onZoomOut,
  })  : assert(zoomInLabel.length > 0, _kEmptyZoomLabel),
        assert(zoomOutLabel.length > 0, _kEmptyZoomLabel);

  /// The accessible name of the control that moves the camera closer, already
  /// localised.
  ///
  /// The control is a glyph with no text, so this is its whole name. Name the
  /// outcome — "Zoom in", "Show more detail" — not the glyph.
  final String zoomInLabel;

  /// The accessible name of the control that moves the camera away, already
  /// localised.
  final String zoomOutLabel;

  /// Called once per accepted activation of the closer control.
  final VoidCallback onZoomIn;

  /// Called once per accepted activation of the further control.
  final VoidCallback onZoomOut;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxZoomControls &&
          other.zoomInLabel == zoomInLabel &&
          other.zoomOutLabel == zoomOutLabel &&
          other.onZoomIn == onZoomIn &&
          other.onZoomOut == onZoomOut;

  @override
  int get hashCode =>
      Object.hash(zoomInLabel, zoomOutLabel, onZoomIn, onZoomOut);

  @override
  String toString() => 'IuxZoomControls($zoomInLabel, $zoomOutLabel)';
}

/// The map does not zoom, so there is no gesture to provide an equivalent for.
///
/// ```dart
/// zoom: const IuxZoomFixed(),
/// ```
///
/// A legitimate answer, and a narrow one. It fits a fixed overview — the whole
/// round at a scale chosen by the application, with no camera the user can
/// move. It does not fit "we have not built the controls yet": a map that
/// responds to a pinch and declares this is a map with an unmet SC 2.5.1
/// obligation and a type saying otherwise.
///
/// Naming it is a claim, in the same way [IuxNoWayBack] is a claim. The
/// difference is that IUX can verify neither, so both exist to make the
/// decision visible at the call site where somebody reviewing the screen will
/// read it.
@immutable
final class IuxZoomFixed extends IuxMapZoom {
  /// Creates the claim that the map does not zoom.
  const IuxZoomFixed();

  @override
  bool operator ==(Object other) => other is IuxZoomFixed;

  @override
  int get hashCode => (IuxZoomFixed).hashCode;

  @override
  String toString() => 'IuxZoomFixed()';
}

/// Which place is currently the one, and what a screen reader is told about it.
///
/// ```dart
/// IuxMapSelection(
///   placeId: visit.reference,
///   announcement: l10n.stopSelected(visit.position, visit.site),
///   // 'Stop 3 of 8, Renshaw & Co, selected'
/// )
/// ```
///
/// **A highlight on a map is a change of colour and nothing else.** For the
/// user who cannot see it, this sentence is the entire event. It is announced
/// through a live region when it changes, and it is the accessible name of the
/// matching row for as long as it holds — so a user sweeping the list also
/// lands on the one row that says it is the current one, rather than having to
/// remember what they heard a moment ago.
///
/// Because it does both jobs, **write it as a name rather than as an event.**
/// "Stop 3 of 8, Renshaw & Co, selected" reads correctly when it is announced
/// and when it is the row's name. "You have just selected stop 3" reads
/// correctly in neither.
///
/// **The word for "selected" is yours.** IUX cannot supply it: the framework
/// holds roles and never words, and a hard-coded "selected" would be English
/// in every application built on this. This is the string cost the pattern
/// documents rather than hides — see `docs/patterns/place-map.md`.
///
/// **Nothing here changes the selection.** The pattern reports which place the
/// user asked for and renders what it is given. A widget that marked itself
/// selected would be showing a state the application has not accepted, which
/// is the same position `IuxListItem.selectable` takes for the same reason.
@immutable
final class IuxMapSelection {
  /// Creates the current selection.
  const IuxMapSelection({required this.placeId, required this.announcement})
      : assert(placeId.length > 0, _kEmptySelectionId),
        assert(announcement.length > 0, _kEmptySelectionAnnouncement);

  /// The [IuxPlace.id] of the selected place.
  ///
  /// Must match a place in the list it is given to; an identifier matching
  /// nothing is refused in debug builds, because it would announce a selection
  /// the user cannot then find.
  final String placeId;

  /// What a screen reader is told, already localised.
  ///
  /// One sentence naming the place and the fact that it is the current one.
  /// See the class documentation for why it has to read as a name.
  final String announcement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxMapSelection &&
          other.placeId == placeId &&
          other.announcement == announcement;

  @override
  int get hashCode => Object.hash(placeId, announcement);

  @override
  String toString() => 'IuxMapSelection($placeId)';
}
