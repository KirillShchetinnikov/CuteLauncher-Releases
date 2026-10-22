// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

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
  String get backgroundSource => 'مصدر الخلفية';

  @override
  String get noAvailableCategories =>
      'لا توجد أقسام متاحة لإضافة هذا التطبيق إليها.';

  @override
  String get redditWallpaperTheme => 'موضوع ورق الجدران';

  @override
  String get redditThemeAll => 'مختلط';

  @override
  String get redditThemeNature => 'الطبيعة';

  @override
  String get redditThemeSpace => 'الفضاء';

  @override
  String get redditThemeCity => 'المدن';

  @override
  String get redditThemeMinimal => 'بساطتها';

  @override
  String get redditWallpaperResolution => 'الحد الأدنى من القرار';

  @override
  String get redditWallpaperHint =>
      'يقوم كل تحديث ناجح بتنزيل صورة أفقية مختلفة من مجتمع Reddit المحدد. الدقة هي الحد الأدنى للحجم الأصلي؛ لا يتم رفع مستوى الصور. يتم تشغيل التحديث عندما يكون المشغل مفتوحًا ويستأنف عند العودة. يتم تخطي محتوى البالغين ومقاطع الفيديو والمعارض. إذا قام Reddit بحظر الوصول أو لم يتم العثور على صورة مطابقة، فستظل خلفية الشاشة السابقة.';

  @override
  String get dialogCommandDetails => 'إظهار أوامر ADB';

  @override
  String get dialogAssign => 'تعيين';

  @override
  String get dialogApply => 'تطبيق';

  @override
  String get settingsValueNotSet => 'لم يتم ضبطه';

  @override
  String get settingsMenuPosition => 'موضع قائمة الإعدادات';

  @override
  String get settingsMenuLeft => 'اليسار';

  @override
  String get settingsMenuRight => 'صحيح';

  @override
  String get actionCompleted => 'اكتمل الإجراء';

  @override
  String get showRepositoryQrCode => 'إظهار رمز الاستجابة السريعة';

  @override
  String get resetSections => 'إعادة ضبط إعدادات القسم';

  @override
  String get resetSectionsConfirmation =>
      'هل تريد استعادة الأقسام الافتراضية؟ ستتم إزالة الأقسام المخصصة والفواصل والمحتويات المفضلة.';

  @override
  String get cardFocusMode => 'التركيز على العودة إلى المنزل';

  @override
  String get cardFocusRemember => 'احتفظ بالبطاقة المختارة';

  @override
  String get cardFocusFirst => 'البطاقة الأولى';

  @override
  String get cardFocusSettings => 'زر الإعدادات';

  @override
  String get aboutFlauncher => 'حول CuteLauncher';

  @override
  String get addCategory => 'إضافة فئة';

  @override
  String get addSection => 'إضافة قسم';

  @override
  String get alphabetical => 'أبجدي';

  @override
  String get appCardHighlightAnimation => 'رسوم متحركة لإبراز بطاقة التطبيق';

  @override
  String get appInfo => 'معلومات التطبيق';

  @override
  String get appKeyClick => 'صوت نقر عند الضغط على المفتاح';

  @override
  String get applications => 'التطبيقات';

  @override
  String get autoHideAppBar => 'إخفاء شريط الحالة تلقائياً';

  @override
  String get backButtonAction => 'إجراء زر الرجوع';

  @override
  String get category => 'فئة';

  @override
  String get categories => 'الفئات';

  @override
  String get columnCount => 'عدد الأعمدة';

  @override
  String get date => 'التاريخ';

  @override
  String get dateAndTimeFormat => 'تنسيق التاريخ والوقت';

  @override
  String get delete => 'حذف';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'عدم القيام بشيء';

  @override
  String get dialogOptionBackButtonActionShowScreensaver => 'إظهار شاشة التوقف';

  @override
  String get dialogOptionBackButtonActionShowClock => 'إظهار الساعة';

  @override
  String get dialogTextNoFileExplorer =>
      'يرجى تثبيت مستكشف الملفات لاختيار صورة.';

  @override
  String get dialogTitleBackButtonAction => 'اختر إجراء زر الرجوع';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (فئة)';
  }

  @override
  String formattedDate(String dateString) {
    return 'التاريخ المنسق: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'الوقت المنسق: $timeString';
  }

  @override
  String get gradient => 'تدرج لوني';

  @override
  String get favoriteApps => 'التطبيقات المفضلة';

  @override
  String get grid => 'شبكة';

  @override
  String get height => 'الارتفاع';

  @override
  String get hide => 'إخفاء';

  @override
  String get hiddenApplications => 'التطبيقات المخفية';

  @override
  String get launcherSections => 'الأقسام';

  @override
  String get layout => 'التخطيط';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String get manual => 'يدوي';

  @override
  String get modifySection => 'تعديل القسم';

  @override
  String get mustNotBeEmpty => 'يجب ألا يكون فارغاً';

  @override
  String get name => 'الاسم';

  @override
  String get newSection => 'قسم جديد';

  @override
  String get noDateFormatSpecified => 'لم يتم تحديد تنسيق التاريخ';

  @override
  String get noTimeFormatSpecified => 'لم يتم تحديد تنسيق الوقت';

  @override
  String get nonTvApplications => 'تطبيقات غير تلفزيونية';

  @override
  String get open => 'فتح';

  @override
  String get orSelectFormatSpecifiers => 'أو حدد محددات التنسيق';

  @override
  String get openImage => 'افتح الصورة';

  @override
  String get picture => 'صورة';

  @override
  String removeFrom(String name) {
    return 'إزالة من $name';
  }

  @override
  String get renameCategory => 'إعادة تسمية الفئة';

  @override
  String get reorder => 'إعادة ترتيب';

  @override
  String get row => 'صف';

  @override
  String get rowHeight => 'ارتفاع الصف';

  @override
  String get save => 'حفظ';

  @override
  String get spacer => 'فاصل';

  @override
  String get spacerMaxHeightRequirement =>
      'يجب أن يكون أكبر من 0 وأقل من أو يساوي 500';

  @override
  String get statusBar => 'شريط الحالة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get show => 'إظهار';

  @override
  String get showCategoryTitles => 'إظهار عناوين الفئات';

  @override
  String get themes => 'السمات';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'إخفاء مخطط التمييز على الشاشة الرئيسية';

  @override
  String get appSelectorTransitionAnimation =>
      'رسوم متحركة لانتقال محدد التطبيقات';

  @override
  String get sort => 'فرز';

  @override
  String get systemSettings => 'إعدادات النظام';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => 'هذه الفئة فارغة.';

  @override
  String get time => 'الوقت';

  @override
  String get titleStatusBarSettingsPage => 'اختر ما سيتم عرضه في شريط الحالة';

  @override
  String get tvApplications => 'تطبيقات التلفزيون';

  @override
  String get type => 'النوع';

  @override
  String get typeInTheDateFormat => 'اكتب تنسيق التاريخ';

  @override
  String get typeInTheHourFormat => 'اكتب تنسيق الوقت';

  @override
  String get uninstall => 'إلغاء التثبيت';

  @override
  String get wallpaper => 'خلفية';

  @override
  String get withEllipsisAddTo => 'إضافة إلى...';

  @override
  String get timeBasedWallpaper => 'خلفية تعتمد على الوقت';

  @override
  String get pickDayWallpaper => 'اختيار خلفية النهار';

  @override
  String get pickNightWallpaper => 'اختيار خلفية الليل';

  @override
  String get accessibility => 'إمكانية الوصول';

  @override
  String get defaultLauncherIsDefault => 'CuteLauncher هو المشغل الافتراضي';

  @override
  String get defaultLauncherNotDefault => 'CuteLauncher ليس المشغل الافتراضي';

  @override
  String get setAsDefaultLauncher => 'تعيين كمشغل افتراضي';

  @override
  String get defaultLauncherDescription =>
      'عند تعيينه كمشغل افتراضي، سيعود زر الصفحة الرئيسية دائماً إلى CuteLauncher. سيتم أيضاً تشغيل التلفزيون مباشرة في CuteLauncher.';

  @override
  String get inputs => 'المدخلات';

  @override
  String get inputsUnavailableHint =>
      'لا يوفر هذا الجهاز أي مدخلات متاحة. تم تعطيل المفتاح وإخفاء الرمز. في صندوق التلفزيون، لا يتحكم هذا الخيار في مدخلات HDMI الخاصة بالتلفزيون المتصل.';

  @override
  String get inputSources => 'مصادر الإدخال';

  @override
  String get backupAndRestore => 'النسخ الاحتياطي والاستعادة';

  @override
  String get exportBackup => 'تصدير النسخ الاحتياطي';

  @override
  String get importBackup => 'استيراد النسخ الاحتياطي';

  @override
  String exportSuccess(String path) {
    return 'تم تصدير النسخ الاحتياطي بنجاح إلى $path';
  }

  @override
  String get importSuccess => 'تم استيراد النسخ الاحتياطي بنجاح';

  @override
  String get importConfirm =>
      'هل أنت متأكد أنك تريد استيراد النسخ الاحتياطي؟ سيؤدي هذا إلى الكتابة فوق إعداداتك وتخطيطك الحاليين.';

  @override
  String get importError =>
      'لا يمكن استعادة الإعدادات من النسخة الاحتياطية. تحقق من الملف وحاول مرة أخرى.';

  @override
  String exportError(String error) {
    return 'فشل تصدير النسخ الاحتياطي: $error';
  }

  @override
  String get shareBackup => 'مشاركة النسخ الاحتياطي';

  @override
  String get shareBackupDescription =>
      'مشاركة النسخ الاحتياطي مع الأجهزة الأخرى على الشبكة المحلية';

  @override
  String get stopSharing => 'إيقاف المشاركة';

  @override
  String get localNetworkSharingActive => 'مشاركة الشبكة المحلية نشطة!';

  @override
  String get localNetworkSharingInstructions =>
      'قم بتوصيل جهاز آخر بنفس شبكة Wi-Fi وافتح عنوان URL التالي في متصفح الويب:';

  @override
  String get localNetworkSharingDetails =>
      'هنا يمكنك تنزيل إعدادات/تخطيط التلفزيون الخاص بك أو رفع ملف نسخ احتياطي مرة أخرى إلى هذا التلفزيون.';

  @override
  String failedToStartServer(String error) {
    return 'فشل بدء خادم المشاركة: $error';
  }

  @override
  String get notificationBell => 'جرس الإشعارات';

  @override
  String get autoHideNotificationBell => 'إخفاء جرس الإشعارات تلقائياً';

  @override
  String get continueWatching => 'متابعة المشاهدة';

  @override
  String get showContinueWatchingOnHome =>
      'إظهار متابعة المشاهدة على الصفحة الرئيسية';

  @override
  String get permissionDeniedContinueWatching =>
      'الإذن مطلوب لإظهار متابعة المشاهدة';

  @override
  String get interface => 'الواجهة';

  @override
  String get system => 'النظام';

  @override
  String get accentColor => 'لون التمييز';

  @override
  String get miscellaneous => 'متنوع';

  @override
  String get brightnessScheduler => 'مجدول السطوع';

  @override
  String get screensaverSettings => 'إعدادات شاشة التوقف';

  @override
  String get screensaverClockStyle => 'نمط ساعة شاشة التوقف';

  @override
  String get dataUsagePeriod => 'فترة استخدام البيانات';

  @override
  String get notificationAccess => 'الوصول إلى الإشعارات';

  @override
  String get granted => 'مُمنوح';

  @override
  String get permissionRequired => 'الإذن مطلوب';

  @override
  String get systemWidePopupAlert => 'تنبيه منبثق على مستوى النظام';

  @override
  String get overlayPermissionRequired => 'إذن التراكب مطلوب';

  @override
  String get enabled => 'مفعّل';

  @override
  String get disabled => 'معطّل';

  @override
  String get showAppNamesBelowIcons => 'إظهار أسماء التطبيقات أسفل الأيقونات';

  @override
  String get dataUsage => 'استخدام البيانات';

  @override
  String get networkIndicator => 'مؤشر الشبكة';

  @override
  String get homeButtonFix => 'إصلاح زر الصفحة الرئيسية (Google TV)';

  @override
  String get startOnBoot => 'التشغيل عند بدء الجهاز (Google TV / Fire TV)';

  @override
  String get appLanguage => 'اللغة';

  @override
  String get systemDefault => 'افتراضي النظام';

  @override
  String get english => 'الإنجليزية';

  @override
  String get spanish => 'الإسبانية';

  @override
  String get ukrainian => 'الأوكرانية';

  @override
  String get chinese => 'الصينية';

  @override
  String get french => 'الفرنسية';

  @override
  String get german => 'الألمانية';

  @override
  String get japanese => 'اليابانية';

  @override
  String get portuguese => 'البرتغالية';

  @override
  String get russian => 'الروسية';

  @override
  String get italian => 'الإيطالية';

  @override
  String get hindi => 'الهندية';

  @override
  String get korean => 'الكورية';

  @override
  String get arabic => 'العربية';

  @override
  String get turkish => 'التركية';

  @override
  String get hidePersistentNotifications => 'إخفاء الإشعارات الدائمة';

  @override
  String get hidePersistentNotificationsDesc =>
      'إخفاء إشعارات خدمات الخلفية والنظام';

  @override
  String get blockedNotificationApps => 'التطبيقات المحظورة';

  @override
  String get blockAppNotifications => 'حظر الإشعارات';

  @override
  String get unblockAppNotifications => 'إلغاء حظر الإشعارات';

  @override
  String get noBlockedApps => 'لا توجد تطبيقات محظورة';

  @override
  String get persistentNotification => 'دائم';

  @override
  String get unblockAll => 'إلغاء حظر الكل';

  @override
  String get weather => 'الطقس';

  @override
  String get showWeatherWarnings => 'إظهار تحذيرات الطقس والأمطار';

  @override
  String get temperatureUnit => 'وحدة درجة الحرارة';

  @override
  String get celsius => 'مئوية (°C)';

  @override
  String get fahrenheit => 'فهرنهايت (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'قم بتثبيت تطبيق Breezy Weather وتفعيل \'مشاركة البيانات المحلية\' في إعداداته لعرض الطقس وتحذيرات الأمطار.';

  @override
  String get displayAndScreensaver => 'الشاشة وشاشة التوقف';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get continueWatchingDescription =>
      'عرض الأفلام والبرامج التلفزيونية التي تمت مشاهدتها مؤخرًا على الشاشة الرئيسية';

  @override
  String get continueWatchingPermissionDesc =>
      'يلزم الحصول على إذن خاص لقراءة سجل المشاهدة من تطبيقات التلفزيون:';

  @override
  String get requestPermission => 'طلب الإذن';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get openApp => 'فتح';

  @override
  String get notificationOptions => 'خيارات الإشعار';

  @override
  String get noBlockedAppsDesc =>
      'يُسمح لجميع التطبيقات حاليًا بإظهار الإشعارات';

  @override
  String get notificationsAllowed => 'الإشعارات مسموحة';

  @override
  String get notificationsBlocked => 'الإشعارات محظورة';

  @override
  String get dpadDismissHint => 'يسار: تجاهل • موافق: خيارات';

  @override
  String get watchNextDeleteError =>
      'تعذر إزالة العنصر من \"متابعة المشاهدة\". حاول ثانية.';

  @override
  String get hideLauncherTile => 'إخفاء CuteLauncher في شبكة التطبيق';

  @override
  String get hideAndroidSettingsTile =>
      'إخفاء إعدادات Android في مربعات التطبيق';

  @override
  String get animateTileReordering => 'تحريك إعادة ترتيب البلاط';

  @override
  String get imageInputRejected =>
      'هذه الصورة تالفة أو كبيرة جدًا (بحد أقصى 8 MiB و48 ميجابكسل). اختر صورة أخرى.';

  @override
  String get memoryTitle => 'الذاكرة';

  @override
  String get memoryRefresh => 'قياس الذاكرة';

  @override
  String get memoryMeasuring => 'قياس…';

  @override
  String get memoryClear => 'مسح ذاكرة التخزين المؤقت للصور';

  @override
  String get memorySaver => 'توفير الذاكرة';

  @override
  String get memorySaverDescription =>
      'وضع توفير الذاكرة:\n\n• يقلل من ذاكرة التخزين المؤقت للصور ونافذة التحميل المسبق للملصق.\n• تعطيل تمويه خلفية البلاط واللوحة وورق الحائط والمخطط التفصيلي النابض.\n• حدود الظلال على البلاط غير المركزة.\n• مسح ذاكرة التخزين المؤقت عندما ينتقل التطبيق إلى الخلفية.\n\nهذه التأثيرات غير متوفرة في الإعدادات أثناء تمكين حفظ الذاكرة. تعود القيم المحفوظة الخاصة بهم عند تعطيل الوضع. قد يتم إعادة تحميل الصور في كثير من الأحيان.';

  @override
  String get memoryPss => 'مشاركة العملية (PSS)';

  @override
  String get memoryRss => 'ذاكرة العملية المقيمة (RSS)';

  @override
  String get memoryEncodedCache => 'ملفات الصور المخزنة مؤقتا';

  @override
  String get memoryDecodedCache => 'الصور التي تم فك تشفيرها مؤقتًا';

  @override
  String get memoryUnavailable => 'غير متاح';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => 'تقاس عند';

  @override
  String get memoryExplanation =>
      'تداخل PSS وRSS: لا تقم بإضافتهما معًا. تعد أحجام ذاكرة التخزين المؤقت جزءًا من ذاكرة التطبيق ولا تصف كل الذاكرة التي تحتفظ بها الصور النشطة. يؤدي مسح ذاكرة التخزين المؤقت إلى الحفاظ على إعداداتك وملفاتك؛ يتم تحميل الصور مرة أخرى عند الحاجة. قد يقوم Android بإرجاع الذاكرة لاحقًا. RSS هنا يأتي من النواة وPSS من Android؛ قد يقومون بحساب ذاكرة الرسومات بشكل مختلف.';

  @override
  String get memoryRecommendations =>
      'للحصول على ذاكرة أقل، قم بتمكين الحفظ وإظهار عدد أقل من بطاقات مواصلة المشاهدة واستخدام خلفيات أصغر أو تدرج.';

  @override
  String get memoryMeasurementFailed =>
      'قياس العملية غير متوفر. لا تزال معلومات ذاكرة التخزين المؤقت معروضة.';

  @override
  String get addToCategory => 'أضف إلى الفئة';

  @override
  String get addToFavorites => 'أضف إلى المفضلة';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get setCustomBanner => 'تعيين لافتة مخصصة';

  @override
  String get clearCustomBanner => 'مسح الشعار المخصص';

  @override
  String get bannerSetFailed =>
      'لا يمكن تعيين البانر. تحقق من الوصول إلى الصورة وحدد الملف مرة أخرى.';

  @override
  String get bannerClearFailed => 'تعذرت إزالة الشعار المخصص. حاول ثانية.';

  @override
  String get grantUsagePermission => 'منح إذن الاستخدام';

  @override
  String get removeFromContinueWatching => 'إزالة من متابعة المشاهدة';

  @override
  String hideAllFromApp(String appName) {
    return 'إخفاء الكل من $appName';
  }

  @override
  String get playResume => 'تشغيل / استئناف';

  @override
  String openNamedApp(String appName) {
    return 'افتح $appName';
  }

  @override
  String get selectedAccent => 'لهجة مختارة';

  @override
  String get homeButtonFixHint =>
      'إذا كنت تستخدم Google TV، فقم بتمكين \"Home Button Fix\" ضمن إعدادات إمكانية الوصول لجعل زر الصفحة الرئيسية يفتح هذا المشغل.';

  @override
  String get accessibilityPermission => 'إذن الوصول';

  @override
  String get shareFailed => 'فشلت المشاركة';

  @override
  String shareBackupError(String error) {
    return 'فشلت مشاركة النسخة الاحتياطية: $error';
  }

  @override
  String get exportComplete => 'نجاح التصدير';

  @override
  String get exportFailed =>
      'لا يمكن حفظ النسخة الاحتياطية. تحقق من الوصول إلى المجلد والتخزين المتاح.';

  @override
  String backupLoadError(String error) {
    return 'حدث خطأ أثناء تحميل النسخ الاحتياطية: $error';
  }

  @override
  String get noBackupFiles => 'لم يتم العثور على ملفات النسخ الاحتياطي.';

  @override
  String get importComplete => 'نجاح الاستيراد';

  @override
  String get importFailed => 'فشل الاستيراد';

  @override
  String get importAction => 'استيراد';

  @override
  String get continueWatchingApps => 'متابعة مشاهدة التطبيقات';

  @override
  String get blockedContinueWatching => 'تم حظره من متابعة المشاهدة';

  @override
  String get allAppsCanContinueWatching =>
      'يمكن لجميع التطبيقات المدعومة عرض العناصر في \"متابعة المشاهدة\".';

  @override
  String get unblockApp => 'إلغاء الحظر';

  @override
  String get unblockAllApps => 'إلغاء حظر جميع التطبيقات';

  @override
  String get appsWithContinueWatching => 'تطبيقات مع متابعة المشاهدة';

  @override
  String get watchNextAppsHint =>
      'توفر التطبيقات حاليًا عناصر \"مشاهدة التالي\" على شاشتك الرئيسية';

  @override
  String get noWatchNextApps =>
      'لا توجد تطبيقات توفر حاليًا عناصر متابعة المشاهدة.\nعندما تقوم التطبيقات المدعومة (مثل SmartTube أو خدمات البث) بإضافة عناصر، فسوف تظهر هنا.';

  @override
  String get allInstalledApps => 'جميع التطبيقات المثبتة';

  @override
  String get blockWatchNextHint =>
      'قم بالتبديل لمنع أي تطبيق من إضافة عناصر إلى متابعة المشاهدة';

  @override
  String get cardSize => 'حجم البطاقة';

  @override
  String get maximumItems => 'الحد الأقصى للعناصر';

  @override
  String get playbackProgressBar => 'شريط تقدم التشغيل';

  @override
  String get playbackPercentage => 'نسبة التشغيل';

  @override
  String get episodeVideoDetails => 'تفاصيل الحلقة والفيديو';

  @override
  String get restoreHiddenPrograms => 'استعادة البرامج المخفية';

  @override
  String get allHiddenProgramsRestored => 'تمت استعادة كافة البرامج المخفية';

  @override
  String get watchNextAccessAdb => 'مشاهدة الوصول التالي (مطلوب ADB)';

  @override
  String get supportLtvLauncher => 'دعم LTvLauncher';

  @override
  String get scanToDonate => 'قم بالمسح باستخدام كاميرا هاتفك للتبرع:';

  @override
  String get openInBrowser => 'فتح في المتصفح';

  @override
  String get close => 'إغلاق';

  @override
  String get launcherAuthor => 'CuteLauncher بواسطة Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'مشغّل Android TV مستند إلى LTvLauncher من LeanBitLab وFLauncher من Étienne Fesser. مرخّص بموجب GNU GPLv3.';

  @override
  String get projectCredits => 'المشروع والاعتمادات';

  @override
  String get launcherRepository => 'مستودع CuteLauncher';

  @override
  String get originalProject => 'المشروع الأصلي: LTvLauncher';

  @override
  String get noInputsDetected => 'لم يتم الكشف عن أي مدخلات';

  @override
  String get reorderSectionsHint =>
      'حدد باستخدام ◄ / ► ثم استخدم ▲ / ▼ لإعادة الترتيب. قم بعبور حدود القائمة لإخفاء قسم أو إظهاره.';

  @override
  String get customName => 'الاسم المخصص';

  @override
  String get mostUsed => 'تردد الإطلاق';

  @override
  String get lastUsed => 'آخر استخدام';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get allCaughtUp => 'جميع المحاصرين!';

  @override
  String get notificationAccessAdb => 'الوصول إلى الإشعارات (مطلوب ADB)';

  @override
  String get openAppInfo => 'افتح معلومات التطبيق';

  @override
  String get overlayPermission => 'إذن التراكب';

  @override
  String get clockMinimal => 'الحد الأدنى';

  @override
  String get clockMinimalDescription => 'خط رفيع وأنيق (افتراضي)';

  @override
  String get clockBold => 'جريئة';

  @override
  String get clockBoldDescription => 'خط سميك ومرئي للغاية';

  @override
  String get clockRetro => 'الرجعية';

  @override
  String get clockRetroDescription => 'أحادية المسافة، نمط المحطة الرجعية';

  @override
  String get clockElegant => 'أنيق';

  @override
  String get clockElegantDescription => 'الخط الرقيق الكلاسيكي';

  @override
  String get clockNeon => 'نيون';

  @override
  String get clockNeonDescription => 'رفيع للغاية، طراز متوهج';

  @override
  String get clockPixel => 'بكسل';

  @override
  String get clockPixelDescription => 'جريئة أحادية المسافة، تشعر بالممرات';

  @override
  String get clockDigital => 'رقمي';

  @override
  String get clockDigitalDescription => 'عرض أحادي المسافة نظيف';

  @override
  String get themeDefault => 'الافتراضي';

  @override
  String get themePremium => 'قسط';

  @override
  String get themeClassic => 'كلاسيكي';

  @override
  String get themeCapsule => 'كبسولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get actionCancelled => 'تم إلغاء الإجراء';

  @override
  String get ok => 'حسنًا';

  @override
  String get accessibilityGuide =>
      'افتح إعدادات التلفزيون يدويًا، ثم إمكانية الوصول → CuteLauncher Home Button Fix، وقم بتمكين الخدمة. يعتمد موقع هذه القائمة واسمها على الشركة المصنعة للتلفزيون لديك.';

  @override
  String get notificationPermissionGuide =>
      'لا يمكن فتح إعدادات الوصول إلى الإشعارات على هذا التلفزيون. إن السماح بالإشعارات الصادرة في معلومات التطبيق لا يمنح الوصول إلى الإشعارات من التطبيقات الأخرى.\n\nقم بتوصيل التلفزيون الخاص بك عبر ADB وقم بتشغيل:';

  @override
  String get overlayPermissionGuide =>
      'لا يمكن فتح إعدادات إذن التراكب تلقائيًا.\n\nلتمكين النوافذ المنبثقة على التطبيقات الأخرى، قم بتوصيل التلفزيون الخاص بك عبر ADB وقم بتشغيل:';

  @override
  String get watchNextPermissionGuide =>
      'لقراءة بطاقات متابعة المشاهدة من التطبيقات الأخرى، يتطلب Android TV وجود READ_WRITE_WATCH_NEXT_PROGRAMS.\n\nقم بتوصيل التلفزيون الخاص بك عبر ADB وقم بتشغيل:';

  @override
  String get watchNextAccess => 'متابعة مشاهدة الوصول';

  @override
  String itemsCount(int count) {
    return 'عناصر $count';
  }

  @override
  String displayUpToItems(int count) {
    return 'عرض ما يصل إلى $count العناصر الأخيرة';
  }

  @override
  String get unlimitedItems => 'غير محدود';

  @override
  String get allAvailableItems => 'عرض كافة العناصر المتاحة';

  @override
  String get defaultOption => 'الافتراضي';

  @override
  String get manage => 'إدارة';

  @override
  String blockedCount(int count) {
    return 'تم حظر $count';
  }

  @override
  String hiddenCount(int count) {
    return '$count مخفي';
  }

  @override
  String blockedWatchNextCount(int count) {
    return 'تم الحظر من متابعة المشاهدة ($count)';
  }

  @override
  String get sizeExtraSmall => 'صغير جدًا';

  @override
  String get sizeVerySmall => 'صغير جدًا';

  @override
  String get sizeSmall => 'صغير';

  @override
  String get sizeCompact => 'مدمج';

  @override
  String get sizeMediumSmall => 'متوسطة صغيرة';

  @override
  String get sizeMedium => 'متوسط';

  @override
  String get sizeStandardDefault => 'قياسي (افتراضي)';

  @override
  String get sizeMediumLarge => 'متوسطة كبيرة';

  @override
  String get sizeLarge => 'كبير';

  @override
  String get sizeVeryLarge => 'كبير جدًا';

  @override
  String get sizeExtraLarge => 'كبير جدًا';

  @override
  String get sizeHuge => 'ضخم';

  @override
  String get tvApps => 'تطبيقات التلفزيون';

  @override
  String get nonTvApps => 'تطبيقات غير تلفزيونية';

  @override
  String get moviesShows => 'الأفلام والعروض';

  @override
  String get music => 'موسيقى';

  @override
  String get games => 'العاب';

  @override
  String get entertainment => 'الترفيه';

  @override
  String get liveTv => 'البث التلفزيوني المباشر';

  @override
  String get sports => 'الرياضة';

  @override
  String get news => 'أخبار';

  @override
  String get tools => 'أدوات';

  @override
  String get favorites => 'المفضلة';

  @override
  String get customSectionName => 'مخصص...';

  @override
  String get selectSectionName => 'حدد اسمًا';

  @override
  String get weeklyUsage => 'أسبوعي:';

  @override
  String get monthlyUsage => 'شهريا:';

  @override
  String get dailyUsage => 'يوميا:';

  @override
  String get appError => 'حدث خطأ ما';

  @override
  String get weatherRain => 'المطر';

  @override
  String get weatherSnow => 'ثلج';

  @override
  String get weatherStorm => 'عاصفة';

  @override
  String get weatherToday => 'اليوم';

  @override
  String get weatherTomorrow => 'غدا';

  @override
  String weatherOnDay(String day) {
    return 'على $day';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'النسخ الاحتياطي CuteLauncher';

  @override
  String get noApplicationsFound => 'لم يتم العثور على أي تطبيقات';

  @override
  String get invalidDateFormat => 'التنسيق غير صالح';

  @override
  String get selectDateFormats => 'حدد التنسيقات أدناه';

  @override
  String activeItemsCount(int count) {
    return '$count العناصر النشطة';
  }

  @override
  String get colorPurple => 'أرجواني';

  @override
  String get colorTeal => 'البط البري';

  @override
  String get colorBlue => 'أزرق';

  @override
  String get colorOrange => 'برتقالي';

  @override
  String get colorPink => 'وردي';

  @override
  String get colorGreen => 'أخضر';

  @override
  String get colorWhite => 'أبيض';

  @override
  String get colorYellow => 'أصفر';

  @override
  String get colorRed => 'أحمر';

  @override
  String get colorCyan => 'سماوي';

  @override
  String get colorIndigo => 'نيلي';

  @override
  String get colorLime => 'الجير';

  @override
  String get colorAmber => 'العنبر';

  @override
  String get colorRose => 'روز';

  @override
  String get colorIceBlue => 'الجليد الأزرق';

  @override
  String get memoryFeatures => 'الذاكرة حسب الميزة (ذاكرة التخزين المؤقت)';

  @override
  String get memoryAppIcons => 'أيقونات التطبيقات';

  @override
  String get memoryAppBanners => 'لافتات التطبيق';

  @override
  String get memoryWatchNextPosters => 'مواصلة مشاهدة الملصقات';

  @override
  String get memoryOtherCaches => 'مخابئ الصور المشفرة الأخرى';

  @override
  String get memoryFeaturesExplanation =>
      'هذه هي وحدات بايت الصورة التي تم الاحتفاظ بها، والتي تم تضمينها بالفعل في إجمالي ذاكرة التخزين المؤقت المشفرة. الصفر يعني عدم وجود بايتات محتجزة في ذاكرة التخزين المؤقت هذه، وليس أن الميزة لا تستخدم أي ذاكرة. تشترك الخلفيات والصور المعروضة في ذاكرة التخزين المؤقت التي تم فك تشفيرها أعلاه؛ قد تكون الصور النشطة خارجها. لا يمكن تقسيم الطقس والإشعارات وكائنات Dart والمحرك حسب الميزة هنا. تم الإبلاغ عن رسومات الواجهة المشتركة أعلاه بواسطة Android وتم تضمينها بالفعل في PSS. ذاكرتهم جزء من العملية الإجمالية. لا تقم بإضافة هذه القيم المتداخلة.';

  @override
  String get memoryGraphics => 'رسومات الواجهة (مضمنة في PSS)';

  @override
  String get categoryVisible => 'إظهار الفئة';

  @override
  String get hiddenCategories => 'الفئات المخفية';

  @override
  String get visibleCategories => 'فئات مرئية';

  @override
  String get backupSavedToSelectedLocation =>
      'تم حفظ النسخة الاحتياطية في الموقع المحدد';

  @override
  String get tileHorizontalGap => 'التباعد الأفقي';

  @override
  String get tileVerticalGap => 'تباعد عمودي';

  @override
  String get tileOpacity => 'عتامة الخلفية';

  @override
  String get tileShadow => 'الظل';

  @override
  String get tileCornerRadius => 'تقريب الزاوية';

  @override
  String get tileIconScale => 'حجم الأيقونة';

  @override
  String get tileBackgroundColor => 'خلفية البلاط';

  @override
  String get tileLabelSize => 'حجم التسمية';

  @override
  String get resetAppearance => 'إعادة ضبط المظهر';

  @override
  String get tileAppearance => 'مظهر البلاط';

  @override
  String get tileLabelColor => 'لون التسمية';

  @override
  String get tilePreviewName => 'تطبيق عينة';

  @override
  String get tileProportions => 'نسب البلاط';

  @override
  String get tileLarge => 'كبير';

  @override
  String get tileLabelBelow => 'أسفل البلاط';

  @override
  String get tileLabelInside => 'داخل البلاط';

  @override
  String get tileFocusScale => 'تكبير';

  @override
  String get tileMedium => 'متوسط';

  @override
  String get tileFocusBorder => 'لا حركة';

  @override
  String get tileSize => 'حجم البلاط';

  @override
  String get tileCompact => 'مدمج';

  @override
  String get tileLabelPosition => 'موقف التسمية';

  @override
  String get tileFocusEffect => 'تأثير التركيز';

  @override
  String get tileFocusStrength => 'تسليط الضوء على شدة';

  @override
  String get panelIndependent => 'الإعدادات المخصصة';

  @override
  String get panelAppearance => 'نمط اللوحة العلوية';

  @override
  String get panelBackground => 'خلفية اللوحة';

  @override
  String get blurPerformanceHint =>
      'التمويه قد يقلل من النعومة. يتم تعطيله أثناء تشغيل حفظ الذاكرة.';

  @override
  String get panelOpacity => 'عتامة اللوحة';

  @override
  String get tileBlur => 'طمس وراء البلاط';

  @override
  String get panelBlur => 'طمس خلف اللوحة العلوية';

  @override
  String get panelShared => 'مثل الألواح';

  @override
  String get weatherMinutes => 'دقيقة';

  @override
  String get weatherOpenMeteoCredit =>
      'الطقس: Open-Meteo (open-meteo.com)، CC BY 4.0. API مجاني للاستخدام غير التجاري.';

  @override
  String get weatherRateLimit => 'تم الوصول إلى حد الطلب. حاول لاحقًا.';

  @override
  String get weatherYandexCredit =>
      'الطقس: الطقس ياندكس (yandex.ru/pogoda). يعتمد الوصول على خطة API الخاصة بك.';

  @override
  String get yandexWeather => 'ياندكس ويذر (REST)';

  @override
  String get weatherAuthorizationError =>
      'رفض مزود الطقس الطلب. تحقق من مفتاح API وقم بالوصول إلى الخدمة المحددة.';

  @override
  String get weatherYandexHint =>
      'يتطلب مفتاحًا يتمتع بإمكانية الوصول إلى توقعات REST. قد لا يعمل مفتاح خطة Yandex أخرى.';

  @override
  String get weatherSource => 'مصدر الطقس';

  @override
  String get weatherInterval => 'الفاصل الزمني للتحديث';

  @override
  String get weatherLongitude => 'خط الطول (-180 إلى 180)';

  @override
  String get weatherKeyRequired => 'أضف مفتاح Yandex API.';

  @override
  String get weatherLocationName => 'اسم المدينة (اختياري)';

  @override
  String get weatherLocation => 'الموقع';

  @override
  String get weatherApiKey => 'مفتاح ياندكس API';

  @override
  String get weatherInvalidResponse =>
      'قام مصدر الطقس بإرجاع بيانات غير صالحة.';

  @override
  String get weatherUnavailable =>
      'الطقس غير متوفر. يتم الاحتفاظ بالبيانات المستلمة مسبقًا إذا كانت متوفرة. تقتصر عمليات إعادة المحاولة على مرة واحدة كل 5 دقائق.';

  @override
  String get weatherStale => 'الطقس السابق';

  @override
  String get weatherLatitude => 'خط العرض (-90 إلى 90)';

  @override
  String get weatherCoordinatesError =>
      'أدخل المدينة يدويًا أو احصل على الإحداثيات تلقائيًا.';

  @override
  String get weatherRefresh => 'التحقق من وجود تحديثات';

  @override
  String get weatherKeyPrivate =>
      'مخزنة فقط على هذا الجهاز، مستبعدة من النسخ الاحتياطية. الإدخال الفارغ يزيل المفتاح.';

  @override
  String get weatherUpdated => 'تم التحديث';

  @override
  String get onlineWallpaperError =>
      'غير قادر على تحميل هذه الصورة. يتم الاحتفاظ بالخلفية السابقة. حدد \"التحقق من وجود تحديثات\" لإعادة محاولة التنزيل.';

  @override
  String get onlineWallpaperHint =>
      'تُحفظ آخر صورة لاستخدامها دون اتصال (بحد أقصى 8 MiB).';

  @override
  String get onlineWallpaperHours => 'ح';

  @override
  String get onlineWallpaperInterval => 'تحميل الفاصل الزمني';

  @override
  String get onlineWallpaper => 'خلفية على الانترنت';

  @override
  String get onlineWallpaperUrlError =>
      'أدخل صورة HTTPS مباشرة URL بدون تفاصيل تسجيل الدخول.';

  @override
  String get onlineWallpaperEnabled => 'استخدم ورق الحائط على الإنترنت';

  @override
  String get onlineWallpaperSource => 'مصدر الصورة';

  @override
  String get bingWallpaper => 'صورة اليوم Bing';

  @override
  String get onlineWallpaperUrlSource => 'مباشر HTTPS URL';

  @override
  String get updatePlayOnly =>
      'يتلقى هذا التثبيت التحديثات من خلال Google Play.';

  @override
  String get updateCheck => 'تحقق الآن';

  @override
  String get updateInstalled => 'تم التثبيت';

  @override
  String get updateDownloadInstall => 'تحميل وتثبيت';

  @override
  String get updateNoRelease => 'لا يتوفر أي إصدار متوافق أحدث.';

  @override
  String get updateIncompatible =>
      'لا يتطابق APK مع هذا التطبيق أو الشهادة أو الإصدار الأحدث. تم حظر التثبيت.';

  @override
  String get updateError =>
      'غير قادر على التحقق من برنامج التثبيت أو تنزيله أو فتحه. حاول مرة أخرى لاحقًا.';

  @override
  String get updateAvailable => 'التحديث متاح';

  @override
  String get appUpdates => 'تحديثات التطبيق';

  @override
  String get updatePermission =>
      'اسمح بالتثبيت من هذا التطبيق في إعدادات Android، ثم ارجع هنا واضغط على \"تثبيت\" مرة أخرى.';

  @override
  String get updateInstall => 'قم بتثبيت التحديث الذي تم تنزيله';

  @override
  String get updateHint =>
      'المصدر: GitHub / KirillShchetinnikov/CuteLauncher-Releases. يتم تشغيل عمليات الفحص التلقائي أثناء فتح المشغل. يبدأ التنزيل عندما تختاره؛ يطلب منك Android تأكيد التثبيت. يتم الاحتفاظ بالبيانات الخاصة بك.';

  @override
  String get updateAutomatic => 'تحقق تلقائيا مرة واحدة في اليوم';

  @override
  String get allApplications => 'جميع التطبيقات';

  @override
  String get adbAccessibility => 'تمكين إصلاح زر الصفحة الرئيسية';

  @override
  String get adbAuthorization =>
      'قم باعتماد ترخيص ADB على التلفزيون، ثم حاول مرة أخرى.';

  @override
  String get adbChangeConfirm =>
      'هل تريد تطبيق إعداد النظام هذا من خلال ADB؟ يتم حفظ تطبيق المنزل السابق قبل تغييره؛ ويتم الحفاظ على خدمات إمكانية الوصول الأخرى.';

  @override
  String get adbCheck => 'تحقق من الاتصال';

  @override
  String get adbDenied => 'ولم يسمح النظام أو يؤكد هذا التغيير.';

  @override
  String get adbDisable => 'تعطيل المشغل السابق';

  @override
  String get adbDisableConfirm =>
      'هل تريد تعطيل المشغل السابق المحفوظ؟ يتطلب هذا أن يكون CuteLauncher هو تطبيق Home الحالي. قم باستعادته باستخدام إجراء الاسترداد في هذا الإعداد.';

  @override
  String get adbHint =>
      'النموذج الأولي لهذا التلفزيون فقط (127.0.0.1). قم بتمكين TCP ADB في خيارات المطور، وأدخل المنفذ الخاص به وقم بالموافقة على مطالبة التفويض على التلفزيون. تصحيح الأخطاء اللاسلكية باستخدام رمز الاقتران غير مدعوم حتى الآن. يبقى المفتاح الخاص على هذا الجهاز، خارج النسخ الاحتياطية.';

  @override
  String get adbHome => 'اجعل CuteLauncher هو تطبيق المنزل';

  @override
  String get adbInvalid => 'أدخل منفذًا بين 1024 و65535.';

  @override
  String get adbNoRecovery =>
      'الاستعادة غير متاحة: لم يتم العثور على مشغل آخر أو حالة خدمة محفوظة.';

  @override
  String get adbPort => 'منفذ تي سي بي ADB';

  @override
  String get adbReady => 'تم تأكيد الوصول إلى ADB.';

  @override
  String get adbRestore => 'استعادة المشغل السابق';

  @override
  String get adbSuccess => 'تم تطبيق التغيير والتحقق منه.';

  @override
  String get adbTitle => 'إعداد ADB';

  @override
  String get adbUnavailable =>
      'غير قادر على الاتصال. تحقق من TCP ADB والمنفذ ومطالبة الترخيص.';

  @override
  String get nightModeScheduled => 'استخدام الجدول الزمني';

  @override
  String get nightModeTitle => 'الوضع الليلي';

  @override
  String get nightModeScope =>
      'هناك حاجة إلى إذن تراكب لتعتيم التطبيقات الأخرى. بدونها، يعمل التعتيم داخل CuteLauncher. لا يحتاج مرشح TCL إلى إذن تراكب. التعتيم الذي يزيد عن 80% قد يمنع Android الإدخال باللمس في التطبيقات الأخرى؛ لا تزال مفاتيح التحكم عن بعد الخاصة بالتلفزيون تعمل.';

  @override
  String get nightModeEnd => 'نهاية';

  @override
  String get nightModeStart => 'ابدأ';

  @override
  String get nightModeDim => 'يعتم';

  @override
  String get nightModeWarmth => 'مرشح دافئ';

  @override
  String get nightModeScheduleHint =>
      'يستخدم وقت التلفزيون المحلي. يتم دعم فترات بين عشية وضحاها. تعمل أوقات البدء والانتهاء المتساوية على تعطيل عامل التصفية المجدول.';

  @override
  String get nightModeEnabled => 'تمكين الوضع الليلي';

  @override
  String get nightModePermission => 'السماح بالعرض على التطبيقات الأخرى';

  @override
  String get nightModePermissionGranted =>
      'العرض على التطبيقات الأخرى مسموح به';

  @override
  String get backupDownloadsFailed =>
      'لا يمكن حفظ النسخة الاحتياطية للتنزيلات.';

  @override
  String get backupSaveDownloads => 'حفظ النسخة الاحتياطية للتنزيلات';

  @override
  String get adbRestoreAccessibility => 'استعادة إمكانية الوصول';

  @override
  String get nightModeAdbConfirm =>
      'هل تريد السماح لـ CuteLauncher بالعرض فوق التطبيقات الأخرى باستخدام ADB المحلي؟ قم بتمكين تصحيح أخطاء TCP أولاً ثم قم بتخويل الاتصال. يستخدم المنفذ المحفوظ في معالج ADB، أو 5555.';

  @override
  String get nightModeAdbPermission => 'منح الإذن من خلال ADB';

  @override
  String get nightModeNotificationsHint =>
      'يتيح لك الإشعار إيقاف تشغيل عامل التصفية خارج CuteLauncher. بدونها، استخدم هذه القائمة.';

  @override
  String get nightModeNotificationsAllowed => 'يسمح بإشعار الوضع الليلي';

  @override
  String get nightModeNotifications => 'السماح بإشعار الوضع الليلي';

  @override
  String get categoryLastVisibleHint => 'يجب أن تظل فئة واحدة على الأقل مرئية.';

  @override
  String get diagnosticsClear => 'مسح تشخيصات الجلسة';

  @override
  String get diagnosticsReady => 'التقرير جاهز';

  @override
  String get diagnosticsCreate => 'إنشاء تقرير';

  @override
  String get diagnosticsOperations => 'العمليات المسجلة';

  @override
  String get diagnosticsCopied => 'تم نسخ التقرير';

  @override
  String get diagnosticsHint =>
      'يحتوي التقرير على إصدار التطبيق وحالة الإذن واستخدام الذاكرة ونتائج التشغيل. وهو يستثني المفاتيح والعناوين ومسارات الملفات وقوائم التطبيقات ومحتوى الإشعارات. يتم الاحتفاظ بآخر 50 عملية فقط في الذاكرة حتى تتم إعادة تشغيل التطبيق. لا يتم إرسال أي شيء تلقائيًا.';

  @override
  String get diagnosticsTitle => 'تشخيص الأخطاء';

  @override
  String get diagnosticsCopyFailed => 'لا يمكن نسخ التقرير.';

  @override
  String get diagnosticsCopy => 'نسخ التقرير';

  @override
  String get diagnosticsCreating => 'جارٍ إنشاء التقرير...';

  @override
  String get tclBlueLightTitle => 'TCL مرشح الضوء الأزرق';

  @override
  String get tclBlueLightError =>
      'تعذر قراءة أو التحقق من إعداد عامل التصفية TCL. قم بتحديث حالته وحاول مرة أخرى.';

  @override
  String get tclBlueLightUnsupported =>
      'واجهة مرشح TCL غير متوفرة على هذا التلفزيون.';

  @override
  String get tclBlueLightRefresh => 'قم بتحديث حالة عامل التصفية TCL';

  @override
  String get tclBlueLightHint =>
      'يتحكم في مرشح حماية صحة العين المدمج في التلفزيون. ويمكنه أيضًا متابعة جدول الوضع الليلي.';

  @override
  String get nightSolarSchedule => 'غروب الشمس وشروق الشمس';

  @override
  String get nightNextStart => 'البداية التالية';

  @override
  String get nightScheduleTimeHint =>
      'تستخدم الأوقات المنطقة الزمنية للتلفزيون. الإزاحات السلبية سابقة؛ الإزاحات الإيجابية تأتي في وقت لاحق.';

  @override
  String get nightTemperature => 'تصفية درجة حرارة اللون';

  @override
  String get nightScheduleSettings => 'إعدادات الجدول الزمني';

  @override
  String get nightCityName => 'اسم المدينة';

  @override
  String get nightSkipUntilNext => 'تعطيل الوضع الليلي حتى غروب الشمس التالي';

  @override
  String get nightSunriseOffset => 'النهاية بالنسبة لشروق الشمس';

  @override
  String get nightEnableUntilMorning =>
      'تمكين الوضع الليلي حتى شروق الشمس التالي';

  @override
  String get nightPermissions => 'الأذونات';

  @override
  String get nightTclSchedule => 'تضمين مرشح TCL في الجدول الزمني';

  @override
  String get nightSearchCity => 'بحث';

  @override
  String get nightRefreshSun => 'تحديث شروق الشمس وغروبها';

  @override
  String get nightSolarUnavailable =>
      'اختر مدينة وقم بتحديث أوقات الشمس. إذا لم يكن شروق الشمس أو غروبها متاحًا، فسيتوقف الجدول الشمسي مؤقتًا.';

  @override
  String get nightSunsetOffset => 'ابدأ بالنسبة لغروب الشمس';

  @override
  String get nightCityHint =>
      'اختر مدينتك بدلاً من منح الوصول إلى الموقع. يتم إرسال الإحداثيات المحددة إلى Sunrise-Sunset.org، أو Open-Meteo كبديل، لاسترداد أوقات الشمس.';

  @override
  String get nightResumeSchedule => 'العودة إلى الجدول الزمني';

  @override
  String get nightScheduleSource => 'نوع الجدول الزمني';

  @override
  String get nightSolarCached =>
      'استخدام أوقات الشمس المخزنة مؤقتًا؛ ستتم إعادة محاولة تحديث الإنترنت تلقائيًا.';

  @override
  String get nightTclScheduleHint =>
      'يستخدم نفس الجدول الزمني أثناء تمكين الوضع الليلي. تستمر التغييرات اليدوية على مرشح TCL حتى عملية النقل المجدولة التالية. ليس هناك حاجة إلى إذن تراكب.';

  @override
  String get nightRefreshPermission => 'تحديث حالة الإذن';

  @override
  String get nightCityNotFound => 'لم يتم العثور على مدن. حاول اسم آخر.';

  @override
  String get nightNoOffset => 'لا تعويض';

  @override
  String get nightManualSchedule => 'جدول مخصص';

  @override
  String get nightChooseCity => 'اختر المدينة';

  @override
  String get nightPermissionUnknown => 'حالة إذن التراكب غير معروفة';

  @override
  String get nightNextEnd => 'النهاية القادمة';

  @override
  String get nightTemporaryOff => 'يعتم مؤقتا حتى';

  @override
  String get nightCitySearchFailed =>
      'لا يمكن البحث عن المدن. تحقق من اتصالك بالإنترنت.';

  @override
  String get nightSolarAttribution =>
      'أوقات الشمس اليومية: Sunrise-Sunset.org؛ الاحتياطي: Open-Meteo. البحث عن المدينة: الأسماء الجغرافية. يتم تخزين عدة أيام مؤقتًا للاستخدام دون اتصال.';

  @override
  String get nightTemporaryOn => 'يتم التعتيم مؤقتًا حتى';

  @override
  String get homeScreen => 'الشاشة الرئيسية';

  @override
  String get appearanceSettings => 'المظهر';

  @override
  String get generalSettings => 'متقدم';

  @override
  String get advancedSettings => 'متقدم';

  @override
  String get controlAndStartup => 'الضوابط مشغّل والتلفزيون';

  @override
  String get sectionsAndOrder => 'الأقسام والترتيب';

  @override
  String get topPanel => 'اللوحة العلوية';

  @override
  String get tileStyle => 'نمط البلاط';

  @override
  String get tilesAndLabels => 'البلاط والعلامات';

  @override
  String get highlightAndAnimation => 'تسليط الضوء والرسوم المتحركة';

  @override
  String get androidTvSettings => 'إعدادات Android TV';

  @override
  String get weatherSettings => 'إعدادات الطقس';

  @override
  String get showHighlightOutline => 'إظهار الخطوط العريضة المميزة';

  @override
  String get resetTilesAndPanel => 'إعادة ضبط إعدادات البلاط واللوحة';

  @override
  String get resetTilesAndPanelHint =>
      'هل تريد إعادة تعيين معلمات التجانب والتسمية والتمييز واللوحة العلوية الإضافية؟ يتم الحفاظ على ورق الحائط ولون التمييز ونمط البلاط ورؤية الملصق.';

  @override
  String get panelAppearanceSettings => 'مظهر اللوحة العلوية';

  @override
  String get panelSharedHint => 'تغيير المظهر في إعدادات البلاط.';

  @override
  String get effectsCompatibilityHint =>
      'مظهر إضافي: المخطط التفصيلي مرئي دائمًا ولا ينبض. لا يحتوي نمط الأبعاد على مخطط تفصيلي قديم؛ الكلاسيكية لا تنبض. تؤثر الشدة على الحجم والظل. القياس محدود المساحة.';

  @override
  String get sizeAndLayout => 'الحجم والتخطيط';

  @override
  String get labelsGroup => 'التسميات';

  @override
  String get surfaceGroup => 'السطح';

  @override
  String get clockAndDateGroup => 'الساعة والتاريخ';

  @override
  String get networkAndTrafficGroup => 'الشبكة وحركة المرور';

  @override
  String get buttonsGroup => 'الأزرار';

  @override
  String get notificationAppsHint =>
      'قم بإيقاف تشغيل التطبيقات التي لا تحتاج إلى إشعاراتها. يسمح المفتاح الممكّن بالإشعارات؛ لا يزال من الممكن إطلاق التطبيق.';

  @override
  String get notificationPanelLink => 'مظهر اللوحة العلوية';

  @override
  String get overlayAccessAdb => 'العرض فوق التطبيقات الأخرى (ADB)';

  @override
  String get tileStyleModern => 'حديث';

  @override
  String get tileStyleVolume => 'الأبعاد';

  @override
  String get showTime => 'عرض الوقت';

  @override
  String get showDate => 'تاريخ العرض';

  @override
  String get showWeather => 'عرض الطقس';

  @override
  String get showNetwork => 'إظهار حالة الشبكة';

  @override
  String get showTraffic => 'عرض حركة المرور';

  @override
  String get scheduledBrightness => 'السطوع المقرر';

  @override
  String get followTileStyle => 'اتبع الاسلوب';

  @override
  String get androidTvSettingsHint => 'افتح إعدادات نظام التلفزيون';

  @override
  String get autoHideTopPanel => 'إخفاء اللوحة تلقائيًا';

  @override
  String get showSectionTitles => 'إظهار عناوين الأقسام';

  @override
  String get usageDaily => 'يوميا';

  @override
  String get usageWeekly => 'أسبوعيا';

  @override
  String get usageMonthly => 'شهريا';

  @override
  String get onlineWallpaperAddress => 'عنوان الصورة (HTTPS)';

  @override
  String get watchNextAppLimits => 'الحدود لكل تطبيق';

  @override
  String get watchNextAppLimitsHint =>
      'تنطبق حدود المصدر قبل الحد الإجمالي. يحتفظ برنامج Unlimited بالحد الإجمالي فقط؛ المحتوى المخفي يظل مخفيًا.';

  @override
  String get rememberCategoryFocus => 'تذكر آخر بطاقة مركزة';

  @override
  String get automaticBackups => 'النسخ الاحتياطي التلقائي';

  @override
  String get automaticBackupsHint =>
      'نسخ يومية من الإعدادات والخلفيات واللافتات أثناء تنشيط المشغل. يتم تشغيل النسخة المفقودة بعد العودة إلى المشغل. تم تخزينها بشكل خاص على هذا الجهاز، بما يصل إلى 256 MiB؛ تؤدي إزالة التطبيق أو بياناته إلى حذفها. احتفظ بنسخة احتياطية خارجية أيضًا.';

  @override
  String get automaticBackupsEnabled => 'النسخ الاحتياطي التلقائي اليومي';

  @override
  String get automaticBackupsKeep => 'نسخ للاحتفاظ بها';

  @override
  String get automaticBackupCreateNow => 'قم بإنشاء نقطة استعادة الآن';

  @override
  String get automaticBackupFailed =>
      'فشلت عملية النسخ الاحتياطي. تحقق من المساحة الحرة وحاول مرة أخرى.';

  @override
  String get restorePoints => 'استعادة النقاط';

  @override
  String get noRestorePoints => 'لا توجد نقاط استعادة حتى الآن';

  @override
  String get updatePrereleases => 'التحديث إلى الإصدارات التجريبية';

  @override
  String get topPanelObjects => 'العناصر';

  @override
  String get panelTransparency => 'شفافية اللوحة';

  @override
  String get panelTextBackground => 'خلفية النص والزر';

  @override
  String get panelTextBackgroundColor => 'لون خلفية النص والزر';

  @override
  String get panelTextColor => 'لون النص والزر';

  @override
  String get panelTextSize => 'حجم النص والزر';

  @override
  String get panelFont => 'خط النص';

  @override
  String get fontSans => 'بلا رقيق';

  @override
  String get fontSerif => 'شريف';

  @override
  String get fontMono => 'مونوسبيس';

  @override
  String get fontCondensed => 'مكثفة';

  @override
  String get trafficPermissionGranted =>
      'تم منح الوصول إلى إحصاءات حركة المرور';

  @override
  String get background => 'الخلفية';

  @override
  String get backgroundParameters => 'المعلمات';

  @override
  String get resetAppearanceHint =>
      'إعادة ضبط الخلفية واللكنة والبلاط والعلامات والتمييز والرسوم المتحركة؟';

  @override
  String get wallpaperDimming => 'يعتم';

  @override
  String get wallpaperPlacement => 'التنسيب';

  @override
  String get wallpaperDisplay => 'عرض ورق الحائط';

  @override
  String get wallpaperContain => 'إظهار الصورة كاملة';

  @override
  String get wallpaperBlurred => 'أكثر من نسخة غير واضحة';

  @override
  String get wallpaperCover => 'ملء الشاشة';

  @override
  String get wallpaperBrightness => 'سطوع ورق الحائط';

  @override
  String get wallpaperSaturation => 'التشبع';

  @override
  String get categoryPadding => 'حشوة الفئة';

  @override
  String get categoryLight => 'ضوء';

  @override
  String get categoryBlue => 'أزرق';

  @override
  String get categoryPurple => 'أرجواني';

  @override
  String get categoryAllRows => 'الكل';

  @override
  String get categoryTeal => 'البط البري';

  @override
  String get categoryMaxRows => 'صفوف شبكية مرئية';

  @override
  String get categoryDark => 'الظلام';

  @override
  String get categoryAppearance => 'مظهر الفئة';

  @override
  String get categoryBackground => 'خلفية الفئة';

  @override
  String get categoryTransparent => 'شفاف';

  @override
  String get slideshowInterval => 'تغيير الفاصل الزمني';

  @override
  String get slideshowFolderSelected =>
      'الوصول إلى المجلدات المحفوظة على هذا الجهاز.';

  @override
  String get slideshowRandom => 'ترتيب عشوائي';

  @override
  String get wallpaperSlideshow => 'عرض شرائح المجلد';

  @override
  String get slideshowNext => 'الصورة التالية';

  @override
  String get slideshowFolderRequired => 'اختر مجلدًا لبدء عرض الشرائح.';

  @override
  String get slideshowHint =>
      'ما يصل إلى 1000 صورة و4000 إدخال مجلد؛ ملفات تصل إلى 8 MiB. يتم تخطي الملفات الفاسدة ويتم الاحتفاظ بالصورة الأخيرة الجيدة. تتوقف التغييرات في الخلفية. اختر المجلد مرة أخرى بعد الاستعادة على جهاز آخر.';

  @override
  String get slideshowSeconds => 'ق';

  @override
  String get slideshowError =>
      'غير قادر على قراءة الصور. اختر مجلدًا يمكن الوصول إليه يحتوي على صور صالحة.';

  @override
  String get slideshowFolder => 'اختر المجلد';

  @override
  String get slideshowRecursive => 'تضمين المجلدات الفرعية';

  @override
  String get weatherSourceKeyRequired => 'أضف مفتاح API لمصدر الطقس هذا.';

  @override
  String get weatherOpenWeatherCredit =>
      'الطقس: OpenWeather (openweathermap.org). تلخص القيم اليومية فترات التنبؤ المتاحة لمدة ثلاث ساعات.';

  @override
  String get weatherOpenWeatherHint =>
      'استخدم مفتاحك للطقس الحالي والتنبؤات لمدة 5 أيام / 3 ساعات. يقدم كل تحديث طلبين؛ يعتمد الوصول والحدود على خطتك.';

  @override
  String get weatherOpenWeatherKey => 'مفتاح OpenWeather API';

  @override
  String get mediaPause => 'وقفة';

  @override
  String get showNowPlaying => 'عرض يتم تشغيله الآن على الصفحة الرئيسية';

  @override
  String get nowPlayingAccessHint =>
      'تتطلب عناصر التحكم في الوسائط الوصول إلى الإشعارات لـ CuteLauncher. يتم عرض الإجراءات التي يقدمها اللاعب فقط.';

  @override
  String get nowPlaying => 'العب الآن';

  @override
  String get mediaNext => 'المسار التالي';

  @override
  String get mediaPlay => 'استئناف';

  @override
  String get mediaControlError => 'اللاعب غير متاح أو لم يقبل هذا الإجراء.';

  @override
  String get nightUsageAccess => 'السماح بالوصول إلى الاستخدام';

  @override
  String get nightExcludedAppsHint =>
      'يتوقف التراكب ومرشح TCL المجدول في التطبيقات المحددة. مطلوب الوصول إلى الاستخدام؛ وبدون ذلك، لا يمكن تطبيق الاستثناءات.';

  @override
  String get nightExcludedApps => 'التطبيقات المستبعدة';

  @override
  String get adbPairPort => 'منفذ الاقتران';

  @override
  String get adbPairOverlayHint =>
      'افتح تصحيح الأخطاء اللاسلكية وقم بالاقتران برمز الاقتران. أبقِ مربع حوار رمز النظام مفتوحًا. يصبح هذا النموذج نشطًا بعد 30 ثانية. أدخل كلا المنفذين والرمز الموضح بواسطة Android.';

  @override
  String get adbOverlaySettings => 'أعد التحكم إلى الإعدادات لمدة 30 ثانية';

  @override
  String get adbTlsHint =>
      'استخدم تصحيح الأخطاء اللاسلكية في خيارات المطور. الاقتران والاتصال لهما منافذ مختلفة. إذا كان البرنامج الثابت الخاص بك لا يحتوي على شاشة رمز الاقتران أو يحظر تراكب النوافذ، فاستخدم TCP / RSA بدلاً من ذلك. تظل كافة الاتصالات محلية لهذا التلفزيون.';

  @override
  String get adbPaired =>
      'يقترن. تحقق من الاتصال باستخدام منفذ اتصال تصحيح الأخطاء اللاسلكي.';

  @override
  String get adbTransport => 'طريقة الاتصال';

  @override
  String get adbPairCode => 'رمز مكون من ستة أرقام';

  @override
  String get adbOverlayRequired =>
      'يتطلب إدخال الرمز عبر الإعدادات إذنًا للعرض عبر التطبيقات الأخرى.';

  @override
  String get adbOverlayPermission => 'السماح بالعرض على التطبيقات الأخرى';

  @override
  String get adbTlsUnsupported =>
      'لا يمكن لهذه البرامج الثابتة فتح شاشة الإعدادات المطلوبة أو تراكب الاقتران. استخدم TCP/RSA.';

  @override
  String get adbConnectPort => 'منفذ الاتصال';

  @override
  String get adbTls => 'TLS/رمز الاقتران';

  @override
  String get adbTcp => 'تكب / آر إس إيه';

  @override
  String get adbPairingFailed =>
      'فشل الاقتران. تحقق من الكود ومنفذ الاقتران، واترك مربع حوار الكود Android مفتوحًا، ثم حاول مرة أخرى.';

  @override
  String get adbTlsDisabled =>
      'تم تعطيل تصحيح الأخطاء اللاسلكية أو أن حالته غير متوفرة. تمكينه في خيارات المطور.';

  @override
  String get adbPairOverlay => 'أدخل رمز الاقتران عبر الإعدادات';

  @override
  String get adbPair => 'زوج';

  @override
  String get adbDeveloperSettings => 'افتح خيارات المطور';

  @override
  String get adbTwoWindowsHint =>
      'إذا كانت هذه البرامج الثابتة تدعم نافذتين، فاحتفظ بمربع حوار إقران النظام مفتوحًا بجوار CuteLauncher وأدخل الرمز الخاص به هنا. الاقتران المباشر متاح فقط عندما تكون كلا النافذتين مفتوحتين.';

  @override
  String get adbTwoWindows => 'افتح الإعدادات في نافذة ثانية';

  @override
  String get autoLaunchBoot => 'بعد تمهيد التلفزيون';

  @override
  String get autoLaunchOff => 'معطل';

  @override
  String get autoLaunchTitle => 'تشغيل تلقائي';

  @override
  String get autoLaunchDelay => 'تأخير الإطلاق';

  @override
  String get autoLaunchHdmi => 'قم بالتبديل إلى إدخال HDMI المحدد';

  @override
  String get autoLaunchWake => 'بعد الاستيقاظ';

  @override
  String get autoLaunchHint =>
      'اختر تطبيقًا أو إدخال HDMI لفتحه بعد بدء تشغيل التلفزيون أو تنبيهه. قم بتعيين الحدث والتأخير أدناه. يتم تشغيل الإجراء مرة واحدة عندما يعرض Android CuteLauncher. أي إدخال عن بعد أو مغادرة الشاشة الرئيسية يلغي الانتظار. يمكنك تغيير مدخلات HDMI بحرية بعد ذلك. قم بتعيين CuteLauncher كمشغل افتراضي أو قم بتمكين البدء عند التمهيد إذا لزم الأمر. يتطلب اكتشاف التنبيه أن يظل CuteLauncher قيد التشغيل.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds ثانية';
  }

  @override
  String get autoLaunchApp => 'افتح التطبيق المحدد';

  @override
  String get autoLaunchTarget => 'إطلاق الهدف';

  @override
  String get autoLaunchUnavailable =>
      'الهدف غير متاح أو أن البرنامج الثابت لا يسمح بهذا الإجراء.';

  @override
  String get autoLaunchCancelled => 'تم إلغاء الإطلاق المؤجل.';

  @override
  String get syncTitle => 'إعدادات الصرف';

  @override
  String get syncHint =>
      'احفظ ملف الإعدادات، ثم انقله إلى جهاز آخر وافتحه هناك. قم باستبدال الملف مرة أخرى لتحديث كلا الجهازين. تتم مشاركة الواجهة ونمط التجانب وتفضيلات العرض. تبقى التطبيقات والأقسام وملفات الخلفية والأذونات وHOME وقواعد التشغيل والأسرار على هذا الجهاز. هذا هو التبادل اليدوي. لا يتم استخدام أي حساب أو اتصال بالشبكة الخلفية.';

  @override
  String get syncExport => 'حفظ التغييرات في ملف';

  @override
  String get syncImport => 'فتح التغييرات من جهاز آخر';

  @override
  String get syncSaved => 'تم حفظ ملف تبادل الإعدادات.';

  @override
  String get syncFailed =>
      'غير قادر على تبادل الإعدادات. لا يتم الاحتفاظ بالاستيراد الجزئي. قم بفحص الملف أو فتحه مرة أخرى إذا تغيرت الإعدادات أثناء المراجعة.';

  @override
  String get syncPreviewHint =>
      'قم بمراجعة التغييرات قبل التقديم. بالنسبة للتعارضات، حدد كل صف لاختيار هذا الجهاز أو الملف. تم تحديد حفظ هذا الجهاز في البداية. إلغاء يترك الإعدادات دون تغيير.';

  @override
  String get syncNoChanges =>
      'لا توجد إعدادات جديدة. تقدم بطلب للاعتراف بالتاريخ المشترك.';

  @override
  String syncLocalValue(String value) {
    return 'هذا الجهاز: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'من الملف: $value';
  }

  @override
  String get syncKeepLocal => 'الصراع: احتفظ بهذا الجهاز';

  @override
  String get syncUseFile => 'الصراع: استخدم الملف';

  @override
  String get syncApply => 'تطبيق التغييرات التي تمت مراجعتها';

  @override
  String get syncApplied =>
      'تم تبادل الإعدادات احفظ ملفًا جديدًا لإرسال النتيجة مرة أخرى.';

  @override
  String syncStyleParameters(int count) {
    return 'نمط مخصص: $count من الإعدادات (الاختلافات أدناه)';
  }

  @override
  String get cloudBackups => 'النسخ الاحتياطية السحابية';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud. أدخل عنوان HTTPS لمجلد موجود وكلمة مرور التطبيق. التحويلات تتم يدوياً؛ يخزن هذا المجلد أحدث نسخة.';

  @override
  String get cloudUrl => 'عنوان المجلد HTTPS';

  @override
  String get cloudUser => 'اسم المستخدم';

  @override
  String get cloudPassword => 'كلمة مرور التطبيق';

  @override
  String get cloudConnect => 'فحص وحفظ الحساب';

  @override
  String get cloudCheck => 'تحقق من الاتصال';

  @override
  String get cloudDisconnect => 'افصل الحساب';

  @override
  String get cloudDisconnectConfirm =>
      'هل تريد إزالة هذا الحساب من التلفزيون؟ ستبقى النسخ في السحابة.';

  @override
  String get cloudUpload => 'حفظ نسخة إلى السحابة';

  @override
  String get cloudDownload => 'استعادة من السحابة';

  @override
  String get cloudUploadConfirm =>
      'هل تريد استبدال Cutelauncher_backup.json في هذا المجلد بالإعدادات والبيانات الحالية؟';

  @override
  String get cloudSuccess => 'تم';

  @override
  String get cloudConfigurationError =>
      'تحقق من عنوان المجلد HTTPS واسم المستخدم وكلمة مرور التطبيق.';

  @override
  String get cloudAuthorizationError =>
      'تم رفض الوصول. تحقق من أذونات حسابك والمجلد.';

  @override
  String get cloudMissingError =>
      'لم يتم العثور على المجلد أو النسخة الاحتياطية.';

  @override
  String get cloudUnsupportedError =>
      'لا يدعم هذا العنوان عمليات WebDAV المطلوبة. لا يتم اتباع عمليات إعادة التوجيه؛ أدخل عنوان المجلد النهائي.';

  @override
  String get cloudNetworkError =>
      'فشل الاتصال أو انتهت مهلته. حاول مرة أخرى عندما تكون الشبكة متاحة.';

  @override
  String get cloudFailed =>
      'تعذر إكمال إجراء النسخ الاحتياطي. تحقق من الوصول إلى مساحة التخزين وحاول مرة أخرى.';

  @override
  String get cloudStorageError =>
      'تخزين الحساب غير متوفر. افصل الحساب وقم بتكوينه مرة أخرى.';

  @override
  String get adbPermissionChecking => 'جارٍ التحقق من الوصول…';

  @override
  String get adbPermissionConnected => 'ADB متصل · منح الإذن';

  @override
  String get adbPermissionDisconnected => 'تم قطع اتصال ADB · إعداد الاتصال';

  @override
  String get adbSetupIntro =>
      'قم بتمكين تصحيح الأخطاء والشبكة ADB في إعدادات مطور التلفزيون، ثم ثق بـ CuteLauncher. جميع إجراءات ADB تكون على مسؤوليتك الخاصة.';

  @override
  String get adbConnectionBlock => 'اتصال ADB';

  @override
  String get adbNotChecked => 'لم يتم التحقق من الاتصال';

  @override
  String get adbApplied => 'تم تطبيقه بالفعل';

  @override
  String get adbNotApplied => 'لم تطبق بعد';

  @override
  String get adbDefaultBlock => 'مشغّل الافتراضية';

  @override
  String get adbSystemDefault => 'افتح إعداد المشغل الافتراضي للنظام';

  @override
  String get adbAssignDefault => 'قم بتعيين CuteLauncher كمشغل افتراضي عبر ADB';

  @override
  String get adbRestoreDefault => 'قم باستعادة المشغل الافتراضي السابق عبر ADB';

  @override
  String get adbDefaultHint =>
      'استخدم ADB إذا لم تتمكن قائمة النظام من ضبط المشغل الافتراضي.';

  @override
  String get adbBuiltinHint =>
      'يتيح تعطيل المشغل المدمج للنظام فتح CuteLauncher بدلاً من ذلك. قد تتأثر قوائم وأزرار التلفزيون. قم بتمكين المشغل المدمج للتراجع عن هذا.';

  @override
  String get adbHomeBlock => 'زر الصفحة الرئيسية وبدء التشغيل';

  @override
  String get adbEnableService => 'تمكين خدمة الوصول إلى CuteLauncher عبر ADB';

  @override
  String get adbHomeOverride => 'تجاوز زر الصفحة الرئيسية';

  @override
  String get adbHomeOptional =>
      'إذا تم تعطيل المشغل المدمج، فإن تجاوز الصفحة الرئيسية والتشغيل عند بدء تشغيل التلفزيون يعد أمرًا اختياريًا.';

  @override
  String get adbEnableBuiltin => 'تمكين المشغل المدمج عبر ADB';

  @override
  String get adbDisableBuiltin => 'قم بتعطيل المشغل المدمج عبر ADB';

  @override
  String get adbNoBuiltin =>
      'لم يتم العثور على قاذفات Google TV / Android TV مدمجة.';

  @override
  String get adbChanged =>
      'تغيرت الدولة. تحقق من الاتصال وأكد الإجراء مرة أخرى.';

  @override
  String get adbEffectHome =>
      'سوف يصبح CuteLauncher هو المشغل الافتراضي للنظام. سيتم حفظ المشغل الحالي لاستعادته.';

  @override
  String get adbEffectRestore =>
      'سيتم تمكين المشغل السابق وجعله افتراضيًا. إذا لم يكن متاحًا أو لم يتم حفظه، فسيتم تحديد أول مشغل آخر متاح. هذا لا يؤدي إلى تعطيل زر الصفحة الرئيسية.';

  @override
  String get adbEffectDisable =>
      'سيتم تعطيل تطبيق Launcher المدمج لمستخدم التلفزيون. قد تتوقف قوائم وأزرار التلفزيون عن العمل. لم يتم إلغاء تثبيت التطبيق.';

  @override
  String get adbRecoveryHomeDisable =>
      'سيتم أيضًا تعطيل معالج إعداد Google TV بالكامل، بما في ذلك شاشة الاسترداد الرئيسية، بحيث يصبح CuteLauncher هو المشغل الافتراضي. لن تكون ميزات معالج الإعداد متاحة حتى تتم عملية الاستعادة. سيتم حفظ الحالات الأصلية لكلتا الحزمتين لاستعادتهما.';

  @override
  String get adbRecoveryHomeRestore =>
      'سيعود معالج الإعداد Google TV أيضًا إلى حالته المحفوظة.';

  @override
  String get adbDisableHomeUnavailable =>
      'شاشة رئيسية أخرى لها أولوية أعلى. لا يمكن تعطيله بأمان بواسطة هذا المشغل.';

  @override
  String get adbEffectEnable =>
      'ستتم استعادة المشغل المدمج إلى حالته المحفوظة، أو سيتم تمكينه إذا لم يتم حفظ أي حالة. قد يقوم النظام بتحديده كمشغل افتراضي مرة أخرى.';

  @override
  String get adbEffectAccessibility =>
      'سيتم تمكين خدمة الوصول CuteLauncher. يمكنه استقبال الأحداث المنزلية؛ يتم التحكم في الاعتراض بواسطة مفتاح منفصل. يتم الحفاظ على الخدمات الأخرى.';

  @override
  String get adbEffectAccessibilityRestore =>
      'ستعود خدمة CuteLauncher إلى حالتها قبل منح الوصول إلى ADB. يتم الحفاظ على خدمات إمكانية الوصول الأخرى.';

  @override
  String get adbEffectOverlay =>
      'سيتم السماح لـ CuteLauncher بعرض النوافذ فوق التطبيقات الأخرى، بما في ذلك الفلتر الليلي.';

  @override
  String get adbEffectNotifications =>
      'سوف يتلقى CuteLauncher إمكانية الوصول إلى الإشعارات من خلال خدمة المستمع الخاصة به.';

  @override
  String get adbEffectWatchNext =>
      'سيحصل CuteLauncher على حق الوصول إلى متابعة مشاهدة البيانات.';

  @override
  String get adbEffectUsage =>
      'سيتلقى CuteLauncher إمكانية الوصول إلى إحصائيات الاستخدام لحركة المرور واكتشاف التطبيق الأمامي.';

  @override
  String get adbEffectWriteSettings =>
      'سيتم السماح لـ CuteLauncher بتغيير إعدادات سطوع النظام.';

  @override
  String get adbNoAvailableLauncher =>
      'لم يتم العثور على قاذفات مثبتة أخرى. الاستعادة غير متوفرة.';

  @override
  String get adbUnsupported =>
      'غير متوفر على هذا الجهاز: لا يوجد أمر ADB مدعوم.';

  @override
  String get adbHomeUnavailable =>
      'المشغل المدمج له أولوية النظام. التعيين المباشر من خلال ADB غير متاح؛ استخدم إمكانية الوصول أو قم بتعطيل المشغل المدمج.';

  @override
  String get nightBatteryExempt => 'CuteLauncher معفى من التحسين';

  @override
  String get nightBatteryHint =>
      'قد يساعد في تشغيل الجدول الزمني في الخلفية. لا يضمن بقاء العملية في وضع الاستعداد.';

  @override
  String get nightBatteryOptimized => 'CuteLauncher يخضع للتحسين';

  @override
  String get nightBatteryTitle => 'تحسين البطارية';

  @override
  String get nightBatteryUnavailable =>
      'إعدادات النظام غير متوفرة في هذه البرامج الثابتة أو تم رفض الوصول إليها.';

  @override
  String get nightBatteryUnknown => 'حالة الإعفاء غير معروفة';

  @override
  String get nightBatteryOpenApps => 'افتح إعدادات التطبيقات';

  @override
  String get nightBatteryGuide =>
      '1. في إعدادات التطبيقات، افتح الوصول الخاص للتطبيقات.\n2. حدد تحسين البطارية (أحيانًا توفير الطاقة).\n3. ابحث عن CuteLauncher؛ حدد جميع التطبيقات إذا لزم الأمر.\n4. قم بتعطيل التحسين أو حدد غير مقيد.\nتعتمد أسماء القائمة ومدى توفرها على البرامج الثابتة للتلفزيون.';

  @override
  String get updateNotifications => 'إظهار إشعارات التحديث';

  @override
  String get diagnosticsSave => 'حفظ التقرير إلى ملف';

  @override
  String get diagnosticsSaved => 'تم حفظ التقرير';

  @override
  String get diagnosticsSaveFailed =>
      'لا يمكن حفظ التقرير. تحقق من مدير الملفات والمجلد الوجهة.';

  @override
  String get memoryCacheSize => 'حجم ذاكرة التخزين المؤقت للصورة';

  @override
  String get memoryProcess => 'ذاكرة التطبيق';

  @override
  String get memoryImages => 'مخابئ الصور';

  @override
  String get diagnosticsExportOpened =>
      'اختر مجلدًا في مدير الملفات واحفظ التقرير.';

  @override
  String get adbDisableService =>
      'قم بتعطيل خدمة الوصول إلى CuteLauncher عبر ADB';

  @override
  String get adbDefaultSettings => 'إعدادات المشغل الافتراضية';

  @override
  String get adbHomeSettings => 'إعدادات زر الصفحة الرئيسية';

  @override
  String get adbAccessibilitySettings => 'افتح إعدادات إمكانية الوصول';

  @override
  String get adbAccessibilityGuide =>
      'حدد CuteLauncher في قائمة النظام وقم بتمكين الخدمة الخاصة به. ارجع هنا لتكوين اعتراض الصفحة الرئيسية. لتعطيلها، قم بإيقاف تشغيل خدمة CuteLauncher في نفس القائمة.';

  @override
  String get adbEffectAccessibilityDisable =>
      'سيتم تعطيل خدمة CuteLauncher. سوف يتوقف اعتراض المنزل. يتم الحفاظ على خدمات إمكانية الوصول الأخرى.';

  @override
  String get backupAutoEnabled => 'النسخ الاحتياطي التلقائي';

  @override
  String get backupClientId => 'معرف العميل';

  @override
  String get backupClientSecret => 'سر العميل';

  @override
  String get backupCloudImportConfirm =>
      'سيتم استبدال جميع الإعدادات والفئات والصور المحلية بالبيانات السحابية. يكمل؟';

  @override
  String get backupConfigured => 'تم تكوينه';

  @override
  String get backupConnection => 'إعدادات الاتصال';

  @override
  String get backupCreated => 'تم إنشاؤها';

  @override
  String get backupDaily => 'يوميا';

  @override
  String get backupDriveHelp =>
      'حدد اتصال وقم بتأكيد الرمز الموجود على هاتفك. تكون النسخ الاحتياطية مرئية في المجلد CuteLauncher الموجود في Google Drive، حيث يمكنك تنزيلها أو حذفها. احتفظ بأسماء الملفات دون تغيير للاستعادة داخل التطبيق. أعد الاتصال بعد الترقية من النسخ الاحتياطية المخفية؛ لا يتم ترحيل النسخ الاحتياطية القديمة تلقائيًا.';

  @override
  String get backupFrequency => 'تردد النسخ الاحتياطي';

  @override
  String get backupHourly => 'كل ساعة';

  @override
  String get backupLocal => 'نسخ محلية';

  @override
  String get backupMinutes => 'دقيقة';

  @override
  String get backupMode => 'الوضع';

  @override
  String get backupNever => 'لا يوجد نسخة احتياطية حتى الآن';

  @override
  String get backupNotConfigured => 'لم يتم تكوينه';

  @override
  String get backupOptions => 'خيارات النسخ الاحتياطي';

  @override
  String get backupSaveMode => 'النسخ الاحتياطي';

  @override
  String get backupScope => 'النسخ الاحتياطي عبر أجهزة التلفاز';

  @override
  String get backupSyncScope => 'التزامن عبر أجهزة التلفاز';

  @override
  String get backupSeparate => 'منفصلة لكل تلفزيون';

  @override
  String get backupShared => 'نفس الإعدادات لجميع أجهزة التلفاز';

  @override
  String get backupStorage => 'التخزين';

  @override
  String get backupSyncHelp =>
      'تنزيل البيانات وتحميل التغييرات. التغيير الأخير يفوز بالصراعات. يجب أن تكون ساعات التلفاز صحيحة. يتم تشغيل المزامنة أثناء فتح المشغل.';

  @override
  String get backupSyncLimit => 'لا تحقق أكثر من ذلك';

  @override
  String get backupSyncMode => 'التزامن';

  @override
  String get backupSyncOptions => 'خيارات المزامنة';

  @override
  String get backupTime => 'وقت النسخ الاحتياطي';

  @override
  String get backupWeekday => 'يوم من الأسبوع';

  @override
  String get backupWeekly => 'أسبوعيا';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'يتم حذف النسخ المحلية مع التطبيق أو بياناته. احتفظ بنسخة خارج التلفزيون أيضًا.';

  @override
  String get panelObjectOrder => 'ترتيب العناصر';

  @override
  String get panelInformationGroup => 'معلومات';

  @override
  String get panelOrderHint =>
      '◄ / ► لاختيار النقل أو إنهائه؛ ▲ / ▼ لتغيير الترتيب والنقل بين الجانبين عند حدود المجموعات؛ OK / Back للإنهاء.';

  @override
  String get panelTextBackgroundTransparency => 'شفافية خلفية النص والزر';

  @override
  String get weatherCityHint =>
      'أدخل اسم المدينة باللغة الإنجليزية، على سبيل المثال موسكو.';

  @override
  String get weatherCityNotFound =>
      'لم يتم العثور على المدينة. التحقق من اسم المدينة باللغة الإنجليزية.';

  @override
  String get weatherLocationAutomatic => 'احصل تلقائيا';

  @override
  String get weatherLocationAutomaticHint =>
      'الحصول على إحداثيات الجهاز. مطلوب إذن الموقع.';

  @override
  String get weatherLocationManual => 'أدخل يدويا';

  @override
  String get weatherLocationPermissionDenied =>
      'اسمح بالوصول إلى الموقع في إعدادات Android وحاول مرة أخرى.';

  @override
  String get weatherLocationUnavailable =>
      'تعذر الحصول على الإحداثيات. تحقق من إعدادات موقع Android أو أدخل المدينة يدويًا.';

  @override
  String get nightFilterSettings => 'إعدادات التصفية';

  @override
  String get nightScheduleMenu => 'الجدول الزمني';

  @override
  String get nightScheduleInactive => 'الجدول الزمني معطل';

  @override
  String get nightLocation => 'الموقع';

  @override
  String get nightLocationAutomatic => 'احصل تلقائيا';

  @override
  String get nightLocationManual => 'أدخل يدويا';

  @override
  String get nightLocationFailed =>
      'الموقع غير متاح. تحقق من إعدادات الأذونات وموقع النظام.';

  @override
  String get nightCityEnglish => 'أدخل اسم المدينة باللغة الإنجليزية';

  @override
  String get nightOverlayBrief => 'السماح للمرشح بالظهور فوق التطبيقات الأخرى.';

  @override
  String get weatherGetLocation => 'احصل على الموقع';

  @override
  String get backupLastCreated => 'تم إنشاء آخر نسخة احتياطية:';

  @override
  String get backupManagement => 'إدارة النسخ الاحتياطية';

  @override
  String get backupCopyList => 'قائمة النسخ الاحتياطي';

  @override
  String get backupRefreshCopyList => 'تحديث قائمة النسخ الاحتياطي';

  @override
  String get backupCreateNow => 'قم بإنشاء نسخة احتياطية جديدة الآن';

  @override
  String get backupFolderPath => 'مجلد النسخ الاحتياطي';

  @override
  String get backupPrivateFolder => 'مجلد التطبيق الخاص';

  @override
  String get backupRestoreCopy => 'استعادة هذه النسخة الاحتياطية';

  @override
  String get backupDeleteConfirm => 'هل تريد حذف النسخة الاحتياطية المحددة؟';

  @override
  String get blockedAppsGroup => 'التطبيقات المحظورة';

  @override
  String get notificationSettingsButton => 'إعدادات الإخطار';

  @override
  String get hidePersistentNotificationsHint =>
      'إخفاء الإشعارات المستمرة في القائمة وعبر التطبيقات الأخرى.';

  @override
  String get nightTransitionTime => 'وقت الانتقال';

  @override
  String get brightnessSolar => 'استخدم جدول الوضع الليلي';

  @override
  String get brightnessAfterSunrise => 'بعد شروق الشمس';

  @override
  String get brightnessAfterSunset => 'بعد غروب الشمس';

  @override
  String get brightnessTransitionTime => 'وقت انتقال السطوع';

  @override
  String get brightnessSolarUnavailable =>
      'الجدول الزمني للوضع الليلي غير متاح. التحقق من أوقاته ومكانه.';

  @override
  String get persistentNotificationCannotDelete =>
      'لا يمكن حذف هذا الإشعار المستمر. يمكنك فقط منعه.';

  @override
  String get diagnosticsCreateFailed =>
      'تعذر إنشاء التقرير التشخيصي. حاول ثانية.';

  @override
  String get backupListFailed =>
      'تعذر تحميل قائمة النسخ الاحتياطي. تحقق من الوصول إلى وحدة التخزين المحددة.';

  @override
  String get updateInstallerFailed =>
      'لا يمكن فتح مثبت التحديث. حاول مرة أخرى وتأكد من توفر برنامج التثبيت Android.';

  @override
  String get backupFolderFailed =>
      'لا يمكن تحديد أو حفظ مجلد النسخ الاحتياطي. اختر مجلدًا يمكن الوصول إليه وحاول مرة أخرى.';

  @override
  String get updateDownloadFailed =>
      'تعذر تنزيل التحديث. تحقق من اتصالك بالإنترنت والتخزين المتاح.';

  @override
  String get backupDeleteFailed =>
      'لا يمكن حذف النسخة الاحتياطية. تحقق من أذونات الحذف وحاول مرة أخرى.';

  @override
  String get updateCheckFailed =>
      'لا يمكن التحقق من وجود تحديثات. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';

  @override
  String get backupCreateFailed =>
      'تعذر إنشاء النسخة الاحتياطية. تحقق من الوصول إلى مساحة التخزين والمساحة المتاحة.';

  @override
  String get wallpaperChangeFailed =>
      'لا يمكن تغيير خلفية الشاشة. تحقق من الوصول إلى الملف وحاول مرة أخرى.';

  @override
  String get backupDownloadsFolder => 'التنزيلات / CuteLauncher';

  @override
  String get backupChooseFolder => 'اختر مجلدًا في مدير الملفات';

  @override
  String get backupFolderPickerUnavailable =>
      'لا يتوفر منتقي المجلدات على هذا التلفزيون. اختر التنزيلات / CuteLauncher أو مجلد التطبيق الداخلي.';

  @override
  String get driveConfigurationError =>
      'بيانات اعتماد Google Drive مفقودة أو غير صالحة. أدخل معرف العميل وسر العميل الخاص بعميل التلفزيون OAuth.';

  @override
  String get driveCodeExpired =>
      'انتهت مهلة تسجيل الدخول Google Drive. حدد التحقق من الحساب وحفظه للحصول على رمز جديد.';

  @override
  String get brightnessAfterNightStart => 'ليلا';

  @override
  String get brightnessAfterNightEnd => 'النهار';

  @override
  String get backupSyncSettings => 'الإعدادات للمزامنة';

  @override
  String get backupSyncHomeGroup => 'الشاشة الرئيسية والأقسام والتطبيقات';

  @override
  String get backupSyncAppearanceGroup => 'المظهر والخلفيات واللافتات';

  @override
  String get backupSyncDisplayGroup => 'الوضع الليلي والسطوع وشاشة التوقف';

  @override
  String get backupSyncControlsGroup => 'الضوابط مشغّل والتلفزيون';

  @override
  String get backupSyncGeneralGroup => 'اللغة والتحديثات والإعدادات الأخرى';

  @override
  String get backupSyncGroupsHelp =>
      'تبقى الكتل المعطلة محلية على هذا التلفزيون. تتم مزامنة اختيار الكتلة بين الأجهزة.';

  @override
  String get backupSyncGroupsFailed =>
      'لا يمكن حفظ تحديد الإعدادات للمزامنة. حاول ثانية.';

  @override
  String get tileLayoutMode => 'تخطيط البلاط';

  @override
  String get tileLayoutAuto => 'أوتوماتيكي حسب حجم البلاط';

  @override
  String get tileLayoutColumns => 'عدد الأعمدة الثابتة';

  @override
  String get tileLayoutRows => 'عدد الصفوف الثابتة';

  @override
  String get tileRowCount => 'عدد الصفوف';

  @override
  String get useGlobalTileSettings => 'استخدم الإعدادات العالمية';

  @override
  String get centerSelection => 'موقف الاختيار';

  @override
  String get selectionBottom => 'أسفل';

  @override
  String get selectionLower => 'الوسط السفلي';

  @override
  String get selectionCenter => 'مركز';

  @override
  String get selectionUpper => 'العلوي الأوسط';

  @override
  String get selectionTop => 'أعلى';

  @override
  String get settingsStyle => 'نمط الإعدادات';

  @override
  String get tileFocusEnlargement => 'توسيع التركيز';

  @override
  String get tileFocusShadowStrength => 'قوة الظل';

  @override
  String get tileFocusLift => 'ارفع';

  @override
  String get tileFocusLiftHeight => 'ارتفاع الرفع';

  @override
  String get tileFocusBorderColor => 'التركيز على لون الحدود';

  @override
  String get tileFocusAccentColor => 'لون مميز';

  @override
  String get tileFocusDynamicColor => 'الألوان الديناميكية';

  @override
  String get tileSizeFromColumns =>
      'يتم تحديد حجم البلاط من خلال عدد الأعمدة وعرض القسم.';

  @override
  String get resetSectionToGlobal => 'إعادة ضبط الإعدادات على القيم المشتركة';

  @override
  String get resetSectionToGlobalHint =>
      'هل تريد استعادة عناوين الأقسام المشتركة والأيقونات والخلفية وإعادة تعيين الحشو؟';

  @override
  String get resetStyleSection => 'إعادة تعيين هذا القسم';

  @override
  String get resetStyleSectionHint =>
      'هل تريد استعادة الإعدادات الافتراضية لهذا القسم فقط؟';

  @override
  String get notificationStyle => 'نمط الإخطار';

  @override
  String get styleBackgroundColor => 'لون الخلفية';

  @override
  String get styleTransparency => 'شفافية الخلفية';

  @override
  String get styleTextSize => 'حجم النص';

  @override
  String get styleTextColor => 'لون النص';

  @override
  String get noticeSize => 'حجم الإخطار';

  @override
  String get noticeStylePreview => 'معاينة الإخطار';

  @override
  String get backupSyncHomeOptions => 'السلوك والخيارات العامة';

  @override
  String get backupSyncBackground => 'الخلفية واللافتات المخصصة';

  @override
  String get backupSyncTiles => 'البلاط والقائمة وأسلوب الإخطار';

  @override
  String get backupSyncWeatherSource => 'المصدر والمكان';

  @override
  String get backupSyncWeatherDisplay => 'عرض الطقس ووحدات درجة الحرارة';

  @override
  String get backupSyncNotificationSettings => 'عرض الإخطارات والمرشحات';

  @override
  String get backupSyncOther => 'إعدادات أخرى';

  @override
  String get tileFocusBorderStyle => 'نمط الحدود';

  @override
  String get tileFocusOutline => 'الخطوط العريضة';

  @override
  String get tileFocusGlow => 'توهج';

  @override
  String get tileFocusNoBorder => 'لا الحدود';

  @override
  String get tileShowFocusShadow => 'إظهار الظل';

  @override
  String get homeLayoutRow => 'صف أفقي';

  @override
  String get homeLayoutRows => 'صفوف متعددة';

  @override
  String get homeLayoutGrid => 'الشبكة';

  @override
  String get homeCardCount => 'بطاقات مرئية عبر';

  @override
  String get homeAuto => 'تلقائي';

  @override
  String get homeFree => 'التمرير الحر';

  @override
  String get homeAnchored => 'القسم الراسي';

  @override
  String get homeScrollMode => 'التمرير القسم';

  @override
  String get homeSectionPosition => 'موقف القسم النشط';

  @override
  String get homeLabelMode => 'تسميات التطبيق';

  @override
  String get homeLabelNone => 'لا تسميات';

  @override
  String get homeLabelSelected => 'التطبيق المختار فقط';

  @override
  String get homeLabelAll => 'جميع التطبيقات';

  @override
  String get homeInherited => 'القيمة الموروثة';

  @override
  String get homeOwnReset => 'قيمة مخصصة · استخدم العالمية';

  @override
  String get homeParameters => 'المعلمات';

  @override
  String get homeSectionStyle => 'مظهر القسم';

  @override
  String get homeSectionGap => 'المسافة بين الأقسام';

  @override
  String get homeSectionIcons => 'ايقونات القسم';

  @override
  String get homeInactiveOpacity => 'عتامة القسم غير النشط';

  @override
  String get homeResetSection => 'استعادة مظهر القسم الموروث';

  @override
  String get homeCalculatedSize => 'يتم حساب الحجم من عدد البطاقات';

  @override
  String homeGapLimited(int gap) {
    return 'يقتصر التباعد على $gap للحفاظ على عدد البطاقات المحدد.';
  }

  @override
  String get homeResetLayout => 'إعادة تعيين تخطيط القسم';

  @override
  String homeVisibleRows(int count) {
    return 'صفوف مرئية بالكامل: $count';
  }

  @override
  String get homeStylePartial =>
      'ينطبق فقط على الأقسام التي ترث هذه القيمة وتدعمها في تخطيطها الحالي.';

  @override
  String get homeStyleUnavailable =>
      'غير متوفر في إعدادات القسم الحالي. تحقق من التخطيط والتجاوزات المحلية.';

  @override
  String get homeStyleNeedsRows => 'متاح لصفوف متعددة أو شبكة.';

  @override
  String get homeStyleNeedsLabels => 'تمكين التسميات لتغيير حجمها ولونها.';

  @override
  String get homeStyleNeedsAllLabels =>
      'ينطبق الموضع فقط على التصنيفات الموجودة على جميع البطاقات. يبقى العنوان المحدد أسفل القسم.';

  @override
  String get homeStyleNeedsScale => 'حدد تأثير التركيز التوسيع.';

  @override
  String get homeStyleNeedsLift => 'حدد تأثير تركيز الرفع.';

  @override
  String get homeStyleNeedsBorder =>
      'قم بتمكين المخطط التفصيلي أو التوهج أولاً.';

  @override
  String get homeStyleNeedsTitle =>
      'تمكين عنوان القسم لإظهار الأيقونة الخاصة به.';

  @override
  String get homeStyleEconomy =>
      'تم تعطيله عن طريق توفير الذاكرة. يتم الاحتفاظ بالقيمة المحفوظة.';

  @override
  String get homeStyleOpaque => 'قم بتقليل عتامة خلفية البلاط لرؤية التمويه.';

  @override
  String get homeStyleOverridden =>
      'تستخدم الأقسام المرئية قيمها الخاصة. اختر \"استخدام العمومي\" في أحد الأقسام لتطبيق هذا الإعداد.';

  @override
  String get homeStyleIconHint =>
      'يؤثر حجم الرمز على البطاقات التي تحتوي على رمز تطبيق. تملأ لافتات التلفزيون البطاقة بشكل مستقل.';

  @override
  String get homeStyleShadowHint =>
      'يحد حفظ الذاكرة من ظل البطاقات غير النشطة إلى 4. ويتم تكوين ظل التركيز بشكل منفصل.';

  @override
  String get homeStyleTransparent =>
      'لون الخلفية غير مرئي عند مستوى العتامة الصفري. زيادة عتامة خلفية البلاط.';

  @override
  String get homeStyleSingleColumn =>
      'لا تحتوي الشبكة ذات العمود الواحد على فجوات أفقية.';

  @override
  String get homeStyleAutoOnly =>
      'يتغير الحجم فقط في الأقسام ذات عدد البطاقات التلقائية التي ترث الحجم العالمي.';

  @override
  String get sleepTimerThirtySeconds => '30 ثانية (اختبار)';

  @override
  String get sleepTimer => 'توقيت النوم';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة',
      many: '$hours ساعة',
      few: '$hours ساعات',
      two: 'ساعتان',
      one: 'ساعة واحدة',
      zero: '0 ساعة',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1.5 ساعة';

  @override
  String get sleepTimerAllowExact => 'السماح بالتوقيت الدقيق';

  @override
  String get sleepTimerExactRequired =>
      'اسمح بالمؤقتات الدقيقة في إعدادات Android، ثم حدد المدة مرة أخرى.';

  @override
  String get sleepTimerAccessRequired =>
      'قم بتمكين إمكانية الوصول إلى CuteLauncher أو قم بتوصيل ADB المحلي في الإعدادات → أخرى → ADB.';

  @override
  String get sleepTimerFailed =>
      'تعذر ضبط مؤقت النوم أو إكماله. تحقق من إمكانية الوصول وADB المحلي.';

  @override
  String get nightIgnoreHdmiInputs => 'تجاهل مدخلات HDMI';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'قم بإيقاف الفلتر الليلي مؤقتًا أثناء مشاهدة HDMI. مطلوب الوصول إلى الاستخدام؛ يعتمد اكتشاف الإدخال على البرامج الثابتة للتلفزيون.';

  @override
  String get inputsSettings => 'إعدادات الإدخال';

  @override
  String get inputsUseCecNames => 'استخدم أسماء الأجهزة من CEC';

  @override
  String get inputsNamesHint =>
      'أولوية الاسم: اسمك في CuteLauncher → CEC (في حالة التمكين) → الاسم من إعدادات Android → اسم الإدخال القياسي.';

  @override
  String get inputNameHint => 'اتركه فارغًا للحصول على اسم تلقائي';

  @override
  String get inputsSaveFailed => 'لا يمكن حفظ إعدادات الإدخال';

  @override
  String get inputIcon => 'رمز الإدخال';

  @override
  String get inputIconTv => 'تلفزيون';

  @override
  String get inputIconGame => 'وحدة تحكم اللعبة';

  @override
  String get inputIconComputer => 'الكمبيوتر';

  @override
  String get inputIconReceiver => 'المتلقي';

  @override
  String get inputIconDisc => 'مشغل الأقراص';

  @override
  String get inputIconStream => 'جهاز التدفق';

  @override
  String get nightInputExclusions => 'استثناءات الإدخال';

  @override
  String get nightSelectInputs => 'حدد المدخلات لتجاهلها';

  @override
  String get nightNoInputsSelected =>
      'لم يتم تحديد أي مدخلات. سيتم تطبيق الفلتر على كل إدخال.';

  @override
  String get nightPictureExclusions => 'استثناءات وضع الصورة';

  @override
  String get nightPictureExclusionsHint =>
      'حدد الأوضاع التي توقف التعتيم مؤقتًا، والتراكب الدافئ ومرشح TCL المرتبط. يتم الحفاظ على الجدول الزمني. تم التحقق من الاكتشاف على TCL؛ الوصول إلى الاستخدام غير مطلوب.';

  @override
  String get nightPictureUnavailable =>
      'وضع الصورة الحالي غير متوفر في هذه البرامج الثابتة. يتم حفظ اختيارك. تنطبق الاستثناءات فقط عند نجاح الكشف.';

  @override
  String get nightPictureCurrent => 'الوضع الحالي';

  @override
  String get nightPictureRefresh => 'تحديث الوضع الحالي';

  @override
  String get nightPictureCode => 'رمز الوضع';

  @override
  String get nightPictureStandard => 'قياسي';

  @override
  String get nightPictureDynamic => 'ديناميكي';

  @override
  String get nightPictureMovie => 'فيلم';

  @override
  String get nightPictureSport => 'رياضة';

  @override
  String get nightPictureIntelligent => 'ذكي';

  @override
  String get nightPictureBright => 'ساطع (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'قياسي';

  @override
  String get systemApplications => 'تطبيقات النظام';

  @override
  String get removeFromCategory => 'إزالة من الفئة';

  @override
  String get noRemovableCategories =>
      'لم تتم إضافة هذا التطبيق يدويًا إلى أي أقسام. لا يمكن تحرير الأقسام التلقائية.';

  @override
  String get remoteButtonsTitle => 'إعادة تعيين أزرار جهاز التحكم';

  @override
  String get remoteButtonsStart => 'فحص الأزرار (120 ثانية)';

  @override
  String get remoteButtonsStop => 'إيقاف الفحص';

  @override
  String get remoteButtonsHint =>
      'يعرض الفحص الرموز والتحرير والتكرار ويحفظ تقريرًا نصيًا على التلفزيون. غادر الصفحة بعد بدء الفحص حتى لا يتحكم OK بالتسجيل.';

  @override
  String get remoteButtonsEmpty =>
      'لا توجد أحداث بعد. إذا فتح زر تطبيقًا، عُد إلى هنا لرؤية النتيجة.';

  @override
  String get remoteButtonsService => 'الخدمة متصلة';

  @override
  String get remoteButtonsRefresh => 'تحديث';

  @override
  String get remoteBindings => 'تعيينات الأزرار';

  @override
  String get remoteMappingsEnabled => 'تفعيل إعادة التعيين';

  @override
  String get remoteMappingsAdd => 'إضافة تعيين';

  @override
  String get remoteMappingKey => 'الزر';

  @override
  String get remoteMappingAction => 'الإجراء';

  @override
  String get remoteMappingLearn => 'اكتشاف زر التحكم';

  @override
  String get remoteMappingLearnHint =>
      'اضغط زرًا إضافيًا خلال 30 ثانية. أزرار التنقل وPower والبحث الصوتي ومستوى الصوت محمية.';

  @override
  String get remoteMappingsHint =>
      'تتطلب التعيينات خدمة إمكانية الوصول. تُعلّق في المحرر وأثناء التشخيص. تبقى وظائف Home وBack والأسهم وOK للتنقل.';

  @override
  String get remoteMappingsReset => 'إعادة ضبط التعيينات';

  @override
  String get remoteMappingsResetConfirm =>
      'حذف جميع التعيينات وإيقاف إعادة التعيين؟';

  @override
  String get remoteMappingInvalid =>
      'تعذر الحفظ. تحقق من الزر والهدف. تتطلب webhooks اتصال HTTPS أو HTTP على شبكة محلية.';

  @override
  String get remoteMappingBack => 'رجوع';

  @override
  String get remoteMappingProfile => 'الملف الشخصي';

  @override
  String get remoteMappingChannels => 'القنوات';

  @override
  String get remoteMappingQuickSettings => 'إعدادات TCL السريعة';

  @override
  String get remoteMappingTrigger => 'نوع الضغط';

  @override
  String get remoteMappingPress => 'ضغط قصير';

  @override
  String get remoteMappingHold => 'ضغط مطوّل';

  @override
  String get remoteMappingHoldHint =>
      'اضغط 650 مللي ثانية: إجراء واحد دون الضغط القصير. إذا عُيّن الضغط المطوّل فقط، فلن يفعل الضغط القصير شيئًا.';

  @override
  String get remotePanel => 'لوحة عائمة';

  @override
  String get remotePanelSettingsBackground => 'استخدام لون خلفية الإعدادات';

  @override
  String get remotePanelPreview => 'فتح اللوحة';

  @override
  String get settingsHelp => 'مزيد من المعلومات';

  @override
  String get settingsHelpScroll => '▲ / ▼ — تمرير النص';

  @override
  String get panelClockStyle => 'مظهر الساعة';

  @override
  String get clockPreset => 'تصميم الساعة';

  @override
  String get clockCustom => 'مخصص';

  @override
  String get clockWeight => 'سماكة الخط';

  @override
  String get clockGlow => 'توهج النص';

  @override
  String get clockAnimate => 'تحريك الأرقام';

  @override
  String get clockBackground => 'خلفية الساعة';

  @override
  String get clockRadius => 'استدارة زوايا الخلفية';

  @override
  String get dateCalendarEnabled => 'فتح التقويم عند الضغط على التاريخ';

  @override
  String get calendarTitle => 'التقويم';

  @override
  String get dateSettings => 'إعدادات التاريخ';

  @override
  String get clockSharedBackground => 'استخدام خلفية العناصر الأخرى';

  @override
  String get clockDefaultBackground => 'الخلفية الافتراضية';

  @override
  String get remotePanelInheritAppearance => 'استخدام مظهر اللوحة العلوية';

  @override
  String get remotePanelDisabledInLauncher =>
      'اللوحة العائمة معطلة أثناء ظهور CuteLauncher على الشاشة.';

  @override
  String get remoteAccessSettings => 'إعدادات الوصول';

  @override
  String get remoteButtonsTest => 'اختبار الأزرار';

  @override
  String get remoteMappingConflict =>
      'تم تعيين هذا الزر ونوع الضغط بالفعل. اختر زرًا أو نوع ضغط آخر.';

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
