param([string]$JavaHome = $env:JAVA_HOME)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
if (-not $JavaHome) { throw 'Specify a JDK 21 installation.' }
$settings = Get-Content -Raw '.local/signing/signing.json' | ConvertFrom-Json
$env:KEYSTORE_FILE = Join-Path $projectRoot '.local/signing/cutelauncher.p12'
$env:KEYSTORE_PASSWORD = $settings.password
$env:KEY_PASSWORD = $settings.password
$env:KEY_ALIAS = $settings.alias
$env:JAVA_HOME = $JavaHome
$env:UNIVERSAL_ONLY = 'true'
try {
    & '.tools/flutter-upgrade/bin/flutter.bat' build apk --no-pub --release `
        --target=test/device/release_runtime_probe.dart `
        --target-platform=android-arm,android-arm64,android-x64
    if ($LASTEXITCODE) { throw 'Release runtime probe build failed.' }
    New-Item -ItemType Directory -Force '.local/device-probes' | Out-Null
    Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk' `
        -Destination '.local/device-probes/release-runtime.apk'
    & "$PSScriptRoot/build-device-probe.ps1" -Runner com.leanbitlab.ltvL.ReleaseRuntimeProbe -JavaHome $JavaHome
} finally {
    Remove-Item Env:KEYSTORE_FILE,Env:KEYSTORE_PASSWORD,Env:KEY_PASSWORD,Env:KEY_ALIAS,Env:UNIVERSAL_ONLY -ErrorAction SilentlyContinue
}
