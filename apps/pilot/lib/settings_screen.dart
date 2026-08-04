import 'package:flutter/widgets.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'screen_frame.dart';
import 'strings.dart';

/// Where the notification permission conversation currently stands.
enum ReminderPermission {
  /// Never asked.
  notAsked,

  /// Asked and refused.
  refused,

  /// Granted.
  granted,
}

/// Display preferences, the permission conversation, and the way to empty the
/// round.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({
    super.key,
    required this.configuration,
    required this.onConfigurationChanged,
    required this.permission,
    required this.onPermissionChanged,
    required this.clearRound,
  });

  /// The theme currently in force.
  final IuxThemeConfiguration configuration;

  /// Reports a change of theme to the application root.
  final ValueChanged<IuxThemeConfiguration> onConfigurationChanged;

  /// Where the permission conversation stands.
  final ReminderPermission permission;

  /// Reports the user's answer.
  final ValueChanged<ReminderPermission> onPermissionChanged;

  /// The controller behind "clear the whole round".
  ///
  /// Created and owned by the shell rather than here, because the confirmation
  /// it opens has to be handed to an `IuxModalLayer` that lives above the
  /// navigation — a screen that opened its own would be deciding layering.
  final IuxDestructiveFlowController clearRound;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  IuxDisclosureState _about = const IuxDisclosureState.collapsed();

  IuxAccessibilityProfile get _profile => widget.configuration.profile;

  void _updateProfile(IuxAccessibilityProfile profile) =>
      widget.onConfigurationChanged(
        widget.configuration.copyWith(profile: profile),
      );

  @override
  Widget build(BuildContext context) => PilotScreen(
        title: Strings.settingsTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            IuxSection(
              title: Strings.settingsDisplay,
              children: <Widget>[
                IuxSwitch(
                  label: Strings.settingsDark,
                  input: const IuxInputDescriptor(
                    semantics: IuxInputSemantics(label: Strings.settingsDark),
                    helpText: Strings.settingsDarkHelp,
                  ),
                  value: IuxSelectionState.fromSelected(
                    widget.configuration.brightness == Brightness.dark,
                  ),
                  onChanged: (bool value) => widget.onConfigurationChanged(
                    widget.configuration.copyWith(
                      brightness: value ? Brightness.dark : Brightness.light,
                    ),
                  ),
                ),
                IuxSwitch(
                  label: Strings.settingsContrast,
                  input: const IuxInputDescriptor(
                    semantics:
                        IuxInputSemantics(label: Strings.settingsContrast),
                    helpText: Strings.settingsContrastHelp,
                  ),
                  value: IuxSelectionState.fromSelected(
                    _profile.contrast == IuxContrast.high,
                  ),
                  onChanged: (bool value) => _updateProfile(
                    _profile.copyWith(
                      contrast: value ? IuxContrast.high : IuxContrast.standard,
                    ),
                  ),
                ),
                IuxSwitch(
                  label: Strings.settingsMotion,
                  input: const IuxInputDescriptor(
                    semantics: IuxInputSemantics(label: Strings.settingsMotion),
                    helpText: Strings.settingsMotionHelp,
                  ),
                  value: IuxSelectionState.fromSelected(
                    _profile.motion == IuxMotionPreference.reduced,
                  ),
                  onChanged: (bool value) => _updateProfile(
                    _profile.copyWith(
                      motion: value
                          ? IuxMotionPreference.reduced
                          : IuxMotionPreference.standard,
                    ),
                  ),
                ),
              ],
            ),
            const IuxGap.between(),
            IuxSection(
              title: Strings.settingsNotifications,
              children: <Widget>[_reminders],
            ),
            const IuxGap.between(),
            IuxProgressiveDisclosure(
              summary: Strings.settingsAboutSummary,
              state: _about,
              onExpandedChanged: (bool expanded) => setState(
                () => _about = expanded
                    ? const IuxDisclosureState.expanded()
                    : const IuxDisclosureState.collapsed(),
              ),
              child: const _AboutBody(),
            ),
            const IuxGap.between(),
            IuxSection(
              title: Strings.settingsDanger,
              children: <Widget>[
                IuxDestructiveFlow(
                  label: Strings.settingsClear,
                  controller: widget.clearRound,
                ),
              ],
            ),
          ],
        ),
      );

  /// The permission conversation, in whichever state it is in.
  Widget get _reminders => switch (widget.permission) {
        ReminderPermission.notAsked => IuxPermissionRationale(
            moment: IuxBeforeAsking(
              ask: IuxInlineFeedbackAction(
                label: Strings.permissionAsk,
                onActivate: () =>
                    widget.onPermissionChanged(ReminderPermission.granted),
              ),
              decline: IuxInlineFeedbackAction(
                label: Strings.permissionDecline,
                onActivate: () =>
                    widget.onPermissionChanged(ReminderPermission.refused),
              ),
            ),
            title: Strings.permissionTitle,
            reason: Strings.permissionReason,
          ),
        ReminderPermission.refused => IuxPermissionRationale(
            moment: IuxAfterRefusal(
              askAgain: IuxInlineFeedbackAction(
                label: Strings.permissionAskAgain,
                onActivate: () =>
                    widget.onPermissionChanged(ReminderPermission.granted),
              ),
              decline: IuxInlineFeedbackAction(
                label: Strings.permissionKeepOff,
                onActivate: () =>
                    widget.onPermissionChanged(ReminderPermission.refused),
              ),
            ),
            title: Strings.permissionRefusedTitle,
            reason: Strings.permissionRefusedReason,
          ),
        ReminderPermission.granted => IuxAlert(
            category: IuxFeedbackCategory.info,
            categoryLabel: Strings.noteCategory,
            title: Strings.permissionGranted,
            message: Strings.permissionGrantedDetail,
            action: IuxInlineFeedbackAction(
              label: Strings.permissionTurnOff,
              onActivate: () =>
                  widget.onPermissionChanged(ReminderPermission.refused),
            ),
          ),
      };
}

/// What is behind the disclosure.
class _AboutBody extends StatelessWidget {
  const _AboutBody();

  @override
  Widget build(BuildContext context) {
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    return Text(
      Strings.settingsAboutBody,
      style: type.body.copyWith(color: colors.content.secondary),
    );
  }
}
