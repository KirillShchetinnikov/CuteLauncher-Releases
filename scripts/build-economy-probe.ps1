param(
    [Parameter(Mandatory = $true)][int]$BuildNumber,
    [string]$JavaHome = $env:JAVA_HOME,
    [switch]$AllowTcl
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
if (Test-Path -LiteralPath ".local/economy-probe/probe-$BuildNumber.apk") { throw 'Probe APK already exists; choose a new build number.' }
if (-not $JavaHome) { throw 'Set JAVA_HOME to JDK 21.' }
$settings = Get-Content -Raw '.local/signing/signing.json' | ConvertFrom-Json
$env:KEYSTORE_FILE = Join-Path $projectRoot '.local/signing/cutelauncher.p12'
$env:KEYSTORE_PASSWORD = $settings.password
$env:KEY_ALIAS = $settings.alias
$env:KEY_PASSWORD = $settings.password
$env:JAVA_HOME = $JavaHome
$env:UNIVERSAL_ONLY = 'true'
try {
    & '.tools/flutter-upgrade/bin/flutter.bat' build apk --release `
        --target-platform=android-arm,android-arm64,android-x64 `
        --target=test/device/economy_probe.dart "--build-number=$BuildNumber" `
        --dart-define=CUTE_PERFORMANCE_PROBE=true "--dart-define=ALLOW_TCL_PROBE=$($AllowTcl.IsPresent.ToString().ToLowerInvariant())"
    if ($LASTEXITCODE -ne 0) { throw 'Economy probe build failed.' }
    New-Item -ItemType Directory -Force '.local/economy-probe' | Out-Null
    Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk' `
        -Destination ".local/economy-probe/probe-$BuildNumber.apk"
} finally {
    Remove-Item Env:KEYSTORE_FILE,Env:KEYSTORE_PASSWORD,Env:KEY_ALIAS,Env:KEY_PASSWORD,Env:UNIVERSAL_ONLY -ErrorAction SilentlyContinue
}
