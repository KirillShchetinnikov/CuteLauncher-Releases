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
$signingDir = Join-Path $projectRoot '.local/signing'
$settingsFile = Join-Path $signingDir 'signing.json'
$keystoreFile = Join-Path $signingDir 'cutelauncher.p12'
New-Item -ItemType Directory -Force $signingDir | Out-Null

# Keep this directory for subsequent APK updates. Never commit signing secrets.
if (-not (Test-Path -LiteralPath $settingsFile)) {
    if (Test-Path -LiteralPath $keystoreFile) {
        throw 'Keystore exists without signing.json. Restore its credentials before continuing.'
    }
    $randomBytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($randomBytes)
    $settings = [pscustomobject]@{
        alias = 'cutelauncher'
        password = [Convert]::ToBase64String($randomBytes)
    }
    $env:CUTELAUNCHER_KEY_PASSWORD = $settings.password
    & "$JavaHome/bin/keytool.exe" -genkeypair -keystore $keystoreFile -storetype PKCS12 `
        -storepass:env CUTELAUNCHER_KEY_PASSWORD -keypass:env CUTELAUNCHER_KEY_PASSWORD `
        -alias $settings.alias -keyalg RSA -keysize 3072 -validity 10000 `
        -dname 'CN=CuteLauncher, OU=Personal Development' -noprompt
    if ($LASTEXITCODE -ne 0) { throw 'Failed to create signing key.' }
    $settings | ConvertTo-Json | Set-Content -Encoding utf8 $settingsFile
    Remove-Item Env:CUTELAUNCHER_KEY_PASSWORD
}

$settings = Get-Content -Raw $settingsFile | ConvertFrom-Json
$env:KEYSTORE_FILE = $keystoreFile
$env:KEYSTORE_PASSWORD = $settings.password
$env:KEY_ALIAS = $settings.alias
$env:KEY_PASSWORD = $settings.password
$env:JAVA_HOME = $JavaHome
$env:UNIVERSAL_ONLY = 'true'
try {
    $extraArguments = @($DartDefine | ForEach-Object { "--dart-define=$_" })
    if ($BuildNumber -gt 0) { $extraArguments += "--build-number=$BuildNumber" }
    & $Flutter build apk "--$Mode" "--target-platform=$TargetPlatform" @extraArguments
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
    New-Item -ItemType Directory -Force artifacts | Out-Null
    Copy-Item -LiteralPath "build/app/outputs/flutter-apk/app-$Mode.apk" `
        -Destination "artifacts/CuteLauncher-$appVersion-universal-$Mode.apk"
} finally {
    Remove-Item Env:KEYSTORE_FILE,Env:KEYSTORE_PASSWORD,Env:KEY_ALIAS,Env:KEY_PASSWORD,Env:UNIVERSAL_ONLY -ErrorAction SilentlyContinue
}
