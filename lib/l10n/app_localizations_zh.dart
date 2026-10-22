// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

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
  String get backgroundSource => '背景来源';

  @override
  String get noAvailableCategories => '没有可用于添加此应用程序的部分。';

  @override
  String get redditWallpaperTheme => '壁纸主题';

  @override
  String get redditThemeAll => '混合';

  @override
  String get redditThemeNature => '自然';

  @override
  String get redditThemeSpace => '空间';

  @override
  String get redditThemeCity => '城市';

  @override
  String get redditThemeMinimal => '极简主义';

  @override
  String get redditWallpaperResolution => '最小分辨率';

  @override
  String get redditWallpaperHint =>
      '每次成功刷新都会从选定的 Reddit 社区下载不同的风景图像。分辨率是最小原稿尺寸；图像未放大。刷新在启动器打开时运行，并在您返回时恢复。成人内容、视频和画廊将被跳过。如果 Reddit 阻止访问或找不到匹配的图像，则保留之前的壁纸。';

  @override
  String get dialogCommandDetails => '显示 ADB 命令';

  @override
  String get dialogAssign => '分配';

  @override
  String get dialogApply => '申请';

  @override
  String get settingsValueNotSet => '未设置';

  @override
  String get settingsMenuPosition => '设置菜单位置';

  @override
  String get settingsMenuLeft => '左';

  @override
  String get settingsMenuRight => '右';

  @override
  String get actionCompleted => '行动已完成';

  @override
  String get showRepositoryQrCode => '显示二维码';

  @override
  String get resetSections => '重置部分设置';

  @override
  String get resetSectionsConfirmation => '恢复默认部分？自定义部分、间隔和收藏夹内容将被删除。';

  @override
  String get cardFocusMode => '专注回国';

  @override
  String get cardFocusRemember => '保留所选卡';

  @override
  String get cardFocusFirst => '第一张卡';

  @override
  String get cardFocusSettings => '设置按钮';

  @override
  String get aboutFlauncher => '关于 CuteLauncher';

  @override
  String get addCategory => '添加类别';

  @override
  String get addSection => '添加分区';

  @override
  String get alphabetical => '按字母顺序';

  @override
  String get appCardHighlightAnimation => '应用卡片高亮动画';

  @override
  String get appInfo => '应用信息';

  @override
  String get appKeyClick => '按键提示音';

  @override
  String get applications => '应用';

  @override
  String get autoHideAppBar => '自动隐藏状态栏';

  @override
  String get backButtonAction => '返回键行为';

  @override
  String get category => '类别';

  @override
  String get categories => '类别';

  @override
  String get columnCount => '列数';

  @override
  String get date => '日期';

  @override
  String get dateAndTimeFormat => '日期和时间格式';

  @override
  String get delete => '删除';

  @override
  String get dialogOptionBackButtonActionDoNothing => '无操作';

  @override
  String get dialogOptionBackButtonActionShowScreensaver => '显示屏保';

  @override
  String get dialogOptionBackButtonActionShowClock => '显示时钟';

  @override
  String get dialogTextNoFileExplorer => '请安装文件管理器以选择图片。';

  @override
  String get dialogTitleBackButtonAction => '选择返回键行为';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title（类别）';
  }

  @override
  String formattedDate(String dateString) {
    return '格式化日期：$dateString';
  }

  @override
  String formattedTime(String timeString) {
    return '格式化时间：$timeString';
  }

  @override
  String get gradient => '渐变';

  @override
  String get favoriteApps => '收藏应用';

  @override
  String get grid => '网格';

  @override
  String get height => '高度';

  @override
  String get hide => '隐藏';

  @override
  String get hiddenApplications => '已隐藏应用';

  @override
  String get launcherSections => '分区';

  @override
  String get layout => '布局';

  @override
  String get loading => '加载中';

  @override
  String get manual => '手动';

  @override
  String get modifySection => '修改分区';

  @override
  String get mustNotBeEmpty => '不能为空';

  @override
  String get name => '名称';

  @override
  String get newSection => '新建分区';

  @override
  String get noDateFormatSpecified => '未指定日期格式';

  @override
  String get noTimeFormatSpecified => '未指定时间格式';

  @override
  String get nonTvApplications => '非电视应用';

  @override
  String get open => '打开';

  @override
  String get orSelectFormatSpecifiers => '或选择格式说明符';

  @override
  String get openImage => '打开图片';

  @override
  String get picture => '图片';

  @override
  String removeFrom(String name) {
    return '从$name中移除';
  }

  @override
  String get renameCategory => '重命名类别';

  @override
  String get reorder => '重新排序';

  @override
  String get row => '行';

  @override
  String get rowHeight => '行高';

  @override
  String get save => '保存';

  @override
  String get spacer => '间隔';

  @override
  String get spacerMaxHeightRequirement => '必须大于 0 且小于等于 500';

  @override
  String get statusBar => '状态栏';

  @override
  String get settings => '设置';

  @override
  String get show => '显示';

  @override
  String get showCategoryTitles => '显示类别标题';

  @override
  String get themes => '主题';

  @override
  String get hideHighlightOutlineOnHomescreen => '在主屏幕隐藏高亮边框';

  @override
  String get appSelectorTransitionAnimation => '应用选择器转场动画';

  @override
  String get sort => '排序';

  @override
  String get systemSettings => '系统设置';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => '此类别为空。';

  @override
  String get time => '时间';

  @override
  String get titleStatusBarSettingsPage => '选择状态栏中显示的内容';

  @override
  String get tvApplications => '电视应用';

  @override
  String get type => '类型';

  @override
  String get typeInTheDateFormat => '输入日期格式';

  @override
  String get typeInTheHourFormat => '输入时间格式';

  @override
  String get uninstall => '卸载';

  @override
  String get wallpaper => '壁纸';

  @override
  String get withEllipsisAddTo => '添加到…';

  @override
  String get timeBasedWallpaper => '按时间切换壁纸';

  @override
  String get pickDayWallpaper => '选择日间壁纸';

  @override
  String get pickNightWallpaper => '选择夜间壁纸';

  @override
  String get accessibility => '无障碍';

  @override
  String get defaultLauncherIsDefault => 'CuteLauncher 是默认桌面';

  @override
  String get defaultLauncherNotDefault => 'CuteLauncher 不是默认桌面';

  @override
  String get setAsDefaultLauncher => '设为默认桌面';

  @override
  String get defaultLauncherDescription =>
      '设为默认桌面后，按 Home 键将始终返回 CuteLauncher。电视开机也会直接进入 CuteLauncher。';

  @override
  String get inputs => '输入源';

  @override
  String get inputsUnavailableHint =>
      '该设备不提供可用的输入。开关被禁用并且图标被隐藏。在电视盒上，此选项不控制所连接电视的 HDMI 输入。';

  @override
  String get inputSources => '输入源';

  @override
  String get backupAndRestore => '备份与恢复';

  @override
  String get exportBackup => '导出备份';

  @override
  String get importBackup => '导入备份';

  @override
  String exportSuccess(String path) {
    return '备份已成功导出到 $path';
  }

  @override
  String get importSuccess => '备份导入成功';

  @override
  String get importConfirm => '确定要导入备份吗？这将会覆盖你当前的设置和布局。';

  @override
  String get importError => '无法从备份恢复设置。检查文件并重试。';

  @override
  String exportError(String error) {
    return '导出备份失败：$error';
  }

  @override
  String get shareBackup => '共享备份';

  @override
  String get shareBackupDescription => '与局域网中的其他设备共享备份';

  @override
  String get stopSharing => '停止共享';

  @override
  String get localNetworkSharingActive => '局域网共享已开启！';

  @override
  String get localNetworkSharingInstructions =>
      '将另一台设备连接到同一 Wi-Fi 网络，并在浏览器中打开以下地址：';

  @override
  String get localNetworkSharingDetails => '你可以在此下载电视的设置/布局，或将备份文件上传回这台电视。';

  @override
  String failedToStartServer(String error) {
    return '启动共享服务失败：$error';
  }

  @override
  String get notificationBell => '通知铃铛';

  @override
  String get autoHideNotificationBell => '自动隐藏通知铃铛';

  @override
  String get continueWatching => '继续观看';

  @override
  String get showContinueWatchingOnHome => '在主页显示「继续观看」';

  @override
  String get permissionDeniedContinueWatching => '显示「继续观看」需要权限';

  @override
  String get interface => '界面';

  @override
  String get system => '系统';

  @override
  String get accentColor => '强调色';

  @override
  String get miscellaneous => '其他';

  @override
  String get brightnessScheduler => '亮度定时';

  @override
  String get screensaverSettings => '屏保设置';

  @override
  String get screensaverClockStyle => '屏保时钟样式';

  @override
  String get dataUsagePeriod => '数据使用周期';

  @override
  String get notificationAccess => '通知访问权限';

  @override
  String get granted => '已授予';

  @override
  String get permissionRequired => '需要权限';

  @override
  String get systemWidePopupAlert => '全局弹窗提醒';

  @override
  String get overlayPermissionRequired => '需要悬浮窗权限';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已禁用';

  @override
  String get showAppNamesBelowIcons => '在图标下方显示应用名称';

  @override
  String get dataUsage => '数据使用';

  @override
  String get networkIndicator => '网络指示器';

  @override
  String get homeButtonFix => 'Home 键修复（Google TV）';

  @override
  String get startOnBoot => '开机时启动 (Google TV / Fire TV)';

  @override
  String get appLanguage => '语言';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get english => '英语';

  @override
  String get spanish => '西班牙语';

  @override
  String get ukrainian => '乌克兰语';

  @override
  String get chinese => '中文';

  @override
  String get french => '法语';

  @override
  String get german => '德语';

  @override
  String get japanese => '日语';

  @override
  String get portuguese => '葡萄牙语';

  @override
  String get russian => '俄语';

  @override
  String get italian => '意大利语';

  @override
  String get hindi => '印地语';

  @override
  String get korean => '韩语';

  @override
  String get arabic => '阿拉伯语';

  @override
  String get turkish => '土耳其语';

  @override
  String get hidePersistentNotifications => '隐藏常驻通知';

  @override
  String get hidePersistentNotificationsDesc => '隐藏后台服务和系统常驻通知';

  @override
  String get blockedNotificationApps => '已屏蔽的应用';

  @override
  String get blockAppNotifications => '屏蔽通知';

  @override
  String get unblockAppNotifications => '取消屏蔽通知';

  @override
  String get noBlockedApps => '暂无已屏蔽的应用';

  @override
  String get persistentNotification => '常驻';

  @override
  String get unblockAll => '全部取消屏蔽';

  @override
  String get weather => '天气';

  @override
  String get showWeatherWarnings => '显示降雨及天气预警';

  @override
  String get temperatureUnit => '温度单位';

  @override
  String get celsius => '摄氏度 (°C)';

  @override
  String get fahrenheit => '华氏度 (°F)';

  @override
  String get breezyWeatherSetupHint =>
      '安装 Breezy Weather 并在其设置中开启“本地数据共享”/“Gadgetbridge”以显示天气和降雨预警。';

  @override
  String get displayAndScreensaver => '显示与屏幕保护程序';

  @override
  String get notifications => '通知';

  @override
  String get continueWatchingDescription => '在主屏幕上显示支持的应用最近观看的电影和电视剧';

  @override
  String get continueWatchingPermissionDesc => '需要特殊权限才能读取电视应用的观看历史记录：';

  @override
  String get requestPermission => '请求权限';

  @override
  String get dismiss => '关闭';

  @override
  String get openApp => '打开';

  @override
  String get notificationOptions => '通知选项';

  @override
  String get noBlockedAppsDesc => '当前所有应用均允许显示通知';

  @override
  String get notificationsAllowed => '允许通知';

  @override
  String get notificationsBlocked => '已屏蔽通知';

  @override
  String get dpadDismissHint => '左键: 关闭 • 确定: 选项';

  @override
  String get watchNextDeleteError => '无法从“继续观看”中删除该项目。再试一次。';

  @override
  String get hideLauncherTile => '在应用程序网格中隐藏 CuteLauncher';

  @override
  String get hideAndroidSettingsTile => '在应用程序磁贴中隐藏 Android 设置';

  @override
  String get animateTileReordering => '动画图块重新排序';

  @override
  String get imageInputRejected => '该图像已损坏或太大（最大 8 MiB 和 48 兆像素）。选择另一张图像。';

  @override
  String get memoryTitle => '内存';

  @override
  String get memoryRefresh => '测量内存';

  @override
  String get memoryMeasuring => '测量…';

  @override
  String get memoryClear => '清除图像缓存';

  @override
  String get memorySaver => '节省内存';

  @override
  String get memorySaverDescription =>
      '节省内存模式：\n\n• 减少图像缓存和海报预加载窗口。\n• 禁用图块、面板和壁纸背景模糊以及轮廓脉冲。\n• 限制未聚焦图块上的阴影。\n• 当应用程序进入后台时清除缓存。\n\n当启用内存节省时，这些效果在设置中不可用。当模式被禁用时，它们保存的值会返回。图像可能会更频繁地重新加载。';

  @override
  String get memoryPss => '进程共享（PSS）';

  @override
  String get memoryRss => '驻留进程内存（RSS）';

  @override
  String get memoryEncodedCache => '缓存的图像文件';

  @override
  String get memoryDecodedCache => '缓存的解码图像';

  @override
  String get memoryUnavailable => '不可用';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => '测量于';

  @override
  String get memoryExplanation =>
      'PSS 和 RSS 重叠：不要将它们加在一起。缓存大小是应用程序内存的一部分，并不描述活动图像所占用的所有内存。清除缓存会保留您的设置和文件；需要时再次加载图像。 Android 可能会稍后返回内存。这里的RSS来自内核，PSS来自Android；它们对图形内存的解释可能不同。';

  @override
  String get memoryRecommendations => '为了减少内存，启用保存，显示更少的继续观看卡并使用较小的壁纸或渐变。';

  @override
  String get memoryMeasurementFailed => '过程测量不可用。缓存信息仍然显示。';

  @override
  String get addToCategory => '添加到类别';

  @override
  String get addToFavorites => '添加到收藏夹';

  @override
  String get removeFromFavorites => '从收藏夹中删除';

  @override
  String get setCustomBanner => '设置自定义横幅';

  @override
  String get clearCustomBanner => '清晰的自定义横幅';

  @override
  String get bannerSetFailed => '无法设置横幅。检查对图像的访问并再次选择文件。';

  @override
  String get bannerClearFailed => '无法删除自定义横幅。再试一次。';

  @override
  String get grantUsagePermission => '授予使用权限';

  @override
  String get removeFromContinueWatching => '从继续观看中删除';

  @override
  String hideAllFromApp(String appName) {
    return '隐藏 $appName 中的所有内容';
  }

  @override
  String get playResume => '播放/继续';

  @override
  String openNamedApp(String appName) {
    return '打开$appName';
  }

  @override
  String get selectedAccent => '选定的口音';

  @override
  String get homeButtonFixHint =>
      '如果您使用的是 Google TV，请在辅助功能设置下启用“主页按钮修复”，以使主页按钮打开此启动器。';

  @override
  String get accessibilityPermission => '无障碍许可';

  @override
  String get shareFailed => '分享失败';

  @override
  String shareBackupError(String error) {
    return '无法共享备份：$error';
  }

  @override
  String get exportComplete => '导出成功';

  @override
  String get exportFailed => '无法保存备份。检查文件夹访问权限和可用存储空间。';

  @override
  String backupLoadError(String error) {
    return '加载备份时出错：$error';
  }

  @override
  String get noBackupFiles => '未找到备份文件。';

  @override
  String get importComplete => '导入成功';

  @override
  String get importFailed => '导入失败';

  @override
  String get importAction => '进口';

  @override
  String get continueWatchingApps => '继续观看应用程序';

  @override
  String get blockedContinueWatching => '被阻止继续观看';

  @override
  String get allAppsCanContinueWatching => '所有支持的应用程序都可以在“继续观看”中显示项目。';

  @override
  String get unblockApp => '解锁';

  @override
  String get unblockAllApps => '解锁所有应用程序';

  @override
  String get appsWithContinueWatching => '具有“继续观看”功能的应用';

  @override
  String get watchNextAppsHint => '目前在主屏幕上提供观看下一个项目的应用';

  @override
  String get noWatchNextApps =>
      '目前没有应用程序提供“继续观看”项目。\n当支持的应用程序（例如 SmartTube 或流媒体服务）添加项目时，它们将出现在此处。';

  @override
  String get allInstalledApps => '所有已安装的应用程序';

  @override
  String get blockWatchNextHint => '关闭以阻止任何应用添加项目以继续观看';

  @override
  String get cardSize => '卡片尺寸';

  @override
  String get maximumItems => '最大物品数';

  @override
  String get playbackProgressBar => '播放进度条';

  @override
  String get playbackPercentage => '播放百分比';

  @override
  String get episodeVideoDetails => '剧集和视频详细信息';

  @override
  String get restoreHiddenPrograms => '恢复隐藏程序';

  @override
  String get allHiddenProgramsRestored => '所有隐藏程序均已恢复';

  @override
  String get watchNextAccessAdb => '观看下一个访问（需要 ADB）';

  @override
  String get supportLtvLauncher => '支持LTvLauncher';

  @override
  String get scanToDonate => '用手机摄像头扫描即可捐赠：';

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String get close => '关闭';

  @override
  String get launcherAuthor => 'CuteLauncher 由 Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Android TV 发射器基于 LeanBitLab 的 LTvLauncher 和 Étienne Fesser 的 FLauncher。根据 GNU GPLv3 许可。';

  @override
  String get projectCredits => '项目与学分';

  @override
  String get launcherRepository => 'CuteLauncher 存储库';

  @override
  String get originalProject => '原始项目：LTvLauncher';

  @override
  String get noInputsDetected => '未检测到输入';

  @override
  String get reorderSectionsHint =>
      '使用 ◄ / ► 选择，然后使用 ▲ / ▼ 重新排序。跨越列表边界可隐藏或显示某个部分。';

  @override
  String get customName => '自定义名称';

  @override
  String get mostUsed => '发射频率';

  @override
  String get lastUsed => '最后使用';

  @override
  String get clearAll => '全部清除';

  @override
  String get allCaughtUp => '都追上了！';

  @override
  String get notificationAccessAdb => '通知访问（需要 ADB）';

  @override
  String get openAppInfo => '打开应用程序信息';

  @override
  String get overlayPermission => '叠加权限';

  @override
  String get clockMinimal => '最小';

  @override
  String get clockMinimalDescription => '细而优雅的字体（默认）';

  @override
  String get clockBold => '大胆';

  @override
  String get clockBoldDescription => '字体厚实、高度可见';

  @override
  String get clockRetro => '复古';

  @override
  String get clockRetroDescription => '等宽、复古终端风格';

  @override
  String get clockElegant => '优雅';

  @override
  String get clockElegantDescription => '经典衬线字体';

  @override
  String get clockNeon => '霓虹灯';

  @override
  String get clockNeonDescription => '超薄发光风格';

  @override
  String get clockPixel => '像素';

  @override
  String get clockPixelDescription => '大胆的等宽，街机感觉';

  @override
  String get clockDigital => '数码';

  @override
  String get clockDigitalDescription => '干净的等宽显示';

  @override
  String get themeDefault => '默认';

  @override
  String get themePremium => '高级版';

  @override
  String get themeClassic => '经典';

  @override
  String get themeCapsule => '胶囊';

  @override
  String get cancel => '取消';

  @override
  String get actionCancelled => '行动已取消';

  @override
  String get ok => '好的';

  @override
  String get accessibilityGuide =>
      '手动打开电视设置，然后辅助功能 → CuteLauncher Home Button Fix，并启用该服务。此菜单的位置和名称取决于您的电视制造商。';

  @override
  String get notificationPermissionGuide =>
      '无法在此电视上打开通知访问设置。在应用程序信息中允许传出通知不会授予对来自其他应用程序的通知的访问权限。\n\n通过 ADB 连接电视并运行：';

  @override
  String get overlayPermissionGuide =>
      '覆盖权限设置无法自动打开。\n\n要在其他应用程序上启用弹出窗口，请通过 ADB 连接电视并运行：';

  @override
  String get watchNextPermissionGuide =>
      '要从其他应用程序读取“继续观看”卡，Android TV 需要 READ_WRITE_WATCH_NEXT_PROGRAMS。\n\n通过 ADB 连接电视并运行：';

  @override
  String get watchNextAccess => '继续观看访问';

  @override
  String itemsCount(int count) {
    return '$count 项目';
  }

  @override
  String displayUpToItems(int count) {
    return '显示最多 $count 最近的项目';
  }

  @override
  String get unlimitedItems => '无限';

  @override
  String get allAvailableItems => '显示所有可用项目';

  @override
  String get defaultOption => '默认';

  @override
  String get manage => '管理';

  @override
  String blockedCount(int count) {
    return '$count 已被阻止';
  }

  @override
  String hiddenCount(int count) {
    return '$count 隐藏';
  }

  @override
  String blockedWatchNextCount(int count) {
    return '被阻止继续观看 ($count)';
  }

  @override
  String get sizeExtraSmall => '特小号';

  @override
  String get sizeVerySmall => '很小';

  @override
  String get sizeSmall => '小号';

  @override
  String get sizeCompact => '紧凑型';

  @override
  String get sizeMediumSmall => '中小号';

  @override
  String get sizeMedium => '中等';

  @override
  String get sizeStandardDefault => '标准（默认）';

  @override
  String get sizeMediumLarge => '中号 大号';

  @override
  String get sizeLarge => '大号';

  @override
  String get sizeVeryLarge => '非常大';

  @override
  String get sizeExtraLarge => '特大号';

  @override
  String get sizeHuge => '巨大的';

  @override
  String get tvApps => '电视应用程序';

  @override
  String get nonTvApps => '非电视应用';

  @override
  String get moviesShows => '电影和节目';

  @override
  String get music => '音乐';

  @override
  String get games => '游戏';

  @override
  String get entertainment => '娱乐';

  @override
  String get liveTv => '电视直播';

  @override
  String get sports => '体育运动';

  @override
  String get news => '新闻动态';

  @override
  String get tools => '工具';

  @override
  String get favorites => '收藏夹';

  @override
  String get customSectionName => '定制...';

  @override
  String get selectSectionName => '选择一个名字';

  @override
  String get weeklyUsage => '每周：';

  @override
  String get monthlyUsage => '每月：';

  @override
  String get dailyUsage => '每日：';

  @override
  String get appError => '出了点问题';

  @override
  String get weatherRain => '雨';

  @override
  String get weatherSnow => '雪';

  @override
  String get weatherStorm => '风暴';

  @override
  String get weatherToday => '今天';

  @override
  String get weatherTomorrow => '明天';

  @override
  String weatherOnDay(String day) {
    return '在 $day 上';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'CuteLauncher 备份';

  @override
  String get noApplicationsFound => '没有找到应用程序';

  @override
  String get invalidDateFormat => '格式无效';

  @override
  String get selectDateFormats => '选择下面的格式';

  @override
  String activeItemsCount(int count) {
    return '$count 活动项目';
  }

  @override
  String get colorPurple => '紫色';

  @override
  String get colorTeal => '青色';

  @override
  String get colorBlue => '蓝色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorPink => '粉色';

  @override
  String get colorGreen => '绿色';

  @override
  String get colorWhite => '白色';

  @override
  String get colorYellow => '黄色';

  @override
  String get colorRed => '红色';

  @override
  String get colorCyan => '青色';

  @override
  String get colorIndigo => '靛蓝';

  @override
  String get colorLime => '石灰';

  @override
  String get colorAmber => '琥珀色';

  @override
  String get colorRose => '玫瑰';

  @override
  String get colorIceBlue => '冰蓝色';

  @override
  String get memoryFeatures => '按功能划分的内存（缓存）';

  @override
  String get memoryAppIcons => '应用程序图标';

  @override
  String get memoryAppBanners => '应用横幅';

  @override
  String get memoryWatchNextPosters => '继续观看海报';

  @override
  String get memoryOtherCaches => '其他编码图像缓存';

  @override
  String get memoryFeaturesExplanation =>
      '这些是保留的图像字节，已包含在编码缓存总数中。零意味着该缓存中没有保留字节，而不是该功能不使用内存。壁纸和显示图片共享上面的解码缓存；活动图像可能位于其外部。天气、通知、Dart 对象和引擎无法在此处按功能拆分。共享界面图形由 Android 报告，并已包含在 PSS 中。他们的记忆是整个过程的一部分。不要添加这些重叠的值。';

  @override
  String get memoryGraphics => '界面图形（包含在PSS中）';

  @override
  String get categoryVisible => '显示类别';

  @override
  String get hiddenCategories => '隐藏类别';

  @override
  String get visibleCategories => '可见类别';

  @override
  String get backupSavedToSelectedLocation => '备份保存到所选位置';

  @override
  String get tileHorizontalGap => '水平间距';

  @override
  String get tileVerticalGap => '垂直间距';

  @override
  String get tileOpacity => '背景不透明度';

  @override
  String get tileShadow => '影子';

  @override
  String get tileCornerRadius => '圆角';

  @override
  String get tileIconScale => '图标大小';

  @override
  String get tileBackgroundColor => '平铺背景';

  @override
  String get tileLabelSize => '标签尺寸';

  @override
  String get resetAppearance => '重置外观';

  @override
  String get tileAppearance => '瓷砖外观';

  @override
  String get tileLabelColor => '标签颜色';

  @override
  String get tilePreviewName => '示例应用程序';

  @override
  String get tileProportions => '瓷砖比例';

  @override
  String get tileLarge => '大号';

  @override
  String get tileLabelBelow => '瓷砖下方';

  @override
  String get tileLabelInside => '瓷砖里面';

  @override
  String get tileFocusScale => '放大';

  @override
  String get tileMedium => '中等';

  @override
  String get tileFocusBorder => '无动静';

  @override
  String get tileSize => '瓷砖尺寸';

  @override
  String get tileCompact => '紧凑型';

  @override
  String get tileLabelPosition => '标签位置';

  @override
  String get tileFocusEffect => '聚焦效果';

  @override
  String get tileFocusStrength => '突出显示强度';

  @override
  String get panelIndependent => '自定义设置';

  @override
  String get panelAppearance => '顶板样式';

  @override
  String get panelBackground => '面板背景';

  @override
  String get blurPerformanceHint => '模糊可能会降低平滑度。当内存节省打开时，它被禁用。';

  @override
  String get panelOpacity => '面板不透明度';

  @override
  String get tileBlur => '瓷砖后面模糊';

  @override
  String get panelBlur => '顶部面板后面模糊';

  @override
  String get panelShared => '喜欢面板';

  @override
  String get weatherMinutes => '分钟';

  @override
  String get weatherOpenMeteoCredit =>
      '天气：Open-Meteo (open-meteo.com)，CC BY 4.0。免费 API 用于非商业用途。';

  @override
  String get weatherRateLimit => '已达到请求限制。稍后再尝试。';

  @override
  String get weatherYandexCredit =>
      '天气：Yandex 天气 (yandex.ru/pogoda)。访问权限取决于您的 API 计划。';

  @override
  String get yandexWeather => 'Yandex 天气（休息）';

  @override
  String get weatherAuthorizationError => '气象提供商拒绝了该请求。检查 API 密钥并访问所选服务。';

  @override
  String get weatherYandexHint => '需要具有 REST 预测访问权限的密钥。另一个 Yandex 计划的密钥可能不起作用。';

  @override
  String get weatherSource => '天气来源';

  @override
  String get weatherInterval => '更新间隔';

  @override
  String get weatherLongitude => '经度（-180 至 180）';

  @override
  String get weatherKeyRequired => '添加 Yandex API 密钥。';

  @override
  String get weatherLocationName => '城市名称（可选）';

  @override
  String get weatherLocation => '地点';

  @override
  String get weatherApiKey => 'Yandex API 密钥';

  @override
  String get weatherInvalidResponse => '天气源返回无效数据。';

  @override
  String get weatherUnavailable => '天气不可用。如果有的话，先前接收到的数据将被保留。重试次数限制为每 5 分钟一次。';

  @override
  String get weatherStale => '以往天气';

  @override
  String get weatherLatitude => '纬度（-90 至 90）';

  @override
  String get weatherCoordinatesError => '手动输入城市或自动获取坐标。';

  @override
  String get weatherRefresh => '检查更新';

  @override
  String get weatherKeyPrivate => '仅存储在此设备上，不包含在备份中。空输入将删除密钥。';

  @override
  String get weatherUpdated => '已更新';

  @override
  String get onlineWallpaperError => '无法加载该图像。保留以前的壁纸。选择“检查更新”以重试下载。';

  @override
  String get onlineWallpaperHint => '最后一张图片会保留，以便离线使用（最大 8 MiB）。';

  @override
  String get onlineWallpaperHours => '小时';

  @override
  String get onlineWallpaperInterval => '下载间隔';

  @override
  String get onlineWallpaper => '在线壁纸';

  @override
  String get onlineWallpaperUrlError => '输入直接 HTTPS 图像 URL，无需登录详细信息。';

  @override
  String get onlineWallpaperEnabled => '使用在线壁纸';

  @override
  String get onlineWallpaperSource => '图片来源';

  @override
  String get bingWallpaper => 'Bing 当天图片';

  @override
  String get onlineWallpaperUrlSource => '直销 HTTPS URL';

  @override
  String get updatePlayOnly => '此安装通过 Google Play 接收更新。';

  @override
  String get updateCheck => '立即查看';

  @override
  String get updateInstalled => '已安装';

  @override
  String get updateDownloadInstall => '下载并安装';

  @override
  String get updateNoRelease => '没有更新的兼容版本可用。';

  @override
  String get updateIncompatible => 'APK 与此应用程序、证书或更新版本不匹配。安装被阻止。';

  @override
  String get updateError => '无法检查、下载或打开安装程序。稍后再试。';

  @override
  String get updateAvailable => '可用更新';

  @override
  String get appUpdates => '应用程序更新';

  @override
  String get updatePermission => '在 Android 设置中允许从此应用程序进行安装，返回此处并再次按“安装”。';

  @override
  String get updateInstall => '安装下载的更新';

  @override
  String get updateHint =>
      '来源：GitHub / KirillShchetinnikov/CuteLauncher-Releases。启动器打开时会运行自动检查。选择后开始下载； Android 要求您确认安装。您的数据将被保留。';

  @override
  String get updateAutomatic => '每天自动检查一次';

  @override
  String get allApplications => '所有应用程序';

  @override
  String get adbAccessibility => '启用主页按钮修复';

  @override
  String get adbAuthorization => '在电视上批准 ADB 授权，然后重试。';

  @override
  String get adbChangeConfirm =>
      '通过 ADB 应用此系统设置吗？更改前会保存之前的 Home 应用程序；保留其他无障碍服务。';

  @override
  String get adbCheck => '检查连接';

  @override
  String get adbDenied => '系统不允许或确认此更改。';

  @override
  String get adbDisable => '禁用以前的启动器';

  @override
  String get adbDisableConfirm =>
      '禁用之前保存的启动器？这要求 CuteLauncher 成为当前的家庭应用程序。使用此设置中的恢复操作来恢复它。';

  @override
  String get adbHint =>
      '仅适用于此电视的原型 (127.0.0.1)。在开发者选项中启用 TCP ADB，输入其端口并批准电视上的授权提示。尚不支持使用配对码进行无线调试。私钥保留在该设备上，在备份之外。';

  @override
  String get adbHome => '使 CuteLauncher 成为家庭应用程序';

  @override
  String get adbInvalid => '输入 1024 到 65535 之间的端口。';

  @override
  String get adbNoRecovery => '恢复不可用：未找到其他启动器或保存的服务状态。';

  @override
  String get adbPort => 'TCP ADB 端口';

  @override
  String get adbReady => 'ADB 访问已确认。';

  @override
  String get adbRestore => '恢复之前的启动器';

  @override
  String get adbSuccess => '更改已应用并已验证。';

  @override
  String get adbTitle => 'ADB 设置';

  @override
  String get adbUnavailable => '无法连接。检查 TCP ADB、端口和授权提示。';

  @override
  String get nightModeScheduled => '使用时间表';

  @override
  String get nightModeTitle => '夜间模式';

  @override
  String get nightModeScope =>
      '需要叠加权限才能调暗其他应用程序。如果没有它，调光将在 CuteLauncher 内部进行。 TCL 过滤器不需要覆盖权限。超过 80% 的不透明度 Android 可能会阻止其他应用程序中的触摸输入；电视遥控键仍然有效。';

  @override
  String get nightModeEnd => '结束';

  @override
  String get nightModeStart => '开始';

  @override
  String get nightModeDim => '调光';

  @override
  String get nightModeWarmth => '暖滤';

  @override
  String get nightModeScheduleHint => '使用当地电视时间。支持隔夜时段。相同的开始和结束时间会禁用计划的过滤器。';

  @override
  String get nightModeEnabled => '启用夜间模式';

  @override
  String get nightModePermission => '允许在其他应用上显示';

  @override
  String get nightModePermissionGranted => '显示在允许的其他应用程序之上';

  @override
  String get backupDownloadsFailed => '无法将备份保存到“下载”。';

  @override
  String get backupSaveDownloads => '将备份保存到下载';

  @override
  String get adbRestoreAccessibility => '恢复无障碍访问';

  @override
  String get nightModeAdbConfirm =>
      '允许 CuteLauncher 使用本地 ADB 在其他应用程序上显示吗？首先打开TCP调试并授权连接。使用 ADB 向导中保存的端口或 5555。';

  @override
  String get nightModeAdbPermission => '通过 ADB 授予权限';

  @override
  String get nightModeNotificationsHint =>
      '该通知允许您在 CuteLauncher 之外关闭过滤器。如果没有它，请使用此菜单。';

  @override
  String get nightModeNotificationsAllowed => '允许夜间模式通知';

  @override
  String get nightModeNotifications => '允许夜间模式通知';

  @override
  String get categoryLastVisibleHint => '至少有一个类别必须保持可见。';

  @override
  String get diagnosticsClear => '清除会话诊断';

  @override
  String get diagnosticsReady => '报告准备就绪';

  @override
  String get diagnosticsCreate => '创建报告';

  @override
  String get diagnosticsOperations => '记录操作';

  @override
  String get diagnosticsCopied => '报告已复制';

  @override
  String get diagnosticsHint =>
      '报告包含应用程序版本、权限状态、内存使用情况和操作结果。它不包括密钥、地址、文件路径、应用程序列表和通知内容。在应用程序重新启动之前，内存中仅保留最后 50 次操作。不会自动发送任何内容。';

  @override
  String get diagnosticsTitle => '错误诊断';

  @override
  String get diagnosticsCopyFailed => '无法复制报告。';

  @override
  String get diagnosticsCopy => '复印报告';

  @override
  String get diagnosticsCreating => '正在创建报告...';

  @override
  String get tclBlueLightTitle => 'TCL蓝光滤光片';

  @override
  String get tclBlueLightError => '无法读取或验证 TCL 过滤器设置。刷新其状态并重试。';

  @override
  String get tclBlueLightUnsupported => 'TCL 滤镜接口在此电视上不可用。';

  @override
  String get tclBlueLightRefresh => '刷新TCL过滤器状态';

  @override
  String get tclBlueLightHint => '控制电视内置的眼睛健康保护过滤器。它还可以遵循夜间模式时间表。';

  @override
  String get nightSolarSchedule => '日落和日出';

  @override
  String get nightNextStart => '下次开始';

  @override
  String get nightScheduleTimeHint => '时间使用电视时区。负偏移量较早；正偏移量稍后出现。';

  @override
  String get nightTemperature => '滤镜色温';

  @override
  String get nightScheduleSettings => '日程设置';

  @override
  String get nightCityName => '城市名称';

  @override
  String get nightSkipUntilNext => '禁用夜间模式直到下一个日落';

  @override
  String get nightSunriseOffset => '相对于日出结束';

  @override
  String get nightEnableUntilMorning => '启用夜间模式直到下一个日出';

  @override
  String get nightPermissions => '权限';

  @override
  String get nightTclSchedule => '在计划中包括 TCL 过滤器';

  @override
  String get nightSearchCity => '搜索';

  @override
  String get nightRefreshSun => '刷新日出日落';

  @override
  String get nightSolarUnavailable => '选择一个城市并刷新日照时间。如果无法日出或日落，则日照时间表将暂停。';

  @override
  String get nightSunsetOffset => '相对于日落开始';

  @override
  String get nightCityHint =>
      '选择您的城市而不是授予位置访问权限。选定的坐标将发送到 Sunrise-Sunset.org 或 Open-Meteo 作为后备，以检索太阳时间。';

  @override
  String get nightResumeSchedule => '返回日程';

  @override
  String get nightScheduleSource => '时间表类型';

  @override
  String get nightSolarCached => '使用缓存的太阳时间；互联网刷新将自动重试。';

  @override
  String get nightTclScheduleHint =>
      '启用夜间模式时使用相同的时间表。对 TCL 过滤器的手动更改将持续到下一次计划的转换为止。不需要覆盖权限。';

  @override
  String get nightRefreshPermission => '刷新权限状态';

  @override
  String get nightCityNotFound => '未找到城市。尝试另一个名字。';

  @override
  String get nightNoOffset => '无偏移';

  @override
  String get nightManualSchedule => '定制时间表';

  @override
  String get nightChooseCity => '选择城市';

  @override
  String get nightPermissionUnknown => '叠加权限状态未知';

  @override
  String get nightNextEnd => '下一个结束';

  @override
  String get nightTemporaryOff => '暂时关闭直至';

  @override
  String get nightCitySearchFailed => '无法搜索城市。检查您的互联网连接。';

  @override
  String get nightSolarAttribution =>
      '每日太阳时间：Sunrise-Sunset.org；后备：Open-Meteo。城市搜索：GeoNames。缓存几天以供离线使用。';

  @override
  String get nightTemporaryOn => '暂时调暗直到';

  @override
  String get homeScreen => '主屏幕';

  @override
  String get appearanceSettings => '外观';

  @override
  String get generalSettings => '高级';

  @override
  String get advancedSettings => '高级';

  @override
  String get controlAndStartup => '启动器和电视控件';

  @override
  String get sectionsAndOrder => '部分和顺序';

  @override
  String get topPanel => '顶板';

  @override
  String get tileStyle => '瓷砖风格';

  @override
  String get tilesAndLabels => '瓷砖和标签';

  @override
  String get highlightAndAnimation => '突出显示和动画';

  @override
  String get androidTvSettings => 'Android TV 设置';

  @override
  String get weatherSettings => '天气设置';

  @override
  String get showHighlightOutline => '显示突出显示轮廓';

  @override
  String get resetTilesAndPanel => '重置图块和面板设置';

  @override
  String get resetTilesAndPanelHint =>
      '重置其他图块、标签、突出显示和顶部面板参数？壁纸、强调色、瓷砖样式和标签可见性均被保留。';

  @override
  String get panelAppearanceSettings => '顶板外观';

  @override
  String get panelSharedHint => '更改图块设置中的外观。';

  @override
  String get effectsCompatibilityHint =>
      '附加外观：轮廓始终可见且不跳动。维度风格没有遗留轮廓；经典不脉动。强度影响尺度和阴影；缩放是空间有限的。';

  @override
  String get sizeAndLayout => '尺寸和布局';

  @override
  String get labelsGroup => '标签';

  @override
  String get surfaceGroup => '表面';

  @override
  String get clockAndDateGroup => '时钟和日期';

  @override
  String get networkAndTrafficGroup => '网络及流量';

  @override
  String get buttonsGroup => '按钮';

  @override
  String get notificationAppsHint => '关闭不需要通知的应用程序。启用的开关允许通知；该应用程序仍然可以启动。';

  @override
  String get notificationPanelLink => '顶板外观';

  @override
  String get overlayAccessAdb => '显示在其他应用程序之上 (ADB)';

  @override
  String get tileStyleModern => '现代';

  @override
  String get tileStyleVolume => '维度';

  @override
  String get showTime => '演出时间';

  @override
  String get showDate => '显示日期';

  @override
  String get showWeather => '显示天气';

  @override
  String get showNetwork => '显示网络状态';

  @override
  String get showTraffic => '显示路况';

  @override
  String get scheduledBrightness => '预定亮度';

  @override
  String get followTileStyle => '遵循风格';

  @override
  String get androidTvSettingsHint => '打开电视系统设置';

  @override
  String get autoHideTopPanel => '自动隐藏面板';

  @override
  String get showSectionTitles => '显示章节标题';

  @override
  String get usageDaily => '每日';

  @override
  String get usageWeekly => '每周';

  @override
  String get usageMonthly => '每月';

  @override
  String get onlineWallpaperAddress => '图片地址（HTTPS）';

  @override
  String get watchNextAppLimits => '每个应用程序的限制';

  @override
  String get watchNextAppLimitsHint => '源限制先于总体限制应用。无限制仅保留总体限制；隐藏内容保持隐藏状态。';

  @override
  String get rememberCategoryFocus => '记住最后一张聚焦卡';

  @override
  String get automaticBackups => '自动备份';

  @override
  String get automaticBackupsHint =>
      '启动器处于活动状态时，每日复制设置、壁纸和横幅。返回启动器后会运行错过的副本。在此设备上私密存储，总共最多 256 个 MiB；删除应用程序或其数据将删除它们。也保留外部备份。';

  @override
  String get automaticBackupsEnabled => '每日自动备份';

  @override
  String get automaticBackupsKeep => '保留副本';

  @override
  String get automaticBackupCreateNow => '立即创建还原点';

  @override
  String get automaticBackupFailed => '备份操作失败。检查可用空间并重试。';

  @override
  String get restorePoints => '恢复点';

  @override
  String get noRestorePoints => '还没有恢复点';

  @override
  String get updatePrereleases => '更新至预发布版本';

  @override
  String get topPanelObjects => '对象';

  @override
  String get panelTransparency => '面板透明度';

  @override
  String get panelTextBackground => '文本和按钮背景';

  @override
  String get panelTextBackgroundColor => '文本和按钮背景颜色';

  @override
  String get panelTextColor => '文本和按钮颜色';

  @override
  String get panelTextSize => '文本和按钮大小';

  @override
  String get panelFont => '文字字体';

  @override
  String get fontSans => '无衬线字体';

  @override
  String get fontSerif => '衬线';

  @override
  String get fontMono => '等宽字体';

  @override
  String get fontCondensed => '浓缩';

  @override
  String get trafficPermissionGranted => '已授予流量统计访问权限';

  @override
  String get background => '背景';

  @override
  String get backgroundParameters => '参数';

  @override
  String get resetAppearanceHint => '重置背景、重音、图块、标签、突出显示和动画？';

  @override
  String get wallpaperDimming => '调光';

  @override
  String get wallpaperPlacement => '安置';

  @override
  String get wallpaperDisplay => '壁纸展示';

  @override
  String get wallpaperContain => '显示整个图像';

  @override
  String get wallpaperBlurred => '副本过于模糊';

  @override
  String get wallpaperCover => '填满屏幕';

  @override
  String get wallpaperBrightness => '壁纸亮度';

  @override
  String get wallpaperSaturation => '饱和度';

  @override
  String get categoryPadding => '类别填充';

  @override
  String get categoryLight => '光';

  @override
  String get categoryBlue => '蓝色';

  @override
  String get categoryPurple => '紫色';

  @override
  String get categoryAllRows => '全部';

  @override
  String get categoryTeal => '青色';

  @override
  String get categoryMaxRows => '可见的网格行';

  @override
  String get categoryDark => '黑暗';

  @override
  String get categoryAppearance => '类别外观';

  @override
  String get categoryBackground => '类别背景';

  @override
  String get categoryTransparent => '透明';

  @override
  String get slideshowInterval => '更换间隔';

  @override
  String get slideshowFolderSelected => '此设备上保存的文件夹访问权限。';

  @override
  String get slideshowRandom => '随机顺序';

  @override
  String get wallpaperSlideshow => '文件夹幻灯片';

  @override
  String get slideshowNext => '下一张图片';

  @override
  String get slideshowFolderRequired => '选择一个文件夹来开始幻灯片放映。';

  @override
  String get slideshowHint =>
      '多达 1,000 张图像和 4,000 个文件夹条目；文件最多 8 个 MiB。损坏的文件将被跳过，并保留最后的良好图像。变化在后台停止。在另一台设备上恢复后再次选择该文件夹。';

  @override
  String get slideshowSeconds => 's';

  @override
  String get slideshowError => '无法读取图像。选择包含有效图像的可访问文件夹。';

  @override
  String get slideshowFolder => '选择文件夹';

  @override
  String get slideshowRecursive => '包括子文件夹';

  @override
  String get weatherSourceKeyRequired => '为此天气源添加 API 密钥。';

  @override
  String get weatherOpenWeatherCredit =>
      '天气：OpenWeather (openweathermap.org)。每日值总结了可用的三小时预测期。';

  @override
  String get weatherOpenWeatherHint =>
      '使用您的密钥查看当前天气和 5 天/3 小时的天气预报。每次更新都会发出两个请求；访问权限和限制取决于您的计划。';

  @override
  String get weatherOpenWeatherKey => 'OpenWeather API 钥匙';

  @override
  String get mediaPause => '暂停';

  @override
  String get showNowPlaying => '正在首页播放节目';

  @override
  String get nowPlayingAccessHint => '媒体控件需要 CuteLauncher 的通知访问权限。仅显示玩家提供的操作。';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get mediaNext => '下一曲目';

  @override
  String get mediaPlay => '简历';

  @override
  String get mediaControlError => '该玩家不可用或未接受此操作。';

  @override
  String get nightUsageAccess => '允许使用访问';

  @override
  String get nightExcludedAppsHint =>
      '覆盖和计划的 TCL 过滤器在选定的应用程序中暂停。需要使用权限；如果没有它，则无法应用排除。';

  @override
  String get nightExcludedApps => '排除的应用程序';

  @override
  String get adbPairPort => '配对端口';

  @override
  String get adbPairOverlayHint =>
      '打开无线调试并使用配对代码进行配对。保持系统代码对话框打开。此表单将在 30 秒后激活。输入两个端口和 Android 显示的代码。';

  @override
  String get adbOverlaySettings => '将控制权返回到“设置”30 秒';

  @override
  String get adbTlsHint =>
      '在开发者选项中使用无线调试。配对和连接有不同的端口。如果您的固件没有配对代码屏幕或阻止覆盖窗口，请改用 TCP/RSA。所有连接都保留在该电视的本地。';

  @override
  String get adbPaired => '配对。使用无线调试连接端口检查连接。';

  @override
  String get adbTransport => '连接方式';

  @override
  String get adbPairCode => '六位数代码';

  @override
  String get adbOverlayRequired => '通过“设置”输入的代码需要在其他应用程序上显示的权限。';

  @override
  String get adbOverlayPermission => '允许在其他应用上显示';

  @override
  String get adbTlsUnsupported => '该固件无法打开所需的设置屏幕或配对覆盖层。使用 TCP/RSA。';

  @override
  String get adbConnectPort => '连接端口';

  @override
  String get adbTls => 'TLS / 配对代码';

  @override
  String get adbTcp => 'TCP / RSA';

  @override
  String get adbPairingFailed => '配对失败。检查代码和配对端口，保持 Android 代码对话框打开，然后重试。';

  @override
  String get adbTlsDisabled => '无线调试已禁用或状态不可用。在开发者选项中启用它。';

  @override
  String get adbPairOverlay => '在“设置”中输入配对代码';

  @override
  String get adbPair => '配对';

  @override
  String get adbDeveloperSettings => '打开开发者选项';

  @override
  String get adbTwoWindowsHint =>
      '如果此固件支持两个窗口，请保持 CuteLauncher 旁边的系统配对对话框打开，并在此处输入其代码。仅当两个窗口都打开时才可以直接配对。';

  @override
  String get adbTwoWindows => '在第二个窗口中打开“设置”';

  @override
  String get autoLaunchBoot => '电视开机后';

  @override
  String get autoLaunchOff => '残疾人';

  @override
  String get autoLaunchTitle => '自动启动';

  @override
  String get autoLaunchDelay => '发射延迟';

  @override
  String get autoLaunchHdmi => '切换到选定的 HDMI 输入';

  @override
  String get autoLaunchWake => '醒来后';

  @override
  String get autoLaunchHint =>
      '选择在电视启动或唤醒后打开的应用程序或 HDMI 输入。在下面设置事件和延迟。当 Android 显示 CuteLauncher 时，该操作运行一次。任何远程输入或离开主屏幕都会取消等待。之后您可以自由更改 HDMI 输入。将 CuteLauncher 设置为默认启动器，或根据需要启用启动时启动。唤醒检测需要 CuteLauncher 保持运行。';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get autoLaunchApp => '打开选定的应用程序';

  @override
  String get autoLaunchTarget => '发射目标';

  @override
  String get autoLaunchUnavailable => '目标不可用或固件不允许此操作。';

  @override
  String get autoLaunchCancelled => '延迟发射已取消。';

  @override
  String get syncTitle => '交换设置';

  @override
  String get syncHint =>
      '保存设置文件，将其传输到另一台设备并在那里打开它。将文件交换回来以使两台设备保持最新状态。界面、图块样式和显示首选项是共享的。应用程序、分区、壁纸文件、权限、HOME、启动规则和机密均保留在此设备上。这是手动交换；不使用任何帐户或后台网络连接。';

  @override
  String get syncExport => '保存对文件的更改';

  @override
  String get syncImport => '从另一台设备打开更改';

  @override
  String get syncSaved => '已保存设置交换文件。';

  @override
  String get syncFailed => '无法交换设置。不保留部分导入。检查文件，如果设置在审阅期间发生更改，请重新打开它。';

  @override
  String get syncPreviewHint =>
      '申请前查看更改。对于冲突，请选择每一行以选择该设备或文件。最初选择保留该设备。取消会使设置保持不变。';

  @override
  String get syncNoChanges => '没有新的设置。申请承认共同的历史。';

  @override
  String syncLocalValue(String value) {
    return '该设备：$value';
  }

  @override
  String syncFileValue(String value) {
    return '来自文件：$value';
  }

  @override
  String get syncKeepLocal => '冲突：保留此设备';

  @override
  String get syncUseFile => '冲突：使用该文件';

  @override
  String get syncApply => '应用已审核的更改';

  @override
  String get syncApplied => '交换设置。保存一个新文件以将结果发回。';

  @override
  String syncStyleParameters(int count) {
    return '自定义样式：$count 项参数（差异见下方）';
  }

  @override
  String get cloudBackups => '云备份';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud。输入现有文件夹的 HTTPS 地址和应用程序密码。转账是手动的；该文件夹存储最新的副本。';

  @override
  String get cloudUrl => '文件夹HTTPS地址';

  @override
  String get cloudUser => '用户名';

  @override
  String get cloudPassword => '应用密码';

  @override
  String get cloudConnect => '检查并保存帐户';

  @override
  String get cloudCheck => '检查连接';

  @override
  String get cloudDisconnect => '断开帐户';

  @override
  String get cloudDisconnectConfirm => '从电视中删除此帐户吗？云中的副本将保留。';

  @override
  String get cloudUpload => '将副本保存到云端';

  @override
  String get cloudDownload => '从云端恢复';

  @override
  String get cloudUploadConfirm =>
      '将此文件夹中的cuteaulauncher_backup.json 替换为当前设置和数据？';

  @override
  String get cloudSuccess => '完成';

  @override
  String get cloudConfigurationError => '检查HTTPS文件夹地址、用户名和应用程序密码。';

  @override
  String get cloudAuthorizationError => '访问被拒绝。检查您的帐户和文件夹权限。';

  @override
  String get cloudMissingError => '找不到文件夹或备份。';

  @override
  String get cloudUnsupportedError => '该地址不支持所需的 WebDAV 操作。不遵循重定向；输入最终的文件夹地址。';

  @override
  String get cloudNetworkError => '连接失败或超时。当网络可用时重试。';

  @override
  String get cloudFailed => '无法完成备份操作。检查存储访问并重试。';

  @override
  String get cloudStorageError => '帐户存储不可用。断开连接并重新配置帐户。';

  @override
  String get adbPermissionChecking => '正在检查访问...';

  @override
  String get adbPermissionConnected => 'ADB 已连接 · 授予权限';

  @override
  String get adbPermissionDisconnected => 'ADB 已断开·建立连接';

  @override
  String get adbSetupIntro =>
      '在电视开发者设置中启用调试和网络 ADB，然后信任 CuteLauncher。所有 ADB 操作的风险均由您自行承担。';

  @override
  String get adbConnectionBlock => 'ADB 连接';

  @override
  String get adbNotChecked => '连接未检查';

  @override
  String get adbApplied => '已申请';

  @override
  String get adbNotApplied => '尚未申请';

  @override
  String get adbDefaultBlock => '默认启动器';

  @override
  String get adbSystemDefault => '打开系统默认启动器设置';

  @override
  String get adbAssignDefault => '通过 ADB 将 CuteLauncher 设置为默认启动器';

  @override
  String get adbRestoreDefault => '通过 ADB 恢复之前的默认启动器';

  @override
  String get adbDefaultHint => '如果系统菜单无法设置默认启动器，请使用 ADB。';

  @override
  String get adbBuiltinHint =>
      '禁用内置启动器可以让系统打开 CuteLauncher。电视菜单和按钮可能会受到影响。启用内置启动器可以撤消此操作。';

  @override
  String get adbHomeBlock => 'Home按钮和启动';

  @override
  String get adbEnableService => '通过 ADB 启用 CuteLauncher 无障碍服务';

  @override
  String get adbHomeOverride => '覆盖主页按钮';

  @override
  String get adbHomeOptional => '如果内置启动器被禁用，则可以选择覆盖主页并在电视启动时启动。';

  @override
  String get adbEnableBuiltin => '通过 ADB 启用内置启动器';

  @override
  String get adbDisableBuiltin => '通过 ADB 禁用内置启动器';

  @override
  String get adbNoBuiltin => '未找到内置 Google TV / Android TV 发射器。';

  @override
  String get adbChanged => '状态改变了。检查连接并再次确认操作。';

  @override
  String get adbEffectHome => 'CuteLauncher 将成为系统默认启动器。当前的启动器将被保存以供恢复。';

  @override
  String get adbEffectRestore =>
      '之前的启动器将被启用并设为默认值。如果不可用或未保存，则选择第一个可用的其他启动器。这不会禁用主页按钮修复。';

  @override
  String get adbEffectDisable => '电视用户将禁用内置启动器应用程序。电视菜单和按钮可能会停止工作。该应用程序未卸载。';

  @override
  String get adbRecoveryHomeDisable =>
      '整个 Google TV 设置向导（包括其恢复主屏幕）也将被禁用，以便 CuteLauncher 可以成为默认启动器。在恢复之前，安装向导功能将不可用。两个包的原始状态将被保存以供恢复。';

  @override
  String get adbRecoveryHomeRestore => 'Google TV 设置向导也将返回到其保存的状态。';

  @override
  String get adbDisableHomeUnavailable => '另一个主屏幕具有更高的优先级。此启动器无法安全地禁用它。';

  @override
  String get adbEffectEnable =>
      '内置启动器将恢复到其保存的状态，或者如果未保存状态则启用。系统可能会再次选择它作为默认启动器。';

  @override
  String get adbEffectAccessibility =>
      'CuteLauncher 无障碍服务将启用。可以接收Home事件；拦截由单独的开关控制。其他服务均保留。';

  @override
  String get adbEffectAccessibilityRestore =>
      'CuteLauncher 服务将返回到授予 ADB 访问权限之前的状态。其他无障碍服务被保留。';

  @override
  String get adbEffectOverlay => 'CuteLauncher 将被允许在其他应用程序上显示窗口，包括夜间过滤器。';

  @override
  String get adbEffectNotifications => 'CuteLauncher 将通过其自己的侦听器服务接收通知访问。';

  @override
  String get adbEffectWatchNext => 'CuteLauncher 将有权继续观看数据。';

  @override
  String get adbEffectUsage => 'CuteLauncher 将接收用于流量和前台应用程序检测的使用统计访问权限。';

  @override
  String get adbEffectWriteSettings => 'CuteLauncher 将被允许更改系统亮度设置。';

  @override
  String get adbNoAvailableLauncher => '未找到其他已安装的启动器。无法恢复。';

  @override
  String get adbUnsupported => '在此设备上不可用：不支持 ADB 命令。';

  @override
  String get adbHomeUnavailable => '内置启动器具有系统优先级。无法通过ADB直接赋值；使用辅助功能或禁用内置启动器。';

  @override
  String get nightBatteryExempt => 'CuteLauncher 免于优化';

  @override
  String get nightBatteryHint => '可以帮助计划在后台运行。不保证进程在待机状态下存活。';

  @override
  String get nightBatteryOptimized => 'CuteLauncher 待优化';

  @override
  String get nightBatteryTitle => '电池优化';

  @override
  String get nightBatteryUnavailable => '系统设置在此固件上不可用或访问被拒绝。';

  @override
  String get nightBatteryUnknown => '豁免状况未知';

  @override
  String get nightBatteryOpenApps => '打开应用程序设置';

  @override
  String get nightBatteryGuide =>
      '1. 在应用程序设置中，打开特殊应用程序访问权限。\n2. 选择电池优化（有时是节能器）。\n3、找到CuteLauncher；如果需要，选择所有应用程序。\n4. 禁用优化或选择无限制。\n菜单名称和可用性取决于电视固件。';

  @override
  String get updateNotifications => '显示更新通知';

  @override
  String get diagnosticsSave => '将报告保存到文件';

  @override
  String get diagnosticsSaved => '报告已保存';

  @override
  String get diagnosticsSaveFailed => '无法保存报告。检查文件管理器和目标文件夹。';

  @override
  String get memoryCacheSize => '图片缓存大小';

  @override
  String get memoryProcess => '应用内存';

  @override
  String get memoryImages => '图像缓存';

  @override
  String get diagnosticsExportOpened => '在文件管理器中选择一个文件夹并保存报告。';

  @override
  String get adbDisableService => '通过 ADB 禁用 CuteLauncher 辅助服务';

  @override
  String get adbDefaultSettings => '默认启动器设置';

  @override
  String get adbHomeSettings => '主页按钮设置';

  @override
  String get adbAccessibilitySettings => '打开辅助功能设置';

  @override
  String get adbAccessibilityGuide =>
      '在系统菜单中选择CuteLauncher并启用其服务。返回此处配置主页拦截。要禁用它，请在同一菜单中关闭 CuteLauncher 服务。';

  @override
  String get adbEffectAccessibilityDisable =>
      'CuteLauncher 服务将被禁用。主场拦截将停止。其他无障碍服务被保留。';

  @override
  String get backupAutoEnabled => '自动备份';

  @override
  String get backupClientId => '客户ID';

  @override
  String get backupClientSecret => '客户秘密';

  @override
  String get backupCloudImportConfirm => '所有本地设置、类别和图像都将替换为云数据。继续？';

  @override
  String get backupConfigured => '已配置';

  @override
  String get backupConnection => '连接设置';

  @override
  String get backupCreated => '已创建';

  @override
  String get backupDaily => '每日';

  @override
  String get backupDriveHelp =>
      '选择“连接”并确认手机上的代码。备份在 Google Drive 中的 CuteLauncher 文件夹中可见，您可以在其中下载或删除它们。保持文件名不变以进行应用内恢复。从隐藏备份升级后重新连接；旧备份不会自动迁移。';

  @override
  String get backupFrequency => '备份频率';

  @override
  String get backupHourly => '每小时';

  @override
  String get backupLocal => '本地副本';

  @override
  String get backupMinutes => '分钟';

  @override
  String get backupMode => '模式';

  @override
  String get backupNever => '还没有备份';

  @override
  String get backupNotConfigured => '未配置';

  @override
  String get backupOptions => '备份选项';

  @override
  String get backupSaveMode => '备份';

  @override
  String get backupScope => '跨电视备份';

  @override
  String get backupSyncScope => '跨电视同步';

  @override
  String get backupSeparate => '每台电视独立';

  @override
  String get backupShared => '所有电视的设置相同';

  @override
  String get backupStorage => '存储';

  @override
  String get backupSyncHelp => '下载数据并上传更改。最新的变化赢得了冲突。电视时钟必须正确。同步在启动器打开时运行。';

  @override
  String get backupSyncLimit => '检查频率不超过';

  @override
  String get backupSyncMode => '同步';

  @override
  String get backupSyncOptions => '同步选项';

  @override
  String get backupTime => '备份时间';

  @override
  String get backupWeekday => '星期几';

  @override
  String get backupWeekly => '每周';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp => '本地副本将随应用程序或其数据一起删除。在电视外面也放一份副本。';

  @override
  String get panelObjectOrder => '对象顺序';

  @override
  String get panelInformationGroup => '信息';

  @override
  String get panelOrderHint => '◄ / ► 开始或结束移动；▲ / ▼ 调整顺序，在分组边界移至另一侧；OK / 返回结束。';

  @override
  String get panelTextBackgroundTransparency => '文本和按钮背景透明度';

  @override
  String get weatherCityHint => '输入英文城市名称，例如莫斯科。';

  @override
  String get weatherCityNotFound => '未找到城市。检查城市的英文名称。';

  @override
  String get weatherLocationAutomatic => '自动获取';

  @override
  String get weatherLocationAutomaticHint => '获取设备坐标。需要位置许可。';

  @override
  String get weatherLocationManual => '手动输入';

  @override
  String get weatherLocationPermissionDenied => '在 Android 设置中允许位置访问，然后重试。';

  @override
  String get weatherLocationUnavailable => '无法获取坐标。检查 Android 位置设置或手动输入城市。';

  @override
  String get nightFilterSettings => '过滤器设置';

  @override
  String get nightScheduleMenu => '时间表';

  @override
  String get nightScheduleInactive => '时间表已关闭';

  @override
  String get nightLocation => '地点';

  @override
  String get nightLocationAutomatic => '自动获取';

  @override
  String get nightLocationManual => '手动输入';

  @override
  String get nightLocationFailed => '位置不可用。检查权限和系统位置设置。';

  @override
  String get nightCityEnglish => '输入城市英文名称';

  @override
  String get nightOverlayBrief => '允许过滤器显示在其他应用程序之上。';

  @override
  String get weatherGetLocation => '获取位置';

  @override
  String get backupLastCreated => '上次备份已创建：';

  @override
  String get backupManagement => '管理备份';

  @override
  String get backupCopyList => '备份列表';

  @override
  String get backupRefreshCopyList => '刷新备份列表';

  @override
  String get backupCreateNow => '立即创建新备份';

  @override
  String get backupFolderPath => '备份文件夹';

  @override
  String get backupPrivateFolder => '私人应用程序文件夹';

  @override
  String get backupRestoreCopy => '恢复此备份';

  @override
  String get backupDeleteConfirm => '删除选定的备份？';

  @override
  String get blockedAppsGroup => '被阻止的应用程序';

  @override
  String get notificationSettingsButton => '通知设置';

  @override
  String get hidePersistentNotificationsHint => '隐藏列表中和其他应用程序上的持久通知。';

  @override
  String get nightTransitionTime => '过渡时间';

  @override
  String get brightnessSolar => '使用夜间模式时间表';

  @override
  String get brightnessAfterSunrise => '日出后';

  @override
  String get brightnessAfterSunset => '日落之后';

  @override
  String get brightnessTransitionTime => '亮度过渡时间';

  @override
  String get brightnessSolarUnavailable => '夜间模式时间表不可用。检查它的时间和地点。';

  @override
  String get persistentNotificationCannotDelete => '此永久通知无法删除。你只能阻止它。';

  @override
  String get diagnosticsCreateFailed => '无法创建诊断报告。再试一次。';

  @override
  String get backupListFailed => '无法加载备份列表。检查对所选存储的访问。';

  @override
  String get updateInstallerFailed => '无法打开更新安装程序。重试并检查 Android 安装程序是否可用。';

  @override
  String get backupFolderFailed => '无法选择或保存备份文件夹。选择一个可访问的文件夹并重试。';

  @override
  String get updateDownloadFailed => '无法下载更新。检查您的互联网连接和可用存储空间。';

  @override
  String get backupDeleteFailed => '无法删除备份。检查删除权限并重试。';

  @override
  String get updateCheckFailed => '无法检查更新。检查您的互联网连接，然后重试。';

  @override
  String get backupCreateFailed => '无法创建备份。检查存储访问和可用空间。';

  @override
  String get wallpaperChangeFailed => '无法更改壁纸。检查文件访问并重试。';

  @override
  String get backupDownloadsFolder => '下载 / CuteLauncher';

  @override
  String get backupChooseFolder => '在文件管理器中选择一个文件夹';

  @override
  String get backupFolderPickerUnavailable =>
      '此电视上没有可用的文件夹选择器。选择“下载”/CuteLauncher 或内部应用程序文件夹。';

  @override
  String get driveConfigurationError =>
      'Google Drive 凭据丢失或无效。输入电视 OAuth 客户端的客户端 ID 和客户端密钥。';

  @override
  String get driveCodeExpired => 'Google Drive 登录超时。选择检查并保存帐户以获取新代码。';

  @override
  String get brightnessAfterNightStart => '夜间';

  @override
  String get brightnessAfterNightEnd => '白天';

  @override
  String get backupSyncSettings => '要同步的设置';

  @override
  String get backupSyncHomeGroup => '主屏幕、部分和应用程序';

  @override
  String get backupSyncAppearanceGroup => '外观、壁纸和横幅';

  @override
  String get backupSyncDisplayGroup => '夜间模式、亮度和屏保';

  @override
  String get backupSyncControlsGroup => '启动器和电视控件';

  @override
  String get backupSyncGeneralGroup => '语言、更新和其他设置';

  @override
  String get backupSyncGroupsHelp => '禁用的块保留在该电视的本地。块选择在设备之间同步。';

  @override
  String get backupSyncGroupsFailed => '无法保存同步设置选择。再试一次。';

  @override
  String get tileLayoutMode => '平铺布局';

  @override
  String get tileLayoutAuto => '自动按瓷砖尺寸';

  @override
  String get tileLayoutColumns => '固定列数';

  @override
  String get tileLayoutRows => '固定行数';

  @override
  String get tileRowCount => '行数';

  @override
  String get useGlobalTileSettings => '使用全局设置';

  @override
  String get centerSelection => '选择位置';

  @override
  String get selectionBottom => '底部';

  @override
  String get selectionLower => '中下层';

  @override
  String get selectionCenter => '中心';

  @override
  String get selectionUpper => '中上层';

  @override
  String get selectionTop => '顶部';

  @override
  String get settingsStyle => '设置风格';

  @override
  String get tileFocusEnlargement => '焦点放大';

  @override
  String get tileFocusShadowStrength => '暗影强度';

  @override
  String get tileFocusLift => '电梯';

  @override
  String get tileFocusLiftHeight => '举升高度';

  @override
  String get tileFocusBorderColor => '焦点边框颜色';

  @override
  String get tileFocusAccentColor => '强调色';

  @override
  String get tileFocusDynamicColor => '动态色彩';

  @override
  String get tileSizeFromColumns => '平铺大小由列数和部分宽度决定。';

  @override
  String get resetSectionToGlobal => '将设置重置为共享值';

  @override
  String get resetSectionToGlobalHint => '恢复共享部分标题、图标和背景，并重置填充？';

  @override
  String get resetStyleSection => '重置此部分';

  @override
  String get resetStyleSectionHint => '仅恢复此部分的默认值？';

  @override
  String get notificationStyle => '通知样式';

  @override
  String get styleBackgroundColor => '背景颜色';

  @override
  String get styleTransparency => '背景透明度';

  @override
  String get styleTextSize => '文字大小';

  @override
  String get styleTextColor => '文字颜色';

  @override
  String get noticeSize => '通知尺寸';

  @override
  String get noticeStylePreview => '通知预览';

  @override
  String get backupSyncHomeOptions => '行为和一般选项';

  @override
  String get backupSyncBackground => '背景和自定义横幅';

  @override
  String get backupSyncTiles => '磁贴、菜单和通知样式';

  @override
  String get backupSyncWeatherSource => '来源和地点';

  @override
  String get backupSyncWeatherDisplay => '天气显示和温度单位';

  @override
  String get backupSyncNotificationSettings => '通知显示和过滤器';

  @override
  String get backupSyncOther => '其他设置';

  @override
  String get tileFocusBorderStyle => '边框样式';

  @override
  String get tileFocusOutline => '概要';

  @override
  String get tileFocusGlow => '发光';

  @override
  String get tileFocusNoBorder => '无边框';

  @override
  String get tileShowFocusShadow => '显示阴影';

  @override
  String get homeLayoutRow => '横排';

  @override
  String get homeLayoutRows => '多行';

  @override
  String get homeLayoutGrid => '网格';

  @override
  String get homeCardCount => '对面可见卡片';

  @override
  String get homeAuto => '汽车';

  @override
  String get homeFree => '自由滚动';

  @override
  String get homeAnchored => '锚固部分';

  @override
  String get homeScrollMode => '章节滚动';

  @override
  String get homeSectionPosition => '活动部分位置';

  @override
  String get homeLabelMode => '应用标签';

  @override
  String get homeLabelNone => '无标签';

  @override
  String get homeLabelSelected => '仅选定的应用程序';

  @override
  String get homeLabelAll => '所有应用程序';

  @override
  String get homeInherited => '传承价值';

  @override
  String get homeOwnReset => '自定义值·使用全局';

  @override
  String get homeParameters => '参数';

  @override
  String get homeSectionStyle => '断面外观';

  @override
  String get homeSectionGap => '部分之间的空间';

  @override
  String get homeSectionIcons => '部分图标';

  @override
  String get homeInactiveOpacity => '非活动部分不透明度';

  @override
  String get homeResetSection => '恢复继承的部分外观';

  @override
  String get homeCalculatedSize => '尺寸根据卡片数量计算';

  @override
  String homeGapLimited(int gap) {
    return '间距限制为 $gap 以保持所选卡片数量。';
  }

  @override
  String get homeResetLayout => '重置部分布局';

  @override
  String homeVisibleRows(int count) {
    return '完全可见的行：$count';
  }

  @override
  String get homeStylePartial => '仅适用于继承该值并在当前布局中支持该值的部分。';

  @override
  String get homeStyleUnavailable => '在当前部分设置中不可用。检查布局和本地覆盖。';

  @override
  String get homeStyleNeedsRows => '可用于多行或网格。';

  @override
  String get homeStyleNeedsLabels => '使标签能够更改其大小和颜色。';

  @override
  String get homeStyleNeedsAllLabels => '位置仅适用于所有卡片上的标签。所选标题保留在该部分下方。';

  @override
  String get homeStyleNeedsScale => '选择放大对焦效果。';

  @override
  String get homeStyleNeedsLift => '选择提升焦点效果。';

  @override
  String get homeStyleNeedsBorder => '首先启用轮廓或发光。';

  @override
  String get homeStyleNeedsTitle => '启用部分标题以显示其图标。';

  @override
  String get homeStyleEconomy => '通过内存节省禁用。保存的值将被保留。';

  @override
  String get homeStyleOpaque => '降低图块背景不透明度以看到模糊。';

  @override
  String get homeStyleOverridden => '可见部分使用自己的值。在部分中选择“使用全局”以应用此设置。';

  @override
  String get homeStyleIconHint => '图标大小会影响带有应用程序图标的卡片。电视横幅独立填写卡片。';

  @override
  String get homeStyleShadowHint => '节省内存将非活动卡的阴影限制为 4 个。焦点阴影单独配置。';

  @override
  String get homeStyleTransparent => '背景颜色在不透明度为零时不可见。增加图块背景的不透明度。';

  @override
  String get homeStyleSingleColumn => '单列网格没有水平间隙。';

  @override
  String get homeStyleAutoOnly => '尺寸仅在继承全局尺寸的自动卡片计数部分发生变化。';

  @override
  String get sleepTimerThirtySeconds => '30秒（测试）';

  @override
  String get sleepTimer => '睡眠定时器';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes 最小值';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours小时',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1.5小时';

  @override
  String get sleepTimerAllowExact => '允许精确的计时器';

  @override
  String get sleepTimerExactRequired => '在 Android 设置中允许精确计时器，然后再次选择持续时间。';

  @override
  String get sleepTimerAccessRequired =>
      '在设置 → 其他 → ADB 中启用 CuteLauncher 可访问性或连接本地 ADB。';

  @override
  String get sleepTimerFailed => '无法设置或完成睡眠计时器。检查可访问性和本地 ADB。';

  @override
  String get nightIgnoreHdmiInputs => '忽略 HDMI 输入';

  @override
  String get nightIgnoreHdmiInputsHint => '观看 HDMI 时暂停夜间滤镜。需要使用权限；输入检测取决于电视固件。';

  @override
  String get inputsSettings => '输入设置';

  @override
  String get inputsUseCecNames => '使用 CEC 中的设备名称';

  @override
  String get inputsNamesHint =>
      '名称优先级：您在 CuteLauncher 中的名称 → CEC（如果启用）→ Android 设置中的名称 → 标准输入名称。';

  @override
  String get inputNameHint => '留空以获取自动名称';

  @override
  String get inputsSaveFailed => '无法保存输入设置';

  @override
  String get inputIcon => '输入图标';

  @override
  String get inputIconTv => '电视';

  @override
  String get inputIconGame => '游戏机';

  @override
  String get inputIconComputer => '电脑';

  @override
  String get inputIconReceiver => '接收器';

  @override
  String get inputIconDisc => '光盘播放器';

  @override
  String get inputIconStream => '流媒体设备';

  @override
  String get nightInputExclusions => '输入排除';

  @override
  String get nightSelectInputs => '选择要忽略的输入';

  @override
  String get nightNoInputsSelected => '未选择任何输入。过滤器将应用于每个输入。';

  @override
  String get nightPictureExclusions => '图片模式排除';

  @override
  String get nightPictureExclusionsHint =>
      '选择暂停调光、暖色叠加和链接的 TCL 滤镜的模式。时间表被保留。检测已在TCL上得到验证；不需要使用访问权限。';

  @override
  String get nightPictureUnavailable => '当前图像模式在此固件上不可用。您的选择已保存；仅当检测成功时，排除才适用。';

  @override
  String get nightPictureCurrent => '当前模式';

  @override
  String get nightPictureRefresh => '刷新当前模式';

  @override
  String get nightPictureCode => '模式代码';

  @override
  String get nightPictureStandard => '标准型';

  @override
  String get nightPictureDynamic => '动态';

  @override
  String get nightPictureMovie => '电影';

  @override
  String get nightPictureSport => '运动';

  @override
  String get nightPictureIntelligent => '智能化';

  @override
  String get nightPictureBright => '明亮 (Dolby Vision)';

  @override
  String get nightPictureOrdinary => '标准型';

  @override
  String get systemApplications => '系统应用程序';

  @override
  String get removeFromCategory => '从类别中删除';

  @override
  String get noRemovableCategories => '此应用程序尚未手动添加到任何部分。自动部分无法编辑。';

  @override
  String get remoteButtonsTitle => '遥控器按键重映射';

  @override
  String get remoteButtonsStart => '检查按键（120秒）';

  @override
  String get remoteButtonsStop => '停止检查';

  @override
  String get remoteButtonsHint =>
      '检查会显示代码、松开和重复事件，并将文本报告保存在电视上。开始后请离开此页面，以免OK控制记录。';

  @override
  String get remoteButtonsEmpty => '暂无事件。如果按键打开了应用，请返回此处查看结果。';

  @override
  String get remoteButtonsService => '服务已连接';

  @override
  String get remoteButtonsRefresh => '刷新';

  @override
  String get remoteBindings => '按键分配';

  @override
  String get remoteMappingsEnabled => '启用按键重映射';

  @override
  String get remoteMappingsAdd => '添加分配';

  @override
  String get remoteMappingKey => '按键';

  @override
  String get remoteMappingAction => '操作';

  @override
  String get remoteMappingLearn => '识别遥控器按键';

  @override
  String get remoteMappingLearnHint => '请在30秒内按一个附加按键。导航、Power、语音搜索和音量键受到保护。';

  @override
  String get remoteMappingsHint =>
      '按键分配需要无障碍服务。在编辑器和诊断期间会暂停。Home、返回、方向键和OK保留正常导航功能。';

  @override
  String get remoteMappingsReset => '重置分配';

  @override
  String get remoteMappingsResetConfirm => '删除所有分配并关闭重映射？';

  @override
  String get remoteMappingInvalid => '无法保存。请检查按键和目标。Webhook需要HTTPS或本地网络上的HTTP。';

  @override
  String get remoteMappingBack => '返回';

  @override
  String get remoteMappingProfile => '个人资料';

  @override
  String get remoteMappingChannels => '频道';

  @override
  String get remoteMappingQuickSettings => 'TCL快捷设置';

  @override
  String get remoteMappingTrigger => '按压类型';

  @override
  String get remoteMappingPress => '短按';

  @override
  String get remoteMappingHold => '长按';

  @override
  String get remoteMappingHoldHint => '长按650毫秒执行一次，不触发短按操作。如果只分配长按，短按不会执行任何操作。';

  @override
  String get remotePanel => '悬浮面板';

  @override
  String get remotePanelSettingsBackground => '使用设置背景颜色';

  @override
  String get remotePanelPreview => '打开面板';

  @override
  String get settingsHelp => '详细信息';

  @override
  String get settingsHelpScroll => '▲ / ▼ — 滚动文字';

  @override
  String get panelClockStyle => '时钟外观';

  @override
  String get clockPreset => '时钟样式';

  @override
  String get clockCustom => '自定义';

  @override
  String get clockWeight => '字体粗细';

  @override
  String get clockGlow => '文字发光';

  @override
  String get clockAnimate => '数字动画';

  @override
  String get clockBackground => '时钟背景';

  @override
  String get clockRadius => '背景圆角';

  @override
  String get dateCalendarEnabled => '按下日期时打开日历';

  @override
  String get calendarTitle => '日历';

  @override
  String get dateSettings => '日期设置';

  @override
  String get clockSharedBackground => '使用与其他项目相同的背景';

  @override
  String get clockDefaultBackground => '默认背景';

  @override
  String get remotePanelInheritAppearance => '使用顶部面板外观';

  @override
  String get remotePanelDisabledInLauncher => 'CuteLauncher 显示在屏幕上时，弹出面板已停用。';

  @override
  String get remoteAccessSettings => '访问权限设置';

  @override
  String get remoteButtonsTest => '按键测试';

  @override
  String get remoteMappingConflict => '此按键和按压类型已分配。请选择其他按键或按压类型。';

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
}
