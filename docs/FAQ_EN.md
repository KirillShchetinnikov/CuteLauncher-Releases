# CuteLauncher: frequently asked questions

[Русский](FAQ_RU.md) · [English](FAQ_EN.md) · [All documentation](README_EN.md)

Quick answers about setup and key features. Paths start in CuteLauncher settings
unless stated otherwise. Follow the guide links for details.

## Where do I start and which APK should I choose?

You need Android TV or Google TV with Android 9 or later. If you do not know the
architecture, choose the universal APK; otherwise choose ARMv7, ARM64 or x86_64
for your device. Allow installation from the selected source.
[Download and installation](README_EN.md#downloads-and-installation).

## How do I open settings and change the language?

Select the top panel gear. Arrow keys move focus, OK selects an item, and Back
goes back. Choose the language in Advanced, independently of the system language
or following it. Expand Details for explanations of settings.
[Controls](USER_GUIDE_EN.md#controls-and-settings).

## Why does Home return to the stock launcher?

In Launcher and TV controls, check the current home app and select CuteLauncher
through the system launcher picker. If the firmware does not allow this, supported
local ADB assignment and Home interception through the accessibility service are
available. Their operation depends on the firmware. You can start without disabling
the stock launcher. [Home app and TV controls](USER_GUIDE_EN.md#launcher-and-tv-controls).

## Must I configure ADB and grant every permission?

Ordinary app launching does not need ADB. The cleanup manager and some TV controls
require it. Grant other access as needed: for example, notifications need notification
access, and the remapper needs accessibility access.
[Permission table](USER_GUIDE_EN.md#разрешения-и-ограничения).

## How do I create a category and reorder apps?

Open Home screen → Categories and order: create a category, add apps, choose their
order and a row or grid layout. Long-press a tile to open app actions. Built-in
categories can be hidden or moved but cannot be deleted.
[Categories](USER_GUIDE_EN.md#home-screen-and-categories).

## An app disappeared. How do I restore its tile?

Check Apps → Hidden apps and select Show. This also restores hidden CuteLauncher
and Android settings tiles. Check the category visibility too. Hiding a tile does
not disable the app in Android; check disabled packages separately in the cleanup
manager. [Apps](USER_GUIDE_EN.md#apps).

## How do I change tiles, colors, fonts and menu style?

Use Home screen → Appearance, Appearance, and Top panel → Appearance. Choose the
interface style in Appearance → Settings style → Interface style. Individual
categories can override or inherit shared settings. Available fonts depend on the
language; bundled fonts work offline. [Appearance](USER_GUIDE_EN.md#appearance-and-backgrounds).

## Can I use my own wallpaper or video?

Choose Local image or video, then Source settings → Choose file. Videos must be
no larger than 256 MiB and 3840×2160, with a codec supported by the TV; MP4/H.264
is preferred. Playback loops without sound. Videos are not included in backups:
select them again after transferring settings. Slideshows, online wallpapers,
gradients and adaptive landscapes are also available.
[Background sources and limits](USER_GUIDE_EN.md#appearance-and-backgrounds).

## Why does the file or folder picker not open?

Some TVs have a nonfunctional placeholder for the system picker. Install a
compatible file manager and try again. Canceling or failing to select a background
preserves the previous background. [File access](USER_GUIDE_EN.md#разрешения-и-ограничения).

## Why is Continue Watching empty or incomplete?

Cards come from Android Watch Next, populated by the apps themselves. Check category
visibility, selected apps and card limits in Home screen → Categories and order →
Continue Watching. If a service does not publish its history, the launcher cannot
obtain it independently. [Continue Watching](USER_GUIDE_EN.md#continue-watching).

## How do I enable weather and fix stale data?

Open Top panel → Objects → Block settings → Weather settings, choose a source
and a city or coordinates. Check the internet connection and refresh. Breezy
Weather requires a configured compatible app; OpenWeather and Yandex require
personal keys. MET Norway needs no key. Older cached data may appear when the
source is unavailable. [Weather](USER_GUIDE_EN.md#weather).

## How do I hide or reorder widgets and open the calendar?

Open Top panel → Objects / Object order. Select the date or combined block to
open the calendar, provided the date is visible and the calendar is enabled.
Quick settings panel items are selected separately; widget settings are shared.
[Top panel](USER_GUIDE_EN.md#top-panel-and-widgets).

## Why are notifications or the player card missing?

Enable the relevant panel item and grant Android notification access. Check whether
the app is blocked in notification settings. Enable Now playing for the player
card: it appears only when a media session is available, and the player provides
the actions. [Notifications](USER_GUIDE_EN.md#notifications-and-playback).

## Why does traffic show “—”, and why is Wi-Fi speed different from internet speed?

Traffic history needs usage access; configured local ADB can help with Ethernet
on some firmware. Android updates history with a delay, and unavailable data is
shown as “—”. Wi-Fi speed in the network menu is the link speed to the access
point, not an internet speed test. [Network and traffic](USER_GUIDE_EN.md#top-panel-and-widgets).

## Why are HDMI inputs missing or switching unavailable?

Enable Top panel → Objects → Inputs. The list and switching are determined by
the firmware. A TV box’s HDMI connector does not provide access to all television
inputs. The input indicator shows source connection, not the selected input.
[TV inputs](USER_GUIDE_EN.md#tv-inputs).

## Why does the night filter only work in the launcher or fail to follow its schedule?

Allow drawing over other apps for filtering outside the launcher. Check app and
input exclusions; detecting the active app requires usage access. For the schedule,
check the main filter switch, times and the sunset/sunrise location. If a temporary
override is active, select Return to schedule. The schedule cannot enable a filter
disabled by its main switch. Backlight adjustment is configured separately and
depends on the firmware. [Night mode](USER_GUIDE_EN.md#night-mode-and-brightness).

## How do I enable the clock screensaver?

Open Appearance → Screensaver clock style / Screensaver settings if Android
provides these settings. System screensaver availability depends on the device.
[Clock and screensaver](USER_GUIDE_EN.md#clock-and-screensaver).

## Will the timer fully power off the TV?

The timer puts the device into standby without cutting electrical power. An exact
deadline requires exact-alarm permission; standby requires an available system
action or ADB. With a TV box, the effect on the television also depends on HDMI-CEC
and firmware. [Sleep timer](USER_GUIDE_EN.md#sleep-timer).

## How do I remap a button and open quick settings over an app?

In Launcher and TV controls → Remote button remapper, create a mapping, capture
the button, choose the panel-opening action and save. Enable the mapping,
accessibility service and required access for displaying over apps. Short and
long presses are supported; Home supports only a long-press mapping. Power is
excluded, and voice and vendor buttons may not reach the service. Double presses
are not supported. [Remapper](USER_GUIDE_EN.md#remote-remapper-and-quick-settings-panel).

## Why does the open-apps panel not show every process?

The built-in CuteLauncher panel shows TV apps with tasks, not every background
process. It needs authorized local ADB and a connected accessibility service.
Closing an individual task does not guarantee its services stop. Close all
force-stops listed user apps, including playback.
[Open apps](USER_GUIDE_EN.md#open-apps).

## Does the cleanup manager delete apps? How do I undo disabling?

It changes package enabled states while keeping APKs and data. Local ADB is
required; start by refreshing the list. Use Backup and restore inside the manager
to revert changes. State backups are firmware-specific; keep the launcher’s data
while you need them. Another device’s list does not guarantee safety for your TV.
[Cleanup manager](USER_GUIDE_EN.md#tv-cleanup-manager).

## How do I save settings and move them to another TV?

In Advanced → Backup and restore, export a file and import it on the other TV,
or configure backup storage. Backups contain supported settings, categories and
appearance, but not apps or the whole system. Android access grants and ADB
authorization do not transfer. Synchronizing several TVs requires a shared
accessible folder or cloud storage. [Backups](USER_GUIDE_EN.md#backups-and-synchronization).

## How do I update without losing settings?

Use Advanced → Updates or install a newer APK with the same signature over the
current app. Keep the app installed when updating. If installation fails, check
architecture, package and signature compatibility. If the remapper or notifications
stop working after an update, check their Android access settings.
[Updates](USER_GUIDE_EN.md#updates-and-app-information).

## What can I do if the interface feels slow?

Open Advanced → Memory, refresh the measurements and try resource-saving mode.
It limits heavy effects; turning it off restores saved preferences. You can also
clear supported image caches. Clearing a cache is different from clearing app
data. [Memory](USER_GUIDE_EN.md#memory-and-resource-saving).

## How do I report a problem?

Reproduce it, then open Settings → Advanced → Diagnostics → Create report →
Export report → Save to disk. Send the file privately to the author with the
steps and expected result. Do not post it publicly: sanitization may miss
personal data. Nothing is sent automatically.

Sending it to the author means you agree to publication of the anonymized TV
compatibility portion in the CuteLauncher Git repository; errors, commands and
your settings are not published.
[Reporting instructions](USER_GUIDE_EN.md#reporting-an-issue).
