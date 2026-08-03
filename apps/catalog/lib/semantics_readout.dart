import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';

/// Shows a control together with what the semantics tree actually says about
/// it.
///
/// A button's accessible name, its hint and its enabled state are invisible.
/// They are also the half of a button most likely to be wrong, and the only
/// way to check them is normally to install TalkBack on a device. This reads
/// the node the framework built and prints it, so a maintainer can see the
/// announcement change as they change the descriptor.
///
/// It is not TalkBack. It reports the properties Flutter published, not the
/// sentence Android composes from them — word order, the word for "button" and
/// the treatment of a disabled control are the platform's, and they differ
/// between screen readers. What it does prove is which properties are set, and
/// that is where the defects are.
///
/// Turning it on forces the semantics tree to be built for the whole
/// application, exactly as an assistive service would. That is a deliberate
/// cost: a tree that only exists when someone is watching is a tree nobody
/// tests.
class SemanticsReadout extends StatefulWidget {
  /// Shows [child] and reports the semantics node it produced.
  const SemanticsReadout({super.key, required this.child});

  /// The control to probe.
  final Widget child;

  @override
  State<SemanticsReadout> createState() => _SemanticsReadoutState();
}

class _SemanticsReadoutState extends State<SemanticsReadout> {
  /// How many extra frames to ask for while the tree is still being built.
  ///
  /// Bounded, because each retry schedules another frame: an unbounded one
  /// would spin forever on a control that genuinely publishes no node.
  static const int _maxAttempts = 4;

  final GlobalKey _anchor = GlobalKey();
  SemanticsHandle? _handle;
  _Announced? _announced;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _handle = SemanticsBinding.instance.ensureSemantics();
  }

  @override
  void dispose() {
    _handle?.dispose();
    _handle = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());

    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final _Announced? announced = _announced;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        KeyedSubtree(key: _anchor, child: widget.child),
        SizedBox(height: geometry.spacingXs),
        if (announced == null)
          const CatalogNote(
            'No semantics node was published for this control. In a release '
            'build that is expected — the probe only works in debug and '
            'profile. In a debug build it means the control announces nothing.',
          )
        else
          CatalogRows(<(String, String)>[
            ('Name', announced.label.isEmpty ? '(none)' : announced.label),
            ('Hint', announced.hint.isEmpty ? '(none)' : announced.hint),
            ('Role', announced.isButton ? 'button' : '(not a button)'),
            ('Enabled', announced.enabled),
            ('Activatable', announced.hasTap ? 'yes' : 'no'),
          ]),
      ],
    );
  }

  void _read() {
    if (!mounted) return;

    final RenderObject? root = _anchor.currentContext?.findRenderObject();
    final SemanticsNode? node = root == null ? null : _firstNode(root);
    final _Announced? found =
        node == null ? null : _Announced.from(node.getSemanticsData());

    if (found == _announced) {
      // The tree may simply not have been built yet on this frame. Ask for a
      // few more, then stop: a control that publishes nothing is itself the
      // answer, and spinning on it would burn a frame forever.
      if (found == null && _attempts < _maxAttempts) {
        setState(() => _attempts++);
      }
      return;
    }

    setState(() {
      _announced = found;
      _attempts = 0;
    });
  }

  /// The first semantics node published beneath [root].
  ///
  /// Depth first, and it stops at the first node it finds: an IUX action is a
  /// semantics container that excludes its subtree, so the node that carries
  /// the announcement is the outermost one under the anchor.
  static SemanticsNode? _firstNode(RenderObject root) {
    final SemanticsNode? own = root.debugSemantics;
    if (own != null) return own;

    SemanticsNode? found;
    root.visitChildren((RenderObject child) {
      found ??= _firstNode(child);
    });
    return found;
  }
}

/// What the semantics tree published about one control.
@immutable
class _Announced {
  const _Announced({
    required this.label,
    required this.hint,
    required this.isButton,
    required this.enabled,
    required this.hasTap,
  });

  factory _Announced.from(SemanticsData data) => _Announced(
        label: data.label,
        hint: data.hint,
        isButton: data.flagsCollection.isButton,
        // Three values, not two. "not stated" is different from "stated as
        // disabled": a control with no enabled state at all is announced as an
        // ordinary one, which is how a busy control comes to sound available.
        enabled: switch (data.flagsCollection.isEnabled.toBoolOrNull()) {
          true => 'yes',
          false => 'no — announced as disabled',
          null => 'not stated',
        },
        hasTap: data.hasAction(SemanticsAction.tap),
      );

  final String label;
  final String hint;
  final bool isButton;
  final String enabled;
  final bool hasTap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Announced &&
          other.label == label &&
          other.hint == hint &&
          other.isButton == isButton &&
          other.enabled == enabled &&
          other.hasTap == hasTap;

  @override
  int get hashCode => Object.hash(label, hint, isButton, enabled, hasTap);
}
