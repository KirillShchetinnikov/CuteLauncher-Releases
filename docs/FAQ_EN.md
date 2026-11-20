# CuteLauncher: frequently asked questions

[Русский](FAQ_RU.md) · [English](FAQ_EN.md) · [All documentation](README_EN.md)

Quick answers about setup and key features. Paths start in CuteLauncher settings
unless stated otherwise. Follow the guide links for details.

## Where do I start and which APK should I choose?

You need Android TV or Google TV with Android 9 or later. The universal APK supports
ARMv7 and ARM64; separate APKs are also available for each of these architectures.
For an x86_64 device or emulator, choose the separate x86_64 APK.
Allow installation from the selected source.
[Download and installation](README_EN.md#downloads-and-installation).

## How do I open settings and change the language?

Select the top panel gear. Arrow keys move focus, OK selects an item, and Back
goes back. Open **Launcher settings → Language** to choose the app language or
follow the system language. Use the help button next to a setting for details.
[Controls](USER_GUIDE_EN.md#controls-and-settings).

## How do I make CuteLauncher the default launcher?

**The preferred method is to use built-in ADB and disable the stock launcher.**
If ADB is unavailable or you want to keep the stock launcher enabled, try Home Button Fix.

| Method | What changes | What you need |
| --- | --- | --- |
| Set via ADB | CuteLauncher becomes Android's home app. If it finds an enabled stock launcher, it offers to disable it while setting the default. | A working ADB connection on the TV or box and firmware that supports the action. |
| Home Button Fix | Pressing Home opens CuteLauncher. Android keeps its existing home app. | The accessibility service. Your firmware must pass Home presses to it. |
| Android launcher picker | Android makes CuteLauncher the home app. The stock launcher stays enabled. | This works on the few firmware versions that let you select CuteLauncher and keep that choice. |

### 1. Set the default with built-in ADB

1. On your TV or box, open the system **Settings → System → About**. On some Android TV devices, the path is **Settings → Device Preferences → About**.
2. Find **Android TV OS build** or **Build number** and press **OK** on the remote seven times, until you see a message saying you're now a developer.
3. Go back one screen, open **Developer options**, and turn on **USB debugging**. Select **OK** if Android asks you to confirm. Menu names vary by firmware. [Android Developer options](https://developer.android.com/studio/debug/dev-options#enable).
4. If the same menu has a separate **Network debugging** or **ADB over network (TCP)** setting, turn it on. CuteLauncher's built-in ADB connects over TCP. Some firmware requires you to enable the TCP port separately after turning on USB debugging.
5. In CuteLauncher, open **Default launcher and ADB → ADB connection**. Keep port `5555` unless the device uses a different one. Select **Check connection** and approve Android's debugging prompt if it appears.
6. Press Back and open **Set default launcher via ADB**. On the **Default launcher** page, select **Set CuteLauncher as default launcher via ADB**. Review the proposed changes and confirm. When it finishes, check the home app status and press Home from another app.

Disabling the stock launcher can affect manufacturer-specific menus and remote buttons. If TCP ADB or setting the default is unavailable, try Home Button Fix.

To undo the change, keep ADB connected and select **Restore the previous default launcher via ADB**. If you also turned on Home interception or startup, switch them off separately.

### 2. Set up the Home button and keep the stock launcher enabled

1. Open **Default launcher and ADB → Set default launcher via accessibility**. On the **Home button and startup** page, select **Open accessibility settings**.
2. Enable the CuteLauncher service in Android's accessibility settings. If the menu fails to open, go to the TV's system settings manually.
3. Return to **Home button and startup** and enable **Override the Home button**. Open another app and test Home on the remote.

If Home still opens the stock launcher with both settings enabled, your firmware may be blocking Home presses from reaching the service. To open CuteLauncher after a full boot, use the separate **Start when the device turns on** switch on the same page. Android or the firmware may restrict startup. To restore normal Home button behavior, turn off **Override the Home button**.

### 3. Choose CuteLauncher in Android settings

Use this method if you know your firmware supports changing launchers in Android settings and you know how to switch back.

1. Open the gear in CuteLauncher → **Default launcher and ADB → Set default launcher via ADB**.
2. Select **Open system default launcher setting**, then choose **CuteLauncher**.
3. Open another app and press **Home** on the remote. Check that CuteLauncher opens. The **Default launcher** page shows which home app Android selected.

If the system picker fails to open, omits CuteLauncher, or keeps the previous choice, use method 1 or 2. To return to the stock launcher after using the picker, select it in the same Android menu.

[Home app and device controls](USER_GUIDE_EN.md#launcher-and-device-controls).

## Must I configure ADB and grant every permission?

Ordinary app launching does not need ADB. The app disabling manager and some TV controls
require it. Grant other access as needed: for example, notifications need notification
access, and the remapper needs accessibility access.
[Permission table](USER_GUIDE_EN.md#permissions-and-limitations).

## How do I create a category and reorder apps?

Open Home screen → Sections and order: create a category, add apps, choose their
order and a row or grid layout. Long-press a tile to open app actions. Built-in
categories can be hidden or moved but cannot be deleted.
[Categories](USER_GUIDE_EN.md#home-screen-and-categories).

## An app disappeared. How do I restore its tile?

Check Applications → Hidden Apps and select Show. This also restores hidden CuteLauncher
and Android settings tiles. Check the category visibility too. Hiding a tile does
not disable the app in Android; check disabled packages separately in the app disabling
manager. [Apps](USER_GUIDE_EN.md#apps).

## How do I change tiles, colors, fonts and menu style?

Use Home screen for tiles and sections, and Widgets and panels → Top panel →
Appearance for the top panel. Choose the interface style under Launcher settings →
Interface style. Individual categories can override or inherit shared settings.
Available fonts depend on the
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
preserves the previous background. [File access](USER_GUIDE_EN.md#permissions-and-limitations).

## Why is Continue Watching empty or incomplete?

Cards come from Android Watch Next, populated by the apps themselves. Check category
visibility, selected apps and card limits in Home screen → Sections and order →
Continue Watching. If a service does not publish its history, the launcher cannot
obtain it independently. [Continue Watching](USER_GUIDE_EN.md#continue-watching).

## How do I enable weather and fix stale data?

Open Widgets and panels → Widget settings. Under Clock, date and weather,
open Settings, then Weather settings. Choose a source and set a city or
coordinates. Check the internet connection and refresh. Breezy
Weather requires a configured compatible app; OpenWeather and Yandex require
personal keys. MET Norway needs no key. Older cached data may appear when the
source is unavailable. [Weather](USER_GUIDE_EN.md#weather).

## How do I hide or reorder widgets and open the calendar?

Open Widgets and panels → Top panel → Objects. Select the date or combined block to
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

Enable Inputs under Widgets and panels → Top panel → Objects. The list and switching are determined by
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

Open Launcher features and, under Screensaver, select Screensaver Clock Style
or Choose screensaver in Android TV. This group appears if Android lets you
choose a screensaver.
[Clock and screensaver](USER_GUIDE_EN.md#clock-and-screensaver).

## Will the timer fully power off the TV?

The timer puts the device into standby without cutting electrical power. An exact
deadline requires exact-alarm permission; standby requires an available system
action or ADB. With a TV box, the effect on the television also depends on HDMI-CEC
and firmware. [Sleep timer](USER_GUIDE_EN.md#sleep-timer).

## Why does holding a volume button change only one step?

On some Android TV/Google TV firmware, accessibility key filtering interferes
with native volume repeat. This can also affect other apps while the remapper
service is enabled.

Open “Launcher features → Remote button remapper → Hold volume buttons”.
Enabling the remapper uses Auto by default; an explicitly selected mode is
preserved when the remapper is turned off and on again.

- **Auto: while the panel is visible.** Showing the system volume panel temporarily
  releases key filtering. After the selected pause, the launcher checks the window
  and extends the pause while it is available and visible. If the window cannot
  be identified, a timer is used instead.
- **Timed pause.** Filtering resumes after the selected 3, 5, 10, 15 or 30 seconds
  following the last recognized panel appearance. Try this if Auto is unreliable
  on your firmware.
- **Custom repeat.** The launcher adjusts volume while the button is held. This
  requires the device to deliver both volume press and release events to the
  service. Some TVs may produce double steps; use another mode in that case.
- **Disabled.** No workaround is applied; other button assignments are preserved.

Button assignments and Home interception are unavailable during a pause.
Auto limits a continuous pause to one minute. The first hold may change only
one step: release and hold again while the indicator is visible. After updating,
if window access is unavailable, turn the CuteLauncher service off and on again
in system accessibility settings. Panel availability depends on firmware; the
setting can be used on different TV brands and is not restricted to TCL.
If volume behavior gets worse, change the mode or disable the workaround.

## How do I remap a button and open quick settings over an app?

In Launcher features → Remote button remapper, create a mapping, capture
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

## Does the app disabling manager delete apps? How do I undo disabling?

It changes package enabled states while keeping APKs and data. Local ADB is
required; start by refreshing the list. Use Backup and restore inside the manager
to revert changes. State backups are firmware-specific; keep the launcher’s data
while you need them. Another device’s list does not guarantee safety for your TV.
[App disabling manager](USER_GUIDE_EN.md#app-disabling-manager).

## How do I save settings and move them to another TV?

Under Launcher settings, find the Settings management group. Use Export Backup,
then Import Backup on the other TV. You can configure backup storage in the same
group. Backups contain supported settings, categories and
appearance, but not apps or the whole system. Android access grants and ADB
authorization do not transfer. Synchronizing several TVs requires a shared
accessible folder or cloud storage. [Backups](USER_GUIDE_EN.md#backups-and-synchronization).

## How do I update without losing settings?

Use Launcher settings → Application updates or install a newer APK with the same signature over the
current app. Keep the app installed when updating. If installation fails, check
architecture, package and signature compatibility. If the remapper or notifications
stop working after an update, check their Android access settings.
[Updates](USER_GUIDE_EN.md#updates-and-app-information).

## What can I do if the interface feels slow?

Open Diagnostics → Memory, refresh the measurements and try resource-saving mode.
It limits heavy effects; turning it off restores saved preferences. You can also
clear supported image caches. Clearing a cache is different from clearing app
data. [Memory](USER_GUIDE_EN.md#memory-and-resource-saving).

## How do I report a problem?

Open Settings → Diagnostics → Diagnostics. If the failure already happened,
select Create report. For a detailed report, start extended diagnostics,
reproduce the issue, and return to finish recording. Select Export report →
Save to disk and send the file privately to the author with the steps and
expected result. Redaction may miss personal data. Nothing is sent automatically.

Sending it to the author means you agree to publication of the anonymized TV
compatibility portion in the CuteLauncher Git repository; errors, commands and
your settings are not published.
[Reporting instructions](USER_GUIDE_EN.md#reporting-an-issue).
