// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

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
  String get adbWifiOwnedTitle => 'WLAN gehört dem Einrichtungsassistenten';

  @override
  String get adbWifiOwned =>
      'Keine Änderungen: Ein gespeichertes WLAN wurde vom Google-Einrichtungsassistenten erstellt. Seine Deaktivierung kann das Netzwerk löschen und den Fernseher vom Internet trennen.\n\n1. Halten Sie das WLAN-Passwort bereit.\n2. Öffnen Sie die Android-Netzwerkeinstellungen, wählen Sie das Netzwerk und „Netzwerk vergessen“.\n3. Verbinden Sie sich dort erneut.\n4. Kehren Sie zu CuteLauncher zurück, prüfen Sie ADB und versuchen Sie erneut, den integrierten Launcher zu deaktivieren.\n\nErscheint die Meldung erneut, lassen Sie den integrierten Launcher aktiviert: Die Firmware kann das Netzwerk wieder dem Assistenten zuordnen.';

  @override
  String get adbWifiUnknown =>
      'Not changed: the owners of saved Wi-Fi networks could not be verified. Disabling the setup wizard is blocked to protect your connection. Check ADB and try again; some firmware does not provide this information.';

  @override
  String get backgroundSource => 'Hintergrundquelle';

  @override
  String get noAvailableCategories =>
      'Es sind keine Abschnitte verfügbar, zu denen diese App hinzugefügt werden kann.';

  @override
  String get redditWallpaperTheme => 'Tapetenthema';

  @override
  String get redditThemeAll => 'Gemischt';

  @override
  String get redditThemeNature => 'Natur';

  @override
  String get redditThemeSpace => 'Raum';

  @override
  String get redditThemeCity => 'Städte';

  @override
  String get redditThemeMinimal => 'Minimalismus';

  @override
  String get redditWallpaperResolution => 'Mindestauflösung';

  @override
  String get redditWallpaperHint =>
      'Bei jeder erfolgreichen Aktualisierung wird ein anderes Querformatbild aus der ausgewählten Reddit-Community heruntergeladen. Die Auflösung ist die minimale Originalgröße; Bilder werden nicht hochskaliert. Die Aktualisierung wird ausgeführt, während der Launcher geöffnet ist, und wird fortgesetzt, wenn Sie zurückkehren. Inhalte, Videos und Galerien für Erwachsene werden übersprungen. Wenn Reddit den Zugriff blockiert oder kein passendes Bild gefunden wird, bleibt das vorherige Hintergrundbild bestehen.';

  @override
  String get dialogCommandDetails => 'ADB-Befehle anzeigen';

  @override
  String get dialogAssign => 'Zuweisen';

  @override
  String get dialogApply => 'Bewerben';

  @override
  String get settingsValueNotSet => 'Nicht festgelegt';

  @override
  String get settingsMenuPosition => 'Position des Einstellungsmenüs';

  @override
  String get settingsMenuLeft => 'Links';

  @override
  String get settingsMenuRight => 'Richtig';

  @override
  String get actionCompleted => 'Aktion abgeschlossen';

  @override
  String get showRepositoryQrCode => 'QR-Code anzeigen';

  @override
  String get resetSections => 'Abschnittseinstellungen zurücksetzen';

  @override
  String get resetSectionsConfirmation =>
      'Standardabschnitte wiederherstellen? Benutzerdefinierte Abschnitte, Abstandshalter und Favoriteninhalte werden entfernt.';

  @override
  String get cardFocusMode =>
      'Konzentrieren Sie sich auf die Rückkehr nach Hause';

  @override
  String get cardFocusRemember => 'Ausgewählte Karte behalten';

  @override
  String get cardFocusFirst => 'Erste Karte';

  @override
  String get cardFocusSettings => 'Schaltfläche „Einstellungen“.';

  @override
  String get aboutFlauncher => 'Über CuteLauncher';

  @override
  String get addCategory => 'Kategorie hinzufügen';

  @override
  String get addSection => 'Abschnitt hinzufügen';

  @override
  String get alphabetical => 'Alphabetisch';

  @override
  String get appCardHighlightAnimation => 'App-Karten-Hervorhebungsanimation';

  @override
  String get appInfo => 'App-Info';

  @override
  String get appKeyClick => 'Klickgeräusch bei Tastendruck';

  @override
  String get applications => 'Anwendungen';

  @override
  String get autoHideAppBar => 'Statusleiste automatisch ausblenden';

  @override
  String get backButtonAction => 'Aktion der Zurücktaste';

  @override
  String get category => 'Kategorie';

  @override
  String get categories => 'Kategorien';

  @override
  String get columnCount => 'Spaltenanzahl';

  @override
  String get date => 'Datum';

  @override
  String get dateAndTimeFormat => 'Datums- und Zeitformat';

  @override
  String get delete => 'Löschen';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'Nichts tun';

  @override
  String get dialogOptionBackButtonActionShowScreensaver =>
      'Bildschirmschoner anzeigen';

  @override
  String get dialogOptionBackButtonActionShowClock => 'Uhr anzeigen';

  @override
  String get dialogTextNoFileExplorer =>
      'Bitte installieren Sie einen Dateimanager, um ein Bild auszuwählen.';

  @override
  String get dialogTitleBackButtonAction => 'Aktion der Zurücktaste wählen';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (Kategorie)';
  }

  @override
  String formattedDate(String dateString) {
    return 'Formatiertes Datum: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'Formatierte Zeit: $timeString';
  }

  @override
  String get gradient => 'Farbverlauf';

  @override
  String get favoriteApps => 'Lieblings-Apps';

  @override
  String get grid => 'Raster';

  @override
  String get height => 'Höhe';

  @override
  String get hide => 'Ausblenden';

  @override
  String get hiddenApplications => 'Ausgeblendete Apps';

  @override
  String get launcherSections => 'Abschnitte';

  @override
  String get layout => 'Layout';

  @override
  String get loading => 'Wird geladen';

  @override
  String get manual => 'Manuell';

  @override
  String get modifySection => 'Abschnitt ändern';

  @override
  String get mustNotBeEmpty => 'Darf nicht leer sein';

  @override
  String get name => 'Name';

  @override
  String get newSection => 'Neuer Abschnitt';

  @override
  String get noDateFormatSpecified => 'Kein Datumsformat angegeben';

  @override
  String get noTimeFormatSpecified => 'Kein Zeitformat angegeben';

  @override
  String get nonTvApplications => 'Nicht-TV-Apps';

  @override
  String get open => 'Öffnen';

  @override
  String get orSelectFormatSpecifiers => 'Oder Formatbezeichner auswählen';

  @override
  String get openImage => 'Datei auswählen';

  @override
  String get picture => 'Lokales Bild oder Video';

  @override
  String removeFrom(String name) {
    return 'Entfernen aus $name';
  }

  @override
  String get renameCategory => 'Kategorie umbenennen';

  @override
  String get reorder => 'Neu anordnen';

  @override
  String get row => 'Zeile';

  @override
  String get rowHeight => 'Zeilenhöhe';

  @override
  String get save => 'Speichern';

  @override
  String get spacer => 'Abstandshalter';

  @override
  String get spacerMaxHeightRequirement =>
      'Muss größer als 0 und kleiner oder gleich 500 sein';

  @override
  String get statusBar => 'Statusleiste';

  @override
  String get settings => 'Einstellungen';

  @override
  String get show => 'Anzeigen';

  @override
  String get showCategoryTitles => 'Kategorietitel anzeigen';

  @override
  String get themes => 'Designs';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'Hervorhebungskontur auf dem Startbildschirm ausblenden';

  @override
  String get appSelectorTransitionAnimation => 'App-Auswahl-Übergangsanimation';

  @override
  String get sort => 'Sortieren';

  @override
  String get systemSettings => 'Systemeinstellungen';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => 'Diese Kategorie ist leer.';

  @override
  String get time => 'Zeit';

  @override
  String get titleStatusBarSettingsPage =>
      'Wählen Sie aus, was in der Statusleiste angezeigt werden soll';

  @override
  String get tvApplications => 'TV-Apps';

  @override
  String get type => 'Typ';

  @override
  String get typeInTheDateFormat => 'Datumsformat eingeben';

  @override
  String get typeInTheHourFormat => 'Zeitformat eingeben';

  @override
  String get uninstall => 'Deinstallieren';

  @override
  String get wallpaper => 'Hintergrundbild';

  @override
  String get withEllipsisAddTo => 'Hinzufügen zu...';

  @override
  String get timeBasedWallpaper => 'Tag-/Nachtbild';

  @override
  String get pickDayWallpaper => 'Tagbild auswählen';

  @override
  String get pickNightWallpaper => 'Nachtbild auswählen';

  @override
  String get accessibility => 'Barrierefreiheit';

  @override
  String get defaultLauncherIsDefault =>
      'CuteLauncher ist der Standard-Launcher';

  @override
  String get defaultLauncherNotDefault =>
      'CuteLauncher ist nicht der Standard-Launcher';

  @override
  String get setAsDefaultLauncher => 'Als Standard-Launcher festlegen';

  @override
  String get defaultLauncherDescription =>
      'Wenn als Standard-Launcher festgelegt, kehrt die Home-Taste immer zu CuteLauncher zurück. Der TV bootet ebenfalls direkt in CuteLauncher.';

  @override
  String get inputs => 'Eingänge';

  @override
  String get inputsUnavailableHint =>
      'Dieses Gerät bietet keine verfügbaren Eingänge. Der Schalter ist deaktiviert und das Symbol ist ausgeblendet. Bei einer TV-Box steuert diese Option nicht die HDMI-Eingänge des angeschlossenen Fernsehers.';

  @override
  String get inputSources => 'Eingabequellen';

  @override
  String get backupAndRestore => 'Sichern & Wiederherstellen';

  @override
  String get exportBackup => 'Sicherung exportieren';

  @override
  String get importBackup => 'Sicherung importieren';

  @override
  String exportSuccess(String path) {
    return 'Sicherung erfolgreich exportiert nach $path';
  }

  @override
  String get importSuccess => 'Sicherung erfolgreich importiert';

  @override
  String get importConfirm =>
      'Möchten Sie die Sicherung wirklich importieren? Dies wird Ihre aktuellen Einstellungen und Ihr Layout überschreiben.';

  @override
  String get importError =>
      'Die Einstellungen konnten aus der Sicherung nicht wiederhergestellt werden. Überprüfen Sie die Datei und versuchen Sie es erneut.';

  @override
  String exportError(String error) {
    return 'Exportieren der Sicherung fehlgeschlagen: $error';
  }

  @override
  String get shareBackup => 'Sicherung teilen';

  @override
  String get shareBackupDescription =>
      'Sicherung mit anderen Geräten im lokalen Netzwerk teilen';

  @override
  String get stopSharing => 'Teilen beenden';

  @override
  String get localNetworkSharingActive =>
      'Die Freigabe im lokalen Netzwerk ist aktiv!';

  @override
  String get localNetworkSharingInstructions =>
      'Verbinden Sie ein anderes Gerät mit demselben WLAN-Netzwerk und öffnen Sie die folgende URL in einem Webbrowser:';

  @override
  String get localNetworkSharingDetails =>
      'Hier können Sie Ihre TV-Einstellungen/Ihr Layout herunterladen oder eine Sicherungsdatei auf diesen TV hochladen.';

  @override
  String failedToStartServer(String error) {
    return 'Starten des Freigabeservers fehlgeschlagen: $error';
  }

  @override
  String get notificationBell => 'Benachrichtigungsglocke';

  @override
  String get autoHideNotificationBell =>
      'Benachrichtigungsglocke automatisch ausblenden';

  @override
  String get continueWatching => 'Weiterschauen';

  @override
  String get showContinueWatchingOnHome =>
      'Weiterschauen auf dem Startbildschirm anzeigen';

  @override
  String get permissionDeniedContinueWatching =>
      'Berechtigung erforderlich, um Weiterschauen anzuzeigen';

  @override
  String get interface => 'Oberfläche';

  @override
  String get system => 'System';

  @override
  String get accentColor => 'Akzentfarbe';

  @override
  String get miscellaneous => 'Sonstiges';

  @override
  String get brightnessScheduler => 'Helligkeitsplaner';

  @override
  String get screensaverSettings => 'Bildschirmschoner-Einstellungen';

  @override
  String get screensaverClockStyle => 'Bildschirmschoner-Uhrstil';

  @override
  String get dataUsagePeriod => 'Datennutzungszeitraum';

  @override
  String get notificationAccess => 'Benachrichtigungszugriff';

  @override
  String get granted => 'Gewährt';

  @override
  String get permissionRequired => 'Berechtigung erforderlich';

  @override
  String get systemWidePopupAlert => 'Systemweite Popup-Warnung';

  @override
  String get overlayPermissionRequired => 'Overlay-Berechtigung erforderlich';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get showAppNamesBelowIcons => 'App-Namen unter Symbolen anzeigen';

  @override
  String get dataUsage => 'Datennutzung';

  @override
  String get networkIndicator => 'Netzwerkindikator';

  @override
  String get homeButtonFix => 'Home-Taste-Fix (Google TV)';

  @override
  String get startOnBoot => 'Beim Einschalten starten (Google TV / Fire TV)';

  @override
  String get appLanguage => 'Sprache';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get english => 'Englisch';

  @override
  String get spanish => 'Spanisch';

  @override
  String get ukrainian => 'Ukrainisch';

  @override
  String get chinese => 'Chinesisch';

  @override
  String get french => 'Französisch';

  @override
  String get german => 'Deutsch';

  @override
  String get japanese => 'Japanisch';

  @override
  String get portuguese => 'Portugiesisch';

  @override
  String get russian => 'Russisch';

  @override
  String get italian => 'Italienisch';

  @override
  String get hindi => 'Hindi';

  @override
  String get korean => 'Koreanisch';

  @override
  String get arabic => 'Arabisch';

  @override
  String get turkish => 'Türkisch';

  @override
  String get hidePersistentNotifications =>
      'Dauerhafte Benachrichtigungen ausblenden';

  @override
  String get hidePersistentNotificationsDesc =>
      'Hintergrunddienst- und Systembenachrichtigungen ausblenden';

  @override
  String get blockedNotificationApps => 'Blockierte Apps';

  @override
  String get blockAppNotifications => 'Benachrichtigungen blockieren';

  @override
  String get unblockAppNotifications => 'Benachrichtigungen freigeben';

  @override
  String get noBlockedApps => 'Keine blockierten Apps';

  @override
  String get persistentNotification => 'Dauerhaft';

  @override
  String get unblockAll => 'Alle freigeben';

  @override
  String get weather => 'Wetter';

  @override
  String get showWeatherWarnings => 'Wetter- & Regenwarnungen anzeigen';

  @override
  String get temperatureUnit => 'Temperatureinheit';

  @override
  String get celsius => 'Celsius (°C)';

  @override
  String get fahrenheit => 'Fahrenheit (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Installieren Sie Breezy Weather und aktivieren Sie \'Lokale Datenfreigabe\' / \'Gadgetbridge\' in den Einstellungen, um Wetter und Regenwarnungen anzuzeigen.';

  @override
  String get displayAndScreensaver => 'Display & Bildschirmschoner';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get continueWatchingDescription =>
      'Zuletzt angesehene Filme und Serien von unterstützten Apps auf dem Startbildschirm anzeigen';

  @override
  String get continueWatchingPermissionDesc =>
      'Zum Lesen des Wiedergabeverlaufs von TV-Apps ist eine spezielle Berechtigung erforderlich:';

  @override
  String get requestPermission => 'Berechtigung anfordern';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get openApp => 'Öffnen';

  @override
  String get notificationOptions => 'Benachrichtigungsoptionen';

  @override
  String get noBlockedAppsDesc =>
      'Alle Apps dürfen derzeit Benachrichtigungen anzeigen';

  @override
  String get notificationsAllowed => 'Benachrichtigungen erlaubt';

  @override
  String get notificationsBlocked => 'Benachrichtigungen blockiert';

  @override
  String get dpadDismissHint => 'Links: Verwerfen • OK: Optionen';

  @override
  String get watchNextDeleteError =>
      'Das Element konnte nicht aus „Weiter ansehen“ entfernt werden. Versuchen Sie es erneut.';

  @override
  String get hideLauncherTile => 'CuteLauncher im App-Raster ausblenden';

  @override
  String get hideAndroidSettingsTile =>
      'Android-Einstellungen in App-Kacheln ausblenden';

  @override
  String get animateTileReordering =>
      'Animieren Sie die Neuordnung der Kacheln';

  @override
  String get imageInputRejected =>
      'Dieses Bild ist beschädigt oder zu groß (maximal 8 MiB und 48 Megapixel). Wählen Sie ein anderes Bild.';

  @override
  String get memoryTitle => 'Erinnerung';

  @override
  String get memoryRefresh => 'Gedächtnis messen';

  @override
  String get memoryMeasuring => 'Messen…';

  @override
  String get memoryClear => 'Bildcaches löschen';

  @override
  String get memorySaver => 'Speichersparend';

  @override
  String get memorySaverDescription =>
      'Speichersparmodus:\n\n• Reduziert Bildcaches und das Fenster zum Vorladen von Postern.\n• Deaktiviert die Hintergrundunschärfe von Kacheln, Bedienfeldern und Hintergrundbildern sowie das Pulsieren von Umrissen.\n• Begrenzt Schatten auf nicht fokussierten Kacheln.\n• Löscht Caches, wenn die App in den Hintergrund geht.\n\nDiese Effekte sind in den Einstellungen nicht verfügbar, solange die Speicherspeicherung aktiviert ist. Ihre gespeicherten Werte kehren zurück, wenn der Modus deaktiviert wird. Bilder werden möglicherweise häufiger neu geladen.';

  @override
  String get memoryPss => 'Prozessanteil (PSS)';

  @override
  String get memoryRss => 'Residenter Prozessspeicher (RSS)';

  @override
  String get memoryEncodedCache => 'Zwischengespeicherte Bilddateien';

  @override
  String get memoryDecodedCache => 'Zwischengespeicherte dekodierte Bilder';

  @override
  String get memoryUnavailable => 'Nicht verfügbar';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => 'Gemessen bei';

  @override
  String get memoryExplanation =>
      'PSS und RSS überschneiden sich: Addieren Sie sie nicht. Cache-Größen sind Teil des App-Speichers und beschreiben nicht den gesamten Speicher, der von aktiven Bildern belegt wird. Durch das Löschen von Caches bleiben Ihre Einstellungen und Dateien erhalten. Bilder werden bei Bedarf erneut geladen. Android gibt möglicherweise später Speicher zurück. RSS kommt hier vom Kernel und PSS von Android; Sie berücksichtigen den Grafikspeicher möglicherweise unterschiedlich.';

  @override
  String get memoryRecommendations =>
      'Um weniger Speicherplatz zu benötigen, aktivieren Sie das Speichern, zeigen Sie weniger Karten weiter an und verwenden Sie kleinere Hintergrundbilder oder einen Farbverlauf.';

  @override
  String get memoryMeasurementFailed =>
      'Die Prozessmessung ist nicht verfügbar. Cache-Informationen werden weiterhin angezeigt.';

  @override
  String get addToCategory => 'Zur Kategorie hinzufügen';

  @override
  String get addToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get removeFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get setCustomBanner => 'Legen Sie ein benutzerdefiniertes Banner fest';

  @override
  String get clearCustomBanner => 'Benutzerdefiniertes Banner löschen';

  @override
  String get bannerSetFailed =>
      'Das Banner konnte nicht eingestellt werden. Überprüfen Sie den Zugriff auf das Bild und wählen Sie die Datei erneut aus.';

  @override
  String get bannerClearFailed =>
      'Das benutzerdefinierte Banner konnte nicht entfernt werden. Versuchen Sie es erneut.';

  @override
  String get grantUsagePermission => 'Nutzungserlaubnis erteilen';

  @override
  String get removeFromContinueWatching => 'Aus „Weiter ansehen“ entfernen';

  @override
  String hideAllFromApp(String appName) {
    return 'Alles vor $appName ausblenden';
  }

  @override
  String get playResume => 'Abspielen / Fortsetzen';

  @override
  String openNamedApp(String appName) {
    return 'Öffnen Sie $appName';
  }

  @override
  String get selectedAccent => 'Ausgewählter Akzent';

  @override
  String get homeButtonFixHint =>
      'Wenn Sie Google TV verwenden, aktivieren Sie „Home Button Fix“ unter den Eingabehilfeneinstellungen, damit der Home-Button diesen Launcher öffnet.';

  @override
  String get accessibilityPermission => 'Barrierefreiheitserlaubnis';

  @override
  String get shareFailed => 'Teilen fehlgeschlagen';

  @override
  String shareBackupError(String error) {
    return 'Backup konnte nicht geteilt werden: $error';
  }

  @override
  String get exportComplete => 'Erfolg exportieren';

  @override
  String get exportFailed =>
      'Das Backup konnte nicht gespeichert werden. Überprüfen Sie den Ordnerzugriff und den verfügbaren Speicher.';

  @override
  String backupLoadError(String error) {
    return 'Fehler beim Laden der Backups: $error';
  }

  @override
  String get noBackupFiles => 'Keine Sicherungsdateien gefunden.';

  @override
  String get importComplete => 'Erfolg importieren';

  @override
  String get importFailed => 'Import fehlgeschlagen';

  @override
  String get importAction => 'Importieren';

  @override
  String get continueWatchingApps => 'Schauen Sie sich weiterhin Apps an';

  @override
  String get blockedContinueWatching => 'Für die weitere Wiedergabe gesperrt';

  @override
  String get allAppsCanContinueWatching =>
      'Alle unterstützten Apps können Elemente in „Weiter ansehen“ anzeigen.';

  @override
  String get unblockApp => 'Entsperren';

  @override
  String get unblockAllApps => 'Entsperren Sie alle Apps';

  @override
  String get appsWithContinueWatching => 'Apps mit Weiterschauen';

  @override
  String get watchNextAppsHint =>
      'Apps, die derzeit „Nächstes ansehen“-Elemente auf Ihrem Startbildschirm bereitstellen';

  @override
  String get noWatchNextApps =>
      'Derzeit bieten keine Apps „Weiter ansehen“-Elemente an.\nWenn unterstützte Apps (wie SmartTube oder Streaming-Dienste) Elemente hinzufügen, werden diese hier angezeigt.';

  @override
  String get allInstalledApps => 'Alle installierten Apps';

  @override
  String get blockWatchNextHint =>
      'Deaktivieren Sie die Option, um zu verhindern, dass Apps Elemente zu „Weiter ansehen“ hinzufügen';

  @override
  String get cardSize => 'Kartengröße';

  @override
  String get maximumItems => 'Maximale Anzahl an Artikeln';

  @override
  String get playbackProgressBar => 'Wiedergabe-Fortschrittsbalken';

  @override
  String get playbackPercentage => 'Wiedergabeprozentsatz';

  @override
  String get episodeVideoDetails => 'Episoden- und Videodetails';

  @override
  String get restoreHiddenPrograms => 'Versteckte Programme wiederherstellen';

  @override
  String get allHiddenProgramsRestored =>
      'Alle versteckten Programme wiederhergestellt';

  @override
  String get watchNextAccessAdb =>
      'Nächsten Zugriff ansehen (ADB erforderlich)';

  @override
  String get supportLtvLauncher => 'Unterstützt LTvLauncher';

  @override
  String get scanToDonate =>
      'Scannen Sie mit Ihrer Telefonkamera, um zu spenden:';

  @override
  String get openInBrowser => 'Im Browser öffnen';

  @override
  String get close => 'Schließen';

  @override
  String get launcherAuthor => 'CuteLauncher von Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Android TV Launcher basierend auf LTvLauncher von LeanBitLab und FLauncher von Étienne Fesser. Lizenziert unter GNU GPLv3.';

  @override
  String get projectCredits => 'Projekt & Credits';

  @override
  String get launcherRepository => 'CuteLauncher-Repository';

  @override
  String get originalProject => 'Ursprüngliches Projekt: LTvLauncher';

  @override
  String get noInputsDetected => 'Keine Eingaben erkannt';

  @override
  String get reorderSectionsHint =>
      'Mit ◄ / ► auswählen und dann mit ▲ / ▼ neu anordnen. Überqueren Sie die Listengrenze, um einen Abschnitt auszublenden oder anzuzeigen.';

  @override
  String get customName => 'Benutzerdefinierter Name';

  @override
  String get mostUsed => 'Startfrequenz';

  @override
  String get lastUsed => 'Zuletzt verwendet';

  @override
  String get clearAll => 'Alles löschen';

  @override
  String get allCaughtUp => 'Alles aufgeholt!';

  @override
  String get notificationAccessAdb =>
      'Benachrichtigungszugriff (ADB erforderlich)';

  @override
  String get openAppInfo => 'Öffnen Sie App-Info';

  @override
  String get overlayPermission => 'Overlay-Berechtigung';

  @override
  String get clockMinimal => 'Minimal';

  @override
  String get clockMinimalDescription => 'Dünne, elegante Schriftart (Standard)';

  @override
  String get clockBold => 'Fett';

  @override
  String get clockBoldDescription => 'Dicke, gut sichtbare Schriftart';

  @override
  String get clockRetro => 'Retro';

  @override
  String get clockRetroDescription => 'Monospaced, Retro-Terminal-Stil';

  @override
  String get clockElegant => 'Elegant';

  @override
  String get clockElegantDescription => 'Klassische Serifenschrift';

  @override
  String get clockNeon => 'Neon';

  @override
  String get clockNeonDescription => 'Ultradünner, leuchtender Stil';

  @override
  String get clockPixel => 'Pixel';

  @override
  String get clockPixelDescription => 'Mutiges Monospace-Arcade-Feeling';

  @override
  String get clockDigital => 'Digital';

  @override
  String get clockDigitalDescription => 'Sauberes Monospace-Display';

  @override
  String get themeDefault => 'Standard';

  @override
  String get themePremium => 'Premium';

  @override
  String get themeClassic => 'Klassisch';

  @override
  String get themeCapsule => 'Kapsel';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get actionCancelled => 'Aktion abgebrochen';

  @override
  String get ok => 'Okay';

  @override
  String get accessibilityGuide =>
      'Öffnen Sie die TV-Einstellungen manuell, dann Eingabehilfen → CuteLauncher Home Button Fix und aktivieren Sie den Dienst. Der Speicherort und der Name dieses Menüs hängen vom Hersteller Ihres Fernsehgeräts ab.';

  @override
  String get notificationPermissionGuide =>
      'Die Einstellungen für den Benachrichtigungszugriff konnten auf diesem Fernseher nicht geöffnet werden. Durch das Zulassen ausgehender Benachrichtigungen in App Info wird kein Zugriff auf Benachrichtigungen von anderen Apps gewährt.\n\nSchließen Sie Ihren Fernseher über ADB an und führen Sie Folgendes aus:';

  @override
  String get overlayPermissionGuide =>
      'Die Overlay-Berechtigungseinstellungen konnten nicht automatisch geöffnet werden.\n\nUm Popups über anderen Apps zu aktivieren, verbinden Sie Ihren Fernseher über ADB und führen Sie Folgendes aus:';

  @override
  String get watchNextPermissionGuide =>
      'Zum Lesen von Continue Watching-Karten aus anderen Apps ist Android TV READ_WRITE_WATCH_NEXT_PROGRAMS erforderlich.\n\nSchließen Sie Ihren Fernseher über ADB an und führen Sie Folgendes aus:';

  @override
  String get watchNextAccess => 'Weiter ansehen Zugriff';

  @override
  String itemsCount(int count) {
    return '$count Artikel';
  }

  @override
  String displayUpToItems(int count) {
    return 'Zeigt bis zu $count aktuelle Artikel an';
  }

  @override
  String get unlimitedItems => 'Unbegrenzt';

  @override
  String get allAvailableItems => 'Alle verfügbaren Artikel anzeigen';

  @override
  String get defaultOption => 'Standard';

  @override
  String get manage => 'Verwalten';

  @override
  String blockedCount(int count) {
    return '$count blockiert';
  }

  @override
  String hiddenCount(int count) {
    return '$count ausgeblendet';
  }

  @override
  String blockedWatchNextCount(int count) {
    return 'Für die weitere Wiedergabe gesperrt ($count)';
  }

  @override
  String get sizeExtraSmall => 'Extra klein';

  @override
  String get sizeVerySmall => 'Sehr klein';

  @override
  String get sizeSmall => 'Klein';

  @override
  String get sizeCompact => 'Kompakt';

  @override
  String get sizeMediumSmall => 'Mittelklein';

  @override
  String get sizeMedium => 'Mittel';

  @override
  String get sizeStandardDefault => 'Standard (Standard)';

  @override
  String get sizeMediumLarge => 'Mittelgroß';

  @override
  String get sizeLarge => 'Groß';

  @override
  String get sizeVeryLarge => 'Sehr groß';

  @override
  String get sizeExtraLarge => 'Extra groß';

  @override
  String get sizeHuge => 'Riesig';

  @override
  String get tvApps => 'TV-Apps';

  @override
  String get nonTvApps => 'Nicht-TV-Apps';

  @override
  String get moviesShows => 'Filme und Shows';

  @override
  String get music => 'Musik';

  @override
  String get games => 'Spiele';

  @override
  String get entertainment => 'Unterhaltung';

  @override
  String get liveTv => 'Live-TV';

  @override
  String get sports => 'Sport';

  @override
  String get news => 'Nachrichten';

  @override
  String get tools => 'Werkzeuge';

  @override
  String get favorites => 'Favoriten';

  @override
  String get customSectionName => 'Benutzerdefinierte...';

  @override
  String get selectSectionName => 'Wählen Sie einen Namen';

  @override
  String get weeklyUsage => 'Wöchentlich:';

  @override
  String get monthlyUsage => 'Monatlich:';

  @override
  String get dailyUsage => 'Täglich:';

  @override
  String get appError => 'Etwas ist schief gelaufen';

  @override
  String get weatherRain => 'Regen';

  @override
  String get weatherSnow => 'Schnee';

  @override
  String get weatherStorm => 'Sturm';

  @override
  String get weatherToday => 'heute';

  @override
  String get weatherTomorrow => 'morgen';

  @override
  String weatherOnDay(String day) {
    return 'auf $day';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'CuteLauncher-Sicherung';

  @override
  String get noApplicationsFound => 'Keine Anwendungen gefunden';

  @override
  String get invalidDateFormat => 'Ungültiges Format';

  @override
  String get selectDateFormats => 'Wählen Sie unten Formate aus';

  @override
  String activeItemsCount(int count) {
    return '$count aktive Artikel';
  }

  @override
  String get colorPurple => 'Lila';

  @override
  String get colorTeal => 'Blaugrün';

  @override
  String get colorBlue => 'Blau';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPink => 'Rosa';

  @override
  String get colorGreen => 'Grün';

  @override
  String get colorWhite => 'Weiß';

  @override
  String get colorYellow => 'Gelb';

  @override
  String get colorRed => 'Rot';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorLime => 'Limette';

  @override
  String get colorAmber => 'Bernstein';

  @override
  String get colorRose => 'Rose';

  @override
  String get colorIceBlue => 'Eisblau';

  @override
  String get memoryFeatures => 'Speicher nach Funktion (Caches)';

  @override
  String get memoryAppIcons => 'App-Symbole';

  @override
  String get memoryAppBanners => 'App-Banner';

  @override
  String get memoryWatchNextPosters => 'Sehen Sie sich weiterhin Poster an';

  @override
  String get memoryOtherCaches => 'Andere codierte Bildcaches';

  @override
  String get memoryFeaturesExplanation =>
      'Hierbei handelt es sich um beibehaltene Bildbytes, die bereits in der codierten Cache-Gesamtsumme enthalten sind. Null bedeutet, dass sich in diesem Cache keine Bytes befinden, aber nicht, dass die Funktion keinen Speicher benötigt. Hintergrundbilder und angezeigte Bilder teilen sich den oben dekodierten Cache; Aktive Bilder können sich außerhalb davon befinden. Wetter, Benachrichtigungen, Dart-Objekte und die Engine können hier nicht nach Funktionen aufgeteilt werden. Gemeinsam genutzte Schnittstellengrafiken werden oben von Android gemeldet und sind bereits in PSS enthalten. Ihr Gedächtnis ist Teil des Gesamtprozesses. Fügen Sie diese überlappenden Werte nicht hinzu.';

  @override
  String get memoryGraphics => 'Schnittstellengrafiken (im PSS enthalten)';

  @override
  String get categoryVisible => 'Kategorie anzeigen';

  @override
  String get hiddenCategories => 'Versteckte Kategorien';

  @override
  String get visibleCategories => 'Sichtbare Kategorien';

  @override
  String get backupSavedToSelectedLocation =>
      'Backup wird am ausgewählten Ort gespeichert';

  @override
  String get tileHorizontalGap => 'Horizontaler Abstand';

  @override
  String get tileVerticalGap => 'Vertikaler Abstand';

  @override
  String get tileOpacity => 'Hintergrundopazität';

  @override
  String get tileShadow => 'Schatten';

  @override
  String get tileCornerRadius => 'Eckenrundung';

  @override
  String get tileIconScale => 'Symbolgröße';

  @override
  String get tileBackgroundColor => 'Fliesenhintergrund';

  @override
  String get tileLabelSize => 'Etikettengröße';

  @override
  String get resetAppearance => 'Aussehen zurücksetzen';

  @override
  String get tileAppearance => 'Aussehen der Fliesen';

  @override
  String get tileLabelColor => 'Etikettenfarbe';

  @override
  String get tilePreviewName => 'Beispielanwendung';

  @override
  String get tileProportions => 'Fliesenproportionen';

  @override
  String get tileLarge => 'Groß';

  @override
  String get tileLabelBelow => 'Unterhalb der Kachel';

  @override
  String get tileLabelInside => 'Innerhalb der Fliese';

  @override
  String get tileFocusScale => 'Vergrößern';

  @override
  String get tileMedium => 'Mittel';

  @override
  String get tileFocusBorder => 'Keine Bewegung';

  @override
  String get tileSize => 'Fliesengröße';

  @override
  String get tileCompact => 'Kompakt';

  @override
  String get tileLabelPosition => 'Etikettenposition';

  @override
  String get tileFocusEffect => 'Fokuseffekt';

  @override
  String get tileFocusStrength => 'Markieren Sie die Intensität';

  @override
  String get panelIndependent => 'Benutzerdefinierte Einstellungen';

  @override
  String get panelAppearance => 'Top-Panel-Stil';

  @override
  String get panelBackground => 'Panel-Hintergrund';

  @override
  String get blurPerformanceHint =>
      'Unschärfe kann die Glätte beeinträchtigen. Es ist deaktiviert, während die Speicherspeicherung aktiviert ist.';

  @override
  String get panelOpacity => 'Deckkraft des Panels';

  @override
  String get tileBlur => 'Unschärfe hinter Fliesen';

  @override
  String get panelBlur => 'Unschärfe hinter der oberen Platte';

  @override
  String get panelShared => 'Wie Panels';

  @override
  String get weatherMinutes => 'min';

  @override
  String get weatherOpenMeteoCredit =>
      'Wetter: Open-Meteo (open-meteo.com), CC BY 4.0. Kostenloser API für nichtkommerzielle Nutzung.';

  @override
  String get weatherRateLimit =>
      'Anforderungslimit erreicht. Versuchen Sie es später.';

  @override
  String get weatherYandexCredit =>
      'Wetter: Yandex Wetter (yandex.ru/pogoda). Der Zugriff hängt von Ihrem API-Plan ab.';

  @override
  String get yandexWeather => 'Yandex-Wetter (REST)';

  @override
  String get weatherAuthorizationError =>
      'Der Wetteranbieter lehnte die Anfrage ab. Überprüfen Sie den API-Schlüssel und den Zugriff auf den ausgewählten Dienst.';

  @override
  String get weatherYandexHint =>
      'Erfordert einen Schlüssel mit REST-Prognosezugriff. Ein Schlüssel für einen anderen Yandex-Plan funktioniert möglicherweise nicht.';

  @override
  String get weatherSource => 'Wetterquelle';

  @override
  String get weatherInterval => 'Aktualisierungsintervall';

  @override
  String get weatherLongitude => 'Längengrad (-180 bis 180)';

  @override
  String get weatherKeyRequired =>
      'Fügen Sie einen Yandex API-Schlüssel hinzu.';

  @override
  String get weatherLocationName => 'Stadtname (optional)';

  @override
  String get weatherLocation => 'Standort';

  @override
  String get weatherApiKey => 'Yandex API-Schlüssel';

  @override
  String get weatherInvalidResponse =>
      'Die Wetterquelle hat ungültige Daten zurückgegeben.';

  @override
  String get weatherUnavailable =>
      'Wetter ist nicht verfügbar. Zuvor empfangene Daten bleiben, sofern verfügbar, erhalten. Wiederholungsversuche sind auf einmal alle 5 Minuten beschränkt.';

  @override
  String get weatherStale => 'Vorheriges Wetter';

  @override
  String get weatherLatitude => 'Breitengrad (-90 bis 90)';

  @override
  String get weatherCoordinatesError =>
      'Geben Sie eine Stadt manuell ein oder erhalten Sie automatisch Koordinaten.';

  @override
  String get weatherRefresh => 'Suchen Sie nach Updates';

  @override
  String get weatherKeyPrivate =>
      'Nur auf diesem Gerät gespeichert, von Backups ausgeschlossen. Eine leere Eingabe entfernt den Schlüssel.';

  @override
  String get weatherUpdated => 'Aktualisiert';

  @override
  String get onlineWallpaperError =>
      'Dieses Bild kann nicht geladen werden. Das vorherige Hintergrundbild bleibt erhalten. Wählen Sie „Nach Updates suchen“, um den Download erneut zu versuchen.';

  @override
  String get onlineWallpaperHint =>
      'Das zuletzt geladene Bild bleibt auch ohne Internet verfügbar (bis zu 8 MiB).';

  @override
  String get onlineWallpaperHours => 'h';

  @override
  String get onlineWallpaperInterval => 'Download-Intervall';

  @override
  String get onlineWallpaper => 'Online-Hintergrundbild';

  @override
  String get onlineWallpaperUrlError =>
      'Geben Sie ein direktes HTTPS-Bild URL ohne Anmeldedaten ein.';

  @override
  String get onlineWallpaperEnabled => 'Verwenden Sie Online-Hintergrundbilder';

  @override
  String get onlineWallpaperSource => 'Bildquelle';

  @override
  String get bingWallpaper => 'Bing Bild des Tages';

  @override
  String get onlineWallpaperUrlSource => 'Direkt HTTPS URL';

  @override
  String get updatePlayOnly =>
      'Diese Installation erhält Updates über Google Play.';

  @override
  String get updateCheck => 'Jetzt prüfen';

  @override
  String get updateInstalled => 'Installiert';

  @override
  String get updateDownloadInstall => 'Herunterladen und installieren';

  @override
  String get updateNoRelease =>
      'Es ist keine neuere kompatible Version verfügbar.';

  @override
  String get updateIncompatible =>
      'Der APK stimmt nicht mit dieser Anwendung, diesem Zertifikat oder einer neueren Version überein. Die Installation wurde blockiert.';

  @override
  String get updateError =>
      'Das Installationsprogramm kann nicht überprüft, heruntergeladen oder geöffnet werden. Versuchen Sie es später noch einmal.';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get appUpdates => 'Anwendungsaktualisierungen';

  @override
  String get updatePermission =>
      'Erlauben Sie die Installation dieser Anwendung in den Android-Einstellungen, kehren Sie hierher zurück und klicken Sie erneut auf „Installieren“.';

  @override
  String get updateInstall => 'Installieren Sie das heruntergeladene Update';

  @override
  String get updateHint =>
      'Quelle: GitHub / KirillShchetinnikov/CuteLauncher-Releases. Automatische Prüfungen werden ausgeführt, während der Launcher geöffnet ist. Der Download beginnt, wenn Sie ihn auswählen. Android fordert Sie auf, die Installation zu bestätigen. Ihre Daten werden gespeichert.';

  @override
  String get updateAutomatic => 'Einmal täglich automatisch prüfen';

  @override
  String get allApplications => 'Alle Anwendungen';

  @override
  String get adbAccessibility => 'Aktivieren Sie die Home-Button-Korrektur';

  @override
  String get adbAuthorization =>
      'Genehmigen Sie die ADB-Autorisierung auf dem Fernseher und versuchen Sie es dann erneut.';

  @override
  String get adbChangeConfirm =>
      'Diese Systemeinstellung über ADB anwenden? Die vorherige Home-App wird gespeichert, bevor sie geändert wird. Andere Barrierefreiheitsdienste bleiben erhalten.';

  @override
  String get adbCheck => 'Verbindung prüfen';

  @override
  String get adbDenied =>
      'Das System hat diese Änderung weder zugelassen noch bestätigt.';

  @override
  String get adbDisable => 'Deaktivieren Sie den vorherigen Launcher';

  @override
  String get adbDisableConfirm =>
      'Den gespeicherten vorherigen Launcher deaktivieren? Dafür muss CuteLauncher die aktuelle Home-App sein. Stellen Sie es mit der Wiederherstellungsaktion in diesem Setup wieder her.';

  @override
  String get adbHint =>
      'Prototyp nur für diesen Fernseher (127.0.0.1). Aktivieren Sie TCP ADB in den Entwickleroptionen, geben Sie seinen Port ein und bestätigen Sie die Autorisierungsaufforderung auf dem Fernseher. Das drahtlose Debuggen mit einem Pairing-Code wird noch nicht unterstützt. Der private Schlüssel verbleibt außerhalb von Backups auf diesem Gerät.';

  @override
  String get adbHome => 'Machen Sie CuteLauncher zur Home-App';

  @override
  String get adbInvalid => 'Geben Sie einen Port zwischen 1024 und 65535 ein.';

  @override
  String get adbNoRecovery =>
      'Die Wiederherstellung ist nicht verfügbar: Es wurde kein anderer Launcher oder gespeicherter Dienststatus gefunden.';

  @override
  String get adbPort => 'TCP ADB-Port';

  @override
  String get adbReady => 'ADB-Zugriff bestätigt.';

  @override
  String get adbRestore => 'Stellen Sie den vorherigen Launcher wieder her';

  @override
  String get adbSuccess => 'Änderung angewendet und überprüft.';

  @override
  String get adbTitle => 'ADB-Setup';

  @override
  String get adbUnavailable =>
      'Es kann keine Verbindung hergestellt werden. Überprüfen Sie TCP ADB, den Port und die Autorisierungsaufforderung.';

  @override
  String get nightModeScheduled => 'Zeitplan verwenden';

  @override
  String get nightModeTitle => 'Nachtmodus';

  @override
  String get nightModeScope =>
      'Zum Dimmen anderer Apps ist eine Overlay-Berechtigung erforderlich. Ohne sie funktioniert das Dimmen im CuteLauncher. Der TCL-Filter benötigt keine Overlay-Berechtigung. Über 80 % Deckkraft kann Android die Touch-Eingabe in anderen Apps blockieren; Die Tasten der TV-Fernbedienung funktionieren weiterhin.';

  @override
  String get nightModeEnd => 'Ende';

  @override
  String get nightModeStart => 'Starten';

  @override
  String get nightModeDim => 'Dimmen';

  @override
  String get nightModeWarmth => 'Warmer Filter';

  @override
  String get nightModeScheduleHint =>
      'Verwendet lokale Fernsehzeit. Übernachtungszeiten werden unterstützt. Gleiche Start- und Endzeiten deaktivieren den geplanten Filter.';

  @override
  String get nightModeEnabled => 'Nachtmodus aktivieren';

  @override
  String get nightModePermission => 'Anzeige über anderen Apps zulassen';

  @override
  String get nightModePermissionGranted => 'Anzeige über anderen Apps zulässig';

  @override
  String get backupDownloadsFailed =>
      'Das Backup konnte nicht unter „Downloads“ gespeichert werden.';

  @override
  String get backupSaveDownloads => 'Backup unter Downloads speichern';

  @override
  String get adbRestoreAccessibility => 'Barrierefreiheit wiederherstellen';

  @override
  String get nightModeAdbConfirm =>
      'Zulassen, dass CuteLauncher über andere Apps mit lokalem ADB angezeigt wird? Aktivieren Sie zunächst das TCP-Debugging und autorisieren Sie die Verbindung. Verwendet den im ADB-Assistenten gespeicherten Port oder 5555.';

  @override
  String get nightModeAdbPermission => 'Erteilen Sie die Erlaubnis über ADB';

  @override
  String get nightModeNotificationsHint =>
      'Mit der Benachrichtigung können Sie den Filter außerhalb von CuteLauncher deaktivieren. Ohne diese Option verwenden Sie dieses Menü.';

  @override
  String get nightModeNotificationsAllowed =>
      'Benachrichtigung im Nachtmodus zulässig';

  @override
  String get nightModeNotifications => 'Nachtmodus-Benachrichtigung zulassen';

  @override
  String get categoryLastVisibleHint =>
      'Mindestens eine Kategorie muss sichtbar bleiben.';

  @override
  String get diagnosticsClear => 'Sitzungsdiagnose löschen';

  @override
  String get diagnosticsReady => 'Bericht fertig';

  @override
  String get diagnosticsCreate => 'Bericht erstellen';

  @override
  String get diagnosticsOperations => 'Aufgezeichnete Operationen';

  @override
  String get diagnosticsCopied => 'Bericht kopiert';

  @override
  String get diagnosticsSharingNotice =>
      'Senden Sie die Datei dem Autor privat und veröffentlichen Sie sie nicht: Die automatische Bereinigung kann persönliche Daten übersehen. Mit dem Senden stimmen Sie der Veröffentlichung eines anonymisierten TV-Kompatibilitätsberichts im Git-Repository von CuteLauncher zu. Veröffentlicht werden nur Gerätemetadaten und verfügbare Funktionen ohne persönliche Daten; Fehlerprotokolle, Befehle und Ihre Einstellungen werden nicht veröffentlicht.';

  @override
  String get diagnosticsHint =>
      'Ein Bericht vereint TV-Funktionskompatibilität und Fehlerdiagnose. Der Bericht enthält TV-Modell und Firmware, App-Version, Berechtigungen, Speicher, Fehlerphasen und Ursachen sowie bereinigte Systembefehle und Antworten. Gespeichert werden die letzten 50 Vorgänge, separat bis zu 100 Fehler und ein begrenztes ADB-Protokoll der Sitzung. Ein Neustart löscht das Protokoll. Persönliche Daten können trotz Bereinigung verbleiben: Senden Sie die Datei privat und veröffentlichen Sie sie nicht. Es wird nichts automatisch versendet. Für jeden Fehler bleibt ein Schnappschuss der angewendeten Einstellungen erhalten; spätere Änderungen ersetzen ihn nicht.';

  @override
  String get diagnosticsTitle => 'Fehlerdiagnose';

  @override
  String get diagnosticsCopyFailed =>
      'Der Bericht konnte nicht kopiert werden.';

  @override
  String get diagnosticsCopy => 'Bericht kopieren';

  @override
  String get diagnosticsCreating => 'Bericht erstellen…';

  @override
  String get tclBlueLightTitle => 'TCL Blaulichtfilter';

  @override
  String get tclBlueLightError =>
      'Die Filtereinstellung TCL konnte nicht gelesen oder überprüft werden. Aktualisieren Sie den Status und versuchen Sie es erneut.';

  @override
  String get tclBlueLightUnsupported =>
      'Die Filterschnittstelle TCL ist auf diesem Fernseher nicht verfügbar.';

  @override
  String get tclBlueLightRefresh => 'Aktualisieren Sie den Filterstatus TCL';

  @override
  String get tclBlueLightHint =>
      'Steuert den integrierten Augengesundheitsschutzfilter des Fernsehers. Es kann auch dem Nachtmodus-Zeitplan folgen.';

  @override
  String get nightSolarSchedule => 'Sonnenuntergang und Sonnenaufgang';

  @override
  String get nightNextStart => 'Nächster Start';

  @override
  String get nightScheduleTimeHint =>
      'Die Uhrzeiten verwenden die TV-Zeitzone. Negative Offsets liegen früher; Positive Offsets sind später.';

  @override
  String get nightTemperature => 'Farbtemperatur filtern';

  @override
  String get nightScheduleSettings => 'Zeitplaneinstellungen';

  @override
  String get nightCityName => 'Stadtname';

  @override
  String get nightSkipUntilNext =>
      'Deaktivieren Sie den Nachtmodus bis zum nächsten Sonnenuntergang';

  @override
  String get nightSunriseOffset => 'Ende relativ zum Sonnenaufgang';

  @override
  String get nightEnableUntilMorning =>
      'Aktivieren Sie den Nachtmodus bis zum nächsten Sonnenaufgang';

  @override
  String get nightPermissions => 'Berechtigungen';

  @override
  String get nightTclSchedule =>
      'Beziehen Sie den TCL-Filter in den Zeitplan ein';

  @override
  String get nightSearchCity => 'Suchen';

  @override
  String get nightRefreshSun =>
      'Erfrischen Sie Sonnenaufgang und Sonnenuntergang';

  @override
  String get nightSolarUnavailable =>
      'Wählen Sie eine Stadt und erfrischen Sie sich in der Sonne. Wenn kein Sonnenaufgang oder Sonnenuntergang verfügbar ist, wird der Sonnenplan angehalten.';

  @override
  String get nightSunsetOffset => 'Beginnen Sie relativ zum Sonnenuntergang';

  @override
  String get nightCityHint =>
      'Wählen Sie Ihre Stadt, anstatt Standortzugriff zu gewähren. Die ausgewählten Koordinaten werden an Sunrise-Sunset.org oder Open-Meteo als Ersatz gesendet, um die Sonnenzeiten abzurufen.';

  @override
  String get nightResumeSchedule => 'Zurück zum Zeitplan';

  @override
  String get nightScheduleSource => 'Zeitplantyp';

  @override
  String get nightSolarCached =>
      'Verwendung zwischengespeicherter Sonnenzeiten; Die Internetaktualisierung wird automatisch erneut durchgeführt.';

  @override
  String get nightTclScheduleHint =>
      'Verwendet denselben Zeitplan, während der Nachtmodus aktiviert ist. Manuelle Änderungen am TCL-Filter bleiben bis zum nächsten geplanten Übergang bestehen. Es ist keine Overlay-Berechtigung erforderlich.';

  @override
  String get nightRefreshPermission => 'Berechtigungsstatus aktualisieren';

  @override
  String get nightCityNotFound =>
      'Keine Städte gefunden. Versuchen Sie es mit einem anderen Namen.';

  @override
  String get nightNoOffset => 'Kein Versatz';

  @override
  String get nightManualSchedule => 'Benutzerdefinierter Zeitplan';

  @override
  String get nightChooseCity => 'Wählen Sie eine Stadt';

  @override
  String get nightPermissionUnknown =>
      'Der Overlay-Berechtigungsstatus ist unbekannt';

  @override
  String get nightNextEnd => 'Nächstes Ende';

  @override
  String get nightTemporaryOff => 'Dimmen vorübergehend aus bis';

  @override
  String get nightCitySearchFailed =>
      'Es konnte nicht nach Städten gesucht werden. Überprüfen Sie Ihre Internetverbindung.';

  @override
  String get nightSolarAttribution =>
      'Tägliche Sonnenzeiten: Sunrise-Sunset.org; Fallback: Open-Meteo. Städtesuche: GeoNames. Für die Offline-Nutzung werden mehrere Tage zwischengespeichert.';

  @override
  String get nightTemporaryOn => 'Dimmen vorübergehend ein bis';

  @override
  String get homeScreen => 'Startbildschirm';

  @override
  String get appearanceSettings => 'Aussehen';

  @override
  String get generalSettings => 'Fortgeschritten';

  @override
  String get advancedSettings => 'Fortgeschritten';

  @override
  String get controlAndStartup => 'Launcher- und TV-Steuerung';

  @override
  String get sectionsAndOrder => 'Abschnitte und Reihenfolge';

  @override
  String get topPanel => 'Obere Platte';

  @override
  String get tileStyle => 'Fliesenstil';

  @override
  String get tilesAndLabels => 'Kacheln und Etiketten';

  @override
  String get highlightAndAnimation => 'Highlight und Animation';

  @override
  String get androidTvSettings => 'Android TV-Einstellungen';

  @override
  String get weatherSettings => 'Wettereinstellungen';

  @override
  String get showHighlightOutline => 'Hervorhebungsumriss anzeigen';

  @override
  String get resetTilesAndPanel =>
      'Kachel- und Bedienfeldeinstellungen zurücksetzen';

  @override
  String get resetTilesAndPanelHint =>
      'Zusätzliche Kachel-, Beschriftungs-, Hervorhebungs- und obere Panel-Parameter zurücksetzen? Hintergrundbild, Akzentfarbe, Kachelstil und Sichtbarkeit der Beschriftung bleiben erhalten.';

  @override
  String get panelAppearanceSettings => 'Aussehen der Oberseite';

  @override
  String get panelSharedHint =>
      'Ändern Sie das Erscheinungsbild in den Kacheleinstellungen.';

  @override
  String get effectsCompatibilityHint =>
      'Zusätzliches Erscheinungsbild: Der Umriss ist immer sichtbar und pulsiert nicht. Der Dimensionsstil hat keinen Legacy-Umriss; Classic pulsiert nicht. Die Intensität beeinflusst Maßstab und Schatten; Die Skalierung ist platzbegrenzt.';

  @override
  String get sizeAndLayout => 'Größe und Layout';

  @override
  String get labelsGroup => 'Etiketten';

  @override
  String get surfaceGroup => 'Oberfläche';

  @override
  String get clockAndDateGroup => 'Uhr und Datum';

  @override
  String get networkAndTrafficGroup => 'Netzwerk und Verkehr';

  @override
  String get buttonsGroup => 'Knöpfe';

  @override
  String get notificationAppsHint =>
      'Deaktivieren Sie Apps, deren Benachrichtigungen Sie nicht benötigen. Ein aktivierter Schalter ermöglicht Benachrichtigungen; Die App kann weiterhin gestartet werden.';

  @override
  String get notificationPanelLink => 'Aussehen der Oberseite';

  @override
  String get overlayAccessAdb => 'Anzeige über anderen Apps (ADB)';

  @override
  String get tileStyleModern => 'Modern';

  @override
  String get tileStyleVolume => 'Dimensional';

  @override
  String get showTime => 'Zeit anzeigen';

  @override
  String get showDate => 'Datum anzeigen';

  @override
  String get showWeather => 'Wetter anzeigen';

  @override
  String get showNetwork => 'Netzwerkstatus anzeigen';

  @override
  String get showTraffic => 'Verkehr anzeigen';

  @override
  String get scheduledBrightness => 'Geplante Helligkeit';

  @override
  String get followTileStyle => 'Folgen Sie dem Stil';

  @override
  String get androidTvSettingsHint => 'Öffnen Sie die TV-Systemeinstellungen';

  @override
  String get autoHideTopPanel => 'Blenden Sie das Bedienfeld automatisch aus';

  @override
  String get showSectionTitles => 'Abschnittstitel anzeigen';

  @override
  String get usageDaily => 'Täglich';

  @override
  String get usageWeekly => 'Wöchentlich';

  @override
  String get usageMonthly => 'Monatlich';

  @override
  String get onlineWallpaperAddress => 'Bildadresse (HTTPS)';

  @override
  String get watchNextAppLimits => 'Limits pro App';

  @override
  String get watchNextAppLimitsHint =>
      'Quellgrenzwerte gelten vor dem Gesamtgrenzwert. Unlimited behält nur das Gesamtlimit; Versteckte Inhalte bleiben verborgen.';

  @override
  String get rememberCategoryFocus =>
      'Merken Sie sich die zuletzt fokussierte Karte';

  @override
  String get automaticBackups => 'Automatische Sicherung';

  @override
  String get automaticBackupsHint =>
      'Tägliche Kopien von Einstellungen, Hintergrundbildern und Bannern, während der Launcher aktiv ist. Nach der Rückkehr zum Launcher wird eine verpasste Kopie ausgeführt. Privat auf diesem Gerät gespeichert, insgesamt bis zu 256 MiB; Durch das Entfernen der App oder ihrer Daten werden diese gelöscht. Führen Sie auch ein externes Backup durch.';

  @override
  String get automaticBackupsEnabled => 'Tägliches automatisches Backup';

  @override
  String get automaticBackupsKeep => 'Kopien zum Aufbewahren';

  @override
  String get automaticBackupCreateNow =>
      'Erstellen Sie jetzt einen Wiederherstellungspunkt';

  @override
  String get automaticBackupFailed =>
      'Der Sicherungsvorgang ist fehlgeschlagen. Überprüfen Sie den freien Speicherplatz und versuchen Sie es erneut.';

  @override
  String get restorePoints => 'Punkte wiederherstellen';

  @override
  String get noRestorePoints => 'Noch keine Wiederherstellungspunkte';

  @override
  String get updatePrereleases => 'Auf Vorabversionen aktualisieren';

  @override
  String get topPanelObjects => 'Objekte';

  @override
  String get panelTransparency => 'Panel-Transparenz';

  @override
  String get panelTextBackground => 'Text- und Schaltflächenhintergrund';

  @override
  String get panelTextBackgroundColor =>
      'Text- und Schaltflächenhintergrundfarbe';

  @override
  String get panelTextColor => 'Text- und Schaltflächenfarbe';

  @override
  String get panelTextSize => 'Text- und Schaltflächengröße';

  @override
  String get panelFont => 'Textschriftart';

  @override
  String get fontSans => 'Ohne Serifen';

  @override
  String get fontSerif => 'Serife';

  @override
  String get fontMono => 'Monospace';

  @override
  String get fontCondensed => 'Kondensiert';

  @override
  String get trafficPermissionGranted =>
      'Zugriff auf Verkehrsstatistiken gewährt';

  @override
  String get background => 'Hintergrund';

  @override
  String get backgroundParameters => 'Quelleneinstellungen';

  @override
  String get resetAppearanceHint =>
      'Hintergrund, Akzent, Kacheln, Beschriftungen, Hervorhebung und Animation zurücksetzen?';

  @override
  String get wallpaperDimming => 'Dimmen';

  @override
  String get wallpaperPlacement => 'Platzierung';

  @override
  String get wallpaperDisplay => 'Hintergrundbildanzeige';

  @override
  String get wallpaperContain => 'Gesamtes Bild anzeigen';

  @override
  String get wallpaperBlurred => 'Übermäßig verschwommene Kopie';

  @override
  String get wallpaperCover => 'Bildschirm füllen';

  @override
  String get wallpaperBrightness => 'Tapetenhelligkeit';

  @override
  String get wallpaperSaturation => 'Sättigung';

  @override
  String get categoryPadding => 'Kategorieauffüllung';

  @override
  String get categoryLight => 'Licht';

  @override
  String get categoryBlue => 'Blau';

  @override
  String get categoryPurple => 'Lila';

  @override
  String get categoryAllRows => 'Alle';

  @override
  String get categoryTeal => 'Blaugrün';

  @override
  String get categoryMaxRows => 'Sichtbare Gitterreihen';

  @override
  String get categoryDark => 'Dunkel';

  @override
  String get categoryAppearance => 'Erscheinungsbild der Kategorie';

  @override
  String get categoryBackground => 'Kategoriehintergrund';

  @override
  String get categoryTransparent => 'Transparent';

  @override
  String get slideshowInterval => 'Intervall ändern';

  @override
  String get slideshowFolderSelected =>
      'Ordnerzugriff auf diesem Gerät gespeichert.';

  @override
  String get slideshowRandom => 'Zufällige Reihenfolge';

  @override
  String get wallpaperSlideshow => 'Ordner-Diashow';

  @override
  String get slideshowNext => 'Nächstes Bild';

  @override
  String get slideshowFolderRequired =>
      'Wählen Sie einen Ordner, um die Diashow zu starten.';

  @override
  String get slideshowHint =>
      'Bis zu 1.000 Bilder und 4.000 Ordnereinträge; Dateien bis zu 8 MiB. Beschädigte Dateien werden übersprungen und das letzte gute Bild bleibt erhalten. Änderungen bleiben im Hintergrund stehen. Wählen Sie den Ordner nach der Wiederherstellung auf einem anderen Gerät erneut aus.';

  @override
  String get slideshowSeconds => 's';

  @override
  String get slideshowError =>
      'Bilder können nicht gelesen werden. Wählen Sie einen zugänglichen Ordner mit gültigen Bildern.';

  @override
  String get slideshowFolder => 'Ordner auswählen';

  @override
  String get slideshowRecursive => 'Unterordner einschließen';

  @override
  String get weatherSourceKeyRequired =>
      'Fügen Sie einen API-Schlüssel für diese Wetterquelle hinzu.';

  @override
  String get weatherOpenWeatherCredit =>
      'Wetter: OpenWeather (openweathermap.org). Tageswerte fassen die verfügbaren Drei-Stunden-Prognosezeiträume zusammen.';

  @override
  String get weatherOpenWeatherHint =>
      'Verwenden Sie Ihren Schlüssel für das aktuelle Wetter und die 5-Tage-/3-Stunden-Vorhersage. Bei jedem Update werden zwei Anfragen gestellt. Zugriff und Beschränkungen hängen von Ihrem Plan ab.';

  @override
  String get weatherOpenWeatherKey => 'OpenWeather API Schlüssel';

  @override
  String get mediaPause => 'Pause';

  @override
  String get showNowPlaying => 'Jetzt auf der Startseite anzeigen';

  @override
  String get nowPlayingAccessHint =>
      'Mediensteuerelemente erfordern Benachrichtigungszugriff für CuteLauncher. Es werden nur vom Spieler bereitgestellte Aktionen angezeigt.';

  @override
  String get nowPlaying => 'Jetzt spielen';

  @override
  String get mediaNext => 'Nächster Titel';

  @override
  String get mediaPlay => 'Lebenslauf';

  @override
  String get mediaControlError =>
      'Der Spieler ist nicht verfügbar oder hat diese Aktion nicht akzeptiert.';

  @override
  String get nightUsageAccess => 'Nutzungszugriff zulassen';

  @override
  String get nightExcludedAppsHint =>
      'Das Overlay und der geplante TCL-Filter werden in ausgewählten Apps angehalten. Nutzungszugriff ist erforderlich; Ohne sie können Ausschlüsse nicht angewendet werden.';

  @override
  String get nightExcludedApps => 'Ausgeschlossene Apps';

  @override
  String get adbPairPort => 'Pairing-Port';

  @override
  String get adbPairOverlayHint =>
      'Öffnen Sie das Wireless-Debugging und koppeln Sie es mit dem Pairing-Code. Lassen Sie den Systemcode-Dialog geöffnet. Dieses Formular wird nach 30 Sekunden aktiv. Geben Sie beide Ports und den von Android angezeigten Code ein.';

  @override
  String get adbOverlaySettings =>
      'Geben Sie die Steuerung für 30 Sekunden wieder in die Einstellungen zurück';

  @override
  String get adbTlsHint =>
      'Verwenden Sie das Wireless-Debugging in den Entwickleroptionen. Pairing und Verbindung verfügen über unterschiedliche Ports. Wenn Ihre Firmware keinen Pairing-Code-Bildschirm hat oder Overlay-Fenster blockiert, verwenden Sie stattdessen TCP/RSA. Alle Verbindungen bleiben lokal zu diesem Fernseher.';

  @override
  String get adbPaired =>
      'Gepaart. Überprüfen Sie die Verbindung mithilfe des Wireless-Debugging-Verbindungsports.';

  @override
  String get adbTransport => 'Verbindungsmethode';

  @override
  String get adbPairCode => 'Sechsstelliger Code';

  @override
  String get adbOverlayRequired =>
      'Für die Codeeingabe über die Einstellungen ist eine Berechtigung zur Anzeige über anderen Apps erforderlich.';

  @override
  String get adbOverlayPermission => 'Anzeige über anderen Apps zulassen';

  @override
  String get adbTlsUnsupported =>
      'Diese Firmware kann den erforderlichen Einstellungsbildschirm oder das Pairing-Overlay nicht öffnen. Verwenden Sie TCP/RSA.';

  @override
  String get adbConnectPort => 'Verbindungsport';

  @override
  String get adbTls => 'TLS/Pairing-Code';

  @override
  String get adbTcp => 'TCP / RSA';

  @override
  String get adbPairingFailed =>
      'Die Kopplung ist fehlgeschlagen. Überprüfen Sie den Code und den Pairing-Port, lassen Sie das Dialogfeld „Android-Code“ geöffnet und versuchen Sie es erneut.';

  @override
  String get adbTlsDisabled =>
      'Das drahtlose Debuggen ist deaktiviert oder der Status ist nicht verfügbar. Aktivieren Sie es in den Entwickleroptionen.';

  @override
  String get adbPairOverlay =>
      'Geben Sie den Kopplungscode über die Einstellungen ein';

  @override
  String get adbPair => 'Paar';

  @override
  String get adbDeveloperSettings => 'Öffnen Sie die Entwickleroptionen';

  @override
  String get adbTwoWindowsHint =>
      'Wenn diese Firmware zwei Fenster unterstützt, lassen Sie den Systemkopplungsdialog neben CuteLauncher geöffnet und geben Sie hier den Code ein. Die direkte Kopplung ist nur verfügbar, wenn beide Fenster geöffnet sind.';

  @override
  String get adbTwoWindows =>
      'Öffnen Sie die Einstellungen in einem zweiten Fenster';

  @override
  String get autoLaunchBoot => 'Nach dem TV-Start';

  @override
  String get autoLaunchOff => 'Deaktiviert';

  @override
  String get autoLaunchTitle => 'Autostart';

  @override
  String get autoLaunchDelay => 'Startverzögerung';

  @override
  String get autoLaunchHdmi =>
      'Wechseln Sie zu einem ausgewählten HDMI-Eingang';

  @override
  String get autoLaunchWake => 'Nach dem Aufwachen';

  @override
  String get autoLaunchHint =>
      'Wählen Sie eine App oder einen HDMI-Eingang, der nach dem Einschalten oder Aufwecken des Fernsehers geöffnet werden soll. Legen Sie unten das Ereignis und die Verzögerung fest. Die Aktion wird einmal ausgeführt, wenn Android CuteLauncher anzeigt. Jede Eingabe aus der Ferne oder das Verlassen des Startbildschirms bricht das Warten ab. Sie können die HDMI-Eingaben anschließend frei ändern. Legen Sie CuteLauncher als Standard-Launcher fest oder aktivieren Sie bei Bedarf „Beim Booten starten“. Für die Wake-Erkennung muss CuteLauncher weiterhin ausgeführt werden.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds Sekunden';
  }

  @override
  String get autoLaunchApp => 'Öffnen Sie eine ausgewählte App';

  @override
  String get autoLaunchTarget => 'Ziel starten';

  @override
  String get autoLaunchUnavailable =>
      'Das Ziel ist nicht verfügbar oder die Firmware lässt diese Aktion nicht zu.';

  @override
  String get autoLaunchCancelled => 'Verzögerter Start abgesagt.';

  @override
  String get syncTitle => 'Einstellungen austauschen';

  @override
  String get syncHint =>
      'Speichern Sie eine Einstellungsdatei, übertragen Sie sie auf ein anderes Gerät und öffnen Sie sie dort. Tauschen Sie die Datei wieder aus, um beide Geräte auf den neuesten Stand zu bringen. Benutzeroberfläche, Kachelstil und Anzeigeeinstellungen werden gemeinsam genutzt. Apps, Abschnitte, Hintergrunddateien, Berechtigungen, HOME, Startregeln und Geheimnisse bleiben auf diesem Gerät. Dies ist ein manueller Austausch; Es wird kein Konto oder keine Hintergrundnetzwerkverbindung verwendet.';

  @override
  String get syncExport => 'Änderungen an einer Datei speichern';

  @override
  String get syncImport => 'Öffnen Sie Änderungen von einem anderen Gerät';

  @override
  String get syncSaved => 'Einstellungsaustauschdatei gespeichert.';

  @override
  String get syncFailed =>
      'Einstellungen können nicht ausgetauscht werden. Es wird kein Teilimport beibehalten. Überprüfen Sie die Datei oder öffnen Sie sie erneut, wenn sich die Einstellungen während der Überprüfung geändert haben.';

  @override
  String get syncPreviewHint =>
      'Überprüfen Sie die Änderungen, bevor Sie sie anwenden. Wählen Sie bei Konflikten jede Zeile aus, um dieses Gerät oder die Datei auszuwählen. „Dieses Gerät behalten“ ist zunächst ausgewählt. Abbrechen lässt die Einstellungen unverändert.';

  @override
  String get syncNoChanges =>
      'Keine neuen Einstellungen. Beantragen Sie die Anerkennung der gemeinsamen Geschichte.';

  @override
  String syncLocalValue(String value) {
    return 'Dieses Gerät: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'Aus der Datei: $value';
  }

  @override
  String get syncKeepLocal => 'Konflikt: Dieses Gerät behalten';

  @override
  String get syncUseFile => 'Konflikt: Datei verwenden';

  @override
  String get syncApply => 'Überprüfte Änderungen anwenden';

  @override
  String get syncApplied =>
      'Einstellungen ausgetauscht. Speichern Sie eine neue Datei, um das Ergebnis zurückzusenden.';

  @override
  String syncStyleParameters(int count) {
    return 'Benutzerdefinierter Stil: $count Parameter (Unterschiede unten)';
  }

  @override
  String get cloudBackups => 'Cloud-Backups';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud. Geben Sie die HTTPS-Adresse eines vorhandenen Ordners und ein App-Passwort ein. Überweisungen erfolgen manuell; In diesem Ordner wird die neueste Kopie gespeichert.';

  @override
  String get cloudUrl => 'Adresse des Ordners HTTPS';

  @override
  String get cloudUser => 'Benutzername';

  @override
  String get cloudPassword => 'App-Passwort';

  @override
  String get cloudConnect => 'Konto prüfen und speichern';

  @override
  String get cloudCheck => 'Verbindung prüfen';

  @override
  String get cloudDisconnect => 'Konto trennen';

  @override
  String get cloudDisconnectConfirm =>
      'Dieses Konto vom Fernseher entfernen? Kopien in der Cloud bleiben erhalten.';

  @override
  String get cloudUpload => 'Speichern Sie eine Kopie in der Cloud';

  @override
  String get cloudDownload => 'Wiederherstellung aus der Cloud';

  @override
  String get cloudUploadConfirm =>
      'Cutelauncher_backup.json in diesem Ordner durch die aktuellen Einstellungen und Daten ersetzen?';

  @override
  String get cloudSuccess => 'Fertig';

  @override
  String get cloudConfigurationError =>
      'Überprüfen Sie die Ordneradresse HTTPS, den Benutzernamen und das App-Passwort.';

  @override
  String get cloudAuthorizationError =>
      'Zugriff verweigert. Überprüfen Sie Ihre Konto- und Ordnerberechtigungen.';

  @override
  String get cloudMissingError =>
      'Der Ordner oder das Backup wurde nicht gefunden.';

  @override
  String get cloudUnsupportedError =>
      'Diese Adresse unterstützt die erforderlichen WebDAV-Vorgänge nicht. Weiterleitungen werden nicht befolgt; Geben Sie die endgültige Ordneradresse ein.';

  @override
  String get cloudNetworkError =>
      'Die Verbindung ist fehlgeschlagen oder es ist eine Zeitüberschreitung aufgetreten. Versuchen Sie es erneut, wenn das Netzwerk verfügbar ist.';

  @override
  String get cloudFailed =>
      'Die Sicherungsaktion konnte nicht abgeschlossen werden. Überprüfen Sie den Speicherzugriff und versuchen Sie es erneut.';

  @override
  String get cloudStorageError =>
      'Der Kontospeicher ist nicht verfügbar. Trennen Sie das Konto und konfigurieren Sie es erneut.';

  @override
  String get adbPermissionChecking => 'Zugriff wird überprüft…';

  @override
  String get adbPermissionConnected => 'ADB verbunden · Erlaubnis erteilen';

  @override
  String get adbPermissionDisconnected =>
      'ADB getrennt · Verbindung herstellen';

  @override
  String get adbSetupIntro =>
      'Aktivieren Sie Debugging und Netzwerk ADB in den TV-Entwicklereinstellungen und vertrauen Sie dann CuteLauncher. Alle ADB-Aktionen erfolgen auf eigenes Risiko.';

  @override
  String get adbConnectionBlock => 'ADB-Verbindung';

  @override
  String get adbNotChecked => 'Verbindung nicht überprüft';

  @override
  String get adbApplied => 'Bereits angewendet';

  @override
  String get adbNotApplied => 'Noch nicht angewendet';

  @override
  String get adbDefaultBlock => 'Standard-Launcher';

  @override
  String get adbSystemDefault =>
      'Öffnen Sie die Standard-Launcher-Einstellung des Systems';

  @override
  String get adbAssignDefault =>
      'Legen Sie CuteLauncher über ADB als Standard-Launcher fest';

  @override
  String get adbRestoreDefault =>
      'Stellen Sie den vorherigen Standard-Launcher über ADB wieder her';

  @override
  String get adbDefaultHint =>
      'Verwenden Sie ADB, wenn das Systemmenü den Standard-Launcher nicht festlegen kann.';

  @override
  String get adbBuiltinHint =>
      'Durch Deaktivieren des integrierten Launchers kann das System stattdessen CuteLauncher öffnen. TV-Menüs und Tasten können davon betroffen sein. Aktivieren Sie den integrierten Launcher, um dies rückgängig zu machen.';

  @override
  String get adbHomeBlock => 'Home-Taste und Start';

  @override
  String get adbEnableService =>
      'Aktivieren Sie den Barrierefreiheitsdienst CuteLauncher über ADB';

  @override
  String get adbHomeOverride => 'Überschreiben Sie die Home-Taste';

  @override
  String get adbHomeOptional =>
      'Wenn der integrierte Launcher deaktiviert ist, ist das Überschreiben von „Home“ und das Starten beim Einschalten des Fernsehers optional.';

  @override
  String get adbEnableBuiltin =>
      'Aktivieren Sie den integrierten Launcher über ADB';

  @override
  String get adbDisableBuiltin =>
      'Deaktivieren Sie den integrierten Launcher über ADB';

  @override
  String get adbNoBuiltin =>
      'Keine integrierten Google TV-/Android TV-Trägerraketen gefunden.';

  @override
  String get adbChanged =>
      'Staat geändert. Überprüfen Sie die Verbindung und bestätigen Sie die Aktion erneut.';

  @override
  String get adbEffectHome =>
      'CuteLauncher wird zum Standard-Launcher des Systems. Der aktuelle Launcher wird zur Wiederherstellung gespeichert.';

  @override
  String get adbEffectRestore =>
      'Der vorherige Launcher wird aktiviert und als Standard festgelegt. Wenn nicht verfügbar oder nicht gespeichert, wird der erste verfügbare andere Launcher ausgewählt. Dadurch wird der Home-Button-Fix nicht deaktiviert.';

  @override
  String get adbEffectDisable =>
      'Die integrierte Launcher-App wird für den TV-Benutzer deaktiviert. TV-Menüs und Tasten funktionieren möglicherweise nicht mehr. Die App wird nicht deinstalliert.';

  @override
  String get adbRecoveryHomeDisable =>
      'Der gesamte Google TV-Setup-Assistent, einschließlich seines Wiederherstellungs-Startbildschirms, wird ebenfalls deaktiviert, sodass CuteLauncher zum Standard-Startprogramm werden kann. Die Funktionen des Setup-Assistenten sind bis zur Wiederherstellung nicht verfügbar. Der Originalzustand beider Pakete wird zur Wiederherstellung gespeichert.';

  @override
  String get adbRecoveryHomeRestore =>
      'Der Google TV-Setup-Assistent kehrt ebenfalls in seinen gespeicherten Zustand zurück.';

  @override
  String get adbDisableHomeUnavailable =>
      'Ein anderer Startbildschirm hat eine höhere Priorität. Es kann mit diesem Launcher nicht sicher deaktiviert werden.';

  @override
  String get adbEffectEnable =>
      'Der integrierte Launcher wird in seinen gespeicherten Zustand zurückgesetzt oder aktiviert, wenn kein Status gespeichert wurde. Das System wählt es möglicherweise erneut als Standard-Launcher aus.';

  @override
  String get adbEffectAccessibility =>
      'Der Barrierefreiheitsdienst CuteLauncher wird aktiviert. Es kann Home-Ereignisse empfangen; Das Abfangen wird über einen separaten Schalter gesteuert. Andere Dienste bleiben erhalten.';

  @override
  String get adbEffectAccessibilityRestore =>
      'Der CuteLauncher-Dienst kehrt zu seinem Zustand zurück, bevor der ADB-Zugriff gewährt wurde. Andere Barrierefreiheitsdienste bleiben erhalten.';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher darf Fenster über anderen Apps anzeigen, einschließlich des Nachtfilters.';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher erhält Benachrichtigungszugriff über seinen eigenen Listener-Dienst.';

  @override
  String get adbEffectWatchNext =>
      'CuteLauncher erhält Zugriff auf die Daten zur Fortsetzung der Beobachtung.';

  @override
  String get adbEffectUsage =>
      'CuteLauncher erhält Zugriff auf Nutzungsstatistiken für den Datenverkehr und die Erkennung von Vordergrund-Apps.';

  @override
  String get adbEffectWriteSettings =>
      'CuteLauncher darf die Systemhelligkeitseinstellungen ändern.';

  @override
  String get adbNoAvailableLauncher =>
      'Es wurden keine weiteren installierten Launcher gefunden. Die Wiederherstellung ist nicht verfügbar.';

  @override
  String get adbUnsupported =>
      'Auf diesem Gerät nicht verfügbar: Kein unterstützter ADB-Befehl.';

  @override
  String get adbHomeUnavailable =>
      'Der eingebaute Launcher hat Systempriorität. Eine direkte Zuweisung über ADB ist nicht verfügbar; Verwenden Sie die Barrierefreiheit oder deaktivieren Sie den integrierten Launcher.';

  @override
  String get nightBatteryExempt =>
      'CuteLauncher ist von der Optimierung ausgenommen';

  @override
  String get nightBatteryHint =>
      'Kann dazu beitragen, dass der Zeitplan im Hintergrund ausgeführt wird. Garantiert nicht, dass der Prozess den Standby-Modus übersteht.';

  @override
  String get nightBatteryOptimized =>
      'CuteLauncher unterliegt einer Optimierung';

  @override
  String get nightBatteryTitle => 'Batterieoptimierung';

  @override
  String get nightBatteryUnavailable =>
      'Die Systemeinstellungen sind für diese Firmware nicht verfügbar oder der Zugriff wurde verweigert.';

  @override
  String get nightBatteryUnknown => 'Ausnahmestatus unbekannt';

  @override
  String get nightBatteryOpenApps => 'Öffnen Sie die Apps-Einstellungen';

  @override
  String get nightBatteryGuide =>
      '1. Öffnen Sie in den Apps-Einstellungen den speziellen App-Zugriff.\n2. Wählen Sie Batterieoptimierung (manchmal Energiesparmodus).\n3. Finden Sie CuteLauncher; Wählen Sie bei Bedarf Alle Apps aus.\n4. Deaktivieren Sie die Optimierung oder wählen Sie „Uneingeschränkt“ aus.\nMenünamen und Verfügbarkeit hängen von der TV-Firmware ab.';

  @override
  String get updateNotifications => 'Update-Benachrichtigungen anzeigen';

  @override
  String get diagnosticsSave => 'Bericht in Datei speichern';

  @override
  String get diagnosticsSaved => 'Bericht gespeichert';

  @override
  String get diagnosticsSaveFailed =>
      'Der Bericht konnte nicht gespeichert werden. Überprüfen Sie den Dateimanager und den Zielordner.';

  @override
  String get memoryCacheSize => 'Größe des Bildcaches';

  @override
  String get memoryProcess => 'App-Speicher';

  @override
  String get memoryImages => 'Bild-Caches';

  @override
  String get diagnosticsExportOpened =>
      'Wählen Sie im Dateimanager einen Ordner und speichern Sie den Bericht.';

  @override
  String get adbDisableService =>
      'Deaktivieren Sie den Barrierefreiheitsdienst CuteLauncher über ADB';

  @override
  String get adbDefaultSettings => 'Standardeinstellungen für den Launcher';

  @override
  String get adbHomeSettings => 'Einstellungen der Home-Taste';

  @override
  String get adbAccessibilitySettings =>
      'Öffnen Sie die Barrierefreiheitseinstellungen';

  @override
  String get adbAccessibilityGuide =>
      'Wählen Sie im Systemmenü CuteLauncher aus und aktivieren Sie den Dienst. Kehren Sie hierher zurück, um die Home-Abfangfunktion zu konfigurieren. Um es zu deaktivieren, deaktivieren Sie den Dienst CuteLauncher im selben Menü.';

  @override
  String get adbEffectAccessibilityDisable =>
      'Der CuteLauncher-Dienst wird deaktiviert. Das Abfangen zu Hause wird aufhören. Andere Barrierefreiheitsdienste bleiben erhalten.';

  @override
  String get backupAutoEnabled => 'Automatische Sicherung';

  @override
  String get backupClientId => 'Kunden-ID';

  @override
  String get backupClientSecret => 'Client-Geheimnis';

  @override
  String get backupCloudImportConfirm =>
      'Alle lokalen Einstellungen, Kategorien und Bilder werden durch Cloud-Daten ersetzt. Weitermachen?';

  @override
  String get backupConfigured => 'Konfiguriert';

  @override
  String get backupConnection => 'Verbindungseinstellungen';

  @override
  String get backupCreated => 'Erstellt';

  @override
  String get backupDaily => 'Täglich';

  @override
  String get backupDriveHelp =>
      'Wählen Sie „Verbinden“ und bestätigen Sie den Code auf Ihrem Telefon. Backups sind im Ordner CuteLauncher in Google Drive sichtbar, wo Sie sie herunterladen oder löschen können. Behalten Sie die Dateinamen für die In-App-Wiederherstellung bei. Nach dem Upgrade von versteckten Backups aus erneut eine Verbindung herstellen; Alte Backups werden nicht automatisch migriert.';

  @override
  String get backupFrequency => 'Backup-Häufigkeit';

  @override
  String get backupHourly => 'Stündlich';

  @override
  String get backupLocal => 'Lokale Kopien';

  @override
  String get backupMinutes => 'min';

  @override
  String get backupMode => 'Modus';

  @override
  String get backupNever => 'Noch kein Backup';

  @override
  String get backupNotConfigured => 'Nicht konfiguriert';

  @override
  String get backupOptions => 'Backup-Optionen';

  @override
  String get backupSaveMode => 'Sicherung';

  @override
  String get backupScope => 'Backup auf allen Fernsehern';

  @override
  String get backupSyncScope =>
      'Synchronisierung über mehrere Fernseher hinweg';

  @override
  String get backupSeparate => 'Separat für jeden Fernseher';

  @override
  String get backupShared => 'Gleiche Einstellungen für alle Fernseher';

  @override
  String get backupStorage => 'Lagerung';

  @override
  String get backupSyncHelp =>
      'Daten herunterladen und Änderungen hochladen. Die neueste Änderung gewinnt Konflikte. Die Fernsehuhren müssen korrekt sein. Die Synchronisierung läuft, während der Launcher geöffnet ist.';

  @override
  String get backupSyncLimit => 'Überprüfen Sie nicht öfter als';

  @override
  String get backupSyncMode => 'Synchronisierung';

  @override
  String get backupSyncOptions => 'Synchronisierungsoptionen';

  @override
  String get backupTime => 'Backup-Zeit';

  @override
  String get backupWeekday => 'Wochentag';

  @override
  String get backupWeekly => 'Wöchentlich';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'Lokale Kopien werden mit der App bzw. deren Daten gelöscht. Bewahren Sie eine Kopie auch außerhalb des Fernsehers auf.';

  @override
  String get panelObjectOrder => 'Objektreihenfolge';

  @override
  String get panelInformationGroup => 'Informationen';

  @override
  String get panelOrderHint =>
      '◄ / ► startet oder beendet das Verschieben; ▲ / ▼ ändert die Reihenfolge und wechselt an Gruppengrenzen die Seite; OK / Zurück beendet.';

  @override
  String get panelTextBackgroundTransparency =>
      'Transparenz des Text- und Schaltflächenhintergrunds';

  @override
  String get weatherCityHint =>
      'Geben Sie den Namen der Stadt auf Englisch ein, zum Beispiel Moskau.';

  @override
  String get weatherCityNotFound =>
      'Stadt nicht gefunden. Überprüfen Sie den Städtenamen auf Englisch.';

  @override
  String get weatherLocationAutomatic => 'Automatisch erhalten';

  @override
  String get weatherLocationAutomaticHint =>
      'Gerätekoordinaten abrufen. Eine Standortgenehmigung ist erforderlich.';

  @override
  String get weatherLocationManual => 'Geben Sie manuell ein';

  @override
  String get weatherLocationPermissionDenied =>
      'Erlauben Sie den Standortzugriff in den Android-Einstellungen und versuchen Sie es erneut.';

  @override
  String get weatherLocationUnavailable =>
      'Koordinaten konnten nicht abgerufen werden. Überprüfen Sie die Standorteinstellungen von Android oder geben Sie manuell eine Stadt ein.';

  @override
  String get nightFilterSettings => 'Filtereinstellungen';

  @override
  String get nightScheduleMenu => 'Zeitplan';

  @override
  String get nightScheduleInactive => 'Der Zeitplan ist deaktiviert';

  @override
  String get nightLocation => 'Standort';

  @override
  String get nightLocationAutomatic => 'Automatisch erhalten';

  @override
  String get nightLocationManual => 'Geben Sie manuell ein';

  @override
  String get nightLocationFailed =>
      'Standort nicht verfügbar. Überprüfen Sie die Berechtigungs- und Systemstandorteinstellungen.';

  @override
  String get nightCityEnglish =>
      'Geben Sie den Namen der Stadt auf Englisch ein';

  @override
  String get nightOverlayBrief =>
      'Ermöglicht die Anzeige des Filters über anderen Apps.';

  @override
  String get weatherGetLocation => 'Standort abrufen';

  @override
  String get backupLastCreated => 'Letztes Backup wurde erstellt:';

  @override
  String get backupManagement => 'Backups verwalten';

  @override
  String get backupCopyList => 'Backup-Liste';

  @override
  String get backupRefreshCopyList => 'Backup-Liste aktualisieren';

  @override
  String get backupCreateNow => 'Erstellen Sie jetzt ein neues Backup';

  @override
  String get backupFolderPath => 'Sicherungsordner';

  @override
  String get backupPrivateFolder => 'Privater Bewerbungsordner';

  @override
  String get backupRestoreCopy => 'Stellen Sie dieses Backup wieder her';

  @override
  String get backupDeleteConfirm => 'Ausgewähltes Backup löschen?';

  @override
  String get blockedAppsGroup => 'Blockierte Apps';

  @override
  String get notificationSettingsButton => 'Benachrichtigungseinstellungen';

  @override
  String get hidePersistentNotificationsHint =>
      'Blenden Sie dauerhafte Benachrichtigungen in der Liste und über anderen Apps aus.';

  @override
  String get nightTransitionTime => 'Übergangszeit';

  @override
  String get brightnessSolar => 'Verwenden Sie den Nachtmodus-Zeitplan';

  @override
  String get brightnessAfterSunrise => 'Nach Sonnenaufgang';

  @override
  String get brightnessAfterSunset => 'Nach Sonnenuntergang';

  @override
  String get brightnessTransitionTime => 'Helligkeitsübergangszeit';

  @override
  String get brightnessSolarUnavailable =>
      'Der Zeitplan für den Nachtmodus ist nicht verfügbar. Überprüfen Sie die Zeiten und den Ort.';

  @override
  String get persistentNotificationCannotDelete =>
      'Diese dauerhafte Benachrichtigung kann nicht gelöscht werden. Sie können es nur blockieren.';

  @override
  String get diagnosticsCreateFailed =>
      'Der Diagnosebericht konnte nicht erstellt werden. Versuchen Sie es erneut.';

  @override
  String get backupListFailed =>
      'Die Sicherungsliste konnte nicht geladen werden. Überprüfen Sie den Zugriff auf den ausgewählten Speicher.';

  @override
  String get updateInstallerFailed =>
      'Das Update-Installationsprogramm konnte nicht geöffnet werden. Versuchen Sie es erneut und prüfen Sie, ob das Android-Installationsprogramm verfügbar ist.';

  @override
  String get backupFolderFailed =>
      'Der Sicherungsordner konnte nicht ausgewählt oder gespeichert werden. Wählen Sie einen zugänglichen Ordner und versuchen Sie es erneut.';

  @override
  String get updateDownloadFailed =>
      'Das Update konnte nicht heruntergeladen werden. Überprüfen Sie Ihre Internetverbindung und den verfügbaren Speicherplatz.';

  @override
  String get backupDeleteFailed =>
      'Das Backup konnte nicht gelöscht werden. Überprüfen Sie die Löschberechtigungen und versuchen Sie es erneut.';

  @override
  String get updateCheckFailed =>
      'Es konnte nicht nach Updates gesucht werden. Überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get backupCreateFailed =>
      'Das Backup konnte nicht erstellt werden. Überprüfen Sie den Speicherzugriff und den verfügbaren Speicherplatz.';

  @override
  String get wallpaperChangeFailed =>
      'Das Hintergrundbild konnte nicht geändert werden. Überprüfen Sie den Dateizugriff und versuchen Sie es erneut.';

  @override
  String get backupDownloadsFolder => 'Downloads / CuteLauncher';

  @override
  String get backupChooseFolder =>
      'Wählen Sie im Dateimanager einen Ordner aus';

  @override
  String get backupFolderPickerUnavailable =>
      'Auf diesem Fernseher ist keine Ordnerauswahl verfügbar. Wählen Sie Downloads / CuteLauncher oder den internen App-Ordner.';

  @override
  String get driveConfigurationError =>
      'Google Drive-Anmeldeinformationen fehlen oder sind ungültig. Geben Sie die Client-ID und das Client-Geheimnis Ihres TV-OAuth-Clients ein.';

  @override
  String get driveCodeExpired =>
      'Zeitüberschreitung bei der Google Drive-Anmeldung. Wählen Sie „Konto prüfen und speichern“, um einen neuen Code zu erhalten.';

  @override
  String get brightnessAfterNightStart => 'Nachts';

  @override
  String get brightnessAfterNightEnd => 'Tagsüber';

  @override
  String get backupSyncSettings => 'Einstellungen zum Synchronisieren';

  @override
  String get backupSyncHomeGroup => 'Startbildschirm, Abschnitte und Apps';

  @override
  String get backupSyncAppearanceGroup =>
      'Erscheinungsbild, Hintergrundbilder und Banner';

  @override
  String get backupSyncDisplayGroup =>
      'Nachtmodus, Helligkeit und Bildschirmschoner';

  @override
  String get backupSyncControlsGroup => 'Launcher- und TV-Steuerung';

  @override
  String get backupSyncGeneralGroup =>
      'Sprache, Updates und andere Einstellungen';

  @override
  String get backupSyncGroupsHelp =>
      'Deaktivierte Blöcke bleiben auf diesem Fernseher lokal. Die Blockauswahl wird zwischen den Geräten synchronisiert.';

  @override
  String get backupSyncGroupsFailed =>
      'Die Auswahl der Einstellungen für die Synchronisierung konnte nicht gespeichert werden. Versuchen Sie es erneut.';

  @override
  String get tileLayoutMode => 'Kachellayout';

  @override
  String get tileLayoutAuto => 'Automatisch nach Kachelgröße';

  @override
  String get tileLayoutColumns => 'Spaltenanzahl korrigiert';

  @override
  String get tileLayoutRows => 'Feste Zeilenanzahl';

  @override
  String get tileRowCount => 'Zeilenanzahl';

  @override
  String get useGlobalTileSettings => 'Verwenden Sie globale Einstellungen';

  @override
  String get centerSelection => 'Auswahlposition';

  @override
  String get selectionBottom => 'Unten';

  @override
  String get selectionLower => 'Untere Mitte';

  @override
  String get selectionCenter => 'Mitte';

  @override
  String get selectionUpper => 'Obere Mitte';

  @override
  String get selectionTop => 'Top';

  @override
  String get settingsStyle => 'Einstellungsstil';

  @override
  String get tileFocusEnlargement => 'Fokusvergrößerung';

  @override
  String get tileFocusShadowStrength => 'Schattenstärke';

  @override
  String get tileFocusLift => 'Heben';

  @override
  String get tileFocusLiftHeight => 'Hubhöhe';

  @override
  String get tileFocusBorderColor => 'Fokusrahmenfarbe';

  @override
  String get tileFocusAccentColor => 'Akzentfarbe';

  @override
  String get tileFocusDynamicColor => 'Dynamische Farben';

  @override
  String get tileSizeFromColumns =>
      'Die Kachelgröße wird durch die Spaltenanzahl und die Abschnittsbreite bestimmt.';

  @override
  String get resetSectionToGlobal =>
      'Setzen Sie die Einstellungen auf gemeinsame Werte zurück';

  @override
  String get resetSectionToGlobalHint =>
      'Gemeinsame Abschnittstitel, Symbole und Hintergrund wiederherstellen und Abstand zurücksetzen?';

  @override
  String get resetStyleSection => 'Setzen Sie diesen Abschnitt zurück';

  @override
  String get resetStyleSectionHint =>
      'Standardeinstellungen nur für diesen Abschnitt wiederherstellen?';

  @override
  String get notificationStyle => 'Benachrichtigungsstil';

  @override
  String get styleBackgroundColor => 'Hintergrundfarbe';

  @override
  String get styleTransparency => 'Hintergrundtransparenz';

  @override
  String get styleTextSize => 'Textgröße';

  @override
  String get styleTextColor => 'Textfarbe';

  @override
  String get noticeSize => 'Benachrichtigungsgröße';

  @override
  String get noticeStylePreview => 'Benachrichtigungsvorschau';

  @override
  String get backupSyncHomeOptions => 'Verhalten und allgemeine Optionen';

  @override
  String get backupSyncBackground =>
      'Hintergrund- und benutzerdefinierte Banner';

  @override
  String get backupSyncTiles => 'Kachel-, Menü- und Benachrichtigungsstil';

  @override
  String get backupSyncWeatherSource => 'Quelle und Standort';

  @override
  String get backupSyncWeatherDisplay =>
      'Wetteranzeige und Temperatureinheiten';

  @override
  String get backupSyncNotificationSettings =>
      'Benachrichtigungsanzeige und Filter';

  @override
  String get backupSyncOther => 'Andere Einstellungen';

  @override
  String get tileFocusBorderStyle => 'Grenzstil';

  @override
  String get tileFocusOutline => 'Gliederung';

  @override
  String get tileFocusGlow => 'Glühen';

  @override
  String get tileFocusNoBorder => 'Keine Grenze';

  @override
  String get tileShowFocusShadow => 'Schatten zeigen';

  @override
  String get homeLayoutRow => 'Horizontale Reihe';

  @override
  String get homeLayoutRows => 'Mehrere Reihen';

  @override
  String get homeLayoutGrid => 'Gitter';

  @override
  String get homeCardCount => 'Sichtbare Karten quer';

  @override
  String get homeAuto => 'Automatisch';

  @override
  String get homeFree => 'Kostenloses Scrollen';

  @override
  String get homeAnchored => 'Verankerter Abschnitt';

  @override
  String get homeScrollMode => 'Scrollen durch Abschnitte';

  @override
  String get homeSectionPosition => 'Aktive Abschnittsposition';

  @override
  String get homeLabelMode => 'Anwendungsetiketten';

  @override
  String get homeLabelNone => 'Keine Etiketten';

  @override
  String get homeLabelSelected => 'Nur ausgewählte Anwendung';

  @override
  String get homeLabelAll => 'Alle Anwendungen';

  @override
  String get homeInherited => 'Geerbter Wert';

  @override
  String get homeOwnReset => 'Gemeinsame Einstellungen wiederherstellen';

  @override
  String get homeParameters => 'Parameter';

  @override
  String get homeSectionStyle => 'Erscheinungsbild des Abschnitts';

  @override
  String get homeSectionGap => 'Abstand zwischen den Abschnitten';

  @override
  String get homeSectionIcons => 'Abschnittssymbole';

  @override
  String get homeInactiveOpacity => 'Deckkraft inaktiver Abschnitte';

  @override
  String get homeResetSection =>
      'Geerbtes Erscheinungsbild des Abschnitts wiederherstellen';

  @override
  String get homeCalculatedSize =>
      'Die Größe wird anhand der Kartenanzahl berechnet';

  @override
  String homeGapLimited(int gap) {
    return 'Der Abstand ist auf $gap begrenzt, um die ausgewählte Kartenanzahl beizubehalten.';
  }

  @override
  String get homeResetLayout => 'Abschnittslayout zurücksetzen';

  @override
  String homeVisibleRows(int count) {
    return 'Vollständig sichtbare Zeilen: $count';
  }

  @override
  String get homeStylePartial =>
      'Gilt nur für Abschnitte, die diesen Wert erben und ihn in ihrem aktuellen Layout unterstützen.';

  @override
  String get homeStyleUnavailable =>
      'In den aktuellen Abschnittseinstellungen nicht verfügbar. Überprüfen Sie das Layout und die lokalen Überschreibungen.';

  @override
  String get homeStyleNeedsRows =>
      'Verfügbar für mehrere Reihen oder ein Raster.';

  @override
  String get homeStyleNeedsLabels =>
      'Ermöglichen Sie Etiketten, ihre Größe und Farbe zu ändern.';

  @override
  String get homeStyleNeedsAllLabels =>
      'Die Position gilt nur für Beschriftungen auf allen Karten. Der ausgewählte Titel bleibt unter dem Abschnitt.';

  @override
  String get homeStyleNeedsScale => 'Wählen Sie den Vergrößerungsfokuseffekt.';

  @override
  String get homeStyleNeedsLift => 'Wählen Sie den Lift-Focus-Effekt.';

  @override
  String get homeStyleNeedsBorder =>
      'Aktivieren Sie zuerst einen Umriss oder ein Leuchten.';

  @override
  String get homeStyleNeedsTitle =>
      'Aktivieren Sie den Abschnittstitel, um sein Symbol anzuzeigen.';

  @override
  String get homeStyleEconomy =>
      'Durch Speicherspeicherung deaktiviert. Der gespeicherte Wert bleibt erhalten.';

  @override
  String get homeStyleOpaque =>
      'Reduzieren Sie die Deckkraft des Kachelhintergrunds, um Unschärfe zu erkennen.';

  @override
  String get homeStyleOverridden =>
      'Sichtbare Abschnitte verwenden ihre eigenen Werte. Wählen Sie in einem Abschnitt „Global verwenden“, um diese Einstellung anzuwenden.';

  @override
  String get homeStyleIconHint =>
      'Die Symbolgröße wirkt sich auf Karten mit einem App-Symbol aus. TV-Banner füllen die Karte selbstständig.';

  @override
  String get homeStyleShadowHint =>
      'Durch die Speichereinsparung wird der Schatten inaktiver Karten auf 4 begrenzt. Der Fokusschatten wird separat konfiguriert.';

  @override
  String get homeStyleTransparent =>
      'Bei einer Deckkraft von Null ist die Hintergrundfarbe unsichtbar. Erhöhen Sie die Deckkraft des Kachelhintergrunds.';

  @override
  String get homeStyleSingleColumn =>
      'Ein einspaltiges Raster weist keine horizontalen Lücken auf.';

  @override
  String get homeStyleAutoOnly =>
      'Die Größe ändert sich nur in Abschnitten mit automatischer Kartenzählung, die die globale Größe erben.';

  @override
  String get sleepTimerThirtySeconds => '30 Sekunden (Test)';

  @override
  String get sleepTimer => 'Sleep-Timer';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours Stunden',
      one: '1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1,5 Stunden';

  @override
  String get sleepTimerAllowExact => 'Ermöglichen Sie präzise Timer';

  @override
  String get sleepTimerExactRequired =>
      'Erlauben Sie präzise Timer in den Android-Einstellungen und wählen Sie dann erneut eine Dauer aus.';

  @override
  String get sleepTimerAccessRequired =>
      'Aktivieren Sie die Barrierefreiheit von CuteLauncher oder verbinden Sie den lokalen ADB unter Einstellungen → Andere → ADB.';

  @override
  String get sleepTimerFailed =>
      'Der Sleep-Timer konnte nicht eingestellt oder abgeschlossen werden. Überprüfen Sie die Erreichbarkeit und lokale ADB.';

  @override
  String get nightIgnoreHdmiInputs => 'Ignorieren Sie die HDMI-Eingaben';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'Pausieren Sie den Nachtfilter, während Sie HDMI ansehen. Nutzungszugriff ist erforderlich; Die Eingangserkennung hängt von der TV-Firmware ab.';

  @override
  String get inputsSettings => 'Eingabeeinstellungen';

  @override
  String get inputsUseCecNames => 'Verwenden Sie Gerätenamen von CEC';

  @override
  String get inputsNamesHint =>
      'Namenspriorität: Ihr Name in CuteLauncher → CEC (falls aktiviert) → Name aus den Android-Einstellungen → Standardeingabename.';

  @override
  String get inputNameHint => 'Für einen automatischen Namen leer lassen';

  @override
  String get inputsSaveFailed =>
      'Eingabeeinstellungen konnten nicht gespeichert werden';

  @override
  String get inputIcon => 'Eingabesymbol';

  @override
  String get inputIconTv => 'Fernseher';

  @override
  String get inputIconGame => 'Spielekonsole';

  @override
  String get inputIconComputer => 'Computer';

  @override
  String get inputIconReceiver => 'Empfänger';

  @override
  String get inputIconDisc => 'Disc-Player';

  @override
  String get inputIconStream => 'Streaming-Gerät';

  @override
  String get nightInputExclusions => 'Eingabeausschlüsse';

  @override
  String get nightSelectInputs =>
      'Wählen Sie Eingaben aus, die ignoriert werden sollen';

  @override
  String get nightNoInputsSelected =>
      'Keine Eingänge ausgewählt. Der Filter gilt für jede Eingabe.';

  @override
  String get nightPictureExclusions => 'Ausschlüsse für den Bildmodus';

  @override
  String get nightPictureExclusionsHint =>
      'Wählen Sie Modi, die das Dimmen anhalten, das Warm-Overlay und den verknüpften TCL-Filter. Der Zeitplan bleibt erhalten. Die Erkennung wurde auf TCL verifiziert; Ein Nutzungszugriff ist nicht erforderlich.';

  @override
  String get nightPictureUnavailable =>
      'Der aktuelle Bildmodus ist auf dieser Firmware nicht verfügbar. Ihre Auswahl wird gespeichert; Ausschlüsse gelten nur, wenn die Erkennung erfolgreich ist.';

  @override
  String get nightPictureCurrent => 'Aktueller Modus';

  @override
  String get nightPictureRefresh => 'Aktuellen Modus aktualisieren';

  @override
  String get nightPictureCode => 'Moduscode';

  @override
  String get nightPictureStandard => 'Standard';

  @override
  String get nightPictureDynamic => 'Dynamisch';

  @override
  String get nightPictureMovie => 'Film';

  @override
  String get nightPictureSport => 'Sport';

  @override
  String get nightPictureIntelligent => 'Intelligent';

  @override
  String get nightPictureBright => 'Hell (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'Standard';

  @override
  String get systemApplications => 'System-Apps';

  @override
  String get removeFromCategory => 'Aus Kategorie entfernen';

  @override
  String get noRemovableCategories =>
      'Diese App wurde keinem Abschnitt manuell hinzugefügt. Automatische Abschnitte können nicht bearbeitet werden.';

  @override
  String get remoteButtonsTitle => 'Fernbedienungstasten neu belegen';

  @override
  String get remoteButtonsStart => 'Tasten prüfen (120 s)';

  @override
  String get remoteButtonsStop => 'Prüfung beenden';

  @override
  String get remoteButtonsHint =>
      'Die Prüfung zeigt Tastencodes, Loslassen und Wiederholungen und speichert einen Textbericht auf dem TV. Verlassen Sie nach dem Start diese Seite, damit OK die Aufnahme nicht steuert.';

  @override
  String get remoteButtonsEmpty =>
      'Noch keine Ereignisse. Wenn eine Taste eine App öffnet, kehren Sie hierher zurück, um das Ergebnis zu sehen.';

  @override
  String get remoteButtonsService => 'Dienst verbunden';

  @override
  String get remoteButtonsRefresh => 'Aktualisieren';

  @override
  String get remoteBindings => 'Tastenbelegungen';

  @override
  String get remoteMappingsEnabled => 'Neubelegung aktivieren';

  @override
  String get remoteMappingsAdd => 'Belegung hinzufügen';

  @override
  String get remoteMappingKey => 'Taste';

  @override
  String get remoteMappingAction => 'Aktion';

  @override
  String get remoteMappingLearn => 'Fernbedienungstaste erkennen';

  @override
  String get remoteMappingLearnHint =>
      'Drücken Sie innerhalb von 30 Sekunden eine Zusatztaste. Navigation, Power, Sprachsuche und Lautstärke sind geschützt.';

  @override
  String get remoteMappingsHint =>
      'Belegungen benötigen den Bedienungshilfendienst. Im Editor und während der Diagnose sind sie pausiert. Home, Zurück, Pfeile und OK bleiben unverändert.';

  @override
  String get remoteMappingsReset => 'Belegungen zurücksetzen';

  @override
  String get remoteMappingsResetConfirm =>
      'Alle Belegungen löschen und die Neubelegung deaktivieren?';

  @override
  String get remoteMappingInvalid =>
      'Speichern fehlgeschlagen. Prüfen Sie Taste und Ziel. Webhooks benötigen HTTPS oder HTTP im lokalen Netzwerk.';

  @override
  String get remoteMappingBack => 'Zurück';

  @override
  String get remoteMappingProfile => 'Profil';

  @override
  String get remoteMappingChannels => 'Kanäle';

  @override
  String get remoteMappingQuickSettings => 'TCL-Schnelleinstellungen';

  @override
  String get remoteMappingTrigger => 'Tastendruck';

  @override
  String get remoteMappingPress => 'Kurz drücken';

  @override
  String get remoteMappingHold => 'Gedrückt halten';

  @override
  String get remoteMappingHoldHint =>
      '650 ms halten: einmalige Aktion ohne kurzen Tastendruck. Ist nur Halten belegt, bewirkt kurzes Drücken nichts.';

  @override
  String get remotePanelDescription =>
      'Das schwebende Panel zeigt Widgets über anderen Apps. Weisen Sie die Aktion „Schwebendes Panel“ einer Taste Ihrer Fernbedienung zu, um es zu öffnen.';

  @override
  String get remotePanel => 'Schwebendes Panel';

  @override
  String get remotePanelSettingsBackground =>
      'Hintergrundfarbe der Einstellungen verwenden';

  @override
  String get remotePanelPreview => 'Panel öffnen';

  @override
  String get settingsHelp => 'Weitere Informationen';

  @override
  String get settingsHelpScroll => '▲ / ▼ — Text scrollen';

  @override
  String get panelClockStyle => 'Uhrdarstellung';

  @override
  String get clockPreset => 'Schriftstil';

  @override
  String get clockCustom => 'Benutzerdefiniert';

  @override
  String get clockWeight => 'Schriftstärke';

  @override
  String get clockGlow => 'Textleuchten';

  @override
  String get clockAnimate => 'Ziffern animieren';

  @override
  String get clockBackground => 'Uhrhintergrund';

  @override
  String get clockRadius => 'Eckenradius des Hintergrunds';

  @override
  String get dateCalendarEnabled =>
      'Kalender beim Drücken auf das Datum öffnen';

  @override
  String get calendarTitle => 'Kalender';

  @override
  String get dateSettings => 'Datumseinstellungen';

  @override
  String get clockSharedBackground => 'Hintergrund wie bei anderen Objekten';

  @override
  String get clockDefaultBackground => 'Standardhintergrund';

  @override
  String get remotePanelInheritAppearance =>
      'Darstellung der oberen Leiste übernehmen';

  @override
  String get remotePanelDisabledInLauncher =>
      'Das Popup ist deaktiviert, solange CuteLauncher auf dem Bildschirm angezeigt wird.';

  @override
  String get remoteAccessSettings => 'Zugriff einrichten';

  @override
  String get remoteButtonsTest => 'Tastentest';

  @override
  String get remoteMappingConflict =>
      'Diese Taste und Druckart sind bereits zugewiesen. Wählen Sie eine andere Taste oder Druckart.';

  @override
  String get cleanerTitle => 'TV cleanup manager';

  @override
  String get cleanerRefresh => 'Refresh applications';

  @override
  String get cleanerSnapshot => 'Save original state';

  @override
  String get cleanerRestore => 'Basiszustand wiederherstellen';

  @override
  String get cleanerSnapshotSaved => 'Original state saved';

  @override
  String get cleanerExportSnapshot => 'Export original state';

  @override
  String get cleanerSafe => 'Disable verified applications';

  @override
  String get cleanerNoSafe =>
      'Keine passende System-App-Liste für dieses Modell und diese Firmware.';

  @override
  String get cleanerLocal => 'Disable using a local list';

  @override
  String get cleanerProject => 'Project catalog lists';

  @override
  String get cleanerRemoteProject => 'Refresh catalog from GitHub';

  @override
  String get cleanerExternal => 'CleanYourTV examples';

  @override
  String get cleanerDisabledExport =>
      'Bericht deaktivierter Apps als Datei exportieren';

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
      'Der Basiszustand wird bei der ersten erfolgreichen Aktualisierung einmalig erstellt und kann im Launcher weder gelöscht noch überschrieben werden. Er gilt für die Firmware. Manuelle Zustände speichern App-Modi mit Name und Datum und lassen sich wiederherstellen, löschen und exportieren. APKs und App-Daten sind nicht enthalten. Die Wiederherstellung benötigt lokales ADB. Der Absturzschutz versucht automatisch den Basiszustand wiederherzustellen. Das Löschen der Launcher-Daten oder die Deinstallation entfernt auch die Kopien; Root-Zugriff kann nicht verhindert werden.';

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
  String get landscapeDemoStop => 'Stopp';

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
  String get informationGroup => 'Uhr, Datum und Wetter';

  @override
  String get informationSettings => 'Blockeinstellungen';

  @override
  String get informationAppearance => 'Blockdarstellung';

  @override
  String get informationSize => 'Blockgröße';

  @override
  String get informationPosition => 'Position von Uhr und Text';

  @override
  String get informationClockLeft => 'Uhr links, Text rechts';

  @override
  String get informationClockRight => 'Text links, Uhr rechts';

  @override
  String get informationSpacing => 'Abstand zwischen Uhr und Text';

  @override
  String get informationBackground => 'Blockhintergrund';

  @override
  String get homeResetTilesHint =>
      'Gemeinsame Werte für alle Kacheln und Beschriftungen auf dieser Seite wiederherstellen?';

  @override
  String get homeResetLayoutHint =>
      'Layout dieses Bereichs zurücksetzen, gemeinsames Aussehen wiederherstellen und Innenabstände zurücksetzen? Apps und ihre Reihenfolge bleiben erhalten.';

  @override
  String get networkSummary => 'Netzwerk';

  @override
  String get networkConnected => 'Internet verfügbar';

  @override
  String get networkOffline => 'Kein Internetzugriff';

  @override
  String get networkDisconnected => 'Nicht verbunden';

  @override
  String get networkConnection => 'Verbindung';

  @override
  String get networkSignal => 'Signal';

  @override
  String get networkLinkSpeed => 'WLAN-Verbindungsrate';

  @override
  String get networkTrafficRate => 'Geräteverkehr · Empfang / Senden';

  @override
  String get networkSystemSettings => 'System-Netzwerkeinstellungen';

  @override
  String get networkUnavailable => 'Nicht verfügbar';

  @override
  String get networkMobile => 'Mobilfunknetz';

  @override
  String get networkFrequency => 'Frequenz';

  @override
  String get networkMbps => 'Mbit/s';

  @override
  String get networkKbps => 'KB/s';

  @override
  String get networkReadFailed => 'Netzwerkstatus konnte nicht gelesen werden';

  @override
  String get clockItalic => 'Kursiv';

  @override
  String get panelWrapNavigation => 'Zyklische Panelnavigation';

  @override
  String get panelWrapNavigationHelp =>
      'Links und rechts wechseln am Rand zur gegenüberliegenden Seite. Halten Sie eine Pfeiltaste, um sich weiterzubewegen.';

  @override
  String get networkReceive => 'Empfang';

  @override
  String get networkSend => 'Senden';

  @override
  String get landscapeCelestialBodies => 'Sonne und Mond';

  @override
  String get landscapeStarRotation => 'Sternrotation';

  @override
  String get tvPowerTitle => 'Energieverwaltung';

  @override
  String get tvPowerOff => 'TV ausschalten';

  @override
  String get tvPowerReboot => 'TV neu starten';

  @override
  String get tvPowerOffConfirm => 'TV in den Standby versetzen?';

  @override
  String get tvPowerRebootConfirm =>
      'TV neu starten? Offene Apps werden geschlossen.';

  @override
  String get tvPowerSent => 'Befehl gesendet';

  @override
  String get tvPowerFailed =>
      'Befehl fehlgeschlagen. ADB oder Bedienungshilfen prüfen.';

  @override
  String get tvPowerHelp =>
      'Ausschalten aktiviert Standby über den CuteLauncher-Bedienungshilfedienst oder lokales ADB. Neustart benötigt ADB. Bei TV-Boxen wird die Box gesteuert; das TV-Verhalten hängt von HDMI-CEC und Firmware ab.';

  @override
  String get cleanerLists => 'Deaktivierungslisten';

  @override
  String get cleanerRecovery => 'Sicherung und Wiederherstellung';

  @override
  String get cleanerExports => 'Berichte';

  @override
  String get cleanerUpdating => 'Anwendungsliste wird aktualisiert…';

  @override
  String get cleanerRefreshRequired =>
      'Aktualisieren Sie zuerst die Anwendungsliste.';

  @override
  String get cleanerPreinstalled => 'Vorinstallierte Anwendung';

  @override
  String get cleanerNotSystem => 'Dies ist keine Systemanwendung.';

  @override
  String get cleanerMinimalRisk => 'Minimal';

  @override
  String get cleanerCacheFailure =>
      'Die Liste konnte für den nächsten Besuch nicht gespeichert werden.';

  @override
  String get cleanerUserApps => 'Benutzeranwendungen';

  @override
  String get cleanerPreinstalledApps => 'Vorinstallierte Anwendungen';

  @override
  String get cleanerSystemApps => 'Systemanwendungen';

  @override
  String get cleanerBaseline => 'Ursprünglicher Basiszustand';

  @override
  String get cleanerManualStates => 'Manuelle Zustände verwalten';

  @override
  String get cleanerManualSave => 'Aktuellen Zustand speichern';

  @override
  String get cleanerDateName => 'Datum und Uhrzeit verwenden';

  @override
  String get cleanerCustomName => 'Namen eingeben';

  @override
  String get cleanerStateExport =>
      'Gespeicherten Zustand als Datei exportieren';

  @override
  String get cleanerStateRestoreHelp =>
      'Die gespeicherten Aktivierungszustände für diese Firmware werden wiederhergestellt. Später installierte Apps bleiben unverändert. Fehlende Apps und das Deaktivieren geschützter Komponenten werden übersprungen. App-Daten werden nicht wiederhergestellt.';

  @override
  String get cleanerCopiesHelp =>
      'Der Basiszustand wird bei der ersten erfolgreichen Aktualisierung einmalig erstellt und kann im Launcher weder gelöscht noch überschrieben werden. Er gilt für die Firmware. Manuelle Zustände speichern App-Modi mit Name und Datum und lassen sich wiederherstellen, löschen und exportieren. APKs und App-Daten sind nicht enthalten. Die Wiederherstellung benötigt lokales ADB. Der Absturzschutz versucht automatisch den Basiszustand wiederherzustellen. Das Löschen der Launcher-Daten oder die Deinstallation entfernt auch die Kopien; Root-Zugriff kann nicht verhindert werden.';

  @override
  String get cleanerSearch => 'Nach Namen suchen';

  @override
  String get cleanerCatalogUpdateRequired =>
      'Aktualisieren Sie zuerst den Katalog von GitHub.';

  @override
  String get cleanerNoSearchResults => 'Keine passenden Einträge.';

  @override
  String get cleanerAlreadyDisabled =>
      'Alle Apps aus dieser Liste auf diesem TV sind bereits deaktiviert.';

  @override
  String get cleanerAlreadyEnabled =>
      'Alle Apps aus dieser Liste auf diesem TV sind bereits aktiviert.';

  @override
  String get cleanerNoInstalled =>
      'Keine passenden Apps aus dieser Liste sind auf diesem TV installiert.';

  @override
  String get cleanerListProtected =>
      'Die übrigen Apps sind vor Deaktivierung geschützt.';

  @override
  String get cleanerSnapshotFailed =>
      'Sicherung fehlgeschlagen. Keine Apps wurden deaktiviert.';

  @override
  String get cleanerDisableAllPreinstalled =>
      'Alle vorinstallierten Apps deaktivieren';

  @override
  String get cleanerEnableAllPreinstalled =>
      'Alle vorinstallierten Apps aktivieren';

  @override
  String get cleanerPreinstalledList => 'Liste vorinstallierter Apps';

  @override
  String cleanerBeforeList(String listName) {
    return 'Vor Anwenden der Liste: $listName';
  }

  @override
  String get sleepTimerSettings => 'Einstellungen des Ausschalttimers';

  @override
  String get sleepTimerPresets => 'Timer';

  @override
  String get sleepTimerDisplay => 'Anzeige bei aktivem Timer';

  @override
  String get sleepTimerRemaining => 'Verbleibende Zeit';

  @override
  String get sleepTimerEndTime => 'Ausschaltzeit';

  @override
  String get sleepTimerBoth => 'Restzeit und Ausschaltzeit';

  @override
  String get sleepTimerShowSeconds => 'Sekunden anzeigen';

  @override
  String get sleepTimerCloseAfterSelection =>
      'Widget nach Auswahl eines Timers schließen';

  @override
  String get sleepTimerAdd => 'Timer hinzufügen';

  @override
  String get sleepTimerEdit => 'Timer bearbeiten';

  @override
  String get sleepTimerHoursLabel => 'Stunden';

  @override
  String get sleepTimerMinutesLabel => 'Minuten';

  @override
  String get sleepTimerSecondsLabel => 'Sekunden';

  @override
  String get sleepTimerInvalidDuration =>
      'Positive Dauer eingeben: Stunden 0–999999, Minuten und Sekunden 0–59.';

  @override
  String get sleepTimerDeleteConfirmation =>
      'Diesen Timer löschen? Der laufende Countdown wird fortgesetzt.';

  @override
  String get sleepTimerResetConfirmation =>
      'Standardtimer und Reihenfolge wiederherstellen? Eigene Timer werden entfernt. Der laufende Countdown wird fortgesetzt.';

  @override
  String get sleepTimerReorderHint =>
      '◄ / ► oder OK halten zum Verschieben. ▲ / ▼ ändern die Reihenfolge und verschieben Timer zwischen sichtbarer und ausgeblendeter Liste. OK beendet das Verschieben.';

  @override
  String get sleepTimerSaveFailed =>
      'Timer-Einstellungen konnten nicht gespeichert werden.';

  @override
  String get sleepTimerVisible => 'Angezeigt';

  @override
  String get sleepTimerHidden => 'Ausgeblendet';

  @override
  String get sleepTimerReset => 'Timer zurücksetzen';

  @override
  String get cleanerListSnapshotHelp =>
      'Vor dem Deaktivieren einer Liste werden nur die ausgewählten Apps automatisch gesichert. Andere Apps bleiben beim Wiederherstellen unverändert. Das Limit beträgt 100 manuelle und automatische Zustände. Ohne Sicherung beginnt keine Deaktivierung.';

  @override
  String get trafficSettings => 'Datenverkehr-Einstellungen';

  @override
  String get trafficTitle => 'Datenverkehr';

  @override
  String get trafficReceived => 'Empfangen';

  @override
  String get trafficSent => 'Gesendet';

  @override
  String get trafficTotal => 'Gesamt';

  @override
  String get stopApp => 'Stopp';

  @override
  String get backgroundImageFormats =>
      'Bilder: JPEG, PNG, WebP, GIF, BMP — bis 8 MiB, 48 Megapixel und 16.384 Pixel pro Seite.';

  @override
  String get backgroundMediaFormats =>
      'Bilder: JPEG, PNG, WebP, GIF, BMP — bis 8 MiB, 48 Megapixel und 16.384 Pixel pro Seite.\nVideo: MP4/M4V, WebM, MKV — bis 256 MiB und 3840×2160. Codecs hängen vom TV ab; bevorzugt MP4 mit H.264. Stumme Wiederholung, Pause außerhalb des Startbildschirms. Videos sind nicht in Sicherungen enthalten.';

  @override
  String get backgroundFormatError =>
      'Format nicht unterstützt oder Datei beschädigt. Eine gültige Datei in einem der angegebenen Formate wählen.';

  @override
  String backgroundFileTooLarge(String maxMiB) {
    return 'Datei zu groß. Maximal $maxMiB MiB. Eine kleinere Datei wählen.';
  }

  @override
  String get backgroundImageResolutionError =>
      'Bild zu groß: maximal 48 Megapixel und 16.384 Pixel pro Seite.';

  @override
  String get backgroundVideoResolutionError =>
      'Videoauflösung zu hoch. Maximal 3840×2160 (oder 2160×3840) wählen.';

  @override
  String get backgroundVideoCodecError =>
      'Der TV kann das Video nicht abspielen: Codec nicht unterstützt oder Datei beschädigt. MP4 mit H.264 versuchen.';

  @override
  String get backgroundFileApplied =>
      'Datei ausgewählt. Hintergrund aktualisiert.';

  @override
  String get noticePosition => 'Position der Benachrichtigungen';

  @override
  String get noticeBottomRight => 'Unten rechts';

  @override
  String get noticeBottomLeft => 'Unten links';

  @override
  String get noticeTopRight => 'Oben rechts';

  @override
  String get noticeTopLeft => 'Oben links';

  @override
  String get notificationOpenFailed =>
      'Die Benachrichtigungsaktion konnte nicht geöffnet werden. Sie ist möglicherweise nicht mehr verfügbar.';
}
