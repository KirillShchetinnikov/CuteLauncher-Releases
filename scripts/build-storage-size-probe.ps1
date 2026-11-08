param(
    [string]$Sdk = "$env:LOCALAPPDATA/Android/Sdk",
    [string]$JavaHome = $env:JAVA_HOME
)
$ErrorActionPreference = 'Stop'
if (-not $JavaHome) { throw 'Specify a JDK using -JavaHome.' }
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.local/storage-size-probe'
$tools = Join-Path $Sdk 'build-tools/36.0.0'
$androidJar = Join-Path $Sdk 'platforms/android-36/android.jar'
$classes = Join-Path $output 'classes'
$dex = Join-Path $output 'dex'
New-Item -ItemType Directory -Force $classes,$dex | Out-Null
. "$PSScriptRoot/release-signing.ps1"
Invoke-ReleaseSigning -JavaHome $JavaHome -Action {
    & "$JavaHome/bin/javac.exe" -encoding UTF-8 --release 17 -classpath $androidJar -d $classes `
        "$root/android/app/src/androidTest/java/com/leanbitlab/ltvL/StorageSizeProbe.java"
    if ($LASTEXITCODE) { throw 'Probe Java compilation failed.' }
    & "$tools/d8.bat" --min-api 28 --lib $androidJar --output $dex `
        "$classes/com/leanbitlab/ltvL/StorageSizeProbe.class"
    if ($LASTEXITCODE) { throw 'Probe DEX compilation failed.' }
    $unsigned = Join-Path $output 'unsigned.apk'
    $apk = Join-Path $output 'storage-size-probe.apk'
    & "$tools/aapt2.exe" link --manifest "$root/test/android_size_probe/AndroidManifest.xml" -I $androidJar -o $unsigned
    if ($LASTEXITCODE) { throw 'Probe packaging failed.' }
    & "$JavaHome/bin/jar.exe" uf $unsigned -C $dex classes.dex
    if ($LASTEXITCODE) { throw 'Probe DEX packaging failed.' }
    & "$tools/zipalign.exe" -f 4 $unsigned $apk
    if ($LASTEXITCODE) { throw 'Probe alignment failed.' }
    & "$tools/apksigner.bat" sign --ks $env:KEYSTORE_FILE --ks-pass env:KEYSTORE_PASSWORD `
        --key-pass env:KEY_PASSWORD --ks-key-alias $env:KEY_ALIAS $apk
    if ($LASTEXITCODE) { throw 'Probe signing failed.' }
    Write-Output $apk
}
