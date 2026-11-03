# CuteLauncher changelog

[Русский](CHANGELOG_RU.md) · [English](CHANGELOG_EN.md) · [About the launcher](README_EN.md)

## v1.6.7 — 2026-11-03

- Added a download and upload speed widget with a configurable refresh interval. It can be enabled in the top bar and quick settings panel.
- Grouped network status, VPN, speed, and data usage under Network in panel object settings.
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
- Added an option to wait for internet before automatically launching an app. The VPN widget now supports connecting and disconnecting Incy.
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
- Added a VPN widget with client selection, supported connection controls and TV startup settings. Available actions depend on the VPN client and firmware.
- Added volume and current audio output to the top panel, plus a System widget with memory, storage and CPU/RAM charts. Individual readings depend on the device and granted access.
- Added content feeds from installed apps, with channel selection, section appearance settings and opening content from the home screen. App and system support is required.
- Reworked settings with grouped help, clearer shared and individual appearance options, and improved remote navigation, focus and scrolling in long lists.
- Updated the built-in file browser with a more compact header and controls, accessible full paths, improved wallpaper folder selection and file saving without overwriting files with the same name.
- Improved the weather forecast and calendar, and added app selection for background startup with the TV.
- Added launcher settings reset and full app data reset with confirmation. New installations receive prepared initial settings.
- Fixed night filter flicker after sleep, feed artwork refresh, backup saving and cloud storage error handling. Improved recovery of previously granted permissions.
- Improved VPN configuration and TV startup behavior, including handling of autostart restrictions, cancelled actions, removed clients and connection confirmation.
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
