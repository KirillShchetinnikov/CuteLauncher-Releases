. "$PSScriptRoot/cutelauncher-vault.ps1"

function Invoke-ReleaseSigning {
    param([scriptblock]$Action, [string]$JavaHome, [switch]$CreateLocalKey)

    $signingDir = Join-Path (Split-Path $PSScriptRoot -Parent) '.local/signing'
    $vaultDirectory = Get-CuteLauncherVaultDirectory
    $vaultConfig = Join-Path $vaultDirectory 'cutelauncher.json'
    $vaultCredential = Join-Path $vaultDirectory 'cutelauncher-approle.dpapi'
    $settingsFile = Join-Path $signingDir 'signing.json'
    $keystoreFile = Join-Path $signingDir 'cutelauncher.p12'
    $temporaryFile = $null
    $previousEnvironment = @{}
    foreach ($name in 'KEYSTORE_FILE', 'KEYSTORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD', 'UNIVERSAL_ONLY') {
        $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
    }

    try {
        if ((Test-Path -LiteralPath $vaultConfig) -or (Test-Path -LiteralPath $vaultCredential)) {
            $signing = Get-CuteLauncherVaultSecrets -Name keystore_base64, keystore_password, key_password, key_alias
            [IO.Directory]::CreateDirectory($signingDir) | Out-Null
            $temporaryFile = Join-Path $signingDir "temporary-$([guid]::NewGuid()).p12"
            [IO.File]::WriteAllBytes($temporaryFile, [Convert]::FromBase64String($signing.keystore_base64))
            $env:KEYSTORE_FILE = $temporaryFile
            $env:KEYSTORE_PASSWORD = $signing.keystore_password
            $env:KEY_PASSWORD = $signing.key_password
            $env:KEY_ALIAS = $signing.key_alias
        } else {
            $hasSettings = Test-Path -LiteralPath $settingsFile -PathType Leaf
            $hasKeystore = Test-Path -LiteralPath $keystoreFile -PathType Leaf
            if (-not ($hasSettings -and $hasKeystore)) {
                $previousOfficialConfig = Test-Path -LiteralPath (Join-Path $signingDir 'bitwarden.json')
                if ($hasSettings -or $hasKeystore -or $previousOfficialConfig -or -not $CreateLocalKey) {
                    throw 'Restore the existing signing files or configure Vault before building.'
                }
                New-Item -ItemType Directory -Force $signingDir | Out-Null
                $randomBytes = New-Object byte[] 32
                [Security.Cryptography.RandomNumberGenerator]::Fill($randomBytes)
                $settings = @{alias = 'cutelauncher'; password = [Convert]::ToBase64String($randomBytes)}
                $env:KEYSTORE_PASSWORD = $settings.password
                & "$JavaHome/bin/keytool.exe" -genkeypair -keystore $keystoreFile -storetype PKCS12 `
                    -storepass:env KEYSTORE_PASSWORD -keypass:env KEYSTORE_PASSWORD `
                    -alias $settings.alias -keyalg RSA -keysize 3072 -validity 10000 `
                    -dname 'CN=CuteLauncher, OU=Personal Development' -noprompt
                if ($LASTEXITCODE -ne 0) { throw 'Failed to create signing key.' }
                $settings | ConvertTo-Json | Set-Content -Encoding utf8 -LiteralPath $settingsFile
            }
            $settings = Get-Content -Raw -LiteralPath $settingsFile | ConvertFrom-Json
            $env:KEYSTORE_FILE = $keystoreFile
            $env:KEYSTORE_PASSWORD = $settings.password
            $env:KEY_PASSWORD = $settings.password
            $env:KEY_ALIAS = $settings.alias
        }
        $env:JAVA_HOME = $JavaHome
        $env:UNIVERSAL_ONLY = 'true'
        & $Action
    } finally {
        foreach ($name in $previousEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name])
        }
        if ($temporaryFile -and (Test-Path -LiteralPath $temporaryFile)) {
            Remove-Item -LiteralPath $temporaryFile -Force
        }
    }
}
