param(
    [string]$FixturePng = "$PSScriptRoot/../test/fixtures/impeller_resize_320x180.png",
    [string]$Flutter = "$PSScriptRoot/../.tools/flutter-upgrade/bin/flutter.bat",
    [string]$JavaHome = $env:JAVA_HOME,
    [string]$AndroidSdk = "$env:LOCALAPPDATA/Android/Sdk",
    [ValidateSet('android-arm', 'android-arm64', 'android-x64')]
    [string]$TargetPlatform = 'android-arm'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$fixturePath = (Resolve-Path -LiteralPath $FixturePng).Path
$flutterPath = (Resolve-Path -LiteralPath $Flutter).Path
$flutterRoot = Split-Path (Split-Path $flutterPath -Parent) -Parent
if (-not $JavaHome) { throw 'Set JAVA_HOME to JDK 21 or pass -JavaHome.' }
$probeRoot = Join-Path $projectRoot '.local/impeller-image-probe'
foreach ($directory in @('lib', 'assets', 'android/gradle/wrapper',
    'android/app/src/main/java/com/leanbitlab/ltvL')) {
    New-Item -ItemType Directory -Force (Join-Path $probeRoot $directory) | Out-Null
}

# Build a separate Flutter-only host. Never edit the launcher's build files,
# use its signing key, install an APK or change HOME from this script.
Copy-Item -LiteralPath $fixturePath -Destination (Join-Path $probeRoot 'assets/fixture.png')
Copy-Item -LiteralPath (Join-Path $projectRoot 'test/device/impeller_image_probe.dart') `
    -Destination (Join-Path $probeRoot 'lib/main.dart')
foreach ($file in @('settings.gradle', 'build.gradle', 'gradle.properties',
    'gradlew', 'gradlew.bat', 'gradle/wrapper/gradle-wrapper.jar',
    'gradle/wrapper/gradle-wrapper.properties')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot "android/$file") `
        -Destination (Join-Path $probeRoot "android/$file")
}
@'
name: impeller_image_probe
publish_to: none
version: 1.0.0+1
environment:
  sdk: '>=3.13.5 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
flutter:
  assets:
    - assets/fixture.png
'@ | Set-Content -Encoding utf8 (Join-Path $probeRoot 'pubspec.yaml')
"sdk.dir=$($AndroidSdk.Replace('\', '/'))`nflutter.sdk=$($flutterRoot.Replace('\', '/'))" |
    Set-Content -Encoding utf8 (Join-Path $probeRoot 'android/local.properties')
@'
plugins {
    id 'com.android.application'
    id 'dev.flutter.flutter-gradle-plugin'
}
android {
    namespace 'com.leanbitlab.ltvL'
    compileSdk 36
    ndkVersion '28.2.13676358'
    defaultConfig {
        applicationId 'io.github.kirillshchetinnikov.impellerimageprobe'
        minSdk 31
        targetSdk 35
        versionCode 1
        versionName '1.0.0'
    }
    buildTypes {
        release { signingConfig signingConfigs.debug }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_21
        targetCompatibility JavaVersion.VERSION_21
    }
}
flutter { source '../..' }
'@ | Set-Content -Encoding utf8 (Join-Path $probeRoot 'android/app/build.gradle')
@'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="Impeller image probe" android:hardwareAccelerated="true">
        <activity android:name="com.leanbitlab.ltvL.MainActivity"
            android:exported="true" android:theme="@android:style/Theme.Black.NoTitleBar"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2" />
        <meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="true" />
    </application>
</manifest>
'@ | Set-Content -Encoding utf8 (Join-Path $probeRoot 'android/app/src/main/AndroidManifest.xml')
@'
package com.leanbitlab.ltvL;
public final class MainActivity extends io.flutter.embedding.android.FlutterActivity {}
'@ | Set-Content -Encoding utf8 (Join-Path $probeRoot 'android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java')

$previousJavaHome = $env:JAVA_HOME
Push-Location $probeRoot
try {
    $env:JAVA_HOME = $JavaHome
    & $flutterPath pub get --offline
    if ($LASTEXITCODE -ne 0) { throw 'Probe dependency resolution failed.' }
    & $flutterPath build apk --release --no-pub "--target-platform=$TargetPlatform"
    if ($LASTEXITCODE -ne 0) { throw 'Probe build failed.' }
    Write-Output "APK: $probeRoot/build/app/outputs/flutter-apk/app-release.apk"
} finally {
    Pop-Location
    $env:JAVA_HOME = $previousJavaHome
}
