import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  const IuxSpanKind work = IuxSpanKind(
    label: 'Declared work',
    texture: IuxSpanTexture.solid,
  );
  const IuxSpanKind onCall = IuxSpanKind(
    label: 'On call',
    texture: IuxSpanTexture.hatched,
  );
  const IuxSpanKind rest = IuxSpanKind(
    label: 'Statutory rest',
    texture: IuxSpanTexture.dotted,
  );

  // Work beats on-call beats rest: if somebody is working while on call, the
  // hour is worked.
  const List<IuxSpanKind> order = <IuxSpanKind>[work, onCall, rest];

  List<IuxResolvedSpan> settle(List<IuxSpan> spans) =>
      resolveSpans(spans: spans, precedence: order);

  ({double start, double end, String kind}) shape(IuxResolvedSpan s) =>
      (start: s.start, end: s.end, kind: s.kind.label);

  group('spans that do not fight are left alone', () {
    test('nothing in, nothing out', () {
      expect(settle(const <IuxSpan>[]), isEmpty);
    });

    test('two disjoint stretches stay two', () {
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: work, start: 9, end: 17),
        IuxSpan(kind: rest, start: 17, end: 28),
      ]);
      expect(out.map(shape), <Object>[
        (start: 9.0, end: 17.0, kind: 'Declared work'),
        (start: 17.0, end: 28.0, kind: 'Statutory rest'),
      ]);
    });

    test('a gap stays a gap, and nothing is invented to fill it', () {
      // Inventing an "unallocated" band would be the component asserting
      // something the caller never said.
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: work, start: 9, end: 12),
        IuxSpan(kind: rest, start: 14, end: 16),
      ]);
      expect(out.map(shape), <Object>[
        (start: 9.0, end: 12.0, kind: 'Declared work'),
        (start: 14.0, end: 16.0, kind: 'Statutory rest'),
      ]);
    });
  });

  group('when two stretches claim the same minute, precedence settles it', () {
    test('a full overlap leaves the winner alone', () {
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: onCall, start: 9, end: 17),
        IuxSpan(kind: work, start: 9, end: 17),
      ]);
      expect(out.map(shape), <Object>[
        (start: 9.0, end: 17.0, kind: 'Declared work'),
      ]);
    });

    test('a partial overlap splits at the boundary', () {
      // The case the report describes: on call from 08:00, working from 09:00.
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: onCall, start: 8, end: 12),
        IuxSpan(kind: work, start: 9, end: 17),
      ]);
      expect(out.map(shape), <Object>[
        (start: 8.0, end: 9.0, kind: 'On call'),
        (start: 9.0, end: 17.0, kind: 'Declared work'),
      ]);
    });

    test('a span nested inside another cuts it in three', () {
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: onCall, start: 8, end: 20),
        IuxSpan(kind: work, start: 12, end: 14),
      ]);
      expect(out.map(shape), <Object>[
        (start: 8.0, end: 12.0, kind: 'On call'),
        (start: 12.0, end: 14.0, kind: 'Declared work'),
        (start: 14.0, end: 20.0, kind: 'On call'),
      ]);
    });

    test('three claims on one minute, and the order decides', () {
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: rest, start: 0, end: 24),
        IuxSpan(kind: onCall, start: 6, end: 18),
        IuxSpan(kind: work, start: 9, end: 17),
      ]);
      expect(out.map(shape), <Object>[
        (start: 0.0, end: 6.0, kind: 'Statutory rest'),
        (start: 6.0, end: 9.0, kind: 'On call'),
        (start: 9.0, end: 17.0, kind: 'Declared work'),
        (start: 17.0, end: 18.0, kind: 'On call'),
        (start: 18.0, end: 24.0, kind: 'Statutory rest'),
      ]);
    });

    test('the order is the answer, not the list order of the spans', () {
      // The same two stretches, handed over the other way round.
      final List<IuxResolvedSpan> a = settle(const <IuxSpan>[
        IuxSpan(kind: work, start: 9, end: 17),
        IuxSpan(kind: onCall, start: 9, end: 17),
      ]);
      final List<IuxResolvedSpan> b = settle(const <IuxSpan>[
        IuxSpan(kind: onCall, start: 9, end: 17),
        IuxSpan(kind: work, start: 9, end: 17),
      ]);
      expect(a.map(shape), b.map(shape));
    });
  });

  group('the output holds no seam a reader could see or hear', () {
    test('two touching stretches of one kind become one band', () {
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: work, start: 9, end: 12),
        IuxSpan(kind: work, start: 12, end: 17),
      ]);
      expect(out.map(shape), <Object>[
        (start: 9.0, end: 17.0, kind: 'Declared work'),
      ]);
    });

    test('two overlapping stretches of one kind become one band', () {
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: work, start: 9, end: 14),
        IuxSpan(kind: work, start: 12, end: 17),
      ]);
      expect(out.map(shape), <Object>[
        (start: 9.0, end: 17.0, kind: 'Declared work'),
      ]);
    });

    test('a band cut by an unrelated boundary is still one band', () {
      // The rest stretch is interrupted only by where on-call happens to end,
      // and the reader must not hear "rest, rest".
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: rest, start: 0, end: 10),
        IuxSpan(kind: onCall, start: 3, end: 5),
      ]);
      expect(out.map(shape), <Object>[
        (start: 0.0, end: 3.0, kind: 'Statutory rest'),
        (start: 3.0, end: 5.0, kind: 'On call'),
        (start: 5.0, end: 10.0, kind: 'Statutory rest'),
      ]);
    });

    test('no band has zero length', () {
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: work, start: 9, end: 17),
        IuxSpan(kind: onCall, start: 17, end: 20),
        IuxSpan(kind: rest, start: 20, end: 24),
      ]);
      for (final IuxResolvedSpan band in out) {
        expect(band.length, greaterThan(0));
      }
    });

    test('the bands never overlap, which is the whole promise', () {
      final List<IuxResolvedSpan> out = settle(const <IuxSpan>[
        IuxSpan(kind: rest, start: 0, end: 24),
        IuxSpan(kind: onCall, start: 6, end: 18),
        IuxSpan(kind: work, start: 9, end: 17),
        IuxSpan(kind: work, start: 19, end: 21),
      ]);
      for (int i = 0; i < out.length - 1; i++) {
        expect(out[i].end, lessThanOrEqualTo(out[i + 1].start));
      }
    });
  });

  group('it refuses what it cannot draw honestly', () {
    test('a span that ends before it starts', () {
      expect(
        () => IuxSpan(kind: work, start: 17, end: 9),
        throwsAssertionError,
      );
    });

    test('a span of no length', () {
      expect(
        () => IuxSpan(kind: work, start: 9, end: 9),
        throwsAssertionError,
      );
    });

    test('an unnamed kind', () {
      expect(
        () => IuxSpanKind(label: '', texture: IuxSpanTexture.solid),
        throwsAssertionError,
      );
    });

    test('an unnamed row', () {
      expect(
        () => IuxTimelineRow(label: '', spans: const <IuxSpan>[]),
        throwsAssertionError,
      );
    });
  });
}
