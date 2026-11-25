# CuteLauncher changelog

[Русский](CHANGELOG_RU.md) · [English](CHANGELOG_EN.md) · [About the launcher](README_EN.md)

## v1.8.3 — 2026-11-25

- Enabled feeds stay on the home screen when their app tile is hidden. Each feed's visibility is controlled in the feed settings.
- App feeds and Continue Watching let you choose the scrolling mode for long card labels. By default, text scrolls in a continuous loop. In Restart mode, the label returns to the start after a two-second pause.

## v1.8.2 — 2026-11-24

### Home screen and settings

- Section creation and editing now share a layout. New sections can start hidden, with a choice of sorting and layout. The name of an existing section stays in the header while scrolling and can be changed with the pencil icon. Sections and order shows each chosen icon, including for hidden sections.
- Shared section appearance has its own menu entry. Home screen behavior groups buttons and focus separately from system tiles. The hint in the section list changes when reordering starts.
- App Channels settings now give channel order, limits and appearance their own entries. Visibility and order can be changed with the remote in a single list, including for unavailable sources. The list refreshes when opened, and focus stays on a channel after changing its visibility.
- The Watch Next editor now has a visibility switch that keeps the section's position. Participating apps, limits, card settings and appearance are available from one menu. You can also grant Watch Next access there and restore hidden cards from section settings.
- Fixed moving channels and items with the remote. On-screen hints show which buttons change the position and finish the move.
- The gear icon in the top bar uses the accent color when an update is available. When there is no update, the settings header offers a shortcut to support the developer.
- The app list has labeled tabs, and the add-to-section dialog marks hidden sections. The saved choice is highlighted when selecting a language, gradient or auto-launch target.
- Top bar and Quick Settings group item visibility and order on a single page for each panel. The top bar stays visible while you adjust widget placement. Input settings are grouped by display, HDMI-CEC and individual inputs. Sleep timer intervals are grouped into visible and hidden lists.

### Memory and artwork

- Launcher Settings now has a Memory page with separate limits for feed artwork and app icons and banners. You can preload 16 or 32 cards in the active row, clear RAM when leaving the launcher and restore the default limits.
- App Channels and Watch Next now have separate memory and disk caches for artwork. The disk cache reuses downloaded artwork when you scroll back. The Memory page shows cache sizes and lets you clear the disk cache separately.
- Memory Saver uses fixed limits, prepares cards in neighboring feeds closer to when they appear and loads the realistic landscape image at a lower resolution. Turning it off restores your settings.

### Remote and fixes

- A screenshot action is available for remote buttons. With local ADB configured, screenshots are saved in Downloads.
- You can assign a button to open Quick Settings directly from the panel's settings page. Button mappings and other features that require access lead to the shared ADB Connection and Accessibility pages and return to the original setting. The Accessibility page can open Android settings or enable the CuteLauncher service through authorized ADB.
- The built-in Open Apps panel checks local ADB and the accessibility service before opening. If access is missing, it shows what to configure. CuteLauncher appears last as a switchable entry and is protected from being closed.
- The network widget settings show the connection type and whether internet access is available. The indicator can be enabled separately for the top bar and Quick Settings.
- Manual import replaces the current layout with the one in the file, and missing or invalid settings can return to their defaults. If auto-launch settings or button mappings cannot be read, changes are blocked until a retry succeeds.
- Clearing a diagnostic report during an active recording now asks for confirmation. Pressing Back keeps the recording running.
- Diagnostics can show the results of individual compatibility checks. App maintenance uses clearer section names and provides a direct entry to the preinstalled app list. File selection and built-in file browser settings have separate entries.
- Fixed link traversal when scanning the wallpaper folder for images. Links outside the folder and circular links are skipped.

## v1.8.1 — 2026-11-22

- When home screen recommendations refresh, a card keeps its artwork, title and action until the replacement artwork loads. The row no longer flashes placeholders as recommendations change.
- Fixed compact section spacing with tile glow enabled. The spacing now changes at every slider step.
- Local ADB works on TV boxes where the ADB service runs as root. When it connects this way, the launcher warns about the risk of leaving root ADB debugging enabled.
- The diagnostics dialog now clarifies what the extended report contains and where to send the file.

## v1.8.0 — 2026-11-20

### Settings and home screen

- Redesigned the settings menu. Language and appearance are grouped together, widgets and panels share a section, and backup, sync, export and import are available in one place.
- On startup, the home screen uses the saved section layout while Android refreshes the app catalog. Tile images are cached. Fixed banners disappearing after a cache cleanup and reduced memory use when returning home.
- Tiles can use an installed APK icon pack. Apps without a matching icon keep their regular image. Section titles can show icons, and sections can use tighter spacing.
- The Back button can return to the first card in a section or move up through sections one at a time. Both options work in feeds and Watch Next.
- Long feed captions scroll when focused, and two lines can scroll together. Opacity controls share a scale from 0% (fully visible) to 100% (fully transparent). Inactive feeds within a group can use this setting. Section previews respond immediately to visibility changes, and the Medeo fonts were updated to 1.1.0.
- Buttons on the app information card can be reordered or hidden. Local ADB can check app status and restart an app once it has stopped successfully.

