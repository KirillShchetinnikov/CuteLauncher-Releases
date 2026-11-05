param(
    [string]$Flutter = "$PSScriptRoot/../.tools/flutter-upgrade/bin/flutter.bat",
    [string]$JavaHome = $env:JAVA_HOME,
    [ValidateSet('release', 'profile')]
    [string]$Mode = 'release',
    [string[]]$DartDefine = @(),
    [string]$TargetPlatform = 'android-arm,android-arm64,android-x64',
    [int]$BuildNumber = 0
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
$versionMatch = [regex]::Match((Get-Content -Raw (Join-Path $projectRoot 'pubspec.yaml')), '(?m)^version:\s*([^\s+]+)(?:\+\d+)?\s*$')
if (-not $versionMatch.Success) { throw 'Missing app version in pubspec.yaml.' }
$appVersion = $versionMatch.Groups[1].Value
if (-not $JavaHome) { throw 'Set JAVA_HOME to a JDK 21 installation.' }
. "$PSScriptRoot/release-signing.ps1"
Invoke-ReleaseSigning -JavaHome $JavaHome -CreateLocalKey -Action {
    $extraArguments = @($DartDefine | ForEach-Object { "--dart-define=$_" })
    if ($BuildNumber -gt 0) { $extraArguments += "--build-number=$BuildNumber" }
    & $Flutter build apk "--$Mode" "--target-platform=$TargetPlatform" @extraArguments
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
    New-Item -ItemType Directory -Force artifacts | Out-Null
    Copy-Item -LiteralPath "build/app/outputs/flutter-apk/app-$Mode.apk" `
        -Destination "artifacts/CuteLauncher-$appVersion-universal-$Mode.apk"
}
