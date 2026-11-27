function Get-CuteLauncherVaultDirectory {
    Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CodexVault'
}

function Invoke-CuteLauncherVaultRequest($Context, $Path, $Method = 'Get', $Body) {
    $request = @{
        Uri = "$($Context.Address)/v1/$Path"
        Method = $Method
        Headers = $Context.Headers
        TimeoutSec = 15
        MaximumRedirection = 0
        ErrorAction = 'Stop'
        Debug = $false
        Verbose = $false
    }
    if ($null -ne $Body) {
        $request.ContentType = 'application/json'
        $request.Body = ConvertTo-Json -InputObject $Body -Depth 8 -Compress
    }
    try {
        Invoke-RestMethod @request
    } catch {
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
            throw "Vault ${Method} ${Path}: HTTP $status."
        }
        throw "Vault ${Method} ${Path}: connection failed."
    }
}

function Connect-CuteLauncherVault {
    $directory = Get-CuteLauncherVaultDirectory
    try {
        $config = Get-Content -Raw -LiteralPath (Join-Path $directory 'cutelauncher.json') -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop
        $address = [uri]$config.address
        $roleId = ([guid]$config.roleId).ToString()
        if (-not $address.IsAbsoluteUri -or $address.Scheme -ne 'https' -or
            $address.UserInfo -or $address.Query -or $address.Fragment -or $address.AbsolutePath -ne '/') {
            throw 'Expected an HTTPS origin.'
        }
        $encrypted = [IO.File]::ReadAllText((Join-Path $directory 'cutelauncher-approle.dpapi')).Trim()
        $secretId = ConvertTo-SecureString -String $encrypted -ErrorAction Stop
    } catch {
        throw 'Configure the CuteLauncher Vault address, RoleID and Windows DPAPI credential first.'
    }

    $context = @{ Address = $address.GetLeftPart([UriPartial]::Authority); Headers = @{} }
    try {
        $credentials = [pscredential]::new('vault-approle', $secretId)
        $session = Invoke-CuteLauncherVaultRequest $context 'auth/approle/login' -Method Post -Body @{
            role_id = $roleId
            secret_id = $credentials.GetNetworkCredential().Password
        }
    } finally {
        $secretId.Dispose()
    }
    if (-not $session.auth.client_token) { throw 'Vault did not issue an AppRole token.' }
    $context.Headers['X-Vault-Token'] = $session.auth.client_token
    return $context
}

function Get-CuteLauncherVaultSecrets {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('4pda_login', '4pda_password', '4pda_session', 'keystore_base64',
            'keystore_password', 'key_alias', 'key_password')]
        [string[]]$Name
    )
    $context = Connect-CuteLauncherVault
    $values = @{}
    foreach ($key in $Name) {
        $record = Invoke-CuteLauncherVaultRequest $context "cutelauncher/data/$key"
        $value = $record.data.data.value
        if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) {
            throw "Vault record $key has no value."
        }
        $values[$key] = $value
    }
    return $values
}

function Set-CuteLauncherVaultForumSession {
    param([Parameter(Mandatory)][string]$Value)

    try {
        $session = ConvertFrom-Json -InputObject $Value -ErrorAction Stop
    } catch {
        throw 'Expected a JSON 4PDA session.'
    }
    if (-not $session.cookies.Count) { throw 'The 4PDA session has no cookies.' }
    $context = Connect-CuteLauncherVault
    $path = 'cutelauncher/data/4pda_session'
    $record = Invoke-CuteLauncherVaultRequest $context $path
    $version = $record.data.metadata.version
    if ($version -lt 1) { throw 'Vault did not return the current 4PDA session version.' }
    $result = Invoke-CuteLauncherVaultRequest $context $path -Method Post -Body @{
        options = @{ cas = $version }
        data = @{ value = $Value }
    }
    $savedVersion = $result.data.version
    if ($savedVersion -le $version) { throw 'Vault did not confirm writing the 4PDA session.' }
    $verified = Invoke-CuteLauncherVaultRequest $context "${path}?version=$savedVersion"
    if ($verified.data.data.value -cne $Value) { throw 'Vault did not return the saved 4PDA session.' }
}