### Wallpapers, weather and widgets

- A single folder source handles photos and videos on the TV or a USB drive. It supports subfolders, configurable photo timing, sorting by name or date, shuffle and manual advance. Videos play without sound. Existing folder settings are migrated automatically.
- Online wallpapers transition smoothly once the new image has decoded. Scheduled downloads wait if the launcher is busy. The previous video is now released when checking a new file. On compatible devices, the launcher tries another way to display the video if playback fails.
- Adaptive landscapes can use a selected source for sunrise and sunset or times set manually. The fallback sunset calculation has been fixed.
- Auto weather switches between MET Norway, Open-Meteo and Gismeteo. City search checks the built-in catalog first, then GeoNames. Coordinates can be entered manually for weather and night mode. The weather format editor supports line alignment, placeholders for missing readings and notes on data availability.
- Night mode calculates sunrise and sunset offline once a location is set. Scheduled backlight levels range from 0% to 100% in 10% steps.
- Persistent top-bar widgets appear with the clock, and conditional icons appear after a status check. The System widget can show CPU temperature on compatible devices, including through configured local ADB. The Wi-Fi summary shows the channel when it is known.
- Media volume and the active sleep timer can appear over other apps, with separate position and appearance settings. The timer hides in CuteLauncher and fits its full text. The volume indicator keeps the same width as the value changes.

### Remote and device controls

- The top bar can show a Quick Actions menu with a configurable list and order. The menu can launch the system screensaver on compatible firmware and manually advance to another wallpaper or file in a folder.
- Sleep puts the device into standby, including for older shutdown mappings. Full shutdown is available with confirmation through local ADB in Quick Actions and remote mappings. ADB reboot can be assigned with confirmation or as an immediate action.
- Remote buttons can toggle night mode, open the TV guide on compatible TCL devices, or run an ADB shell command entered manually or loaded from a `.sh` file. The built-in Black Screen action remains available. Mappings for the third-party Black Screen app have been removed.
- ADB settings can make CuteLauncher the home app or restore the previous launcher. CuteLauncher checks which app Android actually selected. A separate button opens Android's default home app settings. The ADB connection check retries after an interrupted handshake.
- Fixed autostart after sleep when the launcher is recreated, and opening an app from a notification in the remote quick settings panel. If Android's notification settings are unavailable, the launcher tries to open the system app information page. Opening quick settings successfully from the remote no longer shows an extra toast.

### Backup and sync

- Backup and sync have separate setup wizards, accounts and settings, including separate encryption passwords. Yandex Disk supports code-based sign-in, and Samba network folders support SMB 2/3.
- The sync wizard can select entire subgroups or individual settings. During the first exchange, it explains how to apply, replace or merge settings. Sync files can be managed in the launcher. Back returns from the storage page to the wizard.
- Fixed settings transfer during a full sync. Canceling before changes are applied preserves recent local edits, and repaired sync history persists across restarts. Restoring a backup removes unused imported banners.
- Resetting appearance restores button sounds, section titles and the startup landscape. Resetting one local background source preserves files used by other sources.

### Updates, diagnostics and fixes

- A compatible update appears at the top of Settings with its version, and release notes are available in the update section. With the prerelease channel enabled, the launcher finds the next test version. Update and About dialogs offer support QR codes, and About also offers QR codes for the repository and the 4PDA discussion.
- Recents shows total RAM use, estimated memory use per app and an unloaded status. The memory screen works without ADB. You can create a standard report or start, stop and export an extended diagnostic recording.
- Fixed the cover download queue stalling after HTTP errors and timeouts. Reports show download stages, HTTP statuses and data sizes. Reduced background checks for network traffic, the brightness schedule and Watch Next, reduced memory use when creating a standard report, and fixed a memory leak in the clock animation.
- In the built-in file browser, Left opens the parent folder and Right reveals a long name. Improved HDMI audio output detection on Android 11–12 and added missing translations for system screens.

## v1.8.0-test.14 — 2026-11-19

**Pre-release.**

- Redesigned the settings menu. Language and appearance are grouped together, and widgets and panels share a section. Backup, sync, export and import are now in one place.
- The update and About screens now offer a “Support the developer” button with QR codes for CloudTips and YooMoney. The About screen also has QR codes for the public repository and the 4PDA discussion.
- The Wi-Fi summary shows the network channel when available. Fixed autostart after sleep when Android recreates the launcher.

## v1.8.0-test.13 — 2026-11-18

**Pre-release.**

