import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../layout/iux_section.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import 'iux_form_model.dart';

/// A named group of fields inside a form.
///
/// ```dart
/// IuxFormSection(
///   title: l10n.deliveryAddress,
///   fields: <IuxFormField>[street, postcode, city],
/// )
/// ```
///
/// **Use it** to break a form into groups a user can take one at a time. Five
/// questions under a heading are read as one task; fifteen questions in a
/// column are read as a wall, and the usual response to a wall is to abandon
/// it. The heading is also a screen-reader landmark, so the grouping exists for
/// someone who cannot see the space that expresses it.
///
/// **Do not use it** to group two fields that belong together on one line, and
/// do not create a section per field: a heading above a single question repeats
/// the question, and a screen-reader user then hears it twice before they can
/// answer it once.
///
/// **It takes [IuxFormField]s rather than widgets**, and that is the whole
/// reason it exists beside [IuxSection]. `IuxForm` reads the fields back out of
/// its sections to build the error summary, to find the node to send the user
/// to, and to know when to ask for a check. A section holding opaque widgets
/// could do none of that, and the summary would have to be assembled by hand
/// beside the form — which is how a summary comes to list a field the form no
/// longer contains.
///
/// Used outside an `IuxForm` it still lays fields out correctly, but nothing
/// asks for a check and nothing summarises a failure. It is a layout then, not
/// a pattern.
///
/// ## Spacing
///
/// Fields are separated by at least [kIuxMinimumTargetSpacing]. Two adjacent
/// targets that touch produce mis-taps however large each one is, because a
/// finger landing near the seam has no margin — and in a form the consequence
/// of a mis-tap is a caret in the wrong box and a value typed into the wrong
/// question.
///
/// ## What it does not do
///
/// It does not mark which fields are required. That mark belongs beside the
/// field's own label, inside the field widget, and IUX-012 does not own those
/// files — see `docs/patterns/guided-form.md` for what to do meanwhile. It also
/// does not scroll: the page owns scrolling, and a form that brought its own
/// scroll view would nest one inside the page's.
class IuxFormSection extends StatelessWidget {
  /// Creates a group of fields.
  const IuxFormSection({
    super.key,
    required this.fields,
    this.title,
    this.description,
  })  : assert(
          fields.length > 0,
          'A section with no fields is a heading over nothing. Stop rendering '
          'the section instead, so the user is not shown the name of a group '
          'that has no questions in it.',
        ),
        assert(
          title == null || title.length > 0,
          'An empty title reserves a line, announces a landmark and says '
          'nothing. Omit the parameter instead.',
        ),
        assert(
          description == null || description.length > 0,
          'Pass null rather than an empty description.',
        );

  /// The questions in this group, in the order they are asked.
  final List<IuxFormField> fields;

  /// The heading, already localised.
  ///
  /// Exposed as a header, so a screen-reader user can jump between groups
  /// instead of swiping through every field of the one they are in.
  final String? title;

  /// What the group is for, already localised.
  ///
  /// Use it for something that applies to every field below — why the address
  /// is needed, what happens to it. Anything that applies to one field is that
  /// field's `helpText`, where the user is looking when they answer it.
  final String? description;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    // The separation between two fields is the standard rhythm, but never less
    // than the target floor: a compact density may take the ordinary step below
    // it, and the floor is not the kind of thing a density preference is
    // allowed to spend.
    final double separation = math.max(
      geometry.spacingMd,
      kIuxMinimumTargetSpacing,
    );

    return IuxSection(
      title: title,
      description: description,
      children: <Widget>[
        // One child rather than one per field, so the section's own gap does
        // not decide the separation between two interactive elements.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < fields.length; i++) ...<Widget>[
              if (i > 0) SizedBox(height: separation),
              fields[i].child,
            ],
          ],
        ),
      ],
    );
  }
}
