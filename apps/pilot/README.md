# Rounds — the IUX pilot application

A small application built entirely on IUX, to find out what building on IUX is
like.

```bash
cd apps/pilot
flutter run                 # Android is the platform priority
flutter test
flutter build apk --debug
```

## What it is for, and how it differs from the catalog

`apps/catalog` puts one component at a time under the conditions most likely to
break it. This does the opposite test: it builds a thing that would function,
end to end, and reports what that cost.

The deliverable is not the application. It is the friction — every place the
framework had to be worked around, with the code that proves it. Those places
are documented where they happen, in the file that had to work around them, and
pinned in `test/framework_defects_test.dart` as tests that assert the *current,
wrong* behaviour so the day it is fixed one of them fails.

## What the application does

A round of field service visits.

| Screen | What it exercises |
| --- | --- |
| Visits | `IuxLoadingRetry` across wait, failure and content; `IuxEmptyState` for both an empty round and a filtered-to-nothing one; `IuxSearchField`; `IuxListGroup` and `IuxListItem.tappable`; `IuxErrorRecovery` through `IuxRetryRoute` |
| New visit | `IuxForm`, `IuxFormSection`, `IuxFormField`, `IuxValidationSummary`, `IuxTextField`, `IuxRadioGroup`, `IuxSwitch`, blur-then-submit validation |
| Visit detail | `IuxAsyncActionButton` with a real operation and a feedback event; `IuxDestructiveFlow` with an `IuxUndoOffer`; `IuxCard`; `IuxStatusIndicator`; `IuxAppBarLeading.back` |
| Settings | `IuxSwitch` driving the live `IuxThemeConfiguration`; `IuxPermissionRationale` across all three moments; `IuxProgressiveDisclosure`; `IuxAlert`; `IuxDestructiveFlow` with `IuxNoWayBack` and a confirmation |
| Everywhere | `IuxAdaptiveNavigation`, `IuxAppBar`, `IuxPage`, `IuxSection`, `IuxModalLayer`, `IuxTransientLayer`, `IuxFeedbackScope`, `IuxBadge` |

The round lives in memory and is lost when the application closes. There is no
network and no storage: they would prove nothing about the framework.

## Where the findings are

| Finding | Where it is written down |
| --- | --- |
| `IuxAppBar` + `IuxPage`: double top inset, chrome that does not fit at 300%, no intrinsic height | `lib/screen_frame.dart` |
| `IuxSearchResults` cannot be placed on an `IuxPage`, and has one empty branch where a list needs two | `lib/jobs_screen.dart` |
| `IuxListItem` + `IuxStatusIndicator` overflows at 200% | `lib/jobs_screen.dart` |
| `IuxTransientLayer` covers the bottom navigation | `lib/main.dart`, pinned by `test/transient_overlap_test.dart` |
| `IuxDialog` does not answer the Android back button | `lib/main.dart` |
| `IuxDestructiveFlowController` must be re-synced imperatively, and emits no feedback | `lib/main.dart` |
| `expand: true` inside `IuxTargetSpacing` throws | `lib/job_detail_screen.dart` |
| Every route needs its own modal and transient layers | `lib/job_detail_screen.dart` |
| Five pieces of caller state per form field | `lib/new_job_screen.dart` |
| What composing no user-facing text costs | `lib/strings.dart` |

## Tests

| File | What it proves |
| --- | --- |
| `pilot_test.dart` | The flows work: add, list, search, open, complete, remove, undo, clear, refuse, recover |
| `scaling_test.dart` | Every screen lays out at 100%, 150%, 200% and 300% on a 320x640 window, and right-to-left |
| `transient_overlap_test.dart` | A notice never covers the navigation |
| `framework_defects_test.dart` | The five defects above still behave as described |
