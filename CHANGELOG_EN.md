# CuteLauncher changelog

[Русский](CHANGELOG_RU.md) · [English](CHANGELOG_EN.md) · [About the launcher](README_EN.md)

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
