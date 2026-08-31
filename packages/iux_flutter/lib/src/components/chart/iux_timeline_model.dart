import 'package:flutter/foundation.dart';

/// How a span is filled, which is the channel that survives when colour does
/// not.
///
/// The timeline is the first chart in this library that has to tell **four**
/// things apart, and the palette carries two — `primaryStroke` and
/// `secondaryStroke`, deliberately, because "a chart in which four things all
/// claim different weight has no subject". Rather than add colours whose
/// distinguishability would have to be proved under four theme profiles and
/// under dichromacy, the kinds are told apart by fill.
///
/// This is `IUX-GLYPH-SILHOUETTE-001`'s argument applied to an area instead of
/// a glyph: where the colour channel is weakest, the shape channel carries.
enum IuxSpanTexture {
  /// A filled band. The subject of the row.
  solid,

  /// Diagonal ruling over a light fill. Reads as filled at a glance and stays
  /// distinguishable close up.
  hatched,

  /// A sparse dot field. The least prominent, for the stretch that provides
  /// context rather than the one being examined.
  dotted,

  /// An outline with nothing inside. Reads as absence, which is what an
  /// unallocated stretch is.
  open,
}

/// One category of span, named and drawn distinctly.
@immutable
final class IuxSpanKind {
  /// Creates a kind labelled [label] and drawn as [texture].
  const IuxSpanKind({required this.label, required this.texture})
      : assert(
          label.length > 0,
          'A span kind must be named. The legend spells every kind out in '
          'words precisely so the drawing is never the only way to know what '
          'a band is.',
        );

  /// What this kind is called, already localised.
  ///
  /// Spelled out in the legend beside its own swatch. A legend that shows
  /// colours and expects the reader to match them is the failure SC 1.4.1
  /// names.
  final String label;

  /// How bands of this kind are filled.
  final IuxSpanTexture texture;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxSpanKind && other.label == label && other.texture == texture;

  @override
  int get hashCode => Object.hash(label, texture);

  @override
  String toString() => 'IuxSpanKind($label, ${texture.name})';
}

/// A stretch of the axis, as the caller holds it — possibly overlapping others.
@immutable
final class IuxSpan {
  /// Creates a span of [kind] running from [start] to [end].
  const IuxSpan({required this.kind, required this.start, required this.end})
      : assert(
          start < end,
          'A span ends after it starts. A zero-length or reversed span draws '
          'nothing and would be announced as a stretch that exists.',
        );

  /// What this stretch is.
  final IuxSpanKind kind;

  /// Where it begins, in the axis's own units.
  final double start;

  /// Where it ends, in the axis's own units.
  final double end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxSpan &&
          other.kind == kind &&
          other.start == start &&
          other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);

  @override
  String toString() => 'IuxSpan(${kind.label}, $start..$end)';
}

/// A stretch of the axis after overlaps have been settled.
///
/// Distinct from [IuxSpan] as a type, so a function that needs the settled
/// version cannot be handed the raw one by accident. That distinction is the
/// point of the whole model: **the drawing and the announcement must describe
/// the same bands**, and the only way to guarantee it is to make the resolved
/// form the only thing either of them can see.
@immutable
final class IuxResolvedSpan {
  /// Creates a settled band.
  const IuxResolvedSpan({
    required this.kind,
    required this.start,
    required this.end,
  });

  /// What this stretch is.
  final IuxSpanKind kind;

  /// Where it begins.
  final double start;

  /// Where it ends.
  final double end;

  /// How much of the axis it covers.
  double get length => end - start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxResolvedSpan &&
          other.kind == kind &&
          other.start == start &&
          other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);

  @override
  String toString() => 'IuxResolvedSpan(${kind.label}, $start..$end)';
}

/// One row of a timeline: a subject, and what happened to it across the axis.
@immutable
final class IuxTimelineRow {
  /// Creates a row named [label] holding [spans].
  const IuxTimelineRow({required this.label, required this.spans})
      : assert(
          label.length > 0,
          'A row must be named, or the reader has a band and no idea whose '
          'day it is.',
        );

  /// What this row is, already localised — a weekday, a person, a machine.
  final String label;

  /// The stretches on this row, in any order and possibly overlapping.
  ///
  /// Overlap is expected rather than tolerated. The sets an application holds
  /// genuinely do overlap — somebody can be on call during their working hours
  /// — and a component that demanded disjoint input would be pushing the hard
  /// part back to the caller, which is the half `systm-d/IUX#51` reported as
  /// getting silently wrong.
  final List<IuxSpan> spans;
}

/// Settles overlapping spans into disjoint bands, highest precedence winning.
///
/// **This is the function the component exists for.** Drawing a row of bands is
/// forty lines; deciding what is underneath when two stretches claim the same
/// minute is where a chart becomes subtly and silently incorrect — it renders,
/// it looks plausible, and it states something untrue.
///
/// [precedence] is the kinds in order, first winning. Order rather than a
/// number on each kind: a number invites two kinds to share one, and there is
/// no honest answer to a tie.
///
/// The axis is swept boundary by boundary. At every point, the surviving kind
/// is the earliest in [precedence] that covers it; adjacent points of the same
/// kind are joined, so the output holds no seam a reader could see and no
/// zero-length band a screen reader would announce.
///
/// Stretches of the axis that no span covers are simply absent from the result.
/// A gap is a gap; inventing an "unallocated" band would be the component
/// asserting something the caller never said.
List<IuxResolvedSpan> resolveSpans({
  required List<IuxSpan> spans,
  required List<IuxSpanKind> precedence,
}) {
  if (spans.isEmpty) return const <IuxResolvedSpan>[];

  // Every point at which the answer can change. Sorted and de-duplicated, so a
  // boundary shared by three spans is considered once.
  final Set<double> boundaries = <double>{};
  for (final IuxSpan span in spans) {
    boundaries.add(span.start);
    boundaries.add(span.end);
  }
  final List<double> edges = boundaries.toList()..sort();

  final List<IuxResolvedSpan> settled = <IuxResolvedSpan>[];

  for (int i = 0; i < edges.length - 1; i++) {
    final double from = edges[i];
    final double to = edges[i + 1];

    // Which kinds cover this slice. A span covers it when it starts at or
    // before the slice and ends at or after it — half-open, so a span ending
    // exactly where the slice begins does not claim it.
    IuxSpanKind? winner;
    int best = precedence.length;
    for (final IuxSpan span in spans) {
      if (span.start > from || span.end < to) continue;
      final int rank = precedence.indexOf(span.kind);
      // A kind absent from the precedence list cannot win against one that is
      // in it, and loses to nothing else either — an unranked kind is a caller
      // error the assertions in the widget catch, and this stays total.
      if (rank >= 0 && rank < best) {
        best = rank;
        winner = span.kind;
      }
    }
    if (winner == null) continue;

    // Joined to the previous band when it is the same kind and touches it, so
    // a stretch interrupted only by a boundary of some *other* span is one
    // band rather than two identical ones the reader would hear twice.
    if (settled.isNotEmpty &&
        settled.last.kind == winner &&
        settled.last.end == from) {
      final IuxResolvedSpan previous = settled.removeLast();
      settled.add(
        IuxResolvedSpan(kind: winner, start: previous.start, end: to),
      );
    } else {
      settled.add(IuxResolvedSpan(kind: winner, start: from, end: to));
    }
  }

  return settled;
}