- Remote button settings now include a dedicated action for opening the TV guide on compatible TCL TVs.
- You can assign a custom ADB shell command to a remote button. Enter the command manually or import it from a `.sh` file.
- The ADB connection check retries if the connection drops during the handshake.
- The volume overlay keeps the same width as its reading changes.
- Resetting appearance restores the defaults for button sounds, section headings, and the initial landscape. Resetting an individual local wallpaper source preserves files used by other sources.

## v1.8.0-test.12 — 2026-11-17

**Pre-release.**

- Tapping a notification in the remote quick settings panel opens its app again. If Android cannot open the launcher's notification settings, CuteLauncher tries to open its system app info page.
- Cancelling sync before changes are applied preserves recent local edits. Repairs to damaged sync history persist across restarts.
- After restoring a backup, the launcher removes old imported banners that are no longer in use.
- The launcher performs fewer background checks for the data usage widget, the Continue Watching row, and scheduled brightness. The top bar and quick menu share data usage requests, and Continue Watching cards refresh when their content changes.
- Fixed automatic online wallpaper rotation. If the launcher is busy when a wallpaper change is due, the scheduled download waits its turn.

## v1.8.0-test.10 — 2026-11-16

**Pre-release.**

- You can hide and reorder buttons in an app's details panel. Open the settings using the gear in the panel or go to Settings → Home screen → App info settings. You can also enable a status check over local ADB when opening the panel.
- The app details panel now has a Restart action. When the app can be opened, the launcher starts it after confirming that it was stopped over local ADB.
- When a compatible update is found, its version appears at the top of Settings. Select that entry to open Updates, where you can read What's new before installing.
- Diagnostics offers a standard report and extended recording. Start recording before reproducing an issue, then stop it manually or create an extended report right away.
- Six icons are now available for section headings: Weather, Reading, Kids, Smart home, Travel, and Podcasts.
- Fixed app banners disappearing after the cache is cleared when returning to the home screen. Reduced memory use when repeatedly returning to the home screen and when generating a standard report.
- Fixed how the previous video wallpaper is released when checking a new file. Video wallpaper compatibility depends on the device firmware and decoders. Use H.264 in an MP4 file for better compatibility.

## v1.8.0-test.7 — 2026-11-15

**Pre-release.**

- Add Quick Actions to the top bar using the lightning button. Choose which commands to show and put them in the order you want. From the menu you can start the system screensaver on supported firmware and manually switch the wallpaper or play the next video from a folder.
- Sleep puts the device in standby. A separate command now shuts the device down completely after confirmation and requires local ADB to be configured. The command is available in Quick Actions and remote button mappings. Existing power-off mappings keep their behavior and now appear as Sleep.
- You can map a remote button to toggle Night Mode. Press it again to restore the previous state. The saved filter and schedule settings are preserved.
- Section appearance settings now let you choose a heading icon for built-in and custom sections. For App Feeds, the setting applies to all feeds.
- Adaptive Landscape lets you choose the source of sunrise and sunset times or set them manually. The fallback sunset calculation has been fixed.
- Opening Quick Settings successfully with a mapped remote button no longer shows an extra toast.

## v1.8.0-test.3 — 2026-11-13

**Prerelease.** Video playback from a folder still needs testing on a TV.

- Added video wallpapers from a folder on the TV or a USB drive. Videos loop without sound. You can play them by name, by modification date, or in a random order without repeats within each cycle, and skip to the next video manually.
- Appearance settings now use a consistent transparency scale. At 0% an element is fully visible, and at 100% it is fully transparent.
- General section settings now let you apply transparency to inactive feeds within the selected group. The current feed stays fully visible.
- Fixed update detection between prereleases. The launcher now offers the next test version when the prerelease channel is enabled.

## v1.8.0-test.2 — 2026-11-13

**Prerelease.** Some new features are still being tested. If you are unsure, wait for the stable release.

- The Back button can return to the first card in the current section or move up through sections with repeated presses. This also works in recommendation feeds and Continue Watching.
- The System widget shows CPU temperature on compatible devices. A separate switch displays it in the top bar. If direct readings are unavailable, the widget can use an existing local ADB connection.
- Always-visible top bar widgets appear alongside the clock at startup. Icons that depend on connectivity or another condition appear once that condition is confirmed.
- Improved cold startup. App card artwork is cached. Fixed duplicate images in memory and a memory leak in the clock animation.
- One button in ADB settings sets CuteLauncher as the home screen and lets you restore the previous launcher. The app checks which launcher Android selected. A separate button opens Android's default launcher settings.

## v1.8.0-test.1 — 2026-11-12

**Prerelease.** This version includes new features, some of which have not yet been fully tested. Based on current checks, we do not expect critical issues. If you are unsure, skip this release and wait for the stable version.

