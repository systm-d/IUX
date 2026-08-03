import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  test('spacing scale is ordered', () {
    expect(IuxSpacing.xxs, lessThan(IuxSpacing.xs));
    expect(IuxSpacing.xs, lessThan(IuxSpacing.sm));
    expect(IuxSpacing.sm, lessThan(IuxSpacing.md));
    expect(IuxSpacing.md, lessThan(IuxSpacing.lg));
  });

  test('comfortable profile never reduces touch targets', () {
    const profile = IuxAccessibilityProfile(
      density: IuxDensity.compact,
      touchTarget: IuxTouchTargetPreference.comfortable,
    );
    expect(profile.minimumTouchTarget, IuxTouchTarget.comfortable);
    expect(profile.minimumTouchTarget,
        greaterThanOrEqualTo(IuxTouchTarget.minimum));
  });

  test('accessibility profile is copyable', () {
    const profile = IuxAccessibilityProfile();
    expect(profile.copyWith(contrast: IuxContrast.high).contrast,
        IuxContrast.high);
  });
}
