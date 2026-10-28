# CuteLauncher: feature guide

[Русский](USER_GUIDE_RU.md) · [English](USER_GUIDE_EN.md) · [All documentation](README_EN.md)

CuteLauncher is a remote-controlled home screen for Android TV / Google TV.
Requires Android 9 or later, with ARMv7, ARM64, and x86_64
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
- [Remote remapper and quick settings panel](#remote-remapper-and-quick-settings-panel)
- [Open apps](#open-apps)
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

Click an app tile to launch it with a mouse. The wheel scrolls app rows
horizontally and grids with a limited number of visible rows vertically.
At either end of an app row, the wheel scrolls the home page.

Settings are grouped into Home screen, Top panel, Appearance, Apps, Night mode
and brightness, Launcher and TV controls, and Advanced. Android TV system
settings open separately. Help is collapsed under More details. Choose an
app language in Advanced independently of Android, or follow the system language.
Back returns to the previous settings page. Expanding help should not replace
the selected item's normal action.

## Home screen and categories

At startup, the home screen uses the saved app list and refreshes it in the
background. Installing, removing, or disabling an app updates the list
automatically. When returning from an app or waking the TV, remote control
remains available while weather, posters, and statistics refresh.

Use ↑/↓ to move between nonempty sections, including Continue Watching,
skipping empty sections and spacers. Moving above the first nonempty section
reaches the top panel.

Path: **Home screen → Categories and order**.

Create, rename, and delete categories; add apps; reorder apps and categories;
hide categories and restore them. Standard categories (All Apps, TV Apps,
Non-TV Apps, Favorites, and Continue Watching) cannot be deleted;
they can be hidden and moved. The four standard app categories can be renamed:
their names do not change their purpose or membership. Continue Watching keeps
its name. Favorites app membership is edited manually.
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
category, and change its tile. Set a custom tile banner or restore the default. With ADB connected, Stop appears when an app process is detected and force-stops the app. CuteLauncher itself cannot be stopped from this menu.

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
for the interface, top panel and clock: Medeo Sans, Medeo Mono, Google Sans, Onest, Manrope, Outfit or
the system font; the panel and clock also retain their earlier families.
Only fonts supporting the current interface language are listed. For example,
Outfit is unavailable for Russian. New styles default to Outfit for compatible
languages and Manrope for Cyrillic. Switching languages temporarily substitutes
Manrope or the system font if the saved font is incompatible; switching back
restores the previous choice. All fonts are bundled and work offline.

Background sources:

- A gradient with your chosen colors.
- A local image or video, plus a separate Day/Night image source.
- A folder slideshow with subfolders, order, interval, and next-image controls.
- Bing online wallpapers or an image URL with available update options.
- Selected app colors: a soft background derived from the focused tile's banner or icon.
- Adaptive landscape: an illustrated valley or realistic nature with four seasons. Spring has fresh light greenery and a flowering meadow, plus blossoming trees in the illustrated valley; summer has deep greenery and warm golden grasses.

For a local file, choose **Local image or video → Source settings → Choose file**.
The collapsed help lists formats and limits: JPEG, PNG, WebP, GIF, BMP — up to
8 MiB, 48 megapixels and 16,384 pixels per side; MP4/M4V, WebM, MKV — up to
256 MiB and 3840×2160. The TV must support the codec; MP4 with H.264 is preferred.
Video loops silently, pauses outside Home and does not prevent system sleep.
The video file is excluded from backups; choose it again after moving devices.
Cancellation or an error preserves the previous background. Messages distinguish
unsupported formats, size/resolution limits, codec errors and inaccessible files;
a successful selection is confirmed separately.

If video initialization or playback fails, the launcher automatically tries a compatible output mode when available on the TV. It retries once; if that also fails, an error message appears. This does not add support for a missing codec.

The **Day/Night image** source accepts images only: the day image is used from
06:00 to 18:00, and the night image at other times.

After selecting this source, open **Home screen → Background → Source settings**.
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
usage for a day, week, or month.
Select the traffic counter to see usage for **the day, week and month** together.
Each period has a compact card showing **Received**, **Sent** and **Total**.
Received and sent usage appear side by side, or vertically with large text.
Use the remote to scroll when needed.
The gear and **Top panel → Objects → Traffic settings** open usage access and
the period for the counter on the panel. The open menu always shows all three periods. The counter reads Android history from the start
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
Saturday and Sunday dates are shown in red, including today.

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
200–800, Roboto Mono 100–700, Google Sans 400/500/700, other bundled families
100–900, and system 400/700. Ranges use steps of 100. Out-of-range values
display as the nearest supported weight. Separate clock and combined block
appearance remain independent. Toggling digit animation preserves clock geometry.

**Top panel → Appearance → Wrap panel navigation** is off by default. When enabled,
pressing an arrow at an outermost available button moves focus to the opposite
edge. Holding an arrow keeps moving across both sides without stopping at the
boundary. Navigation follows physical button positions, skipping hidden or
unavailable objects. This setting is shared by home and quick settings panels.

In **Object order** for either panel, the combined block occupies one row and
moves as a unit, including hidden items. Its initial position is the first
information slot in the stored order. Disabling grouping restores individual
positions until you edit the order. After moving the group, its members occupy
adjacent slots at the new position. Hidden items stay hidden, missing weather
data leaves no empty gap, and panel height stays unchanged. Widget settings,
grouping, block appearance and the calendar switch are shared by both panels
and edited in the main top panel settings. The quick settings panel’s **Objects** page
contains only visibility switches, so its set of visible objects is independent.

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

Details open beside the list without overlapping panels. The open button runs
the notification's own action; if no action exists, it launches the app when
launching is supported. System messages without an action or a launchable app
have no open button. An unavailable action displays a message.
The dimming cutout follows the widget button's current size, including its counter.

In **Appearance → Notification style → Notification position**, choose any of
the four screen corners. Launcher messages and app notifications share one stack
and slide in from the nearest side of the screen, sliding back off-screen when
they close. The stack grows downwards in
the top corners and upwards in the bottom corners. When a settings panel or
widget menu occupies the selected side, the stack temporarily moves to the other
side and returns after the panel closes. Over other apps, notifications always
use the selected corner.

The separate Now Playing switch shows the active player's title, artist, and
supported play/pause/next controls. It uses the same notification access. The
card appears only when a media session is available; the player determines its actions.

## TV inputs

Path: **Top panel → Objects → Inputs**.

The launcher lists available system inputs and switches to the selected input.
The menu opens immediately with the last known list and refreshes it in the background.
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
the schedule. The temporary mode ends automatically at the next applicable
schedule boundary: manual activation ends when the night starts, and skipping
the current night ends when it finishes. The “Resume schedule” button then
disappears. Turning the night filter off with the main switch prevents the
schedule from enabling it.

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
Settings are available through the widget gear and
**Top panel → Objects → Sleep timer settings**.
The menu opens immediately with the timer's last known state and refreshes it
in the background.

In **Settings**, choose time remaining, shutdown time or both, whether to show
seconds, and whether to close the widget after selecting a timer. By default,
it shows time remaining with seconds and closes after a successful selection.

**Timers** contains **Visible** and **Hidden** intervals. Press Left/Right or
hold OK to start moving; Up/Down changes the order and moves a timer across the
boundary between the lists. OK finishes moving. Select an interval to edit its
hours, minutes and seconds. Add custom intervals or delete any, including defaults.
**Reset timers** restores the default set and order. Editing the list and resetting
it do not change a countdown already running.

Set, replace, or cancel a standby deadline. The menu shows remaining time and
the result. Android stores the deadline; exact firing needs exact-alarm access,
and standby requires a supported system action or configured ADB. Behavior
depends on the TV. The app does not disconnect electrical power.

## Launcher and TV controls

After three crashes within five minutes, CuteLauncher opens a recovery screen without loading the main interface. On Android 9–10, this counts failures reported by Flutter itself; system crash history is available from Android 11. Settings are preserved. Use the remote to retry, open another TV app or Android settings, and choose a home screen. If local ADB was configured, the restore button returns the previous HOME after confirmation. Without ADB, enable a disabled stock launcher in Android app settings first.

Path: **Launcher and TV controls**.

- **Power management**: put the TV in standby or restart it, with confirmation
  before sending the command. Standby requires the CuteLauncher accessibility
  service or local ADB; restart requires ADB. On a TV box, the command controls
  the box itself; TV behavior depends on HDMI-CEC and firmware. This does not
  disconnect electrical power.
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
check blocks the action by default. If ownership by the setup wizard is confirmed, CuteLauncher
opens a separate dialog: check that you know the password, forget the network and
reconnect through regular Android network settings, then check ADB and retry.
If the message returns, keeping the built-in launcher enabled is safer.
“Disable anyway…” lets you proceed after a separate warning and the red
“Disable” button; “Cancel” is selected by default. Android may delete saved
networks, making Wi-Fi and wireless ADB unavailable. Re-enabling the wizard
will not automatically restore networks: reconnect and enter the password.
Confirmation applies to one operation only. An inconclusive ownership check
cannot be overridden and does not require forgetting the network.
Restoring the original state requires working ADB and saved recovery data.

## Remote remapper and quick settings panel

Path: **Launcher and TV controls → Remote button remapper**.

Button diagnostics records events Android sends to the service and saves the
latest text report. Assign a short press or hold to an app, Home, Back, a webhook,
the quick settings panel, or open apps. There are global and per-mapping switches and reset.
An empty name field shows “Button name”. Below it, select “Assign button”,
then “Capture” in the separate dialog and press the remote button. The dialog
shows the captured button; capture another or select OK to accept. Cancel and
Back keep the previous selection. Then save the assignment in the editor.
There is no list of preset buttons.
For a webhook, enter the URL or import a UTF-8 text file up to 64 KB containing
only the request URL, without commands or explanations. Line breaks are removed.
HTTPS or local HTTP is required. Import errors and cancellation preserve the
previous URL; the editor masks the address.
Save errors explain what to fix: assign a button, select an app, enter a valid
URL, or retry saving.
Deleting an assignment requires confirmation. Cancel and Back keep the assignment.
Home supports a hold assignment only; a short press returns to CuteLauncher.
The list of apps to open shows their icons beside their names; an Android icon
is used when an app icon is unavailable.
Assignments also work over other apps when the firmware delivers the button to the service.

The quick settings panel has its own object selection and order. It appears over the
current app and closes with Back. Accessibility and the relevant special access
are required to operate over apps. Not every physical button reaches the service:
Power is excluded; voice and some branded buttons may be handled by Android.
Double press is not supported.

## Open apps

Path: **Launcher and TV controls → Open apps**. Assign the “Open apps panel” action
in the remapper, just like the quick settings panel. This settings page also opens
the panel directly and selects its type: Automatic, CuteLauncher panel, or
Built-in panel. Automatic mode uses the available manufacturer's `com.nes.recents`
panel (for example, on KP1), otherwise CuteLauncher's own panel. The built-in
option depends on the firmware.

The CuteLauncher panel requires authorized local ADB and a connected accessibility
service. It shows icons and names of TV apps with existing tasks, including
windows in the background. Apps without a TV launch entry, background services
without tasks, and launchers are excluded. OK or clicking an app brings its task
to the foreground; the close button beside it removes all its tasks but does not
guarantee that its background services stop. Close all force-stops user apps
in the list, including playback and background work. System apps and launchers
are preserved. Back or the header close button dismisses the panel. Refresh
reloads the list. Actual window images are not used. After an operation, focus
returns to the previous available button; if it disappears or becomes disabled,
focus moves to Refresh. The panel type is stored
only on this device.

## TV cleanup manager

Path: **Launcher and TV controls → TV cleanup manager**.

The main page contains the refresh action and four groups: All applications,
Disable lists, Backup and recovery, and Reports. Before first use, select Refresh applications:
the groups remain unavailable until the list is read successfully. The last list
and its states persist between visits and launcher restarts. Opening all
applications automatically refreshes the list with a notification; the page opens
only after a successful refresh. Current data is also read before applying changes,
recovery, and export. A failed refresh stops the action and preserves the last
successful list.

Applications are grouped into user, preinstalled, and system applications.
User-installed apps and known ordinary preinstalled apps (such as Prime Video)
show minimal risk and a note that they are not system applications, without
individual descriptions or disabling consequences. Android and manufacturer
system components show their descriptions and risks; unknown system packages
are labeled Application not identified. Each application card shows its version,
state, and an enable or disable action. Protection of important components and
active services applies in every group.

The first successful refresh automatically creates the **baseline original state**
for the current firmware. Backup and recovery shows its creation date and a restore
button. The launcher cannot delete or overwrite the baseline. Updating from an older
version preserves the previous original state. More details at the bottom explains
the copies.

Opening Backup and recovery or the manual states list does not refresh applications.
The current state is read when saving a copy.

Manage manual states saves the current state with a custom name or the date and
time as its name. Previous saves appear below the button. Selecting one opens
restore, delete, and file export through the file manager. Deletion and restoration
require confirmation. Copies contain enabled/disabled application modes, not APKs
or app data; recovery needs local ADB. Apps installed after the copy remain unchanged.
Missing apps and attempts to disable protected components are skipped.

When repeated-crash protection activates, the launcher automatically attempts to
restore baseline app states without starting Flutter. The recovery screen shows
the result and provides a retry button if ADB is unavailable. System settings and
other apps remain accessible. Clearing launcher data or uninstalling it removes
its internal copies; root access cannot be prevented. A separate baseline applies
after a firmware change.

In Disable lists, the verified-applications button uses saved lists of system
applications observed as disabled. It does not change user-installed or ordinary
preinstalled apps; missing and protected packages are skipped. The Preinstalled
applications group can disable or enable all such apps, or open their list with
current states and individual actions.
Entering the group does not refresh the list; it refreshes when you open the
application list or prepare to change application states.

Before confirmed list-based disabling, a separate snapshot of only the selected
applications is saved automatically. It appears in manual states with a
Before applying list label and the source name. Restoring it leaves other apps
unchanged. If saving fails, disabling does not start. The limit is 100 manual
and automatic snapshots; remove unnecessary saves in manual state management.

TXT/JSON import remains available. In the project catalog and CleanYourTV, refresh
from GitHub using the top button first: list entries stay unavailable until a
successful update. Project catalog lists matching the current device and firmware
show a green check mark on their button. Catalogs and application lists support name search. A different
model or firmware is rejected. If everything is already disabled, the manager
says so explicitly; missing applications have a separate message.
The manager does not delete applications or app data.

In Reports, the export button saves device information and disabled applications
to a file. You can submit this report to the project Git manually for inclusion.
Nothing is uploaded automatically. The bundled catalog works without GitHub;
you can also import a suitable local list.

A package appearing in a disable list does not guarantee that disabling it
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
is deleted. External-folder selection depends on the file manager. On Android 9,
saving to Downloads requires storage permission; internal storage and the system
document picker do not require it.

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

On the first launch after an update, the launcher checks previously saved access:
accessibility for button remapping, notification access, display over other apps,
usage statistics, system settings changes, and Continue Watching.
When the previously configured ADB connection is available, missing access is
restored automatically; access disabled before the update is not granted.
This requires a state snapshot saved by the previous version. If ADB is temporarily
unavailable, the recovery queue is retained for up to five attempts within 15 minutes.
If recovery fails, enable the required access again in Android settings.

The launcher also checks its accessibility service connection in the background,
roughly every 15 minutes. Android may postpone checks, particularly during sleep.
If access remains enabled but the service disconnects, the launcher tries to reconnect
it through the previously configured ADB connection. System access disabled outside
an update is not granted automatically. Force-stopping the app in Android suspends
background checks until its next launch. On the tested TCL TV, force-stop also
disables accessibility access; enable it again in Android settings after stopping
the app this way. Waiting and failure reasons are included in the diagnostics report.

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

Path: **Settings → Advanced → Diagnostics**. One report combines shared TV and
CuteLauncher metadata, feature compatibility and errors. There is no separate
compatibility submenu or file. Create a report, view check results, clear it,
and export it by copying or saving to disk.

The report includes model/firmware, app version, permissions, memory, error stages
and causes, and redacted arguments, responses and exception text. ADB entries
also contain the command, stdout/stderr and exit code. Each recorded error links
to a snapshot of the settings applied at that moment; later changes before export
do not replace earlier values. Settings at export are listed separately.
Snapshots exclude passwords, keys, accounts, coordinates, addresses, paths,
app lists and personal content.

Creating a report also adds installed apps with package identifiers, names,
versions, system flags and enabled states, plus section names, contents, order,
visibility and sorting. Empty and hidden sections, spacers and the Continue
Watching position are included. Package identifiers remain readable for diagnosis.
These lists are excluded from published anonymized compatibility data; send the
full report only in a private message. Unavailable or truncated data is marked.

The absence of the proprietary TCL filter on an unsupported device is recorded
as an unavailable capability and is not treated as a diagnostic failure.

For video background errors, file validation and playback are recorded separately:
the original player message, stage, timeout, file size, known video dimensions
and duration, position and playback state. Available ExoPlayer/MediaCodec error
logs are also collected from the launcher process only, without ADB or additional
permissions. If the firmware blocks log access, the report says so. Paths and
personal data are redacted; technical decoder names are retained. Reproduce the
error in the current session, then create a new report before restarting the app.

The last 50 operations, up to 100 failures separately, and a bounded ADB log stay
in memory for the current session until cleared or restarted. Collection is
explicit; viewing and export reuse the same snapshot, while collecting again
replaces it. A failed repeat preserves the previous report. Clearing removes the
current report and logs, but not previously saved files. Nothing is sent automatically.

Compatibility checks inspect metadata and API availability without changing settings.
They do not verify the physical remote, HDMI, sleep or full feature operation.
If collection fails, the unified file retains errors and marks compatibility
results as unknown.

### Reporting an issue

1. Reproduce the actions that cause the problem.
2. Open **Settings → Advanced → Diagnostics**.
3. Select **Create report** and wait until it is ready.
4. Select **Export report → Save to disk**, choose a folder in the file manager,
   and finish saving.
5. Send `cutelauncher_diagnostics_….json` to the author **in a private message**.
   Do not attach it to a public forum topic or GitHub issue: automatic redaction
   may miss personal data. Describe the controls, steps and expected/actual results.
   TV and app version metadata are already included when Android provides them.

**By sending the report to the author, you agree to publication of an anonymized
TV compatibility report in the CuteLauncher Git repository.** Only device metadata
and feature availability are published, without personal data. Error logs,
commands, exceptions and your settings are not published. Publication is not automatic.

Before publication, only the allowed compatibility portion is extracted: model,
manufacturer, firmware, Android/ABI and observed feature states. Serial numbers,
the full fingerprint, exact sending time and user-granted permission state are
excluded. API observations are not presented as full functional verification.

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
