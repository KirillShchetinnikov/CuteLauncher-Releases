// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get scrollContentLabels => '滚动内容行中的长标签';

  @override
  String get contentAppTileStyle => '外观来源';

  @override
  String get contentTileOwnAppearance => '自定义外观';

  @override
  String get contentTileCommonAppearance => '通用外观';

  @override
  String get contentUseSourceLabels => '使用所选外观的标签';

  @override
  String get contentLabelSelected => '仅选中的卡片';

  @override
  String get contentLabelAll => '所有卡片';

  @override
  String get weatherTextResetFormat => '重置格式';

  @override
  String get settingsReportFile => '报告文件';

  @override
  String get homeVisibleRowsLabel => '完整显示的行数';

  @override
  String get watchNextEmpty => '暂无继续观看卡片';

  @override
  String get inputsUnavailableStatus => '没有可用的输入源';

  @override
  String get remoteButtonsNoEvents => '暂无事件';

  @override
  String get informationBackgroundVerticalOffset => '垂直偏移';

  @override
  String get informationResetPositionSize => '重置此页面的所有设置';

  @override
  String get weatherIconsGeometric => '几何';

  @override
  String get weatherIconsCircled => '圆框';

  @override
  String get informationCommonAppearance => '通用设置';

  @override
  String get informationTimeFormat => '时间格式';

  @override
  String get informationDateFormat => '日期格式';

  @override
  String get informationInheritPanelTypography => '继承顶部面板外观';

  @override
  String get informationResetTypography => '重置设置';

  @override
  String get alignSectionTitles => '将分区标题与卡片对齐';

  @override
  String get homeAppName => '主屏幕上的应用名称';

  @override
  String get restoreSystemAppName => '恢复系统名称';

  @override
  String get settingsScrollbar => '滚动条';

  @override
  String get settingsScrollbarHidden => '完全隐藏';

  @override
  String get settingsScrollbarOnScroll => '滚动时显示';

  @override
  String get settingsScrollbarAlways => '始终显示';

  @override
  String get volumeKeysTitle => '长按音量键';

  @override
  String get volumeKeysMode => '修复方式';

  @override
  String get volumeKeysAuto => '自动：面板显示期间';

  @override
  String get volumeKeysTimed => '定时暂停';

  @override
  String get volumeKeysRepeat => '自定义重复';

  @override
  String get volumeKeysDuration => '暂停时长';

  @override
  String get volumeKeysHelp =>
      '部分Android TV和Google TV设备的无障碍按键拦截会影响系统的音量长按重复。服务启用期间，所有应用都可能受到影响。\n\n“自动：面板显示期间”是启用按键映射时的推荐默认模式。音量指示器出现后，暂时解除按键过滤。所选暂停时间结束后检查窗口：如果仍然可见，则继续延长，最长一分钟。如果无法获取窗口，则使用计时器。\n\n“定时暂停”会在最后一次识别到面板出现后的3、5、10、15或30秒恢复过滤。如果自动模式不稳定，可尝试此方式；暂停太短时可增加时长。\n\n“自定义重复”会持续调节音量，直到松开按钮。固件必须向服务发送按下和松开事件。收不到事件时无法生效，也可能出现一次两格的情况。调节异常时请切换模式。\n\n暂停期间，按键映射和Home拦截暂不可用。第一次长按可能只调节一格：请松开后，在指示器仍显示时再次长按。“已禁用”会恢复系统音量处理，同时保留映射。关闭并重新启用按键映射后，所选模式仍会保留。';

  @override
  String get fileStorageSettingsUnavailable =>
      '此固件无法打开所有文件访问权限页面。请使用外部文件浏览器或安装兼容的文件管理器。';

  @override
  String get tileImageMode => '磁贴图像';

  @override
  String get tileBannerImageMode => '有横幅的应用';

  @override
  String get tileIconImageMode => '无横幅的应用';

  @override
  String get tileImageContain => '完整显示图像';

  @override
  String get tileImageCover => '放大并裁剪';

  @override
  String get tileImageEdgeColor => '完整图像与边缘颜色';

  @override
  String get tileImageIcon => '图标与边缘颜色';

  @override
  String get tileImageModeHelp =>
      '为有横幅和无横幅的应用分别选择模式。当磁贴形状裁剪图像或出现空白边缘时生效。可以显示整张图像、按比例放大并裁剪，或使用最近边缘的颜色填充空白。用图标及其边缘颜色替换横幅的选项仅适用于有横幅的应用。保留图标大小设置。';

  @override
  String get wallhavenWallpaperHint =>
      '按所选主题随机获取 Wallhaven 壁纸：SFW、16:9、Full HD 或更高。无需账号或 API 密钥。启动器打开时更新；出错时保留上一张壁纸。';

  @override
  String get renderCompatibilityTitle => '兼容图形输出';

  @override
  String get renderCompatibilityAutomatic => '已为此设备自动启用';

  @override
  String get renderCompatibilityApply => '应用并重启启动器';

  @override
  String get renderCompatibilityFailed => '无法读取或应用设置';

  @override
  String get renderCompatibilityHelp =>
      '如果界面在夜间调暗时闪烁，请尝试此模式。已验证的机型会自动启用。其他电视上的选择仅保存在本设备上，重启启动器后生效。可能增加图形处理负载。';

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
  String get adbWifiOwnedTitle => 'Wi-Fi 属于设置向导';

  @override
  String get adbWifiOwned =>
      '未做任何更改：保存的 Wi-Fi 网络由 Google 设置向导创建。停用向导可能删除网络并使电视断网。\n\n1. 确认您知道 Wi-Fi 密码。\n2. 打开 Android 网络设置，选择该网络，然后选择“忘记网络”。\n3. 通过普通 Android 网络设置重新连接。\n4. 返回 CuteLauncher，检查 ADB，然后重试停用内置启动器。\n\n如果再次出现此消息，请保持内置启动器启用：固件可能会再次将网络归属于设置向导。';

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
  String get dialogOptionBackButtonActionFirstFeedCard => '转到当前内容栏的第一张卡片';

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
  String get openImage => '选择文件';

  @override
  String get picture => '本地图片或视频';

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
  String get timeBasedWallpaper => '日间/夜间图片';

  @override
  String get pickDayWallpaper => '选择日间图片';

  @override
  String get pickNightWallpaper => '选择夜间图片';

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
  String get memoryAdvanced => '高级诊断';

  @override
  String get memoryLauncherTitle => 'CuteLauncher 内存';

  @override
  String get memoryUsage => '内存使用量';

  @override
  String memoryChange(String delta) {
    return '较上次测量 $delta';
  }

  @override
  String get memoryCacheFiles => '内存中的图片文件';

  @override
  String memoryCacheEntries(int count) {
    return '项目数：$count';
  }

  @override
  String memoryCacheResult(String before, String after) {
    return '图片缓存：$before → $after';
  }

  @override
  String get memoryStale => '无法更新，正在显示上次测量结果。';

  @override
  String get memoryTechnical => '技术详情';

  @override
  String get memoryObserve => '内存监测';

  @override
  String get memoryObserveStart => '监测 1 分钟';

  @override
  String get memoryObserveStop => '停止监测';

  @override
  String get memoryObserveRunning => '记录中 · 最长 1 分钟';

  @override
  String get memoryObserveFinished => '记录已停止';

  @override
  String get memoryObserveEmpty => '暂无测量记录';

  @override
  String memorySeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get memoryReadingHelp => '如何理解测量值';

  @override
  String get memorySaverHelp => '内存节省的效果';

  @override
  String get memorySaveFailed => '无法保存内存节省模式，请重试。';

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
  String get weatherCoordinatesError => '请选择城市、输入坐标或自动获取位置。';

  @override
  String get weatherRefresh => '刷新天气';

  @override
  String get weatherKeyPrivate => '仅存储在此设备上，不包含在备份中。空输入将删除密钥。';

  @override
  String get weatherUpdated => '已更新';

  @override
  String get onlineWallpaperError => '无法加载该图像。保留以前的壁纸。选择“刷新壁纸”以重试下载。';

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
  String get diagnosticsSharingNotice =>
      '请通过私信将文件发送给作者，不要公开发布：自动清理可能遗漏个人信息。向作者发送报告即表示您同意在 CuteLauncher 的 Git 仓库中发布匿名的电视兼容性报告。公开内容仅包含无个人信息的设备元数据和功能可用性；错误日志、命令及您的设置不会公开。\n\n报告还包含已安装软件包的名称、版本和启用状态，以及分区名称、内容、顺序和可见性。软件包标识符和名称会保留以便诊断；应用和分区列表不会公开发布。';

  @override
  String get diagnosticsHint =>
      '一份报告同时包含电视功能兼容性和错误诊断。报告包含电视型号和固件、应用版本、权限、内存、错误阶段及原因，以及自动清除个人信息后的命令和响应。当前会话保留最近 50 次操作、单独最多 100 次失败和有限的 ADB 日志。重启后日志清空。清理可能遗漏个人信息：请通过私信发送文件，不要公开发布。不会自动发送任何内容。每次错误都会保存当时生效设置的快照，后续更改不会覆盖它。\n\n报告还包含已安装软件包的名称、版本和启用状态，以及分区名称、内容、顺序和可见性。软件包标识符和名称会保留以便诊断；应用和分区列表不会公开发布。';

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
      '选择您的城市而不是授予位置访问权限。选定的坐标将发送到 Sunrise-Sunset.org 或 GeoNames 作为后备，以检索太阳时间。';

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
      '日出和日落时间来自 Sunrise-Sunset.org，服务不可用时改用 GeoNames。离线时，电视会计算缺少的时间。';

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
  String get notificationAppsHint => '选择要屏蔽通知的应用。开关开启表示通知已被屏蔽。列表保持按名称排序。';

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
  String get automaticBackups => '备份与同步';

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
  String get backgroundParameters => '来源设置';

  @override
  String get resetAppearanceHint => '重置背景、重音、图块、标签、突出显示和动画？';

  @override
  String get wallpaperDimming => '调暗强度';

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
      '选择“连接 Google 云端硬盘”并确认手机上的代码。备份在 Google Drive 中的 CuteLauncher 文件夹中可见，您可以在其中下载或删除它们。保持文件名不变以进行应用内恢复。从隐藏备份升级后重新连接；旧备份不会自动迁移。';

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
  String get weatherCityNotFound => '无法确定城市。请在位置设置中选择城市。';

  @override
  String get weatherLocationAutomatic => '自动获取';

  @override
  String get weatherLocationAutomaticHint => '获取设备坐标。需要位置许可。';

  @override
  String get weatherLocationManual => '手动输入';

  @override
  String get manualLocationInput => '输入方式';

  @override
  String get manualLocationCity => '城市';

  @override
  String get manualLocationCoordinates => '坐标';

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
  String get nightCitySearchHint => '输入城市名称。可在逗号后添加地区或国家。';

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
  String get backupSyncGroupsHelp => '已关闭的项目保留在此电视上。请在各设备上分别选择同步项目。';

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
  String get homeOwnReset => '恢复通用设置';

  @override
  String get homeParameters => '主屏幕行为';

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
  String get noRemovableCategories =>
      '此应用尚未手动添加到任何分区。无法从标准自动分区（所有应用、电视应用、非电视应用）中单独移除，请使用“隐藏”。收藏可手动编辑。';

  @override
  String get remoteButtonsTitle => '遥控器按键重映射';

  @override
  String get remoteButtonsStart => '检查按键（120秒）';

  @override
  String get remoteButtonsStop => '停止检查';

  @override
  String get remoteButtonsControlsHint =>
      '开始测试，然后在任意菜单或已打开的应用中按下按钮。在此停止测试或等待120秒。';

  @override
  String get remoteButtonsHint =>
      '测试结束后，报告将保存到显示的路径并替换上一份报告。使用ADB复制：adb pull <path>。某些系统和厂商按钮可能无法传递给服务。';

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
  String get remoteMappingChooseAction => '选择操作';

  @override
  String get remoteMappingNavigationGroup => '应用与导航';

  @override
  String get remoteMappingScreenSoundGroup => '屏幕和声音';

  @override
  String get remoteMappingAutomationGroup => '自动化';

  @override
  String get remoteMappingLiveTv => '打开电视直播';

  @override
  String get remoteMappingDisplaySettings => '显示设置';

  @override
  String get remoteMappingBluetoothSettings => '蓝牙设置';

  @override
  String get remoteMappingMute => '切换静音';

  @override
  String get remoteMappingNeedsAdb => '需要 ADB';

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
  String get remotePanelDescription =>
      '快捷设置面板可在其他应用上方显示所需的小部件。要使用遥控器打开它，请将“快捷设置面板”操作分配给您喜欢的按钮。';

  @override
  String get remotePanel => '快捷设置面板';

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
  String get clockPreset => '字体样式';

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
  String get remotePanelDisabledInLauncher => 'CuteLauncher 显示在屏幕上时，快捷设置面板已停用。';

  @override
  String get remoteAccessSettings => '访问权限设置';

  @override
  String get remoteButtonsTest => '按键测试';

  @override
  String remoteMappingDeleteConfirm(String name) {
    return '删除“$name”分配？';
  }

  @override
  String get remoteMappingConflict => '此按键和按压类型已分配。请选择其他按键或按压类型。';

  @override
  String get cleanerTitle => 'TV cleanup manager';

  @override
  String get cleanerRefresh => 'Refresh applications';

  @override
  String get cleanerSnapshot => 'Save original state';

  @override
  String get cleanerRestore => '恢复基准状态';

  @override
  String get cleanerSnapshotSaved => 'Original state saved';

  @override
  String get cleanerExportSnapshot => 'Export original state';

  @override
  String get cleanerSafe => 'Disable verified applications';

  @override
  String get cleanerNoSafe => '此型号和固件没有匹配的系统应用列表。';

  @override
  String get cleanerLocal => 'Disable using a local list';

  @override
  String get cleanerProject => 'Project catalog lists';

  @override
  String get cleanerRemoteProject => 'Refresh catalog from GitHub';

  @override
  String get cleanerExternal => 'CleanYourTV examples';

  @override
  String get cleanerDisabledExport => '将停用应用报告导出到文件';

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
      '首次成功刷新列表时仅创建一次基准状态，启动器无法删除或覆盖它，且仅适用于该固件。手动状态记录当前应用模式、名称及日期，可恢复、删除和导出。备份不包含 APK 或应用数据。恢复需要本地 ADB。崩溃循环保护触发时，启动器会尝试自动恢复基准状态。清除启动器数据或卸载启动器也会删除这些备份；无法防止 root 访问。';

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
  String get interfaceCalm => '简约';

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
  String get landscapeDemoStop => '停止';

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
  String get informationGroup => '时钟、日期和天气';

  @override
  String get informationSettings => '区块设置';

  @override
  String get informationAppearance => '区块外观';

  @override
  String get informationSize => '区块大小';

  @override
  String get informationPosition => '时钟和文字的位置';

  @override
  String get informationClockLeft => '时钟在左，文字在右';

  @override
  String get informationClockRight => '文字在左，时钟在右';

  @override
  String get informationSpacing => '时钟与文字间距';

  @override
  String get informationBackground => '区块背景';

  @override
  String get homeResetTilesHint => '恢复此屏幕上所有磁贴和标签的通用值？';

  @override
  String get homeResetLayoutHint => '重置此分区的布局、恢复通用外观并清除内边距？应用及其顺序将保留。';

  @override
  String get networkSummary => '网络';

  @override
  String get networkConnected => '互联网可用';

  @override
  String get networkOffline => '无法访问互联网';

  @override
  String get networkDisconnected => '未连接';

  @override
  String get networkConnection => '连接';

  @override
  String get networkSignal => '信号';

  @override
  String get networkLinkSpeed => 'Wi-Fi 链路速度';

  @override
  String get networkTrafficRate => '设备流量 · 接收 / 发送';

  @override
  String get networkSystemSettings => '系统网络设置';

  @override
  String get networkUnavailable => '不可用';

  @override
  String get networkMobile => '移动网络';

  @override
  String get networkFrequency => '频率';

  @override
  String get networkMbps => 'Mbps';

  @override
  String get networkKbps => 'KB/秒';

  @override
  String get networkReadFailed => '无法读取网络状态';

  @override
  String get clockItalic => '斜体';

  @override
  String get panelWrapNavigation => '面板循环导航';

  @override
  String get panelWrapNavigationHelp => '在边缘按左右键可跳到另一端。长按方向键可在两侧连续移动。';

  @override
  String get networkReceive => '接收';

  @override
  String get networkSend => '发送';

  @override
  String get landscapeCelestialBodies => '太阳和月亮';

  @override
  String get landscapeStarRotation => '星空旋转';

  @override
  String get tvPowerTitle => '电源管理';

  @override
  String remotePowerWithConfirmation(String action) {
    return '$action（需确认）';
  }

  @override
  String remotePowerWithoutConfirmation(String action) {
    return '$action（无需确认）';
  }

  @override
  String get tvPowerOff => '关闭设备';

  @override
  String get tvPowerReboot => '重启设备';

  @override
  String get tvPowerOffConfirm => '将设备置于待机模式？';

  @override
  String get tvPowerRebootConfirm => '重启设备？打开的应用将关闭。';

  @override
  String get tvPowerSent => '命令已发送';

  @override
  String get tvPowerFailed => '无法发送。请检查 ADB 或无障碍权限。';

  @override
  String get tvPowerHelp =>
      '关闭通过 CuteLauncher 无障碍服务或本地 ADB 进入待机模式。重启需要 ADB。电视盒子上的命令控制盒子本身；电视行为取决于 HDMI-CEC 和固件。';

  @override
  String get cleanerLists => '停用列表';

  @override
  String get cleanerRecovery => '备份与恢复';

  @override
  String get cleanerExports => '报告';

  @override
  String get cleanerUpdating => '正在更新应用列表…';

  @override
  String get cleanerRefreshRequired => '请先刷新应用列表。';

  @override
  String get cleanerPreinstalled => '预装应用';

  @override
  String get cleanerNotSystem => '这不是系统应用。';

  @override
  String get cleanerMinimalRisk => '最低';

  @override
  String get cleanerCacheFailure => '无法保存列表以供下次使用。';

  @override
  String get cleanerUserApps => '用户应用';

  @override
  String get cleanerPreinstalledApps => '预装应用';

  @override
  String get cleanerSystemApps => '系统应用';

  @override
  String get cleanerBaseline => '基准初始状态';

  @override
  String get cleanerManualStates => '管理手动状态';

  @override
  String get cleanerManualSave => '保存当前状态';

  @override
  String get cleanerDateName => '使用日期和时间';

  @override
  String get cleanerCustomName => '输入名称';

  @override
  String get cleanerStateExport => '将保存的状态导出到文件';

  @override
  String get cleanerStateRestoreHelp =>
      '将恢复此固件保存的应用启用与停用状态。创建备份后安装的应用保持不变。缺失的应用及停用受保护组件的操作将被跳过。不恢复应用数据。';

  @override
  String get cleanerCopiesHelp =>
      '首次成功刷新列表时仅创建一次基准状态，启动器无法删除或覆盖它，且仅适用于该固件。手动状态记录当前应用模式、名称及日期，可恢复、删除和导出。备份不包含 APK 或应用数据。恢复需要本地 ADB。崩溃循环保护触发时，启动器会尝试自动恢复基准状态。清除启动器数据或卸载启动器也会删除这些备份；无法防止 root 访问。';

  @override
  String get cleanerSearch => '按名称搜索';

  @override
  String get cleanerCatalogUpdateRequired => '请先从 GitHub 更新目录。';

  @override
  String get cleanerNoSearchResults => '没有匹配的条目。';

  @override
  String get cleanerAlreadyDisabled => '此列表中本电视上存在的应用均已停用。';

  @override
  String get cleanerAlreadyEnabled => '此列表中本电视上存在的应用均已启用。';

  @override
  String get cleanerNoInstalled => '此电视未安装列表中的匹配应用。';

  @override
  String get cleanerListProtected => '其余应用受到保护，无法停用。';

  @override
  String get cleanerSnapshotFailed => '无法保存快照。未停用任何应用。';

  @override
  String get cleanerDisableAllPreinstalled => '停用所有预装应用';

  @override
  String get cleanerEnableAllPreinstalled => '启用所有预装应用';

  @override
  String get cleanerPreinstalledList => '预装应用列表';

  @override
  String cleanerBeforeList(String listName) {
    return '应用列表前：$listName';
  }

  @override
  String get sleepTimerSettings => '关机定时器设置';

  @override
  String get sleepTimerPresets => '定时器';

  @override
  String get sleepTimerDisplay => '定时器运行时显示';

  @override
  String get sleepTimerRemaining => '剩余时间';

  @override
  String get sleepTimerEndTime => '关机时间';

  @override
  String get sleepTimerBoth => '剩余时间和关机时间';

  @override
  String get sleepTimerShowSeconds => '显示秒数';

  @override
  String get sleepTimerShowOverApps => '在应用上方显示定时器';

  @override
  String get sleepTimerOverlayHelp => '若要在应用上方显示，请启用 CuteLauncher 无障碍服务。';

  @override
  String get sleepTimerCloseAfterSelection => '选择定时器后关闭小组件';

  @override
  String get sleepTimerAdd => '添加定时器';

  @override
  String get sleepTimerEdit => '编辑定时器';

  @override
  String get sleepTimerHoursLabel => '小时';

  @override
  String get sleepTimerMinutesLabel => '分钟';

  @override
  String get sleepTimerSecondsLabel => '秒';

  @override
  String get sleepTimerInvalidDuration => '请输入大于零的时长：小时0–999999，分钟和秒0–59。';

  @override
  String get sleepTimerDeleteConfirmation => '删除此定时器？正在运行的倒计时将继续。';

  @override
  String get sleepTimerResetConfirmation =>
      '恢复默认定时器及顺序？自定义定时器将被删除。正在运行的倒计时将继续。';

  @override
  String get sleepTimerReorderHint =>
      '◄ / ► 或长按OK开始移动。▲ / ▼调整顺序，并在显示和隐藏列表之间移动。OK结束移动。';

  @override
  String get sleepTimerSaveFailed => '无法保存定时器设置。';

  @override
  String get sleepTimerVisible => '显示';

  @override
  String get sleepTimerHidden => '隐藏';

  @override
  String get sleepTimerReset => '重置定时器';

  @override
  String get cleanerListSnapshotHelp =>
      '停用列表时仅自动保存选定应用的快照。恢复不会更改其他应用。手动和自动快照总上限为100份。保存失败时不会开始停用。';

  @override
  String get trafficSettings => '流量设置';

  @override
  String get trafficTitle => '流量';

  @override
  String get trafficReceived => '已接收';

  @override
  String get trafficSent => '已发送';

  @override
  String get trafficTotal => '总计';

  @override
  String get stopApp => '停止';

  @override
  String get backgroundImageFormats =>
      '图片：JPEG、PNG、WebP、GIF、BMP。最大8 MiB、4800万像素，每边不超过16,384像素。';

  @override
  String get backgroundMediaFormats =>
      '图片：JPEG、PNG、WebP、GIF、BMP。最大8 MiB、4800万像素，每边不超过16,384像素。\n视频：MP4/M4V、WebM、MKV。最大256 MiB、3840×2160。编解码器支持取决于电视；建议使用H.264 MP4。静音循环播放，离开主屏幕后暂停。视频不包含在备份中。';

  @override
  String get backgroundFormatError => '格式不受支持或文件已损坏。请选择所列格式的有效文件。';

  @override
  String backgroundFileTooLarge(String maxMiB) {
    return '文件过大。最大$maxMiB MiB。请选择较小的文件。';
  }

  @override
  String get backgroundImageResolutionError => '图片过大：最多4800万像素，每边不超过16,384像素。';

  @override
  String get backgroundVideoResolutionError =>
      '视频分辨率过高。请选择不超过3840×2160（或2160×3840）的视频。';

  @override
  String get backgroundVideoCodecError =>
      '电视无法播放该视频：编解码器不受支持或文件已损坏。请尝试H.264 MP4。';

  @override
  String get backgroundFileApplied => '已选择文件并更新背景。';

  @override
  String get noticePosition => '通知位置';

  @override
  String get noticeBottomRight => '右下角';

  @override
  String get noticeBottomLeft => '左下角';

  @override
  String get noticeTopRight => '右上角';

  @override
  String get noticeTopLeft => '左上角';

  @override
  String get overlayAppearance => '应用上层显示样式';

  @override
  String get overlayAppearanceTopPanel => '与顶部面板相同';

  @override
  String get overlayAppearanceDark => '深色';

  @override
  String get overlayWhereToShow => '显示位置';

  @override
  String get overlayAtPanelWidget => '顶部面板中小组件的位置';

  @override
  String get notificationOpenFailed => '无法打开通知操作。该操作可能已不可用。';

  @override
  String get adbWifiOverride => '仍然停用…';

  @override
  String get adbWifiRiskTitle => '仍要冒险停用吗？';

  @override
  String get adbWifiRiskEffect => '内置启动器和 Google 设置向导将被停用。';

  @override
  String get adbWifiRiskLoss =>
      'Android 可能删除已保存的 Wi-Fi 网络。Wi-Fi 连接和无线 ADB 可能无法使用。';

  @override
  String get adbWifiRiskRecovery => '重新启用设置向导不会自动恢复已删除的网络。您需要重新连接 Wi-Fi 并输入密码。';

  @override
  String get adbWifiRiskConsent => '仅在知道 Wi-Fi 密码的情况下继续。';

  @override
  String get adbWifiDisable => '停用';

  @override
  String get recentAppsTitle => '已打开的应用';

  @override
  String get recentAppsPanelType => '面板';

  @override
  String get recentAppsAutomatic => '自动';

  @override
  String get recentAppsCustom => 'CuteLauncher 面板';

  @override
  String get recentAppsSystem => '内置面板';

  @override
  String get recentAppsOpen => '打开面板';

  @override
  String get recentAppsRefresh => '刷新';

  @override
  String get recentAppsCloseAll => '全部关闭';

  @override
  String get recentAppsEmpty => '没有具有打开任务的电视应用';

  @override
  String get recentAppsUnavailable => '无法显示已打开的应用。请检查 ADB 和无障碍权限。';

  @override
  String get recentAppsHelp =>
      '仅显示具有打开任务的电视应用。“全部关闭”会停止此列表中的用户应用。请在按键映射器中分配按钮。CuteLauncher 面板需要 ADB 和无障碍权限。';

  @override
  String get recentAppsHomeHint => 'Home 仅支持长按分配。短按返回 CuteLauncher。分配在启动器外也有效。';

  @override
  String get sectionRulesHelp =>
      '标准分区可重命名、移动或隐藏，但不能删除；至少保留一个可见分区。所有应用、电视应用和非电视应用按启动类型自动分类，与应用名称无关；隐藏会从这三个列表中移除应用。收藏和自定义分区需手动添加。应用可按手动顺序、名称、使用频率或最近启动排序，各分区可单独设置外观。继续观看显示应用推荐，可隐藏或移动。';

  @override
  String get remoteMappingNamePlaceholder => '按钮名称';

  @override
  String get remoteMappingAssign => '分配按钮';

  @override
  String get remoteMappingCapture => '捕获';

  @override
  String remoteMappingCaptured(String key) {
    return '已捕获按钮：$key';
  }

  @override
  String get remoteMappingCaptureHint => '选择“捕获”，然后按遥控器按钮。可以重新捕获。选择“确定”接受。';

  @override
  String get remoteMappingCaptureTimeout => '未捕获按钮。请重试。';

  @override
  String get remoteMappingCaptureFailed => '无法捕获。请检查无障碍服务权限。';

  @override
  String get remoteMappingServiceRequired => '请在访问设置中连接无障碍服务。';

  @override
  String get remoteMappingKeyRequired => '未分配按钮。请选择“分配按钮”并捕获按钮。';

  @override
  String get remoteMappingHomeHoldRequired => 'Home 按钮请选择长按。';

  @override
  String get remoteMappingAppRequired => '请选择要启动的应用。';

  @override
  String get remoteMappingUrlRequired => '请输入或导入 Webhook URL。';

  @override
  String get remoteMappingUrlInvalid =>
      'URL 无效。请使用带路径的 HTTPS 或本地 HTTP，不含空格、凭据或 # 片段。';

  @override
  String get remoteMappingSaveFailed => '无法保存。请重试；编辑器中的值已保留。';

  @override
  String get remoteMappingDeleteFailed => '无法删除。请重试。';

  @override
  String get remoteMappingRecents => '已打开应用面板';

  @override
  String get remoteMappingImport => '从文件导入 URL';

  @override
  String get remoteMappingImportHint =>
      '请选择仅包含 Webhook URL 的 UTF-8 文本文件，不含命令或说明。换行符会被删除。';

  @override
  String get remoteMappingImportInvalid =>
      '文件必须仅包含有效的 Webhook URL：HTTPS 或本地 HTTP，不含命令或说明。';

  @override
  String get remoteMappingImportFailed => '无法读取。请选择可访问且不超过 64 KB 的 UTF-8 文本文件。';

  @override
  String get vpnTitle => 'VPN';

  @override
  String get vpnSettings => 'VPN 设置';

  @override
  String get vpnApp => 'VPN 应用';

  @override
  String get vpnAutomatic => '自动';

  @override
  String get vpnNone => '未选择';

  @override
  String get vpnProfile => 'VPN 配置';

  @override
  String get vpnOnlyActive => '仅在连接时显示';

  @override
  String get vpnShowName => '显示应用名称';

  @override
  String get vpnColor => '用颜色突出显示连接';

  @override
  String get vpnNotify => '通知命令执行结果';

  @override
  String get vpnConnected => 'VPN 已连接';

  @override
  String get vpnDisconnected => 'VPN 已断开';

  @override
  String get vpnUnknown => '无法获取 VPN 状态';

  @override
  String get vpnConnect => '连接';

  @override
  String get vpnDisconnect => '断开';

  @override
  String get vpnOpenApp => '打开 VPN 应用';

  @override
  String get vpnAndroidSettings => 'Android VPN 设置';

  @override
  String get vpnAllowControl => '允许控制 VPN';

  @override
  String get vpnFailed => 'VPN 操作失败';

  @override
  String get vpnUnsupported => '此客户端不支持直接控制。您可以打开应用。';

  @override
  String get vpnOther => '另一个或未识别的 VPN 已连接，无法控制。';

  @override
  String get vpnStartup => '电视启动时连接 VPN';

  @override
  String get vpnPending => '正在等待 VPN 连接';

  @override
  String get vpnHelp =>
      '自动选择会识别当前 VPN 并记住它以便重新连接。识别应用和配置需要已连接的本地 ADB。直接控制支持 AmneziaWG 和 WireGuard，需要授予控制权限并在客户端启用远程控制。 Happ 和 MantaRay 使用客户端中选择的配置。';

  @override
  String get vpnProfileHelp =>
      '输入 VPN 应用中的准确配置名称：最多 15 个拉丁字母、数字和 _ = + . - 字符。手动连接时会在可用的情况下自动识别名称。';

  @override
  String get vpnStartupHelp =>
      'VPN 启动独立于常规启动操作。请先配置客户端及其权限。等待网络有时间限制，已有 VPN 不会被替换。只有启动器进程运行时才能检测唤醒。';

  @override
  String get vpnStartupMethod => 'VPN 启动方式';

  @override
  String get vpnStartupClient => '通过 VPN 应用';

  @override
  String get vpnStartupAlwaysOn => 'Android 始终开启 VPN';

  @override
  String get vpnAlwaysOnManaged =>
      '此 VPN 由 Android 始终开启模式管理。请在启动设置或 Android 设置中关闭该模式。';

  @override
  String get vpnRestartRequired => '请重启电视以应用系统模式。';

  @override
  String get vpnAlwaysOnHelp =>
      '通过本地 TCP ADB 将已配置的客户端设为始终开启 VPN。Android 会在电视重启后应用选择。不会启用或更改阻止无 VPN 连接的设置。退出该模式将恢复之前的系统选择。';

  @override
  String get vpnClientConfirmation => '请在 MantaRay 窗口中确认命令。';

  @override
  String get informationTapAction => '点击信息块时';

  @override
  String get informationShowBoth => '天气和日历';

  @override
  String get weatherTextFormat => '天气文本格式';

  @override
  String get weatherTextTemperature => '温度';

  @override
  String get weatherTextApparent => '体感温度';

  @override
  String get weatherTextConditions => '天气状况';

  @override
  String get weatherTextHumidity => '湿度';

  @override
  String get weatherTextLow => '今日最低温';

  @override
  String get weatherTextHigh => '今日最高温';

  @override
  String get weatherTextLiteral => '自定义文本';

  @override
  String get weatherTextNewline => '换行';

  @override
  String get weatherTextBefore => '数据块前';

  @override
  String get weatherTextAfter => '数据块后';

  @override
  String get weatherTextYourFormat => '你的格式';

  @override
  String get weatherTextAdd => '添加数据块';

  @override
  String get weatherTextMoveEarlier => '向前移动';

  @override
  String get weatherTextMoveLater => '向后移动';

  @override
  String get weatherTextHelp =>
      '输入文本及大括号内的代码，或用按钮在光标处插入代码。不区分大小写。值外的圆括号会在数据缺失时一同隐藏。普通大括号需输入两次。允许一个换行。 可以输入文字、数字、空格和任何可打印符号，例如：() [] / : ; + − ° % ·.';

  @override
  String get weatherTextSaveError => '无法保存天气文本格式。';

  @override
  String get weatherTextSampleCity => '北京';

  @override
  String weatherTextMetersPerSecond(String speed) {
    return '$speed 米/秒';
  }

  @override
  String weatherFeelsLike(String temperature) {
    return '体感温度 $temperature';
  }

  @override
  String get weatherForecastTitle => '天气预报';

  @override
  String get weatherForecastPeriod => '预报时段';

  @override
  String weatherForecastDays(int days) {
    return '$days天';
  }

  @override
  String get weatherForecastView => '预报显示方式';

  @override
  String get weatherForecastCards => '简洁卡片';

  @override
  String get weatherForecastList => '详细列表';

  @override
  String weatherForecastAvailable(int available, int requested) {
    return '可用天数：$requested天中的$available天';
  }

  @override
  String get weatherForecastTvTime => '预报日期使用电视时间';

  @override
  String get weatherClear => '晴';

  @override
  String get weatherCloudy => '多云';

  @override
  String get weatherFog => '雾';

  @override
  String get weatherWind => '风';

  @override
  String get weatherPrecipitation => '降水概率';

  @override
  String get showVolume => '显示音量';

  @override
  String get audioStatusTitle => '音量和音频输出';

  @override
  String get audioOutputTv => '电视';

  @override
  String get audioOutputHeadphones => '耳机';

  @override
  String get audioOutputMultiple => '多个';

  @override
  String get audioMuted => '已静音';

  @override
  String get backgroundStartupTitle => '后台应用';

  @override
  String get backgroundStartupFailed => '无法加载或保存设置';

  @override
  String get backgroundStartupRetry => '重试';

  @override
  String get backgroundStartupEmpty => '没有用户应用';

  @override
  String get backgroundStartupUnavailable => '无法在后台启动';

  @override
  String get backgroundStartupRequested => '已请求启动';

  @override
  String get backgroundStartupHelp =>
      '勾选要在电视开机后在后台启动一次的应用。CuteLauncher 须在开机后一分钟内打开：将其设为主屏幕或开启开机启动。应用会在主屏幕后依次启动；勾选不会立即启动。操作遥控器或离开启动器会取消其余启动。休眠唤醒不会再次启动。不支持此模式的应用无法选择。启动不会启用应用内功能，也不保证持续运行。请在应用内授予权限并设置后台运行。Android 或电视固件可能会停止应用。选择仅保存在本电视上。';

  @override
  String get backgroundStartupToggle => '后台自动启动';

  @override
  String get systemWidgetSettings => '系统小组件设置';

  @override
  String get systemShowCpu => '在面板中显示 CPU';

  @override
  String get systemShowRam => '在面板中显示 RAM';

  @override
  String get systemStorage => '存储空间：可用 / 总计';

  @override
  String get systemUptime => '运行时间（小时:分钟）';

  @override
  String get systemTemperature => 'CPU 温度';

  @override
  String get systemAvailable => '可用 RAM';

  @override
  String get systemHistory => '过去一小时 · 平均值和峰值';

  @override
  String get systemNow => '现在';

  @override
  String get systemHourAgo => '−60 分钟';

  @override
  String get systemUpdateInterval => '更新间隔';

  @override
  String get systemWidgetHelp =>
      '面板可见时按所选的1至10秒间隔更新（默认为5秒）。图表显示每分钟的平均值和峰值。使用其他应用、休眠和读取失败的时段显示为空白。历史记录保存在内存中，启动器进程重启后会清除。CPU 和温度数据取决于固件。关闭两个面板数值后将只显示图标。';

  @override
  String get slideshowBrowseFolders => '浏览文件夹';

  @override
  String get slideshowEnterFolderPath => '输入文件夹路径';

  @override
  String get slideshowSystemPicker => '在外部文件浏览器中选择';

  @override
  String get slideshowFolderPath => '文件夹路径';

  @override
  String get slideshowUseFolder => '使用此文件夹';

  @override
  String get slideshowParentFolder => '上级文件夹';

  @override
  String get slideshowStoragePermission => '请在 Android 设置中允许文件访问，以使用内置文件浏览器。';

  @override
  String get slideshowPickerUnavailable => '此电视没有文件夹选择器。请使用内置浏览器或手动输入路径。';

  @override
  String get slideshowFolderUnavailable => '无法访问文件夹。请检查路径、存储设备连接和文件访问权限。';

  @override
  String get slideshowStorageHelp =>
      '内置浏览器可读取电视和已连接存储设备上的文件夹。Android 11 及以上请允许所有文件访问；Android 9–10 请允许存储访问。也可手动输入路径，例如 /storage/emulated/0/Pictures。不会修改文件。';

  @override
  String get fileBrowserTitle => '选择文件';

  @override
  String get filePickerChoose => '选择文件浏览器';

  @override
  String get filePickerSystem => '外部文件浏览器';

  @override
  String get filePickerBuiltIn => '内置文件浏览器';

  @override
  String get fileBrowserEmpty => '没有可显示的项目';

  @override
  String get fileBrowserUnavailable => '无法打开此位置。请检查访问权限后重试。';

  @override
  String get networkAndVpnGroup => '网络和 VPN';

  @override
  String get soundAndInputsGroup => '声音和输入源';

  @override
  String get timerAndNightModeGroup => '定时器和夜间模式';

  @override
  String get systemSettingsGroup => '系统设置';

  @override
  String get appChannelsTitle => '应用内容流';

  @override
  String get appChannelsHelp =>
      '最多选择16个内容流。可用性取决于应用发布的频道和电视固件。空内容流会隐藏。选择仅保存在此电视上。';

  @override
  String get appChannelsUnavailable => '无法读取内容流。请检查电视节目访问权限。';

  @override
  String get appChannelsEmpty => '没有可用的应用内容流。';

  @override
  String get appChannelsRefresh => '刷新内容流';

  @override
  String get appChannelsLaunchFailed => '无法打开此内容。';

  @override
  String get appChannelsSaveFailed => '无法保存选择。最多可选择16个内容流。';

  @override
  String get sectionDeleteConfirm => '删除此分区？已安装的应用将保留。';

  @override
  String get sectionDeleteFailed => '无法删除分区。请重试。';

  @override
  String get appChannelsAccess => '应用信息流访问权限';

  @override
  String get appChannelsMissing => '信息流不可用';

  @override
  String get wallpaperRefresh => '刷新壁纸';

  @override
  String get wallpaperDimmingHelp => '100%保持原始调暗程度，200%将其加倍。这不是黑色蒙层的不透明度。';

  @override
  String get resetLauncherSettings => '重置所有设置';

  @override
  String get resetLauncherSettingsConfirmation =>
      '将删除 CuteLauncher 的所有设置和本地数据，包括分区、收藏、遥控器映射、连接及应用存储中的文件。CuteLauncher 将关闭，下次启动时将如同全新安装。需要重新授予访问权限。CuteLauncher 存储之外的文件和其他应用将保留。';

  @override
  String get resetLauncherSettingsError => '无法完成设置重置。请重试。';

  @override
  String get fileBrowserCurrentFolder => '当前文件夹';

  @override
  String get fileBrowserFileName => '文件名';

  @override
  String get fileBrowserNoFolders => '没有子文件夹';

  @override
  String get fileBrowserNoFiles => '没有匹配的文件';

  @override
  String get fileBrowserPartial => '仅显示文件夹的部分内容';

  @override
  String get fileBrowserReadNameHint => '← 上级文件夹 · → 完整名称';

  @override
  String fileBrowserSavedTo(String path) {
    return '已保存：$path';
  }

  @override
  String get backupDriveConnect => '连接 Google 云端硬盘';

  @override
  String get discardChangesTitle => '放弃更改？';

  @override
  String get discardChangesMessage => '未保存的更改将丢失。';

  @override
  String get backgroundFileUnavailable => '文件不可用';

  @override
  String get backupLastSuccess => '上次成功操作：';

  @override
  String get informationObjectPlacement => '显示位置';

  @override
  String get informationPlacement => '信息块位置';

  @override
  String get informationOnBackground => '壁纸上';

  @override
  String get informationBackgroundPosition => '信息块位置';

  @override
  String get informationBackgroundOffset => '水平偏移';

  @override
  String get informationBackgroundResetOffset => '重置偏移';

  @override
  String get informationBackgroundContentAlignment => '块内对齐';

  @override
  String get informationBackgroundHelp =>
      '分别为时钟、日期和天气选择顶部面板、壁纸或隐藏。壁纸上的元素不响应操作，也不改变磁贴位置。快捷设置保持独立。 两个开关均作用于整个背景信息块：时间、日期和天气。第一个取消山脉遮挡，第二个将信息块显示在云、雨雪和雾的前方。';

  @override
  String get informationAboveLandscape => '显示在风景前方';

  @override
  String get informationAboveWeather => '显示在天气效果前方';

  @override
  String get informationTime => '时钟';

  @override
  String get informationDate => '日期';

  @override
  String get backgroundInformationAppearance => '壁纸上的外观';

  @override
  String onlineWallpaperFailureStage(String stage) {
    String _temp0 = intl.Intl.selectLogic(stage, {
      'initialize': '准备存储',
      'metadata': '请求图片源',
      'download': '下载图片',
      'validation': '验证图片',
      'save': '保存壁纸',
      'other': '保存壁纸',
    });
    return '$_temp0';
  }

  @override
  String onlineWallpaperFailureReason(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'dns': '无法解析服务器地址（DNS）。',
      'connection': '无法建立或维持与服务器的连接。',
      'tls': '安全连接或证书错误（TLS）。',
      'timeout': '请求超时。',
      'http': '服务器返回错误。',
      'redirect': '重定向无效或次数过多。',
      'insecureUrl': '链接不安全：需要不含登录信息的 HTTPS。',
      'tooLarge': '响应超过大小限制。',
      'dimensions': '图片尺寸超过限制。',
      'invalidResponse': '图片源返回了无效数据。',
      'noImage': '图片源未返回符合条件的新图片。',
      'invalidImage': '文件已损坏或图片格式不受支持。',
      'storage': '无法读取或写入壁纸文件。',
      'unknown': '未知错误。',
      'other': '未知错误。',
    });
    return '$_temp0';
  }

  @override
  String get informationPanelAppearance => '面板外观';

  @override
  String get informationData => '格式和数据';

  @override
  String get informationGroupingMinimum => '至少需要两个元素';

  @override
  String get screenshotSceneMode => '截图模式';

  @override
  String get screenshotSceneHour => '小时';

  @override
  String get screenshotSceneMinute => '分钟';

  @override
  String get screenshotSceneHelp =>
      '设置风景和背景时钟的时间，以及风景的天气。关闭设置后仍然生效。不更改系统时间、天气数据或已保存的设置。此版本重新启动时为16:00，多云。';

  @override
  String get autoLaunchWaitForInternet => '等待互联网连接';

  @override
  String get autoLaunchWaitForInternetHelp =>
      '延迟结束后，最多等待60秒以确认互联网连接，然后启动应用。操作遥控器或离开主屏幕会取消启动。';

  @override
  String get remoteMappingIgnore => '忽略按钮';

  @override
  String get remoteMappingBlackScreen => '切换 Black Screen';

  @override
  String get remoteMappingBlackOverlay => '黑屏';

  @override
  String get remoteMappingBlackOverlayHelp => '按一次隐藏画面，再按一次或按返回键恢复画面。电视保持开启。';

  @override
  String get remoteMappingTclScreenOff => '关闭 TCL 屏幕';

  @override
  String get remoteMappingTclScreenOffHelp =>
      '在兼容的 TCL 电视上启用纯音频模式。如果 Android 阻止启动，则需要本地 ADB 连接。';

  @override
  String get remoteMappingBlackScreenHelp =>
      '按一次显示黑色遮罩，再按一次隐藏。需要 jApp 的 Black Screen 付费版，并允许其在其他应用上层显示。';

  @override
  String get adbHomeDependencyProtected => '已阻止停用：发现系统功能依赖或无法检查依赖关系。详情请查看诊断。';

  @override
  String get cleanerOperationResultTitle => '上次操作结果';

  @override
  String get cleanerUnchanged => '未更改';

  @override
  String get cleanerNotAttempted => '未执行';

  @override
  String get cleanerPackageMissing => '应用不存在';

  @override
  String get cleanerReadFailed => '无法读取状态';

  @override
  String get cleanerJournalFailed => '无法保存恢复日志';

  @override
  String get cleanerCommandFailed => '命令执行失败';

  @override
  String get cleanerVerificationFailed => '未能确认新状态';

  @override
  String get inputsCecStateOnly => '仅使用 CEC 判断 HDMI 状态';

  @override
  String get inputsCecStateOnlyHelp =>
      '当固件报告错误的端口状态时启用。仅使用 CEC 数据；没有数据时状态为未知。所有输入仍保留在列表中。';

  @override
  String get backgroundInformationOrderHint =>
      'OK 或 ◄ / ►：开始或结束移动；▲ / ▼：更改从上到下的顺序；返回：结束。';

  @override
  String get homeStyleNeedsSectionBackground => '请选择分区背景颜色。';

  @override
  String get updateWrongPackage => '此 APK 属于其他应用。请从官方来源下载 CuteLauncher 更新。';

  @override
  String get updateNotNewer => '下载的 APK 与当前构建相同或更旧。只能安装更新的构建。';

  @override
  String get updateSignersUnavailable =>
      'Android 未提供已安装应用或 APK 的证书。无法验证签名，已阻止安装。';

  @override
  String get updateSignatureMismatch =>
      'APK 签名与已安装的 CuteLauncher 不同。已阻止更新。请告知开发者当前版本的来源。';

  @override
  String get updateInvalidFile => 'Android 无法读取 APK：文件缺失、为空、过大或无法识别。请重新下载更新。';

  @override
  String get updateVerificationFailed =>
      '验证 APK 时出错，已阻止安装。请重试；如果再次出现，请向开发者发送诊断报告。';

  @override
  String get feedFormat => '封面格式';

  @override
  String get feedFormatAuto => '自动';

  @override
  String get feedFormatLandscape => '横向';

  @override
  String get feedFormatPortrait => '纵向';

  @override
  String get feedFormatHelp =>
      '自动模式根据应用信息或最先加载的三张封面为每个内容流选择统一格式，并保存在此电视上。数量相同时使用横向。其他比例的封面会完整显示在背景上。也可手动选择格式。';

  @override
  String get networkSpeedTitle => '网络速度';

  @override
  String get networkSpeedSettings => '网络速度设置';

  @override
  String get networkSpeedInterval => '更新间隔';

  @override
  String get networkSpeedHelp =>
      '设备各网络接口的平均接收和发送速率。这是当前流量，并非连接速度测试。隐藏组件、进入后台或关闭屏幕时暂停采样。暂停后的首次读数显示为 —。';

  @override
  String networkSpeedUnit(String unit) {
    return '$unit/秒';
  }

  @override
  String get customDateFormat => '自定义格式';

  @override
  String get customDateFormatError => '请使用帮助中的日期符号。文字须用单引号括起，并闭合引号。';

  @override
  String get customDateFormatHelp =>
      'd / dd — 日\nM / MM — 月份数字\nMMM / MMMM — 月份简称 / 全称\nEEE / EEEE — 星期简称 / 全称\nyy / yyyy — 年\nL…LLLL — 独立形式月份\nD…DDD — 年内天数；G — 纪元\n分隔符：空格、. / - ,\n文字：\'日期:\'；单个引号：\'\'\n区分大小写。不支持时间符号。\n示例：EEEE, d. MMMM yyyy';

  @override
  String get apodWallpaper => 'NASA APOD — 每日天文一图';

  @override
  String get apodWallpaperHint =>
      'NASA APOD的每日图片。发布视频时使用近期图片。图片尺寸和宽高比各不相同。此处显示作者信息和发布页面链接。图片权利归各自权利人所有。';

  @override
  String get backupDriveClientImport => '从JSON导入Client ID和Secret';

  @override
  String get backupDriveClientImported => '已导入客户端信息。请连接Google Drive。';

  @override
  String get backupDriveClientImportFailed =>
      '无法导入。请选择Google Cloud中TVs and Limited Input devices类型的JSON文件，大小不超过64 KiB。';

  @override
  String get dateFormatPreview => '预览';

  @override
  String get backupDriveConnectionStatus => 'Google Drive连接状态';

  @override
  String get backupDriveReconnect => '重新连接Google Drive';

  @override
  String get backupSyncRefresh => '刷新';

  @override
  String get backupSyncRefreshFailed => '无法同步设置。请检查存储访问权限后重试。';

  @override
  String get backupThisTv => '此电视';

  @override
  String get backupOtherTv => '其他电视';

  @override
  String get backupTvUnknown => '电视未知';

  @override
  String get panelTooltips => '在所有面板中显示工具提示';

  @override
  String get networkStorageTitle => '网络存储';

  @override
  String get usbStorageTitle => 'USB 存储设备';

  @override
  String get storageScreenUnavailable => '存储设置不可用。';

  @override
  String get appSections => '应用所在分区';

  @override
  String get noAppSections => '此应用不在任何分区中。';

  @override
  String get volumeWidgetSettings => '音量设置';

  @override
  String get volumeUpdateInterval => '更新间隔';

  @override
  String get showVolumeOverlay => '在应用上方显示音量';

  @override
  String get volumeOverlayHelp => '需要启用 CuteLauncher 无障碍服务。';

  @override
  String get clockHoursColor => '小时颜色';

  @override
  String get clockMinutesColor => '分钟颜色';

  @override
  String get clockColorMode => '时钟颜色模式';

  @override
  String get clockSingleColor => '时钟使用同一颜色';

  @override
  String get clockSplitColors => '时钟使用不同颜色';

  @override
  String get clockShowColon => '显示冒号';

  @override
  String get appLaunchGroup => '启动';

  @override
  String get appManagementGroup => '应用管理';

  @override
  String get appCheckProcess => '检查状态';

  @override
  String get appProcessNotChecked => '尚未检查状态';

  @override
  String get appProcessRunning => '正在运行';

  @override
  String get appProcessStopped => '未运行';

  @override
  String get weatherCustomServer => '自定义服务器 (Open-Meteo)';

  @override
  String get widgetSettings => '小组件设置';

  @override
  String get weatherServerUrlImport => '从文件导入地址';

  @override
  String get weatherServerUrlImportError =>
      '导入失败：请选择不超过 4 KB 且仅包含服务器基本 HTTPS 地址的 UTF-8 文本文件。';

  @override
  String get weatherImportReadError => '无法读取导入文件。请检查文件访问权限。';

  @override
  String get weatherImportEncodingError => '导入失败：文件不是 UTF-8 编码。';

  @override
  String get weatherImportTooLargeError => '导入失败：文件超过 4 KB。';

  @override
  String get weatherImportSaveError => '无法保存该值。请重新输入或导入。';

  @override
  String get weatherTokenInvalid => '令牌格式无效。';

  @override
  String get weatherServerUrl => '服务器 HTTPS 地址';

  @override
  String get weatherServerUrlHint =>
      '请输入基本 HTTPS 网址，不含 /v1/forecast、凭据、查询参数或片段。';

  @override
  String get weatherServerCoordinates => '输入坐标';

  @override
  String get weatherServerCoordinatesHint =>
      '请输入纬度和经度，用逗号分隔，小数点用英文句点。示例：50.0, 30.0。';

  @override
  String get weatherIconPack => '天气图标套装';

  @override
  String get weatherIconsStandard => '标准';

  @override
  String get weatherIconsOutline => '轮廓';

  @override
  String get weatherIconsSolid => '实心';

  @override
  String get weatherIconsDuotone => '双色';

  @override
  String get weatherIconsPixel => '像素';

  @override
  String get weatherTextColor => '天气文字颜色';

  @override
  String get weatherIconColor => '天气图标颜色';

  @override
  String get weatherIconFollowsText => '与天气文字同色';

  @override
  String get informationDateColor => '日期颜色';

  @override
  String get clockTextColor => '时钟颜色';

  @override
  String get weatherServerToken => 'Bearer 令牌（可选）';

  @override
  String get weatherServerTokenImport => '从文件导入令牌';

  @override
  String get weatherServerTokenImportError =>
      '导入失败：请选择不超过 4 KB 且仅包含令牌的 UTF-8 文本文件。';

  @override
  String get weatherCheckConnection => '检查连接';

  @override
  String get weatherServerAccessError => '服务器拒绝访问。请检查令牌和服务器权限。';

  @override
  String get weatherServerParametersError => '服务器拒绝了请求参数或坐标。';

  @override
  String get informationComposition => '对象格式';

  @override
  String get informationLayout => '信息块布局';

  @override
  String get informationPositionSize => '位置与大小';

  @override
  String get informationTypography => '字体与数字';

  @override
  String get informationColors => '颜色与效果';

  @override
  String get informationLayers => '背景图层';

  @override
  String get informationAvoidOverlap => '避免设置遮挡信息块';

  @override
  String get weatherPresetBrief => '简洁';

  @override
  String get weatherPresetFeels => '包含体感温度';

  @override
  String get weatherPresetDetails => '详细';

  @override
  String get informationAvoidOverlapHelp =>
      '编辑背景时，设置菜单会暂时移到遮挡信息块较少的一侧。两侧都没有空间时会显示独立预览。退出后恢复通常的菜单位置。';

  @override
  String get informationProfileHelp =>
      '面板与背景的格式和颜色相互独立，天气来源共用。快捷设置和预报使用顶部面板的外观；快捷设置的显示与合并选项单独保存。';

  @override
  String get weatherCompactLayout => '天气与日期合并显示时，天气换行显示为空格。保存的格式保持不变。';

  @override
  String get weatherFormatInvalid => '请添加天气字段。最多允许12个块、1个换行，每个文本字段最多60个字符。';

  @override
  String get fileManagerPreference => '文件管理器';

  @override
  String get fileManagerAsk => '每次询问';

  @override
  String get fileManagerBuiltIn => '内置';

  @override
  String get fileManagerExternal => '外部';

  @override
  String get fileBrowserStartFolder => '起始文件夹';

  @override
  String get fileBrowserStorage => '电视存储空间';

  @override
  String get fileBrowserDownloads => '下载';

  @override
  String get fileBrowserLastFolder => '上次打开的文件夹';

  @override
  String get fileBrowserSort => '排序方式';

  @override
  String get fileBrowserSortName => '名称';

  @override
  String get fileBrowserSortDate => '修改日期';

  @override
  String get fileBrowserSortSize => '大小';

  @override
  String get fileBrowserOrder => '排序顺序';

  @override
  String get fileBrowserAscending => '升序';

  @override
  String get fileBrowserDescending => '降序';

  @override
  String get fileBrowserFoldersFirst => '始终将文件夹置顶';

  @override
  String get fileBrowserShowHidden => '显示隐藏文件和文件夹';

  @override
  String get fileBrowserShowDetails => '显示大小和日期';

  @override
  String get fileBrowserOptionsHelp =>
      '优先打开已选择的文件夹或已选图片的原始文件夹。每项操作分别记住上次打开的文件夹，取消后也会保留。如果文件夹不可用，则打开电视存储空间或下载文件夹。文件夹历史记录仅保存在此电视上。';

  @override
  String get fileBrowserSaveFailed => '无法保存文件浏览器设置。';

  @override
  String get settingsSectionStyle => '分组外观';

  @override
  String get settingsSectionAccentBand => '强调色条';

  @override
  String get settingsSectionSurface => '共用背景';

  @override
  String get panelTextAndButtonsGroup => '文字和按钮';

  @override
  String get settingsGroupScene => '场景';

  @override
  String get settingsGroupSky => '天空与天气';

  @override
  String get settingsGroupAnimation => '动画与预览';

  @override
  String get settingsGroupSource => '来源';

  @override
  String get settingsGroupImageChange => '图片切换';

  @override
  String get settingsGroupBrightness => '亮度级别';

  @override
  String get settingsGroupDisplay => '显示';

  @override
  String get settingsGroupCredentials => '连接信息';

  @override
  String get settingsGroupClient => '客户端参数';

  @override
  String get settingsGroupAccount => '账号连接';

  @override
  String get settingsGroupIndicators => '指示与消息';

  @override
  String get nightModePanelFill => '为月亮图标使用强调色';

  @override
  String get settingsGroupFocusShape => '焦点外观';

  @override
  String get settingsGroupBorder => '边框';

  @override
  String get settingsGroupMotion => '动态';

  @override
  String get settingsGroupControl => '控制';

  @override
  String get settingsGroupPositionSize => '位置与大小';

  @override
  String get settingsGroupGroupsBackground => '分组与背景';

  @override
  String get settingsGroupText => '文字';

  @override
  String get settingsGroupLayout => '布局';

  @override
  String get settingsGroupHeadings => '标题';

  @override
  String get settingsGroupLaunchTarget => '启动内容';

  @override
  String get settingsGroupLaunchTiming => '启动时机';

  @override
  String get settingsGroupBlockPosition => '信息块位置';

  @override
  String get settingsGroupBlockContent => '信息块内容';

  @override
  String get settingsGroupLayers => '显示层级';

  @override
  String get settingsGroupAccess => '访问权限';

  @override
  String get settingsGroupContent => '内容';

  @override
  String get settingsGroupSourcesLimits => '来源与限制';

  @override
  String get settingsGroupCards => '卡片';

  @override
  String get settingsGroupStorage => '存储';

  @override
  String get settingsGroupMode => '模式';

  @override
  String get settingsGroupExceptions => '例外';

  @override
  String get settingsGroupCurrentAction => '当前操作';

  @override
  String get settingsGroupHours => '运行时间';

  @override
  String get settingsGroupSourceAccess => '来源与访问';

  @override
  String get settingsGroupUpdate => '更新';

  @override
  String get settingsGroupSystemCommands => '系统与命令';

  @override
  String get weatherTemplateWarning => '预警';

  @override
  String get weatherTemplateDescription => '不含图标的描述';

  @override
  String get weatherTemplateIcon => '图标';

  @override
  String get weatherTemplateBracesError => '请检查成对的大括号。如需显示普通括号，请输入两次。';

  @override
  String get weatherTemplateUnknownError => '未知代码：';

  @override
  String get weatherTemplateBreakError => '只允许一个换行。';

  @override
  String get weatherTemplateValueError => '请至少添加一个天气代码。';

  @override
  String get weatherTemplateLengthError => '格式过长：最多2048个字符和64个元素。';

  @override
  String get sectionTitleSize => '分区标题大小';

  @override
  String get backupSyncResume => '恢复同步';

  @override
  String get backupSyncUseLocal => '使用此电视的设置';

  @override
  String get backupSyncUseRemote => '使用存储中的设置';

  @override
  String get backupSyncMergeLocal => '合并并优先采用此电视的设置';

  @override
  String get backupSyncMergeRemote => '合并并优先采用存储中的设置';

  @override
  String backupSyncPreviousDate(String date) {
    return '此电视上次同步：$date';
  }

  @override
  String backupSyncRemoteDate(String date) {
    return '存储中的副本：$date';
  }

  @override
  String get appPermissionsTitle => '应用权限';

  @override
  String get appPermissionsGrant => '授予权限并启用';

  @override
  String get appPermissionsRestore => '禁用后自动恢复';

  @override
  String get appPermissionsReconnect => '重新连接服务';

  @override
  String get appPermissionsDisable => '关闭服务和恢复';

  @override
  String get appPermissionsAutoStart => '自动启动';

  @override
  String get appPermissionsBackground => '后台活动';

  @override
  String get appPermissionsPending => '在此授予访问权限后开始恢复。';

  @override
  String get appPermissionsRetry => '等待恢复。请检查 ADB；系统将自动重试。';

  @override
  String get appPermissionsIdentity => '应用签名已更改，请重新授权。';

  @override
  String get appPermissionsEmpty => '没有其他带无障碍服务的应用。';

  @override
  String get appPermissionsError => '操作未完成。请检查 ADB 并刷新状态。部分更改可能已生效。';

  @override
  String get appPermissionsConfirm =>
      '允许无障碍、自动启动和后台活动，然后启用服务？仅执行固件支持的操作。无障碍服务可以读取界面事件并代表您执行操作。';

  @override
  String get appPermissionsHelp =>
      '在此授权的服务默认开启恢复。它会恢复权限并启用服务，包括在 Android 设置中被关闭的情况。关闭恢复会保留当前访问权限。关闭服务也会停止恢复，但保留自动启动和后台权限。重新连接仅重启此服务，不能修复应用错误。需要 ADB，Android 可能推迟检查。自动启动不会打开应用界面。状态来自最近一次检查，不会授予不支持的操作。';

  @override
  String get weatherFieldUnsupported => '此来源不支持该参数';

  @override
  String get weatherFieldMissing => '当前响应中没有数据';

  @override
  String get weatherMissingAsDash => '用破折号表示缺失数据';

  @override
  String get weatherPanelAlignment => '顶部面板天气行对齐';

  @override
  String get syncProtection => '令牌与保护';

  @override
  String get syncKey => '共享同步密钥';

  @override
  String get syncKeyShow => '显示密钥';

  @override
  String get syncKeyCreate => '创建密钥';

  @override
  String get syncKeyInvalid => '请输入64位十六进制密钥。';

  @override
  String get syncKeyHelp =>
      '同步令牌和账户时，所有电视须使用相同密钥。在一台电视上创建后传到其他电视。请妥善保存：没有密钥就无法读取受保护的数据。更换时请更新所有电视。Android权限和硬件密钥保留在本机。';

  @override
  String get syncFiles => '同步文件';

  @override
  String get syncCleanup => '清理旧文件';

  @override
  String get syncCleanupFailed => '部分旧文件未能删除。请重试清理。';

  @override
  String get syncRetire => '排除设备';

  @override
  String get syncRetireConfirm => '将此设备从组中排除？其旧状态将不再应用。重新加入需要新的同步组。';

  @override
  String get backupAccount => '账号';

  @override
  String get backupNewAccount => '连接其他账号';

  @override
  String get backupSetupWizard => '设置向导';

  @override
  String get backupSetupSummary => '摘要';

  @override
  String get backupSetupNext => '下一步';

  @override
  String get backupSetupBack => '返回';

  @override
  String get backupFirstCopy => '立即创建首次备份';

  @override
  String get backupSyncAll => '同步全部';

  @override
  String get backupFirstExchange => '首次交换';

  @override
  String get backupNoRemote => '存储中没有设置。此电视将上传自己的设置。';

  @override
  String get backupSetupStart => '启用';

  @override
  String get backupPassword => '数据加密密码';

  @override
  String get backupPasswordRepeat => '再次输入密码';

  @override
  String get backupPasswordMismatch => '密码不一致';

  @override
  String get backupAccountLocalHelp =>
      '使用已连接的账号或同类型的其他账号。存储凭据保留在此电视上。备份与同步分别管理各自的文件。';

  @override
  String get backupPasswordOptionalHelp =>
      '可选。加密整个文件，包括可转移的令牌。不设密码则不加密。留空可关闭加密。其他电视需使用相同密码读取加密文件。';

  @override
  String get backupYandexDisk => 'Yandex Disk';

  @override
  String get backupYandexHelp =>
      '输入可访问 Disk 应用文件夹的 Yandex OAuth 应用的 Client ID 和 Client Secret。连接后在手机上确认代码。所有电视使用同一个 OAuth 客户端和账号才能共享备份。';

  @override
  String get backupYandexConnect => '连接 Yandex 云端硬盘';

  @override
  String get backupYandexReconnect => '重新连接Yandex Disk';

  @override
  String get backupYandexConnectionStatus => 'Yandex Disk连接状态';

  @override
  String get yandexCodeExpired => 'Yandex Disk 登录超时。选择连接 Yandex 云端硬盘以获取新代码。';

  @override
  String get yandexConfigurationError => '客户ID / 客户秘密 — Yandex OAuth';

  @override
  String get backupSmb => 'Samba / SMB 2–3';

  @override
  String get smbUrl => '文件夹SMB地址';

  @override
  String get smbPassword => '密码';

  @override
  String get smbHelp =>
      '输入现有网络文件夹：smb://server/share/CuteLauncher。输入有权访问该文件夹的用户名和密码；域账号使用 DOMAIN\\user。自动协商 SMB 2 或 3。备份和同步需要读取、写入和删除权限。';

  @override
  String get recentRamTitle => '运行内存';

  @override
  String recentRamUsed(String used, String total, String percent) {
    return '已用 $used / $total · $percent%';
  }

  @override
  String recentRamAvailable(String value) {
    return '可用 $value';
  }

  @override
  String get recentRamUnloaded => '已移出内存';

  @override
  String get recentRamUnavailable => '无数据';

  @override
  String recentRamMiB(String value) {
    return '$value MiB';
  }

  @override
  String recentRamGiB(String value) {
    return '$value GiB';
  }

  @override
  String recentRamApp(String value) {
    return '≈ $value';
  }

  @override
  String get backupExistingSettingsHelp =>
      '所选存储空间中已有同步设置。请选择如何处理：应用到此电视、用此电视的设置替换，或合并。合并时若设置不同，将采用您选择的优先级。在向导的最后一步确认后才会开始交换。';
}
