// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get scrollContentLabels => 'Прокрутка длинных подписей в лентах';

  @override
  String get contentAppTileStyle => 'Источник оформления';

  @override
  String get contentTileOwnAppearance => 'Своё оформление';

  @override
  String get contentTileCommonAppearance => 'Общее оформление';

  @override
  String get contentUseSourceLabels =>
      'Использовать подписи из выбранного оформления';

  @override
  String get contentLabelSelected => 'Только выбранная карточка';

  @override
  String get contentLabelAll => 'Все карточки';

  @override
  String get weatherTextResetFormat => 'Сбросить формат';

  @override
  String get settingsReportFile => 'Файл отчёта';

  @override
  String get homeVisibleRowsLabel => 'Полностью видимых строк';

  @override
  String get watchNextEmpty => 'Карточек «Продолжить просмотр» пока нет';

  @override
  String get inputsUnavailableStatus => 'Доступных входов нет';

  @override
  String get remoteButtonsNoEvents => 'Событий пока нет';

  @override
  String get informationBackgroundVerticalOffset => 'Смещение по вертикали';

  @override
  String get informationResetPositionSize => 'Сбросить все настройки экрана';

  @override
  String get weatherIconsGeometric => 'Геометрические';

  @override
  String get weatherIconsCircled => 'В круге';

  @override
  String get informationCommonAppearance => 'Общие настройки';

  @override
  String get informationTimeFormat => 'Формат времени';

  @override
  String get informationDateFormat => 'Формат даты';

  @override
  String get informationInheritPanelTypography =>
      'Наследовать оформление верхней панели';

  @override
  String get informationResetTypography => 'Сбросить настройки';

  @override
  String get alignSectionTitles => 'Выровнять заголовки по плиткам';

  @override
  String get homeAppName => 'Имя на главном экране';

  @override
  String get restoreSystemAppName => 'Вернуть системное имя';

  @override
  String get settingsScrollbar => 'Полоса прокрутки';

  @override
  String get settingsScrollbarHidden => 'Скрывать полностью';

  @override
  String get settingsScrollbarOnScroll => 'Показывать в момент прокрутки';

  @override
  String get settingsScrollbarAlways => 'Показывать всегда';

  @override
  String get volumeKeysTitle => 'Удержание громкости';

  @override
  String get volumeKeysMode => 'Способ исправления';

  @override
  String get volumeKeysAuto => 'Авто: пока видна панель';

  @override
  String get volumeKeysTimed => 'Пауза по таймеру';

  @override
  String get volumeKeysRepeat => 'Собственный повтор';

  @override
  String get volumeKeysDuration => 'Длительность паузы';

  @override
  String get volumeKeysHelp =>
      'На некоторых Android TV и Google TV перехват кнопок через спецвозможности нарушает системный повтор громкости. Это может затрагивать все приложения, пока служба включена.\n\n«Авто: пока видна панель» — рекомендуемый режим по умолчанию при включении ремаппера. При появлении индикатора снимается фильтр кнопок. После выбранной паузы проверяется окно: пока оно видно, пауза продлевается, но не дольше минуты. Если окно недоступно, используется таймер.\n\n«Пауза по таймеру» возвращает фильтр через выбранные 3, 5, 10, 15 или 30 секунд после последнего распознанного появления панели. Попробуйте этот способ, если «Авто» работает нестабильно; увеличьте время, если пауза слишком короткая.\n\n«Собственный повтор» сам меняет громкость до отпускания кнопки. Он работает только на прошивках, передающих службе нажатие и отпускание громкости. Если события не приходят, способ не поможет; возможен и двойной шаг. При неправильной работе выберите другой режим.\n\nВо время паузы временно недоступны назначения кнопок и перехват Home. Первое удержание может дать один шаг: отпустите кнопку и удерживайте снова, пока индикатор виден. «Отключено» возвращает штатную обработку громкости, сохраняя назначения. Явно выбранный режим сохраняется при выключении и повторном включении ремаппера.';

  @override
  String get fileStorageSettingsUnavailable =>
      'На этой прошивке недоступен экран доступа ко всем файлам. Используйте внешний проводник или установите совместимый файловый менеджер.';

  @override
  String get tileImageMode => 'Изображение плитки';

  @override
  String get tileBannerImageMode => 'Приложения с баннером';

  @override
  String get tileIconImageMode => 'Приложения без баннера';

  @override
  String get tileImageContain => 'Без растягивания';

  @override
  String get tileImageCover => 'С растягиванием';

  @override
  String get tileImageEdgeColor => 'Без растягивания с цветом края';

  @override
  String get tileImageIcon => 'Иконка с цветом края';

  @override
  String get tileImageModeHelp =>
      'Для приложений с баннером и без него режимы выбираются отдельно. Режим применяется, если форма плитки обрезает картинку или остаются пустые края. Можно показать изображение целиком, увеличить с обрезкой без искажения пропорций или заполнить свободную область цветом ближайшего края. Замена баннера иконкой с цветом её края доступна только для приложений с баннером. Настройка размера значка сохраняется.';

  @override
  String get wallhavenWallpaperHint =>
      'Случайные обои Wallhaven по выбранной теме: SFW, 16:9, от Full HD. Без регистрации и API-ключа. Обновление работает при открытом лаунчере; при ошибке сохраняются прежние обои.';

  @override
  String get renderCompatibilityTitle => 'Совместимый вывод графики';

  @override
  String get renderCompatibilityAutomatic =>
      'Включён автоматически для этого устройства';

  @override
  String get renderCompatibilityApply => 'Применить и перезапустить лаунчер';

  @override
  String get renderCompatibilityFailed =>
      'Не удалось прочитать или применить настройку';

  @override
  String get renderCompatibilityHelp =>
      'Попробуйте этот режим, если интерфейс мерцает при ночном затемнении. На проверенных моделях он включается автоматически. На других ТВ выбор сохраняется только на этом устройстве и применяется после перезапуска лаунчера. Может увеличить нагрузку на графику.';

  @override
  String get diagnosticsHubTitle => 'Диагностика';

  @override
  String get tvCompatibilityTitle => 'Проверка TV на совместимость';

  @override
  String get tvCompatibilityRun => 'Запустить проверку';

  @override
  String get tvCompatibilityResults => 'Просмотреть результаты';

  @override
  String get compatibilityReportDate => 'Дата проверки';

  @override
  String get compatibilityLauncherVersion => 'Версия CuteLauncher';

  @override
  String get diagnosticsExport => 'Экспортировать отчёт';

  @override
  String get diagnosticsCopyClipboard => 'Копировать в буфер обмена';

  @override
  String get diagnosticsSaveDisk => 'Сохранить на диск';

  @override
  String get tvCompatibilityHelp =>
      'Проверка читает сведения об устройстве, прошивке, разрешениях и доступности системных функций. Настройки, пакеты и HOME не меняются; ADB не подключается, приложения и системные окна не запускаются. Результаты описывают доступность по данным Android, а не работу физического пульта, HDMI или всей функции. Отчёт можно сохранить для каталога устройств: в нём есть модель и полная идентификация прошивки, но нет серийника, IP, Wi-Fi-сетей, аккаунтов и списка приложений. Автоматической отправки нет. Последний отчёт хранится в памяти до выхода из раздела «Диагностика»; новая проверка заменяет его.';

  @override
  String get compatibilityAndroidTv => 'Поддержка Android TV';

  @override
  String get compatibilityAndroidVersion => 'Версия Android';

  @override
  String get compatibilityHomeRegistered => 'Регистрация CuteLauncher как HOME';

  @override
  String get compatibilityDefaultHome => 'CuteLauncher выбран домашним экраном';

  @override
  String get compatibilityHomeSelection => 'Приоритет выбора HOME';

  @override
  String get compatibilityOverlay => 'Показ поверх приложений';

  @override
  String get compatibilityNotifications => 'Уведомления CuteLauncher';

  @override
  String get compatibilityNotificationListener => 'Чтение уведомлений';

  @override
  String get compatibilityAccessibility => 'Служба специальных возможностей';

  @override
  String get compatibilityWriteSettings => 'Изменение системных настроек';

  @override
  String get compatibilityUsageStats => 'Доступ к статистике использования';

  @override
  String get compatibilityWatchNext => 'Доступ к «Продолжить просмотр»';

  @override
  String get compatibilityTvInputs => 'Системный список ТВ-входов';

  @override
  String get compatibilityDocumentExport => 'Обработчик экспорта JSON';

  @override
  String get compatibilityScreensaverSelection => 'Системный выбор заставки';

  @override
  String get compatibilityAvailable => 'Доступно по данным Android';

  @override
  String get compatibilityNotGranted => 'Разрешение не выдано';

  @override
  String get compatibilityNotConfigured => 'Не настроено или список пуст';

  @override
  String get compatibilityRestricted => 'Обнаружено системное ограничение';

  @override
  String get compatibilityUnsupported => 'Поддержка не обнаружена';

  @override
  String get compatibilityUnknown => 'Не удалось определить';

  @override
  String get appArtworkBackground => 'Цвета выбранного приложения';

  @override
  String get appArtworkBackgroundHelp =>
      'Баннер или значок выбранного приложения создаёт мягкий цветной фон. До загрузки изображения или при ошибке показывается выбранный градиент. В фоне лаунчера обработка приостанавливается. Остальные обои сохраняются.';

  @override
  String get adbWifiOwnedTitle => 'Wi-Fi принадлежит мастеру настройки';

  @override
  String get adbWifiOwned =>
      'Изменения не внесены: сохранённая Wi-Fi-сеть создана мастером настройки Google. Его отключение может удалить сеть и отключить ТВ от интернета.\n\n1. Убедитесь, что знаете пароль Wi-Fi.\n2. Откройте настройки сети Android, выберите эту сеть и нажмите «Забыть сеть».\n3. Подключитесь заново через обычные настройки сети Android.\n4. Вернитесь в CuteLauncher, проверьте ADB и повторите отключение встроенного лаунчера.\n\nЕсли сообщение появляется снова, оставьте встроенный лаунчер включённым: прошивка может снова назначать сеть мастеру настройки.';

  @override
  String get adbWifiUnknown =>
      'Изменения не внесены: не удалось проверить владельцев сохранённых Wi-Fi-сетей. Отключение мастера настройки заблокировано для защиты соединения. Проверьте ADB и повторите попытку; некоторые прошивки не предоставляют эти сведения.';

  @override
  String get backgroundSource => 'Источник фона';

  @override
  String get noAvailableCategories =>
      'Нет разделов, в которые можно добавить это приложение.';

  @override
  String get redditWallpaperTheme => 'Тема обоев';

  @override
  String get redditThemeAll => 'Разные';

  @override
  String get redditThemeNature => 'Природа';

  @override
  String get redditThemeSpace => 'Космос';

  @override
  String get redditThemeCity => 'Города';

  @override
  String get redditThemeMinimal => 'Минимализм';

  @override
  String get redditWallpaperResolution => 'Минимальное разрешение';

  @override
  String get redditWallpaperHint =>
      'Каждое успешное обновление скачивает другую горизонтальную картинку из выбранного сообщества Reddit. Разрешение — минимальный размер оригинала, без увеличения. Обновление работает при открытом лаунчере и возобновляется при возвращении. Контент 18+, видео и галереи пропускаются. Если Reddit блокирует доступ или подходящих картинок нет, остаются прежние обои.';

  @override
  String get dialogCommandDetails => 'Показать команды ADB';

  @override
  String get dialogAssign => 'Назначить';

  @override
  String get dialogApply => 'Применить';

  @override
  String get settingsValueNotSet => 'Не задано';

  @override
  String get settingsMenuPosition => 'Расположение меню настроек';

  @override
  String get settingsMenuLeft => 'Слева';

  @override
  String get settingsMenuRight => 'Справа';

  @override
  String get actionCompleted => 'Действие выполнено';

  @override
  String get showRepositoryQrCode => 'Показать qrcode';

  @override
  String get resetSections => 'Сбросить настройки разделов';

  @override
  String get resetSectionsConfirmation =>
      'Восстановить стандартные разделы? Пользовательские разделы, разделители и состав избранного будут удалены.';

  @override
  String get cardFocusMode => 'Фокус при возврате домой';

  @override
  String get cardFocusRemember => 'Сохранять выбранную карточку';

  @override
  String get cardFocusFirst => 'На первую карточку';

  @override
  String get cardFocusSettings => 'На кнопку настроек';

  @override
  String get aboutFlauncher => 'О программе CuteLauncher';

  @override
  String get addCategory => 'Добавить раздел';

  @override
  String get addSection => 'Добавить раздел';

  @override
  String get alphabetical => 'По алфавиту';

  @override
  String get appCardHighlightAnimation => 'Пульсация рамки выделения';

  @override
  String get appInfo => 'Информация о приложении';

  @override
  String get appKeyClick => 'Звуки нажатий';

  @override
  String get applications => 'Приложения';

  @override
  String get autoHideAppBar => 'Автоскрытие строки состояния';

  @override
  String get backButtonAction => 'Действие кнопки назад';

  @override
  String get category => 'Раздел';

  @override
  String get categories => 'Разделы';

  @override
  String get columnCount => 'Количество столбцов';

  @override
  String get date => 'Дата';

  @override
  String get dateAndTimeFormat => 'Формат даты и времени';

  @override
  String get delete => 'Удалить';

  @override
  String get dialogOptionBackButtonActionFirstFeedCard =>
      'На первую карточку текущего раздела';

  @override
  String get dialogOptionBackButtonActionSectionStartThenUp =>
      'На первую карточку, затем по разделам вверх';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'Ничего не делать';

  @override
  String get dialogOptionBackButtonActionShowScreensaver => 'Показать заставку';

  @override
  String get dialogOptionBackButtonActionShowClock => 'Показать часы';

  @override
  String get dialogTextNoFileExplorer =>
      'Пожалуйста, установите файловый менеджер, чтобы выбрать изображение.';

  @override
  String get dialogTitleBackButtonAction => 'Выберите действие кнопки назад';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (Раздел)';
  }

  @override
  String formattedDate(String dateString) {
    return 'Форматированная дата: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'Форматированное время: $timeString';
  }

  @override
  String get gradient => 'Градиент';

  @override
  String get favoriteApps => 'Избранные приложения';

  @override
  String get grid => 'Сетка';

  @override
  String get height => 'Высота';

  @override
  String get hide => 'Скрыть';

  @override
  String get hiddenApplications => 'Скрытые приложения';

  @override
  String get launcherSections => 'Разделы';

  @override
  String get layout => 'Макет';

  @override
  String get loading => 'Загрузка';

  @override
  String get manual => 'Вручную';

  @override
  String get modifySection => 'Изменить раздел';

  @override
  String get mustNotBeEmpty => 'Не должно быть пустым';

  @override
  String get name => 'Имя';

  @override
  String get newSection => 'Новый раздел';

  @override
  String get noDateFormatSpecified => 'Формат даты не указан';

  @override
  String get noTimeFormatSpecified => 'Формат времени не указан';

  @override
  String get nonTvApplications => 'Приложения не для ТВ';

  @override
  String get open => 'Открыть';

  @override
  String get orSelectFormatSpecifiers => 'Или выберите спецификаторы формата';

  @override
  String get openImage => 'Выбрать файл';

  @override
  String get picture => 'Локальное изображение или видео';

  @override
  String removeFrom(String name) {
    return 'Удалить из $name';
  }

  @override
  String get renameCategory => 'Переименовать раздел';

  @override
  String get reorder => 'Изменить порядок';

  @override
  String get row => 'Строка';

  @override
  String get rowHeight => 'Высота строки';

  @override
  String get save => 'Сохранить';

  @override
  String get spacer => 'Разделитель';

  @override
  String get spacerMaxHeightRequirement =>
      'Должно быть больше 0 и меньше или равно 500';

  @override
  String get statusBar => 'Строка состояния';

  @override
  String get settings => 'Настройки';

  @override
  String get show => 'Показать';

  @override
  String get showCategoryTitles => 'Показывать заголовки разделов';

  @override
  String get themes => 'Темы';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'Скрыть контур выделения на главном экране';

  @override
  String get appSelectorTransitionAnimation => 'Плавное перемещение выделения';

  @override
  String get sort => 'Сортировать';

  @override
  String get systemSettings => 'Настройки Android';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — лаунчер для Android TV на основе LTvLauncher от LeanBitLab и FLauncher от Étienne Fesser.\n\nCuteLauncher: Kirill Shchetinnikov. Лицензия GNU GPLv3.\nРепозиторий: $repoUrl.';
  }

  @override
  String get textEmptyCategory => 'Этот раздел пуст.';

  @override
  String get time => 'Время';

  @override
  String get titleStatusBarSettingsPage =>
      'Выберите, что отображать в строке состояния';

  @override
  String get tvApplications => 'ТВ-приложения';

  @override
  String get type => 'Тип';

  @override
  String get typeInTheDateFormat => 'Введите формат даты';

  @override
  String get typeInTheHourFormat => 'Введите формат времени';

  @override
  String get uninstall => 'Удалить';

  @override
  String get wallpaper => 'Обои';

  @override
  String get withEllipsisAddTo => 'Добавить в...';

  @override
  String get timeBasedWallpaper => 'Дневное/Ночное изображение';

  @override
  String get pickDayWallpaper => 'Выбрать дневное изображение';

  @override
  String get pickNightWallpaper => 'Выбрать ночное изображение';

  @override
  String get accessibility => 'Специальные возможности';

  @override
  String get defaultLauncherIsDefault =>
      'CuteLauncher является лаунчером по умолчанию';

  @override
  String get defaultLauncherNotDefault =>
      'CuteLauncher не является лаунчером по умолчанию';

  @override
  String get setAsDefaultLauncher => 'Установить как лаунчер по умолчанию';

  @override
  String get defaultLauncherDescription =>
      'При установке в качестве лаунчера по умолчанию кнопка «Домой» всегда будет возвращать к CuteLauncher. ТВ также будет загружаться напрямую в CuteLauncher.';

  @override
  String get inputs => 'Входы';

  @override
  String get inputsUnavailableHint =>
      'Устройство не предоставляет доступных входов. Переключатель недоступен, значок скрыт. На ТВ-приставке этот пункт не управляет HDMI-входами подключённого телевизора.';

  @override
  String get inputSources => 'Источники ввода';

  @override
  String get backupAndRestore => 'Резервное копирование и восстановление';

  @override
  String get exportBackup => 'Экспорт резервной копии';

  @override
  String get importBackup => 'Импорт резервной копии';

  @override
  String exportSuccess(String path) {
    return 'Резервная копия успешно экспортирована в $path';
  }

  @override
  String get importSuccess => 'Резервная копия успешно импортирована';

  @override
  String get importConfirm =>
      'Импортировать эту резервную копию? Сохранённые корректные настройки и макет будут применены. Отсутствующие или некорректные отдельные настройки сохранят текущие значения.';

  @override
  String get importError =>
      'Не удалось восстановить настройки из резервной копии. Проверьте файл и повторите попытку.';

  @override
  String exportError(String error) {
    return 'Не удалось экспортировать резервную копию: $error';
  }

  @override
  String get shareBackup => 'Поделиться резервной копией';

  @override
  String get shareBackupDescription =>
      'Поделиться резервной копией с другими устройствами в локальной сети';

  @override
  String get stopSharing => 'Остановить доступ';

  @override
  String get localNetworkSharingActive => 'Доступ в локальной сети активен!';

  @override
  String get localNetworkSharingInstructions =>
      'Подключите другое устройство к той же сети Wi-Fi и откройте следующий URL-адрес в веб-браузере:';

  @override
  String get localNetworkSharingDetails =>
      'Здесь вы можете скачать настройки/макет вашего ТВ или загрузить файл резервной копии обратно на этот ТВ.';

  @override
  String failedToStartServer(String error) {
    return 'Не удалось запустить сервер общего доступа: $error';
  }

  @override
  String get notificationBell => 'Значок уведомлений';

  @override
  String get autoHideNotificationBell => 'Скрывать значок без уведомлений';

  @override
  String get continueWatching => 'Продолжить просмотр';

  @override
  String get showContinueWatchingOnHome =>
      'Показывать «Продолжить просмотр» на главном экране';

  @override
  String get permissionDeniedContinueWatching =>
      'Требуется разрешение для показа «Продолжить просмотр»';

  @override
  String get interface => 'Интерфейс';

  @override
  String get system => 'Система';

  @override
  String get accentColor => 'Акцентный цвет';

  @override
  String get miscellaneous => 'Разное';

  @override
  String get brightnessScheduler => 'Планировщик яркости';

  @override
  String get screensaverSettings => 'Выбрать заставку в Android TV';

  @override
  String get screensaverClockStyle => 'Стиль часов заставки';

  @override
  String get dataUsagePeriod => 'Период подсчёта трафика';

  @override
  String get notificationAccess => 'Доступ к уведомлениям';

  @override
  String get granted => 'Предоставлено';

  @override
  String get permissionRequired => 'Требуется разрешение';

  @override
  String get systemWidePopupAlert => 'Уведомления поверх других приложений';

  @override
  String get overlayPermissionRequired =>
      'Требуется разрешение показывать поверх других приложений';

  @override
  String get enabled => 'Включено';

  @override
  String get disabled => 'Отключено';

  @override
  String get showAppNamesBelowIcons => 'Показывать подписи приложений';

  @override
  String get dataUsage => 'Использование данных';

  @override
  String get networkIndicator => 'Индикатор сети';

  @override
  String get homeButtonFix => 'Кнопка «Домой»';

  @override
  String get startOnBoot => 'Запускать при включении ТВ';

  @override
  String get appLanguage => 'Язык';

  @override
  String get systemDefault => 'Системный по умолчанию';

  @override
  String get english => 'Английский';

  @override
  String get spanish => 'Испанский';

  @override
  String get ukrainian => 'Украинский';

  @override
  String get chinese => 'Китайский';

  @override
  String get french => 'Французский';

  @override
  String get german => 'Немецкий';

  @override
  String get japanese => 'Японский';

  @override
  String get portuguese => 'Португальский';

  @override
  String get russian => 'Русский';

  @override
  String get italian => 'Итальянский';

  @override
  String get hindi => 'Хинди';

  @override
  String get korean => 'Корейский';

  @override
  String get arabic => 'Арабский';

  @override
  String get turkish => 'Турецкий';

  @override
  String get hidePersistentNotifications => 'Скрыть постоянные уведомления';

  @override
  String get hidePersistentNotificationsDesc =>
      'Скрывать фоновые и системные уведомления';

  @override
  String get blockedNotificationApps => 'Блокировка уведомлений от приложений';

  @override
  String get blockAppNotifications => 'Блокировать уведомления';

  @override
  String get unblockAppNotifications => 'Разблокировать уведомления';

  @override
  String get noBlockedApps => 'Нет заблокированных приложений';

  @override
  String get persistentNotification => 'Постоянное';

  @override
  String get unblockAll => 'Разблокировать все';

  @override
  String get weather => 'Погода';

  @override
  String get showWeatherWarnings =>
      'Показывать предупреждения о погоде и дожде';

  @override
  String get temperatureUnit => 'Единица температуры';

  @override
  String get celsius => 'Цельсий (°C)';

  @override
  String get fahrenheit => 'Фаренгейт (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Установите Breezy Weather и включите \'Локальный обмен данными\' / \'Gadgetbridge\' в его настройках для отображения погоды и предупреждений.';

  @override
  String get displayAndScreensaver => 'Ночной режим и яркость';

  @override
  String get notifications => 'Уведомления';

  @override
  String get continueWatchingDescription =>
      'Показывать недавно просмотренные фильмы и передачи на главном экране';

  @override
  String get continueWatchingPermissionDesc =>
      'Для чтения истории просмотров из ТВ-приложений требуется специальное разрешение:';

  @override
  String get requestPermission => 'Запросить разрешение';

  @override
  String get dismiss => 'Закрыть';

  @override
  String get openApp => 'Открыть';

  @override
  String get notificationOptions => 'Параметры уведомления';

  @override
  String get noBlockedAppsDesc =>
      'Всем приложениям в данный момент разрешено показывать уведомления';

  @override
  String get notificationsAllowed => 'Уведомления разрешены';

  @override
  String get notificationsBlocked => 'Уведомления заблокированы';

  @override
  String get dpadDismissHint =>
      '◄ — закрыть · OK — параметры · ► — блокировать приложение';

  @override
  String get watchNextDeleteError =>
      'Не удалось удалить карточку из «Продолжить просмотр». Попробуйте ещё раз.';

  @override
  String get hideLauncherTile => 'Скрывать CuteLauncher в сетке приложений';

  @override
  String get hideAndroidSettingsTile =>
      'Скрывать настройки Android в плитках приложений';

  @override
  String get animateTileReordering => 'Плавная перестановка плиток';

  @override
  String get imageInputRejected =>
      'Изображение повреждено или слишком большое (не более 8 МиБ и 48 мегапикселей). Выберите другое изображение.';

  @override
  String get memoryAdvanced => 'Расширенная диагностика';

  @override
  String get memoryLauncherTitle => 'Память CuteLauncher';

  @override
  String get memoryUsage => 'Использование памяти';

  @override
  String memoryChange(String delta) {
    return '$delta к прошлому замеру';
  }

  @override
  String get memoryCacheFiles => 'Файлы изображений в памяти';

  @override
  String memoryCacheEntries(int count) {
    return 'Элементов: $count';
  }

  @override
  String memoryCacheResult(String before, String after) {
    return 'Кеши изображений: $before → $after';
  }

  @override
  String get memoryStale =>
      'Не удалось обновить данные. Показан предыдущий замер.';

  @override
  String get memoryTechnical => 'Технические показатели';

  @override
  String get memoryObserve => 'Наблюдение за памятью';

  @override
  String get memoryObserveStart => 'Наблюдать 1 минуту';

  @override
  String get memoryObserveStop => 'Остановить наблюдение';

  @override
  String get memoryObserveRunning => 'Идёт запись · до 1 минуты';

  @override
  String get memoryObserveFinished => 'Запись остановлена';

  @override
  String get memoryObserveEmpty => 'Замеров пока нет';

  @override
  String memorySeconds(int seconds) {
    return '$seconds с';
  }

  @override
  String get memoryReadingHelp => 'Как читать показатели';

  @override
  String get memorySaverHelp => 'Что меняет экономия';

  @override
  String get memorySaveFailed =>
      'Не удалось сохранить режим экономии. Повторите попытку.';

  @override
  String get memoryTitle => 'Память';

  @override
  String get memoryRefresh => 'Измерить память';

  @override
  String get memoryMeasuring => 'Измерение…';

  @override
  String get memoryClear => 'Очистить кеши изображений';

  @override
  String get memorySaver => 'Экономия памяти';

  @override
  String get memorySaverDescription =>
      'В режиме экономии:\n\n• Уменьшаются кэши изображений и окно предзагрузки постеров.\n• Отключаются размытие плиток, панели и фона обоев, а также пульсация рамки.\n• Ограничиваются тени невыбранных плиток.\n• Кэши очищаются при уходе приложения в фон.\n\nЭти эффекты недоступны в настройках, пока включена экономия. Их сохранённые значения восстанавливаются после отключения режима. Изображения могут загружаться чаще.';

  @override
  String get memoryPss => 'Доля памяти процесса (PSS)';

  @override
  String get memoryRss => 'Резидентная память процесса (RSS)';

  @override
  String get memoryEncodedCache => 'Кеш байтов изображений';

  @override
  String get memoryDecodedCache => 'Кеш декодированных изображений';

  @override
  String get memoryUnavailable => 'Недоступно';

  @override
  String get memoryUnit => 'МиБ';

  @override
  String get memoryMeasuredAt => 'Время замера';

  @override
  String get memoryExplanation =>
      'PSS и RSS пересекаются: их нельзя складывать. Кеши входят в память приложения и не отражают всю память активных изображений. Очистка сохраняет настройки и файлы; изображения загрузятся снова при необходимости. Android может вернуть память позже. RSS здесь получен из ядра, а PSS — из Android: они могут по-разному учитывать графическую память.';

  @override
  String get memoryRecommendations =>
      'Чтобы снизить расход памяти, включите экономию, уменьшите число карточек «Продолжить просмотр» и используйте обои меньшего размера или градиент.';

  @override
  String get memoryMeasurementFailed =>
      'Замер процесса недоступен. Сведения о кешах показаны отдельно.';

  @override
  String get addToCategory => 'Добавить в раздел';

  @override
  String get addToFavorites => 'Добавить в избранное';

  @override
  String get removeFromFavorites => 'Удалить из избранного';

  @override
  String get setCustomBanner => 'Выбрать свой баннер';

  @override
  String get clearCustomBanner => 'Убрать свой баннер';

  @override
  String get bannerSetFailed =>
      'Не удалось установить баннер. Проверьте доступ к изображению и выберите файл заново.';

  @override
  String get bannerClearFailed =>
      'Не удалось убрать пользовательский баннер. Повторите попытку.';

  @override
  String get grantUsagePermission =>
      'Разрешить доступ к статистике использования';

  @override
  String get removeFromContinueWatching => 'Удалить из «Продолжить просмотр»';

  @override
  String hideAllFromApp(String appName) {
    return 'Скрыть всё из $appName';
  }

  @override
  String get playResume => 'Начать / продолжить просмотр';

  @override
  String openNamedApp(String appName) {
    return 'Открыть $appName';
  }

  @override
  String get selectedAccent => 'Выбранный акцент';

  @override
  String get homeButtonFixHint =>
      'В Google TV включите «Перехват кнопки „Домой“» в специальных возможностях, чтобы эта кнопка открывала CuteLauncher.';

  @override
  String get accessibilityPermission => 'Доступ к специальным возможностям';

  @override
  String get shareFailed => 'Ошибка общего доступа';

  @override
  String shareBackupError(String error) {
    return 'Не удалось открыть общий доступ к резервной копии: $error';
  }

  @override
  String get exportComplete => 'Экспорт завершён';

  @override
  String get exportFailed =>
      'Не удалось сохранить резервную копию. Проверьте доступ к папке и свободное место.';

  @override
  String backupLoadError(String error) {
    return 'Не удалось загрузить список резервных копий: $error';
  }

  @override
  String get noBackupFiles => 'Резервные копии не найдены.';

  @override
  String get importComplete => 'Импорт завершён';

  @override
  String get importFailed => 'Ошибка импорта';

  @override
  String get importAction => 'Импортировать';

  @override
  String get continueWatchingApps => 'Приложения для «Продолжить просмотр»';

  @override
  String get blockedContinueWatching => 'Заблокировано в «Продолжить просмотр»';

  @override
  String get allAppsCanContinueWatching =>
      'Все поддерживаемые приложения могут добавлять карточки в «Продолжить просмотр».';

  @override
  String get unblockApp => 'Разблокировать';

  @override
  String get unblockAllApps => 'Разблокировать все приложения';

  @override
  String get appsWithContinueWatching => 'Приложения с «Продолжить просмотр»';

  @override
  String get watchNextAppsHint =>
      'Приложения, которые сейчас добавляют карточки на главный экран';

  @override
  String get noWatchNextApps =>
      'Пока ни одно приложение не добавило карточки «Продолжить просмотр».\nОни появятся здесь, когда поддерживаемые приложения, например SmartTube или онлайн-кинотеатры, добавят их.';

  @override
  String get allInstalledApps => 'Все установленные приложения';

  @override
  String get blockWatchNextHint =>
      'Выключите переключатель, чтобы запретить приложению добавлять карточки в «Продолжить просмотр»';

  @override
  String get cardSize => 'Размер карточек';

  @override
  String get maximumItems => 'Максимальное число карточек';

  @override
  String get playbackProgressBar => 'Полоса прогресса просмотра';

  @override
  String get playbackPercentage => 'Процент просмотренного';

  @override
  String get episodeVideoDetails => 'Сведения об эпизоде и видео';

  @override
  String get restoreHiddenPrograms => 'Вернуть скрытые карточки';

  @override
  String get allHiddenProgramsRestored => 'Все скрытые карточки восстановлены';

  @override
  String get watchNextAccessAdb => 'Доступ к «Продолжить просмотр» (через ADB)';

  @override
  String get supportLtvLauncher => 'Поддержать LTvLauncher';

  @override
  String get scanToDonate =>
      'Отсканируйте камерой телефона, чтобы поддержать проект:';

  @override
  String get openInBrowser => 'Открыть в браузере';

  @override
  String get close => 'Закрыть';

  @override
  String get launcherAuthor => 'Автор CuteLauncher — Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Лаунчер для Android TV на основе LTvLauncher от LeanBitLab и FLauncher от Étienne Fesser. Лицензия GNU GPLv3.';

  @override
  String get projectCredits => 'Проект и авторы';

  @override
  String get launcherRepository => 'Репозиторий CuteLauncher';

  @override
  String get originalProject => 'Исходный проект: LTvLauncher';

  @override
  String get noInputsDetected => 'Входы не найдены';

  @override
  String get reorderSectionsHint =>
      'Выберите раздел кнопками ◄ / ► и перемещайте кнопками ▲ / ▼. Перейдите через границу списка, чтобы скрыть или показать раздел.';

  @override
  String get customName => 'Своё название';

  @override
  String get mostUsed => 'По частоте запусков';

  @override
  String get lastUsed => 'По последнему запуску';

  @override
  String get clearAll => 'Очистить всё';

  @override
  String get allCaughtUp => 'Новых уведомлений нет';

  @override
  String get notificationAccessAdb => 'Доступ к уведомлениям (через ADB)';

  @override
  String get openAppInfo => 'Открыть сведения о приложении';

  @override
  String get overlayPermission => 'Разрешение на наложение';

  @override
  String get clockMinimal => 'Минималистичный';

  @override
  String get clockMinimalDescription => 'Тонкий шрифт (по умолчанию)';

  @override
  String get clockBold => 'Жирный';

  @override
  String get clockBoldDescription => 'Крупный, хорошо заметный шрифт';

  @override
  String get clockRetro => 'Ретро';

  @override
  String get clockRetroDescription =>
      'Моноширинный шрифт в стиле старого терминала';

  @override
  String get clockElegant => 'Классический';

  @override
  String get clockElegantDescription => 'Классический шрифт с засечками';

  @override
  String get clockNeon => 'Неоновый';

  @override
  String get clockNeonDescription => 'Очень тонкий светящийся шрифт';

  @override
  String get clockPixel => 'Пиксельный';

  @override
  String get clockPixelDescription =>
      'Жирный моноширинный шрифт в стиле игровых автоматов';

  @override
  String get clockDigital => 'Цифровой';

  @override
  String get clockDigitalDescription => 'Чёткий моноширинный шрифт';

  @override
  String get themeDefault => 'По умолчанию';

  @override
  String get themePremium => 'Премиальный';

  @override
  String get themeClassic => 'Классический';

  @override
  String get themeCapsule => 'Капсула';

  @override
  String get cancel => 'Отмена';

  @override
  String get actionCancelled => 'Действие отменено';

  @override
  String get ok => 'ОК';

  @override
  String get accessibilityGuide =>
      'Откройте настройки ТВ вручную, затем «Специальные возможности» → «CuteLauncher: перехват кнопки „Домой“» и включите службу. Расположение и название меню зависят от производителя ТВ.';

  @override
  String get notificationPermissionGuide =>
      'На этом ТВ не удалось открыть настройки доступа к уведомлениям. Разрешение показывать уведомления в сведениях о приложении не даёт доступ к уведомлениям других приложений.\n\nПодключите ТВ через ADB и выполните:';

  @override
  String get overlayPermissionGuide =>
      'Не удалось автоматически открыть настройки наложения.\n\nЧтобы разрешить всплывающие окна поверх других приложений, подключите ТВ через ADB и выполните:';

  @override
  String get watchNextPermissionGuide =>
      'Для чтения карточек «Продолжить просмотр» из других приложений Android TV требует разрешение READ_WRITE_WATCH_NEXT_PROGRAMS.\n\nПодключите ТВ через ADB и выполните:';

  @override
  String get watchNextAccess => 'Доступ к «Продолжить просмотр»';

  @override
  String itemsCount(int count) {
    return 'Карточек: $count';
  }

  @override
  String displayUpToItems(int count) {
    return 'Показывать до $count недавних карточек';
  }

  @override
  String get unlimitedItems => 'Без ограничения';

  @override
  String get allAvailableItems => 'Показывать все доступные карточки';

  @override
  String get defaultOption => 'По умолчанию';

  @override
  String get manage => 'Управление';

  @override
  String blockedCount(int count) {
    return 'Заблокировано: $count';
  }

  @override
  String hiddenCount(int count) {
    return 'Скрыто: $count';
  }

  @override
  String blockedWatchNextCount(int count) {
    return 'Заблокировано в «Продолжить просмотр» ($count)';
  }

  @override
  String get sizeExtraSmall => 'Миниатюрный';

  @override
  String get sizeVerySmall => 'Очень маленький';

  @override
  String get sizeSmall => 'Маленький';

  @override
  String get sizeCompact => 'Компактный';

  @override
  String get sizeMediumSmall => 'Ниже среднего';

  @override
  String get sizeMedium => 'Средний';

  @override
  String get sizeStandardDefault => 'Стандартный (по умолчанию)';

  @override
  String get sizeMediumLarge => 'Выше среднего';

  @override
  String get sizeLarge => 'Большой';

  @override
  String get sizeVeryLarge => 'Очень большой';

  @override
  String get sizeExtraLarge => 'Огромный';

  @override
  String get sizeHuge => 'Максимальный';

  @override
  String get tvApps => 'Приложения для ТВ';

  @override
  String get nonTvApps => 'Приложения не для ТВ';

  @override
  String get moviesShows => 'Фильмы и сериалы';

  @override
  String get music => 'Музыка';

  @override
  String get games => 'Игры';

  @override
  String get entertainment => 'Развлечения';

  @override
  String get liveTv => 'Телеканалы';

  @override
  String get sports => 'Спорт';

  @override
  String get news => 'Новости';

  @override
  String get tools => 'Инструменты';

  @override
  String get favorites => 'Избранное';

  @override
  String get customSectionName => 'Своё название…';

  @override
  String get selectSectionName => 'Выберите название';

  @override
  String get weeklyUsage => 'За неделю: ';

  @override
  String get monthlyUsage => 'За месяц: ';

  @override
  String get dailyUsage => 'За день: ';

  @override
  String get appError => 'Произошла ошибка';

  @override
  String get weatherRain => 'Дождь';

  @override
  String get weatherSnow => 'Снег';

  @override
  String get weatherStorm => 'Гроза';

  @override
  String get weatherToday => 'сегодня';

  @override
  String get weatherTomorrow => 'завтра';

  @override
  String weatherOnDay(String day) {
    return 'в $day';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'Резервная копия CuteLauncher';

  @override
  String get noApplicationsFound => 'Приложения не найдены';

  @override
  String get invalidDateFormat => 'Некорректный формат';

  @override
  String get selectDateFormats => 'Выберите форматы ниже';

  @override
  String activeItemsCount(int count) {
    return 'Активных карточек: $count';
  }

  @override
  String get colorPurple => 'Фиолетовый';

  @override
  String get colorTeal => 'Бирюзовый';

  @override
  String get colorBlue => 'Синий';

  @override
  String get colorOrange => 'Оранжевый';

  @override
  String get colorPink => 'Розовый';

  @override
  String get colorGreen => 'Зелёный';

  @override
  String get colorWhite => 'Белый';

  @override
  String get colorYellow => 'Жёлтый';

  @override
  String get colorRed => 'Красный';

  @override
  String get colorCyan => 'Голубой';

  @override
  String get colorIndigo => 'Индиго';

  @override
  String get colorLime => 'Салатовый';

  @override
  String get colorAmber => 'Янтарный';

  @override
  String get colorRose => 'Розовый красный';

  @override
  String get colorIceBlue => 'Ледяной голубой';

  @override
  String get memoryFeatures => 'Память по функциям (кеши)';

  @override
  String get memoryAppIcons => 'Значки приложений';

  @override
  String get memoryAppBanners => 'Баннеры приложений';

  @override
  String get memoryWatchNextPosters => 'Постеры «Продолжить просмотр»';

  @override
  String get memoryOtherCaches => 'Другие кеши байтов изображений';

  @override
  String get memoryFeaturesExplanation =>
      'Это сохранённые байты изображений, уже включённые в общий кеш байтов. Ноль означает пустой кеш, а не отсутствие расхода памяти у функции. Обои и изображения на экране используют общий кеш декодированных изображений выше; активные изображения могут находиться вне него. Память погоды, уведомлений, объектов Dart и движка здесь нельзя разделить по функциям. Общая графика интерфейса показана выше по данным Android и уже входит в PSS. Она входит в общий расход процесса. Эти пересекающиеся значения нельзя складывать.';

  @override
  String get memoryGraphics => 'Графика интерфейса (входит в PSS)';

  @override
  String get categoryVisible => 'Показывать раздел';

  @override
  String get hiddenCategories => 'Скрытые разделы';

  @override
  String get visibleCategories => 'Отображаемые разделы';

  @override
  String get backupSavedToSelectedLocation =>
      'Резервная копия сохранена в выбранное место';

  @override
  String get tileHorizontalGap => 'Интервал по горизонтали';

  @override
  String get tileVerticalGap => 'Интервал по вертикали';

  @override
  String get tileOpacity => 'Непрозрачность фона';

  @override
  String get tileShadow => 'Тень';

  @override
  String get tileCornerRadius => 'Скругление углов';

  @override
  String get tileIconScale => 'Размер значка';

  @override
  String get tileBackgroundColor => 'Фон плитки';

  @override
  String get tileLabelSize => 'Размер подписи';

  @override
  String get resetAppearance => 'Сбросить оформление';

  @override
  String get tileAppearance => 'Оформление плиток';

  @override
  String get tileLabelColor => 'Цвет подписи';

  @override
  String get tilePreviewName => 'Пример приложения';

  @override
  String get tileProportions => 'Пропорции плиток';

  @override
  String get tileLarge => 'Крупные';

  @override
  String get tileLabelBelow => 'Под плиткой';

  @override
  String get tileLabelInside => 'Внутри плитки';

  @override
  String get tileFocusScale => 'Увеличение';

  @override
  String get tileMedium => 'Средние';

  @override
  String get tileFocusBorder => 'Без движения';

  @override
  String get tileSize => 'Размер плиток';

  @override
  String get tileCompact => 'Компактные';

  @override
  String get tileLabelPosition => 'Расположение подписи';

  @override
  String get tileFocusEffect => 'Эффект выделения';

  @override
  String get tileFocusStrength => 'Интенсивность выделения';

  @override
  String get panelIndependent => 'Свои настройки';

  @override
  String get panelAppearance => 'Стиль верхней панели';

  @override
  String get panelBackground => 'Фон панели';

  @override
  String get blurPerformanceHint =>
      'Размытие может снизить плавность. В режиме экономии памяти оно отключается.';

  @override
  String get panelOpacity => 'Непрозрачность панели';

  @override
  String get tileBlur => 'Размытие за плитками';

  @override
  String get panelBlur => 'Размытие за верхней панелью';

  @override
  String get panelShared => 'Как у панелей';

  @override
  String get weatherMinutes => 'мин';

  @override
  String get weatherOpenMeteoCredit =>
      'Погода: Open-Meteo (open-meteo.com), CC BY 4.0. Бесплатный API для некоммерческого использования.';

  @override
  String get weatherRateLimit => 'Лимит запросов исчерпан. Повторите позже.';

  @override
  String get weatherYandexCredit =>
      'Погода: Яндекс Погода (yandex.ru/pogoda). Доступ зависит от тарифа API.';

  @override
  String get yandexWeather => 'Яндекс Погода (REST)';

  @override
  String get weatherAuthorizationError =>
      'Источник погоды отклонил запрос. Проверьте ключ API и доступ к выбранному сервису.';

  @override
  String get weatherYandexHint =>
      'Нужен ключ с доступом к прогнозу REST. Ключ другого тарифа Яндекса может не подойти.';

  @override
  String get weatherSource => 'Источник погоды';

  @override
  String get weatherInterval => 'Интервал обновления';

  @override
  String get weatherLongitude => 'Долгота (от -180 до 180)';

  @override
  String get weatherKeyRequired => 'Добавьте ключ API Яндекса.';

  @override
  String get weatherLocationName => 'Название города (необязательно)';

  @override
  String get weatherLocation => 'Местоположение';

  @override
  String get weatherApiKey => 'Ключ API Яндекса';

  @override
  String get weatherInvalidResponse =>
      'Источник вернул некорректные данные погоды.';

  @override
  String get weatherUnavailable =>
      'Погода недоступна. Ранее полученные данные сохраняются, если они есть. Повторный запрос возможен раз в 5 минут.';

  @override
  String get weatherStale => 'Предыдущая погода';

  @override
  String get weatherLatitude => 'Широта (от -90 до 90)';

  @override
  String get weatherCoordinatesError =>
      'Выберите город, введите координаты или получите местоположение автоматически.';

  @override
  String get weatherRefresh => 'Обновить погоду';

  @override
  String get weatherKeyPrivate =>
      'Хранится только на этом устройстве, не включается в копии. Пустой ввод удаляет ключ.';

  @override
  String get weatherUpdated => 'Обновлено';

  @override
  String get onlineWallpaperError =>
      'Не удалось загрузить изображение. Сохранены предыдущие обои. Нажмите «Обновить обои», чтобы повторить загрузку.';

  @override
  String get onlineWallpaperHint =>
      'Последняя картинка сохраняется для работы без сети (до 8 МиБ).';

  @override
  String get onlineWallpaperHours => 'ч';

  @override
  String get onlineWallpaperInterval => 'Интервал загрузки';

  @override
  String get onlineWallpaper => 'Онлайн-обои';

  @override
  String get onlineWallpaperUrlError =>
      'Введите прямую HTTPS-ссылку на изображение без данных входа.';

  @override
  String get onlineWallpaperEnabled => 'Использовать онлайн-обои';

  @override
  String get onlineWallpaperSource => 'Источник изображения';

  @override
  String get bingWallpaper => 'Bing — изображение дня';

  @override
  String get onlineWallpaperUrlSource => 'Прямая HTTPS-ссылка';

  @override
  String get updatePlayOnly =>
      'Эта установка получает обновления через Google Play.';

  @override
  String get updateCheck => 'Проверить сейчас';

  @override
  String get updateInstalled => 'Установлено';

  @override
  String get updateDownloadInstall => 'Скачать и установить';

  @override
  String get updateNoRelease => 'Новый совместимый релиз не найден.';

  @override
  String get updateIncompatible =>
      'APK не соответствует приложению, сертификату или более новой версии. Установка заблокирована.';

  @override
  String get updateError =>
      'Не удалось проверить, скачать или открыть установщик. Повторите позже.';

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get appUpdates => 'Обновление приложения';

  @override
  String get updatePermission =>
      'Разрешите установку из этого приложения в настройках Android, вернитесь сюда и снова нажмите «Установить».';

  @override
  String get updateInstall => 'Установить загруженное обновление';

  @override
  String get updateHint =>
      'Источник: GitHub / KirillShchetinnikov/CuteLauncher-Releases. Автопроверка работает, пока лаунчер открыт. Загрузка начинается по вашей команде; Android попросит подтвердить установку. Данные сохраняются.';

  @override
  String get updateAutomatic => 'Проверять автоматически раз в сутки';

  @override
  String get allApplications => 'Все приложения';

  @override
  String get adbAccessibility => 'Включить Home Button Fix';

  @override
  String get adbAuthorization =>
      'Подтвердите доступ ADB на ТВ и повторите запрос.';

  @override
  String get adbChangeConfirm =>
      'Применить выбранную системную настройку через ADB? Перед сменой главного экрана сохраняется прежний лаунчер; остальные службы специальных возможностей сохраняются.';

  @override
  String get adbCheck => 'Проверить подключение';

  @override
  String get adbDenied => 'Система не разрешила или не подтвердила изменение.';

  @override
  String get adbDisable => 'Отключить предыдущий лаунчер';

  @override
  String get adbDisableConfirm =>
      'Отключить сохранённый предыдущий лаунчер? CuteLauncher должен быть текущим главным экраном. Восстановление доступно отдельной кнопкой в этом мастере.';

  @override
  String get adbHint =>
      'Прототип для этого ТВ (127.0.0.1). Включите ADB по TCP в настройках разработчика, укажите порт и подтвердите запрос доступа на ТВ. Беспроводное подключение с кодом сопряжения пока не поддерживается. Закрытый ключ остаётся на устройстве, вне резервных копий.';

  @override
  String get adbHome => 'Назначить CuteLauncher главным экраном';

  @override
  String get adbInvalid => 'Введите порт от 1024 до 65535.';

  @override
  String get adbNoRecovery =>
      'Восстановление недоступно: другой лаунчер или прежнее состояние службы не найдены.';

  @override
  String get adbPort => 'Порт ADB по TCP';

  @override
  String get adbReady => 'Доступ ADB подтверждён.';

  @override
  String get adbRestore => 'Восстановить предыдущий лаунчер';

  @override
  String get adbSuccess => 'Изменение выполнено и проверено.';

  @override
  String get adbTitle => 'Мастер ADB';

  @override
  String get adbUnavailable =>
      'Не удалось подключиться. Проверьте ADB по TCP, порт и запрос авторизации.';

  @override
  String get nightModeScheduled => 'По расписанию';

  @override
  String get nightModeTitle => 'Ночной режим';

  @override
  String get nightModeScope =>
      'Разрешение на наложение нужно для затемнения других приложений. Без него затемнение работает внутри CuteLauncher. Фильтру TCL это разрешение не требуется. При непрозрачности выше 80% Android может блокировать сенсорный ввод в других приложениях; кнопки пульта продолжают работать.';

  @override
  String get nightModeEnd => 'Окончание';

  @override
  String get nightModeStart => 'Начало';

  @override
  String get nightModeDim => 'Затемнение';

  @override
  String get nightModeWarmth => 'Тёплый фильтр';

  @override
  String get nightModeScheduleHint =>
      'Используется время ТВ. Интервал может переходить через полночь. При одинаковом времени начала и окончания фильтр по расписанию отключён.';

  @override
  String get nightModeEnabled => 'Включить ночной режим';

  @override
  String get nightModePermission => 'Разрешить показ поверх других приложений';

  @override
  String get nightModePermissionGranted =>
      'Показ поверх других приложений разрешён';

  @override
  String get backupDownloadsFailed => 'Не удалось сохранить копию в Загрузки.';

  @override
  String get backupSaveDownloads => 'Сохранить копию в Загрузки';

  @override
  String get adbRestoreAccessibility =>
      'Восстановить доступ специальных возможностей';

  @override
  String get nightModeAdbConfirm =>
      'Разрешить CuteLauncher показ поверх других приложений через локальный ADB? Сначала включите отладку по TCP и подтвердите подключение. Используется сохранённый в мастере порт, либо 5555.';

  @override
  String get nightModeAdbPermission => 'Выдать разрешение через ADB';

  @override
  String get nightModeNotificationsHint =>
      'В уведомлении можно выключить фильтр вне CuteLauncher. Без уведомления используйте это меню.';

  @override
  String get nightModeNotificationsAllowed =>
      'Уведомление ночного режима разрешено';

  @override
  String get nightModeNotifications => 'Разрешить уведомление ночного режима';

  @override
  String get categoryLastVisibleHint =>
      'Хотя бы один раздел должен оставаться видимым.';

  @override
  String get diagnosticsClear => 'Очистить отчёт';

  @override
  String get diagnosticsReady => 'Отчёт готов';

  @override
  String get diagnosticsCreate => 'Создать отчёт';

  @override
  String get diagnosticsOperations => 'Записано операций';

  @override
  String get diagnosticsCopied => 'Отчёт скопирован';

  @override
  String get diagnosticsSharingNotice =>
      'Передавайте файл автору в личные сообщения, не публикуйте его открыто: автоматическая очистка может пропустить личные данные. Отправляя отчёт автору, вы соглашаетесь на размещение обезличенного отчёта о совместимости ТВ в Git-репозитории CuteLauncher. Публикуются только сведения об устройстве и доступности функций без личных данных; журнал ошибок, команды и ваши настройки не публикуются.\n\nОтчёт также включает установленные пакеты, их названия, версии и состояние включения, а также разделы, их названия, состав, порядок и видимость. Идентификаторы пакетов и названия сохраняются для диагностики; списки приложений и разделов не публикуются.';

  @override
  String get diagnosticsHint =>
      'Единый отчёт включает совместимость функций ТВ и диагностику ошибок. Отчёт содержит модель и прошивку ТВ, версию приложения, разрешения, память, этапы и причины ошибок, команды и ответы системы после автоматической очистки личных данных. В памяти хранятся последние 50 операций и отдельно до 100 сбоев текущего сеанса, а также ограниченный журнал ADB. После перезапуска журнал удаляется. Очистка может пропустить личные данные: передавайте файл в личные сообщения, не публикуйте его открыто. Ничего не отправляется автоматически. Для каждой ошибки сохраняется снимок применённых настроек: последующие изменения его не заменяют.\n\nОтчёт также включает установленные пакеты, их названия, версии и состояние включения, а также разделы, их названия, состав, порядок и видимость. Идентификаторы пакетов и названия сохраняются для диагностики; списки приложений и разделов не публикуются.';

  @override
  String get diagnosticsTitle => 'Диагностика ошибок';

  @override
  String get diagnosticsCopyFailed => 'Не удалось скопировать отчёт.';

  @override
  String get diagnosticsCopy => 'Скопировать отчёт';

  @override
  String get diagnosticsCreating => 'Создание отчёта…';

  @override
  String get tclBlueLightTitle => 'TCL: фильтр синего цвета';

  @override
  String get tclBlueLightError =>
      'Не удалось прочитать или подтвердить настройку фильтра TCL. Обновите состояние и повторите попытку.';

  @override
  String get tclBlueLightUnsupported =>
      'На этом телевизоре управление фильтром TCL недоступно.';

  @override
  String get tclBlueLightRefresh => 'Обновить состояние фильтра TCL';

  @override
  String get tclBlueLightHint =>
      'Управляет встроенным фильтром «Защита здоровья глаз» телевизора. Его также можно включать по расписанию ночного режима.';

  @override
  String get nightSolarSchedule => 'Закат и рассвет';

  @override
  String get nightNextStart => 'Следующее включение';

  @override
  String get nightScheduleTimeHint =>
      'Время показано в часовом поясе телевизора. Минус — раньше, плюс — позже.';

  @override
  String get nightTemperature => 'Цветовая температура фильтра';

  @override
  String get nightScheduleSettings => 'Настройки расписания';

  @override
  String get nightCityName => 'Название города';

  @override
  String get nightSkipUntilNext =>
      'Отключить ночной режим до следующего заката';

  @override
  String get nightSunriseOffset => 'Выключение относительно рассвета';

  @override
  String get nightEnableUntilMorning =>
      'Включить ночной режим до следующего рассвета';

  @override
  String get nightPermissions => 'Разрешения';

  @override
  String get nightTclSchedule => 'Добавить фильтр TCL в расписание';

  @override
  String get nightSearchCity => 'Найти';

  @override
  String get nightRefreshSun => 'Обновить рассвет и закат';

  @override
  String get nightSolarUnavailable =>
      'Выберите город и обновите время солнца. Если рассвет или закат недоступен, солнечное расписание приостанавливается.';

  @override
  String get nightSunsetOffset => 'Включение относительно заката';

  @override
  String get nightCityHint =>
      'Укажите свой город — разрешение на местоположение не требуется. Координаты выбранного города передаются Sunrise-Sunset.org, а при сбое — GeoNames, для получения времени солнца.';

  @override
  String get nightResumeSchedule => 'Вернуться к расписанию';

  @override
  String get nightScheduleSource => 'Тип расписания';

  @override
  String get nightSolarCached =>
      'Используются сохранённые времена солнца; обновление через интернет повторится автоматически.';

  @override
  String get nightTclScheduleHint =>
      'Использует то же расписание, когда ночной режим включён. Ручное переключение фильтра TCL действует до следующего перехода по расписанию. Разрешение на наложение не требуется.';

  @override
  String get nightRefreshPermission => 'Обновить статус разрешений';

  @override
  String get nightCityNotFound =>
      'Города не найдены. Попробуйте другое название.';

  @override
  String get nightNoOffset => 'Без смещения';

  @override
  String get nightManualSchedule => 'Своё расписание';

  @override
  String get nightChooseCity => 'Выбрать город';

  @override
  String get nightPermissionUnknown =>
      'Статус разрешения на наложение неизвестен';

  @override
  String get nightNextEnd => 'Следующее выключение';

  @override
  String get nightTemporaryOff => 'Затемнение временно отключено до';

  @override
  String get nightCitySearchFailed =>
      'Не удалось найти города. Проверьте подключение к интернету.';

  @override
  String get nightSolarAttribution =>
      'Время рассвета и заката берётся из Sunrise-Sunset.org, при сбое — из GeoNames. Без интернета телевизор рассчитывает недостающие события.';

  @override
  String get nightTemporaryOn => 'Затемнение временно включено до';

  @override
  String get homeScreen => 'Главный экран';

  @override
  String get appearanceSettings => 'Оформление';

  @override
  String get generalSettings => 'Дополнительно';

  @override
  String get advancedSettings => 'Дополнительно';

  @override
  String get controlAndStartup => 'Лаунчер и управление ТВ';

  @override
  String get sectionsAndOrder => 'Разделы и порядок';

  @override
  String get topPanel => 'Верхняя панель';

  @override
  String get tileStyle => 'Стиль плиток';

  @override
  String get tilesAndLabels => 'Плитки и подписи';

  @override
  String get highlightAndAnimation => 'Выделение и анимация';

  @override
  String get androidTvSettings => 'Настройки Android TV';

  @override
  String get weatherSettings => 'Настройки погоды';

  @override
  String get showHighlightOutline => 'Показывать рамку выделения';

  @override
  String get resetTilesAndPanel => 'Сбросить настройки плиток и панели';

  @override
  String get resetTilesAndPanelHint =>
      'Сбросить дополнительные параметры плиток, подписей, выделения и верхней панели? Обои, акцентный цвет, стиль плиток и показ подписей сохранятся.';

  @override
  String get panelAppearanceSettings => 'Оформление верхней панели';

  @override
  String get panelSharedHint =>
      'Оформление можно изменить в настройках плиток.';

  @override
  String get effectsCompatibilityHint =>
      'Дополнительное оформление: рамка всегда видна, пульсации нет. Объёмный стиль без базовой рамки; классический без пульсации. Интенсивность — для увеличения и тени; увеличение ограничено местом.';

  @override
  String get sizeAndLayout => 'Размер и расположение';

  @override
  String get labelsGroup => 'Подписи';

  @override
  String get surfaceGroup => 'Поверхность';

  @override
  String get clockAndDateGroup => 'Часы и дата';

  @override
  String get networkAndTrafficGroup => 'Сеть и трафик';

  @override
  String get buttonsGroup => 'Кнопки';

  @override
  String get notificationAppsHint =>
      'Выберите приложения, уведомления которых нужно блокировать. Включённый переключатель означает блокировку. Список сохраняет алфавитный порядок.';

  @override
  String get notificationPanelLink => 'Оформление верхней панели';

  @override
  String get overlayAccessAdb => 'Показ поверх приложений (через ADB)';

  @override
  String get tileStyleModern => 'Современный';

  @override
  String get tileStyleVolume => 'Объёмный';

  @override
  String get showTime => 'Показывать время';

  @override
  String get showDate => 'Показывать дату';

  @override
  String get showWeather => 'Показывать погоду';

  @override
  String get showNetwork => 'Показывать состояние сети';

  @override
  String get showTraffic => 'Показывать трафик';

  @override
  String get scheduledBrightness => 'Яркость по расписанию';

  @override
  String get followTileStyle => 'По стилю';

  @override
  String get androidTvSettingsHint => 'Открыть системное меню телевизора';

  @override
  String get autoHideTopPanel => 'Автоматически скрывать панель';

  @override
  String get showSectionTitles => 'Показывать названия разделов';

  @override
  String get usageDaily => 'За день';

  @override
  String get usageWeekly => 'За неделю';

  @override
  String get usageMonthly => 'За месяц';

  @override
  String get onlineWallpaperAddress => 'Адрес изображения (HTTPS)';

  @override
  String get watchNextAppLimits => 'Лимиты по приложениям';

  @override
  String get watchNextAppLimitsHint =>
      'Сначала действует лимит приложения, затем общий лимит. «Без ограничений» оставляет только общий лимит; скрытые карточки остаются скрытыми.';

  @override
  String get rememberCategoryFocus => 'Запоминать выбранную карточку';

  @override
  String get automaticBackups => 'Копии и синхронизация';

  @override
  String get automaticBackupsHint =>
      'Ежедневные копии настроек, обоев и баннеров, пока лаунчер активен. Пропущенная копия создаётся после возвращения в лаунчер. Хранятся на этом устройстве, суммарно до 256 MiB; удаление приложения или его данных удалит и копии. Сохраняйте также внешнюю копию.';

  @override
  String get automaticBackupsEnabled => 'Ежедневное автоматическое копирование';

  @override
  String get automaticBackupsKeep => 'Количество сохраняемых копий';

  @override
  String get automaticBackupCreateNow => 'Создать точку восстановления сейчас';

  @override
  String get automaticBackupFailed =>
      'Не удалось выполнить операцию с копией. Проверьте свободное место и повторите попытку.';

  @override
  String get restorePoints => 'Точки восстановления';

  @override
  String get noRestorePoints => 'Точек восстановления пока нет';

  @override
  String get updatePrereleases => 'Обновлять на пререлизы';

  @override
  String get topPanelObjects => 'Объекты';

  @override
  String get panelTransparency => 'Прозрачность панели';

  @override
  String get panelTextBackground => 'Фон текста и кнопок';

  @override
  String get panelTextBackgroundColor => 'Цвет фона текста и кнопок';

  @override
  String get panelTextColor => 'Цвет текста и кнопок';

  @override
  String get panelTextSize => 'Размер текста и кнопок';

  @override
  String get panelFont => 'Шрифт текста';

  @override
  String get fontSans => 'Без засечек';

  @override
  String get fontSerif => 'С засечками';

  @override
  String get fontMono => 'Моноширинный';

  @override
  String get fontCondensed => 'Узкий';

  @override
  String get trafficPermissionGranted => 'Доступ к статистике трафика разрешён';

  @override
  String get background => 'Фон';

  @override
  String get backgroundParameters => 'Настройки источника';

  @override
  String get resetAppearanceHint =>
      'Сбросить фон, акцентный цвет, плитки, подписи, выделение и анимацию?';

  @override
  String get wallpaperDimming => 'Сила затемнения';

  @override
  String get wallpaperPlacement => 'Размещение';

  @override
  String get wallpaperDisplay => 'Отображение обоев';

  @override
  String get wallpaperContain => 'Показать целиком';

  @override
  String get wallpaperBlurred => 'Поверх размытой копии';

  @override
  String get wallpaperCover => 'Заполнить экран';

  @override
  String get wallpaperBrightness => 'Яркость обоев';

  @override
  String get wallpaperSaturation => 'Насыщенность';

  @override
  String get categoryPadding => 'Поля раздела';

  @override
  String get categoryLight => 'Светлая';

  @override
  String get categoryBlue => 'Синяя';

  @override
  String get categoryPurple => 'Фиолетовая';

  @override
  String get categoryAllRows => 'Все';

  @override
  String get categoryTeal => 'Бирюзовая';

  @override
  String get categoryMaxRows => 'Видимые ряды сетки';

  @override
  String get categoryDark => 'Тёмная';

  @override
  String get categoryAppearance => 'Оформление раздела';

  @override
  String get categoryBackground => 'Подложка раздела';

  @override
  String get categoryTransparent => 'Прозрачная';

  @override
  String get slideshowInterval => 'Интервал смены';

  @override
  String get slideshowFolderSelected =>
      'Доступ к папке сохранён на этом устройстве.';

  @override
  String get slideshowRandom => 'Случайный порядок';

  @override
  String get wallpaperSlideshow => 'Слайд-шоу из папки';

  @override
  String get slideshowNext => 'Следующее изображение';

  @override
  String get slideshowFolderRequired => 'Выберите папку для запуска слайд-шоу.';

  @override
  String get slideshowHint =>
      'До 1000 изображений и 4000 записей папки; файлы до 8 МиБ. Повреждённые файлы пропускаются, последняя удачная картинка сохраняется. В фоне смена остановлена. После переноса на другое устройство выберите папку заново.';

  @override
  String get slideshowSeconds => 'с';

  @override
  String get slideshowError =>
      'Не удалось прочитать изображения. Выберите доступную папку с исправными изображениями.';

  @override
  String get slideshowFolder => 'Выбрать папку';

  @override
  String get slideshowRecursive => 'Включать подпапки';

  @override
  String get weatherSourceKeyRequired =>
      'Добавьте API-ключ выбранного источника погоды.';

  @override
  String get weatherOpenWeatherCredit =>
      'Погода: OpenWeather (openweathermap.org). Значения по дням обобщают доступные трёхчасовые периоды прогноза.';

  @override
  String get weatherOpenWeatherHint =>
      'Нужен личный ключ для текущей погоды и прогноза на 5 дней с шагом 3 часа. Одно обновление — два запроса; доступ и лимиты зависят от вашего тарифа.';

  @override
  String get weatherOpenWeatherKey => 'API-ключ OpenWeather';

  @override
  String get mediaPause => 'Пауза';

  @override
  String get showNowPlaying => 'Показывать «Сейчас воспроизводится»';

  @override
  String get nowPlayingAccessHint =>
      'Для управления воспроизведением разрешите CuteLauncher доступ к уведомлениям. Отображаются только действия, предоставленные проигрывателем.';

  @override
  String get nowPlaying => 'Сейчас воспроизводится';

  @override
  String get mediaNext => 'Следующий трек';

  @override
  String get mediaPlay => 'Продолжить';

  @override
  String get mediaControlError =>
      'Проигрыватель недоступен или не принял команду.';

  @override
  String get nightUsageAccess => 'Разрешить доступ к истории использования';

  @override
  String get nightExcludedAppsHint =>
      'Наложение и TCL-фильтр по расписанию приостанавливаются в выбранных приложениях. Нужен доступ к истории использования; без него исключения не действуют.';

  @override
  String get nightExcludedApps => 'Исключённые приложения';

  @override
  String get adbPairPort => 'Порт сопряжения';

  @override
  String get adbPairOverlayHint =>
      'Откройте беспроводную отладку и сопряжение по коду. Не закрывайте системное окно с кодом. Через 30 секунд эта форма станет активной. Введите оба порта и код Android.';

  @override
  String get adbOverlaySettings => 'Вернуть управление настройкам на 30 секунд';

  @override
  String get adbTlsHint =>
      'Используйте беспроводную отладку в настройках разработчика. Порты сопряжения и подключения различаются. Если прошивка не показывает код или скрывает окна поверх настроек, используйте TCP / RSA. Подключение выполняется только к этому ТВ.';

  @override
  String get adbPaired =>
      'Сопряжение выполнено. Проверьте подключение по порту беспроводной отладки.';

  @override
  String get adbTransport => 'Способ подключения';

  @override
  String get adbPairCode => 'Шестизначный код';

  @override
  String get adbOverlayRequired =>
      'Для ввода кода поверх настроек нужен доступ к показу поверх других приложений.';

  @override
  String get adbOverlayPermission => 'Разрешить показ поверх других приложений';

  @override
  String get adbTlsUnsupported =>
      'Прошивка не открывает нужный экран настроек или форму сопряжения. Используйте TCP / RSA.';

  @override
  String get adbConnectPort => 'Порт подключения';

  @override
  String get adbTls => 'TLS / код сопряжения';

  @override
  String get adbTcp => 'TCP / RSA';

  @override
  String get adbPairingFailed =>
      'Сопряжение не удалось. Проверьте код и порт сопряжения, оставьте окно Android с кодом открытым и повторите попытку.';

  @override
  String get adbTlsDisabled =>
      'Беспроводная отладка выключена или её состояние недоступно. Включите её в настройках разработчика.';

  @override
  String get adbPairOverlay => 'Ввести код поверх настроек';

  @override
  String get adbPair => 'Сопряжение';

  @override
  String get adbDeveloperSettings => 'Открыть настройки разработчика';

  @override
  String get adbTwoWindowsHint =>
      'Если прошивка поддерживает два окна, оставьте системный диалог сопряжения рядом с CuteLauncher и введите его код здесь. Прямое сопряжение доступно только в двухоконном режиме.';

  @override
  String get adbTwoWindows => 'Открыть настройки во втором окне';

  @override
  String get autoLaunchBoot => 'После загрузки телевизора';

  @override
  String get autoLaunchOff => 'Выключен';

  @override
  String get autoLaunchTitle => 'Автозапуск';

  @override
  String get autoLaunchDelay => 'Задержка запуска';

  @override
  String get autoLaunchHdmi => 'Переключать на выбранный HDMI';

  @override
  String get autoLaunchWake => 'После пробуждения';

  @override
  String get autoLaunchHint =>
      'Выберите приложение или HDMI-вход, который нужно открыть после включения или пробуждения ТВ. Ниже задайте событие и задержку. Действие выполняется один раз, когда Android показывает CuteLauncher. Любое нажатие пульта или уход с главного экрана отменяет ожидание. После переключения HDMI вы можете свободно менять вход. Для запуска CuteLauncher после включения ТВ может потребоваться назначить его лаунчером по умолчанию или включить «Старт при загрузке». Пробуждение отслеживается, пока CuteLauncher работает.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds секунд';
  }

  @override
  String get autoLaunchApp => 'Открывать выбранное приложение';

  @override
  String get autoLaunchTarget => 'Цель запуска';

  @override
  String get autoLaunchUnavailable =>
      'Цель недоступна или действие не разрешено прошивкой.';

  @override
  String get autoLaunchCancelled => 'Отложенный запуск отменён.';

  @override
  String get syncTitle => 'Обмен настройками';

  @override
  String get syncHint =>
      'Сохраните файл настроек, перенесите на другое устройство и откройте там. Передайте новый файл обратно, чтобы обновить оба устройства. Переносятся интерфейс, оформление плиток и параметры отображения. Приложения, разделы, файлы обоев, разрешения, HOME, правила запуска и секреты остаются на этом устройстве. Обмен ручной: аккаунт и фоновое сетевое подключение не используются.';

  @override
  String get syncExport => 'Сохранить изменения в файл';

  @override
  String get syncImport => 'Открыть изменения другого устройства';

  @override
  String get syncSaved => 'Файл обмена настройками сохранён.';

  @override
  String get syncFailed =>
      'Не удалось обменяться настройками. Частичный импорт не сохраняется. Проверьте файл или откройте его снова, если настройки изменились во время просмотра.';

  @override
  String get syncPreviewHint =>
      'Проверьте изменения перед применением. При конфликте нажмите на строку и выберите настройки этого устройства или файла. Сначала выбран вариант этого устройства. Отмена оставляет настройки без изменений.';

  @override
  String get syncNoChanges =>
      'Новых настроек нет. Применение подтвердит общую историю изменений.';

  @override
  String syncLocalValue(String value) {
    return 'На этом устройстве: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'В файле: $value';
  }

  @override
  String get syncKeepLocal => 'Конфликт: оставить это устройство';

  @override
  String get syncUseFile => 'Конфликт: взять из файла';

  @override
  String get syncApply => 'Применить выбранные изменения';

  @override
  String get syncApplied =>
      'Настройки объединены. Сохраните новый файл для передачи обратно.';

  @override
  String syncStyleParameters(int count) {
    return 'Собственное оформление: $count параметров (различия ниже)';
  }

  @override
  String get cloudBackups => 'Облачные копии';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud. Укажите HTTPS-адрес существующей папки и пароль приложения. Копии передаются вручную; в папке хранится последняя копия.';

  @override
  String get cloudUrl => 'HTTPS-адрес папки';

  @override
  String get cloudUser => 'Имя пользователя';

  @override
  String get cloudPassword => 'Пароль приложения';

  @override
  String get cloudConnect => 'Проверить и сохранить аккаунт';

  @override
  String get cloudCheck => 'Проверить подключение';

  @override
  String get cloudDisconnect => 'Отключить аккаунт';

  @override
  String get cloudDisconnectConfirm =>
      'Удалить аккаунт с телевизора? Копии в облаке сохранятся.';

  @override
  String get cloudUpload => 'Сохранить копию в облако';

  @override
  String get cloudDownload => 'Восстановить из облака';

  @override
  String get cloudUploadConfirm =>
      'Заменить cutelauncher_backup.json в этой папке текущими настройками и данными?';

  @override
  String get cloudSuccess => 'Готово';

  @override
  String get cloudConfigurationError =>
      'Проверьте HTTPS-адрес папки, имя пользователя и пароль приложения.';

  @override
  String get cloudAuthorizationError =>
      'Доступ запрещён. Проверьте аккаунт и права на папку.';

  @override
  String get cloudMissingError => 'Папка или резервная копия не найдена.';

  @override
  String get cloudUnsupportedError =>
      'Адрес не поддерживает нужные операции WebDAV. Переходы на другой адрес не выполняются; укажите конечный адрес папки.';

  @override
  String get cloudNetworkError =>
      'Не удалось подключиться или истекло время ожидания. Повторите при доступной сети.';

  @override
  String get cloudFailed =>
      'Не удалось выполнить действие с резервной копией. Проверьте доступ к хранилищу и повторите попытку.';

  @override
  String get cloudStorageError =>
      'Хранилище аккаунта недоступно. Отключите аккаунт и настройте его заново.';

  @override
  String get adbPermissionChecking => 'Проверка доступа…';

  @override
  String get adbPermissionConnected => 'АДБ подключён · выдать разрешение';

  @override
  String get adbPermissionDisconnected =>
      'АДБ не подключён · настроить подключение';

  @override
  String get adbSetupIntro =>
      'Включите отладку и ADB по сети в настройках разработчика ТВ, затем подтвердите доверие CuteLauncher. Все действия через ADB выполняются на свой страх и риск.';

  @override
  String get adbConnectionBlock => 'Подключение АДБ';

  @override
  String get adbNotChecked => 'Подключение не проверено';

  @override
  String get adbApplied => 'Уже применено';

  @override
  String get adbNotApplied => 'Ещё не применено';

  @override
  String get adbDefaultBlock => 'Лаунчер по умолчанию';

  @override
  String get adbSystemDefault =>
      'Открыть системную настройку лаунчера по умолчанию';

  @override
  String get adbAssignDefault =>
      'Назначить CuteLauncher лаунчером по умолчанию по ADB';

  @override
  String get adbRestoreDefault =>
      'Восстановить предыдущий лаунчер по умолчанию по ADB';

  @override
  String get adbDefaultHint =>
      'Если выбрать лаунчер в системном меню не получается, используйте ADB.';

  @override
  String get adbBuiltinHint =>
      'После отключения встроенного лаунчера некоторые кнопки на пульте и фирменные меню ТВ могут перестать работать. Чтобы отменить отключение, снова включите встроенный лаунчер.';

  @override
  String get adbHomeBlock => 'Кнопка Home и запуск';

  @override
  String get adbEnableService =>
      'Включить службу специальных возможностей CuteLauncher через ADB';

  @override
  String get adbHomeOverride => 'Переопределять кнопку Home';

  @override
  String get adbHomeOptional =>
      'Если встроенный лаунчер отключён, переопределение Home и запуск при включении ТВ необязательны.';

  @override
  String get adbEnableBuiltin => 'Включить встроенный лаунчер через ADB';

  @override
  String get adbDisableBuiltin => 'Отключить встроенный лаунчер через ADB';

  @override
  String get adbNoBuiltin =>
      'Встроенные лаунчеры Google TV / Android TV не найдены.';

  @override
  String get adbChanged =>
      'Состояние изменилось. Проверьте подключение и подтвердите действие заново.';

  @override
  String get adbEffectHome =>
      'CuteLauncher запросит у Android назначение лаунчером по умолчанию и проверит результат. Текущий лаунчер будет сохранён для восстановления.';

  @override
  String get adbEffectRestore =>
      'Будет включён и назначен прежний лаунчер. Если он недоступен или не сохранён, выбран первый доступный другой лаунчер. Home Button Fix этим действием не отключается.';

  @override
  String get adbEffectDisable =>
      'Приложение встроенного лаунчера будет отключено для пользователя ТВ. Возможна потеря фирменных меню и кнопок. Приложение не удаляется.';

  @override
  String get adbRecoveryHomeDisable =>
      'Также будет отключён весь мастер настройки Google TV, включая резервный домашний экран, чтобы лаунчером по умолчанию стал CuteLauncher. Функции мастера будут недоступны до восстановления. Исходные состояния обоих пакетов сохранятся для восстановления.';

  @override
  String get adbRecoveryHomeRestore =>
      'Мастер настройки Google TV также вернётся в сохранённое состояние.';

  @override
  String get adbDisableHomeUnavailable =>
      'Другой домашний экран имеет более высокий приоритет. Наш лаунчер не может безопасно отключить его.';

  @override
  String get adbEffectEnable =>
      'Встроенный лаунчер вернётся в сохранённое состояние, а если оно не сохранено — будет включён. Система может снова выбрать его лаунчером по умолчанию.';

  @override
  String get adbEffectAccessibility =>
      'Служба специальных возможностей CuteLauncher будет включена. Она сможет получать нажатия Home; перехват управляется отдельным переключателем. Другие службы сохраняются.';

  @override
  String get adbEffectAccessibilityRestore =>
      'Служба CuteLauncher вернётся в состояние до выдачи доступа через ADB. Другие службы специальных возможностей сохраняются.';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher получит право показывать окна поверх других приложений, в том числе ночной фильтр.';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher получит доступ к чтению уведомлений и управлению ими через собственную службу.';

  @override
  String get adbEffectWatchNext =>
      'CuteLauncher получит доступ к данным «Продолжить просмотр».';

  @override
  String get adbEffectUsage =>
      'CuteLauncher получит доступ к статистике использования для трафика и определения приложения на экране.';

  @override
  String get adbEffectWriteSettings =>
      'CuteLauncher сможет изменять системные настройки яркости.';

  @override
  String get adbNoAvailableLauncher =>
      'Другие установленные лаунчеры не найдены. Восстановление недоступно.';

  @override
  String get adbUnsupported =>
      'Недоступно на этом устройстве: нет поддерживаемой команды ADB.';

  @override
  String get adbHomeUnchanged =>
      'Android оставил текущий лаунчер. Чтобы кнопка Home открывала CuteLauncher, настройте Home Button Fix.';

  @override
  String get nightBatteryExempt => 'CuteLauncher исключён из оптимизации';

  @override
  String get nightBatteryHint =>
      'Может помочь расписанию работать в фоне. Не гарантирует сохранение процесса в ожидании.';

  @override
  String get nightBatteryOptimized => 'Для CuteLauncher действует оптимизация';

  @override
  String get nightBatteryTitle => 'Оптимизация энергопотребления';

  @override
  String get nightBatteryUnavailable =>
      'Системное меню недоступно на этой прошивке или доступ запрещён.';

  @override
  String get nightBatteryUnknown => 'Статус исключения неизвестен';

  @override
  String get nightBatteryOpenApps => 'Открыть «Приложения»';

  @override
  String get nightBatteryGuide =>
      '1. В разделе «Приложения» откройте «Специальный доступ».\n2. Выберите «Оптимизация энергопотребления» (иногда «Экономия энергии»).\n3. Найдите CuteLauncher; при необходимости выберите «Все приложения».\n4. Отключите оптимизацию или выберите «Без ограничений».\nНазвания и доступность пунктов зависят от прошивки ТВ.';

  @override
  String get updateNotifications => 'Показывать уведомления об обновлении';

  @override
  String get diagnosticsSave => 'Сохранить отчёт в файл';

  @override
  String get diagnosticsSaved => 'Отчёт сохранён';

  @override
  String get diagnosticsSaveFailed =>
      'Не удалось сохранить отчёт. Проверьте доступность менеджера файлов и папки назначения.';

  @override
  String get memoryCacheSize => 'Размер кэша изображений';

  @override
  String get memoryProcess => 'Память приложения';

  @override
  String get memoryImages => 'Кэши изображений';

  @override
  String get diagnosticsExportOpened =>
      'Выберите папку в открывшемся файловом менеджере и сохраните отчёт.';

  @override
  String get adbDisableService =>
      'Выключить службу специальных возможностей CuteLauncher через ADB';

  @override
  String get adbDefaultSettings => 'Настройки лаунчера по умолчанию';

  @override
  String get adbHomeSettings => 'Настройки кнопки Home';

  @override
  String get adbAccessibilitySettings => 'Перейти в специальные возможности';

  @override
  String get adbAccessibilityGuide =>
      'В системном меню выберите CuteLauncher и включите службу. Затем вернитесь сюда, чтобы настроить перехват кнопки Home. Для отключения выключите службу CuteLauncher в том же меню.';

  @override
  String get adbEffectAccessibilityDisable =>
      'Служба CuteLauncher будет выключена. Перехват кнопки Home перестанет работать. Другие службы специальных возможностей сохраняются.';

  @override
  String get backupAutoEnabled => 'Автоматическое копирование';

  @override
  String get backupClientId => 'Client ID';

  @override
  String get backupClientSecret => 'Client Secret';

  @override
  String get backupCloudImportConfirm =>
      'Все локальные настройки, разделы и изображения будут заменены данными из облака. Продолжить?';

  @override
  String get backupConfigured => 'Настроено';

  @override
  String get backupConnection => 'Настройки подключения';

  @override
  String get backupCreated => 'Создана';

  @override
  String get backupDaily => 'Раз в день';

  @override
  String get backupDriveHelp =>
      'Нажмите «Подключить Google Диск» и подтвердите код на телефоне. Копии видны в папке CuteLauncher на Google Диске: их можно скачивать и удалять. Сохраняйте имена файлов для восстановления в приложении. После обновления со скрытых копий подключитесь повторно; старые копии автоматически не переносятся.';

  @override
  String get backupFrequency => 'Частота копирования';

  @override
  String get backupHourly => 'Раз в час';

  @override
  String get backupLocal => 'Локальные копии';

  @override
  String get backupMinutes => 'мин';

  @override
  String get backupMode => 'Режим';

  @override
  String get backupNever => 'Копия ещё не создана';

  @override
  String get backupNotConfigured => 'Не настроено';

  @override
  String get backupOptions => 'Настройки резервного копирования';

  @override
  String get backupSaveMode => 'Резервное копирование';

  @override
  String get backupScope => 'Резервное копирование разных ТВ';

  @override
  String get backupSyncScope => 'Синхронизация разных ТВ';

  @override
  String get backupSeparate => 'Каждый ТВ отдельно';

  @override
  String get backupShared => 'Для всех единые настройки';

  @override
  String get backupStorage => 'Хранилище';

  @override
  String get backupSyncHelp =>
      'Скачиваем данные и отправляем изменения. При конфликте используем более позднее изменение. Часы ТВ должны быть настроены правильно. Обмен работает, пока лаунчер открыт.';

  @override
  String get backupSyncLimit => 'Проверять не чаще';

  @override
  String get backupSyncMode => 'Синхронизация';

  @override
  String get backupSyncOptions => 'Настройки синхронизации';

  @override
  String get backupTime => 'Время копирования';

  @override
  String get backupWeekday => 'День недели';

  @override
  String get backupWeekly => 'Раз в неделю';

  @override
  String get backupGoogleDrive => 'Google Диск';

  @override
  String get backupLocalHelp =>
      'Локальные копии удаляются вместе с приложением или его данными. Храните копию и вне ТВ.';

  @override
  String get panelObjectOrder => 'Порядок объектов';

  @override
  String get panelInformationGroup => 'Информация';

  @override
  String get panelOrderHint =>
      '◄ / ► — выбрать или закончить перемещение; ▲ / ▼ — изменить порядок, на границе групп — перенести на другую сторону; OK / Back — закончить.';

  @override
  String get panelTextBackgroundTransparency =>
      'Прозрачность подложки текста и кнопок';

  @override
  String get weatherCityHint =>
      'Введите название города на английском языке, например Moscow.';

  @override
  String get weatherCityNotFound =>
      'Не удалось определить город. Выберите его в настройках местоположения.';

  @override
  String get weatherLocationAutomatic => 'Получить автоматически';

  @override
  String get weatherLocationAutomaticHint =>
      'Получить координаты устройства. Потребуется разрешение на местоположение.';

  @override
  String get weatherLocationManual => 'Ввести вручную';

  @override
  String get manualLocationInput => 'Способ ввода';

  @override
  String get manualLocationCity => 'Город';

  @override
  String get manualLocationCoordinates => 'Координаты';

  @override
  String get weatherLocationPermissionDenied =>
      'Разрешите доступ к местоположению в настройках Android и повторите попытку.';

  @override
  String get weatherLocationUnavailable =>
      'Не удалось получить координаты. Проверьте местоположение в Android или введите город вручную.';

  @override
  String get nightFilterSettings => 'Настройки фильтра';

  @override
  String get nightScheduleMenu => 'Расписание';

  @override
  String get nightScheduleInactive => 'Расписание выключено';

  @override
  String get nightLocation => 'Местоположение';

  @override
  String get nightLocationAutomatic => 'Получить автоматически';

  @override
  String get nightLocationManual => 'Ввести вручную';

  @override
  String get nightLocationFailed =>
      'Не удалось получить местоположение. Проверьте разрешение и системную геолокацию.';

  @override
  String get nightCitySearchHint =>
      'Введите название города. Через запятую можно добавить регион или страну.';

  @override
  String get nightOverlayBrief =>
      'Позволяет показывать фильтр поверх других приложений.';

  @override
  String get weatherGetLocation => 'Получить местоположение';

  @override
  String get backupLastCreated => 'Последняя РК была создана:';

  @override
  String get backupManagement => 'Управление резервными копиями';

  @override
  String get backupCopyList => 'Список копий';

  @override
  String get backupRefreshCopyList => 'Обновить список копий';

  @override
  String get backupCreateNow => 'Создать новую копию сейчас';

  @override
  String get backupFolderPath => 'Путь сохранения копий';

  @override
  String get backupPrivateFolder => 'Внутренняя папка приложения';

  @override
  String get backupRestoreCopy => 'Восстановиться из копии';

  @override
  String get backupDeleteConfirm => 'Удалить выбранную резервную копию?';

  @override
  String get blockedAppsGroup => 'Заблокированные приложения';

  @override
  String get notificationSettingsButton => 'Настройки уведомлений';

  @override
  String get hidePersistentNotificationsHint =>
      'Скрыть постоянные уведомления в списке и поверх других приложений.';

  @override
  String get nightTransitionTime => 'Время перехода';

  @override
  String get brightnessSolar => 'По расписанию ночного режима';

  @override
  String get brightnessAfterSunrise => 'После рассвета';

  @override
  String get brightnessAfterSunset => 'После заката';

  @override
  String get brightnessTransitionTime => 'Плавная смена яркости';

  @override
  String get brightnessSolarUnavailable =>
      'Не удалось определить расписание ночного режима. Проверьте время и местоположение в его настройках.';

  @override
  String get persistentNotificationCannotDelete =>
      'Это постоянное уведомление: удалить его нельзя. Его можно только заблокировать.';

  @override
  String get diagnosticsCreateFailed =>
      'Не удалось создать диагностический отчёт. Повторите попытку.';

  @override
  String get backupListFailed =>
      'Не удалось загрузить список резервных копий. Проверьте доступ к выбранному хранилищу.';

  @override
  String get updateInstallerFailed =>
      'Не удалось открыть установщик обновления. Повторите попытку и проверьте доступность установщика Android.';

  @override
  String get backupFolderFailed =>
      'Не удалось выбрать или сохранить папку для копий. Выберите доступную папку и повторите попытку.';

  @override
  String get updateDownloadFailed =>
      'Не удалось скачать обновление. Проверьте подключение к интернету и свободное место.';

  @override
  String get backupDeleteFailed =>
      'Не удалось удалить резервную копию. Проверьте права на удаление и повторите попытку.';

  @override
  String get updateCheckFailed =>
      'Не удалось проверить обновления. Проверьте подключение к интернету и повторите попытку.';

  @override
  String get backupCreateFailed =>
      'Не удалось создать резервную копию. Проверьте доступ к хранилищу и свободное место.';

  @override
  String get wallpaperChangeFailed =>
      'Не удалось изменить обои. Проверьте доступ к файлу и повторите попытку.';

  @override
  String get backupDownloadsFolder => 'Загрузки / CuteLauncher';

  @override
  String get backupChooseFolder => 'Выбрать папку в проводнике';

  @override
  String get backupFolderPickerUnavailable =>
      'На этом ТВ нет проводника с выбором папок. Выберите «Загрузки / CuteLauncher» или внутреннюю папку приложения.';

  @override
  String get driveConfigurationError =>
      'Данные Google Диска не введены или некорректны. Введите Client ID и Client Secret OAuth-клиента для ТВ.';

  @override
  String get driveCodeExpired =>
      'Время входа в Google Диск истекло. Нажмите «Проверить и сохранить аккаунт», чтобы получить новый код.';

  @override
  String get brightnessAfterNightStart => 'Ночью';

  @override
  String get brightnessAfterNightEnd => 'Днём';

  @override
  String get backupSyncSettings => 'Настройки для синхронизации';

  @override
  String get backupSyncHomeGroup => 'Главный экран, разделы и приложения';

  @override
  String get backupSyncAppearanceGroup => 'Оформление, обои и баннеры';

  @override
  String get backupSyncDisplayGroup => 'Ночной режим, яркость и заставка';

  @override
  String get backupSyncControlsGroup => 'Управление лаунчером и ТВ';

  @override
  String get backupSyncGeneralGroup => 'Язык, обновления и прочие настройки';

  @override
  String get backupSyncGroupsHelp =>
      'Выключенные блоки остаются на этом ТВ. Состав синхронизации настраивается отдельно на каждом устройстве.';

  @override
  String get backupSyncGroupsFailed =>
      'Не удалось сохранить выбор настроек для синхронизации. Повторите попытку.';

  @override
  String get tileLayoutMode => 'Режим раскладки';

  @override
  String get tileLayoutAuto => 'Автоматически по размеру';

  @override
  String get tileLayoutColumns => 'Фиксированное количество столбцов';

  @override
  String get tileLayoutRows => 'Фиксированное количество строк';

  @override
  String get tileRowCount => 'Количество строк';

  @override
  String get useGlobalTileSettings => 'Использовать общие настройки';

  @override
  String get centerSelection => 'Центрировать выделение';

  @override
  String get selectionBottom => 'Низ';

  @override
  String get selectionLower => 'Полуниз';

  @override
  String get selectionCenter => 'Центр';

  @override
  String get selectionUpper => 'Полуверх';

  @override
  String get selectionTop => 'Верх';

  @override
  String get settingsStyle => 'Стиль настроек';

  @override
  String get tileFocusEnlargement => 'Увеличение при выделении';

  @override
  String get tileFocusShadowStrength => 'Сила тени';

  @override
  String get tileFocusLift => 'Подъём';

  @override
  String get tileFocusLiftHeight => 'Высота подъёма';

  @override
  String get tileFocusBorderColor => 'Цвет рамки выделения';

  @override
  String get tileFocusAccentColor => 'Акцентный цвет';

  @override
  String get tileFocusDynamicColor => 'Динамические цвета';

  @override
  String get tileSizeFromColumns =>
      'Размер плиток определяется количеством столбцов и шириной раздела.';

  @override
  String get resetSectionToGlobal => 'Сбросить настройки к общим';

  @override
  String get resetSectionToGlobalHint =>
      'Вернуть общие названия, значки и подложку раздела и сбросить поля?';

  @override
  String get resetStyleSection => 'Сбросить настройки этого раздела';

  @override
  String get resetStyleSectionHint =>
      'Вернуть стандартные настройки только этого раздела?';

  @override
  String get notificationStyle => 'Стиль уведомлений';

  @override
  String get styleBackgroundColor => 'Цвет фона';

  @override
  String get styleTransparency => 'Прозрачность фона';

  @override
  String get styleTextSize => 'Размер текста';

  @override
  String get styleTextColor => 'Цвет текста';

  @override
  String get noticeSize => 'Размер уведомления';

  @override
  String get noticeStylePreview => 'Так будет выглядеть уведомление';

  @override
  String get backupSyncHomeOptions => 'Поведение и общие параметры';

  @override
  String get backupSyncBackground => 'Фон и пользовательские баннеры';

  @override
  String get backupSyncTiles => 'Стиль плиток, меню и уведомлений';

  @override
  String get backupSyncWeatherSource => 'Источник и местоположение';

  @override
  String get backupSyncWeatherDisplay => 'Показ погоды и единицы температуры';

  @override
  String get backupSyncNotificationSettings => 'Показ и фильтры уведомлений';

  @override
  String get backupSyncOther => 'Прочие настройки';

  @override
  String get tileFocusBorderStyle => 'Стиль рамки';

  @override
  String get tileFocusOutline => 'Обводка';

  @override
  String get tileFocusGlow => 'Свечение';

  @override
  String get tileFocusNoBorder => 'Без рамки';

  @override
  String get tileShowFocusShadow => 'Показывать тень';

  @override
  String get homeLayoutRow => 'Лента';

  @override
  String get homeLayoutRows => 'Несколько рядов';

  @override
  String get homeLayoutGrid => 'Сетка';

  @override
  String get homeCardCount => 'Карточек на экране по ширине';

  @override
  String get homeAuto => 'Авто';

  @override
  String get homeFree => 'Без закрепления';

  @override
  String get homeAnchored => 'С закреплением';

  @override
  String get homeScrollMode => 'Прокрутка разделов';

  @override
  String get homeSectionPosition => 'Положение активного раздела';

  @override
  String get homeLabelMode => 'Подписи приложений';

  @override
  String get homeLabelNone => 'Без подписей';

  @override
  String get homeLabelSelected => 'Только выбранное приложение';

  @override
  String get homeLabelAll => 'Все приложения';

  @override
  String get homeInherited => 'Общее значение';

  @override
  String get homeOwnReset => 'Вернуть общие настройки';

  @override
  String get homeParameters => 'Поведение главного экрана';

  @override
  String get homeSectionStyle => 'Оформление разделов';

  @override
  String get homeSectionGap => 'Интервал между разделами';

  @override
  String get homeSectionIcons => 'Значки разделов';

  @override
  String get homeInactiveOpacity => 'Непрозрачность неактивных разделов';

  @override
  String get homeResetSection => 'Вернуть общее оформление раздела';

  @override
  String get homeCalculatedSize => 'Размер рассчитан по количеству карточек';

  @override
  String homeGapLimited(int gap) {
    return 'Интервал ограничен до $gap, чтобы сохранить выбранное количество карточек.';
  }

  @override
  String get homeResetLayout => 'Сбросить раскладку раздела';

  @override
  String homeVisibleRows(int count) {
    return 'Полностью видимых строк: $count';
  }

  @override
  String get homeStylePartial =>
      'Действует только в разделах, которые наследуют это значение и поддерживают его в текущем режиме.';

  @override
  String get homeStyleUnavailable =>
      'Недоступно при текущих настройках разделов. Проверьте раскладку и собственные значения разделов.';

  @override
  String get homeStyleNeedsRows => 'Доступно для нескольких рядов или сетки.';

  @override
  String get homeStyleNeedsLabels =>
      'Включите подписи, чтобы менять их размер и цвет.';

  @override
  String get homeStyleNeedsAllLabels =>
      'Расположение настраивается только для подписей всех карточек. Название выбранной карточки находится под разделом.';

  @override
  String get homeStyleNeedsScale => 'Выберите эффект выделения «Увеличение».';

  @override
  String get homeStyleNeedsLift => 'Выберите эффект выделения «Подъём».';

  @override
  String get homeStyleNeedsBorder => 'Сначала включите рамку или свечение.';

  @override
  String get homeStyleNeedsTitle =>
      'Включите заголовок раздела, чтобы показывать его значок.';

  @override
  String get homeStyleEconomy =>
      'Отключено экономией памяти. Сохранённое значение не меняется.';

  @override
  String get homeStyleOpaque =>
      'Уменьшите непрозрачность фона плитки, чтобы было видно размытие.';

  @override
  String get homeStyleOverridden =>
      'Видимые разделы используют собственные значения. Выберите «Использовать общее» в разделе, чтобы применить эту настройку.';

  @override
  String get homeStyleIconHint =>
      'Размер значка действует на карточки с иконкой приложения. TV-баннеры заполняют карточку независимо от него.';

  @override
  String get homeStyleShadowHint =>
      'Экономия памяти ограничивает тень неактивных карточек значением 4. Тень выделения настраивается отдельно.';

  @override
  String get homeStyleTransparent =>
      'При полностью прозрачном фоне его цвет не виден. Увеличьте непрозрачность фона плитки.';

  @override
  String get homeStyleSingleColumn =>
      'В сетке с одним столбцом нет горизонтальных промежутков.';

  @override
  String get homeStyleAutoOnly =>
      'Размер меняется только в разделах с количеством карточек «Авто», которые используют общий размер.';

  @override
  String get sleepTimerThirtySeconds => '30 секунд (тест)';

  @override
  String get sleepTimer => 'Таймер отключения';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours часа',
      many: '$hours часов',
      few: '$hours часа',
      one: '1 час',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1,5 часа';

  @override
  String get sleepTimerAllowExact => 'Разрешить точные таймеры';

  @override
  String get sleepTimerExactRequired =>
      'Разрешите точные таймеры в настройках Android и выберите время ещё раз.';

  @override
  String get sleepTimerAccessRequired =>
      'Включите службу специальных возможностей CuteLauncher или подключите локальный ADB в настройках лаунчера.';

  @override
  String get sleepTimerFailed =>
      'Не удалось установить таймер или выключить ТВ. Проверьте службу специальных возможностей и локальный ADB.';

  @override
  String get nightIgnoreHdmiInputs => 'Игнорировать HDMI-входы';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'При просмотре HDMI ночной фильтр приостанавливается. Нужен доступ к истории использования; распознавание входов зависит от прошивки ТВ.';

  @override
  String get inputsSettings => 'Настройки входов';

  @override
  String get inputsUseCecNames => 'Брать имя устройства из CEC';

  @override
  String get inputsNamesHint =>
      'Приоритет названий: своё имя в CuteLauncher → CEC (если включено) → имя из настроек Android → стандартное имя входа.';

  @override
  String get inputNameHint => 'Пустое поле — автоматическое имя';

  @override
  String get inputsSaveFailed => 'Не удалось сохранить настройки входов';

  @override
  String get inputIcon => 'Иконка входа';

  @override
  String get inputIconTv => 'Телевизор';

  @override
  String get inputIconGame => 'Игровая приставка';

  @override
  String get inputIconComputer => 'Компьютер';

  @override
  String get inputIconReceiver => 'Ресивер';

  @override
  String get inputIconDisc => 'Проигрыватель дисков';

  @override
  String get inputIconStream => 'Медиаприставка';

  @override
  String get nightInputExclusions => 'Игнорирование входов';

  @override
  String get nightSelectInputs => 'Выбрать входы для игнорирования';

  @override
  String get nightNoInputsSelected =>
      'Не выбран ни один вход. Фильтр будет действовать на всех входах.';

  @override
  String get nightPictureExclusions => 'Игнорирование режимов изображения';

  @override
  String get nightPictureExclusionsHint =>
      'Отметьте режимы, в которых нужно приостанавливать затемнение, тёплый слой и связанный TCL-фильтр. Расписание сохраняется. Распознавание проверено на TCL; доступ к истории использования не нужен.';

  @override
  String get nightPictureUnavailable =>
      'Текущий режим изображения недоступен на этой прошивке. Выбор сохранится, но исключения действуют только при успешном распознавании.';

  @override
  String get nightPictureCurrent => 'Текущий режим';

  @override
  String get nightPictureRefresh => 'Обновить текущий режим';

  @override
  String get nightPictureCode => 'Код режима';

  @override
  String get nightPictureStandard => 'Стандарт';

  @override
  String get nightPictureDynamic => 'Динамический';

  @override
  String get nightPictureMovie => 'Кино';

  @override
  String get nightPictureSport => 'Спорт';

  @override
  String get nightPictureIntelligent => 'Интеллектуальный';

  @override
  String get nightPictureBright => 'Яркая (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'Обычный';

  @override
  String get systemApplications => 'Системные приложения';

  @override
  String get removeFromCategory => 'Удалить из раздела';

  @override
  String get noRemovableCategories =>
      'Приложение не добавлено вручную ни в один раздел. Из стандартных автоматических разделов («Все приложения», «Приложения для ТВ», «Приложения не для ТВ») удалить его нельзя — используйте «Скрыть». «Избранное» редактируется вручную.';

  @override
  String get remoteButtonsTitle => 'Ремаппер кнопок пульта';

  @override
  String get remoteButtonsStart => 'Проверить кнопки (120 с)';

  @override
  String get remoteButtonsStop => 'Завершить проверку';

  @override
  String get remoteButtonsControlsHint =>
      'Нажмите «Проверить кнопки», затем нажимайте кнопки в любом меню или открытом приложении. Проверка завершается кнопкой «Завершить проверку» или через 120 секунд.';

  @override
  String get remoteButtonsHint =>
      'После завершения отчёт сохраняется в файл по указанному пути и заменяет предыдущий. Прочитайте или скопируйте файл через ADB: adb pull <путь>. Некоторые системные и фирменные кнопки могут быть недоступны службе.';

  @override
  String get remoteButtonsEmpty =>
      'Событий пока нет. Если кнопка открыла приложение, вернитесь сюда, чтобы посмотреть результат.';

  @override
  String get remoteButtonsService => 'Служба подключена';

  @override
  String get remoteButtonsRefresh => 'Обновить';

  @override
  String get remoteBindings => 'Назначения кнопок';

  @override
  String get remoteMappingsEnabled => 'Включить переназначение';

  @override
  String get remoteMappingsAdd => 'Добавить назначение';

  @override
  String get remoteMappingKey => 'Кнопка';

  @override
  String get remoteMappingAction => 'Действие';

  @override
  String get remoteMappingChooseAction => 'Выбрать действие';

  @override
  String get remoteMappingNavigationGroup => 'Приложения и навигация';

  @override
  String get remoteMappingScreenSoundGroup => 'Экран и звук';

  @override
  String get remoteMappingAutomationGroup => 'Автоматизация';

  @override
  String get remoteMappingLiveTv => 'Открыть эфирное ТВ';

  @override
  String get remoteMappingDisplaySettings => 'Настройки экрана';

  @override
  String get remoteMappingBluetoothSettings => 'Настройки Bluetooth';

  @override
  String get remoteMappingMute => 'Выключить или вернуть звук';

  @override
  String get remoteMappingNeedsAdb => 'Нужен ADB';

  @override
  String get remoteMappingLearn => 'Определить кнопку пульта';

  @override
  String get remoteMappingLearnHint =>
      'Нажмите дополнительную кнопку пульта в течение 30 секунд. Навигацию, Power, голосовой поиск и громкость назначать нельзя.';

  @override
  String get remoteMappingsHint =>
      'Для назначений нужна служба специальных возможностей. В редакторе и во время диагностики назначения приостановлены. Home, Back, стрелки и OK сохраняют навигацию.';

  @override
  String get remoteMappingsReset => 'Сбросить назначения';

  @override
  String get remoteMappingsResetConfirm =>
      'Удалить все назначения и выключить переназначение?';

  @override
  String get remoteMappingInvalid =>
      'Не удалось сохранить. Проверьте кнопку и цель. Для webhook нужен HTTPS либо HTTP в локальной сети.';

  @override
  String get remoteMappingBack => 'Назад';

  @override
  String get remoteMappingProfile => 'Профиль';

  @override
  String get remoteMappingChannels => 'Каналы';

  @override
  String get remoteMappingQuickSettings => 'Быстрые настройки TCL';

  @override
  String get remoteMappingTrigger => 'Тип нажатия';

  @override
  String get remoteMappingPress => 'Короткое нажатие';

  @override
  String get remoteMappingHold => 'Удержание';

  @override
  String get remoteMappingHoldHint =>
      'Удерживайте 650 мс: действие выполнится один раз, без короткого нажатия. Если назначено только удержание, короткое нажатие ничего не делает.';

  @override
  String get remotePanelDescription =>
      'Панель быстрых настроек позволяет видеть нужные виджеты поверх других приложений. Чтобы открывать её с пульта, назначьте действие «Панель быстрых настроек» на удобную кнопку.';

  @override
  String get remotePanel => 'Панель быстрых настроек';

  @override
  String get remotePanelSettingsBackground => 'Цвет фона как в настройках';

  @override
  String get remotePanelPreview => 'Открыть панель';

  @override
  String get settingsHelp => 'Подробнее';

  @override
  String get settingsHelpScroll => '▲ / ▼ — читать текст';

  @override
  String get panelClockStyle => 'Оформление часов';

  @override
  String get clockPreset => 'Стиль шрифта';

  @override
  String get clockCustom => 'Свой вариант';

  @override
  String get clockWeight => 'Толщина шрифта';

  @override
  String get clockGlow => 'Свечение текста';

  @override
  String get clockAnimate => 'Анимация цифр';

  @override
  String get clockBackground => 'Подложка часов';

  @override
  String get clockRadius => 'Скругление подложки';

  @override
  String get dateCalendarEnabled => 'Открывать календарь по нажатию на дату';

  @override
  String get calendarTitle => 'Календарь';

  @override
  String get dateSettings => 'Настройки даты';

  @override
  String get clockSharedBackground => 'Подложка как у других объектов';

  @override
  String get clockDefaultBackground => 'Подложка по умолчанию';

  @override
  String get remotePanelInheritAppearance =>
      'Дублировать оформление верхней панели';

  @override
  String get remotePanelDisabledInLauncher =>
      'Вызов панели быстрых настроек отключён, пока открыт CuteLauncher.';

  @override
  String get remoteAccessSettings => 'Настройка доступа';

  @override
  String get remoteButtonsTest => 'Проверка кнопок';

  @override
  String remoteMappingDeleteConfirm(String name) {
    return 'Удалить назначение «$name»?';
  }

  @override
  String get remoteMappingConflict =>
      'Эта кнопка с таким типом нажатия уже назначена. Выберите другую кнопку или тип нажатия.';

  @override
  String get cleanerTitle => 'Менеджер очистки ТВ';

  @override
  String get cleanerRefresh => 'Обновить список приложений';

  @override
  String get cleanerSnapshot => 'Сохранить исходное состояние';

  @override
  String get cleanerRestore => 'Восстановиться из базовой копии';

  @override
  String get cleanerSnapshotSaved => 'Исходное состояние сохранено';

  @override
  String get cleanerExportSnapshot => 'Экспортировать исходное состояние';

  @override
  String get cleanerSafe => 'Отключить проверенные приложения';

  @override
  String get cleanerNoSafe =>
      'Для этой модели и прошивки нет подходящего списка системных приложений.';

  @override
  String get cleanerLocal => 'Отключить по списку из файла';

  @override
  String get cleanerProject => 'Списки из каталога проекта';

  @override
  String get cleanerRemoteProject => 'Обновить каталог из GitHub';

  @override
  String get cleanerExternal => 'Примеры CleanYourTV';

  @override
  String get cleanerDisabledExport =>
      'Экспортировать отчёт об отключениях в файл';

  @override
  String get cleanerInventoryExport => 'Экспортировать отчёт о приложениях';

  @override
  String get cleanerApps => 'Все приложения';

  @override
  String get cleanerEnable => 'Включить приложение';

  @override
  String get cleanerDisable => 'Отключить приложение';

  @override
  String get cleanerProtected => 'Защищено от отключения';

  @override
  String get cleanerUnknown =>
      'Назначение и зависимости не подтверждены. Риск отключения неизвестен.';

  @override
  String get cleanerConfirm => 'Применить изменение?';

  @override
  String get cleanerConfirmText =>
      'Изменится доступность перечисленных приложений и связанных функций. Исходное состояние будет сохранено до изменения. Откат доступен в этом менеджере, пока работают лаунчер и ADB.';

  @override
  String get cleanerObserved =>
      'Список наблюдений: безопасность отключения не проверена.';

  @override
  String get cleanerMismatch =>
      'Список относится к другой прошивке и не будет применён.';

  @override
  String get cleanerMissing => 'Нет доступных пакетов для изменения.';

  @override
  String get cleanerFailure =>
      'Действие не завершено. Проверьте подключение ADB и формат списка.';

  @override
  String get cleanerPartial =>
      'Изменения выполнены частично. Сохранён журнал для отката; обновите список и восстановите изменения при необходимости.';

  @override
  String get cleanerDone => 'Готово';

  @override
  String get cleanerSaved => 'Файл сохранён или передан файловому менеджеру';

  @override
  String get cleanerGitUnavailable =>
      'Каталог недоступен. Для приватного Git используйте встроенный каталог или файл; ключи доступа в APK не хранятся.';

  @override
  String get cleanerSystem => 'Системное приложение';

  @override
  String get cleanerUser => 'Пользовательское приложение';

  @override
  String get cleanerRisk => 'Риск отключения';

  @override
  String get cleanerHelp =>
      'Менеджер работает через локальное ADB-подключение и меняет доступность приложений без удаления APK и их данных. Базовая копия и ручные состояния находятся в «Бэкап и восстановление». Списки наблюдений и сторонние примеры не подтверждают безопасность отключения. Отчёты сохраняются в файл и передаются в Git проекта вручную, автоматически ничего не отправляется.';

  @override
  String get cleanerSkipped =>
      'Пропущены: защищённые, отсутствующие или уже в нужном состоянии';

  @override
  String get cleanerUnidentified => 'Приложение не опознано.';

  @override
  String get cleanerPending => 'Изменено менеджером';

  @override
  String get cleanerNoSnapshot => 'Исходное состояние ещё не сохранено';

  @override
  String get interfaceStyle => 'Стиль интерфейса';

  @override
  String get interfaceStandard => 'Стандартный';

  @override
  String get interfaceCalm => 'Спокойный';

  @override
  String get interfaceGlass => 'Стекло';

  @override
  String get interfaceSoft => 'Мягкий';

  @override
  String get interfaceOutline => 'Контурный';

  @override
  String get interfaceFont => 'Шрифт интерфейса';

  @override
  String get interfaceSystemFont => 'Системный';

  @override
  String get combinedInformation => 'Объединить часы, дату и погоду';

  @override
  String get adaptiveLandscape => 'Адаптивный пейзаж';

  @override
  String get landscapeDemoSpring => 'Весна';

  @override
  String get landscapeDemoSummer => 'Лето';

  @override
  String get landscapeDemoAutumn => 'Осень';

  @override
  String get landscapeDemoWinter => 'Зима';

  @override
  String get landscapeDemoClear => 'Ясно';

  @override
  String get landscapeDemoCloudy => 'Облачно';

  @override
  String get landscapeDemoFog => 'Туман';

  @override
  String get landscapeDemoStart => 'Демонстрация изменений';

  @override
  String get landscapeDemoStop => 'Стоп';

  @override
  String get landscapeVariant => 'Стиль пейзажа';

  @override
  String get landscapeIllustrated => 'Рисованный';

  @override
  String get landscapeRealistic => 'Реалистичный';

  @override
  String get landscapeTimeOfDay => 'Время суток';

  @override
  String get landscapeSeasons => 'Времена года';

  @override
  String get landscapeHemisphere => 'Полушарие';

  @override
  String get landscapeAuto => 'Автоматически';

  @override
  String get landscapeNorth => 'Северное';

  @override
  String get landscapeSouth => 'Южное';

  @override
  String get landscapeClouds => 'Облака';

  @override
  String get landscapePrecipitation => 'Дождь и снег';

  @override
  String get landscapeFog => 'Туман';

  @override
  String get landscapeMotion => 'Анимация погоды';

  @override
  String get landscapeHelp =>
      'Время суток следует сохранённым рассвету и закату из ночного режима; без них рассвет — в 06:00, закат — в 18:00, переходные периоды — по 40 минут до и после. Сезон определяется местным месяцем и полушарием; автоматический выбор использует координаты погоды, затем ночного режима, затем Северное полушарие. При отключении времени суток остаётся день, при отключении сезонов — лето. Погода берётся из текущих данных выбранного источника без дополнительных запросов. Если данных нет или они устарели, небо ясное. Облака, осадки и туман отключаются независимо. Движение по умолчанию выключено, останавливается вне главного экрана и отключается при экономии памяти или системном ограничении анимаций.';

  @override
  String get inputConnected => 'Подключён';

  @override
  String get inputStandby => 'Подключён · ожидание';

  @override
  String get inputDisconnected => 'Отключён';

  @override
  String get inputStateUnknown => 'Состояние подключения недоступно';

  @override
  String get weatherMetNorwayCredit =>
      'Данные: MET Norway, CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Прогноз адаптирован: https://api.met.no/. Без API-ключа; дни по часовому поясу ТВ, минимум и максимум по доступным периодам. Вероятность осадков не предоставляется.';

  @override
  String get informationGroup => 'Часы, дата и погода';

  @override
  String get informationSettings => 'Настройки блока';

  @override
  String get informationAppearance => 'Оформление блока';

  @override
  String get informationSize => 'Общий размер блока';

  @override
  String get informationPosition => 'Расположение часов и текста';

  @override
  String get informationClockLeft => 'Часы слева, текст справа';

  @override
  String get informationClockRight => 'Текст слева, часы справа';

  @override
  String get informationSpacing => 'Расстояние между часами и текстом';

  @override
  String get informationBackground => 'Подложка блока';

  @override
  String get homeResetTilesHint =>
      'Вернуть общие значения всех параметров плиток и подписей на этом экране?';

  @override
  String get homeResetLayoutHint =>
      'Сбросить раскладку раздела, вернуть общее оформление и обнулить поля? Приложения и их порядок сохранятся.';

  @override
  String get networkSummary => 'Сеть';

  @override
  String get networkConnected => 'Интернет доступен';

  @override
  String get networkOffline => 'Нет доступа к интернету';

  @override
  String get networkDisconnected => 'Нет подключения';

  @override
  String get networkConnection => 'Подключение';

  @override
  String get networkSignal => 'Сигнал';

  @override
  String get networkLinkSpeed => 'Скорость Wi-Fi';

  @override
  String get networkTrafficRate => 'Трафик устройства · приём / передача';

  @override
  String get networkSystemSettings => 'Системные настройки сети';

  @override
  String get networkUnavailable => 'Недоступно';

  @override
  String get networkMobile => 'Мобильная сеть';

  @override
  String get networkFrequency => 'Частота';

  @override
  String get networkMbps => 'Мбит/с';

  @override
  String get networkKbps => 'КБ/с';

  @override
  String get networkReadFailed => 'Не удалось получить состояние сети';

  @override
  String get clockItalic => 'Курсив';

  @override
  String get panelWrapNavigation => 'Круговая навигация по панели';

  @override
  String get panelWrapNavigationHelp =>
      'Стрелки влево и вправо переводят фокус с крайней кнопки на противоположный край панели. Удерживайте стрелку для непрерывного перемещения между обеими сторонами.';

  @override
  String get networkReceive => 'Приём';

  @override
  String get networkSend => 'Передача';

  @override
  String get landscapeCelestialBodies => 'Солнце и луна';

  @override
  String get landscapeStarRotation => 'Вращение звёзд';

  @override
  String get tvPowerTitle => 'Управление питанием';

  @override
  String remotePowerWithConfirmation(String action) {
    return '$action (с подтверждением)';
  }

  @override
  String remotePowerWithoutConfirmation(String action) {
    return '$action (без подтверждения)';
  }

  @override
  String get tvPowerOff => 'Выключить устройство';

  @override
  String get tvPowerReboot => 'Перезагрузить устройство';

  @override
  String get tvPowerOffConfirm => 'Перевести устройство в режим ожидания?';

  @override
  String get tvPowerRebootConfirm =>
      'Перезагрузить устройство? Открытые приложения будут закрыты.';

  @override
  String get tvPowerSent => 'Команда отправлена';

  @override
  String get tvPowerFailed =>
      'Не удалось отправить команду. Проверьте ADB или специальные возможности.';

  @override
  String get tvPowerHelp =>
      'Выключение переводит устройство в ожидание через службу специальных возможностей CuteLauncher или локальный ADB. Для перезагрузки нужен ADB. На приставке команда управляет приставкой; поведение телевизора зависит от HDMI-CEC и прошивки.';

  @override
  String get cleanerLists => 'Списки отключения';

  @override
  String get cleanerRecovery => 'Бэкап и восстановление';

  @override
  String get cleanerExports => 'Отчёты';

  @override
  String get cleanerUpdating => 'Обновляется список приложений…';

  @override
  String get cleanerRefreshRequired => 'Сначала обновите список приложений.';

  @override
  String get cleanerPreinstalled => 'Предустановленное приложение';

  @override
  String get cleanerNotSystem => 'Это не системное приложение.';

  @override
  String get cleanerMinimalRisk => 'Минимальный';

  @override
  String get cleanerCacheFailure =>
      'Не удалось запомнить список для следующего входа.';

  @override
  String get cleanerUserApps => 'Пользовательские приложения';

  @override
  String get cleanerPreinstalledApps => 'Предустановленные приложения';

  @override
  String get cleanerSystemApps => 'Системные приложения';

  @override
  String get cleanerBaseline => 'Базовое исходное состояние';

  @override
  String get cleanerManualStates => 'Управление ручными состояниями';

  @override
  String get cleanerManualSave => 'Сохранить текущее состояние';

  @override
  String get cleanerDateName => 'Использовать дату и время';

  @override
  String get cleanerCustomName => 'Задать имя';

  @override
  String get cleanerStateExport => 'Экспортировать сохранение в файл';

  @override
  String get cleanerStateRestoreHelp =>
      'Будут восстановлены сохранённые состояния включения и отключения приложений для этой прошивки. Приложения, установленные после создания копии, останутся без изменений. Отсутствующие приложения и отключение защищённых компонентов будут пропущены. Данные приложений не восстанавливаются.';

  @override
  String get cleanerCopiesHelp =>
      'Базовое исходное состояние создаётся один раз при первом успешном обновлении списка и не удаляется и не перезаписывается средствами лаунчера. Оно привязано к прошивке. Ручные состояния сохраняют текущие режимы приложений, имеют имя и дату; их можно восстанавливать, удалять и экспортировать. Копии не содержат APK и данных приложений. Восстановление требует локального ADB. При срабатывании защиты от падений лаунчер пытается автоматически вернуть базовое состояние. Очистка данных или удаление лаунчера удаляет и эти копии; защита от root-доступа невозможна.';

  @override
  String get cleanerSearch => 'Поиск по имени';

  @override
  String get cleanerCatalogUpdateRequired =>
      'Сначала обновите каталог из GitHub.';

  @override
  String get cleanerNoSearchResults => 'Подходящих записей нет.';

  @override
  String get cleanerAlreadyDisabled =>
      'Все приложения из списка, которые есть на этом ТВ, уже отключены.';

  @override
  String get cleanerAlreadyEnabled =>
      'Все приложения из списка, которые есть на этом ТВ, уже включены.';

  @override
  String get cleanerNoInstalled =>
      'На этом ТВ нет подходящих установленных приложений из списка.';

  @override
  String get cleanerListProtected =>
      'Оставшиеся приложения защищены от отключения.';

  @override
  String get cleanerSnapshotFailed =>
      'Не удалось сохранить снимок. Приложения не отключены.';

  @override
  String get cleanerDisableAllPreinstalled => 'Отключить все предустановленные';

  @override
  String get cleanerEnableAllPreinstalled => 'Включить все предустановленные';

  @override
  String get cleanerPreinstalledList => 'Список предустановленных приложений';

  @override
  String cleanerBeforeList(String listName) {
    return 'Перед применением списка: $listName';
  }

  @override
  String get sleepTimerSettings => 'Настройки таймера отключения';

  @override
  String get sleepTimerPresets => 'Таймеры';

  @override
  String get sleepTimerDisplay => 'Показывать при активном таймере';

  @override
  String get sleepTimerRemaining => 'Оставшееся время';

  @override
  String get sleepTimerEndTime => 'Время отключения';

  @override
  String get sleepTimerBoth => 'Оставшееся время и время отключения';

  @override
  String get sleepTimerShowSeconds => 'Показывать секунды';

  @override
  String get sleepTimerShowOverApps => 'Показывать таймер поверх приложений';

  @override
  String get sleepTimerOverlayHelp =>
      'Для показа поверх приложений включите службу специальных возможностей CuteLauncher.';

  @override
  String get sleepTimerCloseAfterSelection =>
      'Закрывать виджет после выбора таймера';

  @override
  String get sleepTimerAdd => 'Добавить таймер';

  @override
  String get sleepTimerEdit => 'Изменить таймер';

  @override
  String get sleepTimerHoursLabel => 'Часы';

  @override
  String get sleepTimerMinutesLabel => 'Минуты';

  @override
  String get sleepTimerSecondsLabel => 'Секунды';

  @override
  String get sleepTimerInvalidDuration =>
      'Укажите время больше нуля: часы 0–999999, минуты и секунды 0–59.';

  @override
  String get sleepTimerDeleteConfirmation =>
      'Удалить этот таймер? Запущенный отсчёт продолжится.';

  @override
  String get sleepTimerResetConfirmation =>
      'Восстановить стандартные таймеры и их порядок? Свои таймеры будут удалены. Запущенный отсчёт продолжится.';

  @override
  String get sleepTimerReorderHint =>
      '◄ / ► или удержание OK — перемещение. ▲ / ▼ меняют порядок и переносят таймер между отображаемыми и скрытыми. OK завершает перемещение.';

  @override
  String get sleepTimerSaveFailed => 'Не удалось сохранить настройки таймера.';

  @override
  String get sleepTimerVisible => 'Отображаемые';

  @override
  String get sleepTimerHidden => 'Скрытые';

  @override
  String get sleepTimerReset => 'Сбросить таймеры';

  @override
  String get cleanerListSnapshotHelp =>
      'Перед отключением по списку автоматически сохраняется снимок только выбранных приложений. Его восстановление не меняет остальные приложения. Лимит — 100 ручных и автоматических снимков. Если сохранить снимок нельзя, отключение не начинается.';

  @override
  String get trafficSettings => 'Настройки трафика';

  @override
  String get trafficTitle => 'Трафик';

  @override
  String get trafficReceived => 'Получено';

  @override
  String get trafficSent => 'Отправлено';

  @override
  String get trafficTotal => 'Всего';

  @override
  String get stopApp => 'Остановить';

  @override
  String get backgroundImageFormats =>
      'Изображения: JPEG, PNG, WebP, GIF, BMP — до 8 МиБ, 48 мегапикселей и 16 384 пикселей по каждой стороне.';

  @override
  String get backgroundMediaFormats =>
      'Изображения: JPEG, PNG, WebP, GIF, BMP — до 8 МиБ, 48 мегапикселей и 16 384 пикселей по каждой стороне.\nВидео: MP4/M4V, WebM, MKV — до 256 МиБ и 3840×2160. Поддержка кодека зависит от ТВ; предпочтительно MP4 с H.264. Видео повторяется без звука и приостанавливается вне главного экрана. Видео не включается в резервные копии.';

  @override
  String get backgroundFormatError =>
      'Формат не поддерживается или файл повреждён. Выберите исправный файл одного из указанных форматов.';

  @override
  String backgroundFileTooLarge(String maxMiB) {
    return 'Файл слишком большой. Допустимый размер — до $maxMiB МиБ. Выберите файл меньшего размера.';
  }

  @override
  String get backgroundImageResolutionError =>
      'Изображение слишком большое: не более 48 мегапикселей и 16 384 пикселей по каждой стороне.';

  @override
  String get backgroundVideoResolutionError =>
      'Разрешение видео слишком большое. Выберите видео не выше 3840×2160 (или 2160×3840).';

  @override
  String get backgroundVideoCodecError =>
      'ТВ не смог воспроизвести это видео: кодек не поддерживается или файл повреждён. Попробуйте MP4 с H.264.';

  @override
  String get backgroundFileApplied => 'Файл выбран. Фон обновлён.';

  @override
  String get noticePosition => 'Расположение уведомлений';

  @override
  String get noticeBottomRight => 'Внизу справа';

  @override
  String get noticeBottomLeft => 'Внизу слева';

  @override
  String get noticeTopRight => 'Вверху справа';

  @override
  String get noticeTopLeft => 'Вверху слева';

  @override
  String get overlayAppearance => 'Оформление поверх приложений';

  @override
  String get overlayAppearanceTopPanel => 'Как в верхней панели';

  @override
  String get overlayAppearanceDark => 'Тёмное';

  @override
  String get overlayWhereToShow => 'Где показывать';

  @override
  String get overlayAtPanelWidget => 'На месте виджета в верхней панели';

  @override
  String get notificationOpenFailed =>
      'Не удалось открыть действие уведомления. Возможно, оно больше недоступно.';

  @override
  String get adbWifiOverride => 'Всё равно отключить…';

  @override
  String get adbWifiRiskTitle => 'Отключить, несмотря на риск?';

  @override
  String get adbWifiRiskEffect =>
      'Будут отключены встроенный лаунчер и мастер настройки Google.';

  @override
  String get adbWifiRiskLoss =>
      'Android может удалить сохранённые Wi-Fi-сети. Подключение по Wi-Fi и беспроводной ADB могут стать недоступны.';

  @override
  String get adbWifiRiskRecovery =>
      'Повторное включение мастера настройки не вернёт удалённые сети автоматически. Потребуется заново подключиться к Wi-Fi и ввести пароль.';

  @override
  String get adbWifiRiskConsent =>
      'Продолжайте, только если знаете пароль Wi-Fi.';

  @override
  String get adbWifiDisable => 'Отключить';

  @override
  String get recentAppsTitle => 'Открытые приложения';

  @override
  String get recentAppsPanelType => 'Панель';

  @override
  String get recentAppsAutomatic => 'Автоматически';

  @override
  String get recentAppsCustom => 'Панель CuteLauncher';

  @override
  String get recentAppsSystem => 'Встроенная панель';

  @override
  String get recentAppsOpen => 'Открыть панель';

  @override
  String get recentAppsRefresh => 'Обновить';

  @override
  String get recentAppsCloseAll => 'Закрыть всё';

  @override
  String get recentAppsEmpty => 'Нет ТВ-приложений с открытыми задачами';

  @override
  String get recentAppsUnavailable =>
      'Панель открытых приложений недоступна. Проверьте ADB и доступ специальных возможностей.';

  @override
  String get recentAppsHelp =>
      'Показаны только ТВ-приложения с открытыми задачами. «Закрыть всё» останавливает пользовательские приложения из этого списка. Кнопка назначается в ремаппере. Для панели CuteLauncher нужны ADB и доступ специальных возможностей.';

  @override
  String get recentAppsHomeHint =>
      'Для Home доступно только удержание. Короткое нажатие возвращает в CuteLauncher. Назначение действует и вне лаунчера.';

  @override
  String get sectionRulesHelp =>
      'Стандартные разделы можно переименовывать, перемещать и скрывать, но нельзя удалять; хотя бы один должен оставаться видимым. «Все приложения», «Приложения для ТВ» и «Приложения не для ТВ» заполняются автоматически по типу запуска, а не по имени приложения; «Скрыть» убирает приложение из всех трёх списков. «Избранное» и свои разделы заполняются вручную. Порядок приложений: вручную, по имени, частоте или последнему запуску; оформление настраивается для каждого раздела. «Продолжить просмотр» показывает рекомендации приложений, его можно скрывать и перемещать.';

  @override
  String get remoteMappingNamePlaceholder => 'Название кнопки';

  @override
  String get remoteMappingAssign => 'Назначить кнопку';

  @override
  String get remoteMappingCapture => 'Захватить';

  @override
  String remoteMappingCaptured(String key) {
    return 'Захваченная кнопка: $key';
  }

  @override
  String get remoteMappingCaptureHint =>
      'Нажмите «Захватить», затем нужную кнопку пульта. Захват можно повторить. Нажмите ОК, чтобы принять выбор.';

  @override
  String get remoteMappingCaptureTimeout =>
      'Кнопка не захвачена. Нажмите «Захватить» и попробуйте ещё раз.';

  @override
  String get remoteMappingCaptureFailed =>
      'Не удалось захватить кнопку. Проверьте доступ к службе специальных возможностей и повторите захват.';

  @override
  String get remoteMappingServiceRequired =>
      'Для захвата кнопки подключите службу в «Настройке доступа» ремаппера.';

  @override
  String get remoteMappingKeyRequired =>
      'Кнопка не назначена. Нажмите «Назначить кнопку» и захватите кнопку пульта.';

  @override
  String get remoteMappingHomeHoldRequired =>
      'Для Home выберите тип нажатия «Удержание».';

  @override
  String get remoteMappingAppRequired => 'Выберите приложение для запуска.';

  @override
  String get remoteMappingUrlRequired =>
      'Введите Webhook URL или импортируйте его из файла.';

  @override
  String get remoteMappingUrlInvalid =>
      'Неверный Webhook URL. Нужен HTTPS либо HTTP в локальной сети, с путём вызова, без пробелов, логина и фрагмента #.';

  @override
  String get remoteMappingSaveFailed =>
      'Не удалось записать назначение на устройстве. Повторите сохранение; введённые значения сохранены в редакторе.';

  @override
  String get remoteMappingDeleteFailed =>
      'Не удалось удалить назначение на устройстве. Повторите удаление.';

  @override
  String get remoteMappingRecents => 'Панель открытых приложений';

  @override
  String get remoteMappingImport => 'Импортировать URL из файла';

  @override
  String get remoteMappingImportHint =>
      'Выберите текстовый файл UTF-8, содержащий только Webhook URL, без команд и пояснений. Переносы строк удаляются.';

  @override
  String get remoteMappingImportInvalid =>
      'В файле должен быть только корректный Webhook URL: HTTPS либо HTTP в локальной сети, без команд и пояснений.';

  @override
  String get remoteMappingImportFailed =>
      'Не удалось прочитать файл. Выберите доступный текстовый файл UTF-8 размером до 64 КБ.';

  @override
  String get vpnTitle => 'VPN';

  @override
  String get vpnSettings => 'Настройки VPN';

  @override
  String get vpnApp => 'VPN-приложение';

  @override
  String get vpnAutomatic => 'Автоматически';

  @override
  String get vpnNone => 'Не выбрано';

  @override
  String get vpnProfile => 'Профиль VPN';

  @override
  String get vpnOnlyActive => 'Показывать только при подключении';

  @override
  String get vpnShowName => 'Показывать название приложения';

  @override
  String get vpnColor => 'Выделять подключение цветом';

  @override
  String get vpnNotify => 'Уведомлять о результате команд';

  @override
  String get vpnConnected => 'VPN подключён';

  @override
  String get vpnDisconnected => 'VPN отключён';

  @override
  String get vpnUnknown => 'Состояние VPN недоступно';

  @override
  String get vpnConnect => 'Подключить';

  @override
  String get vpnDisconnect => 'Отключить';

  @override
  String get vpnOpenApp => 'Открыть VPN-приложение';

  @override
  String get vpnAndroidSettings => 'Настройки VPN Android';

  @override
  String get vpnAllowControl => 'Разрешить управление VPN';

  @override
  String get vpnFailed => 'Не удалось выполнить действие VPN';

  @override
  String get vpnUnsupported =>
      'Клиент не поддерживает прямое управление. Можно открыть приложение.';

  @override
  String get vpnOther =>
      'Подключён другой или неопределённый VPN. Управление недоступно.';

  @override
  String get vpnStartup => 'VPN при старте ТВ';

  @override
  String get vpnPending => 'Ожидание подключения VPN';

  @override
  String get vpnHelp =>
      'Автоматический выбор подхватывает активный VPN и запоминает его для повторного подключения. Определение приложения и профиля требует подключённого локального АДБ. Прямое управление доступно AmneziaWG и WireGuard с разрешением управления и включённым внешним управлением в клиенте. Happ и MantaRay используют профиль, выбранный в самом клиенте.';

  @override
  String get vpnProfileHelp =>
      'Укажите точное имя профиля из VPN-приложения: до 15 латинских букв, цифр и символов _ = + . -. При ручном подключении имя подхватывается автоматически, если оно доступно.';

  @override
  String get vpnStartupHelp =>
      'VPN запускается дополнительно к обычному автозапуску. Заранее настройте профиль и разрешения клиента. Ожидание сети ограничено; уже активный VPN не заменяется. Пробуждение отслеживается только пока процесс лаунчера работает.';

  @override
  String get vpnStartupMethod => 'Способ запуска VPN';

  @override
  String get vpnStartupClient => 'Через VPN-приложение';

  @override
  String get vpnStartupAlwaysOn => 'Постоянный VPN Android';

  @override
  String get vpnAlwaysOnManaged =>
      'VPN управляется постоянным режимом Android. Отключите этот режим в настройках автозапуска или Android.';

  @override
  String get vpnRestartRequired =>
      'Для применения системного режима перезапустите ТВ.';

  @override
  String get vpnAlwaysOnHelp =>
      'Назначает подготовленный клиент постоянным VPN через локальное TCP АДБ. Android применяет выбор после перезапуска ТВ. Блокировка соединений без VPN не включается и не меняется. При выходе из этого режима восстанавливается прежний системный выбор.';

  @override
  String get vpnClientConfirmation => 'Подтвердите команду в окне MantaRay.';

  @override
  String get informationTapAction => 'При нажатии на блок';

  @override
  String get informationShowBoth => 'Погода и календарь';

  @override
  String get weatherTextFormat => 'Формат текста погоды';

  @override
  String get weatherTextTemperature => 'Температура';

  @override
  String get weatherTextApparent => 'Ощущается';

  @override
  String get weatherTextConditions => 'Условия';

  @override
  String get weatherTextHumidity => 'Влажность';

  @override
  String get weatherTextLow => 'Мин. сегодня';

  @override
  String get weatherTextHigh => 'Макс. сегодня';

  @override
  String get weatherTextLiteral => 'Свой текст';

  @override
  String get weatherTextNewline => 'Перенос строки';

  @override
  String get weatherTextBefore => 'Перед блоком';

  @override
  String get weatherTextAfter => 'После блока';

  @override
  String get weatherTextYourFormat => 'Ваш формат';

  @override
  String get weatherTextAdd => 'Добавить блок';

  @override
  String get weatherTextMoveEarlier => 'Переместить раньше';

  @override
  String get weatherTextMoveLater => 'Переместить позже';

  @override
  String get weatherTextHelp =>
      'Введите свой текст и обозначения в фигурных скобках или вставляйте их кнопками в позицию курсора. Регистр не важен. Круглые скобки вокруг одного значения скрываются вместе с ним, если данных нет. Обычные фигурные скобки удваивайте. Разрешён один перенос строки. С клавиатуры можно вводить буквы, цифры, пробелы и любые печатные символы, например: () [] / : ; + − ° % ·.';

  @override
  String get weatherTextSaveError =>
      'Не удалось сохранить формат текста погоды.';

  @override
  String get weatherTextSampleCity => 'Санкт-Петербург';

  @override
  String weatherTextMetersPerSecond(String speed) {
    return '$speed м/с';
  }

  @override
  String weatherFeelsLike(String temperature) {
    return 'Ощущается как $temperature';
  }

  @override
  String get weatherForecastTitle => 'Прогноз погоды';

  @override
  String get weatherForecastPeriod => 'Период прогноза';

  @override
  String weatherForecastDays(int days) {
    return '$days суток';
  }

  @override
  String get weatherForecastView => 'Вид прогноза';

  @override
  String get weatherForecastCards => 'Компактные карточки';

  @override
  String get weatherForecastList => 'Подробный список';

  @override
  String weatherForecastAvailable(int available, int requested) {
    return 'Доступно дней: $available из $requested';
  }

  @override
  String get weatherForecastTvTime => 'Даты прогноза по времени ТВ';

  @override
  String get weatherClear => 'Ясно';

  @override
  String get weatherCloudy => 'Облачно';

  @override
  String get weatherFog => 'Туман';

  @override
  String get weatherWind => 'Ветер';

  @override
  String get weatherPrecipitation => 'Осадки';

  @override
  String get showVolume => 'Показывать громкость';

  @override
  String get audioStatusTitle => 'Громкость и аудиовыход';

  @override
  String get audioOutputTv => 'ТВ';

  @override
  String get audioOutputHeadphones => 'Наушники';

  @override
  String get audioOutputMultiple => 'Несколько';

  @override
  String get audioMuted => 'Звук выключен';

  @override
  String get backgroundStartupTitle => 'Приложения в фоне';

  @override
  String get backgroundStartupFailed =>
      'Не удалось загрузить или сохранить настройки';

  @override
  String get backgroundStartupRetry => 'Повторить';

  @override
  String get backgroundStartupEmpty => 'Нет пользовательских приложений';

  @override
  String get backgroundStartupUnavailable => 'Запуск в фоне недоступен';

  @override
  String get backgroundStartupRequested => 'Запуск запрошен';

  @override
  String get backgroundStartupHelp =>
      'Отметьте приложения для однократного запуска в фоне после загрузки ТВ. CuteLauncher должен открыться в течение минуты после загрузки: назначьте его домашним экраном или включите запуск лаунчера при загрузке. Приложения запускаются по очереди за домашним экраном; выбор галочки не запускает их сразу. Нажатие пульта или уход из лаунчера отменяет оставшиеся запуски. Пробуждение из сна не запускает их повторно. Некоторые приложения не поддерживают такой режим и недоступны для выбора. Запуск не включает функции внутри приложения и не гарантирует постоянную работу: выдайте нужные разрешения и настройте фоновую работу в самом приложении. Android и прошивка ТВ могут остановить его. Выбор хранится только на этом ТВ.';

  @override
  String get backgroundStartupToggle => 'Автозагрузка в фоне';

  @override
  String get systemWidgetSettings => 'Настройки виджета «Система»';

  @override
  String get systemShowCpu => 'Показывать CPU в панели';

  @override
  String get systemShowRam => 'Показывать RAM в панели';

  @override
  String get systemStorage => 'Накопитель: свободно / всего';

  @override
  String get systemUptime => 'Время работы (часы:минуты)';

  @override
  String get systemShowTemperature => 'Показывать температуру CPU в панели';

  @override
  String get systemTemperature => 'Температура CPU';

  @override
  String get systemAvailable => 'Доступно RAM';

  @override
  String get systemHistory => 'Последний час · среднее и пики';

  @override
  String get systemNow => 'Сейчас';

  @override
  String get systemHourAgo => '−60 мин';

  @override
  String get systemUpdateInterval => 'Интервал обновления';

  @override
  String get systemWidgetHelp =>
      'Показания обновляются с выбранным интервалом от 1 до 10 секунд (по умолчанию 5), пока панель видна. Графики показывают средние значения и пики за минуту. Другие приложения, сон и ошибки чтения оставляют разрывы. История хранится в памяти и сбрасывается при перезапуске процесса лаунчера. CPU и температура зависят от прошивки. Выключите все показатели панели, чтобы оставить только значок.';

  @override
  String get slideshowBrowseFolders => 'Просмотр папок';

  @override
  String get slideshowEnterFolderPath => 'Ввести путь к папке';

  @override
  String get slideshowSystemPicker => 'Выбрать в внешнем проводнике';

  @override
  String get slideshowFolderPath => 'Путь к папке';

  @override
  String get slideshowUseFolder => 'Выбрать эту папку';

  @override
  String get slideshowParentFolder => 'На уровень выше';

  @override
  String get slideshowStoragePermission =>
      'Разрешите доступ к файлам в настройках Android для встроенного проводника.';

  @override
  String get slideshowPickerUnavailable =>
      'На этом ТВ нет проводника с выбором папок. Используйте встроенный просмотр или введите путь вручную.';

  @override
  String get slideshowFolderUnavailable =>
      'Папка недоступна. Проверьте путь, подключение накопителя и разрешение доступа к файлам.';

  @override
  String get slideshowStorageHelp =>
      'Встроенный выбор читает папки памяти ТВ и подключённых накопителей. На Android 11 и новее разрешите доступ ко всем файлам; на Android 9–10 — доступ к памяти. Путь можно ввести вручную, например /storage/emulated/0/Pictures. Файлы не изменяются.';

  @override
  String get fileBrowserTitle => 'Выбор файла';

  @override
  String get filePickerChoose => 'Выбор проводника';

  @override
  String get filePickerSystem => 'Внешний проводник';

  @override
  String get filePickerBuiltIn => 'Встроенный проводник';

  @override
  String get fileBrowserEmpty => 'Нет доступных элементов';

  @override
  String get fileBrowserUnavailable =>
      'Не удалось открыть это расположение. Проверьте доступ и повторите попытку.';

  @override
  String get networkAndVpnGroup => 'Сеть и VPN';

  @override
  String get soundAndInputsGroup => 'Звук и входы';

  @override
  String get timerAndNightModeGroup => 'Таймер и ночной режим';

  @override
  String get systemSettingsGroup => 'Системные настройки';

  @override
  String get appChannelsTitle => 'Ленты приложений';

  @override
  String get appChannelsHelp =>
      'Выберите до 16 лент. Доступность зависит от каналов, опубликованных приложениями, и прошивки ТВ. Пустые ленты скрыты. Выбор хранится на этом ТВ.';

  @override
  String get appChannelsUnavailable =>
      'Не удалось прочитать ленты. Проверьте доступ к ТВ-программам.';

  @override
  String get appChannelsEmpty => 'Нет доступных лент приложений.';

  @override
  String get appChannelsRefresh => 'Обновить ленты';

  @override
  String get appChannelsLaunchFailed => 'Не удалось открыть этот контент.';

  @override
  String get appChannelsSaveFailed =>
      'Не удалось сохранить выбор. Можно выбрать до 16 лент.';

  @override
  String get sectionDeleteConfirm =>
      'Удалить этот раздел? Установленные приложения останутся.';

  @override
  String get sectionDeleteFailed =>
      'Не удалось удалить раздел. Попробуйте ещё раз.';

  @override
  String get appChannelsAccess => 'Доступ к лентам приложений';

  @override
  String get appChannelsMissing => 'Недоступная лента';

  @override
  String get wallpaperRefresh => 'Обновить обои';

  @override
  String get wallpaperDimmingHelp =>
      '100% сохраняет исходное затемнение фона, 200% усиливает его вдвое. Это не непрозрачность чёрного слоя.';

  @override
  String get resetLauncherSettings => 'Сбросить все настройки';

  @override
  String get resetLauncherSettingsConfirmation =>
      'Все настройки и локальные данные CuteLauncher будут удалены: разделы, избранное, назначения пульта, подключения и файлы в хранилище приложения. CuteLauncher закроется; следующий запуск будет как после установки. Доступы потребуется выдать заново. Файлы вне хранилища CuteLauncher и другие приложения сохранятся.';

  @override
  String get resetLauncherSettingsError =>
      'Не удалось завершить сброс настроек. Попробуйте ещё раз.';

  @override
  String get fileBrowserCurrentFolder => 'Текущая папка';

  @override
  String get fileBrowserFileName => 'Имя файла';

  @override
  String get fileBrowserNoFolders => 'Вложенных папок нет';

  @override
  String get fileBrowserNoFiles => 'Нет подходящих файлов';

  @override
  String get fileBrowserPartial => 'Показана только часть содержимого папки';

  @override
  String get fileBrowserReadNameHint => '← На уровень выше · → Имя целиком';

  @override
  String fileBrowserSavedTo(String path) {
    return 'Сохранено: $path';
  }

  @override
  String get backupDriveConnect => 'Подключить Google Диск';

  @override
  String get discardChangesTitle => 'Отменить изменения?';

  @override
  String get discardChangesMessage => 'Несохранённые изменения будут потеряны.';

  @override
  String get backgroundFileUnavailable => 'Файл недоступен';

  @override
  String get backupLastSuccess => 'Последнее успешное действие:';

  @override
  String get informationObjectPlacement => 'Размещение';

  @override
  String get informationPlacement => 'Размещение блока';

  @override
  String get informationOnBackground => 'На фоне';

  @override
  String get informationBackgroundPosition => 'Расположение блока';

  @override
  String get informationBackgroundOffset => 'Смещение по горизонтали';

  @override
  String get informationBackgroundResetOffset => 'Сбросить смещение';

  @override
  String get informationBackgroundContentAlignment =>
      'Выравнивание внутри блока';

  @override
  String get informationBackgroundHelp =>
      'Для часов, даты и погоды отдельно выберите верхнюю панель, фон или скрытие. На фоне элементы не реагируют на нажатия и не меняют положение плиток. Быстрые настройки независимы. Оба переключателя относятся ко всему фоновому блоку: часам, дате и погоде. Первый убирает перекрытие горами, второй поднимает блок над облаками, осадками и туманом.';

  @override
  String get informationAboveLandscape => 'Поверх пейзажа';

  @override
  String get informationAboveWeather => 'Поверх погодных эффектов';

  @override
  String get informationTime => 'Часы';

  @override
  String get informationDate => 'Дата';

  @override
  String get backgroundInformationAppearance => 'Оформление на фоне';

  @override
  String onlineWallpaperFailureStage(String stage) {
    String _temp0 = intl.Intl.selectLogic(stage, {
      'initialize': 'Подготовка хранилища',
      'metadata': 'Запрос к источнику',
      'download': 'Скачивание изображения',
      'validation': 'Проверка изображения',
      'save': 'Сохранение обоев',
      'other': 'Сохранение обоев',
    });
    return '$_temp0';
  }

  @override
  String onlineWallpaperFailureReason(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'dns': 'Не удалось определить адрес сервера (DNS).',
      'connection':
          'Не удалось установить или сохранить соединение с сервером.',
      'tls': 'Ошибка защищённого соединения или сертификата (TLS).',
      'timeout': 'Истекло время ожидания ответа.',
      'http': 'Сервер вернул ошибку.',
      'redirect':
          'Некорректное перенаправление или слишком много перенаправлений.',
      'insecureUrl':
          'Получена небезопасная ссылка: требуется HTTPS без данных входа.',
      'tooLarge': 'Ответ превышает допустимый размер.',
      'dimensions': 'Размеры изображения превышают допустимые.',
      'invalidResponse': 'Источник вернул некорректные данные.',
      'noImage': 'Источник не вернул новых подходящих изображений.',
      'invalidImage':
          'Файл повреждён или формат изображения не поддерживается.',
      'storage': 'Не удалось прочитать или записать файлы обоев.',
      'unknown': 'Неизвестная ошибка.',
      'other': 'Неизвестная ошибка.',
    });
    return '$_temp0';
  }

  @override
  String get informationPanelAppearance => 'Оформление в панели';

  @override
  String get informationData => 'Форматы и данные';

  @override
  String get informationGroupingMinimum => 'Нужны минимум два элемента';

  @override
  String get screenshotSceneMode => 'Режим съёмки';

  @override
  String get screenshotSceneHour => 'Часы';

  @override
  String get screenshotSceneMinute => 'Минуты';

  @override
  String get screenshotSceneHelp =>
      'Задаёт время пейзажа и фоновых часов, а также погоду пейзажа. Режим работает после закрытия настроек. Системное время, данные погоды и сохранённые настройки не меняются. После перезапуска этой сборки: 16:00, облачно.';

  @override
  String get autoLaunchWaitForInternet => 'Ждать интернет';

  @override
  String get autoLaunchWaitForInternetHelp =>
      'После задержки ждать подтверждённого подключения к интернету до 60 секунд, затем запустить приложение. Нажатие пульта или уход с главного экрана отменяет запуск.';

  @override
  String get remoteMappingIgnore => 'Игнорировать кнопку';

  @override
  String get remoteMappingBlackScreen => 'Переключить Black Screen';

  @override
  String get remoteMappingBlackOverlay => 'Чёрный экран';

  @override
  String get remoteMappingBlackOverlayHelp =>
      'Нажмите один раз, чтобы скрыть изображение. Повторите нажатие или нажмите Back, чтобы вернуть его. Телевизор остаётся включённым.';

  @override
  String get remoteMappingTclScreenOff => 'Отключить экран TCL';

  @override
  String get remoteMappingTclScreenOffHelp =>
      'Включает штатный режим «Только звук» на совместимых телевизорах TCL. Если Android блокирует запуск, нужен локальный ADB.';

  @override
  String get remoteMappingBlackScreenHelp =>
      'Нажмите один раз, чтобы показать чёрный экран, и ещё раз, чтобы убрать его. Нужны платная версия Black Screen от jApp и разрешение на показ поверх других приложений.';

  @override
  String get adbHomeDependencyProtected =>
      'Отключение заблокировано: обнаружена зависимость системных функций или её проверка недоступна. Подробности — в диагностике.';

  @override
  String get cleanerOperationResultTitle => 'Результат последней операции';

  @override
  String get cleanerUnchanged => 'Без изменений';

  @override
  String get cleanerNotAttempted => 'Не выполнялось';

  @override
  String get cleanerPackageMissing => 'Приложение отсутствует';

  @override
  String get cleanerReadFailed => 'Не удалось прочитать состояние';

  @override
  String get cleanerJournalFailed =>
      'Не удалось сохранить журнал восстановления';

  @override
  String get cleanerCommandFailed => 'Команда завершилась ошибкой';

  @override
  String get cleanerVerificationFailed => 'Новое состояние не подтверждено';

  @override
  String get inputsCecStateOnly => 'Состояние HDMI только по CEC';

  @override
  String get inputsCecStateOnlyHelp =>
      'Включите, если прошивка путает состояния портов. Используются только сведения CEC; без них состояние неизвестно. Все входы остаются в списке.';

  @override
  String get backgroundInformationOrderHint =>
      'OK или ◄ / ► — начать или закончить перемещение; ▲ / ▼ — изменить порядок сверху вниз; Back — закончить.';

  @override
  String get homeStyleNeedsSectionBackground => 'Выберите цвет фона раздела.';

  @override
  String get updateWrongPackage =>
      'APK предназначен для другого приложения. Скачайте обновление CuteLauncher из официального источника.';

  @override
  String get updateNotNewer =>
      'В загруженном APK та же или более старая сборка. Установить можно только более новую сборку.';

  @override
  String get updateSignersUnavailable =>
      'Android не предоставил сертификаты установленного приложения или APK. Проверить подпись не удалось; установка заблокирована.';

  @override
  String get updateSignatureMismatch =>
      'Подпись APK отличается от подписи установленного CuteLauncher. Обновление заблокировано. Сообщите автору, откуда установлена текущая версия.';

  @override
  String get updateInvalidFile =>
      'Android не смог прочитать APK: файл отсутствует, пуст, слишком велик или не распознан. Скачайте обновление заново.';

  @override
  String get updateVerificationFailed =>
      'При проверке APK произошла ошибка. Установка заблокирована. Повторите попытку; если ошибка повторится, отправьте автору отчёт диагностики.';

  @override
  String get feedFormat => 'Формат обложек';

  @override
  String get feedFormatAuto => 'Авто';

  @override
  String get feedFormatLandscape => 'Горизонтальный';

  @override
  String get feedFormatPortrait => 'Вертикальный';

  @override
  String get feedFormatHelp =>
      'Авто выбирает единый формат ленты по данным приложения или первым трём загруженным обложкам и запоминает его на этом ТВ. При равенстве выбирается горизонтальный формат. Другие пропорции показываются целиком на подложке. Формат можно выбрать вручную.';

  @override
  String get networkSpeedTitle => 'Скорость сети';

  @override
  String get networkSpeedSettings => 'Настройки скорости сети';

  @override
  String get networkSpeedInterval => 'Интервал обновления';

  @override
  String get networkSpeedHelp =>
      'Средняя скорость приёма и передачи по сетевым интерфейсам устройства. Это текущий трафик, а не тест скорости соединения. Опрос приостанавливается при скрытии виджета, в фоне и при выключенном экране. Первое показание после паузы — «—».';

  @override
  String networkSpeedUnit(String unit) {
    return '$unit/с';
  }

  @override
  String get customDateFormat => 'Свой формат';

  @override
  String get customDateFormatError =>
      'Используйте обозначения даты из справки. Текст заключайте в одинарные кавычки и закрывайте их.';

  @override
  String get customDateFormatHelp =>
      'd / dd — число месяца\nM / MM — номер месяца\nMMM / MMMM — краткое / полное название месяца\nEEE / EEEE — краткий / полный день недели\nyy / yyyy — год\nL…LLLL — месяц в самостоятельной форме\nD…DDD — день года; G — эра\nРазделители: пробел, . / - ,\nОбычный текст: \'Дата:\'; одна кавычка: \'\'\nРегистр важен. Обозначения времени не поддерживаются.\nПример: EEEE, d. MMMM yyyy';

  @override
  String get apodWallpaper => 'NASA APOD — астрономическая картинка дня';

  @override
  String get apodWallpaperHint =>
      'Ежедневное изображение NASA APOD. В дни с видео используется недавняя картинка. Размеры и пропорции изображений различаются. Здесь показаны авторство и ссылка на публикацию. Изображения принадлежат их правообладателям.';

  @override
  String get backupDriveClientImport =>
      'Импортировать Client ID и Secret из JSON';

  @override
  String get backupDriveClientImported =>
      'Данные клиента импортированы. Подключите Google Диск.';

  @override
  String get backupDriveClientImportFailed =>
      'Не удалось импортировать данные клиента. Выберите JSON клиента Google Cloud типа «TVs and Limited Input devices» размером до 64 КиБ.';

  @override
  String get dateFormatPreview => 'Предпросмотр';

  @override
  String get backupDriveConnectionStatus =>
      'Состояние подключения Google Диска';

  @override
  String get backupDriveReconnect => 'Переподключить Google Диск';

  @override
  String get backupSyncRefresh => 'Обновить';

  @override
  String get backupSyncRefreshFailed =>
      'Не удалось синхронизировать настройки. Проверьте доступ к хранилищу и повторите попытку.';

  @override
  String get backupThisTv => 'Этот ТВ';

  @override
  String get backupOtherTv => 'Другой ТВ';

  @override
  String get backupTvUnknown => 'ТВ не определён';

  @override
  String get panelTooltips => 'Всплывающие подсказки во всех панелях';

  @override
  String get networkStorageTitle => 'Сетевое хранилище';

  @override
  String get usbStorageTitle => 'USB-накопители';

  @override
  String get storageScreenUnavailable =>
      'Экран управления хранилищем недоступен.';

  @override
  String get appSections => 'Разделы приложения';

  @override
  String get noAppSections => 'Приложение не входит ни в один раздел.';

  @override
  String get volumeWidgetSettings => 'Настройки громкости';

  @override
  String get volumeUpdateInterval => 'Интервал обновления';

  @override
  String get showVolumeOverlay => 'Показывать громкость поверх приложений';

  @override
  String get volumeOverlayHelp =>
      'Для этого включите службу специальных возможностей CuteLauncher.';

  @override
  String get clockHoursColor => 'Цвет часов';

  @override
  String get clockMinutesColor => 'Цвет минут';

  @override
  String get clockColorMode => 'Режим цвета часов';

  @override
  String get clockSingleColor => 'Один цвет часов';

  @override
  String get clockSplitColors => 'Разные цвета часов';

  @override
  String get clockShowColon => 'Показывать двоеточие';

  @override
  String get appLaunchGroup => 'Запуск';

  @override
  String get appManagementGroup => 'Управление приложением';

  @override
  String get appCheckProcess => 'Проверить состояние';

  @override
  String get appProcessNotChecked => 'Состояние не проверено';

  @override
  String get appProcessRunning => 'Запущено';

  @override
  String get appProcessStopped => 'Не запущено';

  @override
  String get weatherCustomServer => 'Свой сервер (Open-Meteo)';

  @override
  String get widgetSettings => 'Настройки виджета';

  @override
  String get weatherServerUrlImport => 'Импортировать адрес из файла';

  @override
  String get weatherServerUrlImportError =>
      'Ошибка импорта: Выберите текстовый файл UTF-8 до 4 КБ, содержащий только базовый HTTPS-адрес сервера.';

  @override
  String get weatherImportReadError =>
      'Не удалось прочитать файл импорта. Проверьте доступ к файлу.';

  @override
  String get weatherImportEncodingError =>
      'Ошибка импорта: файл не в кодировке UTF-8.';

  @override
  String get weatherImportTooLargeError => 'Ошибка импорта: файл больше 4 КБ.';

  @override
  String get weatherImportSaveError =>
      'Не удалось сохранить значение. Повторите ввод или импорт.';

  @override
  String get weatherTokenInvalid => 'Некорректный формат токена.';

  @override
  String get weatherServerUrl => 'HTTPS-адрес сервера';

  @override
  String get weatherServerUrlHint =>
      'Введите базовый HTTPS-адрес без /v1/forecast, учётных данных, параметров запроса и фрагмента.';

  @override
  String get weatherServerCoordinates => 'Ввести координаты';

  @override
  String get weatherServerCoordinatesHint =>
      'Введите широту и долготу через запятую. Для дробной части используйте точку. Пример: 50.0, 30.0.';

  @override
  String get weatherIconPack => 'Набор значков погоды';

  @override
  String get weatherIconsStandard => 'Стандартные';

  @override
  String get weatherIconsOutline => 'Контурные';

  @override
  String get weatherIconsSolid => 'С заливкой';

  @override
  String get weatherIconsDuotone => 'Двухтонные';

  @override
  String get weatherIconsPixel => 'Пиксельные';

  @override
  String get weatherTextColor => 'Цвет текста погоды';

  @override
  String get weatherIconColor => 'Цвет значков погоды';

  @override
  String get weatherIconFollowsText => 'Как у текста погоды';

  @override
  String get informationDateColor => 'Цвет даты';

  @override
  String get clockTextColor => 'Цвет часов';

  @override
  String get weatherServerToken => 'Bearer-токен (необязательно)';

  @override
  String get weatherServerTokenImport => 'Импортировать токен из файла';

  @override
  String get weatherServerTokenImportError =>
      'Ошибка импорта: Выберите текстовый файл UTF-8 до 4 КБ, содержащий только токен.';

  @override
  String get weatherCheckConnection => 'Проверить соединение';

  @override
  String get weatherServerAccessError =>
      'Сервер отказал в доступе. Проверьте токен и права доступа на сервере.';

  @override
  String get weatherServerParametersError =>
      'Сервер отклонил параметры запроса или координаты.';

  @override
  String get informationComposition => 'Формат объектов';

  @override
  String get informationLayout => 'Компоновка блока';

  @override
  String get informationPositionSize => 'Положение и размер';

  @override
  String get informationTypography => 'Шрифт и цифры';

  @override
  String get informationColors => 'Цвета и эффекты';

  @override
  String get informationLayers => 'Слои фонового блока';

  @override
  String get informationAvoidOverlap => 'Не перекрывать блок настройками';

  @override
  String get weatherPresetBrief => 'Кратко';

  @override
  String get weatherPresetFeels => 'С ощущением';

  @override
  String get weatherPresetDetails => 'Подробно';

  @override
  String get informationAvoidOverlapHelp =>
      'При оформлении фона меню временно выбирает сторону с меньшим перекрытием блока. Если свободного места нет, показывается отдельный предпросмотр. После выхода возвращается обычная сторона меню.';

  @override
  String get informationProfileHelp =>
      'Форматы и цвета панели и фона независимы. Источник погоды общий. Быстрая панель и прогноз используют оформление верхней панели; видимость и объединение быстрой панели сохраняются отдельно.';

  @override
  String get weatherCompactLayout =>
      'В объединённом блоке с датой перенос погоды отображается пробелом. Сохранённый формат не меняется.';

  @override
  String get weatherFormatInvalid =>
      'Добавьте погодное поле. Допустимы до 12 блоков, один перенос строки и до 60 символов в каждом текстовом поле.';

  @override
  String get fileManagerPreference => 'Файловый менеджер';

  @override
  String get fileManagerAsk => 'Выбирать каждый раз';

  @override
  String get fileManagerBuiltIn => 'Встроенный';

  @override
  String get fileManagerExternal => 'Внешний';

  @override
  String get fileBrowserStartFolder => 'Начальная папка';

  @override
  String get fileBrowserStorage => 'Память ТВ';

  @override
  String get fileBrowserDownloads => 'Загрузки';

  @override
  String get fileBrowserLastFolder => 'Последняя открытая';

  @override
  String get fileBrowserSort => 'Сортировка';

  @override
  String get fileBrowserSortName => 'По имени';

  @override
  String get fileBrowserSortDate => 'По дате изменения';

  @override
  String get fileBrowserSortSize => 'По размеру';

  @override
  String get fileBrowserOrder => 'Порядок сортировки';

  @override
  String get fileBrowserAscending => 'По возрастанию';

  @override
  String get fileBrowserDescending => 'По убыванию';

  @override
  String get fileBrowserFoldersFirst => 'Папки всегда сверху';

  @override
  String get fileBrowserShowHidden => 'Показывать скрытые файлы и папки';

  @override
  String get fileBrowserShowDetails => 'Показывать размер и дату';

  @override
  String get fileBrowserOptionsHelp =>
      'Уже выбранная папка или исходная папка выбранного изображения открывается в первую очередь. Последняя открытая папка запоминается отдельно для каждого действия, в том числе после отмены. Если папка недоступна, открываются память ТВ или «Загрузки». История папок хранится только на этом ТВ.';

  @override
  String get fileBrowserSaveFailed =>
      'Не удалось сохранить настройки проводника.';

  @override
  String get settingsSectionStyle => 'Оформление групп';

  @override
  String get settingsSectionAccentBand => 'Акцентная полоса';

  @override
  String get settingsSectionSurface => 'Общая поверхность';

  @override
  String get panelTextAndButtonsGroup => 'Текст и кнопки';

  @override
  String get settingsGroupScene => 'Сцена';

  @override
  String get settingsGroupSky => 'Небо и погода';

  @override
  String get settingsGroupAnimation => 'Анимация и просмотр';

  @override
  String get settingsGroupSource => 'Источник';

  @override
  String get settingsGroupImageChange => 'Смена изображений';

  @override
  String get settingsGroupBrightness => 'Уровни яркости';

  @override
  String get settingsGroupDisplay => 'Отображение';

  @override
  String get settingsGroupCredentials => 'Данные подключения';

  @override
  String get settingsGroupClient => 'Параметры клиента';

  @override
  String get settingsGroupAccount => 'Подключение аккаунта';

  @override
  String get settingsGroupIndicators => 'Индикация и сообщения';

  @override
  String get nightModePanelFill => 'Акцентная заливка луны';

  @override
  String get settingsGroupFocusShape => 'Форма выделения';

  @override
  String get settingsGroupBorder => 'Рамка';

  @override
  String get settingsGroupMotion => 'Движение';

  @override
  String get settingsGroupControl => 'Управление';

  @override
  String get settingsGroupPositionSize => 'Расположение и размер';

  @override
  String get settingsGroupGroupsBackground => 'Группы и фон';

  @override
  String get settingsGroupText => 'Текст';

  @override
  String get settingsGroupLayout => 'Расположение';

  @override
  String get settingsGroupHeadings => 'Заголовки';

  @override
  String get settingsGroupLaunchTarget => 'Что запускать';

  @override
  String get settingsGroupLaunchTiming => 'Когда запускать';

  @override
  String get settingsGroupBlockPosition => 'Расположение блока';

  @override
  String get settingsGroupBlockContent => 'Содержимое блока';

  @override
  String get settingsGroupLayers => 'Слои отображения';

  @override
  String get settingsGroupAccess => 'Доступ';

  @override
  String get settingsGroupContent => 'Содержимое';

  @override
  String get settingsGroupSourcesLimits => 'Источники и лимиты';

  @override
  String get settingsGroupCards => 'Карточки';

  @override
  String get settingsGroupStorage => 'Хранение';

  @override
  String get settingsGroupMode => 'Режим';

  @override
  String get settingsGroupExceptions => 'Исключения';

  @override
  String get settingsGroupCurrentAction => 'Текущее действие';

  @override
  String get settingsGroupHours => 'Время работы';

  @override
  String get settingsGroupSourceAccess => 'Источник и доступ';

  @override
  String get settingsGroupUpdate => 'Обновление';

  @override
  String get settingsGroupSystemCommands => 'Система и команды';

  @override
  String get weatherTemplateWarning => 'Предупреждение';

  @override
  String get weatherTemplateDescription => 'Описание без значка';

  @override
  String get weatherTemplateIcon => 'Значок';

  @override
  String get weatherTemplateBracesError =>
      'Проверьте парные фигурные скобки. Для обычной скобки введите её дважды.';

  @override
  String get weatherTemplateUnknownError => 'Неизвестное обозначение:';

  @override
  String get weatherTemplateBreakError =>
      'Допускается только один перенос строки.';

  @override
  String get weatherTemplateValueError =>
      'Добавьте хотя бы одно обозначение погоды.';

  @override
  String get weatherTemplateLengthError =>
      'Формат слишком длинный: до 2048 символов и 64 элементов.';

  @override
  String get sectionTitleSize => 'Размер заголовка раздела';

  @override
  String get backupSyncResume => 'Как возобновить синхронизацию?';

  @override
  String get backupSyncUseLocal => 'Использовать настройки этого ТВ';

  @override
  String get backupSyncUseRemote => 'Использовать настройки из хранилища';

  @override
  String get backupSyncMergeLocal => 'Объединить с приоритетом этого ТВ';

  @override
  String get backupSyncMergeRemote => 'Объединить с приоритетом хранилища';

  @override
  String backupSyncPreviousDate(String date) {
    return 'Последняя синхронизация этого ТВ: $date';
  }

  @override
  String backupSyncRemoteDate(String date) {
    return 'Копия в хранилище: $date';
  }

  @override
  String get appPermissionsTitle => 'Разрешения приложениям';

  @override
  String get appPermissionsGrant => 'Выдать разрешения и включить';

  @override
  String get appPermissionsRestore => 'Восстанавливать при отключении';

  @override
  String get appPermissionsReconnect => 'Переподключить службу';

  @override
  String get appPermissionsDisable => 'Выключить службу и восстановление';

  @override
  String get appPermissionsAutoStart => 'Автозапуск';

  @override
  String get appPermissionsBackground => 'Фоновая работа';

  @override
  String get appPermissionsPending =>
      'Восстановление начнётся после выдачи доступов здесь.';

  @override
  String get appPermissionsRetry =>
      'Восстановление ожидает выполнения. Проверьте ADB; попытки повторяются автоматически.';

  @override
  String get appPermissionsIdentity =>
      'Подпись приложения изменилась. Выдайте доступ заново.';

  @override
  String get appPermissionsEmpty =>
      'Других приложений со службами спецвозможностей нет.';

  @override
  String get appPermissionsError =>
      'Не удалось завершить действие. Проверьте ADB и обновите состояние. Часть изменений могла примениться.';

  @override
  String get appPermissionsConfirm =>
      'Разрешить приложению спецвозможности, автозапуск и фоновую работу, затем включить службу? Применяются только поддерживаемые прошивкой действия. Спецвозможности позволяют читать события интерфейса и выполнять действия от вашего имени.';

  @override
  String get appPermissionsHelp =>
      'Восстановление включено по умолчанию для служб, которым вы выдаёте доступ здесь. Оно возвращает разрешения и включение службы, в том числе после отключения в настройках Android. Снятие переключателя сохраняет текущие доступы. Выключение службы также прекращает восстановление; разрешения автозапуска и фоновой работы остаются. Переподключение перезапускает только эту службу и не исправляет ошибки приложения. Нужен ADB; Android может откладывать проверки. Автозапуск не открывает экран приложения. Статусы отражают последнюю проверку; неподдерживаемые операции не выдаются.';

  @override
  String get weatherFieldUnsupported => 'Источник не поддерживает параметр';

  @override
  String get weatherFieldMissing => 'В текущем ответе нет данных';

  @override
  String get weatherMissingAsDash => 'Прочерки вместо отсутствующих данных';

  @override
  String get weatherPanelAlignment =>
      'Выравнивание строк погоды верхней панели';

  @override
  String get syncProtection => 'Токены и защита';

  @override
  String get syncKey => 'Общий ключ синхронизации';

  @override
  String get syncKeyShow => 'Показать ключ';

  @override
  String get syncKeyCreate => 'Создать ключ';

  @override
  String get syncKeyInvalid => 'Нужен ключ из 64 шестнадцатеричных символов.';

  @override
  String get syncKeyHelp =>
      'Для обмена токенами и аккаунтами задайте одинаковый ключ на всех ТВ. Создайте ключ на одном ТВ и перенесите его на остальные. Сохраните его в надёжном месте: без ключа защищённые данные не прочитать. При смене ключа обновите его на всех ТВ. Разрешения Android и аппаратные ключи остаются локальными.';

  @override
  String get syncFiles => 'Файлы синхронизации';

  @override
  String get syncCleanup => 'Очистить устаревшие файлы';

  @override
  String get syncCleanupFailed =>
      'Не удалось удалить часть старых файлов. Повторите очистку.';

  @override
  String get syncRetire => 'Исключить устройство';

  @override
  String get syncRetireConfirm =>
      'Исключить это устройство из группы? Его старые состояния больше не будут применяться. Для возвращения потребуется новая группа синхронизации.';

  @override
  String get backupAccount => 'Аккаунт';

  @override
  String get backupNewAccount => 'Подключить другой аккаунт';

  @override
  String get backupSetupWizard => 'Мастер настройки';

  @override
  String get backupSetupSummary => 'Итог';

  @override
  String get backupSetupNext => 'Далее';

  @override
  String get backupSetupBack => 'Назад';

  @override
  String get backupFirstCopy => 'Создать первую копию сейчас';

  @override
  String get backupSyncAll => 'Синхронизировать всё';

  @override
  String get backupFirstExchange => 'Первый обмен';

  @override
  String get backupNoRemote =>
      'В хранилище настроек нет. Будут отправлены настройки этого ТВ.';

  @override
  String get backupSetupStart => 'Включить';

  @override
  String get backupPassword => 'Пароль шифрования данных';

  @override
  String get backupPasswordRepeat => 'Повторите пароль';

  @override
  String get backupPasswordMismatch => 'Пароли не совпадают';

  @override
  String get backupAccountLocalHelp =>
      'Используйте подключённый аккаунт или отдельный аккаунт того же типа. Реквизиты хранилищ остаются на этом ТВ. РК и синхронизация хранят и очищают свои файлы независимо.';

  @override
  String get backupPasswordOptionalHelp =>
      'Необязательно. Пароль шифрует весь файл, включая переносимые токены. Без пароля файл не зашифрован. Пустое значение отключает шифрование. Для чтения зашифрованных файлов на другом ТВ нужен тот же пароль.';

  @override
  String get backupYandexDisk => 'Яндекс Диск';

  @override
  String get backupYandexHelp =>
      'Введите Client ID и Client Secret приложения Яндекс OAuth с доступом к папке приложения на Диске. Подключитесь и подтвердите код на телефоне. Для обмена между ТВ используйте один OAuth-клиент и аккаунт.';

  @override
  String get backupYandexConnect => 'Подключить Яндекс Диск';

  @override
  String get backupYandexReconnect => 'Переподключить Яндекс Диск';

  @override
  String get backupYandexConnectionStatus =>
      'Состояние подключения Яндекс Диска';

  @override
  String get yandexCodeExpired =>
      'Время входа в Яндекс Диск истекло. Нажмите «Подключить Яндекс Диск», чтобы получить новый код.';

  @override
  String get yandexConfigurationError =>
      'Client ID / Client Secret — Yandex OAuth';

  @override
  String get backupSmb => 'Samba / SMB 2–3';

  @override
  String get smbUrl => 'SMB-адрес папки';

  @override
  String get smbPassword => 'Пароль';

  @override
  String get smbHelp =>
      'Укажите существующую сетевую папку: smb://server/share/CuteLauncher. Нужны имя пользователя и пароль с доступом к папке; для домена используйте DOMAIN\\user. Поддерживаются SMB 2 и 3, версия выбирается автоматически. Для копий и синхронизации нужны права чтения, записи и удаления.';

  @override
  String get recentRamTitle => 'Оперативная память';

  @override
  String recentRamUsed(String used, String total, String percent) {
    return 'Занято $used из $total · $percent%';
  }

  @override
  String recentRamAvailable(String value) {
    return 'Доступно $value';
  }

  @override
  String get recentRamUnloaded => 'Выгружено';

  @override
  String get recentRamUnavailable => 'Нет данных';

  @override
  String recentRamMiB(String value) {
    return '$value МБ';
  }

  @override
  String recentRamGiB(String value) {
    return '$value ГБ';
  }

  @override
  String recentRamApp(String value) {
    return '≈ $value';
  }

  @override
  String get backupExistingSettingsHelp =>
      'В выбранном хранилище уже есть настройки синхронизации. Выберите, что с ними сделать: применить на этом ТВ, заменить настройками этого ТВ или объединить. Если при объединении настройки различаются, будет использован выбранный вами приоритет. Обмен начнётся после подтверждения на последнем шаге мастера.';
}
