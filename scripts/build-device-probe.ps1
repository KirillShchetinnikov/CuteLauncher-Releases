param(
    [string]$Runner = 'com.leanbitlab.ltvL.NightModeScheduleProbe',
    [string]$JavaHome = $env:JAVA_HOME
)
$ErrorActionPreference = 'Stop'
if ($Runner -notmatch '^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+$') { throw 'Invalid runner class.' }
if (-not $JavaHome) { throw 'Specify -JavaHome (JDK 21).' }
$root = Split-Path $PSScriptRoot -Parent
$runnerSource = Join-Path $root ("android/app/src/androidTest/java/" + $Runner.Replace('.', '/') + '.java')
if (-not (Test-Path -LiteralPath $runnerSource)) { throw "Runner source not found: $Runner" }
$signing = Get-Content -Raw "$root/.local/signing/signing.json" | ConvertFrom-Json
$env:JAVA_HOME = $JavaHome
$env:KEYSTORE_FILE = "$root/.local/signing/cutelauncher.p12"
$env:KEYSTORE_PASSWORD = $signing.password
$env:KEY_PASSWORD = $signing.password
$env:KEY_ALIAS = $signing.alias
$env:UNIVERSAL_ONLY = 'true'
Push-Location "$root/android"
try {
    & ./gradlew.bat ':app:assembleReleaseAndroidTest' '-Ptv-instrumentation' "-Ptv-probe-runner=$Runner" '-Ptarget-platform=android-arm,android-arm64,android-x64'
    if ($LASTEXITCODE) { throw 'Device probe build failed.' }
    $destination = "$root/.local/device-probes"
    New-Item -ItemType Directory -Force $destination | Out-Null
    Copy-Item -LiteralPath "$root/build/app/outputs/apk/androidTest/release/app-release-androidTest.apk" -Destination "$destination/$($Runner.Split('.')[-1]).apk"
    Write-Output "$destination/$($Runner.Split('.')[-1]).apk"
} finally {
    Pop-Location
    Remove-Item Env:KEYSTORE_FILE,Env:KEYSTORE_PASSWORD,Env:KEY_PASSWORD,Env:KEY_ALIAS,Env:UNIVERSAL_ONLY -ErrorAction SilentlyContinue
}
