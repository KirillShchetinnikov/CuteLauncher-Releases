$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent

function Save-ResizedImage($Source, $Target, [int]$Width, [int]$Height, [int]$Inset = 0) {
    $image = [System.Drawing.Image]::FromFile((Join-Path $projectRoot $Source))
    $bitmap = [System.Drawing.Bitmap]::new($Width, $Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.DrawImage($image, $Inset, $Inset, ($Width - 2 * $Inset), ($Height - 2 * $Inset))
        $bitmap.Save((Join-Path $projectRoot $Target), [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
        $image.Dispose()
    }
}

$icon = 'docs/images/concepts/cutelauncher-icon-selected.png'
$banner = 'docs/images/concepts/cutelauncher-tv-banner-selected.png'
# Public snapshots keep app assets, while private concept sources stay private.
if (Test-Path -LiteralPath (Join-Path $projectRoot $icon)) {
    Save-ResizedImage $icon 'assets/icon.png' 1024 1024
} else {
    $icon = 'assets/icon.png'
}
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $banner))) {
    $banner = 'assets/banner.png'
}
# Android's 108 dp adaptive layer: keep the complete artwork in the central 66 dp.
Save-ResizedImage $icon 'assets/icon-foreground.png' 1080 1080 210
if ($banner -ne 'assets/banner.png') {
    Copy-Item -LiteralPath (Join-Path $projectRoot $banner) -Destination (Join-Path $projectRoot 'assets/banner.png')
}
$resourceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'android/app/src/main/res'))
New-Item -ItemType Directory -Force (Join-Path $resourceRoot 'drawable-nodpi') | Out-Null
Save-ResizedImage $banner 'android/app/src/main/res/drawable-nodpi/banner.png' 320 180
foreach ($oldBanner in @('drawable/banner.png', 'drawable-xhdpi/banner.png')) {
    $oldPath = Join-Path $resourceRoot $oldBanner
    if (Test-Path -LiteralPath $oldPath) { Remove-Item -LiteralPath $oldPath }
}

Push-Location $projectRoot
try {
    & "$projectRoot/.tools/flutter-upgrade/bin/dart.bat" run flutter_launcher_icons
    if ($LASTEXITCODE -ne 0) { throw 'Launcher icon generation failed.' }
    # Adaptive icons are available throughout minSdk 28; normalize the generator's v26 folder.
    $generatedIcon = [IO.Path]::GetFullPath((Join-Path $resourceRoot 'mipmap-anydpi-v26/ic_launcher.xml'))
    $currentIcon = [IO.Path]::GetFullPath((Join-Path $resourceRoot 'mipmap-anydpi/ic_launcher.xml'))
    foreach ($iconPath in @($generatedIcon, $currentIcon)) {
        if (-not $iconPath.StartsWith($resourceRoot + [IO.Path]::DirectorySeparatorChar,
                [StringComparison]::OrdinalIgnoreCase)) { throw 'Icon path outside Android resources.' }
    }
    if (Test-Path -LiteralPath $generatedIcon) {
        New-Item -ItemType Directory -Force (Split-Path $currentIcon -Parent) | Out-Null
        Move-Item -LiteralPath $generatedIcon -Destination $currentIcon -Force
        $generatedDirectory = Split-Path $generatedIcon -Parent
        if (-not (Get-ChildItem -LiteralPath $generatedDirectory)) { Remove-Item -LiteralPath $generatedDirectory }
    }
    $adaptiveXml = [IO.File]::ReadAllText($currentIcon)
    if (-not $adaptiveXml.Contains('<monochrome')) {
        $adaptiveXml = $adaptiveXml.Replace('</adaptive-icon>',
            '  <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>' + "`n</adaptive-icon>")
        [IO.File]::WriteAllText($currentIcon, $adaptiveXml)
    }
    # All supported Android versions use the adaptive icon; legacy fallbacks are redundant.
    foreach ($density in @('mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi')) {
        $legacyIcon = Join-Path $resourceRoot "mipmap-$density/ic_launcher.png"
        if (Test-Path -LiteralPath $legacyIcon) { Remove-Item -LiteralPath $legacyIcon }
    }
} finally {
    Pop-Location
}
