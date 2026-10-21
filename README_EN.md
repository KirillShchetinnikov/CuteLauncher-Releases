# CuteLauncher

[Русский](README.md) · [English](README_EN.md)

**Your home screen for Android TV and Google TV, with remote-friendly navigation,
your own app categories, and a look that suits your TV.**

CuteLauncher brings your apps, useful widgets, and TV controls together on one
screen. Choose what to show, where to put it, and which actions to keep within
reach. The launcher's home screen has no advertising blocks.
Created by [Kirill Shchetinnikov](https://github.com/KirillShchetinnikov).

**[Download APK](https://github.com/KirillShchetinnikov/CuteLauncher-Releases/releases/latest)**
· **[User guide](docs/USER_GUIDE_EN.md)**
· **[All documentation](docs/README_EN.md)**
· **[What's new](CHANGELOG_EN.md)**

## What makes it convenient

- **Built for the couch.** Navigate with the directional pad and OK, follow a
  clear focus indicator, hold a tile for its actions, and customize Home/Back.
- **Your apps, your order.** Create categories, collect favorites, rearrange
  items, and hide clutter. Choose rows or grids, with shared or per-category
  settings.
- **Make it your own.** Adjust tile styles, colors, sizes, labels, transparency,
  focus effects, and the side on which menus open. Tune effects or turn them off.
- **Useful information at a glance.** Arrange the clock, calendar, weather,
  network, traffic, TV inputs, notifications, and sleep timer in the top panel.
- **More comfortable evenings.** Use a dimming and warm-color night filter
  manually, on a schedule, or from sunset to sunrise, with app and HDMI exceptions.
- **Keep your setup.** Backups, automatic schedules, and selective synchronization
  help you move your layout and preferences between TVs.

## Main features

### Apps and the home screen

Custom categories, favorites, sorting, hidden and system apps, custom tile
banners, and quick access to app details. Continue Watching displays programs
from Android's Watch Next service when the firmware and installed apps provide
the necessary data.

### Wallpapers, widgets, and media

Use local images and wallpaper folders, online Bing wallpapers, separate day
and night backgrounds, or a background based on the selected app's artwork.
Customize the clock and date, and open the calendar by selecting the date.
Weather supports Breezy Weather, Open-Meteo, OpenWeather, and Yandex, subject to
each provider's requirements. Grant notification access to see notifications and
a Now Playing card with the active player's supported controls.

### Night mode and everyday TV controls

Smooth night-filter transitions, system-brightness scheduling, a clock and
screensaver, a standby timer, available TV inputs, and HDMI/CEC labels.
Configure the home app, restore the previous HOME handler, and use the built-in
ADB connection for supported system operations. The remote remapper supports
short presses and holds, app launches, Home/Back, webhooks, and a floating panel;
these system integrations still require validation on the relevant firmware.

### Settings, backups, and diagnostics

Manual and automatic backups, local folders, WebDAV, and Google Drive with the
required access configured. Selective synchronization lets each TV retain some
of its own settings. Built-in tools include APK update checks, memory information,
a resource-saving mode, and diagnostic-report export.

The TV cleanup manager lists packages and their states, imports package lists,
disables selected apps through ADB, and restores saved states. It does not delete
app data. A third-party disable list cannot be assumed safe for every TV model.

## Installation and compatibility

Download an APK from the [latest release](https://github.com/KirillShchetinnikov/CuteLauncher-Releases/releases/latest)
and install it on your TV or TV box. ARMv7, ARM64, x86_64, and universal builds
are available; choose universal if you do not know your device's architecture.
Android may ask you to allow installation from your chosen source.

The declared platform is **Android 11 and later**. Running on Android 11 has not
yet been confirmed, and development continues. Home-app selection, Home behavior,
ADB, overlays, backlight controls, notifications, and TV inputs depend on firmware
and permissions. You can launch and organize apps without enabling every
additional system integration.

See the [user guide](docs/USER_GUIDE_EN.md#разрешения-и-ограничения) for availability
and limitations. Cloud providers and some system features still have outstanding
integration checks. A feature in the current code is not necessarily included
in your installed APK or verified on every firmware version.

## Documentation and source code

- [User guide](docs/USER_GUIDE_EN.md): features, settings paths, permissions, and
  limitations.
- [Installation, permissions, and limitations](docs/USER_GUIDE_EN.md#разрешения-и-ограничения):
  additional-feature requirements and firmware-specific behavior.
- [Documentation](docs/README_EN.md): guide navigation, attribution, and licenses.

Public source code and APKs are available in
[KirillShchetinnikov/CuteLauncher-Releases](https://github.com/KirillShchetinnikov/CuteLauncher-Releases).
Documentation is available in Russian and English. Language links appear at
the top of each page.

## License and attribution

CuteLauncher is based on LTvLauncher/FLauncher and distributed under
[GNU GPLv3](LICENSE). See [project origins and licenses](docs/README_EN.md#происхождение-и-лицензии)
for the original projects, authors, and licenses covering libraries and assets.