- Backup and synchronization now have separate setup wizards, accounts, and settings. Added Yandex Disk with code-based sign-in and Samba network folders (SMB 2/3). Backup and sync files can use separate encryption passwords.
- Fixed settings transfer in full synchronization. The wizard lets you enable entire subgroups or individual settings. On the first exchange it explains how to apply, replace, or merge settings from storage. Added sync file management. Pressing Back on the remote returns from storage settings to the wizard.
- Weather defaults to Auto mode and switches between MET Norway, Open-Meteo, and Gismeteo. City search checks the built-in catalog first and then GeoNames. Weather and night mode accept manually entered coordinates. The format editor adds line alignment, dashes for missing values, and explanations of data availability.
- Night mode calculates sunrise and sunset offline after a location is set. Scheduled backlight levels range from 0% to 100% in 10% increments.
- Media volume and the active sleep timer can appear over other apps. Each indicator has independent position and appearance settings. The timer hides in CuteLauncher and widens its single-line overlay to fit the full text and icon.
- Standby and restart can be mapped to the remote with confirmation or immediate execution. Restart requires configured ADB. Mappings for the third-party Black Screen app have been removed. The built-in Black Screen action is available.
- Long captions in app feeds and Watch Next scroll while focused. When needed, both lines scroll together. The switch is in the section appearance settings. Section previews react immediately to visibility changes. Medeo fonts were updated to 1.1.0.
- Fixed the cover loading queue getting stuck after HTTP errors and timeouts. Diagnostic reports now include loading stages, HTTP status, bytes received, and network events without storing full image URLs.
- Recents now shows overall RAM usage, per-app memory estimates, and a separate “Unloaded” status. The CuteLauncher Memory page works without ADB and shows measurements and caches. The chart and technical figures are available under Advanced diagnostics.
- In the built-in file browser, Left opens the parent folder and Right expands a long name. Improved HDMI audio output detection compatibility on Android 11–12 and added missing translations for system screens.

## v1.7.5 — 2026-11-11

- Added “App permissions” under “Launcher and TV control”. With local ADB configured, you can grant a user-installed app supported permissions for autostart and background activity, and enable or reconnect its accessibility service. System apps are excluded.
- Added automatic recovery of granted access and the accessibility service when disabled. To disable it permanently, turn off “Restore when disabled” or select “Disable service and recovery”. The app card refreshes after actions; available permissions depend on the firmware.
- Fixed the initial sync when settings differ: you are asked which settings to keep both when enabling sync and when refreshing once with sync disabled. After changing the mode, storage, folder, or sync scope, enable sync again. Cancel and Back cancel the exchange.

## v1.7.4 — 2026-11-10

- Clock, date, and weather settings are grouped in one section. The top bar and wallpaper share formats and can be styled separately. Date format previews use the current date. New installations default to a short date format with the weekday.
- Pressing Back in the date and weather format editors now asks for confirmation. Fixed Gboard language switching in the weather editor.
- Focus moves directly to cards when quickly moving between home screen feeds. If artwork fails to load, the launcher retries while the card remains active.
- Fixed button focus indicators across dialog styles and preserved focus when settings refresh. The section editor now opens on the right. The preview stays in place when settings open on the left.
- The night mode accent highlights the moon icon. It is enabled by default on new installations.
- Improved detection of active Bluetooth audio on Android 9–12 and HDMI ARC on Android 11–12. Fixed a crash when selecting HDMI ARC on Android 11. System settings and input switching depend on the firmware.
- Remote mappings pause while testing buttons. After capturing a button, focus moves to OK. If a mapped action fails, the launcher explains why.
- When resuming sync with a conflict, you can choose which settings to keep. Restoring and syncing settings preserve local app launch counts.
- Updated app dependency information in the TV cleaner for supported firmware. The system file browser is now called External file browser in settings.

## v1.7.2 — 2026-11-09

- You can navigate the home screen as soon as it opens. Static placeholders appear in place of tiles and cards while artwork and data load. Focus and scroll position are preserved as content loads. Previously loaded cards stay visible if a refresh temporarily fails.
- App feeds and Continue Watching can each use their own appearance, the shared tile settings, or the appearance of a specific app section. Captions can be configured separately. Inactive section opacity now applies to feeds and Continue Watching as well.
- Artwork is back in Continue Watching. Covers show the app icon and name, along with a progress bar when progress data is available. Feed cards can show the year, rating, genre, duration, or channel name below the title.
- The maximum number of cards in each feed can be set from 20 to 50. Feeds scroll smoothly with the arrow buttons, and Back can be configured to return to the first card in the current feed.
- Empty feeds, feeds with no available cover art or thumbnails, and the TCL system Favorites feed are hidden from the home screen and feed picker. A feed returns with its previous setting when its artwork becomes available again. Uninstalling an app also removes its feeds from the saved selection.
- When you enable or disable a feed, focus stays on its toggle. The arrow buttons follow the new order of settings. The home screen scrolls smoothly to empty sections, where OK opens section settings.
- Opening settings for a visible section scrolls the home screen to that section so you can see appearance changes immediately. Exiting restores the previous position.
- Remote button remapping now supports switching to a specific HDMI input, opening live TV, toggling media mute, and opening network or Bluetooth settings. The picker is more compact, actions are grouped by category, and long names wrap at word boundaries.
- A remote button can now trigger the built-in Black Screen, the native Audio Only mode on compatible TCL TVs, or toggle the paid Black Screen app.
- An optional accent fill highlights the Night Mode button in the top panel while the mode is active.

