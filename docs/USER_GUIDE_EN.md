# CuteLauncher: feature guide

[Русский](USER_GUIDE_RU.md) · [English](USER_GUIDE_EN.md) · [All documentation](README_EN.md)

CuteLauncher is a remote-controlled home screen for Android TV / Google TV.
The declared platform is Android 11 and later, with ARMv7, ARM64, and x86_64
builds. Running on Android 11 has not yet been confirmed. System features
depend on permissions, available menus, and manufacturer firmware.

This guide describes the current source code. New features appear on a TV
after the corresponding APK is installed. Implemented, device-verified, and
planned features are distinct; limitations appear beside each feature.

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
Restore an overridden setting to its shared value. CuteLauncher and system
settings tiles can be hidden.

## Apps

Path: **Apps**, or the selected tile's actions.

Lists include All apps, System apps, and Hidden apps. App details show its name,
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
- Adaptive landscape: an illustrated valley or realistic nature with four seasons.

After selecting this source, open **Home screen → Background → Source parameters**.
Time of day, seasons, clouds, rain/snow, fog and weather animation have independent
switches. Disabling time of day keeps daylight; disabling seasons keeps summer.
Sun times come from the Night mode cache; without them, sunrise is at 06:00 and
sunset at 18:00, with twilight extending 40 minutes before and after each.
Landscape states crossfade. Seasons follow the month and hemisphere: automatic
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
usage for a day, week, or month.

**Top panel → Objects → Combine time, date and weather** groups enabled items
into one block: a large clock beside two lines for date and weather. Hidden items
stay hidden. The block occupies the first enabled information item's existing
position; other buttons retain their order. Date/time formats and calendar
access remain. Disabling grouping restores individual items in their previous
order. Panel height stays unchanged.

Widgets open their own menus and settings. Availability depends on Android data:
traffic needs usage access, and inputs need support for the relevant TV API.

## Weather

Path: **Top panel → Objects → Weather settings**.

Sources include Breezy Weather, Open-Meteo, OpenWeather, and Yandex. Choose a city
or coordinates, detect location with the required permission, refresh data, and
configure temperature, forecasts, and weather warnings.

Breezy Weather requires a compatible installed app with a configured provider.
OpenWeather and Yandex require their respective personal keys; a full run using
valid personal keys is not yet confirmed. Cached data helps during temporary
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
Double press is not implemented. TV execution and the panel's full set of actions
are not yet verified across all target scenarios.

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

Current profiles contain observed disable states, while the verified list with
no loss of features is empty. A package appearing in an external list does not
establish safety on your firmware. The manager has local test coverage; APK
integration testing on physical TV/emulators remains outstanding.

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
authorization to another TV. Full workflows with real Google Drive accounts,
external folders, and cloud synchronization are not verified in every scenario.

## Updates and app information

Path: **Advanced → Updates / About CuteLauncher**.

Check for updates manually or automatically, receive update notifications, opt
into test releases, and download APKs for the Android installer. Updates check
package and certificate compatibility and need Android installation permission.
Normal updates preserve user settings. Store-distributed versions have their
own update-channel restrictions.

About CuteLauncher shows the version, attribution, and licenses.

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
