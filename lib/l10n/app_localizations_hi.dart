// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

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
  String get adbWifiOwned =>
      'Not changed: a saved Wi-Fi network belongs to the setup wizard. Forget that network and reconnect through Android Settings, then check again. Disabling the wizard could delete the network.';

  @override
  String get adbWifiUnknown =>
      'Not changed: the owners of saved Wi-Fi networks could not be verified. Disabling the setup wizard is blocked to protect your connection. Check ADB and try again; some firmware does not provide this information.';

  @override
  String get backgroundSource => 'पृष्ठभूमि स्रोत';

  @override
  String get noAvailableCategories =>
      'इस ऐप को जोड़ने के लिए कोई अनुभाग उपलब्ध नहीं है।';

  @override
  String get redditWallpaperTheme => 'वॉलपेपर थीम';

  @override
  String get redditThemeAll => 'मिश्रित';

  @override
  String get redditThemeNature => 'प्रकृति';

  @override
  String get redditThemeSpace => 'अंतरिक्ष';

  @override
  String get redditThemeCity => 'शहर';

  @override
  String get redditThemeMinimal => 'अतिसूक्ष्मवाद';

  @override
  String get redditWallpaperResolution => 'न्यूनतम संकल्प';

  @override
  String get redditWallpaperHint =>
      'प्रत्येक सफल रिफ्रेश चयनित Reddit समुदाय से एक अलग लैंडस्केप छवि डाउनलोड करता है। रिज़ॉल्यूशन न्यूनतम मूल आकार है; छवियाँ उन्नत नहीं हैं. लॉन्चर खुला होने पर रिफ्रेश चलता है और जब आप वापस आते हैं तो फिर से शुरू हो जाता है। वयस्क सामग्री, वीडियो और गैलरी छोड़ दी जाती हैं। यदि Reddit पहुंच को अवरुद्ध करता है या कोई मेल खाती छवि नहीं मिलती है, तो पिछला वॉलपेपर बना रहता है।';

  @override
  String get dialogCommandDetails => 'ADB कमांड दिखाएँ';

  @override
  String get dialogAssign => 'नियुक्‍त करें';

  @override
  String get dialogApply => 'आवेदन करें';

  @override
  String get settingsValueNotSet => 'सेट नहीं';

  @override
  String get settingsMenuPosition => 'सेटिंग्स मेनू स्थिति';

  @override
  String get settingsMenuLeft => 'वाम';

  @override
  String get settingsMenuRight => 'ठीक है';

  @override
  String get actionCompleted => 'कार्रवाई पूरी हुई';

  @override
  String get showRepositoryQrCode => 'QR कोड दिखाएँ';

  @override
  String get resetSections => 'अनुभाग सेटिंग रीसेट करें';

  @override
  String get resetSectionsConfirmation =>
      'डिफ़ॉल्ट अनुभाग पुनर्स्थापित करें? कस्टम अनुभाग, स्पेसर और पसंदीदा सामग्री हटा दी जाएंगी।';

  @override
  String get cardFocusMode => 'घर वापसी पर ध्यान दें';

  @override
  String get cardFocusRemember => 'चयनित कार्ड रखें';

  @override
  String get cardFocusFirst => 'पहला कार्ड';

  @override
  String get cardFocusSettings => 'सेटिंग्स बटन';

  @override
  String get aboutFlauncher => 'CuteLauncher के बारे में';

  @override
  String get addCategory => 'श्रेणी जोड़ें';

  @override
  String get addSection => 'अनुभाग जोड़ें';

  @override
  String get alphabetical => 'वर्णानुक्रम';

  @override
  String get appCardHighlightAnimation => 'ऐप कार्ड हाइलाइट एनिमेशन';

  @override
  String get appInfo => 'ऐप जानकारी';

  @override
  String get appKeyClick => 'कुंजी दबाने पर क्लिक ध्वनि';

  @override
  String get applications => 'एप्लिकेशन';

  @override
  String get autoHideAppBar => 'स्टेटस बार को स्वचालित रूप से छिपाएं';

  @override
  String get backButtonAction => 'बैक बटन एक्शन';

  @override
  String get category => 'श्रेणी';

  @override
  String get categories => 'श्रेणियाँ';

  @override
  String get columnCount => 'कॉलम संख्या';

  @override
  String get date => 'दिनांक';

  @override
  String get dateAndTimeFormat => 'दिनांक और समय प्रारूप';

  @override
  String get delete => 'हटाएं';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'कुछ न करें';

  @override
  String get dialogOptionBackButtonActionShowScreensaver =>
      'स्क्रीनसेवर दिखाएं';

  @override
  String get dialogOptionBackButtonActionShowClock => 'घड़ी दिखाएं';

  @override
  String get dialogTextNoFileExplorer =>
      'कृपया चित्र चुनने के लिए फ़ाइल एक्सप्लोरर इंस्टॉल करें।';

  @override
  String get dialogTitleBackButtonAction => 'बैक बटन एक्शन चुनें';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (श्रेणी)';
  }

  @override
  String formattedDate(String dateString) {
    return 'फ़ॉर्मेट किया गया दिनांक: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'फ़ॉर्मेट किया गया समय: $timeString';
  }

  @override
  String get gradient => 'ग्रेडिएंट';

  @override
  String get favoriteApps => 'पसंदीदा ऐप्स';

  @override
  String get grid => 'ग्रिड';

  @override
  String get height => 'ऊंचाई';

  @override
  String get hide => 'छिपाएं';

  @override
  String get hiddenApplications => 'छिपे हुए ऐप्स';

  @override
  String get launcherSections => 'अनुभाग';

  @override
  String get layout => 'लेआउट';

  @override
  String get loading => 'लोड हो रहा है';

  @override
  String get manual => 'मैनुअल';

  @override
  String get modifySection => 'अनुभाग संशोधित करें';

  @override
  String get mustNotBeEmpty => 'खाली नहीं होना चाहिए';

  @override
  String get name => 'नाम';

  @override
  String get newSection => 'नया अनुभाग';

  @override
  String get noDateFormatSpecified => 'कोई दिनांक प्रारूप निर्दिष्ट नहीं';

  @override
  String get noTimeFormatSpecified => 'कोई समय प्रारूप निर्दिष्ट नहीं';

  @override
  String get nonTvApplications => 'गैर-टीवी ऐप्स';

  @override
  String get open => 'खोलें';

  @override
  String get orSelectFormatSpecifiers => 'या प्रारूप निर्दिष्टकर्ता चुनें';

  @override
  String get openImage => 'छवि खोलें';

  @override
  String get picture => 'चित्र';

  @override
  String removeFrom(String name) {
    return '$name से हटाएं';
  }

  @override
  String get renameCategory => 'श्रेणी का नाम बदलें';

  @override
  String get reorder => 'पुन: व्यवस्थित करें';

  @override
  String get row => 'पंक्ति';

  @override
  String get rowHeight => 'पंक्ति की ऊंचाई';

  @override
  String get save => 'सहेजें';

  @override
  String get spacer => 'स्पेसर';

  @override
  String get spacerMaxHeightRequirement =>
      '0 से अधिक और 500 से कम या बराबर होना चाहिए';

  @override
  String get statusBar => 'स्टेटस बार';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get show => 'दिखाएं';

  @override
  String get showCategoryTitles => 'श्रेणी शीर्षक दिखाएं';

  @override
  String get themes => 'थीम';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'होम स्क्रीन पर हाइलाइट आउटलाइन छिपाएं';

  @override
  String get appSelectorTransitionAnimation => 'ऐप सेलेक्टर ट्रांज़िशन एनिमेशन';

  @override
  String get sort => 'क्रमबद्ध करें';

  @override
  String get systemSettings => 'सिस्टम सेटिंग्स';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => 'यह श्रेणी खाली है।';

  @override
  String get time => 'समय';

  @override
  String get titleStatusBarSettingsPage =>
      'चुनें कि स्टेटस बार में क्या दिखाना है';

  @override
  String get tvApplications => 'टीवी ऐप्स';

  @override
  String get type => 'प्रकार';

  @override
  String get typeInTheDateFormat => 'दिनांक प्रारूप टाइप करें';

  @override
  String get typeInTheHourFormat => 'समय प्रारूप टाइप करें';

  @override
  String get uninstall => 'अनइंस्टॉल करें';

  @override
  String get wallpaper => 'वॉलपेपर';

  @override
  String get withEllipsisAddTo => 'इसमें जोड़ें...';

  @override
  String get timeBasedWallpaper => 'समय आधारित वॉलपेपर';

  @override
  String get pickDayWallpaper => 'दिन का वॉलपेपर चुनें';

  @override
  String get pickNightWallpaper => 'रात का वॉलपेपर चुनें';

  @override
  String get accessibility => 'पहुंच (एक्सेसिबिलिटी)';

  @override
  String get defaultLauncherIsDefault => 'CuteLauncher डिफ़ॉल्ट लॉन्चर है';

  @override
  String get defaultLauncherNotDefault =>
      'CuteLauncher डिफ़ॉल्ट लॉन्चर नहीं है';

  @override
  String get setAsDefaultLauncher => 'डिफ़ॉल्ट लॉन्चर के रूप में सेट करें';

  @override
  String get defaultLauncherDescription =>
      'डिफ़ॉल्ट लॉन्चर के रूप में सेट होने पर, होम बटन हमेशा CuteLauncher पर वापस आएगा। टीवी भी सीधे CuteLauncher में बूट होगा।';

  @override
  String get inputs => 'इनपुट';

  @override
  String get inputsUnavailableHint =>
      'यह डिवाइस कोई उपलब्ध इनपुट प्रदान नहीं करता है. स्विच अक्षम है और आइकन छिपा हुआ है. टीवी बॉक्स पर, यह विकल्प कनेक्टेड टीवी के HDMI इनपुट को नियंत्रित नहीं करता है।';

  @override
  String get inputSources => 'इनपुट स्रोत';

  @override
  String get backupAndRestore => 'बैकअप और पुनर्स्थापना';

  @override
  String get exportBackup => 'बैकअप निर्यात करें';

  @override
  String get importBackup => 'बैकअप आयात करें';

  @override
  String exportSuccess(String path) {
    return 'बैकअप सफलतापूर्वक $path में निर्यात किया गया';
  }

  @override
  String get importSuccess => 'बैकअप सफलतापूर्वक आयात किया गया';

  @override
  String get importConfirm =>
      'क्या आप वाकई बैकअप आयात करना चाहते हैं? यह आपकी वर्तमान सेटिंग्स और लेआउट को ओवरराइट कर देगा।';

  @override
  String get importError =>
      'बैकअप से सेटिंग्स पुनर्स्थापित नहीं की जा सकीं. फ़ाइल की जाँच करें और पुनः प्रयास करें।';

  @override
  String exportError(String error) {
    return 'बैकअप निर्यात करने में विफल: $error';
  }

  @override
  String get shareBackup => 'बैकअप साझा करें';

  @override
  String get shareBackupDescription =>
      'स्थानीय नेटवर्क पर अन्य डिवाइसों के साथ बैकअप साझा करें';

  @override
  String get stopSharing => 'साझा करना बंद करें';

  @override
  String get localNetworkSharingActive => 'स्थानीय नेटवर्क साझाकरण सक्रिय है!';

  @override
  String get localNetworkSharingInstructions =>
      'किसी अन्य डिवाइस को उसी Wi-Fi नेटवर्क से कनेक्ट करें और वेब ब्राउज़र में निम्न URL खोलें:';

  @override
  String get localNetworkSharingDetails =>
      'यहां आप अपने टीवी की सेटिंग्स/लेआउट डाउनलोड कर सकते हैं या बैकअप फ़ाइल को इस टीवी पर वापस अपलोड कर सकते हैं।';

  @override
  String failedToStartServer(String error) {
    return 'साझाकरण सर्वर प्रारंभ करने में विफल: $error';
  }

  @override
  String get notificationBell => 'सूचना घंटी';

  @override
  String get autoHideNotificationBell => 'सूचना घंटी को स्वचालित रूप से छिपाएं';

  @override
  String get continueWatching => 'देखना जारी रखें';

  @override
  String get showContinueWatchingOnHome => 'होम पर \'देखना जारी रखें\' दिखाएं';

  @override
  String get permissionDeniedContinueWatching =>
      '\'देखना जारी रखें\' दिखाने के लिए अनुमति आवश्यक है';

  @override
  String get interface => 'इंटरफ़ेस';

  @override
  String get system => 'सिस्टम';

  @override
  String get accentColor => 'एक्सेंट रंग';

  @override
  String get miscellaneous => 'विविध';

  @override
  String get brightnessScheduler => 'चमक शेड्यूलर';

  @override
  String get screensaverSettings => 'स्क्रीनसेवर सेटिंग्स';

  @override
  String get screensaverClockStyle => 'स्क्रीनसेवर घड़ी शैली';

  @override
  String get dataUsagePeriod => 'डेटा उपयोग अवधि';

  @override
  String get notificationAccess => 'सूचना पहुंच';

  @override
  String get granted => 'प्रदान किया गया';

  @override
  String get permissionRequired => 'अनुमति आवश्यक है';

  @override
  String get systemWidePopupAlert => 'सिस्टम-वाइड पॉपअप अलर्ट';

  @override
  String get overlayPermissionRequired => 'ओवरले अनुमति आवश्यक है';

  @override
  String get enabled => 'सक्षम';

  @override
  String get disabled => 'अक्षम';

  @override
  String get showAppNamesBelowIcons => 'आइकन के नीचे ऐप नाम दिखाएं';

  @override
  String get dataUsage => 'डेटा उपयोग';

  @override
  String get networkIndicator => 'नेटवर्क संकेतक';

  @override
  String get homeButtonFix => 'होम बटन फिक्स (Google TV)';

  @override
  String get startOnBoot => 'बूट पर शुरू करें (Google TV / Fire TV)';

  @override
  String get appLanguage => 'भाषा';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get spanish => 'स्पेनिश';

  @override
  String get ukrainian => 'यूक्रेनियन';

  @override
  String get chinese => 'चीनी';

  @override
  String get french => 'फ्रेंच';

  @override
  String get german => 'जर्मन';

  @override
  String get japanese => 'जापानी';

  @override
  String get portuguese => 'पुर्तगाली';

  @override
  String get russian => 'रूसी';

  @override
  String get italian => 'इतालवी';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get korean => 'कोरियाई';

  @override
  String get arabic => 'अरबी';

  @override
  String get turkish => 'तुर्की';

  @override
  String get hidePersistentNotifications => 'स्थायी सूचनाएं छिपाएं';

  @override
  String get hidePersistentNotificationsDesc =>
      'पृष्ठभूमि सेवा और सिस्टम सूचनाएं छिपाएं';

  @override
  String get blockedNotificationApps => 'अवरुद्ध ऐप्स';

  @override
  String get blockAppNotifications => 'सूचनाएं अवरुद्ध करें';

  @override
  String get unblockAppNotifications => 'सूचनाएं अनब्लॉक करें';

  @override
  String get noBlockedApps => 'कोई अवरुद्ध ऐप नहीं';

  @override
  String get persistentNotification => 'स्थायी';

  @override
  String get unblockAll => 'सभी अनब्लॉक करें';

  @override
  String get weather => 'मौसम';

  @override
  String get showWeatherWarnings => 'मौसम और बारिश की चेतावनी दिखाएं';

  @override
  String get temperatureUnit => 'तापमान इकाई';

  @override
  String get celsius => 'सेल्सियस (°C)';

  @override
  String get fahrenheit => 'फ़ारेनहाइट (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'मौसम और बारिश की चेतावनी देखने के लिए Breezy Weather इंस्टॉल करें और उसकी सेटिंग्स में \'स्थानीय डेटा साझाकरण\' सक्षम करें।';

  @override
  String get displayAndScreensaver => 'डिस्प्ले और स्क्रीनसेवर';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get continueWatchingDescription =>
      'होम स्क्रीन पर हाल ही में देखी गई फिल्में और टीवी शो दिखाएं';

  @override
  String get continueWatchingPermissionDesc =>
      'टीवी ऐप्स से देखने का इतिहास पढ़ने के लिए विशेष अनुमति की आवश्यकता है:';

  @override
  String get requestPermission => 'अनुमति का अनुरोध करें';

  @override
  String get dismiss => 'हटाएं';

  @override
  String get openApp => 'खोलें';

  @override
  String get notificationOptions => 'सूचना विकल्प';

  @override
  String get noBlockedAppsDesc =>
      'सभी ऐप्स को वर्तमान में सूचनाएं दिखाने की अनुमति है';

  @override
  String get notificationsAllowed => 'सूचनाएं चालू हैं';

  @override
  String get notificationsBlocked => 'सूचनाएं अवरुद्ध हैं';

  @override
  String get dpadDismissHint => 'बायां: हटाएं • ठीक है: विकल्प';

  @override
  String get watchNextDeleteError =>
      'आइटम को देखना जारी रखें से हटाया नहीं जा सका. पुनः प्रयास करें।';

  @override
  String get hideLauncherTile => 'ऐप ग्रिड में CuteLauncher छुपाएं';

  @override
  String get hideAndroidSettingsTile => 'ऐप टाइल्स में Android सेटिंग्स छुपाएं';

  @override
  String get animateTileReordering => 'चेतन टाइल को पुनः व्यवस्थित करना';

  @override
  String get imageInputRejected =>
      'यह छवि क्षतिग्रस्त है या बहुत बड़ी है (अधिकतम 8 MiB और 48 मेगापिक्सेल)। कोई अन्य छवि चुनें.';

  @override
  String get memoryTitle => 'स्मृति';

  @override
  String get memoryRefresh => 'स्मृति को मापें';

  @override
  String get memoryMeasuring => 'माप रहा हूँ...';

  @override
  String get memoryClear => 'छवि कैश साफ़ करें';

  @override
  String get memorySaver => 'मेमोरी सेविंग';

  @override
  String get memorySaverDescription =>
      'मेमोरी सेविंग मोड:\n\n• छवि कैश और पोस्टर प्रीलोड विंडो को कम करता है।\n• टाइल, पैनल और वॉलपेपर पृष्ठभूमि को धुंधला करने और रूपरेखा स्पंदन को अक्षम करता है।\n• अनफोकस्ड टाइल्स पर छाया को सीमित करता है।\n• ऐप के बैकग्राउंड में जाने पर कैश साफ़ हो जाता है।\n\nमेमोरी सेविंग सक्षम होने पर ये प्रभाव सेटिंग्स में अनुपलब्ध हैं। मोड अक्षम होने पर उनके सहेजे गए मान वापस आ जाते हैं। छवियां अधिक बार पुनः लोड हो सकती हैं.';

  @override
  String get memoryPss => 'प्रक्रिया शेयर (PSS)';

  @override
  String get memoryRss => 'रेजिडेंट प्रोसेस मेमोरी (RSS)';

  @override
  String get memoryEncodedCache => 'कैश्ड छवि फ़ाइलें';

  @override
  String get memoryDecodedCache => 'कैश्ड डिकोड की गई छवियाँ';

  @override
  String get memoryUnavailable => 'अनुपलब्ध';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => 'पर मापा गया';

  @override
  String get memoryExplanation =>
      'PSS और RSS ओवरलैप: उन्हें एक साथ न जोड़ें। कैश आकार ऐप मेमोरी का हिस्सा हैं और सक्रिय छवियों द्वारा रखी गई सभी मेमोरी का वर्णन नहीं करते हैं। कैश साफ़ करने से आपकी सेटिंग्स और फ़ाइलें सुरक्षित रहती हैं; आवश्यकता पड़ने पर छवियाँ पुनः लोड होती हैं। Android बाद में मेमोरी लौटा सकता है। यहां RSS कर्नेल से आता है और PSS Android से आता है; वे ग्राफ़िक्स मेमोरी का अलग-अलग हिसाब लगा सकते हैं।';

  @override
  String get memoryRecommendations =>
      'कम मेमोरी के लिए, सेविंग सक्षम करें, कम दिखाएं, वॉचिंग कार्ड जारी रखें और छोटे वॉलपेपर या ग्रेडिएंट का उपयोग करें।';

  @override
  String get memoryMeasurementFailed =>
      'प्रक्रिया माप उपलब्ध नहीं है. कैश जानकारी अभी भी दिखाई जाती है.';

  @override
  String get addToCategory => 'श्रेणी में जोड़ें';

  @override
  String get addToFavorites => 'पसंदीदा में जोड़ें';

  @override
  String get removeFromFavorites => 'पसंदीदा से हटाएँ';

  @override
  String get setCustomBanner => 'कस्टम बैनर सेट करें';

  @override
  String get clearCustomBanner => 'कस्टम बैनर साफ़ करें';

  @override
  String get bannerSetFailed =>
      'बैनर सेट नहीं किया जा सका. छवि तक पहुंच की जांच करें और फ़ाइल को फिर से चुनें।';

  @override
  String get bannerClearFailed =>
      'कस्टम बैनर नहीं हटाया जा सका. पुनः प्रयास करें।';

  @override
  String get grantUsagePermission => 'उपयोग की अनुमति प्रदान करें';

  @override
  String get removeFromContinueWatching => 'देखना जारी रखें से हटाएँ';

  @override
  String hideAllFromApp(String appName) {
    return '$appName से सभी छिपाएँ';
  }

  @override
  String get playResume => 'चलाएँ/फिर से शुरू करें';

  @override
  String openNamedApp(String appName) {
    return '$appName खोलें';
  }

  @override
  String get selectedAccent => 'चयनित एक्सेंट';

  @override
  String get homeButtonFixHint =>
      'यदि आप Google TV का उपयोग कर रहे हैं, तो होम बटन को इस लॉन्चर को खोलने के लिए एक्सेसिबिलिटी सेटिंग्स के तहत \"होम बटन फिक्स\" सक्षम करें।';

  @override
  String get accessibilityPermission => 'अभिगम्यता अनुमति';

  @override
  String get shareFailed => 'साझा करना विफल';

  @override
  String shareBackupError(String error) {
    return 'बैकअप साझा करने में विफल: $error';
  }

  @override
  String get exportComplete => 'निर्यात सफलता';

  @override
  String get exportFailed =>
      'बैकअप सहेजा नहीं जा सका. फ़ोल्डर पहुंच और उपलब्ध संग्रहण की जांच करें.';

  @override
  String backupLoadError(String error) {
    return 'बैकअप लोड करने में त्रुटि: $error';
  }

  @override
  String get noBackupFiles => 'कोई बैकअप फ़ाइल नहीं मिली.';

  @override
  String get importComplete => 'आयात सफलता';

  @override
  String get importFailed => 'आयात विफल';

  @override
  String get importAction => 'आयात करें';

  @override
  String get continueWatchingApps => 'ऐप्स देखना जारी रखें';

  @override
  String get blockedContinueWatching => 'देखना जारी रखने से अवरोधित किया गया';

  @override
  String get allAppsCanContinueWatching =>
      'सभी समर्थित ऐप्स कंटिन्यू वॉचिंग में आइटम दिखा सकते हैं।';

  @override
  String get unblockApp => 'अनब्लॉक करें';

  @override
  String get unblockAllApps => 'सभी ऐप्स अनब्लॉक करें';

  @override
  String get appsWithContinueWatching => 'देखना जारी रखें वाले ऐप्स';

  @override
  String get watchNextAppsHint =>
      'ऐप्स वर्तमान में आपके होम स्क्रीन पर वॉच नेक्स्ट आइटम उपलब्ध करा रहे हैं';

  @override
  String get noWatchNextApps =>
      'वर्तमान में कोई भी ऐप कंटिन्यू वॉचिंग आइटम उपलब्ध नहीं करा रहा है।\nजब समर्थित ऐप्स (जैसे स्मार्टट्यूब या स्ट्रीमिंग सेवाएं) आइटम जोड़ते हैं, तो वे यहां दिखाई देंगे।';

  @override
  String get allInstalledApps => 'सभी इंस्टॉल किए गए ऐप्स';

  @override
  String get blockWatchNextHint =>
      'किसी भी ऐप को देखना जारी रखें में आइटम जोड़ने से रोकने के लिए टॉगल बंद करें';

  @override
  String get cardSize => 'कार्ड का आकार';

  @override
  String get maximumItems => 'अधिकतम आइटम';

  @override
  String get playbackProgressBar => 'प्लेबैक प्रगति बार';

  @override
  String get playbackPercentage => 'प्लेबैक प्रतिशत';

  @override
  String get episodeVideoDetails => 'एपिसोड और वीडियो विवरण';

  @override
  String get restoreHiddenPrograms => 'छिपे हुए प्रोग्राम पुनर्स्थापित करें';

  @override
  String get allHiddenProgramsRestored => 'सभी छिपे हुए प्रोग्राम बहाल हो गए';

  @override
  String get watchNextAccessAdb => 'अगला एक्सेस देखें (ADB आवश्यक)';

  @override
  String get supportLtvLauncher => 'समर्थन LTvLauncher';

  @override
  String get scanToDonate => 'दान करने के लिए अपने फ़ोन कैमरे से स्कैन करें:';

  @override
  String get openInBrowser => 'ब्राउज़र में खोलें';

  @override
  String get close => 'बंद करें';

  @override
  String get launcherAuthor => 'CuteLauncher Kirill Shchetinnikov द्वारा';

  @override
  String get launcherCredits =>
      'LeanBitLab द्वारा LTvLauncher और Étienne Fesser द्वारा FLauncher पर आधारित Android TV लॉन्चर। GNU GPLv3 के अंतर्गत लाइसेंस प्राप्त।';

  @override
  String get projectCredits => 'प्रोजेक्ट एवं क्रेडिट';

  @override
  String get launcherRepository => 'CuteLauncher रिपॉजिटरी';

  @override
  String get originalProject => 'मूल परियोजना: LTvLauncher';

  @override
  String get noInputsDetected => 'कोई इनपुट नहीं मिला';

  @override
  String get reorderSectionsHint =>
      '◄ / ► के साथ चयन करें और फिर पुनः व्यवस्थित करने के लिए ▲ / ▼ का उपयोग करें। किसी अनुभाग को छिपाने या दिखाने के लिए सूची सीमा को पार करें।';

  @override
  String get customName => 'कस्टम नाम';

  @override
  String get mostUsed => 'प्रक्षेपण आवृत्ति';

  @override
  String get lastUsed => 'अंतिम बार उपयोग किया गया';

  @override
  String get clearAll => 'सभी साफ़ करें';

  @override
  String get allCaughtUp => 'सब पकड़ लिया गया!';

  @override
  String get notificationAccessAdb => 'अधिसूचना पहुंच (ADB आवश्यक)';

  @override
  String get openAppInfo => 'ऐप की जानकारी खोलें';

  @override
  String get overlayPermission => 'ओवरले अनुमति';

  @override
  String get clockMinimal => 'न्यूनतम';

  @override
  String get clockMinimalDescription => 'पतला, सुंदर फ़ॉन्ट (डिफ़ॉल्ट)';

  @override
  String get clockBold => 'साहसी';

  @override
  String get clockBoldDescription => 'मोटा, अत्यधिक दृश्यमान फ़ॉन्ट';

  @override
  String get clockRetro => 'रेट्रो';

  @override
  String get clockRetroDescription => 'मोनोस्पेस्ड, रेट्रो टर्मिनल शैली';

  @override
  String get clockElegant => 'सुरुचिपूर्ण';

  @override
  String get clockElegantDescription => 'क्लासिक सेरिफ़ टाइपफेस';

  @override
  String get clockNeon => 'नियॉन';

  @override
  String get clockNeonDescription => 'अति पतली, चमकदार शैली';

  @override
  String get clockPixel => 'पिक्सेल';

  @override
  String get clockPixelDescription => 'बोल्ड मोनोस्पेस्ड, आर्केड फील';

  @override
  String get clockDigital => 'डिजिटल';

  @override
  String get clockDigitalDescription => 'स्वच्छ मोनोस्पेस्ड डिस्प्ले';

  @override
  String get themeDefault => 'डिफ़ॉल्ट';

  @override
  String get themePremium => 'प्रीमियम';

  @override
  String get themeClassic => 'क्लासिक';

  @override
  String get themeCapsule => 'कैप्सूल';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get actionCancelled => 'कार्रवाई रद्द कर दी गई';

  @override
  String get ok => 'ठीक है';

  @override
  String get accessibilityGuide =>
      'टीवी सेटिंग्स को मैन्युअल रूप से खोलें, फिर एक्सेसिबिलिटी → CuteLauncher होम बटन फिक्स, और सेवा को सक्षम करें। इस मेनू का स्थान और नाम आपके टीवी निर्माता पर निर्भर करता है।';

  @override
  String get notificationPermissionGuide =>
      'इस टीवी पर नोटिफिकेशन एक्सेस सेटिंग्स नहीं खोली जा सकीं। ऐप इन्फो में आउटगोइंग नोटिफिकेशन की अनुमति देने से अन्य ऐप्स से नोटिफिकेशन तक पहुंच नहीं मिलती है।\n\nअपने टीवी को ADB के माध्यम से कनेक्ट करें और चलाएं:';

  @override
  String get overlayPermissionGuide =>
      'ओवरले अनुमति सेटिंग्स स्वचालित रूप से नहीं खोली जा सकीं.\n\nअन्य ऐप्स पर पॉपअप सक्षम करने के लिए, अपने टीवी को ADB के माध्यम से कनेक्ट करें और चलाएं:';

  @override
  String get watchNextPermissionGuide =>
      'अन्य ऐप्स से कंटिन्यू वॉचिंग कार्ड पढ़ने के लिए, Android TV को READ_WRITE_WATCH_NEXT_PROGRAMS की आवश्यकता होती है।\n\nअपने टीवी को ADB के माध्यम से कनेक्ट करें और चलाएं:';

  @override
  String get watchNextAccess => 'देखने की पहुंच जारी रखें';

  @override
  String itemsCount(int count) {
    return '$count आइटम';
  }

  @override
  String displayUpToItems(int count) {
    return '$count तक नवीनतम आइटम प्रदर्शित करें';
  }

  @override
  String get unlimitedItems => 'असीमित';

  @override
  String get allAvailableItems => 'सभी उपलब्ध आइटम प्रदर्शित करें';

  @override
  String get defaultOption => 'डिफ़ॉल्ट';

  @override
  String get manage => 'प्रबंधित करें';

  @override
  String blockedCount(int count) {
    return '$count अवरुद्ध';
  }

  @override
  String hiddenCount(int count) {
    return '$count छिपा हुआ';
  }

  @override
  String blockedWatchNextCount(int count) {
    return 'देखना जारी रखने से अवरोधित ($count)';
  }

  @override
  String get sizeExtraSmall => 'अतिरिक्त छोटा';

  @override
  String get sizeVerySmall => 'बहुत छोटा';

  @override
  String get sizeSmall => 'छोटा';

  @override
  String get sizeCompact => 'सघन';

  @override
  String get sizeMediumSmall => 'मध्यम छोटा';

  @override
  String get sizeMedium => 'मध्यम';

  @override
  String get sizeStandardDefault => 'मानक (डिफ़ॉल्ट)';

  @override
  String get sizeMediumLarge => 'मध्यम बड़ा';

  @override
  String get sizeLarge => 'बड़ा';

  @override
  String get sizeVeryLarge => 'बहुत बड़ा';

  @override
  String get sizeExtraLarge => 'अतिरिक्त बड़ा';

  @override
  String get sizeHuge => 'विशाल';

  @override
  String get tvApps => 'टीवी ऐप्स';

  @override
  String get nonTvApps => 'गैर-टीवी ऐप्स';

  @override
  String get moviesShows => 'फ़िल्में और शो';

  @override
  String get music => 'संगीत';

  @override
  String get games => 'खेल';

  @override
  String get entertainment => 'मनोरंजन';

  @override
  String get liveTv => 'लाइव टीवी';

  @override
  String get sports => 'खेल';

  @override
  String get news => 'समाचार';

  @override
  String get tools => 'उपकरण';

  @override
  String get favorites => 'पसंदीदा';

  @override
  String get customSectionName => 'कस्टम...';

  @override
  String get selectSectionName => 'एक नाम चुनें';

  @override
  String get weeklyUsage => 'साप्ताहिक:';

  @override
  String get monthlyUsage => 'मासिक:';

  @override
  String get dailyUsage => 'दैनिक:';

  @override
  String get appError => 'कुछ ग़लत हो गया';

  @override
  String get weatherRain => 'वर्षा';

  @override
  String get weatherSnow => 'हिमपात';

  @override
  String get weatherStorm => 'तूफ़ान';

  @override
  String get weatherToday => 'आज';

  @override
  String get weatherTomorrow => 'कल';

  @override
  String weatherOnDay(String day) {
    return '$day पर';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'CuteLauncher बैकअप';

  @override
  String get noApplicationsFound => 'कोई एप्लिकेशन नहीं मिला';

  @override
  String get invalidDateFormat => 'अमान्य प्रारूप';

  @override
  String get selectDateFormats => 'नीचे प्रारूप चुनें';

  @override
  String activeItemsCount(int count) {
    return '$count सक्रिय आइटम';
  }

  @override
  String get colorPurple => 'बैंगनी';

  @override
  String get colorTeal => 'चैती';

  @override
  String get colorBlue => 'नीला';

  @override
  String get colorOrange => 'नारंगी';

  @override
  String get colorPink => 'गुलाबी';

  @override
  String get colorGreen => 'हरा';

  @override
  String get colorWhite => 'सफ़ेद';

  @override
  String get colorYellow => 'पीला';

  @override
  String get colorRed => 'लाल';

  @override
  String get colorCyan => 'सियान';

  @override
  String get colorIndigo => 'इंडिगो';

  @override
  String get colorLime => 'नीबू';

  @override
  String get colorAmber => 'अंबर';

  @override
  String get colorRose => 'गुलाब';

  @override
  String get colorIceBlue => 'बर्फीला नीला';

  @override
  String get memoryFeatures => 'फ़ीचर द्वारा मेमोरी (कैश)';

  @override
  String get memoryAppIcons => 'ऐप आइकन';

  @override
  String get memoryAppBanners => 'ऐप बैनर';

  @override
  String get memoryWatchNextPosters => 'पोस्टर देखना जारी रखें';

  @override
  String get memoryOtherCaches => 'अन्य एन्कोडेड छवि कैश';

  @override
  String get memoryFeaturesExplanation =>
      'ये बरकरार छवि बाइट्स हैं, जो पहले से ही एन्कोडेड कैश कुल में शामिल हैं। शून्य का मतलब उस कैश में कोई बरकरार बाइट्स नहीं है, ऐसा नहीं है कि सुविधा कोई मेमोरी का उपयोग नहीं करती है। वॉलपेपर और प्रदर्शित छवियां ऊपर डिकोड किए गए कैश को साझा करती हैं; सक्रिय छवियाँ इसके बाहर हो सकती हैं। मौसम, सूचनाएं, डार्ट ऑब्जेक्ट और इंजन को यहां फीचर द्वारा विभाजित नहीं किया जा सकता है। साझा इंटरफ़ेस ग्राफ़िक्स ऊपर Android द्वारा रिपोर्ट किए गए हैं और पहले से ही PSS में शामिल हैं। उनकी स्मृति कुल प्रक्रिया का हिस्सा है। इन अतिव्यापी मानों को न जोड़ें.';

  @override
  String get memoryGraphics => 'इंटरफ़ेस ग्राफ़िक्स (PSS में शामिल)';

  @override
  String get categoryVisible => 'श्रेणी दिखाएँ';

  @override
  String get hiddenCategories => 'छुपी हुई श्रेणियां';

  @override
  String get visibleCategories => 'दर्शनीय श्रेणियां';

  @override
  String get backupSavedToSelectedLocation => 'बैकअप चयनित स्थान पर सहेजा गया';

  @override
  String get tileHorizontalGap => 'क्षैतिज दूरी';

  @override
  String get tileVerticalGap => 'लंबवत रिक्ति';

  @override
  String get tileOpacity => 'पृष्ठभूमि अस्पष्टता';

  @override
  String get tileShadow => 'छाया';

  @override
  String get tileCornerRadius => 'कोने की गोलाई';

  @override
  String get tileIconScale => 'चिह्न का आकार';

  @override
  String get tileBackgroundColor => 'टाइल पृष्ठभूमि';

  @override
  String get tileLabelSize => 'लेबल का आकार';

  @override
  String get resetAppearance => 'उपस्थिति रीसेट करें';

  @override
  String get tileAppearance => 'टाइल उपस्थिति';

  @override
  String get tileLabelColor => 'लेबल का रंग';

  @override
  String get tilePreviewName => 'नमूना आवेदन';

  @override
  String get tileProportions => 'टाइल अनुपात';

  @override
  String get tileLarge => 'बड़ा';

  @override
  String get tileLabelBelow => 'टाइल के नीचे';

  @override
  String get tileLabelInside => 'टाइल के अंदर';

  @override
  String get tileFocusScale => 'बड़ा करना';

  @override
  String get tileMedium => 'मध्यम';

  @override
  String get tileFocusBorder => 'कोई हलचल नहीं';

  @override
  String get tileSize => 'टाइल का आकार';

  @override
  String get tileCompact => 'सघन';

  @override
  String get tileLabelPosition => 'लेबल स्थिति';

  @override
  String get tileFocusEffect => 'फोकस प्रभाव';

  @override
  String get tileFocusStrength => 'तीव्रता को हाइलाइट करें';

  @override
  String get panelIndependent => 'कस्टम सेटिंग्स';

  @override
  String get panelAppearance => 'शीर्ष पैनल शैली';

  @override
  String get panelBackground => 'पैनल पृष्ठभूमि';

  @override
  String get blurPerformanceHint =>
      'धुंधलापन चिकनाई को कम कर सकता है। मेमोरी सेविंग चालू होने पर यह अक्षम है।';

  @override
  String get panelOpacity => 'पैनल अपारदर्शिता';

  @override
  String get tileBlur => 'टाइल्स के पीछे धुंधलापन';

  @override
  String get panelBlur => 'शीर्ष पैनल के पीछे धुंधला करें';

  @override
  String get panelShared => 'पैनलों की तरह';

  @override
  String get weatherMinutes => 'मि';

  @override
  String get weatherOpenMeteoCredit =>
      'मौसम: Open-Meteo (open-meteo.com), CC BY 4.0। गैर-व्यावसायिक उपयोग के लिए निःशुल्क API।';

  @override
  String get weatherRateLimit => 'अनुरोध सीमा पूरी हो गई. बाद में प्रयास करें।';

  @override
  String get weatherYandexCredit =>
      'मौसम: यांडेक्स मौसम (yandex.ru/pogoda)। एक्सेस आपके API प्लान पर निर्भर करता है।';

  @override
  String get yandexWeather => 'यांडेक्स मौसम (बाकी)';

  @override
  String get weatherAuthorizationError =>
      'मौसम प्रदाता ने अनुरोध अस्वीकार कर दिया। API कुंजी की जाँच करें और चयनित सेवा तक पहुँच प्राप्त करें।';

  @override
  String get weatherYandexHint =>
      'REST पूर्वानुमान पहुंच के साथ एक कुंजी की आवश्यकता है। किसी अन्य यांडेक्स योजना की कुंजी काम नहीं कर सकती है।';

  @override
  String get weatherSource => 'मौसम स्रोत';

  @override
  String get weatherInterval => 'अद्यतन अंतराल';

  @override
  String get weatherLongitude => 'देशांतर (-180 से 180)';

  @override
  String get weatherKeyRequired => 'Yandex API कुंजी जोड़ें।';

  @override
  String get weatherLocationName => 'शहर का नाम (वैकल्पिक)';

  @override
  String get weatherLocation => 'स्थान';

  @override
  String get weatherApiKey => 'यांडेक्स API कुंजी';

  @override
  String get weatherInvalidResponse => 'मौसम स्रोत ने अमान्य डेटा लौटाया।';

  @override
  String get weatherUnavailable =>
      'मौसम अनुपलब्ध है. यदि उपलब्ध हो तो पहले प्राप्त डेटा को बरकरार रखा जाता है। पुनर्प्रयास हर 5 मिनट में एक बार तक सीमित है।';

  @override
  String get weatherStale => 'पिछला मौसम';

  @override
  String get weatherLatitude => 'अक्षांश (-90 से 90)';

  @override
  String get weatherCoordinatesError =>
      'किसी शहर को मैन्युअल रूप से दर्ज करें या स्वचालित रूप से निर्देशांक प्राप्त करें।';

  @override
  String get weatherRefresh => 'अपडेट के लिए जांचें';

  @override
  String get weatherKeyPrivate =>
      'केवल इस डिवाइस पर संग्रहीत, बैकअप से बाहर रखा गया। खाली इनपुट कुंजी को हटा देता है.';

  @override
  String get weatherUpdated => 'अद्यतन किया गया';

  @override
  String get onlineWallpaperError =>
      'इस छवि को लोड करने में असमर्थ. पिछला वॉलपेपर बरकरार रखा गया है. डाउनलोड का पुनः प्रयास करने के लिए \"अपडेट की जांच करें\" चुनें।';

  @override
  String get onlineWallpaperHint =>
      'आखिरी चित्र ऑफ़लाइन उपयोग के लिए सुरक्षित रहता है (अधिकतम 8 MiB)।';

  @override
  String get onlineWallpaperHours => 'ज';

  @override
  String get onlineWallpaperInterval => 'अंतराल डाउनलोड करें';

  @override
  String get onlineWallpaper => 'ऑनलाइन वॉलपेपर';

  @override
  String get onlineWallpaperUrlError =>
      'लॉगिन विवरण के बिना सीधी HTTPS छवि URL दर्ज करें।';

  @override
  String get onlineWallpaperEnabled => 'ऑनलाइन वॉलपेपर का प्रयोग करें';

  @override
  String get onlineWallpaperSource => 'छवि स्रोत';

  @override
  String get bingWallpaper => 'दिन की Bing छवि';

  @override
  String get onlineWallpaperUrlSource => 'डायरेक्ट HTTPS URL';

  @override
  String get updatePlayOnly =>
      'यह इंस्टॉलेशन Google Play के माध्यम से अपडेट प्राप्त करता है।';

  @override
  String get updateCheck => 'अभी जांचें';

  @override
  String get updateInstalled => 'स्थापित';

  @override
  String get updateDownloadInstall => 'डाउनलोड करें और इंस्टॉल करें';

  @override
  String get updateNoRelease => 'कोई नई संगत रिलीज़ उपलब्ध नहीं है।';

  @override
  String get updateIncompatible =>
      'APK इस एप्लिकेशन, प्रमाणपत्र या नए संस्करण से मेल नहीं खाता है। स्थापना अवरुद्ध थी.';

  @override
  String get updateError =>
      'इंस्टॉलर को जांचने, डाउनलोड करने या खोलने में असमर्थ. बाद में पुन: प्रयास।';

  @override
  String get updateAvailable => 'अपडेट उपलब्ध है';

  @override
  String get appUpdates => 'एप्लिकेशन अपडेट';

  @override
  String get updatePermission =>
      'Android सेटिंग्स में इस एप्लिकेशन से इंस्टॉलेशन की अनुमति दें, यहां वापस आएं और फिर से इंस्टॉल दबाएं।';

  @override
  String get updateInstall => 'डाउनलोड किया गया अपडेट इंस्टॉल करें';

  @override
  String get updateHint =>
      'स्रोत: GitHub / KirillShchetinnikov/CuteLauncher-रिलीज़। लॉन्चर खुला होने पर स्वचालित जाँच चलती है। जब आप इसे चुनते हैं तो डाउनलोड प्रारंभ हो जाता है; Android आपसे इंस्टॉलेशन की पुष्टि करने के लिए कहता है। आपका डेटा रखा जाता है.';

  @override
  String get updateAutomatic => 'दिन में एक बार स्वचालित रूप से जांचें';

  @override
  String get allApplications => 'सभी अनुप्रयोग';

  @override
  String get adbAccessibility => 'होम बटन फिक्स सक्षम करें';

  @override
  String get adbAuthorization =>
      'टीवी पर ADB प्राधिकरण को स्वीकृत करें, फिर पुनः प्रयास करें।';

  @override
  String get adbChangeConfirm =>
      'इस सिस्टम सेटिंग को ADB के माध्यम से लागू करें? पिछला होम ऐप बदलने से पहले सहेजा गया है; अन्य पहुंच-योग्यता सेवाएँ संरक्षित हैं।';

  @override
  String get adbCheck => 'कनेक्शन की जाँच करें';

  @override
  String get adbDenied => 'सिस्टम ने इस परिवर्तन की अनुमति या पुष्टि नहीं की.';

  @override
  String get adbDisable => 'पिछले लॉन्चर को अक्षम करें';

  @override
  String get adbDisableConfirm =>
      'सहेजे गए पिछले लॉन्चर को अक्षम करें? इसके लिए CuteLauncher का वर्तमान होम ऐप होना आवश्यक है। इस सेटअप में पुनर्प्राप्ति क्रिया के साथ इसे पुनर्स्थापित करें।';

  @override
  String get adbHint =>
      'केवल इस टीवी के लिए प्रोटोटाइप (127.0.0.1)। डेवलपर विकल्पों में TCP ADB सक्षम करें, इसका पोर्ट दर्ज करें और टीवी पर प्राधिकरण संकेत को मंजूरी दें। पेयरिंग कोड के साथ वायरलेस डिबगिंग अभी समर्थित नहीं है। निजी कुंजी बैकअप के बाहर, इस डिवाइस पर रहती है।';

  @override
  String get adbHome => 'CuteLauncher को होम ऐप बनाएं';

  @override
  String get adbInvalid => '1024 और 65535 के बीच एक पोर्ट दर्ज करें।';

  @override
  String get adbNoRecovery =>
      'पुनर्स्थापना अनुपलब्ध है: कोई अन्य लॉन्चर या सहेजी गई सेवा स्थिति नहीं मिली।';

  @override
  String get adbPort => 'टीसीपी ADB पोर्ट';

  @override
  String get adbReady => 'ADB पहुंच की पुष्टि की गई।';

  @override
  String get adbRestore => 'पिछले लॉन्चर को पुनर्स्थापित करें';

  @override
  String get adbSuccess => 'परिवर्तन लागू किया गया और सत्यापित किया गया.';

  @override
  String get adbTitle => 'ADB सेटअप';

  @override
  String get adbUnavailable =>
      'कनेक्ट करने में असमर्थ. TCP ADB, पोर्ट और प्राधिकरण प्रॉम्प्ट की जाँच करें।';

  @override
  String get nightModeScheduled => 'शेड्यूल का उपयोग करें';

  @override
  String get nightModeTitle => 'रात्रि मोड';

  @override
  String get nightModeScope =>
      'अन्य ऐप्स को मंद करने के लिए ओवरले अनुमति की आवश्यकता है। इसके बिना, डिमिंग CuteLauncher के अंदर काम करता है। TCL फ़िल्टर को किसी ओवरले अनुमति की आवश्यकता नहीं है। 80% से ऊपर अपारदर्शिता Android अन्य ऐप्स में टच इनपुट को ब्लॉक कर सकती है; टीवी रिमोट की चाबियाँ अभी भी काम करती हैं।';

  @override
  String get nightModeEnd => 'ख़त्म';

  @override
  String get nightModeStart => 'प्रारंभ करें';

  @override
  String get nightModeDim => 'मंद करना';

  @override
  String get nightModeWarmth => 'गर्म फिल्टर';

  @override
  String get nightModeScheduleHint =>
      'स्थानीय टीवी समय का उपयोग करता है. रात्रिकालीन अवधि समर्थित हैं. समान प्रारंभ और समाप्ति समय निर्धारित फ़िल्टर को अक्षम कर देते हैं।';

  @override
  String get nightModeEnabled => 'रात्रि मोड सक्षम करें';

  @override
  String get nightModePermission => 'अन्य ऐप्स पर प्रदर्शन की अनुमति दें';

  @override
  String get nightModePermissionGranted => 'अन्य ऐप्स पर प्रदर्शन की अनुमति है';

  @override
  String get backupDownloadsFailed => 'बैकअप को डाउनलोड में सहेजा नहीं जा सका.';

  @override
  String get backupSaveDownloads => 'डाउनलोड में बैकअप सहेजें';

  @override
  String get adbRestoreAccessibility => 'सुगम्यता पहुंच बहाल करें';

  @override
  String get nightModeAdbConfirm =>
      'स्थानीय ADB का उपयोग करके CuteLauncher को अन्य ऐप्स पर प्रदर्शित करने की अनुमति दें? पहले टीसीपी डिबगिंग सक्षम करें और कनेक्शन अधिकृत करें। ADB विज़ार्ड या 5555 में सहेजे गए पोर्ट का उपयोग करता है।';

  @override
  String get nightModeAdbPermission => 'ADB के माध्यम से अनुमति प्रदान करें';

  @override
  String get nightModeNotificationsHint =>
      'अधिसूचना आपको CuteLauncher के बाहर फ़िल्टर बंद करने देती है। इसके बिना, इस मेनू का उपयोग करें.';

  @override
  String get nightModeNotificationsAllowed =>
      'रात्रि मोड अधिसूचना की अनुमति है';

  @override
  String get nightModeNotifications => 'रात्रि मोड अधिसूचना की अनुमति दें';

  @override
  String get categoryLastVisibleHint =>
      'कम से कम एक श्रेणी दृश्यमान रहनी चाहिए.';

  @override
  String get diagnosticsClear => 'स्पष्ट सत्र निदान';

  @override
  String get diagnosticsReady => 'रिपोर्ट तैयार';

  @override
  String get diagnosticsCreate => 'रिपोर्ट बनाएं';

  @override
  String get diagnosticsOperations => 'रिकॉर्ड किए गए ऑपरेशन';

  @override
  String get diagnosticsCopied => 'रिपोर्ट कॉपी की गई';

  @override
  String get diagnosticsHint =>
      'रिपोर्ट में ऐप संस्करण, अनुमति स्थिति, मेमोरी उपयोग और संचालन परिणाम शामिल हैं। इसमें कुंजियाँ, पते, फ़ाइल पथ, ऐप सूचियाँ और अधिसूचना सामग्री शामिल नहीं है। ऐप के पुनरारंभ होने तक केवल अंतिम 50 ऑपरेशन ही मेमोरी में रखे जाते हैं। कुछ भी स्वचालित रूप से नहीं भेजा जाता है.';

  @override
  String get diagnosticsTitle => 'त्रुटि निदान';

  @override
  String get diagnosticsCopyFailed => 'रिपोर्ट की प्रतिलिपि नहीं बनाई जा सकी.';

  @override
  String get diagnosticsCopy => 'रिपोर्ट कॉपी करें';

  @override
  String get diagnosticsCreating => 'रिपोर्ट बनाई जा रही है...';

  @override
  String get tclBlueLightTitle => 'TCL नीला प्रकाश फ़िल्टर';

  @override
  String get tclBlueLightError =>
      'TCL फ़िल्टर सेटिंग को पढ़ या सत्यापित नहीं कर सका। इसकी स्थिति ताज़ा करें और पुनः प्रयास करें।';

  @override
  String get tclBlueLightUnsupported =>
      'इस टीवी पर TCL फ़िल्टर इंटरफ़ेस उपलब्ध नहीं है।';

  @override
  String get tclBlueLightRefresh => 'TCL फ़िल्टर स्थिति ताज़ा करें';

  @override
  String get tclBlueLightHint =>
      'टीवी के अंतर्निर्मित नेत्र स्वास्थ्य सुरक्षा फ़िल्टर को नियंत्रित करता है। यह नाइट मोड शेड्यूल को भी फॉलो कर सकता है।';

  @override
  String get nightSolarSchedule => 'सूर्यास्त और सूर्योदय';

  @override
  String get nightNextStart => 'अगली शुरुआत';

  @override
  String get nightScheduleTimeHint =>
      'टाइम्स टीवी समय क्षेत्र का उपयोग करते हैं। नकारात्मक ऑफसेट पहले हैं; सकारात्मक ऑफसेट बाद में हैं।';

  @override
  String get nightTemperature => 'रंग तापमान फ़िल्टर करें';

  @override
  String get nightScheduleSettings => 'शेड्यूल सेटिंग';

  @override
  String get nightCityName => 'शहर का नाम';

  @override
  String get nightSkipUntilNext => 'अगले सूर्यास्त तक रात्रि मोड अक्षम करें';

  @override
  String get nightSunriseOffset => 'सूर्योदय के सापेक्ष समाप्त';

  @override
  String get nightEnableUntilMorning =>
      'अगले सूर्योदय तक रात्रि मोड सक्षम करें';

  @override
  String get nightPermissions => 'अनुमतियाँ';

  @override
  String get nightTclSchedule => 'शेड्यूल में TCL फ़िल्टर शामिल करें';

  @override
  String get nightSearchCity => 'खोजें';

  @override
  String get nightRefreshSun => 'सूर्योदय और सूर्यास्त को ताज़ा करें';

  @override
  String get nightSolarUnavailable =>
      'एक शहर चुनें और धूप के समय को ताज़ा करें। यदि सूर्योदय या सूर्यास्त अनुपलब्ध है, तो सौर कार्यक्रम रुक जाता है।';

  @override
  String get nightSunsetOffset => 'सूर्यास्त के सापेक्ष प्रारंभ करें';

  @override
  String get nightCityHint =>
      'स्थान पहुंच प्रदान करने के बजाय अपना शहर चुनें। सूर्य के समय को पुनः प्राप्त करने के लिए चयनित निर्देशांक को फ़ॉलबैक के रूप में Sunrise-Sunset.org, या Open-Meteo पर भेजा जाता है।';

  @override
  String get nightResumeSchedule => 'शेड्यूल पर लौटें';

  @override
  String get nightScheduleSource => 'अनुसूची प्रकार';

  @override
  String get nightSolarCached =>
      'कैश्ड सन टाइम का उपयोग करना; इंटरनेट रिफ्रेश स्वचालित रूप से पुनः प्रयास करेगा।';

  @override
  String get nightTclScheduleHint =>
      'रात्रि मोड सक्षम होने पर समान शेड्यूल का उपयोग करता है। TCL फ़िल्टर में मैन्युअल परिवर्तन अगले निर्धारित संक्रमण तक चलते हैं। किसी ओवरले अनुमति की आवश्यकता नहीं है.';

  @override
  String get nightRefreshPermission => 'ताज़ा अनुमति स्थिति';

  @override
  String get nightCityNotFound => 'कोई शहर नहीं मिला. कोई दूसरा नाम आज़माएं.';

  @override
  String get nightNoOffset => 'कोई ऑफसेट नहीं';

  @override
  String get nightManualSchedule => 'कस्टम शेड्यूल';

  @override
  String get nightChooseCity => 'शहर चुनें';

  @override
  String get nightPermissionUnknown => 'ओवरले अनुमति स्थिति अज्ञात है';

  @override
  String get nightNextEnd => 'अगला अंत';

  @override
  String get nightTemporaryOff =>
      'जब तक डिमिंग अस्थायी रूप से बंद नहीं हो जाती';

  @override
  String get nightCitySearchFailed =>
      'शहरों की खोज नहीं की जा सकी. अपना इंटरनेट कनेक्शन जांचें.';

  @override
  String get nightSolarAttribution =>
      'दैनिक सूर्य समय: Sunrise-Sunset.org; फ़ॉलबैक: Open-Meteo। शहर खोज: जियोनाम। ऑफ़लाइन उपयोग के लिए कई दिन कैश किए गए हैं।';

  @override
  String get nightTemporaryOn => 'जब तक अस्थायी रूप से मंदता जारी रहेगी';

  @override
  String get homeScreen => 'होम स्क्रीन';

  @override
  String get appearanceSettings => 'दिखावट';

  @override
  String get generalSettings => 'उन्नत';

  @override
  String get advancedSettings => 'उन्नत';

  @override
  String get controlAndStartup => 'लॉन्चर और टीवी नियंत्रण';

  @override
  String get sectionsAndOrder => 'अनुभाग और आदेश';

  @override
  String get topPanel => 'शीर्ष पैनल';

  @override
  String get tileStyle => 'टाइल शैली';

  @override
  String get tilesAndLabels => 'टाइल्स और लेबल';

  @override
  String get highlightAndAnimation => 'हाइलाइट और एनिमेशन';

  @override
  String get androidTvSettings => 'Android TV सेटिंग्स';

  @override
  String get weatherSettings => 'मौसम सेटिंग';

  @override
  String get showHighlightOutline => 'हाइलाइट रूपरेखा दिखाएँ';

  @override
  String get resetTilesAndPanel => 'टाइल और पैनल सेटिंग्स रीसेट करें';

  @override
  String get resetTilesAndPanelHint =>
      'अतिरिक्त टाइल, लेबल, हाइलाइट और शीर्ष पैनल पैरामीटर रीसेट करें? वॉलपेपर, उच्चारण रंग, टाइल शैली और लेबल दृश्यता संरक्षित हैं।';

  @override
  String get panelAppearanceSettings => 'शीर्ष पैनल उपस्थिति';

  @override
  String get panelSharedHint => 'टाइल सेटिंग में स्वरूप बदलें.';

  @override
  String get effectsCompatibilityHint =>
      'अतिरिक्त उपस्थिति: रूपरेखा हमेशा दृश्यमान होती है और स्पंदित नहीं होती है। आयामी शैली की कोई विरासती रूपरेखा नहीं होती; क्लासिक स्पंदित नहीं होता. तीव्रता पैमाने और छाया को प्रभावित करती है; स्केलिंग स्थान-सीमित है।';

  @override
  String get sizeAndLayout => 'आकार और लेआउट';

  @override
  String get labelsGroup => 'लेबल';

  @override
  String get surfaceGroup => 'सतह';

  @override
  String get clockAndDateGroup => 'घड़ी और तारीख';

  @override
  String get networkAndTrafficGroup => 'नेटवर्क और यातायात';

  @override
  String get buttonsGroup => 'बटन';

  @override
  String get notificationAppsHint =>
      'जिन ऐप्स के नोटिफिकेशन की आपको जरूरत नहीं है उन्हें बंद कर दें। एक सक्षम स्विच सूचनाओं की अनुमति देता है; ऐप अभी भी लॉन्च किया जा सकता है.';

  @override
  String get notificationPanelLink => 'शीर्ष पैनल उपस्थिति';

  @override
  String get overlayAccessAdb => 'अन्य ऐप्स पर प्रदर्शन (ADB)';

  @override
  String get tileStyleModern => 'आधुनिक';

  @override
  String get tileStyleVolume => 'आयामी';

  @override
  String get showTime => 'समय दिखाओ';

  @override
  String get showDate => 'दिनांक दिखाएँ';

  @override
  String get showWeather => 'मौसम दिखाओ';

  @override
  String get showNetwork => 'नेटवर्क स्थिति दिखाएँ';

  @override
  String get showTraffic => 'ट्रैफ़िक दिखाएँ';

  @override
  String get scheduledBrightness => 'अनुसूचित चमक';

  @override
  String get followTileStyle => 'शैली का पालन करें';

  @override
  String get androidTvSettingsHint => 'टीवी सिस्टम सेटिंग्स खोलें';

  @override
  String get autoHideTopPanel => 'पैनल को स्वचालित रूप से छुपाएं';

  @override
  String get showSectionTitles => 'अनुभाग शीर्षक दिखाएँ';

  @override
  String get usageDaily => 'दैनिक';

  @override
  String get usageWeekly => 'साप्ताहिक';

  @override
  String get usageMonthly => 'मासिक';

  @override
  String get onlineWallpaperAddress => 'छवि पता (HTTPS)';

  @override
  String get watchNextAppLimits => 'प्रति ऐप सीमाएँ';

  @override
  String get watchNextAppLimitsHint =>
      'स्रोत सीमाएँ समग्र सीमा से पहले लागू होती हैं। असीमित केवल समग्र सीमा रखता है; छिपी हुई सामग्री छिपी रहती है.';

  @override
  String get rememberCategoryFocus => 'अंतिम फोकस्ड कार्ड याद रखें';

  @override
  String get automaticBackups => 'स्वचालित बैकअप';

  @override
  String get automaticBackupsHint =>
      'लॉन्चर सक्रिय होने पर सेटिंग्स, वॉलपेपर और बैनर की दैनिक प्रतियां। एक छूटी हुई प्रति लॉन्चर पर लौटने के बाद चलती है। इस डिवाइस पर निजी तौर पर संग्रहीत, कुल 256 MiB तक; ऐप या उसके डेटा को हटाने से वे हट जाते हैं। एक बाहरी बैकअप भी रखें.';

  @override
  String get automaticBackupsEnabled => 'दैनिक स्वचालित बैकअप';

  @override
  String get automaticBackupsKeep => 'रखने के लिए प्रतिलिपियाँ';

  @override
  String get automaticBackupCreateNow => 'अभी एक पुनर्स्थापना बिंदु बनाएं';

  @override
  String get automaticBackupFailed =>
      'बैकअप कार्रवाई विफल रही. खाली स्थान की जाँच करें और पुनः प्रयास करें।';

  @override
  String get restorePoints => 'अंक पुनर्स्थापित करें';

  @override
  String get noRestorePoints => 'अभी तक कोई पुनर्स्थापना बिंदु नहीं';

  @override
  String get updatePrereleases => 'पूर्व-रिलीज़ संस्करणों में अपडेट करें';

  @override
  String get topPanelObjects => 'वस्तुएँ';

  @override
  String get panelTransparency => 'पैनल पारदर्शिता';

  @override
  String get panelTextBackground => 'पाठ और बटन पृष्ठभूमि';

  @override
  String get panelTextBackgroundColor => 'पाठ और बटन पृष्ठभूमि रंग';

  @override
  String get panelTextColor => 'पाठ और बटन का रंग';

  @override
  String get panelTextSize => 'पाठ और बटन का आकार';

  @override
  String get panelFont => 'पाठ फ़ॉन्ट';

  @override
  String get fontSans => 'संस सेरिफ़';

  @override
  String get fontSerif => 'सेरिफ़';

  @override
  String get fontMono => 'मोनोस्पेस';

  @override
  String get fontCondensed => 'संघनित';

  @override
  String get trafficPermissionGranted => 'यातायात सांख्यिकी पहुंच प्रदान की गई';

  @override
  String get background => 'पृष्ठभूमि';

  @override
  String get backgroundParameters => 'पैरामीटर्स';

  @override
  String get resetAppearanceHint =>
      'पृष्ठभूमि, उच्चारण, टाइल्स, लेबल, हाइलाइटिंग और एनीमेशन रीसेट करें?';

  @override
  String get wallpaperDimming => 'मंद करना';

  @override
  String get wallpaperPlacement => 'प्लेसमेंट';

  @override
  String get wallpaperDisplay => 'वॉलपेपर प्रदर्शन';

  @override
  String get wallpaperContain => 'संपूर्ण छवि दिखाएँ';

  @override
  String get wallpaperBlurred => 'अधिक धुंधली प्रतिलिपि';

  @override
  String get wallpaperCover => 'स्क्रीन भरें';

  @override
  String get wallpaperBrightness => 'वॉलपेपर की चमक';

  @override
  String get wallpaperSaturation => 'संतृप्ति';

  @override
  String get categoryPadding => 'श्रेणी गद्दी';

  @override
  String get categoryLight => 'रोशनी';

  @override
  String get categoryBlue => 'नीला';

  @override
  String get categoryPurple => 'बैंगनी';

  @override
  String get categoryAllRows => 'सब';

  @override
  String get categoryTeal => 'चैती';

  @override
  String get categoryMaxRows => 'दृश्यमान ग्रिड पंक्तियाँ';

  @override
  String get categoryDark => 'अंधेरा';

  @override
  String get categoryAppearance => 'श्रेणी उपस्थिति';

  @override
  String get categoryBackground => 'श्रेणी पृष्ठभूमि';

  @override
  String get categoryTransparent => 'पारदर्शी';

  @override
  String get slideshowInterval => 'अंतराल बदलें';

  @override
  String get slideshowFolderSelected =>
      'इस डिवाइस पर फ़ोल्डर एक्सेस सहेजा गया।';

  @override
  String get slideshowRandom => 'यादृच्छिक क्रम';

  @override
  String get wallpaperSlideshow => 'फ़ोल्डर स्लाइड शो';

  @override
  String get slideshowNext => 'अगली छवि';

  @override
  String get slideshowFolderRequired =>
      'स्लाइड शो प्रारंभ करने के लिए एक फ़ोल्डर चुनें.';

  @override
  String get slideshowHint =>
      '1,000 छवियाँ और 4,000 फ़ोल्डर प्रविष्टियाँ तक; 8 MiB तक फ़ाइलें। दूषित फ़ाइलें छोड़ दी जाती हैं और अंतिम अच्छी छवि बरकरार रखी जाती है। परिवर्तन पृष्ठभूमि में रुक जाते हैं. किसी अन्य डिवाइस पर रीस्टोर करने के बाद फिर से फोल्डर चुनें।';

  @override
  String get slideshowSeconds => 'एस';

  @override
  String get slideshowError =>
      'छवियाँ पढ़ने में असमर्थ. वैध छवियों वाला एक सुलभ फ़ोल्डर चुनें।';

  @override
  String get slideshowFolder => 'फ़ोल्डर चुनें';

  @override
  String get slideshowRecursive => 'सबफ़ोल्डर शामिल करें';

  @override
  String get weatherSourceKeyRequired =>
      'इस मौसम स्रोत के लिए एक API कुंजी जोड़ें।';

  @override
  String get weatherOpenWeatherCredit =>
      'मौसम: OpenWeather (openweathermap.org)। दैनिक मान उपलब्ध तीन घंटे की पूर्वानुमान अवधि का सारांश प्रस्तुत करते हैं।';

  @override
  String get weatherOpenWeatherHint =>
      'वर्तमान मौसम और 5 दिन/3 घंटे के पूर्वानुमान के लिए अपनी कुंजी का उपयोग करें। प्रत्येक अद्यतन दो अनुरोध करता है; पहुंच और सीमाएं आपकी योजना पर निर्भर करती हैं।';

  @override
  String get weatherOpenWeatherKey => 'OpenWeather API कुंजी';

  @override
  String get mediaPause => 'विराम';

  @override
  String get showNowPlaying => 'शो नाउ होम पर चल रहा है';

  @override
  String get nowPlayingAccessHint =>
      'मीडिया नियंत्रणों को CuteLauncher के लिए अधिसूचना पहुंच की आवश्यकता होती है। केवल खिलाड़ी द्वारा प्रदान की गई गतिविधियाँ दिखाई जाती हैं।';

  @override
  String get nowPlaying => 'अभी खेल रहे हैं';

  @override
  String get mediaNext => 'अगला ट्रैक';

  @override
  String get mediaPlay => 'बायोडाटा';

  @override
  String get mediaControlError =>
      'खिलाड़ी अनुपलब्ध है या उसने इस कार्रवाई को स्वीकार नहीं किया है.';

  @override
  String get nightUsageAccess => 'उपयोग की अनुमति दें';

  @override
  String get nightExcludedAppsHint =>
      'चयनित ऐप्स में ओवरले और शेड्यूल किया गया TCL फ़िल्टर रुका हुआ है। उपयोग पहुंच आवश्यक है; इसके बिना, बहिष्करण लागू नहीं किया जा सकता.';

  @override
  String get nightExcludedApps => 'बहिष्कृत ऐप्स';

  @override
  String get adbPairPort => 'युग्मन पोर्ट';

  @override
  String get adbPairOverlayHint =>
      'वायरलेस डिबगिंग खोलें और पेयरिंग कोड के साथ पेयर करें। सिस्टम कोड संवाद खुला रखें. यह फॉर्म 30 सेकंड के बाद सक्रिय हो जाता है। दोनों पोर्ट और Android द्वारा दिखाया गया कोड दर्ज करें।';

  @override
  String get adbOverlaySettings =>
      '30 सेकंड के लिए सेटिंग्स पर नियंत्रण लौटाएँ';

  @override
  String get adbTlsHint =>
      'डेवलपर विकल्पों में वायरलेस डिबगिंग का उपयोग करें। पेयरिंग और कनेक्शन के अलग-अलग पोर्ट होते हैं। यदि आपके फर्मवेयर में कोई पेयरिंग-कोड स्क्रीन नहीं है या ओवरले विंडो को ब्लॉक करता है, तो इसके बजाय टीसीपी/आरएसए का उपयोग करें। इस टीवी के सभी कनेक्शन स्थानीय रहेंगे।';

  @override
  String get adbPaired =>
      'युग्मित। वायरलेस डिबगिंग कनेक्शन पोर्ट का उपयोग करके कनेक्शन की जाँच करें।';

  @override
  String get adbTransport => 'कनेक्शन विधि';

  @override
  String get adbPairCode => 'छह अंकों का कोड';

  @override
  String get adbOverlayRequired =>
      'सेटिंग्स पर कोड प्रविष्टि को अन्य ऐप्स पर प्रदर्शित करने के लिए अनुमति की आवश्यकता होती है।';

  @override
  String get adbOverlayPermission => 'अन्य ऐप्स पर प्रदर्शन की अनुमति दें';

  @override
  String get adbTlsUnsupported =>
      'यह फर्मवेयर आवश्यक सेटिंग्स स्क्रीन या पेयरिंग ओवरले को नहीं खोल सकता है। टीसीपी/आरएसए का प्रयोग करें.';

  @override
  String get adbConnectPort => 'कनेक्शन पोर्ट';

  @override
  String get adbTls => 'टीएलएस / पेयरिंग कोड';

  @override
  String get adbTcp => 'टीसीपी/आरएसए';

  @override
  String get adbPairingFailed =>
      'युग्मन विफल. कोड और पेयरिंग पोर्ट की जाँच करें, Android कोड डायलॉग खुला रखें और पुनः प्रयास करें।';

  @override
  String get adbTlsDisabled =>
      'वायरलेस डिबगिंग अक्षम है या इसकी स्थिति अनुपलब्ध है। इसे डेवलपर विकल्पों में सक्षम करें।';

  @override
  String get adbPairOverlay => 'सेटिंग्स पर पेयरिंग कोड दर्ज करें';

  @override
  String get adbPair => 'जोड़ी';

  @override
  String get adbDeveloperSettings => 'डेवलपर विकल्प खोलें';

  @override
  String get adbTwoWindowsHint =>
      'यदि यह फर्मवेयर दो विंडो को सपोर्ट करता है, तो सिस्टम पेयरिंग डायलॉग को CuteLauncher के बगल में खुला रखें और इसका कोड यहां दर्ज करें। डायरेक्ट पेयरिंग केवल तभी उपलब्ध है जब दोनों विंडो खुली हों।';

  @override
  String get adbTwoWindows => 'दूसरी विंडो में सेटिंग्स खोलें';

  @override
  String get autoLaunchBoot => 'टीवी बूट के बाद';

  @override
  String get autoLaunchOff => 'विकलांग';

  @override
  String get autoLaunchTitle => 'स्वतः प्रारंभ';

  @override
  String get autoLaunchDelay => 'लॉन्च में देरी';

  @override
  String get autoLaunchHdmi => 'चयनित HDMI इनपुट पर स्विच करें';

  @override
  String get autoLaunchWake => 'जागने के बाद';

  @override
  String get autoLaunchHint =>
      'टीवी स्टार्टअप या वेक के बाद खोलने के लिए कोई ऐप या HDMI इनपुट चुनें। नीचे इवेंट और विलंब सेट करें. जब Android CuteLauncher दिखाता है तो कार्रवाई एक बार चलती है। कोई भी दूरस्थ इनपुट या होम स्क्रीन छोड़ने से प्रतीक्षा रद्द हो जाती है। आप बाद में HDMI इनपुट को स्वतंत्र रूप से बदल सकते हैं। CuteLauncher को डिफ़ॉल्ट लॉन्चर के रूप में सेट करें या यदि आवश्यक हो तो बूट पर स्टार्ट सक्षम करें। वेक डिटेक्शन को चालू रहने के लिए CuteLauncher की आवश्यकता होती है।';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds सेकंड';
  }

  @override
  String get autoLaunchApp => 'एक चयनित ऐप खोलें';

  @override
  String get autoLaunchTarget => 'लक्ष्य लॉन्च करें';

  @override
  String get autoLaunchUnavailable =>
      'लक्ष्य अनुपलब्ध है या फ़र्मवेयर इस क्रिया की अनुमति नहीं देता है.';

  @override
  String get autoLaunchCancelled => 'विलंबित लॉन्च रद्द कर दिया गया.';

  @override
  String get syncTitle => 'विनिमय सेटिंग्स';

  @override
  String get syncHint =>
      'एक सेटिंग फ़ाइल सहेजें, इसे किसी अन्य डिवाइस पर स्थानांतरित करें और वहां खोलें। दोनों डिवाइसों को अद्यतित करने के लिए फ़ाइल को वापस एक्सचेंज करें। इंटरफ़ेस, टाइल शैली और प्रदर्शन प्राथमिकताएँ साझा की जाती हैं। ऐप्स, अनुभाग, वॉलपेपर फ़ाइलें, अनुमतियां, HOME, लॉन्च नियम और रहस्य इस डिवाइस पर रहते हैं। यह मैन्युअल विनिमय है; किसी खाते या पृष्ठभूमि नेटवर्क कनेक्शन का उपयोग नहीं किया जाता है.';

  @override
  String get syncExport => 'किसी फ़ाइल में परिवर्तन सहेजें';

  @override
  String get syncImport => 'किसी अन्य डिवाइस से परिवर्तन खोलें';

  @override
  String get syncSaved => 'सेटिंग्स एक्सचेंज फ़ाइल सहेजी गई।';

  @override
  String get syncFailed =>
      'सेटिंग्स का आदान-प्रदान करने में असमर्थ. कोई आंशिक आयात नहीं रखा गया है. यदि समीक्षा के दौरान सेटिंग्स बदल गई हैं तो फ़ाइल की जाँच करें या इसे दोबारा खोलें।';

  @override
  String get syncPreviewHint =>
      'आवेदन करने से पहले परिवर्तनों की समीक्षा करें. विरोधों के लिए, इस डिवाइस या फ़ाइल को चुनने के लिए प्रत्येक पंक्ति का चयन करें। इस डिवाइस को रखना प्रारंभ में चुना गया है। रद्द करें सेटिंग्स को अपरिवर्तित छोड़ देता है।';

  @override
  String get syncNoChanges =>
      'कोई नई सेटिंग नहीं. साझा इतिहास को स्वीकार करने के लिए आवेदन करें।';

  @override
  String syncLocalValue(String value) {
    return 'यह डिवाइस: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'फ़ाइल से: $value';
  }

  @override
  String get syncKeepLocal => 'संघर्ष: इस उपकरण को रखें';

  @override
  String get syncUseFile => 'संघर्ष: फ़ाइल का उपयोग करें';

  @override
  String get syncApply => 'समीक्षा किए गए परिवर्तन लागू करें';

  @override
  String get syncApplied =>
      'सेटिंग्स का आदान-प्रदान हुआ। परिणाम वापस भेजने के लिए एक नई फ़ाइल सहेजें।';

  @override
  String syncStyleParameters(int count) {
    return 'कस्टम शैली: $count सेटिंग (अंतर नीचे दिए गए हैं)';
  }

  @override
  String get cloudBackups => 'क्लाउड बैकअप';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud। किसी मौजूदा फ़ोल्डर का HTTPS पता और एक ऐप पासवर्ड दर्ज करें। स्थानान्तरण मैनुअल हैं; यह फ़ोल्डर नवीनतम प्रति संग्रहीत करता है.';

  @override
  String get cloudUrl => 'फ़ोल्डर HTTPS पता';

  @override
  String get cloudUser => 'उपयोगकर्ता नाम';

  @override
  String get cloudPassword => 'ऐप पासवर्ड';

  @override
  String get cloudConnect => 'खाता जांचें और सहेजें';

  @override
  String get cloudCheck => 'कनेक्शन की जाँच करें';

  @override
  String get cloudDisconnect => 'खाता डिस्कनेक्ट करें';

  @override
  String get cloudDisconnectConfirm =>
      'इस खाते को टीवी से हटाएं? क्लाउड में प्रतियां बनी रहेंगी.';

  @override
  String get cloudUpload => 'एक प्रति क्लाउड पर सहेजें';

  @override
  String get cloudDownload => 'बादल से पुनर्स्थापित करें';

  @override
  String get cloudUploadConfirm =>
      'इस फ़ोल्डर में Cutelauncher_backup.json को वर्तमान सेटिंग्स और डेटा से बदलें?';

  @override
  String get cloudSuccess => 'हो गया';

  @override
  String get cloudConfigurationError =>
      'HTTPS फ़ोल्डर पता, उपयोगकर्ता नाम और ऐप पासवर्ड जांचें।';

  @override
  String get cloudAuthorizationError =>
      'प्रवेश निषेध. अपने खाते और फ़ोल्डर अनुमतियों की जाँच करें.';

  @override
  String get cloudMissingError => 'फ़ोल्डर या बैकअप नहीं मिला.';

  @override
  String get cloudUnsupportedError =>
      'यह पता आवश्यक WebDAV संचालन का समर्थन नहीं करता है। रीडायरेक्ट का पालन नहीं किया जाता; अंतिम फ़ोल्डर पता दर्ज करें.';

  @override
  String get cloudNetworkError =>
      'कनेक्शन विफल या समयबाह्य. नेटवर्क उपलब्ध होने पर पुनः प्रयास करें.';

  @override
  String get cloudFailed =>
      'बैकअप क्रिया पूर्ण नहीं हो सकी. भंडारण पहुंच की जाँच करें और पुनः प्रयास करें।';

  @override
  String get cloudStorageError =>
      'खाता संग्रहण अनुपलब्ध है. खाते को फिर से डिस्कनेक्ट और कॉन्फ़िगर करें।';

  @override
  String get adbPermissionChecking => 'पहुंच की जाँच की जा रही है...';

  @override
  String get adbPermissionConnected => 'ADB कनेक्ट · अनुमति प्रदान करें';

  @override
  String get adbPermissionDisconnected =>
      'ADB डिस्कनेक्ट हो गया · कनेक्शन सेट करें';

  @override
  String get adbSetupIntro =>
      'टीवी डेवलपर सेटिंग्स में डिबगिंग और नेटवर्क ADB सक्षम करें, फिर CuteLauncher पर भरोसा करें। सभी ADB कार्रवाइयां आपके अपने जोखिम पर हैं।';

  @override
  String get adbConnectionBlock => 'ADB कनेक्शन';

  @override
  String get adbNotChecked => 'कनेक्शन की जाँच नहीं की गई';

  @override
  String get adbApplied => 'पहले ही आवेदन कर दिया गया है';

  @override
  String get adbNotApplied => 'अभी तक आवेदन नहीं किया गया है';

  @override
  String get adbDefaultBlock => 'डिफ़ॉल्ट लॉन्चर';

  @override
  String get adbSystemDefault => 'सिस्टम डिफॉल्ट लॉन्चर सेटिंग खोलें';

  @override
  String get adbAssignDefault =>
      'ADB के माध्यम से CuteLauncher को डिफ़ॉल्ट लॉन्चर के रूप में सेट करें';

  @override
  String get adbRestoreDefault =>
      'ADB के माध्यम से पिछले डिफ़ॉल्ट लॉन्चर को पुनर्स्थापित करें';

  @override
  String get adbDefaultHint =>
      'यदि सिस्टम मेनू डिफ़ॉल्ट लॉन्चर सेट नहीं कर सकता है तो ADB का उपयोग करें।';

  @override
  String get adbBuiltinHint =>
      'अंतर्निहित लॉन्चर को अक्षम करने से सिस्टम को इसके बजाय CuteLauncher खोलने की सुविधा मिलती है। टीवी मेनू और बटन प्रभावित हो सकते हैं. इसे पूर्ववत करने के लिए अंतर्निहित लॉन्चर को सक्षम करें।';

  @override
  String get adbHomeBlock => 'होम बटन और स्टार्टअप';

  @override
  String get adbEnableService =>
      'ADB के माध्यम से CuteLauncher पहुंच सेवा सक्षम करें';

  @override
  String get adbHomeOverride => 'होम बटन को ओवरराइड करें';

  @override
  String get adbHomeOptional =>
      'यदि अंतर्निहित लॉन्चर अक्षम है, तो होम को ओवरराइड करना और टीवी स्टार्टअप पर लॉन्च करना वैकल्पिक है।';

  @override
  String get adbEnableBuiltin =>
      'ADB के माध्यम से अंतर्निहित लॉन्चर सक्षम करें';

  @override
  String get adbDisableBuiltin =>
      'ADB के माध्यम से अंतर्निहित लॉन्चर को अक्षम करें';

  @override
  String get adbNoBuiltin =>
      'कोई अंतर्निहित Google TV / Android TV लॉन्चर नहीं मिला।';

  @override
  String get adbChanged =>
      'राज्य बदल गया. कनेक्शन की जाँच करें और कार्रवाई की दोबारा पुष्टि करें।';

  @override
  String get adbEffectHome =>
      'CuteLauncher सिस्टम डिफॉल्ट लॉन्चर बन जाएगा। वर्तमान लॉन्चर को पुनर्स्थापना के लिए सहेजा जाएगा।';

  @override
  String get adbEffectRestore =>
      'पिछला लॉन्चर सक्षम किया जाएगा और डिफ़ॉल्ट बना दिया जाएगा. यदि अनुपलब्ध है या सहेजा नहीं गया है, तो पहले उपलब्ध अन्य लॉन्चर का चयन किया जाता है। यह होम बटन फिक्स को अक्षम नहीं करता है।';

  @override
  String get adbEffectDisable =>
      'टीवी उपयोगकर्ता के लिए अंतर्निहित लॉन्चर ऐप अक्षम कर दिया जाएगा। टीवी मेनू और बटन काम करना बंद कर सकते हैं। ऐप अनइंस्टॉल नहीं हुआ है.';

  @override
  String get adbRecoveryHomeDisable =>
      'इसकी पुनर्प्राप्ति होम स्क्रीन सहित संपूर्ण Google TV सेटअप विज़ार्ड भी अक्षम कर दिया जाएगा ताकि CuteLauncher डिफ़ॉल्ट लॉन्चर बन सके। पुनर्स्थापना तक सेटअप विज़ार्ड सुविधाएँ अनुपलब्ध रहेंगी। दोनों पैकेजों की मूल स्थिति पुनर्स्थापना के लिए सहेजी जाएगी।';

  @override
  String get adbRecoveryHomeRestore =>
      'Google TV सेटअप विज़ार्ड भी अपनी सहेजी गई स्थिति में वापस आ जाएगा।';

  @override
  String get adbDisableHomeUnavailable =>
      'अन्य होम स्क्रीन की प्राथमिकता अधिक है। इसे इस लॉन्चर द्वारा सुरक्षित रूप से अक्षम नहीं किया जा सकता है.';

  @override
  String get adbEffectEnable =>
      'अंतर्निहित लॉन्चर को उसकी सहेजी गई स्थिति में पुनर्स्थापित किया जाएगा, या यदि कोई स्थिति सहेजी नहीं गई थी तो सक्षम किया जाएगा। सिस्टम इसे फिर से डिफ़ॉल्ट लॉन्चर के रूप में चुन सकता है।';

  @override
  String get adbEffectAccessibility =>
      'CuteLauncher एक्सेसिबिलिटी सेवा सक्षम की जाएगी। यह होम इवेंट प्राप्त कर सकता है; अवरोधन को एक अलग स्विच द्वारा नियंत्रित किया जाता है। अन्य सेवाएँ संरक्षित हैं.';

  @override
  String get adbEffectAccessibilityRestore =>
      'ADB पहुंच प्रदान किए जाने से पहले CuteLauncher सेवा अपनी स्थिति में वापस आ जाएगी। अन्य पहुंच-योग्यता सेवाएँ संरक्षित हैं।';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher को रात्रि फ़िल्टर सहित अन्य ऐप्स पर विंडो प्रदर्शित करने की अनुमति दी जाएगी।';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher को अपनी श्रोता सेवा के माध्यम से अधिसूचना पहुंच प्राप्त होगी।';

  @override
  String get adbEffectWatchNext =>
      'CuteLauncher को डेटा देखना जारी रखने तक पहुंच प्राप्त होगी।';

  @override
  String get adbEffectUsage =>
      'CuteLauncher को ट्रैफ़िक और फ़ोरग्राउंड ऐप डिटेक्शन के लिए उपयोग सांख्यिकी एक्सेस प्राप्त होगा।';

  @override
  String get adbEffectWriteSettings =>
      'CuteLauncher को सिस्टम ब्राइटनेस सेटिंग्स बदलने की अनुमति दी जाएगी।';

  @override
  String get adbNoAvailableLauncher =>
      'कोई अन्य स्थापित लॉन्चर नहीं मिला. पुनर्स्थापना अनुपलब्ध है.';

  @override
  String get adbUnsupported =>
      'इस डिवाइस पर अनुपलब्ध: कोई समर्थित ADB कमांड नहीं।';

  @override
  String get adbHomeUnavailable =>
      'अंतर्निर्मित लॉन्चर में सिस्टम प्राथमिकता है। ADB के माध्यम से सीधा असाइनमेंट उपलब्ध नहीं है; एक्सेसिबिलिटी का उपयोग करें या अंतर्निहित लॉन्चर को अक्षम करें।';

  @override
  String get nightBatteryExempt => 'CuteLauncher अनुकूलन से मुक्त है';

  @override
  String get nightBatteryHint =>
      'शेड्यूल को पृष्ठभूमि में चलाने में सहायता मिल सकती है. यह गारंटी नहीं देता कि प्रक्रिया स्टैंडबाय बनी रहेगी।';

  @override
  String get nightBatteryOptimized => 'CuteLauncher अनुकूलन के अधीन है';

  @override
  String get nightBatteryTitle => 'बैटरी अनुकूलन';

  @override
  String get nightBatteryUnavailable =>
      'इस फ़र्मवेयर पर सिस्टम सेटिंग्स अनुपलब्ध हैं या एक्सेस अस्वीकृत कर दिया गया है।';

  @override
  String get nightBatteryUnknown => 'छूट की स्थिति अज्ञात';

  @override
  String get nightBatteryOpenApps => 'ऐप्स सेटिंग खोलें';

  @override
  String get nightBatteryGuide =>
      '1. ऐप्स सेटिंग में, स्पेशल ऐप एक्सेस खोलें।\n2. बैटरी अनुकूलन (कभी-कभी ऊर्जा बचतकर्ता) का चयन करें।\n3. CuteLauncher खोजें; यदि आवश्यक हो तो सभी ऐप्स का चयन करें।\n4. अनुकूलन अक्षम करें या अप्रतिबंधित का चयन करें।\nमेनू के नाम और उपलब्धता टीवी फ़र्मवेयर पर निर्भर करते हैं।';

  @override
  String get updateNotifications => 'अद्यतन सूचनाएं दिखाएँ';

  @override
  String get diagnosticsSave => 'फ़ाइल में रिपोर्ट सहेजें';

  @override
  String get diagnosticsSaved => 'रिपोर्ट सहेजी गई';

  @override
  String get diagnosticsSaveFailed =>
      'रिपोर्ट सहेजी नहीं जा सकी. फ़ाइल प्रबंधक और गंतव्य फ़ोल्डर की जाँच करें.';

  @override
  String get memoryCacheSize => 'छवि कैश आकार';

  @override
  String get memoryProcess => 'ऐप मेमोरी';

  @override
  String get memoryImages => 'छवि कैश';

  @override
  String get diagnosticsExportOpened =>
      'फ़ाइल प्रबंधक में एक फ़ोल्डर चुनें और रिपोर्ट सहेजें।';

  @override
  String get adbDisableService =>
      'ADB के माध्यम से CuteLauncher पहुंच सेवा को अक्षम करें';

  @override
  String get adbDefaultSettings => 'डिफ़ॉल्ट लॉन्चर सेटिंग्स';

  @override
  String get adbHomeSettings => 'होम बटन सेटिंग्स';

  @override
  String get adbAccessibilitySettings => 'अभिगम्यता सेटिंग खोलें';

  @override
  String get adbAccessibilityGuide =>
      'सिस्टम मेनू में CuteLauncher चुनें और इसकी सेवा सक्षम करें। होम इंटरसेप्शन को कॉन्फ़िगर करने के लिए यहां वापस लौटें। इसे अक्षम करने के लिए, उसी मेनू में CuteLauncher सेवा को बंद करें।';

  @override
  String get adbEffectAccessibilityDisable =>
      'CuteLauncher सेवा अक्षम कर दी जाएगी। घर में दखलअंदाज़ी बंद हो जाएगी. अन्य पहुंच-योग्यता सेवाएँ संरक्षित हैं।';

  @override
  String get backupAutoEnabled => 'स्वचालित बैकअप';

  @override
  String get backupClientId => 'ग्राहक आईडी';

  @override
  String get backupClientSecret => 'ग्राहक रहस्य';

  @override
  String get backupCloudImportConfirm =>
      'सभी स्थानीय सेटिंग्स, श्रेणियां और छवियां क्लाउड डेटा से बदल दी जाएंगी। जारी रखना?';

  @override
  String get backupConfigured => 'विन्यस्त';

  @override
  String get backupConnection => 'कनेक्शन सेटिंग्स';

  @override
  String get backupCreated => 'बनाया गया';

  @override
  String get backupDaily => 'दैनिक';

  @override
  String get backupDriveHelp =>
      'कनेक्ट चुनें और अपने फ़ोन पर कोड की पुष्टि करें। बैकअप Google Drive में CuteLauncher फ़ोल्डर में दिखाई देते हैं, जहां आप उन्हें डाउनलोड या हटा सकते हैं। इन-ऐप पुनर्स्थापना के लिए फ़ाइल नाम अपरिवर्तित रखें। छिपे हुए बैकअप से अपग्रेड करने के बाद पुनः कनेक्ट करें; पुराने बैकअप स्वचालित रूप से माइग्रेट नहीं होते हैं.';

  @override
  String get backupFrequency => 'बैकअप आवृत्ति';

  @override
  String get backupHourly => 'प्रति घंटा';

  @override
  String get backupLocal => 'स्थानीय प्रतिलिपियाँ';

  @override
  String get backupMinutes => 'मि';

  @override
  String get backupMode => 'मोड';

  @override
  String get backupNever => 'अभी तक कोई बैकअप नहीं है';

  @override
  String get backupNotConfigured => 'कॉन्फ़िगर नहीं किया गया';

  @override
  String get backupOptions => 'बैकअप विकल्प';

  @override
  String get backupSaveMode => 'बैकअप';

  @override
  String get backupScope => 'सभी टीवी पर बैकअप';

  @override
  String get backupSyncScope => 'सभी टीवी पर सिंक्रोनाइज़ेशन';

  @override
  String get backupSeparate => 'प्रत्येक टीवी के लिए अलग';

  @override
  String get backupShared => 'सभी टीवी के लिए समान सेटिंग्स';

  @override
  String get backupStorage => 'भंडारण';

  @override
  String get backupSyncHelp =>
      'डेटा डाउनलोड करें और परिवर्तन अपलोड करें. नवीनतम परिवर्तन से संघर्षों में जीत मिलती है। टीवी की घड़ियां सही होनी चाहिए. लॉन्चर खुला होने पर सिंक्रोनाइज़ेशन चलता है।';

  @override
  String get backupSyncLimit => 'से अधिक बार जाँच न करें';

  @override
  String get backupSyncMode => 'तुल्यकालन';

  @override
  String get backupSyncOptions => 'तुल्यकालन विकल्प';

  @override
  String get backupTime => 'बैकअप समय';

  @override
  String get backupWeekday => 'सप्ताह का दिन';

  @override
  String get backupWeekly => 'साप्ताहिक';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'स्थानीय प्रतियां ऐप या उसके डेटा के साथ हटा दी जाती हैं। एक प्रति टीवी के बाहर भी रखें।';

  @override
  String get panelObjectOrder => 'वस्तु क्रम';

  @override
  String get panelInformationGroup => 'सूचना';

  @override
  String get panelOrderHint =>
      '◄ / ► से स्थान बदलना शुरू या समाप्त करें; ▲ / ▼ से क्रम बदलें और समूह की सीमा पर दूसरी ओर ले जाएँ; OK / Back से समाप्त करें।';

  @override
  String get panelTextBackgroundTransparency =>
      'पाठ और बटन पृष्ठभूमि पारदर्शिता';

  @override
  String get weatherCityHint =>
      'शहर का नाम अंग्रेजी में दर्ज करें, उदाहरण के लिए मॉस्को।';

  @override
  String get weatherCityNotFound =>
      'शहर नहीं मिला. अंग्रेजी में शहर का नाम जांचें।';

  @override
  String get weatherLocationAutomatic => 'स्वचालित रूप से प्राप्त करें';

  @override
  String get weatherLocationAutomaticHint =>
      'डिवाइस निर्देशांक प्राप्त करें. स्थान की अनुमति आवश्यक है.';

  @override
  String get weatherLocationManual => 'मैन्युअल रूप से दर्ज करें';

  @override
  String get weatherLocationPermissionDenied =>
      'Android सेटिंग्स में स्थान पहुंच की अनुमति दें और पुनः प्रयास करें।';

  @override
  String get weatherLocationUnavailable =>
      'निर्देशांक प्राप्त नहीं हो सके. Android स्थान सेटिंग जांचें या मैन्युअल रूप से शहर दर्ज करें।';

  @override
  String get nightFilterSettings => 'फ़िल्टर सेटिंग्स';

  @override
  String get nightScheduleMenu => 'अनुसूची';

  @override
  String get nightScheduleInactive => 'शेड्यूल बंद है';

  @override
  String get nightLocation => 'स्थान';

  @override
  String get nightLocationAutomatic => 'स्वचालित रूप से प्राप्त करें';

  @override
  String get nightLocationManual => 'मैन्युअल रूप से दर्ज करें';

  @override
  String get nightLocationFailed =>
      'स्थान अनुपलब्ध. अनुमति और सिस्टम स्थान सेटिंग जांचें.';

  @override
  String get nightCityEnglish => 'शहर का नाम अंग्रेजी में दर्ज करें';

  @override
  String get nightOverlayBrief =>
      'फ़िल्टर को अन्य ऐप्स पर प्रदर्शित होने की अनुमति देता है।';

  @override
  String get weatherGetLocation => 'स्थान प्राप्त करें';

  @override
  String get backupLastCreated => 'अंतिम बैकअप बनाया गया था:';

  @override
  String get backupManagement => 'बैकअप प्रबंधित करें';

  @override
  String get backupCopyList => 'बैकअप सूची';

  @override
  String get backupRefreshCopyList => 'बैकअप सूची ताज़ा करें';

  @override
  String get backupCreateNow => 'अब एक नया बैकअप बनाएं';

  @override
  String get backupFolderPath => 'बैकअप फ़ोल्डर';

  @override
  String get backupPrivateFolder => 'निजी एप्लिकेशन फ़ोल्डर';

  @override
  String get backupRestoreCopy => 'इस बैकअप को पुनर्स्थापित करें';

  @override
  String get backupDeleteConfirm => 'चयनित बैकअप हटाएँ?';

  @override
  String get blockedAppsGroup => 'अवरुद्ध ऐप्स';

  @override
  String get notificationSettingsButton => 'अधिसूचना सेटिंग्स';

  @override
  String get hidePersistentNotificationsHint =>
      'सूची में और अन्य ऐप्स पर लगातार सूचनाएं छुपाएं।';

  @override
  String get nightTransitionTime => 'संक्रमण काल';

  @override
  String get brightnessSolar => 'रात्रि मोड शेड्यूल का उपयोग करें';

  @override
  String get brightnessAfterSunrise => 'सूर्योदय के बाद';

  @override
  String get brightnessAfterSunset => 'सूर्यास्त के बाद';

  @override
  String get brightnessTransitionTime => 'चमक संक्रमण का समय';

  @override
  String get brightnessSolarUnavailable =>
      'रात्रि मोड शेड्यूल अनुपलब्ध है. इसका समय और स्थान जांचें.';

  @override
  String get persistentNotificationCannotDelete =>
      'इस सतत अधिसूचना को हटाया नहीं जा सकता. आप इसे केवल ब्लॉक कर सकते हैं.';

  @override
  String get diagnosticsCreateFailed =>
      'डायग्नोस्टिक रिपोर्ट नहीं बनाई जा सकी. पुनः प्रयास करें।';

  @override
  String get backupListFailed =>
      'बैकअप सूची लोड नहीं हो सकी. चयनित भंडारण तक पहुंच की जाँच करें।';

  @override
  String get updateInstallerFailed =>
      'अद्यतन इंस्टॉलर नहीं खुल सका. पुनः प्रयास करें और जांचें कि Android इंस्टॉलर उपलब्ध है।';

  @override
  String get backupFolderFailed =>
      'बैकअप फ़ोल्डर का चयन या सहेजा नहीं जा सका. एक सुलभ फ़ोल्डर चुनें और पुनः प्रयास करें।';

  @override
  String get updateDownloadFailed =>
      'अपडेट डाउनलोड नहीं हो सका. अपने इंटरनेट कनेक्शन और उपलब्ध संग्रहण की जाँच करें।';

  @override
  String get backupDeleteFailed =>
      'बैकअप हटाया नहीं जा सका. हटाएँ अनुमतियाँ जाँचें और पुनः प्रयास करें।';

  @override
  String get updateCheckFailed =>
      'अद्यतनों की जाँच नहीं की जा सकी. अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get backupCreateFailed =>
      'बैकअप नहीं बनाया जा सका. भंडारण पहुंच और उपलब्ध स्थान की जाँच करें।';

  @override
  String get wallpaperChangeFailed =>
      'वॉलपेपर नहीं बदला जा सका. फ़ाइल पहुंच की जाँच करें और पुनः प्रयास करें।';

  @override
  String get backupDownloadsFolder => 'डाउनलोड / CuteLauncher';

  @override
  String get backupChooseFolder => 'फ़ाइल प्रबंधक में एक फ़ोल्डर चुनें';

  @override
  String get backupFolderPickerUnavailable =>
      'इस टीवी पर कोई फ़ोल्डर पिकर उपलब्ध नहीं है। डाउनलोड / CuteLauncher या आंतरिक ऐप फ़ोल्डर चुनें।';

  @override
  String get driveConfigurationError =>
      'Google Drive क्रेडेंशियल गुम या अमान्य हैं। अपने टीवी OAuth क्लाइंट की क्लाइंट आईडी और क्लाइंट सीक्रेट दर्ज करें।';

  @override
  String get driveCodeExpired =>
      'Google Drive साइन-इन का समय समाप्त हो गया। नया कोड प्राप्त करने के लिए खाता जांचें और सहेजें का चयन करें.';

  @override
  String get brightnessAfterNightStart => 'रात का समय';

  @override
  String get brightnessAfterNightEnd => 'दिन का समय';

  @override
  String get backupSyncSettings => 'सिंक्रनाइज़ करने के लिए सेटिंग्स';

  @override
  String get backupSyncHomeGroup => 'होम स्क्रीन, अनुभाग और ऐप्स';

  @override
  String get backupSyncAppearanceGroup => 'उपस्थिति, वॉलपेपर और बैनर';

  @override
  String get backupSyncDisplayGroup => 'रात्रि मोड, चमक और स्क्रीनसेवर';

  @override
  String get backupSyncControlsGroup => 'लॉन्चर और टीवी नियंत्रण';

  @override
  String get backupSyncGeneralGroup => 'भाषा, अपडेट और अन्य सेटिंग्स';

  @override
  String get backupSyncGroupsHelp =>
      'अक्षम ब्लॉक इस टीवी पर स्थानीय रहते हैं। ब्लॉक चयन उपकरणों के बीच सिंक्रनाइज़ है।';

  @override
  String get backupSyncGroupsFailed =>
      'सिंक्रनाइज़ेशन के लिए सेटिंग चयन सहेजा नहीं जा सका. पुनः प्रयास करें।';

  @override
  String get tileLayoutMode => 'टाइल लेआउट';

  @override
  String get tileLayoutAuto => 'टाइल आकार के अनुसार स्वचालित';

  @override
  String get tileLayoutColumns => 'निश्चित स्तंभ गिनती';

  @override
  String get tileLayoutRows => 'निश्चित पंक्ति गिनती';

  @override
  String get tileRowCount => 'पंक्ति गिनती';

  @override
  String get useGlobalTileSettings => 'वैश्विक सेटिंग्स का प्रयोग करें';

  @override
  String get centerSelection => 'चयन स्थिति';

  @override
  String get selectionBottom => 'तल';

  @override
  String get selectionLower => 'निचला मध्य';

  @override
  String get selectionCenter => 'केंद्र';

  @override
  String get selectionUpper => 'ऊपरी मध्य';

  @override
  String get selectionTop => 'शीर्ष';

  @override
  String get settingsStyle => 'सेटिंग्स शैली';

  @override
  String get tileFocusEnlargement => 'फोकस इज़ाफ़ा';

  @override
  String get tileFocusShadowStrength => 'छाया शक्ति';

  @override
  String get tileFocusLift => 'लिफ्ट';

  @override
  String get tileFocusLiftHeight => 'ऊँचाई उठाएँ';

  @override
  String get tileFocusBorderColor => 'फोकस बॉर्डर रंग';

  @override
  String get tileFocusAccentColor => 'उच्चारण रंग';

  @override
  String get tileFocusDynamicColor => 'गतिशील रंग';

  @override
  String get tileSizeFromColumns =>
      'टाइल का आकार कॉलम संख्या और अनुभाग की चौड़ाई से निर्धारित होता है।';

  @override
  String get resetSectionToGlobal => 'साझा मूल्यों पर सेटिंग्स रीसेट करें';

  @override
  String get resetSectionToGlobalHint =>
      'साझा अनुभाग शीर्षक, आइकन और पृष्ठभूमि पुनर्स्थापित करें, और पैडिंग रीसेट करें?';

  @override
  String get resetStyleSection => 'इस अनुभाग को रीसेट करें';

  @override
  String get resetStyleSectionHint =>
      'केवल इस अनुभाग के लिए डिफ़ॉल्ट पुनर्स्थापित करें?';

  @override
  String get notificationStyle => 'अधिसूचना शैली';

  @override
  String get styleBackgroundColor => 'पृष्ठभूमि का रंग';

  @override
  String get styleTransparency => 'पृष्ठभूमि पारदर्शिता';

  @override
  String get styleTextSize => 'पाठ का आकार';

  @override
  String get styleTextColor => 'पाठ का रंग';

  @override
  String get noticeSize => 'अधिसूचना का आकार';

  @override
  String get noticeStylePreview => 'अधिसूचना पूर्वावलोकन';

  @override
  String get backupSyncHomeOptions => 'व्यवहार और सामान्य विकल्प';

  @override
  String get backupSyncBackground => 'पृष्ठभूमि और कस्टम बैनर';

  @override
  String get backupSyncTiles => 'टाइल, मेनू और अधिसूचना शैली';

  @override
  String get backupSyncWeatherSource => 'स्रोत एवं स्थान';

  @override
  String get backupSyncWeatherDisplay => 'मौसम प्रदर्शन और तापमान इकाइयाँ';

  @override
  String get backupSyncNotificationSettings => 'अधिसूचना प्रदर्शन और फ़िल्टर';

  @override
  String get backupSyncOther => 'अन्य सेटिंग्स';

  @override
  String get tileFocusBorderStyle => 'सीमा शैली';

  @override
  String get tileFocusOutline => 'रूपरेखा';

  @override
  String get tileFocusGlow => 'चमक';

  @override
  String get tileFocusNoBorder => 'कोई सीमा नहीं';

  @override
  String get tileShowFocusShadow => 'छाया दिखाओ';

  @override
  String get homeLayoutRow => 'क्षैतिज पंक्ति';

  @override
  String get homeLayoutRows => 'एकाधिक पंक्तियाँ';

  @override
  String get homeLayoutGrid => 'ग्रिड';

  @override
  String get homeCardCount => 'चारों ओर दिखाई देने वाले कार्ड';

  @override
  String get homeAuto => 'ऑटो';

  @override
  String get homeFree => 'मुफ़्त स्क्रॉलिंग';

  @override
  String get homeAnchored => 'लंगर डाला हुआ अनुभाग';

  @override
  String get homeScrollMode => 'अनुभाग स्क्रॉलिंग';

  @override
  String get homeSectionPosition => 'सक्रिय अनुभाग स्थिति';

  @override
  String get homeLabelMode => 'अनुप्रयोग लेबल';

  @override
  String get homeLabelNone => 'कोई लेबल नहीं';

  @override
  String get homeLabelSelected => 'केवल चयनित आवेदन';

  @override
  String get homeLabelAll => 'सभी अनुप्रयोग';

  @override
  String get homeInherited => 'विरासत में मिला मूल्य';

  @override
  String get homeOwnReset => 'कस्टम मान · वैश्विक उपयोग करें';

  @override
  String get homeParameters => 'पैरामीटर्स';

  @override
  String get homeSectionStyle => 'अनुभाग उपस्थिति';

  @override
  String get homeSectionGap => 'अनुभागों के बीच का स्थान';

  @override
  String get homeSectionIcons => 'अनुभाग चिह्न';

  @override
  String get homeInactiveOpacity => 'निष्क्रिय अनुभाग अपारदर्शिता';

  @override
  String get homeResetSection =>
      'विरासत में मिले अनुभाग स्वरूप को पुनर्स्थापित करें';

  @override
  String get homeCalculatedSize => 'आकार की गणना कार्ड की गिनती से की जाती है';

  @override
  String homeGapLimited(int gap) {
    return 'चयनित कार्ड संख्या को बनाए रखने के लिए रिक्ति $gap तक सीमित है।';
  }

  @override
  String get homeResetLayout => 'अनुभाग लेआउट रीसेट करें';

  @override
  String homeVisibleRows(int count) {
    return 'पूरी तरह से दृश्यमान पंक्तियाँ: $count';
  }

  @override
  String get homeStylePartial =>
      'केवल उन अनुभागों पर लागू होता है जो इस मान को प्राप्त करते हैं और अपने वर्तमान लेआउट में इसका समर्थन करते हैं।';

  @override
  String get homeStyleUnavailable =>
      'वर्तमान अनुभाग सेटिंग में अनुपलब्ध है. लेआउट और स्थानीय ओवरराइड की जाँच करें।';

  @override
  String get homeStyleNeedsRows =>
      'एकाधिक पंक्तियों या ग्रिड के लिए उपलब्ध है।';

  @override
  String get homeStyleNeedsLabels =>
      'लेबल को उनका आकार और रंग बदलने के लिए सक्षम करें।';

  @override
  String get homeStyleNeedsAllLabels =>
      'स्थिति केवल सभी कार्डों पर लेबल पर लागू होती है। चयनित शीर्षक अनुभाग के नीचे रहता है.';

  @override
  String get homeStyleNeedsScale => 'इज़ाफ़ा फ़ोकस प्रभाव का चयन करें.';

  @override
  String get homeStyleNeedsLift => 'लिफ्ट फोकस प्रभाव का चयन करें.';

  @override
  String get homeStyleNeedsBorder => 'पहले एक रूपरेखा या चमक सक्षम करें।';

  @override
  String get homeStyleNeedsTitle =>
      'अनुभाग शीर्षक को उसका आइकन दिखाने के लिए सक्षम करें.';

  @override
  String get homeStyleEconomy =>
      'स्मृति बचत के कारण अक्षम किया गया. सहेजा गया मान बरकरार रखा जाता है.';

  @override
  String get homeStyleOpaque =>
      'धुंधलापन देखने के लिए टाइल पृष्ठभूमि की अपारदर्शिता कम करें।';

  @override
  String get homeStyleOverridden =>
      'दृश्यमान अनुभाग अपने स्वयं के मूल्यों का उपयोग करते हैं। इस सेटिंग को लागू करने के लिए किसी अनुभाग में \"वैश्विक उपयोग करें\" चुनें।';

  @override
  String get homeStyleIconHint =>
      'आइकन का आकार ऐप आइकन वाले कार्ड को प्रभावित करता है। टीवी बैनर स्वतंत्र रूप से कार्ड भरते हैं।';

  @override
  String get homeStyleShadowHint =>
      'मेमोरी सेविंग निष्क्रिय कार्डों की छाया को 4 तक सीमित करती है। फोकस छाया को अलग से कॉन्फ़िगर किया गया है।';

  @override
  String get homeStyleTransparent =>
      'पृष्ठभूमि का रंग शून्य अपारदर्शिता पर अदृश्य है। टाइल पृष्ठभूमि अपारदर्शिता बढ़ाएँ.';

  @override
  String get homeStyleSingleColumn =>
      'एकल-स्तंभ ग्रिड में कोई क्षैतिज अंतराल नहीं होता है।';

  @override
  String get homeStyleAutoOnly =>
      'आकार केवल ऑटो कार्ड गणना वाले अनुभागों में बदलता है जो वैश्विक आकार को प्राप्त करते हैं।';

  @override
  String get sleepTimerThirtySeconds => '30 सेकंड (परीक्षण)';

  @override
  String get sleepTimer => 'नींद का टाइमर';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes मि';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours घंटे',
      one: '1 घंटा',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1.5 घंटे';

  @override
  String get sleepTimerAllowExact => 'सटीक टाइमर की अनुमति दें';

  @override
  String get sleepTimerExactRequired =>
      'Android सेटिंग्स में सटीक टाइमर की अनुमति दें, फिर एक अवधि फिर से चुनें।';

  @override
  String get sleepTimerAccessRequired =>
      'CuteLauncher पहुंच सक्षम करें या सेटिंग्स → अन्य → ADB में स्थानीय ADB कनेक्ट करें।';

  @override
  String get sleepTimerFailed =>
      'स्लीप टाइमर सेट या पूरा नहीं किया जा सका. पहुंच और स्थानीय ADB की जाँच करें।';

  @override
  String get nightIgnoreHdmiInputs => 'HDMI इनपुट पर ध्यान न दें';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'HDMI देखते समय रात्रि फ़िल्टर रोकें। उपयोग पहुंच आवश्यक है; इनपुट डिटेक्शन टीवी फर्मवेयर पर निर्भर करता है।';

  @override
  String get inputsSettings => 'इनपुट सेटिंग्स';

  @override
  String get inputsUseCecNames => 'CEC से डिवाइस नामों का उपयोग करें';

  @override
  String get inputsNamesHint =>
      'नाम प्राथमिकता: CuteLauncher में आपका नाम → CEC (यदि सक्षम है) → Android सेटिंग्स से नाम → मानक इनपुट नाम।';

  @override
  String get inputNameHint => 'स्वचालित नाम के लिए खाली छोड़ें';

  @override
  String get inputsSaveFailed => 'इनपुट सेटिंग्स सहेजी नहीं जा सकीं';

  @override
  String get inputIcon => 'इनपुट आइकन';

  @override
  String get inputIconTv => 'टी.वी';

  @override
  String get inputIconGame => 'गेम कंसोल';

  @override
  String get inputIconComputer => 'कंप्यूटर';

  @override
  String get inputIconReceiver => 'रिसीवर';

  @override
  String get inputIconDisc => 'डिस्क प्लेयर';

  @override
  String get inputIconStream => 'स्ट्रीमिंग डिवाइस';

  @override
  String get nightInputExclusions => 'इनपुट बहिष्करण';

  @override
  String get nightSelectInputs => 'अनदेखा करने के लिए इनपुट का चयन करें';

  @override
  String get nightNoInputsSelected =>
      'कोई इनपुट चयनित नहीं. फ़िल्टर हर इनपुट पर लागू होगा.';

  @override
  String get nightPictureExclusions => 'चित्र मोड बहिष्करण';

  @override
  String get nightPictureExclusionsHint =>
      'ऐसे मोड चुनें जो डिमिंग, वार्म ओवरले और लिंक किए गए TCL फ़िल्टर को रोकते हैं। शेड्यूल सुरक्षित रखा गया है. TCL पर जांच सत्यापित की गई है; उपयोग पहुंच की आवश्यकता नहीं है.';

  @override
  String get nightPictureUnavailable =>
      'इस फ़र्मवेयर पर वर्तमान चित्र मोड उपलब्ध नहीं है। आपका चयन सहेजा गया है; बहिष्करण तभी लागू होते हैं जब पता लगाना सफल हो जाता है।';

  @override
  String get nightPictureCurrent => 'वर्तमान मोड';

  @override
  String get nightPictureRefresh => 'वर्तमान मोड ताज़ा करें';

  @override
  String get nightPictureCode => 'मोड कोड';

  @override
  String get nightPictureStandard => 'मानक';

  @override
  String get nightPictureDynamic => 'गतिशील';

  @override
  String get nightPictureMovie => 'चलचित्र';

  @override
  String get nightPictureSport => 'खेल';

  @override
  String get nightPictureIntelligent => 'बुद्धिमान';

  @override
  String get nightPictureBright => 'उज्ज्वल (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'मानक';

  @override
  String get systemApplications => 'सिस्टम ऐप्स';

  @override
  String get removeFromCategory => 'श्रेणी से हटाएँ';

  @override
  String get noRemovableCategories =>
      'इस ऐप को किसी भी अनुभाग में मैन्युअल रूप से नहीं जोड़ा गया है। स्वचालित अनुभाग संपादित नहीं किए जा सकते.';

  @override
  String get remoteButtonsTitle => 'रिमोट बटन रीमैपर';

  @override
  String get remoteButtonsStart => 'बटन जाँचें (120 सेकंड)';

  @override
  String get remoteButtonsStop => 'जाँच रोकें';

  @override
  String get remoteButtonsHint =>
      'जाँच कोड, छोड़ने और दोहराव दिखाती है और टीवी पर टेक्स्ट रिपोर्ट सहेजती है। शुरू करने के बाद इस पेज से बाहर निकलें ताकि OK रिकॉर्डिंग को नियंत्रित न करे।';

  @override
  String get remoteButtonsEmpty =>
      'अभी कोई ईवेंट नहीं है। यदि कोई बटन ऐप खोलता है, तो परिणाम देखने के लिए यहाँ लौटें।';

  @override
  String get remoteButtonsService => 'सेवा जुड़ी हुई है';

  @override
  String get remoteButtonsRefresh => 'रीफ़्रेश करें';

  @override
  String get remoteBindings => 'बटन के कार्य';

  @override
  String get remoteMappingsEnabled => 'रीमैपिंग चालू करें';

  @override
  String get remoteMappingsAdd => 'कार्य जोड़ें';

  @override
  String get remoteMappingKey => 'बटन';

  @override
  String get remoteMappingAction => 'कार्य';

  @override
  String get remoteMappingLearn => 'रिमोट बटन पहचानें';

  @override
  String get remoteMappingLearnHint =>
      '30 सेकंड के भीतर अतिरिक्त बटन दबाएँ। नेविगेशन, Power, वॉइस सर्च और वॉल्यूम सुरक्षित हैं।';

  @override
  String get remoteMappingsHint =>
      'बटन के कार्यों के लिए सुलभता सेवा चाहिए। संपादक और जाँच में वे रुके रहते हैं। Home, Back, तीर और OK से सामान्य नेविगेशन होता है।';

  @override
  String get remoteMappingsReset => 'बटन के कार्य रीसेट करें';

  @override
  String get remoteMappingsResetConfirm =>
      'सभी बटन के कार्य मिटाकर रीमैपिंग बंद करें?';

  @override
  String get remoteMappingInvalid =>
      'सहेजा नहीं जा सका। बटन और लक्ष्य जाँचें। Webhook के लिए HTTPS या स्थानीय नेटवर्क पर HTTP चाहिए।';

  @override
  String get remoteMappingBack => 'वापस';

  @override
  String get remoteMappingProfile => 'प्रोफ़ाइल';

  @override
  String get remoteMappingChannels => 'चैनल';

  @override
  String get remoteMappingQuickSettings => 'TCL त्वरित सेटिंग';

  @override
  String get remoteMappingTrigger => 'दबाने का प्रकार';

  @override
  String get remoteMappingPress => 'थोड़ी देर दबाएँ';

  @override
  String get remoteMappingHold => 'दबाकर रखें';

  @override
  String get remoteMappingHoldHint =>
      '650 मिलीसेकंड दबाएँ: केवल एक बार कार्य होगा, छोटा दबाव नहीं। केवल होल्ड तय होने पर छोटा दबाव कुछ नहीं करता।';

  @override
  String get remotePanel => 'फ़्लोटिंग पैनल';

  @override
  String get remotePanelSettingsBackground =>
      'सेटिंग के पृष्ठभूमि रंग का उपयोग करें';

  @override
  String get remotePanelPreview => 'पैनल खोलें';

  @override
  String get settingsHelp => 'अधिक जानकारी';

  @override
  String get settingsHelpScroll => '▲ / ▼ — पाठ स्क्रॉल करें';

  @override
  String get panelClockStyle => 'घड़ी का रूप';

  @override
  String get clockPreset => 'घड़ी की शैली';

  @override
  String get clockCustom => 'कस्टम';

  @override
  String get clockWeight => 'फ़ॉन्ट की मोटाई';

  @override
  String get clockGlow => 'टेक्स्ट की चमक';

  @override
  String get clockAnimate => 'अंकों का ऐनिमेशन';

  @override
  String get clockBackground => 'घड़ी की पृष्ठभूमि';

  @override
  String get clockRadius => 'पृष्ठभूमि के कोनों का घुमाव';

  @override
  String get dateCalendarEnabled => 'तारीख दबाने पर कैलेंडर खोलें';

  @override
  String get calendarTitle => 'कैलेंडर';

  @override
  String get dateSettings => 'तारीख की सेटिंग';

  @override
  String get clockSharedBackground => 'अन्य वस्तुओं जैसी पृष्ठभूमि';

  @override
  String get clockDefaultBackground => 'डिफ़ॉल्ट पृष्ठभूमि';

  @override
  String get remotePanelInheritAppearance => 'ऊपरी पैनल का रूप इस्तेमाल करें';

  @override
  String get remotePanelDisabledInLauncher =>
      'CuteLauncher स्क्रीन पर खुला होने पर पॉप-अप पैनल बंद है।';

  @override
  String get remoteAccessSettings => 'ऐक्सेस सेटिंग';

  @override
  String get remoteButtonsTest => 'बटन की जाँच';

  @override
  String get remoteMappingConflict =>
      'यह बटन और दबाने का प्रकार पहले से असाइन है। दूसरा बटन या दबाने का प्रकार चुनें।';

  @override
  String get cleanerTitle => 'TV cleanup manager';

  @override
  String get cleanerRefresh => 'Refresh applications';

  @override
  String get cleanerSnapshot => 'Save original state';

  @override
  String get cleanerRestore => 'Restore manager changes';

  @override
  String get cleanerSnapshotSaved => 'Original state saved';

  @override
  String get cleanerExportSnapshot => 'Export original state';

  @override
  String get cleanerSafe => 'Disable verified applications';

  @override
  String get cleanerNoSafe =>
      'This firmware has no verified list that preserves all features.';

  @override
  String get cleanerLocal => 'Disable using a local list';

  @override
  String get cleanerProject => 'Project catalog lists';

  @override
  String get cleanerRemoteProject => 'Refresh catalog from GitHub';

  @override
  String get cleanerExternal => 'CleanYourTV examples';

  @override
  String get cleanerDisabledExport => 'Export disabled applications';

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
      'The manager uses the local ADB connection configured in TV control settings. It never uninstalls apps or clears their data. The snapshot and recovery journal are separate from ordinary backups. Recovery restores previous states only for packages changed by this manager. Automatic recovery is blocked after a firmware change.\n\nVerified lists match exact firmware. Observed and external lists do not establish safety. Protected components, HOME and active services cannot be disabled. Packages are previewed before applying; missing and already disabled packages are skipped.\n\nThe project catalog is bundled from Git. GitHub refresh requires a public catalog. External examples load only on request and never execute scripts. Export creates JSON containing disabled packages and firmware identity; add it manually to catalog/examples after review. Nothing is uploaded automatically.\n\nApp descriptions and risk remain visible. Unconfirmed purposes are marked explicitly and never included in verified lists.';

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
}
