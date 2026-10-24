// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
  String get backgroundSource => 'Source de fond';

  @override
  String get noAvailableCategories =>
      'Aucune section n\'est disponible pour ajouter cette application.';

  @override
  String get redditWallpaperTheme => 'Thème de fond d\'écran';

  @override
  String get redditThemeAll => 'Mixte';

  @override
  String get redditThemeNature => 'Nature';

  @override
  String get redditThemeSpace => 'Espace';

  @override
  String get redditThemeCity => 'Villes';

  @override
  String get redditThemeMinimal => 'Minimalisme';

  @override
  String get redditWallpaperResolution => 'Résolution minimale';

  @override
  String get redditWallpaperHint =>
      'Chaque actualisation réussie télécharge une image de paysage différente de la communauté Reddit sélectionnée. La résolution est la taille minimale de l\'original ; les images ne sont pas mises à l’échelle. L\'actualisation s\'exécute lorsque le lanceur est ouvert et reprend à votre retour. Le contenu, les vidéos et les galeries pour adultes sont ignorés. Si Reddit bloque l\'accès ou si aucune image correspondante n\'est trouvée, le fond d\'écran précédent reste.';

  @override
  String get dialogCommandDetails => 'Afficher les commandes ADB';

  @override
  String get dialogAssign => 'Attribuer';

  @override
  String get dialogApply => 'Postuler';

  @override
  String get settingsValueNotSet => 'Non défini';

  @override
  String get settingsMenuPosition => 'Position du menu Paramètres';

  @override
  String get settingsMenuLeft => 'Gauche';

  @override
  String get settingsMenuRight => 'À droite';

  @override
  String get actionCompleted => 'Action terminée';

  @override
  String get showRepositoryQrCode => 'Afficher le code QR';

  @override
  String get resetSections => 'Réinitialiser les paramètres de la section';

  @override
  String get resetSectionsConfirmation =>
      'Restaurer les sections par défaut ? Les sections personnalisées, les espaceurs et le contenu des favoris seront supprimés.';

  @override
  String get cardFocusMode => 'Focus sur le retour à la maison';

  @override
  String get cardFocusRemember => 'Conserver la carte sélectionnée';

  @override
  String get cardFocusFirst => 'Première carte';

  @override
  String get cardFocusSettings => 'Bouton Paramètres';

  @override
  String get aboutFlauncher => 'À propos de CuteLauncher';

  @override
  String get addCategory => 'Ajouter une catégorie';

  @override
  String get addSection => 'Ajouter une section';

  @override
  String get alphabetical => 'Alphabétique';

  @override
  String get appCardHighlightAnimation =>
      'Animation de surbrillance de la carte d\'application';

  @override
  String get appInfo => 'Infos sur l\'application';

  @override
  String get appKeyClick => 'Son de clic lors de l\'appui sur une touche';

  @override
  String get applications => 'Applications';

  @override
  String get autoHideAppBar => 'Masquer automatiquement la barre d\'état';

  @override
  String get backButtonAction => 'Action du bouton retour';

  @override
  String get category => 'Catégorie';

  @override
  String get categories => 'Catégories';

  @override
  String get columnCount => 'Nombre de colonnes';

  @override
  String get date => 'Date';

  @override
  String get dateAndTimeFormat => 'Format de la date et de l\'heure';

  @override
  String get delete => 'Supprimer';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'Ne rien faire';

  @override
  String get dialogOptionBackButtonActionShowScreensaver =>
      'Afficher l\'écran de veille';

  @override
  String get dialogOptionBackButtonActionShowClock => 'Afficher l\'horloge';

  @override
  String get dialogTextNoFileExplorer =>
      'Veuillez installer un explorateur de fichiers pour sélectionner une image.';

  @override
  String get dialogTitleBackButtonAction =>
      'Choisir l\'action du bouton retour';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (Catégorie)';
  }

  @override
  String formattedDate(String dateString) {
    return 'Date formatée : $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'Heure formatée : $timeString';
  }

  @override
  String get gradient => 'Dégradé';

  @override
  String get favoriteApps => 'Applications favorites';

  @override
  String get grid => 'Grille';

  @override
  String get height => 'Hauteur';

  @override
  String get hide => 'Masquer';

  @override
  String get hiddenApplications => 'Applications masquées';

  @override
  String get launcherSections => 'Sections';

  @override
  String get layout => 'Disposition';

  @override
  String get loading => 'Chargement';

  @override
  String get manual => 'Manuel';

  @override
  String get modifySection => 'Modifier la section';

  @override
  String get mustNotBeEmpty => 'Ne doit pas être vide';

  @override
  String get name => 'Nom';

  @override
  String get newSection => 'Nouvelle section';

  @override
  String get noDateFormatSpecified => 'Aucun format de date spécifié';

  @override
  String get noTimeFormatSpecified => 'Aucun format d\'heure spécifié';

  @override
  String get nonTvApplications => 'Applications non TV';

  @override
  String get open => 'Ouvrir';

  @override
  String get orSelectFormatSpecifiers =>
      'Ou sélectionner les spécificateurs de format';

  @override
  String get openImage => 'Ouvrir l\'image';

  @override
  String get picture => 'Image';

  @override
  String removeFrom(String name) {
    return 'Retirer de $name';
  }

  @override
  String get renameCategory => 'Renommer la catégorie';

  @override
  String get reorder => 'Réorganiser';

  @override
  String get row => 'Ligne';

  @override
  String get rowHeight => 'Hauteur de ligne';

  @override
  String get save => 'Enregistrer';

  @override
  String get spacer => 'Espace';

  @override
  String get spacerMaxHeightRequirement =>
      'Doit être supérieur à 0 et inférieur ou égal à 500';

  @override
  String get statusBar => 'Barre d\'état';

  @override
  String get settings => 'Paramètres';

  @override
  String get show => 'Afficher';

  @override
  String get showCategoryTitles => 'Afficher les titres des catégories';

  @override
  String get themes => 'Thèmes';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'Masquer le contour de surbrillance sur l\'écran d\'accueil';

  @override
  String get appSelectorTransitionAnimation =>
      'Animation de transition du sélecteur d\'application';

  @override
  String get sort => 'Trier';

  @override
  String get systemSettings => 'Paramètres système';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => 'Cette catégorie est vide.';

  @override
  String get time => 'Heure';

  @override
  String get titleStatusBarSettingsPage =>
      'Choisir ce qu\'il faut afficher dans la barre d\'état';

  @override
  String get tvApplications => 'Applications TV';

  @override
  String get type => 'Taper';

  @override
  String get typeInTheDateFormat => 'Saisir le format de date';

  @override
  String get typeInTheHourFormat => 'Saisir le format de l\'heure';

  @override
  String get uninstall => 'Désinstaller';

  @override
  String get wallpaper => 'Fond d\'écran';

  @override
  String get withEllipsisAddTo => 'Ajouter à...';

  @override
  String get timeBasedWallpaper => 'Fond d\'écran basé sur l\'heure';

  @override
  String get pickDayWallpaper => 'Choisir le fond d\'écran de jour';

  @override
  String get pickNightWallpaper => 'Choisir le fond d\'écran de nuit';

  @override
  String get accessibility => 'Accessibilité';

  @override
  String get defaultLauncherIsDefault =>
      'CuteLauncher est le lanceur par défaut';

  @override
  String get defaultLauncherNotDefault =>
      'CuteLauncher n\'est pas le lanceur par défaut';

  @override
  String get setAsDefaultLauncher => 'Définir comme lanceur par défaut';

  @override
  String get defaultLauncherDescription =>
      'Lorsqu\'il est défini comme lanceur par défaut, le bouton Accueil reviendra toujours à CuteLauncher. La TV démarrera également directement sur CuteLauncher.';

  @override
  String get inputs => 'Entrées';

  @override
  String get inputsUnavailableHint =>
      'Cet appareil ne fournit aucune entrée disponible. Le commutateur est désactivé et l\'icône est masquée. Sur un boîtier TV, cette option ne contrôle pas les entrées HDMI du téléviseur connecté.';

  @override
  String get inputSources => 'Sources d\'entrée';

  @override
  String get backupAndRestore => 'Sauvegarde et restauration';

  @override
  String get exportBackup => 'Exporter la sauvegarde';

  @override
  String get importBackup => 'Importer la sauvegarde';

  @override
  String exportSuccess(String path) {
    return 'Sauvegarde exportée avec succès vers $path';
  }

  @override
  String get importSuccess => 'Sauvegarde importée avec succès';

  @override
  String get importConfirm =>
      'Voulez-vous vraiment importer la sauvegarde ? Cela remplacera vos paramètres et votre disposition actuels.';

  @override
  String get importError =>
      'Impossible de restaurer les paramètres à partir de la sauvegarde. Vérifiez le fichier et réessayez.';

  @override
  String exportError(String error) {
    return 'Échec de l\'exportation de la sauvegarde : $error';
  }

  @override
  String get shareBackup => 'Partager la sauvegarde';

  @override
  String get shareBackupDescription =>
      'Partager la sauvegarde avec d\'autres appareils sur le réseau local';

  @override
  String get stopSharing => 'Arrêter le partage';

  @override
  String get localNetworkSharingActive =>
      'Le partage sur le réseau local est actif !';

  @override
  String get localNetworkSharingInstructions =>
      'Connectez un autre appareil au même réseau Wi-Fi et ouvrez l\'URL suivante dans un navigateur Web :';

  @override
  String get localNetworkSharingDetails =>
      'Ici, vous pouvez télécharger les paramètres/disposition de votre TV ou importer un fichier de sauvegarde vers cette TV.';

  @override
  String failedToStartServer(String error) {
    return 'Échec du démarrage du serveur de partage : $error';
  }

  @override
  String get notificationBell => 'Cloche de notification';

  @override
  String get autoHideNotificationBell =>
      'Masquer automatiquement la cloche de notification';

  @override
  String get continueWatching => 'Continuer à regarder';

  @override
  String get showContinueWatchingOnHome =>
      'Afficher Continuer à regarder sur l\'accueil';

  @override
  String get permissionDeniedContinueWatching =>
      'Autorisation requise pour afficher Continuer à regarder';

  @override
  String get interface => 'Interface';

  @override
  String get system => 'Système';

  @override
  String get accentColor => 'Couleur d\'accentuation';

  @override
  String get miscellaneous => 'Divers';

  @override
  String get brightnessScheduler => 'Planificateur de luminosité';

  @override
  String get screensaverSettings => 'Paramètres de l\'écran de veille';

  @override
  String get screensaverClockStyle => 'Style d\'horloge de l\'écran de veille';

  @override
  String get dataUsagePeriod => 'Période d\'utilisation des données';

  @override
  String get notificationAccess => 'Accès aux notifications';

  @override
  String get granted => 'Accordé';

  @override
  String get permissionRequired => 'Autorisation requise';

  @override
  String get systemWidePopupAlert =>
      'Alerte contextuelle à l\'échelle du système';

  @override
  String get overlayPermissionRequired =>
      'Autorisation de superposition requise';

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get showAppNamesBelowIcons =>
      'Afficher les noms des applications sous les icônes';

  @override
  String get dataUsage => 'Utilisation des données';

  @override
  String get networkIndicator => 'Indicateur réseau';

  @override
  String get homeButtonFix => 'Correction du bouton Accueil (Google TV)';

  @override
  String get startOnBoot => 'Lancer au démarrage (Google TV / Fire TV)';

  @override
  String get appLanguage => 'Langue';

  @override
  String get systemDefault => 'Système par défaut';

  @override
  String get english => 'Anglais';

  @override
  String get spanish => 'Espagnol';

  @override
  String get ukrainian => 'Ukrainien';

  @override
  String get chinese => 'Chinois';

  @override
  String get french => 'Français';

  @override
  String get german => 'Allemand';

  @override
  String get japanese => 'Japonais';

  @override
  String get portuguese => 'Portugais';

  @override
  String get russian => 'Russe';

  @override
  String get italian => 'Italien';

  @override
  String get hindi => 'hindi';

  @override
  String get korean => 'Coréen';

  @override
  String get arabic => 'Arabe';

  @override
  String get turkish => 'Turc';

  @override
  String get hidePersistentNotifications =>
      'Masquer les notifications persistantes';

  @override
  String get hidePersistentNotificationsDesc =>
      'Masquer les notifications des services d\'arrière-plan et du système';

  @override
  String get blockedNotificationApps => 'Applications bloquées';

  @override
  String get blockAppNotifications => 'Bloquer les notifications';

  @override
  String get unblockAppNotifications => 'Débloquer les notifications';

  @override
  String get noBlockedApps => 'Aucune application bloquée';

  @override
  String get persistentNotification => 'Persistante';

  @override
  String get unblockAll => 'Tout débloquer';

  @override
  String get weather => 'Météo';

  @override
  String get showWeatherWarnings => 'Afficher les alertes météo et pluie';

  @override
  String get temperatureUnit => 'Unité de température';

  @override
  String get celsius => 'Celsius (°C)';

  @override
  String get fahrenheit => 'Fahrenheit (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Installez Breezy Weather et activez le \'Partage local des données\' / \'Gadgetbridge\' dans ses paramètres pour afficher la météo et les alertes de pluie.';

  @override
  String get displayAndScreensaver => 'Affichage et écran de veille';

  @override
  String get notifications => 'Notifications';

  @override
  String get continueWatchingDescription =>
      'Afficher les films et séries récemment regardés sur l\'écran d\'accueil';

  @override
  String get continueWatchingPermissionDesc =>
      'Une autorisation spéciale est requise pour lire l\'historique de lecture des applications TV :';

  @override
  String get requestPermission => 'Demander l\'autorisation';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get openApp => 'Ouvrir';

  @override
  String get notificationOptions => 'Options de notification';

  @override
  String get noBlockedAppsDesc =>
      'Toutes les applications sont actuellement autorisées à afficher des notifications';

  @override
  String get notificationsAllowed => 'Notifications autorisées';

  @override
  String get notificationsBlocked => 'Notifications bloquées';

  @override
  String get dpadDismissHint => 'Gauche: Ignorer • OK: Options';

  @override
  String get watchNextDeleteError =>
      'Impossible de supprimer l\'élément de Continuer à regarder. Essayer à nouveau.';

  @override
  String get hideLauncherTile =>
      'Masquer CuteLauncher dans la grille des applications';

  @override
  String get hideAndroidSettingsTile =>
      'Masquer les paramètres Android dans les vignettes de l\'application';

  @override
  String get animateTileReordering => 'Réorganisation des vignettes animées';

  @override
  String get imageInputRejected =>
      'Cette image est endommagée ou trop grande (maximum 8 MiB et 48 mégapixels). Choisissez une autre image.';

  @override
  String get memoryTitle => 'Mémoire';

  @override
  String get memoryRefresh => 'Mémoire de mesure';

  @override
  String get memoryMeasuring => 'Mesurer…';

  @override
  String get memoryClear => 'Effacer les caches d\'images';

  @override
  String get memorySaver => 'Économie de mémoire';

  @override
  String get memorySaverDescription =>
      'Mode d\'économie de mémoire :\n\n• Réduit les caches d\'images et la fenêtre de préchargement des affiches.\n• Désactive le flou d\'arrière-plan des carreaux, des panneaux et du papier peint, ainsi que les pulsations des contours.\n• Limite les ombres sur les tuiles floues.\n• Efface les caches lorsque l\'application passe en arrière-plan.\n\nCes effets ne sont pas disponibles dans les paramètres lorsque la sauvegarde de la mémoire est activée. Leurs valeurs enregistrées reviennent lorsque le mode est désactivé. Les images peuvent se recharger plus souvent.';

  @override
  String get memoryPss => 'Partage de processus (PSS)';

  @override
  String get memoryRss => 'Mémoire de processus résidente (RSS)';

  @override
  String get memoryEncodedCache => 'Fichiers images mis en cache';

  @override
  String get memoryDecodedCache => 'Images décodées en cache';

  @override
  String get memoryUnavailable => 'Indisponible';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => 'Mesuré à';

  @override
  String get memoryExplanation =>
      'PSS et RSS se chevauchent : ne les additionnez pas. Les tailles de cache font partie de la mémoire de l\'application et ne décrivent pas toute la mémoire détenue par les images actives. La suppression des caches conserve vos paramètres et vos fichiers ; les images se chargent à nouveau si nécessaire. Android peut renvoyer de la mémoire ultérieurement. RSS vient ici du noyau et PSS de Android ; ils peuvent prendre en compte la mémoire graphique différemment.';

  @override
  String get memoryRecommendations =>
      'Pour moins de mémoire, activez la sauvegarde, affichez moins de cartes Continuer à regarder et utilisez des fonds d\'écran plus petits ou un dégradé.';

  @override
  String get memoryMeasurementFailed =>
      'La mesure du processus n\'est pas disponible. Les informations du cache sont toujours affichées.';

  @override
  String get addToCategory => 'Ajouter à la catégorie';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get removeFromFavorites => 'Supprimer des favoris';

  @override
  String get setCustomBanner => 'Définir une bannière personnalisée';

  @override
  String get clearCustomBanner => 'Effacer la bannière personnalisée';

  @override
  String get bannerSetFailed =>
      'Impossible de définir la bannière. Vérifiez l\'accès à l\'image et sélectionnez à nouveau le fichier.';

  @override
  String get bannerClearFailed =>
      'Impossible de supprimer la bannière personnalisée. Essayer à nouveau.';

  @override
  String get grantUsagePermission => 'Accorder une autorisation d\'utilisation';

  @override
  String get removeFromContinueWatching => 'Supprimer de Continuer à regarder';

  @override
  String hideAllFromApp(String appName) {
    return 'Tout masquer de $appName';
  }

  @override
  String get playResume => 'Jouer / Reprendre';

  @override
  String openNamedApp(String appName) {
    return 'Ouvrir $appName';
  }

  @override
  String get selectedAccent => 'Accent sélectionné';

  @override
  String get homeButtonFixHint =>
      'Si vous utilisez Google TV, activez « Correction du bouton Accueil » sous Paramètres d\'accessibilité pour que le bouton Accueil ouvre ce lanceur.';

  @override
  String get accessibilityPermission => 'Autorisation d\'accessibilité';

  @override
  String get shareFailed => 'Échec du partage';

  @override
  String shareBackupError(String error) {
    return 'Échec du partage de la sauvegarde : $error';
  }

  @override
  String get exportComplete => 'Succès à l’exportation';

  @override
  String get exportFailed =>
      'Impossible d\'enregistrer la sauvegarde. Vérifiez l\'accès aux dossiers et le stockage disponible.';

  @override
  String backupLoadError(String error) {
    return 'Erreur lors du chargement des sauvegardes : $error';
  }

  @override
  String get noBackupFiles => 'Aucun fichier de sauvegarde trouvé.';

  @override
  String get importComplete => 'Succès de l\'importation';

  @override
  String get importFailed => 'Échec de l\'importation';

  @override
  String get importAction => 'Importer';

  @override
  String get continueWatchingApps => 'Continuer à regarder des applications';

  @override
  String get blockedContinueWatching => 'Bloqué pour continuer à regarder';

  @override
  String get allAppsCanContinueWatching =>
      'Toutes les applications prises en charge peuvent afficher des éléments dans Continuer à regarder.';

  @override
  String get unblockApp => 'Débloquer';

  @override
  String get unblockAllApps => 'Débloquer toutes les applications';

  @override
  String get appsWithContinueWatching =>
      'Applications avec Continuer à regarder';

  @override
  String get watchNextAppsHint =>
      'Applications proposant actuellement des éléments Watch Next sur votre écran d\'accueil';

  @override
  String get noWatchNextApps =>
      'Aucune application ne propose actuellement d\'éléments Continuer à regarder.\nLorsque des applications prises en charge (telles que SmartTube ou des services de streaming) ajoutent des éléments, ils apparaîtront ici.';

  @override
  String get allInstalledApps => 'Toutes les applications installées';

  @override
  String get blockWatchNextHint =>
      'Désactivez cette option pour empêcher toute application d\'ajouter des éléments à Continuer à regarder.';

  @override
  String get cardSize => 'Taille de la carte';

  @override
  String get maximumItems => 'Articles maximum';

  @override
  String get playbackProgressBar => 'Barre de progression de la lecture';

  @override
  String get playbackPercentage => 'Pourcentage de lecture';

  @override
  String get episodeVideoDetails => 'Détails de l\'épisode et de la vidéo';

  @override
  String get restoreHiddenPrograms => 'Restaurer les programmes cachés';

  @override
  String get allHiddenProgramsRestored =>
      'Tous les programmes cachés restaurés';

  @override
  String get watchNextAccessAdb => 'Regarder l\'accès suivant (ADB requis)';

  @override
  String get supportLtvLauncher => 'Prise en charge LTvLauncher';

  @override
  String get scanToDonate =>
      'Scannez avec l\'appareil photo de votre téléphone pour faire un don :';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get close => 'Fermer';

  @override
  String get launcherAuthor => 'CuteLauncher par Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Lanceur Android TV basé sur LTvLauncher de LeanBitLab et FLauncher de Étienne Fesser. Sous licence GNU GPLv3.';

  @override
  String get projectCredits => 'Projet et crédits';

  @override
  String get launcherRepository => 'Référentiel CuteLauncher';

  @override
  String get originalProject => 'Projet original : LTvLauncher';

  @override
  String get noInputsDetected => 'Aucune entrée détectée';

  @override
  String get reorderSectionsHint =>
      'Sélectionnez avec ◄ / ► puis utilisez ▲ / ▼ pour réorganiser. Traversez la limite de la liste pour masquer ou afficher une section.';

  @override
  String get customName => 'Nom personnalisé';

  @override
  String get mostUsed => 'Fréquence de lancement';

  @override
  String get lastUsed => 'Dernière utilisation';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get allCaughtUp => 'Tous rattrapés !';

  @override
  String get notificationAccessAdb => 'Accès aux notifications (ADB requis)';

  @override
  String get openAppInfo => 'Ouvrir les informations sur l\'application';

  @override
  String get overlayPermission => 'Autorisation de superposition';

  @override
  String get clockMinimal => 'Minime';

  @override
  String get clockMinimalDescription => 'Police fine et élégante (par défaut)';

  @override
  String get clockBold => 'Audacieux';

  @override
  String get clockBoldDescription => 'Police épaisse et très visible';

  @override
  String get clockRetro => 'Rétro';

  @override
  String get clockRetroDescription => 'Style de terminal rétro monospace';

  @override
  String get clockElegant => 'Élégant';

  @override
  String get clockElegantDescription => 'Police à empattement classique';

  @override
  String get clockNeon => 'Néon';

  @override
  String get clockNeonDescription => 'Style ultra fin et éclatant';

  @override
  String get clockPixel => 'Pixels';

  @override
  String get clockPixelDescription =>
      'Audacieux, monospace, sensation d\'arcade';

  @override
  String get clockDigital => 'Numérique';

  @override
  String get clockDigitalDescription => 'Affichage propre à espacement fixe';

  @override
  String get themeDefault => 'Par défaut';

  @override
  String get themePremium => 'Prime';

  @override
  String get themeClassic => 'Classique';

  @override
  String get themeCapsule => 'Capsule';

  @override
  String get cancel => 'Annuler';

  @override
  String get actionCancelled => 'Action annulée';

  @override
  String get ok => 'D\'accord';

  @override
  String get accessibilityGuide =>
      'Ouvrez les paramètres du téléviseur manuellement, puis Accessibilité → CuteLauncher Home Button Fix et activez le service. L\'emplacement et le nom de ce menu dépendent du fabricant de votre téléviseur.';

  @override
  String get notificationPermissionGuide =>
      'Les paramètres d\'accès aux notifications n\'ont pas pu être ouverts sur ce téléviseur. Autoriser les notifications sortantes dans App Info ne donne pas accès aux notifications d\'autres applications.\n\nConnectez votre téléviseur via ADB et exécutez :';

  @override
  String get overlayPermissionGuide =>
      'Les paramètres d\'autorisation de superposition n\'ont pas pu être ouverts automatiquement.\n\nPour activer les fenêtres contextuelles sur d\'autres applications, connectez votre téléviseur via ADB et exécutez :';

  @override
  String get watchNextPermissionGuide =>
      'Pour lire Continuer à regarder des cartes d\'autres applications, Android TV nécessite READ_WRITE_WATCH_NEXT_PROGRAMS.\n\nConnectez votre téléviseur via ADB et exécutez :';

  @override
  String get watchNextAccess => 'Continuer à regarder l\'accès';

  @override
  String itemsCount(int count) {
    return 'Articles $count';
  }

  @override
  String displayUpToItems(int count) {
    return 'Afficher jusqu\'à $count éléments récents';
  }

  @override
  String get unlimitedItems => 'Illimité';

  @override
  String get allAvailableItems => 'Afficher tous les articles disponibles';

  @override
  String get defaultOption => 'Par défaut';

  @override
  String get manage => 'Gérer';

  @override
  String blockedCount(int count) {
    return '$count bloqué';
  }

  @override
  String hiddenCount(int count) {
    return '$count caché';
  }

  @override
  String blockedWatchNextCount(int count) {
    return 'Bloqué pour continuer à regarder ($count)';
  }

  @override
  String get sizeExtraSmall => 'Très petit';

  @override
  String get sizeVerySmall => 'Très petit';

  @override
  String get sizeSmall => 'Petit';

  @override
  String get sizeCompact => 'Compacte';

  @override
  String get sizeMediumSmall => 'Moyen Petit';

  @override
  String get sizeMedium => 'Moyen';

  @override
  String get sizeStandardDefault => 'Standard (par défaut)';

  @override
  String get sizeMediumLarge => 'Moyen Grand';

  @override
  String get sizeLarge => 'Grand';

  @override
  String get sizeVeryLarge => 'Très grand';

  @override
  String get sizeExtraLarge => 'Très grand';

  @override
  String get sizeHuge => 'Énorme';

  @override
  String get tvApps => 'Applications télévisées';

  @override
  String get nonTvApps => 'Applications non télévisées';

  @override
  String get moviesShows => 'Films et émissions';

  @override
  String get music => 'Musique';

  @override
  String get games => 'Jeux';

  @override
  String get entertainment => 'Divertissement';

  @override
  String get liveTv => 'Télévision en direct';

  @override
  String get sports => 'Sport';

  @override
  String get news => 'Actualités';

  @override
  String get tools => 'Outils';

  @override
  String get favorites => 'Favoris';

  @override
  String get customSectionName => 'Personnalisé...';

  @override
  String get selectSectionName => 'Sélectionnez un nom';

  @override
  String get weeklyUsage => 'Hebdomadaire :';

  @override
  String get monthlyUsage => 'Mensuel :';

  @override
  String get dailyUsage => 'Quotidiennement :';

  @override
  String get appError => 'Quelque chose s\'est mal passé';

  @override
  String get weatherRain => 'Pluie';

  @override
  String get weatherSnow => 'Neige';

  @override
  String get weatherStorm => 'Tempête';

  @override
  String get weatherToday => 'aujourd\'hui';

  @override
  String get weatherTomorrow => 'demain';

  @override
  String weatherOnDay(String day) {
    return 'sur $day';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'Sauvegarde CuteLauncher';

  @override
  String get noApplicationsFound => 'Aucune application trouvée';

  @override
  String get invalidDateFormat => 'Format invalide';

  @override
  String get selectDateFormats => 'Sélectionnez les formats ci-dessous';

  @override
  String activeItemsCount(int count) {
    return '$count article(s) actif(s)';
  }

  @override
  String get colorPurple => 'Violet';

  @override
  String get colorTeal => 'Sarcelle';

  @override
  String get colorBlue => 'Bleu';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPink => 'Rose';

  @override
  String get colorGreen => 'Vert';

  @override
  String get colorWhite => 'Blanc';

  @override
  String get colorYellow => 'Jaune';

  @override
  String get colorRed => 'Rouge';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorLime => 'Chaux';

  @override
  String get colorAmber => 'Ambre';

  @override
  String get colorRose => 'Rose';

  @override
  String get colorIceBlue => 'Bleu glacier';

  @override
  String get memoryFeatures => 'Mémoire par fonctionnalité (caches)';

  @override
  String get memoryAppIcons => 'Icônes d\'application';

  @override
  String get memoryAppBanners => 'Bannières d\'applications';

  @override
  String get memoryWatchNextPosters => 'Continuer à regarder les affiches';

  @override
  String get memoryOtherCaches => 'Autres caches d\'images codées';

  @override
  String get memoryFeaturesExplanation =>
      'Il s\'agit d\'octets d\'image conservés, déjà inclus dans le total du cache codé. Zéro signifie qu\'aucun octet n\'est conservé dans ce cache, et non que la fonctionnalité n\'utilise aucune mémoire. Les fonds d\'écran et les images affichées partagent le cache décodé ci-dessus ; les images actives peuvent se trouver à l’extérieur. La météo, les notifications, les objets Dart et le moteur ne peuvent pas être divisés par fonctionnalité ici. Les graphiques d\'interface partagée sont signalés ci-dessus par Android et déjà inclus dans PSS. Leur mémoire fait partie du processus total. N\'ajoutez pas ces valeurs qui se chevauchent.';

  @override
  String get memoryGraphics => 'Graphiques d\'interface (inclus dans PSS)';

  @override
  String get categoryVisible => 'Afficher la catégorie';

  @override
  String get hiddenCategories => 'Catégories masquées';

  @override
  String get visibleCategories => 'Catégories visibles';

  @override
  String get backupSavedToSelectedLocation =>
      'Sauvegarde enregistrée à l\'emplacement sélectionné';

  @override
  String get tileHorizontalGap => 'Espacement horizontal';

  @override
  String get tileVerticalGap => 'Espacement vertical';

  @override
  String get tileOpacity => 'Opacité de l\'arrière-plan';

  @override
  String get tileShadow => 'Ombre';

  @override
  String get tileCornerRadius => 'Arrondi des coins';

  @override
  String get tileIconScale => 'Taille de l\'icône';

  @override
  String get tileBackgroundColor => 'Fond de tuile';

  @override
  String get tileLabelSize => 'Taille de l\'étiquette';

  @override
  String get resetAppearance => 'Réinitialiser l\'apparence';

  @override
  String get tileAppearance => 'Aspect du carrelage';

  @override
  String get tileLabelColor => 'Couleur de l\'étiquette';

  @override
  String get tilePreviewName => 'Exemple d\'application';

  @override
  String get tileProportions => 'Proportions des carreaux';

  @override
  String get tileLarge => 'Grand';

  @override
  String get tileLabelBelow => 'Sous la tuile';

  @override
  String get tileLabelInside => 'À l\'intérieur du carreau';

  @override
  String get tileFocusScale => 'Agrandir';

  @override
  String get tileMedium => 'Moyen';

  @override
  String get tileFocusBorder => 'Aucun mouvement';

  @override
  String get tileSize => 'Taille des carreaux';

  @override
  String get tileCompact => 'Compacte';

  @override
  String get tileLabelPosition => 'Position de l\'étiquette';

  @override
  String get tileFocusEffect => 'Effet de mise au point';

  @override
  String get tileFocusStrength => 'Intensité des reflets';

  @override
  String get panelIndependent => 'Paramètres personnalisés';

  @override
  String get panelAppearance => 'Style du panneau supérieur';

  @override
  String get panelBackground => 'Fond du panneau';

  @override
  String get blurPerformanceHint =>
      'Le flou peut réduire la fluidité. Il est désactivé lorsque la sauvegarde de la mémoire est activée.';

  @override
  String get panelOpacity => 'Opacité du panneau';

  @override
  String get tileBlur => 'Flou derrière les carreaux';

  @override
  String get panelBlur => 'Flou derrière le panneau supérieur';

  @override
  String get panelShared => 'Comme des panneaux';

  @override
  String get weatherMinutes => 'min';

  @override
  String get weatherOpenMeteoCredit =>
      'Météo : Open-Meteo (open-meteo.com), CC BY 4.0. API gratuit pour une utilisation non commerciale.';

  @override
  String get weatherRateLimit =>
      'Limite de requêtes atteinte. Essayez plus tard.';

  @override
  String get weatherYandexCredit =>
      'Météo : Météo Yandex (yandex.ru/pogoda). L\'accès dépend de votre forfait API.';

  @override
  String get yandexWeather => 'Météo Yandex (REST)';

  @override
  String get weatherAuthorizationError =>
      'Le fournisseur météo a rejeté la demande. Vérifiez la clé API et accédez au service sélectionné.';

  @override
  String get weatherYandexHint =>
      'Nécessite une clé avec accès aux prévisions REST. Une clé pour un autre plan Yandex peut ne pas fonctionner.';

  @override
  String get weatherSource => 'Source météo';

  @override
  String get weatherInterval => 'Intervalle de mise à jour';

  @override
  String get weatherLongitude => 'Longitude (-180 à 180)';

  @override
  String get weatherKeyRequired => 'Ajoutez une clé Yandex API.';

  @override
  String get weatherLocationName => 'Nom de la ville (facultatif)';

  @override
  String get weatherLocation => 'Emplacement';

  @override
  String get weatherApiKey => 'Clé Yandex API';

  @override
  String get weatherInvalidResponse =>
      'La source météo a renvoyé des données non valides.';

  @override
  String get weatherUnavailable =>
      'La météo n\'est pas disponible. Les données précédemment reçues sont conservées si elles sont disponibles. Les tentatives sont limitées à une fois toutes les 5 minutes.';

  @override
  String get weatherStale => 'Météo précédente';

  @override
  String get weatherLatitude => 'Latitude (-90 à 90)';

  @override
  String get weatherCoordinatesError =>
      'Entrez une ville manuellement ou obtenez automatiquement les coordonnées.';

  @override
  String get weatherRefresh => 'Vérifier les mises à jour';

  @override
  String get weatherKeyPrivate =>
      'Stocké uniquement sur cet appareil, exclu des sauvegardes. Une entrée vide supprime la clé.';

  @override
  String get weatherUpdated => 'Mis à jour';

  @override
  String get onlineWallpaperError =>
      'Impossible de charger cette image. Le fond d’écran précédent est conservé. Sélectionnez « Rechercher les mises à jour » pour réessayer le téléchargement.';

  @override
  String get onlineWallpaperHint =>
      'La dernière image reste disponible hors connexion (jusqu’à 8 MiB).';

  @override
  String get onlineWallpaperHours => 'h';

  @override
  String get onlineWallpaperInterval => 'Intervalle de téléchargement';

  @override
  String get onlineWallpaper => 'Fond d\'écran en ligne';

  @override
  String get onlineWallpaperUrlError =>
      'Entrez une image HTTPS directe URL sans informations de connexion.';

  @override
  String get onlineWallpaperEnabled => 'Utiliser un fond d\'écran en ligne';

  @override
  String get onlineWallpaperSource => 'Source des images';

  @override
  String get bingWallpaper => 'Bing image du jour';

  @override
  String get onlineWallpaperUrlSource => 'URL HTTPS directe';

  @override
  String get updatePlayOnly =>
      'Cette installation reçoit des mises à jour via Google Play.';

  @override
  String get updateCheck => 'Vérifiez maintenant';

  @override
  String get updateInstalled => 'Installé';

  @override
  String get updateDownloadInstall => 'Téléchargez et installez';

  @override
  String get updateNoRelease =>
      'Aucune version compatible plus récente n’est disponible.';

  @override
  String get updateIncompatible =>
      'Le APK ne correspond pas à cette application, ce certificat ou une version plus récente. L\'installation a été bloquée.';

  @override
  String get updateError =>
      'Impossible de vérifier, télécharger ou ouvrir le programme d\'installation. Réessayez plus tard.';

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String get appUpdates => 'Mises à jour des applications';

  @override
  String get updatePermission =>
      'Autorisez l\'installation à partir de cette application dans les paramètres Android, revenez ici et appuyez à nouveau sur Installer.';

  @override
  String get updateInstall => 'Installer la mise à jour téléchargée';

  @override
  String get updateHint =>
      'Source : GitHub / KirillShchetinnikov/CuteLauncher-Releases. Des vérifications automatiques s\'exécutent lorsque le lanceur est ouvert. Le téléchargement commence lorsque vous le choisissez ; Android vous demande de confirmer l\'installation. Vos données sont conservées.';

  @override
  String get updateAutomatic => 'Vérifiez automatiquement une fois par jour';

  @override
  String get allApplications => 'Toutes les candidatures';

  @override
  String get adbAccessibility => 'Activer la correction du bouton d\'accueil';

  @override
  String get adbAuthorization =>
      'Approuvez l’autorisation ADB sur le téléviseur, puis réessayez.';

  @override
  String get adbChangeConfirm =>
      'Appliquer ce paramètre système via ADB ? L\'application Home précédente est enregistrée avant de la modifier ; les autres services d’accessibilité sont préservés.';

  @override
  String get adbCheck => 'Vérifier la connexion';

  @override
  String get adbDenied =>
      'Le système n\'a pas autorisé ni confirmé ce changement.';

  @override
  String get adbDisable => 'Désactiver le lanceur précédent';

  @override
  String get adbDisableConfirm =>
      'Désactiver le lanceur précédent enregistré ? Cela nécessite que CuteLauncher soit l\'application Accueil actuelle. Restaurez-le avec l\'action de récupération dans cette configuration.';

  @override
  String get adbHint =>
      'Prototype pour ce téléviseur uniquement (127.0.0.1). Activez TCP ADB dans les options du développeur, entrez son port et approuvez la demande d\'autorisation sur le téléviseur. Le débogage sans fil avec un code d\'appairage n\'est pas encore pris en charge. La clé privée reste sur cet appareil, en dehors des sauvegardes.';

  @override
  String get adbHome => 'Faites de CuteLauncher l\'application Maison';

  @override
  String get adbInvalid => 'Saisissez un port compris entre 1024 et 65535.';

  @override
  String get adbNoRecovery =>
      'La restauration n\'est pas disponible : aucun autre état de lanceur ou de service enregistré n\'a été trouvé.';

  @override
  String get adbPort => 'Port TCP ADB';

  @override
  String get adbReady => 'Accès ADB confirmé.';

  @override
  String get adbRestore => 'Restaurer le lanceur précédent';

  @override
  String get adbSuccess => 'Modification appliquée et vérifiée.';

  @override
  String get adbTitle => 'Configuration du ADB';

  @override
  String get adbUnavailable =>
      'Impossible de se connecter. Vérifiez TCP ADB, le port et l\'invite d\'autorisation.';

  @override
  String get nightModeScheduled => 'Utiliser le calendrier';

  @override
  String get nightModeTitle => 'Mode nuit';

  @override
  String get nightModeScope =>
      'Une autorisation de superposition est nécessaire pour atténuer d\'autres applications. Sans cela, la gradation fonctionne à l\'intérieur du CuteLauncher. Le filtre TCL ne nécessite aucune autorisation de superposition. Au-dessus de 80 % d\'opacité, Android peut bloquer la saisie tactile dans d\'autres applications ; Les touches de la télécommande du téléviseur fonctionnent toujours.';

  @override
  String get nightModeEnd => 'Fin';

  @override
  String get nightModeStart => 'Commencer';

  @override
  String get nightModeDim => 'Gradation';

  @override
  String get nightModeWarmth => 'Filtre chaud';

  @override
  String get nightModeScheduleHint =>
      'Utilise l\'heure de la télévision locale. Les périodes de nuit sont prises en charge. Des heures de début et de fin égales désactivent le filtre programmé.';

  @override
  String get nightModeEnabled => 'Activer le mode nuit';

  @override
  String get nightModePermission =>
      'Autoriser l\'affichage sur d\'autres applications';

  @override
  String get nightModePermissionGranted =>
      'Affichage sur d\'autres applications autorisé';

  @override
  String get backupDownloadsFailed =>
      'Impossible d\'enregistrer la sauvegarde dans les téléchargements.';

  @override
  String get backupSaveDownloads =>
      'Enregistrer la sauvegarde dans les téléchargements';

  @override
  String get adbRestoreAccessibility => 'Restaurer l’accès à l’accessibilité';

  @override
  String get nightModeAdbConfirm =>
      'Autoriser CuteLauncher à s\'afficher sur d\'autres applications à l\'aide du ADB local ? Activez d\'abord le débogage TCP et autorisez la connexion. Utilise le port enregistré dans l\'assistant ADB, ou 5555.';

  @override
  String get nightModeAdbPermission => 'Accorder l\'autorisation via ADB';

  @override
  String get nightModeNotificationsHint =>
      'La notification vous permet de désactiver le filtre en dehors de CuteLauncher. Sans cela, utilisez ce menu.';

  @override
  String get nightModeNotificationsAllowed =>
      'Notification en mode nuit autorisée';

  @override
  String get nightModeNotifications => 'Autoriser la notification en mode nuit';

  @override
  String get categoryLastVisibleHint =>
      'Au moins une catégorie doit rester visible.';

  @override
  String get diagnosticsClear => 'Effacer les diagnostics de session';

  @override
  String get diagnosticsReady => 'Rapport prêt';

  @override
  String get diagnosticsCreate => 'Créer un rapport';

  @override
  String get diagnosticsOperations => 'Opérations enregistrées';

  @override
  String get diagnosticsCopied => 'Rapport copié';

  @override
  String get diagnosticsHint =>
      'Le rapport contient la version de l\'application, l\'état des autorisations, l\'utilisation de la mémoire et les résultats des opérations. Il exclut les clés, les adresses, les chemins de fichiers, les listes d\'applications et le contenu des notifications. Seules les 50 dernières opérations sont conservées en mémoire jusqu\'au redémarrage de l\'application. Rien n\'est envoyé automatiquement.';

  @override
  String get diagnosticsTitle => 'Diagnostic d\'erreur';

  @override
  String get diagnosticsCopyFailed => 'Impossible de copier le rapport.';

  @override
  String get diagnosticsCopy => 'Copier le rapport';

  @override
  String get diagnosticsCreating => 'Création du rapport…';

  @override
  String get tclBlueLightTitle => 'Filtre de lumière bleue TCL';

  @override
  String get tclBlueLightError =>
      'Impossible de lire ou de vérifier le paramètre de filtre TCL. Actualisez son état et réessayez.';

  @override
  String get tclBlueLightUnsupported =>
      'L\'interface de filtre TCL n\'est pas disponible sur ce téléviseur.';

  @override
  String get tclBlueLightRefresh => 'Actualiser l\'état du filtre TCL';

  @override
  String get tclBlueLightHint =>
      'Contrôle le filtre de protection de la santé oculaire intégré du téléviseur. Il peut également suivre le planning du mode nuit.';

  @override
  String get nightSolarSchedule => 'Coucher et lever de soleil';

  @override
  String get nightNextStart => 'Prochain démarrage';

  @override
  String get nightScheduleTimeHint =>
      'Les horaires utilisent le fuseau horaire du téléviseur. Les compensations négatives sont plus précoces ; les compensations positives sont plus tardives.';

  @override
  String get nightTemperature => 'Température de couleur du filtre';

  @override
  String get nightScheduleSettings => 'Paramètres de planification';

  @override
  String get nightCityName => 'Nom de la ville';

  @override
  String get nightSkipUntilNext =>
      'Désactivez le mode nuit jusqu\'au prochain coucher de soleil';

  @override
  String get nightSunriseOffset => 'Fin par rapport au lever du soleil';

  @override
  String get nightEnableUntilMorning =>
      'Activer le mode nuit jusqu\'au prochain lever du soleil';

  @override
  String get nightPermissions => 'Autorisations';

  @override
  String get nightTclSchedule => 'Inclure le filtre TCL dans le calendrier';

  @override
  String get nightSearchCity => 'Rechercher';

  @override
  String get nightRefreshSun => 'Rafraîchir le lever et le coucher du soleil';

  @override
  String get nightSolarUnavailable =>
      'Choisissez une ville et rafraîchissez les heures d\'ensoleillement. Si le lever ou le coucher du soleil n\'est pas disponible, le programme solaire s\'interrompt.';

  @override
  String get nightSunsetOffset => 'Commencer par rapport au coucher du soleil';

  @override
  String get nightCityHint =>
      'Choisissez votre ville au lieu d\'accorder l\'accès à la localisation. Les coordonnées sélectionnées sont envoyées à Sunrise-Sunset.org, ou Open-Meteo comme solution de secours, pour récupérer les heures d\'ensoleillement.';

  @override
  String get nightResumeSchedule => 'Retour au planning';

  @override
  String get nightScheduleSource => 'Type d\'horaire';

  @override
  String get nightSolarCached =>
      'Utilisation des heures d\'ensoleillement mises en cache ; L\'actualisation Internet réessayera automatiquement.';

  @override
  String get nightTclScheduleHint =>
      'Utilise le même programme lorsque le mode nuit est activé. Les modifications manuelles apportées au filtre TCL durent jusqu\'à la prochaine transition planifiée. Aucune autorisation de superposition n’est nécessaire.';

  @override
  String get nightRefreshPermission => 'Actualiser l\'état de l\'autorisation';

  @override
  String get nightCityNotFound => 'Aucune ville trouvée. Essayez un autre nom.';

  @override
  String get nightNoOffset => 'Pas de décalage';

  @override
  String get nightManualSchedule => 'Horaire personnalisé';

  @override
  String get nightChooseCity => 'Choisir la ville';

  @override
  String get nightPermissionUnknown =>
      'L\'état de l\'autorisation de superposition est inconnu';

  @override
  String get nightNextEnd => 'Fin suivante';

  @override
  String get nightTemporaryOff =>
      'Gradation temporairement désactivée jusqu\'à';

  @override
  String get nightCitySearchFailed =>
      'Impossible de rechercher des villes. Vérifiez votre connexion Internet.';

  @override
  String get nightSolarAttribution =>
      'Horaires d\'ensoleillement quotidiens : Sunrise-Sunset.org ; solution de secours : Open-Meteo. Recherche de ville : GeoNames. Plusieurs jours sont mis en cache pour une utilisation hors ligne.';

  @override
  String get nightTemporaryOn => 'Allumage temporaire jusqu\'à ce que';

  @override
  String get homeScreen => 'Écran d\'accueil';

  @override
  String get appearanceSettings => 'Apparence';

  @override
  String get generalSettings => 'Avancé';

  @override
  String get advancedSettings => 'Avancé';

  @override
  String get controlAndStartup => 'Commandes du lanceur et du téléviseur';

  @override
  String get sectionsAndOrder => 'Sections et ordre';

  @override
  String get topPanel => 'Panneau supérieur';

  @override
  String get tileStyle => 'Style de carrelage';

  @override
  String get tilesAndLabels => 'Carreaux et étiquettes';

  @override
  String get highlightAndAnimation => 'Mise en lumière et animation';

  @override
  String get androidTvSettings => 'Paramètres Android TV';

  @override
  String get weatherSettings => 'Paramètres météo';

  @override
  String get showHighlightOutline => 'Afficher le contour des surbrillance';

  @override
  String get resetTilesAndPanel =>
      'Réinitialiser les paramètres des vignettes et des panneaux';

  @override
  String get resetTilesAndPanelHint =>
      'Réinitialiser les paramètres supplémentaires des vignettes, des étiquettes, des surbrillance et du panneau supérieur ? Le papier peint, la couleur d’accentuation, le style de carrelage et la visibilité des étiquettes sont préservés.';

  @override
  String get panelAppearanceSettings => 'Apparence du panneau supérieur';

  @override
  String get panelSharedHint =>
      'Modifiez l\'apparence dans les paramètres des vignettes.';

  @override
  String get effectsCompatibilityHint =>
      'Aspect supplémentaire : le contour est toujours visible et ne pulse pas. Le style dimensionnel n’a pas de contour hérité ; le classique ne pulse pas. L\'intensité affecte l\'échelle et l\'ombre ; la mise à l’échelle est limitée en espace.';

  @override
  String get sizeAndLayout => 'Taille et disposition';

  @override
  String get labelsGroup => 'Étiquettes';

  @override
  String get surfaceGroup => 'Surface';

  @override
  String get clockAndDateGroup => 'Horloge et date';

  @override
  String get networkAndTrafficGroup => 'Réseau et trafic';

  @override
  String get buttonsGroup => 'Boutons';

  @override
  String get notificationAppsHint =>
      'Désactivez les applications dont vous n\'avez pas besoin des notifications. Un commutateur activé permet les notifications ; l\'application peut toujours être lancée.';

  @override
  String get notificationPanelLink => 'Apparence du panneau supérieur';

  @override
  String get overlayAccessAdb => 'Afficher sur d\'autres applications (ADB)';

  @override
  String get tileStyleModern => 'Moderne';

  @override
  String get tileStyleVolume => 'Dimensionnel';

  @override
  String get showTime => 'Afficher l\'heure';

  @override
  String get showDate => 'Afficher la date';

  @override
  String get showWeather => 'Afficher la météo';

  @override
  String get showNetwork => 'Afficher l\'état du réseau';

  @override
  String get showTraffic => 'Afficher le trafic';

  @override
  String get scheduledBrightness => 'Luminosité programmée';

  @override
  String get followTileStyle => 'Suivre le style';

  @override
  String get androidTvSettingsHint => 'Ouvrez les paramètres du système TV';

  @override
  String get autoHideTopPanel => 'Masquer automatiquement le panneau';

  @override
  String get showSectionTitles => 'Afficher les titres des sections';

  @override
  String get usageDaily => 'Quotidiennement';

  @override
  String get usageWeekly => 'Hebdomadaire';

  @override
  String get usageMonthly => 'Mensuel';

  @override
  String get onlineWallpaperAddress => 'Adresse de l\'image (HTTPS)';

  @override
  String get watchNextAppLimits => 'Limites par application';

  @override
  String get watchNextAppLimitsHint =>
      'Les limites de source s’appliquent avant la limite globale. Unlimited ne conserve que la limite globale ; le contenu caché reste caché.';

  @override
  String get rememberCategoryFocus => 'Rappelez-vous la dernière carte ciblée';

  @override
  String get automaticBackups => 'Sauvegarde automatique';

  @override
  String get automaticBackupsHint =>
      'Copies quotidiennes des paramètres, des fonds d\'écran et des bannières pendant que le lanceur est actif. Une copie manquée s\'exécute après le retour au lanceur. Stocké en privé sur cet appareil, jusqu\'à 256 MiB au total ; la suppression de l\'application ou de ses données les supprime. Conservez également une sauvegarde externe.';

  @override
  String get automaticBackupsEnabled => 'Sauvegarde automatique quotidienne';

  @override
  String get automaticBackupsKeep => 'Copies à conserver';

  @override
  String get automaticBackupCreateNow =>
      'Créez un point de restauration maintenant';

  @override
  String get automaticBackupFailed =>
      'L\'opération de sauvegarde a échoué. Vérifiez l\'espace libre et réessayez.';

  @override
  String get restorePoints => 'Points de restauration';

  @override
  String get noRestorePoints => 'Pas encore de points de restauration';

  @override
  String get updatePrereleases => 'Installer les préversions';

  @override
  String get topPanelObjects => 'Objets';

  @override
  String get panelTransparency => 'Transparence du panneau';

  @override
  String get panelTextBackground => 'Fond de texte et de bouton';

  @override
  String get panelTextBackgroundColor =>
      'Couleur d’arrière-plan du texte et des boutons';

  @override
  String get panelTextColor => 'Couleur du texte et des boutons';

  @override
  String get panelTextSize => 'Taille du texte et des boutons';

  @override
  String get panelFont => 'Police du texte';

  @override
  String get fontSans => 'Sans empattements';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontMono => 'Monospace';

  @override
  String get fontCondensed => 'Condensé';

  @override
  String get trafficPermissionGranted =>
      'Accès aux statistiques de trafic accordé';

  @override
  String get background => 'Contexte';

  @override
  String get backgroundParameters => 'Paramètres';

  @override
  String get resetAppearanceHint =>
      'Réinitialiser l\'arrière-plan, l\'accent, les vignettes, les étiquettes, la mise en surbrillance et l\'animation ?';

  @override
  String get wallpaperDimming => 'Gradation';

  @override
  String get wallpaperPlacement => 'Emplacement';

  @override
  String get wallpaperDisplay => 'Affichage du papier peint';

  @override
  String get wallpaperContain => 'Afficher l\'image entière';

  @override
  String get wallpaperBlurred => 'Sur une copie floue';

  @override
  String get wallpaperCover => 'Remplir l\'écran';

  @override
  String get wallpaperBrightness => 'Luminosité du papier peint';

  @override
  String get wallpaperSaturation => 'Saturation';

  @override
  String get categoryPadding => 'Remplissage de catégorie';

  @override
  String get categoryLight => 'Lumière';

  @override
  String get categoryBlue => 'Bleu';

  @override
  String get categoryPurple => 'Violet';

  @override
  String get categoryAllRows => 'Tout';

  @override
  String get categoryTeal => 'Sarcelle';

  @override
  String get categoryMaxRows => 'Lignes de grille visibles';

  @override
  String get categoryDark => 'Sombre';

  @override
  String get categoryAppearance => 'Apparition de la catégorie';

  @override
  String get categoryBackground => 'Contexte de la catégorie';

  @override
  String get categoryTransparent => 'Transparente';

  @override
  String get slideshowInterval => 'Changer l\'intervalle';

  @override
  String get slideshowFolderSelected =>
      'Accès aux dossiers enregistré sur cet appareil.';

  @override
  String get slideshowRandom => 'Ordre aléatoire';

  @override
  String get wallpaperSlideshow => 'Diaporama de dossiers';

  @override
  String get slideshowNext => 'Image suivante';

  @override
  String get slideshowFolderRequired =>
      'Choisissez un dossier pour démarrer le diaporama.';

  @override
  String get slideshowHint =>
      'Jusqu\'à 1 000 images et 4 000 entrées de dossier ; fichiers jusqu\'à 8 MiB. Les fichiers corrompus sont ignorés et la dernière bonne image est conservée. Les modifications s\'arrêtent en arrière-plan. Choisissez à nouveau le dossier après la restauration sur un autre appareil.';

  @override
  String get slideshowSeconds => 's';

  @override
  String get slideshowError =>
      'Impossible de lire les images. Choisissez un dossier accessible contenant des images valides.';

  @override
  String get slideshowFolder => 'Choisir un dossier';

  @override
  String get slideshowRecursive => 'Inclure les sous-dossiers';

  @override
  String get weatherSourceKeyRequired =>
      'Ajoutez une clé API pour cette source météo.';

  @override
  String get weatherOpenWeatherCredit =>
      'Météo : OpenWeather (openweathermap.org). Les valeurs quotidiennes résument les périodes de prévision de trois heures disponibles.';

  @override
  String get weatherOpenWeatherHint =>
      'Utilisez votre clé pour la météo actuelle et les prévisions sur 5 jours/3 heures. Chaque mise à jour effectue deux requêtes ; l’accès et les limites dépendent de votre forfait.';

  @override
  String get weatherOpenWeatherKey => 'Clé OpenWeather API';

  @override
  String get mediaPause => 'Pause';

  @override
  String get showNowPlaying => 'Afficher En cours de lecture sur Accueil';

  @override
  String get nowPlayingAccessHint =>
      'Les contrôles multimédia nécessitent un accès aux notifications pour CuteLauncher. Seules les actions fournies par le joueur sont affichées.';

  @override
  String get nowPlaying => 'Je joue en ce moment';

  @override
  String get mediaNext => 'Piste suivante';

  @override
  String get mediaPlay => 'CV';

  @override
  String get mediaControlError =>
      'Le joueur n\'est pas disponible ou n\'a pas accepté cette action.';

  @override
  String get nightUsageAccess => 'Autoriser l\'accès à l\'utilisation';

  @override
  String get nightExcludedAppsHint =>
      'La superposition et le filtre TCL programmé s\'arrêtent dans les applications sélectionnées. L\'accès à l\'utilisation est requis ; sans cela, les exclusions ne peuvent pas être appliquées.';

  @override
  String get nightExcludedApps => 'Applications exclues';

  @override
  String get adbPairPort => 'Port d\'appariement';

  @override
  String get adbPairOverlayHint =>
      'Ouvrez le débogage sans fil et associez-le au code d\'appairage. Gardez la boîte de dialogue du code système ouverte. Ce formulaire devient actif après 30 secondes. Entrez les deux ports et le code affiché par Android.';

  @override
  String get adbOverlaySettings =>
      'Reprenez le contrôle sur Paramètres pendant 30 secondes';

  @override
  String get adbTlsHint =>
      'Utilisez le débogage sans fil dans les options du développeur. L\'appairage et la connexion ont des ports différents. Si votre micrologiciel n\'a pas d\'écran de code d\'appairage ou bloque les fenêtres de superposition, utilisez plutôt TCP/RSA. Toutes les connexions restent locales sur ce téléviseur.';

  @override
  String get adbPaired =>
      'Jumelé. Vérifiez la connexion à l\'aide du port de connexion de débogage sans fil.';

  @override
  String get adbTransport => 'Méthode de connexion';

  @override
  String get adbPairCode => 'Code à six chiffres';

  @override
  String get adbOverlayRequired =>
      'La saisie du code dans les paramètres nécessite l\'autorisation de s\'afficher sur d\'autres applications.';

  @override
  String get adbOverlayPermission =>
      'Autoriser l\'affichage sur d\'autres applications';

  @override
  String get adbTlsUnsupported =>
      'Ce micrologiciel ne peut pas ouvrir l\'écran Paramètres requis ou la superposition de couplage. Utilisez TCP/RSA.';

  @override
  String get adbConnectPort => 'Port de connexion';

  @override
  String get adbTls => 'TLS/code de couplage';

  @override
  String get adbTcp => 'TCP/RSA';

  @override
  String get adbPairingFailed =>
      'Le couplage a échoué. Vérifiez le code et le port d\'appairage, laissez la boîte de dialogue du code Android ouverte et réessayez.';

  @override
  String get adbTlsDisabled =>
      'Le débogage sans fil est désactivé ou son état est indisponible. Activez-le dans les options du développeur.';

  @override
  String get adbPairOverlay => 'Entrez le code d\'appairage dans Paramètres';

  @override
  String get adbPair => 'Paire';

  @override
  String get adbDeveloperSettings => 'Ouvrir les options du développeur';

  @override
  String get adbTwoWindowsHint =>
      'Si ce firmware prend en charge deux fenêtres, laissez la boîte de dialogue de couplage du système ouverte à côté de CuteLauncher et entrez son code ici. L\'appairage direct est disponible uniquement lorsque les deux fenêtres sont ouvertes.';

  @override
  String get adbTwoWindows => 'Ouvrez les paramètres dans une deuxième fenêtre';

  @override
  String get autoLaunchBoot => 'Après le démarrage du téléviseur';

  @override
  String get autoLaunchOff => 'Désactivé';

  @override
  String get autoLaunchTitle => 'Démarrage automatique';

  @override
  String get autoLaunchDelay => 'Retard de lancement';

  @override
  String get autoLaunchHdmi => 'Basculer vers une entrée HDMI sélectionnée';

  @override
  String get autoLaunchWake => 'Après le réveil';

  @override
  String get autoLaunchHint =>
      'Choisissez une application ou une entrée HDMI à ouvrir après le démarrage ou le réveil du téléviseur. Définissez l\'événement et le délai ci-dessous. L\'action s\'exécute une fois lorsque Android affiche CuteLauncher. Toute saisie à distance ou sortie de l’écran d’accueil annule l’attente. Vous pouvez ensuite modifier librement les entrées du HDMI. Définissez CuteLauncher comme lanceur par défaut ou activez Démarrer au démarrage si nécessaire. La détection de réveil nécessite que CuteLauncher continue de fonctionner.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds secondes';
  }

  @override
  String get autoLaunchApp => 'Ouvrir une application sélectionnée';

  @override
  String get autoLaunchTarget => 'Objectif de lancement';

  @override
  String get autoLaunchUnavailable =>
      'La cible n\'est pas disponible ou le firmware ne permet pas cette action.';

  @override
  String get autoLaunchCancelled => 'Lancement retardé annulé.';

  @override
  String get syncTitle => 'Paramètres d\'échange';

  @override
  String get syncHint =>
      'Enregistrez un fichier de paramètres, transférez-le sur un autre appareil et ouvrez-le là. Échangez le fichier pour mettre les deux appareils à jour. L’interface, le style de vignette et les préférences d’affichage sont partagés. Les applications, sections, fichiers de fond d\'écran, autorisations, HOME, règles de lancement et secrets restent sur cet appareil. Il s\'agit d\'un échange manuel ; aucun compte ou connexion réseau en arrière-plan n’est utilisé.';

  @override
  String get syncExport => 'Enregistrer les modifications dans un fichier';

  @override
  String get syncImport => 'Ouvrir les modifications depuis un autre appareil';

  @override
  String get syncSaved => 'Fichier d\'échange de paramètres enregistré.';

  @override
  String get syncFailed =>
      'Impossible d\'échanger les paramètres. Aucune importation partielle n\'est conservée. Vérifiez le fichier ou ouvrez-le à nouveau si les paramètres ont été modifiés lors de l\'examen.';

  @override
  String get syncPreviewHint =>
      'Examinez les modifications avant de postuler. En cas de conflits, sélectionnez chaque ligne pour choisir ce périphérique ou le fichier. La conservation de cet appareil est sélectionnée dans un premier temps. Annuler laisse les paramètres inchangés.';

  @override
  String get syncNoChanges =>
      'Pas de nouveaux paramètres. Postulez pour reconnaître l’historique partagé.';

  @override
  String syncLocalValue(String value) {
    return 'Cet appareil : $value';
  }

  @override
  String syncFileValue(String value) {
    return 'À partir du fichier : $value';
  }

  @override
  String get syncKeepLocal => 'Conflit : conserver cet appareil';

  @override
  String get syncUseFile => 'Conflit : utiliser le fichier';

  @override
  String get syncApply => 'Appliquer les modifications révisées';

  @override
  String get syncApplied =>
      'Paramètres échangés. Enregistrez un nouveau fichier pour renvoyer le résultat.';

  @override
  String syncStyleParameters(int count) {
    return 'Style personnalisé : $count paramètres (différences ci-dessous)';
  }

  @override
  String get cloudBackups => 'Sauvegardes cloud';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud. Saisissez l\'adresse HTTPS d\'un dossier existant et un mot de passe d\'application. Les transferts sont manuels ; ce dossier stocke la dernière copie.';

  @override
  String get cloudUrl => 'Adresse du dossier HTTPS';

  @override
  String get cloudUser => 'Nom d\'utilisateur';

  @override
  String get cloudPassword => 'Mot de passe de l\'application';

  @override
  String get cloudConnect => 'Vérifier et sauvegarder le compte';

  @override
  String get cloudCheck => 'Vérifier la connexion';

  @override
  String get cloudDisconnect => 'Déconnecter le compte';

  @override
  String get cloudDisconnectConfirm =>
      'Supprimer ce compte du téléviseur ? Les copies dans le cloud resteront.';

  @override
  String get cloudUpload => 'Enregistrer une copie dans le cloud';

  @override
  String get cloudDownload => 'Restaurer depuis le cloud';

  @override
  String get cloudUploadConfirm =>
      'Remplacer cutelauncher_backup.json dans ce dossier par les paramètres et données actuels ?';

  @override
  String get cloudSuccess => 'Terminé';

  @override
  String get cloudConfigurationError =>
      'Vérifiez l\'adresse du dossier HTTPS, le nom d\'utilisateur et le mot de passe de l\'application.';

  @override
  String get cloudAuthorizationError =>
      'Accès refusé. Vérifiez les autorisations de votre compte et de votre dossier.';

  @override
  String get cloudMissingError =>
      'Le dossier ou la sauvegarde est introuvable.';

  @override
  String get cloudUnsupportedError =>
      'Cette adresse ne prend pas en charge les opérations WebDAV requises. Les redirections ne sont pas suivies ; entrez l’adresse finale du dossier.';

  @override
  String get cloudNetworkError =>
      'La connexion a échoué ou a expiré. Réessayez lorsque le réseau est disponible.';

  @override
  String get cloudFailed =>
      'Impossible de terminer l\'action de sauvegarde. Vérifiez l\'accès au stockage et réessayez.';

  @override
  String get cloudStorageError =>
      'Le stockage du compte n\'est pas disponible. Déconnectez-vous et configurez à nouveau le compte.';

  @override
  String get adbPermissionChecking => 'Vérification de l\'accès…';

  @override
  String get adbPermissionConnected =>
      'ADB connecté · accorder l\'autorisation';

  @override
  String get adbPermissionDisconnected =>
      'ADB déconnecté · établir la connexion';

  @override
  String get adbSetupIntro =>
      'Activez le débogage et le réseau ADB dans les paramètres du développeur TV, puis faites confiance à CuteLauncher. Toutes les actions ADB sont à vos propres risques.';

  @override
  String get adbConnectionBlock => 'Connexion ADB';

  @override
  String get adbNotChecked => 'Connexion non vérifiée';

  @override
  String get adbApplied => 'Déjà postulé';

  @override
  String get adbNotApplied => 'Pas encore appliqué';

  @override
  String get adbDefaultBlock => 'Lanceur par défaut';

  @override
  String get adbSystemDefault =>
      'Paramètres du lanceur par défaut du système ouvert';

  @override
  String get adbAssignDefault =>
      'Définir CuteLauncher comme lanceur par défaut via ADB';

  @override
  String get adbRestoreDefault =>
      'Restaurer le lanceur par défaut précédent via ADB';

  @override
  String get adbDefaultHint =>
      'Utilisez ADB si le menu système ne parvient pas à définir le lanceur par défaut.';

  @override
  String get adbBuiltinHint =>
      'La désactivation du lanceur intégré permet au système d\'ouvrir CuteLauncher à la place. Les menus et les boutons du téléviseur peuvent être affectés. Activez le lanceur intégré pour annuler cette opération.';

  @override
  String get adbHomeBlock => 'Bouton d\'accueil et démarrage';

  @override
  String get adbEnableService =>
      'Activer le service d\'accessibilité CuteLauncher via ADB';

  @override
  String get adbHomeOverride => 'Remplacer le bouton Accueil';

  @override
  String get adbHomeOptional =>
      'Si le lanceur intégré est désactivé, le remplacement de l\'accueil et le lancement au démarrage du téléviseur sont facultatifs.';

  @override
  String get adbEnableBuiltin => 'Activer le lanceur intégré via ADB';

  @override
  String get adbDisableBuiltin => 'Désactiver le lanceur intégré via ADB';

  @override
  String get adbNoBuiltin =>
      'Aucun lanceur Google TV / Android TV intégré trouvé.';

  @override
  String get adbChanged =>
      'L\'état a changé. Vérifiez la connexion et confirmez à nouveau l\'action.';

  @override
  String get adbEffectHome =>
      'CuteLauncher deviendra le lanceur par défaut du système. Le lanceur actuel sera enregistré pour la restauration.';

  @override
  String get adbEffectRestore =>
      'Le lanceur précédent sera activé et défini par défaut. S\'il n\'est pas disponible ou n\'est pas enregistré, le premier autre lanceur disponible est sélectionné. Cela ne désactive pas la correction du bouton d\'accueil.';

  @override
  String get adbEffectDisable =>
      'L\'application de lancement intégrée sera désactivée pour l\'utilisateur du téléviseur. Les menus et les boutons du téléviseur peuvent cesser de fonctionner. L\'application n\'est pas désinstallée.';

  @override
  String get adbRecoveryHomeDisable =>
      'L\'intégralité de l\'assistant de configuration de Google TV, y compris son écran d\'accueil de récupération, sera également désactivée afin que CuteLauncher puisse devenir le lanceur par défaut. Les fonctionnalités de l\'assistant d\'installation ne seront pas disponibles jusqu\'à la restauration. Les états d\'origine des deux packages seront enregistrés pour la restauration.';

  @override
  String get adbRecoveryHomeRestore =>
      'L\'assistant de configuration du Google TV reviendra également à son état enregistré.';

  @override
  String get adbDisableHomeUnavailable =>
      'Un autre écran d\'accueil a une priorité plus élevée. Il ne peut pas être désactivé en toute sécurité par ce lanceur.';

  @override
  String get adbEffectEnable =>
      'Le lanceur intégré sera restauré à son état enregistré ou activé si aucun état n\'a été enregistré. Le système peut le sélectionner à nouveau comme lanceur par défaut.';

  @override
  String get adbEffectAccessibility =>
      'Le service d’accessibilité CuteLauncher sera activé. Il peut recevoir des événements Home ; l\'interception est contrôlée par un interrupteur séparé. Les autres services sont conservés.';

  @override
  String get adbEffectAccessibilityRestore =>
      'Le service CuteLauncher reviendra à son état avant l\'octroi de l\'accès à ADB. Les autres services d’accessibilité sont conservés.';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher sera autorisé à afficher des fenêtres sur d\'autres applications, y compris le filtre de nuit.';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher recevra un accès aux notifications via son propre service d\'écoute.';

  @override
  String get adbEffectWatchNext =>
      'CuteLauncher aura accès à Continuer à regarder les données.';

  @override
  String get adbEffectUsage =>
      'CuteLauncher recevra un accès aux statistiques d\'utilisation pour la détection du trafic et des applications de premier plan.';

  @override
  String get adbEffectWriteSettings =>
      'CuteLauncher sera autorisé à modifier les paramètres de luminosité du système.';

  @override
  String get adbNoAvailableLauncher =>
      'Aucun autre lanceur installé n\'a été trouvé. La restauration n\'est pas disponible.';

  @override
  String get adbUnsupported =>
      'Indisponible sur cet appareil : aucune commande ADB prise en charge.';

  @override
  String get adbHomeUnavailable =>
      'Le lanceur intégré a la priorité système. L\'affectation directe via ADB n\'est pas disponible ; utilisez l\'accessibilité ou désactivez le lanceur intégré.';

  @override
  String get nightBatteryExempt => 'CuteLauncher est exempté d\'optimisation';

  @override
  String get nightBatteryHint =>
      'Peut aider le planning à s\'exécuter en arrière-plan. Ne garantit pas que le processus survivra à la veille.';

  @override
  String get nightBatteryOptimized => 'CuteLauncher est sujet à optimisation';

  @override
  String get nightBatteryTitle => 'Optimisation de la batterie';

  @override
  String get nightBatteryUnavailable =>
      'Les paramètres système ne sont pas disponibles sur ce micrologiciel ou l\'accès a été refusé.';

  @override
  String get nightBatteryUnknown => 'Statut d\'exonération inconnu';

  @override
  String get nightBatteryOpenApps => 'Ouvrir les paramètres des applications';

  @override
  String get nightBatteryGuide =>
      '1. Dans les paramètres des applications, ouvrez Accès spécial aux applications.\n2. Sélectionnez Optimisation de la batterie (parfois Économiseur d\'énergie).\n3. Recherchez CuteLauncher ; sélectionnez Toutes les applications si nécessaire.\n4. Désactivez l\'optimisation ou sélectionnez Sans restriction.\nLes noms des menus et leur disponibilité dépendent du micrologiciel du téléviseur.';

  @override
  String get updateNotifications => 'Afficher les notifications de mise à jour';

  @override
  String get diagnosticsSave => 'Enregistrer le rapport dans un fichier';

  @override
  String get diagnosticsSaved => 'Rapport enregistré';

  @override
  String get diagnosticsSaveFailed =>
      'Impossible d\'enregistrer le rapport. Vérifiez le gestionnaire de fichiers et le dossier de destination.';

  @override
  String get memoryCacheSize => 'Taille du cache d\'images';

  @override
  String get memoryProcess => 'Mémoire d\'application';

  @override
  String get memoryImages => 'Caches d\'images';

  @override
  String get diagnosticsExportOpened =>
      'Choisissez un dossier dans le gestionnaire de fichiers et enregistrez le rapport.';

  @override
  String get adbDisableService =>
      'Désactiver le service d\'accessibilité CuteLauncher via ADB';

  @override
  String get adbDefaultSettings => 'Paramètres du lanceur par défaut';

  @override
  String get adbHomeSettings => 'Paramètres du bouton d\'accueil';

  @override
  String get adbAccessibilitySettings =>
      'Ouvrir les paramètres d\'accessibilité';

  @override
  String get adbAccessibilityGuide =>
      'Sélectionnez CuteLauncher dans le menu système et activez son service. Revenez ici pour configurer l\'interception à domicile. Pour le désactiver, désactivez le service CuteLauncher dans le même menu.';

  @override
  String get adbEffectAccessibilityDisable =>
      'Le service CuteLauncher sera désactivé. L\'interception à domicile s\'arrêtera. Les autres services d’accessibilité sont conservés.';

  @override
  String get backupAutoEnabled => 'Sauvegarde automatique';

  @override
  String get backupClientId => 'Identifiant client';

  @override
  String get backupClientSecret => 'Secret client';

  @override
  String get backupCloudImportConfirm =>
      'Tous les paramètres locaux, catégories et images seront remplacés par des données cloud. Continuer?';

  @override
  String get backupConfigured => 'Configuré';

  @override
  String get backupConnection => 'Paramètres de connexion';

  @override
  String get backupCreated => 'Créé';

  @override
  String get backupDaily => 'Quotidiennement';

  @override
  String get backupDriveHelp =>
      'Sélectionnez Connecter et confirmez le code sur votre téléphone. Les sauvegardes sont visibles dans le dossier CuteLauncher de Google Drive, où vous pouvez les télécharger ou les supprimer. Conservez les noms de fichiers inchangés pour la restauration dans l\'application. Reconnectez-vous après la mise à niveau à partir des sauvegardes cachées ; les anciennes sauvegardes ne sont pas migrées automatiquement.';

  @override
  String get backupFrequency => 'Fréquence de sauvegarde';

  @override
  String get backupHourly => 'Horaire';

  @override
  String get backupLocal => 'Copies locales';

  @override
  String get backupMinutes => 'min';

  @override
  String get backupMode => 'Mode';

  @override
  String get backupNever => 'Pas encore de sauvegarde';

  @override
  String get backupNotConfigured => 'Non configuré';

  @override
  String get backupOptions => 'Options de sauvegarde';

  @override
  String get backupSaveMode => 'Sauvegarde';

  @override
  String get backupScope => 'Sauvegarde sur tous les téléviseurs';

  @override
  String get backupSyncScope => 'Synchronisation entre les téléviseurs';

  @override
  String get backupSeparate => 'Séparé pour chaque téléviseur';

  @override
  String get backupShared => 'Mêmes paramètres pour tous les téléviseurs';

  @override
  String get backupStorage => 'Stockage';

  @override
  String get backupSyncHelp =>
      'Téléchargez les données et téléchargez les modifications. Le dernier changement gagne les conflits. Les horloges de la télévision doivent être correctes. La synchronisation s\'exécute lorsque le lanceur est ouvert.';

  @override
  String get backupSyncLimit => 'Ne vérifiez pas plus souvent que';

  @override
  String get backupSyncMode => 'Synchronisation';

  @override
  String get backupSyncOptions => 'Options de synchronisation';

  @override
  String get backupTime => 'Temps de sauvegarde';

  @override
  String get backupWeekday => 'Jour de la semaine';

  @override
  String get backupWeekly => 'Hebdomadaire';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'Les copies locales sont supprimées avec l\'application ou ses données. Conservez également une copie à l’extérieur du téléviseur.';

  @override
  String get panelObjectOrder => 'Ordre des objets';

  @override
  String get panelInformationGroup => 'Informations';

  @override
  String get panelOrderHint =>
      '◄ / ► commence ou termine le déplacement ; ▲ / ▼ change l’ordre et passe de l’autre côté à la limite des groupes ; OK / Retour termine.';

  @override
  String get panelTextBackgroundTransparency =>
      'Transparence de l’arrière-plan du texte et des boutons';

  @override
  String get weatherCityHint =>
      'Saisissez le nom de la ville en anglais, par exemple Moscou.';

  @override
  String get weatherCityNotFound =>
      'Ville introuvable. Vérifiez le nom de la ville en anglais.';

  @override
  String get weatherLocationAutomatic => 'Obtenez automatiquement';

  @override
  String get weatherLocationAutomaticHint =>
      'Obtenez les coordonnées de l\'appareil. Une autorisation de localisation est requise.';

  @override
  String get weatherLocationManual => 'Entrez manuellement';

  @override
  String get weatherLocationPermissionDenied =>
      'Autorisez l\'accès à la localisation dans les paramètres Android et réessayez.';

  @override
  String get weatherLocationUnavailable =>
      'Impossible d\'obtenir les coordonnées. Vérifiez les paramètres de localisation du Android ou saisissez une ville manuellement.';

  @override
  String get nightFilterSettings => 'Paramètres de filtre';

  @override
  String get nightScheduleMenu => 'Calendrier';

  @override
  String get nightScheduleInactive => 'L\'horaire est désactivé';

  @override
  String get nightLocation => 'Emplacement';

  @override
  String get nightLocationAutomatic => 'Obtenez automatiquement';

  @override
  String get nightLocationManual => 'Entrez manuellement';

  @override
  String get nightLocationFailed =>
      'Emplacement indisponible. Vérifiez les paramètres d’autorisation et d’emplacement du système.';

  @override
  String get nightCityEnglish => 'Entrez le nom de la ville en anglais';

  @override
  String get nightOverlayBrief =>
      'Permet au filtre d\'apparaître sur d\'autres applications.';

  @override
  String get weatherGetLocation => 'Obtenir l\'emplacement';

  @override
  String get backupLastCreated => 'La dernière sauvegarde a été créée :';

  @override
  String get backupManagement => 'Gérer les sauvegardes';

  @override
  String get backupCopyList => 'Liste de sauvegarde';

  @override
  String get backupRefreshCopyList => 'Actualiser la liste de sauvegarde';

  @override
  String get backupCreateNow => 'Créez une nouvelle sauvegarde maintenant';

  @override
  String get backupFolderPath => 'Dossier de sauvegarde';

  @override
  String get backupPrivateFolder => 'Dossier de candidature privé';

  @override
  String get backupRestoreCopy => 'Restaurer cette sauvegarde';

  @override
  String get backupDeleteConfirm => 'Supprimer la sauvegarde sélectionnée ?';

  @override
  String get blockedAppsGroup => 'Applications bloquées';

  @override
  String get notificationSettingsButton => 'Paramètres de notification';

  @override
  String get hidePersistentNotificationsHint =>
      'Masquez les notifications persistantes dans la liste et sur d\'autres applications.';

  @override
  String get nightTransitionTime => 'Temps de transition';

  @override
  String get brightnessSolar => 'Utiliser la programmation du mode nuit';

  @override
  String get brightnessAfterSunrise => 'Après le lever du soleil';

  @override
  String get brightnessAfterSunset => 'Après le coucher du soleil';

  @override
  String get brightnessTransitionTime => 'Temps de transition de luminosité';

  @override
  String get brightnessSolarUnavailable =>
      'La programmation du mode nuit n\'est pas disponible. Vérifiez ses horaires et son emplacement.';

  @override
  String get persistentNotificationCannotDelete =>
      'Cette notification persistante ne peut pas être supprimée. Vous pouvez seulement le bloquer.';

  @override
  String get diagnosticsCreateFailed =>
      'Impossible de créer le rapport de diagnostic. Essayer à nouveau.';

  @override
  String get backupListFailed =>
      'Impossible de charger la liste de sauvegarde. Vérifiez l\'accès au stockage sélectionné.';

  @override
  String get updateInstallerFailed =>
      'Impossible d\'ouvrir le programme d\'installation de la mise à jour. Réessayez et vérifiez que le programme d\'installation de Android est disponible.';

  @override
  String get backupFolderFailed =>
      'Impossible de sélectionner ou d\'enregistrer le dossier de sauvegarde. Choisissez un dossier accessible et réessayez.';

  @override
  String get updateDownloadFailed =>
      'Impossible de télécharger la mise à jour. Vérifiez votre connexion Internet et le stockage disponible.';

  @override
  String get backupDeleteFailed =>
      'Impossible de supprimer la sauvegarde. Vérifiez les autorisations de suppression et réessayez.';

  @override
  String get updateCheckFailed =>
      'Impossible de vérifier les mises à jour. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get backupCreateFailed =>
      'Impossible de créer la sauvegarde. Vérifiez l’accès au stockage et l’espace disponible.';

  @override
  String get wallpaperChangeFailed =>
      'Impossible de changer le fond d\'écran. Vérifiez l\'accès au fichier et réessayez.';

  @override
  String get backupDownloadsFolder => 'Téléchargements / CuteLauncher';

  @override
  String get backupChooseFolder =>
      'Choisissez un dossier dans le gestionnaire de fichiers';

  @override
  String get backupFolderPickerUnavailable =>
      'Aucun sélecteur de dossier n\'est disponible sur ce téléviseur. Choisissez Téléchargements / CuteLauncher ou le dossier interne de l\'application.';

  @override
  String get driveConfigurationError =>
      'Les informations d’identification Google Drive sont manquantes ou non valides. Entrez l\'ID client et le secret client de votre client TV OAuth.';

  @override
  String get driveCodeExpired =>
      'Le délai de connexion à Google Drive a expiré. Sélectionnez Vérifier et enregistrer le compte pour obtenir un nouveau code.';

  @override
  String get brightnessAfterNightStart => 'La nuit';

  @override
  String get brightnessAfterNightEnd => 'Jour';

  @override
  String get backupSyncSettings => 'Paramètres à synchroniser';

  @override
  String get backupSyncHomeGroup =>
      'Écran d\'accueil, sections et applications';

  @override
  String get backupSyncAppearanceGroup =>
      'Apparence, fonds d\'écran et bannières';

  @override
  String get backupSyncDisplayGroup =>
      'Mode nuit, luminosité et économiseur d\'écran';

  @override
  String get backupSyncControlsGroup => 'Commandes du lanceur et du téléviseur';

  @override
  String get backupSyncGeneralGroup =>
      'Langue, mises à jour et autres paramètres';

  @override
  String get backupSyncGroupsHelp =>
      'Les blocs désactivés restent locaux sur ce téléviseur. La sélection de bloc est synchronisée entre les appareils.';

  @override
  String get backupSyncGroupsFailed =>
      'Impossible d\'enregistrer la sélection des paramètres pour la synchronisation. Essayer à nouveau.';

  @override
  String get tileLayoutMode => 'Disposition des tuiles';

  @override
  String get tileLayoutAuto => 'Automatique par taille de tuile';

  @override
  String get tileLayoutColumns => 'Nombre de colonnes fixe';

  @override
  String get tileLayoutRows => 'Nombre de lignes fixe';

  @override
  String get tileRowCount => 'Nombre de lignes';

  @override
  String get useGlobalTileSettings => 'Utiliser les paramètres globaux';

  @override
  String get centerSelection => 'Poste de sélection';

  @override
  String get selectionBottom => 'En bas';

  @override
  String get selectionLower => 'Milieu inférieur';

  @override
  String get selectionCenter => 'Centre';

  @override
  String get selectionUpper => 'Milieu supérieur';

  @override
  String get selectionTop => 'Haut';

  @override
  String get settingsStyle => 'Style des paramètres';

  @override
  String get tileFocusEnlargement => 'Agrandissement de la mise au point';

  @override
  String get tileFocusShadowStrength => 'Force de l\'ombre';

  @override
  String get tileFocusLift => 'Ascenseur';

  @override
  String get tileFocusLiftHeight => 'Hauteur de levage';

  @override
  String get tileFocusBorderColor => 'Couleur de la bordure de mise au point';

  @override
  String get tileFocusAccentColor => 'Couleur d\'accentuation';

  @override
  String get tileFocusDynamicColor => 'Couleurs dynamiques';

  @override
  String get tileSizeFromColumns =>
      'La taille des carreaux est déterminée par le nombre de colonnes et la largeur des sections.';

  @override
  String get resetSectionToGlobal =>
      'Réinitialiser les paramètres aux valeurs partagées';

  @override
  String get resetSectionToGlobalHint =>
      'Restaurer les titres, les icônes et l\'arrière-plan des sections partagées et réinitialiser le remplissage ?';

  @override
  String get resetStyleSection => 'Réinitialiser cette section';

  @override
  String get resetStyleSectionHint =>
      'Restaurer les paramètres par défaut pour cette section uniquement ?';

  @override
  String get notificationStyle => 'Style de notification';

  @override
  String get styleBackgroundColor => 'Couleur de fond';

  @override
  String get styleTransparency => 'Transparence de l\'arrière-plan';

  @override
  String get styleTextSize => 'Taille du texte';

  @override
  String get styleTextColor => 'Couleur du texte';

  @override
  String get noticeSize => 'Taille des notifications';

  @override
  String get noticeStylePreview => 'Aperçu des notifications';

  @override
  String get backupSyncHomeOptions => 'Comportement et options générales';

  @override
  String get backupSyncBackground => 'Arrière-plan et bannières personnalisées';

  @override
  String get backupSyncTiles => 'Style de vignette, de menu et de notification';

  @override
  String get backupSyncWeatherSource => 'Origine et localisation';

  @override
  String get backupSyncWeatherDisplay =>
      'Affichage météo et unités de température';

  @override
  String get backupSyncNotificationSettings =>
      'Affichage des notifications et filtres';

  @override
  String get backupSyncOther => 'Autres paramètres';

  @override
  String get tileFocusBorderStyle => 'Style de bordure';

  @override
  String get tileFocusOutline => 'Aperçu';

  @override
  String get tileFocusGlow => 'Lueur';

  @override
  String get tileFocusNoBorder => 'Pas de frontière';

  @override
  String get tileShowFocusShadow => 'Afficher l\'ombre';

  @override
  String get homeLayoutRow => 'Rangée horizontale';

  @override
  String get homeLayoutRows => 'Plusieurs lignes';

  @override
  String get homeLayoutGrid => 'Grille';

  @override
  String get homeCardCount => 'Cartes visibles partout';

  @override
  String get homeAuto => 'Automatique';

  @override
  String get homeFree => 'Défilement libre';

  @override
  String get homeAnchored => 'Section ancrée';

  @override
  String get homeScrollMode => 'Défilement des sections';

  @override
  String get homeSectionPosition => 'Poste de section active';

  @override
  String get homeLabelMode => 'Étiquettes d\'application';

  @override
  String get homeLabelNone => 'Pas d\'étiquettes';

  @override
  String get homeLabelSelected => 'Application sélectionnée uniquement';

  @override
  String get homeLabelAll => 'Toutes les candidatures';

  @override
  String get homeInherited => 'Valeur héritée';

  @override
  String get homeOwnReset => 'Rétablir les réglages communs';

  @override
  String get homeParameters => 'Paramètres';

  @override
  String get homeSectionStyle => 'Apparition de la section';

  @override
  String get homeSectionGap => 'Espace entre les sections';

  @override
  String get homeSectionIcons => 'Icônes de section';

  @override
  String get homeInactiveOpacity => 'Opacité de la section inactive';

  @override
  String get homeResetSection => 'Restaurer l\'apparence de la section héritée';

  @override
  String get homeCalculatedSize =>
      'La taille est calculée à partir du nombre de cartes';

  @override
  String homeGapLimited(int gap) {
    return 'L\'espacement est limité à $gap pour conserver le nombre de cartes sélectionné.';
  }

  @override
  String get homeResetLayout => 'Réinitialiser la disposition des sections';

  @override
  String homeVisibleRows(int count) {
    return 'Lignes entièrement visibles : $count';
  }

  @override
  String get homeStylePartial =>
      'S\'applique uniquement aux sections qui héritent de cette valeur et la prennent en charge dans leur présentation actuelle.';

  @override
  String get homeStyleUnavailable =>
      'Indisponible dans les paramètres de la section actuelle. Vérifiez la mise en page et les remplacements locaux.';

  @override
  String get homeStyleNeedsRows =>
      'Disponible pour plusieurs lignes ou une grille.';

  @override
  String get homeStyleNeedsLabels =>
      'Permettez aux étiquettes de modifier leur taille et leur couleur.';

  @override
  String get homeStyleNeedsAllLabels =>
      'La position s\'applique uniquement aux étiquettes de toutes les cartes. Le titre sélectionné reste en dessous de la section.';

  @override
  String get homeStyleNeedsScale =>
      'Sélectionnez l’effet de mise au point d’agrandissement.';

  @override
  String get homeStyleNeedsLift =>
      'Sélectionnez l’effet de mise au point lift.';

  @override
  String get homeStyleNeedsBorder =>
      'Activez d\'abord un contour ou une lueur.';

  @override
  String get homeStyleNeedsTitle =>
      'Activez le titre de la section pour afficher son icône.';

  @override
  String get homeStyleEconomy =>
      'Désactivé par sauvegarde de la mémoire. La valeur enregistrée est conservée.';

  @override
  String get homeStyleOpaque =>
      'Réduisez l’opacité de l’arrière-plan des vignettes pour voir le flou.';

  @override
  String get homeStyleOverridden =>
      'Les sections visibles utilisent leurs propres valeurs. Choisissez « Utiliser global » dans une section pour appliquer ce paramètre.';

  @override
  String get homeStyleIconHint =>
      'La taille de l’icône affecte les cartes comportant une icône d’application. Les bannières TV remplissent la carte de manière indépendante.';

  @override
  String get homeStyleShadowHint =>
      'L\'économie de mémoire limite l\'ombre des cartes inactives à 4. L\'ombre de mise au point est configurée séparément.';

  @override
  String get homeStyleTransparent =>
      'La couleur d\'arrière-plan est invisible à opacité nulle. Augmentez l\'opacité de l\'arrière-plan des vignettes.';

  @override
  String get homeStyleSingleColumn =>
      'Une grille à une seule colonne ne comporte aucun espace horizontal.';

  @override
  String get homeStyleAutoOnly =>
      'La taille change uniquement dans les sections avec un nombre de cartes automatique qui hérite de la taille globale.';

  @override
  String get sleepTimerThirtySeconds => '30 secondes (essai)';

  @override
  String get sleepTimer => 'Minuterie de mise en veille';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1,5 heures';

  @override
  String get sleepTimerAllowExact => 'Autoriser des minuteries précises';

  @override
  String get sleepTimerExactRequired =>
      'Autorisez des minuteries précises dans les paramètres Android, puis sélectionnez à nouveau une durée.';

  @override
  String get sleepTimerAccessRequired =>
      'Activez l\'accessibilité au CuteLauncher ou connectez le ADB local dans Paramètres → Autre → ADB.';

  @override
  String get sleepTimerFailed =>
      'Impossible de régler ou de terminer la minuterie de mise en veille. Vérifiez l\'accessibilité et le ADB local.';

  @override
  String get nightIgnoreHdmiInputs => 'Ignorer les entrées HDMI';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'Mettez le filtre de nuit en pause tout en regardant HDMI. L\'accès à l\'utilisation est requis ; la détection d’entrée dépend du micrologiciel du téléviseur.';

  @override
  String get inputsSettings => 'Paramètres d\'entrée';

  @override
  String get inputsUseCecNames => 'Utiliser les noms d\'appareil de CEC';

  @override
  String get inputsNamesHint =>
      'Priorité du nom : votre nom dans CuteLauncher → CEC (si activé) → nom des paramètres Android → nom d\'entrée standard.';

  @override
  String get inputNameHint => 'Laisser vide pour un nom automatique';

  @override
  String get inputsSaveFailed =>
      'Impossible d\'enregistrer les paramètres d\'entrée';

  @override
  String get inputIcon => 'Icône de saisie';

  @override
  String get inputIconTv => 'Télévision';

  @override
  String get inputIconGame => 'Console de jeu';

  @override
  String get inputIconComputer => 'Ordinateur';

  @override
  String get inputIconReceiver => 'Récepteur';

  @override
  String get inputIconDisc => 'Lecteur de disque';

  @override
  String get inputIconStream => 'Appareil de diffusion en continu';

  @override
  String get nightInputExclusions => 'Exclusions d\'entrée';

  @override
  String get nightSelectInputs => 'Sélectionnez les entrées à ignorer';

  @override
  String get nightNoInputsSelected =>
      'Aucune entrée sélectionnée. Le filtre s\'appliquera à chaque entrée.';

  @override
  String get nightPictureExclusions => 'Exclusions du mode Image';

  @override
  String get nightPictureExclusionsHint =>
      'Sélectionnez les modes qui mettent en pause la gradation, la superposition chaude et le filtre TCL lié. L\'horaire est conservé. La détection a été vérifiée sur TCL ; l’accès à l’utilisation n’est pas requis.';

  @override
  String get nightPictureUnavailable =>
      'Le mode image actuel n\'est pas disponible sur ce firmware. Votre sélection est enregistrée ; les exclusions s’appliquent uniquement lorsque la détection réussit.';

  @override
  String get nightPictureCurrent => 'Mode actuel';

  @override
  String get nightPictureRefresh => 'Actualiser le mode actuel';

  @override
  String get nightPictureCode => 'Code de mode';

  @override
  String get nightPictureStandard => 'Norme';

  @override
  String get nightPictureDynamic => 'Dynamique';

  @override
  String get nightPictureMovie => 'Film';

  @override
  String get nightPictureSport => 'Sport';

  @override
  String get nightPictureIntelligent => 'Intelligent';

  @override
  String get nightPictureBright => 'Lumineux (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'Norme';

  @override
  String get systemApplications => 'Applications système';

  @override
  String get removeFromCategory => 'Supprimer de la catégorie';

  @override
  String get noRemovableCategories =>
      'Cette application n\'a été ajoutée manuellement à aucune section. Les sections automatiques ne peuvent pas être modifiées.';

  @override
  String get remoteButtonsTitle => 'Réaffectation des boutons de télécommande';

  @override
  String get remoteButtonsStart => 'Tester les boutons (120 s)';

  @override
  String get remoteButtonsStop => 'Arrêter le test';

  @override
  String get remoteButtonsHint =>
      'Le test affiche les codes, relâchements et répétitions et enregistre un rapport texte sur le TV. Quittez cette page après le démarrage pour que OK ne contrôle pas l’enregistrement.';

  @override
  String get remoteButtonsEmpty =>
      'Aucun événement. Si un bouton ouvre une application, revenez ici pour voir le résultat.';

  @override
  String get remoteButtonsService => 'Service connecté';

  @override
  String get remoteButtonsRefresh => 'Actualiser';

  @override
  String get remoteBindings => 'Affectations des boutons';

  @override
  String get remoteMappingsEnabled => 'Activer la réaffectation';

  @override
  String get remoteMappingsAdd => 'Ajouter une affectation';

  @override
  String get remoteMappingKey => 'Bouton';

  @override
  String get remoteMappingAction => 'Action';

  @override
  String get remoteMappingLearn => 'Détecter un bouton';

  @override
  String get remoteMappingLearnHint =>
      'Appuyez sur un bouton supplémentaire sous 30 secondes. Navigation, Power, recherche vocale et volume sont protégés.';

  @override
  String get remoteMappingsHint =>
      'Les affectations nécessitent le service d’accessibilité. Elles sont suspendues dans l’éditeur et pendant le diagnostic. Accueil, Retour, flèches et OK conservent leur navigation.';

  @override
  String get remoteMappingsReset => 'Réinitialiser les affectations';

  @override
  String get remoteMappingsResetConfirm =>
      'Supprimer toutes les affectations et désactiver la réaffectation ?';

  @override
  String get remoteMappingInvalid =>
      'Enregistrement impossible. Vérifiez le bouton et la cible. Les webhooks nécessitent HTTPS ou HTTP sur le réseau local.';

  @override
  String get remoteMappingBack => 'Retour';

  @override
  String get remoteMappingProfile => 'Profil';

  @override
  String get remoteMappingChannels => 'Chaînes';

  @override
  String get remoteMappingQuickSettings => 'Réglages rapides TCL';

  @override
  String get remoteMappingTrigger => 'Type d’appui';

  @override
  String get remoteMappingPress => 'Appui court';

  @override
  String get remoteMappingHold => 'Appui long';

  @override
  String get remoteMappingHoldHint =>
      'Maintenir 650 ms : une seule action, sans appui court. Si seul l’appui long est affecté, un appui court ne fait rien.';

  @override
  String get remotePanelDescription =>
      'Le panneau flottant affiche vos widgets par-dessus les autres applications. Pour l’ouvrir avec la télécommande, attribuez l’action « Panneau flottant » à la touche de votre choix.';

  @override
  String get remotePanel => 'Panneau flottant';

  @override
  String get remotePanelSettingsBackground =>
      'Utiliser la couleur de fond des paramètres';

  @override
  String get remotePanelPreview => 'Ouvrir le panneau';

  @override
  String get settingsHelp => 'En savoir plus';

  @override
  String get settingsHelpScroll => '▲ / ▼ — faire défiler le texte';

  @override
  String get panelClockStyle => 'Apparence de l’horloge';

  @override
  String get clockPreset => 'Style de police';

  @override
  String get clockCustom => 'Personnalisé';

  @override
  String get clockWeight => 'Épaisseur de police';

  @override
  String get clockGlow => 'Lueur du texte';

  @override
  String get clockAnimate => 'Animer les chiffres';

  @override
  String get clockBackground => 'Fond de l’horloge';

  @override
  String get clockRadius => 'Arrondi du fond';

  @override
  String get dateCalendarEnabled =>
      'Ouvrir le calendrier en appuyant sur la date';

  @override
  String get calendarTitle => 'Calendrier';

  @override
  String get dateSettings => 'Réglages de la date';

  @override
  String get clockSharedBackground => 'Même fond que les autres objets';

  @override
  String get clockDefaultBackground => 'Fond par défaut';

  @override
  String get remotePanelInheritAppearance =>
      'Utiliser l’apparence du panneau supérieur';

  @override
  String get remotePanelDisabledInLauncher =>
      'Le panneau flottant est désactivé lorsque CuteLauncher est affiché.';

  @override
  String get remoteAccessSettings => 'Configurer l’accès';

  @override
  String get remoteButtonsTest => 'Test des boutons';

  @override
  String get remoteMappingConflict =>
      'Ce bouton et ce type d’appui sont déjà attribués. Choisissez un autre bouton ou type d’appui.';

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
  String get landscapeDemoStop => 'Arrêter';

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
  String get informationGroup => 'Horloge, date et météo';

  @override
  String get informationSettings => 'Paramètres du bloc';

  @override
  String get informationAppearance => 'Apparence du bloc';

  @override
  String get informationSize => 'Taille du bloc';

  @override
  String get informationPosition => 'Position de l’horloge et du texte';

  @override
  String get informationClockLeft => 'Horloge à gauche, texte à droite';

  @override
  String get informationClockRight => 'Texte à gauche, horloge à droite';

  @override
  String get informationSpacing => 'Espace entre l’horloge et le texte';

  @override
  String get informationBackground => 'Fond du bloc';

  @override
  String get homeResetTilesHint =>
      'Rétablir les valeurs communes de toutes les tuiles et étiquettes de cet écran ?';

  @override
  String get homeResetLayoutHint =>
      'Réinitialiser la disposition de cette section, rétablir son apparence commune et remettre les marges internes à zéro ? Les applications et leur ordre seront conservés.';

  @override
  String get networkSummary => 'Réseau';

  @override
  String get networkConnected => 'Internet disponible';

  @override
  String get networkOffline => 'Pas d’accès à Internet';

  @override
  String get networkDisconnected => 'Déconnecté';

  @override
  String get networkConnection => 'Connexion';

  @override
  String get networkSignal => 'Signal';

  @override
  String get networkLinkSpeed => 'Débit de liaison Wi-Fi';

  @override
  String get networkTrafficRate => 'Trafic de l’appareil · réception / envoi';

  @override
  String get networkSystemSettings => 'Paramètres réseau du système';

  @override
  String get networkUnavailable => 'Indisponible';

  @override
  String get networkMobile => 'Réseau mobile';

  @override
  String get networkFrequency => 'Fréquence';

  @override
  String get networkMbps => 'Mbit/s';

  @override
  String get networkKbps => 'Ko/s';

  @override
  String get networkReadFailed => 'Impossible de lire l’état du réseau';

  @override
  String get clockItalic => 'Italique';

  @override
  String get panelWrapNavigation => 'Navigation circulaire du panneau';

  @override
  String get panelWrapNavigationHelp =>
      'Aux extrémités, les flèches passent au côté opposé. Maintenez une flèche pour continuer à parcourir les deux côtés.';

  @override
  String get networkReceive => 'Réception';

  @override
  String get networkSend => 'Envoi';

  @override
  String get landscapeCelestialBodies => 'Soleil et lune';

  @override
  String get landscapeStarRotation => 'Rotation des étoiles';
}