## v1.7.1 — 2026-11-08

- Added shared and per-section title size settings, from 12 to 40.
- Fixed accent colour updates: open panels now apply a newly selected colour immediately.
- Remote instructions stay pinned to the bottom of settings and remain visible while scrolling. Compact text fits in at most three lines.
- Updated the first-run profile: Standard style, Medeo Sans, an orange accent, tile labels off, spacing of 6, and enlarged tiles with glow. Updating preserves existing settings, including earlier defaults that were never selected manually.
- Reduced APK size without removing landscapes or fonts. Universal now contains ARMv7 and ARM64; a separate APK is available for x86_64.

## v1.7.0 — 2026-11-08

- Redesigned settings: long pages are divided into related groups. Added Accent strip and Shared surface group styles.
- Added the Calm interface style. Improved readability, highlighting, and remote navigation.
- Added custom app names and an option to align section headings with tiles.
- Added independent clock, date, and weather appearance profiles for the top panel and wallpaper, including formats, fonts, colors, and icons.
- Added horizontal and vertical offsets, size, and alignment for the wallpaper information block. Layer settings apply to the entire block; the menu automatically chooses the side with less overlap.
- Added a weather text editor with previews for the panel and wallpaper, insertion of weather fields at the cursor, and reset to the default template. It supports custom text, a line break, temperature, feels-like temperature, city, description, wind, humidity, and warnings, with remote navigation and on-screen keyboard support.
- Added seven weather icon sets, separate text and icon colors, and feels-like temperature in the forecast.
- Added a custom Open-Meteo server option with address and token import from files, along with OpenWeather and Yandex API key import.
- Added an experimental Gismeteo source with forecasts for up to seven days; it is not intended for regular use.
- Added a preferred file manager setting. The built-in browser now offers starting folder, sorting, hidden file, and file information options, and remembers visited folders.
- Added switching of font family and style with the arrow buttons directly in the settings row.

## v1.6.12 — 2026-11-08

- Long settings pages now use consistent groups with clear headings. Related controls stay together, while short menus keep their simple layout.
- Added a shared choice of group appearance: Accent strip or Shared surface (the default).
- Group appearance applies to home and panel settings, weather, night mode, brightness, notifications, KVN, startup, Continue watching, the file browser, button mappings, and backups.

## v1.6.11 — 2026-11-06

- Redesigned clock, date and weather settings with independent panel and wallpaper profiles, a shared preview, and sections for formats, position, fonts, colors and layers. Existing settings are preserved.
- Weather editing now offers presets and saves the template, units and warnings together. Back discards the entire draft.
- While editing wallpaper information, settings automatically move to the side with less overlap. This option can be disabled.
- Grouped date and weather use two rows in total in the top panel. Saved weather line breaks remain available in other layouts.

## v1.6.10 — 2026-11-05

- Top bar and background clocks can use one color or separate colors for hours and minutes. The colon can also be hidden.
- Scrollbars have three modes: always hidden, visible while scrolling, and always visible (the default).
- Redesigned the app details panel. Information, status, and actions have separate sections, and the status check is started manually.
- Fixed remote navigation between Add section and Reset settings. Long settings lists begin scrolling as focus approaches the middle of the screen.
- The NAS setting is unavailable on devices without NAS support.

## v1.6.9 — 2026-11-04

- Added NAS and USB storage indicators to the top bar and quick settings. NAS is available on compatible Formuler firmware.
- Added a volume refresh interval setting: from 1 to 10 seconds, with a default of 3 seconds.
- Application information now lists the sections containing the app, including hidden sections.
- Panel tooltips can now be toggled and are disabled by default.
- Added an option to turn off always-visible scrollbars.
- Fixed the custom date format editor: the input and preview stay above the keyboard, and Done moves focus to the dialog buttons.
- Fixed wallpaper slideshow transitions: the previous image stays on screen until the next one is ready.
- Removed the overall App Feeds heading from the home screen; the section name in settings is now fixed.
- Tidied up the System and Network widget menus.
- Remote control instructions in settings are now visible without expanding help.
- The presence of Google Cast alone no longer blocks disabling the stock launcher.
- Expanded service and network error diagnostics, including the HTTP status code when an update check fails.

## v1.6.8 — 2026-11-04

