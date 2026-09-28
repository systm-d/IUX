import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// Where the focus ring is actually painted, measured in pixels.
///
/// Three places in this package said the ring was drawn outside the element it
/// identifies — `IuxFocusRing`'s own documentation, `IuxFocusStyle.gap`
/// ("space between the element and its focus ring"), and a button test whose
/// failure message sends the reader to "IuxFocusRing, which reserves space
/// outside". None of them was checked against the paint. The ring decorated
/// the child's own box, so it was drawn *on* the child's edge, and the reserved
/// gap sat outside it instead.
///
/// A control hid that, because a control carries its own padding. A block of
/// text does not: the ring went through the first and last glyph of every line.
/// It was seen on a device, at 100% text, on `IuxOnboardingFlow`'s step heading
/// — which takes focus on every step change (IUX-FOCUS-RING-001).
///
/// These are captures compared against a rule, not goldens compared against a
/// file, so nothing can be blessed into agreeing with the defect. Under
/// `flutter_test` a glyph is a filled box, which makes "no ring pixel inside
/// the text" an exact statement rather than an estimate.
void main() {
  const Color content = Color(0xFFFF00FF);
  const Key target = Key('target');

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    IuxAccessibilityProfile profile = const IuxAccessibilityProfile(),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.light(profile: profile),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              child: IuxFocusRing(focused: true, child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<(Uint8List, int)> capture(WidgetTester tester) async {
    final RenderRepaintBoundary boundary =
        tester.renderObject<RenderRepaintBoundary>(
      find
          .ancestor(
            of: find.byType(IuxFocusRing),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );
    late ByteData? data;
    late int width;
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage();
      width = image.width;
      data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
    });
    return (data!.buffer.asUint8List(), width);
  }

  /// The ring's colour as the theme resolved it.
  Color ringColour(WidgetTester tester) =>
      IuxSemanticColors.of(tester.element(find.byType(IuxFocusRing)))
          .state
          .focus;

  /// The target's rectangle in the capture's own coordinates.
  Rect targetRect(WidgetTester tester) {
    final Rect boundary = tester.getRect(
      find
          .ancestor(
            of: find.byType(IuxFocusRing),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );
    return tester.getRect(find.byKey(target)).shift(-boundary.topLeft);
  }

  /// Every pixel painted exactly in [colour], as the centre of each pixel.
  ///
  /// Exact colour only: an anti-aliased edge pixel is a blend and is not
  /// counted, so what is found is ring the user would see as ring.
  List<Offset> pixelsOf(Uint8List pixels, int width, Color colour) {
    final int r = (colour.r * 255).round();
    final int g = (colour.g * 255).round();
    final int b = (colour.b * 255).round();
    final List<Offset> found = <Offset>[];
    for (int i = 0; i < pixels.length; i += 4) {
      if (pixels[i] == r && pixels[i + 1] == g && pixels[i + 2] == b) {
        final int index = i ~/ 4;
        found.add(
          Offset((index % width) + 0.5, (index ~/ width) + 0.5),
        );
      }
    }
    return found;
  }

  for (final (String name, IuxAccessibilityProfile profile)
      in <(String, IuxAccessibilityProfile)>[
    ('standard', const IuxAccessibilityProfile()),
    (
      'high contrast',
      const IuxAccessibilityProfile(contrast: IuxContrast.high),
    ),
  ]) {
    group('under $name contrast', () {
      testWidgets('the ring never lands on the content it identifies',
          (WidgetTester tester) async {
        await pump(
          tester,
          const ColoredBox(
            key: target,
            color: content,
            child: SizedBox(width: 120, height: 48),
          ),
          profile: profile,
        );
        final (Uint8List pixels, int width) = await capture(tester);
        final Rect child = targetRect(tester);
        final List<Offset> ring = pixelsOf(pixels, width, ringColour(tester));

        expect(ring, isNotEmpty, reason: 'the ring must actually be drawn');
        final List<Offset> onContent =
            ring.where((Offset p) => child.contains(p)).toList();
        expect(
          onContent,
          isEmpty,
          reason: '${onContent.length} ring pixels were painted inside the '
              'element the ring identifies',
        );
        // And the content itself survived: every one of its pixels is still
        // the content's colour, so nothing was drawn over any of it.
        expect(
          pixelsOf(pixels, width, content).length,
          (child.width * child.height).round(),
        );
      });

      testWidgets('the ring keeps the gap the theme promised, on its inside',
          (WidgetTester tester) async {
        await pump(
          tester,
          const ColoredBox(
            key: target,
            color: content,
            child: SizedBox(width: 120, height: 48),
          ),
          profile: profile,
        );
        final (Uint8List pixels, int width) = await capture(tester);
        final double gap = IuxGeometryTheme.of(
          tester.element(find.byType(IuxFocusRing)),
        ).focus.gap;
        // Everything within `gap` of the element: the element grown by the
        // gap, with corners of radius `gap`. A sharp inflated rectangle would
        // claim its own corners are within the gap, and they are not.
        final RRect band = RRect.fromRectAndRadius(
          targetRect(tester).inflate(gap),
          Radius.circular(gap),
        );
        final List<Offset> tooClose =
            pixelsOf(pixels, width, ringColour(tester))
                .where((Offset p) => band.contains(p))
                .toList();

        expect(
          tooClose,
          isEmpty,
          reason: '`IuxFocusStyle.gap` is documented as the space between the '
              'element and its ring. ${tooClose.length} ring pixels sit '
              'inside it.',
        );
      });
    });
  }

  testWidgets('a focused block of text is not struck through at 100%',
      (WidgetTester tester) async {
    // The reported case, reduced to its shape: a heading and a sentence with
    // no padding of their own, which is what IuxOnboardingFlow's step heading
    // is, and what any pattern that focuses text rather than a control is.
    await pump(
      tester,
      const Column(
        key: target,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('The permission, and why now',
              style: TextStyle(color: content, fontSize: 20)),
          Text('Asked once, when it is needed',
              style: TextStyle(color: content, fontSize: 14)),
        ],
      ),
    );
    final (Uint8List pixels, int width) = await capture(tester);
    final Rect text = targetRect(tester);
    final List<Offset> ring = pixelsOf(pixels, width, ringColour(tester));

    expect(ring, isNotEmpty);
    expect(
      ring.where((Offset p) => text.contains(p)),
      isEmpty,
      reason: 'the ring was drawn through the glyphs',
    );
  });

  testWidgets('moving the ring out spent no space',
      (WidgetTester tester) async {
    // The fix is a relocation inside a reservation that already existed, so
    // the element's position must not depend on whether the ring is drawn —
    // the property the reservation was made for in the first place.
    Future<Rect> placed({required bool focused}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: Scaffold(
            body: Center(
              child: IuxFocusRing(
                focused: focused,
                child: const SizedBox(key: target, width: 40, height: 40),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.byKey(target));
    }

    expect(await placed(focused: true), await placed(focused: false));

    final IuxFocusStyle focus = IuxGeometryTheme.of(
      tester.element(find.byType(IuxFocusRing)),
    ).focus;
    final double reserved = 2 * (focus.width + focus.gap);
    expect(
      tester.getSize(find.byType(IuxFocusRing)),
      Size(40 + reserved, 40 + reserved),
      reason: 'the ring reserves exactly its width and its gap on each side, '
          'no more',
    );
  });
}
