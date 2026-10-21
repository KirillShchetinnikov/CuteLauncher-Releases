# CuteLauncher documentation

[Русский](README.md) · [English](README_EN.md) · [About the launcher](../README_EN.md)

## User guide

The [feature guide](USER_GUIDE_EN.md) covers remote navigation, the home screen,
appearance, apps, wallpapers, widgets, night mode, TV controls, backups, updates,
and diagnostics. It includes settings paths, required permissions, and the
limitations of individual features.

## Downloads and installation

Download APKs from the [latest release](https://github.com/KirillShchetinnikov/CuteLauncher-Releases/releases/latest).
Choose ARMv7, ARM64, or x86_64 for your device, or universal if you do not know
its architecture. Android may ask you to allow installation from your chosen
source. Use an APK with the same signing identity when updating, and do not
uninstall the app if you want to preserve your settings.

The declared platform is Android 11 and later; running on Android 11 has not
yet been confirmed. System features depend on firmware and permissions.
See the [guide](USER_GUIDE_EN.md#разрешения-и-ограничения) for details.

## Permissions, reports, and help

Additional access is needed only for the corresponding features. Grant it as
you configure those features. Start with the [permission table](USER_GUIDE_EN.md#разрешения-и-ограничения).
The [diagnostics section](USER_GUIDE_EN.md#диагностика) explains report collection
and export. Reports are never sent automatically. When reporting an issue,
include your CuteLauncher version, TV model, Android version, firmware, and
steps to reproduce it. Do not publish personal keys or private webhook URLs.

<a id="происхождение-и-лицензии"></a>
## Origins and licenses

CuteLauncher is developed by [Kirill Shchetinnikov](https://github.com/KirillShchetinnikov).
Source code and APKs are available in [CuteLauncher-Releases](https://github.com/KirillShchetinnikov/CuteLauncher-Releases).
CuteLauncher is a fork of [LTvLauncher](https://github.com/leanbitlab-org/LtvLauncher),
based on [FLauncher](https://gitlab.com/flauncher/flauncher) by Étienne Fesser
and [osrosal's fork](https://github.com/osrosal/flauncher).

[GNU GPLv3](../LICENSE), original GPLv3-or-later headers, and author notices are
preserved. Distributed modified builds require complete corresponding source,
including modifications and necessary build scripts; signing keys and personal
secrets are excluded. Public project snapshots have their own history. The full
SDK and dependency source collection is not yet declared complete.

The bundled dadb library uses [Apache 2.0](DADB_LICENSE.txt).
[Android runtime notices](../assets/licenses/android_runtime.txt) and
[TLS notices for earlier builds](../assets/licenses/adb_tls.txt) are preserved
in the APK and license screen. Flutter NOTICES includes project, Flutter/engine,
and Dart-package licenses. Bundled font licenses are in [assets/fonts](../assets/fonts).
The test-only DejaVu Sans is distributed with its [license](../test/design/fonts/LICENSE_DEJAVU)
and is not included in the APK. Legal texts remain in their original language.