- Added NASA APOD as an online wallpaper source — the astronomy picture of the day.
- Added a custom date format with a preview and a format reference. Weather settings moved to the main Clock, date and weather page.
- Background clock, date and weather can now be placed independently above landscape mountains and weather effects.
- Added a configurable update interval for the System widget. The network menu now groups IPv4 and IPv6 addresses separately.
- Added Turn off TV and Restart TV actions to the remote button remapper. Turning off puts the device into standby; restarting requires configured ADB. Assigned power actions run without an additional confirmation.
- Added Google Drive Client ID and Client Secret import from JSON. Redesigned the connection page with a separate account status card and a reconnect action.
- Separated manual settings synchronization from full backup management. Backup names include the device model and ID, and the list identifies backups from the current TV. The ID persists across a normal reinstall with the same signing certificate; old backups remain accessible.
- Scrollbars in settings and menus stay visible while content overflows. Fixed nested top panel menu sizing and focus restoration when managing backups.
- Restored fitting app icons in full as the default while preserving user-selected modes. Improved navigation to file permissions on Android TV 12.

## v1.6.7 — 2026-11-03

- Added a download and upload speed widget with a configurable refresh interval. It can be enabled in the top bar and quick settings panel.
- Grouped network status, KVN, speed, and data usage under Network in panel object settings.
- Fixed ADB connection checks on older Android versions: a successful connection no longer fails while reading launcher information. Compatibility errors are no longer reported as connection failures.
- Fixed audio output information collection on older Android versions.
- Feed artwork now fills each card without distortion, cropping excess edges to remove extra margins around wide previews.
- Fixed the diagnostics export dialog: copy and save buttons display correctly, and the explanation is available in collapsed help.
- The 24-hour time format picker now shows morning and afternoon examples to distinguish formats with and without a leading zero.

## v1.6.6 — 2026-11-03

- Improved feed artwork sharpness when cropping images and enlarging the focused card.
- Added automatic artwork format selection and a separate format setting for each feed.
- Added remote-controlled reordering of selected feeds. The editor follows the section ordering layout, with drag handles, app labels and up/down arrows.
- Improved file access requests on Android TV 11–12: when the special access screen is unavailable, the launcher offers the app details page with an explanation of the required permission.
- Placed ADB and accessibility statuses side by side below the open apps panel title, above its action buttons.

## v1.6.5 — 2026-11-03

- Fixed signature validation during in-app updates on some TVs: a valid APK is no longer rejected solely because Android does not return signing certificate information.

## v1.6.4 — 2026-11-02

- Apps with a banner now default to **Fill with cropping** in **Tiles and labels** settings.

## v1.6.3 — 2026-11-02

- Added separate image modes for apps with and without banners: fit the whole image, fill with cropping, and fill unused space with the image edge color. Banners can also be replaced with an app icon; settings account for the tile shape and can be overridden per section.
- Added section background opacity and corner radius. Fixed layout of the selected number of complete grid rows, including labels and spacing.
- Added reordering of the wallpaper clock, date, and weather, plus weather warnings next to the temperature.
- Added volume hold modes when the button remapper is enabled: automatically pause interception while the system volume panel is visible, pause on a timer, generate repeats, or disable the workaround. Button mappings and Home interception are temporarily unavailable during a pause.
- Added an “Ignore button” action. Home screen and settings key sounds can now be enabled independently.
- Added an option to wait for internet before automatically launching an app. The KVN widget now supports connecting and disconnecting Incy.
- Improved opening TV inputs when the standard method fails. Added a CEC-only HDMI status option and fixed system HDMI names on Philips TVs.
- Strengthened protection of important system components and stock HOME dependencies during TV cleanup. Added per-package results for the last operation, including the reason and stage of failures.
- Fixed app list updates when returning Home and retries for unavailable tile images.
- Fixed slideshow wallpaper changes after returning from another app: the next change deadline is preserved, and an elapsed deadline advances to the next image.
- Clarified APK update validation failures. Diagnostics now include system-reported display, HDR, decoder, and audio output capabilities.

## v1.6.2 — 2026-11-02

- Fixed the all-files access permission route on TVs: the launcher prefers Android TV system settings over third-party permission filters. A clear message appears when no suitable screen is available.
- Fixed memory and CPU readings in the quick settings panel displayed over apps. CPU availability depends on the firmware and configured access.
- Fixed vertical movement of a lone single-row app section when scrolling with the mouse wheel.
- Added a banner fill setting for tiles, with a global value and separate choices for individual sections.
- Added a date format with an abbreviated weekday and a comma, such as “Sun, 1 Nov”.
- Updated Medeo Sans and Medeo Mono to version 1.0. Added Medeo Serif for the interface, panel, and clock.

## v1.6.1 — 2026-11-01

