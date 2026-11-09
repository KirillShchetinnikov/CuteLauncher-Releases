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
- [App feeds](#app-feeds)
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
- [Compatible graphics output](#compatible-graphics-output)
- [Diagnostics](#diagnostics)
- [Device data and reports](#device-data-and-reports)
- [Permissions and limitations](#permissions-and-limitations)

## Controls and settings

Use the directional pad to move focus and OK to activate the selected item.
Hold an app tile to open its actions. Back returns from a nested screen;
its home-screen behavior is configurable. Home returns to the launcher when
the default home app or Home interception is configured correctly.
Under **Home screen → Home screen behavior → Back button action**, choose
**First card in current feed** to return focus and scrolling to the start of the
app feed or Continue Watching row that contains the selected card. On the home
screen outside those feeds, the action leaves focus where it is.
You can choose the focus target after Home. Key sounds have separate switches: for Home,
go to **Home screen → Home screen behavior**; for settings, go to
**Interface style → Settings style**. Both switches are off by default.
On return, the launcher also checks for changes to installed apps so it can
update tiles even if a system change notification was missed.

Click an app tile to launch it with a mouse. The wheel scrolls app rows
horizontally and grids with a limited number of visible rows vertically.
At either end of an app row, the wheel scrolls the home page.

When settings move, appear, or disappear on a page, the directional pad follows
their new order.

Settings are grouped into Home screen, Top panel, Interface style, Apps, Night mode
and brightness, Launcher and TV controls, and Advanced. Android TV system
settings open separately. Help is collapsed under a topic title with an information
icon. Current errors and unavailable-state reasons remain visible. Choose an
app language in Advanced independently of Android, or follow the system language.
Back returns to the previous settings page. Expanding help should not replace
the selected item's normal action.
When moving down with the remote, settings start scrolling as the selected
item passes slightly below the middle of the window. Moving up uses a point
slightly above the middle. At either end of the list, focus can reach the edge.
Under **Interface style → Settings style → Scrollbar**, choose **Hide completely**,
**Show while scrolling**, or **Always show** (the default). This applies to
settings, menus, and dialogs. Scrolling works in all three modes. If you previously
turned off persistent scrollbars, they still appear only while scrolling after the update.

Under **Interface style → Settings style → Group appearance**, choose
**Accent strip** or **Shared surface** (the default). One choice applies to groups
across settings pages. Long pages for appearance, weather, night mode,
brightness, notifications, KVN, startup, Continue watching, the file browser,
button mappings, and backups are divided by purpose. Short menus and app
lists keep their simple layout. In the section list, panel object ordering, and
the TV cleaner app list, headings have a divider that starts after the text.
Visible and hidden sleep timer presets use the same separation.
Remote instructions stay pinned to the bottom of the settings panel while
the list scrolls. Compact guides take at most three lines and highlight button names.
Sizes, counts, and dates have labels; states and errors appear as separate
messages beside the relevant setting. Empty lists have an icon and a short
message. Detailed explanations remain in collapsed help.
Under **Top panel → Appearance**, groups
separate background, text, and additional options.
The row material and focus color stay the same. Your group appearance choice
is included in appearance backups; resetting the settings style restores
**Shared surface**.

Clean installations start with Standard style, Medeo Sans, an orange accent,
and an adaptive landscape. Settings open on the left in an opaque dark grey panel.
Tile labels are off; section titles and icons are on. Tile spacing is 6, and
focused tiles grow by 20% with a pulsing glow coloured from the image.
The grid shows up to three visible rows of six apps. All Apps and nonempty feeds
are visible. The clock and date work immediately; weather needs a selected city.
The timer shows 10, 30, 60, 90, and 120 minutes. Updating does not apply this
profile over your settings, including earlier defaults you never selected manually.
An explicit appearance reset restores the new starting style.
Appearance, category, and timer resets
affect only their own scope; resetting local appearance restores shared values.

## Home screen and categories

At startup, the home screen uses the saved app list and refreshes it in the
background. Installing, removing, or disabling an app updates the list
automatically. When returning from an app or waking the TV, remote control
remains available while weather, posters, and statistics refresh.

Use ↑/↓ to move between sections, including Continue Watching.
An empty app section has a focusable “This category is empty.” tile.
Moving to it uses the same scroll animation as moving to other sections.
Press OK on it to open section settings. Navigation skips spacers.
Moving above the first available section
reaches the top panel.

Path: **Home screen → Categories and order**.

The button instructions for moving sections stay pinned to the bottom of the panel.
General information about sections opens separately in collapsed help.
Opening settings for a visible category scrolls Home to its cards. Appearance
changes are visible beside the panel as you make them, while the arrow buttons
and OK continue to control settings. Leaving the editor restores the previous
category on Home and returns focus to the item you opened the editor from.

Create, rename, and delete categories; add apps; reorder apps and categories;
deleting a category requires confirmation and keeps installed apps;
hide categories and restore them. Standard categories (All Apps, TV Apps,
Non-TV Apps, Favorites, Continue Watching, and App feeds) cannot be deleted;
they can be hidden and moved. The four standard app categories can be renamed:
their names do not change their purpose or membership. App feeds and Continue Watching
keep their names. Favorites app membership is edited manually.
Automatic app lists are built from installed apps. Enable and move Continue
Watching in the same editor.
Moving a category across the list boundary places it first among hidden categories;
restoring it places it last among visible ones. Other categories keep their order.

Choose rows or grids, sorting, column and visible-row counts, scrolling, active
category pinning, sizes, spacing, headings, backgrounds, and margins. Some
appearance settings are shared, while others can be overridden per category.
Shared settings can be changed even if all categories use their own values.
Settings incompatible with the current mode remain disabled, such as blur
with an opaque tile background. Category overrides take priority and are
preserved when shared settings change.
A link icon marks shared values; changes to shared settings apply immediately,
including to existing categories. Choosing a value that matches the shared one
restores inheritance. In Tiles and labels, one Restore common settings button
restores all settings on that screen. Titles, icons, padding and background are
available directly in the category appearance editor. Find **Align section titles
with tiles** under **Home screen → Appearance → Sections** and in the appearance
settings for an individual section. When enabled, the title starts at the tile
edge and moves with the tiles when you adjust padding. Titles use edge alignment
by default. **Section title size** in the same settings lets you choose a size
from 12 to 40 (default 24), shared across sections or overridden for an individual
section, including App feeds and Continue Watching. When
titles are hidden, the control is disabled and the saved size is kept.
Colored category backgrounds
have Background opacity (0–100%) and Corner radius (0–64) sliders. Adjust them
for all categories in the home appearance settings or for one category, including
App feeds. Opacity affects only the background; icons and text keep their brightness.
Choosing a transparent background preserves the slider values. Reset category layout also
restores its shared appearance and clears padding, keeping apps and their order.
CuteLauncher and system settings tiles can be hidden.

The grid row limit sets the number of complete rows in the category area,
including labels and gaps. If this area is taller than the screen, the page
scrolls to the selected tile together with the heading. Additional rows scroll
inside the area; All places the whole grid on the home page. Tile size and
corner rounding do not reduce the selected row count.

When the home screen shows just one app category in a single row, the mouse
wheel scrolls apps horizontally without moving the category vertically.
Vertical scrolling remains available with multiple categories, multiple rows,
a grid, or additional content cards.

## App feeds

At startup, static card placeholders reserve space for each selected feed and
Continue Watching. Content fills those positions; you can immediately use the
arrow keys to move to another section. Loading does not pull focus back.
Existing cards stay visible during refreshes, and empty feeds disappear after
the source responds.

Path: **Home screen → Categories and order → App feeds**.

Select up to 16 feeds published by installed apps. One app may offer several
feeds, such as new releases and saved items. When you enable or disable an
available feed, its switch stays focused and visible. The ↑/↓ buttons move
through the updated order. Selected nonempty feeds appear
as one standard category. Move the entire group or move it between visible
and hidden categories. On the feed selection page, **Reorder** opens the order
of enabled feeds when at least two are selected. OK or ◄/► starts or finishes
moving, ↑/↓ changes the position, and Back finishes moving; the next Back returns
to the previous page. The order stays on this TV and applies to feeds on the home screen.
Unavailable and empty selected feeds keep their positions in the saved order.
Press OK on the category to open its editor: view its fixed name, choose feeds, or open
Category appearance. Appearance controls include preview size, corner radius,
horizontal spacing, label size and color, feed titles, padding,
and background. In **Appearance source**, choose **Custom appearance** (the
default), **Shared appearance**, or an app section such as All Apps. Shared
appearance uses the common tile size, proportions, and style. A selected app
section supplies its tile style and calculated size, including sizing by
column count. Headings, padding, and backgrounds have their own settings.
Custom appearance restores your saved preview settings. If the selected app
section is deleted, shared appearance is used.
When using shared appearance or another section, **Use labels from the selected
appearance** is on by default. Turn it off to set label visibility, position,
size, and color separately. The selected source still controls tile size and
other styling.
While selected feeds load for the first time, the home screen
shows one empty card and the App feeds heading if headings are enabled.
After loading, individual feed names are used.
Individual feed titles can be enabled here independently
of the shared section-title setting. Previews always use a single horizontal
row with a uniform format within each feed and titles below the artwork; there is no grid.
Below the title, a card can show a movie's year, rating, and first genre, or a
video's duration and channel name. The line depends on what the app publishes
in its feed. A short description can serve as the second line when it is the only
detail available. The line is visible when labels are shown below the artwork.
On the feed selection page, each enabled feed has an **Artwork format** choice:
**Auto**, **Landscape** (16:9), or **Portrait** (2:3). Auto uses app metadata or,
when absent, the first three loaded covers. Ties use landscape. The result is
remembered on this TV; manual selection takes priority. Artwork fills each card
without distortion, with excess edges cropped around the center. Feed formats are excluded from backups and synchronization.
Feeds use compact vertical spacing, with side margins that accommodate enlarged
edge cards when focused.
Restoring common appearance settings keeps the name and feed selection.
Artwork resolution accounts for the enlarged selected card.
The quality of the source image depends on the app publishing the feed.
Each feed shows up to 20 cards in the source order by default. On the feed
selection page, the **Maximum Items** slider sets the same limit from 20 to 50
for each feed. The value is saved on this TV. Your feed selection survives restarts on this TV and is
excluded from backups and synchronization. The whole group’s name, order,
visibility and appearance are included in category and appearance backups. Hiding the group
keeps your feed selection.

Use ←/→ to select content, ↑/↓ to move between sections, and OK to open the
selected item in its app. At the edge of the screen, ←/→ smoothly scrolls the
feed to the selected card. If system animations are disabled, the feed moves
immediately. Back keeps your configured home-screen behavior;
returning to the launcher follows your chosen Home focus mode.
If the main artwork is unavailable, the launcher tries the feed's fallback image.
A card shows a placeholder when no image is available. Empty feeds are hidden
from the chooser and home screen. Feeds from hidden apps are hidden on the home
screen. Saved feeds that disappear can still be deselected while their
app is installed. Uninstalling the app removes its feeds from the list and
the saved selection.
A feed is hidden from the chooser and home screen if its cards have no
available artwork or thumbnails because resources are broken or providers
are missing. When artwork is available again, the feed reappears with its previous setting.

The list refreshes when system channels change, when returning to the launcher,
and with Refresh feeds. The button receives focus when you open feed selection
and keeps it during loading until you move to another control. Existing cards
and artwork remain visible until their replacements are ready. Unchanged data
preserves focus and scroll position.
If a refresh temporarily fails, the last successfully loaded feed remains visible.
TV listings access is required. Without it, the page
shows an access error, a permission request, and a grant through the configured
built-in ADB instead of reporting that no feeds are available.
Available feeds depend on the app, account, and Android TV / Google TV firmware.
If an app does not publish system channels, CuteLauncher cannot retrieve its
recommendations. Artwork with network URLs downloads from the app's source.

## Apps

Path: **Apps**, or the selected tile's actions.

Lists include All apps, System apps, and Hidden apps. Hidden apps also includes
CuteLauncher and Android settings when their tiles are hidden by the dedicated
switches. Show restores the tile and turns off its hide switch. App details show its name,
package, and version. **App sections** shows the section count and expands to list
their names in launcher order, including hidden sections with a hidden icon.
The list updates when membership changes and explicitly states when no sections apply.
Launch an available app, open Android app information,
request uninstall where Android allows it, hide or restore it, add it to a
category, and change its tile. Actions are grouped into home screen, launch,
appearance, and app management blocks. Set a custom tile banner or restore the
default. Opening the panel does not connect to ADB. **Check status** in the
management block runs a manual check through local ADB on the TV; Android may
ask you to authorize debugging. The status is unknown until checked, then shows
the last check result or an access error. **Stop** appears when an app process
is detected; it force-stops the app and displays the verified command result.
CuteLauncher itself cannot be stopped from this menu.

To change a tile label, hold **OK** on the tile and select **App name on Home**.
The saved name applies across all sections, is used for alphabetical sorting,
and is included in backups and sync. Choose **Restore system name** in the
same editor to switch back.

Hiding an app removes it from automatic launcher lists; it does not disable
the app in Android. The normal system-app list belongs to the launcher catalog.
For the complete installed-package list, including background system components,
use the [cleanup manager](#tv-cleanup-manager).

## Appearance and backgrounds

Paths: **Home screen → Home screen · Appearance**, **Interface style**, **Top panel → Appearance**.

Customize tiles and labels, sizes and spacing, shapes and backgrounds, focus
outlines, zoom and animations, accent color, categories, and the top panel.
Menus and notifications have background, transparency, color, and text-scale
settings. Menus can open on either side. Reset individual groups or all appearance.

**Inactive section opacity** applies to app categories, the app feeds group,
and Continue watching. The last selected section stays fully opaque when
you move to the top panel or settings.

In **Tiles and labels**, **Apps with a banner** and **Apps without a banner**
are independent choices next to tile proportions. Apps with a banner have four modes:

1. **Fit whole image** — shows the entire image inside the tile shape.
2. **Fill with cropping** — enlarges with central cropping, preserving proportions.
3. **Fit with edge color** — shows the whole image and fills the free area
   with the color of the nearest image edge.
4. **Icon with edge color** — replaces the banner with the app icon,
   shows the whole icon and fills the free area with its edge colors.

The mode applies when the original image is cropped by the tile shape or leaves
empty margins. An image that already fits stays unchanged, including in the fourth
mode. Circles and rounded corners are taken into account. Apps without banners
have the first three modes, applied to their icons; **Icon with edge color** is
not offered. A replacement icon in the fourth mode follows the setting for apps
with a banner. Icons retain their separate size setting. Each choice supports
a common value and category overrides. The default is **Fill with cropping** for
apps with a banner and **Fit whole image** for apps without a banner.
After an update the default applies when no mode was previously saved;
explicitly selected modes are preserved. If a replacement icon is unavailable, the banner stays with its edge
colors; if no usable color is found, the normal tile background is used.
Margins within the image file itself are not removed.

With labels below tiles, zoom grows upward and sideways while preserving the
gap above the text. This applies to app tiles and content feed cards.
Side margins accommodate enlarged edge cards in rows and grids.
While scrolling vertically or horizontally, the focus pulse pauses at its
current brightness. The outline or glow remains visible; once scrolling stops,
the pulse resumes if enabled.

**Interface style** offers Standard, Glass, Soft,
Outline, and Calm. Calm removes persistent outlines from ordinary rows and marks
the focused row with an accent-coloured outline and tint. Selection marks,
active switches and sliders also use the chosen accent; the existing styles keep
their surfaces and accent-coloured focus. They change panel materials, buttons, focus, switches and sliders
while preserving placement, dimensions and remote control. Custom colours and
transparency remain. Clean installations start with Standard style and Medeo Sans; updates preserve existing appearance. Choose fonts separately
for the interface, top panel and clock: Medeo Sans, Medeo Mono, Medeo Serif, Google Sans, Onest, Manrope, Outfit or
the system font; the panel and clock also retain their earlier families.
Only fonts supporting the current interface language are listed. For example,
Outfit is unavailable for Russian. New styles default to Outfit for compatible
languages and Manrope for Cyrillic. Switching languages temporarily substitutes
Manrope or the system font if the saved font is incompatible; switching back
restores the previous choice. All fonts are bundled and work offline.
Choose the font family and style directly in their settings rows:
**Font ‹ font name ›**, **Font style ‹ value ›**. Use ◀ / ▶ on the remote
or tap the arrows; changes apply immediately. Switching is disabled when only
one font supports the current language.

Other value selection dialogs open with the selected row visible, even at the
end of a long list. The scrollbar stays separate from the selection buttons.

In **Interface style → Settings style**, **Show tooltips in all panels** enables
button and icon hints when focused with the remote or hovered with a mouse.
This single setting applies to all panels and is off by default. Changes apply
immediately; on-screen control instructions remain visible.

Background sources:

- A gradient with your chosen colors.
- A local image or video, plus a separate Day/Night image source.
- A folder slideshow with subfolders, order, interval, and next-image controls. Use the shared folder picker or the separate path entry in slideshow settings. For manual input, enter an absolute path such as `/storage/emulated/0/Pictures`, or `/storage/VOLUME_NAME/Wallpapers` for a USB drive. Wallpaper files are not modified.

  The slideshow pauses while you watch a film or TV. If the change interval has
  elapsed, the next image loads when you return to the home screen. Otherwise,
  the countdown continues for the remaining time.
  When the slide changes, the previous wallpaper stays visible until the next
  image is ready to display.

- Bing, Wallhaven or NASA APOD online wallpapers, or an image URL with available update options. On failure, settings show the source, loading stage and cause, including the HTTP status when available; the diagnostic report also includes these details. Previously downloaded wallpapers are preserved.
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
The file name appears below each selection; an empty slot and an unavailable file
are distinct. Images selected before this update or restored from a backup may
display the launcher’s internal file name.

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
motion. Clouds of different sizes and shapes drift slowly in one direction,
randomly chosen as left or right when the scene is created. Their speeds vary
slightly; clouds move off-screen and enter from the opposite side.
Realistic scenes are bundled; time changes their lighting and weather
is drawn over them.

Wallpaper placement, brightness, saturation, and dimming depend on the source
and memory-saving mode.

In online wallpaper settings, select **Wallhaven** and a theme: **Mixed**, **Nature**,
**Space**, **Cities**, or **Minimalism**. No account or API key is needed.
Random SFW images are downloaded in 16:9 at Full HD or higher.
Choose an interval of 1, 6, 12, or 24 hours; **Refresh wallpaper** immediately
selects another image. Automatic updates run while the launcher is open and resume
when you return. The last wallpaper is available offline and remains on download
failure. Service availability depends on your network and provider.

**NASA APOD — astronomy picture of the day** downloads images directly from NASA
without an API key or a separate app. New publications are checked hourly while
the launcher is open; an unchanged image is not downloaded again. On video days,
the latest suitable image among seven publications is used. **Refresh wallpaper**
retries the download immediately. On failure, the last successful wallpaper remains.
Sizes and aspect ratios vary; 16:9 and 4K are not guaranteed. Collapsed help shows
the date, title, author credits and publication link. Images belong to their
respective rights holders.

Reddit is currently disabled and cannot be selected.

## Continue Watching

Path: **Home screen → Categories and order → Continue Watching**.

This category shows programs apps have submitted to Android Watch Next. A card
resumes playback through the action supplied by its app. Like App feeds, it uses
one row of cards with cover art and captions below. If the app supplied only a
description, the card uses it as the title. Entries that have neither a title
nor a description are hidden. The app icon and name appear at the top of the
cover. When the app reports playback progress, a bar appears along the bottom
of the cover. Choose participating apps, a total limit, and per-app limits,
and choose whether to show the progress bar and description. Hold OK to view
program details or hide a card. Change the
category's visibility and position in the category editor.
While this category loads at launcher startup, it shows one empty card
and the heading if headings are enabled. When the category is first and startup
focus is set to cards, the placeholder receives focus. Use the arrow buttons
to move away. If the placeholder still has focus when loading finishes, focus
moves to the first available card. An empty response hides the category.

**Category appearance** offers the same controls as App feeds. Cover size and
corners, spacing, captions, heading, padding, and background inherit the shared
appearance. Set overrides for this category or reset them to the shared
values. A previously customized card size is kept until reset.
The appearance source and label settings are saved independently for this section.
The source badge and progress bar stay on the covers.

Apps appear in one alphabetical list; toggling an app keeps its row in place.
An enabled switch allows cards; a disabled switch blocks them. Each row shows
its state or card count. Saved blocks for missing apps can still be removed.
The limits list puts current card sources and apps with saved limits first,
followed by other apps.

The launcher does not read viewing history directly from every video service.
Card availability, freshness, and resuming at the right position depend on the
source app and Android's Watch Next data.

## Top panel and widgets

**Network storage and USB.** Under **Top panel → Objects**, you can turn
**Network storage** and **USB drives** off independently. Icons appear only
when a mounted volume is detected; the USB icon does not represent a keyboard,
remote or other USB peripheral. NAS appears only on compatible firmware with
an accessible Formuler network storage screen. Selecting NAS opens that screen;
USB opens the system storage settings. If the firmware does not provide these
settings, an unavailable message appears. The NAS icon indicates a mounted share,
not a check that the server's files can be reached. Firmware that hides volume
or disk type information may prevent the corresponding icon from appearing.
Quick settings has separate visibility switches; both icons can be moved
using their panel's object order settings.
On incompatible firmware, the network storage switch is disabled in both panels.
On compatible firmware, you can turn it on before mounting a network share.


Path: **Top panel → Objects / Object order**.

Nested settings windows, including value and color selection, open below
the top panel. Long lists scroll within the window bounds.

The **Network** group offers a separate **Network speed** widget.
It is off by default and shows **↓ receive** and **↑ send** in B/s, KiB/s,
MiB/s or GiB/s. In **Network speed settings**, choose an update interval
from **1 to 10 seconds** in one-second steps; the default is 3 seconds.
Selecting the widget opens a readings menu with a gear for these settings.

This is average current traffic across the device’s network interfaces,
not an internet bandwidth test. Usage statistics access and ADB are not required.
Until the second sample, after a pause or when counters are unavailable,
readings show “—”; no traffic is displayed as 0 B/s. Sampling pauses when
the widget is hidden, another app is opened or the screen is off.
Visibility on the quick settings panel is separate; the interval is shared.
Use **Object order** to change its position.

Enable the **System** widget in **Top panel → Objects**; it is off by default.
The panel displays CPU and RAM. **System widget settings** lets you keep either
value or only the icon and choose an **Update interval** from 1 to 10 seconds
(5 by default). The interval applies to CPU, RAM and the other widget readings
on both panels. Select the widget to see overall CPU load, used and
available RAM, free/total internal storage, device uptime since boot
(hours:minutes), and one-hour CPU/RAM charts. CPU temperature appears only when
the system source is available; GPU is not displayed. CPU availability depends
on firmware: when direct access is blocked, the widget uses the built-in ADB's
previously configured and verified local connection. Without that connection,
missing readings appear as “—” or **Unavailable**. After a pause, CPU first appears
on the second successful sample, after the selected interval.

Readings refresh at the selected interval while the widget or its menu is visible.
Charts show minute averages and peak markers on a 0–100% scale. Other apps,
hiding the widget, turning the screen off, and read failures leave gaps;
history is not filled retrospectively. The last hour stays in memory and
resets when the launcher process restarts. RAM refers to device memory;
“used” means “total − available”. Sizes use binary MiB/GiB units.
Visibility on the quick settings panel is separate; CPU/RAM display options
are shared with the top panel.

In the **Sound and inputs** group, **Show volume** enables an informational volume and audio output block.
It is enabled by default; visibility and position persist after a restart.
In **Volume settings → Update interval**, choose a polling interval from 1 to
10 seconds; the default is 3 seconds. The setting is available in both panels'
object lists, is shared between them, and takes effect immediately.
The block shows a speaker icon, a percentage and the current output, such as
**TV**, **ARC**, **HDMI** or **Bluetooth**. When muted, a crossed-out speaker
replaces the percentage. No remote action is needed: the block cannot receive
focus and refreshes at the selected interval while the panel is visible.
Its visibility on the quick settings panel is configured separately.

The percentage represents Android media volume. The level of an external audio
system over ARC/CEC may differ or be unavailable, depending on firmware.
Fixed or unavailable volume is shown as “—”. Identifying the selected output
requires Android 13 or later and firmware that exposes the route; otherwise
a neutral TV icon and “—” appear. **Multiple** indicates several outputs.
After waking, the output updates as the connection to the audio system recovers.

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
 type, Wi-Fi name, signal, link speed, frequency, separate IPv4 and IPv6 address
groups (IPv4 first), and current device
receive/send traffic. Wi-Fi link speed is the connection rate to the access point,
not an internet speed test. Data unavailable from Android is marked explicitly;
no additional location permission is requested. The summary refreshes every three
seconds only while open and the app is active. It includes a system network
settings button.

**KVN** is a separate object in the **Network** group. You can
independently show, hide and reorder it on the top panel and the quick settings
panel. Pressing it opens a menu with KVN status, app, profile and available actions.
The menu can open the KVN app or Android KVN settings; its gear opens **KVN settings**,
shared by both panels. Options include showing only when connected (the default),
the app name, connection color and notifications about manual command results.

With **KVN app → Automatic**, the launcher adopts a manually connected KVN and
remembers the app and available profile name for reconnection. Connecting another
KVN updates this choice. Explicit selection keeps the widget bound to that client.
Identifying the owner and profile requires an already configured local TCP ADB connection (not TLS).
If identification is unavailable, connection status is shown and unverified control
is unavailable. The last client is never substituted for an unknown active KVN.

Direct connect and disconnect commands support **AmneziaWG** and **WireGuard**.
Grant control permission in the launcher's KVN settings and enable remote control
in the client. Grant the permission from the main launcher, not the overlay panel.
The profile name is detected during a manual connection when available; otherwise
enter it exactly as in the client. **Happ**, **MantaRay** and **Incy** also support connect
and disconnect. Configure and test a connection in the client first; the profile
is selected there, so no profile name is required in the launcher.
For MantaRay, confirm the command in its own window. For unattended startup
after boot, use Android always-on mode.
Incy commands may open its screen. For automatic connection, select Incy under
**Autostart → KVN on TV startup**; to start without opening the client, use
**Android always-on KVN** after configuring and approving the first connection.
**Background autostart** requires a compatible app activity; Incy's main activity
uses an incompatible launch mode, so that switch is unavailable.
Other clients can be opened. Sending a command
alone does not count as connecting: the launcher waits for the resulting state.

**Clock, date and weather on the wallpaper.** Open **Top panel → Objects →
Clock, date and weather**. Choose **Disabled**, **Top panel** or **On wallpaper** separately
for the time, date and weather. For example, move the clock to the wallpaper and
keep the date and weather in the panel, grouped or separate. In **Wallpaper appearance → Position and size**,
set **Block position** to left, center or right. On the **Horizontal offset** slider,
press ◀ / ▶ to move the whole block within the selected zone. Changing the position
returns the block to its default point in that zone.
Set **Alignment within block** separately. It stays the same when the position
changes. **Vertical offset** starts at 0 below the top panel. Increase it to move
the entire block down; decrease it to move up. The maximum depends on the block
size: its bottom edge cannot go below the middle of the screen. Changing the
season or horizontal position does not adjust the height automatically.
Both offset sliders and the overall size slider use the same track without tick marks.
**Block size** grows the block downward while keeping its top point fixed.
The maximum depends on its contents, font and available space: growth stops at
the middle of the screen or side boundaries. All values transfer with backups and appearance sync.
Font, colors and glow are in the corresponding appearance sections.
**Reset all settings on this screen** is at the end of the scrolling list. After confirmation, it
restores the default position, alignment, both offsets, size, object order and layers.
Formats, fonts, colors and object placement are kept.
In **Wallpaper appearance → Position and size → Object order**, reorder the date, weather and clock
from top to bottom: OK starts moving, ▲ / ▼ change the order, and OK or Back
finishes. The order is retained for hidden elements too. By default, the date
and weather sit above the large clock.
In the desired appearance profile, open **Object formats → Weather text format**
and insert `{WARN}` at the desired position. Panel and wallpaper templates are independent.
Warnings are hidden when weather data is stale. This decorative block has no dimming
background, cannot receive focus or presses, and does not open widgets. Tile positions
and the scrolling viewport stay unchanged; tiles can overlap the clock.
In the adaptive landscape, the mountain outline can overlap the clock, date and weather in both
illustrated and realistic variants. You adjust the block height yourself. Clouds, rain, snow and
fog pass over the wallpaper clock, date and weather; tiles and the top panel
remain above the effects. Other wallpapers have no overlap effect.
**Wallpaper appearance → Position and size** offers two independent switches for the entire clock,
date and weather block: **Above landscape** removes mountain overlap, while
**Above weather effects** places the block in front of clouds, rain, snow and fog.
Both are off by default and can be enabled together or separately.
They also work when only the date or weather is shown on the wallpaper without a clock.
Moving the elements hides them from the top panel; choosing
**Top panel** again restores their previous order and grouping mode. Wallpaper
elements are also excluded from the top panel order editor. Quick settings panel
visibility and order remain independent; editing that panel does not hide wallpaper clocks.

**Top panel → Objects** has one **Clock, date and weather** entry with a brief
placement summary. Each element's placement is edited only inside this entry.
The remaining settings are split into **Panel appearance**, **Wallpaper appearance**
(available even when hidden). Both profiles contain **Object formats**,
**Font and digits**, and **Colors and effects**. The panel has **Block layout**;
the wallpaper has **Position and size**, including layer settings.
**Object formats** edits time, date and weather formats.
Headings and dividers separate **Clock**, **Date** and **Weather** groups.
**Clock** contains **Time format**, **Show colon** and **Animate digits**;
**Date** contains **Date format**, and **Weather** contains **Temperature unit** and **Weather text format**.
Colon and animation controls remain available when inheriting the top panel font.
Formats, units, warnings, colors and icons are independent for panel and wallpaper.
Existing settings remain until you edit the corresponding profile.
When editing the wallpaper block, the menu always temporarily chooses the side
with less overlap. This behavior cannot be disabled. All **Wallpaper appearance**
windows hide the preview except the **Weather text format** and **Custom date format** editors.
Focus and the current page remain,
and leaving restores the usual menu side. **Weather settings** is a separate entry on the main
**Clock, date and weather** page.
Date settings include a short weekday format, such as “Вс, 1 Нояб” in Russian
or “Sun, 1 Nov” in English: weekday, comma, day and abbreviated month.
The first choice is **Custom format**: enter a date pattern with validation
and underlined unsupported characters. For both panel and wallpaper appearance,
a labelled **Preview** above the input updates as you type.
The input and preview stay visible while the keyboard is open; only the
help scrolls when space is limited. Without the keyboard, the full legend is visible.
Done on the keyboard focuses OK, or Cancel if the pattern is invalid.
Use Left/Right to select a button, then confirm it with the remote.
The settings panel is hidden while editing. Saving or cancelling restores
the previous page with focus on the date setting.
It explains the library symbols: `d`/`dd` for day, `M`/`MM` for month number, `MMM`/`MMMM` for
month name, `EEE`/`EEEE` for weekday and `yy`/`yyyy` for year.
For example, `EEEE, d. MMMM yyyy`. Enclose literal text in single quotes.
Cancel keeps the previous value; the existing format remains selected until you save.

**Panel appearance → Block layout** can group the visible elements.
A grouped block places the date above weather, using two rows in total.
A weather template line break becomes a space here without changing the saved
template; weather can use two lines again when the date is hidden. Grouping is unavailable when
only one or no elements remain. Quick settings has independent visibility and grouping.
Shared size (10–24), font, style, weight and glow apply to the clock, date and
weather in both panels. Digit animation has its own switch. In panel and wallpaper
appearance, **Clock color mode** lets you choose one color for the whole clock or
separate colors for hours and minutes. Your choices are saved when you switch modes.
**Colors and effects → Date color** sets the date color for the selected profile.
Weather text and icon palettes are here too.
**Colors and effects** is split into **Shared settings** for the whole block’s text glow,
**Clock** for color mode and palettes, **Date** for the date color,
and **Weather** for the icon set and text and icon colors.
**Reset all settings on this screen** is the final list item and scrolls with
the settings. After confirmation,
it restores inherited colors, a single clock color, disabled glow and outline weather
icons for the selected appearance profile. Fonts, formats, colon visibility,
animation, placement, layout, layers and the other appearance profile are kept.
Quick settings uses the top-panel
profile while keeping its own visibility, order and grouping.
Select **Default** to restore the inherited color.
The swatch then shows a chain icon for the whole clock, separate hours and minutes,
date, weather text and weather icons. This applies to panel and wallpaper appearance.
Custom colors appear without the icon.
Turning off **Show colon** preserves the gap
between hours and minutes. A grouped clock with date or weather offers left/right clock
position and spacing (0–32).
In **Panel appearance → Font and digits**, **Inherit top panel appearance** is on
by default. Custom controls are hidden; the panel supplies the size and font,
and the font style is regular.
Turn inheritance off to edit these settings. Turning it back on keeps your custom
values. **Reset settings** is the final list item and scrolls with the settings.
It restores this screen’s defaults after
confirmation and enables inheritance; colors, layout, colon, digit animation and wallpaper appearance stay as set.
When top-panel grouping is off, both layout controls remain
visible but disabled, keeping their saved values. Quick-settings grouping does
not enable them. The background and corner radius always match the other
objects in the corresponding panel, including when only one element remains.

Panel clock and date buttons always open the calendar; weather opens the forecast.
A combined block opens the calendar, forecast or both according to its visible members.
Both parts fit in one window without scrolling. Returning from settings updates the
contents according to the current composition. Saturday and Sunday dates are red,
including today.

**Font style** sits below the font selector in panel and wallpaper appearance. It
offers only **Standard** and **Italic**. It changes only the slant, preserving
family, size, weight, color, glow and background. **Font weight** is an inline
arrow control offering only distinct weights for the selected font: Manrope
200–800, Roboto Mono 100–700, Google Sans 400/500/700, Medeo Serif 400, other bundled families
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
adjacent slots at the new position. Hidden items stay hidden. Enabled weather
without data shows a cloud icon that opens its menu; panel height stays unchanged.
Widget settings, grouping, block appearance and the press action are shared by both panels
and edited in the main top panel settings. The quick settings panel’s **Objects** page
contains only visibility switches, so its set of visible objects is independent.

Widgets open their own menus and settings. Availability depends on Android data:
traffic needs usage access, and inputs need support for the relevant TV API.

## Weather

Path: **Top panel → Objects → Clock, date and weather → Weather settings**.

Sources include Breezy Weather, Open-Meteo, MET Norway, OpenWeather, Yandex, Gismeteo, and Custom server (Open-Meteo). Choose a city
or coordinates, detect location with the required permission, refresh data, and
configure the forecast. Units are in each profile’s **Object formats**;
warnings are inserted as a token in its weather editor.

**Gismeteo is a test source. Do not use it in production.** It retrieves
current weather and a forecast of up to seven days from the Gismeteo XML service without a key.

For a custom server, enter a base HTTPS address such as
`https://weather.example.test/home`. The launcher adds `/v1/forecast`.
Enter the address manually or select **Import address from file** below the
**Server HTTPS address** button. Choose a UTF-8 TXT file up to 4 KB containing
a single base HTTPS address. A valid address is saved as soon as you select the file.
The built-in browser opens in the same panel; cancellation or an error keeps
the previous address.
The server determines the location: city entry, coordinates, and location
detection are hidden for this source. The launcher sends no `latitude` or
`longitude`; the forecast uses the coordinates and time zone returned by the server.
Selecting public Open-Meteo directly still requires a location.
If the server requires authentication, enter a Bearer token and select **Check connection**.
Below manual entry for the Bearer token, OpenWeather key, and Yandex API key,
select **Import token from file**. Choose a UTF-8 TXT file up to 4 KB containing
a single token or key. The built-in browser opens in the same panel.
A valid value is saved after selecting the file; cancellation or an error keeps
the previous secret. Manual entry still opens a masked field and saves with **OK**.
Saving or importing a token/key does not check the connection. After changing it,
select **Check connection** for a custom server or **Refresh weather** for another
source. File reading, UTF-8 encoding, size, format, and value-saving errors are
reported separately from weather server access errors.
The token is stored on this TV and is tied to the address you entered. Enter it
again after moving to another TV. During a temporary outage, the launcher shows
the last available data from that server and when it was updated.

Press OK or click the weather to open **Weather forecast**. **Widget settings** offer
**3, 5, or 7 days**, including today (5 by default), and a choice of
**Compact cards** with the date, icon and minimum/maximum temperatures or a
**Detailed list** with conditions and precipitation probability. Units follow
the panel's °C/°F setting. If the source returns fewer days, their number is
shown; unavailable values use “—” and stale data is marked. The menu shows
the location, source and update time. If the source provides a feels-like
temperature, the menu displays it in the selected °C/°F unit.
Cached forecasts retain their dates;
sources without time zone information are identified as using TV time.

In the selected profile, open **Colors and effects → Weather icon set**, preview seven sets:
Standard, Outline, Filled, Two-tone, Pixel, Geometric, and Circled.
Geometric uses angular silhouettes; Circled places weather symbols inside a round frame.
Outline icons are used by default. Your previously selected set is kept.
The wallpaper set is independent; the forecast
and quick settings use the top-panel set. The selected set is visible and focused
as soon as the dialog opens; remote arrows scroll the list. **Weather text color** and
**Weather icon color** can be set separately. Select **Match weather text** in
the icon palette to inherit the weather text color.

In **Object formats → Weather text format**, edit the selected profile’s entire
template in one field. The title identifies the destination: **Top panel** or **On wallpaper**.
Below it, the preview uses the same line limit as the selected destination.
Type your own text with the keyboard
or use the compact buttons below to insert tokens at the cursor. Buttons show
short names without braces in a single row; they insert tokens with curly braces.
A separate legend below the buttons keeps all token descriptions visible in two
columns of six items, each token and its description on its own line.
The expandable help at the bottom contains the detailed editing rules.
The preview appears larger in a taller frame with small padding around its
contents. The **Preview:** label is to its left, vertically centered.
OK or pressing the field opens the keyboard;
after dismissing it, arrow keys move focus between controls.
The title, input field and preview stay above the keyboard when it opens;
the preview becomes shorter.
On insertion buttons, ◄ / ► select a function in the row, ▲ returns to the
field, and ▼ goes straight to the reference in one press. Returning upward from
the reference or downward from the field restores the last selected button.
The cursor position and selection are preserved when moving to buttons, returning
to the field and reopening the keyboard. A static insertion marker remains visible
while the field is unfocused and follows the cursor after inserting a token.
Save applies the template; Cancel or Back discards the draft.
**Reset format**, next to Cancel, restores the default template with an icon,
temperature and warning. Select **Save** to apply it; the temperature unit is kept.
Choose °C/°F separately in **Object formats → Temperature unit**.

Tokens are case-insensitive: `{TEMP}` is temperature, `{FEELS}` is feels-like temperature,
`{MAX}` and `{MIN}` are today’s high and low, `{WARN}` is a warning,
`{CITY}` is the city, `{COND}` is the weather description with an icon, `{DESC}` is
the description without an icon, `{ICON}` is just the icon, `{WIND}` is wind,
and `{HUM}` is humidity. `{BR}` inserts the single allowed line break; in a combined
panel with the date, it appears as a space while staying saved in the template.
A regular keyboard line break also works. Russian token aliases are supported too. For example:

```text
My weather: {TEMP} / {MAX} / {MIN} ({WARN}){BR}{CITY} {COND}
```

Parentheses around a single value, such as `({WARN})`, disappear with that value
when its data is unavailable. Use `{{` and `}}` for literal curly braces.
An unknown token or extra line break is highlighted in red, with the reason below
the field. Saving becomes available after fixing the error.
Templates allow up to 2048 characters and 64 elements,
and must include at least one weather token.

All selected forecast days fit in one window without scrolling. The detailed list
uses compact rows and two columns when space permits. The combined window gives
the calendar and weather matching surfaces; when space is limited, the content
scales down as a whole, keeping every day visible. Back closes the menu and returns
focus to the widget. The gear opens shared block settings. Settings remain accessible
without weather data, and the calendar keeps working in the combined view.
New combined blocks show weather and calendar together; an explicitly saved
calendar enable/disable choice is respected until a new block action is selected.

Breezy Weather requires a compatible installed app with a configured provider.
MET Norway needs no key: data by MET Norway under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/), adapted from https://api.met.no/. Forecast days use the TV time zone; min/max cover available periods and precipitation probability is unavailable. OpenWeather and Yandex require their respective personal keys. Cached data helps during temporary
outages, but does not make an old forecast current.

## Notifications and playback

In the notification blocking list, an enabled switch means the app's notifications
are blocked. Each app appears once; changing a switch keeps the list order.

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
On Philips TVs, metadata suffixes such as `&GAME_CONSOLE` are removed from
Android's custom HDMI names. A `null` name falls back to the system input name.
Names you enter in CuteLauncher are kept exactly as entered.

Input availability, labels, and switching depend on firmware. A TV box's HDMI
connection is not equivalent to the television's own input list.
When system inputs are unavailable, their settings are also unavailable.
Saved names, icons, and the CEC option are preserved.

If firmware confuses port states, enable Use only CEC for HDMI state in input
settings. The indicator then uses CEC-device data; without it, the state is
unknown. This option is off by default. All inputs, names, and icons remain.
Turning it off restores the states reported by firmware.

If standard input opening fails, the launcher tries fallback routes.
Special YaOS and XGIMI handlers are supported; MiTV-NSOP0 opens Xiaomi's
source picker. If firmware blocks every route, the launcher reports failure.
An accepted launch does not guarantee a signal.

## Night mode and brightness

Path: **Night mode and brightness**; the night-mode widget provides quick controls.

**Fill the top panel button** highlights active night mode with the theme's
accent color. The fill is off by default.

The night filter controls dimming, warmth, and color strength. Enable it manually,
at scheduled times, or from sunset to sunrise for a chosen location, with offsets
and smooth transitions. When starting without internet, saved solar events are
used. If events for the required day are missing, yesterday's sunrise and sunset
times for the same location are reused; without that history, the defaults are
08:00 and 20:00. The schedule works immediately while times refresh in the background.
Skip the current night, enable until morning, or resume
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

Path: **Interface style → Screensaver clock style / Screensaver settings**, when Android
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
  Service screens, factory screens and setup wizards are excluded from recovery
  home choices. Recovery is unavailable if no suitable launcher remains.
  Before disabling stock HOME, known remote-button and Live TV service dependencies
  are checked, including additional Android profiles. Google Cast presence alone
  does not block disabling the launcher. A dependency or unavailable
  check blocks disabling; diagnostics include the reason. No profiles are removed.
- Enable the launcher's accessibility service and configure Home interception.
- Grant supported special access to the launcher through ADB.
- Launch an app or switch once to HDMI after TV boot or wake, with event and delay settings.
  For apps, **Wait for internet** waits up to 60 seconds after the delay, then makes
  one launch attempt. Remote input or leaving Home cancels it. It is off by default
  and does not delay HDMI switching.

**Autostart** includes a separate **KVN on TV startup** choice:
**Not selected** disables KVN startup; selecting an installed KVN client enables
it in addition to the existing app/HDMI target. Direct connection requires a
supported client, a configured profile and control permissions. Selecting an app
does not immediately connect it. A separate 0–60 second delay and an optional
wake trigger (off by default) are available.
Boot schedules one attempt after a network becomes available, with a network wait
bounded to one minute after the delay and connection confirmation bounded to 15 seconds.
Android's scheduler may defer execution. An active KVN is not replaced.
The client or firmware may restrict background connections; such an attempt is
not reported as successful.
Wake is detected only while the launcher process is alive. The latest attempt's
result appears in autostart settings. KVN client, profile and startup settings
are local to the TV and excluded from backups; object visibility is backed up.

Under **Startup method**, choose **Android always-on KVN** instead of a client
command. Select a compatible app after configuring it and approving its first
connection. The launcher's local ADB connection must be enabled.
The change is saved in Android; **restart the TV** to apply it. Android starts
the KVN after boot. Delay and wake settings are unused in this mode.
Blocking traffic without KVN is not enabled; changes are rejected if this
protection is already active. Leaving the mode restores the previous system
selection unless you changed it separately, and also requires a restart.
The widget cannot temporarily disconnect an always-on KVN: change the system
mode in autostart or Android settings first.
Once the system selection is cleared, connection control returns to the widget
immediately. The restart notice remains in autostart settings; the widget menu
hides it while autostart is disabled.

In **Autostart → Background apps**, check user apps to launch once behind Home
after TV boot. CuteLauncher must open within one minute: set it as Home or
enable launcher startup on boot. Checking an app saves the selection without
launching it immediately. Apps start one by one; remote input or leaving the
launcher cancels remaining launches. Waking from sleep does not repeat them.
Apps incompatible with this mode are marked unavailable; a previously selected
unavailable app can still be unchecked. Launching does not enable features inside
an app or guarantee continuous operation: configure permissions and background
operation in the app itself. Android and the TV firmware may stop it.
Selections stay on this TV and are not transferred through backups.
The subsection includes collapsed help explaining how it works.
The same choice is available in each app's context menu as **Background autostart**.
It shares its state with the list: switching it in either place immediately updates
the other. A failed save keeps the previous value. Incompatible apps cannot be
enabled, but a previously saved selection can still be disabled.

Normal app/HDMI autostart acts when Android hands control to the launcher; choosing a target does
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

**Ignore button** consumes the selected press without opening an app or sending
a command. It is available for assignable remapper buttons; essential controls
remain protected. Disabling the assignment restores the button's normal action.

Path: **Launcher and TV controls → Remote button remapper**.

In button diagnostics, the start/stop instructions and the report path, when known,
are visible without expanding help. Help explains copying the report and limitations.
Button diagnostics records events Android sends to the service and saves the
latest text report. Assign a short press or hold to a chosen action. The
“Action” row opens the grouped picker. Up and Down move within a column,
and Left and Right switch columns. OK on an action returns to the editor
with that action selected. Back closes the picker and keeps the previous
choice. “Ignore button” is below the categories.

In “Inputs,” select a specific HDMI input or open live TV. The choices
depend on the device's inputs and system TV app. “Screen and sound” groups
display actions and the media mute toggle. “System” opens network or
Bluetooth settings. System screens appear when the firmware provides an
accessible handler.

“Turn off TV” puts the device in standby; “Reboot TV” requires configured ADB.
An assigned power action runs immediately without an additional confirmation.
On a TV box, the command controls the box; the TV's response depends on HDMI-CEC
and firmware. There are global and per-mapping switches and reset.

“Black screen” covers the current app with a black layer. Repeat the same press
or press Back to show the picture. This action uses CuteLauncher’s enabled
accessibility service.

On compatible TCL TVs, “Turn off TCL screen” starts the TV’s Audio Only countdown.
After the countdown, the TV turns off the picture and keeps the sound playing.
If Android blocks the background service start, set up local ADB. Use the
remote to restore the picture as supported by the TCL firmware.

“Toggle Black Screen” shows a black overlay over the current app. Press or hold
the same button again to hide it. This action requires the paid version of Black
Screen by jApp and permission to display over other apps. [Black Screen on Google Play](https://play.google.com/store/apps/details?id=io.japp.blackscreen).

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

### Holding volume buttons

“Hold volume buttons” offers “Auto: while the panel is visible”, “Timed pause”,
“Custom repeat” and “Disabled”. An enabled remapper initially uses Auto; your
explicit choice is preserved. The pause can be 3, 5, 10, 15 or 30 seconds.
Auto extends it while the system window is visible, up to one minute; an
unavailable window falls back to the timer. Assignments and Home interception
are unavailable during a pause. Custom repeat requires volume keys to reach
the service. See the [FAQ](FAQ_EN.md#why-does-holding-a-volume-button-change-only-one-step)
for the initial single step and choosing another mode.


## Open apps

Path: **Launcher and TV controls → Open apps**. Assign the “Open apps panel” action
in the remapper, just like the quick settings panel. This settings page also opens
the panel directly and selects its type: Automatic, CuteLauncher panel, or
Built-in panel. Automatic mode uses the available manufacturer's `com.nes.recents`
panel (for example, on KP1), otherwise CuteLauncher's own panel. The built-in
option depends on the firmware.
When returning from the panel, focus stays on the “Open panel” button.

The CuteLauncher panel requires authorized local ADB and a connected accessibility
service. Both access statuses appear below the panel title, above its action
buttons, and on its settings page.
If access is missing, select its row: ADB opens CuteLauncher's connection setup,
and Accessibility opens the system service settings. Statuses refresh on return.
The panel shows icons and names of TV apps with existing tasks, including
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

Bundled restrictions for specific models and firmware preserve known system
dependencies. They apply only when the specified device metadata matches exactly
and also protect restoration. Observations from another TV do not authorize
disabling packages on yours.

Path: **Launcher and TV controls → TV cleanup manager**.

After a change or restoration, Last operation result shows each package as
changed, unchanged, skipped, failed, or not attempted. Failures identify the
stage: reading, saving the recovery journal, issuing the command, or verifying
the state. Refreshing the list preserves this result until another operation
or leaving the page.

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
Apps that open system settings and TV inputs are also protected. If their handlers
cannot be identified, cleanup stops before changing packages.
Low-level HDMI/AV services and packages requesting hardware-input access are also
protected, even when their input is not currently published. This does not hide
inputs or change how they are displayed.
It also prevents disabling core Android modules and known critical MediaTek/CLTV
services even when the firmware does not mark them as persistent services.

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

## Choosing files and folders

In **Advanced → File manager**, choose the preferred method for all file, folder,
and document-save actions:

- **Ask every time** — the default: when an external picker is available, choose
  between the system picker and the built-in browser.
- **Built-in** — open the CuteLauncher browser directly.
- **External** — open a compatible system or installed picker directly.

If no compatible external handler is available, or it becomes unavailable before
launch, the built-in browser opens. Cancelling the external picker ends selection.
The preference persists between launches and is included in backups and synchronization.

**Advanced → Built-in file browser** provides:

- a starting folder: TV storage, Downloads, or the last opened folder;
- sorting by name, modification date, or size, in ascending or descending order;
- keeping folders at the top;
- showing hidden files and folders;
- showing file sizes and dates.

By default, the last folder for that action opens, names are sorted in ascending
order, folders come first, hidden items are excluded, and sizes and dates are shown.
An already selected folder takes priority over the starting folder. The original
folder is remembered separately for the wallpaper, day and night images, and each
application's banner when selected in the built-in browser. Select an older image
again if its original folder was not saved. Cancelling keeps the selected file or
folder unchanged but remembers the last visited folder. If a folder was removed
or a drive disconnected, TV storage or the selected Downloads folder opens;
unavailable Downloads falls back to TV storage. Folder history stays on this TV,
while browser options are included in backups and synchronization.

The built-in browser shows folders and matching files only: JSON for settings
imports, TXT/JSON for links and cleaner lists, images for banners and icons,
and images or videos for wallpapers. When details are enabled, each file shows its size and one available
date, either creation or modification. Missing details are shown as “Unavailable”.

The built-in browser shows the current path at the top. The up-arrow button
and Back move to the parent folder; Back at the storage root closes the picker.
The close button exits from any level. Returning upward restores the scroll
position and focus of the folder you left. Up from the first item moves focus to
the top buttons; Left/Right move between them. Down past the end of the list moves
focus to the confirmation button. For a folder, press “Use this folder”;
for a file, select its name. To export, choose a folder and press “Save”. A numeric
suffix is added when a name is already taken; existing files are not overwritten.
The export success message shows the actual path and name of the created file.
Cancellation preserves your previous selection.


The path is labelled “Current folder”; the export “File name” stays visible while
scrolling. Press OK on a long path or export name to expand it, use the arrows to
read it, and press OK again or move focus away to collapse it. In the list, Left
expands an item's full name only if it is clipped; another Left collapses it.
If the full name fits, Left keeps the row height unchanged. Right moves to folder confirmation, and
Left from confirmation returns to the list. Re-entering a folder restores its
scroll position and focus. The browser indicates when only part of a folder's
contents is shown.

The built-in browser needs storage access on Android 9–10 (including write access
when saving) or all files access on Android 11 and newer. It works with TV storage
and attached drives. The system picker may offer other sources and does not require
broad file access. Manual path entry is available only in slideshow settings.

On Android 11 and newer, all files access is a separate setting that may not
appear in the app’s regular permission list. CuteLauncher opens its page in
system settings. If the firmware does not provide this screen, the app reports
it: use the system file picker or a compatible file manager. Opening settings
does not mean that access has already been granted.

## Backups and synchronization

Path: **Advanced → Backup and restore**.

Export settings to a file and import them again; create, restore, delete, and
refresh backups. Import/export prevents duplicate requests while running. A list
loading error remains visible until a successful refresh and does not mean there
are no backups. A private rollback point is created before restoration. Backups
contain supported launcher settings, categories, and custom appearance; they
do not back up installed apps or the entire TV system.

Backups and synchronization shows the current mode, enabled state, storage,
and the time of the last successful action. Disconnecting WebDAV or Google Drive
requires confirmation; cancelling keeps the connection.

Automatic backups support schedules, frequency, and retention. Storage includes
the internal folder, Downloads / CuteLauncher, a selected folder, WebDAV, and
Google Drive with configured access. Internal storage is removed when app data
is deleted. Choose an external folder using the system picker or built-in browser. On Android 9,
saving to Downloads requires storage permission; internal storage and the system
document picker do not require it.

A separate card at the top of the Google Drive connection page shows the connection
status. For a configured account, the button reads “Reconnect Google Drive”.
Help is at the bottom of the page.

In Google Drive connection settings, import Client ID and Client Secret from the
JSON downloaded from Google Cloud for a “TVs and Limited Input devices” client.
Transfer the file to the TV or a USB drive and select “Import Client ID and Secret from JSON”.
Files up to 64 KiB with an `installed` object are supported. Then select “Connect Google Drive”
and confirm the code in your browser. Import fills the fields without connecting the account
automatically. Errors and cancellation preserve the fields; Client Secret stays masked.

In Synchronization mode, “Refresh” starts a manual settings exchange.
“Backup management” always creates, lists, restores and deletes full backups,
regardless of the selected mode. Sync files are excluded; creating a backup does
not apply settings from other TVs.
New file names and backup labels include the TV manufacturer/model and device ID.
The ID survives a normal reinstall with the same signing key; a factory reset,
a different Android user or signing key may change it. If the firmware provides
no ID, an installation-local ID is used. Older backups remain accessible.
Each backup is marked “This TV” or “Another TV” using the full device ID rather
than the model name. An older backup with a different installation ID is marked
“TV unknown”: after a reinstall, its origin cannot reliably be determined.
Use an updated CuteLauncher version on other TVs to read the new file names.

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

If validation fails, the launcher reports the reason: an APK for another app,
the same or an older build, a different signature, unavailable certificates,
an unreadable file, or a verification error. For file problems, download the
update again. If the signature differs, tell the author where you obtained
the installed version; if a verification error persists, send a diagnostic
report. You do not need to uninstall the launcher or delete its data.

The launcher remembers granted access in local settings: accessibility for button
remapping, notifications, display over other apps, usage statistics, system settings
changes, and Continue Watching. If permissions are reset, it periodically tries to
restore them through the previously configured local ADB connection, including
outside app updates. Access that has never been granted is not enabled automatically.
The initial state comes from a snapshot saved by the previous version or permissions
observed by the current version.

Background checks run roughly every 15 minutes. Android may postpone them,
particularly during sleep. The service has 30 seconds to connect; after three
background attempts, recovery pauses for an hour, then continues. ADB unavailability
does not erase remembered permissions. After an update, up to five additional fast
attempts run within 15 minutes.
To stop accessibility recovery, disable it through the ADB page in CuteLauncher.
Disabling it only in Android settings is treated as lost access and may be reversed
by a background check. Force-stopping the app suspends checks until its next launch.
If ADB is unavailable, you can enable the required access manually in Android settings.
Waiting and failure reasons are included in the diagnostics report.

In **Advanced**, **Reset all settings** appears above **About CuteLauncher**.
After confirmation, Android completely clears CuteLauncher data: preferences,
sections, Favorites, statistics, remote mappings, ADB and cloud connections,
automatic backup preferences, weather keys, and files in app storage. CuteLauncher will close;
the next launch will use the initial settings, and access must be configured again.
Files saved outside CuteLauncher storage (for example, backups in Downloads or on
USB) and other apps are not deleted.

About CuteLauncher shows the version, attribution, and licenses.
The interface displays versions without a build number; Android keeps an internal
build counter for installing updates.

## Memory and resource saving

Path: **Advanced → Memory and resource saving**.

Inspect memory and cache information, free supported caches, and choose a
resource-saving mode. Clearing caches does not reset settings or disable system
apps. Cache sizes are not independent RAM measurements for each feature.

<a id="диагностика"></a>
## Compatible graphics output

Path: **Settings → Advanced → Compatible graphics output**.
If the interface flickers with night dimming, try enabling this mode.
On verified models, the workaround is enabled automatically, as shown in settings.
Other TVs have a switch. After changing it, select
**Apply and restart launcher**: settings close and Home opens.
The mode may increase graphics load. The choice is saved only on this device
and is not transferred through backups or synchronization.

## Diagnostics

Path: **Settings → Advanced → Diagnostics**. One report combines shared TV and
CuteLauncher metadata, feature compatibility and errors. There is no separate
compatibility submenu or file. Create a report, view check results, clear it,
and export it by copying or saving to disk.

On Android 11–12, a file access request can open the CuteLauncher app details
if the special access screen is unavailable. Check Permissions → Files and media there.

Creating it also reads display modes, HDR, video/audio decoders and audio-output
formats. These are capabilities reported by Android, not playback test results;
unavailable metadata is marked separately. Audio device names and addresses are
excluded from this metadata.

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
4. Select **Export report → Save to disk**, choose a folder in your selected browser,
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
| Authorized local ADB | Cleanup manager, relevant TV-control operations, and the CPU load fallback |
| Compatible file manager | Additional file sources and system folder selection; a built-in browser is also available |

Permissions are granted by the user and may be revoked by Android. A visible
setting does not guarantee firmware support. When asking about your device,
include its exact model, Android version, and firmware build.

The KVN on TV startup switch enables autostart separately. The method and app appear below it. Disabling preserves these choices; changing always-on KVN requires a restart.

TCL firmware may block AmneziaWG from starting in the background. If the boot command fails, the launcher briefly opens the KVN client once, starts the selected tunnel and restores the previous screen. If you have moved to another app, that app stays open.
