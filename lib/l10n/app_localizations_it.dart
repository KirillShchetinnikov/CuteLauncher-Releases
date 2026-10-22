// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

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
  String get backgroundSource => 'Fonte di sfondo';

  @override
  String get noAvailableCategories =>
      'Non ci sono sezioni disponibili a cui aggiungere questa app.';

  @override
  String get redditWallpaperTheme => 'Tema della carta da parati';

  @override
  String get redditThemeAll => 'Misto';

  @override
  String get redditThemeNature => 'Natura';

  @override
  String get redditThemeSpace => 'Spazio';

  @override
  String get redditThemeCity => 'Città';

  @override
  String get redditThemeMinimal => 'Minimalismo';

  @override
  String get redditWallpaperResolution => 'Risoluzione minima';

  @override
  String get redditWallpaperHint =>
      'Ogni aggiornamento riuscito scarica un\'immagine orizzontale diversa dalla community Reddit selezionata. La risoluzione è la dimensione minima dell\'originale; le immagini non vengono ingrandite. L\'aggiornamento viene eseguito mentre il programma di avvio è aperto e riprende al tuo ritorno. I contenuti per adulti, i video e le gallerie vengono saltati. Se Reddit blocca l\'accesso o non viene trovata alcuna immagine corrispondente, rimane lo sfondo precedente.';

  @override
  String get dialogCommandDetails => 'Mostra i comandi ADB';

  @override
  String get dialogAssign => 'Assegnare';

  @override
  String get dialogApply => 'Applicare';

  @override
  String get settingsValueNotSet => 'Non impostato';

  @override
  String get settingsMenuPosition => 'Posizione del menu Impostazioni';

  @override
  String get settingsMenuLeft => 'A sinistra';

  @override
  String get settingsMenuRight => 'Giusto';

  @override
  String get actionCompleted => 'Azione completata';

  @override
  String get showRepositoryQrCode => 'Mostra il codice QR';

  @override
  String get resetSections => 'Ripristina le impostazioni della sezione';

  @override
  String get resetSectionsConfirmation =>
      'Ripristinare le sezioni predefinite? Le sezioni personalizzate, gli spaziatori e i contenuti dei Preferiti verranno rimossi.';

  @override
  String get cardFocusMode => 'Concentrarsi sul ritorno a casa';

  @override
  String get cardFocusRemember => 'Mantieni la carta selezionata';

  @override
  String get cardFocusFirst => 'Prima carta';

  @override
  String get cardFocusSettings => 'Pulsante Impostazioni';

  @override
  String get aboutFlauncher => 'Informazioni su CuteLauncher';

  @override
  String get addCategory => 'Aggiungi categoria';

  @override
  String get addSection => 'Aggiungi sezione';

  @override
  String get alphabetical => 'Alfabetico';

  @override
  String get appCardHighlightAnimation =>
      'Animazione evidenziazione scheda app';

  @override
  String get appInfo => 'Info app';

  @override
  String get appKeyClick => 'Suono clic alla pressione del tasto';

  @override
  String get applications => 'Applicazioni';

  @override
  String get autoHideAppBar => 'Nascondi automaticamente barra di stato';

  @override
  String get backButtonAction => 'Azione pulsante Indietro';

  @override
  String get category => 'Categoria';

  @override
  String get categories => 'Categorie';

  @override
  String get columnCount => 'Numero di colonne';

  @override
  String get date => 'Data';

  @override
  String get dateAndTimeFormat => 'Formato data e ora';

  @override
  String get delete => 'Elimina';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'Non fare nulla';

  @override
  String get dialogOptionBackButtonActionShowScreensaver =>
      'Mostra salvaschermo';

  @override
  String get dialogOptionBackButtonActionShowClock => 'Mostra orologio';

  @override
  String get dialogTextNoFileExplorer =>
      'Installa un file manager per selezionare un\'immagine.';

  @override
  String get dialogTitleBackButtonAction =>
      'Scegli l\'azione del pulsante Indietro';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (Categoria)';
  }

  @override
  String formattedDate(String dateString) {
    return 'Data formattata: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'Ora formattata: $timeString';
  }

  @override
  String get gradient => 'Sfumatura';

  @override
  String get favoriteApps => 'App preferite';

  @override
  String get grid => 'Griglia';

  @override
  String get height => 'Altezza';

  @override
  String get hide => 'Nascondi';

  @override
  String get hiddenApplications => 'App nascoste';

  @override
  String get launcherSections => 'Sezioni';

  @override
  String get layout => 'Disposizione';

  @override
  String get loading => 'Caricamento';

  @override
  String get manual => 'Manuale';

  @override
  String get modifySection => 'Modifica sezione';

  @override
  String get mustNotBeEmpty => 'Non può essere vuoto';

  @override
  String get name => 'Nome';

  @override
  String get newSection => 'Nuova sezione';

  @override
  String get noDateFormatSpecified => 'Nessun formato data specificato';

  @override
  String get noTimeFormatSpecified => 'Nessun formato ora specificato';

  @override
  String get nonTvApplications => 'App non TV';

  @override
  String get open => 'Apri';

  @override
  String get orSelectFormatSpecifiers =>
      'Oppure seleziona specificatori di formato';

  @override
  String get openImage => 'Apri l\'immagine';

  @override
  String get picture => 'Immagine';

  @override
  String removeFrom(String name) {
    return 'Rimuovi da $name';
  }

  @override
  String get renameCategory => 'Rinomina categoria';

  @override
  String get reorder => 'Riordina';

  @override
  String get row => 'Riga';

  @override
  String get rowHeight => 'Altezza riga';

  @override
  String get save => 'Salva';

  @override
  String get spacer => 'Spaziatore';

  @override
  String get spacerMaxHeightRequirement =>
      'Deve essere maggiore di 0 e minore o uguale a 500';

  @override
  String get statusBar => 'Barra di stato';

  @override
  String get settings => 'Impostazioni';

  @override
  String get show => 'Mostra';

  @override
  String get showCategoryTitles => 'Mostra titoli delle categorie';

  @override
  String get themes => 'Temi';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'Nascondi contorno evidenziazione nella schermata Home';

  @override
  String get appSelectorTransitionAnimation =>
      'Animazione transizione selettore app';

  @override
  String get sort => 'Ordina';

  @override
  String get systemSettings => 'Impostazioni di sistema';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => 'Questa categoria è vuota.';

  @override
  String get time => 'Ora';

  @override
  String get titleStatusBarSettingsPage =>
      'Scegli cosa mostrare nella barra di stato';

  @override
  String get tvApplications => 'App TV';

  @override
  String get type => 'Tipo';

  @override
  String get typeInTheDateFormat => 'Inserisci il formato data';

  @override
  String get typeInTheHourFormat => 'Inserisci il formato ora';

  @override
  String get uninstall => 'Disinstalla';

  @override
  String get wallpaper => 'Sfondo';

  @override
  String get withEllipsisAddTo => 'Aggiungi a...';

  @override
  String get timeBasedWallpaper => 'Sfondo basato sull\'ora';

  @override
  String get pickDayWallpaper => 'Scegli sfondo diurno';

  @override
  String get pickNightWallpaper => 'Scegli sfondo notturno';

  @override
  String get accessibility => 'Accessibilità';

  @override
  String get defaultLauncherIsDefault =>
      'CuteLauncher è il launcher predefinito';

  @override
  String get defaultLauncherNotDefault =>
      'CuteLauncher non è il launcher predefinito';

  @override
  String get setAsDefaultLauncher => 'Imposta come launcher predefinito';

  @override
  String get defaultLauncherDescription =>
      'Quando impostato come launcher predefinito, il pulsante Home tornerà sempre a CuteLauncher. La TV si avvierà direttamente su CuteLauncher.';

  @override
  String get inputs => 'Ingressi';

  @override
  String get inputsUnavailableHint =>
      'Questo dispositivo non fornisce ingressi disponibili. L\'interruttore è disabilitato e l\'icona è nascosta. Su un TV-Box, questa opzione non controlla gli ingressi HDMI della TV collegata.';

  @override
  String get inputSources => 'Sorgenti di ingresso';

  @override
  String get backupAndRestore => 'Backup e Ripristino';

  @override
  String get exportBackup => 'Esporta Backup';

  @override
  String get importBackup => 'Importa Backup';

  @override
  String exportSuccess(String path) {
    return 'Backup esportato con successo in $path';
  }

  @override
  String get importSuccess => 'Backup importato con successo';

  @override
  String get importConfirm =>
      'Sei sicuro di voler importare il backup? Questo sovrascriverà le tue impostazioni e il layout attuali.';

  @override
  String get importError =>
      'Impossibile ripristinare le impostazioni dal backup. Controlla il file e riprova.';

  @override
  String exportError(String error) {
    return 'Impossibile esportare il backup: $error';
  }

  @override
  String get shareBackup => 'Condividi Backup';

  @override
  String get shareBackupDescription =>
      'Condividi il backup con altri dispositivi sulla rete locale';

  @override
  String get stopSharing => 'Interrompi condivisione';

  @override
  String get localNetworkSharingActive =>
      'La condivisione sulla rete locale è attiva!';

  @override
  String get localNetworkSharingInstructions =>
      'Collega un altro dispositivo alla stessa rete Wi-Fi e apri il seguente URL in un browser web:';

  @override
  String get localNetworkSharingDetails =>
      'Qui puoi scaricare le impostazioni/layout della tua TV o caricare un file di backup su questa TV.';

  @override
  String failedToStartServer(String error) {
    return 'Impossibile avviare il server di condivisione: $error';
  }

  @override
  String get notificationBell => 'Campanella notifiche';

  @override
  String get autoHideNotificationBell =>
      'Nascondi automaticamente campanella notifiche';

  @override
  String get continueWatching => 'Continua a guardare';

  @override
  String get showContinueWatchingOnHome =>
      'Mostra Continua a guardare nella Home';

  @override
  String get permissionDeniedContinueWatching =>
      'Autorizzazione richiesta per mostrare Continua a guardare';

  @override
  String get interface => 'Interfaccia';

  @override
  String get system => 'Sistema';

  @override
  String get accentColor => 'Colore primario';

  @override
  String get miscellaneous => 'Varie';

  @override
  String get brightnessScheduler => 'Pianificatore luminosità';

  @override
  String get screensaverSettings => 'Impostazioni salvaschermo';

  @override
  String get screensaverClockStyle => 'Stile orologio salvaschermo';

  @override
  String get dataUsagePeriod => 'Periodo utilizzo dati';

  @override
  String get notificationAccess => 'Accesso notifiche';

  @override
  String get granted => 'Concesso';

  @override
  String get permissionRequired => 'Autorizzazione richiesta';

  @override
  String get systemWidePopupAlert => 'Avviso popup di sistema';

  @override
  String get overlayPermissionRequired =>
      'Autorizzazione sovrapposizione richiesta';

  @override
  String get enabled => 'Abilitato';

  @override
  String get disabled => 'Disabilitato';

  @override
  String get showAppNamesBelowIcons => 'Mostra nomi app sotto le icone';

  @override
  String get dataUsage => 'Utilizzo dati';

  @override
  String get networkIndicator => 'Indicatore di rete';

  @override
  String get homeButtonFix => 'Fix pulsante Home (Google TV)';

  @override
  String get startOnBoot => 'Avvia all\'accensione (Google TV / Fire TV)';

  @override
  String get appLanguage => 'Lingua';

  @override
  String get systemDefault => 'Predefinito di sistema';

  @override
  String get english => 'Inglese';

  @override
  String get spanish => 'Spagnolo';

  @override
  String get ukrainian => 'Ucraino';

  @override
  String get chinese => 'Cinese';

  @override
  String get french => 'Francese';

  @override
  String get german => 'Tedesco';

  @override
  String get japanese => 'Giapponese';

  @override
  String get portuguese => 'Portoghese';

  @override
  String get russian => 'Russo';

  @override
  String get italian => 'Italiano';

  @override
  String get hindi => 'hindi';

  @override
  String get korean => 'Coreano';

  @override
  String get arabic => 'Arabo';

  @override
  String get turkish => 'Turco';

  @override
  String get hidePersistentNotifications => 'Nascondi notifiche persistenti';

  @override
  String get hidePersistentNotificationsDesc =>
      'Nascondi le notifiche dei servizi in background e di sistema';

  @override
  String get blockedNotificationApps => 'App bloccate';

  @override
  String get blockAppNotifications => 'Blocca notifiche';

  @override
  String get unblockAppNotifications => 'Sblocca notifiche';

  @override
  String get noBlockedApps => 'Nessuna app bloccata';

  @override
  String get persistentNotification => 'Persistente';

  @override
  String get unblockAll => 'Sblocca tutto';

  @override
  String get weather => 'Meteo';

  @override
  String get showWeatherWarnings => 'Mostra avvisi meteo e pioggia';

  @override
  String get temperatureUnit => 'Unità di temperatura';

  @override
  String get celsius => 'Celsius (°C)';

  @override
  String get fahrenheit => 'Fahrenheit (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Installa Breezy Weather e abilita \'Condivisione dati locali\' / \'Gadgetbridge\' nelle impostazioni per visualizzare meteo e avvisi di pioggia.';

  @override
  String get displayAndScreensaver => 'Schermo e salvaschermo';

  @override
  String get notifications => 'Notifiche';

  @override
  String get continueWatchingDescription =>
      'Mostra film e programmi TV visti di recente sulla schermata iniziale';

  @override
  String get continueWatchingPermissionDesc =>
      'È richiesta un\'autorizzazione speciale per leggere la cronologia di visualizzazione:';

  @override
  String get requestPermission => 'Richiedi autorizzazione';

  @override
  String get dismiss => 'Ignora';

  @override
  String get openApp => 'Apri';

  @override
  String get notificationOptions => 'Opzioni notifica';

  @override
  String get noBlockedAppsDesc =>
      'Tutte le applicazioni possono attualmente mostrare notifiche';

  @override
  String get notificationsAllowed => 'Notifiche consentite';

  @override
  String get notificationsBlocked => 'Notifiche bloccate';

  @override
  String get dpadDismissHint => 'Sinistra: Ignora • OK: Opzioni';

  @override
  String get watchNextDeleteError =>
      'Impossibile rimuovere l\'elemento da Continua a guardare. Riprova.';

  @override
  String get hideLauncherTile =>
      'Nascondi CuteLauncher nella griglia dell\'app';

  @override
  String get hideAndroidSettingsTile =>
      'Nascondi le impostazioni Android nei riquadri dell\'app';

  @override
  String get animateTileReordering => 'Animare il riordino delle tessere';

  @override
  String get imageInputRejected =>
      'Questa immagine è danneggiata o troppo grande (massimo 8 MiB e 48 megapixel). Scegli un\'altra immagine.';

  @override
  String get memoryTitle => 'Memoria';

  @override
  String get memoryRefresh => 'Misurare la memoria';

  @override
  String get memoryMeasuring => 'Misurare...';

  @override
  String get memoryClear => 'Cancella le cache delle immagini';

  @override
  String get memorySaver => 'Risparmio di memoria';

  @override
  String get memorySaverDescription =>
      'Modalità di risparmio della memoria:\n\n• Riduce le cache delle immagini e la finestra di precarico dei poster.\n• Disattiva la sfocatura dello sfondo di piastrelle, pannelli e sfondi e la pulsazione dei contorni.\n• Limita le ombre sulle tessere non a fuoco.\n• Cancella le cache quando l\'app passa in background.\n\nQuesti effetti non sono disponibili nelle impostazioni mentre è abilitato il salvataggio della memoria. I loro valori salvati ritornano quando la modalità è disabilitata. Le immagini potrebbero essere ricaricate più spesso.';

  @override
  String get memoryPss => 'Condivisione processo (PSS)';

  @override
  String get memoryRss => 'Memoria del processo residente (RSS)';

  @override
  String get memoryEncodedCache => 'File di immagini memorizzati nella cache';

  @override
  String get memoryDecodedCache =>
      'Immagini decodificate memorizzate nella cache';

  @override
  String get memoryUnavailable => 'Non disponibile';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => 'Misurato a';

  @override
  String get memoryExplanation =>
      'PSS e RSS si sovrappongono: non sommarli. Le dimensioni della cache fanno parte della memoria dell\'app e non descrivono tutta la memoria contenuta dalle immagini attive. Svuotare le cache mantiene le impostazioni e i file; le immagini si caricano nuovamente quando necessario. Android potrebbe restituire la memoria in un secondo momento. RSS qui proviene dal kernel e PSS da Android; possono tenere conto della memoria grafica in modo diverso.';

  @override
  String get memoryRecommendations =>
      'Per meno memoria, attiva il salvataggio, mostra meno Continua a guardare le schede e utilizza sfondi più piccoli o una sfumatura.';

  @override
  String get memoryMeasurementFailed =>
      'La misurazione del processo non è disponibile. Le informazioni sulla cache vengono ancora visualizzate.';

  @override
  String get addToCategory => 'Aggiungi alla categoria';

  @override
  String get addToFavorites => 'Aggiungi ai preferiti';

  @override
  String get removeFromFavorites => 'Rimuovi dai preferiti';

  @override
  String get setCustomBanner => 'Imposta banner personalizzato';

  @override
  String get clearCustomBanner => 'Cancella banner personalizzato';

  @override
  String get bannerSetFailed =>
      'Impossibile impostare il banner. Verifica l\'accesso all\'immagine e seleziona nuovamente il file.';

  @override
  String get bannerClearFailed =>
      'Impossibile rimuovere il banner personalizzato. Riprova.';

  @override
  String get grantUsagePermission =>
      'Concedere l\'autorizzazione all\'utilizzo';

  @override
  String get removeFromContinueWatching => 'Rimuovi da Continua a guardare';

  @override
  String hideAllFromApp(String appName) {
    return 'Nascondi tutto da $appName';
  }

  @override
  String get playResume => 'Riproduci/Riprendi';

  @override
  String openNamedApp(String appName) {
    return 'Apri $appName';
  }

  @override
  String get selectedAccent => 'Accento selezionato';

  @override
  String get homeButtonFixHint =>
      'Se utilizzi Google TV, abilita \"Correzione pulsante Home\" nelle impostazioni di accessibilità per fare in modo che il pulsante Home apra questo launcher.';

  @override
  String get accessibilityPermission => 'Autorizzazione di accessibilità';

  @override
  String get shareFailed => 'Condivisione non riuscita';

  @override
  String shareBackupError(String error) {
    return 'Impossibile condividere il backup: $error';
  }

  @override
  String get exportComplete => 'Esportazione riuscita';

  @override
  String get exportFailed =>
      'Impossibile salvare il backup. Controlla l\'accesso alla cartella e lo spazio di archiviazione disponibile.';

  @override
  String backupLoadError(String error) {
    return 'Errore durante il caricamento dei backup: $error';
  }

  @override
  String get noBackupFiles => 'Nessun file di backup trovato.';

  @override
  String get importComplete => 'Importazione riuscita';

  @override
  String get importFailed => 'Importazione non riuscita';

  @override
  String get importAction => 'Importa';

  @override
  String get continueWatchingApps => 'Continua a guardare le app';

  @override
  String get blockedContinueWatching => 'Bloccato da Continua a guardare';

  @override
  String get allAppsCanContinueWatching =>
      'Tutte le app supportate possono mostrare elementi in Continua a guardare.';

  @override
  String get unblockApp => 'Sblocca';

  @override
  String get unblockAllApps => 'Sblocca tutte le app';

  @override
  String get appsWithContinueWatching => 'App con Continua a guardare';

  @override
  String get watchNextAppsHint =>
      'App che attualmente forniscono elementi Guarda successivo sulla schermata Home';

  @override
  String get noWatchNextApps =>
      'Nessuna app attualmente fornisce elementi Continua a guardare.\nQuando le app supportate (come SmartTube o servizi di streaming) aggiungono elementi, verranno visualizzati qui.';

  @override
  String get allInstalledApps => 'Tutte le app installate';

  @override
  String get blockWatchNextHint =>
      'Disattiva per impedire a qualsiasi app di aggiungere elementi a Continua a guardare';

  @override
  String get cardSize => 'Dimensioni della carta';

  @override
  String get maximumItems => 'Articoli massimi';

  @override
  String get playbackProgressBar => 'Barra di avanzamento della riproduzione';

  @override
  String get playbackPercentage => 'Percentuale di riproduzione';

  @override
  String get episodeVideoDetails => 'Dettagli episodio e video';

  @override
  String get restoreHiddenPrograms => 'Ripristina programmi nascosti';

  @override
  String get allHiddenProgramsRestored =>
      'Tutti i programmi nascosti ripristinati';

  @override
  String get watchNextAccessAdb =>
      'Guarda l\'accesso successivo (ADB richiesto)';

  @override
  String get supportLtvLauncher => 'Supporta LTvLauncher';

  @override
  String get scanToDonate =>
      'Scansiona con la fotocamera del tuo telefono per donare:';

  @override
  String get openInBrowser => 'Apri nel browser';

  @override
  String get close => 'Chiudi';

  @override
  String get launcherAuthor => 'CuteLauncher per Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Lanciatore Android TV basato su LTvLauncher di LeanBitLab e FLauncher di Étienne Fesser. Concesso in licenza sotto GNU GPLv3.';

  @override
  String get projectCredits => 'Progetto e crediti';

  @override
  String get launcherRepository => 'Archivio CuteLauncher';

  @override
  String get originalProject => 'Progetto originale: LTvLauncher';

  @override
  String get noInputsDetected => 'Nessun input rilevato';

  @override
  String get reorderSectionsHint =>
      'Selezionare con ◄ / ► quindi utilizzare ▲ / ▼ per riordinare. Attraversa il limite dell\'elenco per nascondere o mostrare una sezione.';

  @override
  String get customName => 'Nome personalizzato';

  @override
  String get mostUsed => 'Frequenza di lancio';

  @override
  String get lastUsed => 'Ultimo utilizzo';

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String get allCaughtUp => 'Tutti presi!';

  @override
  String get notificationAccessAdb => 'Accesso alle notifiche (ADB richiesto)';

  @override
  String get openAppInfo => 'Apri Informazioni sull\'app';

  @override
  String get overlayPermission => 'Autorizzazione di sovrapposizione';

  @override
  String get clockMinimal => 'Minimo';

  @override
  String get clockMinimalDescription =>
      'Carattere sottile ed elegante (predefinito)';

  @override
  String get clockBold => 'Grassetto';

  @override
  String get clockBoldDescription => 'Carattere spesso e altamente visibile';

  @override
  String get clockRetro => 'retrò';

  @override
  String get clockRetroDescription => 'Stile terminale monospaziato e retrò';

  @override
  String get clockElegant => 'Elegante';

  @override
  String get clockElegantDescription => 'Carattere tipografico serif classico';

  @override
  String get clockNeon => 'Neon';

  @override
  String get clockNeonDescription => 'Stile ultrasottile e luminoso';

  @override
  String get clockPixel => 'Pixel';

  @override
  String get clockPixelDescription => 'Audace monospazio, atmosfera arcade';

  @override
  String get clockDigital => 'Digitale';

  @override
  String get clockDigitalDescription => 'Display pulito a spaziatura fissa';

  @override
  String get themeDefault => 'Predefinito';

  @override
  String get themePremium => 'Premio';

  @override
  String get themeClassic => 'Classico';

  @override
  String get themeCapsule => 'Capsula';

  @override
  String get cancel => 'Annulla';

  @override
  String get actionCancelled => 'Azione annullata';

  @override
  String get ok => 'Va bene';

  @override
  String get accessibilityGuide =>
      'Aprire manualmente le impostazioni della TV, quindi Accessibilità → CuteLauncher Correzione pulsante Home e abilitare il servizio. La posizione e il nome di questo menu dipendono dal produttore del televisore.';

  @override
  String get notificationPermissionGuide =>
      'Impossibile aprire le impostazioni di accesso alle notifiche su questo televisore. Consentire le notifiche in uscita in Informazioni app non garantisce l\'accesso alle notifiche di altre app.\n\nCollega la tua TV tramite ADB ed esegui:';

  @override
  String get overlayPermissionGuide =>
      'Non è stato possibile aprire automaticamente le impostazioni delle autorizzazioni di sovrapposizione.\n\nPer abilitare i popup su altre app, collega la TV tramite ADB ed esegui:';

  @override
  String get watchNextPermissionGuide =>
      'Per leggere le schede Continua a guardare da altre app, Android TV richiede READ_WRITE_WATCH_NEXT_PROGRAMS.\n\nCollega la tua TV tramite ADB ed esegui:';

  @override
  String get watchNextAccess => 'Continua a guardare l\'accesso';

  @override
  String itemsCount(int count) {
    return 'Articoli $count';
  }

  @override
  String displayUpToItems(int count) {
    return 'Visualizza fino a $count elementi recenti';
  }

  @override
  String get unlimitedItems => 'Illimitato';

  @override
  String get allAvailableItems => 'Visualizza tutti gli articoli disponibili';

  @override
  String get defaultOption => 'Predefinito';

  @override
  String get manage => 'Gestisci';

  @override
  String blockedCount(int count) {
    return '$count bloccato';
  }

  @override
  String hiddenCount(int count) {
    return '$count nascosto';
  }

  @override
  String blockedWatchNextCount(int count) {
    return 'Bloccato da Continua a guardare ($count)';
  }

  @override
  String get sizeExtraSmall => 'Molto piccolo';

  @override
  String get sizeVerySmall => 'Molto piccolo';

  @override
  String get sizeSmall => 'Piccolo';

  @override
  String get sizeCompact => 'Compatto';

  @override
  String get sizeMediumSmall => 'Medio Piccolo';

  @override
  String get sizeMedium => 'Medio';

  @override
  String get sizeStandardDefault => 'Standard (predefinito)';

  @override
  String get sizeMediumLarge => 'Medio Grande';

  @override
  String get sizeLarge => 'Grande';

  @override
  String get sizeVeryLarge => 'Molto grande';

  @override
  String get sizeExtraLarge => 'Molto grande';

  @override
  String get sizeHuge => 'Enorme';

  @override
  String get tvApps => 'App televisive';

  @override
  String get nonTvApps => 'App non TV';

  @override
  String get moviesShows => 'Film e spettacoli';

  @override
  String get music => 'Musica';

  @override
  String get games => 'Giochi';

  @override
  String get entertainment => 'Intrattenimento';

  @override
  String get liveTv => 'TV in diretta';

  @override
  String get sports => 'Sport';

  @override
  String get news => 'Novità';

  @override
  String get tools => 'Strumenti';

  @override
  String get favorites => 'Preferiti';

  @override
  String get customSectionName => 'Personalizzato...';

  @override
  String get selectSectionName => 'Seleziona un nome';

  @override
  String get weeklyUsage => 'Settimanale:';

  @override
  String get monthlyUsage => 'Mensile:';

  @override
  String get dailyUsage => 'Giornaliero:';

  @override
  String get appError => 'Qualcosa è andato storto';

  @override
  String get weatherRain => 'Pioggia';

  @override
  String get weatherSnow => 'Neve';

  @override
  String get weatherStorm => 'Tempesta';

  @override
  String get weatherToday => 'oggi';

  @override
  String get weatherTomorrow => 'domani';

  @override
  String weatherOnDay(String day) {
    return 'su $day';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'Backup di CuteLauncher';

  @override
  String get noApplicationsFound => 'Nessuna applicazione trovata';

  @override
  String get invalidDateFormat => 'Formato non valido';

  @override
  String get selectDateFormats => 'Seleziona i formati di seguito';

  @override
  String activeItemsCount(int count) {
    return 'Articolo/i attivo/i $count';
  }

  @override
  String get colorPurple => 'Viola';

  @override
  String get colorTeal => 'Verde acqua';

  @override
  String get colorBlue => 'Blu';

  @override
  String get colorOrange => 'Arancione';

  @override
  String get colorPink => 'Rosa';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorWhite => 'Bianco';

  @override
  String get colorYellow => 'Giallo';

  @override
  String get colorRed => 'Rosso';

  @override
  String get colorCyan => 'Ciano';

  @override
  String get colorIndigo => 'Indaco';

  @override
  String get colorLime => 'Calce';

  @override
  String get colorAmber => 'Ambra';

  @override
  String get colorRose => 'Rosa';

  @override
  String get colorIceBlue => 'Blu ghiaccio';

  @override
  String get memoryFeatures => 'Memoria per funzionalità (cache)';

  @override
  String get memoryAppIcons => 'Icone dell\'app';

  @override
  String get memoryAppBanners => 'Banner dell\'app';

  @override
  String get memoryWatchNextPosters => 'Continua a guardare i poster';

  @override
  String get memoryOtherCaches => 'Altre cache di immagini codificate';

  @override
  String get memoryFeaturesExplanation =>
      'Si tratta di byte di immagine conservati, già inclusi nel totale della cache codificata. Zero significa nessun byte conservato nella cache, non che la funzionalità non utilizzi memoria. Gli sfondi e le immagini visualizzate condividono la cache decodificata sopra; le immagini attive potrebbero trovarsi al di fuori di esso. Meteo, notifiche, oggetti Dart e motore non possono essere suddivisi per funzionalità qui. La grafica dell\'interfaccia condivisa è riportata sopra da Android e già inclusa in PSS. La loro memoria è parte del processo totale. Non aggiungere questi valori sovrapposti.';

  @override
  String get memoryGraphics => 'Grafica dell\'interfaccia (inclusa in PSS)';

  @override
  String get categoryVisible => 'Mostra categoria';

  @override
  String get hiddenCategories => 'Categorie nascoste';

  @override
  String get visibleCategories => 'Categorie visibili';

  @override
  String get backupSavedToSelectedLocation =>
      'Backup salvato nella posizione selezionata';

  @override
  String get tileHorizontalGap => 'Spaziatura orizzontale';

  @override
  String get tileVerticalGap => 'Spaziatura verticale';

  @override
  String get tileOpacity => 'Opacità dello sfondo';

  @override
  String get tileShadow => 'Ombra';

  @override
  String get tileCornerRadius => 'Arrotondamento degli angoli';

  @override
  String get tileIconScale => 'Dimensione dell\'icona';

  @override
  String get tileBackgroundColor => 'Sfondo di piastrelle';

  @override
  String get tileLabelSize => 'Dimensioni dell\'etichetta';

  @override
  String get resetAppearance => 'Ripristina aspetto';

  @override
  String get tileAppearance => 'Aspetto delle piastrelle';

  @override
  String get tileLabelColor => 'Colore dell\'etichetta';

  @override
  String get tilePreviewName => 'Applicazione di esempio';

  @override
  String get tileProportions => 'Proporzioni delle piastrelle';

  @override
  String get tileLarge => 'Grande';

  @override
  String get tileLabelBelow => 'Sotto la piastrella';

  @override
  String get tileLabelInside => 'All\'interno della piastrella';

  @override
  String get tileFocusScale => 'Ingrandire';

  @override
  String get tileMedium => 'Medio';

  @override
  String get tileFocusBorder => 'Nessun movimento';

  @override
  String get tileSize => 'Dimensione della piastrella';

  @override
  String get tileCompact => 'Compatto';

  @override
  String get tileLabelPosition => 'Posizione dell\'etichetta';

  @override
  String get tileFocusEffect => 'Effetto di messa a fuoco';

  @override
  String get tileFocusStrength => 'Intensità dell\'evidenziazione';

  @override
  String get panelIndependent => 'Impostazioni personalizzate';

  @override
  String get panelAppearance => 'Stile del pannello superiore';

  @override
  String get panelBackground => 'Sfondo del pannello';

  @override
  String get blurPerformanceHint =>
      'La sfocatura può ridurre l\'uniformità. È disabilitato mentre è attivo il salvataggio della memoria.';

  @override
  String get panelOpacity => 'Opacità del pannello';

  @override
  String get tileBlur => 'Sfocatura dietro le piastrelle';

  @override
  String get panelBlur => 'Sfocatura dietro il pannello superiore';

  @override
  String get panelShared => 'Come i pannelli';

  @override
  String get weatherMinutes => 'min';

  @override
  String get weatherOpenMeteoCredit =>
      'Meteo: Open-Meteo (open-meteo.com), CC BY 4.0. API gratuito per uso non commerciale.';

  @override
  String get weatherRateLimit =>
      'Limite di richieste raggiunto. Riprova più tardi.';

  @override
  String get weatherYandexCredit =>
      'Meteo: Meteo Yandex (yandex.ru/pogoda). L\'accesso dipende dal tuo piano API.';

  @override
  String get yandexWeather => 'Meteo Yandex (REST)';

  @override
  String get weatherAuthorizationError =>
      'Il fornitore meteorologico ha rifiutato la richiesta. Verifica la chiave API e accedi al servizio selezionato.';

  @override
  String get weatherYandexHint =>
      'Richiede una chiave con accesso alle previsioni REST. Una chiave per un altro piano Yandex potrebbe non funzionare.';

  @override
  String get weatherSource => 'Fonte meteo';

  @override
  String get weatherInterval => 'Intervallo di aggiornamento';

  @override
  String get weatherLongitude => 'Longitudine (da -180 a 180)';

  @override
  String get weatherKeyRequired => 'Aggiungi una chiave Yandex API.';

  @override
  String get weatherLocationName => 'Nome della città (facoltativo)';

  @override
  String get weatherLocation => 'Posizione';

  @override
  String get weatherApiKey => 'Chiave Yandex API';

  @override
  String get weatherInvalidResponse =>
      'La fonte meteorologica ha restituito dati non validi.';

  @override
  String get weatherUnavailable =>
      'Il meteo non è disponibile. I dati ricevuti in precedenza vengono conservati, se disponibili. I nuovi tentativi sono limitati a una volta ogni 5 minuti.';

  @override
  String get weatherStale => 'Meteo precedente';

  @override
  String get weatherLatitude => 'Latitudine (da -90 a 90)';

  @override
  String get weatherCoordinatesError =>
      'Inserisci una città manualmente o ottieni le coordinate automaticamente.';

  @override
  String get weatherRefresh => 'Controlla gli aggiornamenti';

  @override
  String get weatherKeyPrivate =>
      'Memorizzato solo su questo dispositivo, escluso dai backup. L\'input vuoto rimuove la chiave.';

  @override
  String get weatherUpdated => 'Aggiornato';

  @override
  String get onlineWallpaperError =>
      'Impossibile caricare questa immagine. Lo sfondo precedente viene mantenuto. Seleziona \"Verifica aggiornamenti\" per riprovare il download.';

  @override
  String get onlineWallpaperHint =>
      'L’ultima immagine resta disponibile senza connessione (fino a 8 MiB).';

  @override
  String get onlineWallpaperHours => 'h';

  @override
  String get onlineWallpaperInterval => 'Intervallo di download';

  @override
  String get onlineWallpaper => 'Carta da parati in linea';

  @override
  String get onlineWallpaperUrlError =>
      'Inserisci un\'immagine HTTPS diretta URL senza dettagli di accesso.';

  @override
  String get onlineWallpaperEnabled => 'Usa lo sfondo online';

  @override
  String get onlineWallpaperSource => 'Fonte dell\'immagine';

  @override
  String get bingWallpaper => 'Bing immagine del giorno';

  @override
  String get onlineWallpaperUrlSource => 'Diretto HTTPS URL';

  @override
  String get updatePlayOnly =>
      'Questa installazione riceve aggiornamenti tramite Google Play.';

  @override
  String get updateCheck => 'Controlla ora';

  @override
  String get updateInstalled => 'Installato';

  @override
  String get updateDownloadInstall => 'Scarica e installa';

  @override
  String get updateNoRelease =>
      'Non è disponibile alcuna versione compatibile più recente.';

  @override
  String get updateIncompatible =>
      'APK non corrisponde a questa applicazione, certificato o versione più recente. L\'installazione è stata bloccata.';

  @override
  String get updateError =>
      'Impossibile controllare, scaricare o aprire il programma di installazione. Riprova più tardi.';

  @override
  String get updateAvailable => 'Aggiornamento disponibile';

  @override
  String get appUpdates => 'Aggiornamenti dell\'applicazione';

  @override
  String get updatePermission =>
      'Consenti l\'installazione da questa applicazione nelle impostazioni di Android, torna qui e premi nuovamente Installa.';

  @override
  String get updateInstall => 'Installa l\'aggiornamento scaricato';

  @override
  String get updateHint =>
      'Fonte: GitHub / KirillShchetinnikov/CuteLauncher-Releases. I controlli automatici vengono eseguiti mentre il programma di avvio è aperto. Il download inizia quando lo scegli; Android richiede di confermare l\'installazione. I tuoi dati vengono conservati.';

  @override
  String get updateAutomatic => 'Controlla automaticamente una volta al giorno';

  @override
  String get allApplications => 'Tutte le applicazioni';

  @override
  String get adbAccessibility => 'Abilita la correzione del pulsante Home';

  @override
  String get adbAuthorization =>
      'Approvare l\'autorizzazione ADB sul televisore, quindi riprovare.';

  @override
  String get adbChangeConfirm =>
      'Applicare questa impostazione di sistema tramite ADB? L\'app Home precedente viene salvata prima di modificarla; gli altri servizi di accessibilità vengono preservati.';

  @override
  String get adbCheck => 'Controlla la connessione';

  @override
  String get adbDenied =>
      'Il sistema non ha consentito né confermato questa modifica.';

  @override
  String get adbDisable => 'Disabilita il launcher precedente';

  @override
  String get adbDisableConfirm =>
      'Disabilitare il launcher precedente salvato? Ciò richiede che CuteLauncher sia l\'app Home corrente. Ripristinalo con l\'azione di ripristino in questa configurazione.';

  @override
  String get adbHint =>
      'Prototipo solo per questo televisore (127.0.0.1). Abilita TCP ADB nelle opzioni sviluppatore, inserisci la sua porta e approva la richiesta di autorizzazione sulla TV. Il debug wireless con un codice di accoppiamento non è ancora supportato. La chiave privata rimane su questo dispositivo, al di fuori dei backup.';

  @override
  String get adbHome => 'Rendi CuteLauncher l\'app Casa';

  @override
  String get adbInvalid => 'Inserisci una porta compresa tra 1024 e 65535.';

  @override
  String get adbNoRecovery =>
      'Il ripristino non è disponibile: non è stato trovato nessun altro launcher o stato del servizio salvato.';

  @override
  String get adbPort => 'Porta TCP ADB';

  @override
  String get adbReady => 'Accesso ADB confermato.';

  @override
  String get adbRestore => 'Ripristina il launcher precedente';

  @override
  String get adbSuccess => 'Modifica applicata e verificata.';

  @override
  String get adbTitle => 'Configurazione ADB';

  @override
  String get adbUnavailable =>
      'Impossibile connettersi. Controllare TCP ADB, la porta e la richiesta di autorizzazione.';

  @override
  String get nightModeScheduled => 'Usa il programma';

  @override
  String get nightModeTitle => 'Modalità notturna';

  @override
  String get nightModeScope =>
      'È necessaria l\'autorizzazione di sovrapposizione per oscurare altre app. Senza di esso, l\'attenuazione funziona all\'interno di CuteLauncher. Il filtro TCL non necessita di autorizzazioni di sovrapposizione. Un\'opacità superiore all\'80% Android potrebbe bloccare l\'input touch in altre app; I tasti del telecomando della TV funzionano ancora.';

  @override
  String get nightModeEnd => 'Fine';

  @override
  String get nightModeStart => 'Inizia';

  @override
  String get nightModeDim => 'Oscuramento';

  @override
  String get nightModeWarmth => 'Filtro caldo';

  @override
  String get nightModeScheduleHint =>
      'Utilizza l\'ora della TV locale. Sono supportati i periodi notturni. Orari di inizio e di fine uguali disabilitano il filtro pianificato.';

  @override
  String get nightModeEnabled => 'Abilita la modalità notturna';

  @override
  String get nightModePermission => 'Consenti la visualizzazione su altre app';

  @override
  String get nightModePermissionGranted =>
      'È consentita la visualizzazione su altre app';

  @override
  String get backupDownloadsFailed =>
      'Impossibile salvare il backup in Download.';

  @override
  String get backupSaveDownloads => 'Salva il backup in Download';

  @override
  String get adbRestoreAccessibility =>
      'Ripristinare l\'accesso all\'accessibilità';

  @override
  String get nightModeAdbConfirm =>
      'Consentire a CuteLauncher di essere visualizzato su altre app utilizzando ADB locale? Abilita prima il debug TCP e autorizza la connessione. Utilizza la porta salvata nella procedura guidata ADB o 5555.';

  @override
  String get nightModeAdbPermission =>
      'Concedere l\'autorizzazione tramite ADB';

  @override
  String get nightModeNotificationsHint =>
      'La notifica ti consente di disattivare il filtro all\'esterno di CuteLauncher. Senza di esso, utilizzare questo menu.';

  @override
  String get nightModeNotificationsAllowed =>
      'Notifica in modalità notturna consentita';

  @override
  String get nightModeNotifications =>
      'Consenti la notifica della modalità notturna';

  @override
  String get categoryLastVisibleHint =>
      'Almeno una categoria deve rimanere visibile.';

  @override
  String get diagnosticsClear => 'Cancella la diagnostica della sessione';

  @override
  String get diagnosticsReady => 'Rapporto pronto';

  @override
  String get diagnosticsCreate => 'Crea rapporto';

  @override
  String get diagnosticsOperations => 'Operazioni registrate';

  @override
  String get diagnosticsCopied => 'Rapporto copiato';

  @override
  String get diagnosticsHint =>
      'Il report contiene la versione dell\'app, lo stato dell\'autorizzazione, l\'utilizzo della memoria e i risultati dell\'operazione. Sono esclusi chiavi, indirizzi, percorsi di file, elenchi di app e contenuti di notifica. Solo le ultime 50 operazioni vengono mantenute in memoria fino al riavvio dell\'app. Niente viene inviato automaticamente.';

  @override
  String get diagnosticsTitle => 'Diagnostica degli errori';

  @override
  String get diagnosticsCopyFailed => 'Impossibile copiare il rapporto.';

  @override
  String get diagnosticsCopy => 'Copia rapporto';

  @override
  String get diagnosticsCreating => 'Creazione rapporto…';

  @override
  String get tclBlueLightTitle => 'TCL filtro luce blu';

  @override
  String get tclBlueLightError =>
      'Impossibile leggere o verificare l\'impostazione del filtro TCL. Aggiorna il suo stato e riprova.';

  @override
  String get tclBlueLightUnsupported =>
      'L\'interfaccia del filtro TCL non è disponibile su questo televisore.';

  @override
  String get tclBlueLightRefresh => 'Aggiorna lo stato del filtro TCL';

  @override
  String get tclBlueLightHint =>
      'Controlla il filtro integrato per la protezione della salute degli occhi del televisore. Può anche seguire il programma della modalità notturna.';

  @override
  String get nightSolarSchedule => 'Tramonto e alba';

  @override
  String get nightNextStart => 'Prossimo inizio';

  @override
  String get nightScheduleTimeHint =>
      'Gli orari utilizzano il fuso orario della TV. Gli offset negativi sono precedenti; gli offset positivi sono successivi.';

  @override
  String get nightTemperature => 'Filtro temperatura colore';

  @override
  String get nightScheduleSettings => 'Impostazioni di pianificazione';

  @override
  String get nightCityName => 'Nome della città';

  @override
  String get nightSkipUntilNext =>
      'Disattiva la modalità notturna fino al prossimo tramonto';

  @override
  String get nightSunriseOffset => 'Fine relativa all\'alba';

  @override
  String get nightEnableUntilMorning =>
      'Abilita la modalità notturna fino alla prossima alba';

  @override
  String get nightPermissions => 'Autorizzazioni';

  @override
  String get nightTclSchedule => 'Includere il filtro TCL nella pianificazione';

  @override
  String get nightSearchCity => 'Cerca';

  @override
  String get nightRefreshSun => 'Aggiorna l\'alba e il tramonto';

  @override
  String get nightSolarUnavailable =>
      'Scegli una città e aggiorna gli orari del sole. Se l\'alba o il tramonto non sono disponibili, la programmazione solare viene messa in pausa.';

  @override
  String get nightSunsetOffset => 'Inizio relativo al tramonto';

  @override
  String get nightCityHint =>
      'Scegli la tua città invece di concedere l\'accesso alla posizione. Le coordinate selezionate vengono inviate a Sunrise-Sunset.org, o Open-Meteo come fallback, per recuperare l\'ora del sole.';

  @override
  String get nightResumeSchedule => 'Ritorna al programma';

  @override
  String get nightScheduleSource => 'Tipo di pianificazione';

  @override
  String get nightSolarCached =>
      'Utilizzo degli orari solari memorizzati nella cache; l\'aggiornamento Internet riproverà automaticamente.';

  @override
  String get nightTclScheduleHint =>
      'Utilizza la stessa programmazione mentre è abilitata la modalità notturna. Le modifiche manuali al filtro TCL durano fino alla successiva transizione programmata. Non è necessaria alcuna autorizzazione di sovrapposizione.';

  @override
  String get nightRefreshPermission => 'Aggiorna lo stato dei permessi';

  @override
  String get nightCityNotFound => 'Nessuna città trovata. Prova un altro nome.';

  @override
  String get nightNoOffset => 'Nessuna compensazione';

  @override
  String get nightManualSchedule => 'Programma personalizzato';

  @override
  String get nightChooseCity => 'Scegli città';

  @override
  String get nightPermissionUnknown =>
      'Lo stato dell\'autorizzazione di sovrapposizione è sconosciuto';

  @override
  String get nightNextEnd => 'Fine successiva';

  @override
  String get nightTemporaryOff =>
      'Dimmerazione temporaneamente disattivata fino al';

  @override
  String get nightCitySearchFailed =>
      'Impossibile cercare le città. Controlla la tua connessione Internet.';

  @override
  String get nightSolarAttribution =>
      'Orari solari giornalieri: Sunrise-Sunset.org; fallback: Open-Meteo. Ricerca città: GeoNames. Diversi giorni vengono memorizzati nella cache per l\'utilizzo offline.';

  @override
  String get nightTemporaryOn => 'Dimmerazione temporanea fino al';

  @override
  String get homeScreen => 'Schermata iniziale';

  @override
  String get appearanceSettings => 'Aspetto';

  @override
  String get generalSettings => 'Avanzato';

  @override
  String get advancedSettings => 'Avanzato';

  @override
  String get controlAndStartup => 'Launcher e controlli TV';

  @override
  String get sectionsAndOrder => 'Sezioni e ordine';

  @override
  String get topPanel => 'Pannello superiore';

  @override
  String get tileStyle => 'Stile piastrella';

  @override
  String get tilesAndLabels => 'Piastrelle ed etichette';

  @override
  String get highlightAndAnimation => 'Evidenziazione e animazione';

  @override
  String get androidTvSettings => 'Impostazioni Android TV';

  @override
  String get weatherSettings => 'Impostazioni meteo';

  @override
  String get showHighlightOutline => 'Mostra il contorno dell\'evidenziazione';

  @override
  String get resetTilesAndPanel =>
      'Ripristina le impostazioni del riquadro e del pannello';

  @override
  String get resetTilesAndPanelHint =>
      'Reimpostare i parametri aggiuntivi di riquadro, etichetta, evidenziazione e pannello superiore? Lo sfondo, il colore principale, lo stile delle piastrelle e la visibilità dell\'etichetta vengono conservati.';

  @override
  String get panelAppearanceSettings => 'Aspetto del pannello superiore';

  @override
  String get panelSharedHint =>
      'Modifica l\'aspetto nelle impostazioni dei riquadri.';

  @override
  String get effectsCompatibilityHint =>
      'Aspetto aggiuntivo: il contorno è sempre visibile e non pulsa. Lo stile dimensionale non ha contorni ereditati; il classico non pulsa. L\'intensità influenza la scala e l\'ombra; il ridimensionamento è limitato nello spazio.';

  @override
  String get sizeAndLayout => 'Dimensioni e disposizione';

  @override
  String get labelsGroup => 'Etichette';

  @override
  String get surfaceGroup => 'Superficie';

  @override
  String get clockAndDateGroup => 'Orologio e data';

  @override
  String get networkAndTrafficGroup => 'Rete e traffico';

  @override
  String get buttonsGroup => 'Pulsanti';

  @override
  String get notificationAppsHint =>
      'Disattiva le app di cui non ti servono le notifiche. Un interruttore abilitato consente le notifiche; è ancora possibile avviare l\'app.';

  @override
  String get notificationPanelLink => 'Aspetto del pannello superiore';

  @override
  String get overlayAccessAdb => 'Visualizzazione su altre app (ADB)';

  @override
  String get tileStyleModern => 'Moderno';

  @override
  String get tileStyleVolume => 'Dimensionale';

  @override
  String get showTime => 'Mostra l\'ora';

  @override
  String get showDate => 'Mostra data';

  @override
  String get showWeather => 'Mostra il meteo';

  @override
  String get showNetwork => 'Mostra lo stato della rete';

  @override
  String get showTraffic => 'Mostra traffico';

  @override
  String get scheduledBrightness => 'Luminosità programmata';

  @override
  String get followTileStyle => 'Segui lo stile';

  @override
  String get androidTvSettingsHint => 'Apri le impostazioni del sistema TV';

  @override
  String get autoHideTopPanel => 'Nascondi automaticamente il pannello';

  @override
  String get showSectionTitles => 'Mostra i titoli delle sezioni';

  @override
  String get usageDaily => 'Ogni giorno';

  @override
  String get usageWeekly => 'Settimanale';

  @override
  String get usageMonthly => 'Mensile';

  @override
  String get onlineWallpaperAddress => 'Indirizzo immagine (HTTPS)';

  @override
  String get watchNextAppLimits => 'Limiti per app';

  @override
  String get watchNextAppLimitsHint =>
      'I limiti della fonte si applicano prima del limite generale. Illimitato mantiene solo il limite generale; il contenuto nascosto rimane nascosto.';

  @override
  String get rememberCategoryFocus => 'Ricorda l\'ultima carta focalizzata';

  @override
  String get automaticBackups => 'Backup automatico';

  @override
  String get automaticBackupsHint =>
      'Copie giornaliere di impostazioni, sfondi e banner mentre il launcher è attivo. Una copia mancata viene eseguita dopo essere tornata al programma di avvio. Memorizzati privatamente su questo dispositivo, fino a 256 MiB in totale; la rimozione dell\'app o dei suoi dati li elimina. Conserva anche un backup esterno.';

  @override
  String get automaticBackupsEnabled => 'Backup automatico giornaliero';

  @override
  String get automaticBackupsKeep => 'Copie da conservare';

  @override
  String get automaticBackupCreateNow => 'Crea subito un punto di ripristino';

  @override
  String get automaticBackupFailed =>
      'L\'operazione di backup non è riuscita. Controlla lo spazio libero e riprova.';

  @override
  String get restorePoints => 'Punti di ripristino';

  @override
  String get noRestorePoints => 'Nessun punto di ripristino ancora';

  @override
  String get updatePrereleases => 'Aggiornare alle versioni preliminari';

  @override
  String get topPanelObjects => 'Oggetti';

  @override
  String get panelTransparency => 'Trasparenza del pannello';

  @override
  String get panelTextBackground => 'Sfondo del testo e del pulsante';

  @override
  String get panelTextBackgroundColor =>
      'Colore dello sfondo del testo e del pulsante';

  @override
  String get panelTextColor => 'Colore del testo e del pulsante';

  @override
  String get panelTextSize => 'Dimensioni del testo e dei pulsanti';

  @override
  String get panelFont => 'Carattere del testo';

  @override
  String get fontSans => 'Sans serif';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontMono => 'Monospazio';

  @override
  String get fontCondensed => 'Condensato';

  @override
  String get trafficPermissionGranted =>
      'Accesso alle statistiche sul traffico concesso';

  @override
  String get background => 'Sfondo';

  @override
  String get backgroundParameters => 'Parametri';

  @override
  String get resetAppearanceHint =>
      'Reimpostare lo sfondo, l\'accento, i riquadri, le etichette, l\'evidenziazione e l\'animazione?';

  @override
  String get wallpaperDimming => 'Oscuramento';

  @override
  String get wallpaperPlacement => 'Posizionamento';

  @override
  String get wallpaperDisplay => 'Visualizzazione dello sfondo';

  @override
  String get wallpaperContain => 'Mostra l\'intera immagine';

  @override
  String get wallpaperBlurred => 'Oltre copia sfocata';

  @override
  String get wallpaperCover => 'Riempi lo schermo';

  @override
  String get wallpaperBrightness => 'Luminosità della carta da parati';

  @override
  String get wallpaperSaturation => 'Saturazione';

  @override
  String get categoryPadding => 'Imbottitura di categoria';

  @override
  String get categoryLight => 'Luce';

  @override
  String get categoryBlue => 'Blu';

  @override
  String get categoryPurple => 'Viola';

  @override
  String get categoryAllRows => 'Tutto';

  @override
  String get categoryTeal => 'Verde acqua';

  @override
  String get categoryMaxRows => 'Righe della griglia visibili';

  @override
  String get categoryDark => 'Buio';

  @override
  String get categoryAppearance => 'Aspetto della categoria';

  @override
  String get categoryBackground => 'Sfondo della categoria';

  @override
  String get categoryTransparent => 'Trasparente';

  @override
  String get slideshowInterval => 'Cambia intervallo';

  @override
  String get slideshowFolderSelected =>
      'Accesso alle cartelle salvate su questo dispositivo.';

  @override
  String get slideshowRandom => 'Ordine casuale';

  @override
  String get wallpaperSlideshow => 'Presentazione della cartella';

  @override
  String get slideshowNext => 'Immagine successiva';

  @override
  String get slideshowFolderRequired =>
      'Scegli una cartella per avviare la presentazione.';

  @override
  String get slideshowHint =>
      'Fino a 1.000 immagini e 4.000 voci di cartelle; file fino a 8 MiB. I file danneggiati vengono ignorati e viene conservata l\'ultima immagine valida. I cambiamenti si fermano in background. Scegli di nuovo la cartella dopo il ripristino su un altro dispositivo.';

  @override
  String get slideshowSeconds => 's';

  @override
  String get slideshowError =>
      'Impossibile leggere le immagini. Scegli una cartella accessibile contenente immagini valide.';

  @override
  String get slideshowFolder => 'Scegli la cartella';

  @override
  String get slideshowRecursive => 'Includi sottocartelle';

  @override
  String get weatherSourceKeyRequired =>
      'Aggiungi una chiave API per questa fonte meteo.';

  @override
  String get weatherOpenWeatherCredit =>
      'Meteo: OpenWeather (openweathermap.org). I valori giornalieri riepilogano i periodi di previsione di tre ore disponibili.';

  @override
  String get weatherOpenWeatherHint =>
      'Utilizza la chiave per il meteo attuale e le previsioni per 5 giorni/3 ore. Ogni aggiornamento effettua due richieste; l\'accesso e i limiti dipendono dal tuo piano.';

  @override
  String get weatherOpenWeatherKey => 'OpenWeather API Chiave';

  @override
  String get mediaPause => 'Pausa';

  @override
  String get showNowPlaying => 'Mostra Ora in riproduzione su Home';

  @override
  String get nowPlayingAccessHint =>
      'I controlli multimediali richiedono l\'accesso alle notifiche per CuteLauncher. Vengono mostrate solo le azioni fornite dal giocatore.';

  @override
  String get nowPlaying => 'Adesso sto giocando';

  @override
  String get mediaNext => 'Traccia successiva';

  @override
  String get mediaPlay => 'Riprendi';

  @override
  String get mediaControlError =>
      'Il giocatore non è disponibile o non ha accettato questa azione.';

  @override
  String get nightUsageAccess => 'Consenti l\'accesso all\'utilizzo';

  @override
  String get nightExcludedAppsHint =>
      'Il filtro TCL sovrapposto e pianificato viene messo in pausa nelle app selezionate. È richiesto l\'accesso all\'utilizzo; senza di esso non è possibile applicare le esclusioni.';

  @override
  String get nightExcludedApps => 'App escluse';

  @override
  String get adbPairPort => 'Porta di accoppiamento';

  @override
  String get adbPairOverlayHint =>
      'Apri Debug wireless e Associa con codice di accoppiamento. Mantenere aperta la finestra di dialogo del codice di sistema. Questo modulo diventa attivo dopo 30 secondi. Inserisci entrambe le porte e il codice mostrato da Android.';

  @override
  String get adbOverlaySettings =>
      'Riporta il controllo su Impostazioni per 30 secondi';

  @override
  String get adbTlsHint =>
      'Utilizza il debug wireless nelle opzioni sviluppatore. L\'accoppiamento e la connessione hanno porte diverse. Se il firmware non dispone di una schermata del codice di accoppiamento o blocca le finestre in sovrapposizione, utilizzare invece TCP/RSA. Tutte le connessioni rimangono locali su questo televisore.';

  @override
  String get adbPaired =>
      'Accoppiato. Controllare la connessione utilizzando la porta di connessione di debug wireless.';

  @override
  String get adbTransport => 'Metodo di connessione';

  @override
  String get adbPairCode => 'Codice a sei cifre';

  @override
  String get adbOverlayRequired =>
      'L\'immissione del codice su Impostazioni richiede l\'autorizzazione per la visualizzazione su altre app.';

  @override
  String get adbOverlayPermission => 'Consenti la visualizzazione su altre app';

  @override
  String get adbTlsUnsupported =>
      'Questo firmware non può aprire la schermata Impostazioni richiesta o l\'overlay di accoppiamento. Utilizza TCP/RSA.';

  @override
  String get adbConnectPort => 'Porta di connessione';

  @override
  String get adbTls => 'TLS/codice di abbinamento';

  @override
  String get adbTcp => 'TCP/RSA';

  @override
  String get adbPairingFailed =>
      'Associazione non riuscita. Controlla il codice e la porta di accoppiamento, mantieni aperta la finestra di dialogo del codice Android e riprova.';

  @override
  String get adbTlsDisabled =>
      'Il debug wireless è disabilitato o il suo stato non è disponibile. Abilitalo nelle Opzioni sviluppatore.';

  @override
  String get adbPairOverlay =>
      'Inserisci il codice di accoppiamento su Impostazioni';

  @override
  String get adbPair => 'Coppia';

  @override
  String get adbDeveloperSettings => 'Apri le Opzioni sviluppatore';

  @override
  String get adbTwoWindowsHint =>
      'Se questo firmware supporta due finestre, mantieni aperta la finestra di dialogo di accoppiamento del sistema accanto a CuteLauncher e inserisci qui il suo codice. L\'accoppiamento diretto è disponibile solo quando entrambe le finestre sono aperte.';

  @override
  String get adbTwoWindows => 'Apri Impostazioni in una seconda finestra';

  @override
  String get autoLaunchBoot => 'Dopo l\'avvio della TV';

  @override
  String get autoLaunchOff => 'Disabilitato';

  @override
  String get autoLaunchTitle => 'Avvio automatico';

  @override
  String get autoLaunchDelay => 'Ritardo nel lancio';

  @override
  String get autoLaunchHdmi => 'Passa a un ingresso HDMI selezionato';

  @override
  String get autoLaunchWake => 'Dopo la veglia';

  @override
  String get autoLaunchHint =>
      'Scegli un\'app o un ingresso HDMI da aprire dopo l\'avvio o la riattivazione del TV. Imposta l\'evento e il ritardo di seguito. L\'azione viene eseguita una volta quando Android mostra CuteLauncher. Qualsiasi input remoto o l\'uscita dalla schermata iniziale annullano l\'attesa. Successivamente è possibile modificare liberamente gli ingressi HDMI. Imposta CuteLauncher come launcher predefinito o abilita Avvia all\'avvio, se necessario. Il rilevamento della scia richiede che CuteLauncher rimanga in esecuzione.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds secondi';
  }

  @override
  String get autoLaunchApp => 'Apri un\'app selezionata';

  @override
  String get autoLaunchTarget => 'Obiettivo di lancio';

  @override
  String get autoLaunchUnavailable =>
      'La destinazione non è disponibile oppure il firmware non consente questa azione.';

  @override
  String get autoLaunchCancelled => 'Lancio ritardato annullato.';

  @override
  String get syncTitle => 'Impostazioni di scambio';

  @override
  String get syncHint =>
      'Salva un file di impostazioni, trasferiscilo su un altro dispositivo e aprilo lì. Scambia nuovamente il file per aggiornare entrambi i dispositivi. L\'interfaccia, lo stile dei riquadri e le preferenze di visualizzazione sono condivisi. App, sezioni, file di sfondi, autorizzazioni, HOME, regole di avvio e segreti rimangono su questo dispositivo. Questo è lo scambio manuale; non viene utilizzato alcun account o connessione di rete in background.';

  @override
  String get syncExport => 'Salva le modifiche in un file';

  @override
  String get syncImport => 'Apri le modifiche da un altro dispositivo';

  @override
  String get syncSaved => 'File di scambio delle impostazioni salvato.';

  @override
  String get syncFailed =>
      'Impossibile scambiare le impostazioni. Non viene mantenuta alcuna importazione parziale. Controlla il file o aprilo di nuovo se le impostazioni sono cambiate durante la revisione.';

  @override
  String get syncPreviewHint =>
      'Esamina le modifiche prima di applicarle. In caso di conflitti, seleziona ciascuna riga per scegliere questo dispositivo o il file. Inizialmente è stata selezionata la conservazione di questo dispositivo. Annulla lascia le impostazioni invariate.';

  @override
  String get syncNoChanges =>
      'Nessuna nuova impostazione. Applicare per riconoscere la cronologia condivisa.';

  @override
  String syncLocalValue(String value) {
    return 'Questo dispositivo: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'Dal file: $value';
  }

  @override
  String get syncKeepLocal => 'Conflitto: mantieni questo dispositivo';

  @override
  String get syncUseFile => 'Conflitto: utilizzare il file';

  @override
  String get syncApply => 'Applicare le modifiche riviste';

  @override
  String get syncApplied =>
      'Impostazioni scambiate. Salva un nuovo file per inviare il risultato.';

  @override
  String syncStyleParameters(int count) {
    return 'Stile personalizzato: $count parametri (differenze sotto)';
  }

  @override
  String get cloudBackups => 'Backup nel cloud';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud. Inserisci l\'indirizzo HTTPS di una cartella esistente e una password per l\'app. I trasferimenti sono manuali; questa cartella memorizza la copia più recente.';

  @override
  String get cloudUrl => 'Indirizzo della cartella HTTPS';

  @override
  String get cloudUser => 'Nome utente';

  @override
  String get cloudPassword => 'Password dell\'app';

  @override
  String get cloudConnect => 'Controlla e salva l\'account';

  @override
  String get cloudCheck => 'Controlla la connessione';

  @override
  String get cloudDisconnect => 'Disconnetti l\'account';

  @override
  String get cloudDisconnectConfirm =>
      'Rimuovere questo account dalla TV? Le copie nel cloud rimarranno.';

  @override
  String get cloudUpload => 'Salva una copia sul cloud';

  @override
  String get cloudDownload => 'Ripristina dal cloud';

  @override
  String get cloudUploadConfirm =>
      'Sostituisci cutelauncher_backup.json in questa cartella con le impostazioni e i dati correnti?';

  @override
  String get cloudSuccess => 'Fatto';

  @override
  String get cloudConfigurationError =>
      'Controlla l\'indirizzo della cartella HTTPS, il nome utente e la password dell\'app.';

  @override
  String get cloudAuthorizationError =>
      'Accesso negato. Controlla i permessi del tuo account e della tua cartella.';

  @override
  String get cloudMissingError =>
      'La cartella o il backup non sono stati trovati.';

  @override
  String get cloudUnsupportedError =>
      'Questo indirizzo non supporta le operazioni WebDAV richieste. I reindirizzamenti non vengono seguiti; inserire l\'indirizzo della cartella finale.';

  @override
  String get cloudNetworkError =>
      'Connessione non riuscita o scaduta. Riprovare quando la rete sarà disponibile.';

  @override
  String get cloudFailed =>
      'Impossibile completare l\'azione di backup. Controlla l\'accesso allo spazio di archiviazione e riprova.';

  @override
  String get cloudStorageError =>
      'Lo spazio di archiviazione dell\'account non è disponibile. Disconnettiti e configura nuovamente l\'account.';

  @override
  String get adbPermissionChecking => 'Verifica dell\'accesso…';

  @override
  String get adbPermissionConnected =>
      'ADB connesso · concedere l\'autorizzazione';

  @override
  String get adbPermissionDisconnected =>
      'ADB disconnesso · impostare la connessione';

  @override
  String get adbSetupIntro =>
      'Abilita il debug e la rete ADB nelle impostazioni sviluppatore della TV, quindi fidati di CuteLauncher. Tutte le azioni ADB sono a tuo rischio e pericolo.';

  @override
  String get adbConnectionBlock => 'Collegamento ADB';

  @override
  String get adbNotChecked => 'Connessione non controllata';

  @override
  String get adbApplied => 'Già applicato';

  @override
  String get adbNotApplied => 'Non ancora applicato';

  @override
  String get adbDefaultBlock => 'Avvio predefinito';

  @override
  String get adbSystemDefault =>
      'Apri l\'impostazione di avvio predefinita del sistema';

  @override
  String get adbAssignDefault =>
      'Imposta CuteLauncher come launcher predefinito tramite ADB';

  @override
  String get adbRestoreDefault =>
      'Ripristina il precedente launcher predefinito tramite ADB';

  @override
  String get adbDefaultHint =>
      'Utilizzare ADB se il menu di sistema non può impostare il launcher predefinito.';

  @override
  String get adbBuiltinHint =>
      'La disabilitazione del launcher integrato consente invece al sistema di aprire CuteLauncher. I menu e i pulsanti del televisore potrebbero risentirne. Abilita il launcher integrato per annullare questa operazione.';

  @override
  String get adbHomeBlock => 'Tasto Home e avvio';

  @override
  String get adbEnableService =>
      'Abilita il servizio di accessibilità CuteLauncher tramite ADB';

  @override
  String get adbHomeOverride => 'Sostituisci il pulsante Home';

  @override
  String get adbHomeOptional =>
      'Se il launcher integrato è disabilitato, l\'override della Home e l\'avvio all\'avvio della TV sono facoltativi.';

  @override
  String get adbEnableBuiltin => 'Abilita il launcher integrato tramite ADB';

  @override
  String get adbDisableBuiltin =>
      'Disabilita il launcher integrato tramite ADB';

  @override
  String get adbNoBuiltin =>
      'Nessun launcher Google TV / Android TV integrato trovato.';

  @override
  String get adbChanged =>
      'Stato cambiato. Controlla la connessione e conferma nuovamente l\'azione.';

  @override
  String get adbEffectHome =>
      'CuteLauncher diventerà il launcher predefinito del sistema. Il launcher corrente verrà salvato per il ripristino.';

  @override
  String get adbEffectRestore =>
      'Il programma di avvio precedente verrà abilitato e reso predefinito. Se non disponibile o non salvato, viene selezionato il primo altro launcher disponibile. Ciò non disabilita la correzione del pulsante Home.';

  @override
  String get adbEffectDisable =>
      'L\'app di avvio integrata verrà disabilitata per l\'utente TV. I menu e i pulsanti del televisore potrebbero smettere di funzionare. L\'app non viene disinstallata.';

  @override
  String get adbRecoveryHomeDisable =>
      'Anche l\'intera procedura guidata di configurazione di Google TV, inclusa la schermata iniziale di ripristino, verrà disabilitata in modo che CuteLauncher possa diventare il launcher predefinito. Le funzionalità della procedura guidata di configurazione non saranno disponibili fino al ripristino. Gli stati originali di entrambi i pacchetti verranno salvati per il ripristino.';

  @override
  String get adbRecoveryHomeRestore =>
      'Anche la procedura guidata di configurazione Google TV tornerà allo stato salvato.';

  @override
  String get adbDisableHomeUnavailable =>
      'Un\'altra schermata iniziale ha una priorità più alta. Non può essere disabilitato in modo sicuro da questo launcher.';

  @override
  String get adbEffectEnable =>
      'Il programma di avvio integrato verrà ripristinato allo stato salvato o abilitato se non è stato salvato nessuno stato. Il sistema potrebbe selezionarlo nuovamente come launcher predefinito.';

  @override
  String get adbEffectAccessibility =>
      'Il servizio di accessibilità CuteLauncher sarà abilitato. Può ricevere eventi Home; l\'intercettazione è controllata da un interruttore separato. Gli altri servizi vengono mantenuti.';

  @override
  String get adbEffectAccessibilityRestore =>
      'Il servizio CuteLauncher tornerà allo stato precedente alla concessione dell\'accesso ADB. Altri servizi di accessibilità vengono preservati.';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher potrà visualizzare finestre su altre app, incluso il filtro notturno.';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher riceverà l\'accesso alle notifiche tramite il proprio servizio di ascolto.';

  @override
  String get adbEffectWatchNext =>
      'CuteLauncher riceverà l\'accesso a Continua a guardare i dati.';

  @override
  String get adbEffectUsage =>
      'CuteLauncher riceverà l\'accesso alle statistiche di utilizzo per il rilevamento del traffico e delle app in primo piano.';

  @override
  String get adbEffectWriteSettings =>
      'CuteLauncher potrà modificare le impostazioni di luminosità del sistema.';

  @override
  String get adbNoAvailableLauncher =>
      'Non sono stati trovati altri launcher installati. Il ripristino non è disponibile.';

  @override
  String get adbUnsupported =>
      'Non disponibile su questo dispositivo: nessun comando ADB supportato.';

  @override
  String get adbHomeUnavailable =>
      'Il launcher integrato ha la priorità di sistema. L\'assegnazione diretta tramite ADB non è disponibile; utilizzare l\'accessibilità o disabilitare il launcher integrato.';

  @override
  String get nightBatteryExempt => 'CuteLauncher è esente da ottimizzazione';

  @override
  String get nightBatteryHint =>
      'Può aiutare la pianificazione a funzionare in background. Non garantisce che il processo sopravviva allo standby.';

  @override
  String get nightBatteryOptimized =>
      'CuteLauncher è soggetto a ottimizzazione';

  @override
  String get nightBatteryTitle => 'Ottimizzazione della batteria';

  @override
  String get nightBatteryUnavailable =>
      'Le impostazioni di sistema non sono disponibili su questo firmware oppure l\'accesso è stato negato.';

  @override
  String get nightBatteryUnknown => 'Stato di esenzione sconosciuto';

  @override
  String get nightBatteryOpenApps => 'Apri le impostazioni delle app';

  @override
  String get nightBatteryGuide =>
      '1. Nelle Impostazioni app, apri Accesso app speciale.\n2. Selezionare Ottimizzazione batteria (a volte Risparmio energetico).\n3. Trova CuteLauncher; seleziona Tutte le app se necessario.\n4. Disattiva l\'ottimizzazione o seleziona Senza restrizioni.\nI nomi dei menu e la disponibilità dipendono dal firmware del televisore.';

  @override
  String get updateNotifications => 'Mostra notifiche di aggiornamento';

  @override
  String get diagnosticsSave => 'Salva il rapporto su file';

  @override
  String get diagnosticsSaved => 'Rapporto salvato';

  @override
  String get diagnosticsSaveFailed =>
      'Impossibile salvare il rapporto. Controlla il file manager e la cartella di destinazione.';

  @override
  String get memoryCacheSize => 'Dimensioni della cache delle immagini';

  @override
  String get memoryProcess => 'Memoria dell\'app';

  @override
  String get memoryImages => 'Cache di immagini';

  @override
  String get diagnosticsExportOpened =>
      'Scegli una cartella nel file manager e salva il report.';

  @override
  String get adbDisableService =>
      'Disabilitare il servizio di accessibilità CuteLauncher tramite ADB';

  @override
  String get adbDefaultSettings => 'Impostazioni di avvio predefinite';

  @override
  String get adbHomeSettings => 'Impostazioni del pulsante Home';

  @override
  String get adbAccessibilitySettings =>
      'Apri le impostazioni di accessibilità';

  @override
  String get adbAccessibilityGuide =>
      'Seleziona CuteLauncher nel menu di sistema e abilita il suo servizio. Torna qui per configurare l\'intercettazione domestica. Per disabilitarlo, disattivare il servizio CuteLauncher nello stesso menu.';

  @override
  String get adbEffectAccessibilityDisable =>
      'Il servizio CuteLauncher verrà disabilitato. Le intercettazioni domestiche verranno interrotte. Altri servizi di accessibilità vengono preservati.';

  @override
  String get backupAutoEnabled => 'Backup automatico';

  @override
  String get backupClientId => 'ID cliente';

  @override
  String get backupClientSecret => 'Segreto del cliente';

  @override
  String get backupCloudImportConfirm =>
      'Tutte le impostazioni locali, le categorie e le immagini verranno sostituite con i dati cloud. Continuare?';

  @override
  String get backupConfigured => 'Configurato';

  @override
  String get backupConnection => 'Impostazioni di connessione';

  @override
  String get backupCreated => 'Creato';

  @override
  String get backupDaily => 'Ogni giorno';

  @override
  String get backupDriveHelp =>
      'Seleziona Connetti e conferma il codice sul tuo telefono. I backup sono visibili nella cartella CuteLauncher in Google Drive, dove è possibile scaricarli o eliminarli. Mantieni invariati i nomi dei file per il ripristino in-app. Riconnettiti dopo l\'aggiornamento dai backup nascosti; i vecchi backup non vengono migrati automaticamente.';

  @override
  String get backupFrequency => 'Frequenza di backup';

  @override
  String get backupHourly => 'Ogni ora';

  @override
  String get backupLocal => 'Copie locali';

  @override
  String get backupMinutes => 'min';

  @override
  String get backupMode => 'Modalità';

  @override
  String get backupNever => 'Nessun backup ancora';

  @override
  String get backupNotConfigured => 'Non configurato';

  @override
  String get backupOptions => 'Opzioni di backup';

  @override
  String get backupSaveMode => 'Backup';

  @override
  String get backupScope => 'Backup su tutti i televisori';

  @override
  String get backupSyncScope => 'Sincronizzazione tra televisori';

  @override
  String get backupSeparate => 'Separato per ogni TV';

  @override
  String get backupShared => 'Stesse impostazioni per tutti i televisori';

  @override
  String get backupStorage => 'Stoccaggio';

  @override
  String get backupSyncHelp =>
      'Scarica i dati e carica le modifiche. L’ultimo cambiamento vince i conflitti. Gli orologi della TV devono essere corretti. La sincronizzazione viene eseguita mentre il launcher è aperto.';

  @override
  String get backupSyncLimit => 'Controlla non più spesso di';

  @override
  String get backupSyncMode => 'Sincronizzazione';

  @override
  String get backupSyncOptions => 'Opzioni di sincronizzazione';

  @override
  String get backupTime => 'Tempo di backup';

  @override
  String get backupWeekday => 'Giorno della settimana';

  @override
  String get backupWeekly => 'Settimanale';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'Le copie locali vengono eliminate con l\'app o i suoi dati. Conservane una copia anche fuori dalla TV.';

  @override
  String get panelObjectOrder => 'Ordine degli oggetti';

  @override
  String get panelInformationGroup => 'Informazioni';

  @override
  String get panelOrderHint =>
      '◄ / ► avvia o termina lo spostamento; ▲ / ▼ cambia l’ordine e passa all’altro lato al confine dei gruppi; OK / Indietro termina.';

  @override
  String get panelTextBackgroundTransparency =>
      'Trasparenza dello sfondo del testo e dei pulsanti';

  @override
  String get weatherCityHint =>
      'Inserisci il nome della città in inglese, ad esempio Mosca.';

  @override
  String get weatherCityNotFound =>
      'Città non trovata. Controlla il nome della città in inglese.';

  @override
  String get weatherLocationAutomatic => 'Ottieni automaticamente';

  @override
  String get weatherLocationAutomaticHint =>
      'Ottieni le coordinate del dispositivo. È richiesta l\'autorizzazione alla posizione.';

  @override
  String get weatherLocationManual => 'Inserisci manualmente';

  @override
  String get weatherLocationPermissionDenied =>
      'Consenti l\'accesso alla posizione nelle impostazioni Android e riprova.';

  @override
  String get weatherLocationUnavailable =>
      'Impossibile ottenere le coordinate. Controlla le impostazioni di posizione di Android o inserisci una città manualmente.';

  @override
  String get nightFilterSettings => 'Impostazioni filtro';

  @override
  String get nightScheduleMenu => 'Programma';

  @override
  String get nightScheduleInactive => 'Il programma è interrotto';

  @override
  String get nightLocation => 'Posizione';

  @override
  String get nightLocationAutomatic => 'Ottieni automaticamente';

  @override
  String get nightLocationManual => 'Inserisci manualmente';

  @override
  String get nightLocationFailed =>
      'Posizione non disponibile. Controlla le impostazioni di autorizzazione e posizione del sistema.';

  @override
  String get nightCityEnglish => 'Inserisci il nome della città in inglese';

  @override
  String get nightOverlayBrief =>
      'Consente la visualizzazione del filtro su altre app.';

  @override
  String get weatherGetLocation => 'Ottieni la posizione';

  @override
  String get backupLastCreated => 'L\'ultimo backup è stato creato:';

  @override
  String get backupManagement => 'Gestisci i backup';

  @override
  String get backupCopyList => 'Elenco di backup';

  @override
  String get backupRefreshCopyList => 'Aggiorna l\'elenco dei backup';

  @override
  String get backupCreateNow => 'Crea un nuovo backup adesso';

  @override
  String get backupFolderPath => 'Cartella di backup';

  @override
  String get backupPrivateFolder => 'Cartella dell\'applicazione privata';

  @override
  String get backupRestoreCopy => 'Ripristina questo backup';

  @override
  String get backupDeleteConfirm => 'Eliminare il backup selezionato?';

  @override
  String get blockedAppsGroup => 'App bloccate';

  @override
  String get notificationSettingsButton => 'Impostazioni di notifica';

  @override
  String get hidePersistentNotificationsHint =>
      'Nascondi le notifiche persistenti nell\'elenco e su altre app.';

  @override
  String get nightTransitionTime => 'Tempo di transizione';

  @override
  String get brightnessSolar =>
      'Utilizza la pianificazione della modalità notturna';

  @override
  String get brightnessAfterSunrise => 'Dopo l\'alba';

  @override
  String get brightnessAfterSunset => 'Dopo il tramonto';

  @override
  String get brightnessTransitionTime =>
      'Tempo di transizione della luminosità';

  @override
  String get brightnessSolarUnavailable =>
      'La pianificazione della modalità notturna non è disponibile. Controlla gli orari e la posizione.';

  @override
  String get persistentNotificationCannotDelete =>
      'Questa notifica persistente non può essere eliminata. Puoi solo bloccarlo.';

  @override
  String get diagnosticsCreateFailed =>
      'Impossibile creare il rapporto diagnostico. Riprova.';

  @override
  String get backupListFailed =>
      'Impossibile caricare l\'elenco dei backup. Controlla l\'accesso allo spazio di archiviazione selezionato.';

  @override
  String get updateInstallerFailed =>
      'Impossibile aprire il programma di installazione dell\'aggiornamento. Riprovare e verificare che il programma di installazione Android sia disponibile.';

  @override
  String get backupFolderFailed =>
      'Impossibile selezionare o salvare la cartella di backup. Scegli una cartella accessibile e riprova.';

  @override
  String get updateDownloadFailed =>
      'Impossibile scaricare l\'aggiornamento. Controlla la connessione Internet e lo spazio di archiviazione disponibile.';

  @override
  String get backupDeleteFailed =>
      'Impossibile eliminare il backup. Controlla le autorizzazioni di eliminazione e riprova.';

  @override
  String get updateCheckFailed =>
      'Impossibile verificare la presenza di aggiornamenti. Controlla la connessione Internet e riprova.';

  @override
  String get backupCreateFailed =>
      'Impossibile creare il backup. Controlla l\'accesso allo spazio di archiviazione e lo spazio disponibile.';

  @override
  String get wallpaperChangeFailed =>
      'Impossibile cambiare lo sfondo. Controlla l\'accesso al file e riprova.';

  @override
  String get backupDownloadsFolder => 'Download / CuteLauncher';

  @override
  String get backupChooseFolder => 'Scegli una cartella nel file manager';

  @override
  String get backupFolderPickerUnavailable =>
      'Su questo televisore non è disponibile il selettore di cartelle. Scegli Download / CuteLauncher o la cartella interna dell\'app.';

  @override
  String get driveConfigurationError =>
      'Le credenziali Google Drive mancano o non sono valide. Inserisci l\'ID client e il segreto client del client TV OAuth.';

  @override
  String get driveCodeExpired =>
      'Google Drive Accesso scaduto. Seleziona Controlla e salva account per ottenere un nuovo codice.';

  @override
  String get brightnessAfterNightStart => 'Notturno';

  @override
  String get brightnessAfterNightEnd => 'Diurno';

  @override
  String get backupSyncSettings => 'Impostazioni da sincronizzare';

  @override
  String get backupSyncHomeGroup => 'Schermata iniziale, sezioni e app';

  @override
  String get backupSyncAppearanceGroup => 'Aspetto, sfondi e banner';

  @override
  String get backupSyncDisplayGroup =>
      'Modalità notturna, luminosità e salvaschermo';

  @override
  String get backupSyncControlsGroup => 'Launcher e controlli TV';

  @override
  String get backupSyncGeneralGroup =>
      'Lingua, aggiornamenti e altre impostazioni';

  @override
  String get backupSyncGroupsHelp =>
      'I blocchi disabilitati rimangono locali su questa TV. La selezione del blocco è sincronizzata tra i dispositivi.';

  @override
  String get backupSyncGroupsFailed =>
      'Impossibile salvare la selezione delle impostazioni per la sincronizzazione. Riprova.';

  @override
  String get tileLayoutMode => 'Disposizione delle piastrelle';

  @override
  String get tileLayoutAuto =>
      'Automatico in base alla dimensione della piastrella';

  @override
  String get tileLayoutColumns => 'Conteggio colonne fisso';

  @override
  String get tileLayoutRows => 'Conteggio righe fisso';

  @override
  String get tileRowCount => 'Conteggio delle righe';

  @override
  String get useGlobalTileSettings => 'Utilizza le impostazioni globali';

  @override
  String get centerSelection => 'Posizione di selezione';

  @override
  String get selectionBottom => 'In basso';

  @override
  String get selectionLower => 'Medio basso';

  @override
  String get selectionCenter => 'Centro';

  @override
  String get selectionUpper => 'Medio alto';

  @override
  String get selectionTop => 'In alto';

  @override
  String get settingsStyle => 'Stile delle impostazioni';

  @override
  String get tileFocusEnlargement => 'Ingrandimento del fuoco';

  @override
  String get tileFocusShadowStrength => 'La forza dell\'ombra';

  @override
  String get tileFocusLift => 'Ascensore';

  @override
  String get tileFocusLiftHeight => 'Altezza di sollevamento';

  @override
  String get tileFocusBorderColor => 'Mettere a fuoco il colore del bordo';

  @override
  String get tileFocusAccentColor => 'Colore accento';

  @override
  String get tileFocusDynamicColor => 'Colori dinamici';

  @override
  String get tileSizeFromColumns =>
      'La dimensione delle tessere è determinata dal numero di colonne e dalla larghezza della sezione.';

  @override
  String get resetSectionToGlobal =>
      'Ripristina le impostazioni sui valori condivisi';

  @override
  String get resetSectionToGlobalHint =>
      'Ripristinare i titoli, le icone e lo sfondo delle sezioni condivise e reimpostare la spaziatura interna?';

  @override
  String get resetStyleSection => 'Reimposta questa sezione';

  @override
  String get resetStyleSectionHint =>
      'Ripristinare le impostazioni predefinite solo per questa sezione?';

  @override
  String get notificationStyle => 'Stile di notifica';

  @override
  String get styleBackgroundColor => 'Colore di sfondo';

  @override
  String get styleTransparency => 'Trasparenza dello sfondo';

  @override
  String get styleTextSize => 'Dimensione del testo';

  @override
  String get styleTextColor => 'Colore del testo';

  @override
  String get noticeSize => 'Dimensioni della notifica';

  @override
  String get noticeStylePreview => 'Anteprima della notifica';

  @override
  String get backupSyncHomeOptions => 'Comportamento e opzioni generali';

  @override
  String get backupSyncBackground => 'Sfondo e banner personalizzati';

  @override
  String get backupSyncTiles =>
      'Stile dei riquadri, dei menu e delle notifiche';

  @override
  String get backupSyncWeatherSource => 'Origine e posizione';

  @override
  String get backupSyncWeatherDisplay =>
      'Visualizzazione meteo e unità di temperatura';

  @override
  String get backupSyncNotificationSettings =>
      'Visualizzazione e filtri delle notifiche';

  @override
  String get backupSyncOther => 'Altre impostazioni';

  @override
  String get tileFocusBorderStyle => 'Stile del bordo';

  @override
  String get tileFocusOutline => 'Contorno';

  @override
  String get tileFocusGlow => 'Bagliore';

  @override
  String get tileFocusNoBorder => 'Nessun confine';

  @override
  String get tileShowFocusShadow => 'Mostra ombra';

  @override
  String get homeLayoutRow => 'Fila orizzontale';

  @override
  String get homeLayoutRows => 'Righe multiple';

  @override
  String get homeLayoutGrid => 'Griglia';

  @override
  String get homeCardCount => 'Carte visibili attraverso';

  @override
  String get homeAuto => 'Automatico';

  @override
  String get homeFree => 'Scorrimento libero';

  @override
  String get homeAnchored => 'Sezione ancorata';

  @override
  String get homeScrollMode => 'Scorrimento della sezione';

  @override
  String get homeSectionPosition => 'Posizione della sezione attiva';

  @override
  String get homeLabelMode => 'Etichette dell\'applicazione';

  @override
  String get homeLabelNone => 'Nessuna etichetta';

  @override
  String get homeLabelSelected => 'Solo applicazione selezionata';

  @override
  String get homeLabelAll => 'Tutte le applicazioni';

  @override
  String get homeInherited => 'Valore ereditato';

  @override
  String get homeOwnReset => 'Valore personalizzato · usa globale';

  @override
  String get homeParameters => 'Parametri';

  @override
  String get homeSectionStyle => 'Aspetto della sezione';

  @override
  String get homeSectionGap => 'Spazio tra le sezioni';

  @override
  String get homeSectionIcons => 'Icone di sezione';

  @override
  String get homeInactiveOpacity => 'Opacità della sezione inattiva';

  @override
  String get homeResetSection =>
      'Ripristina l\'aspetto della sezione ereditata';

  @override
  String get homeCalculatedSize =>
      'La dimensione viene calcolata dal conteggio delle carte';

  @override
  String homeGapLimited(int gap) {
    return 'La spaziatura è limitata a $gap per mantenere il conteggio delle carte selezionate.';
  }

  @override
  String get homeResetLayout => 'Reimposta il layout della sezione';

  @override
  String homeVisibleRows(int count) {
    return 'Righe completamente visibili: $count';
  }

  @override
  String get homeStylePartial =>
      'Si applica solo alle sezioni che ereditano questo valore e lo supportano nel layout corrente.';

  @override
  String get homeStyleUnavailable =>
      'Non disponibile nelle impostazioni della sezione corrente. Controllare il layout e le sostituzioni locali.';

  @override
  String get homeStyleNeedsRows => 'Disponibile per più righe o una griglia.';

  @override
  String get homeStyleNeedsLabels =>
      'Consenti alle etichette di modificarne dimensione e colore.';

  @override
  String get homeStyleNeedsAllLabels =>
      'La posizione si applica solo alle etichette su tutte le carte. Il titolo selezionato rimane sotto la sezione.';

  @override
  String get homeStyleNeedsScale =>
      'Seleziona l\'effetto di messa a fuoco dell\'ingrandimento.';

  @override
  String get homeStyleNeedsLift => 'Seleziona l\'effetto Lift Focus.';

  @override
  String get homeStyleNeedsBorder => 'Abilita prima un contorno o un bagliore.';

  @override
  String get homeStyleNeedsTitle =>
      'Abilita il titolo della sezione per mostrare la sua icona.';

  @override
  String get homeStyleEconomy =>
      'Disabilitato dal salvataggio della memoria. Il valore salvato viene mantenuto.';

  @override
  String get homeStyleOpaque =>
      'Riduci l\'opacità dello sfondo del riquadro per vedere la sfocatura.';

  @override
  String get homeStyleOverridden =>
      'Le sezioni visibili utilizzano i propri valori. Scegli \"Utilizza globale\" in una sezione per applicare questa impostazione.';

  @override
  String get homeStyleIconHint =>
      'La dimensione dell\'icona influisce sulle carte con l\'icona di un\'app. I banner TV riempiono la scheda in modo indipendente.';

  @override
  String get homeStyleShadowHint =>
      'Il salvataggio della memoria limita l\'ombra delle carte inattive a 4. L\'ombra del fuoco è configurata separatamente.';

  @override
  String get homeStyleTransparent =>
      'Il colore di sfondo è invisibile con opacità zero. Aumenta l\'opacità dello sfondo del riquadro.';

  @override
  String get homeStyleSingleColumn =>
      'Una griglia a colonna singola non presenta spazi orizzontali.';

  @override
  String get homeStyleAutoOnly =>
      'La dimensione cambia solo nelle sezioni con conteggio automatico delle carte che ereditano la dimensione globale.';

  @override
  String get sleepTimerThirtySeconds => '30 secondi (prova)';

  @override
  String get sleepTimer => 'Temporizzatore di sonno';

  @override
  String sleepTimerMinutes(int minutes) {
    return '${minutes}min';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ore',
      one: '1 ora',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1,5 ore';

  @override
  String get sleepTimerAllowExact => 'Consenti timer precisi';

  @override
  String get sleepTimerExactRequired =>
      'Consenti timer precisi nelle impostazioni Android, quindi seleziona nuovamente una durata.';

  @override
  String get sleepTimerAccessRequired =>
      'Abilita l\'accessibilità CuteLauncher o connetti ADB locale in Impostazioni → Altro → ADB.';

  @override
  String get sleepTimerFailed =>
      'Impossibile impostare o completare il timer di spegnimento. Verifica accessibilità e ADB locale.';

  @override
  String get nightIgnoreHdmiInputs => 'Ignora gli ingressi HDMI';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'Metti in pausa il filtro notturno mentre guardi HDMI. È richiesto l\'accesso all\'utilizzo; il rilevamento dell\'ingresso dipende dal firmware del televisore.';

  @override
  String get inputsSettings => 'Impostazioni di ingresso';

  @override
  String get inputsUseCecNames => 'Utilizza i nomi dei dispositivi da CEC';

  @override
  String get inputsNamesHint =>
      'Priorità nome: il tuo nome in CuteLauncher → CEC (se abilitato) → nome dalle impostazioni Android → nome input standard.';

  @override
  String get inputNameHint => 'Lascia vuoto per un nome automatico';

  @override
  String get inputsSaveFailed => 'Impossibile salvare le impostazioni di input';

  @override
  String get inputIcon => 'Icona di ingresso';

  @override
  String get inputIconTv => 'televisione';

  @override
  String get inputIconGame => 'Consolle di gioco';

  @override
  String get inputIconComputer => 'Calcolatore';

  @override
  String get inputIconReceiver => 'Ricevitore';

  @override
  String get inputIconDisc => 'Lettore di dischi';

  @override
  String get inputIconStream => 'Dispositivo di streaming';

  @override
  String get nightInputExclusions => 'Esclusioni di input';

  @override
  String get nightSelectInputs => 'Seleziona gli input da ignorare';

  @override
  String get nightNoInputsSelected =>
      'Nessun ingresso selezionato. Il filtro verrà applicato a ogni input.';

  @override
  String get nightPictureExclusions => 'Esclusioni della modalità immagine';

  @override
  String get nightPictureExclusionsHint =>
      'Seleziona le modalità che mettono in pausa l\'attenuazione, la sovrapposizione calda e il filtro TCL collegato. Il programma è conservato. Il rilevamento è stato verificato su TCL; l\'accesso all\'utilizzo non è richiesto.';

  @override
  String get nightPictureUnavailable =>
      'La modalità immagine corrente non è disponibile su questo firmware. La tua selezione viene salvata; le esclusioni si applicano solo quando il rilevamento ha esito positivo.';

  @override
  String get nightPictureCurrent => 'Modalità corrente';

  @override
  String get nightPictureRefresh => 'Aggiorna la modalità corrente';

  @override
  String get nightPictureCode => 'Codice modalità';

  @override
  String get nightPictureStandard => 'Norma';

  @override
  String get nightPictureDynamic => 'Dinamico';

  @override
  String get nightPictureMovie => 'Film';

  @override
  String get nightPictureSport => 'Sport';

  @override
  String get nightPictureIntelligent => 'Intelligente';

  @override
  String get nightPictureBright => 'Luminoso (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'Norma';

  @override
  String get systemApplications => 'App di sistema';

  @override
  String get removeFromCategory => 'Rimuovi dalla categoria';

  @override
  String get noRemovableCategories =>
      'Questa app non è stata aggiunta manualmente ad alcuna sezione. Le sezioni automatiche non possono essere modificate.';

  @override
  String get remoteButtonsTitle => 'Rimappatura dei tasti del telecomando';

  @override
  String get remoteButtonsStart => 'Verifica tasti (120 s)';

  @override
  String get remoteButtonsStop => 'Termina verifica';

  @override
  String get remoteButtonsHint =>
      'La verifica mostra codici, rilasci e ripetizioni e salva un rapporto di testo sul TV. Esci dalla pagina dopo l’avvio per evitare che OK controlli la registrazione.';

  @override
  String get remoteButtonsEmpty =>
      'Nessun evento. Se un tasto apre un’app, torna qui per vedere il risultato.';

  @override
  String get remoteButtonsService => 'Servizio connesso';

  @override
  String get remoteButtonsRefresh => 'Aggiorna';

  @override
  String get remoteBindings => 'Assegnazioni dei tasti';

  @override
  String get remoteMappingsEnabled => 'Attiva rimappatura';

  @override
  String get remoteMappingsAdd => 'Aggiungi assegnazione';

  @override
  String get remoteMappingKey => 'Tasto';

  @override
  String get remoteMappingAction => 'Azione';

  @override
  String get remoteMappingLearn => 'Rileva un tasto';

  @override
  String get remoteMappingLearnHint =>
      'Premi un tasto aggiuntivo entro 30 secondi. Navigazione, Power, ricerca vocale e volume sono protetti.';

  @override
  String get remoteMappingsHint =>
      'Le assegnazioni richiedono il servizio di accessibilità. Sono sospese nell’editor e durante la diagnostica. Home, Indietro, frecce e OK mantengono la navigazione.';

  @override
  String get remoteMappingsReset => 'Reimposta assegnazioni';

  @override
  String get remoteMappingsResetConfirm =>
      'Eliminare tutte le assegnazioni e disattivare la rimappatura?';

  @override
  String get remoteMappingInvalid =>
      'Salvataggio non riuscito. Controlla tasto e destinazione. I webhook richiedono HTTPS o HTTP su rete locale.';

  @override
  String get remoteMappingBack => 'Indietro';

  @override
  String get remoteMappingProfile => 'Profilo';

  @override
  String get remoteMappingChannels => 'Canali';

  @override
  String get remoteMappingQuickSettings => 'Impostazioni rapide TCL';

  @override
  String get remoteMappingTrigger => 'Tipo di pressione';

  @override
  String get remoteMappingPress => 'Pressione breve';

  @override
  String get remoteMappingHold => 'Pressione prolungata';

  @override
  String get remoteMappingHoldHint =>
      'Tieni premuto per 650 ms: una sola azione, senza quella breve. Se è assegnata solo la pressione prolungata, quella breve non fa nulla.';

  @override
  String get remotePanel => 'Pannello mobile';

  @override
  String get remotePanelSettingsBackground =>
      'Usa il colore di sfondo delle impostazioni';

  @override
  String get remotePanelPreview => 'Apri pannello';

  @override
  String get settingsHelp => 'Ulteriori informazioni';

  @override
  String get settingsHelpScroll => '▲ / ▼ — scorri il testo';

  @override
  String get panelClockStyle => 'Aspetto dell’orologio';

  @override
  String get clockPreset => 'Stile dell’orologio';

  @override
  String get clockCustom => 'Personalizzato';

  @override
  String get clockWeight => 'Spessore del carattere';

  @override
  String get clockGlow => 'Bagliore del testo';

  @override
  String get clockAnimate => 'Anima le cifre';

  @override
  String get clockBackground => 'Sfondo dell’orologio';

  @override
  String get clockRadius => 'Arrotondamento dello sfondo';

  @override
  String get dateCalendarEnabled => 'Apri il calendario premendo la data';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get dateSettings => 'Impostazioni data';

  @override
  String get clockSharedBackground => 'Stesso sfondo degli altri oggetti';

  @override
  String get clockDefaultBackground => 'Sfondo predefinito';

  @override
  String get remotePanelInheritAppearance =>
      'Usa l’aspetto del pannello superiore';

  @override
  String get remotePanelDisabledInLauncher =>
      'Il pannello popup è disattivato mentre CuteLauncher è sullo schermo.';

  @override
  String get remoteAccessSettings => 'Configura accesso';

  @override
  String get remoteButtonsTest => 'Test dei pulsanti';

  @override
  String get remoteMappingConflict =>
      'Questo pulsante e tipo di pressione sono già assegnati. Scegli un altro pulsante o tipo di pressione.';

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
