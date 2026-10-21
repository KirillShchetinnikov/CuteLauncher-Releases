import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh'),
  ];

  /// No description provided for @diagnosticsHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsHubTitle;

  /// No description provided for @tvCompatibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'TV compatibility check'**
  String get tvCompatibilityTitle;

  /// No description provided for @tvCompatibilityRun.
  ///
  /// In en, this message translates to:
  /// **'Run check'**
  String get tvCompatibilityRun;

  /// No description provided for @tvCompatibilityResults.
  ///
  /// In en, this message translates to:
  /// **'View results'**
  String get tvCompatibilityResults;

  /// No description provided for @compatibilityReportDate.
  ///
  /// In en, this message translates to:
  /// **'Check date'**
  String get compatibilityReportDate;

  /// No description provided for @compatibilityLauncherVersion.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher version'**
  String get compatibilityLauncherVersion;

  /// No description provided for @diagnosticsExport.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get diagnosticsExport;

  /// No description provided for @diagnosticsCopyClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get diagnosticsCopyClipboard;

  /// No description provided for @diagnosticsSaveDisk.
  ///
  /// In en, this message translates to:
  /// **'Save to disk'**
  String get diagnosticsSaveDisk;

  /// No description provided for @tvCompatibilityHelp.
  ///
  /// In en, this message translates to:
  /// **'Reads device, firmware, permission and system capability metadata. No settings, packages or HOME are changed; ADB is not connected, and no apps or system screens are launched. Results describe availability reported by Android, not physical remote, HDMI or end-to-end operation. Export includes the model and full firmware identity for the device catalog, without serial number, IP, Wi-Fi networks, accounts or installed app lists. Nothing is sent automatically. The latest report stays in memory until you leave Diagnostics; running a new check replaces it.'**
  String get tvCompatibilityHelp;

  /// No description provided for @compatibilityAndroidTv.
  ///
  /// In en, this message translates to:
  /// **'Android TV support'**
  String get compatibilityAndroidTv;

  /// No description provided for @compatibilityAndroidVersion.
  ///
  /// In en, this message translates to:
  /// **'Android version'**
  String get compatibilityAndroidVersion;

  /// No description provided for @compatibilityHomeRegistered.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher registered as HOME'**
  String get compatibilityHomeRegistered;

  /// No description provided for @compatibilityDefaultHome.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher selected as home screen'**
  String get compatibilityDefaultHome;

  /// No description provided for @compatibilityHomeSelection.
  ///
  /// In en, this message translates to:
  /// **'HOME selection priority'**
  String get compatibilityHomeSelection;

  /// No description provided for @compatibilityOverlay.
  ///
  /// In en, this message translates to:
  /// **'Display over other apps'**
  String get compatibilityOverlay;

  /// No description provided for @compatibilityNotifications.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher notifications'**
  String get compatibilityNotifications;

  /// No description provided for @compatibilityNotificationListener.
  ///
  /// In en, this message translates to:
  /// **'Notification access'**
  String get compatibilityNotificationListener;

  /// No description provided for @compatibilityAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility service'**
  String get compatibilityAccessibility;

  /// No description provided for @compatibilityWriteSettings.
  ///
  /// In en, this message translates to:
  /// **'Write system settings'**
  String get compatibilityWriteSettings;

  /// No description provided for @compatibilityUsageStats.
  ///
  /// In en, this message translates to:
  /// **'Usage statistics access'**
  String get compatibilityUsageStats;

  /// No description provided for @compatibilityWatchNext.
  ///
  /// In en, this message translates to:
  /// **'Watch Next access'**
  String get compatibilityWatchNext;

  /// No description provided for @compatibilityTvInputs.
  ///
  /// In en, this message translates to:
  /// **'System TV input list'**
  String get compatibilityTvInputs;

  /// No description provided for @compatibilityDocumentExport.
  ///
  /// In en, this message translates to:
  /// **'JSON export handler'**
  String get compatibilityDocumentExport;

  /// No description provided for @compatibilityScreensaverSelection.
  ///
  /// In en, this message translates to:
  /// **'System screensaver selection'**
  String get compatibilityScreensaverSelection;

  /// No description provided for @compatibilityAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available according to Android'**
  String get compatibilityAvailable;

  /// No description provided for @compatibilityNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Permission not granted'**
  String get compatibilityNotGranted;

  /// No description provided for @compatibilityNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured or list empty'**
  String get compatibilityNotConfigured;

  /// No description provided for @compatibilityRestricted.
  ///
  /// In en, this message translates to:
  /// **'System restriction detected'**
  String get compatibilityRestricted;

  /// No description provided for @compatibilityUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Support not detected'**
  String get compatibilityUnsupported;

  /// No description provided for @compatibilityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Could not determine'**
  String get compatibilityUnknown;

  /// No description provided for @appArtworkBackground.
  ///
  /// In en, this message translates to:
  /// **'Selected app colours'**
  String get appArtworkBackground;

  /// No description provided for @appArtworkBackgroundHelp.
  ///
  /// In en, this message translates to:
  /// **'The focused app\'s banner or icon becomes a soft colour background. The selected gradient appears before an image is ready or if it cannot be read. Changes pause while the launcher is in the background. Your other wallpapers are kept.'**
  String get appArtworkBackgroundHelp;

  /// No description provided for @adbWifiOwned.
  ///
  /// In en, this message translates to:
  /// **'Not changed: a saved Wi-Fi network belongs to the setup wizard. Forget that network and reconnect through Android Settings, then check again. Disabling the wizard could delete the network.'**
  String get adbWifiOwned;

  /// No description provided for @adbWifiUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not changed: the owners of saved Wi-Fi networks could not be verified. Disabling the setup wizard is blocked to protect your connection. Check ADB and try again; some firmware does not provide this information.'**
  String get adbWifiUnknown;

  /// No description provided for @backgroundSource.
  ///
  /// In en, this message translates to:
  /// **'Background source'**
  String get backgroundSource;

  /// No description provided for @noAvailableCategories.
  ///
  /// In en, this message translates to:
  /// **'There are no sections available to add this app to.'**
  String get noAvailableCategories;

  /// No description provided for @redditWallpaperTheme.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper theme'**
  String get redditWallpaperTheme;

  /// No description provided for @redditThemeAll.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get redditThemeAll;

  /// No description provided for @redditThemeNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get redditThemeNature;

  /// No description provided for @redditThemeSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get redditThemeSpace;

  /// No description provided for @redditThemeCity.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get redditThemeCity;

  /// No description provided for @redditThemeMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimalism'**
  String get redditThemeMinimal;

  /// No description provided for @redditWallpaperResolution.
  ///
  /// In en, this message translates to:
  /// **'Minimum resolution'**
  String get redditWallpaperResolution;

  /// No description provided for @redditWallpaperHint.
  ///
  /// In en, this message translates to:
  /// **'Each successful refresh downloads a different landscape image from the selected Reddit community. Resolution is the minimum original size; images are not upscaled. Refresh runs while the launcher is open and resumes when you return. Adult content, videos and galleries are skipped. If Reddit blocks access or no matching image is found, the previous wallpaper remains.'**
  String get redditWallpaperHint;

  /// No description provided for @dialogCommandDetails.
  ///
  /// In en, this message translates to:
  /// **'Show ADB commands'**
  String get dialogCommandDetails;

  /// No description provided for @dialogAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get dialogAssign;

  /// No description provided for @dialogApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get dialogApply;

  /// No description provided for @settingsValueNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsValueNotSet;

  /// No description provided for @settingsMenuPosition.
  ///
  /// In en, this message translates to:
  /// **'Settings menu position'**
  String get settingsMenuPosition;

  /// No description provided for @settingsMenuLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get settingsMenuLeft;

  /// No description provided for @settingsMenuRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get settingsMenuRight;

  /// No description provided for @actionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Action completed'**
  String get actionCompleted;

  /// No description provided for @showRepositoryQrCode.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get showRepositoryQrCode;

  /// No description provided for @resetSections.
  ///
  /// In en, this message translates to:
  /// **'Reset section settings'**
  String get resetSections;

  /// No description provided for @resetSectionsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Restore default sections? Custom sections, spacers and Favorites contents will be removed.'**
  String get resetSectionsConfirmation;

  /// No description provided for @cardFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus on return Home'**
  String get cardFocusMode;

  /// No description provided for @cardFocusRemember.
  ///
  /// In en, this message translates to:
  /// **'Keep selected card'**
  String get cardFocusRemember;

  /// No description provided for @cardFocusFirst.
  ///
  /// In en, this message translates to:
  /// **'First card'**
  String get cardFocusFirst;

  /// No description provided for @cardFocusSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings button'**
  String get cardFocusSettings;

  /// No description provided for @aboutFlauncher.
  ///
  /// In en, this message translates to:
  /// **'About CuteLauncher'**
  String get aboutFlauncher;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @addSection.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get addSection;

  /// No description provided for @alphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get alphabetical;

  /// No description provided for @appCardHighlightAnimation.
  ///
  /// In en, this message translates to:
  /// **'Highlight outline pulse'**
  String get appCardHighlightAnimation;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'Application info'**
  String get appInfo;

  /// No description provided for @appKeyClick.
  ///
  /// In en, this message translates to:
  /// **'Key sounds'**
  String get appKeyClick;

  /// No description provided for @applications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applications;

  /// No description provided for @autoHideAppBar.
  ///
  /// In en, this message translates to:
  /// **'Automatically hide status bar'**
  String get autoHideAppBar;

  /// No description provided for @backButtonAction.
  ///
  /// In en, this message translates to:
  /// **'Back button action'**
  String get backButtonAction;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @columnCount.
  ///
  /// In en, this message translates to:
  /// **'Column count'**
  String get columnCount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @dateAndTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Date and time format'**
  String get dateAndTimeFormat;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @dialogOptionBackButtonActionDoNothing.
  ///
  /// In en, this message translates to:
  /// **'Do nothing'**
  String get dialogOptionBackButtonActionDoNothing;

  /// No description provided for @dialogOptionBackButtonActionShowScreensaver.
  ///
  /// In en, this message translates to:
  /// **'Show screensaver'**
  String get dialogOptionBackButtonActionShowScreensaver;

  /// No description provided for @dialogOptionBackButtonActionShowClock.
  ///
  /// In en, this message translates to:
  /// **'Show clock'**
  String get dialogOptionBackButtonActionShowClock;

  /// No description provided for @dialogTextNoFileExplorer.
  ///
  /// In en, this message translates to:
  /// **'Please install a file explorer in order to pick a picture.'**
  String get dialogTextNoFileExplorer;

  /// No description provided for @dialogTitleBackButtonAction.
  ///
  /// In en, this message translates to:
  /// **'Choose the back button action'**
  String get dialogTitleBackButtonAction;

  /// No description provided for @disambiguateCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} (Category)'**
  String disambiguateCategoryTitle(String title);

  /// No description provided for @formattedDate.
  ///
  /// In en, this message translates to:
  /// **'Formatted date: {dateString}'**
  String formattedDate(String dateString);

  /// No description provided for @formattedTime.
  ///
  /// In en, this message translates to:
  /// **'Formatted time: {timeString}'**
  String formattedTime(String timeString);

  /// No description provided for @gradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get gradient;

  /// No description provided for @favoriteApps.
  ///
  /// In en, this message translates to:
  /// **'Favorite Apps'**
  String get favoriteApps;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @hiddenApplications.
  ///
  /// In en, this message translates to:
  /// **'Hidden Apps'**
  String get hiddenApplications;

  /// No description provided for @launcherSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get launcherSections;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @modifySection.
  ///
  /// In en, this message translates to:
  /// **'Modify section'**
  String get modifySection;

  /// No description provided for @mustNotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Must not be empty'**
  String get mustNotBeEmpty;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @newSection.
  ///
  /// In en, this message translates to:
  /// **'New section'**
  String get newSection;

  /// No description provided for @noDateFormatSpecified.
  ///
  /// In en, this message translates to:
  /// **'No date format specified'**
  String get noDateFormatSpecified;

  /// No description provided for @noTimeFormatSpecified.
  ///
  /// In en, this message translates to:
  /// **'No time format specified'**
  String get noTimeFormatSpecified;

  /// No description provided for @nonTvApplications.
  ///
  /// In en, this message translates to:
  /// **'Non-TV Apps'**
  String get nonTvApplications;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @orSelectFormatSpecifiers.
  ///
  /// In en, this message translates to:
  /// **'Or select format specifiers'**
  String get orSelectFormatSpecifiers;

  /// No description provided for @openImage.
  ///
  /// In en, this message translates to:
  /// **'Open image'**
  String get openImage;

  /// No description provided for @picture.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get picture;

  /// No description provided for @removeFrom.
  ///
  /// In en, this message translates to:
  /// **'Remove from {name}'**
  String removeFrom(String name);

  /// No description provided for @renameCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename category'**
  String get renameCategory;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @row.
  ///
  /// In en, this message translates to:
  /// **'Row'**
  String get row;

  /// No description provided for @rowHeight.
  ///
  /// In en, this message translates to:
  /// **'Row height'**
  String get rowHeight;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @spacer.
  ///
  /// In en, this message translates to:
  /// **'Spacer'**
  String get spacer;

  /// No description provided for @spacerMaxHeightRequirement.
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0 and less than or equal to 500'**
  String get spacerMaxHeightRequirement;

  /// No description provided for @statusBar.
  ///
  /// In en, this message translates to:
  /// **'Status bar'**
  String get statusBar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @showCategoryTitles.
  ///
  /// In en, this message translates to:
  /// **'Show category titles'**
  String get showCategoryTitles;

  /// No description provided for @themes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themes;

  /// No description provided for @hideHighlightOutlineOnHomescreen.
  ///
  /// In en, this message translates to:
  /// **'Hide highlight outline on homescreen'**
  String get hideHighlightOutlineOnHomescreen;

  /// No description provided for @appSelectorTransitionAnimation.
  ///
  /// In en, this message translates to:
  /// **'Smooth highlight transitions'**
  String get appSelectorTransitionAnimation;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'Android settings'**
  String get systemSettings;

  /// No description provided for @textAboutDialog.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher is an Android TV launcher based on LTvLauncher by LeanBitLab and FLauncher by Étienne Fesser.\n\nCuteLauncher by Kirill Shchetinnikov. GNU GPLv3.\nRepository: {repoUrl}.'**
  String textAboutDialog(String repoUrl);

  /// No description provided for @textEmptyCategory.
  ///
  /// In en, this message translates to:
  /// **'This category is empty.'**
  String get textEmptyCategory;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @titleStatusBarSettingsPage.
  ///
  /// In en, this message translates to:
  /// **'Choose what to display in the status bar'**
  String get titleStatusBarSettingsPage;

  /// No description provided for @tvApplications.
  ///
  /// In en, this message translates to:
  /// **'TV Apps'**
  String get tvApplications;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @typeInTheDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Type in the date format'**
  String get typeInTheDateFormat;

  /// No description provided for @typeInTheHourFormat.
  ///
  /// In en, this message translates to:
  /// **'Type in the hour format'**
  String get typeInTheHourFormat;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @wallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get wallpaper;

  /// No description provided for @withEllipsisAddTo.
  ///
  /// In en, this message translates to:
  /// **'Add to...'**
  String get withEllipsisAddTo;

  /// No description provided for @timeBasedWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Time based wallpaper'**
  String get timeBasedWallpaper;

  /// No description provided for @pickDayWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Pick day wallpaper'**
  String get pickDayWallpaper;

  /// No description provided for @pickNightWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Pick night wallpaper'**
  String get pickNightWallpaper;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @defaultLauncherIsDefault.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher is the default launcher'**
  String get defaultLauncherIsDefault;

  /// No description provided for @defaultLauncherNotDefault.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher is not the default launcher'**
  String get defaultLauncherNotDefault;

  /// No description provided for @setAsDefaultLauncher.
  ///
  /// In en, this message translates to:
  /// **'Set as default launcher'**
  String get setAsDefaultLauncher;

  /// No description provided for @defaultLauncherDescription.
  ///
  /// In en, this message translates to:
  /// **'When set as the default launcher, the Home button will always return to CuteLauncher. The TV will also boot directly into CuteLauncher.'**
  String get defaultLauncherDescription;

  /// No description provided for @inputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get inputs;

  /// No description provided for @inputsUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'This device provides no available inputs. The switch is disabled and the icon is hidden. On a TV box, this option does not control the connected TV’s HDMI inputs.'**
  String get inputsUnavailableHint;

  /// No description provided for @inputSources.
  ///
  /// In en, this message translates to:
  /// **'Input Sources'**
  String get inputSources;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully to {path}'**
  String exportSuccess(String path);

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully'**
  String get importSuccess;

  /// No description provided for @importConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import this backup? Saved valid settings and layout will be applied. Missing or invalid individual settings keep their current values.'**
  String get importConfirm;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Could not restore settings from the backup. Check the file and try again.'**
  String get importError;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup: {error}'**
  String exportError(String error);

  /// No description provided for @shareBackup.
  ///
  /// In en, this message translates to:
  /// **'Share Backup'**
  String get shareBackup;

  /// No description provided for @shareBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Share backup with other devices on local network'**
  String get shareBackupDescription;

  /// No description provided for @stopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop Sharing'**
  String get stopSharing;

  /// No description provided for @localNetworkSharingActive.
  ///
  /// In en, this message translates to:
  /// **'Local network sharing is active!'**
  String get localNetworkSharingActive;

  /// No description provided for @localNetworkSharingInstructions.
  ///
  /// In en, this message translates to:
  /// **'Connect another device to the same Wi-Fi network and open the following URL in a web browser:'**
  String get localNetworkSharingInstructions;

  /// No description provided for @localNetworkSharingDetails.
  ///
  /// In en, this message translates to:
  /// **'Here you can download your TV settings/layout or upload a backup file back to this TV.'**
  String get localNetworkSharingDetails;

  /// No description provided for @failedToStartServer.
  ///
  /// In en, this message translates to:
  /// **'Failed to start sharing server: {error}'**
  String failedToStartServer(String error);

  /// No description provided for @notificationBell.
  ///
  /// In en, this message translates to:
  /// **'Notification icon'**
  String get notificationBell;

  /// No description provided for @autoHideNotificationBell.
  ///
  /// In en, this message translates to:
  /// **'Hide icon when there are no notifications'**
  String get autoHideNotificationBell;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get continueWatching;

  /// No description provided for @showContinueWatchingOnHome.
  ///
  /// In en, this message translates to:
  /// **'Show Continue Watching on Home'**
  String get showContinueWatchingOnHome;

  /// No description provided for @permissionDeniedContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Permission required to show Continue Watching'**
  String get permissionDeniedContinueWatching;

  /// No description provided for @interface.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get interface;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @miscellaneous.
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous'**
  String get miscellaneous;

  /// No description provided for @brightnessScheduler.
  ///
  /// In en, this message translates to:
  /// **'Brightness Scheduler'**
  String get brightnessScheduler;

  /// No description provided for @screensaverSettings.
  ///
  /// In en, this message translates to:
  /// **'Choose screensaver in Android TV'**
  String get screensaverSettings;

  /// No description provided for @screensaverClockStyle.
  ///
  /// In en, this message translates to:
  /// **'Screensaver Clock Style'**
  String get screensaverClockStyle;

  /// No description provided for @dataUsagePeriod.
  ///
  /// In en, this message translates to:
  /// **'Traffic counting period'**
  String get dataUsagePeriod;

  /// No description provided for @notificationAccess.
  ///
  /// In en, this message translates to:
  /// **'Notification Access'**
  String get notificationAccess;

  /// No description provided for @granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get granted;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @systemWidePopupAlert.
  ///
  /// In en, this message translates to:
  /// **'System-wide Popup Alert'**
  String get systemWidePopupAlert;

  /// No description provided for @overlayPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Overlay Permission Required'**
  String get overlayPermissionRequired;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @showAppNamesBelowIcons.
  ///
  /// In en, this message translates to:
  /// **'Show app labels'**
  String get showAppNamesBelowIcons;

  /// No description provided for @dataUsage.
  ///
  /// In en, this message translates to:
  /// **'Data Usage'**
  String get dataUsage;

  /// No description provided for @networkIndicator.
  ///
  /// In en, this message translates to:
  /// **'Network Indicator'**
  String get networkIndicator;

  /// No description provided for @homeButtonFix.
  ///
  /// In en, this message translates to:
  /// **'Home button'**
  String get homeButtonFix;

  /// No description provided for @startOnBoot.
  ///
  /// In en, this message translates to:
  /// **'Start when the TV turns on'**
  String get startOnBoot;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get appLanguage;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @ukrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get ukrainian;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// No description provided for @portuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get portuguese;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @italian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get italian;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @korean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get korean;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @hidePersistentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Hide Persistent Notifications'**
  String get hidePersistentNotifications;

  /// No description provided for @hidePersistentNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide ongoing background service and system notifications'**
  String get hidePersistentNotificationsDesc;

  /// No description provided for @blockedNotificationApps.
  ///
  /// In en, this message translates to:
  /// **'Block notifications from apps'**
  String get blockedNotificationApps;

  /// No description provided for @blockAppNotifications.
  ///
  /// In en, this message translates to:
  /// **'Block Notifications'**
  String get blockAppNotifications;

  /// No description provided for @unblockAppNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unblock Notifications'**
  String get unblockAppNotifications;

  /// No description provided for @noBlockedApps.
  ///
  /// In en, this message translates to:
  /// **'No blocked apps'**
  String get noBlockedApps;

  /// No description provided for @persistentNotification.
  ///
  /// In en, this message translates to:
  /// **'Persistent'**
  String get persistentNotification;

  /// No description provided for @unblockAll.
  ///
  /// In en, this message translates to:
  /// **'Unblock All'**
  String get unblockAll;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @showWeatherWarnings.
  ///
  /// In en, this message translates to:
  /// **'Show Weather & Rain Warnings'**
  String get showWeatherWarnings;

  /// No description provided for @temperatureUnit.
  ///
  /// In en, this message translates to:
  /// **'Temperature Unit'**
  String get temperatureUnit;

  /// No description provided for @celsius.
  ///
  /// In en, this message translates to:
  /// **'Celsius (°C)'**
  String get celsius;

  /// No description provided for @fahrenheit.
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit (°F)'**
  String get fahrenheit;

  /// No description provided for @breezyWeatherSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Install Breezy Weather and enable \'Local data sharing\' / \'Gadgetbridge\' in its settings to see weather and rain warnings.'**
  String get breezyWeatherSetupHint;

  /// No description provided for @displayAndScreensaver.
  ///
  /// In en, this message translates to:
  /// **'Night mode and brightness'**
  String get displayAndScreensaver;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @continueWatchingDescription.
  ///
  /// In en, this message translates to:
  /// **'Show recently watched movies and TV shows from supported apps on your home screen'**
  String get continueWatchingDescription;

  /// No description provided for @continueWatchingPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Special permission is required to read watch history from TV apps. You can grant it using the button below or via ADB:'**
  String get continueWatchingPermissionDesc;

  /// No description provided for @requestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request Permission'**
  String get requestPermission;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openApp;

  /// No description provided for @notificationOptions.
  ///
  /// In en, this message translates to:
  /// **'Notification Options'**
  String get notificationOptions;

  /// No description provided for @noBlockedAppsDesc.
  ///
  /// In en, this message translates to:
  /// **'All applications are currently allowed to show notifications'**
  String get noBlockedAppsDesc;

  /// No description provided for @notificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications Allowed'**
  String get notificationsAllowed;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications Blocked'**
  String get notificationsBlocked;

  /// No description provided for @dpadDismissHint.
  ///
  /// In en, this message translates to:
  /// **'◄ — dismiss · OK — options · ► — block app'**
  String get dpadDismissHint;

  /// No description provided for @watchNextDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the item from Continue Watching. Try again.'**
  String get watchNextDeleteError;

  /// No description provided for @hideLauncherTile.
  ///
  /// In en, this message translates to:
  /// **'Hide CuteLauncher in the app grid'**
  String get hideLauncherTile;

  /// No description provided for @hideAndroidSettingsTile.
  ///
  /// In en, this message translates to:
  /// **'Hide Android settings in app tiles'**
  String get hideAndroidSettingsTile;

  /// No description provided for @animateTileReordering.
  ///
  /// In en, this message translates to:
  /// **'Animate tile reordering'**
  String get animateTileReordering;

  /// No description provided for @imageInputRejected.
  ///
  /// In en, this message translates to:
  /// **'This image is damaged or too large (maximum 8 MiB and 48 megapixels). Choose another image.'**
  String get imageInputRejected;

  /// No description provided for @memoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memoryTitle;

  /// No description provided for @memoryRefresh.
  ///
  /// In en, this message translates to:
  /// **'Measure memory'**
  String get memoryRefresh;

  /// No description provided for @memoryMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring…'**
  String get memoryMeasuring;

  /// No description provided for @memoryClear.
  ///
  /// In en, this message translates to:
  /// **'Clear image caches'**
  String get memoryClear;

  /// No description provided for @memorySaver.
  ///
  /// In en, this message translates to:
  /// **'Memory saving'**
  String get memorySaver;

  /// No description provided for @memorySaverDescription.
  ///
  /// In en, this message translates to:
  /// **'Memory saving mode:\n\n• Reduces image caches and the poster preload window.\n• Disables tile, panel and wallpaper background blur, and outline pulsing.\n• Limits shadows on unfocused tiles.\n• Clears caches when the app goes into the background.\n\nThese effects are unavailable in settings while memory saving is enabled. Their saved values return when the mode is disabled. Images may reload more often.'**
  String get memorySaverDescription;

  /// No description provided for @memoryPss.
  ///
  /// In en, this message translates to:
  /// **'Process share (PSS)'**
  String get memoryPss;

  /// No description provided for @memoryRss.
  ///
  /// In en, this message translates to:
  /// **'Resident process memory (RSS)'**
  String get memoryRss;

  /// No description provided for @memoryEncodedCache.
  ///
  /// In en, this message translates to:
  /// **'Cached image files'**
  String get memoryEncodedCache;

  /// No description provided for @memoryDecodedCache.
  ///
  /// In en, this message translates to:
  /// **'Cached decoded images'**
  String get memoryDecodedCache;

  /// No description provided for @memoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get memoryUnavailable;

  /// No description provided for @memoryUnit.
  ///
  /// In en, this message translates to:
  /// **'MiB'**
  String get memoryUnit;

  /// No description provided for @memoryMeasuredAt.
  ///
  /// In en, this message translates to:
  /// **'Measured at'**
  String get memoryMeasuredAt;

  /// No description provided for @memoryExplanation.
  ///
  /// In en, this message translates to:
  /// **'PSS and RSS overlap: do not add them together. Cache sizes are part of app memory and do not describe all memory held by active images. Clearing caches keeps your settings and files; images load again when needed. Android may return memory later. RSS here comes from the kernel and PSS from Android; they may account for graphics memory differently.'**
  String get memoryExplanation;

  /// No description provided for @memoryRecommendations.
  ///
  /// In en, this message translates to:
  /// **'For less memory, enable saving, show fewer Continue watching cards and use smaller wallpapers or a gradient.'**
  String get memoryRecommendations;

  /// No description provided for @memoryMeasurementFailed.
  ///
  /// In en, this message translates to:
  /// **'Process measurement is unavailable. Cache information is still shown.'**
  String get memoryMeasurementFailed;

  /// No description provided for @addToCategory.
  ///
  /// In en, this message translates to:
  /// **'Add to Category'**
  String get addToCategory;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Fav'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Fav'**
  String get removeFromFavorites;

  /// No description provided for @setCustomBanner.
  ///
  /// In en, this message translates to:
  /// **'Set Custom Banner'**
  String get setCustomBanner;

  /// No description provided for @clearCustomBanner.
  ///
  /// In en, this message translates to:
  /// **'Clear Custom Banner'**
  String get clearCustomBanner;

  /// No description provided for @bannerSetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not set the banner. Check access to the image and select the file again.'**
  String get bannerSetFailed;

  /// No description provided for @bannerClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the custom banner. Try again.'**
  String get bannerClearFailed;

  /// No description provided for @grantUsagePermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Usage Permission'**
  String get grantUsagePermission;

  /// No description provided for @removeFromContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Remove from Continue Watching'**
  String get removeFromContinueWatching;

  /// No description provided for @hideAllFromApp.
  ///
  /// In en, this message translates to:
  /// **'Hide all from {appName}'**
  String hideAllFromApp(String appName);

  /// No description provided for @playResume.
  ///
  /// In en, this message translates to:
  /// **'Play / Resume'**
  String get playResume;

  /// No description provided for @openNamedApp.
  ///
  /// In en, this message translates to:
  /// **'Open {appName}'**
  String openNamedApp(String appName);

  /// No description provided for @selectedAccent.
  ///
  /// In en, this message translates to:
  /// **'Selected Accent'**
  String get selectedAccent;

  /// No description provided for @homeButtonFixHint.
  ///
  /// In en, this message translates to:
  /// **'If you are using Google TV, enable \"Home Button Fix\" under Accessibility settings to make the Home button open this launcher.'**
  String get homeButtonFixHint;

  /// No description provided for @accessibilityPermission.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Permission'**
  String get accessibilityPermission;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share Failed'**
  String get shareFailed;

  /// No description provided for @shareBackupError.
  ///
  /// In en, this message translates to:
  /// **'Failed to share backup: {error}'**
  String shareBackupError(String error);

  /// No description provided for @exportComplete.
  ///
  /// In en, this message translates to:
  /// **'Export Success'**
  String get exportComplete;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the backup. Check folder access and available storage.'**
  String get exportFailed;

  /// No description provided for @backupLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading backups: {error}'**
  String backupLoadError(String error);

  /// No description provided for @noBackupFiles.
  ///
  /// In en, this message translates to:
  /// **'No backup files found.'**
  String get noBackupFiles;

  /// No description provided for @importComplete.
  ///
  /// In en, this message translates to:
  /// **'Import Success'**
  String get importComplete;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get importFailed;

  /// No description provided for @importAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importAction;

  /// No description provided for @continueWatchingApps.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching Apps'**
  String get continueWatchingApps;

  /// No description provided for @blockedContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Blocked from Continue Watching'**
  String get blockedContinueWatching;

  /// No description provided for @allAppsCanContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'All supported apps can show items in Continue Watching.'**
  String get allAppsCanContinueWatching;

  /// No description provided for @unblockApp.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockApp;

  /// No description provided for @unblockAllApps.
  ///
  /// In en, this message translates to:
  /// **'Unblock All Apps'**
  String get unblockAllApps;

  /// No description provided for @appsWithContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Apps with Continue Watching'**
  String get appsWithContinueWatching;

  /// No description provided for @watchNextAppsHint.
  ///
  /// In en, this message translates to:
  /// **'Apps currently providing Watch Next items on your home screen'**
  String get watchNextAppsHint;

  /// No description provided for @noWatchNextApps.
  ///
  /// In en, this message translates to:
  /// **'No apps are currently providing Continue Watching items.\nWhen supported apps (such as SmartTube or streaming services) add items, they will appear here.'**
  String get noWatchNextApps;

  /// No description provided for @allInstalledApps.
  ///
  /// In en, this message translates to:
  /// **'All Installed Apps'**
  String get allInstalledApps;

  /// No description provided for @blockWatchNextHint.
  ///
  /// In en, this message translates to:
  /// **'Toggle off to block any app from adding items to Continue Watching'**
  String get blockWatchNextHint;

  /// No description provided for @cardSize.
  ///
  /// In en, this message translates to:
  /// **'Card Size'**
  String get cardSize;

  /// No description provided for @maximumItems.
  ///
  /// In en, this message translates to:
  /// **'Maximum Items'**
  String get maximumItems;

  /// No description provided for @playbackProgressBar.
  ///
  /// In en, this message translates to:
  /// **'Playback Progress Bar'**
  String get playbackProgressBar;

  /// No description provided for @playbackPercentage.
  ///
  /// In en, this message translates to:
  /// **'Playback Percentage'**
  String get playbackPercentage;

  /// No description provided for @episodeVideoDetails.
  ///
  /// In en, this message translates to:
  /// **'Episode & Video Details'**
  String get episodeVideoDetails;

  /// No description provided for @restoreHiddenPrograms.
  ///
  /// In en, this message translates to:
  /// **'Restore Hidden Programs'**
  String get restoreHiddenPrograms;

  /// No description provided for @allHiddenProgramsRestored.
  ///
  /// In en, this message translates to:
  /// **'All hidden programs restored'**
  String get allHiddenProgramsRestored;

  /// No description provided for @watchNextAccessAdb.
  ///
  /// In en, this message translates to:
  /// **'Watch Next Access (ADB Required)'**
  String get watchNextAccessAdb;

  /// No description provided for @supportLtvLauncher.
  ///
  /// In en, this message translates to:
  /// **'Support LTvLauncher'**
  String get supportLtvLauncher;

  /// No description provided for @scanToDonate.
  ///
  /// In en, this message translates to:
  /// **'Scan with your phone camera to donate:'**
  String get scanToDonate;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get openInBrowser;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @launcherAuthor.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher by Kirill Shchetinnikov'**
  String get launcherAuthor;

  /// No description provided for @launcherCredits.
  ///
  /// In en, this message translates to:
  /// **'Android TV launcher based on LTvLauncher by LeanBitLab and FLauncher by Étienne Fesser. Licensed under GNU GPLv3.'**
  String get launcherCredits;

  /// No description provided for @projectCredits.
  ///
  /// In en, this message translates to:
  /// **'Project & Credits'**
  String get projectCredits;

  /// No description provided for @launcherRepository.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher Repository'**
  String get launcherRepository;

  /// No description provided for @originalProject.
  ///
  /// In en, this message translates to:
  /// **'Original project: LTvLauncher'**
  String get originalProject;

  /// No description provided for @noInputsDetected.
  ///
  /// In en, this message translates to:
  /// **'No inputs detected'**
  String get noInputsDetected;

  /// No description provided for @reorderSectionsHint.
  ///
  /// In en, this message translates to:
  /// **'Select with ◄ / ► then use ▲ / ▼ to reorder. Cross the list boundary to hide or show a section.'**
  String get reorderSectionsHint;

  /// No description provided for @customName.
  ///
  /// In en, this message translates to:
  /// **'Custom Name'**
  String get customName;

  /// No description provided for @mostUsed.
  ///
  /// In en, this message translates to:
  /// **'Launch frequency'**
  String get mostUsed;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last Used'**
  String get lastUsed;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @notificationAccessAdb.
  ///
  /// In en, this message translates to:
  /// **'Notification Access (ADB Required)'**
  String get notificationAccessAdb;

  /// No description provided for @openAppInfo.
  ///
  /// In en, this message translates to:
  /// **'Open App Info'**
  String get openAppInfo;

  /// No description provided for @overlayPermission.
  ///
  /// In en, this message translates to:
  /// **'Overlay Permission'**
  String get overlayPermission;

  /// No description provided for @clockMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get clockMinimal;

  /// No description provided for @clockMinimalDescription.
  ///
  /// In en, this message translates to:
  /// **'Thin, elegant font (Default)'**
  String get clockMinimalDescription;

  /// No description provided for @clockBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get clockBold;

  /// No description provided for @clockBoldDescription.
  ///
  /// In en, this message translates to:
  /// **'Thick, highly visible font'**
  String get clockBoldDescription;

  /// No description provided for @clockRetro.
  ///
  /// In en, this message translates to:
  /// **'Retro'**
  String get clockRetro;

  /// No description provided for @clockRetroDescription.
  ///
  /// In en, this message translates to:
  /// **'Monospaced, retro terminal style'**
  String get clockRetroDescription;

  /// No description provided for @clockElegant.
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get clockElegant;

  /// No description provided for @clockElegantDescription.
  ///
  /// In en, this message translates to:
  /// **'Classic serif typeface'**
  String get clockElegantDescription;

  /// No description provided for @clockNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get clockNeon;

  /// No description provided for @clockNeonDescription.
  ///
  /// In en, this message translates to:
  /// **'Ultra-thin, glowing style'**
  String get clockNeonDescription;

  /// No description provided for @clockPixel.
  ///
  /// In en, this message translates to:
  /// **'Pixel'**
  String get clockPixel;

  /// No description provided for @clockPixelDescription.
  ///
  /// In en, this message translates to:
  /// **'Bold monospaced, arcade feel'**
  String get clockPixelDescription;

  /// No description provided for @clockDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get clockDigital;

  /// No description provided for @clockDigitalDescription.
  ///
  /// In en, this message translates to:
  /// **'Clean monospaced display'**
  String get clockDigitalDescription;

  /// No description provided for @themeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get themeDefault;

  /// No description provided for @themePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get themePremium;

  /// No description provided for @themeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get themeClassic;

  /// No description provided for @themeCapsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get themeCapsule;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @actionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Action cancelled'**
  String get actionCancelled;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @accessibilityGuide.
  ///
  /// In en, this message translates to:
  /// **'Open the TV settings manually, then Accessibility → CuteLauncher Home Button Fix, and enable the service. The location and name of this menu depend on your TV manufacturer.'**
  String get accessibilityGuide;

  /// No description provided for @notificationPermissionGuide.
  ///
  /// In en, this message translates to:
  /// **'The notification access settings could not be opened on this TV. Allowing outgoing notifications in App Info does not grant access to notifications from other apps.\n\nConnect your TV via ADB and run:'**
  String get notificationPermissionGuide;

  /// No description provided for @overlayPermissionGuide.
  ///
  /// In en, this message translates to:
  /// **'The overlay permission settings could not be opened automatically.\n\nTo enable popups over other apps, connect your TV via ADB and run:'**
  String get overlayPermissionGuide;

  /// No description provided for @watchNextPermissionGuide.
  ///
  /// In en, this message translates to:
  /// **'To read Continue Watching cards from other apps, Android TV requires READ_WRITE_WATCH_NEXT_PROGRAMS.\n\nConnect your TV via ADB and run:'**
  String get watchNextPermissionGuide;

  /// No description provided for @watchNextAccess.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching access'**
  String get watchNextAccess;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @displayUpToItems.
  ///
  /// In en, this message translates to:
  /// **'Display up to {count} recent items'**
  String displayUpToItems(int count);

  /// No description provided for @unlimitedItems.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimitedItems;

  /// No description provided for @allAvailableItems.
  ///
  /// In en, this message translates to:
  /// **'Display all available items'**
  String get allAvailableItems;

  /// No description provided for @defaultOption.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultOption;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @blockedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} blocked'**
  String blockedCount(int count);

  /// No description provided for @hiddenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} hidden'**
  String hiddenCount(int count);

  /// No description provided for @blockedWatchNextCount.
  ///
  /// In en, this message translates to:
  /// **'Blocked from Continue Watching ({count})'**
  String blockedWatchNextCount(int count);

  /// No description provided for @sizeExtraSmall.
  ///
  /// In en, this message translates to:
  /// **'Extra Small'**
  String get sizeExtraSmall;

  /// No description provided for @sizeVerySmall.
  ///
  /// In en, this message translates to:
  /// **'Very Small'**
  String get sizeVerySmall;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// No description provided for @sizeCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get sizeCompact;

  /// No description provided for @sizeMediumSmall.
  ///
  /// In en, this message translates to:
  /// **'Medium Small'**
  String get sizeMediumSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// No description provided for @sizeStandardDefault.
  ///
  /// In en, this message translates to:
  /// **'Standard (Default)'**
  String get sizeStandardDefault;

  /// No description provided for @sizeMediumLarge.
  ///
  /// In en, this message translates to:
  /// **'Medium Large'**
  String get sizeMediumLarge;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// No description provided for @sizeVeryLarge.
  ///
  /// In en, this message translates to:
  /// **'Very Large'**
  String get sizeVeryLarge;

  /// No description provided for @sizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get sizeExtraLarge;

  /// No description provided for @sizeHuge.
  ///
  /// In en, this message translates to:
  /// **'Huge'**
  String get sizeHuge;

  /// No description provided for @tvApps.
  ///
  /// In en, this message translates to:
  /// **'TV Apps'**
  String get tvApps;

  /// No description provided for @nonTvApps.
  ///
  /// In en, this message translates to:
  /// **'Non-TV Apps'**
  String get nonTvApps;

  /// No description provided for @moviesShows.
  ///
  /// In en, this message translates to:
  /// **'Movies & Shows'**
  String get moviesShows;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// No description provided for @liveTv.
  ///
  /// In en, this message translates to:
  /// **'Live TV'**
  String get liveTv;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sports;

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @customSectionName.
  ///
  /// In en, this message translates to:
  /// **'Custom...'**
  String get customSectionName;

  /// No description provided for @selectSectionName.
  ///
  /// In en, this message translates to:
  /// **'Select a name'**
  String get selectSectionName;

  /// No description provided for @weeklyUsage.
  ///
  /// In en, this message translates to:
  /// **'Weekly: '**
  String get weeklyUsage;

  /// No description provided for @monthlyUsage.
  ///
  /// In en, this message translates to:
  /// **'Monthly: '**
  String get monthlyUsage;

  /// No description provided for @dailyUsage.
  ///
  /// In en, this message translates to:
  /// **'Daily: '**
  String get dailyUsage;

  /// No description provided for @appError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get appError;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @weatherStorm.
  ///
  /// In en, this message translates to:
  /// **'Storm'**
  String get weatherStorm;

  /// No description provided for @weatherToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get weatherToday;

  /// No description provided for @weatherTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get weatherTomorrow;

  /// No description provided for @weatherOnDay.
  ///
  /// In en, this message translates to:
  /// **'on {day}'**
  String weatherOnDay(String day);

  /// No description provided for @weatherWarning.
  ///
  /// In en, this message translates to:
  /// **'{probability}{condition} {day}'**
  String weatherWarning(String probability, String condition, String day);

  /// No description provided for @backupShareTitle.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher Backup'**
  String get backupShareTitle;

  /// No description provided for @noApplicationsFound.
  ///
  /// In en, this message translates to:
  /// **'No applications found'**
  String get noApplicationsFound;

  /// No description provided for @invalidDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid format'**
  String get invalidDateFormat;

  /// No description provided for @selectDateFormats.
  ///
  /// In en, this message translates to:
  /// **'Select formats below'**
  String get selectDateFormats;

  /// No description provided for @activeItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active item(s)'**
  String activeItemsCount(int count);

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorCyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get colorCyan;

  /// No description provided for @colorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get colorIndigo;

  /// No description provided for @colorLime.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get colorLime;

  /// No description provided for @colorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// No description provided for @colorRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get colorRose;

  /// No description provided for @colorIceBlue.
  ///
  /// In en, this message translates to:
  /// **'Ice Blue'**
  String get colorIceBlue;

  /// No description provided for @memoryFeatures.
  ///
  /// In en, this message translates to:
  /// **'Memory by feature (caches)'**
  String get memoryFeatures;

  /// No description provided for @memoryAppIcons.
  ///
  /// In en, this message translates to:
  /// **'App icons'**
  String get memoryAppIcons;

  /// No description provided for @memoryAppBanners.
  ///
  /// In en, this message translates to:
  /// **'App banners'**
  String get memoryAppBanners;

  /// No description provided for @memoryWatchNextPosters.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching posters'**
  String get memoryWatchNextPosters;

  /// No description provided for @memoryOtherCaches.
  ///
  /// In en, this message translates to:
  /// **'Other encoded image caches'**
  String get memoryOtherCaches;

  /// No description provided for @memoryFeaturesExplanation.
  ///
  /// In en, this message translates to:
  /// **'These are retained image bytes, already included in the encoded cache total. Zero means no retained bytes in that cache, not that the feature uses no memory. Wallpapers and displayed images share the decoded cache above; active images may be outside it. Weather, notifications, Dart objects and the engine cannot be split by feature here. Shared interface graphics are reported above by Android and already included in PSS. Their memory is part of the process total. Do not add these overlapping values.'**
  String get memoryFeaturesExplanation;

  /// No description provided for @memoryGraphics.
  ///
  /// In en, this message translates to:
  /// **'Interface graphics (included in PSS)'**
  String get memoryGraphics;

  /// No description provided for @categoryVisible.
  ///
  /// In en, this message translates to:
  /// **'Show category'**
  String get categoryVisible;

  /// No description provided for @hiddenCategories.
  ///
  /// In en, this message translates to:
  /// **'Hidden categories'**
  String get hiddenCategories;

  /// No description provided for @visibleCategories.
  ///
  /// In en, this message translates to:
  /// **'Visible categories'**
  String get visibleCategories;

  /// No description provided for @backupSavedToSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to the selected location'**
  String get backupSavedToSelectedLocation;

  /// No description provided for @tileHorizontalGap.
  ///
  /// In en, this message translates to:
  /// **'Horizontal spacing'**
  String get tileHorizontalGap;

  /// No description provided for @tileVerticalGap.
  ///
  /// In en, this message translates to:
  /// **'Vertical spacing'**
  String get tileVerticalGap;

  /// No description provided for @tileOpacity.
  ///
  /// In en, this message translates to:
  /// **'Background opacity'**
  String get tileOpacity;

  /// No description provided for @tileShadow.
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get tileShadow;

  /// No description provided for @tileCornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner rounding'**
  String get tileCornerRadius;

  /// No description provided for @tileIconScale.
  ///
  /// In en, this message translates to:
  /// **'Icon size'**
  String get tileIconScale;

  /// No description provided for @tileBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Tile background'**
  String get tileBackgroundColor;

  /// No description provided for @tileLabelSize.
  ///
  /// In en, this message translates to:
  /// **'Label size'**
  String get tileLabelSize;

  /// No description provided for @resetAppearance.
  ///
  /// In en, this message translates to:
  /// **'Reset appearance'**
  String get resetAppearance;

  /// No description provided for @tileAppearance.
  ///
  /// In en, this message translates to:
  /// **'Tile appearance'**
  String get tileAppearance;

  /// No description provided for @tileLabelColor.
  ///
  /// In en, this message translates to:
  /// **'Label color'**
  String get tileLabelColor;

  /// No description provided for @tilePreviewName.
  ///
  /// In en, this message translates to:
  /// **'Sample application'**
  String get tilePreviewName;

  /// No description provided for @tileProportions.
  ///
  /// In en, this message translates to:
  /// **'Tile proportions'**
  String get tileProportions;

  /// No description provided for @tileLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get tileLarge;

  /// No description provided for @tileLabelBelow.
  ///
  /// In en, this message translates to:
  /// **'Below the tile'**
  String get tileLabelBelow;

  /// No description provided for @tileLabelInside.
  ///
  /// In en, this message translates to:
  /// **'Inside the tile'**
  String get tileLabelInside;

  /// No description provided for @tileFocusScale.
  ///
  /// In en, this message translates to:
  /// **'Enlarge'**
  String get tileFocusScale;

  /// No description provided for @tileMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get tileMedium;

  /// No description provided for @tileFocusBorder.
  ///
  /// In en, this message translates to:
  /// **'No movement'**
  String get tileFocusBorder;

  /// No description provided for @tileSize.
  ///
  /// In en, this message translates to:
  /// **'Tile size'**
  String get tileSize;

  /// No description provided for @tileCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get tileCompact;

  /// No description provided for @tileLabelPosition.
  ///
  /// In en, this message translates to:
  /// **'Label position'**
  String get tileLabelPosition;

  /// No description provided for @tileFocusEffect.
  ///
  /// In en, this message translates to:
  /// **'Focus effect'**
  String get tileFocusEffect;

  /// No description provided for @tileFocusStrength.
  ///
  /// In en, this message translates to:
  /// **'Highlight intensity'**
  String get tileFocusStrength;

  /// No description provided for @panelIndependent.
  ///
  /// In en, this message translates to:
  /// **'Custom settings'**
  String get panelIndependent;

  /// No description provided for @panelAppearance.
  ///
  /// In en, this message translates to:
  /// **'Top panel style'**
  String get panelAppearance;

  /// No description provided for @panelBackground.
  ///
  /// In en, this message translates to:
  /// **'Panel background'**
  String get panelBackground;

  /// No description provided for @blurPerformanceHint.
  ///
  /// In en, this message translates to:
  /// **'Blur may reduce smoothness. It is disabled while memory saving is on.'**
  String get blurPerformanceHint;

  /// No description provided for @panelOpacity.
  ///
  /// In en, this message translates to:
  /// **'Panel opacity'**
  String get panelOpacity;

  /// No description provided for @tileBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur behind tiles'**
  String get tileBlur;

  /// No description provided for @panelBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur behind top panel'**
  String get panelBlur;

  /// No description provided for @panelShared.
  ///
  /// In en, this message translates to:
  /// **'Like panels'**
  String get panelShared;

  /// No description provided for @weatherMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get weatherMinutes;

  /// No description provided for @weatherOpenMeteoCredit.
  ///
  /// In en, this message translates to:
  /// **'Weather: Open-Meteo (open-meteo.com), CC BY 4.0. Free API for non-commercial use.'**
  String get weatherOpenMeteoCredit;

  /// No description provided for @weatherRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Request limit reached. Try later.'**
  String get weatherRateLimit;

  /// No description provided for @weatherYandexCredit.
  ///
  /// In en, this message translates to:
  /// **'Weather: Yandex Weather (yandex.ru/pogoda). Access depends on your API plan.'**
  String get weatherYandexCredit;

  /// No description provided for @yandexWeather.
  ///
  /// In en, this message translates to:
  /// **'Yandex Weather (REST)'**
  String get yandexWeather;

  /// No description provided for @weatherAuthorizationError.
  ///
  /// In en, this message translates to:
  /// **'The weather provider rejected the request. Check the API key and access to the selected service.'**
  String get weatherAuthorizationError;

  /// No description provided for @weatherYandexHint.
  ///
  /// In en, this message translates to:
  /// **'Requires a key with REST forecast access. A key for another Yandex plan may not work.'**
  String get weatherYandexHint;

  /// No description provided for @weatherSource.
  ///
  /// In en, this message translates to:
  /// **'Weather source'**
  String get weatherSource;

  /// No description provided for @weatherInterval.
  ///
  /// In en, this message translates to:
  /// **'Update interval'**
  String get weatherInterval;

  /// No description provided for @weatherLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude (-180 to 180)'**
  String get weatherLongitude;

  /// No description provided for @weatherKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a Yandex API key.'**
  String get weatherKeyRequired;

  /// No description provided for @weatherLocationName.
  ///
  /// In en, this message translates to:
  /// **'City name (optional)'**
  String get weatherLocationName;

  /// No description provided for @weatherLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get weatherLocation;

  /// No description provided for @weatherApiKey.
  ///
  /// In en, this message translates to:
  /// **'Yandex API key'**
  String get weatherApiKey;

  /// No description provided for @weatherInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The weather source returned invalid data.'**
  String get weatherInvalidResponse;

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather is unavailable. Previously received data is retained if available. Retries are limited to once every 5 minutes.'**
  String get weatherUnavailable;

  /// No description provided for @weatherStale.
  ///
  /// In en, this message translates to:
  /// **'Previous weather'**
  String get weatherStale;

  /// No description provided for @weatherLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude (-90 to 90)'**
  String get weatherLatitude;

  /// No description provided for @weatherCoordinatesError.
  ///
  /// In en, this message translates to:
  /// **'Enter a city manually or get coordinates automatically.'**
  String get weatherCoordinatesError;

  /// No description provided for @weatherRefresh.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get weatherRefresh;

  /// No description provided for @weatherKeyPrivate.
  ///
  /// In en, this message translates to:
  /// **'Stored only on this device, excluded from backups. Empty input removes the key.'**
  String get weatherKeyPrivate;

  /// No description provided for @weatherUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get weatherUpdated;

  /// No description provided for @onlineWallpaperError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load this image. Previous wallpaper is retained. Select “Check for updates” to retry the download.'**
  String get onlineWallpaperError;

  /// No description provided for @onlineWallpaperHint.
  ///
  /// In en, this message translates to:
  /// **'The last image is kept offline (up to 8 MiB).'**
  String get onlineWallpaperHint;

  /// No description provided for @onlineWallpaperHours.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get onlineWallpaperHours;

  /// No description provided for @onlineWallpaperInterval.
  ///
  /// In en, this message translates to:
  /// **'Download interval'**
  String get onlineWallpaperInterval;

  /// No description provided for @onlineWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Online wallpaper'**
  String get onlineWallpaper;

  /// No description provided for @onlineWallpaperUrlError.
  ///
  /// In en, this message translates to:
  /// **'Enter a direct HTTPS image URL without login details.'**
  String get onlineWallpaperUrlError;

  /// No description provided for @onlineWallpaperEnabled.
  ///
  /// In en, this message translates to:
  /// **'Use online wallpaper'**
  String get onlineWallpaperEnabled;

  /// No description provided for @onlineWallpaperSource.
  ///
  /// In en, this message translates to:
  /// **'Image source'**
  String get onlineWallpaperSource;

  /// No description provided for @bingWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Bing image of the day'**
  String get bingWallpaper;

  /// No description provided for @onlineWallpaperUrlSource.
  ///
  /// In en, this message translates to:
  /// **'Direct HTTPS URL'**
  String get onlineWallpaperUrlSource;

  /// No description provided for @updatePlayOnly.
  ///
  /// In en, this message translates to:
  /// **'This installation receives updates through Google Play.'**
  String get updatePlayOnly;

  /// No description provided for @updateCheck.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get updateCheck;

  /// No description provided for @updateInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get updateInstalled;

  /// No description provided for @updateDownloadInstall.
  ///
  /// In en, this message translates to:
  /// **'Download and install'**
  String get updateDownloadInstall;

  /// No description provided for @updateNoRelease.
  ///
  /// In en, this message translates to:
  /// **'No newer compatible release is available.'**
  String get updateNoRelease;

  /// No description provided for @updateIncompatible.
  ///
  /// In en, this message translates to:
  /// **'The APK does not match this application, certificate or a newer version. Installation was blocked.'**
  String get updateIncompatible;

  /// No description provided for @updateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to check, download or open the installer. Try again later.'**
  String get updateError;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @appUpdates.
  ///
  /// In en, this message translates to:
  /// **'Application updates'**
  String get appUpdates;

  /// No description provided for @updatePermission.
  ///
  /// In en, this message translates to:
  /// **'Allow installation from this application in Android settings, return here and press Install again.'**
  String get updatePermission;

  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Install downloaded update'**
  String get updateInstall;

  /// No description provided for @updateHint.
  ///
  /// In en, this message translates to:
  /// **'Source: GitHub / KirillShchetinnikov/CuteLauncher-Releases. Automatic checks run while the launcher is open. Download starts when you choose it; Android asks you to confirm installation. Your data is kept.'**
  String get updateHint;

  /// No description provided for @updateAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Check automatically once a day'**
  String get updateAutomatic;

  /// No description provided for @allApplications.
  ///
  /// In en, this message translates to:
  /// **'All applications'**
  String get allApplications;

  /// No description provided for @adbAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Enable Home Button Fix'**
  String get adbAccessibility;

  /// No description provided for @adbAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Approve ADB authorization on the TV, then try again.'**
  String get adbAuthorization;

  /// No description provided for @adbChangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Apply this system setting through ADB? The previous Home app is saved before changing it; other accessibility services are preserved.'**
  String get adbChangeConfirm;

  /// No description provided for @adbCheck.
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get adbCheck;

  /// No description provided for @adbDenied.
  ///
  /// In en, this message translates to:
  /// **'The system did not allow or confirm this change.'**
  String get adbDenied;

  /// No description provided for @adbDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable the previous launcher'**
  String get adbDisable;

  /// No description provided for @adbDisableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disable the saved previous launcher? This requires CuteLauncher to be the current Home app. Restore it with the recovery action in this setup.'**
  String get adbDisableConfirm;

  /// No description provided for @adbHint.
  ///
  /// In en, this message translates to:
  /// **'Prototype for this TV only (127.0.0.1). Enable TCP ADB in developer options, enter its port and approve the authorization prompt on the TV. Wireless debugging with a pairing code is not supported yet. The private key stays on this device, outside backups.'**
  String get adbHint;

  /// No description provided for @adbHome.
  ///
  /// In en, this message translates to:
  /// **'Make CuteLauncher the Home app'**
  String get adbHome;

  /// No description provided for @adbInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a port between 1024 and 65535.'**
  String get adbInvalid;

  /// No description provided for @adbNoRecovery.
  ///
  /// In en, this message translates to:
  /// **'Restoration is unavailable: no other launcher or saved service state was found.'**
  String get adbNoRecovery;

  /// No description provided for @adbPort.
  ///
  /// In en, this message translates to:
  /// **'TCP ADB port'**
  String get adbPort;

  /// No description provided for @adbReady.
  ///
  /// In en, this message translates to:
  /// **'ADB access confirmed.'**
  String get adbReady;

  /// No description provided for @adbRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore the previous launcher'**
  String get adbRestore;

  /// No description provided for @adbSuccess.
  ///
  /// In en, this message translates to:
  /// **'Change applied and verified.'**
  String get adbSuccess;

  /// No description provided for @adbTitle.
  ///
  /// In en, this message translates to:
  /// **'ADB setup'**
  String get adbTitle;

  /// No description provided for @adbUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check TCP ADB, the port and the authorization prompt.'**
  String get adbUnavailable;

  /// No description provided for @nightModeScheduled.
  ///
  /// In en, this message translates to:
  /// **'Use schedule'**
  String get nightModeScheduled;

  /// No description provided for @nightModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get nightModeTitle;

  /// No description provided for @nightModeScope.
  ///
  /// In en, this message translates to:
  /// **'Overlay permission is needed to dim other apps. Without it, dimming works inside CuteLauncher. The TCL filter needs no overlay permission. Above 80% opacity Android may block touch input in other apps; TV remote keys still work.'**
  String get nightModeScope;

  /// No description provided for @nightModeEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get nightModeEnd;

  /// No description provided for @nightModeStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get nightModeStart;

  /// No description provided for @nightModeDim.
  ///
  /// In en, this message translates to:
  /// **'Dimming'**
  String get nightModeDim;

  /// No description provided for @nightModeWarmth.
  ///
  /// In en, this message translates to:
  /// **'Warm filter'**
  String get nightModeWarmth;

  /// No description provided for @nightModeScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Uses local TV time. Overnight periods are supported. Equal start and end times disable the scheduled filter.'**
  String get nightModeScheduleHint;

  /// No description provided for @nightModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable night mode'**
  String get nightModeEnabled;

  /// No description provided for @nightModePermission.
  ///
  /// In en, this message translates to:
  /// **'Allow display over other apps'**
  String get nightModePermission;

  /// No description provided for @nightModePermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Display over other apps allowed'**
  String get nightModePermissionGranted;

  /// No description provided for @backupDownloadsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the backup to Downloads.'**
  String get backupDownloadsFailed;

  /// No description provided for @backupSaveDownloads.
  ///
  /// In en, this message translates to:
  /// **'Save backup to Downloads'**
  String get backupSaveDownloads;

  /// No description provided for @adbRestoreAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Restore accessibility access'**
  String get adbRestoreAccessibility;

  /// No description provided for @nightModeAdbConfirm.
  ///
  /// In en, this message translates to:
  /// **'Allow CuteLauncher to display over other apps using local ADB? Enable TCP debugging first and authorize the connection. Uses the port saved in the ADB wizard, or 5555.'**
  String get nightModeAdbConfirm;

  /// No description provided for @nightModeAdbPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant permission through ADB'**
  String get nightModeAdbPermission;

  /// No description provided for @nightModeNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'The notification lets you turn the filter off outside CuteLauncher. Without it, use this menu.'**
  String get nightModeNotificationsHint;

  /// No description provided for @nightModeNotificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Night mode notification allowed'**
  String get nightModeNotificationsAllowed;

  /// No description provided for @nightModeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow night mode notification'**
  String get nightModeNotifications;

  /// No description provided for @categoryLastVisibleHint.
  ///
  /// In en, this message translates to:
  /// **'At least one category must remain visible.'**
  String get categoryLastVisibleHint;

  /// No description provided for @diagnosticsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear report'**
  String get diagnosticsClear;

  /// No description provided for @diagnosticsReady.
  ///
  /// In en, this message translates to:
  /// **'Report ready'**
  String get diagnosticsReady;

  /// No description provided for @diagnosticsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create report'**
  String get diagnosticsCreate;

  /// No description provided for @diagnosticsOperations.
  ///
  /// In en, this message translates to:
  /// **'Recorded operations'**
  String get diagnosticsOperations;

  /// No description provided for @diagnosticsCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied'**
  String get diagnosticsCopied;

  /// No description provided for @diagnosticsHint.
  ///
  /// In en, this message translates to:
  /// **'The report contains the app version, permission state, memory usage and operation results. It excludes keys, addresses, file paths, app lists and notification content. Only the last 50 operations are kept in memory until the app restarts. Nothing is sent automatically.'**
  String get diagnosticsHint;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Error diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the report.'**
  String get diagnosticsCopyFailed;

  /// No description provided for @diagnosticsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get diagnosticsCopy;

  /// No description provided for @diagnosticsCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating report…'**
  String get diagnosticsCreating;

  /// No description provided for @tclBlueLightTitle.
  ///
  /// In en, this message translates to:
  /// **'TCL blue light filter'**
  String get tclBlueLightTitle;

  /// No description provided for @tclBlueLightError.
  ///
  /// In en, this message translates to:
  /// **'Could not read or verify the TCL filter setting. Refresh its state and try again.'**
  String get tclBlueLightError;

  /// No description provided for @tclBlueLightUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The TCL filter interface is unavailable on this TV.'**
  String get tclBlueLightUnsupported;

  /// No description provided for @tclBlueLightRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh TCL filter state'**
  String get tclBlueLightRefresh;

  /// No description provided for @tclBlueLightHint.
  ///
  /// In en, this message translates to:
  /// **'Controls the built-in Eye Health Protection filter of the TV. It can also follow the night mode schedule.'**
  String get tclBlueLightHint;

  /// No description provided for @nightSolarSchedule.
  ///
  /// In en, this message translates to:
  /// **'Sunset and sunrise'**
  String get nightSolarSchedule;

  /// No description provided for @nightNextStart.
  ///
  /// In en, this message translates to:
  /// **'Next start'**
  String get nightNextStart;

  /// No description provided for @nightScheduleTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Times use the TV time zone. Negative offsets are earlier; positive offsets are later.'**
  String get nightScheduleTimeHint;

  /// No description provided for @nightTemperature.
  ///
  /// In en, this message translates to:
  /// **'Filter color temperature'**
  String get nightTemperature;

  /// No description provided for @nightScheduleSettings.
  ///
  /// In en, this message translates to:
  /// **'Schedule settings'**
  String get nightScheduleSettings;

  /// No description provided for @nightCityName.
  ///
  /// In en, this message translates to:
  /// **'City name'**
  String get nightCityName;

  /// No description provided for @nightSkipUntilNext.
  ///
  /// In en, this message translates to:
  /// **'Disable night mode until the next sunset'**
  String get nightSkipUntilNext;

  /// No description provided for @nightSunriseOffset.
  ///
  /// In en, this message translates to:
  /// **'End relative to sunrise'**
  String get nightSunriseOffset;

  /// No description provided for @nightEnableUntilMorning.
  ///
  /// In en, this message translates to:
  /// **'Enable night mode until the next sunrise'**
  String get nightEnableUntilMorning;

  /// No description provided for @nightPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get nightPermissions;

  /// No description provided for @nightTclSchedule.
  ///
  /// In en, this message translates to:
  /// **'Include TCL filter in schedule'**
  String get nightTclSchedule;

  /// No description provided for @nightSearchCity.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get nightSearchCity;

  /// No description provided for @nightRefreshSun.
  ///
  /// In en, this message translates to:
  /// **'Refresh sunrise and sunset'**
  String get nightRefreshSun;

  /// No description provided for @nightSolarUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Choose a city and refresh sun times. If sunrise or sunset is unavailable, the solar schedule pauses.'**
  String get nightSolarUnavailable;

  /// No description provided for @nightSunsetOffset.
  ///
  /// In en, this message translates to:
  /// **'Start relative to sunset'**
  String get nightSunsetOffset;

  /// No description provided for @nightCityHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your city instead of granting location access. The selected coordinates are sent to Sunrise-Sunset.org, or Open-Meteo as a fallback, to retrieve sun times.'**
  String get nightCityHint;

  /// No description provided for @nightResumeSchedule.
  ///
  /// In en, this message translates to:
  /// **'Return to schedule'**
  String get nightResumeSchedule;

  /// No description provided for @nightScheduleSource.
  ///
  /// In en, this message translates to:
  /// **'Schedule type'**
  String get nightScheduleSource;

  /// No description provided for @nightSolarCached.
  ///
  /// In en, this message translates to:
  /// **'Using cached sun times; internet refresh will retry automatically.'**
  String get nightSolarCached;

  /// No description provided for @nightTclScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Uses the same schedule while night mode is enabled. Manual changes to the TCL filter last until the next scheduled transition. No overlay permission is needed.'**
  String get nightTclScheduleHint;

  /// No description provided for @nightRefreshPermission.
  ///
  /// In en, this message translates to:
  /// **'Refresh permission status'**
  String get nightRefreshPermission;

  /// No description provided for @nightCityNotFound.
  ///
  /// In en, this message translates to:
  /// **'No cities found. Try another name.'**
  String get nightCityNotFound;

  /// No description provided for @nightNoOffset.
  ///
  /// In en, this message translates to:
  /// **'No offset'**
  String get nightNoOffset;

  /// No description provided for @nightManualSchedule.
  ///
  /// In en, this message translates to:
  /// **'Custom schedule'**
  String get nightManualSchedule;

  /// No description provided for @nightChooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose city'**
  String get nightChooseCity;

  /// No description provided for @nightPermissionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Overlay permission status is unknown'**
  String get nightPermissionUnknown;

  /// No description provided for @nightNextEnd.
  ///
  /// In en, this message translates to:
  /// **'Next end'**
  String get nightNextEnd;

  /// No description provided for @nightTemporaryOff.
  ///
  /// In en, this message translates to:
  /// **'Dimming temporarily off until'**
  String get nightTemporaryOff;

  /// No description provided for @nightCitySearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not search for cities. Check your internet connection.'**
  String get nightCitySearchFailed;

  /// No description provided for @nightSolarAttribution.
  ///
  /// In en, this message translates to:
  /// **'Daily sun times: Sunrise-Sunset.org; fallback: Open-Meteo. City search: GeoNames. Several days are cached for offline use.'**
  String get nightSolarAttribution;

  /// No description provided for @nightTemporaryOn.
  ///
  /// In en, this message translates to:
  /// **'Dimming temporarily on until'**
  String get nightTemporaryOn;

  /// No description provided for @homeScreen.
  ///
  /// In en, this message translates to:
  /// **'Home screen'**
  String get homeScreen;

  /// No description provided for @appearanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSettings;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get generalSettings;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedSettings;

  /// No description provided for @controlAndStartup.
  ///
  /// In en, this message translates to:
  /// **'Launcher and TV controls'**
  String get controlAndStartup;

  /// No description provided for @sectionsAndOrder.
  ///
  /// In en, this message translates to:
  /// **'Sections and order'**
  String get sectionsAndOrder;

  /// No description provided for @topPanel.
  ///
  /// In en, this message translates to:
  /// **'Top panel'**
  String get topPanel;

  /// No description provided for @tileStyle.
  ///
  /// In en, this message translates to:
  /// **'Tile style'**
  String get tileStyle;

  /// No description provided for @tilesAndLabels.
  ///
  /// In en, this message translates to:
  /// **'Tiles and labels'**
  String get tilesAndLabels;

  /// No description provided for @highlightAndAnimation.
  ///
  /// In en, this message translates to:
  /// **'Highlight and animation'**
  String get highlightAndAnimation;

  /// No description provided for @androidTvSettings.
  ///
  /// In en, this message translates to:
  /// **'Android TV settings'**
  String get androidTvSettings;

  /// No description provided for @weatherSettings.
  ///
  /// In en, this message translates to:
  /// **'Weather settings'**
  String get weatherSettings;

  /// No description provided for @showHighlightOutline.
  ///
  /// In en, this message translates to:
  /// **'Show highlight outline'**
  String get showHighlightOutline;

  /// No description provided for @resetTilesAndPanel.
  ///
  /// In en, this message translates to:
  /// **'Reset tile and panel settings'**
  String get resetTilesAndPanel;

  /// No description provided for @resetTilesAndPanelHint.
  ///
  /// In en, this message translates to:
  /// **'Reset additional tile, label, highlight and top panel parameters? Wallpaper, accent color, tile style and label visibility are preserved.'**
  String get resetTilesAndPanelHint;

  /// No description provided for @panelAppearanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Top panel appearance'**
  String get panelAppearanceSettings;

  /// No description provided for @panelSharedHint.
  ///
  /// In en, this message translates to:
  /// **'Change the appearance in tile settings.'**
  String get panelSharedHint;

  /// No description provided for @effectsCompatibilityHint.
  ///
  /// In en, this message translates to:
  /// **'Additional appearance: the outline is always visible and does not pulse. Dimensional style has no legacy outline; classic does not pulse. Intensity affects scale and shadow; scaling is space-limited.'**
  String get effectsCompatibilityHint;

  /// No description provided for @sizeAndLayout.
  ///
  /// In en, this message translates to:
  /// **'Size and layout'**
  String get sizeAndLayout;

  /// No description provided for @labelsGroup.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labelsGroup;

  /// No description provided for @surfaceGroup.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get surfaceGroup;

  /// No description provided for @clockAndDateGroup.
  ///
  /// In en, this message translates to:
  /// **'Clock and date'**
  String get clockAndDateGroup;

  /// No description provided for @networkAndTrafficGroup.
  ///
  /// In en, this message translates to:
  /// **'Network and traffic'**
  String get networkAndTrafficGroup;

  /// No description provided for @buttonsGroup.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get buttonsGroup;

  /// No description provided for @notificationAppsHint.
  ///
  /// In en, this message translates to:
  /// **'Turn off apps whose notifications you do not need. An enabled switch allows notifications; the app can still be launched.'**
  String get notificationAppsHint;

  /// No description provided for @notificationPanelLink.
  ///
  /// In en, this message translates to:
  /// **'Top panel appearance'**
  String get notificationPanelLink;

  /// No description provided for @overlayAccessAdb.
  ///
  /// In en, this message translates to:
  /// **'Display over other apps (ADB)'**
  String get overlayAccessAdb;

  /// No description provided for @tileStyleModern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get tileStyleModern;

  /// No description provided for @tileStyleVolume.
  ///
  /// In en, this message translates to:
  /// **'Dimensional'**
  String get tileStyleVolume;

  /// No description provided for @showTime.
  ///
  /// In en, this message translates to:
  /// **'Show time'**
  String get showTime;

  /// No description provided for @showDate.
  ///
  /// In en, this message translates to:
  /// **'Show date'**
  String get showDate;

  /// No description provided for @showWeather.
  ///
  /// In en, this message translates to:
  /// **'Show weather'**
  String get showWeather;

  /// No description provided for @showNetwork.
  ///
  /// In en, this message translates to:
  /// **'Show network status'**
  String get showNetwork;

  /// No description provided for @showTraffic.
  ///
  /// In en, this message translates to:
  /// **'Show traffic'**
  String get showTraffic;

  /// No description provided for @scheduledBrightness.
  ///
  /// In en, this message translates to:
  /// **'Scheduled brightness'**
  String get scheduledBrightness;

  /// No description provided for @followTileStyle.
  ///
  /// In en, this message translates to:
  /// **'Follow style'**
  String get followTileStyle;

  /// No description provided for @androidTvSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Open the TV system settings'**
  String get androidTvSettingsHint;

  /// No description provided for @autoHideTopPanel.
  ///
  /// In en, this message translates to:
  /// **'Automatically hide the panel'**
  String get autoHideTopPanel;

  /// No description provided for @showSectionTitles.
  ///
  /// In en, this message translates to:
  /// **'Show section titles'**
  String get showSectionTitles;

  /// No description provided for @usageDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get usageDaily;

  /// No description provided for @usageWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get usageWeekly;

  /// No description provided for @usageMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get usageMonthly;

  /// No description provided for @onlineWallpaperAddress.
  ///
  /// In en, this message translates to:
  /// **'Image address (HTTPS)'**
  String get onlineWallpaperAddress;

  /// No description provided for @watchNextAppLimits.
  ///
  /// In en, this message translates to:
  /// **'Limits per app'**
  String get watchNextAppLimits;

  /// No description provided for @watchNextAppLimitsHint.
  ///
  /// In en, this message translates to:
  /// **'Source limits apply before the overall limit. Unlimited keeps only the overall limit; hidden content stays hidden.'**
  String get watchNextAppLimitsHint;

  /// No description provided for @rememberCategoryFocus.
  ///
  /// In en, this message translates to:
  /// **'Remember last focused card'**
  String get rememberCategoryFocus;

  /// No description provided for @automaticBackups.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get automaticBackups;

  /// No description provided for @automaticBackupsHint.
  ///
  /// In en, this message translates to:
  /// **'Daily copies of settings, wallpapers and banners while the launcher is active. A missed copy runs after returning to the launcher. Stored privately on this device, up to 256 MiB total; removing the app or its data deletes them. Keep an external backup too.'**
  String get automaticBackupsHint;

  /// No description provided for @automaticBackupsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Daily automatic backup'**
  String get automaticBackupsEnabled;

  /// No description provided for @automaticBackupsKeep.
  ///
  /// In en, this message translates to:
  /// **'Copies to keep'**
  String get automaticBackupsKeep;

  /// No description provided for @automaticBackupCreateNow.
  ///
  /// In en, this message translates to:
  /// **'Create a restore point now'**
  String get automaticBackupCreateNow;

  /// No description provided for @automaticBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup operation failed. Check free space and try again.'**
  String get automaticBackupFailed;

  /// No description provided for @restorePoints.
  ///
  /// In en, this message translates to:
  /// **'Restore points'**
  String get restorePoints;

  /// No description provided for @noRestorePoints.
  ///
  /// In en, this message translates to:
  /// **'No restore points yet'**
  String get noRestorePoints;

  /// No description provided for @updatePrereleases.
  ///
  /// In en, this message translates to:
  /// **'Update to prereleases'**
  String get updatePrereleases;

  /// No description provided for @topPanelObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get topPanelObjects;

  /// No description provided for @panelTransparency.
  ///
  /// In en, this message translates to:
  /// **'Panel transparency'**
  String get panelTransparency;

  /// No description provided for @panelTextBackground.
  ///
  /// In en, this message translates to:
  /// **'Text and button background'**
  String get panelTextBackground;

  /// No description provided for @panelTextBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Text and button background color'**
  String get panelTextBackgroundColor;

  /// No description provided for @panelTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text and button color'**
  String get panelTextColor;

  /// No description provided for @panelTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text and button size'**
  String get panelTextSize;

  /// No description provided for @panelFont.
  ///
  /// In en, this message translates to:
  /// **'Text font'**
  String get panelFont;

  /// No description provided for @fontSans.
  ///
  /// In en, this message translates to:
  /// **'Sans serif'**
  String get fontSans;

  /// No description provided for @fontSerif.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get fontSerif;

  /// No description provided for @fontMono.
  ///
  /// In en, this message translates to:
  /// **'Monospace'**
  String get fontMono;

  /// No description provided for @fontCondensed.
  ///
  /// In en, this message translates to:
  /// **'Condensed'**
  String get fontCondensed;

  /// No description provided for @trafficPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Traffic statistics access granted'**
  String get trafficPermissionGranted;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @backgroundParameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get backgroundParameters;

  /// No description provided for @resetAppearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Reset background, accent, tiles, labels, highlighting and animation?'**
  String get resetAppearanceHint;

  /// No description provided for @wallpaperDimming.
  ///
  /// In en, this message translates to:
  /// **'Dimming'**
  String get wallpaperDimming;

  /// No description provided for @wallpaperPlacement.
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get wallpaperPlacement;

  /// No description provided for @wallpaperDisplay.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper display'**
  String get wallpaperDisplay;

  /// No description provided for @wallpaperContain.
  ///
  /// In en, this message translates to:
  /// **'Show whole image'**
  String get wallpaperContain;

  /// No description provided for @wallpaperBlurred.
  ///
  /// In en, this message translates to:
  /// **'Over blurred copy'**
  String get wallpaperBlurred;

  /// No description provided for @wallpaperCover.
  ///
  /// In en, this message translates to:
  /// **'Fill screen'**
  String get wallpaperCover;

  /// No description provided for @wallpaperBrightness.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper brightness'**
  String get wallpaperBrightness;

  /// No description provided for @wallpaperSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get wallpaperSaturation;

  /// No description provided for @categoryPadding.
  ///
  /// In en, this message translates to:
  /// **'Category padding'**
  String get categoryPadding;

  /// No description provided for @categoryLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get categoryLight;

  /// No description provided for @categoryBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get categoryBlue;

  /// No description provided for @categoryPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get categoryPurple;

  /// No description provided for @categoryAllRows.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAllRows;

  /// No description provided for @categoryTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get categoryTeal;

  /// No description provided for @categoryMaxRows.
  ///
  /// In en, this message translates to:
  /// **'Visible grid rows'**
  String get categoryMaxRows;

  /// No description provided for @categoryDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get categoryDark;

  /// No description provided for @categoryAppearance.
  ///
  /// In en, this message translates to:
  /// **'Category appearance'**
  String get categoryAppearance;

  /// No description provided for @categoryBackground.
  ///
  /// In en, this message translates to:
  /// **'Category background'**
  String get categoryBackground;

  /// No description provided for @categoryTransparent.
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get categoryTransparent;

  /// No description provided for @slideshowInterval.
  ///
  /// In en, this message translates to:
  /// **'Change interval'**
  String get slideshowInterval;

  /// No description provided for @slideshowFolderSelected.
  ///
  /// In en, this message translates to:
  /// **'Folder access saved on this device.'**
  String get slideshowFolderSelected;

  /// No description provided for @slideshowRandom.
  ///
  /// In en, this message translates to:
  /// **'Random order'**
  String get slideshowRandom;

  /// No description provided for @wallpaperSlideshow.
  ///
  /// In en, this message translates to:
  /// **'Folder slideshow'**
  String get wallpaperSlideshow;

  /// No description provided for @slideshowNext.
  ///
  /// In en, this message translates to:
  /// **'Next image'**
  String get slideshowNext;

  /// No description provided for @slideshowFolderRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder to start the slideshow.'**
  String get slideshowFolderRequired;

  /// No description provided for @slideshowHint.
  ///
  /// In en, this message translates to:
  /// **'Up to 1,000 images and 4,000 folder entries; files up to 8 MiB. Corrupt files are skipped and the last good image is retained. Changes stop in the background. Choose the folder again after restoring on another device.'**
  String get slideshowHint;

  /// No description provided for @slideshowSeconds.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get slideshowSeconds;

  /// No description provided for @slideshowError.
  ///
  /// In en, this message translates to:
  /// **'Unable to read images. Choose an accessible folder containing valid images.'**
  String get slideshowError;

  /// No description provided for @slideshowFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get slideshowFolder;

  /// No description provided for @slideshowRecursive.
  ///
  /// In en, this message translates to:
  /// **'Include subfolders'**
  String get slideshowRecursive;

  /// No description provided for @weatherSourceKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Add an API key for this weather source.'**
  String get weatherSourceKeyRequired;

  /// No description provided for @weatherOpenWeatherCredit.
  ///
  /// In en, this message translates to:
  /// **'Weather: OpenWeather (openweathermap.org). Daily values summarize the available three-hour forecast periods.'**
  String get weatherOpenWeatherCredit;

  /// No description provided for @weatherOpenWeatherHint.
  ///
  /// In en, this message translates to:
  /// **'Use your key for Current Weather and 5 day / 3 hour Forecast. Each update makes two requests; access and limits depend on your plan.'**
  String get weatherOpenWeatherHint;

  /// No description provided for @weatherOpenWeatherKey.
  ///
  /// In en, this message translates to:
  /// **'OpenWeather API key'**
  String get weatherOpenWeatherKey;

  /// No description provided for @mediaPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get mediaPause;

  /// No description provided for @showNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Show Now playing on Home'**
  String get showNowPlaying;

  /// No description provided for @nowPlayingAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Media controls require notification access for CuteLauncher. Only actions provided by the player are shown.'**
  String get nowPlayingAccessHint;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @mediaNext.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get mediaNext;

  /// No description provided for @mediaPlay.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get mediaPlay;

  /// No description provided for @mediaControlError.
  ///
  /// In en, this message translates to:
  /// **'The player is unavailable or did not accept this action.'**
  String get mediaControlError;

  /// No description provided for @nightUsageAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow usage access'**
  String get nightUsageAccess;

  /// No description provided for @nightExcludedAppsHint.
  ///
  /// In en, this message translates to:
  /// **'The overlay and scheduled TCL filter pause in selected apps. Usage access is required; without it, exclusions cannot be applied.'**
  String get nightExcludedAppsHint;

  /// No description provided for @nightExcludedApps.
  ///
  /// In en, this message translates to:
  /// **'Excluded apps'**
  String get nightExcludedApps;

  /// No description provided for @adbPairPort.
  ///
  /// In en, this message translates to:
  /// **'Pairing port'**
  String get adbPairPort;

  /// No description provided for @adbPairOverlayHint.
  ///
  /// In en, this message translates to:
  /// **'Open Wireless debugging and Pair with pairing code. Keep the system code dialog open. This form becomes active after 30 seconds. Enter both ports and the code shown by Android.'**
  String get adbPairOverlayHint;

  /// No description provided for @adbOverlaySettings.
  ///
  /// In en, this message translates to:
  /// **'Return control to Settings for 30 seconds'**
  String get adbOverlaySettings;

  /// No description provided for @adbTlsHint.
  ///
  /// In en, this message translates to:
  /// **'Use Wireless debugging in Developer options. Pairing and connection have different ports. If your firmware has no pairing-code screen or blocks overlay windows, use TCP / RSA instead. All connections remain local to this TV.'**
  String get adbTlsHint;

  /// No description provided for @adbPaired.
  ///
  /// In en, this message translates to:
  /// **'Paired. Check the connection using the Wireless debugging connection port.'**
  String get adbPaired;

  /// No description provided for @adbTransport.
  ///
  /// In en, this message translates to:
  /// **'Connection method'**
  String get adbTransport;

  /// No description provided for @adbPairCode.
  ///
  /// In en, this message translates to:
  /// **'Six-digit code'**
  String get adbPairCode;

  /// No description provided for @adbOverlayRequired.
  ///
  /// In en, this message translates to:
  /// **'Code entry over Settings requires permission to display over other apps.'**
  String get adbOverlayRequired;

  /// No description provided for @adbOverlayPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow display over other apps'**
  String get adbOverlayPermission;

  /// No description provided for @adbTlsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This firmware cannot open the required Settings screen or pairing overlay. Use TCP / RSA.'**
  String get adbTlsUnsupported;

  /// No description provided for @adbConnectPort.
  ///
  /// In en, this message translates to:
  /// **'Connection port'**
  String get adbConnectPort;

  /// No description provided for @adbTls.
  ///
  /// In en, this message translates to:
  /// **'TLS / pairing code'**
  String get adbTls;

  /// No description provided for @adbTcp.
  ///
  /// In en, this message translates to:
  /// **'TCP / RSA'**
  String get adbTcp;

  /// No description provided for @adbPairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed. Check the code and pairing port, keep the Android code dialog open, and try again.'**
  String get adbPairingFailed;

  /// No description provided for @adbTlsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Wireless debugging is disabled or its state is unavailable. Enable it in Developer options.'**
  String get adbTlsDisabled;

  /// No description provided for @adbPairOverlay.
  ///
  /// In en, this message translates to:
  /// **'Enter pairing code over Settings'**
  String get adbPairOverlay;

  /// No description provided for @adbPair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get adbPair;

  /// No description provided for @adbDeveloperSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Developer options'**
  String get adbDeveloperSettings;

  /// No description provided for @adbTwoWindowsHint.
  ///
  /// In en, this message translates to:
  /// **'If this firmware supports two windows, keep the system pairing dialog open beside CuteLauncher and enter its code here. Direct pairing is available only while both windows are open.'**
  String get adbTwoWindowsHint;

  /// No description provided for @adbTwoWindows.
  ///
  /// In en, this message translates to:
  /// **'Open Settings in a second window'**
  String get adbTwoWindows;

  /// No description provided for @autoLaunchBoot.
  ///
  /// In en, this message translates to:
  /// **'After TV boot'**
  String get autoLaunchBoot;

  /// No description provided for @autoLaunchOff.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get autoLaunchOff;

  /// No description provided for @autoLaunchTitle.
  ///
  /// In en, this message translates to:
  /// **'Autostart'**
  String get autoLaunchTitle;

  /// No description provided for @autoLaunchDelay.
  ///
  /// In en, this message translates to:
  /// **'Launch delay'**
  String get autoLaunchDelay;

  /// No description provided for @autoLaunchHdmi.
  ///
  /// In en, this message translates to:
  /// **'Switch to a selected HDMI input'**
  String get autoLaunchHdmi;

  /// No description provided for @autoLaunchWake.
  ///
  /// In en, this message translates to:
  /// **'After wake'**
  String get autoLaunchWake;

  /// No description provided for @autoLaunchHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an app or HDMI input to open after TV startup or wake. Set the event and delay below. The action runs once when Android shows CuteLauncher. Any remote input or leaving the home screen cancels the wait. You can freely change HDMI inputs afterward. Set CuteLauncher as the default launcher or enable Start on boot if needed. Wake detection requires CuteLauncher to remain running.'**
  String get autoLaunchHint;

  /// No description provided for @autoLaunchSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String autoLaunchSeconds(int seconds);

  /// No description provided for @autoLaunchApp.
  ///
  /// In en, this message translates to:
  /// **'Open a selected app'**
  String get autoLaunchApp;

  /// No description provided for @autoLaunchTarget.
  ///
  /// In en, this message translates to:
  /// **'Launch target'**
  String get autoLaunchTarget;

  /// No description provided for @autoLaunchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The target is unavailable or the firmware does not allow this action.'**
  String get autoLaunchUnavailable;

  /// No description provided for @autoLaunchCancelled.
  ///
  /// In en, this message translates to:
  /// **'Delayed launch cancelled.'**
  String get autoLaunchCancelled;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchange settings'**
  String get syncTitle;

  /// No description provided for @syncHint.
  ///
  /// In en, this message translates to:
  /// **'Save a settings file, transfer it to another device and open it there. Exchange the file back to bring both devices up to date. Interface, tile style and display preferences are shared. Apps, sections, wallpaper files, permissions, HOME, launch rules and secrets stay on this device. This is manual exchange; no account or background network connection is used.'**
  String get syncHint;

  /// No description provided for @syncExport.
  ///
  /// In en, this message translates to:
  /// **'Save changes to a file'**
  String get syncExport;

  /// No description provided for @syncImport.
  ///
  /// In en, this message translates to:
  /// **'Open changes from another device'**
  String get syncImport;

  /// No description provided for @syncSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings exchange file saved.'**
  String get syncSaved;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to exchange settings. No partial import is kept. Check the file or open it again if settings changed during review.'**
  String get syncFailed;

  /// No description provided for @syncPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Review changes before applying. For conflicts, select each row to choose this device or the file. Keeping this device is selected initially. Cancel leaves settings unchanged.'**
  String get syncPreviewHint;

  /// No description provided for @syncNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No new settings. Apply to acknowledge the shared history.'**
  String get syncNoChanges;

  /// No description provided for @syncLocalValue.
  ///
  /// In en, this message translates to:
  /// **'This device: {value}'**
  String syncLocalValue(String value);

  /// No description provided for @syncFileValue.
  ///
  /// In en, this message translates to:
  /// **'From file: {value}'**
  String syncFileValue(String value);

  /// No description provided for @syncKeepLocal.
  ///
  /// In en, this message translates to:
  /// **'Conflict: keep this device'**
  String get syncKeepLocal;

  /// No description provided for @syncUseFile.
  ///
  /// In en, this message translates to:
  /// **'Conflict: use the file'**
  String get syncUseFile;

  /// No description provided for @syncApply.
  ///
  /// In en, this message translates to:
  /// **'Apply reviewed changes'**
  String get syncApply;

  /// No description provided for @syncApplied.
  ///
  /// In en, this message translates to:
  /// **'Settings exchanged. Save a new file to send the result back.'**
  String get syncApplied;

  /// No description provided for @syncStyleParameters.
  ///
  /// In en, this message translates to:
  /// **'Custom style: {count} parameters (differences below)'**
  String syncStyleParameters(int count);

  /// No description provided for @cloudBackups.
  ///
  /// In en, this message translates to:
  /// **'Cloud backups'**
  String get cloudBackups;

  /// No description provided for @cloudHelp.
  ///
  /// In en, this message translates to:
  /// **'WebDAV / Nextcloud. Enter the HTTPS address of an existing folder and an app password. Transfers are manual; this folder stores the latest copy.'**
  String get cloudHelp;

  /// No description provided for @cloudUrl.
  ///
  /// In en, this message translates to:
  /// **'Folder HTTPS address'**
  String get cloudUrl;

  /// No description provided for @cloudUser.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get cloudUser;

  /// No description provided for @cloudPassword.
  ///
  /// In en, this message translates to:
  /// **'App password'**
  String get cloudPassword;

  /// No description provided for @cloudConnect.
  ///
  /// In en, this message translates to:
  /// **'Check and save account'**
  String get cloudConnect;

  /// No description provided for @cloudCheck.
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get cloudCheck;

  /// No description provided for @cloudDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect account'**
  String get cloudDisconnect;

  /// No description provided for @cloudDisconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this account from the TV? Copies in the cloud will remain.'**
  String get cloudDisconnectConfirm;

  /// No description provided for @cloudUpload.
  ///
  /// In en, this message translates to:
  /// **'Save a copy to the cloud'**
  String get cloudUpload;

  /// No description provided for @cloudDownload.
  ///
  /// In en, this message translates to:
  /// **'Restore from the cloud'**
  String get cloudDownload;

  /// No description provided for @cloudUploadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace cutelauncher_backup.json in this folder with the current settings and data?'**
  String get cloudUploadConfirm;

  /// No description provided for @cloudSuccess.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cloudSuccess;

  /// No description provided for @cloudConfigurationError.
  ///
  /// In en, this message translates to:
  /// **'Check the HTTPS folder address, username and app password.'**
  String get cloudConfigurationError;

  /// No description provided for @cloudAuthorizationError.
  ///
  /// In en, this message translates to:
  /// **'Access denied. Check your account and folder permissions.'**
  String get cloudAuthorizationError;

  /// No description provided for @cloudMissingError.
  ///
  /// In en, this message translates to:
  /// **'The folder or backup was not found.'**
  String get cloudMissingError;

  /// No description provided for @cloudUnsupportedError.
  ///
  /// In en, this message translates to:
  /// **'This address does not support the required WebDAV operations. Redirects are not followed; enter the final folder address.'**
  String get cloudUnsupportedError;

  /// No description provided for @cloudNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Connection failed or timed out. Try again when the network is available.'**
  String get cloudNetworkError;

  /// No description provided for @cloudFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the backup action. Check storage access and try again.'**
  String get cloudFailed;

  /// No description provided for @cloudStorageError.
  ///
  /// In en, this message translates to:
  /// **'Account storage is unavailable. Disconnect and configure the account again.'**
  String get cloudStorageError;

  /// No description provided for @adbPermissionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking access…'**
  String get adbPermissionChecking;

  /// No description provided for @adbPermissionConnected.
  ///
  /// In en, this message translates to:
  /// **'ADB connected · grant permission'**
  String get adbPermissionConnected;

  /// No description provided for @adbPermissionDisconnected.
  ///
  /// In en, this message translates to:
  /// **'ADB disconnected · set up connection'**
  String get adbPermissionDisconnected;

  /// No description provided for @adbSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'Enable debugging and network ADB in the TV developer settings, then trust CuteLauncher. All ADB actions are at your own risk.'**
  String get adbSetupIntro;

  /// No description provided for @adbConnectionBlock.
  ///
  /// In en, this message translates to:
  /// **'ADB connection'**
  String get adbConnectionBlock;

  /// No description provided for @adbNotChecked.
  ///
  /// In en, this message translates to:
  /// **'Connection not checked'**
  String get adbNotChecked;

  /// No description provided for @adbApplied.
  ///
  /// In en, this message translates to:
  /// **'Already applied'**
  String get adbApplied;

  /// No description provided for @adbNotApplied.
  ///
  /// In en, this message translates to:
  /// **'Not applied yet'**
  String get adbNotApplied;

  /// No description provided for @adbDefaultBlock.
  ///
  /// In en, this message translates to:
  /// **'Default launcher'**
  String get adbDefaultBlock;

  /// No description provided for @adbSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'Open system default launcher setting'**
  String get adbSystemDefault;

  /// No description provided for @adbAssignDefault.
  ///
  /// In en, this message translates to:
  /// **'Set CuteLauncher as default launcher via ADB'**
  String get adbAssignDefault;

  /// No description provided for @adbRestoreDefault.
  ///
  /// In en, this message translates to:
  /// **'Restore the previous default launcher via ADB'**
  String get adbRestoreDefault;

  /// No description provided for @adbDefaultHint.
  ///
  /// In en, this message translates to:
  /// **'Use ADB if the system menu cannot set the default launcher.'**
  String get adbDefaultHint;

  /// No description provided for @adbBuiltinHint.
  ///
  /// In en, this message translates to:
  /// **'Disabling the built-in launcher lets the system open CuteLauncher instead. TV menus and buttons may be affected. Enable the built-in launcher to undo this.'**
  String get adbBuiltinHint;

  /// No description provided for @adbHomeBlock.
  ///
  /// In en, this message translates to:
  /// **'Home button and startup'**
  String get adbHomeBlock;

  /// No description provided for @adbEnableService.
  ///
  /// In en, this message translates to:
  /// **'Enable CuteLauncher accessibility service via ADB'**
  String get adbEnableService;

  /// No description provided for @adbHomeOverride.
  ///
  /// In en, this message translates to:
  /// **'Override the Home button'**
  String get adbHomeOverride;

  /// No description provided for @adbHomeOptional.
  ///
  /// In en, this message translates to:
  /// **'If the built-in launcher is disabled, overriding Home and launching at TV startup are optional.'**
  String get adbHomeOptional;

  /// No description provided for @adbEnableBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Enable built-in launcher via ADB'**
  String get adbEnableBuiltin;

  /// No description provided for @adbDisableBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Disable built-in launcher via ADB'**
  String get adbDisableBuiltin;

  /// No description provided for @adbNoBuiltin.
  ///
  /// In en, this message translates to:
  /// **'No built-in Google TV / Android TV launchers found.'**
  String get adbNoBuiltin;

  /// No description provided for @adbChanged.
  ///
  /// In en, this message translates to:
  /// **'State changed. Check the connection and confirm the action again.'**
  String get adbChanged;

  /// No description provided for @adbEffectHome.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher will become the system default launcher. The current launcher will be saved for restoration.'**
  String get adbEffectHome;

  /// No description provided for @adbEffectRestore.
  ///
  /// In en, this message translates to:
  /// **'The previous launcher will be enabled and made default. If unavailable or not saved, the first available other launcher is selected. This does not disable Home Button Fix.'**
  String get adbEffectRestore;

  /// No description provided for @adbEffectDisable.
  ///
  /// In en, this message translates to:
  /// **'The built-in launcher app will be disabled for the TV user. TV menus and buttons may stop working. The app is not uninstalled.'**
  String get adbEffectDisable;

  /// No description provided for @adbRecoveryHomeDisable.
  ///
  /// In en, this message translates to:
  /// **'The entire Google TV setup wizard, including its recovery home screen, will also be disabled so that CuteLauncher can become the default launcher. Setup wizard features will be unavailable until restoration. The original states of both packages will be saved for restoration.'**
  String get adbRecoveryHomeDisable;

  /// No description provided for @adbRecoveryHomeRestore.
  ///
  /// In en, this message translates to:
  /// **'The Google TV setup wizard will also return to its saved state.'**
  String get adbRecoveryHomeRestore;

  /// No description provided for @adbDisableHomeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Another home screen has a higher priority. It cannot be disabled safely by this launcher.'**
  String get adbDisableHomeUnavailable;

  /// No description provided for @adbEffectEnable.
  ///
  /// In en, this message translates to:
  /// **'The built-in launcher will be restored to its saved state, or enabled if no state was saved. The system may select it as the default launcher again.'**
  String get adbEffectEnable;

  /// No description provided for @adbEffectAccessibility.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher accessibility service will be enabled. It can receive Home events; interception is controlled by a separate switch. Other services are preserved.'**
  String get adbEffectAccessibility;

  /// No description provided for @adbEffectAccessibilityRestore.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher service will return to its state before ADB access was granted. Other accessibility services are preserved.'**
  String get adbEffectAccessibilityRestore;

  /// No description provided for @adbEffectOverlay.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher will be allowed to display windows over other apps, including the night filter.'**
  String get adbEffectOverlay;

  /// No description provided for @adbEffectNotifications.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher will receive notification access through its own listener service.'**
  String get adbEffectNotifications;

  /// No description provided for @adbEffectWatchNext.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher will receive access to Continue watching data.'**
  String get adbEffectWatchNext;

  /// No description provided for @adbEffectUsage.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher will receive usage statistics access for traffic and foreground app detection.'**
  String get adbEffectUsage;

  /// No description provided for @adbEffectWriteSettings.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher will be allowed to change system brightness settings.'**
  String get adbEffectWriteSettings;

  /// No description provided for @adbNoAvailableLauncher.
  ///
  /// In en, this message translates to:
  /// **'No other installed launchers were found. Restoration is unavailable.'**
  String get adbNoAvailableLauncher;

  /// No description provided for @adbUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unavailable on this device: no supported ADB command.'**
  String get adbUnsupported;

  /// No description provided for @adbHomeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The built-in launcher has system priority. Direct assignment through ADB is unavailable; use accessibility or disable the built-in launcher.'**
  String get adbHomeUnavailable;

  /// No description provided for @nightBatteryExempt.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher is exempt from optimization'**
  String get nightBatteryExempt;

  /// No description provided for @nightBatteryHint.
  ///
  /// In en, this message translates to:
  /// **'May help the schedule run in the background. Does not guarantee the process survives standby.'**
  String get nightBatteryHint;

  /// No description provided for @nightBatteryOptimized.
  ///
  /// In en, this message translates to:
  /// **'CuteLauncher is subject to optimization'**
  String get nightBatteryOptimized;

  /// No description provided for @nightBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization'**
  String get nightBatteryTitle;

  /// No description provided for @nightBatteryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'System settings are unavailable on this firmware or access was denied.'**
  String get nightBatteryUnavailable;

  /// No description provided for @nightBatteryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Exemption status unknown'**
  String get nightBatteryUnknown;

  /// No description provided for @nightBatteryOpenApps.
  ///
  /// In en, this message translates to:
  /// **'Open Apps settings'**
  String get nightBatteryOpenApps;

  /// No description provided for @nightBatteryGuide.
  ///
  /// In en, this message translates to:
  /// **'1. In Apps settings, open Special app access.\n2. Select Battery optimization (sometimes Energy saver).\n3. Find CuteLauncher; select All apps if needed.\n4. Disable optimization or select Unrestricted.\nMenu names and availability depend on the TV firmware.'**
  String get nightBatteryGuide;

  /// No description provided for @updateNotifications.
  ///
  /// In en, this message translates to:
  /// **'Show update notifications'**
  String get updateNotifications;

  /// No description provided for @diagnosticsSave.
  ///
  /// In en, this message translates to:
  /// **'Save report to file'**
  String get diagnosticsSave;

  /// No description provided for @diagnosticsSaved.
  ///
  /// In en, this message translates to:
  /// **'Report saved'**
  String get diagnosticsSaved;

  /// No description provided for @diagnosticsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the report. Check the file manager and destination folder.'**
  String get diagnosticsSaveFailed;

  /// No description provided for @memoryCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Image cache size'**
  String get memoryCacheSize;

  /// No description provided for @memoryProcess.
  ///
  /// In en, this message translates to:
  /// **'App memory'**
  String get memoryProcess;

  /// No description provided for @memoryImages.
  ///
  /// In en, this message translates to:
  /// **'Image caches'**
  String get memoryImages;

  /// No description provided for @diagnosticsExportOpened.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder in the file manager and save the report.'**
  String get diagnosticsExportOpened;

  /// No description provided for @adbDisableService.
  ///
  /// In en, this message translates to:
  /// **'Disable CuteLauncher accessibility service via ADB'**
  String get adbDisableService;

  /// No description provided for @adbDefaultSettings.
  ///
  /// In en, this message translates to:
  /// **'Default launcher settings'**
  String get adbDefaultSettings;

  /// No description provided for @adbHomeSettings.
  ///
  /// In en, this message translates to:
  /// **'Home button settings'**
  String get adbHomeSettings;

  /// No description provided for @adbAccessibilitySettings.
  ///
  /// In en, this message translates to:
  /// **'Open accessibility settings'**
  String get adbAccessibilitySettings;

  /// No description provided for @adbAccessibilityGuide.
  ///
  /// In en, this message translates to:
  /// **'Select CuteLauncher in the system menu and enable its service. Return here to configure Home interception. To disable it, turn off the CuteLauncher service in the same menu.'**
  String get adbAccessibilityGuide;

  /// No description provided for @adbEffectAccessibilityDisable.
  ///
  /// In en, this message translates to:
  /// **'The CuteLauncher service will be disabled. Home interception will stop. Other accessibility services are preserved.'**
  String get adbEffectAccessibilityDisable;

  /// No description provided for @backupAutoEnabled.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get backupAutoEnabled;

  /// No description provided for @backupClientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get backupClientId;

  /// No description provided for @backupClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Client Secret'**
  String get backupClientSecret;

  /// No description provided for @backupCloudImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'All local settings, categories and images will be replaced with cloud data. Continue?'**
  String get backupCloudImportConfirm;

  /// No description provided for @backupConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get backupConfigured;

  /// No description provided for @backupConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection settings'**
  String get backupConnection;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get backupCreated;

  /// No description provided for @backupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get backupDaily;

  /// No description provided for @backupDriveHelp.
  ///
  /// In en, this message translates to:
  /// **'Select Connect and confirm the code on your phone. Backups are visible in the CuteLauncher folder in Google Drive, where you can download or delete them. Keep file names unchanged for in-app restore. Reconnect after upgrading from hidden backups; old backups are not migrated automatically.'**
  String get backupDriveHelp;

  /// No description provided for @backupFrequency.
  ///
  /// In en, this message translates to:
  /// **'Backup frequency'**
  String get backupFrequency;

  /// No description provided for @backupHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get backupHourly;

  /// No description provided for @backupLocal.
  ///
  /// In en, this message translates to:
  /// **'Local copies'**
  String get backupLocal;

  /// No description provided for @backupMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get backupMinutes;

  /// No description provided for @backupMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get backupMode;

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get backupNever;

  /// No description provided for @backupNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get backupNotConfigured;

  /// No description provided for @backupOptions.
  ///
  /// In en, this message translates to:
  /// **'Backup options'**
  String get backupOptions;

  /// No description provided for @backupSaveMode.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupSaveMode;

  /// No description provided for @backupScope.
  ///
  /// In en, this message translates to:
  /// **'Backup across TVs'**
  String get backupScope;

  /// No description provided for @backupSyncScope.
  ///
  /// In en, this message translates to:
  /// **'Synchronization across TVs'**
  String get backupSyncScope;

  /// No description provided for @backupSeparate.
  ///
  /// In en, this message translates to:
  /// **'Separate for each TV'**
  String get backupSeparate;

  /// No description provided for @backupShared.
  ///
  /// In en, this message translates to:
  /// **'Same settings for all TVs'**
  String get backupShared;

  /// No description provided for @backupStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get backupStorage;

  /// No description provided for @backupSyncHelp.
  ///
  /// In en, this message translates to:
  /// **'Download data and upload changes. The latest change wins conflicts. TV clocks must be correct. Synchronization runs while the launcher is open.'**
  String get backupSyncHelp;

  /// No description provided for @backupSyncLimit.
  ///
  /// In en, this message translates to:
  /// **'Check no more often than'**
  String get backupSyncLimit;

  /// No description provided for @backupSyncMode.
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get backupSyncMode;

  /// No description provided for @backupSyncOptions.
  ///
  /// In en, this message translates to:
  /// **'Synchronization options'**
  String get backupSyncOptions;

  /// No description provided for @backupTime.
  ///
  /// In en, this message translates to:
  /// **'Backup time'**
  String get backupTime;

  /// No description provided for @backupWeekday.
  ///
  /// In en, this message translates to:
  /// **'Day of week'**
  String get backupWeekday;

  /// No description provided for @backupWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get backupWeekly;

  /// No description provided for @backupGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get backupGoogleDrive;

  /// No description provided for @backupLocalHelp.
  ///
  /// In en, this message translates to:
  /// **'Local copies are deleted with the app or its data. Keep a copy outside the TV too.'**
  String get backupLocalHelp;

  /// No description provided for @panelObjectOrder.
  ///
  /// In en, this message translates to:
  /// **'Object order'**
  String get panelObjectOrder;

  /// No description provided for @panelInformationGroup.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get panelInformationGroup;

  /// No description provided for @panelOrderHint.
  ///
  /// In en, this message translates to:
  /// **'◄ / ► selects or finishes moving; ▲ / ▼ reorders objects and moves them between sides at group boundaries; OK / Back finishes moving.'**
  String get panelOrderHint;

  /// No description provided for @panelTextBackgroundTransparency.
  ///
  /// In en, this message translates to:
  /// **'Text and button background transparency'**
  String get panelTextBackgroundTransparency;

  /// No description provided for @weatherCityHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the city name in English, for example Moscow.'**
  String get weatherCityHint;

  /// No description provided for @weatherCityNotFound.
  ///
  /// In en, this message translates to:
  /// **'City not found. Check the city name in English.'**
  String get weatherCityNotFound;

  /// No description provided for @weatherLocationAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Get automatically'**
  String get weatherLocationAutomatic;

  /// No description provided for @weatherLocationAutomaticHint.
  ///
  /// In en, this message translates to:
  /// **'Get device coordinates. Location permission is required.'**
  String get weatherLocationAutomaticHint;

  /// No description provided for @weatherLocationManual.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get weatherLocationManual;

  /// No description provided for @weatherLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location access in Android settings and try again.'**
  String get weatherLocationPermissionDenied;

  /// No description provided for @weatherLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not obtain coordinates. Check Android location settings or enter a city manually.'**
  String get weatherLocationUnavailable;

  /// No description provided for @nightFilterSettings.
  ///
  /// In en, this message translates to:
  /// **'Filter settings'**
  String get nightFilterSettings;

  /// No description provided for @nightScheduleMenu.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get nightScheduleMenu;

  /// No description provided for @nightScheduleInactive.
  ///
  /// In en, this message translates to:
  /// **'Schedule is off'**
  String get nightScheduleInactive;

  /// No description provided for @nightLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get nightLocation;

  /// No description provided for @nightLocationAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Get automatically'**
  String get nightLocationAutomatic;

  /// No description provided for @nightLocationManual.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get nightLocationManual;

  /// No description provided for @nightLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable. Check permission and system location settings.'**
  String get nightLocationFailed;

  /// No description provided for @nightCityEnglish.
  ///
  /// In en, this message translates to:
  /// **'Enter the city name in English'**
  String get nightCityEnglish;

  /// No description provided for @nightOverlayBrief.
  ///
  /// In en, this message translates to:
  /// **'Allows the filter to appear over other apps.'**
  String get nightOverlayBrief;

  /// No description provided for @weatherGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Get location'**
  String get weatherGetLocation;

  /// No description provided for @backupLastCreated.
  ///
  /// In en, this message translates to:
  /// **'Last backup was created:'**
  String get backupLastCreated;

  /// No description provided for @backupManagement.
  ///
  /// In en, this message translates to:
  /// **'Manage backups'**
  String get backupManagement;

  /// No description provided for @backupCopyList.
  ///
  /// In en, this message translates to:
  /// **'Backup list'**
  String get backupCopyList;

  /// No description provided for @backupRefreshCopyList.
  ///
  /// In en, this message translates to:
  /// **'Refresh backup list'**
  String get backupRefreshCopyList;

  /// No description provided for @backupCreateNow.
  ///
  /// In en, this message translates to:
  /// **'Create a new backup now'**
  String get backupCreateNow;

  /// No description provided for @backupFolderPath.
  ///
  /// In en, this message translates to:
  /// **'Backup folder'**
  String get backupFolderPath;

  /// No description provided for @backupPrivateFolder.
  ///
  /// In en, this message translates to:
  /// **'Private application folder'**
  String get backupPrivateFolder;

  /// No description provided for @backupRestoreCopy.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup'**
  String get backupRestoreCopy;

  /// No description provided for @backupDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the selected backup?'**
  String get backupDeleteConfirm;

  /// No description provided for @blockedAppsGroup.
  ///
  /// In en, this message translates to:
  /// **'Blocked apps'**
  String get blockedAppsGroup;

  /// No description provided for @notificationSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettingsButton;

  /// No description provided for @hidePersistentNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Hide persistent notifications in the list and over other apps.'**
  String get hidePersistentNotificationsHint;

  /// No description provided for @nightTransitionTime.
  ///
  /// In en, this message translates to:
  /// **'Transition time'**
  String get nightTransitionTime;

  /// No description provided for @brightnessSolar.
  ///
  /// In en, this message translates to:
  /// **'Use night mode schedule'**
  String get brightnessSolar;

  /// No description provided for @brightnessAfterSunrise.
  ///
  /// In en, this message translates to:
  /// **'After sunrise'**
  String get brightnessAfterSunrise;

  /// No description provided for @brightnessAfterSunset.
  ///
  /// In en, this message translates to:
  /// **'After sunset'**
  String get brightnessAfterSunset;

  /// No description provided for @brightnessTransitionTime.
  ///
  /// In en, this message translates to:
  /// **'Brightness transition time'**
  String get brightnessTransitionTime;

  /// No description provided for @brightnessSolarUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Night mode schedule is unavailable. Check its times and location.'**
  String get brightnessSolarUnavailable;

  /// No description provided for @persistentNotificationCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'This persistent notification cannot be deleted. You can only block it.'**
  String get persistentNotificationCannotDelete;

  /// No description provided for @diagnosticsCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the diagnostic report. Try again.'**
  String get diagnosticsCreateFailed;

  /// No description provided for @backupListFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the backup list. Check access to the selected storage.'**
  String get backupListFailed;

  /// No description provided for @updateInstallerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the update installer. Try again and check that the Android installer is available.'**
  String get updateInstallerFailed;

  /// No description provided for @backupFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not select or save the backup folder. Choose an accessible folder and try again.'**
  String get backupFolderFailed;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download the update. Check your internet connection and available storage.'**
  String get updateDownloadFailed;

  /// No description provided for @backupDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the backup. Check delete permissions and try again.'**
  String get backupDeleteFailed;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates. Check your internet connection and try again.'**
  String get updateCheckFailed;

  /// No description provided for @backupCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the backup. Check storage access and available space.'**
  String get backupCreateFailed;

  /// No description provided for @wallpaperChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change the wallpaper. Check file access and try again.'**
  String get wallpaperChangeFailed;

  /// No description provided for @backupDownloadsFolder.
  ///
  /// In en, this message translates to:
  /// **'Downloads / CuteLauncher'**
  String get backupDownloadsFolder;

  /// No description provided for @backupChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder in file manager'**
  String get backupChooseFolder;

  /// No description provided for @backupFolderPickerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No folder picker is available on this TV. Choose Downloads / CuteLauncher or the internal app folder.'**
  String get backupFolderPickerUnavailable;

  /// No description provided for @driveConfigurationError.
  ///
  /// In en, this message translates to:
  /// **'Google Drive credentials are missing or invalid. Enter the Client ID and Client Secret of your TV OAuth client.'**
  String get driveConfigurationError;

  /// No description provided for @driveCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Google Drive sign-in timed out. Select Check and save account to get a new code.'**
  String get driveCodeExpired;

  /// No description provided for @brightnessAfterNightStart.
  ///
  /// In en, this message translates to:
  /// **'Nighttime'**
  String get brightnessAfterNightStart;

  /// No description provided for @brightnessAfterNightEnd.
  ///
  /// In en, this message translates to:
  /// **'Daytime'**
  String get brightnessAfterNightEnd;

  /// No description provided for @backupSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings to synchronize'**
  String get backupSyncSettings;

  /// No description provided for @backupSyncHomeGroup.
  ///
  /// In en, this message translates to:
  /// **'Home screen, sections and apps'**
  String get backupSyncHomeGroup;

  /// No description provided for @backupSyncAppearanceGroup.
  ///
  /// In en, this message translates to:
  /// **'Appearance, wallpapers and banners'**
  String get backupSyncAppearanceGroup;

  /// No description provided for @backupSyncDisplayGroup.
  ///
  /// In en, this message translates to:
  /// **'Night mode, brightness and screensaver'**
  String get backupSyncDisplayGroup;

  /// No description provided for @backupSyncControlsGroup.
  ///
  /// In en, this message translates to:
  /// **'Launcher and TV controls'**
  String get backupSyncControlsGroup;

  /// No description provided for @backupSyncGeneralGroup.
  ///
  /// In en, this message translates to:
  /// **'Language, updates and other settings'**
  String get backupSyncGeneralGroup;

  /// No description provided for @backupSyncGroupsHelp.
  ///
  /// In en, this message translates to:
  /// **'Disabled blocks stay local to this TV. The block selection is synchronized between devices.'**
  String get backupSyncGroupsHelp;

  /// No description provided for @backupSyncGroupsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the settings selection for synchronization. Try again.'**
  String get backupSyncGroupsFailed;

  /// No description provided for @tileLayoutMode.
  ///
  /// In en, this message translates to:
  /// **'Tile layout'**
  String get tileLayoutMode;

  /// No description provided for @tileLayoutAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic by tile size'**
  String get tileLayoutAuto;

  /// No description provided for @tileLayoutColumns.
  ///
  /// In en, this message translates to:
  /// **'Fixed column count'**
  String get tileLayoutColumns;

  /// No description provided for @tileLayoutRows.
  ///
  /// In en, this message translates to:
  /// **'Fixed row count'**
  String get tileLayoutRows;

  /// No description provided for @tileRowCount.
  ///
  /// In en, this message translates to:
  /// **'Row count'**
  String get tileRowCount;

  /// No description provided for @useGlobalTileSettings.
  ///
  /// In en, this message translates to:
  /// **'Use global settings'**
  String get useGlobalTileSettings;

  /// No description provided for @centerSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection position'**
  String get centerSelection;

  /// No description provided for @selectionBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get selectionBottom;

  /// No description provided for @selectionLower.
  ///
  /// In en, this message translates to:
  /// **'Lower middle'**
  String get selectionLower;

  /// No description provided for @selectionCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get selectionCenter;

  /// No description provided for @selectionUpper.
  ///
  /// In en, this message translates to:
  /// **'Upper middle'**
  String get selectionUpper;

  /// No description provided for @selectionTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get selectionTop;

  /// No description provided for @settingsStyle.
  ///
  /// In en, this message translates to:
  /// **'Settings style'**
  String get settingsStyle;

  /// No description provided for @tileFocusEnlargement.
  ///
  /// In en, this message translates to:
  /// **'Focus enlargement'**
  String get tileFocusEnlargement;

  /// No description provided for @tileFocusShadowStrength.
  ///
  /// In en, this message translates to:
  /// **'Shadow strength'**
  String get tileFocusShadowStrength;

  /// No description provided for @tileFocusLift.
  ///
  /// In en, this message translates to:
  /// **'Lift'**
  String get tileFocusLift;

  /// No description provided for @tileFocusLiftHeight.
  ///
  /// In en, this message translates to:
  /// **'Lift height'**
  String get tileFocusLiftHeight;

  /// No description provided for @tileFocusBorderColor.
  ///
  /// In en, this message translates to:
  /// **'Focus border color'**
  String get tileFocusBorderColor;

  /// No description provided for @tileFocusAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get tileFocusAccentColor;

  /// No description provided for @tileFocusDynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic colors'**
  String get tileFocusDynamicColor;

  /// No description provided for @tileSizeFromColumns.
  ///
  /// In en, this message translates to:
  /// **'Tile size is determined by the column count and section width.'**
  String get tileSizeFromColumns;

  /// No description provided for @resetSectionToGlobal.
  ///
  /// In en, this message translates to:
  /// **'Reset settings to shared values'**
  String get resetSectionToGlobal;

  /// No description provided for @resetSectionToGlobalHint.
  ///
  /// In en, this message translates to:
  /// **'Restore shared section titles, icons and background, and reset padding?'**
  String get resetSectionToGlobalHint;

  /// No description provided for @resetStyleSection.
  ///
  /// In en, this message translates to:
  /// **'Reset this section'**
  String get resetStyleSection;

  /// No description provided for @resetStyleSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults for this section only?'**
  String get resetStyleSectionHint;

  /// No description provided for @notificationStyle.
  ///
  /// In en, this message translates to:
  /// **'Notification style'**
  String get notificationStyle;

  /// No description provided for @styleBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get styleBackgroundColor;

  /// No description provided for @styleTransparency.
  ///
  /// In en, this message translates to:
  /// **'Background transparency'**
  String get styleTransparency;

  /// No description provided for @styleTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get styleTextSize;

  /// No description provided for @styleTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get styleTextColor;

  /// No description provided for @noticeSize.
  ///
  /// In en, this message translates to:
  /// **'Notification size'**
  String get noticeSize;

  /// No description provided for @noticeStylePreview.
  ///
  /// In en, this message translates to:
  /// **'Notification preview'**
  String get noticeStylePreview;

  /// No description provided for @backupSyncHomeOptions.
  ///
  /// In en, this message translates to:
  /// **'Behavior and general options'**
  String get backupSyncHomeOptions;

  /// No description provided for @backupSyncBackground.
  ///
  /// In en, this message translates to:
  /// **'Background and custom banners'**
  String get backupSyncBackground;

  /// No description provided for @backupSyncTiles.
  ///
  /// In en, this message translates to:
  /// **'Tile, menu and notification style'**
  String get backupSyncTiles;

  /// No description provided for @backupSyncWeatherSource.
  ///
  /// In en, this message translates to:
  /// **'Source and location'**
  String get backupSyncWeatherSource;

  /// No description provided for @backupSyncWeatherDisplay.
  ///
  /// In en, this message translates to:
  /// **'Weather display and temperature units'**
  String get backupSyncWeatherDisplay;

  /// No description provided for @backupSyncNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification display and filters'**
  String get backupSyncNotificationSettings;

  /// No description provided for @backupSyncOther.
  ///
  /// In en, this message translates to:
  /// **'Other settings'**
  String get backupSyncOther;

  /// No description provided for @tileFocusBorderStyle.
  ///
  /// In en, this message translates to:
  /// **'Border style'**
  String get tileFocusBorderStyle;

  /// No description provided for @tileFocusOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get tileFocusOutline;

  /// No description provided for @tileFocusGlow.
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get tileFocusGlow;

  /// No description provided for @tileFocusNoBorder.
  ///
  /// In en, this message translates to:
  /// **'No border'**
  String get tileFocusNoBorder;

  /// No description provided for @tileShowFocusShadow.
  ///
  /// In en, this message translates to:
  /// **'Show shadow'**
  String get tileShowFocusShadow;

  /// No description provided for @homeLayoutRow.
  ///
  /// In en, this message translates to:
  /// **'Horizontal row'**
  String get homeLayoutRow;

  /// No description provided for @homeLayoutRows.
  ///
  /// In en, this message translates to:
  /// **'Multiple rows'**
  String get homeLayoutRows;

  /// No description provided for @homeLayoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get homeLayoutGrid;

  /// No description provided for @homeCardCount.
  ///
  /// In en, this message translates to:
  /// **'Visible cards across'**
  String get homeCardCount;

  /// No description provided for @homeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get homeAuto;

  /// No description provided for @homeFree.
  ///
  /// In en, this message translates to:
  /// **'Free scrolling'**
  String get homeFree;

  /// No description provided for @homeAnchored.
  ///
  /// In en, this message translates to:
  /// **'Anchored section'**
  String get homeAnchored;

  /// No description provided for @homeScrollMode.
  ///
  /// In en, this message translates to:
  /// **'Section scrolling'**
  String get homeScrollMode;

  /// No description provided for @homeSectionPosition.
  ///
  /// In en, this message translates to:
  /// **'Active section position'**
  String get homeSectionPosition;

  /// No description provided for @homeLabelMode.
  ///
  /// In en, this message translates to:
  /// **'Application labels'**
  String get homeLabelMode;

  /// No description provided for @homeLabelNone.
  ///
  /// In en, this message translates to:
  /// **'No labels'**
  String get homeLabelNone;

  /// No description provided for @homeLabelSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected application only'**
  String get homeLabelSelected;

  /// No description provided for @homeLabelAll.
  ///
  /// In en, this message translates to:
  /// **'All applications'**
  String get homeLabelAll;

  /// No description provided for @homeInherited.
  ///
  /// In en, this message translates to:
  /// **'Inherited value'**
  String get homeInherited;

  /// No description provided for @homeOwnReset.
  ///
  /// In en, this message translates to:
  /// **'Custom value · use global'**
  String get homeOwnReset;

  /// No description provided for @homeParameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get homeParameters;

  /// No description provided for @homeSectionStyle.
  ///
  /// In en, this message translates to:
  /// **'Section appearance'**
  String get homeSectionStyle;

  /// No description provided for @homeSectionGap.
  ///
  /// In en, this message translates to:
  /// **'Space between sections'**
  String get homeSectionGap;

  /// No description provided for @homeSectionIcons.
  ///
  /// In en, this message translates to:
  /// **'Section icons'**
  String get homeSectionIcons;

  /// No description provided for @homeInactiveOpacity.
  ///
  /// In en, this message translates to:
  /// **'Inactive section opacity'**
  String get homeInactiveOpacity;

  /// No description provided for @homeResetSection.
  ///
  /// In en, this message translates to:
  /// **'Restore inherited section appearance'**
  String get homeResetSection;

  /// No description provided for @homeCalculatedSize.
  ///
  /// In en, this message translates to:
  /// **'Size is calculated from the card count'**
  String get homeCalculatedSize;

  /// No description provided for @homeGapLimited.
  ///
  /// In en, this message translates to:
  /// **'Spacing is limited to {gap} to keep the selected card count.'**
  String homeGapLimited(int gap);

  /// No description provided for @homeResetLayout.
  ///
  /// In en, this message translates to:
  /// **'Reset section layout'**
  String get homeResetLayout;

  /// No description provided for @homeVisibleRows.
  ///
  /// In en, this message translates to:
  /// **'Fully visible rows: {count}'**
  String homeVisibleRows(int count);

  /// No description provided for @homeStylePartial.
  ///
  /// In en, this message translates to:
  /// **'Applies only to sections that inherit this value and support it in their current layout.'**
  String get homeStylePartial;

  /// No description provided for @homeStyleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable in the current section settings. Check the layout and local overrides.'**
  String get homeStyleUnavailable;

  /// No description provided for @homeStyleNeedsRows.
  ///
  /// In en, this message translates to:
  /// **'Available for multiple rows or a grid.'**
  String get homeStyleNeedsRows;

  /// No description provided for @homeStyleNeedsLabels.
  ///
  /// In en, this message translates to:
  /// **'Enable labels to change their size and color.'**
  String get homeStyleNeedsLabels;

  /// No description provided for @homeStyleNeedsAllLabels.
  ///
  /// In en, this message translates to:
  /// **'Position applies only to labels on all cards. The selected title stays below the section.'**
  String get homeStyleNeedsAllLabels;

  /// No description provided for @homeStyleNeedsScale.
  ///
  /// In en, this message translates to:
  /// **'Select the enlargement focus effect.'**
  String get homeStyleNeedsScale;

  /// No description provided for @homeStyleNeedsLift.
  ///
  /// In en, this message translates to:
  /// **'Select the lift focus effect.'**
  String get homeStyleNeedsLift;

  /// No description provided for @homeStyleNeedsBorder.
  ///
  /// In en, this message translates to:
  /// **'Enable an outline or glow first.'**
  String get homeStyleNeedsBorder;

  /// No description provided for @homeStyleNeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable the section title to show its icon.'**
  String get homeStyleNeedsTitle;

  /// No description provided for @homeStyleEconomy.
  ///
  /// In en, this message translates to:
  /// **'Disabled by memory saving. The saved value is retained.'**
  String get homeStyleEconomy;

  /// No description provided for @homeStyleOpaque.
  ///
  /// In en, this message translates to:
  /// **'Reduce the tile background opacity to see blur.'**
  String get homeStyleOpaque;

  /// No description provided for @homeStyleOverridden.
  ///
  /// In en, this message translates to:
  /// **'Visible sections use their own values. Choose “Use global” in a section to apply this setting.'**
  String get homeStyleOverridden;

  /// No description provided for @homeStyleIconHint.
  ///
  /// In en, this message translates to:
  /// **'Icon size affects cards with an app icon. TV banners fill the card independently.'**
  String get homeStyleIconHint;

  /// No description provided for @homeStyleShadowHint.
  ///
  /// In en, this message translates to:
  /// **'Memory saving limits the shadow of inactive cards to 4. Focus shadow is configured separately.'**
  String get homeStyleShadowHint;

  /// No description provided for @homeStyleTransparent.
  ///
  /// In en, this message translates to:
  /// **'The background color is invisible at zero opacity. Increase the tile background opacity.'**
  String get homeStyleTransparent;

  /// No description provided for @homeStyleSingleColumn.
  ///
  /// In en, this message translates to:
  /// **'A single-column grid has no horizontal gaps.'**
  String get homeStyleSingleColumn;

  /// No description provided for @homeStyleAutoOnly.
  ///
  /// In en, this message translates to:
  /// **'Size changes only in sections with Auto card count that inherit the global size.'**
  String get homeStyleAutoOnly;

  /// No description provided for @sleepTimerThirtySeconds.
  ///
  /// In en, this message translates to:
  /// **'30 seconds (test)'**
  String get sleepTimerThirtySeconds;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String sleepTimerMinutes(int minutes);

  /// No description provided for @sleepTimerHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String sleepTimerHours(int hours);

  /// No description provided for @sleepTimerHourAndHalf.
  ///
  /// In en, this message translates to:
  /// **'1.5 hours'**
  String get sleepTimerHourAndHalf;

  /// No description provided for @sleepTimerAllowExact.
  ///
  /// In en, this message translates to:
  /// **'Allow precise timers'**
  String get sleepTimerAllowExact;

  /// No description provided for @sleepTimerExactRequired.
  ///
  /// In en, this message translates to:
  /// **'Allow precise timers in Android settings, then select a duration again.'**
  String get sleepTimerExactRequired;

  /// No description provided for @sleepTimerAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Enable CuteLauncher accessibility or connect local ADB in Settings → Other → ADB.'**
  String get sleepTimerAccessRequired;

  /// No description provided for @sleepTimerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not set or complete the sleep timer. Check accessibility and local ADB.'**
  String get sleepTimerFailed;

  /// No description provided for @nightIgnoreHdmiInputs.
  ///
  /// In en, this message translates to:
  /// **'Ignore HDMI inputs'**
  String get nightIgnoreHdmiInputs;

  /// No description provided for @nightIgnoreHdmiInputsHint.
  ///
  /// In en, this message translates to:
  /// **'Pause the night filter while watching HDMI. Usage access is required; input detection depends on the TV firmware.'**
  String get nightIgnoreHdmiInputsHint;

  /// No description provided for @inputsSettings.
  ///
  /// In en, this message translates to:
  /// **'Input settings'**
  String get inputsSettings;

  /// No description provided for @inputsUseCecNames.
  ///
  /// In en, this message translates to:
  /// **'Use device names from CEC'**
  String get inputsUseCecNames;

  /// No description provided for @inputsNamesHint.
  ///
  /// In en, this message translates to:
  /// **'Name priority: your name in CuteLauncher → CEC (if enabled) → name from Android settings → standard input name.'**
  String get inputsNamesHint;

  /// No description provided for @inputNameHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for an automatic name'**
  String get inputNameHint;

  /// No description provided for @inputsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save input settings'**
  String get inputsSaveFailed;

  /// No description provided for @inputIcon.
  ///
  /// In en, this message translates to:
  /// **'Input icon'**
  String get inputIcon;

  /// No description provided for @inputIconTv.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get inputIconTv;

  /// No description provided for @inputIconGame.
  ///
  /// In en, this message translates to:
  /// **'Game console'**
  String get inputIconGame;

  /// No description provided for @inputIconComputer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get inputIconComputer;

  /// No description provided for @inputIconReceiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get inputIconReceiver;

  /// No description provided for @inputIconDisc.
  ///
  /// In en, this message translates to:
  /// **'Disc player'**
  String get inputIconDisc;

  /// No description provided for @inputIconStream.
  ///
  /// In en, this message translates to:
  /// **'Streaming device'**
  String get inputIconStream;

  /// No description provided for @nightInputExclusions.
  ///
  /// In en, this message translates to:
  /// **'Input exclusions'**
  String get nightInputExclusions;

  /// No description provided for @nightSelectInputs.
  ///
  /// In en, this message translates to:
  /// **'Select inputs to ignore'**
  String get nightSelectInputs;

  /// No description provided for @nightNoInputsSelected.
  ///
  /// In en, this message translates to:
  /// **'No inputs selected. The filter will apply to every input.'**
  String get nightNoInputsSelected;

  /// No description provided for @nightPictureExclusions.
  ///
  /// In en, this message translates to:
  /// **'Picture mode exclusions'**
  String get nightPictureExclusions;

  /// No description provided for @nightPictureExclusionsHint.
  ///
  /// In en, this message translates to:
  /// **'Select modes that pause dimming, the warm overlay and the linked TCL filter. The schedule is preserved. Detection has been verified on TCL; usage access is not required.'**
  String get nightPictureExclusionsHint;

  /// No description provided for @nightPictureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The current picture mode is unavailable on this firmware. Your selection is saved; exclusions apply only when detection succeeds.'**
  String get nightPictureUnavailable;

  /// No description provided for @nightPictureCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current mode'**
  String get nightPictureCurrent;

  /// No description provided for @nightPictureRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh current mode'**
  String get nightPictureRefresh;

  /// No description provided for @nightPictureCode.
  ///
  /// In en, this message translates to:
  /// **'Mode code'**
  String get nightPictureCode;

  /// No description provided for @nightPictureStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get nightPictureStandard;

  /// No description provided for @nightPictureDynamic.
  ///
  /// In en, this message translates to:
  /// **'Dynamic'**
  String get nightPictureDynamic;

  /// No description provided for @nightPictureMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get nightPictureMovie;

  /// No description provided for @nightPictureSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get nightPictureSport;

  /// No description provided for @nightPictureIntelligent.
  ///
  /// In en, this message translates to:
  /// **'Intelligent'**
  String get nightPictureIntelligent;

  /// No description provided for @nightPictureBright.
  ///
  /// In en, this message translates to:
  /// **'Bright (Dolby Vision)'**
  String get nightPictureBright;

  /// No description provided for @nightPictureOrdinary.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get nightPictureOrdinary;

  /// No description provided for @systemApplications.
  ///
  /// In en, this message translates to:
  /// **'System apps'**
  String get systemApplications;

  /// No description provided for @removeFromCategory.
  ///
  /// In en, this message translates to:
  /// **'Remove from category'**
  String get removeFromCategory;

  /// No description provided for @noRemovableCategories.
  ///
  /// In en, this message translates to:
  /// **'This app has not been manually added to any sections. Automatic sections cannot be edited.'**
  String get noRemovableCategories;

  /// No description provided for @remoteButtonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote button remapper'**
  String get remoteButtonsTitle;

  /// No description provided for @remoteButtonsStart.
  ///
  /// In en, this message translates to:
  /// **'Check buttons (120 s)'**
  String get remoteButtonsStart;

  /// No description provided for @remoteButtonsStop.
  ///
  /// In en, this message translates to:
  /// **'Stop checking'**
  String get remoteButtonsStop;

  /// No description provided for @remoteButtonsHint.
  ///
  /// In en, this message translates to:
  /// **'Start the test, then press buttons in any menu or open app. Stop it here or wait 120 seconds. After the test, the report is saved at the path below, replacing the previous report. Copy it using ADB: adb pull <path>. Some system and manufacturer buttons may be unavailable to the service.'**
  String get remoteButtonsHint;

  /// No description provided for @remoteButtonsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events yet. If a button opens an app, return here to see the result.'**
  String get remoteButtonsEmpty;

  /// No description provided for @remoteButtonsService.
  ///
  /// In en, this message translates to:
  /// **'Service connected'**
  String get remoteButtonsService;

  /// No description provided for @remoteButtonsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get remoteButtonsRefresh;

  /// No description provided for @remoteBindings.
  ///
  /// In en, this message translates to:
  /// **'Button assignments'**
  String get remoteBindings;

  /// No description provided for @remoteMappingsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable remapping'**
  String get remoteMappingsEnabled;

  /// No description provided for @remoteMappingsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add assignment'**
  String get remoteMappingsAdd;

  /// No description provided for @remoteMappingKey.
  ///
  /// In en, this message translates to:
  /// **'Button'**
  String get remoteMappingKey;

  /// No description provided for @remoteMappingAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get remoteMappingAction;

  /// No description provided for @remoteMappingLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn a remote button'**
  String get remoteMappingLearn;

  /// No description provided for @remoteMappingLearnHint.
  ///
  /// In en, this message translates to:
  /// **'Press an extra remote button within 30 seconds. Navigation, Power, voice search and volume cannot be assigned.'**
  String get remoteMappingLearnHint;

  /// No description provided for @remoteMappingsHint.
  ///
  /// In en, this message translates to:
  /// **'Assignments require the accessibility service. They are paused in the editor and during diagnostics. Home, Back, arrows and OK keep their normal navigation.'**
  String get remoteMappingsHint;

  /// No description provided for @remoteMappingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset assignments'**
  String get remoteMappingsReset;

  /// No description provided for @remoteMappingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all assignments and turn remapping off?'**
  String get remoteMappingsResetConfirm;

  /// No description provided for @remoteMappingInvalid.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Check the button and target. Webhooks require HTTPS or HTTP on a local network.'**
  String get remoteMappingInvalid;

  /// No description provided for @remoteMappingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get remoteMappingBack;

  /// No description provided for @remoteMappingProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get remoteMappingProfile;

  /// No description provided for @remoteMappingChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get remoteMappingChannels;

  /// No description provided for @remoteMappingQuickSettings.
  ///
  /// In en, this message translates to:
  /// **'TCL quick settings'**
  String get remoteMappingQuickSettings;

  /// No description provided for @remoteMappingTrigger.
  ///
  /// In en, this message translates to:
  /// **'Press type'**
  String get remoteMappingTrigger;

  /// No description provided for @remoteMappingPress.
  ///
  /// In en, this message translates to:
  /// **'Short press'**
  String get remoteMappingPress;

  /// No description provided for @remoteMappingHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get remoteMappingHold;

  /// No description provided for @remoteMappingHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Hold for 650 ms: fires once, without the short action. If only hold is assigned, a short tap does nothing.'**
  String get remoteMappingHoldHint;

  /// No description provided for @remotePanel.
  ///
  /// In en, this message translates to:
  /// **'Floating panel'**
  String get remotePanel;

  /// No description provided for @remotePanelSettingsBackground.
  ///
  /// In en, this message translates to:
  /// **'Use settings background color'**
  String get remotePanelSettingsBackground;

  /// No description provided for @remotePanelPreview.
  ///
  /// In en, this message translates to:
  /// **'Open panel'**
  String get remotePanelPreview;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'More information'**
  String get settingsHelp;

  /// No description provided for @settingsHelpScroll.
  ///
  /// In en, this message translates to:
  /// **'▲ / ▼ — scroll text'**
  String get settingsHelpScroll;

  /// No description provided for @panelClockStyle.
  ///
  /// In en, this message translates to:
  /// **'Clock appearance'**
  String get panelClockStyle;

  /// No description provided for @clockPreset.
  ///
  /// In en, this message translates to:
  /// **'Clock design'**
  String get clockPreset;

  /// No description provided for @clockCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get clockCustom;

  /// No description provided for @clockWeight.
  ///
  /// In en, this message translates to:
  /// **'Font weight'**
  String get clockWeight;

  /// No description provided for @clockGlow.
  ///
  /// In en, this message translates to:
  /// **'Text glow'**
  String get clockGlow;

  /// No description provided for @clockAnimate.
  ///
  /// In en, this message translates to:
  /// **'Animate digits'**
  String get clockAnimate;

  /// No description provided for @clockBackground.
  ///
  /// In en, this message translates to:
  /// **'Clock background'**
  String get clockBackground;

  /// No description provided for @clockRadius.
  ///
  /// In en, this message translates to:
  /// **'Background corner radius'**
  String get clockRadius;

  /// No description provided for @dateCalendarEnabled.
  ///
  /// In en, this message translates to:
  /// **'Open calendar when pressing the date'**
  String get dateCalendarEnabled;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @dateSettings.
  ///
  /// In en, this message translates to:
  /// **'Date settings'**
  String get dateSettings;

  /// No description provided for @clockSharedBackground.
  ///
  /// In en, this message translates to:
  /// **'Use the same background as other objects'**
  String get clockSharedBackground;

  /// No description provided for @clockDefaultBackground.
  ///
  /// In en, this message translates to:
  /// **'Default background'**
  String get clockDefaultBackground;

  /// No description provided for @remotePanelInheritAppearance.
  ///
  /// In en, this message translates to:
  /// **'Use top panel appearance'**
  String get remotePanelInheritAppearance;

  /// No description provided for @remotePanelDisabledInLauncher.
  ///
  /// In en, this message translates to:
  /// **'Popup panel is disabled while CuteLauncher is on screen.'**
  String get remotePanelDisabledInLauncher;

  /// No description provided for @remoteAccessSettings.
  ///
  /// In en, this message translates to:
  /// **'Access settings'**
  String get remoteAccessSettings;

  /// No description provided for @remoteButtonsTest.
  ///
  /// In en, this message translates to:
  /// **'Button test'**
  String get remoteButtonsTest;

  /// No description provided for @remoteMappingConflict.
  ///
  /// In en, this message translates to:
  /// **'This button and press type are already assigned. Choose another button or press type.'**
  String get remoteMappingConflict;

  /// No description provided for @cleanerTitle.
  ///
  /// In en, this message translates to:
  /// **'TV cleanup manager'**
  String get cleanerTitle;

  /// No description provided for @cleanerRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh applications'**
  String get cleanerRefresh;

  /// No description provided for @cleanerSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Save original state'**
  String get cleanerSnapshot;

  /// No description provided for @cleanerRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore manager changes'**
  String get cleanerRestore;

  /// No description provided for @cleanerSnapshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Original state saved'**
  String get cleanerSnapshotSaved;

  /// No description provided for @cleanerExportSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Export original state'**
  String get cleanerExportSnapshot;

  /// No description provided for @cleanerSafe.
  ///
  /// In en, this message translates to:
  /// **'Disable verified applications'**
  String get cleanerSafe;

  /// No description provided for @cleanerNoSafe.
  ///
  /// In en, this message translates to:
  /// **'This firmware has no verified list that preserves all features.'**
  String get cleanerNoSafe;

  /// No description provided for @cleanerLocal.
  ///
  /// In en, this message translates to:
  /// **'Disable using a local list'**
  String get cleanerLocal;

  /// No description provided for @cleanerProject.
  ///
  /// In en, this message translates to:
  /// **'Project catalog lists'**
  String get cleanerProject;

  /// No description provided for @cleanerRemoteProject.
  ///
  /// In en, this message translates to:
  /// **'Refresh catalog from GitHub'**
  String get cleanerRemoteProject;

  /// No description provided for @cleanerExternal.
  ///
  /// In en, this message translates to:
  /// **'CleanYourTV examples'**
  String get cleanerExternal;

  /// No description provided for @cleanerDisabledExport.
  ///
  /// In en, this message translates to:
  /// **'Export disabled applications'**
  String get cleanerDisabledExport;

  /// No description provided for @cleanerInventoryExport.
  ///
  /// In en, this message translates to:
  /// **'Export application report'**
  String get cleanerInventoryExport;

  /// No description provided for @cleanerApps.
  ///
  /// In en, this message translates to:
  /// **'All applications'**
  String get cleanerApps;

  /// No description provided for @cleanerEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable application'**
  String get cleanerEnable;

  /// No description provided for @cleanerDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable application'**
  String get cleanerDisable;

  /// No description provided for @cleanerProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected from disabling'**
  String get cleanerProtected;

  /// No description provided for @cleanerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Purpose and dependencies are unconfirmed. Disabling risk is unknown.'**
  String get cleanerUnknown;

  /// No description provided for @cleanerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Apply change?'**
  String get cleanerConfirm;

  /// No description provided for @cleanerConfirmText.
  ///
  /// In en, this message translates to:
  /// **'The listed apps and related features will be affected. Original states are saved before changes. Recovery requires this launcher and ADB to remain available.'**
  String get cleanerConfirmText;

  /// No description provided for @cleanerObserved.
  ///
  /// In en, this message translates to:
  /// **'Observed list: disabling safety has not been verified.'**
  String get cleanerObserved;

  /// No description provided for @cleanerMismatch.
  ///
  /// In en, this message translates to:
  /// **'The list belongs to a different firmware and will not be applied.'**
  String get cleanerMismatch;

  /// No description provided for @cleanerMissing.
  ///
  /// In en, this message translates to:
  /// **'No available packages to change.'**
  String get cleanerMissing;

  /// No description provided for @cleanerFailure.
  ///
  /// In en, this message translates to:
  /// **'Action did not complete. Check ADB connectivity and the list format.'**
  String get cleanerFailure;

  /// No description provided for @cleanerPartial.
  ///
  /// In en, this message translates to:
  /// **'Changes completed partially. Recovery journal is saved; refresh the list and restore if needed.'**
  String get cleanerPartial;

  /// No description provided for @cleanerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cleanerDone;

  /// No description provided for @cleanerSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved or handed to the file manager'**
  String get cleanerSaved;

  /// No description provided for @cleanerGitUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Catalog unavailable. For private Git, use the bundled catalog or a file; no access tokens are stored in the APK.'**
  String get cleanerGitUnavailable;

  /// No description provided for @cleanerSystem.
  ///
  /// In en, this message translates to:
  /// **'System application'**
  String get cleanerSystem;

  /// No description provided for @cleanerUser.
  ///
  /// In en, this message translates to:
  /// **'User application'**
  String get cleanerUser;

  /// No description provided for @cleanerRisk.
  ///
  /// In en, this message translates to:
  /// **'Disabling risk'**
  String get cleanerRisk;

  /// No description provided for @cleanerHelp.
  ///
  /// In en, this message translates to:
  /// **'The manager uses the local ADB connection configured in TV control settings. It never uninstalls apps or clears their data. The snapshot and recovery journal are separate from ordinary backups. Recovery restores previous states only for packages changed by this manager. Automatic recovery is blocked after a firmware change.\n\nVerified lists match exact firmware. Observed and external lists do not establish safety. Protected components, HOME and active services cannot be disabled. Packages are previewed before applying; missing and already disabled packages are skipped.\n\nThe project catalog is bundled from Git. GitHub refresh requires a public catalog. External examples load only on request and never execute scripts. Export creates JSON containing disabled packages and firmware identity; add it manually to catalog/examples after review. Nothing is uploaded automatically.\n\nApp descriptions and risk remain visible. Unconfirmed purposes are marked explicitly and never included in verified lists.'**
  String get cleanerHelp;

  /// No description provided for @cleanerSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped: protected, missing or already in the requested state'**
  String get cleanerSkipped;

  /// No description provided for @cleanerUnidentified.
  ///
  /// In en, this message translates to:
  /// **'Application not identified.'**
  String get cleanerUnidentified;

  /// No description provided for @cleanerPending.
  ///
  /// In en, this message translates to:
  /// **'Changed by manager'**
  String get cleanerPending;

  /// No description provided for @cleanerNoSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Original state not saved yet'**
  String get cleanerNoSnapshot;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'pt',
    'ru',
    'tr',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
