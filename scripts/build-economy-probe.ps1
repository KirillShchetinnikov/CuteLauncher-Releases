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
. "$PSScriptRoot/release-signing.ps1"
Invoke-ReleaseSigning -JavaHome $JavaHome -Action {
    & '.tools/flutter-upgrade/bin/flutter.bat' build apk --release `
        --target-platform=android-arm,android-arm64,android-x64 `
        --target=test/device/economy_probe.dart "--build-number=$BuildNumber" `
        --dart-define=CUTE_PERFORMANCE_PROBE=true "--dart-define=ALLOW_TCL_PROBE=$($AllowTcl.IsPresent.ToString().ToLowerInvariant())"
    if ($LASTEXITCODE -ne 0) { throw 'Economy probe build failed.' }
    New-Item -ItemType Directory -Force '.local/economy-probe' | Out-Null
    Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk' `
        -Destination ".local/economy-probe/probe-$BuildNumber.apk"
}
