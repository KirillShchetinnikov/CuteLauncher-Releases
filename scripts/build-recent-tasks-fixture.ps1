param(
    [string]$Sdk = "$env:LOCALAPPDATA/Android/Sdk",
    [string]$JavaHome = $env:JAVA_HOME
)
$ErrorActionPreference = 'Stop'
if (-not $JavaHome) { throw 'Specify -JavaHome (JDK 21).' }
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.local/recent-task-fixture'
$tools = Join-Path $Sdk 'build-tools/36.0.0'
$androidJar = Join-Path $Sdk 'platforms/android-36/android.jar'
New-Item -ItemType Directory -Force "$output/classes","$output/dex" | Out-Null
$previousJava = $env:JAVA_HOME
$env:JAVA_HOME = $JavaHome
try {
    & "$JavaHome/bin/javac.exe" -encoding UTF-8 --release 8 -classpath $androidJar -d "$output/classes" "$root/test/android_fixture/RecentTasksFixture.java"
    if ($LASTEXITCODE) { throw 'Fixture compilation failed.' }
    & "$tools/d8.bat" --min-api 28 --lib $androidJar --output "$output/dex" "$output/classes/io/cutelauncher/fixture/recents/RecentTasksFixture.class"
    if ($LASTEXITCODE) { throw 'Fixture dex failed.' }
    & "$tools/aapt2.exe" link --manifest "$root/test/android_fixture/RecentTasksManifest.xml" -I $androidJar -o "$output/unsigned.apk"
    if ($LASTEXITCODE) { throw 'Fixture packaging failed.' }
    & "$JavaHome/bin/jar.exe" uf "$output/unsigned.apk" -C "$output/dex" classes.dex
    if ($LASTEXITCODE) { throw 'Fixture dex packaging failed.' }
    & "$tools/zipalign.exe" -f 4 "$output/unsigned.apk" "$output/fixture.apk"
    if ($LASTEXITCODE) { throw 'Fixture alignment failed.' }
    $key = Join-Path $output 'fixture.keystore'
    if (-not (Test-Path -LiteralPath $key)) {
        & "$JavaHome/bin/keytool.exe" -genkeypair -keystore $key -storepass android -keypass android -alias fixture -keyalg RSA -validity 1000 -dname 'CN=CuteLauncher test fixture' -noprompt
        if ($LASTEXITCODE) { throw 'Fixture key generation failed.' }
    }
    & "$tools/apksigner.bat" sign --ks $key --ks-pass pass:android --key-pass pass:android "$output/fixture.apk"
    if ($LASTEXITCODE) { throw 'Fixture signing failed.' }
    Write-Output "$output/fixture.apk"
} finally { $env:JAVA_HOME = $previousJava }