- Added independent placement for the clock, date and weather: each can stay in the top panel, move onto the wallpaper or be hidden. The wallpaper block has size, alignment, font, color and glow settings; mountains in the adaptive landscape overlap the lower part of the clock to create depth.
- Updated adaptive landscape clouds with varied shapes and sizes, slow movement at slightly different speeds and smooth wrapping at screen edges. Clouds and other weather effects appear above the wallpaper clock.
- Reworked Clock, date and weather settings with separate placement, panel appearance, wallpaper appearance, formats and data options. Quick settings have independent visibility and grouping; calendar and forecast views open according to the selected block's contents.
- Added Wallhaven online wallpapers with Mixed, Nature, Space, Cities and Minimalism themes, manual switching and scheduled updates. No account or API key is required; availability depends on the network and provider.
- Added a KVN widget with client selection, supported connection controls and TV startup settings. Available actions depend on the KVN client and firmware.
- Added volume and current audio output to the top panel, plus a System widget with memory, storage and CPU/RAM charts. Individual readings depend on the device and granted access.
- Added content feeds from installed apps, with channel selection, section appearance settings and opening content from the home screen. App and system support is required.
- Reworked settings with grouped help, clearer shared and individual appearance options, and improved remote navigation, focus and scrolling in long lists.
- Updated the built-in file browser with a more compact header and controls, accessible full paths, improved wallpaper folder selection and file saving without overwriting files with the same name.
- Improved the weather forecast and calendar, and added app selection for background startup with the TV.
- Added launcher settings reset and full app data reset with confirmation. New installations receive prepared initial settings.
- Fixed night filter flicker after sleep, feed artwork refresh, backup saving and cloud storage error handling. Improved recovery of previously granted permissions.
- Improved KVN configuration and TV startup behavior, including handling of autostart restrictions, cancelled actions, removed clients and connection confirmation.
- Open apps settings now show the status of required access and provide shortcuts to configure it. Unavailable TV input settings are no longer offered for editing.
- Added suitable-file filtering, file size and modification date to the file browser. Long names expand when truncated, with improved access to controls and remote navigation.
- Fixed clipping of enlarged tiles and glow at section edges, neighboring tiles covering the focused tile, focus rendering in feeds and thin seams in glow effects. Improved card spacing and section behavior when hiding or restoring sections.
- Fixed the top boundary of home screen scrolling so tiles and their focus effects stay outside the top panel area.
- Fixed lost focus when selecting feeds or opening the apps panel, unnecessary settings scrolling, deletion cancellation and preservation of remote button assignment drafts. Clarified messages for saving, export, backups and cloud storage disconnection.
- Made network, notification, media, TV input and online wallpaper updates more robust when leaving and returning to the launcher. Online wallpaper failures now show the source, stage and cause in settings and diagnostic reports.
- Improved performance by reducing unnecessary updates and repaints and optimizing section and feed scrolling, tile focus animation, backgrounds, weather effects and app list loading in settings.

## v1.5.1 — 2026-10-28

- Fixed recovery of button remapping access after an update when Android blocks accessibility. Previously granted access and a configured ADB connection are required.

## v1.5.0 — 2026-10-28

- **Noticeably faster in everyday use.** Home screen preparation time is down by almost **40%**, total cold startup time by about **15%**, and return-to-home time by almost **20%**. Figures are rounded from controlled measurements; results depend on the device and settings.
- Optimized interface rendering and sped up opening quick settings, the inputs menu, the sleep timer, and the open apps panel for more responsive controls.
- Added the Open apps panel with app switching, individual app closing, and Close all for user apps. Settings let you choose the built-in panel or an available system panel.
- Open apps can be assigned to a remote button. Home supports a separate long-press action while a short press still returns to the launcher.
- Improved the remote mapping editor with a separate button capture dialog, app icons in the picker, webhook URL import from a text file, and deletion confirmation. Removed the Action completed line from the mappings list.
- Added the Medeo Sans and Medeo Mono fonts for the interface, panel, and clock.
- Fixed navigation from Continue Watching across empty sections and improved focus retention.
- Fixed night mode schedule resumption and improved permission recovery and accessibility service connection monitoring.

## v1.4.2 — 2026-10-27

- Fixed thin anti-aliasing seams inside Medeo Pixel characters that appeared at certain text sizes and positions.

## v1.4.1 — 2026-10-27

- Added a recent apps panel with app switching, individual app closing, and Close all for user apps. Settings let you choose the built-in panel or an available system panel.
- Recent apps can be assigned to a remote button. Home supports a separate long-press action while a short press still returns to the launcher.
- Added the Medeo Sans, Medeo Mono, and Medeo Pixel font families for the interface, panel, and clock.

## v1.4.0 — 2026-10-26

- Added Android 9 and 10 support, including file access, backups, update installation, and system permissions.
- Improved video wallpaper compatibility: after a playback failure on Android 10 or later, the launcher automatically tries another video output mode. Codec support depends on the device.
- Fixed a false diagnostic error on TCL devices where the system picture filter is unavailable.
- Expanded the catalog of preinstalled app descriptions for the TV cleaner.

## v1.3.1 — 2026-10-26

