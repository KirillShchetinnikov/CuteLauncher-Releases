function Get-BitwardenSigning($Configuration) {
    $bws = (Get-Command bws -CommandType Application -ErrorAction SilentlyContinue).Source
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if (-not $bws) { $bws = Join-Path $localAppData 'Programs/Bitwarden/bws.exe' }
    if (-not (Test-Path -LiteralPath $bws -PathType Leaf)) { throw 'Install the Bitwarden Secrets Manager CLI (bws).' }

    $projectId = ([guid]$Configuration.projectId).ToString()
    $tokenFile = Join-Path $localAppData "CodexBitwarden/$projectId.dpapi"
    if (-not (Test-Path -LiteralPath $tokenFile -PathType Leaf)) { throw 'Save the Bitwarden machine-account token in your Windows profile first.' }
    $token = ConvertTo-SecureString -String (Get-Content -Raw -LiteralPath $tokenFile).Trim()
    $previousToken = $env:BWS_ACCESS_TOKEN
    $values = @{}
    try {
        $credential = [pscredential]::new('bws', $token)
        $env:BWS_ACCESS_TOKEN = $credential.GetNetworkCredential().Password
        foreach ($name in 'KEYSTORE_BASE64', 'KEYSTORE_PASSWORD', 'KEY_PASSWORD', 'KEY_ALIAS') {
            $recordName = "CUTELAUNCHER_$name"
            $secretId = ([guid]$Configuration.secretIds.$name).ToString()
            $result = & $bws secret get $secretId --output json 2>$null
            if ($LASTEXITCODE -ne 0) { throw "Bitwarden could not read $name." }
            try { $secret = ($result -join "`n") | ConvertFrom-Json -ErrorAction Stop }
            catch { throw "Invalid Bitwarden response for $name." }
            if ($secret.key -cne $recordName -or $secret.projectId -ne $projectId -or -not $secret.value) {
                throw "Expected Bitwarden record $recordName."
            }
            $values[$name] = $secret.value
        }
    } finally {
        $env:BWS_ACCESS_TOKEN = $previousToken
        $token.Dispose()
    }
    return $values
}

function Invoke-ReleaseSigning {
    param([scriptblock]$Action, [string]$JavaHome, [switch]$CreateLocalKey)

    $signingDir = Join-Path (Split-Path $PSScriptRoot -Parent) '.local/signing'
    $configurationFile = Join-Path $signingDir 'bitwarden.json'
    $settingsFile = Join-Path $signingDir 'signing.json'
    $keystoreFile = Join-Path $signingDir 'cutelauncher.p12'
    $temporaryFile = $null
    $previousEnvironment = @{}
    foreach ($name in 'KEYSTORE_FILE', 'KEYSTORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD', 'UNIVERSAL_ONLY') {
        $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
    }

    try {
        if (Test-Path -LiteralPath $configurationFile) {
            $configuration = Get-Content -Raw -LiteralPath $configurationFile | ConvertFrom-Json
            $signing = Get-BitwardenSigning $configuration
            $temporaryFile = Join-Path $signingDir "temporary-$([guid]::NewGuid()).p12"
            [IO.File]::WriteAllBytes($temporaryFile, [Convert]::FromBase64String($signing.KEYSTORE_BASE64))
            $env:KEYSTORE_FILE = $temporaryFile
            $env:KEYSTORE_PASSWORD = $signing.KEYSTORE_PASSWORD
            $env:KEY_PASSWORD = $signing.KEY_PASSWORD
            $env:KEY_ALIAS = $signing.KEY_ALIAS
        } else {
            $hasSettings = Test-Path -LiteralPath $settingsFile -PathType Leaf
            $hasKeystore = Test-Path -LiteralPath $keystoreFile -PathType Leaf
            if (-not ($hasSettings -and $hasKeystore)) {
                if ($hasSettings -or $hasKeystore -or -not $CreateLocalKey) {
                    throw 'Restore the existing signing files or configure Bitwarden before building.'
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
