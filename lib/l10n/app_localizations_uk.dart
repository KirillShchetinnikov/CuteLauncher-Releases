// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

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
  String get adbWifiOwnedTitle => 'Wi-Fi належить майстру налаштування';

  @override
  String get adbWifiOwned =>
      'Зміни не внесено: збережену мережу Wi-Fi створив майстер налаштування Google. Його вимкнення може видалити мережу та від’єднати телевізор від інтернету.\n\n1. Переконайтеся, що знаєте пароль Wi-Fi.\n2. Відкрийте налаштування мережі Android, виберіть мережу й натисніть «Забути мережу».\n3. Підключіться знову через звичайні налаштування мережі Android.\n4. Поверніться до CuteLauncher, перевірте ADB і повторіть вимкнення вбудованого лаунчера.\n\nЯкщо повідомлення з’явиться знову, залиште вбудований лаунчер увімкненим: прошивка може знову призначати мережу майстру.';

  @override
  String get adbWifiUnknown =>
      'Not changed: the owners of saved Wi-Fi networks could not be verified. Disabling the setup wizard is blocked to protect your connection. Check ADB and try again; some firmware does not provide this information.';

  @override
  String get backgroundSource => 'Джерело фону';

  @override
  String get noAvailableCategories =>
      'Немає розділів, до яких можна додати цю програму.';

  @override
  String get redditWallpaperTheme => 'Тема шпалер';

  @override
  String get redditThemeAll => 'змішаний';

  @override
  String get redditThemeNature => 'природа';

  @override
  String get redditThemeSpace => 'космос';

  @override
  String get redditThemeCity => 'Міста';

  @override
  String get redditThemeMinimal => 'Мінімалізм';

  @override
  String get redditWallpaperResolution => 'Мінімальна роздільна здатність';

  @override
  String get redditWallpaperHint =>
      'Кожне успішне оновлення завантажує інше альбомне зображення з вибраної спільноти Reddit. Роздільна здатність — мінімальний розмір оригіналу; зображення не масштабуються. Оновлення запускається, коли панель запуску відкрито, і відновлюється, коли ви повертаєтесь. Вміст для дорослих, відео та галереї пропускаються. Якщо Reddit блокує доступ або відповідне зображення не знайдено, попередні шпалери залишаються.';

  @override
  String get dialogCommandDetails => 'Показати команди ADB';

  @override
  String get dialogAssign => 'Призначити';

  @override
  String get dialogApply => 'Застосувати';

  @override
  String get settingsValueNotSet => 'Не встановлено';

  @override
  String get settingsMenuPosition => 'Позиція меню налаштувань';

  @override
  String get settingsMenuLeft => 'Ліворуч';

  @override
  String get settingsMenuRight => 'правильно';

  @override
  String get actionCompleted => 'Дія завершена';

  @override
  String get showRepositoryQrCode => 'Показати QR-код';

  @override
  String get resetSections => 'Скинути налаштування розділу';

  @override
  String get resetSectionsConfirmation =>
      'Відновити розділи за замовчуванням? Користувацькі розділи, розділи та вміст вибраного буде видалено.';

  @override
  String get cardFocusMode => 'Зосередьтеся на поверненні додому';

  @override
  String get cardFocusRemember => 'Зберегти вибрану картку';

  @override
  String get cardFocusFirst => 'Перша карта';

  @override
  String get cardFocusSettings => 'Кнопка налаштувань';

  @override
  String get aboutFlauncher => 'Про CuteLauncher';

  @override
  String get addCategory => 'Додати категорію';

  @override
  String get addSection => 'Додати розділ';

  @override
  String get alphabetical => 'За алфавітом';

  @override
  String get appCardHighlightAnimation =>
      'Анімація виділення картки застосунку';

  @override
  String get appInfo => 'Інформація про застосунок';

  @override
  String get appKeyClick => 'Звук клацання при натисканні клавіші';

  @override
  String get applications => 'Застосунки';

  @override
  String get autoHideAppBar => 'Автоматично приховувати рядок стану';

  @override
  String get backButtonAction => 'Дія кнопки «Назад»';

  @override
  String get category => 'Категорія';

  @override
  String get categories => 'Категорії';

  @override
  String get columnCount => 'Кількість стовпців';

  @override
  String get date => 'Дата';

  @override
  String get dateAndTimeFormat => 'Формат дати й часу';

  @override
  String get delete => 'Видалити';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'Нічого не робити';

  @override
  String get dialogOptionBackButtonActionShowScreensaver => 'Показати заставку';

  @override
  String get dialogOptionBackButtonActionShowClock => 'Показати годинник';

  @override
  String get dialogTextNoFileExplorer =>
      'Будь ласка, встановіть файловий менеджер, щоб вибрати зображення.';

  @override
  String get dialogTitleBackButtonAction => 'Виберіть дію кнопки «Назад»';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (Категорія)';
  }

  @override
  String formattedDate(String dateString) {
    return 'Формат дати: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'Формат часу: $timeString';
  }

  @override
  String get gradient => 'Градієнт';

  @override
  String get favoriteApps => 'Улюблені застосунки';

  @override
  String get grid => 'Сітка';

  @override
  String get height => 'Висота';

  @override
  String get hide => 'Приховати';

  @override
  String get hiddenApplications => 'Приховані застосунки';

  @override
  String get launcherSections => 'Розділи';

  @override
  String get layout => 'Розташування';

  @override
  String get loading => 'Завантаження';

  @override
  String get manual => 'Вручну';

  @override
  String get modifySection => 'Змінити розділ';

  @override
  String get mustNotBeEmpty => 'Не повинно бути порожнім';

  @override
  String get name => 'Назва';

  @override
  String get newSection => 'Новий розділ';

  @override
  String get noDateFormatSpecified => 'Формат дати не вказано';

  @override
  String get noTimeFormatSpecified => 'Формат часу не вказано';

  @override
  String get nonTvApplications => 'Застосунки не для ТБ';

  @override
  String get open => 'Відкрити';

  @override
  String get orSelectFormatSpecifiers => 'Або виберіть специфікатори формату';

  @override
  String get openImage => 'Вибрати файл';

  @override
  String get picture => 'Локальне зображення або відео';

  @override
  String removeFrom(String name) {
    return 'Видалити з $name';
  }

  @override
  String get renameCategory => 'Перейменувати категорію';

  @override
  String get reorder => 'Змінити порядок';

  @override
  String get row => 'Рядок';

  @override
  String get rowHeight => 'Висота рядка';

  @override
  String get save => 'Зберегти';

  @override
  String get spacer => 'Роздільник';

  @override
  String get spacerMaxHeightRequirement => 'Має бути більше 0 і не більше 500';

  @override
  String get statusBar => 'Рядок стану';

  @override
  String get settings => 'Налаштування';

  @override
  String get show => 'Показати';

  @override
  String get showCategoryTitles => 'Показувати назви категорій';

  @override
  String get themes => 'Теми';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'Приховати контур виділення на головному екрані';

  @override
  String get appSelectorTransitionAnimation =>
      'Анімація переходу вибору застосунку';

  @override
  String get sort => 'Сортування';

  @override
  String get systemSettings => 'Системні налаштування';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => 'Ця категорія порожня.';

  @override
  String get time => 'Час';

  @override
  String get titleStatusBarSettingsPage =>
      'Виберіть, що відображати в рядку стану';

  @override
  String get tvApplications => 'Застосунки для ТБ';

  @override
  String get type => 'Тип';

  @override
  String get typeInTheDateFormat => 'Введіть формат дати';

  @override
  String get typeInTheHourFormat => 'Введіть формат часу';

  @override
  String get uninstall => 'Видалити';

  @override
  String get wallpaper => 'Шпалери';

  @override
  String get withEllipsisAddTo => 'Додати до...';

  @override
  String get timeBasedWallpaper => 'Денне/Нічне зображення';

  @override
  String get pickDayWallpaper => 'Вибрати денне зображення';

  @override
  String get pickNightWallpaper => 'Вибрати нічне зображення';

  @override
  String get accessibility => 'Спеціальні можливості';

  @override
  String get defaultLauncherIsDefault =>
      'CuteLauncher є лаунчером за замовчуванням';

  @override
  String get defaultLauncherNotDefault =>
      'CuteLauncher не є лаунчером за замовчуванням';

  @override
  String get setAsDefaultLauncher => 'Встановити як лаунчер за замовчуванням';

  @override
  String get defaultLauncherDescription =>
      'Якщо встановлено як лаунчер за замовчуванням, кнопка «Домівка» завжди повертатиме до CuteLauncher. Телевізор також завантажуватиметься одразу в CuteLauncher.';

  @override
  String get inputs => 'Джерела сигналу';

  @override
  String get inputsUnavailableHint =>
      'Цей пристрій не надає доступних входів. Перемикач вимкнено, а значок приховано. На телеприставці ця опція не керує входами HDMI підключеного телевізора.';

  @override
  String get inputSources => 'Джерела сигналу';

  @override
  String get backupAndRestore => 'Резервне копіювання та відновлення';

  @override
  String get exportBackup => 'Експортувати резервну копію';

  @override
  String get importBackup => 'Імпортувати резервну копію';

  @override
  String exportSuccess(String path) {
    return 'Резервну копію успішно експортовано до $path';
  }

  @override
  String get importSuccess => 'Резервну копію успішно імпортовано';

  @override
  String get importConfirm =>
      'Ви впевнені, що хочете імпортувати резервну копію? Це замінить поточні налаштування та розташування.';

  @override
  String get importError =>
      'Не вдалося відновити налаштування з резервної копії. Перевірте файл і повторіть спробу.';

  @override
  String exportError(String error) {
    return 'Не вдалося експортувати резервну копію: $error';
  }

  @override
  String get shareBackup => 'Поділитися резервною копією';

  @override
  String get shareBackupDescription =>
      'Поділитися резервною копією з іншими пристроями в локальній мережі';

  @override
  String get stopSharing => 'Зупинити спільний доступ';

  @override
  String get localNetworkSharingActive =>
      'Спільний доступ у локальній мережі активний!';

  @override
  String get localNetworkSharingInstructions =>
      'Підключіть інший пристрій до тієї самої мережі Wi-Fi та відкрийте таку адресу у веббраузері:';

  @override
  String get localNetworkSharingDetails =>
      'Тут ви можете завантажити налаштування/розташування вашого ТБ або вивантажити файл резервної копії назад на цей телевізор.';

  @override
  String failedToStartServer(String error) {
    return 'Не вдалося запустити сервер спільного доступу: $error';
  }

  @override
  String get notificationBell => 'Дзвіночок сповіщень';

  @override
  String get autoHideNotificationBell =>
      'Автоматично приховувати дзвіночок сповіщень';

  @override
  String get continueWatching => 'Продовжити перегляд';

  @override
  String get showContinueWatchingOnHome =>
      'Показувати «Продовжити перегляд» на головному екрані';

  @override
  String get permissionDeniedContinueWatching =>
      'Потрібен дозвіл для показу «Продовжити перегляд»';

  @override
  String get interface => 'Інтерфейс';

  @override
  String get system => 'Система';

  @override
  String get accentColor => 'Акцентний колір';

  @override
  String get miscellaneous => 'Інше';

  @override
  String get brightnessScheduler => 'Розклад яскравості';

  @override
  String get screensaverSettings => 'Налаштування заставки';

  @override
  String get screensaverClockStyle => 'Стиль годинника заставки';

  @override
  String get dataUsagePeriod => 'Період використання даних';

  @override
  String get notificationAccess => 'Доступ до сповіщень';

  @override
  String get granted => 'Надано';

  @override
  String get permissionRequired => 'Потрібен дозвіл';

  @override
  String get systemWidePopupAlert => 'Спливне сповіщення в системі';

  @override
  String get overlayPermissionRequired => 'Потрібен дозвіл на накладання';

  @override
  String get enabled => 'Увімкнено';

  @override
  String get disabled => 'Вимкнено';

  @override
  String get showAppNamesBelowIcons =>
      'Показувати назви застосунків під іконками';

  @override
  String get dataUsage => 'Використання даних';

  @override
  String get networkIndicator => 'Індикатор мережі';

  @override
  String get homeButtonFix => 'Виправлення кнопки «Домівка» (Google TV)';

  @override
  String get startOnBoot =>
      'Запускати після завантаження (Google TV / Fire TV)';

  @override
  String get appLanguage => 'Мова';

  @override
  String get systemDefault => 'Системна мова за замовчуванням';

  @override
  String get english => 'Англійська';

  @override
  String get spanish => 'Іспанська';

  @override
  String get ukrainian => 'Українська';

  @override
  String get chinese => 'Китайська';

  @override
  String get french => 'Французька';

  @override
  String get german => 'Німецька';

  @override
  String get japanese => 'Японська';

  @override
  String get portuguese => 'Португальська';

  @override
  String get russian => 'Російська';

  @override
  String get italian => 'Італійська';

  @override
  String get hindi => 'Гінді';

  @override
  String get korean => 'Корейська';

  @override
  String get arabic => 'Арабська';

  @override
  String get turkish => 'Турецька';

  @override
  String get hidePersistentNotifications => 'Приховати постійні сповіщення';

  @override
  String get hidePersistentNotificationsDesc =>
      'Приховувати фонові та системні сповіщення';

  @override
  String get blockedNotificationApps => 'Заблоковані додатки';

  @override
  String get blockAppNotifications => 'Блокувати сповіщення';

  @override
  String get unblockAppNotifications => 'Розблокувати сповіщення';

  @override
  String get noBlockedApps => 'Немає заблокованих додатків';

  @override
  String get persistentNotification => 'Постійне';

  @override
  String get unblockAll => 'Розблокувати все';

  @override
  String get weather => 'Погода';

  @override
  String get showWeatherWarnings => 'Показувати сповіщення про погоду та дощ';

  @override
  String get temperatureUnit => 'Одиниця температури';

  @override
  String get celsius => 'Цельсій (°C)';

  @override
  String get fahrenheit => 'Фаренгейт (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Встановіть Breezy Weather та увімкніть \'Локальний обмін даними\' / \'Gadgetbridge\' у налаштуваннях для перегляду погоди та попереджень про дощ.';

  @override
  String get displayAndScreensaver => 'Екран та заставка';

  @override
  String get notifications => 'Сповіщення';

  @override
  String get continueWatchingDescription =>
      'Показувати нещодавно переглянуті фільми та серіали на головному екрані';

  @override
  String get continueWatchingPermissionDesc =>
      'Для читання історії перегляду з ТВ-додатків потрібен спеціальний дозвіл:';

  @override
  String get requestPermission => 'Запитати дозвіл';

  @override
  String get dismiss => 'Закрити';

  @override
  String get openApp => 'Відкрити';

  @override
  String get notificationOptions => 'Параметри сповіщення';

  @override
  String get noBlockedAppsDesc =>
      'Усім програмам наразі дозволено показувати сповіщення';

  @override
  String get notificationsAllowed => 'Сповіщення дозволено';

  @override
  String get notificationsBlocked => 'Сповіщення заблоковано';

  @override
  String get dpadDismissHint => 'Вліво: Закрити • OK: Параметри';

  @override
  String get watchNextDeleteError =>
      'Не вдалося видалити елемент із продовження перегляду. Спробуйте знову.';

  @override
  String get hideLauncherTile => 'Сховати CuteLauncher у сітці програми';

  @override
  String get hideAndroidSettingsTile =>
      'Сховати налаштування Android на панелях програми';

  @override
  String get animateTileReordering => 'Зміна порядку анімованих плиток';

  @override
  String get imageInputRejected =>
      'Це зображення пошкоджене або завелике (максимум 8 MiB і 48 мегапікселів). Виберіть інше зображення.';

  @override
  String get memoryTitle => 'Пам\'ять';

  @override
  String get memoryRefresh => 'Виміряти пам\'ять';

  @override
  String get memoryMeasuring => 'Вимірювання…';

  @override
  String get memoryClear => 'Очистити кеш зображень';

  @override
  String get memorySaver => 'Збереження пам\'яті';

  @override
  String get memorySaverDescription =>
      'Режим збереження пам\'яті:\n\n• Зменшує кеш зображень і вікно попереднього завантаження плакатів.\n• Вимикає розмиття фону плитки, панелі та шпалери та пульсування контуру.\n• Обмежує тіні на несфокусованих плитках.\n• Очищає кеш, коли програма переходить у фоновий режим.\n\nЦі ефекти недоступні в налаштуваннях, якщо ввімкнено збереження пам’яті. Їх збережені значення повертаються, коли режим вимкнено. Зображення можуть перезавантажуватися частіше.';

  @override
  String get memoryPss => 'Частка процесу (PSS)';

  @override
  String get memoryRss => 'Резидентна пам\'ять процесу (RSS)';

  @override
  String get memoryEncodedCache => 'Кешовані файли зображень';

  @override
  String get memoryDecodedCache => 'Кешовані декодовані зображення';

  @override
  String get memoryUnavailable => 'Недоступний';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => 'Вимірюється в';

  @override
  String get memoryExplanation =>
      'PSS і RSS перекриваються: не додавайте їх разом. Розміри кешу є частиною пам’яті програми і не описують всю пам’ять, яку зберігають активні зображення. Очищення кешу зберігає ваші налаштування та файли; зображення завантажуються знову, коли це необхідно. Android може повернути пам\'ять пізніше. RSS тут походить від ядра, а PSS — від Android; вони можуть по-різному враховувати графічну пам\'ять.';

  @override
  String get memoryRecommendations =>
      'Щоб зменшити обсяг пам’яті, увімкніть збереження, показуйте менше карток Продовжити перегляд і використовуйте менші шпалери або градієнт.';

  @override
  String get memoryMeasurementFailed =>
      'Вимірювання процесу недоступне. Інформація про кеш все ще відображається.';

  @override
  String get addToCategory => 'Додати до категорії';

  @override
  String get addToFavorites => 'Додати до вибраного';

  @override
  String get removeFromFavorites => 'Видалити з улюбленого';

  @override
  String get setCustomBanner => 'Встановити спеціальний банер';

  @override
  String get clearCustomBanner => 'Очистити спеціальний банер';

  @override
  String get bannerSetFailed =>
      'Не вдалося встановити банер. Перевірте доступ до зображення та знову виберіть файл.';

  @override
  String get bannerClearFailed =>
      'Не вдалося видалити спеціальний банер. Спробуйте знову.';

  @override
  String get grantUsagePermission => 'Надати дозвіл на використання';

  @override
  String get removeFromContinueWatching => 'Вилучити з Продовжити перегляд';

  @override
  String hideAllFromApp(String appName) {
    return 'Приховати все від $appName';
  }

  @override
  String get playResume => 'Відтворити / Відновити';

  @override
  String openNamedApp(String appName) {
    return 'Відкрийте $appName';
  }

  @override
  String get selectedAccent => 'Виділений акцент';

  @override
  String get homeButtonFixHint =>
      'Якщо ви користуєтеся Google TV, увімкніть «Виправлення кнопки «Додому»» в налаштуваннях спеціальних можливостей, щоб кнопка «Додому» відкривала цю панель запуску.';

  @override
  String get accessibilityPermission => 'Дозвіл доступності';

  @override
  String get shareFailed => 'Не вдалося поділитися';

  @override
  String shareBackupError(String error) {
    return 'Не вдалося поділитися резервною копією: $error';
  }

  @override
  String get exportComplete => 'Успіх експорту';

  @override
  String get exportFailed =>
      'Не вдалося зберегти резервну копію. Перевірте доступ до папки та доступне сховище.';

  @override
  String backupLoadError(String error) {
    return 'Помилка завантаження резервних копій: $error';
  }

  @override
  String get noBackupFiles => 'Резервні файли не знайдено.';

  @override
  String get importComplete => 'Успішний імпорт';

  @override
  String get importFailed => 'Помилка імпорту';

  @override
  String get importAction => 'Імпорт';

  @override
  String get continueWatchingApps => 'Продовжити перегляд програм';

  @override
  String get blockedContinueWatching => 'Заблоковано для продовження перегляду';

  @override
  String get allAppsCanContinueWatching =>
      'Усі підтримувані програми можуть показувати елементи в розділі «Продовжити перегляд».';

  @override
  String get unblockApp => 'Розблокувати';

  @override
  String get unblockAllApps => 'Розблокувати всі програми';

  @override
  String get appsWithContinueWatching => 'Програми з Продовжити перегляд';

  @override
  String get watchNextAppsHint =>
      'Програми, які наразі пропонують елементи Дивитися далі на головному екрані';

  @override
  String get noWatchNextApps =>
      'Наразі жодна програма не надає елементи «Продовжити перегляд».\nКоли підтримувані програми (наприклад, SmartTube або потокові служби) додають елементи, вони з’являться тут.';

  @override
  String get allInstalledApps => 'Усі встановлені програми';

  @override
  String get blockWatchNextHint =>
      'Вимкніть, щоб будь-яка програма не додавала елементи до продовження перегляду';

  @override
  String get cardSize => 'Розмір картки';

  @override
  String get maximumItems => 'Максимальна кількість предметів';

  @override
  String get playbackProgressBar => 'Індикатор прогресу відтворення';

  @override
  String get playbackPercentage => 'Відсоток відтворення';

  @override
  String get episodeVideoDetails => 'Деталі епізоду та відео';

  @override
  String get restoreHiddenPrograms => 'Відновлення прихованих програм';

  @override
  String get allHiddenProgramsRestored => 'Відновлено всі приховані програми';

  @override
  String get watchNextAccessAdb => 'Переглянути далі Доступ (потрібен ADB)';

  @override
  String get supportLtvLauncher => 'Підтримка LTvLauncher';

  @override
  String get scanToDonate =>
      'Скануйте за допомогою камери телефону, щоб пожертвувати:';

  @override
  String get openInBrowser => 'Відкрити в браузері';

  @override
  String get close => 'Закрити';

  @override
  String get launcherAuthor => 'CuteLauncher від Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Лаунчер Android TV на основі LTvLauncher від LeanBitLab і FLauncher від Étienne Fesser. Ліцензовано згідно з GNU GPLv3.';

  @override
  String get projectCredits => 'Проект і кредити';

  @override
  String get launcherRepository => 'Репозиторій CuteLauncher';

  @override
  String get originalProject => 'Оригінальний проект: LTvLauncher';

  @override
  String get noInputsDetected => 'Введення не виявлено';

  @override
  String get reorderSectionsHint =>
      'Виберіть за допомогою ◄ / ►, потім використовуйте ▲ / ▼, щоб змінити порядок. Перейдіть за межі списку, щоб приховати або показати розділ.';

  @override
  String get customName => 'Спеціальна назва';

  @override
  String get mostUsed => 'Частота запуску';

  @override
  String get lastUsed => 'Останнє використання';

  @override
  String get clearAll => 'Очистити все';

  @override
  String get allCaughtUp => 'Все наздогнали!';

  @override
  String get notificationAccessAdb => 'Доступ до сповіщень (потрібен ADB)';

  @override
  String get openAppInfo => 'Відкрийте інформацію про додаток';

  @override
  String get overlayPermission => 'Дозвіл на накладання';

  @override
  String get clockMinimal => 'Мінімальний';

  @override
  String get clockMinimalDescription =>
      'Тонкий елегантний шрифт (за замовчуванням)';

  @override
  String get clockBold => 'жирний';

  @override
  String get clockBoldDescription => 'Товстий, добре помітний шрифт';

  @override
  String get clockRetro => 'Ретро';

  @override
  String get clockRetroDescription => 'Моноширинний термінал у стилі ретро';

  @override
  String get clockElegant => 'Елегантний';

  @override
  String get clockElegantDescription => 'Класичний шрифт із засічками';

  @override
  String get clockNeon => 'Неон';

  @override
  String get clockNeonDescription => 'Ультратонкий, сяючий стиль';

  @override
  String get clockPixel => 'піксель';

  @override
  String get clockPixelDescription =>
      'Жирний моноширинне зображення, відчуття аркади';

  @override
  String get clockDigital => 'цифровий';

  @override
  String get clockDigitalDescription => 'Чистий моноширинний дисплей';

  @override
  String get themeDefault => 'За замовчуванням';

  @override
  String get themePremium => 'Преміум';

  @override
  String get themeClassic => 'класичний';

  @override
  String get themeCapsule => 'капсула';

  @override
  String get cancel => 'Скасувати';

  @override
  String get actionCancelled => 'Акція скасована';

  @override
  String get ok => 'добре';

  @override
  String get accessibilityGuide =>
      'Відкрийте налаштування телевізора вручну, потім Спеціальні можливості → CuteLauncher Виправити кнопку Home і ввімкніть службу. Розташування та назва цього меню залежать від виробника телевізора.';

  @override
  String get notificationPermissionGuide =>
      'Не вдалося відкрити налаштування доступу до сповіщень на цьому телевізорі. Якщо дозволити вихідні сповіщення в App Info, це не надасть доступ до сповіщень з інших програм.\n\nПідключіть телевізор через ADB і запустіть:';

  @override
  String get overlayPermissionGuide =>
      'Налаштування дозволу на накладання не вдалося відкрити автоматично.\n\nЩоб увімкнути спливаючі вікна над іншими програмами, підключіть телевізор через ADB і запустіть:';

  @override
  String get watchNextPermissionGuide =>
      'Щоб читати картки Continue Watching з інших програм, Android TV вимагає READ_WRITE_WATCH_NEXT_PROGRAMS.\n\nПідключіть телевізор через ADB і запустіть:';

  @override
  String get watchNextAccess => 'Продовжити перегляд доступу';

  @override
  String itemsCount(int count) {
    return '$count елементи';
  }

  @override
  String displayUpToItems(int count) {
    return 'Показати до $count нещодавні елементи';
  }

  @override
  String get unlimitedItems => 'Необмежений';

  @override
  String get allAvailableItems => 'Показати всі доступні елементи';

  @override
  String get defaultOption => 'За замовчуванням';

  @override
  String get manage => 'Керувати';

  @override
  String blockedCount(int count) {
    return '$count заблоковано';
  }

  @override
  String hiddenCount(int count) {
    return '$count приховано';
  }

  @override
  String blockedWatchNextCount(int count) {
    return 'Заблоковано для продовження перегляду ($count)';
  }

  @override
  String get sizeExtraSmall => 'Дуже малий';

  @override
  String get sizeVerySmall => 'Дуже маленький';

  @override
  String get sizeSmall => 'Маленький';

  @override
  String get sizeCompact => 'Компактний';

  @override
  String get sizeMediumSmall => 'Середній Малий';

  @override
  String get sizeMedium => 'Середній';

  @override
  String get sizeStandardDefault => 'Стандартний (за замовчуванням)';

  @override
  String get sizeMediumLarge => 'Середній Великий';

  @override
  String get sizeLarge => 'великий';

  @override
  String get sizeVeryLarge => 'Дуже великий';

  @override
  String get sizeExtraLarge => 'Дуже великий';

  @override
  String get sizeHuge => 'Величезний';

  @override
  String get tvApps => 'ТБ програми';

  @override
  String get nonTvApps => 'Нетелевізійні програми';

  @override
  String get moviesShows => 'Фільми та шоу';

  @override
  String get music => 'музика';

  @override
  String get games => 'Ігри';

  @override
  String get entertainment => 'Розваги';

  @override
  String get liveTv => 'Пряме телебачення';

  @override
  String get sports => 'спорт';

  @override
  String get news => 'Новини';

  @override
  String get tools => 'Інструменти';

  @override
  String get favorites => 'Вибране';

  @override
  String get customSectionName => 'Спеціальний...';

  @override
  String get selectSectionName => 'Виберіть назву';

  @override
  String get weeklyUsage => 'Щотижня:';

  @override
  String get monthlyUsage => 'Щомісяця:';

  @override
  String get dailyUsage => 'щоденно:';

  @override
  String get appError => 'Щось пішло не так';

  @override
  String get weatherRain => 'Дощ';

  @override
  String get weatherSnow => 'сніг';

  @override
  String get weatherStorm => 'Буря';

  @override
  String get weatherToday => 'сьогодні';

  @override
  String get weatherTomorrow => 'завтра';

  @override
  String weatherOnDay(String day) {
    return 'на $day';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'Резервне копіювання CuteLauncher';

  @override
  String get noApplicationsFound => 'Додатків не знайдено';

  @override
  String get invalidDateFormat => 'Недійсний формат';

  @override
  String get selectDateFormats => 'Виберіть формати нижче';

  @override
  String activeItemsCount(int count) {
    return '$count активний елемент(и)';
  }

  @override
  String get colorPurple => 'Фіолетовий';

  @override
  String get colorTeal => 'Чирок';

  @override
  String get colorBlue => 'Синій';

  @override
  String get colorOrange => 'Помаранчевий';

  @override
  String get colorPink => 'Рожевий';

  @override
  String get colorGreen => 'Зелений';

  @override
  String get colorWhite => 'Білий';

  @override
  String get colorYellow => 'Жовтий';

  @override
  String get colorRed => 'Червоний';

  @override
  String get colorCyan => 'Блакитний';

  @override
  String get colorIndigo => 'Індиго';

  @override
  String get colorLime => 'Вапно';

  @override
  String get colorAmber => 'Бурштин';

  @override
  String get colorRose => 'Роза';

  @override
  String get colorIceBlue => 'Ice Blue';

  @override
  String get memoryFeatures => 'Пам\'ять за функціями (кеші)';

  @override
  String get memoryAppIcons => 'Значки додатків';

  @override
  String get memoryAppBanners => 'Банери додатків';

  @override
  String get memoryWatchNextPosters => 'Продовжуйте перегляд плакатів';

  @override
  String get memoryOtherCaches => 'Інші кеші закодованих зображень';

  @override
  String get memoryFeaturesExplanation =>
      'Це збережені байти зображення, які вже включені до загального обсягу закодованого кешу. Нуль означає відсутність збережених байтів у цьому кеші, а не те, що функція не використовує пам’ять. Шпалери та відображені зображення мають спільний декодований кеш вище; активні зображення можуть бути поза ним. Тут неможливо розділити погоду, сповіщення, об’єкти Dart і механізм за функціями. Спільна графіка інтерфейсу описана вище в Android і вже включена в PSS. Їх пам\'ять є частиною всього процесу. Не додавайте ці значення, що збігаються.';

  @override
  String get memoryGraphics => 'Графіка інтерфейсу (включена в PSS)';

  @override
  String get categoryVisible => 'Показати категорію';

  @override
  String get hiddenCategories => 'Приховані категорії';

  @override
  String get visibleCategories => 'Видимі категорії';

  @override
  String get backupSavedToSelectedLocation =>
      'Резервну копію збережено у вибраному місці';

  @override
  String get tileHorizontalGap => 'Горизонтальний інтервал';

  @override
  String get tileVerticalGap => 'Вертикальний інтервал';

  @override
  String get tileOpacity => 'Непрозорість фону';

  @override
  String get tileShadow => 'Тінь';

  @override
  String get tileCornerRadius => 'Закруглення кутів';

  @override
  String get tileIconScale => 'Розмір значка';

  @override
  String get tileBackgroundColor => 'Плитка фону';

  @override
  String get tileLabelSize => 'Розмір етикетки';

  @override
  String get resetAppearance => 'Скинути зовнішній вигляд';

  @override
  String get tileAppearance => 'Зовнішній вигляд плитки';

  @override
  String get tileLabelColor => 'Колір етикетки';

  @override
  String get tilePreviewName => 'Зразок заяви';

  @override
  String get tileProportions => 'Пропорції плитки';

  @override
  String get tileLarge => 'великий';

  @override
  String get tileLabelBelow => 'Нижче плитки';

  @override
  String get tileLabelInside => 'Всередині плитки';

  @override
  String get tileFocusScale => 'Збільшити';

  @override
  String get tileMedium => 'Середній';

  @override
  String get tileFocusBorder => 'Жодного руху';

  @override
  String get tileSize => 'Розмір плитки';

  @override
  String get tileCompact => 'Компактний';

  @override
  String get tileLabelPosition => 'Положення мітки';

  @override
  String get tileFocusEffect => 'Ефект фокусування';

  @override
  String get tileFocusStrength => 'Інтенсивність виділення';

  @override
  String get panelIndependent => 'Спеціальні налаштування';

  @override
  String get panelAppearance => 'Стиль верхньої панелі';

  @override
  String get panelBackground => 'Фон панелі';

  @override
  String get blurPerformanceHint =>
      'Розмиття може зменшити гладкість. Він вимкнений, коли ввімкнено збереження пам’яті.';

  @override
  String get panelOpacity => 'Непрозорість панелі';

  @override
  String get tileBlur => 'Розмиття за плитками';

  @override
  String get panelBlur => 'Розмиття за верхньою панеллю';

  @override
  String get panelShared => 'Як панелі';

  @override
  String get weatherMinutes => 'хв';

  @override
  String get weatherOpenMeteoCredit =>
      'Погода: Open-Meteo (open-meteo.com), CC BY 4.0. Безкоштовний API для некомерційного використання.';

  @override
  String get weatherRateLimit => 'Ліміт запитів досягнуто. Спробуйте пізніше.';

  @override
  String get weatherYandexCredit =>
      'Погода: Яндекс Погода (yandex.ru/pogoda). Доступ залежить від вашого плану API.';

  @override
  String get yandexWeather => 'Яндекс Погода (REST)';

  @override
  String get weatherAuthorizationError =>
      'Провайдер погоди відхилив запит. Перевірте ключ API і доступ до вибраного сервісу.';

  @override
  String get weatherYandexHint =>
      'Потрібен ключ із доступом прогнозу REST. Ключ іншого плану Яндекс може не працювати.';

  @override
  String get weatherSource => 'Джерело погоди';

  @override
  String get weatherInterval => 'Інтервал оновлення';

  @override
  String get weatherLongitude => 'Довгота (від -180 до 180)';

  @override
  String get weatherKeyRequired => 'Додайте ключ Яндекс API.';

  @override
  String get weatherLocationName => 'Назва міста (необов\'язково)';

  @override
  String get weatherLocation => 'Розташування';

  @override
  String get weatherApiKey => 'Яндекс ключ API';

  @override
  String get weatherInvalidResponse =>
      'Джерело погоди повернуло недійсні дані.';

  @override
  String get weatherUnavailable =>
      'Погода недоступна. Раніше отримані дані зберігаються, якщо вони є. Повторні спроби обмежені разом на 5 хвилин.';

  @override
  String get weatherStale => 'Попередня погода';

  @override
  String get weatherLatitude => 'Широта (від -90 до 90)';

  @override
  String get weatherCoordinatesError =>
      'Введіть місто вручну або отримайте координати автоматично.';

  @override
  String get weatherRefresh => 'Перевірте наявність оновлень';

  @override
  String get weatherKeyPrivate =>
      'Зберігається лише на цьому пристрої, виключено з резервних копій. Порожнє введення видаляє ключ.';

  @override
  String get weatherUpdated => 'Оновлено';

  @override
  String get onlineWallpaperError =>
      'Не вдалося завантажити це зображення. Попередні шпалери зберігаються. Виберіть «Перевірити наявність оновлень», щоб повторити спробу завантаження.';

  @override
  String get onlineWallpaperHint =>
      'Останнє зображення зберігається для роботи без мережі (до 8 MiB).';

  @override
  String get onlineWallpaperHours => 'ч';

  @override
  String get onlineWallpaperInterval => 'Інтервал завантаження';

  @override
  String get onlineWallpaper => 'Онлайн шпалери';

  @override
  String get onlineWallpaperUrlError =>
      'Введіть пряме зображення HTTPS URL без даних для входу.';

  @override
  String get onlineWallpaperEnabled => 'Використовуйте онлайн шпалери';

  @override
  String get onlineWallpaperSource => 'Джерело зображення';

  @override
  String get bingWallpaper => 'Зображення дня Bing';

  @override
  String get onlineWallpaperUrlSource => 'Прямий HTTPS URL';

  @override
  String get updatePlayOnly =>
      'Ця інсталяція отримує оновлення через Google Play.';

  @override
  String get updateCheck => 'Перевір зараз';

  @override
  String get updateInstalled => 'встановлено';

  @override
  String get updateDownloadInstall => 'Завантажте та встановіть';

  @override
  String get updateNoRelease => 'Немає нових сумісних версій.';

  @override
  String get updateIncompatible =>
      'APK не відповідає цій програмі, сертифікату чи новішій версії. Встановлення заблоковано.';

  @override
  String get updateError =>
      'Неможливо перевірити, завантажити або відкрити програму встановлення. Повторіть спробу пізніше.';

  @override
  String get updateAvailable => 'Доступне оновлення';

  @override
  String get appUpdates => 'Оновлення програми';

  @override
  String get updatePermission =>
      'Дозвольте встановлення з цієї програми в налаштуваннях Android, поверніться сюди та знову натисніть «Встановити».';

  @override
  String get updateInstall => 'Встановіть завантажене оновлення';

  @override
  String get updateHint =>
      'Джерело: GitHub / KirillShchetinnikov/CuteLauncher-Releases. Автоматичні перевірки запускаються, коли панель запуску відкрито. Завантаження починається, коли ви його вибираєте; Android просить підтвердити встановлення. Ваші дані зберігаються.';

  @override
  String get updateAutomatic => 'Перевіряйте автоматично раз на день';

  @override
  String get allApplications => 'Всі програми';

  @override
  String get adbAccessibility => 'Увімкнути виправлення кнопки Home';

  @override
  String get adbAuthorization =>
      'Підтвердьте авторизацію ADB на телевізорі та повторіть спробу.';

  @override
  String get adbChangeConfirm =>
      'Застосувати це системне налаштування через ADB? Попередня програма Home зберігається перед її зміною; інші служби доступності зберігаються.';

  @override
  String get adbCheck => 'Перевірте підключення';

  @override
  String get adbDenied => 'Система не дозволила або підтвердила цю зміну.';

  @override
  String get adbDisable => 'Вимкніть попередню програму запуску';

  @override
  String get adbDisableConfirm =>
      'Вимкнути збережену попередню панель запуску? Для цього CuteLauncher має бути поточною програмою Home. Відновіть його за допомогою дії відновлення в цьому налаштуванні.';

  @override
  String get adbHint =>
      'Лише прототип для цього телевізора (127.0.0.1). Увімкніть TCP ADB у параметрах розробника, введіть його порт і підтвердьте запит авторизації на телевізорі. Бездротове налагодження за допомогою коду сполучення поки що не підтримується. Приватний ключ залишається на цьому пристрої, поза резервними копіями.';

  @override
  String get adbHome => 'Зробіть CuteLauncher додатком Home';

  @override
  String get adbInvalid => 'Введіть порт між 1024 і 65535.';

  @override
  String get adbNoRecovery =>
      'Відновлення недоступне: не знайдено іншого запуску чи збереженого стану служби.';

  @override
  String get adbPort => 'Порт TCP ADB';

  @override
  String get adbReady => 'Доступ до ADB підтверджено.';

  @override
  String get adbRestore => 'Відновити попередній лаунчер';

  @override
  String get adbSuccess => 'Зміну застосовано та перевірено.';

  @override
  String get adbTitle => 'Налаштування ADB';

  @override
  String get adbUnavailable =>
      'Не вдалося підключитися. Перевірте TCP ADB, порт і підказку авторизації.';

  @override
  String get nightModeScheduled => 'Використовуйте розклад';

  @override
  String get nightModeTitle => 'Нічний режим';

  @override
  String get nightModeScope =>
      'Для затемнення інших програм потрібен дозвіл на накладання. Без нього затемнення працює всередині CuteLauncher. Фільтру TCL не потрібен дозвіл на накладання. Понад 80% непрозорості Android може блокувати сенсорне введення в інших програмах; Пульти від телевізора все ще працюють.';

  @override
  String get nightModeEnd => 'Кінець';

  @override
  String get nightModeStart => 'Почніть';

  @override
  String get nightModeDim => 'затемнення';

  @override
  String get nightModeWarmth => 'Теплий фільтр';

  @override
  String get nightModeScheduleHint =>
      'Використовується місцевий телевізійний час. Підтримуються ночівлі. Рівний час початку та закінчення вимикає запланований фільтр.';

  @override
  String get nightModeEnabled => 'Увімкніть нічний режим';

  @override
  String get nightModePermission => 'Дозволити показ поверх інших програм';

  @override
  String get nightModePermissionGranted =>
      'Дозволяється показ поверх інших програм';

  @override
  String get backupDownloadsFailed =>
      'Не вдалося зберегти резервну копію в завантаженнях.';

  @override
  String get backupSaveDownloads =>
      'Збережіть резервну копію в розділі Завантаження';

  @override
  String get adbRestoreAccessibility =>
      'Відновити доступ до спеціальних можливостей';

  @override
  String get nightModeAdbConfirm =>
      'Дозволити CuteLauncher відображатися поверх інших програм за допомогою локального ADB? Спочатку увімкніть налагодження TCP і авторизуйте підключення. Використовує порт, збережений у майстрі ADB, або 5555.';

  @override
  String get nightModeAdbPermission => 'Надайте дозвіл через ADB';

  @override
  String get nightModeNotificationsHint =>
      'Сповіщення дозволяє вимкнути фільтр за межами CuteLauncher. Без нього використовуйте це меню.';

  @override
  String get nightModeNotificationsAllowed =>
      'Сповіщення в нічному режимі дозволено';

  @override
  String get nightModeNotifications => 'Дозволити сповіщення в нічному режимі';

  @override
  String get categoryLastVisibleHint =>
      'Принаймні одна категорія має залишатися видимою.';

  @override
  String get diagnosticsClear => 'Чітка діагностика сесії';

  @override
  String get diagnosticsReady => 'Звіт готовий';

  @override
  String get diagnosticsCreate => 'Створити звіт';

  @override
  String get diagnosticsOperations => 'Записані операції';

  @override
  String get diagnosticsCopied => 'Звіт скопійовано';

  @override
  String get diagnosticsSharingNotice =>
      'Передавайте файл автору в особисті повідомлення, не публікуйте відкрито: автоматичне очищення може пропустити особисті дані. Надсилаючи звіт автору, ви погоджуєтеся на розміщення знеособленого звіту про сумісність ТВ у Git-репозиторії CuteLauncher. Публікуються лише відомості про пристрій і доступність функцій без особистих даних; журнал помилок, команди та ваші налаштування не публікуються.\n\nЗвіт також містить установлені пакети, їхні назви, версії та стан увімкнення, а також назви, склад, порядок і видимість розділів. Ідентифікатори й назви зберігаються для діагностики; списки застосунків і розділів не публікуються.';

  @override
  String get diagnosticsHint =>
      'Єдиний звіт містить сумісність функцій ТВ і діагностику помилок. Звіт містить модель і прошивку ТВ, версію застосунку, дозволи, пам’ять, етапи й причини помилок, команди та відповіді після автоматичного очищення особистих даних. Зберігаються останні 50 операцій, окремо до 100 збоїв і обмежений журнал ADB поточного сеансу. Перезапуск очищує журнал. Особисті дані можуть залишитися: надсилайте файл у приватні повідомлення, не публікуйте відкрито. Автоматичного надсилання немає. Для кожної помилки зберігається знімок застосованих налаштувань: подальші зміни його не замінюють.\n\nЗвіт також містить установлені пакети, їхні назви, версії та стан увімкнення, а також назви, склад, порядок і видимість розділів. Ідентифікатори й назви зберігаються для діагностики; списки застосунків і розділів не публікуються.';

  @override
  String get diagnosticsTitle => 'Діагностика помилок';

  @override
  String get diagnosticsCopyFailed => 'Не вдалося скопіювати звіт.';

  @override
  String get diagnosticsCopy => 'Копіювати звіт';

  @override
  String get diagnosticsCreating => 'Створення звіту…';

  @override
  String get tclBlueLightTitle => 'TCL синій світлофільтр';

  @override
  String get tclBlueLightError =>
      'Не вдалося прочитати або перевірити налаштування фільтра TCL. Оновіть його стан і повторіть спробу.';

  @override
  String get tclBlueLightUnsupported =>
      'Інтерфейс фільтра TCL недоступний на цьому телевізорі.';

  @override
  String get tclBlueLightRefresh => 'Оновити стан фільтра TCL';

  @override
  String get tclBlueLightHint =>
      'Керує вбудованим фільтром захисту здоров’я очей телевізора. Він також може стежити за розкладом нічного режиму.';

  @override
  String get nightSolarSchedule => 'Захід і схід сонця';

  @override
  String get nightNextStart => 'Наступний старт';

  @override
  String get nightScheduleTimeHint =>
      'Для часу використовується часовий пояс телевізора. Негативні зміщення більш ранні; позитивні зміщення пізніше.';

  @override
  String get nightTemperature => 'Колірна температура фільтра';

  @override
  String get nightScheduleSettings => 'Налаштування розкладу';

  @override
  String get nightCityName => 'Назва міста';

  @override
  String get nightSkipUntilNext =>
      'Вимкніть нічний режим до наступного заходу сонця';

  @override
  String get nightSunriseOffset => 'Кінець відносно сходу сонця';

  @override
  String get nightEnableUntilMorning =>
      'Увімкніть нічний режим до наступного світанку';

  @override
  String get nightPermissions => 'Дозволи';

  @override
  String get nightTclSchedule => 'Включіть фільтр TCL у розклад';

  @override
  String get nightSearchCity => 'Пошук';

  @override
  String get nightRefreshSun => 'Оновити схід і захід сонця';

  @override
  String get nightSolarUnavailable =>
      'Виберіть місто та оновіть сонячні години. Якщо схід або захід сонця недоступні, розклад сонячної енергії призупиняється.';

  @override
  String get nightSunsetOffset => 'Почніть відносно заходу сонця';

  @override
  String get nightCityHint =>
      'Виберіть своє місто замість надання доступу до місцезнаходження. Вибрані координати надсилаються на Sunrise-Sunset.org або Open-Meteo як запасний варіант для отримання сонячного часу.';

  @override
  String get nightResumeSchedule => 'Повернутися до розкладу';

  @override
  String get nightScheduleSource => 'Тип розкладу';

  @override
  String get nightSolarCached =>
      'Використання кешованого сонячного часу; Інтернет-оновлення повториться автоматично.';

  @override
  String get nightTclScheduleHint =>
      'Використовує той самий розклад, коли ввімкнено нічний режим. Внесені вручну зміни до фільтра TCL діють до наступного запланованого переходу. Дозвіл на накладання не потрібен.';

  @override
  String get nightRefreshPermission => 'Оновити статус дозволу';

  @override
  String get nightCityNotFound => 'Міста не знайдено. Спробуйте інше ім\'я.';

  @override
  String get nightNoOffset => 'Без зміщення';

  @override
  String get nightManualSchedule => 'Індивідуальний графік';

  @override
  String get nightChooseCity => 'Виберіть місто';

  @override
  String get nightPermissionUnknown => 'Статус дозволу на накладання невідомий';

  @override
  String get nightNextEnd => 'Наступний кінець';

  @override
  String get nightTemporaryOff => 'Затемнення тимчасово вимкнено до';

  @override
  String get nightCitySearchFailed =>
      'Не вдалося знайти міста. Перевірте підключення до Інтернету.';

  @override
  String get nightSolarAttribution =>
      'Щоденний час сонця: Sunrise-Sunset.org; запасний: Open-Meteo. Пошук міста: GeoNames. Кілька днів зберігаються в кеші для використання в автономному режимі.';

  @override
  String get nightTemporaryOn => 'Затемнення тимчасово ввімкнено до';

  @override
  String get homeScreen => 'Головний екран';

  @override
  String get appearanceSettings => 'Зовнішній вигляд';

  @override
  String get generalSettings => 'Просунутий';

  @override
  String get advancedSettings => 'Просунутий';

  @override
  String get controlAndStartup => 'Панель запуску та керування телевізором';

  @override
  String get sectionsAndOrder => 'Розділи та порядок';

  @override
  String get topPanel => 'Верхня панель';

  @override
  String get tileStyle => 'Стиль плитки';

  @override
  String get tilesAndLabels => 'Плитки та етикетки';

  @override
  String get highlightAndAnimation => 'Підсвічування та анімація';

  @override
  String get androidTvSettings => 'Налаштування Android TV';

  @override
  String get weatherSettings => 'Налаштування погоди';

  @override
  String get showHighlightOutline => 'Показати контур виділення';

  @override
  String get resetTilesAndPanel => 'Скидання налаштувань плитки та панелі';

  @override
  String get resetTilesAndPanelHint =>
      'Скинути додаткові параметри плитки, мітки, виділення та верхньої панелі? Шпалери, акцентний колір, стиль плитки та видимість етикетки збережені.';

  @override
  String get panelAppearanceSettings => 'Зовнішній вигляд верхньої панелі';

  @override
  String get panelSharedHint => 'Змініть вигляд у налаштуваннях плитки.';

  @override
  String get effectsCompatibilityHint =>
      'Додатковий зовнішній вигляд: контур завжди видно і не пульсує. Розмірний стиль не має спадкового контуру; класичний не пульсує. Інтенсивність впливає на масштаб і тінь; масштабування обмежене простором.';

  @override
  String get sizeAndLayout => 'Розмір і планування';

  @override
  String get labelsGroup => 'етикетки';

  @override
  String get surfaceGroup => 'Поверхня';

  @override
  String get clockAndDateGroup => 'Годинник і дата';

  @override
  String get networkAndTrafficGroup => 'Мережа та трафік';

  @override
  String get buttonsGroup => 'кнопки';

  @override
  String get notificationAppsHint =>
      'Вимкніть програми, сповіщення яких вам не потрібні. Увімкнений перемикач дозволяє сповіщення; програму все ще можна запустити.';

  @override
  String get notificationPanelLink => 'Зовнішній вигляд верхньої панелі';

  @override
  String get overlayAccessAdb => 'Відображення поверх інших програм (ADB)';

  @override
  String get tileStyleModern => 'Сучасний';

  @override
  String get tileStyleVolume => 'Габаритний';

  @override
  String get showTime => 'Показати час';

  @override
  String get showDate => 'Показати дату';

  @override
  String get showWeather => 'Показати погоду';

  @override
  String get showNetwork => 'Показати стан мережі';

  @override
  String get showTraffic => 'Показати трафік';

  @override
  String get scheduledBrightness => 'Запланована яскравість';

  @override
  String get followTileStyle => 'Дотримуйтесь стилю';

  @override
  String get androidTvSettingsHint =>
      'Відкрийте системні налаштування телевізора';

  @override
  String get autoHideTopPanel => 'Автоматично приховати панель';

  @override
  String get showSectionTitles => 'Показати заголовки розділів';

  @override
  String get usageDaily => 'Щодня';

  @override
  String get usageWeekly => 'Щотижня';

  @override
  String get usageMonthly => 'Щомісяця';

  @override
  String get onlineWallpaperAddress => 'Адреса зображення (HTTPS)';

  @override
  String get watchNextAppLimits => 'Обмеження на додаток';

  @override
  String get watchNextAppLimitsHint =>
      'Обмеження джерела застосовуються перед загальним обмеженням. Unlimited зберігає лише загальний ліміт; прихований вміст залишається прихованим.';

  @override
  String get rememberCategoryFocus =>
      'Запам\'ятати останню картку, яку виділили';

  @override
  String get automaticBackups => 'Автоматичне резервне копіювання';

  @override
  String get automaticBackupsHint =>
      'Щоденні копії налаштувань, шпалер і банерів, поки активний лаунчер. Пропущена копія запускається після повернення до панелі запуску. Зберігається приватно на цьому пристрої, загалом до 256 MiB; видалення програми або її даних видаляє їх. Також зберігайте зовнішню резервну копію.';

  @override
  String get automaticBackupsEnabled =>
      'Щоденне автоматичне резервне копіювання';

  @override
  String get automaticBackupsKeep => 'Копії залишити';

  @override
  String get automaticBackupCreateNow => 'Створіть точку відновлення зараз';

  @override
  String get automaticBackupFailed =>
      'Помилка операції резервного копіювання. Перевірте вільне місце та повторіть спробу.';

  @override
  String get restorePoints => 'Точки відновлення';

  @override
  String get noRestorePoints => 'Точок відновлення ще немає';

  @override
  String get updatePrereleases => 'Оновлювати до попередніх випусків';

  @override
  String get topPanelObjects => 'Об\'єкти';

  @override
  String get panelTransparency => 'Прозорість панелі';

  @override
  String get panelTextBackground => 'Текст і фон кнопки';

  @override
  String get panelTextBackgroundColor => 'Колір фону тексту та кнопки';

  @override
  String get panelTextColor => 'Колір тексту та кнопки';

  @override
  String get panelTextSize => 'Розмір тексту та кнопки';

  @override
  String get panelFont => 'Шрифт тексту';

  @override
  String get fontSans => 'Без засічок';

  @override
  String get fontSerif => 'Засічки';

  @override
  String get fontMono => 'Моноширинні';

  @override
  String get fontCondensed => 'Згущене';

  @override
  String get trafficPermissionGranted => 'Доступ до статистики трафіку надано';

  @override
  String get background => 'Фон';

  @override
  String get backgroundParameters => 'Налаштування джерела';

  @override
  String get resetAppearanceHint =>
      'Скинути фон, акценти, плитки, мітки, виділення та анімацію?';

  @override
  String get wallpaperDimming => 'затемнення';

  @override
  String get wallpaperPlacement => 'Розміщення';

  @override
  String get wallpaperDisplay => 'Відображення шпалер';

  @override
  String get wallpaperContain => 'Показати все зображення';

  @override
  String get wallpaperBlurred => 'Над розмита копія';

  @override
  String get wallpaperCover => 'На весь екран';

  @override
  String get wallpaperBrightness => 'Яскравість шпалер';

  @override
  String get wallpaperSaturation => 'насиченість';

  @override
  String get categoryPadding => 'Заповнення категорій';

  @override
  String get categoryLight => 'світло';

  @override
  String get categoryBlue => 'Синій';

  @override
  String get categoryPurple => 'Фіолетовий';

  @override
  String get categoryAllRows => 'все';

  @override
  String get categoryTeal => 'Чирок';

  @override
  String get categoryMaxRows => 'Видимі рядки сітки';

  @override
  String get categoryDark => 'Темний';

  @override
  String get categoryAppearance => 'Зовнішній вигляд категорії';

  @override
  String get categoryBackground => 'Категорія фону';

  @override
  String get categoryTransparent => 'Прозорий';

  @override
  String get slideshowInterval => 'Інтервал зміни';

  @override
  String get slideshowFolderSelected =>
      'Доступ до папки збережено на цьому пристрої.';

  @override
  String get slideshowRandom => 'Випадковий порядок';

  @override
  String get wallpaperSlideshow => 'Слайд-шоу папки';

  @override
  String get slideshowNext => 'Наступне зображення';

  @override
  String get slideshowFolderRequired => 'Виберіть папку для запуску слайд-шоу.';

  @override
  String get slideshowHint =>
      'До 1000 зображень і 4000 записів папок; файли до 8 MiB. Пошкоджені файли пропускаються, а останнє якісне зображення зберігається. Зміни зупиняються у фоновому режимі. Виберіть папку ще раз після відновлення на іншому пристрої.';

  @override
  String get slideshowSeconds => 'с';

  @override
  String get slideshowError =>
      'Неможливо прочитати зображення. Виберіть доступну папку, яка містить дійсні зображення.';

  @override
  String get slideshowFolder => 'Виберіть папку';

  @override
  String get slideshowRecursive => 'Включати вкладені папки';

  @override
  String get weatherSourceKeyRequired =>
      'Додайте ключ API для цього джерела погоди.';

  @override
  String get weatherOpenWeatherCredit =>
      'Погода: OpenWeather (openweathermap.org). Щоденні значення підсумовують доступні тригодинні періоди прогнозу.';

  @override
  String get weatherOpenWeatherHint =>
      'Використовуйте свій ключ для поточної погоди та прогнозу на 5 днів/3 години. Кожне оновлення робить два запити; доступ і обмеження залежать від вашого плану.';

  @override
  String get weatherOpenWeatherKey => 'Ключ OpenWeather API';

  @override
  String get mediaPause => 'Пауза';

  @override
  String get showNowPlaying => 'Показати зараз грає на головній сторінці';

  @override
  String get nowPlayingAccessHint =>
      'Елементи керування медіа-файлами потребують доступу до сповіщень для CuteLauncher. Відображаються лише дії, надані гравцем.';

  @override
  String get nowPlaying => 'Зараз грає';

  @override
  String get mediaNext => 'Наступний трек';

  @override
  String get mediaPlay => 'Резюме';

  @override
  String get mediaControlError => 'Гравець недоступний або не прийняв цю дію.';

  @override
  String get nightUsageAccess => 'Дозволити доступ до використання';

  @override
  String get nightExcludedAppsHint =>
      'Накладання та запланований фільтр TCL призупинено у вибраних програмах. Потрібен доступ до використання; без нього не можна застосовувати виключення.';

  @override
  String get nightExcludedApps => 'Виключені програми';

  @override
  String get adbPairPort => 'Порт сполучення';

  @override
  String get adbPairOverlayHint =>
      'Відкрийте «Налагодження бездротового зв’язку» та з’єднайте з кодом з’єднання. Тримайте діалогове вікно системного коду відкритим. Ця форма стає активною через 30 секунд. Введіть обидва порти та код, показаний Android.';

  @override
  String get adbOverlaySettings =>
      'Поверніть керування до налаштувань на 30 секунд';

  @override
  String get adbTlsHint =>
      'Використовуйте бездротове налагодження в параметрах розробника. Сполучення та підключення мають різні порти. Якщо ваша мікропрограма не має екрана з кодом сполучення або блокує накладені вікна, замість цього використовуйте TCP / RSA. Усі підключення залишаються локальними для цього телевізора.';

  @override
  String get adbPaired =>
      'Парні. Перевірте підключення за допомогою порту бездротового налагодження.';

  @override
  String get adbTransport => 'Спосіб підключення';

  @override
  String get adbPairCode => 'Шестизначний код';

  @override
  String get adbOverlayRequired =>
      'Для введення коду в налаштуваннях потрібен дозвіл для відображення поверх інших програм.';

  @override
  String get adbOverlayPermission => 'Дозволити показ поверх інших програм';

  @override
  String get adbTlsUnsupported =>
      'Це мікропрограмне забезпечення не може відкрити потрібний екран налаштувань або накладання пари. Використовуйте TCP / RSA.';

  @override
  String get adbConnectPort => 'Порт підключення';

  @override
  String get adbTls => 'TLS / код сполучення';

  @override
  String get adbTcp => 'TCP / RSA';

  @override
  String get adbPairingFailed =>
      'Не вдалося створити пару. Перевірте код і порт сполучення, залиште діалогове вікно коду Android відкритим і повторіть спробу.';

  @override
  String get adbTlsDisabled =>
      'Бездротове налагодження вимкнено або його стан недоступний. Увімкніть його в параметрах розробника.';

  @override
  String get adbPairOverlay => 'Введіть код з’єднання в налаштуваннях';

  @override
  String get adbPair => 'Пара';

  @override
  String get adbDeveloperSettings => 'Відкрийте параметри розробника';

  @override
  String get adbTwoWindowsHint =>
      'Якщо ця прошивка підтримує два вікна, залиште відкритим діалогове вікно сполучення системи поруч із CuteLauncher і введіть його код тут. Пряме з’єднання доступне лише тоді, коли відкриті обидва вікна.';

  @override
  String get adbTwoWindows => 'Відкрийте налаштування у другому вікні';

  @override
  String get autoLaunchBoot => 'Після завантаження телевізора';

  @override
  String get autoLaunchOff => 'Вимкнено';

  @override
  String get autoLaunchTitle => 'Автозапуск';

  @override
  String get autoLaunchDelay => 'Затримка запуску';

  @override
  String get autoLaunchHdmi => 'Переключіться на вибраний вхід HDMI';

  @override
  String get autoLaunchWake => 'Після пробудження';

  @override
  String get autoLaunchHint =>
      'Виберіть програму або вхід HDMI, щоб відкрити після запуску телевізора або пробудження. Нижче встановіть подію та затримку. Дія виконується один раз, коли Android показує CuteLauncher. Будь-який віддалений вхід або вихід з головного екрана скасовує очікування. Ви можете вільно змінити входи HDMI пізніше. Встановіть CuteLauncher як програму запуску за замовчуванням або увімкніть Запуск під час завантаження, якщо потрібно. Виявлення пробудження вимагає, щоб CuteLauncher продовжував працювати.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds секунд';
  }

  @override
  String get autoLaunchApp => 'Відкрийте вибрану програму';

  @override
  String get autoLaunchTarget => 'Запуск мішені';

  @override
  String get autoLaunchUnavailable =>
      'Ціль недоступна або мікропрограма не дозволяє цю дію.';

  @override
  String get autoLaunchCancelled => 'Відкладений запуск скасовано.';

  @override
  String get syncTitle => 'Налаштування обміну';

  @override
  String get syncHint =>
      'Збережіть файл налаштувань, перенесіть його на інший пристрій і відкрийте там. Обміняйте файл назад, щоб оновити обидва пристрої. Інтерфейс, стиль плитки та параметри відображення є спільними. Програми, розділи, файли шпалер, дозволи, HOME, правила запуску та секрети залишаються на цьому пристрої. Це ручний обмін; не використовується обліковий запис або підключення до мережі у фоновому режимі.';

  @override
  String get syncExport => 'Збережіть зміни у файлі';

  @override
  String get syncImport => 'Відкрити зміни з іншого пристрою';

  @override
  String get syncSaved => 'Файл обміну налаштуваннями збережено.';

  @override
  String get syncFailed =>
      'Неможливо обмінятися налаштуваннями. Частковий імпорт не зберігається. Перевірте файл або відкрийте його знову, якщо налаштування змінилися під час перегляду.';

  @override
  String get syncPreviewHint =>
      'Перегляньте зміни перед застосуванням. Для конфліктів виділіть кожен рядок, щоб вибрати цей пристрій або файл. Спочатку вибрано збереження цього пристрою. Скасувати залишає налаштування без змін.';

  @override
  String get syncNoChanges =>
      'Немає нових налаштувань. Подайте заявку, щоб підтвердити спільну історію.';

  @override
  String syncLocalValue(String value) {
    return 'Цей пристрій: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'З файлу: $value';
  }

  @override
  String get syncKeepLocal => 'Конфлікт: залишити цей пристрій';

  @override
  String get syncUseFile => 'Конфлікт: використовувати файл';

  @override
  String get syncApply => 'Застосувати перевірені зміни';

  @override
  String get syncApplied =>
      'Налаштування поміняно. Збережіть новий файл, щоб надіслати результат назад.';

  @override
  String syncStyleParameters(int count) {
    return 'Власний стиль: $count параметрів (відмінності нижче)';
  }

  @override
  String get cloudBackups => 'Хмарні резервні копії';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud. Введіть адресу HTTPS наявної папки та пароль програми. Перекази ручні; у цій папці зберігається остання копія.';

  @override
  String get cloudUrl => 'Адреса папки HTTPS';

  @override
  String get cloudUser => 'Ім\'я користувача';

  @override
  String get cloudPassword => 'Пароль програми';

  @override
  String get cloudConnect => 'Перевірте та збережіть обліковий запис';

  @override
  String get cloudCheck => 'Перевірте підключення';

  @override
  String get cloudDisconnect => 'Відключити обліковий запис';

  @override
  String get cloudDisconnectConfirm =>
      'Видалити цей обліковий запис із телевізора? Копії в хмарі залишаться.';

  @override
  String get cloudUpload => 'Збережіть копію в хмарі';

  @override
  String get cloudDownload => 'Відновити з хмари';

  @override
  String get cloudUploadConfirm =>
      'Замінити cutelauncher_backup.json у цій папці на поточні налаштування та дані?';

  @override
  String get cloudSuccess => 'Готово';

  @override
  String get cloudConfigurationError =>
      'Перевірте адресу папки HTTPS, ім’я користувача та пароль програми.';

  @override
  String get cloudAuthorizationError =>
      'Доступ заборонено. Перевірте свій обліковий запис і дозволи папки.';

  @override
  String get cloudMissingError => 'Папку або резервну копію не знайдено.';

  @override
  String get cloudUnsupportedError =>
      'Ця адреса не підтримує необхідні операції WebDAV. Перенаправлення не виконуються; введіть остаточну адресу папки.';

  @override
  String get cloudNetworkError =>
      'Помилка підключення або час очікування. Повторіть спробу, коли мережа стане доступною.';

  @override
  String get cloudFailed =>
      'Не вдалося виконати дію резервного копіювання. Перевірте доступ до сховища та повторіть спробу.';

  @override
  String get cloudStorageError =>
      'Пам\'ять облікового запису недоступна. Від’єднайте та знову налаштуйте обліковий запис.';

  @override
  String get adbPermissionChecking => 'Перевірка доступу…';

  @override
  String get adbPermissionConnected => 'ADB підключено · надати дозвіл';

  @override
  String get adbPermissionDisconnected =>
      'ADB відключено · налагодити підключення';

  @override
  String get adbSetupIntro =>
      'Увімкніть налагодження та мережу ADB у налаштуваннях розробника телевізора, а потім довірте CuteLauncher. Усі дії ADB виконуєте на свій страх і ризик.';

  @override
  String get adbConnectionBlock => 'Підключення ADB';

  @override
  String get adbNotChecked => 'Підключення не перевірено';

  @override
  String get adbApplied => 'Вже застосовано';

  @override
  String get adbNotApplied => 'Ще не застосовано';

  @override
  String get adbDefaultBlock => 'Панель запуску за замовчуванням';

  @override
  String get adbSystemDefault =>
      'Відкрити параметри запуску системи за замовчуванням';

  @override
  String get adbAssignDefault =>
      'Встановити CuteLauncher як програму запуску за замовчуванням через ADB';

  @override
  String get adbRestoreDefault =>
      'Відновіть попередню програму запуску за замовчуванням за допомогою ADB';

  @override
  String get adbDefaultHint =>
      'Використовуйте ADB, якщо системне меню не може встановити програму запуску за замовчуванням.';

  @override
  String get adbBuiltinHint =>
      'Якщо вимкнути вбудований засіб запуску, система натомість відкриватиме CuteLauncher. Це може вплинути на меню та кнопки телевізора. Увімкніть вбудовану панель запуску, щоб скасувати це.';

  @override
  String get adbHomeBlock => 'Кнопка «Додому» та запуск';

  @override
  String get adbEnableService =>
      'Увімкнути службу доступності CuteLauncher через ADB';

  @override
  String get adbHomeOverride => 'Замінити кнопку «Додому».';

  @override
  String get adbHomeOptional =>
      'Якщо вбудовану програму запуску вимкнено, заміна головного екрана та запуск під час запуску телевізора необов’язкові.';

  @override
  String get adbEnableBuiltin =>
      'Увімкніть вбудовану програму запуску через ADB';

  @override
  String get adbDisableBuiltin =>
      'Вимкніть вбудовану програму запуску через ADB';

  @override
  String get adbNoBuiltin =>
      'Вбудованих засобів запуску Google TV / Android TV не знайдено.';

  @override
  String get adbChanged =>
      'Стан змінився. Перевірте підключення та підтвердіть дію ще раз.';

  @override
  String get adbEffectHome =>
      'CuteLauncher стане програмою запуску системи за замовчуванням. Поточну панель запуску буде збережено для відновлення.';

  @override
  String get adbEffectRestore =>
      'Попередню програму запуску буде ввімкнено та встановлено за умовчанням. Якщо недоступний або не збережений, вибирається перша доступна інша панель запуску. Це не вимикає функцію Home Button Fix.';

  @override
  String get adbEffectDisable =>
      'Вбудовану програму запуску буде вимкнено для користувача телевізора. Меню та кнопки телевізора можуть перестати працювати. Програма не видалена.';

  @override
  String get adbRecoveryHomeDisable =>
      'Весь майстер налаштування Google TV, включаючи головний екран відновлення, також буде вимкнено, щоб CuteLauncher міг стати засобом запуску за замовчуванням. Функції майстра налаштування будуть недоступні до відновлення. Початковий стан обох пакетів буде збережено для відновлення.';

  @override
  String get adbRecoveryHomeRestore =>
      'Майстер налаштування Google TV також повернеться до свого збереженого стану.';

  @override
  String get adbDisableHomeUnavailable =>
      'Інший головний екран має вищий пріоритет. Його не можна безпечно вимкнути за допомогою цієї програми запуску.';

  @override
  String get adbEffectEnable =>
      'Вбудований засіб запуску буде відновлено до збереженого стану або ввімкнено, якщо стан не було збережено. Система може знову вибрати його як засіб запуску за замовчуванням.';

  @override
  String get adbEffectAccessibility =>
      'Службу доступності CuteLauncher буде ввімкнено. Він може отримувати Home події; Перехоплення контролюється окремим перемикачем. Інші послуги збережено.';

  @override
  String get adbEffectAccessibilityRestore =>
      'Служба CuteLauncher повернеться до свого стану до надання доступу ADB. Інші служби доступності збережено.';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher буде дозволено відображати вікна поверх інших програм, включаючи нічний фільтр.';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher отримуватиме доступ до сповіщень через власну службу слухачів.';

  @override
  String get adbEffectWatchNext =>
      'CuteLauncher отримає доступ до продовження перегляду даних.';

  @override
  String get adbEffectUsage =>
      'CuteLauncher отримає доступ до статистики використання для виявлення трафіку та активних програм.';

  @override
  String get adbEffectWriteSettings =>
      'CuteLauncher буде дозволено змінювати налаштування яскравості системи.';

  @override
  String get adbNoAvailableLauncher =>
      'Інших встановлених лаунчерів не знайдено. Відновлення недоступне.';

  @override
  String get adbUnsupported =>
      'Недоступно на цьому пристрої: не підтримується команда ADB.';

  @override
  String get adbHomeUnavailable =>
      'Вбудований засіб запуску має системний пріоритет. Пряме призначення через ADB недоступне; скористайтеся доступністю або вимкніть вбудовану панель запуску.';

  @override
  String get nightBatteryExempt => 'CuteLauncher не підлягає оптимізації';

  @override
  String get nightBatteryHint =>
      'Може допомогти розкладу працювати у фоновому режимі. Не гарантує збереження процесу в режимі очікування.';

  @override
  String get nightBatteryOptimized => 'CuteLauncher підлягає оптимізації';

  @override
  String get nightBatteryTitle => 'Оптимізація батареї';

  @override
  String get nightBatteryUnavailable =>
      'Системні налаштування недоступні для цієї мікропрограми або заборонено доступ.';

  @override
  String get nightBatteryUnknown => 'Статус звільнення невідомий';

  @override
  String get nightBatteryOpenApps => 'Відкрийте налаштування програм';

  @override
  String get nightBatteryGuide =>
      '1. У налаштуваннях програм відкрийте Спеціальний доступ до програм.\n2. Виберіть оптимізацію батареї (іноді енергозбереження).\n3. Знайдіть CuteLauncher; виберіть Усі програми, якщо потрібно.\n4. Вимкніть оптимізацію або виберіть Без обмежень.\nНазви та доступність меню залежать від мікропрограми телевізора.';

  @override
  String get updateNotifications => 'Показати сповіщення про оновлення';

  @override
  String get diagnosticsSave => 'Зберегти звіт у файл';

  @override
  String get diagnosticsSaved => 'Звіт збережено';

  @override
  String get diagnosticsSaveFailed =>
      'Не вдалося зберегти звіт. Перевірте файловий менеджер і папку призначення.';

  @override
  String get memoryCacheSize => 'Розмір кешу зображення';

  @override
  String get memoryProcess => 'Пам\'ять програми';

  @override
  String get memoryImages => 'Кеші зображень';

  @override
  String get diagnosticsExportOpened =>
      'Виберіть папку в файловому менеджері та збережіть звіт.';

  @override
  String get adbDisableService =>
      'Вимкнути службу доступності CuteLauncher через ADB';

  @override
  String get adbDefaultSettings =>
      'Налаштування панелі запуску за замовчуванням';

  @override
  String get adbHomeSettings => 'Налаштування кнопки «Додому».';

  @override
  String get adbAccessibilitySettings => 'Відкрийте налаштування доступності';

  @override
  String get adbAccessibilityGuide =>
      'Виберіть CuteLauncher у системному меню та ввімкніть його службу. Поверніться сюди, щоб налаштувати домашнє перехоплення. Щоб вимкнути його, вимкніть послугу CuteLauncher у цьому ж меню.';

  @override
  String get adbEffectAccessibilityDisable =>
      'Службу CuteLauncher буде вимкнено. Домашнє перехоплення припиниться. Інші служби доступності збережено.';

  @override
  String get backupAutoEnabled => 'Автоматичне резервне копіювання';

  @override
  String get backupClientId => 'ID клієнта';

  @override
  String get backupClientSecret => 'Секрет клієнта';

  @override
  String get backupCloudImportConfirm =>
      'Усі локальні налаштування, категорії та зображення буде замінено хмарними даними. Продовжити?';

  @override
  String get backupConfigured => 'Налаштовано';

  @override
  String get backupConnection => 'Налаштування підключення';

  @override
  String get backupCreated => 'Створено';

  @override
  String get backupDaily => 'Щодня';

  @override
  String get backupDriveHelp =>
      'Виберіть Підключитися та підтвердьте код на телефоні. Резервні копії доступні в папці CuteLauncher у Google Drive, звідки їх можна завантажити або видалити. Не змінюйте імена файлів для відновлення в додатку. Повторне підключення після оновлення з прихованих резервних копій; старі резервні копії не переносяться автоматично.';

  @override
  String get backupFrequency => 'Частота резервного копіювання';

  @override
  String get backupHourly => 'щогодини';

  @override
  String get backupLocal => 'Локальні копії';

  @override
  String get backupMinutes => 'хв';

  @override
  String get backupMode => 'Режим';

  @override
  String get backupNever => 'Резервної копії ще немає';

  @override
  String get backupNotConfigured => 'Не налаштовано';

  @override
  String get backupOptions => 'Варіанти резервного копіювання';

  @override
  String get backupSaveMode => 'Резервне копіювання';

  @override
  String get backupScope => 'Резервне копіювання на телевізорах';

  @override
  String get backupSyncScope => 'Синхронізація між телевізорами';

  @override
  String get backupSeparate => 'Для кожного телевізора окремо';

  @override
  String get backupShared => 'Однакові налаштування для всіх телевізорів';

  @override
  String get backupStorage => 'Зберігання';

  @override
  String get backupSyncHelp =>
      'Завантажити дані та завантажити зміни. Остання зміна виграє конфлікти. Годинники телевізора мають бути правильними. Синхронізація виконується, коли відкрито панель запуску.';

  @override
  String get backupSyncLimit => 'Перевіряйте не частіше ніж';

  @override
  String get backupSyncMode => 'Синхронізація';

  @override
  String get backupSyncOptions => 'Параметри синхронізації';

  @override
  String get backupTime => 'Резервний час';

  @override
  String get backupWeekday => 'День тижня';

  @override
  String get backupWeekly => 'Щотижня';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'Локальні копії видаляються разом із програмою або її даними. Зберігайте копію також поза телевізором.';

  @override
  String get panelObjectOrder => 'Порядок об\'єктів';

  @override
  String get panelInformationGroup => 'Інформація';

  @override
  String get panelOrderHint =>
      '◄ / ► — почати або завершити переміщення; ▲ / ▼ — змінити порядок, на межі груп — перенести на інший бік; OK / Back — завершити.';

  @override
  String get panelTextBackgroundTransparency =>
      'Прозорість фону тексту та кнопки';

  @override
  String get weatherCityHint =>
      'Введіть назву міста англійською мовою, наприклад Moscow.';

  @override
  String get weatherCityNotFound =>
      'Місто не знайдено. Перевірте назву міста англійською.';

  @override
  String get weatherLocationAutomatic => 'Отримати автоматично';

  @override
  String get weatherLocationAutomaticHint =>
      'Отримати координати пристрою. Потрібен дозвіл на місцезнаходження.';

  @override
  String get weatherLocationManual => 'Введіть вручну';

  @override
  String get weatherLocationPermissionDenied =>
      'Дозвольте доступ до місцезнаходження в налаштуваннях Android і повторіть спробу.';

  @override
  String get weatherLocationUnavailable =>
      'Не вдалося отримати координати. Перевірте налаштування розташування Android або введіть місто вручну.';

  @override
  String get nightFilterSettings => 'Налаштування фільтра';

  @override
  String get nightScheduleMenu => 'розклад';

  @override
  String get nightScheduleInactive => 'Розклад вимкнено';

  @override
  String get nightLocation => 'Розташування';

  @override
  String get nightLocationAutomatic => 'Отримати автоматично';

  @override
  String get nightLocationManual => 'Введіть вручну';

  @override
  String get nightLocationFailed =>
      'Місцезнаходження недоступне. Перевірте налаштування дозволу та розташування системи.';

  @override
  String get nightCityEnglish => 'Введіть назву міста англійською мовою';

  @override
  String get nightOverlayBrief =>
      'Дозволяє фільтру відображатися поверх інших програм.';

  @override
  String get weatherGetLocation => 'Отримати місцезнаходження';

  @override
  String get backupLastCreated => 'Створено останню резервну копію:';

  @override
  String get backupManagement => 'Керуйте резервними копіями';

  @override
  String get backupCopyList => 'Резервний список';

  @override
  String get backupRefreshCopyList => 'Оновити список резервних копій';

  @override
  String get backupCreateNow => 'Створіть нову резервну копію зараз';

  @override
  String get backupFolderPath => 'Резервна папка';

  @override
  String get backupPrivateFolder => 'Приватна папка заявки';

  @override
  String get backupRestoreCopy => 'Відновити цю резервну копію';

  @override
  String get backupDeleteConfirm => 'Видалити вибрану резервну копію?';

  @override
  String get blockedAppsGroup => 'Заблоковані програми';

  @override
  String get notificationSettingsButton => 'Налаштування сповіщень';

  @override
  String get hidePersistentNotificationsHint =>
      'Приховати постійні сповіщення в списку та над іншими програмами.';

  @override
  String get nightTransitionTime => 'Перехідний час';

  @override
  String get brightnessSolar => 'Використовуйте розклад нічного режиму';

  @override
  String get brightnessAfterSunrise => 'Після сходу сонця';

  @override
  String get brightnessAfterSunset => 'Після заходу сонця';

  @override
  String get brightnessTransitionTime => 'Час переходу яскравості';

  @override
  String get brightnessSolarUnavailable =>
      'Розклад нічного режиму недоступний. Перевірте його час і місце розташування.';

  @override
  String get persistentNotificationCannotDelete =>
      'Це постійне сповіщення не можна видалити. Його можна лише заблокувати.';

  @override
  String get diagnosticsCreateFailed =>
      'Не вдалося створити діагностичний звіт. Спробуйте знову.';

  @override
  String get backupListFailed =>
      'Не вдалося завантажити список резервних копій. Перевірити доступ до вибраного сховища.';

  @override
  String get updateInstallerFailed =>
      'Не вдалося відкрити інсталятор оновлення. Спробуйте ще раз і переконайтеся, що інсталятор Android доступний.';

  @override
  String get backupFolderFailed =>
      'Не вдалося вибрати або зберегти папку резервної копії. Виберіть доступну папку та повторіть спробу.';

  @override
  String get updateDownloadFailed =>
      'Не вдалося завантажити оновлення. Перевірте підключення до Інтернету та доступний обсяг пам’яті.';

  @override
  String get backupDeleteFailed =>
      'Не вдалося видалити резервну копію. Перевірте дозволи на видалення та повторіть спробу.';

  @override
  String get updateCheckFailed =>
      'Не вдалося перевірити наявність оновлень. Перевірте підключення до Інтернету та повторіть спробу.';

  @override
  String get backupCreateFailed =>
      'Не вдалося створити резервну копію. Перевірте доступ до сховища та доступний простір.';

  @override
  String get wallpaperChangeFailed =>
      'Не вдалося змінити шпалери. Перевірте доступ до файлу та повторіть спробу.';

  @override
  String get backupDownloadsFolder => 'Завантаження / CuteLauncher';

  @override
  String get backupChooseFolder => 'Виберіть папку в файловому менеджері';

  @override
  String get backupFolderPickerUnavailable =>
      'На цьому телевізорі недоступний засіб вибору папок. Виберіть Завантаження / CuteLauncher або внутрішню папку програми.';

  @override
  String get driveConfigurationError =>
      'Облікові дані Google Drive відсутні або недійсні. Введіть ідентифікатор клієнта та секрет клієнта свого клієнта TV OAuth.';

  @override
  String get driveCodeExpired =>
      'Час очікування входу Google Drive минув. Виберіть Перевірити та зберегти обліковий запис, щоб отримати новий код.';

  @override
  String get brightnessAfterNightStart => 'Нічний час';

  @override
  String get brightnessAfterNightEnd => 'денний час';

  @override
  String get backupSyncSettings => 'Налаштування для синхронізації';

  @override
  String get backupSyncHomeGroup => 'Головний екран, розділи та програми';

  @override
  String get backupSyncAppearanceGroup => 'Зовнішній вигляд, шпалери та банери';

  @override
  String get backupSyncDisplayGroup => 'Нічний режим, яскравість і заставка';

  @override
  String get backupSyncControlsGroup =>
      'Панель запуску та керування телевізором';

  @override
  String get backupSyncGeneralGroup => 'Мова, оновлення та інші налаштування';

  @override
  String get backupSyncGroupsHelp =>
      'Вимкнені блоки залишаються локальними для цього телевізора. Вибір блоку синхронізується між пристроями.';

  @override
  String get backupSyncGroupsFailed =>
      'Не вдалося зберегти вибрані налаштування для синхронізації. Спробуйте знову.';

  @override
  String get tileLayoutMode => 'Розкладка плитки';

  @override
  String get tileLayoutAuto => 'Автоматично за розміром плитки';

  @override
  String get tileLayoutColumns => 'Фіксована кількість стовпців';

  @override
  String get tileLayoutRows => 'Фіксована кількість рядків';

  @override
  String get tileRowCount => 'Підрахунок рядків';

  @override
  String get useGlobalTileSettings => 'Використовуйте глобальні налаштування';

  @override
  String get centerSelection => 'Вибір позиції';

  @override
  String get selectionBottom => 'Дно';

  @override
  String get selectionLower => 'Нижня середина';

  @override
  String get selectionCenter => 'центр';

  @override
  String get selectionUpper => 'Верхня середина';

  @override
  String get selectionTop => 'Топ';

  @override
  String get settingsStyle => 'Стиль налаштувань';

  @override
  String get tileFocusEnlargement => 'Збільшення фокусу';

  @override
  String get tileFocusShadowStrength => 'Сила тіні';

  @override
  String get tileFocusLift => 'Ліфт';

  @override
  String get tileFocusLiftHeight => 'Висота підйому';

  @override
  String get tileFocusBorderColor => 'Колір межі фокуса';

  @override
  String get tileFocusAccentColor => 'Акцентний колір';

  @override
  String get tileFocusDynamicColor => 'Динамічні кольори';

  @override
  String get tileSizeFromColumns =>
      'Розмір плитки визначається кількістю колон і шириною секції.';

  @override
  String get resetSectionToGlobal => 'Скинути налаштування до спільних значень';

  @override
  String get resetSectionToGlobalHint =>
      'Відновити спільні заголовки розділів, значки та фон і скинути відступи?';

  @override
  String get resetStyleSection => 'Скинути цей розділ';

  @override
  String get resetStyleSectionHint =>
      'Відновити налаштування за замовчуванням лише для цього розділу?';

  @override
  String get notificationStyle => 'Стиль сповіщень';

  @override
  String get styleBackgroundColor => 'Колір фону';

  @override
  String get styleTransparency => 'Прозорість фону';

  @override
  String get styleTextSize => 'Розмір тексту';

  @override
  String get styleTextColor => 'Колір тексту';

  @override
  String get noticeSize => 'Розмір сповіщення';

  @override
  String get noticeStylePreview => 'Попередній перегляд сповіщень';

  @override
  String get backupSyncHomeOptions => 'Поведінка та загальні параметри';

  @override
  String get backupSyncBackground => 'Фон і власні банери';

  @override
  String get backupSyncTiles => 'Плитка, меню та стиль сповіщень';

  @override
  String get backupSyncWeatherSource => 'Джерело та місцезнаходження';

  @override
  String get backupSyncWeatherDisplay =>
      'Відображення погоди та одиниці вимірювання температури';

  @override
  String get backupSyncNotificationSettings =>
      'Відображення та фільтри сповіщень';

  @override
  String get backupSyncOther => 'Інші налаштування';

  @override
  String get tileFocusBorderStyle => 'Стиль кордону';

  @override
  String get tileFocusOutline => 'Контур';

  @override
  String get tileFocusGlow => 'Світіння';

  @override
  String get tileFocusNoBorder => 'Без межі';

  @override
  String get tileShowFocusShadow => 'Показати тінь';

  @override
  String get homeLayoutRow => 'Горизонтальний ряд';

  @override
  String get homeLayoutRows => 'Кілька рядів';

  @override
  String get homeLayoutGrid => 'Сітка';

  @override
  String get homeCardCount => 'Видимі картки поперек';

  @override
  String get homeAuto => 'Авто';

  @override
  String get homeFree => 'Вільне прокручування';

  @override
  String get homeAnchored => 'Закріплений розділ';

  @override
  String get homeScrollMode => 'Прокрутка розділу';

  @override
  String get homeSectionPosition => 'Позиція активного розділу';

  @override
  String get homeLabelMode => 'Етикетки додатків';

  @override
  String get homeLabelNone => 'Без міток';

  @override
  String get homeLabelSelected => 'Лише вибрана програма';

  @override
  String get homeLabelAll => 'Всі програми';

  @override
  String get homeInherited => 'Успадкована цінність';

  @override
  String get homeOwnReset => 'Повернути спільні налаштування';

  @override
  String get homeParameters => 'Параметри';

  @override
  String get homeSectionStyle => 'Зовнішній вигляд розділу';

  @override
  String get homeSectionGap => 'Відстань між секціями';

  @override
  String get homeSectionIcons => 'Значки розділів';

  @override
  String get homeInactiveOpacity => 'Непрозорість неактивного розділу';

  @override
  String get homeResetSection => 'Відновити вигляд успадкованого розділу';

  @override
  String get homeCalculatedSize => 'Розмір розраховується за кількістю карток';

  @override
  String homeGapLimited(int gap) {
    return 'Інтервал обмежений $gap, щоб зберегти кількість вибраних карток.';
  }

  @override
  String get homeResetLayout => 'Скинути макет розділу';

  @override
  String homeVisibleRows(int count) {
    return 'Повністю видимі рядки: $count';
  }

  @override
  String get homeStylePartial =>
      'Застосовується лише до розділів, які успадковують це значення та підтримують його в поточному макеті.';

  @override
  String get homeStyleUnavailable =>
      'Недоступно в налаштуваннях поточного розділу. Перевірте макет і локальні перевизначення.';

  @override
  String get homeStyleNeedsRows => 'Доступно для кількох рядків або сітки.';

  @override
  String get homeStyleNeedsLabels =>
      'Увімкніть мітки, щоб змінити їх розмір і колір.';

  @override
  String get homeStyleNeedsAllLabels =>
      'Позиція застосовується лише до міток на всіх картках. Вибраний заголовок залишається під розділом.';

  @override
  String get homeStyleNeedsScale => 'Виберіть ефект збільшення фокуса.';

  @override
  String get homeStyleNeedsLift => 'Виберіть ефект підйому фокусу.';

  @override
  String get homeStyleNeedsBorder => 'Спочатку ввімкніть контур або світіння.';

  @override
  String get homeStyleNeedsTitle =>
      'Увімкніть назву розділу, щоб відобразити його значок.';

  @override
  String get homeStyleEconomy =>
      'Вимкнено через збереження пам\'яті. Збережене значення зберігається.';

  @override
  String get homeStyleOpaque =>
      'Зменшіть непрозорість фону плитки, щоб побачити розмиття.';

  @override
  String get homeStyleOverridden =>
      'Видимі розділи використовують власні значення. Виберіть «Використовувати глобальне» в розділі, щоб застосувати це налаштування.';

  @override
  String get homeStyleIconHint =>
      'Розмір значка впливає на картки із значком програми. Телебанери заповнюють картку самостійно.';

  @override
  String get homeStyleShadowHint =>
      'Збереження пам\'яті обмежує тінь неактивних карт до 4. Тінь фокуса налаштовується окремо.';

  @override
  String get homeStyleTransparent =>
      'Колір фону невидимий за нульової прозорості. Збільште непрозорість фону плитки.';

  @override
  String get homeStyleSingleColumn =>
      'Сітка в один стовпець не має горизонтальних розривів.';

  @override
  String get homeStyleAutoOnly =>
      'Розмір змінюється лише в розділах із автоматичним підрахунком карток, які успадковують глобальний розмір.';

  @override
  String get sleepTimerThirtySeconds => '30 секунд (тест)';

  @override
  String get sleepTimer => 'Таймер сну';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes мін';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours години',
      many: '$hours годин',
      few: '$hours години',
      one: '$hours година',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1,5 години';

  @override
  String get sleepTimerAllowExact => 'Дозволити точні таймери';

  @override
  String get sleepTimerExactRequired =>
      'Дозвольте точні таймери в налаштуваннях Android, а потім знову виберіть тривалість.';

  @override
  String get sleepTimerAccessRequired =>
      'Увімкніть доступність CuteLauncher або підключіть локальний ADB у Налаштуваннях → Інше → ADB.';

  @override
  String get sleepTimerFailed =>
      'Не вдалося встановити або завершити таймер сну. Перевірте доступність і локальний ADB.';

  @override
  String get nightIgnoreHdmiInputs => 'Ігнорувати введення HDMI';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'Зупиніть нічний фільтр під час перегляду HDMI. Потрібен доступ до використання; виявлення входу залежить від мікропрограми телевізора.';

  @override
  String get inputsSettings => 'Параметри введення';

  @override
  String get inputsUseCecNames => 'Використовуйте назви пристроїв із CEC';

  @override
  String get inputsNamesHint =>
      'Пріоритет імені: ваше ім’я в CuteLauncher → CEC (якщо ввімкнено) → ім’я з налаштувань Android → стандартне ім’я введення.';

  @override
  String get inputNameHint => 'Залиште порожнім для автоматичного імені';

  @override
  String get inputsSaveFailed => 'Не вдалося зберегти налаштування введення';

  @override
  String get inputIcon => 'Значок введення';

  @override
  String get inputIconTv => 'телевізор';

  @override
  String get inputIconGame => 'Ігрова консоль';

  @override
  String get inputIconComputer => 'комп\'ютер';

  @override
  String get inputIconReceiver => 'Приймач';

  @override
  String get inputIconDisc => 'Програвач дисків';

  @override
  String get inputIconStream => 'Потоковий пристрій';

  @override
  String get nightInputExclusions => 'Виключення вхідних даних';

  @override
  String get nightSelectInputs => 'Виберіть введення, які потрібно ігнорувати';

  @override
  String get nightNoInputsSelected =>
      'Вхідні дані не вибрано. Фільтр застосовуватиметься до кожного входу.';

  @override
  String get nightPictureExclusions => 'Виключення режиму зображення';

  @override
  String get nightPictureExclusionsHint =>
      'Виберіть режими, які призупиняють затемнення, тепле накладання та пов’язаний фільтр TCL. Розклад збережений. Виявлення було перевірено на TCL; доступ до використання не потрібен.';

  @override
  String get nightPictureUnavailable =>
      'Поточний режим зображення недоступний у цій мікропрограмі. Ваш вибір збережено; виключення застосовуються лише в разі успішного виявлення.';

  @override
  String get nightPictureCurrent => 'Поточний режим';

  @override
  String get nightPictureRefresh => 'Оновити поточний режим';

  @override
  String get nightPictureCode => 'Код режиму';

  @override
  String get nightPictureStandard => 'Стандартний';

  @override
  String get nightPictureDynamic => 'Динамічний';

  @override
  String get nightPictureMovie => 'фільм';

  @override
  String get nightPictureSport => 'спорт';

  @override
  String get nightPictureIntelligent => 'Розумний';

  @override
  String get nightPictureBright => 'Яскравий (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'Стандартний';

  @override
  String get systemApplications => 'Системні програми';

  @override
  String get removeFromCategory => 'Видалити з категорії';

  @override
  String get noRemovableCategories =>
      'Застосунок не додано вручну до жодного розділу. Зі стандартних автоматичних розділів («Усі», «Для ТБ», «Не для ТБ») видалити його не можна — скористайтеся «Приховати». «Обране» редагується вручну.';

  @override
  String get remoteButtonsTitle => 'Ремапер кнопок пульта';

  @override
  String get remoteButtonsStart => 'Перевірити кнопки (120 с)';

  @override
  String get remoteButtonsStop => 'Завершити перевірку';

  @override
  String get remoteButtonsHint =>
      'Перевірка показує коди, відпускання й повтори та зберігає текстовий звіт на ТВ. Запустіть перевірку й вийдіть зі сторінки, щоб OK не керував записом.';

  @override
  String get remoteButtonsEmpty =>
      'Подій поки немає. Якщо кнопка відкрила застосунок, поверніться сюди, щоб переглянути результат.';

  @override
  String get remoteButtonsService => 'Службу підключено';

  @override
  String get remoteButtonsRefresh => 'Оновити';

  @override
  String get remoteBindings => 'Призначення кнопок';

  @override
  String get remoteMappingsEnabled => 'Увімкнути перепризначення';

  @override
  String get remoteMappingsAdd => 'Додати призначення';

  @override
  String get remoteMappingKey => 'Кнопка';

  @override
  String get remoteMappingAction => 'Дія';

  @override
  String get remoteMappingLearn => 'Визначити кнопку пульта';

  @override
  String get remoteMappingLearnHint =>
      'Натисніть додаткову кнопку протягом 30 секунд. Навігацію, Power, голосовий пошук і гучність призначати не можна.';

  @override
  String get remoteMappingsHint =>
      'Для призначень потрібна служба спеціальних можливостей. У редакторі й під час діагностики вони призупинені. Home, Back, стрілки й OK зберігають навігацію.';

  @override
  String get remoteMappingsReset => 'Скинути призначення';

  @override
  String get remoteMappingsResetConfirm =>
      'Видалити всі призначення й вимкнути перепризначення?';

  @override
  String get remoteMappingInvalid =>
      'Не вдалося зберегти. Перевірте кнопку й ціль. Для webhook потрібен HTTPS або HTTP у локальній мережі.';

  @override
  String get remoteMappingBack => 'Назад';

  @override
  String get remoteMappingProfile => 'Профіль';

  @override
  String get remoteMappingChannels => 'Канали';

  @override
  String get remoteMappingQuickSettings => 'Швидкі налаштування TCL';

  @override
  String get remoteMappingTrigger => 'Тип натискання';

  @override
  String get remoteMappingPress => 'Коротке натискання';

  @override
  String get remoteMappingHold => 'Утримання';

  @override
  String get remoteMappingHoldHint =>
      'Утримуйте 650 мс: дія виконається один раз, без короткого натискання. Якщо призначено лише утримання, коротке натискання нічого не робить.';

  @override
  String get remotePanelDescription =>
      'Панель швидких налаштувань показує потрібні віджети поверх інших застосунків. Щоб відкривати її з пульта, призначте дію «Панель швидких налаштувань» на зручну кнопку.';

  @override
  String get remotePanel => 'Панель швидких налаштувань';

  @override
  String get remotePanelSettingsBackground => 'Колір тла як у налаштуваннях';

  @override
  String get remotePanelPreview => 'Відкрити панель';

  @override
  String get settingsHelp => 'Докладніше';

  @override
  String get settingsHelpScroll => '▲ / ▼ — читати текст';

  @override
  String get panelClockStyle => 'Оформлення годинника';

  @override
  String get clockPreset => 'Стиль шрифту';

  @override
  String get clockCustom => 'Власний варіант';

  @override
  String get clockWeight => 'Товщина шрифту';

  @override
  String get clockGlow => 'Світіння тексту';

  @override
  String get clockAnimate => 'Анімація цифр';

  @override
  String get clockBackground => 'Підкладка годинника';

  @override
  String get clockRadius => 'Заокруглення підкладки';

  @override
  String get dateCalendarEnabled => 'Відкривати календар натисканням на дату';

  @override
  String get calendarTitle => 'Календар';

  @override
  String get dateSettings => 'Налаштування дати';

  @override
  String get clockSharedBackground => 'Підкладка як в інших об’єктів';

  @override
  String get clockDefaultBackground => 'Типова підкладка';

  @override
  String get remotePanelInheritAppearance =>
      'Дублювати оформлення верхньої панелі';

  @override
  String get remotePanelDisabledInLauncher =>
      'Виклик панелі швидких налаштувань вимкнено, поки відкрито CuteLauncher.';

  @override
  String get remoteAccessSettings => 'Налаштування доступу';

  @override
  String get remoteButtonsTest => 'Перевірка кнопок';

  @override
  String remoteMappingDeleteConfirm(String name) {
    return 'Видалити призначення «$name»?';
  }

  @override
  String get remoteMappingConflict =>
      'Цю кнопку з таким типом натискання вже призначено. Виберіть іншу кнопку або тип натискання.';

  @override
  String get cleanerTitle => 'TV cleanup manager';

  @override
  String get cleanerRefresh => 'Refresh applications';

  @override
  String get cleanerSnapshot => 'Save original state';

  @override
  String get cleanerRestore => 'Відновитися з базової копії';

  @override
  String get cleanerSnapshotSaved => 'Original state saved';

  @override
  String get cleanerExportSnapshot => 'Export original state';

  @override
  String get cleanerSafe => 'Disable verified applications';

  @override
  String get cleanerNoSafe =>
      'Для цієї моделі та прошивки немає відповідного списку системних застосунків.';

  @override
  String get cleanerLocal => 'Disable using a local list';

  @override
  String get cleanerProject => 'Project catalog lists';

  @override
  String get cleanerRemoteProject => 'Refresh catalog from GitHub';

  @override
  String get cleanerExternal => 'CleanYourTV examples';

  @override
  String get cleanerDisabledExport => 'Експортувати звіт про вимкнення у файл';

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
      'Базовий стан створюється один раз під час першого успішного оновлення списку. Засобами лаунчера його не можна видалити чи перезаписати. Він прив’язаний до прошивки. Ручні стани зберігають режими застосунків з іменем і датою; їх можна відновлювати, видаляти й експортувати. Копії не містять APK і даних. Відновлення потребує локального ADB. Захист від падінь намагається автоматично повернути базовий стан. Очищення даних або видалення лаунчера видаляє копії; захист від root неможливий.';

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
  String get landscapeDemoStop => 'Стоп';

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
  String get informationGroup => 'Годинник, дата й погода';

  @override
  String get informationSettings => 'Налаштування блоку';

  @override
  String get informationAppearance => 'Оформлення блоку';

  @override
  String get informationSize => 'Загальний розмір блоку';

  @override
  String get informationPosition => 'Розташування годинника й тексту';

  @override
  String get informationClockLeft => 'Годинник ліворуч, текст праворуч';

  @override
  String get informationClockRight => 'Текст ліворуч, годинник праворуч';

  @override
  String get informationSpacing => 'Відстань між годинником і текстом';

  @override
  String get informationBackground => 'Тло блоку';

  @override
  String get homeResetTilesHint =>
      'Повернути спільні значення всіх параметрів плиток і підписів на цьому екрані?';

  @override
  String get homeResetLayoutHint =>
      'Скинути розкладку розділу, повернути спільне оформлення та обнулити поля? Застосунки та їхній порядок збережуться.';

  @override
  String get networkSummary => 'Мережа';

  @override
  String get networkConnected => 'Інтернет доступний';

  @override
  String get networkOffline => 'Немає доступу до інтернету';

  @override
  String get networkDisconnected => 'Немає підключення';

  @override
  String get networkConnection => 'Підключення';

  @override
  String get networkSignal => 'Сигнал';

  @override
  String get networkLinkSpeed => 'Швидкість з’єднання Wi-Fi';

  @override
  String get networkTrafficRate => 'Трафік пристрою · приймання / передавання';

  @override
  String get networkSystemSettings => 'Системні налаштування мережі';

  @override
  String get networkUnavailable => 'Недоступно';

  @override
  String get networkMobile => 'Мобільна мережа';

  @override
  String get networkFrequency => 'Частота';

  @override
  String get networkMbps => 'Мбіт/с';

  @override
  String get networkKbps => 'КБ/с';

  @override
  String get networkReadFailed => 'Не вдалося отримати стан мережі';

  @override
  String get clockItalic => 'Курсив';

  @override
  String get panelWrapNavigation => 'Кругова навігація панеллю';

  @override
  String get panelWrapNavigationHelp =>
      'Стрілки переводять фокус із крайньої кнопки на протилежний край. Утримуйте стрілку для безперервного переміщення обома сторонами.';

  @override
  String get networkReceive => 'Приймання';

  @override
  String get networkSend => 'Передавання';

  @override
  String get landscapeCelestialBodies => 'Сонце і місяць';

  @override
  String get landscapeStarRotation => 'Обертання зірок';

  @override
  String get tvPowerTitle => 'Керування живленням';

  @override
  String get tvPowerOff => 'Вимкнути ТВ';

  @override
  String get tvPowerReboot => 'Перезавантажити ТВ';

  @override
  String get tvPowerOffConfirm => 'Перевести ТВ у режим очікування?';

  @override
  String get tvPowerRebootConfirm =>
      'Перезавантажити ТВ? Відкриті застосунки буде закрито.';

  @override
  String get tvPowerSent => 'Команду надіслано';

  @override
  String get tvPowerFailed =>
      'Не вдалося надіслати команду. Перевірте ADB або спеціальні можливості.';

  @override
  String get tvPowerHelp =>
      'Вимкнення переводить ТВ в очікування через службу спеціальних можливостей CuteLauncher або локальний ADB. Перезавантаження потребує ADB. На приставці команда керує приставкою; поведінка ТВ залежить від HDMI-CEC і прошивки.';

  @override
  String get cleanerLists => 'Списки вимкнення';

  @override
  String get cleanerRecovery => 'Резервування та відновлення';

  @override
  String get cleanerExports => 'Звіти';

  @override
  String get cleanerUpdating => 'Оновлюється список застосунків…';

  @override
  String get cleanerRefreshRequired => 'Спочатку оновіть список застосунків.';

  @override
  String get cleanerPreinstalled => 'Попередньо встановлений застосунок';

  @override
  String get cleanerNotSystem => 'Це не системний застосунок.';

  @override
  String get cleanerMinimalRisk => 'Мінімальний';

  @override
  String get cleanerCacheFailure =>
      'Не вдалося зберегти список для наступного входу.';

  @override
  String get cleanerUserApps => 'Користувацькі застосунки';

  @override
  String get cleanerPreinstalledApps => 'Попередньо встановлені застосунки';

  @override
  String get cleanerSystemApps => 'Системні застосунки';

  @override
  String get cleanerBaseline => 'Базовий початковий стан';

  @override
  String get cleanerManualStates => 'Керування ручними станами';

  @override
  String get cleanerManualSave => 'Зберегти поточний стан';

  @override
  String get cleanerDateName => 'Використати дату й час';

  @override
  String get cleanerCustomName => 'Задати ім’я';

  @override
  String get cleanerStateExport => 'Експортувати збереження у файл';

  @override
  String get cleanerStateRestoreHelp =>
      'Буде відновлено збережені стани ввімкнення та вимкнення застосунків для цієї прошивки. Застосунки, встановлені після створення копії, не зміняться. Відсутні застосунки та вимкнення захищених компонентів буде пропущено. Дані застосунків не відновлюються.';

  @override
  String get cleanerCopiesHelp =>
      'Базовий стан створюється один раз під час першого успішного оновлення списку. Засобами лаунчера його не можна видалити чи перезаписати. Він прив’язаний до прошивки. Ручні стани зберігають режими застосунків з іменем і датою; їх можна відновлювати, видаляти й експортувати. Копії не містять APK і даних. Відновлення потребує локального ADB. Захист від падінь намагається автоматично повернути базовий стан. Очищення даних або видалення лаунчера видаляє копії; захист від root неможливий.';

  @override
  String get cleanerSearch => 'Пошук за назвою';

  @override
  String get cleanerCatalogUpdateRequired =>
      'Спочатку оновіть каталог із GitHub.';

  @override
  String get cleanerNoSearchResults => 'Відповідних записів немає.';

  @override
  String get cleanerAlreadyDisabled =>
      'Усі застосунки зі списку, наявні на цьому ТВ, уже вимкнено.';

  @override
  String get cleanerAlreadyEnabled =>
      'Усі застосунки зі списку, наявні на цьому ТВ, уже ввімкнено.';

  @override
  String get cleanerNoInstalled =>
      'На цьому ТВ немає відповідних установлених застосунків зі списку.';

  @override
  String get cleanerListProtected =>
      'Решта застосунків захищені від вимкнення.';

  @override
  String get cleanerSnapshotFailed =>
      'Не вдалося зберегти знімок. Застосунки не вимкнено.';

  @override
  String get cleanerDisableAllPreinstalled =>
      'Вимкнути всі попередньо встановлені';

  @override
  String get cleanerEnableAllPreinstalled =>
      'Увімкнути всі попередньо встановлені';

  @override
  String get cleanerPreinstalledList =>
      'Список попередньо встановлених застосунків';

  @override
  String cleanerBeforeList(String listName) {
    return 'Перед застосуванням списку: $listName';
  }

  @override
  String get sleepTimerSettings => 'Налаштування таймера вимкнення';

  @override
  String get sleepTimerPresets => 'Таймери';

  @override
  String get sleepTimerDisplay => 'Показувати під час роботи таймера';

  @override
  String get sleepTimerRemaining => 'Час, що залишився';

  @override
  String get sleepTimerEndTime => 'Час вимкнення';

  @override
  String get sleepTimerBoth => 'Залишок часу та час вимкнення';

  @override
  String get sleepTimerShowSeconds => 'Показувати секунди';

  @override
  String get sleepTimerCloseAfterSelection =>
      'Закривати віджет після вибору таймера';

  @override
  String get sleepTimerAdd => 'Додати таймер';

  @override
  String get sleepTimerEdit => 'Змінити таймер';

  @override
  String get sleepTimerHoursLabel => 'Години';

  @override
  String get sleepTimerMinutesLabel => 'Хвилини';

  @override
  String get sleepTimerSecondsLabel => 'Секунди';

  @override
  String get sleepTimerInvalidDuration =>
      'Укажіть час більше нуля: години 0–999999, хвилини та секунди 0–59.';

  @override
  String get sleepTimerDeleteConfirmation =>
      'Видалити цей таймер? Запущений відлік триватиме.';

  @override
  String get sleepTimerResetConfirmation =>
      'Відновити стандартні таймери та їхній порядок? Власні таймери буде видалено. Запущений відлік триватиме.';

  @override
  String get sleepTimerReorderHint =>
      '◄ / ► або утримання OK — переміщення. ▲ / ▼ змінюють порядок і переносять таймери між видимими та прихованими. OK завершує переміщення.';

  @override
  String get sleepTimerSaveFailed =>
      'Не вдалося зберегти налаштування таймера.';

  @override
  String get sleepTimerVisible => 'Відображувані';

  @override
  String get sleepTimerHidden => 'Приховані';

  @override
  String get sleepTimerReset => 'Скинути таймери';

  @override
  String get cleanerListSnapshotHelp =>
      'Перед вимкненням за списком автоматично зберігається знімок лише вибраних застосунків. Його відновлення не змінює інші застосунки. Ліміт — 100 ручних та автоматичних знімків. Без збереження вимкнення не починається.';

  @override
  String get trafficSettings => 'Налаштування трафіку';

  @override
  String get trafficTitle => 'Трафік';

  @override
  String get trafficReceived => 'Отримано';

  @override
  String get trafficSent => 'Надіслано';

  @override
  String get trafficTotal => 'Усього';

  @override
  String get stopApp => 'Стоп';

  @override
  String get backgroundImageFormats =>
      'Зображення: JPEG, PNG, WebP, GIF, BMP — до 8 МіБ, 48 мегапікселів і 16 384 пікселів на кожному боці.';

  @override
  String get backgroundMediaFormats =>
      'Зображення: JPEG, PNG, WebP, GIF, BMP — до 8 МіБ, 48 мегапікселів і 16 384 пікселів на кожному боці.\nВідео: MP4/M4V, WebM, MKV — до 256 МіБ і 3840×2160. Підтримка кодека залежить від ТВ; бажано MP4 з H.264. Повторюється без звуку й призупиняється поза головним екраном. Відео не входить до резервних копій.';

  @override
  String get backgroundFormatError =>
      'Формат не підтримується або файл пошкоджено. Виберіть справний файл одного із зазначених форматів.';

  @override
  String backgroundFileTooLarge(String maxMiB) {
    return 'Файл завеликий. Допустимий розмір — до $maxMiB МіБ. Виберіть менший файл.';
  }

  @override
  String get backgroundImageResolutionError =>
      'Зображення завелике: не більше 48 мегапікселів і 16 384 пікселів на кожному боці.';

  @override
  String get backgroundVideoResolutionError =>
      'Роздільність відео завелика. Виберіть до 3840×2160 (або 2160×3840).';

  @override
  String get backgroundVideoCodecError =>
      'ТВ не зміг відтворити відео: кодек не підтримується або файл пошкоджено. Спробуйте MP4 з H.264.';

  @override
  String get backgroundFileApplied => 'Файл вибрано. Фон оновлено.';

  @override
  String get noticePosition => 'Розташування сповіщень';

  @override
  String get noticeBottomRight => 'Унизу праворуч';

  @override
  String get noticeBottomLeft => 'Унизу ліворуч';

  @override
  String get noticeTopRight => 'Угорі праворуч';

  @override
  String get noticeTopLeft => 'Угорі ліворуч';

  @override
  String get notificationOpenFailed =>
      'Не вдалося відкрити дію сповіщення. Можливо, вона більше недоступна.';

  @override
  String get adbWifiOverride => 'Усе одно вимкнути…';

  @override
  String get adbWifiRiskTitle => 'Вимкнути попри ризик?';

  @override
  String get adbWifiRiskEffect =>
      'Буде вимкнено вбудований лаунчер і майстер налаштування Google.';

  @override
  String get adbWifiRiskLoss =>
      'Android може видалити збережені мережі Wi-Fi. З’єднання Wi-Fi та бездротовий ADB можуть стати недоступними.';

  @override
  String get adbWifiRiskRecovery =>
      'Повторне ввімкнення майстра не відновить видалені мережі автоматично. Потрібно буде знову підключитися до Wi-Fi та ввести пароль.';

  @override
  String get adbWifiRiskConsent =>
      'Продовжуйте, лише якщо знаєте пароль Wi-Fi.';

  @override
  String get adbWifiDisable => 'Вимкнути';

  @override
  String get recentAppsTitle => 'Відкриті програми';

  @override
  String get recentAppsPanelType => 'Панель';

  @override
  String get recentAppsAutomatic => 'Автоматично';

  @override
  String get recentAppsCustom => 'Панель CuteLauncher';

  @override
  String get recentAppsSystem => 'Вбудована панель';

  @override
  String get recentAppsOpen => 'Відкрити панель';

  @override
  String get recentAppsRefresh => 'Оновити';

  @override
  String get recentAppsCloseAll => 'Закрити все';

  @override
  String get recentAppsEmpty => 'Немає ТВ-програм із відкритими завданнями';

  @override
  String get recentAppsUnavailable =>
      'Панель відкритих програм недоступна. Перевірте ADB і спеціальні можливості.';

  @override
  String get recentAppsHelp =>
      'Показано лише ТВ-програми з відкритими завданнями. «Закрити все» зупиняє користувацькі програми з цього списку. Кнопка призначається в ремапері. Панелі CuteLauncher потрібні ADB і спеціальні можливості.';

  @override
  String get recentAppsHomeHint =>
      'Для Home доступне лише утримання. Коротке натискання повертає до CuteLauncher. Призначення діє і поза лаунчером.';

  @override
  String get sectionRulesHelp =>
      'Стандартні розділи можна перейменовувати, переміщувати й приховувати, але не видаляти; хоча б один має бути видимим. «Усі», «Для ТБ» та «Не для ТБ» заповнюються за типом запуску, а не назвою; приховування прибирає застосунок з усіх трьох. «Обране» та власні розділи заповнюються вручну. Порядок: вручну, за назвою, частотою чи останнім запуском; оформлення окреме. «Продовжити перегляд» показує рекомендації, його можна приховувати й переміщувати.';

  @override
  String get remoteMappingNamePlaceholder => 'Назва кнопки';

  @override
  String get remoteMappingAssign => 'Призначити кнопку';

  @override
  String get remoteMappingCapture => 'Захопити';

  @override
  String remoteMappingCaptured(String key) {
    return 'Захоплена кнопка: $key';
  }

  @override
  String get remoteMappingCaptureHint =>
      'Натисніть «Захопити», потім кнопку пульта. Захоплення можна повторити. Натисніть ОК для підтвердження.';

  @override
  String get remoteMappingCaptureTimeout =>
      'Кнопку не захоплено. Спробуйте знову.';

  @override
  String get remoteMappingCaptureFailed =>
      'Не вдалося захопити кнопку. Перевірте службу спеціальних можливостей.';

  @override
  String get remoteMappingServiceRequired =>
      'Підключіть службу спеціальних можливостей у налаштуваннях доступу.';

  @override
  String get remoteMappingKeyRequired =>
      'Кнопку не призначено. Натисніть «Призначити кнопку» та захопіть її.';

  @override
  String get remoteMappingHomeHoldRequired => 'Для Home виберіть «Утримання».';

  @override
  String get remoteMappingAppRequired => 'Виберіть програму для запуску.';

  @override
  String get remoteMappingUrlRequired => 'Введіть або імпортуйте Webhook URL.';

  @override
  String get remoteMappingUrlInvalid =>
      'Неправильний URL. Потрібен HTTPS або локальний HTTP зі шляхом, без пробілів, облікових даних і фрагмента #.';

  @override
  String get remoteMappingSaveFailed =>
      'Не вдалося зберегти. Повторіть; значення залишилися в редакторі.';

  @override
  String get remoteMappingDeleteFailed =>
      'Не вдалося видалити. Спробуйте знову.';

  @override
  String get remoteMappingRecents => 'Панель відкритих програм';

  @override
  String get remoteMappingImport => 'Імпортувати URL з файлу';

  @override
  String get remoteMappingImportHint =>
      'Виберіть файл UTF-8 лише з Webhook URL, без команд і пояснень. Переноси рядків видаляються.';

  @override
  String get remoteMappingImportInvalid =>
      'Файл має містити лише правильний Webhook URL: HTTPS або локальний HTTP, без команд і пояснень.';

  @override
  String get remoteMappingImportFailed =>
      'Не вдалося прочитати. Виберіть доступний файл UTF-8 розміром до 64 КБ.';
}