- Fixed text being clipped at the top and bottom in settings, including labels, values, and buttons using Manrope.
- Added a separate one-time confirmation when disabling the stock launcher carries an identified risk of losing saved Wi-Fi networks. Disabling remains blocked if Wi-Fi safety cannot be determined.

## v1.3.0 — 2026-10-26

- Added local video wallpapers with silent looping playback. Codec support depends on the TV; video files are not included in backups.
- Reworked the TV cleanup manager with app groups, a protected baseline state, named snapshots, restoration, and export. The state of selected apps is saved automatically before disabling them through a list. Restoration requires local ADB.
- Added sleep timer settings: custom intervals, ordering and visibility controls, display options, and optional seconds.
- Updated notifications: launcher messages and app notifications now share one stack that can appear in any screen corner. Fixed notification actions and entrance and exit animations.
- The traffic menu now shows downloaded, uploaded, and total data for the day, week, and month together.
- Added an option to stop a running app from its information menu when ADB is active.
- Combined diagnostics into a single report covering TV details, compatibility, and errors. Reports should be sent to the author privately.
- Added recovery of previously granted access after updates when a saved access state and configured ADB are available.
- Unified widget menus and settings across the main and popup panels. Fixed navigation, focus retention, panel sizing, and minor visual issues; weekends are now highlighted in red in the calendar.

## v1.2.1 — 2026-10-24

- Added Power management under Launcher and TV controls, with buttons for standby and restart. Actions require confirmation; standby requires the CuteLauncher accessibility service or local ADB, while restart requires ADB.
- Fixed mouse wheel scrolling over a highlighted app tile. In app strips, the wheel scrolls apps horizontally and passes scrolling to the page at the edge.

## v1.2.0 — 2026-10-24

- Updated adaptive landscapes with smooth lighting transitions, richer sunrises and sunsets, a distinct evening twilight palette, and more pronounced seasonal differences.
- The sun and moon follow separate arcs. The night sky now features meteors with fading trails and an optional star rotation setting. Weather effects have been reworked.
- Added a landscape demonstration showing changes in time of day, seasons, and weather, with an option to stop playback.
- Added connection details and current download and upload rates to the network menu. Fixed traffic totals for the selected period; unavailable history now appears as a dash. Ethernet traffic history can also be read through a configured local ADB connection.
- Combined clock, date, and weather settings. Unified the appearance of top panel menus, added wraparound navigation between its buttons, and introduced a wallpaper refraction effect in text and icons.
- Fixed clipped text in settings, font weight selection, category appearance inheritance, and the initial app highlight when opening the home screen.
- Fixed weather updates, hidden app filters, and slideshow intervals being reset by unrelated settings changes.
- Added a recovery screen after repeated launcher startup crashes.

## v1.1.4 — 2026-10-22

- Fixed delayed controls when returning to the home screen with the Home button.
- Added MET Norway as a weather source without an API key. Forecasts are adapted from MET Norway data under CC BY 4.0; precipitation probability is not shown for this source.

## v1.1.2 — 2026-10-22

- Fixed repeated app sorting changes: returning to the original mode now applies and saves correctly.
- Fixed text being clipped at the top and bottom in settings buttons using Manrope, including multiline values in the Glass style.
- Public release descriptions now include links to the Russian and English changelogs.

## v1.1.1 — 2026-10-22

- Fixed saving the manual app order in All Apps, TV Apps, and Non-TV Apps: the order survives restarts and settings reloads, including when apps are hidden.
- The build number is hidden from the displayed version. APK filenames now include the app version.

## v1.1.0+75 — 2026-10-22

- CuteLauncher 1.1 leaves beta as a public stable release. APKs and source code are available in the public repository; this release is not marked as a prerelease.

- Added Glass, Soft, and Outline interface styles, plus language-aware Google Sans, Onest, Manrope, and Outfit font choices. Fixed the selected font being applied to the open settings panel.
- Added adaptive landscapes with illustrated and photorealistic variants, time-of-day and seasonal changes, and weather effects. Artwork from the selected app can also be used as the background.
- The clock, date, and weather can be combined into one top-panel block. TV input buttons show connection status when the firmware provides it.
- Added TV compatibility diagnostics, a device catalog, and a cleanup manager with a preview of packages to disable and recovery of their previous states. Fixed app inventory access on Android 14. Availability depends on firmware and permissions; third-party disable lists are not considered verified for every TV.
- Reorganized remote button remapping settings and assignment editing. Made adjustments to the active night filter smoother and strengthened protection of saved Wi-Fi when disabling the initial setup wizard.
- Updated the Russian and English user documentation and added a gallery of 12 screenshots in 4K. Public source code is published as a separate snapshot without internal documentation or private development history.
- Reddit wallpapers remain unavailable; use Bing or a custom URL for online wallpapers.

Historical APKs are available in [releases](https://github.com/KirillShchetinnikov/CuteLauncher-Releases/releases).
Entries for older versions have not been reconstructed retrospectively.
