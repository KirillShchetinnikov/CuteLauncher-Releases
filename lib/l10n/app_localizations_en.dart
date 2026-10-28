// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get diagnosticsHubTitle => 'Diagnostics';

  @override
  String get tvCompatibilityTitle => 'TV compatibility check';

  @override
  String get tvCompatibilityRun => 'Run check';

  @override
  String get tvCompatibilityResults => 'View results';

  @override
  String get compatibilityReportDate => 'Check date';

  @override
  String get compatibilityLauncherVersion => 'CuteLauncher version';

  @override
  String get diagnosticsExport => 'Export report';

  @override
  String get diagnosticsCopyClipboard => 'Copy to clipboard';

  @override
  String get diagnosticsSaveDisk => 'Save to disk';

  @override
  String get tvCompatibilityHelp =>
      'Reads device, firmware, permission and system capability metadata. No settings, packages or HOME are changed; ADB is not connected, and no apps or system screens are launched. Results describe availability reported by Android, not physical remote, HDMI or end-to-end operation. Export includes the model and full firmware identity for the device catalog, without serial number, IP, Wi-Fi networks, accounts or installed app lists. Nothing is sent automatically. The latest report stays in memory until you leave Diagnostics; running a new check replaces it.';

  @override
  String get compatibilityAndroidTv => 'Android TV support';

  @override
  String get compatibilityAndroidVersion => 'Android version';

  @override
  String get compatibilityHomeRegistered => 'CuteLauncher registered as HOME';

  @override
  String get compatibilityDefaultHome => 'CuteLauncher selected as home screen';

  @override
  String get compatibilityHomeSelection => 'HOME selection priority';

  @override
  String get compatibilityOverlay => 'Display over other apps';

  @override
  String get compatibilityNotifications => 'CuteLauncher notifications';

  @override
  String get compatibilityNotificationListener => 'Notification access';

  @override
  String get compatibilityAccessibility => 'Accessibility service';

  @override
  String get compatibilityWriteSettings => 'Write system settings';

  @override
  String get compatibilityUsageStats => 'Usage statistics access';

  @override
  String get compatibilityWatchNext => 'Watch Next access';

  @override
  String get compatibilityTvInputs => 'System TV input list';

  @override
  String get compatibilityDocumentExport => 'JSON export handler';

  @override
  String get compatibilityScreensaverSelection =>
      'System screensaver selection';

  @override
  String get compatibilityAvailable => 'Available according to Android';

  @override
  String get compatibilityNotGranted => 'Permission not granted';

  @override
  String get compatibilityNotConfigured => 'Not configured or list empty';

  @override
  String get compatibilityRestricted => 'System restriction detected';

  @override
  String get compatibilityUnsupported => 'Support not detected';

  @override
  String get compatibilityUnknown => 'Could not determine';

  @override
  String get appArtworkBackground => 'Selected app colours';

  @override
  String get appArtworkBackgroundHelp =>
      'The focused app\'s banner or icon becomes a soft colour background. The selected gradient appears before an image is ready or if it cannot be read. Changes pause while the launcher is in the background. Your other wallpapers are kept.';

  @override
  String get adbWifiOwnedTitle => 'Wi-Fi belongs to the setup wizard';

  @override
  String get adbWifiOwned =>
      'No changes made: a saved Wi-Fi network was created by the Google setup wizard. Disabling it may delete the network and disconnect the TV.\n\n1. Make sure you know the Wi-Fi password.\n2. Open Android network settings, select that network and choose Forget network.\n3. Reconnect through the regular Android network settings.\n4. Return to CuteLauncher, check ADB and try disabling the built-in launcher again.\n\nIf this message returns, keep the built-in launcher enabled: the firmware may assign the network to the setup wizard again.';

  @override
  String get adbWifiUnknown =>
      'Not changed: the owners of saved Wi-Fi networks could not be verified. Disabling the setup wizard is blocked to protect your connection. Check ADB and try again; some firmware does not provide this information.';

  @override
  String get backgroundSource => 'Background source';

  @override
  String get noAvailableCategories =>
      'There are no sections available to add this app to.';

  @override
  String get redditWallpaperTheme => 'Wallpaper theme';

  @override
  String get redditThemeAll => 'Mixed';

  @override
  String get redditThemeNature => 'Nature';

  @override
  String get redditThemeSpace => 'Space';

  @override
  String get redditThemeCity => 'Cities';

  @override
  String get redditThemeMinimal => 'Minimalism';

  @override
  String get redditWallpaperResolution => 'Minimum resolution';

  @override
  String get redditWallpaperHint =>
      'Each successful refresh downloads a different landscape image from the selected Reddit community. Resolution is the minimum original size; images are not upscaled. Refresh runs while the launcher is open and resumes when you return. Adult content, videos and galleries are skipped. If Reddit blocks access or no matching image is found, the previous wallpaper remains.';

  @override
  String get dialogCommandDetails => 'Show ADB commands';

  @override
  String get dialogAssign => 'Assign';

  @override
  String get dialogApply => 'Apply';

  @override
  String get settingsValueNotSet => 'Not set';

  @override
  String get settingsMenuPosition => 'Settings menu position';

  @override
  String get settingsMenuLeft => 'Left';

  @override
  String get settingsMenuRight => 'Right';

  @override
  String get actionCompleted => 'Action completed';

  @override
  String get showRepositoryQrCode => 'Show QR code';

  @override
  String get resetSections => 'Reset section settings';

  @override
  String get resetSectionsConfirmation =>
      'Restore default sections? Custom sections, spacers and Favorites contents will be removed.';

  @override
  String get cardFocusMode => 'Focus on return Home';

  @override
  String get cardFocusRemember => 'Keep selected card';

  @override
  String get cardFocusFirst => 'First card';

  @override
  String get cardFocusSettings => 'Settings button';

  @override
  String get aboutFlauncher => 'About CuteLauncher';

  @override
  String get addCategory => 'Add category';

  @override
  String get addSection => 'Add section';

  @override
  String get alphabetical => 'Alphabetical';

  @override
  String get appCardHighlightAnimation => 'Highlight outline pulse';

  @override
  String get appInfo => 'Application info';

  @override
  String get appKeyClick => 'Key sounds';

  @override
  String get applications => 'Applications';

  @override
  String get autoHideAppBar => 'Automatically hide status bar';

  @override
  String get backButtonAction => 'Back button action';

  @override
  String get category => 'Category';

  @override
  String get categories => 'Categories';

  @override
  String get columnCount => 'Column count';

  @override
  String get date => 'Date';

  @override
  String get dateAndTimeFormat => 'Date and time format';

  @override
  String get delete => 'Delete';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'Do nothing';

  @override
  String get dialogOptionBackButtonActionShowScreensaver => 'Show screensaver';

  @override
  String get dialogOptionBackButtonActionShowClock => 'Show clock';

  @override
  String get dialogTextNoFileExplorer =>
      'Please install a file explorer in order to pick a picture.';

  @override
  String get dialogTitleBackButtonAction => 'Choose the back button action';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (Category)';
  }

  @override
  String formattedDate(String dateString) {
    return 'Formatted date: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'Formatted time: $timeString';
  }

  @override
  String get gradient => 'Gradient';

  @override
  String get favoriteApps => 'Favorite Apps';

  @override
  String get grid => 'Grid';

  @override
  String get height => 'Height';

  @override
  String get hide => 'Hide';

  @override
  String get hiddenApplications => 'Hidden Apps';

  @override
  String get launcherSections => 'Sections';

  @override
  String get layout => 'Layout';

  @override
  String get loading => 'Loading';

  @override
  String get manual => 'Manual';

  @override
  String get modifySection => 'Modify section';

  @override
  String get mustNotBeEmpty => 'Must not be empty';

  @override
  String get name => 'Name';

  @override
  String get newSection => 'New section';

  @override
  String get noDateFormatSpecified => 'No date format specified';

  @override
  String get noTimeFormatSpecified => 'No time format specified';

  @override
  String get nonTvApplications => 'Non-TV Apps';

  @override
  String get open => 'Open';

  @override
  String get orSelectFormatSpecifiers => 'Or select format specifiers';

  @override
  String get openImage => 'Choose file';

  @override
  String get picture => 'Local image or video';

  @override
  String removeFrom(String name) {
    return 'Remove from $name';
  }

  @override
  String get renameCategory => 'Rename category';

  @override
  String get reorder => 'Reorder';

  @override
  String get row => 'Row';

  @override
  String get rowHeight => 'Row height';

  @override
  String get save => 'Save';

  @override
  String get spacer => 'Spacer';

  @override
  String get spacerMaxHeightRequirement =>
      'Must be greater than 0 and less than or equal to 500';

  @override
  String get statusBar => 'Status bar';

  @override
  String get settings => 'Settings';

  @override
  String get show => 'Show';

  @override
  String get showCategoryTitles => 'Show category titles';

  @override
  String get themes => 'Themes';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'Hide highlight outline on homescreen';

  @override
  String get appSelectorTransitionAnimation => 'Smooth highlight transitions';

  @override
  String get sort => 'Sort';

  @override
  String get systemSettings => 'Android settings';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher is an Android TV launcher based on LTvLauncher by LeanBitLab and FLauncher by Étienne Fesser.\n\nCuteLauncher by Kirill Shchetinnikov. GNU GPLv3.\nRepository: $repoUrl.';
  }

  @override
  String get textEmptyCategory => 'This category is empty.';

  @override
  String get time => 'Time';

  @override
  String get titleStatusBarSettingsPage =>
      'Choose what to display in the status bar';

  @override
  String get tvApplications => 'TV Apps';

  @override
  String get type => 'Type';

  @override
  String get typeInTheDateFormat => 'Type in the date format';

  @override
  String get typeInTheHourFormat => 'Type in the hour format';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get wallpaper => 'Wallpaper';

  @override
  String get withEllipsisAddTo => 'Add to...';

  @override
  String get timeBasedWallpaper => 'Day/Night image';

  @override
  String get pickDayWallpaper => 'Choose day image';

  @override
  String get pickNightWallpaper => 'Choose night image';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get defaultLauncherIsDefault => 'CuteLauncher is the default launcher';

  @override
  String get defaultLauncherNotDefault =>
      'CuteLauncher is not the default launcher';

  @override
  String get setAsDefaultLauncher => 'Set as default launcher';

  @override
  String get defaultLauncherDescription =>
      'When set as the default launcher, the Home button will always return to CuteLauncher. The TV will also boot directly into CuteLauncher.';

  @override
  String get inputs => 'Inputs';

  @override
  String get inputsUnavailableHint =>
      'This device provides no available inputs. The switch is disabled and the icon is hidden. On a TV box, this option does not control the connected TV’s HDMI inputs.';

  @override
  String get inputSources => 'Input Sources';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get importBackup => 'Import Backup';

  @override
  String exportSuccess(String path) {
    return 'Backup exported successfully to $path';
  }

  @override
  String get importSuccess => 'Backup imported successfully';

  @override
  String get importConfirm =>
      'Import this backup? Saved valid settings and layout will be applied. Missing or invalid individual settings keep their current values.';

  @override
  String get importError =>
      'Could not restore settings from the backup. Check the file and try again.';

  @override
  String exportError(String error) {
    return 'Failed to export backup: $error';
  }

  @override
  String get shareBackup => 'Share Backup';

  @override
  String get shareBackupDescription =>
      'Share backup with other devices on local network';

  @override
  String get stopSharing => 'Stop Sharing';

  @override
  String get localNetworkSharingActive => 'Local network sharing is active!';

  @override
  String get localNetworkSharingInstructions =>
      'Connect another device to the same Wi-Fi network and open the following URL in a web browser:';

  @override
  String get localNetworkSharingDetails =>
      'Here you can download your TV settings/layout or upload a backup file back to this TV.';

  @override
  String failedToStartServer(String error) {
    return 'Failed to start sharing server: $error';
  }

  @override
  String get notificationBell => 'Notification icon';

  @override
  String get autoHideNotificationBell =>
      'Hide icon when there are no notifications';

  @override
  String get continueWatching => 'Continue Watching';

  @override
  String get showContinueWatchingOnHome => 'Show Continue Watching on Home';

  @override
  String get permissionDeniedContinueWatching =>
      'Permission required to show Continue Watching';

  @override
  String get interface => 'Interface';

  @override
  String get system => 'System';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get miscellaneous => 'Miscellaneous';

  @override
  String get brightnessScheduler => 'Brightness Scheduler';

  @override
  String get screensaverSettings => 'Choose screensaver in Android TV';

  @override
  String get screensaverClockStyle => 'Screensaver Clock Style';

  @override
  String get dataUsagePeriod => 'Traffic counting period';

  @override
  String get notificationAccess => 'Notification Access';

  @override
  String get granted => 'Granted';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get systemWidePopupAlert => 'System-wide Popup Alert';

  @override
  String get overlayPermissionRequired => 'Overlay Permission Required';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get showAppNamesBelowIcons => 'Show app labels';

  @override
  String get dataUsage => 'Data Usage';

  @override
  String get networkIndicator => 'Network Indicator';

  @override
  String get homeButtonFix => 'Home button';

  @override
  String get startOnBoot => 'Start when the TV turns on';

  @override
  String get appLanguage => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get ukrainian => 'Ukrainian';

  @override
  String get chinese => 'Chinese';

  @override
  String get french => 'French';

  @override
  String get german => 'German';

  @override
  String get japanese => 'Japanese';

  @override
  String get portuguese => 'Portuguese';

  @override
  String get russian => 'Russian';

  @override
  String get italian => 'Italian';

  @override
  String get hindi => 'Hindi';

  @override
  String get korean => 'Korean';

  @override
  String get arabic => 'Arabic';

  @override
  String get turkish => 'Turkish';

  @override
  String get hidePersistentNotifications => 'Hide Persistent Notifications';

  @override
  String get hidePersistentNotificationsDesc =>
      'Hide ongoing background service and system notifications';

  @override
  String get blockedNotificationApps => 'Block notifications from apps';

  @override
  String get blockAppNotifications => 'Block Notifications';

  @override
  String get unblockAppNotifications => 'Unblock Notifications';

  @override
  String get noBlockedApps => 'No blocked apps';

  @override
  String get persistentNotification => 'Persistent';

  @override
  String get unblockAll => 'Unblock All';

  @override
  String get weather => 'Weather';

  @override
  String get showWeatherWarnings => 'Show Weather & Rain Warnings';

  @override
  String get temperatureUnit => 'Temperature Unit';

  @override
  String get celsius => 'Celsius (°C)';

  @override
  String get fahrenheit => 'Fahrenheit (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Install Breezy Weather and enable \'Local data sharing\' / \'Gadgetbridge\' in its settings to see weather and rain warnings.';

  @override
  String get displayAndScreensaver => 'Night mode and brightness';

  @override
  String get notifications => 'Notifications';

  @override
  String get continueWatchingDescription =>
      'Show recently watched movies and TV shows from supported apps on your home screen';

  @override
  String get continueWatchingPermissionDesc =>
      'Special permission is required to read watch history from TV apps. You can grant it using the button below or via ADB:';

  @override
  String get requestPermission => 'Request Permission';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get openApp => 'Open';

  @override
  String get notificationOptions => 'Notification Options';

  @override
  String get noBlockedAppsDesc =>
      'All applications are currently allowed to show notifications';

  @override
  String get notificationsAllowed => 'Notifications Allowed';

  @override
  String get notificationsBlocked => 'Notifications Blocked';

  @override
  String get dpadDismissHint => '◄ — dismiss · OK — options · ► — block app';

  @override
  String get watchNextDeleteError =>
      'Could not remove the item from Continue Watching. Try again.';

  @override
  String get hideLauncherTile => 'Hide CuteLauncher in the app grid';

  @override
  String get hideAndroidSettingsTile => 'Hide Android settings in app tiles';

  @override
  String get animateTileReordering => 'Animate tile reordering';

  @override
  String get imageInputRejected =>
      'This image is damaged or too large (maximum 8 MiB and 48 megapixels). Choose another image.';

  @override
  String get memoryTitle => 'Memory';

  @override
  String get memoryRefresh => 'Measure memory';

  @override
  String get memoryMeasuring => 'Measuring…';

  @override
  String get memoryClear => 'Clear image caches';

  @override
  String get memorySaver => 'Memory saving';

  @override
  String get memorySaverDescription =>
      'Memory saving mode:\n\n• Reduces image caches and the poster preload window.\n• Disables tile, panel and wallpaper background blur, and outline pulsing.\n• Limits shadows on unfocused tiles.\n• Clears caches when the app goes into the background.\n\nThese effects are unavailable in settings while memory saving is enabled. Their saved values return when the mode is disabled. Images may reload more often.';

  @override
  String get memoryPss => 'Process share (PSS)';

  @override
  String get memoryRss => 'Resident process memory (RSS)';

  @override
  String get memoryEncodedCache => 'Cached image files';

  @override
  String get memoryDecodedCache => 'Cached decoded images';

  @override
  String get memoryUnavailable => 'Unavailable';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => 'Measured at';

  @override
  String get memoryExplanation =>
      'PSS and RSS overlap: do not add them together. Cache sizes are part of app memory and do not describe all memory held by active images. Clearing caches keeps your settings and files; images load again when needed. Android may return memory later. RSS here comes from the kernel and PSS from Android; they may account for graphics memory differently.';

  @override
  String get memoryRecommendations =>
      'For less memory, enable saving, show fewer Continue watching cards and use smaller wallpapers or a gradient.';

  @override
  String get memoryMeasurementFailed =>
      'Process measurement is unavailable. Cache information is still shown.';

  @override
  String get addToCategory => 'Add to Category';

  @override
  String get addToFavorites => 'Add to Fav';

  @override
  String get removeFromFavorites => 'Remove from Fav';

  @override
  String get setCustomBanner => 'Set Custom Banner';

  @override
  String get clearCustomBanner => 'Clear Custom Banner';

  @override
  String get bannerSetFailed =>
      'Could not set the banner. Check access to the image and select the file again.';

  @override
  String get bannerClearFailed =>
      'Could not remove the custom banner. Try again.';

  @override
  String get grantUsagePermission => 'Grant Usage Permission';

  @override
  String get removeFromContinueWatching => 'Remove from Continue Watching';

  @override
  String hideAllFromApp(String appName) {
    return 'Hide all from $appName';
  }

  @override
  String get playResume => 'Play / Resume';

  @override
  String openNamedApp(String appName) {
    return 'Open $appName';
  }

  @override
  String get selectedAccent => 'Selected Accent';

  @override
  String get homeButtonFixHint =>
      'If you are using Google TV, enable \"Home Button Fix\" under Accessibility settings to make the Home button open this launcher.';

  @override
  String get accessibilityPermission => 'Accessibility Permission';

  @override
  String get shareFailed => 'Share Failed';

  @override
  String shareBackupError(String error) {
    return 'Failed to share backup: $error';
  }

  @override
  String get exportComplete => 'Export Success';

  @override
  String get exportFailed =>
      'Could not save the backup. Check folder access and available storage.';

  @override
  String backupLoadError(String error) {
    return 'Error loading backups: $error';
  }

  @override
  String get noBackupFiles => 'No backup files found.';

  @override
  String get importComplete => 'Import Success';

  @override
  String get importFailed => 'Import Failed';

  @override
  String get importAction => 'Import';

  @override
  String get continueWatchingApps => 'Continue Watching Apps';

  @override
  String get blockedContinueWatching => 'Blocked from Continue Watching';

  @override
  String get allAppsCanContinueWatching =>
      'All supported apps can show items in Continue Watching.';

  @override
  String get unblockApp => 'Unblock';

  @override
  String get unblockAllApps => 'Unblock All Apps';

  @override
  String get appsWithContinueWatching => 'Apps with Continue Watching';

  @override
  String get watchNextAppsHint =>
      'Apps currently providing Watch Next items on your home screen';

  @override
  String get noWatchNextApps =>
      'No apps are currently providing Continue Watching items.\nWhen supported apps (such as SmartTube or streaming services) add items, they will appear here.';

  @override
  String get allInstalledApps => 'All Installed Apps';

  @override
  String get blockWatchNextHint =>
      'Toggle off to block any app from adding items to Continue Watching';

  @override
  String get cardSize => 'Card Size';

  @override
  String get maximumItems => 'Maximum Items';

  @override
  String get playbackProgressBar => 'Playback Progress Bar';

  @override
  String get playbackPercentage => 'Playback Percentage';

  @override
  String get episodeVideoDetails => 'Episode & Video Details';

  @override
  String get restoreHiddenPrograms => 'Restore Hidden Programs';

  @override
  String get allHiddenProgramsRestored => 'All hidden programs restored';

  @override
  String get watchNextAccessAdb => 'Watch Next Access (ADB Required)';

  @override
  String get supportLtvLauncher => 'Support LTvLauncher';

  @override
  String get scanToDonate => 'Scan with your phone camera to donate:';

  @override
  String get openInBrowser => 'Open in Browser';

  @override
  String get close => 'Close';

  @override
  String get launcherAuthor => 'CuteLauncher by Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Android TV launcher based on LTvLauncher by LeanBitLab and FLauncher by Étienne Fesser. Licensed under GNU GPLv3.';

  @override
  String get projectCredits => 'Project & Credits';

  @override
  String get launcherRepository => 'CuteLauncher Repository';

  @override
  String get originalProject => 'Original project: LTvLauncher';

  @override
  String get noInputsDetected => 'No inputs detected';

  @override
  String get reorderSectionsHint =>
      'Select with ◄ / ► then use ▲ / ▼ to reorder. Cross the list boundary to hide or show a section.';

  @override
  String get customName => 'Custom Name';

  @override
  String get mostUsed => 'Launch frequency';

  @override
  String get lastUsed => 'Last Used';

  @override
  String get clearAll => 'Clear All';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get notificationAccessAdb => 'Notification Access (ADB Required)';

  @override
  String get openAppInfo => 'Open App Info';

  @override
  String get overlayPermission => 'Overlay Permission';

  @override
  String get clockMinimal => 'Minimal';

  @override
  String get clockMinimalDescription => 'Thin, elegant font (Default)';

  @override
  String get clockBold => 'Bold';

  @override
  String get clockBoldDescription => 'Thick, highly visible font';

  @override
  String get clockRetro => 'Retro';

  @override
  String get clockRetroDescription => 'Monospaced, retro terminal style';

  @override
  String get clockElegant => 'Elegant';

  @override
  String get clockElegantDescription => 'Classic serif typeface';

  @override
  String get clockNeon => 'Neon';

  @override
  String get clockNeonDescription => 'Ultra-thin, glowing style';

  @override
  String get clockPixel => 'Pixel';

  @override
  String get clockPixelDescription => 'Bold monospaced, arcade feel';

  @override
  String get clockDigital => 'Digital';

  @override
  String get clockDigitalDescription => 'Clean monospaced display';

  @override
  String get themeDefault => 'Default';

  @override
  String get themePremium => 'Premium';

  @override
  String get themeClassic => 'Classic';

  @override
  String get themeCapsule => 'Capsule';

  @override
  String get cancel => 'Cancel';

  @override
  String get actionCancelled => 'Action cancelled';

  @override
  String get ok => 'OK';

  @override
  String get accessibilityGuide =>
      'Open the TV settings manually, then Accessibility → CuteLauncher Home Button Fix, and enable the service. The location and name of this menu depend on your TV manufacturer.';

  @override
  String get notificationPermissionGuide =>
      'The notification access settings could not be opened on this TV. Allowing outgoing notifications in App Info does not grant access to notifications from other apps.\n\nConnect your TV via ADB and run:';

  @override
  String get overlayPermissionGuide =>
      'The overlay permission settings could not be opened automatically.\n\nTo enable popups over other apps, connect your TV via ADB and run:';

  @override
  String get watchNextPermissionGuide =>
      'To read Continue Watching cards from other apps, Android TV requires READ_WRITE_WATCH_NEXT_PROGRAMS.\n\nConnect your TV via ADB and run:';

  @override
  String get watchNextAccess => 'Continue Watching access';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String displayUpToItems(int count) {
    return 'Display up to $count recent items';
  }

  @override
  String get unlimitedItems => 'Unlimited';

  @override
  String get allAvailableItems => 'Display all available items';

  @override
  String get defaultOption => 'Default';

  @override
  String get manage => 'Manage';

  @override
  String blockedCount(int count) {
    return '$count blocked';
  }

  @override
  String hiddenCount(int count) {
    return '$count hidden';
  }

  @override
  String blockedWatchNextCount(int count) {
    return 'Blocked from Continue Watching ($count)';
  }

  @override
  String get sizeExtraSmall => 'Extra Small';

  @override
  String get sizeVerySmall => 'Very Small';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeCompact => 'Compact';

  @override
  String get sizeMediumSmall => 'Medium Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeStandardDefault => 'Standard (Default)';

  @override
  String get sizeMediumLarge => 'Medium Large';

  @override
  String get sizeLarge => 'Large';

  @override
  String get sizeVeryLarge => 'Very Large';

  @override
  String get sizeExtraLarge => 'Extra Large';

  @override
  String get sizeHuge => 'Huge';

  @override
  String get tvApps => 'TV Apps';

  @override
  String get nonTvApps => 'Non-TV Apps';

  @override
  String get moviesShows => 'Movies & Shows';

  @override
  String get music => 'Music';

  @override
  String get games => 'Games';

  @override
  String get entertainment => 'Entertainment';

  @override
  String get liveTv => 'Live TV';

  @override
  String get sports => 'Sports';

  @override
  String get news => 'News';

  @override
  String get tools => 'Tools';

  @override
  String get favorites => 'Favorites';

  @override
  String get customSectionName => 'Custom...';

  @override
  String get selectSectionName => 'Select a name';

  @override
  String get weeklyUsage => 'Weekly: ';

  @override
  String get monthlyUsage => 'Monthly: ';

  @override
  String get dailyUsage => 'Daily: ';

  @override
  String get appError => 'Something went wrong';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherStorm => 'Storm';

  @override
  String get weatherToday => 'today';

  @override
  String get weatherTomorrow => 'tomorrow';

  @override
  String weatherOnDay(String day) {
    return 'on $day';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'CuteLauncher Backup';

  @override
  String get noApplicationsFound => 'No applications found';

  @override
  String get invalidDateFormat => 'Invalid format';

  @override
  String get selectDateFormats => 'Select formats below';

  @override
  String activeItemsCount(int count) {
    return '$count active item(s)';
  }

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorWhite => 'White';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorRed => 'Red';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorLime => 'Lime';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorRose => 'Rose';

  @override
  String get colorIceBlue => 'Ice Blue';

  @override
  String get memoryFeatures => 'Memory by feature (caches)';

  @override
  String get memoryAppIcons => 'App icons';

  @override
  String get memoryAppBanners => 'App banners';

  @override
  String get memoryWatchNextPosters => 'Continue Watching posters';

  @override
  String get memoryOtherCaches => 'Other encoded image caches';

  @override
  String get memoryFeaturesExplanation =>
      'These are retained image bytes, already included in the encoded cache total. Zero means no retained bytes in that cache, not that the feature uses no memory. Wallpapers and displayed images share the decoded cache above; active images may be outside it. Weather, notifications, Dart objects and the engine cannot be split by feature here. Shared interface graphics are reported above by Android and already included in PSS. Their memory is part of the process total. Do not add these overlapping values.';

  @override
  String get memoryGraphics => 'Interface graphics (included in PSS)';

  @override
  String get categoryVisible => 'Show category';

  @override
  String get hiddenCategories => 'Hidden categories';

  @override
  String get visibleCategories => 'Visible categories';

  @override
  String get backupSavedToSelectedLocation =>
      'Backup saved to the selected location';

  @override
  String get tileHorizontalGap => 'Horizontal spacing';

  @override
  String get tileVerticalGap => 'Vertical spacing';

  @override
  String get tileOpacity => 'Background opacity';

  @override
  String get tileShadow => 'Shadow';

  @override
  String get tileCornerRadius => 'Corner rounding';

  @override
  String get tileIconScale => 'Icon size';

  @override
  String get tileBackgroundColor => 'Tile background';

  @override
  String get tileLabelSize => 'Label size';

  @override
  String get resetAppearance => 'Reset appearance';

  @override
  String get tileAppearance => 'Tile appearance';

  @override
  String get tileLabelColor => 'Label color';

  @override
  String get tilePreviewName => 'Sample application';

  @override
  String get tileProportions => 'Tile proportions';

  @override
  String get tileLarge => 'Large';

  @override
  String get tileLabelBelow => 'Below the tile';

  @override
  String get tileLabelInside => 'Inside the tile';

  @override
  String get tileFocusScale => 'Enlarge';

  @override
  String get tileMedium => 'Medium';

  @override
  String get tileFocusBorder => 'No movement';

  @override
  String get tileSize => 'Tile size';

  @override
  String get tileCompact => 'Compact';

  @override
  String get tileLabelPosition => 'Label position';

  @override
  String get tileFocusEffect => 'Focus effect';

  @override
  String get tileFocusStrength => 'Highlight intensity';

  @override
  String get panelIndependent => 'Custom settings';

  @override
  String get panelAppearance => 'Top panel style';

  @override
  String get panelBackground => 'Panel background';

  @override
  String get blurPerformanceHint =>
      'Blur may reduce smoothness. It is disabled while memory saving is on.';

  @override
  String get panelOpacity => 'Panel opacity';

  @override
  String get tileBlur => 'Blur behind tiles';

  @override
  String get panelBlur => 'Blur behind top panel';

  @override
  String get panelShared => 'Like panels';

  @override
  String get weatherMinutes => 'min';

  @override
  String get weatherOpenMeteoCredit =>
      'Weather: Open-Meteo (open-meteo.com), CC BY 4.0. Free API for non-commercial use.';

  @override
  String get weatherRateLimit => 'Request limit reached. Try later.';

  @override
  String get weatherYandexCredit =>
      'Weather: Yandex Weather (yandex.ru/pogoda). Access depends on your API plan.';

  @override
  String get yandexWeather => 'Yandex Weather (REST)';

  @override
  String get weatherAuthorizationError =>
      'The weather provider rejected the request. Check the API key and access to the selected service.';

  @override
  String get weatherYandexHint =>
      'Requires a key with REST forecast access. A key for another Yandex plan may not work.';

  @override
  String get weatherSource => 'Weather source';

  @override
  String get weatherInterval => 'Update interval';

  @override
  String get weatherLongitude => 'Longitude (-180 to 180)';

  @override
  String get weatherKeyRequired => 'Add a Yandex API key.';

  @override
  String get weatherLocationName => 'City name (optional)';

  @override
  String get weatherLocation => 'Location';

  @override
  String get weatherApiKey => 'Yandex API key';

  @override
  String get weatherInvalidResponse =>
      'The weather source returned invalid data.';

  @override
  String get weatherUnavailable =>
      'Weather is unavailable. Previously received data is retained if available. Retries are limited to once every 5 minutes.';

  @override
  String get weatherStale => 'Previous weather';

  @override
  String get weatherLatitude => 'Latitude (-90 to 90)';

  @override
  String get weatherCoordinatesError =>
      'Enter a city manually or get coordinates automatically.';

  @override
  String get weatherRefresh => 'Check for updates';

  @override
  String get weatherKeyPrivate =>
      'Stored only on this device, excluded from backups. Empty input removes the key.';

  @override
  String get weatherUpdated => 'Updated';

  @override
  String get onlineWallpaperError =>
      'Unable to load this image. Previous wallpaper is retained. Select “Check for updates” to retry the download.';

  @override
  String get onlineWallpaperHint =>
      'The last image is kept offline (up to 8 MiB).';

  @override
  String get onlineWallpaperHours => 'h';

  @override
  String get onlineWallpaperInterval => 'Download interval';

  @override
  String get onlineWallpaper => 'Online wallpaper';

  @override
  String get onlineWallpaperUrlError =>
      'Enter a direct HTTPS image URL without login details.';

  @override
  String get onlineWallpaperEnabled => 'Use online wallpaper';

  @override
  String get onlineWallpaperSource => 'Image source';

  @override
  String get bingWallpaper => 'Bing image of the day';

  @override
  String get onlineWallpaperUrlSource => 'Direct HTTPS URL';

  @override
  String get updatePlayOnly =>
      'This installation receives updates through Google Play.';

  @override
  String get updateCheck => 'Check now';

  @override
  String get updateInstalled => 'Installed';

  @override
  String get updateDownloadInstall => 'Download and install';

  @override
  String get updateNoRelease => 'No newer compatible release is available.';

  @override
  String get updateIncompatible =>
      'The APK does not match this application, certificate or a newer version. Installation was blocked.';

  @override
  String get updateError =>
      'Unable to check, download or open the installer. Try again later.';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get appUpdates => 'Application updates';

  @override
  String get updatePermission =>
      'Allow installation from this application in Android settings, return here and press Install again.';

  @override
  String get updateInstall => 'Install downloaded update';

  @override
  String get updateHint =>
      'Source: GitHub / KirillShchetinnikov/CuteLauncher-Releases. Automatic checks run while the launcher is open. Download starts when you choose it; Android asks you to confirm installation. Your data is kept.';

  @override
  String get updateAutomatic => 'Check automatically once a day';

  @override
  String get allApplications => 'All applications';

  @override
  String get adbAccessibility => 'Enable Home Button Fix';

  @override
  String get adbAuthorization =>
      'Approve ADB authorization on the TV, then try again.';

  @override
  String get adbChangeConfirm =>
      'Apply this system setting through ADB? The previous Home app is saved before changing it; other accessibility services are preserved.';

  @override
  String get adbCheck => 'Check connection';

  @override
  String get adbDenied => 'The system did not allow or confirm this change.';

  @override
  String get adbDisable => 'Disable the previous launcher';

  @override
  String get adbDisableConfirm =>
      'Disable the saved previous launcher? This requires CuteLauncher to be the current Home app. Restore it with the recovery action in this setup.';

  @override
  String get adbHint =>
      'Prototype for this TV only (127.0.0.1). Enable TCP ADB in developer options, enter its port and approve the authorization prompt on the TV. Wireless debugging with a pairing code is not supported yet. The private key stays on this device, outside backups.';

  @override
  String get adbHome => 'Make CuteLauncher the Home app';

  @override
  String get adbInvalid => 'Enter a port between 1024 and 65535.';

  @override
  String get adbNoRecovery =>
      'Restoration is unavailable: no other launcher or saved service state was found.';

  @override
  String get adbPort => 'TCP ADB port';

  @override
  String get adbReady => 'ADB access confirmed.';

  @override
  String get adbRestore => 'Restore the previous launcher';

  @override
  String get adbSuccess => 'Change applied and verified.';

  @override
  String get adbTitle => 'ADB setup';

  @override
  String get adbUnavailable =>
      'Unable to connect. Check TCP ADB, the port and the authorization prompt.';

  @override
  String get nightModeScheduled => 'Use schedule';

  @override
  String get nightModeTitle => 'Night mode';

  @override
  String get nightModeScope =>
      'Overlay permission is needed to dim other apps. Without it, dimming works inside CuteLauncher. The TCL filter needs no overlay permission. Above 80% opacity Android may block touch input in other apps; TV remote keys still work.';

  @override
  String get nightModeEnd => 'End';

  @override
  String get nightModeStart => 'Start';

  @override
  String get nightModeDim => 'Dimming';

  @override
  String get nightModeWarmth => 'Warm filter';

  @override
  String get nightModeScheduleHint =>
      'Uses local TV time. Overnight periods are supported. Equal start and end times disable the scheduled filter.';

  @override
  String get nightModeEnabled => 'Enable night mode';

  @override
  String get nightModePermission => 'Allow display over other apps';

  @override
  String get nightModePermissionGranted => 'Display over other apps allowed';

  @override
  String get backupDownloadsFailed => 'Could not save the backup to Downloads.';

  @override
  String get backupSaveDownloads => 'Save backup to Downloads';

  @override
  String get adbRestoreAccessibility => 'Restore accessibility access';

  @override
  String get nightModeAdbConfirm =>
      'Allow CuteLauncher to display over other apps using local ADB? Enable TCP debugging first and authorize the connection. Uses the port saved in the ADB wizard, or 5555.';

  @override
  String get nightModeAdbPermission => 'Grant permission through ADB';

  @override
  String get nightModeNotificationsHint =>
      'The notification lets you turn the filter off outside CuteLauncher. Without it, use this menu.';

  @override
  String get nightModeNotificationsAllowed => 'Night mode notification allowed';

  @override
  String get nightModeNotifications => 'Allow night mode notification';

  @override
  String get categoryLastVisibleHint =>
      'At least one category must remain visible.';

  @override
  String get diagnosticsClear => 'Clear report';

  @override
  String get diagnosticsReady => 'Report ready';

  @override
  String get diagnosticsCreate => 'Create report';

  @override
  String get diagnosticsOperations => 'Recorded operations';

  @override
  String get diagnosticsCopied => 'Report copied';

  @override
  String get diagnosticsSharingNotice =>
      'Send the file to the author privately, not publicly: automatic redaction may miss personal data. By sending the report to the author, you agree to publication of an anonymized TV compatibility report in the CuteLauncher Git repository. Only device metadata and feature availability are published, without personal data; error logs, commands and your settings are not published.\n\nThe report also includes installed packages, their names, versions and enabled state, plus section names, contents, order and visibility. Package identifiers and names are retained for diagnosis; app and section lists are not published.';

  @override
  String get diagnosticsHint =>
      'One report combines TV feature compatibility and error diagnostics. The report includes the TV model and firmware, app version, permissions, memory, error stages and causes, and system commands and responses with automatic personal-data redaction. Memory retains the last 50 operations, up to 100 failures separately, and a bounded ADB log for the current session. Restarting clears the log. Redaction may miss personal data: send the file in a private message instead of posting it publicly. Nothing is sent automatically. Each error retains a snapshot of the applied settings; later changes do not replace it.\n\nThe report also includes installed packages, their names, versions and enabled state, plus section names, contents, order and visibility. Package identifiers and names are retained for diagnosis; app and section lists are not published.';

  @override
  String get diagnosticsTitle => 'Error diagnostics';

  @override
  String get diagnosticsCopyFailed => 'Could not copy the report.';

  @override
  String get diagnosticsCopy => 'Copy report';

  @override
  String get diagnosticsCreating => 'Creating report…';

  @override
  String get tclBlueLightTitle => 'TCL blue light filter';

  @override
  String get tclBlueLightError =>
      'Could not read or verify the TCL filter setting. Refresh its state and try again.';

  @override
  String get tclBlueLightUnsupported =>
      'The TCL filter interface is unavailable on this TV.';

  @override
  String get tclBlueLightRefresh => 'Refresh TCL filter state';

  @override
  String get tclBlueLightHint =>
      'Controls the built-in Eye Health Protection filter of the TV. It can also follow the night mode schedule.';

  @override
  String get nightSolarSchedule => 'Sunset and sunrise';

  @override
  String get nightNextStart => 'Next start';

  @override
  String get nightScheduleTimeHint =>
      'Times use the TV time zone. Negative offsets are earlier; positive offsets are later.';

  @override
  String get nightTemperature => 'Filter color temperature';

  @override
  String get nightScheduleSettings => 'Schedule settings';

  @override
  String get nightCityName => 'City name';

  @override
  String get nightSkipUntilNext => 'Disable night mode until the next sunset';

  @override
  String get nightSunriseOffset => 'End relative to sunrise';

  @override
  String get nightEnableUntilMorning =>
      'Enable night mode until the next sunrise';

  @override
  String get nightPermissions => 'Permissions';

  @override
  String get nightTclSchedule => 'Include TCL filter in schedule';

  @override
  String get nightSearchCity => 'Search';

  @override
  String get nightRefreshSun => 'Refresh sunrise and sunset';

  @override
  String get nightSolarUnavailable =>
      'Choose a city and refresh sun times. If sunrise or sunset is unavailable, the solar schedule pauses.';

  @override
  String get nightSunsetOffset => 'Start relative to sunset';

  @override
  String get nightCityHint =>
      'Choose your city instead of granting location access. The selected coordinates are sent to Sunrise-Sunset.org, or Open-Meteo as a fallback, to retrieve sun times.';

  @override
  String get nightResumeSchedule => 'Return to schedule';

  @override
  String get nightScheduleSource => 'Schedule type';

  @override
  String get nightSolarCached =>
      'Using cached sun times; internet refresh will retry automatically.';

  @override
  String get nightTclScheduleHint =>
      'Uses the same schedule while night mode is enabled. Manual changes to the TCL filter last until the next scheduled transition. No overlay permission is needed.';

  @override
  String get nightRefreshPermission => 'Refresh permission status';

  @override
  String get nightCityNotFound => 'No cities found. Try another name.';

  @override
  String get nightNoOffset => 'No offset';

  @override
  String get nightManualSchedule => 'Custom schedule';

  @override
  String get nightChooseCity => 'Choose city';

  @override
  String get nightPermissionUnknown => 'Overlay permission status is unknown';

  @override
  String get nightNextEnd => 'Next end';

  @override
  String get nightTemporaryOff => 'Dimming temporarily off until';

  @override
  String get nightCitySearchFailed =>
      'Could not search for cities. Check your internet connection.';

  @override
  String get nightSolarAttribution =>
      'Daily sun times: Sunrise-Sunset.org; fallback: Open-Meteo. City search: GeoNames. Several days are cached for offline use.';

  @override
  String get nightTemporaryOn => 'Dimming temporarily on until';

  @override
  String get homeScreen => 'Home screen';

  @override
  String get appearanceSettings => 'Appearance';

  @override
  String get generalSettings => 'Advanced';

  @override
  String get advancedSettings => 'Advanced';

  @override
  String get controlAndStartup => 'Launcher and TV controls';

  @override
  String get sectionsAndOrder => 'Sections and order';

  @override
  String get topPanel => 'Top panel';

  @override
  String get tileStyle => 'Tile style';

  @override
  String get tilesAndLabels => 'Tiles and labels';

  @override
  String get highlightAndAnimation => 'Highlight and animation';

  @override
  String get androidTvSettings => 'Android TV settings';

  @override
  String get weatherSettings => 'Weather settings';

  @override
  String get showHighlightOutline => 'Show highlight outline';

  @override
  String get resetTilesAndPanel => 'Reset tile and panel settings';

  @override
  String get resetTilesAndPanelHint =>
      'Reset additional tile, label, highlight and top panel parameters? Wallpaper, accent color, tile style and label visibility are preserved.';

  @override
  String get panelAppearanceSettings => 'Top panel appearance';

  @override
  String get panelSharedHint => 'Change the appearance in tile settings.';

  @override
  String get effectsCompatibilityHint =>
      'Additional appearance: the outline is always visible and does not pulse. Dimensional style has no legacy outline; classic does not pulse. Intensity affects scale and shadow; scaling is space-limited.';

  @override
  String get sizeAndLayout => 'Size and layout';

  @override
  String get labelsGroup => 'Labels';

  @override
  String get surfaceGroup => 'Surface';

  @override
  String get clockAndDateGroup => 'Clock and date';

  @override
  String get networkAndTrafficGroup => 'Network and traffic';

  @override
  String get buttonsGroup => 'Buttons';

  @override
  String get notificationAppsHint =>
      'Turn off apps whose notifications you do not need. An enabled switch allows notifications; the app can still be launched.';

  @override
  String get notificationPanelLink => 'Top panel appearance';

  @override
  String get overlayAccessAdb => 'Display over other apps (ADB)';

  @override
  String get tileStyleModern => 'Modern';

  @override
  String get tileStyleVolume => 'Dimensional';

  @override
  String get showTime => 'Show time';

  @override
  String get showDate => 'Show date';

  @override
  String get showWeather => 'Show weather';

  @override
  String get showNetwork => 'Show network status';

  @override
  String get showTraffic => 'Show traffic';

  @override
  String get scheduledBrightness => 'Scheduled brightness';

  @override
  String get followTileStyle => 'Follow style';

  @override
  String get androidTvSettingsHint => 'Open the TV system settings';

  @override
  String get autoHideTopPanel => 'Automatically hide the panel';

  @override
  String get showSectionTitles => 'Show section titles';

  @override
  String get usageDaily => 'Daily';

  @override
  String get usageWeekly => 'Weekly';

  @override
  String get usageMonthly => 'Monthly';

  @override
  String get onlineWallpaperAddress => 'Image address (HTTPS)';

  @override
  String get watchNextAppLimits => 'Limits per app';

  @override
  String get watchNextAppLimitsHint =>
      'Source limits apply before the overall limit. Unlimited keeps only the overall limit; hidden content stays hidden.';

  @override
  String get rememberCategoryFocus => 'Remember last focused card';

  @override
  String get automaticBackups => 'Automatic backup';

  @override
  String get automaticBackupsHint =>
      'Daily copies of settings, wallpapers and banners while the launcher is active. A missed copy runs after returning to the launcher. Stored privately on this device, up to 256 MiB total; removing the app or its data deletes them. Keep an external backup too.';

  @override
  String get automaticBackupsEnabled => 'Daily automatic backup';

  @override
  String get automaticBackupsKeep => 'Copies to keep';

  @override
  String get automaticBackupCreateNow => 'Create a restore point now';

  @override
  String get automaticBackupFailed =>
      'Backup operation failed. Check free space and try again.';

  @override
  String get restorePoints => 'Restore points';

  @override
  String get noRestorePoints => 'No restore points yet';

  @override
  String get updatePrereleases => 'Update to prereleases';

  @override
  String get topPanelObjects => 'Objects';

  @override
  String get panelTransparency => 'Panel transparency';

  @override
  String get panelTextBackground => 'Text and button background';

  @override
  String get panelTextBackgroundColor => 'Text and button background color';

  @override
  String get panelTextColor => 'Text and button color';

  @override
  String get panelTextSize => 'Text and button size';

  @override
  String get panelFont => 'Text font';

  @override
  String get fontSans => 'Sans serif';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontMono => 'Monospace';

  @override
  String get fontCondensed => 'Condensed';

  @override
  String get trafficPermissionGranted => 'Traffic statistics access granted';

  @override
  String get background => 'Background';

  @override
  String get backgroundParameters => 'Source settings';

  @override
  String get resetAppearanceHint =>
      'Reset background, accent, tiles, labels, highlighting and animation?';

  @override
  String get wallpaperDimming => 'Dimming';

  @override
  String get wallpaperPlacement => 'Placement';

  @override
  String get wallpaperDisplay => 'Wallpaper display';

  @override
  String get wallpaperContain => 'Show whole image';

  @override
  String get wallpaperBlurred => 'Over blurred copy';

  @override
  String get wallpaperCover => 'Fill screen';

  @override
  String get wallpaperBrightness => 'Wallpaper brightness';

  @override
  String get wallpaperSaturation => 'Saturation';

  @override
  String get categoryPadding => 'Category padding';

  @override
  String get categoryLight => 'Light';

  @override
  String get categoryBlue => 'Blue';

  @override
  String get categoryPurple => 'Purple';

  @override
  String get categoryAllRows => 'All';

  @override
  String get categoryTeal => 'Teal';

  @override
  String get categoryMaxRows => 'Visible grid rows';

  @override
  String get categoryDark => 'Dark';

  @override
  String get categoryAppearance => 'Category appearance';

  @override
  String get categoryBackground => 'Category background';

  @override
  String get categoryTransparent => 'Transparent';

  @override
  String get slideshowInterval => 'Change interval';

  @override
  String get slideshowFolderSelected => 'Folder access saved on this device.';

  @override
  String get slideshowRandom => 'Random order';

  @override
  String get wallpaperSlideshow => 'Folder slideshow';

  @override
  String get slideshowNext => 'Next image';

  @override
  String get slideshowFolderRequired =>
      'Choose a folder to start the slideshow.';

  @override
  String get slideshowHint =>
      'Up to 1,000 images and 4,000 folder entries; files up to 8 MiB. Corrupt files are skipped and the last good image is retained. Changes stop in the background. Choose the folder again after restoring on another device.';

  @override
  String get slideshowSeconds => 's';

  @override
  String get slideshowError =>
      'Unable to read images. Choose an accessible folder containing valid images.';

  @override
  String get slideshowFolder => 'Choose folder';

  @override
  String get slideshowRecursive => 'Include subfolders';

  @override
  String get weatherSourceKeyRequired =>
      'Add an API key for this weather source.';

  @override
  String get weatherOpenWeatherCredit =>
      'Weather: OpenWeather (openweathermap.org). Daily values summarize the available three-hour forecast periods.';

  @override
  String get weatherOpenWeatherHint =>
      'Use your key for Current Weather and 5 day / 3 hour Forecast. Each update makes two requests; access and limits depend on your plan.';

  @override
  String get weatherOpenWeatherKey => 'OpenWeather API key';

  @override
  String get mediaPause => 'Pause';

  @override
  String get showNowPlaying => 'Show Now playing on Home';

  @override
  String get nowPlayingAccessHint =>
      'Media controls require notification access for CuteLauncher. Only actions provided by the player are shown.';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get mediaNext => 'Next track';

  @override
  String get mediaPlay => 'Resume';

  @override
  String get mediaControlError =>
      'The player is unavailable or did not accept this action.';

  @override
  String get nightUsageAccess => 'Allow usage access';

  @override
  String get nightExcludedAppsHint =>
      'The overlay and scheduled TCL filter pause in selected apps. Usage access is required; without it, exclusions cannot be applied.';

  @override
  String get nightExcludedApps => 'Excluded apps';

  @override
  String get adbPairPort => 'Pairing port';

  @override
  String get adbPairOverlayHint =>
      'Open Wireless debugging and Pair with pairing code. Keep the system code dialog open. This form becomes active after 30 seconds. Enter both ports and the code shown by Android.';

  @override
  String get adbOverlaySettings => 'Return control to Settings for 30 seconds';

  @override
  String get adbTlsHint =>
      'Use Wireless debugging in Developer options. Pairing and connection have different ports. If your firmware has no pairing-code screen or blocks overlay windows, use TCP / RSA instead. All connections remain local to this TV.';

  @override
  String get adbPaired =>
      'Paired. Check the connection using the Wireless debugging connection port.';

  @override
  String get adbTransport => 'Connection method';

  @override
  String get adbPairCode => 'Six-digit code';

  @override
  String get adbOverlayRequired =>
      'Code entry over Settings requires permission to display over other apps.';

  @override
  String get adbOverlayPermission => 'Allow display over other apps';

  @override
  String get adbTlsUnsupported =>
      'This firmware cannot open the required Settings screen or pairing overlay. Use TCP / RSA.';

  @override
  String get adbConnectPort => 'Connection port';

  @override
  String get adbTls => 'TLS / pairing code';

  @override
  String get adbTcp => 'TCP / RSA';

  @override
  String get adbPairingFailed =>
      'Pairing failed. Check the code and pairing port, keep the Android code dialog open, and try again.';

  @override
  String get adbTlsDisabled =>
      'Wireless debugging is disabled or its state is unavailable. Enable it in Developer options.';

  @override
  String get adbPairOverlay => 'Enter pairing code over Settings';

  @override
  String get adbPair => 'Pair';

  @override
  String get adbDeveloperSettings => 'Open Developer options';

  @override
  String get adbTwoWindowsHint =>
      'If this firmware supports two windows, keep the system pairing dialog open beside CuteLauncher and enter its code here. Direct pairing is available only while both windows are open.';

  @override
  String get adbTwoWindows => 'Open Settings in a second window';

  @override
  String get autoLaunchBoot => 'After TV boot';

  @override
  String get autoLaunchOff => 'Disabled';

  @override
  String get autoLaunchTitle => 'Autostart';

  @override
  String get autoLaunchDelay => 'Launch delay';

  @override
  String get autoLaunchHdmi => 'Switch to a selected HDMI input';

  @override
  String get autoLaunchWake => 'After wake';

  @override
  String get autoLaunchHint =>
      'Choose an app or HDMI input to open after TV startup or wake. Set the event and delay below. The action runs once when Android shows CuteLauncher. Any remote input or leaving the home screen cancels the wait. You can freely change HDMI inputs afterward. Set CuteLauncher as the default launcher or enable Start on boot if needed. Wake detection requires CuteLauncher to remain running.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get autoLaunchApp => 'Open a selected app';

  @override
  String get autoLaunchTarget => 'Launch target';

  @override
  String get autoLaunchUnavailable =>
      'The target is unavailable or the firmware does not allow this action.';

  @override
  String get autoLaunchCancelled => 'Delayed launch cancelled.';

  @override
  String get syncTitle => 'Exchange settings';

  @override
  String get syncHint =>
      'Save a settings file, transfer it to another device and open it there. Exchange the file back to bring both devices up to date. Interface, tile style and display preferences are shared. Apps, sections, wallpaper files, permissions, HOME, launch rules and secrets stay on this device. This is manual exchange; no account or background network connection is used.';

  @override
  String get syncExport => 'Save changes to a file';

  @override
  String get syncImport => 'Open changes from another device';

  @override
  String get syncSaved => 'Settings exchange file saved.';

  @override
  String get syncFailed =>
      'Unable to exchange settings. No partial import is kept. Check the file or open it again if settings changed during review.';

  @override
  String get syncPreviewHint =>
      'Review changes before applying. For conflicts, select each row to choose this device or the file. Keeping this device is selected initially. Cancel leaves settings unchanged.';

  @override
  String get syncNoChanges =>
      'No new settings. Apply to acknowledge the shared history.';

  @override
  String syncLocalValue(String value) {
    return 'This device: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'From file: $value';
  }

  @override
  String get syncKeepLocal => 'Conflict: keep this device';

  @override
  String get syncUseFile => 'Conflict: use the file';

  @override
  String get syncApply => 'Apply reviewed changes';

  @override
  String get syncApplied =>
      'Settings exchanged. Save a new file to send the result back.';

  @override
  String syncStyleParameters(int count) {
    return 'Custom style: $count parameters (differences below)';
  }

  @override
  String get cloudBackups => 'Cloud backups';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud. Enter the HTTPS address of an existing folder and an app password. Transfers are manual; this folder stores the latest copy.';

  @override
  String get cloudUrl => 'Folder HTTPS address';

  @override
  String get cloudUser => 'Username';

  @override
  String get cloudPassword => 'App password';

  @override
  String get cloudConnect => 'Check and save account';

  @override
  String get cloudCheck => 'Check connection';

  @override
  String get cloudDisconnect => 'Disconnect account';

  @override
  String get cloudDisconnectConfirm =>
      'Remove this account from the TV? Copies in the cloud will remain.';

  @override
  String get cloudUpload => 'Save a copy to the cloud';

  @override
  String get cloudDownload => 'Restore from the cloud';

  @override
  String get cloudUploadConfirm =>
      'Replace cutelauncher_backup.json in this folder with the current settings and data?';

  @override
  String get cloudSuccess => 'Done';

  @override
  String get cloudConfigurationError =>
      'Check the HTTPS folder address, username and app password.';

  @override
  String get cloudAuthorizationError =>
      'Access denied. Check your account and folder permissions.';

  @override
  String get cloudMissingError => 'The folder or backup was not found.';

  @override
  String get cloudUnsupportedError =>
      'This address does not support the required WebDAV operations. Redirects are not followed; enter the final folder address.';

  @override
  String get cloudNetworkError =>
      'Connection failed or timed out. Try again when the network is available.';

  @override
  String get cloudFailed =>
      'Could not complete the backup action. Check storage access and try again.';

  @override
  String get cloudStorageError =>
      'Account storage is unavailable. Disconnect and configure the account again.';

  @override
  String get adbPermissionChecking => 'Checking access…';

  @override
  String get adbPermissionConnected => 'ADB connected · grant permission';

  @override
  String get adbPermissionDisconnected =>
      'ADB disconnected · set up connection';

  @override
  String get adbSetupIntro =>
      'Enable debugging and network ADB in the TV developer settings, then trust CuteLauncher. All ADB actions are at your own risk.';

  @override
  String get adbConnectionBlock => 'ADB connection';

  @override
  String get adbNotChecked => 'Connection not checked';

  @override
  String get adbApplied => 'Already applied';

  @override
  String get adbNotApplied => 'Not applied yet';

  @override
  String get adbDefaultBlock => 'Default launcher';

  @override
  String get adbSystemDefault => 'Open system default launcher setting';

  @override
  String get adbAssignDefault => 'Set CuteLauncher as default launcher via ADB';

  @override
  String get adbRestoreDefault =>
      'Restore the previous default launcher via ADB';

  @override
  String get adbDefaultHint =>
      'Use ADB if the system menu cannot set the default launcher.';

  @override
  String get adbBuiltinHint =>
      'Disabling the built-in launcher lets the system open CuteLauncher instead. TV menus and buttons may be affected. Enable the built-in launcher to undo this.';

  @override
  String get adbHomeBlock => 'Home button and startup';

  @override
  String get adbEnableService =>
      'Enable CuteLauncher accessibility service via ADB';

  @override
  String get adbHomeOverride => 'Override the Home button';

  @override
  String get adbHomeOptional =>
      'If the built-in launcher is disabled, overriding Home and launching at TV startup are optional.';

  @override
  String get adbEnableBuiltin => 'Enable built-in launcher via ADB';

  @override
  String get adbDisableBuiltin => 'Disable built-in launcher via ADB';

  @override
  String get adbNoBuiltin =>
      'No built-in Google TV / Android TV launchers found.';

  @override
  String get adbChanged =>
      'State changed. Check the connection and confirm the action again.';

  @override
  String get adbEffectHome =>
      'CuteLauncher will become the system default launcher. The current launcher will be saved for restoration.';

  @override
  String get adbEffectRestore =>
      'The previous launcher will be enabled and made default. If unavailable or not saved, the first available other launcher is selected. This does not disable Home Button Fix.';

  @override
  String get adbEffectDisable =>
      'The built-in launcher app will be disabled for the TV user. TV menus and buttons may stop working. The app is not uninstalled.';

  @override
  String get adbRecoveryHomeDisable =>
      'The entire Google TV setup wizard, including its recovery home screen, will also be disabled so that CuteLauncher can become the default launcher. Setup wizard features will be unavailable until restoration. The original states of both packages will be saved for restoration.';

  @override
  String get adbRecoveryHomeRestore =>
      'The Google TV setup wizard will also return to its saved state.';

  @override
  String get adbDisableHomeUnavailable =>
      'Another home screen has a higher priority. It cannot be disabled safely by this launcher.';

  @override
  String get adbEffectEnable =>
      'The built-in launcher will be restored to its saved state, or enabled if no state was saved. The system may select it as the default launcher again.';

  @override
  String get adbEffectAccessibility =>
      'CuteLauncher accessibility service will be enabled. It can receive Home events; interception is controlled by a separate switch. Other services are preserved.';

  @override
  String get adbEffectAccessibilityRestore =>
      'CuteLauncher service will return to its state before ADB access was granted. Other accessibility services are preserved.';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher will be allowed to display windows over other apps, including the night filter.';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher will receive notification access through its own listener service.';

  @override
  String get adbEffectWatchNext =>
      'CuteLauncher will receive access to Continue watching data.';

  @override
  String get adbEffectUsage =>
      'CuteLauncher will receive usage statistics access for traffic and foreground app detection.';

  @override
  String get adbEffectWriteSettings =>
      'CuteLauncher will be allowed to change system brightness settings.';

  @override
  String get adbNoAvailableLauncher =>
      'No other installed launchers were found. Restoration is unavailable.';

  @override
  String get adbUnsupported =>
      'Unavailable on this device: no supported ADB command.';

  @override
  String get adbHomeUnavailable =>
      'The built-in launcher has system priority. Direct assignment through ADB is unavailable; use accessibility or disable the built-in launcher.';

  @override
  String get nightBatteryExempt => 'CuteLauncher is exempt from optimization';

  @override
  String get nightBatteryHint =>
      'May help the schedule run in the background. Does not guarantee the process survives standby.';

  @override
  String get nightBatteryOptimized => 'CuteLauncher is subject to optimization';

  @override
  String get nightBatteryTitle => 'Battery optimization';

  @override
  String get nightBatteryUnavailable =>
      'System settings are unavailable on this firmware or access was denied.';

  @override
  String get nightBatteryUnknown => 'Exemption status unknown';

  @override
  String get nightBatteryOpenApps => 'Open Apps settings';

  @override
  String get nightBatteryGuide =>
      '1. In Apps settings, open Special app access.\n2. Select Battery optimization (sometimes Energy saver).\n3. Find CuteLauncher; select All apps if needed.\n4. Disable optimization or select Unrestricted.\nMenu names and availability depend on the TV firmware.';

  @override
  String get updateNotifications => 'Show update notifications';

  @override
  String get diagnosticsSave => 'Save report to file';

  @override
  String get diagnosticsSaved => 'Report saved';

  @override
  String get diagnosticsSaveFailed =>
      'Could not save the report. Check the file manager and destination folder.';

  @override
  String get memoryCacheSize => 'Image cache size';

  @override
  String get memoryProcess => 'App memory';

  @override
  String get memoryImages => 'Image caches';

  @override
  String get diagnosticsExportOpened =>
      'Choose a folder in the file manager and save the report.';

  @override
  String get adbDisableService =>
      'Disable CuteLauncher accessibility service via ADB';

  @override
  String get adbDefaultSettings => 'Default launcher settings';

  @override
  String get adbHomeSettings => 'Home button settings';

  @override
  String get adbAccessibilitySettings => 'Open accessibility settings';

  @override
  String get adbAccessibilityGuide =>
      'Select CuteLauncher in the system menu and enable its service. Return here to configure Home interception. To disable it, turn off the CuteLauncher service in the same menu.';

  @override
  String get adbEffectAccessibilityDisable =>
      'The CuteLauncher service will be disabled. Home interception will stop. Other accessibility services are preserved.';

  @override
  String get backupAutoEnabled => 'Automatic backup';

  @override
  String get backupClientId => 'Client ID';

  @override
  String get backupClientSecret => 'Client Secret';

  @override
  String get backupCloudImportConfirm =>
      'All local settings, categories and images will be replaced with cloud data. Continue?';

  @override
  String get backupConfigured => 'Configured';

  @override
  String get backupConnection => 'Connection settings';

  @override
  String get backupCreated => 'Created';

  @override
  String get backupDaily => 'Daily';

  @override
  String get backupDriveHelp =>
      'Select Connect and confirm the code on your phone. Backups are visible in the CuteLauncher folder in Google Drive, where you can download or delete them. Keep file names unchanged for in-app restore. Reconnect after upgrading from hidden backups; old backups are not migrated automatically.';

  @override
  String get backupFrequency => 'Backup frequency';

  @override
  String get backupHourly => 'Hourly';

  @override
  String get backupLocal => 'Local copies';

  @override
  String get backupMinutes => 'min';

  @override
  String get backupMode => 'Mode';

  @override
  String get backupNever => 'No backup yet';

  @override
  String get backupNotConfigured => 'Not configured';

  @override
  String get backupOptions => 'Backup options';

  @override
  String get backupSaveMode => 'Backup';

  @override
  String get backupScope => 'Backup across TVs';

  @override
  String get backupSyncScope => 'Synchronization across TVs';

  @override
  String get backupSeparate => 'Separate for each TV';

  @override
  String get backupShared => 'Same settings for all TVs';

  @override
  String get backupStorage => 'Storage';

  @override
  String get backupSyncHelp =>
      'Download data and upload changes. The latest change wins conflicts. TV clocks must be correct. Synchronization runs while the launcher is open.';

  @override
  String get backupSyncLimit => 'Check no more often than';

  @override
  String get backupSyncMode => 'Synchronization';

  @override
  String get backupSyncOptions => 'Synchronization options';

  @override
  String get backupTime => 'Backup time';

  @override
  String get backupWeekday => 'Day of week';

  @override
  String get backupWeekly => 'Weekly';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'Local copies are deleted with the app or its data. Keep a copy outside the TV too.';

  @override
  String get panelObjectOrder => 'Object order';

  @override
  String get panelInformationGroup => 'Information';

  @override
  String get panelOrderHint =>
      '◄ / ► selects or finishes moving; ▲ / ▼ reorders objects and moves them between sides at group boundaries; OK / Back finishes moving.';

  @override
  String get panelTextBackgroundTransparency =>
      'Text and button background transparency';

  @override
  String get weatherCityHint =>
      'Enter the city name in English, for example Moscow.';

  @override
  String get weatherCityNotFound =>
      'City not found. Check the city name in English.';

  @override
  String get weatherLocationAutomatic => 'Get automatically';

  @override
  String get weatherLocationAutomaticHint =>
      'Get device coordinates. Location permission is required.';

  @override
  String get weatherLocationManual => 'Enter manually';

  @override
  String get weatherLocationPermissionDenied =>
      'Allow location access in Android settings and try again.';

  @override
  String get weatherLocationUnavailable =>
      'Could not obtain coordinates. Check Android location settings or enter a city manually.';

  @override
  String get nightFilterSettings => 'Filter settings';

  @override
  String get nightScheduleMenu => 'Schedule';

  @override
  String get nightScheduleInactive => 'Schedule is off';

  @override
  String get nightLocation => 'Location';

  @override
  String get nightLocationAutomatic => 'Get automatically';

  @override
  String get nightLocationManual => 'Enter manually';

  @override
  String get nightLocationFailed =>
      'Location unavailable. Check permission and system location settings.';

  @override
  String get nightCityEnglish => 'Enter the city name in English';

  @override
  String get nightOverlayBrief =>
      'Allows the filter to appear over other apps.';

  @override
  String get weatherGetLocation => 'Get location';

  @override
  String get backupLastCreated => 'Last backup was created:';

  @override
  String get backupManagement => 'Manage backups';

  @override
  String get backupCopyList => 'Backup list';

  @override
  String get backupRefreshCopyList => 'Refresh backup list';

  @override
  String get backupCreateNow => 'Create a new backup now';

  @override
  String get backupFolderPath => 'Backup folder';

  @override
  String get backupPrivateFolder => 'Private application folder';

  @override
  String get backupRestoreCopy => 'Restore this backup';

  @override
  String get backupDeleteConfirm => 'Delete the selected backup?';

  @override
  String get blockedAppsGroup => 'Blocked apps';

  @override
  String get notificationSettingsButton => 'Notification settings';

  @override
  String get hidePersistentNotificationsHint =>
      'Hide persistent notifications in the list and over other apps.';

  @override
  String get nightTransitionTime => 'Transition time';

  @override
  String get brightnessSolar => 'Use night mode schedule';

  @override
  String get brightnessAfterSunrise => 'After sunrise';

  @override
  String get brightnessAfterSunset => 'After sunset';

  @override
  String get brightnessTransitionTime => 'Brightness transition time';

  @override
  String get brightnessSolarUnavailable =>
      'Night mode schedule is unavailable. Check its times and location.';

  @override
  String get persistentNotificationCannotDelete =>
      'This persistent notification cannot be deleted. You can only block it.';

  @override
  String get diagnosticsCreateFailed =>
      'Could not create the diagnostic report. Try again.';

  @override
  String get backupListFailed =>
      'Could not load the backup list. Check access to the selected storage.';

  @override
  String get updateInstallerFailed =>
      'Could not open the update installer. Try again and check that the Android installer is available.';

  @override
  String get backupFolderFailed =>
      'Could not select or save the backup folder. Choose an accessible folder and try again.';

  @override
  String get updateDownloadFailed =>
      'Could not download the update. Check your internet connection and available storage.';

  @override
  String get backupDeleteFailed =>
      'Could not delete the backup. Check delete permissions and try again.';

  @override
  String get updateCheckFailed =>
      'Could not check for updates. Check your internet connection and try again.';

  @override
  String get backupCreateFailed =>
      'Could not create the backup. Check storage access and available space.';

  @override
  String get wallpaperChangeFailed =>
      'Could not change the wallpaper. Check file access and try again.';

  @override
  String get backupDownloadsFolder => 'Downloads / CuteLauncher';

  @override
  String get backupChooseFolder => 'Choose a folder in file manager';

  @override
  String get backupFolderPickerUnavailable =>
      'No folder picker is available on this TV. Choose Downloads / CuteLauncher or the internal app folder.';

  @override
  String get driveConfigurationError =>
      'Google Drive credentials are missing or invalid. Enter the Client ID and Client Secret of your TV OAuth client.';

  @override
  String get driveCodeExpired =>
      'Google Drive sign-in timed out. Select Check and save account to get a new code.';

  @override
  String get brightnessAfterNightStart => 'Nighttime';

  @override
  String get brightnessAfterNightEnd => 'Daytime';

  @override
  String get backupSyncSettings => 'Settings to synchronize';

  @override
  String get backupSyncHomeGroup => 'Home screen, sections and apps';

  @override
  String get backupSyncAppearanceGroup => 'Appearance, wallpapers and banners';

  @override
  String get backupSyncDisplayGroup => 'Night mode, brightness and screensaver';

  @override
  String get backupSyncControlsGroup => 'Launcher and TV controls';

  @override
  String get backupSyncGeneralGroup => 'Language, updates and other settings';

  @override
  String get backupSyncGroupsHelp =>
      'Disabled blocks stay local to this TV. The block selection is synchronized between devices.';

  @override
  String get backupSyncGroupsFailed =>
      'Could not save the settings selection for synchronization. Try again.';

  @override
  String get tileLayoutMode => 'Tile layout';

  @override
  String get tileLayoutAuto => 'Automatic by tile size';

  @override
  String get tileLayoutColumns => 'Fixed column count';

  @override
  String get tileLayoutRows => 'Fixed row count';

  @override
  String get tileRowCount => 'Row count';

  @override
  String get useGlobalTileSettings => 'Use global settings';

  @override
  String get centerSelection => 'Selection position';

  @override
  String get selectionBottom => 'Bottom';

  @override
  String get selectionLower => 'Lower middle';

  @override
  String get selectionCenter => 'Center';

  @override
  String get selectionUpper => 'Upper middle';

  @override
  String get selectionTop => 'Top';

  @override
  String get settingsStyle => 'Settings style';

  @override
  String get tileFocusEnlargement => 'Focus enlargement';

  @override
  String get tileFocusShadowStrength => 'Shadow strength';

  @override
  String get tileFocusLift => 'Lift';

  @override
  String get tileFocusLiftHeight => 'Lift height';

  @override
  String get tileFocusBorderColor => 'Focus border color';

  @override
  String get tileFocusAccentColor => 'Accent color';

  @override
  String get tileFocusDynamicColor => 'Dynamic colors';

  @override
  String get tileSizeFromColumns =>
      'Tile size is determined by the column count and section width.';

  @override
  String get resetSectionToGlobal => 'Reset settings to shared values';

  @override
  String get resetSectionToGlobalHint =>
      'Restore shared section titles, icons and background, and reset padding?';

  @override
  String get resetStyleSection => 'Reset this section';

  @override
  String get resetStyleSectionHint => 'Restore defaults for this section only?';

  @override
  String get notificationStyle => 'Notification style';

  @override
  String get styleBackgroundColor => 'Background color';

  @override
  String get styleTransparency => 'Background transparency';

  @override
  String get styleTextSize => 'Text size';

  @override
  String get styleTextColor => 'Text color';

  @override
  String get noticeSize => 'Notification size';

  @override
  String get noticeStylePreview => 'Notification preview';

  @override
  String get backupSyncHomeOptions => 'Behavior and general options';

  @override
  String get backupSyncBackground => 'Background and custom banners';

  @override
  String get backupSyncTiles => 'Tile, menu and notification style';

  @override
  String get backupSyncWeatherSource => 'Source and location';

  @override
  String get backupSyncWeatherDisplay =>
      'Weather display and temperature units';

  @override
  String get backupSyncNotificationSettings =>
      'Notification display and filters';

  @override
  String get backupSyncOther => 'Other settings';

  @override
  String get tileFocusBorderStyle => 'Border style';

  @override
  String get tileFocusOutline => 'Outline';

  @override
  String get tileFocusGlow => 'Glow';

  @override
  String get tileFocusNoBorder => 'No border';

  @override
  String get tileShowFocusShadow => 'Show shadow';

  @override
  String get homeLayoutRow => 'Horizontal row';

  @override
  String get homeLayoutRows => 'Multiple rows';

  @override
  String get homeLayoutGrid => 'Grid';

  @override
  String get homeCardCount => 'Visible cards across';

  @override
  String get homeAuto => 'Auto';

  @override
  String get homeFree => 'Free scrolling';

  @override
  String get homeAnchored => 'Anchored section';

  @override
  String get homeScrollMode => 'Section scrolling';

  @override
  String get homeSectionPosition => 'Active section position';

  @override
  String get homeLabelMode => 'Application labels';

  @override
  String get homeLabelNone => 'No labels';

  @override
  String get homeLabelSelected => 'Selected application only';

  @override
  String get homeLabelAll => 'All applications';

  @override
  String get homeInherited => 'Inherited value';

  @override
  String get homeOwnReset => 'Restore common settings';

  @override
  String get homeParameters => 'Parameters';

  @override
  String get homeSectionStyle => 'Section appearance';

  @override
  String get homeSectionGap => 'Space between sections';

  @override
  String get homeSectionIcons => 'Section icons';

  @override
  String get homeInactiveOpacity => 'Inactive section opacity';

  @override
  String get homeResetSection => 'Restore inherited section appearance';

  @override
  String get homeCalculatedSize => 'Size is calculated from the card count';

  @override
  String homeGapLimited(int gap) {
    return 'Spacing is limited to $gap to keep the selected card count.';
  }

  @override
  String get homeResetLayout => 'Reset section layout';

  @override
  String homeVisibleRows(int count) {
    return 'Fully visible rows: $count';
  }

  @override
  String get homeStylePartial =>
      'Applies only to sections that inherit this value and support it in their current layout.';

  @override
  String get homeStyleUnavailable =>
      'Unavailable in the current section settings. Check the layout and local overrides.';

  @override
  String get homeStyleNeedsRows => 'Available for multiple rows or a grid.';

  @override
  String get homeStyleNeedsLabels =>
      'Enable labels to change their size and color.';

  @override
  String get homeStyleNeedsAllLabels =>
      'Position applies only to labels on all cards. The selected title stays below the section.';

  @override
  String get homeStyleNeedsScale => 'Select the enlargement focus effect.';

  @override
  String get homeStyleNeedsLift => 'Select the lift focus effect.';

  @override
  String get homeStyleNeedsBorder => 'Enable an outline or glow first.';

  @override
  String get homeStyleNeedsTitle =>
      'Enable the section title to show its icon.';

  @override
  String get homeStyleEconomy =>
      'Disabled by memory saving. The saved value is retained.';

  @override
  String get homeStyleOpaque =>
      'Reduce the tile background opacity to see blur.';

  @override
  String get homeStyleOverridden =>
      'Visible sections use their own values. Choose “Use global” in a section to apply this setting.';

  @override
  String get homeStyleIconHint =>
      'Icon size affects cards with an app icon. TV banners fill the card independently.';

  @override
  String get homeStyleShadowHint =>
      'Memory saving limits the shadow of inactive cards to 4. Focus shadow is configured separately.';

  @override
  String get homeStyleTransparent =>
      'The background color is invisible at zero opacity. Increase the tile background opacity.';

  @override
  String get homeStyleSingleColumn =>
      'A single-column grid has no horizontal gaps.';

  @override
  String get homeStyleAutoOnly =>
      'Size changes only in sections with Auto card count that inherit the global size.';

  @override
  String get sleepTimerThirtySeconds => '30 seconds (test)';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1.5 hours';

  @override
  String get sleepTimerAllowExact => 'Allow precise timers';

  @override
  String get sleepTimerExactRequired =>
      'Allow precise timers in Android settings, then select a duration again.';

  @override
  String get sleepTimerAccessRequired =>
      'Enable CuteLauncher accessibility or connect local ADB in Settings → Other → ADB.';

  @override
  String get sleepTimerFailed =>
      'Could not set or complete the sleep timer. Check accessibility and local ADB.';

  @override
  String get nightIgnoreHdmiInputs => 'Ignore HDMI inputs';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'Pause the night filter while watching HDMI. Usage access is required; input detection depends on the TV firmware.';

  @override
  String get inputsSettings => 'Input settings';

  @override
  String get inputsUseCecNames => 'Use device names from CEC';

  @override
  String get inputsNamesHint =>
      'Name priority: your name in CuteLauncher → CEC (if enabled) → name from Android settings → standard input name.';

  @override
  String get inputNameHint => 'Leave empty for an automatic name';

  @override
  String get inputsSaveFailed => 'Could not save input settings';

  @override
  String get inputIcon => 'Input icon';

  @override
  String get inputIconTv => 'TV';

  @override
  String get inputIconGame => 'Game console';

  @override
  String get inputIconComputer => 'Computer';

  @override
  String get inputIconReceiver => 'Receiver';

  @override
  String get inputIconDisc => 'Disc player';

  @override
  String get inputIconStream => 'Streaming device';

  @override
  String get nightInputExclusions => 'Input exclusions';

  @override
  String get nightSelectInputs => 'Select inputs to ignore';

  @override
  String get nightNoInputsSelected =>
      'No inputs selected. The filter will apply to every input.';

  @override
  String get nightPictureExclusions => 'Picture mode exclusions';

  @override
  String get nightPictureExclusionsHint =>
      'Select modes that pause dimming, the warm overlay and the linked TCL filter. The schedule is preserved. Detection has been verified on TCL; usage access is not required.';

  @override
  String get nightPictureUnavailable =>
      'The current picture mode is unavailable on this firmware. Your selection is saved; exclusions apply only when detection succeeds.';

  @override
  String get nightPictureCurrent => 'Current mode';

  @override
  String get nightPictureRefresh => 'Refresh current mode';

  @override
  String get nightPictureCode => 'Mode code';

  @override
  String get nightPictureStandard => 'Standard';

  @override
  String get nightPictureDynamic => 'Dynamic';

  @override
  String get nightPictureMovie => 'Movie';

  @override
  String get nightPictureSport => 'Sport';

  @override
  String get nightPictureIntelligent => 'Intelligent';

  @override
  String get nightPictureBright => 'Bright (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'Standard';

  @override
  String get systemApplications => 'System apps';

  @override
  String get removeFromCategory => 'Remove from category';

  @override
  String get noRemovableCategories =>
      'This app has not been manually added to any sections. Apps cannot be removed from the standard automatic sections (All Apps, TV Apps, Non-TV Apps); use Hide. Favorites can be edited manually.';

  @override
  String get remoteButtonsTitle => 'Remote button remapper';

  @override
  String get remoteButtonsStart => 'Check buttons (120 s)';

  @override
  String get remoteButtonsStop => 'Stop checking';

  @override
  String get remoteButtonsHint =>
      'Start the test, then press buttons in any menu or open app. Stop it here or wait 120 seconds. After the test, the report is saved at the path below, replacing the previous report. Copy it using ADB: adb pull <path>. Some system and manufacturer buttons may be unavailable to the service.';

  @override
  String get remoteButtonsEmpty =>
      'No events yet. If a button opens an app, return here to see the result.';

  @override
  String get remoteButtonsService => 'Service connected';

  @override
  String get remoteButtonsRefresh => 'Refresh';

  @override
  String get remoteBindings => 'Button assignments';

  @override
  String get remoteMappingsEnabled => 'Enable remapping';

  @override
  String get remoteMappingsAdd => 'Add assignment';

  @override
  String get remoteMappingKey => 'Button';

  @override
  String get remoteMappingAction => 'Action';

  @override
  String get remoteMappingLearn => 'Learn a remote button';

  @override
  String get remoteMappingLearnHint =>
      'Press an extra remote button within 30 seconds. Navigation, Power, voice search and volume cannot be assigned.';

  @override
  String get remoteMappingsHint =>
      'Assignments require the accessibility service. They are paused in the editor and during diagnostics. Home, Back, arrows and OK keep their normal navigation.';

  @override
  String get remoteMappingsReset => 'Reset assignments';

  @override
  String get remoteMappingsResetConfirm =>
      'Delete all assignments and turn remapping off?';

  @override
  String get remoteMappingInvalid =>
      'Could not save. Check the button and target. Webhooks require HTTPS or HTTP on a local network.';

  @override
  String get remoteMappingBack => 'Back';

  @override
  String get remoteMappingProfile => 'Profile';

  @override
  String get remoteMappingChannels => 'Channels';

  @override
  String get remoteMappingQuickSettings => 'TCL quick settings';

  @override
  String get remoteMappingTrigger => 'Press type';

  @override
  String get remoteMappingPress => 'Short press';

  @override
  String get remoteMappingHold => 'Hold';

  @override
  String get remoteMappingHoldHint =>
      'Hold for 650 ms: fires once, without the short action. If only hold is assigned, a short tap does nothing.';

  @override
  String get remotePanelDescription =>
      'The quick settings panel keeps your widgets within reach over other apps. To open it with your remote, assign the Quick settings panel action to a button of your choice.';

  @override
  String get remotePanel => 'Quick settings panel';

  @override
  String get remotePanelSettingsBackground => 'Use settings background color';

  @override
  String get remotePanelPreview => 'Open panel';

  @override
  String get settingsHelp => 'More information';

  @override
  String get settingsHelpScroll => '▲ / ▼ — scroll text';

  @override
  String get panelClockStyle => 'Clock appearance';

  @override
  String get clockPreset => 'Font style';

  @override
  String get clockCustom => 'Custom';

  @override
  String get clockWeight => 'Font weight';

  @override
  String get clockGlow => 'Text glow';

  @override
  String get clockAnimate => 'Animate digits';

  @override
  String get clockBackground => 'Clock background';

  @override
  String get clockRadius => 'Background corner radius';

  @override
  String get dateCalendarEnabled => 'Open calendar when pressing the date';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get dateSettings => 'Date settings';

  @override
  String get clockSharedBackground =>
      'Use the same background as other objects';

  @override
  String get clockDefaultBackground => 'Default background';

  @override
  String get remotePanelInheritAppearance => 'Use top panel appearance';

  @override
  String get remotePanelDisabledInLauncher =>
      'The quick settings panel is disabled while CuteLauncher is on screen.';

  @override
  String get remoteAccessSettings => 'Access settings';

  @override
  String get remoteButtonsTest => 'Button test';

  @override
  String remoteMappingDeleteConfirm(String name) {
    return 'Delete the assignment “$name”?';
  }

  @override
  String get remoteMappingConflict =>
      'This button and press type are already assigned. Choose another button or press type.';

  @override
  String get cleanerTitle => 'TV cleanup manager';

  @override
  String get cleanerRefresh => 'Refresh applications';

  @override
  String get cleanerSnapshot => 'Save original state';

  @override
  String get cleanerRestore => 'Restore baseline state';

  @override
  String get cleanerSnapshotSaved => 'Original state saved';

  @override
  String get cleanerExportSnapshot => 'Export original state';

  @override
  String get cleanerSafe => 'Disable verified applications';

  @override
  String get cleanerNoSafe =>
      'No matching system application list exists for this model and firmware.';

  @override
  String get cleanerLocal => 'Disable using a local list';

  @override
  String get cleanerProject => 'Project catalog lists';

  @override
  String get cleanerRemoteProject => 'Refresh catalog from GitHub';

  @override
  String get cleanerExternal => 'CleanYourTV examples';

  @override
  String get cleanerDisabledExport => 'Export disabled-app report to file';

  @override
  String get cleanerInventoryExport => 'Export application report';

  @override
  String get cleanerApps => 'All applications';

  @override
  String get cleanerEnable => 'Enable application';

  @override
  String get cleanerDisable => 'Disable application';

  @override
  String get cleanerProtected => 'Protected from disabling';

  @override
  String get cleanerUnknown =>
      'Purpose and dependencies are unconfirmed. Disabling risk is unknown.';

  @override
  String get cleanerConfirm => 'Apply change?';

  @override
  String get cleanerConfirmText =>
      'The listed apps and related features will be affected. Original states are saved before changes. Recovery requires this launcher and ADB to remain available.';

  @override
  String get cleanerObserved =>
      'Observed list: disabling safety has not been verified.';

  @override
  String get cleanerMismatch =>
      'The list belongs to a different firmware and will not be applied.';

  @override
  String get cleanerMissing => 'No available packages to change.';

  @override
  String get cleanerFailure =>
      'Action did not complete. Check ADB connectivity and the list format.';

  @override
  String get cleanerPartial =>
      'Changes completed partially. Recovery journal is saved; refresh the list and restore if needed.';

  @override
  String get cleanerDone => 'Done';

  @override
  String get cleanerSaved => 'File saved or handed to the file manager';

  @override
  String get cleanerGitUnavailable =>
      'Catalog unavailable. For private Git, use the bundled catalog or a file; no access tokens are stored in the APK.';

  @override
  String get cleanerSystem => 'System application';

  @override
  String get cleanerUser => 'User application';

  @override
  String get cleanerRisk => 'Disabling risk';

  @override
  String get cleanerHelp =>
      'The manager uses local ADB to change app availability without removing APKs or app data. The baseline and manual states are in Backup and recovery. Observed lists and external examples do not prove that disabling is safe. Reports are saved to files and submitted to the project Git manually; nothing is uploaded automatically.';

  @override
  String get cleanerSkipped =>
      'Skipped: protected, missing or already in the requested state';

  @override
  String get cleanerUnidentified => 'Application not identified.';

  @override
  String get cleanerPending => 'Changed by manager';

  @override
  String get cleanerNoSnapshot => 'Original state not saved yet';

  @override
  String get interfaceStyle => 'Interface style';

  @override
  String get interfaceStandard => 'Standard';

  @override
  String get interfaceGlass => 'Glass';

  @override
  String get interfaceSoft => 'Soft';

  @override
  String get interfaceOutline => 'Outline';

  @override
  String get interfaceFont => 'Interface font';

  @override
  String get interfaceSystemFont => 'System';

  @override
  String get combinedInformation => 'Combine time, date and weather';

  @override
  String get adaptiveLandscape => 'Adaptive landscape';

  @override
  String get landscapeDemoSpring => 'Spring';

  @override
  String get landscapeDemoSummer => 'Summer';

  @override
  String get landscapeDemoAutumn => 'Autumn';

  @override
  String get landscapeDemoWinter => 'Winter';

  @override
  String get landscapeDemoClear => 'Clear';

  @override
  String get landscapeDemoCloudy => 'Cloudy';

  @override
  String get landscapeDemoFog => 'Fog';

  @override
  String get landscapeDemoStart => 'Demonstrate changes';

  @override
  String get landscapeDemoStop => 'Stop';

  @override
  String get landscapeVariant => 'Landscape style';

  @override
  String get landscapeIllustrated => 'Illustrated';

  @override
  String get landscapeRealistic => 'Realistic';

  @override
  String get landscapeTimeOfDay => 'Time of day';

  @override
  String get landscapeSeasons => 'Seasons';

  @override
  String get landscapeHemisphere => 'Hemisphere';

  @override
  String get landscapeAuto => 'Automatic';

  @override
  String get landscapeNorth => 'Northern';

  @override
  String get landscapeSouth => 'Southern';

  @override
  String get landscapeClouds => 'Clouds';

  @override
  String get landscapePrecipitation => 'Rain and snow';

  @override
  String get landscapeFog => 'Fog';

  @override
  String get landscapeMotion => 'Animate weather';

  @override
  String get landscapeHelp =>
      'Time follows cached sunrise and sunset from Night mode; without them, dawn is at 06:00 and dusk at 18:00, with 40-minute transitions around each. Seasons follow the local month and hemisphere; automatic hemisphere uses weather coordinates, then Night mode coordinates, then the Northern Hemisphere. With time of day off, the scene stays in daylight; with seasons off, it stays in summer. Weather uses current data from the selected weather source, without extra requests. Missing or stale weather shows clear skies. Clouds, precipitation and fog can be disabled independently. Motion is off by default, stops when Home is hidden, and is disabled in memory saving mode or when reduced motion is requested.';

  @override
  String get inputConnected => 'Connected';

  @override
  String get inputStandby => 'Connected · standby';

  @override
  String get inputDisconnected => 'Disconnected';

  @override
  String get inputStateUnknown => 'Connection status unavailable';

  @override
  String get weatherMetNorwayCredit =>
      'Data: MET Norway, CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Forecast adapted from https://api.met.no/. No API key; days use the TV time zone, min/max cover available periods. Precipitation probability is unavailable.';

  @override
  String get informationGroup => 'Clock, date and weather';

  @override
  String get informationSettings => 'Block settings';

  @override
  String get informationAppearance => 'Block appearance';

  @override
  String get informationSize => 'Block size';

  @override
  String get informationPosition => 'Clock and text position';

  @override
  String get informationClockLeft => 'Clock left, text right';

  @override
  String get informationClockRight => 'Text left, clock right';

  @override
  String get informationSpacing => 'Space between clock and text';

  @override
  String get informationBackground => 'Block background';

  @override
  String get homeResetTilesHint =>
      'Restore common values for all tiles and labels on this screen?';

  @override
  String get homeResetLayoutHint =>
      'Reset this section’s layout, restore its common appearance and reset padding? Apps and their order will be kept.';

  @override
  String get networkSummary => 'Network';

  @override
  String get networkConnected => 'Internet available';

  @override
  String get networkOffline => 'No internet access';

  @override
  String get networkDisconnected => 'Disconnected';

  @override
  String get networkConnection => 'Connection';

  @override
  String get networkSignal => 'Signal';

  @override
  String get networkLinkSpeed => 'Wi-Fi link speed';

  @override
  String get networkTrafficRate => 'Device traffic · receive / send';

  @override
  String get networkSystemSettings => 'System network settings';

  @override
  String get networkUnavailable => 'Unavailable';

  @override
  String get networkMobile => 'Mobile network';

  @override
  String get networkFrequency => 'Frequency';

  @override
  String get networkMbps => 'Mbps';

  @override
  String get networkKbps => 'KB/s';

  @override
  String get networkReadFailed => 'Could not read network status';

  @override
  String get clockItalic => 'Italic';

  @override
  String get panelWrapNavigation => 'Wrap panel navigation';

  @override
  String get panelWrapNavigationHelp =>
      'Left and right wrap between the outermost panel buttons. Hold an arrow to keep moving across both sides.';

  @override
  String get networkReceive => 'Receive';

  @override
  String get networkSend => 'Send';

  @override
  String get landscapeCelestialBodies => 'Sun and moon';

  @override
  String get landscapeStarRotation => 'Star rotation';

  @override
  String get tvPowerTitle => 'Power management';

  @override
  String get tvPowerOff => 'Turn off TV';

  @override
  String get tvPowerReboot => 'Restart TV';

  @override
  String get tvPowerOffConfirm => 'Put the TV in standby?';

  @override
  String get tvPowerRebootConfirm => 'Restart the TV? Open apps will close.';

  @override
  String get tvPowerSent => 'Command sent';

  @override
  String get tvPowerFailed =>
      'Could not send the command. Check ADB or accessibility access.';

  @override
  String get tvPowerHelp =>
      'Turning off puts the TV in standby through the CuteLauncher accessibility service or local ADB. Restart requires ADB. On a TV box, the command controls the box; TV behavior depends on HDMI-CEC and firmware.';

  @override
  String get cleanerLists => 'Disable lists';

  @override
  String get cleanerRecovery => 'Backup and recovery';

  @override
  String get cleanerExports => 'Reports';

  @override
  String get cleanerUpdating => 'Updating application list…';

  @override
  String get cleanerRefreshRequired => 'Refresh the application list first.';

  @override
  String get cleanerPreinstalled => 'Preinstalled application';

  @override
  String get cleanerNotSystem => 'This is not a system application.';

  @override
  String get cleanerMinimalRisk => 'Minimal';

  @override
  String get cleanerCacheFailure =>
      'Could not save the list for the next visit.';

  @override
  String get cleanerUserApps => 'User applications';

  @override
  String get cleanerPreinstalledApps => 'Preinstalled applications';

  @override
  String get cleanerSystemApps => 'System applications';

  @override
  String get cleanerBaseline => 'Baseline original state';

  @override
  String get cleanerManualStates => 'Manage manual states';

  @override
  String get cleanerManualSave => 'Save current state';

  @override
  String get cleanerDateName => 'Use date and time';

  @override
  String get cleanerCustomName => 'Enter a name';

  @override
  String get cleanerStateExport => 'Export saved state to file';

  @override
  String get cleanerStateRestoreHelp =>
      'Saved enabled and disabled application states for this firmware will be restored. Apps installed after the copy was created remain unchanged. Missing apps and attempts to disable protected components are skipped. App data is not restored.';

  @override
  String get cleanerCopiesHelp =>
      'The baseline is created once on the first successful list refresh. The launcher cannot delete or overwrite it. It is tied to the firmware. Manual states capture current app modes with a name and date and can be restored, deleted or exported. Copies contain neither APKs nor app data. Recovery requires local ADB. When crash-loop protection activates, the launcher attempts to restore the baseline automatically. Clearing launcher data or uninstalling it also removes these copies; root access cannot be prevented.';

  @override
  String get cleanerSearch => 'Search by name';

  @override
  String get cleanerCatalogUpdateRequired =>
      'Refresh the catalog from GitHub first.';

  @override
  String get cleanerNoSearchResults => 'No matching entries.';

  @override
  String get cleanerAlreadyDisabled =>
      'All applications from this list present on this TV are already disabled.';

  @override
  String get cleanerAlreadyEnabled =>
      'All applications from this list present on this TV are already enabled.';

  @override
  String get cleanerNoInstalled =>
      'No matching applications from this list are installed on this TV.';

  @override
  String get cleanerListProtected =>
      'The remaining applications are protected from disabling.';

  @override
  String get cleanerSnapshotFailed =>
      'Could not save the snapshot. No applications were disabled.';

  @override
  String get cleanerDisableAllPreinstalled => 'Disable all preinstalled apps';

  @override
  String get cleanerEnableAllPreinstalled => 'Enable all preinstalled apps';

  @override
  String get cleanerPreinstalledList => 'Preinstalled application list';

  @override
  String cleanerBeforeList(String listName) {
    return 'Before applying list: $listName';
  }

  @override
  String get sleepTimerSettings => 'Sleep timer settings';

  @override
  String get sleepTimerPresets => 'Timers';

  @override
  String get sleepTimerDisplay => 'Display while active';

  @override
  String get sleepTimerRemaining => 'Time remaining';

  @override
  String get sleepTimerEndTime => 'Shutdown time';

  @override
  String get sleepTimerBoth => 'Remaining and shutdown time';

  @override
  String get sleepTimerShowSeconds => 'Show seconds';

  @override
  String get sleepTimerCloseAfterSelection =>
      'Close widget after selecting a timer';

  @override
  String get sleepTimerAdd => 'Add timer';

  @override
  String get sleepTimerEdit => 'Edit timer';

  @override
  String get sleepTimerHoursLabel => 'Hours';

  @override
  String get sleepTimerMinutesLabel => 'Minutes';

  @override
  String get sleepTimerSecondsLabel => 'Seconds';

  @override
  String get sleepTimerInvalidDuration =>
      'Enter a positive duration: hours 0–999999, minutes and seconds 0–59.';

  @override
  String get sleepTimerDeleteConfirmation =>
      'Delete this timer? The running countdown will continue.';

  @override
  String get sleepTimerResetConfirmation =>
      'Restore the default timers and their order? Custom timers will be removed. The running countdown will continue.';

  @override
  String get sleepTimerReorderHint =>
      '◄ / ► or hold OK to move. ▲ / ▼ changes order and moves timers between visible and hidden lists. OK finishes moving.';

  @override
  String get sleepTimerSaveFailed => 'Could not save timer settings.';

  @override
  String get sleepTimerVisible => 'Visible';

  @override
  String get sleepTimerHidden => 'Hidden';

  @override
  String get sleepTimerReset => 'Reset timers';

  @override
  String get cleanerListSnapshotHelp =>
      'Disabling a list automatically saves a snapshot of only the selected apps. Restoring it leaves other apps unchanged. The limit is 100 manual and automatic snapshots. If saving fails, disabling does not start.';

  @override
  String get trafficSettings => 'Traffic settings';

  @override
  String get trafficTitle => 'Traffic';

  @override
  String get trafficReceived => 'Received';

  @override
  String get trafficSent => 'Sent';

  @override
  String get trafficTotal => 'Total';

  @override
  String get stopApp => 'Stop';

  @override
  String get backgroundImageFormats =>
      'Images: JPEG, PNG, WebP, GIF, BMP — up to 8 MiB, 48 megapixels and 16,384 pixels per side.';

  @override
  String get backgroundMediaFormats =>
      'Images: JPEG, PNG, WebP, GIF, BMP — up to 8 MiB, 48 megapixels and 16,384 pixels per side.\nVideo: MP4/M4V, WebM, MKV — up to 256 MiB and 3840×2160. Codec support depends on the TV; MP4 with H.264 is preferred. Video loops silently and pauses outside Home. Videos are excluded from backups.';

  @override
  String get backgroundFormatError =>
      'Unsupported format or damaged file. Choose a valid file in one of the listed formats.';

  @override
  String backgroundFileTooLarge(String maxMiB) {
    return 'The file is too large. Maximum size: $maxMiB MiB. Choose a smaller file.';
  }

  @override
  String get backgroundImageResolutionError =>
      'The image is too large: up to 48 megapixels and 16,384 pixels per side.';

  @override
  String get backgroundVideoResolutionError =>
      'Video resolution is too high. Choose up to 3840×2160 (or 2160×3840).';

  @override
  String get backgroundVideoCodecError =>
      'The TV could not play this video: the codec is unsupported or the file is damaged. Try MP4 with H.264.';

  @override
  String get backgroundFileApplied => 'File selected. Background updated.';

  @override
  String get noticePosition => 'Notification position';

  @override
  String get noticeBottomRight => 'Bottom right';

  @override
  String get noticeBottomLeft => 'Bottom left';

  @override
  String get noticeTopRight => 'Top right';

  @override
  String get noticeTopLeft => 'Top left';

  @override
  String get notificationOpenFailed =>
      'Could not open the notification action. It may no longer be available.';

  @override
  String get adbWifiOverride => 'Disable anyway…';

  @override
  String get adbWifiRiskTitle => 'Disable despite the risk?';

  @override
  String get adbWifiRiskEffect =>
      'The built-in launcher and Google setup wizard will be disabled.';

  @override
  String get adbWifiRiskLoss =>
      'Android may delete saved Wi-Fi networks. Wi-Fi connectivity and wireless ADB may become unavailable.';

  @override
  String get adbWifiRiskRecovery =>
      'Re-enabling the setup wizard will not automatically restore deleted networks. You will need to reconnect to Wi-Fi and enter the password.';

  @override
  String get adbWifiRiskConsent =>
      'Continue only if you know the Wi-Fi password.';

  @override
  String get adbWifiDisable => 'Disable';

  @override
  String get recentAppsTitle => 'Open apps';

  @override
  String get recentAppsPanelType => 'Panel';

  @override
  String get recentAppsAutomatic => 'Automatic';

  @override
  String get recentAppsCustom => 'CuteLauncher panel';

  @override
  String get recentAppsSystem => 'Built-in panel';

  @override
  String get recentAppsOpen => 'Open panel';

  @override
  String get recentAppsRefresh => 'Refresh';

  @override
  String get recentAppsCloseAll => 'Close all';

  @override
  String get recentAppsEmpty => 'No TV apps with open tasks';

  @override
  String get recentAppsUnavailable =>
      'Open apps unavailable. Check ADB and accessibility access.';

  @override
  String get recentAppsHelp =>
      'Only TV apps with open tasks are shown. Close all stops user apps in this list. Assign a button in the remapper. The CuteLauncher panel needs ADB and accessibility access.';

  @override
  String get recentAppsHomeHint =>
      'Home supports hold only. A short press returns to CuteLauncher. The assignment also works outside the launcher.';

  @override
  String get sectionRulesHelp =>
      'Standard sections can be renamed, moved or hidden, but not deleted; at least one must stay visible. All Apps, TV Apps and Non-TV Apps are filled automatically by launch type, not app name; Hide removes an app from all three. Favorites and custom sections are filled manually. Sort apps manually, by name, frequency or last launch; adjust appearance per section. Continue Watching shows app recommendations and can be hidden or moved.';

  @override
  String get remoteMappingNamePlaceholder => 'Button name';

  @override
  String get remoteMappingAssign => 'Assign button';

  @override
  String get remoteMappingCapture => 'Capture';

  @override
  String remoteMappingCaptured(String key) {
    return 'Captured button: $key';
  }

  @override
  String get remoteMappingCaptureHint =>
      'Select Capture, then press the remote button. You can capture again. Select OK to accept.';

  @override
  String get remoteMappingCaptureTimeout =>
      'No button captured. Select Capture and try again.';

  @override
  String get remoteMappingCaptureFailed =>
      'Could not capture the button. Check accessibility service access and try again.';

  @override
  String get remoteMappingServiceRequired =>
      'Connect the accessibility service in the remapper access settings to capture a button.';

  @override
  String get remoteMappingKeyRequired =>
      'No button assigned. Select Assign button and capture a remote button.';

  @override
  String get remoteMappingHomeHoldRequired =>
      'Select Hold for the Home button.';

  @override
  String get remoteMappingAppRequired => 'Select an app to launch.';

  @override
  String get remoteMappingUrlRequired =>
      'Enter a Webhook URL or import it from a file.';

  @override
  String get remoteMappingUrlInvalid =>
      'Invalid Webhook URL. Use HTTPS or local HTTP with a request path, without spaces, credentials or a # fragment.';

  @override
  String get remoteMappingSaveFailed =>
      'Could not save the assignment on this device. Try saving again; your editor values are retained.';

  @override
  String get remoteMappingDeleteFailed =>
      'Could not delete the assignment on this device. Try again.';

  @override
  String get remoteMappingRecents => 'Open apps panel';

  @override
  String get remoteMappingImport => 'Import URL from file';

  @override
  String get remoteMappingImportHint =>
      'Choose a UTF-8 text file containing only the Webhook URL, without commands or explanations. Line breaks are removed.';

  @override
  String get remoteMappingImportInvalid =>
      'The file must contain only a valid Webhook URL: HTTPS or local HTTP, without commands or explanations.';

  @override
  String get remoteMappingImportFailed =>
      'Could not read the file. Choose an accessible UTF-8 text file up to 64 KB.';
}
