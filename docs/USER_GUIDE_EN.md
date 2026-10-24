# CuteLauncher: feature guide

[Русский](USER_GUIDE_RU.md) · [English](USER_GUIDE_EN.md) · [All documentation](README_EN.md)

CuteLauncher is a remote-controlled home screen for Android TV / Google TV.
Requires Android 11 or later, with ARMv7, ARM64, and x86_64
builds. System features
depend on permissions, available menus, and manufacturer firmware.

This guide describes CuteLauncher features. Install the corresponding APK
update to get new features. Requirements and limitations appear beside each feature.

## Contents

- [Controls and settings](#controls-and-settings)
- [Home screen and categories](#home-screen-and-categories)
- [Apps](#apps)
- [Appearance and backgrounds](#appearance-and-backgrounds)
- [Continue Watching](#continue-watching)
- [Top panel and widgets](#top-panel-and-widgets)
- [Weather](#weather)
- [Notifications and playback](#notifications-and-playback)
- [TV inputs](#tv-inputs)
- [Night mode and brightness](#night-mode-and-brightness)
- [Clock and screensaver](#clock-and-screensaver)
- [Sleep timer](#sleep-timer)
- [Launcher and TV controls](#launcher-and-tv-controls)
- [Remote remapper and floating panel](#remote-remapper-and-floating-panel)
- [TV cleanup manager](#tv-cleanup-manager)
- [Backups and synchronization](#backups-and-synchronization)
- [Updates and app information](#updates-and-app-information)
- [Memory and resource saving](#memory-and-resource-saving)
- [Diagnostics](#diagnostics)
- [Device data and reports](#device-data-and-reports)
- [Permissions and limitations](#permissions-and-limitations)

## Controls and settings

Use the directional pad to move focus and OK to activate the selected item.
Hold an app tile to open its actions. Back returns from a nested screen;
its home-screen behavior is configurable. Home returns to the launcher when
the default home app or Home interception is configured correctly. You can
choose the focus target after Home and enable navigation sounds.

Settings are grouped into Home screen, Top panel, Appearance, Apps, Night mode
and brightness, Launcher and TV controls, and Advanced. Android TV system
settings open separately. Help is collapsed under More details. Choose an
app language in Advanced independently of Android, or follow the system language.
Back returns to the previous settings page. Expanding help should not replace
the selected item's normal action.

## Home screen and categories

Path: **Home screen → Categories and order**.

Create, rename, and delete categories; add apps; reorder apps and categories;
hide categories and restore them. Favorites is edited like any other category.
Automatic app lists are built from installed apps. Enable and move Continue
Watching in the same editor.

Choose rows or grids, sorting, column and visible-row counts, scrolling, active
category pinning, sizes, spacing, headings, backgrounds, and margins. Some
appearance settings are shared, while others can be overridden per category.
A link icon marks shared values; changes to shared settings apply immediately,
including to existing categories. Choosing a value that matches the shared one
restores inheritance. In Tiles and labels, one Restore common settings button
restores all settings on that screen. Titles, icons, padding and background are
available directly in the category appearance editor. Reset category layout also
restores its shared appearance and clears padding, keeping apps and their order.
CuteLauncher and system settings tiles can be hidden.

## Apps

Path: **Apps**, or the selected tile's actions.

Lists include All apps, System apps, and Hidden apps. Hidden apps also includes
CuteLauncher and Android settings when their tiles are hidden by the dedicated
switches. Show restores the tile and turns off its hide switch. App details show its name,
package, and version. Launch an available app, open Android app information,
request uninstall where Android allows it, hide or restore it, add it to a
category, and change its tile. Set a custom tile banner or restore the default.

Hiding an app removes it from automatic launcher lists; it does not disable
the app in Android. The normal system-app list belongs to the launcher catalog.
For the complete installed-package list, including background system components,
use the [cleanup manager](#tv-cleanup-manager).

## Appearance and backgrounds

Paths: **Home screen → Appearance**, **Appearance**, **Top panel → Appearance**.

Customize tiles and labels, sizes and spacing, shapes and backgrounds, focus
outlines, zoom and animations, accent color, categories, and the top panel.
Menus and notifications have background, transparency, color, and text-scale
settings. Menus can open on either side. Reset individual groups or all appearance.

**Appearance → Settings style → Interface style** offers Standard, Glass, Soft,
and Outline. They change panel materials, buttons, focus, switches and sliders
while preserving placement, dimensions and remote control. Custom colours and
transparency remain. Standard stays the initial style. Choose fonts separately
for the interface, top panel and clock: Google Sans, Onest, Manrope, Outfit or
the system font; the panel and clock also retain their earlier families.
Only fonts supporting the current interface language are listed. For example,
Outfit is unavailable for Russian. New styles default to Outfit for compatible
languages and Manrope for Cyrillic. Switching languages temporarily substitutes
Manrope or the system font if the saved font is incompatible; switching back
restores the previous choice. All fonts are bundled and work offline.

Background sources:

- A gradient with your chosen colors.
- A local image, including separate day and night wallpapers.
- A folder slideshow with subfolders, order, interval, and next-image controls.
- Bing online wallpapers or an image URL with available update options.
- Selected app colors: a soft background derived from the focused tile's banner or icon.
- Adaptive landscape: an illustrated valley or realistic nature with four seasons. Spring has fresh light greenery and a flowering meadow, plus blossoming trees in the illustrated valley; summer has deep greenery and warm golden grasses.

After selecting this source, open **Home screen → Background → Source parameters**.
Time of day, seasons, clouds, rain/snow, fog and weather animation have independent
switches. Disabling time of day keeps daylight; disabling seasons keeps summer.
The **Sun and moon** switch shows or hides both bodies together in the illustrated
and realistic landscapes, including the preview. The sun moves across the sky
and disappears completely behind the horizon; the moon appears at night.
Stars are scattered irregularly across the sky, with occasional tailed meteors that move and fade away.
The separate **Star rotation** switch enables slow rotation of the night sky,
and is off by default. The preview always shows rotation according to its simulated time.
Sun times come from the Night mode cache; without them, sunrise is at 06:00 and
sunset at 18:00. The first visible solar pixels emerge above the mountains at local sunrise, and the last disappear at local sunset. Ambient lighting transitions from 40 minutes before sunrise to 40 minutes after it; evenings pass through sunset and a separate violet twilight before night, 80 minutes after sunset. Transitions shorten on days with little daylight.
The **Demonstrate changes** button in landscape settings starts at the current time and previews a full day at variable speed: a steady hour passes in about a third of a second, while an hour within the glow takes four seconds. Fast time resumes as soon as the glow ends. Dawn and sunset slow down so the color changes remain visible. The glow spreads across the sky in soft waves from the sunrise or sunset point, strongest near the sun and much weaker on mountains and forest. It starts 10 minutes before sunrise or an hour before sunset and fades out an hour after sunrise or 10 minutes after sunset; the sun already emerges from behind the mountains red-orange and becomes lighter after sunrise. In the evening, it starts turning red 40 minutes before the local sunset and stays red as it disappears behind the mountains. Moderately dense rain falls down and slightly left, parallel to its streaks, and remains visible in both the regular weather effect and the preview. Four pairs follow: summer with clouds, autumn with rain, winter with snow, and spring with fog. Each season appears clear for 2 seconds, followed by its weather effect for 3 seconds. Seasonal images crossfade smoothly in 0.5 seconds. The preview ends automatically after one full run. You can also stop it by pressing **Stop**, leaving the screen, or moving the app to the background. The preview enables weather movement and star rotation even when the normal switches are off, without changing saved settings; sun and moon visibility follows their switch. During the preview, settings are completely hidden. At the top center of the screen, a progress bar without numbers shows the full run, followed by the current effect and simulated time, and a **Stop** button to the right of the caption. Stop or Back cancels the preview and restores the same settings page; Home cancels it and returns to the home screen.

Sky colors and landscape lighting change gradually throughout sunrise and sunset. Seasons follow the month and hemisphere: automatic
selection uses weather coordinates, then Night mode coordinates, then Northern.
You can explicitly choose Northern or Southern Hemisphere.

Weather effects use current data from your selected weather source without extra
requests; missing or stale data shows clear skies. Motion is off by default,
stops outside Home, and is disabled in memory-saving mode or with system reduced
motion. Realistic scenes are bundled; time changes their lighting and weather
is drawn over them.

Wallpaper placement, brightness, saturation, and dimming depend on the source
and memory-saving mode. Reddit is currently disabled and cannot be selected.

## Continue Watching

Path: **Home screen → Categories and order → Continue Watching**.

This category shows programs apps have submitted to Android Watch Next. A card
resumes playback through the action supplied by its app. Choose participating
apps, card size, a total limit, and per-app limits. View details or hide individual
recommendations. Change the category's visibility and position in the category editor.

The launcher does not read viewing history directly from every video service.
Card availability, freshness, and resuming at the right position depend on the
source app and Android's Watch Next data.

## Top panel and widgets


Path: **Top panel → Objects / Object order**.

Enable, hide, and rearrange the clock, date, weather, network status, traffic,
TV inputs, notifications, sleep timer, night mode, and launcher/Android settings
buttons. Time and date have display and style settings; selecting the date opens
a calendar. Network status shows the available connection type. Traffic shows
usage for a day, week, or month. The counter reads Android history from the start
of the selected day, week or month,
including usage before the widget was enabled. Android may update history with a delay.
If data for the selected period is unavailable, the counter shows “—”. When firmware
does not expose Ethernet usage through the normal Android API, the launcher reads
system history using an already configured local ADB connection. Set up and verify
that connection under Launcher and TV control → ADB connection. History refreshes
at most once every five minutes; Android's hourly history buckets may appear later.
If history cannot be read through either method, the counter shows “—”.
Calendar, night mode, sleep timer, inputs, notifications and network menus inherit
settings appearance and open below their buttons. Back or clicking outside closes
the menu. The calendar gear opens the shared Clock, date and weather settings.

Selecting the network icon opens a compact menu below the button, using settings
appearance. The gear at the top right opens Android network settings; Back or
clicking outside closes the menu. It shows internet availability, connection
 type, Wi-Fi name, signal, link speed, frequency, IP addresses and current device
receive/send traffic. Wi-Fi link speed is the connection rate to the access point,
not an internet speed test. Data unavailable from Android is marked explicitly;
no additional location permission is requested. The summary refreshes every three
seconds only while open and the app is active. It includes a system network
settings button; the separate VPN icon opens VPN settings.

In **Top panel → Objects**, the clock, date and weather share one section with
three independent switches and a **Block settings** button. Block settings contain
the grouping and calendar switches. The calendar is available in either mode:
select the date or the combined block while the date is visible to open it.

Without grouping, there are separate clock, date and weather settings. Grouping
replaces these with **Block appearance** and **Weather settings**, plus a separate
clock animation switch. Time and date formats are edited in block appearance.
Block size (10–24), font, font style, weight, color and glow affect the entire
block; color and glow also affect the weather icon. Place the clock to the left
or right of the text and set their spacing (0–32). These two controls appear when
the clock and at least one text item are enabled. The background can inherit the
panel's background or have its own color, transparency and corner radius.

**Font style** sits below the font selector in clock and block appearance. It
offers only **Standard** and **Italic**. It changes only the slant, preserving
family, size, weight, color, glow and background. **Font weight** is an inline
arrow control offering only distinct weights for the selected font: Manrope
200–800, monospace 100–700, Google Sans 400/500/700, other bundled families
100–900, and system 400/700. Ranges use steps of 100. Out-of-range values
display as the nearest supported weight. Separate clock and combined block
appearance remain independent. Toggling digit animation preserves clock geometry.

**Top panel → Appearance → Wrap panel navigation** is off by default. When enabled,
pressing an arrow at an outermost available button moves focus to the opposite
edge. Holding an arrow keeps moving across both sides without stopping at the
boundary. Navigation follows physical button positions, skipping hidden or
unavailable objects. This setting is shared by home and floating panels.

In **Object order** for either panel, the combined block occupies one row and
moves as a unit, including hidden items. Its initial position is the first
information slot in the stored order. Disabling grouping restores individual
positions until you edit the order. After moving the group, its members occupy
adjacent slots at the new position. Hidden items stay hidden, missing weather
data leaves no empty gap, and panel height stays unchanged. Grouping and block
appearance are shared by both panels; visibility and calendar switches remain
independent for each panel.

Widgets open their own menus and settings. Availability depends on Android data:
traffic needs usage access, and inputs need support for the relevant TV API.

## Weather

Path: **Top panel → Objects → Block settings → Weather settings**.

Sources include Breezy Weather, Open-Meteo, MET Norway, OpenWeather, and Yandex. Choose a city
or coordinates, detect location with the required permission, refresh data, and
configure temperature, forecasts, and weather warnings.

Breezy Weather requires a compatible installed app with a configured provider.
MET Norway needs no key: data by MET Norway under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/), adapted from https://api.met.no/. Forecast days use the TV time zone; min/max cover available periods and precipitation probability is unavailable. OpenWeather and Yandex require their respective personal keys. Cached data helps during temporary
outages, but does not make an old forecast current.

## Notifications and playback

Path: **Top panel → Objects → Notifications**.

After granting notification access, view the notification list, inspect and
dismiss supported notifications, and enable a counter and popups. Customize
appearance, block selected apps, and control which notification types appear.

The separate Now Playing switch shows the active player's title, artist, and
supported play/pause/next controls. It uses the same notification access. The
card appears only when a media session is available; the player determines its actions.

## TV inputs

Path: **Top panel → Objects → Inputs**.

The launcher lists available system inputs and switches to the selected input.
Each input button has a connection indicator: a green dot means connected,
a yellow pause icon means connected in standby, an empty circle means disconnected,
and a question mark means the TV does not report its state. Indicators update when
connections change. They show source connectivity, not the input selected for viewing.
HDMI ports follow their physical numbering, with custom Android labels and
CEC-device information taken into account. Enable CEC names or assign your own
name and icon. Port numbers determine order.

Input availability, labels, and switching depend on firmware. A TV box's HDMI
connection is not equivalent to the television's own input list.

## Night mode and brightness

Path: **Night mode and brightness**; the night-mode widget provides quick controls.

The night filter controls dimming, warmth, and color strength. Enable it manually,
at scheduled times, or from sunset to sunrise for a chosen location, with offsets
and smooth transitions. Skip the current night, enable until morning, or resume
the schedule.

With overlay access, the filter can cover other apps; otherwise only the local
launcher filter is available. Exceptions cover apps, HDMI inputs, and supported
picture modes. Detecting the active app requires usage access. Picture-mode
detection depends on the manufacturer.

A separate brightness scheduler controls supported system backlights, with time
intervals or night boundaries, target levels, and smooth transitions. Disabling
it restores the saved level. Backlight control and the color filter are different
features; backlight writes depend on firmware and system-settings permission.

Automatic sound-profile and picture-mode changes on the night schedule are
planned and are not currently available features.

## Clock and screensaver

Path: **Appearance → Screensaver clock style / Screensaver settings**, when Android
provides a working system selector.

There is a home-screen clock mode and a dedicated clock screensaver. Show clock
and Show screensaver can be assigned to Back in **Home screen → Options**.
Clock appearance is configurable. Select the screensaver through Android;
Android controls that menu's availability and automatic startup conditions.
Top-panel clock settings are separate.

## Sleep timer

Path: the top panel's **Sleep timer** widget.

Set, replace, or cancel a standby deadline. The menu shows remaining time and
the result. Android stores the deadline; exact firing needs exact-alarm access,
and standby requires a supported system action or configured ADB. Behavior
depends on the TV. The app does not disconnect electrical power.

## Launcher and TV controls

After three crashes within five minutes, CuteLauncher opens a recovery screen without loading the main interface. Settings are preserved. Use the remote to retry, open another TV app or Android settings, and choose a home screen. If local ADB was configured, the restore button returns the previous HOME after confirmation. Without ADB, enable a disabled stock launcher in Android app settings first.

Path: **Launcher and TV controls**.

- Configure local TCP/RSA ADB: port, connection check, and authorization on the TV.
- Inspect the current home app, open system launcher selection, assign CuteLauncher
  through supported ADB actions, or restore the previous HOME handler.
- Manage built-in Google TV / Android TV launchers and Home Button Fix separately.
- Enable the launcher's accessibility service and configure Home interception.
- Grant supported special access to the launcher through ADB.
- Launch an app or switch once to HDMI after TV boot or wake, with event and delay settings.

Autostart acts when Android hands control to the launcher; choosing a target does
not launch it immediately. Firmware determines whether HOME can be changed.
Consequences and confirmation appear before changes. Disabling setupwraith also
checks ownership of saved Wi-Fi networks: network-loss risk or an inconclusive
check blocks the action. Restoring the original state requires working ADB and
saved recovery data.

## Remote remapper and floating panel

Path: **Launcher and TV controls → Remote button remapper**.

Button diagnostics records events Android sends to the service and saves the
latest text report. Assign a short press or hold to an app, Home, Back, a webhook,
or the floating top panel. There are global and per-mapping switches and reset.

The floating panel has its own object selection and order. It appears over the
current app and closes with Back. Accessibility and the relevant special access
are required to operate over apps. Not every physical button reaches the service:
Power is excluded; voice and some branded buttons may be handled by Android.
Double press is not supported.

## TV cleanup manager

Path: **Launcher and TV controls → TV cleanup manager**.

The manager reads all installed packages, including system packages, and shows
their states, versions, known descriptions, and disable risks. Unknown packages
are labeled App not recognized. Descriptions and risks are visible immediately,
with an enable/disable action in the package card.

Save original states, undo manager changes, import a local TXT/JSON package list,
or choose an exact model/firmware profile or an external CleanYourTV example.
Selected and skipped packages are shown before changes. Important system
components are protected. Original states are saved before mutating commands;
the journal supports retrying partial recovery. Apps and app data are not deleted.

Copy or save the original snapshot, app report, and disabled-package list. Reports
are not sent automatically. The built-in catalog works without GitHub access;
you can also import a suitable local list.

A package appearing in an external list does not guarantee that disabling it
is safe on your firmware. Choose lists for your model and save the original states.

## Backups and synchronization

Path: **Advanced → Backup and restore**.

Export settings to a file and import them again; create, restore, delete, and
refresh backups. A private rollback point is created before restoration. Backups
contain supported launcher settings, categories, and custom appearance; they
do not back up installed apps or the entire TV system.

Automatic backups support schedules, frequency, and retention. Storage includes
the internal folder, Downloads / CuteLauncher, a selected folder, WebDAV, and
Google Drive with configured access. Internal storage is removed when app data
is deleted. External-folder selection depends on the file manager.

Synchronize selected settings groups between TVs while leaving other groups local.
Multiple TVs need a shared accessible folder or cloud storage; their internal
folders are not shared storage.

ADB keys, Android permissions, and private service data are not transferred as
ordinary settings. A settings backup does not grant permissions or transfer ADB
authorization to another TV.

## Updates and app information

Path: **Advanced → Updates / About CuteLauncher**.

Check for updates manually or automatically, receive update notifications, opt
into test releases, and download APKs for the Android installer. Updates check
package and certificate compatibility and need Android installation permission.
Normal updates preserve user settings. Store-distributed versions have their
own update-channel restrictions.

About CuteLauncher shows the version, attribution, and licenses.
The interface displays versions without a build number; Android keeps an internal
build counter for installing updates.

## Memory and resource saving

Path: **Advanced → Memory and resource saving**.

Inspect memory and cache information, free supported caches, and choose a
resource-saving mode. Clearing caches does not reset settings or disable system
apps. Cache sizes are not independent RAM measurements for each feature.

<a id="диагностика"></a>
## Diagnostics

Path: **Advanced → Diagnostics**.

**TV compatibility check:** run, inspect results, copy or save an export, and
open More details. It collects the device profile and available APIs/permissions
without changing settings or asking for manual participation in individual tests.
It does not automatically verify the physical remote, HDMI, sleep, or complete
service behavior.

**Error diagnostics:** create, clear, copy, or save a report, and open More details.
This is bounded diagnostics of launcher operations, available system information,
and memory, rather than the complete Android log.

Collection is explicit. The two sections' results are independent and remain in
memory until leaving diagnostics. Clearing errors does not remove compatibility
results or previously exported files. Saving needs a working system file picker
or compatible file manager.

### Reporting an issue

1. Reproduce the actions that cause the problem.
2. Open **Settings → Advanced → Diagnostics → Error diagnostics**.
3. Select **Create report** and wait until it is ready.
4. Select **Export report → Save to disk**, choose a folder in the file manager,
   and finish saving.
5. Attach `cutelauncher_errors_….json` to your forum post or
   [GitHub issue](https://github.com/KirillShchetinnikov/CuteLauncher-Releases/issues).
   Include the device model, Android and firmware versions, CuteLauncher version,
   input method, steps to reproduce, and expected and actual results.

For a device compatibility issue, also open **Diagnostics → TV compatibility check**,
create a report, and save it the same way. Attach `cutelauncher_compatibility_….json`.

The app collects diagnostics; the saved JSON file lets you share the results
with the developer. Reports are never sent automatically. Review the file before
posting: it may contain device and app information.

## Device data and reports

Diagnostics collects model/firmware details and available APIs/permissions.
The cleanup manager collects installed-package information and states. Collection
and export are user-initiated; reports are never sent automatically.

The latest button report is stored as `remote-buttons-last.txt` in the app's own
external folder. The cleanup manager's original-state and recovery journal is
stored internally, separately per firmware. Do not clear launcher data while you
still need that recovery journal.

Choose the save location during export. Temporary export cache does not replace
a saved file. Review a report before sharing it: it may contain device and
installed-app information. Reading packages does not verify every TV feature,
and a disabled-app list is not a recommendation for a different TV.

<a id="разрешения-и-ограничения"></a>
## Permissions and limitations

| Access or condition | Features that need it |
|---|---|
| Default home-app assignment | Home returns to CuteLauncher and normal launcher startup |
| Accessibility | Home interception and supported remote-button mappings |
| Display over other apps | Night filter and relevant overlays |
| Notification access | Notification list, popups, and media sessions |
| Usage access | Traffic and active-app detection for night-mode exceptions |
| Modify system settings | Supported brightness controls |
| Location | Automatic weather coordinates and solar scheduling |
| Exact alarms | System sleep-timer deadline event |
| Install unknown apps | APK updates through Android's installer |
| Authorized local ADB | Cleanup manager and relevant TV-control operations |
| Compatible file manager | File/folder selection and saving reports/backups when system pickers do not work |

Permissions are granted by the user and may be revoked by Android. A visible
setting does not guarantee firmware support. When asking about your device,
include its exact model, Android version, and firmware build.
