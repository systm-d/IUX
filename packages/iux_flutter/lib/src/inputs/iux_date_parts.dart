import 'package:flutter/foundation.dart';

/// A date as the user is entering it: three parts, any of which may be missing.
///
/// **Not a `DateTime`, and the difference is the whole reason this exists.** A
/// user filling in a date has typed a day and not yet a year, or a month that
/// is 13 because they are still typing. `DateTime?` cannot hold either: it is
/// null or it is a complete, valid instant, so a field built on it has to
/// invent a private half-state the parent cannot see or validate.
///
/// It also carries no time and no zone. A `DateTime` used as a date is a date
/// that moves when the device crosses a boundary, which is a defect that
/// surfaces once a year in the field and never in a test.
///
/// The parent owns validity, as it owns every other kind. [date] is offered so
/// the common check is one line; what a bad date *means* stays the caller's.
@immutable
final class IuxDateParts {
  /// Creates a date from the parts the user has entered.
  const IuxDateParts({this.day, this.month, this.year});

  /// The empty date, before the user has typed anything.
  const IuxDateParts.empty()
      : day = null,
        month = null,
        year = null;

  /// The day of the month, or null while it is unanswered.
  ///
  /// Not range-checked here. A field that silently refused 32 would be
  /// deciding, mid-keystroke, that the user meant something else.
  final int? day;

  /// The month, 1 to 12, or null while it is unanswered.
  final int? month;

  /// The year, as typed, or null while it is unanswered.
  final int? year;

  /// Whether all three parts have been answered.
  ///
  /// True says nothing about whether they make a real date: 31 February is
  /// complete and wrong.
  bool get isComplete => day != null && month != null && year != null;

  /// Whether nothing has been entered at all.
  bool get isEmpty => day == null && month == null && year == null;

  /// The date these parts name, or null when they are incomplete or unreal.
  ///
  /// Unreal is checked by round-trip rather than by a calendar table: Dart
  /// rolls 31 February over into March, so a constructed date that disagrees
  /// with the parts it was built from is one the user did not name.
  DateTime? get date {
    if (!isComplete) return null;
    final DateTime candidate = DateTime(year!, month!, day!);
    if (candidate.year != year || candidate.month != month) return null;
    if (candidate.day != day) return null;
    return candidate;
  }

  /// Returns a copy with the given parts replaced.
  ///
  /// A part is cleared by passing [clearDay], [clearMonth] or [clearYear],
  /// because a null argument cannot mean both "leave it" and "empty it".
  IuxDateParts copyWith({
    int? day,
    int? month,
    int? year,
    bool clearDay = false,
    bool clearMonth = false,
    bool clearYear = false,
  }) =>
      IuxDateParts(
        day: clearDay ? null : (day ?? this.day),
        month: clearMonth ? null : (month ?? this.month),
        year: clearYear ? null : (year ?? this.year),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxDateParts &&
          other.day == day &&
          other.month == month &&
          other.year == year;

  @override
  int get hashCode => Object.hash(day, month, year);

  @override
  String toString() => 'IuxDateParts($day/$month/$year)';
}

/// What the three parts of a date field are called, already localised.
///
/// A separate object rather than three parameters, so a caller cannot supply
/// two of the three — which would leave one part announced as "edit box" and
/// nothing else, the exact failure every field in this library refuses.
@immutable
final class IuxDateFieldLabels {
  /// Creates the three names, already localised.
  const IuxDateFieldLabels({
    required this.day,
    required this.month,
    required this.year,
  })  : assert(day.length > 0, 'The day part must be named.'),
        assert(month.length > 0, 'The month part must be named.'),
        assert(year.length > 0, 'The year part must be named.');

  /// What the day box is called.
  final String day;

  /// What the month box is called.
  final String month;

  /// What the year box is called.
  final String year;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxDateFieldLabels &&
          other.day == day &&
          other.month == month &&
          other.year == year;

  @override
  int get hashCode => Object.hash(day, month, year);
}
