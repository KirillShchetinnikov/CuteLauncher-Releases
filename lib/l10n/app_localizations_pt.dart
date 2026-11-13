// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get scrollContentLabels => 'Rolar rótulos longos nas linhas';

  @override
  String get contentAppTileStyle => 'Origem da aparência';

  @override
  String get contentTileOwnAppearance => 'Aparência personalizada';

  @override
  String get contentTileCommonAppearance => 'Aparência geral';

  @override
  String get contentUseSourceLabels =>
      'Usar os rótulos da aparência selecionada';

  @override
  String get contentLabelSelected => 'Apenas o cartão selecionado';

  @override
  String get contentLabelAll => 'Todos os cartões';

  @override
  String get weatherTextResetFormat => 'Redefinir formato';

  @override
  String get settingsReportFile => 'Ficheiro do relatório';

  @override
  String get homeVisibleRowsLabel => 'Linhas totalmente visíveis';

  @override
  String get watchNextEmpty => 'Ainda não há cartões para continuar a assistir';

  @override
  String get inputsUnavailableStatus => 'Nenhuma entrada disponível';

  @override
  String get remoteButtonsNoEvents => 'Ainda não há eventos';

  @override
  String get informationBackgroundVerticalOffset => 'Deslocamento vertical';

  @override
  String get informationResetPositionSize =>
      'Redefinir todas as configurações desta tela';

  @override
  String get weatherIconsGeometric => 'Geométricos';

  @override
  String get weatherIconsCircled => 'Em círculo';

  @override
  String get informationCommonAppearance => 'Configurações comuns';

  @override
  String get informationTimeFormat => 'Formato de hora';

  @override
  String get informationDateFormat => 'Formato de data';

  @override
  String get informationInheritPanelTypography =>
      'Herdar a aparência do painel superior';

  @override
  String get informationResetTypography => 'Redefinir configurações';

  @override
  String get alignSectionTitles =>
      'Alinhar os títulos das secções com os mosaicos';

  @override
  String get homeAppName => 'Nome da aplicação no ecrã inicial';

  @override
  String get restoreSystemAppName => 'Restaurar o nome do sistema';

  @override
  String get settingsScrollbar => 'Barra de rolagem';

  @override
  String get settingsScrollbarHidden => 'Ocultar completamente';

  @override
  String get settingsScrollbarOnScroll => 'Mostrar durante a rolagem';

  @override
  String get settingsScrollbarAlways => 'Mostrar sempre';

  @override
  String get volumeKeysTitle => 'Manter botões de volume';

  @override
  String get volumeKeysMode => 'Modo de correção';

  @override
  String get volumeKeysAuto => 'Auto: enquanto o painel estiver visível';

  @override
  String get volumeKeysTimed => 'Pausa temporizada';

  @override
  String get volumeKeysRepeat => 'Repetição própria';

  @override
  String get volumeKeysDuration => 'Duração da pausa';

  @override
  String get volumeKeysHelp =>
      'Em alguns Android TV e Google TV, interceptar botões pela acessibilidade interfere na repetição do volume. Isso pode afetar todos os aplicativos enquanto o serviço estiver ativo.\n\n«Auto: enquanto o painel estiver visível» é o modo recomendado por padrão ao ativar os mapeamentos. O indicador suspende o filtro. Após a pausa escolhida, a janela é verificada: a pausa se prolonga enquanto ela estiver visível, até um minuto. Se a janela estiver indisponível, usa-se um temporizador.\n\n«Pausa temporizada» restaura o filtro 3, 5, 10, 15 ou 30 segundos após a última aparição reconhecida do painel. Experimente se Auto for instável; aumente a duração se a pausa for curta.\n\n«Repetição própria» ajusta o volume até soltar o botão. Exige que o firmware envie o pressionar e o soltar ao serviço. Sem esses eventos não funciona; também pode haver passos duplos. Nesse caso, troque de modo.\n\nDurante a pausa, os mapeamentos e a interceptação de Home ficam indisponíveis. O primeiro toque longo pode mudar um passo: solte e repita enquanto o indicador estiver visível. «Desativado» restaura o controle nativo sem apagar mapeamentos. O modo escolhido é mantido ao desativar e reativar o remapeador.';

  @override
  String get fileStorageSettingsUnavailable =>
      'Este firmware não oferece uma tela de acesso a todos os arquivos. Use o explorador de arquivos externo ou instale um gerenciador de arquivos compatível.';

  @override
  String get tileImageMode => 'Imagem do bloco';

  @override
  String get tileBannerImageMode => 'Apps com banner';

  @override
  String get tileIconImageMode => 'Apps sem banner';

  @override
  String get tileImageContain => 'Mostrar imagem inteira';

  @override
  String get tileImageCover => 'Preencher com recorte';

  @override
  String get tileImageEdgeColor => 'Ajustar com cor da borda';

  @override
  String get tileImageIcon => 'Ícone com cor da borda';

  @override
  String get tileImageModeHelp =>
      'Escolha modos separados para apps com e sem banner. Aplicam-se quando a forma recorta a imagem ou deixa margens vazias. Mostre a imagem inteira, amplie proporcionalmente com recorte ou preencha o espaço livre com a cor da borda mais próxima. Substituir o banner pelo ícone com suas cores de borda está disponível apenas para apps com banner. O ajuste de tamanho do ícone é preservado.';

  @override
  String get wallhavenWallpaperHint =>
      'Papéis de parede aleatórios do Wallhaven por tema: SFW, 16:9, Full HD ou superior. Sem conta nem chave de API. Atualização com o launcher aberto; em caso de erro, mantém a imagem anterior.';

  @override
  String get renderCompatibilityTitle => 'Saída gráfica compatível';

  @override
  String get renderCompatibilityAutomatic =>
      'Ativada automaticamente neste dispositivo';

  @override
  String get renderCompatibilityApply => 'Aplicar e reiniciar o launcher';

  @override
  String get renderCompatibilityFailed =>
      'Não foi possível ler ou aplicar a configuração';

  @override
  String get renderCompatibilityHelp =>
      'Experimente este modo se a interface piscar com o escurecimento noturno. Ele é ativado automaticamente nos modelos verificados. Em outras TVs, a escolha é salva apenas neste dispositivo e aplicada após reiniciar o launcher. Pode aumentar a carga gráfica.';

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
      'O Wi-Fi pertence ao assistente de configuração';

  @override
  String get adbWifiOwned =>
      'Nenhuma alteração: uma rede Wi-Fi guardada foi criada pelo assistente Google. Desativá-lo pode apagar a rede e desligar a TV da internet.\n\n1. Confirme que sabe a palavra-passe Wi-Fi.\n2. Abra as definições de rede Android, selecione a rede e escolha Esquecer rede.\n3. Volte a ligar através dessas definições.\n4. Regresse ao CuteLauncher, verifique o ADB e tente desativar o launcher integrado.\n\nSe a mensagem voltar, mantenha o launcher integrado ativo: o firmware pode voltar a atribuir a rede ao assistente.';

  @override
  String get adbWifiUnknown =>
      'Not changed: the owners of saved Wi-Fi networks could not be verified. Disabling the setup wizard is blocked to protect your connection. Check ADB and try again; some firmware does not provide this information.';

  @override
  String get backgroundSource => 'Fonte de plano de fundo';

  @override
  String get noAvailableCategories =>
      'Não há seções disponíveis para adicionar este aplicativo.';

  @override
  String get redditWallpaperTheme => 'Tema de papel de parede';

  @override
  String get redditThemeAll => 'Misto';

  @override
  String get redditThemeNature => 'Natureza';

  @override
  String get redditThemeSpace => 'Espaço';

  @override
  String get redditThemeCity => 'Cidades';

  @override
  String get redditThemeMinimal => 'Minimalismo';

  @override
  String get redditWallpaperResolution => 'Resolução mínima';

  @override
  String get redditWallpaperHint =>
      'Cada atualização bem-sucedida baixa uma imagem de paisagem diferente da comunidade Reddit selecionada. A resolução é o tamanho original mínimo; as imagens não são ampliadas. A atualização é executada enquanto o inicializador está aberto e continua quando você retorna. Conteúdo adulto, vídeos e galerias são ignorados. Se Reddit bloquear o acesso ou nenhuma imagem correspondente for encontrada, o papel de parede anterior permanecerá.';

  @override
  String get dialogCommandDetails => 'Mostrar comandos ADB';

  @override
  String get dialogAssign => 'Atribuir';

  @override
  String get dialogApply => 'Aplicar';

  @override
  String get settingsValueNotSet => 'Não definido';

  @override
  String get settingsMenuPosition => 'Posição do menu de configurações';

  @override
  String get settingsMenuLeft => 'Esquerda';

  @override
  String get settingsMenuRight => 'Certo';

  @override
  String get actionCompleted => 'Ação concluída';

  @override
  String get showRepositoryQrCode => 'Mostrar código QR';

  @override
  String get resetSections => 'Redefinir configurações de seção';

  @override
  String get resetSectionsConfirmation =>
      'Restaurar seções padrão? Seções personalizadas, espaçadores e conteúdos de Favoritos serão removidos.';

  @override
  String get cardFocusMode => 'Concentre-se no retorno para casa';

  @override
  String get cardFocusRemember => 'Manter cartão selecionado';

  @override
  String get cardFocusFirst => 'Primeiro cartão';

  @override
  String get cardFocusSettings => 'Botão Configurações';

  @override
  String get aboutFlauncher => 'Sobre o CuteLauncher';

  @override
  String get addCategory => 'Adicionar categoria';

  @override
  String get addSection => 'Adicionar seção';

  @override
  String get alphabetical => 'Alfabético';

  @override
  String get appCardHighlightAnimation =>
      'Animação de destaque do cartão do app';

  @override
  String get appInfo => 'Informações do app';

  @override
  String get appKeyClick => 'Som de clique ao pressionar tecla';

  @override
  String get applications => 'Aplicativos';

  @override
  String get autoHideAppBar => 'Ocultar barra de status automaticamente';

  @override
  String get backButtonAction => 'Ação do botão voltar';

  @override
  String get category => 'Categoria';

  @override
  String get categories => 'Categorias';

  @override
  String get columnCount => 'Contagem de colunas';

  @override
  String get date => 'Data';

  @override
  String get dateAndTimeFormat => 'Formato de data e hora';

  @override
  String get delete => 'Excluir';

  @override
  String get dialogOptionBackButtonActionFirstFeedCard =>
      'Primeiro cartão da seção atual';

  @override
  String get dialogOptionBackButtonActionSectionStartThenUp =>
      'Primeiro cartão, depois subir uma seção por vez';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'Não fazer nada';

  @override
  String get dialogOptionBackButtonActionShowScreensaver =>
      'Mostrar protetor de tela';

  @override
  String get dialogOptionBackButtonActionShowClock => 'Mostrar relógio';

  @override
  String get dialogTextNoFileExplorer =>
      'Por favor, instale um explorador de arquivos para escolher uma imagem.';

  @override
  String get dialogTitleBackButtonAction => 'Escolha a ação do botão voltar';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (Categoria)';
  }

  @override
  String formattedDate(String dateString) {
    return 'Data formatada: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'Hora formatada: $timeString';
  }

  @override
  String get gradient => 'Gradiente';

  @override
  String get favoriteApps => 'Apps favoritos';

  @override
  String get grid => 'Grade';

  @override
  String get height => 'Altura';

  @override
  String get hide => 'Ocultar';

  @override
  String get hiddenApplications => 'Apps ocultos';

  @override
  String get launcherSections => 'Seções';

  @override
  String get layout => 'Disposição';

  @override
  String get loading => 'Carregando';

  @override
  String get manual => 'Manual';

  @override
  String get modifySection => 'Modificar seção';

  @override
  String get mustNotBeEmpty => 'Não pode estar vazio';

  @override
  String get name => 'Nome';

  @override
  String get newSection => 'Nova seção';

  @override
  String get noDateFormatSpecified => 'Nenhum formato de data especificado';

  @override
  String get noTimeFormatSpecified => 'Nenhum formato de hora especificado';

  @override
  String get nonTvApplications => 'Apps não-TV';

  @override
  String get open => 'Abrir';

  @override
  String get orSelectFormatSpecifiers =>
      'Ou selecione especificadores de formato';

  @override
  String get openImage => 'Escolher ficheiro';

  @override
  String get picture => 'Imagem ou vídeo local';

  @override
  String removeFrom(String name) {
    return 'Remover de $name';
  }

  @override
  String get renameCategory => 'Renomear categoria';

  @override
  String get reorder => 'Reordenar';

  @override
  String get row => 'Linha';

  @override
  String get rowHeight => 'Altura da linha';

  @override
  String get save => 'Salvar';

  @override
  String get spacer => 'Espaçador';

  @override
  String get spacerMaxHeightRequirement =>
      'Deve ser maior que 0 e menor ou igual a 500';

  @override
  String get statusBar => 'Barra de status';

  @override
  String get settings => 'Configurações';

  @override
  String get show => 'Mostrar';

  @override
  String get showCategoryTitles => 'Mostrar títulos das categorias';

  @override
  String get themes => 'Temas';

  @override
  String get hideHighlightOutlineOnHomescreen =>
      'Ocultar contorno de destaque na tela inicial';

  @override
  String get appSelectorTransitionAnimation =>
      'Animação de transição do seletor de apps';

  @override
  String get sort => 'Ordenar';

  @override
  String get systemSettings => 'Configurações do sistema';

  @override
  String textAboutDialog(String repoUrl) {
    return 'CuteLauncher — Kirill Shchetinnikov. Based on LTvLauncher (LeanBitLab) and FLauncher (Étienne Fesser). GNU GPLv3. $repoUrl';
  }

  @override
  String get textEmptyCategory => 'Esta categoria está vazia.';

  @override
  String get time => 'Hora';

  @override
  String get titleStatusBarSettingsPage =>
      'Escolha o que exibir na barra de status';

  @override
  String get tvApplications => 'Apps de TV';

  @override
  String get type => 'Tipo';

  @override
  String get typeInTheDateFormat => 'Digite o formato de data';

  @override
  String get typeInTheHourFormat => 'Digite o formato de hora';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String get wallpaper => 'Papel de parede';

  @override
  String get withEllipsisAddTo => 'Adicionar a...';

  @override
  String get timeBasedWallpaper => 'Imagem diurna/noturna';

  @override
  String get pickDayWallpaper => 'Escolher imagem diurna';

  @override
  String get pickNightWallpaper => 'Escolher imagem noturna';

  @override
  String get accessibility => 'Acessibilidade';

  @override
  String get defaultLauncherIsDefault => 'CuteLauncher é o launcher padrão';

  @override
  String get defaultLauncherNotDefault =>
      'CuteLauncher não é o launcher padrão';

  @override
  String get setAsDefaultLauncher => 'Definir como launcher padrão';

  @override
  String get defaultLauncherDescription =>
      'Quando definido como launcher padrão, o botão Home sempre retornará ao CuteLauncher. A TV também iniciará diretamente no CuteLauncher.';

  @override
  String get inputs => 'Entradas';

  @override
  String get inputsUnavailableHint =>
      'Este dispositivo não fornece entradas disponíveis. A chave está desabilitada e o ícone está oculto. Em uma caixa de TV, esta opção não controla as entradas HDMI da TV conectada.';

  @override
  String get inputSources => 'Fontes de entrada';

  @override
  String get backupAndRestore => 'Backup e Restauração';

  @override
  String get exportBackup => 'Exportar Backup';

  @override
  String get importBackup => 'Importar Backup';

  @override
  String exportSuccess(String path) {
    return 'Backup exportado com sucesso para $path';
  }

  @override
  String get importSuccess => 'Backup importado com sucesso';

  @override
  String get importConfirm =>
      'Tem certeza de que deseja importar o backup? Isso substituirá suas configurações e layout atuais.';

  @override
  String get importError =>
      'Não foi possível restaurar as configurações do backup. Verifique o arquivo e tente novamente.';

  @override
  String exportError(String error) {
    return 'Falha ao exportar backup: $error';
  }

  @override
  String get shareBackup => 'Compartilhar Backup';

  @override
  String get shareBackupDescription =>
      'Compartilhar backup com outros dispositivos na rede local';

  @override
  String get stopSharing => 'Parar Compartilhamento';

  @override
  String get localNetworkSharingActive =>
      'O compartilhamento na rede local está ativo!';

  @override
  String get localNetworkSharingInstructions =>
      'Conecte outro dispositivo à mesma rede Wi-Fi e abra a seguinte URL em um navegador da web:';

  @override
  String get localNetworkSharingDetails =>
      'Aqui você pode baixar as configurações/layout da sua TV ou enviar um arquivo de backup de volta para esta TV.';

  @override
  String failedToStartServer(String error) {
    return 'Falha ao iniciar o servidor de compartilhamento: $error';
  }

  @override
  String get notificationBell => 'Sino de Notificação';

  @override
  String get autoHideNotificationBell =>
      'Ocultar Sino de Notificação automaticamente';

  @override
  String get continueWatching => 'Continuar assistindo';

  @override
  String get showContinueWatchingOnHome =>
      'Mostrar Continuar assistindo na tela inicial';

  @override
  String get permissionDeniedContinueWatching =>
      'Permissão necessária para mostrar Continuar assistindo';

  @override
  String get interface => 'Interface';

  @override
  String get system => 'Sistema';

  @override
  String get accentColor => 'Cor de destaque';

  @override
  String get miscellaneous => 'Diversos';

  @override
  String get brightnessScheduler => 'Agendador de brilho';

  @override
  String get screensaverSettings => 'Configurações do protetor de tela';

  @override
  String get screensaverClockStyle => 'Estilo de relógio do protetor de tela';

  @override
  String get dataUsagePeriod => 'Período de uso de dados';

  @override
  String get notificationAccess => 'Acesso a notificações';

  @override
  String get granted => 'Concedido';

  @override
  String get permissionRequired => 'Permissão Necessária';

  @override
  String get systemWidePopupAlert => 'Alerta pop-up de todo o sistema';

  @override
  String get overlayPermissionRequired =>
      'Permissão de sobreposição necessária';

  @override
  String get enabled => 'Ativado';

  @override
  String get disabled => 'Desativado';

  @override
  String get showAppNamesBelowIcons =>
      'Mostrar nomes dos apps abaixo dos ícones';

  @override
  String get dataUsage => 'Uso de dados';

  @override
  String get networkIndicator => 'Indicador de rede';

  @override
  String get homeButtonFix => 'Correção do botão Home (Google TV)';

  @override
  String get startOnBoot => 'Iniciar ao ligar (Google TV / Fire TV)';

  @override
  String get appLanguage => 'Idioma';

  @override
  String get systemDefault => 'Padrão do sistema';

  @override
  String get english => 'Inglês';

  @override
  String get spanish => 'Espanhol';

  @override
  String get ukrainian => 'Ucraniano';

  @override
  String get chinese => 'Chinês';

  @override
  String get french => 'Francês';

  @override
  String get german => 'Alemão';

  @override
  String get japanese => 'Japonês';

  @override
  String get portuguese => 'Português';

  @override
  String get russian => 'Russo';

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
  String get hidePersistentNotifications => 'Ocultar notificações persistentes';

  @override
  String get hidePersistentNotificationsDesc =>
      'Ocultar notificações de serviços em segundo plano e do sistema';

  @override
  String get blockedNotificationApps => 'Aplicativos bloqueados';

  @override
  String get blockAppNotifications => 'Bloquear notificações';

  @override
  String get unblockAppNotifications => 'Desbloquear notificações';

  @override
  String get noBlockedApps => 'Nenhum aplicativo bloqueado';

  @override
  String get persistentNotification => 'Persistente';

  @override
  String get unblockAll => 'Desbloquear tudo';

  @override
  String get weather => 'Clima';

  @override
  String get showWeatherWarnings => 'Mostrar alertas de chuva e clima';

  @override
  String get temperatureUnit => 'Unidade de temperatura';

  @override
  String get celsius => 'Celsius (°C)';

  @override
  String get fahrenheit => 'Fahrenheit (°F)';

  @override
  String get breezyWeatherSetupHint =>
      'Instale o Breezy Weather e ative o \'Compartilhamento local de dados\' / \'Gadgetbridge\' nas configurações para ver o clima e alertas de chuva.';

  @override
  String get displayAndScreensaver => 'Tela e protetor de tela';

  @override
  String get notifications => 'Notificações';

  @override
  String get continueWatchingDescription =>
      'Mostrar filmes e programas assistidos recentemente na tela inicial';

  @override
  String get continueWatchingPermissionDesc =>
      'É necessária uma permissão especial para ler o histórico de reprodução:';

  @override
  String get requestPermission => 'Solicitar permissão';

  @override
  String get dismiss => 'Descartar';

  @override
  String get openApp => 'Abrir';

  @override
  String get notificationOptions => 'Opções de notificação';

  @override
  String get noBlockedAppsDesc =>
      'Todos os aplicativos estão atualmente autorizados a exibir notificações';

  @override
  String get notificationsAllowed => 'Notificações permitidas';

  @override
  String get notificationsBlocked => 'Notificações bloqueadas';

  @override
  String get dpadDismissHint => 'Esquerda: Descartar • OK: Opções';

  @override
  String get watchNextDeleteError =>
      'Não foi possível remover o item de Continuar assistindo. Tente novamente.';

  @override
  String get hideLauncherTile => 'Ocultar CuteLauncher na grade do aplicativo';

  @override
  String get hideAndroidSettingsTile =>
      'Ocultar configurações do Android em blocos de aplicativos';

  @override
  String get animateTileReordering => 'Animar reordenação de blocos';

  @override
  String get imageInputRejected =>
      'Esta imagem está danificada ou é muito grande (máximo 8 MiB e 48 megapixels). Escolha outra imagem.';

  @override
  String get memoryAdvanced => 'Diagnóstico avançado';

  @override
  String get memoryLauncherTitle => 'Memória do CuteLauncher';

  @override
  String get memoryUsage => 'Uso de memória';

  @override
  String memoryChange(String delta) {
    return '$delta desde a medição anterior';
  }

  @override
  String get memoryCacheFiles => 'Arquivos de imagem na memória';

  @override
  String memoryCacheEntries(int count) {
    return 'Itens: $count';
  }

  @override
  String memoryCacheResult(String before, String after) {
    return 'Caches de imagens: $before → $after';
  }

  @override
  String get memoryStale =>
      'Não foi possível atualizar. A medição anterior é exibida.';

  @override
  String get memoryTechnical => 'Detalhes técnicos';

  @override
  String get memoryObserve => 'Monitoramento de memória';

  @override
  String get memoryObserveStart => 'Observar por 1 minuto';

  @override
  String get memoryObserveStop => 'Parar monitoramento';

  @override
  String get memoryObserveRunning => 'Gravando · até 1 minuto';

  @override
  String get memoryObserveFinished => 'Gravação encerrada';

  @override
  String get memoryObserveEmpty => 'Nenhuma medição registrada';

  @override
  String memorySeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get memoryReadingHelp => 'Como interpretar as medições';

  @override
  String get memorySaverHelp => 'Efeitos da economia de memória';

  @override
  String get memorySaveFailed =>
      'Não foi possível salvar o modo de economia. Tente novamente.';

  @override
  String get memoryTitle => 'Memória';

  @override
  String get memoryRefresh => 'Medir memória';

  @override
  String get memoryMeasuring => 'Medindo…';

  @override
  String get memoryClear => 'Limpar caches de imagens';

  @override
  String get memorySaver => 'Economia de memória';

  @override
  String get memorySaverDescription =>
      'Modo de economia de memória:\n\n• Reduz caches de imagens e a janela de pré-carregamento do pôster.\n• Desativa o desfoque de fundo do bloco, do painel e do papel de parede e a pulsação do contorno.\n• Limita sombras em blocos desfocados.\n• Limpa caches quando o aplicativo entra em segundo plano.\n\nEsses efeitos não estão disponíveis nas configurações enquanto a economia de memória está ativada. Seus valores salvos retornam quando o modo é desabilitado. As imagens podem ser recarregadas com mais frequência.';

  @override
  String get memoryPss => 'Compartilhamento de processo (PSS)';

  @override
  String get memoryRss => 'Memória de processo residente (RSS)';

  @override
  String get memoryEncodedCache => 'Arquivos de imagem armazenados em cache';

  @override
  String get memoryDecodedCache => 'Imagens decodificadas em cache';

  @override
  String get memoryUnavailable => 'Indisponível';

  @override
  String get memoryUnit => 'MiB';

  @override
  String get memoryMeasuredAt => 'Medido em';

  @override
  String get memoryExplanation =>
      'PSS e RSS se sobrepõem: não os adicione. Os tamanhos de cache fazem parte da memória do aplicativo e não descrevem toda a memória mantida pelas imagens ativas. A limpeza de caches mantém suas configurações e arquivos; as imagens são carregadas novamente quando necessário. Android pode retornar memória posteriormente. RSS aqui vem do kernel e PSS de Android; eles podem contabilizar a memória gráfica de maneira diferente.';

  @override
  String get memoryRecommendations =>
      'Para menos memória, ative o salvamento, mostre menos cartões Continue assistindo e use papéis de parede menores ou um gradiente.';

  @override
  String get memoryMeasurementFailed =>
      'A medição do processo não está disponível. As informações do cache ainda são mostradas.';

  @override
  String get addToCategory => 'Adicionar à categoria';

  @override
  String get addToFavorites => 'Adicionar aos favoritos';

  @override
  String get removeFromFavorites => 'Remover dos favoritos';

  @override
  String get setCustomBanner => 'Definir banner personalizado';

  @override
  String get clearCustomBanner => 'Limpar banner personalizado';

  @override
  String get bannerSetFailed =>
      'Não foi possível definir o banner. Verifique o acesso à imagem e selecione o arquivo novamente.';

  @override
  String get bannerClearFailed =>
      'Não foi possível remover o banner personalizado. Tente novamente.';

  @override
  String get grantUsagePermission => 'Conceder permissão de uso';

  @override
  String get removeFromContinueWatching => 'Remover de continuar assistindo';

  @override
  String hideAllFromApp(String appName) {
    return 'Ocultar tudo de $appName';
  }

  @override
  String get playResume => 'Reproduzir / Retomar';

  @override
  String openNamedApp(String appName) {
    return 'Abra $appName';
  }

  @override
  String get selectedAccent => 'Acento Selecionado';

  @override
  String get homeButtonFixHint =>
      'Se você estiver usando Google TV, habilite \"Home Button Fix\" nas configurações de acessibilidade para fazer com que o botão Home abra este inicializador.';

  @override
  String get accessibilityPermission => 'Permissão de acessibilidade';

  @override
  String get shareFailed => 'Falha no compartilhamento';

  @override
  String shareBackupError(String error) {
    return 'Falha ao compartilhar backup: $error';
  }

  @override
  String get exportComplete => 'Sucesso na exportação';

  @override
  String get exportFailed =>
      'Não foi possível salvar o backup. Verifique o acesso à pasta e o armazenamento disponível.';

  @override
  String backupLoadError(String error) {
    return 'Erro ao carregar backups: $error';
  }

  @override
  String get noBackupFiles => 'Nenhum arquivo de backup encontrado.';

  @override
  String get importComplete => 'Sucesso na importação';

  @override
  String get importFailed => 'Falha na importação';

  @override
  String get importAction => 'Importar';

  @override
  String get continueWatchingApps => 'Continue assistindo aplicativos';

  @override
  String get blockedContinueWatching => 'Bloqueado para continuar assistindo';

  @override
  String get allAppsCanContinueWatching =>
      'Todos os aplicativos suportados podem mostrar itens em Continuar assistindo.';

  @override
  String get unblockApp => 'Desbloquear';

  @override
  String get unblockAllApps => 'Desbloquear todos os aplicativos';

  @override
  String get appsWithContinueWatching => 'Aplicativos com continuar assistindo';

  @override
  String get watchNextAppsHint =>
      'Aplicativos que atualmente fornecem itens do Assistir a seguir na tela inicial';

  @override
  String get noWatchNextApps =>
      'No momento, nenhum aplicativo fornece itens para continuar assistindo.\nQuando aplicativos suportados (como SmartTube ou serviços de streaming) adicionam itens, eles aparecerão aqui.';

  @override
  String get allInstalledApps => 'Todos os aplicativos instalados';

  @override
  String get blockWatchNextHint =>
      'Desative para impedir que qualquer aplicativo adicione itens a Continuar assistindo';

  @override
  String get cardSize => 'Tamanho do cartão';

  @override
  String get maximumItems => 'Máximo de itens';

  @override
  String get playbackProgressBar => 'Barra de progresso da reprodução';

  @override
  String get playbackPercentage => 'Porcentagem de reprodução';

  @override
  String get episodeVideoDetails => 'Detalhes do episódio e do vídeo';

  @override
  String get restoreHiddenPrograms => 'Restaurar programas ocultos';

  @override
  String get allHiddenProgramsRestored =>
      'Todos os programas ocultos restaurados';

  @override
  String get watchNextAccessAdb => 'Assistir próximo acesso (ADB obrigatório)';

  @override
  String get supportLtvLauncher => 'Suporte LTvLauncher';

  @override
  String get scanToDonate =>
      'Digitalize com a câmera do seu telefone para doar:';

  @override
  String get openInBrowser => 'Abrir no navegador';

  @override
  String get close => 'Fechar';

  @override
  String get launcherAuthor => 'CuteLauncher por Kirill Shchetinnikov';

  @override
  String get launcherCredits =>
      'Lançador Android TV baseado em LTvLauncher de LeanBitLab e FLauncher de Étienne Fesser. Licenciado sob GNU GPLv3.';

  @override
  String get projectCredits => 'Projeto e Créditos';

  @override
  String get launcherRepository => 'Repositório CuteLauncher';

  @override
  String get originalProject => 'Projeto original: LTvLauncher';

  @override
  String get noInputsDetected => 'Nenhuma entrada detectada';

  @override
  String get reorderSectionsHint =>
      'Selecione com ◄ / ► e use ▲ / ▼ para reordenar. Cruze o limite da lista para ocultar ou mostrar uma seção.';

  @override
  String get customName => 'Nome personalizado';

  @override
  String get mostUsed => 'Frequência de lançamento';

  @override
  String get lastUsed => 'Último uso';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String get allCaughtUp => 'Todos apanhados!';

  @override
  String get notificationAccessAdb => 'Acesso à notificação (ADB necessário)';

  @override
  String get openAppInfo => 'Abra as informações do aplicativo';

  @override
  String get overlayPermission => 'Permissão de sobreposição';

  @override
  String get clockMinimal => 'Mínimo';

  @override
  String get clockMinimalDescription => 'Fonte fina e elegante (padrão)';

  @override
  String get clockBold => 'Ousado';

  @override
  String get clockBoldDescription => 'Fonte espessa e altamente visível';

  @override
  String get clockRetro => 'Retrô';

  @override
  String get clockRetroDescription => 'Estilo de terminal retro monoespaçado';

  @override
  String get clockElegant => 'Elegante';

  @override
  String get clockElegantDescription => 'Tipo de letra serif clássico';

  @override
  String get clockNeon => 'Néon';

  @override
  String get clockNeonDescription => 'Estilo ultrafino e brilhante';

  @override
  String get clockPixel => 'Pixel';

  @override
  String get clockPixelDescription =>
      'Sensação de arcade ousada e monoespaçada';

  @override
  String get clockDigital => 'Digitais';

  @override
  String get clockDigitalDescription => 'Tela monoespaçada limpa';

  @override
  String get themeDefault => 'Padrão';

  @override
  String get themePremium => 'Prêmio';

  @override
  String get themeClassic => 'Clássico';

  @override
  String get themeCapsule => 'Cápsula';

  @override
  String get cancel => 'Cancelar';

  @override
  String get actionCancelled => 'Ação cancelada';

  @override
  String get ok => 'OK';

  @override
  String get accessibilityGuide =>
      'Abra as configurações da TV manualmente, em Acessibilidade → CuteLauncher Home Button Fix e ative o serviço. A localização e o nome deste menu dependem do fabricante da sua TV.';

  @override
  String get notificationPermissionGuide =>
      'Não foi possível abrir as configurações de acesso às notificações nesta TV. Permitir notificações de saída nas Informações do aplicativo não concede acesso a notificações de outros aplicativos.\n\nConecte sua TV via ADB e execute:';

  @override
  String get overlayPermissionGuide =>
      'As configurações de permissão de sobreposição não puderam ser abertas automaticamente.\n\nPara ativar pop-ups em outros aplicativos, conecte sua TV via ADB e execute:';

  @override
  String get watchNextPermissionGuide =>
      'Para ler cartões Continuar assistindo de outros aplicativos, Android TV requer READ_WRITE_WATCH_NEXT_PROGRAMS.\n\nConecte sua TV via ADB e execute:';

  @override
  String get watchNextAccess => 'Continuar assistindo acesso';

  @override
  String itemsCount(int count) {
    return 'Itens $count';
  }

  @override
  String displayUpToItems(int count) {
    return 'Exibir até itens recentes do $count';
  }

  @override
  String get unlimitedItems => 'Ilimitado';

  @override
  String get allAvailableItems => 'Exibir todos os itens disponíveis';

  @override
  String get defaultOption => 'Padrão';

  @override
  String get manage => 'Gerenciar';

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
    return 'Bloqueado para continuar assistindo ($count)';
  }

  @override
  String get sizeExtraSmall => 'Extra pequeno';

  @override
  String get sizeVerySmall => 'Muito pequeno';

  @override
  String get sizeSmall => 'Pequeno';

  @override
  String get sizeCompact => 'Compacto';

  @override
  String get sizeMediumSmall => 'Médio Pequeno';

  @override
  String get sizeMedium => 'Médio';

  @override
  String get sizeStandardDefault => 'Padrão (padrão)';

  @override
  String get sizeMediumLarge => 'Médio Grande';

  @override
  String get sizeLarge => 'Grande';

  @override
  String get sizeVeryLarge => 'Muito Grande';

  @override
  String get sizeExtraLarge => 'Extra Grande';

  @override
  String get sizeHuge => 'Enorme';

  @override
  String get tvApps => 'Aplicativos de TV';

  @override
  String get nonTvApps => 'Aplicativos que não são de TV';

  @override
  String get moviesShows => 'Filmes e programas';

  @override
  String get music => 'Música';

  @override
  String get games => 'Jogos';

  @override
  String get entertainment => 'Entretenimento';

  @override
  String get liveTv => 'TV ao vivo';

  @override
  String get sports => 'Esportes';

  @override
  String get news => 'Notícias';

  @override
  String get tools => 'Ferramentas';

  @override
  String get favorites => 'Favoritos';

  @override
  String get customSectionName => 'Personalizado...';

  @override
  String get selectSectionName => 'Selecione um nome';

  @override
  String get weeklyUsage => 'Semanalmente:';

  @override
  String get monthlyUsage => 'Mensalmente:';

  @override
  String get dailyUsage => 'Diariamente:';

  @override
  String get appError => 'Algo deu errado';

  @override
  String get weatherRain => 'Chuva';

  @override
  String get weatherSnow => 'Neve';

  @override
  String get weatherStorm => 'Tempestade';

  @override
  String get weatherToday => 'hoje';

  @override
  String get weatherTomorrow => 'amanhã';

  @override
  String weatherOnDay(String day) {
    return 'em $day';
  }

  @override
  String weatherWarning(String probability, String condition, String day) {
    return '$probability$condition $day';
  }

  @override
  String get backupShareTitle => 'Backup CuteLauncher';

  @override
  String get noApplicationsFound => 'Nenhum aplicativo encontrado';

  @override
  String get invalidDateFormat => 'Formato inválido';

  @override
  String get selectDateFormats => 'Selecione os formatos abaixo';

  @override
  String activeItemsCount(int count) {
    return '$count item(s) ativo(s)';
  }

  @override
  String get colorPurple => 'Roxo';

  @override
  String get colorTeal => 'Azul-petróleo';

  @override
  String get colorBlue => 'Azul';

  @override
  String get colorOrange => 'Laranja';

  @override
  String get colorPink => 'Rosa';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorWhite => 'Branco';

  @override
  String get colorYellow => 'Amarelo';

  @override
  String get colorRed => 'Vermelho';

  @override
  String get colorCyan => 'Ciano';

  @override
  String get colorIndigo => 'Índigo';

  @override
  String get colorLime => 'Limão';

  @override
  String get colorAmber => 'Âmbar';

  @override
  String get colorRose => 'Rosa';

  @override
  String get colorIceBlue => 'Azul Gelo';

  @override
  String get memoryFeatures => 'Memória por recurso (caches)';

  @override
  String get memoryAppIcons => 'Ícones de aplicativos';

  @override
  String get memoryAppBanners => 'Banners de aplicativos';

  @override
  String get memoryWatchNextPosters => 'Continue assistindo pôsteres';

  @override
  String get memoryOtherCaches => 'Outros caches de imagens codificadas';

  @override
  String get memoryFeaturesExplanation =>
      'São bytes de imagem retidos, já incluídos no total do cache codificado. Zero significa que não há bytes retidos nesse cache, e não que o recurso não use memória. Os papéis de parede e as imagens exibidas compartilham o cache decodificado acima; imagens ativas podem estar fora dele. O clima, as notificações, os objetos Dart e o mecanismo não podem ser divididos por recurso aqui. Os gráficos de interface compartilhada são relatados acima por Android e já incluídos em PSS. A memória deles faz parte do processo total. Não adicione esses valores sobrepostos.';

  @override
  String get memoryGraphics => 'Gráficos de interface (incluídos em PSS)';

  @override
  String get categoryVisible => 'Mostrar categoria';

  @override
  String get hiddenCategories => 'Categorias ocultas';

  @override
  String get visibleCategories => 'Categorias visíveis';

  @override
  String get backupSavedToSelectedLocation =>
      'Backup salvo no local selecionado';

  @override
  String get tileHorizontalGap => 'Espaçamento horizontal';

  @override
  String get tileVerticalGap => 'Espaçamento vertical';

  @override
  String get tileOpacity => 'Opacidade de fundo';

  @override
  String get tileShadow => 'Sombra';

  @override
  String get tileCornerRadius => 'Arredondamento de canto';

  @override
  String get tileIconScale => 'Tamanho do ícone';

  @override
  String get tileBackgroundColor => 'Fundo do ladrilho';

  @override
  String get tileLabelSize => 'Tamanho da etiqueta';

  @override
  String get resetAppearance => 'Redefinir aparência';

  @override
  String get tileAppearance => 'Aparência do ladrilho';

  @override
  String get tileLabelColor => 'Cor da etiqueta';

  @override
  String get tilePreviewName => 'Exemplo de aplicação';

  @override
  String get tileProportions => 'Proporções do ladrilho';

  @override
  String get tileLarge => 'Grande';

  @override
  String get tileLabelBelow => 'Abaixo do ladrilho';

  @override
  String get tileLabelInside => 'Dentro do azulejo';

  @override
  String get tileFocusScale => 'Ampliar';

  @override
  String get tileMedium => 'Médio';

  @override
  String get tileFocusBorder => 'Nenhum movimento';

  @override
  String get tileSize => 'Tamanho do ladrilho';

  @override
  String get tileCompact => 'Compacto';

  @override
  String get tileLabelPosition => 'Posição da etiqueta';

  @override
  String get tileFocusEffect => 'Efeito de foco';

  @override
  String get tileFocusStrength => 'Intensidade de destaque';

  @override
  String get panelIndependent => 'Configurações personalizadas';

  @override
  String get panelAppearance => 'Estilo do painel superior';

  @override
  String get panelBackground => 'Fundo do painel';

  @override
  String get blurPerformanceHint =>
      'O desfoque pode reduzir a suavidade. Ele fica desativado enquanto a economia de memória está ativada.';

  @override
  String get panelOpacity => 'Opacidade do painel';

  @override
  String get tileBlur => 'Desfocar atrás dos azulejos';

  @override
  String get panelBlur => 'Desfoque atrás do painel superior';

  @override
  String get panelShared => 'Como painéis';

  @override
  String get weatherMinutes => 'min';

  @override
  String get weatherOpenMeteoCredit =>
      'Tempo: Open-Meteo (open-meteo.com), CC BY 4.0. API gratuito para uso não comercial.';

  @override
  String get weatherRateLimit =>
      'Limite de solicitações atingido. Tente mais tarde.';

  @override
  String get weatherYandexCredit =>
      'Tempo: Tempo Yandex (yandex.ru/pogoda). O acesso depende do seu plano API.';

  @override
  String get yandexWeather => 'Tempo Yandex (REST)';

  @override
  String get weatherAuthorizationError =>
      'O provedor de meteorologia rejeitou o pedido. Verifique a chave API e o acesso ao serviço selecionado.';

  @override
  String get weatherYandexHint =>
      'Requer uma chave com acesso de previsão REST. Uma chave para outro plano Yandex pode não funcionar.';

  @override
  String get weatherSource => 'Fonte meteorológica';

  @override
  String get weatherInterval => 'Intervalo de atualização';

  @override
  String get weatherLongitude => 'Longitude (-180 a 180)';

  @override
  String get weatherKeyRequired => 'Adicione uma chave Yandex API.';

  @override
  String get weatherLocationName => 'Nome da cidade (opcional)';

  @override
  String get weatherLocation => 'Localização';

  @override
  String get weatherApiKey => 'Chave Yandex API';

  @override
  String get weatherInvalidResponse =>
      'A fonte meteorológica retornou dados inválidos.';

  @override
  String get weatherUnavailable =>
      'O tempo não está disponível. Os dados recebidos anteriormente são retidos, se disponíveis. As novas tentativas são limitadas a uma vez a cada 5 minutos.';

  @override
  String get weatherStale => 'Clima anterior';

  @override
  String get weatherLatitude => 'Latitude (-90 a 90)';

  @override
  String get weatherCoordinatesError =>
      'Escolha uma cidade, informe as coordenadas ou detecte a localização automaticamente.';

  @override
  String get weatherRefresh => 'Atualizar meteorologia';

  @override
  String get weatherKeyPrivate =>
      'Armazenado apenas neste dispositivo, excluído dos backups. A entrada vazia remove a chave.';

  @override
  String get weatherUpdated => 'Atualizado';

  @override
  String get onlineWallpaperError =>
      'Não foi possível carregar esta imagem. O papel de parede anterior é mantido. Selecione “Atualizar fundo” para tentar novamente o download.';

  @override
  String get onlineWallpaperHint =>
      'A última imagem é mantida para uso sem conexão (até 8 MiB).';

  @override
  String get onlineWallpaperHours => 'h';

  @override
  String get onlineWallpaperInterval => 'Intervalo de download';

  @override
  String get onlineWallpaper => 'Papel de parede on-line';

  @override
  String get onlineWallpaperUrlError =>
      'Insira uma imagem HTTPS direta URL sem detalhes de login.';

  @override
  String get onlineWallpaperEnabled => 'Use papel de parede online';

  @override
  String get onlineWallpaperSource => 'Fonte da imagem';

  @override
  String get bingWallpaper => 'Imagem Bing do dia';

  @override
  String get onlineWallpaperUrlSource => 'Direto HTTPS URL';

  @override
  String get updatePlayOnly =>
      'Esta instalação recebe atualizações por meio do Google Play.';

  @override
  String get updateCheck => 'Verifique agora';

  @override
  String get updateInstalled => 'Instalado';

  @override
  String get updateDownloadInstall => 'Baixe e instale';

  @override
  String get updateNoRelease =>
      'Nenhuma versão compatível mais recente está disponível.';

  @override
  String get updateIncompatible =>
      'O APK não corresponde a este aplicativo, certificado ou versão mais recente. A instalação foi bloqueada.';

  @override
  String get updateError =>
      'Não foi possível verificar, baixar ou abrir o instalador. Tente novamente mais tarde.';

  @override
  String get updateAvailable => 'Atualização disponível';

  @override
  String get appUpdates => 'Atualizações de aplicativos';

  @override
  String get updatePermission =>
      'Permita a instalação deste aplicativo nas configurações do Android, volte aqui e pressione Instalar novamente.';

  @override
  String get updateInstall => 'Instale a atualização baixada';

  @override
  String get updateHint =>
      'Fonte: GitHub/KirillShchetinnikov/CuteLauncher-Releases. As verificações automáticas são executadas enquanto o inicializador está aberto. O download começa quando você escolhe; Android solicita que você confirme a instalação. Seus dados são mantidos.';

  @override
  String get updateAutomatic => 'Verifique automaticamente uma vez por dia';

  @override
  String get allApplications => 'Todos os aplicativos';

  @override
  String get adbAccessibility => 'Habilitar correção do botão Home';

  @override
  String get adbAuthorization =>
      'Aprove a autorização ADB na TV e tente novamente.';

  @override
  String get adbChangeConfirm =>
      'Aplicar esta configuração do sistema através do ADB? O app Home anterior é salvo antes de alterá-lo; outros serviços de acessibilidade são preservados.';

  @override
  String get adbCheck => 'Verifique a conexão';

  @override
  String get adbDenied =>
      'O sistema não permitiu nem confirmou esta alteração.';

  @override
  String get adbDisable => 'Desative o inicializador anterior';

  @override
  String get adbDisableConfirm =>
      'Desativar o inicializador anterior salvo? Isso requer que CuteLauncher seja o aplicativo Home atual. Restaure-o com a ação de recuperação nesta configuração.';

  @override
  String get adbHint =>
      'Protótipo apenas para esta TV (127.0.0.1). Habilite TCP ADB nas opções do desenvolvedor, insira sua porta e aprove o prompt de autorização na TV. A depuração sem fio com um código de emparelhamento ainda não é suportada. A chave privada permanece neste dispositivo, fora dos backups.';

  @override
  String get adbHome => 'Faça do CuteLauncher o aplicativo Home';

  @override
  String get adbInvalid => 'Insira uma porta entre 1024 e 65535.';

  @override
  String get adbNoRecovery =>
      'A restauração não está disponível: nenhum outro iniciador ou estado de serviço salvo foi encontrado.';

  @override
  String get adbPort => 'Porta TCP ADB';

  @override
  String get adbReady => 'Acesso ADB confirmado.';

  @override
  String get adbRestore => 'Restaurar o inicializador anterior';

  @override
  String get adbSuccess => 'Alteração aplicada e verificada.';

  @override
  String get adbTitle => 'Configuração ADB';

  @override
  String get adbUnavailable =>
      'Não foi possível conectar. Verifique o TCP ADB, a porta e o prompt de autorização.';

  @override
  String get nightModeScheduled => 'Usar agendamento';

  @override
  String get nightModeTitle => 'Modo noturno';

  @override
  String get nightModeScope =>
      'A permissão de sobreposição é necessária para escurecer outros aplicativos. Sem ele, o escurecimento funciona dentro do CuteLauncher. O filtro TCL não precisa de permissão de sobreposição. Acima de 80% de opacidade, Android pode bloquear a entrada por toque em outros aplicativos; As teclas do controle remoto da TV ainda funcionam.';

  @override
  String get nightModeEnd => 'Fim';

  @override
  String get nightModeStart => 'Começar';

  @override
  String get nightModeDim => 'Escurecimento';

  @override
  String get nightModeWarmth => 'Filtro quente';

  @override
  String get nightModeScheduleHint =>
      'Usa o horário local da TV. Os períodos noturnos são suportados. Horários de início e término iguais desativam o filtro programado.';

  @override
  String get nightModeEnabled => 'Ativar modo noturno';

  @override
  String get nightModePermission =>
      'Permitir exibição sobre outros aplicativos';

  @override
  String get nightModePermissionGranted =>
      'Exibição sobre outros aplicativos permitida';

  @override
  String get backupDownloadsFailed =>
      'Não foi possível salvar o backup em Downloads.';

  @override
  String get backupSaveDownloads => 'Salvar backup em downloads';

  @override
  String get adbRestoreAccessibility => 'Restaurar o acesso de acessibilidade';

  @override
  String get nightModeAdbConfirm =>
      'Permitir que CuteLauncher seja exibido sobre outros aplicativos usando ADB local? Habilite primeiro a depuração TCP e autorize a conexão. Usa a porta salva no assistente ADB ou 5555.';

  @override
  String get nightModeAdbPermission => 'Conceda permissão por meio de ADB';

  @override
  String get nightModeNotificationsHint =>
      'A notificação permite desligar o filtro fora do CuteLauncher. Sem ele, use este menu.';

  @override
  String get nightModeNotificationsAllowed =>
      'Notificação de modo noturno permitida';

  @override
  String get nightModeNotifications => 'Permitir notificação do modo noturno';

  @override
  String get categoryLastVisibleHint =>
      'Pelo menos uma categoria deve permanecer visível.';

  @override
  String get diagnosticsClear => 'Limpar diagnóstico de sessão';

  @override
  String get diagnosticsReady => 'Relatório pronto';

  @override
  String get diagnosticsCreate => 'Criar relatório';

  @override
  String get diagnosticsOperations => 'Operações registradas';

  @override
  String get diagnosticsCopied => 'Relatório copiado';

  @override
  String get diagnosticsSharingNotice =>
      'Envie o ficheiro ao autor por mensagem privada, sem o publicar: a limpeza automática pode deixar dados pessoais. Ao enviá-lo, aceita a publicação de um relatório anónimo de compatibilidade da TV no repositório Git do CuteLauncher. Apenas metadados do dispositivo e disponibilidade das funções serão publicados, sem dados pessoais; registos de erros, comandos e as suas definições não serão publicados.\n\nO relatório também inclui pacotes instalados, nomes, versões e estado de ativação, além dos nomes, conteúdo, ordem e visibilidade das seções. Identificadores e nomes são mantidos para diagnóstico; essas listas não são publicadas.';

  @override
  String get diagnosticsHint =>
      'Um único relatório reúne compatibilidade das funções da TV e diagnóstico de erros. O relatório inclui modelo e firmware da TV, versão da aplicação, permissões, memória, etapas e causas de erros, comandos e respostas com remoção automática de dados pessoais. Guarda as últimas 50 operações, até 100 falhas separadamente e um registo ADB limitado da sessão. Reiniciar apaga o registo. Podem restar dados pessoais: envie o ficheiro por mensagem privada, sem o publicar. Nada é enviado automaticamente. Cada erro conserva uma cópia das definições aplicadas; alterações posteriores não a substituem.\n\nO relatório também inclui pacotes instalados, nomes, versões e estado de ativação, além dos nomes, conteúdo, ordem e visibilidade das seções. Identificadores e nomes são mantidos para diagnóstico; essas listas não são publicadas.';

  @override
  String get diagnosticsTitle => 'Diagnóstico de erros';

  @override
  String get diagnosticsCopyFailed => 'Não foi possível copiar o relatório.';

  @override
  String get diagnosticsCopy => 'Copiar relatório';

  @override
  String get diagnosticsCreating => 'Criando relatório…';

  @override
  String get tclBlueLightTitle => 'Filtro de luz azul TCL';

  @override
  String get tclBlueLightError =>
      'Não foi possível ler ou verificar a configuração do filtro TCL. Atualize seu estado e tente novamente.';

  @override
  String get tclBlueLightUnsupported =>
      'A interface do filtro TCL não está disponível nesta TV.';

  @override
  String get tclBlueLightRefresh => 'Atualizar estado do filtro TCL';

  @override
  String get tclBlueLightHint =>
      'Controla o filtro integrado de proteção à saúde ocular da TV. Também pode seguir a programação do modo noturno.';

  @override
  String get nightSolarSchedule => 'Pôr do sol e nascer do sol';

  @override
  String get nightNextStart => 'Próximo início';

  @override
  String get nightScheduleTimeHint =>
      'Os horários usam o fuso horário da TV. As compensações negativas são anteriores; os deslocamentos positivos são posteriores.';

  @override
  String get nightTemperature => 'Filtrar temperatura de cor';

  @override
  String get nightScheduleSettings => 'Configurações de agendamento';

  @override
  String get nightCityName => 'Nome da cidade';

  @override
  String get nightSkipUntilNext =>
      'Desative o modo noturno até o próximo pôr do sol';

  @override
  String get nightSunriseOffset => 'Fim em relação ao nascer do sol';

  @override
  String get nightEnableUntilMorning =>
      'Ative o modo noturno até o próximo nascer do sol';

  @override
  String get nightPermissions => 'Permissões';

  @override
  String get nightTclSchedule => 'Incluir filtro TCL no cronograma';

  @override
  String get nightSearchCity => 'Pesquisar';

  @override
  String get nightRefreshSun => 'Atualizar o nascer e o pôr do sol';

  @override
  String get nightSolarUnavailable =>
      'Escolha uma cidade e atualize os horários de sol. Se o nascer ou o pôr do sol não estiverem disponíveis, a programação solar será pausada.';

  @override
  String get nightSunsetOffset => 'Comece em relação ao pôr do sol';

  @override
  String get nightCityHint =>
      'Escolha sua cidade em vez de conceder acesso ao local. As coordenadas selecionadas são enviadas para Sunrise-Sunset.org, ou GeoNames como alternativa, para recuperar os horários do sol.';

  @override
  String get nightResumeSchedule => 'Voltar ao cronograma';

  @override
  String get nightScheduleSource => 'Tipo de agendamento';

  @override
  String get nightSolarCached =>
      'Usando horários de sol em cache; a atualização da Internet tentará novamente automaticamente.';

  @override
  String get nightTclScheduleHint =>
      'Usa a mesma programação enquanto o modo noturno está ativado. As alterações manuais no filtro TCL duram até a próxima transição agendada. Nenhuma permissão de sobreposição é necessária.';

  @override
  String get nightRefreshPermission => 'Atualizar status de permissão';

  @override
  String get nightCityNotFound =>
      'Nenhuma cidade encontrada. Tente outro nome.';

  @override
  String get nightNoOffset => 'Sem deslocamento';

  @override
  String get nightManualSchedule => 'Agenda personalizada';

  @override
  String get nightChooseCity => 'Escolha a cidade';

  @override
  String get nightPermissionUnknown =>
      'O status da permissão de sobreposição é desconhecido';

  @override
  String get nightNextEnd => 'Próximo fim';

  @override
  String get nightTemporaryOff => 'Escurecer temporariamente desligado até';

  @override
  String get nightCitySearchFailed =>
      'Não foi possível pesquisar cidades. Verifique sua conexão com a Internet.';

  @override
  String get nightSolarAttribution =>
      'Os horários do nascer e do pôr do sol vêm de Sunrise-Sunset.org ou, se falhar, de GeoNames. Sem internet, a TV calcula os horários que faltam.';

  @override
  String get nightTemporaryOn => 'Escurecimento temporariamente ativado até';

  @override
  String get homeScreen => 'Tela inicial';

  @override
  String get appearanceSettings => 'Aparência';

  @override
  String get generalSettings => 'Avançado';

  @override
  String get advancedSettings => 'Avançado';

  @override
  String get controlAndStartup => 'Controles do iniciador e da TV';

  @override
  String get sectionsAndOrder => 'Seções e ordem';

  @override
  String get topPanel => 'Painel superior';

  @override
  String get tileStyle => 'Estilo de bloco';

  @override
  String get tilesAndLabels => 'Azulejos e rótulos';

  @override
  String get highlightAndAnimation => 'Destaque e animação';

  @override
  String get androidTvSettings => 'Configurações Android TV';

  @override
  String get weatherSettings => 'Configurações de clima';

  @override
  String get showHighlightOutline => 'Mostrar contorno de destaque';

  @override
  String get resetTilesAndPanel => 'Redefinir configurações de bloco e painel';

  @override
  String get resetTilesAndPanelHint =>
      'Redefinir parâmetros adicionais de bloco, rótulo, destaque e painel superior? O papel de parede, a cor de destaque, o estilo do bloco e a visibilidade da etiqueta são preservados.';

  @override
  String get panelAppearanceSettings => 'Aparência do painel superior';

  @override
  String get panelSharedHint =>
      'Altere a aparência nas configurações do bloco.';

  @override
  String get effectsCompatibilityHint =>
      'Aparência adicional: o contorno está sempre visível e não pulsa. O estilo dimensional não possui contorno legado; clássico não pulsa. A intensidade afeta a escala e a sombra; a escala é limitada pelo espaço.';

  @override
  String get sizeAndLayout => 'Tamanho e layout';

  @override
  String get labelsGroup => 'Etiquetas';

  @override
  String get surfaceGroup => 'Superfície';

  @override
  String get clockAndDateGroup => 'Relógio e data';

  @override
  String get networkAndTrafficGroup => 'Rede e tráfego';

  @override
  String get buttonsGroup => 'Botões';

  @override
  String get notificationAppsHint =>
      'Selecione as aplicações cujas notificações pretende bloquear. Um interruptor ativo significa bloqueio. A lista mantém a ordem alfabética.';

  @override
  String get notificationPanelLink => 'Aparência do painel superior';

  @override
  String get overlayAccessAdb => 'Exibir sobre outros aplicativos (ADB)';

  @override
  String get tileStyleModern => 'Moderno';

  @override
  String get tileStyleVolume => 'Dimensional';

  @override
  String get showTime => 'Hora do show';

  @override
  String get showDate => 'Mostrar data';

  @override
  String get showWeather => 'Mostrar clima';

  @override
  String get showNetwork => 'Mostrar status da rede';

  @override
  String get showTraffic => 'Mostrar tráfego';

  @override
  String get scheduledBrightness => 'Brilho programado';

  @override
  String get followTileStyle => 'Siga o estilo';

  @override
  String get androidTvSettingsHint => 'Abra as configurações do sistema de TV';

  @override
  String get autoHideTopPanel => 'Ocultar automaticamente o painel';

  @override
  String get showSectionTitles => 'Mostrar títulos de seções';

  @override
  String get usageDaily => 'Diariamente';

  @override
  String get usageWeekly => 'Semanalmente';

  @override
  String get usageMonthly => 'Mensalmente';

  @override
  String get onlineWallpaperAddress => 'Endereço da imagem (HTTPS)';

  @override
  String get watchNextAppLimits => 'Limites por aplicativo';

  @override
  String get watchNextAppLimitsHint =>
      'Os limites de origem aplicam-se antes do limite geral. Ilimitado mantém apenas o limite geral; o conteúdo oculto permanece oculto.';

  @override
  String get rememberCategoryFocus => 'Lembre-se do último cartão em foco';

  @override
  String get automaticBackups => 'Cópias e sincronização';

  @override
  String get automaticBackupsHint =>
      'Cópias diárias de configurações, papéis de parede e banners enquanto o inicializador estiver ativo. Uma cópia perdida é executada após retornar ao inicializador. Armazenado de forma privada neste dispositivo, até 256 MiB no total; remover o aplicativo ou seus dados os exclui. Mantenha um backup externo também.';

  @override
  String get automaticBackupsEnabled => 'Backup automático diário';

  @override
  String get automaticBackupsKeep => 'Cópias para guardar';

  @override
  String get automaticBackupCreateNow => 'Crie um ponto de restauração agora';

  @override
  String get automaticBackupFailed =>
      'A operação de backup falhou. Verifique o espaço livre e tente novamente.';

  @override
  String get restorePoints => 'Pontos de restauração';

  @override
  String get noRestorePoints => 'Ainda não há pontos de restauração';

  @override
  String get updatePrereleases => 'Atualizar para versões de pré-lançamento';

  @override
  String get topPanelObjects => 'Objetos';

  @override
  String get panelTransparency => 'Transparência do painel';

  @override
  String get panelTextBackground => 'Fundo de texto e botão';

  @override
  String get panelTextBackgroundColor => 'Cor de fundo do texto e do botão';

  @override
  String get panelTextColor => 'Cor do texto e do botão';

  @override
  String get panelTextSize => 'Tamanho do texto e do botão';

  @override
  String get panelFont => 'Fonte do texto';

  @override
  String get fontSans => 'Sem serifa';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontMono => 'Monoespaçado';

  @override
  String get fontCondensed => 'Condensado';

  @override
  String get trafficPermissionGranted =>
      'Acesso às estatísticas de tráfego concedido';

  @override
  String get background => 'Plano de fundo';

  @override
  String get backgroundParameters => 'Definições da fonte';

  @override
  String get resetAppearanceHint =>
      'Redefinir plano de fundo, destaque, blocos, rótulos, realce e animação?';

  @override
  String get wallpaperDimming => 'Intensidade do escurecimento';

  @override
  String get wallpaperPlacement => 'Colocação';

  @override
  String get wallpaperDisplay => 'Exibição de papel de parede';

  @override
  String get wallpaperContain => 'Mostrar imagem inteira';

  @override
  String get wallpaperBlurred => 'Sobre cópia borrada';

  @override
  String get wallpaperCover => 'Preencher tela';

  @override
  String get wallpaperBrightness => 'Brilho do papel de parede';

  @override
  String get wallpaperSaturation => 'Saturação';

  @override
  String get categoryPadding => 'Preenchimento de categoria';

  @override
  String get categoryLight => 'Luz';

  @override
  String get categoryBlue => 'Azul';

  @override
  String get categoryPurple => 'Roxo';

  @override
  String get categoryAllRows => 'Todos';

  @override
  String get categoryTeal => 'Azul-petróleo';

  @override
  String get categoryMaxRows => 'Linhas de grade visíveis';

  @override
  String get categoryDark => 'Escuro';

  @override
  String get categoryAppearance => 'Aparência da categoria';

  @override
  String get categoryBackground => 'Histórico da categoria';

  @override
  String get categoryTransparent => 'Transparente';

  @override
  String get slideshowInterval => 'Intervalo de mudança';

  @override
  String get slideshowFolderSelected =>
      'Acesso à pasta salvo neste dispositivo.';

  @override
  String get slideshowRandom => 'Ordem aleatória';

  @override
  String get wallpaperSlideshow => 'Apresentação de slides de pasta';

  @override
  String get slideshowNext => 'Próxima imagem';

  @override
  String get slideshowFolderRequired =>
      'Escolha uma pasta para iniciar a apresentação de slides.';

  @override
  String get slideshowHint =>
      'Até 1.000 imagens e 4.000 entradas de pasta; arquivos de até 8 MiB. Os arquivos corrompidos são ignorados e a última imagem boa é mantida. As alterações param em segundo plano. Escolha a pasta novamente após restaurar em outro dispositivo.';

  @override
  String get slideshowSeconds => 'é';

  @override
  String get slideshowError =>
      'Não é possível ler imagens. Escolha uma pasta acessível contendo imagens válidas.';

  @override
  String get slideshowFolder => 'Escolha a pasta';

  @override
  String get slideshowRecursive => 'Incluir subpastas';

  @override
  String get weatherSourceKeyRequired =>
      'Adicione uma chave API para esta fonte meteorológica.';

  @override
  String get weatherOpenWeatherCredit =>
      'Tempo: OpenWeather (openweathermap.org). Os valores diários resumem os períodos de previsão de três horas disponíveis.';

  @override
  String get weatherOpenWeatherHint =>
      'Use sua chave para o clima atual e previsão de 5 dias/3 horas. Cada atualização faz duas solicitações; o acesso e os limites dependem do seu plano.';

  @override
  String get weatherOpenWeatherKey => 'Chave OpenWeather API';

  @override
  String get mediaPause => 'Pausa';

  @override
  String get showNowPlaying => 'Mostrar agora tocando na página inicial';

  @override
  String get nowPlayingAccessHint =>
      'Os controles de mídia exigem acesso de notificação para CuteLauncher. Apenas as ações fornecidas pelo jogador são mostradas.';

  @override
  String get nowPlaying => 'Agora jogando';

  @override
  String get mediaNext => 'Próxima faixa';

  @override
  String get mediaPlay => 'Currículo';

  @override
  String get mediaControlError =>
      'O jogador está indisponível ou não aceitou esta ação.';

  @override
  String get nightUsageAccess => 'Permitir acesso de uso';

  @override
  String get nightExcludedAppsHint =>
      'A sobreposição e o filtro TCL programado pausam em aplicativos selecionados. O acesso de uso é necessário; sem ele, as exclusões não podem ser aplicadas.';

  @override
  String get nightExcludedApps => 'Aplicativos excluídos';

  @override
  String get adbPairPort => 'Porta de emparelhamento';

  @override
  String get adbPairOverlayHint =>
      'Abra a depuração sem fio e emparelhe com o código de emparelhamento. Mantenha a caixa de diálogo do código do sistema aberta. Este formulário fica ativo após 30 segundos. Insira ambas as portas e o código mostrado por Android.';

  @override
  String get adbOverlaySettings =>
      'Retorne o controle às configurações por 30 segundos';

  @override
  String get adbTlsHint =>
      'Use a depuração sem fio nas opções do desenvolvedor. O emparelhamento e a conexão possuem portas diferentes. Se o seu firmware não tiver tela de código de emparelhamento ou bloquear janelas de sobreposição, use TCP/RSA. Todas as conexões permanecem locais para esta TV.';

  @override
  String get adbPaired =>
      'Emparelhado. Verifique a conexão usando a porta de conexão de depuração sem fio.';

  @override
  String get adbTransport => 'Método de conexão';

  @override
  String get adbPairCode => 'Código de seis dígitos';

  @override
  String get adbOverlayRequired =>
      'A entrada de código nas configurações requer permissão para exibição em outros aplicativos.';

  @override
  String get adbOverlayPermission =>
      'Permitir exibição sobre outros aplicativos';

  @override
  String get adbTlsUnsupported =>
      'Este firmware não pode abrir a tela de configurações necessária ou a sobreposição de emparelhamento. Utilize TCP/RSA.';

  @override
  String get adbConnectPort => 'Porta de conexão';

  @override
  String get adbTls => 'TLS/código de emparelhamento';

  @override
  String get adbTcp => 'TCP/RSA';

  @override
  String get adbPairingFailed =>
      'O emparelhamento falhou. Verifique o código e a porta de emparelhamento, mantenha a caixa de diálogo do código Android aberta e tente novamente.';

  @override
  String get adbTlsDisabled =>
      'A depuração sem fio está desativada ou seu estado não está disponível. Habilite-o nas opções do desenvolvedor.';

  @override
  String get adbPairOverlay =>
      'Insira o código de emparelhamento em Configurações';

  @override
  String get adbPair => 'Par';

  @override
  String get adbDeveloperSettings => 'Abra as opções do desenvolvedor';

  @override
  String get adbTwoWindowsHint =>
      'Se este firmware suportar duas janelas, mantenha a caixa de diálogo de emparelhamento do sistema aberta ao lado de CuteLauncher e insira seu código aqui. O emparelhamento direto está disponível apenas enquanto ambas as janelas estão abertas.';

  @override
  String get adbTwoWindows => 'Abra Configurações em uma segunda janela';

  @override
  String get autoLaunchBoot => 'Após a inicialização da TV';

  @override
  String get autoLaunchOff => 'Desativado';

  @override
  String get autoLaunchTitle => 'Início automático';

  @override
  String get autoLaunchDelay => 'Atraso no lançamento';

  @override
  String get autoLaunchHdmi => 'Alternar para uma entrada HDMI selecionada';

  @override
  String get autoLaunchWake => 'Depois de acordar';

  @override
  String get autoLaunchHint =>
      'Escolha um aplicativo ou entrada HDMI para abrir após a inicialização ou ativação da TV. Defina o evento e o atraso abaixo. A ação é executada uma vez quando Android mostra CuteLauncher. Qualquer entrada remota ou saída da tela inicial cancela a espera. Você pode alterar livremente as entradas do HDMI posteriormente. Defina CuteLauncher como o inicializador padrão ou ative Iniciar na inicialização, se necessário. A detecção de ativação requer que o CuteLauncher permaneça em execução.';

  @override
  String autoLaunchSeconds(int seconds) {
    return '$seconds segundos';
  }

  @override
  String get autoLaunchApp => 'Abra um aplicativo selecionado';

  @override
  String get autoLaunchTarget => 'Alvo de lançamento';

  @override
  String get autoLaunchUnavailable =>
      'O destino não está disponível ou o firmware não permite esta ação.';

  @override
  String get autoLaunchCancelled => 'Lançamento atrasado cancelado.';

  @override
  String get syncTitle => 'Configurações de troca';

  @override
  String get syncHint =>
      'Salve um arquivo de configurações, transfira-o para outro dispositivo e abra-o lá. Troque o arquivo de volta para atualizar os dois dispositivos. Interface, estilo de bloco e preferências de exibição são compartilhados. Aplicativos, seções, arquivos de papel de parede, permissões, HOME, regras de inicialização e segredos permanecem neste dispositivo. Esta é uma troca manual; nenhuma conta ou conexão de rede em segundo plano é usada.';

  @override
  String get syncExport => 'Salvar alterações em um arquivo';

  @override
  String get syncImport => 'Abra alterações de outro dispositivo';

  @override
  String get syncSaved => 'Arquivo de troca de configurações salvo.';

  @override
  String get syncFailed =>
      'Não é possível trocar configurações. Nenhuma importação parcial é mantida. Verifique o arquivo ou abra-o novamente se as configurações foram alteradas durante a revisão.';

  @override
  String get syncPreviewHint =>
      'Revise as alterações antes de aplicar. Para conflitos, selecione cada linha para escolher este dispositivo ou arquivo. Manter este dispositivo é selecionado inicialmente. Cancelar deixa as configurações inalteradas.';

  @override
  String get syncNoChanges =>
      'Sem novas configurações. Inscreva-se para reconhecer o histórico compartilhado.';

  @override
  String syncLocalValue(String value) {
    return 'Este dispositivo: $value';
  }

  @override
  String syncFileValue(String value) {
    return 'Do arquivo: $value';
  }

  @override
  String get syncKeepLocal => 'Conflito: mantenha este dispositivo';

  @override
  String get syncUseFile => 'Conflito: use o arquivo';

  @override
  String get syncApply => 'Aplicar alterações revisadas';

  @override
  String get syncApplied =>
      'Configurações trocadas. Salve um novo arquivo para enviar o resultado de volta.';

  @override
  String syncStyleParameters(int count) {
    return 'Estilo personalizado: $count parâmetros (diferenças abaixo)';
  }

  @override
  String get cloudBackups => 'Backups na nuvem';

  @override
  String get cloudHelp =>
      'WebDAV/Nextcloud. Insira o endereço HTTPS de uma pasta existente e uma senha do aplicativo. As transferências são manuais; esta pasta armazena a cópia mais recente.';

  @override
  String get cloudUrl => 'Endereço da pasta HTTPS';

  @override
  String get cloudUser => 'Nome de usuário';

  @override
  String get cloudPassword => 'Senha do aplicativo';

  @override
  String get cloudConnect => 'Verifique e salve a conta';

  @override
  String get cloudCheck => 'Verifique a conexão';

  @override
  String get cloudDisconnect => 'Desconectar conta';

  @override
  String get cloudDisconnectConfirm =>
      'Remover esta conta da TV? As cópias na nuvem permanecerão.';

  @override
  String get cloudUpload => 'Salve uma cópia na nuvem';

  @override
  String get cloudDownload => 'Restaurar da nuvem';

  @override
  String get cloudUploadConfirm =>
      'Substitua cutelauncher_backup.json nesta pasta pelas configurações e dados atuais?';

  @override
  String get cloudSuccess => 'Concluído';

  @override
  String get cloudConfigurationError =>
      'Verifique o endereço da pasta HTTPS, nome de usuário e senha do aplicativo.';

  @override
  String get cloudAuthorizationError =>
      'Acesso negado. Verifique as permissões da sua conta e pasta.';

  @override
  String get cloudMissingError => 'A pasta ou backup não foi encontrado.';

  @override
  String get cloudUnsupportedError =>
      'Este endereço não suporta as operações WebDAV necessárias. Os redirecionamentos não são seguidos; insira o endereço final da pasta.';

  @override
  String get cloudNetworkError =>
      'A conexão falhou ou expirou. Tente novamente quando a rede estiver disponível.';

  @override
  String get cloudFailed =>
      'Não foi possível concluir a ação de backup. Verifique o acesso ao armazenamento e tente novamente.';

  @override
  String get cloudStorageError =>
      'O armazenamento da conta não está disponível. Desconecte e configure a conta novamente.';

  @override
  String get adbPermissionChecking => 'Verificando acesso…';

  @override
  String get adbPermissionConnected => 'ADB conectado · conceder permissão';

  @override
  String get adbPermissionDisconnected =>
      'ADB desconectado · configurar conexão';

  @override
  String get adbSetupIntro =>
      'Habilite a depuração e a rede ADB nas configurações do desenvolvedor de TV e, em seguida, confie em CuteLauncher. Todas as ações do ADB são por sua conta e risco.';

  @override
  String get adbConnectionBlock => 'Conexão ADB';

  @override
  String get adbNotChecked => 'Conexão não verificada';

  @override
  String get adbApplied => 'Já aplicado';

  @override
  String get adbNotApplied => 'Ainda não aplicado';

  @override
  String get adbDefaultBlock => 'Iniciador padrão';

  @override
  String get adbSystemDefault =>
      'Abra a configuração do inicializador padrão do sistema';

  @override
  String get adbAssignDefault =>
      'Defina CuteLauncher como inicializador padrão via ADB';

  @override
  String get adbRestoreDefault =>
      'Restaure o inicializador padrão anterior via ADB';

  @override
  String get adbDefaultHint =>
      'Use ADB se o menu do sistema não puder definir o inicializador padrão.';

  @override
  String get adbBuiltinHint =>
      'Ao desativar o inicializador integrado, alguns botões do controle remoto e menus da TV específicos do fabricante podem parar de funcionar. Reative o inicializador integrado para desfazer a alteração.';

  @override
  String get adbHomeBlock => 'Botão home e inicialização';

  @override
  String get adbEnableService =>
      'Habilite o serviço de acessibilidade CuteLauncher via ADB';

  @override
  String get adbHomeOverride => 'Substituir o botão Home';

  @override
  String get adbHomeOptional =>
      'Se o iniciador integrado estiver desativado, substituir a página inicial e iniciar na inicialização da TV será opcional.';

  @override
  String get adbEnableBuiltin => 'Habilite o iniciador integrado via ADB';

  @override
  String get adbDisableBuiltin => 'Desative o iniciador integrado via ADB';

  @override
  String get adbNoBuiltin =>
      'Nenhum iniciador Google TV / Android TV integrado encontrado.';

  @override
  String get adbChanged =>
      'Estado mudou. Verifique a conexão e confirme a ação novamente.';

  @override
  String get adbEffectHome =>
      'O CuteLauncher solicitará ao Android que o defina como iniciador padrão e verificará o resultado. O iniciador atual será salvo para restauração.';

  @override
  String get adbEffectRestore =>
      'O inicializador anterior será habilitado e tornado padrão. Se não estiver disponível ou não for salvo, o primeiro outro iniciador disponível será selecionado. Isso não desativa a correção do botão Home.';

  @override
  String get adbEffectDisable =>
      'O aplicativo inicializador integrado será desativado para o usuário da TV. Os menus e botões da TV podem parar de funcionar. O aplicativo não foi desinstalado.';

  @override
  String get adbRecoveryHomeDisable =>
      'Todo o assistente de configuração do Google TV, incluindo sua tela inicial de recuperação, também será desativado para que o CuteLauncher possa se tornar o inicializador padrão. Os recursos do assistente de configuração ficarão indisponíveis até a restauração. Os estados originais de ambos os pacotes serão salvos para restauração.';

  @override
  String get adbRecoveryHomeRestore =>
      'O assistente de configuração do Google TV também retornará ao estado salvo.';

  @override
  String get adbDisableHomeUnavailable =>
      'Outra tela inicial tem prioridade mais alta. Não pode ser desativado com segurança por este iniciador.';

  @override
  String get adbEffectEnable =>
      'O iniciador integrado será restaurado ao estado salvo ou ativado se nenhum estado tiver sido salvo. O sistema pode selecioná-lo como inicializador padrão novamente.';

  @override
  String get adbEffectAccessibility =>
      'O serviço de acessibilidade CuteLauncher será ativado. Pode receber eventos Home; a interceptação é controlada por um switch separado. Outros serviços são preservados.';

  @override
  String get adbEffectAccessibilityRestore =>
      'O serviço CuteLauncher retornará ao seu estado antes do acesso ADB ser concedido. Outros serviços de acessibilidade são preservados.';

  @override
  String get adbEffectOverlay =>
      'CuteLauncher terá permissão para exibir janelas sobre outros aplicativos, incluindo o filtro noturno.';

  @override
  String get adbEffectNotifications =>
      'CuteLauncher receberá acesso à notificação por meio de seu próprio serviço de ouvinte.';

  @override
  String get adbEffectWatchNext =>
      'CuteLauncher receberá acesso para continuar observando os dados.';

  @override
  String get adbEffectUsage =>
      'CuteLauncher receberá acesso a estatísticas de uso para tráfego e detecção de aplicativos em primeiro plano.';

  @override
  String get adbEffectWriteSettings =>
      'CuteLauncher terá permissão para alterar as configurações de brilho do sistema.';

  @override
  String get adbNoAvailableLauncher =>
      'Nenhum outro lançador instalado foi encontrado. A restauração não está disponível.';

  @override
  String get adbUnsupported =>
      'Indisponível neste dispositivo: nenhum comando ADB compatível.';

  @override
  String get adbHomeUnchanged =>
      'O Android manteve o iniciador atual. Para abrir o CuteLauncher com o botão Início, configure o Home Button Fix.';

  @override
  String get nightBatteryExempt => 'CuteLauncher está isento de otimização';

  @override
  String get nightBatteryHint =>
      'Pode ajudar a programação a ser executada em segundo plano. Não garante que o processo sobreviva ao modo de espera.';

  @override
  String get nightBatteryOptimized => 'CuteLauncher está sujeito a otimização';

  @override
  String get nightBatteryTitle => 'Otimização da bateria';

  @override
  String get nightBatteryUnavailable =>
      'As configurações do sistema não estão disponíveis neste firmware ou o acesso foi negado.';

  @override
  String get nightBatteryUnknown => 'Status de isenção desconhecido';

  @override
  String get nightBatteryOpenApps => 'Abra as configurações de aplicativos';

  @override
  String get nightBatteryGuide =>
      '1. Nas configurações de aplicativos, abra Acesso especial a aplicativos.\n2. Selecione Otimização da bateria (às vezes Economia de energia).\n3. Encontre CuteLauncher; selecione Todos os aplicativos, se necessário.\n4. Desative a otimização ou selecione Irrestrito.\nOs nomes dos menus e a disponibilidade dependem do firmware da TV.';

  @override
  String get updateNotifications => 'Mostrar notificações de atualização';

  @override
  String get diagnosticsSave => 'Salvar relatório em arquivo';

  @override
  String get diagnosticsSaved => 'Relatório salvo';

  @override
  String get diagnosticsSaveFailed =>
      'Não foi possível salvar o relatório. Verifique o gerenciador de arquivos e a pasta de destino.';

  @override
  String get memoryCacheSize => 'Tamanho do cache de imagem';

  @override
  String get memoryProcess => 'Memória do aplicativo';

  @override
  String get memoryImages => 'Caches de imagens';

  @override
  String get diagnosticsExportOpened =>
      'Escolha uma pasta no gerenciador de arquivos e salve o relatório.';

  @override
  String get adbDisableService =>
      'Desative o serviço de acessibilidade CuteLauncher via ADB';

  @override
  String get adbDefaultSettings => 'Configurações padrão do iniciador';

  @override
  String get adbHomeSettings => 'Configurações do botão Home';

  @override
  String get adbAccessibilitySettings =>
      'Abra as configurações de acessibilidade';

  @override
  String get adbAccessibilityGuide =>
      'Selecione CuteLauncher no menu do sistema e habilite seu serviço. Volte aqui para configurar a interceptação inicial. Para desativá-lo, desligue o serviço CuteLauncher no mesmo menu.';

  @override
  String get adbEffectAccessibilityDisable =>
      'O serviço CuteLauncher será desativado. A interceptação domiciliar será interrompida. Outros serviços de acessibilidade são preservados.';

  @override
  String get backupAutoEnabled => 'Backup automático';

  @override
  String get backupClientId => 'ID do cliente';

  @override
  String get backupClientSecret => 'Segredo do cliente';

  @override
  String get backupCloudImportConfirm =>
      'Todas as configurações locais, categorias e imagens serão substituídas por dados na nuvem. Continuar?';

  @override
  String get backupConfigured => 'Configurado';

  @override
  String get backupConnection => 'Configurações de conexão';

  @override
  String get backupCreated => 'Criado';

  @override
  String get backupDaily => 'Diariamente';

  @override
  String get backupDriveHelp =>
      'Selecione Ligar Google Drive e confirme o código em seu telefone. Os backups ficam visíveis na pasta CuteLauncher em Google Drive, onde você pode baixá-los ou excluí-los. Mantenha os nomes dos arquivos inalterados para restauração no aplicativo. Reconecte após atualizar de backups ocultos; backups antigos não são migrados automaticamente.';

  @override
  String get backupFrequency => 'Frequência de backup';

  @override
  String get backupHourly => 'De hora em hora';

  @override
  String get backupLocal => 'Cópias locais';

  @override
  String get backupMinutes => 'min';

  @override
  String get backupMode => 'Modo';

  @override
  String get backupNever => 'Ainda não há backup';

  @override
  String get backupNotConfigured => 'Não configurado';

  @override
  String get backupOptions => 'Opções de backup';

  @override
  String get backupSaveMode => 'Cópia de segurança';

  @override
  String get backupScope => 'Backup em TVs';

  @override
  String get backupSyncScope => 'Sincronização entre TVs';

  @override
  String get backupSeparate => 'Separado para cada TV';

  @override
  String get backupShared => 'Mesmas configurações para todas as TVs';

  @override
  String get backupStorage => 'Armazenamento';

  @override
  String get backupSyncHelp =>
      'Baixe dados e carregue alterações. A última mudança vence conflitos. Os relógios da TV devem estar corretos. A sincronização é executada enquanto o inicializador está aberto.';

  @override
  String get backupSyncLimit => 'Verifique no máximo';

  @override
  String get backupSyncMode => 'Sincronização';

  @override
  String get backupSyncOptions => 'Opções de sincronização';

  @override
  String get backupTime => 'Tempo de backup';

  @override
  String get backupWeekday => 'Dia da semana';

  @override
  String get backupWeekly => 'Semanalmente';

  @override
  String get backupGoogleDrive => 'Google Drive';

  @override
  String get backupLocalHelp =>
      'As cópias locais são excluídas com o aplicativo ou seus dados. Mantenha uma cópia fora da TV também.';

  @override
  String get panelObjectOrder => 'Ordem dos objetos';

  @override
  String get panelInformationGroup => 'Informação';

  @override
  String get panelOrderHint =>
      '◄ / ► inicia ou termina a movimentação; ▲ / ▼ altera a ordem e muda de lado no limite dos grupos; OK / Voltar termina.';

  @override
  String get panelTextBackgroundTransparency =>
      'Transparência de fundo de texto e botão';

  @override
  String get weatherCityHint =>
      'Digite o nome da cidade em inglês, por exemplo Moscou.';

  @override
  String get weatherCityNotFound =>
      'Não foi possível identificar a cidade. Selecione-a nas configurações de localização.';

  @override
  String get weatherLocationAutomatic => 'Obtenha automaticamente';

  @override
  String get weatherLocationAutomaticHint =>
      'Obtenha as coordenadas do dispositivo. É necessária permissão de localização.';

  @override
  String get weatherLocationManual => 'Insira manualmente';

  @override
  String get manualLocationInput => 'Método de entrada';

  @override
  String get manualLocationCity => 'Cidade';

  @override
  String get manualLocationCoordinates => 'Coordenadas';

  @override
  String get weatherLocationPermissionDenied =>
      'Permita o acesso à localização nas configurações do Android e tente novamente.';

  @override
  String get weatherLocationUnavailable =>
      'Não foi possível obter coordenadas. Verifique as configurações de localização do Android ou insira uma cidade manualmente.';

  @override
  String get nightFilterSettings => 'Configurações de filtro';

  @override
  String get nightScheduleMenu => 'Cronograma';

  @override
  String get nightScheduleInactive => 'A programação está desativada';

  @override
  String get nightLocation => 'Localização';

  @override
  String get nightLocationAutomatic => 'Obtenha automaticamente';

  @override
  String get nightLocationManual => 'Insira manualmente';

  @override
  String get nightLocationFailed =>
      'Localização indisponível. Verifique as configurações de permissão e localização do sistema.';

  @override
  String get nightCitySearchHint =>
      'Digite o nome da cidade. Após uma vírgula, você pode incluir a região ou o país.';

  @override
  String get nightOverlayBrief =>
      'Permite que o filtro apareça sobre outros aplicativos.';

  @override
  String get weatherGetLocation => 'Obter localização';

  @override
  String get backupLastCreated => 'O último backup foi criado:';

  @override
  String get backupManagement => 'Gerenciar backups';

  @override
  String get backupCopyList => 'Lista de backup';

  @override
  String get backupRefreshCopyList => 'Atualizar lista de backup';

  @override
  String get backupCreateNow => 'Crie um novo backup agora';

  @override
  String get backupFolderPath => 'Pasta de backup';

  @override
  String get backupPrivateFolder => 'Pasta privada do aplicativo';

  @override
  String get backupRestoreCopy => 'Restaurar este backup';

  @override
  String get backupDeleteConfirm => 'Excluir o backup selecionado?';

  @override
  String get blockedAppsGroup => 'Aplicativos bloqueados';

  @override
  String get notificationSettingsButton => 'Configurações de notificação';

  @override
  String get hidePersistentNotificationsHint =>
      'Oculte notificações persistentes na lista e em outros aplicativos.';

  @override
  String get nightTransitionTime => 'Tempo de transição';

  @override
  String get brightnessSolar => 'Use a programação do modo noturno';

  @override
  String get brightnessAfterSunrise => 'Depois do nascer do sol';

  @override
  String get brightnessAfterSunset => 'Depois do pôr do sol';

  @override
  String get brightnessTransitionTime => 'Tempo de transição de brilho';

  @override
  String get brightnessSolarUnavailable =>
      'A programação do modo noturno não está disponível. Verifique seus horários e localização.';

  @override
  String get persistentNotificationCannotDelete =>
      'Esta notificação persistente não pode ser excluída. Você só pode bloqueá-lo.';

  @override
  String get diagnosticsCreateFailed =>
      'Não foi possível criar o relatório de diagnóstico. Tente novamente.';

  @override
  String get backupListFailed =>
      'Não foi possível carregar a lista de backup. Verifique o acesso ao armazenamento selecionado.';

  @override
  String get updateInstallerFailed =>
      'Não foi possível abrir o instalador da atualização. Tente novamente e verifique se o instalador Android está disponível.';

  @override
  String get backupFolderFailed =>
      'Não foi possível selecionar ou salvar a pasta de backup. Escolha uma pasta acessível e tente novamente.';

  @override
  String get updateDownloadFailed =>
      'Não foi possível baixar a atualização. Verifique sua conexão com a Internet e o armazenamento disponível.';

  @override
  String get backupDeleteFailed =>
      'Não foi possível excluir o backup. Verifique as permissões de exclusão e tente novamente.';

  @override
  String get updateCheckFailed =>
      'Não foi possível verificar se há atualizações. Verifique sua conexão com a Internet e tente novamente.';

  @override
  String get backupCreateFailed =>
      'Não foi possível criar o backup. Verifique o acesso ao armazenamento e o espaço disponível.';

  @override
  String get wallpaperChangeFailed =>
      'Não foi possível alterar o papel de parede. Verifique o acesso ao arquivo e tente novamente.';

  @override
  String get backupDownloadsFolder => 'Downloads/CuteLauncher';

  @override
  String get backupChooseFolder =>
      'Escolha uma pasta no gerenciador de arquivos';

  @override
  String get backupFolderPickerUnavailable =>
      'Nenhum seletor de pasta está disponível nesta TV. Escolha Downloads/CuteLauncher ou a pasta interna do aplicativo.';

  @override
  String get driveConfigurationError =>
      'As credenciais Google Drive estão ausentes ou são inválidas. Insira o ID do cliente e o segredo do cliente do seu cliente TV OAuth.';

  @override
  String get driveCodeExpired =>
      'O tempo de login do Google Drive expirou. Selecione Verificar e salvar conta para obter um novo código.';

  @override
  String get brightnessAfterNightStart => 'Noite';

  @override
  String get brightnessAfterNightEnd => 'Diurno';

  @override
  String get backupSyncSettings => 'Configurações para sincronizar';

  @override
  String get backupSyncHomeGroup => 'Tela inicial, seções e aplicativos';

  @override
  String get backupSyncAppearanceGroup =>
      'Aparência, papéis de parede e banners';

  @override
  String get backupSyncDisplayGroup =>
      'Modo noturno, brilho e protetor de tela';

  @override
  String get backupSyncControlsGroup => 'Controles do iniciador e da TV';

  @override
  String get backupSyncGeneralGroup =>
      'Idioma, atualizações e outras configurações';

  @override
  String get backupSyncGroupsHelp =>
      'Os blocos desativados ficam nesta TV. Escolha os blocos separadamente em cada dispositivo.';

  @override
  String get backupSyncGroupsFailed =>
      'Não foi possível salvar a seleção de configurações para sincronização. Tente novamente.';

  @override
  String get tileLayoutMode => 'Layout de bloco';

  @override
  String get tileLayoutAuto => 'Automático por tamanho de bloco';

  @override
  String get tileLayoutColumns => 'Contagem de colunas fixa';

  @override
  String get tileLayoutRows => 'Contagem de linhas fixa';

  @override
  String get tileRowCount => 'Contagem de linhas';

  @override
  String get useGlobalTileSettings => 'Usar configurações globais';

  @override
  String get centerSelection => 'Posição de seleção';

  @override
  String get selectionBottom => 'Inferior';

  @override
  String get selectionLower => 'Meio inferior';

  @override
  String get selectionCenter => 'Centro';

  @override
  String get selectionUpper => 'Médio superior';

  @override
  String get selectionTop => 'Superior';

  @override
  String get settingsStyle => 'Estilo de configurações';

  @override
  String get tileFocusEnlargement => 'Ampliação do foco';

  @override
  String get tileFocusShadowStrength => 'Força da sombra';

  @override
  String get tileFocusLift => 'Elevador';

  @override
  String get tileFocusLiftHeight => 'Altura de elevação';

  @override
  String get tileFocusBorderColor => 'Cor da borda do foco';

  @override
  String get tileFocusAccentColor => 'Cor de destaque';

  @override
  String get tileFocusDynamicColor => 'Cores dinâmicas';

  @override
  String get tileSizeFromColumns =>
      'O tamanho do bloco é determinado pela contagem de colunas e pela largura da seção.';

  @override
  String get resetSectionToGlobal =>
      'Redefinir configurações para valores compartilhados';

  @override
  String get resetSectionToGlobalHint =>
      'Restaurar títulos, ícones e plano de fundo de seções compartilhadas e redefinir o preenchimento?';

  @override
  String get resetStyleSection => 'Redefinir esta seção';

  @override
  String get resetStyleSectionHint =>
      'Restaurar os padrões apenas para esta seção?';

  @override
  String get notificationStyle => 'Estilo de notificação';

  @override
  String get styleBackgroundColor => 'Cor de fundo';

  @override
  String get styleTransparency => 'Transparência de fundo';

  @override
  String get styleTextSize => 'Tamanho do texto';

  @override
  String get styleTextColor => 'Cor do texto';

  @override
  String get noticeSize => 'Tamanho da notificação';

  @override
  String get noticeStylePreview => 'Visualização de notificação';

  @override
  String get backupSyncHomeOptions => 'Comportamento e opções gerais';

  @override
  String get backupSyncBackground => 'Plano de fundo e banners personalizados';

  @override
  String get backupSyncTiles => 'Estilo de bloco, menu e notificação';

  @override
  String get backupSyncWeatherSource => 'Fonte e localização';

  @override
  String get backupSyncWeatherDisplay =>
      'Exibição do tempo e unidades de temperatura';

  @override
  String get backupSyncNotificationSettings =>
      'Exibição de notificação e filtros';

  @override
  String get backupSyncOther => 'Outras configurações';

  @override
  String get tileFocusBorderStyle => 'Estilo de borda';

  @override
  String get tileFocusOutline => 'Esboço';

  @override
  String get tileFocusGlow => 'Brilho';

  @override
  String get tileFocusNoBorder => 'Sem fronteira';

  @override
  String get tileShowFocusShadow => 'Mostrar sombra';

  @override
  String get homeLayoutRow => 'Linha horizontal';

  @override
  String get homeLayoutRows => 'Várias linhas';

  @override
  String get homeLayoutGrid => 'Grade';

  @override
  String get homeCardCount => 'Cartões visíveis em';

  @override
  String get homeAuto => 'Automático';

  @override
  String get homeFree => 'Rolagem livre';

  @override
  String get homeAnchored => 'Seção ancorada';

  @override
  String get homeScrollMode => 'Rolagem de seção';

  @override
  String get homeSectionPosition => 'Posição da seção ativa';

  @override
  String get homeLabelMode => 'Etiquetas de aplicativos';

  @override
  String get homeLabelNone => 'Sem rótulos';

  @override
  String get homeLabelSelected => 'Somente aplicativo selecionado';

  @override
  String get homeLabelAll => 'Todos os aplicativos';

  @override
  String get homeInherited => 'Valor herdado';

  @override
  String get homeOwnReset => 'Restaurar definições comuns';

  @override
  String get homeParameters => 'Comportamento do ecrã inicial';

  @override
  String get homeSectionStyle => 'Aparência da seção';

  @override
  String get homeSectionGap => 'Espaço entre seções';

  @override
  String get homeSectionIcons => 'Ícones de seção';

  @override
  String get homeInactiveOpacity => 'Opacidade da seção inativa';

  @override
  String get homeResetSection => 'Restaurar a aparência da seção herdada';

  @override
  String get homeCalculatedSize =>
      'O tamanho é calculado a partir da contagem de cartas';

  @override
  String homeGapLimited(int gap) {
    return 'O espaçamento é limitado a $gap para manter a contagem de cartões selecionada.';
  }

  @override
  String get homeResetLayout => 'Redefinir layout da seção';

  @override
  String homeVisibleRows(int count) {
    return 'Linhas totalmente visíveis: $count';
  }

  @override
  String get homeStylePartial =>
      'Aplica-se apenas a seções que herdam esse valor e o suportam em seu layout atual.';

  @override
  String get homeStyleUnavailable =>
      'Indisponível nas configurações da seção atual. Verifique o layout e as substituições locais.';

  @override
  String get homeStyleNeedsRows => 'Disponível para múltiplas linhas ou grade.';

  @override
  String get homeStyleNeedsLabels =>
      'Ative os rótulos para alterar seu tamanho e cor.';

  @override
  String get homeStyleNeedsAllLabels =>
      'A posição se aplica apenas às etiquetas de todos os cartões. O título selecionado fica abaixo da seção.';

  @override
  String get homeStyleNeedsScale => 'Selecione o efeito de foco de ampliação.';

  @override
  String get homeStyleNeedsLift => 'Selecione o efeito de foco de elevação.';

  @override
  String get homeStyleNeedsBorder => 'Ative um contorno ou brilho primeiro.';

  @override
  String get homeStyleNeedsTitle =>
      'Habilite o título da seção para mostrar seu ícone.';

  @override
  String get homeStyleEconomy =>
      'Desativado pela economia de memória. O valor salvo é mantido.';

  @override
  String get homeStyleOpaque =>
      'Reduza a opacidade do fundo do bloco para ver o desfoque.';

  @override
  String get homeStyleOverridden =>
      'As seções visíveis usam seus próprios valores. Escolha “Usar global” em uma seção para aplicar esta configuração.';

  @override
  String get homeStyleIconHint =>
      'O tamanho do ícone afeta os cartões com um ícone de aplicativo. Os banners de TV preenchem o cartão de forma independente.';

  @override
  String get homeStyleShadowHint =>
      'A economia de memória limita a sombra de cartões inativos a 4. A sombra do foco é configurada separadamente.';

  @override
  String get homeStyleTransparent =>
      'A cor de fundo é invisível com opacidade zero. Aumente a opacidade do fundo do bloco.';

  @override
  String get homeStyleSingleColumn =>
      'Uma grade de coluna única não possui lacunas horizontais.';

  @override
  String get homeStyleAutoOnly =>
      'O tamanho muda apenas em seções com contagem automática de cartões que herdam o tamanho global.';

  @override
  String get sleepTimerThirtySeconds => '30 segundos (teste)';

  @override
  String get sleepTimer => 'Temporizador';

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
      'Permita temporizadores precisos nas configurações do Android e selecione uma duração novamente.';

  @override
  String get sleepTimerAccessRequired =>
      'Ative a acessibilidade do CuteLauncher ou conecte o ADB local em Configurações → Outro → ADB.';

  @override
  String get sleepTimerFailed =>
      'Não foi possível definir ou concluir o temporizador. Verifique a acessibilidade e o ADB local.';

  @override
  String get nightIgnoreHdmiInputs => 'Ignorar entradas HDMI';

  @override
  String get nightIgnoreHdmiInputsHint =>
      'Pause o filtro noturno enquanto assiste HDMI. O acesso de uso é necessário; a detecção de entrada depende do firmware da TV.';

  @override
  String get inputsSettings => 'Configurações de entrada';

  @override
  String get inputsUseCecNames => 'Use nomes de dispositivos de CEC';

  @override
  String get inputsNamesHint =>
      'Prioridade de nome: seu nome em CuteLauncher → CEC (se habilitado) → nome das configurações de Android → nome de entrada padrão.';

  @override
  String get inputNameHint => 'Deixe em branco para um nome automático';

  @override
  String get inputsSaveFailed =>
      'Não foi possível salvar as configurações de entrada';

  @override
  String get inputIcon => 'Ícone de entrada';

  @override
  String get inputIconTv => 'televisão';

  @override
  String get inputIconGame => 'Consola de jogos';

  @override
  String get inputIconComputer => 'Computador';

  @override
  String get inputIconReceiver => 'Receptor';

  @override
  String get inputIconDisc => 'Leitor de disco';

  @override
  String get inputIconStream => 'Dispositivo de streaming';

  @override
  String get nightInputExclusions => 'Exclusões de entrada';

  @override
  String get nightSelectInputs => 'Selecione entradas a serem ignoradas';

  @override
  String get nightNoInputsSelected =>
      'Nenhuma entrada selecionada. O filtro será aplicado a todas as entradas.';

  @override
  String get nightPictureExclusions => 'Exclusões do modo de imagem';

  @override
  String get nightPictureExclusionsHint =>
      'Selecione modos que pausam o escurecimento, a sobreposição quente e o filtro TCL vinculado. A programação é preservada. A detecção foi verificada em TCL; o acesso de uso não é necessário.';

  @override
  String get nightPictureUnavailable =>
      'O modo de imagem atual não está disponível neste firmware. Sua seleção é salva; as exclusões se aplicam somente quando a detecção é bem-sucedida.';

  @override
  String get nightPictureCurrent => 'Modo atual';

  @override
  String get nightPictureRefresh => 'Atualizar modo atual';

  @override
  String get nightPictureCode => 'Código de modo';

  @override
  String get nightPictureStandard => 'Padrão';

  @override
  String get nightPictureDynamic => 'Dinâmico';

  @override
  String get nightPictureMovie => 'Filme';

  @override
  String get nightPictureSport => 'Esporte';

  @override
  String get nightPictureIntelligent => 'Inteligente';

  @override
  String get nightPictureBright => 'Brilhante (Dolby Vision)';

  @override
  String get nightPictureOrdinary => 'Padrão';

  @override
  String get systemApplications => 'Aplicativos do sistema';

  @override
  String get removeFromCategory => 'Remover da categoria';

  @override
  String get noRemovableCategories =>
      'Este app não foi adicionado manualmente a nenhuma seção. Não é possível removê-lo das seções automáticas padrão (Todos, TV, Não TV); use Ocultar. Favoritos pode ser editado manualmente.';

  @override
  String get remoteButtonsTitle => 'Remapeamento dos botões do comando';

  @override
  String get remoteButtonsStart => 'Verificar botões (120 s)';

  @override
  String get remoteButtonsStop => 'Terminar verificação';

  @override
  String get remoteButtonsControlsHint =>
      'Inicie a verificação e prima botões em qualquer menu ou aplicação aberta. Termine-a aqui ou aguarde 120 segundos.';

  @override
  String get remoteButtonsHint =>
      'Após a verificação, o relatório é guardado no caminho indicado e substitui o anterior. Copie-o com ADB: adb pull <path>. Alguns botões do sistema e do fabricante podem não estar disponíveis para o serviço.';

  @override
  String get remoteButtonsEmpty =>
      'Ainda não há eventos. Se um botão abrir uma aplicação, volte aqui para ver o resultado.';

  @override
  String get remoteButtonsService => 'Serviço ligado';

  @override
  String get remoteButtonsRefresh => 'Atualizar';

  @override
  String get remoteBindings => 'Atribuições dos botões';

  @override
  String get remoteMappingsEnabled => 'Ativar remapeamento';

  @override
  String get remoteMappingsAdd => 'Adicionar atribuição';

  @override
  String get remoteMappingKey => 'Botão';

  @override
  String get remoteMappingAction => 'Ação';

  @override
  String get remoteMappingChooseAction => 'Escolher uma ação';

  @override
  String get remoteMappingNavigationGroup => 'Aplicações e navegação';

  @override
  String get remoteMappingScreenSoundGroup => 'Ecrã e som';

  @override
  String get remoteMappingAutomationGroup => 'Automatização';

  @override
  String get remoteMappingLiveTv => 'Abrir TV em direto';

  @override
  String get remoteMappingDisplaySettings => 'Definições do ecrã';

  @override
  String get remoteMappingBluetoothSettings => 'Definições de Bluetooth';

  @override
  String get remoteMappingMute => 'Silenciar ou repor o som';

  @override
  String get remoteMappingNeedsAdb => 'Requer ADB';

  @override
  String get remoteMappingLearn => 'Detetar um botão';

  @override
  String get remoteMappingLearnHint =>
      'Prima um botão adicional em 30 segundos. Navegação, Power, pesquisa por voz e volume estão protegidos.';

  @override
  String get remoteMappingsHint =>
      'As atribuições requerem o serviço de acessibilidade. São pausadas no editor e durante o diagnóstico. Início, Voltar, setas e OK mantêm a navegação.';

  @override
  String get remoteMappingsReset => 'Repor atribuições';

  @override
  String get remoteMappingsResetConfirm =>
      'Eliminar todas as atribuições e desativar o remapeamento?';

  @override
  String get remoteMappingInvalid =>
      'Não foi possível guardar. Verifique o botão e o destino. Os webhooks requerem HTTPS ou HTTP numa rede local.';

  @override
  String get remoteMappingBack => 'Voltar';

  @override
  String get remoteMappingProfile => 'Perfil';

  @override
  String get remoteMappingChannels => 'Canais';

  @override
  String get remoteMappingQuickSettings => 'Definições rápidas TCL';

  @override
  String get remoteMappingTrigger => 'Tipo de pressão';

  @override
  String get remoteMappingPress => 'Pressão curta';

  @override
  String get remoteMappingHold => 'Manter premido';

  @override
  String get remoteMappingHoldHint =>
      'Mantenha 650 ms: uma ação, sem a pressão curta. Se apenas a pressão longa estiver atribuída, um toque curto não faz nada.';

  @override
  String get remotePanelDescription =>
      'O painel de definições rápidas mostra os seus widgets sobre outras aplicações. Para o abrir com o comando, atribua a ação «Painel de definições rápidas» a um botão à sua escolha.';

  @override
  String get remotePanel => 'Painel de definições rápidas';

  @override
  String get remotePanelSettingsBackground =>
      'Usar a cor de fundo das definições';

  @override
  String get remotePanelPreview => 'Abrir painel';

  @override
  String get settingsHelp => 'Mais informações';

  @override
  String get settingsHelpScroll => '▲ / ▼ — rolar o texto';

  @override
  String get panelClockStyle => 'Aparência do relógio';

  @override
  String get clockPreset => 'Estilo da fonte';

  @override
  String get clockCustom => 'Personalizado';

  @override
  String get clockWeight => 'Espessura da fonte';

  @override
  String get clockGlow => 'Brilho do texto';

  @override
  String get clockAnimate => 'Animar dígitos';

  @override
  String get clockBackground => 'Fundo do relógio';

  @override
  String get clockRadius => 'Arredondamento do fundo';

  @override
  String get dateCalendarEnabled => 'Abrir calendário ao pressionar a data';

  @override
  String get calendarTitle => 'Calendário';

  @override
  String get dateSettings => 'Definições de data';

  @override
  String get clockSharedBackground => 'Usar o fundo dos outros objetos';

  @override
  String get clockDefaultBackground => 'Fundo padrão';

  @override
  String get remotePanelInheritAppearance =>
      'Usar a aparência do painel superior';

  @override
  String get remotePanelDisabledInLauncher =>
      'O painel de definições rápidas fica desativado enquanto o CuteLauncher está na tela.';

  @override
  String get remoteAccessSettings => 'Configurar acesso';

  @override
  String get remoteButtonsTest => 'Teste de botões';

  @override
  String remoteMappingDeleteConfirm(String name) {
    return 'Eliminar a atribuição «$name»?';
  }

  @override
  String get remoteMappingConflict =>
      'Este botão e tipo de pressão já estão atribuídos. Escolha outro botão ou tipo de pressão.';

  @override
  String get cleanerTitle => 'TV cleanup manager';

  @override
  String get cleanerRefresh => 'Refresh applications';

  @override
  String get cleanerSnapshot => 'Save original state';

  @override
  String get cleanerRestore => 'Restaurar estado base';

  @override
  String get cleanerSnapshotSaved => 'Original state saved';

  @override
  String get cleanerExportSnapshot => 'Export original state';

  @override
  String get cleanerSafe => 'Disable verified applications';

  @override
  String get cleanerNoSafe =>
      'Não há lista de apps do sistema para este modelo e firmware.';

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
      'Exportar relatório de apps desativados para arquivo';

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
      'O estado base é criado uma vez na primeira atualização bem-sucedida e não pode ser excluído nem sobrescrito pelo launcher. É vinculado ao firmware. Estados manuais salvam os modos dos apps com nome e data e podem ser restaurados, excluídos e exportados. Não contêm APKs nem dados. A restauração exige ADB local. A proteção contra falhas tenta restaurar a base automaticamente. Limpar os dados ou desinstalar o launcher remove as cópias; o acesso root não pode ser impedido.';

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
  String get interfaceCalm => 'Suave e discreto';

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
  String get informationGroup => 'Relógio, data e clima';

  @override
  String get informationSettings => 'Configurações do bloco';

  @override
  String get informationAppearance => 'Aparência do bloco';

  @override
  String get informationSize => 'Tamanho do bloco';

  @override
  String get informationPosition => 'Posição do relógio e do texto';

  @override
  String get informationClockLeft => 'Relógio à esquerda, texto à direita';

  @override
  String get informationClockRight => 'Texto à esquerda, relógio à direita';

  @override
  String get informationSpacing => 'Espaço entre relógio e texto';

  @override
  String get informationBackground => 'Fundo do bloco';

  @override
  String get homeResetTilesHint =>
      'Restaurar os valores comuns de todos os blocos e legendas deste ecrã?';

  @override
  String get homeResetLayoutHint =>
      'Repor a disposição desta secção, restaurar o aspeto comum e remover as margens internas? As aplicações e a sua ordem serão mantidas.';

  @override
  String get networkSummary => 'Rede';

  @override
  String get networkConnected => 'Internet disponível';

  @override
  String get networkOffline => 'Sem acesso à Internet';

  @override
  String get networkDisconnected => 'Desconectado';

  @override
  String get networkConnection => 'Conexão';

  @override
  String get networkSignal => 'Sinal';

  @override
  String get networkLinkSpeed => 'Velocidade do enlace Wi-Fi';

  @override
  String get networkTrafficRate => 'Tráfego do dispositivo · recepção / envio';

  @override
  String get networkSystemSettings => 'Configurações de rede do sistema';

  @override
  String get networkUnavailable => 'Indisponível';

  @override
  String get networkMobile => 'Rede móvel';

  @override
  String get networkFrequency => 'Frequência';

  @override
  String get networkMbps => 'Mbps';

  @override
  String get networkKbps => 'KB/s';

  @override
  String get networkReadFailed => 'Não foi possível ler o estado da rede';

  @override
  String get clockItalic => 'Itálico';

  @override
  String get panelWrapNavigation => 'Navegação circular no painel';

  @override
  String get panelWrapNavigationHelp =>
      'As setas passam da extremidade para o lado oposto. Mantenha uma seta pressionada para continuar pelos dois lados.';

  @override
  String get networkReceive => 'Recepção';

  @override
  String get networkSend => 'Envio';

  @override
  String get landscapeCelestialBodies => 'Sol e lua';

  @override
  String get landscapeStarRotation => 'Rotação das estrelas';

  @override
  String get tvPowerTitle => 'Gestão de energia';

  @override
  String remotePowerWithConfirmation(String action) {
    return '$action (com confirmação)';
  }

  @override
  String remotePowerWithoutConfirmation(String action) {
    return '$action (sem confirmação)';
  }

  @override
  String get tvPowerOff => 'Desligar dispositivo';

  @override
  String get tvPowerReboot => 'Reiniciar dispositivo';

  @override
  String get tvPowerOffConfirm => 'Colocar o dispositivo em espera?';

  @override
  String get tvPowerRebootConfirm =>
      'Reiniciar o dispositivo? Os aplicativos abertos serão fechados.';

  @override
  String get tvPowerSent => 'Comando enviado';

  @override
  String get tvPowerFailed =>
      'Falha ao enviar. Verifique ADB ou acessibilidade.';

  @override
  String get tvPowerHelp =>
      'Desligar ativa a espera pelo serviço de acessibilidade do CuteLauncher ou ADB local. Reiniciar exige ADB. Em uma TV box, controla a box; a TV depende de HDMI-CEC e do firmware.';

  @override
  String get cleanerLists => 'Listas de desativação';

  @override
  String get cleanerRecovery => 'Backup e restauração';

  @override
  String get cleanerExports => 'Relatórios';

  @override
  String get cleanerUpdating => 'Atualizando a lista de aplicativos…';

  @override
  String get cleanerRefreshRequired =>
      'Atualize primeiro a lista de aplicativos.';

  @override
  String get cleanerPreinstalled => 'Aplicativo pré-instalado';

  @override
  String get cleanerNotSystem => 'Este não é um aplicativo do sistema.';

  @override
  String get cleanerMinimalRisk => 'Mínimo';

  @override
  String get cleanerCacheFailure =>
      'Não foi possível guardar a lista para a próxima visita.';

  @override
  String get cleanerUserApps => 'Aplicativos do usuário';

  @override
  String get cleanerPreinstalledApps => 'Aplicativos pré-instalados';

  @override
  String get cleanerSystemApps => 'Aplicativos do sistema';

  @override
  String get cleanerBaseline => 'Estado original base';

  @override
  String get cleanerManualStates => 'Gerenciar estados manuais';

  @override
  String get cleanerManualSave => 'Salvar estado atual';

  @override
  String get cleanerDateName => 'Usar data e hora';

  @override
  String get cleanerCustomName => 'Inserir um nome';

  @override
  String get cleanerStateExport => 'Exportar estado salvo para arquivo';

  @override
  String get cleanerStateRestoreHelp =>
      'Os estados de ativação salvos para este firmware serão restaurados. Apps instalados depois não serão alterados. Apps ausentes e a desativação de componentes protegidos serão ignorados. Os dados dos apps não são restaurados.';

  @override
  String get cleanerCopiesHelp =>
      'O estado base é criado uma vez na primeira atualização bem-sucedida e não pode ser excluído nem sobrescrito pelo launcher. É vinculado ao firmware. Estados manuais salvam os modos dos apps com nome e data e podem ser restaurados, excluídos e exportados. Não contêm APKs nem dados. A restauração exige ADB local. A proteção contra falhas tenta restaurar a base automaticamente. Limpar os dados ou desinstalar o launcher remove as cópias; o acesso root não pode ser impedido.';

  @override
  String get cleanerSearch => 'Pesquisar por nome';

  @override
  String get cleanerCatalogUpdateRequired =>
      'Atualize primeiro o catálogo do GitHub.';

  @override
  String get cleanerNoSearchResults => 'Nenhum item correspondente.';

  @override
  String get cleanerAlreadyDisabled =>
      'Todos os apps desta lista presentes nesta TV já estão desativados.';

  @override
  String get cleanerAlreadyEnabled =>
      'Todos os apps desta lista presentes nesta TV já estão ativados.';

  @override
  String get cleanerNoInstalled =>
      'Nenhum app correspondente desta lista está instalado nesta TV.';

  @override
  String get cleanerListProtected =>
      'Os apps restantes estão protegidos contra desativação.';

  @override
  String get cleanerSnapshotFailed =>
      'Não foi possível salvar o estado. Nenhum app foi desativado.';

  @override
  String get cleanerDisableAllPreinstalled =>
      'Desativar todos os apps pré-instalados';

  @override
  String get cleanerEnableAllPreinstalled =>
      'Ativar todos os apps pré-instalados';

  @override
  String get cleanerPreinstalledList => 'Lista de apps pré-instalados';

  @override
  String cleanerBeforeList(String listName) {
    return 'Antes de aplicar a lista: $listName';
  }

  @override
  String get sleepTimerSettings =>
      'Configurações do temporizador de desligamento';

  @override
  String get sleepTimerPresets => 'Temporizadores';

  @override
  String get sleepTimerDisplay => 'Exibir com temporizador ativo';

  @override
  String get sleepTimerRemaining => 'Tempo restante';

  @override
  String get sleepTimerEndTime => 'Hora de desligamento';

  @override
  String get sleepTimerBoth => 'Tempo restante e hora de desligamento';

  @override
  String get sleepTimerShowSeconds => 'Mostrar segundos';

  @override
  String get sleepTimerShowOverApps => 'Mostrar temporizador sobre os apps';

  @override
  String get sleepTimerOverlayHelp =>
      'Ative o serviço de acessibilidade do CuteLauncher para exibi-lo sobre os apps.';

  @override
  String get sleepTimerCloseAfterSelection => 'Fechar o widget após selecionar';

  @override
  String get sleepTimerAdd => 'Adicionar temporizador';

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
      'Insira uma duração positiva: horas 0–999999, minutos e segundos 0–59.';

  @override
  String get sleepTimerDeleteConfirmation =>
      'Excluir este temporizador? A contagem regressiva ativa continuará.';

  @override
  String get sleepTimerResetConfirmation =>
      'Restaurar os temporizadores e a ordem padrão? Os personalizados serão removidos. A contagem regressiva ativa continuará.';

  @override
  String get sleepTimerReorderHint =>
      '◄ / ► ou segure OK para mover. ▲ / ▼ alteram a ordem e movem temporizadores entre visíveis e ocultos. OK encerra o movimento.';

  @override
  String get sleepTimerSaveFailed =>
      'Não foi possível salvar as configurações do temporizador.';

  @override
  String get sleepTimerVisible => 'Visíveis';

  @override
  String get sleepTimerHidden => 'Ocultos';

  @override
  String get sleepTimerReset => 'Redefinir temporizadores';

  @override
  String get cleanerListSnapshotHelp =>
      'A desativação de uma lista salva apenas os apps selecionados. A restauração não muda outros apps. O limite é de 100 estados manuais e automáticos. Sem salvar, a desativação não começa.';

  @override
  String get trafficSettings => 'Configurações de tráfego';

  @override
  String get trafficTitle => 'Tráfego';

  @override
  String get trafficReceived => 'Recebido';

  @override
  String get trafficSent => 'Enviado';

  @override
  String get trafficTotal => 'Total';

  @override
  String get stopApp => 'Parar';

  @override
  String get backgroundImageFormats =>
      'Imagens: JPEG, PNG, WebP, GIF, BMP — até 8 MiB, 48 megapíxeis e 16.384 píxeis por lado.';

  @override
  String get backgroundMediaFormats =>
      'Imagens: JPEG, PNG, WebP, GIF, BMP — até 8 MiB, 48 megapíxeis e 16.384 píxeis por lado.\nVídeo: MP4/M4V, WebM, MKV — até 256 MiB e 3840×2160. Os codecs dependem da TV; recomenda-se MP4 com H.264. Repete sem som e pausa fora do ecrã inicial. Vídeos excluídos das cópias de segurança.';

  @override
  String get backgroundFormatError =>
      'Formato não suportado ou ficheiro danificado. Escolha um ficheiro válido num dos formatos indicados.';

  @override
  String backgroundFileTooLarge(String maxMiB) {
    return 'O ficheiro é demasiado grande. Máximo: $maxMiB MiB. Escolha um mais pequeno.';
  }

  @override
  String get backgroundImageResolutionError =>
      'Imagem demasiado grande: até 48 megapíxeis e 16.384 píxeis por lado.';

  @override
  String get backgroundVideoResolutionError =>
      'Resolução de vídeo demasiado alta. Escolha até 3840×2160 (ou 2160×3840).';

  @override
  String get backgroundVideoCodecError =>
      'A TV não reproduziu o vídeo: codec não suportado ou ficheiro danificado. Experimente MP4 com H.264.';

  @override
  String get backgroundFileApplied => 'Ficheiro selecionado. Fundo atualizado.';

  @override
  String get noticePosition => 'Posição das notificações';

  @override
  String get noticeBottomRight => 'Em baixo à direita';

  @override
  String get noticeBottomLeft => 'Em baixo à esquerda';

  @override
  String get noticeTopRight => 'Em cima à direita';

  @override
  String get noticeTopLeft => 'Em cima à esquerda';

  @override
  String get overlayAppearance => 'Aparência sobre aplicações';

  @override
  String get overlayAppearanceTopPanel => 'Igual ao painel superior';

  @override
  String get overlayAppearanceDark => 'Escura';

  @override
  String get overlayWhereToShow => 'Onde mostrar';

  @override
  String get overlayAtPanelWidget => 'Na posição do widget no painel superior';

  @override
  String get notificationOpenFailed =>
      'Não foi possível abrir a ação da notificação. Ela pode não estar mais disponível.';

  @override
  String get adbWifiOverride => 'Desativar mesmo assim…';

  @override
  String get adbWifiRiskTitle => 'Desativar apesar do risco?';

  @override
  String get adbWifiRiskEffect =>
      'O launcher integrado e o assistente de configuração do Google serão desativados.';

  @override
  String get adbWifiRiskLoss =>
      'O Android pode excluir redes Wi-Fi salvas. O Wi-Fi e o ADB sem fio podem ficar indisponíveis.';

  @override
  String get adbWifiRiskRecovery =>
      'Reativar o assistente não restaurará automaticamente as redes excluídas. Será necessário reconectar ao Wi-Fi e inserir a senha.';

  @override
  String get adbWifiRiskConsent =>
      'Continue apenas se souber a senha do Wi-Fi.';

  @override
  String get adbWifiDisable => 'Desativar';

  @override
  String get recentAppsTitle => 'Aplicativos abertos';

  @override
  String get recentAppsPanelType => 'Painel';

  @override
  String get recentAppsAutomatic => 'Automático';

  @override
  String get recentAppsCustom => 'Painel CuteLauncher';

  @override
  String get recentAppsSystem => 'Painel integrado';

  @override
  String get recentAppsOpen => 'Abrir painel';

  @override
  String get recentAppsRefresh => 'Atualizar';

  @override
  String get recentAppsCloseAll => 'Fechar todos';

  @override
  String get recentAppsEmpty => 'Nenhum aplicativo de TV com tarefas abertas';

  @override
  String get recentAppsUnavailable =>
      'Aplicativos abertos indisponíveis. Verifique ADB e o acesso de acessibilidade.';

  @override
  String get recentAppsHelp =>
      'Apenas aplicativos de TV com tarefas abertas são exibidos. «Fechar todos» interrompe os aplicativos do usuário nesta lista. Atribua um botão no remapeador. O painel CuteLauncher requer ADB e acessibilidade.';

  @override
  String get recentAppsHomeHint =>
      'Home permite apenas pressão longa. Um toque curto retorna ao CuteLauncher. A atribuição também funciona fora do inicializador.';

  @override
  String get sectionRulesHelp =>
      'As seções padrão podem ser renomeadas, movidas ou ocultadas, mas não excluídas; pelo menos uma deve ficar visível. Todos, TV e Não TV são preenchidas pelo tipo de inicialização, não pelo nome; Ocultar remove o app das três. Favoritos e seções próprias são preenchidas manualmente. Ordem: manual, nome, frequência ou último uso; aparência por seção. Continuar assistindo mostra recomendações e pode ser ocultada ou movida.';

  @override
  String get remoteMappingNamePlaceholder => 'Nome do botão';

  @override
  String get remoteMappingAssign => 'Atribuir botão';

  @override
  String get remoteMappingCapture => 'Capturar';

  @override
  String remoteMappingCaptured(String key) {
    return 'Botão capturado: $key';
  }

  @override
  String get remoteMappingCaptureHint =>
      'Selecione Capturar e pressione o botão. Pode repetir. Selecione OK para aceitar.';

  @override
  String get remoteMappingCaptureTimeout =>
      'Nenhum botão capturado. Tente novamente.';

  @override
  String get remoteMappingCaptureFailed =>
      'Falha na captura. Verifique o serviço de acessibilidade.';

  @override
  String get remoteMappingServiceRequired =>
      'Conecte o serviço de acessibilidade nas configurações de acesso.';

  @override
  String get remoteMappingKeyRequired =>
      'Nenhum botão atribuído. Selecione Atribuir botão e capture um.';

  @override
  String get remoteMappingHomeHoldRequired =>
      'Selecione Pressão longa para Home.';

  @override
  String get remoteMappingAppRequired => 'Selecione um aplicativo para abrir.';

  @override
  String get remoteMappingUrlRequired =>
      'Insira ou importe uma URL de webhook.';

  @override
  String get remoteMappingUrlInvalid =>
      'URL inválida. Use HTTPS ou HTTP local com caminho, sem espaços, credenciais ou fragmento #.';

  @override
  String get remoteMappingSaveFailed =>
      'Falha ao salvar. Tente novamente; os valores são mantidos.';

  @override
  String get remoteMappingDeleteFailed => 'Falha ao excluir. Tente novamente.';

  @override
  String get remoteMappingRecents => 'Painel de aplicativos abertos';

  @override
  String get remoteMappingImport => 'Importar URL de arquivo';

  @override
  String get remoteMappingImportHint =>
      'Escolha um arquivo UTF-8 contendo apenas a URL do webhook, sem comandos ou explicações. As quebras de linha são removidas.';

  @override
  String get remoteMappingImportInvalid =>
      'O arquivo deve conter apenas uma URL de webhook válida: HTTPS ou HTTP local, sem comandos ou explicações.';

  @override
  String get remoteMappingImportFailed =>
      'Falha na leitura. Escolha um arquivo UTF-8 acessível de até 64 KB.';

  @override
  String get vpnTitle => 'VPN';

  @override
  String get vpnSettings => 'Configurações de VPN';

  @override
  String get vpnApp => 'Aplicativo VPN';

  @override
  String get vpnAutomatic => 'Automático';

  @override
  String get vpnNone => 'Não selecionado';

  @override
  String get vpnProfile => 'Perfil VPN';

  @override
  String get vpnOnlyActive => 'Mostrar apenas quando conectado';

  @override
  String get vpnShowName => 'Mostrar nome do aplicativo';

  @override
  String get vpnColor => 'Destacar conexão com cor';

  @override
  String get vpnNotify => 'Notificar resultados dos comandos';

  @override
  String get vpnConnected => 'VPN conectada';

  @override
  String get vpnDisconnected => 'VPN desconectada';

  @override
  String get vpnUnknown => 'Status da VPN indisponível';

  @override
  String get vpnConnect => 'Conectar';

  @override
  String get vpnDisconnect => 'Desconectar';

  @override
  String get vpnOpenApp => 'Abrir aplicativo VPN';

  @override
  String get vpnAndroidSettings => 'Configurações de VPN do Android';

  @override
  String get vpnAllowControl => 'Permitir controle da VPN';

  @override
  String get vpnFailed => 'Falha na ação da VPN';

  @override
  String get vpnUnsupported =>
      'O cliente não oferece controle direto. Você pode abrir o aplicativo.';

  @override
  String get vpnOther =>
      'Outra VPN ou uma VPN não identificada está conectada. Controle indisponível.';

  @override
  String get vpnStartup => 'VPN ao iniciar a TV';

  @override
  String get vpnPending => 'Aguardando conexão VPN';

  @override
  String get vpnHelp =>
      'A seleção automática detecta a VPN ativa e a memoriza para reconexão. A detecção de aplicativo e perfil requer ADB local conectado. AmneziaWG e WireGuard precisam de permissão de controle e controle remoto ativado no cliente. Happ e MantaRay usam o perfil selecionado no cliente.';

  @override
  String get vpnProfileHelp =>
      'Digite o nome exato do perfil no aplicativo VPN: até 15 letras latinas, dígitos e _ = + . -. O nome é detectado na conexão manual quando disponível.';

  @override
  String get vpnStartupHelp =>
      'A VPN inicia além das ações de inicialização normais. Configure antes o perfil e as permissões. A espera pela rede é limitada; uma VPN ativa não é substituída. A ativação após repouso só é detectada enquanto o processo do launcher está em execução.';

  @override
  String get vpnStartupMethod => 'Método de início da VPN';

  @override
  String get vpnStartupClient => 'Pelo aplicativo VPN';

  @override
  String get vpnStartupAlwaysOn => 'VPN sempre ativa do Android';

  @override
  String get vpnAlwaysOnManaged =>
      'O Android gerencia esta VPN no modo sempre ativo. Desative o modo nas configurações de início ou do Android.';

  @override
  String get vpnRestartRequired =>
      'Reinicie a TV para aplicar o modo do sistema.';

  @override
  String get vpnAlwaysOnHelp =>
      'Define um cliente configurado como VPN sempre ativa por ADB TCP local. O Android aplica a seleção após reiniciar a TV. O bloqueio de conexões sem VPN não é ativado nem alterado. Ao sair do modo, a seleção anterior do sistema é restaurada.';

  @override
  String get vpnClientConfirmation =>
      'Confirme o comando na janela do MantaRay.';

  @override
  String get informationTapAction => 'Ao pressionar o bloco';

  @override
  String get informationShowBoth => 'Tempo e calendário';

  @override
  String get weatherTextFormat => 'Formato do texto do tempo';

  @override
  String get weatherTextTemperature => 'Temperatura';

  @override
  String get weatherTextApparent => 'Sensação térmica';

  @override
  String get weatherTextConditions => 'Condições';

  @override
  String get weatherTextHumidity => 'Humidade';

  @override
  String get weatherTextLow => 'Mínima de hoje';

  @override
  String get weatherTextHigh => 'Máxima de hoje';

  @override
  String get weatherTextLiteral => 'Texto personalizado';

  @override
  String get weatherTextNewline => 'Quebra de linha';

  @override
  String get weatherTextBefore => 'Antes do bloco';

  @override
  String get weatherTextAfter => 'Depois do bloco';

  @override
  String get weatherTextYourFormat => 'O seu formato';

  @override
  String get weatherTextAdd => 'Adicionar bloco';

  @override
  String get weatherTextMoveEarlier => 'Mover para trás';

  @override
  String get weatherTextMoveLater => 'Mover para a frente';

  @override
  String get weatherTextHelp =>
      'Introduza texto e códigos entre chavetas ou insira-os no cursor com os botões. Maiúsculas e minúsculas são equivalentes. Os parênteses em torno de um valor desaparecem se faltarem dados. Duplique as chavetas literais. É permitida uma quebra de linha. Pode digitar letras, números, espaços e quaisquer símbolos imprimíveis, por exemplo: () [] / : ; + − ° % ·.';

  @override
  String get weatherTextSaveError =>
      'Não foi possível guardar o formato do texto do tempo.';

  @override
  String get weatherTextSampleCity => 'Lisboa';

  @override
  String weatherTextMetersPerSecond(String speed) {
    return '$speed m/s';
  }

  @override
  String weatherFeelsLike(String temperature) {
    return 'Sensação térmica $temperature';
  }

  @override
  String get weatherForecastTitle => 'Previsão do tempo';

  @override
  String get weatherForecastPeriod => 'Período da previsão';

  @override
  String weatherForecastDays(int days) {
    return '$days dias';
  }

  @override
  String get weatherForecastView => 'Vista da previsão';

  @override
  String get weatherForecastCards => 'Cartões compactos';

  @override
  String get weatherForecastList => 'Lista detalhada';

  @override
  String weatherForecastAvailable(int available, int requested) {
    return 'Dias disponíveis: $available de $requested';
  }

  @override
  String get weatherForecastTvTime => 'Datas no horário da TV';

  @override
  String get weatherClear => 'Céu limpo';

  @override
  String get weatherCloudy => 'Nublado';

  @override
  String get weatherFog => 'Nevoeiro';

  @override
  String get weatherWind => 'Vento';

  @override
  String get weatherPrecipitation => 'Precipitação';

  @override
  String get showVolume => 'Mostrar volume';

  @override
  String get audioStatusTitle => 'Volume e saída de áudio';

  @override
  String get audioOutputTv => 'TV';

  @override
  String get audioOutputHeadphones => 'Auscultadores';

  @override
  String get audioOutputMultiple => 'Várias';

  @override
  String get audioMuted => 'Sem som';

  @override
  String get backgroundStartupTitle => 'Aplicativos em segundo plano';

  @override
  String get backgroundStartupFailed =>
      'Não foi possível carregar ou salvar as configurações';

  @override
  String get backgroundStartupRetry => 'Tentar novamente';

  @override
  String get backgroundStartupEmpty => 'Nenhum aplicativo de usuário';

  @override
  String get backgroundStartupUnavailable =>
      'Inicialização em segundo plano indisponível';

  @override
  String get backgroundStartupRequested => 'Inicialização solicitada';

  @override
  String get backgroundStartupHelp =>
      'Marque os aplicativos para iniciar uma vez em segundo plano após ligar a TV. O CuteLauncher deve abrir em um minuto: defina-o como tela inicial ou ative sua inicialização ao ligar. Os aplicativos iniciam um a um atrás da tela inicial; marcar não os inicia imediatamente. Usar o controle ou sair do launcher cancela os inícios restantes. Sair do repouso não os inicia novamente. Aplicativos incompatíveis não podem ser selecionados. Iniciar não ativa funções internas nem garante operação contínua. Conceda permissões e configure o segundo plano no próprio aplicativo. O Android ou o firmware pode encerrá-lo. A seleção fica apenas nesta TV.';

  @override
  String get backgroundStartupToggle =>
      'Inicialização automática em segundo plano';

  @override
  String get systemWidgetSettings => 'Definições do widget Sistema';

  @override
  String get systemShowCpu => 'Mostrar CPU no painel';

  @override
  String get systemShowRam => 'Mostrar RAM no painel';

  @override
  String get systemStorage => 'Armazenamento: livre / total';

  @override
  String get systemUptime => 'Tempo de atividade (horas:minutos)';

  @override
  String get systemShowTemperature => 'Mostrar a temperatura da CPU no painel';

  @override
  String get systemTemperature => 'Temperatura da CPU';

  @override
  String get systemAvailable => 'RAM disponível';

  @override
  String get systemHistory => 'Última hora · médias e picos';

  @override
  String get systemNow => 'Agora';

  @override
  String get systemHourAgo => '−60 min';

  @override
  String get systemUpdateInterval => 'Intervalo de atualização';

  @override
  String get systemWidgetHelp =>
      'Os valores são atualizados no intervalo escolhido de 1 a 10 segundos (5 por predefinição) enquanto o painel está visível. Os gráficos mostram médias e picos por minuto. Outras aplicações, suspensão e erros de leitura deixam intervalos. O histórico fica na memória e é apagado ao reiniciar o processo do iniciador. CPU e temperatura dependem do firmware. Desative todos os valores do painel para mostrar apenas o ícone.';

  @override
  String get slideshowBrowseFolders => 'Explorar pastas';

  @override
  String get slideshowEnterFolderPath => 'Inserir caminho da pasta';

  @override
  String get slideshowSystemPicker =>
      'Escolher no explorador de arquivos externo';

  @override
  String get slideshowFolderPath => 'Caminho da pasta';

  @override
  String get slideshowUseFolder => 'Usar esta pasta';

  @override
  String get slideshowParentFolder => 'Pasta superior';

  @override
  String get slideshowStoragePermission =>
      'Permita o acesso a arquivos nas configurações do Android para usar o explorador integrado.';

  @override
  String get slideshowPickerUnavailable =>
      'Esta TV não tem seletor de pastas. Use o explorador integrado ou introduza um caminho.';

  @override
  String get slideshowFolderUnavailable =>
      'Pasta indisponível. Verifique o caminho, a unidade e a permissão de acesso.';

  @override
  String get slideshowStorageHelp =>
      'O explorador integrado lê pastas da TV e unidades ligadas. No Android 11 ou mais recente, permita o acesso a todos os ficheiros; no Android 9–10, ao armazenamento. Pode inserir um caminho como /storage/emulated/0/Pictures. Os ficheiros não são alterados.';

  @override
  String get fileBrowserTitle => 'Escolher um arquivo';

  @override
  String get filePickerChoose => 'Escolher explorador de arquivos';

  @override
  String get filePickerSystem => 'Explorador de arquivos externo';

  @override
  String get filePickerBuiltIn => 'Explorador de arquivos integrado';

  @override
  String get fileBrowserEmpty => 'Nenhum item para exibir';

  @override
  String get fileBrowserUnavailable =>
      'Não foi possível abrir este local. Verifique o acesso e tente novamente.';

  @override
  String get networkAndVpnGroup => 'Rede e VPN';

  @override
  String get soundAndInputsGroup => 'Som e entradas';

  @override
  String get timerAndNightModeGroup => 'Temporizador e modo noturno';

  @override
  String get systemSettingsGroup => 'Configurações do sistema';

  @override
  String get appChannelsTitle => 'Feeds de aplicativos';

  @override
  String get appChannelsHelp =>
      'Escolha até 16 feeds. A disponibilidade depende dos canais publicados pelos aplicativos e do firmware da TV. Feeds vazios ficam ocultos. A seleção permanece nesta TV.';

  @override
  String get appChannelsUnavailable =>
      'Não foi possível ler os feeds. Verifique o acesso à programação de TV.';

  @override
  String get appChannelsEmpty => 'Nenhum feed de aplicativo disponível.';

  @override
  String get appChannelsRefresh => 'Atualizar feeds';

  @override
  String get appChannelsLaunchFailed => 'Não foi possível abrir este conteúdo.';

  @override
  String get appChannelsSaveFailed =>
      'Não foi possível salvar a seleção. Escolha até 16 feeds.';

  @override
  String get sectionDeleteConfirm =>
      'Eliminar esta secção? As aplicações instaladas serão mantidas.';

  @override
  String get sectionDeleteFailed =>
      'Não foi possível eliminar a secção. Tente novamente.';

  @override
  String get appChannelsAccess => 'Acesso aos feeds das aplicações';

  @override
  String get appChannelsMissing => 'Feed indisponível';

  @override
  String get wallpaperRefresh => 'Atualizar fundo';

  @override
  String get wallpaperDimmingHelp =>
      '100% mantém o escurecimento original; 200% duplica-o. Não é a opacidade de uma camada preta.';

  @override
  String get resetLauncherSettings => 'Repor todas as definições';

  @override
  String get resetLauncherSettingsConfirmation =>
      'Todas as definições e dados locais do CuteLauncher serão eliminados: secções, favoritos, atribuições do comando, ligações e ficheiros no armazenamento da aplicação. O CuteLauncher será fechado e o próximo arranque será como uma instalação nova. Os acessos terão de ser concedidos novamente. Ficheiros fora do armazenamento do CuteLauncher e outras aplicações serão mantidos.';

  @override
  String get resetLauncherSettingsError =>
      'Não foi possível concluir a reposição. Tente novamente.';

  @override
  String get fileBrowserCurrentFolder => 'Pasta atual';

  @override
  String get fileBrowserFileName => 'Nome do ficheiro';

  @override
  String get fileBrowserNoFolders => 'Sem subpastas';

  @override
  String get fileBrowserNoFiles => 'Sem ficheiros compatíveis';

  @override
  String get fileBrowserPartial => 'Apenas parte da pasta é apresentada';

  @override
  String get fileBrowserReadNameHint => '← Pasta superior · → Nome completo';

  @override
  String fileBrowserSavedTo(String path) {
    return 'Guardado: $path';
  }

  @override
  String get backupDriveConnect => 'Ligar Google Drive';

  @override
  String get discardChangesTitle => 'Descartar alterações?';

  @override
  String get discardChangesMessage =>
      'As alterações não guardadas serão perdidas.';

  @override
  String get backgroundFileUnavailable => 'Arquivo indisponível';

  @override
  String get backupLastSuccess => 'Última ação bem-sucedida:';

  @override
  String get informationObjectPlacement => 'Posição';

  @override
  String get informationPlacement => 'Posição do bloco';

  @override
  String get informationOnBackground => 'Sobre o fundo';

  @override
  String get informationBackgroundPosition => 'Posição do bloco';

  @override
  String get informationBackgroundOffset => 'Deslocamento horizontal';

  @override
  String get informationBackgroundResetOffset => 'Redefinir deslocamento';

  @override
  String get informationBackgroundContentAlignment =>
      'Alinhamento dentro do bloco';

  @override
  String get informationBackgroundHelp =>
      'Escolha painel superior, fundo ou oculto separadamente para relógio, data e clima. Os elementos do fundo não respondem a comandos nem movem os blocos. As definições rápidas são independentes. As duas opções aplicam-se a todo o bloco de fundo: hora, data e tempo. A primeira elimina a sobreposição das montanhas; a segunda coloca o bloco acima das nuvens, da precipitação e do nevoeiro.';

  @override
  String get informationAboveLandscape => 'Acima da paisagem';

  @override
  String get informationAboveWeather => 'Acima dos efeitos meteorológicos';

  @override
  String get informationTime => 'Relógio';

  @override
  String get informationDate => 'Data';

  @override
  String get backgroundInformationAppearance => 'Aparência no fundo';

  @override
  String onlineWallpaperFailureStage(String stage) {
    String _temp0 = intl.Intl.selectLogic(stage, {
      'initialize': 'Preparação do armazenamento',
      'metadata': 'Consulta à fonte',
      'download': 'Download da imagem',
      'validation': 'Validação da imagem',
      'save': 'Gravação do papel de parede',
      'other': 'Gravação do papel de parede',
    });
    return '$_temp0';
  }

  @override
  String onlineWallpaperFailureReason(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'dns': 'Não foi possível resolver o endereço do servidor (DNS).',
      'connection':
          'Não foi possível estabelecer ou manter a conexão com o servidor.',
      'tls': 'Erro de conexão segura ou certificado (TLS).',
      'timeout': 'O tempo de espera da solicitação esgotou.',
      'http': 'O servidor retornou um erro.',
      'redirect': 'Redirecionamento inválido ou redirecionamentos demais.',
      'insecureUrl': 'URL insegura: é necessário HTTPS sem credenciais.',
      'tooLarge': 'A resposta excede o limite de tamanho.',
      'dimensions': 'As dimensões da imagem excedem o limite.',
      'invalidResponse': 'A fonte retornou dados inválidos.',
      'noImage': 'A fonte não retornou novas imagens adequadas.',
      'invalidImage':
          'O arquivo está corrompido ou o formato de imagem não é compatível.',
      'storage':
          'Não foi possível ler ou gravar os arquivos do papel de parede.',
      'unknown': 'Erro desconhecido.',
      'other': 'Erro desconhecido.',
    });
    return '$_temp0';
  }

  @override
  String get informationPanelAppearance => 'Aparência do painel';

  @override
  String get informationData => 'Formatos e dados';

  @override
  String get informationGroupingMinimum =>
      'São necessários pelo menos dois elementos';

  @override
  String get screenshotSceneMode => 'Modo de captura';

  @override
  String get screenshotSceneHour => 'Horas';

  @override
  String get screenshotSceneMinute => 'Minutos';

  @override
  String get screenshotSceneHelp =>
      'Define a hora da paisagem e do relógio de fundo e o clima da paisagem. Continua ativo após fechar as definições. Não altera a hora do sistema, os dados meteorológicos nem as definições guardadas. Ao reiniciar esta versão: 16:00, nublado.';

  @override
  String get autoLaunchWaitForInternet => 'Aguardar Internet';

  @override
  String get autoLaunchWaitForInternetHelp =>
      'Após o atraso, aguarda até 60 segundos pela confirmação do acesso à Internet e inicia a aplicação. Usar o comando ou sair do início cancela o arranque.';

  @override
  String get remoteMappingIgnore => 'Ignorar botão';

  @override
  String get remoteMappingBlackScreen => 'Alternar Black Screen';

  @override
  String get remoteMappingBlackOverlay => 'Tela preta';

  @override
  String get remoteMappingBlackOverlayHelp =>
      'Pressione uma vez para ocultar a imagem. Pressione novamente ou use Voltar para restaurá-la. A TV continua ligada.';

  @override
  String get remoteMappingTclScreenOff => 'Desligar a tela TCL';

  @override
  String get remoteMappingTclScreenOffHelp =>
      'Ativa o modo Apenas áudio em TVs TCL compatíveis. Se o Android bloquear a execução, é necessária uma conexão ADB local.';

  @override
  String get remoteMappingBlackScreenHelp =>
      'Pressione uma vez para mostrar a tela preta e novamente para ocultá-la. É necessária a versão paga do Black Screen da jApp e a permissão para exibição sobre outros apps.';

  @override
  String get adbHomeDependencyProtected =>
      'Desativação bloqueada: foi encontrada uma dependência do sistema ou não foi possível verificá-la. Consulte o diagnóstico.';

  @override
  String get cleanerOperationResultTitle => 'Resultado da última operação';

  @override
  String get cleanerUnchanged => 'Sem alterações';

  @override
  String get cleanerNotAttempted => 'Não executado';

  @override
  String get cleanerPackageMissing => 'Aplicativo ausente';

  @override
  String get cleanerReadFailed => 'Não foi possível ler o estado';

  @override
  String get cleanerJournalFailed =>
      'Não foi possível salvar o registro de recuperação';

  @override
  String get cleanerCommandFailed => 'O comando falhou';

  @override
  String get cleanerVerificationFailed => 'O novo estado não foi confirmado';

  @override
  String get inputsCecStateOnly => 'Estado HDMI apenas por CEC';

  @override
  String get inputsCecStateOnlyHelp =>
      'Ative se o firmware informar estados incorretos das portas. Apenas dados CEC são usados; sem eles, o estado é desconhecido. Todas as entradas permanecem na lista.';

  @override
  String get backgroundInformationOrderHint =>
      'OK ou ◄ / ►: iniciar ou terminar a movimentação; ▲ / ▼: alterar a ordem de cima para baixo; Voltar: terminar.';

  @override
  String get homeStyleNeedsSectionBackground =>
      'Escolha uma cor de fundo para a seção.';

  @override
  String get updateWrongPackage =>
      'Este APK é de outro aplicativo. Baixe uma atualização do CuteLauncher da fonte oficial.';

  @override
  String get updateNotNewer =>
      'O APK baixado tem a mesma compilação ou uma anterior. Só é possível instalar uma compilação mais recente.';

  @override
  String get updateSignersUnavailable =>
      'O Android não forneceu os certificados do aplicativo instalado ou do APK. Não foi possível verificar a assinatura; instalação bloqueada.';

  @override
  String get updateSignatureMismatch =>
      'A assinatura do APK difere da assinatura do CuteLauncher instalado. Atualização bloqueada. Informe ao autor de onde veio a versão instalada.';

  @override
  String get updateInvalidFile =>
      'O Android não conseguiu ler o APK: o arquivo está ausente, vazio, grande demais ou não foi reconhecido. Baixe a atualização novamente.';

  @override
  String get updateVerificationFailed =>
      'Ocorreu um erro ao verificar o APK. Instalação bloqueada. Tente novamente; se o erro se repetir, envie um relatório de diagnóstico ao autor.';

  @override
  String get feedFormat => 'Formato das capas';

  @override
  String get feedFormatAuto => 'Automático';

  @override
  String get feedFormatLandscape => 'Horizontal';

  @override
  String get feedFormatPortrait => 'Vertical';

  @override
  String get feedFormatHelp =>
      'Automático escolhe um formato por feed pelos dados do aplicativo ou pelas três primeiras capas carregadas e o salva nesta TV. Em caso de empate, usa horizontal. Outras proporções são exibidas inteiras sobre um fundo. Você pode escolher o formato manualmente.';

  @override
  String get networkSpeedTitle => 'Velocidade da rede';

  @override
  String get networkSpeedSettings => 'Definições de velocidade da rede';

  @override
  String get networkSpeedInterval => 'Intervalo de atualização';

  @override
  String get networkSpeedHelp =>
      'Taxas médias de recepção e envio nas interfaces de rede do dispositivo. É o tráfego atual, não um teste da conexão. As leituras pausam quando o widget está oculto, em segundo plano ou com a tela desligada. A primeira leitura após uma pausa mostra —.';

  @override
  String networkSpeedUnit(String unit) {
    return '$unit/s';
  }

  @override
  String get customDateFormat => 'Formato personalizado';

  @override
  String get customDateFormatError =>
      'Use os símbolos de data da ajuda. Coloque o texto entre aspas simples e feche-as.';

  @override
  String get customDateFormatHelp =>
      'd / dd — dia\nM / MM — número do mês\nMMM / MMMM — mês abreviado / completo\nEEE / EEEE — dia da semana abreviado / completo\nyy / yyyy — ano\nL…LLLL — mês independente\nD…DDD — dia do ano; G — era\nSeparadores: espaço, . / - ,\nTexto: \'Data:\'; apóstrofo: \'\'\nMaiúsculas e minúsculas importam. Símbolos de hora não são aceitos.\nExemplo: EEEE, d. MMMM yyyy';

  @override
  String get apodWallpaper => 'NASA APOD — imagem astronômica do dia';

  @override
  String get apodWallpaperHint =>
      'Imagem diária do NASA APOD. Nos dias com vídeo, é usada uma imagem recente. Tamanhos e proporções variam. Os créditos e o link da publicação aparecem aqui. As imagens pertencem aos respectivos titulares.';

  @override
  String get backupDriveClientImport => 'Importar Client ID e Secret de JSON';

  @override
  String get backupDriveClientImported =>
      'Dados do cliente importados. Conecte o Google Drive.';

  @override
  String get backupDriveClientImportFailed =>
      'Não foi possível importar os dados. Selecione um JSON do Google Cloud para TVs and Limited Input devices de até 64 KiB.';

  @override
  String get dateFormatPreview => 'Prévia';

  @override
  String get backupDriveConnectionStatus =>
      'Estado da conexão com o Google Drive';

  @override
  String get backupDriveReconnect => 'Reconectar o Google Drive';

  @override
  String get backupSyncRefresh => 'Atualizar';

  @override
  String get backupSyncRefreshFailed =>
      'Não foi possível sincronizar as definições. Verifique o acesso ao armazenamento e tente novamente.';

  @override
  String get backupThisTv => 'Esta TV';

  @override
  String get backupOtherTv => 'Outra TV';

  @override
  String get backupTvUnknown => 'TV desconhecida';

  @override
  String get panelTooltips => 'Mostrar dicas em todos os painéis';

  @override
  String get networkStorageTitle => 'Armazenamento de rede';

  @override
  String get usbStorageTitle => 'Unidades USB';

  @override
  String get storageScreenUnavailable =>
      'As definições de armazenamento não estão disponíveis.';

  @override
  String get appSections => 'Seções do aplicativo';

  @override
  String get noAppSections => 'Este aplicativo não está em nenhuma seção.';

  @override
  String get volumeWidgetSettings => 'Configurações de volume';

  @override
  String get volumeUpdateInterval => 'Intervalo de atualização';

  @override
  String get showVolumeOverlay => 'Mostrar volume sobre os apps';

  @override
  String get volumeOverlayHelp =>
      'O serviço de acessibilidade do CuteLauncher precisa estar ativado.';

  @override
  String get clockHoursColor => 'Cor das horas';

  @override
  String get clockMinutesColor => 'Cor dos minutos';

  @override
  String get clockColorMode => 'Modo de cor do relógio';

  @override
  String get clockSingleColor => 'Uma cor para o relógio';

  @override
  String get clockSplitColors => 'Cores diferentes para o relógio';

  @override
  String get clockShowColon => 'Mostrar dois-pontos';

  @override
  String get appLaunchGroup => 'Inicialização';

  @override
  String get appManagementGroup => 'Gerir aplicação';

  @override
  String get appCheckProcess => 'Verificar estado';

  @override
  String get appProcessNotChecked => 'Estado não verificado';

  @override
  String get appProcessRunning => 'Em execução';

  @override
  String get appProcessStopped => 'Não está em execução';

  @override
  String get weatherCustomServer => 'Servidor personalizado (Open-Meteo)';

  @override
  String get widgetSettings => 'Definições do widget';

  @override
  String get weatherServerUrlImport => 'Importar endereço de um ficheiro';

  @override
  String get weatherServerUrlImportError =>
      'Falha na importação: Escolha um ficheiro de texto UTF-8 de até 4 KB que contenha apenas o endereço HTTPS de base do servidor.';

  @override
  String get weatherImportReadError =>
      'Não foi possível ler o ficheiro a importar. Verifique o acesso ao ficheiro.';

  @override
  String get weatherImportEncodingError =>
      'Falha na importação: o ficheiro não está em UTF-8.';

  @override
  String get weatherImportTooLargeError =>
      'Falha na importação: o ficheiro excede 4 KB.';

  @override
  String get weatherImportSaveError =>
      'Não foi possível guardar o valor. Volte a introduzi-lo ou importá-lo.';

  @override
  String get weatherTokenInvalid => 'Formato de token inválido.';

  @override
  String get weatherServerUrl => 'Endereço HTTPS do servidor';

  @override
  String get weatherServerUrlHint =>
      'Introduza um URL HTTPS de base sem /v1/forecast, credenciais, consulta ou fragmento.';

  @override
  String get weatherServerCoordinates => 'Introduzir coordenadas';

  @override
  String get weatherServerCoordinatesHint =>
      'Introduza a latitude e a longitude separadas por vírgula, usando o ponto decimal. Exemplo: 50.0, 30.0.';

  @override
  String get weatherIconPack => 'Conjunto de ícones meteorológicos';

  @override
  String get weatherIconsStandard => 'Padrão';

  @override
  String get weatherIconsOutline => 'Contorno';

  @override
  String get weatherIconsSolid => 'Preenchidos';

  @override
  String get weatherIconsDuotone => 'Dois tons';

  @override
  String get weatherIconsPixel => 'Pixel';

  @override
  String get weatherTextColor => 'Cor do texto meteorológico';

  @override
  String get weatherIconColor => 'Cor dos ícones meteorológicos';

  @override
  String get weatherIconFollowsText => 'Igual ao texto meteorológico';

  @override
  String get informationDateColor => 'Cor da data';

  @override
  String get clockTextColor => 'Cor do relógio';

  @override
  String get weatherServerToken => 'Token Bearer (opcional)';

  @override
  String get weatherServerTokenImport => 'Importar token de um ficheiro';

  @override
  String get weatherServerTokenImportError =>
      'Falha na importação: Escolha um ficheiro de texto UTF-8 de até 4 KB que contenha apenas o token.';

  @override
  String get weatherCheckConnection => 'Verificar ligação';

  @override
  String get weatherServerAccessError =>
      'O servidor negou o acesso. Verifique o token e as permissões do servidor.';

  @override
  String get weatherServerParametersError =>
      'O servidor rejeitou os parâmetros do pedido ou as coordenadas.';

  @override
  String get informationComposition => 'Formato dos objetos';

  @override
  String get informationLayout => 'Disposição do bloco';

  @override
  String get informationPositionSize => 'Posição e tamanho';

  @override
  String get informationTypography => 'Fonte e dígitos';

  @override
  String get informationColors => 'Cores e efeitos';

  @override
  String get informationLayers => 'Camadas do fundo';

  @override
  String get informationAvoidOverlap => 'Não cobrir o bloco com as definições';

  @override
  String get weatherPresetBrief => 'Resumido';

  @override
  String get weatherPresetFeels => 'Sensação térmica';

  @override
  String get weatherPresetDetails => 'Detalhado';

  @override
  String get informationAvoidOverlapHelp =>
      'Ao editar o fundo, as definições mudam temporariamente para o lado que menos cobre o bloco. Se nenhum lado estiver livre, aparece uma pré-visualização separada. Ao sair, regressa o lado habitual.';

  @override
  String get informationProfileHelp =>
      'Os formatos e as cores do painel e do fundo são independentes. A fonte meteorológica é comum. As definições rápidas e a previsão usam o aspeto do painel superior; a visibilidade e o agrupamento das definições rápidas são separados.';

  @override
  String get weatherCompactLayout =>
      'Quando o tempo partilha um bloco com a data, a quebra aparece como um espaço. O formato guardado não muda.';

  @override
  String get weatherFormatInvalid =>
      'Adicione um campo meteorológico. São permitidos até 12 blocos, uma quebra de linha e 60 caracteres por campo de texto.';

  @override
  String get fileManagerPreference => 'Gerenciador de arquivos';

  @override
  String get fileManagerAsk => 'Perguntar sempre';

  @override
  String get fileManagerBuiltIn => 'Integrado';

  @override
  String get fileManagerExternal => 'Externo';

  @override
  String get fileBrowserStartFolder => 'Pasta inicial';

  @override
  String get fileBrowserStorage => 'Armazenamento da TV';

  @override
  String get fileBrowserDownloads => 'Downloads';

  @override
  String get fileBrowserLastFolder => 'Última pasta aberta';

  @override
  String get fileBrowserSort => 'Ordenar por';

  @override
  String get fileBrowserSortName => 'Nome';

  @override
  String get fileBrowserSortDate => 'Data de modificação';

  @override
  String get fileBrowserSortSize => 'Tamanho';

  @override
  String get fileBrowserOrder => 'Ordem';

  @override
  String get fileBrowserAscending => 'Crescente';

  @override
  String get fileBrowserDescending => 'Decrescente';

  @override
  String get fileBrowserFoldersFirst => 'Pastas sempre primeiro';

  @override
  String get fileBrowserShowHidden => 'Mostrar arquivos e pastas ocultos';

  @override
  String get fileBrowserShowDetails => 'Mostrar tamanho e data';

  @override
  String get fileBrowserOptionsHelp =>
      'A pasta selecionada ou a pasta original da imagem escolhida abre primeiro. A última pasta aberta é lembrada separadamente para cada ação, mesmo após o cancelamento. Se uma pasta estiver indisponível, abre o armazenamento da TV ou Downloads. O histórico de pastas fica apenas nesta TV.';

  @override
  String get fileBrowserSaveFailed =>
      'Não foi possível salvar as configurações do explorador.';

  @override
  String get settingsSectionStyle => 'Aparência dos grupos';

  @override
  String get settingsSectionAccentBand => 'Faixa de destaque';

  @override
  String get settingsSectionSurface => 'Superfície comum';

  @override
  String get panelTextAndButtonsGroup => 'Texto e botões';

  @override
  String get settingsGroupScene => 'Cena';

  @override
  String get settingsGroupSky => 'Céu e clima';

  @override
  String get settingsGroupAnimation => 'Animação e prévia';

  @override
  String get settingsGroupSource => 'Origem';

  @override
  String get settingsGroupImageChange => 'Troca de imagens';

  @override
  String get settingsGroupBrightness => 'Níveis de brilho';

  @override
  String get settingsGroupDisplay => 'Exibição';

  @override
  String get settingsGroupCredentials => 'Dados de conexão';

  @override
  String get settingsGroupClient => 'Parâmetros do cliente';

  @override
  String get settingsGroupAccount => 'Conexão da conta';

  @override
  String get settingsGroupIndicators => 'Indicadores e mensagens';

  @override
  String get nightModePanelFill => 'Cor de destaque para a lua';

  @override
  String get settingsGroupFocusShape => 'Aparência do foco';

  @override
  String get settingsGroupBorder => 'Borda';

  @override
  String get settingsGroupMotion => 'Movimento';

  @override
  String get settingsGroupControl => 'Controles';

  @override
  String get settingsGroupPositionSize => 'Posição e tamanho';

  @override
  String get settingsGroupGroupsBackground => 'Grupos e fundo';

  @override
  String get settingsGroupText => 'Texto';

  @override
  String get settingsGroupLayout => 'Disposição';

  @override
  String get settingsGroupHeadings => 'Títulos';

  @override
  String get settingsGroupLaunchTarget => 'O que iniciar';

  @override
  String get settingsGroupLaunchTiming => 'Quando iniciar';

  @override
  String get settingsGroupBlockPosition => 'Posição do bloco';

  @override
  String get settingsGroupBlockContent => 'Conteúdo do bloco';

  @override
  String get settingsGroupLayers => 'Camadas de exibição';

  @override
  String get settingsGroupAccess => 'Acesso';

  @override
  String get settingsGroupContent => 'Conteúdo';

  @override
  String get settingsGroupSourcesLimits => 'Fontes e limites';

  @override
  String get settingsGroupCards => 'Cartões';

  @override
  String get settingsGroupStorage => 'Armazenamento';

  @override
  String get settingsGroupMode => 'Modo';

  @override
  String get settingsGroupExceptions => 'Exceções';

  @override
  String get settingsGroupCurrentAction => 'Ação atual';

  @override
  String get settingsGroupHours => 'Horário de funcionamento';

  @override
  String get settingsGroupSourceAccess => 'Origem e acesso';

  @override
  String get settingsGroupUpdate => 'Atualização';

  @override
  String get settingsGroupSystemCommands => 'Sistema e comandos';

  @override
  String get weatherTemplateWarning => 'Aviso';

  @override
  String get weatherTemplateDescription => 'Descrição sem ícone';

  @override
  String get weatherTemplateIcon => 'Ícone';

  @override
  String get weatherTemplateBracesError =>
      'Verifique as chavetas emparelhadas. Duplique uma chaveta para a mostrar como texto.';

  @override
  String get weatherTemplateUnknownError => 'Código desconhecido:';

  @override
  String get weatherTemplateBreakError => 'Só é permitida uma quebra de linha.';

  @override
  String get weatherTemplateValueError =>
      'Adicione pelo menos um código meteorológico.';

  @override
  String get weatherTemplateLengthError =>
      'O formato é demasiado longo: até 2048 caracteres e 64 elementos.';

  @override
  String get sectionTitleSize => 'Tamanho do título da seção';

  @override
  String get backupSyncResume => 'Retomar a sincronização';

  @override
  String get backupSyncUseLocal => 'Usar as definições desta TV';

  @override
  String get backupSyncUseRemote => 'Usar as definições do armazenamento';

  @override
  String get backupSyncMergeLocal => 'Combinar com prioridade para esta TV';

  @override
  String get backupSyncMergeRemote =>
      'Combinar com prioridade para o armazenamento';

  @override
  String backupSyncPreviousDate(String date) {
    return 'Última sincronização desta TV: $date';
  }

  @override
  String backupSyncRemoteDate(String date) {
    return 'Cópia no armazenamento: $date';
  }

  @override
  String get appPermissionsTitle => 'Permissões de aplicações';

  @override
  String get appPermissionsGrant => 'Conceder permissões e ativar';

  @override
  String get appPermissionsRestore => 'Restaurar após desativação';

  @override
  String get appPermissionsReconnect => 'Reconectar serviço';

  @override
  String get appPermissionsDisable => 'Desativar serviço e restauração';

  @override
  String get appPermissionsAutoStart => 'Início automático';

  @override
  String get appPermissionsBackground => 'Atividade em segundo plano';

  @override
  String get appPermissionsPending =>
      'A restauração começa após conceder acesso aqui.';

  @override
  String get appPermissionsRetry =>
      'Restauração pendente. Verifique o ADB; as tentativas são automáticas.';

  @override
  String get appPermissionsIdentity =>
      'A assinatura da aplicação mudou. Conceda acesso novamente.';

  @override
  String get appPermissionsEmpty =>
      'Não há outras aplicações com serviços de acessibilidade.';

  @override
  String get appPermissionsError =>
      'Não foi possível concluir. Verifique o ADB e atualize o estado. Algumas alterações podem ter sido aplicadas.';

  @override
  String get appPermissionsConfirm =>
      'Permitir acessibilidade, início automático e atividade em segundo plano e ativar o serviço? Apenas ações suportadas pelo firmware são aplicadas. A acessibilidade pode ler eventos da interface e agir em seu nome.';

  @override
  String get appPermissionsHelp =>
      'A restauração está ativa por padrão para serviços autorizados aqui. Restaura permissões e ativação, mesmo após desativação no Android. Desativar a restauração mantém os acessos atuais. Desativar o serviço também interrompe a restauração; as permissões de início e segundo plano permanecem. Reconectar reinicia apenas este serviço, sem corrigir erros da aplicação. É necessário ADB; o Android pode adiar verificações. O início automático não abre a tela da aplicação. Os estados refletem a última verificação; operações não suportadas não são autorizadas.';

  @override
  String get weatherFieldUnsupported => 'Não suportado por esta fonte';

  @override
  String get weatherFieldMissing => 'Sem dados na resposta atual';

  @override
  String get weatherMissingAsDash => 'Traços para dados ausentes';

  @override
  String get weatherPanelAlignment => 'Alinhamento do tempo no painel superior';

  @override
  String get syncProtection => 'Tokens e proteção';

  @override
  String get syncKey => 'Chave de sincronização partilhada';

  @override
  String get syncKeyShow => 'Mostrar chave';

  @override
  String get syncKeyCreate => 'Criar chave';

  @override
  String get syncKeyInvalid =>
      'Introduza uma chave hexadecimal de 64 caracteres.';

  @override
  String get syncKeyHelp =>
      'Use a mesma chave em todas as TVs para sincronizar tokens e contas. Crie-a numa TV e transfira-a para as restantes. Guarde-a: sem a chave, os dados protegidos não podem ser lidos. Ao alterá-la, atualize todas as TVs. As permissões Android e as chaves de hardware ficam locais.';

  @override
  String get syncFiles => 'Ficheiros de sincronização';

  @override
  String get syncCleanup => 'Limpar ficheiros antigos';

  @override
  String get syncCleanupFailed =>
      'Não foi possível eliminar alguns ficheiros antigos. Tente limpar novamente.';

  @override
  String get syncRetire => 'Excluir dispositivo';

  @override
  String get syncRetireConfirm =>
      'Excluir este dispositivo do grupo? Os seus estados antigos deixarão de ser aplicados. Para voltar é necessário um novo grupo de sincronização.';

  @override
  String get backupAccount => 'Conta';

  @override
  String get backupNewAccount => 'Conectar outra conta';

  @override
  String get backupSetupWizard => 'Assistente de configuração';

  @override
  String get backupSetupSummary => 'Resumo';

  @override
  String get backupSetupNext => 'Avançar';

  @override
  String get backupSetupBack => 'Voltar';

  @override
  String get backupFirstCopy => 'Criar o primeiro backup agora';

  @override
  String get backupSyncAll => 'Sincronizar tudo';

  @override
  String get backupFirstExchange => 'Primeira troca';

  @override
  String get backupNoRemote =>
      'Não há configurações no armazenamento. Esta TV enviará as suas.';

  @override
  String get backupSetupStart => 'Ativar';

  @override
  String get backupPassword => 'Senha de criptografia dos dados';

  @override
  String get backupPasswordRepeat => 'Repetir senha';

  @override
  String get backupPasswordMismatch => 'As senhas não coincidem';

  @override
  String get backupAccountLocalHelp =>
      'Use uma conta conectada ou outra do mesmo tipo. As credenciais ficam nesta TV. Backup e sincronização gerenciam seus arquivos separadamente.';

  @override
  String get backupPasswordOptionalHelp =>
      'Opcional. Criptografa todo o arquivo, incluindo tokens transferíveis. Sem senha não há criptografia. Um valor vazio desativa a criptografia. Outras TVs precisam da mesma senha.';

  @override
  String get backupYandexDisk => 'Yandex Disk';

  @override
  String get backupYandexHelp =>
      'Insira Client ID e Client Secret de um aplicativo Yandex OAuth com acesso à sua pasta no Disk. Conecte e confirme o código no telefone. Use o mesmo cliente OAuth e conta em todas as TVs.';

  @override
  String get backupYandexConnect => 'Ligar Yandex Disk';

  @override
  String get backupYandexReconnect => 'Reconectar o Yandex Disk';

  @override
  String get backupYandexConnectionStatus =>
      'Estado da conexão com o Yandex Disk';

  @override
  String get yandexCodeExpired =>
      'O tempo de login do Yandex Disk expirou. Selecione Verificar e salvar conta para obter um novo código.';

  @override
  String get yandexConfigurationError =>
      'ID do cliente / Segredo do cliente — Yandex OAuth';

  @override
  String get backupSmb => 'Samba / SMB 2–3';

  @override
  String get smbUrl => 'Endereço da pasta SMB';

  @override
  String get smbPassword => 'Senha';

  @override
  String get smbHelp =>
      'Informe uma pasta de rede existente: smb://server/share/CuteLauncher. Insira usuário e senha com acesso; use DOMAIN\\user para uma conta de domínio. SMB 2 ou 3 é escolhido automaticamente. Backup e sincronização exigem permissões de leitura, gravação e exclusão.';

  @override
  String get recentRamTitle => 'Memória RAM';

  @override
  String recentRamUsed(String used, String total, String percent) {
    return 'Em uso: $used de $total · $percent%';
  }

  @override
  String recentRamAvailable(String value) {
    return 'Disponível: $value';
  }

  @override
  String get recentRamUnloaded => 'Fora da memória';

  @override
  String get recentRamUnavailable => 'Sem dados';

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
      'O armazenamento selecionado já contém definições de sincronização. Escolha entre aplicá-las a esta TV, substituí-las pelas definições desta TV ou combiná-las. Se houver diferenças na combinação, será usada a prioridade escolhida. A troca começará após a confirmação no último passo do assistente.';
}
