$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$manifestPath = Join-Path (Get-Location) 'test/design/manifest.json'
$manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
$images = @(Get-ChildItem -LiteralPath test/design/goldens -Filter '*.png')
if ($images.Count -ne $manifest.states.Count) {
    throw 'Add metadata for new design states to test/design/manifest.json before refreshing the gallery.'
}
$cards = foreach ($state in $manifest.states) {
    $path = Join-Path 'test/design/goldens' "$($state.name).png"
    $state.sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    $bytes = [System.IO.File]::ReadAllBytes((Join-Path (Get-Location) $path))
    # PNG IHDR stores width and height as unsigned big-endian integers.
    $width = [int]$bytes[16] * 16777216 + [int]$bytes[17] * 65536 + [int]$bytes[18] * 256 + [int]$bytes[19]
    $height = [int]$bytes[20] * 16777216 + [int]$bytes[21] * 65536 + [int]$bytes[22] * 256 + [int]$bytes[23]
    $state.pngSize = @($width, $height)
    $name = [System.Net.WebUtility]::HtmlEncode($state.name)
    $description = [System.Net.WebUtility]::HtmlEncode("$($state.theme) · $($state.language) · text $($state.textScale) · $($state.physicalSize[0])×$($state.physicalSize[1]) / DPR $($state.dpr)")
    "<article data-name=`"$name`"><a href=`"../test/design/goldens/$name.png`"><img loading=`"lazy`" src=`"../test/design/goldens/$name.png`" alt=`"$name`"></a><h2>$name</h2><p>$description</p></article>"
}
$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 10) + "`n", $utf8)
$galleryPath = Join-Path (Get-Location) 'docs/design-gallery.html'
$gallery = [System.IO.File]::ReadAllText($galleryPath)
$content = '<main>' + ($cards -join "`n") + '</main>'
$gallery = [regex]::Replace($gallery, '(?s)<main>.*</main>', [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $content })
[System.IO.File]::WriteAllText($galleryPath, $gallery, $utf8)
Write-Output "Gallery metadata refreshed: $($manifest.states.Count) states."
