param([string]$JavaHome = $env:JAVA_HOME)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
if (-not $JavaHome) { throw 'Specify a JDK 21 installation.' }
. "$PSScriptRoot/release-signing.ps1"
Invoke-ReleaseSigning -JavaHome $JavaHome -Action {
    & '.tools/flutter-upgrade/bin/flutter.bat' build apk --no-pub --release `
        --target=test/device/release_runtime_probe.dart `
        --target-platform=android-arm,android-arm64,android-x64
    if ($LASTEXITCODE) { throw 'Release runtime probe build failed.' }
    New-Item -ItemType Directory -Force '.local/device-probes' | Out-Null
    Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk' `
        -Destination '.local/device-probes/release-runtime.apk'
}
& "$PSScriptRoot/build-device-probe.ps1" -Runner com.leanbitlab.ltvL.ReleaseRuntimeProbe -JavaHome $JavaHome
