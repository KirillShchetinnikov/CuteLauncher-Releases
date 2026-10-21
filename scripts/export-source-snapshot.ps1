param(
    [string]$Ref = 'HEAD'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$resolvedCommit = & git -C $projectRoot rev-parse --verify --end-of-options "$Ref^{commit}" 2>$null
if ($LASTEXITCODE -ne 0 -or -not $resolvedCommit) {
    throw 'Ref must resolve to an existing commit.'
}
$commit = ([string]$resolvedCommit).Trim()
if ($commit -notmatch '^[0-9a-f]{40}$') { throw 'Invalid resolved commit.' }
if ($Ref -eq 'HEAD') {
    $dirty = & git -C $projectRoot status --porcelain
    if ($LASTEXITCODE -ne 0 -or $dirty) {
        throw 'Commit the working tree before exporting HEAD, or select an explicit existing commit/tag.'
    }
}
$spec = (& git -C $projectRoot show "${commit}:pubspec.yaml") -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'Cannot read committed pubspec.yaml.' }
$versionMatch = [regex]::Match($spec, '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+(?:-test\.[0-9]+)?\+[0-9]+)\s*$')
if (-not $versionMatch.Success) { throw 'Unsupported committed app version.' }
$version = $versionMatch.Groups[1].Value
$files = @(& git -C $projectRoot -c core.quotepath=false ls-tree -r --name-only $commit)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect committed source tree.' }
foreach ($file in $files) {
    if ($file -match '(^|/)(\.local|\.tools|\.dart_tool|\.git|\.codex|\.agents|\.aws|build|artifacts)(/|$)' -or
        $file -match '(?i)(\.(p12|pfx|jks|keystore|pem)$|(^|/)(local\.properties|key\.properties|signing\.json|adbkey|id_rsa|id_ed25519)$|(^|/)\.env$)') {
        throw "Private/build-only path is tracked: $file"
    }
}
foreach ($required in @('LICENSE', 'README.md', 'pubspec.yaml', 'pubspec.lock',
        'lib/main.dart', 'android/app/build.gradle', 'scripts/build-apk.ps1',
        'docs/USER_GUIDE_RU.md')) {
    if ($files -notcontains $required) { throw "Missing source/build file: $required" }
}

$outputDirectory = Join-Path $projectRoot 'artifacts/source'
[void][IO.Directory]::CreateDirectory($outputDirectory)
$name = "CuteLauncher-$version-$($commit.Substring(0,12))-source-snapshot"
$archivePath = Join-Path $outputDirectory "$name.zip"
$partialPath = "$archivePath.partial"
$manifestPath = Join-Path $outputDirectory "$name.json"
foreach ($target in @($archivePath, $partialPath, $manifestPath)) {
    if (Test-Path -LiteralPath $target) { throw "Output already exists; snapshots are never overwritten: $target" }
}
try {
    & git -C $projectRoot archive --format=zip "--prefix=$name/" "--output=$partialPath" $commit
    if ($LASTEXITCODE -ne 0) { throw 'Source archive failed.' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($partialPath)
    try {
        $entries = @($zip.Entries | Where-Object { -not $_.FullName.EndsWith('/') } |
            ForEach-Object { $_.FullName.Substring($name.Length + 1) })
        $difference = @(Compare-Object ($files | Sort-Object) ($entries | Sort-Object))
        if ($difference.Count -ne 0) { throw 'Archive differs from the inspected committed tree.' }
    } finally { $zip.Dispose() }
    [IO.File]::Move($partialPath, $archivePath)
    $manifest = [ordered]@{
        kind = 'project-source-snapshot'
        completeCorrespondingSource = $false
        commit = $commit
        version = $version
        archive = [IO.Path]::GetFileName($archivePath)
        sha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        files = $files.Count
        limitation = 'Project source only. SDK and dependency corresponding sources must be collected and verified separately before distribution.'
    }
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json) + "`n")
    Write-Output "Local source snapshot: $archivePath"
    Write-Output "Manifest: $manifestPath"
} finally {
    if (Test-Path -LiteralPath $partialPath) { Remove-Item -LiteralPath $partialPath }
}
