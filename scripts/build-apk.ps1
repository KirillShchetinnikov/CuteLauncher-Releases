param(
    [string]$Flutter = "$PSScriptRoot/../.tools/flutter-upgrade/bin/flutter.bat",
    [string]$JavaHome = $env:JAVA_HOME,
    [ValidateSet('release', 'profile')]
    [string]$Mode = 'release',
    [string[]]$DartDefine = @(),
    [string]$TargetPlatform = 'android-arm,android-arm64,android-x64',
    [int]$BuildNumber = 0,
    [string]$SplitDebugInfo = '',
    [switch]$NoSplitDebugInfo
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
$versionMatch = [regex]::Match((Get-Content -Raw (Join-Path $projectRoot 'pubspec.yaml')), '(?m)^version:\s*([^\s+]+)(?:\+(\d+))?\s*$')
if (-not $versionMatch.Success) { throw 'Missing app version in pubspec.yaml.' }
$appVersion = $versionMatch.Groups[1].Value
if (-not $JavaHome) { throw 'Set JAVA_HOME to a JDK 21 installation.' }
if ($NoSplitDebugInfo -and $SplitDebugInfo) { throw 'Do not combine NoSplitDebugInfo with SplitDebugInfo.' }
$appBuild = if ($BuildNumber -gt 0) { "$BuildNumber" } else { $versionMatch.Groups[2].Value }
if ($Mode -eq 'release' -and -not $NoSplitDebugInfo) {
    if (-not $SplitDebugInfo) {
        $runId = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $SplitDebugInfo = Join-Path $projectRoot "artifacts/symbols/$appVersion+$appBuild/$runId"
    }
    if ((Test-Path -LiteralPath $SplitDebugInfo) -and (Get-ChildItem -LiteralPath $SplitDebugInfo -Force | Select-Object -First 1)) {
        throw 'SplitDebugInfo must be empty: preserve symbols from previous builds.'
    }
}
. "$PSScriptRoot/release-signing.ps1"
Invoke-ReleaseSigning -JavaHome $JavaHome -CreateLocalKey -Action {
    $builtApks = @()
    $extraArguments = @($DartDefine | ForEach-Object { "--dart-define=$_" })
    if ($BuildNumber -gt 0) { $extraArguments += "--build-number=$BuildNumber" }
    if ($Mode -eq 'release' -and $SplitDebugInfo) { $extraArguments += "--split-debug-info=$SplitDebugInfo" }
    New-Item -ItemType Directory -Force artifacts | Out-Null
    if ($Mode -eq 'release') {
        $platformAbis = @{'android-arm' = 'armeabi-v7a'; 'android-arm64' = 'arm64-v8a'; 'android-x64' = 'x86_64'}
        $targets = @($TargetPlatform.Split(','))
        if (-not $targets.Count -or @($targets | Where-Object { -not $platformAbis.ContainsKey($_) }).Count) {
            throw 'TargetPlatform must contain android-arm, android-arm64 and/or android-x64.'
        }
        # Save the ARM artifacts before the x64 pass replaces Gradle outputs.
        $env:UNIVERSAL_ONLY = $null
        $armTargets = @($targets | Where-Object { $_ -ne 'android-x64' } | Select-Object -Unique)
        if ($armTargets.Count) {
            & $Flutter build apk --release "--target-platform=$($armTargets -join ',')" @extraArguments
            if ($LASTEXITCODE -ne 0) { throw 'ARM APK build failed.' }
            $armOutputs = @('universal') + @($armTargets | ForEach-Object { $platformAbis[$_] })
            foreach ($abi in $armOutputs) {
                $name = "CuteLauncher-$appVersion-$abi-release.apk"
                Copy-Item -LiteralPath "build/app/outputs/apk/release/$name" -Destination "artifacts/$name"
                $builtApks += Get-Item -LiteralPath "artifacts/$name"
            }
        }
        if ($targets -contains 'android-x64') {
            & $Flutter build apk --release --split-per-abi --target-platform=android-x64 @extraArguments
            if ($LASTEXITCODE -ne 0) { throw 'x64 APK build failed.' }
            $name = "CuteLauncher-$appVersion-x86_64-release.apk"
            Copy-Item -LiteralPath "build/app/outputs/apk/release/$name" -Destination "artifacts/$name"
            $builtApks += Get-Item -LiteralPath "artifacts/$name"
        }
        if ($SplitDebugInfo) {
            foreach ($target in ($targets | Select-Object -Unique)) {
                if (-not (Test-Path -LiteralPath "$SplitDebugInfo/app.$target.symbols" -PathType Leaf)) {
                    throw "Missing debug symbols for $target."
                }
            }
            $files = @($builtApks) + @(Get-ChildItem -LiteralPath $SplitDebugInfo -Filter '*.symbols' -File)
            $hashes = @($files | ForEach-Object {
                [ordered]@{ file = $_.Name; bytes = $_.Length; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
            })
            [ordered]@{
                version = "$appVersion+$appBuild"
                sourceCommit = (git rev-parse HEAD)
                files = $hashes
            } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$SplitDebugInfo/build.json" -Encoding utf8
            Write-Host "Dart debug symbols and APK hashes: $SplitDebugInfo"
        }
    } else {
        & $Flutter build apk --profile "--target-platform=$TargetPlatform" @extraArguments
        if ($LASTEXITCODE -ne 0) { throw 'Profile APK build failed.' }
        Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-profile.apk' `
            -Destination "artifacts/CuteLauncher-$appVersion-universal-profile.apk"
    }
}
