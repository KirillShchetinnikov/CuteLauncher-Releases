// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

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
  String get adbWifiOwnedTitle => 'Wi-Fi가 설정 마법사에 속함';

  @override
  String get adbWifiOwned =>
      '변경하지 않았습니다. 저장된 Wi-Fi 네트워크를 Google 설정 마법사가 만들었습니다. 마법사를 사용 중지하면 네트워크가 삭제되어 TV 연결이 끊길 수 있습니다.\n\n1. Wi-Fi 비밀번호를 알고 있는지 확인하세요.\n2. Android 네트워크 설정에서 해당 네트워크를 선택하고 네트워크 삭제를 누르세요.\n3. 일반 Android 네트워크 설정에서 다시 연결하세요.\n4. CuteLauncher로 돌아와 ADB를 확인하고 기본 런처 사용 중지를 다시 시도하세요.\n\n메시지가 다시 나타나면 기본 런처를 켜 두세요. 펌웨어가 네트워크 소유자를 다시 마법사로 지정할 수 있습니다.';

  @override
  String get adbWifiUnknown =>
      'Not changed: the owners of saved Wi-Fi networks could not be verified. Disabling the setup wizard is blocked to protect your connection. Check ADB and try again; some firmware does not provide this information.';

  @override
  String get backgroundSource => '배경 소스';

  @override
  String get noAvailableCategories => '이 앱을 추가할 수 있는 섹션이 없습니다.';

  @override
  String get redditWallpaperTheme => '배경화면 테마';

  @override
  String get redditThemeAll => '혼합';

  @override
  String get redditThemeNature => '자연';

  @override
  String get redditThemeSpace => '공간';

  @override
  String get redditThemeCity => '도시';

  @override
  String get redditThemeMinimal => '미니멀리즘';

  @override
  String get redditWallpaperResolution => '최소 해상도';

  @override
  String get redditWallpaperHint =>
      '새로 고침이 성공할 때마다 선택한 Reddit 커뮤니티에서 다른 가로 이미지가 다운로드됩니다. 해상도는 최소 원본 크기입니다. 이미지는 확대되지 않습니다. 새로 고침은 실행기가 열려 있는 동안 실행되고 다시 시작되면 다시 시작됩니다. 성인용 콘텐츠, 비디오, 갤러리는 건너뜁니다. Reddit가 액세스를 차단하거나 일치하는 이미지를 찾을 수 없는 경우 이전 배경화면이 유지됩니다.';

  @override
  String get dialogCommandDetails => 'ADB 명령 표시';

  @override
  String get dialogAssign => '할당';

  @override
  String get dialogApply => '적용';

  @override
  String get settingsValueNotSet => '설정되지 않음';

  @override
  String get settingsMenuPosition => '설정 메뉴 위치';

  @override
  String get settingsMenuLeft => '왼쪽';

  @override
  String get settingsMenuRight => '오른쪽';

  @override
  String get actionCompleted => '작업 완료';

  @override
  String get showRepositoryQrCode => 'QR 코드 표시';

  @override
  String get resetSections => '섹션 설정 재설정';

  @override
  String get resetSectionsConfirmation =>
      '기본 섹션을 복원하시겠습니까? 사용자 정의 섹션, 공백 및 즐겨찾기 콘텐츠가 제거됩니다.';

  @override
  String get cardFocusMode => '귀국에 집중';

  @override
  String get cardFocusRemember => '선택한 카드 유지';

  @override
  String get cardFocusFirst => '첫 번째 카드';

  @override
  String get cardFocusSettings => '설정 버튼';

  @override
  String get aboutFlauncher => 'CuteLauncher 정보';

  @override
  String get addCategory => '카테고리 추가';

  @override
  String get addSection => '섹션 추가';

  @override
  String get alphabetical => '알파벳순';

  @override
  String get appCardHighlightAnimation => '앱 카드 하이라이트 애니메이션';

  @override
  String get appInfo => '앱 정보';

  @override
  String get appKeyClick => '키 누름 시 클릭 소리';

  @override
  String get applications => '애플리케이션';

  @override
  String get autoHideAppBar => '상태 표시줄 자동 숨기기';

  @override
  String get backButtonAction => '뒤로 버튼 동작';

  @override
  String get category => '카테고리';

  @override
  String get categories => '카테고리';

  @override
  String get columnCount => '열 수';

  @override
  String get date => '날짜';

  @override
  String get dateAndTimeFormat => '날짜 및 시간 형식';

  @override
  String get delete => '삭제';

  @override
  String get dialogOptionBackButtonActionDoNothing => '아무 작업 안 함';

  @override
  String get dialogOptionBackButtonActionShowScreensaver => '화면 보호기 표시';

  @override
  String get dialogOptionBackButtonActionShowClock => '시계 표시';

  @override
  String get dialogTextNoFileExplorer => '사진을 선택하려면 파일 탐색기를 설치하세요.';

  @override
  String get dialogTitleBackButtonAction => '뒤로 버튼 동작 선택';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (카테고리)';
  }

  @override
  String formattedDate(String dateString) {
    return '포맷된 날짜: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return '포맷된 시간: $timeString';
  }

  @override
  String get gradient => '그라데이션';

  @override
  String get favoriteApps => '즐겨찾는 앱';

  @override
  String get grid => '그리드';

  @override
  String get height => '높이';

  @override
  String get hide => '숨기기';

  @override
  String get hiddenApplications => '숨겨진 앱';

  @override
  String get launcherSections => '섹션';

  @override
  String get layout => '레이아웃';

  @override
  String get loading => '로딩 중';

  @override
  String get manual => '수동';

  @override
  String get modifySection => '섹션 수정';

  @override
  String get mustNotBeEmpty => '비워둘 수 없습니다';

  @override
  String get name => '이름';

  @override
  String get newSection => '새 섹션';

  @override
  String get noDateFormatSpecified => '날짜 형식이 지정되지 않음';

  @override
  String get noTimeFormatSpecified => '시간 형식이 지정되지 않음';

  @override
  String get nonTvApplications => '비 TV 앱';

  @override
  String get open => '열기';

  @override
  String get orSelectFormatSpecifiers => '또는 형식 지정자 선택';

  @override
  String get openImage => '파일 선택';

  @override
  String get picture => '로컬 이미지 또는 동영상';

  @override
  String removeFrom(String name) {
    return '$name에서 제거';
  }

  @override
  String get renameCategory => '카테고리 이름 변경';

  @override
  String get reorder => '재정렬';

  @override
  String get row => '행';

  @override
  String get rowHeight => '행 높이';

  @override
  String get save => '저장';

  @override
  String get spacer => '간격';

  @override
  String get spacerMaxHeightRequirement => '0보다 크고 500 이하여야 합니다';

  @override
  String get statusBar => '상태 표시줄';

  @override
  String get settings => '설정';

  @override
  String get show => '표시';

  @override
  String get showCategoryTitles => '카테고리 제목 표시';

  @override
  String get themes => '테마';

  @override
  String get hideHighlightOutlineOnHomescreen => '홈 화면에서 하이라이트 윤곽선 숨기기';

  @override
  String get appSelectorTransitionAnimation => '앱 선택기 전환 애니메이션';

  @override
  String get sort => '정렬';

  @override
  String get systemSettings => '시스템 설정';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => '이 카테고리는 비어 있습니다.';

  @override
  String get time => '시간';

  @override
  String get titleStatusBarSettingsPage => '상태 표시줄에 표시할 내용 선택';

  @override
  String get tvApplications => 'TV 앱';

  @override
  String get type => '유형';

  @override
  String get typeInTheDateFormat => '날짜 형식 입력';

  @override
  String get typeInTheHourFormat => '시간 형식 입력';

  @override
  String get uninstall => '제거';

  @override
  String get wallpaper => '배경화면';

  @override
  String get withEllipsisAddTo => '추가...';

  @override
  String get timeBasedWallpaper => '낮/밤 이미지';

  @override
  String get pickDayWallpaper => '낮 이미지 선택';

  @override
  String get pickNightWallpaper => '밤 이미지 선택';

  @override
  String get accessibility => '접근성';

  @override
  String get defaultLauncherIsDefault => 'CuteLauncher가 기본 런처입니다';

  @override
  String get defaultLauncherNotDefault => 'CuteLauncher가 기본 런처가 아닙니다';

  @override
  String get setAsDefaultLauncher => '기본 런처로 설정';

  @override
  String get defaultLauncherDescription =>
      '기본 런처로 설정하면 홈 버튼은 항상 CuteLauncher로 돌아갑니다. TV도 직접 CuteLauncher로 부팅됩니다.';

  @override
  String get inputs => '입력';

  @override
  String get inputsUnavailableHint =>
      '이 장치는 사용 가능한 입력을 제공하지 않습니다. 스위치가 비활성화되고 아이콘이 숨겨집니다. TV 상자에서 이 옵션은 연결된 TV의 HDMI 입력을 제어하지 않습니다.';

  @override
  String get inputSources => '입력 소스';

  @override
  String get backupAndRestore => '백업 및 복원';

  @override
  String get exportBackup => '백업 내보내기';

  @override
  String get importBackup => '백업 가져오기';

  @override
  String exportSuccess(String path) {
    return '백업이 $path로 성공적으로 내보내졌습니다';
  }

  @override
  String get importSuccess => '백업을 성공적으로 가져왔습니다';

  @override
  String get importConfirm => '백업을 가져오시겠습니까? 현재 설정 및 레이아웃을 덮어씁니다.';

  @override
  String get importError => '백업에서 설정을 복원할 수 없습니다. 파일을 확인하고 다시 시도해 보세요.';

  @override
  String exportError(String error) {
    return '백업 내보내기 실패: $error';
  }

  @override
  String get shareBackup => '백업 공유';

  @override
  String get shareBackupDescription => '로컬 네트워크의 다른 기기와 백업 공유';

  @override
  String get stopSharing => '공유 중지';

  @override
  String get localNetworkSharingActive => '로컬 네트워크 공유가 활성화되었습니다!';

  @override
  String get localNetworkSharingInstructions =>
      '다른 기기를 동일한 Wi-Fi 네트워크에 연결하고 웹 브라우저에서 다음 URL을 엽니다.';

  @override
  String get localNetworkSharingDetails =>
      '여기에서 TV 설정/레이아웃을 다운로드하거나 이 TV로 백업 파일을 업로드할 수 있습니다.';

  @override
  String failedToStartServer(String error) {
    return '공유 서버 시작 실패: $error';
  }

  @override
  String get notificationBell => '알림 벨';

  @override
  String get autoHideNotificationBell => '알림 벨 자동 숨기기';

  @override
  String get continueWatching => '계속 시청';

  @override
  String get showContinueWatchingOnHome => '홈에서 계속 시청 표시';

  @override
  String get permissionDeniedContinueWatching => '계속 시청을 표시하려면 권한이 필요합니다';

  @override
  String get interface => '인터페이스';

  @override
  String get system => '시스템';

  @override
  String get accentColor => '강조 색상';

  @override
  String get miscellaneous => '기타';

  @override
  String get brightnessScheduler => '밝기 스케줄러';

  @override
  String get screensaverSettings => '화면 보호기 설정';

  @override
  String get screensaverClockStyle => '화면 보호기 시계 스타일';

  @override
  String get dataUsagePeriod => '데이터 사용 기간';

  @override
  String get notificationAccess => '알림 액세스';

  @override
  String get granted => '부여됨';

  @override
  String get permissionRequired => '권한 필요';

  @override
  String get systemWidePopupAlert => '시스템 전체 팝업 알림';

  @override
  String get overlayPermissionRequired => '오버레이 권한 필요';

  @override
  String get enabled => '사용 설정됨';

  @override
  String get disabled => '사용 중지됨';

  @override
  String get showAppNamesBelowIcons => '아이콘 아래에 앱 이름 표시';

  @override
  String get dataUsage => '데이터 사용량';

  @override
  String get networkIndicator => '네트워크 표시기';

  @override
  String get homeButtonFix => '홈 버튼 수정 (Google TV)';

  @override
  String get startOnBoot => '부팅 시 시작 (Google TV / Fire TV)';

  @override
  String get appLanguage => '언어';

  @override
  String get systemDefault => '시스템 기본값';

  @override
  String get english => '영어';

  @override
  String get spanish => '스페인어';

  @override
  String get ukrainian => '우크라이나어';

  @override
  String get chinese => '중국어';

  @override
  String get french => '프랑스어';

  @override
  String get german => '독일어';

  @override
  String get japanese => '일본어';

  @override
  String get portuguese => '포르투갈어';

  @override
  String get russian => '러시아어';

  @override
  String get italian => '이탈리아어';

  @override
  String get hindi => '힌디어';

  @override
  String get korean => '한국어';

  @override
  String get arabic => '아랍어';

  @override
  String get turkish => '터키어';

  @override
  String get hidePersistentNotifications => '고정 알림 숨기기';

  @override
  String get hidePersistentNotificationsDesc => '백그라운드 서비스 및 시스템 고정 알림 숨기기';

  @override
  String get blockedNotificationApps => '차단된 앱';

  @override
  String get blockAppNotifications => '알림 차단';

  @override
  String get unblockAppNotifications => '알림 차단 해제';

  @override
  String get noBlockedApps => '차단된 앱이 없습니다';

  @override
  String get persistentNotification => '고정';

  @override
  String get unblockAll => '모두 차단 해제';

  @override
  String get weather => '날씨';

  @override
  String get showWeatherWarnings => '날씨 및 강우 경보 표시';

  @override
  String get temperatureUnit => '온도 단위';

  @override
  String get celsius => '섭씨 (°C)';

  @override
  String get fahrenheit => '화씨 (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Breezy Weather를 설치하고 설정에서 \'로컬 데이터 공유\' / \'Gadgetbridge\'를 활성화하면 날씨 및 강우 경보가 표시됩니다.';

  @override
  String get displayAndScreensaver => '디스플레이 및 화면 보호기';

  @override
  String get notifications => '알림';

  @override
  String get continueWatchingDescription => '홈 화면에 최근 시청한 영화 및 TV 프로그램 표시';

  @override
  String get continueWatchingPermissionDesc =>
      'TV 앱의 시청 기록을 읽으려면 특별한 권한이 필요합니다:';

  @override
  String get requestPermission => '권한 요청';

  @override
  String get dismiss => '닫기';

  @override
  String get openApp => '열기';

  @override
  String get notificationOptions => '알림 옵션';

  @override
  String get noBlockedAppsDesc => '현재 모든 애플리케이션의 알림 표시가 허용되어 있습니다';

  @override
  String get notificationsAllowed => '알림 허용됨';

  @override
  String get notificationsBlocked => '알림 차단됨';

  @override
  String get dpadDismissHint => '왼쪽: 닫기 • 확인: 옵션';

  @override
  String get watchNextDeleteError => '계속 시청에서 항목을 삭제할 수 없습니다. 다시 시도해 보세요.';

  @override
  String get hideLauncherTile => '앱 그리드에서 CuteLauncher 숨기기';

  @override
  String get hideAndroidSettingsTile => '앱 타일에서 Android 설정 숨기기';

  @override
  String get animateTileReordering => '타일 재정렬 애니메이션';

  @override
  String get imageInputRejected =>
      '이미지가 손상되었거나 너무 큽니다(최대 8 MiB 및 48 메가픽셀). 다른 이미지를 선택하세요.';

  @override
  String get memoryTitle => '메모리';

  @override
  String get memoryRefresh => '메모리 측정';

  @override
  String get memoryMeasuring => '측정 중…';

  @override
  String get memoryClear => '이미지 캐시 지우기';

  @override
  String get memorySaver => '메모리 절약';

  @override
  String get memorySaverDescription =>
      '메모리 절약 모드:\n\n• 이미지 캐시와 포스터 사전 로드 창을 줄입니다.\n• 타일, 패널, 배경 화면 배경 흐림 및 윤곽선 펄스를 비활성화합니다.\n• 초점이 맞지 않는 타일의 그림자를 제한합니다.\n• 앱이 백그라운드로 전환되면 캐시를 지웁니다.\n\n메모리 절약이 활성화된 동안에는 이러한 효과를 설정에서 사용할 수 없습니다. 모드가 비활성화되면 저장된 값이 반환됩니다. 이미지가 더 자주 다시 로드될 수 있습니다.';

  @override
  String get memoryPss => '프로세스 공유(PSS)';

  @override
  String get memoryRss => '상주 프로세스 메모리(RSS)';

  @override
  String get memoryEncodedCache => '캐시된 이미지 파일';

  @override
  String get memoryDecodedCache => '캐시된 디코딩된 이미지';

  @override
  String get memoryUnavailable => '이용 불가';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => '측정 시간';

  @override
  String get memoryExplanation =>
      'PSS 및 RSS 겹침: 함께 추가하지 마십시오. 캐시 크기는 앱 메모리의 일부이며 활성 이미지가 보유한 모든 메모리를 설명하지는 않습니다. 캐시를 지우면 설정과 파일이 유지됩니다. 필요할 때 이미지가 다시 로드됩니다. Android는 나중에 메모리를 반환할 수 있습니다. RSS는 커널에서, PSS는 Android에서 나왔습니다. 그래픽 메모리를 다르게 설명할 수 있습니다.';

  @override
  String get memoryRecommendations =>
      '메모리를 줄이려면 저장을 활성화하고 카드를 더 적게 표시하고 계속해서 카드를 보고 더 작은 배경화면이나 그라데이션을 사용하세요.';

  @override
  String get memoryMeasurementFailed => '프로세스 측정을 사용할 수 없습니다. 캐시 정보는 계속 표시됩니다.';

  @override
  String get addToCategory => '카테고리에 추가';

  @override
  String get addToFavorites => '즐겨찾기에 추가';

  @override
  String get removeFromFavorites => '즐겨찾기에서 삭제';

  @override
  String get setCustomBanner => '맞춤 배너 설정';

  @override
  String get clearCustomBanner => '맞춤 배너 지우기';

  @override
  String get bannerSetFailed =>
      '배너를 설정할 수 없습니다. 이미지에 대한 접근 권한을 확인하고 파일을 다시 선택하세요.';

  @override
  String get bannerClearFailed => '맞춤 배너를 삭제할 수 없습니다. 다시 시도해 보세요.';

  @override
  String get grantUsagePermission => '사용 권한 부여';

  @override
  String get removeFromContinueWatching => '계속 시청에서 삭제';

  @override
  String hideAllFromApp(String appName) {
    return '$appName에서 모두 숨기기';
  }

  @override
  String get playResume => '재생 / 재개';

  @override
  String openNamedApp(String appName) {
    return '$appName 열기';
  }

  @override
  String get selectedAccent => '선택한 악센트';

  @override
  String get homeButtonFixHint =>
      'Google TV를 사용하는 경우 접근성 설정에서 \"홈 버튼 수정\"을 활성화하여 홈 버튼으로 이 런처를 열 수 있습니다.';

  @override
  String get accessibilityPermission => '접근성 권한';

  @override
  String get shareFailed => '공유 실패';

  @override
  String shareBackupError(String error) {
    return '백업 공유 실패: $error';
  }

  @override
  String get exportComplete => '수출 성공';

  @override
  String get exportFailed => '백업을 저장할 수 없습니다. 폴더 액세스 및 사용 가능한 저장 공간을 확인하세요.';

  @override
  String backupLoadError(String error) {
    return '백업 로드 중 오류 발생: $error';
  }

  @override
  String get noBackupFiles => '백업 파일을 찾을 수 없습니다.';

  @override
  String get importComplete => '가져오기 성공';

  @override
  String get importFailed => '가져오기 실패';

  @override
  String get importAction => '가져오기';

  @override
  String get continueWatchingApps => '계속해서 앱 시청하기';

  @override
  String get blockedContinueWatching => '계속 시청이 차단됨';

  @override
  String get allAppsCanContinueWatching => '지원되는 모든 앱은 계속 시청에 항목을 표시할 수 있습니다.';

  @override
  String get unblockApp => '차단 해제';

  @override
  String get unblockAllApps => '모든 앱 차단 해제';

  @override
  String get appsWithContinueWatching => '계속해서 시청할 수 있는 앱';

  @override
  String get watchNextAppsHint => '현재 홈 화면에 다음 볼만한 동영상 항목을 제공하는 앱';

  @override
  String get noWatchNextApps =>
      '현재 계속 시청 항목을 제공하는 앱이 없습니다.\n지원되는 앱(예: SmartTube 또는 스트리밍 서비스)이 항목을 추가하면 여기에 표시됩니다.';

  @override
  String get allInstalledApps => '설치된 모든 앱';

  @override
  String get blockWatchNextHint => '앱이 계속 시청에 항목을 추가하지 못하도록 차단하려면 끄세요.';

  @override
  String get cardSize => '카드 크기';

  @override
  String get maximumItems => '최대 품목';

  @override
  String get playbackProgressBar => '재생 진행률 표시줄';

  @override
  String get playbackPercentage => '재생 비율';

  @override
  String get episodeVideoDetails => '에피소드 및 동영상 세부정보';

  @override
  String get restoreHiddenPrograms => '숨겨진 프로그램 복원';

  @override
  String get allHiddenProgramsRestored => '모든 숨겨진 프로그램이 복원되었습니다.';

  @override
  String get watchNextAccessAdb => '다음 시청 액세스(ADB 필요)';

  @override
  String get supportLtvLauncher => 'LTvLauncher 지원';

  @override
  String get scanToDonate => '기부하려면 휴대폰 카메라로 스캔하세요.';

  @override
  String get openInBrowser => '브라우저에서 열기';

  @override
  String get close => '닫기';

  @override
  String get launcherAuthor => 'CuteLauncher 으로 Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Android TV 런처는 LeanBitLab의 LTvLauncher 및 Étienne Fesser의 FLauncher를 기반으로 합니다. GNU GPLv3에 따라 라이센스가 부여되었습니다.';

  @override
  String get projectCredits => '프로젝트 및 크레딧';

  @override
  String get launcherRepository => 'CuteLauncher 리포지토리';

  @override
  String get originalProject => '원본 프로젝트: LTvLauncher';

  @override
  String get noInputsDetected => '감지된 입력이 없습니다.';

  @override
  String get reorderSectionsHint =>
      '¼ / ►로 선택한 후 ▲ / ▼로 순서를 변경하세요. 섹션을 숨기거나 표시하려면 목록 경계를 넘습니다.';

  @override
  String get customName => '맞춤 이름';

  @override
  String get mostUsed => '발사 빈도';

  @override
  String get lastUsed => '마지막으로 사용됨';

  @override
  String get clearAll => '모두 지우기';

  @override
  String get allCaughtUp => '모두 따라잡았어!';

  @override
  String get notificationAccessAdb => '알림 액세스(ADB 필요)';

  @override
  String get openAppInfo => '앱 정보 열기';

  @override
  String get overlayPermission => '오버레이 권한';

  @override
  String get clockMinimal => '최소';

  @override
  String get clockMinimalDescription => '얇고 우아한 글꼴(기본값)';

  @override
  String get clockBold => '굵게';

  @override
  String get clockBoldDescription => '두껍고 눈에 잘 띄는 글꼴';

  @override
  String get clockRetro => '레트로';

  @override
  String get clockRetroDescription => '고정 폭, 복고풍 터미널 스타일';

  @override
  String get clockElegant => '우아함';

  @override
  String get clockElegantDescription => '클래식 세리프 서체';

  @override
  String get clockNeon => '네온';

  @override
  String get clockNeonDescription => '매우 얇고 빛나는 스타일';

  @override
  String get clockPixel => '픽셀';

  @override
  String get clockPixelDescription => '대담한 고정폭, 아케이드 느낌';

  @override
  String get clockDigital => '디지털';

  @override
  String get clockDigitalDescription => '고정 폭 디스플레이 청소';

  @override
  String get themeDefault => '기본값';

  @override
  String get themePremium => '프리미엄';

  @override
  String get themeClassic => '클래식';

  @override
  String get themeCapsule => '캡슐';

  @override
  String get cancel => '취소';

  @override
  String get actionCancelled => '작업이 취소되었습니다.';

  @override
  String get ok => '알았어';

  @override
  String get accessibilityGuide =>
      'TV 설정을 수동으로 연 다음 접근성 → CuteLauncher 홈 버튼 수정을 실행하고 서비스를 활성화하세요. 이 메뉴의 위치와 이름은 TV 제조업체에 따라 다릅니다.';

  @override
  String get notificationPermissionGuide =>
      '이 TV에서는 알림 액세스 설정을 열 수 없습니다. 앱 정보에서 발신 알림을 허용해도 다른 앱의 알림에 대한 액세스 권한은 부여되지 않습니다.\n\nADB를 통해 TV를 연결하고 다음을 실행하세요.';

  @override
  String get overlayPermissionGuide =>
      '오버레이 권한 설정을 자동으로 열 수 없습니다.\n\n다른 앱 위에 팝업을 활성화하려면 ADB를 통해 TV를 연결하고 다음을 실행하세요.';

  @override
  String get watchNextPermissionGuide =>
      '다른 앱에서 계속 시청 카드를 읽으려면 Android TV에 READ_WRITE_WATCH_NEXT_PROGRAMS가 필요합니다.\n\nADB를 통해 TV를 연결하고 다음을 실행하세요.';

  @override
  String get watchNextAccess => '계속 시청 액세스';

  @override
  String itemsCount(int count) {
    return '$count 항목';
  }

  @override
  String displayUpToItems(int count) {
    return '$count 최근 항목까지 표시';
  }

  @override
  String get unlimitedItems => '무제한';

  @override
  String get allAvailableItems => '사용 가능한 모든 항목 표시';

  @override
  String get defaultOption => '기본값';

  @override
  String get manage => '관리하다';

  @override
  String blockedCount(int count) {
    return '$count가 차단됨';
  }

  @override
  String hiddenCount(int count) {
    return '$count 숨겨진';
  }

  @override
  String blockedWatchNextCount(int count) {
    return '계속 시청이 차단됨($count)';
  }

  @override
  String get sizeExtraSmall => '아주 작은';

  @override
  String get sizeVerySmall => '매우 작음';

  @override
  String get sizeSmall => '작은';

  @override
  String get sizeCompact => '콤팩트';

  @override
  String get sizeMediumSmall => '중소형';

  @override
  String get sizeMedium => '중간';

  @override
  String get sizeStandardDefault => '표준(기본값)';

  @override
  String get sizeMediumLarge => '중대형';

  @override
  String get sizeLarge => '대형';

  @override
  String get sizeVeryLarge => '매우 큼';

  @override
  String get sizeExtraLarge => '특대형';

  @override
  String get sizeHuge => '거대한';

  @override
  String get tvApps => 'TV 앱';

  @override
  String get nonTvApps => 'TV 이외의 앱';

  @override
  String get moviesShows => '영화 및 프로그램';

  @override
  String get music => '음악';

  @override
  String get games => '게임';

  @override
  String get entertainment => '엔터테인먼트';

  @override
  String get liveTv => '라이브 TV';

  @override
  String get sports => '스포츠';

  @override
  String get news => '뉴스';

  @override
  String get tools => '도구';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get customSectionName => '맞춤...';

  @override
  String get selectSectionName => '이름을 선택하세요';

  @override
  String get weeklyUsage => '주간:';

  @override
  String get monthlyUsage => '월간:';

  @override
  String get dailyUsage => '매일:';

  @override
  String get appError => '문제가 발생했습니다.';

  @override
  String get weatherRain => '비';

  @override
  String get weatherSnow => '눈';

  @override
  String get weatherStorm => '폭풍';

  @override
  String get weatherToday => '오늘';

  @override
  String get weatherTomorrow => '내일';

  @override
  String weatherOnDay(String day) {
    return '$day에서';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'CuteLauncher 백업';

  @override
  String get noApplicationsFound => '애플리케이션을 찾을 수 없습니다.';

  @override
  String get invalidDateFormat => '잘못된 형식';

  @override
  String get selectDateFormats => '아래에서 형식을 선택하세요.';

  @override
  String activeItemsCount(int count) {
    return '$count 활성 항목';
  }

  @override
  String get colorPurple => '보라색';

  @override
  String get colorTeal => '청록색';

  @override
  String get colorBlue => '블루';

  @override
  String get colorOrange => '오렌지';

  @override
  String get colorPink => '핑크';

  @override
  String get colorGreen => '녹색';

  @override
  String get colorWhite => '화이트';

  @override
  String get colorYellow => '노란색';

  @override
  String get colorRed => '빨간색';

  @override
  String get colorCyan => '청록색';

  @override
  String get colorIndigo => '인디고';

  @override
  String get colorLime => '라임';

  @override
  String get colorAmber => '호박색';

  @override
  String get colorRose => '로즈';

  @override
  String get colorIceBlue => '아이스 블루';

  @override
  String get memoryFeatures => '기능별 메모리(캐시)';

  @override
  String get memoryAppIcons => '앱 아이콘';

  @override
  String get memoryAppBanners => '앱 배너';

  @override
  String get memoryWatchNextPosters => '계속해서 포스터를 시청하세요';

  @override
  String get memoryOtherCaches => '기타 인코딩된 이미지 캐시';

  @override
  String get memoryFeaturesExplanation =>
      '이는 인코딩된 캐시 총계에 이미 포함된 보유 이미지 바이트입니다. 0은 해당 캐시에 보존된 바이트가 없음을 의미하지만 해당 기능이 메모리를 사용하지 않는다는 의미는 아닙니다. 배경화면과 표시된 이미지는 위의 디코딩된 캐시를 공유합니다. 활성 이미지가 외부에 있을 수 있습니다. 날씨, 알림, Dart 개체 및 엔진은 여기에서 기능별로 분할될 수 없습니다. 공유 인터페이스 그래픽은 위에서 Android에 의해 보고되었으며 이미 PSS에 포함되어 있습니다. 그들의 기억은 프로세스 전체의 일부입니다. 이렇게 겹치는 값을 추가하지 마세요.';

  @override
  String get memoryGraphics => '인터페이스 그래픽(PSS에 포함)';

  @override
  String get categoryVisible => '카테고리 표시';

  @override
  String get hiddenCategories => '숨겨진 카테고리';

  @override
  String get visibleCategories => '보이는 카테고리';

  @override
  String get backupSavedToSelectedLocation => '선택한 위치에 백업이 저장되었습니다.';

  @override
  String get tileHorizontalGap => '가로 간격';

  @override
  String get tileVerticalGap => '수직 간격';

  @override
  String get tileOpacity => '배경 불투명도';

  @override
  String get tileShadow => '그림자';

  @override
  String get tileCornerRadius => '코너 라운딩';

  @override
  String get tileIconScale => '아이콘 크기';

  @override
  String get tileBackgroundColor => '타일 배경';

  @override
  String get tileLabelSize => '라벨 크기';

  @override
  String get resetAppearance => '외모 재설정';

  @override
  String get tileAppearance => '타일 외관';

  @override
  String get tileLabelColor => '라벨 색상';

  @override
  String get tilePreviewName => '샘플 애플리케이션';

  @override
  String get tileProportions => '타일 비율';

  @override
  String get tileLarge => '대형';

  @override
  String get tileLabelBelow => '타일 아래';

  @override
  String get tileLabelInside => '타일 내부';

  @override
  String get tileFocusScale => '확대';

  @override
  String get tileMedium => '중간';

  @override
  String get tileFocusBorder => '움직임 없음';

  @override
  String get tileSize => '타일 크기';

  @override
  String get tileCompact => '콤팩트';

  @override
  String get tileLabelPosition => '라벨 위치';

  @override
  String get tileFocusEffect => '집중 효과';

  @override
  String get tileFocusStrength => '하이라이트 강도';

  @override
  String get panelIndependent => '맞춤 설정';

  @override
  String get panelAppearance => '상단 패널 스타일';

  @override
  String get panelBackground => '패널 배경';

  @override
  String get blurPerformanceHint =>
      '흐림 효과는 부드러움을 감소시킬 수 있습니다. 메모리 절약이 켜져 있는 동안에는 비활성화됩니다.';

  @override
  String get panelOpacity => '패널 불투명도';

  @override
  String get tileBlur => '타일 뒤 흐림';

  @override
  String get panelBlur => '상단 패널 뒤의 흐림';

  @override
  String get panelShared => '패널처럼';

  @override
  String get weatherMinutes => '분';

  @override
  String get weatherOpenMeteoCredit =>
      '날씨: Open-Meteo(open-meteo.com), CC BY 4.0. 비상업적 용도로 무료 API를 사용하세요.';

  @override
  String get weatherRateLimit => '요청 한도에 도달했습니다. 나중에 시도해 보세요.';

  @override
  String get weatherYandexCredit =>
      '날씨: Yandex 날씨(yandex.ru/pogoda). 액세스 권한은 API 계획에 따라 다릅니다.';

  @override
  String get yandexWeather => 'Yandex 날씨(REST)';

  @override
  String get weatherAuthorizationError =>
      '날씨 제공업체가 요청을 거부했습니다. API 키를 확인하고 선택한 서비스에 접근하세요.';

  @override
  String get weatherYandexHint =>
      'REST 예측 액세스 권한이 있는 키가 필요합니다. 다른 Yandex 요금제의 키가 작동하지 않을 수 있습니다.';

  @override
  String get weatherSource => '날씨 출처';

  @override
  String get weatherInterval => '업데이트 간격';

  @override
  String get weatherLongitude => '경도(-180~180)';

  @override
  String get weatherKeyRequired => 'Yandex API 키를 추가합니다.';

  @override
  String get weatherLocationName => '도시 이름(선택사항)';

  @override
  String get weatherLocation => '위치';

  @override
  String get weatherApiKey => 'Yandex API 키';

  @override
  String get weatherInvalidResponse => '날씨 소스에서 잘못된 데이터를 반환했습니다.';

  @override
  String get weatherUnavailable =>
      '날씨를 확인할 수 없습니다. 이전에 수신된 데이터는 가능한 경우 유지됩니다. 재시도는 5분마다 한 번으로 제한됩니다.';

  @override
  String get weatherStale => '이전 날씨';

  @override
  String get weatherLatitude => '위도(-90~90)';

  @override
  String get weatherCoordinatesError => '도시를 수동으로 입력하거나 자동으로 좌표를 받으세요.';

  @override
  String get weatherRefresh => '업데이트 확인';

  @override
  String get weatherKeyPrivate => '이 기기에만 저장되며 백업에서는 제외됩니다. 빈 입력은 키를 제거합니다.';

  @override
  String get weatherUpdated => '업데이트됨';

  @override
  String get onlineWallpaperError =>
      '이 이미지를 로드할 수 없습니다. 이전 배경화면은 그대로 유지됩니다. 다운로드를 다시 시도하려면 “업데이트 확인”을 선택하십시오.';

  @override
  String get onlineWallpaperHint =>
      '마지막 이미지는 오프라인에서도 사용할 수 있도록 저장됩니다(최대 8 MiB).';

  @override
  String get onlineWallpaperHours => '시간';

  @override
  String get onlineWallpaperInterval => '다운로드 간격';

  @override
  String get onlineWallpaper => '온라인 벽지';

  @override
  String get onlineWallpaperUrlError => '로그인 정보 없이 직접 HTTPS 이미지 URL를 입력하세요.';

  @override
  String get onlineWallpaperEnabled => '온라인 배경화면 사용';

  @override
  String get onlineWallpaperSource => '이미지 출처';

  @override
  String get bingWallpaper => 'Bing 오늘의 이미지';

  @override
  String get onlineWallpaperUrlSource => '다이렉트 HTTPS URL';

  @override
  String get updatePlayOnly => '이 설치는 Google Play를 통해 업데이트를 받습니다.';

  @override
  String get updateCheck => '지금 확인하세요';

  @override
  String get updateInstalled => '설치됨';

  @override
  String get updateDownloadInstall => '다운로드 및 설치';

  @override
  String get updateNoRelease => '사용할 수 있는 최신 호환 릴리스가 없습니다.';

  @override
  String get updateIncompatible =>
      'APK는 이 애플리케이션, 인증서 또는 최신 버전과 일치하지 않습니다. 설치가 차단되었습니다.';

  @override
  String get updateError => '설치 프로그램을 확인, 다운로드 또는 열 수 없습니다. 나중에 다시 시도하세요.';

  @override
  String get updateAvailable => '업데이트 가능';

  @override
  String get appUpdates => '애플리케이션 업데이트';

  @override
  String get updatePermission =>
      'Android 설정에서 이 애플리케이션의 설치를 허용하고 여기로 돌아와 설치를 다시 누르세요.';

  @override
  String get updateInstall => '다운로드한 업데이트 설치';

  @override
  String get updateHint =>
      '출처: GitHub / KirillShchetinnikov/CuteLauncher-릴리스. 실행기가 열려 있는 동안 자동 검사가 실행됩니다. 선택하면 다운로드가 시작됩니다. Android는 설치 확인을 요청합니다. 귀하의 데이터는 보관됩니다.';

  @override
  String get updateAutomatic => '하루에 한 번씩 자동으로 확인';

  @override
  String get allApplications => '모든 애플리케이션';

  @override
  String get adbAccessibility => '홈 버튼 수정 활성화';

  @override
  String get adbAuthorization => 'TV에서 ADB 인증을 승인한 후 다시 시도하세요.';

  @override
  String get adbChangeConfirm =>
      'ADB를 통해 이 시스템 설정을 적용하시겠습니까? 이전 홈 앱은 변경하기 전에 저장됩니다. 다른 접근성 서비스는 유지됩니다.';

  @override
  String get adbCheck => '연결 확인';

  @override
  String get adbDenied => '시스템은 이 변경을 허용하거나 확인하지 않았습니다.';

  @override
  String get adbDisable => '이전 런처 비활성화';

  @override
  String get adbDisableConfirm =>
      '저장된 이전 실행기를 비활성화하시겠습니까? 현재 홈 앱이 되려면 CuteLauncher가 필요합니다. 이 설정의 복구 작업으로 복원하세요.';

  @override
  String get adbHint =>
      '이 TV 전용 프로토타입입니다(127.0.0.1). 개발자 옵션에서 TCP ADB를 활성화하고 해당 포트를 입력한 후 TV에서 인증 메시지를 승인하세요. 페어링 코드를 사용한 무선 디버깅은 아직 지원되지 않습니다. 개인 키는 백업 외부에서 이 장치에 유지됩니다.';

  @override
  String get adbHome => 'CuteLauncher를 홈 앱으로 만들기';

  @override
  String get adbInvalid => '1024에서 65535 사이의 포트를 입력하세요.';

  @override
  String get adbNoRecovery =>
      '복원을 사용할 수 없습니다. 다른 실행 프로그램이나 저장된 서비스 상태를 찾을 수 없습니다.';

  @override
  String get adbPort => 'TCP ADB 포트';

  @override
  String get adbReady => 'ADB 액세스가 확인되었습니다.';

  @override
  String get adbRestore => '이전 런처 복원';

  @override
  String get adbSuccess => '변경사항이 적용되고 확인되었습니다.';

  @override
  String get adbTitle => 'ADB 설정';

  @override
  String get adbUnavailable => '연결할 수 없습니다. TCP ADB, 포트 및 인증 프롬프트를 확인하세요.';

  @override
  String get nightModeScheduled => '이용일정';

  @override
  String get nightModeTitle => '야간 모드';

  @override
  String get nightModeScope =>
      '다른 앱을 흐리게 하려면 오버레이 권한이 필요합니다. 그것이 없으면 CuteLauncher 내부에서 디밍이 작동합니다. TCL 필터에는 오버레이 권한이 필요하지 않습니다. 80% 이상의 불투명도 Android는 다른 앱의 터치 입력을 차단할 수 있습니다. TV 리모컨 키는 여전히 작동합니다.';

  @override
  String get nightModeEnd => '끝';

  @override
  String get nightModeStart => '시작';

  @override
  String get nightModeDim => '디밍';

  @override
  String get nightModeWarmth => '따뜻한 필터';

  @override
  String get nightModeScheduleHint =>
      '지역 TV 시간을 사용합니다. 야간 기간이 지원됩니다. 시작 시간과 종료 시간이 동일하면 예약된 필터가 비활성화됩니다.';

  @override
  String get nightModeEnabled => '야간 모드 활성화';

  @override
  String get nightModePermission => '다른 앱 위에 표시 허용';

  @override
  String get nightModePermissionGranted => '다른 앱 위에 표시가 허용됨';

  @override
  String get backupDownloadsFailed => '백업을 다운로드에 저장할 수 없습니다.';

  @override
  String get backupSaveDownloads => '다운로드에 백업 저장';

  @override
  String get adbRestoreAccessibility => '접근성 액세스 복원';

  @override
  String get nightModeAdbConfirm =>
      '로컬 ADB를 사용하여 CuteLauncher가 다른 앱 위에 표시되도록 허용하시겠습니까? 먼저 TCP 디버깅을 활성화하고 연결을 승인하세요. ADB 마법사에 저장된 포트 또는 5555를 사용합니다.';

  @override
  String get nightModeAdbPermission => 'ADB를 통해 권한 부여';

  @override
  String get nightModeNotificationsHint =>
      '알림을 통해 CuteLauncher 외부에서 필터를 끌 수 있습니다. 없으면 이 메뉴를 사용하세요.';

  @override
  String get nightModeNotificationsAllowed => '야간 모드 알림이 허용됨';

  @override
  String get nightModeNotifications => '야간 모드 알림 허용';

  @override
  String get categoryLastVisibleHint => '하나 이상의 카테고리가 계속 표시되어야 합니다.';

  @override
  String get diagnosticsClear => '세션 진단 지우기';

  @override
  String get diagnosticsReady => '보고서 준비됨';

  @override
  String get diagnosticsCreate => '보고서 작성';

  @override
  String get diagnosticsOperations => '기록된 작업';

  @override
  String get diagnosticsCopied => '보고서가 복사되었습니다.';

  @override
  String get diagnosticsSharingNotice =>
      '파일을 공개하지 말고 작성자에게 개인 메시지로 보내세요. 자동 정리 후에도 개인정보가 남을 수 있습니다. 보고서를 보내면 익명화된 TV 호환성 보고서를 CuteLauncher Git 저장소에 게시하는 데 동의하는 것으로 간주합니다. 개인정보 없이 기기 정보와 기능 사용 가능 여부만 공개하며 오류 로그, 명령 및 개인 설정은 공개하지 않습니다.';

  @override
  String get diagnosticsHint =>
      '하나의 보고서에 TV 기능 호환성과 오류 진단을 함께 담습니다. 보고서에는 TV 모델과 펌웨어, 앱 버전, 권한, 메모리, 오류 단계와 원인, 개인정보를 자동 정리한 명령과 응답이 포함됩니다. 현재 세션의 최근 작업 50개, 별도로 오류 최대 100개와 제한된 ADB 로그를 보관합니다. 다시 시작하면 로그가 삭제됩니다. 개인정보가 남을 수 있으므로 공개하지 말고 개인 메시지로 보내세요. 자동 전송하지 않습니다.각 오류에는 당시 적용된 설정의 스냅샷이 저장되며 이후 변경으로 대체되지 않습니다.';

  @override
  String get diagnosticsTitle => '오류 진단';

  @override
  String get diagnosticsCopyFailed => '보고서를 복사할 수 없습니다.';

  @override
  String get diagnosticsCopy => '보고서 복사';

  @override
  String get diagnosticsCreating => '보고서 작성 중…';

  @override
  String get tclBlueLightTitle => 'TCL 블루라이트 필터';

  @override
  String get tclBlueLightError =>
      'TCL 필터 설정을 읽거나 확인할 수 없습니다. 상태를 새로 고치고 다시 시도하세요.';

  @override
  String get tclBlueLightUnsupported => '이 TV에서는 TCL 필터 인터페이스를 사용할 수 없습니다.';

  @override
  String get tclBlueLightRefresh => 'TCL 필터 상태 새로 고침';

  @override
  String get tclBlueLightHint =>
      'TV에 내장된 눈 건강 보호 필터를 제어합니다. 야간 모드 일정을 따를 수도 있습니다.';

  @override
  String get nightSolarSchedule => '일몰과 일출';

  @override
  String get nightNextStart => '다음 시작';

  @override
  String get nightScheduleTimeHint =>
      '시간은 TV 시간대를 사용합니다. 음수 오프셋이 더 빠릅니다. 양수 오프셋은 나중에 나옵니다.';

  @override
  String get nightTemperature => '필터 색온도';

  @override
  String get nightScheduleSettings => '일정 설정';

  @override
  String get nightCityName => '도시 이름';

  @override
  String get nightSkipUntilNext => '다음 일몰까지 야간 모드를 비활성화합니다.';

  @override
  String get nightSunriseOffset => '일출과 관련된 종료';

  @override
  String get nightEnableUntilMorning => '다음 해가 뜰 때까지 야간 모드를 활성화하세요.';

  @override
  String get nightPermissions => '권한';

  @override
  String get nightTclSchedule => '일정에 TCL 필터 포함';

  @override
  String get nightSearchCity => '검색';

  @override
  String get nightRefreshSun => '일출과 일몰 새로 고침';

  @override
  String get nightSolarUnavailable =>
      '도시를 선택하고 태양 시간을 새로 고칩니다. 일출이나 일몰을 이용할 수 없는 경우 태양일정이 일시 중지됩니다.';

  @override
  String get nightSunsetOffset => '일몰과 함께 시작';

  @override
  String get nightCityHint =>
      '위치 액세스 권한을 부여하는 대신 도시를 선택하세요. 선택한 좌표는 대체적으로 Sunrise-Sunset.org 또는 Open-Meteo로 전송되어 태양 시간을 검색합니다.';

  @override
  String get nightResumeSchedule => '일정으로 돌아가기';

  @override
  String get nightScheduleSource => '일정 유형';

  @override
  String get nightSolarCached => '캐시된 태양 시간 사용 인터넷 새로 고침이 자동으로 다시 시도됩니다.';

  @override
  String get nightTclScheduleHint =>
      '야간 모드가 활성화된 동안 동일한 일정을 사용합니다. TCL 필터에 대한 수동 변경은 다음 예정된 전환까지 지속됩니다. 오버레이 권한이 필요하지 않습니다.';

  @override
  String get nightRefreshPermission => '권한 상태 새로 고침';

  @override
  String get nightCityNotFound => '도시를 찾을 수 없습니다. 다른 이름을 사용해 보세요.';

  @override
  String get nightNoOffset => '오프셋 없음';

  @override
  String get nightManualSchedule => '맞춤 일정';

  @override
  String get nightChooseCity => '도시를 선택하세요';

  @override
  String get nightPermissionUnknown => '오버레이 권한 상태를 알 수 없습니다.';

  @override
  String get nightNextEnd => '다음 끝';

  @override
  String get nightTemporaryOff => '다음까지 일시적으로 밝기가 꺼집니다.';

  @override
  String get nightCitySearchFailed => '도시를 검색할 수 없습니다. 인터넷 연결을 확인하세요.';

  @override
  String get nightSolarAttribution =>
      '일일 태양 시간: Sunrise-Sunset.org; 대체: Open-Meteo. 도시 검색: GeoNames. 오프라인 사용을 위해 며칠 동안 캐시됩니다.';

  @override
  String get nightTemporaryOn => '다음까지 일시적으로 밝기가 어두워집니다.';

  @override
  String get homeScreen => '홈 화면';

  @override
  String get appearanceSettings => '외관';

  @override
  String get generalSettings => '고급';

  @override
  String get advancedSettings => '고급';

  @override
  String get controlAndStartup => '런처 및 TV 컨트롤';

  @override
  String get sectionsAndOrder => '섹션 및 순서';

  @override
  String get topPanel => '상단 패널';

  @override
  String get tileStyle => '타일 스타일';

  @override
  String get tilesAndLabels => '타일 및 라벨';

  @override
  String get highlightAndAnimation => '하이라이트 및 애니메이션';

  @override
  String get androidTvSettings => 'Android TV 설정';

  @override
  String get weatherSettings => '날씨 설정';

  @override
  String get showHighlightOutline => '하이라이트 개요 표시';

  @override
  String get resetTilesAndPanel => '타일 및 패널 설정 재설정';

  @override
  String get resetTilesAndPanelHint =>
      '추가 타일, 라벨, 강조 표시 및 상단 패널 매개변수를 재설정하시겠습니까? 배경 화면, 강조 색상, 타일 스타일 및 레이블 가시성이 유지됩니다.';

  @override
  String get panelAppearanceSettings => '상단 패널 외관';

  @override
  String get panelSharedHint => '타일 설정에서 모양을 변경하세요.';

  @override
  String get effectsCompatibilityHint =>
      '추가 모양: 윤곽선이 항상 표시되고 펄스가 발생하지 않습니다. 치수 스타일에는 기존 윤곽선이 없습니다. 클래식은 맥박이 뛰지 않습니다. 강도는 규모와 그림자에 영향을 미칩니다. 확장은 공간이 제한되어 있습니다.';

  @override
  String get sizeAndLayout => '크기 및 레이아웃';

  @override
  String get labelsGroup => '라벨';

  @override
  String get surfaceGroup => '표면';

  @override
  String get clockAndDateGroup => '시계 및 날짜';

  @override
  String get networkAndTrafficGroup => '네트워크 및 트래픽';

  @override
  String get buttonsGroup => '버튼';

  @override
  String get notificationAppsHint =>
      '알림이 필요하지 않은 앱을 끄세요. 활성화된 스위치는 알림을 허용합니다. 앱은 계속 실행될 수 있습니다.';

  @override
  String get notificationPanelLink => '상단 패널 외관';

  @override
  String get overlayAccessAdb => '다른 앱 위에 표시(ADB)';

  @override
  String get tileStyleModern => '현대';

  @override
  String get tileStyleVolume => '차원';

  @override
  String get showTime => '쇼 시간';

  @override
  String get showDate => '날짜 표시';

  @override
  String get showWeather => '날씨 표시';

  @override
  String get showNetwork => '네트워크 상태 표시';

  @override
  String get showTraffic => '교통정보 표시';

  @override
  String get scheduledBrightness => '예약된 밝기';

  @override
  String get followTileStyle => '스타일을 따르세요';

  @override
  String get androidTvSettingsHint => 'TV 시스템 설정을 엽니다';

  @override
  String get autoHideTopPanel => '패널을 자동으로 숨깁니다.';

  @override
  String get showSectionTitles => '섹션 제목 표시';

  @override
  String get usageDaily => '매일';

  @override
  String get usageWeekly => '주간';

  @override
  String get usageMonthly => '월간';

  @override
  String get onlineWallpaperAddress => '이미지 주소(HTTPS)';

  @override
  String get watchNextAppLimits => '앱당 한도';

  @override
  String get watchNextAppLimitsHint =>
      '소스 제한은 전체 제한보다 먼저 적용됩니다. Unlimited는 전체 한도만 유지합니다. 숨겨진 콘텐츠는 숨겨진 상태로 유지됩니다.';

  @override
  String get rememberCategoryFocus => '마지막으로 집중된 카드 기억';

  @override
  String get automaticBackups => '자동 백업';

  @override
  String get automaticBackupsHint =>
      '런처가 활성화되어 있는 동안 매일 설정, 배경 화면 및 배너 사본이 제공됩니다. 누락된 복사본은 실행 프로그램으로 돌아온 후 실행됩니다. 이 장치에는 최대 256개의 MiB가 개인적으로 저장됩니다. 앱이나 해당 데이터를 제거하면 삭제됩니다. 외부 백업도 유지하세요.';

  @override
  String get automaticBackupsEnabled => '매일 자동 백업';

  @override
  String get automaticBackupsKeep => '보관할 사본';

  @override
  String get automaticBackupCreateNow => '지금 복원 지점 만들기';

  @override
  String get automaticBackupFailed => '백업 작업이 실패했습니다. 여유 공간을 확인하고 다시 시도하세요.';

  @override
  String get restorePoints => '복원 지점';

  @override
  String get noRestorePoints => '아직 복원 지점이 없습니다.';

  @override
  String get updatePrereleases => '사전 출시 버전으로 업데이트';

  @override
  String get topPanelObjects => '객체';

  @override
  String get panelTransparency => '패널 투명성';

  @override
  String get panelTextBackground => '텍스트 및 버튼 배경';

  @override
  String get panelTextBackgroundColor => '텍스트 및 버튼 배경색';

  @override
  String get panelTextColor => '텍스트 및 버튼 색상';

  @override
  String get panelTextSize => '텍스트 및 버튼 크기';

  @override
  String get panelFont => '텍스트 글꼴';

  @override
  String get fontSans => '산세리프체';

  @override
  String get fontSerif => '세리프';

  @override
  String get fontMono => '고정 폭';

  @override
  String get fontCondensed => '응축됨';

  @override
  String get trafficPermissionGranted => '교통 통계 액세스 권한이 부여되었습니다.';

  @override
  String get background => '배경';

  @override
  String get backgroundParameters => '소스 설정';

  @override
  String get resetAppearanceHint => '배경, 강조, 타일, 라벨, 강조표시 및 애니메이션을 재설정하시겠습니까?';

  @override
  String get wallpaperDimming => '디밍';

  @override
  String get wallpaperPlacement => '배치';

  @override
  String get wallpaperDisplay => '배경 화면 표시';

  @override
  String get wallpaperContain => '전체 이미지 표시';

  @override
  String get wallpaperBlurred => '흐린 사본';

  @override
  String get wallpaperCover => '화면 채우기';

  @override
  String get wallpaperBrightness => '배경 화면 밝기';

  @override
  String get wallpaperSaturation => '채도';

  @override
  String get categoryPadding => '카테고리 패딩';

  @override
  String get categoryLight => '빛';

  @override
  String get categoryBlue => '블루';

  @override
  String get categoryPurple => '보라색';

  @override
  String get categoryAllRows => '모두';

  @override
  String get categoryTeal => '청록색';

  @override
  String get categoryMaxRows => '보이는 그리드 행';

  @override
  String get categoryDark => '어둠';

  @override
  String get categoryAppearance => '카테고리 외관';

  @override
  String get categoryBackground => '카테고리 배경';

  @override
  String get categoryTransparent => '투명';

  @override
  String get slideshowInterval => '변경 간격';

  @override
  String get slideshowFolderSelected => '이 기기에 폴더 액세스 권한이 저장되었습니다.';

  @override
  String get slideshowRandom => '무작위 순서';

  @override
  String get wallpaperSlideshow => '폴더 슬라이드쇼';

  @override
  String get slideshowNext => '다음 이미지';

  @override
  String get slideshowFolderRequired => '슬라이드쇼를 시작할 폴더를 선택하세요.';

  @override
  String get slideshowHint =>
      '최대 1,000개의 이미지와 4,000개의 폴더 항목; 파일은 최대 8개 MiB입니다. 손상된 파일은 건너뛰고 마지막으로 좋은 이미지가 유지됩니다. 변경사항은 백그라운드에서 중지됩니다. 다른 기기에서 복원한 후 해당 폴더를 다시 선택하세요.';

  @override
  String get slideshowSeconds => '초';

  @override
  String get slideshowError =>
      '이미지를 읽을 수 없습니다. 유효한 이미지가 포함된 액세스 가능한 폴더를 선택하세요.';

  @override
  String get slideshowFolder => '폴더 선택';

  @override
  String get slideshowRecursive => '하위 폴더 포함';

  @override
  String get weatherSourceKeyRequired => '이 날씨 소스에 대해 API 키를 추가하세요.';

  @override
  String get weatherOpenWeatherCredit =>
      '날씨: OpenWeather(openweathermap.org). 일일 값은 사용 가능한 3시간 예측 기간을 요약합니다.';

  @override
  String get weatherOpenWeatherHint =>
      '현재 날씨와 5일/3시간 예보에 키를 사용하세요. 각 업데이트는 두 가지 요청을 합니다. 액세스 및 제한은 계획에 따라 다릅니다.';

  @override
  String get weatherOpenWeatherKey => 'OpenWeather API 키';

  @override
  String get mediaPause => '일시중지';

  @override
  String get showNowPlaying => '지금 홈에서 재생 중';

  @override
  String get nowPlayingAccessHint =>
      '미디어 제어에는 CuteLauncher에 대한 알림 액세스가 필요합니다. 플레이어가 제공한 작업만 표시됩니다.';

  @override
  String get nowPlaying => '지금 재생 중';

  @override
  String get mediaNext => '다음 트랙';

  @override
  String get mediaPlay => '이력서';

  @override
  String get mediaControlError => '플레이어를 사용할 수 없거나 이 작업을 수락하지 않았습니다.';

  @override
  String get nightUsageAccess => '사용 액세스 허용';

  @override
  String get nightExcludedAppsHint =>
      '선택한 앱에서 오버레이 및 예약된 TCL 필터가 일시중지됩니다. 사용 권한이 필요합니다. 그렇지 않으면 제외를 적용할 수 없습니다.';

  @override
  String get nightExcludedApps => '제외된 앱';

  @override
  String get adbPairPort => '페어링 포트';

  @override
  String get adbPairOverlayHint =>
      '무선 디버깅을 열고 페어링 코드로 페어링합니다. 시스템 코드 대화 상자를 열어 두십시오. 이 양식은 30초 후에 활성화됩니다. 포트와 Android에 표시된 코드를 모두 입력하세요.';

  @override
  String get adbOverlaySettings => '30초 동안 제어권을 설정으로 되돌립니다.';

  @override
  String get adbTlsHint =>
      '개발자 옵션에서 무선 디버깅을 사용하세요. 페어링과 연결 포트는 다릅니다. 펌웨어에 페어링 코드 화면이 없거나 오버레이 창을 차단하는 경우 대신 TCP/RSA를 사용하세요. 모든 연결은 이 TV에 대한 로컬로 유지됩니다.';

  @override
  String get adbPaired => '페어링되었습니다. 무선 디버깅 연결 포트를 이용하여 연결을 확인하세요.';

  @override
  String get adbTransport => '연결 방법';

  @override
  String get adbPairCode => '6자리 코드';

  @override
  String get adbOverlayRequired => '설정을 통한 코드 입력은 다른 앱 위에 표시하려면 권한이 필요합니다.';

  @override
  String get adbOverlayPermission => '다른 앱 위에 표시 허용';

  @override
  String get adbTlsUnsupported =>
      '이 펌웨어는 필수 설정 화면이나 페어링 오버레이를 열 수 없습니다. TCP/RSA를 사용하세요.';

  @override
  String get adbConnectPort => '연결 포트';

  @override
  String get adbTls => 'TLS/페어링 코드';

  @override
  String get adbTcp => 'TCP/RSA';

  @override
  String get adbPairingFailed =>
      '페어링에 실패했습니다. 코드와 페어링 포트를 확인하고 Android 코드 대화 상자를 열어둔 후 다시 시도하세요.';

  @override
  String get adbTlsDisabled =>
      '무선 디버깅이 비활성화되었거나 해당 상태를 사용할 수 없습니다. 개발자 옵션에서 활성화하세요.';

  @override
  String get adbPairOverlay => '설정에 페어링 코드를 입력하세요.';

  @override
  String get adbPair => '쌍';

  @override
  String get adbDeveloperSettings => '개발자 옵션 열기';

  @override
  String get adbTwoWindowsHint =>
      '이 펌웨어가 두 개의 창을 지원하는 경우 CuteLauncher 옆에 시스템 페어링 대화 상자를 열어두고 여기에 해당 코드를 입력하십시오. 직접 페어링은 두 창이 모두 열려 있는 동안에만 가능합니다.';

  @override
  String get adbTwoWindows => '두 번째 창에서 설정 열기';

  @override
  String get autoLaunchBoot => 'TV 부팅 후';

  @override
  String get autoLaunchOff => '장애인';

  @override
  String get autoLaunchTitle => '자동 시작';

  @override
  String get autoLaunchDelay => '발사 지연';

  @override
  String get autoLaunchHdmi => '선택한 HDMI 입력으로 전환';

  @override
  String get autoLaunchWake => '기상 후';

  @override
  String get autoLaunchHint =>
      'TV 시작 또는 절전 모드 해제 후 열 앱 또는 HDMI 입력을 선택하세요. 아래에서 이벤트와 지연을 설정하세요. Android가 CuteLauncher를 표시하면 작업이 한 번 실행됩니다. 원격 입력을 하거나 홈 화면을 나가면 대기가 취소됩니다. 나중에 HDMI 입력을 자유롭게 변경할 수 있습니다. CuteLauncher를 기본 실행기로 설정하거나 필요한 경우 부팅 시 시작을 활성화합니다. 깨우기 감지를 계속 실행하려면 CuteLauncher가 필요합니다.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds 초';
  }

  @override
  String get autoLaunchApp => '선택한 앱 열기';

  @override
  String get autoLaunchTarget => '발사 목표';

  @override
  String get autoLaunchUnavailable => '대상을 사용할 수 없거나 펌웨어에서 이 작업을 허용하지 않습니다.';

  @override
  String get autoLaunchCancelled => '지연 출시가 취소되었습니다.';

  @override
  String get syncTitle => '교환 설정';

  @override
  String get syncHint =>
      '설정 파일을 저장하고 다른 장치로 전송한 다음 그곳에서 엽니다. 파일을 다시 교환하여 두 장치를 모두 최신 상태로 유지하세요. 인터페이스, 타일 스타일 및 디스플레이 기본 설정이 공유됩니다. 앱, 섹션, 배경화면 파일, 권한, HOME, 실행 규칙 및 비밀은 이 장치에 유지됩니다. 이는 수동 교환입니다. 계정이나 백그라운드 네트워크 연결이 사용되지 않습니다.';

  @override
  String get syncExport => '변경 사항을 파일에 저장';

  @override
  String get syncImport => '다른 기기의 변경사항 열기';

  @override
  String get syncSaved => '설정 교환 파일이 저장되었습니다.';

  @override
  String get syncFailed =>
      '설정을 교환할 수 없습니다. 부분 가져오기는 유지되지 않습니다. 파일을 확인하거나 검토 중에 설정이 변경된 경우 다시 엽니다.';

  @override
  String get syncPreviewHint =>
      '적용하기 전에 변경사항을 검토하세요. 충돌이 발생하는 경우 각 행을 선택하여 이 장치나 파일을 선택하세요. 처음에는 이 장치 유지가 선택되어 있습니다. 취소하면 설정이 변경되지 않습니다.';

  @override
  String get syncNoChanges => '새로운 설정이 없습니다. 공유 이력 인정을 신청합니다.';

  @override
  String syncLocalValue(String value) {
    return '이 장치: $value';
  }

  @override
  String syncFileValue(String value) {
    return '파일에서: $value';
  }

  @override
  String get syncKeepLocal => '충돌: 이 장치를 유지하세요';

  @override
  String get syncUseFile => '충돌: 파일 사용';

  @override
  String get syncApply => '검토된 변경사항 적용';

  @override
  String get syncApplied => '설정이 교환되었습니다. 결과를 다시 보내려면 새 파일을 저장하세요.';

  @override
  String syncStyleParameters(int count) {
    return '사용자 지정 스타일: 매개변수 $count개(차이점은 아래 표시)';
  }

  @override
  String get cloudBackups => '클라우드 백업';

  @override
  String get cloudHelp =>
      'WebDAV / Nextcloud. 기존 폴더의 HTTPS 주소와 앱 비밀번호를 입력하세요. 전송은 수동으로 이루어집니다. 이 폴더에는 최신 복사본이 저장됩니다.';

  @override
  String get cloudUrl => '폴더 HTTPS 주소';

  @override
  String get cloudUser => '사용자 이름';

  @override
  String get cloudPassword => '앱 비밀번호';

  @override
  String get cloudConnect => '계정 확인 및 저장';

  @override
  String get cloudCheck => '연결 확인';

  @override
  String get cloudDisconnect => '계정 연결 해제';

  @override
  String get cloudDisconnectConfirm =>
      'TV에서 이 계정을 삭제하시겠습니까? 클라우드의 사본은 그대로 유지됩니다.';

  @override
  String get cloudUpload => '클라우드에 복사본 저장';

  @override
  String get cloudDownload => '클라우드에서 복원';

  @override
  String get cloudUploadConfirm =>
      '이 폴더의 Cutelauncher_backup.json을 현재 설정 및 데이터로 바꾸시겠습니까?';

  @override
  String get cloudSuccess => '완료';

  @override
  String get cloudConfigurationError => 'HTTPS 폴더 주소, 사용자 이름, 앱 비밀번호를 확인하세요.';

  @override
  String get cloudAuthorizationError => '액세스가 거부되었습니다. 계정 및 폴더 권한을 확인하세요.';

  @override
  String get cloudMissingError => '폴더 또는 백업을 찾을 수 없습니다.';

  @override
  String get cloudUnsupportedError =>
      '이 주소는 필수 WebDAV 작업을 지원하지 않습니다. 리디렉션은 따르지 않습니다. 최종 폴더 주소를 입력하세요.';

  @override
  String get cloudNetworkError =>
      '연결이 실패했거나 시간이 초과되었습니다. 네트워크를 사용할 수 있게 되면 다시 시도해 보세요.';

  @override
  String get cloudFailed => '백업 작업을 완료할 수 없습니다. 저장소 액세스를 확인하고 다시 시도하세요.';

  @override
  String get cloudStorageError => '계정 저장을 사용할 수 없습니다. 계정 연결을 끊고 다시 구성하십시오.';

  @override
  String get adbPermissionChecking => '액세스 확인 중…';

  @override
  String get adbPermissionConnected => 'ADB 연결됨 · 권한 부여';

  @override
  String get adbPermissionDisconnected => 'ADB 연결이 끊어짐 · 연결 설정';

  @override
  String get adbSetupIntro =>
      'TV 개발자 설정에서 디버깅 및 네트워크 ADB를 활성화한 다음 CuteLauncher를 신뢰하세요. 모든 ADB 작업에 따른 위험은 귀하의 책임입니다.';

  @override
  String get adbConnectionBlock => 'ADB 연결';

  @override
  String get adbNotChecked => '연결이 확인되지 않았습니다.';

  @override
  String get adbApplied => '이미 적용됨';

  @override
  String get adbNotApplied => '아직 적용되지 않음';

  @override
  String get adbDefaultBlock => '기본 실행기';

  @override
  String get adbSystemDefault => '시스템 기본 실행기 설정 열기';

  @override
  String get adbAssignDefault => 'ADB를 통해 CuteLauncher를 기본 실행기로 설정';

  @override
  String get adbRestoreDefault => 'ADB를 통해 이전 기본 실행기를 복원합니다.';

  @override
  String get adbDefaultHint => '시스템 메뉴에서 기본 실행 프로그램을 설정할 수 없는 경우 ADB를 사용하세요.';

  @override
  String get adbBuiltinHint =>
      '내장 실행기를 비활성화하면 시스템이 대신 CuteLauncher를 열 수 있습니다. TV 메뉴 및 버튼이 영향을 받을 수 있습니다. 이 작업을 취소하려면 내장 실행기를 활성화하세요.';

  @override
  String get adbHomeBlock => '홈 버튼 및 시작';

  @override
  String get adbEnableService => 'ADB를 통해 CuteLauncher 접근성 서비스 활성화';

  @override
  String get adbHomeOverride => '홈 버튼 재정의';

  @override
  String get adbHomeOptional =>
      '내장 실행기가 비활성화된 경우 홈을 재정의하고 TV 시작 시 실행하는 것은 선택 사항입니다.';

  @override
  String get adbEnableBuiltin => 'ADB를 통해 내장 실행 프로그램 활성화';

  @override
  String get adbDisableBuiltin => 'ADB를 통해 내장 실행 프로그램 비활성화';

  @override
  String get adbNoBuiltin => '내장된 Google TV / Android TV 실행기를 찾을 수 없습니다.';

  @override
  String get adbChanged => '상태가 변경되었습니다. 연결을 확인하고 작업을 다시 확인하십시오.';

  @override
  String get adbEffectHome =>
      'CuteLauncher가 시스템 기본 실행 프로그램이 됩니다. 복원을 위해 현재 실행 프로그램이 저장됩니다.';

  @override
  String get adbEffectRestore =>
      '이전 실행기가 활성화되고 기본값으로 설정됩니다. 사용할 수 없거나 저장되지 않은 경우 사용 가능한 첫 번째 다른 실행 프로그램이 선택됩니다. 홈 버튼 수정은 비활성화되지 않습니다.';

  @override
  String get adbEffectDisable =>
      'TV 사용자의 경우 내장된 런처 앱이 비활성화됩니다. TV 메뉴 및 버튼이 작동하지 않을 수 있습니다. 앱이 제거되지 않았습니다.';

  @override
  String get adbRecoveryHomeDisable =>
      '복구 홈 화면을 포함한 전체 Google TV 설정 마법사도 비활성화되어 CuteLauncher가 기본 실행 프로그램이 될 수 있습니다. 설정 마법사 기능은 복원될 때까지 사용할 수 없습니다. 두 패키지의 원래 상태는 복원을 위해 저장됩니다.';

  @override
  String get adbRecoveryHomeRestore => 'Google TV 설정 마법사도 저장된 상태로 돌아갑니다.';

  @override
  String get adbDisableHomeUnavailable =>
      '다른 홈 화면의 우선순위가 더 높습니다. 이 런처로는 안전하게 비활성화할 수 없습니다.';

  @override
  String get adbEffectEnable =>
      '내장된 실행 프로그램은 저장된 상태로 복원되거나, 저장된 상태가 없으면 활성화됩니다. 시스템은 이를 기본 실행기로 다시 선택할 수 있습니다.';

  @override
  String get adbEffectAccessibility =>
      'CuteLauncher 접근성 서비스가 활성화됩니다. 홈 이벤트를 수신할 수 있습니다. 차단은 별도의 스위치로 제어됩니다. 다른 서비스는 보존됩니다.';

  @override
  String get adbEffectAccessibilityRestore =>
      'CuteLauncher 서비스는 ADB 액세스가 허용되기 전의 상태로 돌아갑니다. 다른 접근성 서비스는 유지됩니다.';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher는 야간 필터를 포함하여 다른 앱 위에 창을 표시할 수 있습니다.';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher는 자체 수신기 서비스를 통해 알림 액세스를 받습니다.';

  @override
  String get adbEffectWatchNext => 'CuteLauncher는 계속 시청 데이터에 대한 액세스 권한을 받습니다.';

  @override
  String get adbEffectUsage =>
      'CuteLauncher는 트래픽 및 포그라운드 앱 감지를 위한 사용 통계 액세스를 받습니다.';

  @override
  String get adbEffectWriteSettings => 'CuteLauncher는 시스템 밝기 설정을 변경할 수 있습니다.';

  @override
  String get adbNoAvailableLauncher => '설치된 다른 실행 프로그램을 찾을 수 없습니다. 복원이 불가능합니다.';

  @override
  String get adbUnsupported => '이 장치에서는 사용할 수 없습니다. 지원되는 ADB 명령이 없습니다.';

  @override
  String get adbHomeUnavailable =>
      '내장된 실행 프로그램은 시스템 우선순위를 가집니다. ADB를 통한 직접 할당은 불가능합니다. 접근성을 사용하거나 내장 실행기를 비활성화하세요.';

  @override
  String get nightBatteryExempt => 'CuteLauncher는 최적화에서 제외됩니다.';

  @override
  String get nightBatteryHint =>
      '일정이 백그라운드에서 실행되는 데 도움이 될 수 있습니다. 프로세스가 대기 상태에서 살아남는 것을 보장하지 않습니다.';

  @override
  String get nightBatteryOptimized => 'CuteLauncher는 최적화 대상입니다.';

  @override
  String get nightBatteryTitle => '배터리 최적화';

  @override
  String get nightBatteryUnavailable =>
      '이 펌웨어에서는 시스템 설정을 사용할 수 없거나 액세스가 거부되었습니다.';

  @override
  String get nightBatteryUnknown => '면제 상태를 알 수 없음';

  @override
  String get nightBatteryOpenApps => '앱 설정 열기';

  @override
  String get nightBatteryGuide =>
      '1. 앱 설정에서 특수 앱 액세스를 엽니다.\n2. 배터리 최적화(경우에 따라 에너지 절약)를 선택합니다.\n3. CuteLauncher를 찾으세요. 필요한 경우 모든 앱을 선택합니다.\n4. 최적화를 비활성화하거나 제한 없음을 선택합니다.\n메뉴 이름과 사용 가능 여부는 TV 펌웨어에 따라 다릅니다.';

  @override
  String get updateNotifications => '업데이트 알림 표시';

  @override
  String get diagnosticsSave => '보고서를 파일로 저장';

  @override
  String get diagnosticsSaved => '보고서가 저장되었습니다.';

  @override
  String get diagnosticsSaveFailed => '보고서를 저장할 수 없습니다. 파일 관리자와 대상 폴더를 확인하세요.';

  @override
  String get memoryCacheSize => '이미지 캐시 크기';

  @override
  String get memoryProcess => '앱 메모리';

  @override
  String get memoryImages => '이미지 캐시';

  @override
  String get diagnosticsExportOpened => '파일 관리자에서 폴더를 선택하고 보고서를 저장합니다.';

  @override
  String get adbDisableService => 'ADB를 통해 CuteLauncher 접근성 서비스 비활성화';

  @override
  String get adbDefaultSettings => '기본 런처 설정';

  @override
  String get adbHomeSettings => '홈버튼 설정';

  @override
  String get adbAccessibilitySettings => '접근성 설정 열기';

  @override
  String get adbAccessibilityGuide =>
      '시스템 메뉴에서 CuteLauncher를 선택하고 해당 서비스를 활성화합니다. 홈 차단을 구성하려면 여기로 돌아오세요. 이를 비활성화하려면 동일한 메뉴에서 CuteLauncher 서비스를 끄십시오.';

  @override
  String get adbEffectAccessibilityDisable =>
      'CuteLauncher 서비스가 비활성화됩니다. 홈 차단이 중지됩니다. 다른 접근성 서비스는 유지됩니다.';

  @override
  String get backupAutoEnabled => '자동 백업';

  @override
  String get backupClientId => '클라이언트 ID';

  @override
  String get backupClientSecret => '클라이언트 비밀번호';

  @override
  String get backupCloudImportConfirm =>
      '모든 로컬 설정, 카테고리 및 이미지가 클라우드 데이터로 대체됩니다. 계속하다?';

  @override
  String get backupConfigured => '구성됨';

  @override
  String get backupConnection => '연결 설정';

  @override
  String get backupCreated => '생성됨';

  @override
  String get backupDaily => '매일';

  @override
  String get backupDriveHelp =>
      '연결을 선택하고 휴대폰에서 코드를 확인하세요. 백업은 Google Drive의 CuteLauncher 폴더에 표시되며, 여기서 다운로드하거나 삭제할 수 있습니다. 인앱 복원을 위해 파일 이름을 변경하지 않고 유지하세요. 숨겨진 백업에서 업그레이드한 후 다시 연결하세요. 이전 백업은 자동으로 마이그레이션되지 않습니다.';

  @override
  String get backupFrequency => '백업 빈도';

  @override
  String get backupHourly => '시간별';

  @override
  String get backupLocal => '로컬 사본';

  @override
  String get backupMinutes => '분';

  @override
  String get backupMode => '모드';

  @override
  String get backupNever => '아직 백업이 없습니다';

  @override
  String get backupNotConfigured => '구성되지 않음';

  @override
  String get backupOptions => '백업 옵션';

  @override
  String get backupSaveMode => '백업';

  @override
  String get backupScope => 'TV 간 백업';

  @override
  String get backupSyncScope => 'TV 간 동기화';

  @override
  String get backupSeparate => 'TV마다 별도';

  @override
  String get backupShared => '모든 TV에 동일한 설정';

  @override
  String get backupStorage => '저장';

  @override
  String get backupSyncHelp =>
      '데이터를 다운로드하고 변경 사항을 업로드합니다. 최신 변경 사항이 충돌을 이기게 됩니다. TV 시계가 정확해야 합니다. 실행기가 열려 있는 동안 동기화가 실행됩니다.';

  @override
  String get backupSyncLimit => '다음보다 자주 확인하지 마세요.';

  @override
  String get backupSyncMode => '동기화';

  @override
  String get backupSyncOptions => '동기화 옵션';

  @override
  String get backupTime => '백업 시간';

  @override
  String get backupWeekday => '요일';

  @override
  String get backupWeekly => '주간';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      '로컬 복사본은 앱 또는 해당 데이터와 함께 삭제됩니다. TV 외부에도 사본을 보관하세요.';

  @override
  String get panelObjectOrder => '개체 순서';

  @override
  String get panelInformationGroup => '정보';

  @override
  String get panelOrderHint =>
      '◄ / ►로 이동 시작 또는 종료, ▲ / ▼로 순서 변경 및 그룹 경계에서 반대쪽으로 이동, OK / 뒤로로 종료합니다.';

  @override
  String get panelTextBackgroundTransparency => '텍스트 및 버튼 배경 투명도';

  @override
  String get weatherCityHint => '도시 이름을 영어로 입력하세요(예: Moscow).';

  @override
  String get weatherCityNotFound => '도시를 찾을 수 없습니다. 도시 이름을 영어로 확인하세요.';

  @override
  String get weatherLocationAutomatic => '자동으로 받기';

  @override
  String get weatherLocationAutomaticHint => '장치 좌표를 가져옵니다. 위치 권한이 필요합니다.';

  @override
  String get weatherLocationManual => '수동으로 입력';

  @override
  String get weatherLocationPermissionDenied =>
      'Android 설정에서 위치 액세스를 허용하고 다시 시도하세요.';

  @override
  String get weatherLocationUnavailable =>
      '좌표를 얻을 수 없습니다. Android 위치 설정을 확인하거나 도시를 수동으로 입력하세요.';

  @override
  String get nightFilterSettings => '필터 설정';

  @override
  String get nightScheduleMenu => '일정';

  @override
  String get nightScheduleInactive => '일정이 꺼져 있습니다';

  @override
  String get nightLocation => '위치';

  @override
  String get nightLocationAutomatic => '자동으로 받기';

  @override
  String get nightLocationManual => '수동으로 입력';

  @override
  String get nightLocationFailed => '위치를 확인할 수 없습니다. 권한 및 시스템 위치 설정을 확인하세요.';

  @override
  String get nightCityEnglish => '도시 이름을 영어로 입력하세요';

  @override
  String get nightOverlayBrief => '필터가 다른 앱 위에 표시되도록 허용합니다.';

  @override
  String get weatherGetLocation => '위치 확인';

  @override
  String get backupLastCreated => '마지막 백업이 생성되었습니다:';

  @override
  String get backupManagement => '백업 관리';

  @override
  String get backupCopyList => '백업 목록';

  @override
  String get backupRefreshCopyList => '백업 목록 새로 고침';

  @override
  String get backupCreateNow => '지금 새 백업 만들기';

  @override
  String get backupFolderPath => '백업 폴더';

  @override
  String get backupPrivateFolder => '개인 애플리케이션 폴더';

  @override
  String get backupRestoreCopy => '이 백업을 복원하세요';

  @override
  String get backupDeleteConfirm => '선택한 백업을 삭제하시겠습니까?';

  @override
  String get blockedAppsGroup => '차단된 앱';

  @override
  String get notificationSettingsButton => '알림 설정';

  @override
  String get hidePersistentNotificationsHint => '목록과 다른 앱에서 지속적인 알림을 숨깁니다.';

  @override
  String get nightTransitionTime => '전환 시간';

  @override
  String get brightnessSolar => '야간 모드 일정 사용';

  @override
  String get brightnessAfterSunrise => '일출 후';

  @override
  String get brightnessAfterSunset => '일몰 후';

  @override
  String get brightnessTransitionTime => '밝기 전환 시간';

  @override
  String get brightnessSolarUnavailable =>
      '야간 모드 일정을 사용할 수 없습니다. 시간과 위치를 확인하세요.';

  @override
  String get persistentNotificationCannotDelete =>
      '이 지속적인 알림은 삭제할 수 없습니다. 차단할 수만 있습니다.';

  @override
  String get diagnosticsCreateFailed => '진단 보고서를 생성할 수 없습니다. 다시 시도해 보세요.';

  @override
  String get backupListFailed => '백업 목록을 로드할 수 없습니다. 선택한 저장소에 대한 액세스를 확인하세요.';

  @override
  String get updateInstallerFailed =>
      '업데이트 설치 프로그램을 열 수 없습니다. 다시 시도하고 Android 설치 프로그램을 사용할 수 있는지 확인하세요.';

  @override
  String get backupFolderFailed =>
      '백업 폴더를 선택하거나 저장할 수 없습니다. 접근 가능한 폴더를 선택하고 다시 시도하세요.';

  @override
  String get updateDownloadFailed =>
      '업데이트를 다운로드할 수 없습니다. 인터넷 연결과 사용 가능한 저장 공간을 확인하세요.';

  @override
  String get backupDeleteFailed => '백업을 삭제할 수 없습니다. 삭제 권한을 확인하고 다시 시도하세요.';

  @override
  String get updateCheckFailed => '업데이트를 확인할 수 없습니다. 인터넷 연결을 확인하고 다시 시도하세요.';

  @override
  String get backupCreateFailed =>
      '백업을 생성할 수 없습니다. 저장소 액세스 및 사용 가능한 공간을 확인하세요.';

  @override
  String get wallpaperChangeFailed =>
      '배경화면을 변경할 수 없습니다. 파일 액세스를 확인하고 다시 시도하세요.';

  @override
  String get backupDownloadsFolder => '다운로드 / CuteLauncher';

  @override
  String get backupChooseFolder => '파일 관리자에서 폴더를 선택하세요';

  @override
  String get backupFolderPickerUnavailable =>
      '이 TV에서는 폴더 선택기를 사용할 수 없습니다. 다운로드 / CuteLauncher 또는 내부 앱 폴더를 선택합니다.';

  @override
  String get driveConfigurationError =>
      'Google Drive 자격 증명이 누락되었거나 유효하지 않습니다. TV OAuth 클라이언트의 클라이언트 ID와 클라이언트 비밀번호를 입력하세요.';

  @override
  String get driveCodeExpired =>
      'Google Drive 로그인 시간이 초과되었습니다. 새 코드를 받으려면 계정 확인 및 저장을 선택하세요.';

  @override
  String get brightnessAfterNightStart => '야간';

  @override
  String get brightnessAfterNightEnd => '주간';

  @override
  String get backupSyncSettings => '동기화할 설정';

  @override
  String get backupSyncHomeGroup => '홈 화면, 섹션 및 앱';

  @override
  String get backupSyncAppearanceGroup => '외관, 배경화면 및 배너';

  @override
  String get backupSyncDisplayGroup => '야간 모드, 밝기 및 화면 보호기';

  @override
  String get backupSyncControlsGroup => '런처 및 TV 컨트롤';

  @override
  String get backupSyncGeneralGroup => '언어, 업데이트 및 기타 설정';

  @override
  String get backupSyncGroupsHelp =>
      '비활성화된 블록은 이 TV에 로컬로 유지됩니다. 블록 선택은 장치 간에 동기화됩니다.';

  @override
  String get backupSyncGroupsFailed => '동기화를 위한 설정 선택을 저장할 수 없습니다. 다시 시도해 보세요.';

  @override
  String get tileLayoutMode => '타일 레이아웃';

  @override
  String get tileLayoutAuto => '타일 크기에 따라 자동';

  @override
  String get tileLayoutColumns => '고정 열 수';

  @override
  String get tileLayoutRows => '고정 행 수';

  @override
  String get tileRowCount => '행 개수';

  @override
  String get useGlobalTileSettings => '전역 설정 사용';

  @override
  String get centerSelection => '선택 위치';

  @override
  String get selectionBottom => '바닥';

  @override
  String get selectionLower => '중간 하단';

  @override
  String get selectionCenter => '센터';

  @override
  String get selectionUpper => '중간 상단';

  @override
  String get selectionTop => '탑';

  @override
  String get settingsStyle => '설정 스타일';

  @override
  String get tileFocusEnlargement => '초점 확대';

  @override
  String get tileFocusShadowStrength => '그림자 강도';

  @override
  String get tileFocusLift => '리프트';

  @override
  String get tileFocusLiftHeight => '리프트 높이';

  @override
  String get tileFocusBorderColor => '초점 테두리 색상';

  @override
  String get tileFocusAccentColor => '악센트 색상';

  @override
  String get tileFocusDynamicColor => '동적 색상';

  @override
  String get tileSizeFromColumns => '타일 크기는 열 수와 섹션 너비에 따라 결정됩니다.';

  @override
  String get resetSectionToGlobal => '설정을 공유 값으로 재설정';

  @override
  String get resetSectionToGlobalHint =>
      '공유 섹션 제목, 아이콘, 배경을 복원하고 패딩을 재설정하시겠습니까?';

  @override
  String get resetStyleSection => '이 섹션 재설정';

  @override
  String get resetStyleSectionHint => '이 섹션의 기본값만 복원하시겠습니까?';

  @override
  String get notificationStyle => '알림 스타일';

  @override
  String get styleBackgroundColor => '배경색';

  @override
  String get styleTransparency => '배경 투명도';

  @override
  String get styleTextSize => '텍스트 크기';

  @override
  String get styleTextColor => '텍스트 색상';

  @override
  String get noticeSize => '알림 크기';

  @override
  String get noticeStylePreview => '알림 미리보기';

  @override
  String get backupSyncHomeOptions => '동작 및 일반 옵션';

  @override
  String get backupSyncBackground => '배경 및 맞춤 배너';

  @override
  String get backupSyncTiles => '타일, 메뉴 및 알림 스타일';

  @override
  String get backupSyncWeatherSource => '소스 및 위치';

  @override
  String get backupSyncWeatherDisplay => '날씨 표시 및 온도 단위';

  @override
  String get backupSyncNotificationSettings => '알림 표시 및 필터';

  @override
  String get backupSyncOther => '기타 설정';

  @override
  String get tileFocusBorderStyle => '테두리 스타일';

  @override
  String get tileFocusOutline => '개요';

  @override
  String get tileFocusGlow => '글로우';

  @override
  String get tileFocusNoBorder => '국경 없음';

  @override
  String get tileShowFocusShadow => '그림자 표시';

  @override
  String get homeLayoutRow => '가로줄';

  @override
  String get homeLayoutRows => '여러 행';

  @override
  String get homeLayoutGrid => '그리드';

  @override
  String get homeCardCount => '눈에 보이는 카드';

  @override
  String get homeAuto => '자동';

  @override
  String get homeFree => '무료 스크롤';

  @override
  String get homeAnchored => '고정된 섹션';

  @override
  String get homeScrollMode => '섹션 스크롤';

  @override
  String get homeSectionPosition => '활성 섹션 위치';

  @override
  String get homeLabelMode => '애플리케이션 라벨';

  @override
  String get homeLabelNone => '라벨 없음';

  @override
  String get homeLabelSelected => '선택한 애플리케이션만';

  @override
  String get homeLabelAll => '모든 애플리케이션';

  @override
  String get homeInherited => '상속된 가치';

  @override
  String get homeOwnReset => '공통 설정 복원';

  @override
  String get homeParameters => '매개변수';

  @override
  String get homeSectionStyle => '단면 모양';

  @override
  String get homeSectionGap => '섹션 사이의 공간';

  @override
  String get homeSectionIcons => '섹션 아이콘';

  @override
  String get homeInactiveOpacity => '비활성 섹션 불투명도';

  @override
  String get homeResetSection => '상속된 섹션 모양 복원';

  @override
  String get homeCalculatedSize => '크기는 카드 수로 계산됩니다.';

  @override
  String homeGapLimited(int gap) {
    return '선택한 카드 수를 유지하기 위해 간격은 $gap로 제한됩니다.';
  }

  @override
  String get homeResetLayout => '섹션 레이아웃 재설정';

  @override
  String homeVisibleRows(int count) {
    return '완전히 보이는 행: $count';
  }

  @override
  String get homeStylePartial => '이 값을 상속하고 현재 레이아웃에서 지원하는 섹션에만 적용됩니다.';

  @override
  String get homeStyleUnavailable =>
      '현재 섹션 설정에서는 사용할 수 없습니다. 레이아웃과 로컬 재정의를 확인하세요.';

  @override
  String get homeStyleNeedsRows => '여러 행이나 그리드에 사용할 수 있습니다.';

  @override
  String get homeStyleNeedsLabels => '라벨의 크기와 색상을 변경하려면 라벨을 활성화하세요.';

  @override
  String get homeStyleNeedsAllLabels =>
      '위치는 모든 카드의 라벨에만 적용됩니다. 선택한 제목은 섹션 아래에 유지됩니다.';

  @override
  String get homeStyleNeedsScale => '확대 초점 효과를 선택하세요.';

  @override
  String get homeStyleNeedsLift => '리프트 포커스 효과를 선택하세요.';

  @override
  String get homeStyleNeedsBorder => '윤곽선이나 광선을 먼저 활성화하십시오.';

  @override
  String get homeStyleNeedsTitle => '아이콘을 표시하려면 섹션 제목을 활성화하세요.';

  @override
  String get homeStyleEconomy => '메모리 절약으로 인해 비활성화되었습니다. 저장된 값은 유지됩니다.';

  @override
  String get homeStyleOpaque => '흐리게 보려면 타일 배경 불투명도를 줄이세요.';

  @override
  String get homeStyleOverridden =>
      '표시되는 섹션은 자체 값을 사용합니다. 이 설정을 적용하려면 섹션에서 \"전역 사용\"을 선택하세요.';

  @override
  String get homeStyleIconHint =>
      '아이콘 크기는 앱 아이콘이 있는 카드에 영향을 미칩니다. TV 배너는 카드를 독립적으로 채웁니다.';

  @override
  String get homeStyleShadowHint =>
      '메모리 절약은 비활성 카드의 섀도우를 4개로 제한합니다. 포커스 섀도우는 별도로 구성됩니다.';

  @override
  String get homeStyleTransparent =>
      '불투명도가 0이면 배경색이 보이지 않습니다. 타일 ​​배경 불투명도를 높입니다.';

  @override
  String get homeStyleSingleColumn => '단일 열 그리드에는 수평 간격이 없습니다.';

  @override
  String get homeStyleAutoOnly => '전체 크기를 상속하는 자동 카드 수가 있는 섹션에서만 크기가 변경됩니다.';

  @override
  String get sleepTimerThirtySeconds => '30초(테스트)';

  @override
  String get sleepTimer => '취침 타이머';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes 분';
  }

  @override
  String sleepTimerHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours시간',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerHourAndHalf => '1.5시간';

  @override
  String get sleepTimerAllowExact => '정확한 타이머 허용';

  @override
  String get sleepTimerExactRequired =>
      'Android 설정에서 정확한 타이머를 허용한 다음 지속 시간을 다시 선택하세요.';

  @override
  String get sleepTimerAccessRequired =>
      'CuteLauncher 접근성을 활성화하거나 설정 → 기타 → ADB에서 로컬 ADB를 연결하세요.';

  @override
  String get sleepTimerFailed =>
      '취침 타이머를 설정하거나 완료할 수 없습니다. 접근성과 로컬 ADB를 확인하세요.';

  @override
  String get nightIgnoreHdmiInputs => 'HDMI 입력 무시';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'HDMI를 시청하는 동안 야간 필터를 일시 중지하세요. 사용 권한이 필요합니다. 입력 감지는 TV 펌웨어에 따라 다릅니다.';

  @override
  String get inputsSettings => '입력 설정';

  @override
  String get inputsUseCecNames => 'CEC의 장치 이름 사용';

  @override
  String get inputsNamesHint =>
      '이름 우선순위: CuteLauncher의 이름 → CEC(활성화된 경우) → Android 설정의 이름 → 표준 입력 이름.';

  @override
  String get inputNameHint => '자동 이름을 지정하려면 비워두세요.';

  @override
  String get inputsSaveFailed => '입력 설정을 저장할 수 없습니다.';

  @override
  String get inputIcon => '입력 아이콘';

  @override
  String get inputIconTv => 'TV';

  @override
  String get inputIconGame => '게임 콘솔';

  @override
  String get inputIconComputer => '컴퓨터';

  @override
  String get inputIconReceiver => '수신기';

  @override
  String get inputIconDisc => '디스크 플레이어';

  @override
  String get inputIconStream => '스트리밍 장치';

  @override
  String get nightInputExclusions => '입력 제외';

  @override
  String get nightSelectInputs => '무시할 입력 선택';

  @override
  String get nightNoInputsSelected => '선택한 입력이 없습니다. 필터는 모든 입력에 적용됩니다.';

  @override
  String get nightPictureExclusions => '사진 모드 제외';

  @override
  String get nightPictureExclusionsHint =>
      '디밍, 웜 오버레이 및 연결된 TCL 필터를 일시 중지하는 모드를 선택하세요. 일정이 유지됩니다. TCL에서 감지가 확인되었습니다. 사용 액세스가 필요하지 않습니다.';

  @override
  String get nightPictureUnavailable =>
      '현재 사진 모드는 이 펌웨어에서 사용할 수 없습니다. 선택 사항이 저장되었습니다. 제외는 탐지에 성공한 경우에만 적용됩니다.';

  @override
  String get nightPictureCurrent => '현재 모드';

  @override
  String get nightPictureRefresh => '현재 모드 새로 고침';

  @override
  String get nightPictureCode => '모드 코드';

  @override
  String get nightPictureStandard => '표준';

  @override
  String get nightPictureDynamic => '동적';

  @override
  String get nightPictureMovie => '영화';

  @override
  String get nightPictureSport => '스포츠';

  @override
  String get nightPictureIntelligent => '지능형';

  @override
  String get nightPictureBright => '밝음(Dolby Vision)';

  @override
  String get nightPictureOrdinary => '표준';

  @override
  String get systemApplications => '시스템 앱';

  @override
  String get removeFromCategory => '카테고리에서 삭제';

  @override
  String get noRemovableCategories =>
      '이 앱은 어떤 섹션에도 수동으로 추가되지 않았습니다. 자동 섹션은 편집할 수 없습니다.';

  @override
  String get remoteButtonsTitle => '리모컨 버튼 재설정';

  @override
  String get remoteButtonsStart => '버튼 확인 (120초)';

  @override
  String get remoteButtonsStop => '확인 종료';

  @override
  String get remoteButtonsHint =>
      '코드, 놓기 및 반복을 표시하고 TV에 텍스트 보고서를 저장합니다. OK가 기록을 조작하지 않도록 시작 후 이 페이지에서 나가세요.';

  @override
  String get remoteButtonsEmpty =>
      '아직 이벤트가 없습니다. 버튼으로 앱이 열리면 여기로 돌아와 결과를 확인하세요.';

  @override
  String get remoteButtonsService => '서비스 연결됨';

  @override
  String get remoteButtonsRefresh => '새로고침';

  @override
  String get remoteBindings => '버튼 할당';

  @override
  String get remoteMappingsEnabled => '재설정 사용';

  @override
  String get remoteMappingsAdd => '할당 추가';

  @override
  String get remoteMappingKey => '버튼';

  @override
  String get remoteMappingAction => '동작';

  @override
  String get remoteMappingLearn => '리모컨 버튼 감지';

  @override
  String get remoteMappingLearnHint =>
      '30초 안에 추가 버튼을 누르세요. 탐색, Power, 음성 검색 및 볼륨 버튼은 보호됩니다.';

  @override
  String get remoteMappingsHint =>
      '버튼 할당에는 접근성 서비스가 필요합니다. 편집기와 진단 중에는 일시 중지됩니다. Home, 뒤로, 방향키, OK는 탐색 기능을 유지합니다.';

  @override
  String get remoteMappingsReset => '할당 초기화';

  @override
  String get remoteMappingsResetConfirm => '모든 할당을 삭제하고 재설정을 끌까요?';

  @override
  String get remoteMappingInvalid =>
      '저장하지 못했습니다. 버튼과 대상을 확인하세요. Webhook은 HTTPS 또는 로컬 네트워크의 HTTP가 필요합니다.';

  @override
  String get remoteMappingBack => '뒤로';

  @override
  String get remoteMappingProfile => '프로필';

  @override
  String get remoteMappingChannels => '채널';

  @override
  String get remoteMappingQuickSettings => 'TCL 빠른 설정';

  @override
  String get remoteMappingTrigger => '누르기 유형';

  @override
  String get remoteMappingPress => '짧게 누르기';

  @override
  String get remoteMappingHold => '길게 누르기';

  @override
  String get remoteMappingHoldHint =>
      '650ms 동안 누르면 짧게 누르기 동작 없이 한 번 실행합니다. 길게 누르기만 할당하면 짧게 눌러도 동작하지 않습니다.';

  @override
  String get remotePanelDescription =>
      '플로팅 패널은 다른 앱 위에 필요한 위젯을 표시합니다. 리모컨으로 열려면 원하는 버튼에 플로팅 패널 동작을 지정하세요.';

  @override
  String get remotePanel => '플로팅 패널';

  @override
  String get remotePanelSettingsBackground => '설정 배경색 사용';

  @override
  String get remotePanelPreview => '패널 열기';

  @override
  String get settingsHelp => '자세히 알아보기';

  @override
  String get settingsHelpScroll => '▲ / ▼ — 텍스트 스크롤';

  @override
  String get panelClockStyle => '시계 모양';

  @override
  String get clockPreset => '글꼴 스타일';

  @override
  String get clockCustom => '사용자 지정';

  @override
  String get clockWeight => '글꼴 두께';

  @override
  String get clockGlow => '텍스트 빛 효과';

  @override
  String get clockAnimate => '숫자 애니메이션';

  @override
  String get clockBackground => '시계 배경';

  @override
  String get clockRadius => '배경 모서리 둥글기';

  @override
  String get dateCalendarEnabled => '날짜를 눌러 달력 열기';

  @override
  String get calendarTitle => '달력';

  @override
  String get dateSettings => '날짜 설정';

  @override
  String get clockSharedBackground => '다른 항목과 같은 배경 사용';

  @override
  String get clockDefaultBackground => '기본 배경';

  @override
  String get remotePanelInheritAppearance => '상단 패널 모양 사용';

  @override
  String get remotePanelDisabledInLauncher =>
      'CuteLauncher가 화면에 표시되는 동안 팝업 패널이 비활성화됩니다.';

  @override
  String get remoteAccessSettings => '접근 권한 설정';

  @override
  String get remoteButtonsTest => '버튼 테스트';

  @override
  String get remoteMappingConflict =>
      '이 버튼과 누르기 유형은 이미 할당되었습니다. 다른 버튼이나 누르기 유형을 선택하세요.';

  @override
  String get cleanerTitle => 'TV cleanup manager';

  @override
  String get cleanerRefresh => 'Refresh applications';

  @override
  String get cleanerSnapshot => 'Save original state';

  @override
  String get cleanerRestore => '기준 상태로 복원';

  @override
  String get cleanerSnapshotSaved => 'Original state saved';

  @override
  String get cleanerExportSnapshot => 'Export original state';

  @override
  String get cleanerSafe => 'Disable verified applications';

  @override
  String get cleanerNoSafe => '이 모델과 펌웨어에 일치하는 시스템 앱 목록이 없습니다.';

  @override
  String get cleanerLocal => 'Disable using a local list';

  @override
  String get cleanerProject => 'Project catalog lists';

  @override
  String get cleanerRemoteProject => 'Refresh catalog from GitHub';

  @override
  String get cleanerExternal => 'CleanYourTV examples';

  @override
  String get cleanerDisabledExport => '사용 중지 앱 보고서를 파일로 내보내기';

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
      '첫 목록 새로고침 성공 시 기준 상태가 한 번 생성되며 런처에서 삭제하거나 덮어쓸 수 없습니다. 해당 펌웨어에 연결됩니다. 수동 상태는 앱 모드를 이름 및 날짜와 함께 저장하며 복원, 삭제, 내보내기가 가능합니다. APK나 앱 데이터는 포함하지 않습니다. 복원에는 로컬 ADB가 필요합니다. 반복 충돌 보호가 작동하면 기준 상태로 자동 복원을 시도합니다. 런처 데이터 삭제나 제거 시 복사본도 삭제됩니다. 루트 접근은 막을 수 없습니다.';

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
  String get landscapeDemoStop => '중지';

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
  String get informationGroup => '시계, 날짜 및 날씨';

  @override
  String get informationSettings => '블록 설정';

  @override
  String get informationAppearance => '블록 모양';

  @override
  String get informationSize => '블록 크기';

  @override
  String get informationPosition => '시계와 텍스트 위치';

  @override
  String get informationClockLeft => '시계 왼쪽, 텍스트 오른쪽';

  @override
  String get informationClockRight => '텍스트 왼쪽, 시계 오른쪽';

  @override
  String get informationSpacing => '시계와 텍스트 간격';

  @override
  String get informationBackground => '블록 배경';

  @override
  String get homeResetTilesHint => '이 화면의 모든 타일과 레이블을 공통 값으로 복원할까요?';

  @override
  String get homeResetLayoutHint =>
      '이 섹션의 레이아웃을 초기화하고 공통 모양을 복원하며 안쪽 여백을 없앨까요? 앱과 순서는 유지됩니다.';

  @override
  String get networkSummary => '네트워크';

  @override
  String get networkConnected => '인터넷 사용 가능';

  @override
  String get networkOffline => '인터넷에 연결할 수 없음';

  @override
  String get networkDisconnected => '연결되지 않음';

  @override
  String get networkConnection => '연결';

  @override
  String get networkSignal => '신호';

  @override
  String get networkLinkSpeed => 'Wi-Fi 링크 속도';

  @override
  String get networkTrafficRate => '기기 트래픽 · 수신 / 송신';

  @override
  String get networkSystemSettings => '시스템 네트워크 설정';

  @override
  String get networkUnavailable => '사용 불가';

  @override
  String get networkMobile => '모바일 네트워크';

  @override
  String get networkFrequency => '주파수';

  @override
  String get networkMbps => 'Mbps';

  @override
  String get networkKbps => 'KB/초';

  @override
  String get networkReadFailed => '네트워크 상태를 읽을 수 없습니다';

  @override
  String get clockItalic => '기울임꼴';

  @override
  String get panelWrapNavigation => '패널 순환 탐색';

  @override
  String get panelWrapNavigationHelp =>
      '가장자리에서 화살표를 누르면 반대쪽으로 이동합니다. 화살표를 길게 누르면 양쪽을 계속 탐색합니다.';

  @override
  String get networkReceive => '수신';

  @override
  String get networkSend => '송신';

  @override
  String get landscapeCelestialBodies => '해와 달';

  @override
  String get landscapeStarRotation => '별 회전';

  @override
  String get tvPowerTitle => '전원 관리';

  @override
  String get tvPowerOff => 'TV 끄기';

  @override
  String get tvPowerReboot => 'TV 다시 시작';

  @override
  String get tvPowerOffConfirm => 'TV를 대기 모드로 전환할까요?';

  @override
  String get tvPowerRebootConfirm => '다시 시작할까요? 열려 있는 앱이 종료됩니다.';

  @override
  String get tvPowerSent => '명령 전송됨';

  @override
  String get tvPowerFailed => '전송하지 못했습니다. ADB 또는 접근성을 확인하세요.';

  @override
  String get tvPowerHelp =>
      '끄기는 CuteLauncher 접근성 서비스 또는 로컬 ADB로 대기 모드를 켭니다. 다시 시작하려면 ADB가 필요합니다. TV 박스에서는 박스를 제어하며 TV 동작은 HDMI-CEC와 펌웨어에 따라 다릅니다.';

  @override
  String get cleanerLists => '사용 중지 목록';

  @override
  String get cleanerRecovery => '백업 및 복원';

  @override
  String get cleanerExports => '보고서';

  @override
  String get cleanerUpdating => '앱 목록 업데이트 중…';

  @override
  String get cleanerRefreshRequired => '먼저 앱 목록을 새로고침하세요.';

  @override
  String get cleanerPreinstalled => '사전 설치된 앱';

  @override
  String get cleanerNotSystem => '시스템 앱이 아닙니다.';

  @override
  String get cleanerMinimalRisk => '최소';

  @override
  String get cleanerCacheFailure => '다음 방문을 위해 목록을 저장하지 못했습니다.';

  @override
  String get cleanerUserApps => '사용자 앱';

  @override
  String get cleanerPreinstalledApps => '사전 설치된 앱';

  @override
  String get cleanerSystemApps => '시스템 앱';

  @override
  String get cleanerBaseline => '기준 초기 상태';

  @override
  String get cleanerManualStates => '수동 저장 상태 관리';

  @override
  String get cleanerManualSave => '현재 상태 저장';

  @override
  String get cleanerDateName => '날짜와 시간 사용';

  @override
  String get cleanerCustomName => '이름 입력';

  @override
  String get cleanerStateExport => '저장된 상태를 파일로 내보내기';

  @override
  String get cleanerStateRestoreHelp =>
      '이 펌웨어에 저장된 앱의 사용 및 사용 중지 상태를 복원합니다. 복사본 생성 후 설치한 앱은 변경하지 않습니다. 없는 앱과 보호된 구성 요소의 사용 중지는 건너뜁니다. 앱 데이터는 복원하지 않습니다.';

  @override
  String get cleanerCopiesHelp =>
      '첫 목록 새로고침 성공 시 기준 상태가 한 번 생성되며 런처에서 삭제하거나 덮어쓸 수 없습니다. 해당 펌웨어에 연결됩니다. 수동 상태는 앱 모드를 이름 및 날짜와 함께 저장하며 복원, 삭제, 내보내기가 가능합니다. APK나 앱 데이터는 포함하지 않습니다. 복원에는 로컬 ADB가 필요합니다. 반복 충돌 보호가 작동하면 기준 상태로 자동 복원을 시도합니다. 런처 데이터 삭제나 제거 시 복사본도 삭제됩니다. 루트 접근은 막을 수 없습니다.';

  @override
  String get cleanerSearch => '이름으로 검색';

  @override
  String get cleanerCatalogUpdateRequired => '먼저 GitHub에서 카탈로그를 새로고침하세요.';

  @override
  String get cleanerNoSearchResults => '일치하는 항목이 없습니다.';

  @override
  String get cleanerAlreadyDisabled => '이 목록 중 이 TV에 있는 모든 앱은 이미 사용 중지 상태입니다.';

  @override
  String get cleanerAlreadyEnabled => '이 목록 중 이 TV에 있는 모든 앱은 이미 사용 상태입니다.';

  @override
  String get cleanerNoInstalled => '이 목록에 일치하는 앱이 이 TV에 설치되어 있지 않습니다.';

  @override
  String get cleanerListProtected => '나머지 앱은 사용 중지로부터 보호됩니다.';

  @override
  String get cleanerSnapshotFailed => '상태를 저장하지 못했습니다. 앱을 사용 중지하지 않았습니다.';

  @override
  String get cleanerDisableAllPreinstalled => '모든 사전 설치 앱 사용 중지';

  @override
  String get cleanerEnableAllPreinstalled => '모든 사전 설치 앱 사용';

  @override
  String get cleanerPreinstalledList => '사전 설치 앱 목록';

  @override
  String cleanerBeforeList(String listName) {
    return '목록 적용 전: $listName';
  }

  @override
  String get sleepTimerSettings => '취침 타이머 설정';

  @override
  String get sleepTimerPresets => '타이머';

  @override
  String get sleepTimerDisplay => '타이머 실행 중 표시';

  @override
  String get sleepTimerRemaining => '남은 시간';

  @override
  String get sleepTimerEndTime => '종료 시각';

  @override
  String get sleepTimerBoth => '남은 시간과 종료 시각';

  @override
  String get sleepTimerShowSeconds => '초 표시';

  @override
  String get sleepTimerCloseAfterSelection => '타이머 선택 후 위젯 닫기';

  @override
  String get sleepTimerAdd => '타이머 추가';

  @override
  String get sleepTimerEdit => '타이머 편집';

  @override
  String get sleepTimerHoursLabel => '시간';

  @override
  String get sleepTimerMinutesLabel => '분';

  @override
  String get sleepTimerSecondsLabel => '초';

  @override
  String get sleepTimerInvalidDuration =>
      '0보다 긴 시간을 입력하세요. 시간 0–999999, 분과 초 0–59.';

  @override
  String get sleepTimerDeleteConfirmation =>
      '이 타이머를 삭제할까요? 실행 중인 카운트다운은 계속됩니다.';

  @override
  String get sleepTimerResetConfirmation =>
      '기본 타이머와 순서를 복원할까요? 사용자 타이머는 삭제됩니다. 실행 중인 카운트다운은 계속됩니다.';

  @override
  String get sleepTimerReorderHint =>
      '◄ / ► 또는 OK 길게 눌러 이동. ▲ / ▼로 순서를 바꾸고 표시/숨김 목록 사이에서 이동합니다. OK로 이동을 마칩니다.';

  @override
  String get sleepTimerSaveFailed => '타이머 설정을 저장할 수 없습니다.';

  @override
  String get sleepTimerVisible => '표시';

  @override
  String get sleepTimerHidden => '숨김';

  @override
  String get sleepTimerReset => '타이머 초기화';

  @override
  String get cleanerListSnapshotHelp =>
      '목록 사용 중지 전에 선택한 앱만 자동 저장합니다. 복원 시 다른 앱은 변경하지 않습니다. 수동 및 자동 상태를 합쳐 최대 100개 저장합니다. 저장에 실패하면 사용 중지를 시작하지 않습니다.';

  @override
  String get trafficSettings => '트래픽 설정';

  @override
  String get trafficTitle => '트래픽';

  @override
  String get trafficReceived => '수신';

  @override
  String get trafficSent => '송신';

  @override
  String get trafficTotal => '전체';

  @override
  String get stopApp => '중지';

  @override
  String get backgroundImageFormats =>
      '이미지: JPEG, PNG, WebP, GIF, BMP — 최대 8 MiB, 4,800만 화소, 각 변 16,384픽셀.';

  @override
  String get backgroundMediaFormats =>
      '이미지: JPEG, PNG, WebP, GIF, BMP — 최대 8 MiB, 4,800만 화소, 각 변 16,384픽셀.\n동영상: MP4/M4V, WebM, MKV — 최대 256 MiB, 3840×2160. 코덱 지원은 TV에 따라 다릅니다. H.264 MP4를 권장합니다. 소리 없이 반복하며 홈 밖에서는 일시 정지합니다. 동영상은 백업에 포함되지 않습니다.';

  @override
  String get backgroundFormatError =>
      '지원하지 않는 형식이거나 손상된 파일입니다. 표시된 형식의 정상 파일을 선택하세요.';

  @override
  String backgroundFileTooLarge(String maxMiB) {
    return '파일이 너무 큽니다. 최대 $maxMiB MiB입니다. 더 작은 파일을 선택하세요.';
  }

  @override
  String get backgroundImageResolutionError =>
      '이미지가 너무 큽니다. 최대 4,800만 화소, 각 변 16,384픽셀입니다.';

  @override
  String get backgroundVideoResolutionError =>
      '동영상 해상도가 너무 높습니다. 최대 3840×2160 또는 2160×3840을 선택하세요.';

  @override
  String get backgroundVideoCodecError =>
      'TV에서 동영상을 재생할 수 없습니다. 코덱이 지원되지 않거나 파일이 손상되었습니다. H.264 MP4를 시도하세요.';

  @override
  String get backgroundFileApplied => '파일을 선택했습니다. 배경이 변경되었습니다.';

  @override
  String get noticePosition => '알림 위치';

  @override
  String get noticeBottomRight => '오른쪽 아래';

  @override
  String get noticeBottomLeft => '왼쪽 아래';

  @override
  String get noticeTopRight => '오른쪽 위';

  @override
  String get noticeTopLeft => '왼쪽 위';

  @override
  String get notificationOpenFailed => '알림 동작을 열 수 없습니다. 더 이상 사용할 수 없을 수 있습니다.';

  @override
  String get adbWifiOverride => '그래도 사용 중지…';

  @override
  String get adbWifiRiskTitle => '위험을 감수하고 사용 중지할까요?';

  @override
  String get adbWifiRiskEffect => '기본 런처와 Google 설정 마법사가 사용 중지됩니다.';

  @override
  String get adbWifiRiskLoss =>
      'Android가 저장된 Wi-Fi 네트워크를 삭제할 수 있습니다. Wi-Fi 연결과 무선 ADB를 사용할 수 없게 될 수 있습니다.';

  @override
  String get adbWifiRiskRecovery =>
      '설정 마법사를 다시 켜도 삭제된 네트워크가 자동으로 복원되지 않습니다. Wi-Fi에 다시 연결하고 비밀번호를 입력해야 합니다.';

  @override
  String get adbWifiRiskConsent => 'Wi-Fi 비밀번호를 알고 있는 경우에만 계속하세요.';

  @override
  String get adbWifiDisable => '사용 중지';
}
