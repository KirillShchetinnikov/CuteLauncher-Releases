// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get adbWifiOwnedTitle =>
      'La red Wi-Fi pertenece al asistente de configuración';

  @override
  String get adbWifiOwned =>
      'No se hicieron cambios: una red Wi-Fi guardada fue creada por el asistente de Google. Desactivarlo podría borrar la red y desconectar el televisor.\n\n1. Asegúrese de conocer la contraseña Wi-Fi.\n2. Abra los ajustes de red de Android, seleccione la red y pulse Olvidar red.\n3. Vuelva a conectarse desde esos ajustes.\n4. Regrese a CuteLauncher, compruebe ADB e intente desactivar el lanzador integrado.\n\nSi vuelve a aparecer el mensaje, mantenga el lanzador integrado activado: el firmware puede asignar otra vez la red al asistente.';

  @override
  String get adbWifiUnknown =>
      'Not changed: the owners of saved Wi-Fi networks could not be verified. Disabling the setup wizard is blocked to protect your connection. Check ADB and try again; some firmware does not provide this information.';

  @override
  String get backgroundSource => 'Fuente de fondo';

  @override
  String get noAvailableCategories =>
      'No hay secciones disponibles para agregar esta aplicación.';

  @override
  String get redditWallpaperTheme => 'Tema de fondo de pantalla';

  @override
  String get redditThemeAll => 'Mixto';

  @override
  String get redditThemeNature => 'naturaleza';

  @override
  String get redditThemeSpace => 'espacio';

  @override
  String get redditThemeCity => 'Ciudades';

  @override
  String get redditThemeMinimal => 'Minimalismo';

  @override
  String get redditWallpaperResolution => 'Resolución mínima';

  @override
  String get redditWallpaperHint =>
      'Cada actualización exitosa descarga una imagen horizontal diferente de la comunidad Reddit seleccionada. La resolución es el tamaño original mínimo; las imágenes no están mejoradas. La actualización se ejecuta mientras el iniciador está abierto y se reanuda cuando regresa. Se omiten el contenido para adultos, los vídeos y las galerías. Si Reddit bloquea el acceso o no se encuentra ninguna imagen coincidente, el fondo de pantalla anterior permanece.';

  @override
  String get dialogCommandDetails => 'Mostrar comandos ADB';

  @override
  String get dialogAssign => 'Asignar';

  @override
  String get dialogApply => 'Aplicar';

  @override
  String get settingsValueNotSet => 'No establecido';

  @override
  String get settingsMenuPosition => 'Posición del menú de configuración';

  @override
  String get settingsMenuLeft => 'Izquierda';

  @override
  String get settingsMenuRight => 'Derecha';

  @override
  String get actionCompleted => 'Acción completada';

  @override
  String get showRepositoryQrCode => 'Mostrar código QR';

  @override
  String get resetSections => 'Restablecer la configuración de la sección';

  @override
  String get resetSectionsConfirmation =>
      '¿Restaurar secciones predeterminadas? Se eliminarán las secciones personalizadas, los espaciadores y los contenidos favoritos.';

  @override
  String get cardFocusMode => 'Centrarse en el regreso a casa';

  @override
  String get cardFocusRemember => 'Mantener tarjeta seleccionada';

  @override
  String get cardFocusFirst => 'Primera carta';

  @override
  String get cardFocusSettings => 'Botón de configuración';

  @override
  String get aboutFlauncher => 'Acerca de CuteLauncher';

  @override
  String get addCategory => 'Agregar categoría';

  @override
  String get addSection => 'Agregar sección';

  @override
  String get alphabetical => 'Alfabético';

  @override
  String get appCardHighlightAnimation => 'Resaltar aplicaciones';

  @override
  String get appInfo => 'Datos de la aplicación';

  @override
  String get appKeyClick => 'Sonido al presionar una tecla';

  @override
  String get applications => 'Aplicaciones';

  @override
  String get autoHideAppBar => 'Ocultar barra de estado automáticamente';

  @override
  String get backButtonAction => 'Acción del botón \'Atrás\'';

  @override
  String get category => 'Categoría';

  @override
  String get categories => 'Categorías';

  @override
  String get columnCount => 'Cantidad de columnas';

  @override
  String get date => 'Fecha';

  @override
  String get dateAndTimeFormat => 'Formato de fecha y hora';

  @override
  String get delete => 'Eliminar';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'Nada';

  @override
  String get dialogOptionBackButtonActionShowScreensaver =>
      'Mostrar salvapantallas';

  @override
  String get dialogOptionBackButtonActionShowClock => 'Mostrar reloj';

  @override
  String get dialogTextNoFileExplorer =>
      'Por favor, instale un gestor de archivos para seleccionar una imagen.';

  @override
  String get dialogTitleBackButtonAction =>
      'Elegir la acción del botón \'Atrás\'';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (Categoría)';
  }

  @override
  String formattedDate(String dateString) {
    return 'Fecha con formato: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'Hora con formato: $timeString';
  }

  @override
  String get gradient => 'Gradiente';

  @override
  String get favoriteApps => 'Apps Favoritas';

  @override
  String get grid => 'Cuadrícula';

  @override
  String get height => 'Altura';

  @override
  String get hide => 'Ocultar';

  @override
  String get hiddenApplications => 'Aplicaciones ocultas';

  @override
  String get launcherSections => 'Secciones';

  @override
  String get layout => 'Distribución';

  @override
  String get loading => 'Cargando';

  @override
  String get manual => 'Manual';

  @override
  String get modifySection => 'Modificar sección';

  @override
  String get mustNotBeEmpty => 'No debe estar vacío';

  @override
  String get name => 'Nombre';

  @override
  String get newSection => 'Nueva sección';

  @override
  String get noDateFormatSpecified => 'Sin formato de fecha';

  @override
  String get noTimeFormatSpecified => 'Sin formato de hora';

  @override
  String get nonTvApplications => 'Otras aplicaciones';

  @override
  String get open => 'Abrir';

  @override
  String get orSelectFormatSpecifiers =>
      'O seleccione especificadores de formato';

  @override
  String get openImage => 'Elegir archivo';

  @override
  String get picture => 'Imagen o vídeo local';

  @override
  String removeFrom(String name) {
    return 'Eliminar de $name';
  }

  @override
  String get renameCategory => 'Renombrar categoría';

  @override
  String get reorder => 'Reordenar';

  @override
  String get row => 'Fila';

  @override
  String get rowHeight => 'Altura de fila';

  @override
  String get save => 'Guardar';

  @override
  String get spacer => 'Espaciador';

  @override
  String get spacerMaxHeightRequirement =>
      'Debe ser mayor a cero y menor o igual a 500';

  @override
  String get statusBar => 'Barra de estado';

  @override
  String get settings => 'Ajustes';

  @override
  String get show => 'Mostrar';

  @override
  String get showCategoryTitles => 'Mostrar títulos de categorías';

  @override
  String get themes => 'Temas';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'Ocultar el contorno de resaltado en la pantalla de inicio';

  @override
  String get appSelectorTransitionAnimation =>
      'Animación de transición del selector de aplicaciones';

  @override
  String get sort => 'Orden';

  @override
  String get systemSettings => 'Ajustes del sistema';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => 'Esta categoría está vacía.';

  @override
  String get time => 'Hora';

  @override
  String get titleStatusBarSettingsPage =>
      'Elija la información a mostrar en la barra de estado';

  @override
  String get tvApplications => 'Aplicaciones del televisor';

  @override
  String get type => 'Tipo';

  @override
  String get typeInTheDateFormat => 'Escriba el formato de fecha';

  @override
  String get typeInTheHourFormat => 'Escriba el formato de hora';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String get wallpaper => 'Fondo de pantalla';

  @override
  String get withEllipsisAddTo => 'Añadir a...';

  @override
  String get timeBasedWallpaper => 'Imagen diurna/nocturna';

  @override
  String get pickDayWallpaper => 'Elegir imagen diurna';

  @override
  String get pickNightWallpaper => 'Elegir imagen nocturna';

  @override
  String get accessibility => 'Accesibilidad';

  @override
  String get defaultLauncherIsDefault =>
      'CuteLauncher es el lanzador predeterminado';

  @override
  String get defaultLauncherNotDefault =>
      'CuteLauncher no es el lanzador predeterminado';

  @override
  String get setAsDefaultLauncher => 'Establecer como lanzador predeterminado';

  @override
  String get defaultLauncherDescription =>
      'Cuando se establece como lanzador predeterminado, el botón de inicio siempre regresará a CuteLauncher. El TV también iniciará directamente en CuteLauncher.';

  @override
  String get inputs => 'Entradas';

  @override
  String get inputsUnavailableHint =>
      'Este dispositivo no proporciona entradas disponibles. El interruptor está desactivado y el icono está oculto. En una caja de TV, esta opción no controla las entradas HDMI del televisor conectado.';

  @override
  String get inputSources => 'Fuentes de Entrada';

  @override
  String get backupAndRestore => 'Copia de seguridad y restauración';

  @override
  String get exportBackup => 'Exportar copia de seguridad';

  @override
  String get importBackup => 'Importar copia de seguridad';

  @override
  String exportSuccess(String path) {
    return 'Copia de seguridad exportada con éxito a $path';
  }

  @override
  String get importSuccess => 'Copia de seguridad importada con éxito';

  @override
  String get importConfirm =>
      '¿Está seguro de que desea importar la copia de seguridad? Esto sobrescribirá su configuración y diseño actuales.';

  @override
  String get importError =>
      'No se pudo restaurar la configuración desde la copia de seguridad. Verifique el archivo e inténtelo nuevamente.';

  @override
  String exportError(String error) {
    return 'Error al exportar la copia de seguridad: $error';
  }

  @override
  String get shareBackup => 'Compartir copia';

  @override
  String get shareBackupDescription =>
      'Comparta la copia de seguridad con otros dispositivos en la red local';

  @override
  String get stopSharing => 'Detener uso compartido';

  @override
  String get localNetworkSharingActive =>
      '¡El uso compartido en red local está activo!';

  @override
  String get localNetworkSharingInstructions =>
      'Conecte otro dispositivo a la misma red Wi-Fi y abra la siguiente URL en un navegador web:';

  @override
  String get localNetworkSharingDetails =>
      'Aquí puede descargar la configuración/diseño de su TV o subir un archivo de copia de seguridad a esta TV.';

  @override
  String failedToStartServer(String error) {
    return 'Error al iniciar el servidor de uso compartido: $error';
  }

  @override
  String get notificationBell => 'Campana de notificaciones';

  @override
  String get autoHideNotificationBell =>
      'Ocultar campana de notificaciones automáticamente';

  @override
  String get continueWatching => 'Continuar viendo';

  @override
  String get showContinueWatchingOnHome => 'Mostrar Continuar viendo en Inicio';

  @override
  String get permissionDeniedContinueWatching =>
      'Se requiere permiso para mostrar Continuar viendo';

  @override
  String get interface => 'Interfaz';

  @override
  String get system => 'Sistema';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get miscellaneous => 'Miscelánea';

  @override
  String get brightnessScheduler => 'Programador de brillo';

  @override
  String get screensaverSettings => 'Ajustes del salvapantallas';

  @override
  String get screensaverClockStyle => 'Estilo de reloj del salvapantallas';

  @override
  String get dataUsagePeriod => 'Período de uso de datos';

  @override
  String get notificationAccess => 'Acceso a notificaciones';

  @override
  String get granted => 'Concedido';

  @override
  String get permissionRequired => 'Permiso requerido';

  @override
  String get systemWidePopupAlert => 'Alerta emergente del sistema';

  @override
  String get overlayPermissionRequired => 'Permiso de superposición requerido';

  @override
  String get enabled => 'Habilitado';

  @override
  String get disabled => 'Deshabilitado';

  @override
  String get showAppNamesBelowIcons => 'Mostrar nombres debajo de los iconos';

  @override
  String get dataUsage => 'Uso de datos';

  @override
  String get networkIndicator => 'Indicador de red';

  @override
  String get homeButtonFix => 'Corrección del botón Inicio (Google TV)';

  @override
  String get startOnBoot => 'Iniciar al encender (Google TV / Fire TV)';

  @override
  String get appLanguage => 'Idioma';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get ukrainian => 'Ucraniano';

  @override
  String get chinese => 'Chino';

  @override
  String get french => 'Francés';

  @override
  String get german => 'Alemán';

  @override
  String get japanese => 'Japonés';

  @override
  String get portuguese => 'Portugués';

  @override
  String get russian => 'Ruso';

  @override
  String get italian => 'Italiano';

  @override
  String get hindi => 'hindi';

  @override
  String get korean => 'Coreano';

  @override
  String get arabic => 'Árabe';

  @override
  String get turkish => 'Turco';

  @override
  String get hidePersistentNotifications =>
      'Ocultar notificaciones persistentes';

  @override
  String get hidePersistentNotificationsDesc =>
      'Ocultar notificaciones de servicios en segundo plano y del sistema';

  @override
  String get blockedNotificationApps => 'Aplicaciones bloqueadas';

  @override
  String get blockAppNotifications => 'Bloquear notificaciones';

  @override
  String get unblockAppNotifications => 'Desbloquear notificaciones';

  @override
  String get noBlockedApps => 'No hay aplicaciones bloqueadas';

  @override
  String get persistentNotification => 'Persistente';

  @override
  String get unblockAll => 'Desbloquear todo';

  @override
  String get weather => 'Clima';

  @override
  String get showWeatherWarnings => 'Mostrar alertas de lluvia y clima';

  @override
  String get temperatureUnit => 'Unidad de temperatura';

  @override
  String get celsius => 'Celsius (°C)';

  @override
  String get fahrenheit => 'Fahrenheit (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Instala Breezy Weather y activa \'Compartir datos locales\' / \'Gadgetbridge\' en sus ajustes para ver el clima y avisos de lluvia.';

  @override
  String get displayAndScreensaver => 'Pantalla y salvapantallas';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get continueWatchingDescription =>
      'Mostrar películas y series vistas recientemente en la pantalla de inicio';

  @override
  String get continueWatchingPermissionDesc =>
      'Se requiere un permiso especial para leer el historial de reproducción de las aplicaciones de TV:';

  @override
  String get requestPermission => 'Solicitar permiso';

  @override
  String get dismiss => 'Descartar';

  @override
  String get openApp => 'Abrir';

  @override
  String get notificationOptions => 'Opciones de notificación';

  @override
  String get noBlockedAppsDesc =>
      'Todas las aplicaciones tienen permitido mostrar notificaciones';

  @override
  String get notificationsAllowed => 'Notificaciones permitidas';

  @override
  String get notificationsBlocked => 'Notificaciones bloqueadas';

  @override
  String get dpadDismissHint => 'Izquierda: Descartar • OK: Opciones';

  @override
  String get watchNextDeleteError =>
      'No se pudo eliminar el elemento de Continuar viendo. Intentar otra vez.';

  @override
  String get hideLauncherTile =>
      'Ocultar CuteLauncher en la cuadrícula de aplicaciones';

  @override
  String get hideAndroidSettingsTile =>
      'Ocultar la configuración de Android en los mosaicos de la aplicación';

  @override
  String get animateTileReordering => 'Animar el reordenamiento de mosaicos';

  @override
  String get imageInputRejected =>
      'Esta imagen está dañada o es demasiado grande (máximo 8 MiB y 48 megapíxeles). Elige otra imagen.';

  @override
  String get memoryTitle => 'Memoria';

  @override
  String get memoryRefresh => 'Medir la memoria';

  @override
  String get memoryMeasuring => 'Midiendo…';

  @override
  String get memoryClear => 'Borrar cachés de imágenes';

  @override
  String get memorySaver => 'Ahorro de memoria';

  @override
  String get memorySaverDescription =>
      'Modo de ahorro de memoria:\n\n• Reduce los cachés de imágenes y la ventana de precarga de carteles.\n• Desactiva el desenfoque del fondo de mosaicos, paneles y fondos de pantalla, y la pulsación del contorno.\n• Limita las sombras en mosaicos desenfocados.\n• Borra los cachés cuando la aplicación pasa a segundo plano.\n\nEstos efectos no están disponibles en la configuración mientras el ahorro de memoria está habilitado. Sus valores guardados regresan cuando el modo está desactivado. Las imágenes pueden recargarse con más frecuencia.';

  @override
  String get memoryPss => 'Proceso compartido (PSS)';

  @override
  String get memoryRss => 'Memoria de proceso residente (RSS)';

  @override
  String get memoryEncodedCache => 'Archivos de imagen en caché';

  @override
  String get memoryDecodedCache => 'Imágenes decodificadas en caché';

  @override
  String get memoryUnavailable => 'No disponible';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => 'Medido en';

  @override
  String get memoryExplanation =>
      'PSS y RSS se superponen: no los sumes. Los tamaños de caché son parte de la memoria de la aplicación y no describen toda la memoria que contienen las imágenes activas. Borrar cachés mantiene su configuración y archivos; Las imágenes se cargan nuevamente cuando sea necesario. Android puede devolver la memoria más tarde. RSS aquí viene del kernel y PSS de Android; pueden representar la memoria gráfica de manera diferente.';

  @override
  String get memoryRecommendations =>
      'Para tener menos memoria, habilite el guardado, muestre menos tarjetas para Continuar viendo y use fondos de pantalla más pequeños o un degradado.';

  @override
  String get memoryMeasurementFailed =>
      'La medición del proceso no está disponible. La información de la caché todavía se muestra.';

  @override
  String get addToCategory => 'Agregar a la categoría';

  @override
  String get addToFavorites => 'Añadir a favoritos';

  @override
  String get removeFromFavorites => 'Quitar de favoritos';

  @override
  String get setCustomBanner => 'Establecer banner personalizado';

  @override
  String get clearCustomBanner => 'Borrar banner personalizado';

  @override
  String get bannerSetFailed =>
      'No se pudo configurar el banner. Verifique el acceso a la imagen y seleccione el archivo nuevamente.';

  @override
  String get bannerClearFailed =>
      'No se pudo eliminar el banner personalizado. Intentar otra vez.';

  @override
  String get grantUsagePermission => 'Conceder permiso de uso';

  @override
  String get removeFromContinueWatching => 'Quitar de Continuar viendo';

  @override
  String hideAllFromApp(String appName) {
    return 'Ocultar todo de $appName';
  }

  @override
  String get playResume => 'Reproducir / Reanudar';

  @override
  String openNamedApp(String appName) {
    return 'Abrir $appName';
  }

  @override
  String get selectedAccent => 'Acento seleccionado';

  @override
  String get homeButtonFixHint =>
      'Si está utilizando Google TV, habilite \"Corregir botón de inicio\" en la configuración de Accesibilidad para que el botón de Inicio abra este iniciador.';

  @override
  String get accessibilityPermission => 'Permiso de accesibilidad';

  @override
  String get shareFailed => 'Compartir falló';

  @override
  String shareBackupError(String error) {
    return 'No se pudo compartir la copia de seguridad: $error';
  }

  @override
  String get exportComplete => 'Exportación exitosa';

  @override
  String get exportFailed =>
      'No se pudo guardar la copia de seguridad. Verifique el acceso a la carpeta y el almacenamiento disponible.';

  @override
  String backupLoadError(String error) {
    return 'Error al cargar copias de seguridad: $error';
  }

  @override
  String get noBackupFiles => 'No se encontraron archivos de respaldo.';

  @override
  String get importComplete => 'Importación exitosa';

  @override
  String get importFailed => 'Importación fallida';

  @override
  String get importAction => 'Importar';

  @override
  String get continueWatchingApps => 'Continuar viendo aplicaciones';

  @override
  String get blockedContinueWatching => 'Bloqueado para continuar viendo';

  @override
  String get allAppsCanContinueWatching =>
      'Todas las aplicaciones compatibles pueden mostrar elementos en Continuar viendo.';

  @override
  String get unblockApp => 'Desbloquear';

  @override
  String get unblockAllApps => 'Desbloquear todas las aplicaciones';

  @override
  String get appsWithContinueWatching => 'Aplicaciones con Continuar viendo';

  @override
  String get watchNextAppsHint =>
      'Aplicaciones que actualmente ofrecen elementos Ver a continuación en su pantalla de inicio';

  @override
  String get noWatchNextApps =>
      'Actualmente, ninguna aplicación proporciona elementos para Continuar viendo.\nCuando las aplicaciones compatibles (como SmartTube o servicios de transmisión) agreguen elementos, aparecerán aquí.';

  @override
  String get allInstalledApps => 'Todas las aplicaciones instaladas';

  @override
  String get blockWatchNextHint =>
      'Desactívelo para impedir que cualquier aplicación agregue elementos para Continuar viendo';

  @override
  String get cardSize => 'Tamaño de tarjeta';

  @override
  String get maximumItems => 'Artículos máximos';

  @override
  String get playbackProgressBar => 'Barra de progreso de reproducción';

  @override
  String get playbackPercentage => 'Porcentaje de reproducción';

  @override
  String get episodeVideoDetails => 'Detalles del episodio y vídeo';

  @override
  String get restoreHiddenPrograms => 'Restaurar programas ocultos';

  @override
  String get allHiddenProgramsRestored =>
      'Todos los programas ocultos restaurados';

  @override
  String get watchNextAccessAdb => 'Ver siguiente acceso (se requiere ADB)';

  @override
  String get supportLtvLauncher => 'Soporte LTvLauncher';

  @override
  String get scanToDonate => 'Escanea con la cámara de tu teléfono para donar:';

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String get close => 'Cerrar';

  @override
  String get launcherAuthor => 'CuteLauncher por Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Lanzador Android TV basado en LTvLauncher de LeanBitLab y FLauncher de Étienne Fesser. Licenciado bajo GNU GPLv3.';

  @override
  String get projectCredits => 'Proyecto y Créditos';

  @override
  String get launcherRepository => 'Repositorio CuteLauncher';

  @override
  String get originalProject => 'Proyecto original: LTvLauncher';

  @override
  String get noInputsDetected => 'No se detectaron entradas';

  @override
  String get reorderSectionsHint =>
      'Seleccione con ◄ / ► luego use ▲ / ▼ para reordenar. Cruce el límite de la lista para ocultar o mostrar una sección.';

  @override
  String get customName => 'Nombre personalizado';

  @override
  String get mostUsed => 'Frecuencia de lanzamiento';

  @override
  String get lastUsed => 'Usado por última vez';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get allCaughtUp => '¡Todos atrapados!';

  @override
  String get notificationAccessAdb =>
      'Acceso a notificaciones (se requiere ADB)';

  @override
  String get openAppInfo => 'Abrir información de la aplicación';

  @override
  String get overlayPermission => 'Permiso de superposición';

  @override
  String get clockMinimal => 'mínimo';

  @override
  String get clockMinimalDescription =>
      'Fuente fina y elegante (predeterminada)';

  @override
  String get clockBold => 'Negrita';

  @override
  String get clockBoldDescription => 'Fuente gruesa y muy visible';

  @override
  String get clockRetro => 'Retro';

  @override
  String get clockRetroDescription => 'Estilo terminal retro monoespaciado';

  @override
  String get clockElegant => 'elegante';

  @override
  String get clockElegantDescription => 'Tipografía serif clásica';

  @override
  String get clockNeon => 'Neón';

  @override
  String get clockNeonDescription => 'Estilo ultrafino y brillante';

  @override
  String get clockPixel => 'Píxel';

  @override
  String get clockPixelDescription => 'Audaz sensación monoespaciada y arcade';

  @override
  String get clockDigital => 'digitales';

  @override
  String get clockDigitalDescription => 'Pantalla limpia y monoespaciada';

  @override
  String get themeDefault => 'Predeterminado';

  @override
  String get themePremium => 'prima';

  @override
  String get themeClassic => 'Clásico';

  @override
  String get themeCapsule => 'Cápsula';

  @override
  String get cancel => 'Cancelar';

  @override
  String get actionCancelled => 'Acción cancelada';

  @override
  String get ok => 'bien';

  @override
  String get accessibilityGuide =>
      'Abra la configuración del televisor manualmente, luego Accesibilidad → CuteLauncher Reparación del botón de inicio y habilite el servicio. La ubicación y el nombre de este menú dependen del fabricante de su televisor.';

  @override
  String get notificationPermissionGuide =>
      'La configuración de acceso a notificaciones no se pudo abrir en este televisor. Permitir notificaciones salientes en Información de la aplicación no otorga acceso a notificaciones de otras aplicaciones.\n\nConecte su televisor a través de ADB y ejecute:';

  @override
  String get overlayPermissionGuide =>
      'La configuración de permisos de superposición no se pudo abrir automáticamente.\n\nPara habilitar ventanas emergentes sobre otras aplicaciones, conecte su televisor a través de ADB y ejecute:';

  @override
  String get watchNextPermissionGuide =>
      'Para leer tarjetas Continuar viendo desde otras aplicaciones, Android TV requiere READ_WRITE_WATCH_NEXT_PROGRAMS.\n\nConecte su televisor a través de ADB y ejecute:';

  @override
  String get watchNextAccess => 'Continuar viendo acceso';

  @override
  String itemsCount(int count) {
    return 'Artículos $count';
  }

  @override
  String displayUpToItems(int count) {
    return 'Mostrar hasta elementos recientes $count';
  }

  @override
  String get unlimitedItems => 'Ilimitado';

  @override
  String get allAvailableItems => 'Mostrar todos los artículos disponibles';

  @override
  String get defaultOption => 'Predeterminado';

  @override
  String get manage => 'Administrar';

  @override
  String blockedCount(int count) {
    return '$count bloqueado';
  }

  @override
  String hiddenCount(int count) {
    return '$count oculto';
  }

  @override
  String blockedWatchNextCount(int count) {
    return 'Bloqueado para continuar viendo ($count)';
  }

  @override
  String get sizeExtraSmall => 'Extrapequeño';

  @override
  String get sizeVerySmall => 'muy pequeño';

  @override
  String get sizeSmall => 'pequeño';

  @override
  String get sizeCompact => 'Compacto';

  @override
  String get sizeMediumSmall => 'Mediano Pequeño';

  @override
  String get sizeMedium => 'Medio';

  @override
  String get sizeStandardDefault => 'Estándar (predeterminado)';

  @override
  String get sizeMediumLarge => 'Mediano Grande';

  @override
  String get sizeLarge => 'Grande';

  @override
  String get sizeVeryLarge => 'muy grande';

  @override
  String get sizeExtraLarge => 'extragrande';

  @override
  String get sizeHuge => 'enorme';

  @override
  String get tvApps => 'Aplicaciones de televisión';

  @override
  String get nonTvApps => 'Aplicaciones que no son de televisión';

  @override
  String get moviesShows => 'Películas y espectáculos';

  @override
  String get music => 'musica';

  @override
  String get games => 'Juegos';

  @override
  String get entertainment => 'Entretenimiento';

  @override
  String get liveTv => 'Televisión en vivo';

  @override
  String get sports => 'Deportes';

  @override
  String get news => 'Noticias';

  @override
  String get tools => 'Herramientas';

  @override
  String get favorites => 'Favoritos';

  @override
  String get customSectionName => 'Personalizado...';

  @override
  String get selectSectionName => 'Seleccione un nombre';

  @override
  String get weeklyUsage => 'Semanal:';

  @override
  String get monthlyUsage => 'Mensual:';

  @override
  String get dailyUsage => 'Diariamente:';

  @override
  String get appError => 'algo salió mal';

  @override
  String get weatherRain => 'Lluvia';

  @override
  String get weatherSnow => 'nieve';

  @override
  String get weatherStorm => 'tormenta';

  @override
  String get weatherToday => 'hoy';

  @override
  String get weatherTomorrow => 'mañana';

  @override
  String weatherOnDay(String day) {
    return 'en $day';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'Copia de seguridad CuteLauncher';

  @override
  String get noApplicationsFound => 'No se encontraron aplicaciones';

  @override
  String get invalidDateFormat => 'Formato no válido';

  @override
  String get selectDateFormats => 'Seleccione los formatos a continuación';

  @override
  String activeItemsCount(int count) {
    return '$count elementos activos';
  }

  @override
  String get colorPurple => 'Púrpura';

  @override
  String get colorTeal => 'verde azulado';

  @override
  String get colorBlue => 'azul';

  @override
  String get colorOrange => 'naranja';

  @override
  String get colorPink => 'rosa';

  @override
  String get colorGreen => 'verde';

  @override
  String get colorWhite => 'blanco';

  @override
  String get colorYellow => 'amarillo';

  @override
  String get colorRed => 'rojo';

  @override
  String get colorCyan => 'cian';

  @override
  String get colorIndigo => 'índigo';

  @override
  String get colorLime => 'lima';

  @override
  String get colorAmber => 'ámbar';

  @override
  String get colorRose => 'rosa';

  @override
  String get colorIceBlue => 'azul hielo';

  @override
  String get memoryFeatures => 'Memoria por característica (cachés)';

  @override
  String get memoryAppIcons => 'Iconos de aplicaciones';

  @override
  String get memoryAppBanners => 'pancartas de aplicaciones';

  @override
  String get memoryWatchNextPosters => 'Continuar viendo carteles';

  @override
  String get memoryOtherCaches => 'Otros cachés de imágenes codificadas';

  @override
  String get memoryFeaturesExplanation =>
      'Estos son bytes de imagen retenidos, ya incluidos en el total de la caché codificada. Cero significa que no hay bytes retenidos en ese caché, no que la función no use memoria. Los fondos de pantalla y las imágenes mostradas comparten el caché decodificado arriba; las imágenes activas pueden estar fuera de él. El clima, las notificaciones, los objetos Dart y el motor no se pueden dividir por función aquí. Los gráficos de interfaz compartidos se indican arriba en Android y ya están incluidos en PSS. Su memoria es parte del proceso total. No agregue estos valores superpuestos.';

  @override
  String get memoryGraphics => 'Gráficos de interfaz (incluidos en PSS)';

  @override
  String get categoryVisible => 'Mostrar categoría';

  @override
  String get hiddenCategories => 'Categorías ocultas';

  @override
  String get visibleCategories => 'Categorías visibles';

  @override
  String get backupSavedToSelectedLocation =>
      'Copia de seguridad guardada en la ubicación seleccionada';

  @override
  String get tileHorizontalGap => 'Espaciado horizontal';

  @override
  String get tileVerticalGap => 'Espaciado vertical';

  @override
  String get tileOpacity => 'Opacidad del fondo';

  @override
  String get tileShadow => 'sombra';

  @override
  String get tileCornerRadius => 'redondeo de esquinas';

  @override
  String get tileIconScale => 'Tamaño del icono';

  @override
  String get tileBackgroundColor => 'Fondo del azulejo';

  @override
  String get tileLabelSize => 'Tamaño de etiqueta';

  @override
  String get resetAppearance => 'Restablecer apariencia';

  @override
  String get tileAppearance => 'Aspecto del azulejo';

  @override
  String get tileLabelColor => 'Color de etiqueta';

  @override
  String get tilePreviewName => 'Aplicación de muestra';

  @override
  String get tileProportions => 'Proporciones de azulejos';

  @override
  String get tileLarge => 'Grande';

  @override
  String get tileLabelBelow => 'Debajo del azulejo';

  @override
  String get tileLabelInside => 'Dentro del azulejo';

  @override
  String get tileFocusScale => 'Ampliar';

  @override
  String get tileMedium => 'Medio';

  @override
  String get tileFocusBorder => 'Sin movimiento';

  @override
  String get tileSize => 'Tamaño del azulejo';

  @override
  String get tileCompact => 'Compacto';

  @override
  String get tileLabelPosition => 'Posición de la etiqueta';

  @override
  String get tileFocusEffect => 'efecto de enfoque';

  @override
  String get tileFocusStrength => 'Intensidad de resaltado';

  @override
  String get panelIndependent => 'Configuraciones personalizadas';

  @override
  String get panelAppearance => 'Estilo del panel superior';

  @override
  String get panelBackground => 'Fondo del panel';

  @override
  String get blurPerformanceHint =>
      'El desenfoque puede reducir la suavidad. Está deshabilitado mientras el ahorro de memoria está activado.';

  @override
  String get panelOpacity => 'Opacidad del panel';

  @override
  String get tileBlur => 'Desenfoque detrás de los azulejos';

  @override
  String get panelBlur => 'Desenfoque detrás del panel superior';

  @override
  String get panelShared => 'Como paneles';

  @override
  String get weatherMinutes => 'mín.';

  @override
  String get weatherOpenMeteoCredit =>
      'Tiempo: Open-Meteo (open-meteo.com), CC BY 4.0. API gratuito para uso no comercial.';

  @override
  String get weatherRateLimit =>
      'Se alcanzó el límite de solicitudes. Inténtalo más tarde.';

  @override
  String get weatherYandexCredit =>
      'Clima: Yandex Weather (yandex.ru/pogoda). El acceso depende de su plan API.';

  @override
  String get yandexWeather => 'Tiempo Yandex (REST)';

  @override
  String get weatherAuthorizationError =>
      'El proveedor meteorológico rechazó la solicitud. Consulta la clave API y accede al servicio seleccionado.';

  @override
  String get weatherYandexHint =>
      'Requiere una clave con acceso a pronóstico REST. Es posible que una clave para otro plan de Yandex no funcione.';

  @override
  String get weatherSource => 'Fuente meteorológica';

  @override
  String get weatherInterval => 'Intervalo de actualización';

  @override
  String get weatherLongitude => 'Longitud (-180 a 180)';

  @override
  String get weatherKeyRequired => 'Agregue una clave Yandex API.';

  @override
  String get weatherLocationName => 'Nombre de la ciudad (opcional)';

  @override
  String get weatherLocation => 'Ubicación';

  @override
  String get weatherApiKey => 'Clave Yandex API';

  @override
  String get weatherInvalidResponse =>
      'La fuente meteorológica arrojó datos no válidos.';

  @override
  String get weatherUnavailable =>
      'El tiempo no está disponible. Los datos recibidos anteriormente se conservan si están disponibles. Los reintentos están limitados a una vez cada 5 minutos.';

  @override
  String get weatherStale => 'Clima anterior';

  @override
  String get weatherLatitude => 'Latitud (-90 a 90)';

  @override
  String get weatherCoordinatesError =>
      'Ingrese una ciudad manualmente u obtenga coordenadas automáticamente.';

  @override
  String get weatherRefresh => 'Buscar actualizaciones';

  @override
  String get weatherKeyPrivate =>
      'Almacenado únicamente en este dispositivo, excluido de las copias de seguridad. La entrada vacía elimina la clave.';

  @override
  String get weatherUpdated => 'Actualizado';

  @override
  String get onlineWallpaperError =>
      'No se puede cargar esta imagen. Se conserva el fondo de pantalla anterior. Seleccione \"Buscar actualizaciones\" para volver a intentar la descarga.';

  @override
  String get onlineWallpaperHint =>
      'La última imagen se conserva para usarla sin conexión (hasta 8 MiB).';

  @override
  String get onlineWallpaperHours => 'h';

  @override
  String get onlineWallpaperInterval => 'Intervalo de descarga';

  @override
  String get onlineWallpaper => 'Fondo de pantalla en línea';

  @override
  String get onlineWallpaperUrlError =>
      'Ingrese una imagen HTTPS directa URL sin detalles de inicio de sesión.';

  @override
  String get onlineWallpaperEnabled => 'Usar fondo de pantalla en línea';

  @override
  String get onlineWallpaperSource => 'Fuente de la imagen';

  @override
  String get bingWallpaper => 'Bing imagen del día';

  @override
  String get onlineWallpaperUrlSource => 'Directo HTTPS URL';

  @override
  String get updatePlayOnly =>
      'Esta instalación recibe actualizaciones a través de Google Play.';

  @override
  String get updateCheck => 'Compruébalo ahora';

  @override
  String get updateInstalled => 'Instalado';

  @override
  String get updateDownloadInstall => 'Descargar e instalar';

  @override
  String get updateNoRelease =>
      'No hay ninguna versión compatible más reciente disponible.';

  @override
  String get updateIncompatible =>
      'El APK no coincide con esta aplicación, certificado o versión más reciente. La instalación fue bloqueada.';

  @override
  String get updateError =>
      'No se puede verificar, descargar o abrir el instalador. Vuelve a intentarlo más tarde.';

  @override
  String get updateAvailable => 'Actualización disponible';

  @override
  String get appUpdates => 'Actualizaciones de aplicaciones';

  @override
  String get updatePermission =>
      'Permita la instalación desde esta aplicación en la configuración de Android, regrese aquí y presione Instalar nuevamente.';

  @override
  String get updateInstall => 'Instalar la actualización descargada';

  @override
  String get updateHint =>
      'Fuente: GitHub / KirillShchetinnikov/CuteLauncher-Releases. Las comprobaciones automáticas se ejecutan mientras el iniciador está abierto. La descarga comienza cuando la eliges; Android le pide que confirme la instalación. Tus datos se conservan.';

  @override
  String get updateAutomatic => 'Comprobar automáticamente una vez al día';

  @override
  String get allApplications => 'Todas las aplicaciones';

  @override
  String get adbAccessibility => 'Habilitar la corrección del botón de inicio';

  @override
  String get adbAuthorization =>
      'Apruebe la autorización ADB en el televisor y vuelva a intentarlo.';

  @override
  String get adbChangeConfirm =>
      '¿Aplicar esta configuración del sistema a través de ADB? La aplicación Home anterior se guarda antes de cambiarla; Se conservan otros servicios de accesibilidad.';

  @override
  String get adbCheck => 'Comprobar conexión';

  @override
  String get adbDenied => 'El sistema no permitió ni confirmó este cambio.';

  @override
  String get adbDisable => 'Deshabilitar el lanzador anterior';

  @override
  String get adbDisableConfirm =>
      '¿Desactivar el iniciador anterior guardado? Esto requiere que CuteLauncher sea la aplicación de inicio actual. Restáurelo con la acción de recuperación en esta configuración.';

  @override
  String get adbHint =>
      'Prototipo solo para este televisor (127.0.0.1). Habilite TCP ADB en las opciones de desarrollador, ingrese su puerto y apruebe el mensaje de autorización en el televisor. Aún no se admite la depuración inalámbrica con un código de emparejamiento. La clave privada permanece en este dispositivo, fuera de las copias de seguridad.';

  @override
  String get adbHome => 'Haga de CuteLauncher la aplicación de inicio';

  @override
  String get adbInvalid => 'Ingrese un puerto entre 1024 y 65535.';

  @override
  String get adbNoRecovery =>
      'La restauración no está disponible: no se encontró ningún otro iniciador ni estado de servicio guardado.';

  @override
  String get adbPort => 'Puerto TCP ADB';

  @override
  String get adbReady => 'ADB acceso confirmado.';

  @override
  String get adbRestore => 'Restaurar el lanzador anterior';

  @override
  String get adbSuccess => 'Cambio aplicado y verificado.';

  @override
  String get adbTitle => 'Configuración de ADB';

  @override
  String get adbUnavailable =>
      'No se puede conectar. Verifique TCP ADB, el puerto y el mensaje de autorización.';

  @override
  String get nightModeScheduled => 'Horario de uso';

  @override
  String get nightModeTitle => 'Modo nocturno';

  @override
  String get nightModeScope =>
      'Se necesita permiso de superposición para atenuar otras aplicaciones. Sin él, la atenuación funciona dentro del CuteLauncher. El filtro TCL no necesita permiso de superposición. Por encima del 80 % de opacidad, Android puede bloquear la entrada táctil en otras aplicaciones; Las teclas del control remoto del televisor aún funcionan.';

  @override
  String get nightModeEnd => 'Fin';

  @override
  String get nightModeStart => 'Empezar';

  @override
  String get nightModeDim => 'Atenuación';

  @override
  String get nightModeWarmth => 'Filtro caliente';

  @override
  String get nightModeScheduleHint =>
      'Utiliza el horario de la televisión local. Se admiten períodos nocturnos. Los tiempos de inicio y finalización iguales desactivan el filtro programado.';

  @override
  String get nightModeEnabled => 'Habilitar el modo nocturno';

  @override
  String get nightModePermission =>
      'Permitir visualización sobre otras aplicaciones';

  @override
  String get nightModePermissionGranted =>
      'Mostrar sobre otras aplicaciones permitidas';

  @override
  String get backupDownloadsFailed =>
      'No se pudo guardar la copia de seguridad en Descargas.';

  @override
  String get backupSaveDownloads => 'Guardar copia de seguridad en Descargas';

  @override
  String get adbRestoreAccessibility => 'Restaurar el acceso de accesibilidad';

  @override
  String get nightModeAdbConfirm =>
      '¿Permitir que CuteLauncher se muestre sobre otras aplicaciones usando ADB local? Primero habilite la depuración de TCP y autorice la conexión. Utiliza el puerto guardado en el asistente ADB, o 5555.';

  @override
  String get nightModeAdbPermission => 'Conceder permiso a través de ADB';

  @override
  String get nightModeNotificationsHint =>
      'La notificación le permite desactivar el filtro fuera de CuteLauncher. Sin él, utilice este menú.';

  @override
  String get nightModeNotificationsAllowed =>
      'Se permite la notificación en modo nocturno';

  @override
  String get nightModeNotifications => 'Permitir notificación de modo nocturno';

  @override
  String get categoryLastVisibleHint =>
      'Al menos una categoría debe permanecer visible.';

  @override
  String get diagnosticsClear => 'Borrar diagnóstico de sesión';

  @override
  String get diagnosticsReady => 'Informe listo';

  @override
  String get diagnosticsCreate => 'Crear informe';

  @override
  String get diagnosticsOperations => 'Operaciones registradas';

  @override
  String get diagnosticsCopied => 'Informe copiado';

  @override
  String get diagnosticsSharingNotice =>
      'Envíe el archivo al autor por mensaje privado, no lo publique: la limpieza automática puede omitir datos personales. Al enviarlo, acepta que se publique un informe anónimo de compatibilidad del televisor en el repositorio Git de CuteLauncher. Solo se publican metadatos del dispositivo y disponibilidad de funciones, sin datos personales; no se publican registros de errores, comandos ni sus ajustes.\n\nEl informe también incluye paquetes instalados, nombres, versiones y estado de activación, y los nombres, contenido, orden y visibilidad de las secciones. Se conservan los identificadores y nombres para el diagnóstico; estas listas no se publican.';

  @override
  String get diagnosticsHint =>
      'Un único informe combina compatibilidad de funciones del televisor y diagnóstico de errores. El informe incluye modelo y firmware del televisor, versión de la aplicación, permisos, memoria, etapas y causas de errores, comandos y respuestas con eliminación automática de datos personales. Guarda las últimas 50 operaciones, hasta 100 fallos por separado y un registro ADB limitado de la sesión. Se borra al reiniciar. La limpieza puede omitir datos personales: envíe el archivo por mensaje privado, no lo publique. No se envía nada automáticamente. Cada error conserva una instantánea de los ajustes aplicados; los cambios posteriores no la sustituyen.\n\nEl informe también incluye paquetes instalados, nombres, versiones y estado de activación, y los nombres, contenido, orden y visibilidad de las secciones. Se conservan los identificadores y nombres para el diagnóstico; estas listas no se publican.';

  @override
  String get diagnosticsTitle => 'Diagnóstico de errores';

  @override
  String get diagnosticsCopyFailed => 'No se pudo copiar el informe.';

  @override
  String get diagnosticsCopy => 'Copiar informe';

  @override
  String get diagnosticsCreating => 'Creando informe…';

  @override
  String get tclBlueLightTitle => 'Filtro de luz azul TCL';

  @override
  String get tclBlueLightError =>
      'No se pudo leer ni verificar la configuración del filtro TCL. Actualice su estado e inténtelo de nuevo.';

  @override
  String get tclBlueLightUnsupported =>
      'La interfaz de filtro TCL no está disponible en este televisor.';

  @override
  String get tclBlueLightRefresh => 'Actualizar el estado del filtro TCL';

  @override
  String get tclBlueLightHint =>
      'Controla el filtro de protección ocular integrado del televisor. También puede seguir el horario del modo nocturno.';

  @override
  String get nightSolarSchedule => 'Atardecer y amanecer';

  @override
  String get nightNextStart => 'Próximo comienzo';

  @override
  String get nightScheduleTimeHint =>
      'Los horarios utilizan la zona horaria de televisión. Las compensaciones negativas se producen antes; las compensaciones positivas son posteriores.';

  @override
  String get nightTemperature => 'Temperatura de color del filtro';

  @override
  String get nightScheduleSettings => 'Configuración de programación';

  @override
  String get nightCityName => 'Nombre de la ciudad';

  @override
  String get nightSkipUntilNext =>
      'Desactiva el modo nocturno hasta el próximo atardecer';

  @override
  String get nightSunriseOffset => 'Fin relativo al amanecer';

  @override
  String get nightEnableUntilMorning =>
      'Activa el modo nocturno hasta el próximo amanecer';

  @override
  String get nightPermissions => 'Permisos';

  @override
  String get nightTclSchedule => 'Incluir el filtro TCL en el cronograma';

  @override
  String get nightSearchCity => 'Buscar';

  @override
  String get nightRefreshSun => 'Refrescar el amanecer y el atardecer';

  @override
  String get nightSolarUnavailable =>
      'Elige una ciudad y refresca los tiempos de sol. Si el amanecer o el atardecer no están disponibles, el horario solar se detiene.';

  @override
  String get nightSunsetOffset => 'Inicio relativo al atardecer';

  @override
  String get nightCityHint =>
      'Elija su ciudad en lugar de otorgar acceso a la ubicación. Las coordenadas seleccionadas se envían a Sunrise-Sunset.org, o Open-Meteo como alternativa, para recuperar las horas del sol.';

  @override
  String get nightResumeSchedule => 'Volver al horario';

  @override
  String get nightScheduleSource => 'Tipo de horario';

  @override
  String get nightSolarCached =>
      'Usar horas de sol almacenadas en caché; La actualización de Internet se volverá a intentar automáticamente.';

  @override
  String get nightTclScheduleHint =>
      'Utiliza el mismo horario mientras el modo nocturno está habilitado. Los cambios manuales al filtro TCL duran hasta la siguiente transición programada. No se necesita permiso de superposición.';

  @override
  String get nightRefreshPermission => 'Actualizar el estado del permiso';

  @override
  String get nightCityNotFound =>
      'No se encontraron ciudades. Prueba con otro nombre.';

  @override
  String get nightNoOffset => 'Sin compensación';

  @override
  String get nightManualSchedule => 'Horario personalizado';

  @override
  String get nightChooseCity => 'Elige ciudad';

  @override
  String get nightPermissionUnknown =>
      'Se desconoce el estado del permiso de superposición';

  @override
  String get nightNextEnd => 'próximo final';

  @override
  String get nightTemporaryOff => 'Atenuación temporalmente apagada hasta';

  @override
  String get nightCitySearchFailed =>
      'No se pudieron buscar ciudades. Verifique su conexión a Internet.';

  @override
  String get nightSolarAttribution =>
      'Horario de sol diario: Sunrise-Sunset.org; respaldo: Open-Meteo. Búsqueda de ciudades: GeoNames. Se almacenan en caché varios días para uso sin conexión.';

  @override
  String get nightTemporaryOn => 'Atenuación temporal encendida hasta';

  @override
  String get homeScreen => 'Pantalla de inicio';

  @override
  String get appearanceSettings => 'Apariencia';

  @override
  String get generalSettings => 'Avanzado';

  @override
  String get advancedSettings => 'Avanzado';

  @override
  String get controlAndStartup => 'Controles de lanzador y TV';

  @override
  String get sectionsAndOrder => 'Secciones y orden';

  @override
  String get topPanel => 'Panel superior';

  @override
  String get tileStyle => 'Estilo de mosaico';

  @override
  String get tilesAndLabels => 'Azulejos y etiquetas';

  @override
  String get highlightAndAnimation => 'Resaltado y animación.';

  @override
  String get androidTvSettings => 'Configuración de Android TV';

  @override
  String get weatherSettings => 'Configuración del clima';

  @override
  String get showHighlightOutline => 'Mostrar esquema resaltado';

  @override
  String get resetTilesAndPanel =>
      'Restablecer la configuración de mosaicos y paneles';

  @override
  String get resetTilesAndPanelHint =>
      '¿Restablecer parámetros adicionales de mosaicos, etiquetas, resaltados y paneles superiores? Se conservan el papel tapiz, el color de acento, el estilo de los mosaicos y la visibilidad de las etiquetas.';

  @override
  String get panelAppearanceSettings => 'Aspecto del panel superior';

  @override
  String get panelSharedHint =>
      'Cambie la apariencia en la configuración de mosaicos.';

  @override
  String get effectsCompatibilityHint =>
      'Aspecto adicional: el contorno siempre es visible y no parpadea. El estilo dimensional no tiene un contorno heredado; El clásico no pulsa. La intensidad afecta la escala y la sombra; el escalado tiene un espacio limitado.';

  @override
  String get sizeAndLayout => 'Tamaño y diseño';

  @override
  String get labelsGroup => 'Etiquetas';

  @override
  String get surfaceGroup => 'Superficie';

  @override
  String get clockAndDateGroup => 'Reloj y fecha';

  @override
  String get networkAndTrafficGroup => 'Red y tráfico';

  @override
  String get buttonsGroup => 'Botones';

  @override
  String get notificationAppsHint =>
      'Desactiva las aplicaciones cuyas notificaciones no necesites. Un interruptor habilitado permite notificaciones; la aplicación aún se puede iniciar.';

  @override
  String get notificationPanelLink => 'Aspecto del panel superior';

  @override
  String get overlayAccessAdb => 'Mostrar sobre otras aplicaciones (ADB)';

  @override
  String get tileStyleModern => 'moderno';

  @override
  String get tileStyleVolume => 'dimensional';

  @override
  String get showTime => 'Mostrar hora';

  @override
  String get showDate => 'Mostrar fecha';

  @override
  String get showWeather => 'Mostrar el tiempo';

  @override
  String get showNetwork => 'Mostrar estado de la red';

  @override
  String get showTraffic => 'Mostrar tráfico';

  @override
  String get scheduledBrightness => 'Brillo programado';

  @override
  String get followTileStyle => 'Seguir estilo';

  @override
  String get androidTvSettingsHint => 'Abra la configuración del sistema de TV';

  @override
  String get autoHideTopPanel => 'Ocultar automáticamente el panel';

  @override
  String get showSectionTitles => 'Mostrar títulos de sección';

  @override
  String get usageDaily => 'Diariamente';

  @override
  String get usageWeekly => 'Semanal';

  @override
  String get usageMonthly => 'Mensual';

  @override
  String get onlineWallpaperAddress => 'Dirección de imagen (HTTPS)';

  @override
  String get watchNextAppLimits => 'Límites por aplicación';

  @override
  String get watchNextAppLimitsHint =>
      'Los límites de fuente se aplican antes del límite general. Ilimitado mantiene sólo el límite general; el contenido oculto permanece oculto.';

  @override
  String get rememberCategoryFocus => 'Recuerda la última tarjeta enfocada';

  @override
  String get automaticBackups => 'Copia de seguridad automática';

  @override
  String get automaticBackupsHint =>
      'Copias diarias de configuraciones, fondos de pantalla y pancartas mientras el iniciador está activo. Se ejecuta una copia perdida después de regresar al iniciador. Almacenado de forma privada en este dispositivo, hasta 256 MiB en total; eliminar la aplicación o sus datos los elimina. Mantenga también una copia de seguridad externa.';

  @override
  String get automaticBackupsEnabled => 'Copia de seguridad automática diaria';

  @override
  String get automaticBackupsKeep => 'Copias para conservar';

  @override
  String get automaticBackupCreateNow => 'Crea un punto de restauración ahora';

  @override
  String get automaticBackupFailed =>
      'La operación de copia de seguridad falló. Comprueba el espacio libre y vuelve a intentarlo.';

  @override
  String get restorePoints => 'puntos de restauración';

  @override
  String get noRestorePoints => 'Aún no hay puntos de restauración';

  @override
  String get updatePrereleases => 'Actualizar a versiones preliminares';

  @override
  String get topPanelObjects => 'Objetos';

  @override
  String get panelTransparency => 'Transparencia del panel';

  @override
  String get panelTextBackground => 'Fondo de texto y botón';

  @override
  String get panelTextBackgroundColor =>
      'Color de fondo del texto y del botón.';

  @override
  String get panelTextColor => 'Color del texto y del botón';

  @override
  String get panelTextSize => 'Tamaño del texto y del botón';

  @override
  String get panelFont => 'Fuente de texto';

  @override
  String get fontSans => 'Sans serifa';

  @override
  String get fontSerif => 'Serifa';

  @override
  String get fontMono => 'monoespacio';

  @override
  String get fontCondensed => 'condensado';

  @override
  String get trafficPermissionGranted =>
      'Acceso a estadísticas de tráfico concedido';

  @override
  String get background => 'Antecedentes';

  @override
  String get backgroundParameters => 'Ajustes de la fuente';

  @override
  String get resetAppearanceHint =>
      '¿Restablecer fondo, acento, mosaicos, etiquetas, resaltado y animación?';

  @override
  String get wallpaperDimming => 'Atenuación';

  @override
  String get wallpaperPlacement => 'Colocación';

  @override
  String get wallpaperDisplay => 'Pantalla de fondo de pantalla';

  @override
  String get wallpaperContain => 'Mostrar imagen completa';

  @override
  String get wallpaperBlurred => 'Sobre copia borrosa';

  @override
  String get wallpaperCover => 'Llenar pantalla';

  @override
  String get wallpaperBrightness => 'Brillo del fondo de pantalla';

  @override
  String get wallpaperSaturation => 'Saturación';

  @override
  String get categoryPadding => 'Relleno de categoría';

  @override
  String get categoryLight => 'Luz';

  @override
  String get categoryBlue => 'azul';

  @override
  String get categoryPurple => 'Púrpura';

  @override
  String get categoryAllRows => 'Todos';

  @override
  String get categoryTeal => 'verde azulado';

  @override
  String get categoryMaxRows => 'Filas de cuadrícula visibles';

  @override
  String get categoryDark => 'oscuro';

  @override
  String get categoryAppearance => 'Apariencia de categoría';

  @override
  String get categoryBackground => 'Antecedentes de la categoría';

  @override
  String get categoryTransparent => 'Transparente';

  @override
  String get slideshowInterval => 'Intervalo de cambio';

  @override
  String get slideshowFolderSelected =>
      'Acceso a la carpeta guardada en este dispositivo.';

  @override
  String get slideshowRandom => 'Orden aleatorio';

  @override
  String get wallpaperSlideshow => 'Presentación de diapositivas de carpeta';

  @override
  String get slideshowNext => 'Siguiente imagen';

  @override
  String get slideshowFolderRequired =>
      'Elija una carpeta para iniciar la presentación de diapositivas.';

  @override
  String get slideshowHint =>
      'Hasta 1000 imágenes y 4000 entradas de carpetas; archivos de hasta 8 MiB. Los archivos corruptos se omiten y se conserva la última imagen buena. Los cambios se detienen en segundo plano. Elija la carpeta nuevamente después de restaurar en otro dispositivo.';

  @override
  String get slideshowSeconds => 's';

  @override
  String get slideshowError =>
      'No se pueden leer imágenes. Elija una carpeta accesible que contenga imágenes válidas.';

  @override
  String get slideshowFolder => 'Elige carpeta';

  @override
  String get slideshowRecursive => 'Incluir subcarpetas';

  @override
  String get weatherSourceKeyRequired =>
      'Agregue una clave API para esta fuente meteorológica.';

  @override
  String get weatherOpenWeatherCredit =>
      'Tiempo: OpenWeather (openweathermap.org). Los valores diarios resumen los períodos de pronóstico de tres horas disponibles.';

  @override
  String get weatherOpenWeatherHint =>
      'Utilice su clave para el clima actual y el pronóstico de 5 días/3 horas. Cada actualización realiza dos solicitudes; el acceso y los límites dependen de su plan.';

  @override
  String get weatherOpenWeatherKey => 'Llave OpenWeather API';

  @override
  String get mediaPause => 'Pausa';

  @override
  String get showNowPlaying => 'Mostrar ahora reproduciéndose en Inicio';

  @override
  String get nowPlayingAccessHint =>
      'Los controles multimedia requieren acceso a notificaciones para CuteLauncher. Sólo se muestran las acciones proporcionadas por el jugador.';

  @override
  String get nowPlaying => 'Ahora jugando';

  @override
  String get mediaNext => 'Siguiente pista';

  @override
  String get mediaPlay => 'Currículum';

  @override
  String get mediaControlError =>
      'El jugador no está disponible o no aceptó esta acción.';

  @override
  String get nightUsageAccess => 'Permitir acceso de uso';

  @override
  String get nightExcludedAppsHint =>
      'La superposición y el filtro TCL programado se pausan en aplicaciones seleccionadas. Se requiere acceso de uso; sin él, no se pueden aplicar exclusiones.';

  @override
  String get nightExcludedApps => 'Aplicaciones excluidas';

  @override
  String get adbPairPort => 'Puerto de emparejamiento';

  @override
  String get adbPairOverlayHint =>
      'Abra la depuración inalámbrica y empareje con código de emparejamiento. Mantenga abierto el cuadro de diálogo del código del sistema. Este formulario se activa después de 30 segundos. Ingrese ambos puertos y el código mostrado por Android.';

  @override
  String get adbOverlaySettings =>
      'Devuelva el control a Configuración durante 30 segundos';

  @override
  String get adbTlsHint =>
      'Utilice la depuración inalámbrica en las opciones de desarrollador. El emparejamiento y la conexión tienen diferentes puertos. Si su firmware no tiene una pantalla de código de emparejamiento o bloquea ventanas superpuestas, utilice TCP/RSA en su lugar. Todas las conexiones siguen siendo locales para este televisor.';

  @override
  String get adbPaired =>
      'Emparejado. Verifique la conexión utilizando el puerto de conexión de depuración inalámbrica.';

  @override
  String get adbTransport => 'Método de conexión';

  @override
  String get adbPairCode => 'Código de seis dígitos';

  @override
  String get adbOverlayRequired =>
      'La entrada de código en Configuración requiere permiso para mostrarse en otras aplicaciones.';

  @override
  String get adbOverlayPermission =>
      'Permitir visualización sobre otras aplicaciones';

  @override
  String get adbTlsUnsupported =>
      'Este firmware no puede abrir la pantalla de configuración requerida ni la superposición de emparejamiento. Utilice TCP/RSA.';

  @override
  String get adbConnectPort => 'Puerto de conexión';

  @override
  String get adbTls => 'TLS/código de emparejamiento';

  @override
  String get adbTcp => 'TCP/RSA';

  @override
  String get adbPairingFailed =>
      'El emparejamiento falló. Verifique el código y el puerto de emparejamiento, mantenga abierto el cuadro de diálogo del código Android e inténtelo nuevamente.';

  @override
  String get adbTlsDisabled =>
      'La depuración inalámbrica está deshabilitada o su estado no está disponible. Habilítelo en Opciones de desarrollador.';

  @override
  String get adbPairOverlay =>
      'Ingrese el código de emparejamiento en Configuración';

  @override
  String get adbPair => 'par';

  @override
  String get adbDeveloperSettings => 'Abrir opciones de desarrollador';

  @override
  String get adbTwoWindowsHint =>
      'Si este firmware admite dos ventanas, mantenga abierto el cuadro de diálogo de emparejamiento del sistema junto a CuteLauncher e ingrese su código aquí. El emparejamiento directo solo está disponible mientras ambas ventanas están abiertas.';

  @override
  String get adbTwoWindows => 'Abra Configuración en una segunda ventana';

  @override
  String get autoLaunchBoot => 'Después del arranque del televisor';

  @override
  String get autoLaunchOff => 'Discapacitado';

  @override
  String get autoLaunchTitle => 'Inicio automático';

  @override
  String get autoLaunchDelay => 'Retraso de lanzamiento';

  @override
  String get autoLaunchHdmi => 'Cambiar a una entrada HDMI seleccionada';

  @override
  String get autoLaunchWake => 'despues de despertar';

  @override
  String get autoLaunchHint =>
      'Elija una aplicación o entrada HDMI para abrir después de encender o activar el televisor. Configure el evento y el retraso a continuación. La acción se ejecuta una vez cuando Android muestra CuteLauncher. Cualquier entrada remota o salir de la pantalla de inicio cancela la espera. Puede cambiar libremente las entradas del HDMI posteriormente. Configure CuteLauncher como iniciador predeterminado o habilite Iniciar al arrancar si es necesario. La detección de reactivación requiere que CuteLauncher siga ejecutándose.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds segundos';
  }

  @override
  String get autoLaunchApp => 'Abrir una aplicación seleccionada';

  @override
  String get autoLaunchTarget => 'Objetivo de lanzamiento';

  @override
  String get autoLaunchUnavailable =>
      'El objetivo no está disponible o el firmware no permite esta acción.';

  @override
  String get autoLaunchCancelled => 'Lanzamiento retrasado cancelado.';

  @override
  String get syncTitle => 'Configuración de intercambio';

  @override
  String get syncHint =>
      'Guarde un archivo de configuración, transfiéralo a otro dispositivo y ábralo allí. Vuelva a intercambiar el archivo para actualizar ambos dispositivos. Se comparten las preferencias de interfaz, estilo de mosaico y visualización. Las aplicaciones, secciones, archivos de fondo de pantalla, permisos, HOME, reglas de inicio y secretos permanecen en este dispositivo. Este es un intercambio manual; no se utiliza ninguna cuenta ni conexión de red en segundo plano.';

  @override
  String get syncExport => 'Guardar cambios en un archivo';

  @override
  String get syncImport => 'Abrir cambios desde otro dispositivo';

  @override
  String get syncSaved => 'Archivo de intercambio de configuración guardado.';

  @override
  String get syncFailed =>
      'No se pueden intercambiar configuraciones. No se conserva ninguna importación parcial. Verifique el archivo o ábralo nuevamente si la configuración cambió durante la revisión.';

  @override
  String get syncPreviewHint =>
      'Revise los cambios antes de aplicar. Para conflictos, seleccione cada fila para elegir este dispositivo o el archivo. Inicialmente se selecciona mantener este dispositivo. Cancelar deja la configuración sin cambios.';

  @override
  String get syncNoChanges =>
      'Sin nuevas configuraciones. Aplicar para reconocer la historia compartida.';

  @override
  String syncLocalValue(String value) {
    return 'Este dispositivo: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'Del archivo: $value';
  }

  @override
  String get syncKeepLocal => 'Conflicto: conservar este dispositivo';

  @override
  String get syncUseFile => 'Conflicto: usar el archivo';

  @override
  String get syncApply => 'Aplicar cambios revisados';

  @override
  String get syncApplied =>
      'Configuraciones intercambiadas. Guarde un nuevo archivo para enviar el resultado.';

  @override
  String syncStyleParameters(int count) {
    return 'Estilo personalizado: $count parámetros (diferencias abajo)';
  }

  @override
  String get cloudBackups => 'Copias de seguridad en la nube';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud. Ingrese la dirección HTTPS de una carpeta existente y una contraseña de la aplicación. Las transferencias son manuales; esta carpeta almacena la última copia.';

  @override
  String get cloudUrl => 'Dirección de carpeta HTTPS';

  @override
  String get cloudUser => 'Nombre de usuario';

  @override
  String get cloudPassword => 'Contraseña de la aplicación';

  @override
  String get cloudConnect => 'Consultar y guardar cuenta';

  @override
  String get cloudCheck => 'Comprobar conexión';

  @override
  String get cloudDisconnect => 'Desconectar cuenta';

  @override
  String get cloudDisconnectConfirm =>
      '¿Eliminar esta cuenta del televisor? Las copias en la nube permanecerán.';

  @override
  String get cloudUpload => 'Guardar una copia en la nube';

  @override
  String get cloudDownload => 'Restaurar desde la nube';

  @override
  String get cloudUploadConfirm =>
      '¿Reemplazar cutelauncher_backup.json en esta carpeta con la configuración y los datos actuales?';

  @override
  String get cloudSuccess => 'hecho';

  @override
  String get cloudConfigurationError =>
      'Verifique la dirección de la carpeta HTTPS, el nombre de usuario y la contraseña de la aplicación.';

  @override
  String get cloudAuthorizationError =>
      'Acceso denegado. Verifique los permisos de su cuenta y carpeta.';

  @override
  String get cloudMissingError =>
      'No se encontró la carpeta o la copia de seguridad.';

  @override
  String get cloudUnsupportedError =>
      'Esta dirección no admite las operaciones WebDAV requeridas. No se siguen redirecciones; ingrese la dirección final de la carpeta.';

  @override
  String get cloudNetworkError =>
      'La conexión falló o se agotó el tiempo de espera. Inténtalo de nuevo cuando la red esté disponible.';

  @override
  String get cloudFailed =>
      'No se pudo completar la acción de copia de seguridad. Verifique el acceso al almacenamiento e inténtelo nuevamente.';

  @override
  String get cloudStorageError =>
      'El almacenamiento de la cuenta no está disponible. Desconecta y configura la cuenta nuevamente.';

  @override
  String get adbPermissionChecking => 'Comprobando acceso…';

  @override
  String get adbPermissionConnected => 'ADB conectado · otorgar permiso';

  @override
  String get adbPermissionDisconnected =>
      'ADB desconectado · configurar conexión';

  @override
  String get adbSetupIntro =>
      'Habilite la depuración y la red ADB en la configuración del desarrollador de TV, luego confíe en CuteLauncher. Todas las acciones ADB son bajo su propio riesgo.';

  @override
  String get adbConnectionBlock => 'Conexión ADB';

  @override
  String get adbNotChecked => 'Conexión no comprobada';

  @override
  String get adbApplied => 'Ya aplicado';

  @override
  String get adbNotApplied => 'Aún no aplicado';

  @override
  String get adbDefaultBlock => 'Lanzador predeterminado';

  @override
  String get adbSystemDefault =>
      'Abrir la configuración predeterminada del iniciador del sistema';

  @override
  String get adbAssignDefault =>
      'Configure CuteLauncher como iniciador predeterminado a través de ADB';

  @override
  String get adbRestoreDefault =>
      'Restaure el iniciador predeterminado anterior a través de ADB';

  @override
  String get adbDefaultHint =>
      'Utilice ADB si el menú del sistema no puede configurar el iniciador predeterminado.';

  @override
  String get adbBuiltinHint =>
      'Deshabilitar el iniciador incorporado permite que el sistema abra CuteLauncher. Los menús y botones del televisor pueden verse afectados. Habilite el iniciador incorporado para deshacer esto.';

  @override
  String get adbHomeBlock => 'Botón de inicio y inicio';

  @override
  String get adbEnableService =>
      'Habilite el servicio de accesibilidad CuteLauncher a través de ADB';

  @override
  String get adbHomeOverride => 'Anular el botón Inicio';

  @override
  String get adbHomeOptional =>
      'Si el iniciador integrado está deshabilitado, anular Inicio e iniciar al iniciar el televisor son opcionales.';

  @override
  String get adbEnableBuiltin =>
      'Habilite el iniciador integrado a través de ADB';

  @override
  String get adbDisableBuiltin =>
      'Deshabilite el iniciador incorporado a través de ADB';

  @override
  String get adbNoBuiltin =>
      'No se encontraron lanzadores Google TV / Android TV integrados.';

  @override
  String get adbChanged =>
      'El estado cambió. Verifique la conexión y confirme la acción nuevamente.';

  @override
  String get adbEffectHome =>
      'CuteLauncher se convertirá en el iniciador predeterminado del sistema. El iniciador actual se guardará para su restauración.';

  @override
  String get adbEffectRestore =>
      'El iniciador anterior se habilitará y se establecerá como predeterminado. Si no está disponible o no se guarda, se selecciona el primer otro iniciador disponible. Esto no desactiva la corrección del botón de inicio.';

  @override
  String get adbEffectDisable =>
      'La aplicación de inicio incorporada se desactivará para el usuario de TV. Los menús y botones del televisor pueden dejar de funcionar. La aplicación no se desinstala.';

  @override
  String get adbRecoveryHomeDisable =>
      'Todo el asistente de configuración de Google TV, incluida su pantalla de inicio de recuperación, también se desactivará para que CuteLauncher pueda convertirse en el iniciador predeterminado. Las funciones del asistente de configuración no estarán disponibles hasta la restauración. Los estados originales de ambos paquetes se guardarán para su restauración.';

  @override
  String get adbRecoveryHomeRestore =>
      'El asistente de configuración Google TV también volverá a su estado guardado.';

  @override
  String get adbDisableHomeUnavailable =>
      'Otra pantalla de inicio tiene mayor prioridad. Este lanzador no puede desactivarlo de forma segura.';

  @override
  String get adbEffectEnable =>
      'El iniciador integrado se restaurará a su estado guardado o se habilitará si no se guardó ningún estado. Es posible que el sistema vuelva a seleccionarlo como iniciador predeterminado.';

  @override
  String get adbEffectAccessibility =>
      'Se habilitará el servicio de accesibilidad CuteLauncher. Puede recibir eventos de Inicio; la interceptación se controla mediante un interruptor separado. Se conservan otros servicios.';

  @override
  String get adbEffectAccessibilityRestore =>
      'El servicio CuteLauncher volverá a su estado anterior a que se concediera el acceso a ADB. Se conservan otros servicios de accesibilidad.';

  @override
  String get adbEffectOverlay =>
      'A CuteLauncher se le permitirá mostrar ventanas sobre otras aplicaciones, incluido el filtro nocturno.';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher recibirá acceso a notificaciones a través de su propio servicio de escucha.';

  @override
  String get adbEffectWatchNext =>
      'CuteLauncher recibirá acceso a los datos de Continuar viendo.';

  @override
  String get adbEffectUsage =>
      'CuteLauncher recibirá acceso a estadísticas de uso para el tráfico y la detección de aplicaciones en primer plano.';

  @override
  String get adbEffectWriteSettings =>
      'A CuteLauncher se le permitirá cambiar la configuración de brillo del sistema.';

  @override
  String get adbNoAvailableLauncher =>
      'No se encontraron otros lanzadores instalados. La restauración no está disponible.';

  @override
  String get adbUnsupported =>
      'No disponible en este dispositivo: no hay comando ADB compatible.';

  @override
  String get adbHomeUnavailable =>
      'El lanzador incorporado tiene prioridad del sistema. La asignación directa a través de ADB no está disponible; use la accesibilidad o desactive el iniciador incorporado.';

  @override
  String get nightBatteryExempt => 'CuteLauncher está exento de optimización';

  @override
  String get nightBatteryHint =>
      'Puede ayudar a que la programación se ejecute en segundo plano. No garantiza que el proceso sobreviva al modo de espera.';

  @override
  String get nightBatteryOptimized => 'CuteLauncher está sujeto a optimización';

  @override
  String get nightBatteryTitle => 'Optimización de la batería';

  @override
  String get nightBatteryUnavailable =>
      'La configuración del sistema no está disponible en este firmware o se denegó el acceso.';

  @override
  String get nightBatteryUnknown => 'Estado de exención desconocido';

  @override
  String get nightBatteryOpenApps => 'Abrir configuración de aplicaciones';

  @override
  String get nightBatteryGuide =>
      '1. En la configuración de aplicaciones, abra Acceso a aplicaciones especiales.\n2. Seleccione Optimización de la batería (a veces Ahorro de energía).\n3. Busque CuteLauncher; seleccione Todas las aplicaciones si es necesario.\n4. Desactive la optimización o seleccione Sin restricciones.\nLos nombres de los menús y la disponibilidad dependen del firmware del televisor.';

  @override
  String get updateNotifications => 'Mostrar notificaciones de actualización';

  @override
  String get diagnosticsSave => 'Guardar informe en archivo';

  @override
  String get diagnosticsSaved => 'Informe guardado';

  @override
  String get diagnosticsSaveFailed =>
      'No se pudo guardar el informe. Verifique el administrador de archivos y la carpeta de destino.';

  @override
  String get memoryCacheSize => 'Tamaño de caché de imagen';

  @override
  String get memoryProcess => 'Memoria de la aplicación';

  @override
  String get memoryImages => 'Cachés de imágenes';

  @override
  String get diagnosticsExportOpened =>
      'Elija una carpeta en el administrador de archivos y guarde el informe.';

  @override
  String get adbDisableService =>
      'Deshabilite el servicio de accesibilidad CuteLauncher a través de ADB';

  @override
  String get adbDefaultSettings => 'Configuración predeterminada del iniciador';

  @override
  String get adbHomeSettings => 'Configuración del botón de inicio';

  @override
  String get adbAccessibilitySettings => 'Abrir configuración de accesibilidad';

  @override
  String get adbAccessibilityGuide =>
      'Seleccione CuteLauncher en el menú del sistema y habilite su servicio. Regrese aquí para configurar la interceptación de inicio. Para desactivarlo, desactive el servicio CuteLauncher en el mismo menú.';

  @override
  String get adbEffectAccessibilityDisable =>
      'El servicio CuteLauncher quedará deshabilitado. Se detendrá la interceptación domiciliaria. Se conservan otros servicios de accesibilidad.';

  @override
  String get backupAutoEnabled => 'Copia de seguridad automática';

  @override
  String get backupClientId => 'ID de cliente';

  @override
  String get backupClientSecret => 'Secreto del cliente';

  @override
  String get backupCloudImportConfirm =>
      'Todas las configuraciones, categorías e imágenes locales serán reemplazadas con datos de la nube. ¿Continuar?';

  @override
  String get backupConfigured => 'Configurado';

  @override
  String get backupConnection => 'Configuración de conexión';

  @override
  String get backupCreated => 'Creado';

  @override
  String get backupDaily => 'Diariamente';

  @override
  String get backupDriveHelp =>
      'Seleccione Conectar y confirme el código en su teléfono. Las copias de seguridad están visibles en la carpeta CuteLauncher en Google Drive, donde puede descargarlas o eliminarlas. Mantenga los nombres de los archivos sin cambios para la restauración dentro de la aplicación. Vuelva a conectarse después de actualizar desde copias de seguridad ocultas; Las copias de seguridad antiguas no se migran automáticamente.';

  @override
  String get backupFrequency => 'Frecuencia de respaldo';

  @override
  String get backupHourly => 'Por hora';

  @override
  String get backupLocal => 'Copias locales';

  @override
  String get backupMinutes => 'mín.';

  @override
  String get backupMode => 'Modo';

  @override
  String get backupNever => 'Aún no hay copia de seguridad';

  @override
  String get backupNotConfigured => 'No configurado';

  @override
  String get backupOptions => 'Opciones de copia de seguridad';

  @override
  String get backupSaveMode => 'Copia de seguridad';

  @override
  String get backupScope => 'Copia de seguridad en televisores';

  @override
  String get backupSyncScope => 'Sincronización entre televisores';

  @override
  String get backupSeparate => 'Separado para cada televisor';

  @override
  String get backupShared =>
      'Mismas configuraciones para todos los televisores';

  @override
  String get backupStorage => 'Almacenamiento';

  @override
  String get backupSyncHelp =>
      'Descargar datos y subir cambios. El último cambio gana los conflictos. Los relojes de televisión deben ser correctos. La sincronización se ejecuta mientras el iniciador está abierto.';

  @override
  String get backupSyncLimit => 'Verifique no más a menudo que';

  @override
  String get backupSyncMode => 'Sincronización';

  @override
  String get backupSyncOptions => 'Opciones de sincronización';

  @override
  String get backupTime => 'tiempo de respaldo';

  @override
  String get backupWeekday => 'dia de la semana';

  @override
  String get backupWeekly => 'Semanal';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'Las copias locales se eliminan con la aplicación o sus datos. Mantenga una copia fuera del televisor también.';

  @override
  String get panelObjectOrder => 'Orden de objetos';

  @override
  String get panelInformationGroup => 'Información';

  @override
  String get panelOrderHint =>
      '◄ / ► inicia o termina el movimiento; ▲ / ▼ cambia el orden y pasa al otro lado en el límite del grupo; OK / Atrás termina.';

  @override
  String get panelTextBackgroundTransparency =>
      'Transparencia de fondo de texto y botones.';

  @override
  String get weatherCityHint =>
      'Introduzca el nombre de la ciudad en inglés, por ejemplo Moscú.';

  @override
  String get weatherCityNotFound =>
      'Ciudad no encontrada. Consulta el nombre de la ciudad en inglés.';

  @override
  String get weatherLocationAutomatic => 'Obtener automáticamente';

  @override
  String get weatherLocationAutomaticHint =>
      'Obtenga las coordenadas del dispositivo. Se requiere permiso de ubicación.';

  @override
  String get weatherLocationManual => 'Ingresar manualmente';

  @override
  String get weatherLocationPermissionDenied =>
      'Permita el acceso a la ubicación en la configuración de Android y vuelva a intentarlo.';

  @override
  String get weatherLocationUnavailable =>
      'No se pudieron obtener las coordenadas. Verifique la configuración de ubicación de Android o ingrese una ciudad manualmente.';

  @override
  String get nightFilterSettings => 'Configuración de filtro';

  @override
  String get nightScheduleMenu => 'Horario';

  @override
  String get nightScheduleInactive => 'El horario está apagado';

  @override
  String get nightLocation => 'Ubicación';

  @override
  String get nightLocationAutomatic => 'Obtener automáticamente';

  @override
  String get nightLocationManual => 'Ingresar manualmente';

  @override
  String get nightLocationFailed =>
      'Ubicación no disponible. Verifique la configuración de permisos y ubicación del sistema.';

  @override
  String get nightCityEnglish => 'Ingrese el nombre de la ciudad en inglés';

  @override
  String get nightOverlayBrief =>
      'Permite que el filtro aparezca sobre otras aplicaciones.';

  @override
  String get weatherGetLocation => 'Obtener ubicación';

  @override
  String get backupLastCreated => 'Se creó la última copia de seguridad:';

  @override
  String get backupManagement => 'Administrar copias de seguridad';

  @override
  String get backupCopyList => 'Lista de respaldo';

  @override
  String get backupRefreshCopyList => 'Actualizar lista de respaldo';

  @override
  String get backupCreateNow => 'Crea una nueva copia de seguridad ahora';

  @override
  String get backupFolderPath => 'Carpeta de respaldo';

  @override
  String get backupPrivateFolder => 'Carpeta de aplicación privada';

  @override
  String get backupRestoreCopy => 'Restaurar esta copia de seguridad';

  @override
  String get backupDeleteConfirm =>
      '¿Eliminar la copia de seguridad seleccionada?';

  @override
  String get blockedAppsGroup => 'Aplicaciones bloqueadas';

  @override
  String get notificationSettingsButton => 'Configuración de notificaciones';

  @override
  String get hidePersistentNotificationsHint =>
      'Oculte notificaciones persistentes en la lista y en otras aplicaciones.';

  @override
  String get nightTransitionTime => 'tiempo de transición';

  @override
  String get brightnessSolar => 'Usar horario de modo nocturno';

  @override
  String get brightnessAfterSunrise => 'despues del amanecer';

  @override
  String get brightnessAfterSunset => 'despues del atardecer';

  @override
  String get brightnessTransitionTime => 'Tiempo de transición de brillo';

  @override
  String get brightnessSolarUnavailable =>
      'El horario del modo nocturno no está disponible. Consulta sus horarios y ubicación.';

  @override
  String get persistentNotificationCannotDelete =>
      'Esta notificación persistente no se puede eliminar. Sólo puedes bloquearlo.';

  @override
  String get diagnosticsCreateFailed =>
      'No se pudo crear el informe de diagnóstico. Intentar otra vez.';

  @override
  String get backupListFailed =>
      'No se pudo cargar la lista de respaldo. Verifique el acceso al almacenamiento seleccionado.';

  @override
  String get updateInstallerFailed =>
      'No se pudo abrir el instalador de la actualización. Inténtelo de nuevo y verifique que el instalador Android esté disponible.';

  @override
  String get backupFolderFailed =>
      'No se pudo seleccionar ni guardar la carpeta de respaldo. Elija una carpeta accesible e inténtelo nuevamente.';

  @override
  String get updateDownloadFailed =>
      'No se pudo descargar la actualización. Verifique su conexión a Internet y el almacenamiento disponible.';

  @override
  String get backupDeleteFailed =>
      'No se pudo eliminar la copia de seguridad. Verifique los permisos de eliminación e inténtelo nuevamente.';

  @override
  String get updateCheckFailed =>
      'No se pudo buscar actualizaciones. Verifique su conexión a Internet e inténtelo nuevamente.';

  @override
  String get backupCreateFailed =>
      'No se pudo crear la copia de seguridad. Verifique el acceso al almacenamiento y el espacio disponible.';

  @override
  String get wallpaperChangeFailed =>
      'No se pudo cambiar el fondo de pantalla. Verifique el acceso al archivo e inténtelo nuevamente.';

  @override
  String get backupDownloadsFolder => 'Descargas / CuteLauncher';

  @override
  String get backupChooseFolder =>
      'Elija una carpeta en el administrador de archivos';

  @override
  String get backupFolderPickerUnavailable =>
      'No hay ningún selector de carpetas disponible en este televisor. Elija Descargas / CuteLauncher o la carpeta interna de la aplicación.';

  @override
  String get driveConfigurationError =>
      'Las credenciales Google Drive faltan o no son válidas. Ingrese el ID de cliente y el secreto de cliente de su cliente TV OAuth.';

  @override
  String get driveCodeExpired =>
      'Google Drive Se agotó el tiempo de tiempo de inicio de sesión. Seleccione Verificar y guardar cuenta para obtener un nuevo código.';

  @override
  String get brightnessAfterNightStart => 'Noche';

  @override
  String get brightnessAfterNightEnd => 'diurno';

  @override
  String get backupSyncSettings => 'Configuraciones para sincronizar';

  @override
  String get backupSyncHomeGroup =>
      'Pantalla de inicio, secciones y aplicaciones';

  @override
  String get backupSyncAppearanceGroup =>
      'Apariencia, fondos de pantalla y banners.';

  @override
  String get backupSyncDisplayGroup => 'Modo nocturno, brillo y salvapantallas';

  @override
  String get backupSyncControlsGroup => 'Controles de lanzador y TV';

  @override
  String get backupSyncGeneralGroup =>
      'Idioma, actualizaciones y otras configuraciones';

  @override
  String get backupSyncGroupsHelp =>
      'Los bloques para discapacitados permanecen locales en este televisor. La selección de bloques se sincroniza entre dispositivos.';

  @override
  String get backupSyncGroupsFailed =>
      'No se pudo guardar la selección de configuración para la sincronización. Intentar otra vez.';

  @override
  String get tileLayoutMode => 'Diseño de mosaicos';

  @override
  String get tileLayoutAuto => 'Automático por tamaño de mosaico';

  @override
  String get tileLayoutColumns => 'Recuento de columnas fijo';

  @override
  String get tileLayoutRows => 'Recuento de filas fijo';

  @override
  String get tileRowCount => 'recuento de filas';

  @override
  String get useGlobalTileSettings => 'Usar configuración global';

  @override
  String get centerSelection => 'Posición de selección';

  @override
  String get selectionBottom => 'Abajo';

  @override
  String get selectionLower => 'Medio bajo';

  @override
  String get selectionCenter => 'Centro';

  @override
  String get selectionUpper => 'Medio superior';

  @override
  String get selectionTop => 'Arriba';

  @override
  String get settingsStyle => 'Estilo de configuración';

  @override
  String get tileFocusEnlargement => 'Ampliación de enfoque';

  @override
  String get tileFocusShadowStrength => 'Fuerza de la sombra';

  @override
  String get tileFocusLift => 'ascensor';

  @override
  String get tileFocusLiftHeight => 'Altura de elevación';

  @override
  String get tileFocusBorderColor => 'Color del borde de enfoque';

  @override
  String get tileFocusAccentColor => 'Color de acento';

  @override
  String get tileFocusDynamicColor => 'Colores dinámicos';

  @override
  String get tileSizeFromColumns =>
      'El tamaño del mosaico está determinado por el número de columnas y el ancho de la sección.';

  @override
  String get resetSectionToGlobal =>
      'Restablecer la configuración a valores compartidos';

  @override
  String get resetSectionToGlobalHint =>
      '¿Restaurar títulos, íconos y fondos de secciones compartidas y restablecer el relleno?';

  @override
  String get resetStyleSection => 'Restablecer esta sección';

  @override
  String get resetStyleSectionHint =>
      '¿Restaurar los valores predeterminados solo para esta sección?';

  @override
  String get notificationStyle => 'Estilo de notificación';

  @override
  String get styleBackgroundColor => 'Color de fondo';

  @override
  String get styleTransparency => 'Transparencia de fondo';

  @override
  String get styleTextSize => 'Tamaño del texto';

  @override
  String get styleTextColor => 'Color del texto';

  @override
  String get noticeSize => 'Tamaño de notificación';

  @override
  String get noticeStylePreview => 'Vista previa de notificación';

  @override
  String get backupSyncHomeOptions => 'Comportamiento y opciones generales.';

  @override
  String get backupSyncBackground => 'Fondo y banners personalizados';

  @override
  String get backupSyncTiles => 'Estilo de mosaico, menú y notificación';

  @override
  String get backupSyncWeatherSource => 'Fuente y ubicación';

  @override
  String get backupSyncWeatherDisplay =>
      'Visualización del tiempo y unidades de temperatura.';

  @override
  String get backupSyncNotificationSettings =>
      'Pantalla de notificación y filtros';

  @override
  String get backupSyncOther => 'Otras configuraciones';

  @override
  String get tileFocusBorderStyle => 'Estilo de borde';

  @override
  String get tileFocusOutline => 'esquema';

  @override
  String get tileFocusGlow => 'Resplandor';

  @override
  String get tileFocusNoBorder => 'Sin fronteras';

  @override
  String get tileShowFocusShadow => 'Mostrar sombra';

  @override
  String get homeLayoutRow => 'fila horizontal';

  @override
  String get homeLayoutRows => 'Varias filas';

  @override
  String get homeLayoutGrid => 'Cuadrícula';

  @override
  String get homeCardCount => 'Tarjetas visibles a través';

  @override
  String get homeAuto => 'Automático';

  @override
  String get homeFree => 'Desplazamiento libre';

  @override
  String get homeAnchored => 'Tramo anclado';

  @override
  String get homeScrollMode => 'Desplazamiento de sección';

  @override
  String get homeSectionPosition => 'Posición de la sección activa';

  @override
  String get homeLabelMode => 'Etiquetas de aplicación';

  @override
  String get homeLabelNone => 'Sin etiquetas';

  @override
  String get homeLabelSelected => 'Sólo aplicación seleccionada';

  @override
  String get homeLabelAll => 'Todas las aplicaciones';

  @override
  String get homeInherited => 'Valor heredado';

  @override
  String get homeOwnReset => 'Restaurar ajustes comunes';

  @override
  String get homeParameters => 'Parámetros';

  @override
  String get homeSectionStyle => 'Apariencia de la sección';

  @override
  String get homeSectionGap => 'Espacio entre secciones';

  @override
  String get homeSectionIcons => 'Iconos de sección';

  @override
  String get homeInactiveOpacity => 'Opacidad de la sección inactiva';

  @override
  String get homeResetSection =>
      'Restaurar la apariencia de la sección heredada';

  @override
  String get homeCalculatedSize =>
      'El tamaño se calcula a partir del recuento de cartas.';

  @override
  String homeGapLimited(int gap) {
    return 'El espacio está limitado a $gap para mantener el recuento de tarjetas seleccionadas.';
  }

  @override
  String get homeResetLayout => 'Restablecer diseño de sección';

  @override
  String homeVisibleRows(int count) {
    return 'Filas completamente visibles: $count';
  }

  @override
  String get homeStylePartial =>
      'Se aplica solo a las secciones que heredan este valor y lo admiten en su diseño actual.';

  @override
  String get homeStyleUnavailable =>
      'No disponible en la configuración de la sección actual. Verifique el diseño y las anulaciones locales.';

  @override
  String get homeStyleNeedsRows =>
      'Disponible para varias filas o una cuadrícula.';

  @override
  String get homeStyleNeedsLabels =>
      'Habilite las etiquetas para cambiar su tamaño y color.';

  @override
  String get homeStyleNeedsAllLabels =>
      'La posición se aplica sólo a las etiquetas de todas las tarjetas. El título seleccionado permanece debajo de la sección.';

  @override
  String get homeStyleNeedsScale =>
      'Seleccione el efecto de enfoque de ampliación.';

  @override
  String get homeStyleNeedsLift =>
      'Seleccione el efecto de enfoque de elevación.';

  @override
  String get homeStyleNeedsBorder => 'Primero habilite un contorno o brillo.';

  @override
  String get homeStyleNeedsTitle =>
      'Habilite el título de la sección para mostrar su icono.';

  @override
  String get homeStyleEconomy =>
      'Deshabilitado por ahorro de memoria. El valor guardado se conserva.';

  @override
  String get homeStyleOpaque =>
      'Reduzca la opacidad del fondo del mosaico para ver el desenfoque.';

  @override
  String get homeStyleOverridden =>
      'Las secciones visibles utilizan sus propios valores. Elija \"Usar global\" en una sección para aplicar esta configuración.';

  @override
  String get homeStyleIconHint =>
      'El tamaño del icono afecta a las tarjetas con el icono de una aplicación. Los carteles de televisión llenan la tarjeta de forma independiente.';

  @override
  String get homeStyleShadowHint =>
      'El ahorro de memoria limita la sombra de las tarjetas inactivas a 4. La sombra de enfoque se configura por separado.';

  @override
  String get homeStyleTransparent =>
      'El color de fondo es invisible con opacidad cero. Aumente la opacidad del fondo del mosaico.';

  @override
  String get homeStyleSingleColumn =>
      'Una cuadrícula de una sola columna no tiene espacios horizontales.';

  @override
  String get homeStyleAutoOnly =>
      'El tamaño cambia solo en secciones con recuento automático de tarjetas que heredan el tamaño global.';

  @override
  String get sleepTimerThirtySeconds => '30 segundos (prueba)';

  @override
  String get sleepTimer => 'Temporizador de sueño';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes mín.';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1,5 horas';

  @override
  String get sleepTimerAllowExact => 'Permitir temporizadores precisos';

  @override
  String get sleepTimerExactRequired =>
      'Permita temporizadores precisos en la configuración del Android y luego seleccione una duración nuevamente.';

  @override
  String get sleepTimerAccessRequired =>
      'Habilite la accesibilidad del CuteLauncher o conecte el ADB local en Configuración → Otro → ADB.';

  @override
  String get sleepTimerFailed =>
      'No se pudo configurar o completar el temporizador de apagado. Verificar accesibilidad y ADB local.';

  @override
  String get nightIgnoreHdmiInputs => 'Ignorar las entradas HDMI';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'Pausa el filtro nocturno mientras miras HDMI. Se requiere acceso de uso; La detección de entrada depende del firmware del televisor.';

  @override
  String get inputsSettings => 'Configuración de entrada';

  @override
  String get inputsUseCecNames => 'Utilice nombres de dispositivos de CEC';

  @override
  String get inputsNamesHint =>
      'Prioridad de nombre: su nombre en CuteLauncher → CEC (si está habilitado) → nombre de la configuración de Android → nombre de entrada estándar.';

  @override
  String get inputNameHint => 'Déjelo vacío para un nombre automático';

  @override
  String get inputsSaveFailed =>
      'No se pudo guardar la configuración de entrada';

  @override
  String get inputIcon => 'Icono de entrada';

  @override
  String get inputIconTv => 'televisión';

  @override
  String get inputIconGame => 'consola de juegos';

  @override
  String get inputIconComputer => 'Computadora';

  @override
  String get inputIconReceiver => 'Receptor';

  @override
  String get inputIconDisc => 'Reproductor de discos';

  @override
  String get inputIconStream => 'Dispositivo de transmisión';

  @override
  String get nightInputExclusions => 'Exclusiones de entrada';

  @override
  String get nightSelectInputs => 'Seleccionar entradas para ignorar';

  @override
  String get nightNoInputsSelected =>
      'No hay entradas seleccionadas. El filtro se aplicará a cada entrada.';

  @override
  String get nightPictureExclusions => 'Exclusiones del modo de imagen';

  @override
  String get nightPictureExclusionsHint =>
      'Seleccione modos que pausan la atenuación, la superposición cálida y el filtro TCL vinculado. El horario se conserva. La detección se ha verificado en TCL; No se requiere acceso de uso.';

  @override
  String get nightPictureUnavailable =>
      'El modo de imagen actual no está disponible en este firmware. Su selección se guarda; Las exclusiones se aplican sólo cuando la detección tiene éxito.';

  @override
  String get nightPictureCurrent => 'Modo actual';

  @override
  String get nightPictureRefresh => 'Actualizar modo actual';

  @override
  String get nightPictureCode => 'Código de modo';

  @override
  String get nightPictureStandard => 'Estándar';

  @override
  String get nightPictureDynamic => 'Dinámico';

  @override
  String get nightPictureMovie => 'película';

  @override
  String get nightPictureSport => 'deporte';

  @override
  String get nightPictureIntelligent => 'inteligente';

  @override
  String get nightPictureBright => 'Brillante (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'Estándar';

  @override
  String get systemApplications => 'Aplicaciones del sistema';

  @override
  String get removeFromCategory => 'Eliminar de la categoría';

  @override
  String get noRemovableCategories =>
      'Esta aplicación no se ha añadido manualmente a ninguna sección. No se puede quitar de las secciones automáticas estándar (Todas, Para TV, No para TV); use Ocultar. Favoritos se edita manualmente.';

  @override
  String get remoteButtonsTitle => 'Reasignación de botones del mando';

  @override
  String get remoteButtonsStart => 'Comprobar botones (120 s)';

  @override
  String get remoteButtonsStop => 'Detener comprobación';

  @override
  String get remoteButtonsHint =>
      'La prueba muestra códigos, liberaciones y repeticiones y guarda un informe de texto en el TV. Salga de esta página al iniciar para que OK no controle la grabación.';

  @override
  String get remoteButtonsEmpty =>
      'Aún no hay eventos. Si un botón abre una aplicación, vuelva aquí para ver el resultado.';

  @override
  String get remoteButtonsService => 'Servicio conectado';

  @override
  String get remoteButtonsRefresh => 'Actualizar';

  @override
  String get remoteBindings => 'Asignaciones de botones';

  @override
  String get remoteMappingsEnabled => 'Activar reasignación';

  @override
  String get remoteMappingsAdd => 'Añadir asignación';

  @override
  String get remoteMappingKey => 'Botón';

  @override
  String get remoteMappingAction => 'Acción';

  @override
  String get remoteMappingLearn => 'Detectar un botón';

  @override
  String get remoteMappingLearnHint =>
      'Pulse un botón adicional antes de 30 segundos. La navegación, Power, búsqueda por voz y volumen están protegidos.';

  @override
  String get remoteMappingsHint =>
      'Las asignaciones requieren el servicio de accesibilidad. Se pausan en el editor y durante el diagnóstico. Inicio, Atrás, flechas y OK mantienen su navegación.';

  @override
  String get remoteMappingsReset => 'Restablecer asignaciones';

  @override
  String get remoteMappingsResetConfirm =>
      '¿Eliminar todas las asignaciones y desactivar la reasignación?';

  @override
  String get remoteMappingInvalid =>
      'No se pudo guardar. Compruebe el botón y el destino. Los webhooks requieren HTTPS o HTTP en una red local.';

  @override
  String get remoteMappingBack => 'Atrás';

  @override
  String get remoteMappingProfile => 'Perfil';

  @override
  String get remoteMappingChannels => 'Canales';

  @override
  String get remoteMappingQuickSettings => 'Ajustes rápidos TCL';

  @override
  String get remoteMappingTrigger => 'Tipo de pulsación';

  @override
  String get remoteMappingPress => 'Pulsación corta';

  @override
  String get remoteMappingHold => 'Mantener pulsado';

  @override
  String get remoteMappingHoldHint =>
      'Mantenga 650 ms: una sola acción, sin pulsación corta. Si solo se asigna la pulsación larga, un toque corto no hace nada.';

  @override
  String get remotePanelDescription =>
      'El panel de ajustes rápidos muestra tus widgets sobre otras aplicaciones. Para abrirlo con el mando, asigna la acción «Panel de ajustes rápidos» al botón que prefieras.';

  @override
  String get remotePanel => 'Panel de ajustes rápidos';

  @override
  String get remotePanelSettingsBackground =>
      'Usar el color de fondo de los ajustes';

  @override
  String get remotePanelPreview => 'Abrir panel';

  @override
  String get settingsHelp => 'Más información';

  @override
  String get settingsHelpScroll => '▲ / ▼ — desplazar texto';

  @override
  String get panelClockStyle => 'Aspecto del reloj';

  @override
  String get clockPreset => 'Estilo de fuente';

  @override
  String get clockCustom => 'Personalizado';

  @override
  String get clockWeight => 'Grosor de fuente';

  @override
  String get clockGlow => 'Resplandor del texto';

  @override
  String get clockAnimate => 'Animar dígitos';

  @override
  String get clockBackground => 'Fondo del reloj';

  @override
  String get clockRadius => 'Radio de las esquinas del fondo';

  @override
  String get dateCalendarEnabled => 'Abrir el calendario al pulsar la fecha';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get dateSettings => 'Ajustes de fecha';

  @override
  String get clockSharedBackground => 'Usar el fondo de los demás objetos';

  @override
  String get clockDefaultBackground => 'Fondo predeterminado';

  @override
  String get remotePanelInheritAppearance =>
      'Usar el aspecto del panel superior';

  @override
  String get remotePanelDisabledInLauncher =>
      'El panel de ajustes rápidos está desactivado mientras CuteLauncher está en pantalla.';

  @override
  String get remoteAccessSettings => 'Configurar acceso';

  @override
  String get remoteButtonsTest => 'Prueba de botones';

  @override
  String remoteMappingDeleteConfirm(String name) {
    return '¿Eliminar la asignación «$name»?';
  }

  @override
  String get remoteMappingConflict =>
      'Este botón y tipo de pulsación ya están asignados. Elige otro botón o tipo de pulsación.';

  @override
  String get cleanerTitle => 'TV cleanup manager';

  @override
  String get cleanerRefresh => 'Refresh applications';

  @override
  String get cleanerSnapshot => 'Save original state';

  @override
  String get cleanerRestore => 'Restaurar el estado base';

  @override
  String get cleanerSnapshotSaved => 'Original state saved';

  @override
  String get cleanerExportSnapshot => 'Export original state';

  @override
  String get cleanerSafe => 'Disable verified applications';

  @override
  String get cleanerNoSafe =>
      'No hay lista de apps del sistema para este modelo y firmware.';

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
      'Exportar informe de aplicaciones desactivadas a un archivo';

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
      'El estado base se crea una sola vez al actualizar la lista correctamente por primera vez. El lanzador no permite borrarlo ni sobrescribirlo y está ligado al firmware. Los estados manuales guardan los modos de las apps con nombre y fecha; pueden restaurarse, eliminarse y exportarse. No incluyen APK ni datos. La restauración requiere ADB local. La protección ante fallos intenta restaurar automáticamente el estado base. Borrar los datos o desinstalar el lanzador elimina las copias; no se puede impedir el acceso root.';

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
  String get landscapeDemoStop => 'Parar';

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
  String get informationGroup => 'Reloj, fecha y tiempo';

  @override
  String get informationSettings => 'Ajustes del bloque';

  @override
  String get informationAppearance => 'Apariencia del bloque';

  @override
  String get informationSize => 'Tamaño del bloque';

  @override
  String get informationPosition => 'Posición del reloj y del texto';

  @override
  String get informationClockLeft => 'Reloj a la izquierda, texto a la derecha';

  @override
  String get informationClockRight =>
      'Texto a la izquierda, reloj a la derecha';

  @override
  String get informationSpacing => 'Espacio entre reloj y texto';

  @override
  String get informationBackground => 'Fondo del bloque';

  @override
  String get homeResetTilesHint =>
      '¿Restaurar los valores comunes de todas las tarjetas y etiquetas de esta pantalla?';

  @override
  String get homeResetLayoutHint =>
      '¿Restablecer el diseño de esta sección, restaurar la apariencia común y quitar los márgenes internos? Se conservarán las aplicaciones y su orden.';

  @override
  String get networkSummary => 'Red';

  @override
  String get networkConnected => 'Internet disponible';

  @override
  String get networkOffline => 'Sin acceso a Internet';

  @override
  String get networkDisconnected => 'Desconectado';

  @override
  String get networkConnection => 'Conexión';

  @override
  String get networkSignal => 'Señal';

  @override
  String get networkLinkSpeed => 'Velocidad de enlace Wi-Fi';

  @override
  String get networkTrafficRate =>
      'Tráfico del dispositivo · recepción / envío';

  @override
  String get networkSystemSettings => 'Ajustes de red del sistema';

  @override
  String get networkUnavailable => 'No disponible';

  @override
  String get networkMobile => 'Red móvil';

  @override
  String get networkFrequency => 'Frecuencia';

  @override
  String get networkMbps => 'Mbps';

  @override
  String get networkKbps => 'KB/s';

  @override
  String get networkReadFailed => 'No se pudo leer el estado de la red';

  @override
  String get clockItalic => 'Cursiva';

  @override
  String get panelWrapNavigation => 'Navegación circular del panel';

  @override
  String get panelWrapNavigationHelp =>
      'Las flechas pasan del extremo al lado opuesto. Mantenga pulsada una flecha para seguir recorriendo ambos lados.';

  @override
  String get networkReceive => 'Recepción';

  @override
  String get networkSend => 'Envío';

  @override
  String get landscapeCelestialBodies => 'Sol y luna';

  @override
  String get landscapeStarRotation => 'Rotación de las estrellas';

  @override
  String get tvPowerTitle => 'Gestión de energía';

  @override
  String get tvPowerOff => 'Apagar TV';

  @override
  String get tvPowerReboot => 'Reiniciar TV';

  @override
  String get tvPowerOffConfirm => '¿Poner el TV en espera?';

  @override
  String get tvPowerRebootConfirm =>
      '¿Reiniciar el TV? Se cerrarán las apps abiertas.';

  @override
  String get tvPowerSent => 'Comando enviado';

  @override
  String get tvPowerFailed =>
      'No se pudo enviar. Comprueba ADB o accesibilidad.';

  @override
  String get tvPowerHelp =>
      'Apagar activa la espera mediante accesibilidad de CuteLauncher o ADB local. Reiniciar requiere ADB. En un TV box se controla el box; el TV depende de HDMI-CEC y del firmware.';

  @override
  String get cleanerLists => 'Listas de desactivación';

  @override
  String get cleanerRecovery => 'Copia y restauración';

  @override
  String get cleanerExports => 'Informes';

  @override
  String get cleanerUpdating => 'Actualizando la lista de aplicaciones…';

  @override
  String get cleanerRefreshRequired =>
      'Actualiza primero la lista de aplicaciones.';

  @override
  String get cleanerPreinstalled => 'Aplicación preinstalada';

  @override
  String get cleanerNotSystem => 'No es una aplicación del sistema.';

  @override
  String get cleanerMinimalRisk => 'Mínimo';

  @override
  String get cleanerCacheFailure =>
      'No se pudo guardar la lista para la próxima visita.';

  @override
  String get cleanerUserApps => 'Aplicaciones del usuario';

  @override
  String get cleanerPreinstalledApps => 'Aplicaciones preinstaladas';

  @override
  String get cleanerSystemApps => 'Aplicaciones del sistema';

  @override
  String get cleanerBaseline => 'Estado original base';

  @override
  String get cleanerManualStates => 'Gestionar estados manuales';

  @override
  String get cleanerManualSave => 'Guardar estado actual';

  @override
  String get cleanerDateName => 'Usar fecha y hora';

  @override
  String get cleanerCustomName => 'Introducir un nombre';

  @override
  String get cleanerStateExport => 'Exportar estado guardado a un archivo';

  @override
  String get cleanerStateRestoreHelp =>
      'Se restaurarán los estados de activación guardados para este firmware. Las apps instaladas después no cambiarán. Se omitirán las apps ausentes y la desactivación de componentes protegidos. No se restauran datos de las apps.';

  @override
  String get cleanerCopiesHelp =>
      'El estado base se crea una sola vez al actualizar la lista correctamente por primera vez. El lanzador no permite borrarlo ni sobrescribirlo y está ligado al firmware. Los estados manuales guardan los modos de las apps con nombre y fecha; pueden restaurarse, eliminarse y exportarse. No incluyen APK ni datos. La restauración requiere ADB local. La protección ante fallos intenta restaurar automáticamente el estado base. Borrar los datos o desinstalar el lanzador elimina las copias; no se puede impedir el acceso root.';

  @override
  String get cleanerSearch => 'Buscar por nombre';

  @override
  String get cleanerCatalogUpdateRequired =>
      'Actualiza primero el catálogo desde GitHub.';

  @override
  String get cleanerNoSearchResults => 'No hay entradas coincidentes.';

  @override
  String get cleanerAlreadyDisabled =>
      'Todas las apps de esta lista presentes en el TV ya están desactivadas.';

  @override
  String get cleanerAlreadyEnabled =>
      'Todas las apps de esta lista presentes en el TV ya están activadas.';

  @override
  String get cleanerNoInstalled =>
      'No hay apps coincidentes de esta lista instaladas en este TV.';

  @override
  String get cleanerListProtected =>
      'Las apps restantes están protegidas contra la desactivación.';

  @override
  String get cleanerSnapshotFailed =>
      'No se pudo guardar la copia. No se desactivó ninguna app.';

  @override
  String get cleanerDisableAllPreinstalled =>
      'Desactivar todas las apps preinstaladas';

  @override
  String get cleanerEnableAllPreinstalled =>
      'Activar todas las apps preinstaladas';

  @override
  String get cleanerPreinstalledList => 'Lista de apps preinstaladas';

  @override
  String cleanerBeforeList(String listName) {
    return 'Antes de aplicar la lista: $listName';
  }

  @override
  String get sleepTimerSettings => 'Ajustes del temporizador de apagado';

  @override
  String get sleepTimerPresets => 'Temporizadores';

  @override
  String get sleepTimerDisplay => 'Mostrar con el temporizador activo';

  @override
  String get sleepTimerRemaining => 'Tiempo restante';

  @override
  String get sleepTimerEndTime => 'Hora de apagado';

  @override
  String get sleepTimerBoth => 'Tiempo restante y hora de apagado';

  @override
  String get sleepTimerShowSeconds => 'Mostrar segundos';

  @override
  String get sleepTimerCloseAfterSelection =>
      'Cerrar el widget al elegir un temporizador';

  @override
  String get sleepTimerAdd => 'Añadir temporizador';

  @override
  String get sleepTimerEdit => 'Editar temporizador';

  @override
  String get sleepTimerHoursLabel => 'Horas';

  @override
  String get sleepTimerMinutesLabel => 'Minutos';

  @override
  String get sleepTimerSecondsLabel => 'Segundos';

  @override
  String get sleepTimerInvalidDuration =>
      'Introduce una duración positiva: horas 0–999999, minutos y segundos 0–59.';

  @override
  String get sleepTimerDeleteConfirmation =>
      '¿Eliminar este temporizador? La cuenta atrás activa continuará.';

  @override
  String get sleepTimerResetConfirmation =>
      '¿Restaurar los temporizadores y su orden predeterminado? Se eliminarán los personalizados. La cuenta atrás activa continuará.';

  @override
  String get sleepTimerReorderHint =>
      '◄ / ► o mantener OK para mover. ▲ / ▼ cambian el orden y mueven temporizadores entre visibles y ocultos. OK termina el movimiento.';

  @override
  String get sleepTimerSaveFailed =>
      'No se pudieron guardar los ajustes del temporizador.';

  @override
  String get sleepTimerVisible => 'Visibles';

  @override
  String get sleepTimerHidden => 'Ocultos';

  @override
  String get sleepTimerReset => 'Restablecer temporizadores';

  @override
  String get cleanerListSnapshotHelp =>
      'Antes de desactivar una lista se guardan solo las apps seleccionadas. Restaurarlas no cambia otras apps. El límite es de 100 estados manuales y automáticos. Si falla el guardado, no se inicia la desactivación.';

  @override
  String get trafficSettings => 'Ajustes de tráfico';

  @override
  String get trafficTitle => 'Tráfico';

  @override
  String get trafficReceived => 'Recibido';

  @override
  String get trafficSent => 'Enviado';

  @override
  String get trafficTotal => 'Total';

  @override
  String get stopApp => 'Parar';

  @override
  String get backgroundImageFormats =>
      'Imágenes: JPEG, PNG, WebP, GIF, BMP — hasta 8 MiB, 48 megapíxeles y 16.384 píxeles por lado.';

  @override
  String get backgroundMediaFormats =>
      'Imágenes: JPEG, PNG, WebP, GIF, BMP — hasta 8 MiB, 48 megapíxeles y 16.384 píxeles por lado.\nVídeo: MP4/M4V, WebM, MKV — hasta 256 MiB y 3840×2160. Los códecs dependen del TV; se recomienda MP4 con H.264. Se repite sin sonido y se pausa fuera de Inicio. No se incluye en las copias de seguridad.';

  @override
  String get backgroundFormatError =>
      'Formato no compatible o archivo dañado. Elija un archivo válido de los formatos indicados.';

  @override
  String backgroundFileTooLarge(String maxMiB) {
    return 'El archivo es demasiado grande. Máximo: $maxMiB MiB. Elija uno más pequeño.';
  }

  @override
  String get backgroundImageResolutionError =>
      'Imagen demasiado grande: hasta 48 megapíxeles y 16.384 píxeles por lado.';

  @override
  String get backgroundVideoResolutionError =>
      'Resolución de vídeo demasiado alta. Elija hasta 3840×2160 (o 2160×3840).';

  @override
  String get backgroundVideoCodecError =>
      'El TV no pudo reproducir el vídeo: códec no compatible o archivo dañado. Pruebe MP4 con H.264.';

  @override
  String get backgroundFileApplied =>
      'Archivo seleccionado. Fondo actualizado.';

  @override
  String get noticePosition => 'Posición de las notificaciones';

  @override
  String get noticeBottomRight => 'Abajo a la derecha';

  @override
  String get noticeBottomLeft => 'Abajo a la izquierda';

  @override
  String get noticeTopRight => 'Arriba a la derecha';

  @override
  String get noticeTopLeft => 'Arriba a la izquierda';

  @override
  String get notificationOpenFailed =>
      'No se pudo abrir la acción de la notificación. Puede que ya no esté disponible.';

  @override
  String get adbWifiOverride => 'Desactivar de todos modos…';

  @override
  String get adbWifiRiskTitle => '¿Desactivar a pesar del riesgo?';

  @override
  String get adbWifiRiskEffect =>
      'Se desactivarán el lanzador integrado y el asistente de configuración de Google.';

  @override
  String get adbWifiRiskLoss =>
      'Android puede eliminar las redes Wi-Fi guardadas. La conexión Wi-Fi y ADB inalámbrico podrían dejar de estar disponibles.';

  @override
  String get adbWifiRiskRecovery =>
      'Volver a activar el asistente no restaurará automáticamente las redes eliminadas. Tendrá que conectarse de nuevo e introducir la contraseña.';

  @override
  String get adbWifiRiskConsent =>
      'Continúe solo si conoce la contraseña del Wi-Fi.';

  @override
  String get adbWifiDisable => 'Desactivar';

  @override
  String get recentAppsTitle => 'Aplicaciones abiertas';

  @override
  String get recentAppsPanelType => 'Panel';

  @override
  String get recentAppsAutomatic => 'Automático';

  @override
  String get recentAppsCustom => 'Panel de CuteLauncher';

  @override
  String get recentAppsSystem => 'Panel integrado';

  @override
  String get recentAppsOpen => 'Abrir panel';

  @override
  String get recentAppsRefresh => 'Actualizar';

  @override
  String get recentAppsCloseAll => 'Cerrar todas';

  @override
  String get recentAppsEmpty => 'No hay aplicaciones de TV con tareas abiertas';

  @override
  String get recentAppsUnavailable =>
      'Las aplicaciones abiertas no están disponibles. Comprueba ADB y el acceso de accesibilidad.';

  @override
  String get recentAppsHelp =>
      'Solo se muestran aplicaciones de TV con tareas abiertas. «Cerrar todas» detiene las aplicaciones de usuario de esta lista. Asigna un botón en el reasignador. El panel de CuteLauncher requiere ADB y accesibilidad.';

  @override
  String get recentAppsHomeHint =>
      'Home solo admite pulsación larga. Una pulsación corta vuelve a CuteLauncher. La asignación también funciona fuera del lanzador.';

  @override
  String get sectionRulesHelp =>
      'Las secciones estándar se pueden renombrar, mover u ocultar, pero no eliminar; al menos una debe seguir visible. Las listas Todas, Para TV y No para TV se llenan según el tipo de inicio, no el nombre; Ocultar quita la aplicación de las tres. Favoritos y las secciones propias se llenan manualmente. Orden: manual, nombre, frecuencia o último inicio; apariencia por sección. Seguir viendo muestra recomendaciones y se puede ocultar o mover.';

  @override
  String get remoteMappingNamePlaceholder => 'Nombre del botón';

  @override
  String get remoteMappingAssign => 'Asignar botón';

  @override
  String get remoteMappingCapture => 'Capturar';

  @override
  String remoteMappingCaptured(String key) {
    return 'Botón capturado: $key';
  }

  @override
  String get remoteMappingCaptureHint =>
      'Pulsa Capturar y después el botón del mando. Puedes repetir. Pulsa OK para aceptar.';

  @override
  String get remoteMappingCaptureTimeout =>
      'No se capturó un botón. Reinténtalo.';

  @override
  String get remoteMappingCaptureFailed =>
      'No se pudo capturar. Comprueba el servicio de accesibilidad.';

  @override
  String get remoteMappingServiceRequired =>
      'Conecta el servicio de accesibilidad en los ajustes de acceso.';

  @override
  String get remoteMappingKeyRequired =>
      'No hay botón asignado. Pulsa Asignar botón y captura uno.';

  @override
  String get remoteMappingHomeHoldRequired =>
      'Selecciona Pulsación larga para Home.';

  @override
  String get remoteMappingAppRequired =>
      'Selecciona una aplicación para abrir.';

  @override
  String get remoteMappingUrlRequired =>
      'Introduce o importa una URL de webhook.';

  @override
  String get remoteMappingUrlInvalid =>
      'URL no válida. Usa HTTPS o HTTP local con ruta, sin espacios, credenciales ni fragmento #.';

  @override
  String get remoteMappingSaveFailed =>
      'No se pudo guardar. Reinténtalo; se conservan los valores.';

  @override
  String get remoteMappingDeleteFailed => 'No se pudo eliminar. Reinténtalo.';

  @override
  String get remoteMappingRecents => 'Panel de aplicaciones abiertas';

  @override
  String get remoteMappingImport => 'Importar URL desde archivo';

  @override
  String get remoteMappingImportHint =>
      'Elige un archivo UTF-8 con solo la URL de webhook, sin comandos ni explicaciones. Se eliminan los saltos de línea.';

  @override
  String get remoteMappingImportInvalid =>
      'El archivo debe contener solo una URL de webhook válida: HTTPS o HTTP local, sin comandos ni explicaciones.';

  @override
  String get remoteMappingImportFailed =>
      'No se pudo leer. Elige un archivo UTF-8 accesible de hasta 64 KB.';
}
