// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

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
  String get adbWifiOwnedTitle => 'Wi-Fi はセットアップウィザードに属しています';

  @override
  String get adbWifiOwned =>
      '変更は行われていません。保存済みの Wi-Fi ネットワークは Google セットアップウィザードが作成しました。無効にするとネットワークが削除され、テレビが切断される場合があります。\n\n1. Wi-Fi パスワードを確認してください。\n2. Android のネットワーク設定で対象のネットワークを選び、「削除」を選択してください。\n3. 通常の Android ネットワーク設定から再接続してください。\n4. CuteLauncher に戻り、ADB を確認して内蔵ランチャーの無効化を再試行してください。\n\n再び表示される場合は内蔵ランチャーを有効のままにしてください。ファームウェアが再びウィザードをネットワーク所有者にする場合があります。';

  @override
  String get adbWifiUnknown =>
      'Not changed: the owners of saved Wi-Fi networks could not be verified. Disabling the setup wizard is blocked to protect your connection. Check ADB and try again; some firmware does not provide this information.';

  @override
  String get backgroundSource => 'バックグラウンドソース';

  @override
  String get noAvailableCategories => 'このアプリを追加できるセクションはありません。';

  @override
  String get redditWallpaperTheme => '壁紙のテーマ';

  @override
  String get redditThemeAll => '混合';

  @override
  String get redditThemeNature => '自然';

  @override
  String get redditThemeSpace => '宇宙';

  @override
  String get redditThemeCity => '都市';

  @override
  String get redditThemeMinimal => 'ミニマリズム';

  @override
  String get redditWallpaperResolution => '最小解像度';

  @override
  String get redditWallpaperHint =>
      '更新が成功するたびに、選択した Reddit コミュニティから異なる風景画像がダウンロードされます。解像度は元の最小サイズです。画像はアップスケールされません。ランチャーが開いている間は更新が実行され、戻ったときに再開されます。アダルト コンテンツ、ビデオ、ギャラリーはスキップされます。 Reddit がアクセスをブロックする場合、または一致する画像が見つからない場合は、以前の壁紙が残ります。';

  @override
  String get dialogCommandDetails => 'ADB コマンドを表示する';

  @override
  String get dialogAssign => '割り当てる';

  @override
  String get dialogApply => '申し込む';

  @override
  String get settingsValueNotSet => '未設定';

  @override
  String get settingsMenuPosition => '設定メニューの位置';

  @override
  String get settingsMenuLeft => '左';

  @override
  String get settingsMenuRight => '右';

  @override
  String get actionCompleted => 'アクションが完了しました';

  @override
  String get showRepositoryQrCode => 'QRコードを表示';

  @override
  String get resetSections => 'セクション設定をリセット';

  @override
  String get resetSectionsConfirmation =>
      'デフォルトのセクションを復元しますか?カスタム セクション、スペーサー、お気に入りのコンテンツは削除されます。';

  @override
  String get cardFocusMode => '帰国に集中';

  @override
  String get cardFocusRemember => '選択したカードを保持する';

  @override
  String get cardFocusFirst => '最初のカード';

  @override
  String get cardFocusSettings => '設定ボタン';

  @override
  String get aboutFlauncher => 'CuteLauncherについて';

  @override
  String get addCategory => 'カテゴリを追加';

  @override
  String get addSection => 'セクションを追加';

  @override
  String get alphabetical => 'アルファベット順';

  @override
  String get appCardHighlightAnimation => 'アプリカードのハイライトアニメーション';

  @override
  String get appInfo => 'アプリ情報';

  @override
  String get appKeyClick => 'キー押下時のクリック音';

  @override
  String get applications => 'アプリケーション';

  @override
  String get autoHideAppBar => 'ステータスバーを自動非表示';

  @override
  String get backButtonAction => '戻るボタンの動作';

  @override
  String get category => 'カテゴリ';

  @override
  String get categories => 'カテゴリ';

  @override
  String get columnCount => '列数';

  @override
  String get date => '日付';

  @override
  String get dateAndTimeFormat => '日付と時刻の形式';

  @override
  String get delete => '削除';

  @override
  String get dialogOptionBackButtonActionDoNothing => '何もしない';

  @override
  String get dialogOptionBackButtonActionShowScreensaver => 'スクリーンセーバーを表示';

  @override
  String get dialogOptionBackButtonActionShowClock => '時計を表示';

  @override
  String get dialogTextNoFileExplorer => '画像を選択するにはファイルエクスプローラーをインストールしてください。';

  @override
  String get dialogTitleBackButtonAction => '戻るボタンの動作を選択';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (カテゴリ)';
  }

  @override
  String formattedDate(String dateString) {
    return '書式化された日付: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return '書式化された時刻: $timeString';
  }

  @override
  String get gradient => 'グラデーション';

  @override
  String get favoriteApps => 'お気に入りアプリ';

  @override
  String get grid => 'グリッド';

  @override
  String get height => '高さ';

  @override
  String get hide => '非表示';

  @override
  String get hiddenApplications => '非表示のアプリ';

  @override
  String get launcherSections => 'セクション';

  @override
  String get layout => 'レイアウト';

  @override
  String get loading => '読み込み中';

  @override
  String get manual => '手動';

  @override
  String get modifySection => 'セクションを変更';

  @override
  String get mustNotBeEmpty => '空にすることはできません';

  @override
  String get name => '名前';

  @override
  String get newSection => '新しいセクション';

  @override
  String get noDateFormatSpecified => '日付形式が指定されていません';

  @override
  String get noTimeFormatSpecified => '時刻形式が指定されていません';

  @override
  String get nonTvApplications => '非TVアプリ';

  @override
  String get open => '開く';

  @override
  String get orSelectFormatSpecifiers => 'または形式指定子を選択';

  @override
  String get openImage => 'ファイルを選択';

  @override
  String get picture => 'ローカルの画像または動画';

  @override
  String removeFrom(String name) {
    return '$nameから削除';
  }

  @override
  String get renameCategory => 'カテゴリ名を変更';

  @override
  String get reorder => '並べ替え';

  @override
  String get row => '行';

  @override
  String get rowHeight => '行の高さ';

  @override
  String get save => '保存';

  @override
  String get spacer => 'スペーサー';

  @override
  String get spacerMaxHeightRequirement => '0より大きく500以下である必要があります';

  @override
  String get statusBar => 'ステータスバー';

  @override
  String get settings => '設定';

  @override
  String get show => '表示';

  @override
  String get showCategoryTitles => 'カテゴリタイトルを表示';

  @override
  String get themes => 'テーマ';

  @override
  String get hideHighlightOutlineOnHomescreen => 'ホーム画面でハイライトのアウトラインを非表示';

  @override
  String get appSelectorTransitionAnimation => 'アプリセレクターの遷移アニメーション';

  @override
  String get sort => '並べ替え';

  @override
  String get systemSettings => 'システム設定';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => 'このカテゴリは空です。';

  @override
  String get time => '時刻';

  @override
  String get titleStatusBarSettingsPage => 'ステータスバーに表示するものを選択';

  @override
  String get tvApplications => 'TVアプリ';

  @override
  String get type => '種類';

  @override
  String get typeInTheDateFormat => '日付形式を入力';

  @override
  String get typeInTheHourFormat => '時刻形式を入力';

  @override
  String get uninstall => 'アンインストール';

  @override
  String get wallpaper => '壁紙';

  @override
  String get withEllipsisAddTo => '追加...';

  @override
  String get timeBasedWallpaper => '昼間・夜間の画像';

  @override
  String get pickDayWallpaper => '昼間の画像を選択';

  @override
  String get pickNightWallpaper => '夜間の画像を選択';

  @override
  String get accessibility => 'アクセシビリティ';

  @override
  String get defaultLauncherIsDefault => 'CuteLauncherはデフォルトのランチャーです';

  @override
  String get defaultLauncherNotDefault => 'CuteLauncherはデフォルトのランチャーではありません';

  @override
  String get setAsDefaultLauncher => 'デフォルトのランチャーに設定';

  @override
  String get defaultLauncherDescription =>
      'デフォルトのランチャーに設定すると、ホームボタンは常にCuteLauncherに戻ります。TVの起動時も直接CuteLauncherが起動します。';

  @override
  String get inputs => '入力';

  @override
  String get inputsUnavailableHint =>
      'このデバイスには利用可能な入力がありません。スイッチは無効になり、アイコンは非表示になります。 TV ボックスでは、このオプションは接続された TV の HDMI 入力を制御しません。';

  @override
  String get inputSources => '入力ソース';

  @override
  String get backupAndRestore => 'バックアップと復元';

  @override
  String get exportBackup => 'バックアップをエクスポート';

  @override
  String get importBackup => 'バックアップをインポート';

  @override
  String exportSuccess(String path) {
    return 'バックアップが$pathに正常にエクスポートされました';
  }

  @override
  String get importSuccess => 'バックアップが正常にインポートされました';

  @override
  String get importConfirm => 'バックアップをインポートしますか？現在の設定とレイアウトが上書きされます。';

  @override
  String get importError => 'バックアップから設定を復元できませんでした。ファイルを確認して、再試行してください。';

  @override
  String exportError(String error) {
    return 'バックアップのエクスポートに失敗しました: $error';
  }

  @override
  String get shareBackup => 'バックアップを共有';

  @override
  String get shareBackupDescription => 'ローカルネットワーク上の他のデバイスとバックアップを共有';

  @override
  String get stopSharing => '共有を停止';

  @override
  String get localNetworkSharingActive => 'ローカルネットワーク共有が有効です！';

  @override
  String get localNetworkSharingInstructions =>
      '他のデバイスを同じWi-Fiネットワークに接続し、Webブラウザで次のURLを開きます：';

  @override
  String get localNetworkSharingDetails =>
      'ここでTVの設定/レイアウトをダウンロードするか、バックアップファイルをこのTVにアップロードできます。';

  @override
  String failedToStartServer(String error) {
    return '共有サーバーの起動に失敗しました: $error';
  }

  @override
  String get notificationBell => '通知ベル';

  @override
  String get autoHideNotificationBell => '通知ベルを自動非表示';

  @override
  String get continueWatching => '続きを見る';

  @override
  String get showContinueWatchingOnHome => 'ホームに「続きを見る」を表示';

  @override
  String get permissionDeniedContinueWatching => '「続きを見る」を表示するには権限が必要です';

  @override
  String get interface => 'インターフェース';

  @override
  String get system => 'システム';

  @override
  String get accentColor => 'アクセントカラー';

  @override
  String get miscellaneous => 'その他';

  @override
  String get brightnessScheduler => '明るさスケジューラー';

  @override
  String get screensaverSettings => 'スクリーンセーバー設定';

  @override
  String get screensaverClockStyle => 'スクリーンセーバー時計スタイル';

  @override
  String get dataUsagePeriod => 'データ使用期間';

  @override
  String get notificationAccess => '通知アクセス';

  @override
  String get granted => '許可済み';

  @override
  String get permissionRequired => '権限が必要です';

  @override
  String get systemWidePopupAlert => 'システム全体のポップアップアラート';

  @override
  String get overlayPermissionRequired => 'オーバーレイ権限が必要です';

  @override
  String get enabled => '有効';

  @override
  String get disabled => '無効';

  @override
  String get showAppNamesBelowIcons => 'アイコンの下にアプリ名を表示';

  @override
  String get dataUsage => 'データ使用量';

  @override
  String get networkIndicator => 'ネットワークインジケーター';

  @override
  String get homeButtonFix => 'ホームボタン修正 (Google TV)';

  @override
  String get startOnBoot => '起動時に開始 (Google TV / Fire TV)';

  @override
  String get appLanguage => '言語';

  @override
  String get systemDefault => 'システムのデフォルト';

  @override
  String get english => '英語';

  @override
  String get spanish => 'スペイン語';

  @override
  String get ukrainian => 'ウクライナ語';

  @override
  String get chinese => '中国語';

  @override
  String get french => 'フランス語';

  @override
  String get german => 'ドイツ語';

  @override
  String get japanese => '日本語';

  @override
  String get portuguese => 'ポルトガル語';

  @override
  String get russian => 'ロシア語';

  @override
  String get italian => 'イタリア語';

  @override
  String get hindi => 'ヒンディー語';

  @override
  String get korean => '韓国語';

  @override
  String get arabic => 'アラビア語';

  @override
  String get turkish => 'トルコ語';

  @override
  String get hidePersistentNotifications => '常駐通知を非表示';

  @override
  String get hidePersistentNotificationsDesc => 'バックグラウンドサービスやシステムの常駐通知を非表示';

  @override
  String get blockedNotificationApps => 'ブロックされたアプリ';

  @override
  String get blockAppNotifications => '通知をブロック';

  @override
  String get unblockAppNotifications => '通知のブロックを解除';

  @override
  String get noBlockedApps => 'ブロックされたアプリはありません';

  @override
  String get persistentNotification => '常駐';

  @override
  String get unblockAll => 'すべてブロック解除';

  @override
  String get weather => '天気';

  @override
  String get showWeatherWarnings => '天気と雨の警告を表示';

  @override
  String get temperatureUnit => '温度単位';

  @override
  String get celsius => '摂氏 (°C)';

  @override
  String get fahrenheit => '華氏 (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Breezy Weather をインストールし、設定で「ローカルデータ共有」/「Gadgetbridge」を有効にすると、天気と雨の警告が表示されます。';

  @override
  String get displayAndScreensaver => 'ディスプレイとスクリーンセーバー';

  @override
  String get notifications => '通知';

  @override
  String get continueWatchingDescription => 'ホーム画面に最近再生した映画や番組を表示します';

  @override
  String get continueWatchingPermissionDesc => 'TVアプリの視聴履歴を読み取るには特別な権限が必要です:';

  @override
  String get requestPermission => '権限をリクエスト';

  @override
  String get dismiss => '非表示';

  @override
  String get openApp => '開く';

  @override
  String get notificationOptions => '通知のオプション';

  @override
  String get noBlockedAppsDesc => '現在、すべてのアプリで通知の表示が許可されています';

  @override
  String get notificationsAllowed => '通知を許可';

  @override
  String get notificationsBlocked => '通知をブロック';

  @override
  String get dpadDismissHint => '左: 非表示 • OK: オプション';

  @override
  String get watchNextDeleteError => '「継続視聴」からアイテムを削除できませんでした。もう一度やり直してください。';

  @override
  String get hideLauncherTile => 'アプリグリッドで CuteLauncher を非表示にする';

  @override
  String get hideAndroidSettingsTile => 'アプリタイルでAndroid設定を非表示にする';

  @override
  String get animateTileReordering => 'タイルの並べ替えをアニメーション化する';

  @override
  String get imageInputRejected =>
      'この画像は破損しているか、大きすぎます (最大 8 MiB および 48 メガピクセル)。別の画像を選択してください。';

  @override
  String get memoryTitle => '記憶';

  @override
  String get memoryRefresh => 'メモリを測定する';

  @override
  String get memoryMeasuring => '測定中…';

  @override
  String get memoryClear => '画像キャッシュをクリアする';

  @override
  String get memorySaver => 'メモリの節約';

  @override
  String get memorySaverDescription =>
      'メモリ節約モード:\n\n• 画像キャッシュとポスターのプリロード ウィンドウを削減します。\n• タイル、パネル、壁紙の背景のぼかしと輪郭のパルスを無効にします。\n• 焦点の合っていないタイル上の影を制限します。\n• アプリがバックグラウンドに移行するときにキャッシュをクリアします。\n\nメモリ節約が有効になっている間は、これらの効果は設定で使用できません。モードが無効になると、保存された値が返されます。画像はより頻繁にリロードされる場合があります。';

  @override
  String get memoryPss => 'プロセス共有 (PSS)';

  @override
  String get memoryRss => '常駐プロセスメモリ (RSS)';

  @override
  String get memoryEncodedCache => 'キャッシュされた画像ファイル';

  @override
  String get memoryDecodedCache => 'キャッシュされたデコードされた画像';

  @override
  String get memoryUnavailable => '利用不可';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => '測定場所';

  @override
  String get memoryExplanation =>
      'PSS と RSS は重複しています。これらを一緒に加算しないでください。キャッシュ サイズはアプリ メモリの一部であり、アクティブなイメージが保持するすべてのメモリを表すものではありません。キャッシュをクリアすると、設定とファイルが保持されます。必要に応じて画像を再度読み込みます。 Android は後でメモリを返す可能性があります。ここでの RSS はカーネルからのものであり、PSS は Android からのものです。グラフィックス メモリの考慮方法が異なる場合があります。';

  @override
  String get memoryRecommendations =>
      'メモリを少なくするには、保存を有効にし、表示する「継続視聴」カードの数を減らし、小さい壁紙またはグラデーションを使用します。';

  @override
  String get memoryMeasurementFailed => 'プロセス測定はできません。キャッシュ情報は引き続き表示されます。';

  @override
  String get addToCategory => 'カテゴリに追加';

  @override
  String get addToFavorites => 'お気に入りに追加';

  @override
  String get removeFromFavorites => 'お気に入りから削除';

  @override
  String get setCustomBanner => 'カスタムバナーの設定';

  @override
  String get clearCustomBanner => 'カスタムバナーをクリア';

  @override
  String get bannerSetFailed => 'バナーを設定できませんでした。画像へのアクセスを確認し、ファイルを再度選択してください。';

  @override
  String get bannerClearFailed => 'カスタム バナーを削除できませんでした。もう一度やり直してください。';

  @override
  String get grantUsagePermission => '使用許可を与える';

  @override
  String get removeFromContinueWatching => '継続視聴から削除';

  @override
  String hideAllFromApp(String appName) {
    return '$appName からすべてを非表示にする';
  }

  @override
  String get playResume => '再生/再開';

  @override
  String openNamedApp(String appName) {
    return '$appNameを開く';
  }

  @override
  String get selectedAccent => '選択されたアクセント';

  @override
  String get homeButtonFixHint =>
      'Google TV を使用している場合は、アクセシビリティ設定で「ホーム ボタンの修正」を有効にして、ホーム ボタンでこのランチャーを開くようにします。';

  @override
  String get accessibilityPermission => 'アクセシビリティ許可';

  @override
  String get shareFailed => '共有に失敗しました';

  @override
  String shareBackupError(String error) {
    return 'バックアップの共有に失敗しました: $error';
  }

  @override
  String get exportComplete => 'エクスポートの成功';

  @override
  String get exportFailed => 'バックアップを保存できませんでした。フォルダーへのアクセスと利用可能なストレージを確認します。';

  @override
  String backupLoadError(String error) {
    return 'バックアップのロード中にエラーが発生しました: $error';
  }

  @override
  String get noBackupFiles => 'バックアップ ファイルが見つかりません。';

  @override
  String get importComplete => 'インポート成功';

  @override
  String get importFailed => 'インポートに失敗しました';

  @override
  String get importAction => 'インポート';

  @override
  String get continueWatchingApps => 'アプリの視聴を続ける';

  @override
  String get blockedContinueWatching => '継続視聴がブロックされています';

  @override
  String get allAppsCanContinueWatching =>
      'サポートされているすべてのアプリは、「継続視聴」でアイテムを表示できます。';

  @override
  String get unblockApp => 'ブロックを解除する';

  @override
  String get unblockAllApps => 'すべてのアプリのブロックを解除する';

  @override
  String get appsWithContinueWatching => '継続視聴機能のあるアプリ';

  @override
  String get watchNextAppsHint => '現在、ホーム画面に Watch Next アイテムを提供しているアプリ';

  @override
  String get noWatchNextApps =>
      '現在、継続視聴アイテムを提供するアプリはありません。\nサポートされているアプリ (SmartTube やストリーミング サービスなど) が項目を追加すると、ここに表示されます。';

  @override
  String get allInstalledApps => 'インストールされているすべてのアプリ';

  @override
  String get blockWatchNextHint => 'オフに切り替えると、アプリが「継続視聴」項目を追加するのをブロックします。';

  @override
  String get cardSize => 'カードサイズ';

  @override
  String get maximumItems => '最大アイテム数';

  @override
  String get playbackProgressBar => '再生プログレスバー';

  @override
  String get playbackPercentage => '再生パーセンテージ';

  @override
  String get episodeVideoDetails => 'エピソードとビデオの詳細';

  @override
  String get restoreHiddenPrograms => '隠しプログラムを復元する';

  @override
  String get allHiddenProgramsRestored => 'すべての隠しプログラムが復元されました';

  @override
  String get watchNextAccessAdb => '次のアクセスを視聴 (ADB が必要)';

  @override
  String get supportLtvLauncher => 'サポートLTvLauncher';

  @override
  String get scanToDonate => '寄付するには携帯電話のカメラでスキャンしてください:';

  @override
  String get openInBrowser => 'ブラウザで開く';

  @override
  String get close => '閉じる';

  @override
  String get launcherAuthor => 'CuteLauncher by Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Android TV ランチャーは、LeanBitLab による LTvLauncher および Étienne Fesser による FLauncher に基づいています。 GNU GPLv3 に基づいてライセンスされています。';

  @override
  String get projectCredits => 'プロジェクトとクレジット';

  @override
  String get launcherRepository => 'CuteLauncher リポジトリ';

  @override
  String get originalProject => '元のプロジェクト: LTvLauncher';

  @override
  String get noInputsDetected => '入力が検出されませんでした';

  @override
  String get reorderSectionsHint =>
      '◄ / ► で選択し、▲ / ▼ を使用して並べ替えます。リストの境界を越えてセクションを非表示または表示します。';

  @override
  String get customName => 'カスタム名';

  @override
  String get mostUsed => '起動頻度';

  @override
  String get lastUsed => '最後に使用したもの';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String get allCaughtUp => '全員追いついた！';

  @override
  String get notificationAccessAdb => '通知アクセス (ADB が必要)';

  @override
  String get openAppInfo => 'アプリ情報を開く';

  @override
  String get overlayPermission => 'オーバーレイ許可';

  @override
  String get clockMinimal => '最小限';

  @override
  String get clockMinimalDescription => '細くエレガントなフォント (デフォルト)';

  @override
  String get clockBold => '太字';

  @override
  String get clockBoldDescription => '太くて視認性の高いフォント';

  @override
  String get clockRetro => 'レトロ';

  @override
  String get clockRetroDescription => '等幅のレトロなターミナル スタイル';

  @override
  String get clockElegant => 'エレガント';

  @override
  String get clockElegantDescription => 'クラシックなセリフ書体';

  @override
  String get clockNeon => 'ネオン';

  @override
  String get clockNeonDescription => '極薄で輝くスタイル';

  @override
  String get clockPixel => 'ピクセル';

  @override
  String get clockPixelDescription => '大胆な等幅、アーケードの雰囲気';

  @override
  String get clockDigital => 'デジタル';

  @override
  String get clockDigitalDescription => 'すっきりとした等幅ディスプレイ';

  @override
  String get themeDefault => 'デフォルト';

  @override
  String get themePremium => 'プレミアム';

  @override
  String get themeClassic => 'クラシック';

  @override
  String get themeCapsule => 'カプセル';

  @override
  String get cancel => 'キャンセル';

  @override
  String get actionCancelled => 'アクションがキャンセルされました';

  @override
  String get ok => 'OK';

  @override
  String get accessibilityGuide =>
      'テレビの設定を手動で開き、「アクセシビリティ」→「CuteLauncher ホームボタンの修正」の順に選択し、サービスを有効にします。このメニューの場所と名前は、テレビのメーカーによって異なります。';

  @override
  String get notificationPermissionGuide =>
      'このテレビでは通知アクセス設定を開けませんでした。アプリ情報で送信通知を許可しても、他のアプリからの通知へのアクセスは許可されません。\n\nADB 経由でテレビを接続し、次を実行します。';

  @override
  String get overlayPermissionGuide =>
      'オーバーレイ許可設定を自動的に開くことができませんでした。\n\n他のアプリ上でポップアップを有効にするには、ADB 経由でテレビに接続し、次のコマンドを実行します。';

  @override
  String get watchNextPermissionGuide =>
      '他のアプリから「継続視聴」カードを読み取るには、Android TV には READ_WRITE_WATCH_NEXT_PROGRAMS が必要です。\n\nADB 経由でテレビを接続し、次を実行します。';

  @override
  String get watchNextAccess => 'アクセスを続ける';

  @override
  String itemsCount(int count) {
    return '$count アイテム';
  }

  @override
  String displayUpToItems(int count) {
    return '最大 $count の最近のアイテムを表示します';
  }

  @override
  String get unlimitedItems => '無制限';

  @override
  String get allAvailableItems => '利用可能なアイテムをすべて表示する';

  @override
  String get defaultOption => 'デフォルト';

  @override
  String get manage => '管理する';

  @override
  String blockedCount(int count) {
    return '$count がブロックされました';
  }

  @override
  String hiddenCount(int count) {
    return '$count 非表示';
  }

  @override
  String blockedWatchNextCount(int count) {
    return '継続視聴がブロックされました ($count)';
  }

  @override
  String get sizeExtraSmall => '特小';

  @override
  String get sizeVerySmall => '非常に小さい';

  @override
  String get sizeSmall => '小';

  @override
  String get sizeCompact => 'コンパクト';

  @override
  String get sizeMediumSmall => '中 小';

  @override
  String get sizeMedium => '中';

  @override
  String get sizeStandardDefault => '標準 (デフォルト)';

  @override
  String get sizeMediumLarge => '中大';

  @override
  String get sizeLarge => '大';

  @override
  String get sizeVeryLarge => '非常に大きい';

  @override
  String get sizeExtraLarge => '特大';

  @override
  String get sizeHuge => '巨大な';

  @override
  String get tvApps => 'テレビアプリ';

  @override
  String get nonTvApps => 'テレビ以外のアプリ';

  @override
  String get moviesShows => '映画と番組';

  @override
  String get music => '音楽';

  @override
  String get games => 'ゲーム';

  @override
  String get entertainment => 'エンターテイメント';

  @override
  String get liveTv => 'ライブテレビ';

  @override
  String get sports => 'スポーツ';

  @override
  String get news => 'ニュース';

  @override
  String get tools => 'ツール';

  @override
  String get favorites => 'お気に入り';

  @override
  String get customSectionName => 'カスタム...';

  @override
  String get selectSectionName => '名前を選択してください';

  @override
  String get weeklyUsage => '毎週:';

  @override
  String get monthlyUsage => '毎月:';

  @override
  String get dailyUsage => '毎日:';

  @override
  String get appError => '何か問題が発生しました';

  @override
  String get weatherRain => '雨';

  @override
  String get weatherSnow => '雪';

  @override
  String get weatherStorm => '嵐';

  @override
  String get weatherToday => '今日';

  @override
  String get weatherTomorrow => '明日';

  @override
  String weatherOnDay(String day) {
    return '$dayで';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'CuteLauncher バックアップ';

  @override
  String get noApplicationsFound => 'アプリケーションが見つかりませんでした';

  @override
  String get invalidDateFormat => '無効な形式';

  @override
  String get selectDateFormats => '以下の形式を選択してください';

  @override
  String activeItemsCount(int count) {
    return '$count アクティブなアイテム';
  }

  @override
  String get colorPurple => '紫';

  @override
  String get colorTeal => 'ティール';

  @override
  String get colorBlue => 'ブルー';

  @override
  String get colorOrange => 'オレンジ';

  @override
  String get colorPink => 'ピンク';

  @override
  String get colorGreen => '緑';

  @override
  String get colorWhite => 'ホワイト';

  @override
  String get colorYellow => '黄色';

  @override
  String get colorRed => '赤';

  @override
  String get colorCyan => 'シアン';

  @override
  String get colorIndigo => 'インディゴ';

  @override
  String get colorLime => 'ライム';

  @override
  String get colorAmber => 'アンバー';

  @override
  String get colorRose => 'ローズ';

  @override
  String get colorIceBlue => 'アイスブルー';

  @override
  String get memoryFeatures => '機能ごとのメモリ (キャッシュ)';

  @override
  String get memoryAppIcons => 'アプリアイコン';

  @override
  String get memoryAppBanners => 'アプリのバナー';

  @override
  String get memoryWatchNextPosters => 'ポスターを見続ける';

  @override
  String get memoryOtherCaches => 'その他のエンコードされた画像キャッシュ';

  @override
  String get memoryFeaturesExplanation =>
      'これらは保持された画像バイトであり、エンコードされたキャッシュの合計にすでに含まれています。 0 は、そのキャッシュにバイトが保持されていないことを意味します。機能がメモリを使用しないことを意味するわけではありません。壁紙と表示される画像は、上記のデコードされたキャッシュを共有します。アクティブなイメージはその外側にある可能性があります。ここでは、天気、通知、Dart オブジェクト、エンジンを機能ごとに分割することはできません。共有インターフェイス グラフィックスは上記の Android によって報告されており、すでに PSS に含まれています。彼らの記憶はプロセス全体の一部です。これらの重複する値を追加しないでください。';

  @override
  String get memoryGraphics => 'インターフェイスグラフィックス (PSS に含まれます)';

  @override
  String get categoryVisible => 'カテゴリを表示';

  @override
  String get hiddenCategories => '隠しカテゴリ';

  @override
  String get visibleCategories => '表示可能なカテゴリ';

  @override
  String get backupSavedToSelectedLocation => '選択した場所にバックアップが保存されました';

  @override
  String get tileHorizontalGap => '水平方向の間隔';

  @override
  String get tileVerticalGap => '垂直方向の間隔';

  @override
  String get tileOpacity => '背景の不透明度';

  @override
  String get tileShadow => 'シャドウ';

  @override
  String get tileCornerRadius => '角の丸み';

  @override
  String get tileIconScale => 'アイコンのサイズ';

  @override
  String get tileBackgroundColor => 'タイルの背景';

  @override
  String get tileLabelSize => 'ラベルサイズ';

  @override
  String get resetAppearance => '外観をリセットする';

  @override
  String get tileAppearance => 'タイルの外観';

  @override
  String get tileLabelColor => 'ラベルの色';

  @override
  String get tilePreviewName => 'サンプルアプリケーション';

  @override
  String get tileProportions => 'タイルの比率';

  @override
  String get tileLarge => '大';

  @override
  String get tileLabelBelow => 'タイルの下';

  @override
  String get tileLabelInside => 'タイルの内側';

  @override
  String get tileFocusScale => '拡大する';

  @override
  String get tileMedium => '中';

  @override
  String get tileFocusBorder => '動きなし';

  @override
  String get tileSize => 'タイルのサイズ';

  @override
  String get tileCompact => 'コンパクト';

  @override
  String get tileLabelPosition => 'ラベルの位置';

  @override
  String get tileFocusEffect => 'フォーカス効果';

  @override
  String get tileFocusStrength => 'ハイライトの強度';

  @override
  String get panelIndependent => 'カスタム設定';

  @override
  String get panelAppearance => 'トップパネルスタイル';

  @override
  String get panelBackground => 'パネルの背景';

  @override
  String get blurPerformanceHint =>
      'ぼかしを行うと滑らかさが低下する場合があります。メモリ保存がオンの場合は無効になります。';

  @override
  String get panelOpacity => 'パネルの不透明度';

  @override
  String get tileBlur => 'タイルの後ろをぼかします';

  @override
  String get panelBlur => 'トップパネルの後ろのぼかし';

  @override
  String get panelShared => 'パネルのようなもの';

  @override
  String get weatherMinutes => '分';

  @override
  String get weatherOpenMeteoCredit =>
      '天気: Open-Meteo (open-meteo.com)、CC BY 4.0。非営利目的の場合は無料の API。';

  @override
  String get weatherRateLimit => 'リクエストの制限に達しました。後で試してください。';

  @override
  String get weatherYandexCredit =>
      '天気: Yandex 天気 (yandex.ru/pogoda)。アクセスは、API プランによって異なります。';

  @override
  String get yandexWeather => 'ヤンデックス天気 (REST)';

  @override
  String get weatherAuthorizationError =>
      '気象プロバイダーはリクエストを拒否しました。 API キーを確認し、選択したサービスにアクセスします。';

  @override
  String get weatherYandexHint =>
      'REST 予測アクセスを持つキーが必要です。別の Yandex プランのキーは機能しない可能性があります。';

  @override
  String get weatherSource => '気象源';

  @override
  String get weatherInterval => '更新間隔';

  @override
  String get weatherLongitude => '経度 (-180 ～ 180)';

  @override
  String get weatherKeyRequired => 'Yandex API キーを追加します。';

  @override
  String get weatherLocationName => '都市名 (オプション)';

  @override
  String get weatherLocation => '場所';

  @override
  String get weatherApiKey => 'Yandex API キー';

  @override
  String get weatherInvalidResponse => '気象情報源が無効なデータを返しました。';

  @override
  String get weatherUnavailable =>
      '天気は利用できません。以前に受信したデータが利用可能な場合は保持されます。再試行は 5 分に 1 回に制限されています。';

  @override
  String get weatherStale => '以前の天気';

  @override
  String get weatherLatitude => '緯度 (-90 ～ 90)';

  @override
  String get weatherCoordinatesError => '都市を手動で入力するか、座標を自動的に取得します。';

  @override
  String get weatherRefresh => 'アップデートを確認する';

  @override
  String get weatherKeyPrivate =>
      'このデバイスにのみ保存され、バックアップから除外されます。入力を空にするとキーが削除されます。';

  @override
  String get weatherUpdated => '更新されました';

  @override
  String get onlineWallpaperError =>
      'この画像をロードできません。以前の壁紙は保持されます。 「アップデートを確認」を選択してダウンロードを再試行します。';

  @override
  String get onlineWallpaperHint => '最後に取得した画像はオフラインでも使えるよう保存されます（最大8 MiB）。';

  @override
  String get onlineWallpaperHours => 'h';

  @override
  String get onlineWallpaperInterval => 'ダウンロード間隔';

  @override
  String get onlineWallpaper => 'オンライン壁紙';

  @override
  String get onlineWallpaperUrlError =>
      'ログインの詳細を含まずに、直接 HTTPS イメージ URL を入力します。';

  @override
  String get onlineWallpaperEnabled => 'オンライン壁紙を使用する';

  @override
  String get onlineWallpaperSource => '画像ソース';

  @override
  String get bingWallpaper => 'Bing 今日の画像';

  @override
  String get onlineWallpaperUrlSource => 'ダイレクト HTTPS URL';

  @override
  String get updatePlayOnly => 'このインストールは、Google Play を通じて更新を受け取ります。';

  @override
  String get updateCheck => '今すぐチェック';

  @override
  String get updateInstalled => 'インストール済み';

  @override
  String get updateDownloadInstall => 'ダウンロードしてインストールする';

  @override
  String get updateNoRelease => '互換性のある新しいリリースはありません。';

  @override
  String get updateIncompatible =>
      'APK は、このアプリケーション、証明書、または新しいバージョンと一致しません。インストールがブロックされました。';

  @override
  String get updateError => 'インストーラーを確認、ダウンロード、または開くことができません。後でもう一度試してください。';

  @override
  String get updateAvailable => '利用可能なアップデート';

  @override
  String get appUpdates => 'アプリケーションのアップデート';

  @override
  String get updatePermission =>
      'Android 設定でこのアプリケーションからのインストールを許可し、ここに戻ってもう一度 [インストール] を押します。';

  @override
  String get updateInstall => 'ダウンロードしたアップデートをインストールする';

  @override
  String get updateHint =>
      '出典: GitHub / KirillShchetinnikov/CuteLauncher-リリース。ランチャーが開いている間、自動チェックが実行されます。選択するとダウンロードが開始されます。 Android はインストールの確認を求めます。あなたのデータは保管されます。';

  @override
  String get updateAutomatic => '1日1回自動チェック';

  @override
  String get allApplications => 'すべてのアプリケーション';

  @override
  String get adbAccessibility => 'ホームボタンの修正を有効にする';

  @override
  String get adbAuthorization => 'テレビで ADB 認証を承認してから、再試行してください。';

  @override
  String get adbChangeConfirm =>
      'ADB を通じてこのシステム設定を適用しますか?以前のホーム アプリは、変更する前に保存されます。他のアクセシビリティ サービスは維持されます。';

  @override
  String get adbCheck => '接続を確認してください';

  @override
  String get adbDenied => 'システムはこの変更を許可または確認しませんでした。';

  @override
  String get adbDisable => '以前のランチャーを無効にする';

  @override
  String get adbDisableConfirm =>
      '保存した以前のランチャーを無効にしますか?これには、CuteLauncher が現在のホーム アプリである必要があります。この設定の回復アクションで復元します。';

  @override
  String get adbHint =>
      'この TV 専用のプロトタイプ (127.0.0.1)。開発者向けオプションで TCP ADB を有効にし、そのポートを入力して、テレビ上の認証プロンプトを承認します。ペアリング コードを使用したワイヤレス デバッグはまだサポートされていません。秘密キーは、バックアップの外で、このデバイス上に残ります。';

  @override
  String get adbHome => 'CuteLauncher をホーム アプリにする';

  @override
  String get adbInvalid => '1024 ～ 65535 のポートを入力します。';

  @override
  String get adbNoRecovery => '復元は利用できません。他のランチャーまたは保存されたサービス状態が見つかりませんでした。';

  @override
  String get adbPort => 'TCP ADB ポート';

  @override
  String get adbReady => 'ADB アクセスを確認しました。';

  @override
  String get adbRestore => '以前のランチャーを復元する';

  @override
  String get adbSuccess => '変更が適用され、確認されました。';

  @override
  String get adbTitle => 'ADBセットアップ';

  @override
  String get adbUnavailable => '接続できません。 TCP ADB、ポート、および認証プロンプトを確認します。';

  @override
  String get nightModeScheduled => '利用スケジュール';

  @override
  String get nightModeTitle => 'ナイトモード';

  @override
  String get nightModeScope =>
      '他のアプリを暗くするにはオーバーレイ権限が必要です。これがないと、CuteLauncher 内で調光が機能します。 TCL フィルターにはオーバーレイ権限は必要ありません。不透明度が 80% を超えると、Android は他のアプリでのタッチ入力をブロックする可能性があります。テレビのリモコンキーは引き続き機能します。';

  @override
  String get nightModeEnd => '終了';

  @override
  String get nightModeStart => 'スタート';

  @override
  String get nightModeDim => '調光';

  @override
  String get nightModeWarmth => 'ウォームフィルター';

  @override
  String get nightModeScheduleHint =>
      '現地のテレビ時間を使用します。夜間期間もサポートされています。開始時刻と終了時刻が等しいと、スケジュールされたフィルターが無効になります。';

  @override
  String get nightModeEnabled => 'ナイトモードを有効にする';

  @override
  String get nightModePermission => '他のアプリの上に表示を許可する';

  @override
  String get nightModePermissionGranted => '他のアプリの上に重ねて表示可能';

  @override
  String get backupDownloadsFailed => 'バックアップをダウンロードに保存できませんでした。';

  @override
  String get backupSaveDownloads => 'バックアップをダウンロードに保存する';

  @override
  String get adbRestoreAccessibility => 'アクセシビリティアクセスを復元する';

  @override
  String get nightModeAdbConfirm =>
      'ローカルの ADB を使用して、CuteLauncher が他のアプリの上に表示されることを許可しますか?最初に TCP デバッグを有効にして、接続を承認します。 ADB ウィザードで保存したポート、または 5555 を使用します。';

  @override
  String get nightModeAdbPermission => 'ADB を通じて許可を付与します。';

  @override
  String get nightModeNotificationsHint =>
      'この通知により、CuteLauncher の外でフィルターをオフにすることができます。それがない場合は、このメニューを使用してください。';

  @override
  String get nightModeNotificationsAllowed => 'ナイトモード通知を許可する';

  @override
  String get nightModeNotifications => 'ナイトモード通知を許可する';

  @override
  String get categoryLastVisibleHint => '少なくとも 1 つのカテゴリが表示されたままでなければなりません。';

  @override
  String get diagnosticsClear => 'セッション診断をクリアする';

  @override
  String get diagnosticsReady => 'レポートの準備ができました';

  @override
  String get diagnosticsCreate => 'レポートの作成';

  @override
  String get diagnosticsOperations => '記録された操作';

  @override
  String get diagnosticsCopied => 'レポートをコピーしました';

  @override
  String get diagnosticsSharingNotice =>
      'ファイルは公開せず、作者に個別メッセージで送ってください。自動処理後も個人情報が残る場合があります。送信すると、匿名化されたテレビ互換性レポートを CuteLauncher の Git リポジトリで公開することに同意したものとします。公開するのは個人情報を含まない機器情報と機能の利用可否だけです。エラーログ、コマンド、個人の設定は公開しません。\n\nレポートにはインストール済みパッケージの名前、バージョン、有効状態と、セクションの名前、内容、順序、表示状態も含まれます。診断のため識別子と名前は保持されますが、これらの一覧は公開されません。';

  @override
  String get diagnosticsHint =>
      '1つのレポートにテレビ機能の互換性とエラー診断をまとめます。レポートにはテレビの機種とファームウェア、アプリのバージョン、権限、メモリ、エラーの段階と原因、個人情報を自動処理したコマンドと応答が含まれます。現在のセッションの直近 50 操作、別枠で最大 100 件の失敗、制限付き ADB ログを保持します。再起動で消去されます。個人情報が残る可能性があるため、公開せず個別メッセージで送信してください。自動送信はありません。各エラーにはその時点の適用設定を保存し、後の変更では置き換えません。\n\nレポートにはインストール済みパッケージの名前、バージョン、有効状態と、セクションの名前、内容、順序、表示状態も含まれます。診断のため識別子と名前は保持されますが、これらの一覧は公開されません。';

  @override
  String get diagnosticsTitle => 'エラー診断';

  @override
  String get diagnosticsCopyFailed => 'レポートをコピーできませんでした。';

  @override
  String get diagnosticsCopy => 'レポートのコピー';

  @override
  String get diagnosticsCreating => 'レポートを作成中…';

  @override
  String get tclBlueLightTitle => 'TCL ブルーライトフィルター';

  @override
  String get tclBlueLightError =>
      'TCL フィルター設定を読み取ることも検証することもできませんでした。状態を更新して再試行してください。';

  @override
  String get tclBlueLightUnsupported => 'TCL フィルター インターフェイスはこのテレビでは使用できません。';

  @override
  String get tclBlueLightRefresh => 'TCL フィルター状態を更新します';

  @override
  String get tclBlueLightHint =>
      'テレビの内蔵 Eye Health Protection フィルターを制御します。夜間モードのスケジュールに従うこともできます。';

  @override
  String get nightSolarSchedule => '日没と日の出';

  @override
  String get nightNextStart => '次のスタート';

  @override
  String get nightScheduleTimeHint =>
      '時間はテレビのタイムゾーンを使用します。負のオフセットは早くなります。正のオフセットは後で説明します。';

  @override
  String get nightTemperature => 'フィルターの色温度';

  @override
  String get nightScheduleSettings => 'スケジュール設定';

  @override
  String get nightCityName => '都市名';

  @override
  String get nightSkipUntilNext => '次の日没までナイトモードを無効にする';

  @override
  String get nightSunriseOffset => '日の出を基準にして終了';

  @override
  String get nightEnableUntilMorning => '次の日の出までナイトモードを有効にする';

  @override
  String get nightPermissions => '権限';

  @override
  String get nightTclSchedule => 'スケジュールに TCL フィルターを含める';

  @override
  String get nightSearchCity => '検索';

  @override
  String get nightRefreshSun => '日の出と日の入りをリフレッシュ';

  @override
  String get nightSolarUnavailable =>
      '都市を選択して、太陽の時間を更新してください。日の出または日の入りが利用できない場合、ソーラー スケジュールは一時停止します。';

  @override
  String get nightSunsetOffset => '日没を基準にして開始';

  @override
  String get nightCityHint =>
      '位置情報へのアクセスを許可する代わりに、都市を選択してください。選択した座標は、太陽時刻を取得するために、Sunrise-Sunset.org またはフォールバックとして Open-Meteo に送信されます。';

  @override
  String get nightResumeSchedule => 'スケジュールに戻る';

  @override
  String get nightScheduleSource => 'スケジュールの種類';

  @override
  String get nightSolarCached => 'キャッシュされた太陽時刻を使用します。インターネット更新は自動的に再試行されます。';

  @override
  String get nightTclScheduleHint =>
      'ナイトモードが有効になっている間は同じスケジュールを使用します。 TCL フィルターへの手動変更は、次にスケジュールされた移行まで持続します。オーバーレイ許可は必要ありません。';

  @override
  String get nightRefreshPermission => '権限ステータスの更新';

  @override
  String get nightCityNotFound => '都市が見つかりませんでした。別の名前を試してください。';

  @override
  String get nightNoOffset => 'オフセットなし';

  @override
  String get nightManualSchedule => 'カスタムスケジュール';

  @override
  String get nightChooseCity => '都市を選択してください';

  @override
  String get nightPermissionUnknown => 'オーバーレイの許可ステータスが不明です';

  @override
  String get nightNextEnd => '次の終わり';

  @override
  String get nightTemporaryOff => 'まで調光は一時的にオフになります';

  @override
  String get nightCitySearchFailed => '都市を検索できませんでした。インターネット接続を確認してください。';

  @override
  String get nightSolarAttribution =>
      '毎日の太陽の時刻: Sunrise-Sunset.org;フォールバック: Open-Meteo。都市検索: GeoNames。オフラインで使用するために数日分がキャッシュされます。';

  @override
  String get nightTemporaryOn => 'まで一時的に調光します';

  @override
  String get homeScreen => 'ホーム画面';

  @override
  String get appearanceSettings => '外観';

  @override
  String get generalSettings => '上級者向け';

  @override
  String get advancedSettings => '上級者向け';

  @override
  String get controlAndStartup => 'ランチャーとテレビのコントロール';

  @override
  String get sectionsAndOrder => 'セクションと順序';

  @override
  String get topPanel => 'トップパネル';

  @override
  String get tileStyle => 'タイルスタイル';

  @override
  String get tilesAndLabels => 'タイルとラベル';

  @override
  String get highlightAndAnimation => 'ハイライトとアニメーション';

  @override
  String get androidTvSettings => 'Android TVの設定';

  @override
  String get weatherSettings => '天気設定';

  @override
  String get showHighlightOutline => 'ハイライトのアウトラインを表示';

  @override
  String get resetTilesAndPanel => 'タイルとパネルの設定をリセットする';

  @override
  String get resetTilesAndPanelHint =>
      '追加のタイル、ラベル、ハイライト、トップパネルのパラメータをリセットしますか?壁紙、アクセントカラー、タイルスタイル、ラベルの表示/非表示は維持されます。';

  @override
  String get panelAppearanceSettings => 'トップパネル外観';

  @override
  String get panelSharedHint => 'タイル設定で外観を変更します。';

  @override
  String get effectsCompatibilityHint =>
      '追加の外観: 輪郭は常に表示され、脈動しません。寸法スタイルには従来のアウトラインはありません。クラシックは脈動しません。強度はスケールとシャドウに影響します。スケーリングにはスペースが限られています。';

  @override
  String get sizeAndLayout => 'サイズとレイアウト';

  @override
  String get labelsGroup => 'ラベル';

  @override
  String get surfaceGroup => '表面';

  @override
  String get clockAndDateGroup => '時計と日付';

  @override
  String get networkAndTrafficGroup => 'ネットワークとトラフィック';

  @override
  String get buttonsGroup => 'ボタン';

  @override
  String get notificationAppsHint =>
      '通知が必要ないアプリはオフにしてください。スイッチを有効にすると通知が可能になります。アプリは引き続き起動できます。';

  @override
  String get notificationPanelLink => 'トップパネル外観';

  @override
  String get overlayAccessAdb => '他のアプリの上に重ねて表示（ADB）';

  @override
  String get tileStyleModern => 'モダン';

  @override
  String get tileStyleVolume => '次元';

  @override
  String get showTime => 'ショータイム';

  @override
  String get showDate => '上映日';

  @override
  String get showWeather => '天気を表示';

  @override
  String get showNetwork => 'ネットワークステータスを表示する';

  @override
  String get showTraffic => 'トラフィックを表示';

  @override
  String get scheduledBrightness => '予定明るさ';

  @override
  String get followTileStyle => 'スタイルに従う';

  @override
  String get androidTvSettingsHint => 'テレビのシステム設定を開きます';

  @override
  String get autoHideTopPanel => 'パネルを自動的に非表示にする';

  @override
  String get showSectionTitles => 'セクションのタイトルを表示する';

  @override
  String get usageDaily => '毎日';

  @override
  String get usageWeekly => '毎週';

  @override
  String get usageMonthly => '毎月';

  @override
  String get onlineWallpaperAddress => '画像アドレス (HTTPS)';

  @override
  String get watchNextAppLimits => 'アプリごとの制限';

  @override
  String get watchNextAppLimitsHint =>
      'ソース制限は全体の制限の前に適用されます。 Unlimited では全体の制限のみが維持されます。非表示のコンテンツは非表示のままになります。';

  @override
  String get rememberCategoryFocus => '最後にフォーカスされたカードを記憶する';

  @override
  String get automaticBackups => '自動バックアップ';

  @override
  String get automaticBackupsHint =>
      'ランチャーがアクティブな間、設定、壁紙、バナーの毎日のコピー。失敗したコピーは、ランチャーに戻った後に実行されます。このデバイスにプライベートに保存され、合計最大 256 MiB。アプリまたはそのデータを削除すると、それらも削除されます。外部バックアップも取っておいてください。';

  @override
  String get automaticBackupsEnabled => '毎日の自動バックアップ';

  @override
  String get automaticBackupsKeep => '保管するコピー';

  @override
  String get automaticBackupCreateNow => '今すぐ復元ポイントを作成します';

  @override
  String get automaticBackupFailed => 'バックアップ操作が失敗しました。空き容量を確認して再試行してください。';

  @override
  String get restorePoints => '復元ポイント';

  @override
  String get noRestorePoints => '復元ポイントはまだありません';

  @override
  String get updatePrereleases => 'プレリリースに更新する';

  @override
  String get topPanelObjects => 'オブジェクト';

  @override
  String get panelTransparency => 'パネルの透明度';

  @override
  String get panelTextBackground => 'テキストとボタンの背景';

  @override
  String get panelTextBackgroundColor => 'テキストとボタンの背景色';

  @override
  String get panelTextColor => 'テキストとボタンの色';

  @override
  String get panelTextSize => 'テキストとボタンのサイズ';

  @override
  String get panelFont => 'テキストフォント';

  @override
  String get fontSans => 'サンセリフ';

  @override
  String get fontSerif => 'セリフ';

  @override
  String get fontMono => '等空間';

  @override
  String get fontCondensed => '凝縮された';

  @override
  String get trafficPermissionGranted => 'トラフィック統計へのアクセスが許可されました';

  @override
  String get background => '背景';

  @override
  String get backgroundParameters => 'ソースの設定';

  @override
  String get resetAppearanceHint => '背景、アクセント、タイル、ラベル、ハイライト、アニメーションをリセットしますか?';

  @override
  String get wallpaperDimming => '調光';

  @override
  String get wallpaperPlacement => '配置';

  @override
  String get wallpaperDisplay => '壁紙表示';

  @override
  String get wallpaperContain => '全体画像を表示';

  @override
  String get wallpaperBlurred => 'ぼやけたコピーの上';

  @override
  String get wallpaperCover => '画面全体を埋める';

  @override
  String get wallpaperBrightness => '壁紙の明るさ';

  @override
  String get wallpaperSaturation => '彩度';

  @override
  String get categoryPadding => 'カテゴリのパディング';

  @override
  String get categoryLight => 'ライト';

  @override
  String get categoryBlue => 'ブルー';

  @override
  String get categoryPurple => '紫';

  @override
  String get categoryAllRows => 'すべて';

  @override
  String get categoryTeal => 'ティール';

  @override
  String get categoryMaxRows => '表示されるグリッド行';

  @override
  String get categoryDark => '暗い';

  @override
  String get categoryAppearance => 'カテゴリの外観';

  @override
  String get categoryBackground => 'カテゴリーの背景';

  @override
  String get categoryTransparent => '透明';

  @override
  String get slideshowInterval => '変更間隔';

  @override
  String get slideshowFolderSelected => 'このデバイスに保存されているフォルダーへのアクセス。';

  @override
  String get slideshowRandom => 'ランダムな順序';

  @override
  String get wallpaperSlideshow => 'フォルダーのスライドショー';

  @override
  String get slideshowNext => '次の画像';

  @override
  String get slideshowFolderRequired => 'フォルダーを選択してスライドショーを開始します。';

  @override
  String get slideshowHint =>
      '最大 1,000 個の画像と 4,000 個のフォルダー エントリ。最大 8 つの MiB ファイル。破損したファイルはスキップされ、最後の正常なイメージが保持されます。変更はバックグラウンドで停止します。別のデバイスに復元した後、再度フォルダーを選択してください。';

  @override
  String get slideshowSeconds => 's';

  @override
  String get slideshowError => '画像を読み取れません。有効な画像が含まれるアクセス可能なフォルダーを選択してください。';

  @override
  String get slideshowFolder => 'フォルダーを選択してください';

  @override
  String get slideshowRecursive => 'サブフォルダーを含める';

  @override
  String get weatherSourceKeyRequired => 'この気象情報源に API キーを追加します。';

  @override
  String get weatherOpenWeatherCredit =>
      '天気: OpenWeather (openweathermap.org)。毎日の値は、利用可能な 3 時間の予測期間を要約します。';

  @override
  String get weatherOpenWeatherHint =>
      '現在の天気と 5 日間/3 時間の天気予報にキーを使用します。各更新では 2 つのリクエストが行われます。アクセスと制限はプランによって異なります。';

  @override
  String get weatherOpenWeatherKey => 'OpenWeather APIキー';

  @override
  String get mediaPause => '一時停止';

  @override
  String get showNowPlaying => 'ホームで再生中を表示';

  @override
  String get nowPlayingAccessHint =>
      'メディア コントロールには、CuteLauncher の通知アクセスが必要です。プレイヤーが指定したアクションのみが表示されます。';

  @override
  String get nowPlaying => 'プレイ中';

  @override
  String get mediaNext => '次のトラック';

  @override
  String get mediaPlay => '再開';

  @override
  String get mediaControlError => 'プレーヤーは利用できないか、このアクションを受け入れませんでした。';

  @override
  String get nightUsageAccess => '使用状況へのアクセスを許可する';

  @override
  String get nightExcludedAppsHint =>
      'オーバーレイとスケジュールされた TCL フィルターは、選択したアプリで一時停止します。使用アクセスが必要です。それがないと除外を適用できません。';

  @override
  String get nightExcludedApps => '除外されたアプリ';

  @override
  String get adbPairPort => 'ペアリングポート';

  @override
  String get adbPairOverlayHint =>
      'ワイヤレス デバッグを開き、ペアリング コードでペアリングします。システム コード ダイアログを開いたままにしておきます。このフォームは 30 秒後にアクティブになります。両方のポートと、Android で示されるコードを入力します。';

  @override
  String get adbOverlaySettings => '30 秒間制御を設定に戻します';

  @override
  String get adbTlsHint =>
      '開発者向けオプションでワイヤレス デバッグを使用します。ペアリングと接続には異なるポートがあります。ファームウェアにペアリング コード画面がない場合、またはオーバーレイ ウィンドウがブロックされている場合は、代わりに TCP / RSA を使用してください。すべての接続はこのテレビに対してローカルのままです。';

  @override
  String get adbPaired => 'ペアリングしました。ワイヤレスデバッグ接続ポートを使用して接続を確認します。';

  @override
  String get adbTransport => '接続方法';

  @override
  String get adbPairCode => '6桁のコード';

  @override
  String get adbOverlayRequired => '[設定] 上でコードを入力するには、他のアプリの上に表示する権限が必要です。';

  @override
  String get adbOverlayPermission => '他のアプリの上に表示を許可する';

  @override
  String get adbTlsUnsupported =>
      'このファームウェアでは、必要な設定画面またはペアリング オーバーレイを開くことができません。 TCP/RSAを使用します。';

  @override
  String get adbConnectPort => '接続ポート';

  @override
  String get adbTls => 'TLS / ペアリングコード';

  @override
  String get adbTcp => 'TCP/RSA';

  @override
  String get adbPairingFailed =>
      'ペアリングに失敗しました。コードとペアリング ポートを確認し、Android コード ダイアログを開いたままにして、再試行してください。';

  @override
  String get adbTlsDisabled =>
      'ワイヤレス デバッグが無効になっているか、その状態が利用できません。開発者向けオプションで有効にします。';

  @override
  String get adbPairOverlay => '[設定] でペアリング コードを入力します';

  @override
  String get adbPair => 'ペア';

  @override
  String get adbDeveloperSettings => '開発者向けオプションを開く';

  @override
  String get adbTwoWindowsHint =>
      'このファームウェアが 2 つのウィンドウをサポートしている場合は、CuteLauncher の横にあるシステム ペアリング ダイアログを開いたままにし、ここにコードを入力します。直接ペアリングは、両方のウィンドウが開いているときにのみ使用できます。';

  @override
  String get adbTwoWindows => '2 番目のウィンドウで設定を開きます';

  @override
  String get autoLaunchBoot => 'TV起動後';

  @override
  String get autoLaunchOff => '無効';

  @override
  String get autoLaunchTitle => '自動起動';

  @override
  String get autoLaunchDelay => '打ち上げ遅延';

  @override
  String get autoLaunchHdmi => '選択した HDMI 入力に切り替えます';

  @override
  String get autoLaunchWake => '目覚めた後';

  @override
  String get autoLaunchHint =>
      'テレビの起動後またはスリープ解除後に開くアプリまたは HDMI 入力を選択します。以下のイベントと遅延を設定します。アクションは、Android が CuteLauncher を示すときに 1 回実行されます。リモート入力またはホーム画面から離れると、待機がキャンセルされます。 HDMIの入力は後から自由に変更できます。 CuteLauncher をデフォルトのランチャーとして設定するか、必要に応じて起動時に開始を有効にします。ウェイク検出には、CuteLauncher を実行し続ける必要があります。';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get autoLaunchApp => '選択したアプリを開く';

  @override
  String get autoLaunchTarget => '発射ターゲット';

  @override
  String get autoLaunchUnavailable => 'ターゲットが利用できないか、ファームウェアがこのアクションを許可していません。';

  @override
  String get autoLaunchCancelled => '延期された打ち上げは中止されました。';

  @override
  String get syncTitle => '交換設定';

  @override
  String get syncHint =>
      '設定ファイルを保存し、別のデバイスに転送して、そこで開きます。ファイルを交換して戻し、両方のデバイスを最新の状態にします。インターフェイス、タイル スタイル、表示設定は共有されます。アプリ、セクション、壁紙ファイル、権限、HOME、起動ルール、およびシークレットはこのデバイスに残ります。これは手動での交換です。アカウントやバックグラウンド ネットワーク接続は使用されません。';

  @override
  String get syncExport => '変更をファイルに保存する';

  @override
  String get syncImport => '別のデバイスから変更を開く';

  @override
  String get syncSaved => '設定交換ファイルが保存されました。';

  @override
  String get syncFailed =>
      '設定を交換できません。部分的なインポートは保持されません。ファイルを確認するか、レビュー中に設定が変更された場合はファイルを再度開きます。';

  @override
  String get syncPreviewHint =>
      '適用する前に変更内容を確認してください。競合する場合は、各行を選択してこのデバイスまたはファイルを選択します。最初は「このデバイスを保持する」が選択されています。キャンセルすると設定は変更されません。';

  @override
  String get syncNoChanges => '新しい設定はありません。共有履歴の承認を申請します。';

  @override
  String syncLocalValue(String value) {
    return 'このデバイス: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'ファイルから: $value';
  }

  @override
  String get syncKeepLocal => '競合: このデバイスを維持します';

  @override
  String get syncUseFile => '競合: ファイルを使用します';

  @override
  String get syncApply => 'レビューされた変更を適用する';

  @override
  String get syncApplied => '設定を交換しました。新しいファイルを保存して結果を送り返します。';

  @override
  String syncStyleParameters(int count) {
    return 'カスタムスタイル：$count個の設定（相違点は下記）';
  }

  @override
  String get cloudBackups => 'クラウドバックアップ';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud。既存のフォルダーの HTTPS アドレスとアプリのパスワードを入力します。転送は手動です。このフォルダーには最新のコピーが保存されます。';

  @override
  String get cloudUrl => 'フォルダ HTTPS アドレス';

  @override
  String get cloudUser => 'ユーザー名';

  @override
  String get cloudPassword => 'アプリのパスワード';

  @override
  String get cloudConnect => 'アカウントを確認して保存する';

  @override
  String get cloudCheck => '接続を確認してください';

  @override
  String get cloudDisconnect => 'アカウントを切断する';

  @override
  String get cloudDisconnectConfirm => 'このアカウントをテレビから削除しますか?クラウド上のコピーは残ります。';

  @override
  String get cloudUpload => 'コピーをクラウドに保存する';

  @override
  String get cloudDownload => 'クラウドから復元する';

  @override
  String get cloudUploadConfirm =>
      'このフォルダー内のcutelauncher_backup.jsonを現在の設定とデータに置き換えますか?';

  @override
  String get cloudSuccess => '完了';

  @override
  String get cloudConfigurationError =>
      'HTTPS フォルダーのアドレス、ユーザー名、アプリのパスワードを確認してください。';

  @override
  String get cloudAuthorizationError => 'アクセスが拒否されました。アカウントとフォルダーの権限を確認してください。';

  @override
  String get cloudMissingError => 'フォルダーまたはバックアップが見つかりませんでした。';

  @override
  String get cloudUnsupportedError =>
      'このアドレスは、必要な WebDAV 操作をサポートしていません。リダイレクトは追跡されません。最終的なフォルダーアドレスを入力します。';

  @override
  String get cloudNetworkError =>
      '接続が失敗したか、タイムアウトになりました。ネットワークが利用可能なときに再試行してください。';

  @override
  String get cloudFailed => 'バックアップ操作を完了できませんでした。ストレージへのアクセスを確認して、再試行してください。';

  @override
  String get cloudStorageError => 'アカウントのストレージが利用できません。切断してアカウントを再度設定します。';

  @override
  String get adbPermissionChecking => 'アクセスを確認中…';

  @override
  String get adbPermissionConnected => 'ADB 接続済み · 許可を付与';

  @override
  String get adbPermissionDisconnected => 'ADB が切断されました · 接続をセットアップしました';

  @override
  String get adbSetupIntro =>
      'TV 開発者設定でデバッグとネットワーク ADB を有効にし、CuteLauncher を信頼します。 ADB のすべての操作は自己責任で行ってください。';

  @override
  String get adbConnectionBlock => 'ADB接続';

  @override
  String get adbNotChecked => '接続はチェックされていません';

  @override
  String get adbApplied => 'すでに適用されています';

  @override
  String get adbNotApplied => 'まだ適用されていません';

  @override
  String get adbDefaultBlock => 'デフォルトのランチャー';

  @override
  String get adbSystemDefault => 'オープンシステムのデフォルトランチャー設定';

  @override
  String get adbAssignDefault => 'ADB 経由で CuteLauncher をデフォルトのランチャーとして設定します';

  @override
  String get adbRestoreDefault => 'ADB 経由で以前のデフォルトのランチャーを復元します';

  @override
  String get adbDefaultHint => 'システムメニューでデフォルトのランチャーを設定できない場合は、ADB を使用してください。';

  @override
  String get adbBuiltinHint =>
      '内蔵ランチャーを無効にすると、システムは代わりに CuteLauncher を開くことができます。テレビのメニューとボタンが影響を受ける可能性があります。これを元に戻すには、組み込みのランチャーを有効にします。';

  @override
  String get adbHomeBlock => 'ホームボタンと起動';

  @override
  String get adbEnableService => 'ADB 経由で CuteLauncher アクセシビリティ サービスを有効にする';

  @override
  String get adbHomeOverride => 'ホームボタンを上書きする';

  @override
  String get adbHomeOptional =>
      '内蔵ランチャーが無効になっている場合、ホームのオーバーライドと TV 起動時の起動はオプションです。';

  @override
  String get adbEnableBuiltin => 'ADB 経由で内蔵ランチャーを有効にする';

  @override
  String get adbDisableBuiltin => 'ADB 経由で内蔵ランチャーを無効にする';

  @override
  String get adbNoBuiltin => '内蔵の Google TV / Android TV ランチャーが見つかりません。';

  @override
  String get adbChanged => '状態が変わりました。接続を確認し、動作を再度確認してください。';

  @override
  String get adbEffectHome =>
      'CuteLauncher がシステムのデフォルトのランチャーになります。現在のランチャーは復元のために保存されます。';

  @override
  String get adbEffectRestore =>
      '以前のランチャーが有効になり、デフォルトになります。使用できない場合、または保存されていない場合は、最初に使用可能な他のランチャーが選択されます。これによってホームボタンの修正が無効になるわけではありません。';

  @override
  String get adbEffectDisable =>
      '内蔵ランチャー アプリは TV ユーザーに対して無効になります。テレビのメニューやボタンが機能しなくなる場合があります。アプリはアンインストールされていません。';

  @override
  String get adbRecoveryHomeDisable =>
      'リカバリ ホーム画面を含む Google TV セットアップ ウィザード全体も無効になり、CuteLauncher がデフォルトのランチャーになることができます。セットアップ ウィザードの機能は、復元するまで使用できません。両方のパッケージの元の状態が復元のために保存されます。';

  @override
  String get adbRecoveryHomeRestore => 'Google TV セットアップ ウィザードも保存された状態に戻ります。';

  @override
  String get adbDisableHomeUnavailable =>
      '別のホーム画面の方が優先されます。このランチャーでは安全に無効にすることはできません。';

  @override
  String get adbEffectEnable =>
      '組み込みランチャーは保存された状態に復元され、状態が保存されていない場合は有効になります。システムはそれをデフォルトのランチャーとして再度選択する場合があります。';

  @override
  String get adbEffectAccessibility =>
      'CuteLauncher アクセシビリティ サービスが有効になります。ホーム イベントを受信できます。インターセプトは別のスイッチによって制御されます。他のサービスは維持されます。';

  @override
  String get adbEffectAccessibilityRestore =>
      'CuteLauncher サービスは、ADB アクセスが許可される前の状態に戻ります。他のアクセシビリティ サービスは維持されます。';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher は、夜間フィルターを含む他のアプリの上にウィンドウを表示できるようになります。';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher は、独自のリスナー サービスを通じて通知アクセスを受け取ります。';

  @override
  String get adbEffectWatchNext => 'CuteLauncher は、データの監視を継続するためのアクセスを受け取ります。';

  @override
  String get adbEffectUsage =>
      'CuteLauncher は、トラフィックとフォアグラウンド アプリ検出のための使用統計アクセスを受け取ります。';

  @override
  String get adbEffectWriteSettings => 'CuteLauncher はシステムの明るさ設定を変更できるようになります。';

  @override
  String get adbNoAvailableLauncher =>
      '他にインストールされているランチャーは見つかりませんでした。復元はできません。';

  @override
  String get adbUnsupported => 'このデバイスでは使用できません: サポートされている ADB コマンドはありません。';

  @override
  String get adbHomeUnavailable =>
      '内蔵ランチャーはシステム優先です。 ADB を介した直接割り当ては利用できません。アクセシビリティを使用するか、内蔵ランチャーを無効にしてください。';

  @override
  String get nightBatteryExempt => 'CuteLauncherは最適化の対象外です';

  @override
  String get nightBatteryHint =>
      'スケジュールがバックグラウンドで実行されるのに役立つ場合があります。プロセスがスタンバイ状態で存続することは保証されません。';

  @override
  String get nightBatteryOptimized => 'CuteLauncherは最適化の対象です';

  @override
  String get nightBatteryTitle => 'バッテリーの最適化';

  @override
  String get nightBatteryUnavailable =>
      'このファームウェアではシステム設定を利用できないか、アクセスが拒否されました。';

  @override
  String get nightBatteryUnknown => '免除状況は不明';

  @override
  String get nightBatteryOpenApps => 'アプリ設定を開く';

  @override
  String get nightBatteryGuide =>
      '1. [アプリ設定] で、[特別なアプリ アクセス] を開きます。\n2. バッテリーの最適化 (場合によっては省エネ) を選択します。\n3. CuteLauncher を見つけます。必要に応じて、「すべてのアプリ」を選択します。\n4. 最適化を無効にするか、「無制限」を選択します。\nメニュー名と利用できるかどうかは、テレビのファームウェアによって異なります。';

  @override
  String get updateNotifications => '更新通知を表示する';

  @override
  String get diagnosticsSave => 'レポートをファイルに保存';

  @override
  String get diagnosticsSaved => 'レポートが保存されました';

  @override
  String get diagnosticsSaveFailed =>
      'レポートを保存できませんでした。ファイルマネージャーと保存先フォルダーを確認してください。';

  @override
  String get memoryCacheSize => '画像キャッシュサイズ';

  @override
  String get memoryProcess => 'アプリのメモリ';

  @override
  String get memoryImages => '画像キャッシュ';

  @override
  String get diagnosticsExportOpened => 'ファイル マネージャーでフォルダーを選択し、レポートを保存します。';

  @override
  String get adbDisableService => 'ADB 経由で CuteLauncher アクセシビリティ サービスを無効にする';

  @override
  String get adbDefaultSettings => 'デフォルトのランチャー設定';

  @override
  String get adbHomeSettings => 'ホームボタンの設定';

  @override
  String get adbAccessibilitySettings => 'アクセシビリティ設定を開く';

  @override
  String get adbAccessibilityGuide =>
      'システムメニューでCuteLauncherを選択し、そのサービスを有効にします。ここに戻ってホーム インターセプトを設定します。これを無効にするには、同じメニューで CuteLauncher サービスをオフにします。';

  @override
  String get adbEffectAccessibilityDisable =>
      'CuteLauncher サービスは無効になります。ホームインターセプトは停止します。他のアクセシビリティ サービスは維持されます。';

  @override
  String get backupAutoEnabled => '自動バックアップ';

  @override
  String get backupClientId => 'クライアントID';

  @override
  String get backupClientSecret => 'クライアントシークレット';

  @override
  String get backupCloudImportConfirm =>
      'すべてのローカル設定、カテゴリ、画像はクラウド データに置き換えられます。続く？';

  @override
  String get backupConfigured => '設定済み';

  @override
  String get backupConnection => '接続設定';

  @override
  String get backupCreated => '作成されました';

  @override
  String get backupDaily => '毎日';

  @override
  String get backupDriveHelp =>
      '[接続] を選択し、携帯電話でコードを確認します。バックアップは、Google Drive の CuteLauncher フォルダーに表示され、ダウンロードまたは削除できます。アプリ内復元ではファイル名を変更しないでください。非表示のバックアップからアップグレードした後に再接続します。古いバックアップは自動的に移行されません。';

  @override
  String get backupFrequency => 'バックアップ頻度';

  @override
  String get backupHourly => '毎時';

  @override
  String get backupLocal => 'ローカルコピー';

  @override
  String get backupMinutes => '分';

  @override
  String get backupMode => 'モード';

  @override
  String get backupNever => 'まだバックアップがありません';

  @override
  String get backupNotConfigured => '未設定';

  @override
  String get backupOptions => 'バックアップオプション';

  @override
  String get backupSaveMode => 'バックアップ';

  @override
  String get backupScope => 'テレビ間でのバックアップ';

  @override
  String get backupSyncScope => 'テレビ間での同期';

  @override
  String get backupSeparate => 'テレビごとに分ける';

  @override
  String get backupShared => 'すべてのテレビで同じ設定';

  @override
  String get backupStorage => 'ストレージ';

  @override
  String get backupSyncHelp =>
      'データをダウンロードし、変更をアップロードします。最新の変更は競合に勝ちます。テレビの時計は正確でなければなりません。同期はランチャーが開いている間に実行されます。';

  @override
  String get backupSyncLimit => '以下の頻度でチェックしてください';

  @override
  String get backupSyncMode => '同期';

  @override
  String get backupSyncOptions => '同期オプション';

  @override
  String get backupTime => 'バックアップ時間';

  @override
  String get backupWeekday => '曜日';

  @override
  String get backupWeekly => '毎週';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'ローカル コピーはアプリまたはそのデータとともに削除されます。コピーをテレビの外にも保管してください。';

  @override
  String get panelObjectOrder => 'オブジェクトの順序';

  @override
  String get panelInformationGroup => '情報';

  @override
  String get panelOrderHint =>
      '◄ / ► で移動を開始・終了、▲ / ▼ で順序を変更し、グループの境界で反対側へ移動、OK / 戻るで終了。';

  @override
  String get panelTextBackgroundTransparency => 'テキストとボタンの背景の透明度';

  @override
  String get weatherCityHint => '都市名を英語で入力します (たとえば、Moscow)。';

  @override
  String get weatherCityNotFound => '都市が見つかりません。都市名を英語で確認してください。';

  @override
  String get weatherLocationAutomatic => '自動的に取得';

  @override
  String get weatherLocationAutomaticHint => 'デバイスの座標を取得します。位置情報の許可が必要です。';

  @override
  String get weatherLocationManual => '手動で入力';

  @override
  String get weatherLocationPermissionDenied =>
      'Android 設定で位置情報へのアクセスを許可し、再試行してください。';

  @override
  String get weatherLocationUnavailable =>
      '座標を取得できませんでした。 Android の位置設定を確認するか、手動で都市を入力してください。';

  @override
  String get nightFilterSettings => 'フィルター設定';

  @override
  String get nightScheduleMenu => 'スケジュール';

  @override
  String get nightScheduleInactive => 'スケジュールはオフです';

  @override
  String get nightLocation => '場所';

  @override
  String get nightLocationAutomatic => '自動的に取得';

  @override
  String get nightLocationManual => '手動で入力';

  @override
  String get nightLocationFailed => '場所が利用できません。権限とシステムの場所の設定を確認してください。';

  @override
  String get nightCityEnglish => '都市名を英語で入力してください';

  @override
  String get nightOverlayBrief => 'フィルターを他のアプリの上に表示できるようにします。';

  @override
  String get weatherGetLocation => '位置情報を取得';

  @override
  String get backupLastCreated => '最後のバックアップが作成されました:';

  @override
  String get backupManagement => 'バックアップの管理';

  @override
  String get backupCopyList => 'バックアップリスト';

  @override
  String get backupRefreshCopyList => 'バックアップリストを更新する';

  @override
  String get backupCreateNow => '今すぐ新しいバックアップを作成してください';

  @override
  String get backupFolderPath => 'バックアップフォルダ';

  @override
  String get backupPrivateFolder => 'プライベートアプリケーションフォルダー';

  @override
  String get backupRestoreCopy => 'このバックアップを復元します';

  @override
  String get backupDeleteConfirm => '選択したバックアップを削除しますか?';

  @override
  String get blockedAppsGroup => 'ブロックされたアプリ';

  @override
  String get notificationSettingsButton => '通知設定';

  @override
  String get hidePersistentNotificationsHint => 'リスト内および他のアプリ上で永続的な通知を非表示にします。';

  @override
  String get nightTransitionTime => '移行時間';

  @override
  String get brightnessSolar => 'ナイトモードスケジュールを使用する';

  @override
  String get brightnessAfterSunrise => '日の出後';

  @override
  String get brightnessAfterSunset => '日没後';

  @override
  String get brightnessTransitionTime => '明るさの遷移時間';

  @override
  String get brightnessSolarUnavailable =>
      'ナイトモードスケジュールは利用できません。時間と場所を確認してください。';

  @override
  String get persistentNotificationCannotDelete =>
      'この永続的な通知は削除できません。ブロックすることしかできません。';

  @override
  String get diagnosticsCreateFailed => '診断レポートを作成できませんでした。もう一度やり直してください。';

  @override
  String get backupListFailed => 'バックアップリストをロードできませんでした。選択したストレージへのアクセスを確認します。';

  @override
  String get updateInstallerFailed =>
      'アップデートインストーラーを開けませんでした。もう一度試して、Android インストーラーが利用可能であることを確認してください。';

  @override
  String get backupFolderFailed =>
      'バックアップフォルダーを選択または保存できませんでした。アクセス可能なフォルダーを選択して、再試行してください。';

  @override
  String get updateDownloadFailed =>
      'アップデートをダウンロードできませんでした。インターネット接続と利用可能なストレージを確認してください。';

  @override
  String get backupDeleteFailed => 'バックアップを削除できませんでした。削除権限を確認して、再試行してください。';

  @override
  String get updateCheckFailed =>
      'アップデートを確認できませんでした。インターネット接続を確認して、もう一度試してください。';

  @override
  String get backupCreateFailed => 'バックアップを作成できませんでした。ストレージへのアクセスと空き容量を確認します。';

  @override
  String get wallpaperChangeFailed => '壁紙を変更できませんでした。ファイルアクセスを確認して、再試行してください。';

  @override
  String get backupDownloadsFolder => 'ダウンロード / CuteLauncher';

  @override
  String get backupChooseFolder => 'ファイルマネージャーでフォルダーを選択する';

  @override
  String get backupFolderPickerUnavailable =>
      'このテレビではフォルダー ピッカーを利用できません。ダウンロード / CuteLauncher または内部アプリ フォルダーを選択します。';

  @override
  String get driveConfigurationError =>
      'Google Drive 資格情報が見つからないか、無効です。 TV OAuth クライアントのクライアント ID とクライアント シークレットを入力します。';

  @override
  String get driveCodeExpired =>
      'Google Drive サインインがタイムアウトしました。新しいコードを取得するには、「アカウントを確認して保存」を選択します。';

  @override
  String get brightnessAfterNightStart => '夜間';

  @override
  String get brightnessAfterNightEnd => '昼間';

  @override
  String get backupSyncSettings => '同期する設定';

  @override
  String get backupSyncHomeGroup => 'ホーム画面、セクション、アプリ';

  @override
  String get backupSyncAppearanceGroup => '外観、壁紙、バナー';

  @override
  String get backupSyncDisplayGroup => 'ナイトモード、明るさ、スクリーンセーバー';

  @override
  String get backupSyncControlsGroup => 'ランチャーとテレビのコントロール';

  @override
  String get backupSyncGeneralGroup => '言語、アップデート、その他の設定';

  @override
  String get backupSyncGroupsHelp =>
      '無効化されたブロックは、このテレビに対してローカルのままです。ブロック選択はデバイス間で同期されます。';

  @override
  String get backupSyncGroupsFailed => '同期用の設定の選択を保存できませんでした。もう一度やり直してください。';

  @override
  String get tileLayoutMode => 'タイルレイアウト';

  @override
  String get tileLayoutAuto => 'タイルサイズに応じて自動';

  @override
  String get tileLayoutColumns => '固定列数';

  @override
  String get tileLayoutRows => '固定行数';

  @override
  String get tileRowCount => '行数';

  @override
  String get useGlobalTileSettings => 'グローバル設定を使用する';

  @override
  String get centerSelection => '選択位置';

  @override
  String get selectionBottom => '下';

  @override
  String get selectionLower => '中下';

  @override
  String get selectionCenter => 'センター';

  @override
  String get selectionUpper => '上中';

  @override
  String get selectionTop => 'トップへ';

  @override
  String get settingsStyle => '設定スタイル';

  @override
  String get tileFocusEnlargement => '焦点拡大';

  @override
  String get tileFocusShadowStrength => '影の強さ';

  @override
  String get tileFocusLift => 'リフト';

  @override
  String get tileFocusLiftHeight => 'リフト高さ';

  @override
  String get tileFocusBorderColor => 'フォーカスの境界線の色';

  @override
  String get tileFocusAccentColor => 'アクセントカラー';

  @override
  String get tileFocusDynamicColor => 'ダイナミックなカラー';

  @override
  String get tileSizeFromColumns => 'タイルのサイズは、列数とセクション幅によって決まります。';

  @override
  String get resetSectionToGlobal => '設定を共有値にリセット';

  @override
  String get resetSectionToGlobalHint =>
      '共有セクションのタイトル、アイコン、背景を復元し、パディングをリセットしますか?';

  @override
  String get resetStyleSection => 'このセクションをリセット';

  @override
  String get resetStyleSectionHint => 'このセクションのみをデフォルトに戻しますか?';

  @override
  String get notificationStyle => '通知スタイル';

  @override
  String get styleBackgroundColor => '背景色';

  @override
  String get styleTransparency => '背景の透明度';

  @override
  String get styleTextSize => '文字サイズ';

  @override
  String get styleTextColor => '文字の色';

  @override
  String get noticeSize => '通知サイズ';

  @override
  String get noticeStylePreview => '通知プレビュー';

  @override
  String get backupSyncHomeOptions => '動作と一般的なオプション';

  @override
  String get backupSyncBackground => '背景とカスタムバナー';

  @override
  String get backupSyncTiles => 'タイル、メニュー、通知スタイル';

  @override
  String get backupSyncWeatherSource => '出典と場所';

  @override
  String get backupSyncWeatherDisplay => '天気表示と温度単位';

  @override
  String get backupSyncNotificationSettings => '通知の表示とフィルター';

  @override
  String get backupSyncOther => 'その他の設定';

  @override
  String get tileFocusBorderStyle => 'ボーダースタイル';

  @override
  String get tileFocusOutline => '概要';

  @override
  String get tileFocusGlow => 'グロー';

  @override
  String get tileFocusNoBorder => '境界線なし';

  @override
  String get tileShowFocusShadow => '影を表示する';

  @override
  String get homeLayoutRow => '横列';

  @override
  String get homeLayoutRows => '複数の行';

  @override
  String get homeLayoutGrid => 'グリッド';

  @override
  String get homeCardCount => '全体に表示されるカード';

  @override
  String get homeAuto => '自動';

  @override
  String get homeFree => '無料スクロール';

  @override
  String get homeAnchored => 'アンカーセクション';

  @override
  String get homeScrollMode => 'セクションのスクロール';

  @override
  String get homeSectionPosition => 'アクティブセクションの位置';

  @override
  String get homeLabelMode => 'アプリケーションラベル';

  @override
  String get homeLabelNone => 'ラベルなし';

  @override
  String get homeLabelSelected => '選択したアプリケーションのみ';

  @override
  String get homeLabelAll => 'すべてのアプリケーション';

  @override
  String get homeInherited => '継承値';

  @override
  String get homeOwnReset => '共通設定に戻す';

  @override
  String get homeParameters => 'パラメータ';

  @override
  String get homeSectionStyle => '断面の外観';

  @override
  String get homeSectionGap => 'セクション間のスペース';

  @override
  String get homeSectionIcons => 'セクションアイコン';

  @override
  String get homeInactiveOpacity => '非アクティブセクションの不透明度';

  @override
  String get homeResetSection => '継承されたセクションの外観を復元する';

  @override
  String get homeCalculatedSize => 'サイズはカード枚数から計算されます';

  @override
  String homeGapLimited(int gap) {
    return '選択したカード数を維持するために、間隔は $gap に制限されます。';
  }

  @override
  String get homeResetLayout => 'セクションのレイアウトをリセット';

  @override
  String homeVisibleRows(int count) {
    return '完全に表示される行: $count';
  }

  @override
  String get homeStylePartial => 'この値を継承し、現在のレイアウトでサポートするセクションにのみ適用されます。';

  @override
  String get homeStyleUnavailable =>
      '現在のセクション設定では使用できません。レイアウトとローカル オーバーライドを確認してください。';

  @override
  String get homeStyleNeedsRows => '複数の行またはグリッドで使用できます。';

  @override
  String get homeStyleNeedsLabels => 'ラベルのサイズと色を変更できるようにします。';

  @override
  String get homeStyleNeedsAllLabels =>
      '位置はすべてのカードのラベルにのみ適用されます。選択したタイトルはセクションの下に残ります。';

  @override
  String get homeStyleNeedsScale => '拡大フォーカス効果を選択します。';

  @override
  String get homeStyleNeedsLift => 'リフトフォーカス効果を選択します。';

  @override
  String get homeStyleNeedsBorder => '最初にアウトラインまたはグローを有効にします。';

  @override
  String get homeStyleNeedsTitle => 'セクションのタイトルを有効にしてアイコンを表示します。';

  @override
  String get homeStyleEconomy => 'メモリ節約により無効化されました。保存された値は保持されます。';

  @override
  String get homeStyleOpaque => 'ぼやけを確認するには、タイルの背景の不透明度を下げます。';

  @override
  String get homeStyleOverridden =>
      '表示されているセクションでは独自の値が使用されます。この設定を適用するには、セクションで「グローバルを使用」を選択します。';

  @override
  String get homeStyleIconHint =>
      'アイコンのサイズは、アプリのアイコンが含まれるカードに影響します。テレビ バナーはカードに独立して埋められます。';

  @override
  String get homeStyleShadowHint =>
      'メモリ節約により、非アクティブなカードのシャドウが 4 に制限されます。フォーカス シャドウは個別に設定されます。';

  @override
  String get homeStyleTransparent => '不透明度がゼロの場合、背景色は見えません。タイルの背景の不透明度を上げます。';

  @override
  String get homeStyleSingleColumn => '単列グリッドには水平方向のギャップがありません。';

  @override
  String get homeStyleAutoOnly => 'サイズは、グローバル サイズを継承する自動カード数のセクションでのみ変更されます。';

  @override
  String get sleepTimerThirtySeconds => '30秒（テスト）';

  @override
  String get sleepTimer => 'スリープタイマー';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes 分';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours時間',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1.5時間';

  @override
  String get sleepTimerAllowExact => '正確なタイマーを許可する';

  @override
  String get sleepTimerExactRequired => 'Android 設定で正確なタイマーを許可し、期間を再度選択します。';

  @override
  String get sleepTimerAccessRequired =>
      'CuteLauncher のアクセシビリティを有効にするか、[設定] → [その他] → [ADB] でローカルの ADB に接続します。';

  @override
  String get sleepTimerFailed =>
      'スリープ タイマーを設定または完了できませんでした。アクセシビリティとローカルの ADB を確認してください。';

  @override
  String get nightIgnoreHdmiInputs => 'HDMI 入力を無視する';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'HDMI を見ている間、ナイトフィルターを一時停止します。使用アクセスが必要です。入力検出はテレビのファームウェアに依存します。';

  @override
  String get inputsSettings => '入力設定';

  @override
  String get inputsUseCecNames => 'CEC からのデバイス名を使用します';

  @override
  String get inputsNamesHint =>
      '名前の優先順位: CuteLauncher の名前 → CEC (有効な場合) → Android 設定の名前 → 標準入力名。';

  @override
  String get inputNameHint => '自動名を付ける場合は空白のままにします';

  @override
  String get inputsSaveFailed => '入力設定を保存できませんでした';

  @override
  String get inputIcon => '入力アイコン';

  @override
  String get inputIconTv => 'テレビ';

  @override
  String get inputIconGame => 'ゲーム機';

  @override
  String get inputIconComputer => 'コンピュータ';

  @override
  String get inputIconReceiver => '受信機';

  @override
  String get inputIconDisc => 'ディスクプレーヤー';

  @override
  String get inputIconStream => 'ストリーミングデバイス';

  @override
  String get nightInputExclusions => '入力の除外';

  @override
  String get nightSelectInputs => '無視する入力を選択してください';

  @override
  String get nightNoInputsSelected => '入力が選択されていません。フィルターはすべての入力に適用されます。';

  @override
  String get nightPictureExclusions => 'ピクチャーモードの除外事項';

  @override
  String get nightPictureExclusionsHint =>
      '調光、ウォームオーバーレイ、リンクされた TCL フィルターを一時停止するモードを選択します。スケジュールは保存されます。 TCL で検出が確認されています。使用アクセスは必要ありません。';

  @override
  String get nightPictureUnavailable =>
      '現在の画像モードはこのファームウェアでは使用できません。選択内容が保存されます。除外は、検出が成功した場合にのみ適用されます。';

  @override
  String get nightPictureCurrent => '現在のモード';

  @override
  String get nightPictureRefresh => '現在のリフレッシュモード';

  @override
  String get nightPictureCode => 'モードコード';

  @override
  String get nightPictureStandard => '標準';

  @override
  String get nightPictureDynamic => 'ダイナミック';

  @override
  String get nightPictureMovie => '映画';

  @override
  String get nightPictureSport => 'スポーツ';

  @override
  String get nightPictureIntelligent => 'インテリジェント';

  @override
  String get nightPictureBright => 'ブライト (Dolby Vision)';

  @override
  String get nightPictureOrdinary => '標準';

  @override
  String get systemApplications => 'システムアプリ';

  @override
  String get removeFromCategory => 'カテゴリから削除';

  @override
  String get noRemovableCategories =>
      'このアプリはどのセクションにも手動追加されていません。標準の自動セクション（すべて、TV用、TV以外）からは削除できません。「非表示」を使用してください。お気に入りは手動編集できます。';

  @override
  String get remoteButtonsTitle => 'リモコンボタンの割り当て';

  @override
  String get remoteButtonsStart => 'ボタンを確認（120秒）';

  @override
  String get remoteButtonsStop => '確認を終了';

  @override
  String get remoteButtonsHint =>
      'コード、解放、リピートを表示し、テレビにテキストレポートを保存します。OKが記録を操作しないよう、開始後はこのページを離れてください。';

  @override
  String get remoteButtonsEmpty =>
      'イベントはまだありません。ボタンでアプリが開いた場合は、ここに戻ると結果を確認できます。';

  @override
  String get remoteButtonsService => 'サービス接続済み';

  @override
  String get remoteButtonsRefresh => '更新';

  @override
  String get remoteBindings => 'ボタンの割り当て';

  @override
  String get remoteMappingsEnabled => '割り当てを有効にする';

  @override
  String get remoteMappingsAdd => '割り当てを追加';

  @override
  String get remoteMappingKey => 'ボタン';

  @override
  String get remoteMappingAction => '動作';

  @override
  String get remoteMappingLearn => 'リモコンボタンを検出';

  @override
  String get remoteMappingLearnHint =>
      '30秒以内に追加ボタンを押してください。移動、Power、音声検索、音量ボタンは保護されています。';

  @override
  String get remoteMappingsHint =>
      '割り当てにはユーザー補助サービスが必要です。編集画面と診断中は一時停止します。Home、戻る、矢印、OKは通常の移動に使えます。';

  @override
  String get remoteMappingsReset => '割り当てをリセット';

  @override
  String get remoteMappingsResetConfirm => 'すべての割り当てを削除して無効にしますか？';

  @override
  String get remoteMappingInvalid =>
      '保存できませんでした。ボタンと対象を確認してください。WebhookにはHTTPSまたはローカルネットワークのHTTPが必要です。';

  @override
  String get remoteMappingBack => '戻る';

  @override
  String get remoteMappingProfile => 'プロフィール';

  @override
  String get remoteMappingChannels => 'チャンネル';

  @override
  String get remoteMappingQuickSettings => 'TCLクイック設定';

  @override
  String get remoteMappingTrigger => '押し方';

  @override
  String get remoteMappingPress => '短押し';

  @override
  String get remoteMappingHold => '長押し';

  @override
  String get remoteMappingHoldHint =>
      '650ミリ秒の長押しで一度だけ実行し、短押し動作は実行しません。長押しのみ割り当てた場合、短押しは何もしません。';

  @override
  String get remotePanelDescription =>
      'クイック設定パネルは他のアプリの上にウィジェットを表示します。リモコンで開くには、好きなボタンに「クイック設定パネル」アクションを割り当ててください。';

  @override
  String get remotePanel => 'クイック設定パネル';

  @override
  String get remotePanelSettingsBackground => '設定の背景色を使用';

  @override
  String get remotePanelPreview => 'パネルを開く';

  @override
  String get settingsHelp => '詳細情報';

  @override
  String get settingsHelpScroll => '▲ / ▼ — テキストをスクロール';

  @override
  String get panelClockStyle => '時計の外観';

  @override
  String get clockPreset => 'フォントスタイル';

  @override
  String get clockCustom => 'カスタム';

  @override
  String get clockWeight => '文字の太さ';

  @override
  String get clockGlow => '文字の発光';

  @override
  String get clockAnimate => '数字のアニメーション';

  @override
  String get clockBackground => '時計の背景';

  @override
  String get clockRadius => '背景の角の丸み';

  @override
  String get dateCalendarEnabled => '日付を押してカレンダーを開く';

  @override
  String get calendarTitle => 'カレンダー';

  @override
  String get dateSettings => '日付の設定';

  @override
  String get clockSharedBackground => '他の項目と同じ背景を使う';

  @override
  String get clockDefaultBackground => '既定の背景';

  @override
  String get remotePanelInheritAppearance => '上部パネルの外観を使用';

  @override
  String get remotePanelDisabledInLauncher =>
      'CuteLauncher の表示中はクイック設定パネルを開けません。';

  @override
  String get remoteAccessSettings => 'アクセス設定';

  @override
  String get remoteButtonsTest => 'ボタンテスト';

  @override
  String remoteMappingDeleteConfirm(String name) {
    return '割り当て「$name」を削除しますか？';
  }

  @override
  String get remoteMappingConflict =>
      'このボタンと押し方はすでに割り当てられています。別のボタンまたは押し方を選んでください。';

  @override
  String get cleanerTitle => 'TV cleanup manager';

  @override
  String get cleanerRefresh => 'Refresh applications';

  @override
  String get cleanerSnapshot => 'Save original state';

  @override
  String get cleanerRestore => '基準状態に復元';

  @override
  String get cleanerSnapshotSaved => 'Original state saved';

  @override
  String get cleanerExportSnapshot => 'Export original state';

  @override
  String get cleanerSafe => 'Disable verified applications';

  @override
  String get cleanerNoSafe => 'このモデルとファームウェアに一致するシステムアプリ一覧はありません。';

  @override
  String get cleanerLocal => 'Disable using a local list';

  @override
  String get cleanerProject => 'Project catalog lists';

  @override
  String get cleanerRemoteProject => 'Refresh catalog from GitHub';

  @override
  String get cleanerExternal => 'CleanYourTV examples';

  @override
  String get cleanerDisabledExport => '無効なアプリのレポートをファイルに出力';

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
      '基準状態は最初の一覧更新成功時に一度だけ作成され、ランチャーから削除・上書きできません。ファームウェアに紐付きます。手動状態は現在のアプリ状態を名前と日時付きで保存し、復元・削除・出力できます。APKやアプリのデータは含みません。復元にはローカルADBが必要です。クラッシュループ保護が作動すると基準状態の自動復元を試みます。ランチャーのデータ消去やアンインストールで保存状態も削除されます。rootアクセスは防止できません。';

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
  String get informationGroup => '時計・日付・天気';

  @override
  String get informationSettings => 'ブロックの設定';

  @override
  String get informationAppearance => 'ブロックの外観';

  @override
  String get informationSize => 'ブロックのサイズ';

  @override
  String get informationPosition => '時計とテキストの配置';

  @override
  String get informationClockLeft => '時計が左、テキストが右';

  @override
  String get informationClockRight => 'テキストが左、時計が右';

  @override
  String get informationSpacing => '時計とテキストの間隔';

  @override
  String get informationBackground => 'ブロックの背景';

  @override
  String get homeResetTilesHint => 'この画面のすべてのタイルとラベルを共通の値に戻しますか？';

  @override
  String get homeResetLayoutHint =>
      'このセクションのレイアウト、共通の外観、内側の余白をリセットしますか？アプリとその順序は保持されます。';

  @override
  String get networkSummary => 'ネットワーク';

  @override
  String get networkConnected => 'インターネット利用可能';

  @override
  String get networkOffline => 'インターネットにアクセスできません';

  @override
  String get networkDisconnected => '未接続';

  @override
  String get networkConnection => '接続';

  @override
  String get networkSignal => '信号';

  @override
  String get networkLinkSpeed => 'Wi-Fi リンク速度';

  @override
  String get networkTrafficRate => '端末の通信量 · 受信 / 送信';

  @override
  String get networkSystemSettings => 'システムのネットワーク設定';

  @override
  String get networkUnavailable => '利用不可';

  @override
  String get networkMobile => 'モバイルネットワーク';

  @override
  String get networkFrequency => '周波数';

  @override
  String get networkMbps => 'Mbps';

  @override
  String get networkKbps => 'KB/秒';

  @override
  String get networkReadFailed => 'ネットワーク状態を取得できません';

  @override
  String get clockItalic => '斜体';

  @override
  String get panelWrapNavigation => 'パネルの循環ナビゲーション';

  @override
  String get panelWrapNavigationHelp =>
      '端のボタンから左右キーで反対側へ移動します。キーを押し続けると両側を連続して移動できます。';

  @override
  String get networkReceive => '受信';

  @override
  String get networkSend => '送信';

  @override
  String get landscapeCelestialBodies => '太陽と月';

  @override
  String get landscapeStarRotation => '星の回転';

  @override
  String get tvPowerTitle => '電源管理';

  @override
  String get tvPowerOff => 'テレビをオフ';

  @override
  String get tvPowerReboot => 'テレビを再起動';

  @override
  String get tvPowerOffConfirm => 'テレビをスタンバイにしますか？';

  @override
  String get tvPowerRebootConfirm => '再起動しますか？開いているアプリは終了します。';

  @override
  String get tvPowerSent => 'コマンドを送信しました';

  @override
  String get tvPowerFailed => '送信できません。ADB またはユーザー補助を確認してください。';

  @override
  String get tvPowerHelp =>
      'オフは CuteLauncher のユーザー補助サービスまたはローカル ADB でスタンバイにします。再起動には ADB が必要です。TV ボックスではボックスを操作します。テレビの動作は HDMI-CEC とファームウェアに依存します。';

  @override
  String get cleanerLists => '無効化リスト';

  @override
  String get cleanerRecovery => 'バックアップと復元';

  @override
  String get cleanerExports => 'レポート';

  @override
  String get cleanerUpdating => 'アプリ一覧を更新しています…';

  @override
  String get cleanerRefreshRequired => '最初にアプリ一覧を更新してください。';

  @override
  String get cleanerPreinstalled => 'プリインストールアプリ';

  @override
  String get cleanerNotSystem => 'システムアプリではありません。';

  @override
  String get cleanerMinimalRisk => '最小';

  @override
  String get cleanerCacheFailure => '次回表示する一覧を保存できませんでした。';

  @override
  String get cleanerUserApps => 'ユーザーアプリ';

  @override
  String get cleanerPreinstalledApps => 'プリインストールアプリ';

  @override
  String get cleanerSystemApps => 'システムアプリ';

  @override
  String get cleanerBaseline => '基準の初期状態';

  @override
  String get cleanerManualStates => '手動保存した状態の管理';

  @override
  String get cleanerManualSave => '現在の状態を保存';

  @override
  String get cleanerDateName => '日時を使用';

  @override
  String get cleanerCustomName => '名前を入力';

  @override
  String get cleanerStateExport => '保存した状態をファイルに出力';

  @override
  String get cleanerStateRestoreHelp =>
      'このファームウェアで保存したアプリの有効・無効状態を復元します。保存後にインストールしたアプリは変更しません。存在しないアプリと保護されたコンポーネントの無効化はスキップします。アプリのデータは復元しません。';

  @override
  String get cleanerCopiesHelp =>
      '基準状態は最初の一覧更新成功時に一度だけ作成され、ランチャーから削除・上書きできません。ファームウェアに紐付きます。手動状態は現在のアプリ状態を名前と日時付きで保存し、復元・削除・出力できます。APKやアプリのデータは含みません。復元にはローカルADBが必要です。クラッシュループ保護が作動すると基準状態の自動復元を試みます。ランチャーのデータ消去やアンインストールで保存状態も削除されます。rootアクセスは防止できません。';

  @override
  String get cleanerSearch => '名前で検索';

  @override
  String get cleanerCatalogUpdateRequired => '最初にGitHubからカタログを更新してください。';

  @override
  String get cleanerNoSearchResults => '一致する項目はありません。';

  @override
  String get cleanerAlreadyDisabled => 'このテレビにある一覧内のアプリはすべて無効になっています。';

  @override
  String get cleanerAlreadyEnabled => 'このテレビにある一覧内のアプリはすべて有効になっています。';

  @override
  String get cleanerNoInstalled => 'このテレビには一覧と一致するアプリがありません。';

  @override
  String get cleanerListProtected => '残りのアプリは無効化から保護されています。';

  @override
  String get cleanerSnapshotFailed => '状態を保存できませんでした。アプリは無効化していません。';

  @override
  String get cleanerDisableAllPreinstalled => 'すべてのプリインストールアプリを無効化';

  @override
  String get cleanerEnableAllPreinstalled => 'すべてのプリインストールアプリを有効化';

  @override
  String get cleanerPreinstalledList => 'プリインストールアプリの一覧';

  @override
  String cleanerBeforeList(String listName) {
    return '一覧適用前：$listName';
  }

  @override
  String get sleepTimerSettings => 'スリープタイマー設定';

  @override
  String get sleepTimerPresets => 'タイマー';

  @override
  String get sleepTimerDisplay => 'タイマー動作中の表示';

  @override
  String get sleepTimerRemaining => '残り時間';

  @override
  String get sleepTimerEndTime => 'スリープ時刻';

  @override
  String get sleepTimerBoth => '残り時間とスリープ時刻';

  @override
  String get sleepTimerShowSeconds => '秒を表示';

  @override
  String get sleepTimerCloseAfterSelection => 'タイマー選択後にウィジェットを閉じる';

  @override
  String get sleepTimerAdd => 'タイマーを追加';

  @override
  String get sleepTimerEdit => 'タイマーを編集';

  @override
  String get sleepTimerHoursLabel => '時間';

  @override
  String get sleepTimerMinutesLabel => '分';

  @override
  String get sleepTimerSecondsLabel => '秒';

  @override
  String get sleepTimerInvalidDuration =>
      '0より長い時間を入力してください。時間は0～999999、分と秒は0～59です。';

  @override
  String get sleepTimerDeleteConfirmation => 'このタイマーを削除しますか？実行中のカウントダウンは続きます。';

  @override
  String get sleepTimerResetConfirmation =>
      '標準のタイマーと順序に戻しますか？追加したタイマーは削除されます。実行中のカウントダウンは続きます。';

  @override
  String get sleepTimerReorderHint =>
      '◄ / ► またはOK長押しで移動。▲ / ▼ で順序を変更し、表示・非表示リスト間で移動します。OKで移動を終了します。';

  @override
  String get sleepTimerSaveFailed => 'タイマー設定を保存できませんでした。';

  @override
  String get sleepTimerVisible => '表示';

  @override
  String get sleepTimerHidden => '非表示';

  @override
  String get sleepTimerReset => 'タイマーをリセット';

  @override
  String get cleanerListSnapshotHelp =>
      '一覧の無効化前に選択したアプリのみを自動保存します。復元しても他のアプリは変更しません。手動と自動の保存は合計100件までです。保存に失敗すると無効化を開始しません。';

  @override
  String get trafficSettings => '通信量の設定';

  @override
  String get trafficTitle => '通信量';

  @override
  String get trafficReceived => '受信';

  @override
  String get trafficSent => '送信';

  @override
  String get trafficTotal => '合計';

  @override
  String get stopApp => '停止';

  @override
  String get backgroundImageFormats =>
      '画像：JPEG、PNG、WebP、GIF、BMP。上限8 MiB、48メガピクセル、各辺16,384ピクセル。';

  @override
  String get backgroundMediaFormats =>
      '画像：JPEG、PNG、WebP、GIF、BMP。上限8 MiB、48メガピクセル、各辺16,384ピクセル。\n動画：MP4/M4V、WebM、MKV。上限256 MiB、3840×2160。コーデックの対応はテレビによって異なります。H.264のMP4を推奨します。無音で繰り返し、ホーム以外では一時停止します。動画はバックアップに含まれません。';

  @override
  String get backgroundFormatError =>
      '未対応の形式、または破損したファイルです。記載された形式の正常なファイルを選んでください。';

  @override
  String backgroundFileTooLarge(String maxMiB) {
    return 'ファイルが大きすぎます。上限は$maxMiB MiBです。小さいファイルを選んでください。';
  }

  @override
  String get backgroundImageResolutionError =>
      '画像が大きすぎます。上限48メガピクセル、各辺16,384ピクセルです。';

  @override
  String get backgroundVideoResolutionError =>
      '動画の解像度が高すぎます。3840×2160（または2160×3840）以下を選んでください。';

  @override
  String get backgroundVideoCodecError =>
      'テレビで動画を再生できません。未対応のコーデック、またはファイル破損です。H.264のMP4をお試しください。';

  @override
  String get backgroundFileApplied => 'ファイルを選択し、背景を更新しました。';

  @override
  String get noticePosition => '通知の表示位置';

  @override
  String get noticeBottomRight => '右下';

  @override
  String get noticeBottomLeft => '左下';

  @override
  String get noticeTopRight => '右上';

  @override
  String get noticeTopLeft => '左上';

  @override
  String get notificationOpenFailed => '通知の操作を開けませんでした。すでに利用できなくなっている可能性があります。';

  @override
  String get adbWifiOverride => 'それでも無効にする…';

  @override
  String get adbWifiRiskTitle => 'リスクを承知で無効にしますか？';

  @override
  String get adbWifiRiskEffect => '標準ランチャーとGoogleのセットアップウィザードが無効になります。';

  @override
  String get adbWifiRiskLoss =>
      '保存済みのWi-FiネットワークがAndroidによって削除される可能性があります。Wi-Fi接続とワイヤレスADBが利用できなくなる場合があります。';

  @override
  String get adbWifiRiskRecovery =>
      '再び有効にしても削除されたネットワークは自動で復元されません。Wi-Fiに再接続してパスワードを入力する必要があります。';

  @override
  String get adbWifiRiskConsent => 'Wi-Fiのパスワードが分かる場合のみ続行してください。';

  @override
  String get adbWifiDisable => '無効にする';

  @override
  String get recentAppsTitle => '開いているアプリ';

  @override
  String get recentAppsPanelType => 'パネル';

  @override
  String get recentAppsAutomatic => '自動';

  @override
  String get recentAppsCustom => 'CuteLauncherパネル';

  @override
  String get recentAppsSystem => '内蔵パネル';

  @override
  String get recentAppsOpen => 'パネルを開く';

  @override
  String get recentAppsRefresh => '更新';

  @override
  String get recentAppsCloseAll => 'すべて閉じる';

  @override
  String get recentAppsEmpty => 'タスクが開いているTVアプリはありません';

  @override
  String get recentAppsUnavailable =>
      '開いているアプリを表示できません。ADBとユーザー補助の権限を確認してください。';

  @override
  String get recentAppsHelp =>
      'タスクが開いているTVアプリのみ表示します。「すべて閉じる」は一覧のユーザーアプリを停止します。リマッパーでボタンを割り当ててください。CuteLauncherパネルにはADBとユーザー補助の権限が必要です。';

  @override
  String get recentAppsHomeHint =>
      'Homeは長押しのみ割り当て可能です。短押しでCuteLauncherに戻ります。割り当てはランチャー外でも動作します。';

  @override
  String get sectionRulesHelp =>
      '標準セクションは名前の変更・移動・非表示にできますが、削除はできません。最低1つは表示が必要です。すべて、TV用、TV以外はアプリ名ではなく起動形式で自動分類され、非表示にすると3つの一覧から消えます。お気に入りと独自セクションは手動追加です。並び順は手動、名前、使用頻度、最終起動から選択し、外観は個別設定できます。視聴を続けるはアプリのおすすめを表示し、移動・非表示にできます。';

  @override
  String get remoteMappingNamePlaceholder => 'ボタン名';

  @override
  String get remoteMappingAssign => 'ボタンを割り当て';

  @override
  String get remoteMappingCapture => '取得';

  @override
  String remoteMappingCaptured(String key) {
    return '取得したボタン：$key';
  }

  @override
  String get remoteMappingCaptureHint =>
      '「取得」を選んでリモコンのボタンを押してください。再取得できます。OK で確定します。';

  @override
  String get remoteMappingCaptureTimeout => 'ボタンを取得できませんでした。再試行してください。';

  @override
  String get remoteMappingCaptureFailed => '取得できません。ユーザー補助サービスの権限を確認してください。';

  @override
  String get remoteMappingServiceRequired => 'アクセス設定でユーザー補助サービスを接続してください。';

  @override
  String get remoteMappingKeyRequired => 'ボタンが未割り当てです。「ボタンを割り当て」で取得してください。';

  @override
  String get remoteMappingHomeHoldRequired => 'Home には長押しを選んでください。';

  @override
  String get remoteMappingAppRequired => '起動するアプリを選んでください。';

  @override
  String get remoteMappingUrlRequired => 'Webhook URL を入力または読み込んでください。';

  @override
  String get remoteMappingUrlInvalid =>
      'URL が無効です。パス付きの HTTPS またはローカル HTTP を使い、空白・認証情報・# フラグメントを含めないでください。';

  @override
  String get remoteMappingSaveFailed => '保存できませんでした。再試行してください。編集内容は保持されます。';

  @override
  String get remoteMappingDeleteFailed => '削除できませんでした。再試行してください。';

  @override
  String get remoteMappingRecents => '起動中アプリパネル';

  @override
  String get remoteMappingImport => 'ファイルから URL を読み込む';

  @override
  String get remoteMappingImportHint =>
      'Webhook URL のみを含む UTF-8 テキストファイルを選んでください。コマンドや説明は含めないでください。改行は削除されます。';

  @override
  String get remoteMappingImportInvalid =>
      'ファイルには有効な Webhook URL のみを含めてください。HTTPS またはローカル HTTP を使い、コマンドや説明は含めないでください。';

  @override
  String get remoteMappingImportFailed =>
      '読めませんでした。アクセス可能な 64 KB 以下の UTF-8 テキストファイルを選んでください。';
}
