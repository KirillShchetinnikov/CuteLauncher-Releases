param(
    [string]$Flutter = "$PSScriptRoot/../.tools/flutter-upgrade/bin/flutter.bat",
    [switch]$Update,
    [string]$Reason
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
if (-not $IsWindows -and $env:OS -ne 'Windows_NT') {
    throw 'Design goldens use the Windows x64 reference renderer.'
}
if ($Update -and [string]::IsNullOrWhiteSpace($Reason)) {
    throw 'Specify -Reason and inspect the image diff before committing updated goldens.'
}
$version = & $Flutter --version --machine | ConvertFrom-Json
if ($version.frameworkRevision -ne 'c197ca5199e9ee5661e865596c9c07294dfab51c') {
    throw 'Use the pinned Flutter 3.47.9 revision for design goldens.'
}
$testArgs = @('test', 'test/design/design_goldens_test.dart', '--no-pub')
if ($Update) { $testArgs += '--update-goldens' }
& $Flutter @testArgs
if ($LASTEXITCODE -ne 0) { throw 'Design golden checks failed. Inspect test/design/failures.' }
if ($Update) {
    & "$PSScriptRoot/update-design-gallery.ps1"
    Add-Content -Encoding utf8 test/design/UPDATES.md "`n- $(Get-Date -Format yyyy-MM-dd): $Reason"
    Write-Output 'Review docs/design-gallery.html and git diff before committing the new images.'
}
