// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

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
  String get adbWifiOwnedTitle => 'Wi-Fi kurulum sihirbazına ait';

  @override
  String get adbWifiOwned =>
      'Değişiklik yapılmadı: kayıtlı bir Wi-Fi ağı Google kurulum sihirbazı tarafından oluşturulmuş. Sihirbazı kapatmak ağı silebilir ve TV’nin bağlantısını kesebilir.\n\n1. Wi-Fi parolasını bildiğinizden emin olun.\n2. Android ağ ayarlarını açın, ağı seçin ve Ağı unut seçeneğini kullanın.\n3. Normal Android ağ ayarlarından yeniden bağlanın.\n4. CuteLauncher’a dönün, ADB’yi kontrol edin ve yerleşik başlatıcıyı kapatmayı yeniden deneyin.\n\nMesaj tekrarlanırsa yerleşik başlatıcıyı açık bırakın: yazılım ağı tekrar sihirbaza atayabilir.';

  @override
  String get adbWifiUnknown =>
      'Not changed: the owners of saved Wi-Fi networks could not be verified. Disabling the setup wizard is blocked to protect your connection. Check ADB and try again; some firmware does not provide this information.';

  @override
  String get backgroundSource => 'Arka plan kaynağı';

  @override
  String get noAvailableCategories =>
      'Bu uygulamanın eklenebileceği bölüm yok.';

  @override
  String get redditWallpaperTheme => 'Duvar kağıdı teması';

  @override
  String get redditThemeAll => 'Karışık';

  @override
  String get redditThemeNature => 'Doğa';

  @override
  String get redditThemeSpace => 'Uzay';

  @override
  String get redditThemeCity => 'Şehirler';

  @override
  String get redditThemeMinimal => 'Minimalizm';

  @override
  String get redditWallpaperResolution => 'Minimum çözünürlük';

  @override
  String get redditWallpaperHint =>
      'Her başarılı yenileme, seçilen Reddit topluluğundan farklı bir yatay görüntü indirir. Çözünürlük minimum orijinal boyuttur; resimler büyütülmüyor. Yenileme, başlatıcı açıkken çalışır ve geri döndüğünüzde devam eder. Yetişkinlere uygun içerik, videolar ve galeriler atlanır. Reddit erişimi engellerse veya eşleşen görüntü bulunamazsa önceki duvar kağıdı kalır.';

  @override
  String get dialogCommandDetails => 'ADB komutlarını göster';

  @override
  String get dialogAssign => 'Ata';

  @override
  String get dialogApply => 'Uygula';

  @override
  String get settingsValueNotSet => 'Ayarlanmadı';

  @override
  String get settingsMenuPosition => 'Ayarlar menüsü konumu';

  @override
  String get settingsMenuLeft => 'Sol';

  @override
  String get settingsMenuRight => 'Sağ';

  @override
  String get actionCompleted => 'İşlem tamamlandı';

  @override
  String get showRepositoryQrCode => 'QR kodunu göster';

  @override
  String get resetSections => 'Bölüm ayarlarını sıfırla';

  @override
  String get resetSectionsConfirmation =>
      'Varsayılan bölümler geri yüklensin mi? Özel bölümler, ara parçalar ve Sık Kullanılanlar içerikleri kaldırılacaktır.';

  @override
  String get cardFocusMode => 'Eve dönüşe odaklanın';

  @override
  String get cardFocusRemember => 'Seçilen kartı koru';

  @override
  String get cardFocusFirst => 'İlk kart';

  @override
  String get cardFocusSettings => 'Ayarlar düğmesi';

  @override
  String get aboutFlauncher => 'CuteLauncher Hakkında';

  @override
  String get addCategory => 'Kategori ekle';

  @override
  String get addSection => 'Bölüm ekle';

  @override
  String get alphabetical => 'Alfabetik';

  @override
  String get appCardHighlightAnimation => 'Uygulama kartı vurgulama animasyonu';

  @override
  String get appInfo => 'Uygulama bilgisi';

  @override
  String get appKeyClick => 'Tuşa basıldığında tıklama sesi';

  @override
  String get applications => 'Uygulamalar';

  @override
  String get autoHideAppBar => 'Durum çubuğunu otomatik gizle';

  @override
  String get backButtonAction => 'Geri düğmesi eylemi';

  @override
  String get category => 'Kategori';

  @override
  String get categories => 'Kategoriler';

  @override
  String get columnCount => 'Sütun sayısı';

  @override
  String get date => 'Tarih';

  @override
  String get dateAndTimeFormat => 'Tarih ve saat biçimi';

  @override
  String get delete => 'Sil';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'Hiçbir şey yapma';

  @override
  String get dialogOptionBackButtonActionShowScreensaver =>
      'Ekran koruyucuyu göster';

  @override
  String get dialogOptionBackButtonActionShowClock => 'Saati göster';

  @override
  String get dialogTextNoFileExplorer =>
      'Resim seçmek için lütfen bir dosya gezgini yükleyin.';

  @override
  String get dialogTitleBackButtonAction => 'Geri düğmesi eylemini seçin';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (Kategori)';
  }

  @override
  String formattedDate(String dateString) {
    return 'Biçimlendirilmiş tarih: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'Biçimlendirilmiş saat: $timeString';
  }

  @override
  String get gradient => 'Gradyan';

  @override
  String get favoriteApps => 'Favori Uygulamalar';

  @override
  String get grid => 'Izgara';

  @override
  String get height => 'Yükseklik';

  @override
  String get hide => 'Gizle';

  @override
  String get hiddenApplications => 'Gizli Uygulamalar';

  @override
  String get launcherSections => 'Bölümler';

  @override
  String get layout => 'Düzen';

  @override
  String get loading => 'Yükleniyor';

  @override
  String get manual => 'Manuel';

  @override
  String get modifySection => 'Bölümü değiştir';

  @override
  String get mustNotBeEmpty => 'Boş bırakılamaz';

  @override
  String get name => 'Ad';

  @override
  String get newSection => 'Yeni bölüm';

  @override
  String get noDateFormatSpecified => 'Tarih biçimi belirtilmedi';

  @override
  String get noTimeFormatSpecified => 'Saat biçimi belirtilmedi';

  @override
  String get nonTvApplications => 'TV Dışı Uygulamalar';

  @override
  String get open => 'Aç';

  @override
  String get orSelectFormatSpecifiers => 'Veya biçim belirteçlerini seçin';

  @override
  String get openImage => 'Dosya seç';

  @override
  String get picture => 'Yerel resim veya video';

  @override
  String removeFrom(String name) {
    return '$name öğesinden kaldır';
  }

  @override
  String get renameCategory => 'Kategoriyi yeniden adlandır';

  @override
  String get reorder => 'Yeniden sırala';

  @override
  String get row => 'Satır';

  @override
  String get rowHeight => 'Satır yüksekliği';

  @override
  String get save => 'Kaydet';

  @override
  String get spacer => 'Ayırıcı';

  @override
  String get spacerMaxHeightRequirement =>
      '0\'dan büyük ve 500\'den küçük veya eşit olmalıdır';

  @override
  String get statusBar => 'Durum çubuğu';

  @override
  String get settings => 'Ayarlar';

  @override
  String get show => 'Göster';

  @override
  String get showCategoryTitles => 'Kategori başlıklarını göster';

  @override
  String get themes => 'Temalar';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'Ana ekranda vurgu anahattını gizle';

  @override
  String get appSelectorTransitionAnimation =>
      'Uygulama seçici geçiş animasyonu';

  @override
  String get sort => 'Sırala';

  @override
  String get systemSettings => 'Sistem ayarları';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => 'Bu kategori boş.';

  @override
  String get time => 'Saat';

  @override
  String get titleStatusBarSettingsPage =>
      'Durum çubuğunda neyin görüntüleneceğini seçin';

  @override
  String get tvApplications => 'TV Uygulamaları';

  @override
  String get type => 'Tür';

  @override
  String get typeInTheDateFormat => 'Tarih biçimini yazın';

  @override
  String get typeInTheHourFormat => 'Saat biçimini yazın';

  @override
  String get uninstall => 'Kaldır';

  @override
  String get wallpaper => 'Duvar kağıdı';

  @override
  String get withEllipsisAddTo => 'Şuraya ekle...';

  @override
  String get timeBasedWallpaper => 'Gündüz/Gece resmi';

  @override
  String get pickDayWallpaper => 'Gündüz resmini seç';

  @override
  String get pickNightWallpaper => 'Gece resmini seç';

  @override
  String get accessibility => 'Erişilebilirlik';

  @override
  String get defaultLauncherIsDefault => 'CuteLauncher varsayılan başlatıcıdır';

  @override
  String get defaultLauncherNotDefault =>
      'CuteLauncher varsayılan başlatıcı değildir';

  @override
  String get setAsDefaultLauncher => 'Varsayılan başlatıcı olarak ayarla';

  @override
  String get defaultLauncherDescription =>
      'Varsayılan başlatıcı olarak ayarlandığında, Ana Sayfa düğmesi her zaman CuteLauncher\'a döner. TV de doğrudan CuteLauncher\'da başlar.';

  @override
  String get inputs => 'Girişler';

  @override
  String get inputsUnavailableHint =>
      'Bu cihaz kullanılabilir giriş sağlamıyor. Anahtar devre dışı bırakılır ve simge gizlenir. Bir TV kutusunda bu seçenek bağlı TV\'nin HDMI girişlerini kontrol etmez.';

  @override
  String get inputSources => 'Giriş Kaynakları';

  @override
  String get backupAndRestore => 'Yedekleme ve Geri Yükleme';

  @override
  String get exportBackup => 'Yedeği Dışa Aktar';

  @override
  String get importBackup => 'Yedeği İçe Aktar';

  @override
  String exportSuccess(String path) {
    return 'Yedek başarıyla $path konumuna dışa aktarıldı';
  }

  @override
  String get importSuccess => 'Yedek başarıyla içe aktarıldı';

  @override
  String get importConfirm =>
      'Yedeği içe aktarmak istediğinizden emin misiniz? Bu işlem mevcut ayarlarınızın ve düzeninizin üzerine yazacaktır.';

  @override
  String get importError =>
      'Ayarlar yedeklemeden geri yüklenemedi. Dosyayı kontrol edip tekrar deneyin.';

  @override
  String exportError(String error) {
    return 'Yedek dışa aktarılamadı: $error';
  }

  @override
  String get shareBackup => 'Yedeği Paylaş';

  @override
  String get shareBackupDescription =>
      'Yedeği yerel ağdaki diğer cihazlarla paylaş';

  @override
  String get stopSharing => 'Paylaşımı Durdur';

  @override
  String get localNetworkSharingActive => 'Yerel ağ paylaşımı etkin!';

  @override
  String get localNetworkSharingInstructions =>
      'Başka bir cihazı aynı Wi-Fi ağına bağlayın ve bir web tarayıcısında aşağıdaki URL\'yi açın:';

  @override
  String get localNetworkSharingDetails =>
      'Buradan TV ayarlarınızı/düzeninizi indirebilir veya bir yedek dosyasını bu TV\'ye geri yükleyebilirsiniz.';

  @override
  String failedToStartServer(String error) {
    return 'Paylaşım sunucusu başlatılamadı: $error';
  }

  @override
  String get notificationBell => 'Bildirim Zili';

  @override
  String get autoHideNotificationBell => 'Bildirim Zilini otomatik gizle';

  @override
  String get continueWatching => 'İzlemeye Devam Et';

  @override
  String get showContinueWatchingOnHome =>
      'Ana Ekranda İzlemeye Devam Et\'i göster';

  @override
  String get permissionDeniedContinueWatching =>
      'İzlemeye Devam Et\'i göstermek için izin gerekli';

  @override
  String get interface => 'Arayüz';

  @override
  String get system => 'Sistem';

  @override
  String get accentColor => 'Vurgu Rengi';

  @override
  String get miscellaneous => 'Çeşitli';

  @override
  String get brightnessScheduler => 'Parlaklık Zamanlayıcısı';

  @override
  String get screensaverSettings => 'Ekran Koruyucu Ayarları';

  @override
  String get screensaverClockStyle => 'Ekran Koruyucu Saat Stili';

  @override
  String get dataUsagePeriod => 'Veri Kullanım Dönemi';

  @override
  String get notificationAccess => 'Bildirim Erişimi';

  @override
  String get granted => 'Verildi';

  @override
  String get permissionRequired => 'İzin Gerekli';

  @override
  String get systemWidePopupAlert => 'Sistem Geneli Açılır Pencere Uyarısı';

  @override
  String get overlayPermissionRequired => 'Kaplama İzni Gerekli';

  @override
  String get enabled => 'Etkin';

  @override
  String get disabled => 'Devre Dışı';

  @override
  String get showAppNamesBelowIcons =>
      'Uygulama adlarını simgelerin altında göster';

  @override
  String get dataUsage => 'Veri Kullanımı';

  @override
  String get networkIndicator => 'Ağ Göstergesi';

  @override
  String get homeButtonFix => 'Ana Sayfa Düğmesi Düzeltmesi (Google TV)';

  @override
  String get startOnBoot => 'Açılışta başlat (Google TV / Fire TV)';

  @override
  String get appLanguage => 'Dil';

  @override
  String get systemDefault => 'Sistem Varsayılanı';

  @override
  String get english => 'İngilizce';

  @override
  String get spanish => 'İspanyolca';

  @override
  String get ukrainian => 'Ukraynaca';

  @override
  String get chinese => 'Çince';

  @override
  String get french => 'Fransızca';

  @override
  String get german => 'Almanca';

  @override
  String get japanese => 'Japonca';

  @override
  String get portuguese => 'Portekizce';

  @override
  String get russian => 'Rusça';

  @override
  String get italian => 'İtalyanca';

  @override
  String get hindi => 'Hintçe';

  @override
  String get korean => 'Korece';

  @override
  String get arabic => 'Arapça';

  @override
  String get turkish => 'Türkçe';

  @override
  String get hidePersistentNotifications => 'Kalıcı Bildirimleri Gizle';

  @override
  String get hidePersistentNotificationsDesc =>
      'Arka plan servisi ve sistem bildirimlerini gizle';

  @override
  String get blockedNotificationApps => 'Engellenen Uygulamalar';

  @override
  String get blockAppNotifications => 'Bildirimleri Engelle';

  @override
  String get unblockAppNotifications => 'Bildirim Engelini Kaldır';

  @override
  String get noBlockedApps => 'Engellenen uygulama yok';

  @override
  String get persistentNotification => 'Kalıcı';

  @override
  String get unblockAll => 'Tümünün Engelini Kaldır';

  @override
  String get weather => 'Hava Durumu';

  @override
  String get showWeatherWarnings => 'Hava Durumu ve Yağmur Uyarılarını Göster';

  @override
  String get temperatureUnit => 'Sıcaklık Birimi';

  @override
  String get celsius => 'Santigrat (°C)';

  @override
  String get fahrenheit => 'Fahrenhayt (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Hava durumu ve yağmur uyarılarını görmek için Breezy Weather\'ı yükleyin ve ayarlarından \'Yerel veri paylaşımı\' / \'Gadgetbridge\' özelliğini etkinleştirin.';

  @override
  String get displayAndScreensaver => 'Ekran ve Ekran Koruyucu';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get continueWatchingDescription =>
      'Son izlenen filmleri ve dizileri ana ekranda göster';

  @override
  String get continueWatchingPermissionDesc =>
      'TV uygulamalarından izleme geçmişini okumak için özel izin gereklidir:';

  @override
  String get requestPermission => 'İzin İste';

  @override
  String get dismiss => 'Kapat';

  @override
  String get openApp => 'Aç';

  @override
  String get notificationOptions => 'Bildirim Seçenekleri';

  @override
  String get noBlockedAppsDesc =>
      'Şu anda tüm uygulamaların bildirim göstermesine izin veriliyor';

  @override
  String get notificationsAllowed => 'Bildirimlere İzin Verildi';

  @override
  String get notificationsBlocked => 'Bildirimler Engellendi';

  @override
  String get dpadDismissHint => 'Sol: Kapat • Tamam: Seçenekler';

  @override
  String get watchNextDeleteError =>
      'Öğe İzlemeye Devam Et\'ten kaldırılamadı. Tekrar deneyin.';

  @override
  String get hideLauncherTile => 'CuteLauncher\'yi uygulama kılavuzunda gizle';

  @override
  String get hideAndroidSettingsTile =>
      'Uygulama kutucuklarında Android ayarlarını gizle';

  @override
  String get animateTileReordering =>
      'Parçacıkların yeniden sıralamasını canlandırın';

  @override
  String get imageInputRejected =>
      'Bu resim hasarlı veya çok büyük (maksimum 8 MiB ve 48 megapiksel). Başka bir resim seçin.';

  @override
  String get memoryTitle => 'Bellek';

  @override
  String get memoryRefresh => 'Belleği ölç';

  @override
  String get memoryMeasuring => 'Ölçme…';

  @override
  String get memoryClear => 'Görüntü önbelleklerini temizle';

  @override
  String get memorySaver => 'Bellek tasarrufu';

  @override
  String get memorySaverDescription =>
      'Bellek tasarrufu modu:\n\n• Görüntü önbelleklerini ve poster önyükleme penceresini azaltır.\n• Döşeme, panel ve duvar kağıdı arka plan bulanıklığını ve ana hatların yanıp sönmesini devre dışı bırakır.\n• Odaklanmamış döşemelerdeki gölgeleri sınırlar.\n• Uygulama arka plana geçtiğinde önbellekleri temizler.\n\nBellek tasarrufu etkinken bu efektler ayarlarda kullanılamaz. Mod devre dışı bırakıldığında kayıtlı değerleri geri döner. Resimler daha sık yeniden yüklenebilir.';

  @override
  String get memoryPss => 'İşlem paylaşımı (PSS)';

  @override
  String get memoryRss => 'Yerleşik işlem belleği (RSS)';

  @override
  String get memoryEncodedCache => 'Önbelleğe alınmış görüntü dosyaları';

  @override
  String get memoryDecodedCache => 'Önbelleğe alınmış kodu çözülmüş resimler';

  @override
  String get memoryUnavailable => 'Kullanılamıyor';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => 'Ölçülen';

  @override
  String get memoryExplanation =>
      'PSS ve RSS çakışıyor: bunları birbirine eklemeyin. Önbellek boyutları uygulama belleğinin bir parçasıdır ve etkin görsellerin tuttuğu tüm belleği açıklamaz. Önbellekleri temizlemek ayarlarınızı ve dosyalarınızı korur; gerektiğinde görüntüler tekrar yüklenir. Android daha sonra belleği geri döndürebilir. Burada RSS çekirdekten, PSS ise Android\'den geliyor; grafik belleğini farklı şekilde hesaba katabilirler.';

  @override
  String get memoryRecommendations =>
      'Daha az bellek için kaydetmeyi etkinleştirin, daha az İzlemeye devam kartı gösterin ve daha küçük duvar kağıtları veya degrade kullanın.';

  @override
  String get memoryMeasurementFailed =>
      'Proses ölçümü mevcut değil. Önbellek bilgileri hâlâ gösteriliyor.';

  @override
  String get addToCategory => 'Kategoriye Ekle';

  @override
  String get addToFavorites => 'Favorilere Ekle';

  @override
  String get removeFromFavorites => 'Favorilerden kaldır';

  @override
  String get setCustomBanner => 'Özel Banner Ayarla';

  @override
  String get clearCustomBanner => 'Özel Banner\'ı Temizle';

  @override
  String get bannerSetFailed =>
      'Banner ayarlanamadı. Resme erişimi kontrol edin ve dosyayı tekrar seçin.';

  @override
  String get bannerClearFailed => 'Özel banner kaldırılamadı. Tekrar deneyin.';

  @override
  String get grantUsagePermission => 'Kullanım İzni Ver';

  @override
  String get removeFromContinueWatching => 'İzlemeye Devam Et\'ten kaldır';

  @override
  String hideAllFromApp(String appName) {
    return '$appName\'den hepsini gizle';
  }

  @override
  String get playResume => 'Oynat / Devam Et';

  @override
  String openNamedApp(String appName) {
    return '$appName\'yi açın';
  }

  @override
  String get selectedAccent => 'Seçilen Vurgu';

  @override
  String get homeButtonFixHint =>
      'Google TV kullanıyorsanız Ana Sayfa düğmesinin bu başlatıcıyı açmasını sağlamak için Erişilebilirlik ayarları altında \"Ana Sayfa Düğmesini Düzeltme\"yi etkinleştirin.';

  @override
  String get accessibilityPermission => 'Erişilebilirlik İzni';

  @override
  String get shareFailed => 'Paylaşım Başarısız';

  @override
  String shareBackupError(String error) {
    return 'Yedekleme paylaşılamadı: $error';
  }

  @override
  String get exportComplete => 'İhracat Başarısı';

  @override
  String get exportFailed =>
      'Yedekleme kaydedilemedi. Klasör erişimini ve kullanılabilir depolama alanını kontrol edin.';

  @override
  String backupLoadError(String error) {
    return 'Yedeklemeler yüklenirken hata oluştu: $error';
  }

  @override
  String get noBackupFiles => 'Yedekleme dosyası bulunamadı.';

  @override
  String get importComplete => 'İçe Aktarma Başarısı';

  @override
  String get importFailed => 'İçe Aktarma Başarısız';

  @override
  String get importAction => 'İthalat';

  @override
  String get continueWatchingApps => 'Uygulamaları İzlemeye Devam Et';

  @override
  String get blockedContinueWatching => 'İzlemeye Devam Etme Engellendi';

  @override
  String get allAppsCanContinueWatching =>
      'Desteklenen tüm uygulamalar İzlemeye Devam Et bölümündeki öğeleri gösterebilir.';

  @override
  String get unblockApp => 'Engellemeyi kaldır';

  @override
  String get unblockAllApps => 'Tüm Uygulamaların Engelini Kaldır';

  @override
  String get appsWithContinueWatching =>
      'İzlemeye Devam Et özelliğine sahip uygulamalar';

  @override
  String get watchNextAppsHint =>
      'Şu anda ana ekranınızda Sonraki İzle öğelerini sunan uygulamalar';

  @override
  String get noWatchNextApps =>
      'Şu anda hiçbir uygulama İzlemeye Devam Et öğeleri sunmuyor.\nDesteklenen uygulamalar (SmartTube veya akış hizmetleri gibi) öğe eklediğinde burada görünürler.';

  @override
  String get allInstalledApps => 'Tüm Yüklü Uygulamalar';

  @override
  String get blockWatchNextHint =>
      'Herhangi bir uygulamanın İzlemeye Devam Et\'e öğe eklemesini engellemek için kapatın';

  @override
  String get cardSize => 'Kart Boyutu';

  @override
  String get maximumItems => 'Maksimum Öğeler';

  @override
  String get playbackProgressBar => 'Oynatma İlerleme Çubuğu';

  @override
  String get playbackPercentage => 'Oynatma Yüzdesi';

  @override
  String get episodeVideoDetails => 'Bölüm ve Video Detayları';

  @override
  String get restoreHiddenPrograms => 'Gizli Programları Geri Yükle';

  @override
  String get allHiddenProgramsRestored => 'Tüm gizli programlar geri yüklendi';

  @override
  String get watchNextAccessAdb => 'Sonraki Erişimi İzle (ADB Gerekli)';

  @override
  String get supportLtvLauncher => 'LTvLauncher\'yi destekleyin';

  @override
  String get scanToDonate =>
      'Bağış yapmak için telefonunuzun kamerasını tarayın:';

  @override
  String get openInBrowser => 'Tarayıcıda Aç';

  @override
  String get close => 'Kapat';

  @override
  String get launcherAuthor => 'CuteLauncher, Kirill Shchetinnikov tarafından';

  @override
  String get launcherCredits =>
      'Android TV başlatıcısı, LeanBitLab\'nin LTvLauncher\'sini ve Étienne Fesser\'nin FLauncher\'sini temel alır. GNU GPLv3 kapsamında lisanslanmıştır.';

  @override
  String get projectCredits => 'Proje ve Krediler';

  @override
  String get launcherRepository => 'CuteLauncher Deposu';

  @override
  String get originalProject => 'Orijinal proje: LTvLauncher';

  @override
  String get noInputsDetected => 'Hiçbir giriş algılanmadı';

  @override
  String get reorderSectionsHint =>
      '◄ / ► ile seçin ve yeniden sıralamak için ▲ / ▼ tuşlarını kullanın. Bir bölümü gizlemek veya göstermek için liste sınırını geçin.';

  @override
  String get customName => 'Özel Ad';

  @override
  String get mostUsed => 'Başlatma sıklığı';

  @override
  String get lastUsed => 'Son Kullanılan';

  @override
  String get clearAll => 'Tümünü Temizle';

  @override
  String get allCaughtUp => 'Hepsi yakalandı!';

  @override
  String get notificationAccessAdb => 'Bildirim Erişimi (ADB Gerekli)';

  @override
  String get openAppInfo => 'Uygulama Bilgilerini Aç';

  @override
  String get overlayPermission => 'Yer Paylaşımı İzni';

  @override
  String get clockMinimal => 'Asgari';

  @override
  String get clockMinimalDescription => 'İnce, zarif yazı tipi (Varsayılan)';

  @override
  String get clockBold => 'Kalın';

  @override
  String get clockBoldDescription => 'Kalın, son derece görünür yazı tipi';

  @override
  String get clockRetro => 'retro';

  @override
  String get clockRetroDescription => 'Tek aralıklı, retro terminal stili';

  @override
  String get clockElegant => 'zarif';

  @override
  String get clockElegantDescription => 'Klasik serif yazı tipi';

  @override
  String get clockNeon => 'neon';

  @override
  String get clockNeonDescription => 'Ultra ince, parlak tarz';

  @override
  String get clockPixel => 'Piksel';

  @override
  String get clockPixelDescription => 'Cesur tek aralıklı, arcade hissi';

  @override
  String get clockDigital => 'Dijital';

  @override
  String get clockDigitalDescription => 'Tek aralıklı ekranı temizle';

  @override
  String get themeDefault => 'Varsayılan';

  @override
  String get themePremium => 'prim';

  @override
  String get themeClassic => 'Klasik';

  @override
  String get themeCapsule => 'Kapsül';

  @override
  String get cancel => 'İptal';

  @override
  String get actionCancelled => 'İşlem iptal edildi';

  @override
  String get ok => 'tamam';

  @override
  String get accessibilityGuide =>
      'TV ayarlarını manuel olarak açın, ardından Erişilebilirlik → CuteLauncher Ana Sayfa Düğmesini Düzeltme seçeneğini açın ve hizmeti etkinleştirin. Bu menünün konumu ve adı TV üreticinize bağlıdır.';

  @override
  String get notificationPermissionGuide =>
      'Bu TV\'de bildirim erişim ayarları açılamadı. Uygulama Bilgisi\'nde giden bildirimlere izin verilmesi, diğer uygulamalardan gelen bildirimlere erişim izni vermez.\n\nTV\'nizi ADB aracılığıyla bağlayın ve çalıştırın:';

  @override
  String get overlayPermissionGuide =>
      'Yer paylaşımı izin ayarları otomatik olarak açılamadı.\n\nDiğer uygulamaların üzerinden açılır pencereleri etkinleştirmek için TV\'nizi ADB aracılığıyla bağlayın ve şunu çalıştırın:';

  @override
  String get watchNextPermissionGuide =>
      'Diğer uygulamalardan İzlemeye Devam Et kartlarını okumak için Android TV, READ_WRITE_WATCH_NEXT_PROGRAMS gerektirir.\n\nTV\'nizi ADB aracılığıyla bağlayın ve çalıştırın:';

  @override
  String get watchNextAccess => 'İzlemeye Devam Et erişimi';

  @override
  String itemsCount(int count) {
    return '$count öğeleri';
  }

  @override
  String displayUpToItems(int count) {
    return '$count\'ye kadar yeni öğeleri görüntüle';
  }

  @override
  String get unlimitedItems => 'Sınırsız';

  @override
  String get allAvailableItems => 'Mevcut tüm öğeleri görüntüle';

  @override
  String get defaultOption => 'Varsayılan';

  @override
  String get manage => 'Yönet';

  @override
  String blockedCount(int count) {
    return '$count engellendi';
  }

  @override
  String hiddenCount(int count) {
    return '$count gizli';
  }

  @override
  String blockedWatchNextCount(int count) {
    return 'İzlemeye Devam Etmesi Engellendi ($count)';
  }

  @override
  String get sizeExtraSmall => 'Ekstra Küçük';

  @override
  String get sizeVerySmall => 'Çok Küçük';

  @override
  String get sizeSmall => 'Küçük';

  @override
  String get sizeCompact => 'Kompakt';

  @override
  String get sizeMediumSmall => 'Orta Küçük';

  @override
  String get sizeMedium => 'Orta';

  @override
  String get sizeStandardDefault => 'Standart (Varsayılan)';

  @override
  String get sizeMediumLarge => 'Orta Büyük';

  @override
  String get sizeLarge => 'Büyük';

  @override
  String get sizeVeryLarge => 'Çok Büyük';

  @override
  String get sizeExtraLarge => 'Ekstra Büyük';

  @override
  String get sizeHuge => 'Devasa';

  @override
  String get tvApps => 'TV Uygulamaları';

  @override
  String get nonTvApps => 'TV Dışı Uygulamalar';

  @override
  String get moviesShows => 'Filmler ve Programlar';

  @override
  String get music => 'Müzik';

  @override
  String get games => 'Oyunlar';

  @override
  String get entertainment => 'Eğlence';

  @override
  String get liveTv => 'Canlı TV';

  @override
  String get sports => 'Spor';

  @override
  String get news => 'Haberler';

  @override
  String get tools => 'Araçlar';

  @override
  String get favorites => 'Favoriler';

  @override
  String get customSectionName => 'Özel...';

  @override
  String get selectSectionName => 'Bir ad seçin';

  @override
  String get weeklyUsage => 'Haftalık:';

  @override
  String get monthlyUsage => 'Aylık:';

  @override
  String get dailyUsage => 'Günlük:';

  @override
  String get appError => 'Bir şeyler ters gitti';

  @override
  String get weatherRain => 'Yağmur';

  @override
  String get weatherSnow => 'Kar';

  @override
  String get weatherStorm => 'Fırtına';

  @override
  String get weatherToday => 'bugün';

  @override
  String get weatherTomorrow => 'yarın';

  @override
  String weatherOnDay(String day) {
    return '$day\'de';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'CuteLauncher Yedekleme';

  @override
  String get noApplicationsFound => 'Hiçbir uygulama bulunamadı';

  @override
  String get invalidDateFormat => 'Geçersiz biçim';

  @override
  String get selectDateFormats => 'Aşağıdaki formatları seçin';

  @override
  String activeItemsCount(int count) {
    return '$count aktif ürün(ler)';
  }

  @override
  String get colorPurple => 'Mor';

  @override
  String get colorTeal => 'turkuaz';

  @override
  String get colorBlue => 'Mavi';

  @override
  String get colorOrange => 'Turuncu';

  @override
  String get colorPink => 'Pembe';

  @override
  String get colorGreen => 'Yeşil';

  @override
  String get colorWhite => 'Beyaz';

  @override
  String get colorYellow => 'Sarı';

  @override
  String get colorRed => 'Kırmızı';

  @override
  String get colorCyan => 'Camgöbeği';

  @override
  String get colorIndigo => 'Çivit mavisi';

  @override
  String get colorLime => 'kireç';

  @override
  String get colorAmber => 'kehribar';

  @override
  String get colorRose => 'Gül';

  @override
  String get colorIceBlue => 'Buz Mavisi';

  @override
  String get memoryFeatures => 'Özelliğe göre bellek (önbellekler)';

  @override
  String get memoryAppIcons => 'Uygulama simgeleri';

  @override
  String get memoryAppBanners => 'Uygulama banner\'ları';

  @override
  String get memoryWatchNextPosters => 'Posterleri İzlemeye Devam Edin';

  @override
  String get memoryOtherCaches => 'Diğer kodlanmış görüntü önbellekleri';

  @override
  String get memoryFeaturesExplanation =>
      'Bunlar, kodlanmış önbellek toplamına zaten dahil edilmiş olan, tutulan görüntü baytlarıdır. Sıfır, özelliğin bellek kullanmadığı anlamına gelmez, önbellekte tutulan bayt olmadığı anlamına gelir. Duvar kağıtları ve görüntülenen resimler yukarıdaki kodu çözülmüş önbelleği paylaşır; aktif görüntüler bunun dışında olabilir. Hava durumu, bildirimler, Dart nesneleri ve motor burada özelliğe göre bölünemez. Paylaşılan arayüz grafikleri yukarıda Android tarafından rapor edilmiştir ve zaten PSS\'ye dahil edilmiştir. Hafızaları sürecin toplamının bir parçasıdır. Bu çakışan değerleri eklemeyin.';

  @override
  String get memoryGraphics => 'Arayüz grafikleri (PSS\'ye dahildir)';

  @override
  String get categoryVisible => 'Kategoriyi göster';

  @override
  String get hiddenCategories => 'Gizli kategoriler';

  @override
  String get visibleCategories => 'Görünür kategoriler';

  @override
  String get backupSavedToSelectedLocation =>
      'Yedekleme seçilen konuma kaydedildi';

  @override
  String get tileHorizontalGap => 'Yatay aralık';

  @override
  String get tileVerticalGap => 'Dikey aralık';

  @override
  String get tileOpacity => 'Arka plan opaklığı';

  @override
  String get tileShadow => 'Gölge';

  @override
  String get tileCornerRadius => 'Köşe yuvarlama';

  @override
  String get tileIconScale => 'Simge boyutu';

  @override
  String get tileBackgroundColor => 'Döşeme arka planı';

  @override
  String get tileLabelSize => 'Etiket boyutu';

  @override
  String get resetAppearance => 'Görünümü sıfırla';

  @override
  String get tileAppearance => 'Döşeme görünümü';

  @override
  String get tileLabelColor => 'Etiket rengi';

  @override
  String get tilePreviewName => 'Örnek uygulama';

  @override
  String get tileProportions => 'Fayans oranları';

  @override
  String get tileLarge => 'Büyük';

  @override
  String get tileLabelBelow => 'Döşemenin altında';

  @override
  String get tileLabelInside => 'Döşemenin içinde';

  @override
  String get tileFocusScale => 'Büyüt';

  @override
  String get tileMedium => 'Orta';

  @override
  String get tileFocusBorder => 'Hareket yok';

  @override
  String get tileSize => 'Döşeme boyutu';

  @override
  String get tileCompact => 'Kompakt';

  @override
  String get tileLabelPosition => 'Etiket konumu';

  @override
  String get tileFocusEffect => 'Odaklanma efekti';

  @override
  String get tileFocusStrength => 'Yoğunluğu vurgulayın';

  @override
  String get panelIndependent => 'Özel ayarlar';

  @override
  String get panelAppearance => 'Üst panel stili';

  @override
  String get panelBackground => 'Panel arka planı';

  @override
  String get blurPerformanceHint =>
      'Bulanıklaştırma düzgünlüğü azaltabilir. Bellek tasarrufu açıkken devre dışı bırakılır.';

  @override
  String get panelOpacity => 'Panel opaklığı';

  @override
  String get tileBlur => 'Fayansların arkasını bulanıklaştırın';

  @override
  String get panelBlur => 'Üst panelin arkasını bulanıklaştırın';

  @override
  String get panelShared => 'Panelleri beğen';

  @override
  String get weatherMinutes => 'dk.';

  @override
  String get weatherOpenMeteoCredit =>
      'Hava Durumu: Open-Meteo (open-meteo.com), CC BY 4.0. Ticari olmayan kullanım için ücretsiz API.';

  @override
  String get weatherRateLimit => 'İstek sınırına ulaşıldı. Daha sonra deneyin.';

  @override
  String get weatherYandexCredit =>
      'Hava Durumu: Yandex Hava Durumu (yandex.ru/pogoda). Erişim API planınıza bağlıdır.';

  @override
  String get yandexWeather => 'Yandex Hava Durumu (REST)';

  @override
  String get weatherAuthorizationError =>
      'Hava durumu sağlayıcısı talebi reddetti. API anahtarını kontrol edin ve seçilen hizmete erişin.';

  @override
  String get weatherYandexHint =>
      'REST tahmin erişimine sahip bir anahtar gerektirir. Başka bir Yandex planının anahtarı çalışmayabilir.';

  @override
  String get weatherSource => 'Hava durumu kaynağı';

  @override
  String get weatherInterval => 'Güncelleme aralığı';

  @override
  String get weatherLongitude => 'Boylam (-180 ila 180)';

  @override
  String get weatherKeyRequired => 'Yandex API anahtarı ekleyin.';

  @override
  String get weatherLocationName => 'Şehir adı (isteğe bağlı)';

  @override
  String get weatherLocation => 'Konum';

  @override
  String get weatherApiKey => 'Yandex API anahtarı';

  @override
  String get weatherInvalidResponse =>
      'Hava durumu kaynağı geçersiz veri döndürdü.';

  @override
  String get weatherUnavailable =>
      'Hava durumu kullanılamıyor. Daha önce alınan veriler mevcutsa korunur. Yeniden denemeler her 5 dakikada bir ile sınırlıdır.';

  @override
  String get weatherStale => 'Önceki hava durumu';

  @override
  String get weatherLatitude => 'Enlem (-90 ila 90)';

  @override
  String get weatherCoordinatesError =>
      'Bir şehri manuel olarak girin veya koordinatları otomatik olarak alın.';

  @override
  String get weatherRefresh => 'Güncellemeleri kontrol edin';

  @override
  String get weatherKeyPrivate =>
      'Yalnızca bu cihazda depolanır, yedeklemelerin dışında bırakılır. Boş giriş anahtarı kaldırır.';

  @override
  String get weatherUpdated => 'Güncellendi';

  @override
  String get onlineWallpaperError =>
      'Bu resim yüklenemiyor. Önceki duvar kağıdı korunur. İndirmeyi yeniden denemek için “Güncellemeleri kontrol et”i seçin.';

  @override
  String get onlineWallpaperHint =>
      'Son resim çevrimdışı kullanım için saklanır (en fazla 8 MiB).';

  @override
  String get onlineWallpaperHours => 'sa';

  @override
  String get onlineWallpaperInterval => 'İndirme aralığı';

  @override
  String get onlineWallpaper => 'Çevrimiçi duvar kağıdı';

  @override
  String get onlineWallpaperUrlError =>
      'Oturum açma ayrıntıları olmadan doğrudan bir HTTPS görüntüsü URL girin.';

  @override
  String get onlineWallpaperEnabled => 'Çevrimiçi duvar kağıdını kullan';

  @override
  String get onlineWallpaperSource => 'Resim kaynağı';

  @override
  String get bingWallpaper => 'Günün Bing görüntüsü';

  @override
  String get onlineWallpaperUrlSource => 'Doğrudan HTTPS URL';

  @override
  String get updatePlayOnly =>
      'Bu kurulum, güncellemeleri Google Play aracılığıyla alır.';

  @override
  String get updateCheck => 'Şimdi kontrol et';

  @override
  String get updateInstalled => 'Yüklendi';

  @override
  String get updateDownloadInstall => 'İndirin ve yükleyin';

  @override
  String get updateNoRelease => 'Daha yeni uyumlu bir sürüm mevcut değil.';

  @override
  String get updateIncompatible =>
      'APK bu uygulamayla, sertifikayla veya daha yeni bir sürümle eşleşmiyor. Kurulum engellendi.';

  @override
  String get updateError =>
      'Yükleyici kontrol edilemiyor, indirilemiyor veya açılamıyor. Daha sonra tekrar deneyin.';

  @override
  String get updateAvailable => 'Güncelleme mevcut';

  @override
  String get appUpdates => 'Uygulama güncellemeleri';

  @override
  String get updatePermission =>
      'Android ayarlarında bu uygulamadan kuruluma izin verin, buraya dönün ve tekrar Kur\'a basın.';

  @override
  String get updateInstall => 'İndirilen güncellemeyi yükle';

  @override
  String get updateHint =>
      'Kaynak: GitHub / KirillShchetinnikov/CuteLauncher-Releases. Otomatik kontroller başlatıcı açıkken çalışır. İndirme, seçtiğiniz anda başlar; Android sizden kurulumu onaylamanızı ister. Verileriniz saklanmaktadır.';

  @override
  String get updateAutomatic => 'Günde bir kez otomatik olarak kontrol edin';

  @override
  String get allApplications => 'Tüm uygulamalar';

  @override
  String get adbAccessibility => 'Ana Sayfa Düğmesi Düzeltmeyi Etkinleştir';

  @override
  String get adbAuthorization =>
      'TV\'de ADB yetkilendirmesini onaylayın ve tekrar deneyin.';

  @override
  String get adbChangeConfirm =>
      'Bu sistem ayarı ADB aracılığıyla uygulansın mı? Önceki Home uygulaması değiştirilmeden önce kaydedilir; diğer erişilebilirlik hizmetleri korunur.';

  @override
  String get adbCheck => 'Bağlantıyı kontrol edin';

  @override
  String get adbDenied => 'Sistem bu değişikliğe izin vermedi veya onaylamadı.';

  @override
  String get adbDisable => 'Önceki başlatıcıyı devre dışı bırak';

  @override
  String get adbDisableConfirm =>
      'Kaydedilen önceki başlatıcı devre dışı bırakılsın mı? Bunun için CuteLauncher\'nin geçerli Ev uygulaması olması gerekir. Bu kurulumdaki kurtarma eylemiyle geri yükleyin.';

  @override
  String get adbHint =>
      'Yalnızca bu TV için prototip (127.0.0.1). Geliştirici seçeneklerinde TCP ADB\'yi etkinleştirin, bağlantı noktasını girin ve TV\'deki yetkilendirme istemini onaylayın. Eşleştirme koduyla kablosuz hata ayıklama henüz desteklenmiyor. Özel anahtar, yedeklemelerin dışında bu cihazda kalır.';

  @override
  String get adbHome => 'CuteLauncher\'yi Ev uygulaması yapın';

  @override
  String get adbInvalid =>
      '1024 ile 65535 arasında bir bağlantı noktası girin.';

  @override
  String get adbNoRecovery =>
      'Geri yükleme kullanılamıyor: Başka başlatıcı veya kayıtlı hizmet durumu bulunamadı.';

  @override
  String get adbPort => 'TCP ADB bağlantı noktası';

  @override
  String get adbReady => 'ADB erişimi onaylandı.';

  @override
  String get adbRestore => 'Önceki başlatıcıyı geri yükle';

  @override
  String get adbSuccess => 'Değişiklik uygulandı ve doğrulandı.';

  @override
  String get adbTitle => 'ADB kurulumu';

  @override
  String get adbUnavailable =>
      'Bağlantı kurulamıyor. TCP ADB\'yi, bağlantı noktasını ve yetkilendirme istemini kontrol edin.';

  @override
  String get nightModeScheduled => 'Programı kullan';

  @override
  String get nightModeTitle => 'Gece modu';

  @override
  String get nightModeScope =>
      'Diğer uygulamaları karartmak için yer paylaşımı izni gereklidir. Bu olmadan, karartma CuteLauncher\'nin içinde çalışır. TCL filtresinin yer paylaşımı iznine ihtiyacı yoktur. %80\'in üzerinde opaklık Android diğer uygulamalardaki dokunma girişini engelleyebilir; TV\'nin uzaktan kumanda tuşları hâlâ çalışıyor.';

  @override
  String get nightModeEnd => 'Bitiş';

  @override
  String get nightModeStart => 'Başlat';

  @override
  String get nightModeDim => 'Karartma';

  @override
  String get nightModeWarmth => 'Sıcak filtre';

  @override
  String get nightModeScheduleHint =>
      'Yerel TV saatini kullanır. Gecelik dönemler desteklenmektedir. Eşit başlangıç ​​ve bitiş saatleri, zamanlanmış filtreyi devre dışı bırakır.';

  @override
  String get nightModeEnabled => 'Gece modunu etkinleştir';

  @override
  String get nightModePermission =>
      'Diğer uygulamaların üzerinde görüntülenmeye izin ver';

  @override
  String get nightModePermissionGranted =>
      'İzin verilen diğer uygulamaların üzerinde görüntüleme';

  @override
  String get backupDownloadsFailed =>
      'Yedekleme İndirilenler\'e kaydedilemedi.';

  @override
  String get backupSaveDownloads => 'Yedeği İndirilenler\'e kaydet';

  @override
  String get adbRestoreAccessibility =>
      'Erişilebilirlik erişimini geri yükleyin';

  @override
  String get nightModeAdbConfirm =>
      'Yerel ADB kullanılarak CuteLauncher\'nin diğer uygulamalar üzerinde görüntülenmesine izin verilsin mi? Önce TCP hata ayıklamasını etkinleştirin ve bağlantıyı yetkilendirin. ADB sihirbazında veya 5555\'te kayıtlı bağlantı noktasını kullanır.';

  @override
  String get nightModeAdbPermission => 'ADB aracılığıyla izin verin';

  @override
  String get nightModeNotificationsHint =>
      'Bildirim, filtreyi CuteLauncher dışında kapatmanıza olanak tanır. O olmadan bu menüyü kullanın.';

  @override
  String get nightModeNotificationsAllowed =>
      'Gece modu bildirimine izin verildi';

  @override
  String get nightModeNotifications => 'Gece modu bildirimine izin ver';

  @override
  String get categoryLastVisibleHint =>
      'En az bir kategori görünür kalmalıdır.';

  @override
  String get diagnosticsClear => 'Oturum teşhislerini temizle';

  @override
  String get diagnosticsReady => 'Rapor hazır';

  @override
  String get diagnosticsCreate => 'Rapor oluştur';

  @override
  String get diagnosticsOperations => 'Kaydedilen işlemler';

  @override
  String get diagnosticsCopied => 'Rapor kopyalandı';

  @override
  String get diagnosticsSharingNotice =>
      'Dosyayı yazara özel mesajla gönderin, herkese açık paylaşmayın: otomatik temizleme kişisel verileri kaçırabilir. Göndererek anonim TV uyumluluk raporunun CuteLauncher Git deposunda yayımlanmasını kabul edersiniz. Yalnızca cihaz bilgileri ve özellik kullanılabilirliği kişisel veriler olmadan yayımlanır; hata günlükleri, komutlar ve ayarlarınız yayımlanmaz.';

  @override
  String get diagnosticsHint =>
      'Tek rapor TV özellik uyumluluğunu ve hata tanılamasını birleştirir. Rapor TV modeli ve yazılımını, uygulama sürümünü, izinleri, belleği, hata aşamaları ve nedenlerini, kişisel verileri otomatik temizlenen komutları ve yanıtları içerir. Oturumda son 50 işlem, ayrıca en fazla 100 hata ve sınırlı ADB kaydı tutulur. Yeniden başlatma kaydı siler. Temizleme bazı kişisel verileri kaçırabilir: dosyayı herkese açık paylaşmak yerine özel mesajla gönderin. Otomatik gönderim yoktur. Her hata, uygulanan ayarların anlık görüntüsünü saklar; sonraki değişiklikler bunu değiştirmez.';

  @override
  String get diagnosticsTitle => 'Hata teşhisi';

  @override
  String get diagnosticsCopyFailed => 'Rapor kopyalanamadı.';

  @override
  String get diagnosticsCopy => 'Raporu kopyala';

  @override
  String get diagnosticsCreating => 'Rapor oluşturuluyor…';

  @override
  String get tclBlueLightTitle => 'TCL mavi ışık filtresi';

  @override
  String get tclBlueLightError =>
      'TCL filtre ayarı okunamadı veya doğrulanamadı. Durumunu yenileyin ve tekrar deneyin.';

  @override
  String get tclBlueLightUnsupported =>
      'TCL filtre arayüzü bu TV\'de mevcut değil.';

  @override
  String get tclBlueLightRefresh => 'TCL filtre durumunu yenile';

  @override
  String get tclBlueLightHint =>
      'TV\'nin yerleşik Göz Sağlığı Koruma filtresini kontrol eder. Ayrıca gece modu programını da takip edebilir.';

  @override
  String get nightSolarSchedule => 'Gün batımı ve gün doğumu';

  @override
  String get nightNextStart => 'Sonraki başlangıç';

  @override
  String get nightScheduleTimeHint =>
      'Saatler TV saat dilimini kullanır. Negatif dengelemeler daha erkendir; pozitif ofsetler daha sonradır.';

  @override
  String get nightTemperature => 'Filtre renk sıcaklığı';

  @override
  String get nightScheduleSettings => 'Zamanlama ayarları';

  @override
  String get nightCityName => 'Şehir adı';

  @override
  String get nightSkipUntilNext =>
      'Bir sonraki gün batımına kadar gece modunu devre dışı bırakın';

  @override
  String get nightSunriseOffset => 'Güneşin doğuşuna göre bitiş';

  @override
  String get nightEnableUntilMorning =>
      'Bir sonraki gün doğumuna kadar gece modunu etkinleştirin';

  @override
  String get nightPermissions => 'İzinler';

  @override
  String get nightTclSchedule => 'TCL filtresini programa dahil et';

  @override
  String get nightSearchCity => 'Ara';

  @override
  String get nightRefreshSun => 'Gün doğumu ve gün batımını yenileyin';

  @override
  String get nightSolarUnavailable =>
      'Bir şehir seçin ve güneş saatlerini yenileyin. Gün doğumu veya gün batımı mevcut değilse güneş enerjisi programı duraklatılır.';

  @override
  String get nightSunsetOffset => 'Gün batımına göre başlayın';

  @override
  String get nightCityHint =>
      'Konum erişimine izin vermek yerine şehrinizi seçin. Seçilen koordinatlar, güneş zamanlarını almak için Sunrise-Sunset.org\'a veya yedek olarak Open-Meteo\'ye gönderilir.';

  @override
  String get nightResumeSchedule => 'Programa dön';

  @override
  String get nightScheduleSource => 'Zamanlama türü';

  @override
  String get nightSolarCached =>
      'Önbelleğe alınmış güneş zamanlarını kullanma; İnternet yenileme otomatik olarak yeniden denenecektir.';

  @override
  String get nightTclScheduleHint =>
      'Gece modu etkinken aynı programı kullanır. TCL filtresinde yapılan manuel değişiklikler bir sonraki programlı geçişe kadar sürer. Kaplama iznine gerek yoktur.';

  @override
  String get nightRefreshPermission => 'İzin durumunu yenile';

  @override
  String get nightCityNotFound =>
      'Hiçbir şehir bulunamadı. Başka bir ad deneyin.';

  @override
  String get nightNoOffset => 'Ofset yok';

  @override
  String get nightManualSchedule => 'Özel program';

  @override
  String get nightChooseCity => 'Şehir seç';

  @override
  String get nightPermissionUnknown => 'Yer paylaşımı izin durumu bilinmiyor';

  @override
  String get nightNextEnd => 'Sonraki son';

  @override
  String get nightTemporaryOff => 'Karartma geçici olarak kapalı';

  @override
  String get nightCitySearchFailed =>
      'Şehirler aranamadı. İnternet bağlantınızı kontrol edin.';

  @override
  String get nightSolarAttribution =>
      'Günlük güneşlenme saatleri: Sunrise-Sunset.org; geri dönüş: Open-Meteo. Şehir araması: GeoNames. Çevrimdışı kullanım için birkaç gün önbelleğe alınır.';

  @override
  String get nightTemporaryOn => 'Karartma geçici olarak açık';

  @override
  String get homeScreen => 'Ana ekran';

  @override
  String get appearanceSettings => 'Görünüm';

  @override
  String get generalSettings => 'Gelişmiş';

  @override
  String get advancedSettings => 'Gelişmiş';

  @override
  String get controlAndStartup => 'Başlatıcı ve TV kontrolleri';

  @override
  String get sectionsAndOrder => 'Bölümler ve sipariş';

  @override
  String get topPanel => 'Üst panel';

  @override
  String get tileStyle => 'Döşeme stili';

  @override
  String get tilesAndLabels => 'Döşemeler ve etiketler';

  @override
  String get highlightAndAnimation => 'Vurgulama ve animasyon';

  @override
  String get androidTvSettings => 'Android TV ayarları';

  @override
  String get weatherSettings => 'Hava durumu ayarları';

  @override
  String get showHighlightOutline => 'Vurgu ana hatlarını göster';

  @override
  String get resetTilesAndPanel => 'Döşeme ve panel ayarlarını sıfırlayın';

  @override
  String get resetTilesAndPanelHint =>
      'Ek döşeme, etiket, vurgulama ve üst panel parametreleri sıfırlansın mı? Duvar kağıdı, vurgu rengi, döşeme stili ve etiket görünürlüğü korunur.';

  @override
  String get panelAppearanceSettings => 'Üst panel görünümü';

  @override
  String get panelSharedHint => 'Döşeme ayarlarında görünümü değiştirin.';

  @override
  String get effectsCompatibilityHint =>
      'Ek görünüm: ana hat her zaman görünürdür ve darbe yapmaz. Boyutsal stilin eski bir taslağı yoktur; klasik nabız atmıyor. Yoğunluk ölçeği ve gölgeyi etkiler; ölçeklendirme alanla sınırlıdır.';

  @override
  String get sizeAndLayout => 'Boyut ve düzen';

  @override
  String get labelsGroup => 'Etiketler';

  @override
  String get surfaceGroup => 'Yüzey';

  @override
  String get clockAndDateGroup => 'Saat ve tarih';

  @override
  String get networkAndTrafficGroup => 'Ağ ve trafik';

  @override
  String get buttonsGroup => 'Düğmeler';

  @override
  String get notificationAppsHint =>
      'Bildirimlerine ihtiyaç duymadığınız uygulamaları kapatın. Etkinleştirilmiş bir anahtar bildirimlere izin verir; uygulama hâlâ başlatılabilir.';

  @override
  String get notificationPanelLink => 'Üst panel görünümü';

  @override
  String get overlayAccessAdb => 'Diğer uygulamaların üzerinde görüntüle (ADB)';

  @override
  String get tileStyleModern => 'Çağdaş';

  @override
  String get tileStyleVolume => 'boyutlu';

  @override
  String get showTime => 'Zamanı göster';

  @override
  String get showDate => 'Tarihi göster';

  @override
  String get showWeather => 'Hava durumunu göster';

  @override
  String get showNetwork => 'Ağ durumunu göster';

  @override
  String get showTraffic => 'Trafiği göster';

  @override
  String get scheduledBrightness => 'Zamanlanmış parlaklık';

  @override
  String get followTileStyle => 'Stili takip et';

  @override
  String get androidTvSettingsHint => 'TV sistem ayarlarını açın';

  @override
  String get autoHideTopPanel => 'Paneli otomatik olarak gizle';

  @override
  String get showSectionTitles => 'Bölüm başlıklarını göster';

  @override
  String get usageDaily => 'Günlük';

  @override
  String get usageWeekly => 'Haftalık';

  @override
  String get usageMonthly => 'Aylık';

  @override
  String get onlineWallpaperAddress => 'Resim adresi (HTTPS)';

  @override
  String get watchNextAppLimits => 'Uygulama başına sınırlar';

  @override
  String get watchNextAppLimitsHint =>
      'Kaynak limitleri genel limitten önce uygulanır. Sınırsız yalnızca genel sınırı korur; gizli içerik gizli kalır.';

  @override
  String get rememberCategoryFocus => 'Son odaklanılan kartı hatırla';

  @override
  String get automaticBackups => 'Otomatik yedekleme';

  @override
  String get automaticBackupsHint =>
      'Başlatıcı etkinken ayarların, duvar kağıtlarının ve bannerların günlük kopyaları. Kaçırılan bir kopya, başlatıcıya döndükten sonra çalıştırılır. Toplamda en fazla 256 MiB olmak üzere bu cihazda özel olarak depolanır; uygulamayı veya verilerini kaldırmak onları siler. Harici bir yedek de bulundurun.';

  @override
  String get automaticBackupsEnabled => 'Günlük otomatik yedekleme';

  @override
  String get automaticBackupsKeep => 'Saklanacak kopyalar';

  @override
  String get automaticBackupCreateNow =>
      'Şimdi bir geri yükleme noktası oluşturun';

  @override
  String get automaticBackupFailed =>
      'Yedekleme işlemi başarısız oldu. Boş alanı kontrol edip tekrar deneyin.';

  @override
  String get restorePoints => 'Noktaları geri yükle';

  @override
  String get noRestorePoints => 'Henüz geri yükleme noktası yok';

  @override
  String get updatePrereleases => 'Ön sürümlere güncelle';

  @override
  String get topPanelObjects => 'Nesneler';

  @override
  String get panelTransparency => 'Panel şeffaflığı';

  @override
  String get panelTextBackground => 'Metin ve düğme arka planı';

  @override
  String get panelTextBackgroundColor => 'Metin ve düğme arka plan rengi';

  @override
  String get panelTextColor => 'Metin ve düğme rengi';

  @override
  String get panelTextSize => 'Metin ve düğme boyutu';

  @override
  String get panelFont => 'Metin yazı tipi';

  @override
  String get fontSans => 'Sans serif';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontMono => 'Tek uzay';

  @override
  String get fontCondensed => 'Yoğunlaştırılmış';

  @override
  String get trafficPermissionGranted =>
      'Trafik istatistiklerine erişim izni verildi';

  @override
  String get background => 'Arkaplan';

  @override
  String get backgroundParameters => 'Kaynak ayarları';

  @override
  String get resetAppearanceHint =>
      'Arka plan, vurgu, döşemeler, etiketler, vurgulama ve animasyon sıfırlansın mı?';

  @override
  String get wallpaperDimming => 'Karartma';

  @override
  String get wallpaperPlacement => 'Yerleştirme';

  @override
  String get wallpaperDisplay => 'Duvar kağıdı ekranı';

  @override
  String get wallpaperContain => 'Resmin tamamını göster';

  @override
  String get wallpaperBlurred => 'Bulanık kopyanın üzerinde';

  @override
  String get wallpaperCover => 'Ekranı doldur';

  @override
  String get wallpaperBrightness => 'Duvar kağıdı parlaklığı';

  @override
  String get wallpaperSaturation => 'Doygunluk';

  @override
  String get categoryPadding => 'Kategori dolgusu';

  @override
  String get categoryLight => 'Işık';

  @override
  String get categoryBlue => 'Mavi';

  @override
  String get categoryPurple => 'Mor';

  @override
  String get categoryAllRows => 'Hepsi';

  @override
  String get categoryTeal => 'turkuaz';

  @override
  String get categoryMaxRows => 'Görünür ızgara satırları';

  @override
  String get categoryDark => 'Karanlık';

  @override
  String get categoryAppearance => 'Kategori görünümü';

  @override
  String get categoryBackground => 'Kategori arka planı';

  @override
  String get categoryTransparent => 'Şeffaf';

  @override
  String get slideshowInterval => 'Aralığı değiştir';

  @override
  String get slideshowFolderSelected => 'Klasör erişimi bu cihaza kaydedildi.';

  @override
  String get slideshowRandom => 'Rastgele sıra';

  @override
  String get wallpaperSlideshow => 'Klasör slayt gösterisi';

  @override
  String get slideshowNext => 'Sonraki resim';

  @override
  String get slideshowFolderRequired =>
      'Slayt gösterisini başlatmak için bir klasör seçin.';

  @override
  String get slideshowHint =>
      '1.000\'e kadar görüntü ve 4.000\'e kadar klasör girişi; 8 MiB\'ye kadar dosyalar. Bozuk dosyalar atlanır ve son iyi görüntü korunur. Değişiklikler arka planda durur. Başka bir cihaza geri yükledikten sonra klasörü tekrar seçin.';

  @override
  String get slideshowSeconds => 's';

  @override
  String get slideshowError =>
      'Resimler okunamıyor. Geçerli görseller içeren erişilebilir bir klasör seçin.';

  @override
  String get slideshowFolder => 'Klasör seç';

  @override
  String get slideshowRecursive => 'Alt klasörleri dahil et';

  @override
  String get weatherSourceKeyRequired =>
      'Bu hava durumu kaynağı için bir API anahtarı ekleyin.';

  @override
  String get weatherOpenWeatherCredit =>
      'Hava Durumu: OpenWeather (openweathermap.org). Günlük değerler mevcut üç saatlik tahmin dönemlerini özetler.';

  @override
  String get weatherOpenWeatherHint =>
      'Mevcut Hava Durumu ve 5 günlük / 3 saatlik Tahmin için anahtarınızı kullanın. Her güncelleme iki istekte bulunur; erişim ve sınırlar planınıza bağlıdır.';

  @override
  String get weatherOpenWeatherKey => 'OpenWeather API anahtarı';

  @override
  String get mediaPause => 'Duraklat';

  @override
  String get showNowPlaying => 'Şimdi Ana Sayfada oynatıldığını göster';

  @override
  String get nowPlayingAccessHint =>
      'Medya kontrolleri CuteLauncher için bildirim erişimi gerektirir. Yalnızca oynatıcı tarafından sağlanan eylemler gösterilir.';

  @override
  String get nowPlaying => 'Şimdi oynatılıyor';

  @override
  String get mediaNext => 'Sonraki parça';

  @override
  String get mediaPlay => 'Devam et';

  @override
  String get mediaControlError =>
      'Oyuncu müsait değil veya bu işlemi kabul etmedi.';

  @override
  String get nightUsageAccess => 'Kullanım erişimine izin ver';

  @override
  String get nightExcludedAppsHint =>
      'Seçilen uygulamalarda yer paylaşımı ve planlanmış TCL filtresi duraklatılır. Kullanım erişimi gereklidir; bu olmadan istisnalar uygulanamaz.';

  @override
  String get nightExcludedApps => 'Hariç tutulan uygulamalar';

  @override
  String get adbPairPort => 'Eşleştirme bağlantı noktası';

  @override
  String get adbPairOverlayHint =>
      'Kablosuz hata ayıklamayı açın ve eşleştirme koduyla eşleştirin. Sistem kodu iletişim kutusunu açık tutun. Bu form 30 saniye sonra aktif hale gelir. Her iki bağlantı noktasını ve Android tarafından gösterilen kodu girin.';

  @override
  String get adbOverlaySettings =>
      'Kontrolü 30 saniyeliğine Ayarlar\'a döndürün';

  @override
  String get adbTlsHint =>
      'Geliştirici seçeneklerinde Kablosuz hata ayıklamayı kullanın. Eşleştirme ve bağlantının farklı bağlantı noktaları vardır. Ürün yazılımınızda eşleştirme kodu ekranı yoksa veya yer paylaşımlı pencereleri engelliyorsa, bunun yerine TCP / RSA\'yı kullanın. Tüm bağlantılar bu TV\'de yerel kalır.';

  @override
  String get adbPaired =>
      'Eşleştirildi. Kablosuz hata ayıklama bağlantı noktasını kullanarak bağlantıyı kontrol edin.';

  @override
  String get adbTransport => 'Bağlantı yöntemi';

  @override
  String get adbPairCode => 'Altı haneli kod';

  @override
  String get adbOverlayRequired =>
      'Ayarlar üzerinden kod girişi, diğer uygulamaların üzerinde görüntülenme izni gerektirir.';

  @override
  String get adbOverlayPermission =>
      'Diğer uygulamaların üzerinde görüntülenmeye izin ver';

  @override
  String get adbTlsUnsupported =>
      'Bu ürün yazılımı gerekli Ayarlar ekranını veya eşleştirme katmanını açamıyor. TCP / RSA\'yı kullanın.';

  @override
  String get adbConnectPort => 'Bağlantı noktası';

  @override
  String get adbTls => 'TLS / eşleştirme kodu';

  @override
  String get adbTcp => 'TCP/RSA';

  @override
  String get adbPairingFailed =>
      'Eşleştirme başarısız oldu. Kodu ve eşleştirme bağlantı noktasını kontrol edin, Android kod iletişim kutusunu açık tutun ve tekrar deneyin.';

  @override
  String get adbTlsDisabled =>
      'Kablosuz hata ayıklama devre dışı veya durumu kullanılamıyor. Geliştirici seçeneklerinde etkinleştirin.';

  @override
  String get adbPairOverlay => 'Ayarlar\'a eşleştirme kodunu girin';

  @override
  String get adbPair => 'Çift';

  @override
  String get adbDeveloperSettings => 'Geliştirici seçeneklerini aç';

  @override
  String get adbTwoWindowsHint =>
      'Bu ürün yazılımı iki pencereyi destekliyorsa, CuteLauncher\'nin yanındaki sistem eşleştirme iletişim kutusunu açık tutun ve kodunu buraya girin. Doğrudan eşleştirme yalnızca her iki pencere de açıkken kullanılabilir.';

  @override
  String get adbTwoWindows => 'Ayarları ikinci bir pencerede açın';

  @override
  String get autoLaunchBoot => 'TV açılışından sonra';

  @override
  String get autoLaunchOff => 'Devre dışı';

  @override
  String get autoLaunchTitle => 'Otomatik başlatma';

  @override
  String get autoLaunchDelay => 'Başlatma gecikmesi';

  @override
  String get autoLaunchHdmi => 'Seçilen bir HDMI girişine geçiş yap';

  @override
  String get autoLaunchWake => 'Uyandıktan sonra';

  @override
  String get autoLaunchHint =>
      'TV başlatıldıktan veya uyandırıldıktan sonra açılacak bir uygulamayı veya HDMI girişini seçin. Olayı ve gecikmeyi aşağıda ayarlayın. Android, CuteLauncher\'yi gösterdiğinde eylem bir kez çalıştırılır. Herhangi bir uzaktan giriş veya ana ekrandan ayrılma, beklemeyi iptal eder. HDMI girişlerini daha sonra serbestçe değiştirebilirsiniz. CuteLauncher\'yi varsayılan başlatıcı olarak ayarlayın veya gerekirse Başlatma sırasında başlat seçeneğini etkinleştirin. Uyanıklık tespiti CuteLauncher\'nin çalışmaya devam etmesini gerektirir.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds saniye';
  }

  @override
  String get autoLaunchApp => 'Seçilen bir uygulamayı aç';

  @override
  String get autoLaunchTarget => 'Hedefi başlat';

  @override
  String get autoLaunchUnavailable =>
      'Hedef kullanılamıyor veya ürün yazılımı bu eyleme izin vermiyor.';

  @override
  String get autoLaunchCancelled => 'Gecikmeli başlatma iptal edildi.';

  @override
  String get syncTitle => 'Değişim ayarları';

  @override
  String get syncHint =>
      'Bir ayar dosyasını kaydedin, başka bir cihaza aktarın ve orada açın. Her iki cihazı da güncel hale getirmek için dosyayı geri değiştirin. Arayüz, döşeme stili ve ekran tercihleri ​​paylaşılır. Uygulamalar, bölümler, duvar kağıdı dosyaları, izinler, HOME, başlatma kuralları ve sırlar bu cihazda kalır. Bu manuel değişimdir; hiçbir hesap veya arka plan ağ bağlantısı kullanılmaz.';

  @override
  String get syncExport => 'Değişiklikleri bir dosyaya kaydetme';

  @override
  String get syncImport => 'Değişiklikleri başka bir cihazdan açma';

  @override
  String get syncSaved => 'Ayarlar değişim dosyası kaydedildi.';

  @override
  String get syncFailed =>
      'Ayarlar değiştirilemiyor. Kısmi ithalat yapılmaz. İnceleme sırasında ayarlar değiştiyse dosyayı kontrol edin veya tekrar açın.';

  @override
  String get syncPreviewHint =>
      'Uygulamadan önce değişiklikleri inceleyin. Çakışmalarda bu cihazı veya dosyayı seçmek için her satırı seçin. Bu cihazın tutulması başlangıçta seçilir. İptal, ayarları değiştirmeden bırakır.';

  @override
  String get syncNoChanges =>
      'Yeni ayar yok. Paylaşılan geçmişi onaylamak için başvurun.';

  @override
  String syncLocalValue(String value) {
    return 'Bu cihaz: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'Dosyadan: $value';
  }

  @override
  String get syncKeepLocal => 'Çakışma: Bu cihazı koruyun';

  @override
  String get syncUseFile => 'Çakışma: dosyayı kullan';

  @override
  String get syncApply => 'İncelenen değişiklikleri uygula';

  @override
  String get syncApplied =>
      'Ayarlar değiştirildi. Sonucu geri göndermek için yeni bir dosya kaydedin.';

  @override
  String syncStyleParameters(int count) {
    return 'Özel stil: $count parametre (farklar aşağıda)';
  }

  @override
  String get cloudBackups => 'Bulut yedeklemeleri';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud. Mevcut bir klasörün HTTPS adresini ve bir uygulama şifresini girin. Transferler manueldir; bu klasör en son kopyayı saklar.';

  @override
  String get cloudUrl => 'Klasör HTTPS adresi';

  @override
  String get cloudUser => 'Kullanıcı adı';

  @override
  String get cloudPassword => 'Uygulama şifresi';

  @override
  String get cloudConnect => 'Hesabı kontrol edin ve kaydedin';

  @override
  String get cloudCheck => 'Bağlantıyı kontrol edin';

  @override
  String get cloudDisconnect => 'Hesabın bağlantısını kes';

  @override
  String get cloudDisconnectConfirm =>
      'Bu hesap TV\'den kaldırılsın mı? Buluttaki kopyalar kalacaktır.';

  @override
  String get cloudUpload => 'Bir kopyasını buluta kaydet';

  @override
  String get cloudDownload => 'Buluttan geri yükleme';

  @override
  String get cloudUploadConfirm =>
      'Bu klasördeki sevimlilauncher_backup.json geçerli ayarlar ve verilerle değiştirilsin mi?';

  @override
  String get cloudSuccess => 'Bitti';

  @override
  String get cloudConfigurationError =>
      'HTTPS klasör adresini, kullanıcı adını ve uygulama şifresini kontrol edin.';

  @override
  String get cloudAuthorizationError =>
      'Erişim reddedildi. Hesap ve klasör izinlerinizi kontrol edin.';

  @override
  String get cloudMissingError => 'Klasör veya yedekleme bulunamadı.';

  @override
  String get cloudUnsupportedError =>
      'Bu adres gerekli WebDAV işlemlerini desteklemiyor. Yönlendirmelere uyulmuyor; son klasör adresini girin.';

  @override
  String get cloudNetworkError =>
      'Bağlantı başarısız oldu veya zaman aşımına uğradı. Ağ kullanılabilir olduğunda tekrar deneyin.';

  @override
  String get cloudFailed =>
      'Yedekleme işlemi tamamlanamadı. Depolama erişimini kontrol edin ve tekrar deneyin.';

  @override
  String get cloudStorageError =>
      'Hesap depolama alanı kullanılamıyor. Hesabın bağlantısını kesin ve yeniden yapılandırın.';

  @override
  String get adbPermissionChecking => 'Erişim kontrol ediliyor…';

  @override
  String get adbPermissionConnected => 'ADB bağlandı · izin ver';

  @override
  String get adbPermissionDisconnected =>
      'ADB bağlantısı kesildi · bağlantıyı kurun';

  @override
  String get adbSetupIntro =>
      'TV geliştirici ayarlarında hata ayıklamayı ve ağ ADB\'yi etkinleştirin, ardından CuteLauncher\'ye güvenin. Tüm ADB eylemlerinin riski size aittir.';

  @override
  String get adbConnectionBlock => 'ADB bağlantısı';

  @override
  String get adbNotChecked => 'Bağlantı kontrol edilmedi';

  @override
  String get adbApplied => 'Zaten uygulandı';

  @override
  String get adbNotApplied => 'Henüz uygulanmadı';

  @override
  String get adbDefaultBlock => 'Varsayılan başlatıcı';

  @override
  String get adbSystemDefault => 'Sistem varsayılan başlatıcı ayarını aç';

  @override
  String get adbAssignDefault =>
      'CuteLauncher\'yi ADB aracılığıyla varsayılan başlatıcı olarak ayarlayın';

  @override
  String get adbRestoreDefault =>
      'Önceki varsayılan başlatıcıyı ADB aracılığıyla geri yükleyin';

  @override
  String get adbDefaultHint =>
      'Sistem menüsü varsayılan başlatıcıyı ayarlayamıyorsa ADB\'yi kullanın.';

  @override
  String get adbBuiltinHint =>
      'Yerleşik başlatıcıyı devre dışı bırakmak sistemin bunun yerine CuteLauncher\'yi açmasına olanak tanır. TV menüleri ve düğmeleri etkilenebilir. Bunu geri almak için yerleşik başlatıcıyı etkinleştirin.';

  @override
  String get adbHomeBlock => 'Ana sayfa düğmesi ve başlatma';

  @override
  String get adbEnableService =>
      'CuteLauncher erişilebilirlik hizmetini ADB aracılığıyla etkinleştirin';

  @override
  String get adbHomeOverride => 'Ana Sayfa düğmesini geçersiz kıl';

  @override
  String get adbHomeOptional =>
      'Yerleşik başlatıcı devre dışı bırakılırsa Ana Sayfa\'nın geçersiz kılınması ve TV başlatıldığında başlatılması isteğe bağlıdır.';

  @override
  String get adbEnableBuiltin =>
      'ADB aracılığıyla yerleşik başlatıcıyı etkinleştirin';

  @override
  String get adbDisableBuiltin =>
      'ADB aracılığıyla yerleşik başlatıcıyı devre dışı bırakın';

  @override
  String get adbNoBuiltin =>
      'Yerleşik Google TV / Android TV başlatıcısı bulunamadı.';

  @override
  String get adbChanged =>
      'Devlet değişti. Bağlantıyı kontrol edin ve işlemi tekrar onaylayın.';

  @override
  String get adbEffectHome =>
      'CuteLauncher sistemin varsayılan başlatıcısı olacaktır. Mevcut başlatıcı geri yükleme için kaydedilecek.';

  @override
  String get adbEffectRestore =>
      'Önceki başlatıcı etkinleştirilecek ve varsayılan hale getirilecek. Mevcut değilse veya kaydedilmemişse mevcut ilk başlatıcı seçilir. Bu, Ana Sayfa Düğmesi Düzeltmeyi devre dışı bırakmaz.';

  @override
  String get adbEffectDisable =>
      'Yerleşik başlatıcı uygulaması TV kullanıcısı için devre dışı bırakılacaktır. TV menüleri ve düğmeleri çalışmayı durdurabilir. Uygulama kaldırılmıyor.';

  @override
  String get adbRecoveryHomeDisable =>
      'CuteLauncher\'nin varsayılan başlatıcı olabilmesi için, kurtarma ana ekranı da dahil olmak üzere Google TV kurulum sihirbazının tamamı da devre dışı bırakılacaktır. Kurulum sihirbazı özellikleri restorasyona kadar kullanılamayacaktır. Her iki paketin orijinal durumları geri yükleme için kaydedilecektir.';

  @override
  String get adbRecoveryHomeRestore =>
      'Google TV kurulum sihirbazı da kayıtlı durumuna geri dönecektir.';

  @override
  String get adbDisableHomeUnavailable =>
      'Başka bir ana ekranın önceliği daha yüksektir. Bu başlatıcı tarafından güvenli bir şekilde devre dışı bırakılamaz.';

  @override
  String get adbEffectEnable =>
      'Yerleşik başlatıcı kayıtlı durumuna geri yüklenecek veya herhangi bir durum kaydedilmemişse etkinleştirilecektir. Sistem onu ​​tekrar varsayılan başlatıcı olarak seçebilir.';

  @override
  String get adbEffectAccessibility =>
      'CuteLauncher erişilebilirlik hizmeti etkinleştirilecektir. Ev etkinliklerini alabilir; müdahale ayrı bir anahtarla kontrol edilir. Diğer hizmetler korunur.';

  @override
  String get adbEffectAccessibilityRestore =>
      'CuteLauncher hizmeti, ADB erişimi verilmeden önceki durumuna geri dönecektir. Diğer erişilebilirlik hizmetleri korunur.';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher\'nin gece filtresi de dahil olmak üzere diğer uygulamaların üzerinde pencereleri görüntülemesine izin verilecek.';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher, kendi dinleyici hizmeti aracılığıyla bildirim erişimi alacaktır.';

  @override
  String get adbEffectWatchNext =>
      'CuteLauncher, İzlemeye devam etme verilerine erişim elde edecek.';

  @override
  String get adbEffectUsage =>
      'CuteLauncher, trafik ve ön plandaki uygulama tespiti için kullanım istatistikleri erişimine sahip olacaktır.';

  @override
  String get adbEffectWriteSettings =>
      'CuteLauncher\'nin sistem parlaklık ayarlarını değiştirmesine izin verilecek.';

  @override
  String get adbNoAvailableLauncher =>
      'Yüklü başka başlatıcı bulunamadı. Restorasyon kullanılamıyor.';

  @override
  String get adbUnsupported =>
      'Bu cihazda kullanılamıyor: desteklenen ADB komutu yok.';

  @override
  String get adbHomeUnavailable =>
      'Yerleşik başlatıcının sistem önceliği vardır. ADB aracılığıyla doğrudan atama mevcut değildir; erişilebilirliği kullanın veya yerleşik başlatıcıyı devre dışı bırakın.';

  @override
  String get nightBatteryExempt => 'CuteLauncher optimizasyondan muaftır';

  @override
  String get nightBatteryHint =>
      'Programın arka planda çalışmasına yardımcı olabilir. İşlemin bekleme modunda hayatta kalacağını garanti etmez.';

  @override
  String get nightBatteryOptimized => 'CuteLauncher optimizasyona tabidir';

  @override
  String get nightBatteryTitle => 'Pil optimizasyonu';

  @override
  String get nightBatteryUnavailable =>
      'Bu ürün yazılımında sistem ayarları kullanılamıyor veya erişim reddedildi.';

  @override
  String get nightBatteryUnknown => 'Muafiyet durumu bilinmiyor';

  @override
  String get nightBatteryOpenApps => 'Uygulama ayarlarını aç';

  @override
  String get nightBatteryGuide =>
      '1. Uygulama ayarlarında Özel uygulama erişimini açın.\n2. Pil optimizasyonunu (bazen Enerji tasarrufu) seçin.\n3. CuteLauncher\'yi bulun; gerekiyorsa Tüm uygulamalar\'ı seçin.\n4. Optimizasyonu devre dışı bırakın veya Sınırsız\'ı seçin.\nMenü adları ve kullanılabilirliği TV donanım yazılımına bağlıdır.';

  @override
  String get updateNotifications => 'Güncelleme bildirimlerini göster';

  @override
  String get diagnosticsSave => 'Raporu dosyaya kaydet';

  @override
  String get diagnosticsSaved => 'Rapor kaydedildi';

  @override
  String get diagnosticsSaveFailed =>
      'Rapor kaydedilemedi. Dosya yöneticisini ve hedef klasörü kontrol edin.';

  @override
  String get memoryCacheSize => 'Görüntü önbellek boyutu';

  @override
  String get memoryProcess => 'Uygulama belleği';

  @override
  String get memoryImages => 'Görüntü önbellekleri';

  @override
  String get diagnosticsExportOpened =>
      'Dosya yöneticisinde bir klasör seçin ve raporu kaydedin.';

  @override
  String get adbDisableService =>
      'CuteLauncher erişilebilirlik hizmetini ADB aracılığıyla devre dışı bırakın';

  @override
  String get adbDefaultSettings => 'Varsayılan başlatıcı ayarları';

  @override
  String get adbHomeSettings => 'Ana sayfa düğmesi ayarları';

  @override
  String get adbAccessibilitySettings => 'Erişilebilirlik ayarlarını aç';

  @override
  String get adbAccessibilityGuide =>
      'Sistem menüsünde CuteLauncher\'yi seçin ve hizmetini etkinleştirin. Evde dinlemeyi yapılandırmak için buraya dönün. Devre dışı bırakmak için aynı menüden CuteLauncher hizmetini kapatın.';

  @override
  String get adbEffectAccessibilityDisable =>
      'CuteLauncher hizmeti devre dışı bırakılacak. Eve müdahale durdurulacak. Diğer erişilebilirlik hizmetleri korunur.';

  @override
  String get backupAutoEnabled => 'Otomatik yedekleme';

  @override
  String get backupClientId => 'Müşteri Kimliği';

  @override
  String get backupClientSecret => 'Müşteri Sırrı';

  @override
  String get backupCloudImportConfirm =>
      'Tüm yerel ayarlar, kategoriler ve görseller bulut verileriyle değiştirilecek. Devam etmek?';

  @override
  String get backupConfigured => 'Yapılandırılmış';

  @override
  String get backupConnection => 'Bağlantı ayarları';

  @override
  String get backupCreated => 'Oluşturuldu';

  @override
  String get backupDaily => 'Günlük';

  @override
  String get backupDriveHelp =>
      'Bağlan\'ı seçin ve telefonunuzdaki kodu onaylayın. Yedeklemeler, Google Drive\'deki CuteLauncher klasöründe görünür; bunları indirebilir veya silebilirsiniz. Uygulama içi geri yükleme için dosya adlarını değiştirmeden tutun. Gizli yedeklemelerden yükseltme yaptıktan sonra yeniden bağlanın; eski yedeklemeler otomatik olarak taşınmaz.';

  @override
  String get backupFrequency => 'Yedekleme sıklığı';

  @override
  String get backupHourly => 'Saatlik';

  @override
  String get backupLocal => 'Yerel kopyalar';

  @override
  String get backupMinutes => 'dk.';

  @override
  String get backupMode => 'Mod';

  @override
  String get backupNever => 'Henüz yedekleme yok';

  @override
  String get backupNotConfigured => 'Yapılandırılmadı';

  @override
  String get backupOptions => 'Yedekleme seçenekleri';

  @override
  String get backupSaveMode => 'Yedekleme';

  @override
  String get backupScope => 'TV\'ler arasında yedekleme';

  @override
  String get backupSyncScope => 'TV\'ler arasında senkronizasyon';

  @override
  String get backupSeparate => 'Her TV için ayrı';

  @override
  String get backupShared => 'Tüm TV\'ler için aynı ayarlar';

  @override
  String get backupStorage => 'Depolama';

  @override
  String get backupSyncHelp =>
      'Verileri indirin ve değişiklikleri yükleyin. Son değişiklik çatışmaları kazanır. TV saatleri doğru olmalıdır. Başlatıcı açıkken senkronizasyon çalışır.';

  @override
  String get backupSyncLimit => 'Şundan daha sık kontrol etmeyin:';

  @override
  String get backupSyncMode => 'Senkronizasyon';

  @override
  String get backupSyncOptions => 'Senkronizasyon seçenekleri';

  @override
  String get backupTime => 'Yedekleme süresi';

  @override
  String get backupWeekday => 'Haftanın günü';

  @override
  String get backupWeekly => 'Haftalık';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'Yerel kopyalar uygulama veya verileriyle birlikte silinir. Bir kopyasını da TV\'nin dışında saklayın.';

  @override
  String get panelObjectOrder => 'Nesne sırası';

  @override
  String get panelInformationGroup => 'Bilgi';

  @override
  String get panelOrderHint =>
      '◄ / ► taşımayı başlatır veya bitirir; ▲ / ▼ sıralamayı değiştirir ve grup sınırında diğer tarafa taşır; OK / Geri bitirir.';

  @override
  String get panelTextBackgroundTransparency =>
      'Metin ve düğme arka planı şeffaflığı';

  @override
  String get weatherCityHint =>
      'Şehir adını İngilizce olarak girin, örneğin Moskova.';

  @override
  String get weatherCityNotFound =>
      'Şehir bulunamadı. Şehir adını İngilizce olarak kontrol edin.';

  @override
  String get weatherLocationAutomatic => 'Otomatik olarak al';

  @override
  String get weatherLocationAutomaticHint =>
      'Cihaz koordinatlarını alın. Konum izni gereklidir.';

  @override
  String get weatherLocationManual => 'Manuel olarak girin';

  @override
  String get weatherLocationPermissionDenied =>
      'Android ayarlarında konum erişimine izin verin ve tekrar deneyin.';

  @override
  String get weatherLocationUnavailable =>
      'Koordinatlar alınamadı. Android konum ayarlarını kontrol edin veya manuel olarak bir şehir girin.';

  @override
  String get nightFilterSettings => 'Filtre ayarları';

  @override
  String get nightScheduleMenu => 'Program';

  @override
  String get nightScheduleInactive => 'Program kapalı';

  @override
  String get nightLocation => 'Konum';

  @override
  String get nightLocationAutomatic => 'Otomatik olarak al';

  @override
  String get nightLocationManual => 'Manuel olarak girin';

  @override
  String get nightLocationFailed =>
      'Konum kullanılamıyor. İzin ve sistem konumu ayarlarını kontrol edin.';

  @override
  String get nightCityEnglish => 'Şehir adını İngilizce olarak girin';

  @override
  String get nightOverlayBrief =>
      'Filtrenin diğer uygulamaların üzerinde görünmesine izin verir.';

  @override
  String get weatherGetLocation => 'Konumu al';

  @override
  String get backupLastCreated => 'Son yedekleme oluşturuldu:';

  @override
  String get backupManagement => 'Yedeklemeleri yönet';

  @override
  String get backupCopyList => 'Yedekleme listesi';

  @override
  String get backupRefreshCopyList => 'Yedekleme listesini yenile';

  @override
  String get backupCreateNow => 'Şimdi yeni bir yedek oluşturun';

  @override
  String get backupFolderPath => 'Yedekleme klasörü';

  @override
  String get backupPrivateFolder => 'Özel uygulama klasörü';

  @override
  String get backupRestoreCopy => 'Bu yedeği geri yükle';

  @override
  String get backupDeleteConfirm => 'Seçilen yedekleme silinsin mi?';

  @override
  String get blockedAppsGroup => 'Engellenen uygulamalar';

  @override
  String get notificationSettingsButton => 'Bildirim ayarları';

  @override
  String get hidePersistentNotificationsHint =>
      'Listede ve diğer uygulamalarda kalıcı bildirimleri gizleyin.';

  @override
  String get nightTransitionTime => 'Geçiş zamanı';

  @override
  String get brightnessSolar => 'Gece modu programını kullan';

  @override
  String get brightnessAfterSunrise => 'Güneş doğduktan sonra';

  @override
  String get brightnessAfterSunset => 'Gün batımından sonra';

  @override
  String get brightnessTransitionTime => 'Parlaklık geçiş süresi';

  @override
  String get brightnessSolarUnavailable =>
      'Gece modu programı kullanılamıyor. Saatlerini ve yerini kontrol edin.';

  @override
  String get persistentNotificationCannotDelete =>
      'Bu kalıcı bildirim silinemez. Sadece engelleyebilirsiniz.';

  @override
  String get diagnosticsCreateFailed =>
      'Tanılama raporu oluşturulamadı. Tekrar deneyin.';

  @override
  String get backupListFailed =>
      'Yedekleme listesi yüklenemedi. Seçilen depolamaya erişimi kontrol edin.';

  @override
  String get updateInstallerFailed =>
      'Güncelleme yükleyicisi açılamadı. Tekrar deneyin ve Android yükleyicinin mevcut olup olmadığını kontrol edin.';

  @override
  String get backupFolderFailed =>
      'Yedekleme klasörü seçilemedi veya kaydedilemedi. Erişilebilir bir klasör seçin ve tekrar deneyin.';

  @override
  String get updateDownloadFailed =>
      'Güncelleme indirilemedi. İnternet bağlantınızı ve kullanılabilir depolama alanınızı kontrol edin.';

  @override
  String get backupDeleteFailed =>
      'Yedekleme silinemedi. Silme izinlerini kontrol edip tekrar deneyin.';

  @override
  String get updateCheckFailed =>
      'Güncellemeler kontrol edilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get backupCreateFailed =>
      'Yedekleme oluşturulamadı. Depolama erişimini ve kullanılabilir alanı kontrol edin.';

  @override
  String get wallpaperChangeFailed =>
      'Duvar kağıdı değiştirilemedi. Dosya erişimini kontrol edip tekrar deneyin.';

  @override
  String get backupDownloadsFolder => 'İndirilenler / CuteLauncher';

  @override
  String get backupChooseFolder => 'Dosya yöneticisinde bir klasör seçin';

  @override
  String get backupFolderPickerUnavailable =>
      'Bu TV\'de klasör seçici mevcut değil. İndirilenler / CuteLauncher\'yi veya dahili uygulama klasörünü seçin.';

  @override
  String get driveConfigurationError =>
      'Google Drive kimlik bilgileri eksik veya geçersiz. TV OAuth istemcinizin İstemci Kimliğini ve İstemci Sırrını girin.';

  @override
  String get driveCodeExpired =>
      'Google Drive oturum açma işlemi zaman aşımına uğradı. Yeni bir kod almak için Hesabı kontrol et ve kaydet\'i seçin.';

  @override
  String get brightnessAfterNightStart => 'Gece vakti';

  @override
  String get brightnessAfterNightEnd => 'Gündüz';

  @override
  String get backupSyncSettings => 'Senkronize edilecek ayarlar';

  @override
  String get backupSyncHomeGroup => 'Ana ekran, bölümler ve uygulamalar';

  @override
  String get backupSyncAppearanceGroup => 'Görünüm, duvar kağıtları ve afişler';

  @override
  String get backupSyncDisplayGroup => 'Gece modu, parlaklık ve ekran koruyucu';

  @override
  String get backupSyncControlsGroup => 'Başlatıcı ve TV kontrolleri';

  @override
  String get backupSyncGeneralGroup => 'Dil, güncellemeler ve diğer ayarlar';

  @override
  String get backupSyncGroupsHelp =>
      'Devre dışı bırakılan bloklar bu TV\'ye yerel kalır. Blok seçimi cihazlar arasında senkronize edilir.';

  @override
  String get backupSyncGroupsFailed =>
      'Senkronizasyon için ayar seçimi kaydedilemedi. Tekrar deneyin.';

  @override
  String get tileLayoutMode => 'Döşeme düzeni';

  @override
  String get tileLayoutAuto => 'Döşeme boyutuna göre otomatik';

  @override
  String get tileLayoutColumns => 'Sabit sütun sayısı';

  @override
  String get tileLayoutRows => 'Sabit satır sayısı';

  @override
  String get tileRowCount => 'Satır sayısı';

  @override
  String get useGlobalTileSettings => 'Genel ayarları kullan';

  @override
  String get centerSelection => 'Seçim konumu';

  @override
  String get selectionBottom => 'Alt';

  @override
  String get selectionLower => 'Alt orta';

  @override
  String get selectionCenter => 'Merkez';

  @override
  String get selectionUpper => 'Üst orta';

  @override
  String get selectionTop => 'Üst';

  @override
  String get settingsStyle => 'Ayarlar stili';

  @override
  String get tileFocusEnlargement => 'Odak büyütme';

  @override
  String get tileFocusShadowStrength => 'Gölge gücü';

  @override
  String get tileFocusLift => 'Asansör';

  @override
  String get tileFocusLiftHeight => 'Kaldırma yüksekliği';

  @override
  String get tileFocusBorderColor => 'Kenarlık rengine odaklan';

  @override
  String get tileFocusAccentColor => 'Vurgu rengi';

  @override
  String get tileFocusDynamicColor => 'Dinamik renkler';

  @override
  String get tileSizeFromColumns =>
      'Döşeme boyutu sütun sayısı ve bölüm genişliğine göre belirlenir.';

  @override
  String get resetSectionToGlobal => 'Ayarları paylaşılan değerlere sıfırla';

  @override
  String get resetSectionToGlobalHint =>
      'Paylaşılan bölüm başlıkları, simgeler ve arka plan geri yüklensin ve dolgular sıfırlansın mı?';

  @override
  String get resetStyleSection => 'Bu bölümü sıfırla';

  @override
  String get resetStyleSectionHint =>
      'Yalnızca bu bölüm için varsayılanlar geri yüklensin mi?';

  @override
  String get notificationStyle => 'Bildirim stili';

  @override
  String get styleBackgroundColor => 'Arka plan rengi';

  @override
  String get styleTransparency => 'Arka plan şeffaflığı';

  @override
  String get styleTextSize => 'Metin boyutu';

  @override
  String get styleTextColor => 'Metin rengi';

  @override
  String get noticeSize => 'Bildirim boyutu';

  @override
  String get noticeStylePreview => 'Bildirim önizlemesi';

  @override
  String get backupSyncHomeOptions => 'Davranış ve genel seçenekler';

  @override
  String get backupSyncBackground => 'Arka plan ve özel bannerlar';

  @override
  String get backupSyncTiles => 'Döşeme, menü ve bildirim stili';

  @override
  String get backupSyncWeatherSource => 'Kaynak ve konum';

  @override
  String get backupSyncWeatherDisplay =>
      'Hava durumu ekranı ve sıcaklık birimleri';

  @override
  String get backupSyncNotificationSettings => 'Bildirim ekranı ve filtreler';

  @override
  String get backupSyncOther => 'Diğer ayarlar';

  @override
  String get tileFocusBorderStyle => 'Kenarlık stili';

  @override
  String get tileFocusOutline => 'Taslak';

  @override
  String get tileFocusGlow => 'Parıltı';

  @override
  String get tileFocusNoBorder => 'Sınır yok';

  @override
  String get tileShowFocusShadow => 'Gölgeyi göster';

  @override
  String get homeLayoutRow => 'Yatay sıra';

  @override
  String get homeLayoutRows => 'Çoklu satırlar';

  @override
  String get homeLayoutGrid => 'Izgara';

  @override
  String get homeCardCount => 'Genel olarak görünür kartlar';

  @override
  String get homeAuto => 'Otomatik';

  @override
  String get homeFree => 'Ücretsiz kaydırma';

  @override
  String get homeAnchored => 'Bağlantılı bölüm';

  @override
  String get homeScrollMode => 'Bölüm kaydırma';

  @override
  String get homeSectionPosition => 'Aktif bölüm konumu';

  @override
  String get homeLabelMode => 'Uygulama etiketleri';

  @override
  String get homeLabelNone => 'Etiket yok';

  @override
  String get homeLabelSelected => 'Yalnızca seçilen uygulama';

  @override
  String get homeLabelAll => 'Tüm uygulamalar';

  @override
  String get homeInherited => 'Devralınan değer';

  @override
  String get homeOwnReset => 'Ortak ayarları geri yükle';

  @override
  String get homeParameters => 'Parametreler';

  @override
  String get homeSectionStyle => 'Bölüm görünümü';

  @override
  String get homeSectionGap => 'Bölümler arasındaki boşluk';

  @override
  String get homeSectionIcons => 'Bölüm simgeleri';

  @override
  String get homeInactiveOpacity => 'Etkin olmayan bölüm opaklığı';

  @override
  String get homeResetSection => 'Devralınan bölümün görünümünü geri yükleme';

  @override
  String get homeCalculatedSize => 'Boyut kart sayısına göre hesaplanır';

  @override
  String homeGapLimited(int gap) {
    return 'Seçilen kart sayısını korumak için aralık $gap ile sınırlıdır.';
  }

  @override
  String get homeResetLayout => 'Bölüm düzenini sıfırla';

  @override
  String homeVisibleRows(int count) {
    return 'Tamamen görünür satırlar: $count';
  }

  @override
  String get homeStylePartial =>
      'Yalnızca bu değeri devralan ve onu geçerli düzenlerinde destekleyen bölümler için geçerlidir.';

  @override
  String get homeStyleUnavailable =>
      'Geçerli bölüm ayarlarında mevcut değil. Düzeni ve yerel geçersiz kılmaları kontrol edin.';

  @override
  String get homeStyleNeedsRows =>
      'Birden çok satır veya ızgara için kullanılabilir.';

  @override
  String get homeStyleNeedsLabels =>
      'Etiketlerin boyutunu ve rengini değiştirmesini etkinleştirin.';

  @override
  String get homeStyleNeedsAllLabels =>
      'Konum yalnızca tüm kartlardaki etiketler için geçerlidir. Seçilen başlık bölümün altında kalır.';

  @override
  String get homeStyleNeedsScale => 'Büyütme odak efektini seçin.';

  @override
  String get homeStyleNeedsLift => 'Kaldırma odak efektini seçin.';

  @override
  String get homeStyleNeedsBorder =>
      'Önce bir taslağı veya parlamayı etkinleştirin.';

  @override
  String get homeStyleNeedsTitle =>
      'Simgesini göstermek için bölüm başlığını etkinleştirin.';

  @override
  String get homeStyleEconomy =>
      'Bellek tasarrufu nedeniyle devre dışı bırakıldı. Kaydedilen değer korunur.';

  @override
  String get homeStyleOpaque =>
      'Bulanıklığı görmek için döşeme arka planının opaklığını azaltın.';

  @override
  String get homeStyleOverridden =>
      'Görünür bölümler kendi değerlerini kullanır. Bu ayarı uygulamak için bir bölümde \"Genel kullan\"ı seçin.';

  @override
  String get homeStyleIconHint =>
      'Simge boyutu, uygulama simgesine sahip kartları etkiler. TV afişleri kartı bağımsız olarak doldurur.';

  @override
  String get homeStyleShadowHint =>
      'Bellek tasarrufu, etkin olmayan kartların gölgesini 4 ile sınırlar. Odak gölgesi ayrı olarak yapılandırılır.';

  @override
  String get homeStyleTransparent =>
      'Arka plan rengi sıfır opaklıkta görünmez. Döşeme arka planının opaklığını artırın.';

  @override
  String get homeStyleSingleColumn =>
      'Tek sütunlu ızgarada yatay boşluk yoktur.';

  @override
  String get homeStyleAutoOnly =>
      'Boyut yalnızca genel boyutu devralan Otomatik kart sayımına sahip bölümlerde değişir.';

  @override
  String get sleepTimerThirtySeconds => '30 saniye (test)';

  @override
  String get sleepTimer => 'Uyku zamanlayıcısı';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes dk.';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours saat',
      one: '1 saat',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1,5 saat';

  @override
  String get sleepTimerAllowExact => 'Hassas zamanlayıcılara izin ver';

  @override
  String get sleepTimerExactRequired =>
      'Android ayarlarında hassas zamanlayıcılara izin verin, ardından tekrar bir süre seçin.';

  @override
  String get sleepTimerAccessRequired =>
      'CuteLauncher erişilebilirliğini etkinleştirin veya Ayarlar → Diğer → ADB bölümünden yerel ADB\'yi bağlayın.';

  @override
  String get sleepTimerFailed =>
      'Uyku zamanlayıcısı ayarlanamadı veya tamamlanamadı. Erişilebilirliği ve yerel ADB\'yi kontrol edin.';

  @override
  String get nightIgnoreHdmiInputs => 'HDMI girişlerini yoksay';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'HDMI izlerken gece filtresini duraklatın. Kullanım erişimi gereklidir; giriş tespiti TV donanım yazılımına bağlıdır.';

  @override
  String get inputsSettings => 'Giriş ayarları';

  @override
  String get inputsUseCecNames => 'CEC\'deki cihaz adlarını kullanın';

  @override
  String get inputsNamesHint =>
      'Ad önceliği: CuteLauncher içindeki adınız → CEC (etkinse) → Android ayarlarındaki ad → standart giriş adı.';

  @override
  String get inputNameHint => 'Otomatik ad için boş bırakın';

  @override
  String get inputsSaveFailed => 'Giriş ayarları kaydedilemedi';

  @override
  String get inputIcon => 'Giriş simgesi';

  @override
  String get inputIconTv => 'televizyon';

  @override
  String get inputIconGame => 'Oyun konsolu';

  @override
  String get inputIconComputer => 'Bilgisayar';

  @override
  String get inputIconReceiver => 'Alıcı';

  @override
  String get inputIconDisc => 'Disk oynatıcı';

  @override
  String get inputIconStream => 'Akış cihazı';

  @override
  String get nightInputExclusions => 'Giriş hariç tutmalar';

  @override
  String get nightSelectInputs => 'Yoksayılacak girişleri seçin';

  @override
  String get nightNoInputsSelected =>
      'Hiçbir giriş seçilmedi. Filtre her girişe uygulanacaktır.';

  @override
  String get nightPictureExclusions => 'Resim modu hariç tutmaları';

  @override
  String get nightPictureExclusionsHint =>
      'Karartmayı duraklatan modları, sıcak kaplamayı ve bağlantılı TCL filtreyi seçin. Program korunur. Algılama TCL\'de doğrulandı; kullanım erişimi gerekli değildir.';

  @override
  String get nightPictureUnavailable =>
      'Geçerli resim modu bu cihaz yazılımında mevcut değildir. Seçiminiz kaydedildi; hariç tutmalar yalnızca algılama başarılı olduğunda geçerlidir.';

  @override
  String get nightPictureCurrent => 'Mevcut mod';

  @override
  String get nightPictureRefresh => 'Geçerli modu yenile';

  @override
  String get nightPictureCode => 'Mod kodu';

  @override
  String get nightPictureStandard => 'Standart';

  @override
  String get nightPictureDynamic => 'Dinamik';

  @override
  String get nightPictureMovie => 'Film';

  @override
  String get nightPictureSport => 'Spor';

  @override
  String get nightPictureIntelligent => 'Akıllı';

  @override
  String get nightPictureBright => 'Parlak (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'Standart';

  @override
  String get systemApplications => 'Sistem uygulamaları';

  @override
  String get removeFromCategory => 'Kategoriden kaldır';

  @override
  String get noRemovableCategories =>
      'Bu uygulama herhangi bir bölüme manuel olarak eklenmemiştir. Otomatik bölümler düzenlenemez.';

  @override
  String get remoteButtonsTitle => 'Kumanda tuşlarını yeniden eşleme';

  @override
  String get remoteButtonsStart => 'Tuşları kontrol et (120 sn)';

  @override
  String get remoteButtonsStop => 'Kontrolü durdur';

  @override
  String get remoteButtonsHint =>
      'Kontrol kodları, bırakmaları ve tekrarları gösterir ve TV üzerinde metin raporu kaydeder. OK kaydı yönetmesin diye başlattıktan sonra bu sayfadan çıkın.';

  @override
  String get remoteButtonsEmpty =>
      'Henüz olay yok. Bir tuş uygulama açarsa sonucu görmek için buraya dönün.';

  @override
  String get remoteButtonsService => 'Hizmet bağlı';

  @override
  String get remoteButtonsRefresh => 'Yenile';

  @override
  String get remoteBindings => 'Tuş atamaları';

  @override
  String get remoteMappingsEnabled => 'Yeniden eşlemeyi etkinleştir';

  @override
  String get remoteMappingsAdd => 'Atama ekle';

  @override
  String get remoteMappingKey => 'Tuş';

  @override
  String get remoteMappingAction => 'Eylem';

  @override
  String get remoteMappingLearn => 'Kumanda tuşunu algıla';

  @override
  String get remoteMappingLearnHint =>
      '30 saniye içinde ek bir tuşa basın. Gezinme, Power, sesli arama ve ses düzeyi korunur.';

  @override
  String get remoteMappingsHint =>
      'Atamalar erişilebilirlik hizmetini gerektirir. Düzenleyicide ve tanılama sırasında duraklatılır. Ana ekran, Geri, oklar ve OK gezinmeyi korur.';

  @override
  String get remoteMappingsReset => 'Atamaları sıfırla';

  @override
  String get remoteMappingsResetConfirm =>
      'Tüm atamalar silinsin ve yeniden eşleme kapatılsın mı?';

  @override
  String get remoteMappingInvalid =>
      'Kaydedilemedi. Tuşu ve hedefi kontrol edin. Webhook için HTTPS veya yerel ağda HTTP gerekir.';

  @override
  String get remoteMappingBack => 'Geri';

  @override
  String get remoteMappingProfile => 'Profil';

  @override
  String get remoteMappingChannels => 'Kanallar';

  @override
  String get remoteMappingQuickSettings => 'TCL hızlı ayarları';

  @override
  String get remoteMappingTrigger => 'Basma türü';

  @override
  String get remoteMappingPress => 'Kısa basma';

  @override
  String get remoteMappingHold => 'Basılı tutma';

  @override
  String get remoteMappingHoldHint =>
      '650 ms basılı tutun: kısa eylem olmadan bir kez çalışır. Yalnızca basılı tutma atanmışsa kısa basma hiçbir şey yapmaz.';

  @override
  String get remotePanelDescription =>
      'Yüzen panel, widget’larınızı diğer uygulamaların üzerinde gösterir. Kumandayla açmak için Yüzen panel eylemini istediğiniz bir düğmeye atayın.';

  @override
  String get remotePanel => 'Yüzen panel';

  @override
  String get remotePanelSettingsBackground =>
      'Ayarların arka plan rengini kullan';

  @override
  String get remotePanelPreview => 'Paneli aç';

  @override
  String get settingsHelp => 'Daha fazla bilgi';

  @override
  String get settingsHelpScroll => '▲ / ▼ — metni kaydır';

  @override
  String get panelClockStyle => 'Saat görünümü';

  @override
  String get clockPreset => 'Yazı tipi stili';

  @override
  String get clockCustom => 'Özel';

  @override
  String get clockWeight => 'Yazı kalınlığı';

  @override
  String get clockGlow => 'Metin parlaması';

  @override
  String get clockAnimate => 'Rakam animasyonu';

  @override
  String get clockBackground => 'Saat arka planı';

  @override
  String get clockRadius => 'Arka plan köşe yuvarlaklığı';

  @override
  String get dateCalendarEnabled => 'Tarihe basıldığında takvimi aç';

  @override
  String get calendarTitle => 'Takvim';

  @override
  String get dateSettings => 'Tarih ayarları';

  @override
  String get clockSharedBackground => 'Diğer nesnelerle aynı arka plan';

  @override
  String get clockDefaultBackground => 'Varsayılan arka plan';

  @override
  String get remotePanelInheritAppearance => 'Üst panel görünümünü kullan';

  @override
  String get remotePanelDisabledInLauncher =>
      'CuteLauncher ekrandayken açılır panel devre dışıdır.';

  @override
  String get remoteAccessSettings => 'Erişim ayarları';

  @override
  String get remoteButtonsTest => 'Düğme testi';

  @override
  String get remoteMappingConflict =>
      'Bu düğme ve basma türü zaten atanmış. Başka bir düğme veya basma türü seçin.';

  @override
  String get cleanerTitle => 'TV cleanup manager';

  @override
  String get cleanerRefresh => 'Refresh applications';

  @override
  String get cleanerSnapshot => 'Save original state';

  @override
  String get cleanerRestore => 'Temel durumu geri yükle';

  @override
  String get cleanerSnapshotSaved => 'Original state saved';

  @override
  String get cleanerExportSnapshot => 'Export original state';

  @override
  String get cleanerSafe => 'Disable verified applications';

  @override
  String get cleanerNoSafe =>
      'Bu model ve yazılım için eşleşen sistem uygulama listesi yok.';

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
      'Devre dışı uygulama raporunu dosyaya aktar';

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
      'Temel durum ilk başarılı liste yenilemesinde bir kez oluşturulur; başlatıcıdan silinemez veya üzerine yazılamaz. Yazılıma bağlıdır. Elle kaydedilen durumlar uygulama kiplerini ad ve tarihle saklar; geri yüklenebilir, silinebilir ve dışa aktarılabilir. APK veya uygulama verisi içermezler. Geri yükleme yerel ADB gerektirir. Çökme koruması temeli otomatik geri yüklemeyi dener. Başlatıcı verilerini temizlemek veya başlatıcıyı kaldırmak kopyaları da siler; root erişimi engellenemez.';

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
  String get landscapeDemoStop => 'Durdur';

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
  String get informationGroup => 'Saat, tarih ve hava durumu';

  @override
  String get informationSettings => 'Blok ayarları';

  @override
  String get informationAppearance => 'Blok görünümü';

  @override
  String get informationSize => 'Blok boyutu';

  @override
  String get informationPosition => 'Saat ve metin konumu';

  @override
  String get informationClockLeft => 'Saat solda, metin sağda';

  @override
  String get informationClockRight => 'Metin solda, saat sağda';

  @override
  String get informationSpacing => 'Saat ve metin aralığı';

  @override
  String get informationBackground => 'Blok arka planı';

  @override
  String get homeResetTilesHint =>
      'Bu ekrandaki tüm kutucuk ve etiketler için ortak değerler geri yüklensin mi?';

  @override
  String get homeResetLayoutHint =>
      'Bu bölümün düzeni sıfırlansın, ortak görünümü geri yüklensin ve iç boşlukları kaldırılsın mı? Uygulamalar ve sıraları korunur.';

  @override
  String get networkSummary => 'Ağ';

  @override
  String get networkConnected => 'İnternet kullanılabilir';

  @override
  String get networkOffline => 'İnternet erişimi yok';

  @override
  String get networkDisconnected => 'Bağlı değil';

  @override
  String get networkConnection => 'Bağlantı';

  @override
  String get networkSignal => 'Sinyal';

  @override
  String get networkLinkSpeed => 'Wi-Fi bağlantı hızı';

  @override
  String get networkTrafficRate => 'Cihaz trafiği · alma / gönderme';

  @override
  String get networkSystemSettings => 'Sistem ağ ayarları';

  @override
  String get networkUnavailable => 'Kullanılamıyor';

  @override
  String get networkMobile => 'Mobil ağ';

  @override
  String get networkFrequency => 'Frekans';

  @override
  String get networkMbps => 'Mbps';

  @override
  String get networkKbps => 'KB/sn';

  @override
  String get networkReadFailed => 'Ağ durumu okunamadı';

  @override
  String get clockItalic => 'İtalik';

  @override
  String get panelWrapNavigation => 'Panelde döngüsel gezinme';

  @override
  String get panelWrapNavigationHelp =>
      'Kenarda ok tuşu karşı tarafa geçer. Her iki tarafta ilerlemek için ok tuşunu basılı tutun.';

  @override
  String get networkReceive => 'Alma';

  @override
  String get networkSend => 'Gönderme';

  @override
  String get landscapeCelestialBodies => 'Güneş ve ay';

  @override
  String get landscapeStarRotation => 'Yıldızların dönüşü';

  @override
  String get tvPowerTitle => 'Güç yönetimi';

  @override
  String get tvPowerOff => 'TV’yi kapat';

  @override
  String get tvPowerReboot => 'TV’yi yeniden başlat';

  @override
  String get tvPowerOffConfirm => 'TV beklemeye alınsın mı?';

  @override
  String get tvPowerRebootConfirm =>
      'TV yeniden başlatılsın mı? Açık uygulamalar kapanacak.';

  @override
  String get tvPowerSent => 'Komut gönderildi';

  @override
  String get tvPowerFailed =>
      'Komut gönderilemedi. ADB veya erişilebilirliği kontrol edin.';

  @override
  String get tvPowerHelp =>
      'Kapatma, CuteLauncher erişilebilirlik hizmeti veya yerel ADB ile beklemeyi açar. Yeniden başlatma ADB gerektirir. TV kutusunda kutu kontrol edilir; TV davranışı HDMI-CEC ve yazılıma bağlıdır.';

  @override
  String get cleanerLists => 'Devre dışı bırakma listeleri';

  @override
  String get cleanerRecovery => 'Yedekleme ve geri yükleme';

  @override
  String get cleanerExports => 'Raporlar';

  @override
  String get cleanerUpdating => 'Uygulama listesi güncelleniyor…';

  @override
  String get cleanerRefreshRequired => 'Önce uygulama listesini yenileyin.';

  @override
  String get cleanerPreinstalled => 'Önceden yüklenmiş uygulama';

  @override
  String get cleanerNotSystem => 'Bu bir sistem uygulaması değildir.';

  @override
  String get cleanerMinimalRisk => 'En düşük';

  @override
  String get cleanerCacheFailure => 'Liste sonraki ziyaret için kaydedilemedi.';

  @override
  String get cleanerUserApps => 'Kullanıcı uygulamaları';

  @override
  String get cleanerPreinstalledApps => 'Önceden yüklenmiş uygulamalar';

  @override
  String get cleanerSystemApps => 'Sistem uygulamaları';

  @override
  String get cleanerBaseline => 'Temel başlangıç durumu';

  @override
  String get cleanerManualStates => 'Elle kaydedilen durumları yönet';

  @override
  String get cleanerManualSave => 'Geçerli durumu kaydet';

  @override
  String get cleanerDateName => 'Tarih ve saati kullan';

  @override
  String get cleanerCustomName => 'Ad gir';

  @override
  String get cleanerStateExport => 'Kaydedilen durumu dosyaya aktar';

  @override
  String get cleanerStateRestoreHelp =>
      'Bu yazılım için kaydedilen etkinlik durumları geri yüklenir. Daha sonra kurulan uygulamalar değişmez. Eksik uygulamalar ve korunan bileşenleri devre dışı bırakma atlanır. Uygulama verileri geri yüklenmez.';

  @override
  String get cleanerCopiesHelp =>
      'Temel durum ilk başarılı liste yenilemesinde bir kez oluşturulur; başlatıcıdan silinemez veya üzerine yazılamaz. Yazılıma bağlıdır. Elle kaydedilen durumlar uygulama kiplerini ad ve tarihle saklar; geri yüklenebilir, silinebilir ve dışa aktarılabilir. APK veya uygulama verisi içermezler. Geri yükleme yerel ADB gerektirir. Çökme koruması temeli otomatik geri yüklemeyi dener. Başlatıcı verilerini temizlemek veya başlatıcıyı kaldırmak kopyaları da siler; root erişimi engellenemez.';

  @override
  String get cleanerSearch => 'Ada göre ara';

  @override
  String get cleanerCatalogUpdateRequired =>
      'Önce GitHub kataloğunu yenileyin.';

  @override
  String get cleanerNoSearchResults => 'Eşleşen kayıt yok.';

  @override
  String get cleanerAlreadyDisabled =>
      'Bu listedeki TV’de bulunan tüm uygulamalar zaten devre dışı.';

  @override
  String get cleanerAlreadyEnabled =>
      'Bu listedeki TV’de bulunan tüm uygulamalar zaten etkin.';

  @override
  String get cleanerNoInstalled =>
      'Bu listeden eşleşen bir uygulama bu TV’de yüklü değil.';

  @override
  String get cleanerListProtected =>
      'Kalan uygulamalar devre dışı bırakmaya karşı korunuyor.';

  @override
  String get cleanerSnapshotFailed =>
      'Durum kaydedilemedi. Hiçbir uygulama devre dışı bırakılmadı.';

  @override
  String get cleanerDisableAllPreinstalled =>
      'Önceden yüklenmiş tüm uygulamaları devre dışı bırak';

  @override
  String get cleanerEnableAllPreinstalled =>
      'Önceden yüklenmiş tüm uygulamaları etkinleştir';

  @override
  String get cleanerPreinstalledList => 'Önceden yüklenmiş uygulama listesi';

  @override
  String cleanerBeforeList(String listName) {
    return 'Liste uygulanmadan önce: $listName';
  }

  @override
  String get sleepTimerSettings => 'Uyku zamanlayıcısı ayarları';

  @override
  String get sleepTimerPresets => 'Zamanlayıcılar';

  @override
  String get sleepTimerDisplay => 'Zamanlayıcı etkinken göster';

  @override
  String get sleepTimerRemaining => 'Kalan süre';

  @override
  String get sleepTimerEndTime => 'Kapanma saati';

  @override
  String get sleepTimerBoth => 'Kalan süre ve kapanma saati';

  @override
  String get sleepTimerShowSeconds => 'Saniyeleri göster';

  @override
  String get sleepTimerCloseAfterSelection => 'Seçimden sonra bileşeni kapat';

  @override
  String get sleepTimerAdd => 'Zamanlayıcı ekle';

  @override
  String get sleepTimerEdit => 'Zamanlayıcıyı düzenle';

  @override
  String get sleepTimerHoursLabel => 'Saat';

  @override
  String get sleepTimerMinutesLabel => 'Dakika';

  @override
  String get sleepTimerSecondsLabel => 'Saniye';

  @override
  String get sleepTimerInvalidDuration =>
      'Sıfırdan büyük süre girin: saat 0–999999, dakika ve saniye 0–59.';

  @override
  String get sleepTimerDeleteConfirmation =>
      'Bu zamanlayıcı silinsin mi? Çalışan geri sayım devam eder.';

  @override
  String get sleepTimerResetConfirmation =>
      'Varsayılan zamanlayıcılar ve sıraları geri yüklensin mi? Özel zamanlayıcılar silinir. Çalışan geri sayım devam eder.';

  @override
  String get sleepTimerReorderHint =>
      'Taşımak için ◄ / ► veya OK tuşunu basılı tutun. ▲ / ▼ sırayı değiştirir ve görünür/gizli listeler arasında taşır. OK taşımayı bitirir.';

  @override
  String get sleepTimerSaveFailed => 'Zamanlayıcı ayarları kaydedilemedi.';

  @override
  String get sleepTimerVisible => 'Görünen';

  @override
  String get sleepTimerHidden => 'Gizli';

  @override
  String get sleepTimerReset => 'Zamanlayıcıları sıfırla';

  @override
  String get cleanerListSnapshotHelp =>
      'Listeyi devre dışı bırakmadan önce yalnızca seçilen uygulamalar kaydedilir. Geri yüklemek diğer uygulamaları değiştirmez. Sınır 100 elle ve otomatik kayıttır. Kayıt başarısızsa devre dışı bırakma başlamaz.';

  @override
  String get trafficSettings => 'Trafik ayarları';

  @override
  String get trafficTitle => 'Trafik';

  @override
  String get trafficReceived => 'Alınan';

  @override
  String get trafficSent => 'Gönderilen';

  @override
  String get trafficTotal => 'Toplam';

  @override
  String get stopApp => 'Durdur';

  @override
  String get backgroundImageFormats =>
      'Resimler: JPEG, PNG, WebP, GIF, BMP — en fazla 8 MiB, 48 megapiksel ve her kenarda 16.384 piksel.';

  @override
  String get backgroundMediaFormats =>
      'Resimler: JPEG, PNG, WebP, GIF, BMP — en fazla 8 MiB, 48 megapiksel ve her kenarda 16.384 piksel.\nVideo: MP4/M4V, WebM, MKV — en fazla 256 MiB ve 3840×2160. Kodek desteği TV’ye bağlıdır; H.264 içeren MP4 önerilir. Sessiz tekrarlanır, Ana Ekran dışında duraklatılır. Videolar yedeklere dahil edilmez.';

  @override
  String get backgroundFormatError =>
      'Desteklenmeyen biçim veya bozuk dosya. Belirtilen biçimlerden geçerli bir dosya seçin.';

  @override
  String backgroundFileTooLarge(String maxMiB) {
    return 'Dosya çok büyük. En fazla $maxMiB MiB. Daha küçük bir dosya seçin.';
  }

  @override
  String get backgroundImageResolutionError =>
      'Resim çok büyük: en fazla 48 megapiksel ve her kenarda 16.384 piksel.';

  @override
  String get backgroundVideoResolutionError =>
      'Video çözünürlüğü çok yüksek. En fazla 3840×2160 (veya 2160×3840) seçin.';

  @override
  String get backgroundVideoCodecError =>
      'TV videoyu oynatamadı: kodek desteklenmiyor veya dosya bozuk. H.264 içeren MP4 deneyin.';

  @override
  String get backgroundFileApplied => 'Dosya seçildi. Arka plan güncellendi.';

  @override
  String get noticePosition => 'Bildirim konumu';

  @override
  String get noticeBottomRight => 'Sağ alt';

  @override
  String get noticeBottomLeft => 'Sol alt';

  @override
  String get noticeTopRight => 'Sağ üst';

  @override
  String get noticeTopLeft => 'Sol üst';

  @override
  String get notificationOpenFailed =>
      'Bildirim eylemi açılamadı. Artık kullanılamıyor olabilir.';

  @override
  String get adbWifiOverride => 'Yine de devre dışı bırak…';

  @override
  String get adbWifiRiskTitle => 'Riske rağmen devre dışı bırakılsın mı?';

  @override
  String get adbWifiRiskEffect =>
      'Yerleşik başlatıcı ve Google kurulum sihirbazı devre dışı bırakılacak.';

  @override
  String get adbWifiRiskLoss =>
      'Android kayıtlı Wi-Fi ağlarını silebilir. Wi-Fi bağlantısı ve kablosuz ADB kullanılamayabilir.';

  @override
  String get adbWifiRiskRecovery =>
      'Sihirbazı yeniden etkinleştirmek silinen ağları otomatik olarak geri getirmez. Wi-Fi ağına yeniden bağlanıp şifreyi girmeniz gerekir.';

  @override
  String get adbWifiRiskConsent =>
      'Yalnızca Wi-Fi şifresini biliyorsanız devam edin.';

  @override
  String get adbWifiDisable => 'Devre dışı bırak';
}
